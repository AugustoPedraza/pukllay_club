---
name: ui-design-system
description: Design-system rules for PukllayClub's Phoenix/LiveView UI — daisyUI conventions, banned styling patterns, spacing/typography scale, and the component inventory. Load before writing or editing .heex templates, LiveViews, function components, or any styling/layout task.
---

## Scope switch — read this before any rule below

Two independent design systems live in this app (D-16, D-17). Work out which one governs the
file in front of you before applying anything else in this skill.

### Scope A — the admin system

Governs **every `/admin` screen** and **the shared chrome staff see everywhere, public pages
included**: the drawer, the bottom tab bar, every bottom sheet, the snackbar, and every dialog.
A signed-in staff member sees this chrome on public pages too (D-13a/D-13b) — the fact that the
surrounding page is public does not put its chrome in Scope B. This scope comes from sketches
059–080, validated against iOS HIG / Material 3 in `01.8.2-BENCHMARK.md`, and superseded the
admin system's own earlier drafts (061, 063, 065-R8/R9/R10, 066, 067, 068 are dead — see the
`sketch-findings-pukllay_club` metadata for exactly which sketch replaced which).

**Rules (see "Scope A — the admin system" below for the full contract):**
S3 Contorno — outline-only actions, no filled button, with one documented exception (the
editor's 56px top app bar); the four anatomies A1 outlined / A2 text / A3 icon / A4 sheet row;
22px/600 Inter titles with Bebas reserved only for the editor's game name (D-26); a status is a
dot + text, never a pill (D-19h); a chevron means "this row opens another page" and nothing else
(D-19i); a pencil marks an editable block (D-26); one feedback component, the bottom snackbar
(D-19b/D-19c); every sheet closes with a 44px ✕ (D-19e); every destructive action confirms in a
centred dialog, never a sheet (D-19f); a curated-list removal gets a Deshacer snackbar instead of
a confirmation (D-19k); the press state is one token (D-19o); the 44px floor is measured on the
hit box.

### Scope B — public catalog content

**Unchanged.** Everything below "Scope B — public catalog content" in this file — daisyUI
semantic classes, `font-display` headings, the `.pk-*` families — governs the public catalog
surface (the browse grid, game detail page, filters, carousels, the About page) exactly as it
did before this phase. D-16 explicitly leaves this scope alone: restyling public catalog content
to the admin system is **out of scope** for this phase, and nothing here should be read as
inviting it. If you are editing a `CatalogLive`/`GameCard`/public `Layouts` template, or anything
under `assets/css/app.css`'s `PK CATALOG SURFACES` block, you are in Scope B.

**One shared boundary, not a third scope:** `Layouts` (root/app shell) renders both — the shared
staff chrome (Scope A, per D-13a/D-13b) and the public page content it wraps (Scope B). Editing
`layouts.ex` means applying Scope A rules to the drawer/tab-bar/sheet markup and Scope B rules to
everything else the layout wraps.

---

## Universal rules (both scopes)

These apply regardless of which scope governs the rest of the file — they are project-wide
conventions the admin system also follows (see `01.8.2-TOKENS.md` — the admin's tokens resolve
through the same `app.css` theme variables, never a literal hex).

### Banned — never write these

- Arbitrary Tailwind values: `text-[10px]`, `w-[123px]`, `bg-[#fff]`, etc.
- Raw hex/rgb/hsl colors anywhere in markup or inline `style=`.
- Inline `style="..."` attributes.
- Any color class that isn't one of the theme tokens below (`text-red-500`, `bg-gray-100`, etc.
  are not valid — this app has two custom themes, not Tailwind's default palette).

### Theme tokens (light default, dark via `data-theme`)

Colors: `base-100/200/300` + `base-content`, `primary`/`-content`, `secondary`/`-content`,
`accent`/`-content`, `neutral`/`-content`, `info`/`success`/`warning`/`error` (+ `-content`).
Scope B consumes these through daisyUI's semantic modifier classes (`badge-accent`, not
`bg-accent text-accent-content`). Scope A consumes the same underlying CSS variables through its
own admin-scoped aliases (`--color-surface`, `--color-surface-2`, `--val`, `--stroke`) — see
`01.8.2-TOKENS.md` for the full reconciliation table; do not invent a second name for a value
that table already resolves.

Radius: `rounded-box` for Scope B cards/images/drawers/panels. Scope A's own radius token is
`var(--radius-md)` (8px), used by every admin action per the button-system reference below —
these are two different radius tokens for two different scopes, not a contradiction.

Fonts: `font-display` (Bebas Neue) for Scope B headings/titles/section labels. `font-sans`
(Inter, the default) for everything else, in both scopes — Scope A's admin titles are 22px/600
Inter, with Bebas reserved only for the editor's game name (D-26).

**Single source of truth:** `assets/css/app.css` is the only file allowed to declare a
`daisyui-theme` block (a stray second file was found and removed 2026-08-21 — don't recreate one).
Theme names are locked to `light`/`dark` — renaming breaks four hardcoded copies
(`assets/js/theme.js`, `layouts.ex`'s `data-theme` variants + `data-phx-theme` attrs, `app.css`'s
`@custom-variant dark`, `layouts_test.exs`) and strands any visitor with a saved `phx:theme` in
localStorage. Sketch themes under `.planning/sketches/themes/` mirror `app.css` via the mapping
table in `default.css`, checked by `check-theme-drift.sh`.

### Hit-target minimum

`min-h-11` (44px) is the floor in both scopes. Scope A measures it on the **hit box**, not the
drawn box (a 32px chip with a bleeding `::after` is a legal 44px target; a two-line sheet row
must actually be 44px tall). Tappable PILLS in Scope B are the documented exception (quick
260913-1s5) — `.pk-pill-interactive`'s own `::after` hit layer supplies the 44px target, so a
pill must never also carry `min-h-11`.

---

## Scope A — the admin system

**Design source of truth:** `.claude/skills/sketch-findings-pukllay_club/references/admin-*.md`
— read the per-screen file for the surface you're editing before writing admin markup. This
skill routes to that authority; it does not restate it:

- `references/admin-shell-navigation.md` — drawer, tab bar, header states, logout
- `references/admin-button-system.md` — the full S3 Contorno role/anatomy contract (A1–A4)
- `references/admin-juegos.md` — the Juegos list, search, create-by-BGG flow
- `references/admin-game-editor.md` — the editor chrome, save-bar write model, status franja
- `references/admin-estantes.md` — Estantes/Pendientes/Administrar estantes
- `references/admin-web-destacados.md` — the Web/destacados admin page

**Token authority:** `.planning/phases/01.8.2-admin-ui-ux-redesign/01.8.2-TOKENS.md` — the
reconciled table every admin colour reference resolves against. Reference the tokens it lands
(`--color-surface`, `--color-surface-2`, `--val`, `--stroke`) directly; do not re-derive a value
that table already fates.

**Do not touch `sketch-findings-pukllay_club`.** It already packages the 052–080 admin decisions
(verified current as of this plan) — a "refresh" of that skill is not this plan's job and would
rewrite an already-current file.

### The action system — S3 Contorno, outline-only

Every admin action is outlined or text/icon-only — **no filled button** in the admin, full stop,
with exactly one documented exception: the editor's 56px top app bar, where D-27 overturns 064's
"no disabled buttons / S3 Contorno" rule **for that bar only** (its one control, the ⋮, is judged
on painted area, not the outline anatomy). Every other admin surface — dashboard, Juegos, Estantes,
Pendientes, Administrar estantes, Staff, Web/secciones, Niveles, every sheet and dialog — stays
outline-only. See `references/admin-button-system.md` for the full role table (Principal /
Secundaria / Terciaria / Peligro) and the resolved light/dark hex.

**Four anatomies, no fifth:**

- **A1 — outlined**: 44px, 16px side padding, 1px stroke, 8px radius, 14px/600. Carries Principal
  and Secundaria.
- **A2 — text**: 44px, 12px side padding, no stroke, pulled −12px so the label lands on the
  content edge. Carries Terciaria and Peligro.
- **A3 — icon**: 44×44 borderless circle, 18px glyph, pulled −12px. Carries Terciaria and Peligro.
- **A4 — sheet row**: 48px full-bleed row, commit first, no Cancelar row (the sheet closes with
  its header ✕ instead — D-19e). A sheet has no buttons at all.

### Titles and the second system glyph

Admin page titles are **22px/600 Inter** — not `font-display`. The one exception is the game
editor's `<h1>`, which borrows the public ficha's **Bebas 30/36** with no label (D-26, overriding
the rank ladder for that page only). Every other admin page keeps the 22px/600 Inter title.

A **pencil** (14px) marks an editable block in the editor body — this is a second, deliberate
system glyph alongside the chevron (D-26), not drift. It appears only where a `--val`-tinted row
alone can't carry the "you can change this" signal (the cover, the description).

### Status, chevron, and the pencil — three glyphs, three jobs

- **A status is a dot + text, never a pill** (D-19h): `● Publicado`, `● Borrador`, `● Retirado`,
  `● Sin lugar`, `● Afuera`. Every status indicator in the admin. Tag and filter chips are not
  statuses and are unaffected.
- **A chevron means "this row opens another page"** and nothing else (D-19i). A row that acts in
  place — shows an answer, opens a sheet — has no chevron.
- **A pencil marks an editable block** (D-26) — the editor's second system glyph, distinct from
  both of the above.

### Feedback — one component

The top toast is deleted. Every admin message uses **the bottom snackbar** (D-19b/D-19c): 10s
with an action (Deshacer / Reintentar), closing early on ✕ or replacement; 4s without an action.

### Sheets and destructive confirmation

Every admin bottom sheet closes with a **44px ✕ at the right of its header** — tap outside, drag
down, and Esc also close it. **No Cancelar row** inside the sheet (D-19e); a commit row, if any,
stays first.

Every destructive action confirms in a **centred 312px dialog**, never in a sheet (D-19f): 16px
radius, an 18/600 question naming the thing, one 14px muted consequence line, two right-aligned
text actions (Cancelar focused by default, the verb in Peligro red). Scrim tap and Esc cancel.

**A curated-list removal is not destructive** (D-19k): it happens at once with a Deshacer
snackbar, no dialog, no Peligro red. D-19f's dialog is reserved for actions that lose state staff
would have to rebuild (Quitar del estante, Eliminar estante, Quitar del staff, Retirar a game).

### Press state — one token

Every pressable admin surface gets a press state, and it is **one token**: suppress the platform
tap highlight at `:root` (`-webkit-tap-highlight-color: transparent`, inherits) and paint
`:active` with `var(--color-surface-2)` (D-19o). The rule is "a `:hover` implies an `:active`" —
touch has no hover, so a hover-only admin control is invisible to press on the primary platform.
`:active` on a mouse press is the only way to verify this; CDP touch emulation does not set it.

---

## Scope B — public catalog content

Everything from here down is unchanged from before this phase and governs public catalog
content only (the browse grid, game detail page, filters, carousels, About page). D-16 leaves
this scope alone.

### Core rule

daisyUI is the primary system for Scope B. Prefer its semantic classes (`btn-primary`,
`badge-secondary`, `select`, `input`, `card`, `drawer`, `rounded-box`) over raw Tailwind utilities
for anything daisyUI already names. Raw Tailwind is for layout only (flex, grid, gap, spacing,
max-width) — never for color, radius, or component shape daisyUI already covers.

**Before writing custom markup, check `core_components.ex` and daisyUI's component list first.**
State explicitly which one you checked and why it doesn't fit before hand-rolling markup.

**Exception: the catalogue's horizontally-scrolling rails (`CarouselRow.carousel_row/1`) do not
use daisyUI's `carousel` component.** That component hides its scrollbar with no replacement
scroll cue, which is precisely why the rail read as an unresponsive grid before 01-11. The rail
is hand-rolled (`.pk-rail`/`.pk-rail-wrap`) instead — see the catalogue surface layer below. This
is the one deliberate exception to "prefer daisyUI"; it is not a precedent for hand-rolling other
daisyUI-covered components.

### Spacing/typography scale (observed, not invented)

- Card body padding: `p-4`.
- Grid: `grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4` — keep skeleton and real grid
  identical so loading state doesn't reflow.
- Section rhythm: `space-y-6` between major page sections, `space-y-3` within one section,
  `space-y-2` inside a card body.
- Chip/pill rows: `gap-1`; icon+text pairs: `gap-2`; grids/carousels: `gap-4`.
- Muted/secondary text: `text-neutral text-sm` — this app's convention. Not
  `text-base-content/70`, which survives only in unmaintained boilerplate; don't propagate it.
- Touch targets: add `min-h-11` to any tappable button/control under 44px (see "Hit-target
  minimum" above for the shared floor and the pill exception).
- Page container: one `mx-auto max-w-{size} px-4 py-6 sm:px-6 lg:px-8` per page. Page width is
  each LiveView's own responsibility. `Layouts.app`'s inner wrapper deliberately declares no
  `max-w-*` so the page's own container is the one that wins — never add a width cap back to the
  layout. Never nest two `max-w-*` containers: the narrower one silently wins regardless of
  nesting order.
  Caution: `Layouts.app`'s `<main>` still owns `px-4 py-20 sm:px-6 lg:px-8`, and
  `CatalogLive.Show` relies on it (it declares no padding of its own) — stripping `<main>`'s
  padding is a separate, breaking change, not a cleanup.
  **Deliberate exception: `CatalogLive.Index` (01-11/01-12, corrected 2026-08-24).** The catalogue
  page runs `fullbleed`/`sticky` on `Layouts.app` and has no single page-container div — every one
  of its sections (toolbar, main grid, load-more, and every carousel row header and rail wrap) is
  individually wrapped in the same shared **shell column**: `mx-auto w-full max-w-7xl pk-gutter`,
  the identical recipe the header inner and footer row use. `fullbleed` on this page means "the
  layout adds no padding of its own" — not "content reaches the viewport edge." Each carousel
  rail's horizontal scroll and edge-fade are scoped to that shell column, not to the viewport: the
  fade sits at the column's edges, and the poster cards, row titles and prev/next controls all
  share one x-position with the header wordmark and footer brand lockup. Don't "fix" the shell
  column back into a single page-container div — the page's sections are individually wrapped by
  design — and don't copy the full-bleed treatment onto a page that has no edge-to-edge content.
  Before 2026-08-24 this paragraph described the shelves as intentionally reaching the viewport
  edge; that was a bug, not a design decision — see the sketch 011 content-width-alignment finding
  in `sketch-findings-pukllay_club/references/layout-navigation.md`, which had already validated
  the shell-column cap for shelves and was simply never ported into production.

### Type hierarchy

- Type scale: `font-display` for headings (h1/h2/h3, section labels), `font-sans` for body,
  `text-sm` for muted/secondary — see Theme tokens above. Cap a single Scope B screen at 3
  distinct size/weight levels (heading, body, muted); reach for a 4th only with a specific reason.
  (Scope A caps admin screens differently — see the admin references above; do not import this
  cap into `/admin` work.)
- Weight and color, not a new size, are the emphasis lever — reserve a size bump for a genuinely
  larger content unit, since a large enough size gap still outranks weight alone.
- Put the most important content top-left; users scan, they don't read top-to-bottom by default.
- An over-wide `CoreComponents.table/1` column wraps and truncates — it is never dropped.
- Numeric table columns right-align with consistent precision; identifier-like digit strings
  (IDs, phone numbers) stay left-aligned as text, not treated as numeric data.

**Catalogue screen measured inventory (2026-09-02, quick task 260902-fdm):** re-measured live
computed `font-family`/`font-size`/`font-weight` triples on `CatalogLive.Index` at 390px/768px via
headless Chrome + CDP, same methodology as the 2026-09-01 measurement below (filtered to elements
with a real layout box, excluding descendants of a currently-closed `.pk-drawer`/`.pk-sheet`).
**4** distinct combos at ≤480px (down from 6 — sketch 044 winner H hides the footer's entire
lockup, links, and copyright at this breakpoint, retiring both the footer-scoped Bebas Neue/20px
row and the footer's own contribution to the Inter/12px/400 and Inter/14px/400 rows), **5** at
≥481px (byte-identical to 2026-09-01 — confirms this footer reduction is mobile-only):

| Combo | Tier | Source |
|---|---|---|
| Bebas Neue / 24px / 400 | heading | `font-display text-2xl` — header wordmark (every width), plus the footer wordmark at ≥481px only; every carousel row title, main-grid heading, empty-state heading (one shared Tailwind utility pair, not independently-declared). **Retired at ≤480px:** the footer-scoped Bebas Neue/20px/400 SIZE exception 260901-ty6 introduced no longer has a source — the footer lockup does not render at all below 480px (sketch 044) |
| Inter / 14px / 600 (≥481px) → 12px / 600 (≤480px) | body, semibold emphasis | `.pk-nav-links a`, `.pk-card-caption h3`, `.pk-chip`, `.pk-see-all` (retired, quick 260913-0h6 — the affordance moved into `.pk-row-cue`), `.pk-row-cue` — one tier, one deliberate narrow-viewport density step, unaffected by this footer change |
| Inter / 14px / 400 | body | `text-neutral text-sm` regular copy (e.g. the main-grid result-count line). The footer links' former 14px landing here (260901-ty6) is gone at ≤480px — `.pk-footer-links a` does not render below 480px anymore (sketch 044) |
| Inter / 12px / 400 | muted | brand tagline (`text-xs text-neutral`). At ≤480px only the header's instance renders — the footer's own tagline is hidden with the rest of its lockup (sketch 044) |
| Inter / 16px / 400 (≥481px only) | body | `.pk-footer-links a` (FAQ/Contacto/Juntadas) — inherited, not independently declared, unchanged at ≥481px |

Maps cleanly onto heading/body/muted with weight (600 vs 400) as the body tier's sanctioned
emphasis lever. The heading tier is back to a single SIZE at every width — 260901-ty6's ≤480px
footer-scoped exception to "demotion is by colour, not size" (app.css D-B comment) is withdrawn as
of sketch 044, since the footer lockup it applied to no longer renders at that breakpoint at all.
Re-measure before adding a new type combo to this screen; this table is what makes the cap
enforceable rather than re-litigable.

### Affordance

- Disabled vs hidden: disable a control only for a temporary mode active on the same screen;
  hide a control that's permanently inapplicable. Prefer leaving it enabled and validating after
  the attempt over disabling it beforehand. (Scope A's disabled-control rule is stricter and
  different — see the admin button-system reference: disabled means "nothing to write," never a
  generic "temporarily inapplicable.")
- Icon-only buttons are fine for fewer than 3 inline row actions; at 3 or more switch to a
  labelled menu. `CoreComponents.icon/1` (`hero-*` names) and `button/1` are the components to
  use for either case.
- Hit-target minimum is `min-h-11` (see Spacing/typography scale above) — don't introduce a
  second number here.
- Hover is never the sole affordance for a control; touch devices have no hover state, so
  anything revealed on hover needs a persistent fallback. (Scope A states the same rule as
  "a `:hover` implies an `:active`" — see D-19o above.)
- Action labels use a precise verb (e.g. `Eliminar`, not a generic `Aceptar`) so the
  consequence — navigate, dismiss, or mutate — is predictable before the click.

### Catalogue surface layer (`pk-*`, phase 01, plans 01-10/01-11/01-12)

The catalogue browse page (sketches 001/002, variant D) needed CSS daisyUI/Tailwind utilities
don't reach — full-bleed edge-fade shelves, a shared preview surface cloned into two different
places, a sticky nav tinting on scroll. That CSS lives in **one delimited block** in
`assets/css/app.css`, between the `PK CATALOG SURFACES START` and `PK CATALOG SURFACES END`
comment markers. **This is the only sanctioned custom-CSS layer in Scope B** — new custom CSS
that daisyUI/Tailwind utilities genuinely can't express belongs inside this block, extending the
existing groups below, not scattered into a new `<style>` block or a second delimited region.
(Scope A's admin CSS lives under `assets/css/admin/` per `01.8.2-TOKENS.md` — a separate layer,
not an extension of this one.)

Rules that apply to everything in the block:

- Every class resolves colour through the daisyUI theme CSS variables (`--color-base-100`,
  `--color-primary`, etc.) and radius through `--radius-box`/`--radius-field` — never a literal
  hex/rgb color — so both the light and dark theme render every surface correctly.
- **A field that must look identical on two different surfaces is declared in exactly one CSS
  class, shared verbatim by both** — never two independently-declared rules for the same visual
  property, even if the values start out matching. This is the single most load-bearing rule in
  this layer: every surface-drift bug found during sketching (title font-size, description
  line-clamp, poster aspect-ratio, the sheet's double-padding bug found live during 01-11) came
  from violating it. See `GamePreview`'s moduledoc for the concrete example.
- **`--pk-gutter` is the single horizontal-alignment token, consumed by exactly one rule
  (`.pk-gutter`).** No other selector in the block may set a horizontal padding on an aligned
  surface (the header, a row header, a rail wrap, a capped page section). This is what makes the
  nav and the row content below it provably share an edge instead of drifting to two
  independently-chosen spacing values.
- The narrow-viewport (`max-width: 480px`) density and navigation-switch values are declared in
  **one** `@media` block, positioned **last** in the file — after every base rule it overrides.
  A same-specificity override placed earlier in the file loses to a later plain rule regardless
  of the media query matching; this bit twice during 01-12 (the nav-links/chip-nav display swap
  silently lost to the base rule until the whole block was moved to the end). Don't split this
  block or move it earlier — add to it in place.

Class inventory by group:

| Group | Classes |
|---|---|
| Page and shelf layout | `--pk-gutter`, `.pk-gutter`, `.pk-page`, `.pk-shelf`, `.pk-row-link`, `.pk-row-cue` (+`.pk-row-cue-icon`) |
| Rail and edge-fade | `.pk-rail-wrap` (+`::before`/`::after`), `.pk-rail` (+`::-webkit-scrollbar`), `.pk-poster-card` (+`.is-hero`) |
| Card (resting state) | `.pk-card`, `.pk-card-poster`, `.pk-card-caption` |
| Preview surfaces (hover portal + mobile sheet) | `.pk-facts-row`, `.pk-fact`, `.pk-difficulty`, `.pk-difficulty-dot` (+`.is-filled`), `.pk-preview-poster`, `.pk-preview-body`, `.pk-preview-title`, `.pk-preview-text`, `.pk-preview-cta`, `.pk-portal` (+`.is-visible`), `.pk-sheet-backdrop` (+`.is-visible`), `.pk-sheet` (+`.is-open`), `.pk-sheet-body`, `.pk-sheet-handle`, `.pk-sheet-close`, `body.pk-sheet-open` |
| Nav and chips | `.pk-header`, `.pk-header-sticky`, `.pk-nav` (+`.is-scrolled`), `.pk-nav-links`, `.pk-nav-search`, `.pk-chip-nav` (+`::-webkit-scrollbar`), `.pk-chip` (+`.is-active`), `.pk-chip-spacer` |

### Component inventory — use these before writing new markup (Scope B)

| Module | Function | Required attrs |
|---|---|---|
| `CoreComponents` | `flash/1` | `flash`, `kind` |
| `CoreComponents` | `button/1` | inner_block (rest: href/navigate/patch/...). **Scope-qualified** (D-17): in Scope B, `variant`: unset (soft `btn-primary btn-soft`, default), `"primary"` (filled `btn-primary` — the page's one action), `"secondary"` (`btn-outline btn-primary` — repeated/secondary actions, e.g. a per-card CTA; the tier `GamePreview`'s Ver detalles hand-rolls the equivalent of). In Scope A, there is no filled `variant="primary"` — an admin action is always one of the outlined/text/icon anatomies in `references/admin-button-system.md`, and `variant="primary"` there means A1 outlined, never `btn-primary`'s fill. |
| `CoreComponents` | `input/1` | `field` or `name`+`value`, `type` |
| `CoreComponents` | `table/1` | `id`, `rows`, `:col` slot |
| `CoreComponents` | `list/1` | `:item` slot (with `title`) |
| `CoreComponents` | `icon/1` | `name` (`hero-*`) |
| `Layouts` | `app/1` | `flash`, inner_block. Optional: `fullbleed` (bool, default `false`), `sticky` (bool, default `false`), `:nav_links`/`:nav_search`/`:subnav` slots |
| `Layouts` | `brand_logo/1` | —. Optional: `tagline` (string, default `"JUEGOS DE MESA MODERNOS"`) — the footer is the one call site that overrides it. `mark` (bool, default `true`) — when `false`, omits the isologo `<img>` pair entirely and demotes the wordmark to the muted colour tier via `pk-brand-quiet`; the footer is the one call site that passes `false` (D-A/D-B, 260823-snj) so the mark belongs to the header alone. Renders a theme-aware isologo pair toggled by the `dark:` variant, gated at compile time on both `priv/static/images/isologo-light.png` and `isologo-dark.png` existing (falls back to wordmark-only if either is missing) |
| `GameCard` | `game_card/1` | `id`, `game` |
| `FilterModal` | `filter_modal/1` | `id`, `facet_options`. Optional: `mechanics`/`themes`/`weight_bands`/`tags` (lists, default `[]`), `players`/`max_playtime` (integers, default `nil`), `open` (bool, default `false`), `q` (string, default `""`), `total` (integer, default `0`), `filters_active` (bool, default `false`) |
| `CarouselRow` | `carousel_row/1` | `id`, `title`, `games`. Optional: `variant` (`:standard`/`:hero`), `subtitle`, `badge`, `href` (quick 260913-0h6 — renders the header as a `.pk-row-link` with a "Ver todos" cue landing on the shelf's filtered grid; `CatalogLive.Index` passes it for the 7 filter-expressible shelves, `nil` for `recientemente_anadidos` and `CatalogLive.Show`'s `similares`) |
| `CarouselRow` | `skeleton_card/1` | `id` |
| `GamePreview` | `preview_body/1` | `game` — the shared body cloned by both the portal and the sheet |
| `GamePreview` | `preview_template/1` | `game` — wraps `preview_body/1` in an inert `<template>` |
| `GamePreview` | `preview_host/1` | — renders the portal + sheet once, outside every rail |
| `GamePreview` | `facts_row/1` | `game` — players/tiempo/dificultad pills |
| `GamePreview` | `difficulty_indicator/1` | `level` (1..3) |
| `GameChips` | `weight_band_badge/1` | `game` |
| `GameChips` | `chip_row/1` | `terms` |
| `GameChips` | `editorial_tags/1` | `tags` |

`CoreComponents.header/1` exists but is unused and off-convention (plain `text-lg`, not
`font-display`) — don't reach for it without fixing it to match the heading rule above. (This is
a Scope B component; Scope A's own header/back-row conventions live in
`references/admin-shell-navigation.md`.)
