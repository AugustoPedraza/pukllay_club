---
name: ui-design-system
description: Design-system rules for PukllayClub's Phoenix/LiveView UI — daisyUI conventions, banned styling patterns, spacing/typography scale, and the component inventory. Load before writing or editing .heex templates, LiveViews, function components, or any styling/layout task.
---

## Core rule

daisyUI is the primary system. Prefer its semantic classes (`btn-primary`, `badge-secondary`,
`select`, `input`, `card`, `drawer`, `carousel`, `rounded-box`) over raw Tailwind utilities for
anything daisyUI already names. Raw Tailwind is for layout only (flex, grid, gap, spacing,
max-width) — never for color, radius, or component shape daisyUI already covers.

**Before writing custom markup, check `core_components.ex` and daisyUI's component list first.**
State explicitly which one you checked and why it doesn't fit before hand-rolling markup.

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

## Component inventory — use these before writing new markup

| Module | Function | Required attrs |
|---|---|---|
| `CoreComponents` | `flash/1` | `flash`, `kind` |
| `CoreComponents` | `button/1` | inner_block (rest: href/navigate/patch/...) |
| `CoreComponents` | `input/1` | `field` or `name`+`value`, `type` |
| `CoreComponents` | `table/1` | `id`, `rows`, `:col` slot |
| `CoreComponents` | `list/1` | `:item` slot (with `title`) |
| `CoreComponents` | `icon/1` | `name` (`hero-*`) |
| `Layouts` | `app/1` | `flash`, inner_block |
| `Layouts` | `brand_logo/1` | — |
| `GameCard` | `game_card/1` | `id`, `game` |
| `FilterDrawer` | `filter_drawer/1` | `id`, `facet_options` |
| `CarouselRow` | `carousel_row/1` | `id`, `title`, `games` |
| `CarouselRow` | `skeleton_card/1` | `id` |
| `GameChips` | `weight_band_badge/1` | `game` |
| `GameChips` | `chip_row/1` | `terms` |
| `GameChips` | `editorial_tags/1` | `tags` |

`CoreComponents.header/1` exists but is unused and off-convention (plain `text-lg`, not
`font-display`) — don't reach for it without fixing it to match the heading rule above.
