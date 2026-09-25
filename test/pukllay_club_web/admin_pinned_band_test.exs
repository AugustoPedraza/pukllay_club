defmodule PukllayClubWeb.AdminPinnedBandTest do
  # Plan 01.8.3-06 (G-01.8.3-2a): a browser-free tripwire on the pinned
  # caption-ink algebra in assets/css/admin/juegos.css. `test/visual/
  # admin_shell.mjs` proves the RENDERED pixels are right, but it needs a
  # booted dev server, a real staff session and a real browser — this test
  # binds the SOURCE-LEVEL invariants that make that rendering correct, so a
  # revert of the fix, a literalised --bandp, or a --pt dropped below its
  # floor all go red in `mix quality` with no browser at all.
  #
  # Follows admin_tokens_test.exs's file-read-and-assert convention: read the
  # real stylesheet off disk, strip comments first (copied verbatim — this
  # codebase's block comments have no leading `*` per continuation line, so a
  # line-anchored filter would miss them), and never trust a comment. This
  # plan's own defect shipped for a full round behind a comment that
  # described a rule that did not exist — a guard that reads comments could
  # never have caught it.
  use ExUnit.Case, async: true

  @juegos_css_path Path.expand("../../assets/css/admin/juegos.css", __DIR__)

  @base_header_selector ".pk-admin-juegos-section-header"
  @pinned_header_selector ".pk-admin-juegos-section-heading-wrap[data-pinned=\"true\"] .pk-admin-juegos-section-header"

  defp juegos_source, do: File.read!(@juegos_css_path)

  # Copied verbatim from admin_tokens_test.exs — see that file's own comment
  # for why a non-greedy, dot-matches-newline span strip is required here
  # instead of a line-anchored `^\s*\*` filter.
  defp strip_comments(src), do: Regex.replace(~r/\/\*.*?\*\//s, src, "")

  # Isolates a rule's declaration body by SELECTOR TEXT rather than by line
  # number (line numbers drift; selector text does not). The selector is
  # required to be followed immediately by `{` (allowing only whitespace in
  # between), so this never accidentally matches a longer selector that
  # merely ENDS with the same text (e.g. the `::before` pinned rule, or the
  # `--collapsible` variant) — `Regex.run` also returns the FIRST match in
  # the file, which is what lets `@base_header_selector` resolve to the base
  # rule rather than the later `:first-child` override, since the base rule
  # is declared first.
  defp rule_body(src, selector) do
    pattern = Regex.escape(selector) <> "\\s*\\{([^}]*)\\}"

    case Regex.run(~r/#{pattern}/s, src) do
      [_, body] -> body
      nil -> nil
    end
  end

  defp declared_value(block, token) do
    case Regex.run(~r/#{Regex.escape(token)}\s*:\s*([^;]+);/, block) do
      [_, raw] -> String.trim(raw)
      nil -> nil
    end
  end

  defp to_float(str) do
    str = if String.contains?(str, "."), do: str, else: str <> ".0"
    String.to_float(str)
  end

  defp numeric_value(src, token) do
    [_, raw] = Regex.run(~r/#{Regex.escape(token)}\s*:\s*([\d.]+)px\s*;/, src)
    to_float(raw)
  end

  # Resolves what `--bandp` ACTUALLY evaluates to, by reading its declared
  # calc() out of the stylesheet and doing the arithmetic — never by
  # recomputing the intended formula in Elixir.
  #
  # This distinction is the whole point (CR-02, 01.8.3-REVIEW.md). An earlier
  # version of this file derived `bandp` as `(44.0 - cap_box) / 2` on the
  # Elixir side and then asserted `cap_box + 2 * bandp == 44`, which is
  # algebraically true for every input and therefore could not fail. It was
  # proven blind by mutating the stylesheet's own divisor from `/ 2` to
  # `/ 3` — a real 35.4px band instead of the required 44px, the same class
  # of defect as the shipped 32.2px/44.2px bug — with every assertion in
  # this file still green. Reading the declared expression is what makes the
  # band-height and `--pt` floor tests below falsifiable.
  #
  # Only the canonical shape `calc((<target>px - var(--cap-box)) / <divisor>)`
  # is accepted. A restructured or literalised `--bandp` fails here rather
  # than being silently approximated — an unparseable derivation is itself
  # the signal, since this guard exists to pin that derivation in source.
  defp declared_bandp_px(src) do
    body = rule_body(src, @base_header_selector)
    raw = body && declared_value(body, "--bandp")

    assert raw,
           "Expected a `--bandp` declaration in `#{@base_header_selector}`, found none."

    pattern = ~r/^calc\(\s*\(\s*([\d.]+)px\s*-\s*var\(\s*--cap-box\s*\)\s*\)\s*\/\s*([\d.]+)\s*\)$/

    case Regex.run(pattern, String.trim(raw)) do
      [_, target, divisor] ->
        d = to_float(divisor)

        assert d != 0.0,
               "`--bandp`'s calc() divides by zero: `#{raw}`."

        (to_float(target) - numeric_value(src, "--cap-box")) / d

      nil ->
        flunk("""
        `--bandp` is declared as `#{raw}`, which does not match the canonical
        derivation `calc((<target>px - var(--cap-box)) / 2)`.

        The pinned band's height invariant (D-15, 01.8.3-05) requires --bandp to
        be HALF the leftover air once the caption box is removed from the 44px
        target, derived from --cap-box rather than measured or hard-coded. If
        this derivation genuinely needs a new shape, update this parser in the
        same edit — do not loosen it to a substring match, which is exactly the
        blindness CR-02 recorded.
        """)
    end
  end

  test "the pinned header rule declares padding-top and padding-bottom, both referencing --bandp" do
    body = juegos_source() |> strip_comments() |> rule_body(@pinned_header_selector)

    assert body,
           "No `#{@pinned_header_selector}` rule found in assets/css/admin/juegos.css — " <>
             "the pinned padding override this plan adds must exist as its own rule, " <>
             "separate from the `::before` band rule."

    padding_top = declared_value(body, "padding-top")
    padding_bottom = declared_value(body, "padding-bottom")

    assert padding_top,
           "Expected a `padding-top` declaration in `#{@pinned_header_selector}`, found none."

    assert padding_bottom,
           "Expected a `padding-bottom` declaration in `#{@pinned_header_selector}`, found none."

    assert padding_top =~ "--bandp",
           "Expected `padding-top` (#{padding_top}) to reference `--bandp` — the pinned ink " <>
             "position must be derived from the same custom property the band's own height is."

    assert padding_bottom =~ "--bandp",
           "Expected `padding-bottom` (#{padding_bottom}) to reference `--bandp` — the " <>
             "compensating padding must be derived from the same property, not a literal."
  end

  test "--bandp is declared as a calc() derived from --cap-box and the 44px target, not a literal" do
    body = juegos_source() |> strip_comments() |> rule_body(@base_header_selector)

    assert body,
           "No `#{@base_header_selector}` base rule found in assets/css/admin/juegos.css."

    bandp_raw = declared_value(body, "--bandp")

    assert bandp_raw,
           "Expected a `--bandp` declaration in `#{@base_header_selector}`, found none."

    assert bandp_raw =~ "calc(",
           "Expected `--bandp` to be a calc() expression, got `#{bandp_raw}` — a hard-coded " <>
             "length here is the exact fixture-constant defect RESEARCH.md warned about " <>
             "(a value measured against a different fixture's own dimensions)."

    assert bandp_raw =~ "--cap-box",
           "Expected `--bandp`'s calc() to reference `--cap-box`, got `#{bandp_raw}`."

    assert bandp_raw =~ "44px",
           "Expected `--bandp`'s calc() to reference the 44px pinned-band target, got `#{bandp_raw}`."
  end

  test "every declared --pt clears --bandp + --cap, so the pinned padding-bottom never resolves negative" do
    src = strip_comments(juegos_source())

    cap_box = numeric_value(src, "--cap-box")
    cap = numeric_value(src, "--cap")
    # The DECLARED --bandp, not a recomputed one — a wrong derivation must move
    # this floor, or the floor check is blind in the same way CR-02 recorded.
    bandp = declared_bandp_px(src)
    floor = bandp + cap

    pts =
      ~r/--pt\s*:\s*([\d.]+)px\s*;/
      |> Regex.scan(src)
      |> Enum.map(fn [_, raw] -> to_float(raw) end)

    assert length(pts) >= 2,
           "Expected at least 2 declared `--pt` values (the base rule plus the `:first-child` " <>
             "override) in assets/css/admin/juegos.css, found #{length(pts)}."

    for pt <- pts do
      assert pt >= floor - 0.001,
             "Found `--pt: #{pt}px` in assets/css/admin/juegos.css, below the required floor " <>
               "of `--bandp + --cap` (#{Float.round(floor, 2)}px, derived from --cap-box=" <>
               "#{cap_box}px and --cap=#{cap}px). Below this floor the pinned rule's " <>
               "`padding-bottom` resolves negative and the declaration is dropped entirely, " <>
               "silently reverting the header's pinned box height."
    end
  end

  test "the band-height algebra closes: --cap-box + 2 * --bandp equals 44" do
    src = strip_comments(juegos_source())

    cap_box = numeric_value(src, "--cap-box")
    # Evaluated from the stylesheet's own declared calc() — see
    # declared_bandp_px/1's comment for why recomputing it here made this
    # assertion a tautology that could not fail (CR-02).
    bandp = declared_bandp_px(src)

    assert_in_delta cap_box + 2 * bandp,
                    44.0,
                    0.05,
                    "--cap-box (#{cap_box}px) + 2 * --bandp (#{bandp}px, as DECLARED in " <>
                      "juegos.css) does not resolve to 44px — the pinned band's own height " <>
                      "invariant (D-15, 01.8.3-05) no longer holds."
  end
end
