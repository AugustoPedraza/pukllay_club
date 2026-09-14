defmodule PukllayClubWeb.Admin.ShelfLive.Assign do
  @moduledoc """
  The phone-first "walk the shelf" tap-to-assign screen at
  `/admin/estantes/:id/asignar` (D-12..D-14, UI-SPEC E4) — the real cost
  this phase exists for: the one-time placement of ~400 existing games,
  spread over several Saturdays.

  Every tap is its own save (`Shelves.assign_game/2`, one `Repo.update/1`)
  — progress persists across sessions, so a fresh mount always shows
  whatever was placed so far. Lists are always re-derived from the
  database after a write, never held as client-trusted state, so a failed
  save can never leave an unsaved assignment on screen (UI-SPEC E4 error).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog.Shelf
  alias PukllayClub.Catalog.Shelves

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Integer.parse(id) do
      {shelf_id, ""} ->
        shelf = Shelves.get_shelf!(shelf_id)

        {:ok,
         socket
         |> assign(:page_title, "Asignando a #{shelf.name}")
         |> assign(:shelf, shelf)
         |> load_lists()}

      _not_an_integer ->
        raise Ecto.NoResultsError, queryable: Shelf
    end
  end

  defp load_lists(socket) do
    shelf = socket.assigns.shelf
    {placed, total} = Shelves.location_progress()

    socket
    |> assign(:placed, placed)
    |> assign(:total, total)
    |> assign(:games_on_shelf, Shelves.games_on_shelf(shelf.id))
    |> assign(:unplaced_games, Shelves.unplaced_games())
  end

  @impl true
  def handle_event("assign", %{"game-id" => game_id}, socket) do
    case Integer.parse(game_id) do
      {int_id, ""} ->
        shelf_id = socket.assigns.shelf.id

        case Shelves.assign_game(int_id, shelf_id) do
          {:ok, _game, _previous_shelf} -> {:noreply, load_lists(socket)}
          {:error, _changeset} -> {:noreply, socket}
        end

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  defp progress_class(placed, total) when placed == total and total > 0, do: "text-success"
  defp progress_class(_placed, _total), do: "text-neutral text-sm"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <.header>
          Asignando a {@shelf.name}
          <:subtitle>
            <span class={progress_class(@placed, @total)}>{@placed}/{@total} ubicados</span>
          </:subtitle>
          <:actions>
            <.link navigate={~p"/admin/juegos"} class="text-sm text-neutral">
              ← Volver
            </.link>
          </:actions>
        </.header>

        <div class="space-y-2">
          <h2 class="font-display text-xl">En este estante ({length(@games_on_shelf)})</h2>
          <p :if={@games_on_shelf == []} class="text-neutral text-sm">
            Todavía no hay juegos en este estante.
          </p>
          <ul class="space-y-1">
            <li :for={game <- @games_on_shelf} class="min-h-11 flex items-center px-2">
              {game.name}
            </li>
          </ul>
        </div>

        <div class="space-y-2">
          <h2 class="font-display text-xl">Sin ubicar ({length(@unplaced_games)})</h2>
          <p :if={@unplaced_games == []} class="text-neutral text-sm">
            Todos los juegos ya tienen un estante.
          </p>
          <button
            :for={game <- @unplaced_games}
            type="button"
            phx-click="assign"
            phx-value-game-id={game.id}
            class="flex w-full min-h-11 items-center gap-2 rounded-box border border-base-300 p-2 text-left"
          >
            {game.name}
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
