defmodule PukllayClub.Catalog do
  @moduledoc """
  The Catalog context — the only module `PukllayClub.Catalog.Game` rows are
  read/written through, whether from the public catalog UI
  (`CatalogLive.Index`) or the admin. **The database is the sole source of
  truth (D-09):** the CSV seed path (`mix catalog.seed`,
  `Catalog.Seed.CsvImport`, and the full-row `upsert_game!/1` upsert) was
  retired in phase 01.8.1 and must never be reintroduced — a replace-all
  upsert would silently revert any admin edit. `/admin` is the only editing
  surface for club-owned fields; the surviving offline tasks
  (`StatsEnricher`, `GalleryBackfill`, `OGCardBackfill`,
  `catalog.translate_descriptions`) write through narrow allowlists that
  never touch a club-owned column.

  `filter_games/1` is the single composed query serving CATALOG-02
  (filter), CATALOG-03 (search), and CATALOG-04 (sort) together, per
  01-RESEARCH.md Pattern 3 — one pipeline of `maybe_*` predicates, never a
  branch between "search mode" and "filter mode". Every user-supplied value
  reaches Postgres as a pinned `^` parameter inside `fragment/2`; no query
  text is ever built by string interpolation (T-01-20).
  """

  import Ecto.Query

  alias Ecto.Multi
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.SectionGame
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClub.Repo
  alias PukllayClub.Workers.EnrichGameWorker

  @default_limit 24
  # Admin Juegos list (D-09 Task 2) page size — the UI-SPEC's own E1
  # truth ("~400 rows via `Cargar más`") calls for a larger first page
  # than the public catalog's @default_limit, matching the plan's own
  # acceptance behavior ("With 60 games, the first render shows 50 rows").
  @admin_default_limit 50
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
  # D-26: the featured section's own ceiling — capped at ~20 total,
  # never the @carousel_infinite_scroll_max every other section gets.
  @featured_max 20
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
    |> published_only()
    |> order_by([g], asc: g.name)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  The one composed query serving filtering, faceting, searching, sorting,
  and pagination together (CATALOG-02/03/04, D-14/D-15).

  Accepts a map or keyword list with `:q`, `:mechanics` (Spanish labels),
  `:themes` (Spanish labels), `:weight_bands`, `:sections` (D-27, bound
  positive integers — see `maybe_filter_sections/2`), `:designers`,
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
    |> put_section_names()
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

  # Postgres' `bigint` range — the `games.id` primary key's real column
  # type. A crafted id outside this range would otherwise reach Postgrex as
  # a bound parameter and raise there (T-2x6-03); rejecting it here keeps
  # the single 404 contract intact instead of risking a 500.
  @max_bigint 9_223_372_036_854_775_807

  @doc """
  Fetches a single game by id, raising `Ecto.NoResultsError` for an unknown
  id. `Ecto.NoResultsError` implements `Plug.Exception` with a 404 status,
  so a caller rendering it as a Plug/LiveView error surfaces the generated
  404 page rather than a crash or a 500 (T-01-30).

  **This is the unfiltered ADMIN read (D-04/D-08)** — it returns a `:draft`
  or `:retired` game exactly as readily as a `:published` one, so a game can
  still be opened for editing regardless of its lifecycle status. Every
  PUBLIC read path must use `get_published_game!/1` instead; see that
  function's own @doc.

  Accepts either the bare `"<id>"` form or the id-slug `"<id>-<anything>"`
  form (quick task 260913-2x6) — the slug tail is only for readability/SEO
  and is never validated against the game's real current slug here; that
  canonicalization check lives in `PukllayClubWeb.Plugs.GameSEO` and
  `CatalogLive.Show.handle_params/3`, which compare the raw param against
  `Phoenix.Param.to_param/1` and redirect/patch when it differs. A
  non-numeric id, an id followed by anything other than a `-`, or an
  integer outside Postgres' bigint range (T-2x6-03) all raise
  `Ecto.NoResultsError` here — `Repo.get!/2` would otherwise raise
  `Ecto.Query.CastError` for a non-numeric id, which does *not* implement
  `Plug.Exception` and would 500 instead of rendering the branded 404.
  """
  def get_game!(id) when is_binary(id) do
    case Integer.parse(id) do
      {int_id, ""} -> fetch_by_id!(int_id)
      {int_id, "-" <> _rest} -> fetch_by_id!(int_id)
      _ -> raise Ecto.NoResultsError, queryable: Game
    end
  end

  def get_game!(id), do: Repo.get!(Game, id)

  defp fetch_by_id!(int_id) when int_id in 1..@max_bigint, do: Repo.get!(Game, int_id)
  defp fetch_by_id!(_out_of_range), do: raise(Ecto.NoResultsError, queryable: Game)

  @doc """
  Builds an admin edit changeset for `game` (D-07) — the five club-owned
  fields only, via `Game.admin_changeset/2`. Used by
  `PukllayClubWeb.Admin.GameLive.Form` for both the initial form and live
  `phx-change="validate"` re-validation.
  """
  def change_game_admin(%Game{} = game, attrs \\ %{}) do
    Game.admin_changeset(game, attrs)
  end

  @doc """
  Persists an admin edit to `game` (D-07) via `Game.admin_changeset/2`.
  Returns `{:ok, game}` / `{:error, changeset}`. BGG-derived fields
  submitted in `attrs` are silently ignored — `Game.admin_changeset/2`'s
  cast allowlist is the enforcement point (T-01.8.1-21).
  """
  def update_game_admin(%Game{} = game, attrs) do
    game
    |> Game.admin_changeset(attrs)
    |> Repo.update()
  end

  # Postgres' `integer` range — the `games.bgg_id` column's real column
  # type (D-01, 01.8.1-08). A parsed id outside this range can never be a
  # real BGG id worth accepting.
  @max_bgg_id 2_147_483_647

  @doc """
  Parses staff-pasted BGG input (D-01, 01.8.1-08): either a bare BGG id
  (digits only, surrounding whitespace trimmed) or a full BGG URL —
  `boardgamegeek.com`/`www.boardgamegeek.com` only, path starting
  `/boardgame/<digits>` or `/boardgameexpansion/<digits>` (`URI.parse/1`
  for the host check, T-01.8.1-37: an off-host URL is never accepted, so a
  crafted URL can never reach `BggClient` with an id it wasn't meant to
  have). The extracted digits are cast with `Integer.parse/1` and must
  fall in `1..#{@max_bgg_id}` (the `games.bgg_id` integer column's real
  range) — `"0"`, an id above that range, and anything else return
  `:error`.
  """
  @spec parse_bgg_input(String.t()) :: {:ok, pos_integer()} | :error
  def parse_bgg_input(input) when is_binary(input) do
    trimmed = String.trim(input)

    with :error <- parse_bgg_digits(trimmed) do
      parse_bgg_url(trimmed)
    end
  end

  defp parse_bgg_digits(value) do
    if value != "" and String.match?(value, ~r/^[0-9]+$/) do
      validate_bgg_range(String.to_integer(value))
    else
      :error
    end
  end

  @allowed_bgg_hosts ["boardgamegeek.com", "www.boardgamegeek.com"]

  defp parse_bgg_url(value) do
    uri = URI.parse(value)

    with true <- uri.host in @allowed_bgg_hosts,
         path when is_binary(path) <- uri.path,
         [_match, digits] <- Regex.run(~r{^/(?:boardgame|boardgameexpansion)/([0-9]+)}, path) do
      validate_bgg_range(String.to_integer(digits))
    else
      _no_match -> :error
    end
  end

  defp validate_bgg_range(id) when id >= 1 and id <= @max_bgg_id, do: {:ok, id}
  defp validate_bgg_range(_out_of_range), do: :error

  # T-01.8.1-73: the first key of the two-int4 `pg_advisory_xact_lock(int,
  # int)` form (distinct from the single-bigint form Postgres also
  # supports — the two forms live in separate advisory-lock key spaces,
  # `objsubid` 2 vs 1 in `pg_locks`, so this namespace can never collide
  # with a future single-bigint advisory lock elsewhere in this app). The
  # second key is always the parsed BGG id.
  @bgg_id_lock_namespace 8_811_015

  @doc """
  Creates a `:draft` game from staff-pasted BGG input — a bare id or a BGG
  URL, via `parse_bgg_input/1` (D-01) — and enqueues its background
  enrichment job in the same transaction: either both the row and the job
  exist, or neither does. Unparseable input returns
  `{:error, :invalid_bgg_id}` before any database work happens.

  **D-03 (revised 2026-09-14, gap CR-B-01, user decision): a known BGG id
  is a WARNING, not a rejection.** Games legitimately share a BGG id when
  they are editions of one another (BGG 163412: "Patchwork" / "Patchwork
  Andino") — `games.bgg_id` is intentionally NOT unique, and a unique or
  partial-unique index on it is wrong for this project (it would reject
  those real editions and fail the production migration). Adding an id
  that already belongs to any game — draft, published, or retired —
  inserts nothing and returns `{:existing_editions, games}`: every game
  currently holding that id, ordered by `:id` ascending, never empty. A
  caller confirms an edition via `acknowledged_game_ids:` (the ids it just
  showed the user); the insert proceeds only when every current holder's
  id is in that list (`MapSet.subset?/2`). A repeated confirm that no
  longer covers every current holder (double-tap, a stale second tab)
  returns the refreshed `{:existing_editions, games}` list instead of
  inserting again — one staff action can never produce two drafts.

  A per-BGG-id `pg_advisory_xact_lock(#{@bgg_id_lock_namespace}, bgg_id)`
  serializes same-id callers across processes (two tabs, two staff): it is
  taken FIRST, inside the same `Ecto.Multi`/transaction as the editions
  re-check, insert, and job enqueue, so the re-check always runs as a
  fresh READ COMMITTED read that sees whatever a prior lock holder just
  committed. **In sandboxed tests the xact lock is held until the test's
  own sandbox transaction ends — any test calling this function must live
  in an `async: false` module**, and a test that wants to observe the
  lock/race itself needs a real (unboxed) connection — see
  `test/pukllay_club/catalog/bgg_editions_test.exs`.

  Returns `{:ok, game}` with the inserted draft, `{:existing_editions,
  games}` when not every current holder was acknowledged, or `{:error,
  changeset}` if `Game.draft_changeset/2` itself rejects the parsed id
  (defensive — the range check in `parse_bgg_input/1` already prevents
  most invalid input from reaching it).
  """
  @spec add_game_from_bgg(String.t(), keyword()) ::
          {:ok, Game.t()}
          | {:existing_editions, [Game.t(), ...]}
          | {:error, :invalid_bgg_id | Ecto.Changeset.t()}
  def add_game_from_bgg(bgg_id, opts \\ []) when is_binary(bgg_id) do
    acknowledged_game_ids = Keyword.get(opts, :acknowledged_game_ids, [])

    case parse_bgg_input(bgg_id) do
      {:ok, bgg_id_int} -> insert_draft_with_edition_check(bgg_id_int, acknowledged_game_ids)
      :error -> {:error, :invalid_bgg_id}
    end
  end

  defp insert_draft_with_edition_check(bgg_id_int, acknowledged_game_ids) do
    Multi.new()
    |> Multi.run(:bgg_id_lock, fn repo, _changes ->
      repo.query!("SELECT pg_advisory_xact_lock($1, $2)", [@bgg_id_lock_namespace, bgg_id_int])
      {:ok, :locked}
    end)
    |> Multi.run(:editions_check, fn repo, _changes ->
      check_bgg_id_editions(repo, bgg_id_int, acknowledged_game_ids)
    end)
    |> Multi.insert(:game, Game.draft_changeset(%Game{}, %{bgg_id: bgg_id_int}))
    |> Oban.insert(:enrich_job, fn %{game: game} ->
      EnrichGameWorker.new(%{game_id: game.id})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{game: game}} ->
        {:ok, game}

      {:error, :editions_check, {:existing_editions, games}, _changes_so_far} ->
        {:existing_editions, games}

      {:error, :game, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  # Runs AFTER the lock, as its own statement inside the same transaction,
  # so READ COMMITTED gives it a fresh snapshot that includes whatever a
  # lock holder just committed (T-01.8.1-68). No status filter — draft,
  # published, and retired games all count as an existing edition holder.
  defp check_bgg_id_editions(repo, bgg_id_int, acknowledged_game_ids) do
    games =
      repo.all(from(g in Game, where: g.bgg_id == ^bgg_id_int, order_by: [asc: g.id]))

    existing_ids = MapSet.new(games, & &1.id)

    if MapSet.subset?(existing_ids, MapSet.new(acknowledged_game_ids)) do
      {:ok, :acknowledged}
    else
      {:error, {:existing_editions, games}}
    end
  end

  @doc """
  Re-enqueues enrichment for a `"failed"` draft (D-03) — sets
  `enrichment_status` back to `"pending"` and inserts a fresh
  `EnrichGameWorker` job in one `Ecto.Multi`, so the row is never left
  stuck between "failed" and "pending" if the insert somehow failed.
  Returns `{:error, :not_failed}` for any other `enrichment_status`
  without touching the row — Reintentar only ever applies to a genuinely
  failed record.
  """
  @spec retry_enrichment(Game.t()) :: {:ok, Game.t()} | {:error, :not_failed}
  def retry_enrichment(%Game{enrichment_status: "failed"} = game) do
    Multi.new()
    |> Multi.update(:game, Game.enrichment_changeset(game, %{enrichment_status: "pending"}))
    |> Oban.insert(:enrich_job, fn %{game: game} ->
      EnrichGameWorker.new(%{game_id: game.id})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{game: game}} -> {:ok, game}
    end
  end

  def retry_enrichment(%Game{}), do: {:error, :not_failed}

  @doc """
  Admin listing of games (D-09 Task 2) — unlike every public read path,
  this has NO status filter by default: staff see drafts, published, and
  retired games together. Accepts `:status` (`:draft | :published |
  :retired | nil` — `nil` means "all"), `:q` (case-insensitive `ilike`
  name search, `\\`/`%`/`_` escaped before wrapping in `%...%` so a
  literal percent/underscore in a game's name cannot be used to widen the
  match, T-01-20/T-01.8.1-23), `:limit` (default #{@admin_default_limit})
  and `:offset`. Always ordered `[asc: g.name, asc: g.id]` — the `:id`
  tiebreaker keeps `Cargar más` pagination stable across pages, same
  convention as every other paginated read in this module.
  """
  def list_admin_games(opts \\ []) do
    opts = normalize_opts(opts)
    limit = Map.get(opts, :limit, @admin_default_limit)
    offset = Map.get(opts, :offset, 0)

    Game
    |> admin_filtered_query(opts)
    |> order_by([g], asc: g.name, asc: g.id)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Total count of games matching `list_admin_games/1`'s same `:status`/`:q`
  predicates, ignoring `:limit`/`:offset` — drives the dashboard's
  `{N} borradores` badge (`count_admin_games(status: :draft)`, D-35) and
  the Juegos list's `Cargar más` exhaustion check.
  """
  def count_admin_games(opts \\ []) do
    opts = normalize_opts(opts)

    Game
    |> admin_filtered_query(opts)
    |> Repo.aggregate(:count)
  end

  defp admin_filtered_query(query, opts) do
    query
    |> maybe_filter_admin_status(Map.get(opts, :status))
    |> maybe_search_admin_name(Map.get(opts, :q))
  end

  @doc """
  The admin Juegos list, grouped by `status` (D-25, plan 01.8.2-14) —
  the partition the redesigned Juegos screen renders three sections from
  (Borradores/Juegos del club/Retirados). Every game appears in EXACTLY
  one of the three keys: the partition is guaranteed by the schema
  (`Game.status` is an `Ecto.Enum` with three mutually exclusive values,
  D-04) rather than by three independently-ordered predicates, so
  `length(:draft) + length(:published) + length(:retired) ==
  count_admin_games(opts)` always holds — assert it, don't just trust it.

  Accepts the same `:q` `list_admin_games/1` does (case-insensitive
  `ilike` name search, same escaping — T-01-20/T-01.8.1-23). Never accepts
  `:status`: the whole point of this function is the status split, so a
  `:status` opt here would fight its own return shape (silently dropped
  rather than raising, matching `normalize_opts/1`'s permissive style).
  Never accepts `:limit`/`:offset` either — D-25 replaces `Cargar más`
  paging with one continuously-scrolled, grouped list; every matching row
  is returned. Each group is ordered `[asc: g.name, asc: g.id]`, the same
  tie-break `list_admin_games/1` uses.
  """
  @spec list_admin_games_by_status(keyword() | map()) :: %{
          draft: [Game.t()],
          published: [Game.t()],
          retired: [Game.t()]
        }
  def list_admin_games_by_status(opts \\ []) do
    opts =
      opts
      |> normalize_opts()
      |> Map.drop([:status, :limit, :offset])

    grouped =
      Game
      |> admin_filtered_query(opts)
      |> order_by([g], asc: g.name, asc: g.id)
      |> Repo.all()
      |> Enum.group_by(& &1.status)

    %{
      draft: Map.get(grouped, :draft, []),
      published: Map.get(grouped, :published, []),
      retired: Map.get(grouped, :retired, [])
    }
  end

  defp maybe_filter_admin_status(query, nil), do: query
  defp maybe_filter_admin_status(query, status), do: from(g in query, where: g.status == ^status)

  defp maybe_search_admin_name(query, q) when q in [nil, ""], do: query

  defp maybe_search_admin_name(query, q) do
    pattern = "%" <> escape_ilike(q) <> "%"
    from g in query, where: ilike(g.name, ^pattern)
  end

  # T-01.8.1-23: `%`/`_` are ILIKE wildcards and `\` is the escape
  # character itself — each must be escaped before this value is wrapped
  # in `%...%`, or a game named e.g. "100%" would match every row via an
  # unintended wildcard rather than a literal substring.
  defp escape_ilike(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end

  @doc """
  Fetches a single **published** game by id, raising `Ecto.NoResultsError`
  for an unknown id, a non-numeric id, an id outside Postgres' bigint
  range, OR a `:draft`/`:retired` game (D-04, D-08, RESEARCH.md Pitfall 2).
  `Ecto.NoResultsError` implements `Plug.Exception` (404), so
  `PukllayClubWeb.Plugs.GameSEO` and `CatalogLive.Show.mount/3` both render
  the branded 404 for a drafted or retired game's URL — identical to an
  unknown id (T-01.8.1-12: this is the one open decision this plan's
  checkpoint settled).

  Deliberately its OWN function with its own private `fetch_published_by_id!/1`
  — never a boolean flag threaded through `get_game!/1` — so the published
  predicate cannot accidentally be forgotten/inverted at a call site
  (RESEARCH.md Pitfall 2's explicit warning). Mirrors `get_game!/1`'s exact
  id-parsing contract (bare id, id-slug, non-numeric, out-of-bigint) so the
  two functions only ever differ by the `status` predicate.
  """
  def get_published_game!(id) when is_binary(id) do
    case Integer.parse(id) do
      {int_id, ""} -> fetch_published_by_id!(int_id)
      {int_id, "-" <> _rest} -> fetch_published_by_id!(int_id)
      _ -> raise Ecto.NoResultsError, queryable: Game
    end
  end

  def get_published_game!(id), do: fetch_published_by_id!(id)

  defp fetch_published_by_id!(int_id) when int_id in 1..@max_bigint do
    from(g in Game, where: g.id == ^int_id and g.status == :published)
    |> Repo.one!()
    |> put_section_names()
  end

  defp fetch_published_by_id!(_out_of_range), do: raise(Ecto.NoResultsError, queryable: Game)

  @doc """
  Moves `game` to `:published` from `:draft` only (D-04, D-08, D-37 gate 1)
  — a staff-drafted game's first publish. A retired game reaches
  `:published` only through `restore_game/1`, the dedicated retired ->
  published entry point; publishing it directly here would bypass that
  function's guard, the exact gap sketch 078 proved was pure paint (a drawn
  gate the code never enforced).

  **D-30's nivel gate (plan 01.8.2-20):** a draft additionally needs
  `Game.needs_nivel_to_publish?/1` to be false — a non-expansion draft with
  no `weight_band` returns `{:error, :nivel_required}` instead of
  publishing, since it would otherwise render in no weight-band row on the
  home page (D-37). An expansion has no such condition (D-30 is explicit).
  This lives HERE, not only in the draft sheet's UI (D-37: "078 proved the
  drawn gate is pure paint by publishing through the other door") — every
  caller of this function is gated, the button is a convenience, not the
  control.

  Returns `{:ok, game}` on a publishable draft, `{:error, :nivel_required}`
  on a non-expansion draft with no nivel, or `{:error, :not_publishable}`
  for any other origin status (leaving it unchanged in every error case).
  """
  def publish_game(%Game{status: :draft} = game) do
    if Game.needs_nivel_to_publish?(game) do
      {:error, :nivel_required}
    else
      game
      |> Game.status_changeset(%{status: :published})
      |> Repo.update()
    end
  end

  def publish_game(%Game{}), do: {:error, :not_publishable}

  @doc """
  Moves `game` to `:retired` from `:published` only (D-08's soft delete,
  D-37 gate 1) — a retired game disappears from every public surface
  `:draft` already did (T-01.8.1-12), restorable via `restore_game/1`.
  Returns `{:ok, game}` on a published game, or `{:error, :not_retirable}`
  for any other origin status (leaving it unchanged).
  """
  def retire_game(%Game{status: :published} = game) do
    game
    |> Game.status_changeset(%{status: :retired})
    |> Repo.update()
  end

  def retire_game(%Game{}), do: {:error, :not_retirable}

  @doc """
  Restores a `:retired` game back to `:published` (D-08). A game that is
  not currently retired returns `{:error, :not_retired}` rather than
  silently succeeding — restore is defined only as the retired -> published
  transition, `publish_game/1` is the entry point for draft -> published.
  """
  def restore_game(%Game{status: :retired} = game) do
    game
    |> Game.status_changeset(%{status: :published})
    |> Repo.update()
  end

  def restore_game(%Game{}), do: {:error, :not_retired}

  @doc """
  The single, explicitly-ordered source of truth for `sitemap.xml`'s
  per-game entries (SEO-04). Selects `Game` structs carrying only `:id`,
  `:name` and `:updated_at` (quick task 260913-2x6 widened this from
  `:id`/`:updated_at` alone: `:name` is now needed because
  `SitemapController` interpolates the struct into `~p"/juegos/\#{game}"`,
  which routes through the one `Phoenix.Param` impl and needs `:name` to
  derive the slug). Ordered by `:id` (a property of the query, not of
  Postgres' physical row order) so two successive requests over unchanged
  data return byte-identical documents.

  **Filters to `:published` games only (D-04, D-08).** This function's own
  moduledoc used to warn that a future visibility/draft/soft-delete column
  would need a filter added here "at the same time, or a hidden/draft game
  would still appear in the public sitemap" (RESEARCH.md Pitfall 2) — this
  plan's `add_status_to_games` migration is that column, and this is that
  filter.
  """
  @spec sitemap_entries() :: [Game.t()]
  def sitemap_entries do
    Repo.all(
      from g in Game,
        where: g.status == :published,
        select: struct(g, [:id, :name, :updated_at]),
        order_by: [asc: g.id]
    )
  end

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

  **Candidates are filtered to `:published` games only (D-04, D-08)** — the
  viewed game itself is excluded by `where: g.id != ^id` regardless of its
  own status (it is already resolved via `get_published_game!/1` by the
  caller, so it can only reach here already published).
  """
  def similar_games(%Game{id: id, weight_band: weight_band, mechanics: mechanics, themes: themes}) do
    band_order = band_preference_order(weight_band)

    from(g in Game,
      where: g.id != ^id and g.status == :published,
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
    |> Repo.all()
    |> put_section_names()
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
  bands, and sections (D-27) — every value the vocabulary/database exposes
  as a filterable facet. `sections` lists non-hidden `:manual` sections
  with at least one published member, featured first then by `position` —
  the same ordering `list_home_sections/0` uses for the home page itself —
  computed with one `exists` subquery per section row rather than an N+1
  membership check (T-01.8.1-53).
  """
  def facet_options do
    %{
      mechanics: Vocabulary.mechanic_options(),
      themes: Vocabulary.theme_options(),
      weight_bands: Vocabulary.weight_bands(),
      sections: section_facet_options()
    }
  end

  defp section_facet_options do
    Repo.all(
      from s in Section,
        as: :section,
        where: s.kind == :manual and s.hidden == false,
        where:
          exists(
            from sg in SectionGame,
              join: g in Game,
              on: g.id == sg.game_id,
              where: sg.section_id == parent_as(:section).id and g.status == :published
          ),
        order_by: [desc: s.featured, asc: s.position],
        select: %{id: s.id, name: s.name}
    )
  end

  @doc """
  Fills `Game.section_names` (a virtual field, D-17, 01.8.1-11) — the
  chips/preview data source that replaced the retired `games.tags`
  hashtag facet (D-22 option A: `tags` stays frozen history, never read
  by a public surface again). Accepts a single `%Game{}` or a list, and
  returns the same shape back with `:section_names` populated: the names
  of each game's visible (non-hidden, non-featured) `:manual` sections,
  ordered by section `position`.

  ONE query for the whole list — never one per game (T-01.8.1-53) — so
  every public read that feeds a chip or preview (`get_published_game!/1`,
  `filter_games/1`, `fetch_section_page/3` — covering both
  `list_home_sections/0` and `section_page/3` — and `similar_games/1`)
  costs exactly one extra query for its own page, not N.
  """
  def put_section_names(games) when is_list(games) do
    names_by_game_id = section_names_by_game_id(Enum.map(games, & &1.id))

    Enum.map(games, fn game -> %{game | section_names: Map.get(names_by_game_id, game.id, [])} end)
  end

  def put_section_names(%Game{} = game) do
    [game] = put_section_names([game])
    game
  end

  defp section_names_by_game_id([]), do: %{}

  defp section_names_by_game_id(ids) do
    SectionGame
    |> join(:inner, [sg], s in Section, on: s.id == sg.section_id)
    |> where(
      [sg, s],
      sg.game_id in ^ids and s.kind == :manual and s.hidden == false and s.featured == false
    )
    |> order_by([sg, s], asc: s.position)
    |> select([sg, s], {sg.game_id, s.name})
    |> Repo.all()
    |> Enum.group_by(fn {game_id, _name} -> game_id end, fn {_game_id, name} -> name end)
  end

  @doc """
  The home page's staff-owned sections (D-17..D-28), replacing the retired
  hardcoded 8-row dispatch (`carousel_row_specs/0`/`row_query/1`). Loads
  every non-hidden section ordered featured-first then by `position`
  (D-18), fetches each section's first page through `fetch_section_page/3`
  — the featured section capped at `@featured_max` games (D-26), every
  other section capped at `@carousel_infinite_scroll_max` — and drops any
  section whose first page comes back empty (D-24: no published members,
  or every member is draft/retired).

  Each row is `%{key:, section_id:, title:, subtitle:, kind:, rule_value:,
  featured?:, games:, offset:, exhausted?:}` — `key` is the client-facing
  `"section-<id>"` string `section_page/3` accepts back; `section_id` is
  the raw integer used to derive this row's LiveView stream name
  (`carousel_section_<id>`), never built from client input (T-01.8.1-46).
  """
  def list_home_sections do
    Section
    |> where([s], s.hidden == false)
    |> order_by([s], desc: s.featured, asc: s.position)
    |> Repo.all()
    |> Enum.map(&build_home_section/1)
    |> Enum.reject(&(&1.games == []))
  end

  defp build_home_section(section) do
    initial_limit = min(@carousel_limit, ceiling_for(section))
    {games, exhausted?} = fetch_section_page(section, 0, initial_limit)

    %{
      key: "section-#{section.id}",
      section_id: section.id,
      title: section.name,
      subtitle: section.subtitle,
      kind: section.kind,
      rule_value: section.rule_value,
      featured?: section.featured,
      games: games,
      offset: length(games),
      exhausted?: exhausted?
    }
  end

  @doc """
  Next page for one home-page section (quick task 260824-u5d's in-row
  infinite scroll, ported to sections). `key` must be a `"section-<id>"`
  string with `id` parsed via a literal prefix match + `Integer.parse/1` —
  the client-sent key is never converted into an atom (T-01-37/T-01.8.1-46).
  Returns `{:ok, {games, exhausted?}}` for a known, non-hidden section id,
  `:error` for anything else (unknown id, a hidden section, or a malformed
  key).
  """
  def section_page(key, offset, limit \\ @carousel_page_size)

  def section_page("section-" <> id_string, offset, limit) when is_integer(offset) and offset >= 0 do
    with {id, ""} <- Integer.parse(id_string),
         %Section{hidden: false} = section <- Repo.get(Section, id) do
      {:ok, fetch_section_page(section, offset, limit)}
    else
      _ -> :error
    end
  end

  def section_page(_key, _offset, _limit), do: :error

  # Same `limit + 1` over-fetch shape the retired `fetch_row_page/3`
  # carried: one extra row tells us whether more exist, with no second
  # COUNT query. The request is clamped against this section's own
  # ceiling BEFORE touching the database — a client cannot force an
  # unbounded query by repeatedly requesting an exhausted rail.
  defp fetch_section_page(section, offset, limit) do
    ceiling = ceiling_for(section)
    allowed = max(ceiling - offset, 0)
    effective = min(limit, allowed)

    if effective == 0 do
      {[], true}
    else
      rows =
        section
        |> section_query()
        |> offset(^offset)
        |> limit(^(effective + 1))
        |> Repo.all()

      games = rows |> Enum.take(effective) |> put_section_names()
      exhausted? = length(rows) <= effective or offset + effective >= ceiling

      {games, exhausted?}
    end
  end

  # D-26: the featured section is capped at @featured_max; every other
  # section keeps the pre-existing @carousel_infinite_scroll_max ceiling.
  defp ceiling_for(%Section{featured: true}), do: @featured_max
  defp ceiling_for(%Section{featured: false}), do: @carousel_infinite_scroll_max

  # Dispatches on the section's own `kind`/`sort` (loaded from the
  # database, never client input). `manual` joins `section_games`;
  # `weight_band` filters on the game's own `weight_band` column;
  # `recent` filters non-expansions. Every variant keeps
  # `status == :published` (D-24, T-01.8.1-47) and ends its `order_by`
  # with a `g.id` tiebreaker — there is no unique index on `name`, so
  # without it Postgres could order tied rows differently between page 1
  # and page 2 and silently duplicate one card while skipping another
  # (the same reasoning the retired `tags_query/1`/`weight_band_query/1`
  # carried).
  defp section_query(%Section{kind: :manual, id: id, sort: sort}) do
    manual_order_by(
      from(g in Game,
        join: sg in SectionGame,
        on: sg.game_id == g.id and sg.section_id == ^id,
        where: g.status == :published
      ),
      sort
    )
  end

  # D-37 gate 2: excludes expansions, mirroring the `:recent` clause below
  # — this was masked only because every one of the catalog's 26
  # expansions carries a NULL `weight_band` today, and D-30's editor flow
  # (01.8.2) puts staff in front of that field for the first time.
  defp section_query(%Section{kind: :weight_band, rule_value: band, sort: sort}) do
    automatic_order_by(
      from(g in Game, where: g.weight_band == ^band and g.status == :published and g.is_expansion == false),
      sort
    )
  end

  defp section_query(%Section{kind: :recent, sort: sort}) do
    automatic_order_by(from(g in Game, where: g.is_expansion == false and g.status == :published), sort)
  end

  defp manual_order_by(query, :manual) do
    from [g, sg] in query, order_by: [asc: sg.position, asc: g.id]
  end

  defp manual_order_by(query, sort), do: automatic_order_by(query, sort)

  defp automatic_order_by(query, :name) do
    from g in query, order_by: [asc: g.name, asc: g.id]
  end

  defp automatic_order_by(query, :bgg_weight) do
    from g in query, order_by: [asc_nulls_last: g.bgg_weight, asc: g.id]
  end

  defp automatic_order_by(query, :bgg_rating) do
    from g in query, order_by: [desc_nulls_last: g.bgg_rating, asc: g.id]
  end

  defp automatic_order_by(query, :recent) do
    from g in query, order_by: [desc: g.inserted_at, asc: g.id]
  end

  defp normalize_opts(opts), do: Map.new(opts)

  defp base_filtered_query(query, opts) do
    query
    |> published_only()
    |> maybe_search(Map.get(opts, :q))
    |> maybe_filter_mechanics(Map.get(opts, :mechanics))
    |> maybe_filter_themes(Map.get(opts, :themes))
    |> maybe_filter_weight_bands(Map.get(opts, :weight_bands))
    |> maybe_filter_sections(Map.get(opts, :sections))
    |> maybe_filter_designers(Map.get(opts, :designers))
    |> maybe_filter_artists(Map.get(opts, :artists))
    |> maybe_filter_players(Map.get(opts, :players))
    |> maybe_filter_playtime(Map.get(opts, :max_playtime))
    |> maybe_filter_age(Map.get(opts, :min_age))
  end

  # D-04, D-08, RESEARCH.md Pitfall 2: the single non-optional published
  # predicate every public read composes with — never a `maybe_*` predicate,
  # since it is never conditional. Applied at the head of
  # `base_filtered_query/2` (covering `filter_games/1`/`count_games/1`
  # together) and directly by every other public read below
  # (`list_games/1`, `sitemap_entries/0`, `similar_games/1`,
  # `tags_query/1`, `weight_band_query/1`, `recent_query/0`) so a draft or
  # retired game can never leak through any read path in this module.
  defp published_only(query), do: from(g in query, where: g.status == :published)

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

  # D-27, T-01.8.1-50/T-01.8.1-51: `ids` are bound integers by the time they
  # reach here (`CatalogFilters.from_params/1`'s `parse_id_list_param/1`
  # already parsed/deduped/capped them) — never string-interpolated. The
  # subquery restricts to `:manual`, non-hidden sections so a hidden
  # section's id, or a `:weight_band`/`:recent` section's id, matches no
  # game (an automatic section has no `section_games` rows at all).
  defp maybe_filter_sections(query, ids) when ids in [nil, []], do: query

  defp maybe_filter_sections(query, ids) do
    from g in query,
      where:
        g.id in subquery(
          from sg in SectionGame,
            join: s in Section,
            on: s.id == sg.section_id,
            where: sg.section_id in ^ids and s.kind == :manual and s.hidden == false,
            select: sg.game_id
        )
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
