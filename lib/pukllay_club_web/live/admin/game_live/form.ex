defmodule PukllayClubWeb.Admin.GameLive.Form do
  @moduledoc """
  The game editor, at `/admin/juegos/:id/editar` — D-27's one 56px top
  bar, D-29's consequence franja, D-28's fixed foot save bar, and D-26's
  ficha-mirroring body (plan 01.8.2-17). Plan 01.8.2-21 closes the last
  three blocks: the Copias stepper (D-31), the ESTANTE block's real
  position-aware sheet (D-32), and the BGG-id lifecycle (open item 3,
  D-38).

  `mount/3` loads via `Catalog.get_game!/1` — the unfiltered ADMIN read —
  so a `:retired` game opens here exactly as readily as a `:published` one.
  A `:draft` game is different (plan 01.8.2-20, D-30): `mount/3` redirects
  it straight back to `/admin/juegos?draft=<id>`, which reopens that
  draft's own sheet on the list — this page renders ONLY for an
  already-published (or retired) game, whether reached via the Juegos
  list's row chevron or a direct URL to `/admin/juegos/:id/editar`. A
  draft is edited in the list's own sheet, never here (see
  `GameLive.Index`'s own moduledoc).

  **The write model — «la hoja PREPARA, el pie escribe» (080)**: the page
  holds a draft (`@draft`, a plain map of `Game.admin_changeset/2`'s five
  cast fields) and a `@saved` snapshot of the same shape — the values last
  persisted. `dirty?/2` compares the two. `Guardar` (the foot `save_bar/1`)
  copies the draft onto `SAVED` through `Catalog.update_game_admin/2`,
  which routes through `Game.admin_changeset/2`'s unchanged five-field cast
  allowlist (`[:name, :weight_band, :is_expansion, :description,
  :shelf_id]`, T-01.8.2-75/T-01.8.1-21) — never widened here.

  **D-31/D-32 (plan 01.8.2-21): Copias and Estante are NOT draft fields.**
  `:shelf_id` stays in `@draft_fields`/the changeset only because
  `Game.admin_changeset/2`'s cast list is a shared, un-narrowed contract
  (widening OR narrowing it is out of this plan's scope — see this
  plan's own SUMMARY); the ESTANTE block itself never reads or writes
  `@draft.shelf_id` any more — it reads/writes real `copies` rows
  directly, through `Shelves.place_copy/3`, immediately on commit, never
  deferred to the foot bar. Copias likewise creates/removes copy rows
  directly (`Shelves.add_copy/1`, `Shelves.remove_copy_for_game/2`,
  `Shelves.delete_copy/1`) and never touches `Game.admin_changeset/2` —
  the old flat integer count column was dropped by D-31, and routing a
  count through the game changeset would recreate it in spirit.

  The `"draft-change"` event is the generic write-into-the-draft entry
  point plan 01.8.2-17 wired and plan 01.8.2-19's field sheets now call
  directly (`choice_sheet/1`'s `"choice-select"` and `text_sheet/1`'s
  `"text-sheet-save"` both end by writing into `@draft`, never the
  database — see D-30 below).

  **D-30 — two sheet patterns, never mixed.** `choice_sheet/1` (nivel, es
  una expansión): an `.opt` row per option, the selected one carries a
  **tick** (D-23 — never the `--val` tint, which stays on the row that
  opened the sheet), and **choosing IS the commit** — it writes into
  `@draft` and closes the sheet in one round trip. No `Guardar` renders
  inside it. `text_sheet/1` (nombre, descripción): its own **wide
  `Guardar`** commits the typed value into `@draft` and closes; **✕
  discards** what was typed (079's fix for 073 d41's "exactly one
  `Guardar`" — closing a text sheet with ✕ used to silently drop the
  edit). Only the foot `save_bar/1` ever reaches the database for these
  four fields — a field sheet, whichever pattern, never calls `Catalog`
  directly.

  **The ESTANTE block (D-32).** Keeps D-23's row anatomy (a row showing
  the current value, opening a sheet) but the sheet is the SAME
  position-aware "¿Dónde va?" sheet `EstanteLive.Index` uses
  (`PukllayClubWeb.AdminComponents.placement_sheet/1` +
  `PukllayClubWeb.Admin.PlacementSheet`, extracted by this plan) — never
  a plain list of estantes, which is exactly what D-32 exists to
  prevent. For a multi-copy game with no copy already in context
  (`?copy=<id>`, carried from a cover's options sheet, or the game's
  single copy by default), tapping ESTANTE first asks which copy before
  opening the sheet.

  **The Copias stepper (D-31).** A stepper, not a sheet-opening row —
  D-23 explicitly puts steppers out of the editable-row anatomy's scope.
  Raising creates an unplaced copy; lowering removes an unplaced one
  first, or — when every copy is placed — opens a which-copy-to-remove
  sheet naming each candidate by `copia N de M` + its estante/box.

  **The BGG-id lifecycle (open item 3, D-38).** Reachable from the ⋮
  menu: `Vincular con BGG` (no `bgg_id` yet), `Reintentar` (any `bgg_id`,
  any `enrichment_status` — the old `"failed"`-only gate matched 0 rows),
  and `Borrar el ID` (a `bgg_missing` game whose stored id never
  resolves). Linking and retrying both **save first, then act** — D-38's
  fix for 075's `commitId`/`loadState()` bug (which never shipped in
  Elixir, but the ordering constraint is real): neither ever reloads
  `@draft`/`@saved` from a fresh read, so an in-progress edit survives.
  The editor subscribes to `"admin:games"` and, on `{:game_enriched,
  id}` for this game, refreshes the SAVED baseline for `:name`/
  `:description` ONLY where the staff member has not touched them —
  T-01.8.2-99's fix for `admin_changeset`'s `:name` cast silently
  writing a stale placeholder back over the name BGG just supplied.
  """
  use PukllayClubWeb, :live_view

  alias Phoenix.LiveView.JS
  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Shelves
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClubWeb.Admin.PlacementSheet
  alias PukllayClubWeb.AdminComponents

  # D-31/D-27: the five-field cast ceiling `Game.admin_changeset/2` pins —
  # restated here (not re-derived) so the draft/saved maps this module
  # builds can never silently drift from what the changeset actually
  # accepts. Widening this list without ALSO widening the changeset (or
  # vice versa) is caught immediately: a field present here but absent from
  # the changeset is simply dropped on save (Ecto's own `cast/3` contract),
  # never persisted and never an error. `:shelf_id` stays here even though
  # the ESTANTE block itself (D-32, plan 01.8.2-21) no longer reads or
  # writes it — narrowing the shared changeset contract is out of this
  # plan's scope; see this module's own moduledoc.
  @draft_fields [:name, :weight_band, :is_expansion, :description, :shelf_id]

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    game = Catalog.get_game!(id)

    if game.status == :draft do
      # D-30/plan 01.8.2-20: this page is for an already-published (or
      # retired) game only. A direct URL to a draft's editor — the row no
      # longer carries a chevron here (D-19i), but the URL is still
      # guessable — never renders a half-editor; it hands the game straight
      # back to the list, which opens the same draft's sheet.
      {:ok, push_navigate(socket, to: ~p"/admin/juegos?#{%{draft: game.id}}")}
    else
      if connected?(socket) do
        Phoenix.PubSub.subscribe(PukllayClub.PubSub, "admin:games")
      end

      game = Catalog.put_section_names(game)
      draft = draft_from_game(game)
      copies = Shelves.copies_for_game(game.id)
      copy_context = resolve_copy_context(copies, params["copy"])

      {:ok,
       socket
       |> assign(:page_title, game.name)
       |> assign(:game, game)
       |> assign(:draft, draft)
       |> assign(:saved, draft)
       |> assign(:shelves, Shelves.list_shelves())
       |> assign(:copies, copies)
       |> assign(:copy_context, copy_context)
       |> assign(:copy_picker_open, false)
       |> assign(:which_copy_sheet, nil)
       |> assign(:shelf_sheet, nil)
       |> assign(:undo_snapshot, nil)
       |> assign(:bgg_undo_snapshot, nil)
       |> assign(:action_snackbar, nil)
       |> assign(:menu_open, false)
       |> assign(:confirm_retire, false)
       |> assign(:confirm_discard, false)
       |> assign(:open_sheet, nil)
       |> assign(:sheet_value, nil)
       |> assign(:sheet_error, nil)
       |> assign(:bgg_link_value, "")
       |> assign(:bgg_link_error, nil)
       |> assign(:bgg_link_edition_prompt, nil)}
    end
  end

  defp draft_from_game(game), do: Map.take(game, @draft_fields)

  defp dirty?(draft, saved), do: draft != saved

  # ============================================================
  # The write model — Guardar (D-28) and the generic draft-write seam
  # plan 01.8.2-19's field sheets will call.
  # ============================================================

  @impl true
  def handle_event("save", _params, socket) do
    case save_draft_if_dirty(socket) do
      {:ok, socket} -> {:noreply, put_flash(socket, :info, "Cambios guardados.")}
      {:error, socket} -> {:noreply, put_flash(socket, :error, "No se pudo guardar. Revisá los datos.")}
    end
  end

  # Plan 01.8.2-19's field sheets write into the draft through this one
  # event — this plan builds the seam and exercises it directly (no sheet
  # UI calls it yet). `field` arrives as a string naming one of
  # `@draft_fields`; an unrecognised field is a no-op rather than a crash,
  # since a stale/forged event name must never corrupt the draft.
  @impl true
  def handle_event("draft-change", %{"field" => field, "value" => value}, socket) do
    case Enum.find(@draft_fields, &(Atom.to_string(&1) == field)) do
      nil -> {:noreply, socket}
      key -> {:noreply, assign(socket, :draft, Map.put(socket.assigns.draft, key, cast_draft_value(key, value)))}
    end
  end

  # ============================================================
  # D-31, plan 01.8.2-21 — the Copias stepper: copy rows created and
  # removed DIRECTLY, never through `Game.admin_changeset/2`. Both write
  # immediately (not deferred to the foot bar) — a comment on each
  # handler says so, per this plan's own instruction, since a reader
  # would otherwise assume it is a bug against «la hoja PREPARA, el pie
  # escribe».
  # ============================================================

  # Copy-row write, not a draft edit — commits immediately (D-31).
  @impl true
  def handle_event("copias-increment", _params, socket) do
    case Shelves.add_copy(socket.assigns.game.id) do
      {:ok, _copy} -> {:noreply, refresh_copies_and_context(socket)}
      {:error, _changeset} -> {:noreply, put_flash(socket, :error, "No se pudo agregar la copia.")}
    end
  end

  # Copy-row write, not a draft edit — commits immediately (D-31). Floors
  # at 1 (a game with zero copies has no meaning in this catalog) with a
  # plain no-op, matching `Shelves.move_shelf/2`'s own "enabled-and-no-op
  # over disabled" precedent for a stepper's edge.
  @impl true
  def handle_event("copias-decrement", _params, socket) do
    game_id = socket.assigns.game.id

    if length(socket.assigns.copies) <= 1 do
      {:noreply, socket}
    else
      case Shelves.remove_copy_for_game(game_id) do
        {:ok, _removed} ->
          {:noreply, refresh_copies_and_context(socket)}

        {:error, :no_unplaced_copy} ->
          {:noreply, assign(socket, :which_copy_sheet, socket.assigns.copies)}
      end
    end
  end

  @impl true
  def handle_event("copias-remove-copy", %{"copy-id" => copy_id}, socket) do
    case Integer.parse(copy_id) do
      {int_id, ""} ->
        case Shelves.remove_copy_for_game(socket.assigns.game.id, int_id) do
          {:ok, _removed} ->
            {:noreply, socket |> assign(:which_copy_sheet, nil) |> refresh_copies_and_context()}

          {:error, _reason} ->
            {:noreply, assign(socket, :which_copy_sheet, nil)}
        end

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close-which-copy-sheet", _params, socket) do
    {:noreply, assign(socket, :which_copy_sheet, nil)}
  end

  # ============================================================
  # D-32, plan 01.8.2-21 — the ESTANTE block: opens the SAME position-
  # aware "¿Dónde va?" sheet `EstanteLive.Index` uses
  # (`PlacementSheet`/`AdminComponents.placement_sheet/1`, extracted by
  # this plan). A copy-location write, not a draft edit — commits
  # immediately, never deferred to the foot bar (D-31's comment
  # convention, restated here).
  # ============================================================

  @impl true
  def handle_event("edit-field", %{"field" => "shelf_id"}, socket) do
    case socket.assigns.copy_context do
      nil ->
        case socket.assigns.copies do
          [] -> {:noreply, put_flash(socket, :error, "Este juego todavía no tiene copias.")}
          _multiple -> {:noreply, assign(socket, :copy_picker_open, true)}
        end

      copy ->
        {:noreply, assign(socket, :shelf_sheet, PlacementSheet.open(copy))}
    end
  end

  @impl true
  def handle_event("pick-copy-context", %{"copy-id" => copy_id}, socket) do
    case Integer.parse(copy_id) do
      {int_id, ""} ->
        case Enum.find(socket.assigns.copies, &(&1.id == int_id)) do
          nil ->
            {:noreply, socket}

          copy ->
            {:noreply,
             socket
             |> assign(:copy_context, copy)
             |> assign(:copy_picker_open, false)
             |> assign(:shelf_sheet, PlacementSheet.open(copy))}
        end

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close-copy-picker", _params, socket) do
    {:noreply, assign(socket, :copy_picker_open, false)}
  end

  @impl true
  def handle_event("donde-va-search", %{"q" => q}, socket) do
    query = String.slice(q, 0, 120)
    {:noreply, update(socket, :shelf_sheet, &PlacementSheet.search(&1, query))}
  end

  @impl true
  def handle_event("donde-va-field-clear", _params, socket) do
    {:noreply, update(socket, :shelf_sheet, &PlacementSheet.field_clear/1)}
  end

  @impl true
  def handle_event("donde-va-pick-estante", %{"shelf-id" => id}, socket) do
    shelf = Shelves.get_shelf!(String.to_integer(id))
    {:noreply, apply_shelf_pick(socket, PlacementSheet.pick_estante(socket.assigns.shelf_sheet, shelf))}
  end

  @impl true
  def handle_event("donde-va-pick-copy", %{"copy-id" => id}, socket) do
    copy = Shelves.get_copy!(String.to_integer(id))
    {:noreply, apply_shelf_pick(socket, PlacementSheet.pick_copy(socket.assigns.shelf_sheet, copy))}
  end

  @impl true
  def handle_event("donde-va-commit", %{"index" => idx}, socket) do
    shelf = socket.assigns.shelf_sheet.estante
    {:noreply, commit_shelf_sheet(socket, shelf.id, String.to_integer(idx))}
  end

  @impl true
  def handle_event("donde-va-close", _params, socket) do
    {:noreply, assign(socket, :shelf_sheet, nil)}
  end

  @impl true
  def handle_event("undo-place", _params, socket) do
    case socket.assigns.undo_snapshot do
      nil ->
        {:noreply, socket}

      %{copy_id: copy_id, shelf_id: shelf_id, position: position} ->
        socket = socket |> assign(:undo_snapshot, nil) |> assign(:action_snackbar, nil)

        case Shelves.restore_position(copy_id, shelf_id, position) do
          {:ok, restored} ->
            socket = refresh_copies_and_context(socket)
            fresh = Enum.find(socket.assigns.copies, &(&1.id == restored.id)) || restored
            {:noreply, maybe_update_copy_context(socket, fresh)}

          {:error, _reason} ->
            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_event("dismiss-action-snackbar", _params, socket) do
    {:noreply,
     socket
     |> assign(:action_snackbar, nil)
     |> assign(:undo_snapshot, nil)
     |> assign(:bgg_undo_snapshot, nil)}
  end

  # Every admin block's open event. The two choice fields (D-23/D-30)
  # open `choice_sheet/1`; the two text fields open `text_sheet/1`,
  # priming `@sheet_value` from the CURRENT draft so a sheet reopened after
  # a discard shows the draft's real value, not a stale typed one.
  # Copias (its own stepper events above), Estante ("shelf_id" above), and
  # the cover (`field="cover"`, deliberately inert — `admin-game-editor.md`'s
  # own "What to Avoid" section records that redrawing the cover reverts
  # 01.3.1/D-07; the badge exists because the pencil needs a target, not
  # because the cover is genuinely editable) all fall through to the
  # catch-all no-op below.
  @impl true
  def handle_event("edit-field", %{"field" => field}, socket) when field in ["weight_band", "is_expansion"] do
    {:noreply, assign(socket, :open_sheet, String.to_existing_atom(field))}
  end

  @impl true
  def handle_event("edit-field", %{"field" => field}, socket) when field in ["name", "description"] do
    key = String.to_existing_atom(field)

    {:noreply,
     socket
     |> assign(:open_sheet, key)
     |> assign(:sheet_value, Map.get(socket.assigns.draft, key) || "")
     |> assign(:sheet_error, nil)}
  end

  @impl true
  def handle_event("edit-field", %{"field" => _field}, socket) do
    {:noreply, socket}
  end

  # Live typing inside `text_sheet/1` (T-01.8.2-88's own mitigation): this
  # tracks `@sheet_value` ONLY — never `@draft` — so `close-field-sheet`
  # below has real typed-but-unsubmitted text to discard, and a submit
  # (`"text-sheet-save"`) has the true current value even if the browser
  # round-trip beat a keystroke.
  @impl true
  def handle_event("sheet-input", %{"field" => field, "value" => value}, socket) when field in ["name", "description"] do
    {:noreply, assign(socket, :sheet_value, value)}
  end

  # ✕ (or Esc/scrim/drag-down, via `AdminSheet`): discards whatever was
  # typed/selected without touching `@draft` — the write model's other
  # half from `"draft-change"`'s own no-op-on-stale-field guard. Also
  # closes the BGG-link sheet's own local state (harmless when it was
  # never open).
  @impl true
  def handle_event("close-field-sheet", _params, socket) do
    {:noreply,
     socket
     |> assign(:open_sheet, nil)
     |> assign(:sheet_value, nil)
     |> assign(:sheet_error, nil)
     |> assign(:bgg_link_value, "")
     |> assign(:bgg_link_error, nil)
     |> assign(:bgg_link_edition_prompt, nil)}
  end

  # `choice_sheet/1`'s own commit: choosing an option IS the commit (D-30)
  # — it writes into `@draft` (never `Catalog`) and closes in one round
  # trip. Reuses `@draft_fields`/`cast_draft_value/2` verbatim so a
  # stale/forged `field` can never corrupt the draft, exactly like
  # `"draft-change"` above.
  @impl true
  def handle_event("choice-select", %{"field" => field, "choice" => choice}, socket) do
    case Enum.find(@draft_fields, &(Atom.to_string(&1) == field)) do
      nil ->
        {:noreply, socket}

      key ->
        {:noreply,
         socket
         |> assign(:draft, Map.put(socket.assigns.draft, key, cast_draft_value(key, choice)))
         |> assign(:open_sheet, nil)}
    end
  end

  # `text_sheet/1`'s own wide `Guardar`: runs the ONE changed field
  # through `Game.admin_changeset/2` at commit time (T-01.8.2-92) so a
  # validation error (the name's `validate_length(:name, max: 255)`)
  # surfaces inside the sheet, where the typing happened, instead of
  # after a silent close — built from `socket.assigns.game` (the last
  # PERSISTED values), never `@draft`, so an unrelated dirty field can
  # never leak a spurious error into this one field's check. Valid ->
  # writes into `@draft` and closes; invalid -> keeps the sheet open with
  # the typed value retained and the translated error shown.
  @impl true
  def handle_event("text-sheet-save", %{"field" => field, "value" => value}, socket)
      when field in ["name", "description"] do
    key = String.to_existing_atom(field)
    changeset = Catalog.change_game_admin(socket.assigns.game, %{key => value})

    case Keyword.get(changeset.errors, key) do
      nil ->
        {:noreply,
         socket
         |> assign(:draft, Map.put(socket.assigns.draft, key, value))
         |> assign(:open_sheet, nil)
         |> assign(:sheet_value, nil)
         |> assign(:sheet_error, nil)}

      error ->
        {:noreply,
         socket
         |> assign(:sheet_value, value)
         |> assign(:sheet_error, translate_error(error))}
    end
  end

  # ============================================================
  # Open item 3 / D-38, plan 01.8.2-21 — the BGG-id lifecycle: link a
  # fresh id, Reintentar (re-gated), Borrar el ID, and the
  # `{:game_enriched, id}` race guard.
  # ============================================================

  @impl true
  def handle_event("open-bgg-link", _params, socket) do
    {:noreply,
     socket
     |> assign(:menu_open, false)
     |> assign(:open_sheet, :bgg_link)
     |> assign(:bgg_link_value, "")
     |> assign(:bgg_link_error, nil)
     |> assign(:bgg_link_edition_prompt, nil)}
  end

  @impl true
  def handle_event("link-bgg-input", %{"bgg_id" => value}, socket) do
    {:noreply, assign(socket, :bgg_link_value, value)}
  end

  @impl true
  def handle_event("link-bgg-save", %{"bgg_id" => value}, socket) do
    case save_draft_if_dirty(socket) do
      {:ok, socket} -> do_link_bgg(socket, value, [])
      {:error, socket} -> {:noreply, put_flash(socket, :error, "No se pudo guardar. Revisá los datos.")}
    end
  end

  @impl true
  def handle_event("confirm-link-edition", _params, %{assigns: %{bgg_link_edition_prompt: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_event("confirm-link-edition", _params, socket) do
    %{input: input, games: games} = socket.assigns.bgg_link_edition_prompt
    do_link_bgg(socket, input, Enum.map(games, & &1.id))
  end

  @impl true
  def handle_event("cancel-link-edition", _params, socket) do
    {:noreply, assign(socket, :bgg_link_edition_prompt, nil)}
  end

  # D-03: `game-id` (never the reserved `value` key — project memory rule)
  # is parsed defensively even though this screen only ever renders one
  # game's own id. D-38's save-first-then-retry ordering: any pending
  # draft edit is persisted BEFORE the retry itself, and the retry's own
  # success path never reloads through a stale re-fetch of the draft —
  # only `@game`/`@draft`/`@saved` are refreshed from the SAME updated
  # struct `Catalog.retry_enrichment/1` returns.
  @impl true
  def handle_event("retry-enrichment", %{"game-id" => game_id}, socket) do
    case Integer.parse(game_id) do
      {int_id, ""} ->
        case save_draft_if_dirty(socket) do
          {:ok, socket} -> do_retry_enrichment(socket, int_id)
          {:error, socket} -> {:noreply, put_flash(socket, :error, "No se pudo guardar. Revisá los datos.")}
        end

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  # Open item 3: "a stored id that never resolves is worse than none" —
  # clears `bgg_id` for a `bgg_missing` game. Plain action + Deshacer
  # (the `bgg_missing` games this targets never have enriched data to
  # lose — nothing to confirm in a centred dialog for).
  @impl true
  def handle_event("borrar-bgg-id", _params, socket) do
    previous = %{bgg_id: socket.assigns.game.bgg_id, enrichment_status: socket.assigns.game.enrichment_status}

    case Catalog.clear_bgg_id(socket.assigns.game) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:game, updated)
         |> assign(:menu_open, false)
         |> assign(:bgg_undo_snapshot, previous)
         |> assign(:action_snackbar, %{
           id: "editor-action-snackbar",
           message: "ID de BGG borrado",
           action: %{label: "Deshacer", event: "undo-borrar-bgg-id"}
         })}

      {:error, _changeset} ->
        {:noreply, socket |> assign(:menu_open, false) |> put_flash(:error, "No se pudo borrar el ID.")}
    end
  end

  @impl true
  def handle_event("undo-borrar-bgg-id", _params, socket) do
    case socket.assigns.bgg_undo_snapshot do
      nil ->
        {:noreply, socket}

      %{bgg_id: bgg_id, enrichment_status: enrichment_status} ->
        case Catalog.restore_bgg_id(socket.assigns.game, bgg_id, enrichment_status) do
          {:ok, updated} ->
            {:noreply,
             socket
             |> assign(:game, updated)
             |> assign(:bgg_undo_snapshot, nil)
             |> assign(:action_snackbar, nil)}

          {:error, _reason} ->
            {:noreply, socket}
        end
    end
  end

  # ============================================================
  # D-27's back control + D-19f's discard-confirm dialog
  # ============================================================

  @impl true
  def handle_event("back-clicked", _params, socket) do
    if dirty?(socket.assigns.draft, socket.assigns.saved) do
      {:noreply, assign(socket, :confirm_discard, true)}
    else
      {:noreply, push_navigate(socket, to: ~p"/admin/juegos")}
    end
  end

  @impl true
  def handle_event("cancel-discard", _params, socket) do
    {:noreply, assign(socket, :confirm_discard, false)}
  end

  @impl true
  def handle_event("confirm-discard", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/juegos")}
  end

  # ============================================================
  # D-27's ⋮ lifecycle sheet + the D-19f retire-confirm dialog
  # ============================================================

  @impl true
  def handle_event("open-menu", _params, socket) do
    {:noreply, assign(socket, :menu_open, true)}
  end

  @impl true
  def handle_event("close-menu", _params, socket) do
    {:noreply, assign(socket, :menu_open, false)}
  end

  @impl true
  def handle_event("retire", _params, socket) do
    {:noreply, socket |> assign(:menu_open, false) |> assign(:confirm_retire, true)}
  end

  @impl true
  def handle_event("cancel-retire", _params, socket) do
    {:noreply, assign(socket, :confirm_retire, false)}
  end

  # `status` commits on its own, outside `@draft`/`@saved` entirely (D-27's
  # moduledoc note) — neither branch below touches either assign, which is
  # what lets an in-progress field edit survive a status change untouched.
  @impl true
  def handle_event("confirm-retire", _params, socket) do
    case Catalog.retire_game(socket.assigns.game) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(:game, game)
         |> assign(:confirm_retire, false)
         |> put_flash(:info, "Juego retirado.")}

      {:error, _reason} = error ->
        {:noreply,
         socket
         |> assign(:confirm_retire, false)
         |> put_flash(:error, lifecycle_error_message(error))}
    end
  end

  @impl true
  def handle_event("restore", _params, socket) do
    case Catalog.restore_game(socket.assigns.game) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(:game, game)
         |> assign(:menu_open, false)
         |> put_flash(:info, "Juego restaurado.")}

      {:error, _reason} = error ->
        {:noreply,
         socket
         |> assign(:menu_open, false)
         |> put_flash(:error, lifecycle_error_message(error))}
    end
  end

  # T-01.8.2-99: a save at the moment enrichment lands must never write a
  # stale placeholder name back over the name BGG just supplied. On
  # `{:game_enriched, id}` for THIS game, refreshes the SAVED baseline
  # for `:name`/`:description` ONLY where the staff member has not
  # touched them — a touched field is left exactly as typed.
  @impl true
  def handle_info({:game_enriched, id}, %{assigns: %{game: %{id: id}}} = socket) do
    fresh = id |> Catalog.get_game!() |> Catalog.put_section_names()
    {:noreply, reconcile_enrichment(socket, fresh)}
  end

  def handle_info({:game_enriched, _other_id}, socket), do: {:noreply, socket}

  # ============================================================
  # Private helpers behind the handlers above — grouped here (not
  # interleaved with `handle_event/3`) so every clause of that callback
  # stays contiguous (Elixir's own "clauses ... should be grouped
  # together" compiler warning, which `mix compile --warnings-as-errors`
  # in `mix quality` treats as a build failure).
  # ============================================================

  # D-38's save-first-then-act ordering — Reintentar and linking a BGG id
  # both call this BEFORE touching `bgg_id`/`enrichment_status`, and
  # neither reloads `@draft`/`@saved` from a fresh read afterward (that
  # was 075's `commitId`/`loadState()` bug). A clean editor is a no-op —
  # `{:ok, socket}` unchanged.
  defp save_draft_if_dirty(socket) do
    if dirty?(socket.assigns.draft, socket.assigns.saved) do
      case Catalog.update_game_admin(socket.assigns.game, socket.assigns.draft) do
        {:ok, game} ->
          game = Catalog.put_section_names(game)
          saved = draft_from_game(game)

          {:ok,
           socket
           |> assign(:game, game)
           |> assign(:page_title, game.name)
           |> assign(:draft, saved)
           |> assign(:saved, saved)}

        {:error, _changeset} ->
          {:error, socket}
      end
    else
      {:ok, socket}
    end
  end

  # Recomputes `:copies` (D-02, D-31: `count(copies)` is the ONLY Copias
  # source) and reconciles `:copy_context` against it — if the copy the
  # ESTANTE block was pointed at no longer exists (an edge case: the
  # stepper happened to remove it), falls back to a fresh default rather
  # than holding a dangling reference.
  defp refresh_copies_and_context(socket) do
    copies = Shelves.copies_for_game(socket.assigns.game.id)

    copy_context =
      case socket.assigns.copy_context do
        %{id: id} -> Enum.find(copies, &(&1.id == id)) || resolve_copy_context(copies, nil)
        nil -> resolve_copy_context(copies, nil)
      end

    socket
    |> assign(:copies, copies)
    |> assign(:copy_context, copy_context)
  end

  defp resolve_copy_context(copies, copy_id_param) do
    case parse_copy_id(copy_id_param) do
      nil -> default_copy_context(copies)
      int_id -> Enum.find(copies, &(&1.id == int_id)) || default_copy_context(copies)
    end
  end

  defp parse_copy_id(nil), do: nil

  defp parse_copy_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _not_an_integer -> nil
    end
  end

  defp default_copy_context([copy]), do: copy
  defp default_copy_context(_copies), do: nil

  defp apply_shelf_pick(socket, {:commit, shelf_id, index}), do: commit_shelf_sheet(socket, shelf_id, index)
  defp apply_shelf_pick(socket, {:choose_slot, new_state}), do: assign(socket, :shelf_sheet, new_state)

  defp commit_shelf_sheet(socket, shelf_id, index) do
    copy = socket.assigns.shelf_sheet.copy
    previous_shelf_id = copy.shelf_id
    previous_position = copy.position

    case Shelves.place_copy(copy.id, shelf_id, index) do
      {:ok, moved} ->
        message = if is_nil(previous_shelf_id), do: "Juego ubicado", else: "Juego movido"
        socket = refresh_copies_and_context(socket)
        fresh = Enum.find(socket.assigns.copies, &(&1.id == moved.id)) || moved

        socket
        |> assign(:shelf_sheet, nil)
        |> assign(:copy_context, fresh)
        |> assign(:undo_snapshot, %{copy_id: moved.id, shelf_id: previous_shelf_id, position: previous_position})
        |> assign(:action_snackbar, %{
          id: "editor-action-snackbar",
          message: message,
          action: %{label: "Deshacer", event: "undo-place"}
        })

      {:error, _reason} ->
        assign(socket, :shelf_sheet, nil)
    end
  end

  defp maybe_update_copy_context(socket, %{id: id} = fresh) do
    if socket.assigns.copy_context && socket.assigns.copy_context.id == id do
      assign(socket, :copy_context, fresh)
    else
      socket
    end
  end

  defp do_link_bgg(socket, value, acknowledged_ids) do
    case Catalog.link_bgg_id(socket.assigns.game, value, acknowledged_game_ids: acknowledged_ids) do
      {:ok, updated} ->
        updated = Catalog.put_section_names(updated)

        {:noreply,
         socket
         |> assign(:game, updated)
         |> assign(:draft, draft_from_game(updated))
         |> assign(:saved, draft_from_game(updated))
         |> assign(:open_sheet, nil)
         |> assign(:bgg_link_value, "")
         |> assign(:bgg_link_error, nil)
         |> assign(:bgg_link_edition_prompt, nil)
         |> put_flash(:info, "BGG vinculado.")}

      {:existing_editions, games} ->
        {:noreply,
         socket
         |> assign(:bgg_link_value, value)
         |> assign(:bgg_link_error, nil)
         |> assign(:bgg_link_edition_prompt, %{input: value, games: games})}

      {:error, :invalid_bgg_id} ->
        {:noreply,
         socket
         |> assign(:bgg_link_value, value)
         |> assign(:bgg_link_error, "Pegá un número de BGG o el link del juego.")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(:bgg_link_value, value)
         |> assign(:bgg_link_error, "No se pudo vincular.")}
    end
  end

  defp do_retry_enrichment(socket, game_id) do
    case game_id |> Catalog.get_game!() |> Catalog.retry_enrichment() do
      {:ok, updated} ->
        updated = Catalog.put_section_names(updated)

        {:noreply,
         socket
         |> assign(:game, updated)
         |> assign(:draft, draft_from_game(updated))
         |> assign(:saved, draft_from_game(updated))
         |> assign(:menu_open, false)}

      {:error, :no_bgg_id} ->
        {:noreply, socket}
    end
  end

  defp reconcile_enrichment(socket, fresh) do
    touched_name? = socket.assigns.draft.name != socket.assigns.saved.name
    touched_description? = socket.assigns.draft.description != socket.assigns.saved.description

    new_saved = %{
      socket.assigns.saved
      | name: if(touched_name?, do: socket.assigns.saved.name, else: fresh.name),
        description: if(touched_description?, do: socket.assigns.saved.description, else: fresh.description)
    }

    new_draft = %{
      socket.assigns.draft
      | name: if(touched_name?, do: socket.assigns.draft.name, else: fresh.name),
        description: if(touched_description?, do: socket.assigns.draft.description, else: fresh.description)
    }

    socket
    |> assign(:game, fresh)
    |> assign(:saved, new_saved)
    |> assign(:draft, new_draft)
  end

  # ============================================================
  # Render-only helpers
  # ============================================================

  defp cast_draft_value(:is_expansion, value) when is_boolean(value), do: value
  defp cast_draft_value(:is_expansion, "true"), do: true
  defp cast_draft_value(:is_expansion, _falsy), do: false

  defp cast_draft_value(:shelf_id, value) when value in [nil, ""], do: nil

  defp cast_draft_value(:shelf_id, value) when is_binary(value) do
    case Integer.parse(value) do
      {int_id, ""} -> int_id
      _not_an_integer -> nil
    end
  end

  defp cast_draft_value(:shelf_id, value) when is_integer(value), do: value
  defp cast_draft_value(:weight_band, value) when value in [nil, ""], do: nil
  defp cast_draft_value(_field, value), do: value

  # D-29: the consequence, not the name — a draft renders NEITHER string
  # (the prohibition `01.8.2-UI-SPEC.md`'s copywriting contract names as
  # "the single easiest thing for a build to get wrong here").
  defp franja_text(:published), do: "Publicado · Así se ve en la web."
  defp franja_text(:retired), do: "Retirado · No se ve en la web ni está en el estante."
  defp franja_text(:draft), do: nil

  defp weight_band_label(nil), do: "Sin nivel"

  defp weight_band_label(value) do
    case Enum.find(Vocabulary.weight_bands(), &(&1.value == value)) do
      nil -> "Sin nivel"
      band -> band.label
    end
  end

  # D-32: the ESTANTE block's real, copy-level value — NEVER `@draft.shelf_id`
  # (the dead game-level column, D-31). `copy_context` is `nil` either
  # because this game has no copies yet (edge case) or because a
  # multi-copy game has not had its copy resolved yet (tapping the row
  # asks which copy first).
  defp estante_value(copy_context, copies) do
    cond do
      copy_context -> copy_shelf_label(copy_context)
      copies == [] -> "Sin ubicar"
      true -> "Elegí una copia"
    end
  end

  defp copy_shelf_label(%{shelf_id: nil}), do: "Sin ubicar"

  defp copy_shelf_label(%{shelf_id: shelf_id, shelf: shelf, position: position}) do
    total = length(Shelves.copies_on_shelf(shelf_id))
    "#{shelf.name} · caja #{position + 1} de #{total}"
  end

  # D-03: "copia N de M" only when the game has more than one copy.
  defp which_copy_name(copy, total) when total > 1, do: "Copia #{copy.number}"
  defp which_copy_name(_copy, _total), do: "Esta copia"

  defp which_copy_meta(%{shelf_id: nil}), do: "Sin ubicar"

  defp which_copy_meta(%{shelf_id: shelf_id, shelf: shelf, position: position}) do
    total = length(Shelves.copies_on_shelf(shelf_id))
    "#{shelf.name} · caja #{position + 1} de #{total}"
  end

  defp mechanics_text(%{mechanics: mechanics}), do: join_or_dash(Vocabulary.covered_mechanics(mechanics))
  defp themes_text(%{themes: themes}), do: join_or_dash(Vocabulary.covered_themes(themes))
  defp join_names(names), do: join_or_dash(names)
  defp join_or_dash([]), do: "—"
  defp join_or_dash(values), do: Enum.join(values, ", ")
  defp value_or_dash(nil), do: "—"
  defp value_or_dash(value), do: to_string(value)

  defp lifecycle_action(:published), do: {"Retirar", "Deja de verse en la web y sale del estante.", "retire"}
  defp lifecycle_action(:retired), do: {"Restaurar", "Vuelve a la ludoteca y a la web.", "restore"}
  defp lifecycle_action(:draft), do: nil

  # Open item 3 — "a stored id that never resolves is worse than none",
  # offered for the 8 `bgg_missing` games specifically: no other
  # enrichment_status leaves a stored id this dead.
  defp borrar_bgg_id_offered?(%{bgg_id: bgg_id, enrichment_status: "bgg_missing"}), do: not is_nil(bgg_id)
  defp borrar_bgg_id_offered?(_game), do: false

  # D-37's origin-guard refusal tuples (T-01.8.2-90) — this screen only
  # ever calls `retire_game/1` (-> `:not_retirable`) and `restore_game/1`
  # (-> `:not_retired`), but `:not_publishable` is included too: it's
  # `publish_game/1`'s own refusal, named explicitly in this plan's
  # `<read_first>` alongside the other two, and a future ⋮ action reusing
  # this same helper for a publish path (this screen only ever reaches a
  # published game, D-30, so it never fires today) should find the message
  # already here rather than a silent fourth case. A refused transition
  # surfaces via the shared snackbar (`put_flash`, routed by
  # `Layouts.admin_flash/1`, D-19c) — never a silent no-op.
  defp lifecycle_error_message({:error, :not_publishable}), do: "No se pudo publicar. El estado cambió mientras tanto."

  defp lifecycle_error_message({:error, :not_retirable}), do: "No se pudo retirar. El estado cambió mientras tanto."

  defp lifecycle_error_message({:error, :not_retired}), do: "No se pudo restaurar. El estado cambió mientras tanto."

  defp lifecycle_error_message({:error, _other}), do: "No se pudo completar la acción."

  # ============================================================
  # D-30's two sheet patterns — NEVER MIXED. `choice_sheet/1` is the
  # `.opt` + tick pattern (nivel, es una expansión): choosing IS the
  # commit and closes, no `Guardar` renders. `text_sheet/1` is the other
  # pattern (nombre, descripción): its own wide `Guardar` commits, ✕
  # discards. Do not add a commit control to `choice_sheet/1` and do not
  # make `text_sheet/1` commit on selection/close — that is exactly the
  # blur D-30 names and forbids.
  # ============================================================

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :field, :atom, required: true
  attr :options, :list, required: true, doc: "[%{value: any, label: string, sub: string | nil}]"
  attr :selected, :any
  attr :open, :boolean, default: false
  attr :on_close, JS, default: %JS{}

  defp choice_sheet(assigns) do
    ~H"""
    <AdminComponents.sheet id={@id} title={@title} open={@open} on_close={@on_close}>
      <button
        :for={opt <- @options}
        type="button"
        class="pk-editor-opt"
        data-pk-pressable="true"
        phx-click="choice-select"
        phx-value-field={@field}
        phx-value-choice={to_string(opt.value)}
      >
        <span class="pk-editor-opt__text">
          <span class="pk-editor-opt__label">{opt.label}</span>
          <span :if={opt[:sub]} class="pk-editor-opt__sub">{opt.sub}</span>
        </span>
        <.icon :if={opt.value == @selected} name="hero-check" class="pk-editor-opt__tick" />
      </button>
    </AdminComponents.sheet>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :value, :string, default: ""
  attr :error, :string, default: nil
  attr :textarea, :boolean, default: false
  attr :open, :boolean, default: false
  attr :on_close, JS, default: %JS{}

  defp text_sheet(assigns) do
    ~H"""
    <AdminComponents.sheet id={@id} title={@title} open={@open} on_close={@on_close}>
      <form id={"#{@id}-form"} phx-submit="text-sheet-save" phx-change="sheet-input">
        <input type="hidden" name="field" value={@field} />
        <AdminComponents.field
          type={if @textarea, do: "textarea", else: "text"}
          name="value"
          id={"#{@id}-input"}
          label={@label}
          value={@value}
          errors={if @error, do: [@error], else: []}
        />
        <AdminComponents.action
          anatomy="a1"
          role="principal"
          type="submit"
          class="pk-editor-sheet-save"
        >
          Guardar
        </AdminComponents.action>
      </form>
    </AdminComponents.sheet>
    """
  end

  # Open item 3, D-38 — the link-a-BGG-id sheet: a text field reusing
  # 01.8.1's own `parse_bgg_input/1` (via `Catalog.link_bgg_id/3`), plus
  # the SAME editions-warning shape `GameLive.Index`'s add-by-BGG form
  # uses when the pasted id is already held by another game.
  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :value, :string, default: ""
  attr :error, :string, default: nil
  attr :edition_prompt, :map, default: nil
  attr :on_close, JS, default: %JS{}

  defp bgg_link_sheet(assigns) do
    ~H"""
    <AdminComponents.sheet id={@id} title="Vincular con BGG" open={@open} on_close={@on_close}>
      <div :if={@edition_prompt} id="editor-bgg-edition-prompt">
        <p>
          Ya tenés {edition_names(@edition_prompt.games)} con este BGG ID. ¿Es otra edición?
        </p>
        <ul>
          <li :for={game <- @edition_prompt.games}>{game.name}</li>
        </ul>
        <AdminComponents.action
          id="confirm-link-edition"
          anatomy="a1"
          role="principal"
          phx-click="confirm-link-edition"
        >
          Sí, es otra edición
        </AdminComponents.action>
        <AdminComponents.action
          id="cancel-link-edition"
          anatomy="a2"
          role="terciaria"
          phx-click="cancel-link-edition"
        >
          Cancelar
        </AdminComponents.action>
      </div>
      <form
        :if={!@edition_prompt}
        id={"#{@id}-form"}
        phx-submit="link-bgg-save"
        phx-change="link-bgg-input"
      >
        <AdminComponents.field
          type="text"
          name="bgg_id"
          id={"#{@id}-input"}
          label="ID o link de BGG"
          value={@value}
          errors={if @error, do: [@error], else: []}
        />
        <AdminComponents.action
          anatomy="a1"
          role="principal"
          type="submit"
          class="pk-editor-sheet-save"
        >
          Vincular
        </AdminComponents.action>
      </form>
    </AdminComponents.sheet>
    """
  end

  # D-03 (revised): natural Spanish list join — mirrors `GameLive.Index`'s
  # own `edition_names/1`.
  defp edition_names(games) do
    games |> Enum.map(& &1.name) |> join_with_y()
  end

  defp join_with_y([name]), do: name
  defp join_with_y([a, b]), do: "#{a} y #{b}"

  defp join_with_y(names) do
    {last, rest} = List.pop_at(names, -1)
    Enum.join(rest, ", ") <> " y " <> last
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      admin_chrome
      fullbleed
      bottom_collapse
      suppress_tab_bar
    >
      <div id="game-editor" class="pk-game-editor">
        <div id="editor-topbar" class="pk-editor-topbar" phx-hook="EditorShell">
          <button
            type="button"
            class="pk-editor-topbar__back"
            aria-label="Volver a Juegos"
            data-pk-pressable="true"
            phx-click="back-clicked"
          >
            <.icon name="hero-chevron-left-mini" class="size-5" />
          </button>
          <span class="pk-editor-topbar__title">{@game.name}</span>
          <button
            type="button"
            class="pk-editor-topbar__menu"
            aria-label="Más acciones"
            aria-haspopup="dialog"
            aria-expanded={to_string(@menu_open)}
            data-pk-pressable="true"
            phx-click="open-menu"
          >
            <.icon name="hero-ellipsis-vertical" class="size-5" />
          </button>
        </div>

        <div
          :if={franja_text(@game.status)}
          class="pk-editor-franja"
          data-pk-editor-franja={@game.status}
        >
          <span
            class={["pk-editor-franja__dot", "pk-editor-franja__dot--#{@game.status}"]}
            aria-hidden="true"
          ></span>
          <span class="pk-editor-franja__text">{franja_text(@game.status)}</span>
        </div>

        <div class="pk-editor-body pk-admin-has-save-bar">
          <div :if={failed?(@game)} class="pk-editor-error">
            <span>Error al traer datos de BGG.</span>
            <AdminComponents.action
              anatomy="a2"
              role="terciaria"
              phx-click="retry-enrichment"
              phx-value-game-id={@game.id}
            >
              Reintentar
            </AdminComponents.action>
          </div>

          <%!-- pills: today, only the nivel chip (D-26's other public-ficha
          pills — players/playtime/min_age — are BGG-derived and add no
          editable signal here; nivel is the one club-owned fact this row
          exists to surface). --%>
          <div class="pk-editor-pills">
            <button
              type="button"
              class="pk-editor-pill pk-editor-pill--editable"
              data-pk-pressable="true"
              phx-click="edit-field"
              phx-value-field="weight_band"
            >
              {weight_band_label(@draft.weight_band)}
              <span class="pk-editor-pencil" aria-hidden="true">
                <.icon name="hero-pencil" class="size-3" />
              </span>
            </button>
          </div>

          <%!-- tapa: pencil corner badge only, no phx-click — see this
          module's own moduledoc on `edit-field` field="cover". --%>
          <div class="pk-editor-cover">
            <img :if={@game.cover_url} src={@game.cover_url} alt="" class="pk-editor-cover__img" />
            <span class="pk-editor-cover__pencil" aria-hidden="true">
              <.icon name="hero-pencil" class="size-3" />
            </span>
          </div>

          <button
            type="button"
            class="pk-editor-title"
            data-pk-pressable="true"
            phx-click="edit-field"
            phx-value-field="name"
          >
            {@draft.name}
            <span class="pk-editor-pencil" aria-hidden="true">
              <.icon name="hero-pencil" class="size-3" />
            </span>
          </button>

          <span :if={@game.section_names != []} class="pk-editor-section-chip">
            {hd(@game.section_names)}
          </span>

          <button
            :if={@draft.description}
            type="button"
            class="pk-editor-desc"
            data-pk-pressable="true"
            phx-click="edit-field"
            phx-value-field="description"
          >
            <span class="pk-editor-desc__text">{@draft.description}</span>
            <span class="pk-editor-pencil" aria-hidden="true">
              <.icon name="hero-pencil" class="size-3" />
            </span>
          </button>

          <dl class="pk-editor-facts">
            <div>
              <dt>Año</dt>
              <dd>{value_or_dash(@game.year_published)}</dd>
            </div>
            <div>
              <dt>Diseñadores</dt>
              <dd>{join_names(@game.designers)}</dd>
            </div>
            <div>
              <dt>Ilustradores</dt>
              <dd>{join_names(@game.artists)}</dd>
            </div>
            <div>
              <dt>Mecánicas</dt>
              <dd>{mechanics_text(@game)}</dd>
            </div>
            <div>
              <dt>Temáticas</dt>
              <dd>{themes_text(@game)}</dd>
            </div>
          </dl>

          <div class="pk-editor-divider"></div>

          <%!-- D-31, plan 01.8.2-21: the Copias stepper — deliberately NOT
          `editable_row/1` (D-23 puts steppers out of that anatomy's
          scope). Writes copy rows directly, immediately — see this
          module's own moduledoc. --%>
          <AdminComponents.stepper_row
            label="Copias"
            value={to_string(length(@copies))}
            decrement_event="copias-decrement"
            increment_event="copias-increment"
          />
          <AdminComponents.editable_row
            label="Estante"
            value={estante_value(@copy_context, @copies)}
            phx-click="edit-field"
            phx-value-field="shelf_id"
          />
          <AdminComponents.editable_row
            label="Es una expansión"
            value={if @draft.is_expansion, do: "Sí", else: "No"}
            phx-click="edit-field"
            phx-value-field="is_expansion"
          />
        </div>
      </div>

      <AdminComponents.sheet
        :if={lifecycle_action(@game.status)}
        id="editor-lifecycle-sheet"
        title="Ciclo del juego"
        subtitle={elem(lifecycle_action(@game.status), 1)}
        open={@menu_open}
        on_close={JS.push("close-menu")}
      >
        <AdminComponents.action
          anatomy="a4"
          role={if @game.status == :published, do: "peligro", else: "terciaria"}
          phx-click={elem(lifecycle_action(@game.status), 2)}
        >
          {elem(lifecycle_action(@game.status), 0)}
        </AdminComponents.action>
        <AdminComponents.action
          :if={is_nil(@game.bgg_id)}
          id="editor-link-bgg"
          anatomy="a4"
          role="terciaria"
          phx-click="open-bgg-link"
        >
          Vincular con BGG
        </AdminComponents.action>
        <AdminComponents.action
          :if={@game.bgg_id}
          id="editor-retry-enrichment"
          anatomy="a4"
          role="terciaria"
          phx-click="retry-enrichment"
          phx-value-game-id={@game.id}
        >
          Reintentar
        </AdminComponents.action>
        <AdminComponents.action
          :if={borrar_bgg_id_offered?(@game)}
          id="editor-borrar-bgg-id"
          anatomy="a4"
          role="peligro"
          phx-click="borrar-bgg-id"
        >
          Borrar el ID
        </AdminComponents.action>
      </AdminComponents.sheet>

      <%!-- D-30's choice-field sheets (D-23's tick, never a tint; choosing
      commits and closes — see `choice_sheet/1`'s own moduledoc). --%>
      <.choice_sheet
        id="editor-weight-band-sheet"
        title="Nivel"
        field={:weight_band}
        options={
          Enum.map(
            Vocabulary.weight_bands(),
            &%{value: &1.value, label: &1.label, sub: &1.descriptor}
          )
        }
        selected={@draft.weight_band}
        open={@open_sheet == :weight_band}
        on_close={JS.push("close-field-sheet")}
      />
      <.choice_sheet
        id="editor-is-expansion-sheet"
        title="Es una expansión"
        field={:is_expansion}
        options={[%{value: true, label: "Sí"}, %{value: false, label: "No"}]}
        selected={@draft.is_expansion}
        open={@open_sheet == :is_expansion}
        on_close={JS.push("close-field-sheet")}
      />

      <%!-- D-30's text-field sheets (a wide in-sheet `Guardar`; ✕ discards
      — see `text_sheet/1`'s own moduledoc). --%>
      <.text_sheet
        id="editor-name-sheet"
        title="Nombre"
        field={:name}
        label="Nombre"
        value={@sheet_value || @draft.name}
        error={@sheet_error}
        open={@open_sheet == :name}
        on_close={JS.push("close-field-sheet")}
      />
      <.text_sheet
        id="editor-description-sheet"
        title="Descripción"
        field={:description}
        label="Descripción"
        value={@sheet_value || @draft.description}
        error={@sheet_error}
        textarea
        open={@open_sheet == :description}
        on_close={JS.push("close-field-sheet")}
      />

      <%!-- Open item 3, D-38 — the link-a-BGG-id sheet. --%>
      <.bgg_link_sheet
        id="editor-bgg-link-sheet"
        value={@bgg_link_value}
        error={@bgg_link_error}
        edition_prompt={@bgg_link_edition_prompt}
        open={@open_sheet == :bgg_link}
        on_close={JS.push("close-field-sheet")}
      />

      <%!-- D-31, plan 01.8.2-21 — Copias' which-copy-to-remove sheet:
      opened only when every copy is placed, so every row here IS placed
      (D-02's copy-row write, T-01.8.2-102's mitigation). --%>
      <AdminComponents.sheet
        :if={@which_copy_sheet}
        id="editor-which-copy-sheet"
        title="¿Cuál copia sacamos?"
        open
        on_close={JS.push("close-which-copy-sheet")}
      >
        <AdminComponents.list_row
          :for={copy <- @which_copy_sheet || []}
          id={"editor-which-copy-#{copy.id}"}
          name={which_copy_name(copy, length(@which_copy_sheet || []))}
          meta={which_copy_meta(copy)}
          phx-click="copias-remove-copy"
          phx-value-copy-id={copy.id}
        />
      </AdminComponents.sheet>

      <%!-- D-32, plan 01.8.2-21 — a multi-copy game's ESTANTE block asks
      which copy before opening the position-aware sheet, when no copy
      context was carried in (`?copy=<id>`). --%>
      <AdminComponents.sheet
        :if={@copy_picker_open}
        id="editor-copy-picker-sheet"
        title="¿Qué copia?"
        open
        on_close={JS.push("close-copy-picker")}
      >
        <AdminComponents.list_row
          :for={copy <- @copies}
          id={"editor-copy-picker-#{copy.id}"}
          name={which_copy_name(copy, length(@copies))}
          meta={which_copy_meta(copy)}
          phx-click="pick-copy-context"
          phx-value-copy-id={copy.id}
        />
      </AdminComponents.sheet>

      <%!-- D-32, plan 01.8.2-21 — the SAME position-aware "¿Dónde va?"
      sheet `EstanteLive.Index` uses. --%>
      <AdminComponents.placement_sheet
        :if={@shelf_sheet}
        id="editor-shelf-sheet"
        state={@shelf_sheet}
      />

      <AdminComponents.dialog
        id="editor-discard-dialog"
        question="¿Salir sin guardar?"
        consequence="Los cambios que hiciste se pierden."
        verb="Salir"
        open={@confirm_discard}
        on_confirm={JS.push("confirm-discard")}
        on_cancel={JS.push("cancel-discard")}
      />

      <AdminComponents.dialog
        id="editor-retire-dialog"
        question={"¿Retirar #{@game.name}?"}
        consequence="El club ya no lo tiene. No va a aparecer más en la ludoteca pública ni en los estantes. Vas a poder restaurarlo después."
        verb="Retirar"
        open={@confirm_retire}
        on_confirm={JS.push("confirm-retire")}
        on_cancel={JS.push("cancel-retire")}
      />

      <AdminComponents.snackbar
        :if={@action_snackbar}
        id={@action_snackbar.id}
        message={@action_snackbar.message}
        action={@action_snackbar.action}
        on_close={JS.push("dismiss-action-snackbar")}
      />

      <AdminComponents.save_bar
        dirty={dirty?(@draft, @saved)}
        on_save={JS.push("save")}
      />
    </Layouts.app>
    """
  end

  defp failed?(game), do: game.enrichment_status == "failed"
end
