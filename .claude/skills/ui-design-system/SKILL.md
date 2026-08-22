---
name: ui-design-system
description: Design-system rules for PukllayClub's Phoenix/LiveView UI — daisyUI conventions, banned styling patterns, spacing/typography scale, and the component inventory. Load before writing or editing .heex templates, LiveViews, function components, or any styling/layout task.
---

## Core rule

daisyUI is the primary system. Prefer its semantic classes (`btn-primary`, `badge-secondary`,
`select`, `input`, `card`, `drawer`, `rounded-box`) over raw Tailwind utilities for anything
daisyUI already names. Raw Tailwind is for layout only (flex, grid, gap, spacing, max-width) —
never for color, radius, or component shape daisyUI already covers.

**Before writing custom markup, check `core_components.ex` and daisyUI's component list first.**
State explicitly which one you checked and why it doesn't fit before hand-rolling markup.

**Exception: the catalogue's horizontally-scrolling rails (`CarouselRow.carousel_row/1`) do not
use daisyUI's `carousel` component.** That component hides its scrollbar with no replacement
scroll cue, which is precisely why the rail read as an unresponsive grid before 01-11. The rail
is hand-rolled (`.pk-rail`/`.pk-rail-wrap`) instead — see the catalogue surface layer below. This
is the one deliberate exception to "prefer daisyUI"; it is not a precedent for hand-rolling other
daisyUI-covered components.

## Banned — never write these

- Arbitrary Tailwind values: `text-[10px]`, `w-[123px]`, `bg-[#fff]`, etc.
- Raw hex/rgb/hsl colors anywhere in markup or inline `style=`.
- Inline `style="..."` attributes.
- Any color class that isn't one of the theme tokens below (`text-red-500`, `bg-gray-100`, etc.
  are not valid — this app has two custom themes, not Tailwind's default palette).

## Theme tokens (light default, dark via `data-theme`)

Colors: `base-100/200/300` + `base-content`, `primary`/`-content`, `secondary`/`-content`,
`accent`/`-content`, `neutral`/`-content`, `info`/`success`/`warning`/`error` (+ `-content`).
Use the semantic daisyUI modifier form (`badge-accent`, not `bg-accent text-accent-content`) —
match `game_chips.ex`'s pattern, don't invent a new raw-color combination.

Radius: `rounded-box` for all cards/images/drawers/panels — the only radius token used in the
app; never `rounded-lg`/`rounded-xl`.

Fonts: `font-display` (Bebas Neue) for all headings/titles/section labels — h1/h2/h3,
empty-state titles, brand wordmark. `font-sans` (Inter, the default) for everything else. Do
not leave a heading on the plain sans default.

**Single source of truth:** `assets/css/app.css` is the only file allowed to declare a
`daisyui-theme` block (a stray second file was found and removed 2026-08-21 — don't recreate one).
Theme names are locked to `light`/`dark` — renaming breaks four hardcoded copies
(`assets/js/theme.js`, `layouts.ex`'s `data-theme` variants + `data-phx-theme` attrs, `app.css`'s
`@custom-variant dark`, `layouts_test.exs`) and strands any visitor with a saved `phx:theme` in
localStorage. Sketch themes under `.planning/sketches/themes/` mirror `app.css` via the mapping
table in `default.css`, checked by `check-theme-drift.sh`.

## Spacing/typography scale (observed, not invented)

- Card body padding: `p-4`.
- Grid: `grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4` — keep skeleton and real grid
  identical so loading state doesn't reflow.
- Section rhythm: `space-y-6` between major page sections, `space-y-3` within one section,
  `space-y-2` inside a card body.
- Chip/pill rows: `gap-1`; icon+text pairs: `gap-2`; grids/carousels: `gap-4`.
- Muted/secondary text: `text-neutral text-sm` — this app's convention. Not
  `text-base-content/70`, which survives only in unmaintained boilerplate; don't propagate it.
- Touch targets: add `min-h-11` to any tappable pill/button under 44px (see
  `filter_drawer.ex`'s `facet_pill`).
- Page container: one `mx-auto max-w-{size} px-4 py-6 sm:px-6 lg:px-8` per page. Page width is
  each LiveView's own responsibility. `Layouts.app`'s inner wrapper deliberately declares no
  `max-w-*` so the page's own container is the one that wins — never add a width cap back to the
  layout. Never nest two `max-w-*` containers: the narrower one silently wins regardless of
  nesting order.
  Caution: `Layouts.app`'s `<main>` still owns `px-4 py-20 sm:px-6 lg:px-8`, and
  `CatalogLive.Show` relies on it (it declares no padding of its own) — stripping `<main>`'s
  padding is a separate, breaking change, not a cleanup.
  **Deliberate exception: `CatalogLive.Index` (01-11/01-12).** The catalogue page runs
  `fullbleed`/`sticky` on `Layouts.app` and its own carousel shelves reach the viewport edge with
  no page-container padding at all — that full-bleed reach is the entire point of the Netflix-
  style edge-fade shelf pattern. Its capped inner sections (toolbar, main grid, load-more) each
  still get `mx-auto w-full max-w-7xl pk-gutter`, individually wrapped. This is the one page in
  the app that intentionally has no single page-container div; don't "fix" it to match the rule
  above, and don't copy the full-bleed pattern onto a page that has no edge-to-edge content.

## Type hierarchy

- Type scale: `font-display` for headings (h1/h2/h3, section labels), `font-sans` for body,
  `text-sm` for muted/secondary — see Theme tokens above. Cap a single screen at 3 distinct
  size/weight levels (heading, body, muted); reach for a 4th only with a specific reason.
- Weight and color, not a new size, are the emphasis lever — reserve a size bump for a genuinely
  larger content unit, since a large enough size gap still outranks weight alone.
- Put the most important content top-left; users scan, they don't read top-to-bottom by default.
- An over-wide `CoreComponents.table/1` column wraps and truncates — it is never dropped.
- Numeric table columns right-align with consistent precision; identifier-like digit strings
  (IDs, phone numbers) stay left-aligned as text, not treated as numeric data.

**Catalogue screen measured inventory (2026-08-21, quick task 260821-dah):** re-measured live
computed `font-family`/`font-size`/`font-weight` triples on `CatalogLive.Index` at
375px/768px/1440px via headless Chrome + CDP, filtered to elements with a real layout box
(`display !== 'none'`, `visibility !== 'hidden'`) — identical **5** distinct combos at every
breakpoint (only which elements land in which bucket shifts, not the combo count):

| Combo | Tier | Source |
|---|---|---|
| Bebas Neue / 24px / 400 | heading | `font-display text-2xl` — brand wordmark, every carousel row title, main-grid heading, empty-state heading (one shared Tailwind utility pair, not independently-declared) |
| Inter / 14px / 600 (≥481px) → 12px / 600 (≤480px) | body, semibold emphasis | `.pk-nav-links a`, `.pk-card-caption h3`, `.pk-chip`, `.pk-see-all` — one tier, one deliberate narrow-viewport density step (the single last-positioned `@media` block above), not two drifting rules |
| Inter / 14px / 400 | body | `text-neutral text-sm` regular copy (e.g. the main-grid result-count line) |
| Inter / 12px / 400 | muted | brand tagline (`text-xs text-neutral`, fixed 2026-08-21) |
| — accepted exception — | — | native `<select>`/`<option>` render at 14px/400 via the browser/daisyUI default, coinciding with the body tier by chance — not overridden, per "prefer daisyUI" |

Maps cleanly onto heading/body/muted with weight (600 vs 400) as the body tier's sanctioned
emphasis lever, not a 4th size level — **already at the 3-tier cap**, no CSS changed for this
measurement. Re-measure before adding a new type combo to this screen; this table is what makes
the cap enforceable rather than re-litigable.

## Affordance

- Disabled vs hidden: disable a control only for a temporary mode active on the same screen;
  hide a control that's permanently inapplicable. Prefer leaving it enabled and validating after
  the attempt over disabling it beforehand.
- Icon-only buttons are fine for fewer than 3 inline row actions; at 3 or more switch to a
  labelled menu. `CoreComponents.icon/1` (`hero-*` names) and `button/1` are the components to
  use for either case.
- Hit-target minimum is `min-h-11` (see Spacing/typography scale above) — don't introduce a
  second number here.
- Hover is never the sole affordance for a control; touch devices have no hover state, so
  anything revealed on hover needs a persistent fallback.
- Action labels use a precise verb (e.g. `Eliminar`, not a generic `Aceptar`) so the
  consequence — navigate, dismiss, or mutate — is predictable before the click.

## Catalogue surface layer (`pk-*`, phase 01, plans 01-10/01-11/01-12)

The catalogue browse page (sketches 001/002, variant D) needed CSS daisyUI/Tailwind utilities
don't reach — full-bleed edge-fade shelves, a shared preview surface cloned into two different
places, a sticky nav tinting on scroll. That CSS lives in **one delimited block** in
`assets/css/app.css`, between the `PK CATALOG SURFACES START` and `PK CATALOG SURFACES END`
comment markers. **This is the only sanctioned custom-CSS layer in the app** — new custom CSS
that daisyUI/Tailwind utilities genuinely can't express belongs inside this block, extending the
existing groups below, not scattered into a new `<style>` block or a second delimited region.

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
| Page and shelf layout | `--pk-gutter`, `.pk-gutter`, `.pk-page`, `.pk-shelf` |
| Rail and edge-fade | `.pk-rail-wrap` (+`::before`/`::after`), `.pk-rail` (+`::-webkit-scrollbar`), `.pk-poster-card` (+`.is-hero`), `.pk-see-all` |
| Card (resting state) | `.pk-card`, `.pk-card-poster`, `.pk-card-caption` |
| Preview surfaces (hover portal + mobile sheet) | `.pk-facts-row`, `.pk-fact`, `.pk-difficulty`, `.pk-difficulty-dot` (+`.is-filled`), `.pk-preview-poster`, `.pk-preview-body`, `.pk-preview-title`, `.pk-preview-text`, `.pk-preview-cta`, `.pk-portal` (+`.is-visible`), `.pk-sheet-backdrop` (+`.is-visible`), `.pk-sheet` (+`.is-open`), `.pk-sheet-body`, `.pk-sheet-handle`, `.pk-sheet-close`, `body.pk-sheet-open` |
| Nav and chips | `.pk-header`, `.pk-header-sticky`, `.pk-nav` (+`.is-scrolled`), `.pk-nav-links`, `.pk-nav-search`, `.pk-chip-nav` (+`::-webkit-scrollbar`), `.pk-chip` (+`.is-active`), `.pk-chip-spacer` |

## Component inventory — use these before writing new markup

| Module | Function | Required attrs |
|---|---|---|
| `CoreComponents` | `flash/1` | `flash`, `kind` |
| `CoreComponents` | `button/1` | inner_block (rest: href/navigate/patch/...). `variant`: unset (soft `btn-primary btn-soft`, default), `"primary"` (filled `btn-primary` — the page's one action), `"secondary"` (`btn-outline btn-primary` — repeated/secondary actions, e.g. a per-card CTA; the tier `GamePreview`'s Ver detalles hand-rolls the equivalent of) |
| `CoreComponents` | `input/1` | `field` or `name`+`value`, `type` |
| `CoreComponents` | `table/1` | `id`, `rows`, `:col` slot |
| `CoreComponents` | `list/1` | `:item` slot (with `title`) |
| `CoreComponents` | `icon/1` | `name` (`hero-*`) |
| `Layouts` | `app/1` | `flash`, inner_block. Optional: `fullbleed` (bool, default `false`), `sticky` (bool, default `false`), `:nav_links`/`:nav_search`/`:subnav` slots |
| `Layouts` | `brand_logo/1` | —. Optional: `tagline` (string, default `"JUEGOS DE MESA MODERNOS"`) — the footer is the one call site that overrides it. Renders a theme-aware isologo pair toggled by the `dark:` variant, gated at compile time on both `priv/static/images/isologo-light.png` and `isologo-dark.png` existing (falls back to wordmark-only if either is missing) |
| `GameCard` | `game_card/1` | `id`, `game` |
| `FilterDrawer` | `filter_drawer/1` | `id`, `facet_options` |
| `CarouselRow` | `carousel_row/1` | `id`, `title`, `games`. Optional: `variant` (`:standard`/`:hero`), `subtitle`, `see_all_row` |
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
`font-display`) — don't reach for it without fixing it to match the heading rule above.
