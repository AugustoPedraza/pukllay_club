defmodule PukllayClubWeb.Admin.SectionLive.Index do
  @moduledoc """
  Secciones management at `/admin/secciones` (D-17, D-18, UI-SPEC E6) —
  every section, hidden ones included, in the same featured-first-then-
  position order the public home page renders (`Catalog.list_home_sections/0`).
  Each row links to its own `Admin.SectionLive.Edit` settings screen.

  No delete action exists anywhere on this screen (E6 empty: cannot occur
  at launch since plan 10's migration seeds 3 sections plus an empty
  featured one; sections are hide-only, per D-17/E6).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog.Sections

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Secciones")
     |> assign(:sections, Sections.list_sections())}
  end

  defp kind_hint(:manual), do: "Elegida a mano"
  defp kind_hint(:weight_band), do: "Por nivel"
  defp kind_hint(:recent), do: "Recientes"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <.header>Secciones</.header>

        <ul class="space-y-2">
          <li
            :for={section <- @sections}
            class="flex items-center gap-2 rounded-box border border-base-300 p-2"
          >
            <.link
              navigate={~p"/admin/secciones/#{section.id}"}
              class="flex-1 min-h-11 flex items-center gap-2"
            >
              <span class="flex-1">{section.name}</span>
              <span class="text-neutral text-sm">{kind_hint(section.kind)}</span>
              <span :if={section.featured} class="badge">Destacada</span>
              <span :if={section.hidden} class="badge badge-neutral">Oculta</span>
            </.link>
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end
end
