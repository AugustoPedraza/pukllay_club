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

  describe "the open box's own edges sit on the shared gutter line" do
    test "the inset's horizontal component reads the shared gutter token" do
      body = open_morph_narrow_block(source())

      assert body =~ ~r/inset:\s*0\s+var\(--pk-gutter\)\s*;/,
             "`.pk-search-morph.is-open`'s `inset` must be a two-value shorthand whose " <>
               "horizontal component is `var(--pk-gutter)` (vertical stays 0). A single-value " <>
               "`inset: 0` resolves against the containing block's PADDING edge, which at " <>
               "≤480px is the viewport edge — that is the whole bug: the box's own background, " <>
               "border and shadow reach the screen edge instead of the content line every other " <>
               "aligned surface (brand mark, chip row, grid, footer) shares."
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
