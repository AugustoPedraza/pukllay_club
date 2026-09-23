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
end
