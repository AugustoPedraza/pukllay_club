defmodule PukllayClub.Catalog.BggEditionsTest do
  @moduledoc """
  D-03 (revised 2026-09-14, gap CR-B-01, user decision): a known BGG id is a
  warning, not a rejection — only an explicit confirm inserts an edition,
  and same-id callers are serialized by a per-BGG-id transaction advisory
  lock with an in-lock re-check. See `Catalog.add_game_from_bgg/2`'s @doc
  for the full contract this file proves, including the Patchwork /
  Patchwork Andino pair (bgg_id 163412) that a unique index would break.
  """
  use PukllayClub.DataCase, async: false
  use Oban.Testing, repo: PukllayClub.Repo

  import PukllayClub.CatalogFixtures

  alias Ecto.Adapters.SQL.Sandbox
  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Repo
  alias PukllayClub.Workers.EnrichGameWorker

  # T-01.8.1-73: must equal `PukllayClub.Catalog.@bgg_id_lock_namespace`.
  @bgg_id_lock_namespace 8_811_015

  describe "add_game_from_bgg/2 — known BGG id, no acknowledgement (D-03 revised)" do
    test "returns the existing game and inserts nothing" do
      existing = game_fixture(%{bgg_id: 266_192, status: :retired})

      assert {:existing_editions, games} = Catalog.add_game_from_bgg("266192")
      assert Enum.map(games, & &1.id) == [existing.id]
      assert Catalog.count_admin_games() == 1
      refute_enqueued(worker: EnrichGameWorker)
    end

    test "the Patchwork pair (bgg_id 163412) returns both games instead of raising" do
      patchwork = game_fixture(%{bgg_id: 163_412, name: "Patchwork"})
      andino = game_fixture(%{bgg_id: 163_412, name: "Patchwork Andino"})

      assert {:existing_editions, games} = Catalog.add_game_from_bgg("163412")
      assert Enum.map(games, & &1.id) == Enum.sort([patchwork.id, andino.id])
    end
  end

  describe "add_game_from_bgg/2 — acknowledged edition (D-03 revised)" do
    test "acknowledging every existing holder inserts a new edition sharing the bgg_id" do
      patchwork = game_fixture(%{bgg_id: 163_412, name: "Patchwork"})
      andino = game_fixture(%{bgg_id: 163_412, name: "Patchwork Andino"})

      assert {:ok, edition} =
               Catalog.add_game_from_bgg("163412",
                 acknowledged_game_ids: [patchwork.id, andino.id]
               )

      assert edition.bgg_id == 163_412
      assert edition.status == :draft

      assert Repo.aggregate(from(g in Game, where: g.bgg_id == 163_412), :count) == 3
      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => edition.id})
    end

    test "a stale acknowledgement (already inserted) re-warns with the refreshed list" do
      existing = game_fixture(%{bgg_id: 184_267, status: :draft})

      assert {:ok, edition} =
               Catalog.add_game_from_bgg("184267", acknowledged_game_ids: [existing.id])

      assert {:existing_editions, games} =
               Catalog.add_game_from_bgg("184267", acknowledged_game_ids: [existing.id])

      assert Enum.map(games, & &1.id) == Enum.sort([existing.id, edition.id])
    end

    test "partial acknowledgement of the Patchwork pair inserts nothing" do
      patchwork = game_fixture(%{bgg_id: 163_412, name: "Patchwork"})
      andino = game_fixture(%{bgg_id: 163_412, name: "Patchwork Andino"})

      assert {:existing_editions, games} =
               Catalog.add_game_from_bgg("163412", acknowledged_game_ids: [patchwork.id])

      assert Enum.map(games, & &1.id) == Enum.sort([patchwork.id, andino.id])
      assert Catalog.count_admin_games() == 2
    end
  end

  describe "games.bgg_id has no unique index (guards the rejected REVIEW fix)" do
    test "no unique or partial-unique index exists on games.bgg_id" do
      %{rows: rows} =
        Repo.query!("""
        SELECT indexdef FROM pg_indexes
        WHERE schemaname = 'public' AND tablename = 'games'
          AND indexdef ILIKE '%unique%' AND indexdef ILIKE '%bgg_id%'
        """)

      assert rows == []
    end
  end

  # Real (unboxed) Postgres connections — the sandbox's shared connection
  # serializes every transaction onto one connection and makes advisory
  # locks re-entrant (the same process "already holds" the lock), which
  # hides the exact race this per-BGG-id lock exists to prevent. Each
  # concurrent Task below must call `Sandbox.unboxed_run/2` itself:
  # otherwise it resolves through `$callers` and shares its parent's
  # single connection instead of getting its own.
  describe "concurrent submits (real connections)" do
    setup do
      on_exit(fn ->
        Sandbox.unboxed_run(Repo, fn ->
          bgg_ids = [2_000_015_001, 2_000_015_002]
          game_ids = Repo.all(from(g in Game, where: g.bgg_id in ^bgg_ids, select: g.id))

          Repo.delete_all(
            from(j in Oban.Job,
              where: j.worker == "PukllayClub.Workers.EnrichGameWorker",
              where: fragment("(?->>'game_id')::bigint", j.args) in ^game_ids
            )
          )

          Repo.delete_all(from(g in Game, where: g.id in ^game_ids))
        end)
      end)

      :ok
    end

    test "callers wait on the per-BGG-id lock and re-check inside it" do
      test_bgg_id = 2_000_015_001

      {tasks, holder} =
        Sandbox.unboxed_run(Repo, fn ->
          {:ok, {tasks, holder}} =
            Repo.transaction(fn ->
              Repo.query!("SELECT pg_advisory_xact_lock($1, $2)", [
                @bgg_id_lock_namespace,
                test_bgg_id
              ])

              tasks =
                for _ <- 1..3 do
                  Task.async(fn ->
                    Sandbox.unboxed_run(Repo, fn ->
                      Catalog.add_game_from_bgg(Integer.to_string(test_bgg_id))
                    end)
                  end)
                end

              assert wait_for_waiters(@bgg_id_lock_namespace, test_bgg_id, 3)

              holder = Repo.insert!(Game.draft_changeset(%Game{}, %{bgg_id: test_bgg_id}))

              {tasks, holder}
            end)

          {tasks, holder}
        end)

      results = Task.await_many(tasks, 5_000)

      for result <- results do
        assert {:existing_editions, [got]} = result
        assert got.id == holder.id
      end

      count =
        Sandbox.unboxed_run(Repo, fn ->
          Repo.aggregate(from(g in Game, where: g.bgg_id == ^test_bgg_id), :count)
        end)

      assert count == 1
    end

    test "N-way race for a brand-new bgg_id yields exactly one draft" do
      test_bgg_id = 2_000_015_002

      tasks =
        for _ <- 1..4 do
          Task.async(fn ->
            Sandbox.unboxed_run(Repo, fn ->
              receive do
                :go -> Catalog.add_game_from_bgg(Integer.to_string(test_bgg_id))
              end
            end)
          end)
        end

      for task <- tasks, do: send(task.pid, :go)

      results = Task.await_many(tasks, 5_000)

      {oks, editions} = Enum.split_with(results, &match?({:ok, _}, &1))

      assert [{:ok, winner}] = oks
      assert length(editions) == 3

      for {:existing_editions, [game]} <- editions do
        assert game.id == winner.id
      end

      count =
        Sandbox.unboxed_run(Repo, fn ->
          Repo.aggregate(from(g in Game, where: g.bgg_id == ^test_bgg_id), :count)
        end)

      assert count == 1

      jobs_count =
        Sandbox.unboxed_run(Repo, fn ->
          Repo.aggregate(
            from(j in Oban.Job,
              where: j.worker == "PukllayClub.Workers.EnrichGameWorker",
              where: fragment("(?->>'game_id')::bigint", j.args) == ^winner.id
            ),
            :count
          )
        end)

      assert jobs_count == 1
    end
  end

  # Bounded poll (at most 100 x 20ms = 2s) against `pg_locks` for `expected`
  # backends currently WAITING (not granted) on the two-int4 advisory lock
  # keyed `(namespace, bgg_id)`. Namespace and bgg_id are bound as query
  # parameters, never inlined into the SQL text.
  defp wait_for_waiters(namespace, bgg_id, expected, attempts \\ 100)
  defp wait_for_waiters(_namespace, _bgg_id, _expected, 0), do: false

  defp wait_for_waiters(namespace, bgg_id, expected, attempts) do
    %{rows: [[count]]} =
      Repo.query!(
        """
        SELECT count(*) FROM pg_locks
        WHERE locktype = 'advisory' AND NOT granted
          AND classid::bigint = $1 AND objid::bigint = $2 AND objsubid = 2
        """,
        [namespace, bgg_id]
      )

    if count >= expected do
      true
    else
      Process.sleep(20)
      wait_for_waiters(namespace, bgg_id, expected, attempts - 1)
    end
  end
end
