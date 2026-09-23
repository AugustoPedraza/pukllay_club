defmodule PukllayClub.Catalog.Seed.StatsAudit do
  @moduledoc """
  Read-only audit of the array columns
  `PukllayClub.Catalog.Seed.StatsEnricher` writes (`publishers`, `artists`,
  `mechanics`, `designers`). Has **no write path whatsoever** — it exists so
  a production BGG stats repair run
  (`PukllayClub.Release.enrich_bgg_stats/1`) can be *proved* to have
  worked rather than assumed, and is the measurement half of quick task
  260922-veq's before/after discipline.

  `publishers` and `artists` are the *subject* of the repair — quick task
  260922-tum's `BggClient` xpath-scoping fix folded nested
  `boardgameversion` entries into these two columns only. `mechanics` and
  `designers`, plus `total_games`, are *controls*: the repair must leave
  them unchanged. If a control metric moves between a before/after pair of
  `report/0` calls, the run touched something outside its intended
  allowlist and the operator's runbook says to stop and restore.
  """

  import Ecto.Query

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Repo

  @audited_columns [:publishers, :artists, :mechanics, :designers]

  @doc """
  Loads every game's `id`, `bgg_id` and the four audited array columns in
  one query, then reduces them **in Elixir** — the duplicate rule is
  expressed once, never as a second copy in SQL, mirroring
  `PukllayClub.Catalog.BandAudit.mismatches/0` (01.8.1-13).

  Returns a map with a UTC ISO8601 `run_at`, `total_games`,
  `games_with_bgg_id`, and one nested stats map per column in
  `#{inspect(@audited_columns)}`. Each per-column map carries:

    * `max` — the largest raw entry count across all rows (a nil column
      counts as an empty list; the reported count is the stored length,
      never the deduplicated length — this measurement reports what is
      stored, it does not silently repair it)
    * `max_game_id` / `max_bgg_id` — the `id`/`bgg_id` of the row holding
      that maximum, so an operator can spot-check the worst case against
      BGG's raw XML the way quick task 260922-tum did for bgg_id 432
    * `rows_with_duplicates` — the number of rows whose stored entry count
      differs from its unique entry count

  An empty catalog does not raise: every `max` is `0` and every
  `max_game_id`/`max_bgg_id` is `nil`.
  """
  @spec report() :: map()
  def report do
    rows =
      Game
      |> select([g], %{
        id: g.id,
        bgg_id: g.bgg_id,
        publishers: g.publishers,
        artists: g.artists,
        mechanics: g.mechanics,
        designers: g.designers
      })
      |> order_by([g], asc: g.id)
      |> Repo.all()

    column_stats = Map.new(@audited_columns, fn column -> {column, column_stats(rows, column)} end)

    Map.merge(
      %{
        run_at: DateTime.to_iso8601(DateTime.utc_now()),
        total_games: length(rows),
        games_with_bgg_id: Enum.count(rows, &(&1.bgg_id != nil))
      },
      column_stats
    )
  end

  defp column_stats(rows, column) do
    initial = %{max: 0, max_game_id: nil, max_bgg_id: nil, rows_with_duplicates: 0}

    Enum.reduce(rows, initial, fn row, acc ->
      values = List.wrap(Map.get(row, column))
      count = length(values)
      duplicate? = count != length(Enum.uniq(values))

      acc
      |> maybe_update_max(count, row)
      |> Map.update!(:rows_with_duplicates, &(&1 + if(duplicate?, do: 1, else: 0)))
    end)
  end

  defp maybe_update_max(acc, count, row) when count > acc.max do
    %{acc | max: count, max_game_id: row.id, max_bgg_id: row.bgg_id}
  end

  defp maybe_update_max(acc, _count, _row), do: acc
end
