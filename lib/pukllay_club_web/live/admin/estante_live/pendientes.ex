defmodule PukllayClubWeb.Admin.EstanteLive.Pendientes do
  @moduledoc """
  `/admin/estantes/pendientes` (D-08, D-19g, plan 01.8.2-18) — the work
  queues behind Estantes' header badge, on their own page so the
  Estantes screen itself keeps its one job (search a box, D-19j).

  Two sections, both ALWAYS rendered — a heading with its own count, one
  hint line, then every row:

    * **Afuera** — Phase 4 checkout data. The section exists empty
      until then, by decision: this is a permanent placeholder, not a
      loading or error state, and must never be removed for being
      empty (D-08).
    * **Sin ubicar** — `Shelves.unplaced_copies/0`, the SAME source the
      Estantes header badge, the dashboard box and the tab-bar badge
      all read, so this page's own count can never disagree with any
      of them. Zero rows here is the honest success state ("every game
      has a spot"), not a defect.

  A row (either section) navigates to `/admin/estantes?copy=<id>` — the
  literal query param `EstanteLive.Index` reads in its own `mount/3` and
  feeds straight into `select_copy_struct/2`, the exact function a
  suggestion-row tap there already uses. That single mechanism gives
  both cases their required behaviour for free: a Sin ubicar copy (its
  own `shelf_id` is `nil`) opens «¿Dónde va?» immediately; an Afuera
  copy (once Phase 4 exists) lands on its estante's rail with itself
  lifted. `copy_target/1` below is the one place that URL is built, so
  both row renderers (and any future one) stay wired to the identical
  path.

  Subscribes to `"admin:estantes"` (D-11) and reloads the Sin ubicar
  count/list on every broadcast — Afuera has no write path yet, so
  nothing there needs to react to this topic.

  Lives inside the existing `live_session :require_staff` block — a
  signed-out visitor is redirected before this module ever mounts.
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
     |> assign(:page_title, "Pendientes")
     |> load_unplaced()}
  end

  defp load_unplaced(socket) do
    assign(socket, :unplaced, Shelves.unplaced_copies())
  end

  @impl true
  def handle_info({:estante_updated, _shelf_id}, socket) do
    {:noreply, load_unplaced(socket)}
  end

  # `EstanteLive.Index`'s own `?copy=<id>` handling — one URL-building
  # function shared by every row this page renders, whichever queue it
  # comes from.
  defp copy_target(copy), do: ~p"/admin/estantes?copy=#{copy.id}"

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
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <AdminComponents.back_row to={~p"/admin/estantes"} label="Estantes" />
        <h1 class="pk-admin-page-title">Pendientes</h1>

        <section id="pendientes-afuera" class="pk-admin-pendientes-queue">
          <AdminComponents.list_section_label>Afuera · 0</AdminComponents.list_section_label>
          <p class="pk-admin-empty-note">Volvieron de una mesa: tocá uno para ver dónde va.</p>
          <%!-- Phase 4 brings the real checkout data this section lists;
          until then it always renders empty (D-08) — never removed for
          being empty, and never a loading/error state. --%>
          <p class="pk-admin-empty-note">Todavía no hay juegos afuera.</p>
        </section>

        <section id="pendientes-sin-ubicar" class="pk-admin-pendientes-queue">
          <AdminComponents.list_section_label>
            Sin ubicar · {length(@unplaced)}
          </AdminComponents.list_section_label>
          <p class="pk-admin-empty-note">Todavía no tienen lugar: tocá uno para ubicarlo.</p>

          <p :if={@unplaced == []} class="pk-admin-empty-note">
            Todos los juegos tienen lugar.
          </p>

          <div :if={@unplaced != []} id="pendientes-sin-ubicar-rows">
            <AdminComponents.list_row
              :for={copy <- @unplaced}
              id={"pendientes-sin-ubicar-#{copy.id}"}
              cover={copy.game.thumbnail_url}
              name={copy.game.name}
              navigate={copy_target(copy)}
            />
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
