---
phase: quick-260902-il3
plan: 01
subsystem: ui
tags: [phoenix, liveview, tailwind, heex, css, layouts]

requires:
  - phase: quick-260902-glf
    provides: the site-wide sticky-footer app shell removed, footer follows content
provides:
  - "Layouts.app `bottom_collapse` attr — a second, independent bottom-only axis alongside `boundary_collapse`"
  - "main.pk-bottom-collapse CSS rule, sharing its footer-margin declaration with the detail page's main.pk-boundary-collapse (D-04)"
  - "catalog index page opted into bottom_collapse; catalog page's last-shelf-to-footer gap now matches the detail page exactly"
affects: [catalog-index-ui, detail-page-ui, footer-layout]

actuals:
  tokens: 6316
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Two independent boundary-collapse axes on Layouts.app's <main>: boundary_collapse (both ends) and bottom_collapse (bottom only), nested as mutually-exclusive branches of one `if` so they can never both render (cascade-layer hazard avoidance)"
    - "Shared CSS declarations across pages via grouped selectors (main.pk-X + .pk-footer, main.pk-Y + .pk-footer { ... }) rather than duplicating literals per page"

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/components/layouts.ex
    - assets/css/app.css
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - test/pukllay_club_web/components/layouts_test.exs
    - test/pukllay_club_web/footer_rhythm_test.exs
    - test/pukllay_club_web/header_subnav_placement_test.exs

key-decisions:
  - "D-01: catalog page does NOT reuse boundary_collapse (would move its separately-closed top spacing, REQ-2 forbids this) — added a second, bottom-only axis instead"
  - "D-02: bottom_collapse is nested INSIDE boundary_collapse's `else` branch, not a third sibling — boundary_collapse always wins when both are true, so the two classes are structurally incapable of both rendering (no cascade-layer race)"
  - "D-03 (human-judgment flag): shipped 16px at <=480px / 24px above 480px, matching the detail page's actual rendered values — NOT a flat 24px as REQ-1's literal wording suggested. The app has shipped 16px at mobile since sketch 044 (260902-fdm); forcing 24px here would reopen that closed decision and leave the catalog page looser than the detail page at the exact width the original complaint came from."
  - "D-04: the two pages' footer-margin rules are grouped onto ONE shared declaration (main.pk-bottom-collapse + .pk-footer, main.pk-boundary-collapse + .pk-footer { margin-top: ... }) at both breakpoints, rather than duplicating the 1.5rem/1rem literals — one boundary decision, one place to retune it"
  - "Rule 1 auto-fix: header_subnav_placement_test.exs asserted a >=73px bottom-padding floor on the catalog page's <main>, justified as fixed-CTA-bar clearance — but the catalog page never renders a fixed CTA bar (only the detail page does, via body.pk-has-cta-bar). The floor only ever held by coincidence (catalog previously shared Detalle's old pb-20 default). Inverted into an absence guard now that bottom_collapse supplies the zero via CSS."

requirements-completed: [REQ-1, REQ-2, REQ-3, REQ-4, REQ-5]

coverage:
  - id: D1
    description: "Catalog page's last-shelf-to-footer gap drops from 128px/176px to 16px/24px (390px/1280px), matching the detail page exactly"
    requirement: "REQ-1"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/footer_rhythm_test.exs — 'bottom_collapse shares its footer-margin declaration with boundary_collapse (260902-il3)' describe (5 tests)"
        status: pass
      - kind: e2e
        ref: "live CDP measurement against localhost:4000/ at 339px/390px/1280px — see Live Measurements table below"
        status: pass
    human_judgment: false
  - id: D2
    description: "Catalog page's top spacing (padding-top, header-to-first-shelf distance) is provably unchanged at every measured width"
    requirement: "REQ-2"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs — 'with bottom_collapse set and boundary_collapse unset, <main> carries the bottom-collapse class and keeps the default top-padding utilities'"
        status: pass
      - kind: e2e
        ref: "live CDP measurement — padding-top 32px/80px and header-to-first-shelf 101px/80px at 390px/1280px, byte-identical to the recorded baseline"
        status: pass
    human_judgment: false
  - id: D3
    description: "Detail page and about page are untouched — no test guarding either was edited to make the fix pass"
    requirement: "REQ-3"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs 'boundary_collapse call-site contract' describe + test/pukllay_club_web/live/catalog_show_test.exs (both pre-existing, unedited, still passing)"
        status: pass
      - kind: e2e
        ref: "live CDP measurement — detail page /juegos/177 and about page /quienes-somos, byte-identical to baseline at 390px/1280px"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every new CSS rule and template branch carries a comment recording its measurement, rationale, and the closed decisions it deliberately does not reopen"
    requirement: "REQ-4"
    verification: []
    human_judgment: true
    rationale: "Comment density/quality is a documentation-style judgment call, not something a test can assert; reviewed manually against the density of the surrounding boundary_collapse comment block during implementation."
  - id: D5
    description: "Catalog page's grid surface (filtered results, not carousel shelves) and its two in-<main> overlays (#game-preview, #filter-modal) are measured, not assumed, for footer-overlap risk"
    requirement: "REQ-5"
    verification:
      - kind: e2e
        ref: "live CDP measurement against localhost:4000/?players=4 (grid surface) and computed-style checks on #game-preview/#filter-modal — see Live Measurements and Threat Mitigation Verification below"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-09-02
status: complete
---

# Quick Task 260902-il3: Fix the catalog page's bottom-boundary gap Summary

**Added a `bottom_collapse` axis to `Layouts.app` that closes the catalog page's 128px/176px last-shelf-to-footer gap down to 16px/24px, matching the detail page, without touching the catalog page's separately-tuned top spacing.**

## Performance

- **Duration:** ~13 min
- **Completed:** 2026-09-02T16:47:38Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added a `bottom_collapse` boolean attr to `Layouts.app`, structurally mutually exclusive with the existing `boundary_collapse` (nested inside its `else` branch, D-02) so the two can never both render.
- Added `main.pk-bottom-collapse` / `main.pk-bottom-collapse .pk-shelf:last-of-type` CSS rules that cancel `<main>`'s bottom padding and the trailing shelf's own margin, and grouped the catalog page's footer-margin rule onto the same declaration the detail page's `boundary_collapse` already ships (D-04) at both the >480px and ≤480px breakpoints.
- Wired the catalog index page's `<Layouts.app>` call to `bottom_collapse`, leaving its top spacing on the shared default per D-01.
- Added 7 new ExUnit tests in `layouts_test.exs` (exact-string contracts + call-site contracts for all three pages) and 5 new tests in `footer_rhythm_test.exs` (shared-declaration, ordering, and CSS-fact guards), every one of the `footer_rhythm_test.exs` guards verified RED against a deliberately-broken variant before being accepted green.
- Live-verified the fix over CDP at 339px/390px/1280px on the catalog page (both the carousel-shelf surface and the filtered grid surface), the detail page, and the about page — every number matches the plan's expected targets, with zero regression on the two untouched pages.
- Rule 1 auto-fix: corrected a stale pre-existing test (`header_subnav_placement_test.exs`) that asserted the catalog page's `<main>` must reserve ≥73px of bottom padding as "fixed-CTA-bar clearance" — the catalog page never renders a fixed CTA bar; that floor only ever held by coincidence.

## Task Commits

1. **Task 1: End-to-end bottom-collapse axis — catalog page only** - `01f3695` (feat, tdd)
2. **Task 2: Pin the shared-declaration and cross-breakpoint contracts as stylesheet regression guards** - `cf95f7b` (test, tdd)
3. **Task 3: Live-verify the geometry over CDP, sweep for regressions** - no code changes; this SUMMARY is the artifact (see Live Measurements below)

_Note: this quick task's PLAN.md was not pre-committed by the orchestrator; per the executor's own instructions, docs artifacts (this SUMMARY, STATE.md) are left uncommitted for the orchestrator to commit._

## Files Created/Modified

- `lib/pukllay_club_web/components/layouts.ex` - added `bottom_collapse` attr + restructured `<main>`'s class-list `if`/`else` nesting
- `assets/css/app.css` - added `main.pk-bottom-collapse` rules; grouped catalog/detail footer-margin selectors at both breakpoints
- `lib/pukllay_club_web/live/catalog_live/index.ex` - added `bottom_collapse` to the catalog page's `<Layouts.app>` call
- `test/pukllay_club_web/components/layouts_test.exs` - 7 new tests (bottom_collapse class contracts + 3-page call-site contracts)
- `test/pukllay_club_web/footer_rhythm_test.exs` - 5 new tests (shared-declaration, token-equality, padding-axis, and selector-ordering guards)
- `test/pukllay_club_web/header_subnav_placement_test.exs` - Rule 1 fix: inverted the stale ≥73px bottom-padding-floor test into a correct absence guard

## Decisions Made

See `key-decisions` in frontmatter (D-01 through D-04, plus the Rule 1 auto-fix). D-03 is explicitly flagged below as a human-judgment item.

**D-03 human-judgment flag:** the user's original request/REQ-1 wording asked for "24px" at both viewport widths. This ships **16px at ≤480px / 24px above 480px**, matching what the detail page already renders (a value the app committed to in sketch 044, quick task 260902-fdm). Shipping a flat 24px would have required either reopening that closed ≤480px decision or leaving the catalog page 8px looser than the detail page at exactly the mobile width the original gap complaint came from. A human should confirm this reading is correct.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected a stale bottom-padding floor test that would have blocked the fix**
- **Found during:** Task 1 (full regression sweep after implementing `bottom_collapse`)
- **Issue:** `test/pukllay_club_web/header_subnav_placement_test.exs` had a pre-existing test asserting the catalog page's (`/`) `<main>` must reserve ≥73px of bottom padding, justified in its own failure message as "fixed-CTA-bar clearance" for `.pk-mobile-cta-bar`/`.pk-about-cta-bar`. Neither of those bars is ever rendered by the catalog page — grep confirms `pk-has-cta-bar` is toggled only by `catalog_live/show.ex` (the detail page). The floor only ever held on the catalog page by coincidence: pre-fix, the catalog page shared the exact same `pb-20 pt-8 sm:pt-20` default branch as the about page (which does have justification unrelated to this test), not because the catalog page itself needed CTA-bar clearance.
- **Fix:** Inverted the test into `"the bottom padding is zeroed via bottom_collapse, not reserved as CTA-bar clearance"` — asserts `<main>` carries no base `pb-*` Tailwind utility and does carry `pk-bottom-collapse` instead. Removed the now-unused `@min_bottom_padding_px` module attribute, replaced with an explanatory comment pointing at the corrected test.
- **Files modified:** `test/pukllay_club_web/header_subnav_placement_test.exs`
- **Verification:** `mix test test/pukllay_club_web/header_subnav_placement_test.exs` (4/4 pass); full suite green (773/773)
- **Committed in:** `01f3695` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug/stale test)
**Impact on plan:** Necessary to land the plan's core objective at all — the stale test's premise directly contradicted the plan's explicit goal of zeroing the catalog page's bottom padding. No scope creep; the fix touches only the one test whose reasoning was factually wrong for the page it exercised.

## Issues Encountered

None beyond the deviation above.

## Live Measurements (Task 3, CDP)

All measurements taken headless (Chrome 151, `getBoundingClientRect()`/`getComputedStyle()` over CDP) against the running dev server at `localhost:4000`, per the plan's `<investigation_findings>` baseline.

### (A)+(B) Catalog page (`/`) — carousel-shelf surface

| Viewport | main padding-top | main padding-bottom | last-shelf margin-bottom | footer margin-top | last-shelf → footer gap | header → first-shelf |
|----------|-------------------|----------------------|----------------------------|---------------------|---------------------------|------------------------|
| 339px    | 32px              | 0px                  | 0px                        | 16px                 | **16px**                  | 101px                  |
| 390px    | 32px              | 0px                  | 0px                        | 16px                 | **16px**                  | 101px                  |
| 1280px   | 80px              | 0px                  | 0px                        | 24px                 | **24px**                  | 80px                   |

Matches D-03's target (16px at ≤480px, 24px above) exactly. Top spacing (padding-top 32px/80px, header-to-first-shelf 101px/80px) is byte-identical to the plan's recorded pre-fix baseline — REQ-2 confirmed unmoved.

### (C) Detail page (`/juegos/177`) — unchanged baseline

| Viewport | main class | padding-top | padding-bottom | last-shelf → footer |
|----------|------------|--------------|------------------|------------------------|
| 390px    | `pk-boundary-collapse` | 24px | 0px | 16px |
| 1280px   | `pk-boundary-collapse` | 24px | 0px | 24px |

Byte-identical to the plan's recorded baseline. No `pk-bottom-collapse` present.

### (C) About page (`/quienes-somos`) — unchanged baseline

| Viewport | main class | main → footer gap |
|----------|-------------|----------------------|
| 390px    | `pb-20 pt-8 sm:pt-20` | 16px |
| 1280px   | `pb-20 pt-8 sm:pt-20` | 48px |

1280px gap (48px) is byte-identical to the plan's recorded baseline. Neither `pk-bottom-collapse` nor `pk-boundary-collapse` present.

### (D) Catalog page — filtered results-grid surface (`?players=4`, `browsing_results?` = true)

| Viewport | grid-sentinel → footer gap |
|----------|-------------------------------|
| 390px    | 16px |
| 1280px   | 24px |

Measured cleanly at 16px/24px, not "16+1px" as the plan's pre-measurement estimate speculated — the `data-grid-sentinel` element's 1px height sits flush against `<main>`'s own bottom edge (which now carries `padding-bottom: 0`), so the visible gap is exactly the footer's `margin-top`, identical to the shelf surface. Confirmed not a defect (the plan explicitly anticipated and pre-authorized this outcome).

### (E) T-260902-il3-02 — `<main>`'s in-flow overlays after bottom-padding removal

Checked across all measured page states (default `/`, `?q=a` short-page state, `?players=4` filtered state), at 339px/390px/1280px:

| Element | position | in-flow height | visibility (closed state) | pointer-events (closed state) | overlaps footer visually |
|---------|----------|-------------------|-------------------------------|-----------------------------------|------------------------------|
| `#game-preview` | `static` | **0px** (every state) | n/a (empty box, no visible content by default) | n/a | No — zero height, contributes nothing to flow |
| `#filter-modal` (daisyUI `.modal`) | `fixed` | n/a (out of flow) | `hidden` | `none` | Geometric bounding-box overlap occurs on short pages (e.g. `?q=a`, where the footer is within the initial viewport), but `visibility: hidden` + `pointer-events: none` in the closed state mean it can neither be seen nor intercept clicks — confirmed via computed-style check, not assumed |

**Finding:** no fix needed. `#game-preview` genuinely contributes zero in-flow height in every tested state. `#filter-modal`'s `position: fixed` box can geometrically overlap the footer's rect on short pages, but its closed-state `visibility: hidden`/`pointer-events: none` (daisyUI's own modal mechanism, unmodified by this task) make that overlap harmless — it is neither visible nor clickable. T-260902-il3-02's mitigation holds without any additional change.

## Threat Flags

None — no new network endpoints, auth paths, file-access patterns, or trust-boundary schema changes introduced. This task is presentational only (one boolean template attr, CSS rules, one call-site flag), matching the plan's own threat-model assessment.

## Regression Sweep (Task 3F)

- `mix test`: **773/773 passing** (baseline 762 + 7 new `layouts_test.exs` tests + 5 new `footer_rhythm_test.exs` tests + 1 rewritten `header_subnav_placement_test.exs` test in place, net +11 new/rewritten assertions across the file set — 1 pre-existing test rewritten in place, not added)
- `mix format --check-formatted`: clean
- `mix quality` (full alias — hex.audit, deps.audit, deps.unlock --check-unused, format, credo, sobelow, test): clean. Sobelow's 5 findings are pre-existing low-confidence findings in unrelated seed/import modules, untouched by this task.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The catalog page's bottom-boundary gap is closed and matches the detail page's rhythm exactly. No known regressions on the detail or about pages.
- Human visual confirmation still recommended (per the plan's `<human-check>` verify step and the D-03 human-judgment flag above) — a live browser check at 390px and 1280px that the 16px/24px split reads as intentional, matching the precedent set by prior footer-spacing quick tasks (260901-ty6, 260902-fdm, 260902-g21, 260902-glf).
- No blockers for future UI work on this surface.

---
*Quick Task: 260902-il3*
*Completed: 2026-09-02*

## Self-Check: PASSED

All 6 modified source/test files and the SUMMARY.md itself confirmed present on disk. Both task
commits (`01f3695`, `cf95f7b`) confirmed present in `git log`. No missing items.
