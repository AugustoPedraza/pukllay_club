defmodule PukllayClubWeb.Admin.DashboardLive do
  @moduledoc """
  The `/admin` task dashboard shell (D-35, UI-SPEC E10).

  Mobile-first: a single-column card grid (`grid-cols-1 sm:grid-cols-2`)
  with no filled primary button on the page itself. `#admin-cards` is left
  empty here — later plans in this phase fill it in the fixed order Juegos,
  Estantes, Secciones, Revisar niveles, Staff (D-35).
  """
  use PukllayClubWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <.header>Panel</.header>
        <div id="admin-cards" class="grid grid-cols-1 gap-4 sm:grid-cols-2"></div>
        <.link href={~p"/admin/salir"} method="delete" class="text-sm text-neutral">
          Salir
        </.link>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
