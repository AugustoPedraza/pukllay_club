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

  # Plan 01.5-08 (G-01.5-3 item 4): the About page opts into `bottom_collapse`
  # (layouts.ex), which cancels <main>'s own `pb-20` while leaving the default
  # top-padding utilities (`pt-8 sm:pt-20`) in place. Asserting BOTH halves is
  # the point — a future "simplification" to `boundary_collapse` would also
  # collapse the top boundary and move the hero, and would only be caught by
  # the second half of this assertion failing.
  describe "bottom-boundary opt-in (plan 01.5-08, G-01.5-3 item 4)" do
    test "the about page's <main> carries the collapsed-bottom class, not pb-20, and keeps the default top-padding utilities",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      main_class =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("main")
        |> LazyHTML.attribute("class")
        |> List.first()

      assert main_class =~ "pk-bottom-collapse"
      refute main_class =~ "pb-20"
      refute main_class =~ "pk-boundary-collapse"
      assert main_class =~ "pt-8"
      assert main_class =~ "sm:pt-20"
    end
  end

  # G-01.5-5 gap closure (plan 01.5-09,
  # .planning/debug/G-01.5-5-cierre-footer-gap.md): the shared
  # `main.pk-bottom-collapse/pk-boundary-collapse + .pk-footer` rules above
  # are correct everywhere except this one page, where #cierre's own tint
  # paints the identical token the footer paints. Both halves of the
  # assertion below matter: the page-scoped override must exist and zero
  # THIS boundary, AND the shared declarations it overrides must still carry
  # their own non-zero margin values — a future author "simplifying" by
  # zeroing the shared rule instead would silently move the catalog index's
  # and detail page's own closed 24px/16px boundary decisions, which have
  # shipped unreported for two phases and were never the subject of this
  # complaint.
  describe "About page footer-boundary override (G-01.5-5 gap closure, plan 01.5-09)" do
    test "a body:has(#cierre)-scoped rule zeroes the last-band-to-footer margin without touching the shared collapse declarations' own non-zero values" do
      src = strip_comments(css_source())

      override =
        Regex.run(
          ~r/body:has\(#cierre\)\s+main\.pk-bottom-collapse\s*\+\s*\.pk-footer\s*,\s*body:has\(#cierre\)\s+main\.pk-boundary-collapse\s*\+\s*\.pk-footer\s*\{([^}]*)\}/s,
          src
        )

      assert override,
             "Expected a body:has(#cierre)-scoped override targeting both " <>
               "main.pk-bottom-collapse + .pk-footer and " <>
               "main.pk-boundary-collapse + .pk-footer — the surface condition " <>
               "(#cierre's tint matching .pk-footer's background) is unique to the " <>
               "About page, so the override must be scoped by #cierre's presence, " <>
               "not applied unconditionally."

      [_, override_body] = override

      assert override_body =~ ~r/margin-top\s*:\s*0\s*;/,
             "Expected the page-scoped override to zero margin-top for the About page's " <>
               "last-band-to-footer boundary."

      # Both shared declarations this override outbids must still declare
      # their own non-zero margin — proves the fix didn't "succeed" by
      # weakening the rule every other page still depends on.
      unmediated =
        Regex.run(
          ~r/(?<!body:has\(#cierre\)\s)main\.pk-bottom-collapse\s*\+\s*\.pk-footer\s*,\s*main\.pk-boundary-collapse\s*\+\s*\.pk-footer\s*\{([^}]*)\}/s,
          src
        )

      assert unmediated, "Expected the shared, unmediated main.*-collapse + .pk-footer rule to still exist."
      [_, unmediated_body] = unmediated

      refute unmediated_body =~ ~r/margin-top\s*:\s*0\s*;/,
             "The shared unmediated boundary rule must keep its own non-zero margin-top — " <>
               "the catalog index and detail page still depend on it."

      assert unmediated_body =~ ~r/margin-top\s*:\s*1\.5rem\s*;/,
             "Expected the shared unmediated boundary rule to still declare margin-top: 1.5rem."

      mobile_media =
        case Regex.run(~r/@media\s*\(max-width:\s*480px\)\s*\{/, src, return: :index) do
          [{start, match_len}] -> String.slice(src, (start + match_len)..-1//1)
          nil -> nil
        end

      assert mobile_media, "Expected an @media (max-width: 480px) block."

      mobile_rule =
        Regex.run(
          ~r/(?<!body:has\(#cierre\)\s)main\.pk-bottom-collapse\s*\+\s*\.pk-footer\s*,\s*main\.pk-boundary-collapse\s*\+\s*\.pk-footer\s*\{([^}]*)\}/s,
          mobile_media
        )

      assert mobile_rule, "Expected the shared <=480px main.*-collapse + .pk-footer rule to still exist."
      [_, mobile_rule_body] = mobile_rule

      refute mobile_rule_body =~ ~r/margin-top\s*:\s*0\s*;/,
             "The shared <=480px boundary rule must keep its own non-zero margin-top."

      assert mobile_rule_body =~ ~r/margin-top\s*:\s*1rem\s*;/,
             "Expected the shared <=480px boundary rule to still declare margin-top: 1rem."
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

    test "the #cierre band offers exactly one CTA (the shared Sumate component) and a plain signature carrying no links at all (plan 01.5-03, D-13)",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      cierre = LazyHTML.query(doc, "#cierre")
      cierre_html = LazyHTML.to_html(cierre)

      assert cierre_html =~ "Nos vemos el sábado"
      assert cierre_html =~ "Pukllay Club ·"
      assert cierre_html =~ "San Salvador de Jujuy, Argentina"

      cta_buttons = LazyHTML.query(cierre, "a.btn")
      assert Enum.count(cta_buttons) == 1
      assert LazyHTML.attribute(cta_buttons, "href") == [ClubLinks.whatsapp_group_url()]
      assert LazyHTML.to_html(cta_buttons) =~ "Sumate"

      # D-13 (plan 01.5-03): the trailing Instagram link that shipped since
      # plan 049 is gone — Contacto's chip row now covers all 3 channels
      # explicitly, making a fourth mention here redundant. The closing
      # band's only anchor is the Sumate button.
      meta_links = LazyHTML.query(cierre, "a:not(.btn)")
      assert Enum.empty?(meta_links)
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

      assert Enum.empty?(imgs),
             "Expected zero <img> elements inside .pk-about-map-thumb — the live frame " <>
               "renders its own tiles, so there is no screenshot asset left to reference."

      credit = LazyHTML.query(doc, ".pk-about-map-credit")

      assert Enum.empty?(credit),
             "Expected zero elements matching .pk-about-map-credit — plan 01.4-11's figcaption " <>
               "is superseded by 01.4-12 (CONTEXT.md D-15): the live frame renders Google's real " <>
               "attribution at native size, so a hand-authored credit line is now a second, " <>
               "redundant, non-authoritative attribution."

      contacto = LazyHTML.query(doc, "#contacto")
      figures = LazyHTML.query(contacto, "figure")

      assert Enum.empty?(figures),
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

    test "inside the 639px block, .pk-about-contact-links a span is visually hidden via sr-only (CR-01), not display: none" do
      src = strip_comments(css_source())
      body = media_639_body(src)

      rule = Regex.run(~r/\.pk-about-contact-links a span\s*\{([^}]*)\}/s, body)
      assert rule, "Expected a .pk-about-contact-links a span rule inside the 639px block."
      [_, rule_body] = rule

      refute rule_body =~ ~r/display\s*:\s*none/,
             "Expected .pk-about-contact-links a span NOT to declare display: none (CR-01: WhatsApp has no aria-label with labels: true, so hiding its span from the a11y tree removes its only accessible name)."

      assert rule_body =~ ~r/clip\s*:\s*rect\(0,\s*0,\s*0,\s*0\)/,
             "Expected .pk-about-contact-links a span to use the sr-only visually-hidden technique so its text stays in the accessibility tree."
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

  # Plan 01.5-02, Task 3 (D-09): the live Maps embed relocated from
  # #contacto into #juntadas, moved verbatim (every pre-existing embed
  # test above must keep passing unchanged).
  describe "Maps embed relocation to Juntadas (plan 01.5-02, D-09)" do
    test "#juntadas .pk-about-map-thumb renders exactly 1 element", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      thumb = LazyHTML.query(doc, "#juntadas .pk-about-map-thumb")

      assert Enum.count(thumb) == 1
    end

    test "#contacto .pk-about-map-thumb renders exactly 0 elements", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      thumb = LazyHTML.query(doc, "#contacto .pk-about-map-thumb")

      assert Enum.empty?(thumb)
    end

    test "the map thumb was moved, not copied — exactly 1 .pk-about-map-thumb page-wide",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      thumb = LazyHTML.query(doc, ".pk-about-map-thumb")

      assert Enum.count(thumb) == 1
    end

    test "the relocated iframe keeps its src and every security-relevant attribute byte-identical",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      iframe = LazyHTML.query(doc, "#juntadas .pk-about-map-embed")

      assert Enum.count(iframe) == 1
      assert LazyHTML.attribute(iframe, "src") == [ClubLinks.maps_embed_url()]
      assert LazyHTML.attribute(iframe, "loading") == ["lazy"]
      assert LazyHTML.attribute(iframe, "referrerpolicy") == ["strict-origin-when-cross-origin"]
      assert LazyHTML.attribute(iframe, "sandbox") == ["allow-scripts allow-same-origin"]
      assert LazyHTML.attribute(iframe, "tabindex") == ["-1"]
      assert LazyHTML.attribute(iframe, "aria-hidden") == ["true"]
    end

    test "#contacto a returns exactly the 3 chip anchors — the overlay map link left with the map",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      links = LazyHTML.query(doc, "#contacto a")
      hrefs = LazyHTML.attribute(links, "href")

      assert Enum.count(links) == 3

      assert hrefs == [
               ClubLinks.whatsapp_group_url(),
               ClubLinks.facebook_url(),
               ClubLinks.instagram_url()
             ]
    end
  end

  # Plan 01.5-03, Task 1 (D-13): the Cierre signature's markup and the
  # mobile size rule's specificity. The DOM half of "no trailing link" is
  # covered above ("#cierre band offers exactly one CTA..."); these tests
  # cover the two-line-wrap markup and the CSS-source facts that make the
  # mobile size rule un-out-specifiable (sketch 051's second bug,
  # about-page-content.md).
  describe "Cierre closing signature two-line wrap (plan 01.5-03, D-13)" do
    test "the signature paragraph carries both pk-about-eyebrow and pk-about-closing-meta, with exactly one pk-about-closing-break <br>",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      signature = LazyHTML.query(doc, "#cierre p.pk-about-eyebrow")

      assert Enum.count(signature) == 1
      [class] = LazyHTML.attribute(signature, "class")
      assert class =~ "pk-about-eyebrow"
      assert class =~ "pk-about-closing-meta"

      breaks = LazyHTML.query(doc, "#cierre .pk-about-closing-break")
      assert Enum.count(breaks) == 1
      assert LazyHTML.tag(breaks) == ["br"]
    end

    test "app.css declares a top-level .pk-about-closing-break rule with display: none" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-closing-break\s*\{([^}]*)\}/s, src)
      assert rule, "Expected a top-level .pk-about-closing-break rule in app.css."
      [_, body] = rule

      assert body =~ ~r/display\s*:\s*none/,
             "Expected the top-level .pk-about-closing-break rule to declare display: none."
    end

    test "inside the 639px block, #cierre .pk-about-closing-break declares display: block and #cierre .pk-about-closing-meta declares a font-size" do
      src = strip_comments(css_source())
      body = media_639_body(src)
      assert body, "Expected to extract the @media (max-width: 639px) block body."

      break_rule = Regex.run(~r/#cierre \.pk-about-closing-break\s*\{([^}]*)\}/s, body)
      assert break_rule, "Expected a #cierre .pk-about-closing-break rule inside the 639px block."
      [_, break_body] = break_rule

      assert break_body =~ ~r/display\s*:\s*block/,
             "Expected #cierre .pk-about-closing-break to declare display: block."

      meta_rule = Regex.run(~r/#cierre \.pk-about-closing-meta\s*\{([^}]*)\}/s, body)
      assert meta_rule, "Expected a #cierre .pk-about-closing-meta rule inside the 639px block."
      [_, meta_body] = meta_rule

      assert meta_body =~ ~r/font-size\s*:/,
             "Expected #cierre .pk-about-closing-meta to declare a font-size."
    end

    test "the .pk-about-eyebrow and .pk-about-eyebrow a rules are unchanged apart from added comments" do
      src = strip_comments(css_source())

      eyebrow_rule = Regex.run(~r/\.pk-about-eyebrow\s*\{([^}]*)\}/s, src)
      assert eyebrow_rule, "Expected a .pk-about-eyebrow rule in app.css."
      [_, eyebrow_body] = eyebrow_rule

      assert eyebrow_body =~ ~r/font-size\s*:\s*0\.75rem/
      assert eyebrow_body =~ ~r/text-transform\s*:\s*uppercase/
      assert eyebrow_body =~ ~r/letter-spacing\s*:\s*0\.1em/
      assert eyebrow_body =~ ~r/color\s*:\s*var\(--color-neutral\)/

      eyebrow_a_rule = Regex.run(~r/\.pk-about-eyebrow a\s*\{([^}]*)\}/s, src)
      assert eyebrow_a_rule, "Expected a .pk-about-eyebrow a rule in app.css."
      [_, eyebrow_a_body] = eyebrow_a_rule

      assert eyebrow_a_body =~ ~r/color\s*:\s*inherit/
      assert eyebrow_a_body =~ ~r/text-decoration\s*:\s*underline/
    end
  end

  # G-01.5-8 gap closure (plan 01.5-11,
  # .planning/debug/G-01.5-8-cierre-tagline-footer-grouping.md), second
  # lever's source guard. `.pk-about-eyebrow` and `.pk-footer-meta`
  # independently declare the same font-size/color pair, 475 lines apart in
  # app.css, because they express the same "de-emphasised meta" role —
  # nothing structural stops them re-converging. test/visual/about_geometry.mjs
  # has its own runtime check for this (checkSignatureFooterTypeCollision),
  # but that probe needs a booted dev server and is not part of `mix test`;
  # this is the source-level guard that runs in the normal suite.
  describe "Cierre closing signature desktop type register (G-01.5-8 gap closure, plan 01.5-11)" do
    test "the >=640px block gives #cierre .pk-about-closing-meta a color that is not var(--color-neutral)" do
      src = strip_comments(css_source())
      body = media_640_body(src)
      assert body, "Expected to extract the @media (min-width: 640px) block body."

      rule = Regex.run(~r/#cierre \.pk-about-closing-meta\s*\{([^}]*)\}/s, body)

      assert rule,
             "Expected a #cierre .pk-about-closing-meta rule inside the @media (min-width: 640px) " <>
               "block. Without it the Cierre closing signature (\"Pukllay Club · San Salvador de " <>
               "Jujuy, Argentina\") keeps resolving font-size, line-height, color, font-family and " <>
               "font-weight identically to .pk-footer-meta at desktop widths — the exact " <>
               "five-attribute collision G-01.5-8's diagnosis measured in both themes, which read " <>
               "the signature as the footer's own meta text instead of the closing statement's " <>
               "last line. The signature is .pk-about-eyebrow's only consumer on this page, so " <>
               "this override regresses no other caller."

      [_, rule_body] = rule

      assert rule_body =~ ~r/color\s*:/,
             "Expected the desktop #cierre .pk-about-closing-meta rule to declare a color."

      refute rule_body =~ ~r/color\s*:\s*var\(--color-neutral\)/,
             "Expected the desktop #cierre .pk-about-closing-meta color to resolve through a token " <>
               "OTHER than var(--color-neutral) — that is the exact token .pk-footer-meta uses, and " <>
               "reusing it here is the collision G-01.5-8 diagnosed: five computed type attributes " <>
               "(font-size, line-height, color, font-family, font-weight) identical between the " <>
               "signature and the footer's own meta text, in both themes, sharing nothing with the " <>
               "signature's own group (the 48px heading, the bordered pill button)."
    end

    test "the <=639px signature rule (D-13) is untouched — no color declared there, size stays 10px" do
      src = strip_comments(css_source())
      body = media_639_body(src)
      assert body, "Expected to extract the @media (max-width: 639px) block body."

      rule = Regex.run(~r/#cierre \.pk-about-closing-meta\s*\{([^}]*)\}/s, body)
      assert rule, "Expected the <=639px #cierre .pk-about-closing-meta rule to still exist."
      [_, rule_body] = rule

      assert rule_body =~ ~r/font-size\s*:\s*10px/,
             "Expected the <=639px signature rule to keep its own font-size: 10px unchanged — this " <>
               "gap closure is scoped to >=640px only, because the signature's rendered width below " <>
               "640px is an operand plan 01.5-13's G-01.5-10 mobile balance argument spends, and this " <>
               "lever deliberately moves no geometry."

      refute rule_body =~ ~r/color\s*:/,
             "Expected the <=639px signature rule to declare no color of its own — this gap " <>
               "closure's colour lever is desktop-only (the type collision is exact only there); the " <>
               "<=639px signature keeps inheriting .pk-about-eyebrow's base var(--color-neutral) " <>
               "unchanged, matching the behavior spec's 'byte-identical below 640px' requirement."
    end
  end

  # Plan 01.5-13 (G-01.5-10 gap closure —
  # .planning/debug/G-01.5-10-mobile-cierre-heading-tagline-balance.md):
  # source guard for #cierre's mobile COUNTERPART to the >=640px block above
  # (padding-block: 5rem; #cierre h2's clamp(2rem, 4vw, 3rem)).
  # test/visual/about_geometry.mjs has its own runtime checks for the
  # RENDERED effect (checkCierreProportionBudget, checkCierreHierarchy,
  # checkCierreNoWrap), but that probe needs a booted dev server and is not
  # part of `mix test`; this is the source-level guard that runs in the
  # normal suite, pinning the STRUCTURE the plan's own decision insists on:
  # "both levers ship in one media block, or neither."
  describe "Cierre mobile counterpart to the 640px block (G-01.5-10 gap closure, plan 01.5-13)" do
    test "the @media (max-width: 639px) block contains BOTH #cierre's own padding-block AND #cierre h2's own font-size/line-height" do
      src = strip_comments(css_source())
      body = media_639_body(src)
      assert body, "Expected to extract the @media (max-width: 639px) block body."

      padding_rule = Regex.run(~r/#cierre\s*\{([^}]*)\}/s, body)

      assert padding_rule,
             "Expected a bare #cierre rule inside the @media (max-width: 639px) block declaring " <>
               "its own padding-block. Without it, mobile Cierre falls back to the shared " <>
               ".pk-band padding (4.5rem/72px, sized for content-rich bands) — the G-01.5-10 " <>
               "diagnosis measured that as pad/content 1.67 against this page's own 0.19-0.53 " <>
               "band norm and this band's own accepted 0.90-1.02 desktop state, with 64.3% of " <>
               "the band rendering as empty ink."

      [_, padding_body] = padding_rule

      assert padding_body =~ ~r/padding-block\s*:/,
             "Expected the mobile #cierre rule to declare its own padding-block."

      h2_rule = Regex.run(~r/#cierre h2\s*\{([^}]*)\}/s, body)

      assert h2_rule,
             "Expected a #cierre h2 rule inside the @media (max-width: 639px) block declaring " <>
               "its own font-size. Without it, the mobile heading keeps the page-wide " <>
               "font-display text-2xl size with no Cierre-specific step at all (1.00x the page's " <>
               "own h2 norm at 375px, vs 1.33x at 640px and 2.00x at 1280px — G-01.5-10's E-08) " <>
               "and the closing signature (204.4px) keeps out-measuring the heading (163.7px), " <>
               "24.8% wider — the exact inversion the user called unbalanced."

      [_, h2_body] = h2_rule

      assert h2_body =~ ~r/font-size\s*:/,
             "Expected the mobile #cierre h2 rule to declare its own font-size."

      assert h2_body =~ ~r/line-height\s*:/,
             "Expected the mobile #cierre h2 rule to declare its own line-height — left to " <>
               "inherit, the rendered clear gap above the signature (declared 24px, rendered " <>
               "36px per the all-caps face's empty descent) becomes unpredictable, since the " <>
               "heading's line box is an operand in that arithmetic."
    end

    test "neither new #cierre rule declares a gap of its own — D-12's one flex gap still governs both viewports" do
      src = strip_comments(css_source())
      body = media_639_body(src)
      assert body, "Expected to extract the @media (max-width: 639px) block body."

      # Scoped to the two NEW #cierre/#cierre h2 rule bodies specifically,
      # not the whole 639px block — that block also legitimately contains
      # .pk-about-contact-links's own unrelated `gap: 1rem` (D-08), which a
      # whole-block scan would wrongly trip on.
      padding_rule = Regex.run(~r/#cierre\s*\{([^}]*)\}/s, body)
      assert padding_rule, "Expected a bare #cierre rule inside the @media (max-width: 639px) block."
      [_, padding_body] = padding_rule

      h2_rule = Regex.run(~r/#cierre h2\s*\{([^}]*)\}/s, body)
      assert h2_rule, "Expected a #cierre h2 rule inside the @media (max-width: 639px) block."
      [_, h2_body] = h2_rule

      failure_message =
        "Expected the mobile counterpart rules to declare no gap of their own. G-01.5-10's own " <>
          "diagnosis measured tightening #cierre's gap as making the 'too much space' " <>
          "complaint objectively WORSE (16px -> pad/content 1.85, 12px -> 1.95, both " <>
          "backwards) — the fix lever here is padding and heading size, never the gap."

      assert Regex.scan(~r/(?<![-\w])gap\s*:/, padding_body) == [], failure_message
      assert Regex.scan(~r/(?<![-\w])gap\s*:/, h2_body) == [], failure_message
    end

    test "#cierre .pk-band-inner's gap is declared exactly once in the whole stylesheet, with no per-viewport override" do
      src = strip_comments(css_source())

      selector_occurrences = ~r/#cierre \.pk-band-inner\s*\{/ |> Regex.scan(src) |> length()

      assert selector_occurrences == 1,
             "Expected exactly one #cierre .pk-band-inner rule in the whole stylesheet, found " <>
               "#{selector_occurrences}. D-12 requires the band's one internal spacing rule to " <>
               "stay a single declaration, unconditional at every width — a second, viewport-" <>
               "scoped declaration would reintroduce the two-spacing-system problem D-12 exists " <>
               "to prevent, and would be exactly the kind of scattered override this plan was " <>
               "structured to avoid ('both levers in one media block, or neither')."
    end
  end

  # Plan 01.5-03, Task 2 (D-12): every Cierre internal gap comes from ONE
  # flex gap on the content column, never per-element margins.
  describe "Cierre one flex gap (plan 01.5-03, D-12)" do
    test "#cierre .pk-band-inner is a top-level rule declaring display: flex, flex-direction: column, align-items: center and exactly one gap" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/#cierre \.pk-band-inner\s*\{([^}]*)\}/s, src)
      assert rule, "Expected a top-level #cierre .pk-band-inner rule in app.css."
      [_, body] = rule

      assert body =~ ~r/display\s*:\s*flex/
      assert body =~ ~r/flex-direction\s*:\s*column/
      assert body =~ ~r/align-items\s*:\s*center/

      assert ~r/(?<![-\w])gap\s*:/ |> Regex.scan(body) |> length() == 1,
             "Expected exactly one gap declaration in #cierre .pk-band-inner."
    end

    test "#cierre .pk-band-inner declares no margin" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/#cierre \.pk-band-inner\s*\{([^}]*)\}/s, src)
      assert rule, "Expected a top-level #cierre .pk-band-inner rule in app.css."
      [_, body] = rule

      assert Regex.scan(~r/margin/, body) == [],
             "Expected #cierre .pk-band-inner to declare no margin."
    end

    test "the #cierre content column keeps the text-center utility so the two-line signature stays centered",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      inner = LazyHTML.query(doc, "#cierre .pk-band-inner")

      assert Enum.count(inner) == 1
      [class] = LazyHTML.attribute(inner, "class")
      assert class =~ "text-center"
    end

    test "#cierre .pk-band-inner has exactly 3 element children (heading, button wrapper, signature)",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      children = LazyHTML.query(doc, "#cierre .pk-band-inner > *")

      assert Enum.count(children) == 3
    end
  end

  # Plan 01.5-03, Task 3 (D-10) shipped Cierre as a full-viewport moment on
  # desktop, compensated against the header's own live published height.
  # REVISED by plan 01.5-07 (G-01.5-3 items 3a/3b —
  # .planning/debug/cierre-band-whitespace.md): the header-height
  # compensation was removed (D-14 painted the band the header's own tint,
  # so the header no longer visually eats the band's top edge and the
  # compensation was silently shifting the gap split by one header height),
  # and the 100vh floor was reduced to 70vh/70dvh per the 01.5-07 checkpoint
  # decision (see 01.5-07-SUMMARY.md "Decisions").
  describe "Cierre full-screen desktop treatment (plan 01.5-03 D-10, revised 01.5-07, revised again G-01.5-5/6 gap closure)" do
    defp media_640_body(src) do
      case Regex.run(~r/@media\s*\(min-width:\s*640px\)\s*\{/, src, return: :index) do
        [{start, match_len}] ->
          body_start = start + match_len
          extract_balanced_block(src, body_start)

        nil ->
          nil
      end
    end

    test "the @media (min-width: 640px) block contains a #cierre rule declaring a fixed padding-block, not a viewport-height floor" do
      src = strip_comments(css_source())
      body = media_640_body(src)
      assert body, "Expected to extract the @media (min-width: 640px) block body."

      rule = Regex.run(~r/#cierre\s*\{([^}]*)\}/s, body)
      assert rule, "Expected a #cierre rule inside the @media (min-width: 640px) block."
      [_, rule_body] = rule

      # G-01.5-5/G-01.5-6 gap closure: min-height: 70vh/70dvh (01.5-07) was
      # still viewport-HEIGHT-coupled and reproduced the original "huge
      # space top and bottom" complaint on common ~900px-tall laptop
      # screens (measured 238.67px gaps). Replaced with a fixed
      # padding-block so the whitespace amount is a constant, never a
      # function of the viewer's screen height. See the CSS comment above
      # this rule for the full measurement/rationale.
      #
      # 01.5-09 (G-01.5-6): retuned 8rem -> 5rem. This is the cheap guard
      # that the MECHANISM stays a fixed padding rather than a
      # height-relative floor (the refutes below); the bare value itself is
      # expected to move whenever the value is deliberately retuned — see
      # app.css's comment above this rule for the run-unit rationale and the
      # recorded 6rem runner-up.
      assert rule_body =~ ~r/padding-block\s*:\s*5rem\s*;/,
             "Expected #cierre to declare a fixed padding-block: 5rem at >=640px, not a viewport-height-relative min-height."

      refute rule_body =~ ~r/min-height/,
             "#cierre must not reintroduce a min-height floor at this width — that mechanism is exactly what produced the huge-whitespace regression this test guards against."

      refute rule_body =~ ~r/display\s*:\s*flex/,
             "#cierre no longer needs flex/align-items to centre its content — a fixed padding-block produces identical top/bottom gaps via ordinary block flow, which is a stronger evenness guarantee. Reintroducing flex here is a sign the min-height mechanism crept back in."
    end

    test "the #cierre rule inside the >=640px block does not reintroduce the retired header-height padding shorthand" do
      src = strip_comments(css_source())
      body = media_640_body(src)

      rule = Regex.run(~r/#cierre\s*\{([^}]*)\}/s, body)
      assert rule, "Expected a #cierre rule inside the @media (min-width: 640px) block."
      [_, rule_body] = rule

      # This asserted "no padding override at all" until this session's
      # G-01.5-5/6 gap closure deliberately added padding-block: 8rem (see
      # the test above) — that is now the correct, expected state, not a
      # regression. What must still never come back is the SPECIFIC
      # defective declaration 01.5-07 removed: the bare `padding:` shorthand
      # keyed on --pk-header-h, which both shifted the top/bottom split by
      # one header height (D-14 made the compensation unnecessary) and
      # silently zeroed the shared bottom padding via its 3-value form.
      refute rule_body =~ ~r/(?<![-\w])padding\s*:\s*var\(--pk-header-h/,
             "The header-height top-padding compensation (`padding: var(--pk-header-h, ...) 0 0`) was " <>
               "removed on purpose (01.5-07, G-01.5-3): D-14 painted #cierre the header's own tint, so " <>
               "the header no longer eats visually into the band's top edge, and reinstating this " <>
               "specific declaration reopens the uneven-gap defect it caused. This is distinct from " <>
               "padding-block: 8rem (asserted above), which is this session's deliberate fixed-height " <>
               "mechanism, not the retired compensation."
    end

    test "the block contains #cierre h2 with font-size: clamp(2rem, 4vw, 3rem)" do
      src = strip_comments(css_source())
      body = media_640_body(src)

      rule = Regex.run(~r/#cierre h2\s*\{([^}]*)\}/s, body)
      assert rule, "Expected a #cierre h2 rule inside the @media (min-width: 640px) block."
      [_, rule_body] = rule

      assert rule_body =~ ~r/font-size\s*:\s*clamp\(2rem,\s*4vw,\s*3rem\)/
    end

    test "the @media (min-width: 640px) block declares no gap — the one gap from D-12 governs both viewports" do
      src = strip_comments(css_source())
      body = media_640_body(src)

      assert Regex.scan(~r/(?<![-\w])gap\s*:/, body) == [],
             "Expected the desktop full-screen block to declare no gap of its own."
    end

    test "--pk-header-h is republished from exactly one place and is still read by at least 3 rules in app.css" do
      src = strip_comments(css_source())

      consumer_count = ~r/var\(--pk-header-h/ |> Regex.scan(src) |> length()

      # 01.5-07 removed #cierre's own reads of this token (its header-height
      # compensation was the thing being removed); .pk-shelf's
      # scroll-margin-top, .pk-title-echo's top and .pk-poster-col's sticky
      # top remain, so the floor drops from >=4 to >=3, not to 0 — this is
      # still a regression guard against a parallel/duplicate token, not a
      # weakened check.
      assert consumer_count >= 3,
             "Expected --pk-header-h to be read by at least 3 rules in app.css (regression guard against a parallel token)."

      layouts_src =
        File.read!(Path.expand("../../../lib/pukllay_club_web/components/layouts.ex", __DIR__))

      publisher_count =
        ~r/setProperty\("--pk-header-h"/ |> Regex.scan(layouts_src) |> length()

      assert publisher_count == 1,
             "Expected --pk-header-h to be published from exactly one place in layouts.ex."
    end
  end

  # Plan 01.5-04, Task 1 (D-11): the closing band's own Sumate button is
  # suppressed at the exact same 480px threshold where the sticky
  # .pk-about-cta-bar takes over, so a member never sees the same ask
  # twice on one screen, and no width range exists with neither visible.
  describe "Cierre CTA suppression at the sticky-bar threshold (plan 01.5-04, D-11)" do
    defp media_480_body(src) do
      case Regex.run(~r/@media\s*\(max-width:\s*480px\)\s*\{/, src, return: :index) do
        [{start, match_len}] ->
          body_start = start + match_len
          extract_balanced_block(src, body_start)

        nil ->
          nil
      end
    end

    test "app.css contains exactly one @media (max-width: 480px) block" do
      src = strip_comments(css_source())

      matches = Regex.scan(~r/@media\s*\(max-width:\s*480px\)/, src)

      assert length(matches) == 1,
             "Expected exactly one @media (max-width: 480px) block in app.css — both halves " <>
               "of the sticky-bar/Cierre-button display swap must share one threshold (D-11), " <>
               "never two separate blocks at the same value."
    end

    test "inside the 480px block, .pk-about-cta-bar declares display: block and #cierre .pk-about-cierre-cta declares display: none" do
      src = strip_comments(css_source())
      body = media_480_body(src)
      assert body, "Expected to extract the @media (max-width: 480px) block body."

      bar_rule = Regex.run(~r/\.pk-about-cta-bar\s*\{([^}]*)\}/s, body)
      assert bar_rule, "Expected a .pk-about-cta-bar rule inside the 480px block."
      [_, bar_body] = bar_rule
      assert bar_body =~ ~r/display\s*:\s*block/

      cierre_rule = Regex.run(~r/#cierre \.pk-about-cierre-cta\s*\{([^}]*)\}/s, body)
      assert cierre_rule, "Expected a #cierre .pk-about-cierre-cta rule inside the 480px block."
      [_, cierre_body] = cierre_rule
      assert cierre_body =~ ~r/display\s*:\s*none/
    end

    # Plan 01.5-08 (G-01.5-3 item 4): the in-flow .pk-about-cta-spacer this
    # test used to also assert here is gone, replaced by a page-scoped
    # document-end clearance rule. That replacement must share the SAME
    # 480px block as .pk-about-cta-bar's own display swap for the identical
    # co-location reason D-11 itself exists: a threshold mismatch between
    # "bar appears" and "clearance is reserved" would put the bar back over
    # the footer at some width.
    test "inside the 480px block, a body:has(.pk-about-cta-bar) rule reserves document-end padding-bottom" do
      src = strip_comments(css_source())
      body = media_480_body(src)
      assert body, "Expected to extract the @media (max-width: 480px) block body."

      clearance_rule = Regex.run(~r/body:has\(\.pk-about-cta-bar\)\s*\{([^}]*)\}/s, body)

      assert clearance_rule,
             "Expected a body:has(.pk-about-cta-bar) rule inside the SAME 480px block as " <>
               ".pk-about-cta-bar's own display swap — a mismatched threshold would put the " <>
               "fixed bar back over the footer at some width."

      [_, clearance_body] = clearance_rule
      assert clearance_body =~ ~r/padding-bottom\s*:\s*\S/
    end

    # G-01.5-7 gap closure (plan 01.5-10 —
    # .planning/debug/G-01.5-7-cta-bar-background-visible.md): the inherited
    # `4.5rem` literal was 3px loose against the bar's shipped 69px height
    # and became 1px TIGHT the moment plan 01.5-10's Task 1 grew the Sumate
    # button to 48px — a hard literal pinned against a content-derived
    # height is guaranteed to drift, and already had, in both directions.
    # This asserts the replacement is a calc() expression composed from the
    # bar's own parts (rather than a bare literal that could silently drift
    # again the next time the button's size changes), naming the drift this
    # guards against in its own failure message.
    test "the body:has(.pk-about-cta-bar) clearance is composed via calc(), not a bare literal" do
      src = strip_comments(css_source())
      body = media_480_body(src)
      assert body, "Expected to extract the @media (max-width: 480px) block body."

      clearance_rule = Regex.run(~r/body:has\(\.pk-about-cta-bar\)\s*\{([^}]*)\}/s, body)
      assert clearance_rule, "Expected a body:has(.pk-about-cta-bar) rule inside the 480px block."
      [_, clearance_body] = clearance_rule

      assert clearance_body =~ ~r/padding-bottom\s*:\s*calc\(/,
             "Expected the document-end clearance to be a calc() expression derived from the " <>
               "bar's own padding/button-height/border, not a bare px/rem literal. A bare " <>
               "literal against a content-derived bar height is guaranteed to drift — the " <>
               "inherited 4.5rem was 3px loose against the 69px pre-01.5-10 bar and became 1px " <>
               "TIGHT the moment the button grew to 48px, which is exactly the recurrence this " <>
               "guard exists to catch."
    end

    test "no .pk-about-cta-spacer selector remains anywhere in app.css" do
      src = strip_comments(css_source())

      refute src =~ "pk-about-cta-spacer",
             "Expected .pk-about-cta-spacer to be fully removed — its clearance job moved to " <>
               "a body:has(.pk-about-cta-bar) document-end reservation (plan 01.5-08)."
    end

    test "the Cierre button wrapper carries pk-about-cierre-cta and still contains the Sumate anchor",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      wrapper = LazyHTML.query(doc, "#cierre .pk-about-cierre-cta")
      assert Enum.count(wrapper) == 1

      button = LazyHTML.query(doc, "#cierre .pk-about-cierre-cta a.btn")
      assert Enum.count(button) == 1
    end

    test "no .pk-about-cta-spacer element renders on the about page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      assert Enum.empty?(LazyHTML.query(doc, ".pk-about-cta-spacer"))
    end

    # Plan 01.5-08 (Rule 1 bug, found via Task 3's live CDP probe): this
    # element is not the shell's space-y-4 wrapper's last child
    # (#pk-about-morph-mark and the <noscript> marker follow it), and
    # Tailwind v4's space-y-* utilities apply margin-block-end (not
    # margin-top, unlike v3) to every non-last child. Left un-neutralised,
    # that gave this position:fixed;bottom:0 element a real 16px margin
    # pushing its rendered box 16px above the true viewport edge — live-
    # measured (390x900 viewport): bar top=815px/bottom=884px instead of the
    # 831px/900px its own bottom:0 promises, eating directly into this
    # plan's reserved clearance. Source-level regression guard; the live
    # probe (test/visual/about_geometry.mjs) is the oracle that actually
    # caught the defect.
    test "the base .pk-about-cta-bar rule declares margin-block-end: 0" do
      src = strip_comments(css_source())

      base_rule = Regex.run(~r/(?<!:has\()\.pk-about-cta-bar\s*\{([^}]*)\}/s, src)
      assert base_rule, "Expected a base (non-media-query) .pk-about-cta-bar rule in app.css."
      [_, base_body] = base_rule

      assert base_body =~ ~r/margin-block-end\s*:\s*0\b/,
             "Expected the base .pk-about-cta-bar rule to zero margin-block-end — otherwise " <>
               "the shell's space-y-4 utility (Tailwind v4: margin-block-end on every non-last " <>
               "child) pushes this fixed, bottom:0 bar away from the true viewport edge."
    end

    test "no .pk-about-cta-bar rule anywhere in app.css declares justify-content (daisyUI's .btn already centers)" do
      src = strip_comments(css_source())

      rule_bodies =
        ~r/\.pk-about-cta-bar\s*\{([^}]*)\}/s
        |> Regex.scan(src)
        |> Enum.map(fn [_, body] -> body end)

      assert rule_bodies != [], "Expected at least one .pk-about-cta-bar rule in app.css."

      for body <- rule_bodies do
        assert Regex.scan(~r/justify-content/, body) == [],
               "Expected no .pk-about-cta-bar rule to declare justify-content — daisyUI's " <>
                 ".btn already centers; sketch 051's centering fix was for its own hand-rolled " <>
                 "button CSS, not this app's."
      end
    end

    # G-01.5-7 gap closure (plan 01.5-10 —
    # .planning/debug/G-01.5-7-cta-bar-background-visible.md): no gate in
    # this repo can observe a RENDERED colour (about_geometry.mjs is a
    # geometric oracle only, and check-theme-drift.sh is colour-scoped to a
    # different comparison entirely), so a source-level assertion on the two
    # token names is the only recurrence guard this fix can have. Pins BOTH
    # the fill this bar must KEEP (base-100, deliberately different from its
    # two siblings — the 6-arm differential proved swapping it is inert on
    # the reported symptom and actively worse at the page bottom) and the
    # border token it must now USE (neutral, replacing base-300).
    test "the base .pk-about-cta-bar rule keeps base-100 fill and uses the neutral border token, not base-300" do
      src = strip_comments(css_source())

      base_rule = Regex.run(~r/(?<!:has\()\.pk-about-cta-bar\s*\{([^}]*)\}/s, src)
      assert base_rule, "Expected a base (non-media-query) .pk-about-cta-bar rule in app.css."
      [_, base_body] = base_rule

      assert base_body =~ ~r/background\s*:\s*var\(--color-base-100\)/,
             "Expected .pk-about-cta-bar to keep background: var(--color-base-100) — a 6-arm " <>
               "runtime differential proved swapping the fill to base-200 (matching its two " <>
               "siblings) is INERT on the reported symptom (1.406:1 light / 1.19:1 dark, " <>
               "byte-identical to doing nothing) and makes the fill collapse to 1.000:1 against " <>
               "the surface it overlays at the real page bottom — strictly worse there."

      assert base_body =~ ~r/border-top\s*:\s*1px\s+solid\s+var\(--color-neutral\)/,
             "Expected .pk-about-cta-bar's border-top to resolve through var(--color-neutral) " <>
               "(measured 5.785:1 light / 7.128:1 dark against the bar's fill), the same token " <>
               ".pk-title-echo already migrated to for the identical reason."

      refute base_body =~ ~r/border-top\s*:\s*1px\s+solid\s+var\(--color-base-300\)/,
             "Expected the retired border-300 pairing to be gone entirely — it measured only " <>
               "1.406:1 light / 1.19:1 dark against the bar's own fill, under the 3:1 WCAG " <>
               "1.4.11 non-text-contrast floor this fix exists to clear."
    end
  end

  # Plan 01.5-04, Task 2 (D-14): page-wide band background alternation —
  # plain -> tint -> dark -> plain -> tint top to bottom, with FAQ's dark
  # band kept as a deliberate one-off highlight outside the alternation.
  describe "About page band background alternation (plan 01.5-04, D-14)" do
    test "app.css declares exactly one top-level .pk-band-tint rule with background: var(--color-base-200) as its only declaration" do
      src = strip_comments(css_source())

      matches = Regex.scan(~r/(?m)^\.pk-band-tint\s*\{/, src)

      assert length(matches) == 1,
             "Expected exactly one top-level .pk-band-tint rule in app.css."

      [_, body] = Regex.run(~r/\.pk-band-tint\s*\{([^}]*)\}/s, src)
      declarations = body |> String.split(";") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

      assert declarations == ["background: var(--color-base-200)"],
             "Expected .pk-band-tint to declare background: var(--color-base-200) and nothing else, got: #{inspect(declarations)}"
    end

    test "the .pk-band-dark rule still declares background: var(--color-primary) and color: var(--color-primary-content) unchanged" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-band-dark\s*\{([^}]*)\}/s, src)
      assert rule, "Expected a .pk-band-dark rule in app.css."
      [_, body] = rule

      assert body =~ ~r/background\s*:\s*var\(--color-primary\)/
      assert body =~ ~r/color\s*:\s*var\(--color-primary-content\)/
    end

    test "reading section.pk-band class attributes in document order yields the state sequence plain, tint, dark, plain, tint",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      sections = LazyHTML.query(doc, "section.pk-band")
      classes = LazyHTML.attribute(sections, "class")

      assert Enum.count(classes) == 5,
             "Expected exactly 5 section.pk-band elements on the About page."

      states =
        Enum.map(classes, fn class ->
          cond do
            class =~ "pk-band-dark" -> :dark
            class =~ "pk-band-tint" -> :tint
            true -> :plain
          end
        end)

      assert states == [:plain, :tint, :dark, :plain, :tint],
             "Expected the band background sequence (document order) to be " <>
               "plain, tint, dark, plain, tint — got: #{inspect(states)}. Asserting the ORDER " <>
               "is the point: a correct set of classes attached to the wrong sections would " <>
               "still satisfy a count-only assertion."
    end

    test "exactly 2 sections carry pk-band-tint and exactly 1 carries pk-band-dark, and it is #faq",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)

      tinted = LazyHTML.query(doc, "section.pk-band-tint")
      assert Enum.count(tinted) == 2

      dark = LazyHTML.query(doc, "section.pk-band-dark")
      assert Enum.count(dark) == 1
      assert LazyHTML.attribute(dark, "id") == ["faq"]
    end

    test "no section carries both pk-band-tint and pk-band-dark", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      sections = LazyHTML.query(doc, "section.pk-band")
      classes = LazyHTML.attribute(sections, "class")

      refute Enum.any?(classes, fn class -> class =~ "pk-band-tint" and class =~ "pk-band-dark" end),
             "Expected no section to carry both pk-band-tint and pk-band-dark — FAQ's dark " <>
               "treatment stays a one-off highlight, not also tinted."
    end

    # G-01.5-2 gap closure (.planning/debug/inter-band-whitespace-gap.md,
    # plan 01.5-06): the shared shell's `space-y-4` wrapper (layouts.ex:670)
    # puts 16px of margin-block-end on every non-last direct child, which on
    # the About page are these `.pk-band` sections — producing a visible
    # whitespace strip at all four band-to-band boundaries. This is a
    # CSS-source oracle (not geometry — see test/visual/about_geometry.mjs
    # for the rendered-rect oracle this same gap closure adds), but it is
    # the first test in this describe block to assert anything about
    # SPACING rather than colour/class, since none of the four tests above
    # could have caught a margin defect.
    test ".pk-band declares margin-block-end: 0, cancelling the shell's space-y-4 margin at every band-to-band boundary" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/(?m)^\.pk-band\s*\{([^}]*)\}/s, src)

      assert rule,
             "Expected a top-level .pk-band rule in app.css."

      [_, body] = rule

      assert body =~ ~r/margin-block-end\s*:\s*0\b/,
             "Expected .pk-band to declare margin-block-end: 0. Without it, layouts.ex's " <>
               "shared shell wrapper (<div class=\"mx-auto space-y-4\">) puts 16px of " <>
               "margin-block-end on every non-last direct child — on the About page those " <>
               "children are the .pk-band sections themselves, producing a visible whitespace " <>
               "strip at all four band-to-band boundaries (fotos->tint, tint->faq, faq->plain, " <>
               "plain->cierre; see .planning/debug/inter-band-whitespace-gap.md). This zero is " <>
               "load-bearing, not a redundant reset — do not delete it as dead CSS."
    end
  end

  # G-01.5-7 gap closure (this session, 2026-09-09): .pk-nav is a
  # layouts.ex-shared component (every page's sticky header), not
  # About-scoped — but the bug was only DISCOVERED via the About page,
  # because D-14 (this same phase, plan 01.5-04, tested above) is the only
  # place in the app with a dark, high-contrast band a scrolled visitor can
  # land the header over. The regression guard lives here rather than in
  # layouts_test.exs to keep it next to the D-14 test it is a direct
  # consequence of.
  describe "sticky header opacity when scrolled (G-01.5-7 gap closure)" do
    test ".pk-nav.is-scrolled declares a fully opaque background, no color-mix/transparent" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/(?m)^\.pk-nav\.is-scrolled\s*\{([^}]*)\}/s, src)
      assert rule, "Expected a top-level .pk-nav.is-scrolled rule in app.css."
      [_, body] = rule

      background = Regex.run(~r/(?<![-\w])background\s*:\s*([^;]+);/, body)
      assert background, "Expected .pk-nav.is-scrolled to declare a background."
      [_, background_value] = background

      # Scoped to the `background` declaration alone — box-shadow (below)
      # legitimately keeps its own color-mix() for the hairline shadow
      # tint, which was never the bug.
      refute background_value =~ ~r/color-mix/,
             "Expected .pk-nav.is-scrolled's background to declare no color-mix()/transparency. " <>
               "A 94%-opaque tint here let the FAQ band's bold light-on-dark copy (D-14) read as " <>
               "clearly visible ghost text through the scrolled header — invisible over light page " <>
               "content, which is why no prior visual check over a plain background caught it. See " <>
               "the CSS comment above this rule for the full incident."

      assert String.trim(background_value) == "var(--color-base-200)",
             "Expected .pk-nav.is-scrolled to declare a plain, fully opaque background: var(--color-base-200), got: #{inspect(background_value)}"

      assert body =~ ~r/border-bottom-color/,
             "Expected .pk-nav.is-scrolled to still declare border-bottom-color — the scrolled " <>
               "state must remain visually distinct from rest via border + shadow, not silently " <>
               "become identical to the unscrolled .pk-nav now that the transparency is gone."

      assert body =~ ~r/box-shadow/,
             "Expected .pk-nav.is-scrolled to still declare box-shadow, for the same reason as " <>
               "border-bottom-color above."
    end
  end
end
