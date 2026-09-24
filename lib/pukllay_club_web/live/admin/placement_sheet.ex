defmodule PukllayClubWeb.Admin.PlacementSheet do
  @moduledoc """
  The pure state transitions behind D-00c's full-height "¿Dónde va?"
  sheet, extracted (plan 01.8.2-21, D-32) so `EstanteLive.Index` (the
  original implementation, plan 01.8.2-16) and `GameLive.Form`'s ESTANTE
  block share ONE placement path — never a second, position-blind one
  that could reintroduce "the box goes to the far right" (D-00c
  reversed that; D-32 exists specifically to stop the editor bringing it
  back).

  Every function here is pure state-shaping over the sheet's own map
  (`%{copy:, query:, results:, estante:, copies:}`) — the actual write
  (`Shelves.place_copy/3`, the snackbar/Deshacer wiring) stays owned by
  each caller's own `handle_event/3`, since the two screens differ in
  surrounding chrome (a full rail vs. an editor row) and in what a
  successful commit should refresh. `AdminComponents.placement_sheet/1`
  is the matching shared RENDER half.
  """

  alias PukllayClub.Catalog.Shelves

  @doc "Initial sheet state for placing/moving `copy` (D-00c)."
  @spec open(struct()) :: map()
  def open(copy), do: %{copy: copy, query: "", results: [], estante: nil, copies: []}

  @doc """
  Live search-as-you-type over estantes and already-placed copies
  (`Shelves.search_estantes_or_copies/2`), excluding the copy being
  placed/moved from its own results.
  """
  @spec search(map(), String.t()) :: map()
  def search(state, query) do
    results = if query == "", do: [], else: Shelves.search_estantes_or_copies(query, state.copy.id)
    %{state | query: query, results: results, estante: nil, copies: []}
  end

  @doc "Clears the search field back to the estante-list idle state."
  @spec field_clear(map()) :: map()
  def field_clear(state), do: %{state | query: "", results: [], estante: nil, copies: []}

  @doc """
  Picks an estante — an EMPTY one commits immediately as the copy's
  first box (decision 35), returned as `{:commit, shelf_id, 0}`; a
  non-empty one returns `{:choose_slot, state}` with the rail loaded so
  the caller renders the "+" slots for staff to pick the exact spot.
  """
  @spec pick_estante(map(), struct()) :: {:commit, integer(), 0} | {:choose_slot, map()}
  def pick_estante(state, %{id: shelf_id} = shelf) do
    rail_copies =
      shelf_id
      |> Shelves.copies_on_shelf()
      |> Enum.reject(&(&1.id == state.copy.id))

    if rail_copies == [] do
      {:commit, shelf_id, 0}
    else
      {:choose_slot, %{state | estante: shelf, copies: rail_copies, query: shelf.name, results: []}}
    end
  end

  @doc "Picks an already-placed copy from search results — resolves to ITS estante."
  @spec pick_copy(map(), struct()) :: {:commit, integer(), 0} | {:choose_slot, map()}
  def pick_copy(state, copy), do: pick_estante(state, copy.shelf)
end
