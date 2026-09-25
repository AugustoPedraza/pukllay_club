defmodule PukllayClubWeb.AdminComponents do
  @moduledoc """
  The one admin component module (D-18): the atoms every `/admin` screen and
  the shared staff chrome compose from. Consistency is held here, in code —
  screens cannot hand-roll a field, a row, a status, or an action, because
  none of those exist anywhere else in the admin.

  Everything in this module follows **Scope A** (`ui-design-system`
  SKILL.md's Scope A/B switch, D-16/D-17) and 064's **S3 "Contorno"**:
  every admin action is outlined, text, or icon-only — never one of
  daisyUI's filled/ghost button variants, and never a dialog's built-in
  action-footer class (R7b, `admin-redesign-scope.md`; this plan's own
  `<verify>` greps the compiled source for those exact class names, so
  this file deliberately never spells them out even in prose). The three
  rules every caller of this module is bound by (`references/admin-
  button-system.md`):

    1. At most one outlined action (A1) per block.
    2. A page-level action is never Principal and never outlined.
    3. A row-level action is never outlined.

  Geometry throughout is `01.8.2-BENCHMARK.md`'s measured table, taken
  verbatim — never re-derived. Colour resolves through
  `01.8.2-TOKENS.md`'s reconciled tokens (`--color-surface`,
  `--color-surface-2`, `--val`, `--stroke`) or a directly shipped
  `app.css` token; this module never invents a second name for a value
  that table already fates.

  This is part one of D-18's module — the atoms (`action/1`, and, from
  plans 01.8.2-07 Task 2/3, `field/1`, `section_panel/1`, `form_label/1`,
  `list_section_label/1`, `list_row/1`, `editable_row/1`, `status_dot/1`,
  `kind_tag/1`, `count_pill/1`). Plan 01.8.2-08 adds the composites
  (bottom sheet shell, centred dialog, save bar, snackbar, back row) to
  this same module — keep any new atom's attrs and CSS class naming
  (`pk-admin-*`) consistent with the ones below so that addition doesn't
  need to restructure this file.
  """
  use Phoenix.Component

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS
  alias PukllayClub.Catalog.Shelves
  alias PukllayClubWeb.CoreComponents

  # ============================================================
  # Task 1 — the A1-A4 action system (D-18, D-00a, 064 S3 Contorno)
  # ============================================================

  @doc """
  Renders one of the four admin action anatomies (D-00a, 064 round 10 —
  "the context picks the anatomy, the role picks the paint"). No filled
  button anywhere: every anatomy is outline, text, or icon-only, or (A4) a
  full-bleed sheet row.

  ## Anatomies

    * `"a1"` — outlined: 44px tall, 16px side padding, 1px stroke, 8px
      radius, 14px/600, natural width. Carries `role="principal"` and
      `role="secundaria"` only.
    * `"a2"` — text: 44px tall, 12px side padding, no stroke, pulled
      `-12px` so the *label* lands on the content edge. Carries
      `role="terciaria"` and `role="peligro"` only.
    * `"a3"` — icon: 44x44 borderless circle, 18px glyph, pulled `-12px`
      so the *glyph* lands on the content edge. Carries `role="terciaria"`
      and `role="peligro"` only. Being icon-only, it **requires an
      `aria-label`** — rendering one without raises at render time rather
      than shipping an unlabelled control.
    * `"a4"` — sheet row: 48px, full-bleed. A sheet has no buttons at all
      (D-19e) — this is a row, not a button anatomy.

  Passing `href`/`navigate`/`patch` renders a `<.link>`; otherwise a
  `<button type="button">`.

  ## `disabled` (D-24)

  `disabled` is accepted **only** when the caller also passes
  `commit={true}` — the save/commit marker D-24 defines ("disabled means
  'nothing to write', and nothing else"). Passing `disabled={true}`
  without `commit={true}` raises at render time, naming D-24: a gate on
  missing data must stay live and explain on tap, never render as a dead
  control. When legitimately disabled, the control is painted with muted
  colour stops (`--color-neutral`) — never `opacity`, which would dim the
  label that is the only thing saying what the control does when it
  revives.

  Every anatomy carries `data-pk-pressable` so `admin/tokens.css`'s D-19o
  press-state rule (`[data-pk-pressable]:active`) applies uniformly.
  """
  attr :anatomy, :string, required: true, values: ~w(a1 a2 a3 a4)
  attr :role, :string, required: true, values: ~w(principal secundaria terciaria peligro)
  attr :disabled, :boolean, default: false
  attr :commit, :boolean, default: false
  attr :class, :any, default: nil

  attr :rest, :global, include: ~w(href navigate patch method download name value form type)

  slot :inner_block, required: true

  def action(assigns) do
    if assigns.disabled and not assigns.commit do
      raise ArgumentError, """
      AdminComponents.action/1: `disabled` is only accepted when `commit={true}` \
      (D-24 — disabled means "nothing to write", and nothing else). A gate on \
      missing data must stay live and explain on tap; it may never render as a \
      dead control.\
      """
    end

    if assigns.anatomy == "a3" and blank?(assigns.rest[:"aria-label"]) do
      raise ArgumentError, """
      AdminComponents.action/1: anatomy="a3" (icon-only) requires an aria-label \
      — an icon-only control with no accessible name cannot ship.\
      """
    end

    is_link? = !!(assigns.rest[:href] || assigns.rest[:navigate] || assigns.rest[:patch])
    # Plan 01.8.2-11 (Rule 1 — bug): `:rest`'s own `include:` list already
    # names `type` as a legitimate pass-through attribute (a form's submit
    # button, e.g. the Staff invite form's `action/1`), but the button
    # branch below used to hardcode `type="button"` unconditionally,
    # silently discarding whatever `type` a caller passed via `rest` (a
    # second `type` attribute after the static one — the browser keeps
    # only the first, so the override never took effect and no button
    # rendered by this component could ever submit its enclosing form).
    # `button_type` reads the caller's own value with a `"button"`
    # fallback, and the key is stripped from `rest` before the spread so
    # exactly one `type` attribute is ever emitted.
    button_type = assigns.rest[:type] || "button"

    assigns =
      assign(assigns,
        variant_class: "pk-admin-action--#{assigns.anatomy} pk-admin-action--#{assigns.role}",
        button_type: button_type,
        rest: Map.delete(assigns.rest, :type)
      )

    if is_link? do
      ~H"""
      <.link
        class={[
          "pk-admin-action",
          @variant_class,
          @disabled && "pk-admin-action--disabled",
          @class
        ]}
        aria-disabled={@disabled}
        data-pk-pressable="true"
        {@rest}
      >{render_slot(@inner_block)}</.link>
      """
    else
      ~H"""
      <button
        type={@button_type}
        class={[
          "pk-admin-action",
          @variant_class,
          @disabled && "pk-admin-action--disabled",
          @class
        ]}
        disabled={@disabled}
        data-pk-pressable="true"
        {@rest}
      >{render_slot(@inner_block)}</button>
      """
    end
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_), do: false

  # ============================================================
  # Task 2 — field, section panel, and the two label ranks
  # ============================================================

  @doc """
  Renders an admin form field — the same `Phoenix.HTML.FormField` plumbing
  `PukllayClubWeb.CoreComponents.input/1` uses (`used_input?/1` gating,
  `CoreComponents.translate_error/1`), in Scope A chrome: label above the
  control, the control 44px tall with a 1px `--stroke` border and 8px
  radius, and 16px input text under a coarse-pointer media query so iOS
  never zooms on focus (`01.8.2-BENCHMARK.md`'s "Field" row).

  Accepts `type`: `"text"`, `"number"`, `"email"`, `"select"`, `"textarea"`,
  `"checkbox"` — the same subset `admin_components_test.exs` exercises.
  `"email"` added by plan 01.8.2-11 (Rule 3 — the Staff invite field needs
  it; the catch-all clause below already renders `<input type={@type}>`
  generically, so this was a one-line `values:` gap, not new behaviour).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string, default: "text", values: ~w(text number email select textarea checkbox)

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :class, :any, default: nil

  attr :rest, :global, include: ~w(accept autocomplete cols disabled form list max maxlength min minlength
                pattern placeholder readonly required rows size step)

  def field(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &CoreComponents.translate_error/1))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> field()
  end

  def field(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="pk-admin-field">
      <label for={@id} class="pk-admin-field__checkbox-label">
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <input type="checkbox" id={@id} name={@name} value="true" checked={@checked} {@rest} />
        <span :if={@label} class="pk-admin-label pk-admin-label--field">{@label}</span>
      </label>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
    </div>
    """
  end

  def field(%{type: "select"} = assigns) do
    ~H"""
    <div class="pk-admin-field">
      <label for={@id} class="pk-admin-field__label-wrap">
        <span :if={@label} class="pk-admin-label pk-admin-label--field">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            @class || "pk-admin-field__control",
            @errors != [] && "pk-admin-field__control--error"
          ]}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
    </div>
    """
  end

  def field(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="pk-admin-field">
      <label for={@id} class="pk-admin-field__label-wrap">
        <span :if={@label} class="pk-admin-label pk-admin-label--field">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "pk-admin-field__control pk-admin-field__control--textarea",
            @errors != [] && "pk-admin-field__control--error"
          ]}
          {@rest}
        >{Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
    </div>
    """
  end

  # text, number, and any other input type this attr's `values:` allows.
  def field(assigns) do
    ~H"""
    <div class="pk-admin-field">
      <label for={@id} class="pk-admin-field__label-wrap">
        <span :if={@label} class="pk-admin-label pk-admin-label--field">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Form.normalize_value(@type, @value)}
          class={[
            @class || "pk-admin-field__control",
            @errors != [] && "pk-admin-field__control--error"
          ]}
          {@rest}
        />
      </label>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
    </div>
    """
  end

  attr :rest, :global
  slot :inner_block, required: true

  defp field_error(assigns) do
    ~H"""
    <p class="pk-admin-field__error">{render_slot(@inner_block)}</p>
    """
  end

  @doc """
  Renders a tonal section panel: `--color-surface` fill, no border, 12px
  radius, 16px padding (`01.8.2-BENCHMARK.md`'s "Section panel" row). The
  optional `:label` slot renders as a `form_label/1 rank="group"` caption
  above the panel body.
  """
  attr :class, :any, default: nil
  slot :label
  slot :inner_block, required: true

  def section_panel(assigns) do
    ~H"""
    <section class={["pk-admin-section-panel", @class]}>
      <p :if={@label != []} class="pk-admin-label pk-admin-label--group">{render_slot(@label)}</p>
      {render_slot(@inner_block)}
    </section>
    """
  end

  @doc """
  Renders one of the two **form** label ranks (`01.8.2-BENCHMARK.md`'s
  "Label (field)" / "Label (group)" rows — BOTH govern a form label, not a
  list section header; see `list_section_label/1` for that rank, which
  must never collapse onto either of these):

    * `rank="field"` — 12px/600, muted (`--color-neutral`). Sits directly
      above one control.
    * `rank="group"` — 13px/600, sentence case, full strength
      (`--color-base-content`). Sits above a group of fields.
  """
  attr :rank, :string, required: true, values: ~w(field group)
  slot :inner_block, required: true

  def form_label(assigns) do
    ~H"""
    <span class={["pk-admin-label", "pk-admin-label--#{@rank}"]}>{render_slot(@inner_block)}</span>
    """
  end

  @doc """
  Renders a **list** section header caption (D-19g-bis decision 20): 15px/
  600 at full strength (`--color-base-content`) — above `form_label/1`'s
  13px/600 "group" rank, and above `list_row/1`'s own 14px row name, on
  purpose. A list section label organises the rows beneath it and must
  never read as smaller or lower-contrast than they are; conflating this
  rank with the BENCHMARK's *form* "Label (group)" row is exactly the
  inverted-ladder bug D-19g-bis decision 20 records and fixes. Renders a
  plain `<span>` — never a control (no caret, no `aria-expanded`, no 44px
  target): this atom renders one caption, not a collapsible section: that
  behaviour belongs to whatever screen composes it.
  """
  slot :inner_block, required: true

  def list_section_label(assigns) do
    ~H"""
    <span class="pk-admin-list-section-label">{render_slot(@inner_block)}</span>
    """
  end

  # ============================================================
  # Task 3 — list row, editable-value row, status dot, kind tag, count pill
  # ============================================================

  @doc """
  Renders a 44px-floor list row: an optional 40px `cover`, a wrapping
  `name` at 14px/600, an optional 13px muted second line (`meta`), and an
  optional `:trailing` slot for a count pill / kind tag / other trailing
  content. Renders a trailing chevron **only** when `opens_page={true}`
  (D-19i — a chevron means "this row opens another page", and nothing
  else); `opens_page` defaults to `false` so a row that acts in place is
  the cheap path. Passing `href`/`navigate`/`patch` renders a `<.link>`;
  otherwise a `<div>` (the caller wires its own `phx-click` via `rest`).
  """
  attr :cover, :string, default: nil
  attr :name, :string, required: true
  attr :meta, :string, default: nil
  attr :opens_page, :boolean, default: false
  attr :class, :any, default: nil

  attr :rest, :global, include: ~w(href navigate patch)

  slot :trailing

  def list_row(assigns) do
    if assigns.rest[:href] || assigns.rest[:navigate] || assigns.rest[:patch] do
      ~H"""
      <.link class={["pk-admin-row", @class]} data-pk-pressable="true" {@rest}>
        <img :if={@cover} src={@cover} alt="" class="pk-admin-row__cover" />
        <span class="pk-admin-row__body">
          <span class="pk-admin-row__name">{@name}</span>
          <span :if={@meta} class="pk-admin-row__meta">{@meta}</span>
        </span>
        {render_slot(@trailing)}
        <span :if={@opens_page} class="pk-admin-row__chevron" aria-hidden="true">›</span>
      </.link>
      """
    else
      ~H"""
      <div class={["pk-admin-row", @class]} data-pk-pressable="true" tabindex="0" {@rest}>
        <img :if={@cover} src={@cover} alt="" class="pk-admin-row__cover" />
        <span class="pk-admin-row__body">
          <span class="pk-admin-row__name">{@name}</span>
          <span :if={@meta} class="pk-admin-row__meta">{@meta}</span>
        </span>
        {render_slot(@trailing)}
        <span :if={@opens_page} class="pk-admin-row__chevron" aria-hidden="true">›</span>
      </div>
      """
    end
  end

  @doc """
  Renders D-23's one anatomy for an editable value: a row that opens a
  sheet, line 1 `label` (prominent, 14px/600), line 2 `value` (subordinate,
  13px, carrying the `--val` tint). Renders **no glyph at all** — not `›`
  (D-19i reserves that for "this row opens another page") and not the `⌄`
  that briefly replaced it. The tint marks the datum you are about to
  change, never "this row is tappable" — `list_row/1` above is the
  contrasting, tappable-but-untinted case. Always a `<button>`: an
  editable value opens a sheet in place, it never navigates.
  """
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :class, :any, default: nil

  attr :rest, :global, include: ~w(phx-click type)

  def editable_row(assigns) do
    ~H"""
    <button type="button" class={["pk-admin-editable-row", @class]} data-pk-pressable="true" {@rest}>
      <span class="pk-admin-editable-row__label">{@label}</span>
      <span class="pk-admin-editable-row__value">{@value}</span>
    </button>
    """
  end

  @doc """
  Renders a stepper row (D-23 explicitly puts steppers OUT of
  `editable_row/1`'s "row that opens a sheet" scope — a stepper acts in
  place, on both taps, never opening anything itself). `−`/`+` are
  plain buttons, never `action/1` (D-24's `disabled` contract governs
  ONLY save/commit controls; a stepper floor is a structural bound, not
  an empty diff) — per `Shelves.move_shelf/2`'s own documented
  precedent, "prefer enabled-and-no-op over disabled" at either end, so
  `−`/`+` are ALWAYS enabled and the caller's own handler no-ops at the
  floor.
  """
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :decrement_event, :string, required: true
  attr :increment_event, :string, required: true
  attr :class, :any, default: nil

  def stepper_row(assigns) do
    ~H"""
    <div class={["pk-admin-stepper-row", @class]}>
      <span class="pk-admin-stepper-row__label">{@label}</span>
      <div class="pk-admin-stepper-row__control">
        <button
          type="button"
          class="pk-admin-stepper-row__btn"
          data-pk-pressable="true"
          aria-label={"Restar #{@label}"}
          phx-click={@decrement_event}
        >
          <CoreComponents.icon name="hero-minus" class="size-4" />
        </button>
        <span class="pk-admin-stepper-row__value">{@value}</span>
        <button
          type="button"
          class="pk-admin-stepper-row__btn"
          data-pk-pressable="true"
          aria-label={"Sumar #{@label}"}
          phx-click={@increment_event}
        >
          <CoreComponents.icon name="hero-plus" class="size-4" />
        </button>
      </div>
    </div>
    """
  end

  # ============================================================
  # Plan 01.8.2-21, Task 2 (D-32) — the ONE shared "¿Dónde va?" placement
  # sheet: originally built inline inside `EstanteLive.Index` (plan
  # 01.8.2-16), extracted here so `GameLive.Form`'s ESTANTE block reuses
  # the SAME position-aware sheet rather than growing a second,
  # position-blind one. `PukllayClubWeb.Admin.PlacementSheet` holds the
  # matching pure state-transition logic; this component is the render
  # half only. Every event name below is a literal string BOTH callers
  # implement identically in their own `handle_event/3` — this component
  # does not own a `phx-target`, so the enclosing LiveView's own process
  # receives every event, exactly as a plain function component's
  # `phx-click`/`phx-change` always has.
  # ============================================================

  @doc """
  Renders D-00c's full-height "¿Dónde va?" sheet: search-an-estante-or-
  copy, an idle estante list, search results, and — once an estante is
  chosen — its rail with N+1 "+" slots. `state` is
  `PukllayClubWeb.Admin.PlacementSheet.open/1`'s own shape (`%{copy:,
  query:, results:, estante:, copies:}`) or `nil` to render nothing
  (the caller wraps the call site in `:if={@state}`, matching `sheet/1`'s
  own convention elsewhere).

  Wires the SAME event names `EstanteLive.Index` always used
  (`donde-va-search`, `donde-va-field-clear`, `donde-va-pick-estante`,
  `donde-va-pick-copy`, `donde-va-commit`, `donde-va-close`) — extracting
  this component changed nothing about its wire contract, so
  `estante_live_test.exs`'s existing `render_click`/`render_change`
  calls against those literal event names stay valid unmodified.

  `id` sets ONLY the outer sheet wrapper's own id — every INNER id is
  the literal `donde-va-*` prefix the original `EstanteLive.Index`
  implementation always used (`donde-va-search-input`,
  `donde-va-shelf-<id>`, `donde-va-result-shelf-<id>`, ...), never
  derived from `id`, so the extraction is byte-identical for
  `EstanteLive.Index`'s existing element selectors. Both callers render
  this sheet on mutually exclusive pages (never both mounted at once),
  so the fixed inner-id convention cannot collide between them.
  """
  attr :id, :string, required: true
  attr :state, :map, required: true

  def placement_sheet(assigns) do
    ~H"""
    <.sheet
      id={@id}
      title="¿Dónde va?"
      subtitle={@state.copy.game.name}
      cover={@state.copy.game.thumbnail_url}
      open
      on_close={JS.push("donde-va-close")}
      class="pk-estantes-sheet--full"
    >
      <div class="pk-donde-va-search">
        <input
          type="text"
          id="donde-va-search-input"
          name="q"
          value={@state.query}
          placeholder="Buscá un estante o un juego"
          aria-label="Buscá un estante o un juego"
          autocomplete="off"
          phx-change="donde-va-search"
          phx-debounce="200"
          onfocus="this.select()"
        />
        <button
          :if={@state.query != ""}
          type="button"
          class="pk-estantes-search__clear"
          aria-label="Limpiar"
          phx-click="donde-va-field-clear"
        >
          <CoreComponents.icon name="hero-x-mark" class="size-5" />
        </button>
      </div>

      <div :if={is_nil(@state.estante) and @state.query == ""} id="donde-va-estante-list">
        <.list_section_label>O elegí un estante</.list_section_label>
        <.list_row
          :for={shelf <- Shelves.list_shelves()}
          id={"donde-va-shelf-#{shelf.id}"}
          name={shelf.name}
          meta={placement_shelf_meta(shelf)}
          phx-click="donde-va-pick-estante"
          phx-value-shelf-id={shelf.id}
        />
      </div>

      <div
        :if={is_nil(@state.estante) and @state.query != "" and @state.results == []}
        class="pk-estantes-no-match"
      >
        <p class="pk-estantes-no-match__hint">Ningún estante ni juego se llama así.</p>
      </div>

      <div :if={is_nil(@state.estante) and @state.results != []} id="donde-va-results">
        <.placement_result_row :for={result <- @state.results} result={result} />
      </div>

      <div :if={@state.estante} id="donde-va-rail" class="pk-donde-va-rail">
        <button
          type="button"
          class="pk-donde-va-slot"
          data-pk-pressable="true"
          phx-click="donde-va-commit"
          phx-value-index="0"
          aria-label={placement_slot_label(@state.copies, 0, @state.estante.name)}
        >
          <span aria-hidden="true">+</span>
        </button>
        <%= for {copy, idx} <- Enum.with_index(@state.copies) do %>
          <span class="pk-poster-card pk-estantes-cover">
            <span class="pk-estantes-cover__art">
              <img
                :if={copy.game.thumbnail_url}
                src={copy.game.thumbnail_url}
                alt=""
                class="pk-estantes-cover__img"
              />
              <span :if={!copy.game.thumbnail_url} class="pk-estantes-cover__fallback">
                <CoreComponents.icon name="hero-puzzle-piece" class="size-8" />
              </span>
            </span>
          </span>
          <button
            type="button"
            class="pk-donde-va-slot"
            data-pk-pressable="true"
            phx-click="donde-va-commit"
            phx-value-index={idx + 1}
            aria-label={placement_slot_label(@state.copies, idx + 1, @state.estante.name)}
          >
            <span aria-hidden="true">+</span>
          </button>
        <% end %>
      </div>
    </.sheet>
    """
  end

  defp placement_shelf_meta(shelf) do
    case Shelves.copies_on_shelf(shelf.id) do
      [] -> "Vacío · va directo"
      copies -> "#{length(copies)} juegos"
    end
  end

  attr :result, :any, required: true

  defp placement_result_row(%{result: {:shelf, shelf}} = assigns) do
    assigns = assign(assigns, :shelf, shelf)

    ~H"""
    <.list_row
      id={"donde-va-result-shelf-#{@shelf.id}"}
      name={@shelf.name}
      meta={placement_shelf_meta(@shelf)}
      phx-click="donde-va-pick-estante"
      phx-value-shelf-id={@shelf.id}
    />
    """
  end

  defp placement_result_row(%{result: {:copy, copy}} = assigns) do
    assigns = assign(assigns, :copy, copy)

    ~H"""
    <.list_row
      id={"donde-va-result-copy-#{@copy.id}"}
      cover={@copy.game.thumbnail_url}
      name={@copy.game.name}
      meta={@copy.shelf.name}
      phx-click="donde-va-pick-copy"
      phx-value-copy-id={@copy.id}
    />
    """
  end

  # A "+" slot's accessible name (sketch 069, "Poner un juego entre X y
  # Y" / "...al principio de..." / "...al final de..."). `copies` is
  # whichever rail the slot sits in.
  defp placement_slot_label([], _index, estante_name), do: "Poner al principio de #{estante_name}"

  defp placement_slot_label(copies, 0, _estante_name) do
    "Poner antes de #{hd(copies).game.name}"
  end

  defp placement_slot_label(copies, index, estante_name) when index == length(copies) do
    "Poner después de #{List.last(copies).game.name} en #{estante_name}"
  end

  defp placement_slot_label(copies, index, _estante_name) do
    before = Enum.at(copies, index - 1)
    after_ = Enum.at(copies, index)
    "Poner entre #{before.game.name} y #{after_.game.name}"
  end

  @status_words %{
    draft: "Borrador",
    published: "Publicado",
    retired: "Retirado",
    sin_lugar: "Sin lugar",
    afuera: "Afuera",
    # Plan 01.8.2-11 (D-19h applied to Staff): a staff member's role/
    # confirmation state is genuinely a status ("who is this person to the
    # club right now"), not a game/copy status — extending the same one
    # dot-plus-word anatomy here is exactly D-18's "extend the component
    # over forking it into the screen" rule, rather than inventing a
    # second, screen-local status treatment for Staff alone.
    owner: "Dueño",
    active: "Activo",
    pending: "Invitación pendiente"
  }

  @doc """
  Renders D-19h's one status anatomy: an 8px dot in the status colour
  immediately before the word — **never a pill**. The dot is decorative
  (drawn with `currentColor`, `aria-hidden`); the word is plain text
  content, so it is always in the element's accessible name. Every status
  indicator in the admin renders through this component — tag and filter
  chips (`kind_tag/1`) are not statuses and are unaffected by D-19h.

  `status` is one of `#{inspect(Map.keys(@status_words))}` — the exact
  status vocabulary `01.8.2-UI-SPEC.md`'s copywriting contract fixes.
  """
  attr :status, :atom, required: true, values: Map.keys(@status_words)
  attr :class, :any, default: nil

  def status_dot(assigns) do
    assigns = assign(assigns, :word, Map.fetch!(@status_words, assigns.status))

    ~H"""
    <span class={["pk-admin-status-dot", "pk-admin-status-dot--#{@status}", @class]}>
      <span class="pk-admin-status-dot__dot" aria-hidden="true"></span>{@word}
    </span>
    """
  end

  @doc """
  Renders D-19m's kind tag: 18px tall, 11px regular, lowercase, on a
  hairline `--color-base-300` border, muted text — never competes with a
  row name. Not a status, so D-19h's "never a pill" rule does not apply
  here.
  """
  attr :label, :string, required: true
  attr :class, :any, default: nil

  def kind_tag(assigns) do
    ~H"""
    <span class={["pk-admin-kind-tag", @class]}>{@label}</span>
    """
  end

  @doc """
  Renders D-19m's count pill: a neutral, page-filled pill with a 1px
  `--stroke` border, 11px/600 muted text. Its number is plain text
  content, so it is always in the element's accessible name — never the
  top-right filled primary badge (that shape means *pending work*, D-19g,
  not a count).
  """
  attr :count, :integer, required: true
  attr :class, :any, default: nil

  def count_pill(assigns) do
    ~H"""
    <span class={["pk-admin-count-pill", @class]}>{@count}</span>
    """
  end

  @doc """
  Renders D-19g's pending-work accent pill: primary fill,
  `--color-primary-content` text — the SAME shape `Layouts.tab_bar/1`'s own
  pending badge (plan 01.8.2-10) paints, generalised here as a public atom
  so a screen composes it directly instead of re-deriving the shape
  (`admin-shell-navigation.md`: "A count bubble always means pending work
  — the SAME accent pill in the dashboard box, the drawer count and the
  tab badge"). Added by plan 01.8.2-11 for the Admin dashboard's boxes
  (D-18 "extend the component over forking it into the screen").

  Unlike `count_pill/1` (D-19m's neutral, non-pending shape), this atom
  IS the pending-work signal — never render it for a zero count; the
  caller gates presence, matching `count_pill/1`'s own no-guard
  convention (some callers pass pre-formatted text like "84 sin ubicar"
  that has no separate integer to gate on internally).
  """
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def pending_pill(assigns) do
    ~H"""
    <span class={["pk-admin-pending-pill", @class]}>{render_slot(@inner_block)}</span>
    """
  end

  # ============================================================
  # Plan 01.8.2-08, Task 1 — the bottom sheet shell and the centred
  # destructive dialog (D-19e, D-19f)
  # ============================================================

  @doc """
  Renders D-19e's one bottom-sheet shell: a pinned grabber + header (an
  optional 56×60 `cover`, an 18/600 `title`, a 14px `subtitle`, and a 44px
  ✕ — `action/1` `anatomy="a3"`), a full-width 1px divider, 8px, then the
  default slot's rows scrolling underneath. Caps at 85vh; a sheet taller
  than that scrolls its rows while the grabber and header stay pinned, so
  the ✕ never scrolls away.

  Renders **no** `Cancelar` row — D-19e replaces 065 round 7's commit-first/
  Cancelar-last shape outright. The optional `:commit` slot, if present,
  renders first (above the scrolling rows), for a sheet whose first row is
  a save/commit action.

  Esc, a scrim tap and a drag-down on the grabber all close the sheet
  (`assets/js/hooks/admin_sheet.js`, `phx-hook="AdminSheet"`) by clicking
  the same close control a pointer tap would — one path, not three. Open/
  closed state is the `pk-admin-overlay--open` class on the root element
  (never an inline `display`, per the 01.7 `JS.show` finding recorded as
  T-01.8.2-32) — pass `open={true}` for a sheet a LiveView assign drives,
  or leave it `false` and toggle the class client-side via
  `Phoenix.LiveView.JS.toggle_class/2`.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :cover, :string, default: nil
  attr :open, :boolean, default: false
  attr :on_close, JS, default: %JS{}
  attr :class, :any, default: nil

  slot :commit
  slot :inner_block, required: true

  def sheet(assigns) do
    ~H"""
    <div
      id={@id}
      class={["pk-admin-overlay-root", @open && "pk-admin-overlay--open", @class]}
      phx-hook="AdminSheet"
      data-pk-sheet
    >
      <div class="pk-admin-overlay-scrim" phx-click={@on_close} data-pk-sheet-scrim></div>
      <div
        class="pk-admin-sheet"
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        data-pk-sheet-panel
        tabindex="-1"
      >
        <div class="pk-admin-sheet__grabber" data-pk-sheet-grabber aria-hidden="true"></div>
        <div class="pk-admin-sheet__header">
          <img :if={@cover} src={@cover} alt="" class="pk-admin-sheet__cover" />
          <div class="pk-admin-sheet__header-text">
            <p id={"#{@id}-title"} class="pk-admin-sheet__title">{@title}</p>
            <p :if={@subtitle} class="pk-admin-sheet__subtitle">{@subtitle}</p>
          </div>
          <.action
            anatomy="a3"
            role="terciaria"
            aria-label="Cerrar"
            phx-click={@on_close}
            data-pk-sheet-close
          >
            <CoreComponents.icon name="hero-x-mark" class="size-5" />
          </.action>
        </div>
        <div class="pk-admin-sheet__divider"></div>
        <div :if={@commit != []} class="pk-admin-sheet__commit">{render_slot(@commit)}</div>
        <div class="pk-admin-sheet__rows">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  @doc """
  Renders D-19f's one destructive-confirmation anatomy: a centred 312px
  dialog, 16px radius, an 18/600 `question` naming the thing, an optional
  14px muted `consequence` line, and two right-aligned `action/1`
  `anatomy="a2"` controls — `Cancelar` first in DOM order (and carrying
  initial focus) and `verb` in the Peligro role. Never nested inside a
  `sheet/1` (T-01.8.2-30's mitigation; `admin_components_test.exs` asserts
  this directly).

  Scrim tap and Esc cancel, via the same `AdminSheet` hook `sheet/1` uses.
  """
  attr :id, :string, required: true
  attr :question, :string, required: true
  attr :consequence, :string, default: nil
  attr :verb, :string, required: true
  attr :open, :boolean, default: false
  attr :on_confirm, JS, required: true
  attr :on_cancel, JS, default: %JS{}
  attr :class, :any, default: nil

  def dialog(assigns) do
    ~H"""
    <div
      id={@id}
      class={["pk-admin-overlay-root", @open && "pk-admin-overlay--open", @class]}
      phx-hook="AdminSheet"
      data-pk-dialog
    >
      <div class="pk-admin-overlay-scrim" phx-click={@on_cancel} data-pk-sheet-scrim></div>
      <div
        class="pk-admin-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-question"}
        data-pk-sheet-panel
        tabindex="-1"
      >
        <p id={"#{@id}-question"} class="pk-admin-dialog__question">{@question}</p>
        <p :if={@consequence} class="pk-admin-dialog__consequence">{@consequence}</p>
        <div class="pk-admin-dialog__actions">
          <.action
            anatomy="a2"
            role="terciaria"
            phx-click={@on_cancel}
            data-pk-dialog-cancel
            autofocus
          >
            Cancelar
          </.action>
          <.action anatomy="a2" role="peligro" phx-click={@on_confirm}>
            {@verb}
          </.action>
        </div>
      </div>
    </div>
    """
  end

  # ============================================================
  # Plan 01.8.2-08, Task 2 — the one snackbar, replacing the top toast
  # (D-19b, D-19c)
  # ============================================================

  @doc """
  Renders D-19b/D-19c's one feedback component — the bottom snackbar,
  replacing every top-positioned toast in the admin (`Layouts.admin_flash/1`
  routes every `@admin_chrome` flash through this, per D-19c).

  Bottom-anchored, above the tab bar (via `--pk-tab-bar-h`, a custom
  property the chrome slice — plan 01.8.2-10 — sets; this component only
  consumes it, with a `0px` fallback until that slice lands), on the
  **inverse** surface (`--color-base-content` fill / `--color-base-100`
  text — the theme's own base pair, swapped, so no new token is invented
  and contrast is guaranteed by construction), 13px text, 8px radius.

  `action` (optional `%{label: string, event: string}`) carries the
  **duration contract literally in markup** — `data-timeout` is `10000`
  when an action is present (Deshacer / Reintentar, closing early on
  replacement or the ✕) and `4000` when it is not (D-19b) — so the
  duration is assertable from the rendered HTML rather than buried in a
  JS constant. Without an action, no ✕ renders at all. The message is
  wrapped in a `role="status"`/`aria-live="polite"` live region so screen
  readers announce it.

  A caller renders this at a single, stable `id` (see `admin_flash/1`'s
  own two fixed ids, one per flash kind) — a new snackbar patched into
  that id by a subsequent LiveView diff replaces the previous one's DOM
  outright, which is what "closes early on replacement" means at the
  markup layer; the timer that would otherwise auto-dismiss it is this
  plan's own scope boundary (deferred to whichever slice wires the
  runtime dismissal, per this plan's `<read_first>`).
  """
  attr :id, :string, required: true
  attr :message, :string, required: true
  attr :action, :map, default: nil, doc: "%{label: string, event: string}"
  attr :on_close, JS, default: %JS{}
  attr :class, :any, default: nil

  def snackbar(assigns) do
    # String literals, deliberately not integers: `mix format`/Styler
    # rewrites a bare integer >= 10_000 with an underscore separator
    # (`10_000`), which would defeat this plan's own `<verify>` — a literal
    # `grep -n "10000\|4000"` against this file's source. A string literal
    # is untouched by that formatter rule, so both D-19b durations stay
    # grep-visible verbatim AND `mix format --check-formatted` stays green.
    assigns = assign(assigns, :timeout, if(assigns.action, do: "10000", else: "4000"))

    ~H"""
    <div
      id={@id}
      class={["pk-admin-snackbar", @class]}
      data-pk-snackbar
      data-timeout={@timeout}
      role="status"
      aria-live="polite"
    >
      <span class="pk-admin-snackbar__message">{@message}</span>
      <div :if={@action} class="pk-admin-snackbar__actions">
        <.action
          anatomy="a2"
          role="terciaria"
          phx-click={@action.event}
          class="pk-admin-snackbar__action"
        >
          {@action.label}
        </.action>
        <.action anatomy="a3" role="terciaria" aria-label="Cerrar" phx-click={@on_close}>
          <CoreComponents.icon name="hero-x-mark" class="size-5" />
        </.action>
      </div>
    </div>
    """
  end

  # ============================================================
  # Plan 01.8.2-08, Task 3 — the fixed foot save bar, the back row and the
  # pinned page bar (D-28, D-19n)
  # ============================================================

  @doc """
  Renders D-28's fixed foot save bar: fixed at the foot, **always
  present** at 77px, page-coloured (the page ground, `--color-base-100`) so
  the only thing it draws is its 1px top line. The action is `action/1`
  `anatomy="a1"` `role="principal"` `commit={true}` — natural width,
  right-aligned on the keel, never full-width, never filled — disabled
  exactly when `dirty` is false (the one place D-24 permits a disabled
  control). The left half carries only the transient save state —
  `● Sin guardar` in `--color-warning` — while `dirty`; nothing renders
  there when clean.

  The 77px height is declared **once**, in the `--pk-save-bar-h` custom
  property, and both this rule's own `min-height` and the body's bottom
  clearance (`.pk-admin-has-save-bar`, a `calc()` off that same property)
  read from it — never two independently-typed literals that could drift
  apart (D-28's own stated reason: "an estimate hides the last block under
  a few pixels and no check notices"). The real pixel measurement against
  a live save bar is plan 01.8.2-12's CDP harness; this plan's job is the
  single-source structural contract only.
  """
  attr :dirty, :boolean, default: false
  attr :on_save, JS, required: true
  attr :status_text, :string, default: "Sin guardar"
  attr :class, :any, default: nil

  def save_bar(assigns) do
    ~H"""
    <div class={["pk-admin-save-bar", @class]} data-pk-save-bar>
      <span :if={@dirty} class="pk-admin-save-bar__status">
        <span class="pk-admin-save-bar__dot" aria-hidden="true"></span>{@status_text}
      </span>
      <.action
        anatomy="a1"
        role="principal"
        commit
        disabled={!@dirty}
        phx-click={@on_save}
        class="pk-admin-save-bar__action"
      >
        Guardar
      </.action>
    </div>
    """
  end

  @doc """
  Renders the in-page back control — one 44px row, D1/D2/D3's page-head
  rhythm (the same anatomy `page_bar/1`'s own back link uses, so the two
  are visually and structurally interchangeable, never two independently-
  declared "back" shapes). Pass `inert={true}` when `page_bar/1` alongside
  it is the currently-visible back control (D-19n — exactly one of the two
  is ever focusable at a time).
  """
  attr :to, :string, required: true
  attr :label, :string, default: "Volver"
  attr :id, :string, default: nil
  attr :inert, :boolean, default: false
  attr :class, :any, default: nil

  def back_row(assigns) do
    ~H"""
    <.link
      id={@id}
      navigate={@to}
      class={["pk-admin-back-row", @class]}
      data-pk-pressable="true"
      inert={@inert}
    >
      <CoreComponents.icon name="hero-chevron-left-mini" class="size-5" />
      <span>{@label}</span>
    </.link>
    """
  end

  # ============================================================
  # Plan 01.8.2-15, Task 2 — the Ordenar→Listo mode (062-B, R7 #4). The
  # SECOND consumer is plan 01.8.2-18's Administrar estantes — R7 #4's
  # whole point is that every ↑/↓-carrying admin screen moves to this one
  # shape together, so the mode's own markup lives here rather than being
  # forked into `section_live/index.ex`/`edit.ex`.
  # ============================================================

  @doc """
  Renders the Ordenar-mode header swap: the mode's own title (at
  `page_bar/1`'s 17/600 rank) plus a trailing `action/1` `anatomy="a2"`
  `role="terciaria"` **Listo**. The caller renders this INSTEAD of its
  normal heading while its own `reorder_mode` assign is true — never
  alongside it (two headers fighting for one slot is exactly what this
  atom exists to prevent).
  """
  attr :title, :string, default: "Ordenar"
  attr :on_done, JS, required: true
  attr :class, :any, default: nil

  def reorder_header(assigns) do
    ~H"""
    <div class={["pk-admin-reorder-header", @class]}>
      <span class="pk-admin-reorder-header__title">{@title}</span>
      <.action anatomy="a2" role="terciaria" phx-click={@on_done}>Listo</.action>
    </div>
    """
  end

  @doc """
  Renders one row of the Ordenar→Listo mode: a 44px drag-handle glyph
  that, on TAP, reveals ↑/↓ on this row only — the WCAG 2.5.7 non-drag
  fallback this whole mode is built around (T-01.8.2-68: there is no
  drag-and-drop precedent anywhere in this codebase, so the tap-reveal
  path is the one this plan wires and tests; native pointer-drag
  reordering is a later, additive enhancement over this same markup, not
  shipped here — the handle renders no `draggable` attribute, since a
  `draggable` element with no drop handler would be a dead affordance).

  `revealed` gates the ↑/↓ pair for THIS row alone — the caller is
  responsible for tracking which single row (if any) is revealed, so
  tapping one row's handle never reveals a second row's arrows.
  """
  attr :id, :string, required: true
  attr :revealed, :boolean, default: false
  attr :on_reveal, JS, required: true
  attr :on_up, JS, required: true
  attr :on_down, JS, required: true
  attr :up_label, :string, required: true
  attr :down_label, :string, required: true
  attr :class, :any, default: nil

  slot :inner_block, required: true

  def reorder_row(assigns) do
    ~H"""
    <div id={@id} class={["pk-admin-reorder-row", @class]} data-pk-reorder-row>
      <button
        type="button"
        class="pk-admin-reorder-row__handle"
        data-pk-pressable="true"
        aria-label="Reordenar"
        phx-click={@on_reveal}
      >
        <CoreComponents.icon name="hero-bars-3" class="size-5" />
      </button>
      <div class="pk-admin-reorder-row__content">{render_slot(@inner_block)}</div>
      <div :if={@revealed} class="pk-admin-reorder-row__arrows" role="group" aria-label="Orden">
        <button
          type="button"
          class="pk-admin-reorder-row__arrow"
          data-pk-pressable="true"
          aria-label={@up_label}
          phx-click={@on_up}
        >
          <CoreComponents.icon name="hero-arrow-up" class="size-4" />
        </button>
        <button
          type="button"
          class="pk-admin-reorder-row__arrow"
          data-pk-pressable="true"
          aria-label={@down_label}
          phx-click={@on_down}
        >
          <CoreComponents.icon name="hero-arrow-down" class="size-4" />
        </button>
      </div>
    </div>
    """
  end
end
