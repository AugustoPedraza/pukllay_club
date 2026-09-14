defmodule PukllayClubWeb.Admin.SectionLive.Edit do
  @moduledoc """
  Section settings screen at `/admin/secciones/:id` (D-17, D-19, UI-SPEC
  E6) — rename, edit subtitle, hide/show, and (D-19) pick the section's
  sort rule. `:id` is parsed defensively with `Integer.parse/1`
  (T-01-37/T-01.8.1-46 convention), mirroring
  `Admin.ShelfLive.Assign`'s own `:id` handling.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.Sections

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Integer.parse(id) do
      {int_id, ""} ->
        section = Sections.get_section!(int_id)

        {:ok,
         socket
         |> assign(:page_title, section.name)
         |> assign(:section, section)
         |> assign(:form, to_form(Sections.change_section(section)))}

      _not_an_integer ->
        raise Ecto.NoResultsError, queryable: Section
    end
  end

  @impl true
  def handle_event("validate", %{"section" => params}, socket) do
    changeset =
      socket.assigns.section
      |> Sections.change_section(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"section" => params}, socket) do
    case Sections.update_section(socket.assigns.section, params) do
      {:ok, section} ->
        {:noreply,
         socket
         |> assign(:section, section)
         |> assign(:page_title, section.name)
         |> assign(:form, to_form(Sections.change_section(section)))
         |> put_flash(:info, "Sección guardada.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <.header>
          {@section.name}
          <:actions>
            <.link navigate={~p"/admin/secciones"} class="text-sm text-neutral">
              ← Volver
            </.link>
          </:actions>
        </.header>

        <.form
          for={@form}
          id="section-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-2"
        >
          <.input field={@form[:name]} type="text" label="Nombre" />
          <.input field={@form[:subtitle]} type="text" label="Subtítulo" />
          <.input field={@form[:hidden]} type="checkbox" label="Ocultar en la home" />

          <.button variant="primary">Guardar cambios</.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
