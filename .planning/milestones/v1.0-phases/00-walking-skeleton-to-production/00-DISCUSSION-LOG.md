# Phase 0: Walking Skeleton to Production - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-24
**Phase:** 0-Walking Skeleton to Production
**Areas discussed:** Build & deploy strategy, Migration safety on deploy, Secrets management,
Infra readiness & scope, Local dev toolchain pinning, Observability

---

## Build & Deploy Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Kamal builds on Hetzner host | Kamal's default `builder: { arch: arm64 }`, no CI runner | |
| GitHub Actions arm64 runner | Native `ubuntu-24.04-arm` runner builds the image in CI | ✓ |

**User's choice:** GitHub Actions arm64 runner.

| Option | Description | Selected |
|--------|-------------|----------|
| CI-driven on merge to main | GitHub Actions runs `kamal deploy` automatically after merge | ✓ |
| Manual from your machine | You run `kamal deploy` locally when ready | |

**User's choice:** CI-driven on merge to main.

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub Container Registry (ghcr.io) | Free, auth via `GITHUB_TOKEN` | ✓ |
| Docker Hub | Separate account/token, pull rate limits | |

**User's choice:** GitHub Container Registry (ghcr.io).

| Option | Description | Selected |
|--------|-------------|----------|
| Single pipeline: quality gate, then build+deploy on main | One workflow, broken merges never deploy | ✓ |
| Separate workflows, deploy doesn't re-check quality | Deploy trusts main is already gated | |

**User's choice:** Single pipeline: quality gate, then build+deploy on main.

**Notes:** Choosing CI-driven deploy here directly changed the default answer for Secrets
Management later (secrets must reach GitHub Actions, not just stay local).

---

## Migration Safety on Deploy

| Option | Description | Selected |
|--------|-------------|----------|
| Entrypoint-gated bin/migrate | Custom ENTRYPOINT runs `bin/migrate` before `bin/server` | ✓ |
| Kamal pre-deploy hook (SSH + mix ecto.migrate) | Not viable — Mix unavailable in a release | |

**User's choice:** Entrypoint-gated bin/migrate.

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, require a live proof | Ship a real schema-change migration through the full pipeline before Phase 0 is "done" | ✓ |
| No, code review is enough | Skip an explicit live-deploy proof step | |

**User's choice:** Yes, require a live proof.

| Option | Description | Selected |
|--------|-------------|----------|
| Container never healthy — notified via failed CI/kamal output | No extra alerting | ✓ |
| Same, plus a Slack/email/webhook alert on deploy failure | Extra notification channel | |

**User's choice:** Container never healthy — notified via failed CI/kamal output.

---

## Secrets Management

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub Actions repo secrets → .kamal/secrets via env substitution | Real values never in the file/git | ✓ |
| GitHub Environments with required reviewers | Same, plus a manual approval gate | |

**User's choice:** GitHub Actions repo secrets → .kamal/secrets via env substitution.

| Option | Description | Selected |
|--------|-------------|----------|
| Generate once locally, paste into GitHub repo secrets | Simple, no rotation runbook | ✓ |
| Same, but document a rotation runbook now | Extra upfront documentation | |

**User's choice:** Generate once locally, paste into GitHub repo secrets.

| Option | Description | Selected |
|--------|-------------|----------|
| Built-in GITHUB_TOKEN | No extra secret, job-scoped | ✓ |
| Dedicated Personal Access Token (PAT) | Extra setup, only needed for out-of-CI pulls | |

**User's choice:** Built-in GITHUB_TOKEN.

---

## Infra Readiness & Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Not yet created — Phase 0 includes provisioning steps | Plan documents server creation | ✓ |
| Already created and reachable via SSH | Skip provisioning instructions | |

**User's choice:** Not yet created — Phase 0 includes provisioning steps.

| Option | Description | Selected |
|--------|-------------|----------|
| Domain registered, DNS provider ready — just point a record | Assumes domain/DNS already exist | ✓ |
| Domain and DNS setup also needed from scratch | Covers registrar + DNS provider setup | |

**User's choice:** Domain registered, DNS provider ready — just point a record.

| Option | Description | Selected |
|--------|-------------|----------|
| Stock Phoenix welcome page, unmodified | Zero design work | ✓ |
| Stock page with a one-line "coming soon" tweak | Minimal branding touch | |

**User's choice:** Stock Phoenix welcome page, unmodified.

---

## Local Dev Toolchain Pinning

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, pin elixir + erlang via mise | Matches CI/Docker builder versions | ✓ |
| No, leave version management to asdf/.tool-versions or system Elixir | | |

**User's choice:** Yes, pin elixir + erlang via mise.

---

## Observability

| Option | Description | Selected |
|--------|-------------|----------|
| Default Phoenix Logger only, no extra service | Zero added cost | |
| Add a free-tier error tracker (e.g. Sentry free tier) | Catches crashes even pre-product-code | ✓ |

**User's choice:** Add a free-tier error tracker (Sentry free tier).

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub repo secret → .kamal/secrets, same pattern as other secrets | Consistent with D-08 | ✓ |
| You decide | | |

**User's choice:** GitHub repo secret → .kamal/secrets, same pattern as other secrets.

---

## Claude's Discretion

- Nightly `pg_dump` → R2 mechanism (host cron/systemd vs. scheduled GitHub Actions workflow) —
  raised as an option, not selected for deep-dive discussion.
- Backup retention policy and restore-testing cadence.
- CI caching key (`mix.lock` hash) and CI Postgres service image (`postgres:17` for Phase 0).

## Deferred Ideas

None — discussion stayed within phase scope.
