defmodule PukllayClub.Catalog do
  @moduledoc """
  The Catalog context — the only module `CatalogLive.Index` (and the seed
  pipeline) reads/writes `PukllayClub.Catalog.Game` rows through. Later
  plans extend `list_games/1` with filtering, sorting, and search; this
  tracer only needs the shape.
  """

  import Ecto.Query

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Repo

  @default_limit 24

  @doc """
  Lists games ordered by name. Accepts `:limit` (default #{@default_limit}).
  """
  def list_games(opts \\ []) do
    limit = Keyword.get(opts, :limit, @default_limit)

    Game
    |> order_by([g], asc: g.name)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Inserts or updates a game row, upserting on the `:csv_row` unique index
  (the seed task's natural key — see the migration/schema for why this is
  `csv_row` and not `bgg_id`, D-02/D-19).
  """
  def upsert_game!(attrs) do
    %Game{}
    |> Game.seed_changeset(attrs)
    |> Repo.insert!(
      # `:search_vector` (01-04) is a Postgres GENERATED ALWAYS column —
      # it can only ever be set to DEFAULT, so it must be excluded here too,
      # not just `:id`/`:inserted_at`, or a re-run's `ON CONFLICT DO UPDATE`
      # tries `SET search_vector = EXCLUDED.search_vector` and Postgres
      # raises `(generated_always) column "search_vector" can only be
      # updated to DEFAULT`.
      on_conflict: {:replace_all_except, [:id, :inserted_at, :search_vector]},
      conflict_target: :csv_row
    )
  end
end
