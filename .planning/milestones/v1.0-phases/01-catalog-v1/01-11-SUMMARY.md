---
phase: 01-catalog-v1
plan: 11
subsystem: ui
tags: [phoenix-liveview, css, catalog, sketch-001, full-bleed]

requires:
  - phase: 01-catalog-v1
    provides: GamePreview, minimal GameCard (data-game-card, pk-card-poster/pk-card-caption), pk-* CSS layer

provides:
  - --pk-gutter design token consumed by exactly one CSS rule (.pk-gutter)
  - Full-bleed edge-fade shelf layer (.pk-shelf/.pk-rail-wrap/.pk-rail/.pk-poster-card)
  - Layouts.app fullbleed opt-in
  - Ver todo tile wired to real filter state (see-all event)
  - Narrow-viewport (max-width 480px) density set + touch-scroll hardening
affects: [01-12]

actuals:
  tokens: 46000
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Single design token (--pk-gutter) consumed by exactly one CSS rule (.pk-gutter) as the structural fix for nav/row misalignment drift"
    - "Narrow-viewport density values (gutter, gap, card width, fade width) all flip together in one @media block to prevent the specificity-trap bug found during sketching"

key-files:
  modified:
    - assets/css/app.css
    - lib/pukllay_club_web/components/layouts.ex
    - lib/pukllay_club_web/components/carousel_row.ex
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - test/pukllay_club_web/components/layouts_test.exs
    - test/pukllay_club_web/live/catalog_live_test.exs

key-decisions:
  - "Fixed a pre-existing 01-10 bug found via real-device testing during this plan's tracer checkpoint: .pk-sheet-body had its own 24px padding stacked on top of the cloned .pk-preview-body's own 24px padding, so the mobile sheet's text content was inset 48px total while the poster figure was only inset 24px (content narrower than image). Removed the sheet-body padding so it matches the portal's zero-padding contract."
  - "The recency shelf's Ver todo tile sorts by :year_desc (game publication year, the closest existing grid sort) rather than by club acquisition order (inserted_at, what the shelf itself is actually ordered by) — adding an acquisition-recency sort mode to the main grid's sort dropdown is out of this plan's scope. Documented as a known limitation rather than silently diverging from the shelf's real semantics."
  - "Page shell restructured to pk-page with each capped section (toolbar, error alert, heading, empty state, grid, load-more) individually wrapped in mx-auto w-full max-w-7xl pk-gutter, and #carousel-rows left as a direct unwrapped child so shelves reach the viewport edge."

patterns-established:
  - "--pk-gutter and its narrow-viewport override are the only place any pk-* surface may declare horizontal padding — enforced by a single-declaration acceptance gate, carried forward into 01-12's nav work"

requirements-completed: []

coverage:
  - id: D1
    description: "Full-bleed edge-fade shelves with the row heading and rail sharing one gutter declaration"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#a shelf's row-header and rail-wrap both carry the shared gutter class"
        status: pass
    human_judgment: true
    rationale: "Visible gradient-fade rendering and edge alignment were verified live in a real browser (screenshot + scroll + computed-style checks), which the LiveView test suite cannot assert directly"
  - id: D2
    description: "Ver todo tile applies each shelf's own selection to the main grid with pagination reset"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#clicking the tile on the tag-backed shelf renders only the tagged game and hides the shelves"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#an unrecognised row value leaves the result set unchanged rather than raising"
        status: pass
    human_judgment: false
  - id: D3
    description: "Narrow-viewport density: ~3.5 cards visible with the fade narrower than the peek, all values flipping together from one media block"
    verification:
      - kind: other
        ref: "manual browser check at 335px viewport: --pk-gutter=0.875rem, hero card=118px, standard card=96px, fade=16px, rail gap=10px"
        status: pass
    human_judgment: true
    rationale: "Real-device swipe/back-gesture behavior (the plan's own <human-check>) was not exercised — this session's browser-automation tooling has no touch/swipe gesture emulation. overscroll-behavior-x and touch-action were confirmed present via computed styles, but the actual swipe-to-back-gesture and vertical-scroll-through-a-card behaviors need a real phone check before shipping."

duration: 65min
completed: 2026-08-19
status: complete
---

# Phase 1 Plan 11: Shelf-structure layout — full-bleed edge-fade shelves Summary

**Full-bleed Netflix-style carousel shelves with always-visible gradient edge-fades, a single `--pk-gutter` token aligning the header to every row, a "Ver todo" tile wired to real filter state, and narrow-viewport density tuned to peek the next card.**

## Performance

- **Duration:** 65 min
- **Started:** 2026-08-19T19:15:00Z
- **Completed:** 2026-08-19T20:20:00Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- `--pk-gutter` token consumed by exactly one CSS rule; header, row headers, rail wraps and capped page sections all provably share one edge — verified live (edge-fade visible after scrolling a rail)
- `.pk-shelf`/`.pk-rail-wrap` (48px edge-fade)/`.pk-rail`/`.pk-poster-card` replace daisyUI's `.carousel`, which hid the scrollbar with no cue
- `Layouts.app` gains a `fullbleed` opt-in (default `false`, byte-identical header/main classes when unset — `CatalogLive.Show` untouched, confirmed by test)
- Trailing dashed "Ver todo {categoría}" tile per shelf, wired to a real `see-all` LiveView event that reproduces each shelf's own query and resets pagination like every other filter — verified live (click narrows the grid, hides shelves, shows "112 juegos encontrados")
- One `@media (max-width: 480px)` block flips gutter/gap/card-width/fade-width/shelf-margin/caption-size together; `.pk-rail` gets `overscroll-behavior-x: contain` + `touch-action: manipulation` — verified live via computed styles at a 335px viewport
- **Mid-plan fix (found by the user via real-device testing during the Task 1 tracer checkpoint):** the mobile sheet from 01-10 had a double-padding bug (`.pk-sheet-body`'s own 24px stacked on `.pk-preview-body`'s 24px), making the text content column read narrower than the poster image above it. Fixed by removing `.pk-sheet-body`'s padding so it matches the portal's zero-padding contract.

## Task Commits

Each task was committed atomically:

1. **Task 1: One full-bleed edge-fade shelf, aligned to the header gutter** - `2265d13` (feat)
2. **fix: mid-plan real-device bug fix (01-10 sheet double-padding)** - `89167d6` (fix)
3. **Task 2: Trailing "Ver todo" tile wired to real filter state** - `31b63a0` (feat)
4. **Task 3: Narrow-viewport rail density and touch-scroll hardening** - `a9155f3` (feat)

## Files Created/Modified
- `assets/css/app.css` - `--pk-gutter`, `.pk-gutter`, `.pk-shelf`, `.pk-rail-wrap`/`::before`/`::after`, `.pk-rail`, `.pk-poster-card`(`.is-hero`), `.pk-see-all`, the 480px density block, and the `.pk-sheet-body` fix
- `lib/pukllay_club_web/components/layouts.ex` - `fullbleed` attr on `app/1`
- `lib/pukllay_club_web/components/carousel_row.ex` - rewritten off daisyUI `.carousel` onto the pk-rail layer; `see_all_row` attr and tile
- `lib/pukllay_club_web/live/catalog_live/index.ex` - `pk-page` shell restructure, `handle_event("see-all", ...)`, `see_all_selection/1`
- `test/pukllay_club_web/components/layouts_test.exs` - 2 new tests for `fullbleed` on/off
- `test/pukllay_club_web/live/catalog_live_test.exs` - 8 new tests (gutter sharing, pk-page shell, 4 see-all tests, heading regression, pk-shelf regression)

## Decisions Made
- Fixed the 01-10 mobile-sheet double-padding bug in place (see above) rather than deferring — it directly blocked confident verification of this plan's own gutter-alignment work and was reported by the user mid-session.
- The recency shelf's Ver todo tile uses `:year_desc` (publication year) rather than a true acquisition-recency sort — documented as a known limitation; adding a new sort mode to the grid's dropdown was judged out of scope for this plan.
- Each capped page section gets its own `mx-auto w-full max-w-7xl pk-gutter` wrapper div rather than one shared wrapper, keeping the original section boundaries and `:if` conditionals intact.

## Deviations from Plan

**1. [Rule 1 - Bug] Fixed 01-10's mobile-sheet double-padding**
- **Found during:** Task 1 tracer checkpoint, reported by the user after real-device testing
- **Issue:** `.pk-sheet-body { padding: 24px }` stacked on top of the cloned `.pk-preview-body`'s own `padding: 24px`, insetting the sheet's text content 48px total while the poster figure (outside `.pk-preview-body`) was inset only 24px
- **Fix:** Removed `.pk-sheet-body`'s padding; the sheet now matches the portal's contract of zero padding of its own
- **Files modified:** `assets/css/app.css`
- **Verification:** Manual DOM inspection (poster/body rects both full sheet width post-fix) + visual screenshot
- **Committed in:** `89167d6`

---

**Total deviations:** 1 auto-fixed (1 bug). **Impact:** Necessary correctness fix for a real, user-reported layout defect in already-shipped 01-10 code; no scope creep into 01-11's own task list.

## Issues Encountered
- The available browser-automation tooling has no touch/swipe gesture emulation, so Task 3's `<human-check>` (real-phone swipe-to-end not triggering back-navigation, vertical swipe from a card scrolling the page) could not be exercised directly. `overscroll-behavior-x: contain` and `touch-action: manipulation` were confirmed present via computed styles on the rail; the actual gesture behavior should be spot-checked on a real device before shipping, same caveat as 01-10's touch-open-sheet path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Ready for `01-12` (sticky nav + mobile category chips), which continues in the same `pk-gutter`/`PK CATALOG SURFACES` CSS block and depends on this plan's shelf anchor (`.pk-shelf`, `scroll-margin-top`) and `pk-gutter` contract.
- Recommend a real-device check of the rail swipe/back-gesture behavior alongside 01-10's still-outstanding touch-sheet-open check.

---
*Phase: 01-catalog-v1*
*Completed: 2026-08-19*
