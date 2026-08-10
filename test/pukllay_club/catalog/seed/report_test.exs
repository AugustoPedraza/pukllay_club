defmodule PukllayClub.Catalog.Seed.ReportTest do
  use ExUnit.Case, async: true

  alias PukllayClub.Catalog.Seed.Report

  describe "render/1" do
    test "states the analyzed row count" do
      report = Report.new() |> Report.set_rows_analyzed(434)

      assert Report.render(report) =~ "**Analyzed rows:** 434"
    end

    test "renders the unrecognized hashtag cells section with row, column, and value" do
      report =
        Report.new()
        |> Report.add(:unrecognized_hashtags, %{row: 12, name: "Foo", column: "#NivelExperto", value: "di"})

      rendered = Report.render(report)

      assert rendered =~ "## Unrecognized hashtag cells"
      assert rendered =~ "**Count:** 1"
      assert rendered =~ "| 12 | Foo | #NivelExperto | di |"
    end

    test "a zero-finding section still renders with an explicit count" do
      report = Report.new()
      rendered = Report.render(report)

      assert rendered =~ "## BGG ids with no returned item"
      assert rendered =~ "**Count:** 0"
      assert rendered =~ "## No Spanish edition found"
      assert rendered =~ "**Count:** 0"
    end

    test "renders every row of a duplicate BGG_ID group" do
      report =
        Report.new()
        |> Report.add(:duplicate_bgg_id, %{
          bgg_id: 163_412,
          rows: [%{row: 88, name: "Game A"}, %{row: 201, name: "Game B"}]
        })

      rendered = Report.render(report)

      assert rendered =~ "### BGG_ID 163412"
      assert rendered =~ "Row 88: Game A"
      assert rendered =~ "Row 201: Game B"
    end

    test "splits zero-hashtag rows into peso-resolved and unresolved counts" do
      report =
        Report.new()
        |> Report.add(:zero_hashtag_peso_resolved, %{row: 5, name: "Game A", band: "ingenio_estratega"})
        |> Report.add(:zero_hashtag_unresolved, %{row: 9, name: "Game B"})

      rendered = Report.render(report)

      assert rendered =~ "**Peso-resolved:** 1"
      assert rendered =~ "**Unresolved:** 1"
    end

    test "ranks uncovered mechanic terms by observed frequency, covered terms excluded" do
      report =
        Report.new()
        |> Report.add(:observed_mechanics, "Set Collection")
        |> Report.add(:observed_mechanics, "Legacy Game")
        |> Report.add(:observed_mechanics, "Legacy Game")
        |> Report.add(:observed_mechanics, "Storytelling")

      rendered = Report.render(report)

      assert rendered =~ "## Uncovered mechanic terms"
      refute rendered =~ "Set Collection"
      legacy_index = :binary.match(rendered, "Legacy Game") |> elem(0)
      storytelling_index = :binary.match(rendered, "Storytelling") |> elem(0)
      assert legacy_index < storytelling_index
    end
  end

  describe "write!/2" do
    test "writes the rendered markdown to the given path" do
      path = Path.join(System.tmp_dir!(), "catalog_seed_report_test_#{System.unique_integer([:positive])}.md")
      on_exit(fn -> File.rm(path) end)

      report = Report.new() |> Report.set_rows_analyzed(3)
      Report.write!(report, path)

      assert File.read!(path) =~ "**Analyzed rows:** 3"
    end
  end
end
