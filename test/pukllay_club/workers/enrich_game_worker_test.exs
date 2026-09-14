defmodule PukllayClub.Workers.EnrichGameWorkerTest do
  use PukllayClub.DataCase, async: false
  use Oban.Testing, repo: PukllayClub.Repo

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.ImagePipeline
  alias PukllayClub.Catalog.Seed.TranslatedDescription
  alias PukllayClub.Workers.EnrichGameWorker

  @fixture File.read!("test/support/fixtures/bgg_thing_on_mars.xml")

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

    Req.Test.stub(BggClient, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("text/xml")
      |> Plug.Conn.send_resp(200, @fixture)
    end)

    Req.Test.stub(ImagePipeline, fn conn ->
      png =
        800
        |> Image.new!(600, color: [10, 20, 30])
        |> Image.write!(:memory, suffix: ".png")

      conn
      |> Plug.Conn.put_resp_content_type("image/png")
      |> Plug.Conn.send_resp(200, png)
    end)

    :ok
  end

  describe "perform/1" do
    test "fetches BGG and updates the draft with the real name and facts" do
      {:ok, game} = Catalog.add_game_from_bgg("184267")

      assert :ok = perform_job(EnrichGameWorker, %{"game_id" => game.id})

      updated = Catalog.get_game!(game.id)
      assert updated.name == "On Mars"
      assert updated.min_players == 1
      assert updated.max_players == 4
      assert updated.enrichment_status == "enriched"
      assert updated.status == :draft
      assert updated.description == "Descripción en español."
      assert updated.thumbnail_url =~ "games/184267/cover-thumb.webp"
      assert updated.cover_url =~ "games/184267/cover-large.webp"
    end

    test "keeps a staff-renamed game's name" do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Nombre elegido por el staff",
          description: nil,
          thumbnail_url: nil,
          cover_url: nil,
          status: :draft,
          enrichment_status: "pending"
        })

      assert :ok = perform_job(EnrichGameWorker, %{"game_id" => game.id})

      assert Catalog.get_game!(game.id).name == "Nombre elegido por el staff"
    end

    test "returns an Oban-visible error when BGG has no matching item" do
      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, "<items></items>")
      end)

      game =
        game_fixture(%{bgg_id: 999_999_999, status: :draft, enrichment_status: "pending"})

      assert {:error, :bgg_missing} = perform_job(EnrichGameWorker, %{"game_id" => game.id})
    end

    test "broadcasts {:game_enriched, game_id} on \"admin:games\" after a successful enrichment" do
      {:ok, game} = Catalog.add_game_from_bgg("184267")

      Phoenix.PubSub.subscribe(PukllayClub.PubSub, "admin:games")

      assert :ok = perform_job(EnrichGameWorker, %{"game_id" => game.id})

      assert_received {:game_enriched, game_id}
      assert game_id == game.id
    end
  end

  describe "add_game_from_bgg/1 -> Oban job enqueuing" do
    test "inserts a draft and enqueues exactly one EnrichGameWorker job with game_id" do
      assert {:ok, game} = Catalog.add_game_from_bgg("266192")

      assert game.status == :draft
      assert game.enrichment_status == "pending"
      assert game.name == "Juego #266192"

      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => game.id})
    end

    test "returns {:error, :invalid_bgg_id} for non-numeric input" do
      assert {:error, :invalid_bgg_id} = Catalog.add_game_from_bgg("abc")
      assert {:error, :invalid_bgg_id} = Catalog.add_game_from_bgg("")
      assert {:error, :invalid_bgg_id} = Catalog.add_game_from_bgg("https://boardgamegeek.com/boardgame/266192")
    end
  end
end
