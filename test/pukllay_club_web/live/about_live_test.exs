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

  # D-09: the club plays at the club and never lends games out — these
  # patterns catch any accidental "take it home"/lending framing creeping
  # into the page's copy.
  @lending_vocabulary ~r/prestamo|préstamo|alquil|llevar a casa|llevate|llévate/iu

  describe "About page content (SHELL-02)" do
    test "renders all four FAQ questions and answers verbatim, under #faq", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      assert html =~ "Lo que todos preguntan"
      assert html =~ "¿Cuándo y dónde?"
      assert html =~ "Todos los sábados desde las 16 hs, en el Club de Emprendedores, San Salvador de Jujuy."
      assert html =~ "¿Cuánto cuesta?"
      assert html =~ "Nada. La entrada es libre y los juegos los ponemos nosotros."
      assert html =~ "¿Tengo que saber jugar?"

      assert html =~
               "No. La mayoría de los juegos se aprenden en diez minutos y siempre hay alguien para explicarte."

      assert html =~ "¿Puedo ir solo?"
      assert html =~ "Sí, mucha gente viene sola. Te sumamos a una mesa apenas llegás."
    end

    test "renders the 'Qué hacemos' and 'Nuestra historia' paragraphs verbatim", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      assert html =~ "Qué hacemos"

      assert html =~
               "De más de 400 juegos elegimos la selección del día: esa es nuestra parte. La tuya es disfrutar."

      assert html =~ "Nuestra historia"

      assert html =~ "Todo empezó en abril de 2021"
      assert html =~ "Más de cinco años después nos sigue emocionando lo mismo"

      refute html =~
               "Empezamos en 2024 con una mesa y unos pocos juegos. Hoy somos una comunidad que se encuentra cada semana en San Salvador de Jujuy. Pukllay significa jugar en quechua."
    end

    test "the 'Qué hacemos' jump link resolves to a live #juntadas element, and Juntadas carries the new copy",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      assert html =~ ~s(href="#juntadas")
      assert html =~ ~s(id="juntadas")
      assert html =~ "Dónde y cuándo jugamos"

      assert html =~
               "Nos juntamos los sábados en el Club de Emprendedores, San Salvador de Jujuy. Los juegos los llevamos nosotros; vos traé las ganas."

      refute html =~
               "Nos juntamos todos los sábados desde las 16 hs en el Club de Emprendedores, San Salvador de Jujuy. La entrada es libre y los juegos los ponemos nosotros."
    end

    test "renders the closing CTA heading, both button labels and the meta line", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      assert html =~ "Nos vemos el sábado"
      assert html =~ "Grupo de WhatsApp"
      assert html =~ "Instagram"
      assert html =~ "Pukllay Club · San Salvador de Jujuy, Argentina ·"
    end

    test "/club and /quienes-somos render byte-identical HTML once per-connection session/CSRF tokens are normalized (D-01)",
         %{conn: conn} do
      {:ok, _view, club_html} = live(conn, ~p"/club")
      {:ok, _view, quienes_html} = live(conn, ~p"/quienes-somos")

      # live/2 mints a fresh CSRF token, a random root container id and a
      # phx-session/phx-static payload per connection, so raw HTML from two
      # separate live/2 calls is never byte-identical even for the exact
      # same route (verified empirically against this repo) — normalizing
      # only those four per-connection fields, never any real page content,
      # is what makes "byte-identical" a meaningful, non-flaky claim rather
      # than a permanently-failing one.
      normalize = fn html ->
        html
        |> String.replace(~r/csrf-token" content="[^"]*"/, "csrf-token\" content=\"X\"")
        |> String.replace(~r/data-phx-session="[^"]*"/, "data-phx-session=\"X\"")
        |> String.replace(~r/data-phx-static="[^"]*"/, "data-phx-static=\"X\"")
        |> String.replace(~r/id="phx-[^"]*"/, "id=\"phx-X\"")
      end

      assert normalize.(club_html) == normalize.(quienes_html)
    end

    test "the footer's #faq, #contacto and #juntadas links all resolve to a real element id on the page",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      assert html =~ ~s(id="faq")
      assert html =~ ~s(id="contacto")
      assert html =~ ~s(id="juntadas")
    end

    test "never frames the club as lending or renting games to take home (D-09)", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      refute html =~ @lending_vocabulary
    end

    test "carries no design-source font reference and no inline style attribute (D-08)", %{
      conn: conn
    } do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      refute html =~ "Bricolage"
      refute html =~ "Instrument Sans"
      refute html =~ "JetBrains"
      refute html =~ ~s(style=")
    end

    test "renders the four-slide placeholder photo rail with dot navigation and no <img> (D-12)",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      assert html =~ "foto — mesa llena un sábado"
      assert html =~ "foto — explicando un juego"
      assert html =~ "foto — la ludoteca"
      assert html =~ "foto — la comunidad"

      rail_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-about-rail")
        |> LazyHTML.to_html()

      refute rail_html =~ "<img"

      dot_count =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("[data-goto]")
        |> Enum.count()

      assert dot_count == 4
      assert html =~ ~s(aria-label="Foto 1")
      assert html =~ ~s(aria-label="Foto 2")
      assert html =~ ~s(aria-label="Foto 3")
      assert html =~ ~s(aria-label="Foto 4")
    end
  end
end
