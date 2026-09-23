defmodule PukllayClub.Catalog.CopiesTest do
  @moduledoc """
  Proves the `copies` table + `Copy` schema (D-01, D-02, D-03, D-05,
  01.8.2-01 — the phase tracer): both unique indexes surface as changeset
  errors, the two `on_delete` behaviors hold, and
  `Shelves.count_for_game/1`/`counts_for_games/1` (D-02, D-31) are the
  only Copias read path. `async: false` (DataCase): historically also
  needed by the backfill-replay tests this file carried before D-31's
  flat-count-column drop; kept for consistency now that those tests are
  gone (they raced `Repo.delete_all(Copy)` against concurrently-running
  async tests).

  **D-31 note:** the `priv/repo/migrations/20260923120000_create_copies.exs`
  `backfill_statements/0` replay tests that used to live here were
  removed by plan `01.8.2-05` — that raw SQL reads the old per-game
  integer count column directly, which D-31's migration removes, so
  replaying it against the current schema would fail with a missing
  column error. That migration's backfill is proven historically (it
  already ran in production/dev); this file now proves the copy-count
  read path that replaces it.
  """
  use PukllayClub.DataCase, async: false

  import PukllayClub.CatalogFixtures
  import PukllayClub.CopiesFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Catalog.Copy
  alias PukllayClub.Catalog.Shelves
  alias PukllayClub.Repo

  describe "changeset/2" do
    test "requires game_id and number" do
      changeset = Copy.changeset(%Copy{}, %{})

      refute changeset.valid?
      assert %{game_id: ["can't be blank"], number: ["can't be blank"]} = errors_on(changeset)
    end

    test "two copies of the same game cannot share a number" do
      game = game_fixture()
      copy_fixture(%{game_id: game.id, number: 1})

      assert {:error, changeset} =
               %Copy{} |> Copy.changeset(%{game_id: game.id, number: 1}) |> Repo.insert()

      assert %{game_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "two copies on the same estante cannot share a position" do
      shelf = shelf_fixture()
      game_a = game_fixture(%{name: "Copia A"})
      game_b = game_fixture(%{name: "Copia B"})
      copy_fixture(%{game_id: game_a.id, shelf_id: shelf.id, position: 0})

      assert {:error, changeset} =
               %Copy{}
               |> Copy.changeset(%{game_id: game_b.id, number: 1, shelf_id: shelf.id, position: 0})
               |> Repo.insert()

      assert %{shelf_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "two unplaced copies (shelf_id nil) never collide, even with the same nil position" do
      game_a = game_fixture(%{name: "Copia A"})
      game_b = game_fixture(%{name: "Copia B"})

      assert %Copy{} = copy_fixture(%{game_id: game_a.id})
      assert %Copy{} = copy_fixture(%{game_id: game_b.id})
    end
  end

  describe "deletion cascades (D-01)" do
    test "deleting a game deletes its copies" do
      game = game_fixture()
      copy = copy_fixture(%{game_id: game.id})

      Repo.delete!(game)

      refute Repo.get(Copy, copy.id)
    end

    test "deleting an estante leaves its copies without a shelf" do
      shelf = shelf_fixture()
      game = game_fixture()
      copy = copy_fixture(%{game_id: game.id, shelf_id: shelf.id, position: 0})

      Repo.delete!(shelf)

      reloaded = Repo.get!(Copy, copy.id)
      assert reloaded.shelf_id == nil
    end
  end

  describe "Shelves.count_for_game/1 (D-02, D-31)" do
    test "a game with three copy rows reports a Copias count of 3" do
      game = game_fixture()
      copy_fixture(%{game_id: game.id})
      copy_fixture(%{game_id: game.id})
      copy_fixture(%{game_id: game.id})

      assert Shelves.count_for_game(game.id) == 3
    end

    test "a game with one copy row reports 1" do
      game = game_fixture()
      copy_fixture(%{game_id: game.id})

      assert Shelves.count_for_game(game.id) == 1
    end

    test "a game with zero copy rows reports 0, never nil" do
      game = game_fixture()

      assert Shelves.count_for_game(game.id) == 0
    end

    test "placed and unplaced copies both count" do
      shelf = shelf_fixture()
      game = game_fixture()
      copy_fixture(%{game_id: game.id, shelf_id: shelf.id, position: 0})
      copy_fixture(%{game_id: game.id})

      assert Shelves.count_for_game(game.id) == 2
    end
  end

  describe "Shelves.counts_for_games/1 (D-02, D-31)" do
    test "returns a map of game_id => count for every requested game, N+1-free" do
      game_a = game_fixture(%{name: "Juego A"})
      game_b = game_fixture(%{name: "Juego B"})
      game_c = game_fixture(%{name: "Juego C"})
      copy_fixture(%{game_id: game_a.id})
      copy_fixture(%{game_id: game_a.id})
      copy_fixture(%{game_id: game_b.id})

      counts = Shelves.counts_for_games([game_a.id, game_b.id, game_c.id])

      assert counts[game_a.id] == 2
      assert counts[game_b.id] == 1
      refute Map.has_key?(counts, game_c.id)
      assert Map.get(counts, game_c.id, 0) == 0
    end
  end
end
