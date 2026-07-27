---
phase: 00-walking-skeleton-to-production
verified: 2026-07-27T22:02:39Z
status: passed
score: 22/22 must-haves verified
behavior_unverified: 0
overrides_applied: 0
mode_note: "ROADMAP.md tags this phase mode: mvp, but the phase goal is an infra/deploy statement, not a User Story ('As a ... I want ... so that ...'). user-story.validate returned valid=false. Since this is a zero-product-code deploy-pipeline phase (explicitly 'no product features' per CONTEXT.md), the MVP-mode User Flow Coverage methodology does not apply — standard goal-backward verification was used instead. Flagging the mode/goal-format mismatch for correction in ROADMAP.md, not as a phase gap."
---

# Phase 0: Walking Skeleton to Production Verification Report

**Phase Goal:** A trivial but real Phoenix app is deployed to production with a proven, repeatable deploy pipeline — no product features, no gold-plating.
**Verified:** 2026-07-27T22:02:39Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | pukllay.club responds over HTTPS with placeholder page and working `/up` (DEPLOY-01, SC1) | VERIFIED | `curl -sf https://pukllay.club/` → 200, body contains "Phoenix Framework"; `curl -sf https://pukllay.club/up` → 200 "OK"; live TLS cert issued by Let's Encrypt (`notAfter=Oct 25 2026`), issuer `C=US, O=Let's Encrypt, CN=YE2` |
| 2 | Every PR runs CI (`mix quality`) against a Postgres service and must pass before merge (DEPLOY-02, SC2) | VERIFIED | `.github/workflows/ci.yml` runs `postgres:17` service + `mix quality` (format→credo→sobelow→test); branch protection on `main` requires `quality` check (`gh api .../branches/main/protection` → `checks:[{context:"quality"}]`, `enforce_admins:true`); live CI run `30304481871` on latest commit `421f988` passed in 39s |
| 3 | `kamal deploy` ships a change with zero downtime and runs Ecto migrations as part of the deploy (DEPLOY-03, SC3) | VERIFIED | `docker-entrypoint` gates `bin/createdb`+`bin/migrate` before `exec bin/server`; D-06 live proof: migration `20260727154440_create_deploy_proof.exs` shipped through full CI→build→Kamal pipeline (run `30281928667`, all 3 jobs green); real deploy job log shows `kamal-proxy deploy pukllay_club-web --health-check-path="/up"` then `First web container is healthy` — cutover is gated on the healthcheck, which cannot pass until migrate/createdb complete inside the entrypoint |
| 4 | A nightly `pg_dump` backup job runs automatically and lands in Cloudflare R2 (DEPLOY-04, SC4) | VERIFIED | `.github/workflows/backup.yml` has `schedule: cron: "0 8 * * *"` + `workflow_dispatch`; live manual-trigger run `30304735080` (today) succeeded, log shows `gzip -t`/`test -s` validation passing and `upload: ./backup-2026-07-27.sql.gz to s3://pukllay-backups/backup-2026-07-27.sql.gz` |
| 5 | AGENTS.md documents TDD loop, `mix quality` alias, manual-merge-gate rule, and non-goals (DEPLOY-05, SC5) | VERIFIED | `AGENTS.md` contains `## TDD Loop`, `## mix quality Alias` (matches `mix.exs` alias order exactly), `## Manual Merge Gate`, `## Non-Goals (Phase 0)` sections |
| 6 | GET /up requires no auth/session/CSRF (00-01) | VERIFIED | `/up` route lives in its own `:health` pipeline outside `:browser`; test asserts no `_pukllay_club_key` session cookie; live curl confirms 200 "OK" plain-text |
| 7 | Stock unmodified Phoenix welcome page at `/` (D-14) | VERIFIED | live curl to `/` returns unmodified `phx.new` welcome markup ("Phoenix Framework") |
| 8 | mise.toml pins Elixir 1.19.x / Erlang 28.x (D-16) | VERIFIED | `mise.toml`: `elixir = "1.19.5-otp-28"`, `erlang = "28.5"`; matches `erlef/setup-beam` pins in `ci.yml`/`deploy.yml` |
| 9 | Sentry wired via `Sentry.LoggerHandler`, DSN from `SENTRY_DSN` env, stdout Logger retained (D-17/D-18) | VERIFIED | `application.ex` calls `:logger.add_handler(..., Sentry.LoggerHandler, ...)`; `config/runtime.exs` reads `SENTRY_DSN` env var; no Logger backend removed |
| 10 | OTP release boots with full default supervision tree (D-15) | VERIFIED | `application.ex` children list is the unmodified `phx.new` default (Telemetry, Repo, DNSCluster, PubSub, Endpoint) |
| 11 | `mix quality` alias order: format→credo→sobelow→test (cheapest first) | VERIFIED | `mix.exs` `aliases/0`: `quality: ["format --check-formatted", "credo --strict", "sobelow --config", "test --warnings-as-errors"]` |
| 12 | `phx.gen.release --docker` artifacts exist (Dockerfile, bin/migrate, release.ex wrapping Ecto.Migrator) | VERIFIED | `Dockerfile` multi-stage (debian:trixie-slim runner, not Alpine); `lib/pukllay_club/release.ex` wraps `Ecto.Migrator.with_repo/2`, no Mix dependency |
| 13 | CI caches on `mix.lock` hash, runs on `ubuntu-latest` (D-04/CONTEXT.md discretion) | VERIFIED | `ci.yml`/`deploy.yml`: `key: ...${{ hashFiles('**/mix.lock') }}`, `runs-on: ubuntu-latest` |
| 14 | Custom Docker ENTRYPOINT runs migrations before server boot, gated on server command (D-05) | VERIFIED | `docker-entrypoint`: `if [ "$1" = "/app/bin/server" ]; then /app/bin/createdb; /app/bin/migrate; fi; exec "$@"` |
| 15 | `deploy.yml` declares ghcr.io image, arm64/amd64 server config, TLS proxy + `/up` healthcheck, localhost-bound pgvector accessory (D-15, adjusted per D-20) | VERIFIED | `config/deploy.yml`: `proxy.ssl:true`, `proxy.healthcheck.path:/up`, `accessories.db.image: pgvector/pgvector:pg17`, `port: "127.0.0.1:5432:5432"` — note: `builder.arch: amd64` (D-20 GCP pivot supersedes original arm64 plan, documented and approved in CONTEXT.md D-20, not a gap) |
| 16 | `.kamal/secrets` contains only `$VAR` references, gitignored, no literal values (D-08) | VERIFIED | `git ls-files .kamal/` returns nothing (untracked); `.gitignore` has `/.kamal/secrets`; local file content is `$VAR=$VAR` pairs only |
| 17 | Postgres accessory reachable only on 127.0.0.1 on the live host (D-15) | VERIFIED | live off-host TCP probe to `34.41.63.138:5432` timed out/refused |
| 18 | Deploy workflow builds natively, pushes to ghcr.io via `GITHUB_TOKEN`, runs `kamal deploy` (D-01/D-02/D-03/D-10, adjusted per D-20) | VERIFIED | `deploy.yml build-and-push` job builds on `ubuntu-latest` (native x86_64 per D-20 GCP pivot), pushes via `docker/build-push-action`, `deploy` job runs `kamal deploy --skip-push` |
| 19 | Deploy job re-runs `mix quality` before build/deploy (D-04) | VERIFIED | `deploy.yml` `quality` job (identical gate) runs before `build-and-push`/`deploy` |
| 20 | Deploy job's `GITHUB_TOKEN` has `packages: read` so Kamal can pull the image (post-review fix, CR-01) | VERIFIED | `deploy.yml` `deploy:` job has explicit `permissions: {contents: read, packages: read}`; live run `30304481495`'s `deploy` job succeeded (previously would have failed here per 00-REVIEW.md CR-01) |
| 21 | Nightly backup pipeline fails loudly on a broken/empty dump instead of silently uploading it (post-review fix, CR-02) | VERIFIED | `backup.yml` wraps remote pipeline in `bash -c 'set -o pipefail; ...'` + `gzip -t`/`test -s` validation; visible in live run `30304735080` log |
| 22 | Backup password never appears as a `docker exec -e` command-line argument (post-review fix, WR-01) | VERIFIED | `backup.yml` sends password via SSH stdin heredoc (`<<< "PGPASSWORD=$POSTGRES_PASSWORD"`) into a remote `mktemp`+`chmod 600` env file, read via `docker exec --env-file`, never as a `-e` arg |

**Score:** 22/22 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/pukllay_club_web/controllers/health_controller.ex` | `/up` returns 200 plain-text | VERIFIED | present, substantive, wired via router `:health` pipeline, live-curl confirmed |
| `test/pukllay_club_web/controllers/health_controller_test.exs` | Unit tests for `/up` | VERIFIED | 2 real assertions (200/body, no session cookie); passes in CI |
| `mise.toml` | Elixir/Erlang pins | VERIFIED | present, correct pins |
| `mix.exs` | `quality` alias, deps | VERIFIED | present, alias matches order |
| `Dockerfile` | Multi-stage release build | VERIFIED | debian:trixie-slim, ENTRYPOINT/CMD wired |
| `rel/overlays/bin/migrate`, `rel/overlays/bin/createdb` | Release migration/db-bootstrap scripts | VERIFIED | present, invoked from `docker-entrypoint` |
| `lib/pukllay_club/release.ex` | `Ecto.Migrator`/`storage_up` wrapper | VERIFIED | `migrate/0`, `createdb/0`, `rollback/2` all present, no Mix dependency |
| `.credo.exs` / `.sobelow-conf` | Quality-gate configs | VERIFIED | present with dated, reviewed exceptions (not blanket-disabled) |
| `AGENTS.md` | Phase 0 conventions doc | VERIFIED | 4 required sections present |
| `.github/workflows/ci.yml` | PR quality gate | VERIFIED | present, wired, live-passing |
| `.github/workflows/deploy.yml` | Build+push+deploy pipeline | VERIFIED | present, wired, live-passing (all 3 jobs) |
| `.github/workflows/backup.yml` | Nightly R2 backup | VERIFIED | present, wired, live-passing |
| `config/deploy.yml` | Kamal service config | VERIFIED | present, points at real live host `34.41.63.138` |
| `.kamal/secrets` | Gitignored secrets template | VERIFIED | present locally, untracked, `$VAR`-only |
| `docker-entrypoint` | Migration-gating entrypoint | VERIFIED | present, correct gating logic |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `/up` route | Kamal health probe | `router.ex` `:health` pipeline, `config/deploy.yml` `proxy.healthcheck.path: /up` | WIRED | Confirmed both in config and live: kamal-proxy log shows `--health-check-path="/up"` and `First web container is healthy` |
| `SENTRY_DSN` GitHub secret | release runtime env | `.kamal/secrets` → `deploy.yml` env export → `config/runtime.exs` | WIRED | `deploy.yml` exports `SENTRY_DSN` from `secrets.SENTRY_DSN`; declared in `config/deploy.yml env.secret`; consumed in `runtime.exs` |
| `docker-entrypoint` | `bin/migrate`/`bin/createdb` | gated on `$1 = /app/bin/server` | WIRED | Verified file content; live deploy log shows app booting successfully after this gate on every recent deploy |
| CI check name (`quality`) | branch protection required check | GitHub branch protection API | WIRED | `required_status_checks.checks = [{context:"quality"}]`, matches job name in both `ci.yml` and `deploy.yml` |
| `deploy.yml` `deploy` job | ghcr.io image pull | `permissions.packages: read` + `KAMAL_REGISTRY_PASSWORD: secrets.GITHUB_TOKEN` | WIRED | CR-01 fix confirmed present; live run succeeded end-to-end |
| `backup.yml` | `db` Kamal accessory | `sudo docker exec ... db bash -c '...pg_dump...'` | WIRED | matches `config/deploy.yml`'s `accessories.db.service: db` override; live run succeeded |
| `backup.yml` | Cloudflare R2 | `aws s3 cp --endpoint-url $R2_ENDPOINT` | WIRED | live run shows real object uploaded to `s3://pukllay-backups/` |

### Behavioral Spot-Checks (Live Production Infra)

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Production HTTPS root | `curl -sf https://pukllay.club/` | HTTP 200, "Phoenix Framework" body | PASS |
| Production health endpoint | `curl -sf https://pukllay.club/up` | HTTP 200 "OK" | PASS |
| Valid TLS cert | `openssl s_client ... | openssl x509 -dates` | Let's Encrypt cert, valid through Oct 25 2026 | PASS |
| Postgres not internet-reachable | `/dev/tcp/34.41.63.138/5432` | Refused/timeout | PASS |
| Branch protection active | `gh api .../branches/main/protection` | `quality` required, `enforce_admins: true` | PASS |
| Latest CI run (commit `421f988`) | `gh run view 30304481871` | `quality` job passed (39s) | PASS |
| Latest Deploy run (commit `421f988`) | `gh run view 30304481495` | `quality`, `build-and-push`, `deploy` all passed | PASS |
| D-06 migration-proof deploy | `gh run view 30281928667` + job log grep | All 3 jobs green; kamal-proxy log shows health-check-gated cutover | PASS |
| Nightly backup manual trigger | `gh run view 30304735080` + job log grep | `gzip -t`/`test -s` passed; real R2 upload confirmed in log | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DEPLOY-01 | 00-01, 00-04, 00-05 | Deployed to production over HTTPS, placeholder page + `/up` | SATISFIED | Live curl checks pass |
| DEPLOY-02 | 00-03 | CI runs `mix quality` on every PR, Postgres service, merge gate | SATISFIED | ci.yml + branch protection + live runs |
| DEPLOY-03 | 00-04, 00-05 | `kamal deploy` zero-downtime + migrations-on-deploy | SATISFIED | D-06 live proof, entrypoint gating, kamal-proxy health-check log |
| DEPLOY-04 | 00-06 | Nightly `pg_dump` → Cloudflare R2 | SATISFIED | backup.yml schedule + live manual-trigger upload confirmed |
| DEPLOY-05 | 00-02 | AGENTS.md conventions doc | SATISFIED | All 4 required sections present, content matches actual `mix.exs`/CI config |

No orphaned requirements — all 5 Deploy requirements from REQUIREMENTS.md are claimed across the phase's plans and match the phase's roadmap entry.

### Anti-Patterns Found

None blocking. No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK` markers found in any phase-modified file. The two code-review BLOCKER findings (CR-01: missing `packages: read` on the deploy job; CR-02: silent-empty-backup risk) were found by `00-REVIEW.md`, fixed in commits `165bed9`/`8af075d`, and independently confirmed here via live re-execution of the affected workflows on the current `main` HEAD — both fixes are present and functioning, not just claimed.

Three INFO-level findings from `00-REVIEW.md` remain unaddressed by design (out of fix-pass scope, non-blocking): CI/deploy workflow job duplication (IN-01), floating-tag Action pins other than `webfactory/ssh-agent` (IN-02), and a stock/unedited `README.md` (IN-03). None of these affect the phase's must-haves or observable truths — noted for awareness, not gaps.

One accepted, explicitly-documented risk carried forward: production DB traffic between the app and `db` accessory containers is unencrypted (`ssl: true` commented out in `config/runtime.exs`, WR-04) — reviewed and accepted as low-risk for a single-tenant host, with a code comment recording the rationale and revisit condition. Not a gap; a documented, in-scope decision.

### Human Verification Required

None. All must-haves were verifiable via direct codebase inspection, GitHub API queries, and live production curl/TCP checks — no items required subjective human judgment beyond what plans 00-05/00-06 already had the actual project owner perform and record (D-06 live migration proof, R2 dashboard object confirmation), which this verification independently corroborated via GitHub Actions job logs.

### Gaps Summary

No gaps found. All 5 roadmap Success Criteria and all plan-level must-haves across 00-01 through 00-06 are verified against the live codebase and live production infrastructure (https://pukllay.club, GCP e2-micro host, GitHub Actions runs, Cloudflare R2). The two BLOCKER-level code-review findings raised in `00-REVIEW.md` were fixed and the fixes were independently confirmed working via fresh live workflow runs on the current `main` HEAD, not just re-read from the SUMMARY/REVIEW-FIX narrative.

One process note (not a gap): ROADMAP.md tags this phase `mode: mvp`, but its goal is phrased as an infra statement rather than a User Story, and `user-story.validate` correctly rejects it. Since Phase 0 is explicitly scoped as zero-product-code deploy-pipeline work (CONTEXT.md: "No catalog, no auth, no AI/embeddings/Oban/BGG"), MVP User Flow Coverage verification does not meaningfully apply here; standard goal-backward verification (roadmap Success Criteria + PLAN must_haves) was used instead. Recommend either removing `mode: mvp` from infra-only phases in future roadmaps or accepting this as an intentional exception for Phase 0.

---

_Verified: 2026-07-27T22:02:39Z_
_Verifier: Claude (gsd-verifier)_
