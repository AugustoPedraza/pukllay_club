defmodule PukllayClubWeb.Admin.EstanteLiveTest do
  @moduledoc """
  D-08's search-first Estantes screen (plan 01.8.2-13, rebuilding the
  01.8.2-01 tracer this replaces). This slice (Task 1 of 3) covers the
  idle prompt+field at rest and the search dropdown (recent/suggestions/
  no-match). The answered state's rail (D-03/D-04's accessible-name
  contract) and D-11's live-update behaviour are Task 2 and Task 3's own
  additions to this same file.
  """
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures
  import PukllayClub.CopiesFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Catalog.Shelves

  describe "GET /admin/estantes — signed-out visitor (T-01.8.2-03)" do
    test "is redirected to the login path", %{conn: conn} do
      conn = get(conn, ~p"/admin/estantes")
      assert redirected_to(conn) == ~p"/admin/ingresar"
    end
  end

  describe "GET /admin/estantes/1/asignar — superseded route (D-08)" do
    test "returns 404", %{conn: conn} do
      assert %{status: 404} = get(conn, "/admin/estantes/1/asignar")
    end
  end

  describe "the idle state (D-08, D-19j)" do
    setup :register_and_log_in_staff

    test "renders the prompt and the field, and nothing else below (D-19j)", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/estantes")

      assert html =~ "¿Qué juego buscás?"
      assert html =~ "Buscá un juego"
      assert html =~ "Todavía no buscaste ningún juego."

      refute html =~ "pk-rail\""
      refute html =~ "estante-copy-"
      refute html =~ "estantes-suggestions"
    end

    test "renders no estante list and no pending-game list", %{conn: conn} do
      shelf_fixture(%{name: "Estante Norte"})
      copy_fixture(%{game_id: game_fixture(%{name: "Sin lugar aún"}).id})

      {:ok, _lv, html} = live(conn, ~p"/admin/estantes")

      refute html =~ "Estante Norte"
      refute html =~ "Sin lugar aún"
    end

    test "the header renders the Pendientes A3 icon before the gear icon, with no badge at 0",
         %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/estantes")

      pendientes_at = html |> :binary.match("Pendientes") |> elem(0)
      gear_at = html |> :binary.match("Administrar estantes") |> elem(0)
      assert pendientes_at < gear_at

      refute html =~ "pk-estantes-icon-badge__count"
    end

    test "the Pendientes badge count is Shelves.unplaced_copies/0's length", %{conn: conn} do
      copy_fixture(%{game_id: game_fixture(%{name: "Uno"}).id})
      copy_fixture(%{game_id: game_fixture(%{name: "Dos"}).id})

      {:ok, _lv, html} = live(conn, ~p"/admin/estantes")

      assert length(Shelves.unplaced_copies()) == 2
      assert html =~ "pk-estantes-icon-badge__count"
      assert html =~ ~r/pk-estantes-icon-badge__count[^<]*>\s*2\s*</
    end
  end

  describe "typing shows suggestions (D-08)" do
    setup :register_and_log_in_staff

    test "a match renders cover, name and the estante name", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      game = game_fixture(%{name: "Catán"})
      copy = copy_fixture(%{game_id: game.id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      html = render_change(lv, "search", %{"q" => "cat"})

      assert html =~ "Catán"
      assert html =~ "Estante Norte"
    end

    test "an unplaced match renders the Sin lugar status dot, never a pill", %{conn: conn} do
      game = game_fixture(%{name: "Dixit"})
      copy_fixture(%{game_id: game.id})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      html = render_change(lv, "search", %{"q" => "dix"})

      assert html =~ "Dixit"
      assert html =~ "pk-admin-status-dot--sin_lugar"
      assert html =~ "Sin lugar"

      # D-19h: never a pill for a status.
      refute html =~ "pk-admin-pending-pill"
      refute html =~ "pk-admin-count-pill"
    end

    test "a query with no match renders exactly one Crear « row", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      html = render_change(lv, "search", %{"q" => "zzzznomatch"})

      assert html =~ "Ningún juego se llama así."
      assert html |> String.split("Crear «") |> length() == 2
      assert html =~ "Crear «zzzznomatch»"
    end

    test "the suggestion query is capped at 120 characters and never crashes on a long input",
         %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      long_query = String.duplicate("a", 500)

      html = render_change(lv, "search", %{"q" => long_query})

      assert html =~ "Ningún juego se llama así."
    end
  end
end
