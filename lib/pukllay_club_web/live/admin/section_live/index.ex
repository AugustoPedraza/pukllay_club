defmodule PukllayClubWeb.Admin.SectionLive.Index do
  @moduledoc """
  Web at `/admin/secciones` (D-00a, D-19f, D-19h, D-19i, D-19j, D-19k,
  D-19l, D-19m — the renamed Secciones, sketch 070's design) — the page
  opens directly on the destacada's own rail, D-19l's counterpart to
  D-19g: a short, stable list of the same kind of thing (home rows) earns
  its place below the destacada's main control, as navigation
  (`Otras filas`), not a second control. Tapping an `Otras filas` row
  opens `Admin.SectionLive.Edit`, the same page shape scoped to that
  section — the destacada's own settings and member management live
  directly on this page instead, since D-19l already gives it a resting
  place at the top.

  `Quitar de la fila` (D-19k) is the explicit counter-case to D-19f: it
  happens at once with a 10s Deshacer snackbar, no dialog, and the row is
  never Peligro red — removing a game from a curated row loses no state
  staff would have to rebuild. The Ajustes «Mostrar en el inicio» toggle
  is the shipped `hidden` column's *inverse* — the previously-shipped
  label read the opposite polarity (`admin-redesign-scope.md` gap #14), a
  copy flip that must not silently invert the control.
  `normalize_ajustes_params/1` below is the one place that inversion
  happens.

  No delete action exists anywhere on this screen (E6 empty: cannot occur
  at launch since plan 10's migration seeds 3 sections plus an empty
  featured one; sections are hide-only, per D-17/E6). `Sections`' own
  context calls (`settings_changeset/2` reading `kind` off the struct,
  the featured cap checked inside the insert transaction, 01.8.1-12's
  closure of T-01.8.1-56) are called exactly as before — this plan
  changes presentation and the removal/undo shape only.
  """
  use PukllayClubWeb, :live_view

  alias Phoenix.LiveView.JS
  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Sections
  alias PukllayClubWeb.AdminComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Web")
     |> assign(:name_input, "")
     |> assign(:name_error, nil)
     |> assign(:q, "")
     |> assign(:search_results, [])
     |> assign(:add_error, nil)
     |> assign(:selected_member, nil)
     |> assign(:removed, nil)
     |> assign(:reorder_mode, false)
     |> assign(:revealed_section_id, nil)
     |> assign(:reorder_snapshot, nil)
     |> assign(:undo_snapshot, nil)
     |> load_sections()}
  end

  defp load_sections(socket) do
    sections = Sections.list_sections()
    featured = Enum.find(sections, & &1.featured)

    socket
    |> assign(:featured, featured)
    |> assign(:other_sections, Enum.reject(sections, & &1.featured))
    |> assign(:featured_members, if(featured, do: Sections.section_members(featured), else: []))
    |> assign(:form, if(featured, do: to_form(Sections.change_section(featured))))
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

  @impl true
  def handle_event("validate", %{"section" => params}, socket) do
    changeset =
      socket.assigns.featured
      |> Sections.change_section(normalize_ajustes_params(params))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"section" => params}, socket) do
    case Sections.update_section(socket.assigns.featured, normalize_ajustes_params(params)) do
      {:ok, _section} ->
        {:noreply, socket |> load_sections() |> put_flash(:info, "Fila guardada.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    results = if q == "", do: [], else: search_candidates(socket, q)
    {:noreply, socket |> assign(:q, q) |> assign(:search_results, results)}
  end

  @impl true
  def handle_event("add-game", %{"game-id" => id}, socket) do
    case Integer.parse(id) do
      {int_id, ""} ->
        case Sections.add_game(socket.assigns.featured, int_id) do
          {:ok, _section} ->
            {:noreply,
             socket
             |> assign(:add_error, nil)
             |> assign(:q, "")
             |> assign(:search_results, [])
             |> load_sections()}

          {:error, reason} ->
            {:noreply, assign(socket, :add_error, reason)}
        end

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open-member-sheet", %{"game-id" => id}, socket) do
    case Integer.parse(id) do
      {int_id, ""} ->
        member = Enum.find(socket.assigns.featured_members, &(&1.game_id == int_id))
        {:noreply, assign(socket, :selected_member, member)}

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close-member-sheet", _params, socket) do
    {:noreply, assign(socket, :selected_member, nil)}
  end

  # D-19k: at once, no dialog, never Peligro — the game and its shelf
  # spot are untouched, so Deshacer (`undo-remove` below) is a plain
  # re-add rather than a state restore.
  @impl true
  def handle_event("remove-game", %{"game-id" => id}, socket) do
    case Integer.parse(id) do
      {int_id, ""} ->
        member = Enum.find(socket.assigns.featured_members, &(&1.game_id == int_id))
        {:ok, _section} = Sections.remove_game(socket.assigns.featured, int_id)

        {:noreply,
         socket
         |> assign(:selected_member, nil)
         |> assign(:removed, member && %{game_id: int_id, name: member.game.name})
         |> load_sections()}

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
        {:ok, _section} = Sections.add_game(socket.assigns.featured, game_id)
        {:noreply, socket |> assign(:removed, nil) |> load_sections()}
    end
  end

  @impl true
  def handle_event("dismiss-remove-snackbar", _params, socket) do
    {:noreply, assign(socket, :removed, nil)}
  end

  @impl true
  def handle_event("start-reorder", _params, socket) do
    {:noreply,
     socket
     |> assign(:reorder_mode, true)
     |> assign(:revealed_section_id, nil)
     |> assign(:reorder_snapshot, Enum.map(socket.assigns.other_sections, & &1.id))}
  end

  @impl true
  def handle_event("done-reorder", _params, socket) do
    {:noreply,
     socket
     |> assign(:reorder_mode, false)
     |> assign(:revealed_section_id, nil)
     |> assign(:undo_snapshot, socket.assigns.reorder_snapshot)
     |> assign(:reorder_snapshot, nil)}
  end

  @impl true
  def handle_event("undo-reorder", _params, socket) do
    case socket.assigns.undo_snapshot do
      nil ->
        {:noreply, socket}

      snapshot ->
        restore_section_order(snapshot)
        {:noreply, socket |> assign(:undo_snapshot, nil) |> load_sections()}
    end
  end

  @impl true
  def handle_event("dismiss-reorder-snackbar", _params, socket) do
    {:noreply, assign(socket, :undo_snapshot, nil)}
  end

  @impl true
  def handle_event("reveal-section", %{"id" => id}, socket) do
    case parse_id(id) do
      nil -> {:noreply, socket}
      int_id -> {:noreply, assign(socket, :revealed_section_id, int_id)}
    end
  end

  # `id` arrives as a string from the always-visible-arrows era's
  # `phx-value-section-id` HTML attribute, OR as an already-decoded
  # integer from `reorder_row/1`'s `JS.push(..., value: %{"section-id" =>
  # section.id})` — `parse_id/1` accepts both.
  defp move(socket, id, direction) do
    case parse_id(id) do
      nil ->
        {:noreply, socket}

      int_id ->
        {:ok, _section} = int_id |> Sections.get_section!() |> Sections.move_section(direction)
        {:noreply, load_sections(socket)}
    end
  end

  # D-19l's "Mostrar en el inicio" is the shipped `hidden` column's
  # INVERSE — the copy flip (`admin-redesign-scope.md` gap #14) must
  # invert the value it submits, not just the label, or the control would
  # silently do the opposite of what it says (T-01.8.2-65). This is the
  # ONE place that inversion happens; `Sections`/`Section` never learn a
  # "shown" concept, only ever `hidden`.
  defp normalize_ajustes_params(%{"shown" => shown} = params) do
    params
    |> Map.delete("shown")
    |> Map.put("hidden", to_string(shown != "true"))
  end

  defp normalize_ajustes_params(params), do: params

  # `JS.push(..., value: %{"id" => section.id})` round-trips the id as a
  # JSON number, not a string — `phx-value-*` HTML attributes always
  # arrive as strings. Accept both rather than assuming one shape.
  defp parse_id(id) when is_integer(id), do: id

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int_id, ""} -> int_id
      _not_an_integer -> nil
    end
  end

  defp parse_id(_other), do: nil

  # Restores `@other_sections` to `target_ids`' order using ONLY
  # `Sections.move_section/2`'s existing adjacent-swap primitive (no new
  # `Sections` function, per this plan's own scope) — a classic
  # selection-sort-by-adjacent-transposition: for each target position in
  # turn, bubble the wanted section up to it one swap at a time.
  defp restore_section_order(target_ids) do
    Enum.reduce(0..(length(target_ids) - 1), :ok, fn index, :ok ->
      wanted_id = Enum.at(target_ids, index)
      bubble_section_to(wanted_id, index)
    end)
  end

  defp bubble_section_to(section_id, target_index) do
    current_ids = Sections.list_sections() |> Enum.reject(& &1.featured) |> Enum.map(& &1.id)
    current_index = Enum.find_index(current_ids, &(&1 == section_id))

    if current_index && current_index > target_index do
      {:ok, _section} = section_id |> Sections.get_section!() |> Sections.move_section(:up)
      bubble_section_to(section_id, target_index)
    else
      :ok
    end
  end

  defp search_candidates(socket, q) do
    member_game_ids = Enum.map(socket.assigns.featured_members, & &1.game_id)

    [q: q, limit: 20]
    |> Catalog.list_admin_games()
    |> Enum.reject(&(&1.status == :retired or &1.id in member_game_ids))
  end

  defp kind_tag_label(:manual), do: "personalizada"
  defp kind_tag_label(_automatic), do: "automática"

  defp other_section_meta(%{kind: :manual} = section) do
    count = length(Sections.section_members(section))
    "#{count} juego#{if count == 1, do: "", else: "s"}"
  end

  defp other_section_meta(_automatic), do: nil

  defp other_section_count(%{kind: :manual} = section), do: length(Sections.section_members(section))
  defp other_section_count(_automatic), do: nil

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
        <h1 class="pk-admin-page-title">Web</h1>

        <div :if={@featured} id="web-destacada" class="pk-admin-web-destacada">
          <p class="pk-admin-web-destacada__name">{@featured.name}</p>
          <p class="pk-admin-web-destacada__context">
            {length(@featured_members)} juego{if length(@featured_members) == 1, do: "", else: "s"}
          </p>

          <div :if={@featured_members != []} class="pk-rail-wrap">
            <div class="pk-rail" id="web-destacada-rail">
              <button
                :for={member <- @featured_members}
                type="button"
                id={"web-cover-#{member.game_id}"}
                class="pk-poster-card"
                data-pk-pressable="true"
                phx-click="open-member-sheet"
                phx-value-game-id={member.game_id}
              >
                <div role="img" aria-label={member.game.name} class="pk-admin-web-cover__art">
                  <img
                    :if={member.game.thumbnail_url}
                    src={member.game.thumbnail_url}
                    alt=""
                    class="pk-admin-web-cover__img"
                  />
                  <div :if={!member.game.thumbnail_url} class="pk-admin-web-cover__fallback">
                    <.icon name="hero-puzzle-piece" class="size-8" />
                  </div>
                </div>
              </button>
            </div>
          </div>

          <p :if={@featured_members == []} class="pk-admin-empty-note">
            Sin juegos, no se ve en el inicio.
          </p>

          <form id="web-search-form" phx-change="search" class="pk-admin-web-search">
            <AdminComponents.field
              type="text"
              id="web-search-input"
              name="q"
              value={@q}
              label="Agregar un juego"
              placeholder="Buscá un juego"
              phx-debounce="300"
            />
          </form>

          <p :if={add_error_message(@add_error)} class="pk-admin-web-add-error">
            {add_error_message(@add_error)}
          </p>

          <div :if={@q != ""} id="web-search-results" class="pk-admin-web-search-results">
            <p :if={@search_results == []} class="pk-admin-empty-note">Sin resultados.</p>
            <AdminComponents.list_row
              :for={game <- @search_results}
              id={"web-search-result-#{game.id}"}
              name={game.name}
              phx-click="add-game"
              phx-value-game-id={game.id}
            />
          </div>

          <AdminComponents.section_panel class="pk-admin-web-ajustes">
            <:label>Ajustes</:label>
            <.form
              for={@form}
              id="web-ajustes-form"
              phx-change="validate"
              phx-submit="save"
              class="pk-admin-stacked-form"
            >
              <AdminComponents.field field={@form[:name]} label="Nombre" />
              <AdminComponents.field field={@form[:subtitle]} label="Subtítulo" />
              <AdminComponents.field
                type="checkbox"
                id="web-ajustes-shown"
                name="section[shown]"
                checked={!@form[:hidden].value}
                label="Mostrar en el inicio"
              />
              <AdminComponents.action anatomy="a1" role="principal" type="submit">
                Guardar
              </AdminComponents.action>
            </.form>
          </AdminComponents.section_panel>
        </div>

        <section :if={@other_sections != []} id="web-otras-filas" class="pk-admin-web-otras">
          <div class="pk-admin-web-otras-header">
            <AdminComponents.reorder_header
              :if={@reorder_mode}
              title="Ordenar filas"
              on_done={JS.push("done-reorder")}
            />
            <AdminComponents.list_section_label :if={!@reorder_mode}>
              Otras filas
            </AdminComponents.list_section_label>
            <AdminComponents.action
              :if={!@reorder_mode}
              anatomy="a3"
              role="terciaria"
              aria-label="Ordenar filas"
              phx-click="start-reorder"
            >
              <.icon name="hero-arrows-up-down" class="size-5" />
            </AdminComponents.action>
          </div>

          <div :if={!@reorder_mode}>
            <div :for={section <- @other_sections} class="pk-admin-web-otras-row">
              <AdminComponents.list_row
                id={"other-section-#{section.id}"}
                class="pk-admin-web-otras-row__row"
                name={section.name}
                meta={other_section_meta(section)}
                navigate={~p"/admin/secciones/#{section.id}"}
                opens_page
              >
                <:trailing>
                  <AdminComponents.kind_tag label={kind_tag_label(section.kind)} />
                  <AdminComponents.count_pill
                    :if={other_section_count(section)}
                    count={other_section_count(section)}
                  />
                </:trailing>
              </AdminComponents.list_row>
            </div>
          </div>

          <div :if={@reorder_mode} id="web-otras-reorder">
            <AdminComponents.reorder_row
              :for={section <- @other_sections}
              id={"reorder-section-#{section.id}"}
              revealed={@revealed_section_id == section.id}
              on_reveal={JS.push("reveal-section", value: %{"id" => section.id})}
              on_up={JS.push("move-up", value: %{"section-id" => section.id})}
              on_down={JS.push("move-down", value: %{"section-id" => section.id})}
              up_label={"Subir #{section.name}"}
              down_label={"Bajar #{section.name}"}
            >
              {section.name}
            </AdminComponents.reorder_row>
          </div>
        </section>

        <AdminComponents.section_panel class="pk-admin-web-create">
          <:label>Nueva fila</:label>
          <form id="create-section-form" phx-submit="create" class="pk-admin-web-create-form">
            <AdminComponents.field
              type="text"
              id="create-section-name"
              name="name"
              value={@name_input}
              label="Nombre de la sección"
              errors={if @name_error, do: [@name_error], else: []}
            />
            <AdminComponents.action anatomy="a1" role="principal" type="submit">
              Crear sección
            </AdminComponents.action>
          </form>
        </AdminComponents.section_panel>
      </div>

      <AdminComponents.sheet
        :if={@selected_member}
        id="web-member-sheet"
        title={@selected_member.game.name}
        subtitle={@featured.name}
        open
        on_close={JS.push("close-member-sheet")}
      >
        <AdminComponents.action
          anatomy="a4"
          role="terciaria"
          phx-click="remove-game"
          phx-value-game-id={@selected_member.game_id}
        >
          Quitar de la fila
        </AdminComponents.action>
      </AdminComponents.sheet>

      <AdminComponents.snackbar
        :if={@removed}
        id="web-remove-snackbar"
        message={"«#{@removed.name}» quitado de la fila."}
        action={%{label: "Deshacer", event: "undo-remove"}}
        on_close={JS.push("dismiss-remove-snackbar")}
      />

      <AdminComponents.snackbar
        :if={@undo_snapshot}
        id="web-reorder-snackbar"
        message="Orden guardado"
        action={%{label: "Deshacer", event: "undo-reorder"}}
        on_close={JS.push("dismiss-reorder-snackbar")}
      />
    </Layouts.app>
    """
  end

  defp add_error_message(:featured_full), do: "La sección destacada ya tiene 20 juegos. Quitá uno para agregar otro."

  defp add_error_message(:already_member), do: "Ese juego ya está en la sección."
  defp add_error_message(_other), do: nil
end
