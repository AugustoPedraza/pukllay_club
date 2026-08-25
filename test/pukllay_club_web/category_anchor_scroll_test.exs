defmodule PukllayClubWeb.CategoryAnchorScrollTest do
  # Guards the motion half of the category-index interaction: tapping a category
  # must GLIDE to its shelf, not teleport to it.
  #
  # Motivating incident (debug session category-menu-scroll-animation): selecting
  # a category from the index menu jumped instantly to the target section on both
  # mobile and desktop. Nothing was broken in the usual sense — the anchors
  # resolved, the section was correct, the landing offset already cleared the
  # header. The page simply arrived with no animation, which read as jarring.
  #
  # The cause was an ABSENCE, which is why nothing flagged it. Both surfaces —
  # the desktop `.pk-cat-item` mega-menu rows and the mobile `.pk-chip` row — are
  # plain native anchors (`href="#carousel-KEY"`), and `.CatalogNav`'s
  # `onCatItemClick` deliberately only closes the panel rather than intercepting
  # the click. Native fragment navigation is animated ONLY when the document's
  # scrolling element computes `scroll-behavior: smooth`; `app.css` never
  # declared that for `html`, so the CSS initial value `auto` was in force and an
  # instant jump was the specification-mandated behaviour. Measured in headless
  # Chrome before the fix: `html.scrollBehavior = auto`. After: `smooth`, with
  # every other scroll-related computed value byte-identical.
  #
  # Oracle type: derived (contract). The real proof is a browser animating a
  # scroll over ~500ms, which ExUnit cannot observe; these assertions pin the
  # declarations and the markup mechanism that animation is a function of. The
  # first is RED-verified against the pre-fix stylesheet. The rest are boundary
  # neighbours around the same equivalence class, each guarding a specific wrong
  # change rather than restating the fix:
  #
  #   * dropping the reduced-motion gate (an accessibility regression that would
  #     still "work"),
  #   * letting the declaration reach `.pk-rail`, whose `.CarouselScroll` hook
  #     writes `scrollLeft` every animation frame and would then be fighting the
  #     browser for the same property,
  #   * dropping `.pk-shelf`'s `scroll-margin-top`, which would trade an instant
  #     jump for a smooth glide to the WRONG place (under the sticky header),
  #   * converting the anchors to JS handlers, which bypasses the CSS mechanism
  #     entirely and silently restores the jump.
  use ExUnit.Case, async: true

  @css_path Path.expand("../../assets/css/app.css", __DIR__)
  @built_css_path Path.expand("../../priv/static/assets/css/app.css", __DIR__)
  @layouts_path Path.expand("../../lib/pukllay_club_web/components/layouts.ex", __DIR__)
  @index_path Path.expand("../../lib/pukllay_club_web/live/catalog_live/index.ex", __DIR__)

  defp source, do: File.read!(@css_path)

  # Returns the body of the first `{ ... }` block opening at or after `from`,
  # brace-matched rather than regex-matched so a nested rule (which is exactly
  # what `@media { html { ... } }` is) doesn't terminate the block early.
  defp block_after(src, from) do
    case :binary.match(src, "{", scope: {from, byte_size(src) - from}) do
      :nomatch -> nil
      {open, 1} -> collect(src, open + 1, 1, open + 1)
    end
  end

  defp collect(src, pos, depth, start) do
    cond do
      pos >= byte_size(src) -> nil
      depth == 0 -> binary_part(src, start, pos - start - 1)
      true -> step(src, pos, depth, start)
    end
  end

  defp step(src, pos, depth, start) do
    case binary_part(src, pos, 1) do
      "{" -> collect(src, pos + 1, depth + 1, start)
      "}" -> collect(src, pos + 1, depth - 1, start)
      _ -> collect(src, pos + 1, depth, start)
    end
  end

  # The body of every rule whose selector matches `selector` exactly, ignoring
  # anything inside comments (this file's prose discusses `scroll-behavior` at
  # length, and a naive substring search would happily assert against a comment).
  defp rule_bodies(src, selector) do
    src
    |> strip_comments()
    |> find_rules(selector, 0, [])
  end

  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  defp find_rules(src, selector, from, acc) do
    pattern = Regex.compile!("(?m)^\\s*" <> Regex.escape(selector) <> "\\s*\\{")

    case Regex.run(pattern, binary_part(src, from, byte_size(src) - from), return: :index) do
      nil -> Enum.reverse(acc)
      [{at, _len} | _] -> collect_rule(src, selector, from + at, acc)
    end
  end

  defp collect_rule(src, selector, at, acc) do
    body = block_after(src, at)
    next = at + max(byte_size(body || ""), 1)
    find_rules(src, selector, next, [body | acc])
  end

  describe "the document scroller animates category-anchor navigation" do
    test "html declares scroll-behavior: smooth" do
      bodies = rule_bodies(source(), "html")

      assert Enum.any?(bodies, &(&1 =~ ~r/scroll-behavior:\s*smooth/)),
             "No `html { scroll-behavior: smooth }` in assets/css/app.css. Without it the CSS " <>
               "initial value `auto` governs the document scrolling element, and every category " <>
               "anchor on BOTH surfaces (the desktop `.pk-cat-item` mega-menu rows and the " <>
               "mobile `.pk-chip` row) jumps instantly to its shelf instead of gliding — the " <>
               "exact symptom reported as \"not polished, kind of instant scrolling\". This has " <>
               "to sit on `html` specifically: neither `html` nor `body` carries an `overflow` " <>
               "outside the transient `.pk-sheet-open`/`.pk-drawer-open` scroll locks, so `html` " <>
               "IS `document.scrollingElement` and its value is the one fragment navigation reads."
    end

    test "the smooth scroll is gated behind prefers-reduced-motion: no-preference" do
      src = strip_comments(source())

      at_rules = Regex.scan(~r/@media[^{]*prefers-reduced-motion:\s*no-preference[^{]*/, src, return: :index)

      gated? =
        Enum.any?(at_rules, fn [{at, len} | _] ->
          case block_after(src, at + len) do
            nil -> false
            body -> body =~ ~r/(?m)^\s*html\s*\{[^}]*scroll-behavior:\s*smooth/s
          end
        end)

      assert gated?,
             "`html { scroll-behavior: smooth }` is declared outside any " <>
               "`@media (prefers-reduced-motion: no-preference)` block. Browsers are not " <>
               "consistent about honouring a reduced-motion preference for smooth scrolling on " <>
               "their own, so the gate is what actually does the work — verified with Chrome's " <>
               "`--force-prefers-reduced-motion`, under which `html.scrollBehavior` correctly " <>
               "falls back to `auto`. It also matches this file's existing motion discipline " <>
               "(`.pk-scroll-top`'s bounce) and daisyUI's own `.carousel` rule, which gates its " <>
               "smooth scroll identically. A visitor who asked for less motion keeps the instant " <>
               "jump; for them that is the correct outcome, not a regression."
    end

    test "the horizontal rails keep their explicit scroll-behavior: auto" do
      bodies = rule_bodies(source(), ".pk-rail")

      assert Enum.any?(bodies, &(&1 =~ ~r/scroll-behavior:\s*auto/)),
             "`.pk-rail` no longer pins `scroll-behavior: auto`. `.CarouselScroll` " <>
               "(carousel_row.ex) animates the rails itself, assigning `rail.scrollLeft` on " <>
               "every animation frame with its own `easeOutSoft` curve. If the rail ever " <>
               "computes `smooth`, the browser's scroll animation and the hook's per-frame " <>
               "writes fight over the same property and the carousel stutters or stalls. " <>
               "`scroll-behavior` is not inherited, so the `html` rule above cannot reach the " <>
               "rail on its own — this explicit `auto` is the belt to that braces, and both " <>
               "were measured holding in a real browser (`html` smooth, `.pk-rail` auto, `body` " <>
               "auto, simultaneously)."
    end

    test "the shelves keep the scroll-margin-top that decides where a glide lands" do
      bodies = rule_bodies(source(), ".pk-shelf")

      assert Enum.any?(bodies, &(&1 =~ ~r/scroll-margin-top:/)),
             "`.pk-shelf` no longer declares `scroll-margin-top`. That rule and the `html` " <>
               "smooth-scroll rule are two halves of one interaction: this one says WHERE an " <>
               "anchor lands (clear of the sticky header, derived from its published " <>
               "`--pk-header-h` rather than a hardcoded constant), the other says HOW it gets " <>
               "there. Dropping it does not restore the old bug — it makes a worse one, because " <>
               "the page now glides smoothly and deliberately to a heading hidden underneath " <>
               "the header."
    end

    test "the built stylesheet still carries the html rule after LightningCSS" do
      # End-to-end on the real build output. Skipped when assets have not been
      # built (fresh clone / CI step ordering), since absence then says nothing.
      if File.exists?(@built_css_path) do
        built = strip_comments(File.read!(@built_css_path))

        assert built =~ ~r/(?m)^\s*html\s*\{\s*scroll-behavior:\s*smooth/,
               "The `html { scroll-behavior: smooth }` rule is present in assets/css/app.css " <>
                 "but absent from priv/static/assets/css/app.css. Something in the asset " <>
                 "pipeline dropped or rewrote it, so the browser never sees it and the fix is " <>
                 "inert in production even though the source looks correct. (This is not " <>
                 "hypothetical for this file: debug search-expand-header-overlap lost an entire " <>
                 "rule to a premature comment terminator with no error anywhere.)"
      end
    end
  end

  describe "both category surfaces stay on the native mechanism the fix depends on" do
    test "the category entries are native fragment anchors on desktop and mobile" do
      for {path, label} <- [
            {@layouts_path, "the desktop mega-menu (`Layouts.category_menu/1`)"},
            {@index_path, "the mobile chip row (`CatalogLive.Index`)"}
          ] do
        assert File.read!(path) =~ ~S(href={"#carousel-#{row.key}"}),
               "#{label} no longer links to its shelf with a native `href=\"#carousel-KEY\"` " <>
                 "anchor. The scroll animation is delivered by the BROWSER's fragment " <>
                 "navigation reading `html`'s `scroll-behavior` — that is the entire reason one " <>
                 "CSS declaration fixed both surfaces at once, with no JS and no per-surface " <>
                 "handler. Replace the anchor with a click handler and the CSS stops applying: " <>
                 "a `scrollTo`/`scrollIntoView` call without an explicit `behavior: \"smooth\"` " <>
                 "silently restores the instant jump this session fixed."
      end
    end

    test "the category click handler does not intercept the navigation" do
      source = File.read!(@layouts_path)

      [_, handler] = String.split(source, "this.onCatItemClick =", parts: 2)
      handler = String.slice(handler, 0, 200)

      refute handler =~ "preventDefault",
             "`.CatalogNav`'s `onCatItemClick` now calls `preventDefault`. Its job is to close " <>
               "the panel and then get out of the way — cancelling the click cancels the native " <>
               "fragment navigation, which is the only thing performing the scroll at all. The " <>
               "menu would close and the page would not move."

      refute source =~ "scrollIntoView",
             "A `scrollIntoView` call appeared in layouts.ex. If it is scrolling to a category " <>
               "shelf it overrides the CSS mechanism this session's fix relies on, and unless " <>
               "it passes `behavior: \"smooth\"` explicitly it reintroduces the instant jump. " <>
               "Prefer leaving the native anchor alone; if a handler is genuinely needed, pass " <>
               "the behavior explicitly and update this guard to say so."
    end
  end
end
