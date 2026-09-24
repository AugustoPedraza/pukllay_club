defmodule PukllayClubWeb.Admin.EstanteLive.Index do
  @moduledoc """
  `/admin/estantes` (D-08, plan 01.8.2-13) — search-first, one job: find a
  box. This is the real screen the phase tracer (01.8.2-01) was standing
  in for; the tracer's `?estante=` picker is gone outright, replaced by
  D-08's search: idle shows only the prompt and the 48px field, focusing
  the empty field shows up to 3 `Últimas búsquedas` (this LiveView's own
  session state, never persisted), typing shows suggestions via
  `Shelves.search_copies/1`, and picking one raises the page and opens the
  picked copy's estante as a rail (`Shelves.copies_on_shelf/1`) with that
  copy lifted.

  **D-00c (plan 01.8.2-16): placing and moving.** A copy with no spot
  opens the full-height «¿Dónde va?» sheet the instant it is selected —
  no intermediate button (`select_copy_struct/2` below). Its search
  (`Shelves.search_estantes_or_copies/2`) finds an estante by name or an
  already-placed game (resolving to its estante); choosing an empty
  estante places the copy directly as its first box, otherwise staff pick
  the exact spot — before the first box, between any two, or after the
  last — rendered as N+1 "+" slots whose 0-based index is passed straight
  to `Shelves.place_copy/3` with no translation layer. Moving (Task 3's
  `open-mover`, fired from the selected cover's options sheet) opens the
  SAME sheet: the copy keeps its old spot until a new one is chosen, then
  both changes commit through `place_copy/3`'s own single locked
  transaction — never a remove-then-place two-step (T-01.8.2-71).
  Every completed place/move/removal is undoable via `Shelves.
  restore_position/3` (`@undo_snapshot`, `@action_snackbar` — one Deshacer
  mechanism shared by every write this screen makes).

  **`?copy=<id>` (plan 01.8.2-18):** Pendientes' own rows (Sin ubicar,
  and Afuera once Phase 4 exists) navigate here with that literal
  query param instead of inventing a second selection mechanism —
  `mount/3` reads it and calls the SAME `select_copy_struct/2` a
  suggestion-row tap uses, so a Sin ubicar copy opens «¿Dónde va?»
  immediately (its own `shelf_id` is `nil`) and an Afuera copy lands on
  its estante's rail with itself lifted, exactly as picking it from the
  search dropdown would. An unknown/malformed id is silently ignored
  (falls through to the normal idle state) rather than raising, since a
  stale link should degrade, not error.

  Header: a 44px A3 Pendientes icon carrying D-19g's count badge
  (`Shelves.unplaced_copies/0`'s length — the SAME source the dashboard
  box reads, so the two counts can never disagree) followed by the
  Administrar estantes gear. Both navigate to routes plan 01.8.2-18
  creates — rendered as plain string `navigate` paths (not `~p`, which
  would fail to compile against a route that does not exist yet).

  Subscribes to `"admin:estantes"` (mirrors `Admin.GameLive.Index`'s
  `"admin:games"` subscription) and re-reads live per D-11: a broadcast
  for the estante currently on screen re-renders the rail; a broadcast for
  any other estante only refreshes the Pendientes badge, leaving the
  rail's scroll position alone; and if the SELECTED copy's own location
  changed underneath the viewing staff member (place/move/remove by
  someone else), a quiet 4-second snackbar says so via the shared admin
  snackbar mechanism (`Layouts.admin_flash/1`, D-19c) rather than a
  bespoke one. `Shelves.place_copy/3`/`remove_copy_from_shelf/1`'s own
  transaction re-reads the copy inside the lock (T-01.8.2-73), so a
  client-held slot index can never act on a copy the write path itself
  did not just verify.

  This route lives inside the existing `live_session :require_staff`
  block (T-01.8.2-03) — a signed-out visitor is redirected before this
  module ever mounts. No `/admin/estantes/:id` route exists or is added
  here (D-08: an estante has no page of its own).
  """
  use PukllayClubWeb, :live_view

  alias Phoenix.LiveView.JS
  alias PukllayClub.Catalog.Shelves
  alias PukllayClubWeb.Admin.PlacementSheet
  alias PukllayClubWeb.AdminComponents

  # D-08: "Últimas búsquedas (3)" — a per-session, in-memory recency list,
  # never written to the database (this is not a history feature).
  @max_recent 3

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PukllayClub.PubSub, "admin:estantes")
    end

    socket =
      socket
      |> assign(:page_title, "Estantes")
      |> assign(:query, "")
      |> assign(:suggestions, [])
      |> assign(:recent_searches, [])
      |> assign(:selected_copy, nil)
      |> assign(:copies, [])
      |> assign(:copy_counts, %{})
      |> assign(:pending_count, pending_count())
      |> assign(:donde_va, nil)
      |> assign(:que_va_aca, nil)
      |> assign(:cover_options_open, false)
      |> assign(:confirm_remove, nil)
      |> assign(:undo_snapshot, nil)
      |> assign(:action_snackbar, nil)
      |> assign(:landed_copy_id, nil)

    {:ok, apply_copy_param(socket, params)}
  end

  defp apply_copy_param(socket, %{"copy" => raw_id}) do
    case parse_id(raw_id) do
      nil -> socket
      id -> select_copy_from_param(socket, id)
    end
  end

  defp apply_copy_param(socket, _params), do: socket

  defp select_copy_from_param(socket, id) do
    copy = Shelves.get_copy!(id)
    select_copy_struct(socket, copy)
  rescue
    Ecto.NoResultsError -> socket
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    query = String.slice(q, 0, 120)

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:suggestions, Shelves.search_copies(query))}
  end

  @impl true
  def handle_event("pick-copy", %{"copy-id" => raw_id}, socket) do
    case parse_id(raw_id) do
      nil -> {:noreply, socket}
      id -> {:noreply, select_copy(socket, id)}
    end
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply, reset_to_idle(socket)}
  end

  # ------------------------------------------------------------------
  # «¿Dónde va?» — placing/moving (D-00c, plan 01.8.2-16)
  # ------------------------------------------------------------------

  @impl true
  def handle_event("open-mover", _params, socket) do
    {:noreply,
     socket
     |> assign(:cover_options_open, false)
     |> open_donde_va(socket.assigns.selected_copy)}
  end

  @impl true
  def handle_event("donde-va-search", %{"q" => q}, socket) do
    query = String.slice(q, 0, 120)
    {:noreply, update(socket, :donde_va, &PlacementSheet.search(&1, query))}
  end

  @impl true
  def handle_event("donde-va-field-clear", _params, socket) do
    {:noreply, update(socket, :donde_va, &PlacementSheet.field_clear/1)}
  end

  @impl true
  def handle_event("donde-va-pick-estante", %{"shelf-id" => id}, socket) do
    shelf = Shelves.get_shelf!(String.to_integer(id))
    {:noreply, apply_donde_va_pick(socket, PlacementSheet.pick_estante(socket.assigns.donde_va, shelf))}
  end

  @impl true
  def handle_event("donde-va-pick-copy", %{"copy-id" => id}, socket) do
    copy = Shelves.get_copy!(String.to_integer(id))
    {:noreply, apply_donde_va_pick(socket, PlacementSheet.pick_copy(socket.assigns.donde_va, copy))}
  end

  @impl true
  def handle_event("donde-va-commit", %{"index" => idx}, socket) do
    shelf = socket.assigns.donde_va.estante
    {:noreply, commit_donde_va(socket, shelf.id, String.to_integer(idx))}
  end

  @impl true
  def handle_event("donde-va-close", _params, socket) do
    donde_va = socket.assigns.donde_va
    socket = assign(socket, :donde_va, nil)

    # Decision 37/39: ✕ / tap outside / Esc cancels — for a genuinely
    # unplaced copy (this was a PLACE, not a MOVE) there is nothing left
    # to show, so the screen returns to idle. A move leaves the copy
    # exactly where it was (nothing was ever written before commit), so
    # the underlying answered view is simply left as-is.
    if donde_va && is_nil(donde_va.copy.shelf_id) do
      {:noreply, reset_to_idle(socket)}
    else
      {:noreply, socket}
    end
  end

  # ------------------------------------------------------------------
  # "+" slots and «¿Qué juego va acá?» (D-08, plan 01.8.2-16)
  # ------------------------------------------------------------------

  @impl true
  def handle_event("open-que-va-aca", %{"index" => idx}, socket) do
    index = String.to_integer(idx)
    copy = socket.assigns.selected_copy
    snapshot_ids = Enum.map(socket.assigns.copies, & &1.id)

    {:noreply,
     assign(socket, :que_va_aca, %{
       shelf_id: copy.shelf_id,
       index: index,
       query: "",
       results: [],
       snapshot_ids: snapshot_ids
     })}
  end

  @impl true
  def handle_event("que-va-aca-search", %{"q" => q}, socket) do
    query = String.slice(q, 0, 120)
    results = if query == "", do: [], else: Shelves.search_copies(query)
    {:noreply, update(socket, :que_va_aca, fn qva -> %{qva | query: query, results: results} end)}
  end

  @impl true
  def handle_event("que-va-aca-pick", %{"copy-id" => id}, socket) do
    qva = socket.assigns.que_va_aca
    current_ids = qva.shelf_id |> Shelves.copies_on_shelf() |> Enum.map(& &1.id)

    if current_ids == qva.snapshot_ids do
      copy = Shelves.get_copy!(String.to_integer(id))
      {:noreply, commit_que_va_aca(socket, qva, copy)}
    else
      {:noreply,
       socket
       |> assign(:que_va_aca, nil)
       |> put_flash(:info, "El estante cambió mientras elegías un juego. Probá de nuevo.")}
    end
  end

  @impl true
  def handle_event("que-va-aca-close", _params, socket) do
    {:noreply, assign(socket, :que_va_aca, nil)}
  end

  # ------------------------------------------------------------------
  # The selected cover's options sheet and Quitar del estante (D-08,
  # D-19f, D-19e, plan 01.8.2-16)
  # ------------------------------------------------------------------

  @impl true
  def handle_event("open-cover-options", %{"copy-id" => _id}, socket) do
    {:noreply, assign(socket, :cover_options_open, true)}
  end

  @impl true
  def handle_event("close-cover-options", _params, socket) do
    {:noreply, assign(socket, :cover_options_open, false)}
  end

  @impl true
  def handle_event("ask-quitar", _params, socket) do
    {:noreply,
     socket
     |> assign(:cover_options_open, false)
     |> assign(:confirm_remove, socket.assigns.selected_copy)}
  end

  @impl true
  def handle_event("cancel-quitar", _params, socket) do
    {:noreply, assign(socket, :confirm_remove, nil)}
  end

  @impl true
  def handle_event("confirm-quitar", _params, socket) do
    copy = socket.assigns.confirm_remove
    previous = %{shelf_id: copy.shelf_id, position: copy.position}

    case Shelves.remove_copy_from_shelf(copy.id) do
      {:ok, removed} ->
        {:noreply,
         socket
         |> assign(:confirm_remove, nil)
         |> assign(:undo_snapshot, %{copy_id: removed.id, shelf_id: previous.shelf_id, position: previous.position})
         |> assign(:action_snackbar, %{
           id: "estantes-action-snackbar",
           message: "Juego quitado del estante",
           action: %{label: "Deshacer", event: "undo-place"}
         })
         |> reset_to_idle()}

      {:error, _reason} ->
        {:noreply, assign(socket, :confirm_remove, nil)}
    end
  end

  # ------------------------------------------------------------------
  # The one shared Deshacer mechanism for every write this screen makes
  # ------------------------------------------------------------------

  @impl true
  def handle_event("undo-place", _params, socket) do
    case socket.assigns.undo_snapshot do
      nil ->
        {:noreply, socket}

      %{copy_id: copy_id, shelf_id: shelf_id, position: position} ->
        socket = socket |> assign(:undo_snapshot, nil) |> assign(:action_snackbar, nil)

        case Shelves.restore_position(copy_id, shelf_id, position) do
          {:ok, restored} -> {:noreply, maybe_show_restored(socket, restored)}
          {:error, _reason} -> {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_event("dismiss-action-snackbar", _params, socket) do
    {:noreply, socket |> assign(:action_snackbar, nil) |> assign(:undo_snapshot, nil)}
  end

  @impl true
  def handle_info({:estante_updated, shelf_id}, socket) do
    socket = assign(socket, :pending_count, pending_count())
    {:noreply, reconcile_selection(socket, shelf_id)}
  end

  # No copy currently selected — nothing on screen can be stale, only the
  # Pendientes badge (already refreshed above) can have changed.
  defp reconcile_selection(%{assigns: %{selected_copy: nil}} = socket, _shelf_id), do: socket

  defp reconcile_selection(%{assigns: %{selected_copy: %{shelf_id: current}}} = socket, shelf_id)
       when current != shelf_id do
    # D-11: "a broadcast for a different estante ... does not disturb the
    # rail's scroll position" — leaving every rail-related assign
    # untouched is what keeps the LiveView diff empty for this branch.
    socket
  end

  defp reconcile_selection(%{assigns: %{selected_copy: old_copy}} = socket, _shelf_id) do
    fresh = Shelves.get_copy!(old_copy.id)

    if fresh.shelf_id != old_copy.shelf_id or fresh.position != old_copy.position do
      # D-11: "if a copy you are acting on changed underneath you, a quiet
      # snackbar says so" — routed through the shared admin snackbar
      # (`Layouts.admin_flash/1`, D-19c) rather than composing a second,
      # bespoke one; no `action`, so it takes the default 4s duration.
      socket
      |> put_flash(:info, "«#{fresh.game.name}» cambió de lugar.")
      |> select_copy_struct(fresh)
    else
      reload_rail(socket, fresh)
    end
  rescue
    Ecto.NoResultsError ->
      socket
      |> assign(:selected_copy, nil)
      |> assign(:copies, [])
      |> assign(:copy_counts, %{})
  end

  defp reload_rail(socket, copy) do
    socket
    |> assign(:selected_copy, copy)
    |> load_rail(copy)
  end

  defp select_copy(socket, id) do
    copy = Shelves.get_copy!(id)

    socket
    |> select_copy_struct(copy)
    |> update(:recent_searches, &push_recent_list(&1, copy))
  rescue
    Ecto.NoResultsError -> socket
  end

  defp select_copy_struct(socket, copy) do
    socket =
      socket
      |> assign(:selected_copy, copy)
      |> assign(:query, copy.game.name)
      |> assign(:suggestions, [])
      |> assign(:cover_options_open, false)
      |> assign(:que_va_aca, nil)
      |> assign(:landed_copy_id, nil)
      |> load_rail(copy)

    # D-00c (estante-ui-restart decision 36): a game with no spot opens
    # "¿Dónde va?" the instant it is selected — no intermediate button.
    if is_nil(copy.shelf_id), do: open_donde_va(socket, copy), else: socket
  end

  defp load_rail(socket, %{shelf_id: nil}) do
    socket
    |> assign(:copies, [])
    |> assign(:copy_counts, %{})
  end

  defp load_rail(socket, %{shelf_id: shelf_id}) do
    copies = Shelves.copies_on_shelf(shelf_id)
    game_ids = Enum.map(copies, & &1.game_id)

    socket
    |> assign(:copies, copies)
    |> assign(:copy_counts, Shelves.counts_for_games(game_ids))
  end

  defp reset_to_idle(socket) do
    socket
    |> assign(:selected_copy, nil)
    |> assign(:query, "")
    |> assign(:suggestions, [])
    |> assign(:copies, [])
    |> assign(:copy_counts, %{})
    |> assign(:cover_options_open, false)
    |> assign(:donde_va, nil)
    |> assign(:que_va_aca, nil)
    |> assign(:landed_copy_id, nil)
  end

  defp open_donde_va(socket, copy) do
    assign(socket, :donde_va, PlacementSheet.open(copy))
  end

  # `PlacementSheet.pick_estante/2`/`pick_copy/2` return `{:commit, ...}`
  # for an empty estante (decision 35) or `{:choose_slot, state}` once
  # the "+" rail is loaded for staff to pick the exact spot.
  defp apply_donde_va_pick(socket, {:commit, shelf_id, index}), do: commit_donde_va(socket, shelf_id, index)
  defp apply_donde_va_pick(socket, {:choose_slot, donde_va}), do: assign(socket, :donde_va, donde_va)

  defp commit_donde_va(socket, shelf_id, index) do
    copy = socket.assigns.donde_va.copy

    socket
    |> assign(:donde_va, nil)
    |> commit_placement(copy, shelf_id, index)
  end

  defp commit_que_va_aca(socket, %{shelf_id: shelf_id, index: index}, copy) do
    socket
    |> assign(:que_va_aca, nil)
    |> commit_placement(copy, shelf_id, index)
  end

  # The one write path behind every "landing" this screen does — Task 1's
  # «¿Dónde va?» commit and Task 2's «¿Qué juego va acá?» commit both
  # funnel through here, so there is exactly one place that decides the
  # snackbar wording, snapshots the undo, and refreshes whichever rail is
  # currently on screen.
  defp commit_placement(socket, copy, shelf_id, index) do
    # WR-01: the previous location comes from `place_copy/3`'s own return
    # (verified under its advisory lock), never from `copy` above — that
    # struct can be stale by the time this commits if a different staff
    # member moved this exact copy while the «¿Dónde va?»/«¿Qué juego va
    # acá?» sheet was still open (PubSub reconciliation here only ever
    # refreshes what's RENDERED, never this already-captured `copy`).
    case Shelves.place_copy(copy.id, shelf_id, index) do
      {:ok, %{moved: moved, previous_shelf_id: previous_shelf_id, previous_position: previous_position}} ->
        fresh = Shelves.get_copy!(moved.id)
        message = if is_nil(previous_shelf_id), do: "Juego ubicado", else: "Juego movido"

        socket
        |> refresh_after_write(fresh)
        |> assign(:undo_snapshot, %{
          copy_id: fresh.id,
          shelf_id: previous_shelf_id,
          position: previous_position
        })
        |> assign(:action_snackbar, %{
          id: "estantes-action-snackbar",
          message: message,
          action: %{label: "Deshacer", event: "undo-place"}
        })
        |> assign(:landed_copy_id, fresh.id)

      {:error, _reason} ->
        socket
    end
  end

  defp refresh_after_write(%{assigns: %{selected_copy: %{id: id}}} = socket, %{id: id} = fresh) do
    reload_rail(socket, fresh)
  end

  defp refresh_after_write(%{assigns: %{selected_copy: %{shelf_id: shelf_id}}} = socket, %{shelf_id: shelf_id})
       when not is_nil(shelf_id) do
    load_rail(socket, socket.assigns.selected_copy)
  end

  defp refresh_after_write(socket, _fresh), do: socket

  defp maybe_show_restored(%{assigns: %{selected_copy: %{id: id}}} = socket, %{id: id} = restored) do
    fresh = Shelves.get_copy!(restored.id)
    reload_rail(socket, fresh)
  end

  defp maybe_show_restored(%{assigns: %{selected_copy: %{shelf_id: shelf_id}}} = socket, %{shelf_id: shelf_id})
       when not is_nil(shelf_id) do
    load_rail(socket, socket.assigns.selected_copy)
  end

  defp maybe_show_restored(socket, _restored), do: socket

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> int
      _not_an_integer -> nil
    end
  end

  defp parse_id(_non_binary), do: nil

  defp pending_count, do: length(Shelves.unplaced_copies())

  defp pendientes_aria_label(0), do: "Pendientes"
  defp pendientes_aria_label(count), do: "Pendientes, #{count} pendientes"

  defp badge_text(count) when count > 99, do: "99+"
  defp badge_text(count), do: Integer.to_string(count)

  # D-03: "copia N de M" (N = the copy's own stable `number`, M = every
  # copy of that game, on or off any estante) appears only when the game
  # has more than one copy; "caja N de M" (D-04) always counts boxes on
  # THIS estante, from the real `position` order — never the render index
  # standing in for either number.
  defp cover_alt(copy, index, total_on_shelf, copy_counts) do
    caja = "caja #{index + 1} de #{total_on_shelf}"
    total_for_game = Map.get(copy_counts, copy.game_id, 1)

    if total_for_game > 1 do
      "#{copy.game.name}, copia #{copy.number} de #{total_for_game}, #{caja}"
    else
      "#{copy.game.name}, #{caja}"
    end
  end

  defp push_recent_list(recent, copy) do
    Enum.take([copy | Enum.reject(recent, &(&1.id == copy.id))], @max_recent)
  end

  # A "+" slot's accessible name (sketch 069, "Poner un juego entre X y
  # Y" / "...al principio de..." / "...al final de..."). `copies` is
  # whichever rail the slot sits in (the donde-va sheet's chosen estante,
  # or the page's own answered rail).
  defp slot_label([], _index, estante_name), do: "Poner al principio de #{estante_name}"

  defp slot_label(copies, 0, _estante_name) do
    "Poner antes de #{hd(copies).game.name}"
  end

  defp slot_label(copies, index, estante_name) when index == length(copies) do
    "Poner después de #{List.last(copies).game.name} en #{estante_name}"
  end

  defp slot_label(copies, index, _estante_name) do
    before = Enum.at(copies, index - 1)
    after_ = Enum.at(copies, index)
    "Poner entre #{before.game.name} y #{after_.game.name}"
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
        <div
          id="estantes-page"
          phx-hook="AdminRail"
          class="pk-estantes"
          data-raised={to_string(@selected_copy != nil)}
        >
          <%!-- The header icons come BEFORE the title in DOM order and are
          absolutely positioned (`.pk-estantes-header-actions`, `.pk-estantes`
          itself is the `position: relative` anchor) so `<h1>`'s own
          `nextElementSibling` is genuine body content, not a header
          sibling — `test/visual/admin_components.mjs`'s D3 check walks
          exactly that sibling to measure the page-head-to-body rhythm, and
          a title+icons flex row where the icons come AFTER the title in
          DOM broke that measurement (found live against this screen,
          `01.8.2-13`'s own Task 3 harness run). Visual order (title left,
          icons right) is unaffected — it is drawn purely by
          `position: absolute`, not by DOM order. --%>
          <div class="pk-estantes-header-actions">
            <span class="pk-estantes-icon-badge">
              <AdminComponents.action
                anatomy="a3"
                role="terciaria"
                aria-label={pendientes_aria_label(@pending_count)}
                navigate="/admin/estantes/pendientes"
              >
                <.icon name="hero-inbox" class="size-5" />
              </AdminComponents.action>
              <span
                :if={@pending_count > 0}
                class="pk-estantes-icon-badge__count"
                aria-hidden="true"
              >
                {badge_text(@pending_count)}
              </span>
            </span>
            <AdminComponents.action
              anatomy="a3"
              role="terciaria"
              aria-label="Administrar estantes"
              navigate="/admin/estantes/administrar"
            >
              <.icon name="hero-cog-6-tooth" class="size-5" />
            </AdminComponents.action>
          </div>
          <h1 class="pk-admin-page-title pk-estantes-title">Estantes</h1>

          <div :if={is_nil(@selected_copy)} class="pk-estantes-hero">
            <p class="pk-estantes-prompt">¿Qué juego buscás?</p>
          </div>

          <div id="estantes-search-wrap" class="pk-estantes-search-wrap">
            <form id="estantes-search-form" phx-change="search" class="pk-estantes-search">
              <input
                type="text"
                id="estantes-search-input"
                name="q"
                value={@query}
                placeholder="Buscá un juego"
                aria-label="Buscá un juego"
                autocomplete="off"
                phx-debounce="200"
                onfocus="this.select()"
              />
              <button
                :if={@query != "" or @selected_copy}
                type="button"
                class="pk-estantes-search__clear"
                aria-label="Limpiar búsqueda"
                phx-click="clear"
              >
                <.icon name="hero-x-mark" class="size-5" />
              </button>

              <div class="pk-estantes-dropdown" id="estantes-dropdown">
                <div :if={@query != "" and @suggestions != []} id="estantes-suggestions">
                  <.suggestion_row
                    :for={copy <- @suggestions}
                    id={"suggestion-#{copy.id}"}
                    copy={copy}
                  />
                </div>

                <div :if={@query != "" and @suggestions == []} class="pk-estantes-no-match">
                  <p class="pk-estantes-no-match__hint">Ningún juego se llama así.</p>
                  <AdminComponents.list_row
                    id="estantes-create-row"
                    name={"Crear «#{@query}»"}
                    meta="Agregarlo al catálogo"
                    navigate={~p"/admin/juegos?nombre=#{@query}"}
                    opens_page
                  />
                </div>

                <div :if={@query == "" and @recent_searches != []} id="estantes-recent">
                  <AdminComponents.list_section_label>
                    Últimas búsquedas
                  </AdminComponents.list_section_label>
                  <.suggestion_row
                    :for={copy <- @recent_searches}
                    id={"recent-#{copy.id}"}
                    copy={copy}
                  />
                </div>

                <p :if={@query == "" and @recent_searches == []} class="pk-estantes-no-recent">
                  Todavía no buscaste ningún juego.
                </p>
              </div>
            </form>
          </div>

          <div :if={is_nil(@selected_copy)} class="pk-estantes-spacer-bottom"></div>

          <div :if={@selected_copy} class="pk-estantes-answer">
            <div :if={@selected_copy.shelf} class="pk-estantes-estante-context">
              <.icon name="hero-archive-box" class="size-4" />
              <span>{@selected_copy.shelf.name}</span>
            </div>

            <div :if={@selected_copy.shelf} class="pk-rail-wrap">
              <div class="pk-rail" id="estantes-rail">
                <%= for {copy, index} <- Enum.with_index(@copies) do %>
                  <button
                    :if={copy.id == @selected_copy.id}
                    type="button"
                    class="pk-estantes-slot"
                    data-pk-pressable="true"
                    phx-click="open-que-va-aca"
                    phx-value-index={index}
                    aria-label={slot_label(@copies, index, @selected_copy.shelf.name)}
                  >
                    <span aria-hidden="true">+</span>
                  </button>
                  <button
                    type="button"
                    id={"estante-copy-#{copy.id}"}
                    class={[
                      "pk-poster-card",
                      "pk-estantes-cover",
                      copy.id == @selected_copy.id && "pk-estantes-cover--lifted",
                      copy.id == @landed_copy_id && "pk-estantes-cover--landed"
                    ]}
                    data-pk-pressable="true"
                    data-pk-rail-selected={to_string(copy.id == @selected_copy.id)}
                    phx-click={
                      if copy.id == @selected_copy.id, do: "open-cover-options", else: "pick-copy"
                    }
                    phx-value-copy-id={copy.id}
                    aria-label={cover_alt(copy, index, length(@copies), @copy_counts)}
                  >
                    <span class="pk-estantes-cover__art">
                      <img
                        :if={copy.game.thumbnail_url}
                        src={copy.game.thumbnail_url}
                        alt=""
                        class="pk-estantes-cover__img"
                      />
                      <span :if={!copy.game.thumbnail_url} class="pk-estantes-cover__fallback">
                        <.icon name="hero-puzzle-piece" class="size-8" />
                      </span>
                    </span>
                  </button>
                  <button
                    :if={copy.id == @selected_copy.id}
                    type="button"
                    class="pk-estantes-slot"
                    data-pk-pressable="true"
                    phx-click="open-que-va-aca"
                    phx-value-index={index + 1}
                    aria-label={slot_label(@copies, index + 1, @selected_copy.shelf.name)}
                  >
                    <span aria-hidden="true">+</span>
                  </button>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>

      <AdminComponents.placement_sheet :if={@donde_va} id="donde-va-sheet" state={@donde_va} />

      <AdminComponents.sheet
        :if={@que_va_aca}
        id="que-va-aca-sheet"
        title="¿Qué juego va acá?"
        subtitle={@selected_copy && @selected_copy.shelf && @selected_copy.shelf.name}
        open
        on_close={JS.push("que-va-aca-close")}
        class="pk-estantes-sheet--full"
      >
        <div class="pk-donde-va-search">
          <input
            type="text"
            id="que-va-aca-search-input"
            name="q"
            value={@que_va_aca.query}
            placeholder="Buscá el juego que va acá"
            aria-label="Buscá el juego que va acá"
            autocomplete="off"
            phx-change="que-va-aca-search"
            phx-debounce="200"
            onfocus="this.select()"
          />
        </div>

        <div :if={@que_va_aca.query == ""} id="que-va-aca-unplaced">
          <AdminComponents.list_section_label>
            Sin ubicar · {length(Shelves.unplaced_copies())}
          </AdminComponents.list_section_label>
          <AdminComponents.list_row
            :for={copy <- Shelves.unplaced_copies()}
            id={"que-va-aca-unplaced-#{copy.id}"}
            cover={copy.game.thumbnail_url}
            name={copy.game.name}
            phx-click="que-va-aca-pick"
            phx-value-copy-id={copy.id}
          />
        </div>

        <div
          :if={@que_va_aca.query != "" and @que_va_aca.results == []}
          class="pk-estantes-no-match"
        >
          <p class="pk-estantes-no-match__hint">Ningún juego se llama así.</p>
          <%!-- Crear routes to the Juegos new-game editor with the name
          filled in — placing the created game straight into THIS exact
          slot (rather than opening a second "¿Dónde va?") is plan
          01.8.2-20's return-path wiring; this row only names the handoff
          (estante-ui-restart decision 66). --%>
          <AdminComponents.list_row
            id="que-va-aca-create-row"
            name={"Crear «#{@que_va_aca.query}»"}
            meta="Agregarlo al catálogo"
            navigate={~p"/admin/juegos?nombre=#{@que_va_aca.query}"}
            opens_page
          />
        </div>

        <div :if={@que_va_aca.query != "" and @que_va_aca.results != []} id="que-va-aca-results">
          <AdminComponents.list_row
            :for={copy <- @que_va_aca.results}
            id={"que-va-aca-result-#{copy.id}"}
            cover={copy.game.thumbnail_url}
            name={copy.game.name}
            meta={copy.shelf && copy.shelf.name}
            phx-click="que-va-aca-pick"
            phx-value-copy-id={copy.id}
          />
        </div>
      </AdminComponents.sheet>

      <AdminComponents.sheet
        :if={@cover_options_open and @selected_copy}
        id="cover-options-sheet"
        title={@selected_copy.game.name}
        subtitle={@selected_copy.shelf && @selected_copy.shelf.name}
        cover={@selected_copy.game.thumbnail_url}
        open
        on_close={JS.push("close-cover-options")}
      >
        <AdminComponents.action
          anatomy="a4"
          role="terciaria"
          navigate={~p"/juegos/#{@selected_copy.game}"}
        >
          Ver ficha
        </AdminComponents.action>
        <AdminComponents.action anatomy="a4" role="terciaria" phx-click="open-mover">
          Mover
        </AdminComponents.action>
        <AdminComponents.action anatomy="a4" role="peligro" phx-click="ask-quitar">
          Quitar del estante
        </AdminComponents.action>
      </AdminComponents.sheet>

      <AdminComponents.dialog
        :if={@confirm_remove}
        id="confirm-quitar-dialog"
        question={"¿Quitar #{@confirm_remove.game.name} del estante?"}
        consequence="Queda sin lugar hasta que lo vuelvas a ubicar."
        verb="Quitar"
        open
        on_confirm={JS.push("confirm-quitar")}
        on_cancel={JS.push("cancel-quitar")}
      />

      <AdminComponents.snackbar
        :if={@action_snackbar}
        id={@action_snackbar.id}
        message={@action_snackbar.message}
        action={@action_snackbar.action}
        on_close={JS.push("dismiss-action-snackbar")}
      />
    </Layouts.app>
    """
  end

  attr :id, :string, required: true
  attr :copy, :any, required: true

  defp suggestion_row(assigns) do
    ~H"""
    <AdminComponents.list_row
      id={@id}
      cover={@copy.game.thumbnail_url}
      name={@copy.game.name}
      phx-click="pick-copy"
      phx-value-copy-id={@copy.id}
    >
      <:trailing>
        <span :if={@copy.shelf} class="pk-estantes-row-meta">{@copy.shelf.name}</span>
        <AdminComponents.status_dot :if={is_nil(@copy.shelf_id)} status={:sin_lugar} />
      </:trailing>
    </AdminComponents.list_row>
    """
  end
end
