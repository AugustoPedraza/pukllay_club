defmodule PukllayClubWeb.Admin.EstanteLive.Administrar do
  @moduledoc """
  `/admin/estantes/administrar` (D-08, D-09, D-10, plan 01.8.2-18) — the
  rare management job behind the gear: create, rename, reorder and
  delete estantes. Finding/placing/moving/removing a box already
  happens on `/admin/estantes` (D-08's own revision 45), so an estante
  row here carries **no chevron** and there is no `/admin/estantes/:id`
  route — tapping a row opens its options sheet in place.

  **Rows:** estante icon · name · `N juegos` (batched via
  `Shelves.counts_for_shelves/1`, never one query per row — T-01.8.2-86).
  Tapping one opens its options sheet (Editar / Eliminar).

  **One name sheet serves both Nuevo estante and Editar** (D-08): the
  field is pre-filled and selected — `Estante {next}` for a new one, the
  current name for an edit — with the hint "Un nombre que se reconozca
  en el salón.". Both errors (empty, duplicate) surface inside the
  sheet; the duplicate error comes straight from `Shelf`'s own
  `unique_constraint(:name)` (T-01.8.2-84: never a pre-check query,
  which would just reopen the race the constraint already closes).

  **Eliminar (D-10, D-19f, T-01.8.2-83):** a destructive row in the
  options sheet opens `AdminComponents.dialog/1` — never an in-sheet
  confirm. The consequence line states the real, currently-displayed
  copy count for that estante; confirming calls `Shelves.delete_shelf/1`
  (T-01.8.2-81/82's own locked snapshot-then-clear-then-delete), and the
  resulting snackbar's Deshacer calls `Shelves.restore_deleted_shelf/1`
  to put the whole arrangement — the estante AND every copy's exact
  former position — back in one shot.

  **Ordenar→Listo (D-08, plan 01.8.2-15's `AdminComponents.reorder_header/1`
  + `reorder_row/1`, this module is their SECOND consumer):** a
  page-level mode swap (per D-08's own management-page decision — the
  header itself becomes "Ordenar estantes" + Listo, no back link, unlike
  Web's LOCAL-scope Ordenar), with the exact same tap-reveal-↑/↓ shape.
  `Listo` shows `Orden guardado` with a 10s Deshacer that restores the
  pre-mode order via a selection-sort of adjacent `Shelves.move_shelf/2`
  swaps (mirrors `SectionLive.Index`'s `restore_section_order/1` — no
  new bulk-reorder function was added for this, matching that
  precedent). The committed `shelves.position` order (`Shelves.
  list_shelves/0`) is the order used everywhere estantes are listed —
  this list, and "O elegí un estante" in «¿Dónde va?».

  **First run (D-09):** zero estantes renders one line of purpose and
  Nuevo estante as the ONLY visible page action — Ordenar is hidden
  entirely at zero estantes (reordering nothing makes no sense, and a
  second visible action would contradict D-09's "one action"). No
  wizard, no checklist, no seeded room layout.

  Subscribes to `"admin:estantes"` (D-11) and reloads the row list,
  counts and order on every broadcast.

  Lives inside the existing `live_session :require_staff` block — a
  signed-out visitor is redirected before this module ever mounts.
  """
  use PukllayClubWeb, :live_view

  alias Phoenix.LiveView.JS
  alias PukllayClub.Catalog.Shelves
  alias PukllayClubWeb.AdminComponents

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PukllayClub.PubSub, "admin:estantes")
    end

    {:ok,
     socket
     |> assign(:page_title, "Administrar estantes")
     |> assign(:selected_shelf, nil)
     |> assign(:name_sheet, nil)
     |> assign(:confirm_delete, nil)
     |> assign(:deleted_shelf, nil)
     |> assign(:reorder_mode, false)
     |> assign(:revealed_shelf_id, nil)
     |> assign(:reorder_snapshot, nil)
     |> assign(:undo_snapshot, nil)
     |> assign(:info_snackbar, nil)
     |> load_shelves()}
  end

  @impl true
  def handle_info({:estante_updated, _shelf_id}, socket) do
    {:noreply, load_shelves(socket)}
  end

  # ------------------------------------------------------------------
  # The estante row's options sheet (D-19e)
  # ------------------------------------------------------------------

  @impl true
  def handle_event("open-shelf-options", %{"shelf-id" => id}, socket) do
    case parse_id(id) do
      nil -> {:noreply, socket}
      int_id -> {:noreply, assign(socket, :selected_shelf, find_shelf(socket, int_id))}
    end
  end

  @impl true
  def handle_event("close-shelf-options", _params, socket) do
    {:noreply, assign(socket, :selected_shelf, nil)}
  end

  # ------------------------------------------------------------------
  # The one name sheet — Nuevo estante and Editar (D-08 decision 67)
  # ------------------------------------------------------------------

  @impl true
  def handle_event("open-new-shelf", _params, socket) do
    next_name = "Estante #{length(socket.assigns.shelves) + 1}"
    {:noreply, assign(socket, :name_sheet, %{mode: :new, shelf: nil, name: next_name, error: nil})}
  end

  @impl true
  def handle_event("open-edit-shelf", _params, socket) do
    shelf = socket.assigns.selected_shelf

    {:noreply,
     socket
     |> assign(:selected_shelf, nil)
     |> assign(:name_sheet, %{mode: :edit, shelf: shelf, name: shelf.name, error: nil})}
  end

  @impl true
  def handle_event("close-name-sheet", _params, socket) do
    {:noreply, assign(socket, :name_sheet, nil)}
  end

  # Typing clears any error the previous attempt surfaced (D-08 decision 67).
  @impl true
  def handle_event("validate-name", %{"name" => name}, socket) do
    {:noreply, update(socket, :name_sheet, fn sheet -> %{sheet | name: name, error: nil} end)}
  end

  @impl true
  def handle_event("save-name", %{"name" => name}, socket) do
    case socket.assigns.name_sheet do
      %{mode: :new} -> {:noreply, create_shelf(socket, name)}
      %{mode: :edit, shelf: shelf} -> {:noreply, rename_shelf(socket, shelf, name)}
    end
  end

  @impl true
  def handle_event("dismiss-info-snackbar", _params, socket) do
    {:noreply, assign(socket, :info_snackbar, nil)}
  end

  # ------------------------------------------------------------------
  # Eliminar (D-10, D-19f) — the dialog, the consequence, the undo
  # ------------------------------------------------------------------

  @impl true
  def handle_event("ask-delete", _params, socket) do
    shelf = socket.assigns.selected_shelf
    count = Map.get(socket.assigns.counts, shelf.id, 0)

    {:noreply,
     socket
     |> assign(:selected_shelf, nil)
     |> assign(:confirm_delete, %{shelf: shelf, count: count})}
  end

  @impl true
  def handle_event("cancel-delete", _params, socket) do
    {:noreply, assign(socket, :confirm_delete, nil)}
  end

  @impl true
  def handle_event("confirm-delete", _params, socket) do
    shelf = socket.assigns.confirm_delete.shelf

    case Shelves.delete_shelf(shelf) do
      {:ok, snapshot} ->
        {:noreply,
         socket
         |> assign(:confirm_delete, nil)
         |> assign(:deleted_shelf, snapshot)
         |> load_shelves()}

      {:error, _reason} ->
        {:noreply, assign(socket, :confirm_delete, nil)}
    end
  end

  @impl true
  def handle_event("undo-delete", _params, socket) do
    case socket.assigns.deleted_shelf do
      nil ->
        {:noreply, socket}

      snapshot ->
        # WR-02: `restore_deleted_shelf/1` re-inserts a shelf row through
        # `Shelf.changeset/2`'s `unique_constraint(:name)` — if a shelf with
        # this exact name has been (re)created in the interim (plausible:
        # staff commonly re-create a shelf right after deleting it, or two
        # staff members are both managing estantes at once), it returns
        # `{:error, changeset}` instead of `{:ok, shelf}`. Handle that
        # branch rather than crashing the LiveView on a `MatchError`.
        case Shelves.restore_deleted_shelf(snapshot) do
          {:ok, _shelf} ->
            {:noreply, socket |> assign(:deleted_shelf, nil) |> load_shelves()}

          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(:deleted_shelf, nil)
             |> put_flash(:error, "No se pudo deshacer: ya existe un estante con ese nombre.")}
        end
    end
  end

  @impl true
  def handle_event("dismiss-delete-snackbar", _params, socket) do
    {:noreply, assign(socket, :deleted_shelf, nil)}
  end

  # ------------------------------------------------------------------
  # Ordenar → Listo (D-08 decision 68, plan 01.8.2-15's shared atoms)
  # ------------------------------------------------------------------

  @impl true
  def handle_event("start-reorder", _params, socket) do
    {:noreply,
     socket
     |> assign(:reorder_mode, true)
     |> assign(:revealed_shelf_id, nil)
     |> assign(:reorder_snapshot, Enum.map(socket.assigns.shelves, & &1.id))}
  end

  @impl true
  def handle_event("done-reorder", _params, socket) do
    {:noreply,
     socket
     |> assign(:reorder_mode, false)
     |> assign(:revealed_shelf_id, nil)
     |> assign(:undo_snapshot, socket.assigns.reorder_snapshot)
     |> assign(:reorder_snapshot, nil)}
  end

  @impl true
  def handle_event("undo-reorder", _params, socket) do
    case socket.assigns.undo_snapshot do
      nil ->
        {:noreply, socket}

      snapshot ->
        restore_shelf_order(snapshot)
        {:noreply, socket |> assign(:undo_snapshot, nil) |> load_shelves()}
    end
  end

  @impl true
  def handle_event("dismiss-reorder-snackbar", _params, socket) do
    {:noreply, assign(socket, :undo_snapshot, nil)}
  end

  @impl true
  def handle_event("reveal-shelf", %{"id" => id}, socket) do
    case parse_id(id) do
      nil -> {:noreply, socket}
      int_id -> {:noreply, assign(socket, :revealed_shelf_id, int_id)}
    end
  end

  @impl true
  def handle_event("move-up", %{"shelf-id" => id}, socket), do: move(socket, id, :up)

  @impl true
  def handle_event("move-down", %{"shelf-id" => id}, socket), do: move(socket, id, :down)

  # ------------------------------------------------------------------
  # Private helpers
  # ------------------------------------------------------------------

  defp load_shelves(socket) do
    shelves = Shelves.list_shelves()
    counts = Shelves.counts_for_shelves(Enum.map(shelves, & &1.id))

    socket
    |> assign(:shelves, shelves)
    |> assign(:counts, counts)
  end

  defp find_shelf(socket, id), do: Enum.find(socket.assigns.shelves, &(&1.id == id))

  defp create_shelf(socket, name) do
    case Shelves.create_shelf(%{name: name}) do
      {:ok, _shelf} ->
        socket
        |> assign(:name_sheet, nil)
        |> assign(:info_snackbar, %{message: "Estante creado"})
        |> load_shelves()

      {:error, changeset} ->
        put_name_sheet_error(socket, name, changeset)
    end
  end

  defp rename_shelf(socket, shelf, name) do
    case Shelves.rename_shelf(shelf, name) do
      {:ok, _shelf} ->
        socket = socket |> assign(:name_sheet, nil) |> load_shelves()
        if shelf.name == name, do: socket, else: assign(socket, :info_snackbar, %{message: "Nombre guardado"})

      {:error, changeset} ->
        put_name_sheet_error(socket, name, changeset)
    end
  end

  defp put_name_sheet_error(socket, name, changeset) do
    error = changeset.errors |> translate_errors(:name) |> List.first()
    update(socket, :name_sheet, fn sheet -> %{sheet | name: name, error: error} end)
  end

  defp move(socket, id, direction) do
    case parse_id(id) do
      nil ->
        {:noreply, socket}

      int_id ->
        {:ok, _shelf} = int_id |> Shelves.get_shelf!() |> Shelves.move_shelf(direction)
        {:noreply, load_shelves(socket)}
    end
  end

  # Restores `@shelves` to `target_ids`' order using ONLY
  # `Shelves.move_shelf/2`'s existing adjacent-swap primitive — mirrors
  # `SectionLive.Index.restore_section_order/1` exactly, no new bulk-
  # reorder context function.
  defp restore_shelf_order(target_ids) do
    Enum.reduce(0..(length(target_ids) - 1), :ok, fn index, :ok ->
      wanted_id = Enum.at(target_ids, index)
      bubble_shelf_to(wanted_id, index)
    end)
  end

  defp bubble_shelf_to(shelf_id, target_index) do
    current_ids = Enum.map(Shelves.list_shelves(), & &1.id)
    current_index = Enum.find_index(current_ids, &(&1 == shelf_id))

    if current_index && current_index > target_index do
      {:ok, _shelf} = shelf_id |> Shelves.get_shelf!() |> Shelves.move_shelf(:up)
      bubble_shelf_to(shelf_id, target_index)
    else
      :ok
    end
  end

  defp parse_id(id) when is_integer(id), do: id

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int_id, ""} -> int_id
      _not_an_integer -> nil
    end
  end

  defp parse_id(_other), do: nil

  defp name_sheet_title(:new), do: "Nuevo estante"
  defp name_sheet_title(:edit), do: "Editar estante"

  defp name_sheet_commit_label(:new), do: "Crear estante"
  defp name_sheet_commit_label(:edit), do: "Guardar"

  # Decision 67: "N estantes" when creating, "N juegos" when editing —
  # the sheet's own context line names what the field's value will
  # apply to.
  defp name_sheet_subtitle(%{mode: :new}, shelves, _counts), do: "#{length(shelves)} estantes"

  defp name_sheet_subtitle(%{mode: :edit, shelf: shelf}, _shelves, counts) do
    "#{Map.get(counts, shelf.id, 0)} juegos"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      bottom_collapse
      admin_chrome
      active_tab={:estantes}
    >
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <AdminComponents.back_row :if={!@reorder_mode} to={~p"/admin/estantes"} label="Estantes" />

        <AdminComponents.reorder_header
          :if={@reorder_mode}
          title="Ordenar estantes"
          on_done={JS.push("done-reorder")}
        />

        <%!-- The header actions come BEFORE the `<h1>` in DOM order and are
        absolutely positioned (`.pk-administrar-header-actions`,
        `.pk-administrar` itself is the `position: relative` anchor) — the
        SAME idiom `estante_live/index.ex` established, for the SAME reason
        (see that file's own comment on its `pk-estantes-header-actions`
        call site): `test/visual/admin_components.mjs`'s D3 check walks the
        `<h1>`'s own `nextElementSibling` to measure the page-head-to-body
        rhythm, and a title+icons flex row where the icons come AFTER the
        title in DOM broke that measurement AND shifted the title's own
        vertical position at narrower viewports where the icon row wraps
        (found live against this exact screen). Visual order (title left,
        icons right) is unaffected — it is drawn purely by
        `position: absolute`, not by DOM order. --%>
        <div :if={!@reorder_mode} id="administrar-page" class="pk-administrar">
          <div class="pk-administrar-header-actions">
            <AdminComponents.action
              :if={@shelves != []}
              anatomy="a3"
              role="terciaria"
              aria-label="Ordenar estantes"
              phx-click="start-reorder"
            >
              <.icon name="hero-arrows-up-down" class="size-5" />
            </AdminComponents.action>
            <AdminComponents.action
              anatomy="a2"
              role="terciaria"
              aria-label="Nuevo estante"
              phx-click="open-new-shelf"
            >
              Nuevo estante
            </AdminComponents.action>
          </div>
          <h1 class="pk-admin-page-title pk-administrar-title">Administrar estantes</h1>

          <p :if={@shelves == []} id="administrar-empty" class="pk-admin-empty-note">
            Creá los estantes en el orden en que los recorrés.
          </p>

          <div :if={@shelves != []} id="administrar-rows">
            <.estante_row
              :for={shelf <- @shelves}
              shelf={shelf}
              count={Map.get(@counts, shelf.id, 0)}
            />
          </div>
        </div>

        <div :if={@reorder_mode} id="administrar-reorder-rows">
          <AdminComponents.reorder_row
            :for={shelf <- @shelves}
            id={"reorder-shelf-#{shelf.id}"}
            revealed={@revealed_shelf_id == shelf.id}
            on_reveal={JS.push("reveal-shelf", value: %{"id" => shelf.id})}
            on_up={JS.push("move-up", value: %{"shelf-id" => shelf.id})}
            on_down={JS.push("move-down", value: %{"shelf-id" => shelf.id})}
            up_label={"Subir #{shelf.name}"}
            down_label={"Bajar #{shelf.name}"}
          >
            {shelf.name}
          </AdminComponents.reorder_row>
        </div>
      </div>

      <AdminComponents.sheet
        :if={@selected_shelf}
        id="shelf-options-sheet"
        title={@selected_shelf.name}
        subtitle={"#{Map.get(@counts, @selected_shelf.id, 0)} juegos"}
        open
        on_close={JS.push("close-shelf-options")}
      >
        <AdminComponents.action anatomy="a4" role="terciaria" phx-click="open-edit-shelf">
          Editar
        </AdminComponents.action>
        <AdminComponents.action anatomy="a4" role="peligro" phx-click="ask-delete">
          Eliminar
        </AdminComponents.action>
      </AdminComponents.sheet>

      <AdminComponents.sheet
        :if={@name_sheet}
        id="shelf-name-sheet"
        title={name_sheet_title(@name_sheet.mode)}
        subtitle={name_sheet_subtitle(@name_sheet, @shelves, @counts)}
        open
        on_close={JS.push("close-name-sheet")}
      >
        <form
          id="shelf-name-form"
          phx-change="validate-name"
          phx-submit="save-name"
          class="pk-admin-stacked-form"
        >
          <AdminComponents.field
            id="shelf-name-input"
            name="name"
            type="text"
            label="Nombre"
            value={@name_sheet.name}
            errors={if @name_sheet.error, do: [@name_sheet.error], else: []}
            maxlength="40"
            autocomplete="off"
            onfocus="this.select()"
          />
          <p class="pk-admin-empty-note">Un nombre que se reconozca en el salón.</p>
          <AdminComponents.action anatomy="a1" role="principal" type="submit">
            {name_sheet_commit_label(@name_sheet.mode)}
          </AdminComponents.action>
        </form>
      </AdminComponents.sheet>

      <AdminComponents.dialog
        :if={@confirm_delete}
        id="confirm-delete-shelf-dialog"
        question={"¿Eliminar #{@confirm_delete.shelf.name}?"}
        consequence={"Sus #{@confirm_delete.count} juegos quedan sin lugar hasta que los vuelvas a ubicar."}
        verb="Eliminar"
        open
        on_confirm={JS.push("confirm-delete")}
        on_cancel={JS.push("cancel-delete")}
      />

      <AdminComponents.snackbar
        :if={@deleted_shelf}
        id="delete-shelf-snackbar"
        message="Estante eliminado"
        action={%{label: "Deshacer", event: "undo-delete"}}
        on_close={JS.push("dismiss-delete-snackbar")}
      />

      <AdminComponents.snackbar
        :if={@undo_snapshot}
        id="administrar-reorder-snackbar"
        message="Orden guardado"
        action={%{label: "Deshacer", event: "undo-reorder"}}
        on_close={JS.push("dismiss-reorder-snackbar")}
      />

      <AdminComponents.snackbar
        :if={@info_snackbar}
        id="administrar-info-snackbar"
        message={@info_snackbar.message}
        on_close={JS.push("dismiss-info-snackbar")}
      />
    </Layouts.app>
    """
  end

  attr :shelf, :any, required: true
  attr :count, :integer, required: true

  # Composes directly against `.pk-admin-row`'s own established classes
  # (`admin_components.ex`'s `list_row/1` CSS shape, plan 01.8.2-08) —
  # not a fork of that component, since `list_row/1`'s `cover` attr only
  # ever renders an `<img>` and this row needs an estante GLYPH tile
  # instead of a game cover. Mirrors 01.8.2-15's own `niveles_row/1`
  # precedent for the identical situation (compose against the shared
  # shape rather than adding a new atom for one caller). No chevron
  # (D-19i) — this row opens a sheet in place, never a page.
  defp estante_row(assigns) do
    ~H"""
    <div
      id={"shelf-row-#{@shelf.id}"}
      class="pk-admin-row"
      tabindex="0"
      data-pk-pressable="true"
      phx-click="open-shelf-options"
      phx-value-shelf-id={@shelf.id}
    >
      <span class="pk-admin-administrar-row__icon" aria-hidden="true">
        <.icon name="hero-archive-box" class="size-5" />
      </span>
      <span class="pk-admin-row__body">
        <span class="pk-admin-row__name">{@shelf.name}</span>
        <span class="pk-admin-row__meta">{@count} juegos</span>
      </span>
    </div>
    """
  end
end
