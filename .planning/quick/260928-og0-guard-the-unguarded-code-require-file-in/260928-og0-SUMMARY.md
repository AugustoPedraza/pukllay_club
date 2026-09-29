---
phase: quick-260928-og0
plan: 01
subsystem: testing
tags: [elixir, exunit, ecto-migrator, compiler-warnings]

requires: []
provides:
  - "sections_backfill_test.exs guards its Code.require_file/1 call against the CreateSections module-redefinition warning"
  - "clear_estantes_migration_test.exs's top-of-file comment accurately reflects that all three migration-requiring test files now share the same guard"
affects: [testing]

actuals:
  tokens: 616
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - test/pukllay_club/catalog/sections_backfill_test.exs
    - test/pukllay_club/repo/clear_estantes_migration_test.exs

key-decisions:
  - "Guard placed inside setup, not moved above defmodule like the two precedents (catalog_test.exs, clear_estantes_migration_test.exs) — see Design Decision section below for the three grounded reasons."
  - "Corrected the exemption clause in clear_estantes_migration_test.exs's comment rather than deleting the measured claim it was based on — the claim (setup-time diagnostics miss the --warnings-as-errors window) is true and stays; only the conclusion drawn from it (that this makes an unguarded require there fine) is removed."

patterns-established: []

requirements-completed: [QUICK-260928-OG0-01]

coverage:
  - id: D1
    description: "sections_backfill_test.exs's Code.require_file/1 call is guarded so a fresh-database run emits zero CreateSections redefinition warnings, while the test still loads and exercises the migration module"
    requirement: "QUICK-260928-OG0-01"
    verification:
      - kind: unit
        ref: "mix test --warnings-as-errors test/pukllay_club/catalog/sections_backfill_test.exs (fresh MIX_TEST_PARTITION=og0probe DB) — 0 compiler warnings, 1 test, 0 failures, exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "clear_estantes_migration_test.exs's top comment no longer tells the next reader an unguarded require is fine anywhere; the accurate mechanism content and the 35961407560 citation survive byte-for-byte; no 36478951582 citation is introduced"
    requirement: "QUICK-260928-OG0-01"
    verification:
      - kind: unit
        ref: "grep -c 'guarded anyway' (=1), grep -c 'requires a migration too' (=0), grep -c '36478951582' across both files (=0,0), grep -c '35961407560' (=1)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Full 1878-test suite runs clean (0 compiler warnings) on a fresh, isolated database after both edits; no third file changed; probe database destroyed; developer's own pukllay_club_test database untouched"
    verification:
      - kind: unit
        ref: "mix test --warnings-as-errors (full suite, fresh MIX_TEST_PARTITION=og0probe DB) — 1878 tests, 0 failures, 0 compiler warnings, exit 0; psql -lqt | grep -c og0probe = 0 after final drop"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-09-28
status: complete
---

# Phase quick-260928-og0 Plan 01: Guard the unguarded Code.require_file in sections_backfill_test.exs Summary

**Wrapped the bare `Code.require_file/1` call in `sections_backfill_test.exs`'s `setup` block in the same `Code.ensure_loaded?` guard the other two migration-requiring test files already use, eliminating the last Elixir compiler warning in the suite on a fresh database — and corrected the now-stale exemption note this created a gap in.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-28T23:25:04Z
- **Completed:** 2026-09-28T23:29:51Z
- **Tasks:** 3 completed
- **Files modified:** 2

## Accomplishments

- `sections_backfill_test.exs` no longer emits the `CreateSections` module-redefinition compiler warning on a fresh database — measured before (1 warning) and after (0 warnings) under identical fresh-DB conditions.
- `clear_estantes_migration_test.exs`'s top-of-file comment now correctly states that all three migration-requiring test files share the same guard, and explains why `sections_backfill_test.exs` is guarded anyway even though its `setup`-time warning happens to sit outside `--warnings-as-errors`'s collection window.
- Full 1878-test suite confirmed clean (0 compiler warnings, 0 failures) on a fresh, isolated database after both changes.

## RED/GREEN Evidence (hand-translated — `mix test` does not emit TAP)

**RED — Task 1, before any edit.** Command: `MIX_TEST_PARTITION=og0probe mix ecto.drop --quiet` (fresh partition dropped first) then `MIX_TEST_PARTITION=og0probe mix test --warnings-as-errors test/pukllay_club/catalog/sections_backfill_test.exs` (the `test` alias re-creates and re-migrates the partition DB in the same VM). Observed: exactly 1 line matching `warning: ` — `redefining module PukllayClub.Repo.Migrations.CreateSections (current version defined in memory)`, pointing at `priv/repo/migrations/20260914150000_create_sections.exs:1`. Test result: `1 test, 0 failures`. Exit code: `0` (expected and part of the evidence — see the plan's Grounding section on why this doesn't fail the run: the require runs inside `setup`, after `Kernel.ParallelCompiler.require/2`'s window has closed). HALT condition (warning count 0) did not trigger — premise confirmed.

**GREEN — Task 2, after the guard.** Same command, same fresh-partition procedure (dropped and re-created again). Observed: 0 lines matching `warning: `. Test result: `1 test, 0 failures`. Exit code: `0`. `git diff --numstat` showed 8 insertions / 1 deletion, confined to `sections_backfill_test.exs`.

**Full-suite confirmation — Task 3.** Same fresh-partition procedure, full suite: `MIX_TEST_PARTITION=og0probe mix test --warnings-as-errors` (no file filter). Observed: 0 lines matching `warning: `, `1878 tests, 0 failures`, exit code `0`.

## Task Commits

1. **Task 1: Establish falsifiable RED on a fresh, isolated database** - no commit (evidence-only; no repo files modified, confirmed via `git status --short` unchanged before/after)
2. **Task 2: Guard the require, keeping it in `setup`** - `2dff8c31` (fix)
3. **Task 3: Correct the comment block, then prove the suite is clean** - `68b7b1ff` (docs)

_Plan carried no separate metadata commit — the orchestrator handles STATE.md/ROADMAP.md/final commit per the calling instructions for this quick task._

## Files Created/Modified

- `test/pukllay_club/catalog/sections_backfill_test.exs` - `setup`'s `Code.require_file(@migration_path)` call now wrapped in `if !Code.ensure_loaded?(PukllayClub.Repo.Migrations.CreateSections) do ... end`, matching the guard shape already used by `catalog_test.exs` and `clear_estantes_migration_test.exs`. `@migration_path`, the two `Repo.delete_all/1` calls, and the rest of the file are unchanged.
- `test/pukllay_club/repo/clear_estantes_migration_test.exs` - Only the closing exemption clause of the top-of-file comment changed. The accurate mechanism explanation (the `Ecto.Migrator` compile-then-require sequence, the `mix test` alias quotation, "fresh database only — i.e. CI, always", the CI run 35961407560 citation) survives byte-for-byte. The new closing text states: all three migration-requiring test files now carry the guard; `sections_backfill_test.exs`'s `setup`-time require genuinely misses the `--warnings-as-errors` collection window (measured 2026-09-28, Elixir 1.19.5, fresh DB, full suite, warning printed, exit 0); it is guarded anyway because that exemption is an artefact of ExUnit's diagnostic window and of the file's `async: false` status, not a property to build on — flipping that file to `async: true` would move the same diagnostic inside the window.

## Decisions Made

### Design Decision: guard stays inside `setup`, not moved above `defmodule`

Both precedents (`catalog_test.exs`, `clear_estantes_migration_test.exs`) place their guard above `defmodule`. This plan deliberately kept `sections_backfill_test.exs`'s guard inside `setup` instead, for three grounded reasons carried over from the plan's own design note:

1. Moving it strands `@migration_path` (line 17) with no remaining reader (the guard would reference the module atom directly, not the path variable), which emits an unused-module-attribute warning — and that one IS emitted during the require window at the top of the file, so it WOULD be counted by `--warnings-as-errors`. The move would trade a harmless (uncounted) warning for a build-failing one unless the attribute were also deleted, widening the diff beyond the plan's scope.
2. Moving it would make the `CreateSections` module available at compile time of the test module, falsifying the accurate comment (lines 32-38, unchanged) that justifies dispatching via `Module.concat/2` instead of a literal qualified call. Leaving that comment behind, now wrong, is exactly the failure mode this plan's Task 3 exists to fix elsewhere — fixing it properly there would mean rewriting the dispatch as an `alias` + direct call and rewriting that comment too, a larger change to an otherwise-correct file.
3. Location isn't what closes the hole; the guard is. `Code.require_file/1` is already idempotent via `Code.required_files/0` — only the first call ever redefines anything — so the guard suppresses that first call wherever it sits. With the guard in place, the warning is never emitted at all, so the file no longer depends on ExUnit's diagnostic-window timing for its safety, including if it's ever flipped to `async: true` (where a `setup`-emitted warning would land inside the collection window and would fail the build).

### Decision: correct the comment's conclusion, not its measured claim

The task brief that seeded this plan asserted CI run 36478951582 disproved the exemption clause. Live measurement at planning time (documented in the plan's Grounding section, re-confirmed by this execution) showed that assertion is itself wrong: run 36478951582 fails on an unrelated `mix deps.audit` / `mint 1.10.1` advisory via `System.stop(1)`, not on this warning. The clause's underlying claim — that a `setup`-time warning misses `--warnings-as-errors`'s collection window on an `async: false` file — is true and measured; only the conclusion ("so leaving it unguarded there is fine") was wrong, since that timing is an artefact of the diagnostic window, not a property to design around. This plan's edit preserves the measured claim and removes only the false conclusion, and does not cite run 36478951582 anywhere in source.

## Deviations from Plan

None — plan executed exactly as written, including its flagged deviation (see below, carried forward as an open item rather than fixed).

## Open — not fixed here

**The real cause of PR #72's red CI is `mix deps.audit` finding two advisories against the pinned `mint 1.10.1`, not any compiler warning.** This was established by live measurement at planning time (fetching the actual CI log for run 36478951582) and is explicitly out of scope for this task — this plan only makes a fresh-database `mix test --warnings-as-errors` run warning-free, which it now does. The mechanism: `deps/mix_audit/lib/mix_audit/cli/audit.ex` calls `System.stop(1)` when advisories are found; `System.stop/1` is asynchronous, so the `mix quality` alias runs on through `credo`, `sobelow`, and the full `test` step (which completes with `1878 tests, 0 failures`) before the VM exits 1 with no further message — matching the CI log's shape exactly. Locally `mix deps.audit` currently exits 0 only because the local advisory database copy predates the two `mint 1.10.1` entries (`EEF-CVE-2026-91043` HIGH, `EEF-CVE-2026-92103` MEDIUM); `mix.lock:38` does pin `mint 1.10.1`.

**Note on the task brief's own attribution, corrected at execution time (per this task's prompt context, not independently re-verified in this session):** the failing command in that CI run was `mix hex.audit` (the first step of the `quality` alias), not `mix deps.audit` — `deps.audit` reportedly printed "No vulnerabilities found." a second later in the same run. This SUMMARY records that correction as given; this plan's own Grounding section (written at planning time) still describes the mechanism as `mix deps.audit` → `System.stop(1)`. Whichever audit step is the literal trigger, the underlying `mint 1.10.1` advisories and the `System.stop(1)` async-exit mechanism are the real, unresolved cause — not this plan's guard. **Also already resolved and merged, independent of this plan:** commit `1311b0e8` bumped `mint 1.10.1 -> 1.11.0` (+ `hpax 1.0.4 -> 1.1.0`) in `mix.lock`; CI is green on `main`. This plan did not touch `mix.lock` and does not claim to have fixed CI.

Three options remain for the developer if this resurfaces (kept here for reference, though the mint pin itself has since been bumped per the above):
1. Bump or replace the transitive `mint` pin to a version without the advisory.
2. Add a `.mix_audit_ignore` (or equivalent) entry with a dated justification, if the advisory is assessed as not applicable.
3. Accept a red gate until one of the above is done.

**No claim in this SUMMARY, in either commit message, or in either edited source comment states that this change fixes CI or makes `mix quality` pass — per the plan's explicit prohibition.**

## Issues Encountered

None. All three tasks completed on the first pass; every gate specified in the plan (guard-presence grep, fresh-DB warning counts, `git diff --numstat`, `mix format --check-formatted`, scoped `mix credo --strict`, full-suite fresh-DB run, probe-database-removal check) passed on first execution.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The suite is warning-free on a fresh database. The `mint 1.10.1` CI-failure cause is documented above as an open item, though independently resolved (commit `1311b0e8`) per the task's own updated context. No blockers for other work.

## Self-Check: PASSED

- FOUND: test/pukllay_club/catalog/sections_backfill_test.exs
- FOUND: test/pukllay_club/repo/clear_estantes_migration_test.exs
- FOUND: .planning/quick/260928-og0-guard-the-unguarded-code-require-file-in/260928-og0-SUMMARY.md
- FOUND: 2dff8c31 (fix commit)
- FOUND: 68b7b1ff (docs commit)

---

*Phase: quick-260928-og0*
*Completed: 2026-09-28*
