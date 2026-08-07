defmodule PukllayClub.Repo.Migrations.CreateGames do
  use Ecto.Migration

  @moduledoc """
  Plan 01-03 tracer: the full `games` table shape for the phase (per
  01-RESEARCH.md Pattern 1, GIN indexes and the `search_vector` generated
  column land in 01-04's post-seed migration, not here).

  `csv_row` — not `bgg_id` — is the unique-index conflict target: it makes
  the one-time seed task re-runnable (D-02) and deliberately preserves both
  CSV rows that share `BGG_ID` 163412 instead of deduping (D-19). `bgg_id`
  is nullable (41/434 rows have none, D-18) and only plainly indexed.
  """

  def change do
    create table(:games) do
      add :name, :string, null: false
      add :csv_row, :integer, null: false
      add :bgg_id, :integer
      add :units, :integer
      add :min_players, :integer
      add :max_players, :integer
      add :min_playtime, :integer
      add :max_playtime, :integer
      add :playing_time, :integer
      add :min_age, :integer
      add :year_published, :integer
      add :weight_band, :string
      add :bgg_weight, :float
      add :tags, {:array, :string}, default: []
      add :mechanics, {:array, :string}, default: []
      add :themes, {:array, :string}, default: []
      add :designers, {:array, :string}, default: []
      add :publishers, {:array, :string}, default: []
      add :description, :text
      add :thumbnail_url, :string
      add :cover_url, :string
      add :gallery_urls, {:array, :string}, default: []
      add :bgg_payload, :map
      add :enrichment_status, :string, null: false, default: "pending"

      timestamps()
    end

    create unique_index(:games, [:csv_row])
    create index(:games, [:bgg_id])
  end
end
