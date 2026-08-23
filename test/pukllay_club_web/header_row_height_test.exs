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

    test "the header wordmark is nowrap, so the lockup is always exactly two lines" do
      body = block!(source(), ".pk-nav-inner .pk-brand-wordmark")

      assert body =~ "white-space: nowrap",
             "The header wordmark must be nowrap. It is a two-line composition by design " <>
               "(name over tagline); a third line is always a bug, never an adaptation."
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
    test "the wordmark is hidden by default and revealed only at a wide-enough breakpoint" do
      src = source()

      assert block!(src, ".pk-nav-inner .pk-brand-wordmark") =~ "display: none",
             "The header wordmark must be hidden by default and opted back in at a breakpoint. " <>
               "Showing it by default is what left 481-767px over-subscribed."

      # Locate the min-width block that reveals it, and pin the width itself.
      # This is the boundary assertion: the reveal width is the whole fix. The
      # row needs 250 (brand) + 24 + 166.3 (links) + 24 + 280 (open pill) + 64
      # (gutters) = 808.3px to seat everything at natural size. 48rem/768px is
      # the widest existing breakpoint at or below that, and the pill's own
      # shrink guard covers the 40.3px difference (it lands at 239.7px there).
      # Anything narrower reopens the bug: at 640px/sm the pill would be left
      # 111.7px, narrower than its own 44px toggle plus 44px close control.
      reveal_widths =
        src
        |> String.split("@media (min-width: ")
        |> Enum.drop(1)
        |> Enum.filter(fn chunk ->
          [head | _] = String.split(chunk, "@media", parts: 2)
          head =~ ~r/\.pk-nav-inner \.pk-brand-wordmark\s*\{[^}]*display:\s*flex/
        end)
        |> Enum.map(fn chunk ->
          case Regex.run(~r/^([\d.]+)(rem|px)/, chunk) do
            [_, n, "rem"] -> String.to_float(n <> ".0") * 16
            [_, n, "px"] -> String.to_float(n <> ".0")
            nil -> flunk("Could not parse the min-width value revealing the header wordmark")
          end
        end)

      assert reveal_widths != [],
             "No `@media (min-width: ...)` block restores `display: flex` on " <>
               "`.pk-nav-inner .pk-brand-wordmark`. Without it the wordmark never appears at any " <>
               "viewport width."

      for width <- reveal_widths do
        assert width >= 768,
               "The header wordmark is revealed at #{trunc(width)}px, but the row cannot seat " <>
                 "brand + nav links + the open search pill below 768px without the pill " <>
                 "collapsing past its own controls. Revealing it earlier reopens the header " <>
                 "height bug."
      end
    end

    test "the narrow-viewport block does not re-declare the wordmark's display" do
      refute narrow_viewport_block(source()) =~
               ~r/\.pk-nav-inner \.pk-brand-wordmark\s*\{[^}]*display:/,
             "The ≤480px block declares the header wordmark's display again. One visual " <>
               "property must have exactly one owner in this layer — and a 480px threshold is " <>
               "precisely the wrong number, since the wordmark stops fitting at 768px."
    end
  end
end
