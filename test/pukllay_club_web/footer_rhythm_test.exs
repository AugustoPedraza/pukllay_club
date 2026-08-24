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

  defp narrow_footer_block(src) do
    [_, tail] = String.split(strip_comments(src), "@media (max-width: 480px) {", parts: 2)

    case Regex.run(~r/\.pk-footer\s*\{([^}]*)\}/, tail) do
      [_, body] -> body
      nil -> flunk("The ≤480px block no longer re-declares `.pk-footer` spacing tokens")
    end
  end

  defp rem_token!(block, name) do
    case Regex.run(~r/--pk-footer-gap-#{name}:\s*([\d.]+)rem/, block) do
      [_, value] -> String.to_float(if String.contains?(value, "."), do: value, else: value <> ".0")
      nil -> flunk("Token `--pk-footer-gap-#{name}` is missing from this block")
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

    test "the right cluster carries exactly three concern-level children" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      children = doc |> LazyHTML.query(".pk-footer-right > *") |> Enum.count()

      # Was four before the fix (social, label, toggle, meta). Three is the number
      # of actual CONCERNS; a fourth means something was added without being
      # grouped, which is precisely how this bug accreted in the first place.
      assert children == 3,
             "`.pk-footer-right` has #{children} direct children, expected 3 (social, theme, " <>
               "meta). This cluster reached the reported \"overloaded\" state by gaining a " <>
               "concern without its spacing being revisited — if a new one is genuinely needed, " <>
               "re-measure the row rather than only updating this number."
    end
  end
end
