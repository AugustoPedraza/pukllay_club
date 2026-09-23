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

    assigns =
      assign(
        assigns,
        :variant_class,
        "pk-admin-action--#{assigns.anatomy} pk-admin-action--#{assigns.role}"
      )

    if assigns.rest[:href] || assigns.rest[:navigate] || assigns.rest[:patch] do
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
        type="button"
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

  Accepts `type`: `"text"`, `"number"`, `"select"`, `"textarea"`,
  `"checkbox"` — the same subset `admin_components_test.exs` exercises.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string, default: "text", values: ~w(text number select textarea checkbox)

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
end
