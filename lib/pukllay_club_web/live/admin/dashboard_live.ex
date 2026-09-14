defmodule PukllayClubWeb.Admin.DashboardLive do
  @moduledoc """
  The `/admin` task dashboard shell (D-35, UI-SPEC E10).

  Mobile-first: a single-column card grid (`grid-cols-1 sm:grid-cols-2`)
  with no filled primary button on the page itself. `#admin-cards`' D-35
  order is Juegos, Estantes, Secciones, Revisar niveles, Staff — plan
  01.8.1-05 added Juegos, 01.8.1-07 appended Staff, 01.8.1-09 inserted
  Estantes second, 01.8.1-12 inserted Secciones third (no pending-work
  badge — a section always has *something* to curate, there's no "N left"
  count that makes sense here), and this plan (01.8.1-13) inserts Revisar
  niveles fourth, completing the fixed order.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Accounts.User
  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.BandAudit
  alias PukllayClub.Catalog.Shelves

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <.header>Panel</.header>
        <div id="admin-cards" class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <.link
            navigate={~p"/admin/juegos"}
            class="rounded-box bg-base-200 p-4 min-h-11 flex items-center justify-between gap-2"
          >
            <span class="font-display text-xl">Juegos</span>
            <span :if={@draft_count > 0} class="badge badge-warning">
              {@draft_count} borradores
            </span>
          </.link>
          <.link
            navigate={~p"/admin/estantes"}
            class="rounded-box bg-base-200 p-4 min-h-11 flex items-center justify-between gap-2"
          >
            <span class="font-display text-xl">Estantes</span>
            <span :if={@placed < @total} class="badge badge-warning">
              {@placed}/{@total} ubicados
            </span>
          </.link>
          <.link
            navigate={~p"/admin/secciones"}
            class="rounded-box bg-base-200 p-4 min-h-11 flex items-center justify-between gap-2"
          >
            <span class="font-display text-xl">Secciones</span>
          </.link>
          <.link
            navigate={~p"/admin/niveles"}
            class="rounded-box bg-base-200 p-4 min-h-11 flex items-center justify-between gap-2"
          >
            <span class="font-display text-xl">Revisar niveles</span>
            <span :if={@mismatches_count > 0} class="badge badge-warning">
              {@mismatches_count} discrepancias
            </span>
          </.link>
          <.link
            :if={User.owner?(@current_scope.user)}
            navigate={~p"/admin/staff"}
            class="rounded-box bg-base-200 p-4 min-h-11 flex items-center justify-between gap-2"
          >
            <span class="font-display text-xl">Staff</span>
          </.link>
        </div>
        <.link href={~p"/admin/salir"} method="delete" class="text-sm text-neutral">
          Salir
        </.link>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {placed, total} = Shelves.location_progress()

    {:ok,
     socket
     |> assign(:draft_count, Catalog.count_admin_games(status: :draft))
     |> assign(:placed, placed)
     |> assign(:total, total)
     |> assign(:mismatches_count, BandAudit.count_mismatches())}
  end
end
