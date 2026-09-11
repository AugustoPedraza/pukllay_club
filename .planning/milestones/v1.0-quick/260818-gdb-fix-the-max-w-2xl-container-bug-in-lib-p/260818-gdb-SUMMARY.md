---
phase: quick-260818-gdb
plan: 01
subsystem: ui
tags: [phoenix, liveview, tailwind, daisyui, layout]

requires:
  - phase: 01-catalog-v1
    provides: CatalogLive.Index (max-w-7xl) and CatalogLive.Show (max-w-4xl) page containers that this plan's fix unblocks

provides:
  - Layouts.app's content wrapper no longer imposes a 672px (max-w-2xl) width cap on every page
  - Page-level regression tests proving / renders inside max-w-7xl and /juegos/:id inside max-w-4xl
  - Component-level regression test pinning Layouts.app's width-cap-free contract
  - Updated ui-design-system SKILL.md page-container rule describing the fixed contract (no longer an open bug)

affects: [ui, catalog, any future LiveView page relying on Layouts.app for its width]

actuals:
  tokens: 1922
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Page width is each LiveView's own responsibility; Layouts.app's wrapper carries no max-w-* of its own"

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/components/layouts.ex
    - test/pukllay_club_web/components/layouts_test.exs
    - test/pukllay_club_web/live/catalog_live_test.exs
    - test/pukllay_club_web/live/catalog_show_test.exs
    - .claude/skills/ui-design-system/SKILL.md

key-decisions:
  - "Dropped only the max-w-2xl utility from Layouts.app's inner wrapper div, keeping mx-auto and space-y-4 intact — <main>'s own padding (px-4 py-20 sm:px-6 lg:px-8) was explicitly left untouched since CatalogLive.Show depends on it for its gutters"
  - "No explanatory code comment left in layouts.ex naming the removed class (per plan instruction); rationale recorded in commit messages instead"

patterns-established:
  - "Never nest two max-w-* containers — the narrower one silently wins regardless of nesting order (now codified in ui-design-system SKILL.md)"

requirements-completed: [QUICK-260818-GDB]

coverage:
  - id: D1
    description: "/ renders inside CatalogLive.Index's own max-w-7xl container with no 672px ancestor cap"
    requirement: "QUICK-260818-GDB"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#renders inside its own max-w-7xl container, with no 672px ancestor cap"
        status: pass
    human_judgment: false
  - id: D2
    description: "/juegos/:id renders inside CatalogLive.Show's own max-w-4xl container with no 672px ancestor cap"
    requirement: "QUICK-260818-GDB"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#renders inside its own max-w-4xl container, with no 672px ancestor cap"
        status: pass
    human_judgment: false
  - id: D3
    description: "Layouts.app's content wrapper imposes no max-w-2xl page-width cap and still centers slot content via mx-auto"
    requirement: "QUICK-260818-GDB"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#app/1 content wrapper imposes no 672px page-width cap, and still centers slot content"
        status: pass
    human_judgment: false
  - id: D4
    description: "Visual confirmation that the catalog grid and detail page render noticeably wider than the previous 672px cap, in both light and dark themes"
    verification: []
    human_judgment: true
    rationale: "Requires a human to load the running app in a browser and visually judge layout width/gutters/theme rendering — the automated tests prove the correct Tailwind classes are present, but not that the rendered layout looks right."

duration: 25min
completed: 2026-08-18
status: complete
---

# Quick Task 260818-gdb: Fix the max-w-2xl container bug in Layouts.app Summary

**Removed the `max-w-2xl` width cap that `Layouts.app`'s wrapper silently imposed on every page (capping the catalog grid and detail page at 672px), added page- and component-level regression tests, and updated the design-system rule that previously documented this as an open bug.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-08-18T14:32:00Z
- **Completed:** 2026-08-18T14:57:11Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- `Layouts.app`'s content wrapper no longer declares `max-w-2xl` — page width is now purely each LiveView's own responsibility (`max-w-7xl` for the catalog index, `max-w-4xl` for the detail page)
- Two new page-level regression tests (`catalog_live_test.exs`, `catalog_show_test.exs`) assert the correct container class is present and the 672px cap is absent
- One new component-level regression test (`layouts_test.exs`) pins the layout wrapper's contract directly, so a future page cannot silently reinherit the cap
- `ui-design-system/SKILL.md`'s page-container rule rewritten to describe the fixed contract (page width belongs to the LiveView; never nest two `max-w-*` containers; `<main>`'s padding is separately load-bearing for `CatalogLive.Show`) instead of flagging an open defect

## Task Commits

Each task was committed atomically (TDD RED → GREEN per task):

1. **Task 1: End-to-end — a catalog page renders at its own container width**
   - `0fc6e30` (test) — RED: failing page-level regression tests for both `/` and `/juegos/:id`
   - `0058274` (feat) — GREEN: dropped `max-w-2xl` from `Layouts.app`'s wrapper
2. **Task 2: Component-level regression guard on the layout wrapper** — `6d7893f` (test)
3. **Task 3: Update the design-system page-container rule** — `b44d927` (docs)

_Task 2's test was written directly against the already-fixed layout (GREEN from Task 1), consistent with its role as a pure regression guard rather than a new-behavior RED/GREEN pair._

## Files Created/Modified
- `lib/pukllay_club_web/components/layouts.ex` — dropped `max-w-2xl` from `app/1`'s content wrapper div; `mx-auto space-y-4` retained, `<main>`'s own classes untouched
- `test/pukllay_club_web/live/catalog_live_test.exs` — added the `/` max-w-7xl / no-max-w-2xl regression test
- `test/pukllay_club_web/live/catalog_show_test.exs` — added the `/juegos/:id` max-w-4xl / no-max-w-2xl regression test
- `test/pukllay_club_web/components/layouts_test.exs` — added the `app/1 content wrapper` describe block pinning the wrapper's contract
- `.claude/skills/ui-design-system/SKILL.md` — rewrote the `Page container:` bullet to describe the fixed contract and added a caution about `<main>`'s load-bearing padding

## Decisions Made
- Only the `max-w-2xl` utility was removed from the wrapper div — `mx-auto` and `space-y-4` were kept, and `<main>`'s own `px-4 py-20 sm:px-6 lg:px-8` was left byte-identical, since `CatalogLive.Show` declares no padding of its own and depends on it (explicit plan scope boundary).
- No explanatory comment referencing the removed class was left in `layouts.ex` — the plan's `<verify>` gate greps the file for that exact scenario, and the rationale lives in the commit message instead.

## Deviations from Plan

None in the scope of this plan's own files — all three tasks executed as written, including the explicit exclusions (no `<main>` padding changes, no code comment naming the removed class).

### Pre-existing out-of-scope condition (not fixed, logged to ledger)

`mix quality`'s literal "passes clean" success criterion is currently blocked by conditions that predate and are unrelated to this plan:
- `config/runtime.exs` has pre-existing unstaged formatting drift (present in `git status` before this plan started; not in this plan's `files_modified`).
- Sobelow's low-confidence `Traversal.FileModule` findings in `lib/pukllay_club/catalog/seed/csv_import.ex` and `lib/pukllay_club/catalog/seed/report.ex` (pre-existing, not touched by this plan) cause `sobelow --config`'s configured `exit: true, threshold: :low` to return non-zero.
- Credo `--strict` reports one pre-existing `Software Design` suggestion in `lib/pukllay_club_web/components/core_components.ex` (also untouched by this plan).

Per the scope-boundary rule, none of these were fixed here. Verified independently instead:
- `mix test --warnings-as-errors` — **143 tests, 0 failures**, no compiler warnings.
- `mix credo --strict lib/pukllay_club_web/components/layouts.ex` — clean, no issues.
- `mix sobelow --exit` — no findings reference `layouts.ex`.
- `mix hex.audit` / `mix deps.audit` — clean (no retired packages, no vulnerabilities).

Logged to `.planning/WINDOWS.md` (entry id 1, kind `deviation`) so it stays visible at ship time.

---

**Total deviations:** 0 auto-fixed within this plan's scope; 1 pre-existing out-of-scope condition logged to the broken-windows ledger (not fixed, per scope-boundary rule).
**Impact on plan:** None — this plan's own success criteria (width-cap removal, three new regression tests, updated design-system rule) are all met and independently verified.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Human Verification Pending

Per Task 1's `<verify><human-check>`: run `mix phx.server`, open `/` on a desktop-width viewport, and confirm the catalog grid now spans well past ~672px (reaching 4 columns at `lg`) instead of sitting in a narrow centred column; then open a `/juegos/:id` page and confirm it renders wider than before with its left/right gutters intact. Also confirm this looks correct in both light and dark themes (plan's `<verification>` section). This project's `workflow.human_verify_mode` is `end-of-phase`, so this check was not executed as a blocking mid-flight checkpoint — it is recorded here (and as `coverage` deliverable D4 with `human_judgment: true`) for follow-up.

## Next Phase Readiness
- The width-cap defect is fixed and regression-tested at both the page and component level; no ancestor element caps any future page's width unless a new `max-w-*` is deliberately added to `Layouts.app` again (now discouraged by the updated design-system rule).
- No blockers for subsequent work.

---
*Phase: quick-260818-gdb*
*Completed: 2026-08-18*

## Self-Check: PASSED

All 5 modified/created files verified present on disk; all 4 task commit hashes (0fc6e30, 0058274, 6d7893f, b44d927) verified present in git log.
