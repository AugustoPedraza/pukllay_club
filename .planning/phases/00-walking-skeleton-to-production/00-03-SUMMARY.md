---
phase: 00-walking-skeleton-to-production
plan: 03
subsystem: infra
tags: [github-actions, ci, branch-protection, erlef-setup-beam, gh-cli]

# Dependency graph
requires:
  - phase: 00-01
    provides: Phoenix scaffold, mix.exs `quality` alias (format, credo, sobelow, test)
provides:
  - Public GitHub repository (`AugustoPedraza/pukllay_club`) wired as `origin`
  - `.github/workflows/ci.yml` — runs `mix quality` against a `postgres:17` service on every PR and push to `main`, with mix.lock-keyed dependency caching
  - Branch protection on `main` requiring the `quality` status check (strict, enforce_admins=true, no bypass)
  - PR + branch-merge workflow now required for future commits to `main` (direct pushes are blocked by the new gate)
affects: [00-04, 00-05, 00-06]

# Tech tracking
tech-stack:
  added: [erlef/setup-beam@v1, actions/cache@v4, postgres:17 service container]
  patterns: [GitHub Actions CI gate before merge, mix.lock-keyed build caching, required-status-check branch protection]

key-files:
  created: [.github/workflows/ci.yml]
  modified: [.planning/phases/00-walking-skeleton-to-production/00-CONTEXT.md, .planning/phases/00-walking-skeleton-to-production/00-RESEARCH.md]

key-decisions:
  - "D-19 (new): repo flipped from private to public during execution — GitHub Free does not support branch protection/rulesets on private repos; explicit user decision, verified no secret-exposure risk"
  - "Branch protection requires PR-based merges to main going forward — direct `git push` to main is now rejected once a required status check exists, so future plans (00-04+) must open a PR and let CI pass before merging, even under `branching_strategy: none`"
  - "60-day scheduled-workflow auto-disable now applies (public repo) — flagged forward to plan 00-06's nightly backup job design"

requirements-completed: [DEPLOY-02]

coverage:
  - id: D1
    description: "GitHub Actions CI workflow runs `mix quality` against a postgres:17 service on every PR and push to main, with mix.lock-keyed caching"
    requirement: "DEPLOY-02"
    verification:
      - kind: integration
        ref: "gh run 30133882177 (push to main) — quality job passed in 2m19s"
        status: pass
      - kind: integration
        ref: "gh pr checks 1 (PR #1) — quality check passed"
        status: pass
    human_judgment: false
  - id: D2
    description: "Branch protection on main requires the quality check to pass before any merge, with no admin bypass"
    requirement: "DEPLOY-02"
    verification:
      - kind: integration
        ref: "gh api repos/AugustoPedraza/pukllay_club/branches/main/protection --jq '.required_status_checks.checks' -> [{context: quality}]; .enforce_admins.enabled -> true"
        status: pass
      - kind: integration
        ref: "direct `git push origin main` rejected with GH006 'Required status check quality is expected' — confirms the gate is live and non-bypassable"
        status: pass
    human_judgment: false
  - id: D3
    description: "Repository visibility changed from private to public to unlock GitHub Free branch protection"
    requirement: "DEPLOY-02"
    verification: []
    human_judgment: true
    rationale: "This is a real-world, irreversible-in-spirit business/portfolio decision (repo becomes publicly visible) made via explicit user confirmation mid-execution, overriding the plan's original 'do not make public' constraint. Recorded here for human sign-off/awareness, not something automated verification can validate."

duration: 90min
completed: 2026-07-25
status: complete
---

# Phase 0 Plan 03: CI Quality Gate + Branch Protection Summary

**GitHub Actions `quality` job (erlef/setup-beam, mix.lock-keyed cache, postgres:17 service, `mix quality`) gates every PR and push to `main`, enforced via non-bypassable branch protection on a now-public `pukllay_club` repo.**

## Performance

- **Duration:** ~90 min
- **Started:** 2026-07-24T23:17:50Z (session start, per STATE.md)
- **Completed:** 2026-07-25T00:47:40Z
- **Tasks:** 3 (plus 1 mid-execution checkpoint/decision cycle)
- **Files modified:** 3 (`.github/workflows/ci.yml` created; `00-CONTEXT.md`, `00-RESEARCH.md` updated)

## Accomplishments
- Created the private (later flipped public) GitHub repository `AugustoPedraza/pukllay_club` and pushed the existing scaffold as `origin`/`main`
- Authored `.github/workflows/ci.yml`: triggers on `pull_request` and `push` to `main`, pins Elixir 1.19.5-otp-28/Erlang 28.5 via `erlef/setup-beam@v1` (matching `mise.toml`), caches `deps`/`_build` keyed on `hashFiles('**/mix.lock')`, runs a `postgres:17` health-checked service, and runs `mix quality` (format → credo → sobelow → test) with least-privilege `permissions: contents: read`
- Verified the workflow end-to-end: first push-to-main CI run passed (`quality` job, 2m19s); confirmed the check-run name is exactly `quality`
- Enabled branch protection on `main`: `required_status_checks` = `[quality]`, `strict: true`, `enforce_admins: true` (no bypass, including for the repo owner)
- Proved the gate is live and non-bypassable: opened PR #1 to land the deviation-documentation commits, watched the `quality` check pass on the PR, and merged only after it went green — and separately confirmed a raw `git push` directly to `main` is rejected by GitHub (`GH006: Required status check "quality" is expected`) now that the check exists

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the private GitHub repo and push the scaffold** — no separate file commit (remote wiring only, not a git-trackable diff); verified via `git remote get-url origin` and `gh repo view --json visibility`
2. **Task 2: Author the CI quality-gate workflow (ci.yml)** - `19e209c` (feat) — pushed directly to `main` (branch protection did not yet exist)
3. **Task 3: Require the CI check as a branch-protection merge gate on main** - branch protection configured via `gh api` (not a file diff); the accompanying documentation of this task's deviation (repo visibility change + updated Pitfall 3 guidance) is commit `abf635c` (docs), landed via PR #1 and merged as `1a6fbd2` (merge commit) — this commit itself had to go through the new PR + CI gate since it was authored after Task 3 activated branch protection

**Plan metadata:** (final commit hash recorded after this SUMMARY is committed — see below)

## Files Created/Modified
- `.github/workflows/ci.yml` - GitHub Actions CI quality gate (erlef/setup-beam, mix.lock cache, postgres:17 service, `mix quality`)
- `.planning/phases/00-walking-skeleton-to-production/00-CONTEXT.md` - added D-19 documenting the private→public visibility change, rationale, and the flagged-forward 60-day auto-disable tradeoff for plan 00-06
- `.planning/phases/00-walking-skeleton-to-production/00-RESEARCH.md` - corrected the now-stale "60-day auto-disable doesn't apply to private repos" reasoning in two places (Summary section, Pitfall 3) to reflect the repo now being public

## Decisions Made
- **D-19 (repository visibility, private → public):** Task 3's branch protection requirement could not be satisfied on a private repo under GitHub Free (`403 Upgrade to GitHub Pro or make this repository public`). Per explicit, informed user/coordinator confirmation mid-execution: the repo was flipped to public rather than upgrading to GitHub Pro or accepting a weaker (undocumented-convention-only) merge gate. Rationale: the project doubles as a professional portfolio piece (public visibility is a feature); no secrets exist anywhere in git history or tracked files; `ci.yml` references zero repository secrets and uses the safe `pull_request` (not `pull_request_target`) trigger; GitHub Actions repo secrets are visibility-agnostic (encrypted, write-only, usable only by accounts with write access). This overrides the plan's original Task 1 "do not make public" note — documented here and in `00-CONTEXT.md` D-19 for traceability.
- **Branch protection configuration:** `required_status_checks.strict = true`, `checks = [{context: "quality"}]`, `enforce_admins = true`, all other bypass-adjacent settings (`allow_force_pushes`, `allow_deletions`, `block_creations`) left `false`/disabled. This matches the plan's "no bypass, including admin" requirement precisely.
- **Workflow-process implication (important for 00-04/00-05/00-06):** with branch protection active, GitHub rejects *any* push to `main` — including direct pushes by the repo owner — unless that exact commit already carries a passing `quality` check. This project's `.planning/config.json` has `git.branching_strategy: "none"` (direct-to-main commits), which is now incompatible with completing a plan's final metadata commit via a bare `git push origin main`. This plan's own remaining commits were landed via a short-lived branch + PR (`docs/00-03-ci-branch-protection` → PR #1 → merged after CI passed), which fully respects the non-bypassable gate. **Future plan executors (00-04 onward) will need the same branch+PR pattern for every commit that lands on `main`**, unless the project's git workflow config is deliberately revisited. Flagging this to STATE.md blockers/concerns since it affects every remaining Phase 0 plan.

## Deviations from Plan

### Auto-fixed / User-decided Issues

**1. [Rule 4 - Architectural/business decision, explicit user confirmation] Repository visibility flipped private → public**
- **Found during:** Task 3 (branch protection)
- **Issue:** GitHub Free does not support branch protection or repository rulesets on private repositories (`403 Upgrade to GitHub Pro or make this repository public`). This directly conflicted with Task 1's private-repo requirement and the plan's explicit "do not make the repo public" instruction.
- **Fix:** Raised a `checkpoint:decision` (gate=blocking-human) to the coordinator with three options (upgrade to GitHub Pro, accept a convention-only gate, or go public). The coordinator returned an explicit, informed decision to go public, with verified rationale (portfolio value; no secrets in git history or `ci.yml`; GitHub Actions secrets are visibility-agnostic). Flipped the repo to public via `gh repo edit --visibility public`, then successfully configured branch protection.
- **Files modified:** none directly (repo setting); documentation of the decision added to `00-CONTEXT.md` (D-19) and `00-RESEARCH.md` (corrected Pitfall 3 / Summary reasoning)
- **Verification:** `gh repo view --json visibility` → `PUBLIC`; branch protection API call succeeded; `required_status_checks.checks` = `[{context: "quality"}]`; `enforce_admins.enabled` = `true`
- **Committed in:** `abf635c` (merged via PR #1 as `1a6fbd2`)

**2. [Rule 3 - Blocking issue, non-bypassing fix] Direct push to main rejected after branch protection activated**
- **Found during:** attempting to push the Task 3 documentation commit (`abf635c`) directly to `main`
- **Issue:** `git push origin main` failed with `GH006: Required status check "quality" is expected` — GitHub blocks any push (not just PR merges) to a protected branch unless the pushed commit already has a passing required check.
- **Fix:** Created a short-lived branch (`docs/00-03-ci-branch-protection`), pushed it, opened PR #1, waited for the `quality` check to pass, then merged via `gh pr merge --merge --delete-branch`. This is the standard, non-bypassing way to satisfy a required-status-check gate — `enforce_admins` was never touched or loosened.
- **Files modified:** none beyond the already-staged `00-CONTEXT.md`/`00-RESEARCH.md` changes
- **Verification:** PR #1 shows `quality` check = pass; `gh pr view 1 --json state,mergedAt` → `MERGED`; local `main` fast-forwarded to the merge commit `1a6fbd2`
- **Committed in:** `1a6fbd2` (merge commit on `main`)

---

**Total deviations:** 2 (1 architectural/user-decided, 1 auto-fixed blocking issue)
**Impact on plan:** Both were necessary to satisfy DEPLOY-02's literal requirement (a real, non-bypassable branch-protection gate) given a GitHub plan-tier limitation the original research did not anticipate. No scope creep — no functionality was added beyond what Task 3 required. The workflow-process implication (PR-based merges now required for `main`) is a real, lasting change to how future plans in this phase must land commits; flagged explicitly rather than silently worked around.

## Issues Encountered
- `gh api` nested-boolean field (`required_status_checks[strict]`) required `-F` (typed) rather than `-f` (string) flag syntax — first attempt failed with a JSON-schema validation error (`"true" is not a boolean`); resolved by switching to `-F`.
- `gh pr merge --delete-branch` triggered a local `git pull --rebase` attempt that failed due to unrelated pre-existing uncommitted changes (`.planning/config.json`, `.planning/research/.cache/*.json` — present before this plan started, out of scope, left untouched). The GitHub-side merge succeeded regardless; local `main` was brought up to date via `git fetch` + `git merge --ff-only origin/main`.

## User Setup Required
None beyond what the coordinator already confirmed (repo visibility decision, GitHub Pro not purchased). No new environment variables or dashboard configuration introduced by this plan.

## Next Phase Readiness
- `main` is now protected: every future change requires a green `quality` CI check before it can land, whether via PR merge or (attempted) direct push.
- **Blocker/process note for plan 00-04 (Docker/Kamal deploy) and beyond:** because direct pushes to `main` are now rejected once a status check exists, the executor for subsequent plans must land commits via a short branch + PR (`gh pr create` → wait for CI → `gh pr merge`), not a bare `git push origin main`, even though `.planning/config.json` still has `git.branching_strategy: "none"`. This is documented here and should be considered before executing 00-04.
- **Blocker/process note for plan 00-06 (nightly backup):** the repo is now public, so GitHub's 60-day scheduled-workflow auto-disable applies. Plan 00-06 must either accept this risk explicitly or add a lightweight keepalive mechanism (see `00-CONTEXT.md` D-19 and `00-RESEARCH.md` Pitfall 3 for the accepted-tradeoff rationale).
- DEPLOY-02 is satisfied: every PR (and push to `main`) runs `mix quality` against a real Postgres service with dependency caching, and cannot be merged/pushed until it passes.

---
*Phase: 00-walking-skeleton-to-production*
*Completed: 2026-07-25*
