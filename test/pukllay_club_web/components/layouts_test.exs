defmodule PukllayClubWeb.LayoutsTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PukllayClubWeb.Layouts

  describe "brand_logo/1" do
    test "renders the wordmark and tagline" do
      html = render_component(&Layouts.brand_logo/1, %{})

      assert html =~ "PUKLLAY CLUB"
      assert html =~ "JUEGOS DE MESA MODERNOS"
    end

    test "renders without a broken image reference when the isologo asset is absent" do
      refute File.exists?("priv/static/images/isologo.svg")

      html = render_component(&Layouts.brand_logo/1, %{})

      refute html =~ "isologo.svg"
    end
  end

  describe "app/1 header" do
    test "shows the brand wordmark and tagline" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ "PUKLLAY CLUB"
      assert html =~ "JUEGOS DE MESA MODERNOS"
    end

    test "no longer contains the generated Phoenix marketing links" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      refute html =~ "phoenixframework.org"
      refute html =~ "github.com/phoenixframework/phoenix"
      refute html =~ "phoenix.hexdocs.pm"
    end

    test "still renders the theme toggle" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ "phx:set-theme"
      assert html =~ ~s(data-phx-theme="light")
      assert html =~ ~s(data-phx-theme="dark")
      assert html =~ ~s(data-phx-theme="system")
    end

    test "still emits the px-4 sm:px-6 lg:px-8 header classes when fullbleed is not passed (01-11)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ "px-4 sm:px-6 lg:px-8"
      refute html =~ "pk-gutter"
    end

    test "swaps to the shared pk-gutter class and drops its own horizontal padding when fullbleed is true (01-11)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: [], fullbleed: true})

      assert html =~ "pk-gutter"
      refute html =~ "px-4 sm:px-6 lg:px-8"
    end

    test "emits no nav-hook attribute value when sticky is not passed (01-12)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      refute html =~ "phx-hook"
      refute html =~ "CatalogNav"
    end

    test "emits the sticky wrapper and the nav-hook attribute when sticky is true (01-12)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: [], sticky: true})

      assert html =~ "pk-header-sticky"
      assert html =~ "phx-hook"
      assert html =~ "CatalogNav"
    end
  end

  # Guards against reintroducing the 672px page cap described by the
  # design-system's page-container rule — page width belongs to each
  # LiveView's own container, not to Layouts.app's wrapper.
  describe "app/1 content wrapper" do
    test "imposes no 672px page-width cap, and still centers slot content" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      refute html =~ "max-w-2xl"
      assert html =~ "mx-auto"
    end
  end

  describe "brand_logo/1 hit target" do
    test "the wordmark link meets the app's 44px hit-target floor" do
      html = render_component(&Layouts.brand_logo/1, %{})

      assert html =~ "min-h-11"
    end
  end

  # Guards the 2026-08-18 banned-Tailwind-pattern todo: text-[10px] is an
  # arbitrary value and text-base-content/70 is an unmaintained holdover —
  # both explicitly banned by ui-design-system in favor of the app's
  # documented text-neutral muted-text convention.
  describe "brand_logo/1 tagline tokens" do
    test "renders the tagline through theme tokens, not banned arbitrary/opacity classes" do
      html = render_component(&Layouts.brand_logo/1, %{})

      refute html =~ "text-[10px]"
      refute html =~ "text-base-content/70"
      assert html =~ "text-neutral"
    end
  end

  describe "theme_toggle/1 accessible names and hit target" do
    test "each of the three buttons announces a distinct Spanish accessible name" do
      html = render_component(&Layouts.theme_toggle/1, %{})

      assert html =~ ~r/aria-label="[^"]*sistema[^"]*"/i
      assert html =~ ~r/aria-label="[^"]*claro[^"]*"/i
      assert html =~ ~r/aria-label="[^"]*oscuro[^"]*"/i
    end

    test "each button meets the app's 44px hit-target floor on both axes" do
      html = render_component(&Layouts.theme_toggle/1, %{})

      assert html |> String.split("min-h-11") |> length() == 4
      assert html |> String.split("min-w-11") |> length() == 4
    end
  end

  describe "root layout" do
    test "declares Spanish as the document language", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~s(lang="es")
    end
  end
end
