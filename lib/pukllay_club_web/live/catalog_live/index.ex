defmodule PukllayClubWeb.CatalogLive.Index do
  @moduledoc """
  Public browse entry point at `/` (CATALOG-01, CATALOG-02, CATALOG-03,
  CATALOG-04, CATALOG-08). Fully unauthenticated — no auth plug, no
  `current_scope` requirement, the `:browser` pipeline is reused
  unmodified. Reads exclusively through `PukllayClub.Catalog`, never
  `Repo` directly.

  Filter state (`:q`, `:mechanics`, `:themes`, `:weight_bands`, `:tags`,
  `:players`, `:max_playtime`, `:min_age`, `:sort`, `:offset`, `:total`)
  lives in assigns. Every filter-changing event funnels through
  `apply_filters/1` — the one place that decides pagination-reset
  semantics (D-12): it recomputes results, resets `:offset` to the first
  page, sets `:total`, and resets the `:games` stream. `"load-more"` is
  the only event that appends instead (01-RESEARCH.md Pattern 4).

  Catalog reads are wrapped in `apply_filters/1`'s `rescue` so a query
  failure (e.g. a crafted scalar value Postgres rejects) renders the
  UI-SPEC error banner instead of crashing the LiveView (T-01-24).

  `:loading` is true only for the very first, *disconnected* static render
  (`connected?(socket) == false`) — the standard LiveView two-phase mount
  trick: the disconnected render paints instantly with skeleton
  placeholders (no DB round-trip on that pass), then the connected
  websocket mount replaces it with real carousel/grid data. It is set once
  in `mount/3` and never toggled again by any `handle_event`.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog
  alias PukllayClubWeb.CarouselRow
  alias PukllayClubWeb.FilterDrawer
  alias PukllayClubWeb.GameCard

  @page_size 24
  @skeleton_carousel_rows 8

  @impl true
  def mount(_params, _session, socket) do
    loading? = not connected?(socket)

    socket =
      socket
      |> assign(:page_title, "Catálogo")
      |> assign(:q, "")
      |> assign(:mechanics, [])
      |> assign(:themes, [])
      |> assign(:weight_bands, [])
      |> assign(:tags, [])
      |> assign(:players, nil)
      |> assign(:max_playtime, nil)
      |> assign(:min_age, nil)
      |> assign(:sort, :name_asc)
      |> assign(:loading, loading?)
      |> assign(:page_size, @page_size)
      |> assign(:skeleton_carousel_rows, @skeleton_carousel_rows)
      |> assign(:facet_options, if(loading?, do: empty_facet_options(), else: Catalog.facet_options()))
      |> assign(:carousel_rows, if(loading?, do: [], else: Catalog.list_carousel_rows()))

    socket =
      if loading? do
        socket
        |> assign(:offset, 0)
        |> assign(:total, 0)
        |> assign(:load_error, false)
        |> stream(:games, [])
      else
        apply_filters(socket)
      end

    {:ok, socket}
  end

  defp empty_facet_options, do: %{mechanics: [], themes: [], weight_bands: [], editorial_tags: []}

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(:q, q) |> apply_filters()}
  end

  def handle_event("toggle-facet", %{"facet" => facet, "value" => value}, socket) do
    case facet_assign_key(facet) do
      nil ->
        {:noreply, socket}

      key ->
        current = Map.get(socket.assigns, key, [])
        updated = if value in current, do: List.delete(current, value), else: [value | current]

        {:noreply, socket |> assign(key, updated) |> apply_filters()}
    end
  end

  def handle_event("set-scalar", params, socket) do
    socket =
      socket
      |> assign(:players, parse_int(params["players"]))
      |> assign(:max_playtime, parse_int(params["max_playtime"]))
      |> assign(:min_age, parse_int(params["min_age"]))
      |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("sort", %{"sort" => sort}, socket) do
    {:noreply, socket |> assign(:sort, parse_sort(sort)) |> apply_filters()}
  end

  def handle_event("clear-filters", _params, socket) do
    socket =
      socket
      |> assign(:q, "")
      |> assign(:mechanics, [])
      |> assign(:themes, [])
      |> assign(:weight_bands, [])
      |> assign(:tags, [])
      |> assign(:players, nil)
      |> assign(:max_playtime, nil)
      |> assign(:min_age, nil)
      |> assign(:sort, :name_asc)
      |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("load-more", _params, socket) do
    opts = socket.assigns |> filter_opts() |> Map.put(:offset, socket.assigns.offset)

    case safe_filter_games(opts) do
      {:ok, games} ->
        {:noreply,
         socket
         |> assign(:offset, socket.assigns.offset + @page_size)
         |> stream(:games, games, at: -1)}

      :error ->
        {:noreply, assign(socket, :load_error, true)}
    end
  end

  defp facet_assign_key("mechanics"), do: :mechanics
  defp facet_assign_key("themes"), do: :themes
  defp facet_assign_key("weight_bands"), do: :weight_bands
  defp facet_assign_key("tags"), do: :tags
  defp facet_assign_key(_unrecognized), do: nil

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(str) do
    case Integer.parse(str) do
      {n, _rest} -> n
      :error -> nil
    end
  end

  defp parse_sort("name_asc"), do: :name_asc
  defp parse_sort("playtime_asc"), do: :playtime_asc
  defp parse_sort("playtime_desc"), do: :playtime_desc
  defp parse_sort("complexity_asc"), do: :complexity_asc
  defp parse_sort("complexity_desc"), do: :complexity_desc
  defp parse_sort("year_desc"), do: :year_desc
  defp parse_sort(_unrecognized), do: :name_asc

  defp filter_opts(assigns) do
    %{
      q: assigns.q,
      mechanics: assigns.mechanics,
      themes: assigns.themes,
      weight_bands: assigns.weight_bands,
      tags: assigns.tags,
      players: assigns.players,
      max_playtime: assigns.max_playtime,
      min_age: assigns.min_age,
      sort: assigns.sort
    }
  end

  defp apply_filters(socket) do
    opts = socket.assigns |> filter_opts() |> Map.put(:offset, 0) |> Map.put(:limit, @page_size)

    case safe_filter_games(opts) do
      {:ok, games} ->
        socket
        |> assign(:offset, @page_size)
        |> assign(:total, Catalog.count_games(opts))
        |> assign(:load_error, false)
        |> stream(:games, games, reset: true)

      :error ->
        socket
        |> assign(:offset, 0)
        |> assign(:total, 0)
        |> assign(:load_error, true)
        |> stream(:games, [], reset: true)
    end
  end

  defp safe_filter_games(opts) do
    {:ok, Catalog.filter_games(opts)}
  rescue
    _error -> :error
  end

  defp result_count_text(1), do: "1 juego encontrado"
  defp result_count_text(n), do: "#{n} juegos encontrados"

  # A filtered view shows one authoritative result set — the curated
  # carousel rows step aside rather than competing with it (Task 3 action
  # text).
  defp filters_active?(assigns) do
    assigns.q not in [nil, ""] or
      assigns.mechanics != [] or
      assigns.themes != [] or
      assigns.weight_bands != [] or
      assigns.tags != [] or
      not is_nil(assigns.players) or
      not is_nil(assigns.max_playtime) or
      not is_nil(assigns.min_age)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-7xl space-y-6 px-4 py-6 sm:px-6 lg:px-8">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <form phx-change="search" id="catalog-search-form" class="flex-1">
            <.input
              type="text"
              name="q"
              value={@q}
              placeholder="Busca por título, autor o editorial…"
              phx-debounce="300"
            />
          </form>

          <div class="flex items-center gap-4">
            <FilterDrawer.filter_drawer
              id="filter-drawer"
              facet_options={@facet_options}
              mechanics={@mechanics}
              themes={@themes}
              weight_bands={@weight_bands}
              tags={@tags}
              players={@players}
              max_playtime={@max_playtime}
              min_age={@min_age}
            />

            <select
              name="sort"
              phx-change="sort"
              class="select select-bordered focus:outline-hidden focus-within:outline-hidden"
            >
              <option value="name_asc" selected={@sort == :name_asc}>Nombre</option>
              <option value="playtime_asc" selected={@sort == :playtime_asc}>
                Duración: menor a mayor
              </option>
              <option value="playtime_desc" selected={@sort == :playtime_desc}>
                Duración: mayor a menor
              </option>
              <option value="complexity_asc" selected={@sort == :complexity_asc}>
                Complejidad: menor a mayor
              </option>
              <option value="complexity_desc" selected={@sort == :complexity_desc}>
                Complejidad: mayor a menor
              </option>
              <option value="year_desc" selected={@sort == :year_desc}>Más recientes</option>
            </select>
          </div>
        </div>

        <div :if={not filters_active?(assigns)} id="carousel-rows" class="space-y-8">
          <%= if @loading do %>
            <CarouselRow.skeleton_row
              :for={n <- 1..@skeleton_carousel_rows}
              id={"carousel-skeleton-#{n}"}
            />
          <% else %>
            <CarouselRow.carousel_row
              :for={row <- @carousel_rows}
              id={"carousel-#{row.key}"}
              title={row.title}
              games={row.games}
            />
          <% end %>
        </div>

        <div :if={@load_error} class="alert alert-error">
          No pudimos cargar el catálogo en este momento. Intenta recargar la página en unos segundos.
        </div>

        <p class="text-neutral text-sm">{result_count_text(@total)}</p>

        <div
          :if={@total == 0 and not @load_error}
          class="bg-base-200 space-y-4 rounded-box p-8 text-center"
        >
          <h2 class="font-display text-2xl">No encontramos juegos con esos filtros</h2>
          <p>
            Prueba a quitar algún filtro o ajustar tu búsqueda — seguro hay algo en nuestra colección que te va a gustar.
          </p>
          <button type="button" phx-click="clear-filters" class="btn btn-primary">
            Limpiar filtros
          </button>
        </div>

        <div :if={@loading} class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          <CarouselRow.skeleton_card :for={n <- 1..@page_size} id={"grid-skeleton-#{n}"} />
        </div>

        <div
          :if={not @loading}
          id="games"
          phx-update="stream"
          class={[
            "grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4",
            @total == 0 && "hidden"
          ]}
        >
          <GameCard.game_card :for={{id, game} <- @streams.games} id={id} game={game} />
        </div>

        <div :if={@total > 0 and @offset < @total} class="flex justify-center">
          <button type="button" phx-click="load-more" class="btn btn-outline">Cargar más</button>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
