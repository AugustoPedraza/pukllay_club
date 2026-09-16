defmodule PukllayClubWeb.Admin.SectionLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures
  import PukllayClub.SectionsFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.Sections
  alias PukllayClub.Repo

  describe "SectionLive.Index — anonymous access" do
    test "an anonymous request redirects to /admin/ingresar", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/admin/ingresar"}}} = live(conn, ~p"/admin/secciones")
    end
  end

  describe "SectionLive.Index — list (D-17, D-18, UI-SPEC E6)" do
    setup :register_and_log_in_staff

    test "shows every section with a kind hint, and Oculta/Destacada badges", %{conn: conn} do
      # The migration's own D-22 backfill already seeds a featured
      # section ("Destacados del club") and 3 weight_band + 1 recent
      # section — the partial unique index allows only one featured
      # section, so this test creates only a hidden manual section of
      # its own and asserts against the pre-seeded rows for the rest.
      section_fixture(%{name: "Vieja sección propia", hidden: true})

      {:ok, _lv, html} = live(conn, ~p"/admin/secciones")

      assert html =~ "Destacados del club"
      assert html =~ "Destacada"
      assert html =~ "Vieja sección propia"
      assert html =~ "Oculta"
      assert html =~ "Elegida a mano"
      assert html =~ "Por nivel"
      assert html =~ "Recientes"
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

  describe "SectionLive.Index — reorder (D-18, D-19, UI-SPEC Visual Hierarchy)" do
    setup :register_and_log_in_staff

    test "the featured row has no ↑/↓ controls; a non-featured row does", %{conn: conn} do
      section_fixture(%{name: "Movible"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      refute has_element?(lv, "button[aria-label='Subir Destacados del club']")
      refute has_element?(lv, "button[aria-label='Bajar Destacados del club']")
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

  describe "SectionLive.Edit — anonymous access" do
    test "an anonymous request redirects to /admin/ingresar", %{conn: conn} do
      section = section_fixture()

      assert {:error, {:redirect, %{to: "/admin/ingresar"}}} =
               live(conn, ~p"/admin/secciones/#{section.id}")
    end
  end

  describe "SectionLive.Edit — rename and hide (D-17, UI-SPEC E6)" do
    setup :register_and_log_in_staff

    test "renaming a section makes the public home page render the new title", %{conn: conn} do
      section = section_fixture(%{name: "Vieja"})
      add_game_to_section(section, game_fixture(%{name: "Un juego"}))

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      html = lv |> form("#section-form", section: %{name: "Para arrancar"}) |> render_submit()
      assert html =~ "Sección guardada."

      {:ok, _home_lv, home_html} = live(build_conn(), ~p"/")
      assert home_html =~ "Para arrancar"
      refute home_html =~ "Vieja"
    end

    test "hiding a section removes it from the public home page", %{conn: conn} do
      section = section_fixture(%{name: "Se oculta"})
      add_game_to_section(section, game_fixture(%{name: "Otro juego"}))

      {:ok, _home_lv, home_html_before} = live(build_conn(), ~p"/")
      assert home_html_before =~ "Se oculta"

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")
      lv |> form("#section-form", section: %{hidden: "true"}) |> render_submit()

      {:ok, _home_lv, home_html} = live(build_conn(), ~p"/")
      refute home_html =~ "Se oculta"
    end

    test "a 41-character name shows a validation error and does not save", %{conn: conn} do
      section = section_fixture(%{name: "Vieja"})
      too_long = String.duplicate("a", 41)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      html = lv |> form("#section-form", section: %{name: too_long}) |> render_submit()

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

      lv |> form("#section-form", section: %{sort: "name"}) |> render_submit()

      home_row = Enum.find(Catalog.list_home_sections(), &(&1.section_id == section.id))
      assert Enum.map(home_row.games, & &1.name) == ["Alfa", "Zeta"]
    end
  end

  describe "SectionLive.Edit — member picker (D-25)" do
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

      # A search RESULT button (add-game) excludes both an existing
      # member and a retired game — the member list below (unconditional)
      # is a separate assertion.
      assert has_element?(lv, "button[phx-click='add-game'][phx-value-game-id='#{matching.id}']")
      refute has_element?(lv, "button[phx-click='add-game'][phx-value-game-id='#{already_in.id}']")
      refute has_element?(lv, "button[phx-click='add-game']", "Carcassonne Retirado")

      html =
        lv
        |> element("button[phx-value-game-id='#{matching.id}']", "Carcassonne")
        |> render_click()

      assert html =~ "Carcassonne en la sección"
      assert html =~ "Carcassonne"
    end

    test "a member row shows ↑/↓ and Quitar when sort is manual", %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game = game_fixture(%{name: "Catán"})
      add_game_to_section(section, game)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      assert has_element?(lv, "button[aria-label='Subir Catán']")
      assert has_element?(lv, "button[aria-label='Bajar Catán']")
      assert has_element?(lv, "button[phx-click='remove-game'][phx-value-game-id='#{game.id}']")
    end

    test "a member row hides ↑/↓ when sort is not manual", %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :name})
      game = game_fixture(%{name: "Catán"})
      add_game_to_section(section, game)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      refute has_element?(lv, "button[aria-label='Subir Catán']")
      refute has_element?(lv, "button[aria-label='Bajar Catán']")
      assert has_element?(lv, "button[phx-click='remove-game'][phx-value-game-id='#{game.id}']")
    end

    test "Quitar removes the game without a confirmation", %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game = game_fixture(%{name: "Catán"})
      add_game_to_section(section, game)

      {:ok, lv, html} = live(conn, ~p"/admin/secciones/#{section.id}")
      assert html =~ "Catán"

      html =
        lv
        |> element("button[phx-click='remove-game'][phx-value-game-id='#{game.id}']")
        |> render_click()

      refute html =~ "Catán"
    end

    test "at 20 members the featured screen shows the cap message", %{conn: conn} do
      featured = Repo.get_by!(Section, featured: true)

      for _ <- 1..20 do
        {:ok, _section} = Sections.add_game(featured, game_fixture().id)
      end

      extra = game_fixture(%{name: "Juego 21"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{featured.id}")

      lv |> form("#section-member-search", %{q: "Juego 21"}) |> render_change()

      html =
        lv
        |> element("button[phx-value-game-id='#{extra.id}']", "Juego 21")
        |> render_click()

      assert html =~ "La sección destacada ya tiene 20 juegos. Quitá uno para agregar otro."
    end
  end
end
