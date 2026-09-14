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

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
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

  defp count_occurrences(text, substring) do
    text |> String.split(substring) |> length() |> Kernel.-(1)
  end
end
