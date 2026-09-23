defmodule PukllayClubWeb.Admin.GameLiveTest do
  @moduledoc """
  `Admin.GameLive.Form` (`/admin/juegos/:id/editar`) — the editor. Split
  from `game_live_index_test.exs` by plan 01.8.2-14 (D-25) along the
  screen boundary: the list screen (`GameLive.Index`) moved to its own
  file, this one keeps every editor-facing test for plan 01.8.2-17 to
  rewrite when the editor itself is rebuilt.
  """
  use PukllayClubWeb.ConnCase, async: false
  use Oban.Testing, repo: PukllayClub.Repo

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures
  import PukllayClub.SectionsFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.Sections
  alias PukllayClub.Repo
  alias PukllayClub.Workers.EnrichGameWorker

  describe "GameLive.Form — edit screen (D-07, T-01.8.1-21)" do
    setup :register_and_log_in_staff

    test "shows the game's name in the form and its BGG mechanics read-only", %{conn: conn} do
      game = game_fixture(%{name: "Catán", mechanics: ["Dice Rolling", "Hand Management"]})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "Catán"
      assert html =~ "Tira dados"
      assert html =~ "Gestión de mano"
    end

    test "submitting a new name saves and the public page renders the new name", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Catán Viejo"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      lv
      |> form("#game-form", game: %{name: "Catán Nuevo"})
      |> render_submit()

      updated = Catalog.get_game!(game.id)
      assert updated.name == "Catán Nuevo"

      conn = get(conn, ~p"/juegos/#{updated}")
      assert html_response(conn, 200) =~ "Catán Nuevo"
    end

    test "submitting a blank name re-renders with a field error and does not save", %{conn: conn} do
      game = game_fixture(%{name: "Catán"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      html =
        lv
        |> form("#game-form", game: %{name: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
      assert Catalog.get_game!(game.id).name == "Catán"
    end

    test "attempting to submit bgg_weight or mechanics leaves those columns unchanged", %{
      conn: conn
    } do
      game = game_fixture(%{bgg_weight: 2.3, mechanics: ["Dice Rolling"]})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      # A raw "save" push (not the form/3 helper, which validates params
      # against the form's own rendered fields and would refuse a
      # "mechanics" field that doesn't exist on the form) — this is the
      # attacker-controlled-params scenario T-01.8.1-21 exists to cover.
      render_submit(lv, "save", %{
        "game" => %{
          "name" => game.name,
          "bgg_weight" => "4.9",
          "mechanics" => ["Trading"]
        }
      })

      updated = Catalog.get_game!(game.id)
      assert updated.bgg_weight == 2.3
      assert updated.mechanics == ["Dice Rolling"]
    end

    test "a draft game opens in the editor even though its public URL 404s", %{conn: conn} do
      game = game_fixture(%{status: :draft})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      assert html =~ game.name

      assert_raise Ecto.NoResultsError, fn ->
        Catalog.get_published_game!(to_string(game.id))
      end
    end

    test "the shelf select saves shelf_id and never leaks it onto the public page", %{
      conn: conn
    } do
      shelf = shelf_fixture(%{name: "Estante-Test-Ludoteca"})
      game = game_fixture()

      {:ok, lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      assert html =~ "Estante-Test-Ludoteca"

      lv
      |> form("#game-form", game: %{shelf_id: to_string(shelf.id)})
      |> render_submit()

      assert Catalog.get_game!(game.id).shelf_id == shelf.id

      conn = get(conn, ~p"/juegos/#{game}")
      refute html_response(conn, 200) =~ "Estante-Test-Ludoteca"
    end
  end

  describe "GameLive.Form — Secciones checkboxes (D-07)" do
    setup :register_and_log_in_staff

    test "lists every manual section as a checkbox, pre-checked for current membership", %{
      conn: conn
    } do
      section_a = section_fixture(%{name: "Sección A"})
      section_b = section_fixture(%{name: "Sección B"})
      game = game_fixture()
      add_game_to_section(section_a, game)

      {:ok, lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "Sección A"
      assert html =~ "Sección B"

      assert has_element?(lv, "input[value='#{section_a.id}'][checked]")
      refute has_element?(lv, "input[value='#{section_b.id}'][checked]")
    end

    test "checking two sections and saving makes the game a member of both", %{conn: conn} do
      section_a = section_fixture(%{name: "Sección A"})
      section_b = section_fixture(%{name: "Sección B"})
      game = game_fixture()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      lv
      |> form("#game-form", game: %{section_ids: [to_string(section_a.id), to_string(section_b.id)]})
      |> render_submit()

      member_ids = Sections.member_section_ids(game.id)
      assert Enum.sort(member_ids) == Enum.sort([section_a.id, section_b.id])
    end

    test "unchecking a section removes membership", %{conn: conn} do
      section = section_fixture(%{name: "Sección Única"})
      game = game_fixture()
      add_game_to_section(section, game)

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      lv |> form("#game-form", game: %{section_ids: []}) |> render_submit()

      assert Sections.member_section_ids(game.id) == []
    end

    test "a featured_full error surfaces as a form-level flash without reverting the game's own save",
         %{conn: conn} do
      featured = Repo.get_by!(Section, featured: true)

      for _ <- 1..20 do
        {:ok, _section} = Sections.add_game(featured, game_fixture().id)
      end

      game = game_fixture(%{name: "Sin publicar todavía"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      html =
        lv
        |> form("#game-form", game: %{name: "Nombre nuevo", section_ids: [to_string(featured.id)]})
        |> render_submit()

      assert html =~ "La sección destacada ya tiene 20 juegos."
      assert Catalog.get_game!(game.id).name == "Nombre nuevo"
    end
  end

  describe "GameLive.Form — anonymous access" do
    test "an anonymous request redirects to /admin/ingresar", %{conn: conn} do
      game = game_fixture()

      assert {:error, {:redirect, %{to: "/admin/ingresar"}}} =
               live(conn, ~p"/admin/juegos/#{game.id}/editar")
    end
  end

  describe "GameLive.Form — status actions (D-04, D-08)" do
    setup :register_and_log_in_staff

    test "on a draft's form, Publicar saves pending changes and publishes it", %{conn: conn} do
      game = game_fixture(%{status: :draft, name: "Sin publicar"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      html =
        render_submit(lv, "save", %{
          "game" => %{"name" => "Ya listo"},
          "_action" => "publish"
        })

      assert html =~ "Juego publicado."
      updated = Catalog.get_game!(game.id)
      assert updated.status == :published
      assert updated.name == "Ya listo"
    end

    test "on a published game, Retirar opens the confirmation and confirming retires it", %{
      conn: conn
    } do
      game = game_fixture(%{status: :published, name: "Se retira"})

      {:ok, lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      refute html =~ "¿Retirar"

      html = render_click(lv, "retire")
      assert html =~ "¿Retirar Se retira?"

      html = render_click(lv, "confirm-retire")
      assert html =~ "Juego retirado."
      assert Catalog.get_game!(game.id).status == :retired
    end

    test "cancelling the retire confirmation leaves the game published", %{conn: conn} do
      game = game_fixture(%{status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "retire")
      render_click(lv, "cancel-retire")

      assert Catalog.get_game!(game.id).status == :published
    end

    test "on a retired game, Restaurar restores it", %{conn: conn} do
      game = game_fixture(%{status: :retired})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      html = render_click(lv, "restore")

      assert html =~ "Juego restaurado."
      assert Catalog.get_game!(game.id).status == :published
    end
  end

  describe "GameLive.Form — failed enrichment retry (D-03)" do
    setup :register_and_log_in_staff

    test "a failed draft shows the error alert and Reintentar button", %{conn: conn} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Juego #184267",
          status: :draft,
          enrichment_status: "failed"
        })

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "Error al traer datos de BGG."
      assert html =~ "Reintentar"
    end

    test "clicking Reintentar re-enqueues enrichment and clears the error", %{conn: conn} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Juego #184267",
          status: :draft,
          enrichment_status: "failed"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      html = render_click(lv, "retry-enrichment", %{"game-id" => to_string(game.id)})

      refute html =~ "Error al traer datos de BGG."
      assert Catalog.get_game!(game.id).enrichment_status == "pending"
      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => game.id})
    end
  end
end
