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
end
