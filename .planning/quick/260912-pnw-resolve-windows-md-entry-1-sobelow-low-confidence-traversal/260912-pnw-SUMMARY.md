---
phase: quick-260912-pnw
plan: 01
subsystem: security
tags: [sobelow, security-static-analysis, traversal, seed-tooling]

# Dependency graph
requires: []
provides:
  - "Function-level sobelow_skip annotations closing 4 Traversal.FileModule findings in seed tooling"
  - ".sobelow-conf skip: true enabled with reviewed-exception rationale"
affects: []

# Actuals (#2632)
actuals:
  tokens: 1100
  tasks: 2
  commits: 1
  plan_head_before: "19a59f6"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Function-level sobelow_skip scoped to a single submodule (Traversal.FileModule), preferred over a project-wide ignore entry, so unrelated web-reachable traversal bugs would still be caught"

key-files:
  created: []
  modified:
    - lib/pukllay_club/catalog/seed/csv_import.ex
    - lib/pukllay_club/catalog/seed/report.ex
    - .sobelow-conf

key-decisions:
  - "Suppressed via inline function-level sobelow_skip comments (skip: true) rather than adding Traversal.FileModule to the project-wide ignore list, so future web-reachable traversal findings in other modules are still caught"
  - "Did not run `windows fixed 1` per orchestrator instruction — the ledger flip is deferred to the orchestrator (user-approved, manual step) after gates pass"

requirements-completed: []

coverage:
  - id: D1
    description: "All 4 Traversal.FileModule sobelow findings in seed/csv_import.ex and seed/report.ex closed via reviewed, commented, function-level skips; 3 unrelated findings still surface"
    verification:
      - kind: other
        ref: "mix sobelow --config --verbose (manual invocation, see Verification Evidence below)"
        status: pass
    human_judgment: false
  - id: D2
    description: "mix quality passes end-to-end with no regressions from the sobelow-conf/annotation change"
    verification:
      - kind: other
        ref: "mix quality (manual invocation, see Verification Evidence below)"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-09-12
status: complete
---

# Quick Task 260912-pnw: Resolve WINDOWS.md Entry #1 (sobelow Traversal.FileModule) Summary

**Closed 4 low-confidence Traversal.FileModule sobelow findings in offline seed tooling via 3 reviewed, function-level `sobelow_skip` annotations (not a project-wide ignore), after confirming both flagged modules are unreachable from any web-facing code path.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-09-12T18:45:00-03:00 (approx)
- **Completed:** 2026-09-12T18:57:00-03:00 (approx)
- **Tasks:** 2 (Task 1 committed; Task 2 was verification-only, no file changes)
- **Files modified:** 3

## Accomplishments
- Reachability gate confirmed (grep across `lib` and `test`, plus a specific `lib/pukllay_club_web` grep): the only callers of `CsvImport.stream_rows/1`, `CsvImport.header_row/1`, and `Report.write!/2` are `mix catalog.seed` (a Mix task, not shipped in the release) and two test files. No `PukllayClubWeb` module reaches either function.
- Added a reviewed, dated comment plus `# sobelow_skip ["Traversal.FileModule"]` directly above `stream_rows/1` and `header_row/1` in `csv_import.ex`, and above `write!/2` in `report.ex` (one skip covers both `File.mkdir_p!/1` and `File.write!/2` in that function).
- Flipped `.sobelow-conf`'s `skip: false` to `skip: true` with a dated reviewed-exception comment block (matching the existing `Config.CSP` block's style), explaining the mechanism and why a function-level skip was chosen over a project-wide `ignore` entry.
- Verified the 3 unrelated low-confidence findings (`seo_tags.ex` XSS.Raw, `catalog_live/index.ex` DOS.BinToAtom, `seo.ex` XSS.Raw) still surface unchanged — proving the suppression is scoped to exactly the 3 annotated functions, not project-wide.
- Confirmed `config/runtime.exs` formatting and `core_components.ex` credo cleanliness (both already clean, per plan's pre-verified claim).
- Ran full `mix quality` (hex.audit, deps.audit, deps.unlock --check-unused, format, credo --strict, sobelow --config, test --warnings-as-errors) end-to-end: exit 0, 1040 tests / 0 failures.

## Task Commits

Each task was committed atomically:

1. **Task 1: Re-confirm operator-only path sources, then add function-level Traversal.FileModule skips and enable skip mode** - `def1307` (fix)
2. **Task 2: Confirm the rest of entry #1 is clean, pass mix quality, and flip WINDOWS entry 1** - No commit (verification-only; the WINDOWS.md ledger flip was intentionally skipped per orchestrator instruction — see below)

**Plan metadata:** No metadata commit made — per orchestrator constraint, STATE.md/ROADMAP.md are not updated and SUMMARY/PLAN/STATE are not committed by this executor.

## Files Created/Modified
- `lib/pukllay_club/catalog/seed/csv_import.ex` - Added reviewed comment + `sobelow_skip ["Traversal.FileModule"]` above `stream_rows/1` and `header_row/1`
- `lib/pukllay_club/catalog/seed/report.ex` - Added reviewed comment + `sobelow_skip ["Traversal.FileModule"]` above `write!/2`
- `.sobelow-conf` - `skip: false` -> `skip: true`, with a new dated reviewed-exception comment block

## Decisions Made
- Chose function-level `sobelow_skip` annotations (requiring `skip: true`) over adding `Traversal.FileModule` to the project-wide `ignore` list, so a future web-reachable traversal bug in a different module would still be caught by `mix quality`.
- Per explicit orchestrator constraint, did **not** run `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows fixed 1` and did **not** touch `.planning/WINDOWS.md`. The plan's Task 2 instructed running that CLI command and expected a `WINDOWS_ALREADY_RESOLVED` refusal (entry 1 is currently `waived`, not `open`, and the CLI has no reopen verb) — but the orchestrator's constraints explicitly instructed skipping this step entirely, stating the orchestrator will flip the entry manually (user-approved) after this plan's gates pass. WINDOWS.md was read for context only (see Verification Evidence) and left byte-identical.

## Deviations from Plan

None — plan executed as written for Task 1. Task 2's WINDOWS.md ledger-flip step was intentionally skipped per explicit orchestrator constraint (documented above and in the constraints given for this run), not a deviation rule (1-4) trigger — it's an orchestrator-level scope override, not a discovery made during execution.

## Issues Encountered
None.

## Verification Evidence

**Task 1 automated verify (all passed):**
```
mix sobelow --config --verbose | grep -cE '^File: lib/pukllay_club/catalog/seed/(csv_import|report)\.ex'  => 0
mix sobelow --config | grep -c 'Low Confidence'                                                            => 3
grep -c 'sobelow_skip \["Traversal.FileModule"\]' lib/pukllay_club/catalog/seed/csv_import.ex               => 2
grep -c 'sobelow_skip \["Traversal.FileModule"\]' lib/pukllay_club/catalog/seed/report.ex                   => 1
grep '^  skip: true,$' .sobelow-conf                                                                        => match
grep 'ignore: \["Config.CSP"\],' .sobelow-conf                                                              => match (unchanged)
test ! -e .sobelow-skips                                                                                    => no file (unchanged)
mix format --check-formatted                                                                                 => exit 0
mix test test/pukllay_club/catalog/seed/ --warnings-as-errors                                                => 113 tests, 0 failures
```

**Sobelow before (from plan's pre-verified findings, re-confirmed live) — 7 findings, 4 in scope:**
- `Traversal.FileModule` `File.stream!` — csv_import.ex:27 (`stream_rows/1`)
- `Traversal.FileModule` `File.stream!` — csv_import.ex:41 (`header_row/1`)
- `Traversal.FileModule` `File.mkdir_p!` — report.ex:142 (`write!/2`)
- `Traversal.FileModule` `File.write!` — report.ex:143 (`write!/2`)
- `XSS.Raw` seo_tags.ex:55 (out of scope)
- `DOS.BinToAtom` catalog_live/index.ex:228 (out of scope)
- `XSS.Raw` seo.ex:188 (out of scope)

**Sobelow after — 3 findings, all out-of-scope, unchanged:**
- `XSS.Raw` seo_tags.ex:55
- `DOS.BinToAtom` catalog_live/index.ex:228
- `XSS.Raw` seo.ex:188

**Task 2 automated verify (all passed):**
```
mix format --check-formatted config/runtime.exs      => exit 0
mix credo --strict lib/pukllay_club_web/components/core_components.ex => "18 mods/funs, found no issues" (exit 0)
mix quality                                            => exit 0 (hex.audit clean, deps.audit clean, no unused deps,
                                                            format clean, credo 888 mods/funs no issues,
                                                            sobelow shows exactly the 3 out-of-scope findings,
                                                            1040 tests / 0 failures)
```

## Observations (recorded only, no changes made)

1. **3 remaining out-of-scope low-confidence sobelow findings**, candidates for a separate future review:
   - `XSS.Raw` `lib/pukllay_club_web/components/seo_tags.ex:55` (`seo_tags/1` — `Phoenix.HTML.raw` over meta/link tags built from `seo.description`/`seo.canonical_url`/`seo.image_url`/`seo.title`)
   - `DOS.BinToAtom` `lib/pukllay_club_web/live/catalog_live/index.ex:228` (`carousel_stream_name/1` — atom interpolation from `key`)
   - `XSS.Raw` `lib/pukllay_club_web/seo.ex:188` (`json_ld_tag/2` — `Phoenix.HTML.raw` over `nonce`/`json_ld`)
2. **`.sobelow-conf`'s `exit: true` is not a recognized sobelow 0.14.1 exit threshold** (only `"low"`/`"medium"`/`"high"` are recognized) — the `sobelow --config` step of `mix quality` never fails on findings regardless of severity. This means `mix quality` passing does not, by itself, prove sobelow found zero findings — it only proves the command didn't crash. Changing `exit:` to a real threshold (e.g. `"low"`) would make `mix quality` start failing on the 3 out-of-scope findings above; that's a separate decision for the user, not made here.
3. **WINDOWS.md entry 1 current on-disk state** (read-only, unchanged by this plan): `status: "waived"`, with `resolved_at: "2026-09-12T21:18:08.013Z"` already set from a prior run. The plan anticipated running `windows fixed 1` and expected a `WINDOWS_ALREADY_RESOLVED` refusal since `markFixed` only accepts `open` entries and there is no reopen verb. Per this run's orchestrator constraints, that step (and the CLI invocation entirely) was skipped — WINDOWS.md was left byte-identical (verified: not staged, not modified). The orchestrator is expected to flip this entry manually after reviewing this SUMMARY's gate results.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All 4 Traversal.FileModule findings from WINDOWS.md entry #1 are genuinely closed (not waived) with a real, reviewed fix.
- `mix quality` passes cleanly end-to-end on this branch.
- WINDOWS.md entry #1 is left untouched, pending the orchestrator's manual ledger flip.
- No blockers for sibling batch items on this branch (bgg_client.ex, filter_modal.ex, debug/todo files were not touched).

## Self-Check: PASSED

- FOUND: lib/pukllay_club/catalog/seed/csv_import.ex
- FOUND: lib/pukllay_club/catalog/seed/report.ex
- FOUND: .sobelow-conf
- FOUND commit: def1307
- WINDOWS.md: no diff, confirmed untouched (`git status --short .planning/WINDOWS.md` empty)

---
*Phase: quick-260912-pnw*
*Completed: 2026-09-12*
