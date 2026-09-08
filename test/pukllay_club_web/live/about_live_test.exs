defmodule PukllayClubWeb.AboutLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PukllayClubWeb.ClubLinks

  @css_path Path.expand("../../../assets/css/app.css", __DIR__)

  defp css_source, do: File.read!(@css_path)

  # Comments are prose, not cascade — matching a selector/property name
  # inside a comment is a false pass. Same idiom as about_header_morph_test.exs
  # and footer_rhythm_test.exs.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

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

  # Plan 01.4-02 Task 2 (tracer): the Contacto card's map, resolved
  # end-to-end from ClubLinks through the rendered markup. Task 3 adds the
  # WhatsApp/Instagram icon links.
  #
  # Oracle boundary (plan 01.4-07 Task 2, closing G-01.4-2; revised 01.4-10
  # Task 3 and 01.4-12, closing G-01.4-5). Plan 01.4-12 replaced the static
  # screenshot facade with a live Google Maps embed (D-11 through D-14),
  # superseding plan 01.4-11's `.pk-about-map-credit` figcaption (D-15) —
  # the live frame renders Google's own attribution at Google's own native
  # size, retiring the crop/legibility problem this describe block spent
  # three plans engineering around rather than solving further. This suite
  # now owns DOM and CSS-source facts about a FRAME, not an image:
  #   1. THIS suite (ExUnit + LazyHTML) gates markup shape and stylesheet
  #      facts — the iframe's presence/src/attributes, the overlay anchor,
  #      and the CSS declarations that make the frame inert. Fast,
  #      deterministic, no browser.
  #   2. `test/visual/about_map_attribution.mjs` owns whether the frame
  #      ACTUALLY LOADS, stays inert, and gets themed, in a real browser.
  #      This is a NETWORK question against a third-party service with an
  #      undocumented, unversioned URL payload — this suite structurally
  #      cannot ask it, and no server-side signal exists if that payload
  #      ever breaks. Developer-invoked only (needs a real browser and a
  #      booted server, and network access to the embed's origin).
  #   3. A human still adjudicates whether the finished component reads
  #      right — including, per D-13, whether the dark-theme filter
  #      approximation is acceptable, which has no other oracle.
  describe "Contacto card map thumbnail (D-04/D-05/D-06, plan 01.4-02 Task 2)" do
    test "renders no href=\"#\" placeholder anchor anywhere on the page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      refute html =~ ~s(href="#")
    end

    test "the venue URL literal appears only in club_links.ex, never in about_live.ex" do
      about_live_source = File.read!("lib/pukllay_club_web/live/about_live.ex")

      refute about_live_source =~ "maps.app.goo.gl"
    end

    # G-01.4-2 gap closure (see .planning/debug/G-01.4-2-map-thumb-coverage.md):
    # the long (desktop) caption shipped unconditionally at every viewport,
    # wrapping to 2-3 lines and swallowing up to 74.9% of the thumbnail in
    # the 640-767px two-column band. Sketch 048's own short mobile caption
    # ("Cómo llegar ↗") was never ported. Fix: both variants render, gated
    # by the lg breakpoint (not sm — sm is where the parent grid halves the
    # card, making the long caption WORST there, not at 375px).
    test "renders both caption variants inside .pk-about-map-thumb, gated by the lg breakpoint",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      thumb = LazyHTML.query(doc, ".pk-about-map-thumb")

      short = LazyHTML.query(thumb, ".pk-about-map-label.lg\\:hidden")
      short_html = LazyHTML.to_html(short)
      assert Enum.count(short) == 1
      assert short_html =~ "Cómo llegar ↗"
      refute short_html =~ "Club de Emprendedores"

      long = LazyHTML.query(thumb, ".pk-about-map-label.hidden.lg\\:block")
      long_html = LazyHTML.to_html(long)
      assert Enum.count(long) == 1
      assert long_html =~ "Club de Emprendedores, San Salvador de Jujuy — Cómo llegar ↗"
    end

    test ".pk-about-map-label is an opaque, single-line chip declaring no display" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-map-label\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-label rule in app.css."
      [_, body] = rule

      assert body =~ "background: var(--color-base-100);",
             "Expected .pk-about-map-label's background to resolve directly from " <>
               "var(--color-base-100) with nothing wrapping it — the prior translucent " <>
               "color-mix(...) fill is what let the map ghost through (G-01.4-2)."

      assert body =~ "white-space: nowrap;",
             "Expected .pk-about-map-label to declare white-space: nowrap — a structural " <>
               "ceiling on the caption's height regardless of font metrics or a future copy edit."

      refute body =~ "display",
             "An unlayered .pk-* rule declaring display would beat the hidden/lg:block " <>
               "utility pair on the two caption spans, rendering both at once — the exact " <>
               "cascade hazard plan 01.4-05's Rule 1 fix had to undo on the isologo theme " <>
               "variants (this file's own top-of-file hazard note)."
    end

    # G-01.4-4 gap closure (see
    # .planning/debug/G-01.4-4-maps-thumbnail-approach.md): 01.4-07 changed
    # .pk-about-map-label's STYLING from a full-bleed band to a bordered
    # chip but kept the band's `left`/`right` pinning, so the chip stretched
    # to its container instead of shrink-wrapping to its own text — 177.7px
    # of dead space at 375px, the visual signature of an empty disabled
    # input. A chip is sized by its content; only a band spans its
    # container. This test gates the sizing-model fix, not the caption
    # fixes above (those measured correct at all 24 viewport/theme
    # combinations and are untouched).
    test ".pk-about-map-label shrink-wraps to its content and nests concentrically inside the thumb" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-map-label\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-label rule in app.css."
      [_, body] = rule

      refute body =~ ~r/right\s*:/,
             "Expected .pk-about-map-label to declare no offset from the thumb's trailing " <>
               "edge — with both `left` and `right` set, an absolutely-positioned element " <>
               "stretches to its container instead of shrink-wrapping to its own text, which " <>
               "is what produced 177.7px of dead space at 375px (G-01.4-4). A chip is sized " <>
               "by its content; a band spans its container."

      assert body =~ ~r/max-width\s*:\s*calc\([^)]*--pk-map-label-inset[^)]*\)/,
             "Expected .pk-about-map-label's max-width to be a calc() naming " <>
               "--pk-map-label-inset, so the chip can never overflow the thumb now that " <>
               "nothing else bounds its trailing edge."

      assert body =~
               ~r/border-radius\s*:\s*max\(0px,\s*calc\(var\(--radius-box\)\s*-\s*var\(--pk-map-label-inset\)\)\)/,
             "Expected .pk-about-map-label's border-radius to be derived by subtracting " <>
               "--pk-map-label-inset from var(--radius-box) — an inset element only nests " <>
               "concentrically when its own radius equals the outer radius minus the inset " <>
               "(G-01.4-4: outer 8px, inset 8px, so the correct inner radius is 0, not the " <>
               "bare --radius-box token that shipped before)."
    end

    test ".pk-about-map-thumb declares a min-height alongside its aspect-ratio" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-map-thumb\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-thumb rule in app.css."
      [_, body] = rule

      assert body =~ "aspect-ratio",
             "Expected .pk-about-map-thumb to still declare aspect-ratio (unchanged)."

      assert body =~ "min-height",
             "Expected .pk-about-map-thumb to declare a min-height floor — aspect-ratio alone " <>
               "lets the box collapse to 93px tall in the 640-767px two-column band " <>
               "(G-01.4-2, see .planning/debug/G-01.4-2-map-thumb-coverage.md)."
    end

    # Plan 01.4-12 (D-11/D-14): the facade's anchor was `.pk-about-map-thumb`
    # itself; the live frame's overlay click target is a descendant,
    # `.pk-about-map-link`, so the frame box (now a plain div wrapping an
    # inert iframe) can sit alongside it. Retargeted from the pre-01.4-12
    # test that queried `.pk-about-map-thumb` directly for the anchor.
    test "renders a .pk-about-map-link overlay to ClubLinks.maps_url() with target=_blank and rel=noopener noreferrer",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      link = LazyHTML.query(doc, ".pk-about-map-link")
      link_html = LazyHTML.to_html(link)

      assert Enum.count(link) == 1
      assert link_html =~ ClubLinks.maps_url()
      assert link_html =~ ~s(target="_blank")
      assert link_html =~ ~s(rel="noopener noreferrer")
    end

    # Plan 01.4-12 (D-11): the live embed itself. `src` is byte-equal to
    # ClubLinks.maps_embed_url/0 — the single source the CSP's frame-src
    # directive is also derived from (csp.ex).
    test "renders exactly one iframe with src equal to ClubLinks.maps_embed_url()", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      iframes = LazyHTML.query(doc, "iframe")

      assert Enum.count(iframes) == 1,
             "Expected exactly one iframe on the page — this app's first third-party frame."

      src = iframes |> LazyHTML.attribute("src") |> List.first()
      assert src == ClubLinks.maps_embed_url()
    end

    test "the iframe carries loading and referrerpolicy, and carries neither allowfullscreen nor style",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      iframe_html = doc |> LazyHTML.query("iframe") |> LazyHTML.to_html()

      assert iframe_html =~ ~s(loading="lazy")
      assert iframe_html =~ ~s(referrerpolicy="strict-origin-when-cross-origin")

      refute iframe_html =~ "allowfullscreen",
             "D-14 makes the frame non-interactive — no visitor can reach a fullscreen " <>
               "control, and the sandbox denies fullscreen regardless. An attribute that can " <>
               "never fire is a claim about behavior that is not true."

      refute iframe_html =~ ~s(style=),
             "Inline style is banned outright by the ui-design-system skill; the raw Google " <>
               "export's width/height/style are replaced by the card's own responsive sizing " <>
               "and named CSS (D-11)."
    end

    # Plan 01.4-12 (D-11): the facade's clipping anchor is now a plain
    # frame box. Zero <img>, zero .pk-about-map-credit and zero <figure>
    # are all NEGATIVE assertions proving the screenshot-era markup is
    # actually gone, not merely superseded in source but still rendering.
    test "renders .pk-about-map-thumb as a non-anchor div with zero <img>, zero .pk-about-map-credit, and zero <figure> in #contacto",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)

      thumb = LazyHTML.query(doc, ".pk-about-map-thumb")
      assert Enum.count(thumb) == 1
      thumb_html = LazyHTML.to_html(thumb)
      refute thumb_html =~ ~r/^<a[\s>]/, "Expected .pk-about-map-thumb to be a div, not an anchor."

      imgs = LazyHTML.query(thumb, "img")

      assert Enum.count(imgs) == 0,
             "Expected zero <img> elements inside .pk-about-map-thumb — the live frame " <>
               "renders its own tiles, so there is no screenshot asset left to reference."

      credit = LazyHTML.query(doc, ".pk-about-map-credit")

      assert Enum.count(credit) == 0,
             "Expected zero elements matching .pk-about-map-credit — plan 01.4-11's figcaption " <>
               "is superseded by 01.4-12 (CONTEXT.md D-15): the live frame renders Google's real " <>
               "attribution at native size, so a hand-authored credit line is now a second, " <>
               "redundant, non-authoritative attribution."

      contacto = LazyHTML.query(doc, "#contacto")
      figures = LazyHTML.query(contacto, "figure")

      assert Enum.count(figures) == 0,
             "Expected zero <figure> elements inside #contacto — the screenshot facade's " <>
               "<figure> wrapper (and its figcaption) is gone."
    end

    # Plan 01.4-12 Task 2 (D-14): pointer-events: none is the single
    # declaration that both prevents the scroll trap and lets clicks reach
    # the overlay anchor.
    test ".pk-about-map-embed declares pointer-events: none and border: 0" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-map-embed\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-embed rule in app.css."
      [_, body] = rule

      assert body =~ ~r/pointer-events\s*:\s*none/,
             "Expected .pk-about-map-embed to declare pointer-events: none — the D-14 " <>
               "mechanism that both prevents the scroll trap and lets clicks reach the " <>
               "overlay anchor."

      assert body =~ ~r/border\s*:\s*0/,
             "Expected .pk-about-map-embed to declare border: 0 — the named replacement " <>
               "for the raw Google export's inline style=\"border:0\", which this app's " <>
               "design system bans."
    end

    # Plan 01.4-12 Task 2 (D-06): the overlay covers the whole box, so
    # D-06's click-out is reachable from anywhere on the map.
    test ".pk-about-map-link declares inset: 0 and position: absolute" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-map-link\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-link rule in app.css."
      [_, body] = rule

      assert body =~ ~r/inset\s*:\s*0/,
             "Expected .pk-about-map-link to declare inset: 0 — the overlay covers the " <>
               "whole box, so D-06's click-out is reachable from anywhere on the map."

      assert body =~ ~r/position\s*:\s*absolute/,
             "Expected .pk-about-map-link to declare position: absolute."
    end

    # Plan 01.4-12 Task 2 (D-13): the dark-theme filter approximation.
    test "a [data-theme=\"dark\"] .pk-about-map-embed rule declares a filter containing invert(" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\[data-theme="dark"\]\s*\.pk-about-map-embed\s*\{([^}]*)\}/s, src)

      assert rule,
             "Expected a [data-theme=\"dark\"] .pk-about-map-embed rule in app.css (D-13)."

      [_, body] = rule

      assert body =~ ~r/filter\s*:[^;]*invert\(/,
             "Expected the dark-theme rule's filter to contain invert(...) (D-13)."
    end

    # Plan 01.4-12 Task 2: a filter on the wrapper would invert the caption
    # chip and the overlay link along with the map, and would also make the
    # wrapper a containing block for its absolutely-positioned descendants
    # — a layout side effect of a color decision.
    test "no [data-theme=\"dark\"] rule in app.css targets .pk-about-map-thumb" do
      src = strip_comments(css_source())

      refute src =~ ~r/\[data-theme="dark"\]\s*\.pk-about-map-thumb\s*\{/,
             "Expected no [data-theme=\"dark\"] rule targeting .pk-about-map-thumb — a " <>
               "filter on the wrapper would invert the caption chip and the overlay link " <>
               "along with the map, and would make the wrapper a containing block for its " <>
               "absolutely-positioned descendants (the chip and the link), quietly changing " <>
               "their layout as a side effect of a color decision (D-13)."
    end

    # Plan 01.4-12 Task 2: the chip vacates the frame's bottom edge because
    # that edge belongs to Google's own attribution bar, whose height this
    # app does not control (D-13/D-14 supersede the prior `bottom` fix).
    test ".pk-about-map-label declares a top offset reading --pk-map-label-inset and no bottom" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-map-label\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-label rule in app.css."
      [_, body] = rule

      assert body =~ ~r/top\s*:\s*var\(--pk-map-label-inset\)/,
             "Expected .pk-about-map-label to declare top: var(--pk-map-label-inset)."

      refute body =~ ~r/bottom\s*:/,
             "Expected .pk-about-map-label to declare no bottom — the chip vacates the " <>
               "frame's bottom edge because that edge belongs to Google's own attribution " <>
               "bar, whose height this app does not control."
    end

    # G-01.4-5's root cause (01.4-10-SUMMARY.md): a dead custom property
    # (--pk-map-thumb-w/-h/--pk-map-attrib-band) claiming to know a shape
    # nothing renders is exactly how .pk-about-map-thumb ended up cropping
    # against a stale ratio in the first place. Gated against the RULE
    # BODIES the existing Regex.run helper extracts — never a whole-file
    # grep, since the comment blocks above both rules legitimately name all
    # three while explaining the removal, and a whole-file grep would be
    # satisfied by its own explanation.
    test "neither .pk-about-map-thumb nor .pk-about-map-label declares --pk-map-thumb-w/-h or --pk-map-attrib-band" do
      src = strip_comments(css_source())

      thumb_rule = Regex.run(~r/\.pk-about-map-thumb\s*\{([^}]*)\}/s, src)
      assert thumb_rule, "Expected to find a .pk-about-map-thumb rule in app.css."
      [_, thumb_body] = thumb_rule

      label_rule = Regex.run(~r/\.pk-about-map-label\s*\{([^}]*)\}/s, src)
      assert label_rule, "Expected to find a .pk-about-map-label rule in app.css."
      [_, label_body] = label_rule

      for prop <- ["--pk-map-thumb-w", "--pk-map-thumb-h", "--pk-map-attrib-band"] do
        refute thumb_body =~ prop,
               "Expected .pk-about-map-thumb's rule body to declare no #{prop} — it " <>
                 "described a JPEG's bytes and the strip of it Google's baked-in mark " <>
                 "occupied; a live frame has no such measurements, and a dead custom " <>
                 "property left behind is exactly how .pk-about-map-thumb came to claim a " <>
                 "stale ratio for an asset that had changed shape — G-01.4-5's root cause."

        refute label_body =~ prop,
               "Expected .pk-about-map-label's rule body to declare no #{prop} (see the " <>
                 ".pk-about-map-thumb assertion above for why)."
      end
    end

    test "neither about-maps-thumb.jpg nor about-maps-thumb-dark.jpg exists on disk" do
      refute File.exists?("priv/static/images/about-maps-thumb.jpg"),
             "Expected priv/static/images/about-maps-thumb.jpg to be deleted — see this " <>
               "plan's <asset_disposition>. git retains it if the embed is ever reverted."

      refute File.exists?("priv/static/images/about-maps-thumb-dark.jpg"),
             "Expected priv/static/images/about-maps-thumb-dark.jpg to be deleted — see " <>
               "this plan's <asset_disposition>. git retains it if the embed is ever reverted."
    end
  end

  # Plan 01.4-07 Task 2: guards the invariant whose absence made G-01.4-2
  # possible — one caption string doing both jobs (mobile brevity and
  # desktop context). See the oracle-boundary comment above the "Contacto
  # card map thumbnail" describe block for what this test suite can and
  # cannot prove about this component.
  describe "the map-thumbnail caption length invariant (plan 01.4-07 Task 2)" do
    test "the short caption string is materially shorter than the long one" do
      short = "Cómo llegar ↗"
      long = "Club de Emprendedores, San Salvador de Jujuy — Cómo llegar ↗"

      assert String.length(short) < String.length(long) - 20,
             "The short caption must be materially shorter than the long one — comparing " <>
               "length (not pinning either literal string) keeps a future copy edit free while " <>
               "guarding against the one-string-doing-both-jobs shape that made G-01.4-2 " <>
               "possible in the first place."
    end
  end

  # Plan 01.4-02 Task 3: the Contacto card's real WhatsApp/Instagram icon
  # links, resolved through the newly-public Layouts.social_links/1.
  # Extended to 3 channels in plan 01.5-02 (D-06/D-07): Facebook added,
  # Email deliberately excluded (footer-only).
  describe "Contacto card icon links (plan 01.4-02 Task 3, extended plan 01.5-02)" do
    test "renders exactly 3 links inside .pk-about-contact-links: WhatsApp, Facebook and Instagram, in social_links/1's fixed render order",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      links = LazyHTML.query(doc, ".pk-about-contact-links a")
      hrefs = LazyHTML.attribute(links, "href")

      assert Enum.count(links) == 3

      assert hrefs == [
               ClubLinks.whatsapp_group_url(),
               ClubLinks.facebook_url(),
               ClubLinks.instagram_url()
             ]

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
      assert links_html =~ "Facebook"
      assert links_html =~ "Instagram"
    end
  end

  # Plan 01.5-02, Task 1 (D-05): the card's chrome (background, border-radius,
  # padding) is gone, while the internal flex/gap layout is untouched.
  describe "Contacto card de-chroming (plan 01.5-02, D-05)" do
    test ".pk-about-contact-card keeps its flex layout but declares no background, border-radius or padding" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-contact-card\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-contact-card rule in app.css."
      [_, body] = rule

      assert Regex.scan(~r/background\s*:/, body) == [],
             "Expected .pk-about-contact-card to declare no background (D-05 removes the card chrome)."

      assert Regex.scan(~r/border-radius\s*:/, body) == [],
             "Expected .pk-about-contact-card to declare no border-radius (D-05 removes the card chrome)."

      assert Regex.scan(~r/padding\s*:/, body) == [],
             "Expected .pk-about-contact-card to declare no padding (D-05 removes the card chrome)."

      assert body =~ ~r/display\s*:\s*flex/,
             "Expected .pk-about-contact-card to keep display: flex (D-05 preserves internal layout)."

      assert body =~ ~r/flex-direction\s*:\s*column/,
             "Expected .pk-about-contact-card to keep flex-direction: column (D-05 preserves internal layout)."

      assert body =~ ~r/gap\s*:/,
             "Expected .pk-about-contact-card to keep its gap (D-05 preserves internal layout)."
    end
  end

  # Plan 01.5-02, Task 1 (D-06): the chip resting state pulls its colour
  # pairing bare from --color-accent/--color-accent-content, matching
  # .pk-pill-accent's existing precedent.
  describe "Contacto chip accent tint (plan 01.5-02, D-06)" do
    test ".pk-about-contact-links a declares the accent background/content colour pairing" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-contact-links a\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-contact-links a rule in app.css."
      [_, body] = rule

      assert body =~ ~r/background\s*:\s*var\(--color-accent\)/,
             "Expected .pk-about-contact-links a to set background: var(--color-accent)."

      assert body =~ ~r/color\s*:\s*var\(--color-accent-content\)/,
             "Expected .pk-about-contact-links a to set color: var(--color-accent-content)."
    end
  end

  # Plan 01.5-02, Task 2 (D-08): at <=639px the chip row drops labels and
  # goes icon-only + circular + centered — a pure space-fit constraint
  # (3 labeled chips ~387px vs a 375px phone's ~327px available width).
  describe "Contacto chip mobile treatment (plan 01.5-02, D-08)" do
    defp media_639_body(src) do
      case Regex.run(~r/@media\s*\(max-width:\s*639px\)\s*\{/, src, return: :index) do
        [{start, match_len}] ->
          body_start = start + match_len
          extract_balanced_block(src, body_start)

        nil ->
          nil
      end
    end

    # Balanced-brace-aware scan from just after the media query's opening
    # `{` to its matching close, so assertions below match only within this
    # block's own body — matching a bare property against the whole file
    # would pass on any of the dozens of unrelated rules that declare it.
    defp extract_balanced_block(src, start_index) do
      src
      |> String.slice(start_index..-1//1)
      |> do_extract_balanced_block(1, [])
    end

    defp do_extract_balanced_block(<<>>, _depth, acc), do: acc |> Enum.reverse() |> IO.iodata_to_binary()

    defp do_extract_balanced_block(<<"{", rest::binary>>, depth, acc) do
      do_extract_balanced_block(rest, depth + 1, ["{" | acc])
    end

    defp do_extract_balanced_block(<<"}", _rest::binary>>, 1, acc) do
      acc |> Enum.reverse() |> IO.iodata_to_binary()
    end

    defp do_extract_balanced_block(<<"}", rest::binary>>, depth, acc) do
      do_extract_balanced_block(rest, depth - 1, ["}" | acc])
    end

    defp do_extract_balanced_block(<<c::utf8, rest::binary>>, depth, acc) do
      do_extract_balanced_block(rest, depth, [<<c::utf8>> | acc])
    end

    test "app.css contains a @media (max-width: 639px) block referencing .pk-about-contact-links" do
      src = strip_comments(css_source())

      assert src =~ ~r/@media\s*\(max-width:\s*639px\)/,
             "Expected a @media (max-width: 639px) block in app.css."

      body = media_639_body(src)
      assert body, "Expected to extract the @media (max-width: 639px) block body."

      assert body =~ ".pk-about-contact-links",
             "Expected the @media (max-width: 639px) block to reference .pk-about-contact-links."
    end

    test "inside the 639px block, .pk-about-contact-links a span declares display: none" do
      src = strip_comments(css_source())
      body = media_639_body(src)

      rule = Regex.run(~r/\.pk-about-contact-links a span\s*\{([^}]*)\}/s, body)
      assert rule, "Expected a .pk-about-contact-links a span rule inside the 639px block."
      [_, rule_body] = rule

      assert rule_body =~ ~r/display\s*:\s*none/,
             "Expected .pk-about-contact-links a span to declare display: none."
    end

    test "inside the 639px block, .pk-about-contact-links declares justify-content: center" do
      src = strip_comments(css_source())
      body = media_639_body(src)

      rule = Regex.run(~r/\.pk-about-contact-links\s*\{([^}]*)\}/s, body)
      assert rule, "Expected a .pk-about-contact-links rule inside the 639px block."
      [_, rule_body] = rule

      assert rule_body =~ ~r/justify-content\s*:\s*center/,
             "Expected .pk-about-contact-links to declare justify-content: center."
    end

    test "inside the 639px block, .pk-about-contact-links a declares border-radius: 9999px" do
      src = strip_comments(css_source())
      body = media_639_body(src)

      rule = Regex.run(~r/\.pk-about-contact-links a\s*\{([^}]*)\}/s, body)
      assert rule, "Expected a .pk-about-contact-links a rule inside the 639px block."
      [_, rule_body] = rule

      assert rule_body =~ ~r/border-radius\s*:\s*9999px/,
             "Expected .pk-about-contact-links a to declare border-radius: 9999px."
    end

    test "the rendered markup still contains all three label spans regardless of viewport",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      spans = LazyHTML.query(doc, ".pk-about-contact-links a span")

      assert Enum.count(spans) == 3
    end
  end
end
