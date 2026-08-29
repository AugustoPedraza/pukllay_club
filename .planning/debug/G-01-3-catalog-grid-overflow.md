---
status: diagnosed
trigger: "G-01-3: Catalog grid renders ~20 columns of game cards side by side on the main page, forcing horizontal scrolling, instead of a responsive column count per viewport width."
created: 2026-08-18T00:00:00.000Z
updated: 2026-08-18T00:00:00.000Z
---

## Current Focus

hypothesis: CONFIRMED — the user-reported "~20 columns forcing horizontal scroll" is not a defect in the responsive `#games` grid (index.ex:314); it is the by-design horizontal-scrolling `CarouselRow` component (one of 8 D-09 rows rendered above the grid on the same page), each capped at exactly `@carousel_limit = 20` games (catalog.ex:21), using daisyUI's `.carousel` (`display:inline-flex; overflow-x:scroll; scrollbar-width:none`) + `.carousel-item` (`flex:none`) — i.e. an intentional non-wrapping horizontal rail, not the grid.
test: n/a — diagnosis complete, goal is find_root_cause_only
expecting: n/a
next_action: none — return ROOT CAUSE FOUND to caller

## Symptoms

expected: The catalog grid on the main page (/) renders a responsive number of columns per viewport width, with no horizontal scrolling.
actual: User reported roughly 20 columns of game cards rendering side by side on the main page, forcing horizontal scrolling. Expected the responsive grid (grid-cols-2 sm:grid-cols-3 lg:grid-cols-4, per lib/pukllay_club_web/live/catalog_live/index.ex:314) to constrain column count per viewport — actual behavior suggests the grid/flex layout isn't wrapping or constraining item width correctly.
errors: None reported
reproduction: Test 2 in .planning/phases/01-catalog-v1/01-UAT.md — load the main catalog page (/) and observe the grid layout
started: Discovered during UAT (Phase 01-catalog-v1)

## Eliminated

- hypothesis: "The `#games` responsive grid's Tailwind utility classes (`grid`, `grid-cols-2`, `sm:grid-cols-3`, `lg:grid-cols-4`) are missing/purged from the compiled CSS, or overridden by a competing rule (inline style, flex ancestor, missing width constraint, `grid-auto-flow: column`)."
  evidence: "Read priv/static/assets/css/app.css directly. `.grid { display: grid; }` (line 1728-1730), `.grid-cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }` (line 1892-1893, unconditional base rule), `.sm\\:grid-cols-3 { @media (min-width: 640px) { grid-template-columns: repeat(3, minmax(0, 1fr)); } }` (line 2453-2455), `.lg\\:grid-cols-4 { @media (min-width: 1024px) { grid-template-columns: repeat(4, minmax(0, 1fr)); } }` (line 2478-2480). Source order correctly escalates base < sm: < lg: so at wide viewports the later (lg:) rule wins per normal cascade, matching intended responsive behavior. Grepped for any competing `#games`, `display: flex` on `.grid`, or a second `.grid` definition in the compiled CSS and in assets/vendor/*.js (topbar.js, heroicons.js) — none found. No `@source` scoping issue in assets/css/app.css (`@source \"../../lib/pukllay_club_web\"` covers index.ex, and G-01-2's prior investigation independently confirmed `sm:grid-cols-3` — one of the exact same-file classes — present in this same compiled CSS)."
  timestamp: 2026-08-18T00:00:00.000Z

- hypothesis: "GameCard.game_card/1's root element carries a hardcoded/fixed width or a competing display mode when rendered inside the grid (vs. the carousel), causing grid tracks to be sized by content instead of the viewport."
  evidence: "Read lib/pukllay_club_web/components/game_card.ex. The `:class` attr defaults to `nil` and index.ex:318 (`<GameCard.game_card :for={{id, game} <- @streams.games} id={id} game={game} />`) never passes a class override — so inside the grid the card gets only `class=\"card bg-base-200 shadow-sm\"` (daisyUI `.card`, `display:flex; flex-direction:column` — a normal grid-item block, no forced width). The fixed-width classes (`w-40 shrink-0 sm:w-48`) are only ever passed by CarouselRow (carousel_row.ex:26), which is a distinct, intentional context per game_card.ex's own moduledoc (\"Accepts an optional :class so a caller ... can control the card's width/shrink behavior without this component needing to know which context it's in\")."
  timestamp: 2026-08-18T00:00:00.000Z

## Evidence

- timestamp: 2026-08-18T00:00:00.000Z
  checked: "lib/pukllay_club_web/live/catalog_live/index.ex full file, focused on render/1 (lines 222-327)"
  found: "The `#games` grid (line 309-319, `id=\"games\" phx-update=\"stream\"`) is rendered unconditionally whenever `not @loading` (i.e. always, once connected) alongside the 8 `CarouselRow.carousel_row` sections (line 270-284), which are only hidden when a filter is active (`:if={not filters_active?(assigns)}`). So on the default, unfiltered landing page, BOTH the 8 horizontally-scrolling carousel rows AND the responsive `#games` grid are visible on the same page, stacked vertically. The class list on line 312-316 correctly renders `grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4` (plus a falsy-filtered `hidden` only when `@total == 0`) via Phoenix's builtin class-list truthy-filtering — standard, correct usage."
  implication: "A user loading `/` sees the carousel rows first (above the grid), which is the more likely thing being described as 'the grid' if they didn't distinguish the two sections."

- timestamp: 2026-08-18T00:00:00.000Z
  checked: "lib/pukllay_club_web/components/carousel_row.ex full file"
  found: "`carousel_row/1` renders each row as `<div class=\"carousel carousel-center gap-4 rounded-box\">` containing one `<div class=\"carousel-item\">` per game, each wrapping a `GameCard.game_card` with `class=\"w-40 shrink-0 sm:w-48\"`. This is daisyUI's carousel component — a horizontally-scrolling rail by design, not a wrapping grid."
  implication: "This component's entire purpose is to render N cards side-by-side with horizontal scroll — exactly the visual symptom reported."

- timestamp: 2026-08-18T00:00:00.000Z
  checked: "lib/pukllay_club/catalog.ex list_carousel_rows/0 and @carousel_limit (lines 21, 138-183)"
  found: "`@carousel_limit 20` (line 21) caps every one of the 8 D-09 carousel rows (`tags_query/1`, `weight_band_query/1`, `recent_query/0` all apply `limit: ^@carousel_limit`) at exactly 20 games each."
  implication: "The user's 'roughly 20 columns... side by side' is a near-exact numeric match to `@carousel_limit = 20` — not to `@page_size = 24` (the grid's page size). This is strong, specific, falsifiable evidence pointing at a fully-populated carousel row, not the grid."

- timestamp: 2026-08-18T00:00:00.000Z
  checked: "priv/static/assets/css/app.css daisyUI `.carousel` / `.carousel-item` compiled rules (lines 1484-1491, 1651-1659)"
  found: "`.carousel { display: inline-flex; overflow-x: scroll; scroll-snap-type: x mandatory; scrollbar-width: none; ... }` and `.carousel-item { display: flex; flex: none; scroll-snap-align: start; }`. `inline-flex` defaults to `flex-wrap: nowrap`, and `flex: none` prevents items from shrinking to fit — so all N items in a row are forced onto one non-wrapping horizontal line, scrollable via `overflow-x: scroll`. `scrollbar-width: none` additionally hides the native scrollbar, removing the usual visual cue that the row is a scrollable carousel rather than a broken/overflowing layout."
  implication: "Mechanism confirmed: this is the exact, intentional CSS behavior of a daisyUI carousel, and the hidden scrollbar plausibly explains why a user would mistake this by-design horizontal rail for a broken/unresponsive grid — there's no visible affordance signaling 'this scrolls, swipe it'."

## Resolution

root_cause: "Not a defect in the `#games` responsive grid at lib/pukllay_club_web/live/catalog_live/index.ex:314 — its Tailwind classes (`grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4`) are correctly compiled, unconflicted, and correctly escalate by breakpoint (verified directly in priv/static/assets/css/app.css). The reported '~20 columns side by side, forcing horizontal scrolling' is the by-design behavior of the `CarouselRow` component (lib/pukllay_club_web/components/carousel_row.ex) — one of the 8 D-09 carousel rows rendered above the grid on the same unfiltered landing page — using daisyUI's `.carousel` (inline-flex, overflow-x:scroll, no wrap) + `.carousel-item` (flex:none), each row capped at exactly `@carousel_limit = 20` games (lib/pukllay_club/catalog.ex:21), matching the user's 'roughly 20' observation precisely. Contributing factor: `.carousel`'s `scrollbar-width: none` hides the native scrollbar, removing the visual cue that the row is meant to scroll, which plausibly caused the user to misattribute this intentional horizontal-scroll carousel to 'the grid not being responsive'."
fix: ""
verification: ""
files_changed: []
