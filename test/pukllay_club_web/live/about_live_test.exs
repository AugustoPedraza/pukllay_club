defmodule PukllayClubWeb.AboutLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PukllayClubWeb.ClubLinks

  describe "GET /club and GET /quienes-somos (D-01: two aliases, no redirect)" do
    test "GET /club returns 200 and renders, not a redirect", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ~p"/club")
    end

    test "GET /quienes-somos returns 200 and renders, not a redirect", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ~p"/quienes-somos")
    end

    test "both routes render the same verbatim hero copy (D-06)", %{conn: conn} do
      {:ok, _view, club_html} = live(conn, ~p"/club")
      {:ok, _view, quienes_html} = live(conn, ~p"/quienes-somos")

      for html <- [club_html, quienes_html] do
        assert html =~ "Conectá jugando"
        assert html =~ "Club de juegos de mesa · Jujuy"

        assert html =~
                 "Nos juntamos todos los sábados a jugar. Venís, te sentás, alguien te explica."
      end
    end

    test "both routes render the shared footer shell", %{conn: conn} do
      {:ok, _view, club_html} = live(conn, ~p"/club")
      {:ok, _view, quienes_html} = live(conn, ~p"/quienes-somos")

      assert club_html =~ "pk-footer"
      assert quienes_html =~ "pk-footer"
    end

    test "renders nav-links with Quiénes Somos marked active, never a breadcrumb", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      assert html =~ ~s(aria-current="page")
      refute html =~ "pk-nav-crumb"
    end

    test "renders no search-morph control (About passes no nav_search slot) (01.1-08)", %{
      conn: conn
    } do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      refute html =~ "pk-search-morph"
    end

    test "the drawer marks Quiénes Somos as the current page (01.1-09)", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      inicio_link = doc |> LazyHTML.query(".pk-drawer-links a:first-child") |> LazyHTML.to_html()
      quienes_link = doc |> LazyHTML.query(".pk-drawer-links a:last-child") |> LazyHTML.to_html()

      refute inicio_link =~ ~s(aria-current="page")
      assert quienes_link =~ ~s(aria-current="page")
    end
  end

  describe "join CTA renders in the hero, not the header (D-05 superseded, plan 01.1-08)" do
    test "both /club and /quienes-somos render the CTA with the WhatsApp href and rel=noopener noreferrer", %{
      conn: conn
    } do
      {:ok, _view, club_html} = live(conn, ~p"/club")
      {:ok, _view, quienes_html} = live(conn, ~p"/quienes-somos")

      for html <- [club_html, quienes_html] do
        assert html =~ "Sumate"
        assert html =~ ClubLinks.whatsapp_group_url()
        assert html =~ ~s(rel="noopener noreferrer")
      end
    end

    test "both routes render no join CTA inside #app-header", %{conn: conn} do
      {:ok, _view, club_html} = live(conn, ~p"/club")
      {:ok, _view, quienes_html} = live(conn, ~p"/quienes-somos")

      for html <- [club_html, quienes_html] do
        header_html =
          html
          |> LazyHTML.from_document()
          |> LazyHTML.query("#app-header")
          |> LazyHTML.to_html()

        refute header_html =~ "Sumate"
      end
    end
  end

  describe "mobile sticky join-CTA bar (01.1-09, D-05 superseded)" do
    test "both /club and /quienes-somos render .pk-about-cta-bar with the WhatsApp href", %{
      conn: conn
    } do
      {:ok, _view, club_html} = live(conn, ~p"/club")
      {:ok, _view, quienes_html} = live(conn, ~p"/quienes-somos")

      for html <- [club_html, quienes_html] do
        bar_html =
          html
          |> LazyHTML.from_document()
          |> LazyHTML.query(".pk-about-cta-bar")
          |> LazyHTML.to_html()

        assert bar_html =~ ClubLinks.whatsapp_group_url()
      end
    end
  end
end
