---
phase: 01-catalog-v1
plan: 12
subsystem: ui
tags: [phoenix-liveview, css, catalog, sketch-001, navigation, intersection-observer]

requires:
  - phase: 01-catalog-v1
    provides: pk-gutter token and .pk-gutter rule, .pk-shelf/.pk-rail-wrap/.pk-rail layer, Layouts.app fullbleed attr (01-11)

provides:
  - Layouts.app sticky attr plus nav_links/nav_search/subnav slots
  - .CatalogNav colocated hook (scroll tint + chip scroll-spy)
  - Sticky, gutter-aligned nav carrying 4 shelf anchors and the search box
  - Mobile category chip row (pk-chip-nav) as the narrow-viewport nav dimension
  - pk-* catalogue surface layer recorded in .claude/skills/ui-design-system/SKILL.md
  - Composite LiveView test proving 01-10/01-11/01-12 compose on the real page
affects: []

actuals:
  tokens: 58000
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Colocated hooks require phx-hook to be a STATIC string literal for Phoenix's compile-time .Name -> Module.Name qualification to fire; a dynamic expression (cond && \".Name\") ships an unresolvable hook name with no compile-time warning"
    - "A same-specificity CSS override placed earlier in a stylesheet loses to a later plain rule regardless of whether it's inside a matching @media block — the narrow-viewport switch block must be positioned last, after every base rule it overrides"

key-files:
  modified:
    - lib/pukllay_club_web/components/layouts.ex
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - assets/css/app.css
    - test/pukllay_club_web/components/layouts_test.exs
    - test/pukllay_club_web/live/catalog_live_test.exs
    - .claude/skills/ui-design-system/SKILL.md

key-decisions:
  - "app/1 renders two separate static <div id=\"app-header\"> branches (:if={@sticky} / :if={!@sticky}) sharing a private header_inner/1, instead of one div with a dynamic phx-hook expression — required for the colocated hook's compile-time name qualification to work at all. Found live: 'unknown hook found for \".CatalogNav\"' in the browser console."
  - "The narrow-viewport @media (max-width: 480px) block — extended in this plan with the nav-links/chip-nav display swap — must be the LAST rule block in the delimited CSS section, after every base rule (.pk-nav-links, .pk-chip-nav, .pk-nav-search) it overrides. Found live: chips never appeared at narrow width because the media block, positioned earlier in the file (from 01-11), lost the cascade to the later plain .pk-nav-links{display:flex} rule regardless of the media query matching."
  - "Chip scroll-spy (IntersectionObserver) could not be empirically verified in this session's browser-automation tab: document.visibilityState reports 'hidden' even while the tab has focus, and Chrome throttles IntersectionObserver callbacks for non-visible tabs (confirmed with a raw, unrelated IntersectionObserver test in the same tab that also never fired). The DOM wiring (chip/section pairing, guard conditions) is code-reviewed and structurally correct; anchor-link and chip-click navigation (native browser behavior, unaffected by the throttling) were verified live and land correctly below the sticky header."

patterns-established:
  - "pk-* catalogue surface layer is now formally the sanctioned custom-CSS home in .claude/skills/ui-design-system/SKILL.md — future custom CSS extends this block rather than starting a new one"

requirements-completed: [CATALOG-01, CATALOG-05, CATALOG-06, CATALOG-07]

coverage:
  - id: D1
    description: "Sticky header pinned to viewport top, tints flat-translucent on scroll, no blur"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#emits the sticky wrapper and the nav-hook attribute when sticky is true (01-12)"
        status: pass
    human_judgment: true
    rationale: "Sticky positioning and the is-scrolled tint toggle were verified live via a real browser (manual scroll-event dispatch + screenshot), which server-rendered tests cannot assert directly"
  - id: D2
    description: "Four shelf anchor links + search box in the header, resolving to real section ids, byte-identical detail-page header when not sticky"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#every shelf anchor href resolves to an element id present in the document"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#emits no nav-hook attribute value when sticky is not passed (01-12)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Mobile category chip row replaces nav links below ~480px, spacer end margins, 44px chips"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#the unfiltered landing render emits one chip per populated shelf, each targeting a real section id, bracketed by spacers"
        status: pass
    human_judgment: true
    rationale: "Chip pill styling, real click-through navigation, and scroll-margin clearance were confirmed live in the browser; the active-chip highlight (IntersectionObserver scroll-spy) could not be exercised due to a tab-visibility/throttling limitation in this session's tooling — needs a real-device or foregrounded-tab check"
  - id: D4
    description: "Design-system skill records the pk-* layer, its rules, and the full component inventory"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#the unfiltered landing page renders the whole assembled contract in one pass"
        status: pass
      - kind: other
        ref: "grep -c 'pk-gutter'/'GamePreview' .claude/skills/ui-design-system/SKILL.md (both >=1)"
        status: pass
    human_judgment: false

duration: 90min
completed: 2026-08-19
status: complete
---

# Phase 1 Plan 12: Navigation — sticky nav, mobile chips, design-system record Summary

**Sticky gutter-aligned nav carrying shelf anchors and search, a mobile category-chip row with scroll-spy wiring, and the `pk-*` catalogue surface layer formally recorded in the project's design-system skill — closing out Phase 01's catalog UI.**

## Performance

- **Duration:** 90 min
- **Started:** 2026-08-19T20:20:00Z
- **Completed:** 2026-08-19T21:50:00Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- `Layouts.app` gains `sticky` + `nav_links`/`nav_search`/`subnav` slots; `.CatalogNav` colocated hook toggles `is-scrolled` past a 40px threshold — verified live end to end after fixing a real compile-time hook-qualification bug
- Search form moved into the header verbatim (same id/bindings, zero test breakage); 4 shelf anchors filtered to populated rows, rendered only when unfiltered
- Mobile `pk-chip-nav`: spacer-bracketed chips, one per populated shelf, real click-through navigation confirmed live landing correctly below the sticky header
- Chip scroll-spy (`IntersectionObserver`) wired per spec, guarded on ≥1 chip + ≥1 resolvable section — could not be empirically confirmed active due to a tooling limitation (see Issues Encountered)
- `.claude/skills/ui-design-system/SKILL.md` now documents the `pk-*` layer as the sanctioned custom-CSS home, its rules (shared-declaration, single-gutter-token, media-block-must-be-last), and the full class/component inventory
- One composite LiveView test proves the sticky header, search, nav links, chips, gutter-shared shelf, rail markers, Ver todo tile, card marker, and preview host all render together on the real page — not just in isolation
- **Two real bugs found and fixed live during this plan**, both documented in the skill so they aren't rediscovered:
  1. A dynamic `phx-hook={cond && ".Name"}` expression never gets Phoenix's compile-time `.Name` → `Module.Name` qualification, producing a silent "unknown hook found" runtime failure
  2. A same-specificity CSS rule earlier in the file loses to a later plain rule regardless of a matching `@media` query — the narrow-viewport nav switch had to move to the very end of the delimited block

## Task Commits

Each task was committed atomically:

1. **Task 1: Sticky, gutter-aligned nav carrying shelf anchors and the search box** - `c43af16` (feat)
2. **Task 2: Mobile category chip row as the narrow-viewport navigation dimension** - `7ba43ba` (feat)
3. **Task 3: Record the pk-* catalogue surface layer in the design-system skill and sweep the whole page** - `2b688cf` (docs)

## Files Created/Modified
- `lib/pukllay_club_web/components/layouts.ex` - `sticky` attr, 3 new slots, `.CatalogNav` hook (scroll tint + scroll-spy), `header_inner/1`
- `lib/pukllay_club_web/live/catalog_live/index.ex` - search form moved into `nav_search`, `nav_links`/`subnav` (chips) filled, `nav_link_entries/1`
- `assets/css/app.css` - `.pk-header(-sticky)`, `.pk-nav(.is-scrolled)`, `.pk-nav-links`, `.pk-nav-search`, `.pk-chip-nav`, `.pk-chip(.is-active)`, `.pk-chip-spacer`; narrow-viewport block moved to end of the delimited section
- `test/pukllay_club_web/components/layouts_test.exs` - 2 new tests for sticky on/off
- `test/pukllay_club_web/live/catalog_live_test.exs` - 6 new tests (search-in-header, anchor resolution, 3 chip tests, 1 composite test)
- `.claude/skills/ui-design-system/SKILL.md` - new catalogue surface layer section, amended core/page-container rules, extended component inventory

## Decisions Made
- Split `app/1`'s hook-carrying wrapper into two statically-attributed `:if` branches instead of one dynamic-attribute div — the only way to get Phoenix's compile-time colocated-hook name qualification to fire.
- Moved the entire narrow-viewport `@media` block (density values from 01-11 plus this plan's nav/chip switch) to the very end of the delimited CSS section, after every rule it overrides, to fix a cascade-order bug where the override silently lost regardless of the media query matching.
- Both fixes above are documented as explicit rules in the design-system skill's new section, not just fixed in place, so a future plan extending this CSS block doesn't rediscover them.

## Deviations from Plan

**1. [Rule 1 - Bug] Fixed colocated-hook qualification failure**
- **Found during:** Task 1 tracer checkpoint, live browser verification
- **Issue:** `phx-hook={@sticky && ".CatalogNav"}` rendered the literal, unqualified string `.CatalogNav` to the DOM; Phoenix's compile-time rewrite to `PukllayClubWeb.Layouts.CatalogNav` only applies to static string-literal attributes, not dynamic expressions — console showed "unknown hook found for '.CatalogNav'"
- **Fix:** Split into two `:if`-gated branches, each with a fully static `phx-hook=".CatalogNav"` (present) or no `phx-hook` at all (absent), sharing markup via a new private `header_inner/1` component
- **Files modified:** `lib/pukllay_club_web/components/layouts.ex`, `test/pukllay_club_web/components/layouts_test.exs` (assertions updated to check the qualified substring `"CatalogNav"` rather than the literal `.CatalogNav` string)
- **Verification:** Live browser check — `phx-hook` attribute resolves to `PukllayClubWeb.Layouts.CatalogNav`, scroll listener fires and toggles `is-scrolled`
- **Committed in:** `c43af16`

**2. [Rule 1 - Bug] Fixed narrow-viewport nav/chip display-switch cascade-order loss**
- **Found during:** Task 1 live browser verification (nav links stayed visible at a 335px viewport despite the media query matching)
- **Issue:** The `@media (max-width: 480px)` block (created in 01-11, extended in this plan) was positioned before the base `.pk-nav-links`/`.pk-chip-nav` rules in the file; same-specificity + later-source-wins meant the base `display: flex` always won regardless of the media query
- **Fix:** Moved the entire media block to the end of the delimited `PK CATALOG SURFACES` section, after every rule it overrides
- **Files modified:** `assets/css/app.css`
- **Verification:** Live browser check at 335px — nav links hidden, search box fills the row, chip row visible
- **Committed in:** `c43af16`

---

**Total deviations:** 2 auto-fixed (2 bugs, both found via live browser verification rather than the automated test suite, which cannot observe client-side hook mounting or cascade behavior). **Impact:** Both were necessary correctness fixes for features this plan's own tasks were building; no scope creep.

## Issues Encountered
- The chip scroll-spy's `IntersectionObserver` could not be empirically verified firing in this session. `document.visibilityState` reports `"hidden"` on the automated browser tab even while it has focus and accepts input/screenshots, and Chrome throttles `IntersectionObserver` (and most rAF-driven work) for non-visible tabs — confirmed by a raw, unrelated `IntersectionObserver` test in the same tab that also never received a callback. This is a tooling limitation, not a confirmed code defect: the hook's guard logic and chip/section pairing are code-reviewed and structurally correct, and everything NOT gated on IntersectionObserver (chip rendering, real click-through anchor navigation, scroll-margin clearance) was confirmed live. Needs a real-device or foregrounded-tab check before considering the active-chip highlight fully verified.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 01 (Catalog v1) is now feature-complete across all 12 plans.
- Two outstanding real-device verification gaps carried forward from this phase's UI work (all found via the same automation-tooling limitation, not known defects):
  1. 01-10's mobile sheet: real touch-tap-to-open path (the `finePointer === false` branch)
  2. 01-11's rail: swipe-to-end not triggering back-navigation, vertical swipe-from-card scrolling the page
  3. 01-12's chip scroll-spy: active-chip highlight while scrolling
- Recommend a single real-phone pass through the catalogue page to close all three before considering Phase 01's mobile UX fully signed off.

---
*Phase: 01-catalog-v1*
*Completed: 2026-08-19*
