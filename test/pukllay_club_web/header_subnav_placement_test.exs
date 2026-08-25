defmodule PukllayClubWeb.HeaderSubnavPlacementTest do
  # Guards two things cycle 5 changed about the top of every page: WHERE the
  # mobile category chip row sits in the scroll stack, and how much vertical
  # budget `<main>` spends before the first pixel of content on a phone.
  #
  # Motivating incident (debug search-right-align-mobile, cycle 5).
  #
  # 1. UN-STICKING. `{render_slot(@subnav)}` used to render as a child of
  #    `#app-header`, and `.pk-header-sticky` is `position: sticky; top: 0`.
  #    Sticky pins the whole box, so the chip row shared the header's common
  #    fate at every scroll position — measured y=0..133 at scrollY 0 AND
  #    unchanged at y=0..133 at scrollY 1400. The user asked for the row to
  #    scroll away with the page. No CSS can exempt a child from its ancestor's
  #    sticky box, so the row had to LEAVE the element; that is why this is a
  #    markup contract and not a stylesheet one, and why a test that only read
  #    app.css could not guard it.
  #
  #    The move has a sharp edge, which is the real reason this file exists.
  #    `.CatalogNav` collected its scroll-spy targets with
  #    `this.el.querySelectorAll("[data-chip-target]")` where `this.el` IS
  #    `#app-header`. Two different surfaces share that attribute: the 8 desktop
  #    `.pk-cat-item` rows (still inside the header) and the 8 mobile chips (now
  #    outside it). Scoped to `this.el` after the move, the hook still finds all
  #    8 desktop rows and ZERO chips — so the chips keep rendering, keep
  #    scrolling, keep looking completely fine, and silently never highlight
  #    again. That is the failure mode this guards: not a crash, not a blank
  #    screen, just a feature that quietly stops.
  #
  # 2. MOBILE VERTICAL BUDGET. `<main>` carried a flat `py-20` — 5rem/80px of
  #    top padding at EVERY viewport width, a desktop-scale value shipped
  #    unconditionally to phones. Measured at 390px it put the first heading at
  #    y=213: 25% of an 844px viewport, ~32% of a 667px iPhone SE, spent before
  #    any content. It was also 100% of the gap the user photographed between
  #    the chip row and "DESTACADOS DEL CLUB" — `gapWrapToHeading` measured
  #    80.00px exactly, so nothing else contributed and there was no second
  #    cause to look for.
  #
  #    The fix is deliberately asymmetric (`pb-20 pt-8 sm:pt-20`), and the
  #    bottom half is the part worth protecting. `pb-20` is not decoration
  #    balancing the top — it is the clearance that keeps the last content on
  #    Detalle and Quiénes Somos out from behind their `position: fixed;
  #    bottom: 0` CTA bars (`.pk-mobile-cta-bar` measured 68px tall,
  #    `.pk-about-cta-bar` 73px). "Tidying" the two halves back into a single
  #    symmetric `py-*` is therefore a content-occlusion bug on two pages that
  #    were never part of the report, which is exactly the kind of plausible
  #    cleanup a future reader would make.
  #
  # Oracle type: derived (contract). The real proof of both defects is rendered
  # geometry in a browser, which ExUnit cannot observe; these assertions pin the
  # structural properties that geometry is a function of. Three were verified RED
  # against the pre-fix tree — the placement one, the hook-scope one and the
  # top-padding one. The bottom-padding and minimum-top-padding assertions are
  # boundary neighbours: green by construction, guarding the two opposite wrong
  # fixes (collapse the gap to nothing; make the padding symmetric again).
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

  @layouts_path Path.expand("../../lib/pukllay_club_web/components/layouts.ex", __DIR__)

  # Tailwind's spacing scale: one step is 0.25rem = 4px.
  @px_per_step 4

  # Back above this and the phone is spending a quarter of its viewport on
  # nothing again. Sits well clear of the shipped 32px so ordinary retuning
  # doesn't trip it — it only catches a return to the desktop-scale value.
  @max_mobile_top_padding_px 48

  # ...and below this the first heading is glued to the chip row. Cycles 2-4 of
  # this same debug session burned three rounds establishing that a zero gap at
  # this boundary reads as "merged", so the floor is not hypothetical.
  @min_mobile_top_padding_px 16

  # The tallest measured fixed bottom CTA bar (.pk-about-cta-bar at 390px;
  # .pk-mobile-cta-bar is 68px). Below this, real content sits permanently
  # behind the bar with no way to scroll it clear.
  @min_bottom_padding_px 73

  defp landing_doc(conn) do
    game_fixture(%{name: "Subnav Placement Game", tags: ["#CreaConexiones"]})
    {:ok, _view, html} = live(conn, ~p"/")
    LazyHTML.from_document(html)
  end

  # Base (unprefixed) padding only — a `sm:`/`md:`/`lg:` variant applies from
  # 640px up and is explicitly NOT what mobile gets, so counting it here would
  # read the desktop value and call the mobile defect fixed.
  defp base_padding_px(class_string) do
    class_string
    |> String.split()
    |> Enum.reject(&String.contains?(&1, ":"))
    |> Enum.reduce(%{top: nil, bottom: nil}, fn token, acc ->
      case Regex.run(~r/^p([ytb])-(\d+)$/, token) do
        [_, "y", n] -> %{top: step_px(n), bottom: step_px(n)}
        [_, "t", n] -> %{acc | top: step_px(n)}
        [_, "b", n] -> %{acc | bottom: step_px(n)}
        nil -> acc
      end
    end)
  end

  defp step_px(n), do: String.to_integer(n) * @px_per_step

  describe "the chip row scrolls with the page, not with the header" do
    test "the subnav renders outside #app-header, in normal page flow", %{conn: conn} do
      doc = landing_doc(conn)

      header_html = doc |> LazyHTML.query("#app-header") |> LazyHTML.to_html()

      refute header_html =~ "pk-chip-nav",
             "The chip row is rendering INSIDE `#app-header`, which is " <>
               "`position: sticky; top: 0` (.pk-header-sticky). Sticky pins the whole box, so " <>
               "from there the chip row cannot scroll away no matter what CSS is applied to it " <>
               "— measured pre-fix at y=64..133 at scrollY 0 and STILL y=64..133 at scrollY " <>
               "1400, zero relative motion. The user explicitly asked for it to scroll away " <>
               "with the page, so it has to be rendered as a sibling of the header, not a child."

      subnav_html = doc |> LazyHTML.query("#app-subnav") |> LazyHTML.to_html()

      assert subnav_html =~ "pk-chip-nav-wrap",
             "No `#app-subnav` element containing the chip row. That id is not decorative: it " <>
               "is how `.CatalogNav` reaches the chips for scroll-spy now that they live " <>
               "outside the hook's own element. Rename or drop it and the chips stop " <>
               "highlighting, silently."
    end

    test "the scroll-spy hook collects targets from the subnav as well as the header" do
      source = File.read!(@layouts_path)

      [_, spy_setup] = String.split(source, "this.spyRoots", parts: 2)
      spy_setup = String.slice(spy_setup, 0, 400)

      assert spy_setup =~ "app-subnav",
             "`.CatalogNav` builds its scroll-spy target list without referencing " <>
               "`#app-subnav`. The two surfaces carrying `data-chip-target` no longer share an " <>
               "element: the 8 desktop `.pk-cat-item` rows are inside `#app-header`, the 8 " <>
               "mobile chips are outside it. A collection scoped to `this.el` alone still finds " <>
               "the desktop rows and none of the chips — so the chip row renders, scrolls and " <>
               "looks perfectly healthy while never highlighting again. Verified in a browser: " <>
               "16 targets found across both roots, exactly 1 active, and the active chip " <>
               "tracks correctly across scroll (Destacados -> Equipo ganador -> Ingenio " <>
               "estratega -> Recientemente añadidos at 390px)."
    end
  end

  describe "<main>'s vertical padding is sized for the viewport it renders on" do
    test "the desktop top padding is not shipped to mobile", %{conn: conn} do
      classes =
        conn |> landing_doc() |> LazyHTML.query("main") |> LazyHTML.attribute("class") |> hd()

      %{top: top} = base_padding_px(classes)

      assert top,
             "`<main>` declares no base (unprefixed) vertical top padding at all in `#{classes}`."

      assert top <= @max_mobile_top_padding_px,
             "`<main>` reserves #{top}px of top padding at mobile widths, over the " <>
               "#{@max_mobile_top_padding_px}px ceiling. This shipped as a flat `py-20` — one " <>
               "80px value for every viewport — which measured at 390px put the first heading " <>
               "at y=213, a quarter of the viewport spent before any content, and accounted for " <>
               "100.00% of the gap a user reported as \"too separated\" (gapWrapToHeading " <>
               "measured exactly 80.00px). Give the desktop value a breakpoint prefix rather " <>
               "than applying it unconditionally."

      assert top >= @min_mobile_top_padding_px,
             "`<main>` reserves only #{top}px of top padding at mobile, under the " <>
               "#{@min_mobile_top_padding_px}px floor — the first heading is now glued to the " <>
               "chip row above it. This is the opposite failure to the one above and it is not " <>
               "hypothetical: cycles 2-4 of this same debug session spent three rounds " <>
               "establishing that a collapsed gap at this boundary reads as \"merged\" to a " <>
               "human on a real device. Trimming excess is not the same as removing separation."
    end

    test "the bottom padding survives, because it is fixed-CTA-bar clearance", %{conn: conn} do
      classes =
        conn |> landing_doc() |> LazyHTML.query("main") |> LazyHTML.attribute("class") |> hd()

      %{bottom: bottom} = base_padding_px(classes)

      assert bottom && bottom >= @min_bottom_padding_px,
             "`<main>` reserves #{inspect(bottom)}px of bottom padding at mobile, under the " <>
               "#{@min_bottom_padding_px}px floor. This padding is not decoration balancing the " <>
               "top — Detalle (`.pk-mobile-cta-bar`, measured 68px) and Quiénes Somos " <>
               "(`.pk-about-cta-bar`, measured 73px) both render `position: fixed; bottom: 0` " <>
               "CTA bars at mobile, and this is the only thing keeping their last content from " <>
               "sitting permanently behind one. The top and bottom halves are asymmetric on " <>
               "purpose; folding them back into one `py-*` to tidy them up is a content- " <>
               "occlusion bug on two pages that were never part of the report."
    end
  end
end
