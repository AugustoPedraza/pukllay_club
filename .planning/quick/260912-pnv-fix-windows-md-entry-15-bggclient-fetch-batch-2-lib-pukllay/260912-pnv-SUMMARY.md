---
phase: quick-260912-pnv
plan: 01
subsystem: seed-tooling
tags: [elixir, bgg-api, req, ex-unit, tdd]

# Dependency graph
requires: []
provides:
  - "BggClient.fetch_batch/2 handles an empty id list gracefully (`{:ok, []}`, zero HTTP requests) instead of crashing on `binary_to_integer(\"\")`"
affects: [catalog-seed, stats-enricher]

# Actuals (#2632)
actuals:
  tokens: 594
  tasks: 1
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Empty-collection short-circuit function clause placed before the guarded clause, matching module's existing multi-clause style"

key-files:
  created: []
  modified:
    - lib/pukllay_club/catalog/seed/bgg_client.ex
    - test/pukllay_club/catalog/seed/bgg_client_test.exs

key-decisions:
  - "Task 2 (WINDOWS.md ledger closure via the `windows fixed` CLI verb) was explicitly excluded from this run per orchestrator instruction — the orchestrator will flip entry 15 to fixed manually (user-approved) after these commits land. No `windows` CLI command was invoked and .planning/WINDOWS.md was not touched."

requirements-completed: []

coverage:
  - id: D1
    description: "BggClient.fetch_batch([], credentials) returns {:ok, []} and makes zero HTTP requests"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog/seed/bgg_client_test.exs#returns {:ok, []} for an empty id list without making an HTTP request (WINDOWS #15)"
        status: pass
    human_judgment: false
  - id: D2
    description: "All pre-existing fetch_batch/2 behaviours unchanged (single-id parse, unranked normalization, hostile-DTD error, 401 error, 429 retry, req_options/0)"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog/seed/bgg_client_test.exs (6 pre-existing tests, all passing)"
        status: pass
    human_judgment: false

duration: 2min
completed: 2026-09-12
status: complete
---

# Quick Task 260912-pnv: Fix WINDOWS.md entry 15 — BggClient.fetch_batch/2 empty-list crash

**Added a new `fetch_batch([], %Credentials{})` clause to BggClient that returns `{:ok, []}` before building any HTTP request, pinned with a TDD regression test (RED confirmed, then GREEN).**

## Performance

- **Duration:** ~2 min (commit-to-commit)
- **Started:** 2026-09-12T18:37:49-03:00 (RED commit)
- **Completed:** 2026-09-12T18:38:28-03:00 (GREEN commit)
- **Tasks:** 1 of 2 plan tasks (Task 1 only; Task 2 explicitly skipped — see below)
- **Files modified:** 2

## Accomplishments
- `BggClient.fetch_batch([], credentials)` now returns `{:ok, []}` immediately, never reaching `do_request/3`, so no HTTP request (and no Authorization header) is ever sent for an empty batch.
- New clause placed before the existing guarded clause per the plan's key_links requirement, so clause ordering guarantees the short-circuit.
- Regression test added and observed failing (RED) before the fix, then passing (GREEN) after — confirming the fix actually closes the crash and isn't a false-positive test.
- All 6 pre-existing tests in `bgg_client_test.exs` remain green (single-id parse, unranked normalization, hostile-DTD error tuple, 401 error tuple, 429 retry, `req_options/0`).

## Task Commits

Each task was committed atomically (TDD RED → GREEN):

1. **Task 1a: RED — failing test** - `6b5ad57` (test)
2. **Task 1b: GREEN — fix** - `048f607` (fix)

No plan-metadata commit was made for this SUMMARY per the orchestrator's explicit instruction (STATE.md/ROADMAP.md not updated, PLAN/STATE/SUMMARY not committed by this agent).

_Note: TDD task produced 2 commits (test → fix), matching the plan's two-commit expectation for Task 1._

## Files Created/Modified
- `lib/pukllay_club/catalog/seed/bgg_client.ex` - Added `def fetch_batch([], %Credentials{}), do: {:ok, []}` clause before the guarded clause; extended the `@doc` for `fetch_batch/2` with one sentence documenting the empty-list short-circuit and citing WINDOWS.md entry 15.
- `test/pukllay_club/catalog/seed/bgg_client_test.exs` - Added a new test in the `describe "fetch_batch/2"` block asserting `{:ok, []}` and `refute_received {:bgg_request_made, _}` against a `Req.Test` stub that would otherwise report any call.

## Decisions Made
- Kept the `%Credentials{}` pattern (not `_credentials`) on the new clause so passing a non-`Credentials` second argument to `fetch_batch([], ...)` still fails the same way (`FunctionClauseError`) as it did before this change, preserving the existing contract's shape.
- Did not touch `@max_batch_size`, `@spec`, or the existing guarded clause — the plan's `key_links` explicitly required clause ordering only, no other logic changes.
- **Skipped Task 2 (WINDOWS.md ledger closure) entirely per the orchestrator's explicit constraint.** The plan called for running `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows fixed 15` and recording the outcome (expected refusal, since entry 15 is `waived` not `open`). This run did NOT execute that command and did NOT modify `.planning/WINDOWS.md` in any way — the orchestrator will flip entry 15 to `fixed` manually (user-approved) after these two commits land on `fix/window-followups-260912`. The underlying bug the ledger entry describes is fixed as of commit `048f607`.

## Deviations from Plan

None - Task 1 executed exactly as written (RED test, confirm failure, GREEN fix, format, credo, two commits). Task 2 was not a deviation but an explicit orchestrator-level scope reduction for this run (documented above, not something discovered during execution).

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The underlying WINDOWS.md entry 15 bug is fixed and regression-tested on branch `fix/window-followups-260912` (commits `6b5ad57`, `048f607`).
- Ledger entry 15 itself remains `waived` in `.planning/WINDOWS.md` as of this SUMMARY — it was intentionally left untouched. The orchestrator is expected to close it (via CLI if it now accepts `waived` -> `fixed`, or via an explicit user-approved manual edit if not) once these commits are confirmed landed.
- No blockers for continuing with the remaining `260912-pn*` quick-batch items.

---
*Phase: quick-260912-pnv*
*Completed: 2026-09-12*
