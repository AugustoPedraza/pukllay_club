defmodule PukllayClub.Catalog do
  @moduledoc """
  The Catalog context — the only module `CatalogLive.Index` (and the seed
  pipeline) reads/writes `PukllayClub.Catalog.Game` rows through.

  `filter_games/1` is the single composed query serving CATALOG-02
  (filter), CATALOG-03 (search), and CATALOG-04 (sort) together, per
  01-RESEARCH.md Pattern 3 — one pipeline of `maybe_*` predicates, never a
  branch between "search mode" and "filter mode". Every user-supplied value
  reaches Postgres as a pinned `^` parameter inside `fragment/2`; no query
  text is ever built by string interpolation (T-01-20).
  """

  import Ecto.Query

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClub.Repo

  @default_limit 24
  @carousel_limit 20
  @allowed_sorts [
    :name_asc,
    :playtime_asc,
    :playtime_desc,
    :complexity_asc,
    :complexity_desc,
    :year_desc
  ]
  @weight_band_order ["descubre_el_hobby", "ingenio_estratega", "nivel_experto"]

  @doc """
  Lists games ordered by name. Accepts `:limit` (default #{@default_limit}).

  Superseded by `filter_games/1` for the browse page (01-05); kept as the
  simplest possible read path for any future caller that just wants "the
  first N games alphabetically" with no filtering.
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

  @doc """
  The one composed query serving filtering, faceting, searching, sorting,
  and pagination together (CATALOG-02/03/04, D-14/D-15).

  Accepts a map or keyword list with `:q`, `:mechanics` (Spanish labels),
  `:themes` (Spanish labels), `:weight_bands`, `:tags`, `:players`,
  `:max_playtime`, `:min_age`, `:sort`, `:limit` (default
  #{@default_limit}), `:offset` (default 0). Always applies `LIMIT` —
  never returns an unbounded result set (T-01-22).
  """
  def filter_games(opts \\ []) do
    opts = normalize_opts(opts)

    Game
    |> base_filtered_query(opts)
    |> apply_sort(normalize_sort(Map.get(opts, :sort)))
    |> limit(^(Map.get(opts, :limit) || @default_limit))
    |> offset(^(Map.get(opts, :offset) || 0))
    |> Repo.all()
  end

  @doc """
  Total count of games matching the same predicate pipeline as
  `filter_games/1`, ignoring `:limit`/`:offset`/`:sort` — drives the
  "N juegos encontrados" copy and the empty-state branch.
  """
  def count_games(opts \\ []) do
    opts = normalize_opts(opts)

    Game
    |> base_filtered_query(opts)
    |> Repo.aggregate(:count)
  end

  @doc """
  Fetches a single game by id, raising `Ecto.NoResultsError` for an unknown
  id. `Ecto.NoResultsError` implements `Plug.Exception` with a 404 status,
  so `CatalogLive.Show` renders the generated 404 page rather than a crash
  or a 500 (T-01-30).
  """
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Pill options for the filter drawer: mechanic/theme Spanish labels, weight
  bands, and editorial tags — every value the vocabulary exposes as a
  filterable facet.
  """
  def facet_options do
    %{
      mechanics: Vocabulary.mechanic_options(),
      themes: Vocabulary.theme_options(),
      weight_bands: Vocabulary.weight_bands(),
      editorial_tags: Vocabulary.editorial_tags()
    }
  end

  @doc """
  The fixed, hardcoded D-09 carousel rows, in order: `Destacados del club`
  (any editorial hashtag, capped at #{@carousel_limit}), one row per
  editorial hashtag, one row per weight band, then `Recientemente
  añadidos`. Each row is `%{key:, title:, games:}`.

  **Recorded limitation:** the club export has no acquisition date, so
  after a single bulk seed `Recientemente añadidos` is effectively
  reverse-CSV order (`inserted_at` desc, `csv_row` desc tie-break) — a real
  acquisition date is Phase 4 admin territory (D-10).

  **G-01-5:** that same reverse-CSV ordering is exactly why this row used
  to surface almost exclusively expansions/promos — the club's source
  export happens to cluster every expansion/promo entry as one contiguous
  block at the tail of the sheet. `recent_query/0` now filters on
  `is_expansion == false`; see `PukllayClub.Catalog.Seed.ExpansionClassifier`
  for how that flag is derived. The `is_expansion` column now exists on
  every game and could be filtered elsewhere too, but Phase 1 deliberately
  scopes the exclusion to this one carousel row — `filter_games/1`,
  `count_games/1`, and every other carousel row are untouched, so an
  expansion the club physically owns remains searchable and present in the
  main grid.

  The row set is intentionally hardcoded — no configuration table, no
  admin form, no dynamic registry. D-10 defers that to Phase 4.
  """
  def list_carousel_rows do
    editorial_tag_values = Enum.map(Vocabulary.editorial_tags(), & &1.tag)

    [
      carousel_row(:destacados_del_club, "Destacados del club", tags_query(editorial_tag_values)),
      carousel_row(:crea_conexiones, "Crea conexiones", tags_query(["#CreaConexiones"])),
      carousel_row(:equipo_ganador, "Equipo ganador", tags_query(["#EquipoGanador"])),
      carousel_row(:duelos_memorables, "Duelos memorables", tags_query(["#DuelosMemorables"])),
      carousel_row(
        :descubre_el_hobby,
        "Descubre el hobby",
        weight_band_query("descubre_el_hobby")
      ),
      carousel_row(
        :ingenio_estratega,
        "Ingenio estratega",
        weight_band_query("ingenio_estratega")
      ),
      carousel_row(:nivel_experto, "Nivel experto", weight_band_query("nivel_experto")),
      carousel_row(:recientemente_anadidos, "Recientemente añadidos", recent_query())
    ]
  end

  defp carousel_row(key, title, query) do
    %{key: key, title: title, games: Repo.all(query)}
  end

  defp tags_query(tags) do
    from g in Game,
      where: fragment("? && ?", g.tags, type(^tags, {:array, :string})),
      order_by: [asc: g.name],
      limit: ^@carousel_limit
  end

  defp weight_band_query(band) do
    from g in Game,
      where: g.weight_band == ^band,
      order_by: [asc: g.name],
      limit: ^@carousel_limit
  end

  defp recent_query do
    from g in Game,
      order_by: [desc: g.inserted_at, desc: g.csv_row],
      limit: ^@carousel_limit
  end

  defp normalize_opts(opts), do: Map.new(opts)

  defp base_filtered_query(query, opts) do
    query
    |> maybe_search(Map.get(opts, :q))
    |> maybe_filter_mechanics(Map.get(opts, :mechanics))
    |> maybe_filter_themes(Map.get(opts, :themes))
    |> maybe_filter_weight_bands(Map.get(opts, :weight_bands))
    |> maybe_filter_tags(Map.get(opts, :tags))
    |> maybe_filter_players(Map.get(opts, :players))
    |> maybe_filter_playtime(Map.get(opts, :max_playtime))
    |> maybe_filter_age(Map.get(opts, :min_age))
  end

  defp maybe_search(query, q) when q in [nil, ""], do: query

  defp maybe_search(query, term) do
    from g in query,
      where: fragment("? @@ websearch_to_tsquery('spanish_unaccent', ?)", g.search_vector, ^term)
  end

  defp maybe_filter_mechanics(query, labels) when labels in [nil, []], do: query

  defp maybe_filter_mechanics(query, labels) do
    raw_values = Enum.flat_map(labels, &Vocabulary.mechanic_terms_for/1)

    from g in query, where: fragment("? && ?", g.mechanics, type(^raw_values, {:array, :string}))
  end

  defp maybe_filter_themes(query, labels) when labels in [nil, []], do: query

  defp maybe_filter_themes(query, labels) do
    raw_values = Enum.flat_map(labels, &Vocabulary.theme_terms_for/1)

    from g in query, where: fragment("? && ?", g.themes, type(^raw_values, {:array, :string}))
  end

  defp maybe_filter_weight_bands(query, bands) when bands in [nil, []], do: query

  defp maybe_filter_weight_bands(query, bands) do
    from g in query, where: g.weight_band in ^bands
  end

  defp maybe_filter_tags(query, tags) when tags in [nil, []], do: query

  defp maybe_filter_tags(query, tags) do
    from g in query, where: fragment("? && ?", g.tags, type(^tags, {:array, :string}))
  end

  defp maybe_filter_players(query, nil), do: query

  defp maybe_filter_players(query, n) do
    from g in query, where: g.min_players <= ^n and g.max_players >= ^n
  end

  defp maybe_filter_playtime(query, nil), do: query

  defp maybe_filter_playtime(query, n) do
    from g in query,
      where: fragment("coalesce(?, ?) <= ?", g.playing_time, g.max_playtime, ^n)
  end

  defp maybe_filter_age(query, nil), do: query

  defp maybe_filter_age(query, n) do
    from g in query, where: g.min_age <= ^n
  end

  defp normalize_sort(sort) when sort in @allowed_sorts, do: sort
  defp normalize_sort("name_asc"), do: :name_asc
  defp normalize_sort("playtime_asc"), do: :playtime_asc
  defp normalize_sort("playtime_desc"), do: :playtime_desc
  defp normalize_sort("complexity_asc"), do: :complexity_asc
  defp normalize_sort("complexity_desc"), do: :complexity_desc
  defp normalize_sort("year_desc"), do: :year_desc
  defp normalize_sort(_unrecognized), do: :name_asc

  defp apply_sort(query, :playtime_asc) do
    from g in query,
      order_by: [asc_nulls_last: fragment("coalesce(?, ?)", g.playing_time, g.max_playtime)]
  end

  defp apply_sort(query, :playtime_desc) do
    from g in query,
      order_by: [desc_nulls_last: fragment("coalesce(?, ?)", g.playing_time, g.max_playtime)]
  end

  defp apply_sort(query, :complexity_asc) do
    from g in query,
      order_by: [
        asc_nulls_last:
          fragment(
            "array_position(?, ?)",
            type(^@weight_band_order, {:array, :string}),
            g.weight_band
          ),
        asc_nulls_last: g.bgg_weight
      ]
  end

  defp apply_sort(query, :complexity_desc) do
    from g in query,
      order_by: [
        desc_nulls_last:
          fragment(
            "array_position(?, ?)",
            type(^@weight_band_order, {:array, :string}),
            g.weight_band
          ),
        desc_nulls_last: g.bgg_weight
      ]
  end

  defp apply_sort(query, :year_desc) do
    from g in query, order_by: [desc_nulls_last: g.year_published]
  end

  defp apply_sort(query, :name_asc) do
    from g in query, order_by: [asc: g.name]
  end
end
