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
