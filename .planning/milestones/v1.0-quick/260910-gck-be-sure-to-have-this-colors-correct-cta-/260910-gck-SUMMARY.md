---
phase: quick-260910-gck
plan: 01
subsystem: ui
tags: [css, daisyui, wcag, contrast, dark-mode, accessibility]

# Dependency graph
requires:
  - phase: quick-260910-efe
    provides: sketch 054's shipped dark theme palette + sketch 055's dark-scoped ink-swap mechanism (--color-neutral) for 17 primary-as-text rules
provides:
  - Dark-mode outline-primary CTA contrast fix (WCAG 1.4.3/1.4.11) split by role — Sumate CTA (hero + closing band) solid-fills; .pk-preview-cta and the "Reintentar" secondary button ink-swap to --color-neutral
  - .pk-btn-secondary class hook on core_components.ex's "secondary" button variant, giving CSS a direct target instead of daisyUI's raw class combination
  - Regression test coverage in catalog_show_test.exs's existing dark-theme contrast harness (4 new tests, tripwire-verified)
affects: [about-page-dark-mode, catalog-detail-dark-mode, future-cta-contrast-work]

actuals:
  tokens: 15500
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Dark-scoped CTA role split: primary CTA gets a solid-fill override, secondary CTAs get an ink-swap override — two different dark-scoped mechanisms for two different visual-hierarchy roles, chosen at a blocking developer checkpoint from measured evidence rather than applied mechanically"
    - "CSS hook classes for shared component variants: when a shared component (core_components.ex's button/1) produces no distinguishing class for a CSS-only fix to target, add one to the variant map rather than selecting on the raw daisyUI class combination (which also matches unrelated call sites)"

key-files:
  created:
    - .planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md
  modified:
    - assets/css/app.css
    - lib/pukllay_club_web/components/core_components.ex
    - test/pukllay_club_web/live/catalog_show_test.exs

key-decisions:
  - "Developer chose Option D (split-by-role), validated via sketch 056 against all 4 real affected elements: Sumate (hero + closing band, the site's actual primary CTA) keeps full brand-primary visibility via a dark-scoped solid fill reusing the already-proven .pk-sumate-btn-solid pair (6.70:1); the genuinely secondary CTAs (.pk-preview-cta, the Reintentar retry button) take sketch 055's established --color-neutral ink-swap mechanism (7.00:1/6.21:1)"
  - "Added a .pk-btn-secondary class hook to core_components.ex's 'secondary' variant string rather than selecting on daisyUI's raw btn-outline/btn-primary class combination, since that combination also matches .pk-sumate-btn and would require a fragile :not() exclusion"

patterns-established:
  - "Pattern: CSS provenance comments record which measured evidence artifact backed a fix (260910-gck-EVIDENCE.md), matching this file's existing convention of citing the sketch/plan that produced a decision"

requirements-completed: [QUICK-260910-GCK]

coverage:
  - id: D1
    description: "Dark-mode Sumate CTA (hero + closing band) solid-fills to --color-primary background / --color-primary-content text (6.70:1), clearing both the 4.5:1 WCAG 1.4.3 floor and the 3:1 1.4.11 floor"
    requirement: "QUICK-260910-GCK"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#dark-mode Sumate CTA solid-fills to the primary/primary-content pair (260910-gck)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Sumate solid-fill rule excludes the mobile sticky bar (.pk-sumate-btn-solid) so it is not re-declared by a competing rule"
    requirement: "QUICK-260910-GCK"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#dark-mode Sumate solid-fill excludes the sticky bar (not re-declared, 260910-gck)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Dark-mode secondary CTAs (.pk-preview-cta, .pk-btn-secondary / the Reintentar retry button) ink-swap to --color-neutral, clearing both the 4.5:1 text and 3:1 border floors on both base-100 and base-200 grounds"
    requirement: "QUICK-260910-GCK"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#dark-mode secondary CTAs ink-swap to --color-neutral, clearing both floors (260910-gck)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Light theme's outline-primary CTAs remain untouched by the dark-only fix (still 14.4:1, base .pk-sumate-btn declares no color/background)"
    requirement: "QUICK-260910-GCK"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#light theme's outline-primary CTAs are untouched by the dark-mode fix (260910-gck)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Visual confirmation that the split-by-role treatment (solid Sumate + neutral-ink secondary CTAs) reads correctly across all 4 real affected placements in dark mode"
    verification: []
    human_judgment: true
    rationale: "The developer already visually validated this via sketch 056 (side-by-side comparison of all 4 real affected elements) before choosing Option D at the Task 2 checkpoint — this is a taste/visual-hierarchy confirmation the numbers alone can't settle, consistent with why the plan routed this decision to a human checkpoint in the first place rather than auto-selecting."

duration: 24min
completed: 2026-09-10
status: complete
---

# Quick Task 260910-gck: Dark-mode Outline-primary CTA Contrast Summary

**Split-by-role dark-mode WCAG fix: Sumate CTA solid-fills to primary/primary-content (6.70:1), secondary CTAs (.pk-preview-cta, Reintentar) ink-swap to --color-neutral (7.00:1/6.21:1) — closing the last open dark-mode contrast debt from the sketch 054 palette ship**

## Performance

- **Duration:** 24 min
- **Started:** 2026-09-10T11:57:46-03:00
- **Completed:** 2026-09-10T12:21:37-03:00
- **Tasks:** 3 (Task 1: evidence gathering, Task 2: blocking developer checkpoint, Task 3: implementation + tests)
- **Files modified:** 3 (+1 evidence artifact created)

## Accomplishments

- Measured and documented (260910-gck-EVIDENCE.md) that daisyUI's `btn-outline btn-primary` resolves both label `color` and `border-color` to `--color-primary` (#8C2BB6) with a transparent background — failing both the 4.5:1 WCAG 1.4.3 text floor and the 3:1 1.4.11 border floor on every affected dark-mode placement (2.34:1 on base-100, 2.08:1 on base-200)
- Presented the evidence at a blocking developer checkpoint (Task 2); the developer chose Option D ("split-by-role"), validated visually via sketch 056 against all 4 real affected elements
- Implemented the split-by-role fix: Sumate (hero + closing band) gets a dark-scoped solid fill reusing the exact pair already proven on the mobile sticky bar; `.pk-preview-cta` and the "Reintentar" secondary button get the sketch-055 ink-swap mechanism to `--color-neutral`, covering both `color` and `border-color`
- Added a `.pk-btn-secondary` class hook to `core_components.ex`'s `"secondary"` button variant so the CSS fix has an explicit, unambiguous target
- Added 4 regression tests reusing the existing dark-theme contrast harness in `catalog_show_test.exs`; verified the tripwire is real by temporarily reverting the CSS and confirming 3/4 tests fail
- `mix quality` passes end to end (907 tests, 0 failures); `check-theme-drift.sh` exits 0; no `@plugin "daisyui-theme"` token value was touched

## Task Commits

Each task was committed atomically:

1. **Task 1: Measure every affected CTA surface and write the evidence artifact** - `6f20334` (docs)
2. **Task 2: Developer decides how to fix the dark-mode CTA contrast** - checkpoint only, no code changes; developer chose Option D (split-by-role) via sketch 056
3. **Task 3: Implement the chosen fix and pin it with a regression test** - `d762448` (fix)

_Note: This is a quick task, not a standard phase plan — Task 2 is a `checkpoint:decision` with no commit of its own, and the final plan-metadata commit (SUMMARY.md/STATE.md) is made separately by the orchestrator, per this workflow's constraints._

## Files Created/Modified

- `.planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md` - Verified call-site inventory, daisyUI resolution proof, WCAG-role floor verdicts, and the full contrast ratio matrix that backed the Task 2 checkpoint
- `assets/css/app.css` - Two new dark-scoped rules: `[data-theme="dark"] .pk-sumate-btn:not(.pk-sumate-btn-solid)` (solid fill + hover) and `[data-theme="dark"] .pk-preview-cta, [data-theme="dark"] .pk-btn-secondary` (ink-swap); updated `.pk-sumate-btn`'s own comment to record the dark-mode divergence
- `lib/pukllay_club_web/components/core_components.ex` - Added `.pk-btn-secondary` to the `"secondary"` button variant's class string
- `test/pukllay_club_web/live/catalog_show_test.exs` - 4 new tests in the `"01.3-07 net-new CSS-source pins"` describe block, reusing `css_source/0`, `dark_theme_plugin_block/0`, `light_theme_plugin_block/0`, `token_value/2`, `relative_luminance/1`, `contrast_ratio/2`

## Decisions Made

- **Developer chose Option D (split-by-role)** at the Task 2 blocking checkpoint, validated via sketch 056 against all 4 real affected elements (hero, closing band, preview card, retry banner) before the pick: Sumate keeps brand-primary prominence via a solid fill (matching the site's actual primary-CTA hierarchy); the genuinely secondary CTAs take the quieter, already-established neutral ink.
- **Reused the existing `.pk-sumate-btn-solid` mechanism** for the Sumate fill rather than inventing new CSS — the developer's message explicitly directed re-verifying whether the existing modifier class or a new dark-scoped rule was cleaner; a new dark-scoped rule (`:not(.pk-sumate-btn-solid)`) was chosen because directly applying the existing unscoped `.pk-sumate-btn-solid` class to the hero/closing-band call sites would have changed their LIGHT-mode appearance too, which was explicitly out of scope (dark-mode-only fix).
- **Added a `.pk-btn-secondary` class hook to `core_components.ex`** instead of selecting on daisyUI's raw `btn-outline btn-primary` class combination — that combination also matches `.pk-sumate-btn` (both carry the same two daisyUI classes), which would have required a fragile `:not()` exclusion in the CSS selector instead of an explicit, readable hook. Verified the existing `core_components_test.exs` "secondary" variant tests (substring assertions, not exact-string matches) still pass with the added class.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - anticipated by plan, not unilateral] Added `.pk-btn-secondary` class to `core_components.ex`'s shared `button/1` component**
- **Found during:** Task 3 (implementation)
- **Issue:** `core_components.ex`'s `variant="secondary"` produces bare `btn btn-outline btn-primary` with no `.pk-*` hook for the CSS fix to target directly. The plan's own `<action>` explicitly anticipated this exact call: "decide between adding a `.pk-*` class to that variant string in `core_components.ex` and targeting daisyUI's own class combination in the selector, and record in the rule comment which you chose and why."
- **Fix:** Added `.pk-btn-secondary` to the `"secondary"` variant's class string, documented the choice inline in `core_components.ex` and in the app.css provenance comment.
- **Files modified:** `lib/pukllay_club_web/components/core_components.ex` (not in Task 3's originally-listed `<files>`, but the plan's own `<action>` text explicitly sanctioned this edit as one of the two valid implementation paths)
- **Verification:** `test/pukllay_club_web/components/core_components_test.exs`'s existing `"secondary"` variant tests (substring assertions on `"btn-outline"`/`"btn-primary"`, not exact-string matches) still pass unmodified; confirmed as part of the full `mix quality` test run (907 tests, 0 failures).
- **Committed in:** `d762448` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (plan-anticipated component edit, not a scope violation — Rule 2/plan-sanctioned)
**Impact on plan:** None beyond what the plan itself already flagged as a required implementation decision. No scope creep.

## Issues Encountered

- `mix format --check-formatted` initially failed on the new test file (Styler wanted `~s()` instead of an escaped-quote string literal in one `flunk/1` message). Fixed by running `mix format`; reviewed the resulting diff per CLAUDE.md's Styler guidance — the rewrite was a pure string-literal-style change with no semantic difference. Re-ran the full test suite and `mix quality` after the fix; both pass.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The last open dark-mode WCAG contrast debt from the sketch 054 palette ship is now closed. No known dark-mode CTA renders `--color-primary` as failing text or border ink.
- `260910-gck-EVIDENCE.md` documents the full measured baseline (call-site inventory, daisyUI resolution proof, contrast matrix) — reusable reference if the palette or button system changes again in the future.
- No blockers for future work. Any future palette retune will re-trip the 4 new regression tests if it regresses either the Sumate solid-fill pair or the secondary-CTA neutral ink.

---
*Phase: quick-260910-gck*
*Completed: 2026-09-10*
