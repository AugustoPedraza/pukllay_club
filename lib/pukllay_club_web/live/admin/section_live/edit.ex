defmodule PukllayClubWeb.Admin.SectionLive.Edit do
  @moduledoc """
  A non-featured home row's own page at `/admin/secciones/:id` (D-00a,
  D-19f, D-19h, D-19i, D-19j, D-19k, D-19m — sketch 070 decision 12: "any
  hand-picked row opens the same page" as the destacada's own
  `Admin.SectionLive.Index`, just reached with a `‹ Volver` back link
  instead of Web's own resting place). Rename, edit subtitle, hide/show
  (D-19), pick the section's sort rule, and (D-25, `:manual` sections
  only) a phone-first member picker: a debounced type-ahead search to add
  games and a per-item `Quitar de la fila` (D-19k: at once, a 10s
  Deshacer snackbar, no dialog, never Peligro — removing a game from a
  curated row loses no state staff would have to rebuild). `:id` is
  parsed defensively with `Integer.parse/1` (T-01-37/T-01.8.1-46
  convention), mirroring `Admin.ShelfLive.Assign`'s own `:id` handling.

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

  `Sections`' own context calls (`settings_changeset/2` reading `kind` off
  the struct, the featured cap checked inside the insert transaction,
  01.8.1-12's closure of T-01.8.1-56) are called exactly as before — this
  plan changes presentation and the removal/undo shape only.
  """
  use PukllayClubWeb, :live_view

  alias Phoenix.LiveView.JS
  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.Sections
  alias PukllayClubWeb.AdminComponents

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
         |> assign(:removed, nil)
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
      |> Sections.change_section(normalize_ajustes_params(params))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"section" => params}, socket) do
    case Sections.update_section(socket.assigns.section, normalize_ajustes_params(params)) do
      {:ok, section} ->
        {:noreply,
         socket
         |> assign(:section, section)
         |> assign(:page_title, section.name)
         |> assign(:form, to_form(Sections.change_section(section)))
         |> put_flash(:info, "Fila guardada.")}

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

  # D-19k: at once, no dialog, never Peligro — Deshacer (`undo-remove`
  # below) is a plain re-add, since the game and its shelf spot are
  # untouched by removal from a curated row.
  @impl true
  def handle_event("remove-game", %{"game-id" => id}, socket) do
    case Integer.parse(id) do
      {int_id, ""} ->
        member = Enum.find(socket.assigns.members, &(&1.game_id == int_id))
        {:ok, _section} = Sections.remove_game(socket.assigns.section, int_id)

        {:noreply,
         socket
         |> assign(:removed, member && %{game_id: int_id, name: member.game.name})
         |> reload_members()}

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("undo-remove", _params, socket) do
    case socket.assigns.removed do
      nil ->
        {:noreply, socket}

      %{game_id: game_id} ->
        {:ok, _section} = Sections.add_game(socket.assigns.section, game_id)
        {:noreply, socket |> assign(:removed, nil) |> reload_members()}
    end
  end

  @impl true
  def handle_event("dismiss-remove-snackbar", _params, socket) do
    {:noreply, assign(socket, :removed, nil)}
  end

  @impl true
  def handle_event("move-member-up", %{"game-id" => id}, socket), do: move_member(socket, id, :up)

  @impl true
  def handle_event("move-member-down", %{"game-id" => id}, socket), do: move_member(socket, id, :down)

  # D-19l's "Mostrar en el inicio" is the shipped `hidden` column's
  # INVERSE — the copy flip (`admin-redesign-scope.md` gap #14) must
  # invert the value it submits, not just the label, or the control would
  # silently do the opposite of what it says (T-01.8.2-65).
  defp normalize_ajustes_params(%{"shown" => shown} = params) do
    params
    |> Map.delete("shown")
    |> Map.put("hidden", to_string(shown != "true"))
  end

  defp normalize_ajustes_params(params), do: params

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
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      bottom_collapse
      admin_chrome
      active_tab={:web}
    >
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <AdminComponents.back_row to={~p"/admin/secciones"} />
        <h1 class="pk-admin-page-title">{@section.name}</h1>

        <AdminComponents.section_panel>
          <:label>Ajustes</:label>
          <.form
            for={@form}
            id="section-form"
            phx-change="validate"
            phx-submit="save"
            class="pk-admin-stacked-form"
          >
            <AdminComponents.field field={@form[:name]} label="Nombre" />
            <AdminComponents.field field={@form[:subtitle]} label="Subtítulo" />
            <AdminComponents.field
              type="checkbox"
              id="section-ajustes-shown"
              name="section[shown]"
              checked={!@form[:hidden].value}
              label="Mostrar en el inicio"
            />

            <p :if={@section.kind == :recent} class="pk-admin-empty-note">
              Orden: más recientes primero
            </p>
            <AdminComponents.field
              :if={@section.kind != :recent}
              field={@form[:sort]}
              type="select"
              label="Orden"
              options={sort_options(@section.kind)}
            />

            <AdminComponents.action anatomy="a1" role="principal" type="submit">
              Guardar
            </AdminComponents.action>
          </.form>
        </AdminComponents.section_panel>

        <p :if={@section.kind == :weight_band} class="pk-admin-empty-note">
          Los juegos de esta sección salen de su nivel.
        </p>

        <div :if={@section.kind == :manual} id="section-members" class="space-y-3">
          <AdminComponents.list_section_label>
            Juegos ({length(@members)})
          </AdminComponents.list_section_label>

          <p :if={add_error_message(@add_error)} class="pk-admin-web-add-error">
            {add_error_message(@add_error)}
          </p>

          <form id="section-member-search" phx-change="search" class="pk-admin-web-search">
            <AdminComponents.field
              type="text"
              id="section-member-search-input"
              name="q"
              value={@q}
              label="Agregar un juego"
              placeholder="Buscá un juego"
              phx-debounce="300"
            />
          </form>

          <div :if={@q != ""} id="section-search-results" class="pk-admin-web-search-results">
            <p :if={@search_results == []} class="pk-admin-empty-note">Sin resultados.</p>
            <AdminComponents.list_row
              :for={game <- @search_results}
              id={"section-search-result-#{game.id}"}
              name={game.name}
              phx-click="add-game"
              phx-value-game-id={game.id}
            />
          </div>

          <div :for={member <- @members} class="pk-admin-web-otras-row">
            <AdminComponents.list_row
              id={"section-member-#{member.game_id}"}
              class="pk-admin-web-otras-row__row"
              name={member.game.name}
            >
              <:trailing>
                <AdminComponents.action
                  anatomy="a2"
                  role="terciaria"
                  phx-click="remove-game"
                  phx-value-game-id={member.game_id}
                >
                  Quitar de la fila
                </AdminComponents.action>
              </:trailing>
            </AdminComponents.list_row>
            <AdminComponents.action
              :if={@section.sort == :manual}
              anatomy="a3"
              role="terciaria"
              aria-label={"Subir #{member.game.name}"}
              phx-click="move-member-up"
              phx-value-game-id={member.game_id}
            >
              <.icon name="hero-arrow-up" class="size-5" />
            </AdminComponents.action>
            <AdminComponents.action
              :if={@section.sort == :manual}
              anatomy="a3"
              role="terciaria"
              aria-label={"Bajar #{member.game.name}"}
              phx-click="move-member-down"
              phx-value-game-id={member.game_id}
            >
              <.icon name="hero-arrow-down" class="size-5" />
            </AdminComponents.action>
          </div>
        </div>
      </div>

      <AdminComponents.snackbar
        :if={@removed}
        id="section-remove-snackbar"
        message={"«#{@removed.name}» quitado de la fila."}
        action={%{label: "Deshacer", event: "undo-remove"}}
        on_close={JS.push("dismiss-remove-snackbar")}
      />
    </Layouts.app>
    """
  end
end
