defmodule PukllayClubWeb.HeaderRowHeightTest do
  # Guards the header row's height contract — the class of bug where the header
  # silently grows because text inside it reflowed, taking every sticky-offset
  # element on the page with it.
  #
  # Motivating incident (debug session header-height-wordmark-wrap): `.pk-nav-inner`
  # is a single-line, auto-height flex row with align-items:center, so its height
  # is whatever its tallest item needs. The brand lockup was BOTH shrinkable
  # (`flex-initial` on header_inner/1's wrapper) and wrappable (no `white-space`
  # rule anywhere), so whenever the row ran out of room the flex algorithm shrank
  # the brand and its 206px tagline reflowed onto 2 then 3 line boxes. The row
  # grew to match (48 -> 64 -> 80 -> 112px), the header grew with it
  # (65 -> 81 -> 97 -> 129px), and the .CatalogNav ResizeObserver faithfully
  # published the inflated value as --pk-header-h. `.pk-nav-links` failed the same
  # way as a second-order effect (166.3 -> 116.3px min-content, wrapping
  # "Quiénes Somos").
  #
  # `@media (max-width: 480px)` hiding the wordmark was the ONLY reason phones
  # were immune — 480px was never the width at which the wordmark stops fitting,
  # so every viewport from 481px to 808px was broken.
  #
  # UPDATE (2026-09-09, header minimalism pass): the wordmark is now a SINGLE
  # line ("PUKLLAY CLUB", no tagline), not the two-line name+tagline stack this
  # file's history describes — at 155.3px measured (was 250px) it fits the row
  # at every viewport width (re-verified via header_capacity_test.exs's
  # re-derived arithmetic and a live CDP sweep, 320-1280px, both the catalog and
  # About headers, zero overflow), so it is UNCONDITIONALLY visible now — no
  # `display: none` base rule and no reveal breakpoint. The two-line-specific
  # tests below (nowrap-as-two-lines, hidden-by-default-then-revealed) are
  # retired along with the mechanism they guarded; `nowrap` itself — now
  # guaranteeing exactly ONE line, not two — is still load-bearing and still
  # tested.
  #
  # Oracle type: derived (contract). Real proof of this bug is rendered geometry
  # in a browser, which ExUnit cannot observe; these assertions instead pin the
  # structural preconditions the geometry depends on. Each one was verified RED
  # against the pre-fix tree, not merely green after it.
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias PukllayClubWeb.Layouts

  @css_path Path.expand("../../assets/css/app.css", __DIR__)

  defp source, do: File.read!(@css_path)

  # First declaration block for a selector, matched on the exact selector text.
  defp block!(src, selector) do
    pattern = Regex.compile!("(?m)^#{Regex.escape(selector)}\\s*\\{([^}]*)\\}")

    case Regex.run(pattern, src) do
      [_, body] -> body
      nil -> flunk("No top-level rule found for `#{selector}` in assets/css/app.css")
    end
  end

  # Everything from the trailing narrow-viewport block to the end of the file.
  defp narrow_viewport_block(src) do
    [_, tail] = String.split(src, "@media (max-width: 480px) {", parts: 2)
    tail
  end

  describe "brand lockup cannot reflow" do
    test "the header's brand wrapper is pinned, not shrinkable" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      classes =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header .pk-nav-inner > div")
        |> LazyHTML.attribute("class")

      tokens = Enum.flat_map(classes, &String.split/1)

      assert "shrink-0" in tokens,
             "The header brand wrapper must carry shrink-0. Without it the brand is a " <>
               "shrinkable flex item, and in a nowrap auto-height row that does not make the " <>
               "brand narrower — it reflows the wordmark onto extra lines and the row inherits " <>
               "the height."

      refute "flex-initial" in tokens,
             "A direct child of .pk-nav-inner still carries flex-initial (flex: 0 1 auto). " <>
               "That is exactly the declaration that let the brand shrink and the header grow."
    end

    test "the header wordmark is nowrap, so the lockup is always exactly one line" do
      body = block!(source(), ".pk-nav-inner .pk-brand-wordmark")

      assert body =~ "white-space: nowrap",
             "The header wordmark must be nowrap. It is a one-line composition by design " <>
               "(\"PUKLLAY CLUB\", no tagline); a second line is always a bug, never an " <>
               "adaptation."
    end
  end

  describe "nav links cannot reflow" do
    test "the link list is pinned and its links are nowrap" do
      src = source()

      assert block!(src, ".pk-nav-links") =~ "flex-shrink: 0",
             "`.pk-nav-links` must not shrink. Left shrinkable it collapses to its 116.3px " <>
               "min-content and wraps, which grows the row exactly the way the brand did — " <>
               "pinning only the brand relocates the bug rather than removing it."

      assert block!(src, ".pk-nav-links a") =~ "white-space: nowrap",
             "Individual nav links must be nowrap; a single two-word link (\"Quiénes Somos\") " <>
               "reflowing still puts a second line into the row."
    end
  end

  describe "the row has room for what it renders" do
    # G-01.5 header minimalism pass (2026-09-09): the wordmark used to be
    # hidden by default and revealed only at a wide-enough breakpoint (its own
    # describe block, retired along with the mechanism — see the moduledoc
    # update above). At 155.3px the one-line lockup fits the row at every
    # width, so there is nothing left to reveal: no `display: none` base rule
    # exists to opt back in from, and no `@media (min-width: ...)` block
    # exists to opt back in AT. This test asserts the ABSENCE directly, so a
    # future re-introduction of either half of the retired mechanism (without
    # the other) fails loudly instead of silently reinstating a partial,
    # broken version of it.
    test "the wordmark has no display:none base rule and no reveal breakpoint — it is unconditional" do
      src = source()

      body = block!(src, ".pk-nav-inner .pk-brand-wordmark")

      refute body =~ ~r/display\s*:/,
             "`.pk-nav-inner .pk-brand-wordmark` declares a `display` property. The one-line " <>
               "lockup (155.3px) is unconditionally visible by design — reintroducing a " <>
               "display toggle here means either a hide-by-default rule with no reveal (the " <>
               "wordmark never appears) or a partial reveal mechanism that header_capacity_test.exs " <>
               "no longer derives breakpoints for."

      refute src =~ ~r/\.pk-nav-inner \.pk-brand-wordmark\s*\{[^}]*display:/,
             "A `@media` block still toggles `.pk-nav-inner .pk-brand-wordmark`'s display " <>
               "somewhere in the stylesheet. The one-line lockup needs no reveal breakpoint at " <>
               "all — see header_capacity_test.exs for the re-derived row arithmetic that " <>
               "proves it fits at every width."
    end

    test "the narrow-viewport block does not declare the wordmark's display" do
      refute narrow_viewport_block(source()) =~
               ~r/\.pk-nav-inner \.pk-brand-wordmark\s*\{[^}]*display:/,
             "The ≤480px block declares the header wordmark's display. The lockup is " <>
               "unconditionally visible at every width now — a per-breakpoint display override " <>
               "here would silently reintroduce a hide/reveal mechanism this file's other test " <>
               "asserts does not exist."
    end
  end
end
