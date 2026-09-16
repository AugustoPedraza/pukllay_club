defmodule PukllayClub.Repo.Migrations.AllowAdminAddedGames do
  use Ecto.Migration

  @moduledoc """
  Makes `games.csv_row` nullable (D-09, 01.8.1-06). The ~434 games imported
  by the now-retired CSV seed pipeline keep their historical `csv_row`
  value; a game added by staff through `Catalog.add_game_from_bgg/1` has
  none. The unique index on `csv_row` is left in place — Postgres treats
  every `NULL` as distinct from every other `NULL`, so any number of
  admin-added games can coexist with a `NULL` `csv_row` without violating
  uniqueness.
  """

  def change do
    alter table(:games) do
      modify :csv_row, :integer, null: true
    end
  end
end
