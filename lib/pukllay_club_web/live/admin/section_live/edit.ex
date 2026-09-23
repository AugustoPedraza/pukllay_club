defmodule PukllayClubWeb.Admin.SectionLive.Edit do
  @moduledoc """
  Section settings screen at `/admin/secciones/:id` (D-17, D-19, D-25,
  UI-SPEC E6) — rename, edit subtitle, hide/show, (D-19) pick the
  section's sort rule, and (D-25, `:manual` sections only) a phone-first
  member picker: a debounced type-ahead search to add games and, when
  `sort == :manual`, ↑/↓ to reorder plus a per-item `Quitar` (no
  confirmation — mirrors unchecking a filter). `:id` is parsed
  defensively with `Integer.parse/1` (T-01-37/T-01.8.1-46 convention),
  mirroring `Admin.ShelfLive.Assign`'s own `:id` handling.

  The sort select's options depend on the section's own `kind` (D-19,
  D-20, D-21 — enforced server-side by `Section.settings_changeset/2`,
  mirrored here only for the UI's own affordance): a `:manual` section
  may pick any sort; a `:weight_band` section never sees `A mano` (D-20 —
  membership always comes from the game's own `weight_band`, a manual
  pick order makes no sense without a manual member list); a `:recent`
  section has no select at all, just a fixed "Orden: más recientes
  primero" line (D-21 — the ordering IS the automatic rule). A
  `:weight_band` section shows "Los juegos de esta sección salen de su
  nivel." in place of any member list — it never has one (D-20).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog
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
         |> assign(:form, to_form(Sections.change_section(section)))
         |> assign(:q, "")
         |> assign(:search_results, [])
         |> assign(:add_error, nil)
         |> reload_members()}

      _not_an_integer ->
        raise Ecto.NoResultsError, queryable: Section
    end
  end

  defp reload_members(socket) do
    assign(socket, :members, Sections.section_members(socket.assigns.section))
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

  # D-25: type-ahead search across non-retired games not already a
  # member of this section — mirrors `Admin.ShelfLive.Assign`'s own
  # `phx-debounce="300"` search shape.
  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    results = if q == "", do: [], else: search_candidates(socket, q)
    {:noreply, socket |> assign(:q, q) |> assign(:search_results, results)}
  end

  @impl true
  def handle_event("add-game", %{"game-id" => id}, socket) do
    case Integer.parse(id) do
      {int_id, ""} ->
        case Sections.add_game(socket.assigns.section, int_id) do
          {:ok, _section} ->
            {:noreply,
             socket
             |> assign(:add_error, nil)
             |> assign(:q, "")
             |> assign(:search_results, [])
             |> reload_members()}

          {:error, reason} ->
            {:noreply, assign(socket, :add_error, reason)}
        end

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove-game", %{"game-id" => id}, socket) do
    case Integer.parse(id) do
      {int_id, ""} ->
        {:ok, _section} = Sections.remove_game(socket.assigns.section, int_id)
        {:noreply, reload_members(socket)}

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("move-member-up", %{"game-id" => id}, socket), do: move_member(socket, id, :up)

  @impl true
  def handle_event("move-member-down", %{"game-id" => id}, socket), do: move_member(socket, id, :down)

  defp move_member(socket, id, direction) do
    case Integer.parse(id) do
      {int_id, ""} ->
        {:ok, _section} = Sections.move_game(socket.assigns.section, int_id, direction)
        {:noreply, reload_members(socket)}

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  defp search_candidates(socket, q) do
    member_game_ids = Enum.map(socket.assigns.members, & &1.game_id)

    [q: q, limit: 20]
    |> Catalog.list_admin_games()
    |> Enum.reject(&(&1.status == :retired or &1.id in member_game_ids))
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

  defp add_error_message(:featured_full), do: "La sección destacada ya tiene 20 juegos. Quitá uno para agregar otro."

  defp add_error_message(:already_member), do: "Ese juego ya está en la sección."
  defp add_error_message(_other), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse admin_chrome>
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

        <div :if={@section.kind == :manual} id="section-members" class="space-y-3">
          <h2 class="font-display text-xl">Juegos ({length(@members)})</h2>

          <p :if={add_error_message(@add_error)} class="text-warning text-sm">
            {add_error_message(@add_error)}
          </p>

          <form id="section-member-search" phx-change="search" class="w-full">
            <.input
              type="text"
              id="section-member-search-input"
              name="q"
              value={@q}
              placeholder="Buscar un juego para agregar"
              phx-debounce="300"
            />
          </form>

          <div :if={@q != ""} class="space-y-1">
            <p :if={@search_results == []} class="text-neutral text-sm">Sin resultados.</p>
            <button
              :for={game <- @search_results}
              type="button"
              phx-click="add-game"
              phx-value-game-id={game.id}
              class="flex w-full min-h-11 items-center gap-2 rounded-box border border-base-300 p-2 text-left"
            >
              <span class="flex-1">{game.name}</span>
            </button>
          </div>

          <ul class="space-y-1">
            <li
              :for={member <- @members}
              class="flex items-center gap-2 rounded-box border border-base-300 p-2"
            >
              <span class="flex-1 min-h-11 flex items-center">{member.game.name}</span>
              <button
                :if={@section.sort == :manual}
                type="button"
                phx-click="move-member-up"
                phx-value-game-id={member.game_id}
                aria-label={"Subir #{member.game.name}"}
                class="btn btn-ghost btn-square min-h-11 min-w-11"
              >
                <.icon name="hero-arrow-up" />
              </button>
              <button
                :if={@section.sort == :manual}
                type="button"
                phx-click="move-member-down"
                phx-value-game-id={member.game_id}
                aria-label={"Bajar #{member.game.name}"}
                class="btn btn-ghost btn-square min-h-11 min-w-11"
              >
                <.icon name="hero-arrow-down" />
              </button>
              <.button variant="secondary" phx-click="remove-game" phx-value-game-id={member.game_id}>
                Quitar
              </.button>
            </li>
          </ul>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
