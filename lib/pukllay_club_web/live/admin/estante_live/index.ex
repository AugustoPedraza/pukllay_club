defmodule PukllayClubWeb.Admin.EstanteLive.Index do
  @moduledoc """
  `/admin/estantes` — the phase tracer's read path (D-01/D-02/D-03/D-04,
  01.8.2-01): renders one estante's copies as a horizontally-scrollable
  rail of covers, in real left-to-right `position` order
  (`Shelves.copies_on_shelf/1`), each carrying an accessible name of the
  form `"{game name}, caja {position+1} de {count}"` (D-04: boxes are
  counted, not games).

  Deliberately minimal — this task proves the model end to end (a copy
  placed at a position renders at that position), not the full D-08
  Estantes design. No search, no estante dropdown, no "¿Dónde va?" sheet,
  no Pendientes page: plans 01.8.2-13, 01.8.2-16, and 01.8.2-18 expand
  this page. `?estante=` selects which estante to view (falls back to the
  first one in walking order), parsed as a plain integer — never
  `String.to_atom/1` on a client-supplied value — and validated against
  the currently-loaded estante list rather than trusted directly.

  Subscribes to the `"admin:estantes"` PubSub topic once connected
  (mirrors `Admin.GameLive.Index`'s `"admin:games"` subscription) and
  re-reads both the estante list and the selected estante's rail on
  every `{:estante_updated, _shelf_id}` broadcast — the id itself is
  unused, since any write on any estante could in principle affect what
  this page currently shows (an estante count, a copy that just left).

  This route lives inside the existing `live_session :require_staff`
  block (T-01.8.2-03) — a signed-out visitor is redirected before this
  module ever mounts.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog.Shelves

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PukllayClub.PubSub, "admin:estantes")
    end

    {:ok,
     socket
     |> assign(:page_title, "Estantes")
     |> assign(:estantes, Shelves.list_shelves())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, select_estante(socket, params["estante"])}
  end

  @impl true
  def handle_info({:estante_updated, _shelf_id}, socket) do
    current_id = socket.assigns[:selected] && socket.assigns.selected.id

    socket =
      socket
      |> assign(:estantes, Shelves.list_shelves())
      |> select_estante(current_id && Integer.to_string(current_id))

    {:noreply, socket}
  end

  defp select_estante(socket, requested_id) do
    estantes = socket.assigns.estantes
    selected = find_estante(estantes, parse_estante_id(requested_id)) || List.first(estantes)

    socket
    |> assign(:selected, selected)
    |> load_rail(selected)
  end

  defp find_estante(_estantes, nil), do: nil
  defp find_estante(estantes, id), do: Enum.find(estantes, &(&1.id == id))

  # Never `String.to_atom/1` on a client-supplied param (T-01-37
  # convention) — parsed as a plain integer and, either way, validated
  # against the already-loaded estante list by `find_estante/2` above
  # rather than trusted directly.
  defp parse_estante_id(nil), do: nil

  defp parse_estante_id(id) do
    case Integer.parse(id) do
      {int, ""} -> int
      _not_an_integer -> nil
    end
  end

  defp load_rail(socket, nil), do: assign(socket, :copies, [])
  defp load_rail(socket, shelf), do: assign(socket, :copies, Shelves.copies_on_shelf(shelf.id))

  # D-04: "caja N de M" counts boxes (copies), not games — a game with
  # more than one copy on the same estante gets one cover per copy.
  defp cover_alt(copy, index, count) do
    "#{copy.game.name}, caja #{index + 1} de #{count}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      bottom_collapse
      admin_chrome
      active_tab={:estantes}
    >
      <div class="mx-auto w-full max-w-4xl space-y-6">
        <.header>Estantes</.header>

        <div :if={@estantes == []} class="text-center py-12 space-y-2">
          <h2 class="font-display text-2xl">Todavía no hay estantes</h2>
          <p class="text-neutral text-sm">Creá el primer estante para empezar a ubicar juegos.</p>
        </div>

        <div :if={@selected} class="space-y-3">
          <div class="flex items-center gap-2">
            <.icon name="hero-archive-box" class="size-5 text-neutral" />
            <h2 class="font-display text-xl">{@selected.name}</h2>
          </div>

          <p :if={@copies == []} class="text-neutral text-sm">
            Este estante todavía no tiene juegos.
          </p>

          <div :if={@copies != []} class="pk-rail-wrap">
            <div class="pk-rail">
              <div
                :for={{copy, index} <- Enum.with_index(@copies)}
                id={"estante-copy-#{copy.id}"}
                class="w-24 shrink-0"
              >
                <div
                  role="img"
                  aria-label={cover_alt(copy, index, length(@copies))}
                  class="h-32 w-24 overflow-hidden rounded-box bg-base-200"
                >
                  <img
                    :if={copy.game.thumbnail_url}
                    src={copy.game.thumbnail_url}
                    alt=""
                    class="h-full w-full object-cover"
                  />
                  <div
                    :if={!copy.game.thumbnail_url}
                    class="flex h-full w-full items-center justify-center text-primary"
                  >
                    <.icon name="hero-puzzle-piece" class="size-8" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
