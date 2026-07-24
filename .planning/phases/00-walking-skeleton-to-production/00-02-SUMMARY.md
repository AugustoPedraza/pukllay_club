---
phase: 00-walking-skeleton-to-production
plan: 02
subsystem: docs
tags: [agents-md, conventions, tdd, mix-quality, merge-gate, ci]

# Dependency graph
requires:
  - phase: 00-walking-skeleton-to-production (plan 01)
    provides: phx.new scaffold, mix quality alias in mix.exs, phx.new-generated AGENTS.md
provides:
  - Repo-root AGENTS.md documenting the TDD loop, mix quality alias order, manual-merge-gate rule, and Phase 0 non-goals
affects: [00-03 (CI workflow — must match documented mix quality order), 00-04 (Kamal deploy — must match documented merge-gate rule), all future phases (conventions doc every contributor/agent reads first)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "AGENTS.md holds both framework-generated usage rules (from mix phx.new / usage_rules sync) and project-specific conventions, appended rather than overwritten"

key-files:
  created: []
  modified:
    - AGENTS.md

key-decisions:
  - "Appended the four DEPLOY-05 sections into the existing phx.new-generated AGENTS.md instead of overwriting it, preserving the Phoenix/Elixir/Ecto/LiveView usage-rules block between its <!-- usage-rules-start/end --> markers"

patterns-established:
  - "New project-convention sections in AGENTS.md live between the 'Project guidelines' bullets and the '### Phoenix v1.8 guidelines' subsection, outside the auto-synced usage-rules block"

requirements-completed: [DEPLOY-05]

coverage:
  - id: D1
    description: "AGENTS.md documents the TDD loop, the mix quality alias order, the manual-merge-gate rule, and Phase 0 non-goals"
    requirement: "DEPLOY-05"
    verification:
      - kind: other
        ref: "test -f AGENTS.md && grep -qi 'TDD' AGENTS.md && grep -q 'mix quality' AGENTS.md && grep -qi 'merge' AGENTS.md && grep -qi 'non-goal' AGENTS.md"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-24
status: complete
---

# Phase 00 Plan 02: AGENTS.md Conventions Summary

**Repo-root AGENTS.md now documents the TDD loop, `mix quality` gate order, manual-merge-gate rule, and Phase 0 non-goals, appended onto the existing phx.new-generated usage-rules doc**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-24T23:15:00Z
- **Completed:** 2026-07-24T23:17:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Added a "TDD Loop" section: derive/write a test from the acceptance criterion → red → green → refactor → `mix quality` before commit
- Added a "`mix quality` Alias" section stating the exact order (`format --check-formatted` → `credo --strict` → `sobelow --config` → `test --warnings-as-errors`) and the cheapest-first rationale
- Added a "Manual Merge Gate" section: every PR must pass CI before merge (no bypass, including trivial/admin merges), `main` re-runs `mix quality` before build/deploy (D-04), and health-check failures must be fixed, never bypassed
- Added a "Non-Goals (Phase 0)" section covering product features, log-aggregation, alerting, backup restore-test automation, and secrets-manager scope, plus a known-limitation note on GitHub scheduled-workflow best-effort timing

## Task Commits

1. **Task 1: Write AGENTS.md with the four required sections** - `1fd73f1` (docs)

**Plan metadata:** (this commit, below)

## Files Created/Modified
- `AGENTS.md` - Appended four project-convention sections (TDD Loop, mix quality Alias, Manual Merge Gate, Non-Goals) ahead of the existing phx.new-generated Phoenix/Elixir/Ecto/LiveView usage-rules block

## Decisions Made
- Appended new content rather than overwriting the file: plan 00-01's `mix phx.new` scaffold already created `AGENTS.md` (449 lines of framework usage rules synced via the `usage_rules` mix task, wrapped in `<!-- usage-rules-start -->`/`<!-- usage-rules-end -->` markers). Overwriting would have destroyed that framework guidance and fought a tool-managed block. The four new sections were inserted right after the existing "Project guidelines" bullets and before "### Phoenix v1.8 guidelines," outside the auto-synced region.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical context] AGENTS.md already existed; plan's "Create AGENTS.md" action adapted to "append to existing AGENTS.md"**
- **Found during:** Task 1 (pre-action file check)
- **Issue:** The plan's `<action>` describes creating `AGENTS.md` as if from scratch. Plan 00-01 (already executed) ran `mix phx.new`, which generates its own `AGENTS.md` containing Phoenix/Elixir/Ecto/LiveView framework guidelines managed by the `usage_rules` sync tool. Blindly overwriting per a literal reading of the plan would have deleted that framework content and broken the tool-managed sync markers.
- **Fix:** Inserted the four required sections (TDD Loop, mix quality Alias, Manual Merge Gate, Non-Goals) into the existing file at a stable, non-generated location, leaving the `<!-- usage-rules-start -->...<!-- usage-rules-end -->` block untouched.
- **Files modified:** AGENTS.md
- **Verification:** `test -f AGENTS.md && grep -qi 'TDD' AGENTS.md && grep -q 'mix quality' AGENTS.md && grep -qi 'merge' AGENTS.md && grep -qi 'non-goal' AGENTS.md` passes; existing Phoenix guidelines content byte-for-byte unchanged below the insertion point
- **Committed in:** `1fd73f1` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical context / plan-vs-reality adjustment)
**Impact on plan:** No scope creep — same four sections the plan specified were written, at a location that avoids destroying already-committed framework content from plan 00-01.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- DEPLOY-05 is satisfied; AGENTS.md's `mix quality` order (`format --check-formatted` → `credo --strict` → `sobelow --config` → `test --warnings-as-errors`) matches the alias already authored in plan 00-01's `mix.exs`, giving plan 00-03 (CI) and plan 00-04 (Kamal deploy) a single source of truth to mirror for the merge-gate rule (D-04).
- No blockers for plan 00-03 or later plans in this phase.

---
*Phase: 00-walking-skeleton-to-production*
*Completed: 2026-07-24*

## Self-Check: PASSED

- FOUND: AGENTS.md
- FOUND: .planning/phases/00-walking-skeleton-to-production/00-02-SUMMARY.md
- FOUND: commit 1fd73f1 (Task 1)
- FOUND: commit 916e36a (docs: add plan summary)
