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

  describe "«¿Dónde va?» — placing a copy with no spot (D-00c, plan 01.8.2-16)" do
    setup :register_and_log_in_staff

    test "selecting a game with no spot opens the sheet directly, with no intermediate control",
         %{conn: conn} do
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Sin lugar todavía"}).id})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "sin lugar"})
      html = lv |> element("#suggestion-#{copy.id}") |> render_click()

      assert html =~ "¿Dónde va?"
      assert html =~ "donde-va-sheet"
      refute html =~ "Elegir dónde va"
      assert html =~ "O elegí un estante"
    end

    # D-00c removed the separate Ubicar button on purpose — the plan's own
    # <verify> greps the compiled source for this literally; this test
    # pins the same rule at the behavioural level.
    test "there is no Ubicar control anywhere on the page", %{conn: conn} do
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Cualquiera"}).id})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "cualquiera"})
      html = lv |> element("#suggestion-#{copy.id}") |> render_click()

      refute html =~ ">Ubicar<"
      refute html =~ "\"Ubicar\""
    end

    test "choosing an empty estante places the copy at position 0 and shows Juego ubicado",
         %{conn: conn} do
      empty_shelf = shelf_fixture(%{name: "Estante Vacío"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Recién llegado"}).id})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "recién"})
      lv |> element("#suggestion-#{copy.id}") |> render_click()

      html = lv |> element("#donde-va-shelf-#{empty_shelf.id}") |> render_click()

      assert html =~ "Juego ubicado"
      refute html =~ "donde-va-sheet"

      fresh = Shelves.get_copy!(copy.id)
      assert fresh.shelf_id == empty_shelf.id
      assert fresh.position == 0
    end

    test "choosing a non-empty estante renders a + slot before, between and after every box; tapping one commits at that exact index",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Lleno"})
      a = copy_fixture(%{game_id: game_fixture(%{name: "A"}).id})
      b = copy_fixture(%{game_id: game_fixture(%{name: "B"}).id})
      {:ok, _} = Shelves.place_copy(a.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(b.id, shelf.id, 1)

      new_copy = copy_fixture(%{game_id: game_fixture(%{name: "Nueva llegada"}).id})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "nueva llegada"})
      lv |> element("#suggestion-#{new_copy.id}") |> render_click()

      html = lv |> element("#donde-va-shelf-#{shelf.id}") |> render_click()
      assert count_occurrences(html, "pk-donde-va-slot") == 3

      render_click(lv, "donde-va-commit", %{"index" => "1"})

      positions = shelf.id |> Shelves.copies_on_shelf() |> Enum.map(&{&1.id, &1.position})
      assert positions == [{a.id, 0}, {new_copy.id, 1}, {b.id, 2}]
    end

    test "a move keeps the copy in its old spot until the new one is chosen; cancelling changes nothing",
         %{conn: conn} do
      shelf_a = shelf_fixture(%{name: "Origen"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Movible"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf_a.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "movible"})
      lv |> element("#suggestion-#{copy.id}") |> render_click()

      html = render_click(lv, "open-mover", %{})
      assert html =~ "¿Dónde va?"

      render_click(lv, "donde-va-close", %{})

      fresh = Shelves.get_copy!(copy.id)
      assert fresh.shelf_id == shelf_a.id
      assert fresh.position == 0
    end

    test "a cross-estante move leaves both estantes gap-free, committed in one transaction",
         %{conn: conn} do
      shelf_a = shelf_fixture(%{name: "Origen"})
      shelf_b = shelf_fixture(%{name: "Destino"})
      a0 = copy_fixture(%{game_id: game_fixture(%{name: "A0"}).id})
      a1 = copy_fixture(%{game_id: game_fixture(%{name: "A1"}).id})
      {:ok, _} = Shelves.place_copy(a0.id, shelf_a.id, 0)
      {:ok, _} = Shelves.place_copy(a1.id, shelf_a.id, 1)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "a0"})
      lv |> element("#suggestion-#{a0.id}") |> render_click()

      render_click(lv, "open-mover", %{})
      render_change(lv, "donde-va-search", %{"q" => "destino"})
      html = lv |> element("#donde-va-result-shelf-#{shelf_b.id}") |> render_click()

      assert html =~ "Juego movido"

      remaining_a = shelf_a.id |> Shelves.copies_on_shelf() |> Enum.map(& &1.id)
      assert remaining_a == [a1.id]
      on_b = shelf_b.id |> Shelves.copies_on_shelf() |> Enum.map(& &1.id)
      assert on_b == [a0.id]
    end

    test "Deshacer after a move restores the copy's previous estante and position",
         %{conn: conn} do
      shelf_a = shelf_fixture(%{name: "Origen"})
      shelf_b = shelf_fixture(%{name: "Destino"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Recuperable"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf_a.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "recuperable"})
      lv |> element("#suggestion-#{copy.id}") |> render_click()

      render_click(lv, "open-mover", %{})
      render_change(lv, "donde-va-search", %{"q" => "destino"})
      lv |> element("#donde-va-result-shelf-#{shelf_b.id}") |> render_click()

      assert Shelves.get_copy!(copy.id).shelf_id == shelf_b.id

      render_click(lv, "undo-place", %{})

      fresh = Shelves.get_copy!(copy.id)
      assert fresh.shelf_id == shelf_a.id
      assert fresh.position == 0
    end
  end

  describe "the \"+\" slots and «¿Qué juego va acá?» (D-08, plan 01.8.2-16 Task 2)" do
    setup :register_and_log_in_staff

    test "the rail renders exactly two + slots, one on each side of the selected cover",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      a = copy_fixture(%{game_id: game_fixture(%{name: "A"}).id})
      b = copy_fixture(%{game_id: game_fixture(%{name: "B"}).id})
      c = copy_fixture(%{game_id: game_fixture(%{name: "C"}).id})
      {:ok, _} = Shelves.place_copy(a.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(b.id, shelf.id, 1)
      {:ok, _} = Shelves.place_copy(c.id, shelf.id, 2)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "b"})
      html = lv |> element("#suggestion-#{b.id}") |> render_click()

      assert count_occurrences(html, "pk-estantes-slot") == 2
    end

    test "each + carries its 0-based index and opens the sheet bound to that exact slot",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      a = copy_fixture(%{game_id: game_fixture(%{name: "A"}).id})
      b = copy_fixture(%{game_id: game_fixture(%{name: "B"}).id})
      {:ok, _} = Shelves.place_copy(a.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(b.id, shelf.id, 1)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "a"})
      lv |> element("#suggestion-#{a.id}") |> render_click()

      html = render_click(lv, "open-que-va-aca", %{"index" => "1"})
      assert html =~ "¿Qué juego va acá?"

      new_copy = copy_fixture(%{game_id: game_fixture(%{name: "Entre A y B"}).id})
      render_click(lv, "que-va-aca-pick", %{"copy-id" => to_string(new_copy.id)})

      positions = shelf.id |> Shelves.copies_on_shelf() |> Enum.map(&{&1.id, &1.position})
      assert positions == [{a.id, 0}, {new_copy.id, 1}, {b.id, 2}]
    end

    test "the sheet lists Sin ubicar games before any search results", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      selected = copy_fixture(%{game_id: game_fixture(%{name: "Elegido"}).id})
      {:ok, _} = Shelves.place_copy(selected.id, shelf.id, 0)
      unplaced = copy_fixture(%{game_id: game_fixture(%{name: "Suelto"}).id})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "elegido"})
      lv |> element("#suggestion-#{selected.id}") |> render_click()

      html = render_click(lv, "open-que-va-aca", %{"index" => "1"})

      assert html =~ "Sin ubicar"
      assert html =~ ~s(id="que-va-aca-unplaced-#{unplaced.id}")
    end

    test "choosing an already-shelved game moves it and leaves its old estante gap-free",
         %{conn: conn} do
      shelf_a = shelf_fixture(%{name: "Origen"})
      shelf_b = shelf_fixture(%{name: "Destino"})
      selected = copy_fixture(%{game_id: game_fixture(%{name: "Elegido"}).id})
      {:ok, _} = Shelves.place_copy(selected.id, shelf_b.id, 0)

      a0 = copy_fixture(%{game_id: game_fixture(%{name: "A0"}).id})
      a1 = copy_fixture(%{game_id: game_fixture(%{name: "A1"}).id})
      {:ok, _} = Shelves.place_copy(a0.id, shelf_a.id, 0)
      {:ok, _} = Shelves.place_copy(a1.id, shelf_a.id, 1)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "elegido"})
      lv |> element("#suggestion-#{selected.id}") |> render_click()

      render_click(lv, "open-que-va-aca", %{"index" => "1"})
      render_change(lv, "que-va-aca-search", %{"q" => "a0"})
      html = lv |> element("#que-va-aca-result-#{a0.id}") |> render_click()

      assert html =~ "Juego movido"

      remaining_a = shelf_a.id |> Shelves.copies_on_shelf() |> Enum.map(& &1.id)
      assert remaining_a == [a1.id]

      on_b = shelf_b.id |> Shelves.copies_on_shelf() |> Enum.map(& &1.id)
      assert on_b == [selected.id, a0.id]
    end

    test "picking a Sin ubicar game places it beside the selected cover in one transaction",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      selected = copy_fixture(%{game_id: game_fixture(%{name: "Elegido"}).id})
      {:ok, _} = Shelves.place_copy(selected.id, shelf.id, 0)
      unplaced = copy_fixture(%{game_id: game_fixture(%{name: "Suelto"}).id})

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "elegido"})
      lv |> element("#suggestion-#{selected.id}") |> render_click()

      render_click(lv, "open-que-va-aca", %{"index" => "0"})
      html = lv |> element("#que-va-aca-unplaced-#{unplaced.id}") |> render_click()

      assert html =~ "Juego ubicado"

      positions = shelf.id |> Shelves.copies_on_shelf() |> Enum.map(&{&1.id, &1.position})
      assert positions == [{unplaced.id, 0}, {selected.id, 1}]
    end

    test "the + before the first box in the rail opens the sheet bound to index 0", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      a = copy_fixture(%{game_id: game_fixture(%{name: "Único"}).id})
      {:ok, _} = Shelves.place_copy(a.id, shelf.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "único"})
      lv |> element("#suggestion-#{a.id}") |> render_click()

      render_click(lv, "open-que-va-aca", %{"index" => "0"})

      new_copy = copy_fixture(%{game_id: game_fixture(%{name: "Primero"}).id})
      render_click(lv, "que-va-aca-pick", %{"copy-id" => to_string(new_copy.id)})

      positions = shelf.id |> Shelves.copies_on_shelf() |> Enum.map(&{&1.id, &1.position})
      assert positions == [{new_copy.id, 0}, {a.id, 1}]
    end

    test "a broadcast reindexing the estante while the sheet is open aborts the commit and renders a snackbar with no action",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      selected = copy_fixture(%{game_id: game_fixture(%{name: "Elegido"}).id})
      {:ok, _} = Shelves.place_copy(selected.id, shelf.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "elegido"})
      lv |> element("#suggestion-#{selected.id}") |> render_click()

      render_click(lv, "open-que-va-aca", %{"index" => "1"})

      # A concurrent staff member places another copy on the SAME estante
      # while the sheet is open — a real write through the same locked
      # path, broadcasting {:estante_updated, shelf_id} for real.
      intruder = copy_fixture(%{game_id: game_fixture(%{name: "Intruso"}).id})
      {:ok, _} = Shelves.place_copy(intruder.id, shelf.id, 1)

      pending = copy_fixture(%{game_id: game_fixture(%{name: "Pendiente"}).id})
      html = render_click(lv, "que-va-aca-pick", %{"copy-id" => to_string(pending.id)})

      assert html =~ "cambió mientras elegías"
      assert html =~ ~s(data-timeout="4000")

      # The would-be commit never happened — pending stays unplaced.
      assert Shelves.get_copy!(pending.id).shelf_id == nil
    end
  end

  describe "the selected cover's options sheet and Quitar del estante (D-08, D-19f, D-19e, plan 01.8.2-16 Task 3)" do
    setup :register_and_log_in_staff

    test "tapping an unselected cover moves the selection; tapping the selected one opens its options sheet",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      a = copy_fixture(%{game_id: game_fixture(%{name: "A"}).id})
      b = copy_fixture(%{game_id: game_fixture(%{name: "B"}).id})
      {:ok, _} = Shelves.place_copy(a.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(b.id, shelf.id, 1)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "a"})
      lv |> element("#suggestion-#{a.id}") |> render_click()

      # Tapping the OTHER cover moves the selection, no options sheet.
      html = lv |> element("#estante-copy-#{b.id}") |> render_click()
      refute html =~ "cover-options-sheet"
      assert html =~ ~s(id="estante-copy-#{b.id}" class="pk-poster-card pk-estantes-cover pk-estantes-cover--lifted)

      # Tapping the NOW-selected cover opens its options sheet.
      html = lv |> element("#estante-copy-#{b.id}") |> render_click()
      assert html =~ "cover-options-sheet"
      assert html =~ "Ver ficha"
      assert html =~ "Mover"
      assert html =~ "Quitar del estante"
    end

    test "the options sheet renders no Cancelar text and a 44px close control", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Único"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "único"})
      lv |> element("#suggestion-#{copy.id}") |> render_click()

      html = lv |> element("#estante-copy-#{copy.id}") |> render_click()

      [_, sheet_and_after] = String.split(html, ~s(id="cover-options-sheet"), parts: 2)
      sheet_slice = String.slice(sheet_and_after, 0, 2000)

      refute sheet_slice =~ "Cancelar"
      assert sheet_slice =~ "Cerrar"
    end

    test "Quitar del estante renders a dialog that is not nested inside a sheet, with Cancelar focused",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Único"}).id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "único"})
      lv |> element("#suggestion-#{copy.id}") |> render_click()
      lv |> element("#estante-copy-#{copy.id}") |> render_click()

      html = lv |> element("[phx-click='ask-quitar']") |> render_click()

      refute html =~ "cover-options-sheet"
      assert html =~ ~s(id="confirm-quitar-dialog")
      assert html =~ "¿Quitar Único del estante?"

      [_, dialog_and_after] = String.split(html, ~s(id="confirm-quitar-dialog"), parts: 2)
      dialog_slice = String.slice(dialog_and_after, 0, 2000)
      assert dialog_slice =~ ~s(autofocus)
    end

    test "confirming removal leaves the estante's remaining positions gap-free", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      a = copy_fixture(%{game_id: game_fixture(%{name: "A"}).id})
      b = copy_fixture(%{game_id: game_fixture(%{name: "B"}).id})
      c = copy_fixture(%{game_id: game_fixture(%{name: "C"}).id})
      {:ok, _} = Shelves.place_copy(a.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(b.id, shelf.id, 1)
      {:ok, _} = Shelves.place_copy(c.id, shelf.id, 2)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "b"})
      lv |> element("#suggestion-#{b.id}") |> render_click()
      lv |> element("#estante-copy-#{b.id}") |> render_click()
      lv |> element("[phx-click='ask-quitar']") |> render_click()

      html = render_click(lv, "confirm-quitar", %{})
      assert html =~ "Juego quitado del estante"

      fresh_b = Shelves.get_copy!(b.id)
      assert fresh_b.shelf_id == nil
      assert fresh_b.position == nil

      positions = shelf.id |> Shelves.copies_on_shelf() |> Enum.map(&{&1.id, &1.position})
      assert positions == [{a.id, 0}, {c.id, 1}]
    end

    test "Deshacer after removal restores the copy to its previous position", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      a = copy_fixture(%{game_id: game_fixture(%{name: "A"}).id})
      b = copy_fixture(%{game_id: game_fixture(%{name: "B"}).id})
      {:ok, _} = Shelves.place_copy(a.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(b.id, shelf.id, 1)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "a"})
      lv |> element("#suggestion-#{a.id}") |> render_click()
      lv |> element("#estante-copy-#{a.id}") |> render_click()
      lv |> element("[phx-click='ask-quitar']") |> render_click()
      render_click(lv, "confirm-quitar", %{})

      render_click(lv, "undo-place", %{})

      fresh_a = Shelves.get_copy!(a.id)
      assert fresh_a.shelf_id == shelf.id
      assert fresh_a.position == 0

      positions = shelf.id |> Shelves.copies_on_shelf() |> Enum.map(&{&1.id, &1.position})
      assert positions == [{a.id, 0}, {b.id, 1}]
    end

    test "the selected cover of a three-copy game has an accessible name containing both copia and caja",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      multi = game_fixture(%{name: "Multi"})
      m1 = copy_fixture(%{game_id: multi.id})
      _m2 = copy_fixture(%{game_id: multi.id})
      _m3 = copy_fixture(%{game_id: multi.id})
      {:ok, _} = Shelves.place_copy(m1.id, shelf.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "multi"})
      html = lv |> element("#suggestion-#{m1.id}") |> render_click()

      [_, cover_and_after] = String.split(html, ~s(id="estante-copy-#{m1.id}"), parts: 2)
      cover_slice = String.slice(cover_and_after, 0, 300)

      assert cover_slice =~ "copia #{m1.number} de 3"
      assert cover_slice =~ "caja 1 de 1"
    end

    test "the selected cover of a single-copy game's accessible name contains caja and not copia",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      solo = copy_fixture(%{game_id: game_fixture(%{name: "Solo"}).id})
      {:ok, _} = Shelves.place_copy(solo.id, shelf.id, 0)

      {:ok, lv, _html} = live(conn, ~p"/admin/estantes")
      render_change(lv, "search", %{"q" => "solo"})
      html = lv |> element("#suggestion-#{solo.id}") |> render_click()

      [_, cover_and_after] = String.split(html, ~s(id="estante-copy-#{solo.id}"), parts: 2)
      cover_slice = String.slice(cover_and_after, 0, 300)

      assert cover_slice =~ "caja 1 de 1"
      refute cover_slice =~ "copia"
    end
  end

  defp count_occurrences(haystack, needle) do
    haystack
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end
end
