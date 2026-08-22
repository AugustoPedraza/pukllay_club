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

  # Local wrapper for exercising the :nav_search slot / search-morph
  # (01.1-08) — same render_component/2 slot-testing pattern as
  # render_with_crumb/1 above.
  defp render_with_nav_search(assigns) do
    assigns = assign_new(assigns, :search_expanded, fn -> false end)

    ~H"""
    <Layouts.app flash={%{}} search_expanded={@search_expanded}>
      <:nav_search>
        <input type="text" name="q" id="test-search-input" />
      </:nav_search>
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
  end

  describe "brand_logo/1 theme-aware isologo pair (260821-v7q)" do
    test "renders exactly two <img> elements inside the <a> when both marks are present" do
      html = render_component(&Layouts.brand_logo/1, %{})

      imgs =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("a img")

      assert Enum.count(imgs) == 2
    end

    test "the light mark carries dark:hidden and the dark mark carries hidden dark:block, both width=36 alt=\"\"" do
      html = render_component(&Layouts.brand_logo/1, %{})

      [light_img_html, dark_img_html] =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("a img")
        |> Enum.map(&LazyHTML.to_html/1)

      assert light_img_html =~ "isologo-light.png"
      assert light_img_html =~ ~s(class="dark:hidden")
      assert light_img_html =~ ~s(width="36")
      assert light_img_html =~ ~s(alt="")

      assert dark_img_html =~ "isologo-dark.png"
      assert dark_img_html =~ ~s(class="hidden dark:block")
      assert dark_img_html =~ ~s(width="36")
      assert dark_img_html =~ ~s(alt="")
    end

    test "both marks also render inside the footer's .pk-footer-left cluster" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      footer_left_imgs =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-footer-left img")

      assert Enum.count(footer_left_imgs) == 2
    end

    test "forcing isologo? false renders no <img> and keeps the wordmark + default tagline" do
      html = render_component(&Layouts.brand_logo/1, %{isologo?: false})

      imgs =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("img")

      assert Enum.empty?(imgs)
      assert html =~ "PUKLLAY CLUB"
      assert html =~ "JUEGOS DE MESA MODERNOS"
    end

    test "both mark paths satisfy File.exists?/1 (gate truthfulness)" do
      assert File.exists?("priv/static/images/isologo-light.png")
      assert File.exists?("priv/static/images/isologo-dark.png")
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

    # Theme toggle relocated to the footer (sketch 017 Round 2, plan
    # 01.1-08 Task 3) — scoped to the footer subtree, and a companion
    # asserts the header ROW (.pk-nav-inner, not the whole #app-header —
    # plan 01.1-09's mobile drawer renders its own toggle copy inside
    # #app-header, so a wider assertion would false-fail one wave later)
    # carries none of it.
    test "still renders the theme toggle, now inside the footer" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      footer_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("footer")
        |> LazyHTML.to_html()

      assert footer_html =~ "phx:set-theme"
      assert footer_html =~ ~s(data-phx-theme="light")
      assert footer_html =~ ~s(data-phx-theme="dark")
      assert footer_html =~ ~s(data-phx-theme="system")
    end

    test "the header row (.pk-nav-inner) carries no data-phx-theme attribute at all" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      nav_inner_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-nav-inner")
        |> LazyHTML.to_html()

      refute nav_inner_html =~ "data-phx-theme"
    end

    test "the theme toggle wrapper carries no card or border class, and the footer toggle tag renders" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      footer_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("footer")
        |> LazyHTML.to_html()

      refute footer_html =~ ~s(class="card)
      refute footer_html =~ "border-base-300"
      assert footer_html =~ "pk-footer-toggle-tag"
      assert footer_html =~ "Tema"
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

  # Header cluster rework (quick task 260822-2v9): the header element carries
  # the horizontal-padding-zeroing utility alongside navbar, and the brand
  # wrapper no longer swallows the row's free space. The .pk-nav-actions
  # container this describe block originally covered (grouping the CTA and
  # theme toggle) is superseded by plan 01.1-08 — the CTA left the header
  # entirely (Task 2, see "app/1 join CTA is not a shell element" below) and
  # the wrapper itself was removed along with it. Scoped to #app-header via
  # LazyHTML so main/footer markup can't produce a false pass (both also
  # render a theme toggle / brand lockup elsewhere).
  describe "app/1 header cluster rework (260822-2v9, .pk-nav-actions superseded by 01.1-08)" do
    test "the header element carries px-0 alongside navbar (kills the competing padding source)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header header")
        |> LazyHTML.to_html()

      assert header_html =~ ~r/class="[^"]*\bnavbar\b[^"]*\bpx-0\b[^"]*"/
    end

    # Rewritten (01.1-08 Task 3) to query every element's class attribute
    # inside the header subtree and assert none of them carries flex-1 as a
    # whitespace-delimited class token — the original assertion
    # (`refute header_html =~ ~s(class="flex-1")`) only ever passed because
    # brand_logo/1's anchor class string was longer than the exact literal,
    # not because flex-1 was actually absent (the real bug this plan fixes:
    # the anchor still carried flex-1 while its wrapper had already moved to
    # flex-initial).
    test "no element inside the header subtree carries flex-1 as a class token" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      classes =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header [class]")
        |> LazyHTML.attribute("class")

      refute Enum.any?(classes, fn class -> "flex-1" in String.split(class) end)
      assert html =~ "flex-initial"
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

  # Footer's left cluster reuses brand_logo/1 but must not repeat the
  # header's brand subtitle (260821-umm). The footer overrides the tagline
  # with the About hero's <h1> text, verbatim including the accent
  # (Conectá, not Conecta — see the plan's Correction note).
  describe "app/1 footer left cluster tagline (260821-umm)" do
    test "the footer's left cluster renders the About hero tagline" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      footer_left_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-footer-left")
        |> LazyHTML.to_html()

      assert footer_left_html =~ "Conectá jugando"
    end

    test "the footer's left cluster does not repeat the header's brand subtitle" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      footer_left_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-footer-left")
        |> LazyHTML.to_html()

      refute footer_left_html =~ "JUEGOS DE MESA MODERNOS"
    end

    test "the header's brand lockup still renders its original subtitle, unchanged" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header")
        |> LazyHTML.to_html()

      assert header_html =~ "JUEGOS DE MESA MODERNOS"
      refute header_html =~ "Conectá jugando"
    end

    test "brand_logo/1 called with no attrs still renders the header subtitle (default preserved)" do
      html = render_component(&Layouts.brand_logo/1, %{})

      assert html =~ "JUEGOS DE MESA MODERNOS"
    end

    test "the footer's left cluster renders both theme marks with their dark: variant classes" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      footer_left_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-footer-left")
        |> LazyHTML.to_html()

      assert footer_left_html =~ "isologo-light.png"
      assert footer_left_html =~ ~s(class="dark:hidden")
      assert footer_left_html =~ "isologo-dark.png"
      assert footer_left_html =~ ~s(class="hidden dark:block")
    end
  end

  describe "sumate_cta/1 (D-05 superseded, plan 01.1-08)" do
    test "renders the ClubLinks WhatsApp href with target=_blank and rel=noopener noreferrer" do
      html = render_component(&Layouts.sumate_cta/1, %{})

      assert html =~ PukllayClubWeb.ClubLinks.whatsapp_group_url()
      assert html =~ "Sumate"
      assert html =~ ~s(target="_blank")
      assert html =~ ~s(rel="noopener noreferrer")
    end

    # Sketch 013-E: outline at rest, filling on hover — the same classes as
    # CoreComponents.button/1's "secondary" variant, applied directly since
    # button/1's :rest global attr list doesn't carry target/rel through.
    test "carries the outline-at-rest button classes and the 48px height utility" do
      html = render_component(&Layouts.sumate_cta/1, %{})

      assert html =~ "btn-outline"
      assert html =~ "btn-primary"
      assert html =~ "min-h-12"
      refute html =~ "btn-sm"
    end

    test "is now public (no longer a private header-only function)" do
      assert function_exported?(Layouts, :sumate_cta, 1)
    end
  end

  describe "app/1 join CTA is not a shell element (D-05 superseded, plan 01.1-08)" do
    test "the #app-header subtree contains neither the CTA label nor the WhatsApp URL" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header")
        |> LazyHTML.to_html()

      refute header_html =~ "Sumate"
      refute header_html =~ PukllayClubWeb.ClubLinks.whatsapp_group_url()
    end

    test ".pk-nav-actions is absent from the rendered document" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      refute html =~ "pk-nav-actions"
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

  describe "app/1 search-morph (01.1-08)" do
    test "the morph does not render when no nav_search slot is passed" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      refute html =~ "pk-search-morph"
    end

    test "the morph renders the toggle and close buttons with the slot content between them" do
      html = render_component(&render_with_nav_search/1, %{})

      morph_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-search-morph")
        |> LazyHTML.to_html()

      assert morph_html =~ "pk-search-morph-toggle"
      assert morph_html =~ "test-search-input"
      assert morph_html =~ "pk-search-morph-close"

      toggle_pos = morph_html |> :binary.match("pk-search-morph-toggle") |> elem(0)
      slot_pos = morph_html |> :binary.match("test-search-input") |> elem(0)
      close_pos = morph_html |> :binary.match("pk-search-morph-close") |> elem(0)

      assert toggle_pos < slot_pos
      assert slot_pos < close_pos
    end

    test "the toggle and close buttons each carry a distinct Spanish aria-label" do
      html = render_component(&render_with_nav_search/1, %{})

      assert html =~ ~s(aria-label="Buscar")
      assert html =~ ~s(aria-label="Cerrar búsqueda")
    end

    test "the close button is tabindex=\"-1\" at rest" do
      html = render_component(&render_with_nav_search/1, %{})

      close_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-search-morph-close")
        |> LazyHTML.to_html()

      assert close_html =~ ~s(tabindex="-1")
    end

    test "data-search-expanded reflects the search_expanded attr" do
      html_false = render_component(&render_with_nav_search/1, %{search_expanded: false})
      html_true = render_component(&render_with_nav_search/1, %{search_expanded: true})

      assert html_false =~ ~s(data-search-expanded="false")
      assert html_true =~ ~s(data-search-expanded="true")
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
