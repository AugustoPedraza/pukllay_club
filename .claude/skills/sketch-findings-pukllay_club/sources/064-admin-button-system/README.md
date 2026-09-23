---
sketch: 064
name: admin-button-system
question: "How should every action in the admin (059–063) look so the main step is easy to spot, and the same verb always looks the same?"
winner: "S3 (Contorno) — tuned for weight in round 2"
tags: [admin, buttons, cta, consistency, hierarchy, forms, phase-01.8.1, mobile-first]
---

# Sketch 064: Admin button system

## Design Question
Developer, on 063's Estado: "why there are Publicar as text and then there are disable text? I need all CTA and submit consistent. Review all the admin to be sure those are consistent and easily identifiable."

## Audit of 059–063 (before)
| Look | Used for |
|------|----------|
| Outlined `.obtn` | Agregar (061), Guardar cambios (062), Guardar (062 rename, 063 Estado, **disabled when clean**) |
| Text `.tbtn` | **Publicar**, Restaurar, Retirar (red), Reintentar, Mostrar más, Cancelar, Sí, agregar edición, Renombrar, Listo, Ver en la ludoteca / BGG, **Guardar** (062 rename in a sheet) |
| Soft full-width `.cta2` | Agregar a una fila (063) |
| Disclosure `.bgg-more` | Ver más (063) |
| Grey fill + border `.btn` | Enviarme el link (login) |
| Sheet rows `.dlink` | Sí, retirar / Guardar y salir / Descartar / Cancelar |

Problems found:
- **One verb, many looks:** "Guardar" appears 3 ways (outlined, text, sheet row), and "Agregar" 2 ways (outlined, soft).
- **Inverted hierarchy in Estado:** the draft's main next step (Publicar) is the weakest style, a text button, while a *disabled* outlined Guardar is the heaviest thing in the box. That's why it read as "text and then disabled text".
- **Disabled buttons** (Guardar in 062 and 063, Agregar in 061) show a dimmed box that explains nothing. The status line already says "Todo guardado".
- **Button sizes vary:** heights and type sizes differ (48px vs 44px, 13px vs 14px), and the login uses a fifth style.

## How to View
From the repo root: `python3 -m http.server 8765`, then open http://127.0.0.1:8765/.planning/sketches/064-admin-button-system/index.html

The top bar has **Sistema** (S1 / S2 / S3), **Vista** (Teléfono / Todas) and **Tema** (Claro / Oscuro). Every card is a real admin moment from 059–063.

## Shared by all systems (the part that fixes consistency)
- **One anatomy:** 44px tall, 8px radius, 14px/600 label, 16px icon, 8px between buttons. Text-style buttons use 12px side padding so their label lines up with content edges.
- **Four roles:**
  - **Principal:** at most one per block, the step the page is asking for: Publicar (draft), Guardar (with changes), Agregar, Guardar cambios, Enviarme el link.
  - **Secundaria:** a real action that isn't the main step: Guardar next to Publicar, Restaurar, Agregar a una fila, Sí, agregar edición.
  - **Terciaria:** dismiss, navigation, disclosure and links: Cancelar, Reintentar, Mostrar más, Borrar búsqueda, Ver más, Renombrar, Ordenar, Ver en BoardGameGeek ↗.
  - **Peligro:** red text, never Principal, always confirmed in a sheet: Retirar.
- **Order:** action rows are right-aligned with Principal last. Peligro goes to the far left when it shares a row with Principal. An inline form's button sits beside its field. The single-task login button is full width.
- **No disabled buttons:** Guardar only exists while there are changes. Submits validate on tap, e.g. empty Agregar → "Pegá un ID o link de BGG." + focus.
- **Estado layout:** the status and its line on top, the actions row below. The status never gets squeezed into a column beside two buttons.
  - Borrador: [Publicar]; with changes: [Guardar] [Publicar].
  - Publicado: [Retirar de la web]; with changes: Retirar … [Guardar].
  - Retirado: [Restaurar].
- **Sheets stay 059 rows** (Sí, retirar / Cancelar), not buttons.

## Variants (paint only)
- **S1: Relleno.** Material 3 filled / tonal / text. Principal = solid primary with white text; Secundaria = surface-2 tonal with primary text; Terciaria = primary text. daisyUI: `btn btn-primary` / `btn btn-soft btn-primary` / `btn btn-ghost`. **Overturns 061's "never filled" rule** (and 060's "no filled buttons"). It's the easiest to spot.
- **S2: Tonal.** Principal = a strong primary tint (a white-text tint in dark); Secundaria = primary-tinted outline; Terciaria = text. daisyUI: `btn btn-soft btn-primary` / `btn btn-outline btn-primary` / `btn btn-ghost`. No solid fill, but on the lavender boxes the tonal Principal sits close to the box color.
- **S3: Contorno (the 061 rule, tightened).** Principal = 1.5px primary outline with primary text; Secundaria = neutral outline; Terciaria = text. daisyUI: `btn btn-outline btn-primary` / `btn btn-outline` / `btn btn-ghost`. The closest to today; Principal and Secundaria differ only by border color and weight.

## Winner: S3 Contorno, weight-tuned (round 2, 2026-09-15)
Developer: "S3 looks better. Just be sure that has the correct weight so don't look unbalanced."

S1 and S2 and the Sistema switch are removed (commit `bf17cf7` is their record). What was unbalanced in S3, and the fix:
- **Stroke widths were mixed:** Principal had 1.5px (heavy and blurry at 1x density), Secundaria 1px. Now there's **one 1px stroke for every outline**: Principal, Secundaria and text fields.
- **Secundaria was too faint:** a surface-2 stroke at about 1.4:1 made "Sí, agregar edición" and "Guardar" read as white cards or inputs. Secundaria and fields now share one neutral token, `--stroke` (text mixed into bg: 58% light, 42% dark), at **≥ 3:1** (WCAG 1.4.11). Measured 3.7:1 light, 3.1:1 dark.
- **Text buttons competed with Principal:** they used the same primary color and weight. Terciaria now uses `--color-secondary` (dark: `--color-text-muted`), one step lighter but still ≥ 4.5:1.

The resulting ladder, measured:

| Role | Stroke | Label contrast | daisyUI |
|------|--------|----------------|---------|
| Principal | 1px primary, 12.2:1 (dark 10.5) | 14.2:1 | `btn btn-outline btn-primary` |
| Secundaria | 1px neutral `--stroke`, 3.7:1 (dark 3.1) | text color | `btn btn-outline` with a neutral border |
| Terciaria | none | ≤ 6.0:1 (secondary purple) | `btn btn-ghost` |
| Peligro | none | danger | `btn btn-ghost text-error` |

Verified in headless Chrome, 30 of 30 checks. New since round 1:
- One stroke width across Principal, Secundaria and fields.
- Secundaria and field strokes ≥ 3:1, and the same token.
- Principal stroke more than 1.5× stronger than Secundaria.
- Terciaria labels lighter than Principal labels.
- Only one system left.

## Applied to 059–063 (2026-09-15)
The identical "064: admin button system" CSS block is appended to every admin sketch, scoped with `#device`. Per-sketch changes are listed in each sketch's README:
- **Logins (059–062)** → a full-width Principal.
- **061/062:** add forms are never disabled; empty names/values error on submit; "Sí, agregar edición" → Secundaria.
- **062 only:** "Guardar cambios" only with changes; the rename sheet's Guardar → Principal; Invitar hidden (not disabled) when the staff is full.
- **063:** Estado role matrix with status on top; "Agregar a una fila" → Secundaria; "Ver más" → Terciaria.

**Cross-sketch audit:** `audit-admin.js` loads every admin sketch and walks 25 screens/states in light and dark.
- **Screens:** logins, Juegos + the edition prompt, Web, Estantes, Asignar, Niveles, Staff (+ an empty invite), the rename sheet, a dirty section editor, and 063 draft/published/retired, clean/dirty and BGG failed.
- **Every visible action button:**
  - 44px, 8px radius, 14px/600, not disabled;
  - outlined roles have a 1px stroke and text roles none;
  - the role actually renders its paint (Peligro red, Terciaria `--ter`), which catches specificity losses;
  - label ≥ 4.5:1;
  - outlined buttons stay inside their container's content edge;
  - at most one Principal per action row, and it's last.
- **Text fields:** 1px stroke ≥ 3:1. *(065 R4: the selector now includes `.sfield input` — the Juegos
  search field was outside this check, and had drifted to a filled pill with a transparent border.)*

Since the font-weight pass, the audit also checks type: real Inter 400/600 loads in every sketch, every visible element is 400 or 600, text is Inter or Bebas Neue only, and the active tab label outweighs the inactive ones. Result: 94 of 94. Run: `python3 -m http.server 8765 &` then `node .planning/sketches/064-admin-button-system/audit-admin.js`.

059–062 font weights are now normalized to the app's 400/600 too; see each sketch's README.

## What to Look For
- In Estado (borrador con cambios), can you tell in half a second which button publishes?
- Does Retirar feel far enough from Guardar (publicado con cambios)?
- Do the forms (Agregar, Renombrar, Guardar cambios, login) all read as the same kind of submit?
- Check dark mode, and the "Todas" view for the whole admin side by side.

## Verification
`verify.js` (round 1 version) ran 44 checks in headless Chrome for every system × light/dark:
- no overflow at 420px;
- every button is 44px / 8px radius / 14px 600;
- no disabled buttons;
- at most one Principal per block, and Peligro is never Principal;
- the four roles are painted four different ways;
- every label has ≥ 4.5:1 contrast against the color actually behind it.

It also checks:
- the Estado role matrix;
- Principal last in every action row;
- empty Agregar validates on tap and focuses the field, and typing clears the error;
- desktop has no overflow.

The first run showed 3 false contrast failures: `color-mix()` backgrounds come back as `color(srgb 0–1)` and were parsed as 0–255. The parser is fixed; real contrast passes.

## Round 10 — the other half of the system: which anatomy, in which context (from sketch 065, 2026-09-16)

Developer: *"Those too big and kill balance. and also, there are 'text actions' like 'Ver en la
ludoteca' and 'Quitar del estante'. We need a consistent way to represent actions everywhere with its
corresponding hierachy and correct balance to fix the currently broken rythm."*

This sketch wrote down the **paint** of a role — Principal / Secundaria / Terciaria / Peligro — and
said nothing about the **shape** a role takes in which place. So each place invented one. A census of
**every visible action control on 25 admin surfaces (113 of them, 25 context × role pairs)** found the
same role rendering two different ways in seven places, none of which any check could see, because
this file only ever looked at buttons and only ever at their right edge.

> **THE CONTEXT PICKS THE ANATOMY; THE ROLE PICKS THE PAINT.**

### Four anatomies, and no fifth

| | anatomy | measured | roles it carries |
|---|---|---|---|
| **A1** | outlined | 44px · 16px side padding · 1px stroke · 8px radius · 14px/600 · **inset 0 on both sides** (the stroke ends on the content edge) · **8px** between two of them | Principal, Secundaria |
| **A2** | text | 44px · 12px side padding · no stroke · 14px/600 · **pulled −12px** so the *label* lands on the content edge · **0** between two of them (round 6 #5: their own padding *is* the rhythm) · centred and unpulled in pagination only | Terciaria, Peligro |
| **A3** | icon | 44×44 borderless circle · 18px glyph · **pulled −12px** so the *glyph* lands on the content edge | Terciaria, Peligro |
| **A4** | sheet row | 48px · full-bleed · 16px/400 · 22px leading icon · commit first with `tick`, Cancelar last with `chevL` — **a sheet has no buttons at all** (065 R7b) | all four, by order + icon + tone |

Two things sit beside the four rather than inside them, and both are named so they cannot be mistaken
for drift: the **chip row** is the admin's "pick one of N" control (065 R7b), and the **back control**
is page chrome — a leading-glyph navigation control with its own 4/10px padding and −10px pull,
identical on every drill-down, which 065's `D1` has asserted since round 1.

### Context × role → anatomy

| context | Principal | Secundaria | Terciaria | Peligro |
|---|---|---|---|---|
| **page strip** `.pacts` | never | **never** | **A2** | never |
| **block head** `.lhead` | A1 (*Listo*) | A1 (*Ordenar*) | A2 | never |
| **block foot** `.gacts` | A1 (*Listo*) | A1 (*Agregar juegos*) | A2 | A3, far right |
| **save bar** `.eactions` | A1, last | A1 | A2 | A2, far left |
| **inline form** `.addrow` | A1, beside its field | — | — | — |
| **banner** `.banner-actions` | A1, last | A1 | A2 | A2 |
| **box foot** `.cta2-wrap`, `.bgg-more-wrap` | never | A1, full width | A2, full width | never |
| **row, its trail, its expansion** `.gtrail` · `.gxacts` · `.epanel` · `.ractions` | **never** | **never** | A2 / A3 | A2 / A3 |
| **pagination** `.more` | never | never | A2, centred — the one A2 that is not pulled | never |
| **sheet** `.dlinks` | A4, first, `tick` | A4 | A4 | A4 danger; Cancelar last |

### The rules, and what each one was for

1. **At most one outlined action per block** — widening this sketch's own "at most one Principal per
   block". A block may hold one Principal *and* one Secundaria (063's Estado matrix, `[Guardar]
   [Publicar]`, is exactly that); it may never hold two of one rank. Three equal Secundarias and no
   Principal is the shape of "too big and kill balance": the page shouts three times and asks nothing.
2. **A page-level action is never Principal and never outlined.** It sits under content it does not
   belong to, so it is A2.
3. **A row-level action is never outlined.**
4. **A block's mode control is outlined in both states** — Secundaria to enter, Principal to leave.
   This is round 7's `.lhead` decision (*"a mode toggle that changes what the whole list below it does
   is not a Terciaria text link"*), and it **still holds under a system**: `.gacts` now follows it too,
   and the two outlines left on the Estantes page are one per block, each inside the block it acts on.
5. **A destructive action is never Principal, is A2/A3/A4 only, and confirms in a sheet.**
6. **44px floor on everything tappable**, a row that opens a sheet included — measured on the **hit
   box**, not the drawn box.
7. **A1 never pulls; A2/A3 always pull −12px on the side that touches the block edge.** Round 7 wrote
   this for `.lhead` alone; every context is told now.

### What was actually wrong

1. **`.pacts` applied the borderless −12px pull to an outlined Secundaria**, so "Nuevo estante" hung
   its stroke **12px past the page's left content edge**. This audit measured only the right edge.
2. **The estante's options `.ibtn` sat at inset 0** while every row arrow above it sat at −12 — two
   identical 18px glyphs **12px out of line** down one column.
3. **"The space between two text actions" had four answers** — 4px, 8px, 8px, 0 — against round 6 #5's
   one rule, applied only where round 6 happened to look. This is the "broken rhythm".
4. **`.banner.err .banner-actions { margin: 0 }`** cancelled the strip's pull, so 063's lone
   "Reintentar" had its label 12px inside the banner's content edge while 061's "Cancelar", same class,
   sat on it. The container's pull is dropped and the pull is on the **button**, where an outlined last
   child then ends on the edge and a borderless one puts its label there.
5. **Two panels declared 40px for rows that open a sheet** — `.sgroup.apanel` ("Orden · A mano") and
   `.r6 .sbox.rows` ("Estante · Sin ubicar"): **6 tap targets under the floor**, unaudited because this
   file only measured buttons.
6. **`.ebar .obtn { margin-left: 4px }`** gave a save bar's outlined last action two left margins,
   depending on whether it was `.obtn` or `.b-pri`.
7. **The editor's back row held two anatomies for one context × role** — the back control beside a real
   Terciaria action. Fixed by naming the back control its own role rather than by changing either.

**And one non-finding, recorded because it nearly went in as real:** 061's filter chip is a 32px pill
whose `::after` bleeds its hit area to **44px**. Reading the drawn box reports a legal target as under
the floor — the same harness-trap shape as round 1's three false contrast failures. The floor check
measures the `::after` box.

### `audit-admin.js`: 106 → **154 of 154**

The 48 new checks are one per screen × theme, and they are **`A1`–`A9`** inside the page-side pass:

- **A2** an outlined action's stroke is inside its block's content edge on **both** sides;
- **A3** a borderless action at a block edge puts its *label or glyph* there (−12), never its box —
  skipped for a full-width bar, where the box *is* the strip;
- **A4** at most one Principal and one Secundaria outlined per block;
- **A5** no outlined action in `.pacts`, at row level, in pagination or in a sheet;
- **A6** 0px between two text actions, 8px between two outlined ones;
- **A7** a destructive action is never outlined;
- **A8** every tap target — buttons, icon buttons, `.cta2`, sheet rows, setting rows, chips and list
  rows — clears 44px, measured on the hit box;
- **A9** a sheet renders no buttons, and Cancelar is its last row.

The selector set grew too: `.cta2`, `.ibtn`, `.dlink`, `button.srow` / `label.srow` / `a.srow`, `.chip`
and `.grow` were all outside every previous check.

The cross-page half — *the same context × role must have the same anatomy on every page of one walk* —
is `M1`–`M6` in `065/verify.js`, because only a composition can see it. Both halves exist on purpose:
round 4 and round 9 each found a control nothing audited, and a rule that lives only in the composition
drifts the moment a sketch is edited on its own.
