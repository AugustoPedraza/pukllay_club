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
end
