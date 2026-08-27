defmodule PukllayClubWeb.CatalogLive.ShowTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Reservation
  alias PukllayClubWeb.CarouselRow
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

      link_class = matches |> LazyHTML.attribute("class") |> List.first()
      assert link_class == "pk-fact"
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

    test "renders designers, age, and description in Ficha técnica, and players/duration once in the facts row (D-05)",
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
      assert html =~ "10+"
      assert html =~ "Compite por colonizar la isla de Catán."

      # D-05: players is represented exactly once, by the facts row —
      # never restated as a Ficha técnica spec row.
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
      assert view.module == PukllayClubWeb.CatalogLive.Show
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

    test "the ficha técnica never renders the dead Ilustrador or BGG-ranking rows (D-04)", %{
      conn: conn
    } do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)
      spec_html = doc |> LazyHTML.query(".pk-spec-list") |> LazyHTML.to_html()

      refute spec_html =~ "Ilustrador"
      refute spec_html =~ "Puesto en el ranking BGG"
      refute spec_html =~ "No disponible"
    end

    test "a game with a bgg_id renders a boardgamegeek.com link in the ficha técnica, one without renders none",
         %{conn: conn} do
      # weight_band differs so neither game is the other's Juegos similares
      # bandmate — the footer's own unconditional BGG attribution link
      # would otherwise make "no boardgamegeek.com anywhere on the page"
      # unassertable regardless of this game's own bgg_id.
      with_id = game_fixture(%{name: "Con BGG", bgg_id: 13, weight_band: "nivel_experto"})
      without_id = game_fixture(%{name: "Sin BGG", bgg_id: nil, weight_band: "descubre_el_hobby"})

      {:ok, _view, html_with} = live(conn, ~p"/juegos/#{with_id.id}")
      {:ok, _view, html_without} = live(conn, ~p"/juegos/#{without_id.id}")

      spec_html_with =
        html_with |> LazyHTML.from_document() |> LazyHTML.query(".pk-spec-list") |> LazyHTML.to_html()

      spec_html_without =
        html_without
        |> LazyHTML.from_document()
        |> LazyHTML.query(".pk-spec-list")
        |> LazyHTML.to_html()

      assert spec_html_with =~ "boardgamegeek.com/boardgame/13"
      refute spec_html_without =~ "boardgamegeek.com"
    end

    test "a minimal-data game with none of the five spec fields renders no Ficha técnica heading, and the rest of the page still renders",
         %{conn: conn} do
      game =
        game_fixture(%{
          name: "Juego Minimo",
          min_age: nil,
          year_published: nil,
          designers: [],
          publishers: [],
          bgg_id: nil
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "Ficha técnica"
      refute html =~ "pk-spec-list"
      assert html =~ "Juego Minimo"
      assert html =~ "Reservar para el sábado"
    end

    test "a game with only a bgg_id and none of the other four fields still renders the Ficha técnica heading and the BGG link",
         %{conn: conn} do
      game =
        game_fixture(%{
          min_age: nil,
          year_published: nil,
          designers: [],
          publishers: [],
          bgg_id: 77
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "Ficha técnica"
      assert html =~ "boardgamegeek.com/boardgame/77"
    end

    test "clicking the description toggle expands and collapses the clamp", %{conn: conn} do
      game = game_fixture(%{description: "Una descripción de prueba."})

      {:ok, view, html} = live(conn, ~p"/juegos/#{game.id}")
      assert html =~ "pk-clamp"
      refute html =~ "is-expanded"

      html2 = render_click(view, "toggle-description", %{})
      assert html2 =~ "is-expanded"

      html3 = render_click(view, "toggle-description", %{})
      refute html3 =~ "is-expanded"
    end
  end

  describe "reading column reorder — title then description then a bounded more-info zone (G-01.2-10 task 3)" do
    test "the description block is the element immediately following the title heading — ordered children, not a substring match",
         %{conn: conn} do
      game = game_fixture(%{description: "Una crónica de mercaderes."})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      # Adjacent-sibling combinator: this only matches when .pk-description
      # is literally the very next element after #detail-title-block — an
      # element reinserted between them (the weight badge, the editorial
      # hashtags, either chip row) makes this query return nothing.
      assert doc |> LazyHTML.query("#detail-title-block + .pk-description") |> Enum.count() == 1
    end

    test "the mechanics/themes chip rows and editorial hashtags never render before the description block",
         %{conn: conn} do
      game =
        game_fixture(%{
          description: "Una crónica de mercaderes.",
          mechanics: ["Dice Rolling"],
          themes: ["Economic"],
          tags: ["#CreaConexiones"]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      {description_idx, _} = :binary.match(html, "Una crónica de mercaderes.")
      {mechanics_idx, _} = :binary.match(html, "Mecánicas")
      {themes_idx, _} = :binary.match(html, "Temáticas")
      {hashtag_idx, _} = :binary.match(html, "#CreaConexiones")

      assert description_idx < mechanics_idx
      assert description_idx < themes_idx
      assert description_idx < hashtag_idx
    end

    test "a separator element exists between the description block and the first more-information heading",
         %{conn: conn} do
      game = game_fixture(%{description: "Una crónica.", mechanics: ["Dice Rolling"]})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-description + .divider") |> Enum.count() == 1
    end

    test "the hashtag row flows straight into the Mecánicas heading — ordered siblings, no element (the removed badge) between them (G-01.2-20)",
         %{conn: conn} do
      game =
        game_fixture(%{
          weight_band: "ingenio_estratega",
          description: "Una crónica.",
          mechanics: ["Dice Rolling"],
          tags: ["#CreaConexiones"]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      # Adjacent-sibling chain: the div immediately after .pk-divider (the
      # editorial hashtag row) must itself be immediately followed by the
      # Mecánicas heading. A re-added element between them (the former
      # badge block) breaks the chain and this query returns 0 instead of
      # 1 — even with a weight band present, which is the case that used
      # to render the badge.
      assert doc |> LazyHTML.query(".pk-divider + div + h2.pk-section-heading") |> Enum.count() ==
               1
    end

    test "a game with publishers renders no publisher row in the spec list", %{conn: conn} do
      game = game_fixture(%{publishers: ["Devir"]})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "Devir"
      refute html =~ "Editorial"
    end

    test "a game whose only populated spec field is publishers renders no Ficha técnica section at all",
         %{conn: conn} do
      game =
        game_fixture(%{
          min_age: nil,
          year_published: nil,
          designers: [],
          publishers: ["Devir"],
          bgg_id: nil
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      refute html =~ "Ficha técnica"
      refute html =~ "pk-spec-list"
    end

    test "a game with a year and publishers still renders the Ficha técnica section with the year row",
         %{conn: conn} do
      game =
        game_fixture(%{
          min_age: nil,
          year_published: 2001,
          designers: [],
          publishers: ["Devir"],
          bgg_id: nil
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "Ficha técnica"
      assert html =~ "2001"
      refute html =~ "Devir"
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

  describe "detail page mobile chrome and interaction (SHELL-03)" do
    test "the CTA bar, title-echo bar, and title block all render with their ids", %{conn: conn} do
      game = game_fixture()

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ ~s(id="detail-cta-bar")
      assert html =~ ~s(id="detail-title-echo")
      assert html =~ ~s(id="detail-title-block")
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

    test "the lightbox chevrons carry the keyboard handler's stable hooks and unchanged neighbor targets",
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

      prev_url =
        doc
        |> LazyHTML.query("#detail-lightbox [data-lightbox-prev]")
        |> LazyHTML.attribute("phx-value-url")
        |> List.first()

      next_url =
        doc
        |> LazyHTML.query("#detail-lightbox [data-lightbox-next]")
        |> LazyHTML.attribute("phx-value-url")
        |> List.first()

      # cover_url is first in gallery_thumbnails/1's list, so its previous
      # neighbor wraps around to the last gallery image and its next
      # neighbor is the first gallery image — unchanged targets, only the
      # new data-lightbox-prev/next hooks are added.
      assert prev_url == "https://images.test.invalid/games/1/gallery-2.webp"
      assert next_url == "https://images.test.invalid/games/1/gallery-1.webp"
    end

    test "the poster button that opens the lightbox carries the stable id the hook focuses on close",
         %{conn: conn} do
      game = game_fixture(%{cover_url: "https://images.test.invalid/games/1/cover.webp"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ ~s(id="detail-lightbox-trigger")
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
    test "facts_row renders exactly once, as a direct child of the poster column, immediately followed by the poster panel",
         %{conn: conn} do
      game = game_fixture(%{min_players: 2, max_players: 4, weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      # Exactly one copy exists in the whole document — the mobile overlay
      # copy and the desktop inline copy are gone, collapsed into one.
      assert doc |> LazyHTML.query(".pk-facts-row") |> Enum.count() == 1
      assert doc |> LazyHTML.query(".pk-poster-col > .pk-facts-row") |> Enum.count() == 1

      # Ordered-siblings assertion (not mere presence): the row precedes
      # the panel in document order, at every viewport width.
      assert doc |> LazyHTML.query(".pk-poster-col > .pk-facts-row + .pk-poster-panel") |> Enum.count() ==
               1
    end

    test "the players, tiempo and dificultad pills all render inside the single facts row, with the same link targets they have today",
         %{conn: conn} do
      game = game_fixture(%{min_players: 2, max_players: 4, weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query(".pk-poster-col > .pk-facts-row .pk-fact") |> Enum.count() == 3

      assert doc
             |> LazyHTML.query(".pk-poster-col > .pk-facts-row a.pk-fact[href*='?players=']")
             |> Enum.count() == 1

      assert doc
             |> LazyHTML.query(".pk-poster-col > .pk-facts-row a.pk-fact[href*='?max_playtime=']")
             |> Enum.count() == 1

      assert doc |> LazyHTML.query(".pk-poster-col > .pk-facts-row .pk-difficulty") |> Enum.count() ==
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
      assert doc |> LazyHTML.query(".pk-poster-col > .pk-facts-row") |> Enum.count() == 1

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

  describe "Mecánicas/Temáticas chip contrast fix (G-01.2-20 task 2)" do
    test "the mechanic and theme chip rows' wrapper carries the pk-chip-row scoping class",
         %{conn: conn} do
      game =
        game_fixture(%{
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

      # The hashtag chip renders (proves the row is present at all)...
      assert doc |> LazyHTML.query(".badge-accent") |> Enum.count() == 1

      # ...but never as a descendant of a pk-chip-row wrapper.
      assert doc |> LazyHTML.query("div.pk-chip-row .badge-accent") |> Enum.count() == 0
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
      # which carries pk-chip-row unconditionally.
      assert linked_html =~ "pk-chip-row"
      assert linked_html =~ ~r/<a[^>]*class="badge badge-sm"[^>]*>\s*Tira dados/

      assert unlinked_html =~ "pk-chip-row"
      assert unlinked_html =~ ~s(<span class="badge badge-sm">Tira dados</span>)

      assert overflow_html =~ "pk-chip-row"
      assert overflow_html =~ ~s(<span class="badge badge-sm">+3</span>)

      # Sanity check on the live page: the mechanic chip's real call site
      # (href_fun always passed) does render the linked shape inside the
      # scoped wrapper.
      game = game_fixture(%{mechanics: ["Dice Rolling"]})
      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")
      doc = LazyHTML.from_document(html)

      assert doc
             |> LazyHTML.query("div.pk-chip-row a.badge[href*='mechanics=']")
             |> Enum.count() == 1
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

      assert doc |> LazyHTML.query(".pk-poster-col > .pk-facts-row") |> Enum.count() == 1
    end

    test "the description is the element immediately after the title", %{conn: conn} do
      game = game_fixture(%{description: "Una crónica de mercaderes."})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query("#detail-title-block + .pk-description") |> Enum.count() == 1
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

    test "neither chip row nor the editorial hashtags appear before the description", %{conn: conn} do
      game =
        game_fixture(%{
          description: "Una crónica.",
          mechanics: ["Dice Rolling"],
          themes: ["Economic"],
          tags: ["#CreaConexiones"]
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      {description_idx, _} = :binary.match(html, "Una crónica.")
      {mechanics_idx, _} = :binary.match(html, "Mecánicas")
      {themes_idx, _} = :binary.match(html, "Temáticas")
      {hashtag_idx, _} = :binary.match(html, "#CreaConexiones")

      assert description_idx < mechanics_idx
      assert description_idx < themes_idx
      assert description_idx < hashtag_idx
    end

    test "no publisher row renders, and a publishers-only game renders no spec section", %{
      conn: conn
    } do
      with_publisher = game_fixture(%{publishers: ["Devir"]})
      {:ok, _view, html_with} = live(conn, ~p"/juegos/#{with_publisher.id}")
      refute html_with =~ "Editorial"

      publishers_only =
        game_fixture(%{
          min_age: nil,
          year_published: nil,
          designers: [],
          publishers: ["Devir"],
          bgg_id: nil
        })

      {:ok, _view, html_only} = live(conn, ~p"/juegos/#{publishers_only.id}")
      refute html_only =~ "Ficha técnica"
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

      assert html =~ "Ingresá tu nombre para continuar."
      refute html =~ "Abrir WhatsApp"
    end

    test "a whitespace-only name behaves identically to an empty one", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      html = view |> form("#reservation-modal form", %{"nombre" => "   "}) |> render_submit()

      assert html =~ "Ingresá tu nombre para continuar."
      refute html =~ "Abrir WhatsApp"
    end

    test "a name over 60 graphemes produces a length message and no wa.me link", %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      too_long = String.duplicate("a", 61)
      html = view |> form("#reservation-modal form", %{"nombre" => too_long}) |> render_submit()

      assert html =~ "El nombre es demasiado largo (máximo 60 caracteres)."
      refute html =~ "Abrir WhatsApp"
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
      assert html =~ "próximo sábado en el club"
      refute html =~ ~r/presta|préstamo|alquil|llevar a casa/i
    end

    test "an unconfigured reservation number renders an explanatory message and no link", %{conn: conn} do
      original = Application.get_env(:pukllay_club, :reservation_whatsapp_number)
      Application.put_env(:pukllay_club, :reservation_whatsapp_number, nil)
      on_exit(fn -> Application.put_env(:pukllay_club, :reservation_whatsapp_number, original) end)

      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game.id}")

      html = view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()

      assert html =~ "La reserva no está disponible por el momento."
      refute html =~ "Abrir WhatsApp"
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

  describe "facts pills and chips link into the catalog's filter params (SHELL-04, 01.1-06)" do
    test "the dificultad pill links to ?weight_bands=<band> — the badge's removed link target, moved here (G-01.2-20)",
         %{conn: conn} do
      game = game_fixture(%{name: "Banded Game", weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc
             |> LazyHTML.query(".pk-poster-col > .pk-facts-row a.pk-fact[href='/?weight_bands=ingenio_estratega']")
             |> Enum.count() == 1
    end

    test "a game with no weight band renders neither a dificultad link nor a bare band label in the facts row",
         %{conn: conn} do
      game = game_fixture(%{name: "No Band Game", weight_band: nil})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      doc = LazyHTML.from_document(html)

      assert doc
             |> LazyHTML.query(".pk-poster-col > .pk-facts-row a[href*='weight_bands=']")
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
end
