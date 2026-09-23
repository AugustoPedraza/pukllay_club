defmodule PukllayClub.Repo.Migrations.UnpublishStillEmptyGames do
  use Ecto.Migration

  import Ecto.Query

  require Logger

  @moduledoc """
  D-36: moves every still-genuinely-empty **published** game to `:draft`,
  reversibly, logging before/after counts (D-06's baseline pattern).

  **Re-measured against post-D-35-backfill facts on 2026-09-23** (see the
  01.8.2-04 SUMMARY for the full distribution table) — CONTEXT's
  2026-09-22 shape (`draft 1 · published/bgg_missing 8 ·
  published/enriched 385 · published/no_bgg_id 15 ·
  published/no_bgg_id-expansión 26 = 435`) is **unchanged** by the
  completed D-35 publisher-dedup backfill, because that backfill only
  corrected values inside already-`"enriched"` rows — it never touched
  `enrichment_status`, `bgg_id`, or `is_expansion`, so it cannot move a row
  in or out of this distribution.

  **The row-selection predicate (`still_empty_query/0`) is deliberately
  *not* keyed on `enrichment_status`.** It is keyed on real content —
  `status == "published" AND (description IS NULL OR description = '')
  AND cover_url IS NULL` — because the measurement (re-run 2026-09-23)
  found this predicate selects **exactly the same 49 rows** as
  `enrichment_status IN ('bgg_missing', 'no_bgg_id')`: the 8 `bgg_missing`
  (BGG returned no item; D-36 called these "suspect, not broken", but no
  retry has actually re-run against them since credentials were fixed —
  quick task 260922-veq's own report explicitly left that repair "pending
  a human-authorized production run"), the 15 `no_bgg_id` base games (no
  BGG id at all, structurally broken), and — contrary to D-36's default
  leniency for expansions — **all 26 `no_bgg_id` expansions**, because the
  measurement shows every one of them is exactly as empty (no
  description, no cover, no `weight_band`) as the 15 broken base games.
  D-36 states expansions are excluded from the blanket rule "unless the
  measurement says otherwise" — here it does.

  **Reversibility (D-06):** `up/0` records every affected game id in a
  dedicated audit table (`unpublish_still_empty_games_audit`), created and
  dropped by this same migration, rather than trusting a blanket
  "republish everything currently draft" — that would resurrect a game a
  human genuinely drafted or retired in between `up/0` and a later
  `down/0`. `down/0` restores to `:published` only the ids the audit table
  names, and only while they are still `:draft` (a game moved to
  `:retired` by staff in the interim is left alone).
  """

  @audit_table "unpublish_still_empty_games_audit"

  @doc """
  The row-selection predicate, extracted as a public, schemaless query so
  a test can assert "which rows" in isolation, without running the
  migration. Matches every currently-`:published` game with no real
  content — no description and no cover image — regardless of its
  `enrichment_status` label (see the moduledoc for why the two happen to
  coincide on 2026-09-23's data).
  """
  def still_empty_query do
    from g in "games",
      where: g.status == "published",
      where: is_nil(g.description) or g.description == "",
      where: is_nil(g.cover_url),
      select: g.id
  end

  def up do
    create table(@audit_table, primary_key: false) do
      add :game_id, :bigint, null: false
    end

    # DDL above is queued, not yet executed — `flush/0` forces it to run
    # before the DML below, which needs the table to already exist.
    flush()

    repo = repo()
    affected_ids = repo.all(still_empty_query())
    before_count = length(affected_ids)

    if before_count > 0 do
      rows = Enum.map(affected_ids, &%{game_id: &1})
      {_inserted, _} = repo.insert_all(@audit_table, rows)

      {updated_count, _} =
        repo.update_all(
          from(g in "games", where: g.id in ^affected_ids),
          set: [status: "draft"]
        )

      log_json(%{
        migration: "unpublish_still_empty_games",
        direction: "up",
        before: before_count,
        after: updated_count,
        game_ids: affected_ids
      })
    else
      # D-36: the measured decision and its record are the requirement,
      # not a guaranteed row change — ship as a no-op that still logs.
      log_json(%{
        migration: "unpublish_still_empty_games",
        direction: "up",
        before: 0,
        after: 0,
        game_ids: []
      })
    end
  end

  def down do
    repo = repo()
    ids = repo.all(from(a in @audit_table, select: a.game_id))
    before_count = length(ids)

    {restored_count, _} =
      repo.update_all(
        from(g in "games", where: g.id in ^ids and g.status == "draft"),
        set: [status: "published"]
      )

    log_json(%{
      migration: "unpublish_still_empty_games",
      direction: "down",
      before: before_count,
      after: restored_count,
      game_ids: ids
    })

    drop table(@audit_table)
  end

  defp log_json(payload) do
    Logger.info(Jason.encode!(payload))
  end
end
