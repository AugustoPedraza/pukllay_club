defmodule PukllayClubWeb.CatalogLive.IndexTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

  describe "GET /" do
    test "mounts for an unauthenticated visitor with no redirect (CATALOG-08)", %{conn: conn} do
      game_fixture()

      assert {:ok, _view, _html} = live(conn, ~p"/")
    end

    test "renders the seeded game's name", %{conn: conn} do
      game_fixture(%{name: "On Mars"})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "On Mars"
    end

    test "renders the game cover as an img whose src starts with the R2 public base URL", %{
      conn: conn
    } do
      game_fixture(%{
        thumbnail_url: "https://images.test.invalid/games/184267/cover-thumb.webp"
      })

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~s(src="https://images.test.invalid/games/184267/cover-thumb.webp")
    end

    test "never renders a BGG-hosted image src (CATALOG-09)", %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      image_srcs =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("img")
        |> LazyHTML.attribute("src")

      refute Enum.any?(image_srcs, &(&1 =~ "geekdo-images.com"))
      refute Enum.any?(image_srcs, &(&1 =~ "boardgamegeek.com"))
    end

    # A "Powered by BGG" attribution *link* (D-04, plan 01.1-01 Task 3, not
    # a hotlinked image src) legitimately points at boardgamegeek.com from
    # the shared footer on every page — the assertion above scopes to `img`
    # src attributes specifically so it stays correct alongside that link.

    test "renders the brand placeholder (not a broken image) for a game with no thumbnail, keeping the title accessible (D-18)",
         %{conn: conn} do
      game_fixture(%{
        name: "Juego Sin BGG",
        bgg_id: nil,
        thumbnail_url: nil,
        cover_url: nil,
        enrichment_status: "no_bgg_id"
      })

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "hero-puzzle-piece"
      assert html =~ "Juego Sin BGG"
    end

    test "clamps a long game title with the single-line caption treatment instead of pushing the card layout",
         %{conn: conn} do
      game_fixture(%{
        name: "Un título extraordinariamente largo que debería ocupar más de dos líneas de texto"
      })

      {:ok, _view, html} = live(conn, ~p"/")

      assert grid_html(html) =~ "pk-card-caption"
    end

    test "a resting grid card renders neither a weight-band label nor its descriptor (sketch 002)",
         %{conn: conn} do
      game_fixture(%{name: "Juego Banded", weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/")
      card_html = html |> grid_html() |> strip_preview_templates()

      refute card_html =~ "Ingenio estratega"
      refute card_html =~ "Reglas de 15-20 minutos"
    end

    test "a resting grid card carries no chip, badge, or button markup for a game with tags and mechanics (sketch 002)",
         %{conn: conn} do
      game_fixture(%{
        name: "Juego Con Chips",
        tags: ["#CreaConexiones", "#EquipoGanador", "#DuelosMemorables"],
        mechanics: [
          "Dice Rolling",
          "Hand Management",
          "Worker Placement",
          "Tile Placement",
          "Race"
        ],
        weight_band: "descubre_el_hobby"
      })

      {:ok, _view, html} = live(conn, ~p"/")
      card_html = html |> grid_html() |> strip_preview_templates()

      refute card_html =~ "badge"
      refute card_html =~ "#CreaConexiones"
      refute card_html =~ "#EquipoGanador"
      refute card_html =~ "#DuelosMemorables"
      refute card_html =~ "btn btn-primary btn-sm"
    end

    test "the cover image carries the js-cover-fallback class and a hidden placeholder sibling",
         %{conn: conn} do
      game_fixture(%{
        name: "Juego Con Portada",
        thumbnail_url: "https://images.test.invalid/games/1/cover-thumb.webp"
      })

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "js-cover-fallback"
      assert html =~ "hero-puzzle-piece"
    end

    test "a card's inert preview template carries that game's description and weight-band label, proving the metadata moved rather than disappeared",
         %{conn: conn} do
      game_fixture(%{
        name: "Juego Con Metadata",
        description: "Una descripción única de este juego.",
        weight_band: "nivel_experto"
      })

      {:ok, _view, html} = live(conn, ~p"/")
      card_html = grid_html(html)

      assert card_html =~ "data-game-preview"
      assert card_html =~ "Una descripción única de este juego."
      assert card_html =~ "Nivel experto"
    end

    test "the Ver detalles CTA links to the game's detail page", %{conn: conn} do
      game = game_fixture(%{name: "Juego Detalle"})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~s(href="/juegos/#{game.id}")
    end

    test "renders inside its own max-w-7xl container, with no 672px ancestor cap", %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "max-w-7xl"
      refute html =~ "max-w-2xl"
    end

    test "renders the shared footer (SHELL-01)", %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "pk-footer"
    end
  end

  describe "live filtering, search, sort, and pagination (D-12, D-14, D-15, CATALOG-02/03/04)" do
    test "typing into the search input re-renders the grid with the matching subset, no submit button",
         %{conn: conn} do
      game_fixture(%{name: "Terra Mystica"})
      game_fixture(%{name: "Otro Juego"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Terra"})

      assert html =~ "Terra Mystica"
      refute html =~ "Otro Juego"
    end

    test "toggling a mechanic pill re-renders the grid; toggling it again restores the previous set",
         %{conn: conn} do
      # Selector targets an `input[type=checkbox]`, not a `button` (Task 3
      # moved mechanics into the searchable checklist inside the
      # disclosure) — `toggle-facet` and its phx-value-* pair are unchanged,
      # only the element carrying them changed.
      game_fixture(%{name: "Dice Game", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Other Game", mechanics: ["Auction / Bidding"]})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("input[phx-value-facet=mechanics][phx-value-choice='Tira dados']")
        |> render_click()

      assert html =~ "Dice Game"
      refute html =~ "Other Game"

      html2 =
        view
        |> element("input[phx-value-facet=mechanics][phx-value-choice='Tira dados']")
        |> render_click()

      assert html2 =~ "Dice Game"
      assert html2 =~ "Other Game"
    end

    test "two selected mechanic pills produce a result set that includes games matching either pill",
         %{conn: conn} do
      game_fixture(%{name: "Dice Game", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Worker Game", mechanics: ["Worker Placement"]})
      game_fixture(%{name: "Neither Game", mechanics: ["Auction / Bidding"]})

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("input[phx-value-facet=mechanics][phx-value-choice='Tira dados']")
      |> render_click()

      html =
        view
        |> element("input[phx-value-facet=mechanics][phx-value-choice='Coloca trabajadores']")
        |> render_click()

      assert html =~ "Dice Game"
      assert html =~ "Worker Game"
      refute html =~ "Neither Game"
    end

    test "search text and an active mechanic pill apply together — clearing search restores the pill-filtered set",
         %{conn: conn} do
      game_fixture(%{name: "Catán Dice", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Catán Cards", mechanics: ["Auction / Bidding"]})
      game_fixture(%{name: "Other Dice", mechanics: ["Dice Rolling"]})

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("input[phx-value-facet=mechanics][phx-value-choice='Tira dados']")
      |> render_click()

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Catán"})

      assert html =~ "Catán Dice"
      refute html =~ "Catán Cards"
      refute html =~ "Other Dice"

      html2 =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: ""})

      assert html2 =~ "Catán Dice"
      assert html2 =~ "Other Dice"
      refute html2 =~ "Catán Cards"
    end

    test "a non-default ?sort= param reorders the rendered cards", %{conn: conn} do
      game_fixture(%{name: "Alfa Corto", playing_time: 20})
      game_fixture(%{name: "Zeta Largo", playing_time: 120})

      {:ok, _view, html} = live(conn, ~p"/")

      assert position(grid_html(html), "Alfa Corto") < position(grid_html(html), "Zeta Largo")

      {:ok, _view, html2} = live(conn, ~p"/?sort=playtime_desc")

      assert position(grid_html(html2), "Zeta Largo") < position(grid_html(html2), "Alfa Corto")
    end

    test "pressing Cargar más appends the next page and leaves already-rendered cards in place", %{
      conn: conn
    } do
      for n <- 1..30 do
        game_fixture(%{name: "Juego #{String.pad_leading(Integer.to_string(n), 2, "0")}"})
      end

      {:ok, view, html} = live(conn, ~p"/")

      assert card_count(html) == 24
      assert html =~ "Juego 01"

      html2 =
        view
        |> element("button", "Cargar más")
        |> render_click()

      assert card_count(html2) == 30
      assert html2 =~ "Juego 01"
    end

    test "changing any filter resets pagination back to the first page", %{conn: conn} do
      for n <- 1..30 do
        game_fixture(%{name: "G#{n}", mechanics: ["Dice Rolling"]})
      end

      {:ok, view, html} = live(conn, ~p"/")
      assert html =~ "Cargar más"

      view |> element("button", "Cargar más") |> render_click()

      html2 =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "G1"})

      refute html2 =~ "Cargar más"
    end

    test "a filter combination with no matches renders the empty state, and Limpiar filtros restores results",
         %{conn: conn} do
      game_fixture(%{name: "Existing Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "no existe ningún juego con este nombre"})

      assert html =~ "No se encontraron juegos"
      assert html =~ "Probá con otros filtros o términos de búsqueda."
      refute html =~ "No encontramos juegos con esos filtros"
      assert html =~ "Limpiar filtros"

      # Scoped to .pk-state button.btn-primary (quick-260824-b71): the
      # empty-state's own clear-filters button lives inside .pk-state.
      # FilterModal's footer clear-filters button is now ALSO btn-primary
      # (its "secondary" tier is "btn-outline btn-primary", per
      # ui-design-system's component inventory) — a bare .btn-primary
      # selector is ambiguous between the two, so scope by ancestor instead.
      html2 =
        view
        |> element(".pk-state button.btn-primary", "Limpiar filtros")
        |> render_click()

      assert html2 =~ "Existing Game"
    end

    test "the empty state renders exactly one button inside .pk-state (01.1-07)", %{conn: conn} do
      game_fixture(%{name: "Existing Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "no existe ningún juego con este nombre"})

      pk_state_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-state")
        |> LazyHTML.to_html()

      assert pk_state_html =~ "No se encontraron juegos"
      assert ~r/<button\b/ |> Regex.scan(pk_state_html) |> length() == 1
    end

    test "the result count renders in correct Spanish singular/plural form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "0 juegos encontrados"

      game_fixture(%{name: "Solo Juego"})
      {:ok, _view2, html2} = live(conn, ~p"/")
      assert html2 =~ "1 juego encontrado"

      game_fixture(%{name: "Otro Juego"})
      {:ok, _view3, html3} = live(conn, ~p"/")
      assert html3 =~ "2 juegos encontrados"
    end

    test "when the catalog query raises, the page renders the error-state banner instead of crashing",
         %{conn: conn} do
      game_fixture(%{name: "Existing Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      # Was driven through the now-removed #filter-modal-scalars set-scalar
      # form (quick-260824-b71 deleted it in favor of toggle-scalar chips) —
      # an out-of-Postgres-int-range value reaches the same
      # safe_filter_games/1 rescue via the players chip's toggle-scalar
      # event instead.
      html =
        render_click(view, "toggle-scalar", %{
          "scalar" => "players",
          "choice" => "99999999999999"
        })

      assert html =~ "No pudimos cargar el catálogo"
      assert html =~ "Hubo un problema de conexión."
      assert html =~ "Reintentar"
      # The daisyUI flash placeholders (always present, hidden) legitimately
      # carry "alert-error" as one of several classes — scoped to the old
      # two-class combo this state used to render, not a bare substring.
      refute html =~ ~s(class="alert alert-error")
    end

    test "dispatching retry while the catalog is healthy re-renders a populated grid (01.1-07)", %{
      conn: conn
    } do
      game_fixture(%{name: "Retry Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html = render_click(view, "retry", %{})

      assert html =~ "Retry Game"
    end
  end

  describe "curated carousel rows and loading skeletons (D-08, D-09)" do
    test "the unfiltered browse page renders the 8 fixed carousel rows in D-09 order", %{
      conn: conn
    } do
      game_fixture(%{name: "Crea Game", tags: ["#CreaConexiones"]})
      game_fixture(%{name: "Equipo Game", tags: ["#EquipoGanador"]})
      game_fixture(%{name: "Duelos Game", tags: ["#DuelosMemorables"]})
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Estratega Game", weight_band: "ingenio_estratega"})
      game_fixture(%{name: "Experto Game", weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/")

      titles = [
        "Destacados del club",
        "Crea conexiones",
        "Equipo ganador",
        "Duelos memorables",
        "Descubre el hobby",
        "Ingenio estratega",
        "Nivel experto",
        "Recientemente añadidos"
      ]

      Enum.each(titles, fn title -> assert html =~ title end)

      # Scoped to the row `<h2>` headings, not a whole-row substring search —
      # 01-06's weight-band badges render label text (e.g. "Ingenio
      # estratega") identical to a row heading string *inside a card*, which
      # can appear in an earlier row (e.g. Destacados) whenever that game
      # also carries an editorial tag, breaking a naive position/2 search.
      heading_texts =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-rows h2")
        |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

      assert heading_texts == titles
    end

    test "a carousel row backed by zero games renders neither its title nor an empty rail", %{
      conn: conn
    } do
      game_fixture(%{name: "Only Recent Game", tags: []})

      {:ok, _view, html} = live(conn, ~p"/")

      refute html =~ "Equipo ganador"
      refute html =~ "Duelos memorables"
    end

    test "after applying a filter, the carousel section is absent from the rendered page", %{
      conn: conn
    } do
      game_fixture(%{name: "Filtered Game", mechanics: ["Dice Rolling"]})

      {:ok, view, html} = live(conn, ~p"/")
      assert html =~ "Destacados del club"

      html2 =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Filtered"})

      refute html2 =~ "Destacados del club"
      refute html2 =~ "Recientemente añadidos"
    end

    test "the initial disconnected render shows flat-skeleton card placeholders, not an empty grid",
         %{conn: conn} do
      game_fixture(%{name: "Some Game"})

      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ "pk-skel"
      refute html =~ "animate-pulse"
      refute html =~ ~s("skeleton")
    end
  end

  describe "differentiated row headers and titled main grid (G-01-4)" do
    test "the hero row renders in the primary colour and a weight-band row renders its Vocabulary descriptor as a subtitle",
         %{conn: conn} do
      game_fixture(%{name: "Destacado Game", tags: ["#CreaConexiones"]})
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})

      {:ok, _view, html} = live(conn, ~p"/")

      carousel_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-rows")
        |> LazyHTML.to_html()

      assert carousel_html =~ "text-primary"
      assert carousel_html =~ "Reglas cortas que se explican en 5-10 minutos. Ideal si es tu primera vez."
    end

    test "the unfiltered landing render contains the main-grid section heading", %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "El catálogo completo"
    end

    test "a filtered render shows the results-wording heading and hides the carousel block", %{
      conn: conn
    } do
      game_fixture(%{name: "Filtered Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Filtered"})

      assert html =~ "Resultados"
      refute html =~ "El catálogo completo"
      refute html =~ "id=\"carousel-rows\""
    end
  end

  describe "persistent, discoverable carousel scroll controls (G-01-3)" do
    test "the landing render includes the rail marker and both scroll controls with Spanish aria-labels, and no inline script tag",
         %{conn: conn} do
      game_fixture(%{name: "Rail Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "data-rail"
      assert html =~ ~s(data-scroll="prev")
      assert html =~ ~s(data-scroll="next")
      assert html =~ "Desplazar hacia la izquierda"
      assert html =~ "Desplazar hacia la derecha"
      # Proves the colocated hook was extracted at compile time rather than
      # rendered inline (this app's CSP script-src would refuse an inline
      # <script> body) — the page's own two <script src="..."> tags for
      # app.js/theme.js are expected and unaffected by this check.
      refute html =~ "export default"
    end

    test "sketch 022-C: each rendered shelf's two scroll buttons live inside .pk-rail-wrap, none inside .pk-row-header, and no daisyUI circular-button class remains",
         %{conn: conn} do
      game_fixture(%{name: "Rail Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      carousel_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-rows")
        |> LazyHTML.to_html()

      rail_wrap_buttons =
        carousel_html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(".pk-rail-wrap button[data-scroll]")

      row_header_buttons =
        carousel_html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(".pk-row-header button[data-scroll]")

      shelf_count =
        carousel_html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query("[data-rail-wrap]")
        |> Enum.count()

      assert Enum.count(rail_wrap_buttons) == shelf_count * 2
      assert Enum.empty?(row_header_buttons)
      refute carousel_html =~ "btn-circle"
      assert carousel_html =~ "data-rail-wrap"
    end

    test "sketch 022-C: CatalogLive.Show's Juegos similares shelf gets the identical treatment with no show.ex edit",
         %{conn: conn} do
      game = game_fixture(%{name: "Rail Detail Game"})
      game_fixture(%{name: "Similar Rail Game", bgg_id: 14, csv_row: 9_991})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game}")

      similares_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#similares")
        |> LazyHTML.to_html()

      rail_wrap_buttons =
        similares_html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(".pk-rail-wrap button[data-scroll]")

      row_header_buttons =
        similares_html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(".pk-row-header button[data-scroll]")

      assert Enum.count(rail_wrap_buttons) == 2
      assert Enum.empty?(row_header_buttons)
      refute similares_html =~ "btn-circle"
      assert similares_html =~ "data-rail-wrap"
    end
  end

  describe "shell-capped, gutter-aligned, edge-fade shelves (01-11, quick-260824-9zo)" do
    test "a shelf's row-header and rail-wrap both carry the shell column and gutter classes", %{
      conn: conn
    } do
      game_fixture(%{name: "Shelf Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      carousel_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-rows")
        |> LazyHTML.to_html()

      assert carousel_html =~ "pk-row-header mx-auto w-full max-w-7xl pk-gutter"
      assert carousel_html =~ "pk-rail-wrap mx-auto w-full max-w-7xl pk-gutter"
    end

    test "the disconnected skeleton row carries the same shell column and gutter classes as the real row",
         %{conn: conn} do
      html = conn |> get(~p"/") |> html_response(200)

      skeleton_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-rows")
        |> LazyHTML.to_html()

      assert skeleton_html =~ "pk-row-header mx-auto w-full max-w-7xl pk-gutter"
      assert skeleton_html =~ "pk-rail-wrap mx-auto w-full max-w-7xl pk-gutter"
    end

    test "the page renders the pk-page shell", %{conn: conn} do
      game_fixture(%{name: "Shell Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "pk-page"
    end

    test "every shelf heading is plain Spanish prose, never a raw hashtag string", %{conn: conn} do
      game_fixture(%{name: "Crea Game", tags: ["#CreaConexiones"]})
      game_fixture(%{name: "Equipo Game", tags: ["#EquipoGanador"]})
      game_fixture(%{name: "Duelos Game", tags: ["#DuelosMemorables"]})

      {:ok, _view, html} = live(conn, ~p"/")

      heading_texts =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-rows h2")
        |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

      assert heading_texts != []
      refute Enum.any?(heading_texts, &String.starts_with?(&1, "#"))
    end

    test "a rendered shelf carries the pk-shelf class that owns the anchor scroll offset", %{
      conn: conn
    } do
      game_fixture(%{name: "Anchor Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      carousel_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-rows")
        |> LazyHTML.to_html()

      assert carousel_html =~ "pk-shelf"
    end
  end

  describe "sticky, gutter-aligned nav (01-12)" do
    test "the search form renders inside the sticky header element", %{conn: conn} do
      game_fixture(%{name: "Nav Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header")
        |> LazyHTML.to_html()

      assert header_html =~ ~s(id="catalog-search-form")
    end

    test "the nav-links slot renders the shared Inicio/Quiénes Somos wayfinding links, not shelf anchors (SHELL-01)",
         %{conn: conn} do
      game_fixture(%{name: "Nav Wayfinding Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      nav_links_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-nav-links")
        |> LazyHTML.to_html()

      assert nav_links_html =~ ~s(href="/")
      assert nav_links_html =~ "Inicio"
      assert nav_links_html =~ ~s(href="/quienes-somos")
      assert nav_links_html =~ "Quiénes Somos"
    end

    test "the unfiltered landing render emits one chip per populated shelf, each targeting a real section id, bracketed by spacers",
         %{conn: conn} do
      game_fixture(%{name: "Chip Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      doc = LazyHTML.from_document(html)

      shelf_count = doc |> LazyHTML.query("#carousel-rows section") |> Enum.count()

      chip_targets =
        doc
        |> LazyHTML.query(".pk-chip-nav a.pk-chip")
        |> LazyHTML.attribute("data-chip-target")

      assert chip_targets != []
      assert length(chip_targets) == shelf_count

      Enum.each(chip_targets, fn id -> assert html =~ ~s(id="#{id}") end)

      chip_nav_html =
        doc
        |> LazyHTML.query(".pk-chip-nav")
        |> LazyHTML.to_html()
        |> String.trim()

      # First and last children are spacers: the innermost content right
      # after the opening <nav ...> tag, and right before </nav>, is each
      # a pk-chip-spacer span — never a chip.
      assert Regex.match?(~r/^<nav[^>]*>\s*<span[^>]*class="pk-chip-spacer"/, chip_nav_html)
      assert Regex.match?(~r/<span[^>]*class="pk-chip-spacer"[^>]*><\/span>\s*<\/nav>$/, chip_nav_html)
    end

    test "the chip nav is wrapped by .pk-chip-nav-wrap (sketch 020, quick-260824-jkc)", %{
      conn: conn
    } do
      game_fixture(%{name: "Chip Wrap Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      wrap_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-chip-nav-wrap")
        |> LazyHTML.to_html()

      assert wrap_html =~ ~s(class="pk-chip-nav")
    end

    test "a shelf backed by zero games produces no chip for it", %{conn: conn} do
      game_fixture(%{name: "Only Crea Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      chip_nav_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-chip-nav")
        |> LazyHTML.to_html()

      refute chip_nav_html =~ "carousel-equipo_ganador"
      refute chip_nav_html =~ "carousel-duelos_memorables"
    end

    test "a filtered render emits no chip row", %{conn: conn} do
      game_fixture(%{name: "Filtered Chip Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Filtered"})

      refute html =~ "pk-chip-nav"
    end
  end

  describe "desktop category mega-menu (SHELL-01, sketch 020, quick-260824-jkc)" do
    test "the unfiltered landing render emits a trigger and one .pk-cat-item per populated shelf, matching the chip row's targets",
         %{conn: conn} do
      game_fixture(%{name: "Cat Menu Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-cat-trigger") |> Enum.count() == 1

      shelf_count = doc |> LazyHTML.query("#carousel-rows section") |> Enum.count()

      panel_targets =
        doc |> LazyHTML.query(".pk-cat-item") |> LazyHTML.attribute("data-chip-target")

      chip_targets =
        doc |> LazyHTML.query(".pk-chip-nav a.pk-chip") |> LazyHTML.attribute("data-chip-target")

      assert panel_targets != []
      assert length(panel_targets) == shelf_count
      assert Enum.sort(panel_targets) == Enum.sort(chip_targets)

      Enum.each(panel_targets, fn id -> assert html =~ ~s(id="#{id}") end)
    end

    test "a shelf backed by zero games produces no panel item for it", %{conn: conn} do
      game_fixture(%{name: "Only Crea Menu Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      panel_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-cat-panel")
        |> LazyHTML.to_html()

      refute panel_html =~ "carousel-equipo_ganador"
      refute panel_html =~ "carousel-duelos_memorables"
    end

    test "a filtered render emits neither the trigger nor the panel", %{conn: conn} do
      game_fixture(%{name: "Filtered Cat Menu Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Filtered"})

      refute html =~ "pk-cat-trigger"
      refute html =~ "pk-cat-panel"
    end
  end

  describe "?q= deep link opens the search-morph pre-expanded (01.1-08)" do
    test "mounting /?q=<term> narrows the stream and renders the morph pre-expanded", %{
      conn: conn
    } do
      game_fixture(%{name: "Catan Deep Link"})
      game_fixture(%{name: "Unrelated Game"})

      {:ok, _view, html} = live(conn, "/?q=Catan")

      grid = grid_html(html)
      assert grid =~ "Catan Deep Link"
      refute grid =~ "Unrelated Game"
      assert html =~ ~s(data-search-expanded="true")
    end

    test "mounting / with no q renders the morph at rest (not pre-expanded)", %{conn: conn} do
      game_fixture(%{name: "Rest State Game"})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~s(data-search-expanded="false")
    end
  end

  describe "no join CTA in the header (D-05 superseded, plan 01.1-08)" do
    test "the #app-header subtree contains no join-CTA label", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header")
        |> LazyHTML.to_html()

      refute header_html =~ "Sumate"
    end
  end

  describe "mobile nav drawer active state (01.1-09)" do
    test "the drawer marks Inicio as the current page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      doc = LazyHTML.from_document(html)
      inicio_link = doc |> LazyHTML.query(".pk-drawer-links a:first-child") |> LazyHTML.to_html()
      quienes_link = doc |> LazyHTML.query(".pk-drawer-links a:last-child") |> LazyHTML.to_html()

      assert inicio_link =~ ~s(aria-current="page")
      refute quienes_link =~ ~s(aria-current="page")
    end
  end

  describe "About-scoped mobile sticky join-CTA bar is absent here (01.1-09)" do
    test "/ renders no .pk-about-cta-bar", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      refute html =~ "pk-about-cta-bar"
    end
  end

  describe "Ver todo tile wired to real filter state (01-11)" do
    test "clicking the tile on the tag-backed shelf renders only the tagged game and hides the shelves",
         %{conn: conn} do
      game_fixture(%{name: "Equipo Game", tags: ["#EquipoGanador"]})
      game_fixture(%{name: "Untagged Game", tags: []})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("button[phx-value-row=equipo_ganador]")
        |> render_click()

      grid = grid_html(html)
      assert grid =~ "Equipo Game"
      refute grid =~ "Untagged Game"
      refute html =~ ~s(id="carousel-rows")
    end

    test "clicking the tile on the band-backed shelf renders only games in that band", %{
      conn: conn
    } do
      game_fixture(%{name: "Experto Game", weight_band: "nivel_experto"})
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("button[phx-value-row=nivel_experto]")
        |> render_click()

      grid = grid_html(html)
      assert grid =~ "Experto Game"
      refute grid =~ "Hobby Game"
    end

    test "clicking the tile on the recency shelf reorders the grid newest-first and leaves the shelves rendered",
         %{conn: conn} do
      game_fixture(%{name: "Old Game", tags: ["#CreaConexiones"], year_published: 1995})
      game_fixture(%{name: "New Game", tags: ["#CreaConexiones"], year_published: 2023})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("button[phx-value-row=recientemente_anadidos]")
        |> render_click()

      grid = grid_html(html)
      assert position(grid, "New Game") < position(grid, "Old Game")
      assert html =~ ~s(id="carousel-rows")
    end

    test "an unrecognised row value leaves the result set unchanged rather than raising", %{
      conn: conn
    } do
      game_fixture(%{name: "Untouched Game"})

      {:ok, view, html} = live(conn, ~p"/")
      before_count = card_count(html)

      html2 = render_click(view, "see-all", %{"row" => "not-a-real-row"})

      assert card_count(html2) == before_count
      assert html2 =~ "Untouched Game"
    end
  end

  describe "Content-Security-Policy (T-01-28, closes Phase 0's deferred Sobelow Config.CSP finding)" do
    test "the response carries a content-security-policy header scoped to the configured image origin",
         %{conn: conn} do
      conn = get(conn, ~p"/")

      [policy] = get_resp_header(conn, "content-security-policy")

      assert policy =~ "img-src"
      assert policy =~ "'self'"
      assert policy =~ "https://images.test.invalid"
    end

    test "the policy locks down framing and never allows unsafe-eval scripts", %{conn: conn} do
      conn = get(conn, ~p"/")

      [policy] = get_resp_header(conn, "content-security-policy")

      assert policy =~ "frame-ancestors 'none'"
      refute policy =~ "unsafe-eval"
    end

    test "the policy's img-src never allows a BGG-hosted origin (CATALOG-09 enforced at the browser level)",
         %{conn: conn} do
      conn = get(conn, ~p"/")

      [policy] = get_resp_header(conn, "content-security-policy")

      refute policy =~ "geekdo"
      refute policy =~ "boardgamegeek"
    end
  end

  describe "composite: shelf structure, card, preview surfaces and nav compose together (01-12)" do
    test "the unfiltered landing page renders the whole assembled contract in one pass", %{
      conn: conn
    } do
      game_fixture(%{name: "Composite Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      # Sticky header wrapper + search form inside it
      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header")
        |> LazyHTML.to_html()

      assert header_html =~ "pk-header-sticky"
      assert header_html =~ ~s(id="catalog-search-form")

      # Nav links block
      assert header_html =~ "pk-nav-links"

      # Chip row — a SIBLING of the header, not a child of it (debug
      # search-right-align-mobile, cycle 5). This line used to assert
      # `header_html =~ "pk-chip-nav"`, back when the subnav slot rendered
      # inside `#app-header`. That element is `position: sticky; top: 0`, which
      # pinned the chip row along with the nav at every scroll position; the
      # user asked for the row to scroll away with the page, and nothing but
      # moving it out of that box can deliver it. Kept as a positive assertion
      # on the new location rather than deleted, so the composite still proves
      # the chip row is composed into the page — and `refute` on the old
      # location so a well-meaning revert has to argue with a test instead of
      # silently re-sticking the row. Placement is guarded in full, with the
      # scroll-spy consequence, by header_subnav_placement_test.exs.
      refute header_html =~ "pk-chip-nav"

      subnav_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-subnav")
        |> LazyHTML.to_html()

      assert subnav_html =~ "pk-chip-nav"

      # A gutter-shared row header and rail wrap, rail marker, scroll controls
      carousel_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-rows")
        |> LazyHTML.to_html()

      assert carousel_html =~ "pk-row-header mx-auto w-full max-w-7xl pk-gutter"
      assert carousel_html =~ "pk-rail-wrap mx-auto w-full max-w-7xl pk-gutter"
      assert carousel_html =~ "data-rail"
      assert carousel_html =~ ~s(data-scroll="prev")
      assert carousel_html =~ ~s(data-scroll="next")

      # A Ver todo tile
      assert carousel_html =~ "pk-see-all"

      # A card carrying the card marker and its preview template
      assert carousel_html =~ "data-game-card"
      assert carousel_html =~ "data-game-preview"

      # Preview host with portal and sheet containers
      assert html =~ ~s(id="game-preview-portal")
      assert html =~ ~s(id="game-preview-backdrop")
      assert html =~ ~s(id="game-preview-sheet")
    end
  end

  describe "filter surface reachable from the nav search box (SHELL-04, 01.1-06)" do
    test "exactly one filter-open affordance renders, no second Filtros trigger", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~s(aria-label="Abrir filtros")
      # The retired FilterDrawer's own trigger read literally ">Filtros<" as a
      # label rendered inline next to the icon (no aria-label). FilterModal's
      # own title heading also says "Filtros" (as text, inside <h2>), so a
      # bare substring check would false-positive on that — check for the
      # drawer's specific `<label for=... class="btn ...">` trigger shape
      # instead, which no longer exists anywhere in the page.
      refute html =~ "drawer-toggle"
      refute html =~ "drawer-side"
    end

    test "the filter-open button renders inside #pk-nav-search-region, not elsewhere", %{
      conn: conn
    } do
      {:ok, _view, html} = live(conn, ~p"/")

      region_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#pk-nav-search-region")
        |> LazyHTML.to_html()

      assert region_html =~ ~s(aria-label="Abrir filtros")
    end

    test "clicking the filter-open button opens the modal surface", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element(~s([aria-label="Abrir filtros"]))
        |> render_click()

      assert html =~ "modal-open"
      assert html =~ "Encuentra tu juego"
    end

    test "typing in the nav search box narrows the grid and does not open the filter surface", %{
      conn: conn
    } do
      game_fixture(%{name: "Catan Search"})
      game_fixture(%{name: "Unrelated Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Catan"})

      grid = grid_html(html)
      assert grid =~ "Catan Search"
      refute grid =~ "Unrelated Game"
      refute html =~ "class=\"modal modal-open\""
    end

    test "toggling a facet from inside the open surface narrows the grid and leaves the surface open",
         %{conn: conn} do
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Expert Game", weight_band: "nivel_experto"})

      {:ok, view, _html} = live(conn, ~p"/")

      view |> element(~s([aria-label="Abrir filtros"])) |> render_click()

      html =
        view
        |> element(~s(button[phx-value-facet="weight_bands"][phx-value-choice="descubre_el_hobby"]))
        |> render_click()

      grid = grid_html(html)
      assert grid =~ "Hobby Game"
      refute grid =~ "Expert Game"
      assert html =~ "modal-open"
    end

    test "the live match count in the surface changes as a facet is toggled", %{conn: conn} do
      game_fixture(%{name: "Hobby Game A", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Expert Game B", weight_band: "nivel_experto"})

      {:ok, view, _html} = live(conn, ~p"/")

      html_before = view |> element(~s([aria-label="Abrir filtros"])) |> render_click()
      assert html_before =~ "2 juegos encontrados"

      html_after =
        view
        |> element(~s(button[phx-value-facet="weight_bands"][phx-value-choice="descubre_el_hobby"]))
        |> render_click()

      assert html_after =~ "1 juego encontrado"
    end

    test "the surface closes on close-filters", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element(~s([aria-label="Abrir filtros"])) |> render_click()
      html = render_click(view, "close-filters", %{})

      refute html =~ "class=\"modal modal-open\""
    end

    test "with a facet active and q empty, the morph carries data-search-expanded=\"true\"", %{
      conn: conn
    } do
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element(~s(button[phx-value-facet="weight_bands"][phx-value-choice="descubre_el_hobby"]))
        |> render_click()

      assert html =~ ~s(data-search-expanded="true")
    end

    test "with no facet active and q empty, the morph carries data-search-expanded=\"false\"", %{
      conn: conn
    } do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~s(data-search-expanded="false")
    end

    test "/juegos/:id renders no filter-open affordance", %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game}")

      refute html =~ "Abrir filtros"
    end

    test "on first render the catalog wrapper carries pk-dimmable but not the dimmed modifier", %{
      conn: conn
    } do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "pk-dimmable"
      refute html =~ "is-dimmed"
    end

    test "opening the filter surface adds the dimmed modifier to the pk-dimmable wrapper", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element(~s([aria-label="Abrir filtros"]))
        |> render_click()

      assert html =~ "pk-dimmable"
      assert html =~ "is-dimmed"
    end

    test "closing the filter surface removes the dimmed modifier again", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element(~s([aria-label="Abrir filtros"])) |> render_click()
      html = render_click(view, "close-filters", %{})

      assert html =~ "pk-dimmable"
      refute html =~ "is-dimmed"
    end

    test "the header nav search input shares the modal's search placeholder", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header")
        |> LazyHTML.to_html()

      assert header_html =~ ~s(placeholder="¿Qué juego buscas?")
    end
  end

  describe "toggle-scalar chip handler (quick-260824-b71)" do
    test "toggling a players chip narrows the grid to games matching that exact seat count", %{
      conn: conn
    } do
      game_fixture(%{name: "Four Player Game", min_players: 2, max_players: 4})
      game_fixture(%{name: "Big Group Game", min_players: 5, max_players: 8})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        render_click(view, "toggle-scalar", %{"scalar" => "players", "choice" => "4"})

      grid = grid_html(html)
      assert grid =~ "Four Player Game"
      refute grid =~ "Big Group Game"
    end

    test "toggling the same players chip again clears it (toggle-off)", %{conn: conn} do
      game_fixture(%{name: "Four Player Game", min_players: 2, max_players: 4})
      game_fixture(%{name: "Big Group Game", min_players: 5, max_players: 8})

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "toggle-scalar", %{"scalar" => "players", "choice" => "4"})

      html =
        render_click(view, "toggle-scalar", %{"scalar" => "players", "choice" => "4"})

      grid = grid_html(html)
      assert grid =~ "Four Player Game"
      assert grid =~ "Big Group Game"
    end

    test "toggling max_playtime does not reset an already-active players chip", %{conn: conn} do
      game_fixture(%{
        name: "Match Game",
        min_players: 2,
        max_players: 6,
        max_playtime: 45
      })

      game_fixture(%{
        name: "Wrong Players Game",
        min_players: 5,
        max_players: 6,
        max_playtime: 30
      })

      game_fixture(%{
        name: "Wrong Duration Game",
        min_players: 2,
        max_players: 6,
        max_playtime: 120
      })

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "toggle-scalar", %{"scalar" => "players", "choice" => "4"})

      html =
        render_click(view, "toggle-scalar", %{"scalar" => "max_playtime", "choice" => "60"})

      grid = grid_html(html)
      assert grid =~ "Match Game"
      refute grid =~ "Wrong Players Game"
      refute grid =~ "Wrong Duration Game"
    end

    test "an unrecognised scalar leaves the socket unchanged rather than raising or creating a new atom",
         %{conn: conn} do
      game_fixture(%{name: "Untouched Scalar Game"})

      {:ok, view, html} = live(conn, ~p"/")
      before_count = card_count(html)

      html2 =
        render_click(view, "toggle-scalar", %{"scalar" => "__proto__", "choice" => "5"})

      assert card_count(html2) == before_count
      assert html2 =~ "Untouched Scalar Game"
    end

    test "an unparseable value degrades that scalar to nil rather than raising", %{conn: conn} do
      game_fixture(%{name: "Four Player Game", min_players: 2, max_players: 4})
      game_fixture(%{name: "Big Group Game", min_players: 5, max_players: 8})

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "toggle-scalar", %{"scalar" => "players", "choice" => "4"})

      html =
        render_click(view, "toggle-scalar", %{"scalar" => "players", "choice" => "abc"})

      grid = grid_html(html)
      assert grid =~ "Four Player Game"
      assert grid =~ "Big Group Game"
    end
  end

  describe "filter state read from URL query params (SHELL-04, 01.1-06)" do
    test "?weight_bands=<band> lands the catalog already filtered to that band", %{conn: conn} do
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Expert Game", weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/?weight_bands=descubre_el_hobby")

      grid = grid_html(html)
      assert grid =~ "Hobby Game"
      refute grid =~ "Expert Game"
    end

    test "?mechanics=<covered label> renders only matching games", %{conn: conn} do
      game_fixture(%{name: "Dice Game", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Other Game", mechanics: ["Trading"]})

      {:ok, _view, html} = live(conn, ~p"/?mechanics=Tira dados")

      grid = grid_html(html)
      assert grid =~ "Dice Game"
      refute grid =~ "Other Game"
    end

    test "an unrecognised facet value renders the unfiltered set rather than raising or zero rows",
         %{conn: conn} do
      game_fixture(%{name: "Any Game"})

      {:ok, _view, html_unfiltered} = live(conn, ~p"/")
      {:ok, _view2, html_bogus} = live(conn, ~p"/?mechanics=NoExiste")

      assert grid_html(html_unfiltered) =~ "Any Game"
      assert grid_html(html_bogus) =~ "Any Game"
    end

    test "a 50-element param list is truncated and the page still renders", %{conn: conn} do
      game_fixture(%{name: "Any Game"})

      long_list = Enum.map_join(1..50, ",", &"Fake#{&1}")

      assert {:ok, _view, html} = live(conn, ~p"/?mechanics=#{long_list}")
      assert html =~ "Any Game"
    end

    test "?sort=nope falls back to name order", %{conn: conn} do
      game_fixture(%{name: "Zebra Game", csv_row: 9001})
      game_fixture(%{name: "Alpha Game", csv_row: 9002})

      {:ok, _view, html} = live(conn, ~p"/?sort=nope")

      assert position(html, "Alpha Game") < position(html, "Zebra Game")
    end

    test "?players=abc leaves the players filter unset rather than raising", %{conn: conn} do
      game_fixture(%{name: "Any Game"})

      assert {:ok, _view, html} = live(conn, ~p"/?players=abc")
      assert grid_html(html) =~ "Any Game"
    end
  end

  defp position(html, text) do
    case :binary.match(html, text) do
      {pos, _} -> pos
      :nomatch -> flunk("expected #{inspect(text)} to be present in the rendered HTML")
    end
  end

  # Scopes assertions to the #games grid only — carousel rows (Task 3) also
  # render GameCard/skeleton_card markup on the same page, so a whole-page
  # substring search would double-count.
  defp grid_html(html) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("#games")
    |> LazyHTML.to_html()
  end

  defp card_count(html) do
    html
    |> grid_html()
    |> String.split("data-game-card")
    |> length()
    |> Kernel.-(1)
  end

  # A resting card's inert <template data-game-preview> carries the shared
  # preview body verbatim (Task 1), which legitimately contains chip/badge
  # markup (the sheet-only editorial tag) for cloning on interaction — that
  # is not part of the visible resting card. Strip it before asserting on
  # what actually renders at rest.
  defp strip_preview_templates(html) do
    Regex.replace(~r/<template[^>]*>.*?<\/template>/s, html, "")
  end
end
