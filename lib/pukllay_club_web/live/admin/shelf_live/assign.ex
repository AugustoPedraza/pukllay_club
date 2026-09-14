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

  A `phx-debounce="300"` type-ahead name search (D-13) sits above the
  "Sin ubicar" list and searches every non-retired game, placed or not —
  tapping a placed match instantly *moves* it (D-14), rendering a bottom
  toast ("Movido desde {shelf} · Deshacer") that can undo the move. A
  failed save (e.g. the shelf itself was deleted mid-session) reverts to
  the previous state and shows "No se pudo guardar · Reintentar" in the
  same toast slot (UI-SPEC E4 error) — the screen never shows an unsaved
  assignment. Tapping a game already on the current shelf is a no-op: no
  save, no toast.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog.Shelf
  alias PukllayClub.Catalog.Shelves

  @toast_ttl_ms 6_000

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Integer.parse(id) do
      {shelf_id, ""} ->
        shelf = Shelves.get_shelf!(shelf_id)

        {:ok,
         socket
         |> assign(:page_title, "Asignando a #{shelf.name}")
         |> assign(:shelf, shelf)
         |> assign(:q, "")
         |> assign(:search_results, [])
         |> assign(:toast, nil)
         |> assign(:rename_open, false)
         |> assign(:rename_input, shelf.name)
         |> assign(:rename_error, nil)
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
  def handle_event("search", %{"q" => q}, socket) do
    results = if q == "", do: [], else: Shelves.search_games(q)
    {:noreply, socket |> assign(:q, q) |> assign(:search_results, results)}
  end

  @impl true
  def handle_event("assign", %{"game-id" => game_id}, socket) do
    case Integer.parse(game_id) do
      {int_id, ""} -> {:noreply, do_assign(socket, int_id)}
      _not_an_integer -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("undo-move", params, socket) do
    game_id = parse_optional_id(params["game-id"])
    shelf_id = parse_optional_id(params["shelf-id"])

    if game_id do
      result =
        if shelf_id, do: Shelves.assign_game(game_id, shelf_id), else: Shelves.unassign_game(game_id)

      case result do
        {:ok, _game, _previous} -> {:noreply, socket |> load_lists() |> clear_toast()}
        {:error, _changeset} -> {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open-rename", _params, socket) do
    {:noreply,
     socket
     |> assign(:rename_open, true)
     |> assign(:rename_input, socket.assigns.shelf.name)
     |> assign(:rename_error, nil)}
  end

  @impl true
  def handle_event("cancel-rename", _params, socket) do
    {:noreply, assign(socket, :rename_open, false)}
  end

  @impl true
  def handle_event("rename", %{"name" => name}, socket) do
    case Shelves.rename_shelf(socket.assigns.shelf, name) do
      {:ok, shelf} ->
        {:noreply,
         socket
         |> assign(:shelf, shelf)
         |> assign(:page_title, "Asignando a #{shelf.name}")
         |> assign(:rename_open, false)
         |> assign(:rename_error, nil)
         |> load_lists()}

      {:error, changeset} ->
        error = changeset.errors |> translate_errors(:name) |> List.first()
        {:noreply, socket |> assign(:rename_input, name) |> assign(:rename_error, error)}
    end
  end

  @impl true
  def handle_info({:clear_toast, ref}, socket) do
    case socket.assigns.toast do
      %{ref: ^ref} -> {:noreply, clear_toast(socket)}
      _stale_or_none -> {:noreply, socket}
    end
  end

  # D-13/D-14: a tap on a game already placed on THIS shelf is a genuine
  # no-op — no save, no toast — checked against the already-loaded
  # `:games_on_shelf` list rather than an extra query.
  defp do_assign(socket, game_id) do
    if on_this_shelf?(socket, game_id) do
      socket
    else
      shelf_id = socket.assigns.shelf.id

      case Shelves.assign_game(game_id, shelf_id) do
        {:ok, _game, nil} ->
          socket |> load_lists() |> clear_toast()

        {:ok, _game, previous_shelf} ->
          socket |> load_lists() |> set_moved_toast(game_id, previous_shelf)

        {:error, _changeset} ->
          set_error_toast(socket, game_id)
      end
    end
  end

  defp on_this_shelf?(socket, game_id) do
    Enum.any?(socket.assigns.games_on_shelf, &(&1.id == game_id))
  end

  defp set_moved_toast(socket, game_id, previous_shelf) do
    ref = make_ref()
    Process.send_after(self(), {:clear_toast, ref}, @toast_ttl_ms)

    assign(socket, :toast, %{
      kind: :moved,
      game_id: game_id,
      previous_shelf_id: previous_shelf.id,
      text: "Movido desde #{previous_shelf.name}",
      ref: ref
    })
  end

  defp set_error_toast(socket, game_id) do
    ref = make_ref()
    Process.send_after(self(), {:clear_toast, ref}, @toast_ttl_ms)

    assign(socket, :toast, %{
      kind: :error,
      game_id: game_id,
      previous_shelf_id: nil,
      text: "No se pudo guardar",
      ref: ref
    })
  end

  defp clear_toast(socket), do: assign(socket, :toast, nil)

  defp parse_optional_id(nil), do: nil
  defp parse_optional_id(""), do: nil

  defp parse_optional_id(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _not_an_integer -> nil
    end
  end

  defp progress_class(placed, total) when placed == total and total > 0, do: "text-success"
  defp progress_class(_placed, _total), do: "text-neutral text-sm"

  defp game_tap_button(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="assign"
      phx-value-game-id={@game.id}
      class="flex w-full min-h-11 items-center gap-2 rounded-box border border-base-300 p-2 text-left"
    >
      <span class="flex-1">{@game.name}</span>
      <span :if={@game.shelf} class="text-neutral text-sm">en {@game.shelf.name}</span>
    </button>
    """
  end

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
            <.button variant="secondary" phx-click="open-rename">Renombrar</.button>
            <.link navigate={~p"/admin/juegos"} class="text-sm text-neutral">
              ← Volver
            </.link>
          </:actions>
        </.header>

        <form id="assign-search" phx-change="search" class="w-full">
          <.input
            type="text"
            id="assign-search-input"
            name="q"
            value={@q}
            placeholder="Buscar por nombre"
            phx-debounce="300"
          />
        </form>

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

        <div :if={@q != ""} class="space-y-2">
          <h2 class="font-display text-xl">Resultados</h2>
          <p :if={@search_results == []} class="text-neutral text-sm">Sin resultados.</p>
          <.game_tap_button :for={game <- @search_results} game={game} />
        </div>

        <div :if={@q == ""} class="space-y-2">
          <h2 class="font-display text-xl">Sin ubicar ({length(@unplaced_games)})</h2>
          <p :if={@unplaced_games == []} class="text-neutral text-sm">
            Todos los juegos ya tienen un estante.
          </p>
          <.game_tap_button :for={game <- @unplaced_games} game={game} />
        </div>
      </div>

      <div :if={@rename_open} class="modal modal-open" role="dialog" aria-modal="true">
        <div class="modal-box">
          <h3 class="font-display text-xl">Renombrar estante</h3>
          <form id="rename-shelf-form" phx-submit="rename" class="space-y-2 py-4">
            <.input
              type="text"
              id="rename-shelf-name"
              name="name"
              value={@rename_input}
              label="Nombre del estante"
              errors={if @rename_error, do: [@rename_error], else: []}
            />
            <div class="modal-action">
              <button
                type="button"
                phx-click="cancel-rename"
                class="btn btn-outline btn-primary pk-btn-secondary"
              >
                Cancelar
              </button>
              <.button variant="primary">Guardar cambios</.button>
            </div>
          </form>
        </div>
      </div>

      <div :if={@toast} class="toast toast-bottom toast-center">
        <div
          role="status"
          class={["alert w-80 sm:w-96 text-wrap", @toast.kind == :error && "alert-error"]}
        >
          <span>{@toast.text}</span>
          <span aria-hidden="true">·</span>
          <.button
            :if={@toast.kind == :moved}
            variant="secondary"
            phx-click="undo-move"
            phx-value-game-id={@toast.game_id}
            phx-value-shelf-id={@toast.previous_shelf_id}
          >
            Deshacer
          </.button>
          <.button
            :if={@toast.kind == :error}
            variant="secondary"
            phx-click="assign"
            phx-value-game-id={@toast.game_id}
          >
            Reintentar
          </.button>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
