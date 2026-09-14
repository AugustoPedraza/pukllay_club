defmodule PukllayClub.Catalog.EnrichmentTest do
  use PukllayClub.DataCase, async: true

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Enrichment
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.Credentials

  @fixture File.read!("test/support/fixtures/bgg_thing_on_mars.xml")

  setup do
    {:ok, credentials} = Credentials.fetch()
    %{credentials: credentials}
  end

  describe "attrs_from_bgg_item/1" do
    test "maps a parsed BGG item to BGG-derived columns only" do
      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, @fixture)
      end)

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

  describe "enrich/2" do
    setup %{credentials: credentials} do
      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, @fixture)
      end)

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
      assert is_binary(enriched.description)
    end

    test "keeps a staff-renamed game's name across enrichment", %{credentials: credentials} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Nombre elegido por el staff",
          description: nil,
          enrichment_status: "pending",
          status: :draft
        })

      assert {:ok, enriched} = Enrichment.enrich(game, credentials)

      assert enriched.name == "Nombre elegido por el staff"
    end

    test "keeps a non-blank description across enrichment", %{credentials: credentials} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          description: "Descripción ya cargada por el staff.",
          enrichment_status: "pending",
          status: :draft
        })

      assert {:ok, enriched} = Enrichment.enrich(game, credentials)

      assert enriched.description == "Descripción ya cargada por el staff."
    end

    test "returns {:error, :bgg_missing} when BGG returns no item", %{credentials: credentials} do
      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, "<items></items>")
      end)

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
end
