defmodule PukllayClubWeb.NavDrawerStackingTest do
  @moduledoc """
  Regression coverage for WINDOWS #4 (`.planning/debug/resolved/about-logo-over-nav-drawer.md`):
  on `/quienes-somos` at 390px, the mobile nav drawer used to render as a `position: fixed`
  descendant of `#app-header.pk-header-sticky` (`position: sticky; z-index: 50`). Since sticky
  creates a stacking context, the drawer's own `z-index: 61` only ordered it INSIDE the header —
  the whole header (drawer included) composited into the root at effective z 50, below the About
  page's root-context floating isologo (`#pk-about-morph-mark`, z 60) and the flash toast (z-50).

  No other test in this codebase checks cross-component z-order or markup ancestry together — the
  existing per-rule CSS contract tests (e.g. `catalog_show_test.exs`'s `.pk-lightbox-chevron`
  check) only pin ONE selector's own z-index in isolation, never compare it against a competing
  root-context layer defined in a completely different component. This module closes that gap by
  parsing every competitor's z-index directly from source (never hardcoding a "known good" number
  twice) and asserting both the drawer's DOM placement (a page-level sibling of `#app-header`,
  never a descendant of it) and its effective root-context z-order.
  """

  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PukllayClubWeb.Layouts

  @css_path Path.expand("../../../assets/css/app.css", __DIR__)
  @core_components_path Path.expand(
                          "../../../lib/pukllay_club_web/components/core_components.ex",
                          __DIR__
                        )

  defp css_source, do: File.read!(@css_path)

  # Same non-greedy, dotall block-comment stripper as
  # layouts_test.exs's `app_css_without_comments/0` — must run BEFORE any rule-body match so a
  # commented-out example z-index (or a stale rationale mentioning a selector name) can never be
  # mistaken for a live declaration.
  defp strip_comments(css), do: Regex.replace(~r/\/\*.*?\*\//s, css, "")

  # Column-0 anchored, multiline — same idiom as catalog_show_test.exs's `.pk-lightbox-chevron`
  # rule-body regex. Anchoring to column 0 deliberately skips the INDENTED copies of `.pk-drawer` /
  # `.pk-drawer-backdrop` inside the `@media (max-width: 480px)` block (those only toggle
  # `display`, they carry no z-index, and being indented they can never match `^`). Requiring
  # optional whitespace then `{` directly after the selector means `.pk-drawer` can never match
  # `.pk-drawer-backdrop {` (next char is `-`, not whitespace/brace), and `.pk-sheet` can never
  # match `.pk-sheet-backdrop {` for the same reason.
  defp rule_body!(css, selector) do
    pattern = ~r/(?m)^#{Regex.escape(selector)}\s*\{([^}]*)\}/s

    case Regex.run(pattern, css) do
      [_, body] -> body
      nil -> flunk_missing_rule(selector)
    end
  end

  defp z_index!(body, selector) do
    case Regex.run(~r/z-index:\s*(\d+)/, body) do
      [_, value] ->
        String.to_integer(value)

      nil ->
        raise ExUnit.AssertionError,
          message:
            "`#{selector}` rule was found in assets/css/app.css but declares no numeric " <>
              "z-index — WINDOWS #4's stacking-context guard cannot compare it against " <>
              "competing root-context layers without one."
    end
  end

  defp flunk_missing_rule(selector) do
    raise ExUnit.AssertionError,
      message:
        "No top-level `#{selector} { ... }` rule found in assets/css/app.css — WINDOWS #4's " <>
          "stacking-context guard (nav_drawer_stacking_test.exs) cannot verify cross-component " <>
          "z-order without it. If this selector was renamed/removed, update the guard, don't " <>
          "silently skip the check."
  end

  defp toast_z_index! do
    core_src = File.read!(@core_components_path)

    case Regex.run(~r/toast toast-top toast-end z-(\d+)/, core_src) do
      [_, value] ->
        String.to_integer(value)

      nil ->
        raise ExUnit.AssertionError,
          message:
            "Could not find the flash toast's `toast toast-top toast-end z-NN` class string " <>
              "in core_components.ex — WINDOWS #4's guard needs this latent same-class-trap " <>
              "competitor's z-index parsed from source, not hardcoded."
    end
  end

  describe "drawer markup ancestry (WINDOWS #4)" do
    defp assert_drawer_ancestry!(sticky) do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: [], sticky: sticky})
      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query("#pk-nav-drawer") |> Enum.count() == 1,
             "Expected exactly one #pk-nav-drawer (sticky: #{sticky})"

      assert doc |> LazyHTML.query(".pk-drawer-backdrop") |> Enum.count() == 1,
             "Expected exactly one .pk-drawer-backdrop (sticky: #{sticky})"

      assert doc |> LazyHTML.query("#app-header #pk-nav-drawer") |> Enum.count() == 0,
             "WINDOWS #4: the drawer must NEVER be a descendant of #app-header — " <>
               "#app-header.pk-header-sticky's z-index: 50 forms a stacking context that " <>
               "capped the drawer's effective root z at 50, below .pk-about-morph-mark's 60 " <>
               "(sticky: #{sticky})"

      assert doc |> LazyHTML.query("#app-header .pk-drawer-backdrop") |> Enum.count() == 0,
             "WINDOWS #4: the backdrop must NEVER be a descendant of #app-header, same " <>
               "stacking-context reason as the drawer panel (sticky: #{sticky})"

      assert doc |> LazyHTML.query("body > #pk-nav-drawer") |> Enum.count() == 1,
             "The drawer must be a direct child of body (a page-level sibling of " <>
               "#app-header, like #connection-status) — not nested in <main>, <footer>, or " <>
               "any wrapper element (sticky: #{sticky})"

      assert doc |> LazyHTML.query("body > .pk-drawer-backdrop") |> Enum.count() == 1,
             "The backdrop must be a direct child of body, same as the drawer panel " <>
               "(sticky: #{sticky})"
    end

    test "with sticky: false, the drawer and backdrop render once each, as page-level siblings of #app-header (never a descendant of it)" do
      assert_drawer_ancestry!(false)
    end

    test "with sticky: true, the drawer and backdrop render once each, as page-level siblings of #app-header (never a descendant of it)" do
      assert_drawer_ancestry!(true)
    end

    test "the backdrop carries id=\"pk-nav-drawer-backdrop\" and the drawer still carries role=dialog, aria-modal=true and inert at rest" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      backdrop_html = doc |> LazyHTML.query("#pk-nav-drawer-backdrop") |> LazyHTML.to_html()

      assert backdrop_html =~ ~s(class="pk-drawer-backdrop"),
             "The backdrop must carry id=\"pk-nav-drawer-backdrop\" (the .CatalogNav hook's " <>
               "by-id lookup target now that it lives outside this.el) AND its existing " <>
               ".pk-drawer-backdrop class"

      drawer_html = doc |> LazyHTML.query("#pk-nav-drawer") |> LazyHTML.to_html()

      assert drawer_html =~ ~s(role="dialog")
      assert drawer_html =~ ~s(aria-modal="true")
      assert drawer_html =~ "inert"
    end
  end

  describe "cross-component z-order, parsed from source (WINDOWS #4)" do
    setup do
      %{css: strip_comments(css_source())}
    end

    test "the drawer backdrop and panel outrank .pk-about-morph-mark, .pk-header-sticky and the flash toast", %{
      css: css
    } do
      backdrop_z = css |> rule_body!(".pk-drawer-backdrop") |> z_index!(".pk-drawer-backdrop")
      panel_z = css |> rule_body!(".pk-drawer") |> z_index!(".pk-drawer")
      mark_z = css |> rule_body!(".pk-about-morph-mark") |> z_index!(".pk-about-morph-mark")
      header_z = css |> rule_body!(".pk-header-sticky") |> z_index!(".pk-header-sticky")
      toast_z = toast_z_index!()

      assert backdrop_z > mark_z,
             "WINDOWS #4: .pk-drawer-backdrop (#{backdrop_z}) must outrank " <>
               ".pk-about-morph-mark (#{mark_z}) — the About page's docked floating isologo, " <>
               "a root-context layer that used to paint over the drawer while it stacked " <>
               "inside the z-50 header context"

      assert backdrop_z > header_z,
             "WINDOWS #4: .pk-drawer-backdrop (#{backdrop_z}) must outrank " <>
               ".pk-header-sticky (#{header_z}) itself, or the drawer risks re-confining to " <>
               "the header's stacking context again"

      assert backdrop_z > toast_z,
             "WINDOWS #4: .pk-drawer-backdrop (#{backdrop_z}) must outrank the flash toast's " <>
               "z-#{toast_z} (core_components.ex) — the latent same-class-trap competitor that " <>
               "paints over the open drawer on every route, not just About"

      assert panel_z > backdrop_z,
             "The drawer panel (#{panel_z}) must outrank its own backdrop (#{backdrop_z}), " <>
               "panel above backdrop"
    end

    test "both drawer z-indexes sit strictly inside the 500-700 overlay band, colliding with none of .pk-portal / .pk-sheet-backdrop / .pk-sheet / .pk-lightbox",
         %{css: css} do
      backdrop_z = css |> rule_body!(".pk-drawer-backdrop") |> z_index!(".pk-drawer-backdrop")
      panel_z = css |> rule_body!(".pk-drawer") |> z_index!(".pk-drawer")
      portal_z = css |> rule_body!(".pk-portal") |> z_index!(".pk-portal")
      sheet_backdrop_z = css |> rule_body!(".pk-sheet-backdrop") |> z_index!(".pk-sheet-backdrop")
      sheet_z = css |> rule_body!(".pk-sheet") |> z_index!(".pk-sheet")
      lightbox_z = css |> rule_body!(".pk-lightbox") |> z_index!(".pk-lightbox")

      competitors = [
        {".pk-portal", portal_z},
        {".pk-sheet-backdrop", sheet_backdrop_z},
        {".pk-sheet", sheet_z},
        {".pk-lightbox", lightbox_z}
      ]

      for {name, z} <- [{".pk-drawer-backdrop", backdrop_z}, {".pk-drawer", panel_z}] do
        assert z > portal_z and z < lightbox_z,
               "#{name}'s z-index (#{z}) must sit strictly between .pk-portal (#{portal_z}) " <>
                 "and .pk-lightbox (#{lightbox_z}) — the 500-700 overlay band the user chose " <>
                 "for the re-tiered drawer"

        for {competitor_name, competitor_z} <- competitors do
          refute z == competitor_z,
                 "#{name}'s z-index (#{z}) must not collide with #{competitor_name}'s " <>
                   "(#{competitor_z})"
        end
      end
    end
  end
end
