defmodule PukllayClubWeb.Admin.EstanteLiveTest do
  @moduledoc """
  D-08's search-first Estantes screen (plan 01.8.2-13, rebuilding the
  01.8.2-01 tracer this replaces): the idle prompt+field at rest, the
  search dropdown (recent/suggestions/no-match), the answered state's
  rail — reusing `Shelves.copies_on_shelf/1`'s real `position` order and
  D-03/D-04's accessible-name contract — and D-11's live-update behaviour
  over `"admin:estantes"` broadcasts.
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

  describe "picking a suggestion — the answered state (D-08, D-03, D-04)" do
    setup :register_and_log_in_staff

    test "the field keeps the name, the estante shows as context, and the rail renders in position order",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})

      c0 = copy_fixture(%{game_id: game_fixture(%{name: "Primero"}).id})
      c1 = copy_fixture(%{game_id: game_fixture(%{name: "Segundo"}).id})
      c2 = copy_fixture(%{game_id: game_fixture(%{name: "Tercero"}).id})

      {:ok, _} = Shelves.place_copy(c0.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(c1.id, shelf.id, 1)
      {:ok, _} = Shelves.place_copy(c2.id, shelf.id, 2)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "tercero"})
      html = lv |> element("#suggestion-#{c2.id}") |> render_click()

      assert html =~ ~s(value="Tercero")
      assert html =~ "Estante Norte"

      i0 = html |> :binary.match("estante-copy-#{c0.id}") |> elem(0)
      i1 = html |> :binary.match("estante-copy-#{c1.id}") |> elem(0)
      i2 = html |> :binary.match("estante-copy-#{c2.id}") |> elem(0)
      assert i0 < i1
      assert i1 < i2

      assert html =~ "Tercero, caja 3 de 3"
    end

    test "a cover's accessible name matches caja 3 de 7 for the third of seven boxes",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Grande"})
      target = game_fixture(%{name: "Objetivo"})
      target_copy = copy_fixture(%{game_id: target.id})

      Enum.each(1..7, fn n ->
        copy =
          if n == 3, do: target_copy, else: copy_fixture(%{game_id: game_fixture(%{name: "G#{n}"}).id})

        {:ok, _} = Shelves.place_copy(copy.id, shelf.id, n - 1)
      end)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "objetivo"})
      html = lv |> element("#suggestion-#{target_copy.id}") |> render_click()

      assert html =~ "Objetivo, caja 3 de 7"
    end

    test "the selected cover carries the lift class and the others do not", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Sur"})
      c0 = copy_fixture(%{game_id: game_fixture(%{name: "Uno"}).id})
      c1 = copy_fixture(%{game_id: game_fixture(%{name: "Dos"}).id})
      {:ok, _} = Shelves.place_copy(c0.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(c1.id, shelf.id, 1)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "uno"})
      html = lv |> element("#suggestion-#{c0.id}") |> render_click()

      [_, c0_tag] = String.split(html, ~s(id="estante-copy-#{c0.id}"), parts: 2)
      [_, c1_tag] = String.split(html, ~s(id="estante-copy-#{c1.id}"), parts: 2)

      assert String.slice(c0_tag, 0, 120) =~ "pk-estantes-cover--lifted"
      refute String.slice(c1_tag, 0, 120) =~ "pk-estantes-cover--lifted"
    end

    test "a game with two copies renders copia 1 de 2; a game with one copy renders no copia string",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Este"})
      multi = game_fixture(%{name: "Multi"})
      solo = game_fixture(%{name: "Solo"})

      m1 = copy_fixture(%{game_id: multi.id})
      _m2 = copy_fixture(%{game_id: multi.id})
      s1 = copy_fixture(%{game_id: solo.id})

      {:ok, _} = Shelves.place_copy(m1.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(s1.id, shelf.id, 1)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "multi"})
      html = lv |> element("#suggestion-#{m1.id}") |> render_click()

      assert html =~ "Multi, copia #{m1.number} de 2, caja 1 de 2"
      assert html =~ "Solo, caja 2 de 2"
      refute html =~ "Solo, copia"
    end

    test "exactly one search input renders in idle, searching and answered states", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Oeste"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Único"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      {:ok, lv, idle_html} = live(conn, ~p"/admin/estantes")
      assert count_occurrences(idle_html, ~s(id="estantes-search-input")) == 1

      searching_html = render_change(lv, "search", %{"q" => "úni"})
      assert count_occurrences(searching_html, ~s(id="estantes-search-input")) == 1

      answered_html = lv |> element("#suggestion-#{copy.id}") |> render_click()
      assert count_occurrences(answered_html, ~s(id="estantes-search-input")) == 1
    end

    test "picking a copy with no spot does not render an empty rail", %{conn: conn} do
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Sin lugar todavía"}).id})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "sin lugar"})
      html = lv |> element("#suggestion-#{copy.id}") |> render_click()

      refute html =~ "pk-rail-wrap"
      refute html =~ "id=\"estantes-rail\""
      assert html =~ "no tiene lugar todavía"

      # The event this placeholder wires (plan 01.8.2-16 replaces it).
      assert lv |> element("#estantes-open-donde-va") |> render_click() =~ "no tiene lugar todavía"
    end

    test "the ✕ clears the query and the selection, returning to idle", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Volver"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "volver"})
      lv |> element("#suggestion-#{copy.id}") |> render_click()

      html = lv |> element(".pk-estantes-search__clear") |> render_click()

      assert html =~ "¿Qué juego buscás?"
      refute html =~ "estante-copy-#{copy.id}"
    end
  end

  describe "Últimas búsquedas (D-08)" do
    setup :register_and_log_in_staff

    test "picking a copy adds it to Últimas búsquedas, visible after clearing", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Recordado"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "recordado"})
      lv |> element("#suggestion-#{copy.id}") |> render_click()

      html = lv |> element(".pk-estantes-search__clear") |> render_click()

      assert html =~ "Últimas búsquedas"
      assert html =~ ~s(id="recent-#{copy.id}")
      assert html =~ "Recordado"
    end
  end

  describe "live updates (D-11, plan 01.8.2-13 Task 3)" do
    setup :register_and_log_in_staff

    test "a broadcast for the shown estante re-renders the rail", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      c0 = copy_fixture(%{game_id: game_fixture(%{name: "Primero"}).id})
      {:ok, _} = Shelves.place_copy(c0.id, shelf.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "primero"})
      lv |> element("#suggestion-#{c0.id}") |> render_click()

      c1 = copy_fixture(%{game_id: game_fixture(%{name: "Segundo"}).id})
      {:ok, _} = Shelves.place_copy(c1.id, shelf.id, 1)

      assert render(lv) =~ "estante-copy-#{c1.id}"
    end

    test "a broadcast for a different estante leaves the rail's rendered order and selection unchanged",
         %{conn: conn} do
      shelf_a = shelf_fixture(%{name: "Estante A"})
      shelf_b = shelf_fixture(%{name: "Estante B"})
      c0 = copy_fixture(%{game_id: game_fixture(%{name: "Quedate"}).id})
      {:ok, _} = Shelves.place_copy(c0.id, shelf_a.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "quedate"})
      before_html = lv |> element("#suggestion-#{c0.id}") |> render_click()

      other = copy_fixture(%{game_id: game_fixture(%{name: "Otro"}).id})
      {:ok, _} = Shelves.place_copy(other.id, shelf_b.id, 0)

      after_html = render(lv)
      assert after_html =~ "Estante A"
      refute after_html =~ "Otro"
      assert before_html =~ "estante-copy-#{c0.id}"
      assert after_html =~ "estante-copy-#{c0.id}"
    end

    test "a broadcast moving the selected copy elsewhere renders a snackbar with no action",
         %{conn: conn} do
      shelf_a = shelf_fixture(%{name: "Estante A"})
      shelf_b = shelf_fixture(%{name: "Estante B"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Movido"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf_a.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "movido"})
      lv |> element("#suggestion-#{copy.id}") |> render_click()

      {:ok, _} = Shelves.place_copy(copy.id, shelf_b.id, 0)

      html = render(lv)
      assert html =~ "cambió de lugar"
      assert html =~ ~s(data-timeout="4000")
    end
  end

  defp count_occurrences(haystack, needle) do
    haystack
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end
end
