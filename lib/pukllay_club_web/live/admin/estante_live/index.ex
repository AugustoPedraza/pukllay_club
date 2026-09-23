defmodule PukllayClubWeb.Admin.EstanteLive.Index do
  @moduledoc """
  `/admin/estantes` (D-08, plan 01.8.2-13) — search-first, one job: find a
  box. This is the real screen the phase tracer (01.8.2-01) was standing
  in for; the tracer's `?estante=` picker is gone outright, replaced by
  D-08's search: idle shows only the prompt and the 48px field, focusing
  the empty field shows up to 3 `Últimas búsquedas` (this LiveView's own
  session state, never persisted), and typing shows suggestions via
  `Shelves.search_copies/1`.

  This task (Task 1 of 3) builds the idle state and the search dropdown
  only — picking a suggestion and the answered-state rail are plan
  01.8.2-13's own Task 2.

  Header: a 44px A3 Pendientes icon carrying D-19g's count badge
  (`Shelves.unplaced_copies/0`'s length — the SAME source the dashboard
  box reads, so the two counts can never disagree) followed by the
  Administrar estantes gear. Both navigate to routes plan 01.8.2-18
  creates — rendered as plain string `navigate` paths (not `~p`, which
  would fail to compile against a route that does not exist yet).

  This route lives inside the existing `live_session :require_staff`
  block (T-01.8.2-03) — a signed-out visitor is redirected before this
  module ever mounts. No `/admin/estantes/:id` route exists or is added
  here (D-08: an estante has no page of its own).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog.Shelves
  alias PukllayClubWeb.AdminComponents

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
  def handle_event("clear", _params, socket) do
    {:noreply,
     socket
     |> assign(:query, "")
     |> assign(:suggestions, [])}
  end

  defp pending_count, do: length(Shelves.unplaced_copies())

  defp pendientes_aria_label(0), do: "Pendientes"
  defp pendientes_aria_label(count), do: "Pendientes, #{count} pendientes"

  defp badge_text(count) when count > 99, do: "99+"
  defp badge_text(count), do: Integer.to_string(count)

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
      <div class="pk-estantes" data-raised={to_string(@selected_copy != nil)}>
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
              :if={@query != ""}
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
