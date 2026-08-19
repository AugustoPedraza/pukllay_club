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

      refute html =~ "geekdo-images.com"
      refute html =~ "boardgamegeek.com"
    end

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
      game_fixture(%{name: "Dice Game", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Other Game", mechanics: ["Auction / Bidding"]})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("button[phx-value-facet=mechanics][phx-value-value='Tira dados']")
        |> render_click()

      assert html =~ "Dice Game"
      refute html =~ "Other Game"

      html2 =
        view
        |> element("button[phx-value-facet=mechanics][phx-value-value='Tira dados']")
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
      |> element("button[phx-value-facet=mechanics][phx-value-value='Tira dados']")
      |> render_click()

      html =
        view
        |> element("button[phx-value-facet=mechanics][phx-value-value='Coloca trabajadores']")
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
      |> element("button[phx-value-facet=mechanics][phx-value-value='Tira dados']")
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

    test "changing the sort control reorders the rendered cards", %{conn: conn} do
      game_fixture(%{name: "Alfa Corto", playing_time: 20})
      game_fixture(%{name: "Zeta Largo", playing_time: 120})

      {:ok, view, html} = live(conn, ~p"/")

      assert position(grid_html(html), "Alfa Corto") < position(grid_html(html), "Zeta Largo")

      html2 =
        view
        |> element("select[name=sort]")
        |> render_change(%{sort: "playtime_desc"})

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

      assert html =~ "No encontramos juegos con esos filtros"
      assert html =~ "Limpiar filtros"

      html2 =
        view
        |> element("button", "Limpiar filtros")
        |> render_click()

      assert html2 =~ "Existing Game"
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

      html =
        view
        |> form("#filter-drawer-scalars")
        |> render_change(%{min_age: "99999999999999"})

      assert html =~ "No pudimos cargar el catálogo en este momento"
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

    test "the initial disconnected render shows skeleton card placeholders, not an empty grid", %{
      conn: conn
    } do
      game_fixture(%{name: "Some Game"})

      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ "skeleton"
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
  end

  describe "full-bleed edge-fade shelves, gutter-aligned (01-11)" do
    test "a shelf's row-header and rail-wrap both carry the shared gutter class", %{conn: conn} do
      game_fixture(%{name: "Shelf Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      carousel_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-rows")
        |> LazyHTML.to_html()

      assert carousel_html =~ "pk-row-header pk-gutter"
      assert carousel_html =~ "pk-rail-wrap pk-gutter"
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

    test "every shelf anchor href resolves to an element id present in the document", %{
      conn: conn
    } do
      game_fixture(%{name: "Nav Target Game", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/")

      hrefs =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-nav-links a")
        |> LazyHTML.attribute("href")

      assert hrefs != []

      Enum.each(hrefs, fn "#" <> id ->
        assert html =~ ~s(id="#{id}")
      end)
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
