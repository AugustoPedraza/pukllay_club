defmodule PukllayClub.Repo.Migrations.ValidateEnrichmentStatus do
  use Ecto.Migration

  @moduledoc """
  Adds a `games_enrichment_status_must_be_known` CHECK constraint (D-37 gate
  3), mirroring `add_status_to_games`'s `games_status_must_be_known` pattern
  (Pattern 2: column-level validation backed by a database-level constraint
  as defense in depth against a raw SQL write bypassing
  `Game.enrichment_changeset/2`'s `validate_inclusion/3`).

  Before this migration, `enrichment_status` was validated by
  `validate_inclusion(:enrichment_status, @enrichment_statuses)` only inside
  `Game.seed_changeset/2` — the retired CSV import path
  (`PukllayClub.Catalog.Enrichment`/`EnrichGameWorker` wrote through
  `enrichment_changeset/2`, which cast the column but never validated it).
  Nothing in the live application ever wrote an out-of-range value (verified
  2026-09-23 against the dev database: only `"bgg_missing"`, `"no_bgg_id"`,
  `"enriched"` are present, all valid members), so the normalization step
  below is defense-in-depth, not a real data fix.

  The five allowed values mirror `Game.@enrichment_statuses`
  (`~w(pending enriched no_bgg_id bgg_missing failed)`) — if that module
  attribute ever changes, this migration's list must change with it, exactly
  as `games_status_must_be_known` tracks `Game`'s `status` enum.
  """

  @allowed_statuses ~w(pending enriched no_bgg_id bgg_missing failed)
  @allowed_sql Enum.map_join(@allowed_statuses, ", ", &"'#{&1}'")
  @fallback_status "pending"

  def up do
    # Defense-in-depth normalization: any row whose current value isn't one
    # of the five known statuses is coerced to the pending/unknown member
    # before the constraint is created, so `up/0` can never fail on
    # pre-existing data it didn't cause.
    execute("""
    UPDATE games
    SET enrichment_status = '#{@fallback_status}'
    WHERE enrichment_status IS NOT NULL
      AND enrichment_status NOT IN (#{@allowed_sql})
    """)

    create constraint(:games, :games_enrichment_status_must_be_known,
             check: "enrichment_status IS NULL OR enrichment_status IN (#{@allowed_sql})"
           )
  end

  def down do
    drop constraint(:games, :games_enrichment_status_must_be_known)
  end
end
