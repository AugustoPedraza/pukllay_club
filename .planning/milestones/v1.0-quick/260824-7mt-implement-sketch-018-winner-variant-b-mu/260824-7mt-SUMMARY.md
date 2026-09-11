---
phase: quick-260824-7mt
plan: 01
subsystem: ui
tags: [css, theme-toggle, footer, accessibility, color-mix, wcag]

# Dependency graph
requires:
  - phase: sketch-018
    provides: winning variant B design direction (fade + shrink + tone)
provides:
  - Faded/shrunk/toned theme-toggle glyphs in the shared .pk-theme-toggle CSS block, applied identically at both call sites (footer and mobile drawer)
affects: [footer, mobile-drawer, theme-toggle, ui-design-system]

# Actuals (#2632)
actuals:
  tokens: 1380
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "color-mix(in srgb, ...) for theme-adaptive faded/toned colors (existing app.css idiom, now used on the theme toggle too)"

key-files:
  created: []
  modified:
    - assets/css/app.css
    - .planning/sketches/018-theme-toggle-subtlety/README.md

key-decisions:
  - "Shipped 75% rest-state fade instead of the sketch's 55% — 55% measured 2.25:1 against the light-theme footer surface, failing WCAG 2.1 SC 1.4.11's 3:1 non-text-contrast floor; 75% clears it in both themes (3.22:1 light, 4.94:1 dark)."
  - "Sized the child span (.pk-theme-toggle button > span) at 14px rather than targeting `button svg` — hero icons render as CSS-mask-painted <span> elements (CoreComponents.icon/1 + assets/vendor/heroicons.js), so an svg selector would silently match nothing."
  - "14px produces subordination, not the size parity the sketch assumed — shipped social glyphs measured 16px (not the sketch's assumed 14px), and the toggle's own glyphs were already 16px too."
  - "Added a hover rule (color: var(--color-base-content)) since a newly-faded control needs an explicit pointer response; deliberately did not touch :focus-visible, which was already tuned by G-01-7."
  - "Left the active underline's geometry (left/right/bottom/height/border-radius) untouched — only recolored it — because variant B's absolute insets were measured on a 32px demo button, not this shipped 44px touch target."

patterns-established: []

requirements-completed: [SHELL-01]

coverage:
  - id: D1
    description: "Theme-toggle glyphs read as visibly fainter and smaller than the four social icons at rest, in both light and dark themes, at both call sites (footer + mobile drawer)"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "compiled-stylesheet grep: color-mix 75% neutral/base-200 present, .pk-theme-toggle button > span sized 14px (2 occurrences)"
        status: pass
    human_judgment: true
    rationale: "Visual weight/subordination relative to a sibling element and legibility across two themes is a perceptual judgment; the plan's own Task 2 designates this a human-check. Contrast ratios were computed and verified (3.22:1 light, 4.94:1 dark, both above the 3:1 floor), but the qualitative 'reads as clearly subordinate, not broken' call needs a human."
  - id: D2
    description: "Selected state (system/light/dark) remains unambiguous at a glance in both themes, underline carries the active signal in dark theme where the color tint is subtle"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "compiled-stylesheet grep: color-mix(in srgb, var(--color-primary) 65%, var(--color-neutral)) present exactly twice (active color + active underline background)"
        status: pass
    human_judgment: true
    rationale: "Whether the active state is 'unambiguously identifiable at a glance' is a perceptual judgment the plan's Task 2 explicitly routes to a human-check, particularly for dark theme where the tint alone is a weaker signal than the underline."
  - id: D3
    description: "Every glyph clears WCAG 2.1 SC 1.4.11 (3:1 non-text contrast) against its surface in both themes"
    requirement: "SHELL-01"
    verification:
      - kind: other
        ref: "planner-computed contrast math (planner_findings F6): 75% mix measures 3.22:1 against light footer surface (#F3ECFA) and 4.94:1 against dark footer surface (#22103A), both above the 3:1 floor"
        status: pass
    human_judgment: false
  - id: D4
    description: "Both call sites (.pk-footer-theme and .pk-drawer-utility) pick up the change identically via the shared theme_toggle/1 component and shared CSS block"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs (63 tests, 0 failures) — confirms both call sites render the same component with no markup change"
        status: pass
    human_judgment: false
  - id: D5
    description: "Touch targets, aria-labels, and phx-click behaviour unchanged (no markup or attribute edits)"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs, footer_overflow_test.exs, footer_rhythm_test.exs (63 tests total, 0 failures) — all pass unedited"
        status: pass
    human_judgment: false
  - id: D6
    description: "mix quality passes end to end"
    requirement: "SHELL-01"
    verification:
      - kind: other
        ref: "mix quality (hex.audit, deps.audit, deps.unlock --check-unused, format, credo --strict, sobelow, full test suite) — exit 0, 385 tests 0 failures"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-08-24
status: complete
---

# Quick Task 260824-7mt: Theme Toggle Subtlety (Sketch 018 Winner B) Summary

**Faded, shrunk, and toned the shared `.pk-theme-toggle` CSS block via `color-mix()` so the footer/drawer theme toggle reads as clearly subordinate to the social icons — shipping a WCAG-corrected 75% fade instead of the sketch's unmeasured 55%.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-08-24T08:28:00Z
- **Completed:** 2026-08-24T08:45:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- Rest-state glyph color faded to `color-mix(in srgb, var(--color-neutral) 75%, var(--color-base-200))`, correcting the sketch's 55% figure which failed WCAG 2.1 SC 1.4.11 (3:1 non-text contrast) in light theme
- Glyph size reduced to 14px via a `.pk-theme-toggle button > span` child-combinator rule, correctly targeting the mask-painted `<span>` heroicons actually render as (not the sketch's non-matching `button svg` selector)
- Active color and underline background toned from full `var(--color-primary)` to a 65% primary/neutral mix, applied identically across all three `[data-theme-source]` state selectors
- Added a hover rule restoring full `--color-base-content` for pointer feedback on the newly-faded control
- Recorded both measured divergences from the sketch's assumptions (75% vs 55% fade, 16px vs 14px social-icon baseline) in the sketch README's winner section

## Task Commits

Each task was committed atomically:

1. **Task 1: Apply variant B's three levers to the shared .pk-theme-toggle block** - `86998ab` (feat)
2. **Task 2: Verify no regression at either call site, in both themes, across all three states** - no file changes (verification-only task, `mix quality` passed)
3. **Task 3: Record the implementation against the sketch's winner section** - `c6d378b` (docs)

_Note: quick tasks route their docs commit through the orchestrator's Step 8, not through this SUMMARY._

## Files Created/Modified
- `assets/css/app.css` - Five declaration-level edits to `.pk-theme-toggle`: rest-color fade, child-span glyph size, hover rule, active-color tone, active-underline-background tone; extended the block's explanatory comment with the design rationale and both measured divergences
- `.planning/sketches/018-theme-toggle-subtlety/README.md` - Appended an "Implemented in quick-260824-7mt" note to the winner section documenting both divergences and the unchanged underline geometry

## Decisions Made
- Shipped 75% fade (not the sketch's 55%) — WCAG contrast floor requires it; see key-decisions in frontmatter
- Targeted `.pk-theme-toggle button > span` (not `button svg`) — hero icons are mask-painted spans, no svg exists in this control
- 14px glyph size ships as subordination rather than the parity the sketch's prose assumed, since social glyphs measured 16px in shipped markup, not the sketch's assumed 14px
- Left the active underline's geometry unchanged, recoloring only — variant B's absolute insets were measured on a 32px demo button, not the shipped 44px touch target

## Deviations from Plan

None - plan executed exactly as written. The plan's own `planner_findings` section had already corrected the divergences (75% vs 55% fade, span vs svg selector, 16px vs 14px social baseline) before execution began, so there was nothing left to auto-fix during implementation — every corrected value was applied as specified in the task actions.

## Issues Encountered

None. All five CSS declarations compiled and survived Tailwind processing on the first attempt (verified via the compiled-stylesheet grep gate in Task 1). `mix quality` passed on the first run (385 tests, 0 failures; the one pre-existing Credo suggestion and four pre-existing low-confidence Sobelow findings are on unrelated seed-import files, out of this task's scope).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The theme toggle's visual-hierarchy question raised during the `footer-desktop-imbalance` debug session is closed; sketch 018 is fully implemented.
- Task 2's human-check (visual confirmation across both themes, both call sites, all three states) was not performed via an interactive browser session in this execution — no browser automation tool was available. The automated gates (compiled-CSS grep, `mix quality`, all four toggle-referencing test files) all passed, and the contrast math was pre-verified by the planner (F6) to 3.22:1 light / 4.94:1 dark. The qualitative "reads as clearly subordinate, not broken" judgment (coverage D1/D2 above) is flagged `human_judgment: true` for a follow-up look, consistent with the plan's own Task 2 design.
- Underline-width-vs-14px-glyph is an explicitly flagged possible follow-up (plan's own note): if a human reviewer finds the underline now reads too wide beneath the smaller glyph, that is a new debug/sketch item, not a defect in this task.

---
*Phase: quick-260824-7mt*
*Completed: 2026-08-24*

## Self-Check: PASSED

- FOUND: `assets/css/app.css`
- FOUND: `.planning/sketches/018-theme-toggle-subtlety/README.md`
- FOUND: `.planning/quick/260824-7mt-implement-sketch-018-winner-variant-b-mu/260824-7mt-SUMMARY.md`
- FOUND: commit `86998ab` (feat: apply sketch 018 winner B)
- FOUND: commit `c6d378b` (docs: record sketch 018 implementation divergences)
