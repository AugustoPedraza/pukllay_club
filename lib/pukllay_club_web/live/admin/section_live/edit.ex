defmodule PukllayClubWeb.Admin.SectionLive.Edit do
  @moduledoc """
  Section settings screen at `/admin/secciones/:id` (D-17, D-19, UI-SPEC
  E6) — rename, edit subtitle, hide/show, and (D-19) pick the section's
  sort rule. `:id` is parsed defensively with `Integer.parse/1`
  (T-01-37/T-01.8.1-46 convention), mirroring
  `Admin.ShelfLive.Assign`'s own `:id` handling.

  The sort select's options depend on the section's own `kind` (D-19,
  D-20, D-21 — enforced server-side by `Section.settings_changeset/2`,
  mirrored here only for the UI's own affordance): a `:manual` section
  may pick any sort; a `:weight_band` section never sees `A mano` (D-20 —
  membership always comes from the game's own `weight_band`, a manual
  pick order makes no sense without a manual member list); a `:recent`
  section has no select at all, just a fixed "Orden: más recientes
  primero" line (D-21 — the ordering IS the automatic rule).
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

  defp sort_options(:weight_band) do
    [
      {"Por nombre", :name},
      {"Por peso BGG", :bgg_weight},
      {"Por puntaje BGG", :bgg_rating},
      {"Recientes", :recent}
    ]
  end

  defp sort_options(_manual), do: [{"A mano", :manual} | sort_options(:weight_band)]

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

          <p :if={@section.kind == :recent} class="text-neutral text-sm">
            Orden: más recientes primero
          </p>
          <.input
            :if={@section.kind != :recent}
            field={@form[:sort]}
            type="select"
            label="Orden"
            options={sort_options(@section.kind)}
          />

          <.button variant="primary">Guardar cambios</.button>
        </.form>

        <p :if={@section.kind == :weight_band} class="text-neutral text-sm">
          Los juegos de esta sección salen de su nivel.
        </p>
      </div>
    </Layouts.app>
    """
  end
end
