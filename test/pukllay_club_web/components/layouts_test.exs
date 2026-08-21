defmodule PukllayClubWeb.LayoutsTest do
  use PukllayClubWeb.ConnCase, async: true
  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias PukllayClubWeb.Layouts

  # Local test-only wrappers around Layouts.app/1 so we can exercise the
  # :crumb slot — render_component/2 can't build Phoenix.Component slot
  # data by hand, so a tiny ~H template that passes the slot through is
  # the standard way to test slot-bearing components.
  defp render_with_crumb(assigns) do
    ~H"""
    <Layouts.app flash={%{}}>
      <:crumb>
        <.link navigate="/">Ludoteca</.link>
        <span class="pk-crumb-sep">/</span>
        <span class="pk-crumb-current">Test Game</span>
      </:crumb>
      content
    </Layouts.app>
    """
  end

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

    # The header's content row (.pk-nav-inner) always uses the capped
    # max-w-7xl + pk-gutter recipe now, regardless of `fullbleed` — only
    # <main>'s own padding still toggles on that attr (page-shell.md's
    # content-width alignment rule: header, footer and every capped page
    # section share one max-width and one gutter source on the same
    # element). Scoped to the header element so <main>'s independent
    # px-4 sm:px-6 lg:px-8 (still present when fullbleed is not passed)
    # doesn't produce a false pass/fail on the wrong element.
    test "the header always uses the capped max-w-7xl + pk-gutter inner recipe, regardless of fullbleed (01-11 rework)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header")
        |> LazyHTML.to_html()

      assert header_html =~ "pk-gutter"
      assert header_html =~ "max-w-7xl"
      refute header_html =~ "px-4 sm:px-6 lg:px-8"
    end

    test "fullbleed drops <main>'s own horizontal padding while the header keeps the same capped recipe (01-11)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: [], fullbleed: true})

      assert html =~ "pk-gutter"
      assert html =~ "max-w-7xl"
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

  describe "app/1 footer (SHELL-01, Task 2 checkpoint content)" do
    test "renders the shared pk-footer element with exactly three footer link labels" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ "pk-footer"

      footer_links =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-footer-links a")

      assert Enum.count(footer_links) == 3

      link_labels = Enum.map(footer_links, &(&1 |> LazyHTML.text() |> String.trim()))
      assert link_labels == ["FAQ", "Contacto", "Juntadas"]
    end

    test "the footer link hrefs resolve to the three About-page anchor targets (D-02)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ ~s(href="/quienes-somos#faq")
      assert html =~ ~s(href="/quienes-somos#contacto")
      assert html =~ ~s(href="/quienes-somos#juntadas")
    end
  end

  describe "app/1 Sumate CTA (D-05)" do
    test "renders unconditionally with the ClubLinks WhatsApp href and rel=noopener noreferrer, even when no slot is passed" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ PukllayClubWeb.ClubLinks.whatsapp_group_url()
      assert html =~ "Sumate"
      assert html =~ ~s(rel="noopener noreferrer")
    end
  end

  describe "app/1 :crumb slot (Detalle header state)" do
    test "passing a crumb slot renders pk-nav-crumb" do
      html = render_component(&render_with_crumb/1, %{})

      assert html =~ "pk-nav-crumb"
      assert html =~ "Test Game"
    end

    test "passing no crumb slot renders no pk-nav-crumb" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      refute html =~ "pk-nav-crumb"
    end
  end

  describe "app/1 external anchor safety (T-01.1-03)" do
    test ~s(every target="_blank" anchor in the rendered shell also carries rel="noopener noreferrer") do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      blank_count = html |> String.split(~s(target="_blank")) |> length() |> Kernel.-(1)
      rel_count = html |> String.split(~s(rel="noopener noreferrer")) |> length() |> Kernel.-(1)

      assert blank_count > 0
      assert blank_count == rel_count
    end
  end
end
