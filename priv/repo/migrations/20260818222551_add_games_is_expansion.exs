defmodule PukllayClub.Repo.Migrations.AddGamesIsExpansion do
  use Ecto.Migration

  @moduledoc """
  Adds `games.is_expansion` and backfills it for every existing row (G-01-5)
  — a real queryable column, rather than matching free text in the game
  name at read time, so the "Recientemente añadidos" carousel row can
  exclude expansions/promos (`Catalog.recent_query/0`).

  The backfill `UPDATE` below is a literal-value SQL mirror of
  `PukllayClub.Catalog.Seed.ExpansionClassifier` — one `name ILIKE
  '%marker%'` predicate per marker in that module's `@markers` attribute,
  OR-ed with `csv_row = ANY(ARRAY[...])` carrying the same 4 reviewed
  overrides. **The two must be changed together.** This migration exists so
  production gets the correct flag from the deploy migration itself,
  without re-running the BGG/R2 seed pipeline (which needs live credentials
  and is documented as a one-time operation, D-02) — Kamal's entrypoint
  runs migrations before the new container becomes healthy, so this
  `UPDATE` executes against live production data on the next deploy.

  No index is added: the only consumer is a `LIMIT 20` carousel query over
  434 rows, and the existing `inserted_at`/`csv_row` ordering already
  dominates its cost — this is a deliberate omission, not an oversight.
  """

  def change do
    alter table(:games) do
      add :is_expansion, :boolean, null: false, default: false
    end

    execute(
      """
      UPDATE games SET is_expansion = true
      WHERE name ILIKE '%(expa%'
         OR name ILIKE '%expansi%'
         OR name ILIKE '%promo%'
         OR csv_row = ANY(ARRAY[414, 415, 417, 421])
      """,
      "UPDATE games SET is_expansion = false"
    )
  end
end
