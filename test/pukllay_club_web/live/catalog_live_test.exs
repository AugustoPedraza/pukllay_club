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

    test "clamps a long game title instead of pushing the card layout", %{conn: conn} do
      game_fixture(%{
        name: "Un título extraordinariamente largo que debería ocupar más de dos líneas de texto"
      })

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "line-clamp-2"
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

      assert position(html, "Alfa Corto") < position(html, "Zeta Largo")

      html2 =
        view
        |> element("select[name=sort]")
        |> render_change(%{sort: "playtime_desc"})

      assert position(html2, "Zeta Largo") < position(html2, "Alfa Corto")
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

  defp position(html, text) do
    case :binary.match(html, text) do
      {pos, _} -> pos
      :nomatch -> flunk("expected #{inspect(text)} to be present in the rendered HTML")
    end
  end

  defp card_count(html) do
    html
    |> String.split("card bg-base-200")
    |> length()
    |> Kernel.-(1)
  end
end
