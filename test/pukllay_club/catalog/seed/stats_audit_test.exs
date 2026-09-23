defmodule PukllayClub.Catalog.Seed.StatsAuditTest do
  use PukllayClub.DataCase, async: true

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Seed.StatsAudit

  describe "report/0" do
    test "clean catalog reports real maxima and zero duplicates" do
      game_fixture(%{publishers: ["Devir", "Asmodee", "Z-Man Games"]})
      game_fixture(%{publishers: ["Devir"]})

      report = StatsAudit.report()

      assert report.total_games == 2
      assert report.publishers.max == 3
      assert report.publishers.rows_with_duplicates == 0
    end

    test "a seeded duplicate IS reported (the negative test)" do
      game_fixture(%{publishers: ["Devir", "Asmodee", "Devir"]})

      report = StatsAudit.report()

      assert report.publishers.rows_with_duplicates == 1
      # The raw stored length, not the deduplicated length — the
      # measurement reports what is stored, it does not silently repair it.
      assert report.publishers.max == 3
    end

    test "columns are not cross-wired" do
      game_fixture(%{
        publishers: ["Devir", "Devir"],
        mechanics: ["Dice Rolling"],
        designers: ["Klaus Teuber"]
      })

      report = StatsAudit.report()

      assert report.publishers.rows_with_duplicates == 1
      assert report.mechanics.rows_with_duplicates == 0
      assert report.designers.rows_with_duplicates == 0
    end

    test "empty and absent arrays are counted as zero, not crashes" do
      game_fixture(%{publishers: []})
      game_fixture(%{bgg_id: nil, publishers: []})

      report = StatsAudit.report()

      assert report.publishers.max == 0
      assert report.games_with_bgg_id == 1
    end
  end
end
