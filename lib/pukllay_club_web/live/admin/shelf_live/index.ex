defmodule PukllayClubWeb.Admin.ShelfLive.Index do
  @moduledoc """
  Estantes management + the Saturday pick/restore list, at
  `/admin/estantes` (D-10, D-15, UI-SPEC E5). Two views toggled by
  `?vista=` (parsed with literal clauses, T-01-37 convention — never
  `String.to_atom/1` on the client-supplied param):

  - the default card view: create a shelf, and reorder existing shelves
    with ↑/↓ (`Shelves.move_shelf/2`) — each row links to its own
    `Admin.ShelfLive.Assign` screen;
  - `?vista=lista`: every non-retired game grouped by shelf in walking
    order plus a final `Sin ubicar` group (`Shelves.pick_list/1`), with a
    debounced name filter that narrows games inside groups without
    hiding an empty group's own heading (D-15, UI-SPEC E5 zero-one-many).

  Renaming a shelf lives on `Admin.ShelfLive.Assign`'s own header, not
  here (B10 house rule — a short, bounded task doesn't need its own
  screen).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog.Shelves

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Estantes")
     |> assign(:name_input, "")
     |> assign(:name_error, nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(:vista, parse_vista(params["vista"]))
      |> assign(:q, params["q"] || "")
      |> load_data()

    {:noreply, socket}
  end

  defp parse_vista("lista"), do: :lista
  defp parse_vista(_unrecognized), do: :cards

  defp load_data(socket) do
    %{vista: vista, q: q} = socket.assigns
    groups = Shelves.pick_list(if vista == :lista, do: q)

    counts =
      groups
      |> Enum.filter(fn {key, _games} -> key != :unplaced end)
      |> Map.new(fn {shelf, games} -> {shelf.id, length(games)} end)

    socket
    |> assign(:shelves, Shelves.list_shelves())
    |> assign(:shelf_counts, counts)
    |> assign(:groups, groups)
  end

  @impl true
  def handle_event("create", %{"name" => name}, socket) do
    case Shelves.create_shelf(%{name: name}) do
      {:ok, _shelf} ->
        {:noreply, socket |> assign(:name_input, "") |> assign(:name_error, nil) |> load_data()}

      {:error, changeset} ->
        error = changeset.errors |> translate_errors(:name) |> List.first()
        {:noreply, socket |> assign(:name_input, name) |> assign(:name_error, error)}
    end
  end

  @impl true
  def handle_event("move-up", %{"shelf-id" => id}, socket), do: move(socket, id, :up)

  @impl true
  def handle_event("move-down", %{"shelf-id" => id}, socket), do: move(socket, id, :down)

  @impl true
  def handle_event("filter", %{"q" => q}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/estantes?#{%{"vista" => "lista", "q" => q}}")}
  end

  defp move(socket, id, direction) do
    case Integer.parse(id) do
      {int_id, ""} ->
        {:ok, _shelf} = int_id |> Shelves.get_shelf!() |> Shelves.move_shelf(direction)
        {:noreply, load_data(socket)}

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  defp group_title(:unplaced), do: "Sin ubicar"
  defp group_title(%{name: name}), do: name

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <.header>
          Estantes
          <:actions>
            <.link
              :if={@vista == :cards}
              patch={~p"/admin/estantes?vista=lista"}
              class="text-sm text-neutral"
            >
              Ver lista por estante
            </.link>
            <.link :if={@vista == :lista} patch={~p"/admin/estantes"} class="text-sm text-neutral">
              Ver estantes
            </.link>
          </:actions>
        </.header>

        <div :if={@vista == :cards} class="space-y-6">
          <p :if={@shelves == []} class="text-neutral text-sm">
            Todavía no creaste estantes.
          </p>

          <form id="create-shelf-form" phx-submit="create" class="flex flex-wrap items-end gap-3">
            <div class="flex-1 min-w-48">
              <.input
                type="text"
                id="create-shelf-name"
                name="name"
                value={@name_input}
                label="Nombre del estante"
                errors={if @name_error, do: [@name_error], else: []}
              />
            </div>
            <.button variant="primary">Crear estante</.button>
          </form>

          <ul :if={@shelves != []} class="space-y-2">
            <li
              :for={shelf <- @shelves}
              class="flex items-center gap-2 rounded-box border border-base-300 p-2"
            >
              <.link
                navigate={~p"/admin/estantes/#{shelf.id}/asignar"}
                class="flex-1 min-h-11 flex items-center gap-2"
              >
                <span>{shelf.name}</span>
                <span class="text-neutral text-sm">
                  {Map.get(@shelf_counts, shelf.id, 0)} juegos
                </span>
              </.link>
              <button
                type="button"
                phx-click="move-up"
                phx-value-shelf-id={shelf.id}
                aria-label={"Subir #{shelf.name}"}
                class="btn btn-ghost btn-square min-h-11 min-w-11"
              >
                <.icon name="hero-arrow-up" />
              </button>
              <button
                type="button"
                phx-click="move-down"
                phx-value-shelf-id={shelf.id}
                aria-label={"Bajar #{shelf.name}"}
                class="btn btn-ghost btn-square min-h-11 min-w-11"
              >
                <.icon name="hero-arrow-down" />
              </button>
            </li>
          </ul>
        </div>

        <div :if={@vista == :lista} class="space-y-6">
          <form id="pick-list-filter" phx-change="filter" class="w-full">
            <.input
              type="text"
              id="pick-list-filter-input"
              name="q"
              value={@q}
              placeholder="Buscar por nombre"
              phx-debounce="300"
            />
          </form>

          <div :for={{group, games} <- @groups} class="space-y-2">
            <h2 class="font-display text-xl">{group_title(group)}</h2>
            <p :if={games == []} class="text-neutral text-sm">Sin juegos.</p>
            <ul class="space-y-1">
              <li :for={game <- games} class="min-h-11 flex items-center px-2">{game.name}</li>
            </ul>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
