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

    test "hero renders both the mobile (sm:hidden) and desktop (hidden sm:block) taglines (sketch 046, Pitfall 6)",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      assert html =~ "Volvé a jugar. Volvé a encontrarte."

      assert html =~
               "Nos juntamos todos los sábados a jugar. Venís, te sentás, alguien te explica."

      doc = LazyHTML.from_document(html)
      mobile_html = doc |> LazyHTML.query("p.sm\\:hidden") |> LazyHTML.to_html()
      desktop_html = doc |> LazyHTML.query("p.hidden.sm\\:block") |> LazyHTML.to_html()

      assert mobile_html =~ "Volvé a jugar. Volvé a encontrarte."
      assert desktop_html =~ "Nos juntamos todos los sábados a jugar"
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

      assert html =~
               "Reservá tu lugar por $5.000. ¿Venís de sorpresa? Son $7.000 — pero siempre hay lugar para vos."

      refute html =~ "Nada. La entrada es libre y los juegos los ponemos nosotros."
      assert html =~ "¿Tengo que saber jugar?"

      assert html =~
               "No. La mayoría de los juegos se aprenden en diez minutos y siempre hay alguien para explicarte."

      assert html =~ "¿Puedo ir solo?"
      assert html =~ "Sí, mucha gente viene sola. Te sumamos a una mesa apenas llegás."

      dt_count =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#faq dt")
        |> Enum.count()

      assert dt_count == 4
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

    test "the #cierre band offers exactly one CTA (the shared Sumate component), not a duplicated WhatsApp/Instagram button pair (049)",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      cierre = LazyHTML.query(doc, "#cierre")
      cierre_html = LazyHTML.to_html(cierre)

      assert cierre_html =~ "Nos vemos el sábado"
      assert cierre_html =~ "Pukllay Club · San Salvador de Jujuy, Argentina ·"

      cta_buttons = LazyHTML.query(cierre, "a.btn")
      assert Enum.count(cta_buttons) == 1
      assert LazyHTML.attribute(cta_buttons, "href") == [ClubLinks.whatsapp_group_url()]
      assert LazyHTML.to_html(cta_buttons) =~ "Sumate"

      refute ClubLinks.instagram_url() in LazyHTML.attribute(cta_buttons, "href")

      meta_links = LazyHTML.query(cierre, "a:not(.btn)")
      assert Enum.count(meta_links) == 1
      assert LazyHTML.attribute(meta_links, "href") == [ClubLinks.instagram_url()]
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

    test "renders five real photo slides in order with five dots, no placeholder text remains (sketch 046, D-08, D-09)",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      rail_imgs = LazyHTML.query(doc, ".pk-about-rail img")

      assert Enum.count(rail_imgs) == 5

      srcs = LazyHTML.attribute(rail_imgs, "src")

      assert Enum.map(srcs, &(~r/about-([a-z]+)\.jpg/ |> Regex.run(&1) |> List.last())) ==
               ["juego", "explicacion", "ludoteca", "comunidad", "festejo"]

      alts = LazyHTML.attribute(rail_imgs, "alt")
      assert Enum.all?(alts, &(&1 != ""))

      slides = LazyHTML.query(doc, ".pk-about-slide[data-slide]")
      slide_names = LazyHTML.attribute(slides, "data-slide")

      assert Enum.count(slides) == 5
      assert Enum.uniq(slide_names) == slide_names

      dot_count = doc |> LazyHTML.query("[data-goto]") |> Enum.count()

      assert dot_count == 5
      assert html =~ ~s(aria-label="Foto 1")
      assert html =~ ~s(aria-label="Foto 2")
      assert html =~ ~s(aria-label="Foto 3")
      assert html =~ ~s(aria-label="Foto 4")
      assert html =~ ~s(aria-label="Foto 5")

      rail_html = doc |> LazyHTML.query(".pk-about-rail") |> LazyHTML.to_html()

      refute rail_html =~ "foto — mesa llena un sábado"
      refute rail_html =~ "foto — explicando un juego"
      refute rail_html =~ "foto — la ludoteca"
      refute rail_html =~ "foto — la comunidad"
      refute rail_html =~ "sabado de juegos"
    end
  end

  # Plan 01.4-02 Task 2 (tracer): the Contacto card's Google Maps thumbnail,
  # resolved end-to-end from ClubLinks.maps_url/0 through the rendered
  # anchor and <img>. Task 3 adds the WhatsApp/Instagram icon links.
  describe "Contacto card map thumbnail (D-04/D-05/D-06, plan 01.4-02 Task 2)" do
    test "renders a link to ClubLinks.maps_url() with target=_blank and rel=noopener noreferrer",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      map_anchor = LazyHTML.query(doc, ".pk-about-map-thumb")
      map_html = LazyHTML.to_html(map_anchor)

      assert Enum.count(map_anchor) == 1
      assert map_html =~ ClubLinks.maps_url()
      assert map_html =~ ~s(target="_blank")
      assert map_html =~ ~s(rel="noopener noreferrer")
    end

    test "renders an <img> whose src resolves under /images/ and ends in about-maps-thumb.jpg",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      img_src = doc |> LazyHTML.query(".pk-about-map-thumb img") |> LazyHTML.attribute("src") |> List.first()

      assert img_src =~ "/images/"
      assert img_src =~ "about-maps-thumb.jpg"
    end

    test "renders no href=\"#\" placeholder anchor anywhere on the page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      refute html =~ ~s(href="#")
    end

    test "the venue URL literal appears only in club_links.ex, never in about_live.ex" do
      about_live_source = File.read!("lib/pukllay_club_web/live/about_live.ex")

      refute about_live_source =~ "maps.app.goo.gl"
    end
  end

  # Plan 01.4-02 Task 3: the Contacto card's real WhatsApp/Instagram icon
  # links, resolved through the newly-public Layouts.social_links/1.
  describe "Contacto card icon links (plan 01.4-02 Task 3)" do
    test "renders exactly 2 links inside .pk-about-contact-links: WhatsApp and Instagram, in order",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      links = LazyHTML.query(doc, ".pk-about-contact-links a")
      hrefs = LazyHTML.attribute(links, "href")

      assert Enum.count(links) == 2
      assert hrefs == [ClubLinks.whatsapp_group_url(), ClubLinks.instagram_url()]

      refute ClubLinks.facebook_url() in hrefs
      refute Enum.any?(hrefs, &String.starts_with?(&1, "mailto:"))
    end

    test "each Contacto card link renders an inline <svg> and a visible Spanish text label",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      links = LazyHTML.query(doc, ".pk-about-contact-links a")
      links_html = LazyHTML.to_html(links)

      assert links_html =~ "<svg"
      assert links_html =~ "Grupo de WhatsApp"
      assert links_html =~ "Instagram"
    end
  end
end
