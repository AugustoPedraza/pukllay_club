defmodule PukllayClub.Catalog.Game do
  @moduledoc """
  A single club board game row.

  Mirrors `priv/repo/migrations/*_create_games.exs`. `csv_row` is the
  seed-task natural key (see `PukllayClub.Catalog.upsert_game!/1`); `bgg_id`
  is nullable because ~9% of the club's CSV rows carry no BGG id (D-18) and
  `enrichment_status` records why.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @enrichment_statuses ~w(pending enriched no_bgg_id bgg_missing)

  schema "games" do
    field :name, :string
    field :csv_row, :integer
    field :bgg_id, :integer
    field :units, :integer
    field :min_players, :integer
    field :max_players, :integer
    field :min_playtime, :integer
    field :max_playtime, :integer
    field :playing_time, :integer
    field :min_age, :integer
    field :year_published, :integer
    field :weight_band, :string
    field :bgg_weight, :float
    field :tags, {:array, :string}, default: []
    field :mechanics, {:array, :string}, default: []
    field :themes, {:array, :string}, default: []
    field :designers, {:array, :string}, default: []
    field :publishers, {:array, :string}, default: []
    field :description, :string
    field :thumbnail_url, :string
    field :cover_url, :string
    field :gallery_urls, {:array, :string}, default: []
    field :bgg_payload, :map
    field :enrichment_status, :string, default: "pending"
    # Postgres-generated `tsvector` column (01-04 migration) — Ecto never
    # writes it (never cast in `seed_changeset/2`) and never loads it back
    # (`load_in_query: false` excludes it from normal SELECTs). Deliberately
    # *not* `read_after_writes: true`: Postgrex decodes `tsvector` as a list
    # of `Postgrex.Lexeme` structs, which `Ecto.Type.load/2` cannot coerce
    # into `:string` — requesting it via a post-insert `RETURNING` clause
    # raised `cannot load ... as type :string`. Nothing in the app reads
    # this field; it exists purely so Ecto's schema/changeset machinery is
    # aware of the column without ever touching its value.
    field :search_vector, :string, load_in_query: false

    timestamps()
  end

  @doc """
  Changeset used by the seed pipeline (`PukllayClub.Catalog.upsert_game!/1`).
  Casts every column; requires only `:name` and `:csv_row` since most fields
  are legitimately absent for a not-yet-enriched or `BGG_ID`-less row.
  """
  def seed_changeset(game, attrs) do
    game
    |> cast(attrs, [
      :name,
      :csv_row,
      :bgg_id,
      :units,
      :min_players,
      :max_players,
      :min_playtime,
      :max_playtime,
      :playing_time,
      :min_age,
      :year_published,
      :weight_band,
      :bgg_weight,
      :tags,
      :mechanics,
      :themes,
      :designers,
      :publishers,
      :description,
      :thumbnail_url,
      :cover_url,
      :gallery_urls,
      :bgg_payload,
      :enrichment_status
    ])
    |> validate_required([:name, :csv_row])
    |> validate_inclusion(:enrichment_status, @enrichment_statuses)
    |> unique_constraint(:csv_row)
  end
end
