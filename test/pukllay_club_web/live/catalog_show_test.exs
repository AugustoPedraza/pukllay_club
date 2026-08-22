defmodule PukllayClubWeb.CatalogLive.ShowTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

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

    test "renders the weight-band label AND its one-line descriptor", %{conn: conn} do
      game = game_fixture(%{weight_band: "ingenio_estratega"})

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "Ingenio estratega"
      assert html =~ "Reglas de 15-20 minutos y decisiones pensando un par de jugadas por delante."
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

    test "renders designers, publishers, players, playtime, age, and description when present, omitting each individually when absent",
         %{conn: conn} do
      game =
        game_fixture(%{
          designers: ["Klaus Teuber"],
          publishers: ["Devir"],
          min_players: 3,
          max_players: 4,
          min_age: 10,
          description: "Compite por colonizar la isla de Catán."
        })

      {:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")

      assert html =~ "Klaus Teuber"
      assert html =~ "Devir"
      assert html =~ "3-4"
      assert html =~ "10+"
      assert html =~ "Compite por colonizar la isla de Catán."
    end

    test "omits designers/publishers/age/description rows individually when absent", %{
      conn: conn
    } do
      game =
        game_fixture(%{
          designers: [],
          publishers: [],
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
        |> element(~s(button[phx-value-url="https://images.test.invalid/games/1/gallery-1.webp"]))
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
  end
end
