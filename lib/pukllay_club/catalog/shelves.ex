defmodule PukllayClub.Catalog.Shelves do
  @moduledoc """
  Shelf CRUD and physical-location tracking (D-10..D-16, 01.8.1-09) — a
  focused sub-context under `Catalog`, since shelf-location logic is
  staff-only and `PukllayClub.Catalog` stays the public read surface. Every
  write here is a single `Repo.update/1` — each tap on the walk-the-shelf
  screen (`Admin.ShelfLive.Assign`) is its own save, never batched (D-12).

  Games are given at most one shelf (`games.shelf_id`) — no in-shelf
  position, copies of a multi-unit game are assumed stored together
  (D-11). Deleting a `Shelf` row nilifies every game's `shelf_id`
  (`on_delete: :nilify_all`, migration `create_shelves`) — handled at the
  database level, no application code needed for that invariant.
  """

  import Ecto.Query

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Shelf
  alias PukllayClub.Repo

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
  Assigns `game_id` to `shelf_id` (D-12/D-14) — a single `Repo.update/1`
  through `Game.admin_changeset/2`'s cast allowlist, restricted here to
  `:shelf_id` alone. Returns `{:ok, game, previous_shelf}` — `previous_shelf`
  is `nil` when the game had no prior shelf — or `{:error, changeset}` when
  `shelf_id` doesn't exist (`foreign_key_constraint/2` on the changeset,
  surfaced instead of a raised exception so a save-failure toast can render
  it, UI-SPEC E4 error).
  """
  @spec assign_game(integer(), integer() | nil) ::
          {:ok, Game.t(), Shelf.t() | nil} | {:error, Ecto.Changeset.t()}
  def assign_game(game_id, shelf_id) do
    game = Game |> Repo.get!(game_id) |> Repo.preload(:shelf)
    previous_shelf = game.shelf

    game
    |> Game.admin_changeset(%{shelf_id: shelf_id})
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, Repo.preload(updated, :shelf, force: true), previous_shelf}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "Unassigns `game_id` from its current shelf, back to \"Sin ubicar\" (D-14 undo)."
  @spec unassign_game(integer()) :: {:ok, Game.t(), Shelf.t() | nil} | {:error, Ecto.Changeset.t()}
  def unassign_game(game_id), do: assign_game(game_id, nil)

  @doc """
  `{placed, total}` — count of non-retired games with a shelf assigned vs.
  every non-retired game (D-12). The denominator excludes retired games:
  there is nothing to place for a game no one can rent. Drives the
  walk-the-shelf progress line and the dashboard Estantes card badge —
  the single source both surfaces read, so they can never disagree.
  """
  @spec location_progress() :: {non_neg_integer(), non_neg_integer()}
  def location_progress do
    base = from g in Game, where: g.status != :retired

    total = Repo.aggregate(base, :count)
    placed = Repo.aggregate(from(g in base, where: not is_nil(g.shelf_id)), :count)

    {placed, total}
  end

  @doc """
  Non-retired games with no shelf yet, ordered by name (D-12/D-13).
  Preloads `:shelf` (always `nil` here) so callers rendering a game with
  `Admin.ShelfLive.Assign`'s shared tap-button component never hit an
  `Ecto.Association.NotLoaded` truthy-check bug when checking `game.shelf`.
  """
  def unplaced_games do
    from(g in Game,
      where: g.status != :retired and is_nil(g.shelf_id),
      order_by: [asc: g.name, asc: g.id]
    )
    |> Repo.all()
    |> Repo.preload(:shelf)
  end

  @doc "Non-retired games currently placed on `shelf_id`, ordered by name. Preloads `:shelf`."
  def games_on_shelf(shelf_id) do
    from(g in Game,
      where: g.status != :retired and g.shelf_id == ^shelf_id,
      order_by: [asc: g.name, asc: g.id]
    )
    |> Repo.all()
    |> Repo.preload(:shelf)
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
  The Saturday pick/restore list (D-15, UI-SPEC E5 zero-one-many): every
  non-retired game grouped by shelf in walking order, names ordered inside
  each group, followed by a final `{:unplaced, games}` group. An empty
  shelf still appears as `{shelf, []}` — a shelf with nothing on it yet is
  exactly what a Saturday pick/restore run needs to see, not something to
  hide. `q` optionally filters games by name (same escaped ILIKE as
  `search_games/1`) without hiding a shelf's own heading — a shelf with
  zero matches under an active filter still renders, empty.
  """
  @spec pick_list(String.t() | nil) :: [{Shelf.t(), [Game.t()]} | {:unplaced, [Game.t()]}]
  def pick_list(q \\ nil) do
    games =
      Game
      |> where([g], g.status != :retired)
      |> maybe_filter_pick_name(q)
      |> order_by([g], asc: g.name, asc: g.id)
      |> Repo.all()

    games_by_shelf = Enum.group_by(games, & &1.shelf_id)

    shelf_groups =
      Enum.map(list_shelves(), fn shelf ->
        {shelf, Map.get(games_by_shelf, shelf.id, [])}
      end)

    shelf_groups ++ [{:unplaced, Map.get(games_by_shelf, nil, [])}]
  end

  defp maybe_filter_pick_name(query, q) when q in [nil, ""], do: query

  defp maybe_filter_pick_name(query, q) do
    where(query, [g], ilike(g.name, ^("%" <> escape_ilike(q) <> "%")))
  end
end
