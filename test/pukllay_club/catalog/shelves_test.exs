defmodule PukllayClub.Catalog.ShelvesTest do
  @moduledoc """
  Proves the copies-aware rewrite of `Shelves` (D-01, D-02, D-03, D-04,
  D-11, 01.8.2-01) — position-ordered reads, gap-free place/remove under
  a per-estante advisory lock (including a real cross-process race), and
  the `"admin:estantes"` PubSub broadcast. The shelf CRUD describes
  below (`create_shelf/1`, `rename_shelf/2`, `move_shelf/2`) are
  unchanged by this plan and kept as regression coverage.

  The concurrency describe uses REAL (unboxed) Postgres connections, the
  same pattern `test/pukllay_club/catalog/bgg_editions_test.exs` already
  established for `catalog.ex`'s own per-BGG-id advisory lock: the
  sandbox's shared connection serializes every transaction onto one
  connection and makes advisory locks re-entrant (the same process
  "already holds" the lock), which would hide the exact race this lock
  exists to prevent. `async: false` — real connections bypass the
  sandbox's per-test isolation.
  """
  use PukllayClub.DataCase, async: false

  import PukllayClub.CatalogFixtures
  import PukllayClub.CopiesFixtures
  import PukllayClub.ShelvesFixtures

  alias Ecto.Adapters.SQL.Sandbox
  alias PukllayClub.Catalog.Copy
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Shelf
  alias PukllayClub.Catalog.Shelves
  alias PukllayClub.Repo

  describe "create_shelf/1 and list_shelves/0 (D-10)" do
    test "creates a shelf at the next walking position" do
      {:ok, l1} = Shelves.create_shelf(%{name: "L1"})
      {:ok, l2} = Shelves.create_shelf(%{name: "L2"})

      assert l1.position == 1
      assert l2.position == 2
      assert Enum.map(Shelves.list_shelves(), & &1.name) == ["L1", "L2"]
    end

    test "rejects a duplicate name" do
      shelf_fixture(%{name: "L1"})
      assert {:error, changeset} = Shelves.create_shelf(%{name: "L1"})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "rejects a name over 40 characters (UI-SPEC E4 long-text)" do
      assert {:error, changeset} = Shelves.create_shelf(%{name: String.duplicate("a", 41)})
      assert "should be at most 40 character(s)" in errors_on(changeset).name
    end
  end

  describe "rename_shelf/2 (D-10)" do
    test "renames a shelf" do
      shelf = shelf_fixture(%{name: "L1"})
      assert {:ok, renamed} = Shelves.rename_shelf(shelf, "L1 (Cooperativos)")
      assert renamed.name == "L1 (Cooperativos)"
    end

    test "rejects a name over 40 characters" do
      shelf = shelf_fixture()
      assert {:error, changeset} = Shelves.rename_shelf(shelf, String.duplicate("a", 41))
      assert "should be at most 40 character(s)" in errors_on(changeset).name
    end
  end

  describe "move_shelf/2 (D-10)" do
    test "swaps position with the neighbour in the given direction" do
      l1 = shelf_fixture(%{name: "L1"})
      _l2 = shelf_fixture(%{name: "L2"})
      l3 = shelf_fixture(%{name: "L3"})

      assert {:ok, _} = Shelves.move_shelf(l3, :up)
      assert Enum.map(Shelves.list_shelves(), & &1.name) == ["L1", "L3", "L2"]

      assert {:ok, _} = Shelves.move_shelf(l1, :down)
      assert Enum.map(Shelves.list_shelves(), & &1.name) == ["L3", "L1", "L2"]
    end

    test "is a no-op at either end of the list" do
      l1 = shelf_fixture(%{name: "L1"})
      l2 = shelf_fixture(%{name: "L2"})

      assert {:ok, _} = Shelves.move_shelf(l1, :up)
      assert Enum.map(Shelves.list_shelves(), & &1.name) == ["L1", "L2"]

      assert {:ok, _} = Shelves.move_shelf(l2, :down)
      assert Enum.map(Shelves.list_shelves(), & &1.name) == ["L1", "L2"]
    end
  end

  describe "copies_on_shelf/1 and unplaced_copies/0 (D-04/D-08)" do
    test "copies_on_shelf/1 orders by position ascending, game preloaded" do
      shelf = shelf_fixture()
      alfa = game_fixture(%{name: "Alfa"})
      beta = game_fixture(%{name: "Beta"})

      copy_a = copy_fixture(%{game_id: alfa.id})
      copy_b = copy_fixture(%{game_id: beta.id})

      {:ok, _} = Shelves.place_copy(copy_a.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(copy_b.id, shelf.id, 0)

      [first, second] = Shelves.copies_on_shelf(shelf.id)
      assert first.id == copy_b.id
      assert first.position == 0
      assert first.game.id == beta.id
      assert second.id == copy_a.id
      assert second.position == 1
    end

    test "unplaced_copies/0 returns copies with shelf_id nil, game preloaded, ordered by name" do
      zeta = game_fixture(%{name: "Zeta"})
      alfa = game_fixture(%{name: "Alfa"})
      shelf = shelf_fixture()
      placed_game = game_fixture(%{name: "Colocado"})
      placed_copy = copy_fixture(%{game_id: placed_game.id})
      {:ok, _} = Shelves.place_copy(placed_copy.id, shelf.id, 0)

      copy_zeta = copy_fixture(%{game_id: zeta.id})
      copy_alfa = copy_fixture(%{game_id: alfa.id})

      results = Shelves.unplaced_copies()

      assert Enum.map(results, & &1.id) == [copy_alfa.id, copy_zeta.id]
      assert Enum.all?(results, &(is_nil(&1.shelf_id) and is_nil(&1.position)))
      assert Enum.map(results, & &1.game.name) == ["Alfa", "Zeta"]
    end
  end

  describe "place_copy/3 (D-00c, D-11)" do
    test "index 0 on an empty estante gives position 0" do
      shelf = shelf_fixture()
      game = game_fixture()
      copy = copy_fixture(%{game_id: game.id})

      assert {:ok, moved} = Shelves.place_copy(copy.id, shelf.id, 0)
      assert moved.shelf_id == shelf.id
      assert moved.position == 0
    end

    test "an index between two placed copies shifts every later copy up by one, no gap" do
      shelf = shelf_fixture()
      c0 = copy_fixture(%{game_id: game_fixture(%{name: "G0"}).id})
      c1 = copy_fixture(%{game_id: game_fixture(%{name: "G1"}).id})
      c2 = copy_fixture(%{game_id: game_fixture(%{name: "G2"}).id})

      {:ok, _} = Shelves.place_copy(c0.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(c1.id, shelf.id, 1)
      {:ok, moved} = Shelves.place_copy(c2.id, shelf.id, 1)

      assert moved.position == 1

      positions =
        shelf.id
        |> Shelves.copies_on_shelf()
        |> Enum.map(&{&1.id, &1.position})

      assert positions == [{c0.id, 0}, {c2.id, 1}, {c1.id, 2}]
    end

    test "moving a copy already placed on another estante removes it from the old one and reindexes gap-free" do
      shelf_a = shelf_fixture(%{name: "A"})
      shelf_b = shelf_fixture(%{name: "B"})

      a0 = copy_fixture(%{game_id: game_fixture(%{name: "A0"}).id})
      a1 = copy_fixture(%{game_id: game_fixture(%{name: "A1"}).id})
      a2 = copy_fixture(%{game_id: game_fixture(%{name: "A2"}).id})

      {:ok, _} = Shelves.place_copy(a0.id, shelf_a.id, 0)
      {:ok, _} = Shelves.place_copy(a1.id, shelf_a.id, 1)
      {:ok, _} = Shelves.place_copy(a2.id, shelf_a.id, 2)

      assert {:ok, moved} = Shelves.place_copy(a1.id, shelf_b.id, 0)
      assert moved.shelf_id == shelf_b.id
      assert moved.position == 0

      remaining_a =
        shelf_a.id
        |> Shelves.copies_on_shelf()
        |> Enum.map(&{&1.id, &1.position})

      assert remaining_a == [{a0.id, 0}, {a2.id, 1}]

      on_b = shelf_b.id |> Shelves.copies_on_shelf() |> Enum.map(&{&1.id, &1.position})
      assert on_b == [{a1.id, 0}]
    end

    test "moving a copy to a later index within the SAME estante reindexes correctly" do
      shelf = shelf_fixture()
      c0 = copy_fixture(%{game_id: game_fixture(%{name: "M0"}).id})
      c1 = copy_fixture(%{game_id: game_fixture(%{name: "M1"}).id})
      c2 = copy_fixture(%{game_id: game_fixture(%{name: "M2"}).id})

      {:ok, _} = Shelves.place_copy(c0.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(c1.id, shelf.id, 1)
      {:ok, _} = Shelves.place_copy(c2.id, shelf.id, 2)

      assert {:ok, moved} = Shelves.place_copy(c0.id, shelf.id, 2)
      assert moved.position == 2

      positions =
        shelf.id
        |> Shelves.copies_on_shelf()
        |> Enum.map(&{&1.id, &1.position})

      assert positions == [{c1.id, 0}, {c2.id, 1}, {c0.id, 2}]
    end

    test "returns {:error, :copy_not_found} for an unknown copy id" do
      shelf = shelf_fixture()
      assert {:error, :copy_not_found} = Shelves.place_copy(-1, shelf.id, 0)
    end

    test "broadcasts {:estante_updated, shelf_id} on \"admin:estantes\"" do
      Phoenix.PubSub.subscribe(PukllayClub.PubSub, "admin:estantes")

      shelf = shelf_fixture()
      copy = copy_fixture(%{game_id: game_fixture().id})

      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      assert_receive {:estante_updated, shelf_id}
      assert shelf_id == shelf.id
    end

    # T-01.8.2-71 (plan 01.8.2-16): a move must be one transaction, not
    # remove-then-place in two steps — asserted here by forcing the
    # transaction's LAST write (`insert_at`'s final `update_all`) to fail
    # on a bogus destination `shelf_id` (violates the `copies.shelf_id`
    # FK, which `update_all` does not pre-validate) and proving the
    # `vacate/2` step that already ran (removing `a0` from `shelf_a`) was
    # rolled back with it — the old estante is exactly as it was before
    # the failed call, never left half-vacated.
    test "a move that fails mid-transaction leaves the old estante completely unchanged (atomicity, T-01.8.2-71)" do
      shelf_a = shelf_fixture(%{name: "Origen"})
      a0 = copy_fixture(%{game_id: game_fixture(%{name: "A0"}).id})
      a1 = copy_fixture(%{game_id: game_fixture(%{name: "A1"}).id})
      {:ok, _} = Shelves.place_copy(a0.id, shelf_a.id, 0)
      {:ok, _} = Shelves.place_copy(a1.id, shelf_a.id, 1)

      bogus_shelf_id = -1

      assert_raise Postgrex.Error, fn ->
        Shelves.place_copy(a0.id, bogus_shelf_id, 0)
      end

      remaining_a = shelf_a.id |> Shelves.copies_on_shelf() |> Enum.map(&{&1.id, &1.position})
      assert remaining_a == [{a0.id, 0}, {a1.id, 1}]
    end
  end

  describe "search_estantes_or_copies/2 (D-00c, T-01.8.2-73)" do
    test "matches estantes by name, ranked first" do
      shelf = shelf_fixture(%{name: "Estante Norte"})

      assert [{:shelf, ^shelf}] = Shelves.search_estantes_or_copies("norte")
    end

    test "matches an already-placed copy's game by name, resolving to its shelf" do
      shelf = shelf_fixture(%{name: "Estante Sur"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Catán"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      assert [{:copy, found}] = Shelves.search_estantes_or_copies("catan")
      assert found.id == copy.id
      assert found.shelf.id == shelf.id
    end

    test "an unplaced copy's game never appears — only shelved games are neighbourhoods" do
      copy_fixture(%{game_id: game_fixture(%{name: "Zorblax"}).id})

      assert Shelves.search_estantes_or_copies("zorblax") == []
    end

    test "excludes the copy being placed/moved via exclude_copy_id" do
      shelf = shelf_fixture(%{name: "Estante Este"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Dixit"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      assert Shelves.search_estantes_or_copies("dixit", copy.id) == []
    end

    test "returns [] for a blank query" do
      assert Shelves.search_estantes_or_copies("") == []
    end

    test "estantes come before copies for the same query" do
      shelf = shelf_fixture(%{name: "Alfa"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Alfa Quest"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      assert [{:shelf, _}, {:copy, _}] = Shelves.search_estantes_or_copies("alfa")
    end
  end

  describe "restore_position/3 (D-00c Deshacer)" do
    test "restores a copy that was unplaced before the write it undoes" do
      shelf = shelf_fixture()
      copy = copy_fixture(%{game_id: game_fixture().id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      assert {:ok, restored} = Shelves.restore_position(copy.id, nil, nil)
      assert restored.shelf_id == nil
      assert restored.position == nil
    end

    test "restores a copy to its previous estante and position, reindexing around it" do
      shelf_a = shelf_fixture(%{name: "A"})
      shelf_b = shelf_fixture(%{name: "B"})

      a0 = copy_fixture(%{game_id: game_fixture(%{name: "A0"}).id})
      a1 = copy_fixture(%{game_id: game_fixture(%{name: "A1"}).id})
      {:ok, _} = Shelves.place_copy(a0.id, shelf_a.id, 0)
      {:ok, _} = Shelves.place_copy(a1.id, shelf_a.id, 1)

      # a0 moves to shelf_b, so its old position (0) is snapshotted before
      # the move for the undo below.
      {:ok, _} = Shelves.place_copy(a0.id, shelf_b.id, 0)

      # A third copy lands in a0's old slot on shelf_a while a0 is away —
      # this is the "neighbours may have shifted" case the restore
      # function exists for.
      a2 = copy_fixture(%{game_id: game_fixture(%{name: "A2"}).id})
      {:ok, _} = Shelves.place_copy(a2.id, shelf_a.id, 0)

      assert {:ok, restored} = Shelves.restore_position(a0.id, shelf_a.id, 0)
      assert restored.shelf_id == shelf_a.id
      assert restored.position == 0

      positions = shelf_a.id |> Shelves.copies_on_shelf() |> Enum.map(&{&1.id, &1.position})
      assert positions == [{a0.id, 0}, {a2.id, 1}, {a1.id, 2}]
    end
  end

  describe "remove_copy_from_shelf/1 (D-11)" do
    test "nilifies shelf and position and reindexes the estante gap-free" do
      shelf = shelf_fixture()
      c0 = copy_fixture(%{game_id: game_fixture(%{name: "R0"}).id})
      c1 = copy_fixture(%{game_id: game_fixture(%{name: "R1"}).id})
      c2 = copy_fixture(%{game_id: game_fixture(%{name: "R2"}).id})

      {:ok, _} = Shelves.place_copy(c0.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(c1.id, shelf.id, 1)
      {:ok, _} = Shelves.place_copy(c2.id, shelf.id, 2)

      assert {:ok, removed} = Shelves.remove_copy_from_shelf(c1.id)
      assert removed.shelf_id == nil
      assert removed.position == nil

      positions =
        shelf.id
        |> Shelves.copies_on_shelf()
        |> Enum.map(&{&1.id, &1.position})

      assert positions == [{c0.id, 0}, {c2.id, 1}]
    end

    test "is a no-op for an already-unplaced copy" do
      copy = copy_fixture(%{game_id: game_fixture().id})
      assert {:ok, unchanged} = Shelves.remove_copy_from_shelf(copy.id)
      assert unchanged.shelf_id == nil
      assert unchanged.position == nil
    end

    test "broadcasts on success" do
      Phoenix.PubSub.subscribe(PukllayClub.PubSub, "admin:estantes")

      shelf = shelf_fixture()
      copy = copy_fixture(%{game_id: game_fixture().id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      assert {:ok, _} = Shelves.remove_copy_from_shelf(copy.id)

      assert_received {:estante_updated, shelf_id}
      assert shelf_id == shelf.id
    end
  end

  # Real (unboxed) Postgres connections — see this module's moduledoc.
  # Each concurrent Task below must call `Sandbox.unboxed_run/2` itself,
  # otherwise it resolves through `$callers` and shares its parent's
  # single connection instead of getting its own.
  describe "concurrent place_copy/3 on one estante (D-11, real connections)" do
    test "N-way race yields positions exactly 0..n-1, no duplicate, no gap" do
      {shelf, copies} =
        Sandbox.unboxed_run(Repo, fn ->
          shelf = shelf_fixture()
          copies = for n <- 1..4, do: copy_fixture(%{game_id: game_fixture(%{name: "C#{n}"}).id})
          {shelf, copies}
        end)

      game_ids = Enum.map(copies, & &1.game_id)

      # Real (unboxed) writes are committed for real, not rolled back by
      # the sandbox at test end — `on_exit` (not the inline cleanup this
      # replaced) guarantees this runs even if an assertion below fails,
      # so a failing run can never leak rows into later tests'
      # `count_admin_games/0`-style assertions. Deleting the games
      # cascades to their copies (`on_delete: :delete_all`).
      on_exit(fn ->
        Sandbox.unboxed_run(Repo, fn ->
          Repo.delete_all(from(g in Game, where: g.id in ^game_ids))
          Repo.delete_all(from(s in Shelf, where: s.id == ^shelf.id))
        end)
      end)

      tasks =
        for copy <- copies do
          Task.async(fn ->
            Sandbox.unboxed_run(Repo, fn ->
              receive do
                :go -> Shelves.place_copy(copy.id, shelf.id, 0)
              end
            end)
          end)
        end

      for task <- tasks, do: send(task.pid, :go)

      results = Task.await_many(tasks, 5_000)
      assert Enum.all?(results, &match?({:ok, _}, &1))

      positions =
        Sandbox.unboxed_run(Repo, fn ->
          Copy
          |> where([c], c.shelf_id == ^shelf.id)
          |> Repo.all()
          |> Enum.map(& &1.position)
          |> Enum.sort()
        end)

      assert positions == [0, 1, 2, 3]
    end
  end
end
