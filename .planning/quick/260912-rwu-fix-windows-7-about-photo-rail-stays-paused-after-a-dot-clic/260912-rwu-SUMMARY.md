---
phase: quick-260912-rwu
plan: 01
subsystem: ui
tags: [liveview, colocated-hook, javascript, carousel, autoplay, about-page]

requires:
  - phase: quick-260912 (browser-verification session, waived WINDOWS entries)
    provides: the diagnosed root cause in .planning/debug/about-rail-dot-click-pause.md
provides:
  - "A shared this.pauseThenResume helper in the .AboutCarousel LiveView hook, called from both onClick (dot activation) and onPointerDown (rail swipe)"
  - "A source-contract ExUnit regression gate (about_carousel_hook_test.exs) pinning the hook's pause/resume structure"
  - "Resolved debug session at .planning/debug/resolved/about-rail-dot-click-pause.md"
affects: [about_live, windows-tracking]

actuals:
  tokens: 5585
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "One shared pause-then-resume helper called from every interaction path that can pause a client-side autoplay carousel, instead of each handler managing its own paused/timer state"
    - "Out-of-tree Node execution of a colocated hook's real <script> source (extracted verbatim), mounted against a minimal DOM stub with real event bubbling and fake timers, as an executor-only proof of client-side timer behavior ExUnit cannot exercise"

key-files:
  created:
    - test/pukllay_club_web/about_carousel_hook_test.exs
  modified:
    - lib/pukllay_club_web/live/about_live.ex
    - .planning/debug/resolved/about-rail-dot-click-pause.md (moved from .planning/debug/, status flipped to resolved)

key-decisions:
  - "Kept onPointerDown registered on this.rail (not moved to this.el) — the rail stays the swipe/hover surface; dots are fully covered by the click path for every input modality (tap, mouse click, keyboard Enter/Space)."
  - "mouseenter/mouseleave stayed unchanged on this.rail; mouseenter's existing clearTimeout(this.resumeTimer) call already satisfies the 'resting mouse must not resume out from under a pending dot-click timer' requirement, so no new hover flag or guard was added."

requirements-completed: []

coverage:
  - id: D1
    description: "Tapping, clicking, or keyboard-pressing an About photo-rail dot pauses auto-advance, which resumes ~6s after the last interaction (WINDOWS #7 fixed)"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/about_carousel_hook_test.exs (15 tests, all describe blocks)"
        status: pass
      - kind: other
        ref: "out-of-tree Node execution (K1-K5) of the real fixed hook source, scratchpad-only, never committed"
        status: pass
    human_judgment: true
    rationale: "No live browser re-check at a real 390px viewport was performed in this run (out of scope for this quick item) — a human should confirm the fix visually before flipping WINDOWS.md entry #7 to fixed."

duration: ~20min
completed: 2026-09-12
status: complete
---

# Quick 260912-rwu: About photo-rail dot-click resume Summary

**Shared `pauseThenResume` helper in the `.AboutCarousel` LiveView hook so dot taps, keyboard dot presses, and rail swipes all arm the same 6s autoplay-resume timer, closing WINDOWS #7.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-12T20:18:51-03:00 (first task commit)
- **Completed:** 2026-09-12T20:24:23-03:00 (debug-session close-out commit)
- **Tasks:** 2
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- Fixed WINDOWS #7: a photo-rail dot tap (touch, mouse, or keyboard) no longer pauses the About page's photo carousel autoplay forever. All pause-causing interactions (dot click, rail swipe) now go through one `this.pauseThenResume` helper that pauses, clears any pending resume timer, then arms a fresh 6000ms resume.
- Added `test/pukllay_club_web/about_carousel_hook_test.exs`, a source-contract ExUnit gate (15 tests) that pins the hook's structure: the shared helper, its call sites, clear-before-arm timer ordering, the DOM premise that `[data-dots]` is a sibling (not descendant) of `[data-rail]`, mouseenter's timer cancellation, and full teardown. Confirmed RED against the unfixed hook (6/15 failing) before the fix, GREEN after.
- Proved the real timer behavior with an out-of-tree Node 22 execution of the actual (fixed) hook `<script>` body, mounted against a DOM stub with real event bubbling and fake timers — 5 scenarios (K1 dot tap, K2 keyboard press, K3 swipe-after-tap window restart, K4 mouse-resting-on-rail, K5 rail-swipe control) all passed.
- Resolved the debug session `.planning/debug/about-rail-dot-click-pause.md`: filled in `fix`/`verification`/`files_changed`, flipped `status` to `resolved`, and moved it to `.planning/debug/resolved/`.

## Task Commits

Each task was committed atomically:

1. **Task 1 (RED): source-contract tests for the unfixed hook** - `769343d` (test)
2. **Task 1 (GREEN): shared pause-then-resume helper** - `50550c1` (fix)
3. **Task 2: debug-session close-out + credo fix surfaced by `mix quality`** - `9bb1f5f` (docs)

_Note: SUMMARY.md is intentionally not committed (per instruction)._

## Files Created/Modified
- `lib/pukllay_club_web/live/about_live.ex` - `.AboutCarousel` hook: added `this.pauseThenResume`; `onClick` and `onPointerDown` now call it instead of assigning `this.paused` directly; rewrote the WR-01 comment block into prose describing the shared helper.
- `test/pukllay_club_web/about_carousel_hook_test.exs` - New source-contract + rendered-DOM regression suite for the `.AboutCarousel` hook (dot tap, keyboard press, swipe-after-tap, helper contract, mouse-on-rail, no-pause-only-path, DOM premise, teardown).
- `.planning/debug/resolved/about-rail-dot-click-pause.md` - Debug session moved from `.planning/debug/` and closed out (status: resolved, Resolution section filled in).

## Decisions Made
- `onPointerDown` stays on `this.rail` (not moved to `this.el`) — the click path already covers every dot-activation modality, and the user's fix spec explicitly kept the rail as the swipe/hover surface.
- No new hover-tracking flag was added for the "mouse resting on rail after a dot click" scenario — `onMouseEnter`'s pre-existing `clearTimeout(this.resumeTimer)` already satisfies it, confirmed by the K4 simulation (zero scrolls during a 20s hover spanning the original 6s window).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug/Lint] Fixed a credo --strict warning in the new test file**
- **Found during:** Task 2 (running `mix quality` as the final gate)
- **Issue:** `assert Enum.count(rail_gotos) == 0` triggered Credo's "prefer `Enum.empty?/1` over `Enum.count/1`" refactoring warning, which fails `mix quality`'s `credo --strict` step.
- **Fix:** Changed to `assert Enum.empty?(rail_gotos)`.
- **Files modified:** `test/pukllay_club_web/about_carousel_hook_test.exs`
- **Verification:** `mix quality` reruns clean (`892 mods/funs, found no issues`).
- **Committed in:** `9bb1f5f` (part of the debug-session close-out commit)

---

**Total deviations:** 1 auto-fixed (Rule 1, lint)
**Impact on plan:** Trivial style fix required by the project's own quality gate. No scope creep.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The fix is proven by a source-contract ExUnit gate plus an out-of-tree execution of the real hook source; both are honest about their limits (see the debug session's `verification` field).
- **Not done in this run:** a live browser check at a real 390px viewport, and flipping `.planning/WINDOWS.md` entry #7 to fixed — the latter was explicitly out of scope for this quick item ("Do NOT edit .planning/WINDOWS.md"). Whatever process owns WINDOWS.md tracking should pick this up next.

---
*Quick item: 260912-rwu (batch 260912-rws)*
*Completed: 2026-09-12*
