defmodule PukllayClubWeb.HeaderSearchRightAlignTest do
  # Guards the CLOSED header search pill's RIGHT ANCHORING — specifically the
  # class of bug where a STRUCTURAL (DOM-tree) selector silently over-matches
  # into a viewport band where the LAYOUT condition it stands in for is false.
  #
  # Motivating incident (debug search-right-align-mobile). quick task
  # 260824-jkc Task 3 added, at the top level with no media query:
  #
  #     .pk-cat-trigger ~ .pk-search-morph { margin-left: 0 }
  #
  # to stop .pk-cat-trigger and .pk-search-morph both carrying
  # `margin-left: auto` and having flexbox split the row's free space evenly
  # between them (measured: a 303px gap at 1280px instead of "adjacent").
  # That is correct on desktop. But `~` matches on the DOM TREE, while the
  # hand-off the rule relies on — the trigger absorbing the row's free space —
  # requires the trigger to generate a BOX, and `display: none` separates those
  # two things. Inside the trailing narrow-viewport block the trigger is
  # display:none (mobile shows the chip index row instead of the mega-menu) yet
  # stays in the DOM for the desktop panel's containing-block contract, so the
  # override still matched, still stripped the pill's `margin-left: auto`, and
  # nothing replaced the right-push. Measured in headless Chrome at 390px: the
  # closed 44px pill sat at x=110 — 8px past the brand, the row's own gap —
  # leaving 222px of dead space before .pk-nav-inner's content edge at 376,
  # where a right-anchored pill measures 0. That is the reported "search right
  # alignment broken, sitting over the same line as the header".
  #
  # The fix scopes the override to the EXACT COMPLEMENT of the hide band, so it
  # can only apply where its precondition actually holds. The load-bearing
  # assertion here is therefore the LOCKSTEP one: the two breakpoints must stay
  # equal. Moving the mobile breakpoint without moving the guard is the single
  # change that reopens this bug, and it fails this suite with the arithmetic in
  # the message.
  #
  # Oracle type: derived (contract). The real proof is rendered geometry, which
  # ExUnit cannot observe; these assertions pin the structural precondition that
  # geometry depends on. The two override assertions were verified RED against
  # the pre-fix stylesheet; the three invariant assertions were green before and
  # after and exist to stop the fix being "undone from the other side" (by
  # deleting the auto margins the guard hands off to, or by revealing the
  # trigger on mobile).
  use ExUnit.Case, async: true

  @css_path Path.expand("../../assets/css/app.css", __DIR__)

  defp source, do: File.read!(@css_path)

  # Comments are prose, not cascade. Matching selector or declaration text
  # inside a comment is a false pass — and this rule carries a long explanatory
  # comment that names every declaration these assertions look for, so stripping
  # is mandatory here rather than merely tidy.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  # First top-level declaration block for a selector, matched on exact selector
  # text and anchored to the start of a line so `.pk-search-morph` never matches
  # `.pk-search-morph.is-open` and `.pk-cat-trigger` never matches
  # `.pk-cat-trigger-label`.
  defp block!(src, selector) do
    pattern = Regex.compile!("(?m)^#{Regex.escape(selector)}\\s*\\{([^}]*)\\}")

    case Regex.run(pattern, strip_comments(src)) do
      [_, body] -> body
      nil -> flunk("No top-level rule found for `#{selector}` in assets/css/app.css")
    end
  end

  # The trailing narrow-viewport block — the LAST `@media (max-width: Npx)` in
  # the file. Returns its literal width alongside its body so assertions can
  # compare the override's guard against the real breakpoint rather than against
  # a hardcoded 480 that would itself drift.
  defp narrow_viewport(src) do
    stripped = strip_comments(src)

    case List.last(Regex.scan(~r/@media\s*\(\s*max-width:\s*(\d+)px\s*\)\s*\{/, stripped)) do
      [_, width_str] ->
        width = String.to_integer(width_str)
        re = Regex.compile!("@media\\s*\\(\\s*max-width:\\s*#{width}px\\s*\\)\\s*\\{")
        [_, tail] = Regex.split(re, stripped, parts: 2)
        {width, tail}

      _ ->
        flunk("No `@media (max-width: Npx)` block found in assets/css/app.css")
    end
  end

  # The media condition guarding the sibling override, or nil when the override
  # is declared unconditionally at the top level (the defect state).
  defp override_guard(src) do
    case Regex.run(
           ~r/@media\s+([^{]+?)\s*\{\s*\.pk-cat-trigger\s*~\s*\.pk-search-morph\s*\{/,
           strip_comments(src)
         ) do
      [_, condition] -> String.trim(condition)
      nil -> nil
    end
  end

  describe "the sibling override may only apply where .pk-cat-trigger generates a box" do
    test "the override is guarded by a media query, never declared unconditionally" do
      assert override_guard(source()),
             "`.pk-cat-trigger ~ .pk-search-morph { margin-left: 0 }` is declared at the top " <>
               "level, so it applies at EVERY viewport width. The `~` combinator matches on the " <>
               "DOM tree, but this rule's whole justification is that the trigger absorbs the " <>
               "row's free space instead — which requires the trigger to generate a BOX. Below " <>
               "the narrow-viewport breakpoint `.pk-cat-trigger` is `display: none` yet remains " <>
               "in the DOM, so an unguarded override strips `.pk-search-morph`'s " <>
               "`margin-left: auto` with nothing left to push the pill right: measured at 390px " <>
               "the closed pill landed at x=110 (8px past the brand) with 222px of dead space " <>
               "before the row's content edge. Wrap this rule in a media query that excludes the " <>
               "band where the trigger is hidden."
    end

    test "the guard is the exact complement of the trigger's hide breakpoint, in lockstep" do
      src = source()
      {hide_width, _body} = narrow_viewport(src)
      guard = override_guard(src)

      assert guard,
             "The sibling override is unguarded — see the previous test for why that reopens " <>
               "the mobile misalignment."

      guard_match = Regex.run(~r/not\s+all\s+and\s*\(\s*max-width:\s*(\d+)px\s*\)/, guard)

      assert guard_match,
             "The sibling override's guard is `#{guard}`, which is not the exact complement of " <>
               "the trigger's hide condition. It must be written as " <>
               "`not all and (max-width: #{hide_width}px)`, pinning the SAME literal as the " <>
               "`@media (max-width: #{hide_width}px)` block that hides `.pk-cat-trigger`. A " <>
               "`min-width: #{hide_width + 1}px` form is NOT equivalent: it leaves a sub-pixel " <>
               "band (e.g. #{hide_width}.5px) matching neither rule, where the trigger is " <>
               "already visible but the override has not yet kicked in — and both elements " <>
               "carry `margin-left: auto` there, which is the original 303px-gap bug."

      [_, guard_width_str] = guard_match
      guard_width = String.to_integer(guard_width_str)

      assert guard_width == hide_width,
             "Breakpoint drift: `.pk-cat-trigger` is hidden below #{hide_width}px, but the " <>
               "sibling override is only excluded below #{guard_width}px. These two numbers are " <>
               "one decision and must move together. As written, the band between them has a " <>
               "hidden trigger AND a neutralised search margin — exactly the state that left the " <>
               "closed pill stranded #{222}px from the row's right edge at 390px. Update both, " <>
               "or neither."
    end
  end

  describe "the declarations the guard hands off to are still in force" do
    test "the base .pk-search-morph rule still owns the right-anchoring auto margin" do
      assert block!(source(), ".pk-search-morph") =~ ~r/margin-left:\s*auto\s*;/,
             "The base `.pk-search-morph` rule must still declare `margin-left: auto`. This is " <>
               "what right-anchors the closed pill everywhere the sibling override does not " <>
               "apply — i.e. the whole narrow-viewport band, and every page without a category " <>
               "trigger (Detalle). Guarding the override restores nothing if the value it " <>
               "restores has been deleted."
    end

    test "the trigger still carries the auto margin that anchors the group above the breakpoint" do
      assert block!(source(), ".pk-cat-trigger") =~ ~r/margin-left:\s*auto\s*;/,
             "`.pk-cat-trigger` must still declare `margin-left: auto`. Above the breakpoint the " <>
               "override deliberately zeroes the search pill's own auto margin and relies on the " <>
               "trigger's to absorb the row's free space, landing both as one right-anchored " <>
               "group. Remove it and the desktop pair drifts left instead."
    end

    test "the trigger is still hidden in the narrow-viewport block, which is what the guard assumes" do
      {width, body} = narrow_viewport(source())

      assert Regex.match?(~r/\.pk-cat-trigger\s*\{[^}]*display:\s*none/, body),
             "The `@media (max-width: #{width}px)` block no longer hides `.pk-cat-trigger`. That " <>
               "is a real design change (mobile deliberately shows the chip index row instead of " <>
               "the mega-menu), and it invalidates the sibling override's guard: if the trigger " <>
               "now renders a box below #{width}px it can absorb the free space itself, and the " <>
               "override should apply there rather than be excluded. Revisit both rules together."
    end
  end
end
