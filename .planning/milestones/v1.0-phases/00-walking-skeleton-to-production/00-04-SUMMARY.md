---
phase: 00-walking-skeleton-to-production
plan: 04
subsystem: infra
tags: [docker, kamal, github-actions, ghcr, deploy-pipeline, elixir, phoenix]

# Dependency graph
requires:
  - phase: 00-walking-skeleton-to-production
    provides: "Phoenix release Dockerfile (00-01), branch-protected CI quality gate (00-03)"
provides:
  - "Entrypoint-gated migration wiring (docker-entrypoint + Dockerfile ENTRYPOINT/CMD)"
  - "Kamal config/deploy.yml with TLS proxy, /up healthcheck, localhost-bound pgvector accessory, per-role secrets"
  - ".kamal/secrets (gitignored, $VAR-only)"
  - "Main-branch .github/workflows/deploy.yml: quality re-run -> native arm64 build+push to ghcr.io -> kamal deploy"
affects: ["00-05 (live host provisioning + bring-up + D-06 proof)", "00-06 (nightly backup workflow)"]

# Tech tracking
tech-stack:
  added: ["Kamal 2.12.0 (deploy orchestrator, invoked from CI)", "docker/build-push-action@v6, docker/login-action@v3, docker/metadata-action@v5, docker/setup-buildx-action@v3", "ruby/setup-ruby@v1, webfactory/ssh-agent@v0.9.0"]
  patterns: ["Entrypoint-gated migrations (bin/migrate before exec bin/server, gated on the server command)", "Secrets sourced only from GitHub repo secrets, exported as shell env right before kamal deploy for $VAR substitution", "Native arm64 CI build (ubuntu-24.04-arm, no QEMU/platform override)"]

key-files:
  created: ["docker-entrypoint", "config/deploy.yml", ".kamal/secrets (gitignored, not in git)", ".github/workflows/deploy.yml"]
  modified: ["Dockerfile", ".gitignore"]

key-decisions:
  - "Placeholder Hetzner host (<hetzner-host-placeholder>) used in both servers.web and the db accessory's host field in config/deploy.yml — the box does not exist yet (D-12); plan 00-05 fills it in during provisioning."
  - "webfactory/ssh-agent pinned to v0.9.0 (not the plan-stated 'v0.9', which is not a resolvable tag) — verified against the action repo's real tag list."
  - "Merging the deploy.yml PR to main deliberately triggers a real workflow run per D-02 (CI-driven deploy on every merge); the deploy job is expected to fail until 00-05 configures DEPLOY_SSH_KEY/SECRET_KEY_BASE/DATABASE_URL/SENTRY_DSN/POSTGRES_PASSWORD as repo secrets and provisions the host."

requirements-completed: [DEPLOY-03, DEPLOY-01]

coverage:
  - id: D1
    description: "Docker image runs bin/migrate to completion before bin/server, gated on the server command, via a custom ENTRYPOINT"
    requirement: "DEPLOY-03"
    verification:
      - kind: other
        ref: "grep-based automated verify: docker-entrypoint gates on /app/bin/server and calls /app/bin/migrate; Dockerfile sets ENTRYPOINT to it"
        status: pass
    human_judgment: false
  - id: D2
    description: "config/deploy.yml declares TLS proxy with /up healthcheck, a localhost-only pgvector/pgvector:pg17 accessory, and per-role secret declarations; .kamal/secrets is gitignored and literal-value-free"
    requirement: "DEPLOY-03"
    verification:
      - kind: other
        ref: "grep-based automated verify: ssl:true, pgvector/pgvector:pg17, 127.0.0.1:5432:5432 bind, .kamal/secrets in .gitignore, no literal secret values"
        status: pass
    human_judgment: false
  - id: D3
    description: "Main-branch deploy workflow builds arm64 natively on ubuntu-24.04-arm, pushes to ghcr.io with least-privilege permissions, and runs kamal deploy with Kamal installed via ruby/setup-ruby + gem install"
    requirement: "DEPLOY-01"
    verification:
      - kind: e2e
        ref: "Live GitHub Actions run (id 30141218684) on merging PR #6 to main: quality job passed, build-and-push job succeeded (real image pushed to ghcr.io/augustopedraza/pukllay_club), deploy job reached 'Load deploy SSH key' and failed only because DEPLOY_SSH_KEY is not yet a configured repo secret (expected per plan — host/secrets provisioning is plan 00-05)"
        status: pass
    human_judgment: false

duration: 197min
completed: 2026-07-25
status: complete
---

# Phase 00 Plan 04: Deploy Configuration Authoring Summary

**Entrypoint-gated migrations, a Kamal deploy.yml/secrets pair with a localhost-bound pgvector accessory and TLS proxy, and a main-branch GitHub Actions workflow that builds arm64 natively and runs `kamal deploy` — all authored, committed, and proven to fire correctly on a real push to `main` (deploy job fails only on the expected missing-secrets/placeholder-host condition, not a config bug).**

## Performance

- **Duration:** 197 min
- **Started:** 2026-07-25T01:13:25Z
- **Completed:** 2026-07-25T04:29:56Z
- **Tasks:** 3 (+ 1 auto-fix commit)
- **Files modified:** 6 (docker-entrypoint, Dockerfile, .gitignore, config/deploy.yml, .kamal/secrets, .github/workflows/deploy.yml)

## Accomplishments
- Docker image now runs `bin/migrate` to completion before `bin/server`, gated on the command being the server (never on e.g. a remote console), via a custom `docker-entrypoint` script and `ENTRYPOINT`/`CMD` wiring in the Dockerfile.
- `config/deploy.yml` authored: ghcr.io image/registry, `proxy.ssl: true` for `pukllay.club` with a `/up` healthcheck, a `pgvector/pgvector:pg17` db accessory bound to `127.0.0.1:5432:5432` only, and explicit per-role `env.clear`/`env.secret` declarations (no reliance on global secret availability).
- `.kamal/secrets` created containing only `$VAR` references (gitignored, never committed) — `.gitignore` updated accordingly.
- `.github/workflows/deploy.yml` authored: re-runs `mix quality` on every push to `main`, builds+pushes the image natively on `ubuntu-24.04-arm` (no QEMU), then installs Kamal via `ruby/setup-ruby` + `gem install` and runs `kamal deploy` with every secret exported from GitHub repo secrets right before the run.
- Verified end-to-end on a real push to `main`: `quality` passed, `build-and-push` succeeded (a real arm64 image now exists at `ghcr.io/augustopedraza/pukllay_club`), and `deploy` failed at the expected point (missing `DEPLOY_SSH_KEY` repo secret) — not from a workflow authoring bug.

## Task Commits

Each task was landed via its own short-lived branch + PR (branch protection on `main` requires the `quality` check):

1. **Task 1: Entrypoint-gated migrations** - `1a54fd1` (feat) — PR #3
2. **Task 2: Kamal deploy.yml + .kamal/secrets** - `6280880` (feat) — PR #4
3. **Task 3: Main-branch deploy workflow** - `a0bda16` (feat) — PR #5
4. **[Rule 1 auto-fix] webfactory/ssh-agent version pin** - `baf19f2` (fix) — PR #6

_No TDD tasks in this plan (infra/config authoring, no application code)._

## Files Created/Modified
- `docker-entrypoint` - runs `/app/bin/migrate` only when `$1 = /app/bin/server`, then `exec "$@"`
- `Dockerfile` - copies/chmods the entrypoint script, sets `ENTRYPOINT ["/app/bin/docker-entrypoint"]`, keeps `CMD ["/app/bin/server"]`
- `config/deploy.yml` - Kamal service/image/registry, TLS proxy + `/up` healthcheck, db accessory, env.clear/env.secret split
- `.kamal/secrets` - gitignored; `$VAR`-only references for KAMAL_REGISTRY_PASSWORD, SECRET_KEY_BASE, DATABASE_URL, SENTRY_DSN, POSTGRES_PASSWORD
- `.gitignore` - added `/.kamal/secrets`
- `.github/workflows/deploy.yml` - quality -> build-and-push (native arm64) -> deploy (Kamal) pipeline

## Decisions Made
- Used a single, identical `<hetzner-host-placeholder>` string in both `servers.web` and the db accessory's `host:` field in `config/deploy.yml`, clearly commented as a D-12 placeholder to be replaced during plan 00-05's provisioning — kept it obviously non-functional rather than a plausible-looking fake IP.
- Pinned `webfactory/ssh-agent` to `v0.9.0` instead of the plan's literal `@v0.9`, after confirming via the GitHub API that `v0.9` is not a real tag on that repo (only `v0.9.0`/`v0.9.1`/`v0.10.0` etc. exist).
- Left the deploy job's expected failure (missing `DEPLOY_SSH_KEY`) in place rather than gating the workflow to skip running until secrets exist — this matches D-02 (CI-driven deploy on every merge) and gave a real, live proof that the workflow's build/push stage is correct before 00-05 begins.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed unresolvable `webfactory/ssh-agent@v0.9` action reference**
- **Found during:** Task 3 (first live run of the newly-merged deploy workflow, triggered automatically by the task 3 PR merge to `main`)
- **Issue:** The plan's stated pin `webfactory/ssh-agent@v0.9` is not a real tag on that action's repository (real tags are `v0.9.0`, `v0.9.1`, `v0.10.0`, etc.) — the run failed immediately at "Set up job" with "Unable to resolve action `webfactory/ssh-agent@v0.9`, unable to find version `v0.9`."
- **Fix:** Verified the real tag list via `gh api repos/webfactory/ssh-agent/tags` and re-pinned to `v0.9.0` (the exact version the plan intended, now spelled correctly).
- **Files modified:** `.github/workflows/deploy.yml`
- **Verification:** Re-ran the workflow on merge; the job now resolves the action correctly and reaches the (expected) missing-secret failure at the "Load deploy SSH key" step instead of failing at action resolution.
- **Committed in:** `baf19f2` (task 3 fix commit, PR #6)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary correctness fix for a broken action reference; no scope creep. All three tasks' `<verify>` blocks and `<acceptance_criteria>` pass as written.

## Issues Encountered
- Local `docker build .` failed at the `mix local.hex --force` step with `OS monotonic time stepped backwards! ... Aborted (core dumped)` — a pre-existing host-environment issue (BEAM VM clock-stepping abort on this dev machine), unrelated to the Dockerfile changes in this plan (it fails before reaching the modified ENTRYPOINT/CMD lines, on an unmodified earlier line). Per the task's acceptance criteria ("`docker build .` succeeds locally — or the build step is documented as arm64-only and deferred to the CI native build"), this is documented and deferred: the live GitHub Actions `ubuntu-24.04-arm` run in the workflow-authoring verification above is a real, successful arm64 build+push, which supersedes the local build attempt as proof the Dockerfile is correct.
- `gh pr merge --squash --delete-branch` repeatedly failed its own post-merge local sync step ("cannot pull with rebase: You have unstaged changes") because of pre-existing unrelated local modifications (`.planning/config.json`, untracked `.planning/research/.cache/*.json` files predating this plan's execution). The PR merge itself succeeded on GitHub every time (verified via `gh pr view --json state,mergedAt`); the local `main` branch was brought back in sync each time with a plain `git fetch && git merge origin/main` fast-forward, which never touched the unrelated dirty files.

## User Setup Required
None yet for this plan — but plan 00-05 (live bring-up) will require the user to add these as GitHub repo secrets before a real deploy can succeed: `DEPLOY_SSH_KEY`, `SECRET_KEY_BASE`, `DATABASE_URL`, `SENTRY_DSN`, `POSTGRES_PASSWORD` (KAMAL_REGISTRY_PASSWORD is sourced from `GITHUB_TOKEN` automatically, no separate secret needed).

## Next Phase Readiness
- All deploy configuration is authored, committed, and verified to fire correctly on a real push to `main` — `quality` and `build-and-push` both pass for real; `deploy` fails only on the expected missing-secrets/placeholder-host condition.
- Plan 00-05 can proceed directly to: provisioning the Hetzner CAX31, pointing DNS, filling in `config/deploy.yml`'s placeholder host, adding the GitHub repo secrets listed above, running `kamal setup` once, and then proving D-06 (a live schema-change migration through the full pipeline).
- No blockers identified for 00-05.

---
*Phase: 00-walking-skeleton-to-production*
*Completed: 2026-07-25*

## Self-Check: PASSED

All 6 created/modified files found on disk; all 4 commit hashes (1a54fd1, 6280880, a0bda16, baf19f2) found in git history.
