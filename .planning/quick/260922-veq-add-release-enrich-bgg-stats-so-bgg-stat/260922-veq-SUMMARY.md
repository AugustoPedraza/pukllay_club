---
phase: quick-260922-veq
plan: 01
subsystem: infra
tags: [elixir, ecto, release, bgg, jason, req]

requires:
  - phase: quick-260922-tum
    provides: "BggClient.parse_items/1 xpath-scoping fix (./ not .//), already deployed to production"
provides:
  - "PukllayClub.Release.enrich_bgg_stats/1 — release-callable repair vehicle (rpc-only)"
  - "PukllayClub.Release.bgg_stats_report/0 — release-callable read-only before/after measurement (rpc-only)"
  - "PukllayClub.Catalog.Seed.StatsAudit.report/0 — falsifiable duplicate-entry audit"
  - "docs/runbooks/production-bgg-reenrichment.md — the operator's six-step sequence"
affects: [production-bgg-stats-repair]

actuals:
  tokens: 6401
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Release entry points (rpc-only) guard liveness via a required-process allowlist (Process.whereis/1) rather than Ecto.Migrator.with_repo/2, which is unsafe against an already-running node's connection pool"
    - "Release functions publish through two channels (IO.puts for rpc's discarded-return-value problem, Logger.info for kamal app logs / Sentry) instead of writing a file under priv/, which is discarded on every deploy"
    - "Tuple-valued summary fields ({ids, reason}) are normalized to maps before Jason.encode!/1 — a bare tuple raises Protocol.UndefinedError"

key-files:
  created:
    - lib/pukllay_club/catalog/seed/stats_audit.ex
    - test/pukllay_club/release_test.exs
    - test/pukllay_club/catalog/seed/stats_audit_test.exs
    - docs/runbooks/production-bgg-reenrichment.md
  modified:
    - lib/pukllay_club/release.ex
    - AGENTS.md

key-decisions:
  - "ensure_live_node!/1 takes its process-name list as an argument (not hardcoded) so both the raise branch and the real required-process list are directly testable, per F4's grounding fact"
  - "bgg_stats_report/0 passes a narrower [PukllayClub.Repo] list to the same guard rather than a separate, looser guard function — one guard, two call sites"
  - "StatsAudit.report/0 computes entirely in Elixir (never a second SQL copy of the duplicate rule), mirroring the BandAudit.mismatches/0 precedent from 01.8.1-13"

patterns-established:
  - "Release module functions meant for rpc invocation print one JSON line via IO.puts AND Logger.info, write no file, and document the exact rpc invocation in their @doc"

requirements-completed: [QUICK-260922-VEQ-01]

coverage:
  - id: D1
    description: "Release.enrich_bgg_stats/1 exists, delegates to StatsEnricher.enrich_from_bgg/2, supports dry_run: true, and refuses to run on a node missing Repo or Req.Finch"
    requirement: "QUICK-260922-VEQ-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club/release_test.exs#enrich_bgg_stats/1 and #ensure_live_node!/1 (7 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Release.bgg_stats_report/0 and Catalog.Seed.StatsAudit.report/0 exist, are read-only, and report publisher/artist maxima and duplicate-row counts alongside unchanged mechanics/designers controls, falsifiably (a seeded duplicate IS reported)"
    requirement: "QUICK-260922-VEQ-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog/seed/stats_audit_test.exs (4 tests) + test/pukllay_club/release_test.exs#bgg_stats_report/0 (1 test)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both release functions print exactly one JSON line and write no file; no raw credential value reaches stdout or the log"
    requirement: "QUICK-260922-VEQ-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club/release_test.exs#'no raw credential value reaches stdout or the log' and #'nothing is written under priv/'"
        status: pass
    human_judgment: false
  - id: D4
    description: "docs/runbooks/production-bgg-reenrichment.md holds the exact six-step operator sequence, and AGENTS.md points to it — nothing in this plan was executed against production"
    requirement: "QUICK-260922-VEQ-01"
    verification:
      - kind: other
        ref: "test -f docs/runbooks/production-bgg-reenrichment.md && grep bgg_stats_report/enrich_bgg_stats && grep AGENTS.md — RUNBOOK_WIRED"
        status: pass
    human_judgment: true
    rationale: "The runbook's real acceptance gate (Step 5's before/after comparison table) can only be evaluated once an operator actually runs it against production — that is explicitly out of scope for this plan (code-and-docs only, no production access). A human must read the runbook end to end before authorizing that later run, per the plan's own <human-check>."

duration: ~15min
completed: 2026-09-22
status: complete
---

# Phase quick-260922-veq: Release.enrich_bgg_stats/1 + falsifiable production measurement Summary

**Two release-callable entry points (`Release.enrich_bgg_stats/1`, `Release.bgg_stats_report/0`) that let an operator repair and prove-repaired production's BGG-contaminated `publishers`/`artists` columns without Mix, plus the runbook for the human-gated run that follows.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-09-22T22:50:07-03:00 (plan commit)
- **Completed:** 2026-09-22T22:56:58-03:00 (last task commit); `mix quality` ran after
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- `PukllayClub.Release.enrich_bgg_stats/1` — the repair vehicle, guarded by `ensure_live_node!/1` (refuses a node missing `PukllayClub.Repo`/`Req.Finch` with an actionable `rpc`-naming error instead of half-running), delegating entirely to the already-deployed `StatsEnricher.enrich_from_bgg/2`
- The `failed_batches` tuple-to-JSON encoding trap (T-VEQ-04's sibling risk) is closed: `{ids, reason}` 2-tuples are normalized to `%{ids:, reason:}` maps before `Jason.encode!/1`, regression-tested against a stubbed 403
- `PukllayClub.Catalog.Seed.StatsAudit.report/0` — a read-only, falsifiable audit (negative-tested: a seeded duplicate publisher entry IS reported, and a cross-wiring test proves `mechanics`/`designers` aren't accidentally reading the wrong column) plus `Release.bgg_stats_report/0` as its `rpc` entry point
- `docs/runbooks/production-bgg-reenrichment.md` — the full six-step operator sequence (before measurement, dry run as the real gate, live run, after measurement, a property-shaped comparison table, record), plus an `AGENTS.md` pointer

## Task Commits

Each task was committed atomically:

1. **Task 1: Release.enrich_bgg_stats/1 — the repair vehicle, end to end** - `50e7c13` (feat)
2. **Task 2: StatsAudit.report/0 + Release.bgg_stats_report/0 — the falsifiable measurement** - `e657d0a` (feat)
3. **Task 3: The production runbook — the commands the operator will actually run** - `029f2c4` (docs)

**Plan metadata:** `88a14c2` (docs: plan)

## Files Created/Modified
- `lib/pukllay_club/release.ex` - added `ensure_live_node!/1`, `enrich_bgg_stats/1`, `bgg_stats_report/0`
- `lib/pukllay_club/catalog/seed/stats_audit.ex` - new read-only audit module (no write path)
- `test/pukllay_club/release_test.exs` - new: 13 tests across both release functions and the guard
- `test/pukllay_club/catalog/seed/stats_audit_test.exs` - new: 4 tests, including the negative (duplicate-detection) test
- `docs/runbooks/production-bgg-reenrichment.md` - new operator runbook
- `AGENTS.md` - pointer to the runbook, added after the existing `create_owner` block

## Decisions Made
- `ensure_live_node!/1` takes the process-name list as its (defaulted) argument, so the raise branch is unit-testable without killing a real supervisor and the real required-process list (`[PukllayClub.Repo, Req.Finch]`) is itself asserted satisfiable — it can never silently drift to name a process that isn't running.
- `bgg_stats_report/0` reuses `ensure_live_node!/1` with a narrower `[PukllayClub.Repo]` list rather than adding a second guard function — one guard, two call sites, per the plan's action spec.
- `StatsAudit.report/0` computes the duplicate rule entirely in Elixir (one `select` + `Enum.reduce`), never a second SQL copy — this follows the `BandAudit.mismatches/0` precedent (01.8.1-13) the plan cited.

## Deviations from Plan

None — plan executed exactly as written. Both tests written first per the `tdd="true"` tasks passed on the first full run once one test-fixture detail (an array-column test's un-set fixture default) was corrected during authoring — recorded below as it required a genuine fix, not a design change.

### Auto-fixed Issues

**1. [Rule 1 - Bug] `StatsAudit.report/0`'s empty-array test used a stale fixture default**
- **Found during:** Task 2, first `mix test` run
- **Issue:** The test "empty and absent arrays are counted as zero, not crashes" inserted a second game via `game_fixture(%{bgg_id: nil})` without overriding `publishers`, so the fixture's default `publishers: ["Devir"]` gave `publishers.max == 1`, not the expected `0`.
- **Fix:** Passed `publishers: []` explicitly on both fixtures in that test, matching the test's actual intent (empty-array handling, not fixture-default coverage).
- **Files modified:** `test/pukllay_club/catalog/seed/stats_audit_test.exs`
- **Verification:** `mix test test/pukllay_club/catalog/seed/stats_audit_test.exs` green (4/4)
- **Committed in:** `e657d0a` (Task 2 commit — the test never landed in its broken form)

---

**Total deviations:** 1 auto-fixed (1 bug, test-only, found and fixed before the first commit of the affected file)
**Impact on plan:** None — a test-authoring correction, no production code or design changed.

## Styler Review

`mix format` (Styler plugin, mandatory per CLAUDE.md) was reviewed via `git diff` after every task. Two rewrites, both confirmed behavior-preserving:
- `assert Repo.get!(Game, game.id).bgg_rank != nil` → `assert Repo.get!(Game, game.id).bgg_rank` (`bgg_rank` is an integer field, so truthy-check is equivalent to `!= nil`).
- A piped `|> Map.merge(column_stats)` in `StatsAudit.report/0` rewritten to the equivalent nested `Map.merge(%{...}, column_stats)` call — no logic change.

## Issues Encountered

None beyond the test-fixture fix above.

## Human-Access Boundary Honored

Per the plan's constraints, no task in this plan connected to, read from, or wrote to the production host or the production database. `mix quality`'s live-network-simulated tests (`retry: got response with status 429/500` warnings visible in the full-gate run) are pre-existing environmental noise in files this plan did not touch (confirmed via `git diff --stat`), matching the plan's own "Known environmental noise" callout.

**Automated-vs-operator-only split (stated honestly, per the plan's constraints):** Automated here — option passthrough, dry-run wiring, credential redaction in both output channels, the tuple-to-JSON normalization of `failed_batches`, the liveness guard's pass and raise branches, the absence of any `priv/` write, and the entire measurement including its negative tests. **Only provable by the operator at invocation time** (not faked or simulated by this plan) — that `Credentials.fetch!/0` actually resolves on the production host from Kamal's `env.secret`; that `kamal app exec --reuse` reaches the running container; that the printed JSON survives Kamal's own output interleaving; and the real before/after numbers.

## User Setup Required

None — no external service configuration required. The runbook itself documents the human-authorized production run that comes next, but running it is explicitly out of scope for this plan.

## Next Phase Readiness

- `PukllayClub.Release.enrich_bgg_stats/1` and `PukllayClub.Release.bgg_stats_report/0` are deployed-ready (code + tests + `mix quality` green); the actual production repair run is a separate, human-authorized action per `docs/runbooks/production-bgg-reenrichment.md`.
- No blockers. The next operator action is: deploy this change, then follow the runbook's six steps against production.

## Self-Check: PASSED

All 5 created/modified files confirmed present on disk; all 3 task commit hashes (`50e7c13`,
`e657d0a`, `029f2c4`) confirmed present in `git log --oneline --all`.

---
*Phase: quick-260922-veq*
*Completed: 2026-09-22*
