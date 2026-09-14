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

  describe "renaming a shelf from the assign screen header (D-10)" do
    setup :register_and_log_in_staff

    test "Renombrar opens a modal; a valid rename persists", %{conn: conn} do
      shelf = shelf_fixture(%{name: "L1"})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes/#{shelf.id}/asignar")

      html = lv |> element("button", "Renombrar") |> render_click()
      assert html =~ "Renombrar estante"

      html =
        lv
        |> form("#rename-shelf-form", %{name: "L1 (Cooperativos)"})
        |> render_submit()

      assert html =~ "Asignando a L1 (Cooperativos)"
      assert Shelves.get_shelf!(shelf.id).name == "L1 (Cooperativos)"
    end

    test "a 41-character name shows a field error and does not save", %{conn: conn} do
      shelf = shelf_fixture(%{name: "L1"})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes/#{shelf.id}/asignar")
      lv |> element("button", "Renombrar") |> render_click()

      html =
        lv
        |> form("#rename-shelf-form", %{name: String.duplicate("a", 41)})
        |> render_submit()

      assert html =~ "should be at most 40 character"
      assert Shelves.get_shelf!(shelf.id).name == "L1"
    end
  end

  describe "ShelfLive.Index — Estantes management (D-10, UI-SPEC E5)" do
    setup :register_and_log_in_staff

    test "shows the empty state with no shelves, then creates L1 and L2 in order",
         %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/admin/estantes")
      assert html =~ "Todavía no creaste estantes."

      html = lv |> form("#create-shelf-form", %{name: "L1"}) |> render_submit()
      assert html =~ "L1"

      html = lv |> form("#create-shelf-form", %{name: "L2"}) |> render_submit()
      refute html =~ "Todavía no creaste estantes."
      assert html =~ "L1"
      assert html =~ "L2"
      assert Enum.map(Shelves.list_shelves(), & &1.name) == ["L1", "L2"]
    end

    test "rejects a duplicate name with a field error", %{conn: conn} do
      shelf_fixture(%{name: "L1"})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      html = lv |> form("#create-shelf-form", %{name: "L1"}) |> render_submit()

      assert html =~ "has already been taken"
    end

    test "↓ on L1 swaps it below L2; ↑ on the new top shelf (L2) is a no-op", %{conn: conn} do
      l1 = shelf_fixture(%{name: "L1"})
      l2 = shelf_fixture(%{name: "L2"})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")

      html =
        lv
        |> element("button[phx-value-shelf-id='#{l1.id}'][aria-label='Bajar L1']")
        |> render_click()

      assert Enum.map(Shelves.list_shelves(), & &1.name) == ["L2", "L1"]
      assert html =~ "L2"

      html =
        lv
        |> element("button[phx-value-shelf-id='#{l2.id}'][aria-label='Subir L2']")
        |> render_click()

      assert Enum.map(Shelves.list_shelves(), & &1.name) == ["L2", "L1"]
      assert html =~ "L1"
    end

    test "?vista=lista shows groups L1/L2 (empty group still titled) and Sin ubicar, filterable",
         %{conn: conn} do
      l1 = shelf_fixture(%{name: "L1"})
      _l2 = shelf_fixture(%{name: "L2"})
      catan = game_fixture(%{name: "Catán"})
      _wingspan = game_fixture(%{name: "Wingspan"})
      {:ok, _game, nil} = Shelves.assign_game(catan.id, l1.id)

      {:ok, lv, html} = live(conn, ~p"/admin/estantes?vista=lista")

      assert html =~ "L1"
      assert html =~ "L2"
      assert html =~ "Sin ubicar"
      assert html =~ "Catán"
      assert html =~ "Wingspan"

      html = lv |> form("#pick-list-filter", %{q: "cat"}) |> render_change()

      assert html =~ "L1"
      assert html =~ "L2"
      assert html =~ "Sin ubicar"
      assert html =~ "Catán"
      refute html =~ "Wingspan"
    end
  end
end
