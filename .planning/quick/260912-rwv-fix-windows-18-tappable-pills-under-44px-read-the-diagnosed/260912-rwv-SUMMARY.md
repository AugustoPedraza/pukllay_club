---
phase: quick-260912-rwv
plan: 01
subsystem: ui
tags: [css, touch-target, accessibility, daisyui, tailwind, pill-system, a11y]

requires:
  - phase: quick-260912 (debug session creator-pill-touch-target)
    provides: root-cause diagnosis of the sub-44px tappable pill defect (WINDOWS #18)
provides:
  - "`.pk-pill-interactive` now declares `min-height: 44px`, giving every tappable pill a
    44px touch floor by construction"
  - "CSS-source regression describe block in catalog_show_test.exs pinning the floor, its
    floor-only geometry, and base flex centring"
  - "Resolved debug session .planning/debug/resolved/creator-pill-touch-target.md"
affects: [ui-design-system, ux-responsive, WINDOWS #18]

actuals:
  tokens: 4160
  tasks: 3
  commits: 4
  plan_head_before: c6f3b893f0b1147dee2ab4b799734b903c978d99

tech-stack:
  added: []
  patterns:
    - "44px touch-target floor lives on the pill system's behaviour variant
      (`.pk-pill-interactive`), not as a per-call-site Tailwind `min-h-11` utility — every
      current and future call site composing the variant gets the floor by construction"

key-files:
  created: []
  modified:
    - assets/css/app.css
    - test/pukllay_club_web/live/catalog_show_test.exs
    - .planning/debug/resolved/creator-pill-touch-target.md (moved from .planning/debug/, git mv)

key-decisions:
  - "User chose option A (min-height on `.pk-pill-interactive`) over option B (`min-h-11` on
    creator_pills/1 alone) or a scoped middle rule — fixes every tappable-pill call site at
    once and restores sketch 036's original 44px interactive-chip contract dropped in the
    c33e7f1 port"
  - "Left the redundant `min-h-11` utilities on filter_modal.ex / index.ex in place — harmless
    now-redundant class strings pinned by existing tests, removal was explicitly out of scope"

patterns-established:
  - "Height/touch-target floors for a UI variant set belong on the variant that carries the
    behaviour (e.g. 'tappable'), not bolted on per call site — the same discipline this pill
    system's tone-variant geometry gate already enforces for radius/padding/font-size"

requirements-completed: []

coverage:
  - id: D1
    description: "`.pk-pill-interactive` declares `min-height: 44px`, giving every tappable
      pill (creator pills, Mecánicas/Temáticas links, masthead facts-row links, editorial
      hashtag links) a 44px touch floor"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#pill system interactive touch-target floor (WINDOWS #18, quick 260912-rwv) the top-level .pk-pill-interactive rule declares a 44px min-height touch floor"
        status: pass
      - kind: manual_procedural
        ref: "live CDP probe at 390px, /juegos/137 and /juegos/179 — every a.pk-pill-interactive measures 44px tall"
        status: pass
    human_judgment: false
  - id: D2
    description: "The interactive variant adds only a height floor (no fixed height, width,
      padding, or font-size) so pill widths and wrapping are unchanged — Wingspan's artist
      pills still wrap on multiple rows at 390px with no horizontal overflow"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#pill system interactive touch-target floor (WINDOWS #18, quick 260912-rwv) the interactive variant adds only a height floor"
        status: pass
      - kind: manual_procedural
        ref: "live CDP probe: Wingspan artistRowCount=2, scrollWidth==clientWidth==390 on both pages"
        status: pass
    human_judgment: false
  - id: D3
    description: "Text stays vertically centred inside the taller pill for every tone,
      including the zero-vertical-padding hashtag tone"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#pill system interactive touch-target floor (WINDOWS #18, quick 260912-rwv) text stays vertically centred inside the taller pill"
        status: pass
      - kind: manual_procedural
        ref: "live CDP probe: #DuelosMemorables hashtag box vertical midpoint (636.39px) matches text-node vertical midpoint exactly"
        status: pass
    human_judgment: false
  - id: D4
    description: "`mix quality` passes and the debug session creator-pill-touch-target is
      resolved and moved to .planning/debug/resolved/ via git mv, with WINDOWS.md untouched"
    verification:
      - kind: other
        ref: "mix quality (all seven steps exit 0, 1043 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "git show --name-status 12cf21a shows R100 rename; git diff --exit-code main -- .planning/WINDOWS.md .planning/debug/knowledge-base.md exits 0"
        status: pass
    human_judgment: true
    rationale: "The developer's own visual acceptance of the now visibly taller outline pills
      in the fact grid and masthead facts row has not been reviewed — this was flagged as an
      expected cost during diagnosis but is a genuine visual judgment call, not something a
      geometry probe can sign off on."

duration: 45min
completed: 2026-09-12
status: complete
---

# Quick 260912-rwv: WINDOWS #18 tappable pills under 44px — Summary

**Added `min-height: 44px` to `.pk-pill-interactive`, fixing every tappable pill (creator pills, Mecánicas/Temáticas links, masthead facts row, editorial hashtag links) at once, guarded by a new CSS-source regression test.**

## Performance

- **Duration:** ~45 min
- **Tasks:** 3
- **Files modified:** 3 (assets/css/app.css, test/pukllay_club_web/live/catalog_show_test.exs, .planning/debug/resolved/creator-pill-touch-target.md)

## Accomplishments
- `.pk-pill-interactive` now declares `min-height: 44px`, restoring sketch 036's interactive-chip contract dropped in the c33e7f1 port — every tappable pill reaches 44px by construction, not per-call-site convention.
- New CSS-source regression describe block in catalog_show_test.exs pins the 44px floor, its floor-only geometry (no fixed height/max-height/width/padding/font-size), and the base `.pk-pill`'s flex centring (with `.pk-pill-tag` overriding neither).
- Live 390px CDP measurements on /juegos/137 (Wingspan) and /juegos/179 (7 Wonders Duel) confirm every `a.pk-pill-interactive` now measures 44px, Wingspan's artist pills still wrap on multiple rows with no horizontal overflow, and the `#DuelosMemorables` hashtag link's text stays exactly centred.
- Debug session `creator-pill-touch-target` resolved (root_cause byte-identical, fix/verification/files_changed filled) and moved to `.planning/debug/resolved/` via `git mv`.

## Task Commits

Each task was committed atomically (TDD cycle for Task 1's tracer):

1. **Task 1: Tracer — 44px floor pinned by a failing-first CSS-source test**
   - `b207211` — test(260912-rwv): RED — pin 44px touch floor on .pk-pill-interactive
   - `3e0989b` — fix(260912-rwv): GREEN — 44px touch floor on .pk-pill-interactive
2. **Task 2: Full quality gate + live 390px geometry confirmation** — no commit (measurement-only task; scratchpad probe, never committed, per plan)
3. **Task 3: Resolve the debug session + git mv it to resolved/**
   - `12cf21a` — docs(260912-rwv): resolve creator-pill-touch-target debug session (git mv rename, R100 — content snapshot at commit time regressed to the pre-edit blob, see Issues Encountered)
   - `5efd404` — docs(260912-rwv): fixup — apply the resolved-session edits dropped by the prior commit

**Plan metadata:** not committed (SUMMARY.md excluded from commits per this batch item's constraints)

_Note: no separate "Plan metadata" docs commit — STATE.md/ROADMAP.md/WINDOWS.md are explicitly out of scope for this quick-batch item and were not touched._

## Files Created/Modified
- `assets/css/app.css` — added `min-height: 44px;` to `.pk-pill-interactive`, plus a provenance comment above the rule; no other region touched.
- `test/pukllay_club_web/live/catalog_show_test.exs` — new describe block "pill system interactive touch-target floor (WINDOWS #18, quick 260912-rwv)" with three tests (44px floor, floor-only geometry, base flex centring).
- `.planning/debug/resolved/creator-pill-touch-target.md` — moved from `.planning/debug/creator-pill-touch-target.md` via `git mv`; status `diagnosed` → `resolved`, Resolution section filled with fix/verification/files_changed, Specialist Review appended with the user's option-A rationale.

## Decisions Made
- User chose option A (44px floor on `.pk-pill-interactive`) over option B (`min-h-11` on `creator_pills/1` alone) or a scoped `.pk-fact-col .pk-pill-interactive` rule — closes the diagnosed AND-gate at the variant level, covering every current and future call site at once.
- Left the two pre-existing `min-h-11` Tailwind utilities (filter_modal.ex, index.ex) in place as harmless, now-redundant duplication — removing them was explicitly out of scope (their class strings are pinned by existing tests) and doing so would have widened this fix's blast radius.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Task 3's debug-session commit landed the pre-edit blob instead of the edited content**
- **Found during:** Task 3, immediately after committing the git-mv rename
- **Issue:** After editing `.planning/debug/creator-pill-touch-target.md` (frontmatter, Current Focus, Specialist Review, Resolution) and running `git mv` to `.planning/debug/resolved/`, the resulting commit (`12cf21a`) recorded the file with a blob SHA byte-identical to the pre-edit version at `c6f3b89` — the rename was captured correctly (`R100` in `git show --name-status`) but none of the content edits landed in that commit, despite `git status`/`grep` checks run immediately beforehand showing the edited content on disk. Root mechanism not fully diagnosed (possibly a write/stage timing artifact in the worktree's git plumbing); the working tree retained the correct edited content as an uncommitted diff against `HEAD` immediately after the commit.
- **Fix:** Verified the working-tree file still had every intended edit (diffed cleanly against the intended content), then staged and committed it as a second, separate commit (`5efd404`) rather than amending `12cf21a` — per this executor's "always create new commits, never amend" rule. `HEAD` now has the fully correct, resolved content; the rename provenance (`R100`) from `12cf21a` is preserved in history.
- **Files modified:** `.planning/debug/resolved/creator-pill-touch-target.md`
- **Verification:** `git show HEAD:.planning/debug/resolved/creator-pill-touch-target.md | grep '^status:'` → `status: resolved`; re-ran all Task 3 acceptance-criteria checks (file exists at new path, original path gone, `status: resolved` present, `git diff --exit-code main -- .planning/WINDOWS.md .planning/debug/knowledge-base.md` exits 0) against the final `HEAD` — all pass.
- **Committed in:** `5efd404`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** No scope creep — the fix-up commit only restores the content the plan already specified for Task 3; no new files or behavior were introduced.

## Issues Encountered
- The `12cf21a` commit anomaly described above (Rule 1 deviation) — resolved by a follow-up commit, not by amending, so the git history has two commits for Task 3 instead of one. Both commits carry the `260912-rwv` scope tag and are individually inspectable; the final `HEAD` state matches every acceptance criterion.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- WINDOWS #18 is closed: every tappable pill on the game detail page now meets the 44px touch-target minimum, by construction, for current and future call sites.
- Remaining, explicitly-flagged blind spot: the developer has not yet visually reviewed the taller outline pills in the fact grid and masthead facts row (roughly +105px total fact-grid height at 390px, per the diagnosis's injected-fix measurement) — this is a genuine visual/UX judgment call, not something this task's automation can close.
- Follow-up note (not actioned here): the `ux-responsive` skill's "min-h-11 on every tappable pill" per-call-site wording now predates this variant-level floor; a future pass could update that skill's guidance to point at `.pk-pill-interactive` instead.

---
*Phase: quick-260912-rwv*
*Completed: 2026-09-12*
