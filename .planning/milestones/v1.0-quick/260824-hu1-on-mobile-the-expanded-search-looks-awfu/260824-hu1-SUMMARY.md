---
phase: quick-260824-hu1
plan: 01
subsystem: ui
tags: [css, header, search, layout, mobile, gutter, alignment]

# Dependency graph
requires:
  - phase: 01.1-08 (search-morph)
    provides: ".pk-search-morph icon-to-pill morph and its --pk-gutter-driven narrow-viewport overlay"
provides:
  - "A ≤480px open search box whose own edges (background/border/shadow), not just its contents, sit on the shared .pk-gutter alignment line"
  - "A comment-immune regression guard (header_search_gutter_test.exs) pinning the inset/padding/border-radius contract"
affects: [header, mobile-search, gutter-alignment]

# Actuals (#2632) — chars/4 over the realized diff, not a harness token count.
actuals:
  tokens: 2600
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Positional-inset gutter alignment: an absolutely-positioned overlay's horizontal inset is expressed as `inset: 0 var(--pk-gutter)` (two-value shorthand) rather than a zero-inset box compensated by inner padding — this makes the box's own edges (not just its contents) track the shared gutter token."

key-files:
  created:
    - test/pukllay_club_web/header_search_gutter_test.exs
  modified:
    - assets/css/app.css

key-decisions:
  - "Fixed via the inset shorthand's horizontal component (`inset: 0 var(--pk-gutter)`) rather than four separate left/right/top/bottom declarations — keeps the rule as terse as the original while making the token the single owner of horizontal placement."
  - "Deleted (not retuned) the compensating padding-inline, border-radius override, and toggle padding-left override rather than adjusting their values — the plan's diagnosis established these existed only to fake what position: absolute + inset now does for real, so removing them (letting the base rule's declarations win) was correct, not a workaround."

patterns-established:
  - "Comment-stripped source-assertion CSS guards (strip_comments/1 + block!/2 + narrow_viewport_block/1) are this repo's established pattern for pinning header/footer geometry contracts ExUnit cannot observe directly (header_row_height_test.exs, footer_rhythm_test.exs, and now header_search_gutter_test.exs)."

requirements-completed: [SHELL-01, SHELL-04]

coverage:
  - id: D1
    description: "The ≤480px open search box's own inset (background/border/shadow) tracks var(--pk-gutter) instead of a zero-inset shorthand that lands on the viewport edge; the compensating inner padding, the bottom-only border-radius override, and the toggle's zeroed left padding are removed so the base rules (fully-rounded pill, base glyph padding) are the single owners again."
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/header_search_gutter_test.exs (6 tests: inset token, no fake padding, no border-radius override, no toggle padding override, base pill radius intact, --pk-gutter retune intact)"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/header_row_height_test.exs, test/pukllay_club_web/stylesheet_integrity_test.exs, test/pukllay_club_web/components/layouts_test.exs (neighbouring header/stylesheet suites, unaffected)"
        status: pass
      - kind: automated_ui
        ref: "raw CDP against a live headless Chromium at http://localhost:4000/, 390px viewport: getBoundingClientRect() on .pk-search-morph.is-open vs .pk-nav-inner's padding-box edge — morphLeft=14/morphRight=376 vs gutterLeft=14/gutterRight=376 (exact match); borderRadius=9999px"
        status: pass
    human_judgment: false
  - id: D2
    description: "The >480px desktop/tablet search pill is unchanged: static flow, 17.5rem (280px) open width, right-anchored via margin-left: auto — not affected by the narrow-viewport-only fix."
    requirement: "SHELL-04"
    verification:
      - kind: automated_ui
        ref: "raw CDP at 640px viewport: position=relative, width=280px, right=608 (= 640 - 2*32px gutter), marginLeft=45.6875px (auto-resolved)"
        status: pass
      - kind: other
        ref: "git diff assets/css/app.css confined to the trailing @media (max-width: 480px) block; git status shows no change under lib/"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-08-24
status: complete
---

# Quick Task 260824-hu1: Align Open Mobile Search Box to the Shared Gutter Summary

**Fixed a zero-inset `.pk-search-morph.is-open` overlay that resolved against `.pk-nav-inner`'s containing-block padding edge (the viewport edge at ≤480px) instead of the page's shared `.pk-gutter` line — switched its inset to `var(--pk-gutter)`, removed the now-redundant compensating padding and shape overrides, and pinned the contract with a comment-immune regression guard.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-08-24T12:55Z (approx.)
- **Completed:** 2026-08-24T16:04Z
- **Tasks:** 2
- **Files modified:** 2 (1 test, 1 css)

## Accomplishments

- Diagnosed and fixed the root cause exactly as the plan's diagnosis predicted: `.pk-search-morph.is-open`'s `inset: 0` resolved against `.pk-nav-inner`'s containing-block PADDING edge, which at ≤480px is the viewport edge, stepping over `.pk-gutter` entirely.
- Wrote a TDD RED guard first (`header_search_gutter_test.exs`) and confirmed 4 of 6 assertions failed against the pre-fix stylesheet before touching any CSS.
- Landed a 4-line CSS correction confined to the trailing `@media (max-width: 480px)` block: `inset: 0` → `inset: 0 var(--pk-gutter)`, and three now-redundant declarations deleted (`padding-inline`, the bottom-only `border-radius` override, and the toggle's `padding-left: 0` override) so the base rules' fully-rounded pill and glyph padding are single owners again.
- Verified live in a real headless Chromium via raw CDP (no npm deps, matching quick task 260824-eqc's precedent): at 390px the open box's left/right edges (14px / 376px) exactly match `.pk-nav-inner`'s gutter-aligned padding-box edges (14px / 376px), and `border-radius` computes to `9999px` (fully rounded pill). At 640px the desktop path is provably untouched: `position: relative`, `width: 280px` (17.5rem), right-anchored via `margin-left: auto`.
- `mix quality` passed end to end (hex.audit, deps.audit, deps.unlock --check-unused, format/Styler, credo --strict, sobelow, 421 tests) with zero Styler-produced rewrites (clean `git status` after the run).

## Task Commits

Each task was committed atomically:

1. **Task 1: Align the open mobile search box to the shared gutter line** - `f12897c` (test, RED guard) + `0fcc255` (feat, GREEN fix)
2. **Task 2: Confirm the fix in a real browser at both sides of the breakpoint and run the full quality gate** - verification-only, no code changes; nothing to commit beyond Task 1's two commits

**Plan metadata:** not committed by this executor — orchestrator handles the docs commit separately per this quick task's own instructions.

_Note: Task 1 was `type="tracer" tdd="true"` — the RED test commit (`f12897c`) and the GREEN CSS-fix commit (`0fcc255`) are the two halves of that TDD cycle. No REFACTOR commit was needed (the fix was already minimal)._

## Files Created/Modified

- `test/pukllay_club_web/header_search_gutter_test.exs` - new regression guard (6 tests) pinning: the open morph's inset horizontal component reads `var(--pk-gutter)`; no horizontal padding is re-declared on the open box; no `border-radius` override on the open box; no `padding-left` override on the open toggle; the base `.pk-search-morph` rule still owns `border-radius: 9999px`; the narrow-viewport block still retunes `--pk-gutter: 0.875rem`. Follows the `strip_comments/1` + `block!/2` + `narrow_viewport_block/1` pattern established by `header_row_height_test.exs` / `footer_rhythm_test.exs`.
- `assets/css/app.css` - `.pk-search-morph.is-open` inside the trailing `@media (max-width: 480px)` block: `inset: 0` → `inset: 0 var(--pk-gutter)`; `padding-inline: var(--pk-gutter)` deleted; `border-radius: 0 0 var(--radius-box) var(--radius-box)` deleted; the sibling `.pk-search-morph.is-open .pk-search-morph-toggle { padding-left: 0; }` rule deleted; leading comment rewritten to describe the gutter-aligned-overlay-pill contract (superseding sketch 017 Round 5's full-bleed sheet).

## Decisions Made

- Used the `inset` shorthand's horizontal component (`inset: 0 var(--pk-gutter)`) rather than four separate `top`/`right`/`bottom`/`left` declarations — matches the original rule's terseness while making the token the single owner of horizontal placement.
- Deleted (rather than retuned) the compensating `padding-inline`, the bottom-only `border-radius` override, and the toggle's `padding-left: 0` override. The plan's diagnosis established all three existed only to fake, at the content/shape level, what a genuine gutter-aligned `position: absolute` + `inset` now does at the box level — so removing them and letting the base rules (`border-radius: 9999px`, the base open-state toggle padding) win by cascade is the fix, not a partial step toward one.

## Deviations from Plan

None - plan executed exactly as written. Both the diagnosis and the prescribed fix (steps 1-5 of Task 1's `<action>`) matched the actual codebase state precisely; no auto-fixes, no architectural questions, no scope changes.

## Issues Encountered

- The default dev port (4000) had an existing `mix phx.server` instance already running (started earlier in this session, PID 1133757, live since well before this task began) with its esbuild/tailwind watchers active. Starting a second instance failed with `:eaddrinuse`; used the already-running instance instead — confirmed `priv/static/assets/css/app.css` had already picked up the CSS fix live (watcher rebuild) before driving the CDP measurements against it. No new server was started or left running by this task.
- A headless Chromium instance (`chromium --headless --remote-debugging-port=9333`) was started for the CDP measurements and killed immediately after Task 2's verification completed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 2 (Natural-Language Spanish Search + Auth) remains the project's next planned phase; this quick task did not touch anything on its critical path.
- The `.pk-search-morph` narrow-viewport rule is now a clean single-owner state (position + inset + width/height/z-index/box-shadow only), so any future mobile-header change should extend that rule rather than reintroduce a competing padding/radius override.

---
*Phase: quick-260824-hu1*
*Completed: 2026-08-24*

## Self-Check: PASSED

- FOUND: test/pukllay_club_web/header_search_gutter_test.exs
- FOUND: assets/css/app.css (modified)
- FOUND commit: f12897c (test: RED guard)
- FOUND commit: 0fcc255 (feat: GREEN fix)
