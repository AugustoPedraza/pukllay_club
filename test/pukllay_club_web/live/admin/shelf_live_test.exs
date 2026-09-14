defmodule PukllayClubWeb.Admin.ShelfLiveTest do
  use PukllayClubWeb.ConnCase, async: true

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
end
