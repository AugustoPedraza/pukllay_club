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
    field :artists, {:array, :string}, default: []
    field :bgg_rating, :float
    field :bgg_rank, :integer
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
    # Lifecycle status (D-04/D-08, migration `add_status_to_games`) — every
    # public read path in `PukllayClub.Catalog` filters on this; the admin
    # read path (`get_game!/1`) does not. Defaults to `:published` because
    # every pre-existing row (the ~434-game live catalog) predates this
    # column and was already public; the admin add-game flow (plan 06) sets
    # `:draft` explicitly on insert, never relying on this default.
    field :status, Ecto.Enum, values: [:draft, :published, :retired], default: :published
    # Real, queryable expansion/promo flag (G-01-5) — derived at seed time
    # by `PukllayClub.Catalog.Seed.ExpansionClassifier` and backfilled for
    # pre-existing rows by the `add_games_is_expansion` migration. See that
    # module's moduledoc for the marker + reviewed-override rules.
    field :is_expansion, :boolean, default: false
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
      :artists,
      :bgg_rating,
      :bgg_rank,
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
      :enrichment_status,
      :is_expansion
    ])
    |> validate_required([:name, :csv_row])
    |> validate_inclusion(:enrichment_status, @enrichment_statuses)
    |> unique_constraint(:csv_row)
  end

  @doc """
  Changeset for the D-04/D-08 lifecycle transitions
  (`Catalog.publish_game/1`, `Catalog.retire_game/1`, `Catalog.restore_game/1`)
  — casts and validates only `:status`, never any other field.
  """
  def status_changeset(game, attrs) do
    game
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end

# THE single canonical param for this schema (quick task 260913-2x6, see
# `.planning/notes/game-url-slug-format.md`): every `~p"/juegos/#{game}"`
# call site (GameCard/GamePreview detail links, `SEO.canonical_url/1`,
# `SitemapController`, the detail page's share control) picks this up
# automatically via `Phoenix.Param.to_param/1`, and
# `PukllayClubWeb.Plugs.GameSEO`/`CatalogLive.Show.handle_params/3` compare
# a request's raw `id` param against this exact function's output to decide
# whether to redirect/patch — making it the one loop-proof source of truth
# for "is this URL already canonical". Colocated with the `Game` schema
# (rather than a separate file) as the idiomatic place for a schema's
# `Phoenix.Param` impl.
defimpl Phoenix.Param, for: PukllayClub.Catalog.Game do
  alias PukllayClub.Catalog.Slug

  # Mirrors Phoenix's own default `Phoenix.Param` impl for a struct with a
  # nil `:id` — raising here (rather than emitting `"nil-<slug>"` or
  # crashing later inside Ecto) surfaces a genuinely unpersisted/unloaded
  # struct immediately, at the one call site responsible for building a URL
  # from it.
  def to_param(%{id: nil} = game) do
    raise ArgumentError, "cannot build a Phoenix.Param for #{inspect(game.__struct__)} with a nil :id"
  end

  # Empty slug (e.g. a name of "!!!") falls back to the bare id, with no
  # trailing dash — this is also what keeps the redirect/patch check
  # loop-proof: the canonical output is always either "<id>" or
  # "<id>-<[a-z0-9-]+>", never "<id>-".
  def to_param(%{id: id, name: name}) do
    case Slug.slugify(name) do
      "" -> Integer.to_string(id)
      slug -> "#{id}-#{slug}"
    end
  end
end
