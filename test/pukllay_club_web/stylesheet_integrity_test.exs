defmodule PukllayClubWeb.StylesheetIntegrityTest do
  # Guards assets/css/app.css against silent CSS parse errors — the class of
  # bug where the stylesheet still builds, the browser reports nothing, and a
  # rule is simply dropped from the cascade.
  #
  # Motivating incident (debug session search-expand-header-overlap): a prose
  # comment wrote the motion-token wildcard as `(--duration-*/`, whose trailing
  # `*` plus the following `/` formed a `*/` and closed the comment one line
  # early. The leftover prose then landed in CSS context, the parser swallowed
  # it plus the next selector as one invalid selector, and the entire
  # `.pk-search-morph` base rule was discarded — leaving the header's expandable
  # search with no display:flex, height, overflow or margin-left for months.
  # Nothing in the toolchain flagged it: LightningCSS passed the garbage through
  # verbatim and every browser silently applied CSS error recovery.
  use ExUnit.Case, async: true

  @css_path Path.expand("../../assets/css/app.css", __DIR__)

  defp source, do: File.read!(@css_path)

  defp line_of(src, index) do
    src |> binary_part(0, index) |> String.split("\n") |> length()
  end

  # Walks the file the way a CSS tokenizer does: every `/*` runs to the very
  # next `*/`, with no nesting. Returns {comment_ranges, unterminated_index}.
  defp scan_comments(src) do
    do_scan(src, 0, [])
  end

  defp do_scan(src, from, acc) do
    case :binary.match(src, "/*", scope: {from, byte_size(src) - from}) do
      :nomatch ->
        {Enum.reverse(acc), nil}

      {start, 2} ->
        rest_from = start + 2

        case :binary.match(src, "*/", scope: {rest_from, byte_size(src) - rest_from}) do
          :nomatch -> {Enum.reverse(acc), start}
          {stop, 2} -> do_scan(src, stop + 2, [{start, stop} | acc])
        end
    end
  end

  test "no comment is left unterminated" do
    src = source()
    {_comments, unterminated} = scan_comments(src)

    assert unterminated == nil,
           "Unterminated CSS comment opened at assets/css/app.css:#{unterminated && line_of(src, unterminated)}. " <>
             "Everything after it is swallowed as comment text and silently dropped from the cascade."
  end

  test "no comment closes prematurely on a token wildcard" do
    src = source()
    {comments, _} = scan_comments(src)

    # A legitimate close is preceded by whitespace (` */`). A close preceded by
    # an identifier character means the author wrote something like
    # `--duration-*/` or `.foo-*/` and accidentally terminated the comment.
    offenders =
      for {_start, stop} <- comments,
          stop > 0,
          preceding = binary_part(src, stop - 1, 1),
          preceding =~ ~r/[-A-Za-z0-9_]/ do
        {line_of(src, stop), String.trim(binary_part(src, max(stop - 45, 0), min(45, stop)))}
      end

    assert offenders == [],
           "CSS comment(s) closed by an accidental `*/` formed from a token wildcard:\n" <>
             Enum.map_join(offenders, "\n", fn {line, ctx} ->
               "  assets/css/app.css:#{line} — ...#{ctx}*/"
             end) <>
             "\nWrite the wildcard away from the slash (e.g. `--duration-* and --ease-*`). " <>
             "As written, the comment ends early and the next rule is discarded by the CSS parser."
  end

  test "the .pk-search-morph base rule survives into the built stylesheet" do
    # End-to-end assertion on the actual build output: the specific rule the
    # motivating incident silently deleted. Skipped when assets have not been
    # built (fresh clone / CI step ordering), since its absence then says
    # nothing about correctness.
    built = Path.expand("../../priv/static/assets/css/app.css", __DIR__)

    if File.exists?(built) do
      css = File.read!(built)

      assert [_ | _] = parts = String.split(css, ~r/\.pk-search-morph\s*\{/, parts: 2)
      [before_rule | _] = parts

      # The decisive check. In a healthy build the selector is preceded only by
      # the previous rule's closing brace; if the parser is instead about to
      # absorb stray text into the selector, that text shows up right here.
      # Matching on `}` (rather than merely on line-start) is what makes this
      # test fail on the real defect — the orphaned prose also began its own
      # line, so an anchor-based check passes straight through it.
      trailing = before_rule |> String.trim_trailing() |> String.slice(-1..-1)

      assert trailing == "}",
             "In priv/static/assets/css/app.css the .pk-search-morph selector is preceded by " <>
               "#{inspect(String.slice(String.trim_trailing(before_rule), -80..-1))} instead of a " <>
               "closing brace. Stray text before a selector makes the whole rule invalid and the " <>
               "CSS parser silently discards it."

      [_, block] = Regex.run(~r/\.pk-search-morph\s*\{([^}]*)\}/, css)

      # The four declarations whose loss produced each reported symptom:
      # stacked children, over-tall header row, bleed outside the pill, and a
      # search icon that floated beside the nav links instead of the row edge.
      for decl <- ["display: flex", "height: 44px", "overflow: hidden", "margin-left: auto"] do
        assert block =~ decl,
               "Expected `#{decl}` in the built .pk-search-morph rule; without it the header " <>
                 "search morph regresses to the stacked/misplaced layout."
      end
    end
  end

  # ── Reduced-motion guard ───────────────────────────────────────────────
  #
  # Motivating incident (debug session reduced-motion-order-bug): the
  # `prefers-reduced-motion: reduce` accommodation was written as a
  # hand-maintained list of 14 selectors sitting in the middle of app.css. It
  # was silently inert for 8 of them. A media query adds no specificity and
  # every rule in this file is unlayered, so source order decided the winner —
  # any selector whose own `transition:` shorthand appeared further down the
  # file re-expanded transition-duration back to full. Measured in Chrome under
  # --force-prefers-reduced-motion: a perfect split with zero exceptions, the 6
  # selectors above the block at 0.001s and the 8 below it at 0.18-0.28s.
  #
  # Oracle type: DERIVED (contract). The real proof is a browser reporting a
  # collapsed computed duration for every animated surface, which ExUnit cannot
  # observe. These assertions instead pin the two structural properties that
  # make the guard immune to the bug class, since losing either one reopens it
  # silently and with no visible diff in behaviour for a sighted developer who
  # does not have reduced motion enabled:
  #
  #   1. position-independence, carried by `!important`
  #   2. enumeration-independence, carried by the universal selector
  #
  # Every assertion runs against COMMENT-STRIPPED source. This is load-bearing,
  # not fastidiousness: the guard's own explanatory comment in app.css quotes
  # `!important`, `transition-duration` and `prefers-reduced-motion` at length,
  # so a naive substring grep would happily assert against the prose while the
  # actual rule was deleted.

  # Replaces every comment byte with a space, preserving both byte offsets and
  # newlines so line numbers stay accurate.
  defp blank_bytes(bin) do
    for <<b <- bin>>, into: "", do: <<if(b == ?\n, do: ?\n, else: ?\s)>>
  end

  defp stripped_source do
    src = source()
    {comments, _} = scan_comments(src)

    Enum.reduce(comments, src, fn {start, stop}, acc ->
      len = stop + 2 - start

      binary_part(acc, 0, start) <>
        blank_bytes(binary_part(acc, start, len)) <>
        binary_part(acc, stop + 2, byte_size(acc) - stop - 2)
    end)
  end

  # Returns the inner text of the block whose opening brace is at open_idx.
  defp block_body(src, open_idx), do: do_block(src, open_idx + 1, 1, open_idx + 1)

  defp do_block(src, i, depth, start) do
    case binary_part(src, i, 1) do
      "{" -> do_block(src, i + 1, depth + 1, start)
      "}" when depth == 1 -> binary_part(src, start, i - start)
      "}" -> do_block(src, i + 1, depth - 1, start)
      _ -> do_block(src, i + 1, depth, start)
    end
  end

  # Every `@media ... prefers-reduced-motion: reduce ... { }` block in the
  # stylesheet, as {line, selector_text, body}. Deliberately does NOT match
  # `no-preference` blocks, which are a different mechanism with the opposite
  # polarity and are asserted on by category_anchor_scroll_test.
  defp reduce_blocks do
    src = stripped_source()

    ~r/@media[^{}]*prefers-reduced-motion:\s*reduce[^{}]*\{/
    |> Regex.scan(src, return: :index)
    |> Enum.map(fn [{start, len}] ->
      body = block_body(src, start + len - 1)
      [selector | _] = String.split(body, "{", parts: 2)
      {line_of(src, start), String.trim(selector), body}
    end)
  end

  test "the reduced-motion guard exists and is the file's single source of truth" do
    blocks = reduce_blocks()

    assert length(blocks) == 1,
           "Expected exactly one `@media (prefers-reduced-motion: reduce)` block in " <>
             "assets/css/app.css, found #{length(blocks)} at line(s) " <>
             "#{inspect(Enum.map(blocks, &elem(&1, 0)))}. More than one means the accommodation " <>
             "has been split again, which is how it drifted out of coverage the first time; zero " <>
             "means visitors who asked for reduced motion get the full 0.18-0.28s animations."
  end

  test "the guard targets the universal selector, not a hand-maintained list" do
    [{line, selector, _body}] = reduce_blocks()

    assert selector =~ ~r/(^|,)\s*\*\s*(,|$)/,
           "The reduced-motion guard at assets/css/app.css:#{line} no longer targets `*`. Its " <>
             "selector is #{inspect(selector)}. An enumerated list only protects surfaces someone " <>
             "remembered to add to it — that is exactly the defect this rule replaced, where 8 of " <>
             "14 listed selectors were inert and any unlisted surface was never covered at all."

    refute selector =~ ".pk-",
           "The reduced-motion guard at assets/css/app.css:#{line} has grown per-surface " <>
             "selectors (#{inspect(selector)}). Surfaces must not be registered here one by one; " <>
             "the universal selector already covers every one of them, including rules added " <>
             "below this block."
  end

  test "the guard's declarations are !important, which is what makes it position-independent" do
    [{line, _selector, body}] = reduce_blocks()

    # Without !important the guard is just another normal declaration, so any
    # `transition:` shorthand appearing later in the file silently outranks it
    # by source order. That is the original bug, verbatim.
    for prop <- ["transition-duration", "animation-duration", "animation-iteration-count"] do
      assert body =~ ~r/#{prop}\s*:[^;]*!important/,
             "`#{prop}` in the reduced-motion guard at assets/css/app.css:#{line} is missing " <>
               "`!important`. Media queries contribute no specificity and this stylesheet is " <>
               "entirely unlayered, so without !important the guard loses to any `transition:` " <>
               "shorthand declared further down the file — silently, and only for visitors who " <>
               "have reduced motion enabled."
    end
  end

  test "the guard pins animation-iteration-count so infinite animations cannot spin at 1ms" do
    [{line, _selector, body}] = reduce_blocks()

    assert body =~ ~r/animation-iteration-count\s*:\s*1\s*!important/,
           "The reduced-motion guard at assets/css/app.css:#{line} must pin " <>
             "`animation-iteration-count: 1`. Collapsing an `infinite` animation's duration to " <>
             "1ms without also pinning the iteration count makes it repeat roughly a thousand " <>
             "times a second — strictly worse than the motion being suppressed. " <>
             ".pk-scroll-top's bounce is infinite."
  end

  test "durations collapse to 1ms rather than 0s so transitionend still fires" do
    [{line, _selector, body}] = reduce_blocks()

    for prop <- ["transition-duration", "animation-duration"] do
      assert body =~ ~r/#{prop}\s*:\s*1ms\s*!important/,
             "`#{prop}` in the reduced-motion guard at assets/css/app.css:#{line} should be " <>
               "exactly `1ms`. A zero-duration transition generates no transition at all, so " <>
               "`transitionend` never fires — no hook depends on that today, but 1ms is " <>
               "indistinguishable to a human and keeps the event contract intact."
    end
  end

  test "the reduced-motion guard survives into the built stylesheet" do
    # End-to-end check against real build output: the guard is only worth
    # anything if it reaches the browser. Skipped when assets have not been
    # built, since its absence then says nothing about correctness.
    built = Path.expand("../../priv/static/assets/css/app.css", __DIR__)

    if File.exists?(built) do
      css = File.read!(built)

      assert css =~ ~r/prefers-reduced-motion:\s*reduce/,
             "No reduced-motion guard in priv/static/assets/assets/app.css — the accommodation " <>
               "never reaches a visitor's browser. Rebuild assets, or check the guard was not " <>
               "dropped by a CSS parse error upstream of it."

      assert css =~ ~r/transition-duration:\s*1ms\s*!important/,
             "The built stylesheet has a reduced-motion block but no " <>
               "`transition-duration: 1ms !important`. The guard reached the build stripped of " <>
               "the property that makes it win the cascade."
    end
  end
end
