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
    test "renders the one-line wordmark, no tagline" do
      html = render_component(&Layouts.brand_logo/1, %{})

      assert html =~ "PUKLLAY CLUB"
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

      # Plan 01.4-05 (sketch 045, D-10) appended a `pk-brand-mark` styling
      # hook class to both images alongside their theme-variant classes —
      # the class-attribute assertions below now check containment rather
      # than an exact string, since "dark:hidden"/"hidden dark:block" are
      # no longer the ENTIRE class value.
      assert light_img_html =~ "isologo-light.png"
      assert light_img_html =~ ~s(class="dark:hidden pk-brand-mark")
      assert light_img_html =~ ~s(width="36")
      assert light_img_html =~ ~s(alt="")

      assert dark_img_html =~ "isologo-dark.png"
      assert dark_img_html =~ ~s(class="hidden dark:block pk-brand-mark")
      assert dark_img_html =~ ~s(width="36")
      assert dark_img_html =~ ~s(alt="")
    end

    test "the footer's .pk-footer-left cluster renders no mark and no brand_logo/1 call at all (this session's footer minimalism pass, 2026-09-09)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      doc = LazyHTML.from_document(html)
      footer_left = LazyHTML.query(doc, ".pk-footer-left")

      footer_left_imgs = LazyHTML.query(footer_left, "img")
      assert Enum.empty?(footer_left_imgs)

      # Stronger than "no <img>" (which mark: false alone used to satisfy):
      # the footer no longer calls brand_logo/1 at all, so it must render
      # none of the wordmark markup either, not just no isologo.
      footer_left_html = LazyHTML.to_html(footer_left)

      refute footer_left_html =~ "pk-brand-wordmark",
             "Expected .pk-footer-left to render no brand_logo/1 output at all — the footer " <>
               "brand block was removed entirely, not just demoted to mark: false."
    end

    test "the header still renders exactly two <img> marks (header-only, not removed, 260823-snj)" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      header_imgs =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header img")

      assert Enum.count(header_imgs) == 2
    end

    test "forcing isologo? false renders no <img> and keeps the wordmark" do
      html = render_component(&Layouts.brand_logo/1, %{isologo?: false})

      imgs =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("img")

      assert Enum.empty?(imgs)
      assert html =~ "PUKLLAY CLUB"
    end

    test "both mark paths satisfy File.exists?/1 (gate truthfulness)" do
      assert File.exists?("priv/static/images/isologo-light.png")
      assert File.exists?("priv/static/images/isologo-dark.png")
    end
  end

  describe "app/1 header" do
    test "shows the brand wordmark, one line, no tagline" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      assert html =~ "PUKLLAY CLUB"
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

      # Scoped to #app-header (not the whole page, per 01.8.2-09 Task 1):
      # PukllayClubWeb.Layouts.NavDrawer, the drawer's own LiveComponent,
      # renders an unconditional colocated hook (.NavDrawerFocus) OUTSIDE
      # #app-header regardless of @sticky — that unconditional presence is
      # exactly the G-01.8.1-1b fix (the drawer used to only work on pages
      # whose header carried .CatalogNav). .CatalogNav itself stays
      # genuinely conditional on @sticky.
      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header")
        |> LazyHTML.to_html()

      refute header_html =~ "phx-hook"
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
  describe "app/1 connection-status bar (G-01.2-8, plan 01.2-15) and admin flash routing (D-19c, plan 01.8.2-08)" do
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

    test "admin_chrome: true with an :info flash renders the snackbar, never the top toast" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{"info" => "Sesión cerrada."},
          inner_block: [],
          admin_chrome: true
        })

      assert html =~ "pk-admin-snackbar"
      assert html =~ "Sesión cerrada."
      refute html =~ "toast-top"
      refute html =~ "toast-end"
    end

    test "admin_chrome: true with an :error flash renders the snackbar, never the top toast" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{"error" => "Error al traer datos de BGG."},
          inner_block: [],
          admin_chrome: true
        })

      assert html =~ "pk-admin-snackbar"
      assert html =~ "Error al traer datos de BGG."
      refute html =~ "toast-top"
    end

    test "admin_chrome: true with no flash present renders no snackbar" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: [], admin_chrome: true})

      refute html =~ "pk-admin-snackbar"
    end

    test "admin_chrome: false (default, public pages) still renders the top toast — regression guard" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{"info" => "Guardado con éxito"},
          inner_block: []
        })

      assert html =~ "toast-top"
      refute html =~ "pk-admin-snackbar"
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

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game}")

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

    # Plan 01.5-08 (G-01.5-3 item 4): superseded the prior assertion here
    # (About took the full default bottom stack). The about page now opts
    # into `bottom_collapse` — same axis as the catalog index page, since its
    # top spacing is a separately-correct decision that must not move. See
    # `test/pukllay_club_web/live/about_live_test.exs`'s "bottom-boundary
    # opt-in" describe block for the top-padding-preserved half of this
    # contract.
    test "the about page's <main> carries pk-bottom-collapse and not pb-20 or pk-boundary-collapse",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      class = main_class(html)
      assert class =~ "pk-bottom-collapse"
      refute class =~ "pb-20"
      refute class =~ "pk-boundary-collapse"
    end

    test "the detail page's <main> carries pk-boundary-collapse and not pk-bottom-collapse", %{
      conn: conn
    } do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game}")

      class = main_class(html)
      assert class =~ "pk-boundary-collapse"
      refute class =~ "pk-bottom-collapse"
    end
  end

  # Plan 01.5-08 (G-01.5-3 item 4, T-01.5-28): the defect this whole plan
  # closes existed because `about_live.ex` never opted into either boundary
  # attr and nothing surfaced that omission. This test is the surfacing
  # mechanism for the NEXT caller that forgets: it enumerates every real
  # `<Layouts.app` call site under `lib/` and asserts each one passes
  # `boundary_collapse` or `bottom_collapse`.
  describe "Layouts.app caller contract (plan 01.5-08, G-01.5-3 item 4)" do
    # `lib/pukllay_club_web/components/layouts.ex` is the layout's OWN
    # definition file, not a caller — its `@doc` for `app/1` includes an
    # illustrative `<Layouts.app flash={@flash}>` usage example inside a
    # docstring, with no boundary attr, because it is prose documentation,
    # not a real render call. Excluded by path (the definition file), not by
    # sniffing whether a match sits inside a docstring, which would be more
    # fragile to a comment reflow.
    @layouts_definition_file "lib/pukllay_club_web/components/layouts.ex"

    # Callers explicitly exempted from this contract because they genuinely
    # want <main>'s full, unmodified default top+bottom padding stack — not
    # because nobody has looked. A caller taking that default stack
    # accumulates THREE independently-reasonable declarations: <main>'s own
    # bottom padding (`pb-20`, 80px) + its last child's own trailing margin +
    # `.pk-footer`'s own top margin — the exact stack `app.css`'s
    # `main.pk-bottom-collapse` comment records as measured live on the
    # catalog page before quick task 260902-il3 fixed it (176px at 1280px /
    # 128px at 390px). Empty on purpose: every current caller (the catalog
    # index page, the game detail page, and the about page as of this plan)
    # has a considered opt-in. Add a caller's file path here ONLY alongside a
    # comment explaining why it genuinely wants the full default stack —
    # never to silence this test.
    @default_bottom_stack_exceptions []

    # Matches the whole opening tag text up to its first `>` — robust to
    # `mix format`'s attribute-per-line wrapping (unlike a regex anchored to
    # a specific line shape) because it scans the raw source for the literal
    # `<Layouts.app` token rather than a formatted rendering of it. This
    # assumes no call site's attribute values themselves contain a literal
    # `>` (e.g. a `>` inside a `{...}` expression) — none of today's three
    # call sites do, and a future one that did would fail LOUDLY here (either
    # by truncating the tag before a real boundary attr, which the assertion
    # below would then correctly flag as missing) rather than silently.
    @call_site_pattern ~r/<Layouts\.app\b.*?>/s

    defp layouts_app_call_sites do
      "lib/**/*.ex"
      |> Path.wildcard()
      |> Enum.reject(&(&1 == @layouts_definition_file))
      |> Enum.flat_map(fn path ->
        @call_site_pattern
        |> Regex.scan(File.read!(path))
        |> Enum.map(fn [tag] -> {path, tag} end)
      end)
    end

    test "every Layouts.app call site under lib/ passes boundary_collapse or bottom_collapse, or is on the documented exception list" do
      call_sites = layouts_app_call_sites()

      assert call_sites != [],
             "Expected to find at least one real <Layouts.app call site under lib/ — " <>
               "if this fails, the scan itself is broken (wrong glob, wrong exclusion), " <>
               "not that callers vanished."

      for {path, tag} <- call_sites, path not in @default_bottom_stack_exceptions do
        has_boundary_attr? = tag =~ ~r/\bboundary_collapse\b/ or tag =~ ~r/\bbottom_collapse\b/

        assert has_boundary_attr?,
               """
               #{path} calls Layouts.app without boundary_collapse or bottom_collapse.

               A caller that takes <main>'s full default vertical-padding stack
               accumulates THREE independently-reasonable declarations at its bottom
               boundary: <main>'s own bottom padding (pb-20, 80px) + its last child's
               own trailing margin + .pk-footer's own top margin. app.css's
               `main.pk-bottom-collapse` comment (quick task 260902-il3) records the
               catalog page's own live-measured version of that stack before it opted
               in: 176px at 1280px / 128px at 390px — this is the defect class plan
               01.5-08 closed for the about page (G-01.5-3 item 4) after it went
               unnoticed for several plans.

               If this caller genuinely wants the unmodified default stack, add its
               file path to @default_bottom_stack_exceptions above, with a comment
               explaining why — do not let it pass this test silently.
               """
      end
    end
  end

  describe "brand_logo/1 hit target" do
    test "the wordmark link meets the app's 44px hit-target floor" do
      html = render_component(&Layouts.brand_logo/1, %{})

      assert html =~ "min-h-11"
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

  # G-01.5-9 (re-reported 2026-09-09) asked, a second time, whether the
  # mechanism removed above should come back. Plan 01.5-12's checkpoint
  # Task 1 decided A — leave it withdrawn — a second time, with both
  # reported states in front of the developer. This describe block is the
  # GUARD for that decision, not a restoration of the presence tests
  # removed above: it asserts the shell declares NO such mechanism, and it
  # is written to survive the very source it is guarding, because the
  # SUPERSEDED note above `.pk-gutter` in app.css necessarily quotes these
  # same declarations as PROSE while explaining why they were removed (e.g.
  # the literal text "min-height: 100vh" inside that comment's backticks).
  # A check against the raw file source would risk matching that prose
  # instead of real CSS — the specific hazard this describe exists to
  # avoid — so every assertion below first strips CSS comments, then
  # further requires the declaration to sit inside an actual bare `body {`
  # or `main {` rule block (not a comment, not `body.pk-has-cta-bar {`,
  # not `body:has(#cierre) ... {`), which the prose never is.
  describe "root layout sticky-footer decision (G-01.5-9, plan 01.5-12 — decided A: leave withdrawn, 2026-09-09)" do
    @app_css_path "assets/css/app.css"

    # Strips every `/* ... */` CSS comment (non-greedy, DOTALL) before any
    # assertion runs. This is what keeps the SUPERSEDED note's own prose —
    # which quotes `min-height: 100vh`, `min-height: 100dvh`, `flex-grow: 1`
    # and `flex-direction: column` by name, in backticks, as part of the
    # historical record — from ever being read as a live declaration.
    defp app_css_without_comments do
      @app_css_path
      |> File.read!()
      |> then(&Regex.replace(~r/\/\*.*?\*\//s, &1, ""))
    end

    # Matches a real, uncommented, BARE `body { ... }` or `main { ... }`
    # rule — `body` or `main` as the entire selector, not `body.pk-foo`,
    # not `body:has(...)`, not a comma-joined group. The negative lookbehind
    # rejects a preceding word/dot/hyphen character so `.pk-app-shell` (a
    # class, not this element) and `body.pk-sheet-open` (a compound
    # selector, not this element alone) can never match.
    defp bare_element_rule_blocks(css, element) do
      ~r/(?<![\w.-])#{element}\s*\{([^}]*)\}/s
      |> Regex.scan(css, capture: :all_but_first)
      |> Enum.map(fn [block] -> block end)
    end

    @failure_message """
    The shell just declared a site-wide sticky-footer mechanism on `body` \
    or `main` — a viewport-height floor, a flex column, or a flex-grow \
    factor. This is a TWICE-MADE decision, not an oversight: the mechanism \
    was added in Phase 01.2 gap-closure round 4, deleted on 2026-09-02 by \
    quick task 260902-glf as an explicit developer choice, re-reported on \
    2026-09-09 as G-01.5-9, and decided AGAIN — still withdrawn — by plan \
    01.5-12's checkpoint Task 1, with both reported states of the tradeoff \
    (below-footer void on short pages vs. above-footer void on short \
    pages, since this mechanism RELOCATES the empty space rather than \
    removing it) in front of the developer both times.

    The G-01.5-9 debug session
    (.planning/debug/G-01.5-9-footer-not-pinned-bottom.md) got one thing \
    wrong: it describes this mechanism as "an ABSENCE in the shell... \
    present since the shell was written." It was not an absence — it \
    EXISTED and was deliberately removed. Read the whole story, both \
    dates, in app.css's own dated note above `.pk-gutter` (search for \
    "SUPERSEDED 2026-09-02") before restoring anything here. If restoring \
    it is truly the right call now, that is a NEW decision for a NEW plan \
    to make explicitly, with its own checkpoint and its own dated chapter \
    in that note — not a silent side effect of an automated pass reading \
    the diagnosis this test's own history had to correct once already.
    """

    test "body declares no viewport-height sticky-footer floor" do
      css = app_css_without_comments()

      for block <- bare_element_rule_blocks(css, "body") do
        refute block =~ ~r/min-height:\s*100d?vh/, @failure_message
      end
    end

    test "body declares no flex column" do
      css = app_css_without_comments()

      for block <- bare_element_rule_blocks(css, "body") do
        is_flex_column? = block =~ ~r/display:\s*flex\b/ and block =~ ~r/flex-direction:\s*column\b/
        refute is_flex_column?, @failure_message
      end
    end

    test "main declares no flex-grow factor" do
      css = app_css_without_comments()

      for block <- bare_element_rule_blocks(css, "main") do
        refute block =~ ~r/flex(-grow)?:\s*[1-9]/, @failure_message
      end
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

  # G-01.5 footer minimalism pass (2026-09-09): the footer's left cluster
  # used to reuse brand_logo/1 with a tagline override (260821-umm) — that
  # whole mechanism (and this describe block's tests, which pinned its
  # every detail: the override, the no-repeat-header-subtitle guarantee, the
  # header's own subtitle staying put, the no-isologo-filename guard) is
  # retired along with the footer brand block itself. The replacement
  # coverage (no brand_logo output of any kind in .pk-footer-left) lives in
  # the "brand_logo/1 theme-aware isologo pair" describe block above.

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
    #
    # G-01.5-4 (plan 01.5-10): the outline/primary classes stay, but the
    # size now comes from ONE class — pk-sumate-btn (app.css) — that owns
    # every size axis (height, inline padding, font-size, radius) per sketch
    # 051's approved design source. daisyUI's btn-lg size step and the app's
    # min-h-11 touch-floor utility (plan 01.5-05's fix) are BOTH gone: this
    # plan's own diagnosis (.planning/debug/G-01.5-4-hero-cierre-composition-
    # balance.md) found that composition correctly fixed a real proportion
    # defect (1.03:1 -> 1.74:1) but never matched the sketch the composition
    # was actually approved against (2.15:1, pill radius, 28px padding,
    # 16px font, 48px height) — restoring that fidelity means one class now
    # owns the whole axis, so leaving btn-lg or min-h-11 alongside
    # pk-sumate-btn would recreate the exact competing-declaration failure
    # this same component has already been fixed for once. The 44px touch
    # floor is met by pk-sumate-btn's own 48px min-height and is verified by
    # MEASURED height in test/visual/about_geometry.mjs, not by a utility
    # class name here.
    test "carries the outline-at-rest button classes and the single pk-sumate-btn geometry class" do
      html = render_component(&Layouts.sumate_cta/1, %{})

      assert html =~ "btn-outline"
      assert html =~ "btn-primary"
      assert html =~ "pk-sumate-btn"

      refute html =~ "btn-lg",
             "btn-lg is the daisyUI size step plan 01.5-10 retires. It couples a size step's " <>
               "own height/padding-inline/font-size to values sketch 051 never specified (42px/" <>
               "16px/18px in this app's theme) — leaving it alongside pk-sumate-btn makes the " <>
               "two compete on every one of those axes and silently reintroduces a geometry the " <>
               "design source was never approved with."

      refute html =~ "min-h-11",
             "min-h-11 is the one-axis touch-floor utility plan 01.5-05 added and plan 01.5-10 " <>
               "retires. pk-sumate-btn's own 48px min-height already clears the 44px floor as a " <>
               "measured property (see test/visual/about_geometry.mjs) — leaving this utility " <>
               "alongside it would have two declarations compete on the same height axis again."

      refute html =~ "min-h-12"
      refute html =~ "btn-sm"
    end

    test "still merges a caller-supplied class, so the mobile sticky bar keeps dictating its own width" do
      html = render_component(&Layouts.sumate_cta/1, %{class: "w-full"})

      assert html =~ "w-full"
      assert html =~ "pk-sumate-btn"
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

  # Task 1, plan 01.8.2-09 (D-12/G-01.8.1-1b): the drawer's open/close state
  # moved server-side into PukllayClubWeb.Layouts.NavDrawer, a stateful
  # LiveComponent addressed by DOM id (#pk-nav-drawer) rather than the old
  # .CatalogNav-hook mechanism that only mounted when @sticky was true. These
  # tests hit REAL routes (not render_component/2) so render_click/1 can
  # simulate an actual click through the component's own handle_event/3 —
  # exactly what G-01.8.1-1b's "I click and nothing happens" report needs
  # covered on both a public page and an admin page (neither of Show/About
  # nor any admin LiveView passes `sticky`, so this is precisely the
  # previously-broken path).
  describe "app/1 mobile nav drawer — server-rendered open state (01.8.2-09 Task 1, D-12/G-01.8.1-1b)" do
    test "the hamburger opens the drawer on a public page (/)", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      # At rest: closed, inert, aria-expanded false — the same server-
      # rendered signal a browser-less test can assert on.
      assert html =~ ~s(id="pk-nav-drawer")
      refute html =~ ~s(class="pk-drawer is-open")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ "inert"

      opened_html = view |> element(".pk-nav-hamburger") |> render_click()

      assert opened_html =~ ~s(class="pk-drawer is-open")
      assert opened_html =~ ~s(aria-expanded="true")

      drawer_html =
        opened_html |> LazyHTML.from_document() |> LazyHTML.query("#pk-nav-drawer") |> LazyHTML.to_html()

      refute drawer_html =~ "inert",
             "inert must be absent once the drawer is open — inert={!@open} renders the bare " <>
               "boolean attribute only when @open is false"
    end

    test "the hamburger opens the drawer on an admin page (/admin), the page G-01.8.1-1b was reported from" do
      %{conn: conn} = register_and_log_in_staff(%{conn: conn()})

      {:ok, view, html} = live(conn, ~p"/admin")

      refute html =~ ~s(class="pk-drawer is-open")
      assert html =~ ~s(aria-expanded="false")

      opened_html = view |> element(".pk-nav-hamburger") |> render_click()

      assert opened_html =~ ~s(class="pk-drawer is-open")
      assert opened_html =~ ~s(aria-expanded="true")
    end

    test "the close button (inside the component) closes the drawer again, toggling aria-expanded back" do
      {:ok, view, _html} = live(conn(), ~p"/")

      view |> element(".pk-nav-hamburger") |> render_click()
      closed_html = view |> element(".pk-drawer-close") |> render_click()

      refute closed_html =~ ~s(class="pk-drawer is-open")
      assert closed_html =~ ~s(aria-expanded="false")
      assert closed_html =~ "inert"
    end

    test "the backdrop (a plain sibling div outside the component) also closes the drawer, via phx-target" do
      {:ok, view, _html} = live(conn(), ~p"/")

      view |> element(".pk-nav-hamburger") |> render_click()
      closed_html = view |> element("#pk-nav-drawer-backdrop") |> render_click()

      refute closed_html =~ ~s(class="pk-drawer is-open")
      assert closed_html =~ ~s(aria-expanded="false")
    end

    test "the hamburger and the backdrop both target #pk-nav-drawer directly — no shared hook required" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      hamburger_html =
        html |> LazyHTML.from_document() |> LazyHTML.query(".pk-nav-hamburger") |> LazyHTML.to_html()

      backdrop_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#pk-nav-drawer-backdrop")
        |> LazyHTML.to_html()

      assert hamburger_html =~ ~s(phx-click="open")
      assert hamburger_html =~ ~s(phx-target="#pk-nav-drawer")
      assert backdrop_html =~ ~s(phx-click="close")
      assert backdrop_html =~ ~s(phx-target="#pk-nav-drawer")
    end

    test "the drawer's own colocated hook (.NavDrawerFocus) renders unconditionally, regardless of @sticky" do
      non_sticky = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
      sticky = render_component(&Layouts.app/1, %{flash: %{}, inner_block: [], sticky: true})

      for html <- [non_sticky, sticky] do
        drawer_html =
          html |> LazyHTML.from_document() |> LazyHTML.query("#pk-nav-drawer") |> LazyHTML.to_html()

        assert drawer_html =~ "phx-hook"
        assert drawer_html =~ "NavDrawerFocus"
      end
    end

    defp conn, do: Phoenix.ConnTest.build_conn()
  end

  # Task 2, plan 01.8.2-09 (D-19d): the drawer moves to the leading (left)
  # edge site-wide — the BENCHMARK's deviation D-4, resolved ALIGN. Asserts
  # against assets/css/app.css's SOURCE (not rendered markup, since the
  # anchoring lives in a CSS rule, not an HTML attribute) using the exact
  # negative-grep idiom this plan's own <verify> runs, so this test and the
  # CI/CD gate can never silently drift apart.
  describe "the drawer moves left, site-wide (01.8.2-09 Task 2, D-19d)" do
    @app_css_path Path.expand("../../../assets/css/app.css", __DIR__)

    test "no .pk-drawer rule in app.css anchors to the right edge" do
      # Same shell pipeline as this plan's own <verify> command, run here
      # too so this ExUnit gate and the plan's verify can never silently
      # drift apart from re-implementing the same check two different ways.
      cmd = """
      grep -vE '^\\s*(/\\*|\\*)' #{@app_css_path} | grep -B2 -A2 "pk-drawer" | grep -cE "right: *0"
      """

      {output, _exit} = System.shell(cmd)

      assert String.trim(output) == "0",
             "A .pk-drawer-adjacent rule still anchors to the right edge — D-19d moves the " <>
               "drawer left SITE-WIDE, and a half-moved drawer is worse than either position."
    end

    test "the .pk-drawer rule anchors left: 0 and enters via a negative translateX" do
      css = File.read!(@app_css_path)

      drawer_rule =
        case Regex.run(~r/(?m)^\.pk-drawer\s*\{([^}]*)\}/s, css) do
          [_, body] -> body
          nil -> flunk("no top-level `.pk-drawer { ... }` rule found in assets/css/app.css")
        end

      assert drawer_rule =~ ~r/left:\s*0\b/
      refute drawer_rule =~ ~r/right:\s*0\b/
      assert drawer_rule =~ ~r/transform:\s*translateX\(-100%\)/
    end

    test "the drawer opens flush against the left edge (translateX(0) once .is-open, same as before the move)" do
      css = File.read!(@app_css_path)

      open_rule =
        case Regex.run(~r/(?m)^\.pk-drawer\.is-open\s*\{([^}]*)\}/s, css) do
          [_, body] -> body
          nil -> flunk("no top-level `.pk-drawer.is-open { ... }` rule found in assets/css/app.css")
        end

      assert open_rule =~ ~r/transform:\s*translateX\(0\)/
    end

    test "the hamburger renders before the brand wordmark in header DOM order" do
      html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})

      hamburger_index = html |> :binary.match(~s(class="pk-nav-hamburger")) |> elem(0)
      brand_index = html |> :binary.match(~s(pk-brand-wordmark)) |> elem(0)

      assert hamburger_index < brand_index,
             "The hamburger must precede the brand wordmark in DOM order — with no `order` " <>
               "override anywhere in app.css (verified: no `order:` property on any .pk-nav-* " <>
               "or .pk-drawer* selector), plain flex DOM order is what visually places the " <>
               "hamburger on the left, D-19d's other half."
    end

    test "assets/css/admin/chrome.css exists and opens with a comment stating the public-vs-admin CSS split" do
      chrome_css_path = Path.expand("../../../assets/css/admin/chrome.css", __DIR__)

      assert File.exists?(chrome_css_path)

      content = File.read!(chrome_css_path)
      assert content |> String.trim_leading() |> String.starts_with?("/*")
      assert content =~ "PUBLIC-VS-ADMIN SPLIT"
      assert content =~ "app.css"
    end

    test "app.css imports admin/chrome.css" do
      css = File.read!(@app_css_path)
      assert css =~ ~s(@import "./admin/chrome.css";)
    end
  end

  # Task 3, plan 01.8.2-09 (D-13a): the staff sectioned drawer. Real routes
  # (not render_component/2) since staff_session?/1 needs a real
  # @current_scope from an authenticated conn, and D-00b's footer gate
  # needs a real admin route too.
  describe "the staff sectioned drawer, Panel/Sitio/Tu cuenta (01.8.2-09 Task 3, D-13a)" do
    test "a signed-in staff member sees all three sections on a public page (/)" do
      staff = PukllayClub.AccountsFixtures.staff_fixture()
      conn = PukllayClubWeb.ConnCase.log_in_user(Phoenix.ConnTest.build_conn(), staff)

      {:ok, _view, html} = live(conn, ~p"/")

      drawer_html =
        html |> LazyHTML.from_document() |> LazyHTML.query("#pk-nav-drawer") |> LazyHTML.to_html()

      assert drawer_html =~ "Panel"
      assert drawer_html =~ "Sitio"
      assert drawer_html =~ "Tu cuenta"
      assert drawer_html =~ "Admin"
      assert drawer_html =~ "Web"
      assert drawer_html =~ "Perfil"
      assert drawer_html =~ "Salir"
      assert drawer_html =~ staff.email
    end

    test "a signed-in staff member sees the same three sections on an admin page (/admin)" do
      staff = PukllayClub.AccountsFixtures.staff_fixture()
      conn = PukllayClubWeb.ConnCase.log_in_user(Phoenix.ConnTest.build_conn(), staff)

      {:ok, _view, html} = live(conn, ~p"/admin")

      drawer_html =
        html |> LazyHTML.from_document() |> LazyHTML.query("#pk-nav-drawer") |> LazyHTML.to_html()

      assert drawer_html =~ "Panel"
      assert drawer_html =~ "Sitio"
      assert drawer_html =~ "Tu cuenta"
    end

    test "an anonymous visitor's drawer contains none of Panel/Sitio/Tu cuenta" do
      {:ok, _view, html} = live(Phoenix.ConnTest.build_conn(), ~p"/")

      drawer_html =
        html |> LazyHTML.from_document() |> LazyHTML.query("#pk-nav-drawer") |> LazyHTML.to_html()

      refute drawer_html =~ "Panel"
      refute drawer_html =~ "Sitio"
      refute drawer_html =~ "Tu cuenta"
      refute drawer_html =~ "Perfil"
      refute drawer_html =~ "Salir"

      # The anonymous drawer is otherwise byte-identical to before Task 3:
      # still exactly the two public rows.
      assert drawer_html =~ "Inicio"
      assert drawer_html =~ "Quiénes Somos"
    end

    test "form_label/1 rank=\"group\" (13px/600 sentence case) drives the section labels, not the old 11px uppercase .group-label look" do
      staff = PukllayClub.AccountsFixtures.staff_fixture()
      conn = PukllayClubWeb.ConnCase.log_in_user(Phoenix.ConnTest.build_conn(), staff)

      {:ok, _view, html} = live(conn, ~p"/")

      drawer_html =
        html |> LazyHTML.from_document() |> LazyHTML.query("#pk-nav-drawer") |> LazyHTML.to_html()

      assert drawer_html =~ "pk-admin-label--group"
      refute drawer_html =~ "group-label"
    end

    test "the public GET / still renders its footer for an anonymous visitor (footer gate does not over-apply)" do
      {:ok, _view, html} = live(Phoenix.ConnTest.build_conn(), ~p"/")

      assert html =~ "<footer"
      assert html =~ "pk-footer"
    end

    test "the public GET / still renders its footer for a signed-in staff member too" do
      staff = PukllayClub.AccountsFixtures.staff_fixture()
      conn = PukllayClubWeb.ConnCase.log_in_user(Phoenix.ConnTest.build_conn(), staff)

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "<footer"
      assert html =~ "pk-footer"
    end
  end

  describe "tab_bar/1, the 5-tab admin bar (01.8.2-10 Task 1, D-13b)" do
    test "a signed-in staff member sees five destinations on /admin, and the active one carries the indicator" do
      staff = PukllayClub.AccountsFixtures.staff_fixture()
      conn = PukllayClubWeb.ConnCase.log_in_user(Phoenix.ConnTest.build_conn(), staff)

      {:ok, _view, html} = live(conn, ~p"/admin")

      tab_bar_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-admin-tab-bar")
        |> LazyHTML.to_html()

      assert tab_bar_html =~ "Admin"
      assert tab_bar_html =~ "Juegos"
      assert tab_bar_html =~ "Estantes"
      assert tab_bar_html =~ "Web"
      assert tab_bar_html =~ "Perfil"

      [admin_link] = Regex.run(~r/<a[^>]*href="\/admin"[^>]*>/, tab_bar_html)
      assert admin_link =~ "is-active"
      assert admin_link =~ ~s(aria-current="page")

      [juegos_link] = Regex.run(~r/<a[^>]*href="\/admin\/juegos"[^>]*>/, tab_bar_html)
      refute juegos_link =~ "is-active"
      refute juegos_link =~ "aria-current"
    end

    test "an anonymous visitor's / markup contains no tab bar" do
      {:ok, _view, html} = live(Phoenix.ConnTest.build_conn(), ~p"/")

      refute html =~ "pk-admin-tab-bar"
    end

    test "the tab bar's own height is declared once and consumed by the snackbar offset and page clearance via calc()" do
      chrome_css =
        File.read!(Path.expand("../../../assets/css/admin/chrome.css", __DIR__))

      components_css =
        File.read!(Path.expand("../../../assets/css/admin/components.css", __DIR__))

      assert chrome_css =~ ~r/--pk-tab-bar-h:\s*67px;/
      assert components_css =~ ~r/bottom:\s*calc\(var\(--pk-tab-bar-h,\s*0px\)/
      assert chrome_css =~ ~r/\.pk-admin-has-tab-bar\s*\{\s*padding-bottom:\s*calc\(var\(--pk-tab-bar-h\)/
    end

    test "a badge of 0 renders no badge element" do
      staff = PukllayClub.AccountsFixtures.staff_fixture()
      scope = PukllayClub.AccountsFixtures.user_scope_fixture(staff)

      html =
        render_component(&Layouts.tab_bar/1, %{
          current_scope: scope,
          active_tab: :admin,
          badges: %{juegos: 0}
        })

      refute html =~ "pk-admin-tab-badge"
    end

    test "a badge of 150 renders 99+ visually and puts 150 in the accessible name" do
      staff = PukllayClub.AccountsFixtures.staff_fixture()
      scope = PukllayClub.AccountsFixtures.user_scope_fixture(staff)

      html =
        render_component(&Layouts.tab_bar/1, %{
          current_scope: scope,
          active_tab: :admin,
          badges: %{juegos: 150}
        })

      assert html =~ "pk-admin-tab-badge"
      assert html =~ "99+"
      refute html =~ ">150<"
      assert html =~ ~s(aria-label="Juegos, 150 pendientes")
    end

    test "Perfil renders as an avatar tab that opens the nav drawer, not a navigate link" do
      staff = PukllayClub.AccountsFixtures.staff_fixture()
      scope = PukllayClub.AccountsFixtures.user_scope_fixture(staff)

      html = render_component(&Layouts.tab_bar/1, %{current_scope: scope})

      perfil_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-admin-tab--avatar")
        |> LazyHTML.to_html()

      assert perfil_html =~ "Perfil"
      assert perfil_html =~ ~s(phx-click="open")
      assert perfil_html =~ ~s(phx-target="#pk-nav-drawer")
      refute perfil_html =~ "navigate"
    end

    test ".pk-nav-admin is retired (display: none) now that the tab bar supersedes it" do
      chrome_css =
        File.read!(Path.expand("../../../assets/css/admin/chrome.css", __DIR__))

      assert chrome_css =~ ~r/\.pk-nav-inner \.pk-nav-admin\s*\{\s*display:\s*none;/
    end
  end

  # social_links/1 is now a PUBLIC component (promoted in plan 01.4-02
  # Task 3) with three real call sites: the footer (.pk-footer-social), the
  # mobile drawer (.pk-drawer-social), and the About page's Contacto card
  # (.pk-about-contact-links, AboutLive). The footer/drawer tests below keep
  # exercising it indirectly through Layouts.app/1's rendered subtree, since
  # neither call site passes icons/labels and both must stay
  # byte-identical to their pre-promotion output. The `icons`/`labels` attrs
  # themselves are covered directly via render_component/2 further below.
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

  describe "social_links/1 icons/labels attrs (plan 01.4-02 Task 3, direct render_component/2)" do
    test "default icons/labels reproduce the four-icon, no-label footer/drawer shape" do
      html = render_component(&Layouts.social_links/1, %{class: "test-social"})

      links = html |> LazyHTML.from_document() |> LazyHTML.query(".test-social a")
      assert Enum.count(links) == 4

      refute html =~ "Grupo de WhatsApp"
      refute html =~ ">Facebook<"
      refute html =~ ">Instagram<"
      refute html =~ ">Correo<"
    end

    test "icons subset renders only the requested channels, in order" do
      html =
        render_component(&Layouts.social_links/1, %{
          class: "test-social",
          icons: [:whatsapp, :instagram]
        })

      doc = LazyHTML.from_document(html)
      links = LazyHTML.query(doc, ".test-social a")
      hrefs = LazyHTML.attribute(links, "href")

      assert Enum.count(links) == 2

      assert hrefs == [
               PukllayClubWeb.ClubLinks.whatsapp_group_url(),
               PukllayClubWeb.ClubLinks.instagram_url()
             ]
    end

    test "labels: true renders a visible Spanish text label alongside the icon" do
      html =
        render_component(&Layouts.social_links/1, %{
          class: "test-social",
          icons: [:whatsapp, :instagram],
          labels: true
        })

      assert html =~ "Grupo de WhatsApp"
      assert html =~ ">Instagram<"
    end

    test "labels: false (default) renders no text label" do
      html =
        render_component(&Layouts.social_links/1, %{
          class: "test-social",
          icons: [:whatsapp]
        })

      refute html =~ "Grupo de WhatsApp"
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
