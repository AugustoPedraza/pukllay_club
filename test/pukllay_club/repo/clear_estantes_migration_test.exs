# Migration files under `priv/repo/migrations/` are not part of the
# compiled application (`mix compile` never sees them) — `mix ecto.migrate`
# loads them ad hoc via `Ecto.Migrator`. To call the module's `up/0`/`down/0`
# directly, this test must load the source file itself, first.
# Guarded, and the guard is load-bearing on a FRESH database. `mix test`'s
# alias is `["ecto.create --quiet", "ecto.migrate --quiet", "test"]`, and on a
# database that actually has migrations to run, `Ecto.Migrator` compiles every
# migration module into the VM first. An unguarded `Code.require_file/2` then
# re-evaluates this one and emits "redefining module … (current version defined
# in memory)". Because this call sits at the top level of a test FILE, that
# warning is emitted while the suite is being loaded — which is exactly what
# `--warnings-as-errors` counts, so `mix quality` aborts after an otherwise
# green run (CI run 35961407560: "1852 tests, 0 failures" followed by
# "Test suite aborted after successful execution due to warnings").
#
# It does not reproduce on a developer machine whose test database is already
# migrated, because there `ecto.migrate` is a no-op and loads nothing. Fresh
# database only — i.e. CI, always.
#
# Same guard `catalog_test.exs` already uses for its own migration require.
# (`sections_backfill_test.exs` requires a migration too, but from inside
# `setup` — a runtime warning, which `--warnings-as-errors` does not count.)
if !Code.ensure_loaded?(PukllayClub.Repo.Migrations.ClearEstantesAndAssignments) do
  Code.require_file(
    "priv/repo/migrations/20260923140000_clear_estantes_and_assignments.exs",
    File.cwd!()
  )
end

defmodule PukllayClub.Repo.ClearEstantesMigrationTest do
  @moduledoc """
  Proves the D-05/D-06/D-07 clear-slate migration
  (`priv/repo/migrations/20260923140000_clear_estantes_and_assignments.exs`):
  every `shelves` row is gone, every legacy `games.shelf_id` and every
  `copies.shelf_id`/`position` is nilified, the pre-clear counts are
  logged as one JSON line, and `down/0` raises rather than pretending a
  rollback is possible.

  **This is the first migration-behaviour test in this repo** — there
  was no prior convention for testing what a migration actually does to
  data, only for testing schema/changeset behaviour after a migration
  has already run. The shape established here, for a later data-only
  migration to follow:

    - ordinary `PukllayClub.DataCase` (`Ecto.Adapters.SQL.Sandbox`)
      setup — no special migration test case is needed when the
      migration under test does no DDL and calls `PukllayClub.Repo`
      directly rather than the `repo()` migration-DSL helper (see that
      migration's moduledoc for why this specific migration can do
      that).
    - seed fixtures directly, at whatever pre-migration shape the test
      needs (including shapes the ordinary fixtures don't produce, via
      a raw schemaless `Repo.update_all/2` — `game_fixture/1`'s
      `seed_changeset/2` never casts `:shelf_id`, so a legacy assignment
      has to be set that way).
    - invoke the migration module's `up/0` (or `down/0`) directly —
      never through `mix ecto.migrate` / `Ecto.Migrator` — so the test
      runs inside the same Sandbox transaction as the rest of the suite
      and rolls back automatically.
    - assert the logged JSON line with `ExUnit.CaptureLog`, after
      temporarily raising the **global** Logger level to `:info` for the
      duration of each test. `config/test.exs` sets the global level to
      `:warning`, and empirically (verified against this project's exact
      Elixir/OTP pair, `elixir_level_to_erlang_level`/`:logger_config.allow/2`
      in `logger` 1.19.5) neither `Logger.put_process_level/2` (a
      per-process override) nor `capture_log/2`'s own `level:` option can
      raise visibility above that global primary level — both can only
      *lower* it. Only `Logger.configure(level: :info)` actually works;
      this file's `setup` sets it and restores the prior level via
      `on_exit`, and `async: false` keeps that global mutation from
      racing this file's own tests against each other.
  """
  use PukllayClub.DataCase, async: false

  import ExUnit.CaptureLog
  import PukllayClub.CatalogFixtures
  import PukllayClub.CopiesFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Catalog.Copy
  alias PukllayClub.Repo
  alias PukllayClub.Repo.Migrations.ClearEstantesAndAssignments, as: Migration

  setup do
    # config/test.exs sets the global Logger level to :warning, and
    # (verified empirically, see moduledoc) only a global
    # `Logger.configure/1` call actually raises visibility for
    # `ExUnit.CaptureLog` to see the migration's `Logger.info` line —
    # restored via `on_exit` so it never leaks into other test files.
    previous_level = Logger.level()
    Logger.configure(level: :info)
    on_exit(fn -> Logger.configure(level: previous_level) end)
    :ok
  end

  defp game_shelf_id(game_id) do
    Repo.one(from g in "games", where: g.id == ^game_id, select: g.shelf_id)
  end

  defp put_legacy_game_shelf(game_id, shelf_id) do
    Repo.update_all(from(g in "games", where: g.id == ^game_id), set: [shelf_id: shelf_id])
  end

  defp shelves_count do
    Repo.one(from s in "shelves", select: count(s.id))
  end

  defp decode_logged_json(log) do
    [json_line] = log |> String.split("\n") |> Enum.filter(&(&1 =~ "estantes_removed"))
    [_, json] = Regex.run(~r/(\{.*\})/, json_line)
    Jason.decode!(json)
  end

  describe "up/0 (D-05 — the clear itself)" do
    test "deletes every estante" do
      shelf_fixture()
      shelf_fixture()
      assert shelves_count() == 2

      capture_log(fn -> Migration.up() end)

      assert shelves_count() == 0
    end

    test "nilifies every game's legacy shelf_id" do
      shelf = shelf_fixture()
      game = game_fixture()
      put_legacy_game_shelf(game.id, shelf.id)
      assert game_shelf_id(game.id) == shelf.id

      capture_log(fn -> Migration.up() end)

      assert game_shelf_id(game.id) == nil
    end

    test "nilifies every copy's shelf_id and position, leaving it Sin ubicar" do
      shelf = shelf_fixture()
      game = game_fixture()
      copy = copy_fixture(%{game_id: game.id, shelf_id: shelf.id, position: 0})

      capture_log(fn -> Migration.up() end)

      reloaded = Repo.get!(Copy, copy.id)
      assert reloaded.shelf_id == nil
      assert reloaded.position == nil
    end

    test "an already-unplaced copy is left unplaced, not touched into some other state" do
      game = game_fixture()
      copy = copy_fixture(%{game_id: game.id})

      capture_log(fn -> Migration.up() end)

      reloaded = Repo.get!(Copy, copy.id)
      assert reloaded.shelf_id == nil
      assert reloaded.position == nil
    end
  end

  describe "up/0 (D-06 — the logged counts)" do
    test "logs one JSON line with the pre-clear estante and legacy-assignment counts" do
      shelf_fixture()
      other_shelf = shelf_fixture()
      game_a = game_fixture(%{name: "Juego A"})
      game_b = game_fixture(%{name: "Juego B"})
      put_legacy_game_shelf(game_a.id, other_shelf.id)
      put_legacy_game_shelf(game_b.id, other_shelf.id)

      log = capture_log(fn -> Migration.up() end)

      payload = decode_logged_json(log)
      assert payload["estantes_removed"] == 2
      assert payload["assignments_removed"] == 2
      assert is_binary(payload["at"])
    end

    test "the logged estantes_removed count equals what was actually seeded, on a clean slate" do
      log = capture_log(fn -> Migration.up() end)

      payload = decode_logged_json(log)
      assert payload["estantes_removed"] == 0
      assert payload["assignments_removed"] == 0
      assert payload["copies_unplaced"] == 0
    end

    test "copies_unplaced counts copies that had a shelf_id before the clear" do
      shelf = shelf_fixture()
      game = game_fixture()
      copy_fixture(%{game_id: game.id, shelf_id: shelf.id, position: 0})
      # a second, already-unplaced copy must not inflate the count
      copy_fixture(%{game_id: game.id})

      log = capture_log(fn -> Migration.up() end)

      payload = decode_logged_json(log)
      assert payload["copies_unplaced"] == 1
    end
  end

  describe "down/0 (D-05 — one-way by design)" do
    test "raises Ecto.MigrationError instead of pretending a rollback restored anything" do
      assert_raise Ecto.MigrationError, ~r/irreversible by design/, fn ->
        Migration.down()
      end
    end

    test "down/0 does not touch the database at all" do
      shelf_fixture()
      assert shelves_count() == 1

      assert_raise Ecto.MigrationError, fn -> Migration.down() end

      assert shelves_count() == 1
    end
  end
end
