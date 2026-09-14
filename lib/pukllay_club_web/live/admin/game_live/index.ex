defmodule PukllayClubWeb.Admin.GameLive.Index do
  @moduledoc """
  Juegos list at `/admin/juegos` (D-09 Task 2, UI-SPEC E1): every game
  regardless of status, filterable by lifecycle state and searchable by
  name, paged via `Cargar más` over a `phx-update="stream"` table — never
  numbered pagination (ux-patterns B7).

  `estado` is parsed with literal-clause dispatch (`parse_estado/1`) and a
  `nil` catch-all for anything unrecognized — never an atom built from
  the client-supplied param (T-01-37 convention, same shape as
  `PukllayClub.Catalog`'s own `row_query/1`).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog

  @page_size 50

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Juegos")
     |> assign(:loading, not connected?(socket))
     |> assign(:status, nil)
     |> assign(:q, "")
     |> assign(:offset, 0)
     |> assign(:total, 0)
     |> assign(:bgg_id_input, "")
     |> assign(:bgg_id_error, nil)
     |> stream(:games, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(:status, parse_estado(params["estado"]))
      |> assign(:q, params["q"] || "")
      |> load_games()

    {:noreply, socket}
  end

  defp parse_estado("borrador"), do: :draft
  defp parse_estado("publicado"), do: :published
  defp parse_estado("retirado"), do: :retired
  defp parse_estado(_unrecognized), do: nil

  defp load_games(socket) do
    if socket.assigns.loading do
      socket
    else
      %{status: status, q: q} = socket.assigns
      games = Catalog.list_admin_games(status: status, q: q, limit: @page_size)
      total = Catalog.count_admin_games(status: status, q: q)

      socket
      |> assign(:offset, length(games))
      |> assign(:total, total)
      |> stream(:games, games, reset: true)
    end
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, push_patch(socket, to: filter_path(socket.assigns.status, q))}
  end

  @impl true
  def handle_event("add-game", %{"bgg_id" => bgg_id}, socket) do
    case Catalog.add_game_from_bgg(bgg_id) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> assign(:bgg_id_input, "")
         |> assign(:bgg_id_error, nil)
         |> put_flash(:info, "Juego agregado como borrador.")
         |> push_patch(to: filter_path(:draft, ""))}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:bgg_id_input, bgg_id)
         |> assign(:bgg_id_error, "Pegá un número de BGG o el link del juego.")}
    end
  end

  @impl true
  def handle_event("load-more", _params, socket) do
    %{status: status, q: q, offset: offset} = socket.assigns
    games = Catalog.list_admin_games(status: status, q: q, limit: @page_size, offset: offset)

    {:noreply,
     socket
     |> assign(:offset, offset + length(games))
     |> stream(:games, games, at: -1)}
  end

  defp filter_path(status, q) do
    params =
      %{}
      |> maybe_put_param("estado", estado_param(status))
      |> maybe_put_param("q", (q != "" && q) || nil)

    ~p"/admin/juegos?#{params}"
  end

  defp estado_param(:draft), do: "borrador"
  defp estado_param(:published), do: "publicado"
  defp estado_param(:retired), do: "retirado"
  defp estado_param(nil), do: nil

  defp maybe_put_param(map, _key, nil), do: map
  defp maybe_put_param(map, key, value), do: Map.put(map, key, value)

  defp status_badge_class(:draft), do: "badge badge-warning"
  defp status_badge_class(:published), do: "badge badge-success"
  defp status_badge_class(:retired), do: "badge badge-neutral"

  defp status_badge_label(:draft), do: "Borrador"
  defp status_badge_label(:published), do: "Publicado"
  defp status_badge_label(:retired), do: "Retirado"

  defp filter_link_class(true) do
    "min-h-11 inline-flex items-center px-3 rounded-box bg-primary text-primary-content font-semibold"
  end

  defp filter_link_class(false) do
    "min-h-11 inline-flex items-center px-3 rounded-box text-neutral hover:bg-base-200"
  end

  defp empty_heading(:draft), do: "Ningún juego en borrador"
  defp empty_heading(_status), do: "No hay juegos con este filtro."

  defp empty_body(:draft), do: "Agregá un juego pegando su ID o link de BGG."
  defp empty_body(_status), do: "Probá con otro filtro o con otra búsqueda."

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto w-full max-w-4xl space-y-6">
        <.header>Juegos</.header>

        <form
          id="add-game-form"
          phx-submit="add-game"
          class="rounded-box border border-base-300 bg-base-200 p-4 flex flex-wrap items-end gap-3"
        >
          <div class="flex-1 min-w-48">
            <.input
              type="text"
              id="add-game-bgg-id"
              name="bgg_id"
              value={@bgg_id_input}
              label="ID o link de BGG"
              errors={if @bgg_id_error, do: [@bgg_id_error], else: []}
            />
          </div>
          <.button variant="primary">Agregar juego</.button>
        </form>

        <div class="flex flex-wrap items-center gap-4">
          <nav class="flex flex-wrap gap-1" aria-label="Filtrar por estado">
            <.link patch={filter_path(nil, @q)} class={filter_link_class(@status == nil)}>
              Todos
            </.link>
            <.link patch={filter_path(:draft, @q)} class={filter_link_class(@status == :draft)}>
              Borradores
            </.link>
            <.link
              patch={filter_path(:published, @q)}
              class={filter_link_class(@status == :published)}
            >
              Publicados
            </.link>
            <.link patch={filter_path(:retired, @q)} class={filter_link_class(@status == :retired)}>
              Retirados
            </.link>
          </nav>

          <form id="admin-games-search" phx-change="search" class="flex-1 min-w-40">
            <.input
              type="text"
              id="admin-games-search-input"
              name="q"
              value={@q}
              placeholder="Buscar por nombre"
              phx-debounce="300"
            />
          </form>
        </div>

        <div :if={@loading} class="space-y-2">
          <div :for={_n <- 1..8} class="skeleton h-10 w-full"></div>
        </div>

        <div :if={!@loading and @total == 0}>
          <div class="text-center py-12 space-y-2">
            <h2 class="font-display text-2xl">{empty_heading(@status)}</h2>
            <p class="text-neutral text-sm">{empty_body(@status)}</p>
          </div>
        </div>

        <div :if={!@loading and @total > 0} class="space-y-4">
          <.table
            id="admin-games"
            rows={@streams.games}
            row_click={fn {_id, game} -> JS.navigate(~p"/admin/juegos/#{game.id}/editar") end}
          >
            <:col :let={{_id, game}} label="Nombre">
              <span class="truncate">{game.name}</span>
            </:col>
            <:col :let={{_id, game}} label="Estado">
              <span class={status_badge_class(game.status)}>{status_badge_label(game.status)}</span>
            </:col>
          </.table>

          <div :if={@offset < @total} class="flex justify-center">
            <.button phx-click="load-more" variant="secondary">Cargar más</.button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
