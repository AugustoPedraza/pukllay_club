defmodule PukllayClubWeb.CatalogLive.IndexTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

  describe "GET /" do
    test "mounts for an unauthenticated visitor with no redirect (CATALOG-08)", %{conn: conn} do
      game_fixture()

      assert {:ok, _view, _html} = live(conn, ~p"/")
    end

    test "renders the seeded game's name", %{conn: conn} do
      game_fixture(%{name: "On Mars"})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "On Mars"
    end

    test "renders the game cover as an img whose src starts with the R2 public base URL", %{
      conn: conn
    } do
      game_fixture(%{
        thumbnail_url: "https://images.test.invalid/games/184267/cover-thumb.webp"
      })

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~s(src="https://images.test.invalid/games/184267/cover-thumb.webp")
    end

    test "never renders a BGG-hosted image src (CATALOG-09)", %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      refute html =~ "geekdo-images.com"
      refute html =~ "boardgamegeek.com"
    end

    test "renders the brand placeholder (not a broken image) for a game with no thumbnail, keeping the title accessible (D-18)",
         %{conn: conn} do
      game_fixture(%{
        name: "Juego Sin BGG",
        bgg_id: nil,
        thumbnail_url: nil,
        cover_url: nil,
        enrichment_status: "no_bgg_id"
      })

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "hero-puzzle-piece"
      assert html =~ "Juego Sin BGG"
    end

    test "clamps a long game title instead of pushing the card layout", %{conn: conn} do
      game_fixture(%{
        name: "Un título extraordinariamente largo que debería ocupar más de dos líneas de texto"
      })

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "line-clamp-2"
    end
  end
end
