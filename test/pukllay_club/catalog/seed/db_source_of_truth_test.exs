defmodule PukllayClub.Catalog.Seed.DbSourceOfTruthTest do
  @moduledoc """
  Guard test for D-09: proves the CSV seed path and its clobbering
  `Catalog.upsert_game!/1` upsert are gone, and that every surviving
  offline write path leaves a staff-curated game's club-owned fields
  (name, weight_band, is_expansion, tags, description) untouched.
  """
  use PukllayClub.DataCase, async: true

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.StatsEnricher
  alias PukllayClub.Repo

  @on_mars_fixture File.read!("test/support/fixtures/bgg_thing_on_mars.xml")

  describe "the CSV seed path is gone (D-09)" do
    test "mix catalog.seed no longer exists as a Mix task" do
      assert Mix.Task.get("catalog.seed") == nil
    end

    test "PukllayClub.Catalog.Seed.CsvImport no longer exists" do
      refute Code.ensure_loaded?(PukllayClub.Catalog.Seed.CsvImport)
    end

    test "Catalog.upsert_game!/1 no longer exists" do
      refute function_exported?(PukllayClub.Catalog, :upsert_game!, 1)
    end
  end

  describe "surviving offline tasks never touch club-owned fields (D-07, D-09)" do
    test "StatsEnricher's BGG re-enrichment and artist backfill leave a staff-curated game's owned fields unchanged" do
      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, @on_mars_fixture)
      end)

      {:ok, credentials} = Credentials.fetch()

      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Un Nombre Curado Por Staff",
          weight_band: "ingenio_estratega",
          is_expansion: true,
          tags: ["#CreaConexiones"],
          description: "Una descripción curada en español, editada por el staff.",
          bgg_payload: %{"artists" => ["Spirit Artist"]}
        })

      StatsEnricher.backfill_artists_from_payload()
      StatsEnricher.enrich_from_bgg(credentials, delay_ms: 0)

      reloaded = Repo.get!(Game, game.id)

      assert reloaded.name == game.name
      assert reloaded.weight_band == game.weight_band
      assert reloaded.is_expansion == game.is_expansion
      assert reloaded.tags == game.tags
      assert reloaded.description == game.description
    end
  end

  describe "the translate task's candidate selection never re-selects an edited Spanish description (D-06, D-07, D-09)" do
    test "candidates/0 excludes a Spanish-described game and includes a still-English one, with no flag passed" do
      spanish_game =
        game_fixture(%{
          description: "Una descripción curada en español, editada por el staff.",
          bgg_payload: %{"description" => "An English description from BGG."}
        })

      english_game =
        game_fixture(%{
          description: "This description is still in English and has not been translated yet.",
          bgg_payload: %{"description" => "Another English description from BGG."}
        })

      candidate_ids = Enum.map(Mix.Tasks.Catalog.TranslateDescriptions.candidates(), & &1.id)

      refute spanish_game.id in candidate_ids
      assert english_game.id in candidate_ids
    end
  end
end
