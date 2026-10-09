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

  The destacada's rail is the page's ONE add control (D-19j, RAIL-01,
  RAIL-05): every gap between covers, and both ends, is a real "+" button
  that opens the «¿Qué juego va acá?» sheet at that exact spot. Picking a
  game already in the row moves it there instead of duplicating it
  (ADD-05), and at the featured cap every "+" dims but stays a live control
  that explains the cap when tapped (RAIL-04). The older inline add field
  and its results block are gone from this page; `Admin.SectionLive.Edit`
  keeps its own until the page it belongs to is rebuilt.

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
  alias PukllayClubWeb.Admin.Params
  alias PukllayClubWeb.AdminComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Web")
     |> assign(:name_input, "")
     |> assign(:name_error, nil)
     |> assign(:selected_member, nil)
     |> assign(:removed, nil)
     |> assign(:add_sheet, nil)
     |> assign(:placed, nil)
     |> assign(:landed_game_id, nil)
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
        {:noreply, socket |> load_sections() |> clear_snackbars() |> put_flash(:info, "Fila guardada.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  # ------------------------------------------------------------------
  # The rail's "+" slots and the «¿Qué juego va acá?» sheet (01.8.4, ADD-01,
  # ADD-02, ADD-06). Every param is parsed through `Params.parse_int/2`
  # with an explicit range; the slot is bounds-checked against a FRESH
  # `Sections.section_members/1` read, never the render-time
  # `@featured_members`; and no event accepts a section id from the client.
  # ------------------------------------------------------------------

  @impl true
  def handle_event("open-add-sheet", %{"index" => raw}, %{assigns: %{featured: %{} = featured}} = socket) do
    ids = live_member_ids(socket)

    case Params.parse_int(raw, 0..length(ids)) do
      {:ok, index} ->
        if featured_full?(featured, length(ids)) do
          # RAIL-04: bail before the sheet opens, as the artefact does. The UI
          # bail is a courtesy; `insert_game_at/3` re-checks the cap under its
          # row lock. The count is a fresh read, never `@featured_members`.
          {:noreply, socket |> clear_snackbars() |> put_flash(:info, "Ya hay 20 juegos. Quitá uno para agregar otro.")}
        else
          {:noreply, assign(socket, :add_sheet, new_add_sheet(index, ids))}
        end

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("open-add-sheet", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("close-add-sheet", _params, socket) do
    {:noreply, assign(socket, :add_sheet, nil)}
  end

  @impl true
  def handle_event("add-sheet-search", %{"q" => q}, %{assigns: %{add_sheet: %{} = sheet}} = socket) when is_binary(q) do
    query = String.slice(q, 0, 120)
    results = candidate_games(sheet.snapshot_ids, query)
    {:noreply, assign(socket, :add_sheet, %{sheet | query: query, results: results})}
  end

  def handle_event("add-sheet-search", _params, socket), do: {:noreply, socket}

  # ADD-08 / phase 01.8.8: the real "create a game" flow is designed in that
  # phase's own sketch round. Until then the row is a stub that says so and
  # deliberately does NOT navigate anywhere (unlike Estantes' equivalent).
  @impl true
  def handle_event("create-game-stub", _params, socket) do
    {:noreply,
     socket
     |> assign(:add_sheet, nil)
     |> clear_snackbars()
     |> put_flash(:info, "Crear un juego: se diseña en otra ronda")}
  end

  @impl true
  def handle_event("add-sheet-pick", %{"game-id" => raw}, %{assigns: %{add_sheet: %{} = sheet, featured: %{}}} = socket) do
    if live_member_ids(socket) == sheet.snapshot_ids do
      case Params.parse_int(raw, Params.bigint_range()) do
        {:ok, game_id} -> {:noreply, place_game(socket, sheet, game_id)}
        :error -> {:noreply, socket}
      end
    else
      # The row changed under the open sheet: the tapped gap no longer
      # means what it meant. Say so and write nothing, rather than
      # clamping to the nearest valid slot.
      {:noreply,
       socket
       |> assign(:add_sheet, nil)
       |> clear_snackbars()
       |> put_flash(:info, "La fila cambió mientras elegías un juego. Probá de nuevo.")}
    end
  end

  def handle_event("add-sheet-pick", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("undo-place", _params, %{assigns: %{placed: %{kind: :added, game_id: id}}} = socket) do
    {:ok, _section} = Sections.remove_game(socket.assigns.featured, id)

    {:noreply,
     socket
     |> assign(:placed, nil)
     |> assign(:landed_game_id, nil)
     |> load_sections()}
  end

  # The inverse of a move is a move back to the `from` the original call
  # returned, never a recomputed index. The row may have changed since, so a
  # stale undo is swallowed (the context documents this as the caller's job)
  # rather than crashing the LiveView.
  def handle_event("undo-place", _params, %{assigns: %{placed: %{kind: :moved, game_id: id, from: from}}} = socket) do
    _ = Sections.move_game_to(socket.assigns.featured, id, from)

    {:noreply,
     socket
     |> assign(:placed, nil)
     |> assign(:landed_game_id, nil)
     |> load_sections()}
  end

  def handle_event("undo-place", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("dismiss-place-snackbar", _params, socket) do
    {:noreply, assign(socket, :placed, nil)}
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
         |> clear_snackbars()
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
     |> clear_snackbars()
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

  defp new_add_sheet(index, ids) do
    %{
      index: index,
      snapshot_ids: ids,
      query: "",
      results: [],
      recent: Catalog.recent_games_for_row(ids)
    }
  end

  # The cap follows `featured`, never the member count alone: any other
  # manual section is uncapped. The threshold lives only in `Sections`.
  defp featured_full?(%{featured: true}, count), do: count >= Sections.featured_cap()
  defp featured_full?(_section, _count), do: false

  defp live_member_ids(socket) do
    socket.assigns.featured |> Sections.section_members() |> Enum.map(& &1.game_id)
  end

  # A game already in the row is MOVED to the chosen gap, never duplicated
  # (ADD-05); any other game is inserted there.
  defp place_game(socket, sheet, game_id) do
    case Enum.find_index(sheet.snapshot_ids, &(&1 == game_id)) do
      nil -> insert_member(socket, sheet, game_id)
      from -> move_member(socket, sheet, game_id, from)
    end
  end

  defp insert_member(socket, sheet, game_id) do
    case Sections.insert_game_at(socket.assigns.featured, game_id, sheet.index) do
      {:ok, _placement} ->
        socket
        |> assign(:add_sheet, nil)
        |> load_sections()
        |> clear_snackbars()
        |> assign(:landed_game_id, game_id)
        |> assign(:placed, %{kind: :added, game_id: game_id})

      {:error, _reason} ->
        assign(socket, :add_sheet, nil)
    end
  end

  # The artefact's own `from === pos || from === pos - 1` condition: the two
  # gaps that bracket a game are the spot it already occupies. That is a
  # no-op with ZERO writes - a write that happens to land in the same order
  # would still bump `updated_at` on every renumbered row and still offer a
  # Deshacer for an action that did not happen.
  defp move_member(socket, %{index: slot}, _game_id, from) when slot in [from, from + 1] do
    socket
    |> assign(:add_sheet, nil)
    |> clear_snackbars()
    |> put_flash(:info, "Ya está en ese lugar")
  end

  defp move_member(socket, sheet, game_id, from) do
    # `rest_index/2` is the only place the slot-to-rest-list off-by-one lives.
    case Sections.move_game_to(socket.assigns.featured, game_id, Sections.rest_index(from, sheet.index)) do
      {:ok, %{from: original_index}} ->
        socket
        |> assign(:add_sheet, nil)
        |> load_sections()
        |> clear_snackbars()
        |> assign(:landed_game_id, game_id)
        |> assign(:placed, %{kind: :moved, game_id: game_id, from: original_index})

      {:error, _reason} ->
        assign(socket, :add_sheet, nil)
    end
  end

  defp placed_message(%{kind: :moved}), do: "Juego movido"
  defp placed_message(%{kind: :added}), do: "Juego agregado"

  # This page emits snacks through two independent mechanisms — three
  # assigns and `put_flash/3` — and an action-less flash snack has no
  # dismiss consumer at all (the accepted `data-timeout` limitation), so a
  # flash set earlier would otherwise render beside a later assign-driven
  # snack. This is the single gate in front of EVERY snack-setting write in
  # this module, reached in both orders: before each snackbar assign and
  # before each `put_flash/3`.
  defp clear_snackbars(socket) do
    socket
    |> assign(:removed, nil)
    |> assign(:undo_snapshot, nil)
    |> assign(:placed, nil)
    |> clear_flash(:info)
    |> clear_flash(:error)
  end

  # The sheet's candidate rows. A blank query is the idle state (ADD-03:
  # the newest games not already in the row); anything else is the ranked
  # name search (ADD-04). Both queries cap at 6 and exclude `:retired`
  # themselves, so nothing is re-sliced or re-filtered here. A game already
  # in the row IS returned by the search: the sheet marks it and moves it
  # (ADD-05) instead of hiding it.
  defp candidate_games(member_ids, query) do
    if blank_query?(query) do
      Catalog.recent_games_for_row(member_ids)
    else
      Catalog.search_admin_games_ranked(query)
    end
  end

  defp blank_query?(query), do: String.trim(query) == ""

  defp member_names(members), do: Enum.map(members, & &1.game.name)

  # 0-based slot index into the rail's gaps: 0 is before the first cover,
  # `length(names)` is after the last. The `0` clause is evaluated first, so
  # an empty rail's single slot (where 0 is both the first and the last
  # gap) reads "al principio".
  defp slot_where(_names, 0), do: "al principio"
  defp slot_where(names, index) when index == length(names), do: "al final"
  defp slot_where(names, index), do: "entre #{Enum.at(names, index - 1)} y #{Enum.at(names, index)}"

  defp add_sheet_subtitle(section_name, names, index), do: "#{section_name} · #{slot_where(names, index)}"

  attr :index, :integer, required: true
  attr :names, :list, required: true
  attr :full, :boolean, default: false

  defp web_slot(assigns) do
    ~H"""
    <button
      type="button"
      id={"web-slot-#{@index}"}
      class={["pk-admin-web-slot", @full && "pk-admin-web-slot--full"]}
      data-pk-pressable="true"
      phx-click="open-add-sheet"
      phx-value-index={@index}
      aria-label={"Agregar un juego " <> slot_where(@names, @index)}
    >
      <span class="pk-admin-web-slot__plus" aria-hidden="true">+</span>
    </button>
    """
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
    # Computed once per render, not once per slot.
    assigns = assign(assigns, :slots_full, featured_full?(assigns.featured, length(assigns.featured_members)))

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

        <div
          :if={@featured}
          id="web-destacada"
          class="pk-admin-web-destacada"
          phx-hook="AdminRail"
        >
          <p id="web-destacada-name" class="pk-admin-web-destacada__name">{@featured.name}</p>
          <p class="pk-admin-web-destacada__context">
            {length(@featured_members)} juego{if length(@featured_members) == 1, do: "", else: "s"}
          </p>

          <div
            id="web-destacada-rail"
            class={["pk-admin-web-rail", @featured_members == [] && "pk-admin-web-rail--empty"]}
            role="group"
            aria-labelledby="web-destacada-name"
          >
            <%= for {member, index} <- Enum.with_index(@featured_members) do %>
              <.web_slot index={index} names={member_names(@featured_members)} full={@slots_full} />
              <button
                type="button"
                id={"web-cover-#{member.game_id}"}
                class="pk-admin-web-box"
                data-pk-pressable="true"
                data-pk-rail-selected={to_string(member.game_id == @landed_game_id)}
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
                <span class="pk-admin-web-box__caption" aria-hidden="true">{member.game.name}</span>
              </button>
            <% end %>
            <.web_slot
              index={length(@featured_members)}
              names={member_names(@featured_members)}
              full={@slots_full}
            />
            <span :if={@featured_members == []} class="pk-admin-web-rail__hint">
              Tocá + para elegir el primer juego.
            </span>
          </div>

          <p :if={@featured_members == []} class="pk-admin-empty-note">
            Sin juegos, no se ve en el inicio.
          </p>

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

      <AdminComponents.sheet
        :if={@add_sheet}
        id="web-add-sheet"
        title="¿Qué juego va acá?"
        subtitle={
          add_sheet_subtitle(@featured.name, member_names(@featured_members), @add_sheet.index)
        }
        open
        on_close={JS.push("close-add-sheet")}
        class="pk-estantes-sheet--full"
      >
        <:commit>
          <div class="pk-donde-va-search">
            <input
              type="text"
              id="web-add-sheet-input"
              name="q"
              value={@add_sheet.query}
              placeholder="Buscá un juego"
              aria-label="Buscá un juego"
              autocomplete="off"
              phx-change="add-sheet-search"
              phx-debounce="200"
              onfocus="this.select()"
              data-pk-sheet-autofocus
            />
          </div>
        </:commit>

        <div :if={blank_query?(@add_sheet.query)} id="web-add-sheet-recent">
          <AdminComponents.list_section_label>Últimas novedades</AdminComponents.list_section_label>
          <AdminComponents.list_row
            :for={game <- @add_sheet.recent}
            id={"web-add-sheet-recent-#{game.id}"}
            cover={game.thumbnail_url}
            name={game.name}
            phx-click="add-sheet-pick"
            phx-value-game-id={game.id}
          />
        </div>

        <div
          :if={!blank_query?(@add_sheet.query) and @add_sheet.results != []}
          id="web-add-sheet-results"
        >
          <AdminComponents.list_row
            :for={game <- @add_sheet.results}
            id={"web-add-result-#{game.id}"}
            cover={game.thumbnail_url}
            name={game.name}
            meta={if game.id in @add_sheet.snapshot_ids, do: "Ya está en la fila · pasa a este lugar"}
            phx-click="add-sheet-pick"
            phx-value-game-id={game.id}
          />
        </div>

        <div
          :if={!blank_query?(@add_sheet.query) and @add_sheet.results == []}
          id="web-add-sheet-no-match"
          class="pk-estantes-no-match"
        >
          <p class="pk-estantes-no-match__hint">Ningún juego se llama así.</p>
          <%!-- ADD-07: a phx-click stub, NOT a navigate. Phase 01.8.8 (ADD-08)
          designs Web's real "create a game" flow in its own sketch round. --%>
          <AdminComponents.list_row
            id="web-add-create-row"
            name={"Crear «#{String.trim(@add_sheet.query)}»"}
            meta="Agregarlo al catálogo"
            phx-click="create-game-stub"
          />
        </div>
      </AdminComponents.sheet>

      <AdminComponents.snackbar
        :if={@placed}
        id="web-place-snackbar"
        message={placed_message(@placed)}
        action={%{label: "Deshacer", event: "undo-place"}}
        on_close={JS.push("dismiss-place-snackbar")}
      />

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
end
