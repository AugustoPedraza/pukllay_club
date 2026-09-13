defmodule PukllayClubWeb.CatalogLive.ShowTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

  alias Plug.Conn.Query
  alias PukllayClub.Catalog.Reservation
  alias PukllayClubWeb.CarouselRow
  alias PukllayClubWeb.CatalogFilters
  alias PukllayClubWeb.CatalogLive.Show
  alias PukllayClubWeb.GameChips

  describe "GET /juegos/:id" do
    test "returns 200 for an unauthenticated visitor and renders the full title (CATALOG-08)", %{
      conn: conn
    } do
      game =
        game_fixture(%{
          name: "Un título extraordinariamente largo que no debería truncarse en la página de detalle"
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~
               "Un título extraordinariamente largo que no debería truncarse en la página de detalle"
    end

    test "renders the weight-band label but no badge element and no descriptor sentence (G-01.2-20)",
         %{conn: conn} do
      game = game_fixture(%{weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert html =~ "Ingenio estratega"
      assert doc |> LazyHTML.query(".badge-secondary") |> Enum.count() == 0
      refute html =~ "Reglas de 15-20 minutos y decisiones pensando un par de jugadas por delante."
    end

    test "exactly one link into the weight-band filter exists on the page, and it is the dificultad pill",
         %{conn: conn} do
      game = game_fixture(%{weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      matches = LazyHTML.query(doc, "a[href='/?weight_bands=ingenio_estratega']")
      assert Enum.count(matches) == 1

      # G-01.2-26 task 3: the exact-equality assertion now pins the element
      # carrying the pk-fact marker (kept as a test selector/scoping hook,
      # zero visual declarations left on it) plus the pk-pill base, the
      # neutral tone, and the interactive variant (this is a link branch).
      link_class = matches |> LazyHTML.attribute("class") |> List.first()
      assert link_class == "pk-fact pk-pill pk-pill-neutral pk-pill-interactive"
    end

    test "renders the complete mechanic chip list with no overflow indicator", %{conn: conn} do
      game =
        game_fixture(%{
          mechanics: [
            "Dice Rolling",
            "Hand Management",
            "Worker Placement",
            "Tile Placement",
            "Race",
            "Memory",
            "Deduction"
          ]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      for label <- [
            "Tira dados",
            "Gestión de mano",
            "Coloca trabajadores",
            "Coloca losetas",
            "Carrera",
            "Memoria",
            "Deducción"
          ] do
        assert html =~ label
      end

      refute html =~ "+3"
      refute html =~ "+7"
    end

    test "renders designers in the fact grid and description in the reading column, and players/duration once in the facts row; no minimum-age label renders (D-05, UAT gap G-01.3-1 item 2)",
         %{conn: conn} do
      game =
        game_fixture(%{
          designers: ["Klaus Teuber"],
          min_players: 3,
          max_players: 4,
          min_age: 10,
          description: "Compite por colonizar la isla de Catán."
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      facts_html = doc |> LazyHTML.query(".pk-facts-row") |> LazyHTML.to_html()
      spec_html = doc |> LazyHTML.query(".pk-spec-list") |> LazyHTML.to_html()

      assert html =~ "Klaus Teuber"
      assert html =~ "Compite por colonizar la isla de Catán."

      # 01.3-07 (UAT gap G-01.3-1 item 2): no minimum-age row anywhere on
      # the page, even though this game has a min_age set — the field and
      # its ?min_age= filter param remain live, only this render site is
      # gone.
      refute html =~ "10+"
      refute html =~ "Edad mínima"

      # D-05: players is represented exactly once, by the facts row —
      # never restated as a fact-grid row.
      assert facts_html =~ "3-4"
      refute spec_html =~ "3-4"
      refute spec_html =~ "Jugadores"
      refute spec_html =~ "Duración"
    end

    test "omits designers/age/description rows individually when absent, and Editorial never renders (G-01.2-10 task 3)",
         %{conn: conn} do
      game =
        game_fixture(%{
          designers: [],
          min_age: nil,
          description: nil
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "Diseñadores"
      refute html =~ "Editorial"
      refute html =~ "Edad mínima"
    end

    test "a game with gallery images renders a thumbnail strip", %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover-large.webp",
          gallery_urls: [
            "https://images.test.invalid/games/1/gallery-1.webp",
            "https://images.test.invalid/games/1/gallery-2.webp"
          ]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "gallery-thumbnails"
      assert html =~ "gallery-1.webp"
      assert html =~ "gallery-2.webp"
    end

    test "a game with an empty gallery renders the cover alone with no thumbnail strip", %{
      conn: conn
    } do
      game = game_fixture(%{gallery_urls: []})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "gallery-thumbnails"
    end

    test "clicking a thumbnail swaps the main image", %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover-large.webp",
          gallery_urls: ["https://images.test.invalid/games/1/gallery-1.webp"]
        })

      {:ok, view, html} = live(conn, ~p"/juegos/#{game.id}")
      assert html =~ ~s(src="https://images.test.invalid/games/1/cover-large.webp")

      html2 =
        view
        |> element(~s(#gallery-thumbnails button[phx-value-url="https://images.test.invalid/games/1/gallery-1.webp"]))
        |> render_click()

      assert html2 =~ ~s(src="https://images.test.invalid/games/1/gallery-1.webp")
    end

    # G-01.2-10 task 2, D3: the dot affordance dispatches the exact same
    # event/param as the thumbnail it mirrors, through the same
    # select-image whitelist.
    test "clicking a dot swaps the main image", %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover-large.webp",
          gallery_urls: ["https://images.test.invalid/games/1/gallery-1.webp"]
        })

      {:ok, view, html} = live(conn, ~p"/juegos/#{game.id}")
      assert html =~ ~s(src="https://images.test.invalid/games/1/cover-large.webp")

      html2 =
        view
        |> element(~s(#gallery-dots button[phx-value-url="https://images.test.invalid/games/1/gallery-1.webp"]))
        |> render_click()

      assert html2 =~ ~s(src="https://images.test.invalid/games/1/gallery-1.webp")
    end

    test "select-image with a url not in the game's own image list leaves selected_image unchanged",
         %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover-large.webp",
          gallery_urls: []
        })

      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      html2 = render_click(view, "select-image", %{"url" => "https://evil.example.com/x.jpg"})

      refute html2 =~ "evil.example.com"
      assert html2 =~ ~s(src="https://images.test.invalid/games/1/cover-large.webp")
    end

    test "visiting the detail path for a nonexistent id raises Ecto.NoResultsError (404, not a crash)",
         %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/juegos/999999999")
      end
    end

    # 01.1-07: the plain live/2 helper above re-raises Ecto.NoResultsError
    # straight to the test process rather than rendering through the
    # endpoint's normal error pipeline — that's how live/2 itself is
    # implemented in this test env, not a debug_errors setting. A plain
    # conn GET through Phoenix.ConnTest also re-raises rather than
    # returning a rendered response, so Phoenix.ConnTest.assert_error_sent/2
    # (which wraps the call, catches the raise, and asserts the status Plug
    # would have sent) is the documented way to assert the actual rendered
    # 404 body end-to-end, per this plan's own fallback instruction.
    test "an unknown game id renders the branded 404 end-to-end, not Phoenix's default plain text",
         %{conn: conn} do
      {404, _headers, body} =
        assert_error_sent(404, fn ->
          get(conn, ~p"/juegos/999999999")
        end)

      assert body =~ "Juego no encontrado"
    end

    # CR-02: a non-numeric id can't be cast to the `:id` primary key type,
    # so `Repo.get!/2` alone would raise `Ecto.Query.CastError` (no
    # `Plug.Exception` impl) instead of the branded 404 — this exercises
    # the same end-to-end path as the nonexistent-numeric-id test above,
    # but for a non-numeric id.
    test "a non-numeric game id renders the branded 404 end-to-end, not a 500",
         %{conn: conn} do
      {404, _headers, body} =
        assert_error_sent(404, fn ->
          get(conn, ~p"/juegos/abc")
        end)

      assert body =~ "Juego no encontrado"
    end

    test "renders inside the shared capped-inner container (max-w-7xl + pk-gutter), with no 672px ancestor cap",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "max-w-7xl"
      assert html =~ "pk-gutter"
      refute html =~ "max-w-2xl"
    end

    test "renders the breadcrumb with the game's name inside pk-crumb-current, and the shared footer",
         %{conn: conn} do
      game = game_fixture(%{name: "Juego Detalle Shell"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "pk-nav-crumb"

      crumb_current_text =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-crumb-current")
        |> LazyHTML.text()

      assert crumb_current_text == "Juego Detalle Shell"
      assert html =~ "pk-footer"
    end

    test "the header renders a role=search form whose action is the catalog root (01.1-08)", %{
      conn: conn
    } do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header")
        |> LazyHTML.to_html()

      assert header_html =~ ~s(role="search")
      assert header_html =~ ~s(action="/")
    end

    test "the #app-header subtree contains no join-CTA label (D-05 superseded, plan 01.1-08)", %{
      conn: conn
    } do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      header_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#app-header")
        |> LazyHTML.to_html()

      refute header_html =~ "Sumate"
    end

    # Detalle passes no nav_links slot — the exact case a slot-driven drawer
    # would have silently broken. The drawer's link list is shell-owned
    # (layouts.ex's nav_drawer/1), not slot-owned, so it still renders here.
    test "the drawer's two site links render even though the page passes no nav_links slot (01.1-09)",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      drawer_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-drawer-links")
        |> LazyHTML.to_html()

      assert drawer_html =~ "Inicio"
      assert drawer_html =~ "Quiénes Somos"
    end

    test "the drawer marks neither link current on Detalle (active_nav nil, 01.1-09)", %{
      conn: conn
    } do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      drawer_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-drawer-links")
        |> LazyHTML.to_html()

      refute drawer_html =~ "aria-current"
    end

    test "renders no .pk-about-cta-bar (About-scoped, 01.1-09)", %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "pk-about-cta-bar"
    end

    test "the buy-box CTA renders inside the poster column and the reading column has no primary button (SHELL-03)",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      poster_html = doc |> LazyHTML.query(".pk-poster-col") |> LazyHTML.to_html()
      assert poster_html =~ "Reservar para el sábado"
      assert poster_html =~ "btn-primary"

      text_col_html = doc |> LazyHTML.query(".pk-text-col") |> LazyHTML.to_html()
      refute text_col_html =~ "btn-primary"
    end

    test "a game with band-mates renders the Juegos similares shelf with the weight-band subtitle and no Ver todo tile",
         %{conn: conn} do
      game = game_fixture(%{name: "Base", weight_band: "nivel_experto"})
      game_fixture(%{name: "Bandmate", weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "Juegos similares"
      assert html =~ "Otros juegos del mismo nivel: Nivel experto"
      refute html =~ "pk-see-all"
    end

    test "a game whose band has no other members renders no Juegos similares heading and the page still renders",
         %{conn: conn} do
      game = game_fixture(%{name: "Lonely", weight_band: "descubre_el_hobby"})

      {:ok, view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "Juegos similares"
      assert view.module == Show
    end

    # G-01.2-7 / sketch 031: a same-band-filled shelf renders no "Ampliado"
    # badge and keeps the existing weight-band subtitle — the shelf's
    # visible chrome is unchanged when widening never happened.
    test "a same-band-filled shelf renders no badge and the existing weight-band subtitle", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Base Same Band", weight_band: "nivel_experto"})
      game_fixture(%{name: "Bandmate Same Band", weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "Juegos similares"
      refute html =~ "Ampliado"
      assert html =~ "Otros juegos del mismo nivel: Nivel experto"
      refute html =~ "Otras opciones que te van a encantar"
    end

    # A widened shelf (the shelf had to reach past the viewed game's own
    # band to fill the cap) renders the "Ampliado" badge and the swapped
    # subtitle, while the title itself is unchanged.
    test "a widened shelf renders the Ampliado badge and the widened subtitle", %{conn: conn} do
      game = game_fixture(%{name: "Base Widened", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Other Band 1", weight_band: "nivel_experto"})
      game_fixture(%{name: "Other Band 2", weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "Juegos similares"
      assert html =~ "Ampliado"
      assert html =~ "Otras opciones que te van a encantar"
      refute html =~ "Otros juegos del mismo nivel:"
    end

    test "a no-band game's shelf renders the Ampliado badge and the widened subtitle", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Base No Band", weight_band: nil})
      game_fixture(%{name: "Other 1", weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "Juegos similares"
      assert html =~ "Ampliado"
      assert html =~ "Otras opciones que te van a encantar"
    end

    # D-04 (01.2-04) established the rule this test still covers, under
    # different data: ground every field in the real schema, including its
    # gaps — never paper over an absence with a placeholder. At the time
    # this test was written the Ilustrador/BGG-ranking rows were dead
    # placeholders with no backing schema field, so the correct behaviour
    # was "never render, ever." D-05/D-06 (01.3-05), carried forward by
    # 01.3-07's fact-grid/Comunidad BGG split, add real artists/bgg_rank
    # columns, so the correct behaviour is now *conditional*: present when
    # the field is set, absent when it's nil.
    test "the Ilustradores fact-grid column and the Ranking BGG stat render conditionally on real data, never as a placeholder (D-04, D-05, D-06)",
         %{conn: conn} do
      present =
        game_fixture(%{
          name: "Con Datos Avanzados",
          artists: ["Klemens Franz"],
          bgg_rank: 245,
          bgg_id: 13,
          weight_band: "nivel_experto"
        })

      absent =
        game_fixture(%{
          name: "Sin Datos Avanzados",
          artists: [],
          bgg_rank: nil,
          bgg_weight: nil,
          bgg_rating: nil,
          weight_band: "descubre_el_hobby"
        })

      {:ok, _view, html_present} = live(conn, ~p"/juegos/#{present.id}")
      {:ok, _view, html_absent} = live(conn, ~p"/juegos/#{absent.id}")

      spec_present =
        html_present
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-spec-list")
        |> LazyHTML.to_html()

      spec_absent =
        html_absent
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-spec-list")
        |> LazyHTML.to_html()

      bgg_row_present =
        html_present
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-bgg-row")
        |> LazyHTML.to_html()

      bgg_row_absent =
        html_absent
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-bgg-row")
        |> LazyHTML.to_html()

      assert spec_present =~ "Ilustradores"
      assert spec_present =~ "Klemens Franz"
      assert bgg_row_present =~ "Ranking"
      assert bgg_row_present =~ "#245"

      refute spec_absent =~ "Ilustradores"
      refute bgg_row_absent =~ "Ranking"

      # Kept from the original test intact: the old singular "Ilustrador"
      # placeholder label and the "No disponible" placeholder text must
      # still never appear, on either game. The rows are now plural and
      # data-backed (D-05/D-06), not resurrected as the old dead
      # placeholder this assertion originally guarded against.
      refute spec_present =~ "Ilustrador:"
      refute spec_present =~ "No disponible"
      refute spec_absent =~ "Ilustrador:"
      refute spec_absent =~ "No disponible"
    end

    test "a game with a bgg_id renders a boardgamegeek.com/boardgame link in the Comunidad BGG block, one without renders none",
         %{conn: conn} do
      # weight_band differs so neither game is the other's Juegos similares
      # bandmate. The assertion below scopes to "boardgamegeek.com/boardgame"
      # (not the bare domain) specifically because the footer carries its
      # own unconditional "Powered by BGG" attribution link to the bare
      # https://boardgamegeek.com/ root on every page (layouts.ex) — without
      # that scoping, "no boardgamegeek.com anywhere" would be unassertable
      # regardless of this game's own bgg_id.
      with_id = game_fixture(%{name: "Con BGG", bgg_id: 13, weight_band: "nivel_experto"})

      # comunidad_bgg?/1 widens with bgg_id on top of advanced_stats?/1 —
      # override every BGG stat AND the id to nil here, or the block still
      # renders (Fuente line only) and the assertion below would be testing
      # an impossible partial-data combination rather than the real "no BGG
      # presence at all" case this test targets.
      without_id =
        game_fixture(%{
          name: "Sin BGG",
          bgg_id: nil,
          weight_band: "descubre_el_hobby",
          bgg_weight: nil,
          bgg_rating: nil,
          bgg_rank: nil
        })

      {:ok, _view, html_with} = live(conn, ~p"/juegos/#{with_id.id}")
      {:ok, _view, html_without} = live(conn, ~p"/juegos/#{without_id.id}")

      assert html_with =~ "boardgamegeek.com/boardgame/13"
      refute html_without =~ "boardgamegeek.com/boardgame"
    end

    test "a minimal-data game with none of the five fact-grid fields and no bgg_id renders no fact grid and no Comunidad BGG block, and the rest of the page still renders",
         %{conn: conn} do
      game =
        game_fixture(%{
          name: "Juego Minimo",
          min_age: nil,
          year_published: nil,
          designers: [],
          artists: [],
          publishers: [],
          bgg_id: nil,
          bgg_weight: nil,
          bgg_rating: nil,
          bgg_rank: nil,
          mechanics: [],
          themes: []
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "pk-spec-list"
      refute html =~ "Comunidad BGG"
      assert html =~ "Juego Minimo"
      assert html =~ "Reservar para el sábado"
    end

    test "a game with a bgg_rating renders the Valoración stat linking to its BGG page (D-06)",
         %{conn: conn} do
      game = game_fixture(%{name: "Con Valoración", bgg_rating: 7.4, bgg_id: 13, weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      bgg_html =
        html |> LazyHTML.from_document() |> LazyHTML.query(".pk-bgg-row") |> LazyHTML.to_html()

      assert bgg_html =~ "Valoración"
      assert bgg_html =~ "7.4/10"
      assert bgg_html =~ "boardgamegeek.com/boardgame/13"
    end

    test "a game with no bgg_rating renders no Valoración stat, and the rest of the Comunidad BGG block still renders (D-06)",
         %{conn: conn} do
      game = game_fixture(%{name: "Sin Valoración", bgg_rating: nil, weight_band: "descubre_el_hobby"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      bgg_html =
        html |> LazyHTML.from_document() |> LazyHTML.query(".pk-bgg-row") |> LazyHTML.to_html()

      refute bgg_html =~ "Valoración"
      assert html =~ "Comunidad BGG"
    end

    test "a game with only a bgg_id and none of the other four fields still renders no fact grid but does render the Comunidad BGG block and its BGG link",
         %{conn: conn} do
      game =
        game_fixture(%{
          min_age: nil,
          year_published: nil,
          designers: [],
          artists: [],
          publishers: [],
          mechanics: [],
          themes: [],
          bgg_weight: nil,
          bgg_rating: nil,
          bgg_rank: nil,
          bgg_id: 77
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "pk-spec-list"
      assert html =~ "Comunidad BGG"
      assert html =~ "boardgamegeek.com/boardgame/77"
    end

    test "clicking the description toggle expands and collapses the description", %{conn: conn} do
      game = game_fixture(%{description: "Una descripción de prueba."})

      {:ok, view, html} = live(conn, ~p"/juegos/#{game.id}")
      assert html =~ "pk-desc is-clamped"
      refute html =~ "is-expanded"

      html2 = render_click(view, "toggle-description", %{})
      assert html2 =~ "is-expanded"

      html3 = render_click(view, "toggle-description", %{})
      refute html3 =~ "is-expanded"
    end
  end

  # 01.3-08 (UAT gap G-01.3-1 item 6 + sketch 042's inline-chevron toggle)
  # / 01.3-10 (gap closure G-01.3-4): pins the description's justify/clamp
  # mechanism and the icon-only toggle's collapsed/expanded contract. The
  # toggle is now ALWAYS a trailing sibling of the paragraph, never a
  # descendant, in both states — moving it out of the paragraph's line box
  # is what fixes G-01.3-4. Reuses css_source/0 (declared below in the
  # title-echo describe block) for the source-level pins.
  #
  # Describe-block name kept short deliberately: combined with the longest
  # test name below (the round-trip test), a longer describe name pushes
  # the generated `-inlined-test <describe> <test>/1-fun-N-` atom past
  # Erlang's 255-character atom limit and the module fails to compile with
  # an opaque `core_to_ssa`/`list_to_atom` system-limit error.
  describe "description justify + inline icon-only toggle contract (01.3-08/01.3-10)" do
    test "initial render is collapsed: the paragraph is clamped and the toggle is its sibling, never a descendant",
         %{conn: conn} do
      game = game_fixture(%{description: "Una descripción de prueba para el juego."})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      p = LazyHTML.query(doc, "p#game-description.pk-desc.is-clamped")
      assert Enum.count(p) == 1

      # The toggle must never be a descendant of the paragraph — this is
      # the actual invariant G-01.3-4 is about.
      assert Enum.empty?(LazyHTML.query(doc, "p#game-description button"))

      toggle = LazyHTML.query(doc, "#game-description + button.pk-desc-toggle")
      assert Enum.count(toggle) == 1

      assert List.first(LazyHTML.attribute(toggle, "aria-expanded")) == "false"
      assert List.first(LazyHTML.attribute(toggle, "aria-label")) == "Ver más"
      assert List.first(LazyHTML.attribute(toggle, "aria-controls")) == "game-description"
    end

    test "after one toggle event: the paragraph is no longer clamped and the toggle stays a trailing sibling",
         %{conn: conn} do
      game = game_fixture(%{description: "Una descripción de prueba para el juego."})

      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      html = render_click(view, "toggle-description", %{})
      doc = LazyHTML.from_document(html)

      p_expanded = LazyHTML.query(doc, "p#game-description.pk-desc")
      assert Enum.count(p_expanded) == 1
      assert Enum.empty?(LazyHTML.query(doc, "p#game-description.is-clamped"))

      # The toggle must still be a SIBLING of the paragraph, never a descendant.
      assert Enum.empty?(LazyHTML.query(doc, "p#game-description button"))

      trailing = LazyHTML.query(doc, "#game-description + button.pk-desc-toggle")
      assert Enum.count(trailing) == 1
      assert List.first(LazyHTML.attribute(trailing, "aria-expanded")) == "true"
      assert List.first(LazyHTML.attribute(trailing, "aria-label")) == "Ver menos"
      assert List.first(LazyHTML.attribute(trailing, "aria-controls")) == "game-description"
    end

    test "round trip: expand, collapse, expand, collapse, expand, collapse — three full cycles, asserting after every transition",
         %{conn: conn} do
      game = game_fixture(%{description: "Una descripción de prueba para el juego."})

      {:ok, view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert_collapsed = fn html ->
        doc = LazyHTML.from_document(html)
        assert Enum.count(LazyHTML.query(doc, "p#game-description.pk-desc.is-clamped")) == 1
        assert Enum.empty?(LazyHTML.query(doc, "p#game-description button"))
        assert Enum.count(LazyHTML.query(doc, "#game-description + button.pk-desc-toggle")) == 1
      end

      assert_expanded = fn html ->
        doc = LazyHTML.from_document(html)
        assert Enum.empty?(LazyHTML.query(doc, "p#game-description.pk-desc.is-clamped"))
        assert Enum.empty?(LazyHTML.query(doc, "p#game-description button"))
        assert Enum.count(LazyHTML.query(doc, "#game-description + button.pk-desc-toggle")) == 1
      end

      assert_collapsed.(html)

      # This is the exact regression sketch 042 hit: a version that only
      # ever worked on the first expand, then silently no-op'd on every
      # subsequent transition because the relocation logic branched on the
      # button's current parent instead of the target state. Three full
      # cycles (six transitions), asserting after each one, is the point.
      html = render_click(view, "toggle-description", %{})
      assert_expanded.(html)

      html = render_click(view, "toggle-description", %{})
      assert_collapsed.(html)

      html = render_click(view, "toggle-description", %{})
      assert_expanded.(html)

      html = render_click(view, "toggle-description", %{})
      assert_collapsed.(html)

      html = render_click(view, "toggle-description", %{})
      assert_expanded.(html)

      html = render_click(view, "toggle-description", %{})
      assert_collapsed.(html)
    end

    test "a game with a nil description renders neither the paragraph nor the toggle", %{
      conn: conn
    } do
      game = game_fixture(%{description: nil})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "pk-desc-shell"
      refute html =~ "pk-desc-toggle"
      refute html =~ "id=\"game-description\""
    end

    test "the description declares justify and text-justify: inter-word, unconditional at every width" do
      block =
        case Regex.run(~r/(?m)^\.pk-desc\s*\{([^}]*)\}/s, css_source()) do
          [_, body] -> body
          nil -> flunk("No top-level `.pk-desc { ... }` rule found in assets/css/app.css")
        end

      assert block =~ ~r/text-align:\s*justify;/,
             "`.pk-desc` must declare `text-align: justify` unconditionally (UAT item 6 — " <>
               "the alignment must hold at every viewport width, not just desktop)."

      assert block =~ ~r/text-justify:\s*inter-word;/,
             "`.pk-desc` must declare `text-justify: inter-word` — word-based justification is " <>
               "the right setting for Spanish prose regardless of the clip mechanism."
    end

    test "the collapsed description clips via a native three-line clamp with a native ellipsis" do
      clamped_block =
        case Regex.run(~r/(?m)^\.pk-desc\.is-clamped\s*\{([^}]*)\}/s, css_source()) do
          [_, body] -> body
          nil -> flunk("No top-level `.pk-desc.is-clamped { ... }` rule found in assets/css/app.css")
        end

      assert clamped_block =~ ~r/-webkit-line-clamp:\s*3;/,
             "`.pk-desc.is-clamped` must declare the native 3-line clamp — the only clip " <>
               "mechanism with a clean-cut guarantee (description-truncation.md)."

      assert clamped_block =~ ~r/text-overflow:\s*ellipsis;/,
             "`.pk-desc.is-clamped` must declare `text-overflow: ellipsis` — the engine-supplied " <>
               "ellipsis this clamp mechanism exists for."
    end

    test "the toggle declares no float-based positioning and no line-height-derived margin" do
      toggle_block =
        case Regex.run(~r/(?m)^\.pk-desc-toggle\s*\{([^}]*)\}/s, css_source()) do
          [_, body] -> body
          nil -> flunk("No top-level `.pk-desc-toggle { ... }` rule found in assets/css/app.css")
        end

      refute toggle_block =~ ~r/float\s*:/,
             "`.pk-desc-toggle` must not declare float-based positioning — G-01.3-4's root cause " <>
               "was the toggle living inside the paragraph's line box via a float."

      refute toggle_block =~ ~r/calc\(\d+ \* 1\.5em\)/,
             "`.pk-desc-toggle` must not derive its position from a line-height multiple — it is " <>
               "positioned purely as a flex child of `.pk-desc-shell`'s column now."

      assert toggle_block =~ ~r/align-self:\s*flex-end;/,
             "`.pk-desc-toggle` must position itself via `align-self: flex-end` on the shell's " <>
               "flex column — the only positioning mechanism left after this gap closure."
    end

    # 01.3-10 task 2: net-new regressions pinning the OLD failure mode as
    # un-reintroducible — not restatements of the pins above, which only
    # assert the new mechanism is present.
    test "the toggle is never a descendant of the paragraph, in EITHER the collapsed or the expanded state",
         %{conn: conn} do
      game = game_fixture(%{description: "Una descripción de prueba para el juego."})

      {:ok, view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert_containment = fn html ->
        doc = LazyHTML.from_document(html)

        assert Enum.empty?(LazyHTML.query(doc, "p#game-description button")),
               "An engine's float-versus-justified-line width computation can only move a " <>
                 "control that lives INSIDE the line box — keeping the toggle outside the " <>
                 "paragraph entirely is the structural guarantee against G-01.3-4, not a " <>
                 "stylistic preference. G-01.3-4 could not reproduce in Blink at all (zero " <>
                 "measured overflow), so a pixel-measurement assertion would have passed the " <>
                 "whole time this bug shipped; this structural check would not."

        assert Enum.count(LazyHTML.query(doc, "#game-description + button.pk-desc-toggle")) ==
                 1,
               "Expected exactly one button.pk-desc-toggle as #game-description's adjacent " <>
                 "sibling."
      end

      # Collapsed state.
      assert_containment.(html)

      # Expanded state — same invariant must hold after toggling.
      html = render_click(view, "toggle-description", %{})
      assert_containment.(html)
    end

    test "the toggle carries a real 44px box via markup utilities, not an invisible offset overlay",
         %{conn: conn} do
      game = game_fixture(%{description: "Una descripción de prueba para el juego."})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      toggle = LazyHTML.query(doc, "#game-description + button.pk-desc-toggle")
      class = List.first(LazyHTML.attribute(toggle, "class")) || ""

      assert class =~ "min-h-11",
             "The toggle must carry `min-h-11`. The invisible `::before` offset overlay that " <>
               "used to supply the 44px touch floor is deliberately gone — it hung 13px over " <>
               "the paragraph above and the fact grid below, an accidental tap-hijack " <>
               "surface, not a hit area — and must not be reintroduced."

      assert class =~ "min-w-11",
             "The toggle must carry `min-w-11`, for the same reason `min-h-11` is required " <>
               "above: the invisible offset overlay it replaces must not come back."
    end

    test "no rule in the .pk-desc* family declares float-based positioning" do
      family_span =
        case Regex.run(
               ~r/^\.pk-desc-shell\s*\{.*?(?=\n\/\* Boundary between the primary reading block)/ms,
               css_source()
             ) do
          [span] ->
            span

          nil ->
            flunk(
              "Could not locate the .pk-desc* family span (from `.pk-desc-shell {` to the " <>
                "boundary-divider comment) in assets/css/app.css."
            )
        end

      # Scoped to extracted RULE BODIES only, never the whole file — this
      # stylesheet's prose comments legitimately discuss the superseded
      # float technique by name, and a whole-file scan would make the
      # comment self-invalidating.
      bodies = Regex.scan(~r/\{([^}]*)\}/s, family_span, capture: :all_but_first)

      assert bodies != [],
             "Expected at least one `{ ... }` rule body in the .pk-desc* family span."

      for [body] <- bodies do
        refute body =~ ~r/float\s*:/,
               "Found float-based positioning inside a `.pk-desc*` family rule body:\n#{body}\n" <>
                 "G-01.3-4's root cause was exactly this — a control positioned by a float " <>
                 "inside a clipped, justified paragraph."
      end
    end
  end

  # 01.3-12 (gap closure G-01.3-6): ExUnit cannot measure a rendered box, so
  # every assertion below is a DERIVED (contract) oracle — it parses the
  # declarations the geometry is computed from and asserts on the computed
  # numbers, mirroring the idiom `footer_rhythm_test.exs:486-590` already
  # established on this codebase (strip comments, anchored `Regex.run` per
  # rule body, `flunk` with an explanation when a rule has gone missing).
  # The real oracle — does the chevron actually trail the third line on a
  # rendered page — was exercised via the device check deferred to
  # end-of-phase UAT (WINDOWS.md). Values are read out of the CSS/markup
  # wherever a rule already declares them, never hard-coded, so rescaling
  # one side (e.g. the icon) cannot silently leave the other (the padding
  # that centres it) behind.
  describe "collapsed toggle geometry (01.3-12)" do
    @base_font_px 16

    # Comments are prose, not cascade — this stylesheet's own comments now
    # discuss `padding-right`/`position`/`min-w-11` etc. by name (the doc
    # comments Task 1 rewrote), so a whole-blob regex without stripping
    # comments first would be satisfied by prose alone. Reused verbatim from
    # `footer_rhythm_test.exs`.
    defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

    defp rule_body!(src, selector) do
      pattern = ~r/(?m)^#{Regex.escape(selector)}\s*\{([^}]*)\}/s

      case Regex.run(pattern, src) do
        [_, body] ->
          body

        nil ->
          flunk(
            "No `#{selector} { ... }` top-level rule found in assets/css/app.css. If the " <>
              "selector changed, update this test — it exists specifically to notice that " <>
              "kind of drift."
          )
      end
    end

    defp rem_px!(block, prop, label) do
      case Regex.run(~r/#{prop}:\s*([\d.]+)rem/, block) do
        [_, v] ->
          float = String.to_float(if String.contains?(v, "."), do: v, else: v <> ".0")
          float * @base_font_px

        nil ->
          flunk("`#{prop}` is missing from #{label}")
      end
    end

    defp px!(block, prop, label) do
      case Regex.run(~r/#{prop}:\s*([\d.]+)px/, block) do
        [_, v] -> String.to_integer(v)
        nil -> flunk("`#{prop}` is missing from #{label}")
      end
    end

    defp int_prop!(block, prop, label) do
      case Regex.run(~r/#{prop}:\s*(\d+)/, block) do
        [_, v] -> String.to_integer(v)
        nil -> flunk("`#{prop}` is missing from #{label}")
      end
    end

    defp float_prop!(block, prop, label) do
      case Regex.run(~r/#{prop}:\s*([\d.]+)/, block) do
        [_, v] -> String.to_float(if String.contains?(v, "."), do: v, else: v <> ".0")
        nil -> flunk("`#{prop}` is missing from #{label}")
      end
    end

    defp overlay_toggle_body!(src), do: rule_body!(src, ".pk-desc-shell:not(.is-expanded) .pk-desc-toggle")

    test "basis: none of the reading column declares a font-size" do
      src = strip_comments(css_source())

      for selector <- [".pk-desc", ".pk-desc-shell", ".pk-reading-section", ".pk-text-col"] do
        body = rule_body!(src, selector)

        refute body =~ ~r/font-size:/,
               "`#{selector}` declares a font-size. Every px number this describe block " <>
                 "computes (line bands, icon centring, the reserved gutter) rests on the " <>
                 "description computing at the #{@base_font_px}px document base declared " <>
                 "nowhere in the reading column — if a future rule introduces a font-size " <>
                 "here, THIS test must be the thing that notices, not a real device."
      end
    end

    test "last line band: the collapsed icon's ink lands inside it, centred" do
      src = strip_comments(css_source())

      clamp_lines = int_prop!(rule_body!(src, ".pk-desc.is-clamped"), "-webkit-line-clamp", "`.pk-desc.is-clamped`")
      line_height = float_prop!(rule_body!(src, ".pk-desc"), "line-height", "`.pk-desc`")
      line_band = line_height * @base_font_px

      overlay_body = overlay_toggle_body!(src)
      padding_bottom = rem_px!(overlay_body, "padding-bottom", "the collapsed toggle override")
      icon_height = px!(rule_body!(src, ".pk-desc-toggle-icon"), "height", "`.pk-desc-toggle-icon`")

      assert padding_bottom + icon_height <= line_band,
             "The collapsed toggle's icon (height #{icon_height}px, inset #{padding_bottom}px " <>
               "from the paragraph's bottom edge) spans outside the #{line_band}px last line " <>
               "band (#{clamp_lines} lines x #{line_height} x #{@base_font_px}px). A control " <>
               "whose ink band falls entirely outside this range reads as a row of its own " <>
               "below the paragraph — exactly what a real device showed for G-01.3-6 while " <>
               "every DOM-structure and CSS-literal test in this file stayed green."

      centring_gap = abs((line_band - icon_height) / 2 - padding_bottom)

      assert centring_gap <= 1,
             "The collapsed toggle's icon is #{centring_gap}px off-centre in its " <>
               "#{line_band}px last line band (icon #{icon_height}px, inset " <>
               "#{padding_bottom}px). Expected the icon to sit centred in the band it " <>
               "trails, not merely somewhere inside it."
    end

    test "collapsed toggle is out of flow, expanded stays in flow" do
      src = strip_comments(css_source())

      overlay_body = overlay_toggle_body!(src)

      assert overlay_body =~ ~r/position:\s*absolute;/,
             "`.pk-desc-shell:not(.is-expanded) .pk-desc-toggle` must declare " <>
               "`position: absolute` — the declaration that stops the shell's flex column " <>
               "from handing the collapsed control a block row of its own, which is the " <>
               "root cause of G-01.3-6."

      base_toggle_body = rule_body!(src, ".pk-desc-toggle")

      refute base_toggle_body =~ ~r/position\s*:/,
             "The base `.pk-desc-toggle` rule declares its own `position`. It must stay " <>
               "unpositioned so the collapsed-state override is the only thing that takes " <>
               "the control out of flow — the expanded state must keep relying purely on " <>
               "`.pk-desc-shell`'s flex column."

      shell_body = rule_body!(src, ".pk-desc-shell")

      assert shell_body =~ ~r/position:\s*relative;/,
             "`.pk-desc-shell` must declare `position: relative`. Without it the collapsed " <>
               "override's `bottom`/`right` resolve against some distant positioned " <>
               "ancestor instead of the shell's own box, and the control leaves the card " <>
               "entirely."
    end

    test "gutter matches the toggle's markup-declared tap width", %{conn: conn} do
      game = game_fixture(%{description: "Una descripción de prueba para el juego."})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      toggle = LazyHTML.query(doc, "#game-description + button.pk-desc-toggle")
      class = List.first(LazyHTML.attribute(toggle, "class")) || ""

      min_w_px =
        case Regex.run(~r/min-w-(\d+)/, class) do
          [_, n] -> String.to_integer(n) * 4
          nil -> flunk("Toggle class `#{class}` carries no `min-w-N` utility to bind the gutter to")
        end

      padding_right_px =
        rem_px!(rule_body!(strip_comments(css_source()), ".pk-desc.is-clamped"), "padding-right", "`.pk-desc.is-clamped`")

      assert padding_right_px >= min_w_px,
             "`.pk-desc.is-clamped`'s padding-right (#{padding_right_px}px) is narrower than " <>
               "the toggle's own markup-declared tap box (`min-w-#{div(min_w_px, 4)}` = " <>
               "#{min_w_px}px, show.ex). This is the only thing binding a value in app.css " <>
               "to a utility class in show.ex; anything less puts live description text " <>
               "under an interactive box — the tap-hijack surface 01.3-10 deleted on purpose."
    end

    test "shell floor matches the toggle's markup-declared tap height", %{conn: conn} do
      game = game_fixture(%{description: "Una descripción de prueba para el juego."})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      toggle = LazyHTML.query(doc, "#game-description + button.pk-desc-toggle")
      class = List.first(LazyHTML.attribute(toggle, "class")) || ""

      min_h_px =
        case Regex.run(~r/min-h-(\d+)/, class) do
          [_, n] -> String.to_integer(n) * 4
          nil -> flunk("Toggle class `#{class}` carries no `min-h-N` utility to bind the floor to")
        end

      shell_min_height_px =
        rem_px!(
          rule_body!(strip_comments(css_source()), ".pk-desc-shell:not(.is-expanded)"),
          "min-height",
          "`.pk-desc-shell:not(.is-expanded)`"
        )

      assert shell_min_height_px >= min_h_px,
             "The collapsed shell's min-height (#{shell_min_height_px}px) is shorter than " <>
               "the toggle's own markup-declared tap box (`min-h-#{div(min_h_px, 4)}` = " <>
               "#{min_h_px}px, show.ex). A sub-three-line description could then let the " <>
               "absolutely positioned overlay hang upward over the hashtag row above the " <>
               "description block."
    end

    test "no forbidden mechanism in the new rule, and the tripwire test still covers it" do
      overlay_body = overlay_toggle_body!(strip_comments(css_source()))

      refute overlay_body =~ ~r/float\s*:/,
             "`.pk-desc-shell:not(.is-expanded) .pk-desc-toggle` must not declare " <>
               "float-based positioning — G-01.3-4's documented root cause."

      refute overlay_body =~ ~r/calc\(\d+ \* 1\.5em\)/,
             "`.pk-desc-shell:not(.is-expanded) .pk-desc-toggle` must not derive its " <>
               "position from a line-height multiple — the documented source of the " <>
               "pre-01.3-10 fragility."

      # Mirrors the family-span extraction the tripwire test at lines 881-912
      # uses, so a rule placed outside that scan's bounds is caught here too.
      family_span =
        case Regex.run(
               ~r/^\.pk-desc-shell\s*\{.*?(?=\n\/\* Boundary between the primary reading block)/ms,
               css_source()
             ) do
          [span] ->
            span

          nil ->
            flunk(
              "Could not locate the .pk-desc* family span (from `.pk-desc-shell {` to the " <>
                "boundary-divider comment) in assets/css/app.css."
            )
        end

      assert family_span =~ ".pk-desc-shell:not(.is-expanded) .pk-desc-toggle {",
             "The new collapsed-toggle override rule must sit inside the .pk-desc* family " <>
               "span the tripwire test scans (from `.pk-desc-shell {` to the boundary " <>
               "comment) — a rule placed outside those bounds silently falls out of that " <>
               "test's float-scan coverage."
    end
  end

  describe "Ilustradores fact-grid pills (D-05, 01.3-07)" do
    test "renders a single illustrator as one filter-linked pill, not plain text", %{conn: conn} do
      game = game_fixture(%{artists: ["Klemens Franz"], weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      anchors = LazyHTML.query(doc, ".pk-fact-col dd a[href^='/?artists=']")

      assert Enum.count(anchors) == 1
      assert html =~ "Ilustradores"
      assert LazyHTML.to_html(anchors) =~ "Klemens Franz"
      assert List.first(LazyHTML.attribute(anchors, "href")) == "/?artists=Klemens+Franz"
    end

    test "renders one pill per illustrator when there are several — never comma-joined text", %{
      conn: conn
    } do
      game =
        game_fixture(%{
          artists: ["Klemens Franz", "Michael Menzel"],
          weight_band: "ingenio_estratega"
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      anchors = LazyHTML.query(doc, ".pk-fact-col dd a[href^='/?artists=']")

      assert Enum.count(anchors) == 2
      refute html =~ "Klemens Franz, Michael Menzel"
    end

    test "renders no Ilustradores fact-grid column when the artists list is empty", %{
      conn: conn
    } do
      game = game_fixture(%{artists: [], weight_band: "descubre_el_hobby"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "Ilustradores"
    end

    test "a space- and accent-bearing illustrator name round-trips through the ~p href and CatalogFilters.from_params/1 to the exact original string (T-01.3-07-01)",
         %{conn: conn} do
      game = game_fixture(%{artists: ["Loïc Billiau"], weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      [href] =
        doc
        |> LazyHTML.query(".pk-fact-col dd a[href^='/?artists=']")
        |> LazyHTML.attribute("href")

      "/?" <> query_string = href

      filters =
        query_string
        |> Query.decode()
        |> CatalogFilters.from_params()

      assert filters.artists == ["Loïc Billiau"]
    end
  end

  describe "Comunidad BGG stats group (D-06, retitled + moved out of the fact grid by 01.3-07)" do
    test "renders no Comunidad BGG block at all when there is no bgg_id and no stat", %{
      conn: conn
    } do
      game =
        game_fixture(%{
          name: "Sin BGG En Absoluto",
          bgg_id: nil,
          bgg_weight: nil,
          bgg_rating: nil,
          bgg_rank: nil,
          weight_band: "descubre_el_hobby"
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      refute html =~ "Comunidad BGG"
      assert doc |> LazyHTML.query(".pk-bgg-label") |> Enum.empty?()
      assert doc |> LazyHTML.query(".pk-bgg-stat") |> Enum.empty?()
      assert doc |> LazyHTML.query(".pk-bgg-foot") |> Enum.empty?()
    end

    test "renders the group label and the Fuente line but no stat anchors when all three stats are nil and bgg_id is present",
         %{conn: conn} do
      # D-06: the shared fixture default holds a weight value — override it
      # (along with rating/rank) explicitly, or this "all stats absent"
      # case would silently exercise the one-stat-present branch instead.
      game =
        game_fixture(%{
          name: "Sin Avanzado",
          bgg_weight: nil,
          bgg_rating: nil,
          bgg_rank: nil,
          bgg_id: 13,
          weight_band: "descubre_el_hobby"
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert html =~ "Comunidad BGG"
      assert doc |> LazyHTML.query(".pk-bgg-stat") |> Enum.empty?()
      assert html =~ "boardgamegeek.com/boardgame/13"
    end

    test "renders exactly one stat anchor when only one stat is populated", %{conn: conn} do
      game =
        game_fixture(%{
          name: "Solo Peso",
          bgg_weight: 3.2,
          bgg_rating: nil,
          bgg_rank: nil,
          bgg_id: 13,
          weight_band: "nivel_experto"
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      stats = LazyHTML.query(doc, ".pk-bgg-stat")
      stats_html = LazyHTML.to_html(stats)

      assert Enum.count(stats) == 1
      assert stats_html =~ "Peso"
      assert stats_html =~ "3.2/5"
      refute html =~ "Valoración"
      refute html =~ "Ranking"
    end

    test "renders all three stat anchors, each linking to the game's own BGG page", %{
      conn: conn
    } do
      game =
        game_fixture(%{
          name: "Con Todo Avanzado",
          bgg_weight: 3.2,
          bgg_rating: 7.4,
          bgg_rank: 245,
          bgg_id: 13,
          weight_band: "ingenio_estratega"
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      stats_html = doc |> LazyHTML.query(".pk-bgg-row") |> LazyHTML.to_html()

      assert stats_html =~ "Peso"
      assert stats_html =~ "3.2/5"
      assert stats_html =~ "Valoración"
      assert stats_html =~ "7.4/10"
      assert stats_html =~ "Ranking"
      assert stats_html =~ "#245"

      # The three stat anchors, plus the Fuente line's own anchor — all
      # four link to the same BGG page. No other element on the page links
      # to this specific /boardgame/13 path (the footer's own BGG
      # attribution link points at the bare domain root, not this path).
      bgg_links = LazyHTML.query(doc, "a[href='https://boardgamegeek.com/boardgame/13']")

      assert Enum.count(bgg_links) == 4
    end

    # D-06: a game BGG has never ranked renders no ranking stat at all — no
    # placeholder text, no "N/A", no "not ranked" — covered separately from
    # the all-nil case above since bgg_rank absence is the one field
    # backed by a research-flagged normalization assumption (BGG's own
    # "Not Ranked" string must degrade to nil upstream, 01.3-UI-SPEC.md).
    test "a game with no bgg_rank renders no Ranking stat and no placeholder text", %{
      conn: conn
    } do
      game =
        game_fixture(%{
          name: "Sin Ranking",
          bgg_rank: nil,
          bgg_id: 13,
          weight_band: "descubre_el_hobby"
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      bgg_html = doc |> LazyHTML.query(".pk-bgg-row") |> LazyHTML.to_html()

      refute bgg_html =~ "Ranking"
      refute html =~ "Not Ranked"
      refute html =~ "No disponible"
      refute html =~ "N/A"
    end
  end

  describe "reading-column section wrapping (D-03, D-04, recomposed by 01.3-07)" do
    test "a fully-populated game renders exactly four section wrappers (title, description, fact grid, Comunidad BGG)",
         %{conn: conn} do
      game =
        game_fixture(%{
          name: "Juego Completo",
          mechanics: ["Dice Rolling"],
          themes: ["Economic"],
          weight_band: "nivel_experto"
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-reading-section") |> Enum.count() == 4
    end

    test "a description-less, fact-less, BGG-less game renders exactly one section wrapper (title only)",
         %{conn: conn} do
      game =
        game_fixture(%{
          name: "Juego Solo Titulo",
          description: nil,
          year_published: nil,
          designers: [],
          artists: [],
          mechanics: [],
          themes: [],
          bgg_id: nil,
          bgg_weight: nil,
          bgg_rating: nil,
          bgg_rank: nil,
          weight_band: nil
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-reading-section") |> Enum.count() == 1
    end
  end

  describe "reading column reorder — title, hashtags, description, fact grid, BGG (01.3-07)" do
    test "title's section -> hashtag row -> description's section, ordered siblings not a substring match",
         %{conn: conn} do
      game = game_fixture(%{description: "Una crónica de mercaderes.", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      # Adjacent-sibling chain: this only matches when the hashtag row is
      # literally the very next element after the title's own wrapper, and
      # the description's own wrapper is literally the very next element
      # after the hashtag row. An element reinserted anywhere in this chain
      # (a divider, a badge, a stray wrapper) makes this query return 0.
      assert doc
             |> LazyHTML.query(".pk-reading-section + div.pk-rhythm-8 + div.pk-reading-section.pk-rhythm-16")
             |> Enum.count() == 1
    end

    test "hashtags render after title, before description; Mecánicas/Temáticas still after description (sketch 042)",
         %{conn: conn} do
      game =
        game_fixture(%{
          description: "Una crónica de mercaderes.",
          mechanics: ["Dice Rolling"],
          themes: ["Economic"],
          tags: ["#CreaConexiones"]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      {title_idx, _} = :binary.match(html, "detail-title-block")

      # Phase 01.8's Game JSON-LD block (`root.html.heex`, rendered inside
      # <head>) also carries this game's own description text verbatim, so
      # a scope-free :binary.match/2 would find that earlier <head>
      # occurrence instead of the visible reading-column one this test
      # means to locate. Scope the search to start at the title, which is
      # always inside <body>.
      {description_idx, _} =
        :binary.match(html, "Una crónica de mercaderes.", scope: {title_idx, byte_size(html) - title_idx})

      {mechanics_idx, _} = :binary.match(html, "Mecánicas")
      {themes_idx, _} = :binary.match(html, "Temáticas")
      {hashtag_idx, _} = :binary.match(html, "#CreaConexiones")

      assert title_idx < hashtag_idx
      assert hashtag_idx < description_idx
      assert description_idx < mechanics_idx
      assert description_idx < themes_idx
    end

    test "exactly one .pk-divider renders, inside #detail-shelf-separator — the reading column has none (G-01.3-1 items 1/9)",
         %{conn: conn} do
      game = game_fixture(%{description: "Una crónica.", mechanics: ["Dice Rolling"]})

      # A disconnected (static) render unconditionally shows the
      # masthead↔shelf separator regardless of whether any similar-games
      # bandmate exists (@loading short-circuits the emptiness check) —
      # the same technique the masthead↔shelf boundary tests below use.
      conn = get(conn, ~p"/juegos/#{game.id}")
      html = html_response(conn, 200)

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-divider") |> Enum.count() == 1
      assert doc |> LazyHTML.query("#detail-shelf-separator > .pk-divider") |> Enum.count() == 1
    end

    test "no h2.pk-section-heading renders anywhere — Mecánicas/Temáticas/Ficha técnica headings are gone (sketch 040)",
         %{conn: conn} do
      game =
        game_fixture(%{
          weight_band: "ingenio_estratega",
          description: "Una crónica.",
          mechanics: ["Dice Rolling"],
          themes: ["Economic"],
          tags: ["#CreaConexiones"]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query("h2.pk-section-heading") |> Enum.count() == 0
    end

    test "a game with publishers renders no publisher row anywhere", %{conn: conn} do
      game = game_fixture(%{publishers: ["Devir"]})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "Devir"
      refute html =~ "Editorial"
    end

    test "a game whose only populated field is publishers renders no fact grid and no Comunidad BGG block",
         %{conn: conn} do
      game =
        game_fixture(%{
          min_age: nil,
          year_published: nil,
          designers: [],
          artists: [],
          mechanics: [],
          themes: [],
          publishers: ["Devir"],
          bgg_id: nil,
          bgg_weight: nil,
          bgg_rating: nil,
          bgg_rank: nil
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "pk-spec-list"
      refute html =~ "Comunidad BGG"
    end

    test "a game with a year and publishers still renders the fact grid with the year row, and no Comunidad BGG block",
         %{conn: conn} do
      game =
        game_fixture(%{
          min_age: nil,
          year_published: 2001,
          designers: [],
          artists: [],
          mechanics: [],
          themes: [],
          publishers: ["Devir"],
          bgg_id: nil,
          bgg_weight: nil,
          bgg_rating: nil,
          bgg_rank: nil
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "pk-spec-list"
      assert html =~ "2001"
      refute html =~ "Devir"
      refute html =~ "Comunidad BGG"
    end
  end

  describe "masthead↔shelf boundary (G-01.2-18 task 1)" do
    test "a separator sits between the masthead's wrapper and the shelf's section root — ordered siblings, not mere presence",
         %{conn: conn} do
      game = game_fixture(%{name: "Base Boundary", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Bandmate Boundary", weight_band: "descubre_el_hobby"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      # Adjacent-sibling combinator, mirroring the #detail-title-block +
      # .pk-description assertion style 01.2-17 already established — this
      # only matches when the separator is literally the very next element
      # after the masthead's own outer wrapper, and the shelf is literally
      # the very next element after the separator.
      assert doc |> LazyHTML.query("#detail-masthead-wrap + #detail-shelf-separator") |> Enum.count() ==
               1

      assert doc |> LazyHTML.query("#detail-shelf-separator + #similares") |> Enum.count() == 1
    end

    test "the separator renders on the loading (disconnected) pass too, ahead of the skeleton shelf",
         %{conn: conn} do
      game = game_fixture(%{name: "Base Loading Boundary", weight_band: "nivel_experto"})

      conn = get(conn, ~p"/juegos/#{game.id}")
      html = html_response(conn, 200)

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query("#detail-shelf-separator + #similares-skeleton") |> Enum.count() ==
               1
    end

    test "the shelf's own title, badge, and subtitle still render unchanged with the boundary in place",
         %{conn: conn} do
      game = game_fixture(%{name: "Base Boundary Shelf", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Other Band Boundary", weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "Juegos similares"
      assert html =~ "Ampliado"
      assert html =~ "Otras opciones que te van a encantar"
    end
  end

  # G-01.2-22 task 3: co-located with this page's own test suite (rather
  # than relying solely on layouts_test.exs's call-site assertions) — the
  # detail page IS the one call site that opts into the boundary-collapse
  # flag, so this file should say so directly.
  describe "detail page boundary-collapse contract (G-01.2-22)" do
    test "the detail page's <main> carries pk-boundary-collapse, not the shared default vertical padding",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      class = doc |> LazyHTML.query("main") |> LazyHTML.attribute("class") |> List.first()

      assert class =~ "pk-boundary-collapse"
      refute class =~ "pb-20"
      refute class =~ "pt-8"
    end
  end

  describe "detail page mobile chrome and interaction (SHELL-03)" do
    # G-01.2-21 task 3: this describe pins the lightbox's SERVER-SIDE
    # contract (its state class, its aria-hidden marking, and its guarded
    # select-image path) with ExUnit. The other half of the contract —
    # whether the open/close actually fades and scales, whether focus
    # really moves between the trigger and the close button, and whether
    # ArrowLeft/ArrowRight actually change the image — is all client-side
    # (colocated hook JS) and is NOT exercised by these LiveView tests,
    # which never run JavaScript. That half lives in this plan's own
    # <human-check> blocks, harvested into 01.2-UAT.md at phase end. Naming
    # that boundary here is deliberate: it is what stops a later reader from
    # assuming this file already covers it.
    test "the CTA bar, title-echo bar, and title block all render with their ids", %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ ~s(id="detail-cta-bar")
      assert html =~ ~s(id="detail-title-echo")
      assert html =~ ~s(id="detail-title-block")
    end

    # G-01.2-22 task 1: the title-echo bar's positioning moved from a flow-
    # occupying value to a viewport-anchored one (a layout-space fix — see
    # app.css's own comment on .pk-title-echo). This test pins that the
    # element itself, its scroll-to-top control, and its resting (neither
    # state class present) first render all survive that change untouched.
    # Whether the hook actually ADDS is-visible on scroll or is-parked at
    # the footer is client-side scroll-driven behavior with no LiveView
    # render-test equivalent — untested here, and said so, per the plan's
    # own instruction; those two remain routed to the human-check below.
    test "the title-echo bar still carries its scroll-to-top control, and neither state class is present on first render",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      title_echo_html = doc |> LazyHTML.query("#detail-title-echo") |> LazyHTML.to_html()

      assert title_echo_html =~ ~s(data-scroll-top)
      assert title_echo_html =~ "Volver arriba"

      class =
        doc
        |> LazyHTML.query("#detail-title-echo")
        |> LazyHTML.attribute("class")
        |> List.first()

      refute class =~ "is-visible"
      refute class =~ "is-parked"
    end

    # G-01.2-24 task 1: the bar's title <span> gets a real class so it can
    # be styled directly (min-width: 0 + no-wrap + ellipsis, declared in
    # app.css) — a game name too long to fit alongside the fixed 44px
    # scroll-to-top button must clip on one line instead of wrapping to a
    # second one. This test pins the class exists on the span; the visual
    # truncation itself is CSS and routed to the phase's own human-check.
    test "the title-echo bar's title span carries pk-title-echo-name", %{conn: conn} do
      game = game_fixture(%{name: "Through the Ages: A New Story of Civilization"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      span_html =
        doc
        |> LazyHTML.query("#detail-title-echo span")
        |> LazyHTML.to_html()

      assert span_html =~ ~s(class="pk-title-echo-name")
      assert span_html =~ "Through the Ages: A New Story of Civilization"
    end

    test "the CTA bar's button and the buy-box button share the same phx-click and label", %{
      conn: conn
    } do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      cta_bar_html = doc |> LazyHTML.query("#detail-cta-bar") |> LazyHTML.to_html()
      poster_html = doc |> LazyHTML.query(".pk-poster-col") |> LazyHTML.to_html()

      assert cta_bar_html =~ ~s(phx-click="open-reservation")
      assert cta_bar_html =~ "Reservar para el sábado"
      assert poster_html =~ ~s(phx-click="open-reservation")
      assert poster_html =~ "Reservar para el sábado"

      # The label string exists in exactly one place in the source (a shared
      # private helper) — asserted structurally: the rendered page shows it
      # exactly twice (buy-box + CTA bar), never a third independently
      # authored copy.
      occurrences =
        html
        |> String.split("Reservar para el sábado")
        |> length()
        |> Kernel.-(1)

      assert occurrences == 2
    end

    test "the page carries the .DetailChrome hook and no IntersectionObserver or inline on*= handler",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      # Phoenix qualifies a colocated hook's leading-dot name at render time
      # (".DetailChrome" -> "PukllayClubWeb.CatalogLive.Show.DetailChrome"),
      # per layouts.ex's documented reason for using a static string literal.
      assert html =~ ~s(phx-hook="PukllayClubWeb.CatalogLive.Show.DetailChrome")
      refute html =~ "IntersectionObserver"
      refute html =~ ~r/\son[a-z]+=/
    end

    # G-01.2-21 task 2: the lightbox is now always rendered (state lives in
    # the is-open class + aria-hidden, not in whether the element exists —
    # see app.css's own comment on why display can no longer gate this), so
    # this test asserts on the CLASS and aria-hidden marking rather than on
    # the element's presence/absence.
    test "the lightbox is inert on first render (present, no open class, aria-hidden), opens via its is-open class, and stays in sync with select-image",
         %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover.webp",
          gallery_urls: ["https://images.test.invalid/games/1/gallery-1.webp"]
        })

      {:ok, view, html} = live(conn, ~p"/juegos/#{game.id}")

      lightbox_state = fn html ->
        doc = LazyHTML.from_document(html)

        {
          doc |> LazyHTML.query("#detail-lightbox") |> LazyHTML.attribute("class") |> List.first(),
          doc
          |> LazyHTML.query("#detail-lightbox")
          |> LazyHTML.attribute("aria-hidden")
          |> List.first()
        }
      end

      {class1, hidden1} = lightbox_state.(html)
      refute class1 =~ "is-open"
      assert hidden1 == "true"

      html2 = render_click(view, "open-lightbox", %{})
      {class2, hidden2} = lightbox_state.(html2)
      assert class2 =~ "is-open"
      assert hidden2 == "false"
      assert html2 =~ ~s(aria-modal="true")
      assert html2 =~ ~s(src="https://images.test.invalid/games/1/cover.webp")

      html3 =
        render_click(view, "select-image", %{
          "url" => "https://images.test.invalid/games/1/gallery-1.webp"
        })

      assert html3 =~ ~s(src="https://images.test.invalid/games/1/gallery-1.webp")

      html4 = render_click(view, "close-lightbox", %{})
      {class4, hidden4} = lightbox_state.(html4)
      refute class4 =~ "is-open"
      assert hidden4 == "true"
    end

    test "the select-image whitelist guard still rejects a foreign url while the lightbox is open",
         %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover.webp",
          gallery_urls: []
        })

      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      render_click(view, "open-lightbox", %{})

      html2 = render_click(view, "select-image", %{"url" => "https://evil.example.com/x.jpg"})

      refute html2 =~ "evil.example.com"
      assert html2 =~ ~s(src="https://images.test.invalid/games/1/cover.webp")
    end

    test "the lightbox chevrons carry the keyboard handler's stable hooks and wrap at both ends of the gallery",
         %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover.webp",
          gallery_urls: [
            "https://images.test.invalid/games/1/gallery-1.webp",
            "https://images.test.invalid/games/1/gallery-2.webp"
          ]
        })

      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      # G-01.2-25: the chevrons compute their target against @lightbox_image,
      # which is only seeded once the lightbox actually opens (a visitor
      # cannot navigate a closed lightbox) — open it first, same as a real
      # interaction would.
      html = render_click(view, "open-lightbox", %{})

      neighbor_urls = fn html ->
        doc = LazyHTML.from_document(html)

        {
          doc
          |> LazyHTML.query("#detail-lightbox [data-lightbox-prev]")
          |> LazyHTML.attribute("phx-value-url")
          |> List.first(),
          doc
          |> LazyHTML.query("#detail-lightbox [data-lightbox-next]")
          |> LazyHTML.attribute("phx-value-url")
          |> List.first()
        }
      end

      # cover_url is first in gallery_thumbnails/1's list (the START end),
      # so its previous neighbor wraps AROUND to the last gallery image and
      # its next neighbor is the first gallery image — unchanged targets,
      # only the new data-lightbox-prev/next hooks are added.
      {prev_url, next_url} = neighbor_urls.(html)
      assert prev_url == "https://images.test.invalid/games/1/gallery-2.webp"
      assert next_url == "https://images.test.invalid/games/1/gallery-1.webp"

      # Selecting the LAST image (the other END) and re-reading the chevron
      # targets confirms the wrap holds at both ends, not just the one the
      # page mounts on. Dispatched at the lightbox's OWN event
      # (select-lightbox-image, G-01.2-25) — the chevrons no longer move
      # the page's own select-image assign.
      html2 =
        render_click(view, "select-lightbox-image", %{
          "url" => "https://images.test.invalid/games/1/gallery-2.webp"
        })

      {prev_url2, next_url2} = neighbor_urls.(html2)
      assert prev_url2 == "https://images.test.invalid/games/1/gallery-1.webp"
      assert next_url2 == "https://images.test.invalid/games/1/cover.webp"
    end

    # G-01.2-25 task 2: the lightbox's own selection (@lightbox_image) is
    # split from the page's (@selected_image) — stepping through the
    # lightbox must change ONLY the lightbox's own image. The poster image,
    # the thumbnail carrying the active border and the dot carrying the
    # active state (all readers of @selected_image) must not move.
    test "stepping the lightbox forward changes only the lightbox's own image — the poster, active thumbnail and active dot underneath stay put",
         %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover.webp",
          gallery_urls: [
            "https://images.test.invalid/games/1/gallery-1.webp",
            "https://images.test.invalid/games/1/gallery-2.webp"
          ]
        })

      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      html = render_click(view, "open-lightbox", %{})
      doc = LazyHTML.from_document(html)

      poster_src_before =
        doc
        |> LazyHTML.query("#detail-lightbox-trigger img")
        |> LazyHTML.attribute("src")
        |> List.first()

      active_thumb_before =
        doc
        |> LazyHTML.query(~s(#gallery-thumbnails button[phx-value-url='#{game.cover_url}']))
        |> LazyHTML.attribute("class")
        |> List.first()

      active_dot_before =
        doc
        |> LazyHTML.query(~s(#gallery-dots button[phx-value-url='#{game.cover_url}']))
        |> LazyHTML.attribute("class")
        |> List.first()

      assert poster_src_before == game.cover_url
      assert active_thumb_before =~ "border-primary"
      assert active_dot_before =~ "is-active"

      next_url =
        doc
        |> LazyHTML.query("#detail-lightbox [data-lightbox-next]")
        |> LazyHTML.attribute("phx-value-url")
        |> List.first()

      html2 = render_click(view, "select-lightbox-image", %{"url" => next_url})
      doc2 = LazyHTML.from_document(html2)

      lightbox_img_src =
        doc2
        |> LazyHTML.query("#detail-lightbox .pk-lightbox-img")
        |> LazyHTML.attribute("src")
        |> List.first()

      assert lightbox_img_src == next_url

      poster_src_after =
        doc2
        |> LazyHTML.query("#detail-lightbox-trigger img")
        |> LazyHTML.attribute("src")
        |> List.first()

      active_thumb_after =
        doc2
        |> LazyHTML.query(~s(#gallery-thumbnails button[phx-value-url='#{game.cover_url}']))
        |> LazyHTML.attribute("class")
        |> List.first()

      active_dot_after =
        doc2
        |> LazyHTML.query(~s(#gallery-dots button[phx-value-url='#{game.cover_url}']))
        |> LazyHTML.attribute("class")
        |> List.first()

      assert poster_src_after == poster_src_before
      assert active_thumb_after == active_thumb_before
      assert active_dot_after == active_dot_before
    end

    test "the page's poster, active thumbnail and active dot are still unchanged after the lightbox closes, and reopening starts from the same image again",
         %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover.webp",
          gallery_urls: ["https://images.test.invalid/games/1/gallery-1.webp"]
        })

      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      render_click(view, "open-lightbox", %{})

      render_click(view, "select-lightbox-image", %{
        "url" => "https://images.test.invalid/games/1/gallery-1.webp"
      })

      html = render_click(view, "close-lightbox", %{})
      doc = LazyHTML.from_document(html)

      poster_src =
        doc
        |> LazyHTML.query("#detail-lightbox-trigger img")
        |> LazyHTML.attribute("src")
        |> List.first()

      active_thumb_class =
        doc
        |> LazyHTML.query(~s(#gallery-thumbnails button[phx-value-url='#{game.cover_url}']))
        |> LazyHTML.attribute("class")
        |> List.first()

      assert poster_src == game.cover_url
      assert active_thumb_class =~ "border-primary"

      # G-01.2-25: close-lightbox deliberately does NOT sync @lightbox_image
      # back onto @selected_image, so reopening re-seeds from the
      # untouched page selection, not the lightbox's last navigated-to
      # image.
      html2 = render_click(view, "open-lightbox", %{})
      doc2 = LazyHTML.from_document(html2)

      lightbox_img_src =
        doc2
        |> LazyHTML.query("#detail-lightbox .pk-lightbox-img")
        |> LazyHTML.attribute("src")
        |> List.first()

      assert lightbox_img_src == game.cover_url
    end

    test "the select-lightbox-image whitelist guard rejects a url outside the gallery list and leaves the lightbox's image unchanged",
         %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover.webp",
          gallery_urls: []
        })

      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      render_click(view, "open-lightbox", %{})

      html2 = render_click(view, "select-lightbox-image", %{"url" => "https://evil.example.com/x.jpg"})

      refute html2 =~ "evil.example.com"
      assert html2 =~ ~s(src="https://images.test.invalid/games/1/cover.webp")
    end

    test "the poster button that opens the lightbox carries the stable id the hook focuses on close",
         %{conn: conn} do
      game = game_fixture(%{cover_url: "https://images.test.invalid/games/1/cover.webp"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ ~s(id="detail-lightbox-trigger")
    end

    test "a game with exactly one gallery image renders no chevrons, and a game with none renders the lightbox with no image inside",
         %{conn: conn} do
      one_image_game =
        game_fixture(%{cover_url: "https://images.test.invalid/games/1/cover.webp"})

      {:ok, _view, html_one} = live(conn, ~p"/juegos/#{one_image_game.id}")

      doc_one = LazyHTML.from_document(html_one)
      assert doc_one |> LazyHTML.query("#detail-lightbox [data-lightbox-prev]") |> Enum.count() == 0
      assert doc_one |> LazyHTML.query("#detail-lightbox [data-lightbox-next]") |> Enum.count() == 0

      no_image_game = game_fixture(%{cover_url: nil, gallery_urls: []})

      {:ok, _view, html_none} = live(conn, ~p"/juegos/#{no_image_game.id}")

      doc_none = LazyHTML.from_document(html_none)
      assert doc_none |> LazyHTML.query("#detail-lightbox") |> Enum.count() == 1
      assert doc_none |> LazyHTML.query("#detail-lightbox .pk-lightbox-img") |> Enum.count() == 0
      assert doc_none |> LazyHTML.query("#detail-lightbox [data-lightbox-prev]") |> Enum.count() == 0
      assert doc_none |> LazyHTML.query("#detail-lightbox [data-lightbox-next]") |> Enum.count() == 0
    end

    # G-01.2-18 task 2: the mobile CTA bar's own copy of this control was
    # removed — the poster's corner icon is now the page's sole share entry
    # point, so this test asserts on the one remaining control rather than
    # comparing two.
    test "the one remaining share button renders with a data-share-url matching the canonical route",
         %{conn: conn} do
      game = game_fixture(%{name: "Juego Compartido"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      buybox_url =
        doc |> LazyHTML.query("#detail-share-buybox") |> LazyHTML.attribute("data-share-url")

      assert buybox_url != []
      assert hd(buybox_url) =~ ~p"/juegos/#{game.id}"
      assert doc |> LazyHTML.query("#detail-share-ctabar") |> Enum.count() == 0
    end

    test "the share fallback's WhatsApp and X hrefs are percent-encoded", %{conn: conn} do
      game = game_fixture(%{name: "Catán: Edición Básica"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      whatsapp_hrefs =
        doc
        |> LazyHTML.query("a[aria-label='Compartir por WhatsApp']")
        |> LazyHTML.attribute("href")

      x_hrefs =
        doc
        |> LazyHTML.query("a[aria-label='Compartir por X']")
        |> LazyHTML.attribute("href")

      assert length(whatsapp_hrefs) == 1
      assert length(x_hrefs) == 1

      for href <- whatsapp_hrefs ++ x_hrefs do
        query = href |> String.split("?", parts: 2) |> List.last()
        refute query =~ " "
        refute query =~ "?"
      end
    end

    # The following behaviors are genuinely visual/timing-based (scroll-driven
    # CSS class toggles) and have no LiveView render-test equivalent — they
    # are routed to 01.1-VALIDATION.md's Manual-Only table rather than faked
    # here:
    #   - the CTA bar's debounced hide-while-scrolling and its ~200ms return
    #   - the CTA bar and title-echo bar both parking at the real footer,
    #     with the reserved body padding collapsing in the same transition
    #   - the title-echo bar's fade-in once the real <h1> has scrolled past
    #     the header
  end

  describe "buy-box redesign — panel, poster aspect, CTA prominence, cover fallback (D-07)" do
    test "the buy-box cover carries the shared poster aspect class, not the wide preview ratio class",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      poster_html =
        html |> LazyHTML.from_document() |> LazyHTML.query(".pk-poster-col") |> LazyHTML.to_html()

      assert poster_html =~ "pk-card-poster"
      refute poster_html =~ "pk-preview-poster"
      refute poster_html =~ "aspect-video"
    end

    # The elevated-shadow panel treatment (fill/border/shadow, G-01.2-5/
    # G-01.2-6, sketch 027) moved off .pk-poster-col and onto the new
    # .pk-poster-panel element (G-01.2-19 task 1) — this assertion follows
    # the treatment to its new home rather than being dropped, since the
    # decision it protects (no inline utility duplicating the CSS-declared
    # panel look) is still in force, just on a different element.
    test "the poster panel does not carry the fill-only utility string (elevated-shadow panel lives in app.css, G-01.2-5/G-01.2-6)",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      poster_panel_class =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-poster-panel")
        |> LazyHTML.attribute("class")
        |> List.first()

      refute poster_panel_class =~ "bg-base-200"
      refute poster_panel_class =~ "rounded-box"
      refute poster_panel_class =~ "p-4"
    end

    test "the reserve CTA carries the large size step and full width, and the share control is absolutely positioned rather than a row sibling",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      poster_html = doc |> LazyHTML.query(".pk-poster-col") |> LazyHTML.to_html()

      reserve_button_class =
        doc
        |> LazyHTML.query(".pk-poster-col button[phx-click='open-reservation']")
        |> LazyHTML.attribute("class")
        |> List.first()

      assert reserve_button_class =~ "btn-lg"
      assert reserve_button_class =~ "w-full"
      refute reserve_button_class =~ "flex-1"

      # Structural assertion (not class-string matching): the share
      # control's wrapper is an absolutely positioned sibling ancestor
      # inside the poster frame (G-01.2-10 task 2's positioning context,
      # nested one level inside the poster column), not a flex-row
      # sibling of the reserve button.
      share_wrap_ancestor_class =
        doc
        |> LazyHTML.query(".pk-poster-frame > div")
        |> Enum.map(&LazyHTML.attribute(&1, "class"))
        |> Enum.find(fn class -> List.first(class) =~ "absolute" end)

      assert share_wrap_ancestor_class
      assert poster_html =~ "detail-share-buybox"
    end

    test "the buy-box image carries the cover-fallback class and is immediately followed by a hidden placeholder sibling",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      cover_button_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-poster-col button[phx-click='open-lightbox']")
        |> LazyHTML.to_html()

      assert cover_button_html =~ "js-cover-fallback"

      # Structural check (not just presence): the hidden placeholder is the
      # <img>'s next sibling inside the same button, mirroring GameCard's
      # shape verbatim, so the app-wide error listener's
      # `target.nextElementSibling` lookup actually finds it.
      [_before, after_img] =
        String.split(cover_button_html, ~r/<img[^>]*js-cover-fallback[^>]*>/, parts: 2)

      assert after_img =~ ~r/^\s*<div class="hidden/
      assert after_img =~ "hero-puzzle-piece"
    end

    test "the mobile CTA bar still renders with its id and reserve button alongside the .DetailChrome hook",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      cta_bar_html =
        html |> LazyHTML.from_document() |> LazyHTML.query("#detail-cta-bar") |> LazyHTML.to_html()

      assert html =~ ~s(id="detail-cta-bar")
      assert cta_bar_html =~ ~s(phx-click="open-reservation")
      assert html =~ ~s(phx-hook="PukllayClubWeb.CatalogLive.Show.DetailChrome")
    end

    # G-01.2-18 task 2: the bar's second (share) row is gone — this test now
    # pins the single-control shape and the surviving alignment cap rather
    # than the stacked two-control layout it used to assert.
    test "the mobile CTA bar's inner wrapper holds only the reserve button, capped to the content column (G-01.2-18 task 2)",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      cta_bar_html = doc |> LazyHTML.query("#detail-cta-bar") |> LazyHTML.to_html()

      # Structural assertion (not class-string matching): pk-cta-bar-inner
      # sits between the bar and its one remaining control, and its own
      # parent carries pk-gutter — the shipped shell-column recipe, reused
      # verbatim so the bar's control aligns under the content column.
      inner_parent_class =
        doc
        |> LazyHTML.query("#detail-cta-bar > div")
        |> LazyHTML.attribute("class")
        |> List.first()

      assert inner_parent_class =~ "pk-gutter"

      reserve_button_class =
        doc
        |> LazyHTML.query("#detail-cta-bar .pk-cta-bar-inner button[phx-click='open-reservation']")
        |> LazyHTML.attribute("class")
        |> List.first()

      assert reserve_button_class =~ "w-full"
      refute reserve_button_class =~ "flex-1"
      refute cta_bar_html =~ "flex-1"

      assert cta_bar_html =~ "pk-cta-bar-inner"
      refute cta_bar_html =~ "Compartir"

      assert doc |> LazyHTML.query("#detail-cta-bar .pk-cta-bar-inner > *") |> Enum.count() == 1
    end
  end

  describe "G-01.2-11/G-01.2-12 masthead contract (facts row, panel, CTA, dots, shell width)" do
    test "facts_row renders exactly once, as the poster panel's first child, immediately followed by the poster frame",
         %{conn: conn} do
      game = game_fixture(%{min_players: 2, max_players: 4, weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      # Exactly one copy exists in the whole document — the mobile overlay
      # copy and the desktop inline copy are gone, collapsed into one.
      assert doc |> LazyHTML.query(".pk-facts-row") |> Enum.count() == 1
      assert doc |> LazyHTML.query(".pk-poster-panel > .pk-facts-row") |> Enum.count() == 1

      # Ordered-siblings assertion (not mere presence): the row is the
      # panel's FIRST child and precedes the poster frame in document
      # order, at every viewport width (G-01.2-23 task 2, sketch 037 —
      # moved from being the poster column's first child to being the
      # poster panel's first child, so the pills and the photo share one
      # inset).
      assert doc |> LazyHTML.query(".pk-poster-panel > .pk-facts-row + .pk-poster-frame") |> Enum.count() ==
               1

      # Negative assertion: the row is no longer a direct child of the
      # poster column. A future edit that moves it back out must fail
      # here, not silently reopen the margin-mismatch bug G-01.2-23 fixed.
      assert doc |> LazyHTML.query(".pk-poster-col > .pk-facts-row") |> Enum.count() == 0
    end

    test "the players, tiempo and dificultad pills all render inside the single facts row, with the same link targets they have today",
         %{conn: conn} do
      game = game_fixture(%{min_players: 2, max_players: 4, weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-poster-panel > .pk-facts-row .pk-fact") |> Enum.count() == 3

      assert doc
             |> LazyHTML.query(".pk-poster-panel > .pk-facts-row a.pk-fact[href*='?players=']")
             |> Enum.count() == 1

      assert doc
             |> LazyHTML.query(".pk-poster-panel > .pk-facts-row a.pk-fact[href*='?max_playtime=']")
             |> Enum.count() == 1

      assert doc |> LazyHTML.query(".pk-poster-panel > .pk-facts-row .pk-difficulty") |> Enum.count() ==
               1
    end

    test "the poster panel contains the poster frame and both gallery strips, and does NOT contain the poster column's Reservar button",
         %{conn: conn} do
      game =
        game_fixture(%{
          gallery_urls: ["https://images.test.invalid/games/1/gallery-1.webp"]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-poster-panel .pk-poster-frame") |> Enum.count() == 1
      assert doc |> LazyHTML.query(".pk-poster-panel #gallery-thumbnails") |> Enum.count() == 1
      assert doc |> LazyHTML.query(".pk-poster-panel #gallery-dots") |> Enum.count() == 1

      # Structural assertion: the button is a SIBLING of the panel, not a
      # descendant of it.
      assert doc
             |> LazyHTML.query(".pk-poster-panel button[phx-click='open-reservation']")
             |> Enum.count() == 0

      assert doc
             |> LazyHTML.query(".pk-poster-panel + button[phx-click='open-reservation'].pk-poster-reserve")
             |> Enum.count() == 1
    end

    test "the poster column's reserve button carries pk-poster-reserve and the mobile CTA bar's reserve button does not",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      poster_reserve_class =
        doc
        |> LazyHTML.query(".pk-poster-col button[phx-click='open-reservation']")
        |> LazyHTML.attribute("class")
        |> List.first()

      cta_bar_reserve_class =
        doc
        |> LazyHTML.query("#detail-cta-bar button[phx-click='open-reservation']")
        |> LazyHTML.attribute("class")
        |> List.first()

      assert poster_reserve_class =~ "pk-poster-reserve"
      refute cta_bar_reserve_class =~ "pk-poster-reserve"
    end

    # Two Reservar controls exist in the document (the in-panel one and the
    # fixed bar's one), and exactly one carries the breakpoint-toggled
    # class — this is the DOM-level fact CSS depends on. The visual half of
    # the invariant (only one is ever VISIBLE at a given width) is routed to
    # the phase's human-check, not tested here.
    test "exactly two Reservar controls exist in the document, and exactly one carries the breakpoint-toggled class",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      reserve_buttons = LazyHTML.query(doc, "button[phx-click='open-reservation']")
      assert Enum.count(reserve_buttons) == 2

      breakpoint_gated =
        reserve_buttons
        |> Enum.map(&LazyHTML.attribute(&1, "class"))
        |> Enum.filter(fn class -> List.first(class) =~ "pk-poster-reserve" end)

      assert Enum.count(breakpoint_gated) == 1
    end

    test "the share control is still a descendant of the poster frame, not the panel's margin",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-poster-frame #detail-share-buybox") |> Enum.count() == 1
    end

    # quick 260913-1s5: the share button was anchored 8px (top-2/right-2)
    # from the poster's 8px-radius top-right corner, crowding it. Fix: a
    # 12px inset (top-3/right-3), matching .pk-sheet-close's own 12px —
    # still inside .pk-poster-frame, still the wrapper's own plain Tailwind
    # offset utilities (no .pk-* rule targets this wrapper div).
    test "the share wrapper is inset 12px (top-3/right-3), not the old 8px, and stays inside the poster frame",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      share_wrapper_class =
        doc
        |> LazyHTML.query(".pk-poster-frame > div")
        |> Enum.find(fn el ->
          case LazyHTML.attribute(el, "class") do
            [class] -> class =~ "absolute"
            _ -> false
          end
        end)
        |> LazyHTML.attribute("class")
        |> List.first()

      refute is_nil(share_wrapper_class), "expected .pk-poster-frame > div.absolute to exist"

      tokens = String.split(share_wrapper_class)

      assert "top-3" in tokens
      assert "right-3" in tokens
      refute "top-2" in tokens
      refute "right-2" in tokens

      assert doc |> LazyHTML.query(".pk-poster-frame #detail-share-buybox") |> Enum.count() == 1
    end

    test "each dot dispatches select-image with the same phx-value-url the matching thumbnail dispatches, and the dot count equals the thumbnail count",
         %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover.webp",
          gallery_urls: [
            "https://images.test.invalid/games/1/gallery-1.webp",
            "https://images.test.invalid/games/1/gallery-2.webp"
          ]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      thumbnail_urls =
        doc |> LazyHTML.query("#gallery-thumbnails button") |> LazyHTML.attribute("phx-value-url")

      dot_urls = doc |> LazyHTML.query("#gallery-dots button") |> LazyHTML.attribute("phx-value-url")

      assert length(thumbnail_urls) == 3
      assert length(dot_urls) == 3
      assert Enum.sort(thumbnail_urls) == Enum.sort(dot_urls)
    end

    test "a game with no cover and no gallery images renders the placeholder with no broken panel or stray strip",
         %{conn: conn} do
      game = game_fixture(%{cover_url: nil, gallery_urls: []})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      # The existing no-image placeholder still renders inside the frame,
      # inside the panel.
      assert doc |> LazyHTML.query(".pk-poster-panel .pk-poster-frame .pk-card-poster") |> Enum.count() ==
               1

      assert html =~ "hero-puzzle-piece"

      # The single facts row still renders unconditionally.
      assert doc |> LazyHTML.query(".pk-poster-panel > .pk-facts-row") |> Enum.count() == 1

      refute html =~ "gallery-thumbnails"
      refute html =~ "gallery-dots"
    end

    # Task 2's ask: the three wrappers that used to carry an inner width
    # cap (--pk-detail-col-width) now carry only the shell recipe the
    # header/footer already use — one assertion per wrapper, named so a
    # regression re-capping any one of them fails a test that names it.
    test "the masthead wrapper, the shelf-separator wrapper and the CTA bar's outer wrapper all carry the same shell recipe classes",
         %{conn: conn} do
      game = game_fixture(%{weight_band: "nivel_experto"})
      game_fixture(%{weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      shell_recipe = "mx-auto w-full max-w-7xl pk-gutter"

      masthead_wrap_class =
        doc |> LazyHTML.query("#detail-masthead-wrap") |> LazyHTML.attribute("class") |> List.first()

      shelf_separator_wrap_class =
        doc
        |> LazyHTML.query("#detail-shelf-separator")
        |> LazyHTML.attribute("class")
        |> List.first()

      cta_bar_outer_wrap_class =
        doc |> LazyHTML.query("#detail-cta-bar > div") |> LazyHTML.attribute("class") |> List.first()

      assert masthead_wrap_class == shell_recipe
      assert shelf_separator_wrap_class == shell_recipe
      assert cta_bar_outer_wrap_class == shell_recipe
    end

    # The removed separator-only width-cap class appears nowhere in the
    # rendered page — asserted structurally (an exact class-list match on
    # the divider itself) rather than by grepping for the retired class's
    # own literal name, which this file must not reintroduce even in a
    # test string.
    test "the shelf-separator divider carries only its shared divider classes, no separate width-cap class",
         %{conn: conn} do
      game = game_fixture(%{weight_band: "nivel_experto"})
      game_fixture(%{weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      separator_class =
        doc
        |> LazyHTML.query("#detail-shelf-separator .divider")
        |> LazyHTML.attribute("class")
        |> List.first()

      assert separator_class == "divider pk-divider"
    end
  end

  describe "Mecánicas/Temáticas chip contrast fix (G-01.2-20 task 2, retoned by 01.3-07)" do
    test "the mechanic and theme chip rows' wrapper carries the pk-chip-row scoping class",
         %{conn: conn} do
      # 01.3-07: creator_pills/1 (Diseñadores/Ilustradores) also renders a
      # pk-chip-row wrapper now, inside the same fact grid — scope this
      # fixture to only mechanics/themes so the count below still isolates
      # the two rows this test names.
      game =
        game_fixture(%{
          designers: [],
          artists: [],
          mechanics: ["Dice Rolling"],
          themes: ["Economic"]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query("div.pk-chip-row") |> Enum.count() == 2
    end

    test "the editorial hashtag row does NOT carry pk-chip-row — the two rows stay separately styled",
         %{conn: conn} do
      game = game_fixture(%{tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      # The hashtag chip renders (proves the row is present at all) — the
      # pk-pill base + tag tone (01.3-07, superseding the earlier accent
      # tone — sketch 042's lightweight-text hashtag treatment), not a
      # daisyUI badge class.
      assert doc |> LazyHTML.query(".pk-pill-tag") |> Enum.count() == 1

      # ...but never as a descendant of a pk-chip-row wrapper.
      assert doc |> LazyHTML.query("div.pk-chip-row .pk-pill-tag") |> Enum.count() == 0
    end

    test "linked chips, unlinked chips, and the overflow chip all render inside the scoped wrapper",
         %{conn: conn} do
      # The detail page's own call sites always pass href_fun (linked-chip
      # shape only, real-world call sites have far fewer than the 99-limit
      # so overflow never fires there) — exercise chip_row/1's other two
      # shapes (unlinked span, overflow +N) directly via render_component,
      # the same component-testing idiom this codebase already uses
      # elsewhere, without touching game_chips_test.exs (out of scope for
      # this plan).
      linked_html =
        render_component(&GameChips.chip_row/1,
          terms: ["Tira dados"],
          limit: 4,
          href_fun: fn term -> "/?mechanics=#{term}" end
        )

      unlinked_html = render_component(&GameChips.chip_row/1, terms: ["Tira dados"], limit: 4)

      overflow_html =
        render_component(&GameChips.chip_row/1, terms: for(n <- 1..5, do: "Termino #{n}"), limit: 2)

      # All three shapes render inside chip_row/1's single wrapper div,
      # which carries pk-chip-row unconditionally. Chip class strings now
      # render from the pk-pill base + outline tone (01.3-07, superseding
      # the earlier neutral tone) — interactive only on the linked branch,
      # never on the static span or the overflow chip.
      assert linked_html =~ "pk-chip-row"

      assert linked_html =~
               ~r/<a[^>]*class="pk-pill pk-pill-outline pk-pill-interactive"[^>]*>\s*Tira dados/

      assert unlinked_html =~ "pk-chip-row"
      assert unlinked_html =~ ~s(<span class="pk-pill pk-pill-outline">Tira dados</span>)

      assert overflow_html =~ "pk-chip-row"
      assert overflow_html =~ ~s(<span class="pk-pill pk-pill-outline">+3</span>)

      # Sanity check on the live page: the mechanic chip's real call site
      # (href_fun always passed) does render the linked shape inside the
      # scoped wrapper.
      game = game_fixture(%{designers: [], artists: [], mechanics: ["Dice Rolling"]})
      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")
      doc = LazyHTML.from_document(html)

      assert doc
             |> LazyHTML.query("div.pk-chip-row a.pk-pill[href*='mechanics=']")
             |> Enum.count() == 1
    end
  end

  # G-01.2-26 task 3: negative assertion pinning the migration — a future
  # partial re-migration back onto a daisyUI badge class (on any of the
  # three families this plan touches) must fail here.
  describe "pk-pill migration pins no framework badge class survives (G-01.2-26 task 3)" do
    test "the reading column (editorial hashtags, Mecánicas, Temáticas) and the facts row render from pk-pill, never a daisyUI badge class",
         %{conn: conn} do
      game =
        game_fixture(%{
          mechanics: ["Dice Rolling"],
          themes: ["Economic"],
          tags: ["#CreaConexiones"],
          weight_band: "ingenio_estratega"
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      text_col_html = doc |> LazyHTML.query(".pk-text-col") |> LazyHTML.to_html()
      facts_html = doc |> LazyHTML.query(".pk-poster-panel > .pk-facts-row") |> LazyHTML.to_html()

      refute text_col_html =~ ~r/class="[^"]*\bbadge\b/,
             "the reading column (editorial hashtags, Mecánicas, Temáticas) must render from " <>
               "the pk-pill base, not a daisyUI badge class"

      refute facts_html =~ ~r/class="[^"]*\bbadge\b/,
             "the facts row must render from the pk-pill base, not a daisyUI badge class"
    end
  end

  describe "one control in the mobile CTA bar (G-01.2-18 task 2)" do
    test "the fixed bottom bar contains exactly one interactive control, and it is the reserve button",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      controls = LazyHTML.query(doc, "#detail-cta-bar .pk-cta-bar-inner button, #detail-cta-bar .pk-cta-bar-inner a")

      assert Enum.count(controls) == 1

      assert doc
             |> LazyHTML.query("#detail-cta-bar .pk-cta-bar-inner button[phx-click='open-reservation']")
             |> Enum.count() == 1
    end

    test "the page still renders exactly one share control, and it is inside the poster frame",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-share-trigger") |> Enum.count() == 1
      assert doc |> LazyHTML.query(".pk-poster-frame .pk-share-trigger") |> Enum.count() == 1
      refute html =~ "detail-share-ctabar"
    end

    test "the bar's reserve button still carries the full-width and touch-floor classes it carries today",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      reserve_button_class =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#detail-cta-bar button[phx-click='open-reservation']")
        |> LazyHTML.attribute("class")
        |> List.first()

      assert reserve_button_class =~ "w-full"
      assert reserve_button_class =~ "min-h-11"
    end

    test "the shared share-control component renders its accessible name unconditionally now that only one shape remains",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      aria_label =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-share-trigger")
        |> LazyHTML.attribute("aria-label")
        |> List.first()

      refute aria_label in [nil, ""]
    end
  end

  # 01.2-18 task 3: every mechanical ask from G-01.2-10's UAT `missing` list
  # gathered into one named group so a regression on any single one fails a
  # test that names that ask, rather than failing something generic spread
  # across other describe blocks. One assertion per ask, not one shared
  # assertion.
  describe "G-01.2-10 mobile detail-page contract (regression pin, 01.2-18 task 3)" do
    # G-01.2-19 task 1 revised this invariant: the two-copy overlay/inline
    # swap is gone, collapsed into a single facts row above the poster
    # panel (see the "masthead restructure" describe above for the full
    # contract). This test now pins that one row still renders on every
    # render, rather than the two wrappers it used to assert.
    test "the single facts row renders, as a direct child of the poster column, on every render",
         %{conn: conn} do
      game = game_fixture(%{min_players: 2, max_players: 4})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-poster-panel > .pk-facts-row") |> Enum.count() == 1
    end

    test "the description's section immediately follows the title's section and the hashtag row (01.3-07 reorder)",
         %{conn: conn} do
      game = game_fixture(%{description: "Una crónica de mercaderes.", tags: ["#CreaConexiones"]})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc
             |> LazyHTML.query(".pk-reading-section + div.pk-rhythm-8 + div.pk-reading-section.pk-rhythm-16")
             |> Enum.count() == 1
    end

    test "the poster column's reserve button and the bar's reserve button are separately addressable, and exactly one carries the breakpoint-toggled class",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      poster_reserve = LazyHTML.query(doc, ".pk-poster-col button[phx-click='open-reservation']")
      bar_reserve = LazyHTML.query(doc, "#detail-cta-bar button[phx-click='open-reservation']")

      assert Enum.count(poster_reserve) == 1
      assert Enum.count(bar_reserve) == 1

      poster_class = poster_reserve |> LazyHTML.attribute("class") |> List.first()
      bar_class = bar_reserve |> LazyHTML.attribute("class") |> List.first()

      assert poster_class =~ "pk-poster-reserve"
      refute bar_class =~ "pk-poster-reserve"
    end

    test "the chip rows still render after the description; the editorial hashtags render before it (01.3-07 reorder)",
         %{conn: conn} do
      game =
        game_fixture(%{
          description: "Una crónica.",
          mechanics: ["Dice Rolling"],
          themes: ["Economic"],
          tags: ["#CreaConexiones"]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      # Phase 01.8's Game JSON-LD block (`root.html.heex`, rendered inside
      # <head>) also carries this game's own description text verbatim, so
      # a scope-free :binary.match/2 would find that earlier <head>
      # occurrence instead of the visible reading-column one this test
      # means to locate. Scope the search to start at <body>.
      {body_idx, _} = :binary.match(html, "<body")

      {description_idx, _} =
        :binary.match(html, "Una crónica.", scope: {body_idx, byte_size(html) - body_idx})

      {mechanics_idx, _} = :binary.match(html, "Mecánicas")
      {themes_idx, _} = :binary.match(html, "Temáticas")
      {hashtag_idx, _} = :binary.match(html, "#CreaConexiones")

      assert description_idx < mechanics_idx
      assert description_idx < themes_idx
      assert hashtag_idx < description_idx
    end

    test "no publisher row renders, and a publishers-only game renders no fact grid and no Comunidad BGG block",
         %{conn: conn} do
      with_publisher = game_fixture(%{publishers: ["Devir"]})
      {:ok, _view, html_with} = live(conn, ~p"/juegos/#{with_publisher.id}")
      refute html_with =~ "Editorial"

      publishers_only =
        game_fixture(%{
          min_age: nil,
          year_published: nil,
          designers: [],
          artists: [],
          mechanics: [],
          themes: [],
          publishers: ["Devir"],
          bgg_id: nil,
          bgg_weight: nil,
          bgg_rating: nil,
          bgg_rank: nil
        })

      {:ok, _view, html_only} = live(conn, ~p"/juegos/#{publishers_only.id}")
      refute html_only =~ "pk-spec-list"
      refute html_only =~ "Comunidad BGG"
    end

    test "a separator sits between the masthead and the shelf", %{conn: conn} do
      game = game_fixture(%{weight_band: "nivel_experto"})
      game_fixture(%{weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query("#detail-masthead-wrap + #detail-shelf-separator") |> Enum.count() ==
               1
    end

    test "the bar holds exactly one control", %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query("#detail-cta-bar .pk-cta-bar-inner > *") |> Enum.count() == 1
    end

    # Checkpoint D3 (01.2-17): dots on mobile, thumbnails on desktop — both
    # sides of the swap exist in the DOM at every render (CSS toggles which
    # one is visible), so the developer's chosen outcome (keep the strip,
    # add dots alongside it) stays checkable even if a later "cleanup"
    # tries to silently remove what was chosen to keep.
    test "the gallery renders both the thumbnail strip and the dot affordance (checkpoint D3)",
         %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover.webp",
          gallery_urls: ["https://images.test.invalid/games/1/gallery-1.webp"]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "gallery-thumbnails"
      assert html =~ "gallery-dots"
    end

    # "Exactly one reserve control per viewport" is not testable server-side
    # (the breakpoint that hides one of them is CSS, not markup) — this pins
    # the DOM-level fact that CSS depends on instead: two reserve controls
    # exist in the document and exactly one of them carries the class the
    # 48rem detail-layout block toggles. The visual half of the invariant
    # (only one is ever VISIBLE at a given width) is routed to the phase's
    # human-check.
    test "exactly two reserve controls exist in the document, and exactly one of them is breakpoint-gated",
         %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      reserve_buttons = LazyHTML.query(doc, "button[phx-click='open-reservation']")
      assert Enum.count(reserve_buttons) == 2

      breakpoint_gated =
        reserve_buttons
        |> Enum.map(&LazyHTML.attribute(&1, "class"))
        |> Enum.filter(fn class -> List.first(class) =~ "pk-poster-reserve" end)

      assert Enum.count(breakpoint_gated) == 1
    end
  end

  describe "reservation flow (SHELL-03, T-01.1-02)" do
    test "the buy-box trigger opens the reservation modal", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      html = view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      assert html =~ "modal-box"
      assert html =~ ~s(name="nombre")
    end

    test "the mobile CTA-bar trigger opens the same reservation modal", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      html = view |> element("#detail-cta-bar button[phx-click='open-reservation']") |> render_click()

      assert html =~ "modal-box"
      assert html =~ ~s(name="nombre")
    end

    test "an empty name produces a validation message and no wa.me link", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      html = view |> form("#reservation-modal form", %{"nombre" => ""}) |> render_submit()

      assert html =~ "Falta tu nombre."
      refute html =~ "Mandar por WhatsApp"
    end

    test "a whitespace-only name behaves identically to an empty one", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      html = view |> form("#reservation-modal form", %{"nombre" => "   "}) |> render_submit()

      assert html =~ "Falta tu nombre."
      refute html =~ "Mandar por WhatsApp"
    end

    test "a name over 60 graphemes produces a length message and no wa.me link", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      too_long = String.duplicate("a", 61)
      html = view |> form("#reservation-modal form", %{"nombre" => too_long}) |> render_submit()

      assert html =~ "Ese nombre es muy largo."
      refute html =~ "Mandar por WhatsApp"
    end

    test "a valid name produces a working wa.me link to the configured number", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      html = view |> form("#reservation-modal form", %{"nombre" => "Ana Pérez"}) |> render_submit()

      configured_number = Application.get_env(:pukllay_club, :reservation_whatsapp_number)
      assert html =~ "https://wa.me/#{configured_number}?text="
    end

    test "the visitor's name and the game's name are percent-encoded in the wa.me link — no raw space or accented character survives",
         %{conn: conn} do
      game = game_fixture(%{name: "Río Grande"})
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      html = view |> form("#reservation-modal form", %{"nombre" => "José Pérez"}) |> render_submit()

      doc = LazyHTML.from_fragment(html)
      [href] = doc |> LazyHTML.query("#reservation-modal a[href^='https://wa.me/']") |> LazyHTML.attribute("href")
      query = href |> String.split("text=", parts: 2) |> List.last()

      refute query =~ " "
      refute query =~ "é"
      refute query =~ "í"
    end

    test "special characters cannot break out of the text= query parameter", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      html =
        view
        |> form("#reservation-modal form", %{"nombre" => ~s(A&B=C#D"E)})
        |> render_submit()

      doc = LazyHTML.from_fragment(html)
      [href] = doc |> LazyHTML.query("#reservation-modal a[href^='https://wa.me/']") |> LazyHTML.attribute("href")
      query = href |> String.split("text=", parts: 2) |> List.last()

      refute query =~ "&"
      refute query =~ "#"
    end

    test "the reservation message asks the club to set the game up on-site — never to lend or hand it over (D-09)",
         %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      html = view |> form("#reservation-modal form", %{"nombre" => "Ana"}) |> render_submit()

      assert html =~ "quiero reservar"
      assert html =~ "sábado en el club"
      refute html =~ ~r/presta|préstamo|alquil|llevar a casa/i
    end

    test "an unconfigured reservation number renders an explanatory message and no link", %{conn: conn} do
      original = Application.get_env(:pukllay_club, :reservation_whatsapp_number)
      Application.put_env(:pukllay_club, :reservation_whatsapp_number, nil)
      on_exit(fn -> Application.put_env(:pukllay_club, :reservation_whatsapp_number, original) end)

      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      html = view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      assert html =~ "Las reservas están cerradas por ahora."
      refute html =~ "Mandar por WhatsApp"
    end

    test "no reservation data is persisted anywhere — the app defines no schema for it", %{conn: conn} do
      refute Code.ensure_loaded?(Reservation)

      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()
      view |> form("#reservation-modal form", %{"nombre" => "Ana"}) |> render_submit()

      # Still no such schema after a full submit — nothing was ever wired to
      # persist, so there is nothing a submit could have created.
      refute Code.ensure_loaded?(Reservation)
    end
  end

  # Regression pins for the prod FunctionClauseError diagnosed in
  # `.planning/debug/resolved/catalog-show-no-clause.md` (Sentry ELIXIR-1).
  #
  # Oracle type: DERIVED — the expected payload shape is not a guess, it is
  # read off LiveView's shipped client
  # (deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js): `extractMeta`
  # emits every `phx-value-*` attribute plus, for any non-<form> element with a
  # native `.value`, that value under the key "value"; the focusout binding
  # pushes exactly that, because `eventMeta/3` returns `{}` with no liveSocket
  # `metadata` callback registered (assets/js/app.js registers none).
  #
  # These MUST push the payload explicitly rather than going through
  # `view |> element("#reservation-nombre") |> render_blur()`. LiveViewTest
  # builds a non-form event's params from `phx-value-*` attributes ALONE
  # (client_proxy.ex's `maybe_values/4` fallback -> `TreeDOM.all_values/1`); it
  # never replicates extractMeta's native-`.value` copy, so the element-based
  # helper would send `%{}` — a payload no browser can produce. That blind spot
  # is exactly why a fully green suite coexisted with a 100%-reproducible prod
  # crash: nothing here drove these handlers at all before this block existed.
  describe "reservation blur contract (regression: Sentry ELIXIR-1, catalog-show-no-clause)" do
    setup %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      %{view: view, game: game}
    end

    test "a blur carries the typed name under \"value\", and the handler accepts it", %{view: view} do
      html = render_blur(view, "validate-reservation", %{"value" => "Ana"})

      assert html =~ "Mandar por WhatsApp"
      refute html =~ "Falta tu nombre."
    end

    test "an empty blur reports the empty-name message rather than crashing", %{view: view} do
      html = render_blur(view, "validate-reservation", %{"value" => ""})

      assert html =~ "Falta tu nombre."
      refute html =~ "Mandar por WhatsApp"
    end

    test "a whitespace-only blur behaves identically to an empty one", %{view: view} do
      html = render_blur(view, "validate-reservation", %{"value" => "   "})

      assert html =~ "Falta tu nombre."
      refute html =~ "Mandar por WhatsApp"
    end

    # Boundary neighbours around the 60-grapheme equivalence class: the single
    # reported value would have missed an off-by-one on either side of it.
    test "exactly 60 graphemes is accepted on blur", %{view: view} do
      html = render_blur(view, "validate-reservation", %{"value" => String.duplicate("a", 60)})

      assert html =~ "Mandar por WhatsApp"
      refute html =~ "Ese nombre es muy largo."
    end

    test "61 graphemes is rejected on blur", %{view: view} do
      html = render_blur(view, "validate-reservation", %{"value" => String.duplicate("a", 61)})

      assert html =~ "Ese nombre es muy largo."
      refute html =~ "Mandar por WhatsApp"
    end

    # The markup half of the contract the handler's pattern depends on. If a
    # `phx-value-*` attribute is ever added here, extractMeta would start
    # emitting that key too and someone could plausibly "tidy" the handler onto
    # it — this pins that the input carries none, so "value" really is the only
    # key that can arrive.
    test "the blurring input carries no phx-value-* attribute, so \"value\" is the only payload key",
         %{view: view} do
      input =
        view
        |> render()
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(~s(input[phx-blur="validate-reservation"]))

      assert Enum.count(input) == 1

      value_attrs =
        input
        |> LazyHTML.attributes()
        |> List.first()
        |> Enum.map(fn {name, _} -> name end)
        |> Enum.filter(&String.starts_with?(&1, "phx-value-"))

      assert value_attrs == []
      assert input |> LazyHTML.attribute("name") |> List.first() == "nombre"
    end

    # `reserve` is the other half of the same modal and is deliberately NOT
    # symmetric: it is a real phx-submit on the <form>, so it does receive
    # serialized form params. Pinned here so the two are never "made
    # consistent" with each other by someone reading only one of them.
    test "submit still speaks form params (\"nombre\"), unlike blur", %{view: view} do
      html = view |> form("#reservation-modal form", %{"nombre" => "Ana"}) |> render_submit()

      assert html =~ "Mandar por WhatsApp"
    end
  end

  # Class guard for the whole bug family, automating the enumeration that
  # diagnosed it: every event this page can dispatch must have a clause. The
  # attribute scan covers the template and everything it renders; the source
  # scan covers colocated hooks, whose <script> blocks are extracted at compile
  # time and so never appear in the rendered HTML.
  describe "every event the detail page can dispatch is handled (catalog-show-no-clause class guard)" do
    @event_attr_pattern ~r/phx-(?:click|blur|submit|change|keydown|keyup|focus)="([^"]*)"/
    # Show's own module, plus the two other modules whose colocated hooks run
    # on a rendered detail page (Layouts.app's header and the Juegos similares
    # shelf). A hook push is invisible to any markup scan.
    @hook_push_sources [
      "lib/pukllay_club_web/live/catalog_live/show.ex",
      "lib/pukllay_club_web/components/layouts.ex",
      "lib/pukllay_club_web/components/carousel_row.ex"
    ]

    test "the dispatchable event set is exactly the reviewed list", %{conn: conn} do
      game =
        game_fixture(%{
          gallery_urls: [
            "https://images.test.invalid/games/13/gallery-1.webp",
            "https://images.test.invalid/games/13/gallery-2.webp"
          ]
        })

      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      # Open the reservation modal so its own subtree is in the scanned markup.
      html = view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      from_markup =
        @event_attr_pattern
        |> Regex.scan(html)
        |> Enum.map(&List.last/1)
        # JS-command bindings (e.g. the theme switcher's JS.dispatch) render as
        # a JSON array, not an event name — they never reach handle_event/3.
        |> Enum.reject(&String.starts_with?(&1, "["))

      from_hooks =
        Enum.flat_map(@hook_push_sources, fn path ->
          ~r/pushEvent\("([^"]+)"/
          |> Regex.scan(File.read!(path))
          |> Enum.map(&List.last/1)
        end)

      dispatchable = from_markup |> Enum.concat(from_hooks) |> Enum.uniq() |> Enum.sort()

      assert dispatchable == [
               "carousel-load-more",
               "close-lightbox",
               "close-reservation",
               "close-search",
               "open-lightbox",
               "open-reservation",
               "open-search",
               "reserve",
               "select-image",
               "select-lightbox-image",
               "toggle-description",
               "validate-reservation"
             ],
             """
             The set of events reachable from the detail page changed.

             Every name here needs a matching CatalogLive.Show.handle_event/3
             clause whose params pattern matches the payload the BROWSER sends
             — not the one a render_click/render_blur test fabricates. See
             `.planning/debug/resolved/catalog-show-no-clause.md`: an
             unmatched payload crashes the whole LiveView, and the stacktrace
             blames the module's FIRST clause, not the guilty one.
             """
    end

    # CarouselRow's .CarouselScroll hook can push carousel-load-more from any
    # page rendering a shelf. This page's shelf is client-guarded by
    # exhausted={true}, so the push should not happen — but the server must
    # still answer it, because that guard is one template attribute deep.
    test "carousel-load-more is answered (exhausted) instead of crashing the page", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      assert render_hook(view, "carousel-load-more", %{"row" => "similares"}) =~ game.name
      assert render_hook(view, "carousel-load-more", %{}) =~ game.name
    end

    # Not cosmetic, and not assertable through render_hook/3 (which surfaces
    # only the rendered result). `exhausted: true` in the REPLY is the whole
    # stop signal: .CarouselScroll clears `pending` in the reply callback and
    # only latches `this.exhausted` when the reply says so, so a `{:noreply,
    # socket}` here would leave the rail re-firing this event on every single
    # scroll frame instead of stopping after one.
    test "the carousel-load-more reply carries the stop signal the hook latches on" do
      socket = %Phoenix.LiveView.Socket{}

      assert {:reply, %{exhausted: true}, ^socket} =
               Show.handle_event("carousel-load-more", %{}, socket)
    end

    # The client-side half of the guard. A band-mate is required for the shelf
    # to render at all (an empty shelf is omitted entirely), so this also
    # documents that the guard only exists on pages where a shelf exists.
    test "the Juegos similares shelf is still marked exhausted in the markup", %{conn: conn} do
      game = game_fixture(%{name: "Base Exhausted", weight_band: "nivel_experto"})
      game_fixture(%{name: "Bandmate Exhausted", weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      shelf =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#similares")

      assert Enum.count(shelf) == 1
      assert shelf |> LazyHTML.attribute("data-exhausted") |> List.first() == "true"
    end
  end

  # Regression pin for debug session search-broken-on-mobile-detail. The
  # header search-morph's open/closed state is server-owned (01.2-11): the
  # ONLY thing that ever puts `.is-open` on `.pk-search-morph` is the page's
  # :search_expanded assign. This page used to answer open-search/close-search
  # with `{:noreply, socket}` and pass a hardcoded `search_expanded={false}`,
  # so tapping the magnifying glass round-tripped, changed nothing, and the
  # native GET form's input stayed `width: 0; opacity: 0; pointer-events:
  # none` (app.css `.pk-search-morph .pk-nav-search`) at every viewport. The
  # "every event is handled" class guard above stayed green throughout — it
  # proves a clause EXISTS, never that the clause does anything. These tests
  # click the real rendered buttons (element/2 + render_click/1) so they go
  # through the same phx-click binding a tap does.
  describe "header search-morph opens and closes on the detail page (search-broken-on-mobile-detail)" do
    defp morph(html), do: html |> LazyHTML.from_document() |> LazyHTML.query(".pk-search-morph")

    defp morph_open?(html) do
      doc = LazyHTML.from_document(html)

      Enum.count(LazyHTML.query(doc, ".pk-search-morph.is-open")) == 1 and
        Enum.count(LazyHTML.query(doc, ".pk-nav-inner.is-search-open")) == 1 and
        doc |> LazyHTML.query(".pk-search-morph") |> LazyHTML.attribute("data-search-expanded") == ["true"] and
        doc |> LazyHTML.query(".pk-search-morph-toggle") |> LazyHTML.attribute("aria-expanded") == ["true"]
    end

    defp morph_closed?(html) do
      doc = LazyHTML.from_document(html)

      Enum.empty?(LazyHTML.query(doc, ".pk-search-morph.is-open")) and
        Enum.empty?(LazyHTML.query(doc, ".pk-nav-inner.is-search-open")) and
        doc |> LazyHTML.query(".pk-search-morph") |> LazyHTML.attribute("data-search-expanded") == ["false"] and
        doc |> LazyHTML.query(".pk-search-morph-toggle") |> LazyHTML.attribute("aria-expanded") == ["false"]
    end

    test "renders closed on arrival, with the native GET search form inside the morph", %{conn: conn} do
      game = game_fixture()
      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert morph_closed?(html)
      assert html |> morph() |> Enum.count() == 1

      form =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-search-morph #pk-nav-search-region form[role='search']")

      assert LazyHTML.attribute(form, "action") == ["/"]
      assert LazyHTML.attribute(form, "method") == ["get"]

      assert html
             |> LazyHTML.from_document()
             |> LazyHTML.query(".pk-search-morph input#detail-search-q[name='q']")
             |> Enum.count() == 1
    end

    test "tapping the search icon opens the morph so the input becomes reachable", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      html = view |> element(".pk-search-morph-toggle") |> render_click()

      assert morph_open?(html),
             "Tapping `.pk-search-morph-toggle` on the detail page must render " <>
               "`.pk-search-morph.is-open` (and `.pk-nav-inner.is-search-open`, " <>
               "data-search-expanded/aria-expanded=\"true\"). Without `.is-open` the search " <>
               "input stays width 0 / opacity 0 / pointer-events none at every viewport."
    end

    test "the close control closes it again, and the icon reopens it", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      assert view |> element(".pk-search-morph-toggle") |> render_click() |> morph_open?()
      assert view |> element(".pk-search-morph-close") |> render_click() |> morph_closed?()
      assert view |> element(".pk-search-morph-toggle") |> render_click() |> morph_open?()
    end

    test "open-search is idempotent and close-search on an already-closed morph stays closed",
         %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      assert view |> render_click("close-search", %{}) |> morph_closed?()
      assert view |> render_click("open-search", %{}) |> morph_open?()
      assert view |> render_click("open-search", %{}) |> morph_open?()
    end

    test "an unrelated event does not strip an open morph shut", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      view |> element(".pk-search-morph-toggle") |> render_click()

      assert view |> render_click("toggle-description", %{}) |> morph_open?()
    end
  end

  describe "facts pills and chips link into the catalog's filter params (SHELL-04, 01.1-06)" do
    test "the dificultad pill links to ?weight_bands=<band> — the badge's removed link target, moved here (G-01.2-20)",
         %{conn: conn} do
      game = game_fixture(%{name: "Banded Game", weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc
             |> LazyHTML.query(".pk-poster-panel > .pk-facts-row a.pk-fact[href='/?weight_bands=ingenio_estratega']")
             |> Enum.count() == 1
    end

    test "a game with no weight band renders neither a dificultad link nor a bare band label in the facts row",
         %{conn: conn} do
      game = game_fixture(%{name: "No Band Game", weight_band: nil})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc
             |> LazyHTML.query(".pk-poster-panel > .pk-facts-row a[href*='weight_bands=']")
             |> Enum.count() == 0

      refute html =~ "pk-difficulty"
    end

    test "each editorial tag links to ?tags=<tag>", %{conn: conn} do
      game = game_fixture(%{name: "Tagged Game", tags: ["#CreaConexiones", "#EquipoGanador"]})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "tags=%23CreaConexiones"
      assert html =~ "tags=%23EquipoGanador"
    end

    test "each mechanic chip links to ?mechanics=<label>", %{conn: conn} do
      game = game_fixture(%{name: "Mechanic Game", mechanics: ["Dice Rolling"]})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "mechanics="
    end

    test "each theme chip links to ?themes=<label>", %{conn: conn} do
      game = game_fixture(%{name: "Theme Game", themes: ["Economic"]})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "themes="
    end

    test "the players fact links to ?players=<n> when min and max players are both present", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Player Game", min_players: 2, max_players: 5})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "players=5"
    end

    test "the tiempo fact links to ?max_playtime=<n>", %{conn: conn} do
      game =
        game_fixture(%{name: "Time Game", min_playtime: 30, max_playtime: 45, playing_time: nil})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "max_playtime=45"
    end

    test "the browse-card hover preview's facts_row does NOT link (linked defaults to false)", %{
      conn: conn
    } do
      game_fixture(%{name: "Card Preview Game", min_players: 2, max_players: 5})

      {:ok, _view, html} = live(conn, ~p"/")

      preview_html =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("template[data-game-preview]")
        |> LazyHTML.to_html()

      refute preview_html =~ "players="
    end
  end

  describe "detail page in-flight state (01.1-07)" do
    test "the disconnected render paints the similares skeleton shelf, not the real query", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Base Disconnected", weight_band: "nivel_experto"})
      game_fixture(%{name: "Bandmate Disconnected", weight_band: "nivel_experto"})

      conn = get(conn, ~p"/juegos/#{game.id}")
      html = html_response(conn, 200)

      assert html =~ "similares-skeleton"
      refute html =~ "Bandmate Disconnected"
    end

    test "the connected render replaces the skeleton with the real shelf", %{conn: conn} do
      game = game_fixture(%{name: "Base Connected", weight_band: "nivel_experto"})
      game_fixture(%{name: "Bandmate Connected", weight_band: "nivel_experto"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "similares-skeleton"
      assert html =~ "Bandmate Connected"
    end

    test "the loading skeleton and the real shelf share the pk-card-poster footprint class", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Base Footprint", weight_band: "nivel_experto"})
      game_fixture(%{name: "Bandmate Footprint", weight_band: "nivel_experto"})

      disconnected_conn = get(conn, ~p"/juegos/#{game.id}")
      disconnected_html = html_response(disconnected_conn, 200)

      {:ok, _view, connected_html} = live(conn, ~p"/juegos/#{game.id}")

      assert disconnected_html =~ "pk-card-poster"
      assert connected_html =~ "pk-card-poster"
    end
  end

  describe "breadcrumb carries forward catalog filters (D-08)" do
    test "returning via the breadcrumb after a filtered catalog search lands back on the same filtered view",
         %{conn: conn} do
      game_fixture(%{name: "Catán Dice"})
      game_fixture(%{name: "Other Dice"})

      {:ok, index_view, _html} = live(conn, ~p"/")

      filtered_html =
        index_view
        |> form("#catalog-search-form")
        |> render_change(%{q: "Catán"})

      href =
        filtered_html
        |> LazyHTML.from_document()
        |> LazyHTML.query("[data-game-card]")
        |> LazyHTML.attribute("href")
        |> List.first()

      assert href =~ "from="

      {:ok, _show_view, show_html} = live(conn, href)

      assert show_html =~ "Catán Dice"

      crumb_href =
        show_html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-nav-crumb a")
        |> LazyHTML.attribute("href")
        |> List.first()

      assert crumb_href == "/?q=Cat%C3%A1n"
    end

    test "a direct /juegos/:id visit (no from param) breadcrumbs back to the bare catalog root", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Direct Visit Game"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      crumb_href =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-nav-crumb a")
        |> LazyHTML.attribute("href")
        |> List.first()

      assert crumb_href == "/"
    end

    test "a from value carrying an absolute foreign URL never becomes the breadcrumb target", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Hostile From Game"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}?from=#{"https://evil.example"}")

      crumb_href =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-nav-crumb a")
        |> LazyHTML.attribute("href")
        |> List.first()

      assert crumb_href == "/"
    end
  end

  describe "carousel_row/1 badge attr (G-01.2-7, sketch 031)" do
    test "badge: nil renders a header identical to today's — no badge element present" do
      game = game_fixture(%{name: "Row Game"})

      html =
        render_component(&CarouselRow.carousel_row/1, %{
          id: "row",
          title: "Título",
          games: [{"g-#{game.id}", game}],
          row_key: "row"
        })

      header_html =
        html |> LazyHTML.from_fragment() |> LazyHTML.query(".pk-row-header") |> LazyHTML.to_html()

      refute header_html =~ "badge-accent"
    end

    test "badge: \"Ampliado\" renders that text inside the heading" do
      game = game_fixture(%{name: "Row Game"})

      html =
        render_component(&CarouselRow.carousel_row/1, %{
          id: "row",
          title: "Título",
          games: [{"g-#{game.id}", game}],
          row_key: "row",
          badge: "Ampliado"
        })

      header_html =
        html |> LazyHTML.from_fragment() |> LazyHTML.query(".pk-row-header") |> LazyHTML.to_html()

      assert header_html =~ "badge-accent"
      assert header_html =~ "Ampliado"
    end

    # G-01.2-7 regression guard: this is the one page carousel_row/1's new
    # badge attr does NOT otherwise touch. Rendered exactly as
    # CatalogLive.Index calls it (no badge argument passed, matching all 8
    # D-09 home-page rows), the emitted header must carry no badge element.
    test "rendered exactly as CatalogLive.Index calls it (no badge arg), the header carries no badge element" do
      game = game_fixture(%{name: "Home Page Game"})

      html =
        render_component(&CarouselRow.carousel_row/1, %{
          id: "carousel-destacados_del_club",
          title: "Destacados del club",
          games: [{"g-#{game.id}", game}],
          variant: :hero,
          subtitle: "Los favoritos del club",
          empty: false,
          row_key: "destacados_del_club",
          exhausted: true
        })

      header_html =
        html |> LazyHTML.from_fragment() |> LazyHTML.query(".pk-row-header") |> LazyHTML.to_html()

      refute header_html =~ "badge-accent"
    end
  end

  describe "gallery dot hit-box floors (Phase 01.2 gap-closure round 3, G-01.2-23 task 1)" do
    @css_path Path.expand("../../../assets/css/app.css", __DIR__)

    # First top-level `.pk-gallery-dot {...}` block in app.css, matched on
    # the exact selector text so a future `.pk-gallery-dot-mark` or
    # `.pk-gallery-dots` addition can never be mistaken for this one.
    defp gallery_dot_block do
      src = File.read!(@css_path)

      case Regex.run(~r/(?m)^\.pk-gallery-dot\s*\{([^}]*)\}/, src) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-gallery-dot {...}` rule found in assets/css/app.css")
      end
    end

    test "the dot's hit box is 1.5rem wide and 2.75rem tall — a 24px width floor and a 44px height floor" do
      body = gallery_dot_block()

      assert body =~ ~r/width:\s*1\.5rem/,
             "`.pk-gallery-dot` must declare `width: 1.5rem` (24px) — the WCAG 2.5.8 AA " <>
               "target-size minimum. A wider box reopens the ~40px mark spacing UAT test 8 " <>
               "flagged (a 44px-wide box is geometrically incompatible with a compact " <>
               "three-dot indicator); a narrower box drops below the accessibility floor."

      assert body =~ ~r/height:\s*2\.75rem/,
             "`.pk-gallery-dot` must keep `height: 2.75rem` (44px) — this layer's own " <>
               "`min-h-11` HEIGHT floor. The dot is the phone's ONLY image switcher " <>
               "(the thumbnail strip is desktop-only); shrinking its tap height would make " <>
               "it unreachable."
    end
  end

  # G-01.2-24 task 1: source-level CSS fact for this gap-closure round — the
  # 48rem detail-layout block hides the title-echo bar at desktop widths.
  # Co-located here (matching the gallery-dot-hit-box describe above)
  # rather than in layouts_test.exs since this is specific to this page's
  # own CSS, not shared-shell CSS.
  describe "title-echo desktop hide (Phase 01.2 gap-closure round 4, G-01.2-24 task 1)" do
    @css_path Path.expand("../../../assets/css/app.css", __DIR__)

    defp css_source, do: File.read!(@css_path)

    # Matches the single top-level `@media (min-width: 48rem) { ... }`
    # block. The block's own closing brace is un-indented (column 0); every
    # nested rule's closing brace inside it is indented — so a non-greedy
    # match up to the first `\n}` finds exactly the block's own end, never
    # a nested rule's end, regardless of how many rules live inside it.
    defp detail_layout_breakpoint_block do
      case Regex.run(~r/^@media \(min-width: 48rem\) \{(.*?)\n\}/ms, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `@media (min-width: 48rem) { ... }` block found in app.css")
      end
    end

    test "the 48rem detail-layout block hides the title-echo bar, beside the mobile CTA bar's own hide" do
      block = detail_layout_breakpoint_block()

      assert block =~ ~r/\.pk-title-echo\s*\{\s*display:\s*none;\s*\}/,
             "The single 48rem detail-layout block (the same one that already hides " <>
               ".pk-mobile-cta-bar) must also hide .pk-title-echo — this is G-01.2-14's " <>
               "confirmed desktop-leak defect: the condensed title bar must never render " <>
               "at or above the detail breakpoint."

      assert block =~ ~r/\.pk-mobile-cta-bar\s*\{\s*display:\s*none;\s*\}/,
             "Sanity check: the mobile CTA bar's own pre-existing hide must still be present " <>
               "in the same block — the two phone-only bars are hidden in exactly one place."
    end
  end

  # G-01.3-09 (UAT gap G-01.3-1 item 7): pins the sticky title-echo bar's
  # separation from the page (a distinct fill token, not the page's own),
  # its measured two-theme text/border contrast, and its shared-width
  # alignment with the rest of the page's capped surfaces. Reuses the
  # whole css_source/0 + dark_theme_plugin_block/0 + token_value/2 +
  # relative_luminance/1 + contrast_ratio/2 harness the lightbox
  # close-button describe block below already established — no second
  # harness is written here. Sits beside "title-echo desktop hide" above,
  # the existing idiom for asserting on this bar's CSS.
  describe "sticky title-echo bar (G-01.3-09, UAT item 7)" do
    # The bar's OWN rule, matched on its literal (unqualified) selector
    # text anchored to the start of a line. `\s*\{` immediately after
    # `.pk-title-echo` means `.pk-title-echo-inner {`, `.pk-title-echo.is-visible {`
    # and `.pk-title-echo.is-parked {` can never be mistaken for it — none
    # of those has whitespace-then-`{` directly following the bare
    # `.pk-title-echo` token.
    defp title_echo_block do
      case Regex.run(~r/(?m)^\.pk-title-echo\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-title-echo {...}` rule found in assets/css/app.css")
      end
    end

    # Same idiom, for the new inner wrapper rule.
    defp title_echo_inner_block do
      case Regex.run(~r/(?m)^\.pk-title-echo-inner\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-title-echo-inner {...}` rule found in assets/css/app.css")
      end
    end

    # light_theme_plugin_block/0 is NOT redeclared here — 01.3-07's own
    # "net-new CSS-source pins" describe block below already defines it
    # (mirroring dark_theme_plugin_block/0), and `defp` scope is the whole
    # module regardless of which describe block textually defines it. A
    # second definition would fail this file's own harness-reuse
    # discipline (see that block's comment).

    test "the bar's own background token is the new base-200 step, not the page's own base-100" do
      body = title_echo_block()

      assert body =~ ~r/background:\s*var\(--color-base-200\)\s*;/,
             "`.pk-title-echo` must declare `background: var(--color-base-200);` — the " <>
               "one-step-darker/tinted rule detail-page-mobile-interaction.md already " <>
               "established for the mobile CTA bar's own background fix, applied here."

      refute body =~ ~r/var\(--color-base-100\)/,
             "`.pk-title-echo` must not read `--color-base-100` anywhere in its own rule — " <>
               "that is the exact same token the page body itself uses, and reusing it is the " <>
               "'doesn't constrain well' defect this round exists to fix."
    end

    test "the bar declares no horizontal --pk-gutter padding of its own — that moved to the inner wrapper" do
      body = title_echo_block()

      refute body =~ ~r/padding:[^;]*--pk-gutter/,
             "`.pk-title-echo` must not declare its own `--pk-gutter`-bearing horizontal " <>
               "padding — that padding now lives on `.pk-title-echo-inner` (via the `pk-gutter` " <>
               "utility class in the markup), on the SAME element as the width cap. Declaring it " <>
               "here too would double-inset the bar's content."

      assert title_echo_inner_block() =~ ~r/display:\s*flex\s*;/,
             "`.pk-title-echo-inner` must declare `display: flex;` — the row layout that used " <>
               "to live on `.pk-title-echo` itself moved here along with the horizontal padding."
    end

    test "text contrast (light theme): the bar's content token against its own base-200 fill meets 4.5:1" do
      block = light_theme_plugin_block()
      content = token_value(block, "--color-base-content")
      fill = token_value(block, "--color-base-200")

      ratio = contrast_ratio(relative_luminance(content), relative_luminance(fill))

      assert ratio >= 4.5,
             "light theme: the sticky bar's text (--color-base-content, #{content}) must " <>
               "contrast at least 4.5:1 (WCAG 1.4.3) against the bar's own fill " <>
               "(--color-base-200, #{fill}). Computed: #{Float.round(ratio, 2)}:1."
    end

    test "text contrast (dark theme): the bar's content token against its own base-200 fill meets 4.5:1" do
      block = dark_theme_plugin_block()
      content = token_value(block, "--color-base-content")
      fill = token_value(block, "--color-base-200")

      ratio = contrast_ratio(relative_luminance(content), relative_luminance(fill))

      assert ratio >= 4.5,
             "dark theme: the sticky bar's text (--color-base-content, #{content}) must " <>
               "contrast at least 4.5:1 (WCAG 1.4.3) against the bar's own fill " <>
               "(--color-base-200, #{fill}). Computed: #{Float.round(ratio, 2)}:1 — a future " <>
               "palette retune that quietly walks either token toward the other must fail here, " <>
               "not ship."
    end

    # The bar's border reads --color-neutral, not --color-base-300 — see
    # .pk-title-echo's own comment in app.css. Measured directly against
    # this file's tokens: --color-base-300 (the plan's original
    # assumption) computes to only 1.41:1 light / 1.23:1 dark against
    # --color-base-100, both far under the 3.0:1 floor these two tests
    # enforce. This is a Rule 1 auto-fix — the base-100/200/300 family is
    # a subtle background-stepping scale by design and cannot clear 3:1
    # against base-100 at any of its three steps in either theme;
    # --color-neutral is the token this codebase already reaches for when
    # a control needs real, measured contrast while staying visually
    # muted (see the lightbox close button's own dark-theme fix, same
    # token, same reasoning, elsewhere in this file).
    test "the bar's border reads --color-neutral, not --color-base-300" do
      body = title_echo_block()

      assert body =~ ~r/border-bottom:\s*1px solid var\(--color-neutral\)\s*;/,
             "`.pk-title-echo` must declare its border-bottom from `--color-neutral`. " <>
               "`--color-base-300` (the plan's original assumption) measures only 1.41:1 " <>
               "light / 1.23:1 dark against `--color-base-100` — nowhere near the 3.0:1 " <>
               "floor the two tests below enforce."

      refute body =~ ~r/var\(--color-base-300\)/,
             "`.pk-title-echo` must not read `--color-base-300` for its border — that token " <>
               "measured under the 3.0:1 floor in both themes; see the test above."
    end

    test "non-text contrast (light theme): the bar's border token against the page background meets 3.0:1" do
      block = light_theme_plugin_block()
      border = token_value(block, "--color-neutral")
      page_bg = token_value(block, "--color-base-100")

      ratio = contrast_ratio(relative_luminance(border), relative_luminance(page_bg))

      assert ratio >= 3.0,
             "light theme: the sticky bar's separating border (--color-neutral, #{border}) " <>
               "must contrast at least 3.0:1 (WCAG 1.4.11's non-text-contrast floor) against " <>
               "the page background it separates from (--color-base-100, #{page_bg}). " <>
               "Computed: #{Float.round(ratio, 2)}:1."
    end

    test "non-text contrast (dark theme): the bar's border token against the page background meets 3.0:1" do
      block = dark_theme_plugin_block()
      border = token_value(block, "--color-neutral")
      page_bg = token_value(block, "--color-base-100")

      ratio = contrast_ratio(relative_luminance(border), relative_luminance(page_bg))

      assert ratio >= 3.0,
             "dark theme: the sticky bar's separating border (--color-neutral, #{border}) " <>
               "must contrast at least 3.0:1 (WCAG 1.4.11's non-text-contrast floor) against " <>
               "the page background it separates from (--color-base-100, #{page_bg}). " <>
               "Computed: #{Float.round(ratio, 2)}:1 — a separator the eye cannot find is the " <>
               "\"doesn't constrain well\" complaint restated numerically."
    end

    test "the inner wrapper shares alignment classes with the masthead and shelf separator",
         %{conn: conn} do
      game = game_fixture(%{name: "Title Echo Alignment Base", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Title Echo Alignment Sibling", weight_band: "descubre_el_hobby"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      shared_classes = MapSet.new(~w(mx-auto w-full max-w-7xl pk-gutter))

      for {label, selector} <- [
            {"the title-echo bar's inner wrapper", "#detail-title-echo > .pk-title-echo-inner"},
            {"the masthead wrapper", "#detail-masthead-wrap"},
            {"the shelf separator", "#detail-shelf-separator"}
          ] do
        class =
          doc
          |> LazyHTML.query(selector)
          |> LazyHTML.attribute("class")
          |> List.first()

        classes = class |> String.split(~r/\s+/, trim: true) |> MapSet.new()

        assert MapSet.subset?(shared_classes, classes),
               "#{label} (#{selector}) must carry all four shared alignment classes " <>
                 "#{inspect(MapSet.to_list(shared_classes))} — found: #{inspect(class)}"
      end
    end

    # 01.3-11 (gap closure G-01.3-5): the title span's OWN rule, matched on
    # its literal (unqualified) selector text anchored to the start of a
    # line — same idiom as title_echo_block/0 and title_echo_inner_block/0
    # above, and the same reason: `.pk-title-echo-name` must never be
    # confused with `.pk-title-echo` or `.pk-title-echo-inner`.
    defp title_echo_name_block do
      case Regex.run(~r/(?m)^\.pk-title-echo-name\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-title-echo-name {...}` rule found in assets/css/app.css")
      end
    end

    test "the title has a deliberate typographic identity — display font, explicit size, explicit color" do
      body = title_echo_name_block()

      assert body =~ ~r/font-family:\s*var\(--font-display\)\s*;/,
             "`.pk-title-echo-name` must declare `font-family: var(--font-display);`. A " <>
               "title-role element that declares no font properties anywhere in its cascade " <>
               "inherits ambient body text by omission, which is not a decision — that was " <>
               "the exact defect G-01.3-5 reported."

      assert body =~ ~r/font-size:\s*1\.25rem\s*;/,
             "`.pk-title-echo-name` must declare an explicit `font-size: 1.25rem;` — the same " <>
               "display-label step `.pk-section-heading` already uses, one step below the " <>
               "real H1's text-3xl."

      assert body =~ ~r/color:\s*var\(--color-base-content\)\s*;/,
             "`.pk-title-echo-name` must declare an explicit `color: var(--color-base-content);` " <>
               "rather than leaving its text color to inherit."
    end

    test "no faux bold — the rule declares weight 400 and no other numeric or keyword weight" do
      body = title_echo_name_block()

      assert body =~ ~r/font-weight:\s*400\s*;/,
             "`.pk-title-echo-name` must declare `font-weight: 400;` explicitly. Bebas Neue is " <>
               "self-hosted at weight 400 ONLY (see the @font-face blocks in assets/css/app.css), " <>
               "so a heavier value here is synthesized by the browser into a faux bold that no " <>
               "build step will ever flag."

      refute body =~ ~r/font-weight:\s*(?!400\s*;)[0-9]+\s*;/,
             "`.pk-title-echo-name` must not declare any numeric font-weight other than 400 — " <>
               "only weight 400 of Bebas Neue is self-hosted."

      refute body =~ ~r/font-weight:\s*(bold|bolder|semibold)\s*;/,
             "`.pk-title-echo-name` must not declare a keyword font-weight (bold/bolder/semibold) " <>
               "— only weight 400 of Bebas Neue is self-hosted; any other value is " <>
               "browser-synthesized and never flagged by a build step."
    end

    test "typography and truncation coexist in the SAME rule" do
      body = title_echo_name_block()

      truncation_hits =
        Regex.scan(
          ~r/min-width:\s*0\s*;|white-space:\s*nowrap\s*;|overflow:\s*hidden\s*;|text-overflow:\s*ellipsis\s*;/,
          body
        )

      assert length(truncation_hits) == 4,
             "`.pk-title-echo-name` must still declare all four truncation properties " <>
               "(min-width: 0, white-space: nowrap, overflow: hidden, text-overflow: ellipsis) " <>
               "in the SAME rule as the new typography declarations. G-01.2-24: a larger font " <>
               "in a flex item that lost `min-width: 0` wraps to a second line — the exact " <>
               "defect that round fixed, and this round makes the text bigger."

      assert body =~ ~r/font-family:\s*var\(--font-display\)/,
             "The typography declarations must live in the SAME `.pk-title-echo-name` rule as " <>
               "the truncation properties above, not a separate/overriding rule."
    end

    test "the deferred scope really is untouched — bar fill, scroll-top fill, and the bounce keyframes" do
      assert title_echo_block() =~ ~r/background:\s*var\(--color-base-200\)\s*;/,
             "`.pk-title-echo`'s fill token must still read `--color-base-200`. 01.3-09 recorded " <>
               "a developer decision (accept-mechanical) to leave the brand-tint question open; " <>
               "this test is what makes 'the typography fix did not quietly answer it' checkable " <>
               "rather than merely asserted in a SUMMARY."

      scroll_top_body =
        case Regex.run(~r/(?m)^\.pk-scroll-top\s*\{([^}]*)\}/s, css_source()) do
          [_, body] -> body
          nil -> flunk("No top-level `.pk-scroll-top {...}` rule found in assets/css/app.css")
        end

      assert scroll_top_body =~ ~r/background:\s*var\(--color-primary\)\s*;/,
             "`.pk-scroll-top`'s fill token must still read `--color-primary` — untouched by " <>
               "this plan, remaining part of the open brand-tint question."

      assert css_source() =~ ~r/(?m)^@keyframes pk-scroll-top-bounce\b/,
             "The `pk-scroll-top-bounce` keyframes must still exist, untouched by this plan."
    end
  end

  # G-01.2-24 task 2: source-level CSS facts for the corrected
  # boundary-collapse footer margin.
  describe "boundary-collapse footer margin (Phase 01.2 gap-closure round 4, G-01.2-24 task 2)" do
    test "the boundary-collapse following-footer rule declares a non-zero top margin" do
      case Regex.run(~r/main\.pk-boundary-collapse \+ \.pk-footer\s*\{([^}]*)\}/, css_source()) do
        [_, body] ->
          refute body =~ ~r/margin-top:\s*0\b/,
                 "A zero top margin here puts the footer's tinted box flush against the " <>
                   "carousel — the exact defect G-01.2-14 was opened for."

          assert body =~ ~r/margin-top:\s*1\.5rem/,
                 "`main.pk-boundary-collapse + .pk-footer` must declare `margin-top: 1.5rem` " <>
                   "(24px), matching the wrapper's own 24px top padding — the real gap this " <>
                   "boundary is aiming at, not a value hidden inside the footer's own padding."

        nil ->
          flunk("No `main.pk-boundary-collapse + .pk-footer { ... }` rule found in app.css")
      end
    end

    # Existing wrapper-top-padding and shelf-margin-cancel facts, kept
    # exactly as the plan requires ("keep any existing assertions").
    test "the boundary-collapse wrapper still declares 1.5rem top padding and cancels the last shelf's trailing margin" do
      assert Regex.match?(
               ~r/main\.pk-boundary-collapse\s*\{[^}]*padding-top:\s*1\.5rem;[^}]*padding-bottom:\s*0;[^}]*\}/s,
               css_source()
             )

      assert Regex.match?(
               ~r/main\.pk-boundary-collapse \.pk-shelf:last-of-type\s*\{[^}]*margin-bottom:\s*0;[^}]*\}/s,
               css_source()
             )
    end
  end

  # G-01.2-25 task 1 (gap-closure round 5), corrected by G-01.2-28 task 1
  # (gap-closure round 6): the lightbox photo's cap-only width fix was a
  # confirmed no-op (a `max-width` can only shrink, never grow, an element
  # already smaller than it), so round 6 replaced the cap with a real
  # `width`/`height`/`background` on `.pk-lightbox-img`, backed by a new
  # `--pk-shell-content-width` token declared once in `:root`. The
  # chevron-stacking tests below predate round 6 and are untouched by it.
  # `css_source/0` is the shared helper the two describe blocks above
  # already established.
  describe "lightbox shell-width photo and chevron stacking (Phase 01.2 gap-closure round 5, G-01.2-25 task 1; round 6, G-01.2-28 task 1)" do
    # First (and only) top-level `.pk-lightbox-img {...}` rule, matched on
    # the literal selector text, mirroring `gallery_dot_block/0`'s pattern
    # above so a future sibling rule can never be mistaken for this one.
    defp lightbox_img_block do
      case Regex.run(~r/(?m)^\.pk-lightbox-img\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-lightbox-img {...}` rule found in assets/css/app.css")
      end
    end

    # The shared token's own `:root` declaration — round 6 moved the shell-
    # width formula here from `.pk-lightbox-img`'s own (now-removed) cap,
    # so the two assertions that used to match against the photo rule's
    # brace body (the container property and the gutter token) now match
    # here instead, per the plan's own instruction to move rather than
    # delete them.
    defp shell_content_width_token_declaration do
      case Regex.run(~r/--pk-shell-content-width:\s*([^;]*);/, css_source()) do
        [_, value] -> value
        nil -> flunk("No `--pk-shell-content-width` token declared in assets/css/app.css")
      end
    end

    test "the shell's content width is named once as a token, reading the container property and the shared gutter" do
      token_value = shell_content_width_token_declaration()

      assert token_value =~ ~r/var\(--container-7xl,\s*80rem\)/,
             "`--pk-shell-content-width` must read Tailwind's own `--container-7xl` custom " <>
               "property (the same one `.max-w-7xl` resolves against, confirmed emitted in the " <>
               "built stylesheet) rather than a hand-copied 80rem literal with no link back to " <>
               "the shell — this is the formula that moved here from `.pk-lightbox-img`'s own " <>
               "cap when the cap was replaced by a real width."

      assert token_value =~ ~r/var\(--pk-gutter\)/,
             "`--pk-shell-content-width` must subtract the shared `--pk-gutter` token (not a " <>
               "hardcoded rem value) so the token — and every rule that reads it — stays in " <>
               "sync with the header/footer/masthead's own content width, including the " <>
               "token's own narrower value below the 480px breakpoint."
    end

    test "the lightbox photo declares a real width and height instead of caps, plus an opaque fill" do
      body = lightbox_img_block()

      refute body =~ ~r/max-width/,
             "`.pk-lightbox-img` must no longer carry a `max-width` at all. A `max-width` can " <>
               "only ever SHRINK an element, never grow one — which is exactly why the previous " <>
               "round's fix (widening this same cap to the shell's width) was a confirmed no-op: " <>
               "every photo in this catalog renders at a fixed ~800px intrinsic size from the " <>
               "seed pipeline, already smaller than any cap this rule has ever carried. Only a " <>
               "real `width` can grow the box past that intrinsic size."

      assert body =~ ~r/width:\s*var\(--pk-shell-content-width\)\s*;/,
             "`.pk-lightbox-img`'s width must be a single bare read of `--pk-shell-content-width` " <>
               "— the token the shell's own container/gutter formula now lives on — with no " <>
               "fallback literal beside it, which would be a second, silently-diverging opinion " <>
               "about where the shell's edge is."

      refute body =~ ~r/max-height/,
             "the vertical cap must become a real `height` (see the next assertions), matching " <>
               "the photo's own new real width — a mix of one real dimension and one capped " <>
               "dimension would leave the box's height still bounded by its own intrinsic size."

      # G-01.2-18 (gap-closure round 7, plan 01.2-29): the previous round's carried-forward
      # `80vh` was itself the bug — `.pk-lightbox` centres rather than stretches its child, so
      # the unclaimed 20% of viewport height rendered as two translucent scrim bands, one above
      # and one below the stage. Round 7 replaces the single `80vh` with this file's own
      # dual-declaration full-viewport idiom (see the superseded-mechanism note above
      # `.pk-gutter` in app.css, where `.pk-app-shell` used to live, for the fuller argument —
      # that class is deleted outright as of 2026-09-02/260902-glf, but its former comment site
      # keeps the idiom documented since two other places, including this one, cite it): the
      # static unit as a fallback, the dynamic-viewport unit immediately after.
      assert body =~ ~r/height:\s*100vh;\s*height:\s*100dvh;/,
             "`.pk-lightbox-img` must declare `height` TWICE, adjacent and in this exact order " <>
               "— the older `100vh` unit immediately followed by the dynamic-viewport `100dvh` " <>
               "unit, with nothing but whitespace between them. This is not a redundant " <>
               "duplicate: the first line is the fallback a browser without `dvh` support keeps, " <>
               "the second is what every current browser actually uses (see the superseded-" <>
               "mechanism note above `.pk-gutter` in app.css, where `.pk-app-shell` used to " <>
               "live, for the fuller argument) — deleting either line silently reintroduces " <>
               "the mobile-toolbar bug this pair exists to prevent."

      height_declarations = Regex.scan(~r/height:\s*[^;]+;/, body)

      assert length(height_declarations) == 2,
             "`.pk-lightbox-img` must declare `height` exactly twice and no third time. CSS " <>
               "takes the LAST declaration of a property, so a stray third `height:` anywhere " <>
               "below the static/dynamic pair would silently restore whatever envelope it names " <>
               "— with both correct lines still sitting above it looking right. Found " <>
               "#{length(height_declarations)}: #{inspect(height_declarations)}"

      assert body =~ ~r/background:\s*var\(--pk-shadow-color\)\s*;/,
             "`.pk-lightbox-img` must declare an OPAQUE fill reading `--pk-shadow-color` " <>
               "directly at full strength — not mixed toward transparency like every other " <>
               "consumer of that token — so the area the photo doesn't cover is a solid stage. " <>
               "A box that merely reaches the shell's width without a fill of its own still lets " <>
               "the page show through exactly as before, which is the reported symptom this " <>
               "round exists to fix."

      assert body =~ ~r/object-fit:\s*contain/,
             "object-fit must stay byte-identical to HEAD"

      assert body =~ ~r/border-radius:\s*var\(--radius-box\)/,
             "border-radius must stay byte-identical to HEAD"

      assert body =~ ~r/box-shadow:\s*0 28px 56px/,
             "the two-layer shadow must stay byte-identical to HEAD"

      assert body =~ ~r/transform:\s*scale\(0\.96\)/,
             "the scale transition must stay byte-identical to HEAD"
    end

    test "the container paints an opaque shadow-token field; the scrim token keeps its value for its sole reader (G-01.2-19)" do
      case Regex.run(~r/--pk-overlay-scrim:\s*([^;]*);/, css_source()) do
        [_, value] ->
          assert value =~ ~r/color-mix\(in srgb, var\(--pk-shadow-color\) 72%, transparent\)/,
                 "`--pk-overlay-scrim` must keep mixing `--pk-shadow-color` at exactly 72% — " <>
                   "the lightbox leaving is a reader moving OFF this token, not a licence to " <>
                   "retune it. After this round the mobile preview sheet's backdrop " <>
                   "(`.pk-sheet-backdrop`) is this token's SOLE reader, so 72% is not merely a " <>
                   "value the two surfaces happened to share anymore — it is the only thing the " <>
                   "token exists for, and it is still exactly right there, since that sheet is " <>
                   "meant to be seen through."

        nil ->
          flunk("No `--pk-overlay-scrim` token found in assets/css/app.css")
      end

      case Regex.run(~r/(?m)^\.pk-lightbox\s*\{([^}]*)\}/s, css_source()) do
        [_, body] ->
          assert body =~ ~r/background:\s*var\(--pk-shadow-color\)\s*;/,
                 "`.pk-lightbox` must declare a bare, full-strength read of `--pk-shadow-color` " <>
                   "for its own background, with no `color-mix()` wrapper. This element is a " <>
                   "full-inset fixed overlay (`position: fixed; inset: 0`) that has ALWAYS " <>
                   "covered the whole viewport, so what showed around the stage was never " <>
                   "uncovered page — it was this element's own translucent paint compositing " <>
                   "over the page beneath it. A translucent paint on a full-coverage box is a " <>
                   "coverage bug that no amount of resizing the CHILD can fix."

          refute body =~ ~r/--pk-overlay-scrim/,
                 "`.pk-lightbox` must no longer read `--pk-overlay-scrim` at all. A revert to " <>
                   "the translucent value silently reintroduces the exact band the screenshots " <>
                   "showed — roughly 37% of a 1920px window exposed laterally, a thin sliver at " <>
                   "390px — and this refutation is what makes that revert fail loudly instead of " <>
                   "quietly reproducing it."

        nil ->
          flunk("No top-level `.pk-lightbox { ... }` rule found in assets/css/app.css")
      end

      case Regex.run(~r/(?m)^\.pk-sheet-backdrop\s*\{([^}]*)\}/s, css_source()) do
        [_, body] ->
          assert body =~ ~r/background:\s*var\(--pk-overlay-scrim\)\s*;/,
                 "`.pk-sheet-backdrop` must still read `--pk-overlay-scrim` for its own " <>
                   "background. The token is not deleted because this sheet still needs it, and " <>
                   "the sheet itself is not changed because nobody reported it — a frozen value " <>
                   "with no live reader would be dead code, and this is the pairing that proves " <>
                   "it is not."

        nil ->
          flunk("No top-level `.pk-sheet-backdrop { ... }` rule found in assets/css/app.css")
      end
    end

    test "the container and stage backgrounds are the identical string (G-01.2-19)" do
      container_body =
        case Regex.run(~r/(?m)^\.pk-lightbox\s*\{([^}]*)\}/s, css_source()) do
          [_, body] -> body
          nil -> flunk("No top-level `.pk-lightbox { ... }` rule found in assets/css/app.css")
        end

      stage_body = lightbox_img_block()

      container_bg =
        case Regex.run(~r/background:\s*([^;]+);/, container_body) do
          [_, value] -> String.trim(value)
          nil -> flunk("No `background` declaration found in `.pk-lightbox`")
        end

      stage_bg =
        case Regex.run(~r/background:\s*([^;]+);/, stage_body) do
          [_, value] -> String.trim(value)
          nil -> flunk("No `background` declaration found in `.pk-lightbox-img`")
        end

      assert container_bg == stage_bg,
             "`.pk-lightbox`'s background (#{inspect(container_bg)}) and " <>
               "`.pk-lightbox-img`'s background (#{inspect(stage_bg)}) must be the EQUAL " <>
               "string, not merely two values that both happen to match a pattern. A future " <>
               "edit that gives the container its own slightly different dark reintroduces the " <>
               "identical band a few percent fainter — exactly the class of defect that took " <>
               "three UAT rounds to pin down the first time."
    end

    test "both lightbox chevrons carry the shared class, their own side class, and kept their event bindings",
         %{conn: conn} do
      game =
        game_fixture(%{
          cover_url: "https://images.test.invalid/games/1/cover.webp",
          gallery_urls: ["https://images.test.invalid/games/1/gallery-1.webp"]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      prev = LazyHTML.query(doc, "#detail-lightbox [data-lightbox-prev]")
      next = LazyHTML.query(doc, "#detail-lightbox [data-lightbox-next]")

      assert prev != [],
             "must find an element carrying `data-lightbox-prev` — the attribute the " <>
               "keyboard handler's ArrowLeft branch queries by"

      assert next != [],
             "must find an element carrying `data-lightbox-next` — the attribute the " <>
               "keyboard handler's ArrowRight branch queries by"

      prev_class = prev |> LazyHTML.attribute("class") |> List.first()
      next_class = next |> LazyHTML.attribute("class") |> List.first()

      assert prev_class =~ "pk-lightbox-chevron",
             "the previous-image chevron must carry the shared stacking-order class — this is " <>
               "the one that was rendering invisible behind the photo at mobile widths"

      assert next_class =~ "pk-lightbox-chevron",
             "the next-image chevron must ALSO carry the shared class, not only the " <>
               "previously-broken one, so a future markup reorder can never silently " <>
               "reintroduce the DOM-order accident on this side instead"

      assert prev_class =~ "pk-lightbox-chevron-prev",
             "the previous-image chevron must carry its own `pk-lightbox-chevron-prev` side " <>
               "class (G-01.2-28 task 2) — the shared class and the side class are one " <>
               "contract, and splitting them across two tests would invite someone to " <>
               "satisfy one and drop the other."

      assert next_class =~ "pk-lightbox-chevron-next",
             "the next-image chevron must ALSO carry its own `pk-lightbox-chevron-next` " <>
               "side class."

      # Positional-edit guard: the class-attribute rewrite must not have taken an
      # adjacent binding with it — cheaper and more precise than reading a diff.
      assert prev |> LazyHTML.attribute("phx-click") |> List.first() == "select-lightbox-image",
             "the previous chevron's class rewrite must not have taken its click event with it"

      assert next |> LazyHTML.attribute("phx-click") |> List.first() == "select-lightbox-image",
             "the next chevron's class rewrite must not have taken its click event with it"

      prev_url = prev |> LazyHTML.attribute("phx-value-url") |> List.first()
      next_url = next |> LazyHTML.attribute("phx-value-url") |> List.first()

      assert prev_url not in [nil, ""],
             "the previous chevron must still carry a non-empty neighbour URL"

      assert next_url not in [nil, ""],
             "the next chevron must still carry a non-empty neighbour URL"

      assert prev |> LazyHTML.attribute("aria-label") |> List.first() == "Imagen anterior",
             "the previous chevron must keep its accessible label"

      assert next |> LazyHTML.attribute("aria-label") |> List.first() == "Imagen siguiente",
             "the next chevron must keep its accessible label"
    end

    test "each lightbox chevron's side rule sets its own horizontal inset from the shared shell-width token" do
      for {side, prop} <- [{"prev", "left"}, {"next", "right"}] do
        body =
          case Regex.run(~r/(?m)^\.pk-lightbox-chevron-#{side}\s*\{([^}]*)\}/s, css_source()) do
            [_, body] ->
              body

            nil ->
              flunk("No top-level `.pk-lightbox-chevron-#{side} {...}` rule found in assets/css/app.css")
          end

        assert body =~
                 ~r/#{prop}:\s*calc\(50% - \(var\(--pk-shell-content-width\) \/ 2\)\)\s*;/,
               "`.pk-lightbox-chevron-#{side}` must set `#{prop}` to a calculation reading " <>
                 "`--pk-shell-content-width` directly, with no fallback literal beside it — " <>
                 "`.pk-lightbox` is `position: fixed; inset: 0` (the full viewport), so it is " <>
                 "the containing block this button resolves against, and a bare length here " <>
                 "anchors the button to the BROWSER's edge no matter what the photo is doing, " <>
                 "which is exactly the anchoring the user rejected in two consecutive UAT " <>
                 "rounds (tests 12 and 17)."
      end
    end

    test "the .pk-lightbox-chevron class declares an explicit numeric z-index above the photo" do
      case Regex.run(~r/(?m)^\.pk-lightbox-chevron\s*\{([^}]*)\}/, css_source()) do
        [_, body] ->
          assert body =~ ~r/z-index:\s*\d/,
                 "`.pk-lightbox-chevron` must declare an explicit numeric z-index so both " <>
                   "chevrons outrank the photo regardless of DOM order — relying on " <>
                   "`z-index: auto` and markup order is the confirmed root cause of the " <>
                   "mobile left-chevron-behind-the-image defect."

        nil ->
          flunk("No `.pk-lightbox-chevron { ... }` rule found in assets/css/app.css")
      end
    end
  end

  # G-01.2-20, plan 01.2-30 (gap-closure round 8): the lightbox close button
  # inherits daisyUI's unmodified `.btn` fill (`--color-base-200`) because it
  # carries no colour modifier class. That default measures fine in light
  # theme (near-white against the fixed dark `--pk-shadow-color` backdrop)
  # but ~1.1:1 in dark theme (a very dark purple against a near-identical
  # dark backdrop) — UAT test 20's "On the dark needs a little more
  # constrant." This describe block guards the dark-theme-only fix: a rule
  # scoped to `[data-theme="dark"]` sets `--btn-color`/`--btn-fg` from the
  # neutral token pair, `.pk-lightbox-close`'s own rule stays untouched
  # (pinned exhaustively, not by a negative check, since an unscoped fill
  # added there would silently drag light theme along), and the resulting
  # contrast is MEASURED from the file's own tokens rather than string-
  # matched, so a future palette retune that walks `--color-neutral` back
  # toward the backdrop fails the suite instead of shipping quietly.
  describe "lightbox close button dark-theme contrast (Phase 01.2 gap-closure round 8, G-01.2-20, plan 01.2-30)" do
    # The dark-scoped rule, matched on its literal selector text at the
    # start of a line — mirrors `lightbox_img_block/0`'s idiom above so a
    # future sibling rule (e.g. a light-theme variant) can never be mistaken
    # for this one. `.pk-lightbox-close`'s OWN rule (no `[data-theme=...]`
    # prefix) cannot match this pattern, since `^` anchors to the start of
    # the selector text.
    defp dark_lightbox_close_block do
      case Regex.run(
             ~r/(?m)^\[data-theme="dark"\] \.pk-lightbox-close\s*\{([^}]*)\}/s,
             css_source()
           ) do
        [_, body] -> body
        nil -> flunk("No top-level `[data-theme=\"dark\"] .pk-lightbox-close {...}` rule found in assets/css/app.css")
      end
    end

    # `.pk-lightbox-close`'s own (unscoped) rule — same idiom, matched on its
    # bare selector so it is never confused with the dark-scoped rule above.
    defp lightbox_close_own_block do
      case Regex.run(~r/(?m)^\.pk-lightbox-close\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-lightbox-close {...}` rule found in assets/css/app.css")
      end
    end

    # Pulls the dark theme's own `@plugin "daisyui-theme"` block (`name:
    # "dark"`) so a token lookup can be scoped to it — reading a token name
    # against the whole file would silently return LIGHT theme's value if
    # light theme's block happened to be matched first.
    defp dark_theme_plugin_block do
      case Regex.run(
             ~r/@plugin "daisyui\/packages\/bundle\/daisyui-theme" \{\s*name: "dark";(.*?)\n\}/ms,
             css_source()
           ) do
        [_, body] -> body
        nil -> flunk("No dark-theme `@plugin \"daisyui-theme\"` block found in assets/css/app.css")
      end
    end

    # Pulls the `:root[data-theme="dark"]` rule (quick task 260910-hdc) so
    # token_value/2 can read `--pk-ink-brand`'s dark declaration out of it —
    # same scoping reason as dark_theme_plugin_block/0 above: this token is
    # ALSO declared under plain `:root` (light, a variable read of
    # `--color-primary`), so reading the token name against the whole file
    # would risk matching the wrong scope.
    defp dark_pk_ink_brand_root_block do
      case Regex.run(~r/:root\[data-theme="dark"\]\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No `:root[data-theme=\"dark\"] { ... }` rule found in assets/css/app.css")
      end
    end

    # Pulls the single plain `:root { ... }` block that declares at least
    # one `--pk-ramp-*` stop (quick task 260910-l7q, Task 1 tracer) —
    # disambiguated from the file's OTHER plain `:root { ... }` block (the
    # one carrying `--pk-ink-brand`, see dark_pk_ink_brand_root_block/0's
    # sibling above) by CONTENT rather than by match order, the same idiom
    # `oklch-audit.mjs`'s `parsePlainRootPkInkBrand` already uses.
    defp ramp_root_block do
      css_source()
      |> then(&Regex.scan(~r/(?m)^:root\s*\{([^}]*)\}/, &1, capture: :all_but_first))
      |> List.flatten()
      |> Enum.find(&(&1 =~ ~r/--pk-ramp-/))
      |> case do
        nil -> flunk("No plain `:root { ... }` block declaring a `--pk-ramp-` stop found in assets/css/app.css")
        body -> body
      end
    end

    defp token_value(source, token) do
      case Regex.run(~r/#{Regex.escape(token)}:\s*([^;]*);/, source) do
        [_, value] -> value |> String.trim() |> deref_ramp_value()
        nil -> flunk("No `#{token}` token found in the given source")
      end
    end

    # One-hop dereference (quick task 260910-l7q, Task 1 tracer):
    # `token_value/2` is the single choke point ~30 existing colour
    # assertions already funnel through, so teaching the dereference here
    # keeps every call site working unedited. Only a value that IS a
    # `var()` read of a `--pk-ramp-` stop is dereferenced; every other value
    # (hex literals, the `rgb(...)` triple `--pk-shadow-color` carries)
    # passes through untouched. An unresolvable stop is a hard failure
    # (`flunk`), never a silent pass-through of the raw `var(...)` string —
    # that would turn every colour comparison funnelled through here into a
    # string compare that happens to pass for the wrong reason (see the
    # plan's threat model, T-l7q-01).
    defp deref_ramp_value(value) do
      case Regex.run(~r/^var\((--pk-ramp-[0-9]+)\)$/, value) do
        [_, stop] ->
          case Regex.run(~r/#{Regex.escape(stop)}:\s*([^;]*);/, ramp_root_block()) do
            [_, resolved] ->
              String.trim(resolved)

            nil ->
              flunk(
                "Could not resolve `#{stop}` (referenced via `#{value}`) in the --pk-ramp-* " <>
                  "root block — a role points at a ramp stop that does not exist."
              )
          end

        nil ->
          value
      end
    end

    # Turns a colour written either as a six-digit hex literal or as a
    # space-separated `rgb(r g b)` triple (this file's two colour formats)
    # into an {r, g, b} 0-255 integer triple. Shared by relative_luminance/1
    # (WCAG contrast) and oklab/1 (quick task 260910-hdc, OKLCh chroma/hue) —
    # both need the same raw channels, just different downstream math.
    defp parse_rgb(color) do
      case Regex.run(~r/^#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/, String.trim(color)) do
        [_, r, g, b] ->
          {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}

        nil ->
          case Regex.run(~r/rgb\(\s*(\d+)\s+(\d+)\s+(\d+)\s*\)/, color) do
            [_, r, g, b] -> {String.to_integer(r), String.to_integer(g), String.to_integer(b)}
            nil -> flunk("Could not parse colour value for contrast computation: #{inspect(color)}")
          end
      end
    end

    # sRGB (0-255) -> linear-light single channel, the standard EOTF used by
    # both the WCAG relative-luminance formula and the OKLab conversion.
    defp srgb_channel_to_linear(channel) do
      c = channel / 255
      if c <= 0.03928, do: c / 12.92, else: :math.pow((c + 0.055) / 1.055, 2.4)
    end

    # Turns a colour into a WCAG relative luminance.
    defp relative_luminance(color) do
      {r, g, b} = parse_rgb(color)

      [r, g, b]
      |> Enum.map(&srgb_channel_to_linear/1)
      |> then(fn [rl, gl, bl] -> 0.2126 * rl + 0.7152 * gl + 0.0722 * bl end)
    end

    # Turns two relative luminances into a WCAG contrast ratio.
    defp contrast_ratio(l1, l2) do
      {lighter, darker} = if l1 >= l2, do: {l1, l2}, else: {l2, l1}
      (lighter + 0.05) / (darker + 0.05)
    end

    # sRGB -> linear -> OKLab (Björn Ottosson's published matrices — the
    # same conversion this plan's `measured_root_cause` table and
    # `contrast-check.mjs`'s methodology comment cite). Returns {l, a, b} in
    # OKLab space; oklch_chroma/1 and oklch_hue/1 below derive the polar
    # (chroma, hue) form from it. Added for quick task 260910-hdc: the
    # tripwire that encodes "reads as brand purple, not disabled grey" is a
    # CHROMA floor, which relative_luminance/1's WCAG math cannot express.
    defp oklab(color) do
      {r, g, b} = parse_rgb(color)
      [rl, gl, bl] = Enum.map([r, g, b], &srgb_channel_to_linear/1)

      l = 0.4122214708 * rl + 0.5363325363 * gl + 0.0514459929 * bl
      m = 0.2119034982 * rl + 0.6806995451 * gl + 0.1073969566 * bl
      s = 0.0883024619 * rl + 0.2817188376 * gl + 0.6299787005 * bl

      cbrt = fn v -> if v < 0, do: -:math.pow(-v, 1 / 3), else: :math.pow(v, 1 / 3) end
      l_ = cbrt.(l)
      m_ = cbrt.(m)
      s_ = cbrt.(s)

      lab_l = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
      lab_a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
      lab_b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

      {lab_l, lab_a, lab_b}
    end

    # OKLCh chroma magnitude — "how saturated", the axis this task's fix
    # actually turns on (a contrast-only fix can pass WCAG while still
    # reading as grey; chroma is what distinguishes "brand purple" from
    # "disabled grey" at the same lightness/contrast).
    defp oklch_chroma(color) do
      {_l, a, b} = oklab(color)
      :math.sqrt(a * a + b * b)
    end

    # OKLCh hue angle in degrees [0, 360) — the axis "one hue, three chroma
    # tiers" (this task's stated goal) is actually about.
    defp oklch_hue(color) do
      {_l, a, b} = oklab(color)
      degrees = :math.atan2(b, a) * 180 / :math.pi()
      if degrees < 0, do: degrees + 360, else: degrees
    end

    test "the dark-theme rule sets --btn-color and --btn-fg from the neutral token pair, no literal colour" do
      body = dark_lightbox_close_block()

      assert body =~ ~r/--btn-color:\s*var\(--color-neutral\)\s*;/,
             "`[data-theme=\"dark\"] .pk-lightbox-close` must set `--btn-color` to a read of " <>
               "`--color-neutral` — daisyUI's `.btn` resolves its fill from `--btn-color` (falling " <>
               "back to `--color-base-200` when unset), so this is what gives the button an " <>
               "explicit, measured fill in dark theme instead of the unmodified default."

      assert body =~ ~r/--btn-fg:\s*var\(--color-neutral-content\)\s*;/,
             "`[data-theme=\"dark\"] .pk-lightbox-close` must ALSO set `--btn-fg` to a read of " <>
               "`--color-neutral-content`. daisyUI's base `.btn` rule sets `--btn-fg: " <>
               "var(--color-base-content)` INDEPENDENTLY of `--btn-bg`/`--btn-color` — see " <>
               "`.btn-neutral` in deps/daisyui/packages/bundle/daisyui.mjs, which sets BOTH " <>
               "`--btn-color` and `--btn-fg` together, never one alone. A rule that changed only " <>
               "the fill would leave the icon at `--color-base-content` (near-white in dark " <>
               "theme) on the new light-lavender chip — a second, freshly-introduced contrast " <>
               "bug of the same family as the one this round exists to fix."
    end

    test "pk-lightbox-close's own rule declares exactly its four original properties, in order, and no fifth" do
      body = lightbox_close_own_block()

      properties =
        ~r/([a-z-]+):/
        |> Regex.scan(body)
        |> Enum.map(fn [_, prop] -> prop end)

      assert properties == ["position", "top", "right", "z-index"],
             "`.pk-lightbox-close` must declare EXACTLY these four properties, in this exact " <>
               "order, and no fifth. This is an EXHAUSTIVE positive assertion rather than a " <>
               "negative 'does not contain a fill' check — a negative check would still pass a " <>
               "rule that had grown some OTHER unscoped visual property, which is the whole " <>
               "failure mode this round guards against: the button's own rule must stay neutral " <>
               "so light theme (already correct, already signed off) cannot be dragged along by " <>
               "a fix meant to be dark-only. This rule's anchoring (position/top/right) is a " <>
               "recorded decision that BOTH round 6 (01.2-28) and round 7 (01.2-29) were " <>
               "explicitly prohibited from reopening. Found: #{inspect(properties)}"
    end

    test "the dark-theme fill and its icon colour meet WCAG contrast floors, computed from this file's own tokens" do
      dark_block = dark_theme_plugin_block()

      neutral = token_value(dark_block, "--color-neutral")
      neutral_content = token_value(dark_block, "--color-neutral-content")
      shadow_color = token_value(css_source(), "--pk-shadow-color")

      fill_ratio = contrast_ratio(relative_luminance(neutral), relative_luminance(shadow_color))
      content_ratio = contrast_ratio(relative_luminance(neutral_content), relative_luminance(neutral))

      assert fill_ratio >= 3.0,
             "The close button's dark-theme fill (`--color-neutral`, #{neutral}) must contrast " <>
               "at least 3.0:1 (WCAG 1.4.11's non-text-contrast floor) against `--pk-shadow-color` " <>
               "(#{shadow_color}) — the fixed literal both the lightbox scrim and the opaque " <>
               "stage are built from. Computed: #{Float.round(fill_ratio, 2)}:1. The failing pair " <>
               "this round replaces — dark-theme `--color-base-200` (#22103A) against the same " <>
               "backdrop — computed to approximately 1.1:1, a perfectly well-formed pair of token " <>
               "reads that was simply the wrong pair; a future palette retune that quietly walks " <>
               "`--color-neutral` back down toward that surface must fail here, not ship."

      assert content_ratio >= 4.5,
             "The icon's dark-theme colour (`--color-neutral-content`, #{neutral_content}) must " <>
               "contrast at least 4.5:1 (WCAG 1.4.3) against its own new fill (`--color-neutral`, " <>
               "#{neutral}) — the fix must not trade an invisible chip for an invisible glyph. " <>
               "Computed: #{Float.round(content_ratio, 2)}:1."
    end
  end

  # G-01.2-21, plan 01.2-32 (gap-closure round 10): round 8 (G-01.2-20/01.2-30) gave
  # `.pk-lightbox-close` a dark-theme fill because daisyUI's unmodified `.btn` default
  # measured ~1.1:1 against the lightbox's fixed dark backdrop. It deliberately left the
  # chevrons alone, on the stated grounds that they "passed UAT test 21 in both themes on
  # this same stage." That test ran while `.pk-lightbox` was still a translucent scrim.
  # Round 9 (G-01.2-19/01.2-31) then made that field fully opaque, string-identical to the
  # photo stage — the exact condition that made the close button's default fill invisible
  # in dark theme, now unchanged for the chevrons too. This describe block guards the
  # completion of round 8's fix across the whole control set: the chevrons get the SAME
  # two declarations the close button already has, through the shared class both already
  # carry, and a new test asserts the two dark-scoped rules' declaration SETS are equal —
  # so the family is enforced as a relationship, not as two independently-correct rules
  # that happen to agree today.
  describe "lightbox chevron dark-theme contrast, consistent with the close button (Phase 01.2 gap-closure round 10, G-01.2-21, plan 01.2-32)" do
    # The new dark-scoped chevron rule, matched on its literal selector text at the start
    # of a line — mirrors `dark_lightbox_close_block/0`'s idiom directly above so this rule
    # can never be mistaken for `.pk-lightbox-close`'s or `.pk-lightbox-chevron`'s own.
    defp dark_lightbox_chevron_block do
      case Regex.run(
             ~r/(?m)^\[data-theme="dark"\] \.pk-lightbox-chevron\s*\{([^}]*)\}/s,
             css_source()
           ) do
        [_, body] -> body
        nil -> flunk("No top-level `[data-theme=\"dark\"] .pk-lightbox-chevron {...}` rule found in assets/css/app.css")
      end
    end

    # `.pk-lightbox-chevron`'s own (unscoped, shared) rule — anchored at the start of a
    # line and requiring the brace to follow immediately after "chevron", so it can never
    # match `.pk-lightbox-chevron-prev`/`-next`'s rules, which have a dash right after the
    # same substring.
    defp lightbox_chevron_shared_block do
      case Regex.run(~r/(?m)^\.pk-lightbox-chevron\s*\{([^}]*)\}/, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-lightbox-chevron {...}` rule found in assets/css/app.css")
      end
    end

    # `.pk-lightbox-chevron-prev`/`-next`'s own per-side rule.
    defp lightbox_chevron_side_block(side) do
      case Regex.run(~r/(?m)^\.pk-lightbox-chevron-#{side}\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-lightbox-chevron-#{side} {...}` rule found in assets/css/app.css")
      end
    end

    # Turns a brace body into a sorted list of {property, value} pairs, whitespace-
    # normalised on the value side. Used only by the consistency-gate test below, which
    # compares two rules' declarations to each other rather than to a fixed string — a
    # rule declaring the same two PROPERTIES with two DIFFERENT tokens would be exactly
    # the inconsistency this test exists to catch, so property names alone are not enough.
    defp declaration_pairs(body) do
      body
      |> String.split(";")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(fn decl ->
        [prop, value] = String.split(decl, ":", parts: 2)
        {String.trim(prop), value |> String.trim() |> String.replace(~r/\s+/, " ")}
      end)
      |> Enum.sort()
    end

    test "the dark-theme chevron rule sets --btn-color and --btn-fg from the neutral token pair, no literal colour" do
      body = dark_lightbox_chevron_block()

      assert body =~ ~r/--btn-color:\s*var\(--color-neutral\)\s*;/,
             "`[data-theme=\"dark\"] .pk-lightbox-chevron` must set `--btn-color` to a read of " <>
               "`--color-neutral` — daisyUI's `.btn` resolves its fill from `--btn-color` " <>
               "(falling back to `--color-base-200` when unset), so this is what gives both " <>
               "chevrons an explicit, measured fill in dark theme instead of the unmodified " <>
               "default they currently inherit."

      assert body =~ ~r/--btn-fg:\s*var\(--color-neutral-content\)\s*;/,
             "`[data-theme=\"dark\"] .pk-lightbox-chevron` must ALSO set `--btn-fg` to a read " <>
               "of `--color-neutral-content`. daisyUI's base `.btn` rule sets `--btn-fg: " <>
               "var(--color-base-content)` INDEPENDENTLY of `--btn-bg`/`--btn-color` — see " <>
               "`.btn-neutral` in deps/daisyui/packages/bundle/daisyui.mjs, which sets BOTH " <>
               "`--btn-color` and `--btn-fg` together, never one alone. A rule that changed " <>
               "only the fill would leave each chevron's icon at `--color-base-content` " <>
               "(near-white in dark theme) on the new light-lavender chip — roughly 1.9:1, " <>
               "moving the invisibility from the chip to the glyph on two controls this time. " <>
               "This is the SECOND time this exact trap is documented in this file's tests (the " <>
               "close button's own test above states it too); it is restated here rather than " <>
               "cross-referenced because a failure message is read at the moment of failure, " <>
               "not followed as a link."
    end

    test "the dark-theme chevron rule's declarations equal the dark-theme close button rule's declarations" do
      chevron_pairs = declaration_pairs(dark_lightbox_chevron_block())
      close_pairs = declaration_pairs(dark_lightbox_close_block())

      assert chevron_pairs == close_pairs,
             "The dark-scoped chevron rule and the dark-scoped close-button rule must declare " <>
               "the SAME SET of property/value pairs — property names AND values, whitespace-" <>
               "normalised, not just matching property names. These three controls are markup-" <>
               "identical daisyUI circular buttons sitting on one backdrop, and the user has " <>
               "now reported TWICE that they must read as one family — once as \"the close " <>
               "button needs more contrast\" and once, after only the close button was fixed, " <>
               "as \"the close button and the rest of controls must be consistent.\" Two " <>
               "independently-correct rules that happen to agree today are not a family; a " <>
               "family is a rule that fails when they stop agreeing. If a future round " <>
               "genuinely needs the chevrons treated differently from the close button, that " <>
               "is a design decision that must be made deliberately and recorded — deleting " <>
               "this assertion is the correct way to make it. Chevron declared: " <>
               "#{inspect(chevron_pairs)}. Close button declared: #{inspect(close_pairs)}."
    end

    test "the three unscoped chevron rules still declare exactly their stacking order and their own horizontal inset" do
      shared_props =
        ~r/([a-z-]+):/
        |> Regex.scan(lightbox_chevron_shared_block())
        |> Enum.map(fn [_, prop] -> prop end)

      assert shared_props == ["z-index"],
             "`.pk-lightbox-chevron` must declare EXACTLY `z-index` and no other property. " <>
               "This is an EXHAUSTIVE positive assertion, not a negative \"contains no fill\" " <>
               "check — a negative check would still pass a rule that had grown some OTHER " <>
               "unscoped visual property, and unscoped is the failure mode that matters here " <>
               "because it would repaint light theme too. This stacking order is a recorded " <>
               "decision (G-01.2-25, the fix for a chevron painting behind the photo) and is " <>
               "not this round's to touch. Found: #{inspect(shared_props)}"

      for {side, prop} <- [{"prev", "left"}, {"next", "right"}] do
        properties =
          ~r/([a-z-]+):/
          |> Regex.scan(lightbox_chevron_side_block(side))
          |> Enum.map(fn [_, p] -> p end)

        assert properties == [prop],
               "`.pk-lightbox-chevron-#{side}` must declare EXACTLY `#{prop}` and no other " <>
                 "property. This horizontal inset is the shell-width alignment the user asked " <>
                 "for across two separate UAT rounds (01.2-28 task 2) and is not this round's " <>
                 "to touch. Found: #{inspect(properties)}"
      end
    end
  end

  # G-01.2-26 task 2 (gap-closure round 3, UAT gap G-01.2-15): the one base
  # pill representation + its variants. This test is the structural defence
  # against the exact drift that broke the pill rhythm three separate times
  # before this consolidation — a tone variant quietly growing a geometry
  # declaration (radius/padding/font-size) that belongs on the base alone.
  describe "pill system tone-variant geometry gate (Phase 01.2 gap-closure round 3, G-01.2-26 task 2)" do
    @tone_variants ~w(pk-pill-neutral pk-pill-accent pk-pill-outline pk-pill-selected)

    test "no pk-pill tone variant declares border-radius, padding, or font-size — those three properties live on the base alone" do
      src = css_source()

      for tone <- @tone_variants do
        case Regex.run(~r/(?m)^\.#{tone}\s*\{([^}]*)\}/s, src) do
          [_, body] ->
            refute body =~ ~r/border-radius/,
                   "`.#{tone}` must not declare border-radius — shape lives on `.pk-pill` " <>
                     "alone. A tone variant re-declaring geometry is the exact drift that broke " <>
                     "the pill rhythm three separate times before this consolidation (G-01.2-15)."

            refute body =~ ~r/padding/,
                   "`.#{tone}` must not declare padding — padding lives on `.pk-pill` (the " <>
                     "dense default) or a size variant, never on a tone."

            refute body =~ ~r/font-size/,
                   "`.#{tone}` must not declare font-size — type size lives on `.pk-pill` or a " <>
                     "size variant, never on a tone."

          nil ->
            flunk("No top-level `.#{tone} { ... }` rule found in assets/css/app.css")
        end
      end
    end
  end

  # quick 260912-rwv (WINDOWS #18): debug session creator-pill-touch-target
  # diagnosed that every tappable pill composing `pk-pill-interactive`
  # (creator pills, Mecánicas/Temáticas links, masthead facts-row links,
  # editorial hashtag links) rendered 26.5px tall (hashtags 23px) — under
  # this project's 44px touch-target minimum — because the base `.pk-pill`'s
  # dense geometry has no height floor and `.pk-pill-interactive` (c33e7f1)
  # never carried one either, unlike the two call sites that happened to
  # append a per-call-site `min-h-11` utility. rwv's fix drew the whole 44px
  # floor as the pill's own visible box (`min-height: 44px` directly on
  # `.pk-pill-interactive`).
  #
  # quick 260913-1s5: the user then reported the tappable filter pills as
  # too big/rough, breaking the page's balance — this is that visual
  # acceptance (rwv's own SUMMARY explicitly left it unreviewed) coming back
  # negative. Fix: the 44px floor moves OFF the drawn box and onto an
  # invisible, vertical-only `::after` hit layer on the same variant — the
  # pill itself draws a compact 28px (dense) / 32px (comfortable) box, but
  # still accepts a tap across the full 44px band. Row gaps for every
  # tappable-pill row are sized so a later row's invisible layer can never
  # cover an earlier row's visible pill (the tap-hijack failure mode this
  # repo already rejected once for the description toggle — see
  # `.pk-desc-shell`'s own CSS comment, 01.3-10).
  describe "pill system interactive touch-target floor — compact visual floor + 44px hit layer, quick 260913-1s5" do
    # `\s*\{` immediately after `pk-pill-interactive` means
    # `.pk-pill-interactive:hover {` can never be mistaken for this rule —
    # `:` follows immediately with no intervening whitespace, so the anchor
    # never matches at that position. Same idiom as the tone-variant gate
    # and title_echo_block/0 above.
    defp pk_pill_interactive_block do
      case Regex.run(~r/(?m)^\.pk-pill-interactive\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-pill-interactive { ... }` rule found in assets/css/app.css")
      end
    end

    # `::after` immediately follows the selector name — distinct anchor from
    # `pk_pill_interactive_block/0` above, never matches the base rule.
    defp pk_pill_interactive_after_block do
      case Regex.run(~r/(?m)^\.pk-pill-interactive::after\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-pill-interactive::after { ... }` rule found in assets/css/app.css")
      end
    end

    defp pk_pill_comfortable_interactive_block do
      case Regex.run(~r/(?m)^\.pk-pill-comfortable\.pk-pill-interactive\s*\{([^}]*)\}/s, css_source()) do
        [_, body] ->
          body

        nil ->
          flunk(
            "No top-level `.pk-pill-comfortable.pk-pill-interactive { ... }` compound rule found in assets/css/app.css"
          )
      end
    end

    defp pk_pill_base_block do
      case Regex.run(~r/(?m)^\.pk-pill\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-pill { ... }` rule found in assets/css/app.css")
      end
    end

    defp pk_pill_tag_block do
      case Regex.run(~r/(?m)^\.pk-pill-tag\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-pill-tag { ... }` rule found in assets/css/app.css")
      end
    end

    defp pk_poster_panel_facts_row_block do
      case Regex.run(~r/(?m)^\.pk-poster-panel > \.pk-facts-row\s*\{([^}]*)\}/s, css_source()) do
        [_, body] -> body
        nil -> flunk("No top-level `.pk-poster-panel > .pk-facts-row { ... }` rule found in assets/css/app.css")
      end
    end

    test "the top-level .pk-pill-interactive rule declares a 28px compact visual floor (not the old 44px) plus position: relative" do
      body = pk_pill_interactive_block()

      assert body =~ ~r/min-height:\s*28px\s*;/,
             "`.pk-pill-interactive` must declare `min-height: 28px;` — the compact visual floor " <>
               "(quick 260913-1s5) that replaces rwv's 44px DRAWN box; the 44px touch target now " <>
               "comes from the `::after` hit layer instead."

      refute body =~ ~r/min-height:\s*44px\s*;/,
             "`.pk-pill-interactive` must no longer draw a 44px box directly — that is exactly " <>
               "the 'too big/rough' visual regression this task fixes; 44px must live on the " <>
               "`::after` hit layer only."

      assert body =~ ~r/position:\s*relative\s*;/,
             "`.pk-pill-interactive` must declare `position: relative;` so its `::after` hit " <>
               "layer's absolute top/bottom percentages resolve against the pill's own box, not " <>
               "some ancestor's."
    end

    test "the interactive variant's drawn box adds only a height floor — no fixed height, max-height, width, padding, or font-size" do
      body = pk_pill_interactive_block()

      refute body =~ ~r/(?<![\w-])height\s*:/,
             "`.pk-pill-interactive` must not declare a bare `height` — only `min-height` (a " <>
               "floor), so pill geometry above the floor is still driven by content, not clamped."

      refute body =~ ~r/max-height/,
             "`.pk-pill-interactive` must not declare `max-height` — that would defeat the " <>
               "min-height floor for any pill whose content needs more room."

      refute body =~ ~r/width/,
             "`.pk-pill-interactive` must not declare `width`, `min-width`, or `max-width` — " <>
               "the interactive variant owns a height floor only, so pill widths and per-row " <>
               "wrapping (e.g. Wingspan's artist pills at 390px) cannot change."

      refute body =~ ~r/padding/,
             "`.pk-pill-interactive` must not declare `padding` — padding lives on `.pk-pill` " <>
               "or a size variant, never on the interactive behaviour variant."

      refute body =~ ~r/font-size/,
             "`.pk-pill-interactive` must not declare `font-size` — type size lives on `.pk-pill` " <>
               "or a size variant, never on the interactive behaviour variant."
    end

    test "the ::after hit layer spans a 44px-tall, vertical-only band centred on the pill, with no horizontal bleed or paint" do
      body = pk_pill_interactive_after_block()

      assert body =~ ~r/content:\s*"";?/, "`.pk-pill-interactive::after` must declare `content: \"\";`"

      assert body =~ ~r/position:\s*absolute\s*;/,
             "`.pk-pill-interactive::after` must declare `position: absolute;` so it layers over " <>
               "the relatively-positioned pill without affecting layout."

      assert body =~ ~r/left:\s*0\s*;/, "`.pk-pill-interactive::after` must declare `left: 0;`"
      assert body =~ ~r/right:\s*0\s*;/, "`.pk-pill-interactive::after` must declare `right: 0;`"

      top_matches = Regex.scan(~r/top:\s*min\(0px,\s*calc\(50% - 22px\)\)\s*;?/, body)
      bottom_matches = Regex.scan(~r/bottom:\s*min\(0px,\s*calc\(50% - 22px\)\)\s*;?/, body)

      assert top_matches != [],
             "`.pk-pill-interactive::after` must declare `top: min(0px, calc(50% - 22px));` — a " <>
               "44px-tall band centred on the pill, collapsing to the pill's own box once the " <>
               "pill is already taller than 44px."

      assert bottom_matches != [],
             "`.pk-pill-interactive::after` must declare `bottom: min(0px, calc(50% - 22px));` " <>
               "— the same centring rule as `top`, so the layer is symmetric."

      refute body =~ ~r/background/,
             "`.pk-pill-interactive::after` must not paint a background — it is an invisible hit " <>
               "layer only."

      refute body =~ ~r/border(?!-)/,
             "`.pk-pill-interactive::after` must not declare a border — it is an invisible hit " <>
               "layer only."

      refute body =~ ~r/z-index/,
             "`.pk-pill-interactive::after` must not declare a z-index — it needs none to sit " <>
               "above the pill's own (borderless) content."
    end

    test "the comfortable interactive compound rule raises the floor to 32px" do
      body = pk_pill_comfortable_interactive_block()

      assert body =~ ~r/min-height:\s*32px\s*;/,
             "`.pk-pill-comfortable.pk-pill-interactive` must declare `min-height: 32px;` — the " <>
               "comfortable-size compact floor (filter-modal chips, active-filter chips). It must " <>
               "be a COMPOUND selector placed after the plain `.pk-pill-interactive` rule, because " <>
               "a plain `.pk-pill-comfortable` rule sits earlier in the file at equal specificity " <>
               "and would lose to the interactive rule's 28px."
    end

    test "text stays vertically centred inside the pill — the base owns inline-flex + align-items:center, tones never override it" do
      base = pk_pill_base_block()
      tag = pk_pill_tag_block()

      assert base =~ ~r/display:\s*inline-flex\s*;/,
             "`.pk-pill` must declare `display: inline-flex;` — the flex centring that keeps " <>
               "text vertically centred inside the pill at either the 28px or 32px compact floor."

      assert base =~ ~r/align-items:\s*center\s*;/,
             "`.pk-pill` must declare `align-items: center;` — required alongside inline-flex " <>
               "so text centres vertically at the compact floor."

      refute tag =~ ~r/display\s*:/,
             "`.pk-pill-tag` (the hashtag tone, zero vertical padding) must not declare its " <>
               "own `display` — it must inherit the base's inline-flex, or its text would not " <>
               "centre inside the compact floor."

      refute tag =~ ~r/align-items\s*:/,
             "`.pk-pill-tag` must not declare its own `align-items` — it must inherit the " <>
               "base's `center`, or hashtag link text would not centre inside the compact floor."
    end

    test "the masthead facts row's row-gap is at least the 28px pill's 8px hit-layer overhang" do
      body = pk_poster_panel_facts_row_block()

      assert body =~ ~r/row-gap:\s*8px\s*;/,
             "`.pk-poster-panel > .pk-facts-row` must declare `row-gap: 8px;` — a 28px compact " <>
               "pill's `::after` layer overhangs (44 - 28) / 2 = 8px above and below; a smaller " <>
               "row gap would let a later row's invisible hit layer steal taps from the bottom " <>
               "of an earlier row's visible pill."
    end

    test "editorial_tags/1's linked wrapper widens its row gap to gap-y-2, keeping the column gap at gap-x-1" do
      html =
        render_component(&GameChips.editorial_tags/1,
          tags: ["#DuelosMemorables", "#CooperativoPuro"],
          href_fun: fn tag -> "/?tags=" <> URI.encode_www_form(tag) end
        )

      doc = LazyHTML.from_document(html)

      wrapper_class =
        doc
        |> LazyHTML.query("div")
        |> Enum.find(fn el ->
          case LazyHTML.attribute(el, "class") do
            [class] -> class =~ "flex-wrap"
            _ -> false
          end
        end)
        |> LazyHTML.attribute("class")
        |> List.first()

      refute is_nil(wrapper_class), "expected editorial_tags/1's wrapper div to render"

      tokens = String.split(wrapper_class)

      assert "flex" in tokens
      assert "flex-wrap" in tokens
      assert "gap-x-1" in tokens
      assert "gap-y-2" in tokens

      refute "gap-1" in tokens,
             "the old `gap-1` (4px, both axes) must be gone — hashtag pills now draw 28px tall " <>
               "with an 8px hit-layer overhang, so the old 4px row gap would let one row's " <>
               "invisible layer cover the row above it."
    end

    test "editorial_tags/1 still appends a caller-supplied class alongside the new gap tokens" do
      html =
        render_component(&GameChips.editorial_tags/1,
          tags: ["#DuelosMemorables"],
          href_fun: fn tag -> "/?tags=" <> URI.encode_www_form(tag) end,
          class: "pk-rhythm-8"
        )

      assert html =~ "pk-rhythm-8"
      assert html =~ "gap-y-2"
    end
  end

  # 01.3-07 (task 3 net-new coverage): CSS-source pins for the fact-grid
  # breakpoint, the .pk-text-col rhythm mechanism, and the .pk-pill-tag
  # hashtag contrast floor — three properties this restructure introduced
  # that nothing in the pre-existing suite protected. Reuses css_source/0,
  # dark_theme_plugin_block/0, token_value/2, relative_luminance/1 and
  # contrast_ratio/2 from the lightbox-close-button describe block above —
  # no second contrast/CSS-source harness written.
  describe "01.3-07 net-new CSS-source pins (fact-grid breakpoint, rhythm mechanism, hashtag contrast)" do
    # Same idiom as dark_theme_plugin_block/0 above, matching the light
    # theme's own plugin block instead.
    defp light_theme_plugin_block do
      case Regex.run(
             ~r/@plugin "daisyui\/packages\/bundle\/daisyui-theme" \{\s*name: "light";(.*?)\n\}/ms,
             css_source()
           ) do
        [_, body] -> body
        nil -> flunk("No light-theme `@plugin \"daisyui-theme\"` block found in assets/css/app.css")
      end
    end

    test ".pk-fact-cols declares a single-column base rule and a two-column override inside the one 48rem block" do
      src = css_source()

      assert Regex.match?(~r/(?m)^\.pk-fact-cols\s*\{[^}]*grid-template-columns:\s*1fr;/s, src),
             "`.pk-fact-cols` must declare a single-column base rule " <>
               "(`grid-template-columns: 1fr`) outside any media query — the mobile default."

      assert Regex.match?(
               ~r/@media \(min-width: 48rem\) \{.*?\.pk-fact-cols\s*\{[^}]*grid-template-columns:\s*1fr 1fr;/ms,
               src
             ),
             "The two-column override (`grid-template-columns: 1fr 1fr`) must live INSIDE the " <>
               "single 48rem detail-layout `@media` block — a second, independently-opened " <>
               "media query for this one rule would violate that block's own single-owner " <>
               "invariant."
    end

    test ".pk-text-col declares no gap, and the three .pk-text-col > .pk-rhythm-* margin rules all exist (the additive-boundary regression pin)" do
      src = css_source()

      case Regex.run(~r/(?m)^\.pk-text-col\s*\{([^}]*)\}/s, src) do
        [_, body] ->
          refute body =~ ~r/gap:/,
                 "`.pk-text-col` must declare no `gap` — a flex `gap` and a child `margin-top` " <>
                   "are additive, exactly the stacked-boundary bug detail-page-layout.md " <>
                   "records twice. The three named rhythm rules below are the ONLY spacing " <>
                   "mechanism now."

        nil ->
          flunk("No top-level `.pk-text-col { ... }` rule found in assets/css/app.css")
      end

      for tier <- ["8", "16", "32"] do
        assert Regex.match?(
                 ~r/(?m)^\.pk-text-col > \.pk-rhythm-#{tier}\s*\{[^}]*margin-top:/s,
                 src
               ),
               "`.pk-text-col > .pk-rhythm-#{tier}` must declare a `margin-top` — the named " <>
                 "child-margin rhythm tier that replaced the removed flex `gap`."
      end
    end

    # Mirrors dark_lightbox_close_block/0's idiom above (lightbox close
    # button dark-theme contrast describe block): sketch 055 (Option A,
    # 2026-09-10) resolved the dark-mode primary-as-text regression via a
    # dark-scoped override shared by 24 selectors (including .pk-pill-tag)
    # rather than by changing a theme token, so the actual dark-mode ink
    # for .pk-pill-tag is no longer --color-primary — it's whatever this
    # override sets. Matching on the literal `[data-theme="dark"] ` +
    # `.pk-pill-tag` selector text (guaranteed followed by a comma, since
    # it is not the last selector in the list) pulls the real shared
    # declaration body rather than assuming a hardcoded token name.
    #
    # UPDATED (quick task 260910-hdc, 2026-09-10): sketch 055's shared
    # override now resolves `color` from `--pk-ink-brand`, not
    # `--color-neutral` directly — see that token's provenance comment near
    # the top of app.css and the amended comment above the CSS block itself.
    defp dark_pill_tag_text_override_block do
      case Regex.run(~r/\[data-theme="dark"\] \.pk-pill-tag\b.*?\{([^}]*)\}/s, css_source()) do
        [_, body] ->
          body

        nil ->
          flunk("No `[data-theme=\"dark\"] .pk-pill-tag` selector found in a dark-scoped override in assets/css/app.css")
      end
    end

    test ".pk-pill-tag's text meets the 4.5:1 contrast floor in both themes and clears the brand-chroma floor in dark (260910-hdc)" do
      light_block = light_theme_plugin_block()
      light_primary = token_value(light_block, "--color-primary")
      light_base_100 = token_value(light_block, "--color-base-100")
      light_ratio = contrast_ratio(relative_luminance(light_primary), relative_luminance(light_base_100))

      assert light_ratio >= 4.5,
             "light theme: --color-primary (#{light_primary}) against --color-base-100 " <>
               "(#{light_base_100}) measured #{Float.round(light_ratio, 2)}:1 — .pk-pill-tag's " <>
               "hashtag text must clear the 4.5:1 WCAG AA text floor in both themes."

      # Light's `--pk-ink-brand` declaration must be a variable READ of
      # `--color-primary`, not a copied literal — so a future author cannot
      # quietly replace it with a hex and let light silently drift from the
      # brand manual.
      #
      # UPDATED (quick task 260910-l7q, Task 1 tracer): app.css now
      # declares a SECOND plain `:root { ... }` block (the `--pk-ramp-*`
      # ramp, ordered before this one) — `Regex.run/2` would silently match
      # that one first and break this assertion, so this scans every plain
      # `:root` block and picks the one containing `--pk-ink-brand`, the
      # same disambiguation-by-content idiom `ramp_root_block/0` uses for
      # its own sibling block.
      root_body =
        css_source()
        |> then(&Regex.scan(~r/(?m)^:root\s*\{([^}]*)\}/, &1, capture: :all_but_first))
        |> List.flatten()
        |> Enum.find(&(&1 =~ ~r/--pk-ink-brand:/))
        |> case do
          nil -> flunk("No plain `:root { ... }` block declaring `--pk-ink-brand` found in assets/css/app.css")
          body -> body
        end

      assert root_body =~ ~r/--pk-ink-brand:\s*var\(--color-primary\)\s*;/,
             "`:root`'s `--pk-ink-brand` declaration must be `var(--color-primary)`, a variable " <>
               "read — not a copied hex literal — found: #{inspect(root_body)}"

      dark_override_body = dark_pill_tag_text_override_block()

      assert dark_override_body =~ ~r/color:\s*var\(--pk-ink-brand\)\s*;/,
             "The dark-scoped override covering `.pk-pill-tag` must set `color` to a read of " <>
               "`--pk-ink-brand` (quick task 260910-hdc) — found: #{inspect(dark_override_body)}"

      dark_ink_brand_body = dark_pk_ink_brand_root_block()
      dark_ink_brand = token_value(dark_ink_brand_body, "--pk-ink-brand")

      dark_block = dark_theme_plugin_block()
      dark_base_100 = token_value(dark_block, "--color-base-100")
      dark_base_200 = token_value(dark_block, "--color-base-200")
      dark_base_300 = token_value(dark_block, "--color-base-300")

      for {ground_name, ground_hex} <- [
            {"base-100", dark_base_100},
            {"base-200", dark_base_200},
            {"base-300", dark_base_300}
          ] do
        ratio = contrast_ratio(relative_luminance(dark_ink_brand), relative_luminance(ground_hex))

        assert ratio >= 4.5,
               "dark theme: --pk-ink-brand (#{dark_ink_brand}) against --color-#{ground_name} " <>
                 "(#{ground_hex}) measured #{Float.round(ratio, 2)}:1 — .pk-pill-tag's hashtag " <>
                 "text (dark-scoped to --pk-ink-brand) must clear the 4.5:1 WCAG AA text floor " <>
                 "on every dark ground."
      end

      # The chroma floor is the actual fix: a value can clear every contrast
      # ratio above while still being a de-saturated grey-lavender that
      # reads as "disabled" rather than "brand purple". A future retune
      # that walks --pk-ink-brand back toward --color-neutral's C0.057 must
      # fail here rather than ship silently.
      chroma = oklch_chroma(dark_ink_brand)

      assert chroma >= 0.11,
             "dark theme: --pk-ink-brand (#{dark_ink_brand}) measured OKLCh chroma " <>
               "#{Float.round(chroma, 3)}, below the 0.11 floor that distinguishes a saturated " <>
               "brand purple from a desaturated 'disabled' grey-lavender."
    end

    # Sketch 056 (2026-09-10), developer-chosen Option D ("split-by-role")
    # for quick task 260910-gck: `btn-outline btn-primary`'s dark-mode
    # colour (--color-primary as text/border) failed both the 4.5:1 WCAG
    # 1.4.3 floor and the 3:1 1.4.11 floor on every outline-primary CTA
    # (260910-gck-EVIDENCE.md). The fix splits by role: Sumate (the site's
    # actual primary CTA) gets a dark-scoped SOLID fill reusing the
    # already-proven .pk-sumate-btn-solid pair; the genuinely secondary
    # CTAs (.pk-preview-cta, .pk-btn-secondary) get sketch 055's ink-swap
    # mechanism. Matches on literal selector text (not a hardcoded token
    # pair), same idiom as dark_pill_tag_text_override_block/0 above, so a
    # future palette/mechanism change re-fires this tripwire instead of
    # silently passing.
    defp dark_sumate_solid_fill_block do
      case Regex.run(
             ~r/\[data-theme="dark"\] \.pk-sumate-btn:not\(\.pk-sumate-btn-solid\)\s*\{([^}]*)\}/s,
             css_source()
           ) do
        [_, body] ->
          body

        nil ->
          flunk(
            "No `[data-theme=\"dark\"] .pk-sumate-btn:not(.pk-sumate-btn-solid)` rule found " <>
              "in assets/css/app.css"
          )
      end
    end

    # UPDATED (quick task 260910-hdc, 2026-09-10): this block's ink-swap
    # target moved from `--color-neutral` to `--pk-ink-brand` — see that
    # token's provenance comment near the top of app.css and the amended
    # sketch 056 comment above the CSS block itself.
    defp dark_secondary_cta_ink_swap_block do
      case Regex.run(
             ~r/\[data-theme="dark"\] \.pk-preview-cta,\s*\[data-theme="dark"\] \.pk-btn-secondary\s*\{([^}]*)\}/s,
             css_source()
           ) do
        [_, body] ->
          body

        nil ->
          flunk(
            ~s(No `[data-theme="dark"] .pk-preview-cta, [data-theme="dark"] .pk-btn-secondary` ) <>
              "rule found in assets/css/app.css"
          )
      end
    end

    test "dark-mode Sumate CTA solid-fills to the primary/primary-content pair (260910-gck)" do
      solid_body = dark_sumate_solid_fill_block()

      assert solid_body =~ ~r/background:\s*var\(--color-primary\)\s*;/,
             "The dark-scoped Sumate override must set `background` to a read of " <>
               "`--color-primary` — found: #{inspect(solid_body)}"

      assert solid_body =~ ~r/color:\s*var\(--color-primary-content\)\s*;/,
             "The dark-scoped Sumate override must set `color` to a read of " <>
               "`--color-primary-content` — found: #{inspect(solid_body)}"

      assert solid_body =~ ~r/border-color:\s*var\(--color-primary\)\s*;/,
             "The dark-scoped Sumate override must set `border-color` to a read of " <>
               "`--color-primary` — found: #{inspect(solid_body)}"

      dark_block = dark_theme_plugin_block()
      primary = token_value(dark_block, "--color-primary")
      primary_content = token_value(dark_block, "--color-primary-content")
      ratio = contrast_ratio(relative_luminance(primary_content), relative_luminance(primary))

      assert ratio >= 4.5,
             "dark theme: --color-primary-content (#{primary_content}) against its own solid " <>
               "--color-primary background (#{primary}) measured #{Float.round(ratio, 2)}:1 — " <>
               "Sumate's dark-mode solid-fill text must clear the 4.5:1 WCAG AA text floor."
    end

    test "dark-mode Sumate solid-fill excludes the sticky bar (not re-declared, 260910-gck)" do
      # dark_sumate_solid_fill_block/0 already flunks if the rule is missing
      # or if its selector doesn't literally read `:not(.pk-sumate-btn-solid)`
      # — this test additionally proves no SECOND dark-scoped rule also
      # targets `.pk-sumate-btn-solid` with the same background/color/
      # border-color trio, which would recreate the two-rules-compete-on-
      # one-property failure this file has already fixed twice.
      _ = dark_sumate_solid_fill_block()

      refute css_source() =~
               ~r/\[data-theme="dark"\] \.pk-sumate-btn-solid\s*\{[^}]*background:\s*var\(--color-primary\)/s,
             "`.pk-sumate-btn-solid` must not be re-declared by a second dark-scoped rule " <>
               "setting the same background/color/border-color properties it already " <>
               "declares unscoped."
    end

    test "dark-mode secondary CTAs ink-swap to --pk-ink-brand, clearing both floors (260910-hdc)" do
      ink_body = dark_secondary_cta_ink_swap_block()

      assert ink_body =~ ~r/color:\s*var\(--pk-ink-brand\)\s*;/,
             "The dark-scoped secondary-CTA override must set `color` to a read of " <>
               "`--pk-ink-brand` (quick task 260910-hdc) — found: #{inspect(ink_body)}"

      assert ink_body =~ ~r/border-color:\s*var\(--pk-ink-brand\)\s*;/,
             "The dark-scoped secondary-CTA override must set `border-color` to a read of " <>
               "`--pk-ink-brand` (quick task 260910-hdc) — found: #{inspect(ink_body)}"

      dark_ink_brand_body = dark_pk_ink_brand_root_block()
      ink_brand = token_value(dark_ink_brand_body, "--pk-ink-brand")

      dark_block = dark_theme_plugin_block()
      base_100 = token_value(dark_block, "--color-base-100")
      base_200 = token_value(dark_block, "--color-base-200")

      ratio_100 = contrast_ratio(relative_luminance(ink_brand), relative_luminance(base_100))
      ratio_200 = contrast_ratio(relative_luminance(ink_brand), relative_luminance(base_200))

      assert ratio_100 >= 4.5,
             "dark theme: --pk-ink-brand (#{ink_brand}) against --color-base-100 (#{base_100}) " <>
               "measured #{Float.round(ratio_100, 2)}:1 — the preview CTA and secondary button " <>
               "must clear the 4.5:1 WCAG AA text floor on base-100."

      assert ratio_100 >= 3.0,
             "dark theme: --pk-ink-brand (#{ink_brand}) against --color-base-100 (#{base_100}) " <>
               "measured #{Float.round(ratio_100, 2)}:1 — the outline border must clear the " <>
               "3:1 WCAG 1.4.11 non-text floor on base-100."

      assert ratio_200 >= 4.5,
             "dark theme: --pk-ink-brand (#{ink_brand}) against --color-base-200 (#{base_200}) " <>
               "measured #{Float.round(ratio_200, 2)}:1 — the closing-band ground must also " <>
               "clear the 4.5:1 WCAG AA text floor."

      assert ratio_200 >= 3.0,
             "dark theme: --pk-ink-brand (#{ink_brand}) against --color-base-200 (#{base_200}) " <>
               "measured #{Float.round(ratio_200, 2)}:1 — the outline border must clear the " <>
               "3:1 WCAG 1.4.11 non-text floor on base-200."

      chroma = oklch_chroma(ink_brand)

      assert chroma >= 0.11,
             "dark theme: --pk-ink-brand (#{ink_brand}) measured OKLCh chroma " <>
               "#{Float.round(chroma, 3)}, below the 0.11 floor that distinguishes a saturated " <>
               "brand purple from a desaturated 'disabled' grey-lavender."
    end

    test "light theme's outline-primary CTAs are untouched by the dark-mode fix (260910-gck)" do
      light_block = light_theme_plugin_block()
      light_primary = token_value(light_block, "--color-primary")
      light_base_100 = token_value(light_block, "--color-base-100")
      ratio = contrast_ratio(relative_luminance(light_primary), relative_luminance(light_base_100))

      assert ratio >= 4.5,
             "light theme: --color-primary (#{light_primary}) against --color-base-100 " <>
               "(#{light_base_100}) measured #{Float.round(ratio, 2)}:1 — light mode's " <>
               "outline-primary CTAs (Sumate, preview CTA, secondary button) must still " <>
               "resolve straight from --color-primary with no dark-scoped override involved."

      case Regex.run(~r/(?m)^\.pk-sumate-btn\s*\{([^}]*)\}/s, css_source()) do
        [_, base_body] ->
          refute base_body =~ ~r/color:|background:/,
                 "The base (unscoped) `.pk-sumate-btn` rule must declare no `color`/`background` " <>
                   "— light mode's outline treatment must keep coming from daisyUI's own " <>
                   "`btn-outline btn-primary` utilities, untouched by this dark-only fix."

        nil ->
          flunk("No top-level `.pk-sumate-btn { ... }` rule found in assets/css/app.css")
      end
    end

    # Quick task 260910-hdc, Task 2: the tripwire that encodes "one hue per
    # theme" — the actual thing this task fixes, distinct from Task 1's
    # contrast/chroma-floor tests above. A future palette retune that
    # re-splits the muted ink away from dark's brand hue must fail here
    # rather than ship silently.
    test "dark's muted ink sits within 2 degrees of dark's brand hue, at a chroma between the old muted value and --pk-ink-brand (260910-hdc)" do
      dark_block = dark_theme_plugin_block()
      neutral = token_value(dark_block, "--color-neutral")
      primary = token_value(dark_block, "--color-primary")

      neutral_hue = oklch_hue(neutral)
      primary_hue = oklch_hue(primary)
      hue_delta = abs(neutral_hue - primary_hue)

      assert hue_delta <= 2.0,
             "dark theme: --color-neutral (#{neutral}, hue #{Float.round(neutral_hue, 1)}°) must " <>
               "sit within 2 degrees of --color-primary's hue (#{primary}, hue " <>
               "#{Float.round(primary_hue, 1)}°) — measured delta #{Float.round(hue_delta, 1)}° — " <>
               "so dark theme carries one purple hue, not two families 6.6 degrees apart."

      neutral_chroma = oklch_chroma(neutral)

      dark_ink_brand_body = dark_pk_ink_brand_root_block()
      ink_brand = token_value(dark_ink_brand_body, "--pk-ink-brand")
      ink_brand_chroma = oklch_chroma(ink_brand)

      assert neutral_chroma < ink_brand_chroma,
             "dark theme: --color-neutral's chroma (#{Float.round(neutral_chroma, 3)}) must stay " <>
               "strictly below --pk-ink-brand's chroma (#{Float.round(ink_brand_chroma, 3)}), so " <>
               "the muted tier can never overtake the interactive-ink tier."

      old_muted_chroma = oklch_chroma("#B8A6CC")

      assert neutral_chroma > old_muted_chroma,
             "dark theme: --color-neutral's chroma (#{Float.round(neutral_chroma, 3)}) must be " <>
               "strictly above the superseded muted value's chroma " <>
               "(#{Float.round(old_muted_chroma, 3)}, #B8A6CC) — the whole point of this task's " <>
               "retune was to lift chroma onto the brand hue, not merely relabel the old value."
    end
  end

  # Quick task 260910-if9, Task 3 (developer decision: Pick 1 = C2 -- rotate
  # dark's --color-base-100/200/300 onto the brand hue (H313.1), holding L
  # and C; Pick 2 = W1 -- no label-ink change). Reuses
  # dark_theme_plugin_block/0, light_theme_plugin_block/0, token_value/2,
  # oklch_hue/1, oklch_chroma/1, relative_luminance/1 and contrast_ratio/2
  # from the describe blocks above -- no second CSS-source or OKLCh harness
  # declared here. C1 and C3 were costed in AUDIT.md but not picked (C1 --
  # narrower blast radius but caps out around a 10-degree residual spread
  # before the WCAG floor breaks; C3 -- structurally symmetric across themes
  # but does not close dark's own internal split) and are not tested here.
  # W2/W3 (new/split label-ink token) are not written either -- W1 was
  # picked, so `.pk-fact-col dt` / `.pk-bgg-label` / `.pk-bgg-lbl` /
  # `.pk-bgg-foot` are asserted UNCHANGED below, not given a new token.
  describe "quick task 260910-if9: dark base ladder rotated onto the brand hue (C2)" do
    # Task 1's oklch-audit.mjs proposed 8 degrees as a starting threshold
    # (light's own worst intra-tone spread, .pk-pill-accent, measures 9.8
    # degrees) -- Task 2's decision did not contest this number, so it is
    # taken as confirmed. C2's rotation lands the whole ladder within ~1
    # degree of the ink hue, well under this threshold regardless.
    @if9_hue_family_threshold_deg 8.0

    # Sketch 054's own four pinned WCAG ratios (assets/css/app.css's dark
    # `daisyui-theme` block comment, displayed there rounded to 2 decimals
    # as 13.59/6.85/12.07/6.70:1). These module attributes hold the true
    # unrounded floor truncated to 3 decimals (never rounded UP) so this
    # test cannot fail purely from the source comment's own display
    # rounding -- primary-content-on-primary in particular is untouched by
    # C2 and its precise value (6.696172) sits just BELOW the comment's
    # rounded-up "6.70:1", which a naive 6.70 floor would fail on a value
    # C2 never touched.
    @sketch_054_text_on_bg_floor 13.593
    @sketch_054_muted_on_bg_floor 6.847
    @sketch_054_text_on_surface_floor 12.069
    @sketch_054_primary_content_on_primary_floor 6.696

    test "dark's --color-base-100/200/300 sit within the hue-family threshold of dark's ink (--color-neutral), closing the F1 split (260910-if9 AUDIT.md)" do
      dark_block = dark_theme_plugin_block()

      base_100 = token_value(dark_block, "--color-base-100")
      base_200 = token_value(dark_block, "--color-base-200")
      base_300 = token_value(dark_block, "--color-base-300")
      neutral = token_value(dark_block, "--color-neutral")

      hues = %{
        "base-100" => oklch_hue(base_100),
        "base-200" => oklch_hue(base_200),
        "base-300" => oklch_hue(base_300),
        "neutral" => oklch_hue(neutral)
      }

      {min_name, min_hue} = Enum.min_by(hues, fn {_, h} -> h end)
      {max_name, max_hue} = Enum.max_by(hues, fn {_, h} -> h end)
      spread = max_hue - min_hue

      assert spread <= @if9_hue_family_threshold_deg,
             "dark theme: max hue spread across --color-base-100/200/300 and --color-neutral " <>
               "is #{Float.round(spread, 1)}° (#{min_name} #{Float.round(min_hue, 1)}° to " <>
               "#{max_name} #{Float.round(max_hue, 1)}°) -- must be at or below the " <>
               "#{@if9_hue_family_threshold_deg}° hue-family threshold Task 1's audit proposed " <>
               "and Task 2's C2 pick (rotate the base ladder onto the brand hue) commits to " <>
               "closing. Before this fix, `.pk-pill-outline`/`.pk-chip`'s border " <>
               "(--color-base-300) measured 15.0° from --color-neutral and `.pk-pill-neutral`'s " <>
               "fill (--color-base-200) measured 14.6° from it (260910-if9 AUDIT.md, finding F1)."
    end

    test "light theme's --color-base-100/300 are unchanged by the dark-only C2 rotation, and --color-base-200 is unchanged by C2 specifically" do
      light_block = light_theme_plugin_block()

      assert token_value(light_block, "--color-base-100") == "#FFFFFF",
             "light theme: --color-base-100 must stay byte-identical -- C2 is dark-scoped only."

      # UPDATED (quick task 260910-l7q): light `--color-base-200` legitimately
      # moved off its pre-l7q byte-identical value (#F3ECFA) when it JOINed
      # the shared `--pk-ramp-*` ramp under the FLAT envelope (dE 0.0085,
      # per ramp-audit.mjs) -- this is a DIFFERENT, LATER task's deliberate
      # change, not a 260910-if9 C2 regression. token_value/2's one-hop
      # `var(--pk-ramp-*)` dereference (also added by 260910-l7q) resolves
      # this to the ramp's real hex, so this assertion still proves "C2
      # itself never touched light" even though light's OWN value has since
      # moved for an unrelated, later, developer-approved reason.
      assert token_value(light_block, "--color-base-200") == "#F1ECFD",
             "light theme: --color-base-200 must resolve to the shared ramp's --pk-ramp-100 " <>
               "stop (260910-l7q, rotated to H300 by 260912-waa/sketch 058) -- C2 itself never " <>
               "touched this value."

      # UPDATED (quick task 260912-waa): 260910-if9's C2 rotation never
      # touched light -- this value stayed byte-identical through that
      # task. It has since moved for a DIFFERENT, LATER reason: sketch 058
      # (quick task 260912-waa) rotated every purple literal in both
      # themes onto the ramp's uniform H300 hue, "keep consistency with
      # light version to uniform color" per the developer's own
      # instruction.
      assert token_value(light_block, "--color-base-300") == "#DED4F3",
             "light theme: --color-base-300 must resolve to H300 (260912-waa/sketch 058's " <>
               "uniform-hue rotation) -- 260910-if9's C2 rotation itself never touched this " <>
               "value; it is a later task's hue-only rotation, not a C2 regression."
    end

    test "dark's --color-neutral ink still clears the WCAG 4.5:1 text floor against --color-base-200 (pill fill) and --color-base-100 (the ground transparent-fill tones render against)" do
      dark_block = dark_theme_plugin_block()
      neutral = token_value(dark_block, "--color-neutral")
      base_100 = token_value(dark_block, "--color-base-100")
      base_200 = token_value(dark_block, "--color-base-200")

      ratio_on_fill = contrast_ratio(relative_luminance(neutral), relative_luminance(base_200))
      ratio_on_page = contrast_ratio(relative_luminance(neutral), relative_luminance(base_100))

      assert ratio_on_fill >= 4.5,
             "dark theme: --color-neutral (#{neutral}) on --color-base-200 (#{base_200}, " <>
               "`.pk-pill-neutral`'s fill after the C2 rotation) measured " <>
               "#{Float.round(ratio_on_fill, 2)}:1 -- must clear the 4.5:1 WCAG text floor."

      assert ratio_on_page >= 4.5,
             "dark theme: --color-neutral (#{neutral}) on --color-base-100 (#{base_100}, the " <>
               "page ground `.pk-pill-outline`/`.pk-chip` render against with a transparent " <>
               "fill) measured #{Float.round(ratio_on_page, 2)}:1 -- must clear the 4.5:1 WCAG " <>
               "text floor."
    end

    test "sketch 054's four pinned dark-mode contrast assertions hold at or above their recorded ratios after the C2 rotation" do
      dark_block = dark_theme_plugin_block()

      base_100 = token_value(dark_block, "--color-base-100")
      base_200 = token_value(dark_block, "--color-base-200")
      base_content = token_value(dark_block, "--color-base-content")
      neutral = token_value(dark_block, "--color-neutral")
      primary = token_value(dark_block, "--color-primary")
      primary_content = token_value(dark_block, "--color-primary-content")

      text_on_bg = contrast_ratio(relative_luminance(base_content), relative_luminance(base_100))
      muted_on_bg = contrast_ratio(relative_luminance(neutral), relative_luminance(base_100))
      text_on_surface = contrast_ratio(relative_luminance(base_content), relative_luminance(base_200))

      primary_content_on_primary =
        contrast_ratio(relative_luminance(primary_content), relative_luminance(primary))

      assert text_on_bg >= @sketch_054_text_on_bg_floor,
             "dark theme: text (#{base_content}) on bg (#{base_100}) measured " <>
               "#{Float.round(text_on_bg, 4)}:1 -- must stay at or above sketch 054's recorded " <>
               "#{@sketch_054_text_on_bg_floor}:1. A C2 base-ladder rotation must never silently " <>
               "degrade sketch 054's pinned dark-mode contrast."

      assert muted_on_bg >= @sketch_054_muted_on_bg_floor,
             "dark theme: muted (#{neutral}) on bg (#{base_100}) measured " <>
               "#{Float.round(muted_on_bg, 4)}:1 -- must stay at or above sketch 054's recorded " <>
               "#{@sketch_054_muted_on_bg_floor}:1."

      assert text_on_surface >= @sketch_054_text_on_surface_floor,
             "dark theme: text (#{base_content}) on surface (#{base_200}) measured " <>
               "#{Float.round(text_on_surface, 4)}:1 -- must stay at or above sketch 054's " <>
               "recorded #{@sketch_054_text_on_surface_floor}:1."

      assert primary_content_on_primary >= @sketch_054_primary_content_on_primary_floor,
             "dark theme: primary-content (#{primary_content}) on primary (#{primary}) measured " <>
               "#{Float.round(primary_content_on_primary, 4)}:1 -- must stay at or above sketch " <>
               "054's recorded #{@sketch_054_primary_content_on_primary_floor}:1 (--color-primary " <>
               "and --color-primary-content are untouched by C2 -- this pins that fact)."
    end

    test "dark's uppercase/inline label ink rules still read var(--color-neutral) -- W1 (no change) leaves the label tier untouched" do
      src = css_source()

      for selector <- [".pk-fact-col dt", ".pk-bgg-label", ".pk-bgg-lbl", ".pk-bgg-foot"] do
        case Regex.run(~r/(?m)^#{Regex.escape(selector)}\s*\{([^}]*)\}/s, src) do
          [_, body] ->
            assert body =~ ~r/color:\s*var\(--color-neutral\)\s*;/,
                   "`#{selector}` must still read `color: var(--color-neutral)` -- Task 2's Pick " <>
                     "2 was W1 (no change): dark's label-to-body lightness gap (ΔL 20.1) is " <>
                     "already tighter than light's (ΔL 26.9) and clears 6.85:1 contrast, so this " <>
                     "task deliberately does not introduce a --pk-ink-label token."

          nil ->
            flunk("No top-level `#{selector} { ... }` rule found in assets/css/app.css")
        end
      end
    end
  end

  # Quick task 260910-l7q, Task 5: the invariant that is the entire reason
  # approach (b) -- daisyUI's `--color-*` slots as `var()` reads into a
  # shared `--pk-ramp-*` ramp -- was worth its blast radius. Reuses
  # dark_theme_plugin_block/0, light_theme_plugin_block/0, token_value/2,
  # ramp_root_block/0, css_source/0, oklab/1, oklch_chroma/1 and
  # oklch_hue/1 from the describe blocks above -- no second CSS-source or
  # OKLCh harness declared here. This exact describe name is the string
  # the Task 5 red proof (below, in this plan) greps ExUnit's failure
  # output for -- a different name would make that proof vacuous.
  describe "quick task 260910-l7q: shared OKLCh ramp invariants" do
    # Envelope constants as committed to the ramp block's own header
    # comment in app.css (Task 3 Decision 1: FLAT, k=0.85). Sketch 058
    # (quick task 260912-waa, 2026-09-12) moved the ramp's hue from H313.1
    # to H300 -- the brand manual's Lila Oscuro hue -- holding each stop's
    # own shipped OKLCh lightness (see h300-audit.mjs in that quick task's
    # directory). A future change to either value must update both the CSS
    # comment and these two module attributes together.
    @l7q_ramp_hue 300
    @l7q_ramp_k 0.85

    # Roles DELIBERATELY off the ramp under the FLAT envelope Task 3 picked
    # -- either categorically (D-Semantics' four semantic hues + their
    # -content slots; pure achromatic white) or because Task 2's
    # role-by-role audit put them in the blocked set (chroma tier or
    # contrast -- see the per-role annotation directly above each
    # declaration in app.css, and 260910-l7q-SUMMARY.md for the full
    # table). A role in a theme's `--color-*` list that is NEITHER a
    # `var(--pk-ramp-*)` read NOR on that theme's allow-list here is
    # exactly the silent drift T-l7q-03 exists to catch.
    @l7q_light_off_ramp ~w(
      base-100 base-300 base-content primary-content secondary secondary-content
      accent neutral neutral-content
      info info-content success success-content warning warning-content error error-content
    )
    @l7q_dark_off_ramp ~w(
      base-100 primary-content secondary secondary-content accent accent-content
      neutral neutral-content
      info info-content success success-content warning warning-content error error-content
    )

    # Every `--color-<role>: <value>;` declaration in a theme block, as
    # {role, trimmed value} pairs -- shared by both invariant tests below.
    defp l7q_color_declarations(body) do
      ~r/--color-([a-z0-9-]+):\s*([^;]+);/
      |> Regex.scan(body)
      |> Enum.map(fn [_, role, value] -> {role, String.trim(value)} end)
    end

    # The 11 committed ramp stops, in the order they appear in
    # `ramp_root_block/0`'s body -- which IS descending-lightness order by
    # construction (the block is hand-authored top-to-bottom that way and
    # test 1 below separately proves nothing else shares the block), so no
    # re-sort is needed here.
    defp l7q_ramp_stops do
      ~r/--pk-ramp-([0-9]+):\s*(#[0-9A-Fa-f]{6});/
      |> Regex.scan(ramp_root_block())
      |> Enum.map(fn [_, stop, hex] -> {stop, hex} end)
    end

    # OKLCh -> linear sRGB (the exact inverse of oklab/1's forward
    # matrices, mirroring ramp-audit.mjs's own `oklchToLab`/
    # `labToLinearRgb` -- ported here, not re-derived, per D-NoFourthCopy's
    # spirit: one canonical derivation, now in two languages because the
    # gate needs to run in both, never three+ independent copies).
    defp l7q_oklch_to_lab(l_pct, c, h_deg) do
      l = l_pct / 100
      h_rad = h_deg * :math.pi() / 180
      {l, c * :math.cos(h_rad), c * :math.sin(h_rad)}
    end

    defp l7q_lab_to_linear_rgb({l, a, b}) do
      l_ = l + 0.3963377774 * a + 0.2158037573 * b
      m_ = l - 0.1055613458 * a - 0.0638541728 * b
      s_ = l - 0.0894841775 * a - 1.291485548 * b

      ll = l_ * l_ * l_
      mm = m_ * m_ * m_
      ss = s_ * s_ * s_

      r = 4.0767416621 * ll - 3.3077115913 * mm + 0.2309699292 * ss
      g = -1.2684380046 * ll + 2.6097574011 * mm - 0.3413193965 * ss
      b_out = -0.0041960863 * ll - 0.7034186147 * mm + 1.707614701 * ss

      {r, g, b_out}
    end

    defp l7q_in_gamut?(l_pct, c, h_deg) do
      eps = 1.0e-6
      {r, g, b} = l7q_lab_to_linear_rgb(l7q_oklch_to_lab(l_pct, c, h_deg))
      r >= -eps and r <= 1 + eps and g >= -eps and g <= 1 + eps and b >= -eps and b <= 1 + eps
    end

    # Ports ramp-audit.mjs's own `maxChroma` bisection -- the maximum
    # in-gamut sRGB chroma at a given OKLCh lightness/hue. Used ONLY to
    # check that no committed stop exceeds the declared k times this
    # ceiling, never to regenerate the ramp (that stays ramp-audit.mjs's
    # job).
    defp l7q_max_chroma(l_pct, h_deg) do
      {lo, _hi} =
        Enum.reduce(1..40, {0.0, 0.5}, fn _, {lo, hi} ->
          mid = (lo + hi) / 2
          if l7q_in_gamut?(l_pct, mid, h_deg), do: {mid, hi}, else: {lo, mid}
        end)

      lo
    end

    defp l7q_oklch_lightness(hex) do
      {l, _a, _b} = oklab(hex)
      l * 100
    end

    test "single source: --pk-ramp-* stops are declared exactly 11 times, all inside one plain :root block, and no theme block redeclares one" do
      src = css_source()
      full_declaration = ~r/(?m)^\s*--pk-ramp-[0-9]{2,3}:\s*#[0-9A-Fa-f]{6};\s*$/

      all_declarations = Regex.scan(full_declaration, src)

      assert length(all_declarations) == 11,
             "Expected exactly 11 `--pk-ramp-*` stop declarations (a full `token: #hex;` " <>
               "line) across the whole stylesheet, found #{length(all_declarations)}. A " <>
               "second declaration -- especially inside a daisyui-theme block -- would " <>
               "restore per-theme divergence while still looking shared (plan threat " <>
               "T-l7q-02)."

      in_ramp_block = Regex.scan(full_declaration, ramp_root_block())

      assert length(in_ramp_block) == 11,
             "All 11 --pk-ramp-* stops must live inside the ONE plain `:root` block that " <>
               "declares them -- found #{length(in_ramp_block)} inside it against 11 total " <>
               "in the whole file, meaning at least one stop is declared somewhere else."

      for {block_name, block_body} <- [
            {"dark theme", dark_theme_plugin_block()},
            {"light theme", light_theme_plugin_block()}
          ] do
        refute Regex.match?(~r/(?m)^\s*--pk-ramp-[0-9]+:/, block_body),
               "The #{block_name} block must never declare its own --pk-ramp-* token -- it " <>
                 "may only READ one via var(--pk-ramp-NNN)."
      end
    end

    test "no silent drift off-ramp: every --color-* role is either a ramp read or an explicitly allow-listed off-ramp role" do
      for {theme_name, block, allow_list} <- [
            {"light", light_theme_plugin_block(), @l7q_light_off_ramp},
            {"dark", dark_theme_plugin_block(), @l7q_dark_off_ramp}
          ] do
        for {role, value} <- l7q_color_declarations(block) do
          on_ramp = Regex.match?(~r/^var\(--pk-ramp-[0-9]+\)$/, value)
          allow_listed = role in allow_list

          assert on_ramp or allow_listed,
                 "#{theme_name} theme: --color-#{role} is #{inspect(value)} -- neither a " <>
                   "var(--pk-ramp-*) read nor on the explicit off-ramp allow-list above. " <>
                   "Either this role must join the ramp, or its name must be added to the " <>
                   "allow-list with a recorded reason -- this is the exact drift the " <>
                   "260910-efe -> gck -> hdc -> if9 chain is a record of (plan threat T-l7q-03)."
        end
      end
    end

    test "the shared swatch holds: light primary, light accent-content and dark base-200 resolve to the identical hex at the brand hue" do
      light_block = light_theme_plugin_block()
      dark_block = dark_theme_plugin_block()

      light_primary = token_value(light_block, "--color-primary")
      light_accent_content = token_value(light_block, "--color-accent-content")
      dark_base_200 = token_value(dark_block, "--color-base-200")

      assert light_primary == light_accent_content,
             "light --color-primary (#{light_primary}) and --color-accent-content " <>
               "(#{light_accent_content}) must resolve to the identical hex -- both are the " <>
               "same forced D-HueMove join onto the same ramp stop."

      assert light_primary == dark_base_200,
             "light --color-primary/--color-accent-content (#{light_primary}) and dark " <>
               "--color-base-200 (#{dark_base_200}) must resolve to the identical hex -- " <>
               "this is the developer's own 'Reservar para el sábado' motivating example " <>
               "(260910-l7q-CONTEXT.md), closed by construction. A future palette edit that " <>
               "quietly un-shares this swatch must fail here."

      hue = oklch_hue(light_primary)
      raw_delta = abs(hue - @l7q_ramp_hue)
      hue_delta = min(raw_delta, 360 - raw_delta)

      assert hue_delta <= 2.0,
             "The shared swatch (#{light_primary}) measured OKLCh hue " <>
               "#{Float.round(hue, 1)}°, #{Float.round(hue_delta, 1)}° from the ramp's " <>
               "brand hue H#{@l7q_ramp_hue} -- must stay within the same 2° tolerance the " <>
               "260910-hdc tripwire already uses."
    end

    test "the ramp is a ramp: strictly monotone lightness, every stop within 2 degrees of H300, and no stop exceeds k * gamut-max chroma" do
      stops = l7q_ramp_stops()

      assert length(stops) == 11, "Expected 11 ramp stops, found #{length(stops)}"

      stops_with_l = Enum.map(stops, fn {stop, hex} -> {stop, l7q_oklch_lightness(hex)} end)

      for [{prev_stop, prev_l}, {stop, l}] <- Enum.chunk_every(stops_with_l, 2, 1, :discard) do
        assert l < prev_l,
               "Ramp stop --pk-ramp-#{stop} (L#{Float.round(l, 1)}) must be strictly darker " <>
                 "than the preceding declared stop --pk-ramp-#{prev_stop} (L#{Float.round(prev_l, 1)}) " <>
                 "-- the ladder must read as a ladder, in the order the stops are declared."
      end

      for {stop, hex} <- stops do
        c = oklch_chroma(hex)

        # Hue is numerically undefined at C=0 and increasingly noisy as C
        # approaches it -- atan2(b, a) amplifies the same 8-bit hex
        # quantization step into a proportionally larger angle at low
        # chroma. Measured directly against this ramp's own near-white
        # stop (--pk-ramp-50, C≈0.011): 2.4° off H300 (quick task
        # 260912-waa/sketch 058's hue, re-measured after the H313.1 -> H300
        # move), purely from hex rounding, not a real hue drift. Every
        # OTHER stop (C >= 0.023) measures within 0.7° of H300. 0.02 sits
        # between the two, so it exempts only the one stop where hue is
        # genuinely unmeasurable at hex precision, not a general escape
        # hatch.
        if c >= 0.02 do
          hue = oklch_hue(hex)
          raw_delta = abs(hue - @l7q_ramp_hue)
          hue_delta = min(raw_delta, 360 - raw_delta)

          assert hue_delta <= 2.0,
                 "--pk-ramp-#{stop} (#{hex}) measured OKLCh hue #{Float.round(hue, 1)}°, " <>
                   "#{Float.round(hue_delta, 1)}° from H#{@l7q_ramp_hue} -- every stop must " <>
                   "sit on the ramp's single fixed hue."
        end

        l = l7q_oklch_lightness(hex)
        ceiling = @l7q_ramp_k * l7q_max_chroma(l, @l7q_ramp_hue)

        assert c <= ceiling + 0.005,
               "--pk-ramp-#{stop} (#{hex}) measured OKLCh chroma #{Float.round(c, 4)}, above " <>
                 "the declared envelope's ceiling #{Float.round(ceiling, 4)} " <>
                 "(k=#{@l7q_ramp_k} * gamut-max at L#{Float.round(l, 1)}/H#{@l7q_ramp_hue}) -- " <>
                 "no stop may be pinned to (or past) the sRGB gamut wall."
      end
    end
  end
end
