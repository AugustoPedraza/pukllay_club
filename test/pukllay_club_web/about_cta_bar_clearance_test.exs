defmodule PukllayClubWeb.AboutCtaBarClearanceTest do
  # Pins the About page's document-end clearance for its fixed mobile CTA bar
  # (debug cta-bar-footer-gap-uncolored, sketch 053 winner D).
  #
  # THE DEFECT THIS GUARDS: `body:has(.pk-about-cta-bar)`'s `padding-bottom` is
  # `body` padding — it lies OUTSIDE `.pk-footer`'s border-box, so every pixel
  # of it paints the PAGE background, never the footer's fill. The fixed bar
  # covers exactly `--pk-about-cta-bar-h` of that reservation, which makes any
  # ADDITIVE term the one part that can never be covered: it is permanently
  # visible at the true page bottom as an uncoloured band between the footer
  # and the bar. A `+ 1rem` "breathing step" shipped here once and was reported
  # (measured 15.61px of page background at 390x844, both themes).
  #
  # ORACLE TYPE: derived (contract). The true oracle is rendered geometry —
  # the distance from the footer's painted bottom edge to the bar's top border
  # — which ExUnit cannot observe. These assertions pin the CSS contract that
  # geometry depends on, following `about_band_width_test.exs` and
  # `footer_rhythm_test.exs`.
  use ExUnit.Case, async: true

  @css_path Path.expand("../../assets/css/app.css", __DIR__)

  defp source, do: File.read!(@css_path)

  # Comments are prose, not cascade. A selector or value named in a comment
  # must never satisfy an assertion here — strip before matching. (This file
  # documents the removed `+ 1rem` at length in a comment directly above the
  # rule, so stripping is load-bearing, not boilerplate: without it every
  # assertion below would match the prose describing the bug.)
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  defp clearance_block(src) do
    case Regex.run(~r/body:has\(\.pk-about-cta-bar\)\s*\{([^}]*)\}/, strip_comments(src)) do
      [_, body] ->
        body

      nil ->
        flunk("""
        No `body:has(.pk-about-cta-bar)` rule found in assets/css/app.css.

        This rule is the ONLY thing keeping the fixed CTA bar from covering the
        footer's "Powered by BGG" line at the true page bottom. If it was
        renamed or replaced, re-point this test at its replacement — do not
        delete the guard.
        """)
    end
  end

  defp clearance_value(src) do
    block = clearance_block(src)

    case Regex.run(~r/padding-bottom:\s*([^;]+);/, block) do
      [_, value] -> String.trim(value)
      nil -> flunk("`body:has(.pk-about-cta-bar)` declares no `padding-bottom`: #{block}")
    end
  end

  test "the document-end clearance reserves the bar's live-measured height and NOTHING more" do
    value = clearance_value(source())

    # A top-level `calc()` is the only way to add a term to this value, so
    # "the value is a bare var(), not a calc()" is the whole equivalence
    # class in one assertion — it rejects `+ 1rem` and every neighbour of it
    # (`+ 0.5rem`, `+ 8px`, `+ 2rem`) identically, rather than pinning the one
    # literal that happened to ship.
    refute String.starts_with?(value, "calc("),
           """
           `body:has(.pk-about-cta-bar)` wraps its reservation in a top-level calc():

               padding-bottom: #{value};

           This reservation must be the bar's own height and nothing else. It is
           `body` padding, so it sits OUTSIDE the footer's box and paints the PAGE
           background — any amount reserved beyond the bar's height is by
           construction never covered by the bar, and renders as an uncoloured band
           between the footer and the bar at the true page bottom (debug
           cta-bar-footer-gap-uncolored).

           If this boundary reads cramped, grow the FOOTER's own box instead:
           `body:has(.pk-about-cta-bar) .pk-footer { padding-bottom: ... }`. That
           space is painted with the footer's fill; this space is not.
           """

    assert String.starts_with?(value, "var(--pk-about-cta-bar-h"),
           """
           `body:has(.pk-about-cta-bar)`'s reservation is not driven by the
           live-measured bar height:

               padding-bottom: #{value};

           It must read `var(--pk-about-cta-bar-h, ...)`, published by
           `.AboutCtaBarMeasure`'s ResizeObserver (about_live.ex). A hard literal
           here has already drifted twice against the bar's real height (see the
           DRIFT HISTORY paragraph above the rule).
           """
  end

  test "the clearance fallback stays DERIVED from the bar's own declared parts" do
    value = clearance_value(source())

    # Boundary neighbour, guarding the OPPOSITE wrong fix: collapsing the
    # fallback to a single pre-added literal (`69px`) while removing the
    # additive term. That would pass the test above and silently discard plan
    # 01.5-10's "derive, don't restate" discipline, re-opening the drift the
    # `calc()` exists to prevent. The `+` signs INSIDE this fallback are
    # legitimate — they compose the bar's real parts, they do not pad the
    # reservation beyond it.
    assert value =~ ~r/calc\(\s*10px\s*\+\s*48px\s*\+\s*10px\s*\+\s*1px\s*\)/,
           """
           The `--pk-about-cta-bar-h` fallback is no longer composed from the bar's
           own declared parts:

               padding-bottom: #{value};

           Expected the pre-connect fallback to read
           `calc(10px + 48px + 10px + 1px)` — .pk-about-cta-bar's top padding +
           .pk-sumate-btn's min-height + its bottom padding + its border-top. If the
           bar's geometry changed, re-derive these operands; do not replace them
           with a pre-added number.
           """
  end

  test "assets/css/app.css declares exactly one body:has(.pk-about-cta-bar) rule" do
    matches = Regex.scan(~r/body:has\(\.pk-about-cta-bar\)\s*\{/, strip_comments(source()))

    assert length(matches) == 1,
           """
           Expected exactly one `body:has(.pk-about-cta-bar)` rule, found #{length(matches)}.

           A second rule can re-add reserved space that the first one no longer
           declares, reproducing the uncoloured band without ever touching the
           declaration this test's other assertions guard.
           """
  end

  test "the clearance rule is co-located with the bar's own display swap" do
    src = strip_comments(source())

    # Co-location is load-bearing, not tidiness: a threshold mismatch between
    # "bar appears" and "clearance is reserved" opens a width range where the
    # fixed bar covers the footer's "Powered by BGG" line with nothing reserved
    # for it (the T-QUICK-04 threat). Both must live in the SAME
    # `@media (max-width: 480px)` block, so no `@media` at-rule may appear
    # between them.
    display_swap = Regex.run(~r/(?m)^\s+\.pk-about-cta-bar\s*\{[^}]*display:\s*block/, src, return: :index)
    clearance = Regex.run(~r/(?m)^\s+body:has\(\.pk-about-cta-bar\)\s*\{/, src, return: :index)

    assert display_swap, "No indented `.pk-about-cta-bar { display: block }` rule found (the ≤480px display swap)."
    assert clearance, "No indented `body:has(.pk-about-cta-bar)` rule found (the ≤480px clearance)."

    [{swap_start, swap_len} | _] = display_swap
    [{clear_start, _} | _] = clearance

    assert swap_start < clear_start,
           "Expected the bar's display swap to precede the clearance rule in source order."

    between = String.slice(src, swap_start + swap_len, clear_start - (swap_start + swap_len))

    refute between =~ "@media",
           """
           An `@media` at-rule sits between `.pk-about-cta-bar`'s display swap and its
           document-end clearance, so the two are no longer in the same breakpoint block.

           A mismatch between "the bar appears" and "clearance is reserved" opens a
           width range where the fixed bar covers the footer's "Powered by BGG" line
           with no reserved space beneath it. Keep both in the same
           `@media (max-width: 480px)` block.
           """
  end
end
