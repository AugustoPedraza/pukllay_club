defmodule PukllayClubWeb.AdminWebRailCssTest do
  # Plan 01.8.4-04: a browser-free gate on the Web rail's stylesheet source.
  #
  # Three properties of the /admin/secciones rail are invisible to every
  # LiveView test: the slot's 20px-plus-12px geometry (the 44px pitch, the
  # absent rail `gap`), the empty-rail tile, and the landing animation's exact
  # duration, curve and reduced-motion gate. `test/visual/admin_components.mjs`
  # measures the RENDERED hit box in a real browser; this file binds the
  # SOURCE-LEVEL declarations that rendering is a function of, so a revert
  # goes red in `mix quality` with no browser at all.
  #
  # Idiom lifted from admin_pinned_band_test.exs: read the real stylesheet off
  # disk, strip comments first, and never trust a comment. Its CR-02 lesson
  # applies in full - a gate that recomputes the intended arithmetic in Elixir
  # is algebraically true for every input and cannot fail. So the 44px test
  # below READS the flex basis and the margin out of the stylesheet and does
  # arithmetic on what it read.
  #
  # Oracle type: derived (contract). The true oracle for the hit box is
  # `elementFromPoint` in a real browser; these assertions pin the
  # declarations it is a function of.
  use ExUnit.Case, async: true

  @screens_path Path.expand("../../assets/css/admin/screens.css", __DIR__)
  @estantes_path Path.expand("../../assets/css/admin/estantes.css", __DIR__)

  @rail ".pk-admin-web-rail"
  @rail_empty ".pk-admin-web-rail--empty"
  @slot ".pk-admin-web-slot"
  @landed_selector ".pk-admin-web-box--landed .pk-admin-web-cover__art"
  @no_preference "@media (prefers-reduced-motion: no-preference)"

  defp screens, do: @screens_path |> File.read!() |> strip_comments()
  defp estantes, do: @estantes_path |> File.read!() |> strip_comments()

  # Copied from admin_pinned_band_test.exs: a non-greedy, dot-matches-newline
  # span strip, because this codebase's block comments have no leading `*` per
  # continuation line and a line-anchored filter would miss them.
  defp strip_comments(src), do: Regex.replace(~r/\/\*.*?\*\//s, src, "")

  # Isolates a rule's declaration body by SELECTOR TEXT, not by line number.
  #
  # The selector is anchored at a CLASS-NAME BOUNDARY: a `(?<![\w-])`
  # lookbehind and a `(?![\w-])` lookahead, so `.pk-admin-web-rail` can never
  # be satisfied by `.pk-admin-web-rail--empty` or `.pk-admin-web-rail__hint`,
  # which it is a strict prefix of. admin_pinned_band_test.exs's own helper
  # guards only the SUFFIX case and leans on source order for the prefix case;
  # that is exactly the dependence this file must not have. It is this
  # anchoring, and NOT which rule is declared first, that makes
  # `rule_body(src, ".pk-admin-web-rail")` resolve to the base rule: a gate
  # whose correctness depends on declaration order silently stops testing what
  # it claims the moment someone reorders the stylesheet.
  #
  # A class boundary alone still lets `.pk-admin-web-slot` match inside the
  # DESCENDANT selector `.pk-admin-web-rail--empty .pk-admin-web-slot { ... }`
  # (a space is not a name character). So a match is also required to begin a
  # rule: whatever precedes it must be the start of the file or a `{` / `}`.
  defp rule_body(src, selector) do
    pattern = "(?<![\\w-])" <> Regex.escape(selector) <> "(?![\\w-])\\s*\\{([^}]*)\\}"

    ~r/#{pattern}/s
    |> Regex.scan(src, return: :index)
    |> Enum.find_value(fn [{start, _len}, {body_start, body_len}] ->
      if begins_a_rule?(src, start), do: binary_part(src, body_start, body_len)
    end)
  end

  defp begins_a_rule?(src, start) do
    case src |> binary_part(0, start) |> String.trim_trailing() do
      "" -> true
      before -> String.ends_with?(before, ["{", "}"])
    end
  end

  # A rule body, or a flunk naming the selector that was not found - so a
  # missing rule reads as "missing", not as a MatchError.
  defp rule_body!(src, selector) do
    rule_body(src, selector) ||
      flunk("No `#{selector}` rule found in assets/css/admin/screens.css (comment-stripped source).")
  end

  defp declared_value(block, token) do
    case Regex.run(~r/(?<![-\w])#{Regex.escape(token)}\s*:\s*([^;]+);/, block) do
      [_, raw] -> String.trim(raw)
      nil -> nil
    end
  end

  defp declared_value!(block, token, selector) do
    declared_value(block, token) || flunk("Expected a `#{token}` declaration in `#{selector}`, found none.")
  end

  # "20px" -> 20.0, "-12px" -> -12.0, "0" -> 0.0. Anything else is a flunk: an
  # unparseable length is itself the signal, not something to approximate.
  defp px!(raw) do
    case Float.parse(raw) do
      {number, "px"} -> number
      {number, ""} when number == 0.0 -> 0.0
      _other -> flunk("Expected a pixel length, got `#{raw}`.")
    end
  end

  # The horizontal component of a CSS box shorthand (margin, padding, inset's
  # left/right): one value applies to all sides, two or three put the
  # horizontal value second, four put right second and left fourth (and the
  # two must agree here, since the gate treats the box as symmetric).
  defp horizontal!(shorthand) do
    case String.split(shorthand) do
      [all] ->
        px!(all)

      [_vertical, horizontal | rest] when length(rest) <= 1 ->
        px!(horizontal)

      [_top, right, _bottom, left] ->
        assert px!(right) == px!(left), "`#{shorthand}` is not horizontally symmetric."
        px!(right)

      _other ->
        flunk("Cannot read a horizontal length out of `#{shorthand}`.")
    end
  end

  # The flex-basis component of a `flex: <grow> <shrink> <basis>` shorthand.
  defp flex_basis!(shorthand) do
    case String.split(shorthand) do
      [_grow, _shrink, basis] -> px!(basis)
      _other -> flunk("Expected `flex: <grow> <shrink> <basis>`, got `#{shorthand}`.")
    end
  end

  # Brace-matched extraction of an at-rule's body. A regex with `[^}]*` would
  # stop at the first inner `}`; this walks the nesting. Returns nil when the
  # at-rule is absent.
  defp at_rule_body(src, prelude) do
    case :binary.match(src, prelude) do
      {at, len} ->
        rest = binary_part(src, at + len, byte_size(src) - at - len)
        open = :binary.match(rest, "{")
        open && take_balanced(rest, elem(open, 0))

      :nomatch ->
        nil
    end
  end

  defp take_balanced(rest, open_at) do
    inner = binary_part(rest, open_at + 1, byte_size(rest) - open_at - 1)
    close_at = closing_brace(inner, 0, 1)
    close_at && binary_part(inner, 0, close_at)
  end

  defp closing_brace(<<>>, _at, _depth), do: nil
  defp closing_brace(<<"}", _rest::binary>>, at, 1), do: at
  defp closing_brace(<<"}", rest::binary>>, at, depth), do: closing_brace(rest, at + 1, depth - 1)
  defp closing_brace(<<"{", rest::binary>>, at, depth), do: closing_brace(rest, at + 1, depth + 1)
  defp closing_brace(<<_byte, rest::binary>>, at, depth), do: closing_brace(rest, at + 1, depth)

  describe "the rail declares no gap; the slot carries the spacing (RAIL-01 precision)" do
    test "the base rail rule declares no gap of any kind, and is not the --empty rule" do
      src = screens()
      base = rule_body!(src, @rail)
      empty = rule_body!(src, @rail_empty)

      refute Regex.match?(~r/(?<![-\w])(?:row-|column-)?gap\s*:/, base),
             "The base `#{@rail}` rule declares a gap. The 44px pitch comes only from the slot's " <>
               "column plus its margins; a rail gap would add to it."

      assert declared_value(empty, "gap") == "12px",
             "`#{@rail_empty}` must declare `gap: 12px` - the split is pinned, not a ban on gap in the family."

      # If the anchoring ever regresses, both lookups collapse onto one rule and
      # this is the assertion that says so out loud.
      refute base == empty, "rule_body/2 resolved `#{@rail}` and `#{@rail_empty}` to the same rule."
    end

    test "rule_body/2 does not resolve a descendant selector's rule as the slot's own" do
      src = screens()

      assert rule_body!(src, @slot) =~ "flex: 0 0 20px",
             "`#{@slot}` resolved to a rule other than its own (the empty-tile descendant rule?)."
    end
  end

  describe "the 44px horizontal hit box, derived from what is declared (RAIL-01 adjacency)" do
    test "the slot's flex basis plus twice its horizontal margin is 44px" do
      body = rule_body!(screens(), @slot)

      basis = body |> declared_value!("flex", @slot) |> flex_basis!()
      margin = body |> declared_value!("margin", @slot) |> horizontal!()

      assert basis + 2 * margin == 44.0,
             "The slot declares a #{basis}px column with #{margin}px of margin either side: " <>
               "#{basis + 2 * margin}px between covers, expected 44px."
    end

    test "the bleeding hit layer is as wide as the margin it reaches across" do
      src = screens()
      margin = src |> rule_body!(@slot) |> declared_value!("margin", @slot) |> horizontal!()
      inset = src |> rule_body!(@slot <> "::before") |> declared_value!("inset", @slot <> "::before")

      assert inset == "0 -12px", "`#{@slot}::before` must declare `inset: 0 -12px`, found `inset: #{inset}`."

      assert abs(horizontal!(inset)) == margin,
             "The hit layer (#{inset}) and the slot margin (#{margin}px) drifted apart."
    end

    test "the end slots reclaim the rail's own horizontal padding" do
      src = screens()
      padding = src |> rule_body!(@rail) |> declared_value!("padding", @rail) |> horizontal!()

      assert src |> rule_body!(@slot <> ":first-child") |> declared_value!("margin-left", "first-child") == "0"
      assert src |> rule_body!(@slot <> ":last-child") |> declared_value!("margin-right", "last-child") == "0"

      left = src |> rule_body!(@slot <> ":first-child::before") |> declared_value!("left", "first-child::before")
      right = src |> rule_body!(@slot <> ":last-child::before") |> declared_value!("right", "last-child::before")

      assert px!(left) == -padding, "The first slot's hit layer reaches #{left}, the rail pads #{padding}px."
      assert px!(right) == -padding, "The last slot's hit layer reaches #{right}, the rail pads #{padding}px."
    end

    test "the slot may not shrink its column below the glyph, or the pitch silently grows to 48px" do
      # The "+" circle is 24px inside a 20px column. Without `min-width: 0` a
      # flex item's automatic minimum widens the slot to the glyph, and the
      # source above still says 20px. Found by the rendered probe, not by the
      # declarations the tests above read.
      body = rule_body!(screens(), @slot)

      assert declared_value(body, "min-width") in ["0", "0px"],
             "`#{@slot}` must declare `min-width: 0` so its 20px column is really 20px."
    end
  end

  describe "the box, its caption and the empty tile" do
    test "the cover box is 96px wide and its caption is 12px with a 31px floor" do
      src = screens()
      box = rule_body!(src, ".pk-admin-web-box")
      caption = rule_body!(src, ".pk-admin-web-box__caption")

      assert box |> declared_value!("flex", ".pk-admin-web-box") |> flex_basis!() == 96.0
      assert declared_value(box, "width") == "96px"
      assert declared_value(caption, "font-size") == "12px"
      assert declared_value(caption, "min-height") == "31px"
    end

    test "the empty rail's slot is a 96 by 100 dashed tile" do
      selector = @rail_empty <> " " <> @slot
      body = rule_body!(screens(), selector)

      assert body |> declared_value!("flex", selector) |> flex_basis!() == 96.0
      assert declared_value(body, "height") == "100px"
      assert declared_value(body, "border") =~ "dashed"
    end
  end

  describe "the landing animation (RAIL-06)" do
    test "the landed cover animates for 520ms on the sketch's curve" do
      body = rule_body!(screens(), @landed_selector)
      animation = declared_value!(body, "animation", @landed_selector)

      assert animation =~ "pk-admin-web-land"
      assert animation =~ "520ms"
      assert animation =~ "cubic-bezier(0.2, 0.8, 0.3, 1)"
    end

    test "the keyframes and the landed rule both sit inside the no-preference media block" do
      src = screens()
      block = at_rule_body(src, @no_preference)

      assert block, "No `#{@no_preference}` block found in screens.css."
      assert block =~ "@keyframes pk-admin-web-land", "The landing keyframes are not inside the no-preference block."
      assert rule_body(block, @landed_selector), "The landed rule is not inside the no-preference block."

      # Containment is structural: take the block OUT of the source and the
      # trigger and the keyframes must be gone with it. Asserting that both
      # strings merely exist somewhere in the file would pass for a rule that
      # sits outside the gate.
      outside = String.replace(src, block, "")
      refute outside =~ "@keyframes pk-admin-web-land", "The keyframes also appear outside the no-preference block."
      refute rule_body(outside, @landed_selector), "The landed rule also appears outside the no-preference block."
    end

    test "the motion is gated on the trigger, not undone by a per-selector reduce override" do
      refute screens() =~ "prefers-reduced-motion: reduce"
    end

    test "the two screens' landing durations stay separate" do
      assert screens() =~ "520ms"
      refute screens() =~ "620ms", "screens.css picked up the longer landing duration that belongs to estantes.css."
      assert estantes() =~ "620ms", "estantes.css lost its own landing duration."
    end
  end

  describe "the dim rule at the featured cap (RAIL-04's CSS half)" do
    test "a full slot's plus dims, and nothing makes the control inert" do
      selector = @slot <> "--full .pk-admin-web-slot__plus"
      body = rule_body!(screens(), selector)

      {opacity, ""} = body |> declared_value!("opacity", selector) |> Float.parse()

      assert opacity < 1.0
      assert declared_value(body, "pointer-events") == nil, "A dimmed slot must stay live (D-24 forbids dead controls)."
    end
  end
end
