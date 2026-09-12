---
phase: quick-260912-hrx
plan: 01
subsystem: ci-cd
tags: [github-actions, deploy, kamal, ci]
status: complete
dependency-graph:
  requires: []
  provides:
    - deploy.yml `changes` path-filtering gate
    - docs/runbooks/deploy-path-filtering.md
  affects:
    - .github/workflows/deploy.yml
tech-stack:
  added:
    - dorny/paths-filter@v4 (GitHub Action)
  patterns:
    - Fail-open gate via `!= 'false'` output comparison + `continue-on-error: true`
    - Deny-list (not allow-list) path classification for future-proofing
key-files:
  created:
    - docs/runbooks/deploy-path-filtering.md
    - .planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py
  modified:
    - .github/workflows/deploy.yml
decisions:
  - "changes job placed above quality, scoped to permissions: contents: read only — least privilege since it runs a third-party action and must never reach deploy secrets"
  - "predicate-quantifier: 'every' required — default 'some' ORs the negations and misclassifies any file under .planning/.claude as code"
  - "quality kept with no if:/needs: on the gate in both deploy.yml and ci.yml — ci.yml is the workflow branch protection actually requires on PRs and was not touched"
  - "gate output expression compares to literal 'false' string rather than reading the raw output directly, so any error/skip/empty output resolves to true (deploy) rather than false (skip) — fail-open by construction"
actuals:
  tokens: 3632
  tasks: 2
  commits: 2
  plan_head_before: 3167bb5ebb11a8a47da02344ecdbb7a28fbb30d9
metrics:
  duration: ~15min
  completed: 2026-09-12
---

# Quick Task 260912-hrx: Path-based CI filtering for docs-only pushes Summary

Added an always-run `changes` classification job to `deploy.yml` that gates `build-and-push` and
`deploy` on whether a push touched anything outside `.planning/**`, `.claude/**`, `docs/**`, or
`*.md` — so the ~590 tracked markdown files under GSD planning directories no longer trigger a
full Elixir release build and Kamal redeploy on every planning commit, while `quality` keeps
running unconditionally as the required status check.

## What Was Built

**Task 1 (tracer, TDD):** Wrote `check_gate.py` — a structural YAML-parsing checker (not
grep-based) verbatim from the plan's `<verification>` section — and ran it against the unmodified
`deploy.yml` to confirm the exact RED state the plan predicted: 5 failures (no `changes` job;
`build-and-push` missing `needs: changes` and its `if:`; `deploy` missing the same two). No
`quality`/Dockerfile assertions fired at RED, confirming those invariants already held. Edited
`deploy.yml`: added the `changes` job (checkout with `fetch-depth: 0`, then
`dorny/paths-filter@v4` with `id: filter`, `continue-on-error: true`,
`predicate-quantifier: 'every'`, and the five-pattern deny-list filter), an `outputs.code` fail-open
expression, and changed `build-and-push`/`deploy` to `needs: [changes, ...]` +
`if: needs.changes.outputs.code == 'true'`. Re-ran the checker: GREEN, exit 0. Tracer feedback gate
(automated-only `<verify>`, `human_verify_mode: end-of-phase`) re-ran clean, so execution continued
directly into Task 2 without a checkpoint.

**Task 2:** Wrote `docs/runbooks/deploy-path-filtering.md` in the same operator-facing register as
the existing `docs/runbooks/catalog-seed.md`. Covers: which five patterns count as documentation
(reproduced verbatim so the checker's own drift assertion — section 6 of `check_gate.py` — matches
them), why skipping is provably safe (the Dockerfile's selective `COPY` list never touches docs
paths), that `quality` always runs and reports, that the gate is fail-open, and the missing-image
footgun (`kamal deploy --skip-push` from a docs-only `HEAD` fails Kamal's `validate_image` because
`build-and-push` never tagged that commit's SHA in `ghcr.io`) along with the two real escape
hatches (run Kamal locally without `--skip-push`, or land a commit touching a non-doc path) and the
one non-escape-hatch (re-running the skipped workflow just re-skips).

## Deviations from Plan

None — plan executed exactly as written. Both tasks matched their `<behavior>`/`<action>`
specifications, RED state matched the plan's predicted 5 failures exactly, and GREEN was reached
on the first edit with no auto-fix cycles needed.

## Verification

- `python3 .planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py` exits
  0 from the repo root (confirmed after each task and again as the tracer feedback gate re-run).
- `git diff -- .github/workflows/ci.yml` is empty — the required check's workflow is untouched.
- No Elixir source changed; only `.github/workflows/deploy.yml`, the new checker, and the new
  runbook were modified. `git diff --diff-filter=D` after each commit showed no unexpected
  deletions.
- Human check (deferred per this project's `human_verify_mode: end-of-phase`, not run in this
  session): on the next docs-only push to `main`, `gh run list --workflow=deploy.yml --limit 3`
  should show `quality` green with `build-and-push`/`deploy` skipped; the next code-touching push
  should run all four jobs and redeploy.

## Known Stubs

None.

## Threat Flags

None — this plan's own `<threat_model>` (T-QH-01 through T-QH-SC) already covers every new surface
introduced (the `changes` job's third-party action, gate-misclassification risk, the `quality`
required-check boundary, and deploy provenance for docs-only commits); no additional undocumented
surface was found during implementation.

## Self-Check: PASSED

- FOUND: `.github/workflows/deploy.yml` (modified, verified via `git diff --stat`)
- FOUND: `.planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py`
- FOUND: `docs/runbooks/deploy-path-filtering.md`
- FOUND commit `a8fab3a`: `feat(quick-260912-hrx): wire path-filtering gate through build-and-push/deploy`
- FOUND commit `16226be`: `docs(quick-260912-hrx): add deploy path-filtering operator runbook`

## Next Steps

This change lands via a short branch + PR (main is branch-protected — see CLAUDE.md "Git Sync
Discipline"); branching/PR creation is an orchestrator-level operation, not performed by this
executor. Two local commits (`a8fab3a`, `16226be`) sit on `main` ready to be picked up.
