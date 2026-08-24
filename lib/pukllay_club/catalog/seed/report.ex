defmodule PukllayClub.Catalog.Seed.Report do
  @moduledoc """
  Accumulates seed-run findings across every documented real-data quirk
  (D-18/D-19/D-20, D-04's no-Spanish-edition exceptions) and renders them as
  reviewable markdown at `priv/repo/seed_data/catalog_seed_report.md`.

  Every section states an explicit count, including zero, so a clean run is
  visibly clean rather than an absent section. Rendering is deterministic —
  no timestamps, no random ordering — so `mix catalog.seed --report-only`
  reproduces the committed report byte-for-byte given the same CSV.

  Also carries the 01-VOCABULARY.md sections 3a/3b covered-term lists as
  module attributes (until 01-06 creates `PukllayClub.Catalog.Vocabulary`),
  so every observed BGG mechanic/category not yet in the glossary is
  surfaced here, ranked by frequency, for 01-06 to act on.
  """

  defstruct rows_analyzed: 0,
            unrecognized_hashtags: [],
            weight_conflicts: [],
            zero_hashtag_peso_resolved: [],
            zero_hashtag_unresolved: [],
            no_bgg_id: [],
            duplicate_bgg_id: [],
            bgg_missing: [],
            no_spanish_edition: [],
            observed_mechanics: [],
            observed_categories: []

  @type category ::
          :unrecognized_hashtags
          | :weight_conflicts
          | :zero_hashtag_peso_resolved
          | :zero_hashtag_unresolved
          | :no_bgg_id
          | :duplicate_bgg_id
          | :bgg_missing
          | :no_spanish_edition
          | :observed_mechanics
          | :observed_categories

  @type t :: %__MODULE__{}

  # 01-VOCABULARY.md section 3a — the 25 covered mechanic terms (raw BGG values).
  @covered_mechanics [
    "Set Collection",
    "Hand Management",
    "Open Drafting",
    "End Game Bonuses",
    "Solo / Solitaire Game",
    "Tile Placement",
    "Variable Set-up",
    "Dice Rolling",
    "Variable Player Powers",
    "Worker Placement",
    "Contracts",
    "Area Majority / Influence",
    "Cooperative Game",
    "Modular Board",
    "Take That",
    "Push Your Luck",
    "Pattern Building",
    "Race",
    "Deck, Bag, and Pool Building",
    "Simultaneous Action Selection",
    "Grid Movement",
    "Auction / Bidding",
    "Memory",
    "Real-Time",
    "Deduction"
  ]

  # 01-VOCABULARY.md section 3b — the 22 covered category terms (raw BGG values).
  @covered_categories [
    "Card Game",
    "Party Game",
    "Fantasy",
    "Science Fiction",
    "Animals",
    "Economic",
    "Adventure",
    "Medieval",
    "Ancient",
    "Nautical",
    "Farming",
    "City Building",
    "Deduction",
    "Horror",
    "Miniatures",
    "Puzzle",
    "Racing",
    "Space Exploration",
    "Trains",
    "Wargame",
    "Word Game",
    "Children's Game"
  ]

  @doc "A fresh, empty accumulator."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc "Records the total number of CSV rows analyzed this run."
  @spec set_rows_analyzed(t(), non_neg_integer()) :: t()
  def set_rows_analyzed(%__MODULE__{} = report, count) when is_integer(count) and count >= 0 do
    %{report | rows_analyzed: count}
  end

  @doc """
  Appends `finding` to `category`. `finding` shape depends on the category —
  see `render/1`'s per-section rendering for what each one expects.
  """
  @spec add(t(), category(), term()) :: t()
  def add(%__MODULE__{} = report, category, finding) do
    Map.update!(report, category, &[finding | &1])
  end

  @doc "Renders every accumulated finding as reviewable, deterministic markdown."
  @spec render(t()) :: String.t()
  def render(%__MODULE__{} = report) do
    Enum.join(
      [
        "# Catalog Seed Report\n",
        "\n**Analyzed rows:** #{report.rows_analyzed}\n",
        unrecognized_hashtags_section(report),
        weight_conflicts_section(report),
        zero_hashtag_section(report),
        no_bgg_id_section(report),
        duplicate_bgg_id_section(report),
        bgg_missing_section(report),
        no_spanish_edition_section(report),
        uncovered_terms_section("Uncovered mechanic terms", report.observed_mechanics, @covered_mechanics),
        uncovered_terms_section("Uncovered category terms", report.observed_categories, @covered_categories)
      ],
      "\n"
    )
  end

  @doc "Renders and writes the report to `path`, creating parent directories as needed."
  @spec write!(t(), String.t()) :: t()
  def write!(%__MODULE__{} = report, path) do
    path |> Path.dirname() |> File.mkdir_p!()
    File.write!(path, render(report))
    report
  end

  defp unrecognized_hashtags_section(report) do
    rows = report.unrecognized_hashtags |> Enum.reverse() |> Enum.sort_by(& &1.row)

    table =
      Enum.map_join(rows, "\n", fn %{row: row, name: name, column: column, value: value} ->
        "| #{row} | #{cell(name)} | #{cell(column)} | #{cell(value)} |"
      end)

    """
    ## Unrecognized hashtag cells (D-20)

    **Count:** #{length(rows)}
    #{if rows == [], do: "", else: "\n| Row | Name | Column | Value |\n|---|---|---|---|\n" <> table}
    """
  end

  defp weight_conflicts_section(report) do
    rows = report.weight_conflicts |> Enum.reverse() |> Enum.sort_by(& &1.row)

    table =
      Enum.map_join(rows, "\n", fn %{row: row, name: name, resolution: resolution} ->
        "| #{row} | #{cell(name)} | #{cell(resolution)} |"
      end)

    """
    ## Weight-band conflicts (2+ hashtags true)

    **Count:** #{length(rows)}
    #{if rows == [], do: "", else: "\n| Row | Name | Resolution |\n|---|---|---|\n" <> table}
    """
  end

  defp zero_hashtag_section(report) do
    resolved = report.zero_hashtag_peso_resolved |> Enum.reverse() |> Enum.sort_by(& &1.row)
    unresolved = report.zero_hashtag_unresolved |> Enum.reverse() |> Enum.sort_by(& &1.row)

    resolved_table =
      Enum.map_join(resolved, "\n", fn %{row: row, name: name, band: band} ->
        "| #{row} | #{cell(name)} | #{cell(band)} |"
      end)

    unresolved_table =
      Enum.map_join(unresolved, "\n", fn %{row: row, name: name} -> "| #{row} | #{cell(name)} |" end)

    """
    ## Zero-hashtag rows

    **Peso-resolved:** #{length(resolved)}
    **Unresolved:** #{length(unresolved)}

    ### Peso-resolved
    #{if resolved == [], do: "_none_", else: "| Row | Name | Band |\n|---|---|---|\n" <> resolved_table}

    ### Unresolved
    #{if unresolved == [], do: "_none_", else: "| Row | Name |\n|---|---|\n" <> unresolved_table}
    """
  end

  defp no_bgg_id_section(report) do
    rows = report.no_bgg_id |> Enum.reverse() |> Enum.sort_by(& &1.row)
    table = Enum.map_join(rows, "\n", fn %{row: row, name: name} -> "| #{row} | #{cell(name)} |" end)

    """
    ## Rows with no BGG_ID (D-18)

    **Count:** #{length(rows)}
    #{if rows == [], do: "", else: "\n| Row | Name |\n|---|---|\n" <> table}
    """
  end

  defp duplicate_bgg_id_section(report) do
    groups = report.duplicate_bgg_id |> Enum.reverse() |> Enum.sort_by(& &1.bgg_id)

    groups_md =
      Enum.map_join(groups, "\n\n", fn %{bgg_id: bgg_id, rows: rows} ->
        rows_md = Enum.map_join(rows, "\n", fn %{row: row, name: name} -> "- Row #{row}: #{cell(name)}" end)
        "### BGG_ID #{bgg_id}\n#{rows_md}"
      end)

    """
    ## Duplicate BGG_ID groups (D-19)

    **Count:** #{length(groups)}
    #{if groups == [], do: "", else: "\n" <> groups_md}
    """
  end

  defp bgg_missing_section(report) do
    rows = report.bgg_missing |> Enum.reverse() |> Enum.sort_by(& &1.row)

    table =
      Enum.map_join(rows, "\n", fn %{row: row, name: name, bgg_id: bgg_id} ->
        "| #{row} | #{cell(name)} | #{bgg_id} |"
      end)

    """
    ## BGG ids with no returned item

    **Count:** #{length(rows)}
    #{if rows == [], do: "", else: "\n| Row | Name | BGG_ID |\n|---|---|---|\n" <> table}
    """
  end

  defp no_spanish_edition_section(report) do
    rows = report.no_spanish_edition |> Enum.reverse() |> Enum.sort_by(& &1.row)
    table = Enum.map_join(rows, "\n", fn %{row: row, name: name} -> "| #{row} | #{cell(name)} |" end)

    """
    ## No Spanish edition found (D-04)

    **Count:** #{length(rows)}
    #{if rows == [], do: "", else: "\n| Row | Name |\n|---|---|\n" <> table}
    """
  end

  defp uncovered_terms_section(title, observed, covered) do
    ranked =
      observed
      |> Enum.reject(&(&1 in covered))
      |> Enum.frequencies()
      |> Enum.sort_by(fn {term, count} -> {-count, term} end)

    table = Enum.map_join(ranked, "\n", fn {term, count} -> "| #{term} | #{count} |" end)

    """
    ## #{title}

    **Count:** #{length(ranked)}
    #{if ranked == [], do: "", else: "\n| Term | Occurrences |\n|---|---|\n" <> table}
    """
  end

  # A handful of real CSV cells (e.g. row 328's game name) carry an embedded
  # newline from the source export's own quoting. Collapsed to a single
  # space and pipes escaped so every finding renders as one clean markdown
  # table row instead of silently corrupting the table structure.
  defp cell(nil), do: ""

  defp cell(value) do
    value
    |> to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.replace("|", "\\|")
    |> String.trim()
  end
end
