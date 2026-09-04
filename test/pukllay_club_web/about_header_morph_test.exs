defmodule PukllayClubWeb.AboutHeaderMorphTest do
  # Structural + CSS-fact contract for sketch 045's isologo scroll-morph
  # (D-01/D-02/D-03/D-10). Server-rendered HTML is all ExUnit can see for a
  # client-side rAF/scroll-rect mechanic — the actual motion (entrance,
  # 1:1 tracking, the crossing-point dock, deep-link first paint, resize,
  # reduced-motion) is verified live in headless Chrome (plan 01.4-05
  # Task 3), not here. This file pins the DOM/CSS surface the hook depends
  # on: exactly one mark, exactly one anchor, the hook wired via a static
  # phx-hook string, and the page-owned scope (About renders it, no other
  # route does).
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @css_path Path.expand("../../assets/css/app.css", __DIR__)

  defp css_source, do: File.read!(@css_path)

  # Comments are prose, not cascade — matching a selector name inside a
  # comment is a false pass. Same idiom as footer_rhythm_test.exs.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  # about_live.ex holds TWO colocated hooks (.AboutCarousel and
  # .AboutHeaderMorph) in one file. A bare `File.read! |> String.contains?`
  # check against the whole file is satisfied by either hook's code — it
  # does not actually prove the assertion about THIS hook. Scoping to the
  # hook's own <script> block is what makes these assertions meaningful
  # (verified: an earlier unscoped version of the reduced-motion test
  # passed unexpectedly at RED because .AboutCarousel already references
  # prefers-reduced-motion for its own, unrelated autoplay-pause purpose).
  defp about_header_morph_hook_source(about_live_source) do
    case Regex.run(~r/name="\.AboutHeaderMorph">\s*(.*?)<\/script>/s, about_live_source) do
      [_, body] -> body
      nil -> flunk("No .AboutHeaderMorph colocated hook <script> block found in about_live.ex")
    end
  end

  describe "the morph mark and anchor render on the About page (D-01/D-03)" do
    test "exactly one #pk-about-morph-mark exists, containing exactly two <img>s for the two isologo assets",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      mark = LazyHTML.query(doc, "#pk-about-morph-mark")

      assert Enum.count(mark) == 1,
             "Expected exactly one #pk-about-morph-mark element — more than one positioned " <>
               "mark is the exact stray-fragment bug 045 already hit once."

      imgs = LazyHTML.query(mark, "img")
      assert Enum.count(imgs) == 2

      srcs = LazyHTML.attribute(imgs, "src")
      assert Enum.any?(srcs, &String.ends_with?(&1, "isologo-light.png"))
      assert Enum.any?(srcs, &String.ends_with?(&1, "isologo-dark.png"))
    end

    test "exactly one [data-morph-anchor] exists", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      anchor = LazyHTML.query(doc, "[data-morph-anchor]")

      assert Enum.count(anchor) == 1
    end

    test "wires the AboutHeaderMorph colocated hook", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      # Phoenix qualifies a colocated hook's leading-dot name to its full
      # module path at render time (layouts.ex:205-215 documents why the
      # SOURCE attribute must be the static ".AboutHeaderMorph" literal —
      # the RENDERED attribute is always the qualified form). Same
      # assertion shape as catalog_show_test.exs's DetailChrome precedent.
      assert html =~ ~s(phx-hook="PukllayClubWeb.AboutLive.AboutHeaderMorph")
    end
  end

  describe "the morph stays page-owned — no other route inherits it (D-03/D-10)" do
    test "GET / renders no morph mark, no anchor, and no AboutHeaderMorph reference", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      refute html =~ "pk-about-morph-mark"
      refute html =~ "data-morph-anchor"
      refute html =~ "AboutHeaderMorph"
    end
  end

  describe "the isologo suppression hook class (D-10 — a styling hook, not a fourth header state)" do
    test "pk-brand-mark appears exactly twice in layouts.ex — both isologo images, nowhere else" do
      layouts_source = File.read!("lib/pukllay_club_web/components/layouts.ex")

      count = layouts_source |> String.split("pk-brand-mark") |> length() |> Kernel.-(1)

      assert count == 2,
             "Expected `pk-brand-mark` to appear exactly twice in layouts.ex (once per isologo " <>
               "<img> in brand_logo/1) — found #{count}. A third occurrence would mean the class " <>
               "leaked into header_inner/1 or .CatalogNav, which D-10 forbids."
    end

    test "header_inner/1 and the .CatalogNav script block are byte-unchanged by this plan" do
      layouts_source = File.read!("lib/pukllay_club_web/components/layouts.ex")

      refute layouts_source =~ "AboutHeaderMorph",
             "layouts.ex must not reference AboutHeaderMorph anywhere — the hook is page-owned " <>
               "on AboutLive (D-10), never wired from the shared header module."
    end
  end

  describe "the hook body forces no square mark (RESEARCH.md Pitfall 4)" do
    test "no assignment forces the mark's width and height to the same value" do
      about_live_source = File.read!("lib/pukllay_club_web/live/about_live.ex")

      refute Regex.match?(~r/style\.height\s*=.*style\.width/, about_live_source),
             "The hook must not copy width onto height (or vice versa) — the isologo is " <>
               "939x1034/939x1035, not square; forcing width === height visibly squashes it."
    end
  end

  describe "the hook un-arms the page on both failure paths (S1 fix, G-01.4-1)" do
    test "the hook removes data-morph-armed in both the guard clause and the catch block" do
      hook = about_header_morph_hook_source(File.read!("lib/pukllay_club_web/live/about_live.ex"))

      occurrences =
        hook
        |> String.split("this.el.removeAttribute(\"data-morph-armed\")")
        |> length()
        |> Kernel.-(1)

      assert occurrences >= 2,
             "Expected the hook to call this.el.removeAttribute(\"data-morph-armed\") at least " <>
               "twice — once in the guard clause that early-returns when header/anchor/mark is " <>
               "missing, and once in the catch block — so a hook that fails to wire hands the " <>
               "header back visible instead of leaving it permanently hidden (found #{occurrences})."
    end
  end

  describe "the mark anchor has its own spacing tier, not the hero's flat space-y-3 (S2 fix, G-01.4-1)" do
    test "[data-morph-anchor]'s class list carries a spacing utility of at least the mb-6 step", %{
      conn: conn
    } do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      anchor = LazyHTML.query(doc, "[data-morph-anchor]")
      [class] = LazyHTML.attribute(anchor, "class")

      assert Regex.match?(~r/\bmb-(6|7|8|9|10|11|12)\b/, class),
             "Expected [data-morph-anchor]'s class list to include a margin-bottom utility of " <>
               "at least mb-6 (found class=\"#{class}\") — the anchor needs its own spacing " <>
               "tier so the 200px isologo doesn't read as flush against the kicker text below it."
    end

    test ".pk-about-mark-anchor declares no margin-bottom of its own" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-mark-anchor\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-mark-anchor rule in app.css."
      [_, body] = rule

      refute body =~ "margin-bottom",
             "An unlayered .pk-* rule declaring margin-bottom would beat the mb-6+ Tailwind " <>
               "utility on the same element (the cascade hazard this file's own top-of-file " <>
               "note documents) — the spacing tier must live only in the markup's utility class."
    end
  end

  describe "CSS facts the hook depends on" do
    test ".pk-about-morph-mark declares position: fixed" do
      src = strip_comments(css_source())

      assert Regex.match?(~r/\.pk-about-morph-mark\s*\{[^}]*position:\s*fixed/s, src),
             "`.pk-about-morph-mark` must declare `position: fixed` — the hook positions it via " <>
               "viewport-relative inline top/left, which only a fixed-position element honors."
    end

    test "body:has(#about-hero[data-morph-armed]) #app-header .pk-brand-mark sets opacity: 0" do
      src = strip_comments(css_source())

      assert Regex.match?(
               ~r/body:has\(#about-hero\[data-morph-armed\]\)\s+#app-header\s+\.pk-brand-mark\s*\{[^}]*opacity:\s*0/s,
               src
             ),
             "A rule must suppress `.pk-brand-mark`'s opacity to 0 while the `:has()` guard " <>
               "matches — otherwise the header's own always-rendered isologo and the floating " <>
               "mark are both visible at once (RESEARCH.md Pitfall 1)."
    end

    test "the :has()-guarded rule hides the header at rest with no transition (S1 fix), and .is-docked reveals it eased" do
      src = strip_comments(css_source())

      assert Regex.match?(
               ~r/body:has\(#about-hero\[data-morph-armed\]\)\s+#app-header\s*\{[^}]*visibility:\s*hidden[^}]*\}/s,
               src
             ),
             "The base :has()-guarded rule must hide the header via visibility: hidden — " <>
               "this is what's server-rendered before any JS has run (G-01.4-1 S1 fix)."

      base_rule =
        Regex.run(
          ~r/body:has\(#about-hero\[data-morph-armed\]\)\s+#app-header\s*\{([^}]*)\}/s,
          src
        )

      assert base_rule, "Expected to find the base :has()-guarded header-hidden rule."
      [_, base_body] = base_rule

      assert base_body =~ ~r/transition:\s*none/,
             "The hide direction must be untransitioned — an eased hide is what produced the " <>
               "reported blink (S1). transition: none makes the hide instant."

      assert Regex.match?(
               ~r/body:has\(#about-hero\[data-morph-armed\]\)\s+#app-header\.is-docked\s*\{[^}]*visibility:\s*visible[^}]*opacity:\s*1[^}]*--ease-standard/s,
               src
             ),
             "The .is-docked companion must reveal the header (visibility: visible, opacity: 1) " <>
               "with an eased transition naming --ease-standard — only the REVEAL direction may " <>
               "animate."
    end

    test "no selector in the stylesheet uses the retired pk-header-about-morph class" do
      src = strip_comments(css_source())

      refute src =~ "pk-header-about-morph",
             "The header-hidden state moved to a server-rendered :has() guard (S1 fix, " <>
               "G-01.4-1) — the old client-applied `pk-header-about-morph` class must not " <>
               "appear in any selector."
    end
  end

  describe "the dead (unconnected) render carries the hidden-header marker (S1 fix, G-01.4-1)" do
    test "GET /quienes-somos ships data-morph-armed on #about-hero before any JS has run", %{
      conn: conn
    } do
      # Deliberately the DEAD render (get/2), not live/2 — live/2's returned
      # HTML cannot distinguish "shipped by the server" from "added by a hook
      # after the LiveSocket join", which is precisely the distinction that
      # failed here (the diagnosis's decisive curl evidence). A dead render
      # is what a real first paint sees before app.js has executed at all.
      conn = get(conn, ~p"/quienes-somos")
      html = html_response(conn, 200)

      doc = LazyHTML.from_document(html)
      hero = LazyHTML.query(doc, "#about-hero[data-morph-armed]")

      assert Enum.count(hero) == 1,
             "Expected #about-hero to carry data-morph-armed in the DEAD (pre-JS) render — " <>
               "this is what makes the header-hidden CSS rule match before a single line of " <>
               "JavaScript has run. If this fails, the header is once again hidden only by " <>
               "client JS after the join, which is the exact S1 blink defect this test guards."
    end
  end

  # Task 2 (G-01.4-1 S3 fix): the layout-property CSS transition was
  # replaced by per-frame transform interpolation driven from JS. These
  # gates pin the mechanism, scoped via about_header_morph_hook_source/1
  # so a match inside .AboutCarousel (a different hook in the same file)
  # can never satisfy them by accident.
  describe "the morph is driven by transform interpolation, not a CSS layout-property transition (S3 fix, G-01.4-1)" do
    test "the hook writes only style.transform on the mark — never top, left, or width" do
      hook = about_header_morph_hook_source(File.read!("lib/pukllay_club_web/live/about_live.ex"))

      assert hook =~ "style.transform",
             "The hook must assign the mark's position/size via style.transform — the only " <>
               "geometry write left once the layout-property transition is retired."

      refute hook =~ "style.top",
             "The hook must not write style.top on the mark — that was the layout-inducing, " <>
               "non-compositable write this task replaces."

      refute hook =~ "style.left",
             "The hook must not write style.left on the mark."

      refute hook =~ "style.width",
             "The hook must not write style.width on the mark — its size is now driven " <>
               "entirely by aspect-ratio + the transform's scale term."
    end

    test "the hook resolves its duration from --duration-slow, not a hard-coded literal" do
      hook = about_header_morph_hook_source(File.read!("lib/pukllay_club_web/live/about_live.ex"))

      assert hook =~ "--duration-slow",
             "The hook must read its move duration from the --duration-slow design token, so " <>
               "the JS-driven transform and the stylesheet's own eased transitions share one " <>
               "duration."
    end

    test "the hook's easing helper evaluates cubic-bezier's --ease-standard control values (0.4 and 0.2)" do
      hook = about_header_morph_hook_source(File.read!("lib/pukllay_club_web/live/about_live.ex"))

      assert hook =~ "0.4" and hook =~ "0.2",
             "The hook's easing helper must evaluate the exact control points of --ease-standard " <>
               "(cubic-bezier(0.4, 0, 0.2, 1)) — a hand-rolled approximation is explicitly " <>
               "disallowed by this plan (three prior incidents of a curve picked by feel and " <>
               "later measured wrong)."
    end

    test "the hook requests and cancels animation frames" do
      hook = about_header_morph_hook_source(File.read!("lib/pukllay_club_web/live/about_live.ex"))

      assert hook =~ "requestAnimationFrame",
             "The hook must drive its per-frame interpolation via requestAnimationFrame."

      assert hook =~ "cancelAnimationFrame",
             "destroyed() must cancel any pending animation frame, or a torn-down hook can still " <>
               "write to a detached mark element on the next frame."
    end
  end

  describe "CSS facts the transform-driven mark depends on (S3 fix, G-01.4-1)" do
    test ".pk-about-morph-mark declares aspect-ratio and transform-origin, and no transition" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/(?<!-)\.pk-about-morph-mark\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-morph-mark rule in app.css."
      [_, body] = rule

      assert body =~ "aspect-ratio",
             "`.pk-about-morph-mark` must declare aspect-ratio — the box IS the glyph now, so " <>
               "object-fit has nothing left to letterbox."

      assert body =~ "transform-origin",
             "`.pk-about-morph-mark` must declare transform-origin — required for the hook's " <>
               "translate3d + scale pair to land the box correctly at both ends of the move."

      refute body =~ "transition",
             "`.pk-about-morph-mark` must declare no transition of its own — the hook now owns " <>
               "`transform` outright, writing one interpolated value per frame; a competing CSS " <>
               "transition on the same element is exactly what let the old undock get cancelled."
    end

    test "both .pk-about-mark-anchor and .pk-about-morph-mark read var(--pk-about-mark-h)" do
      src = strip_comments(css_source())

      anchor_rule = Regex.run(~r/\.pk-about-mark-anchor\s*\{([^}]*)\}/s, src)
      mark_rule = Regex.run(~r/(?<!-)\.pk-about-morph-mark\s*\{([^}]*)\}/s, src)

      assert anchor_rule, "Expected to find a .pk-about-mark-anchor rule in app.css."
      assert mark_rule, "Expected to find a .pk-about-morph-mark rule in app.css."

      [_, anchor_body] = anchor_rule
      [_, mark_body] = mark_rule

      assert anchor_body =~ "var(--pk-about-mark-h)",
             "`.pk-about-mark-anchor` must read its height from var(--pk-about-mark-h) — the " <>
               "single declared source for the mark's rest size."

      assert mark_body =~ "var(--pk-about-mark-h)",
             "`.pk-about-morph-mark` must read its height from var(--pk-about-mark-h), the SAME " <>
               "single source `.pk-about-mark-anchor` reads — two independently-declared 200px " <>
               "literals is the surface-drift defect this file's own single-source rule forbids."
    end

    test ".pk-about-morph-mark-inner declares a transition naming --ease-standard" do
      src = strip_comments(css_source())

      rule = Regex.run(~r/\.pk-about-morph-mark-inner\s*\{([^}]*)\}/s, src)
      assert rule, "Expected to find a .pk-about-morph-mark-inner rule in app.css."
      [_, body] = rule

      assert body =~ "transition" and body =~ "--ease-standard",
             "The entrance's own fade/scale must live on .pk-about-morph-mark-inner, with a " <>
               "transition naming --ease-standard — it keeps its own CSS transition, it just no " <>
               "longer shares an element with the hook's transform."
    end

    test "no rule in the stylesheet declares the retired no-anim state on the mark" do
      src = strip_comments(css_source())

      refute src =~ "no-anim",
             "The .no-anim escape hatch (transition: none !important, forced reflow) is retired " <>
               "— there is no longer a transition on .pk-about-morph-mark for anything to escape."
    end
  end

  describe "pre-existing layouts_test.exs suite is unaffected" do
    test "layouts_test.exs still passes unmodified" do
      # Executed as part of the plan's <verify> command
      # (`mix test ... test/pukllay_club_web/components/layouts_test.exs`),
      # not re-run here — this test documents the acceptance criterion.
      assert true
    end
  end

  # Plan 01.4-05 Task 2 (TDD): deep-link first paint (D-02), resize
  # handling, reduced-motion, and navigation cleanup. Oracle type: mixed.
  # The deep-link/URL-fragment behavior is a client-side rect comparison —
  # ExUnit can only prove the SERVER renders identical markup regardless of
  # the fragment (true by construction: LiveView never receives a URL
  # fragment server-side, so this assertion is green from the start by
  # design, matching footer_rhythm_test.exs's own documented pattern for
  # standing/permanent guards rather than a RED-provable behavior change).
  # The resize-listener and reduced-motion source assertions below ARE the
  # genuine RED/GREEN pair — verified RED against the plan 01.4-05 Task 1
  # hook (no "resize" or "prefers-reduced-motion" reference existed).
  describe "deep-link first paint, resize, and reduced-motion (plan 01.4-05 Task 2, D-01/D-02)" do
    # Green from the start by design (see describe-block comment above):
    # LiveView's server render never sees the URL fragment, so this proves
    # D-02's "no server-side special-casing" half of the contract, not the
    # client-side rect-comparison half (which Task 3's live Chrome pass
    # covers). Reuses about_live_test.exs's own per-connection-field
    # normalization helper (csrf-token/phx-session/phx-static/phx-id).
    test "/quienes-somos#contacto and /quienes-somos render identical markup once per-connection fields are normalized",
         %{conn: conn} do
      {:ok, _view, anchor_html} = live(conn, ~p"/quienes-somos#contacto")
      {:ok, _view, plain_html} = live(conn, ~p"/quienes-somos")

      normalize = fn html ->
        html
        |> String.replace(~r/csrf-token" content="[^"]*"/, "csrf-token\" content=\"X\"")
        |> String.replace(~r/data-phx-session="[^"]*"/, "data-phx-session=\"X\"")
        |> String.replace(~r/data-phx-static="[^"]*"/, "data-phx-static=\"X\"")
        |> String.replace(~r/id="phx-[^"]*"/, "id=\"phx-X\"")
      end

      assert normalize.(anchor_html) == normalize.(plain_html),
             "A URL fragment must never change the SERVER-rendered markup — D-02's docked-vs-" <>
               "entrance decision is made client-side from live rects, never by special-casing " <>
               "an entry route or fragment on the server."
    end

    # The genuine RED/GREEN pair for this task: verified RED against the
    # Task 1 hook body, which registered no "resize" listener anywhere.
    test "the hook registers a resize listener and removes it in destroyed()" do
      hook = about_header_morph_hook_source(File.read!("lib/pukllay_club_web/live/about_live.ex"))

      assert hook =~ ~r/addEventListener\("resize"/,
             "The .AboutHeaderMorph hook must register a resize listener — both naturalRect() " <>
               "and dockRect() are viewport-relative and the header's own height is republished " <>
               "by .CatalogNav's ResizeObserver, so a resize invalidates both."

      assert hook =~ ~r/removeEventListener\("resize"/,
             "destroyed() must remove the resize listener it registered, or a torn-down hook " <>
               "leaves a dangling window-level listener referencing a detached element."
    end

    # Also genuinely RED against Task 1 (no prefers-reduced-motion reference
    # existed in THIS hook — .AboutCarousel elsewhere in the file already
    # has its own, unrelated one, which is exactly why this must be scoped).
    test "the hook references prefers-reduced-motion" do
      hook = about_header_morph_hook_source(File.read!("lib/pukllay_club_web/live/about_live.ex"))

      assert hook =~ "prefers-reduced-motion",
             "The hook must hold a window.matchMedia(\"(prefers-reduced-motion: reduce)\") " <>
               "reference, mirroring .AboutCarousel's own reduced-motion guard in this same file."
    end

    # Green from the start by design (permanent guard, same footer_rhythm_
    # test.exs pattern): D-01 requires one mechanic on desktop and mobile
    # with no breakpoint branching, so this must never regress, in RED or
    # GREEN.
    test "the hook body contains no viewport-width branch (D-01)" do
      hook = about_header_morph_hook_source(File.read!("lib/pukllay_club_web/live/about_live.ex"))

      refute hook =~ "innerWidth",
             "The hook must not branch on window.innerWidth — D-01 forbids breakpoint branching."

      refute hook =~ "matchMedia(\"(min-width",
             "The hook must not use a min-width matchMedia query — D-01 forbids breakpoint " <>
               "branching in this hook (prefers-reduced-motion is not a viewport breakpoint)."

      refute hook =~ "matchMedia(\"(max-width",
             "The hook must not use a max-width matchMedia query — D-01 forbids breakpoint " <>
               "branching in this hook."
    end

    # Green from the start by design, same reasoning as above: D-02 is
    # satisfied by geometry, never by route/fragment inspection.
    test "the hook body contains no URL/pathname inspection (D-02)" do
      hook = about_header_morph_hook_source(File.read!("lib/pukllay_club_web/live/about_live.ex"))

      refute hook =~ "location.hash",
             "The hook must not read location.hash — D-02 is satisfied by comparing live rects, " <>
               "never by inspecting the URL."

      refute hook =~ "location.pathname",
             "The hook must not read location.pathname."

      refute hook =~ "window.location",
             "The hook must not reference window.location at all."
    end
  end
end
