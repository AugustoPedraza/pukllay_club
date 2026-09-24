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

  describe "Shelves.copies_for_game/1 (D-03, plan 01.8.2-21)" do
    test "ordered by stable number, shelf preloaded" do
      shelf = shelf_fixture()
      game = game_fixture()
      c2 = copy_fixture(%{game_id: game.id, number: 2})
      c1 = copy_fixture(%{game_id: game.id, number: 1, shelf_id: shelf.id, position: 0})

      copies = Shelves.copies_for_game(game.id)

      assert Enum.map(copies, & &1.id) == [c1.id, c2.id]
      assert Enum.find(copies, &(&1.id == c1.id)).shelf.id == shelf.id
      assert Enum.find(copies, &(&1.id == c2.id)).shelf == nil
    end
  end

  describe "Shelves.add_copy/1 (D-02, D-31, plan 01.8.2-21)" do
    test "creates an unplaced copy with the next free stable number" do
      game = game_fixture()
      copy_fixture(%{game_id: game.id, number: 1})

      assert {:ok, copy} = Shelves.add_copy(game.id)

      assert copy.number == 2
      assert copy.shelf_id == nil
      assert copy.position == nil
      assert copy.id in Enum.map(Shelves.unplaced_copies(), & &1.id)
      assert Shelves.count_for_game(game.id) == 2
    end

    test "a gap left by a removed copy is never reused — next free means one past the max" do
      game = game_fixture()
      c1 = copy_fixture(%{game_id: game.id, number: 1})
      copy_fixture(%{game_id: game.id, number: 2})
      {:ok, _} = Shelves.delete_copy(c1)

      assert {:ok, copy} = Shelves.add_copy(game.id)

      assert copy.number == 3
    end
  end

  describe "Shelves.delete_copy/1 (D-02, D-31, plan 01.8.2-21)" do
    test "deletes an unplaced copy directly, leaving the others' numbers unchanged" do
      game = game_fixture()
      c1 = copy_fixture(%{game_id: game.id, number: 1})
      c2 = copy_fixture(%{game_id: game.id, number: 2})

      assert {:ok, _} = Shelves.delete_copy(c1)

      assert Shelves.count_for_game(game.id) == 1
      assert Repo.get(Copy, c2.id).number == 2
    end

    test "deleting a placed copy reindexes its estante gap-free, in one transaction" do
      shelf = shelf_fixture()
      game = game_fixture()
      c0 = copy_fixture(%{game_id: game.id, number: 1, shelf_id: shelf.id, position: 0})
      c1 = copy_fixture(%{game_id: game.id, number: 2, shelf_id: shelf.id, position: 1})
      c2 = copy_fixture(%{game_id: game.id, number: 3, shelf_id: shelf.id, position: 2})

      assert {:ok, _} = Shelves.delete_copy(c0)

      remaining = Shelves.copies_on_shelf(shelf.id)
      assert Enum.map(remaining, & &1.id) == [c1.id, c2.id]
      assert Enum.map(remaining, & &1.position) == [0, 1]
      refute Repo.get(Copy, c0.id)
    end
  end

  describe "Shelves.remove_copy_for_game/2 (D-02, D-31, plan 01.8.2-21)" do
    test "with no copy_id, prefers the lowest-numbered unplaced copy" do
      game = game_fixture()
      copy_fixture(%{game_id: game.id, number: 1})
      c2 = copy_fixture(%{game_id: game.id, number: 2})

      assert {:ok, removed} = Shelves.remove_copy_for_game(game.id)

      refute removed.id == c2.id
      assert Shelves.count_for_game(game.id) == 1
    end

    test "leaves placed copies alone when an unplaced one exists" do
      shelf = shelf_fixture()
      game = game_fixture()
      placed = copy_fixture(%{game_id: game.id, number: 1, shelf_id: shelf.id, position: 0})
      copy_fixture(%{game_id: game.id, number: 2})

      assert {:ok, removed} = Shelves.remove_copy_for_game(game.id)

      refute removed.id == placed.id
      assert Repo.get(Copy, placed.id)
    end

    test "with no unplaced copy, returns {:error, :no_unplaced_copy} — never guesses which placed one" do
      shelf = shelf_fixture()
      game = game_fixture()
      copy_fixture(%{game_id: game.id, number: 1, shelf_id: shelf.id, position: 0})

      assert Shelves.remove_copy_for_game(game.id) == {:error, :no_unplaced_copy}
      assert Shelves.count_for_game(game.id) == 1
    end

    test "with an explicit copy_id, removes exactly that placed copy" do
      shelf = shelf_fixture()
      game = game_fixture()
      target = copy_fixture(%{game_id: game.id, number: 1, shelf_id: shelf.id, position: 0})

      assert {:ok, removed} = Shelves.remove_copy_for_game(game.id, target.id)

      assert removed.id == target.id
      refute Repo.get(Copy, target.id)
    end
  end
end
