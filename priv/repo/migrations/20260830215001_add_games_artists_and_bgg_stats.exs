defmodule PukllayClub.Repo.Migrations.AddGamesArtistsAndBggStats do
  use Ecto.Migration

  @moduledoc """
  Adds `games.artists`, `games.bgg_rating` and `games.bgg_rank` (D-05/D-06)
  and normalizes any already-stored `bgg_weight = 0` to `NULL`.

  Unlike `add_games_is_expansion.exs`'s precedent, **no backfill for the
  three new columns lives here** — the offline `mix catalog.enrich_bgg_stats`
  and `mix catalog.backfill_artists` Mix tasks (01.3-01 Task 2) populate them
  after this migration runs, since populating `artists`/`bgg_rating`/
  `bgg_rank` needs either a live BGG re-enrichment pass or an
  order-preserving dedup Postgres has no trivial one-liner for — neither
  belongs in a migration.

  The `bgg_weight = 0 -> NULL` normalization DOES run here, inline, because
  it is a pure data-correction on an existing column: BGG emits a numeric
  zero rather than omitting the element when it has no weight rating for a
  game, and Elixir's plain-truthiness render guards would print that zero as
  a fabricated-looking score. Measured against `pukllay_club_dev` on
  2026-08-29: exactly 2 rows held `bgg_weight = 0`. The down migration is
  deliberately inert (`SELECT 1`) rather than restoring zeros — guessing
  which of the 49 already-`NULL` rows were originally zeros is not a safe
  reversal, and restoring the 2 known zeros would silently reintroduce the
  exact bug this migration exists to fix.
  """

  def change do
    alter table(:games) do
      add :artists, {:array, :string}, default: []
      add :bgg_rating, :float
      add :bgg_rank, :integer
    end

    execute(
      "UPDATE games SET bgg_weight = NULL WHERE bgg_weight = 0",
      "SELECT 1"
    )
  end
end
