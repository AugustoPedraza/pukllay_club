defmodule PukllayClub.Repo.Migrations.ClearEstantesAndAssignments do
  use Ecto.Migration

  require Logger

  alias PukllayClub.Repo

  @moduledoc """
  D-05/D-06/D-07 (01.8.2-06) — the clear-slate migration. When real
  per-copy left-to-right position lands (D-01, `create_copies`,
  01.8.2-01), there is nothing worth preserving from the old
  name-assigned, game-level shelf model: placement-at-a-chosen-spot
  records the real physical order as a side effect (D-00c). This
  migration deletes every `shelves` row, nilifies every legacy
  `games.shelf_id`, and nilifies every `copies.shelf_id`/`position` — so
  every copy starts in `Sin ubicar` and staff recreate the room with
  **Nuevo estante**, walking each shelf left to right (D-08/D-09).

  **D-05 forbids two specific things, and this migration does neither:**
  no reconstruction of a physical layout from the alphabetical order of
  names, and no synthetic "not yet reviewed" placement state invented to
  soften the gap. Nothing in this file consults name order or any other
  ordering to decide where a copy goes — every copy simply becomes
  unplaced.

  **D-06:** `up/0` reads the pre-clear counts first — `shelves`,
  `games.shelf_id IS NOT NULL`, `copies.shelf_id IS NOT NULL` — then
  emits them as one `Logger.info` JSON line
  (`estantes_removed`/`assignments_removed`/`copies_unplaced`/`at`)
  before making any change. That line is the only record of how much
  shelf data existed at the moment it was destroyed, and the rollout
  runbook (`docs/runbooks/01.8.2-admin-redesign-rollout.md`) checks it
  against a pre-deploy `pg_dump`'s own baseline counts.

  **D-07:** this migration ships in the same deploy as the rebuilt
  Estantes page (`EstanteLive.Index`, plan 01.8.2-01) and Administrar
  estantes (plan 01.8.2-18) — production must never have cleared shelves
  without the screen to rebuild them.

  **This migration is deliberately one-way — `down/0` raises.** Contrast
  the reversible `20260923122000_unpublish_still_empty_games.exs`, which
  restores from an audit table it keeps: that migration is reversible
  because the rows it moves still exist, unchanged, in `games`. This one
  deletes `shelves` outright and nilifies every assignment with no audit
  table at all — there is nothing left, anywhere in this database, that
  `down/0` could read to reconstruct the room. An honest raise, naming
  the pre-deploy `pg_dump` as the only recovery path, is safer than a
  `down/0` that quietly does nothing and lets an operator believe a
  rollback restored the shelf map.

  **Deliberately calls `PukllayClub.Repo` directly, not the `repo()`
  migration-DSL helper.** `Ecto.Migration.Runner.repo/0` reads an `Agent`
  process the migration Runner starts — it only resolves inside an
  active `Ecto.Migrator` run. This migration's test
  (`test/pukllay_club/repo/clear_estantes_migration_test.exs`, the first
  migration-behaviour test in this repo) invokes `up/0` and `down/0`
  directly, with no Runner in the process, so they are written against
  the app's own `Repo` module — which behaves identically whether called
  by `mix ecto.migrate` or by a direct call inside a Sandbox test. This
  is safe specifically because the migration does no DDL (no
  `alter table`, no `create table`): those DSL macros genuinely require
  the Runner's queued-command machinery; plain reads and writes do not.
  Later data-only migrations that want the same direct-call testability
  should follow this shape rather than `repo()`.
  """

  def up do
    %Postgrex.Result{rows: [[estantes_removed]]} =
      Repo.query!("SELECT count(*) FROM shelves")

    %Postgrex.Result{rows: [[assignments_removed]]} =
      Repo.query!("SELECT count(*) FROM games WHERE shelf_id IS NOT NULL")

    %Postgrex.Result{rows: [[copies_unplaced]]} =
      Repo.query!("SELECT count(*) FROM copies WHERE shelf_id IS NOT NULL")

    log_json(%{
      estantes_removed: estantes_removed,
      assignments_removed: assignments_removed,
      copies_unplaced: copies_unplaced,
      at: DateTime.to_iso8601(DateTime.utc_now())
    })

    Repo.query!("UPDATE copies SET shelf_id = NULL, position = NULL")
    Repo.query!("UPDATE games SET shelf_id = NULL")
    Repo.query!("DELETE FROM shelves")

    :ok
  end

  def down do
    raise Ecto.MigrationError,
      message: """
      D-05's clear-slate is irreversible by design: it deletes every
      `shelves` row and nilifies every shelf assignment with no audit
      table, because nothing survives anywhere in this database that
      could reconstruct the room layout afterwards. Recovery is only
      from the pre-deploy `pg_dump` recorded in
      `docs/runbooks/01.8.2-admin-redesign-rollout.md` — restore that
      dump; there is no code-level rollback for this migration.
      """
  end

  defp log_json(payload) do
    Logger.info(Jason.encode!(payload))
  end
end
