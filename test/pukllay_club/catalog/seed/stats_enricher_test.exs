defmodule PukllayClub.Catalog.Seed.StatsEnricherTest do
  use PukllayClub.DataCase, async: true

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.StatsEnricher
  alias PukllayClub.Repo

  @on_mars_fixture File.read!("test/support/fixtures/bgg_thing_on_mars.xml")

  setup do
    {:ok, credentials} = Credentials.fetch()
    %{credentials: credentials}
  end

  describe "enrich_from_bgg/2" do
    test "updates bgg_rating/bgg_rank/bgg_weight/artists/bgg_payload and leaves unrelated columns byte-identical",
         %{credentials: credentials} do
      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, @on_mars_fixture)
      end)

      game =
        game_fixture(%{
          bgg_id: 184_267,
          bgg_weight: nil,
          cover_url: "https://images.test.invalid/games/184267/cover-large.webp",
          thumbnail_url: "https://images.test.invalid/games/184267/cover-thumb.webp",
          gallery_urls: ["https://images.test.invalid/games/184267/gallery-1.webp"],
          description: "Descripción original sin tocar.",
          name: "On Mars",
          csv_row: 999
        })

      summary = StatsEnricher.enrich_from_bgg(credentials, delay_ms: 0)

      assert summary.candidates == 1
      assert summary.fetched == 1
      assert summary.updated == 1

      reloaded = Repo.get!(Game, game.id)

      assert reloaded.bgg_rank == 58
      assert is_float(reloaded.bgg_rating)
      assert reloaded.bgg_rating > 7.0
      assert is_float(reloaded.bgg_weight)
      assert reloaded.artists != []
      assert reloaded.bgg_payload

      # Untouched — the narrow allowlist never reaches these columns.
      assert reloaded.cover_url == game.cover_url
      assert reloaded.thumbnail_url == game.thumbnail_url
      assert reloaded.gallery_urls == game.gallery_urls
      assert reloaded.description == game.description
      assert reloaded.name == game.name
      assert reloaded.csv_row == game.csv_row
    end

    test "skips games whose bgg_id is nil — never included in a request, columns untouched", %{
      credentials: credentials
    } do
      Req.Test.stub(BggClient, fn _conn ->
        flunk("BGG must never be called for a game with no bgg_id")
      end)

      game = game_fixture(%{bgg_id: nil, bgg_weight: nil})

      summary = StatsEnricher.enrich_from_bgg(credentials, delay_ms: 0)

      assert summary.candidates == 0

      reloaded = Repo.get!(Game, game.id)
      assert reloaded.bgg_weight == nil
      assert reloaded.artists == []
    end

    test "a failed batch is named in the summary and games in other batches still update", %{
      credentials: credentials
    } do
      Req.Test.stub(BggClient, fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)

        case conn.query_params["id"] do
          "111" ->
            Plug.Conn.send_resp(conn, 404, "not found")

          "184267" ->
            conn
            |> Plug.Conn.put_resp_content_type("text/xml")
            |> Plug.Conn.send_resp(200, @on_mars_fixture)
        end
      end)

      failing_game = game_fixture(%{bgg_id: 111, bgg_weight: nil})
      succeeding_game = game_fixture(%{bgg_id: 184_267, bgg_weight: nil})

      summary = StatsEnricher.enrich_from_bgg(credentials, batch_size: 1, delay_ms: 0)

      assert length(summary.failed_batches) == 1
      assert {[111], {:http, 404}} = List.first(summary.failed_batches)

      assert Repo.get!(Game, failing_game.id).bgg_weight == nil
      assert is_float(Repo.get!(Game, succeeding_game.id).bgg_weight)
    end

    test "with dry_run: true performs the fetch but writes nothing", %{credentials: credentials} do
      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, @on_mars_fixture)
      end)

      game = game_fixture(%{bgg_id: 184_267, bgg_weight: nil})

      summary = StatsEnricher.enrich_from_bgg(credentials, dry_run: true, delay_ms: 0)

      assert summary.fetched == 1

      reloaded = Repo.get!(Game, game.id)
      assert reloaded.bgg_weight == nil
      assert reloaded.bgg_rating == nil
      assert reloaded.bgg_rank == nil
      assert reloaded.artists == []
    end
  end

  describe "backfill_artists_from_payload/1" do
    test "dedupes a stored payload's artists, preserving first-appearance order, with no HTTP request" do
      game =
        game_fixture(%{
          bgg_payload: %{"artists" => ["Spirit Artist", "Other Artist", "Spirit Artist", "Other Artist", "Third"]}
        })

      summary = StatsEnricher.backfill_artists_from_payload()

      assert summary.scanned == 1
      assert summary.updated == 1
      assert summary.deduplicated == 1

      reloaded = Repo.get!(Game, game.id)
      assert reloaded.artists == ["Spirit Artist", "Other Artist", "Third"]
    end

    test "leaves a game whose payload has no artists key at the empty-list default, and is idempotent" do
      game = game_fixture(%{bgg_payload: %{"name" => "No artists here"}})

      summary1 = StatsEnricher.backfill_artists_from_payload()
      assert summary1.deduplicated == 0
      assert Repo.get!(Game, game.id).artists == []

      summary2 = StatsEnricher.backfill_artists_from_payload()
      assert summary2.deduplicated == 0
      assert Repo.get!(Game, game.id).artists == []
    end
  end
end
