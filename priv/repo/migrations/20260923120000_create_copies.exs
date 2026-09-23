defmodule PukllayClub.Repo.Migrations.CreateCopies do
  use Ecto.Migration

  @moduledoc """
  `copies` (D-01, D-02, D-03, D-05, 01.8.2-01 — the phase tracer): every
  physical copy of a game gets its own row, replacing `games.units` as a
  bare count with real rows a copy-level write path (place/move) can act
  on.

  D-01: a copy carries its own `shelf_id` + `position` (an estante and a
  left-to-right slot in it) — place/move act on a copy, never on a game,
  reversing 01.8.1 D-11's "at most one shelf per game, no in-shelf
  position".
  D-02: copy rows become the source of truth for a game's copy count.
  `games.units` is NOT dropped by this migration — 01.8.2-05 owns D-31's
  drop, once every write path reads copy rows instead.
  D-03: `number` is the stable "copia N de M" identity — assigned once at
  backfill (or on creation) and never renumbered by a later place or
  move.
  D-05: this migration's own backfill leaves every copy unplaced
  (`shelf_id`/`position` both NULL, "Sin ubicar") regardless of whether
  the owning game already had a `games.shelf_id` under the old game-level
  model — the estante/position rebuild ("clear everything") is a
  deliberately separate, later, explicitly-destructive migration, not
  something this additive migration does as a side effect.

  What the database enforces vs. what application code must enforce: the
  two unique indexes below are hard invariants Postgres will never let a
  bad write violate — no two copies of one game share a `number`
  (`copies_game_id_number_index`), and no two copies on one estante share
  a `position` (`copies_shelf_position_unique`, partial on `shelf_id IS
  NOT NULL` so any number of unplaced copies can all carry `position:
  nil` at once). What the database CANNOT enforce is gap-freeness (that
  the positions on one estante are exactly `0..n-1` with no hole) — that
  is `Shelves.place_copy/3`'s job, under a per-estante advisory lock (see
  `lib/pukllay_club/catalog/shelves.ex`).

  `on_delete` differs per FK because the two relationships mean different
  things: a copy cannot outlive its game (`on_delete: :delete_all` on
  `game_id` — deleting the game deletes every copy of it), but a copy
  very much outlives its estante (`on_delete: :nilify_all` on `shelf_id`
  — deleting an estante just unplaces its copies, mirroring the
  "never delete data by deleting a location" rule `create_shelves`
  already established for `games.shelf_id`).

  `backfill_statements/0` is public so
  `test/pukllay_club/catalog/copies_test.exs` can replay the exact same
  SQL against fixture data without re-running this migration.
  """

  def change do
    create table(:copies) do
      add :game_id, references(:games, on_delete: :delete_all), null: false
      add :shelf_id, references(:shelves, on_delete: :nilify_all)
      add :position, :integer
      add :number, :integer, null: false

      timestamps()
    end

    create unique_index(:copies, [:game_id, :number])

    create unique_index(:copies, [:shelf_id, :position],
             where: "shelf_id IS NOT NULL",
             name: :copies_shelf_position_unique
           )

    create index(:copies, [:shelf_id])
    create index(:copies, [:game_id])

    [backfill_sql] = backfill_statements()

    execute(backfill_sql, "DELETE FROM copies")
  end

  @doc """
  The up-direction SQL statement(s) this migration's backfill runs, in
  order — public so `copies_test.exs` can replay them verbatim against
  fixture data (D-01/D-02/D-03/D-05 verification). One copy row per
  existing unit, numbered `1..units` (or just `1` when `units` is NULL —
  a game with no unit count backfills to exactly one copy). Every
  backfilled copy starts unplaced (`shelf_id`/`position` both NULL)
  regardless of the owning game's current `games.shelf_id` — see the
  moduledoc's D-05 paragraph.
  """
  def backfill_statements do
    [
      """
      INSERT INTO copies (game_id, number, inserted_at, updated_at)
      SELECT g.id, gs.n, now(), now()
      FROM games AS g
      CROSS JOIN LATERAL generate_series(1, COALESCE(g.units, 1)) AS gs(n)
      """
    ]
  end
end
