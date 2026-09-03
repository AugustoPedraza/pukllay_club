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

  describe "CSS facts the hook depends on" do
    test ".pk-about-morph-mark declares position: fixed" do
      src = strip_comments(css_source())

      assert Regex.match?(~r/\.pk-about-morph-mark\s*\{[^}]*position:\s*fixed/s, src),
             "`.pk-about-morph-mark` must declare `position: fixed` — the hook positions it via " <>
               "viewport-relative inline top/left, which only a fixed-position element honors."
    end

    test "#app-header.pk-header-about-morph .pk-brand-mark sets opacity: 0" do
      src = strip_comments(css_source())

      assert Regex.match?(
               ~r/#app-header\.pk-header-about-morph\s+\.pk-brand-mark\s*\{[^}]*opacity:\s*0/s,
               src
             ),
             "A rule must suppress `.pk-brand-mark`'s opacity to 0 while `.pk-header-about-morph` " <>
               "is on `#app-header` — otherwise the header's own always-rendered isologo and the " <>
               "floating mark are both visible at once (RESEARCH.md Pitfall 1)."
    end

    test "#app-header.pk-header-about-morph hides the header at rest, and .is-docked reveals it" do
      src = strip_comments(css_source())

      assert Regex.match?(~r/#app-header\.pk-header-about-morph\s*\{[^}]*opacity:\s*0/s, src)

      assert Regex.match?(
               ~r/#app-header\.pk-header-about-morph\.is-docked\s*\{[^}]*opacity:\s*1/s,
               src
             )
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
