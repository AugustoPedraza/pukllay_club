defmodule PukllayClub.Repo.Migrations.AddStatusToGames do
  use Ecto.Migration

  @moduledoc """
  Adds `games.status` (draft / published / retired, D-04/D-08) — the
  lifecycle column every public read path in `PukllayClub.Catalog` must now
  filter on (RESEARCH.md Pitfall 2, `Catalog.sitemap_entries/0`'s own
  moduledoc self-documented this exact gap).

  Mirrors `add_games_is_expansion`'s column-plus-moduledoc shape (Pattern 2):
  `add :status, :string, null: false, default: "published"`. Production
  already holds ~434 live, publicly-visible games (01.7's restore) — the
  COLUMN-LEVEL default is what backfills every one of them to `"published"`
  the instant this migration runs inside Kamal's pre-boot `bin/migrate`, with
  zero rows requiring a data migration/backfill `UPDATE` (unlike
  `is_expansion`, which needed one). Any other default — `"draft"`, no
  default, or a data migration that got the direction wrong — would silently
  empty the entire live catalog on the next deploy (RESEARCH.md Pitfall 1):
  every public query gains `WHERE status = 'published'\'`, and an existing
  row defaulted to anything else instantly fails it.

  The admin add-game path (plan 06, not yet built) sets `status: "draft"`
  explicitly on insert — it must never rely on this column's default, which
  exists solely to make "no explicit status" mean "already-published,
  pre-admin-era row" for the ~434 rows that predate this column entirely.

  A `games_status_must_be_known` check constraint backs the `Ecto.Enum` at
  the database layer (T-01.8.1-11, defense in depth against a raw SQL write
  bypassing the schema's own validation).
  """

  def change do
    alter table(:games) do
      add :status, :string, null: false, default: "published"
    end

    create constraint(:games, :games_status_must_be_known,
             check: "status IN ('draft', 'published', 'retired')"
           )
  end
end
