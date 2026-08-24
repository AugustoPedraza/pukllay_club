defmodule PukllayClubWeb.CoreComponentsTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PukllayClubWeb.CoreComponents

  describe "button/1 variants" do
    test "no variant keeps today's exact output (soft primary default)" do
      html = render_component(&CoreComponents.button/1, %{inner_block: []})

      assert html =~ ~s(class="btn btn-primary btn-soft")
    end

    test "\"primary\" variant keeps today's exact output (filled primary)" do
      html = render_component(&CoreComponents.button/1, %{variant: "primary", inner_block: []})

      assert html =~ ~s(class="btn btn-primary")
      refute html =~ "btn-soft"
      refute html =~ "btn-outline"
    end

    # Closes the "reserve btn-primary for a single page action" todo: a
    # non-filled, non-soft middle tier for repeated/secondary actions,
    # matching the outline treatment GamePreview's Ver detalles CTA
    # already uses live (game_preview.ex:114) so the two are the same
    # visual tier rather than two competing secondaries.
    test "\"secondary\" variant produces a daisyUI outline-tier class, not a filled fill" do
      html = render_component(&CoreComponents.button/1, %{variant: "secondary", inner_block: []})

      assert html =~ "btn-outline"
      assert html =~ "btn-primary"
      refute html =~ "btn-soft"
    end

    test "\"secondary\" is accepted by the variant attr's values: list without an ArgumentError" do
      html = render_component(&CoreComponents.button/1, %{variant: "secondary", inner_block: []})

      assert is_binary(html)
    end
  end
end
