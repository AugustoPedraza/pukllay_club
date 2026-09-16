defmodule PukllayClub.Repo.Migrations.AddBandReviewToGames do
  use Ecto.Migration

  @moduledoc """
  `games.band_reviewed_band` + `games.band_reviewed_at` (D-30, 01.8.1-13):
  the "keep" override snapshot for the band audit
  (`PukllayClub.Catalog.BandAudit`). Both are nullable — a game that has
  never been kept has neither.

  Deliberately a snapshot of the *implied* band at review time, not a bare
  boolean `band_reviewed: true` flag (RESEARCH.md A4). A boolean would
  satisfy D-30's "hides the game from the audit" half forever, even after
  the game's `bgg_weight` later changes to imply a different band — which
  would silently hide a real, new mismatch. Storing the implied band at
  review time instead lets `BandAudit.mismatches/0` compare it against the
  *current* implied band on every read: unchanged since review, still
  hidden; drifted to a different implied band, re-surfaced. The timestamp
  is recorded for staff visibility only (T-01.8.1-62, accepted: no
  per-user attribution needed at ≤4 staff).
  """

  def change do
    alter table(:games) do
      add :band_reviewed_band, :string
      add :band_reviewed_at, :utc_datetime
    end
  end
end
