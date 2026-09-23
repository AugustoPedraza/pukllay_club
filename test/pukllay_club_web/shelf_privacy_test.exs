defmodule PukllayClubWeb.ShelfPrivacyTest do
  @moduledoc """
  D-16 negative proof: a game's shelf location never appears on the
  public game detail page, for either a visitor or an authenticated
  staff session — shelf location is staff-only data.
  """
  use PukllayClubWeb.ConnCase, async: true

  import PukllayClub.CatalogFixtures
  import PukllayClub.CopiesFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Catalog.Shelves

  @secret_shelf_name "Estante-Secreto-Test"

  test "a visitor's /juegos/:id HTML never contains the shelf name", %{conn: conn} do
    shelf = shelf_fixture(%{name: @secret_shelf_name})
    game = game_fixture()
    copy = copy_fixture(%{game_id: game.id})
    {:ok, _copy} = Shelves.place_copy(copy.id, shelf.id, 0)

    conn = get(conn, ~p"/juegos/#{game}")

    refute html_response(conn, 200) =~ @secret_shelf_name
  end

  describe "a staff session" do
    setup :register_and_log_in_staff

    test "does not see the shelf name on /juegos/:id either", %{conn: conn} do
      shelf = shelf_fixture(%{name: @secret_shelf_name})
      game = game_fixture()
      copy = copy_fixture(%{game_id: game.id})
      {:ok, _copy} = Shelves.place_copy(copy.id, shelf.id, 0)

      conn = get(conn, ~p"/juegos/#{game}")

      refute html_response(conn, 200) =~ @secret_shelf_name
    end
  end
end
