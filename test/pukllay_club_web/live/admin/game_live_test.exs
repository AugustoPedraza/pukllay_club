defmodule PukllayClubWeb.Admin.GameLiveTest do
  # async: false (01.8.1-06 Task 2, Rule 3): the add-game/enrichment tests
  # below stub `:catalog_storage`/`:enrichment_translate_call` via global
  # `Application.put_env/3` — the same reason `OGCardBackfillTest` uses
  # `async: false` — so this file can no longer safely run concurrently
  # with itself under `async: true` without racing another async file that
  # reads those same keys.
  use PukllayClubWeb.ConnCase, async: false
  use Oban.Testing, repo: PukllayClub.Repo

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures
  import PukllayClub.SectionsFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.Sections
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.ImagePipeline
  alias PukllayClub.Catalog.Seed.TranslatedDescription
  alias PukllayClub.Repo
  alias PukllayClub.Workers.EnrichGameWorker

  @bgg_fixture File.read!("test/support/fixtures/bgg_thing_on_mars.xml")

  defmodule FakeStorage do
    @moduledoc false
    @behaviour PukllayClub.Catalog.Seed.Storage

    @impl true
    def put(_credentials, key, binary, _opts) do
      Process.put({:fake_storage_put, key}, byte_size(binary))
      {:ok, "https://images.test.invalid/#{key}"}
    end

    @impl true
    def list_keys(_credentials, _prefix), do: {:ok, []}
  end

  describe "GameLive.Form — edit screen (D-07, T-01.8.1-21)" do
    setup :register_and_log_in_staff

    test "shows the game's name in the form and its BGG mechanics read-only", %{conn: conn} do
      game = game_fixture(%{name: "Catán", mechanics: ["Dice Rolling", "Hand Management"]})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "Catán"
      assert html =~ "Tira dados"
      assert html =~ "Gestión de mano"
    end

    test "submitting a new name and units saves and the public page renders the new name", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Catán Viejo", units: 1})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      lv
      |> form("#game-form", game: %{name: "Catán Nuevo", units: "3"})
      |> render_submit()

      updated = Catalog.get_game!(game.id)
      assert updated.name == "Catán Nuevo"
      assert updated.units == 3

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

  describe "GameLive.Index — list, filter, search, load more (D-09 Task 2)" do
    setup :register_and_log_in_staff

    test "lists games by name with a status badge", %{conn: conn} do
      game_fixture(%{name: "Borrador Uno", status: :draft})
      game_fixture(%{name: "Publicado Uno", status: :published})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos")

      assert html =~ "Borrador Uno"
      assert html =~ "Publicado Uno"
      assert html =~ "Borrador"
      assert html =~ "Publicado"
    end

    test "?estado=borrador shows only drafts", %{conn: conn} do
      game_fixture(%{name: "Borrador Uno", status: :draft})
      game_fixture(%{name: "Publicado Uno", status: :published})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos?estado=borrador")

      assert html =~ "Borrador Uno"
      refute html =~ "Publicado Uno"
    end

    test "an unknown estado value shows all games", %{conn: conn} do
      game_fixture(%{name: "Uno", status: :draft})
      game_fixture(%{name: "Dos", status: :published})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos?estado=bogus")

      assert html =~ "Uno"
      assert html =~ "Dos"
    end

    test "typing in the search box narrows by name case-insensitively", %{conn: conn} do
      game_fixture(%{name: "Catán"})
      game_fixture(%{name: "Carcassonne"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html = lv |> form("#admin-games-search", q: "cat") |> render_change()

      assert html =~ "Catán"
      refute html =~ "Carcassonne"
    end

    test "with 60 games, the first render shows 50 rows and Cargar más appends the rest", %{
      conn: conn
    } do
      for n <- 1..60 do
        game_fixture(%{name: "Juego #{String.pad_leading(to_string(n), 3, "0")}"})
      end

      {:ok, lv, html} = live(conn, ~p"/admin/juegos")
      assert count_occurrences(html, "Juego ") == 50

      html = render_click(lv, "load-more")
      assert count_occurrences(html, "Juego ") == 60
    end

    test "the Borradores filter with zero drafts shows the empty state", %{conn: conn} do
      game_fixture(%{status: :published})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos?estado=borrador")

      assert html =~ "Ningún juego en borrador"
      assert html =~ "Agregá un juego pegando su ID o link de BGG."
    end
  end

  describe "GameLive.Index — add game by BGG id (D-01, 01.8.1-06)" do
    setup :register_and_log_in_staff

    setup do
      previous_storage = Application.get_env(:pukllay_club, :catalog_storage)
      previous_translate_call = Application.get_env(:pukllay_club, :enrichment_translate_call)
      Application.put_env(:pukllay_club, :catalog_storage, FakeStorage)

      Application.put_env(:pukllay_club, :enrichment_translate_call, fn _params, _opts ->
        {:ok, %TranslatedDescription{description_es: "Descripción en español."}}
      end)

      on_exit(fn ->
        if previous_storage do
          Application.put_env(:pukllay_club, :catalog_storage, previous_storage)
        else
          Application.delete_env(:pukllay_club, :catalog_storage)
        end

        if previous_translate_call do
          Application.put_env(:pukllay_club, :enrichment_translate_call, previous_translate_call)
        else
          Application.delete_env(:pukllay_club, :enrichment_translate_call)
        end
      end)

      :ok
    end

    defp stub_bgg_fixture do
      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, @bgg_fixture)
      end)
    end

    defp stub_cover_image do
      Req.Test.stub(ImagePipeline, fn conn ->
        png =
          800
          |> Image.new!(600, color: [10, 20, 30])
          |> Image.write!(:memory, suffix: ".png")

        conn
        |> Plug.Conn.put_resp_content_type("image/png")
        |> Plug.Conn.send_resp(200, png)
      end)
    end

    test "an invalid id shows a field error and adds nothing", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-form", bgg_id: "not-a-number")
        |> render_submit()

      assert html =~ "Pegá un número de BGG o el link del juego."
      assert Catalog.count_admin_games() == 0
    end

    test "a valid id adds a draft row showing the cargando placeholder and a skeleton", %{conn: conn} do
      stub_bgg_fixture()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-form", bgg_id: "184267")
        |> render_submit()

      assert html =~ "Juego agregado como borrador."
      assert html =~ "Juego #184267 (cargando…)"
      assert html =~ "skeleton"
    end

    test "after perform_job runs the full pipeline, re-rendering (mount) shows the BGG name", %{
      conn: conn
    } do
      stub_bgg_fixture()
      stub_cover_image()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      lv
      |> form("#add-game-form", bgg_id: "184267")
      |> render_submit()

      game = Repo.get_by!(Game, bgg_id: 184_267)
      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => game.id})

      assert :ok = perform_job(EnrichGameWorker, %{"game_id" => game.id})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos?estado=borrador")
      assert html =~ "On Mars"
      refute html =~ "cargando"
    end

    test "a {:game_enriched, id} broadcast updates the open LiveView's row live, no reload", %{conn: conn} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Juego #184267",
          enrichment_status: "pending",
          status: :draft,
          thumbnail_url: nil,
          cover_url: nil
        })

      {:ok, lv, html} = live(conn, ~p"/admin/juegos")
      assert html =~ "Juego #184267 (cargando…)"

      game
      |> Ecto.Changeset.change(name: "On Mars", enrichment_status: "enriched")
      |> Repo.update!()

      Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game.id})

      html = render(lv)
      assert html =~ "On Mars"
      refute html =~ "cargando"
    end
  end

  describe "GameLive.Index — known BGG id warns, then allows an edition (D-03 revised)" do
    setup :register_and_log_in_staff

    test "pasting a known BGG id warns, then Sí, agregar edición adds an edition", %{
      conn: conn
    } do
      existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-form", bgg_id: "184267")
        |> render_submit()

      assert html =~ "Ya tenés Ya en la ludoteca con este BGG ID. ¿Es otra edición?"
      assert html =~ ~p"/admin/juegos/#{existing.id}/editar"
      assert Catalog.count_admin_games() == 1

      html = lv |> element("#confirm-edition") |> render_click()

      assert html =~ "Edición agregada como borrador."
      assert Catalog.count_admin_games() == 2
    end

    test "pasting a BGG game URL adds a draft (D-01, not only a bare id)", %{conn: conn} do
      stub_bgg_fixture()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-form", bgg_id: "https://boardgamegeek.com/boardgame/184267/on-mars")
        |> render_submit()

      assert html =~ "Juego agregado como borrador."
      assert Catalog.count_admin_games() == 1
    end

    test "both add buttons carry phx-disable-with (IN-B-02)", %{conn: conn} do
      _existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      assert has_element?(lv, "#add-game-form button[phx-disable-with]")

      lv
      |> form("#add-game-form", bgg_id: "184267")
      |> render_submit()

      assert has_element?(lv, "#confirm-edition[phx-disable-with]")
    end

    test "Cancelar removes the prompt without creating anything", %{conn: conn} do
      _existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      lv
      |> form("#add-game-form", bgg_id: "184267")
      |> render_submit()

      assert has_element?(lv, "#edition-prompt")

      lv |> element("#cancel-edition") |> render_click()

      refute has_element?(lv, "#edition-prompt")
      assert Catalog.count_admin_games() == 1
    end

    test "multi-edition copy joins names naturally (Patchwork y Patchwork Andino)", %{
      conn: conn
    } do
      _patchwork = game_fixture(%{bgg_id: 163_412, name: "Patchwork"})
      _andino = game_fixture(%{bgg_id: 163_412, name: "Patchwork Andino"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-form", bgg_id: "163412")
        |> render_submit()

      assert html =~ "Ya tenés Patchwork y Patchwork Andino con este BGG ID. ¿Es otra edición?"
    end

    test "a double-tap on confirm-edition creates exactly one new game", %{conn: conn} do
      _existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      lv
      |> form("#add-game-form", bgg_id: "184267")
      |> render_submit()

      render_click(lv, "confirm-edition", %{})
      render_click(lv, "confirm-edition", %{})

      assert Catalog.count_admin_games() == 2
    end

    test "a stale confirm in a second tab re-warns instead of duplicating", %{conn: conn} do
      existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv1, _html} = live(conn, ~p"/admin/juegos")
      {:ok, lv2, _html} = live(conn, ~p"/admin/juegos")

      lv1 |> form("#add-game-form", bgg_id: "184267") |> render_submit()
      lv2 |> form("#add-game-form", bgg_id: "184267") |> render_submit()

      lv1 |> element("#confirm-edition") |> render_click()
      assert Catalog.count_admin_games() == 2

      html = lv2 |> element("#confirm-edition") |> render_click()
      assert Catalog.count_admin_games() == 2

      edition = Repo.get_by!(Game, bgg_id: 184_267, status: :draft)
      assert html =~ existing.name
      assert html =~ edition.name
    end
  end

  describe "GameLive.Index — failed enrichment retry (D-03)" do
    setup :register_and_log_in_staff

    test "a failed draft's row shows the error alert and Reintentar button", %{conn: conn} do
      game_fixture(%{
        bgg_id: 184_267,
        name: "Juego #184267",
        status: :draft,
        enrichment_status: "failed"
      })

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos")

      assert html =~ "Error al traer datos de BGG."
      assert html =~ "Reintentar"
    end

    test "clicking Reintentar re-enqueues enrichment and the row returns to the cargando state", %{
      conn: conn
    } do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Juego #184267",
          status: :draft,
          enrichment_status: "failed"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html = render_click(lv, "retry-enrichment", %{"game-id" => to_string(game.id)})

      assert html =~ "Juego #184267 (cargando…)"
      refute html =~ "Error al traer datos de BGG."
      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => game.id})
    end

    test "an unparseable game-id is ignored rather than raising", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html = render_click(lv, "retry-enrichment", %{"game-id" => "not-a-number"})

      assert is_binary(html)
    end
  end

  defp count_occurrences(text, substring) do
    text |> String.split(substring) |> length() |> Kernel.-(1)
  end
end
