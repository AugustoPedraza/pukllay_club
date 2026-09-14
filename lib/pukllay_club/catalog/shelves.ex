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

  @doc "Non-retired games with no shelf yet, ordered by name (D-12/D-13)."
  def unplaced_games do
    Repo.all(
      from g in Game,
        where: g.status != :retired and is_nil(g.shelf_id),
        order_by: [asc: g.name, asc: g.id]
    )
  end

  @doc "Non-retired games currently placed on `shelf_id`, ordered by name."
  def games_on_shelf(shelf_id) do
    Repo.all(
      from g in Game,
        where: g.status != :retired and g.shelf_id == ^shelf_id,
        order_by: [asc: g.name, asc: g.id]
    )
  end
end
