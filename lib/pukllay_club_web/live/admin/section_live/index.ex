defmodule PukllayClubWeb.Admin.SectionLive.Index do
  @moduledoc """
  Secciones management at `/admin/secciones` (D-17, D-18, UI-SPEC E6) —
  every section, hidden ones included, in the same featured-first-then-
  position order the public home page renders (`Catalog.list_home_sections/0`).
  Each row links to its own `Admin.SectionLive.Edit` settings screen.
  Staff create new hand-picked sections here and reorder the non-featured
  ones with ↑/↓ (D-19) — the featured row is pinned first with no arrows
  (D-18, UI-SPEC Visual Hierarchy).

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
     |> assign(:name_input, "")
     |> assign(:name_error, nil)
     |> assign(:sections, Sections.list_sections())}
  end

  @impl true
  def handle_event("create", %{"name" => name}, socket) do
    case Sections.create_section(%{name: name}) do
      {:ok, section} ->
        {:noreply, push_navigate(socket, to: ~p"/admin/secciones/#{section.id}")}

      {:error, changeset} ->
        error = changeset.errors |> translate_errors(:name) |> List.first()
        {:noreply, socket |> assign(:name_input, name) |> assign(:name_error, error)}
    end
  end

  @impl true
  def handle_event("move-up", %{"section-id" => id}, socket), do: move(socket, id, :up)

  @impl true
  def handle_event("move-down", %{"section-id" => id}, socket), do: move(socket, id, :down)

  defp move(socket, id, direction) do
    case Integer.parse(id) do
      {int_id, ""} ->
        {:ok, _section} = int_id |> Sections.get_section!() |> Sections.move_section(direction)
        {:noreply, assign(socket, :sections, Sections.list_sections())}

      _not_an_integer ->
        {:noreply, socket}
    end
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

        <form id="create-section-form" phx-submit="create" class="flex flex-wrap items-end gap-3">
          <div class="flex-1 min-w-48">
            <.input
              type="text"
              id="create-section-name"
              name="name"
              value={@name_input}
              label="Nombre de la sección"
              errors={if @name_error, do: [@name_error], else: []}
            />
          </div>
          <.button variant="primary">Crear sección</.button>
        </form>

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
            <button
              :if={!section.featured}
              type="button"
              phx-click="move-up"
              phx-value-section-id={section.id}
              aria-label={"Subir #{section.name}"}
              class="btn btn-ghost btn-square min-h-11 min-w-11"
            >
              <.icon name="hero-arrow-up" />
            </button>
            <button
              :if={!section.featured}
              type="button"
              phx-click="move-down"
              phx-value-section-id={section.id}
              aria-label={"Bajar #{section.name}"}
              class="btn btn-ghost btn-square min-h-11 min-w-11"
            >
              <.icon name="hero-arrow-down" />
            </button>
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end
end
