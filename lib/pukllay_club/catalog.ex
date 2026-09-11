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
  # @carousel_limit is the initial per-row page size on first paint —
  # unchanged by quick task 260824-u5d, so first-paint query cost stays
  # identical to before in-row infinite scroll existed.
  # @carousel_page_size is the per-increment page size for subsequent
  # in-row "load more" fetches. @carousel_infinite_scroll_max is a
  # deliberate browse-depth ceiling (CONTEXT.md "Row size ceiling",
  # revision note: locked at 30 games/row), not a technical/perf limit —
  # tunable later without reopening that decision. Given the locked 30 and
  # the unchanged initial 20, only one 10-game increment can ever land per
  # row (see the plan's <sizing_note> for the arithmetic); 10 is not a
  # typo for 20.
  @carousel_limit 20
  @carousel_page_size 10
  @carousel_infinite_scroll_max 30
  @similares_limit 12
  @allowed_sorts [
    :name_asc,
    :playtime_asc,
    :playtime_desc,
    :complexity_asc,
    :complexity_desc,
    :year_desc
  ]
  @weight_band_order ["descubre_el_hobby", "ingenio_estratega", "nivel_experto"]

  # quick-260824-eqc: the Jugadores chip cluster's top chip is labelled
  # "6+" and means "seats at least this many players", not "seats exactly
  # this many". Below this threshold a `:players` request is a literal
  # seat-count fit (min_players <= n <= max_players); at or above it there
  # is no upper bound, so a party game requiring 7-8 players is a valid
  # answer to "we are six or more" while an exact-fit predicate would
  # silently hide it.
  @players_open_bucket 6

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
  `:themes` (Spanish labels), `:weight_bands`, `:tags`, `:designers`,
  `:artists`, `:players`, `:max_playtime`, `:min_age`, `:sort`, `:limit`
  (default #{@default_limit}), `:offset` (default 0). Always applies
  `LIMIT` — never returns an unbounded result set (T-01-22).

  `:designers`/`:artists` are exact whole-name array-membership matches
  (not substring, not fuzzy) — a member arriving from a creator pill
  expects that game's exact collaborator set, not a fuzzy neighborhood of
  it.

  `:players` is an exact seat-count fit (`min_players <= n <= max_players`)
  below #{@players_open_bucket}; at or above #{@players_open_bucket} it is
  open-ended (`max_players >= n`, no upper bound) — the "6+" bucket, quick
  task 260824-eqc.
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

  A non-numeric id (e.g. `"abc"`) cannot be cast to the `:id` primary key
  type — `Repo.get!/2` would otherwise raise `Ecto.Query.CastError`, which
  does *not* implement `Plug.Exception` and would 500 instead of rendering
  the branded 404. Parsing the id first and raising `Ecto.NoResultsError`
  for anything that doesn't fully parse as an integer keeps the single
  404 contract intact for every kind of bad id, not just the
  numeric-but-nonexistent one.
  """
  def get_game!(id) when is_binary(id) do
    case Integer.parse(id) do
      {int_id, ""} -> Repo.get!(Game, int_id)
      _ -> raise Ecto.NoResultsError, queryable: Game
    end
  end

  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Games "similar" to `game` for the detail page's Juegos similares shelf.

  **G-01.2-7 / sketch 031 (Always-Full Guarantee) supersedes D-06's original
  hard band filter.** Weight band is now a *ranking preference*, not a
  filter: candidates from `game`'s own band always sort first (in D-06's
  exact intra-band order, unchanged — see below), then candidates from
  progressively more distant bands top up the shelf until the cap is
  reached. The old contract — a thin band returns fewer than
  #{@similares_limit} results, and a `weight_band: nil` game returns `[]` —
  is gone. The new contract: the shelf fills to #{@similares_limit} whenever
  the catalog holds that many other games, for every game, band or no band.

  Band-mates are ranked among themselves exactly as D-06 shipped: by shared
  mechanics/themes overlap (mechanics weighted 2, themes 1 — mechanics
  describe how a game actually plays, themes are flavour), ties broken by
  `name` then `id`. The overlap fragment below is byte-identical to the one
  D-06 shipped; only the `where`/`order_by` band handling around it changed.
  Out-of-band top-up candidates are ordered by band distance first (nearest
  band before farther band), then by that same overlap score, so a
  zero-overlap adjacent-band game can still outrank a high-overlap far-band
  game — closeness of complexity band matters more than a raw mechanic/theme
  match once outside the viewed game's own band.

  The band-preference list is built in Elixir from
  `Vocabulary.weight_band_level/1`'s 1..3 ordinal (three bands, negligible
  cost) rather than hardcoding a second ordinal in SQL — this guarantees the
  ranking can never disagree with `Vocabulary.weight_bands/0`'s declared
  order. For a banded game, bands are ordered by ascending distance from
  `game`'s own band level, ties (there are at most two, since only 3 bands
  exist) broken by ascending level, so `game`'s own band always lands first
  with distance 0. For a `nil`-band game there is no anchor to measure
  distance from, so `Vocabulary.weight_bands/0`'s declared order is used
  unchanged and overlap alone ranks within/across bands. The list is bound
  as a single `^` array parameter into `array_position/2` — never
  interpolated into the fragment string (T-01.2-14-01) — and
  `coalesce(..., 99)` pushes a candidate with its own `nil` band to the very
  end, after every real band.

  Still one query, one `Repo.all/1`, one `limit: ^#{@similares_limit}` —
  T-01-22's LIMIT-always/no-unbounded-fetch discipline is unchanged; the
  overlap score is computed in Postgres, never fetched into Elixir and
  sorted in memory.

  Anything semantic beyond mechanics/themes overlap (embeddings,
  natural-language matching) belongs to Phase 2's hybrid search
  (SEARCH-01..04), not here.
  """
  def similar_games(%Game{id: id, weight_band: weight_band, mechanics: mechanics, themes: themes}) do
    band_order = band_preference_order(weight_band)

    Repo.all(
      from(g in Game,
        where: g.id != ^id,
        order_by: [
          asc:
            fragment(
              "coalesce(array_position(?, ?), 99)",
              type(^band_order, {:array, :string}),
              g.weight_band
            ),
          desc:
            fragment(
              """
              (2 * cardinality(array(select unnest(?) intersect select unnest(?)))) +
              cardinality(array(select unnest(?) intersect select unnest(?)))
              """,
              g.mechanics,
              type(^mechanics, {:array, :string}),
              g.themes,
              type(^themes, {:array, :string})
            ),
          asc: g.name,
          asc: g.id
        ],
        limit: ^@similares_limit
      )
    )
  end

  # G-01.2-7: nearest-band-first ordering, derived from
  # Vocabulary.weight_band_level/1's 1..3 ordinal so it can never disagree
  # with Vocabulary.weight_bands/0's declared order. `nil` (no anchor to
  # measure distance from) falls back to the vocabulary's own declared
  # order — overlap alone ranks in that case.
  defp band_preference_order(nil) do
    Enum.map(Vocabulary.weight_bands(), & &1.value)
  end

  defp band_preference_order(weight_band) do
    viewed_level = Vocabulary.weight_band_level(weight_band)

    Vocabulary.weight_bands()
    |> Enum.map(& &1.value)
    |> Enum.sort_by(fn band ->
      level = Vocabulary.weight_band_level(band)
      {abs(level - viewed_level), level}
    end)
  end

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
  (any editorial hashtag, initial page capped at #{@carousel_limit}), one
  row per editorial hashtag, one row per weight band, then `Recientemente
  añadidos`. Each row is `%{key:, title:, games:, offset:, exhausted?:}` —
  `offset`/`exhausted?` seed the in-row infinite-scroll pagination
  (`carousel_page/3`) a connected `CatalogLive.Index` mount turns into
  per-row streams; `games` is kept on this map (rather than dropped) so
  existing callers of this function still get a plain list back.

  Both this function and `carousel_page/3` route through the same
  `row_query/1` dispatch (via `carousel_row_specs/0`) so page 1 and every
  later page are always built from the identical predicate — the single
  most likely silent bug in in-row pagination is page 1 and page N
  silently diverging onto two different `WHERE` clauses.

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
    Enum.map(carousel_row_specs(), fn {key, title} ->
      {games, exhausted?} = fetch_row_page(Atom.to_string(key), 0, @carousel_limit)
      %{key: key, title: title, games: games, offset: length(games), exhausted?: exhausted?}
    end)
  end

  @doc """
  Next page for one carousel row (quick task 260824-u5d, in-row horizontal
  infinite scroll). Returns `{:ok, {games, exhausted?}}` for a known
  `key` string, `:error` for an unrecognised one — never builds an atom
  from `key` (T-01-37 convention). `exhausted?` is true once the row's
  underlying category truly runs out OR the `@carousel_infinite_scroll_max`
  ceiling is reached, whichever comes first.
  """
  def carousel_page(key, offset, limit \\ @carousel_page_size)

  def carousel_page(key, offset, limit) when is_integer(offset) and offset >= 0 do
    case row_query(key) do
      nil -> :error
      _query -> {:ok, fetch_row_page(key, offset, limit)}
    end
  end

  # `limit + 1` over-fetch: one extra row tells us whether more exist,
  # with no second COUNT query per row. Also makes the *initial*
  # exhausted? correct for free — a row shorter than @carousel_limit is
  # exhausted at first paint (e.g. Duelos memorables' 19 games).
  #
  # The request is clamped against the ceiling BEFORE touching the
  # database: when the ceiling is already reached (or would be exceeded),
  # `effective` is 0 and no query runs at all — a client cannot force
  # unbounded queries by repeatedly scrolling an exhausted rail.
  defp fetch_row_page(key, offset, limit) do
    allowed = max(@carousel_infinite_scroll_max - offset, 0)
    effective = min(limit, allowed)

    if effective == 0 do
      {[], true}
    else
      rows =
        key
        |> row_query()
        |> offset(^offset)
        |> limit(^(effective + 1))
        |> Repo.all()

      games = Enum.take(rows, effective)
      exhausted? = length(rows) <= effective or offset + effective >= @carousel_infinite_scroll_max

      {games, exhausted?}
    end
  end

  # Ordered `{key_atom, title}` pairs for the 8 fixed D-09 rows — the
  # single source `list_carousel_rows/0` maps over, so the row set and
  # its order live in exactly one place.
  defp carousel_row_specs do
    [
      {:destacados_del_club, "Destacados del club"},
      {:crea_conexiones, "Crea conexiones"},
      {:equipo_ganador, "Equipo ganador"},
      {:duelos_memorables, "Duelos memorables"},
      {:descubre_el_hobby, "Descubre el hobby"},
      {:ingenio_estratega, "Ingenio estratega"},
      {:nivel_experto, "Nivel experto"},
      {:recientemente_anadidos, "Recientemente añadidos"}
    ]
  end

  # Literal-string clauses with a final catch-all — the T-01-37 convention
  # already used by `facet_assign_key/1` in `CatalogLive.Index`. The
  # client sends a STRING row key (`carousel-load-more`'s payload); never
  # `String.to_atom/1` it. Both `list_carousel_rows/0` and
  # `carousel_page/3` route through this one dispatch.
  defp row_query("destacados_del_club") do
    tags_query(Enum.map(Vocabulary.editorial_tags(), & &1.tag))
  end

  defp row_query("crea_conexiones"), do: tags_query(["#CreaConexiones"])
  defp row_query("equipo_ganador"), do: tags_query(["#EquipoGanador"])
  defp row_query("duelos_memorables"), do: tags_query(["#DuelosMemorables"])
  defp row_query("descubre_el_hobby"), do: weight_band_query("descubre_el_hobby")
  defp row_query("ingenio_estratega"), do: weight_band_query("ingenio_estratega")
  defp row_query("nivel_experto"), do: weight_band_query("nivel_experto")
  defp row_query("recientemente_anadidos"), do: recent_query()
  defp row_query(_unrecognized), do: nil

  # The limit is lifted out of these queries (unlike pre-260824-u5d) so one
  # paginator (`fetch_row_page/3`) serves both the initial page and every
  # increment. An `:id` tiebreaker is added after `:name` on the two
  # name-ordered helpers below — there is no unique index on `name`, so
  # without it Postgres could order tied rows differently between page 1
  # and page 2 and silently duplicate one card while skipping another.
  # `recent_query/0` already tiebreaks on `csv_row` and needs nothing.
  defp tags_query(tags) do
    from g in Game,
      where: fragment("? && ?", g.tags, type(^tags, {:array, :string})),
      order_by: [asc: g.name, asc: g.id]
  end

  defp weight_band_query(band) do
    from g in Game,
      where: g.weight_band == ^band,
      order_by: [asc: g.name, asc: g.id]
  end

  defp recent_query do
    from g in Game,
      where: g.is_expansion == false,
      order_by: [desc: g.inserted_at, desc: g.csv_row]
  end

  defp normalize_opts(opts), do: Map.new(opts)

  defp base_filtered_query(query, opts) do
    query
    |> maybe_search(Map.get(opts, :q))
    |> maybe_filter_mechanics(Map.get(opts, :mechanics))
    |> maybe_filter_themes(Map.get(opts, :themes))
    |> maybe_filter_weight_bands(Map.get(opts, :weight_bands))
    |> maybe_filter_tags(Map.get(opts, :tags))
    |> maybe_filter_designers(Map.get(opts, :designers))
    |> maybe_filter_artists(Map.get(opts, :artists))
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

  # Open-text, whole-name array-membership filters (01.3-06, T-01.3-06-01) —
  # unlike every other maybe_filter_*/2 above, `designers`/`artists` have no
  # closed Vocabulary to translate through (see CatalogFilters moduledoc);
  # the bound-and-parameterize contract from CatalogFilters.parse_name_list_param/1
  # is what keeps this safe, not a whitelist. Values reach the query only
  # via `type(^values, {:array, :string})`, never string interpolation.
  defp maybe_filter_designers(query, values) when values in [nil, []], do: query

  defp maybe_filter_designers(query, values) do
    from g in query, where: fragment("? && ?", g.designers, type(^values, {:array, :string}))
  end

  defp maybe_filter_artists(query, values) when values in [nil, []], do: query

  defp maybe_filter_artists(query, values) do
    from g in query, where: fragment("? && ?", g.artists, type(^values, {:array, :string}))
  end

  defp maybe_filter_players(query, nil), do: query

  # Open-ended top bucket ("6+") — must come before the exact-fit clause
  # below, or it is unreachable. Deliberately NOT a new assign/URL param/
  # scalar name/facet: the chip keeps sending
  # `phx-value-scalar="players" phx-value-choice="6"` through the untouched
  # `toggle-scalar` handler, which is what preserves the cluster's
  # single-select behavior for free (see @players_open_bucket above).
  defp maybe_filter_players(query, n) when n >= @players_open_bucket do
    from g in query, where: g.max_players >= ^n
  end

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
