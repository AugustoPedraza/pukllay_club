defmodule PukllayClub.Repo.Migrations.AddGamesCreatorIndexes do
  use Ecto.Migration

  @moduledoc """
  Adds GIN indexes on `games.designers` and `games.artists` (01.3-06,
  UAT gap G-01.3-1 item 3). `Catalog.maybe_filter_designers/2` and
  `maybe_filter_artists/2` (this plan) are the first queries to filter on
  either column with an array-overlap predicate — `designers` previously
  only ever fed the `search_vector` generated column (see
  `20260810172415_add_games_search_and_indexes.exs`) and `artists` was
  render-only (see `20260830215001_add_games_artists_and_bgg_stats.exs`),
  so neither had an index of its own until now. Both are additive,
  index-only changes; `create index/2` is reversible as-is, so no hand
  written `up`/`down` is needed.
  """

  def change do
    create index(:games, [:designers], using: :gin)
    create index(:games, [:artists], using: :gin)
  end
end
