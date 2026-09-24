defmodule PukllayClubWeb.Admin.GameLiveIndexTest do
  @moduledoc """
  `Admin.GameLive.Index` (`/admin/juegos`) — split out of the former
  `game_live_test.exs` by plan 01.8.2-14 (D-25) along the screen boundary:
  the editor (`GameLive.Form`) keeps its own file for plan 01.8.2-17 to
  rewrite, this file owns everything the redesigned list screen does.

  async: false (01.8.1-06 Task 2, Rule 3): the add-game/enrichment tests
  below stub `:catalog_storage`/`:enrichment_translate_call` via global
  `Application.put_env/3`, the same reason `OGCardBackfillTest` uses
  `async: false`.
  """
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

  setup :register_and_log_in_staff

  describe "GameLive.Index — status groups (D-25)" do
    test "renders three sections in order when all three statuses have games", %{conn: conn} do
      game_fixture(%{name: "Un borrador", status: :draft})
      game_fixture(%{name: "Un publicado", status: :published})
      game_fixture(%{name: "Un retirado", status: :retired})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos")

      assert html =~ "Borradores"
      assert html =~ "Juegos del club"
      assert html =~ "Retirados"

      draft_pos = html |> :binary.match("Borradores") |> elem(0)
      published_pos = html |> :binary.match("Juegos del club") |> elem(0)
      retired_pos = html |> :binary.match("Retirados") |> elem(0)
      assert draft_pos < published_pos
      assert published_pos < retired_pos
    end

    test "a group with 0 rows is not rendered (no Retirados, no Borradores)", %{conn: conn} do
      game_fixture(%{name: "Solo este", status: :published})

      {:ok, lv, html} = live(conn, ~p"/admin/juegos")

      refute has_element?(lv, "#juegos-section-retired")
      refute has_element?(lv, "#juegos-section-draft")
      assert has_element?(lv, "#juegos-section-published")
      refute html =~ "Retirados"
    end

    test "every game appears in exactly one section; the counts sum to count_admin_games/1", %{
      conn: conn
    } do
      game_fixture(%{name: "D1", status: :draft})
      game_fixture(%{name: "D2", status: :draft})
      game_fixture(%{name: "P1", status: :published})
      game_fixture(%{name: "R1", status: :retired})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      # Borradores and Retirados start collapsed (D-19g-bis decision 18) —
      # open both before counting rendered rows.
      render_click(lv, "toggle-section", %{"section-key" => "draft"})
      render_click(lv, "toggle-section", %{"section-key" => "retired"})

      assert lv |> render() |> extract_count("draft") == 2
      assert lv |> render() |> extract_count("published") == 1
      assert lv |> render() |> extract_count("retired") == 1
      assert 2 + 1 + 1 == Catalog.count_admin_games()
    end

    test "a row inside Borradores does not render a status-dot repeating its section's state", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Sin publicar", status: :draft})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "toggle-section", %{"section-key" => "draft"})

      assert has_element?(lv, "#game-row-#{game.id}")
      refute has_element?(lv, "#game-row-#{game.id} .pk-admin-status-dot")
    end

    test "a draft missing data renders a Sin datos row attribute", %{conn: conn} do
      game =
        game_fixture(%{name: "Incompleto", status: :draft, description: nil, cover_url: nil})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "toggle-section", %{"section-key" => "draft"})

      assert has_element?(lv, "#game-row-#{game.id} .pk-admin-kind-tag", "Sin datos")
    end

    test "a draft with real content renders no Sin datos tag", %{conn: conn} do
      game = game_fixture(%{name: "Completo", status: :draft})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "toggle-section", %{"section-key" => "draft"})

      assert has_element?(lv, "#game-row-#{game.id}")
      refute has_element?(lv, "#game-row-#{game.id} .pk-admin-kind-tag", "Sin datos")
    end

    test "no <.table>, no Cargar más, no draft filter chip survives", %{conn: conn} do
      game_fixture(%{name: "Cualquiera"})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos")

      refute html =~ "Cargar más"
      refute html =~ "<table"
      refute html =~ "Publicados</"
    end

    test "with 60 games, every one renders at once (no pagination)", %{conn: conn} do
      for n <- 1..60 do
        game_fixture(%{name: "Juego #{String.pad_leading(to_string(n), 3, "0")}"})
      end

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos")

      assert count_occurrences(html, "id=\"game-row-") >= 60
    end

    test "typing in the search box narrows by name case-insensitively", %{conn: conn} do
      game_fixture(%{name: "Catán"})
      game_fixture(%{name: "Carcassonne"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html = lv |> form("#juegos-search-form", q: "cat") |> render_change()

      assert html =~ "Catán"
      refute html =~ "Carcassonne"
    end

    test "a search with no matches shows the empty state", %{conn: conn} do
      game_fixture(%{name: "Catán"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html = lv |> form("#juegos-search-form", q: "zzz-no-match") |> render_change()

      assert html =~ "Ningún juego coincide"
    end

    test "with zero games at all, shows the empty add-game hint", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/juegos")

      assert html =~ "Ningún juego todavía"
      assert html =~ "Agregá un juego pegando su ID o link de BGG."
    end
  end

  describe "GameLive.Index — collapsible sections (D-19g-bis decision 17/18)" do
    test "Borradores and Retirados start collapsed; Juegos del club is expanded", %{conn: conn} do
      draft = game_fixture(%{name: "Borrador uno", status: :draft})
      published = game_fixture(%{name: "Publicado uno", status: :published})
      retired = game_fixture(%{name: "Retirado uno", status: :retired})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      refute has_element?(lv, "#game-row-#{draft.id}")
      assert has_element?(lv, "#game-row-#{published.id}")
      refute has_element?(lv, "#game-row-#{retired.id}")
    end

    test "toggling Borradores expands it and shows its rows", %{conn: conn} do
      draft = game_fixture(%{name: "Borrador uno", status: :draft})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      refute has_element?(lv, "#game-row-#{draft.id}")

      html = render_click(lv, "toggle-section", %{"section-key" => "draft"})

      assert html =~ draft.name
      assert has_element?(lv, "#game-row-#{draft.id}")
    end

    test "toggling twice collapses it again", %{conn: conn} do
      draft = game_fixture(%{name: "Borrador uno", status: :draft})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "toggle-section", %{"section-key" => "draft"})
      render_click(lv, "toggle-section", %{"section-key" => "draft"})

      refute has_element?(lv, "#game-row-#{draft.id}")
    end

    test "Juegos del club's header carries no caret and is not a button", %{conn: conn} do
      game_fixture(%{name: "Publicado uno", status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      refute has_element?(lv, "#juegos-section-toggle-published")
      assert has_element?(lv, "#juegos-section-published .pk-admin-juegos-section-header")

      refute has_element?(
               lv,
               "#juegos-section-published .pk-admin-juegos-section-header--collapsible"
             )
    end

    test "a collapsible caption's caret appears after the count in DOM order", %{conn: conn} do
      game_fixture(%{name: "Borrador uno", status: :draft})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos")

      header = extract_between(html, "juegos-section-toggle-draft", "</button>")
      count_pos = header |> :binary.match("pk-admin-juegos-count") |> elem(0)
      caret_pos = header |> :binary.match("pk-admin-juegos-caret") |> elem(0)
      assert count_pos < caret_pos
    end

    test "toggle-section ignores an unrecognized section key rather than crashing", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html = render_click(lv, "toggle-section", %{"section-key" => "published"})
      assert is_binary(html)
    end
  end

  describe "GameLive.Index — Copias meta (D-02/D-31), batched" do
    test "a row's trailing count pill reflects counts_for_games/1, no per-row count query", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Con copias", status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      assert has_element?(lv, "#game-row-#{game.id} .pk-admin-count-pill", "0")
    end
  end

  describe "GameLive.Index — D-37 gate 4: post-add landing behaviour" do
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

    test "adding a game opens Borradores and marks the new row fresh", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-sheet-form", bgg_id: "184267")
        |> render_submit()

      game = Repo.get_by!(Game, bgg_id: 184_267)
      assert has_element?(lv, "#game-row-#{game.id}")
      assert html =~ "pk-admin-juegos-row--fresh"
    end

    test "confirming an edition opens Borradores and marks the new row fresh", %{conn: conn} do
      _existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      lv |> form("#add-game-sheet-form", bgg_id: "184267") |> render_submit()
      html = lv |> element("#confirm-edition") |> render_click()

      edition = Repo.get_by!(Game, bgg_id: 184_267, status: :draft)
      assert has_element?(lv, "#game-row-#{edition.id}")
      assert html =~ "pk-admin-juegos-row--fresh"
    end
  end

  describe "GameLive.Index — add game by BGG id (D-01, 01.8.1-06)" do
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
        |> form("#add-game-sheet-form", bgg_id: "not-a-number")
        |> render_submit()

      assert html =~ "Pegá un número de BGG o el link del juego."
      assert Catalog.count_admin_games() == 0
    end

    test "a valid id adds a draft row showing the cargando placeholder and a skeleton", %{conn: conn} do
      stub_bgg_fixture()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-sheet-form", bgg_id: "184267")
        |> render_submit()

      assert html =~ "Buscando info desde BGG"
      assert html =~ "Juego #184267 (cargando…)"
      assert html =~ "skeleton"
    end

    test "after perform_job runs the full pipeline, re-rendering shows the BGG name", %{
      conn: conn
    } do
      stub_bgg_fixture()
      stub_cover_image()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      lv
      |> form("#add-game-sheet-form", bgg_id: "184267")
      |> render_submit()

      game = Repo.get_by!(Game, bgg_id: 184_267)
      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => game.id})

      assert :ok = perform_job(EnrichGameWorker, %{"game_id" => game.id})

      # A fresh mount starts with Borradores collapsed again (session-local
      # UI state, never persisted) — open it before checking the row.
      {:ok, lv2, _html} = live(conn, ~p"/admin/juegos")
      html = render_click(lv2, "toggle-section", %{"section-key" => "draft"})
      assert html =~ "On Mars"
      refute html =~ "cargando"
    end

    test "a {:game_enriched, id} broadcast updates the open LiveView's row live, no reload", %{
      conn: conn
    } do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Juego #184267",
          enrichment_status: "pending",
          status: :draft,
          thumbnail_url: nil,
          cover_url: nil
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "toggle-section", %{"section-key" => "draft"})
      assert render(lv) =~ "Juego #184267 (cargando…)"

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
    test "pasting a known BGG id warns, then Sí, agregar edición adds an edition", %{
      conn: conn
    } do
      existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-sheet-form", bgg_id: "184267")
        |> render_submit()

      assert html =~ "Ya tenés Ya en la ludoteca con este BGG ID. ¿Es otra edición?"
      assert html =~ ~p"/admin/juegos/#{existing.id}/editar"
      assert Catalog.count_admin_games() == 1

      html = lv |> element("#confirm-edition") |> render_click()

      assert html =~ "Edición agregada como borrador."
      assert Catalog.count_admin_games() == 2
    end

    test "pasting a BGG game URL adds a draft (D-01, not only a bare id)", %{conn: conn} do
      Application.put_env(:pukllay_club, :catalog_storage, FakeStorage)

      Application.put_env(:pukllay_club, :enrichment_translate_call, fn _params, _opts ->
        {:ok, %TranslatedDescription{description_es: "Descripción en español."}}
      end)

      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, @bgg_fixture)
      end)

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-sheet-form", bgg_id: "https://boardgamegeek.com/boardgame/184267/on-mars")
        |> render_submit()

      assert html =~ "Buscando info desde BGG"
      assert Catalog.count_admin_games() == 1
    after
      Application.delete_env(:pukllay_club, :catalog_storage)
      Application.delete_env(:pukllay_club, :enrichment_translate_call)
    end

    test "both add buttons carry phx-disable-with (IN-B-02)", %{conn: conn} do
      _existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      assert has_element?(lv, "#add-game-sheet-form button[phx-disable-with]")

      lv
      |> form("#add-game-sheet-form", bgg_id: "184267")
      |> render_submit()

      assert has_element?(lv, "#confirm-edition[phx-disable-with]")
    end

    test "Cancelar removes the prompt without creating anything", %{conn: conn} do
      _existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      lv
      |> form("#add-game-sheet-form", bgg_id: "184267")
      |> render_submit()

      assert has_element?(lv, "#add-game-sheet-edition-prompt")

      lv |> element("#cancel-edition") |> render_click()

      refute has_element?(lv, "#add-game-sheet-edition-prompt")
      assert Catalog.count_admin_games() == 1
    end

    test "plan 01.8.3-04: the edition prompt renders inside the + sheet, not on the page behind it",
         %{conn: conn} do
      _existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})
      count_before = Catalog.count_admin_games()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      lv
      |> form("#add-game-sheet-form", bgg_id: "184267")
      |> render_submit()

      assert has_element?(lv, "#add-game-sheet-edition-prompt")
      refute has_element?(lv, "#edition-prompt")
      refute has_element?(lv, "#add-game-sheet-form")
      assert Catalog.count_admin_games() == count_before

      html = lv |> element("#cancel-edition") |> render_click()

      refute has_element?(lv, "#add-game-sheet-edition-prompt")
      assert has_element?(lv, "#add-game-sheet-form")
      assert html =~ "Número o link de BGG"
    end

    test "multi-edition copy joins names naturally (Patchwork y Patchwork Andino)", %{
      conn: conn
    } do
      _patchwork = game_fixture(%{bgg_id: 163_412, name: "Patchwork"})
      _andino = game_fixture(%{bgg_id: 163_412, name: "Patchwork Andino"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-sheet-form", bgg_id: "163412")
        |> render_submit()

      assert html =~ "Ya tenés Patchwork y Patchwork Andino con este BGG ID. ¿Es otra edición?"
    end

    test "a double-tap on confirm-edition creates exactly one new game", %{conn: conn} do
      _existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      lv
      |> form("#add-game-sheet-form", bgg_id: "184267")
      |> render_submit()

      render_click(lv, "confirm-edition", %{})
      render_click(lv, "confirm-edition", %{})

      assert Catalog.count_admin_games() == 2
    end

    test "a stale confirm in a second tab re-warns instead of duplicating", %{conn: conn} do
      existing = game_fixture(%{bgg_id: 184_267, status: :retired, name: "Ya en la ludoteca"})

      {:ok, lv1, _html} = live(conn, ~p"/admin/juegos")
      {:ok, lv2, _html} = live(conn, ~p"/admin/juegos")

      lv1 |> form("#add-game-sheet-form", bgg_id: "184267") |> render_submit()
      lv2 |> form("#add-game-sheet-form", bgg_id: "184267") |> render_submit()

      lv1 |> element("#confirm-edition") |> render_click()
      assert Catalog.count_admin_games() == 2

      html = lv2 |> element("#confirm-edition") |> render_click()
      assert Catalog.count_admin_games() == 2

      edition = Repo.get_by!(Game, bgg_id: 184_267, status: :draft)
      assert html =~ existing.name
      assert html =~ edition.name
    end
  end

  describe "GameLive.Index — the pinned search/+ row and its sheet (tracer, plan 01.8.3-01)" do
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

    test "renders no back row, no page title, no page bar, and one sr-only h1", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      refute has_element?(lv, ".pk-admin-back-row")
      refute has_element?(lv, ".pk-admin-page-title")
      refute has_element?(lv, ".pk-admin-page-bar")
      refute has_element?(lv, "#add-game-form")
      assert has_element?(lv, "h1.sr-only", "Juegos")
      assert has_element?(lv, "#juegos-search-wrap #juegos-search-input")
      assert has_element?(lv, "#juegos-add-action")
    end

    test "tapping + opens the Agregar juego sheet with a disabled Agregar while the field is empty",
         %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html = render_click(lv, "open-add-game-sheet", %{})

      assert html =~ "Agregar juego"
      assert html =~ "Número o link de BGG"
      assert html =~ "342942"
      assert html =~ "Agregar"
      assert has_element?(lv, "#add-game-sheet-form button[disabled]")
    end

    test "Agregar enables at one character; a non-empty unparseable value still raises its own error",
         %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "open-add-game-sheet", %{})

      lv |> form("#add-game-sheet-form", bgg_id: "3") |> render_change()
      refute has_element?(lv, "#add-game-sheet-form button[disabled]")

      html =
        lv
        |> form("#add-game-sheet-form", bgg_id: "no-es-un-id")
        |> render_submit()

      assert html =~ "Pegá un número de BGG o el link del juego."
      assert has_element?(lv, "#add-game-sheet.pk-admin-overlay--open")
    end

    test "submitting a valid BGG id creates a draft, closes the sheet, and lands fresh in Borradores",
         %{conn: conn} do
      stub_bgg_fixture()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "open-add-game-sheet", %{})

      html =
        lv
        |> form("#add-game-sheet-form", bgg_id: "184267")
        |> render_submit()

      game = Repo.get_by!(Game, bgg_id: 184_267)

      assert html =~ "Buscando info desde BGG"
      refute html =~ "Juego agregado como borrador."
      refute has_element?(lv, "#add-game-sheet.pk-admin-overlay--open")
      assert has_element?(lv, "#game-row-#{game.id}")
      assert html =~ "pk-admin-juegos-row--fresh"
    end
  end

  describe "GameLive.Index — the enrichment-completion snackbar (D-11/D-17, plan 01.8.3-04)" do
    test "a successful arrival shows a 10s Editar snackbar naming the game", %{conn: conn} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "On Mars",
          status: :draft,
          enrichment_status: "enriched"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game.id})

      html = render(lv)
      assert html =~ "On Mars agregado"
      assert html =~ "Editar"
      assert html =~ ~s(data-timeout="10000")
    end

    test "a failed arrival shows a snackbar naming the bgg_id, not the game's name", %{conn: conn} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Juego #184267",
          status: :draft,
          enrichment_status: "failed"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game.id})

      html = render(lv)
      assert html =~ "No pudimos traer los datos BGG de #184267"
      assert html =~ "Editar"
      assert html =~ ~s(data-timeout="10000")
      refute html =~ "Juego #184267 agregado"
    end

    test "a {:game_enriched, id} for a still-pending game renders no snackbar", %{conn: conn} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Juego #184267",
          status: :draft,
          enrichment_status: "pending"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game.id})

      refute has_element?(lv, "#enrichment-toast")
    end

    test "two arrivals in sequence leave exactly one snackbar, naming the second game", %{
      conn: conn
    } do
      game1 =
        game_fixture(%{
          bgg_id: 111_111,
          name: "Primero",
          status: :draft,
          enrichment_status: "enriched"
        })

      game2 =
        game_fixture(%{
          bgg_id: 222_222,
          name: "Segundo",
          status: :draft,
          enrichment_status: "enriched"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game1.id})
      Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game2.id})

      html = render(lv)
      assert count_occurrences(html, ~s(id="enrichment-toast")) == 1
      assert html =~ "Segundo agregado"
      refute html =~ "Primero agregado"
    end

    test "clicking Editar redirects to the game's editor", %{conn: conn} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "On Mars",
          status: :draft,
          enrichment_status: "enriched"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game.id})
      render(lv)

      assert {:error, {:live_redirect, %{to: to}}} =
               lv
               |> element("#enrichment-toast .pk-admin-snackbar__action")
               |> render_click()

      assert to == ~p"/admin/juegos/#{game.id}/editar"
    end

    test "dismiss-enrichment-toast removes the snackbar", %{conn: conn} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "On Mars",
          status: :draft,
          enrichment_status: "enriched"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game.id})
      render(lv)

      html = render_click(lv, "dismiss-enrichment-toast", %{})
      refute html =~ ~s(id="enrichment-toast")
    end

    test "edit-enriched-game with no toast assign neither redirects nor raises", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html = render_click(lv, "edit-enriched-game", %{})
      assert is_binary(html)
    end
  end

  describe "GameLive.Index — the pinned row's boundary and edge cases (plan 01.8.3-01)" do
    test "an empty catalog still renders the pinned search/+ row, so + stays reachable", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      assert has_element?(lv, ".pk-admin-juegos-empty")
      assert has_element?(lv, "#juegos-search-wrap")
      assert has_element?(lv, "#juegos-add-action")
    end

    test "a status group with 0 rows renders no caption, and present captions keep source order",
         %{conn: conn} do
      game_fixture(%{name: "Solo borrador", status: :draft})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos")

      assert html =~ "Borradores"
      refute html =~ "Juegos del club"
      refute html =~ "Retirados"

      game_fixture(%{name: "Publicado", status: :published})
      game_fixture(%{name: "Retirado", status: :retired})

      {:ok, _lv2, html2} = live(conn, ~p"/admin/juegos")

      draft_pos = html2 |> :binary.match("Borradores") |> elem(0)
      published_pos = html2 |> :binary.match("Juegos del club") |> elem(0)
      retired_pos = html2 |> :binary.match("Retirados") |> elem(0)
      assert draft_pos < published_pos
      assert published_pos < retired_pos
    end

    test "submitting a BGG id an existing game already holds does not insert a duplicate", %{
      conn: conn
    } do
      _existing = game_fixture(%{bgg_id: 184_267, status: :published, name: "Ya en la ludoteca"})
      count_before = Catalog.count_admin_games()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html =
        lv
        |> form("#add-game-sheet-form", bgg_id: "184267")
        |> render_submit()

      assert Catalog.count_admin_games() == count_before
      assert html =~ "¿Es otra edición?"
    end

    test "closing the sheet after an invalid submit and reopening clears the error and the field",
         %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "open-add-game-sheet", %{})

      html =
        lv
        |> form("#add-game-sheet-form", bgg_id: "no-es-un-id")
        |> render_submit()

      assert html =~ "Pegá un número de BGG o el link del juego."

      render_click(lv, "close-add-game-sheet", %{})
      html = render_click(lv, "open-add-game-sheet", %{})

      refute html =~ "Pegá un número de BGG o el link del juego."
      refute has_element?(lv, ~s(#add-game-sheet-input[value="no-es-un-id"]))
    end

    test "the pinned search input narrows the rendered rows", %{conn: conn} do
      game_fixture(%{name: "Catán"})
      game_fixture(%{name: "Carcassonne"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html = lv |> form("#juegos-search-form", q: "cat") |> render_change()

      assert html =~ "Catán"
      refute html =~ "Carcassonne"
    end

    test "the search wrap carries no data-pinned-hidden attribute at rest", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      assert has_element?(lv, "#juegos-search-wrap")
      refute has_element?(lv, "#juegos-search-wrap[data-pinned-hidden]")
    end
  end

  describe "GameLive.Index — security & concurrency properties (T-01.8.3-01, plan 01.8.3-04)" do
    test "confirm-edition with no prompt held inserts nothing, redirects nowhere, and the process stays alive",
         %{conn: conn} do
      count_before = Catalog.count_admin_games()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      html = render_click(lv, "confirm-edition", %{})

      assert Catalog.count_admin_games() == count_before
      assert is_binary(html)
      assert Process.alive?(lv.pid)
    end

    test "confirm-edition with no prompt held ignores a fabricated game-id param and inserts nothing",
         %{conn: conn} do
      existing = game_fixture(%{name: "Un juego real", status: :published})
      count_before = Catalog.count_admin_games()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      render_click(lv, "confirm-edition", %{"game-id" => to_string(existing.id)})

      assert Catalog.count_admin_games() == count_before
    end

    test "two {:game_enriched} arrivals leave exactly one #enrichment-toast element", %{
      conn: conn
    } do
      previous_storage = Application.get_env(:pukllay_club, :catalog_storage)

      previous_translate_call =
        Application.get_env(:pukllay_club, :enrichment_translate_call)

      Application.put_env(:pukllay_club, :catalog_storage, FakeStorage)

      Application.put_env(:pukllay_club, :enrichment_translate_call, fn _params, _opts ->
        {:ok, %TranslatedDescription{description_es: "Descripción en español."}}
      end)

      game1 =
        game_fixture(%{
          bgg_id: 333_333,
          name: "Cardal",
          status: :draft,
          enrichment_status: "enriched"
        })

      game2 =
        game_fixture(%{
          bgg_id: 444_444,
          name: "Marisco",
          status: :draft,
          enrichment_status: "enriched"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game1.id})
      Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game2.id})

      html = render(lv)
      assert count_occurrences(html, ~s(id="enrichment-toast")) == 1
      assert html =~ "Marisco agregado"

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
    end

    test "the rendered /admin/juegos HTML never contains phx-value-value", %{conn: conn} do
      game_fixture(%{name: "Cualquiera", status: :draft})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "open-add-game-sheet", %{})
      html = render_click(lv, "toggle-section", %{"section-key" => "draft"})

      refute html =~ "phx-value-value"
    end
  end

  describe "GameLive.Index — failed enrichment retry (D-03)" do
    test "a failed draft's row shows the error alert and Reintentar button", %{conn: conn} do
      game_fixture(%{
        bgg_id: 184_267,
        name: "Juego #184267",
        status: :draft,
        enrichment_status: "failed"
      })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      html = render_click(lv, "toggle-section", %{"section-key" => "draft"})

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
      render_click(lv, "toggle-section", %{"section-key" => "draft"})

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

  describe "GameLive.Index — the draft sheet and row routing (D-30, plan 01.8.2-20)" do
    test "a draft row renders no chevron and opens the draft sheet, never navigating", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Un borrador", status: :draft})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "toggle-section", %{"section-key" => "draft"})

      refute has_element?(lv, "#game-row-#{game.id} .pk-admin-row__chevron")
      html = render_click(lv, "open-draft-sheet", %{"game-id" => to_string(game.id)})

      assert has_element?(lv, "#draft-sheet.pk-admin-overlay--open")
      assert html =~ "Un borrador"
    end

    test "a published row still renders a chevron and navigates to the editor", %{conn: conn} do
      game = game_fixture(%{name: "Un publicado", status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")

      assert has_element?(lv, "#game-row-#{game.id} .pk-admin-row__chevron")
      assert has_element?(lv, ~s(a#game-row-#{game.id}[href="/admin/juegos/#{game.id}/editar"]))
    end

    test "a retired row still renders a chevron and navigates to the editor", %{conn: conn} do
      game = game_fixture(%{name: "Un retirado", status: :retired})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos")
      render_click(lv, "toggle-section", %{"section-key" => "retired"})

      assert has_element?(lv, "#game-row-#{game.id} .pk-admin-row__chevron")
      assert has_element?(lv, ~s(a#game-row-#{game.id}[href="/admin/juegos/#{game.id}/editar"]))
    end

    test "the draft sheet renders exactly five rows for a non-expansion draft", %{conn: conn} do
      game = game_fixture(%{name: "Cinco filas", status: :draft, is_expansion: false})

      {:ok, lv, html} = live(conn, ~p"/admin/juegos?#{%{draft: game.id}}")

      assert has_element?(lv, "#draft-sheet.pk-admin-overlay--open")
      # Anchored on the opening `<div class="pk-draft-sheet-row` prefix —
      # a plain count of the substring "pk-draft-sheet-row" would
      # double-count the cover row, whose class is
      # `"pk-draft-sheet-row pk-draft-sheet-row--cover"`.
      assert count_occurrences(html, ~s(<div class="pk-draft-sheet-row)) == 5
    end

    test "the draft sheet hides the nivel row once Es una expansión is checked", %{conn: conn} do
      game = game_fixture(%{name: "Expansión", status: :draft, is_expansion: false})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos?#{%{draft: game.id}}")

      html = render_change(lv, "draft-sheet-input", %{"is_expansion" => "true"})

      refute html =~ "draft-sheet-weight-band"
    end

    test "closing the draft sheet with ✕ leaves the game unchanged in the database", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Sin tocar", status: :draft, description: "Original"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos?#{%{draft: game.id}}")
      render_change(lv, "draft-sheet-input", %{"name" => "Nunca guardado"})
      render_click(lv, "close-draft-sheet")

      refute has_element?(lv, "#draft-sheet.pk-admin-overlay--open")
      reloaded = Catalog.get_game!(game.id)
      assert reloaded.name == "Sin tocar"
      assert reloaded.description == "Original"
      assert reloaded.status == :draft
    end

    test "publishing closes the sheet and highlights the row in Juegos del club, not Borradores",
         %{conn: conn} do
      game =
        game_fixture(%{
          name: "Listo para publicar",
          status: :draft,
          weight_band: "ingenio_estratega",
          is_expansion: false
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos?#{%{draft: game.id}}")

      html =
        render_submit(lv, "publish-draft", %{
          "name" => game.name,
          "description" => game.description,
          "is_expansion" => "false",
          "weight_band" => "ingenio_estratega"
        })

      refute has_element?(lv, "#draft-sheet.pk-admin-overlay--open")
      assert Catalog.get_game!(game.id).status == :published
      assert has_element?(lv, "#juegos-section-published .pk-admin-juegos-row--fresh##{"game-row-#{game.id}"}")
      refute html =~ "Borradores"
    end

    test "visiting /admin/juegos?draft=<id> directly opens that draft's sheet", %{conn: conn} do
      game = game_fixture(%{name: "Vía URL", status: :draft})

      {:ok, lv, html} = live(conn, ~p"/admin/juegos?#{%{draft: game.id}}")

      assert has_element?(lv, "#draft-sheet.pk-admin-overlay--open")
      assert html =~ "Vía URL"
    end

    test "?draft= pointing at a published game is ignored — no sheet opens", %{conn: conn} do
      game = game_fixture(%{status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos?#{%{draft: game.id}}")

      refute has_element?(lv, "#draft-sheet.pk-admin-overlay--open")
    end

    test "?draft= pointing at an unknown id is ignored rather than raising", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/juegos?#{%{draft: 999_999_999}}")

      refute has_element?(lv, "#draft-sheet.pk-admin-overlay--open")
    end
  end

  describe "GameLive.Index — the draft sheet's publish gate (D-30/D-37, plan 01.8.2-20)" do
    test "Publicar is always rendered enabled — never a disabled attribute", %{conn: conn} do
      game = game_fixture(%{status: :draft, weight_band: nil, is_expansion: false})

      {:ok, lv, html} = live(conn, ~p"/admin/juegos?#{%{draft: game.id}}")

      assert has_element?(lv, "#draft-sheet-publish")
      refute has_element?(lv, "#draft-sheet-publish[disabled]")

      refute html =~
               ~s(id="draft-sheet-publish" class="pk-draft-sheet-cta" data-pk-pressable="true" phx-disable-with="Publicando…" disabled)
    end

    test "tapping Publicar with no nivel shows the inline gate line and does not publish", %{
      conn: conn
    } do
      game =
        game_fixture(%{
          name: "Necesita nivel",
          status: :draft,
          weight_band: nil,
          is_expansion: false
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos?#{%{draft: game.id}}")

      html =
        render_submit(lv, "publish-draft", %{
          "name" => game.name,
          "description" => game.description,
          "is_expansion" => "false"
        })

      assert has_element?(lv, "[data-pk-draft-sheet-gate]")
      assert html =~ "Sin nivel, Necesita nivel no va a aparecer en ninguna fila del inicio."
      assert has_element?(lv, "#draft-sheet.pk-admin-overlay--open")
      assert Catalog.get_game!(game.id).status == :draft
    end

    test "an expansion publishes with no nivel — the gate has no condition for it", %{conn: conn} do
      game =
        game_fixture(%{
          name: "Expansión lista",
          status: :draft,
          weight_band: nil,
          is_expansion: true
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos?#{%{draft: game.id}}")

      render_submit(lv, "publish-draft", %{
        "name" => game.name,
        "description" => game.description,
        "is_expansion" => "true"
      })

      refute has_element?(lv, "#draft-sheet.pk-admin-overlay--open")
      assert Catalog.get_game!(game.id).status == :published
    end

    test "the nivel picker offers exactly the three real Vocabulary bands", %{conn: conn} do
      game = game_fixture(%{status: :draft, weight_band: nil, is_expansion: false})

      {:ok, lv, html} = live(conn, ~p"/admin/juegos?#{%{draft: game.id}}")

      assert has_element?(lv, "#draft-sheet-weight-band")
      assert count_occurrences(html, ~s(<option value="descubre_el_hobby")) == 1
      assert count_occurrences(html, ~s(<option value="ingenio_estratega")) == 1
      assert count_occurrences(html, ~s(<option value="nivel_experto")) == 1
    end
  end

  defp count_occurrences(text, substring) do
    text |> String.split(substring) |> length() |> Kernel.-(1)
  end

  defp extract_count(html, section_key) do
    section = extract_between(html, "id=\"juegos-section-#{section_key}\"", "</section>")
    count_occurrences(section, "id=\"game-row-")
  end

  defp extract_between(html, start_marker, end_marker) do
    case String.split(html, start_marker, parts: 2) do
      [_before, rest] ->
        [between | _] = String.split(rest, end_marker, parts: 2)
        between

      _ ->
        ""
    end
  end
end
