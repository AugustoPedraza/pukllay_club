defmodule PukllayClub.ReleaseTest do
  use PukllayClub.DataCase, async: true

  import ExUnit.CaptureIO
  import ExUnit.CaptureLog
  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Release
  alias PukllayClub.Repo

  @on_mars_fixture File.read!("test/support/fixtures/bgg_thing_on_mars.xml")
  @report_path "priv/repo/seed_data/bgg_stats_enrichment_report.md"

  defp stub_on_mars do
    Req.Test.stub(BggClient, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("text/xml")
      |> Plug.Conn.send_resp(200, @on_mars_fixture)
    end)
  end

  describe "enrich_bgg_stats/1" do
    test "a live run prints one decodable JSON line and writes the row" do
      stub_on_mars()
      game = game_fixture(%{bgg_id: 184_267, bgg_rank: nil})

      out = capture_io(fn -> Release.enrich_bgg_stats(delay_ms: 0) end)

      payload = Jason.decode!(String.trim(out))
      assert payload["candidates"] == 1
      assert payload["updated"] == 1
      assert payload["dry_run"] == false
      assert payload["failed_batches"] == []
      assert is_binary(payload["run_at"])

      assert Repo.get!(Game, game.id).bgg_rank
    end

    test "a dry run writes nothing and says so" do
      stub_on_mars()
      game = game_fixture(%{bgg_id: 184_267, bgg_rank: nil})

      out = capture_io(fn -> Release.enrich_bgg_stats(dry_run: true, delay_ms: 0) end)

      payload = Jason.decode!(String.trim(out))
      assert payload["dry_run"] == true
      assert payload["updated"] == 1

      assert Repo.get!(Game, game.id).bgg_rank == nil
    end

    test "a failed batch is still encodable, with a string reason and integer ids" do
      Req.Test.stub(BggClient, fn conn -> Plug.Conn.send_resp(conn, 403, "forbidden") end)
      game_fixture(%{bgg_id: 999_999, bgg_rank: nil})

      out = capture_io(fn -> Release.enrich_bgg_stats(delay_ms: 0) end)

      payload = Jason.decode!(String.trim(out))
      assert [failed | _] = payload["failed_batches"]
      assert is_binary(failed["reason"])
      assert Enum.all?(failed["ids"], &is_integer/1)
    end

    test "no raw credential value reaches stdout or the log" do
      stub_on_mars()
      game_fixture(%{bgg_id: 184_267, bgg_rank: nil})

      log =
        capture_log(fn ->
          out = capture_io(fn -> Release.enrich_bgg_stats(delay_ms: 0) end)
          refute out =~ "test-token"
        end)

      refute log =~ "test-token"
    end

    test "nothing is written under priv/" do
      stub_on_mars()
      game_fixture(%{bgg_id: 184_267, bgg_rank: nil})

      before = File.read(@report_path)
      capture_io(fn -> Release.enrich_bgg_stats(delay_ms: 0) end)

      assert File.read(@report_path) == before
    end
  end

  describe "ensure_live_node!/1" do
    test "refuses a node that is missing a required process" do
      assert_raise RuntimeError, ~r/ensure_all_started/, fn ->
        Release.ensure_live_node!([:gsd_no_such_process])
      end

      message =
        try do
          Release.ensure_live_node!([:gsd_no_such_process])
          nil
        rescue
          e -> Exception.message(e)
        end

      assert message =~ ":gsd_no_such_process"
    end

    test "passes on a real node" do
      assert Release.ensure_live_node!() == :ok
    end
  end

  describe "bgg_stats_report/0" do
    test "prints one decodable JSON line and returns the same map" do
      game_fixture(%{bgg_id: 13, publishers: ["Devir", "Devir"]})

      out = capture_io(fn -> Release.bgg_stats_report() end)

      payload = Jason.decode!(String.trim(out))
      assert payload["total_games"] == 1
      assert payload["games_with_bgg_id"] == 1
      assert is_binary(payload["run_at"])

      for column <- ["publishers", "artists", "mechanics", "designers"] do
        assert is_map(payload[column])
      end
    end
  end
end
