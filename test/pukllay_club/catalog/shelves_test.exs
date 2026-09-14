defmodule PukllayClub.Catalog.ShelvesTest do
  use PukllayClub.DataCase, async: true

  import PukllayClub.CatalogFixtures
  import PukllayClub.ShelvesFixtures

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

  describe "assign_game/2 and unassign_game/1 (D-12, D-14)" do
    test "assigns an unplaced game and returns nil for its previous shelf" do
      shelf = shelf_fixture()
      game = game_fixture()

      assert {:ok, updated, nil} = Shelves.assign_game(game.id, shelf.id)
      assert updated.shelf_id == shelf.id
    end

    test "moving a game to a different shelf returns its previous shelf" do
      shelf_a = shelf_fixture(%{name: "L1"})
      shelf_b = shelf_fixture(%{name: "L2"})
      game = game_fixture()

      {:ok, _game, nil} = Shelves.assign_game(game.id, shelf_a.id)
      assert {:ok, updated, previous_shelf} = Shelves.assign_game(game.id, shelf_b.id)

      assert updated.shelf_id == shelf_b.id
      assert previous_shelf.id == shelf_a.id
    end

    test "unassign_game/1 clears the shelf" do
      shelf = shelf_fixture()
      game = game_fixture()
      {:ok, _game, nil} = Shelves.assign_game(game.id, shelf.id)

      assert {:ok, updated, previous_shelf} = Shelves.unassign_game(game.id)
      assert updated.shelf_id == nil
      assert previous_shelf.id == shelf.id
    end

    test "assigning to a nonexistent shelf id returns an error changeset" do
      game = game_fixture()

      assert {:error, changeset} = Shelves.assign_game(game.id, -1)
      assert "does not exist" in errors_on(changeset).shelf_id
    end
  end

  describe "location_progress/0, unplaced_games/0, games_on_shelf/1 (D-12, D-13)" do
    test "counts only non-retired games in the denominator" do
      shelf = shelf_fixture()
      placed = game_fixture(%{name: "Placed"})
      unplaced = game_fixture(%{name: "Unplaced"})
      _retired = game_fixture(%{name: "Retired", status: :retired})

      {:ok, _game, nil} = Shelves.assign_game(placed.id, shelf.id)

      assert Shelves.location_progress() == {1, 2}
      assert Enum.map(Shelves.unplaced_games(), & &1.id) == [unplaced.id]
      assert Enum.map(Shelves.games_on_shelf(shelf.id), & &1.id) == [placed.id]
    end
  end

  describe "search_games/1 (D-13)" do
    test "matches non-retired games whether placed or not, preloading shelf" do
      shelf = shelf_fixture(%{name: "L2"})
      catan = game_fixture(%{name: "Catán"})
      camel_up = game_fixture(%{name: "Camel Up"})
      _other = game_fixture(%{name: "Wingspan"})
      _retired = game_fixture(%{name: "Catán Junior", status: :retired})

      {:ok, _game, nil} = Shelves.assign_game(catan.id, shelf.id)

      results = Shelves.search_games("cat")
      assert Enum.map(results, & &1.id) == [catan.id]
      assert hd(results).shelf.name == "L2"

      results = Shelves.search_games("ca")
      assert results |> Enum.map(& &1.id) |> Enum.sort() == Enum.sort([catan.id, camel_up.id])
    end

    test "returns [] for a blank query" do
      assert Shelves.search_games("") == []
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

  describe "pick_list/1 (D-15, UI-SPEC E5 zero-one-many)" do
    test "groups non-retired games by shelf in walking order, plus a final :unplaced group" do
      l1 = shelf_fixture(%{name: "L1"})
      l2 = shelf_fixture(%{name: "L2"})
      catan = game_fixture(%{name: "Catán"})
      _empty_shelf_has_no_games = l2
      unplaced = game_fixture(%{name: "Wingspan"})
      _retired = game_fixture(%{name: "Retired", status: :retired})

      {:ok, _game, nil} = Shelves.assign_game(catan.id, l1.id)

      groups = Shelves.pick_list()

      assert [{^l1, [catan_row]}, {^l2, []}, {:unplaced, [unplaced_row]}] = groups
      assert catan_row.id == catan.id
      assert unplaced_row.id == unplaced.id
    end

    test "filters games by name without hiding an empty shelf's own heading" do
      l1 = shelf_fixture(%{name: "L1"})
      catan = game_fixture(%{name: "Catán"})
      _wingspan = game_fixture(%{name: "Wingspan"})
      {:ok, _game, nil} = Shelves.assign_game(catan.id, l1.id)

      groups = Shelves.pick_list("cat")

      assert [{^l1, [catan_row]}, {:unplaced, []}] = groups
      assert catan_row.id == catan.id
    end
  end

  describe "deleting a shelf nilifies its games' shelf_id" do
    test "on_delete: :nilify_all" do
      shelf = shelf_fixture()
      game = game_fixture()
      {:ok, _game, nil} = Shelves.assign_game(game.id, shelf.id)

      Repo.delete!(shelf)

      assert Repo.get!(PukllayClub.Catalog.Game, game.id).shelf_id == nil
    end
  end
end
