defmodule PukllayClubWeb.Admin.GameLive.Form do
  @moduledoc """
  The game editor, at `/admin/juegos/:id/editar` — D-27's one 56px top app
  bar, D-29's consequence franja, D-28's fixed foot save bar, and D-26's
  ficha-mirroring body (plan 01.8.2-17).

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
  :shelf_id]`, T-01.8.2-75/T-01.8.1-21) — never widened here, and the
  Copias write path is deliberately NOT routed through it (D-31, plan
  01.8.2-21 owns that write). `status` sits OUTSIDE the draft entirely: the
  ⋮ menu's lifecycle actions (`Catalog.retire_game/1`/`restore_game/1`)
  commit on their own, never through `Guardar`.

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
  edit). Only the foot `save_bar/1` ever reaches the database — a field
  sheet, whichever pattern, never calls `Catalog` directly.

  Copias and Estante (`field="copias"`/`field="shelf_id"`) are
  deliberately **not** wired to either pattern here — D-31/D-32 give them
  their own write paths, plan 01.8.2-21's scope. The cover's pencil
  (`field="cover"`) stays inert, per this module's own note below.
  """
  use PukllayClubWeb, :live_view

  alias Phoenix.LiveView.JS
  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Shelves
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClubWeb.AdminComponents

  # D-31/D-27: the five-field cast ceiling `Game.admin_changeset/2` pins —
  # restated here (not re-derived) so the draft/saved maps this module
  # builds can never silently drift from what the changeset actually
  # accepts. Widening this list without ALSO widening the changeset (or
  # vice versa) is caught immediately: a field present here but absent from
  # the changeset is simply dropped on save (Ecto's own `cast/3` contract),
  # never persisted and never an error.
  @draft_fields [:name, :weight_band, :is_expansion, :description, :shelf_id]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    game = Catalog.get_game!(id)

    if game.status == :draft do
      # D-30/plan 01.8.2-20: this page is for an already-published (or
      # retired) game only. A direct URL to a draft's editor — the row no
      # longer carries a chevron here (D-19i), but the URL is still
      # guessable — never renders a half-editor; it hands the game straight
      # back to the list, which opens the same draft's sheet.
      {:ok, push_navigate(socket, to: ~p"/admin/juegos?#{%{draft: game.id}}")}
    else
      game = Catalog.put_section_names(game)
      draft = draft_from_game(game)

      {:ok,
       socket
       |> assign(:page_title, game.name)
       |> assign(:game, game)
       |> assign(:draft, draft)
       |> assign(:saved, draft)
       |> assign(:shelves, Shelves.list_shelves())
       |> assign(:copies_count, Shelves.count_for_game(game.id))
       |> assign(:menu_open, false)
       |> assign(:confirm_retire, false)
       |> assign(:confirm_discard, false)
       |> assign(:open_sheet, nil)
       |> assign(:sheet_value, nil)
       |> assign(:sheet_error, nil)}
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
    case Catalog.update_game_admin(socket.assigns.game, socket.assigns.draft) do
      {:ok, game} ->
        game = Catalog.put_section_names(game)
        saved = draft_from_game(game)

        {:noreply,
         socket
         |> assign(:game, game)
         |> assign(:page_title, game.name)
         |> assign(:draft, saved)
         |> assign(:saved, saved)
         |> assign(:copies_count, Shelves.count_for_game(game.id))
         |> put_flash(:info, "Cambios guardados.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "No se pudo guardar. Revisá los datos.")}
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

  # Every editable block's open event. The two choice fields (D-23/D-30)
  # open `choice_sheet/1`; the two text fields open `text_sheet/1`,
  # priming `@sheet_value` from the CURRENT draft so a sheet reopened after
  # a discard shows the draft's real value, not a stale typed one.
  # Copias/Estante (D-31/D-32, plan 01.8.2-21's own write paths) and the
  # cover (`field="cover"`, deliberately inert — `admin-game-editor.md`'s
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
  # half from `"draft-change"`'s own no-op-on-stale-field guard.
  @impl true
  def handle_event("close-field-sheet", _params, socket) do
    {:noreply,
     socket
     |> assign(:open_sheet, nil)
     |> assign(:sheet_value, nil)
     |> assign(:sheet_error, nil)}
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

  # D-03: `game-id` (never the reserved `value` key — project memory rule)
  # is parsed defensively even though this screen only ever renders one
  # game's own id.
  @impl true
  def handle_event("retry-enrichment", %{"game-id" => game_id}, socket) do
    case Integer.parse(game_id) do
      {int_id, ""} ->
        case int_id |> Catalog.get_game!() |> Catalog.retry_enrichment() do
          {:ok, updated} ->
            updated = Catalog.put_section_names(updated)

            {:noreply,
             socket
             |> assign(:game, updated)
             |> assign(:draft, draft_from_game(updated))
             |> assign(:saved, draft_from_game(updated))}

          {:error, :not_failed} ->
            {:noreply, socket}
        end

      _not_an_integer ->
        {:noreply, socket}
    end
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

  defp failed?(game), do: game.enrichment_status == "failed"

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

  defp shelf_name(nil, _shelves), do: "Sin ubicar"

  defp shelf_name(shelf_id, shelves) do
    case Enum.find(shelves, &(&1.id == shelf_id)) do
      nil -> "Sin ubicar"
      shelf -> shelf.name
    end
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

          <AdminComponents.editable_row
            label="Copias"
            value={to_string(@copies_count)}
            phx-click="edit-field"
            phx-value-field="copias"
          />
          <AdminComponents.editable_row
            label="Estante"
            value={shelf_name(@draft.shelf_id, @shelves)}
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

      <AdminComponents.save_bar
        dirty={dirty?(@draft, @saved)}
        on_save={JS.push("save")}
      />
    </Layouts.app>
    """
  end
end
