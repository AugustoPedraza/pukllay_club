defmodule PukllayClub.Repo.Migrations.DropUnitsFromGames do
  use Ecto.Migration

  @moduledoc """
  D-02/D-31: `games.units` is dropped. Copy rows (`priv/repo/migrations/
  20260923120000_create_copies.exs`, plan 01.8.2-01) became the source of
  truth for a game's copy count — this migration removes the column they
  replaced, along with every schema field, changeset cast, validation and
  template read that touched it (see plan `01.8.2-05`).

  **Required predecessor:** `20260923120000_create_copies.exs` must have
  already run its backfill (one copy row per existing `games.units`, or
  one when `units` was `NULL`) — `up/0` refuses to run otherwise, so this
  migration cannot silently discard counts against an unbackfilled
  database (T-01.8.2-18).

  Why this deletes a whole bug class rather than patching it (D-31):
  `units` had no DB default, was never cast by `enrichment_changeset/2`,
  and `admin_changeset/2` let a blank through — so every game the D-30
  draft flow creates would otherwise carry `copias = nil` forever. Once
  the column is gone, `count(copies)` is the only possible read path and
  that failure mode cannot recur.

  `down/0` is not lossy: it re-adds `units` as a plain nullable integer
  and repopulates it from `count(copies)` per game, so a rollback
  reproduces the same counts (though not the per-copy identity/position
  `copies` itself carries — see the plan's `<reversibility>` note).
  """

  def up do
    %Postgrex.Result{rows: [[missing]]} =
      repo().query!("""
      SELECT count(*)
      FROM games g
      WHERE NOT EXISTS (SELECT 1 FROM copies c WHERE c.game_id = g.id)
      """)

    if missing > 0 do
      raise """
      Refusing to drop games.units: #{missing} game(s) have zero copy rows.
      Run priv/repo/migrations/20260923120000_create_copies.exs's backfill
      (plan 01.8.2-01) before this migration — dropping the column now
      would silently lose their counts.
      """
    end

    alter table(:games) do
      remove :units
    end
  end

  def down do
    alter table(:games) do
      add :units, :integer
    end

    execute("""
    UPDATE games g
    SET units = counts.copy_count
    FROM (
      SELECT game_id, count(*) AS copy_count
      FROM copies
      GROUP BY game_id
    ) AS counts
    WHERE counts.game_id = g.id
    """)
  end
end
