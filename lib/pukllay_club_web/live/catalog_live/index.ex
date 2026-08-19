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
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClubWeb.CarouselRow
  alias PukllayClubWeb.FilterDrawer
  alias PukllayClubWeb.GameCard
  alias PukllayClubWeb.GamePreview

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

  def handle_event("see-all", %{"row" => row}, socket) do
    selection =
      Map.merge(
        %{
          q: "",
          mechanics: [],
          themes: [],
          weight_bands: [],
          tags: [],
          players: nil,
          max_playtime: nil,
          min_age: nil,
          sort: :name_asc
        },
        see_all_selection(row)
      )

    socket =
      selection
      |> Enum.reduce(socket, fn {key, value}, acc -> assign(acc, key, value) end)
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

  # Maps a "see-all" row key to the filter selection that reproduces that
  # shelf's own query (see `PukllayClub.Catalog.list_carousel_rows/0`).
  # Literal string clauses with a final catch-all, matching the existing
  # `facet_assign_key/1`/`parse_sort/1` convention above — never build an
  # atom out of client input — so an unrecognised value leaves the socket
  # unchanged rather than creating a new atom from user input (T-01-37).
  defp see_all_selection("destacados_del_club"), do: %{tags: Enum.map(Vocabulary.editorial_tags(), & &1.tag)}

  defp see_all_selection("crea_conexiones"), do: %{tags: ["#CreaConexiones"]}
  defp see_all_selection("equipo_ganador"), do: %{tags: ["#EquipoGanador"]}
  defp see_all_selection("duelos_memorables"), do: %{tags: ["#DuelosMemorables"]}
  defp see_all_selection("descubre_el_hobby"), do: %{weight_bands: ["descubre_el_hobby"]}
  defp see_all_selection("ingenio_estratega"), do: %{weight_bands: ["ingenio_estratega"]}
  defp see_all_selection("nivel_experto"), do: %{weight_bands: ["nivel_experto"]}
  # `:year_desc` sorts by the game's own publication year, the closest
  # "newest first" option the main grid's sort control already exposes —
  # not `inserted_at` (what the shelf itself is ordered by), since adding
  # a club-acquisition-recency sort mode to the grid is out of this
  # plan's scope. See SUMMARY for the known limitation.
  defp see_all_selection("recientemente_anadidos"), do: %{sort: :year_desc}
  defp see_all_selection(_unrecognized), do: %{}

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

  # Ranks the curated row above the other 7 by colour (G-01-4) — never by a
  # fourth type size, per ui-design-system's 3-level cap.
  defp row_variant(:destacados_del_club), do: :hero
  defp row_variant(_key), do: :standard

  # One plain-Spanish line per D-09 row so all 8 shelves read as 8 distinct
  # things (G-01-4). Six of the eight reuse already-user-reviewed D-05/D-06
  # copy from Vocabulary; :destacados_del_club and :recientemente_anadidos
  # are newly authored here and flagged in the SUMMARY for review. Any
  # unmatched key degrades to a bare heading rather than crashing.
  defp row_subtitle(:crea_conexiones), do: editorial_tag_meaning("#CreaConexiones")
  defp row_subtitle(:equipo_ganador), do: editorial_tag_meaning("#EquipoGanador")
  defp row_subtitle(:duelos_memorables), do: editorial_tag_meaning("#DuelosMemorables")
  defp row_subtitle(:descubre_el_hobby), do: weight_band_descriptor("descubre_el_hobby")
  defp row_subtitle(:ingenio_estratega), do: weight_band_descriptor("ingenio_estratega")
  defp row_subtitle(:nivel_experto), do: weight_band_descriptor("nivel_experto")

  defp row_subtitle(:destacados_del_club), do: "La selección del club — los juegos que más recomendamos ahora mismo."

  defp row_subtitle(:recientemente_anadidos), do: "Las incorporaciones más nuevas a la ludoteca."

  defp row_subtitle(_unrecognized), do: nil

  defp editorial_tag_meaning(tag) do
    Vocabulary.editorial_tags()
    |> Enum.find(&(&1.tag == tag))
    |> case do
      %{meaning: meaning} -> meaning
      nil -> nil
    end
  end

  defp weight_band_descriptor(value) do
    case Vocabulary.weight_band(value) do
      %{descriptor: descriptor} -> descriptor
      nil -> nil
    end
  end

  # "El catálogo completo" is a false claim once filters narrow the result
  # set — the heading text depends on whether a filter is active, but the
  # header itself always renders (even on a zero-result view).
  defp main_grid_heading(assigns) do
    if filters_active?(assigns), do: "Resultados", else: "El catálogo completo"
  end

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
    <Layouts.app flash={@flash} fullbleed>
      <div class="pk-page space-y-6">
        <div class="mx-auto w-full max-w-7xl pk-gutter">
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
              variant={row_variant(row.key)}
              subtitle={row_subtitle(row.key)}
              see_all_row={to_string(row.key)}
            />
          <% end %>
        </div>

        <div :if={@load_error} class="mx-auto w-full max-w-7xl pk-gutter">
          <div class="alert alert-error">
            No pudimos cargar el catálogo en este momento. Intenta recargar la página en unos segundos.
          </div>
        </div>

        <div class="mx-auto w-full max-w-7xl pk-gutter space-y-1">
          <h2 class="font-display text-2xl">{main_grid_heading(assigns)}</h2>
          <p class="text-neutral text-sm">{result_count_text(@total)}</p>
        </div>

        <div :if={@total == 0 and not @load_error} class="mx-auto w-full max-w-7xl pk-gutter">
          <div class="bg-base-200 space-y-4 rounded-box p-8 text-center">
            <h2 class="font-display text-2xl">No encontramos juegos con esos filtros</h2>
            <p>
              Prueba a quitar algún filtro o ajustar tu búsqueda — seguro hay algo en nuestra colección que te va a gustar.
            </p>
            <button type="button" phx-click="clear-filters" class="btn btn-primary">
              Limpiar filtros
            </button>
          </div>
        </div>

        <div :if={@loading} class="mx-auto w-full max-w-7xl pk-gutter">
          <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            <CarouselRow.skeleton_card :for={n <- 1..@page_size} id={"grid-skeleton-#{n}"} />
          </div>
        </div>

        <div :if={not @loading} class="mx-auto w-full max-w-7xl pk-gutter">
          <div
            id="games"
            phx-update="stream"
            class={[
              "grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4",
              @total == 0 && "hidden"
            ]}
          >
            <GameCard.game_card :for={{id, game} <- @streams.games} id={id} game={game} />
          </div>
        </div>

        <div :if={@total > 0 and @offset < @total} class="mx-auto w-full max-w-7xl pk-gutter">
          <div class="flex justify-center">
            <button type="button" phx-click="load-more" class="btn btn-outline">Cargar más</button>
          </div>
        </div>

        <GamePreview.preview_host />
      </div>
    </Layouts.app>
    """
  end
end
