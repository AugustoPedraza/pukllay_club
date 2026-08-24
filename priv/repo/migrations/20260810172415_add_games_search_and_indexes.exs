defmodule PukllayClub.Repo.Migrations.AddGamesSearchAndIndexes do
  use Ecto.Migration

  @moduledoc """
  Plan 01-04 post-seed migration (01-RESEARCH.md Pattern 1): GIN indexes and
  the accent-folding Spanish `search_vector` generated column, added AFTER
  the bulk 434-row seed load rather than before it, so the ~400-row insert
  never pays per-row GIN index maintenance.

  `unaccent()` is STABLE, not IMMUTABLE, so it cannot be called directly
  inside a generated column expression — Postgres rejects that. Layering it
  into a named text search configuration (`spanish_unaccent`) instead keeps
  `to_tsvector(regconfig, text)` immutable while still folding accents
  (01-RESEARCH.md Pitfall 4, CATALOG-03).

  **Empirically found while applying this migration (not in the original
  research/plan, which only flagged the `unaccent()` half of this problem):
  `array_to_string(anyarray, text)` is *also* STABLE, not IMMUTABLE**
  (`select provolatile from pg_proc where proname = 'array_to_string'` → `s`
  on Postgres 16/17) — it's marked conservatively for the generic `anyarray`
  signature even though it's fully deterministic for `text[]`. Postgres
  rejects `to_tsvector('spanish_unaccent', ... || array_to_string(designers,
  ' ') || ...)` with "generation expression is not immutable" for this
  reason alone, independent of the regconfig question. The fix is a tiny
  `IMMUTABLE` PL/pgSQL wrapper (`games_array_to_string/2`) — PL/pgSQL,
  not SQL, because a single-statement SQL-language wrapper gets *inlined*
  by the planner before the mutability check runs, which re-exposes the
  STABLE call and defeats the wrapper; PL/pgSQL functions are never
  inlined, so the declared `IMMUTABLE` label is trusted as written. This is
  a standard, precedented workaround for this exact Postgres limitation —
  verified directly against this project's dev database, both with and
  without the wrapper, before writing this migration.

  Every raw DDL step uses `execute/2` (explicit up + down SQL) rather than
  `execute/1`, so `mix ecto.rollback` is a real, tested down path — Ecto
  runs each step's down command in reverse order automatically within a
  single `change/0`.
  """

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS unaccent", "DROP EXTENSION IF EXISTS unaccent")

    execute(
      "CREATE TEXT SEARCH CONFIGURATION spanish_unaccent (COPY = spanish)",
      "DROP TEXT SEARCH CONFIGURATION IF EXISTS spanish_unaccent"
    )

    execute(
      "ALTER TEXT SEARCH CONFIGURATION spanish_unaccent ALTER MAPPING FOR hword, hword_part, word WITH unaccent, spanish_stem",
      "ALTER TEXT SEARCH CONFIGURATION spanish_unaccent ALTER MAPPING FOR hword, hword_part, word WITH spanish_stem"
    )

    execute(
      """
      CREATE FUNCTION games_array_to_string(text[], text) RETURNS text AS $$
      BEGIN
        RETURN array_to_string($1, $2);
      END;
      $$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
      """,
      "DROP FUNCTION IF EXISTS games_array_to_string(text[], text)"
    )

    execute(
      """
      ALTER TABLE games ADD COLUMN search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector(
          'spanish_unaccent'::regconfig,
          coalesce(name, '') || ' ' ||
          coalesce(games_array_to_string(designers, ' '), '') || ' ' ||
          coalesce(games_array_to_string(publishers, ' '), '')
        )
      ) STORED
      """,
      "ALTER TABLE games DROP COLUMN search_vector"
    )

    create index(:games, [:search_vector], using: :gin)
    create index(:games, [:mechanics], using: :gin)
    create index(:games, [:themes], using: :gin)
    create index(:games, [:tags], using: :gin)

    create index(:games, [:weight_band])
    create index(:games, [:min_players])
    create index(:games, [:max_players])
    create index(:games, [:playing_time])
    create index(:games, [:min_age])
  end
end
