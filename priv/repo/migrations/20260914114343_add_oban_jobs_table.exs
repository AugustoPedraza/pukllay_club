defmodule PukllayClub.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  @moduledoc """
  Creates the `oban_jobs` table (D-01, 01.8.1-06) via Oban's own versioned
  migrator. Pinned to version 14 — the current version of the installed
  `oban` dep (`deps/oban/lib/oban/migrations/postgres.ex`) at the time this
  migration was written — never left unversioned, so a future `oban` bump
  requires an explicit follow-up migration rather than silently changing
  what this file does.
  """

  def up, do: Oban.Migration.up(version: 14)

  def down, do: Oban.Migration.down(version: 1)
end
