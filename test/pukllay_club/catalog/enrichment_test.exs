defmodule PukllayClub.Catalog.EnrichmentTest do
  use PukllayClub.DataCase, async: false

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Enrichment
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.OgCard
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.ImagePipeline
  alias PukllayClub.Catalog.Seed.TranslatedDescription

  @fixture File.read!("test/support/fixtures/bgg_thing_on_mars.xml")
  @no_image_fixture "<items></items>"

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
    {:ok, credentials} = Credentials.fetch()

    previous_storage = Application.get_env(:pukllay_club, :catalog_storage)
    previous_translate_call = Application.get_env(:pukllay_club, :enrichment_translate_call)
    Application.put_env(:pukllay_club, :catalog_storage, FakeStorage)

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

    %{credentials: credentials}
  end

  defp stub_bgg(xml \\ nil) do
    Req.Test.stub(BggClient, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("text/xml")
      |> Plug.Conn.send_resp(200, xml || @fixture)
    end)
  end

  defp solid_png(width, height, color) do
    width
    |> Image.new!(height, color: color)
    |> Image.write!(:memory, suffix: ".png")
  end

  defp stub_cover_fetch(png_binary \\ nil) do
    Req.Test.stub(ImagePipeline, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("image/png")
      |> Plug.Conn.send_resp(200, png_binary || solid_png(800, 600, [10, 20, 30]))
    end)
  end

  defp translate_stub_ok(spanish_text) do
    fn _params, _opts -> {:ok, %TranslatedDescription{description_es: spanish_text}} end
  end

  defp translate_stub_error(reason) do
    fn _params, _opts -> {:error, reason} end
  end

  describe "attrs_from_bgg_item/1" do
    test "maps a parsed BGG item to BGG-derived columns only" do
      stub_bgg()
      {:ok, credentials} = Credentials.fetch()
      {:ok, [item]} = BggClient.fetch_batch([184_267], credentials)

      attrs = Enrichment.attrs_from_bgg_item(item)

      assert attrs.year_published == 2020
      assert attrs.min_players == 1
      assert attrs.max_players == 4
      assert attrs.bgg_weight == item.average_weight
      assert attrs.bgg_rating == item.average_rating
      assert attrs.bgg_rank == item.rank
      assert attrs.themes == item.categories
      assert attrs.mechanics == item.mechanics
      assert attrs.designers == item.designers
      assert attrs.artists == item.artists
      assert attrs.publishers == item.publishers
      assert attrs.bgg_payload == item
      refute Map.has_key?(attrs, :name)
      refute String.contains?(attrs.description, "&mdash;")
    end
  end

  describe "enrich/2 — BGG facts and club-owned-value rules" do
    setup %{credentials: credentials} do
      stub_bgg()
      stub_cover_fetch()
      Application.put_env(:pukllay_club, :enrichment_translate_call, translate_stub_ok("Descripción en español."))
      %{credentials: credentials}
    end

    test "fills the placeholder name, facts, and description, and sets enrichment_status to enriched",
         %{credentials: credentials} do
      game =
        %Game{}
        |> Game.draft_changeset(%{bgg_id: 184_267})
        |> Repo.insert!()

      assert {:ok, enriched} = Enrichment.enrich(game, credentials)

      assert enriched.name == "On Mars"
      assert enriched.min_players == 1
      assert enriched.max_players == 4
      assert enriched.enrichment_status == "enriched"
      assert enriched.status == :draft
      assert enriched.description == "Descripción en español."
    end

    test "keeps a staff-renamed game's name across enrichment", %{credentials: credentials} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Nombre elegido por el staff",
          description: nil,
          thumbnail_url: nil,
          cover_url: nil,
          enrichment_status: "pending",
          status: :draft
        })

      assert {:ok, enriched} = Enrichment.enrich(game, credentials)

      assert enriched.name == "Nombre elegido por el staff"
    end

    test "keeps a non-blank description across enrichment, and never calls the translator", %{
      credentials: credentials
    } do
      Application.put_env(
        :pukllay_club,
        :enrichment_translate_call,
        fn _params, _opts -> flunk("translator must not be called when the description is not blank") end
      )

      game =
        game_fixture(%{
          bgg_id: 184_267,
          description: "Descripción ya cargada por el staff.",
          thumbnail_url: nil,
          cover_url: nil,
          enrichment_status: "pending",
          status: :draft
        })

      assert {:ok, enriched} = Enrichment.enrich(game, credentials)

      assert enriched.description == "Descripción ya cargada por el staff."
    end

    test "returns {:error, :bgg_missing} when BGG returns no item", %{credentials: credentials} do
      stub_bgg(@no_image_fixture)

      game =
        %Game{}
        |> Game.draft_changeset(%{bgg_id: 999_999_999})
        |> Repo.insert!()

      assert {:error, :bgg_missing} = Enrichment.enrich(game, credentials)
    end

    test "returns {:error, reason} on a non-retryable HTTP failure", %{credentials: credentials} do
      Req.Test.stub(BggClient, fn conn ->
        Plug.Conn.send_resp(conn, 401, "unauthorized")
      end)

      game =
        %Game{}
        |> Game.draft_changeset(%{bgg_id: 184_267})
        |> Repo.insert!()

      assert {:error, {:http, 401}} = Enrichment.enrich(game, credentials)
    end
  end

  describe "enrich/2 — images and OG card (D-02, D-05)" do
    setup %{credentials: credentials} do
      stub_bgg()
      Application.put_env(:pukllay_club, :enrichment_translate_call, translate_stub_ok("Descripción en español."))
      %{credentials: credentials}
    end

    test "uploads cover/thumbnail under games/<bgg_id>/ and generates an OG card", %{credentials: credentials} do
      stub_cover_fetch()

      game =
        %Game{}
        |> Game.draft_changeset(%{bgg_id: 184_267})
        |> Repo.insert!()

      assert {:ok, enriched} = Enrichment.enrich(game, credentials)

      assert enriched.thumbnail_url == "https://images.test.invalid/games/184267/cover-thumb.webp"
      assert enriched.cover_url == "https://images.test.invalid/games/184267/cover-large.webp"
      assert enriched.gallery_urls == []

      og_key = OgCard.object_key_for(enriched)
      assert og_key == "games/184267/og-card.webp"
      assert Process.get({:fake_storage_put, og_key}) > 0
    end

    test "an image-processing error returns {:error, {:image, reason}} and writes nothing", %{
      credentials: credentials
    } do
      Req.Test.stub(ImagePipeline, fn conn ->
        Plug.Conn.send_resp(conn, 500, "boom")
      end)

      game =
        %Game{}
        |> Game.draft_changeset(%{bgg_id: 184_267})
        |> Repo.insert!()

      assert {:error, {:image, _reason}} = Enrichment.enrich(game, credentials)

      untouched = Repo.get!(Game, game.id)
      assert untouched.enrichment_status == "pending"
      assert untouched.cover_url == nil
    end

    test "no BGG image succeeds with nil cover fields and uploads no OG card", %{credentials: credentials} do
      stub_bgg(no_image_item_fixture())

      game =
        %Game{}
        |> Game.draft_changeset(%{bgg_id: 184_267})
        |> Repo.insert!()

      assert {:ok, enriched} = Enrichment.enrich(game, credentials)

      assert enriched.cover_url == nil
      assert enriched.thumbnail_url == nil
      assert enriched.gallery_urls == []
      assert enriched.enrichment_status == "enriched"
    end
  end

  describe "enrich/2 — Spanish translation (D-06)" do
    setup %{credentials: credentials} do
      stub_bgg()
      stub_cover_fetch()
      %{credentials: credentials}
    end

    test "stores the Gemini translation when it succeeds", %{credentials: credentials} do
      Application.put_env(:pukllay_club, :enrichment_translate_call, translate_stub_ok("Un juego sobre Marte."))

      game =
        %Game{}
        |> Game.draft_changeset(%{bgg_id: 184_267})
        |> Repo.insert!()

      assert {:ok, enriched} = Enrichment.enrich(game, credentials)
      assert enriched.description == "Un juego sobre Marte."
    end

    test "keeps the cleaned English text when the translator errors", %{credentials: credentials} do
      Application.put_env(:pukllay_club, :enrichment_translate_call, translate_stub_error(:timeout))

      game =
        %Game{}
        |> Game.draft_changeset(%{bgg_id: 184_267})
        |> Repo.insert!()

      assert {:ok, enriched} = Enrichment.enrich(game, credentials)
      assert is_binary(enriched.description)
      refute enriched.description =~ "&mdash;"
      assert enriched.enrichment_status == "enriched"
    end

    test "keeps the cleaned English text and never raises when the Gemini key is missing", %{
      credentials: credentials
    } do
      no_key_credentials = %{credentials | gemini_api_key: nil}

      Application.put_env(
        :pukllay_club,
        :enrichment_translate_call,
        fn _params, _opts -> flunk("translator must not be called without a Gemini key") end
      )

      game =
        %Game{}
        |> Game.draft_changeset(%{bgg_id: 184_267})
        |> Repo.insert!()

      assert {:ok, enriched} = Enrichment.enrich(game, no_key_credentials)
      assert is_binary(enriched.description)
    end
  end

  # An `<item>` with no `<image>`/`<versions>` at all — `select_cover/1` then
  # returns `{:error, :no_image}`.
  defp no_image_item_fixture do
    ~s(<?xml version="1.0"?><items><item type="boardgame" id="184267">) <>
      ~s(<name type="primary" value="On Mars" /><yearpublished value="2020" />) <> ~s(</item></items>)
  end
end
