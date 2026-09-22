# Admin Button / Action System

The one action system for every staff-side surface. Sketch 064 settled the **paint** of the four
roles (winner **S3 "Contorno"**, weight-tuned in round 2); sketch 065 round 10 settled the **shape** a
role takes in each place. Later sketches cite this as the canonical outline button — 080's fixed-foot
`Guardar` is specified verbatim as *"A1 de 064"*.

> **THE CONTEXT PICKS THE ANATOMY; THE ROLE PICKS THE PAINT.**

**Verification status:** 064's `audit-admin.js` walks 25 admin screens/states in light and dark at
**154/154**, and 065's cross-page census (`M1`–`M6`) covers 22 context×role pairs over 100 controls.
All headless Chrome at 420px and 1440px. **Nothing here is confirmed on a real device.**

## Design Decisions

**One anatomy for every action outside a sheet:** `min-height: 44px` · `border-radius: var(--radius-md)`
(8px) · `font-size: 14px; font-weight: 600` · 16px icon · 6px gap between icon and label · **8px between
two outlined buttons** · 16px side padding for outlined roles, **12px for text roles** (so their *label*,
not their box, lands on the content edge).

**Four roles. Only the paint changes.**

| role | class | stroke | label | daisyUI |
|---|---|---|---|---|
| **Principal** | `.obtn` / `.b-pri` | 1px `--color-primary`, **12.2:1** (dark 10.5) | primary, **14.2:1** | `btn btn-outline btn-primary` |
| **Secundaria** | `.b-sec` | 1px neutral `--stroke`, **3.7:1** light / **3.1:1** dark | `--color-text` | `btn btn-outline` with a neutral border |
| **Terciaria** | `.tbtn` | none | `--ter` (secondary purple), **≤ 6.0:1** | `btn btn-ghost` |
| **Peligro** | `.tbtn.danger` | none | `--color-danger` | `btn btn-ghost text-error` |

Round 2 fixed three things that made S3 look unbalanced, and each fix is load-bearing:
1. **One stroke width — 1px — for every outline**, Principal, Secundaria and text fields alike.
   Principal had been 1.5px, which reads heavy and blurry at 1× density. Emphasis comes from stroke
   *colour*, not weight.
2. **Secundaria was too faint at ~1.4:1** — "Guardar" and "Sí, agregar edición" read as white cards or
   inputs. Secundaria and text fields now share **one** neutral token `--stroke` at **≥ 3:1**
   (WCAG 1.4.11). Measured 3.7:1 light / 3.1:1 dark against the page; on a `--color-surface` tint
   3.72:1 / 3.14:1; 065 R7b re-measured it at 4.3:1 light / 3.49:1 dark against the page ground.
3. **Terciaria competed with Principal** — same colour, same weight. It now uses `--color-secondary`
   in light and `--color-text-muted` in dark, one step lighter but still ≥ 4.5:1.

The invariant the audit enforces: **the Principal stroke is more than 1.5× stronger than Secundaria's,
and Terciaria labels are lighter than Principal labels.**

**Resolved token values** (sketch theme = production `app.css`):

| token | light | dark |
|---|---|---|
| `--color-primary` | `#3C1269` | `#7B2DCE` |
| `--color-accent-text` | `#3C1269` | `#E3D9F9` |
| `--color-secondary` | `#7550AC` | `#553384` |
| `--color-text-muted` | `#675C7D` | `#B8A0E5` |
| `--color-danger` | `#B23A5C` | `#E06B90` |
| `--color-bg` / `--color-surface` | `#FFFFFF` / `#F1ECFD` | `#2E154E` / `#3C1269` |
| `--color-text` | `#231339` | `#F1ECFD` |
| `--stroke` (derived) | `color-mix(--color-text 58%, --color-bg)` | `color-mix(--color-text 42%, --color-bg)` |
| `--ter` (derived) | `var(--color-secondary)` | `var(--color-text-muted)` |

**Dark-mode substitutions are not optional.** In dark, Principal swaps `--color-primary` for
`--color-accent-text` (`#E3D9F9`) on both border and label and drops to a transparent background —
`#7B2DCE` on `#2E154E` measured **2.33:1**, under 1.4.11's 3:1 floor. Danger text in admin rows/buttons
lightens to **`#F2A3B8`** on the dark ground.

**Four anatomies, and no fifth (065 R10).**

| | anatomy | measured | roles it carries |
|---|---|---|---|
| **A1** | outlined | 44px · 16px side padding · 1px stroke · 8px radius · 14px/600 · **inset 0 on both sides** (the stroke ends on the content edge) · **8px** between two | Principal, Secundaria |
| **A2** | text | 44px · 12px side padding · no stroke · 14px/600 · **pulled −12px** so the *label* lands on the content edge · **0** between two (their own padding *is* the rhythm) · centred and unpulled in pagination only | Terciaria, Peligro |
| **A3** | icon | 44×44 borderless circle · 18px glyph · **pulled −12px** so the *glyph* lands on the content edge | Terciaria, Peligro |
| **A4** | sheet row | 48px · full-bleed · 16px/400 · 22px leading icon · commit first with `tick`, `Cancelar` last with `chevL` — **a sheet has no buttons at all** | all four, by order + icon + tone |

Two controls sit *beside* the four rather than inside them, named so they cannot be mistaken for drift:
the **chip row** is the admin's "pick one of N" control, and the **back control** is page chrome (its
own 4/10px padding and −10px pull, identical on every drill-down).

**Context × role → anatomy.**

| context | Principal | Secundaria | Terciaria | Peligro |
|---|---|---|---|---|
| **page strip** `.pacts` | never | **never** | **A2** | never |
| **block head** `.lhead` | A1 (*Listo*) | A1 (*Ordenar*) | A2 | never |
| **block foot** `.gacts` | A1 (*Listo*) | A1 (*Agregar juegos*) | A2 | A3, far right |
| **save bar** `.eactions` | A1, last | A1 | A2 | A2, far left |
| **inline form** `.addrow` | A1, beside its field | — | — | — |
| **banner** `.banner-actions` | A1, last | A1 | A2 | A2 |
| **box foot** `.cta2-wrap`, `.bgg-more-wrap` | never | A1, full width | A2, full width | never |
| **row / its trail / its expansion** `.gtrail`·`.gxacts`·`.epanel`·`.ractions` | **never** | **never** | A2 / A3 | A2 / A3 |
| **pagination** `.more` | never | never | A2, centred — the one A2 that is not pulled | never |
| **sheet** `.dlinks` | A4, first, `tick` | A4 | A4 | A4 danger; `Cancelar` last |

**The seven rules the audit enforces (A1–A9 in `audit-admin.js`).**
1. **At most one outlined action per block** — widening 064's own "at most one Principal per block". A
   block may hold one Principal *and* one Secundaria (063's Estado matrix `[Guardar] [Publicar]` is
   exactly that); it may never hold two of one rank. Three equal Secundarias and no Principal *is* the
   shape of "too big and kill balance": the page shouts three times and asks nothing.
2. **A page-level action is never Principal and never outlined** — it sits under content it does not
   belong to, so it is A2.
3. **A row-level action is never outlined.**
4. **A block's mode control is outlined in both states** — Secundaria to enter, Principal to leave. A
   mode toggle that changes what the whole list below it does is not a Terciaria text link.
5. **A destructive action is never Principal**, is A2/A3/A4 only, and confirms in a sheet.
6. **44px floor on everything tappable**, a row that opens a sheet included — measured on the **hit
   box**, not the drawn box.
7. **A1 never pulls; A2/A3 always pull −12px on the side that touches the block edge.**

**Order and placement.** Action rows are right-aligned with **Principal last** (nearest the right
thumb). **Peligro goes to the far left** when it shares a row with Principal. An inline form's button
sits beside its field. The single-task login button is a **full-width Principal**. `.gacts` (a block's
foot strip) is deliberately *left*-aligned — it sits on the list's own left text edge so it reads as
belonging to the list above it, with the block's options icon at the far right; that is a context
rule, not drift.

**Text fields share the Secundaria stroke.** Every text field is 44px / 8px radius / 1px `--stroke` /
page background — the same token as Secundaria, so a button and an input can never drift apart. 063's
in-place editors (title, description, numeric units) are the one documented exemption. The audit
selector is `.tin, .field input, .sfield input` — `.sfield input` was added after 065 R4 found the
Juegos search field had drifted to a filled pill entirely outside the check.

**Estado role matrix (063's lifecycle box).** The status line and its explanation sit **on top**, the
action row **below** — the status never gets squeezed into a column beside two buttons.

| state | actions |
|---|---|
| Borrador | `[Publicar]` · with changes: `[Guardar] [Publicar]` |
| Publicado | `[Retirar de la web]` · with changes: `Retirar …` `[Guardar]` |
| Retirado | `[Restaurar]` |

**"No disabled buttons" — the original rule.** `Guardar` only exists while there are changes; submits
validate on tap (empty `Agregar` → *"Pegá un ID o link de BGG."* + focus). A dimmed box explains
nothing, and the status line already says "Todo guardado". The rule also removed disabled ↑/↓ end
states from being the affordance of record, and made `Invitar` *hidden* (not disabled) when the staff
roster is full, with the help line explaining why.

### Open conflict: "no disabled buttons" is contradicted by later decisions, and is NOT resolved

This is live, not settled. Record it as such.

- **064 banned disabled controls outright** and `audit-admin.js` asserts `not disabled` on every
  visible action button across 25 screens.
- **078 counts the sixth disabled control against that ban** (076 round 3 was the fifth), and **079
  logs the eighth**, each shipped by an explicit decision rather than by oversight.
- **074 (admin header, decision 44)** overturns 064 **for the top app bar only** and upholds it
  everywhere else — the bar's primary is **W3 "Texto"** (a plain text action, no container, 0px² of
  paint when dead) rather than 064's A1 outline. 074's own Open section states the rule conflict
  plainly: *"`no disabled buttons` (064) is still contradicted by the 1/8 dead slot, whichever weight
  ships… The 1/8 case sits between two rules and is governed by neither — the sharpest thing still
  open on this bar."*
- **080 (DECIDIDO 2026-09-22) ships a disabled button on purpose.** Its fixed-foot `Guardar` is
  *"A1 de 064 — contorno, 44px, 16px de padding, radio 8, 14/600, a su ancho natural, a la derecha…
  **habilitado sólo si hay cambios**"*, and the README names it: *"Vuelve un botón deshabilitado — el
  conflicto con 064 que este linaje viene arrastrando, pero ahora por elección explícita y no por
  omisión."* The disabled state's paint had to be re-derived: on the tonal bar `.cta[disabled]` was
  also `--color-surface` and measured **1:1** — invisible but for its 1px ring — so the disabled
  button takes the **page background** instead, at **1.16:1**.

**How to treat it when writing code today:** default to 064 — prefer *not rendering* an action to
rendering it dead. Where a decision above explicitly ships a disabled control (the editor's fixed-foot
`Guardar`, the top app bar's 1/8 dead slot), ship it, and give the disabled state a ground that is not
the same token as the container behind it. Do **not** silently generalise either side; the rule
conflict has no owner yet.

**Second recorded departure, for the same reason:** 071–074 have drawn a **filled** primary
(`.btn { background: var(--color-primary) }`, copied forward verbatim since 072) for four sketches
with nothing recording the departure. 074 decision 44 legalises it only for the top app bar (and picks
text over filled there); **every other admin surface still owes 064's outline Principal**, and that
four-sketch drift in 071–073 is not corrected.

### What 065's census actually found (7 bugs, none visible to any existing check)

A census of **113 visible action controls over 25 surfaces (25 context×role pairs)** found the same
role rendering two ways in seven places:
1. `.pacts` applied the borderless −12px pull to an **outlined** Secundaria, so "Nuevo estante" hung
   its stroke **12px past the page's left content edge**. The audit measured only the right edge.
2. The estante's options `.ibtn` sat at inset 0 while every row arrow above it sat at −12 — two
   identical 18px glyphs **12px out of line** down one column.
3. **"The space between two text actions" had four answers** — 4px (`.gxacts`), 8px (`.eactions`,
   `.banner-actions`), 0 (a save bar with no outline) — against one rule. This is the "broken rhythm".
4. `.banner.err .banner-actions { margin: 0 }` cancelled the strip's pull, so one "Reintentar" sat
   12px inside the content edge while a same-class "Cancelar" sat on it. **The pull belongs on the
   button, not the container.**
5. Two panels declared **40px** for rows that open a sheet — 6 tap targets under the floor, unaudited
   because the check only ever looked at buttons.
6. `.ebar .obtn { margin-left: 4px }` gave a save bar's outlined last action two different left
   margins depending on whether it was `.obtn` or `.b-pri`.
7. The editor's back row held two anatomies for one context×role. Fixed by **naming the back control
   its own role**, not by changing either control.

**Two harness traps worth inheriting.** A 32px filter chip whose `::after` bleeds ±6px is a legal 44px
target — read the **hit box**, not the drawn box, or you will record a false floor violation. And
`color-mix()` backgrounds come back as `color(srgb 0–1)`; parsing them as 0–255 produced three false
contrast failures on the first run.

**Measured effect of landing the action system** (the rail held constant, R10 declarations injected
out and back in): bold share did **not** move at all — weight was never the problem. What moved is
**1px stroke ink**: Estantes shut `662 → 266px` (−60%), one estante open `1026 → 630px` (−39%), and
outlined actions on the first screen `2 → 1`. Pages that grew 6–8px are the ones where a 40px tappable
row became 44.

## CSS Patterns

The sketches ship this block byte-identical in 059–063, scoped with `#device` so it wins over each
sketch's older local rules. In the real app drop the `#device` prefix (or replace it with whatever
scopes the admin layout) and keep everything else.

```css
/* ============ 064: admin button system — S3 "Contorno", weight-tuned ============
   ONE anatomy: 44px · radius-md (8px) · 14px/600 · 16px icon · 6px gap · 8px between two outlines.
   The role only changes the PAINT:
     Principal  .obtn / .b-pri   1px primary stroke, primary label — one per block, LAST in its row
     Secundaria .b-sec           1px neutral --stroke (≥3:1, the SAME token as text fields)
     Terciaria  .tbtn            no stroke, --ter label (one step lighter than Principal)
     Peligro    .tbtn.danger     no stroke, danger label — never Principal, confirms in a sheet   */

:root { --stroke: color-mix(in srgb, var(--color-text) 58%, var(--color-bg)); --ter: var(--color-secondary); }
:root[data-theme="dark"] { --stroke: color-mix(in srgb, var(--color-text) 42%, var(--color-bg)); --ter: var(--color-text-muted); }
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) { --stroke: color-mix(in srgb, var(--color-text) 42%, var(--color-bg)); --ter: var(--color-text-muted); }
}

/* shared anatomy (`.snack .tbtn` is the one exemption — a snackbar action) */
:is(.obtn, .tbtn, .b-pri, .b-sec):not(.snack .tbtn) {
  min-height: 44px; border-radius: var(--radius-md); font-size: 14px; font-weight: 600; line-height: 1;
  display: inline-flex; align-items: center; justify-content: center; gap: 6px; cursor: pointer;
}
:is(.obtn, .tbtn, .b-pri, .b-sec) svg:not(.spin) { width: 16px; height: 16px; }

/* A1 — outlined (Principal + Secundaria): 16px side padding, 1px stroke, page-background fill */
:is(.obtn, .b-pri, .b-sec) { padding: 0 16px; border: 1px solid; background: var(--color-bg); opacity: 1; }
:is(.obtn, .b-pri)        { border-color: var(--color-primary); color: var(--color-primary); }
:is(.obtn, .b-pri):hover  { background: color-mix(in srgb, var(--color-primary) 7%, var(--color-bg)); }
/* dark: --color-primary #7B2DCE on #2E154E is 2.33:1 — under 1.4.11. Swap to the accent ink. */
:root[data-theme="dark"] :is(.obtn, .b-pri)       { border-color: var(--color-accent-text); color: var(--color-accent-text); background: transparent; }
:root[data-theme="dark"] :is(.obtn, .b-pri):hover { background: color-mix(in srgb, var(--color-accent-text) 10%, transparent); }
.b-sec        { border-color: var(--stroke); color: var(--color-text); }
.b-sec:hover  { background: var(--color-surface); }
:root[data-theme="dark"] .b-sec       { background: transparent; }
:root[data-theme="dark"] .b-sec:hover { background: color-mix(in srgb, var(--color-text) 8%, transparent); }

/* A2 — text (Terciaria + Peligro): 12px side padding so the LABEL reaches the content edge */
.tbtn:not(.b-pri):not(.b-sec):not(.snack .tbtn)       { padding: 0 12px; border: 0; background: none; color: var(--ter); }
.tbtn:not(.b-pri):not(.b-sec):not(.snack .tbtn):hover { background: color-mix(in srgb, var(--ter) 10%, transparent); }
/* Peligro repeats the Terciaria selector chain so it outranks it — plain .tbtn.danger loses */
.tbtn.danger:not(.b-pri):not(.b-sec):not(.snack .tbtn)       { color: var(--color-danger); }
.tbtn.danger:not(.b-pri):not(.b-sec):not(.snack .tbtn):hover { background: color-mix(in srgb, var(--color-danger) 9%, transparent); }
:root[data-theme="dark"] .tbtn.danger:not(.b-pri):not(.b-sec):not(.snack .tbtn) { color: #F2A3B8; }

/* focus + full width */
:is(.obtn, .tbtn, .b-pri, .b-sec):focus-visible { outline: 2px solid var(--color-primary); outline-offset: 2px; }
:root[data-theme="dark"] :is(.obtn, .tbtn, .b-pri, .b-sec):focus-visible { outline-color: var(--color-accent-text); }
.btn-block { width: 100%; }   /* the login submit, and nothing else */

/* text fields share the Secundaria stroke; 063's in-place editors keep their soft look */
:is(.tin, .field input, .sfield input):not(.desc-in):not(.num):not(.title-in) { border: 1px solid var(--stroke); }
:is(.tin, .field input, .sfield input):not(.desc-in):not(.num):not(.title-in):focus {
  border-color: var(--color-primary); box-shadow: 0 0 0 1px var(--color-primary); }
:root[data-theme="dark"] :is(.tin, .field input, .sfield input):not(.desc-in):not(.num):not(.title-in):focus {
  border-color: var(--color-accent-text); box-shadow: 0 0 0 1px var(--color-accent-text); }
:is(.tin, .field input, .sfield input).invalid { border-color: var(--color-danger); box-shadow: 0 0 0 1px var(--color-danger); }

/* A3 — icon action */
.ibtn { width: 44px; height: 44px; flex-shrink: 0; border: 0; background: none; border-radius: 50%;
  cursor: pointer; color: var(--color-text-muted); display: flex; align-items: center; justify-content: center; }
.ibtn svg { width: 18px; height: 18px; }
.ibtn:hover  { background: var(--color-surface); color: var(--color-text); }
.ibtn:active { background: var(--color-surface-2); }

/* ============ 065 R10: the context picks the anatomy ============ */
/* rule 7a — an OUTLINED action never pulls, in any context */
:is(.lhead, .pacts, .gacts, .eactions, .banner-actions, .cta2-wrap, .addrow) > :is(.obtn, .b-pri, .b-sec) {
  margin-left: 0; margin-right: 0; }
/* rule 7b — a BORDERLESS action at a block edge pulls −12px, and the pull lives on the BUTTON,
   never on the container (a container-level pull cannot tell an outline from a label) */
.pacts { display: flex; margin-top: 8px; }        /* 8px, not 20 — a text button hides 14px above its label */
.pacts .tbtn { margin-left: -12px; }
main .gacts > .ibtn:last-child { margin-right: -12px; }
.banner-actions { margin-right: 0; }
.banner-actions > .tbtn:not(.b-pri):not(.b-sec):last-child { margin-right: -12px; }
.eactions > .tbtn:first-child:not(.b-pri):not(.b-sec) { margin-left: -12px; }
.eactions > .tbtn:last-child:not(.b-pri):not(.b-sec)  { margin-right: -12px; }
/* action rows: 8px between two outlines, 0 between two text actions (their padding IS the rhythm) */
.eactions { display: flex; justify-content: flex-end; align-items: center; gap: 8px; }
.eactions .push { margin-right: auto; margin-left: -12px; }   /* Peligro, far left */
.gxacts, .epanel .gxacts { gap: 0; }
/* rule 6 — 44px floor on anything tappable, a row that opens a sheet included */
main :is(.sgroup, .sbox.rows) :is(button, label, a).srow { min-height: 44px; }
```

**daisyUI mapping** (the project ships Tailwind + daisyUI): Principal `btn btn-outline btn-primary` ·
Secundaria `btn btn-outline` with a neutral border · Terciaria `btn btn-ghost` · Peligro
`btn btn-ghost text-error`. Override daisyUI's default height/radius/weight to the 44px / 8px / 14-600
anatomy — the roles are outline-only, so `btn-primary`'s fill must never appear.

## HTML Structures

```html
<!-- Save bar / Estado: status on top, actions below. Principal LAST, Peligro far left. -->
<div class="ebar inline">
  <div class="bst">
    <span class="bl1"><span class="dot published"></span>Publicado</span>
    <span class="bl2 dirty">Cambios sin guardar</span>
  </div>
  <div class="eactions">
    <button class="tbtn danger push">Retirar de la web</button>   <!-- A2, far left -->
    <button class="b-pri">Guardar</button>                        <!-- A1, last -->
  </div>
</div>

<!-- Block head: a mode control is A1 in BOTH states -->
<div class="lhead">
  <p class="sec-label">Estantes del club</p>
  <button class="b-sec" aria-pressed="false">Ordenar</button>
</div>
<div class="lhead">
  <p class="sec-label">Estantes del club</p>
  <button class="b-pri" aria-pressed="true">Listo</button>
</div>

<!-- Inline add form: A1 Principal beside its field, never disabled -->
<form class="addrow">
  <div class="fieldwrap"><input class="tin" placeholder="ID o link de BGG"></div>
  <button class="b-pri" type="submit">Agregar</button>
</form>
<p class="ferr">Pegá un ID o link de BGG.</p>   <!-- appears on tap, clears on edit -->

<!-- Page-level action: NEVER outlined, never Principal -->
<div class="pacts"><button class="tbtn">Nuevo estante</button></div>

<!-- Row-level actions: A2 / A3 only, 0px between two text actions -->
<div class="gxacts">
  <button class="tbtn">Ver en la ludoteca</button>
  <button class="tbtn danger">Quitar del estante</button>
</div>

<!-- Login: the one full-width Principal -->
<button class="b-pri btn-block" type="submit">Enviarme el link</button>

<!-- A sheet has NO buttons: commit row first with tick, Cancelar last with chevL -->
<form class="dlinks">
  <button type="submit" class="dlink"><span class="slot">✓</span><span class="lbl">Guardar</span></button>
  <button type="button" class="dlink"><span class="slot">‹</span><span class="lbl">Cancelar</span></button>
</form>

<!-- Busy state: the spinner replaces the icon; never a disabled dim -->
<button class="b-pri" aria-busy="true"><span class="spin"></span>Agregando</button>
```

## What to Avoid

- **Don't use a filled Principal.** 064 won as *Contorno*; S1 (Material filled/tonal) and S2 (tonal)
  were removed with the developer in the room (*"S3 looks better"*), and redrawing them re-litigates a
  settled call. The filled `.btn { background: var(--color-primary) }` present in 071–073 is
  **unrecorded drift**, not a decision — 074 legalises a departure for the **top app bar only**.
- **Don't take Principal to full width.** 064's matrix: save bar → `A1, last`; box foot → Principal
  **never** (a full-width control there is Secundaria or Terciaria). 080 measured a copied full-width
  bar at **15.8%** label-to-box ratio against **61.7%** at natural width — a box sized for a
  23-character label wrapped around a 7-character one. The login submit is the single exception.
- **Don't mix stroke widths.** One 1px stroke for Principal, Secundaria and every text field. 1.5px
  reads heavy and blurry at 1×.
- **Don't let a neutral outline fall under 3:1.** A ~1.4:1 Secundaria reads as an input or a white
  card, and WCAG 1.4.11 sets the floor for a component's boundary. Use the shared `--stroke` token —
  never invent a second one.
- **Don't keep `--color-primary` for Principal in dark.** 2.33:1. Swap to `--color-accent-text`.
- **Don't pull an outlined button.** The −12px pull is for borderless controls only; applied to an
  outline it hangs the stroke 12px past the content edge — a real, measured bug.
- **Don't put the pull on the container.** It cannot distinguish an outlined last child from a
  borderless one; put it on the button.
- **Don't give two text actions a gap.** Their own 12px padding is the rhythm. Four different answers
  to that one rule *is* the "broken rhythm" complaint.
- **Don't stack outlined actions.** One outlined action per block (at most one Principal *and* one
  Secundaria). Three equal Secundarias and no Principal is the exact shape of "too big and kill
  balance".
- **Don't make a destructive action Principal**, and don't let it act without a sheet confirm (or a
  `Deshacer` snackbar where the change is genuinely reversible).
- **Don't put buttons in a bottom sheet.** Sheet actions are 48px full-bleed rows (A4).
- **Don't reach for a disabled button by default** — but don't pretend the ban is intact either. See
  the open-conflict section: 074's top app bar, 078, 079 and 080's fixed-foot `Guardar` all ship
  disabled controls by explicit decision, and the rule has no owner. If you must ship one, its
  disabled ground must differ from the container behind it (`.cta[disabled]` on a tonal bar measured
  **1:1**).
- **Don't audit the drawn box.** A 32px chip with a `::after` bleed is a legal 44px target; measure the
  hit box. And parse `color-mix()` output as `color(srgb 0–1)`, not 0–255, or contrast checks lie.
- **Don't add a control without adding it to the audit selector.** Both of this system's worst drifts
  (the Juegos search field, the segmented view switch) happened in places nothing measured.

## Origin
Synthesized from sketch 064 (admin-button-system) — winner **S3 "Contorno"**, weight-tuned in round 2,
applied across 059–063 and gated by `audit-admin.js` (154/154) — plus its **round 10**, which is
sketch 065's action-system census (113 controls / 25 surfaces) written back into 064's README because
it extends 064's own role matrix.

Open conflicts recorded from sketches **074** (admin-header, decisions 43–44 — 064 overturned for the
top app bar, upheld elsewhere), **078** (publish gate — the sixth disabled control), **079**
(lifecycle — the eighth) and **080** (admin-guardar-fijo, DECIDIDO 2026-09-22 — the fixed-foot
`Guardar` specified as "A1 de 064", disabled while clean).

Source files available in: `sources/064-admin-button-system/` (`index.html`, `verify.js`,
`audit-admin.js`), with the cross-page half of the audit in `sources/065-admin-composition/verify.js`.
