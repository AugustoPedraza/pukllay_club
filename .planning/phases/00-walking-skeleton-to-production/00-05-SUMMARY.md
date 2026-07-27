---
phase: 00-walking-skeleton-to-production
plan: 05
subsystem: infra
tags: [kamal, kamal-proxy, docker, gcp, ghcr, ecto, phoenix, plug-ssl, github-actions]

# Dependency graph
requires:
  - phase: 00-walking-skeleton-to-production (plan 04)
    provides: committed config/deploy.yml, .github/workflows/deploy.yml, and Dockerfile targeting a placeholder host
provides:
  - A live production deployment at https://pukllay.club on a GCP e2-micro host (D-20), reachable over HTTPS with a valid Let's Encrypt cert
  - Proven zero-downtime, migration-gated deploys via kamal-proxy + entrypoint-gated bin/migrate (D-05/D-06)
  - A self-healing PukllayClub.Release.createdb/0 bootstrap so a fresh Postgres accessory can be re-provisioned from nothing
  - The full CI -> build -> Kamal pipeline exercised end-to-end multiple times, including one deploy carrying a real schema migration
affects: [phase-1-catalog, phase-4-club-ops, 00-06-nightly-backup]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Kamal accessory `service:` key must be set explicitly when the app needs to resolve it by a specific DNS name (Docker embedded DNS resolves containers by their real container name, not by the accessory's config key)"
    - "kamal-proxy's app_port must match whatever the app actually listens on (Phoenix defaults to 4000, kamal-proxy defaults to 80) — always set proxy.app_port explicitly for Phoenix"
    - "force_ssl must exclude the health-check path (kamal-proxy probes it internally over plain HTTP), or the health check 301s forever and the container never becomes healthy"
    - "bin/migrate (Ecto.Migrator) never creates the database — pair it with a createdb release task (storage_up, tolerant of :already_up) for a self-bootstrapping first deploy"
    - "when CI builds/pushes the image directly (not via `kamal build`), the image needs the `service=<config.service>` Docker label added manually — Kamal's own validate_image check requires it"
    - "Kamal's `image:` config value must NOT include the registry server prefix — `repository` already joins registry.server + image"
    - ".kamal/secrets is gitignored by design (D-08) even though it holds no literal values — CI must write it fresh on the runner every run, and must mkdir -p .kamal first since empty dirs aren't tracked by git"

key-files:
  created:
    - rel/overlays/bin/createdb
    - priv/repo/migrations/20260727154440_create_deploy_proof.exs
  modified:
    - config/deploy.yml
    - .github/workflows/deploy.yml
    - .gitignore
    - lib/pukllay_club/release.ex
    - docker-entrypoint
    - config/prod.exs

key-decisions:
  - "D-20 executed: production host is a GCP e2-micro (x86_64), not the originally-planned Hetzner CAX31 (arm64) — Hetzner/Oracle capacity shortage at provisioning time (see 00-CONTEXT.md D-20 for full rationale, documented before this plan's execution)"
  - "config/deploy.yml wired to the real host (34.41.63.138), ssh.user: deploy (GCP's non-root metadata-SSH model), builder.arch: amd64, proxy.app_port: 4000"
  - ".github/workflows/deploy.yml build-and-push runner switched to ubuntu-latest (x86_64 native build, simpler than the original arm64 cross-build concern)"
  - "kamal setup --skip-push used once for the GCP host's first-time bootstrap, then switched back to kamal deploy --skip-push (D-02 steady state) once confirmed healthy — both verified live"
  - "PukllayClub.Release.createdb/0 added as a permanent, idempotent bootstrap step (not a one-off manual `CREATE DATABASE`) since this project has already had to re-provision its production host once this same phase"

requirements-completed: [DEPLOY-01, DEPLOY-03]

coverage:
  - id: D1
    description: "App is deployed to production at pukllay.club over HTTPS with a placeholder page and /up health endpoint (DEPLOY-01)"
    requirement: "DEPLOY-01"
    verification:
      - kind: manual_procedural
        ref: "Task 2 checkpoint — user confirmed browser load of https://pukllay.club (valid cert), curl -sf /up returning 200, and off-host Postgres connection refused"
        status: pass
    human_judgment: true
    rationale: "Live production infrastructure (real DNS, real TLS cert, real host) — requires a human confirming from their own network, not just automation inside this sandbox"
  - id: D2
    description: "kamal deploy ships a change to production with zero downtime and runs Ecto migrations as part of the deploy (DEPLOY-03/D-06)"
    requirement: "DEPLOY-03"
    verification:
      - kind: manual_procedural
        ref: "Task 3 checkpoint — user confirmed PR #18 merge, Actions run 30281928667, and the migrate-then-boot-then-cutover log ordering plus schema_migrations row on the live host"
        status: pass
    human_judgment: true
    rationale: "D-06 explicitly requires a live proof on real infrastructure, not code review — the user verified the actual deploy logs and database state themselves"

duration: ~50min active execution (spread across a multi-day session with two human-verification checkpoint pauses)
completed: 2026-07-27
status: complete
---

# Phase 0 Plan 5: Production Deploy on GCP + Live D-06 Migration Proof Summary

**Live production Phoenix app at https://pukllay.club on a GCP e2-micro host via Kamal + kamal-proxy, with a real schema migration proven to gate zero-downtime container cutover (D-06)**

## Performance

- **Duration:** ~50 min active execution time (wall clock spanned longer due to two mandatory `checkpoint:human-verify` pauses awaiting the user's own live verification)
- **Started:** 2026-07-25T16:24:23-03:00 (first commit)
- **Completed:** 2026-07-27T13:28:00-03:00 (approx, final verified redeploy)
- **Tasks:** 3 (1 `type="auto"` + 2 `checkpoint:human-verify`, both approved)
- **Files modified:** 8 (2 created, 6 modified)
- **Commits:** 11 substantive commits (10 task/fix commits + 9 merge commits), all landed via branch + PR per branch protection

## Accomplishments

- Wired the real (GCP e2-micro, not the originally-planned Hetzner CAX31 — D-20) production host into `config/deploy.yml` and `.github/workflows/deploy.yml`
- Bootstrapped the host for the first time via `kamal setup --skip-push`, then confirmed healthy and switched the pipeline to the steady-state `kamal deploy --skip-push` (D-02)
- `https://pukllay.club` is live: stock Phoenix welcome page over HTTPS with a valid Let's Encrypt cert, `/up` returns 200
- Postgres accessory (`db`) confirmed bound to `127.0.0.1:5432` only — off-host connection attempts refused (D-15 held)
- Shipped a real trivial schema migration (`create table(:deploy_proof)`) through the full CI → build → Kamal pipeline and proved, from live container logs and `schema_migrations`, that migration success gates the health check which gates the zero-downtime container swap (D-05/D-06)
- Added a self-healing database-creation bootstrap (`PukllayClub.Release.createdb/0`) so any future re-provisioning of the Postgres accessory (this project has already had to move providers once this phase) doesn't require a manual `CREATE DATABASE` step

## Task Commits

Task 1 required 8 additional fix commits beyond the initial wiring commit — every one of the 9 commits below is a genuine correctness fix discovered only by attempting a real deploy against real infrastructure, not speculative hardening:

1. **Task 1: Wire host + first-time Kamal setup** — `1faa7c0` (feat)
2. **Task 1 fix: Kamal `builder.arch` required + image-tag alignment for `--skip-push`** — `94c4ba2` (fix)
3. **Task 1 fix: `.kamal/secrets` missing on fresh CI checkout** — `0efed4c` (fix)
4. **Task 1 fix: `.kamal/` directory doesn't exist in a fresh checkout** — `c8e33d7` (fix)
5. **Task 1 fix: double-prefixed image path + missing `service` label** — `372eba2` (fix)
6. **Task 1 fix: `db` accessory container name didn't match `DATABASE_URL` hostname** — `5c1c58e` (fix)
7. **Task 1 fix: `bin/migrate` never creates the database — added self-healing `createdb`** — `b2e284d` (feat)
8. **Task 1 fix: kamal-proxy defaulted to port 80; Phoenix listens on 4000** — `f8d8c57` (fix)
9. **Task 1 fix: `force_ssl` 301-redirected kamal-proxy's own `/up` probe** — `e83e0b4` (fix)
10. **Task 3: D-06 live migration proof — `deploy_proof` migration** — `f4059fb` (test)
11. **Post-verification cleanup: switch deploy step back to steady-state `kamal deploy`** — `4f017db` (chore)

Every commit above landed to `main` via its own short-lived branch + PR (`gh pr create` → `quality` CI check → `gh pr merge`), per branch protection (00-03/D-19). Merge commits: `bffeb27`, `fb9d490`, `0f072de`, `d1d57e8`, `52c496c`, `83e9b53`, `556b332`, `d535f2a`, `da51d51`, `084b40e`, `47b2e1b`.

**Task 2** (live HTTPS + `/up` + localhost-only Postgres) required no code changes — verification only, approved by the user.

**Plan metadata:** this commit (docs: complete 00-05 plan)

## Files Created/Modified

- `config/deploy.yml` — real GCP host wired in (`servers.web`, accessory `db.host`), `ssh.user: deploy`, `builder.arch: amd64`, `image:` corrected (no registry prefix), `accessories.db.service: db`, `proxy.app_port: 4000`
- `.github/workflows/deploy.yml` — `build-and-push` runner switched to `ubuntu-latest` (x86_64, D-20 supersedes D-01's arm64 runner); image tagged with the plain full-length git SHA (`type=sha,format=long,prefix=`) to match Kamal's computed version; `service=pukllay_club` label added to the externally-built image; `.kamal/secrets` written fresh on the CI runner (`mkdir -p .kamal` + heredoc) since it's gitignored by design; deploy step uses `kamal deploy --skip-push` (was `kamal setup --skip-push` for the one-time bootstrap)
- `.gitignore` — clarified comment on why `.kamal/secrets` stays gitignored and how CI regenerates it
- `lib/pukllay_club/release.ex` — added `PukllayClub.Release.createdb/0` (standard Ecto `storage_up`/`:already_up` idiom)
- `docker-entrypoint` — calls `/app/bin/createdb` before `/app/bin/migrate`
- `rel/overlays/bin/createdb` (new) — release overlay script invoking `PukllayClub.Release.createdb`
- `config/prod.exs` — `force_ssl` now excludes `paths: ["/up"]` so kamal-proxy's internal, non-forwarded health-check probe isn't redirected
- `priv/repo/migrations/20260727154440_create_deploy_proof.exs` (new) — trivial D-06 proof migration, never read by application code

## Decisions Made

- **D-20 (executed, documented before this plan by a prior commit):** production host is GCP e2-micro (x86_64), not Hetzner CAX31 (arm64) — see `00-CONTEXT.md` for full capacity-shortage rationale. This plan's execution consumed that decision: wired the real IP, added `ssh.user: deploy`, switched the build runner to `ubuntu-latest`.
- **Kamal `builder.arch` is mandatory even when CI never uses `kamal build`** — Kamal's config validator rejects a missing `arch` unconditionally, regardless of `--skip-push`. Set to `amd64` to match the real host.
- **`--skip-push` chosen over letting Kamal build** — the project's CI already builds+pushes via `docker/build-push-action` (D-01/D-10); Kamal only needs to pull the matching tag. Required aligning the pushed tag format (`type=sha,format=long,prefix=`) to Kamal's own computed `version` (the full git SHA) and adding the `service` label Kamal's own build step normally adds automatically.
- **Accessory `service: db`** — Kamal names accessory containers `<service>-<accessory>` by default; the app's `DATABASE_URL` (a GitHub secret, not something this plan could change) targets hostname `db`, so the accessory config must override its container name to match.
- **`proxy.app_port: 4000`** chosen over setting `PORT=80` — keeps Phoenix's own default port for local/dev parity; only kamal-proxy's target changes.
- **`createdb` added as a permanent release task, not a one-off manual `CREATE DATABASE`** — this project has already had to re-provision its production host once this phase (D-20); a self-healing bootstrap is directly useful, not speculative.
- **`kamal setup` used exactly once, then switched to `kamal deploy`** — matches D-02's steady-state CI-driven design; the one-time bootstrap need doesn't justify keeping the heavier `setup` command in the permanent workflow.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Kamal `builder.arch` not set**
- **Found during:** Task 1, first `kamal setup` attempt
- **Issue:** `Kamal::ConfigurationError: builder: Builder arch not set` — Kamal's validator requires this field even though CI never invokes `kamal build`
- **Fix:** Added `builder: { arch: amd64 }` to `config/deploy.yml`; also aligned the built image's tag to Kamal's computed `version` (full git SHA, no prefix) and added `--skip-push` to the deploy command
- **Files modified:** `config/deploy.yml`, `.github/workflows/deploy.yml`
- **Verification:** Next deploy attempt passed config validation
- **Committed in:** `94c4ba2`

**2. [Rule 3 - Blocking] `.kamal/secrets` missing on fresh CI checkout**
- **Found during:** Task 1, second deploy attempt
- **Issue:** `Secret 'KAMAL_REGISTRY_PASSWORD' not found, no secret files ... provided` — `.kamal/secrets` is gitignored by design (D-08), so a fresh CI checkout never has it
- **Fix:** Added a "Write .kamal/secrets" step that heredocs the `$VAR`-only content (no literal values) fresh on the runner before Kamal runs
- **Files modified:** `.github/workflows/deploy.yml`, `.gitignore` (comment clarification only)
- **Committed in:** `0efed4c`

**3. [Rule 1 - Bug] `.kamal/` directory itself doesn't exist in a fresh checkout**
- **Found during:** Task 1, third deploy attempt
- **Issue:** The new "Write .kamal/secrets" step failed with "No such file or directory" — git doesn't track empty directories
- **Fix:** Added `mkdir -p .kamal` before the heredoc write
- **Files modified:** `.github/workflows/deploy.yml`
- **Committed in:** `c8e33d7`

**4. [Rule 1 - Bug] Double-prefixed image path + missing `service` label**
- **Found during:** Task 1, fourth deploy attempt
- **Issue:** `config/deploy.yml`'s `image:` was `ghcr.io/augustopedraza/pukllay_club`, doubling with `registry.server` to `ghcr.io/ghcr.io/...` (harmless only because GHCR happened to collapse the redundant prefix — confirmed via matching digests, but not something to rely on); separately, the externally-built image was missing the `service` label Kamal's own `validate_image` check requires (normally added automatically by `kamal build`, which this pipeline bypasses)
- **Fix:** Corrected `image:` to `augustopedraza/pukllay_club`; added `service=pukllay_club` to the build's `labels` input
- **Files modified:** `config/deploy.yml`, `.github/workflows/deploy.yml`
- **Committed in:** `372eba2`

**5. [Rule 1 - Bug] `db` accessory container name didn't match `DATABASE_URL` hostname**
- **Found during:** Task 1, fifth deploy attempt
- **Issue:** App failed to boot — `tcp connect (db:5432): non-existing domain - :nxdomain`. Kamal names accessory containers `<service>-<accessory>` by default (`pukllay_club-db`); Docker's embedded DNS resolves containers by their real name, not the accessory's config key; `DATABASE_URL` (a GitHub secret) targets hostname `db`
- **Fix:** Added `service: db` to the accessory config (Kamal's documented key for overriding the container name/label). Also manually removed the stray `pukllay_club-db` container left on the host from the previous attempt (still bound to `127.0.0.1:5432`, would have blocked the new `db` container from claiming that port) — no data loss, first-ever deploy, `pg_data` volume untouched
- **Files modified:** `config/deploy.yml`
- **Committed in:** `5c1c58e`

**6. [Rule 2 - Missing Critical] `bin/migrate` never creates the database**
- **Found during:** Task 1, sixth deploy attempt
- **Issue:** `FATAL 3D000 (invalid_catalog_name) database "pukllay_club_prod" does not exist` — `bin/migrate` (`Ecto.Migrator`) only runs migrations, never creates the database, and the pgvector accessory was a genuinely fresh Postgres instance
- **Fix:** Added `PukllayClub.Release.createdb/0` (standard `storage_up`/`:already_up` idiom) + `bin/createdb` overlay script, called from `docker-entrypoint` right before `bin/migrate`. Deliberately made permanent/self-healing rather than a one-off manual `CREATE DATABASE`, since this project has already had to re-provision its host once this phase (D-20)
- **Files modified:** `lib/pukllay_club/release.ex`, `docker-entrypoint`, `rel/overlays/bin/createdb` (new)
- **Committed in:** `b2e284d`

**7. [Rule 3 - Blocking] kamal-proxy targeted the wrong container port**
- **Found during:** Task 1, seventh deploy attempt
- **Issue:** App booted cleanly (createdb + migrate succeeded, Endpoint logged listening on port 4000), but kamal-proxy reported "target failed to become healthy" — it probes container port 80 by default, while Phoenix's Endpoint listens on `PORT` (default `4000`)
- **Fix:** Set `proxy.app_port: 4000` in `config/deploy.yml`
- **Files modified:** `config/deploy.yml`
- **Committed in:** `f8d8c57`

**8. [Rule 1 - Bug] `force_ssl` redirected kamal-proxy's own health-check probe**
- **Found during:** Task 1, eighth deploy attempt
- **Issue:** Health check still failed — container logs showed "Plug.SSL is redirecting GET /up to https://pukllay.club with status 301" on every probe. kamal-proxy's internal health check hits the app over plain HTTP without `x-forwarded-proto`, so `force_ssl` redirects instead of returning 200. The generated `config/prod.exs` literally has a comment flagging this exact scenario, left commented out by default
- **Fix:** Uncommented/adapted to `exclude: [paths: ["/up"]]` (verified `Plug.SSL`'s `exclude` option supports `paths` against the vendored `deps/plug/lib/plug/ssl.ex`)
- **Files modified:** `config/prod.exs`
- **Committed in:** `e83e0b4`

**9. [Rule 3 - Blocking, self-imposed follow-through] Switch back to steady-state `kamal deploy`**
- **Found during:** Post-Task-3 wrap-up
- **Issue:** The `94c4ba2` commit message promised to switch the deploy step from `kamal setup` (one-time bootstrap) back to `kamal deploy` (D-02 steady state) once the first release was confirmed healthy — this was never followed through until now
- **Fix:** Switched `run: kamal setup --skip-push` to `run: kamal deploy --skip-push`; triggered and verified one more live deploy to confirm the steady-state command works identically
- **Files modified:** `.github/workflows/deploy.yml`
- **Committed in:** `4f017db`

---

**Total deviations:** 9 auto-fixed (5 Rule 1 - bug, 3 Rule 3 - blocking, 1 Rule 2 - missing critical)
**Impact on plan:** Every single deviation was discovered only by attempting a real deploy against real, previously-unprovisioned infrastructure — none were speculative. All were necessary for DEPLOY-01/DEPLOY-03 to actually be true rather than merely configured. No scope creep: the `createdb` addition is the only change that goes beyond "make this specific deploy attempt succeed," and it is directly justified by this project's demonstrated infra volatility (two provider changes in one phase: Hetzner → GCP for the host, this migration-proof deploy exercising a from-scratch database).

## Issues Encountered

- The local sandbox environment's Elixir/Hex toolchain (via `mise`) was broken for a full `mix compile`/`mix format`/`mix credo` run — worked around by validating new/changed Elixir files with `Code.string_to_quoted!/1` locally and relying on the `quality` CI job (which ran the full `mix quality` gate successfully on every PR in this session) as the authoritative check. This is a pre-existing sandbox issue unrelated to the plan's scope and was not "fixed" — CI remained the source of truth throughout.
- `gh pr merge --delete-branch` repeatedly failed its local post-merge cleanup step (`cannot pull with rebase: You have unstaged changes`) due to pre-existing, out-of-scope uncommitted changes in the working tree (`.planning/config.json`, `.planning/research/.cache/*.json`, a stray `.claude/settings.local.json.tmp.*` file — none touched by this plan). The merge itself always succeeded on GitHub in every case; only the local branch cleanup/fast-forward needed a manual `git fetch && git merge --ff-only origin/main` afterward. Documented here rather than "fixed" since these files are out of this plan's scope per the deviation rules' scope boundary.

## User Setup Required

None — all `user_setup` prerequisites (Hetzner CAX31 in the original plan text, superseded by the GCP host per D-20; DNS; GitHub repo secrets) were already completed by the user before this plan ran, per the `critical_infra_deviation` briefing.

## Next Phase Readiness

- DEPLOY-01 and DEPLOY-03 are now genuinely proven live, not just configured — Phase 0's core "walking skeleton to production" goal is met for the deploy pipeline.
- Remaining Phase 0 work: plan 00-06 (nightly `pg_dump` → Cloudflare R2 backup, DEPLOY-04) — the only open Phase 0 requirement.
- The `db` accessory naming pattern (`service: db`), `proxy.app_port: 4000`, and the `force_ssl` `/up` exclusion are now load-bearing production config — future plans that touch `config/deploy.yml` or `config/prod.exs` should preserve them.
- `PukllayClub.Release.createdb/0` means any future host re-provisioning (a real, demonstrated risk for this project) can redeploy from a completely empty Postgres accessory without a manual bootstrap step.
- No blockers for Phase 1 (Catalog) — the production deploy pipeline is proven end-to-end and ready to carry real product code.

## Self-Check: PASSED

All 8 files created/modified (`rel/overlays/bin/createdb`, `priv/repo/migrations/20260727154440_create_deploy_proof.exs`, `config/deploy.yml`, `.github/workflows/deploy.yml`, `lib/pukllay_club/release.ex`, `docker-entrypoint`, `config/prod.exs`, this SUMMARY) confirmed present on disk. All 22 referenced commit hashes (11 task/fix commits + 11 merge commits) confirmed present in `git log --all`.

---
*Phase: 00-walking-skeleton-to-production*
*Completed: 2026-07-27*
