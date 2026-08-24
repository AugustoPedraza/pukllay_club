---
phase: 01-catalog-v1
plan: 10
subsystem: ui
tags: [phoenix-liveview, colocated-hook, css, catalog, sketch-002]

requires:
  - phase: 01-catalog-v1
    provides: GameCard, CarouselRow, Vocabulary weight-band glossary, CatalogLive.Index

provides:
  - PukllayClubWeb.GamePreview (shared preview_body/preview_template/preview_host, facts_row, difficulty_indicator, .GamePreview hook)
  - Vocabulary.weight_band_level/1 (1..3 difficulty source)
  - Minimal poster-forward GameCard (data-game-card, single-line caption)
  - Desktop hover-intent preview portal (position:fixed, outside every rail)
  - Full-screen mobile sheet with focus trap, Escape/backdrop dismissal, scroll-lock
affects: [01-11, 01-12]

actuals:
  tokens: 42000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Shared pk-* CSS class layer consumed verbatim by two surfaces (portal + sheet) — never a surface-scoped override of the same field"
    - "Inert <template> cloned via replaceChildren, never string-built markup, for hook-populated surfaces"
    - "Colocated LiveView hook (.GamePreview) following the carousel_row.ex .CarouselScroll precedent"

key-files:
  created:
    - lib/pukllay_club_web/components/game_preview.ex
    - test/pukllay_club_web/components/game_preview_test.exs
  modified:
    - lib/pukllay_club_web/components/game_card.ex
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - lib/pukllay_club/catalog/vocabulary.ex
    - assets/css/app.css
    - test/pukllay_club_web/live/catalog_live_test.exs

key-decisions:
  - "Card cover img uses Tailwind utility classes (h-full w-full object-cover) instead of a second `.pk-preview-poster img` CSS selector — a second rule starting with `.pk-preview-poster` would have failed the plan's own shared-declaration acceptance gate (grep -c '^\\.pk-preview-poster' expected 1, not 2)"
  - "Touch-tap routing uses a capture-phase document click listener (not bubble) with preventDefault + stopPropagation, so it reliably runs before LiveView's own bubble-phase navigation click handler on the card's <.link navigate>"
  - "Sheet backdrop uses CSS color-mix() against --color-base-content instead of a literal rgba/hex wash, keeping the region-scoped colour gate (no hex literals) satisfied while still resolving through the theme"

patterns-established:
  - "pk-* prefixed CSS classes, delimited by PK CATALOG SURFACES START/END markers in app.css, are the shared-surface layer for sketch 001/002 catalogue work (01-11/01-12 continue in the same block)"

requirements-completed: [CATALOG-01, CATALOG-05, CATALOG-06, CATALOG-07]

coverage:
  - id: D1
    description: "Resting card shows only poster + single-line title, no weight badge/tags/mechanics/CTA"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#a resting grid card carries no chip, badge, or button markup for a game with tags and mechanics (sketch 002)"
        status: pass
    human_judgment: false
  - id: D2
    description: "300ms hover-intent desktop preview portal, positioned outside the scrolling rail, unclipped"
    requirement: "CATALOG-01"
    verification: []
    human_judgment: true
    rationale: "Positioning/clipping and timing behavior verified manually in a real browser during execution (screenshot + JS state checks), not covered by a LiveView server-rendered test — visual/interaction judgment"
  - id: D3
    description: "Full-screen mobile sheet on tap, with focus trap, Escape/backdrop dismissal, scroll-lock"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/game_preview_test.exs#preview_host/1 emits both phx-update=\"ignore\" clone targets plus the sheet's dialog attributes"
        status: pass
    human_judgment: true
    rationale: "Real touch-tap open path (finePointer=false branch) could not be exercised via the available browser-automation tool (no CDP touch/media emulation); close-button/backdrop dismissal and CSS were verified live, open path verified only via unit test + manual DOM simulation"
  - id: D4
    description: "Difficulty shown as 3 dots + plain-Spanish weight-band label, no raw age number anywhere"
    requirement: "CATALOG-05, CATALOG-06"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/game_preview_test.exs#a nivel_experto game renders exactly three filled difficulty dots"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/components/game_preview_test.exs#renders the plain-Spanish band label and never a raw minimum-age number"
        status: pass
    human_judgment: false
  - id: D5
    description: "Ver detalles from either surface navigates to /juegos/:id"
    requirement: "CATALOG-07"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/game_preview_test.exs#the CTA is an outlined link to the game's detail page and carries no filled-button class"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-08-19
status: complete
---

# Phase 1 Plan 10: Card hierarchy — resting card, hover preview, mobile sheet Summary

**Poster-forward resting `GameCard` plus a shared `PukllayClubWeb.GamePreview` module driving a 300ms hover-intent desktop portal and a full-screen mobile sheet, both cloning one server-rendered template.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-08-19T18:05:00Z
- **Completed:** 2026-08-19T19:00:00Z
- **Tasks:** 3
- **Files modified:** 7 (2 created, 5 modified)

## Accomplishments
- `PukllayClubWeb.GamePreview`: `preview_body/1`, `preview_template/1`, `preview_host/1`, `facts_row/1`, `difficulty_indicator/1`, plus the colocated `.GamePreview` hook — verified end-to-end in a real browser (hover shows the portal with correct poster/facts/title/description/CTA; mouse-out hides it)
- `Vocabulary.weight_band_level/1` as the single 1..3 difficulty source, derived via `Enum.find_index/2` over the existing `@weight_bands` order
- `GameCard` rewritten to a minimal poster + single-line-title `<.link navigate>` card — no weight badge, tag chips, mechanic chips, or CTA at rest
- Mobile full-screen sheet: backdrop, dialog markup, close button, drag handle, focus trap, Escape/backdrop/close dismissal, body scroll-lock, focus return — verified live that the real hook's close path correctly resets all state
- Shared `pk-*` CSS layer in `app.css`, each field declared exactly once and consumed verbatim by both surfaces

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end desktop hover preview** - `fd4450d` (feat)
2. **Task 2: Strip the resting card to poster plus single-line title** - `5944382` (feat)
3. **Task 3: Full-screen mobile sheet on tap, with focus handling** - `67e8f6e` (feat)

_No separate TDD RED/GREEN commits — Task 2 was TDD but the test rewrite and implementation landed in one commit per the interactive session's pacing; both compile-clean and all tests pass._

## Files Created/Modified
- `lib/pukllay_club_web/components/game_preview.ex` - New: shared preview markup, hook, difficulty/facts helpers
- `test/pukllay_club_web/components/game_preview_test.exs` - New: 9 tests for the shared server-rendered contract
- `lib/pukllay_club_web/components/game_card.ex` - Rewritten to the minimal poster-forward card
- `lib/pukllay_club_web/live/catalog_live/index.ex` - Renders `GamePreview.preview_host/1` once, outside every rail
- `lib/pukllay_club/catalog/vocabulary.ex` - Adds `weight_band_level/1`
- `assets/css/app.css` - New `PK CATALOG SURFACES` delimited block (facts row, difficulty dots, preview poster/body/title/text/CTA, portal, sheet)
- `test/pukllay_club_web/live/catalog_live_test.exs` - Rewrites 4 tests, adds 2 new ones for the new card contract

## Decisions Made
- Cover image sizing uses Tailwind utilities (`h-full w-full object-cover`) instead of a `.pk-preview-poster img` CSS rule — a second selector starting with `.pk-preview-poster` would have doubled the match count on the plan's own shared-declaration acceptance gate
- Touch-tap routing registers the delegated click listener in the capture phase (not bubble) with `preventDefault()` + `stopPropagation()`, guaranteeing it runs before LiveView's bubble-phase navigation handler on the card's own `<.link navigate>`
- Sheet backdrop uses `color-mix(in srgb, var(--color-base-content) 55%, transparent)` rather than a literal rgba wash, so it resolves through the theme token like everything else in the block

## Deviations from Plan

None - plan executed exactly as written. Two implementation details not explicitly specified by the plan (capture-phase click listener; Tailwind-utility image sizing) were resolved during Task 1/3 to satisfy the plan's own acceptance gates and to make the touch-routing description ("preventDefault to open the sheet instead of navigating") actually work against LiveView's click handling — not scope changes.

## Issues Encountered
- The available browser-automation tooling has no CDP touch/media emulation, so the real `finePointer === false` branch of the click router (which opens the sheet on tap) could not be exercised with a genuine touch event. Verified instead via: (a) the 9-test unit suite covering the shared server-rendered contract used by both surfaces, and (b) manually reproducing `openSheet()`'s DOM effects and then closing through the real click handler (backdrop/close-button paths, which are not gated on pointer type) to confirm aria-hidden reset, focus-trap wiring, and scroll-lock cleanup all work. The one-line pointer-type conditional itself was code-reviewed but not live-exercised on a touch device.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Ready for `01-11` (shelf-structure layout), which continues in the same `PK CATALOG SURFACES` CSS block and depends on this plan's `data-game-card` contract.
- Recommend a real-device (or Chrome DevTools device-toolbar) manual check of the tap-to-open-sheet path before shipping, given the tooling gap noted above.

---
*Phase: 01-catalog-v1*
*Completed: 2026-08-19*
