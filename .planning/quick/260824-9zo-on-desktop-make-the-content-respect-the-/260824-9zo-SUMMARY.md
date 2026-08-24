---
phase: quick-260824-9zo
plan: 01
subsystem: ui
tags: [phoenix, liveview, heex, tailwind, daisyui, carousel]

# Dependency graph
requires:
  - phase: 01.1-site-shell-content-pages
    provides: The shell-column recipe (mx-auto w-full max-w-7xl pk-gutter) used by header/footer/main grid
provides:
  - CarouselRow's row header and rail wrap (real + skeleton) capped to the same shell column as the header, footer and main grid
  - Corrected ui-design-system SKILL.md exception paragraph naming the shell column, so it no longer instructs agents to preserve uncapped shelves
affects: [ui-design-system-skill, catalog-live-index, carousel-row]

# Actuals (#2632)
actuals:
  tokens: 1931
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shell column recipe (mx-auto w-full max-w-7xl pk-gutter) applied per-section rather than via a single page-container div, on pages that run fullbleed on Layouts.app"

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/components/carousel_row.ex
    - test/pukllay_club_web/live/catalog_live_test.exs
    - .claude/skills/ui-design-system/SKILL.md

key-decisions:
  - "Applied the app's existing shell-column recipe (mx-auto w-full max-w-7xl pk-gutter) verbatim to the four width-bearing divs in CarouselRow rather than inventing a new width value — the recipe already exists at layouts.ex:407/655 and 6x in catalog_live/index.ex"
  - "No lg: breakpoint prefix added: max-w-7xl is a maximum, so w-full already governs at every viewport <=1280px, keeping mobile byte-identical with zero conditional logic"
  - "Rewrote the ui-design-system SKILL.md exception paragraph in place (not deleted) so the CatalogLive.Index exception still exists but now describes the shipped shell-capped reality, naming the concept 'shell column' so future agents can search for it"

patterns-established:
  - "Shell column: the recipe `mx-auto w-full max-w-7xl pk-gutter`, applied individually to every width-bearing section on a fullbleed page rather than via one wrapping container div"

requirements-completed: [SHELL-01]

coverage:
  - id: D1
    description: "Carousel row header and rail wrap (real render) are capped to the shell column, matching header/footer/main-grid alignment"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#a shelf's row-header and rail-wrap both carry the shell column and gutter classes"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#the unfiltered landing page renders the whole assembled contract in one pass"
        status: pass
    human_judgment: false
  - id: D2
    description: "Skeleton (disconnected mount) row header and rail wrap carry the identical shell-column recipe as the real row, so loading state does not reflow horizontally"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#the disconnected skeleton row carries the same shell column and gutter classes as the real row"
        status: pass
    human_judgment: false
  - id: D3
    description: "Visual alignment on a wide desktop viewport (row titles, first poster card, prev/next controls, edge-fade) lines up with header wordmark, footer brand lockup, and main grid heading"
    verification: []
    human_judgment: true
    rationale: "Pixel-level visual alignment across four independent surfaces (header, footer, main grid, carousel rows) at >=1440px requires a human eyeball check in a real browser window per the plan's <human-check> block — the class-string assertions prove the same recipe is applied, not that it renders visually aligned."
  - id: D4
    description: "ui-design-system SKILL.md no longer instructs a future agent to preserve uncapped shelves on CatalogLive.Index"
    verification:
      - kind: other
        ref: "grep -q 'shell column' .claude/skills/ui-design-system/SKILL.md"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-08-24
status: complete
---

# Quick Task 260824-9zo: Cap carousel shelves to the shell column Summary

**Carousel row headers and rail wraps (real + skeleton) now share the app's `mx-auto w-full max-w-7xl pk-gutter` shell column with the header, footer and main grid, closing a ~320px desktop misalignment; the design-system skill's stale "deliberate full-bleed" paragraph was rewritten so the fix cannot be silently reverted.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-08-24T10:10:00Z (approx)
- **Completed:** 2026-08-24T10:22:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- `CarouselRow`'s row header and rail wrap divs (both `carousel_row/1` and `skeleton_row/1`) now carry the same `mx-auto w-full max-w-7xl pk-gutter` shell-column recipe already used by the header inner and footer row, so poster cards, row titles, and prev/next scroll controls align with the header wordmark and main grid on desktop
- Added a new test proving the disconnected-mount skeleton row carries the identical recipe as the real row, preventing a future width drift between loading and loaded states
- Updated the four existing test assertions that encoded the old uncapped contract, and renamed the describe block to name the new behavior
- Rewrote the stale `ui-design-system/SKILL.md` exception paragraph that told agents the viewport-edge shelves were "the entire point" — it now names and documents the shell column so the next UI task reads the shipped behavior as intentional, not something to "fix" back to full-bleed
- Updated `CarouselRow`'s moduledoc opening line to describe the rail as shell-capped rather than full-bleed

## Task Commits

Each task was committed atomically:

1. **Task 1: Cap the carousel row header and rail wrap to the shell column** - `2e20503` (feat)
2. **Task 2: Correct the docs that would otherwise revert this** - `9b47d4e` (docs)

_No plan-metadata commit — orchestrator handles the docs commit for STATE.md/SUMMARY.md in a later step per this task's constraints._

## Files Created/Modified
- `lib/pukllay_club_web/components/carousel_row.ex` - Four `class` attribute edits (row header + rail wrap, real and skeleton) applying the shell-column recipe; moduledoc opening line updated from "full-bleed" to "shell-capped"
- `test/pukllay_club_web/live/catalog_live_test.exs` - Four assertions updated to the new full recipe string, describe block renamed, one new skeleton-parity test added
- `.claude/skills/ui-design-system/SKILL.md` - `CatalogLive.Index` exception paragraph rewritten to name and describe the shell column instead of instructing agents to preserve full-bleed shelves

## Decisions Made
- Used the app's existing shell-column recipe verbatim (no new width value, no new CSS class) — this is a structural port of a decision already validated in sketch 011 and recorded in `sketch-findings-pukllay_club/references/layout-navigation.md`, never previously shipped to production
- Deliberately added no `lg:` breakpoint prefix: `max-w-7xl` is a `max-width`, inert at and below 1280px, so mobile/tablet rendering is provably unchanged without any conditional logic to maintain

## Deviations from Plan

None - plan executed exactly as written. Both tasks' `<action>` and `<verify>` blocks were followed literally; no Rule 1-4 auto-fixes were needed.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The shell-column alignment fix is complete and covered by automated tests plus `mix quality`.
- One item remains for the human: the plan's `<human-check>` block (visual confirmation at >=1440px that the row titles, first poster card, header wordmark and grid heading share one vertical edge, that prev/next controls sit under the header's search icon, and that dark-theme edge-fades still read correctly). This is a manual visual check, not a blocking checkpoint task in the plan — it can be done by loading `/` in a browser at the next opportunity.
- No blockers for subsequent work; `G-01-4` (carousel affordance) and `G-01-3` (rail vs. grid scroll) remain separately tracked, unrelated to this width-alignment fix.

---
*Phase: quick-260824-9zo*
*Completed: 2026-08-24*

## Self-Check: PASSED

- FOUND: lib/pukllay_club_web/components/carousel_row.ex
- FOUND: test/pukllay_club_web/live/catalog_live_test.exs
- FOUND: .claude/skills/ui-design-system/SKILL.md
- FOUND commit: 2e20503
- FOUND commit: 9b47d4e
