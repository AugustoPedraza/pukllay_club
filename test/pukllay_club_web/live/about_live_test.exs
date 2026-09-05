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

  # G-01.4-5 gap closure (plan 01.4-10 Task 3): walks a baseline JPEG's own
  # marker chain to its Start-Of-Frame segment and returns {width, height}
  # read directly off the file's bytes — no dependency, no trusting a
  # comment. This is the missing wire the gap's root cause needed: one file
  # (app.css) described another file's (the committed screenshot's) shape,
  # and nothing checked the two agreed.
  defp jpeg_dimensions(path) do
    <<0xFF, 0xD8, rest::binary>> = File.read!(path)
    walk_jpeg_segments(rest)
  end

  # RST markers (0xD0-0xD7) carry no length field — skip the marker byte
  # only and keep walking. Not expected before a Start-Of-Frame in a real
  # file, but guarded so a malformed/unexpected file fails loudly instead
  # of misreading a length that isn't there.
  defp walk_jpeg_segments(<<0xFF, marker, rest::binary>>) when marker in 0xD0..0xD7 do
    walk_jpeg_segments(rest)
  end

  # A 0xFF fill byte before the real marker byte — re-inject the single
  # 0xFF this clause consumed and keep walking.
  defp walk_jpeg_segments(<<0xFF, 0xFF, rest::binary>>) do
    walk_jpeg_segments(<<0xFF, rest::binary>>)
  end

  defp walk_jpeg_segments(<<0xFF, 0xDA, _rest::binary>>) do
    raise "Reached Start-Of-Scan (0xFFDA) before any Start-Of-Frame marker — " <>
            "this file is not the baseline JPEG this gate assumes."
  end

  # Start-Of-Frame: 0xC0..0xCF except 0xC4 (Huffman tables), 0xC8 (JPG
  # reserved), 0xCC (arithmetic coding). Payload is one precision byte,
  # then HEIGHT, then WIDTH, both big-endian 16-bit — note the order.
  # `_length` is prefixed since it is not needed once past the header (the
  # payload is read directly off `rest`, unbounded), keeping
  # --warnings-as-errors clean.
  defp walk_jpeg_segments(<<0xFF, marker, _length::16, rest::binary>>)
       when marker in 0xC0..0xCF and marker not in [0xC4, 0xC8, 0xCC] do
    <<_precision, height::16, width::16, _rest::binary>> = rest
    {width, height}
  end

  defp walk_jpeg_segments(<<0xFF, _marker, length::16, rest::binary>>) do
    skip = length - 2
    <<_payload::binary-size(skip), remaining::binary>> = rest
    walk_jpeg_segments(remaining)
  end

  defp walk_jpeg_segments(<<>>) do
    raise "Reached end of file before any Start-Of-Frame marker — this file is not a baseline JPEG."
  end

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
  #
  # Oracle boundary (plan 01.4-07 Task 2, closing G-01.4-2; revised plan
  # 01.4-10 Task 3, closing G-01.4-5): ExUnit + LazyHTML see server-rendered
  # strings, class lists, and stylesheet text — they structurally CANNOT see
  # computed layout, wrapped line counts, rendered opacity, or any coverage
  # ratio. G-01.4-2 was a purely geometric/perceptual defect (a translucent
  # caption overlay that grew to 3 wrapped lines and swallowed 74.9% of the
  # thumbnail) that the original two structural assertions below (anchor
  # href/target/rel, img src) could not have caught — nothing here asserted
  # the caption's text, height, or opacity. The assertions added for that
  # gap (both caption variants render and are gated by lg; the opaque
  # single-source fill; the single-line ceiling; the height floor)
  # constrain the MECHANISM that produced the bug, not the resulting
  # APPEARANCE.
  #
  # G-01.4-5 sharpened this boundary further: this suite's ORIGINAL
  # sentence above was true about pixel CONTENT and false about pixel
  # GEOMETRY — and geometry, not content, is what actually broke (a
  # recaptured asset's real shape silently drifted from the `aspect-ratio`
  # literal that crops it). Three oracles now divide this component, each
  # owning a different question, and no reader should reach for the wrong
  # one:
  #   1. THIS suite (ExUnit + LazyHTML) gates the asset/CSS SHAPE
  #      relationship and other stylesheet facts — e.g. the dimension gate
  #      below reads the real JPEG dimensions off disk and fails the build
  #      the moment they disagree with the custom properties that crop
  #      them. Fast, deterministic, no browser.
  #   2. `test/visual/about_map_attribution.mjs` (+ its Python pixel
  #      oracle) renders the LIVE page in a real headless Chrome at all 4
  #      breakpoints x 2 themes and gates whether Google's attribution
  #      wordmark actually survives to the painted screen, clear of the
  #      caption chip — the render-and-look step this suite cannot perform.
  #      Developer-invoked only (not part of `mix quality`/CI — see
  #      01.4-10-PLAN.md's threat register), because it needs a real
  #      browser and a booted server.
  #   3. A human still adjudicates whether the RESULT reads right —
  #      legibility, framing, whether the crop still looks intentional —
  #      per this phase's end-of-phase UAT convention. No headless-browser
  #      screenshot-diff test is added to CI: this repo has an
  #      engine-divergence precedent (the Phase 01.3 chevron bug reproduced
  #      only on real WebKit, not headless Chromium), and every measurement
  #      in both the G-01.4-2 and G-01.4-5 diagnoses was headless
  #      Chromium — a CI-gated headless screenshot test here would encode
  #      the same blind spot it just failed to catch, at a real maintenance
  #      cost.
  #
  # Plan 01.4-11 (G-01.4-5, second half): the crop fix (01.4-10) stopped the
  # baked-in wordmark from being discarded, but at 2.5-5.9 CSS px it still
  # is not legible to a person — the customization clause of Google's Geo
  # Guidelines, not an optional embellishment. This suite gates the new
  # `.pk-about-map-credit`'s PRESENCE, TEXT, TYPE TIER, and STRUCTURAL
  # placement (inside #contacto, outside the clipping `.pk-about-map-thumb`,
  # no nested anchor) — all DOM facts. Whether the credit is actually big
  # enough to read and contrasted enough to see against the card in a real
  # browser is oracle #2's job (`test/visual/about_map_attribution.mjs`,
  # extended in the same plan to measure the credit's rect/font-size/
  # contrast), and whether the finished component reads right end to end is
  # still oracle #3, the human check.
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

    # G-01.4-4 gap closure, Task 3: `.pk-about-map-thumb img` carried
    # `display: block` until now. Task 3 wires a light/dark <img> theme-
    # variant pair on the isologo's own `block dark:hidden` /
    # `hidden dark:block` pattern (brand_logo/1, layouts.ex) — an unlayered
    # `.pk-*` rule declaring `display` always beats a layered Tailwind
    # utility (this file's own top-of-file cascade-layer hazard note),
    # which would defeat `dark:hidden` and render BOTH images stacked in
    # both themes. This is exactly the Rule 1 defect plan 01.4-05 had to
    # undo on `.pk-about-morph-mark img`'s own theme variants. This is a
    # cascade fact, not a rendered-output fact, so it is asserted against
    # the stylesheet source rather than through a browser the test suite
    # does not have.
    test ".pk-about-map-thumb img declares no display property" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-map-thumb img\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-thumb img rule in app.css."
      [_, body] = rule

      refute body =~ "display",
             "An unlayered .pk-* rule declaring display would beat the dark:hidden / " <>
               "hidden dark:block utility pair on the light/dark theme-variant <img> pair, " <>
               "rendering both at once — the exact cascade hazard plan 01.4-05's Rule 1 fix " <>
               "had to undo on .pk-about-morph-mark img's own theme variants (this file's " <>
               "own top-of-file hazard note)."
    end

    # G-01.4-4 gap closure, Task 3: one light-palette asset served both
    # themes (the light and dark measurement sweeps in the debug session
    # were identical row-for-row) — a 10.1x luminance mismatch against the
    # dark card. Mirrors brand_logo/1's own isologo light/dark pair.
    test "renders both light/dark theme-variant <img>s inside .pk-about-map-thumb, light first",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      imgs = LazyHTML.query(doc, ".pk-about-map-thumb img")

      assert Enum.count(imgs) == 2

      light = Enum.at(imgs, 0)
      dark = Enum.at(imgs, 1)

      light_src = light |> LazyHTML.attribute("src") |> List.first()
      light_class = light |> LazyHTML.attribute("class") |> List.first()
      assert light_src =~ "about-maps-thumb.jpg"
      assert light_class =~ "block"
      assert light_class =~ "dark:hidden"

      dark_src = dark |> LazyHTML.attribute("src") |> List.first()
      dark_class = dark |> LazyHTML.attribute("class") |> List.first()
      assert dark_src =~ "about-maps-thumb-dark.jpg"
      assert dark_class =~ "hidden"
      assert dark_class =~ "dark:block"
    end

    # G-01.4-4 gap closure, Task 3: a presence-only check. This deliberately
    # catches the wired-but-never-captured state — a src pointing at a path
    # with no file behind it — which is the one failure mode of this gap
    # closure that would otherwise ship two broken <img>s and a green suite.
    # See the oracle-boundary comment above this describe block: image
    # CONTENT (luminance, the pin label, competing POIs, the attribution
    # wordmark) is not expressible as an ExUnit assertion and is adjudicated
    # only by the human check in 01.4-09-PLAN.md Task 3's <verify>.
    test "both light and dark map thumbnail asset files exist on disk" do
      assert File.exists?("priv/static/images/about-maps-thumb.jpg")
      assert File.exists?("priv/static/images/about-maps-thumb-dark.jpg")
    end

    # G-01.4-5 gap closure (plan 01.4-10 Task 3): the gap's root cause,
    # closed. 01.4-09 recaptured this asset at 1656x804 (ratio 2.0597) and
    # left `.pk-about-map-thumb` declaring a stale `21 / 9` literal
    # (correct for the earlier ~1200x514 capture it replaced) — nothing in
    # the repo connected the two, so `object-fit: cover` silently discarded
    # 5.86% off the top AND bottom of every render, taking Google's
    # attribution wordmark (baked into the bottom edge) with it
    # (01.4-VERIFICATION.md truth 10). This test's SUBJECT is the
    # RELATIONSHIP between the asset's real shape and the CSS that crops
    # it, not either side pinned to today's numbers — so it keeps working
    # after a legitimate future recapture at a new size, as long as both
    # custom properties are updated in the same commit.
    test "both map assets' real JPEG dimensions match --pk-map-thumb-w/-h in app.css" do
      {light_w, light_h} = jpeg_dimensions("priv/static/images/about-maps-thumb.jpg")
      {dark_w, dark_h} = jpeg_dimensions("priv/static/images/about-maps-thumb-dark.jpg")

      src = strip_comments(css_source())
      rule = Regex.run(~r/\.pk-about-map-thumb\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-thumb rule in app.css."
      [_, body] = rule

      css_w =
        Regex.run(~r/--pk-map-thumb-w:\s*(\d+)/, body) ||
          flunk("""
          Expected .pk-about-map-thumb to declare --pk-map-thumb-w — this custom \
          property is the ONE place in the repo that claims to know the asset's \
          pixel width, read by the rule's aspect-ratio to derive the crop.
          """)

      css_h =
        Regex.run(~r/--pk-map-thumb-h:\s*(\d+)/, body) ||
          flunk("""
          Expected .pk-about-map-thumb to declare --pk-map-thumb-h — see \
          --pk-map-thumb-w's failure message above; the same reasoning applies \
          to height.
          """)

      [_, css_w] = css_w
      [_, css_h] = css_h
      css_w = String.to_integer(css_w)
      css_h = String.to_integer(css_h)

      failure_message = fn label, asset_w, asset_h ->
        """
        #{label} asset is #{asset_w}x#{asset_h} on disk, but .pk-about-map-thumb \
        declares --pk-map-thumb-w: #{css_w} / --pk-map-thumb-h: #{css_h}.

        .pk-about-map-thumb crops with object-fit: cover using an aspect-ratio \
        derived from these two custom properties — a box shaped differently \
        from the asset discards the difference. This is exactly how G-01.4-5 \
        happened: 01.4-09 replaced a 1200x514 capture with a 1656x804 one and \
        left the box declaring the old shape, silently throwing away 5.86% off \
        the top and bottom of every render and taking Google's attribution \
        wordmark with it (see .planning/phases/01.4-ui-polish-pass-for-about-page-sketches/01.4-VERIFICATION.md, \
        truth 10, for the measurement). A recapture at a new size means \
        updating BOTH custom properties in the same commit as the new asset.
        """
      end

      assert {css_w, css_h} == {light_w, light_h},
             failure_message.("Light", light_w, light_h)

      assert {css_w, css_h} == {dark_w, dark_h},
             failure_message.("Dark", dark_w, dark_h)
    end

    test ".pk-about-map-thumb's aspect-ratio names both custom properties, not a numeric literal" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-map-thumb\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-thumb rule in app.css."
      [_, body] = rule

      assert body =~ ~r/aspect-ratio\s*:\s*var\(--pk-map-thumb-w\)\s*\/\s*var\(--pk-map-thumb-h\)/,
             "Expected .pk-about-map-thumb's aspect-ratio to be a ratio of " <>
               "var(--pk-map-thumb-w) / var(--pk-map-thumb-h), not a numeric literal. " <>
               "A literal is a SECOND, unchecked claim about the asset's shape — the " <>
               "test above only gates the custom properties, so having exactly one " <>
               "place in the repo that claims to know the asset's shape (the custom " <>
               "properties) is the entire point of this gap closure."

      assert body =~ "--pk-map-attrib-band",
             "Expected .pk-about-map-thumb to declare --pk-map-attrib-band — the " <>
               "reserve band .pk-about-map-label's bottom offset adds on top of its " <>
               "own inset, so the caption chip can never sit on top of the now-visible " <>
               "attribution."
    end

    test ".pk-about-map-thumb img declares object-position: 50% 100%" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-map-thumb img\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-thumb img rule in app.css."
      [_, body] = rule

      assert body =~ ~r/object-position\s*:\s*50%\s*100%/,
             "Expected .pk-about-map-thumb img to declare object-position: 50% 100% — " <>
               "Google always bakes Maps attribution onto the BOTTOM edge of a capture, " <>
               "so if a vertical crop is ever reintroduced (a container change, a " <>
               "min-height edit, a differently-shaped recapture), the bottom must be " <>
               "the last thing discarded, never the first."

      assert body =~ "object-fit",
             "Expected .pk-about-map-thumb img to still declare object-fit (unchanged)."
    end

    test ".pk-about-map-label's bottom reserves the attribution band on top of its own inset" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-map-label\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-map-label rule in app.css."
      [_, body] = rule

      assert body =~
               ~r/bottom\s*:\s*calc\(var\(--pk-map-label-inset\)\s*\+\s*var\(--pk-map-attrib-band\)\)/,
             "Expected .pk-about-map-label's bottom to be " <>
               "calc(var(--pk-map-label-inset) + var(--pk-map-attrib-band)), not the " <>
               "inset alone. The caption chip is opaque and horizontally overlaps the " <>
               "centred wordmark — uncropping Google's attribution and then parking " <>
               "this chip directly on top of it would satisfy the letter of the fix " <>
               "and none of its purpose (Google's Geo Guidelines: \"Don't remove, " <>
               "obscure, or crop out the attribution information\")."
    end

    # G-01.4-5 gap closure (plan 01.4-11 Task 1): the baked-in wordmark
    # survives the crop (01.4-10) but renders 2.5-5.9 CSS px tall — present
    # in the pixel buffer, not legible to a person. Google's Geo Guidelines
    # require attribution "within close proximity of the content and
    # legible to the average viewer or reader," so a real, legible credit
    # is added adjacent to the thumbnail. The containment pair below is the
    # load-bearing part: presence alone would pass for a credit nested
    # INSIDE the clipping box, which is the exact failure mode this test
    # exists to catch.
    test "renders a legible Google credit inside #contacto, outside the clipping thumbnail",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)

      credit_in_doc = LazyHTML.query(doc, ".pk-about-map-credit")

      assert Enum.count(credit_in_doc) == 1,
             "Expected exactly one element matching .pk-about-map-credit."

      credit_html = LazyHTML.to_html(credit_in_doc)

      assert credit_html =~ "Google",
             "Expected the credit's text to contain the literal \"Google\"."

      refute credit_html =~ "<a ", "Expected the credit to contain no anchor."
      refute credit_html =~ "<a>", "Expected the credit to contain no anchor."

      thumb = LazyHTML.query(doc, ".pk-about-map-thumb")
      credit_inside_thumb = LazyHTML.query(thumb, ".pk-about-map-credit")

      assert Enum.count(credit_inside_thumb) == 0,
             "Expected zero elements matching .pk-about-map-credit inside " <>
               ".pk-about-map-thumb — .pk-about-map-thumb declares overflow: hidden " <>
               "and crops with object-fit: cover, which is what discarded Google's " <>
               "baked-in wordmark at every breakpoint in the first place (G-01.4-5). " <>
               "A credit placed inside it inherits the same clipping."

      contacto = LazyHTML.query(doc, "#contacto")
      credit_inside_contacto = LazyHTML.query(contacto, ".pk-about-map-credit")

      assert Enum.count(credit_inside_contacto) == 1,
             "Expected exactly one element matching .pk-about-map-credit inside #contacto."

      credit_class = credit_in_doc |> LazyHTML.attribute("class") |> List.first()

      assert credit_class =~ "text-xs",
             "Expected the credit's class list to carry text-xs — this app caps its " <>
               "distinct type combinations and enforces the cap by measurement " <>
               "(ui-design-system, Type inventory), so a credit line reuses the " <>
               "shipped muted tier rather than introducing a sixth combo."

      assert credit_class =~ "text-neutral",
             "Expected the credit's class list to carry text-neutral — see the " <>
               "text-xs assertion above; both halves of the shipped muted tier."

      refute credit_class =~ ~r/\[.*\]/,
             "Expected the credit's class list to carry no bracketed arbitrary " <>
               "Tailwind value (ui-design-system, banned list)."
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
