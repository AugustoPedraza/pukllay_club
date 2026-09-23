defmodule PukllayClubWeb.Admin.GameLive.Form do
  @moduledoc """
  The game editor, at `/admin/juegos/:id/editar` — D-27's one 56px top app
  bar, D-29's consequence franja, D-28's fixed foot save bar, and D-26's
  ficha-mirroring body (plan 01.8.2-17).

  `mount/3` loads via `Catalog.get_game!/1` — the unfiltered ADMIN read —
  so a `:draft` or `:retired` game opens here exactly as readily as a
  `:published` one (D-30's normal flow only ever routes a published game
  here via the Juegos list's row chevron; a direct URL still resolves for
  any status, matching every other admin fetch in this app).

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

  The `"draft-change"` event is this plan's own generic write-into-the-
  draft entry point — plan 01.8.2-19's field sheets are the first real
  callers; this plan wires the plumbing (and exercises it directly in its
  own tests) but ships no sheet UI of its own. Every editable block's own
  `"edit-field"` click currently does nothing beyond naming which field was
  tapped — the sheet bodies are plan 01.8.2-19's scope, named at each call
  site.
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
    game = id |> Catalog.get_game!() |> Catalog.put_section_names()
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
     |> assign(:confirm_discard, false)}
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

  # Every editable block's open event, for plan 01.8.2-19 to replace with
  # real sheet-opening logic — see this module's own moduledoc. The
  # cover's pencil (`edit-field` field="cover") is deliberately NOT wired
  # to this or any handler: `admin-game-editor.md`'s own "What to Avoid"
  # section records that redrawing the cover reverts 01.3.1/D-07 on
  # purpose, the badge exists because the pencil needs a target, not
  # because the cover is genuinely editable.
  @impl true
  def handle_event("edit-field", %{"field" => _field}, socket) do
    {:noreply, socket}
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

  @impl true
  def handle_event("confirm-retire", _params, socket) do
    case Catalog.retire_game(socket.assigns.game) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(:game, game)
         |> assign(:confirm_retire, false)
         |> put_flash(:info, "Juego retirado.")}

      {:error, _changeset} ->
        {:noreply, assign(socket, :confirm_retire, false)}
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

      {:error, _reason} ->
        {:noreply, assign(socket, :menu_open, false)}
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
