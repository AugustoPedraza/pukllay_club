---
phase: quick-260910-efe
plan: 01
subsystem: ui
tags: [css, daisyui, dark-mode, theme, contrast, accessibility, wcag]

# Dependency graph
requires:
  - phase: quick-260910-dev
    provides: "Sketch 054's validated dark-mode palette winner (A Lifted Ladder + W2 Deep Jewel), 5 base hypotheses + 3 primary-warmth candidates measured via a live WCAG oracle, developer-picked across two rounds"
provides:
  - "Sketch 054's winning dark daisyUI theme block shipped byte-exact in assets/css/app.css"
  - ".planning/sketches/themes/default.css re-synced to the new dark palette in both dark regions, zero drift"
  - "Dark-mode primary-as-text WCAG regression (17 rules, 6.00:1 -> 2.34:1) closed via a dark-scoped --color-neutral override (sketch 055, Option A)"
affects: [ui-design-system, sketch-findings-pukllay_club, dark-mode-theme]

# Actuals (#2632)
actuals:
  tokens: 4141
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dark-scoped CSS override for a broken-in-one-theme-only contrast pair: `[data-theme=\"dark\"] .selector, ... { color: var(--color-neutral); }` grouped across every affected selector in one rule, rather than touching each base rule or the palette token itself — same shape as the pre-existing `.pk-lightbox-close` dark-scoped fix."

key-files:
  created: []
  modified:
    - assets/css/app.css
    - .planning/sketches/themes/default.css
    - test/pukllay_club_web/live/catalog_show_test.exs

key-decisions:
  - "Task 3 checkpoint (blocking-human decision): dark-mode primary-as-text regression resolved via Option A (dark-scoped text token), reusing the existing --color-neutral token (7.00:1 on --color-base-100) rather than inventing a new token, revisiting the winning palette, or re-scoping the WCAG gate. Validated via sketch 055 (variant A2) against all 17 real affected elements side by side; active-nav-link 'you are here' states remain legible through weight/underline/left-border, not colour alone."
  - "catalog_show_test.exs's .pk-pill-tag contrast test rewritten to measure what the selector actually renders per theme (--color-primary in light, the new dark-scoped --color-neutral override in dark) instead of a hardcoded --color-primary-vs-both-themes comparison that Option A's architecture made structurally false; the 4.5:1 WCAG floor itself was not touched."

patterns-established:
  - "When a shared token breaks a single specific usage (text) in one theme while still serving other usages (fill/border) correctly, prefer a dark-scoped override on the specific selectors over changing the token globally — keeps the token's other 90% of usages and the developer's validated palette decision untouched."

requirements-completed: [SKETCH-054]

coverage:
  - id: D1
    description: "Sketch 054's winning dark palette (8 tokens: base-100/200/300, primary, primary-content, secondary, accent, accent-content) ships byte-exact in assets/css/app.css's dark daisyUI theme block; light theme and the 4 unrelated preserved dark tokens are untouched"
    requirement: SKETCH-054
    verification:
      - kind: other
        ref: "awk-scoped grep over the dark theme block confirming all 8 winner values + 4 preserved tokens present, and the light block's own --color-primary: #3D096D unchanged (Task 1 <verify>)"
        status: pass
    human_judgment: false
  - id: D2
    description: ".planning/sketches/themes/default.css re-synced to the new dark palette in both dark regions (prefers-color-scheme media query and explicit data-theme selector), zero drift against app.css or between the two regions"
    requirement: SKETCH-054
    verification:
      - kind: other
        ref: ".planning/sketches/themes/check-theme-drift.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "Dark-mode primary-as-text WCAG contrast regression (17 rules, 2.34:1) closed via a dark-scoped --color-neutral override; mix quality passes end to end including every WCAG contrast gate that reads the dark theme block; none of the 8 hex values from Task 1 were changed; no WCAG assertion was weakened, skipped, or deleted"
    requirement: SKETCH-054
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#.pk-pill-tag's text meets the 4.5:1 contrast floor in both themes (sketch 055 dark-scoped override)"
        status: pass
      - kind: other
        ref: "mix quality (903 tests, 0 failures; hex.audit, deps.audit, format, credo --strict, sobelow, test all green)"
        status: pass
    human_judgment: false
  - id: D4
    description: "In-file comments that stated a now-false hex or measured ratio for a changed token were reconciled to the real current values (brand-manual note, Maps dark-filter tuning note, title-echo bar note, lightbox-close contrast note, .pk-pill-tag tripwire note)"
    verification:
      - kind: other
        ref: "grep -n '#22103A\\|#170A26' assets/css/app.css confirms only the two deliberately-unchanged sites remain (the 5 *-content ink literals and the .pk-lightbox-close comment's own historical dark-lightbox numbers, which were separately updated to #391B62/1.39:1 as part of Task 1)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Live spot-check of the running app in dark mode at / and /quienes-somos: the ground reads visibly lifted, the CTA button carries the deeper magenta-violet with white label text, and no text has become hard to read (including the 17 rules dark-scoped to --color-neutral)"
    verification: []
    human_judgment: true
    rationale: "Requires a human eyeballing the live composed page in a real browser — automated contrast math confirms the numeric floor but not that the overall composition reads as intended (this is exactly the class of check sketch 054/055 already ran as live human-directed rounds, not something an automated assertion can stand in for)."

# Metrics
duration: 57min
completed: 2026-09-10
status: complete
---

# Quick Task 260910-efe: Ship Sketch 054's Dark Theme Winner Summary

**Shipped sketch 054's winning dark daisyUI palette (lifted base ladder + deep-jewel primary) into `assets/css/app.css`, then closed the one gap the sketch never measured — primary-as-text contrast — via a developer-directed dark-scoped `--color-neutral` override across 17 rules.**

## Performance

- **Duration:** 57 min
- **Started:** 2026-09-10T13:37:53Z
- **Completed:** 2026-09-10T14:34:28Z (Task 3 implementation) / ~14:35Z (summary + ledger)
- **Tasks:** 3 (2 `type="auto"` + 1 `type="checkpoint:decision"`)
- **Files modified:** 3 (`assets/css/app.css`, `.planning/sketches/themes/default.css`, `test/pukllay_club_web/live/catalog_show_test.exs`)

## Accomplishments

- Shipped sketch 054's 8-token winning dark palette (base ladder lifted `#170A26/#22103A/#2F1750` -> `#2F154E/#391B62/#462278`; primary deepened `#A97FD1` -> `#8C2BB6` with white ink) byte-exact into `assets/css/app.css`'s dark daisyUI theme block, light theme untouched
- Re-synced `.planning/sketches/themes/default.css`'s two dark regions to match, zero drift confirmed by `check-theme-drift.sh` (39/39 pair checks OK)
- Resolved the dark-mode primary-as-text WCAG regression the sketch's own objective flagged in advance (17 rules, 2.34:1, tripwire `catalog_show_test.exs:4316`) via a developer-chosen dark-scoped `--color-neutral` override, reusing an existing token rather than reopening the two-round palette decision
- `mix quality` passes end to end (903 tests, 0 failures) with the WCAG floor intact and unweakened

## Task Commits

Each task was committed atomically:

1. **Task 1: Apply sketch 054's winner to app.css's dark theme block** - `5fa7c96` (feat)
2. **Task 2: Re-sync the sketch theme mirror and prove zero drift** - `e551eb0` (feat)
3. **Task 3: Decide how to resolve the dark-mode primary-as-text contrast regression** - `4de535c` (fix)

_Task 3 required a blocking-human checkpoint mid-execution: evidence (the live test failure text and a 17-rule grep count) was gathered and presented with the plan's four options verbatim; the developer's decision (Option A, `--color-neutral`) arrived via the orchestrator before implementation continued._

## Files Created/Modified

- `assets/css/app.css` - Dark daisyUI theme block's 8 colour declarations updated to sketch 054's winner; sketch-054 provenance comment added; 4 stale in-file comments reconciled to real hex/ratios; new dark-scoped `[data-theme="dark"] <17 selectors> { color: var(--color-neutral); }` override rule + rationale comment added after `.pk-pill-tag:hover`; `.pk-pill-tag`'s tripwire comment updated to record the full history (old ratio, new failure, chosen fix)
- `.planning/sketches/themes/default.css` - Both dark regions (media-query + explicit `data-theme="dark"`) re-synced to the same 9 sketch-054 token changes; provenance comment extended with the 2026-09-10 re-derivation note
- `test/pukllay_club_web/live/catalog_show_test.exs` - `.pk-pill-tag` contrast test rewritten to measure the actually-rendered text ink per theme (light: `--color-primary`; dark: the new dark-scoped `--color-neutral` override, structurally confirmed present) instead of a hardcoded token-pair comparison that Option A's architecture made false; new `dark_pill_tag_text_override_block/0` helper mirrors the existing `dark_lightbox_close_block/0` idiom

## Decisions Made

- **Task 3 (developer, via checkpoint):** Chose Option A — dark-scoped text token, specifically reuse `--color-neutral` (`#B8A6CC`, 7.00:1 on `--color-base-100`) rather than adding a new token (Option B), revisiting the winning primary (Option C), or re-scoping the WCAG gate (Option D). Reasoning: keeps the winning palette byte-exact (no reopening the two-round sketch 054 decision), `--color-neutral` is already the file's existing muted/quiet ink used for the same purpose elsewhere (`.pk-lightbox-close`'s own dark-scoped fix), and no changes to `default.css`'s mapping table or `check-theme-drift.sh`'s pair list were required since the token is already mapped and gated. Validated via sketch 055 (variant A2) against all 17 real affected elements side by side before implementation; "you are here" active-nav-link states remain legible through weight/underline/left-border, not colour alone.
- **Test correction (executor, Rule 1 auto-fix within Task 3):** The pre-existing `.pk-pill-tag` contrast test compared the raw `--color-primary`/`--color-base-100` token pair in both themes — a premise Option A's architecture made structurally false for dark (dark's actual rendered ink is now `--color-neutral` via the override, not `--color-primary`). Rewrote it to measure what each theme actually paints, keeping the 4.5:1 floor exactly as it was (not weakened, skipped, or deleted, per the developer's explicit instruction that it "must pass for real").

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `.pk-pill-tag` WCAG test measured the wrong thing after Option A shipped**
- **Found during:** Task 3, first `mix quality` run after implementing the dark-scoped override
- **Issue:** `catalog_show_test.exs:4316` asserted `--color-primary` vs `--color-base-100` >= 4.5:1 in both themes. This was accurate when both themes rendered `.pk-pill-tag`'s text directly from `--color-primary`, but Option A's dark-scoped override means dark no longer does that — the test kept failing at 2.34:1 even though `.pk-pill-tag` now correctly renders `--color-neutral` (7.00:1) in dark.
- **Fix:** Rewrote the test to resolve the actually-rendered ink per theme: light still checks `--color-primary`; dark structurally confirms the dark-scoped override sets `color: var(--color-neutral)` and then measures that token's contrast. The 4.5:1 floor is unchanged.
- **Files modified:** `test/pukllay_club_web/live/catalog_show_test.exs`
- **Verification:** `mix test test/pukllay_club_web/live/catalog_show_test.exs` — 181 tests, 0 failures; full `mix quality` — 903 tests, 0 failures
- **Committed in:** `4de535c` (Task 3 commit)

**2. [Rule 3 - Blocking] New test name exceeded ExUnit's 255-character computed-name limit**
- **Found during:** Task 3, compiling the rewritten test
- **Issue:** The first descriptive test name (`describe` prefix + full test string) exceeded ExUnit's `validate_test_name/1` 255-character ceiling, failing compilation with `SystemLimitError`.
- **Fix:** Shortened the test name while keeping it descriptive of the mechanism (`.pk-pill-tag's text meets the 4.5:1 contrast floor in both themes (sketch 055 dark-scoped override)`).
- **Files modified:** `test/pukllay_club_web/live/catalog_show_test.exs`
- **Verification:** `mix test` compiles and runs clean
- **Committed in:** `4de535c` (Task 3 commit, same edit as deviation 1)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking) — both localized to the one test the architecture change required correcting.
**Impact on plan:** Necessary to satisfy the developer's explicit "must pass for real, not weakened" instruction for Task 3's `<verify>`. No scope creep — no other test files touched, no unrelated CSS rules modified. Logged to `.planning/WINDOWS.md` (entry #25, kind `deviation`) per the broken-windows ledger convention.

## Issues Encountered

- Dependencies were not yet fetched in this worktree (`mix deps.get` was required before any `mix test`/`mix quality` run could compile). Standard `mix.lock`-pinned resolution, not a Rule 3 package-legitimacy concern (no new/unvetted package names involved).
- `mix format` on the rewritten test file contended briefly with a concurrent BEAM build-directory lock from an earlier `mix test` invocation; resolved by waiting for the lock holder to exit, then re-running `mix format --check-formatted` cleanly (exit 0).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Sketch 054's dark theme is fully shipped and the primary-as-text regression it exposed is closed with no outstanding WCAG debt.
- **Open note for the next palette retune:** the five `*-content` ink literals (`--color-neutral-content`, `--color-info-content`, `--color-success-content`, `--color-warning-content`, `--color-error-content`) were deliberately left on their old value (`#170A26`, the OLD `--color-base-100`) rather than following the new ladder to `#2F154E`. These are ink-on-coloured-chip literals, not references to the page ground, and sketch 054's 13-token table did not map them — leaving them alone also keeps the neutral-content/neutral gate at its verified 8.45:1. A future retune that touches these five should re-verify their own contrast pairs explicitly rather than assuming they track the base ladder.
- D5 (live dark-mode spot-check at `/` and `/quienes-somos`) is deferred to end-of-phase human UAT per this project's `human_verify_mode: end-of-phase` convention — not a blocker, consistent with how prior quick tasks in this phase (e.g. 260902-fdm, 260902-il3) have handled visual-only checks.

---
*Phase: quick-260910-efe*
*Completed: 2026-09-10*

## Self-Check: PASSED

All referenced files confirmed present on disk (`assets/css/app.css`, `.planning/sketches/themes/default.css`, `test/pukllay_club_web/live/catalog_show_test.exs`, this SUMMARY.md) and all three task commits confirmed present in `git log --oneline --all` (`5fa7c96`, `e551eb0`, `4de535c`).
