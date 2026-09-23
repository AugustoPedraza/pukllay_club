defmodule PukllayClubWeb.Admin.EstanteLive.Index do
  @moduledoc """
  `/admin/estantes` (D-08, plan 01.8.2-13) — search-first, one job: find a
  box. This is the real screen the phase tracer (01.8.2-01) was standing
  in for; the tracer's `?estante=` picker is gone outright, replaced by
  D-08's search: idle shows only the prompt and the 48px field, focusing
  the empty field shows up to 3 `Últimas búsquedas` (this LiveView's own
  session state, never persisted), typing shows suggestions via
  `Shelves.search_copies/1`, and picking one raises the page and opens the
  picked copy's estante as a rail (`Shelves.copies_on_shelf/1`) with that
  copy lifted.

  A copy with no spot does not render an empty rail — it renders a
  placeholder handoff to the «¿Dónde va?» sheet, which plan 01.8.2-16
  owns; this plan only wires the event (see `handle_event("open-donde-va",
  ...)`) and the placeholder markup, both named at their call sites.

  Header: a 44px A3 Pendientes icon carrying D-19g's count badge
  (`Shelves.unplaced_copies/0`'s length — the SAME source the dashboard
  box reads, so the two counts can never disagree) followed by the
  Administrar estantes gear. Both navigate to routes plan 01.8.2-18
  creates — rendered as plain string `navigate` paths (not `~p`, which
  would fail to compile against a route that does not exist yet).

  Live-update handling over `"admin:estantes"` broadcasts (D-11) is this
  plan's own Task 3.

  This route lives inside the existing `live_session :require_staff`
  block (T-01.8.2-03) — a signed-out visitor is redirected before this
  module ever mounts. No `/admin/estantes/:id` route exists or is added
  here (D-08: an estante has no page of its own).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog.Shelves
  alias PukllayClubWeb.AdminComponents

  # D-08: "Últimas búsquedas (3)" — a per-session, in-memory recency list,
  # never written to the database (this is not a history feature).
  @max_recent 3

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PukllayClub.PubSub, "admin:estantes")
    end

    {:ok,
     socket
     |> assign(:page_title, "Estantes")
     |> assign(:query, "")
     |> assign(:suggestions, [])
     |> assign(:recent_searches, [])
     |> assign(:selected_copy, nil)
     |> assign(:copies, [])
     |> assign(:copy_counts, %{})
     |> assign(:pending_count, pending_count())}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    query = String.slice(q, 0, 120)

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:suggestions, Shelves.search_copies(query))}
  end

  @impl true
  def handle_event("pick-copy", %{"copy-id" => raw_id}, socket) do
    case parse_id(raw_id) do
      nil -> {:noreply, socket}
      id -> {:noreply, select_copy(socket, id)}
    end
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply,
     socket
     |> assign(:query, "")
     |> assign(:suggestions, [])
     |> assign(:selected_copy, nil)
     |> assign(:copies, [])
     |> assign(:copy_counts, %{})}
  end

  @impl true
  def handle_event("open-donde-va", _params, socket) do
    # Placeholder handoff (plan 01.8.2-13's own scope: "wire the event,
    # leave the sheet to plan 01.8.2-16"). The full-height «¿Dónde va?»
    # sheet that would actually open here is plan 01.8.2-16's build; this
    # clause exists so the event exists and does not crash the LiveView
    # when the placeholder button (`#estantes-open-donde-va`) is tapped —
    # it is a documented no-op until that plan lands.
    {:noreply, socket}
  end

  defp select_copy(socket, id) do
    copy = Shelves.get_copy!(id)

    socket
    |> select_copy_struct(copy)
    |> update(:recent_searches, &push_recent_list(&1, copy))
  rescue
    Ecto.NoResultsError -> socket
  end

  defp select_copy_struct(socket, copy) do
    socket
    |> assign(:selected_copy, copy)
    |> assign(:query, copy.game.name)
    |> assign(:suggestions, [])
    |> load_rail(copy)
  end

  defp load_rail(socket, %{shelf_id: nil}) do
    socket
    |> assign(:copies, [])
    |> assign(:copy_counts, %{})
  end

  defp load_rail(socket, %{shelf_id: shelf_id}) do
    copies = Shelves.copies_on_shelf(shelf_id)
    game_ids = Enum.map(copies, & &1.game_id)

    socket
    |> assign(:copies, copies)
    |> assign(:copy_counts, Shelves.counts_for_games(game_ids))
  end

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> int
      _not_an_integer -> nil
    end
  end

  defp parse_id(_non_binary), do: nil

  defp pending_count, do: length(Shelves.unplaced_copies())

  defp pendientes_aria_label(0), do: "Pendientes"
  defp pendientes_aria_label(count), do: "Pendientes, #{count} pendientes"

  defp badge_text(count) when count > 99, do: "99+"
  defp badge_text(count), do: Integer.to_string(count)

  # D-03: "copia N de M" (N = the copy's own stable `number`, M = every
  # copy of that game, on or off any estante) appears only when the game
  # has more than one copy; "caja N de M" (D-04) always counts boxes on
  # THIS estante, from the real `position` order — never the render index
  # standing in for either number.
  defp cover_alt(copy, index, total_on_shelf, copy_counts) do
    caja = "caja #{index + 1} de #{total_on_shelf}"
    total_for_game = Map.get(copy_counts, copy.game_id, 1)

    if total_for_game > 1 do
      "#{copy.game.name}, copia #{copy.number} de #{total_for_game}, #{caja}"
    else
      "#{copy.game.name}, #{caja}"
    end
  end

  defp push_recent_list(recent, copy) do
    Enum.take([copy | Enum.reject(recent, &(&1.id == copy.id))], @max_recent)
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
      <div
        id="estantes-page"
        phx-hook="AdminRail"
        class="pk-estantes"
        data-raised={to_string(@selected_copy != nil)}
      >
        <header class="pk-estantes-header">
          <h1 class="pk-admin-page-title">Estantes</h1>
          <div class="pk-estantes-header-actions">
            <span class="pk-estantes-icon-badge">
              <AdminComponents.action
                anatomy="a3"
                role="terciaria"
                aria-label={pendientes_aria_label(@pending_count)}
                navigate="/admin/estantes/pendientes"
              >
                <.icon name="hero-inbox" class="size-5" />
              </AdminComponents.action>
              <span :if={@pending_count > 0} class="pk-estantes-icon-badge__count" aria-hidden="true">
                {badge_text(@pending_count)}
              </span>
            </span>
            <AdminComponents.action
              anatomy="a3"
              role="terciaria"
              aria-label="Administrar estantes"
              navigate="/admin/estantes/administrar"
            >
              <.icon name="hero-cog-6-tooth" class="size-5" />
            </AdminComponents.action>
          </div>
        </header>

        <div :if={is_nil(@selected_copy)} class="pk-estantes-hero">
          <p class="pk-estantes-prompt">¿Qué juego buscás?</p>
        </div>

        <div id="estantes-search-wrap" class="pk-estantes-search-wrap">
          <form id="estantes-search-form" phx-change="search" class="pk-estantes-search">
            <input
              type="text"
              id="estantes-search-input"
              name="q"
              value={@query}
              placeholder="Buscá un juego"
              aria-label="Buscá un juego"
              autocomplete="off"
              phx-debounce="200"
              onfocus="this.select()"
            />
            <button
              :if={@query != "" or @selected_copy}
              type="button"
              class="pk-estantes-search__clear"
              aria-label="Limpiar búsqueda"
              phx-click="clear"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>

            <div class="pk-estantes-dropdown" id="estantes-dropdown">
              <div :if={@query != "" and @suggestions != []} id="estantes-suggestions">
                <.suggestion_row :for={copy <- @suggestions} id={"suggestion-#{copy.id}"} copy={copy} />
              </div>

              <div :if={@query != "" and @suggestions == []} class="pk-estantes-no-match">
                <p class="pk-estantes-no-match__hint">Ningún juego se llama así.</p>
                <AdminComponents.list_row
                  id="estantes-create-row"
                  name={"Crear «#{@query}»"}
                  meta="Agregarlo al catálogo"
                  navigate={~p"/admin/juegos?nombre=#{@query}"}
                  opens_page
                />
              </div>

              <div :if={@query == "" and @recent_searches != []} id="estantes-recent">
                <AdminComponents.list_section_label>
                  Últimas búsquedas
                </AdminComponents.list_section_label>
                <.suggestion_row
                  :for={copy <- @recent_searches}
                  id={"recent-#{copy.id}"}
                  copy={copy}
                />
              </div>

              <p :if={@query == "" and @recent_searches == []} class="pk-estantes-no-recent">
                Todavía no buscaste ningún juego.
              </p>
            </div>
          </form>
        </div>

        <div :if={is_nil(@selected_copy)} class="pk-estantes-spacer-bottom"></div>

        <div :if={@selected_copy} class="pk-estantes-answer">
          <div :if={@selected_copy.shelf} class="pk-estantes-estante-context">
            <.icon name="hero-archive-box" class="size-4" />
            <span>{@selected_copy.shelf.name}</span>
          </div>

          <div :if={@selected_copy.shelf} class="pk-rail-wrap">
            <div class="pk-rail" id="estantes-rail">
              <div
                :for={{copy, index} <- Enum.with_index(@copies)}
                id={"estante-copy-#{copy.id}"}
                class={[
                  "pk-poster-card",
                  "pk-estantes-cover",
                  copy.id == @selected_copy.id && "pk-estantes-cover--lifted"
                ]}
                data-pk-rail-selected={to_string(copy.id == @selected_copy.id)}
              >
                <div
                  role="img"
                  aria-label={cover_alt(copy, index, length(@copies), @copy_counts)}
                  class="pk-estantes-cover__art"
                >
                  <img
                    :if={copy.game.thumbnail_url}
                    src={copy.game.thumbnail_url}
                    alt=""
                    class="pk-estantes-cover__img"
                  />
                  <div :if={!copy.game.thumbnail_url} class="pk-estantes-cover__fallback">
                    <.icon name="hero-puzzle-piece" class="size-8" />
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div
            :if={is_nil(@selected_copy.shelf)}
            class="pk-estantes-needs-placement"
            id="estantes-needs-placement"
          >
            <p>«{@selected_copy.game.name}» no tiene lugar todavía.</p>
            <%!-- Placeholder for the «¿Dónde va?» entry point (D-00c) —
            plan 01.8.2-16 replaces this button with the real full-height
            sheet; the event it dispatches already exists
            (`handle_event("open-donde-va", ...)` above). --%>
            <AdminComponents.action
              id="estantes-open-donde-va"
              anatomy="a1"
              role="principal"
              phx-click="open-donde-va"
            >
              Elegir dónde va
            </AdminComponents.action>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :id, :string, required: true
  attr :copy, :any, required: true

  defp suggestion_row(assigns) do
    ~H"""
    <AdminComponents.list_row
      id={@id}
      cover={@copy.game.thumbnail_url}
      name={@copy.game.name}
      phx-click="pick-copy"
      phx-value-copy-id={@copy.id}
    >
      <:trailing>
        <span :if={@copy.shelf} class="pk-estantes-row-meta">{@copy.shelf.name}</span>
        <AdminComponents.status_dot :if={is_nil(@copy.shelf_id)} status={:sin_lugar} />
      </:trailing>
    </AdminComponents.list_row>
    """
  end
end
