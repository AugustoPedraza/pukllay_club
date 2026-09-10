defmodule PukllayClubWeb.HeaderCapacityTest do
  # Guards the header row's WIDTH CAPACITY — the class of bug where a breakpoint
  # is chosen by convention rather than derived from the row's own content
  # arithmetic, so the layout is correct on the devices the author tested and
  # broken on the ones they did not.
  #
  # Motivating incident (debug session search-pill-tablet-squeeze). All three of
  # this header's breakpoints were derived against the CLOSED row, and the open
  # search pill absorbs 100% of every derivation error because it is the row's
  # only yielder (`min-width: 0; flex-shrink: 1`, while `.pk-brand-wordmark` and
  # `.pk-nav-links` are pinned `flex-shrink: 0` by debug
  # header-height-wordmark-wrap and `.pk-cat-trigger` is `flex: 0 0 auto`). The
  # result was a SAWTOOTH in which a wider viewport was strictly worse:
  #
  #   * 48rem/768px revealed the wordmark. Its documented sum, 250 + 24 + 166.3
  #     + 24 + 280 + 64 = 808.3px, is three items and two gaps — it OMITTED
  #     `.pk-cat-trigger` (44px) and its gap (24px). It predicted a 239.7px pill
  #     at 768px; measured, 171.7px, short by exactly the missing 68px.
  #   * 50rem/800px revealed the trigger's label. It was bisected on the CLOSED
  #     row's scrollWidth after this very defect had already been observed "at a
  #     functionally useless 2px" — so it RELOCATED the cliff from 768px to
  #     800px rather than removing it. 799px measured a 202.7px pill; 800px
  #     measured 49px, five pixels wider than the closed icon it morphed from.
  #     One extra pixel of viewport destroyed the search box.
  #   * 480px, the mobile overlay boundary, is 182px below the 662.3px the row
  #     actually needs to seat links + trigger + an open pill.
  #
  # So this file does not pin any of those widths. It RECOMPUTES the row's
  # requirement from the stylesheet's own declared values plus a measured
  # content inventory, and asserts each declared breakpoint against the number
  # that comes out. Retune `--pk-gutter`, the row gap or the pill's width and
  # these assertions move with it and name the new number.
  #
  # UPDATE (2026-09-09, this session's header minimalism pass, G-01.5 gap
  # closure follow-on): the brand lockup used to be a two-line "PUKLLAY CLUB" /
  # tagline stack, hidden below 56rem/896px and revealed as a THIRD cliff
  # alongside the two above. It is now a single line ("PUKLLAY CLUB", no
  # tagline), unconditionally visible at every width — narrow enough (155.3px
  # vs the old 250px) that there is no width left where the row cannot seat it.
  # The wordmark-reveal cliff and its test are retired entirely, not just
  # re-derived; every `required/1` sum below now uses the one-line width in
  # place of what used to be a width-dependent isologo-alone-vs-full-lockup
  # split.
  #
  # Oracle type: derived (contract). The real proof is rendered geometry, which
  # ExUnit cannot observe — it was a live CDP sweep across dozens of widths on
  # both the catalog and About headers (this session) plus the original
  # 47-width sweep across four header shapes (search-pill-tablet-squeeze).
  # These assertions pin the arithmetic that geometry depends on.
  use ExUnit.Case, async: true

  @css_path Path.expand("../../assets/css/app.css", __DIR__)
  @catalog_path Path.expand("../../lib/pukllay_club_web/live/catalog_live/index.ex", __DIR__)
  @about_path Path.expand("../../lib/pukllay_club_web/live/about_live.ex", __DIR__)
  @layouts_path Path.expand("../../lib/pukllay_club_web/components/layouts.ex", __DIR__)

  # ── The measured half of the model ────────────────────────────────────────
  #
  # These four are RENDERED TEXT WIDTHS. They cannot be derived from CSS, so
  # they are recorded here with their provenance and fenced by the copy
  # tripwire below: change any of the strings they were measured against and
  # that test fails, demanding a re-measurement instead of silently invalidating
  # every number in this file.
  #
  # Provenance: `brand_lockup_w` — headless Chrome, --force-device-scale-factor=1,
  # catalog header, max-content width of `.pk-nav-inner > .shrink-0` (the
  # isologo + gap-2 + one-line "PUKLLAY CLUB" wordmark), this session
  # (2026-09-09), after the header's two-line-lockup-to-one-line change. The
  # other three are unchanged from the original search-pill-tablet-squeeze
  # sweep (2026-08-25) — the wordmark change touched only the brand cluster.
  @brand_lockup_w 155.3
  @nav_links_w 166.3
  @trigger_icon_w 44.0
  @trigger_label_w 154.7

  # The exact copy those widths were measured against, as WHOLE strings. Not as
  # substrings to search for: `String.contains?` is satisfied by "Quiénes Somos y
  # Nuestra Historia", and lengthening a label is precisely the drift that widens
  # the row — the failure mode a containment check is blind to is the only one
  # that matters here.
  @measured_copy [
    {"catalog nav links", @catalog_path, ["Inicio", "Quiénes Somos"]},
    {"about nav links", @about_path, ["Inicio", "Quiénes Somos"]},
    {"brand name", @layouts_path, ["PUKLLAY CLUB"]},
    {"category trigger label", @layouts_path, ["Explorar categorías"]}
  ]

  # Each extractor returns the rendered text of the elements whose widths were
  # measured, in source order.
  defp extract_copy("catalog nav links", src), do: nav_link_labels(src)
  defp extract_copy("about nav links", src), do: nav_link_labels(src)

  # Order-independent on the class attribute (`pk-brand-wordmark pk-brand-name
  # ...` since this session merged the two classes onto one element, not
  # `pk-brand-name pk-brand-wordmark` or `pk-brand-name` alone) — matches
  # `pk-brand-name` as a whole class token anywhere in the attribute rather
  # than requiring it to open the string, so a future class-order edit cannot
  # silently break this extractor the way it would a `class="pk-brand-name`
  # anchored match.
  defp extract_copy("brand name", src),
    do: captures(src, ~r/<span class="[^"]*\bpk-brand-name\b[^"]*">\s*([^<]*?)\s*<\/span>/)

  defp extract_copy("category trigger label", src),
    do: captures(src, ~r/<span class="pk-cat-trigger-label">\s*([^<]*?)\s*<\/span>/)

  defp nav_link_labels(src) do
    case Regex.run(~r/<:nav_links>(.*?)<\/:nav_links>/s, src) do
      [_, slot] -> captures(slot, ~r/>\s*([^<>]*?)\s*<\/\.link>/)
      nil -> []
    end
  end

  defp captures(src, pattern), do: pattern |> Regex.scan(src) |> Enum.map(fn [_, text] -> text end)

  defp source, do: File.read!(@css_path)

  # Comments are prose, not cascade — and this stylesheet's header comments
  # quote every declaration and number these assertions look for, at length.
  # Matching inside them is a guaranteed false pass.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  defp px("" <> raw) do
    case Regex.run(~r/^\s*([\d.]+)\s*(rem|px)\s*$/, raw) do
      [_, n, "rem"] -> parse_number(n) * 16
      [_, n, "px"] -> parse_number(n)
      _ -> flunk("Could not read a px/rem length from #{inspect(raw)}")
    end
  end

  defp parse_number(n) do
    {f, ""} = Float.parse(if String.contains?(n, "."), do: n, else: n <> ".0")
    f
  end

  # A declaration read out of the first top-level rule for `selector`.
  defp decl!(selector, property) do
    src = strip_comments(source())
    rule = Regex.compile!("(?m)^#{Regex.escape(selector)}\\s*\\{([^}]*)\\}")

    body =
      case Regex.run(rule, src) do
        [_, body] -> body
        nil -> flunk("No top-level rule for `#{selector}` in assets/css/app.css")
      end

    case Regex.run(Regex.compile!("(?<![-\\w])#{property}:\\s*([^;]+);"), body) do
      [_, value] -> String.trim(value)
      nil -> flunk("`#{selector}` declares no `#{property}` in assets/css/app.css")
    end
  end

  # ── The declared half of the model, read out of the stylesheet ────────────

  # UPDATED (quick task 260910-l7q): app.css now declares a SECOND plain
  # `:root { ... }` block (the `--pk-ramp-*` shared colour ramp, ordered
  # BEFORE this one) -- `decl!/2`'s first-match `:root` lookup would
  # silently grab that one instead, which declares no `--pk-gutter`.
  # Disambiguate by scanning every plain `:root` block for the one that
  # actually declares the property, the same idiom this stylesheet's other
  # multi-`:root`-block tests already use.
  defp decl_in_matching_root!(property) do
    src = strip_comments(source())

    ~r/(?m)^:root\s*\{([^}]*)\}/
    |> Regex.scan(src, capture: :all_but_first)
    |> List.flatten()
    |> Enum.find_value(fn body ->
      case Regex.run(Regex.compile!("(?<![-\\w])#{property}:\\s*([^;]+);"), body) do
        [_, value] -> String.trim(value)
        nil -> nil
      end
    end) || flunk("No top-level `:root` block declares `#{property}` in assets/css/app.css")
  end

  defp gutter, do: px(decl_in_matching_root!("--pk-gutter"))
  defp row_gap, do: px(decl!(".pk-nav-inner", "gap"))
  defp open_pill, do: px(decl!(".pk-search-morph.is-open", "width"))
  defp closed_morph, do: px(decl!(".pk-search-morph", "width"))

  # The row must seat `content + every gap between it + both gutters + a FULL
  # pill`. `items` is the in-flow inventory left of the pill, so the gap count
  # is length(items) — one between each pair, plus one before the pill.
  defp required(items) do
    Enum.sum(items) + length(items) * row_gap() + open_pill() + 2 * gutter()
  end

  # The brand lockup is now a single unconditional width at every viewport —
  # there is no more "isologo alone" state to compute separately (that was
  # the pre-2026-09-09 wordmark-hidden case). Both the overlay-band ceiling
  # and the trigger-label reveal use this same brand width.
  defp content_required, do: required([@brand_lockup_w, @nav_links_w, @trigger_icon_w])

  defp label_required, do: required([@brand_lockup_w, @nav_links_w, @trigger_icon_w + @trigger_label_w])

  # Every `@media (min-width: X)` block whose body matches `pattern`, as widths
  # in px. Splitting on `@media` keeps each block's own condition attached to
  # its own body, so a rule in a later block cannot be credited to an earlier
  # breakpoint.
  defp reveal_widths(pattern) do
    source()
    |> strip_comments()
    |> String.split("@media (min-width: ")
    |> Enum.drop(1)
    |> Enum.filter(fn chunk ->
      [head | _] = String.split(chunk, "@media", parts: 2)
      head =~ pattern
    end)
    |> Enum.map(fn chunk ->
      case Regex.run(~r/^([\d.]+(?:rem|px))/, chunk) do
        [_, len] -> px(len)
        nil -> flunk("Could not parse the min-width value on a reveal block")
      end
    end)
  end

  # The `@media (max-width: Npx)` block carrying the overlay band, identified by
  # the rule it contains rather than by its width — identifying it by width
  # would be the very pinning this file exists to avoid.
  defp overlay_band do
    matches =
      ~r/@media \(max-width: (\d+)px\) \{(.*?)\n\}/s
      |> Regex.scan(strip_comments(source()))
      |> Enum.filter(fn [_, _, body] -> body =~ ~r/\.pk-search-morph:where\(/ end)

    case matches do
      [[_, w, body]] -> {String.to_integer(w), body}
      [] -> flunk("No `@media (max-width: Npx)` block contains the overlay-band morph rule")
      many -> flunk("Expected exactly one overlay-band block, found #{length(many)}")
    end
  end

  describe "the content the arithmetic was measured against has not drifted" do
    # THE TRIPWIRE. Everything else in this file is a sum over four measured
    # text widths, and text widths are a function of copy. Silently keeping the
    # numbers while the strings change is how a derived breakpoint decays back
    # into a guessed one — which is this bug's entire recurrence path (KB branch
    # F, content-dependence, also recorded by header-height-wordmark-wrap).
    test "the header copy still matches the strings the widths were measured from" do
      drifted =
        for {what, path, expected} <- @measured_copy,
            actual = extract_copy(what, File.read!(path)),
            actual != expected,
            do:
              "#{Path.relative_to_cwd(path)} — #{what}: measured #{inspect(expected)}, " <>
                "now #{inspect(actual)}"

      assert drifted == [],
             """
             Header copy has changed. The row's measured content widths were taken from
             these exact strings, and they no longer match:

             #{Enum.map_join(drifted, "\n", &("  - " <> &1))}

             Every breakpoint in this suite is a sum over those widths (brand lockup
             #{@brand_lockup_w}, nav links #{@nav_links_w}, trigger icon #{@trigger_icon_w},
             trigger label #{@trigger_label_w}), so changing the copy invalidates all of
             them — silently, and only at viewport widths nobody is looking at.

             RE-MEASURE, don't re-guess: render the header, read the max-content width of
             `.pk-nav-inner > .shrink-0` (the brand lockup), `.pk-nav-links` and
             `.pk-cat-trigger` (icon-only and with its label), update the module
             attributes at the top of this file with the new numbers, and let the
             assertions below tell you where the breakpoints move to.
             """
    end
  end

  describe "the breakpoints are derived from the row's arithmetic" do
    test "the trigger label is revealed only once the row can seat it plus a full pill" do
      required = label_required()
      widths = reveal_widths(~r/\.pk-cat-trigger-label\s*\{[^}]*display:\s*inline/)

      assert widths != [],
             "No `@media (min-width: ...)` block reveals `.pk-cat-trigger-label`."

      for w <- widths do
        assert w >= required,
               """
               `.pk-cat-trigger-label` is revealed at #{trunc(w)}px, but with the label showing
               the row needs #{Float.round(required, 1)}px to still seat a full
               #{trunc(open_pill())}px pill (brand lockup #{@brand_lockup_w} + nav links
               #{@nav_links_w} + trigger icon+label #{@trigger_icon_w + @trigger_label_w}).

               This is the assertion that fails on the original defect. 50rem/800px was chosen by
               bisecting the CLOSED row's scrollWidth, which clears at 780px — but the OPEN row is
               251px wider, so the closed measurement cannot see this constraint at all. At 800px
               the open pill measured 49px. Compute this number; do not probe for it.
               """

        assert w >= required + 16,
               "`.pk-cat-trigger-label` is revealed at #{trunc(w)}px, only " <>
                 "#{Float.round(w - required, 1)}px above its #{Float.round(required, 1)}px " <>
                 "requirement. Same reason as the overlay band below: a cliff derived from " <>
                 "measured text widths needs at least 1rem of headroom for real-device font " <>
                 "metrics."

        assert w < required + 32,
               "`.pk-cat-trigger-label` is revealed at #{trunc(w)}px, more than 2rem above its " <>
                 "#{Float.round(required, 1)}px requirement. The trigger renders icon-only below " <>
                 "this width and its label is what makes the control legible."
      end
    end
  end

  describe "the overlay band covers exactly the widths that cannot fit" do
    test "the band's ceiling is the last width at which the row cannot seat a full pill" do
      {ceiling, _body} = overlay_band()
      required = content_required()
      expected = ceil(required) - 1

      assert ceiling == expected,
             """
             The search overlay band ends at #{ceiling}px, but the row cannot seat the brand
             lockup, the nav links, the icon-only trigger and a full #{trunc(open_pill())}px
             pill until #{Float.round(required, 1)}px:

               #{@brand_lockup_w} + #{trunc(row_gap())} + #{@nav_links_w} + #{trunc(row_gap())} +
               #{@trigger_icon_w} + #{trunc(row_gap())} + #{trunc(open_pill())} + #{trunc(2 * gutter())}
               = #{Float.round(required, 1)}px

             So the band must end at #{expected}px — the last integer width that still cannot
             fit. Ending it lower leaves the pill squeezed in the gap; ending it higher overlays
             the row at widths where the pill fits in flow, covering the category trigger for no
             reason.

             Unlike the reveal above, this boundary takes NO headroom on purpose. A reveal
             is a cliff; this is a ramp — one pixel past it the in-flow pill is 280px, then 279,
             then 278, so a few px of content drift costs a few px of input width and nothing
             else.
             """
    end

    test "the band overlaps the mobile block rather than abutting it" do
      {ceiling, _body} = overlay_band()

      mobile =
        ~r/@media \(max-width: (\d+)px\) \{/
        |> Regex.scan(strip_comments(source()))
        |> Enum.map(fn [_, w] -> String.to_integer(w) end)
        |> Enum.reject(&(&1 == ceiling))
        |> Enum.max(fn -> nil end)

      assert mobile,
             "No mobile `@media (max-width: Npx)` block found beside the overlay band."

      assert ceiling > mobile,
             """
             The overlay band (max-width: #{ceiling}px) does not cover the mobile block
             (max-width: #{mobile}px). These two ranges must OVERLAP, not abut.

             Writing the band as `min-width: #{mobile + 1}px` instead would leave a sub-pixel
             gap — a #{mobile}.5px viewport matches NEITHER rule, so the morph falls back into
             flow and renders the squeezed pill this whole session is about. That is debug
             search-right-align-mobile's finding, where the mirror image of this gap stranded the
             closed pill 222px from the row's edge.

             The overlap is resolved by source order, which is why the band's selector is
             `:where()`-wrapped — see the next test.
             """
    end

    test "the band holds `.pk-search-morph`'s own specificity so source order decides the overlap" do
      {_ceiling, body} = overlay_band()

      assert body =~ ~r/\.pk-search-morph:where\(\.pk-nav-links\s*~\s*\*\)/,
             """
             The overlay band's morph rule must be written
             `.pk-search-morph:where(.pk-nav-links ~ *)`. Two separate jobs ride on that form:

             SCOPE. `.pk-nav-links` is present on the catalog index in both filter states and
             absent from Detalle, whose `.pk-nav-crumb` is `flex: 1` — Detalle yields the row to
             the pill instead of the other way round and measured a full 280px pill at every
             width, so it must not be dragged into this fix. Unscoped, taking the morph out of
             flow there lets the crumb grow into the vacated 68px and run the game title under
             the search icon.

             SPECIFICITY. The band deliberately overlaps the mobile block, and `:where()`
             contributes zero, holding this rule at `.pk-search-morph`'s own 0-1-0 so the later
             mobile block simply wins where both match. Written as a bare
             `.pk-nav-links ~ .pk-search-morph` (0-2-0) it would outrank the mobile block on the
             catalog page and freeze the phone overlay at these values — a rule two thousand
             lines away quietly deciding what phones get.
             """
    end

    test "the band positions the morph in BOTH states, never on the .is-open toggle" do
      {_ceiling, body} = overlay_band()

      [_, morph_rule] =
        Regex.run(~r/\.pk-search-morph:where\([^)]*\)\s*\{([^}]*)\}/, body) ||
          flunk("No morph rule inside the overlay band")

      assert morph_rule =~ ~r/position:\s*absolute/,
             "The overlay band's base morph rule must declare `position: absolute` so the box " <>
               "is out of flow in both states."

      assert morph_rule =~ ~r/right:\s*var\(--pk-gutter\)/,
             "The overlay band's morph rule must pin the box's RIGHT edge to " <>
               "`var(--pk-gutter)`. That declaration is the whole closed-vs-open right-edge " <>
               "invariant: with it, the edge cannot move between states because nothing about " <>
               "it is state-dependent. Measured identical at 47/47 widths."

      refute body =~ ~r/\.pk-search-morph[^{]*\.is-open[^{]*\{[^}]*position:/,
             """
             The overlay band puts `position` on the `.is-open` toggle. `position` is not an
             animatable property, so flipping it with the class is a discrete teleport mid-flight
             — and it is invisible on EXPAND, so a one-directional check goes green on it.

             Debug mobile-search-expand-jump measured that exact shape (its "C1" arm) at
             documentElement.scrollWidth 444px against a 390px viewport on every COLLAPSE: the
             class leaves at t=0, the still-open-width box drops back into the flex row, and the
             row overflows for the rest of the 280ms. Keep `position` on the base rule and let
             `.is-open` change nothing but an interpolable width.
             """
    end

    test "the band reserves the footprint the morph stops occupying in flow" do
      {_ceiling, body} = overlay_band()

      [_, reservation] =
        Regex.run(~r/\.pk-nav-links\s*~\s*\.pk-cat-trigger\s*\{([^}]*)\}/, body) ||
          flunk(
            "The overlay band does not reserve the morph's footprint on `.pk-cat-trigger`. " <>
              "Out of flow the morph stops consuming its width plus the row's gap, so the " <>
              "trigger's own `margin-left: auto` slides it right by exactly that much — " <>
              "landing it underneath the closed search icon."
          )

      [_, value] =
        Regex.run(~r/margin-right:\s*([^;]+);/, reservation) ||
          flunk("The reservation rule declares no `margin-right`.")

      terms =
        ~r/([\d.]+(?:rem|px))/
        |> Regex.scan(value)
        |> Enum.map(fn [_, len] -> px(len) end)
        |> Enum.sum()

      expected = closed_morph() + row_gap()

      assert_in_delta terms,
                      expected,
                      0.01,
                      """
                      The overlay band reserves #{terms}px for the out-of-flow morph, but the
                      footprint it vacates is #{expected}px — the closed morph's own
                      #{trunc(closed_morph())}px width plus `.pk-nav-inner`'s #{trunc(row_gap())}px
                      gap, both read from this stylesheet.

                      Over-reserving leaves a visible hole between the trigger and the search
                      icon; under-reserving slides the trigger under the icon. Either way the
                      CLOSED row stops being byte-identical to what it renders today, which is
                      the property that makes this whole fix invisible until you open the search.
                      """
    end
  end
end
