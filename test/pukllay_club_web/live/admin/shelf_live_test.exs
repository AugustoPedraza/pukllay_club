defmodule PukllayClubWeb.Admin.ShelfLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Ecto.Query
  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Catalog.Shelves

  describe "ShelfLive.Assign — tap to assign (D-12, T-01.8.1-42)" do
    setup :register_and_log_in_staff

    test "tapping an unplaced game saves it, updates the list and progress, and persists after remount",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "L1"})
      game = game_fixture(%{name: "Catán"})

      {:ok, lv, html} = live(conn, ~p"/admin/estantes/#{shelf.id}/asignar")
      assert html =~ "0/1 ubicados"
      assert html =~ "Catán"

      html =
        lv
        |> element("button[phx-value-game-id='#{game.id}']", "Catán")
        |> render_click()

      assert html =~ "1/1 ubicados"
      assert html =~ "Todos los juegos ya tienen un estante."

      {:ok, _lv2, remounted_html} = live(conn, ~p"/admin/estantes/#{shelf.id}/asignar")
      assert remounted_html =~ "1/1 ubicados"
      assert remounted_html =~ "Catán"
    end

    test "a non-integer :id 404s", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/admin/estantes/not-an-id/asignar")
      end
    end
  end

  describe "location_progress reflects taps (D-12)" do
    setup :register_and_log_in_staff

    test "the header progress turns success once every game is placed", %{conn: conn} do
      shelf = shelf_fixture()
      game = game_fixture()

      {:ok, _game, nil} = Shelves.assign_game(game.id, shelf.id)

      {:ok, _lv, html} = live(conn, ~p"/admin/estantes/#{shelf.id}/asignar")
      assert html =~ "text-success"
      assert html =~ "1/1 ubicados"
    end
  end

  describe "type-ahead search, move-with-undo, error revert (D-13, D-14, UI-SPEC E4)" do
    setup :register_and_log_in_staff

    test "searching shows matches whether placed or not, and a placed match shows its shelf",
         %{conn: conn} do
      shelf_a = shelf_fixture(%{name: "L1"})
      shelf_b = shelf_fixture(%{name: "L2"})
      placed = game_fixture(%{name: "Catán"})
      _unplaced = game_fixture(%{name: "Carcassonne"})
      {:ok, _game, nil} = Shelves.assign_game(placed.id, shelf_a.id)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes/#{shelf_b.id}/asignar")

      html = lv |> form("#assign-search", %{q: "ca"}) |> render_change()

      assert html =~ "Catán"
      assert html =~ "en L1"
      assert html =~ "Carcassonne"
    end

    test "tapping a placed match moves it and shows Movido desde ... Deshacer; Deshacer reverts",
         %{conn: conn} do
      shelf_a = shelf_fixture(%{name: "L1"})
      shelf_b = shelf_fixture(%{name: "L2"})
      game = game_fixture(%{name: "Catán"})
      {:ok, _game, nil} = Shelves.assign_game(game.id, shelf_a.id)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes/#{shelf_b.id}/asignar")
      lv |> form("#assign-search", %{q: "cat"}) |> render_change()

      html =
        lv
        |> element("button[phx-value-game-id='#{game.id}']", "Catán")
        |> render_click()

      assert html =~ "Movido desde L1"
      assert html =~ "Deshacer"
      assert shelf_b.id |> Shelves.games_on_shelf() |> Enum.map(& &1.id) == [game.id]

      html = lv |> element("button", "Deshacer") |> render_click()

      refute html =~ "Deshacer"
      assert shelf_a.id |> Shelves.games_on_shelf() |> Enum.map(& &1.id) == [game.id]
      assert Shelves.games_on_shelf(shelf_b.id) == []
    end

    test "tapping a game already on the current shelf is a no-op with no toast", %{conn: conn} do
      shelf = shelf_fixture(%{name: "L1"})
      game = game_fixture(%{name: "Catán"})
      {:ok, _game, nil} = Shelves.assign_game(game.id, shelf.id)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes/#{shelf.id}/asignar")
      lv |> form("#assign-search", %{q: "cat"}) |> render_change()

      html =
        lv
        |> element("button[phx-value-game-id='#{game.id}']", "Catán")
        |> render_click()

      refute html =~ "Movido desde"
      refute html =~ "toast-bottom"
    end

    test "a failed save reverts and shows No se pudo guardar with a working Reintentar",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "L1"})
      game = game_fixture(%{name: "Catán"})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes/#{shelf.id}/asignar")

      # Simulate the shelf disappearing mid-session (e.g. deleted by another
      # staff member) — the LiveView's own `@shelf.id` is now stale, so the
      # next assign attempt hits the `shelf_id` foreign key constraint.
      PukllayClub.Repo.delete_all(from(s in PukllayClub.Catalog.Shelf, where: s.id == ^shelf.id))

      html =
        lv
        |> element("button[phx-value-game-id='#{game.id}']", "Catán")
        |> render_click()

      assert html =~ "No se pudo guardar"
      assert html =~ "Reintentar"
      assert PukllayClub.Catalog.get_game!(game.id).shelf_id == nil

      # Reintentar re-sends the same assignment — still fails the same way,
      # since the shelf still doesn't exist, but must not crash.
      html = lv |> element("button", "Reintentar") |> render_click()
      assert html =~ "No se pudo guardar"
    end
  end
end
