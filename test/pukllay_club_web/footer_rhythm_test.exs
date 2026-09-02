defmodule PukllayClubWeb.FooterRhythmTest do
  # Guards the footer's SPACING HIERARCHY — the class of bug where a layout has
  # enough room and no overflow, yet reads as cluttered because proximity, the
  # only grouping cue available, is spent uniformly instead of in tiers.
  #
  # Motivating incident (debug session footer-desktop-overloaded): sketch 011
  # deliberately gives this footer no divider, so proximity is the ONLY way it
  # can express grouping. But `.pk-footer-left, .pk-footer-right` declared a
  # single `gap: 1.5rem` that served every tier at once, and 1.5rem was also
  # `.pk-footer-row`'s column-gap. Measured on the live app, EVERY within-cluster
  # gap was exactly 24.0px at every viewport from 375px to 1440px: the gap
  # separating the social icons from the copyright line was the same 24px that
  # separated the "Tema" label from the toggle it labels. Roughly nine atoms read
  # as one flat 620.8px run — the reported "too overloaded for being one line".
  #
  # A second, independent defect lived in the same rule set: `.pk-footer-row`'s
  # row-gap was 0.75rem while its clusters' gap was 1.5rem, so on every wrapped
  # line, same-group items sat 24px apart and different-group items only 12px
  # apart — proximity pointing backwards. That affected far more than phones:
  # the row wraps to two tiers at every width from 481px to ~1070px.
  #
  # Oracle type: derived (contract). The real proof is rendered geometry, which
  # ExUnit cannot observe; these assertions pin the token ordering that geometry
  # depends on. Every assertion here was verified RED against the pre-fix values
  # (item/list/group/cluster = 1.5/1/1.5/0.75rem), not merely green after them.
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias PukllayClubWeb.Layouts

  @css_path Path.expand("../../assets/css/app.css", __DIR__)

  defp source, do: File.read!(@css_path)

  # Comments are prose, not cascade. Matching selector names inside a comment is
  # a false pass — this file's sibling (footer_overflow_test) was silently
  # satisfied by a comment once, which is why stripping is done up front here.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  defp base_footer_block(src) do
    case Regex.run(~r/(?m)^\.pk-footer\s*\{([^}]*)\}/, strip_comments(src)) do
      [_, body] -> body
      nil -> flunk("No top-level `.pk-footer` rule found in assets/css/app.css")
    end
  end

  # Everything from the trailing narrow-viewport block to the end of the file.
  defp narrow_viewport_tail(src) do
    [_, tail] = String.split(strip_comments(src), "@media (max-width: 480px) {", parts: 2)
    tail
  end

  defp narrow_footer_block(src) do
    case Regex.run(~r/\.pk-footer\s*\{([^}]*)\}/, narrow_viewport_tail(src)) do
      [_, body] -> body
      nil -> flunk("The ≤480px block no longer re-declares `.pk-footer` spacing tokens")
    end
  end

  # The top-level `.pk-footer-legal` rule — i.e. the one that governs every width
  # from 481px up. Deliberately NOT the ≤480px override.
  defp legal_block(src) do
    case Regex.run(~r/(?m)^\.pk-footer-legal\s*\{([^}]*)\}/, strip_comments(src)) do
      [_, body] -> body
      nil -> flunk("No top-level `.pk-footer-legal` rule found in assets/css/app.css")
    end
  end

  # Everything BEFORE the trailing narrow-viewport block: the cascade that any
  # viewport wider than 480px actually gets.
  defp wide_viewport_source(src) do
    [head, _] = String.split(strip_comments(src), "@media (max-width: 480px) {", parts: 2)
    head
  end

  defp rem_token!(block, name) do
    case Regex.run(~r/--pk-footer-gap-#{name}:\s*([\d.]+)rem/, block) do
      [_, value] -> String.to_float(if String.contains?(value, "."), do: value, else: value <> ".0")
      nil -> flunk("Token `--pk-footer-gap-#{name}` is missing from this block")
    end
  end

  # Sibling to rem_token!/2 for the non-`-gap-` tokens (`--pk-footer-offset`,
  # `--pk-footer-pad-block`) added by quick task 260901-ty6. Kept separate
  # rather than generalizing rem_token!/2's regex, since the gap tiers and the
  # chrome tokens are read by different describe blocks with different naming
  # conventions (`gap-item`/`gap-list`/... vs `offset`/`pad-block`).
  defp footer_token!(block, name) do
    case Regex.run(~r/--pk-footer-#{name}:\s*([\d.]+)rem/, block) do
      [_, value] -> String.to_float(if String.contains?(value, "."), do: value, else: value <> ".0")
      nil -> flunk("Token `--pk-footer-#{name}` is missing from this block")
    end
  end

  describe "the spacing scale keeps its tiers in order" do
    test "the four tiers are strictly ordered item < list < group <= cluster" do
      block = base_footer_block(source())

      item = rem_token!(block, "item")
      list = rem_token!(block, "list")
      group = rem_token!(block, "group")
      cluster = rem_token!(block, "cluster")

      assert item < list,
             "The item tier (#{item}rem) must be tighter than the list tier (#{list}rem), or " <>
               "the \"Tema\" label stops reading as attached to the toggle it labels."

      assert list < group,
             "The list tier (#{list}rem) must be tighter than the group tier (#{group}rem), or " <>
               "sibling links space out as far as unrelated concerns do."

      assert group <= cluster,
             "The group tier (#{group}rem) must not exceed the cluster tier (#{cluster}rem). " <>
               "This is the inversion that made items in the SAME group sit further apart than " <>
               "items in DIFFERENT groups on every wrapped line."
    end

    test "the item tier is separated from the group tier by a visible margin, not a rounding error" do
      block = base_footer_block(source())
      item = rem_token!(block, "item")
      group = rem_token!(block, "group")

      # Boundary neighbour on the defect's equivalence class: the original bug was
      # ratio 1.0 (24px vs 24px). Anything near 1.0 re-creates it even though the
      # strict `<` above would still pass.
      assert group / item >= 2.0,
             "The group tier is only #{Float.round(group / item, 2)}x the item tier. Below 2x " <>
               "the eye cannot tell a binding gap from a separating one, which is the whole " <>
               "mechanism of this bug (it was exactly 1.0x before the fix)."
    end

    test "the ≤480px override retunes values without reordering the tiers" do
      narrow = narrow_footer_block(source())

      group = rem_token!(narrow, "group")
      cluster = rem_token!(narrow, "cluster")

      # Mobile is this project's primary surface, so the values are allowed to be
      # smaller there. The ORDER is what must survive the retune.
      assert group <= cluster,
             "The ≤480px block sets group #{group}rem > cluster #{cluster}rem, re-inverting " <>
               "proximity on the stacked mobile footer — brand/links would sit further apart " <>
               "than the legal line sits from them. This is the exact pre-fix mobile defect."
    end
  end

  describe "the footer consumes the scale instead of re-declaring literals" do
    test "the row and both clusters use the tokens, not hand-written gap values" do
      src = strip_comments(source())

      row = ~r/(?m)^\.pk-footer-row\s*\{([^}]*)\}/ |> Regex.run(src) |> Enum.at(1)
      clusters = ~r/(?m)^\.pk-footer-left,\n\.pk-footer-right\s*\{([^}]*)\}/ |> Regex.run(src) |> Enum.at(1)

      assert row =~ "gap: var(--pk-footer-gap-cluster)",
             "`.pk-footer-row` must take its gap from the shared token. A literal here is how " <>
               "the row-gap drifted to 0.75rem while the clusters sat at 1.5rem — two values " <>
               "for one rhythm, which is what inverted the proximity signal."

      assert clusters =~ "gap: var(--pk-footer-gap-group)",
             "`.pk-footer-left, .pk-footer-right` must take their gap from the shared token, " <>
               "so desktop and mobile provably share one scale rather than two that match today."

      refute row =~ ~r/gap:\s*[\d.]+rem\s+[\d.]+rem/,
             "`.pk-footer-row` declares a two-value gap. Separate row/column gaps are exactly " <>
               "how the wrapped layout ended up with a tighter between-group gap than " <>
               "within-group gap."
    end
  end

  # Quick task 260901-ty6. Guards the footer's VERTICAL chrome the same way
  # the describe blocks above guard its horizontal gap tiers: two new tokens
  # (--pk-footer-offset for .pk-footer's own margin-top, --pk-footer-pad-block
  # for .pk-footer-row's padding-top/padding-bottom) declared once in the base
  # rule and retuned — never re-declared as a literal — in the ≤480px block.
  #
  # Motivating measurement: before this change the mobile footer spent 48px
  # (.pk-footer's own top margin) + 24px + 24px (.pk-footer-row's own
  # top/bottom inner padding) = 96px of vertical chrome before any footer
  # content, on this project's primary surface.
  #
  # Oracle type: derived (contract), same as every other describe block in
  # this file — ExUnit cannot observe rendered geometry, so these pin the
  # token declarations the geometry depends on. Every assertion here was
  # verified RED against the pre-change stylesheet (a bare `margin-top: 3rem`
  # literal on `.pk-footer`, a bare `padding-top`/`padding-bottom: 1.5rem`
  # literal on `.pk-footer-row`, and no `--pk-footer-offset`/
  # `--pk-footer-pad-block` token anywhere in the file) before the CSS was
  # edited.
  describe "the mobile footer spends less vertical chrome than the desktop one" do
    test "the base .pk-footer rule declares both chrome tokens with a non-zero value" do
      block = base_footer_block(source())

      assert footer_token!(block, "offset") > 0,
             "`--pk-footer-offset` must be declared on the base `.pk-footer` rule with a " <>
               "non-zero value — it is what `margin-top` reads."

      assert footer_token!(block, "pad-block") > 0,
             "`--pk-footer-pad-block` must be declared on the base `.pk-footer` rule with a " <>
               "non-zero value — it is what `.pk-footer-row`'s padding-top/padding-bottom read."
    end

    test "margin-top and padding-top/padding-bottom read the tokens, not bare literals" do
      src = strip_comments(source())

      footer_block =
        case Regex.run(~r/(?m)^\.pk-footer\s*\{([^}]*)\}/, src) do
          [_, body] -> body
          nil -> flunk("No top-level `.pk-footer` rule found in assets/css/app.css")
        end

      row_block =
        case Regex.run(~r/(?m)^\.pk-footer-row\s*\{([^}]*)\}/, src) do
          [_, body] -> body
          nil -> flunk("No top-level `.pk-footer-row` rule found in assets/css/app.css")
        end

      assert footer_block =~ ~r/margin-top:\s*var\(--pk-footer-offset\)/,
             "`.pk-footer`'s `margin-top` must read `var(--pk-footer-offset)`, or the ≤480px " <>
               "retune below has nothing to change."

      assert row_block =~ ~r/padding-top:\s*var\(--pk-footer-pad-block\)/,
             "`.pk-footer-row`'s `padding-top` must read `var(--pk-footer-pad-block)`."

      assert row_block =~ ~r/padding-bottom:\s*var\(--pk-footer-pad-block\)/,
             "`.pk-footer-row`'s `padding-bottom` must ALSO read `var(--pk-footer-pad-block)`. " <>
               "Pinning only padding-top would admit a stylesheet where the bottom stayed a " <>
               "literal and the mobile retune half-applies."

      refute footer_block =~ ~r/margin-top:\s*[\d.]+rem/,
             "`.pk-footer` still carries a bare rem literal for `margin-top` alongside the " <>
               "token — that makes the token decorative rather than load-bearing."

      refute row_block =~ ~r/padding-(top|bottom):\s*[\d.]+rem/,
             "`.pk-footer-row` still carries a bare rem literal for `padding-top`/`padding-bottom` " <>
               "alongside the token."
    end

    test "the ≤480px block retunes both tokens strictly downward, with a non-zero offset" do
      base = base_footer_block(source())
      narrow = narrow_footer_block(source())

      base_offset = footer_token!(base, "offset")
      base_pad = footer_token!(base, "pad-block")
      mobile_offset = footer_token!(narrow, "offset")
      mobile_pad = footer_token!(narrow, "pad-block")

      # Compared numerically, not hardcoded — a future retune that keeps the
      # direction (mobile always <= desktop) stays green, and one that
      # inverts it fails, without needing this test edited every time.
      assert mobile_offset < base_offset,
             "The ≤480px `--pk-footer-offset` (#{mobile_offset}rem) must be strictly less than " <>
               "the base value (#{base_offset}rem), or the mobile retune does nothing."

      assert mobile_pad < base_pad,
             "The ≤480px `--pk-footer-pad-block` (#{mobile_pad}rem) must be strictly less than " <>
               "the base value (#{base_pad}rem), or the mobile retune does nothing."

      assert mobile_offset > 0,
             "The ≤480px `--pk-footer-offset` is #{mobile_offset}rem. A zero offset would butt " <>
               "the footer against the content above it, which is the one thing this change " <>
               "must not do — the footer must stay visibly separated by its own margin, on top " <>
               "of its own background/border surface change."
    end
  end

  describe "the theme control renders as one unit" do
    test "the Tema label and the toggle share a single wrapper" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-footer-right > .pk-footer-theme") |> Enum.count() == 1,
             "`.pk-footer-theme` must be a direct child of the right cluster — it is what lets " <>
               "the label and the buttons be bound at the item tier while the cluster separates " <>
               "concerns at the group tier."

      for selector <- [".pk-footer-theme > .pk-footer-toggle-tag", ".pk-footer-theme > .pk-theme-toggle"] do
        assert doc |> LazyHTML.query(selector) |> Enum.count() == 1,
               "`#{selector}` is missing. The label exists to make the control discoverable " <>
                 "(plan 01.1-08, sketch 017 Round 2); if it is separated from the toggle again, " <>
                 "it reads as a third unrelated concern beside the social icons."
      end
    end

    test "the right cluster carries exactly two concern-level children" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      children = doc |> LazyHTML.query(".pk-footer-right > *") |> Enum.count()

      # Four originally (social, label, toggle, meta); three after the label and
      # toggle were wrapped; two now that the legal line moved to its own row.
      # Two is load-bearing in three separate ways, so do not just bump this
      # number if it fails:
      #
      #   1. It matches `.pk-footer-left`'s two concerns — the cluster symmetry
      #      that resolved the 1.66x ink asymmetry (see the describe block below).
      #   2. Everything in here is a control that RELOCATES to the mobile drawer,
      #      which is the only reason the ≤480px block may hide the whole cluster
      #      with one `display: none` instead of hiding children individually. A
      #      third child that does not relocate would silently vanish on phones.
      #   3. It is the count the group tier was measured against.
      assert children == 2,
             "`.pk-footer-right` has #{children} direct children, expected 2 (social, theme). " <>
               "Every child of this cluster must be a control that has a mobile-drawer " <>
               "equivalent, because the ≤480px block hides the CLUSTER, not its children — " <>
               "anything else added here disappears on phones with no way to reach it. If a " <>
               "new concern is genuinely needed, re-measure the row and revisit that hide rule " <>
               "rather than only updating this number."
    end
  end

  # The structural half of debug footer-desktop-imbalance. Spacing tiers alone
  # did not settle the "overloaded" report: with the four-tier scale measurably
  # intact (re-verified on the live app — 8px item, 24px group, 32px cluster, no
  # overflow), the same complaint came back the same day. Proximity can only say
  # "these belong together"; it cannot make unlike things alike, and the right
  # cluster held two interactive utilities PLUS a passive compliance run.
  #
  # Measured at 1280px before this change: right cluster 604.81px carrying 3
  # concerns against left 364.11px carrying 2 (1.66x) with 247.08px of void
  # between them, and `.pk-footer-meta` alone was 59.9% of the right cluster's
  # ink mass while occupying 40.7% of its width — the footer's least important
  # content was its densest. After: 364.11 vs 335.06 (1.09x), two concerns each.
  #
  # Oracle type: derived (contract), same as the rest of this file — the proof is
  # rendered geometry, so these pin the structure and declarations that geometry
  # depends on.
  describe "the legal line is its own band, not a third concern in the right cluster" do
    test "the copyright/BGG line is a full-width row of its own, outside both clusters" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-footer-row > .pk-footer-legal") |> Enum.count() == 1,
             "`.pk-footer-legal` must be a direct child of `.pk-footer-row`. It is a peer of " <>
               "the two clusters, which is what lets the row's own row-gap (the cluster tier) " <>
               "separate it without a divider — sketch 011 forbids one."

      # Two pieces, not one: see the "the band's ink reaches both edges" describe
      # block below for why the count is load-bearing rather than incidental.
      assert doc |> LazyHTML.query(".pk-footer-legal .pk-footer-meta") |> Enum.count() == 2,
             "The copyright + BGG attribution must live inside `.pk-footer-legal`. D-04 makes " <>
               "the attribution a compliance requirement, so it has to stay rendered at every " <>
               "viewport width — this assertion is what proves it did not simply get dropped."

      assert doc |> LazyHTML.query(".pk-footer-right .pk-footer-meta") |> Enum.count() == 0,
             "`.pk-footer-meta` is back inside the right cluster. That is the exact structure " <>
               "this fix undid: a passive legal run sharing a proximity band with two " <>
               "interactive controls, which made the two \"peer\" clusters 1.66x apart in width."
    end

    test "both clusters carry the same number of concerns" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      left = doc |> LazyHTML.query(".pk-footer-left > *") |> Enum.count()
      right = doc |> LazyHTML.query(".pk-footer-right > *") |> Enum.count()

      assert left == right,
             "The footer's two clusters carry #{left} and #{right} concerns. Sketch 011 " <>
               "specified them as PEERS; an imbalance here is what the reported ink/void " <>
               "asymmetry actually was, and it is invisible to every spacing assertion above " <>
               "because each individual gap can be perfectly correct while the clusters they " <>
               "sit in are not comparable."
    end

    test "the break is width-based and survives the column flip at ≤480px" do
      src = strip_comments(source())

      legal =
        case Regex.run(~r/(?m)^\.pk-footer-legal\s*\{([^}]*)\}/, src) do
          [_, body] -> body
          nil -> flunk("No top-level `.pk-footer-legal` rule found in assets/css/app.css")
        end

      assert legal =~ ~r/width:\s*100%/,
             "`.pk-footer-legal` must declare `width: 100%`. That is the whole break " <>
               "mechanism: it makes the item's hypothetical main size the row's full content " <>
               "box, so a wrapping flex row can never fit it beside a cluster."

      # The direction trap. `flex-basis` is the MAIN size, so at ≤480px — where
      # `.pk-footer-row` becomes `flex-direction: column` — `flex-basis: 100%`
      # stops meaning "full width" and starts meaning "full height".
      refute legal =~ ~r/flex-basis:\s*100%/,
             "`.pk-footer-legal` uses `flex-basis: 100%` to force its line. flex-basis is the " <>
               "MAIN axis size, and the ≤480px block turns this row into a column — so that " <>
               "declaration silently becomes a height on this project's primary viewport. Use " <>
               "`width: 100%`, which is correct in both orientations."

      assert legal =~ ~r/display:\s*flex/,
             "`.pk-footer-legal` must be a flex container. As a plain block it generates an " <>
               "anonymous line box whose height is its OWN inherited 1rem strut, not the " <>
               "0.75rem line inside it — measured, that silently added 6px to the footer at " <>
               "every viewport including mobile."

      # Sketch 011: no divider anywhere in this footer. The row-gap does the work.
      refute legal =~ ~r/border/,
             "`.pk-footer-legal` declares a border. Sketch 011 gives this footer no dividers " <>
               "on purpose — separating the legal band is the row-gap's job, and a rule here " <>
               "would re-introduce exactly the \"two visual weights read as two footers\" " <>
               "problem that killed the original Mission Band design."
    end

    test "the ≤480px block returns the legal band to the centred stack" do
      narrow = narrow_viewport_tail(source())

      # The stacked footer is centred: `.pk-footer-row` keeps `align-items: center`,
      # which flips from "centre the clusters vertically" to "centre the stack
      # horizontally" when the direction changes. A width:100% box opts out of that
      # and left-aligns against the gutter while everything above it stays centred.
      assert narrow =~ ~r/\.pk-footer-legal\s*\{[^}]*width:\s*auto/,
             "The ≤480px block no longer resets `.pk-footer-legal`'s width to auto. Mobile is " <>
               "this project's primary surface and its footer is a CENTRED column — leaving " <>
               "the band full-width left-aligns the legal line while the brand and links above " <>
               "it stay centred (measured: x=14 instead of 39.13 at 320px)."
    end

    test "the emptied right cluster cannot spend a gap slot on the mobile stack" do
      narrow = narrow_viewport_tail(source())

      # `display: none` children are skipped by flex gap; an empty flex PARENT is
      # not. Once the legal line moved out, everything left in `.pk-footer-right`
      # relocates to the drawer at ≤480px, so the cluster renders as a zero-height
      # box that still consumes two 24px cluster gaps.
      assert narrow =~ ~r/\.pk-footer-right\s*\{[^}]*display:\s*none/,
             "The ≤480px block must hide `.pk-footer-right` itself, not only its children. " <>
               "A hidden child is skipped by flex `gap`, but an empty visible parent still " <>
               "takes a slot in the column — leaving it in would push the legal line 24px " <>
               "further down the mobile footer to fix a desktop complaint."
    end
  end

  # Treatment D of debug footer-desktop-imbalance, and the last open half of it.
  # Giving the legal line its own band (the describe block above) fixed the
  # cluster asymmetry but created a new one INSIDE the band: 241.75px of ink in a
  # 1216px band at 1280px — 19.88% filled, with the remaining 80.1% sitting as
  # ONE unbroken 974.25px void — so the band read as an orphaned fragment under a
  # dense utility row rather than as a peer band.
  #
  # The load-bearing measurement is that this is a FILL problem and not an
  # alignment one. Built as runtime variants and measured at 1280px, left, centre
  # and right all produce the SAME 19.88% fill; they relocate the void instead of
  # reducing it. Only splitting the run into two edge-anchored pieces changed the
  # number (-> 100%), and it is also the only candidate that stays correct in the
  # wrapped 481-790px band, where `space-between` on the ROW degenerates to
  # left-flush and the right/centre variants became the single odd element in the
  # footer — a defect completely invisible in a 1280px screenshot.
  #
  # Oracle type: derived (contract), as everywhere in this file — ExUnit cannot
  # observe rendered geometry, so these pin the declarations and structure the
  # measured geometry depends on.
  describe "the legal band's ink reaches both edges instead of stubbing at one" do
    test "the band holds two pieces, because space-between over one item is a no-op" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      pieces = doc |> LazyHTML.query(".pk-footer-legal > .pk-footer-meta") |> Enum.count()

      # This count IS the fix, not a rendering detail. `justify-content:
      # space-between` distributes free space BETWEEN items; with a single item
      # there is nothing to distribute and the declaration silently does nothing,
      # returning the band to the 19.88% stub with the CSS still looking correct.
      assert pieces == 2,
             "`.pk-footer-legal` has #{pieces} direct `.pk-footer-meta` children, expected 2 " <>
               "(copyright, attribution). Merging them back into one run makes " <>
               "`justify-content: space-between` a no-op — the band silently returns to a " <>
               "19.88%-filled stub while the stylesheet still reads as if it were anchored."
    end

    test "the two pieces are anchored to opposite edges, not just spread out" do
      legal = legal_block(source())

      assert legal =~ ~r/justify-content:\s*space-between/,
             "`.pk-footer-legal` must use `justify-content: space-between`. That is what puts " <>
               "one piece on each edge of the band, taking its fill from 19.88% to 100% and " <>
               "making the copyright flush with the brand above it while the attribution " <>
               "closes the row's right gutter."

      # Boundary neighbours on the defect's own equivalence class. The defect is
      # "the band's ink does not reach its edges", and a guard that only refuted
      # `flex-start` would still admit these three, which all LOOK like
      # distribution but leave a half- or third-gap outside the first and last
      # item. Measured on the live app at 1280px:
      #
      #   space-between  fill 100.00%   left edge  +0.00px   right edge  +0.00px
      #   space-around   fill  60.51%   left edge +240.11px
      #   space-evenly   fill  47.34%   left edge +320.14px
      #   center         fill  21.02%   left edge +480.22px
      #   flex-end       fill  21.02%   left edge +960.45px
      #
      # Only space-between anchors anything. The rest reproduce the reported
      # defect to varying degrees while reading as a deliberate choice in review.
      for near_miss <- ["space-around", "space-evenly", "center", "flex-end"] do
        refute legal =~ ~r/justify-content:\s*#{near_miss}/,
               "`.pk-footer-legal` uses `justify-content: #{near_miss}`. Measured at 1280px " <>
                 "that fills the band to at most 60.51% and pushes the copyright at least " <>
                 "240px off the brand edge it is supposed to line up with — the orphaned-stub " <>
                 "reading this treatment exists to remove. Only `space-between` anchors a " <>
                 "piece to each edge."
      end
    end

    test "the copyright and the attribution stay on one shared baseline however far apart they sit" do
      legal = legal_block(source())

      # This is a CONSTRAINT carried in from the first half of the same debug
      # session, not a style preference. The originally-reported defect was these
      # two runs sitting 5.00px apart vertically (an `inline-flex` anchor
      # synthesizing its baseline from an 18px logo). Treatment D then moved them
      # ~984px apart horizontally, which is precisely the arrangement where a
      # reintroduced vertical offset would be most visible and least explicable.
      #
      # `align-items: baseline` makes them share a baseline BY CONSTRUCTION at any
      # separation. The initial `stretch` default also happened to align them —
      # but only because both boxes measured exactly 18px tall, which is a
      # coincidence that the next font-size or logo-size change would silently
      # break. Verified on the live app: baseline delta 0.00px at every width from
      # 260px to 1920px, in both themes.
      assert legal =~ ~r/align-items:\s*baseline/,
             "`.pk-footer-legal` must declare `align-items: baseline`. The copyright and the " <>
               "BGG attribution now sit ~984px apart at 1280px, and this session OPENED with " <>
               "a report that those two were not aligned. Baseline alignment is what keeps " <>
               "them on one shared baseline structurally; any other value leaves it to the " <>
               "two boxes coincidentally measuring the same height."

      refute legal =~ ~r/align-items:\s*(center|flex-start|flex-end|stretch)/,
             "`.pk-footer-legal` overrides the baseline alignment. The two pieces have " <>
               "different content — one is plain text, the other carries a 14px image — so " <>
               "any box-edge alignment ties their text position to their box heights instead " <>
               "of their baselines, which is the exact class of bug (a synthesized baseline " <>
               "from an image box) that this debug session started from."
    end

    test "the band degrades by breaking between its pieces, not by bleeding out of them" do
      src = source()
      legal = legal_block(src)

      # `space-between` distributes FREE space, and there is none once the ≤480px
      # block shrink-wraps this band to `width: auto` — so without an explicit gap
      # the copyright and the attribution butt directly together on this project's
      # primary viewport. The gap is the floor in that state and a no-op in the
      # wide one.
      assert legal =~ ~r/gap:\s*var\(--pk-footer-gap-group\)/,
             "`.pk-footer-legal` must declare a gap from the group token. `space-between` has " <>
               "no free space to distribute once the ≤480px block shrink-wraps this band, so " <>
               "without it the copyright and the attribution touch on phones. The group tier " <>
               "is correct because these are two distinct concerns, not one unit."

      assert legal =~ ~r/flex-wrap:\s*wrap/,
             "`.pk-footer-legal` must wrap. Both pieces are `white-space: nowrap`, so below " <>
               "the width where they both fit, wrapping is what lets the band break BETWEEN " <>
               "them instead of shrinking their boxes while the text spills out of the " <>
               "gutter. See FooterOverflowTest for the measured 260px case."
    end

    test "the full-width band holds at every width above the mobile breakpoint" do
      wide = wide_viewport_source(source())

      # The wrapped 481-790px band is where the rejected treatments actually
      # broke, and it is invisible in the 1280px screenshot this was reported
      # from. There, `.pk-footer-row` itself wraps, so both clusters sit flush at
      # the left gutter and any legal band that is not full-width-with-both-edges-
      # anchored becomes the only non-flush element in the footer.
      #
      # The band gets that from `width: 100%`, which the ≤480px block deliberately
      # resets to `auto` for the centred mobile stack. That reset must stay scoped
      # to ≤480px: a `width: auto` anywhere in the wide cascade would collapse the
      # band to shrink-to-fit, at which point `space-between` has no free space
      # and both pieces bunch at the left — the 481-790px failure, silently.
      refute wide =~ ~r/\.pk-footer-legal[^{]*\{[^}]*width:\s*auto/,
             "A rule outside the ≤480px block resets `.pk-footer-legal` to `width: auto`. " <>
               "That collapses the band to shrink-to-fit, which leaves `space-between` no " <>
               "free space to distribute and bunches both pieces at the left gutter. It looks " <>
               "harmless at 1280px only if the band still happens to be full width there — " <>
               "the state it actually breaks is the wrapped 481-790px band."
    end

    test "the inline separator is gone, since the pieces no longer sit next to each other" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      band = doc |> LazyHTML.query(".pk-footer-legal") |> LazyHTML.text()

      # "·" joined two runs that were adjacent. At 1280px they are now ~984px
      # apart, where a separator reads as a dangling glyph trailing one of them.
      refute band =~ "·",
             "The legal band still contains the \"·\" separator. It existed to join the " <>
               "copyright and the attribution while they were one run; treatment D anchors " <>
               "them to opposite edges of the band, so it now renders as a stray glyph " <>
               "hanging off one piece with nothing on the other side of it."
    end
  end

  # Guards FOOTPRINT hierarchy between the right cluster's two icon rows — the
  # channel that four prior sessions on this footer never measured.
  #
  # Motivating incident (debug session footer-theme-toggle-balance). Sketch 014
  # stripped the toggle's chrome, footer-desktop-overloaded fixed its proximity,
  # and sketch 018 / quick task 260824-7mt faded its colour, shrank its glyph
  # 16px -> 14px and toned its active state. All of those move INK. Measured on
  # the live app, byte-identical at 481/768/1024/1280/1440px in both themes,
  # the BOX told the opposite story: `.pk-footer-social` and `.pk-theme-toggle`
  # were BOTH exactly 136.00px wide, so the subordinate control claimed the same
  # horizontal band as the entire four-icon social row — 175.06px (1.287x) once
  # the visible "Tema" label was counted — at 44x44 per button against social's
  # 28x28 (a 2.469x area ratio), while filling only 30.88% of that band with ink
  # against social's 82.35%.
  #
  # The trap worth naming: shrinking the glyph LOWERED the fill ratio inside an
  # unchanged box, so the ink fix made the control sparser rather than smaller.
  # That is why the user re-reported the same complaint the next day, and why
  # these assertions are about the BOX and never about the glyph.
  #
  # Oracle type: derived (contract), as everywhere in this file — ExUnit cannot
  # measure a rendered box, so these pin the declarations the geometry is
  # computed from. The geometric oracle itself was exercised via CDP against the
  # running app, before and after.
  describe "the theme control is subordinate to the social row by footprint, not just by ink" do
    # `.pk-footer-social a`'s square side. This is the number the theme buttons
    # must be measured against — deliberately read from the CSS rather than
    # hard-coded, so rescaling the social row cannot silently leave the theme
    # buttons behind at a value that used to be equal.
    defp social_box!(src) do
      case Regex.run(~r/(?m)^\.pk-footer-social a\s*\{([^}]*)\}/, strip_comments(src)) do
        [_, body] ->
          case Regex.run(~r/width:\s*([\d.]+)px/, body) do
            [_, v] -> String.to_integer(v)
            nil -> flunk("`.pk-footer-social a` no longer declares a px width to compare against")
          end

        nil ->
          flunk("No `.pk-footer-social a` rule found in assets/css/app.css")
      end
    end

    defp footer_theme_button_block!(src) do
      case Regex.run(
             ~r/\.pk-footer-theme \.pk-theme-toggle button\s*\{([^}]*)\}/,
             strip_comments(src)
           ) do
        [_, body] ->
          body

        nil ->
          flunk(
            "The footer-scoped `.pk-footer-theme .pk-theme-toggle button` rule is gone. " <>
              "Without it the buttons fall back to the shared component's `min-w-11`/`min-h-11` " <>
              "(44px), which makes the theme control exactly as wide as the whole social row " <>
              "(136px each, measured) and re-inverts the hierarchy."
          )
      end
    end

    defp px!(block, prop) do
      case Regex.run(~r/#{prop}:\s*([\d.]+)px/, block) do
        [_, v] -> String.to_integer(v)
        nil -> flunk("`#{prop}` is missing from the footer-scoped theme button rule")
      end
    end

    test "a footer theme button is never larger than a social link" do
      src = source()
      social = social_box!(src)
      block = footer_theme_button_block!(src)

      for prop <- ["min-width", "min-height"] do
        assert px!(block, prop) <= social,
               "A footer theme button's #{prop} exceeds `.pk-footer-social a`'s #{social}px. " <>
                 "The two icon rows in this cluster must share ONE sizing system; the defect " <>
                 "was that the LESS important concern had been given the LARGER box (44px vs " <>
                 "28px, a 2.469x area ratio)."
      end

      # `padding: 0` is load-bearing, and this assertion exists because a
      # mutation check found the gap: the buttons carry Tailwind's `p-2`, so
      # 14px of glyph + 16px of padding = 30px would beat a 28px `min-width` and
      # the box would render at 30px while every number above still read as
      # correct. A contract oracle that pins only the min-* pair is satisfied by
      # a layout that never shrank.
      assert block =~ ~r/padding:\s*0/,
             "The footer-scoped theme button rule dropped `padding: 0`. The component's `p-2` " <>
               "then wins the box back to 30px, and min-width silently stops being the " <>
               "constraint that decides the rendered size."
    end

    # The load-bearing assertion in this block. A bare `<=` on the per-button box
    # is not sufficient on its own, because the toggle could still be widened by
    # its gap or by gaining a fourth button. This compares the two rows as the
    # eye does: total declared footprint against total declared footprint.
    test "the theme control's total footprint stays clearly under the social row's" do
      src = source()
      social_box = social_box!(src)
      theme_box = px!(footer_theme_button_block!(src), "min-width")

      social_gap = 8
      theme_gap = 2

      # 4 social links / 3 theme buttons, as pinned by their own markup tests.
      social_row = 4 * social_box + 3 * social_gap
      theme_row = 3 * theme_box + 2 * theme_gap
      ratio = theme_row / social_row

      # The ceiling is 0.8, NOT a bare `< 1.0`. The shipped defect measured
      # exactly 1.000 (136.00px vs 136.00px), so a strict inequality alone would
      # still admit a 0.99 near-peer that reproduces the complaint in full — the
      # same reason the sibling tier test uses a `>= 2.0` ratio floor instead of
      # a strict `>`. 0.8 is the boundary neighbour that closes the class.
      assert ratio <= 0.8,
             "The theme control's footprint is #{Float.round(ratio, 3)}x the social row's " <>
               "(#{theme_row}px vs #{social_row}px). Anything at or near 1.0x reads as a PEER " <>
               "of the social links, not as subordinate to them — the shipped defect was " <>
               "exactly 1.000x. Social links outrank the theme switcher; the footprint has to " <>
               "say so."
    end

    test "the shrink is scoped to the footer, so the mobile drawer keeps its 44px touch targets" do
      src = strip_comments(source())

      # `theme_toggle/1` renders in BOTH the footer and `.pk-drawer-utility`.
      # Below 480px the footer copy is hidden and the drawer copy IS the touch
      # surface, so an unscoped shrink would silently drop every phone user's
      # theme control under the 44px floor locked by quick task 260821-dah.
      refute src =~ ~r/(?m)^\.pk-theme-toggle button\s*\{[^}]*min-width/,
             "A bare `.pk-theme-toggle button` rule now sets a min-width. That reaches the " <>
               "mobile drawer too, where the control is the actual touch target. Scope the " <>
               "override to `.pk-footer-theme` instead."

      html = render_component(&Layouts.theme_toggle/1, %{})

      assert html |> String.split("min-h-11") |> length() == 4,
             "The shared component dropped `min-h-11`. The footer overrides the box in CSS " <>
               "precisely so these utilities can stay on the markup for the drawer's benefit."
    end

    test "the underline insets are tokens, so resizing the box cannot leave them stranded" do
      src = strip_comments(source())

      # Both of these started as `src =~ token` / `src =~ "var(token)"`, and a
      # mutation check caught them SURVIVING: the footer scope declares the same
      # token name and `right:` consumes the same var, so a bare substring match
      # was still satisfied after deleting the base declaration or hardcoding
      # `left`. A file-wide `=~` is not an assertion about the rule you mean.
      base =
        case Regex.run(~r/(?m)^\.pk-theme-toggle \{([^}]*)\}/, src) do
          [_, body] -> body
          nil -> flunk("No base `.pk-theme-toggle` rule found in assets/css/app.css")
        end

      underline =
        case Regex.run(~r/\[data-theme-source[^{]*::after[^{]*\{([^}]*)\}/, src) do
          [_, body] -> body
          nil -> flunk("No active-state `::after` underline rule found in assets/css/app.css")
        end

      for token <- ["--pk-toggle-underline-inset", "--pk-toggle-underline-bottom"] do
        assert base =~ "#{token}:",
               "`#{token}` is missing from the BASE `.pk-theme-toggle` rule. The footer scope " <>
                 "re-declares it, so the footer would still look right while the drawer's 44px " <>
                 "button lost the value entirely — the exact asymmetry this token exists to stop."
      end

      # Every inset side must read the token. Checking one side is not enough:
      # hardcoding just `left` renders the footer's underline asymmetrically
      # (8px one side, 5px the other) and no other assertion here would notice.
      for {prop, token} <- [
            {"left", "--pk-toggle-underline-inset"},
            {"right", "--pk-toggle-underline-inset"},
            {"bottom", "--pk-toggle-underline-bottom"}
          ] do
        assert underline =~ "#{prop}: var(#{token})",
               "The underline's `#{prop}` no longer reads `var(#{token})`. A literal here " <>
                 "renders at the 44px button's value on the footer's 28px one."
      end

      assert src =~ ~r/\.pk-footer-theme \.pk-theme-toggle\s*\{[^}]*--pk-toggle-underline-inset/,
             "The footer scope no longer retunes the underline inset. At the 44px default of " <>
               "8px it renders 12px wide under a 14px glyph — narrower than the thing it marks."

      # The specificity trap this indirection exists to avoid, pinned so nobody
      # "simplifies" it back. The active-state selectors are (0,4,2); a plain
      # `.pk-footer-theme .pk-theme-toggle button::after` override is (0,2,2)
      # and silently loses. That was observed happening, not theorised.
      refute src =~ ~r/\.pk-footer-theme \.pk-theme-toggle button::after\s*\{[^}]*left:/,
             "The underline is being overridden through a `button::after` rule again. That " <>
               "selector is (0,2,2) and loses to the active-state rules' (0,4,2) — it will " <>
               "compile, look correct in the diff, and do nothing. Retune the tokens instead."
    end

    test "the Tema label is hidden visually but still names the control for assistive tech" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      tag = LazyHTML.query(doc, ".pk-footer-theme .pk-footer-toggle-tag")
      assert Enum.count(tag) == 1

      classes = tag |> LazyHTML.attribute("class") |> List.first()

      assert classes =~ "sr-only",
             "The footer's \"Tema\" label is visible again. It was 31.06px of text plus an 8px " <>
               "gap sitting between two icon rows, and it is what took the theme concern to " <>
               "1.287x the social row's width. Vercel's Geist ships the same control in a " <>
               "footer with an sr-only <legend> and no visible text."

      # Hiding it is only acceptable BECAUSE the string was promoted to the
      # group's accessible name. If a later edit deletes the label, this fails
      # rather than quietly leaving the control unnamed.
      wrapper = LazyHTML.query(doc, ".pk-footer-theme")
      assert wrapper |> LazyHTML.attribute("role") |> List.first() == "group"

      labelledby = wrapper |> LazyHTML.attribute("aria-labelledby") |> List.first()
      id = tag |> LazyHTML.attribute("id") |> List.first()

      assert labelledby == id and is_binary(id),
             "`.pk-footer-theme`'s aria-labelledby does not resolve to the \"Tema\" span. " <>
               "The label may only be hidden while it still supplies the group's accessible " <>
               "name — otherwise this is a plain accessibility regression, not a visual fix."
    end
  end
end
