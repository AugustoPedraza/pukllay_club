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

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "extraordinariamente"})

      assert grid_html(html) =~ "pk-card-caption"
    end

    test "a resting grid card renders neither a weight-band label nor its descriptor (sketch 002)",
         %{conn: conn} do
      game_fixture(%{name: "Juego Banded", weight_band: "ingenio_estratega"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Juego Banded"})

      card_html = html |> grid_html() |> strip_preview_templates()

      assert card_html =~ "Juego Banded"
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

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Juego Con Chips"})

      card_html = html |> grid_html() |> strip_preview_templates()

      assert card_html =~ "Juego Con Chips"
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

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Juego Con Metadata"})

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

      {:ok, _view, html} = live(conn, ~p"/?weight_bands=ingenio_estratega")

      assert position(grid_html(html), "Alfa Corto") < position(grid_html(html), "Zeta Largo")

      {:ok, _view, html2} =
        live(conn, ~p"/?weight_bands=ingenio_estratega&sort=playtime_desc")

      assert position(grid_html(html2), "Zeta Largo") < position(grid_html(html2), "Alfa Corto")
    end

    test "dispatching load-more appends the next page and leaves already-rendered cards in place",
         %{conn: conn} do
      for n <- 1..30 do
        game_fixture(%{name: "Juego #{String.pad_leading(Integer.to_string(n), 2, "0")}"})
      end

      {:ok, view, html} = live(conn, ~p"/?q=Juego")

      assert card_count(html) == 24
      assert html =~ "Juego 01"

      html2 = render_click(view, "load-more", %{})

      assert card_count(html2) == 30
      assert html2 =~ "Juego 01"
    end

    test "changing any filter resets pagination back to the first page", %{conn: conn} do
      for n <- 1..30 do
        game_fixture(%{name: "G#{n}", mechanics: ["Dice Rolling"]})
      end

      {:ok, view, html} = live(conn, ~p"/?weight_bands=ingenio_estratega")
      assert card_count(html) == 24

      render_click(view, "load-more", %{})

      html2 =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "G1"})

      assert card_count(html2) == 1
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
      {:ok, _view, html} = live(conn, ~p"/?weight_bands=ingenio_estratega")
      assert html =~ "0 juegos encontrados"

      game_fixture(%{name: "Solo Juego"})
      {:ok, _view2, html2} = live(conn, ~p"/?weight_bands=ingenio_estratega")
      assert html2 =~ "1 juego encontrado"

      game_fixture(%{name: "Otro Juego"})
      {:ok, _view3, html3} = live(conn, ~p"/?weight_bands=ingenio_estratega")
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

  describe "in-row horizontal infinite scroll: carousel-load-more (quick task 260824-u5d)" do
    test "appends cards into exactly one row's rail and leaves a sibling rail untouched", %{
      conn: conn
    } do
      for n <- 1..25 do
        game_fixture(%{
          name: "Winner #{String.pad_leading(to_string(n), 2, "0")}",
          tags: ["#EquipoGanador"]
        })
      end

      game_fixture(%{name: "Sibling Game", tags: ["#CreaConexiones"]})

      {:ok, view, html} = live(conn, ~p"/")

      assert carousel_card_count(html, "equipo_ganador") == 20
      sibling_before = carousel_card_count(html, "crea_conexiones")

      html2 = render_click(view, "carousel-load-more", %{"row" => "equipo_ganador"})

      assert carousel_card_count(html2, "equipo_ganador") == 25
      assert carousel_card_count(html2, "crea_conexiones") == sibling_before
    end

    test "is a no-op on an already-exhausted row", %{conn: conn} do
      game_fixture(%{name: "Only Duel", tags: ["#DuelosMemorables"]})

      {:ok, view, html} = live(conn, ~p"/")
      before = carousel_card_count(html, "duelos_memorables")

      html2 = render_click(view, "carousel-load-more", %{"row" => "duelos_memorables"})

      assert carousel_card_count(html2, "duelos_memorables") == before
    end

    test "is a no-op on an unrecognised row key and does not raise", %{conn: conn} do
      game_fixture(%{name: "Untouched Game"})

      {:ok, view, html} = live(conn, ~p"/")
      before_count = card_count(html)

      html2 = render_click(view, "carousel-load-more", %{"row" => "not-a-real-row"})

      assert card_count(html2) == before_count
      assert html2 =~ "Untouched Game"
    end
  end

  describe "trailing skeleton placeholders + hook data attributes (Task 2, quick task 260824-u5d)" do
    test "a rendered rail carries the row-key and exhausted data attributes and trailing placeholder markup",
         %{conn: conn} do
      game_fixture(%{name: "Equipo Game", tags: ["#EquipoGanador"]})

      {:ok, _view, html} = live(conn, ~p"/")

      section_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-equipo_ganador")
        |> LazyHTML.to_html()

      assert section_html =~ ~s(data-carousel-row="equipo_ganador")
      assert section_html =~ ~s(data-exhausted="true")
      assert section_html =~ "pk-trailing-skel"
      assert section_html =~ ~s(id="carousel-equipo_ganador-skel-1")
      assert section_html =~ ~s(id="carousel-equipo_ganador-skel-2")
    end

    test "an exhausted row still carries the trailing placeholder markup — it is always in the DOM, only hidden",
         %{conn: conn} do
      game_fixture(%{name: "Only Duel", tags: ["#DuelosMemorables"]})

      {:ok, _view, html} = live(conn, ~p"/")

      section_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-duelos_memorables")
        |> LazyHTML.to_html()

      assert section_html =~ ~s(data-exhausted="true")
      assert section_html =~ "pk-trailing-skel"
    end
  end

  describe "vertical infinite scroll: .GridScroll sentinel-driven load-more (D-03)" do
    test "the hook element's data-exhausted is false while more pages remain, and true once the offset reaches the total",
         %{conn: conn} do
      for n <- 1..30 do
        game_fixture(%{name: "Juego #{String.pad_leading(Integer.to_string(n), 2, "0")}"})
      end

      {:ok, view, html} = live(conn, ~p"/?q=Juego")

      assert grid_scroll_html(html) =~ ~s(data-exhausted="false")

      html2 = render_click(view, "load-more", %{})

      assert grid_scroll_html(html2) =~ ~s(data-exhausted="true")
    end

    test "the results view renders the sentinel element and exactly four trailing skeleton placeholders with stable ids",
         %{conn: conn} do
      game_fixture(%{name: "Sentinel Game"})

      {:ok, view, _html} = live(conn, ~p"/")
      html = render_click(view, "apply-filters", %{})

      section_html = grid_scroll_html(html)

      assert section_html =~ "data-grid-sentinel"
      assert section_html =~ ~s(id="grid-skel-1")
      assert section_html =~ ~s(id="grid-skel-2")
      assert section_html =~ ~s(id="grid-skel-3")
      assert section_html =~ ~s(id="grid-skel-4")
      refute section_html =~ ~s(id="grid-skel-5")
    end

    test "the rendered results view contains no inline script tag — the colocated hook is extracted at build time",
         %{conn: conn} do
      game_fixture(%{name: "No Script Game"})

      {:ok, view, _html} = live(conn, ~p"/")
      html = render_click(view, "apply-filters", %{})

      refute html =~ "export default"
    end

    test "dispatching load-more appends the next page without disturbing already-rendered cards, and data-exhausted flips to true on the last page",
         %{conn: conn} do
      for n <- 1..30 do
        game_fixture(%{name: "Juego #{String.pad_leading(Integer.to_string(n), 2, "0")}"})
      end

      {:ok, view, html} = live(conn, ~p"/?q=Juego")

      assert card_count(html) == 24
      assert html =~ "Juego 01"

      html2 = render_click(view, "load-more", %{})

      assert card_count(html2) == 30
      assert html2 =~ "Juego 01"
      assert grid_scroll_html(html2) =~ ~s(data-exhausted="true")
    end

    test "dispatching load-more again after the result set is exhausted is a no-op: unchanged card count, no error state",
         %{conn: conn} do
      for n <- 1..30 do
        game_fixture(%{name: "Juego #{String.pad_leading(Integer.to_string(n), 2, "0")}"})
      end

      {:ok, view, _html} = live(conn, ~p"/?q=Juego")
      render_click(view, "load-more", %{})

      html3 = render_click(view, "load-more", %{})

      assert card_count(html3) == 30
      refute html3 =~ "No pudimos cargar más juegos."
    end

    test "the manual pagination control no longer renders anywhere in the results view", %{
      conn: conn
    } do
      game_fixture(%{name: "Any Game"})

      {:ok, view, _html} = live(conn, ~p"/")
      html = render_click(view, "apply-filters", %{})

      refute html =~ "Cargar más"
    end

    test "changing a filter after loading additional pages resets the offset and clears any error state",
         %{conn: conn} do
      for n <- 1..30 do
        game_fixture(%{name: "G#{n}", mechanics: ["Dice Rolling"]})
      end

      {:ok, view, html} = live(conn, ~p"/?weight_bands=ingenio_estratega")
      assert grid_scroll_html(html) =~ ~s(data-exhausted="false")

      render_click(view, "load-more", %{})

      html2 =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "G1"})

      assert grid_scroll_html(html2) =~ ~s(data-exhausted="true")
      refute html2 =~ "No pudimos cargar más juegos."
    end

    # A mid-scroll load-more query failure (:more_error, distinct from the
    # existing :load_error path) is not reachable from this suite: every
    # value that can make safe_filter_games/1's rescue fire (e.g. the
    # out-of-Postgres-int-range players value used by the existing
    # "when the catalog query raises" test) fails identically on the very
    # first apply_filters/1 call — offset is never client-controlled, so
    # there is no way to make page 1 of a filter succeed while a later
    # load-more page of the SAME filter fails. Recorded here rather than
    # writing a test that would assert nothing; the inline retry line's
    # actual failure/recovery behaviour is deferred to Task 3's
    # <human-check> item 4, the same pattern 01.2-03-SUMMARY.md's D6 used
    # for an analogous untestable scenario.
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

    test "the unfiltered landing renders the carousel-rows container and no results grid (D-01)",
         %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~s(id="carousel-rows")
      refute html =~ ~s(id="games")
      refute html =~ "El catálogo completo"
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

  describe "the two-surface contract: carousels XOR grid (D-01, D-02)" do
    test "an unfiltered landing renders the carousel-rows container, the chip index row and the desktop mega-menu, and renders no #games container",
         %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~s(id="carousel-rows")
      assert html =~ "pk-chip-nav"
      assert html =~ "pk-cat-trigger"
      refute html =~ ~s(id="games")
    end

    test "pressing the filter modal's primary CTA with no facets selected renders the #games container and the full-catalog heading, and hides the carousel surface",
         %{conn: conn} do
      game_fixture()

      {:ok, view, _html} = live(conn, ~p"/")

      html = render_click(view, "apply-filters", %{})

      assert html =~ ~s(id="games")
      assert html =~ "El catálogo completo"
      refute html =~ ~s(id="carousel-rows")
      refute html =~ "pk-chip-nav"
      refute html =~ "pk-cat-trigger"
    end

    test "dismissing the modal instead, with no facets selected, leaves the carousel surface rendered and renders no #games container",
         %{conn: conn} do
      game_fixture()

      {:ok, view, _html} = live(conn, ~p"/")

      html = render_click(view, "close-filters", %{})

      assert html =~ ~s(id="carousel-rows")
      refute html =~ ~s(id="games")
    end

    test "from the submitted state, dispatching clear-filters returns the carousel surface and removes the #games container",
         %{conn: conn} do
      game_fixture()

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "apply-filters", %{})

      html = render_click(view, "clear-filters", %{})

      assert html =~ ~s(id="carousel-rows")
      refute html =~ ~s(id="games")
    end

    # A load failure while the carousel surface is showing was considered
    # (D-02's must_haves list it as a state to prove) but is not reachable
    # from this suite: every path that can put the socket into
    # :load_error (safe_filter_games/1's rescue, exercised via the
    # out-of-range players value in the "GET /" load-error test) also sets
    # a real filter, which makes filters_active?/1 — and therefore
    # browsing_results?/1 — true, landing on the grid surface instead.
    # Recorded here rather than writing a test that would assert nothing;
    # see the plan's SUMMARY for the same note.
  end

  describe "active-filters summary row (G-01.2-4, sketch 029 winner C)" do
    test "several facets, a scalar and a query active render one chip per filter, using the modal's own labels",
         %{conn: conn} do
      game_fixture(%{
        name: "Multi Filter Game",
        weight_band: "ingenio_estratega",
        mechanics: ["Trading"],
        min_players: 3,
        max_players: 3
      })

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "toggle-facet", %{"facet" => "weight_bands", "choice" => "ingenio_estratega"})
      render_click(view, "toggle-facet", %{"facet" => "mechanics", "choice" => "Comercia"})
      render_click(view, "toggle-scalar", %{"scalar" => "players", "choice" => "3"})

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Multi"})

      chip_html = active_filter_chips_html(html)

      assert chip_html =~ "Nivel: Ingenio estratega"
      assert chip_html =~ "Mecánica: Comercia"
      assert chip_html =~ "Jugadores: 3"
      assert chip_html =~ "Búsqueda: Multi"
    end

    test "only a query active renders exactly one chip, naming the query", %{conn: conn} do
      game_fixture(%{name: "Query Only Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Query"})

      chips =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-active-filter-chip")

      assert Enum.count(chips) == 1
      assert LazyHTML.to_html(chips) =~ "Búsqueda: Query"
    end

    test "the unfiltered carousel surface renders no summary chips", %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      refute html =~ "pk-active-filter-chip"
    end

    test "clicking a facet chip drops exactly that filter and leaves the others intact", %{
      conn: conn
    } do
      game_fixture(%{
        name: "Both Match",
        weight_band: "ingenio_estratega",
        mechanics: ["Trading"]
      })

      game_fixture(%{name: "Only Mechanic", mechanics: ["Trading"]})

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "toggle-facet", %{"facet" => "weight_bands", "choice" => "ingenio_estratega"})
      render_click(view, "toggle-facet", %{"facet" => "mechanics", "choice" => "Comercia"})

      html =
        view
        |> element(~s(.pk-active-filter-chip[phx-value-facet="weight_bands"]))
        |> render_click()

      grid = grid_html(html)
      assert grid =~ "Both Match"
      assert grid =~ "Only Mechanic"
      refute html =~ "Nivel: Ingenio estratega"
      assert html =~ "Mecánica: Comercia"
    end

    test "clicking the query chip clears the query and leaves facets intact", %{conn: conn} do
      game_fixture(%{name: "Facet And Query", mechanics: ["Trading"]})
      game_fixture(%{name: "Facet Only", mechanics: ["Trading"]})

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "toggle-facet", %{"facet" => "mechanics", "choice" => "Comercia"})

      view
      |> form("#catalog-search-form")
      |> render_change(%{q: "Facet And"})

      # A direct render_click/3 (matching the "toggle-facet" style two
      # events above), not an `element(view, selector) |> render_click()`
      # DOM lookup: since G-01.2-9 (01.2-16) the chip's `phx-click` renders
      # as a JS.push-encoded value (`page_loading: true`), not the literal
      # event-name string a `[phx-click="clear-query"]` attribute selector
      # depended on.
      html = render_click(view, "clear-query", %{})

      assert html =~ "Mecánica: Comercia"
      refute html =~ "Búsqueda:"

      grid = grid_html(html)
      assert grid =~ "Facet And Query"
      assert grid =~ "Facet Only"
    end

    test "removing the last remaining filter chip returns the member to the carousel surface", %{
      conn: conn
    } do
      game_fixture(%{name: "Solo Filter Game", weight_band: "ingenio_estratega"})

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "toggle-facet", %{"facet" => "weight_bands", "choice" => "ingenio_estratega"})

      html =
        view
        |> element(~s(.pk-active-filter-chip[phx-value-facet="weight_bands"]))
        |> render_click()

      assert html =~ ~s(id="carousel-rows")
      refute html =~ ~s(id="games")
    end

    test "the clear-everything action drops every active filter at once", %{conn: conn} do
      game_fixture(%{name: "Cleared Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "toggle-facet", %{"facet" => "mechanics", "choice" => "Comercia"})

      view
      |> form("#catalog-search-form")
      |> render_change(%{q: "Cleared"})

      html =
        view
        |> element(".pk-clear-filters-link")
        |> render_click()

      refute html =~ "pk-active-filter-chip"
      assert html =~ ~s(id="carousel-rows")
    end

    test "chips do not carry filter_modal's own selection-chip class (Round 2's separation, sketch 029)",
         %{conn: conn} do
      game_fixture(%{name: "Any Game", weight_band: "ingenio_estratega"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        render_click(view, "toggle-facet", %{"facet" => "weight_bands", "choice" => "ingenio_estratega"})

      chip_html = active_filter_chips_html(html)

      refute chip_html =~ "badge-primary"
      refute chip_html =~ "badge-neutral"
      refute chip_html =~ ~s(class="badge)
    end

    # G-01.2-27 task 1: pins the migration onto the shared pill base — a
    # future revert to a bespoke `.pk-active-filter-chip` rule (the exact
    # drift this consolidation ends) fails here, not just visually.
    test "each applied-filter chip composes the shared pill base, the accent tone, the comfortable size, and the interactive variant",
         %{conn: conn} do
      game_fixture(%{name: "Pill Base Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Pill Base"})

      chip_classes =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-active-filter-chip")
        |> LazyHTML.attribute("class")

      assert chip_classes != []

      for class_list <- chip_classes do
        tokens = String.split(class_list)

        assert "pk-pill" in tokens
        assert "pk-pill-accent" in tokens
        assert "pk-pill-comfortable" in tokens
        assert "pk-pill-interactive" in tokens
      end
    end
  end

  describe "settling the background surface once per modal close (G-01.2-4 defect C)" do
    test "G-01.2-4: opening the modal on the carousel surface and toggling a facet leaves the rendered surface unchanged while the modal stays open",
         %{conn: conn} do
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Expert Game", weight_band: "nivel_experto"})

      {:ok, view, _html} = live(conn, ~p"/")

      view |> element(~s([aria-label="Abrir filtros"])) |> render_click()

      html =
        view
        |> element(~s(button[phx-value-facet="weight_bands"][phx-value-choice="descubre_el_hobby"]))
        |> render_click()

      # The background surface is FROZEN: still carousels, no grid heading
      # — even though the filter is now active server-side and the modal's
      # own live match count already reflects it. This looks like it
      # contradicts D-01 (carousels XOR grid) but doesn't: D-01 governs the
      # DESIRED surface (browsing_results?/1); this test is about the
      # RENDERED one (:rendered_results), frozen deliberately while the
      # modal covers it.
      assert html =~ ~s(id="carousel-rows")
      refute html =~ ~s(id="games")
      refute html =~ "Resultados"
      assert html =~ "Ver 1 juego"
    end

    test "G-01.2-4: closing that modal via the X commits the swap: the grid heading appears and the carousel container is gone",
         %{conn: conn} do
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Expert Game", weight_band: "nivel_experto"})

      {:ok, view, _html} = live(conn, ~p"/")

      view |> element(~s([aria-label="Abrir filtros"])) |> render_click()

      view
      |> element(~s(button[phx-value-facet="weight_bands"][phx-value-choice="descubre_el_hobby"]))
      |> render_click()

      html = view |> element("button[data-modal-close]") |> render_click()

      assert html =~ "Resultados"
      refute html =~ ~s(id="carousel-rows")
    end

    test "G-01.2-4: the repopulation test — after opening, filtering and closing via the X, the grid actually contains the matching card, not just an empty frame",
         %{conn: conn} do
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Expert Game", weight_band: "nivel_experto"})

      {:ok, view, _html} = live(conn, ~p"/")

      view |> element(~s([aria-label="Abrir filtros"])) |> render_click()

      view
      |> element(~s(button[phx-value-facet="weight_bands"][phx-value-choice="descubre_el_hobby"]))
      |> render_click()

      html = view |> element("button[data-modal-close]") |> render_click()

      assert card_count(html) == 1
      assert grid_html(html) =~ "Hobby Game"
    end

    test "G-01.2-4: the explicit-submission CTA with nothing selected renders a populated grid (UAT Test 4 clause 1)",
         %{conn: conn} do
      game_fixture(%{name: "Any Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html = render_click(view, "apply-filters", %{})

      assert card_count(html) == 1
    end

    test "G-01.2-4: clear-filters returns the member to the carousels with the row actually populated (mirror-direction repopulation)",
         %{conn: conn} do
      game_fixture(%{name: "Crea Game", tags: ["#CreaConexiones"]})

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "apply-filters", %{})
      html = render_click(view, "clear-filters", %{})

      assert html =~ ~s(id="carousel-rows")
      refute html =~ ~s(id="games")
      assert carousel_card_count(html, "crea_conexiones") == 1
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

  describe "search-morph server-owned open state (G-01.2-2, G-01.2-3)" do
    # The strip regression, pinned. Pre-01.2-11, .pk-search-morph carried a
    # literal `class="pk-search-morph"` string alongside a dynamic
    # data-search-expanded attribute on the SAME element — the moment any
    # of the element's dynamic inputs changed (here: @q flipping
    # browsing_results?/1, which drops the nav_menu/subnav sibling slots),
    # LiveView re-applied the server's attribute set and stripped the
    # client-added `.is-open` class. syncMorph() then silently re-added it
    # but never restored focus, so the member's next keystroke went
    # nowhere. Now the class is rendered FROM :search_expanded on every
    # render, so there is nothing left to strip.
    test "opening the search then typing a query that flips browsing_results? leaves the pill open",
         %{conn: conn} do
      game_fixture(%{name: "Some Game"})

      {:ok, view, _html} = live(conn, ~p"/")

      html = render_click(view, "open-search", %{})
      assert html =~ ~s(data-search-expanded="true")
      assert html =~ "is-open"

      html2 =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Some"})

      assert html2 =~ ~s(data-search-expanded="true")
      assert html2 =~ "is-open"
    end

    test "close-search removes the open state, and a subsequent handle_params for the same query does not restore it",
         %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/?q=Catan")
      assert html =~ ~s(data-search-expanded="true")

      html2 = render_click(view, "close-search", %{})
      assert html2 =~ ~s(data-search-expanded="false")

      # Re-runs handle_params/3 on the SAME LiveView process with the
      # identical query string — the widen-only rule must not treat this
      # as "a URL carrying a query" reopening what the member just closed.
      html3 = render_patch(view, ~p"/?q=Catan")
      assert html3 =~ ~s(data-search-expanded="false")
    end

    # The assertion that the deleted document-level outside-press listener
    # (G-01.2-3/G-01.2-4 defect A) is really gone: every filter-modal
    # interaction below is a full LiveView round trip, and none of them
    # touch :search_expanded server-side.
    test "opening the filter modal, toggling a facet, and closing it leaves the open state untouched",
         %{conn: conn} do
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "open-search", %{})

      html =
        view
        |> element(~s([aria-label="Abrir filtros"]))
        |> render_click()

      assert html =~ ~s(data-search-expanded="true")

      html2 =
        view
        |> element(~s(button[phx-value-facet="weight_bands"][phx-value-choice="descubre_el_hobby"]))
        |> render_click()

      assert html2 =~ ~s(data-search-expanded="true")

      html3 = render_click(view, "close-filters", %{})
      assert html3 =~ ~s(data-search-expanded="true")
    end
  end

  describe "card-vs-preview href parity for the forwarded ?from= filter state (G-01.2-1)" do
    # The debug session found no defect here — GameCard and GamePreview
    # mirror the same three-clause detail_path/2 from the same @from_query
    # assign — but that surface was unreachable while search was broken, so
    # nothing had ever observed it. This is what makes the finding
    # permanent rather than a claim: string equality, not a substring
    # match on one side.
    test "GameCard's own link and GamePreview's Ver detalles CTA build identical hrefs for the same game",
         %{conn: conn} do
      game_fixture(%{name: "Parity Game"})

      {:ok, _view, html} = live(conn, ~p"/?q=Parity")

      card_html = grid_html(html)

      [card_tag] = Regex.run(~r/<a[^>]*data-game-card[^>]*>/, card_html)
      [_, card_href] = Regex.run(~r/href="([^"]+)"/, card_tag)

      [preview_tag] = Regex.run(~r/<a[^>]*pk-preview-cta[^>]*>/, card_html)
      [_, preview_href] = Regex.run(~r/href="([^"]+)"/, preview_tag)

      assert card_href == preview_href
      assert card_href =~ "from="
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

      # No Ver todo tile (removed entirely, quick task 260824-u5d — in-row
      # infinite scroll replaces it)
      refute carousel_html =~ "pk-see-all"

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

    # Superseded by Task 2 (G-01.2-4 defect C): this test used to assert the
    # background grid narrowed the instant a facet was toggled inside the
    # open modal — exactly the "jumps the UI all the time" bug this plan
    # fixes. See the "surface unchanged while modal is open" test below
    # (settling behaviour describe block) for the corrected contract; the
    # live-count half of the old intent is still covered by the next test.
    test "toggling a facet from inside the open surface leaves the modal open and its live count updated, without restructuring the page behind it",
         %{conn: conn} do
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Expert Game", weight_band: "nivel_experto"})

      {:ok, view, _html} = live(conn, ~p"/")

      view |> element(~s([aria-label="Abrir filtros"])) |> render_click()

      html =
        view
        |> element(~s(button[phx-value-facet="weight_bands"][phx-value-choice="descubre_el_hobby"]))
        |> render_click()

      assert html =~ "modal-open"
      assert html =~ "Ver 1 juego"
      refute html =~ ~s(id="games")
      assert html =~ ~s(id="carousel-rows")
    end

    test "the live match count in the surface changes as a facet is toggled", %{conn: conn} do
      game_fixture(%{name: "Hobby Game A", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Expert Game B", weight_band: "nivel_experto"})

      {:ok, view, _html} = live(conn, ~p"/")

      # D-01/D-02: opening the modal alone (nothing selected yet) no longer
      # keeps the grid — and its "N juegos encontrados" heading — rendered
      # behind it; the live count is checked via the modal's own footer
      # CTA label instead, which is always present whenever the modal is
      # open, filtered or not.
      html_before = view |> element(~s([aria-label="Abrir filtros"])) |> render_click()
      assert html_before =~ "Ver 2 juegos"

      html_after =
        view
        |> element(~s(button[phx-value-facet="weight_bands"][phx-value-choice="descubre_el_hobby"]))
        |> render_click()

      assert html_after =~ "Ver 1 juego"
    end

    test "the surface closes on close-filters", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element(~s([aria-label="Abrir filtros"])) |> render_click()
      html = render_click(view, "close-filters", %{})

      refute html =~ "class=\"modal modal-open\""
    end

    # 01.2-11 superseded this test's prior expectation. Toggling a facet no
    # longer force-opens the search pill to reveal the filter badge (the
    # collapsible-badge defect from G-01.2-4) — :search_expanded is now
    # member-owned, only opened by open-search/a URL-carried filter at
    # handle_params time, or closed by close-search. A facet click routes
    # through apply_filters/1 alone, which never touches it.
    test "toggling a facet from a closed pill does not force it open", %{conn: conn} do
      game_fixture(%{name: "Hobby Game", weight_band: "descubre_el_hobby"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element(~s(button[phx-value-facet="weight_bands"][phx-value-choice="descubre_el_hobby"]))
        |> render_click()

      assert html =~ ~s(data-search-expanded="false")
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

      # Clearing the last active scalar returns the member to the carousel
      # surface (D-01/D-02), not an unfiltered grid — both fixtures keep
      # their default tags/weight_band, so they're reachable via the
      # carousel-rows section instead.
      assert html =~ "Four Player Game"
      assert html =~ "Big Group Game"
      refute html =~ ~s(id="games")
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

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Untouched"})

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

      # An unparseable choice degrades the scalar back to nil — with no
      # filter left active, the member lands back on the carousel surface
      # (D-01/D-02), not an unfiltered grid.
      assert html =~ "Four Player Game"
      assert html =~ "Big Group Game"
      refute html =~ ~s(id="games")
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

      # CatalogFilters.from_params/1's whitelist already drops "NoExiste"
      # down to mechanics: [] before this LiveView ever sees it, so both
      # mounts land on the same unfiltered carousel surface (D-01/D-02),
      # not the grid — checked on the whole page in both cases.
      assert html_unfiltered =~ "Any Game"
      assert html_bogus =~ "Any Game"
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

      {:ok, _view, html} = live(conn, ~p"/?sort=nope&weight_bands=ingenio_estratega")

      assert position(grid_html(html), "Alpha Game") < position(grid_html(html), "Zebra Game")
    end

    test "?players=abc leaves the players filter unset rather than raising", %{conn: conn} do
      game_fixture(%{name: "Any Game"})

      # An unset players filter with nothing else active is the unfiltered/
      # carousel surface (D-01/D-02), not the grid.
      assert {:ok, _view, html} = live(conn, ~p"/?players=abc")
      assert html =~ "Any Game"
    end
  end

  # G-01.2-9 gap closure (01.2-16, Task 3): pins the three connections that
  # are invisible to the compiler and therefore the ones a future refactor
  # would quietly break — the page-loading annotation, the results
  # wrapper's hook mount point, and both results regions' surface-flip fade
  # marker. Each assertion below was mutation-verified during authoring
  # (removing the wiring it covers made that assertion fail) — see the
  # 01.2-16-SUMMARY.md for the exact mutations and failing test names.
  describe "G-01.2-9 search/filter transition wiring" do
    test "G-01.2-9: the search form, the one active filter chip, and the clear-filters control are page_loading-annotated",
         %{conn: conn} do
      game_fixture(%{name: "Catan"})

      # Exactly ONE active filter (the query, via ?q=) keeps the rendered
      # chip count at exactly 1 — no mechanics/weight_bands/etc. selected,
      # each of which would render its own additional chip and inflate the
      # count below past 3. That makes the total annotated-element count
      # predictable: the search form + one chip + the clear-filters
      # control = 3, matching this plan's own declared annotation-site
      # count (index.ex Task 2).
      {:ok, _view, html} = live(conn, ~p"/?q=Catan")

      form_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#catalog-search-form")
        |> LazyHTML.to_html()

      assert form_html =~ "page_loading"

      # Each `Phoenix.LiveView.JS.push(event, page_loading: true)` renders
      # exactly one `"page_loading"` JSON key in its element's attribute
      # value, so a plain whole-page substring count is a reliable proxy
      # for "how many elements are annotated" — the same idiom card_count/1
      # above uses for `data-game-card`.
      annotated_count = html |> String.split("page_loading") |> length() |> Kernel.-(1)

      assert annotated_count == 3
    end

    test "the results wrapper carries a non-empty id and the .ResultsLoading phx-hook attribute",
         %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      wrapper_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#results-region")
        |> LazyHTML.to_html()

      assert wrapper_html != ""
      # Colocated hooks render with their fully-qualified module name
      # (e.g. "PukllayClubWeb.CatalogLive.Index.ResultsLoading"), not the
      # literal ".ResultsLoading" written in the template — matched by
      # substring here so this test doesn't hardcode (and drift from) the
      # exact qualified path.
      assert wrapper_html =~ ~r/phx-hook="[^"]*ResultsLoading"/
    end

    test "the carousel-rows container carries the surface-flip fade marker on the unfiltered surface",
         %{conn: conn} do
      game_fixture()

      {:ok, _view, html} = live(conn, ~p"/")

      carousel_rows_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#carousel-rows")
        |> LazyHTML.to_html()

      assert carousel_rows_html =~ "pk-surface-fade"
    end

    test "the grid-scroll wrapper carries the surface-flip fade marker once a search flips the surface to the grid",
         %{conn: conn} do
      game_fixture(%{name: "Catan"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Catan"})

      assert grid_scroll_html(html) =~ "pk-surface-fade"
    end
  end

  # G-01.2-27 task 3 (gap-closure round 3 cont'd, UAT gap G-01.2-15): the
  # drift gate that closes the loop the previous plan's tone-variant gate
  # started (catalog_show_test.exs). This exact drift — a chip- or
  # pill-shaped element growing its own bespoke radius/padding/font-size
  # instead of composing the shared base — has repeated at least three
  # times in this codebase before either gate existed (`.pk-chip-row
  # .badge`'s G-01.2-20 color-only patch, `.pk-active-filter-chip`'s own
  # "must NEVER be merged" note, `.pk-chip`'s own "same outline-at-rest
  # logic" note — see the diagnosis at
  # .planning/debug/G-01.2-15-pill-chip-design-inconsistency.md), which is
  # why a comment alone was judged insufficient here too.
  describe "bespoke-chip drift gate (Phase 01.2 gap-closure round 3, G-01.2-27 task 3)" do
    @css_path Path.expand("../../../assets/css/app.css", __DIR__)

    defp drift_gate_css_source, do: File.read!(@css_path)

    # Every top-level (column-0) CSS rule whose selector text names "chip"
    # or "pill" — found by reading, not assumed (`grep -n "chip\|-pill"
    # assets/css/app.css`): everything not excluded below is either the
    # pill system itself (`.pk-pill` and its tone/size/interactive variants
    # — already policed by catalog_show_test.exs's own gate) or a
    # structural container/pseudo-element with no geometry to police
    # (`.pk-chip-nav`'s scroll rail, its edge-fade pseudo-elements, its
    # spacer, its scrollbar reset).
    defp bespoke_chip_rules(src) do
      ~r/(?m)^(\.[^{}]+?)\{([^{}]*)\}/
      |> Regex.scan(src)
      |> Enum.map(fn [_, selector, body] -> {String.trim(selector), body} end)
      |> Enum.filter(fn {selector, _body} ->
        (String.contains?(selector, "chip") or String.contains?(selector, "pill")) and
          not String.contains?(selector, "pk-pill")
      end)
    end

    # One named, reasoned exclusion per selector family that legitimately
    # keeps a bespoke declaration — not a guess, each reason cites the exact
    # plan/task that put it there. `pk-chip` is matched with a precise
    # token boundary (not a bare substring) so it names ONLY the
    # category-navigation chip itself, never `pk-chip-nav`/`pk-chip-spacer`/
    # `pk-chip-nav-wrap` (structural containers this gate never needed to
    # exempt in the first place).
    # RED (G-01.2-27 task 3): intentionally empty at first commit — the
    # exclusion list is built from what the failing run actually reports,
    # not from a guess (see the GREEN commit for the populated map).
    @exclusions %{}

    defp excluded?(selector) do
      Enum.any?(@exclusions, fn {marker, _reason} ->
        Regex.match?(~r/(?<![\w-])#{Regex.escape(marker)}(?![\w-])/, selector)
      end)
    end

    # CSS's `padding` shorthand puts the horizontal component in a
    # position that depends on how many values are given (1: all sides: 2:
    # vertical horizontal; 3: top horizontal bottom; 4: top right bottom
    # left) — `.pk-chip-nav-wrap`'s own `padding: 0.75rem 0` is VERTICAL
    # only (horizontal component is literally `0`) and must not trip this
    # gate, which is why "declares padding at all" is not the check.
    defp declares_horizontal_padding?(body) do
      cond do
        Regex.match?(~r/padding-(left|right|inline)/, body) ->
          true

        match = Regex.run(~r/(?<![-\w])padding:\s*([^;]+);/, body) ->
          [_, value] = match
          parts = value |> String.trim() |> String.split(~r/\s+/)

          horizontal =
            case length(parts) do
              1 -> [Enum.at(parts, 0)]
              2 -> [Enum.at(parts, 1)]
              3 -> [Enum.at(parts, 1)]
              4 -> [Enum.at(parts, 1), Enum.at(parts, 3)]
              _ -> parts
            end

          Enum.any?(horizontal, &(&1 not in ~w(0 0px 0rem 0em)))

        true ->
          false
      end
    end

    test "no chip- or pill-shaped rule outside the pill system declares a radius, a horizontal padding, or a type size" do
      rules = bespoke_chip_rules(drift_gate_css_source())

      assert rules != [],
             "expected to find at least the excluded category-navigation chip's rule in " <>
               "assets/css/app.css — 0 rules found suggests the scan regex broke, not that " <>
               "the codebase is clean"

      for {selector, body} <- rules, not excluded?(selector) do
        refute body =~ ~r/border-radius/,
               "`#{selector}` declares its own border-radius outside the pill system. A new " <>
                 "chip extends `.pk-pill` with a variant; it does not get a rule of its own. " <>
                 "This exact drift has happened at least three times in this codebase already " <>
                 "(G-01.2-15) — a comment alone was judged insufficient, which is why this " <>
                 "assertion exists."

        refute declares_horizontal_padding?(body),
               "`#{selector}` declares its own horizontal padding outside the pill system. A " <>
                 "new chip extends `.pk-pill`/`.pk-pill-comfortable` with a variant; it does " <>
                 "not get a rule of its own. If the base genuinely cannot express what this " <>
                 "call site needs, that is a design decision to raise, not a rule to add " <>
                 "quietly."

        refute body =~ ~r/font-size/,
               "`#{selector}` declares its own font-size outside the pill system. Type size " <>
                 "lives on `.pk-pill` or a size variant, never on a bespoke chip rule."
      end
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

  # Scopes assertions to the active-filters summary row's chips only
  # (Task 1, G-01.2-4) — a plain substring search would also match a
  # "Nivel"/"Jugadores" label rendered elsewhere on the page (e.g. inside
  # the filter modal itself, which is always in the DOM).
  defp active_filter_chips_html(html) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query(".pk-active-filter-chip")
    |> LazyHTML.to_html()
  end

  # Scopes assertions to the #grid-scroll hook element (D-03) — the
  # .GridScroll wrapper, its data-exhausted attribute, the sentinel, and
  # the trailing skeleton placeholders all live here, one level above
  # #games itself.
  defp grid_scroll_html(html) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("#grid-scroll")
    |> LazyHTML.to_html()
  end

  defp card_count(html) do
    html
    |> grid_html()
    |> String.split("data-game-card")
    |> length()
    |> Kernel.-(1)
  end

  # Counts cards inside one carousel row's rail only, by row key — scoped
  # to `#carousel-<row_key>` so a fetch-more assertion on one row cannot be
  # satisfied by cards that landed in a sibling rail instead (260824-u5d).
  defp carousel_card_count(html, row_key) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("#carousel-#{row_key} [data-game-card]")
    |> Enum.count()
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
