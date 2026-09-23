defmodule PukllayClubWeb.Admin.SectionLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures
  import PukllayClub.SectionsFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.Sections
  alias PukllayClub.Repo

  defp featured_section, do: Repo.get_by!(Section, featured: true)

  describe "SectionLive.Index — anonymous access" do
    test "an anonymous request redirects to /admin/ingresar", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/admin/ingresar"}}} = live(conn, ~p"/admin/secciones")
    end
  end

  describe "SectionLive.Index — Web opens on the destacada (D-00a, D-19l)" do
    setup :register_and_log_in_staff

    test "titles the page Web and shows the destacada's own name and games", %{conn: conn} do
      featured = featured_section()
      game = game_fixture(%{name: "Everdell"})
      add_game_to_section(featured, game)

      {:ok, _lv, html} = live(conn, ~p"/admin/secciones")

      assert html =~ "Web"
      assert html =~ featured.name
      assert html =~ "Everdell"
    end

    test "an empty destacada shows the empty-rail note", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/secciones")

      assert html =~ "Sin juegos, no se ve en el inicio."
    end

    test "Otras filas lists the non-featured sections with a kind tag and, for a manual section, a count",
         %{conn: conn} do
      manual = section_fixture(%{name: "Otra fila a mano", kind: :manual, sort: :manual})
      add_game_to_section(manual, game_fixture())

      {:ok, _lv, html} = live(conn, ~p"/admin/secciones")

      assert html =~ "Otras filas"
      assert html =~ manual.name
      assert html =~ "personalizada"
      assert html =~ "pk-admin-kind-tag"
      assert html =~ "pk-admin-count-pill"
      # D-19m: the count/kind pair is the neutral shapes, never the
      # top-right filled primary badge that means pending work (D-19g).
      refute html =~ "pk-admin-pending-pill"
    end

    test "an automatic (weight_band/recent) Otras fila carries the automática tag, no count pill",
         %{conn: conn} do
      automatic =
        section_fixture(%{name: "Nivel automático", kind: :weight_band, rule_value: "nivel_experto", sort: :name})

      {:ok, _lv, html} = live(conn, ~p"/admin/secciones")

      assert html =~ automatic.name
      assert html =~ "automática"
    end

    test "tapping an Otras fila row navigates to its own edit page", %{conn: conn} do
      other = section_fixture(%{name: "Movible"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      {:ok, _edit_lv, edit_html} =
        lv
        |> element("#other-section-#{other.id}")
        |> render_click()
        |> follow_redirect(conn)

      assert edit_html =~ "Movible"
    end
  end

  describe "SectionLive.Index — reorder (D-18, D-19, UI-SPEC Visual Hierarchy)" do
    setup :register_and_log_in_staff

    test "the featured row has no ↑/↓ controls in Otras filas; a non-featured row does", %{conn: conn} do
      featured = featured_section()
      section_fixture(%{name: "Movible"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      refute has_element?(lv, "button[aria-label='Subir #{featured.name}']")
      refute has_element?(lv, "button[aria-label='Bajar #{featured.name}']")
      assert has_element?(lv, "button[aria-label='Subir Movible']")
      assert has_element?(lv, "button[aria-label='Bajar Movible']")
    end

    test "pressing ↓ reorders the admin list and the home page's own order", %{conn: conn} do
      a = section_fixture(%{name: "Sección A", position: 500})
      b = section_fixture(%{name: "Sección B", position: 501})
      add_game_to_section(a, game_fixture(%{name: "Juego A"}))
      add_game_to_section(b, game_fixture(%{name: "Juego B"}))

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      lv
      |> element("button[phx-value-section-id='#{a.id}'][phx-click='move-down']")
      |> render_click()

      assert Repo.get!(Section, a.id).position == 501
      assert Repo.get!(Section, b.id).position == 500

      home_titles =
        Catalog.list_home_sections()
        |> Enum.filter(&(&1.section_id in [a.id, b.id]))
        |> Enum.map(& &1.title)

      assert home_titles == ["Sección B", "Sección A"]
    end
  end

  describe "SectionLive.Index — Ajustes «Mostrar en el inicio» (D-19l, T-01.8.2-65)" do
    setup :register_and_log_in_staff

    test "unchecking Mostrar en el inicio hides the destacada from the public home", %{conn: conn} do
      featured = featured_section()
      add_game_to_section(featured, game_fixture())

      {:ok, _home_lv, home_html_before} = live(build_conn(), ~p"/")
      assert home_html_before =~ featured.name

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")
      assert html =~ "Mostrar en el inicio"
      refute html =~ "Ocultar en la home"

      lv |> form("#web-ajustes-form", section: %{shown: "false"}) |> render_submit()

      {:ok, _home_lv, home_html} = live(build_conn(), ~p"/")
      refute home_html =~ featured.name
    end

    test "checking it back on shows it again", %{conn: conn} do
      featured = featured_section()
      add_game_to_section(featured, game_fixture())

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> form("#web-ajustes-form", section: %{shown: "false"}) |> render_submit()

      {:ok, _home_lv, hidden_html} = live(build_conn(), ~p"/")
      refute hidden_html =~ featured.name

      lv |> form("#web-ajustes-form", section: %{shown: "true"}) |> render_submit()

      {:ok, _home_lv, home_html} = live(build_conn(), ~p"/")
      assert home_html =~ featured.name
    end
  end

  describe "SectionLive.Index — member add/remove on the destacada (D-19k)" do
    setup :register_and_log_in_staff

    test "typing a name lists matching non-member, non-retired games; tapping adds it", %{conn: conn} do
      featured = featured_section()
      already_in = game_fixture(%{name: "Carcassonne en la fila"})
      add_game_to_section(featured, already_in)
      matching = game_fixture(%{name: "Carcassonne"})
      _retired = game_fixture(%{name: "Carcassonne Retirado", status: :retired})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      lv |> form("#web-search-form", %{q: "carc"}) |> render_change()

      assert has_element?(lv, "#web-search-result-#{matching.id}")
      refute has_element?(lv, "#web-search-result-#{already_in.id}")
      refute has_element?(lv, "#web-search-results", "Carcassonne Retirado")

      html =
        lv
        |> element("#web-search-result-#{matching.id}")
        |> render_click()

      assert html =~ "Carcassonne"
    end

    test "opening a cover's sheet and tapping Quitar de la fila removes it at once, no dialog, no Peligro",
         %{conn: conn} do
      featured = featured_section()
      game = game_fixture(%{name: "Everdell"})
      add_game_to_section(featured, game)

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")
      assert html =~ "Everdell"

      sheet_html =
        lv
        |> element("#web-cover-#{game.id}")
        |> render_click()

      assert sheet_html =~ "Quitar de la fila"
      refute sheet_html =~ "pk-admin-dialog"

      html =
        lv
        |> element("button[phx-click='remove-game'][phx-value-game-id='#{game.id}']")
        |> render_click()

      refute has_element?(lv, "#web-cover-#{game.id}")
      assert html =~ "quitado de la fila"
      assert html =~ ~s(data-timeout="10000")
      refute html =~ "pk-admin-dialog"
      refute html =~ "pk-admin-action--peligro"
    end

    test "Deshacer restores the removed game", %{conn: conn} do
      featured = featured_section()
      game = game_fixture(%{name: "Everdell"})
      add_game_to_section(featured, game)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-cover-#{game.id}") |> render_click()

      lv
      |> element("button[phx-click='remove-game'][phx-value-game-id='#{game.id}']")
      |> render_click()

      html = lv |> element("button[phx-click='undo-remove']") |> render_click()

      assert has_element?(lv, "#web-cover-#{game.id}")
      assert html =~ "Everdell"
    end

    test "at 20 members the featured screen shows the cap message", %{conn: conn} do
      featured = featured_section()

      for _ <- 1..20 do
        {:ok, _section} = Sections.add_game(featured, game_fixture().id)
      end

      extra = game_fixture(%{name: "Juego 21"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      lv |> form("#web-search-form", %{q: "Juego 21"}) |> render_change()

      html =
        lv
        |> element("#web-search-result-#{extra.id}")
        |> render_click()

      assert html =~ "La sección destacada ya tiene 20 juegos. Quitá uno para agregar otro."
    end
  end

  describe "SectionLive.Index — create (D-17, \"Crear sección\")" do
    setup :register_and_log_in_staff

    test "creating a section navigates to its own edit screen", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      {:ok, edit_lv, edit_html} =
        lv
        |> form("#create-section-form", name: "Spiel des Jahres")
        |> render_submit()
        |> follow_redirect(conn)

      assert edit_html =~ "Spiel des Jahres"
      assert edit_lv |> element("h1") |> render() =~ "Spiel des Jahres"
    end

    test "a blank name shows a validation error and stays on the list", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      html = lv |> form("#create-section-form", name: "") |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "SectionLive.Edit — anonymous access" do
    test "an anonymous request redirects to /admin/ingresar", %{conn: conn} do
      section = section_fixture()

      assert {:error, {:redirect, %{to: "/admin/ingresar"}}} =
               live(conn, ~p"/admin/secciones/#{section.id}")
    end
  end

  describe "SectionLive.Edit — rename and Ajustes «Mostrar en el inicio» (D-19l, T-01.8.2-65)" do
    setup :register_and_log_in_staff

    test "renaming a section makes the public home page render the new title", %{conn: conn} do
      section = section_fixture(%{name: "Vieja"})
      add_game_to_section(section, game_fixture(%{name: "Un juego"}))

      {:ok, lv, html} = live(conn, ~p"/admin/secciones/#{section.id}")
      assert html =~ "Mostrar en el inicio"
      refute html =~ "Ocultar en la home"

      html = lv |> form("#section-form", section: %{name: "Para arrancar", shown: "true"}) |> render_submit()
      assert html =~ "Fila guardada."

      {:ok, _home_lv, home_html} = live(build_conn(), ~p"/")
      assert home_html =~ "Para arrancar"
      refute home_html =~ "Vieja"
    end

    test "unchecking Mostrar en el inicio removes the section from the public home page", %{conn: conn} do
      section = section_fixture(%{name: "Se oculta"})
      add_game_to_section(section, game_fixture(%{name: "Otro juego"}))

      {:ok, _home_lv, home_html_before} = live(build_conn(), ~p"/")
      assert home_html_before =~ "Se oculta"

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")
      lv |> form("#section-form", section: %{shown: "false"}) |> render_submit()

      {:ok, _home_lv, home_html} = live(build_conn(), ~p"/")
      refute home_html =~ "Se oculta"
    end

    test "a 41-character name shows a validation error and does not save", %{conn: conn} do
      section = section_fixture(%{name: "Vieja"})
      too_long = String.duplicate("a", 41)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      html = lv |> form("#section-form", section: %{name: too_long, shown: "true"}) |> render_submit()

      assert html =~ "should be at most 40 character(s)"
    end

    test "a non-integer :id 404s", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/admin/secciones/not-an-id")
      end
    end
  end

  describe "SectionLive.Edit — sort select by kind (D-19, D-20, D-21)" do
    setup :register_and_log_in_staff

    test "a manual section's select offers all 5 sorts", %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :manual})

      {:ok, _lv, html} = live(conn, ~p"/admin/secciones/#{section.id}")

      assert html =~ "A mano"
      assert html =~ "Por nombre"
      assert html =~ "Por peso BGG"
      assert html =~ "Por puntaje BGG"
      assert html =~ "Recientes"
    end

    test "a weight_band section's select omits A mano", %{conn: conn} do
      section =
        section_fixture(%{kind: :weight_band, rule_value: "nivel_experto", sort: :name})

      {:ok, _lv, html} = live(conn, ~p"/admin/secciones/#{section.id}")

      refute html =~ "A mano"
      assert html =~ "Por nombre"
      assert html =~ "Los juegos de esta sección salen de su nivel."
    end

    test "a recent section shows fixed text instead of a select", %{conn: conn} do
      section = section_fixture(%{kind: :recent, sort: :recent})

      {:ok, _lv, html} = live(conn, ~p"/admin/secciones/#{section.id}")

      assert html =~ "Orden: más recientes primero"
      refute html =~ "<select"
    end

    test "setting a manual section's sort to Por nombre orders its home row by name", %{
      conn: conn
    } do
      section = section_fixture(%{kind: :manual, sort: :manual})
      zeta = game_fixture(%{name: "Zeta"})
      alfa = game_fixture(%{name: "Alfa"})
      add_game_to_section(section, zeta, 1)
      add_game_to_section(section, alfa, 2)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      lv |> form("#section-form", section: %{sort: "name", shown: "true"}) |> render_submit()

      home_row = Enum.find(Catalog.list_home_sections(), &(&1.section_id == section.id))
      assert Enum.map(home_row.games, & &1.name) == ["Alfa", "Zeta"]
    end
  end

  describe "SectionLive.Edit — member picker (D-25) and Quitar de la fila (D-19k)" do
    setup :register_and_log_in_staff

    test "typing a name lists matching non-retired games not already a member; tapping adds it",
         %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :manual})
      already_in = game_fixture(%{name: "Carcassonne en la sección"})
      add_game_to_section(section, already_in)
      matching = game_fixture(%{name: "Carcassonne"})
      _retired = game_fixture(%{name: "Carcassonne Retirado", status: :retired})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      lv |> form("#section-member-search", %{q: "carc"}) |> render_change()

      assert has_element?(lv, "#section-search-result-#{matching.id}")
      refute has_element?(lv, "#section-search-result-#{already_in.id}")
      refute has_element?(lv, "#section-search-results", "Carcassonne Retirado")

      html =
        lv
        |> element("#section-search-result-#{matching.id}")
        |> render_click()

      assert html =~ "Carcassonne en la sección"
      assert html =~ "Carcassonne"
    end

    test "a member row shows ↑/↓ when sort is manual", %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game = game_fixture(%{name: "Catán"})
      add_game_to_section(section, game)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      assert has_element?(lv, "button[aria-label='Subir Catán']")
      assert has_element?(lv, "button[aria-label='Bajar Catán']")
    end

    test "a member row hides ↑/↓ when sort is not manual", %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :name})
      game = game_fixture(%{name: "Catán"})
      add_game_to_section(section, game)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      refute has_element?(lv, "button[aria-label='Subir Catán']")
      refute has_element?(lv, "button[aria-label='Bajar Catán']")
    end

    test "Quitar de la fila removes at once, with a Deshacer snackbar and no dialog", %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game = game_fixture(%{name: "Catán"})
      add_game_to_section(section, game)

      {:ok, lv, html} = live(conn, ~p"/admin/secciones/#{section.id}")
      assert html =~ "Catán"
      assert html =~ "Quitar de la fila"

      html =
        lv
        |> element("button[phx-click='remove-game'][phx-value-game-id='#{game.id}']")
        |> render_click()

      refute has_element?(lv, "#section-member-#{game.id}")
      assert html =~ "quitado de la fila"
      assert html =~ ~s(data-timeout="10000")
      refute html =~ "pk-admin-dialog"
      refute html =~ "pk-admin-action--peligro"
    end

    test "Deshacer restores the removed member", %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game = game_fixture(%{name: "Catán"})
      add_game_to_section(section, game)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      lv
      |> element("button[phx-click='remove-game'][phx-value-game-id='#{game.id}']")
      |> render_click()

      lv |> element("button[phx-click='undo-remove']") |> render_click()

      assert has_element?(lv, "#section-member-#{game.id}")
    end

    test "at 20 members the featured screen shows the cap message", %{conn: conn} do
      featured = featured_section()

      for _ <- 1..20 do
        {:ok, _section} = Sections.add_game(featured, game_fixture().id)
      end

      extra = game_fixture(%{name: "Juego 21"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{featured.id}")

      lv |> form("#section-member-search", %{q: "Juego 21"}) |> render_change()

      html =
        lv
        |> element("#section-search-result-#{extra.id}")
        |> render_click()

      assert html =~ "La sección destacada ya tiene 20 juegos. Quitá uno para agregar otro."
    end
  end
end
