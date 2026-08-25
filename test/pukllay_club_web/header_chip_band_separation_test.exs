defmodule PukllayClubWeb.HeaderChipBandSeparationTest do
  # Guards the boundary between the two full-bleed bands stacked flush inside the
  # sticky `#app-header` on mobile: the header bar (`.pk-nav`) and the category
  # chip index row (`.pk-chip-nav-wrap`).
  #
  # Motivating incident (debug search-right-align-mobile, cycle 2). quick task
  # 260824-jkc Task 2 introduced `.pk-chip-nav-wrap` and gave it
  # `background: var(--color-base-200)` — the token `.pk-nav` already uses. Both
  # bands are full-bleed, both are opaque (they must be: the stack is sticky, so
  # content scrolls beneath them), and they abut with no gap. With identical
  # fills the entire boundary fell to the wrap's `border-top: 1px solid
  # var(--color-base-300)`.
  #
  # Measured from a real 390px headless-Chrome screenshot, pixel column x=178
  # (a clean gap between two chips):
  #
  #     light   y=  0..63  #F3ECFA   <- .pk-nav
  #             y= 64      #E3D3F0   <- the whole boundary, 1px, 1.226:1
  #             y= 65..108 #F3ECFA   <- .pk-chip-nav-wrap, IDENTICAL fill
  #             y=109..    #FFFFFF   <- page
  #     dark    same shape: #22103A / #2F1750 / #22103A, hairline 1.130:1
  #
  # 1.226:1 is ~2.5x under the 3:1 non-text-contrast floor, so the 64px header
  # row and the 45px chip row rendered as one continuous 109px block — the
  # reported "the chip row is merged with the header".
  #
  # The fix is a FILL STEP, not a stronger line, because arithmetic rules the
  # line out: no pair of this app's surface tokens clears 3:1 in either theme
  # (base-200/300 1.226:1 light / 1.130:1 dark; base-200/100 1.415:1 / 1.086:1;
  # even the existing 8% base-content scroll shadow computes to 1.170:1). The
  # chip band therefore sits on the PAGE surface (base-100), which is also what
  # it semantically is — a page-level index, not header chrome.
  #
  # This is the general rule the theme block's own MEASURED CONSTRAINTS comment
  # already states (app.css, light/dark theme header): two sub-3:1 colours must
  # NEVER be adjacent surfaces or two levels of one hierarchy. No gate encoded
  # it. This suite is that gate, narrowed to the one place it was violated.
  #
  # Cycle 4 (a SECOND, independent defect at the same boundary — the fill step
  # above was necessary but not sufficient, and a human rejected it on a real
  # device). The band also had NO VERTICAL PADDING: measured at 390px the wrap
  # was y=64..109 and its 44px chips were y=65..109, so the pills filled the
  # band edge to edge, touching the header's 1px rule above and the line where
  # page content scrolls under below. Zero whitespace anywhere in the 109px
  # block. At 0px proximity no fill step this app's tokens can produce (the
  # whole ladder tops out at 1.415:1 light / 1.086:1 dark) separates two bands —
  # which is why the colour-only fix could not land, and why whitespace can: it
  # is not bounded by the token ladder.
  #
  # That flush band was a PORT REGRESSION, not a design choice. Sketch 020's
  # `.index-row` — the direct source of `.pk-chip-nav` — declares
  # `padding: var(--space-2) var(--space-4)` (8px vertical). 260824-jkc
  # correctly replaced the HORIZONTAL half with `.pk-chip-spacer` flex items
  # (the documented iOS Safari trailing-padding clip) but dropped the vertical
  # half with it, which that fix never required — the iOS clip only affects the
  # scroll axis. It left the chip row as the only horizontal scroller in the
  # file with no vertical padding; `.pk-rail` carries `padding: 8px 0`.
  #
  # Oracle type: derived (contract). The real proof is rendered pixels, which
  # ExUnit cannot observe; these assertions pin the source-level property those
  # pixels are a function of. Two assertions were verified RED against the
  # stylesheet that actually shipped each defect — the surface-token one (cycle
  # 2) and the vertical-padding one (cycle 4). The rest were green before and
  # after by construction (pre-fix the band and its fades were consistently
  # base-200, and the band was already opaque) and exist to stop the fix being
  # undone from the other side: by moving the band's fill without moving its
  # fades, or by "separating" the bands with transparency, which would reinstate
  # the content bleed-through that predates 260824-jkc.
  use ExUnit.Case, async: true

  @css_path Path.expand("../../assets/css/app.css", __DIR__)

  defp source, do: File.read!(@css_path)

  # Comments are prose, not cascade — and the rule under test carries a long
  # explanatory comment that names every token these assertions look for, so
  # stripping is mandatory here rather than merely tidy.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  # Every top-level block whose selector list STARTS a line with this exact
  # selector. Plural because the fade pseudo-elements are declared twice: once
  # in a shared `::before, ::after` block (geometry) and once individually
  # (each one's edge + gradient). Anchoring alone would silently return the
  # shared geometry block for `::after` — which contains no gradient — and read
  # as "the gradient is gone" rather than "you matched the wrong block".
  defp blocks(src, selector) do
    src
    |> strip_comments()
    |> then(&Regex.scan(Regex.compile!("(?m)^#{Regex.escape(selector)}\\s*\\{([^}]*)\\}"), &1))
    |> Enum.map(fn [_, body] -> body end)
  end

  defp block!(src, selector) do
    case blocks(src, selector) do
      [body | _] -> body
      [] -> flunk("No top-level rule found for `#{selector}` in assets/css/app.css")
    end
  end

  # The `--color-*` token a rule paints its surface with, e.g. "base-200".
  defp surface_token!(src, selector) do
    body = block!(src, selector)

    case Regex.run(~r/(?m)^\s*background:\s*var\(--color-([a-z0-9-]+)\)\s*;/, body) do
      [_, token] ->
        token

      nil ->
        flunk(
          "`#{selector}` does not declare `background: var(--color-...)`. Every surface in this " <>
            "layer resolves its colour through a theme token — never a literal hex/rgb — so both " <>
            "themes render it correctly. Found instead:\n#{String.trim(body)}"
        )
    end
  end

  # Longest-match-wins so `.pk-chip-nav-wrap` never resolves through
  # `.pk-chip-nav`'s block, and longhands beat the shorthand regardless of the
  # order they appear in — the same way the cascade resolves them.
  defp vertical_padding_px!(src, selector) do
    body = block!(src, selector)

    shorthand =
      case Regex.run(~r/(?m)^\s*padding:\s*([^;]+);/, body) do
        [_, value] -> value |> String.split(~r/\s+/, trim: true) |> Enum.map(&length_px!/1)
        nil -> nil
      end

    {top, bottom} =
      case shorthand do
        [all] -> {all, all}
        [v, _h] -> {v, v}
        [t, _h, b] -> {t, b}
        [t, _r, b, _l] -> {t, b}
        _ -> {0, 0}
      end

    {longhand!(body, "padding-top", top), longhand!(body, "padding-bottom", bottom)}
  end

  defp longhand!(body, prop, fallback) do
    case Regex.run(~r/(?m)^\s*#{prop}:\s*([^;]+);/, body) do
      [_, value] -> length_px!(String.trim(value))
      nil -> fallback
    end
  end

  defp length_px!(value) do
    case Regex.run(~r/^(-?[\d.]+)(px|rem|em)?$/, String.trim(value)) do
      [_, n, unit] when unit in ["rem", "em"] -> String.to_float(pad_float(n)) * 16
      [_, n, _] -> String.to_float(pad_float(n))
      [_, n] -> String.to_float(pad_float(n))
      nil -> 0.0
    end
  end

  defp pad_float(n), do: if(String.contains?(n, "."), do: n, else: n <> ".0")

  # The sketch's own value, and the value `.pk-rail` — this app's other
  # horizontal scroller — already ships. Anything below it is not a considered
  # choice, it is the regression.
  @min_band_padding_px 8

  describe "the header bar and the chip index row are two distinguishable bands" do
    test "the chip band does not reuse the header bar's surface token" do
      src = source()
      nav = surface_token!(src, ".pk-nav")
      wrap = surface_token!(src, ".pk-chip-nav-wrap")

      refute wrap == nav,
             "`.pk-nav` and `.pk-chip-nav-wrap` both paint `var(--color-#{nav})`. These are two " <>
               "full-bleed opaque bands stacked flush inside the same sticky `#app-header`, so " <>
               "identical fills leave the entire boundary to the wrap's 1px base-300 " <>
               "`border-top` — measured 1.226:1 in light and 1.130:1 in dark, ~2.5x under the " <>
               "3:1 non-text floor. At 390px the 64px header row and the 45px chip row then " <>
               "render as one continuous 109px block (pixel scan: y=0..63 #F3ECFA, y=64 " <>
               "#E3D3F0, y=65..108 #F3ECFA). That is the shape the theme block's MEASURED " <>
               "CONSTRAINTS comment forbids: never two sub-3:1 colours as adjacent surfaces or " <>
               "as two levels of one hierarchy. A stronger hairline cannot rescue it — no pair " <>
               "of this app's surface tokens clears 3:1 in either theme. The boundary has to be " <>
               "a fill step, so the chip band belongs on the PAGE surface (base-100), not the " <>
               "header's."
    end

    test "both edge fades dissolve from the chip band's own fill" do
      src = source()
      wrap = surface_token!(src, ".pk-chip-nav-wrap")

      for pseudo <- ["::before", "::after"] do
        fade =
          src
          |> blocks(".pk-chip-nav-wrap" <> pseudo)
          |> Enum.find_value(fn body ->
            case Regex.run(~r/linear-gradient\(\s*\d+deg\s*,\s*var\(--color-([a-z0-9-]+)\)/, body) do
              [_, token] -> token
              nil -> nil
            end
          end)

        assert fade,
               "No `.pk-chip-nav-wrap#{pseudo}` rule fades from a `var(--color-...)` token. The " <>
                 "chip row's scroll affordance is that fade — the same mechanism `.pk-rail-wrap` " <>
                 "uses — and it must resolve through a theme token so both themes render it."

        assert fade == wrap,
               "`.pk-chip-nav-wrap#{pseudo}` fades from `var(--color-#{fade})` but the band it " <>
                 "sits on is painted `var(--color-#{wrap})`. A fade is the band's own surface " <>
                 "dissolving to transparent — mismatch it and each end of the scrolling chip row " <>
                 "renders a coloured smudge instead of a fade. These two values are one " <>
                 "decision: whenever the band's fill moves, both fades move with it."
      end
    end

    test "the chip band reserves real vertical whitespace around its chips" do
      {top, bottom} = vertical_padding_px!(source(), ".pk-chip-nav-wrap")

      for {edge, value, neighbour} <- [
            {"top", top, "the header bar's 1px rule"},
            {"bottom", bottom, "the line where page content scrolls under the sticky band"}
          ] do
        assert value >= @min_band_padding_px,
               "`.pk-chip-nav-wrap` reserves #{value}px of padding-#{edge}, under the " <>
                 "#{@min_band_padding_px}px floor. Its chips are a 44px touch target, so with " <>
                 "no padding the band is exactly 44px + 1px border and the pills touch " <>
                 "#{neighbour} — measured at 390px pre-fix: band y=64..109, chips y=65..109, " <>
                 "zero whitespace in the whole 109px header block. That flush band is what a " <>
                 "human rejected on a real device AFTER the surface-token fix above had landed, " <>
                 "and it is why that fix alone could not work: at 0px proximity no fill step " <>
                 "this app's tokens can produce separates two bands (the ladder tops out at " <>
                 "1.415:1 light / 1.086:1 dark). Whitespace is the one separator NOT bounded by " <>
                 "the token ladder. The floor is sketch 020's own `.index-row` value " <>
                 "(`var(--space-2)` = 8px), which `.pk-rail` also ships as `padding: 8px 0` — " <>
                 "260824-jkc dropped it while correctly replacing the HORIZONTAL padding with " <>
                 "`.pk-chip-spacer` flex items, a swap the iOS Safari clip only ever required " <>
                 "on the scroll axis."
      end
    end

    test "the chips' 44px touch target is not what pays for that whitespace" do
      body = block!(source(), ".pk-chip")

      min_height =
        case Regex.run(~r/(?m)^\s*min-height:\s*([^;]+);/, body) do
          [_, value] -> length_px!(String.trim(value))
          nil -> flunk("`.pk-chip` declares no `min-height`; the 44px touch target is unpinned.")
        end

      assert min_height >= 44,
             "`.pk-chip` is #{min_height}px tall, under the 44px hit-target minimum this layer " <>
               "requires. Padding the band grew the sticky header (109px -> 133px at <=480px), " <>
               "so the tempting way to claw that back is to shrink the chips. That trades a " <>
               "spacing bug for an accessibility one: the whitespace has to come from the band, " <>
               "never from the target. Cycle 5 removed the incentive rather than the rule — the " <>
               "band is in normal page flow now (`#app-subnav`), so those pixels scroll away " <>
               "instead of being permanently charged to the viewport, and there is nothing left " <>
               "to reclaim. The floor stands regardless of what the band costs."
    end

    test "the chip band declares its own opaque surface, which its fades dissolve from" do
      body = block!(source(), ".pk-chip-nav-wrap")

      refute Regex.match?(~r/(?m)^\s*background:\s*(transparent|none)\s*;/, body),
             "`.pk-chip-nav-wrap` must declare an opaque surface, never `transparent`. The " <>
               "original reason was occlusion — the band lived inside the `position: sticky` " <>
               "`#app-header` and page content scrolled underneath it, so transparency let that " <>
               "content bleed through the chip row (the state before quick task 260824-jkc). " <>
               "Cycle 5 moved the band out to `#app-subnav` and it no longer occludes anything, " <>
               "so that specific argument has retired — but the assertion has not, for a second " <>
               "reason that was always true and is now the load-bearing one: the two edge fades " <>
               "are `linear-gradient(..., var(--color-...), transparent)`, i.e. THIS BAND'S OWN " <>
               "fill dissolving to nothing. A transparent band leaves them fading from a colour " <>
               "the band does not actually paint, so they render correctly only for as long as " <>
               "whatever shows through happens to match — and turn into a coloured smudge at " <>
               "each end of the row the moment it doesn't. Separating this band from the header " <>
               "is done by changing WHICH opaque surface it paints, never by removing the " <>
               "surface."
    end
  end
end
