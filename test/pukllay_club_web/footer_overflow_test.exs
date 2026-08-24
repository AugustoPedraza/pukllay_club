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

  # Comments are prose, not cascade. Selector-name assertions below must match a
  # real rule, and a comment that merely NAMES a selector was enough to satisfy
  # them — a false pass this file actually hit when `.pk-footer-toggle-tag` was
  # folded into `.pk-footer-theme` and survived only as a word in a comment.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

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
    [_, tail] = String.split(strip_comments(src), "@media (max-width: 480px) {", parts: 2)
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

    test "the legal band's two nowrap pieces can break apart instead of summing into a floor" do
      src = source()

      # This test used to be called "the meta line is the only remaining hard
      # floor, and it is a single item", and its comment warned: "That is only
      # true while it stays ONE item on a line of its own. If a second nowrap
      # sibling were ever added beside it without wrapping, the floor becomes
      # their sum again."
      #
      # A second nowrap sibling was then added, deliberately — the legal band now
      # holds two `.pk-footer-meta` pieces so `space-between` can anchor one to
      # each edge (debug footer-desktop-imbalance, treatment D). So the warned-of
      # condition is now REAL and this test guards the mitigation rather than the
      # old single-item assumption.
      assert block!(src, ".pk-footer-meta") =~ "white-space: nowrap",
             "This test encodes the assumption that .pk-footer-meta is nowrap. If that changed " <>
               "deliberately, update this test's reasoning rather than deleting it."

      # `flex-wrap: wrap` on the band is what stops the two nowrap pieces from
      # summing into a hard floor: below the width where both fit, the band breaks
      # BETWEEN them (each piece keeps its own line) instead of shrinking their
      # boxes while the nowrap text spills out.
      #
      # This is not theoretical. Measured on the live app at 260px BEFORE the
      # split, the single merged run was 241.75px of ink inside a 232px box: the
      # text escaped its own flex item by 9.75px and ran into the right gutter.
      # documentElement.scrollWidth still reported ZERO overflow, because the ink
      # stopped 4.25px short of the viewport edge — which is exactly why the
      # earlier "no overflow down to 260px" claim looked clean while the text was
      # already out of bounds. After the split the same 260px viewport breaks the
      # band onto two lines with 114.67px of room to spare and no bleed at all.
      assert block!(src, ".pk-footer-legal") =~ "flex-wrap: wrap",
             "`.pk-footer-legal` holds two `white-space: nowrap` pieces. Without flex-wrap " <>
               "their min-contents SUM into a hard floor, and because each piece's box is " <>
               "shrinkable while its text is not, the failure is silent: the text bleeds past " <>
               "its box into the gutter without ever registering as document overflow."

      assert block!(src, ".pk-footer-legal") =~ ~r/width:\s*100%/,
             "`.pk-footer-legal` no longer spans the full row. The nowrap pieces are only " <>
               "safe while the band has a whole line to itself; sharing one with a cluster " <>
               "puts it back into a sum-of-min-contents floor, which is the mechanism of " <>
               "this bug."

      assert block!(src, ".pk-footer-row") =~ "flex-wrap: wrap",
             "A full-width item can only take a line of its own inside a WRAPPING container. " <>
               "Without flex-wrap on .pk-footer-row it would instead be squeezed onto the " <>
               "single line beside both clusters."
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

      # The hide is now at the CLUSTER, not per child (debug footer-desktop-imbalance).
      # It could not be before: `.pk-footer-right` also held the copyright/BGG line,
      # which must stay visible at every width. Once that moved to `.pk-footer-legal`,
      # the cluster's entire contents became the two controls that relocate — and
      # hiding the box became necessary as well as sufficient, because flex `gap`
      # skips a hidden CHILD but still spends a slot on an empty visible PARENT.
      #
      # What this rule no longer states per-child — that nothing is hidden unless it
      # has a drawer equivalent — is pinned by FooterRhythmTest, which asserts this
      # cluster holds exactly the two relocating concerns.
      assert narrow =~ ~r/\.pk-footer-right[^{]*\{[^}]*display:\s*none/,
             "`.pk-footer-right` is no longer hidden in the ≤480px block. Match is against a " <>
               "real rule, not a bare mention — naming it in a comment must not satisfy this."

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

      for chunk <- wider_blocks, selector <- [".pk-footer-social", ".pk-footer-right"] do
        head = chunk |> String.split("@media", parts: 2) |> hd()

        refute head =~ ~r/#{Regex.escape(selector)}\s*\{[^}]*display:\s*none/,
               "A min-width media query hides `#{selector}`. The drawer only exists below " <>
                 "480px, so hiding the social/theme controls at any wider viewport strands " <>
                 "them with nowhere to reach them."
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
    # The queries below stay descendant-based on purpose — this test cares that each
    # control is still *inside* the cluster (the wrapping contract above depends on
    # what has to fit), not how deeply it nests. The exact child count is pinned by
    # FooterRhythmTest instead.
    test "the right cluster really does carry every control this contract assumes" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-footer-right .pk-footer-social") |> Enum.count() == 1
      assert doc |> LazyHTML.query(".pk-footer-right .pk-footer-toggle-tag") |> Enum.count() == 1
      assert doc |> LazyHTML.query(".pk-footer-right .pk-theme-toggle") |> Enum.count() == 1
    end

    # The legal line MOVED (debug footer-desktop-imbalance) — out of the right
    # cluster and into its own full-width band. The wrapping contract above was
    # re-measured for that move, exactly as the previous version of this test
    # demanded: zero horizontal overflow at 260/320/360/375/430/481/652/700/790/
    # 800/900/1024/1070/1280/1440/1920px, in both themes.
    #
    # What must not change is that it is still RENDERED, at every viewport width.
    # D-04 makes the attribution a compliance requirement, and the ≤480px block now
    # hides `.pk-footer-right` wholesale — so if the line ever drifted back into
    # that cluster, phones would silently lose it. This assertion is deliberately
    # scoped OUTSIDE the hidden cluster rather than merely "somewhere in the footer".
    test "the legal line renders outside the cluster that gets hidden on phones" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      # Two pieces since treatment D split the run so each edge gets an anchor —
      # copyright left, attribution right. Both must be in the band.
      assert doc |> LazyHTML.query(".pk-footer-legal .pk-footer-meta") |> Enum.count() == 2,
             "The BGG attribution + copyright line must render inside `.pk-footer-legal`, " <>
               "which is the only footer band shown at every viewport width."

      assert doc |> LazyHTML.query(".pk-footer-legal .pk-bgg-note") |> Enum.count() == 1,
             "The attribution anchor itself must be inside `.pk-footer-legal`. Counting " <>
               "`.pk-footer-meta` spans alone would still pass if the piece holding the BGG " <>
               "link were dropped and some other small-print span took its place."

      assert doc |> LazyHTML.query(".pk-footer-right .pk-footer-meta") |> Enum.count() == 0,
             "`.pk-footer-meta` is inside `.pk-footer-right`, which the ≤480px block hides " <>
               "entirely — that would drop a compliance-required attribution (D-04) on every " <>
               "phone. If the cluster is genuinely the right home again, the ≤480px hide rule " <>
               "has to go back to being per-child first."
    end
  end
end
