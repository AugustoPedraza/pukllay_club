defmodule PukllayClubWeb.MotionRhythmTest do
  # Guards the project's MOTION RHYTHM as a system, not any one animation.
  #
  # Five debug sessions converged on this file. Each found a different way for
  # motion to be wrong while every gate stayed green, and each left its rule in
  # prose only — in a rule-level CSS comment or a knowledge-base entry — which
  # is why the same classes kept recurring:
  #
  #   category-menu-scroll-animation  a motion declaration was simply ABSENT,
  #                                   and the CSS initial value is a valid
  #                                   behaviour, so nothing anywhere complained.
  #   catalog-preview-modal-jump      an ACCENT curve (--ease-out-soft, validated
  #                                   at ~3px) applied to 515px of travel put
  #                                   26.3% of the distance in the first frame.
  #                                   Also found abandoned 220ms/360ms literals
  #                                   that the sketch-006 tuning pass never
  #                                   reached BECAUSE they were hardcoded.
  #   carousel-scroll-easing-jump     for a FROM-REST interaction the whole
  #                                   ease-out family is disqualified: every
  #                                   1-(1-t)^n has v0 = nA/D > 0.
  #   reduced-motion-order-bug        a guard that was present, readable and
  #                                   inert. (Guarded by stylesheet_integrity_test.)
  #   mobile-search-expand-jump       a NON-INTERPOLABLE target value (`auto`),
  #                                   so the transition never started at all,
  #                                   plus a discrete `position` flip on the same
  #                                   class toggle.
  #
  # Oracle type: derived (contract). The true oracle is per-frame displacement in
  # a real browser, which ExUnit cannot observe — that was measured directly via
  # CDP during each session. These assertions pin the declarations that
  # displacement is a function of, following the pattern of
  # header_row_height_test.exs and footer_rhythm_test.exs.
  #
  # The tests are written as AUDIT RULES over every animated rule in the
  # stylesheet, not as assertions about specific selectors, so they cover the
  # class rather than the instance that motivated them.
  use ExUnit.Case, async: true

  @css_path Path.expand("../../assets/css/app.css", __DIR__)
  @core_components_path Path.expand(
                          "../../lib/pukllay_club_web/components/core_components.ex",
                          __DIR__
                        )

  # Surfaces the catalog-preview-modal-jump sweep MEASURED and deliberately left
  # on the accent curve, with their measured travel. Listed here so the "large
  # amplitude must not use the accent curve" rule below cannot be read as a ban
  # on the token — it is a threshold, and these are the cases under it.
  @sanctioned_accent_surfaces %{
    ".pk-title-echo" => "8px translateY / 3.7px first frame",
    ".pk-portal" => "18-23px per edge / 7.19px first frame",
    ".pk-dimmable" => "filter only, no travelling property",
    ".pk-search-morph-toggle" => "12px width / 3.92px first frame"
  }

  # Surfaces whose travel exceeds the accent curve's ceiling (~35px at
  # --duration-fast, ~51px at --duration-base, ~73px at --duration-slow, holding
  # a 24px first-frame step as the perceptibility threshold). Each was measured
  # and moved onto --ease-standard by catalog-preview-modal-jump.
  @large_amplitude_surfaces [
    ".pk-sheet",
    ".pk-drawer",
    ".pk-mobile-cta-bar",
    "body.pk-has-cta-bar",
    ".pk-search-morph"
  ]

  defp source, do: File.read!(@css_path)

  # Comments are prose, not cascade. This stylesheet discusses transitions,
  # easing curves and durations at length — several of those comments were
  # written by the very sessions listed above and quote the defective
  # declarations verbatim — so a naive substring match would assert against
  # commentary. footer_rhythm_test.exs found a real false pass this way.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  # Every innermost declaration block as {selector, body}, including rules
  # nested inside @media. `[^{}]` cannot cross a brace, so this naturally
  # resolves to the innermost blocks and the at-rule preludes fall out.
  defp rules(src) do
    src
    |> strip_comments()
    |> then(&Regex.scan(~r/([^{}]+)\{([^{}]*)\}/, &1))
    |> Enum.map(fn [_, sel, body] ->
      {sel |> String.trim() |> String.replace(~r/\s+/, " "), body}
    end)
    |> Enum.reject(fn {sel, _} -> sel == "" or String.contains?(sel, "@") end)
  end

  # `transition:` shorthands only — never the `transition-duration`/
  # `transition-delay` longhands, which is how the reduced-motion guard's
  # deliberate `1ms !important` stays out of scope without needing an exception.
  defp transition_shorthands(body) do
    ~r/(?<![-\w])transition:\s*([^;]+)/
    |> Regex.scan(body)
    |> Enum.map(fn [_, value] -> value |> String.replace(~r/\s+/, " ") |> String.trim() end)
  end

  defp declares?(body, property, value_pattern) do
    Regex.match?(~r/(?<![-\w])#{property}:\s*#{value_pattern}\s*(;|$)/, body)
  end

  # The last compound selector — i.e. the element the rule actually styles.
  # `.pk-search-morph.is-open .pk-nav-search` styles .pk-nav-search, NOT the
  # morph, so a `width: auto` there says nothing about the morph's own width.
  defp subject_classes(selector) do
    selector
    |> String.split(",")
    |> Enum.map(fn part ->
      part
      |> String.trim()
      |> String.split(~r/\s*[\s>+~]\s*/)
      |> List.last()
      |> then(&Regex.scan(~r/\.([A-Za-z0-9_-]+)/, &1 || ""))
      |> Enum.map(fn [_, cls] -> cls end)
    end)
    |> List.flatten()
    |> MapSet.new()
  end

  describe "every animated property must actually be able to animate" do
    # THE RULE THIS SESSION PRODUCED. A transition names a property; if any rule
    # on that same element can set that property to `auto`, the transition
    # silently never starts — `transitionrun` does not fire and the element
    # teleports. There is no error, no warning and no failing gate: the CSS
    # reads as correct and the animation simply is not there.
    test "no element transitions a dimension that another rule sets to `auto`" do
      all_rules = rules(source())

      # Elements that transition a dimensional (interpolable-length) property.
      animated =
        for {selector, body} <- all_rules,
            value <- transition_shorthands(body),
            property <- ["width", "height"],
            String.contains?(value, property),
            class <- subject_classes(selector),
            do: {class, property}

      offenders =
        for {class, property} <- Enum.uniq(animated),
            {selector, body} <- all_rules,
            MapSet.member?(subject_classes(selector), class),
            declares?(body, property, "auto"),
            do: "#{selector} { #{property}: auto }  (because .#{class} transitions #{property})"

      assert offenders == [],
             """
             These rules set a dimension to `auto` on an element that TRANSITIONS that
             dimension. `auto` is not an interpolable value, so the transition never
             starts — no `transitionrun`, no frames, the box just teleports:

             #{Enum.map_join(Enum.uniq(offenders), "\n", &("  - " <> &1))}

             This is debug mobile-search-expand-jump verbatim. The mobile search pill
             moved 318px in a single painted frame in both directions because its open
             state was `width: auto`; the fix was `calc(100% - 2 * var(--pk-gutter))`,
             the same rendered value expressed as a length the browser can interpolate.

             Fix by giving the open state an explicit length (measure what `auto`
             currently resolves to and write that), NOT by deleting the property from
             the transition list — that would make the snap intentional rather than
             accidental, which is not what any of these surfaces want.
             """
    end
  end

  describe "the token system owns every duration and curve" do
    # Catches the drift that let .pk-sheet keep an abandoned 360ms literal
    # through an entire system-wide tuning pass: the sketch-006 pass retuned the
    # tokens, and rules that had hardcoded their timing simply did not receive it.
    test "no `transition` shorthand hardcodes a duration or an easing curve" do
      offenders =
        for {selector, body} <- rules(source()),
            value <- transition_shorthands(body),
            bare = String.replace(value, ~r/var\([^)]*\)/, "TOKEN"),
            raw_literal?(bare),
            do: "#{selector} { transition: #{value} }"

      assert offenders == [],
             """
             These `transition` declarations hardcode a timing value or an easing curve
             instead of reading the shared tokens:

             #{Enum.map_join(Enum.uniq(offenders), "\n", &("  - " <> &1))}

             Use var(--duration-fast|base|slow) and var(--ease-standard|out-soft). A
             hardcoded value opts the rule out of every future tuning pass silently —
             that is exactly how 220ms and 360ms survived from sketches 001/002 into
             shipped code long after sketch 006 replaced them, and why the
             catalog-preview-modal-jump defect went unfixed for several phases.

             Note the CSS keyword `ease` is cubic-bezier(0.25, 0.1, 0.25, 1) — a curve
             belonging to NEITHER token, not a synonym for either.
             """
    end

    test "no rule uses the `all` keyword to pick what animates" do
      offenders =
        for {selector, body} <- rules(source()),
            value <- transition_shorthands(body),
            Regex.match?(~r/^all[\s,]|[\s,]all[\s,]/, value <> " "),
            do: "#{selector} { transition: #{value} }"

      assert offenders == [],
             """
             These rules transition `all`:

             #{Enum.map_join(Enum.uniq(offenders), "\n", &("  - " <> &1))}

             `all` opts in every animatable property, including geometry the element
             never intended to animate — so a layout change made elsewhere silently
             acquires a transition nobody designed, and the element pays a per-frame
             layout cost for properties that were never supposed to move. List the
             properties the rule's own state changes actually touch.
             """
    end

    test "the motion tokens still hold sketch 006's validated values" do
      root = Enum.find_value(rules(source()), fn {sel, body} -> sel == ":root" && body end)

      assert root, "No top-level `:root` block found in assets/css/app.css"

      for {token, value} <- [
            {"--duration-fast", "100ms"},
            {"--duration-base", "180ms"},
            {"--duration-slow", "280ms"},
            {"--ease-standard", "cubic-bezier(0.4, 0, 0.2, 1)"},
            {"--ease-out-soft", "cubic-bezier(0.16, 1, 0.3, 1)"}
          ] do
        assert String.contains?(root, "#{token}: #{value}"),
               "`:root` must still declare `#{token}: #{value}` — sketch 006's winning " <>
                 "variant D. Every amplitude threshold recorded across the debug " <>
                 "knowledge base (the accent curve's 35px/51px/73px ceilings, the 24px " <>
                 "perceptibility step) was computed against these exact numbers, so " <>
                 "retuning a token silently invalidates all of them and they must be " <>
                 "recomputed rather than assumed to carry over."
      end
    end
  end

  describe "amplitude decides the curve, in both directions" do
    # Guards the defect: --ease-out-soft (easeOutExpo) on a large travel puts
    # ~33% of the distance into the first 16.7ms frame at --duration-slow.
    test "large-amplitude sliding surfaces never use the accent curve" do
      offenders =
        for {selector, body} <- rules(source()),
            selector in @large_amplitude_surfaces,
            value <- transition_shorthands(body),
            String.contains?(value, "--ease-out-soft"),
            do: "#{selector} { transition: #{value} }"

      assert offenders == [],
             """
             These large-travel surfaces are using the ACCENT curve:

             #{Enum.map_join(Enum.uniq(offenders), "\n", &("  - " <> &1))}

             --ease-out-soft is easeOutExpo. It spends 32.7% of the travel in the first
             16.7ms frame at --duration-slow (46.7% at --duration-base, 68.6% at
             --duration-fast), then crawls below the threshold of perceived motion.
             Measured on these very surfaces: .pk-sheet 135px of a 515px travel in frame
             one, .pk-drawer 104.8px of 320px, .pk-search-morph 77.2px of 236px.

             Use var(--ease-standard). And do NOT try to fix a pop by lengthening the
             duration — a longer duration on a front-loaded curve is worse, not better:
             the same curve at --duration-slow yields a LARGER first frame than at 360ms.
             """
    end

    # The boundary neighbour, green by construction, guarding the OPPOSITE wrong
    # change. The realistic recurrence path here is not someone reintroducing a
    # bad curve — it is a tidy-up pass noticing the stylesheet uses two curves
    # and "restoring consistency" by collapsing them to one.
    test "the measured small-amplitude surfaces keep the accent curve" do
      for {selector, rationale} <- @sanctioned_accent_surfaces do
        body =
          Enum.find_value(rules(source()), fn {sel, body} -> sel == selector && body end)

        assert body, "No top-level rule found for `#{selector}` in assets/css/app.css"

        assert String.contains?(Enum.join(transition_shorthands(body), " "), "--ease-out-soft"),
               """
               `#{selector}` must keep var(--ease-out-soft).

               It was MEASURED (#{rationale}) and deliberately left on the accent curve by
               the catalog-preview-modal-jump sweep, which moved five other surfaces off it
               and kept these. That makes the finding a THRESHOLD, not a ban on the token.

               If you are here because you were making the stylesheet's curves consistent:
               don't. Two curves is the design. --ease-standard is for travel,
               --ease-out-soft is for accents under ~50px.
               """
      end
    end
  end

  describe "the Elixir-owned animations follow the same rhythm" do
    # core_components' JS.show/JS.hide are the only animated surface not living
    # in app.css, which is precisely why they still carried phx.new's stock
    # `ease-out duration-300` long after every CSS surface had been tuned.
    test "JS.show/JS.hide read the duration tokens and keep `time:` in sync" do
      src = File.read!(@core_components_path)

      for {function, token, expected_ms} <- [
            {"show", "--duration-slow", 280},
            {"hide", "--duration-base", 180}
          ] do
        body =
          case Regex.run(~r/def #{function}\(js.*?\n  end/s, src) do
            [match] -> match
            nil -> flunk("No `def #{function}/2` found in core_components.ex")
          end

        assert String.contains?(body, "duration-[var(#{token})]"),
               "`#{function}/2` must drive its duration from `var(#{token})` rather " <>
                 "than a Tailwind duration literal, so a retune of the token reaches it."

        assert String.contains?(body, "ease-[var(--ease-standard)]"),
               "`#{function}/2` must use `var(--ease-standard)`. Tailwind's `ease-out` " <>
                 "and `ease-in` are neither of this project's two curves."

        assert String.contains?(body, "time: #{expected_ms}"),
               """
               `#{function}/2`'s `time:` must be #{expected_ms}, matching #{token}.

               LiveView uses `time:` to decide when to apply/remove the transition
               classes, and an Elixir integer cannot read a CSS custom property — so
               this is a real coupling that has to be maintained by hand. If it drifts
               below the CSS duration the element is hidden mid-animation; above it,
               the element sits finished-but-waiting.
               """

        refute String.contains?(body, "transition-all"),
               "`#{function}/2` must not use `transition-all` — same reasoning as the " <>
                 "`transition: all` rule for the stylesheet."
      end
    end
  end

  defp raw_literal?(value) do
    Regex.match?(~r/\d+\s*m?s(\s|,|$)/, value) or
      String.contains?(value, "cubic-bezier(") or
      Regex.match?(~r/(^|[\s,])(ease|ease-in|ease-out|ease-in-out|linear|step-\w+)([\s,]|$)/, value)
  end
end
