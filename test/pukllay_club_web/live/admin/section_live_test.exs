defmodule PukllayClubWeb.Admin.SectionLiveTest do
  # Not async: the positional writers re-read the seeded featured section row
  # `FOR UPDATE`, and seeding a member first takes a `KEY SHARE` lock on that
  # same committed row through the foreign key. Two concurrent tests that both
  # seed and then lock would each wait on the other's `KEY SHARE`, which
  # Postgres reports as a deadlock. Running this module after the async ones
  # keeps it out of that cycle (`sections_test.exs` stays async: with this
  # module serialised it has no peer left to deadlock against).
  use PukllayClubWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures
  import PukllayClub.SectionsFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.Sections
  alias PukllayClub.Repo

  defp featured_section, do: Repo.get_by!(Section, featured: true)

  # The rendered slot buttons' ids in left-to-right DOM order.
  defp slot_ids(html) do
    ~r/<button[^>]*\bid="(web-slot-\d+)"/ |> Regex.scan(html) |> Enum.map(&List.last/1)
  end

  # The idle rows' ids in DOM order.
  defp recent_row_ids(html) do
    ~r/id="(web-add-sheet-recent-\d+)"/ |> Regex.scan(html) |> Enum.map(&List.last/1)
  end

  # Quick 261010-gig: neither form is on the page at rest. Both are reached
  # by tapping their trigger — the destacada's own NAME for its settings, the
  # "+" beside the page title for a new row.
  defp open_edit_sheet(lv), do: lv |> element("#web-destacada-name-button") |> render_click()

  defp open_create_sheet(lv), do: lv |> element("button[phx-click='open-create-sheet']") |> render_click()

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

  describe "SectionLive.Index — Ordenar→Listo mode (062-B, R7 #4, T-01.8.2-68)" do
    setup :register_and_log_in_staff

    test "at rest no Otras fila row shows a reorder control", %{conn: conn} do
      section_fixture(%{name: "Movible"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      refute has_element?(lv, "#web-otras-reorder")
      refute has_element?(lv, "button[aria-label='Reordenar']")
    end

    test "Ordenar filas enters the mode: a drag handle per row and Listo in the header", %{conn: conn} do
      section_fixture(%{name: "Movible"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      lv |> element("button[aria-label='Ordenar filas']") |> render_click()

      assert has_element?(lv, "#web-otras-reorder")
      assert has_element?(lv, "#web-otras-reorder button[aria-label='Reordenar']")
      assert has_element?(lv, "button", "Listo")
      # the mode replaces the resting header — Otras filas and its own
      # icon are gone while active
      refute has_element?(lv, "button[aria-label='Ordenar filas']")
    end

    test "tapping a handle reveals ↑/↓ on that row only", %{conn: conn} do
      a = section_fixture(%{name: "Sección A"})
      b = section_fixture(%{name: "Sección B"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("button[aria-label='Ordenar filas']") |> render_click()

      lv |> element("#reorder-section-#{a.id} button[aria-label='Reordenar']") |> render_click()

      assert has_element?(lv, "button[aria-label='Subir #{a.name}']")
      assert has_element?(lv, "button[aria-label='Bajar #{a.name}']")
      refute has_element?(lv, "button[aria-label='Subir #{b.name}']")
      refute has_element?(lv, "button[aria-label='Bajar #{b.name}']")
    end

    test "↓ reorders the admin list and the home page's own order", %{conn: conn} do
      a = section_fixture(%{name: "Sección A", position: 500})
      b = section_fixture(%{name: "Sección B", position: 501})
      add_game_to_section(a, game_fixture(%{name: "Juego A"}))
      add_game_to_section(b, game_fixture(%{name: "Juego B"}))

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("button[aria-label='Ordenar filas']") |> render_click()
      lv |> element("#reorder-section-#{a.id} button[aria-label='Reordenar']") |> render_click()

      lv
      |> element("button[aria-label='Bajar #{a.name}']")
      |> render_click()

      assert Repo.get!(Section, a.id).position == 501
      assert Repo.get!(Section, b.id).position == 500

      home_titles =
        Catalog.list_home_sections()
        |> Enum.filter(&(&1.section_id in [a.id, b.id]))
        |> Enum.map(& &1.title)

      assert home_titles == ["Sección B", "Sección A"]
    end

    test "Listo exits the mode and shows Orden guardado with a Deshacer snackbar", %{conn: conn} do
      section_fixture(%{name: "Movible"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("button[aria-label='Ordenar filas']") |> render_click()

      html = lv |> element("button", "Listo") |> render_click()

      refute has_element?(lv, "#web-otras-reorder")
      assert html =~ "Orden guardado"
      assert html =~ ~s(data-timeout="10000")
    end

    test "Deshacer restores the order in effect when Ordenar filas was entered", %{conn: conn} do
      a = section_fixture(%{name: "Sección A", position: 500})
      b = section_fixture(%{name: "Sección B", position: 501})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("button[aria-label='Ordenar filas']") |> render_click()
      lv |> element("#reorder-section-#{a.id} button[aria-label='Reordenar']") |> render_click()

      lv
      |> element("button[aria-label='Bajar #{a.name}']")
      |> render_click()

      assert Repo.get!(Section, a.id).position == b.position

      lv |> element("button", "Listo") |> render_click()
      lv |> element("button[phx-click='undo-reorder']") |> render_click()

      assert Repo.get!(Section, a.id).position == 500
      assert Repo.get!(Section, b.id).position == 501
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
      refute html =~ "Mostrar en el inicio"

      html = open_edit_sheet(lv)
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
      open_edit_sheet(lv)
      lv |> form("#web-ajustes-form", section: %{shown: "false"}) |> render_submit()

      {:ok, _home_lv, hidden_html} = live(build_conn(), ~p"/")
      refute hidden_html =~ featured.name

      open_edit_sheet(lv)
      lv |> form("#web-ajustes-form", section: %{shown: "true"}) |> render_submit()

      {:ok, _home_lv, home_html} = live(build_conn(), ~p"/")
      assert home_html =~ featured.name
    end
  end

  describe "SectionLive.Index — member add/remove on the destacada (D-19k)" do
    setup :register_and_log_in_staff

    test "typing a name lists matching non-retired games, members included and marked; tapping adds it", %{conn: conn} do
      featured = featured_section()
      already_in = game_fixture(%{name: "Carcassonne en la fila"})
      add_game_to_section(featured, already_in)
      matching = game_fixture(%{name: "Carcassonne"})
      _retired = game_fixture(%{name: "Carcassonne Retirado", status: :retired})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      lv |> element("#web-slot-1") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => "carc"})

      assert has_element?(lv, "#web-add-result-#{matching.id}")
      # Deliberate behaviour change (ADD-05): a game already in the row is no
      # longer excluded - it is shown with its sub-line and moved when picked.
      assert has_element?(lv, "#web-add-result-#{already_in.id}", "Ya está en la fila · pasa a este lugar")
      refute has_element?(lv, "#web-add-sheet-results", "Carcassonne Retirado")

      html =
        lv
        |> element("#web-add-result-#{matching.id}")
        |> render_click()

      assert html =~ "Carcassonne"
      assert member_ids(featured) == [already_in.id, matching.id]
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

    test "at 20 members every slot is dimmed, a tap explains the cap and writes nothing", %{conn: conn} do
      featured = featured_section()
      for _ <- 1..20, do: {:ok, _section} = Sections.add_game(featured, game_fixture().id)
      before = members_with_positions(featured)

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      assert length(slot_ids(html)) == 21
      for index <- 0..20, do: assert(has_element?(lv, "#web-slot-#{index}.pk-admin-web-slot--full"))
      # Dimmed, never dead: D-24 forbids a disabled control.
      refute html =~ "disabled"

      html = lv |> element("#web-slot-0") |> render_click()

      assert html =~ "Ya hay 20 juegos. Quitá uno para agregar otro."
      assert html =~ ~s(data-timeout="4000")
      refute html =~ "Deshacer"
      refute has_element?(lv, "#web-add-sheet")
      assert members_with_positions(featured) == before
    end

    test "at 19 members no slot is dimmed and a tap opens the sheet", %{conn: conn} do
      featured = featured_section()
      for _ <- 1..19, do: {:ok, _section} = Sections.add_game(featured, game_fixture().id)

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      assert length(slot_ids(html)) == 20
      refute html =~ "pk-admin-web-slot--full"

      lv |> element("#web-slot-0") |> render_click()
      assert has_element?(lv, "#web-add-sheet")
    end

    test "an empty row never dims its single slot", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      assert slot_ids(html) == ["web-slot-0"]
      refute has_element?(lv, "#web-slot-0.pk-admin-web-slot--full")
    end

    test "a non-featured manual row accepts a 21st game: the cap follows `featured`, not the count" do
      # The Web page only draws the featured row's rail, so the dim condition
      # (`featured` AND count >= cap) is exercised here at the context level,
      # where the same `featured` flag decides the cap.
      section = section_fixture(%{kind: :manual, sort: :manual})
      for _ <- 1..Sections.featured_cap(), do: {:ok, _section} = Sections.add_game(section, game_fixture().id)

      assert {:ok, _placement} = Sections.insert_game_at(section, game_fixture().id, 0)
      assert length(Sections.section_members(section)) == Sections.featured_cap() + 1
    end

    test "the cap threshold has one home: index.ex carries no literal for it" do
      source = File.read!("lib/pukllay_club_web/live/admin/section_live/index.ex")

      assert source =~ "Sections.featured_cap()"
      refute source =~ ~r/>=\s*20\b/
      refute source =~ "@featured_cap"
    end
  end

  describe "SectionLive.Index — the + slot rail and the add sheet (01.8.4, tracer)" do
    setup :register_and_log_in_staff

    test "a tap on slot 0 opens the sheet, a pick lands the game first, Deshacer restores the row",
         %{conn: conn} do
      featured = featured_section()
      first = game_fixture(%{name: "Everdell"})
      second = game_fixture(%{name: "Wingspan"})
      add_game_to_section(featured, first, 1)
      add_game_to_section(featured, second, 2)
      picked = game_fixture(%{name: "Carcassonne"})

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      # n covers render n + 1 slots, and the rail is one labelled group.
      assert slot_ids(html) == ["web-slot-0", "web-slot-1", "web-slot-2"]
      assert has_element?(lv, ~s(#web-destacada-rail[role="group"][aria-labelledby="web-destacada-name"]))
      assert has_element?(lv, "#web-destacada-name", featured.name)

      sheet_html = lv |> element("#web-slot-0") |> render_click()

      assert sheet_html =~ "¿Qué juego va acá?"
      assert sheet_html =~ "#{featured.name} · al principio"

      assert has_element?(
               lv,
               "#web-add-sheet #web-add-sheet-input[placeholder='Buscá un juego'][data-pk-sheet-autofocus]"
             )

      render_change(lv, "add-sheet-search", %{"q" => "carcas"})
      assert has_element?(lv, "#web-add-sheet-results #web-add-result-#{picked.id}")

      html = lv |> element("#web-add-result-#{picked.id}") |> render_click()

      refute has_element?(lv, "#web-add-sheet")
      members = Sections.section_members(featured)
      assert Enum.map(members, & &1.game_id) == [picked.id, first.id, second.id]
      assert Enum.map(members, & &1.position) == [1, 2, 3]
      assert html =~ "Juego agregado"
      assert html =~ ~s(data-timeout="10000")

      lv |> element("button[phx-click='undo-place']") |> render_click()

      assert featured |> Sections.section_members() |> Enum.map(& &1.game_id) == [first.id, second.id]
      refute has_element?(lv, "#web-place-snackbar")
    end

    test "slot labels name the two covers a slot sits between", %{conn: conn} do
      featured = featured_section()
      add_game_to_section(featured, game_fixture(%{name: "Everdell"}), 1)
      add_game_to_section(featured, game_fixture(%{name: "Wingspan"}), 2)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      assert has_element?(lv, "#web-slot-0[aria-label='Agregar un juego al principio']")
      assert has_element?(lv, "#web-slot-1[aria-label='Agregar un juego entre Everdell y Wingspan']")
      assert has_element?(lv, "#web-slot-2[aria-label='Agregar un juego al final']")
    end

    test "an empty row renders its single slot, labelled al principio", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      assert slot_ids(html) == ["web-slot-0"]
      assert has_element?(lv, "#web-slot-0[aria-label='Agregar un juego al principio']")
      assert has_element?(lv, ~s(#web-destacada-rail[role="group"][aria-labelledby="web-destacada-name"]))

      sheet_html = lv |> element("#web-slot-0") |> render_click()
      assert sheet_html =~ "· al principio"
    end
  end

  describe "SectionLive.Index — an empty row's rail is one dashed tile (01.8.4, RAIL-03)" do
    setup :register_and_log_in_staff

    defp slot_button_count(html), do: length(Regex.scan(~r/<button[^>]*\bclass="[^"]*\bpk-admin-web-slot\b/, html))

    test "an empty row renders the empty modifier, one slot, and the instruction line", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      assert html =~ "Tocá + para elegir el primer juego."
      assert has_element?(lv, "#web-destacada-rail.pk-admin-web-rail--empty")
      assert has_element?(lv, "#web-destacada-rail .pk-admin-web-rail__hint", "Tocá + para elegir el primer juego.")
      assert slot_button_count(html) == 1
      assert has_element?(lv, "#web-destacada-rail > button.pk-admin-web-slot")
    end

    test "the empty rail keeps role=group and its label, and the shipped note still renders", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      assert has_element?(
               lv,
               ~s(#web-destacada-rail.pk-admin-web-rail--empty[role="group"][aria-labelledby="web-destacada-name"])
             )

      assert html =~ "Sin juegos, no se ve en el inicio."
    end

    test "the instruction line is the rail's last child and the slot stays its first", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/secciones")

      [_, rail] = Regex.run(~r/id="web-destacada-rail"[^>]*>(.*?)<\/div>/s, html)
      {slot_at, _} = :binary.match(rail, "web-slot-0")
      {hint_at, _} = :binary.match(rail, "pk-admin-web-rail__hint")

      assert slot_at < hint_at
      assert String.starts_with?(String.trim_leading(rail), "<button")
    end

    test "a populated rail carries no empty modifier and no hint, and renders two slots", %{conn: conn} do
      featured = featured_section()
      add_game_to_section(featured, game_fixture(%{name: "Everdell"}), 1)

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      refute has_element?(lv, "#web-destacada-rail.pk-admin-web-rail--empty")
      refute html =~ "Tocá + para elegir el primer juego."
      refute html =~ "pk-admin-web-rail__hint"
      assert slot_button_count(html) == 2
    end

    test "placing the first game swaps the rail from the empty shape to the populated one", %{conn: conn} do
      picked = game_fixture(%{name: "Carcassonne"})

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")
      assert has_element?(lv, "#web-destacada-rail.pk-admin-web-rail--empty")
      assert slot_button_count(html) == 1

      lv |> element("#web-slot-0") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => "carcas"})
      html = lv |> element("#web-add-result-#{picked.id}") |> render_click()

      refute has_element?(lv, "#web-destacada-rail.pk-admin-web-rail--empty")
      refute html =~ "Tocá + para elegir el primer juego."
      assert slot_button_count(html) == 2
      assert has_element?(lv, "#web-cover-#{picked.id}")
    end
  end

  describe "SectionLive.Index — the placed cover lands (01.8.4, RAIL-06)" do
    setup :register_and_log_in_staff

    # The cover buttons whose class list carries the landed modifier.
    defp landed_cover_ids(html) do
      ~r/<button[^>]*\bid="(web-cover-\d+)"[^>]*\bclass="[^"]*\bpk-admin-web-box--landed\b/
      |> Regex.scan(html)
      |> Enum.map(&List.last/1)
    end

    defp rail_selected(html) do
      ~r/<button[^>]*\bid="(web-cover-\d+)"[^>]*\bdata-pk-rail-selected="(true|false)"/
      |> Regex.scan(html)
      |> Map.new(fn [_, id, flag] -> {id, flag} end)
    end

    test "a placed game's cover alone carries the landed class and is the selected one", %{conn: conn} do
      featured = featured_section()
      [a, b] = seed_named(featured, ["Aaa Aterriza", "Bbb Aterriza"])
      picked = game_fixture(%{name: "Ccc Aterriza"})

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")
      assert landed_cover_ids(html) == []

      lv |> element("#web-slot-1") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => "ccc"})
      html = lv |> element("#web-add-result-#{picked.id}") |> render_click()

      assert landed_cover_ids(html) == ["web-cover-#{picked.id}"]

      assert rail_selected(html) == %{
               "web-cover-#{a.id}" => "false",
               "web-cover-#{picked.id}" => "true",
               "web-cover-#{b.id}" => "false"
             }
    end

    test "a moved game's cover alone carries the landed class", %{conn: conn} do
      featured = featured_section()
      [_a, _b, c] = seed_named(featured, ["Aaa Aterriza", "Bbb Aterriza", "Ccc Aterriza"])

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      open_and_search(lv, 0, "ccc")
      html = lv |> element("#web-add-result-#{c.id}") |> render_click()

      assert landed_cover_ids(html) == ["web-cover-#{c.id}"]
      assert html =~ ~s(data-pk-rail-selected="true")
      assert length(Regex.scan(~r/data-pk-rail-selected="true"/, html)) == 1
    end

    test "the next mutating event clears it: removing a different game, then undoing the removal", %{
      conn: conn
    } do
      featured = featured_section()
      [a, _b] = seed_named(featured, ["Aaa Aterriza", "Bbb Aterriza"])
      picked = game_fixture(%{name: "Ccc Aterriza"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-2") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => "ccc"})
      html = lv |> element("#web-add-result-#{picked.id}") |> render_click()
      assert landed_cover_ids(html) == ["web-cover-#{picked.id}"]

      lv |> element("#web-cover-#{a.id}") |> render_click()
      html = lv |> element("button[phx-click='remove-game'][phx-value-game-id='#{a.id}']") |> render_click()

      refute html =~ "pk-admin-web-box--landed"
      assert Enum.all?(rail_selected(html), fn {_id, flag} -> flag == "false" end)

      # Deshacer re-adds the removed game; it must not light up either.
      html = lv |> element("button[phx-click='undo-remove']") |> render_click()
      refute html =~ "pk-admin-web-box--landed"
    end

    test "saving the row's settings clears it", %{conn: conn} do
      featured = featured_section()
      seed_named(featured, ["Aaa Aterriza"])
      picked = game_fixture(%{name: "Ccc Aterriza"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-1") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => "ccc"})
      html = lv |> element("#web-add-result-#{picked.id}") |> render_click()
      assert landed_cover_ids(html) == ["web-cover-#{picked.id}"]

      open_edit_sheet(lv)

      html =
        lv |> form("#web-ajustes-form", %{"section" => %{"name" => "Destacados nuevos"}}) |> render_submit()

      refute html =~ "pk-admin-web-box--landed"
    end

    test "Deshacer of a placement leaves no cover marked landed", %{conn: conn} do
      featured = featured_section()
      seed_named(featured, ["Aaa Aterriza", "Bbb Aterriza"])
      picked = game_fixture(%{name: "Ccc Aterriza"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => "ccc"})
      lv |> element("#web-add-result-#{picked.id}") |> render_click()
      html = lv |> element("button[phx-click='undo-place']") |> render_click()

      refute html =~ "pk-admin-web-box--landed"
    end
  end

  describe "SectionLive.Index — add-sheet handlers vs. forged and stale payloads (01.8.4, CTX-04)" do
    setup :register_and_log_in_staff

    defp seed_two(featured) do
      first = game_fixture(%{name: "Everdell"})
      second = game_fixture(%{name: "Wingspan"})
      add_game_to_section(featured, first, 1)
      add_game_to_section(featured, second, 2)
      {first, second}
    end

    defp member_ids(featured), do: featured |> Sections.section_members() |> Enum.map(& &1.game_id)

    for {label, raw} <- [{"non-numeric", "abc"}, {"negative", "-1"}, {"past the last gap", "999"}] do
      test "open-add-sheet with a #{label} index leaves the page unchanged and alive", %{conn: conn} do
        featured = featured_section()
        seed_two(featured)
        {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

        render_click(lv, "open-add-sheet", %{"index" => unquote(raw)})

        refute has_element?(lv, "#web-add-sheet")
        assert render(lv) =~ "Everdell"
      end
    end

    test "add-sheet-pick with an id above the bigint maximum leaves the LiveView alive and the row unchanged",
         %{conn: conn} do
      featured = featured_section()
      seed_two(featured)
      before = member_ids(featured)
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()

      render_click(lv, "add-sheet-pick", %{"game-id" => "99999999999999999999"})

      assert render(lv) =~ "Everdell"
      assert member_ids(featured) == before
    end

    test "add-sheet-pick with an unknown in-range id closes the sheet and writes nothing", %{conn: conn} do
      featured = featured_section()
      seed_two(featured)
      before = member_ids(featured)
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-1") |> render_click()

      render_click(lv, "add-sheet-pick", %{"game-id" => "9000000000000"})

      refute has_element?(lv, "#web-add-sheet")
      assert member_ids(featured) == before
    end

    test "a row that changed under the open sheet closes it, says so, and writes nothing", %{conn: conn} do
      featured = featured_section()
      {first, second} = seed_two(featured)
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()

      out_of_band = game_fixture(%{name: "Fuera de banda"})
      {:ok, _} = Sections.add_game(featured, out_of_band.id)
      picked = game_fixture(%{name: "Carcassonne"})

      html = render_click(lv, "add-sheet-pick", %{"game-id" => Integer.to_string(picked.id)})

      refute has_element?(lv, "#web-add-sheet")
      assert html =~ "La fila cambió mientras elegías un juego. Probá de nuevo."
      assert member_ids(featured) == [first.id, second.id, out_of_band.id]
    end

    test "members sharing one position render one deterministic order and the labels follow it", %{conn: conn} do
      featured = featured_section()
      a = game_fixture(%{name: "Zeta"})
      b = game_fixture(%{name: "Alfa"})
      add_game_to_section(featured, a, 7)
      add_game_to_section(featured, b, 7)

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      ordered = Enum.sort([a, b], &(&1.id <= &2.id))
      [lo, hi] = ordered

      assert :binary.match(html, ~s(id="web-cover-#{lo.id}")) < :binary.match(html, ~s(id="web-cover-#{hi.id}"))
      assert has_element?(lv, "#web-slot-1[aria-label='Agregar un juego entre #{lo.name} y #{hi.name}']")
    end

    test "a name with accents and guillemets reaches the slot label and the sheet subtitle verbatim", %{conn: conn} do
      featured = featured_section()
      add_game_to_section(featured, game_fixture(%{name: "«Ñandú» Cañón"}), 1)
      add_game_to_section(featured, game_fixture(%{name: "Árbol & Co"}), 2)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      assert has_element?(lv, "#web-slot-1[aria-label='Agregar un juego entre «Ñandú» Cañón y Árbol & Co']")

      html = lv |> element("#web-slot-1") |> render_click()
      assert html =~ "#{featured.name} · entre «Ñandú» Cañón y Árbol &amp; Co"
    end

    test "exactly one element carries the id the rail group is labelled by, and no cover repeats the row name",
         %{conn: conn} do
      featured = featured_section()
      {first, _second} = seed_two(featured)

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      assert length(Regex.scan(~r/id="web-destacada-name"/, html)) == 1
      refute has_element?(lv, "#web-cover-#{first.id}", featured.name)
    end

    test "only one snackbar renders, whichever order the snacks are set in", %{conn: conn} do
      featured = featured_section()
      {first, _second} = seed_two(featured)
      picked = game_fixture(%{name: "Carcassonne"})
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      snackbars = fn -> length(Regex.scan(~r/data-pk-snackbar/, render(lv))) end

      # flash first, then a snackbar assign
      open_edit_sheet(lv)
      lv |> form("#web-ajustes-form", section: %{name: featured.name}) |> render_submit()
      assert render(lv) =~ "Fila guardada."
      assert snackbars.() == 1

      lv |> element("#web-slot-0") |> render_click()
      render_click(lv, "add-sheet-pick", %{"game-id" => Integer.to_string(picked.id)})
      assert render(lv) =~ "Juego agregado"
      refute render(lv) =~ "Fila guardada."
      assert snackbars.() == 1

      # a snackbar assign first, then a flash
      open_edit_sheet(lv)
      lv |> form("#web-ajustes-form", section: %{name: featured.name}) |> render_submit()
      assert render(lv) =~ "Fila guardada."
      refute render(lv) =~ "Juego agregado"
      assert snackbars.() == 1

      # and a remove snack after a flash
      lv |> element("#web-cover-#{first.id}") |> render_click()
      lv |> element("button[phx-click='remove-game'][phx-value-game-id='#{first.id}']") |> render_click()
      refute render(lv) =~ "Fila guardada."
      assert snackbars.() == 1
    end
  end

  describe "SectionLive.Index — the sheet's recents, ranked search and no-match branch (01.8.4, ADD-03/04/07)" do
    setup :register_and_log_in_staff

    test "an empty query lists Últimas novedades: non-members only, the row's own games excluded", %{conn: conn} do
      featured = featured_section()
      member = game_fixture(%{name: "Ya En La Fila"})
      add_game_to_section(featured, member, 1)
      newcomer = game_fixture(%{name: "Recién Llegado"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      html = lv |> element("#web-slot-0") |> render_click()

      assert html =~ "Últimas novedades"
      assert has_element?(lv, "#web-add-sheet #web-add-sheet-recent")
      assert has_element?(lv, "#web-add-sheet-recent-#{newcomer.id}")
      refute has_element?(lv, "#web-add-sheet-recent-#{member.id}")
      refute has_element?(lv, "#web-add-sheet-results")
      refute has_element?(lv, "#web-add-sheet-no-match")
    end

    test "the idle rows are exactly Catalog.recent_games_for_row/2's output, six at most", %{conn: conn} do
      featured = featured_section()
      member = game_fixture(%{name: "Ya En La Fila"})
      add_game_to_section(featured, member, 1)
      for n <- 1..8, do: game_fixture(%{name: "Novedad #{n}"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      html = lv |> element("#web-slot-0") |> render_click()

      expected = Catalog.recent_games_for_row([member.id])
      assert length(expected) == 6
      assert recent_row_ids(html) == Enum.map(expected, &"web-add-sheet-recent-#{&1.id}")
    end

    test "typing lists ranked results, the starts-with match before the contains-only one", %{conn: conn} do
      contains_only = game_fixture(%{name: "Explorers of Catan"})
      starts_with = game_fixture(%{name: "Catán"})
      _retired = game_fixture(%{name: "Catán Retirado", status: :retired})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()
      html = render_change(lv, "add-sheet-search", %{"q" => "cat"})

      assert has_element?(lv, "#web-add-sheet-results #web-add-result-#{starts_with.id}")
      assert has_element?(lv, "#web-add-sheet-results #web-add-result-#{contains_only.id}")
      refute html =~ "Catán Retirado"
      refute has_element?(lv, "#web-add-sheet-recent")

      # Ordering is asserted by rendered-HTML offset, not by the assign.
      {starts_at, _} = :binary.match(html, ~s(id="web-add-result-#{starts_with.id}"))
      {contains_at, _} = :binary.match(html, ~s(id="web-add-result-#{contains_only.id}"))
      assert starts_at < contains_at
    end

    # Browser-reachability, not handler-reachability. The sibling tests hand-build the param
    # map and push the raw event by name, which bypasses the browser, so they cannot see a
    # client-side defect. LiveView's client
    # `pushInput` throws ("form events require the input to be inside a form") when a
    # `phx-change` input has no enclosing <form>, and sends nothing at all. This test starts at
    # the DOM: `form/2` raises unless a real <form> exists, and `render_change/1` raises unless
    # that form carries a change binding and serializes `q` as a named param.
    test "a keystroke in the real search field reaches the handler and renders a match (browser-reachability, not handler-reachability)",
         %{conn: conn} do
      game = game_fixture(%{name: "Catán"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()
      lv |> form("#web-add-sheet-form", %{q: "cat"}) |> render_change()

      assert has_element?(lv, "#web-add-sheet-results #web-add-result-#{game.id}")
      refute has_element?(lv, "#web-add-sheet-recent")
    end

    test "a whitespace-only query is the idle state, not a no-match", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => "   "})

      assert has_element?(lv, "#web-add-sheet-recent")
      refute has_element?(lv, "#web-add-sheet-no-match")
    end

    test "a query matching nothing renders the verbatim no-match copy and a Crear row", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()
      html = render_change(lv, "add-sheet-search", %{"q" => "zzz"})

      assert has_element?(lv, "#web-add-sheet-no-match")
      assert html =~ "Ningún juego se llama así."
      assert html =~ "Crear «zzz»"
      assert html =~ "Agregarlo al catálogo"
      assert has_element?(lv, "#web-add-create-row", "Crear «zzz»")
      assert has_element?(lv, "#web-add-create-row", "Agregarlo al catálogo")
      refute has_element?(lv, "#web-add-sheet-results")
      refute has_element?(lv, "#web-add-sheet-recent")
    end

    test "the Crear row is a phx-click div, never a link", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => "zzz"})

      assert has_element?(lv, "div#web-add-create-row[phx-click='create-game-stub']")
      refute has_element?(lv, "a#web-add-create-row")
      refute has_element?(lv, "#web-add-create-row[href]")
      refute has_element?(lv, "#web-add-create-row[data-phx-link]")
    end

    test "the Crear row reflects the query escaped, never as markup", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()
      html = render_change(lv, "add-sheet-search", %{"q" => "<b>zzz</b>"})

      refute html =~ "<b>zzz</b>"
      assert html =~ "Crear «&lt;b&gt;zzz&lt;/b&gt;»"
    end

    test "tapping the Crear row flashes the stub copy, closes the sheet and changes nothing", %{conn: conn} do
      featured = featured_section()
      add_game_to_section(featured, game_fixture(%{name: "Everdell"}), 1)
      before = member_ids(featured)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => "zzz"})

      html = lv |> element("#web-add-create-row") |> render_click()

      assert html =~ "Crear un juego: se diseña en otra ronda"
      refute has_element?(lv, "#web-add-sheet")
      assert member_ids(featured) == before
      # Not a navigation: the same LiveView is still rendering the same page.
      assert has_element?(lv, "#web-destacada")
    end
  end

  describe "SectionLive.Index — a game already in the row is moved, not duplicated (01.8.4, ADD-05)" do
    setup :register_and_log_in_staff

    defp seed_named(featured, names) do
      names
      |> Enum.with_index(1)
      |> Enum.map(fn {name, position} ->
        game = game_fixture(%{name: name})
        add_game_to_section(featured, game, position)
        game
      end)
    end

    defp members_with_positions(featured) do
      featured |> Sections.section_members() |> Enum.map(&{&1.game_id, &1.position})
    end

    defp open_and_search(lv, slot, query) do
      lv |> element("#web-slot-#{slot}") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => query})
    end

    test "a member in the results carries the verbatim sub-line; a non-member carries none", %{conn: conn} do
      featured = featured_section()
      [_a, _b, c] = seed_named(featured, ["Aaa Mover", "Bbb Mover", "Ccc Mover"])
      outsider = game_fixture(%{name: "Ddd Mover"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      html = open_and_search(lv, 0, "mover")

      assert has_element?(lv, "#web-add-result-#{c.id}", "Ya está en la fila · pasa a este lugar")
      assert html =~ "Ya está en la fila · pasa a este lugar"
      refute has_element?(lv, "#web-add-result-#{outsider.id}", "Ya está en la fila")
    end

    test "a forward move lands at the chosen gap: count unchanged, once, Juego movido + Deshacer, undo restores", %{
      conn: conn
    } do
      featured = featured_section()
      [a, b, c] = seed_named(featured, ["Aaa Mover", "Bbb Mover", "Ccc Mover"])

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      open_and_search(lv, 0, "ccc")
      html = lv |> element("#web-add-result-#{c.id}") |> render_click()

      members = Sections.section_members(featured)
      assert Enum.map(members, & &1.game_id) == [c.id, a.id, b.id]
      assert length(members) == 3
      assert Enum.map(members, & &1.position) == [1, 2, 3]
      assert length(Regex.scan(~r/id="web-cover-#{c.id}"/, html)) == 1
      refute has_element?(lv, "#web-add-sheet")
      assert has_element?(lv, "#web-place-snackbar", "Juego movido")
      assert html =~ ~s(data-timeout="10000")
      refute html =~ "Juego agregado"

      lv |> element("button[phx-click='undo-place']") |> render_click()

      assert member_ids(featured) == [a.id, b.id, c.id]
      assert featured |> Sections.section_members() |> Enum.map(& &1.position) == [1, 2, 3]
      refute has_element?(lv, "#web-place-snackbar")
    end

    test "a backward move lands one gap further than the full-list slot suggests: [A,B,C,D] slot 3 picking A", %{
      conn: conn
    } do
      featured = featured_section()
      [a, b, c, d] = seed_named(featured, ["Aaa Mover", "Bbb Mover", "Ccc Mover", "Ddd Mover"])

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      open_and_search(lv, 3, "aaa")
      lv |> element("#web-add-result-#{a.id}") |> render_click()

      assert member_ids(featured) == [b.id, c.id, a.id, d.id]

      lv |> element("button[phx-click='undo-place']") |> render_click()
      assert member_ids(featured) == [a.id, b.id, c.id, d.id]
    end

    test "a move to the end of the row and its undo", %{conn: conn} do
      featured = featured_section()
      [a, b, c] = seed_named(featured, ["Aaa Mover", "Bbb Mover", "Ccc Mover"])

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      open_and_search(lv, 3, "aaa")
      lv |> element("#web-add-result-#{a.id}") |> render_click()
      assert member_ids(featured) == [b.id, c.id, a.id]

      lv |> element("button[phx-click='undo-place']") |> render_click()
      assert member_ids(featured) == [a.id, b.id, c.id]
    end

    for {label, slot} <- [{"the gap before it (slot = its index)", 1}, {"the gap after it (slot = index + 1)", 2}] do
      test "picking the game that already occupies #{label} says so and writes nothing", %{conn: conn} do
        featured = featured_section()
        [_a, b, _c] = seed_named(featured, ["Aaa Mover", "Bbb Mover", "Ccc Mover"])
        before = members_with_positions(featured)
        updated_before = featured |> Sections.section_members() |> Enum.map(& &1.updated_at)

        {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
        open_and_search(lv, unquote(slot), "bbb")
        html = lv |> element("#web-add-result-#{b.id}") |> render_click()

        assert html =~ "Ya está en ese lugar"
        refute has_element?(lv, "#web-add-sheet")
        refute has_element?(lv, "#web-place-snackbar")
        refute has_element?(lv, "button[phx-click='undo-place']")
        assert members_with_positions(featured) == before
        assert featured |> Sections.section_members() |> Enum.map(& &1.updated_at) == updated_before
      end
    end

    test "the slot 0 half of the two-gap condition: picking the first game at slot 0 is a no-op", %{conn: conn} do
      featured = featured_section()
      [a, _b, _c] = seed_named(featured, ["Aaa Mover", "Bbb Mover", "Ccc Mover"])
      before = members_with_positions(featured)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      open_and_search(lv, 0, "aaa")
      html = lv |> element("#web-add-result-#{a.id}") |> render_click()

      assert html =~ "Ya está en ese lugar"
      refute has_element?(lv, "#web-add-sheet")
      assert members_with_positions(featured) == before
    end

    test "the same-spot snack carries no action", %{conn: conn} do
      featured = featured_section()
      [_a, b, _c] = seed_named(featured, ["Aaa Mover", "Bbb Mover", "Ccc Mover"])

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      open_and_search(lv, 1, "bbb")
      lv |> element("#web-add-result-#{b.id}") |> render_click()

      assert has_element?(lv, "#admin-snackbar-info", "Ya está en ese lugar")
      refute has_element?(lv, "#admin-snackbar-info button[phx-click]")
    end

    test "a stale undo of a move is swallowed: the page stays alive and the snackbar clears", %{conn: conn} do
      featured = featured_section()
      [a, b, c] = seed_named(featured, ["Aaa Mover", "Bbb Mover", "Ccc Mover"])

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      open_and_search(lv, 0, "ccc")
      lv |> element("#web-add-result-#{c.id}") |> render_click()
      assert member_ids(featured) == [c.id, a.id, b.id]

      # Out of band, the mover leaves the row and the original index no longer exists.
      {:ok, _} = Sections.remove_game(featured, c.id)
      {:ok, _} = Sections.remove_game(featured, b.id)

      lv |> element("button[phx-click='undo-place']") |> render_click()

      refute has_element?(lv, "#web-place-snackbar")
      assert member_ids(featured) == [a.id]
    end
  end

  describe "SectionLive.Index — the inline add control is gone (01.8.4, RAIL-05)" do
    setup :register_and_log_in_staff

    test "with the sheet closed, none of the removed ids render", %{conn: conn} do
      add_game_to_section(featured_section(), game_fixture(%{name: "Everdell"}), 1)
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      refute has_element?(lv, "#web-search-form")
      refute has_element?(lv, "#web-search-input")
      refute has_element?(lv, "#web-search-results")
    end

    test "with the sheet open, none of the removed ids render", %{conn: conn} do
      add_game_to_section(featured_section(), game_fixture(%{name: "Everdell"}), 1)
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()

      assert has_element?(lv, "#web-add-sheet")
      refute has_element?(lv, "#web-search-form")
      refute has_element?(lv, "#web-search-input")
      refute has_element?(lv, "#web-search-results")
    end

    test "with a query typed, none of the removed ids render", %{conn: conn} do
      add_game_to_section(featured_section(), game_fixture(%{name: "Everdell"}), 1)
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      lv |> element("#web-slot-0") |> render_click()
      render_change(lv, "add-sheet-search", %{"q" => "ever"})

      assert has_element?(lv, "#web-add-sheet-results")
      refute has_element?(lv, "#web-search-form")
      refute has_element?(lv, "#web-search-input")
      refute has_element?(lv, "#web-search-results")
    end

    test "index.ex carries no occurrence of the removed ids' shared prefix, moduledoc included" do
      source = File.read!("lib/pukllay_club_web/live/admin/section_live/index.ex")

      refute source =~ "web-search"
    end

    test "edit.ex keeps its own inline add field: RAIL-05 is Index-only" do
      source = File.read!("lib/pukllay_club_web/live/admin/section_live/edit.ex")

      assert source =~ "section-member-search"
    end
  end

  describe "SectionLive.Index — at most one snackbar, in both directions (01.8.4, RAIL-04)" do
    setup :register_and_log_in_staff

    defp snackbar_count(lv), do: length(Regex.scan(~r/\sdata-pk-snackbar[\s=>]/, render(lv)))

    test "flash after assign: the cap flash replaces the remove snackbar", %{conn: conn} do
      featured = featured_section()
      games = for _ <- 1..20, do: game_fixture()
      for game <- games, do: {:ok, _} = Sections.add_game(featured, game.id)
      first = hd(games)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      lv |> element("#web-cover-#{first.id}") |> render_click()
      lv |> element("button[phx-click='remove-game'][phx-value-game-id='#{first.id}']") |> render_click()
      assert has_element?(lv, "[data-pk-snackbar]", "quitado de la fila")
      assert snackbar_count(lv) == 1

      # Back to the cap out of band; the page's own count is now stale.
      {:ok, _} = Sections.add_game(featured, game_fixture().id)

      lv |> element("#web-slot-0") |> render_click()

      assert snackbar_count(lv) == 1
      assert has_element?(lv, "[data-pk-snackbar]", "Ya hay 20 juegos. Quitá uno para agregar otro.")
      refute has_element?(lv, "#web-remove-snackbar")
    end

    test "assign after flash: a successful place replaces the same-spot flash", %{conn: conn} do
      featured = featured_section()
      [a, _b, _c] = seed_named(featured, ["Aaa Snack", "Bbb Snack", "Ccc Snack"])
      newcomer = game_fixture(%{name: "Ddd Snack"})

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      # The same-spot flash is on screen and the sheet has closed.
      open_and_search(lv, 1, "aaa")
      lv |> element("#web-add-result-#{a.id}") |> render_click()
      assert has_element?(lv, "[data-pk-snackbar]", "Ya está en ese lugar")
      assert snackbar_count(lv) == 1

      # `open-add-sheet` sets no snack, so the stale flash is still up when the place commits.
      open_and_search(lv, 0, "ddd")
      assert has_element?(lv, "[data-pk-snackbar]", "Ya está en ese lugar")
      lv |> element("#web-add-result-#{newcomer.id}") |> render_click()

      assert snackbar_count(lv) == 1
      assert has_element?(lv, "[data-pk-snackbar]", "Juego agregado")
      refute has_element?(lv, "[data-pk-snackbar]", "Ya está en ese lugar")
    end
  end

  describe "SectionLive.Index — neither form is open at rest (quick 261010-gig, sketch 070)" do
    setup :register_and_log_in_staff

    test "the page carries no form on mount", %{conn: conn} do
      featured = featured_section()
      seed_two(featured)

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      refute has_element?(lv, "#web-ajustes-form")
      refute has_element?(lv, "#create-section-form")
      refute html =~ "Mostrar en el inicio"
      refute html =~ "Nombre de la sección"
    end

    test "the destacada's name is the dialog trigger that opens its settings", %{conn: conn} do
      featured = featured_section()
      seed_two(featured)

      {:ok, lv, html} = live(conn, ~p"/admin/secciones")

      assert has_element?(
               lv,
               ~s(#web-destacada-name-button[aria-haspopup="dialog"][phx-click="open-edit-sheet"])
             )

      # The rail's label target is still the name text itself, exactly once.
      assert length(Regex.scan(~r/id="web-destacada-name"/, html)) == 1
      assert has_element?(lv, "#web-destacada-name", featured.name)

      html = open_edit_sheet(lv)

      assert html =~ "Editar fila"
      assert has_element?(lv, "#web-edit-sheet #web-ajustes-form")
      assert has_element?(lv, "#web-ajustes-shown")
      assert length(Regex.scan(~r/id="web-destacada-name"/, html)) == 1
    end

    test "saving from the sheet closes it; an invalid name keeps it open", %{conn: conn} do
      featured = featured_section()
      seed_two(featured)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      open_edit_sheet(lv)

      html = lv |> form("#web-ajustes-form", section: %{name: ""}) |> render_submit()

      assert has_element?(lv, "#web-ajustes-form")
      assert html =~ "can&#39;t be blank"

      html = lv |> form("#web-ajustes-form", section: %{name: "Destacados del club 2"}) |> render_submit()

      assert html =~ "Fila guardada."
      refute has_element?(lv, "#web-ajustes-form")
      assert has_element?(lv, "#web-destacada-name", "Destacados del club 2")
      assert featured.id == featured_section().id
    end

    test "the page title's + opens the create sheet and closing it puts the form away", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")

      assert has_element?(lv, ~s(button[phx-click="open-create-sheet"][aria-label="Nueva fila"]))

      html = open_create_sheet(lv)

      assert html =~ "Nueva fila"
      assert has_element?(lv, "#web-create-sheet #create-section-form")

      html = render_click(lv, "close-create-sheet", %{})

      refute html =~ "Nombre de la sección"
      refute has_element?(lv, "#create-section-form")
    end

    test "a name error survives a re-render but not a reopen", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      open_create_sheet(lv)

      html = lv |> form("#create-section-form", name: "") |> render_submit()
      assert html =~ "can&#39;t be blank"

      render_click(lv, "close-create-sheet", %{})
      html = open_create_sheet(lv)

      refute html =~ "can&#39;t be blank"
    end
  end

  describe "SectionLive.Index — create (D-17, \"Crear sección\")" do
    setup :register_and_log_in_staff

    test "creating a section navigates to its own edit screen", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/secciones")
      open_create_sheet(lv)

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
      open_create_sheet(lv)

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

    test "at rest a member row shows no reorder control; Ordenar juegos enters the mode when sort is manual",
         %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game = game_fixture(%{name: "Catán"})
      add_game_to_section(section, game)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      refute has_element?(lv, "#section-members-reorder")
      assert has_element?(lv, "button[aria-label='Ordenar juegos']")

      lv |> element("button[aria-label='Ordenar juegos']") |> render_click()
      lv |> element("#reorder-member-#{game.id} button[aria-label='Reordenar']") |> render_click()

      assert has_element?(lv, "button[aria-label='Subir Catán']")
      assert has_element?(lv, "button[aria-label='Bajar Catán']")
    end

    test "no Ordenar juegos icon when sort is not manual", %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :name})
      game = game_fixture(%{name: "Catán"})
      add_game_to_section(section, game)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      refute has_element?(lv, "button[aria-label='Ordenar juegos']")
    end

    test "Listo exits the mode and Deshacer restores the prior order", %{conn: conn} do
      section = section_fixture(%{kind: :manual, sort: :manual})
      first = game_fixture(%{name: "Primero"})
      second = game_fixture(%{name: "Segundo"})
      add_game_to_section(section, first, 1)
      add_game_to_section(section, second, 2)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")
      lv |> element("button[aria-label='Ordenar juegos']") |> render_click()
      lv |> element("#reorder-member-#{first.id} button[aria-label='Reordenar']") |> render_click()

      lv
      |> element("button[aria-label='Bajar Primero']")
      |> render_click()

      html = lv |> element("button", "Listo") |> render_click()

      refute has_element?(lv, "#section-members-reorder")
      assert html =~ "Orden guardado"

      order_after_move = Enum.map(Sections.section_members(section), & &1.game_id)
      assert order_after_move == [second.id, first.id]

      lv |> element("button[phx-click='undo-reorder']") |> render_click()

      order_after_undo = Enum.map(Sections.section_members(section), & &1.game_id)
      assert order_after_undo == [first.id, second.id]
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
