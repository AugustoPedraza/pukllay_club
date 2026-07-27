---
phase: 00-walking-skeleton-to-production
plan: 06
subsystem: infra
tags: [github-actions, backup, postgres, cloudflare-r2, kamal, pg_dump]

# Dependency graph
requires:
  - phase: 00-05
    provides: "Live production host (GCP e2-micro, deploy@34.41.63.138), the `db` Kamal accessory container, DEPLOY_SSH_KEY/DEPLOY_HOST GitHub secrets"
provides:
  - "Nightly GitHub Actions workflow (.github/workflows/backup.yml) that dumps the production Postgres accessory and uploads a gzipped dump to Cloudflare R2"
  - "workflow_dispatch manual-trigger path, proven end-to-end with a real dump landing in R2"
affects: []

# Tech tracking
tech-stack:
  added: ["aws-cli (R2 upload, S3-compatible endpoint)", "webfactory/ssh-agent@v0.9.0 (reused from deploy.yml)"]
  patterns: ["Transient credential injection: R2/SSH/DB secrets exported into the CI job env only, never written to host disk (D-08 pattern extended to backups)"]

key-files:
  created: [".github/workflows/backup.yml"]
  modified: []

key-decisions:
  - "Backup mechanism: scheduled GitHub Actions workflow over SSH, not a host systemd/cron timer (assumption_delta_decision in 00-06-PLAN.md) — keeps R2 credentials in GitHub secrets (D-08 consistency) instead of persisting them on host disk. Reversible choice, not a one-way door."
  - "ACCEPTED RISK (per orchestrator/user decision, matching CONTEXT.md D-19 flag): GitHub auto-disables `schedule:`-triggered workflows after 60 days of repo inactivity on public repos. No keepalive workflow was added — the project has several more phases of active planned development, making a 60-day commit gap unlikely. This is a deliberate accept, not an oversight; documented here per D-19's explicit forward-flag to this plan."
  - "aws-cli availability is checked and installed on-demand in the workflow rather than assumed present on ubuntu-latest (00-RESEARCH.md Open Question 2) — de-risks a silent 'command not found' failure mode."

requirements-completed: [DEPLOY-04]

coverage:
  - id: D1
    description: "Nightly pg_dump backup pipeline: scheduled + manually-triggerable GitHub Actions workflow dumps the production `db` accessory and uploads a gzipped dump to Cloudflare R2"
    requirement: "DEPLOY-04"
    verification:
      - kind: manual_procedural
        ref: "gh workflow run backup.yml -> run 30290793407 (all steps green: SSH load, aws-cli check, dump, upload); user confirmed object `backup-2026-07-27.sql.gz` (936 B) present in the Cloudflare R2 `pukllay-backups` bucket dashboard, matching the CLI-reported upload size and timestamp exactly"
        status: pass
    human_judgment: true
    rationale: "Confirming the object actually exists (and is not just a CLI-reported success) in the Cloudflare R2 bucket requires dashboard/credential access the CI job and executor environment do not have — per the plan's explicit prohibition, 'upload succeeded' is not proof of 'backup is good' on its own. The user performed this check directly against the R2 dashboard."

duration: 20min
completed: 2026-07-27
status: complete
---

# Phase 0 Plan 6: Nightly Postgres Backup to Cloudflare R2 Summary

**Nightly + manually-triggerable GitHub Actions workflow that SSHes into the production host, dumps the `db` Kamal accessory via `pg_dump | gzip`, and uploads to Cloudflare R2 via `aws s3 cp --endpoint-url` — proven end-to-end with a real dump verified in the R2 dashboard (DEPLOY-04, the last open Phase 0 requirement).**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-27T17:37:00Z (R2 secrets confirmed present via `gh secret list`)
- **Completed:** 2026-07-27T17:49:32Z
- **Tasks:** 2 (1 auto + 1 checkpoint:human-verify)
- **Files modified:** 1

## Accomplishments
- Authored `.github/workflows/backup.yml`: `schedule` cron (nightly, 08:00 UTC) + `workflow_dispatch`, reusing the `webfactory/ssh-agent` + `DEPLOY_SSH_KEY`/`DEPLOY_HOST` pattern established in `deploy.yml` (plan 00-05)
- Targeted the exact `db` accessory container name (confirmed against `config/deploy.yml`'s explicit `service: db` override), ran as `sudo docker exec` since the `deploy` SSH user is non-root
- Uploaded the compressed dump to the exact `pukllay-backups` R2 bucket via `aws s3 cp --endpoint-url "$R2_ENDPOINT"`, with R2 credentials exported from GitHub secrets into the step env only (D-08 pattern)
- Landed the workflow on `main` via branch + PR #21 (branch protection requires the `quality` check — no bare push)
- Manually triggered the workflow (`gh workflow run backup.yml`) and confirmed the run succeeded end-to-end; user independently confirmed the resulting object (`backup-2026-07-27.sql.gz`, 936 B) in the Cloudflare R2 dashboard, matching the CLI-reported upload exactly
- DEPLOY-04 satisfied — this was the last open requirement in Phase 0

## Task Commits

Each task was committed atomically:

1. **Task 1: Author the nightly backup workflow (pg_dump -> gzip -> R2)** - `b1ca0a3` (feat), merged to `main` as `416b668` via PR #21

**Plan metadata:** (pending — this commit)

_Task 2 was a `checkpoint:human-verify` with no code changes — verification only._

## Files Created/Modified
- `.github/workflows/backup.yml` - Nightly + manual-trigger backup workflow: SSH to `deploy@$DEPLOY_HOST`, `sudo docker exec db pg_dump -U postgres pukllay_club_prod | gzip`, `aws s3 cp --endpoint-url` to `s3://pukllay-backups/`

## Decisions Made

- **Backup mechanism:** scheduled GitHub Actions workflow over SSH (research recommendation A3), not a host systemd timer — see `assumption_delta_decision` in `00-06-PLAN.md`. Reversible.
- **60-day auto-disable risk (CONTEXT.md D-19 forward-flag, orchestrator/user-accepted):** GitHub disables `schedule:`-triggered workflows on public repos after 60 days without a repository commit. This project explicitly **accepted this risk as-is** rather than adding a keepalive workflow, consistent with the project's "no gold-plating" pattern — the repo is under active multi-phase development (Phases 1-4 remain), making a 60-day silent gap unlikely. No keepalive mechanism was added. If a future long quiet period is anticipated, re-enable the workflow manually (Actions tab -> re-enable) or add a trivial monthly keepalive commit at that time — not built preemptively here.
- **aws-cli explicit check/install** rather than assuming it's preinstalled on `ubuntu-latest` (00-RESEARCH.md Open Question 2) — a `command -v aws` check with a fallback install via the official AWS CLI v2 installer.
- **PGPASSWORD delivery:** the `POSTGRES_PASSWORD` GitHub secret is interpolated into the SSH command string (single-quoted on the remote side) rather than persisted anywhere — consistent with D-08's "transient injection, never on host disk" pattern already used for R2/SSH credentials.

## Deviations from Plan

None - plan executed exactly as written. The `assumption_delta_decision` (GitHub Actions over host cron) and the 60-day-auto-disable risk acceptance were both pre-flagged in the plan/context and executed as directed, not discovered mid-execution.

## Issues Encountered

None. The `gh pr merge --squash --delete-branch` command's local post-merge `git pull --rebase` step failed due to unrelated pre-existing uncommitted local changes (`.planning/config.json`, research cache files, a stray tmp file — all out of scope for this plan per the deviation-rules scope boundary). Recovered by fetching and fast-forwarding `main` directly (`git fetch && git merge --ff-only origin/main`) without touching those unrelated files. The PR itself merged successfully on GitHub regardless.

## User Setup Required

None for this plan — R2 bucket, R2 API token, and the three R2 GitHub secrets (`R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT`) were already configured by the user before this plan executed (confirmed present via `gh secret list` as the precondition check).

## Next Phase Readiness

- **Phase 0 is now fully complete.** All five Deploy requirements (DEPLOY-01 through DEPLOY-05) are satisfied: live HTTPS deploy, CI-gated zero-downtime Kamal deploys with migrations-on-deploy, nightly backups to R2, and AGENTS.md conventions.
- **Carried-forward operational note:** the accepted 60-day scheduled-workflow auto-disable risk is now live in production — worth a mental note (not an automated alert) if the repo ever goes quiet for an extended stretch between phases.
- **Carried-forward operational note:** a periodic **manual** restore-test of a downloaded R2 backup remains good practice (per the plan's prohibition — "upload succeeded" is not "backup is good") but is intentionally not automated in Phase 0. No later phase currently owns this as a task; flag for Phase 4 (club operations) or an ops-focused follow-up if desired.
- Ready to move to Phase 1 (Catalog v1).

---
*Phase: 00-walking-skeleton-to-production*
*Completed: 2026-07-27*

## Self-Check: PASSED

- FOUND: `.github/workflows/backup.yml`
- FOUND: `.planning/phases/00-walking-skeleton-to-production/00-06-SUMMARY.md`
- FOUND commit: `b1ca0a3` (task commit)
- FOUND commit: `416b668` (merged to main via PR #21)
