defmodule PukllayClubWeb.HeaderSearchGutterTest do
  # Guards the open mobile search box's HORIZONTAL ALIGNMENT — the class of bug
  # where a box floats free of the page's shared gutter line because its inset
  # is resolved against the containing block's padding edge, not its content
  # edge.
  #
  # Motivating incident (quick task 260824-hu1): `.pk-nav-inner` carries
  # `position: relative` and the `.pk-gutter` padding, so it is the containing
  # block for the absolutely-positioned open morph inside the trailing
  # `@media (max-width: 480px)` block. That block set `inset: 0`, which for an
  # absolutely-positioned element resolves against the containing block's
  # PADDING edge — so a zero inset landed the box's own background, border and
  # shadow on the viewport edge, stepping straight over `.pk-gutter`. The rule
  # tried to compensate with its own `padding-inline: var(--pk-gutter)`, but
  # that only inset the box's *contents*; the box itself (and its bottom-only
  # `border-radius` override) still ran edge-to-edge, which is exactly what
  # read as "full width, ignoring the margin, breaking rhythm."
  #
  # Oracle type: derived (contract). The real proof is rendered geometry, which
  # ExUnit cannot observe; these assertions pin the declarations that geometry
  # depends on. Every assertion here was verified RED against the pre-fix
  # stylesheet, not merely green after it.
  use ExUnit.Case, async: true

  @css_path Path.expand("../../assets/css/app.css", __DIR__)

  defp source, do: File.read!(@css_path)

  # Comments are prose, not cascade. Matching selector/declaration names inside
  # a comment is a false pass — this file's siblings (footer_rhythm_test.exs)
  # strip comments up front for the same reason, and this rule's own leading
  # comment is being rewritten by this same change to describe the very
  # declarations these assertions check for.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  # First top-level declaration block for a selector, matched on exact selector
  # text, anchored to the start of a line so `.pk-search-morph` never matches
  # `.pk-search-morph.is-open`.
  defp block!(src, selector) do
    pattern = Regex.compile!("(?m)^#{Regex.escape(selector)}\\s*\\{([^}]*)\\}")

    case Regex.run(pattern, strip_comments(src)) do
      [_, body] -> body
      nil -> flunk("No top-level rule found for `#{selector}` in assets/css/app.css")
    end
  end

  # Everything from the trailing narrow-viewport block to the end of the file.
  defp narrow_viewport_block(src) do
    [_, tail] = String.split(strip_comments(src), "@media (max-width: 480px) {", parts: 2)
    tail
  end

  defp open_morph_narrow_block(src) do
    case Regex.run(~r/\.pk-search-morph\.is-open\s*\{([^}]*)\}/, narrow_viewport_block(src)) do
      [_, body] -> body
      nil -> flunk("No `.pk-search-morph.is-open` rule found in the ≤480px block")
    end
  end

  # The narrow-viewport BASE rule (indented inside the media block, so the
  # line-anchored block!/2 above deliberately cannot reach it). Since debug
  # mobile-search-expand-jump this rule — not `.is-open` — owns the box's
  # position and right edge, because the morph must be absolutely positioned in
  # BOTH states for the width transition to animate symmetrically.
  defp base_morph_narrow_block(src) do
    case Regex.run(~r/(?m)^\s+\.pk-search-morph\s*\{([^}]*)\}/, narrow_viewport_block(src)) do
      [_, body] -> body
      nil -> flunk("No base `.pk-search-morph` rule found in the ≤480px block")
    end
  end

  describe "the open box's own edges sit on the shared gutter line" do
    # Rewritten by debug mobile-search-expand-jump. This asserted the literal
    # `inset: 0 var(--pk-gutter)` shorthand — the MECHANISM rather than the
    # INVARIANT — so it failed on a change that preserves the alignment it
    # exists to protect. The box is no longer positioned by a two-value inset
    # (a `left`+`right` pair makes `width` resolve to `auto`, which is not
    # interpolable and is precisely why the pill snapped open instead of
    # animating). It is now anchored by its RIGHT edge with an explicit
    # interpolable width. Both horizontal edges still land on the gutter line:
    # right = gutter by declaration, left = 100% − (100% − 2·gutter) − gutter =
    # gutter by arithmetic. Verified in-browser at 390px: x=14, right=376.
    test "both horizontal edges are derived from the shared gutter token" do
      base = base_morph_narrow_block(source())
      open = open_morph_narrow_block(source())

      assert base =~ ~r/right:\s*var\(--pk-gutter\)\s*;/,
             "The ≤480px base `.pk-search-morph` rule must pin the box's RIGHT edge to " <>
               "`var(--pk-gutter)`. This is what keeps the open box's own background, border " <>
               "and shadow on the content line every other aligned surface (brand mark, chip " <>
               "row, grid, footer) shares, instead of running to the viewport edge."

      assert open =~ ~r/width:\s*calc\(\s*100%\s*-\s*2\s*\*\s*var\(--pk-gutter\)\s*\)/,
             "`.pk-search-morph.is-open`'s width must be " <>
               "`calc(100% - 2 * var(--pk-gutter))`. Two things ride on this single " <>
               "declaration. ALIGNMENT: with the right edge pinned to the gutter, subtracting " <>
               "exactly two gutters is what lands the LEFT edge on the same line. MOTION: it " <>
               "must be a calc(), never `auto` — `auto` is not interpolable, so the width " <>
               "transition never starts and the pill snaps open in a single frame (318px of " <>
               "travel in one paint). See debug mobile-search-expand-jump."

      refute open =~ ~r/width:\s*auto/,
             "`.pk-search-morph.is-open` must never set `width: auto` at ≤480px. That is the " <>
               "original mobile-search-expand-jump defect verbatim: a non-interpolable width " <>
               "means `transitionrun` never fires and the box teleports."
    end

    test "the box stays absolutely positioned in BOTH states, not just when open" do
      base = base_morph_narrow_block(source())
      open = open_morph_narrow_block(source())

      assert base =~ ~r/position:\s*absolute/,
             "The ≤480px base `.pk-search-morph` rule must declare `position: absolute` so the " <>
               "morph is out of flow in BOTH states. `position` is not an animatable property, " <>
               "so flipping it on the `.is-open` toggle is a discrete teleport."

      refute open =~ ~r/position:\s*/,
             "`.pk-search-morph.is-open` must NOT declare `position` at ≤480px — the base rule " <>
               "above owns it. Moving it back here recreates the half of the bug that only " <>
               "bites on COLLAPSE: `.is-open` leaves at t=0, the still-362px box drops back " <>
               "into the flex row, and because `.is-open`'s `flex-shrink: 1` left with it the " <>
               "base `flex: 0 0 auto` refuses to give — measured documentElement.scrollWidth " <>
               "444px against a 390px viewport, i.e. a horizontal scrollbar flashing for 280ms " <>
               "on every close. This is the boundary neighbour: fixing only the width passes " <>
               "every expand-direction check and still ships that regression."
    end

    test "the box no longer fakes the inset with its own horizontal padding" do
      body = open_morph_narrow_block(source())

      refute body =~ ~r/padding/,
             "`.pk-search-morph.is-open` still declares padding in the ≤480px block. Now that " <>
               "the box itself is genuinely inset by position, a horizontal padding on top of " <>
               "it would double-apply and squeeze the input — this stylesheet's single-owner " <>
               "rule means horizontal space has exactly one owner, and that owner is now the " <>
               "`inset`."
    end

    test "the open state does not re-declare border-radius, so the base pill shape wins" do
      body = open_morph_narrow_block(source())

      refute body =~ ~r/border-radius/,
             "`.pk-search-morph.is-open` still overrides `border-radius` in the ≤480px block. " <>
               "A gutter-inset box with square top corners (the bottom-only override) reads as " <>
               "a slab clipped by the header rather than the pill it morphed from. Deleting the " <>
               "override is how the base rule's fully-rounded pill is restored — it must never " <>
               "be re-declared a second time here."
    end

    test "the open toggle's glyph padding is not re-zeroed in the narrow-viewport block" do
      refute narrow_viewport_block(source()) =~
               ~r/\.pk-search-morph\.is-open \.pk-search-morph-toggle\s*\{[^}]*padding-left/,
             "The ≤480px block still zeroes `.pk-search-morph.is-open .pk-search-morph-toggle`'s " <>
               "left padding. That override existed only to compensate for the box's own fake " <>
               "padding; with the box genuinely gutter-inset, the base open-state rule's own " <>
               "glyph padding must be the single owner of that value at every viewport."
    end
  end

  describe "the base pill shape and the mobile gutter retune are still in force" do
    test "the base .pk-search-morph rule still owns the pill border-radius" do
      body = block!(source(), ".pk-search-morph")

      assert body =~ "border-radius: 9999px",
             "The base `.pk-search-morph` rule must still declare its fully-rounded pill " <>
               "border-radius. Without it, deleting the narrow-viewport override in the test " <>
               "above would restore no shape at all rather than the pill."
    end

    test "the narrow-viewport block still retunes --pk-gutter for the mobile scale" do
      assert narrow_viewport_block(source()) =~ ~r/--pk-gutter:\s*0\.875rem/,
             "The ≤480px block must still retune `--pk-gutter` to its mobile value. The open " <>
               "morph's inset consumes this same token, so the box tracks the mobile gutter " <>
               "(not the 2rem desktop one) only as long as this retune stays in place."
    end
  end
end
