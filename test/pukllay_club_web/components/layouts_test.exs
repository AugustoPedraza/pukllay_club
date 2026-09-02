defmodule PukllayClubWeb.LayoutsTest do
  use PukllayClubWeb.ConnCase, async: true
  use Phoenix.Component

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

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

  # Local wrapper for exercising the :subnav slot (G-01.2-8, plan 01.2-15) —
  # #app-subnav only renders when the slot is non-empty (`:if={@subnav !=
  # []}`), and the connection-status bar's document-position test needs a
  # real #app-subnav element to compare offsets against.
  defp render_with_subnav(assigns) do
    ~H"""
    <Layouts.app flash={%{}}>
      <:subnav>
        <div id="test-subnav-content">chips</div>
      </:subnav>
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

    test "the footer's .pk-footer-left cluster renders no mark (D-A, 260823-snj)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      footer_left_imgs =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-footer-left img")

      assert Enum.empty?(footer_left_imgs)
    end

    test "the header still renders exactly two <img> marks (header-only, not removed, 260823-snj)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      header_imgs =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header img")

      assert Enum.count(header_imgs) == 2
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

  describe "brand_logo/1 mark attr (260823-snj)" do
    test "mark: false renders no <img> but still renders the wordmark" do
      html = render_component(&Layouts.brand_logo/1, %{mark: false})

      imgs =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("img")

      assert Enum.empty?(imgs)
      assert html =~ "PUKLLAY CLUB"
    end

    test "mark: false composes with a passed tagline" do
      html = render_component(&Layouts.brand_logo/1, %{mark: false, tagline: "Conectá jugando"})

      assert html =~ "Conectá jugando"
    end

    test "mark: false emits pk-brand-quiet; the header default does not" do
      quiet_html = render_component(&Layouts.brand_logo/1, %{mark: false})
      default_html = render_component(&Layouts.brand_logo/1, %{})

      assert quiet_html =~ "pk-brand-quiet"
      refute default_html =~ "pk-brand-quiet"
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

  # G-01.2-8 gap closure (plan 01.2-15): replaces phx.new's stock
  # #client-error/#server-error toast with an on-brand, Spanish, in-flow
  # connection-status bar. No pre-existing test in this file ever asserted
  # on either removed id, so there is nothing to delete here — these are all
  # newly authored assertions.
  describe "app/1 connection-status bar (G-01.2-8, plan 01.2-15)" do
    test "flash_group/1 renders neither connection-state id nor the stock toast positioning classes" do
      html = render_component(&Layouts.flash_group/1, %{flash: %{}})

      refute html =~ "client-error"
      refute html =~ "server-error"
      refute html =~ "toast-top"
      refute html =~ "toast-end"
    end

    test "flash_group/1 still renders an :info and an :error flash (deletion was surgical)" do
      html =
        render_component(&Layouts.flash_group/1, %{
          flash: %{"info" => "Guardado con éxito", "error" => "Algo salió mal"}
        })

      assert html =~ "Guardado con éxito"
      assert html =~ "Algo salió mal"
    end

    test "app/1 renders exactly one connection-status bar carrying hidden, role and both connection bindings" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      bar_nodes =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-conn-banner")

      assert Enum.count(bar_nodes) == 1

      bar_html = LazyHTML.to_html(bar_nodes)

      assert bar_html =~ ~s(id="connection-status")
      assert bar_html =~ "hidden"
      assert bar_html =~ ~s(role="status")
      assert bar_html =~ "phx-disconnected"
      assert bar_html =~ "phx-connected"
    end

    test "the bar's copy is Spanish and none of the three replaced English strings remain" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ "Reconectando"
      assert html =~ "no encontramos tu conexión a internet"
      refute html =~ "Attempting to reconnect"
      refute html =~ "Something went wrong"
      refute html =~ "find the internet"
    end

    # The placement assertion compares two numeric offsets, not presence —
    # presence alone would still pass with the bar left at the bottom of the
    # document, which is the exact defect being fixed (the old toast was
    # already in the right DOM position and still read as a floating card
    # because of `position: fixed`; the fix is that this bar is now in flow
    # *here*, between the header and #app-subnav).
    #
    # Mutation check performed once by hand while authoring this test
    # (restored immediately after, per the plan's acceptance criteria):
    # moving the bar's markup down to just before `<.footer />` in
    # `Layouts.app/1` made this test fail (bar offset landed after the
    # #app-subnav offset), confirming the assertion actually depends on
    # document order rather than passing unconditionally.
    test "the connection-status bar sits between #app-header and #app-subnav in document order" do
      html = render_component(&render_with_subnav/1, %{})

      {header_offset, _} = :binary.match(html, ~s(id="app-header"))
      {bar_offset, _} = :binary.match(html, ~s(id="connection-status"))
      {subnav_offset, _} = :binary.match(html, ~s(id="app-subnav"))

      assert header_offset < bar_offset
      assert bar_offset < subnav_offset
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

    defp main_class(html) do
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query("main")
      |> LazyHTML.attribute("class")
      |> List.first()
    end

    # G-01.2-22 task 2/3: `boundary_collapse` (default false) and <main>'s
    # default vertical-padding utilities are mutually exclusive branches of
    # one `if` — never both rendered at once (see the CASCADE-LAYER HAZARD
    # note at the top of app.css for why that would be a landmine, not a
    # convenience). Asserting the exact class string, not a substring, is
    # the whole point: a future edit that retunes the shared default for
    # every page must fail this test by name.
    test "with boundary_collapse unset, <main> carries exactly today's default vertical-padding utilities" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert main_class(html) == "pb-20 pt-8 sm:pt-20 px-4 sm:px-6 lg:px-8"
    end

    test "with boundary_collapse set, <main> carries the collapse class and none of the default vertical-padding utilities" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          boundary_collapse: true,
          inner_block: []
        })

      class = main_class(html)
      assert class == "pk-boundary-collapse px-4 sm:px-6 lg:px-8"
      refute class =~ "pb-20"
      refute class =~ "pt-8"
      refute class =~ "sm:pt-20"
    end

    test "fullbleed's horizontal-padding behavior is unchanged in either boundary_collapse state" do
      unset_html =
        render_component(&Layouts.app/1, %{flash: %{}, fullbleed: true, inner_block: []})

      collapsed_html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          fullbleed: true,
          boundary_collapse: true,
          inner_block: []
        })

      refute main_class(unset_html) =~ "px-4"
      refute main_class(collapsed_html) =~ "px-4"
    end

    # Quick task 260902-il3: `bottom_collapse` is a SECOND, independent axis
    # from `boundary_collapse` (D-01/D-02) — it collapses only the bottom
    # boundary (cancelling `pb-20`), leaving the default top-padding
    # utilities (`pt-8 sm:pt-20`) in place, for a page whose bottom boundary
    # double-stacks but whose top spacing is a separately-tuned, closed
    # decision that must not move (REQ-2). Exact-string assertion, matching
    # the discipline the two tests above already established.
    test "with bottom_collapse set and boundary_collapse unset, <main> carries the bottom-collapse class and keeps the default top-padding utilities" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          bottom_collapse: true,
          inner_block: []
        })

      class = main_class(html)
      assert class == "pk-bottom-collapse pt-8 sm:pt-20 px-4 sm:px-6 lg:px-8"
      refute class =~ "pb-20"
      refute class =~ "pk-boundary-collapse"
    end

    # D-02: the two collapse attrs are structurally exclusive branches, not
    # competing declarations — `boundary_collapse` wins outright when both
    # are set, and `pk-bottom-collapse` must never appear alongside it.
    test "with both boundary_collapse and bottom_collapse set, boundary_collapse wins outright" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          boundary_collapse: true,
          bottom_collapse: true,
          inner_block: []
        })

      assert main_class(html) == "pk-boundary-collapse px-4 sm:px-6 lg:px-8"
    end

    test "fullbleed's horizontal-padding behavior is unchanged in the bottom_collapse state too" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          fullbleed: true,
          bottom_collapse: true,
          inner_block: []
        })

      refute main_class(html) =~ "px-4"
    end
  end

  # G-01.2-22 task 3: the three call-site assertions that make the opt-in
  # scoping enforceable rather than a convention — the detail page passes
  # `boundary_collapse`, the catalog index and about pages do not.
  describe "boundary_collapse call-site contract (G-01.2-22)" do
    test "the detail page's <main> carries pk-boundary-collapse", %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert main_class(html) =~ "pk-boundary-collapse"
    end

    test "the catalog index page's <main> does not carry pk-boundary-collapse", %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      refute main_class(html) =~ "pk-boundary-collapse"
    end

    test "the about page's <main> does not carry pk-boundary-collapse", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      refute main_class(html) =~ "pk-boundary-collapse"
    end

    # Quick task 260902-il3: the catalog page opts into the bottom-only axis
    # instead — D-01 forbids reusing boundary_collapse here since it would
    # also move the catalog page's separately-closed top spacing (REQ-2).
    test "the catalog index page's <main> carries pk-bottom-collapse and not pb-20", %{
      conn: conn
    } do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      class = main_class(html)
      assert class =~ "pk-bottom-collapse"
      refute class =~ "pb-20"
    end

    test "the about page's <main> carries neither pk-bottom-collapse nor pk-boundary-collapse, and still carries pb-20",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      class = main_class(html)
      refute class =~ "pk-bottom-collapse"
      refute class =~ "pk-boundary-collapse"
      assert class =~ "pb-20"
    end

    test "the detail page's <main> carries pk-boundary-collapse and not pk-bottom-collapse", %{
      conn: conn
    } do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      class = main_class(html)
      assert class =~ "pk-boundary-collapse"
      refute class =~ "pk-bottom-collapse"
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

  # REMOVED (2026-09-02, quick task 260902-glf, Task 3): the sticky-footer
  # app shell's `.pk-app-shell` class and its whole CSS mechanism (min-
  # height floor, main-child flex-grow, and — as of this task — the flex
  # column too) are deleted outright, not commented out. This describe
  # used to pin `<body>` carrying `pk-app-shell` on every route; the
  # sibling `pk-app-shell CSS facts` describe (Phase 01.2 gap-closure round
  # 4, G-01.2-24; briefly inverted into an absence guard earlier in this
  # same task) used to assert the stylesheet contract. Both are gone
  # because the class itself is gone: Task 3's live CDP A/B measurement
  # (toggling `.pk-app-shell { display: block !important; }` against the
  # running dev server at 390px, short and long pages) found EVERY
  # geometry number byte-identical with the flex column present vs.
  # removed — `<main>` carries only padding, never a bottom margin, so
  # there was nothing left for `.pk-footer`'s top margin to collapse
  # against once the height floor and growth factor were already gone.
  # The flex column was therefore vestigial, `root.html.heex` now renders
  # a bare `<body>` with no class, and there is no longer a stylesheet
  # contract for this file to pin — see app.css's own dated note above
  # `.pk-gutter` for the full history and measurement record.
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

    test "the footer's left cluster renders neither theme mark filename (D-A, 260823-snj)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      footer_left_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-footer-left")
        |> LazyHTML.to_html()

      refute footer_left_html =~ "isologo-light.png"
      refute footer_left_html =~ "isologo-dark.png"
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
    # Scoped to exclude the drawer's own .pk-drawer-social row (01.1-09
    # Task 2): that row legitimately links the WhatsApp URL as its
    # WhatsApp icon, an unrelated consumer of ClubLinks.whatsapp_group_url/0
    # from the join CTA this test actually guards against. "Sumate" (the
    # CTA's own label, absent from the drawer's markup) stays the direct,
    # unscoped signal.
    test "the #app-header subtree contains neither the CTA label nor its WhatsApp URL outside the drawer's social row" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      doc = LazyHTML.from_document(html)
      header_html = doc |> LazyHTML.query("#app-header") |> LazyHTML.to_html()

      non_drawer_social_html =
        doc
        |> LazyHTML.query("#app-header :not(.pk-drawer-social) > a")
        |> LazyHTML.to_html()

      refute header_html =~ "Sumate"
      refute non_drawer_social_html =~ PukllayClubWeb.ClubLinks.whatsapp_group_url()
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

    test "the toggle's icon is the full hero-magnifying-glass at size-5 (260823-snj)" do
      html = render_component(&render_with_nav_search/1, %{})

      toggle_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-search-morph-toggle")
        |> LazyHTML.to_html()

      assert toggle_html =~ "hero-magnifying-glass"
      assert toggle_html =~ "size-5"
    end

    test "the toggle carries title=\"Buscar\" alongside its aria-label (260823-snj)" do
      html = render_component(&render_with_nav_search/1, %{})

      toggle_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-search-morph-toggle")
        |> LazyHTML.to_html()

      assert toggle_html =~ ~s(title="Buscar")
      assert toggle_html =~ ~s(aria-label="Buscar")
    end

    test "the toggle still carries aria-expanded and aria-controls (regression guard, 260823-snj)" do
      html = render_component(&render_with_nav_search/1, %{})

      toggle_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-search-morph-toggle")
        |> LazyHTML.to_html()

      assert toggle_html =~ ~s(aria-expanded="false")
      assert toggle_html =~ ~s(aria-controls="pk-nav-search-region")
    end
  end

  describe "app/1 search-morph server-owned open state (01.2-11)" do
    # Two directions, not one — a single-direction test would still pass
    # against a rule that unconditionally emitted the class (the exact bug
    # class Task 1 fixes: the class must be PRESENT when true and ABSENT
    # when false, not merely present-when-true).
    test "search_expanded=true renders is-open on the morph and is-search-open on the nav row" do
      html = render_component(&render_with_nav_search/1, %{search_expanded: true})

      morph_html =
        html |> LazyHTML.from_document() |> LazyHTML.query(".pk-search-morph") |> LazyHTML.to_html()

      nav_inner_html =
        html |> LazyHTML.from_document() |> LazyHTML.query(".pk-nav-inner") |> LazyHTML.to_html()

      assert morph_html =~ "is-open"
      assert nav_inner_html =~ "is-search-open"
    end

    test "search_expanded=false renders neither modifier class" do
      html = render_component(&render_with_nav_search/1, %{search_expanded: false})

      morph_html =
        html |> LazyHTML.from_document() |> LazyHTML.query(".pk-search-morph") |> LazyHTML.to_html()

      nav_inner_html =
        html |> LazyHTML.from_document() |> LazyHTML.query(".pk-nav-inner") |> LazyHTML.to_html()

      refute morph_html =~ "is-open"
      refute nav_inner_html =~ "is-search-open"
    end

    test "the toggle and close buttons carry open-search/close-search and their state-derived aria-expanded/tabindex in both directions" do
      html_closed = render_component(&render_with_nav_search/1, %{search_expanded: false})
      html_open = render_component(&render_with_nav_search/1, %{search_expanded: true})

      toggle_closed =
        html_closed
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-search-morph-toggle")
        |> LazyHTML.to_html()

      close_closed =
        html_closed
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-search-morph-close")
        |> LazyHTML.to_html()

      toggle_open =
        html_open
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-search-morph-toggle")
        |> LazyHTML.to_html()

      close_open =
        html_open
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-search-morph-close")
        |> LazyHTML.to_html()

      assert toggle_closed =~ ~s(phx-click="open-search")
      assert close_closed =~ ~s(phx-click="close-search")

      assert toggle_closed =~ ~s(aria-expanded="false")
      assert toggle_closed =~ ~s(tabindex="0")
      assert close_closed =~ ~s(tabindex="-1")

      assert toggle_open =~ ~s(aria-expanded="true")
      assert toggle_open =~ ~s(tabindex="-1")
      assert close_open =~ ~s(tabindex="0")
    end
  end

  describe "app/1 mobile nav drawer (01.1-09)" do
    test "the hamburger renders with a Spanish aria-label and aria-controls=\"pk-nav-drawer\"" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ ~s(aria-label="Abrir menú")
      assert html =~ ~s(aria-controls="pk-nav-drawer")
    end

    test "the panel renders with role=dialog, aria-modal=true and carries inert at rest" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      drawer_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#pk-nav-drawer")
        |> LazyHTML.to_html()

      assert drawer_html =~ ~s(role="dialog")
      assert drawer_html =~ ~s(aria-modal="true")
      assert drawer_html =~ "inert"
    end

    test "both site links render regardless of which slots the caller passed" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      drawer_links_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-drawer-links")
        |> LazyHTML.to_html()

      assert drawer_links_html =~ "Inicio"
      assert drawer_links_html =~ "Quiénes Somos"
    end

    test "active_nav :inicio places aria-current=\"page\" on Inicio only" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: [], active_nav: :inicio})

      doc = LazyHTML.from_document(html)
      inicio_link = doc |> LazyHTML.query(".pk-drawer-links a:first-child") |> LazyHTML.to_html()
      quienes_link = doc |> LazyHTML.query(".pk-drawer-links a:last-child") |> LazyHTML.to_html()

      assert inicio_link =~ ~s(aria-current="page")
      refute quienes_link =~ ~s(aria-current="page")
    end

    test "active_nav :quienes_somos places aria-current=\"page\" on Quiénes Somos only" do
      html =
        render_component(&Layouts.app/1, %{flash: %{}, inner_block: [], active_nav: :quienes_somos})

      doc = LazyHTML.from_document(html)
      inicio_link = doc |> LazyHTML.query(".pk-drawer-links a:first-child") |> LazyHTML.to_html()
      quienes_link = doc |> LazyHTML.query(".pk-drawer-links a:last-child") |> LazyHTML.to_html()

      refute inicio_link =~ ~s(aria-current="page")
      assert quienes_link =~ ~s(aria-current="page")
    end

    test "active_nav nil (the default) marks neither drawer link current" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      drawer_links_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-drawer-links")
        |> LazyHTML.to_html()

      refute drawer_links_html =~ "aria-current"
    end

    test "each drawer link row renders a chevron icon" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      chevrons =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-drawer-links .pk-drawer-chevron")

      assert Enum.count(chevrons) == 2
    end

    test "the drawer's bottom block renders the theme toggle and exactly four social links" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      bottom_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-drawer-bottom")
        |> LazyHTML.to_html()

      assert bottom_html =~ "phx:set-theme"

      drawer_social_links =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-drawer-social a")

      assert Enum.count(drawer_social_links) == 4
    end

    # Pins the reordered bottom block (quick task 260824-q8z): social reads
    # first (more relevance), the theme control second — both wrapped in
    # their own divider. Guards against a future edit silently reverting the
    # order back to theme-first.
    test "the social row renders before the theme control in the drawer's bottom block" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      bottom_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-drawer-bottom")
        |> LazyHTML.to_html()

      social_index = bottom_html |> :binary.match(~s(class="pk-drawer-social")) |> elem(0)
      utility_index = bottom_html |> :binary.match(~s(class="pk-drawer-utility")) |> elem(0)

      assert social_index < utility_index
    end

    # Guards against the footer and the drawer drifting to two independently
    # maintained social lists — both must resolve to the exact same four
    # ClubLinks hrefs, in the same order.
    test "the footer and drawer social markup resolve to the same four hrefs" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      doc = LazyHTML.from_document(html)

      footer_hrefs =
        doc |> LazyHTML.query(".pk-footer-social a") |> LazyHTML.attribute("href")

      drawer_hrefs =
        doc |> LazyHTML.query(".pk-drawer-social a") |> LazyHTML.attribute("href")

      assert length(footer_hrefs) == 4
      assert footer_hrefs == drawer_hrefs
    end

    test ".pk-footer-meta is present in the rendered footer" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ "pk-footer-meta"
    end

    # Mirrors the desktop footer's already-shipped role="group" +
    # aria-labelledby pattern (debug footer-theme-toggle-balance): the three
    # theme buttons get one accessible group name instead of announcing as
    # three unrelated buttons (quick task 260824-q8z).
    test "the drawer's theme control carries role=\"group\" and aria-labelledby" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      utility = LazyHTML.query(doc, ".pk-drawer-utility")

      assert utility |> LazyHTML.attribute("role") |> List.first() == "group"

      assert utility |> LazyHTML.attribute("aria-labelledby") |> List.first() ==
               "pk-drawer-theme-label"
    end

    # The label is CONVERTED (sr-only), not deleted — it still supplies the
    # group's accessible name. Its id must be document-unique: the footer
    # already renders "pk-footer-theme-label" in the same document, so
    # reusing that id would point both controls' aria-labelledby at one
    # ambiguous target.
    test "the drawer's theme label is sr-only with a document-unique id" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      doc = LazyHTML.from_document(html)

      label = LazyHTML.query(doc, "#pk-drawer-theme-label")
      assert Enum.count(label) == 1

      classes = label |> LazyHTML.attribute("class") |> List.first()

      assert classes =~ "sr-only",
             "The drawer's \"Tema\" label is visible again. Sketch 021's Round 6 conclusion " <>
               "(E1 — Icon-Only, Centered) and the footer's already-shipped debug session " <>
               "both converge on sr-only for this control."

      assert classes =~ "pk-drawer-utility-label"

      # Must not collide with the footer's own id in the same document.
      id_occurrences =
        html |> String.split(~s(id="pk-drawer-theme-label")) |> length() |> Kernel.-(1)

      assert id_occurrences == 1
      refute html =~ ~s(id="pk-footer-theme-label" class="pk-drawer-utility-label")
    end

    # Guards the 44px touch floor against a future "tidy the duplicate
    # footer/drawer theme CSS" refactor accidentally widening the footer's
    # 28px scope to the drawer — the drawer is the sole mobile home for the
    # theme control below 480px (`.pk-footer-right` is display:none there).
    test "the drawer's three theme buttons stay 44px after centering" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      utility_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-drawer-utility")
        |> LazyHTML.to_html()

      assert utility_html |> String.split("min-h-11") |> length() |> Kernel.-(1) == 3
      assert utility_html |> String.split("min-w-11") |> length() |> Kernel.-(1) == 3
    end
  end

  # social_links/1 is a private (defp) component — same convention as
  # footer/1 / header_inner/1 elsewhere in this module — so it's exercised
  # indirectly through Layouts.app/1's rendered footer subtree, its one
  # consumer with a stable, always-present container class.
  describe "social_links/1 (exercised via the footer's .pk-footer-social)" do
    test "renders four distinct Spanish aria-labels" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      footer_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-footer-social")
        |> LazyHTML.to_html()

      assert footer_html =~ ~s(aria-label="WhatsApp")
      assert footer_html =~ ~s(aria-label="Facebook")
      assert footer_html =~ ~s(aria-label="Instagram")
      assert footer_html =~ ~s(aria-label="Correo")
    end

    test "the three external links carry rel=noopener noreferrer, the mailto: link carries neither target nor rel" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      doc = LazyHTML.from_document(html)
      footer_social = LazyHTML.query(doc, ".pk-footer-social")
      footer_html = LazyHTML.to_html(footer_social)

      blank_count = footer_html |> String.split(~s(target="_blank")) |> length() |> Kernel.-(1)
      rel_count = footer_html |> String.split(~s(rel="noopener noreferrer")) |> length() |> Kernel.-(1)

      assert blank_count == 3
      assert rel_count == 3

      mailto_html =
        footer_social
        |> LazyHTML.query(~s(a[aria-label="Correo"]))
        |> LazyHTML.to_html()

      refute mailto_html =~ "target="
      refute mailto_html =~ "rel="
    end

    test "the caller-supplied class wraps the rendered links (two container classes, one markup definition)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ ~s(class="pk-footer-social")
      assert html =~ ~s(class="pk-drawer-social")
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
