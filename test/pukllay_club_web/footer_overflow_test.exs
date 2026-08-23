defmodule PukllayClubWeb.FooterOverflowTest do
  # Guards the footer's no-horizontal-overflow contract — the class of bug where
  # a footer cluster's own minimum width exceeds the viewport, so the whole page
  # gains a horizontal scrollbar at widths nobody tested.
  #
  # Motivating incident (debug session footer-overflow-tablet-width): both footer
  # clusters were `display: flex` with no `flex-wrap`, so four items had to share
  # one line. A flex item's default `min-width: auto` resolves to its min-content,
  # which makes a non-wrapping cluster's minimum the SUM of its children —
  # `.pk-footer-right` measured social 136 + "Tema" 31.1 + theme-toggle 136 +
  # meta 227.8 + 3x1.5rem gaps = a hard 602.8px floor, with the BGG logo spilling
  # 18px past its squeezed parent to a 652.8px ink edge. That edge is invariant to
  # viewport width, so documentElement.scrollWidth sat pinned at 653px and every
  # viewport from 481px to 652px scrolled sideways (measured: 172px of overflow at
  # 481px, decaying to 1px at 652px).
  #
  # 481px is where `@media (max-width: 480px)` stops collapsing the cluster. Phones
  # were immune only because that block hides three of the four children and columns
  # the rest — 480px was never the width at which the cluster starts fitting; it
  # needs 653px+.
  #
  # Oracle type: derived (contract). The real proof of this bug is rendered geometry
  # in a browser, which ExUnit cannot observe; these assertions instead pin the
  # structural preconditions that geometry depends on. The wrap assertions were
  # verified RED against the pre-fix tree, not merely green after it.
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

  describe "no footer cluster can pin the page wider than the viewport" do
    test "both footer clusters wrap, so their minimum is max(children) not sum(children)" do
      body = block!(source(), ".pk-footer-left,\n.pk-footer-right")

      assert body =~ "flex-wrap: wrap",
             "`.pk-footer-left, .pk-footer-right` must declare flex-wrap: wrap. Without it each " <>
               "cluster is a single-line flex row, and because a flex item's default " <>
               "min-width: auto is its min-content, the cluster's minimum becomes the SUM of its " <>
               "children — 602.8px for .pk-footer-right, which no viewport under 653px can " <>
               "contain. Wrapping is what makes that minimum max(children) (227.8px) instead."
    end

    test "every multi-child flex container in the footer wraps" do
      src = source()

      # The whole component's wrapping contract in one place: a non-wrapping flex
      # container anywhere in this chain re-creates the sum-of-children floor at
      # its own level, just one box further in.
      for selector <- [".pk-footer-row", ".pk-footer-links", ".pk-footer-left,\n.pk-footer-right"] do
        assert block!(src, selector) =~ "flex-wrap: wrap",
               "`#{String.replace(selector, "\n", " ")}` holds multiple children in a flex row " <>
                 "but does not wrap. Every flex container in the footer must wrap; the one that " <>
                 "doesn't is the one that will pin the page open at some viewport width."
      end
    end

    test "the meta line is the only remaining hard floor, and it is a single item" do
      src = source()

      # .pk-footer-meta keeps white-space: nowrap deliberately (measured safe: it is
      # 245.8px against 417px of available width at the band's worst point, and no
      # overflow was observed anywhere from 260px up). That is only true while it
      # stays ONE item on a wrapping line. If a second nowrap sibling were ever
      # added to the same cluster without wrapping, the floor becomes their sum again.
      assert block!(src, ".pk-footer-meta") =~ "white-space: nowrap",
             "This test encodes the assumption that .pk-footer-meta is nowrap. If that changed " <>
               "deliberately, update this test's reasoning rather than deleting it."

      assert block!(src, ".pk-footer-left,\n.pk-footer-right") =~ "flex-wrap: wrap",
             "A nowrap text run is only safe inside a wrapping cluster, where it can take a " <>
               "line of its own. Inside a non-wrapping cluster it is an unshrinkable term in a " <>
               "sum, which is exactly how this bug happened."
    end
  end

  describe "footer controls are only hidden where their replacement exists" do
    # This guards the fix path that was ELIMINATED during the debug session. The
    # tempting one-line fix was to widen the ≤480px `display: none` override so the
    # 481-652px band got the same treatment. That would have deleted the club's four
    # social links and the entire theme control from every tablet viewport, because
    # the drawer they supposedly "move into" is itself display:none above 480px.
    test "the social and theme controls are hidden only inside the block that opens the drawer" do
      narrow = narrow_viewport_block(source())

      for selector <- [".pk-footer-social", ".pk-footer-toggle-tag"] do
        assert narrow =~ selector,
               "`#{selector}` is no longer hidden in the ≤480px block."
      end

      # The hide is only defensible because the same block reveals the drawer.
      # These must never drift apart into different breakpoints.
      for selector <- [".pk-nav-hamburger", ".pk-drawer"] do
        assert narrow =~ ~r/#{Regex.escape(selector)}\s*\{[^}]*display:\s*(flex|block)/,
               "The ≤480px block hides the footer's social/theme controls on the grounds that " <>
                 "they move into the drawer, but `#{selector}` is not switched on in that same " <>
                 "block. Hiding those controls at any width where the drawer is unavailable " <>
                 "removes them from the page entirely rather than relocating them."
      end
    end

    test "no wider media query hides the footer's social or theme controls" do
      src = source()

      wider_blocks =
        src
        |> String.split(~r/@media \(min-width: /)
        |> Enum.drop(1)

      for chunk <- wider_blocks do
        head = chunk |> String.split("@media", parts: 2) |> hd()

        refute head =~ ~r/\.pk-footer-social\s*\{[^}]*display:\s*none/,
               "A min-width media query hides .pk-footer-social. The drawer only exists below " <>
                 "480px, so hiding the social cluster at any wider viewport strands it."
      end

      # And the ≤480px threshold itself must not creep upward: everything above it
      # relies on the controls being present and the clusters wrapping instead.
      scanned = Regex.scan(~r/@media \(max-width: (\d+)px\)/, src)
      thresholds = Enum.map(scanned, fn [_, n] -> String.to_integer(n) end)

      for t <- thresholds do
        assert t <= 480,
               "A max-width breakpoint at #{t}px was introduced. The footer's hide-controls " <>
                 "treatment is only valid at ≤480px where the drawer exists; widening it is the " <>
                 "fix path this bug's investigation explicitly ruled out."
      end
    end
  end

  describe "the footer renders the controls this contract assumes" do
    test "the right cluster really does carry four children" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-footer-right .pk-footer-social") |> Enum.count() == 1
      assert doc |> LazyHTML.query(".pk-footer-right .pk-footer-toggle-tag") |> Enum.count() == 1
      assert doc |> LazyHTML.query(".pk-footer-right .pk-theme-toggle") |> Enum.count() == 1

      assert doc |> LazyHTML.query(".pk-footer-right .pk-footer-meta") |> Enum.count() == 1,
             "The BGG attribution + copyright line must stay in the footer at every viewport " <>
               "width (D-04). If it moved, the wrapping contract above needs re-measuring."
    end
  end
end
