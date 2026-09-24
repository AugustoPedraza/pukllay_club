defmodule PukllayClub.Catalog.Shelves do
  @moduledoc """
  Shelf CRUD and per-copy physical-location tracking (D-01..D-04, D-11,
  01.8.1-09, 01.8.2-01) — a focused sub-context under `Catalog`, since
  shelf-location logic is staff-only and `PukllayClub.Catalog` stays the
  public read surface.

  **D-01 (reverses 01.8.1 D-11): every physical copy has its own
  location** — an estante plus a left-to-right `position` in it. Place
  and move act on a `PukllayClub.Catalog.Copy`, never on a `Game`; the
  entire old game-level shelf write/read path built directly on
  `games.shelf_id` (one shelf per game, no in-shelf position) is gone
  outright — a second, game-level source of truth alongside the
  copy-level one would reintroduce exactly the model D-01 reverses.

  **D-11: concurrent staff never collide or gap.** `place_copy/3` and
  `remove_copy_from_shelf/1` each take a per-estante
  `pg_advisory_xact_lock` (namespace `@estante_lock_namespace`, `shelf_id`
  as the second key) as the first step of an
  `Ecto.Multi`/`Repo.transaction/1`, mirroring `catalog.ex`'s
  `@bgg_id_lock_namespace` precedent for the same reason —
  the two-int4 form's `pg_locks.objsubid` is a namespace-scoped key
  space, so this module's namespace can never collide with catalog.ex's.
  A cross-estante move locks BOTH estantes, always in ascending
  `shelf_id` order, so two concurrent cross-estante moves can never
  deadlock waiting on each other in opposite orders.

  Every successful write broadcasts `{:estante_updated, shelf_id}` on
  PubSub topic `"admin:estantes"` (mirrors
  `workers/enrich_game_worker.ex`'s `"admin:games"` broadcast) — always
  AFTER the transaction commits, never from inside it.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias PukllayClub.Catalog.Copy
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Shelf
  alias PukllayClub.Repo

  # T-01.8.2-01/02: the first key of the two-int4 `pg_advisory_xact_lock(int,
  # int)` form — distinct from `catalog.ex`'s own `@bgg_id_lock_namespace`
  # module attribute (a different integer entirely), so this namespace can
  # never collide with it (each namespace value gets its own
  # `pg_locks.objsubid` key space). The second key is always an estante's
  # `shelf_id`.
  @estante_lock_namespace 8_811_016

  # T-01.8.2-55/56 (plan 01.8.2-13): `search_copies/1`'s two bounds, mirroring
  # `CatalogFilters`' own established 20x120 ceiling for open-text admin
  # params (`@max_name_length`, `parse_list_param/2`'s `Enum.take(20)`) — the
  # query string is capped BEFORE it ever reaches `ilike/2`, and the result
  # set is capped so a broad match (e.g. a single common letter) can never
  # return more than a short, scannable suggestion list.
  @max_search_query_length 120
  @max_search_results 20

  @doc "Shelves in walking order (ascending `position`, `:id` tiebreak)."
  def list_shelves do
    Repo.all(from s in Shelf, order_by: [asc: s.position, asc: s.id])
  end

  @doc "Fetches a shelf by id, raising `Ecto.NoResultsError` for an unknown id."
  def get_shelf!(id), do: Repo.get!(Shelf, id)

  @doc """
  Creates a shelf at the next walking position (max existing position + 1,
  or 1 for the very first shelf) — D-10. Returns `{:ok, shelf}` /
  `{:error, changeset}` (e.g. a duplicate name, or a name over 40
  characters — UI-SPEC E4 long-text).
  """
  def create_shelf(attrs) do
    %Shelf{}
    |> Shelf.changeset(Map.put(normalize_attrs(attrs), :position, next_position()))
    |> Repo.insert()
  end

  defp next_position do
    case Repo.one(from s in Shelf, select: max(s.position)) do
      nil -> 1
      max -> max + 1
    end
  end

  defp normalize_attrs(attrs) when is_map(attrs), do: attrs
  defp normalize_attrs(attrs), do: Map.new(attrs)

  @doc """
  Renames a shelf (D-10) — same 40-character cap as `create_shelf/1`
  (`Shelf.changeset/2`). Returns `{:ok, shelf}` / `{:error, changeset}`.
  """
  def rename_shelf(%Shelf{} = shelf, name) do
    shelf
    |> Shelf.changeset(%{name: name})
    |> Repo.update()
  end

  @doc """
  Swaps `shelf`'s walking-order position with its immediate neighbour in
  `direction` (`:up` moves it earlier, `:down` moves it later) — D-10. A
  no-op at either end of the list (moving the first shelf up, or the last
  shelf down) rather than an error, since the UI never disables those
  buttons (prefer enabled-and-no-op over disabled). Both updates happen
  inside one transaction so a concurrent reorder (T-01.8.1-44, accepted
  low-severity risk) can never leave two shelves sharing a position.
  """
  def move_shelf(%Shelf{position: original_position} = shelf, direction) when direction in [:up, :down] do
    case neighbor(shelf, direction) do
      nil ->
        {:ok, shelf}

      neighbor ->
        Repo.transaction(fn ->
          {:ok, shelf} = update_position(shelf, neighbor.position)
          {:ok, _neighbor} = update_position(neighbor, original_position)
          shelf
        end)
    end
  end

  defp update_position(%Shelf{} = shelf, position) do
    shelf
    |> Shelf.changeset(%{position: position})
    |> Repo.update()
  end

  defp neighbor(%Shelf{position: position}, :up) do
    Repo.one(
      from s in Shelf,
        where: s.position < ^position,
        order_by: [desc: s.position],
        limit: 1
    )
  end

  defp neighbor(%Shelf{position: position}, :down) do
    Repo.one(
      from s in Shelf,
        where: s.position > ^position,
        order_by: [asc: s.position],
        limit: 1
    )
  end

  @doc """
  Deletes `shelf` in one locked transaction (D-10, plan 01.8.2-18) —
  every copy currently on it is snapshotted as `{copy_id, position}`
  BEFORE anything is written, both halves of a copy's location
  (`shelf_id` AND `position`) are nilified explicitly, and only then is
  the `shelves` row itself deleted. Returns `{:ok, snapshot}`, a plain
  map `%{name: ..., position: ..., copies: [{copy_id, position}, ...]}`
  — exactly what `restore_deleted_shelf/1` needs to put the whole
  arrangement back.

  T-01.8.2-81: never trusts `copies.shelf_id`'s `on_delete: :nilify_all`
  FK alone to leave copies in a consistent "Sin ubicar" state — that
  clause (verified directly, not assumed, by `shelves_test.exs`) only
  touches `shelf_id`; `position` carries no FK of its own and would
  otherwise survive deletion as a stale, meaningless value on a copy
  that reads as unplaced everywhere else. This function's own explicit
  `update_all` is therefore the primary guarantee, with the FK as a
  second line of defense. Never deletes a `Copy` row.
  """
  @spec delete_shelf(Shelf.t()) ::
          {:ok, %{name: String.t(), position: integer(), copies: [{integer(), integer()}]}}
          | {:error, term()}
  def delete_shelf(%Shelf{id: shelf_id, name: name, position: position} = shelf) do
    Multi.new()
    |> Multi.run(:lock, fn repo, _changes -> lock_estantes(repo, [shelf_id]) end)
    |> Multi.run(:snapshot, fn repo, _changes -> {:ok, snapshot_shelf_copies(repo, shelf_id)} end)
    |> Multi.run(:cleared, fn repo, _changes ->
      repo.update_all(from(c in Copy, where: c.shelf_id == ^shelf_id), set: [shelf_id: nil, position: nil])
      {:ok, :cleared}
    end)
    |> Multi.run(:deleted, fn repo, _changes -> repo.delete(shelf) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{snapshot: copies}} ->
        broadcast(shelf_id)
        {:ok, %{name: name, position: position, copies: copies}}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp snapshot_shelf_copies(repo, shelf_id) do
    Copy
    |> where([c], c.shelf_id == ^shelf_id)
    |> select([c], {c.id, c.position})
    |> repo.all()
  end

  @doc """
  Restores a shelf deleted by `delete_shelf/1` from its own snapshot map
  (Deshacer, D-10) — re-inserts a shelf row (a **new** id; the deleted
  row is truly gone) at its former walking-order `position`, then writes
  every snapshotted copy's `{shelf_id, position}` back in one pass.

  A distinct function rather than looping `restore_position/3`
  (`place_copy/3`) once per copy, deliberately: the freshly inserted
  shelf starts with zero copies of its own, so writing every
  snapshotted copy directly onto it can never collide with
  `copies_shelf_position_unique` (that index only guards copies sharing
  ONE `shelf_id`, and every one of these copies is landing on the SAME
  brand-new, previously-empty `shelf_id`) — a loop over `place_copy/3`
  would instead reindex the destination between each step and would not
  reproduce the exact recorded arrangement.

  WR-05: locks the destination shelf plus every currently-distinct
  `shelf_id` among the snapshotted copies' LIVE rows (mirroring
  `lock_estantes/2`'s convention elsewhere in this module), then only
  restores a copy whose live `shelf_id` is still `nil` — exactly what
  `delete_shelf/1` leaves every one of its copies with. If a different
  staff member independently placed one of these copies onto some other
  real shelf in the window between the delete and this Deshacer (that
  other write correctly reindexed around it via `place_copy/3`), this
  function now skips that copy rather than unconditionally clobbering it
  back — silently ripping it away from where the other staff member just
  put it and leaving a gap on that other shelf with nothing left to
  explain it.
  """
  @spec restore_deleted_shelf(%{name: String.t(), position: integer(), copies: [{integer(), integer()}]}) ::
          {:ok, Shelf.t()} | {:error, term()}
  def restore_deleted_shelf(%{name: name, position: position, copies: copies}) do
    copy_ids = Enum.map(copies, fn {copy_id, _copy_position} -> copy_id end)

    Multi.new()
    |> Multi.run(:shelf, fn repo, _changes ->
      %Shelf{} |> Shelf.changeset(%{name: name, position: position}) |> repo.insert()
    end)
    |> Multi.run(:lock, fn repo, %{shelf: shelf} ->
      lock_estantes(repo, [shelf.id | live_shelf_ids(repo, copy_ids)])
    end)
    |> Multi.run(:restored, fn repo, %{shelf: shelf} ->
      live_by_id = live_shelf_by_copy(repo, copy_ids)

      Enum.each(copies, fn {copy_id, copy_position} ->
        if Map.get(live_by_id, copy_id) == nil do
          repo.update_all(from(c in Copy, where: c.id == ^copy_id),
            set: [shelf_id: shelf.id, position: copy_position]
          )
        end
      end)

      {:ok, shelf}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{shelf: shelf}} ->
        broadcast(shelf.id)
        {:ok, shelf}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp live_shelf_ids(repo, copy_ids) do
    Copy
    |> where([c], c.id in ^copy_ids)
    |> select([c], c.shelf_id)
    |> repo.all()
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp live_shelf_by_copy(repo, copy_ids) do
    Copy
    |> where([c], c.id in ^copy_ids)
    |> select([c], {c.id, c.shelf_id})
    |> repo.all()
    |> Map.new()
  end

  @doc """
  `{placed, total}` — count of non-retired games with a shelf assigned vs.
  every non-retired game (D-12). The denominator excludes retired games:
  there is nothing to place for a game no one can rent. Drives the
  dashboard Estantes card badge (`Admin.DashboardLive`) — unchanged by
  01.8.2-01's copy-level rewrite below, since it still reads the
  pre-existing `games.shelf_id` column directly rather than deriving from
  `copies` (a later plan revisits this once `games.shelf_id` itself is
  retired — D-31 dropped the old flat count column, not this one).
  """
  @spec location_progress() :: {non_neg_integer(), non_neg_integer()}
  def location_progress do
    base = from g in Game, where: g.status != :retired

    total = Repo.aggregate(base, :count)
    placed = Repo.aggregate(from(g in base, where: not is_nil(g.shelf_id)), :count)

    {placed, total}
  end

  @doc """
  `{placed, total}` copy-level meter (plan 01.8.2-11, D-02/D-31) — the
  copy-level replacement `Admin.DashboardLive`'s Estantes box reads for
  its meter and percentage. `placed` is every copy with a `shelf_id`;
  `total` is every copy, placed or not. Deliberately NOT
  `location_progress/0` above: that function still counts
  non-retired GAMES via the dead `games.shelf_id` column (a carried-
  forward defect from 01.8.2-01's copy-level rewrite, flagged rather than
  read from here) — this one is copy-level from the start, consistent
  with D-02/D-31's "count(copies) is the only Copias source" rule.
  `{0, 0}` for a club with zero copy rows, never a division error.
  """
  @spec copies_progress() :: {non_neg_integer(), non_neg_integer()}
  def copies_progress do
    total = Repo.aggregate(Copy, :count)
    placed = Repo.aggregate(from(c in Copy, where: not is_nil(c.shelf_id)), :count)

    {placed, total}
  end

  @doc """
  Type-ahead search (D-13) across every non-retired game (placed or not),
  by name — the same escaped ILIKE convention as `Catalog.list_admin_games/1`
  (T-01.8.1-23: `%`/`_`/`\\` escaped before wrapping in `%...%`, so a
  literal percent/underscore in a game's name cannot widen the match).
  Preloads `:shelf` so a placed match can render its current shelf name
  inline. Capped at 20 results (T-01-22).
  """
  @spec search_games(String.t()) :: [Game.t()]
  def search_games(q) when is_binary(q) and q != "" do
    pattern = "%" <> escape_ilike(q) <> "%"

    Game
    |> where([g], g.status != :retired)
    |> where([g], ilike(g.name, ^pattern))
    |> order_by([g], asc: g.name, asc: g.id)
    |> limit(20)
    |> Repo.all()
    |> Repo.preload(:shelf)
  end

  def search_games(_blank), do: []

  # Mirrors `PukllayClub.Catalog`'s own `escape_ilike/1` (T-01.8.1-23).
  defp escape_ilike(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end

  @doc """
  Type-ahead suggestion query across every non-retired game's copies (D-08,
  plan 01.8.2-13 — supersedes `search_games/1` above as the Estantes
  screen's own suggestion source, since that function reads the dead
  `games.shelf_id` column per its own moduledoc flag). Bound by query
  length (#{@max_search_query_length} chars) and result count
  (#{@max_search_results}) — T-01.8.2-55/56, mirroring `CatalogFilters`'
  20x120 open-text ceiling; never `String.to_atom/1` on the input. Matches
  by game name (same escaped-ILIKE convention as `search_games/1`), across
  BOTH placed and unplaced copies — D-08's suggestion row renders either the
  estante name or the `Sin lugar` marker, so an unplaced copy must be
  reachable here too. Preloads `:game` and `:shelf` (the latter `nil` for
  an unplaced copy) so a caller never has to follow up with a second query
  per row.
  """
  @spec search_copies(String.t()) :: [Copy.t()]
  def search_copies(q) when is_binary(q) and q != "" do
    escaped = q |> String.slice(0, @max_search_query_length) |> escape_ilike()
    pattern = "%" <> escaped <> "%"

    Copy
    |> join(:inner, [c], g in assoc(c, :game))
    |> where([c, g], g.status != :retired)
    |> where([c, g], ilike(g.name, ^pattern))
    |> order_by([c, g], asc: g.name, asc: g.id)
    |> limit(^@max_search_results)
    |> Repo.all()
    |> Repo.preload([:game, :shelf])
  end

  def search_copies(_blank), do: []

  @doc """
  Search results for the «¿Dónde va?» full-height sheet (D-00c, plan
  01.8.2-16) — estantes matching `q` by name, then already-placed
  copies matching `q` by their game's name (picking one resolves to
  **its** estante, so staff can place a box "next to" a game they can
  see). Estantes rank first, tagged `{:shelf, shelf}` / `{:copy, copy}`,
  capped at `#{@max_search_results}` total results combined (T-01.8.2-73:
  bounded, parameterized, never `String.to_atom/1`). `exclude_copy_id`
  drops the copy currently being placed/moved from its own results —
  finding yourself as a neighbourhood makes no sense.

  An UNPLACED copy's game never appears here: it has no estante to
  resolve to, and `search_copies/1` (D-08, the Estantes page's own
  suggestion source) already covers "find any game, placed or not" —
  this function answers a narrower question, "where could this box go".
  """
  @spec search_estantes_or_copies(String.t(), integer() | nil) :: [
          {:shelf, Shelf.t()} | {:copy, Copy.t()}
        ]
  def search_estantes_or_copies(q, exclude_copy_id \\ nil)

  def search_estantes_or_copies(q, exclude_copy_id) when is_binary(q) and q != "" do
    escaped = q |> String.slice(0, @max_search_query_length) |> escape_ilike()
    pattern = "%" <> escaped <> "%"

    shelves =
      Shelf
      |> where([s], ilike(s.name, ^pattern))
      |> order_by([s], asc: s.name, asc: s.id)
      |> limit(^@max_search_results)
      |> Repo.all()

    remaining = max(@max_search_results - length(shelves), 0)
    copies = search_placed_copies(pattern, exclude_copy_id, remaining)

    Enum.map(shelves, &{:shelf, &1}) ++ Enum.map(copies, &{:copy, &1})
  end

  def search_estantes_or_copies(_blank, _exclude_copy_id), do: []

  defp search_placed_copies(_pattern, _exclude_copy_id, 0), do: []

  defp search_placed_copies(pattern, exclude_copy_id, limit) do
    Copy
    |> join(:inner, [c], g in assoc(c, :game))
    |> where([c, g], g.status != :retired)
    |> where([c], not is_nil(c.shelf_id))
    |> where([c, g], ilike(g.name, ^pattern))
    |> exclude_copy(exclude_copy_id)
    |> order_by([c, g], asc: g.name, asc: c.id)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:game, :shelf])
  end

  defp exclude_copy(query, nil), do: query
  defp exclude_copy(query, copy_id), do: where(query, [c], c.id != ^copy_id)

  @doc """
  Restores `copy_id` to the exact `{shelf_id, position}` snapshot taken
  immediately before a place/move/remove write — the Deshacer path
  behind every undoable action on `/admin/estantes` (plan 01.8.2-16:
  the «¿Dónde va?» and «¿Qué juego va acá?» sheets, and the Quitar del
  estante dialog). `shelf_id: nil` means the copy was Sin ubicar before
  the write being undone, so restoring is `remove_copy_from_shelf/1`; a
  real `shelf_id` restores through `place_copy/3`'s own locked, gap-free
  insert — reindexing around the returning copy exactly as any other
  placement would, since the neighbours may have shifted while the copy
  was away (another staff member's write, or the very write being
  undone). Never `place_copy/3` with a remembered array index against a
  now-stale neighbour list — that is exactly what this function exists
  to avoid.
  """
  @spec restore_position(integer(), integer() | nil, non_neg_integer() | nil) ::
          {:ok, Copy.t()} | {:error, term()}
  def restore_position(copy_id, nil, nil), do: remove_copy_from_shelf(copy_id)

  def restore_position(copy_id, shelf_id, position) when is_integer(shelf_id) and is_integer(position) do
    place_copy(copy_id, shelf_id, position)
  end

  @doc "Fetches a copy by id, game and shelf preloaded, raising `Ecto.NoResultsError` for an unknown id."
  @spec get_copy!(integer()) :: Copy.t()
  def get_copy!(id) do
    Copy
    |> Repo.get!(id)
    |> Repo.preload([:game, :shelf])
  end

  @doc """
  Copies on `shelf_id`, in real left-to-right `position` order (D-04/D-08
  — the replacement for the old game-level read's name ordering). Game
  preloaded.
  """
  @spec copies_on_shelf(integer()) :: [Copy.t()]
  def copies_on_shelf(shelf_id) do
    Copy
    |> where([c], c.shelf_id == ^shelf_id)
    |> order_by([c], asc: c.position)
    |> Repo.all()
    |> Repo.preload(:game)
  end

  @doc "Unplaced copies (\"Sin ubicar\", `shelf_id` nil), game preloaded, ordered by game name."
  @spec unplaced_copies() :: [Copy.t()]
  def unplaced_copies do
    Repo.all(
      from(c in Copy,
        join: g in assoc(c, :game),
        where: is_nil(c.shelf_id),
        order_by: [asc: g.name, asc: c.id],
        preload: [game: g]
      )
    )
  end

  @doc """
  Copies count for one game (D-02, D-31) — `count(copies)` is the ONLY
  source for the Copias value; every display of it calls this function
  (or `counts_for_games/1` for a list). Never `nil`: a game backed by
  zero copy rows reports `0`, not a missing value.
  """
  @spec count_for_game(integer()) :: non_neg_integer()
  def count_for_game(game_id) do
    Repo.aggregate(from(c in Copy, where: c.game_id == ^game_id), :count)
  end

  @doc """
  Batch copies-count for several games at once (D-02, D-31) — avoids an
  N+1 `count_for_game/1` call per row on a list screen. Returns a map of
  `game_id => count`; a `game_id` with zero copies is simply absent from
  the map (callers should read it with `Map.get(counts, game_id, 0)`).
  """
  @spec counts_for_games([integer()]) :: %{integer() => non_neg_integer()}
  def counts_for_games(game_ids) do
    Copy
    |> where([c], c.game_id in ^game_ids)
    |> group_by([c], c.game_id)
    |> select([c], {c.game_id, count(c.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Every copy of `game_id`, ordered by stable `number` (D-03) — the
  Copias stepper's which-copy-to-remove sheet, and the editor's own
  ESTANTE block (plan 01.8.2-21, D-31/D-32). `:shelf` AND `:game`
  preloaded — `:game` because `PlacementSheet.open/1`'s resulting state
  feeds `AdminComponents.placement_sheet/1`, which renders the sheet's
  `subtitle`/`cover` off `state.copy.game`, the same shape
  `Shelves.get_copy!/1` already returns for `EstanteLive.Index`'s own
  identical usage. An unplaced copy's `:shelf` is `nil`.
  """
  @spec copies_for_game(integer()) :: [Copy.t()]
  def copies_for_game(game_id) do
    Copy
    |> where([c], c.game_id == ^game_id)
    |> order_by([c], asc: c.number)
    |> Repo.all()
    |> Repo.preload([:shelf, :game])
  end

  @doc """
  Creates a new UNPLACED copy for `game_id` (D-02, D-31, plan 01.8.2-21)
  — the Copias stepper's "raise" write. `number` is one past the current
  maximum for this game (D-03: never a renumber; a gap left by a
  previously removed copy is never reused). The new row appears in
  `unplaced_copies/0` immediately, so it counts toward the Pendientes
  badge — broadcasts `{:estante_updated, nil}` on `"admin:estantes"` (no
  real estante is involved, but every open Estantes/Pendientes page
  recomputes its Pendientes count on ANY broadcast regardless of
  payload, per D-11) so a staff member with that page open sees the
  count move without a manual refresh.
  """
  @spec add_copy(integer()) :: {:ok, Copy.t()} | {:error, Ecto.Changeset.t()}
  def add_copy(game_id) do
    case %Copy{} |> Copy.changeset(%{game_id: game_id, number: next_copy_number(game_id)}) |> Repo.insert() do
      {:ok, copy} ->
        broadcast(nil)
        {:ok, copy}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp next_copy_number(game_id) do
    case Repo.one(from(c in Copy, where: c.game_id == ^game_id, select: max(c.number))) do
      nil -> 1
      max -> max + 1
    end
  end

  @doc """
  Removes one copy of `game_id` (D-02, D-31, plan 01.8.2-21) — the
  Copias stepper's "lower" write. Prefers an UNPLACED copy (the lowest
  `number` one, deleted directly — no lock needed, nothing to reindex).
  When `copy_id` is `nil` and every copy of this game is already placed,
  returns `{:error, :no_unplaced_copy}` rather than guessing which
  placed one to remove — the caller presents the which-copy-to-remove
  sheet and calls back with an explicit `copy_id`, which is removed via
  `delete_copy/1`'s locked, gap-free reindex.
  """
  @spec remove_copy_for_game(integer(), integer() | nil) ::
          {:ok, Copy.t()} | {:error, :no_unplaced_copy | term()}
  def remove_copy_for_game(game_id, copy_id \\ nil)

  def remove_copy_for_game(game_id, nil) do
    case unplaced_copy_for_game(game_id) do
      nil -> {:error, :no_unplaced_copy}
      copy -> delete_copy(copy)
    end
  end

  def remove_copy_for_game(_game_id, copy_id) when is_integer(copy_id) do
    delete_copy(get_copy!(copy_id))
  end

  defp unplaced_copy_for_game(game_id) do
    Repo.one(
      from(c in Copy,
        where: c.game_id == ^game_id and is_nil(c.shelf_id),
        order_by: [asc: c.number],
        limit: 1
      )
    )
  end

  @doc """
  Deletes `copy` outright (D-02, D-31, plan 01.8.2-21) —
  `remove_copy_for_game/2`'s final step, also callable directly once a
  which-copy-to-remove sheet names the exact placed copy. An unplaced
  copy is deleted directly (nothing to reindex). A placed copy is
  vacated from its estante — the SAME gap-free reindex
  `remove_copy_from_shelf/1` performs, under the SAME per-estante
  advisory lock — and deleted, in ONE transaction, never a two-step
  remove-then-delete (a crash between the two could otherwise leave a
  phantom placed row, or a gapped estante with no row left to explain
  it).
  """
  @spec delete_copy(Copy.t()) :: {:ok, Copy.t()} | {:error, term()}
  def delete_copy(%Copy{shelf_id: nil} = copy) do
    case Repo.delete(copy) do
      {:ok, deleted} ->
        broadcast(nil)
        {:ok, deleted}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete_copy(%Copy{shelf_id: shelf_id} = copy) do
    Multi.new()
    |> Multi.run(:lock, fn repo, _changes -> lock_estantes(repo, [shelf_id]) end)
    |> Multi.run(:vacated, fn repo, _changes -> vacate(repo, copy) end)
    |> Multi.delete(:deleted, copy)
    |> Repo.transaction()
    |> case do
      {:ok, %{deleted: deleted}} ->
        broadcast(shelf_id)
        {:ok, deleted}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  @doc """
  Batch copies-count for several estantes at once (mirrors
  `counts_for_games/1`'s shape, plan 01.8.2-18) — avoids an N+1
  per-row query on Administrar estantes' `N juegos` meta. Returns a
  map of `shelf_id => count`; a `shelf_id` with zero copies is simply
  absent from the map (callers should read it with `Map.get(counts,
  shelf_id, 0)`).
  """
  @spec counts_for_shelves([integer()]) :: %{integer() => non_neg_integer()}
  def counts_for_shelves(shelf_ids) do
    Copy
    |> where([c], c.shelf_id in ^shelf_ids)
    |> group_by([c], c.shelf_id)
    |> select([c], {c.shelf_id, count(c.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Places `copy_id` on `shelf_id` at the 0-based `index` slot — D-00c
  ("before the first box, between any two, or after the last"). Handles
  every starting state uniformly: a first placement (the copy was
  unplaced), a move from a different estante (D-11: removed from the old
  estante and that estante is reindexed gap-free, in the same
  transaction), and a move to a new index within the SAME estante.
  `index` is clamped into `0..count` (`count` = the destination
  estante's OTHER copies, after the copy has been vacated from its old
  position) — an out-of-range index lands at the nearest valid end
  rather than erroring, since a stale client-side count racing a
  concurrent placement is exactly the case the advisory lock exists to
  serialize, not reject.

  Every position write inside the transaction is its own single-row
  `UPDATE`, issued in an order chosen so no two copies on one estante
  ever transiently share a `position` — `copies_shelf_position_unique`
  is a real (non-deferrable) unique index, checked immediately, so a
  same-statement bulk shift could otherwise raise spuriously depending on
  Postgres's internal row-processing order. Vacating shifts the old
  estante DOWN in ascending-position order (each row moves into a slot
  already emptied by the row below it); inserting shifts the destination
  estante UP in descending-position order (each row moves into a slot
  already emptied by the row above it).

  Returns `{:ok, copy}` / `{:error, reason}`. Broadcasts
  `{:estante_updated, shelf_id}` for the destination estante, and again
  for the source estante when a cross-estante move actually vacated one.
  """
  @spec place_copy(integer(), integer(), non_neg_integer()) ::
          {:ok, Copy.t()} | {:error, term()}
  def place_copy(copy_id, shelf_id, index) when is_integer(index) do
    Multi.new()
    |> Multi.run(:copy, fn repo, _changes -> fetch_copy(repo, copy_id) end)
    |> Multi.run(:lock, fn repo, %{copy: copy} -> lock_estantes(repo, [copy.shelf_id, shelf_id]) end)
    |> Multi.run(:vacated, fn repo, %{copy: copy} -> vacate(repo, copy) end)
    |> Multi.run(:moved, fn repo, %{copy: copy} -> insert_at(repo, copy, shelf_id, index) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{copy: original, moved: moved}} ->
        broadcast(shelf_id)
        if original.shelf_id not in [nil, shelf_id], do: broadcast(original.shelf_id)
        {:ok, moved}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  @doc """
  Removes `copy_id` from its estante — `shelf_id`/`position` both go to
  `nil` ("Sin ubicar") and the estante it left is reindexed gap-free
  under the same per-estante advisory lock `place_copy/3` uses. A no-op
  (`{:ok, copy}`, no lock taken, no broadcast) when the copy is already
  unplaced.
  """
  @spec remove_copy_from_shelf(integer()) :: {:ok, Copy.t()} | {:error, term()}
  def remove_copy_from_shelf(copy_id) do
    Multi.new()
    |> Multi.run(:copy, fn repo, _changes -> fetch_copy(repo, copy_id) end)
    |> Multi.run(:lock, fn repo, %{copy: copy} -> lock_estantes(repo, [copy.shelf_id]) end)
    |> Multi.run(:removed, fn repo, %{copy: copy} -> vacate_and_clear(repo, copy) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{copy: %Copy{shelf_id: nil}, removed: removed}} ->
        {:ok, removed}

      {:ok, %{copy: original, removed: removed}} ->
        broadcast(original.shelf_id)
        {:ok, removed}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp fetch_copy(repo, copy_id) do
    case repo.get(Copy, copy_id) do
      nil -> {:error, :copy_not_found}
      copy -> {:ok, copy}
    end
  end

  # T-01.8.2-02: every non-nil, distinct estante among the ones this write
  # touches is locked, always in ascending `shelf_id` order, so two
  # concurrent cross-estante moves can never deadlock waiting on each
  # other in opposite orders. `nil` (unplaced) has no estante to lock.
  defp lock_estantes(repo, shelf_ids) do
    shelf_ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.each(fn id ->
      repo.query!("SELECT pg_advisory_xact_lock($1, $2)", [@estante_lock_namespace, id])
    end)

    {:ok, :locked}
  end

  # Removes `copy` from its current position (if it has one), reindexing
  # its OLD estante gap-free. A copy that is already unplaced is a no-op.
  defp vacate(_repo, %Copy{shelf_id: nil}), do: {:ok, :not_placed}

  defp vacate(repo, %Copy{id: id, shelf_id: shelf_id, position: position}) do
    # Vacate this copy's own slot FIRST — a NOT DEFERRABLE unique index
    # checks immediately, so leaving this row's `position` in place while
    # shifting its neighbours down risks a transient (shelf_id, position)
    # collision the instant a neighbour lands on it.
    repo.update_all(from(c in Copy, where: c.id == ^id), set: [position: nil])

    Copy
    |> where([c], c.shelf_id == ^shelf_id and c.position > ^position)
    |> order_by([c], asc: c.position)
    |> select([c], {c.id, c.position})
    |> repo.all()
    |> Enum.each(fn {row_id, row_position} ->
      repo.update_all(from(c in Copy, where: c.id == ^row_id), set: [position: row_position - 1])
    end)

    {:ok, :vacated}
  end

  defp vacate_and_clear(_repo, %Copy{shelf_id: nil} = copy), do: {:ok, copy}

  defp vacate_and_clear(repo, %Copy{} = copy) do
    {:ok, :vacated} = vacate(repo, copy)
    repo.update_all(from(c in Copy, where: c.id == ^copy.id), set: [shelf_id: nil, position: nil])
    {:ok, %{copy | shelf_id: nil, position: nil}}
  end

  # Inserts `copy` onto `shelf_id` at `index`, clamped to the destination
  # estante's OTHER copies (`c.id != ^id` excludes `copy` itself — load
  # bearing for a same-estante move, where `copy`'s own row still carries
  # `shelf_id` at this point, just a `nil` position from `vacate/2`
  # above). Shifts the destination's copies at or after the target index
  # UP by one, descending-position order first, so each shift lands in a
  # slot its own neighbour has already vacated.
  defp insert_at(repo, %Copy{id: id} = copy, shelf_id, index) do
    others = where(Copy, [c], c.shelf_id == ^shelf_id and c.id != ^id)
    count = repo.aggregate(others, :count)
    target = index |> max(0) |> min(count)

    others
    |> where([c], c.position >= ^target)
    |> order_by([c], desc: c.position)
    |> select([c], {c.id, c.position})
    |> repo.all()
    |> Enum.each(fn {row_id, row_position} ->
      repo.update_all(from(c in Copy, where: c.id == ^row_id), set: [position: row_position + 1])
    end)

    repo.update_all(from(c in Copy, where: c.id == ^id), set: [shelf_id: shelf_id, position: target])

    {:ok, %{copy | shelf_id: shelf_id, position: target}}
  end

  defp broadcast(shelf_id) do
    Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:estantes", {:estante_updated, shelf_id})
  end
end
