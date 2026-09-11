# Phase 0: Walking Skeleton to Production - Research

**Researched:** 2026-07-24
**Domain:** Elixir/Phoenix deploy pipeline — Docker (native arm64) + Kamal 2 + GitHub Actions CI/CD + Cloudflare R2 backups + Sentry, targeting a not-yet-provisioned Hetzner CAX31
**Confidence:** MEDIUM (stack versions and core patterns are well-documented; several exact syntax details come from single-source WebFetch/WebSearch lookups against official docs and are flagged accordingly — see Sources)

## Summary

Phase 0 has no product code — it is entirely infrastructure and pipeline plumbing. The project's
`.claude/CLAUDE.md` "Technology Stack" section already resolved the three big architecture
questions (native arm64 build, entrypoint-gated migrations, GitHub-Actions-secrets-as-source), and
`00-CONTEXT.md` locked in the specific decisions (D-01 through D-18). This research fills the
remaining gap: **exact syntax and concrete gotchas** for the five pieces that must be assembled —
(1) a GitHub Actions workflow that builds natively on `ubuntu-24.04-arm`, pushes to ghcr.io, and
runs `kamal deploy` from CI; (2) the precise `.kamal/secrets` / `deploy.yml` `env.clear`/`env.secret`
shape that sources values from GitHub repo secrets with nothing ever written to git; (3) `mise.toml`
syntax for pinning Elixir + Erlang/OTP as mise's built-in core plugins; (4) `sentry-elixir` 13.3.0
setup; (5) the nightly `pg_dump`→R2 mechanism, where CONTEXT.md left the choice open.

The single most load-bearing new finding: **Phoenix does NOT generate a `/up` route by default** —
neither `mix phx.new` nor `mix phx.gen.release --docker` ships one. DEPLOY-01's health endpoint
must be hand-added as a plain, unauthenticated route ahead of any browser/CSRF pipeline, or Kamal's
health check (and this whole phase's success criterion #1) will fail silently or hang. This is a
concrete planning action item, not just "verify it's there."

The second load-bearing finding: **Kamal is a Ruby gem** — it does not exist in this repo's runtime
(Elixir) or in this dev machine's toolchain (no Ruby/gem installed). The CI workflow needs its own
`ruby/setup-ruby` + `gem install kamal` step (or a pinned Kamal Docker action) before `kamal deploy`
can run; this must be a workflow step, not an assumption.

Third: the CONTEXT.md-mandated backup-mechanism discretion is resolved here in favor of a
**scheduled GitHub Actions workflow that SSHes into the host**, not a host systemd timer — this is
the option most consistent with D-08's already-locked "R2 keys live as GitHub repo secrets" pattern
and keeps R2 credentials off the host's disk entirely (they're injected transiently into the SSH
session each night). **UPDATE (00-03 execution, see 00-CONTEXT.md D-19): the repo was flipped from
private to public during 00-03 to unlock GitHub Free branch protection, so the "60-day inactivity
auto-disable does not apply to private repos" reasoning below no longer holds** — plan 00-06 must
account for the auto-disable applying now (see the updated Pitfall 3 note further down).

**Primary recommendation:** Build the pipeline in the order Kamal needs it wired — provision the
host and DNS first, then a bare `mix phx.new` skeleton with a hand-added `/up` route, then CI
(quality gate only), then the Docker/Kamal/entrypoint-migration path, then Sentry, then the backup
workflow, then AGENTS.md — and prove D-06's "live migration through the full pipeline" as an explicit
late task, not an afterthought.

## Architectural Responsibility Map

This phase has no UI/API/DB product tiers in the usual sense — it's a deploy pipeline. Mapped to the
closest equivalent "who owns this" tiers to prevent misassignment (e.g., putting migration-gating
logic in CI instead of the container, or putting secrets in git instead of CI/host):

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Placeholder HTML response | API/Backend (Phoenix release, stock `PageController`) | CDN/Edge (kamal-proxy TLS termination) | Phoenix serves the page; kamal-proxy only terminates TLS and proxies — no caching/CDN layer in Phase 0 |
| `/up` health endpoint | API/Backend (hand-added router entry) | — | Must live inside the same OTP release/container so Kamal's own health probe reflects real app+DB readiness, not a static edge response |
| CI quality gate (`mix quality`) | CI/CD (GitHub Actions) | — | Runs against ephemeral Postgres service container; never touches production |
| Docker image build (native arm64) | CI/CD (GitHub Actions, `ubuntu-24.04-arm` runner) | — | Building on the Hetzner host itself was explicitly rejected (D-01) in favor of a native CI runner |
| Container registry | CI/CD boundary (ghcr.io) | — | Sits between CI (pushes) and Host/Ops (pulls via Kamal) |
| Migration execution | Database/Storage (via API/Backend container's own entrypoint, `bin/migrate`) | — | Must run *inside* the release container before `bin/server` starts — not a CI step, not a manual SSH step (D-05) |
| `kamal deploy` orchestration | CI/CD (GitHub Actions, D-02) | Host/Ops (Hetzner CAX31, target) | CI holds the deploy credentials/SSH key at runtime; the host is purely the deploy target |
| Postgres accessory | Database/Storage (Kamal accessory container, `127.0.0.1`-bound) | Host/Ops (Docker on CAX31) | Never exposed beyond localhost — Kamal accessory pattern, not a managed DB |
| Secrets (SECRET_KEY_BASE, DATABASE_URL, registry pw, R2 keys, Sentry DSN) | CI/CD (GitHub Actions repo secrets) | Host/Ops (`.kamal/secrets`-resolved env file, written only at deploy time) | Real values live in exactly one place (GitHub); the host only ever holds resolved, non-literal env files Kamal itself manages |
| TLS termination | CDN/Edge (kamal-proxy, Kamal-built-in) | — | No separate Caddy/Traefik layer (explicit project constraint) |
| Nightly backup | Database/Storage (source: Postgres accessory) | CI/CD (scheduled GitHub Actions workflow, orchestrates dump+upload via SSH) | Dump happens against the DB container; the *trigger and credential injection* live in CI, not on the host |
| Crash/error visibility | API/Backend (in-process `Sentry.LoggerHandler`) | — | No separate log-aggregation service added in Phase 0 (D-18) |

## Project Constraints (from CLAUDE.md)

`.claude/CLAUDE.md` already contains a fully-researched "Technology Stack" section for this project.
Treat it as authoritative for versions and high-level rationale; this research only fills the gaps
it explicitly flagged. Directives extracted for planner compliance:

- **Tech stack is fixed**: Elixir + Phoenix 1.8 LiveView, single Phoenix app (no umbrella), one
  PostgreSQL DB, Tailwind + daisyUI defaults — flag before deviating.
- **Deploy is fixed**: Docker via Kamal to a single Hetzner CAX31 (arm64), kamal-proxy for TLS —
  never layer Caddy on top of Kamal.
- **Runner base image**: `debian:trixie-slim`, never Alpine (musl DNS issues + no ARM64 musl XLA
  binary for a later phase).
- **Build path**: native arm64 build (GitHub-hosted `ubuntu-24.04-arm` runner or the Hetzner host
  itself) — never QEMU cross-build. CONTEXT.md's D-01 locks this to the CI runner specifically.
- **Migrations**: use the `phx.gen.release`-generated `bin/migrate` (wraps `Ecto.Migrator`, no
  `Mix` dependency) via a custom Docker `ENTRYPOINT` — never `mix ecto.migrate` against a release
  (Mix isn't present at runtime).
- **Secrets**: `.kamal/secrets` (gitignored) with variable/command substitution, never literal
  values in git. CONTEXT.md's D-08 supersedes the original "local-only" framing: source those
  substitutions from GitHub Actions repo secrets since deploy is CI-driven.
- **Postgres image**: `pgvector/pgvector:pg17` even though `vector` isn't used yet, to avoid a
  later engine swap (D-15).
- **CI**: `erlef/setup-beam` for pinning Elixir+OTP in GitHub Actions — the Elixir-team-maintained
  standard, not manual Erlang installs and not `mise-action`.
- **`mix quality` alias order**: format → credo → sobelow → test (cheapest/fastest checks first).
- **Do NOT** add Oban tables, `vector` extension, embedding columns, or InstructorLite/Gemini
  config in Phase 0 — explicitly out of scope until Phase 2/3.
- **Do NOT** disable the release's default supervision tree — boot with the normal OTP release
  shape so Phase 2's Oban/Nx.Serving children are additive later.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** arm64 Docker image built on a native GitHub Actions `ubuntu-24.04-arm` runner — not the
  Hetzner host. No QEMU cross-build.
- **D-02:** `kamal deploy` is CI-driven — GitHub Actions runs it automatically on every merge to
  `main`, immediately after a successful build+push. No manual "click deploy," no required-reviewer
  gate.
- **D-03:** Container registry: GitHub Container Registry (ghcr.io), not Docker Hub.
- **D-04:** Single CI pipeline: PRs run `mix quality`; merging to `main` re-runs `mix quality`, then
  builds, pushes, and deploys. A broken merge to `main` never reaches production.
- **D-05:** Entrypoint-gated migrations — custom Docker `ENTRYPOINT` runs `bin/migrate` to
  completion before `exec bin/server`. Kamal's `/up` health check only passes once migrations
  succeed.
- **D-06:** Acceptance requires a live proof: ship an actual trivial schema-change migration through
  the full CI → build → Kamal pipeline and confirm the new container only goes live after migrations
  succeed. Must be an explicit plan task.
- **D-07:** No alerting service (Slack/email/webhook) added in Phase 0 for migration failures — the
  failed GitHub Actions run / `kamal deploy` output is sufficient signal at this stage.
- **D-08:** Real secret values live as GitHub Actions repo secrets. `.kamal/secrets` reads them via
  `$VAR`/command substitution inside the CI job — never literal values in the file or git history.
  Secrets: `SECRET_KEY_BASE`, `DATABASE_URL`, `KAMAL_REGISTRY_PASSWORD`, Cloudflare R2 access
  key/secret, Sentry DSN. `PHX_HOST` and other non-sensitive config stay `clear`.
- **D-09:** `SECRET_KEY_BASE` and the Postgres password are generated once locally and pasted into
  GitHub repo secrets manually. No rotation runbook in Phase 0.
- **D-10:** ghcr.io auth in CI uses the built-in `GITHUB_TOKEN` — no separate PAT.
- **D-11:** Explicitly declare which secrets each Kamal role/accessory needs in `deploy.yml` — don't
  assume global availability.
- **D-12:** The Hetzner CAX31 does not exist yet. Plan must include: create server, install Docker,
  add deploy SSH key, configure firewall (bind Postgres to `127.0.0.1`).
- **D-13:** `pukllay.club` is already registered with a DNS provider the user controls — only needs
  an A/AAAA record pointed at the new server once provisioned.
- **D-14:** Placeholder page = stock Phoenix welcome page, unmodified. No branding.
- **D-15:** Bind Postgres accessory to `127.0.0.1` only, never `0.0.0.0` — don't rely on UFW alone
  (Docker's iptables rules bypass it). Use `pgvector/pgvector:pg17`. Release boots with its full
  default supervision tree.
- **D-16:** Add Elixir + Erlang/OTP pins to the existing `mise.toml` (currently only pins `node`),
  matching whatever `mix phx.new` scaffolds (Elixir 1.19.x / OTP 28.x).
- **D-17:** Add Sentry free tier (`sentry-elixir`) in Phase 0. DSN supplied as a GitHub repo secret,
  wired through `.kamal/secrets` the same way as other secrets.
- **D-18:** Sentry is additive, not a logging replacement — default Phoenix `Logger` → stdout stays
  (viewable via `kamal app logs`). No log aggregation/dashboard service.

### Claude's Discretion

- Nightly `pg_dump` → R2 mechanism (host cron/systemd timer vs. a scheduled GitHub Actions workflow
  that SSHes in) — **this research recommends the scheduled GitHub Actions workflow** (see Common
  Pitfalls / Code Examples below for rationale and concrete shape).
- Backup retention policy and restore-testing cadence — not decided. Keep simple (e.g. keep last N
  dumps in R2); a periodic manual restore-test is good practice but not required to be automated in
  Phase 0.
- CI caching key: `mix.lock` hash (not `mix.exs`) — standard, no discussion needed.
- CI Postgres service image: plain `postgres:17` for Phase 0 (not `pgvector/pgvector`) since no
  vector columns are tested yet.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope. Local toolchain pinning (D-16) and observability
(D-17/D-18) were folded into this phase's decisions rather than deferred.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEPLOY-01 | App deployed to production at pukllay.club over HTTPS, placeholder page + `/up` health endpoint | Confirmed `/up` is NOT auto-generated by `phx.new`/`phx.gen.release` — must be hand-added as a plain unauthenticated route before Kamal health-check wiring; Kamal + kamal-proxy TLS pattern documented below |
| DEPLOY-02 | CI runs `mix quality` on every PR via GitHub Actions, Postgres service + caching | `erlef/setup-beam` + `actions/cache` keyed on `mix.lock` hash pattern documented; CLAUDE.md already fixes the alias order |
| DEPLOY-03 | `kamal deploy` ships a change with zero downtime, runs Ecto migrations as part of deploy | Entrypoint-gated migration pattern (community-standard, not shipped by Phoenix by default) documented with concrete script shape; Kamal `env.clear`/`env.secret` + `.kamal/secrets` substitution syntax documented |
| DEPLOY-04 | Nightly `pg_dump` backup lands in Cloudflare R2 | Two mechanisms evaluated; scheduled-GitHub-Actions-over-SSH recommended over host systemd timer and over the (archived, ARM64-unconfirmed) `postgres-backup-s3` sidecar image |
| DEPLOY-05 | AGENTS.md documents TDD loop, `mix quality` alias, manual-merge-gate rule, non-goals | No template exists yet in this repo — structure proposed below under Code Examples |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Kamal | 2.12.0 [VERIFIED: rubygems.org API, published 2026-06-18] | Deploy orchestrator | Already the project's fixed choice; this pins the exact current version for the CI `gem install kamal` step |
| sentry-elixir | 13.3.0 [VERIFIED: hex.pm API, published 2026-07-07] | Crash/error reporting | Official Elixir SDK for Sentry; ships its own `:logger` handler, no separate log pipeline needed |
| jason | 1.4.5 [VERIFIED: hex.pm API, published 2026-05-05] | JSON codec (sentry-elixir dependency) | Sentry's stated dependency; matches CLAUDE.md's `~> 1.4` note |
| finch | 0.23.0 [VERIFIED: hex.pm API] | HTTP client pool (sentry-elixir + `req` dependency) | Already the project's fixed HTTP stack per CLAUDE.md |

### Supporting (CI/CD tooling — GitHub Actions, not hex packages)

| Action | Version (typical pin) | Purpose | When to Use |
|--------|------------------------|---------|-------------|
| `erlef/setup-beam` | `@v1` | Pin Elixir+OTP in CI | Every CI job that runs `mix` commands |
| `actions/checkout` | `@v4` | Checkout source | Every job |
| `actions/cache` | `@v4` | Cache `deps`/`_build` keyed on `hashFiles('**/mix.lock')` | Speed up `mix deps.get`/compile across PR runs |
| `docker/setup-buildx-action` | `@v3` | Buildx builder for the image build/push job | Native arm64 build job |
| `docker/login-action` | `@v3` | Authenticate to ghcr.io using `GITHUB_TOKEN` | Image build/push job |
| `docker/metadata-action` | `@v5` | Generate image tags (git SHA, `latest`) | Image build/push job |
| `docker/build-push-action` | `@v6` | Build (native, no `--platform` emulation needed on an arm64 runner) + push to ghcr.io | Image build/push job |
| `ruby/setup-ruby` | `@v1` | Install Ruby so `gem install kamal` works in CI | Deploy job (Kamal is a Ruby gem — not present by default on any GitHub-hosted runner image assumption; verify) |
| `webfactory/ssh-agent` | `@v0.9` | Load the deploy SSH private key (GitHub secret) into an agent for the runner | Deploy job, before `kamal deploy` |

**Version verification note:** Docker/GH-official action versions above are widely-used current
majors [ASSUMED — ecosystem-standard majors, not individually re-verified against the GitHub
Marketplace API this session; low risk, these are extremely stable, official `docker/*` org
actions]. Re-confirm exact SHA-pinned versions at implementation time if the project's security
posture wants action-pinning-by-SHA (good practice, not required for Phase 0's stated scope).

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Scheduled GitHub Actions workflow (nightly backup) | Host systemd timer | Simpler/no GitHub dependency, but R2 credentials must then live in a host-side env file indefinitely, breaking the "secrets only ever live in GitHub secrets" pattern D-08 established for everything else |
| Scheduled GitHub Actions workflow (nightly backup) | `eeshugerman/postgres-backup-s3` Docker sidecar (Kamal accessory) | Purpose-built, supports `S3_ENDPOINT` override for R2 — but the repo is **archived** (June 2025, read-only) with no confirmed arm64 image variant; not recommended for an ARM64-only host |
| `ruby/setup-ruby` + `gem install kamal` in CI | A prebuilt Docker image with Kamal preinstalled (e.g. running `kamal deploy` from inside a container action) | Marginally faster CI, more moving parts (a second image to maintain); not worth it for a low-frequency-deploy solo project |

**Installation:**
```bash
# mix.exs (add to existing deps once mix phx.new has been run)
{:sentry, "~> 13.0"},
{:jason, "~> 1.4"},
{:finch, "~> 0.21"}
```

## Package Legitimacy Audit

> The project's package-legitimacy gate tool supports npm/pypi/crates only — this phase's only
> managed-package installs are **hex packages** (Elixir ecosystem), so the check below was done
> manually and directly against the authoritative `hex.pm` API (`hex.pm/api/packages/<name>`),
> which is the equivalent of an ecosystem registry check for this ecosystem.

| Package | Registry | Age | Last Publish | Source Repo | Verdict | Disposition |
|---------|----------|-----|---------------|--------------|---------|-------------|
| sentry | hex.pm | ~10.7 yrs (inserted 2015-12-02) | 2026-07-07 (v13.3.0) | github.com/getsentry/sentry-elixir | OK | Approved |
| jason | hex.pm | ~8.6 yrs (inserted 2017-12-22) | 2026-05-05 (v1.4.5 stable) | github.com/michalmuskala/jason | OK | Approved |
| finch | hex.pm | ~11.9 yrs (inserted 2014-09-15) | current 0.23.0 | github.com/sneako/finch | OK | Approved (already an existing project dependency per CLAUDE.md) |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
**Note on `eeshugerman/postgres-backup-s3`:** not a hex/npm/pypi/crates package (a standalone Docker
image), evaluated separately above under Alternatives Considered — archived/unmaintained, **not
recommended**, excluded from the deploy pipeline.

## Architecture Patterns

### System Architecture Diagram

```
Developer                GitHub                                    Hetzner CAX31 (arm64)
  |                         |                                              |
  |--push branch----------->|                                              |
  |                         |--PR opened------------------------>[CI: mix quality]
  |                         |    (format, credo --strict,               |
  |                         |     sobelow, test --warnings-as-errors,   |
  |                         |     against ephemeral postgres:17 svc)    |
  |                         |                                              |
  |--merge to main--------->|                                              |
  |                         |--CI: mix quality (again, gate)              |
  |                         |--CI: docker buildx build (native arm64      |
  |                         |      runner, multi-stage Dockerfile:        |
  |                         |      hexpm/elixir builder -> debian-slim    |
  |                         |      runner) --push--> ghcr.io              |
  |                         |--CI: gem install kamal; webfactory/         |
  |                         |      ssh-agent loads deploy key             |
  |                         |--CI: kamal deploy ------------------------->|
  |                         |                                              |
  |                         |                                    [pull new image from ghcr.io]
  |                         |                                    [start new container: ENTRYPOINT
  |                         |                                       runs bin/migrate to completion
  |                         |                                       against Postgres accessory,
  |                         |                                       THEN exec bin/server]
  |                         |                                    [kamal-proxy health-checks GET /up
  |                         |                                       on new container]
  |                         |                                              |
  |                         |                                    healthy? --yes--> [kamal-proxy cuts
  |                         |                                       over traffic, old container drops]
  |                         |                                    healthy? --no---> [old container keeps
  |                         |                                       serving; deploy reported failed]
  |                         |                                              |
  https://pukllay.club <----------------- kamal-proxy (TLS, Let's Encrypt) -+
                                                                              |
                                                            [Postgres accessory,
                                                             pgvector/pgvector:pg17,
                                                             bound to 127.0.0.1 only]
                                                                              |
  (nightly, independent of the above)                                       |
  GitHub Actions (scheduled cron) --SSH (deploy key)--> host --docker exec--> [pg_dump | gzip]
                                                                              |
                                                          --upload (R2 creds injected
                                                            transiently into SSH session)-->
                                                                    Cloudflare R2 bucket
```

### Recommended Project Structure

```
pukllay_club/
├── .github/
│   └── workflows/
│       ├── ci.yml              # PR quality gate (mix quality)
│       ├── deploy.yml          # main-branch: quality gate -> build -> push -> kamal deploy
│       └── backup.yml          # nightly cron: pg_dump -> R2
├── config/
│   ├── deploy.yml              # Kamal config (service, image, servers, proxy, accessories, env)
├── .kamal/
│   └── secrets                 # gitignored; $VAR substitution only, never literal values
├── lib/
│   └── pukllay_club/
│       └── release.ex          # generated by phx.gen.release; wraps Ecto.Migrator
├── rel/
│   └── overlays/
│       └── bin/
│           ├── migrate         # generated
│           └── server          # generated
├── Dockerfile                  # multi-stage: hexpm/elixir builder -> debian:trixie-slim runner
├── docker-entrypoint            # custom: run bin/migrate before exec bin/server, only for "server" cmd
├── mise.toml                   # [tools]: node (existing) + elixir + erlang (D-16)
└── AGENTS.md                   # DEPLOY-05: TDD loop, mix quality, merge-gate rule, non-goals
```

### Pattern 1: Native arm64 build + push in GitHub Actions

**What:** A single job (no build matrix needed — this project is single-arch/arm64-only per its own
constraint, unlike a typical multi-arch release) runs on `runs-on: ubuntu-24.04-arm`, builds via
`docker/build-push-action` without any `--platform` flag (the runner's own architecture *is* arm64,
so no emulation layer is invoked at all), and pushes straight to ghcr.io.

**When to use:** Every merge to `main` (D-02/D-04).

**Example:**
```yaml
# Source: pattern synthesized from GitHub's native-ARM-runner docs + docker/build-push-action
# usage conventions [CITED: github.blog/changelog ARM-hosted-runners, docker/build-push-action docs]
build-and-push:
  runs-on: ubuntu-24.04-arm
  needs: quality
  permissions:
    contents: read
    packages: write
  steps:
    - uses: actions/checkout@v4
    - uses: docker/login-action@v3
      with:
        registry: ghcr.io
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    - uses: docker/setup-buildx-action@v3
    - uses: docker/metadata-action@v5
      id: meta
      with:
        images: ghcr.io/${{ github.repository }}
    - uses: docker/build-push-action@v6
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        # No `platforms:` override needed — the runner itself is arm64, this is a native build
```

### Pattern 2: `.kamal/secrets` sourced from GitHub Actions repo secrets

**What:** `.kamal/secrets` never contains literal values — only `$VAR` references. The CI job that
runs `kamal deploy` exports GitHub repo secrets as shell env vars in that same step, so Kamal's own
substitution resolves them at deploy time. `deploy.yml` declares which vars are `clear` vs `secret`.

**When to use:** Every deploy (D-08, D-10, D-11).

**Example:**
```bash
# .kamal/secrets [CITED: kamal-deploy.org/docs/configuration/environment-variables/]
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
SECRET_KEY_BASE=$SECRET_KEY_BASE
DATABASE_URL=$DATABASE_URL
SENTRY_DSN=$SENTRY_DSN
```

```yaml
# config/deploy.yml (excerpt) [CITED: kamal-deploy.org env-vars docs]
env:
  clear:
    PHX_HOST: pukllay.club
    PHX_SERVER: "true"
  secret:
    - SECRET_KEY_BASE
    - DATABASE_URL
    - SENTRY_DSN

accessories:
  db:
    image: pgvector/pgvector:pg17
    host: <hetzner-ip>
    port: "127.0.0.1:5432:5432"
    env:
      secret:
        - POSTGRES_PASSWORD
    volumes:
      - "pg_data:/var/lib/postgresql/data"
```

```yaml
# .github/workflows/deploy.yml deploy step (excerpt)
# [CITED: pattern cross-referenced across multiple Kamal+GitHub-Actions guides]
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: "3.3"
    bundler-cache: false
- run: gem install kamal --version "2.12.0"
- uses: webfactory/ssh-agent@v0.9
  with:
    ssh-private-key: ${{ secrets.DEPLOY_SSH_KEY }}
- name: Deploy
  env:
    KAMAL_REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
    SECRET_KEY_BASE: ${{ secrets.SECRET_KEY_BASE }}
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
    SENTRY_DSN: ${{ secrets.SENTRY_DSN }}
  run: kamal deploy
```

### Pattern 3: Entrypoint-gated migrations

**What:** A custom Docker entrypoint script that runs `bin/migrate` to completion only when the
container's command is `bin/server`, then execs the real server — so Kamal's `/up` health check
(and therefore zero-downtime cutover) is naturally gated on migration success.

**When to use:** Every deploy (D-05, verified live per D-06).

**Example:**
```dockerfile
# Source: community-standard pattern for Phoenix+Kamal, since Phoenix's own releases guide
# describes the *need* but does not ship a concrete script [CITED: phoenix.hexdocs.pm/releases.html
# + cross-referenced Kamal/Phoenix deploy guides]
COPY docker-entrypoint /app/bin/docker-entrypoint
RUN chmod +x /app/bin/docker-entrypoint
ENTRYPOINT ["/app/bin/docker-entrypoint"]
CMD ["/app/bin/server"]
```

```bash
#!/bin/sh
# docker-entrypoint
set -e
if [ "$1" = "/app/bin/server" ]; then
  /app/bin/migrate
fi
exec "$@"
```

### Pattern 4: Hand-added `/up` health route (Phoenix does not generate one)

**What:** `mix phx.new` and `mix phx.gen.release --docker` do NOT create a `/up` route — this was
confirmed against the Phoenix hexdocs releases guide and a real-world Kamal+Phoenix GitHub issue
where the reporter had to add the route manually. It must sit outside the browser pipeline (no
CSRF/session dependency) and outside auth, and should respond fast (no DB round-trip required for
Phase 0 — Kamal's own accessory/DB startup ordering plus the entrypoint migration gate already
proves DB readiness before the app boots).

**When to use:** DEPLOY-01, wired into Kamal's health-check config.

**Example:**
```elixir
# lib/pukllay_club_web/router.ex — add above the normal browser pipeline
pipeline :health do
  plug :accepts, ["text"]
end

scope "/", PukllayClubWeb do
  pipe_through :health
  get "/up", HealthController, :up
end
```

```elixir
# lib/pukllay_club_web/controllers/health_controller.ex
defmodule PukllayClubWeb.HealthController do
  use PukllayClubWeb, :controller

  def up(conn, _params) do
    conn |> put_resp_content_type("text/plain") |> send_resp(200, "OK")
  end
end
```

### Anti-Patterns to Avoid

- **Disabling Kamal's health check to unblock a stuck deploy:** fixes the symptom, loses
  zero-downtime protection *and* migration-gating in the same move. Fix the underlying readiness
  issue (Pitfall below).
- **Running `mix ecto.migrate` against the compiled release:** `Mix` doesn't exist at runtime in an
  OTP release. Use the generated `bin/migrate` (`Ecto.Migrator` directly).
- **Assuming a GitHub-hosted runner has Ruby+Kamal preinstalled:** it doesn't by default reliably
  across all image variants for this purpose — always add an explicit `ruby/setup-ruby` +
  `gem install kamal` step.
- **Writing real secret values into `.kamal/secrets` "just for now":** any value that ever touches
  git history needs rotation — even a since-reverted commit.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Zero-downtime traffic cutover + TLS | A custom nginx/Caddy + manual container swap script | kamal-proxy (built into Kamal 2) | Already handles instant cutover + automatic Let's Encrypt renewal; the project's own constraint forbids layering Caddy on top anyway |
| Migration-before-boot gating | A `handle_continue`/on-boot migration inside `application.ex` | The `bin/migrate`-then-`exec bin/server` entrypoint pattern | Running migrations from inside the OTP app's own boot means every rolling-restart replica races the migration; the entrypoint pattern runs it once, before the app's supervision tree even starts |
| Postgres→R2 backup automation | A hand-rolled cron+`pg_dump`+curl-to-R2-API bash script from scratch | `pg_dump` piped through `gzip`, uploaded via `aws s3 cp --endpoint-url` (aws-cli, already present on most dev machines and easy to install in a runner) or `rclone` (S3-compatible `provider = Cloudflare` config) | These are the two standard, well-documented ways to talk to R2's S3-compatible API — no bespoke HTTP/signing code needed |
| Error/crash capture | A custom `Logger` backend that POSTs to some webhook | `sentry-elixir`'s built-in `Sentry.LoggerHandler` (`enable_logs: true`) | Ships as a `:logger` handler that auto-attaches; free tier covers a walking-skeleton's crash volume |

**Key insight:** Every piece of this phase has a "boring," well-trodden Kamal/Phoenix-community
answer. The risk in Phase 0 is not *missing* tooling — it's assembling the known-good pieces in the
wrong order (e.g., CI step ordering, migration timing) or skipping the hand-added pieces Phoenix
doesn't ship for you (`/up`, the entrypoint script).

## Common Pitfalls

### Pitfall 1: `/up` assumed to exist, doesn't

**What goes wrong:** Kamal's default health check hits `GET /up`. If nobody added that route,
`kamal deploy` hangs at "Waiting for app to become healthy" or the deploy fails outright — and it's
easy to *think* Phoenix ships this by default (many Rails-first Kamal tutorials assume Rails'
built-in `/up`, and Rails does ship one; Phoenix does not).
**Why it happens:** Kamal's docs and most tutorials are Rails-first; Rails auto-generates `/up` via
`Rails::HealthController`, Phoenix has no equivalent generator output.
**How to avoid:** Add the route explicitly (see Pattern 4) as one of the very first app-level tasks
in this phase, before wiring Kamal's `deploy.yml` health-check config at all.
**Warning signs:** `kamal deploy` output stuck on health-check waiting; `curl https://pukllay.club/up`
returns 404 even though the root page loads fine.

### Pitfall 2: Ruby/Kamal not installed in the deploy CI job

**What goes wrong:** `kamal deploy` is a Ruby gem invocation. A workflow that jumps straight from
"push image" to `run: kamal deploy` without a Ruby setup step fails with "kamal: command not found."
**Why it happens:** The rest of this pipeline is Elixir-only (`erlef/setup-beam`), so it's easy to
forget Kamal itself needs its own separate language runtime in the same job.
**How to avoid:** Add `ruby/setup-ruby` + `gem install kamal` (pin the version, e.g. 2.12.0) as
explicit steps in the deploy job, before the `kamal deploy` step.
**Warning signs:** CI fails immediately at the deploy step with a shell "command not found" error.

### Pitfall 3: Scheduled GitHub Actions workflow silently stops running

**What goes wrong:** GitHub's `on: schedule` cron trigger is documented as best-effort — it can lag
under platform load, and (for **public** repos only — confirmed not applicable to private repos)
auto-disables after 60 days of no repository commit activity.
**Why it happens:** GitHub throttles scheduled workloads more aggressively than push-triggered ones,
and there's no built-in alert when a scheduled run silently doesn't fire.
**How to avoid:** **UPDATE (00-03 execution, see 00-CONTEXT.md D-19): the repo was flipped from
private to public during 00-03** (GitHub Free requires a public repo — or a paid Pro plan — to use
branch protection / rulesets, which Task 3 of plan 00-03 required). The "does not apply to private
repos" framing below no longer holds for this project — **the 60-day auto-disable now DOES apply**.
Accepted as a minor, mitigable tradeoff (a repo under active multi-phase development is unlikely to
go 60 days without a commit), but plan 00-06 (nightly `pg_dump` -> R2 backup) MUST explicitly
account for this: either accept the risk in that plan's context, or add a trivial monthly
"keepalive" commit/workflow (the documented community workaround) alongside the nightly backup
workflow. Not a Phase 0 blocker on its own, but worth a one-line note in AGENTS.md's non-goals/
known-limitations for future-self, and an explicit line in 00-06's plan context so it isn't
rediscovered from scratch.
**Warning signs:** No new dumps appearing in the R2 bucket for more than 24-48h; check the
"Actions" tab's scheduled-workflow run history, not just the R2 bucket contents.

### Pitfall 4: Disabling Kamal's health check to "fix" a stuck deploy

**What goes wrong:** If a deploy hangs on health-check waiting (frequently: Pitfall 1's missing
`/up`, or a Postgres accessory that isn't actually reachable yet), a common shortcut is to loosen or
disable the health check to force the deploy through — which silently ships without zero-downtime
protection or migration-gating (D-05's whole safety property depends on this check).
**Why it happens:** Under time pressure, "just get it deployed" feels faster than diagnosing why the
check is failing.
**How to avoid:** Treat a hanging health check as a signal to fix the underlying readiness issue
(missing route, DB accessory misconfigured, migration erroring) — never as a reason to bypass the
check itself.
**Warning signs:** `deploy.yml`'s `healthcheck:` block missing or set to an implausibly short/absent
path/timeout compared to the project's own defaults.

## Code Examples

### AGENTS.md structure (DEPLOY-05 — no existing template in this repo)

```markdown
# AGENTS.md

## TDD Loop
1. Write/derive a test from the acceptance criterion being implemented.
2. Run it — confirm it fails (red).
3. Write the minimum code to pass (green).
4. Refactor with the test green as a safety net.
5. Run `mix quality` before committing.

## `mix quality` alias
Order: format --check-formatted -> credo --strict -> sobelow -> test --warnings-as-errors
(cheapest/fastest checks first; a formatting typo fails in seconds, not after a full test run).

## Manual Merge Gate
Every PR must pass CI (`mix quality` against a Postgres service) before merge. No merges bypass
this gate, including for "trivial" changes. Merging to `main` re-runs `mix quality` as a second
gate before build/deploy — a broken merge never reaches production.

## Non-Goals (Phase 0)
- No product features, no catalog, no auth, no AI/embeddings/Oban/BGG import.
- No log-aggregation dashboard beyond Sentry (crash) + stdout logs (`kamal app logs`).
- No alerting service beyond CI/`kamal deploy` failure signals.
- No backup restore-test automation (manual, periodic).
- No secrets-manager integration beyond GitHub Actions repo secrets + `.kamal/secrets`.
```

### Nightly backup workflow shape (recommended mechanism)

```yaml
# .github/workflows/backup.yml
on:
  schedule:
    - cron: "0 8 * * *"   # nightly, UTC
  workflow_dispatch: {}   # allow manual trigger for testing

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: webfactory/ssh-agent@v0.9
        with:
          ssh-private-key: ${{ secrets.DEPLOY_SSH_KEY }}
      - name: Dump and upload
        env:
          R2_ACCESS_KEY_ID: ${{ secrets.R2_ACCESS_KEY_ID }}
          R2_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY }}
          R2_ENDPOINT: ${{ secrets.R2_ENDPOINT }}
        run: |
          ssh -o StrictHostKeyChecking=accept-new deploy@${{ secrets.DEPLOY_HOST }} \
            "docker exec pukllay-db pg_dump -U postgres pukllay_prod | gzip" \
            > backup-$(date +%F).sql.gz
          aws s3 cp backup-$(date +%F).sql.gz \
            s3://pukllay-backups/ \
            --endpoint-url "$R2_ENDPOINT"
```
*(Illustrative shape, not copy-paste-final — planner should confirm exact Kamal accessory container
name and `aws-cli` availability/version on the `ubuntu-latest` runner at implementation time.)*

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| QEMU-emulated `--platform=linux/arm64` builds on amd64 GitHub runners | Native `ubuntu-24.04-arm` GitHub-hosted runners | GitHub GA'd arm64-hosted runners (2025) | 5-20x faster builds, avoids a documented QEMU/Erlang-JIT crash interaction |
| Kamal 1.x's more flexible external secrets-manager plugins | Kamal 2's stricter `.kamal/secrets` + `env.clear`/`env.secret` split | Kamal 2 rewrite (2024) | Simpler mental model, but CI-driven deploys need an explicit "export GH secrets as shell env vars right before `kamal deploy`" step — this isn't automatic |
| Traefik in front of Kamal 1.x | kamal-proxy, built into Kamal 2 | Kamal 2 | No separate reverse-proxy container to maintain; matches this project's explicit constraint |

**Deprecated/outdated:**
- Kamal 1.x's Traefik-based proxying: fully replaced by kamal-proxy in Kamal 2; do not follow any
  Kamal 1.x tutorial's proxy config.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact GitHub Action versions (`docker/build-push-action@v6`, `docker/login-action@v3`, etc.) | Standard Stack / Code Examples | Low — these are extremely stable, official actions; worst case a minor version bump needed at implementation time, no architectural change |
| A2 | `ruby/setup-ruby` + `gem install kamal --version 2.12.0` is the right CI pattern (vs. a Kamal Docker action) | Pattern 2 / Pitfall 2 | Low-medium — if wrong, deploy job fails fast and loudly at the `kamal deploy` step, easy to diagnose and fix in the workflow file |
| A3 | Recommending scheduled GitHub Actions (not host systemd timer) for nightly backup | Standard Stack (Alternatives), Code Examples | Medium — this is explicitly "Claude's Discretion" per CONTEXT.md; if the user actually prefers host-side simplicity over the D-08-consistency argument, this should be confirmed during plan-phase/discuss, not silently locked in |
| A4 | `webfactory/ssh-agent@v0.9` is current/appropriate for loading the deploy SSH key in both the deploy and backup workflows | Pattern 2, Code Examples | Low — widely used community action; a pinned-version mismatch is a one-line CI fix, not a design risk |

## Open Questions

1. **Exact Kamal `deploy.yml` `healthcheck:` block syntax/defaults for a Phoenix app**
   - What we know: Kamal defaults to `GET /up` with a configurable path/port/interval; `/up` must
     be added manually to the Phoenix router (Pattern 4/Pitfall 1).
   - What's unclear: The exact current default timeout/retry values in Kamal 2.12.0 specifically —
     WebFetch/WebSearch sources didn't surface Kamal 2.12.0's precise default numbers.
   - Recommendation: Confirm against `kamal deploy config` output (or `kamal healthcheck --help`)
     once Kamal is actually installed locally/in CI during plan execution — this is a 30-second
     verification, not a research gap that blocks planning.

2. **Whether GitHub-hosted `ubuntu-latest` runners have `aws-cli` preinstalled for the backup job**
   - What we know: `aws-cli` is present on this dev machine (2.28.0) and is a documented
     GitHub-hosted-runner preinstalled tool in general, but wasn't independently re-verified for the
     current runner image this session.
   - What's unclear: Exact current preinstalled version on `ubuntu-latest` as of this research date.
   - Recommendation: Add an explicit `aws-cli` version check (or install step) in the backup
     workflow rather than assuming; cheap and removes the ambiguity entirely.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Docker | Local image build/test, Kamal on the host | ✓ | 28.4.0 | — |
| `gh` CLI | Repo creation, setting GitHub secrets from the terminal | ✓ (authenticated as AugustoPedraza) | 2.45.0 | — |
| Git remote | CI/Actions require a GitHub remote to exist | ✗ | — | Must be created as a Phase 0 prerequisite task (`gh repo create` or manual remote add) — already flagged in CONTEXT.md's code_context as an implicit prerequisite |
| mise | Local toolchain pinning (D-16) | ✓ | 2026.3.9 (update to 2026.7.13 available) | — |
| Elixir/Erlang (local, via mise) | Local dev matching CI/prod pins | ✓ but mismatched | Elixir 1.17.3-otp-27 installed; target is 1.19.x/OTP 28.x per CLAUDE.md | `mise install` after updating `mise.toml` per D-16 will fetch the correct versions — one-time local resync, not a blocker |
| Ruby / `gem` | Running Kamal locally (optional) and inside CI's deploy job (required) | ✗ (local machine has no Ruby/gem at all) | — | Not needed locally if all Kamal invocations stay CI-driven per D-02; CI job must install it explicitly (Pitfall 2) — no fallback needed since CI-driven is the locked design |
| `psql` | Manual DB inspection/troubleshooting during setup | ✓ | 16.14 | — |
| `aws-cli` | R2 upload in the backup workflow (if this mechanism is chosen) | ✓ (locally: 2.28.0) | 2.28.0 | `rclone` is a viable alternative but is NOT currently installed locally or confirmed on GitHub-hosted runners — verify at implementation time (Open Question 2) |
| `rclone` | Alternative to `aws-cli` for R2 upload | ✗ | — | Use `aws-cli` (available) instead — no need to introduce a second tool |
| Kamal gem | Running `kamal` commands (setup, deploy, app logs) | ✗ (not installed anywhere yet — will be installed fresh in CI per D-02, and optionally locally for `kamal app logs`/troubleshooting) | 2.12.0 latest | Install via `gem install kamal` wherever needed; no viable substitute, this is the fixed deploy tool |

**Missing dependencies with no fallback:**
- Git remote — must be created before any CI/Actions work (one-command prerequisite, not a design
  question).
- Ruby/Kamal in the CI deploy job — must be added as explicit workflow steps; no substitute since
  Kamal itself is the fixed deploy tool.

**Missing dependencies with fallback:**
- `rclone` — not installed, but `aws-cli` (already present) covers the same R2-upload need, so no
  action needed unless a future preference for `rclone`'s multi-backend flexibility emerges.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (ships with `mix phx.new`; not yet scaffolded — Wave 0 must run `mix phx.new`) |
| Config file | none yet — created by `mix phx.new` (`test/test_helper.exs`) |
| Quick run command | `mix test` |
| Full suite command | `mix test --warnings-as-errors` (per `mix quality` alias) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|--------------------|-------------|
| DEPLOY-01 | `/up` returns 200 text | unit/controller test | `mix test test/pukllay_club_web/controllers/health_controller_test.exs -x` | ❌ Wave 0 |
| DEPLOY-01 | Production HTTPS + placeholder page reachable | smoke (manual-only, infra-external) | `curl -sf https://pukllay.club/up` (run manually or as a post-deploy CI step, not ExUnit) | ❌ Wave 0 (add a post-deploy curl-check CI step) |
| DEPLOY-02 | `mix quality` gates every PR | integration (CI itself) | `.github/workflows/ci.yml` running on a `postgres:17` service | ❌ Wave 0 |
| DEPLOY-03 | `kamal deploy` ships zero-downtime + migrations-on-deploy | manual-only (live proof, per D-06) | No automatable unit test — verified by shipping an actual schema-change migration through the full pipeline and observing container swap timing/`schema_migrations` | N/A — this is inherently an end-to-end infra proof, justified manual-only per D-06 |
| DEPLOY-04 | Nightly `pg_dump` lands in R2 | smoke (manual trigger via `workflow_dispatch`, then verify bucket contents) | `gh workflow run backup.yml` then check R2 bucket | ❌ Wave 0 (workflow file itself) |
| DEPLOY-05 | AGENTS.md exists with required sections | smoke (file existence + grep for required headings) | `test -f AGENTS.md && grep -q "TDD Loop" AGENTS.md` (shell check, not ExUnit) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test` (quick)
- **Per wave merge:** `mix quality` (full suite: format, credo, sobelow, test --warnings-as-errors)
- **Phase gate:** Full suite green, plus the DEPLOY-03 live-migration proof (D-06) and a real
  `curl https://pukllay.club/up` check, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `mix phx.new` scaffold itself — nothing exists yet in this repo.
- [ ] `test/pukllay_club_web/controllers/health_controller_test.exs` — covers DEPLOY-01's `/up`
      route.
- [ ] `.github/workflows/ci.yml` — covers DEPLOY-02.
- [ ] `.github/workflows/deploy.yml` — covers DEPLOY-03 (build+push+deploy portion; the
      migration-gating proof itself is a manual D-06 task, not a file).
- [ ] `.github/workflows/backup.yml` — covers DEPLOY-04.
- [ ] `AGENTS.md` — covers DEPLOY-05.
- [ ] Framework install: `mix phx.new pukllay_club --database postgres` (or equivalent) — the very
      first task of this phase.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|-------------------|
| V2 Authentication | No | No auth exists in Phase 0 — no product surface, stock welcome page only |
| V3 Session Management | No | No sessions issued in Phase 0 |
| V4 Access Control | No | No access-controlled resources exist yet |
| V5 Input Validation | Minimal | `/up` takes no input; no other user-facing input surface in Phase 0 |
| V6 Cryptography | Yes | TLS via kamal-proxy/Let's Encrypt (automatic cert issuance/renewal); no custom crypto code |
| V14 Configuration (secrets/deployment) | Yes | GitHub Actions repo secrets as the single source of truth; `.kamal/secrets` never holds literal values; per-role/accessory explicit secret declarations (D-11) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Secret values committed to git history (even transiently) | Information Disclosure | `.kamal/secrets` gitignored + substitution-only; rotate immediately if any value ever touches a commit, even reverted |
| Postgres accessory exposed beyond localhost | Information Disclosure / Elevation of Privilege | Bind to `127.0.0.1` only (D-15); don't rely on UFW alone since Docker's own iptables rules bypass host firewall rules |
| Stale/overly-broad `GITHUB_TOKEN` permissions in the build/push job | Elevation of Privilege | Explicitly scope `permissions: contents: read, packages: write` in the workflow, not the default broad token |
| SSH deploy key compromise (used by both deploy.yml and backup.yml) | Spoofing / Elevation of Privilege | Key lives only as a GitHub repo secret, loaded transiently via `webfactory/ssh-agent`; no plaintext copy on any runner disk beyond the job's ephemeral lifetime |
| Kamal health check disabled to force through a bad deploy (Pitfall 4) | Tampering | Treat health-check failures as signals to fix, never as a reason to bypass — organizational/process control, not code |

## Sources

### Primary (HIGH confidence)
- hex.pm package API (`/api/packages/sentry`, `/api/packages/jason`, `/api/packages/finch`) — direct
  registry queries — versions/publish dates for sentry 13.3.0, jason 1.4.5, finch 0.23.0
- rubygems.org package API (`/api/v1/gems/kamal.json`) — Kamal 2.12.0, published 2026-06-18
- GitHub's own docs (`docs.github.com/actions/managing-workflow-runs/disabling-and-enabling-a-workflow`)
  — confirmed the 60-day scheduled-workflow auto-disable applies to public repos only

### Secondary (MEDIUM confidence)
- `.claude/CLAUDE.md` "Technology Stack" section — this project's own already-researched primary
  source for versions/rationale (hex.pm API cross-checked at the time it was written)
- GitHub's changelog / community write-ups on native `ubuntu-24.04-arm` hosted runners and
  `docker/build-push-action` matrix patterns (WebSearch, cross-checked across multiple independent
  sources)
- WebSearch results on `phx.gen.release`/entrypoint-migration community pattern (cross-checked
  across Phoenix's own hexdocs guide + multiple Kamal+Phoenix deploy write-ups)
- `basecamp/kamal` GitHub issue #574 (WebFetch) — confirms `/up` is not Phoenix-default; developer
  had to add it manually

### Tertiary (LOW confidence — single-source WebFetch/WebSearch lookups, not independently cross-checked)
- Exact `.kamal/secrets`/`deploy.yml` `env.clear`/`env.secret` syntax (WebFetch of
  `kamal-deploy.org/docs/configuration/environment-variables/`) — syntax itself is very likely
  correct (official docs page), but this session's fetch tool downgrades single-WebFetch lookups to
  LOW confidence per this project's own classify-confidence tooling; re-confirm against the live
  Kamal docs at implementation time
- `mise.toml` erlang/elixir core-plugin syntax (WebFetch of `mise.jdx.dev/lang/erlang.html` and
  `/lang/elixir.html`) — same caveat as above
- sentry-elixir Phoenix-specific `Sentry.PlugCapture`/`Sentry.PlugContext` integration details — not
  fully extracted this session (WebFetch returned partial results); the baseline `LoggerHandler`
  crash-capture setup (sufficient for D-17's stated goal) was confirmed, but the deeper
  request-context plug wiring should be double-checked against `sentry.hexdocs.pm/13.3.0/setup-with-phoenix.html`
  directly during implementation if richer request context is desired
- `eeshugerman/postgres-backup-s3` archived status and lack of confirmed ARM64 variant (single
  WebFetch of the GitHub repo)
- GitHub Actions ARM64 runner pricing (`$0.005/min`, 1x Linux multiplier) — single WebSearch,
  directionally correct but exact current numbers should be re-checked against GitHub's live pricing
  page since this space has changed multiple times recently per the search results themselves

## Metadata

**Confidence breakdown:**
- Standard stack (Kamal/sentry/jason/finch versions): HIGH — direct registry API queries
- Architecture (deploy pipeline shape, entrypoint pattern, `/up` gap): MEDIUM — cross-checked across
  official docs + a real GitHub issue + this project's own prior CLAUDE.md research
- Exact syntax details (Kamal secrets, mise.toml, sentry Phoenix plugs): LOW-MEDIUM — single-source
  WebFetch lookups against official docs; syntax is very likely correct but wasn't independently
  cross-checked a second way this session
- Pitfalls: MEDIUM — mix of this project's own pre-existing PITFALLS.md research (already
  MEDIUM-confidence, cross-checked) plus new findings (the `/up` gap, Ruby/Kamal-in-CI gap, GH
  Actions schedule reliability) each confirmed against at least one authoritative source

**Research date:** 2026-07-24
**Valid until:** ~30 days for the Kamal/GitHub Actions/mise syntax details (fast-moving tooling
ecosystem); hex package version pins should be re-verified at implementation time regardless, since
this phase may not be implemented immediately after this research session.
