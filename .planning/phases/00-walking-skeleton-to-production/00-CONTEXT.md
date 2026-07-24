# Phase 0: Walking Skeleton to Production - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the entire deploy pipeline end-to-end with zero product code: a trivial-but-real Phoenix
app reachable at `https://pukllay.club`, CI that gates every PR, `kamal deploy` shipping changes
to the Hetzner CAX31 with zero downtime and migrations-on-deploy, and a nightly `pg_dump` backup
landing in Cloudflare R2. No catalog, no auth, no AI/embeddings/Oban/BGG — those are explicitly
out of scope until Phase 1+.

</domain>

<decisions>
## Implementation Decisions

**Note on process:** This CONTEXT.md was discussed twice. The first pass (same session) was
skipped by explicit user request ("none") and used research defaults. The user then re-ran
`/gsd-discuss-phase 0`, chose "Update it," and actually discussed all four proposed areas plus two
follow-ups (local toolchain pinning, observability). **This version supersedes the first pass** —
several decisions below (build location, deploy trigger, secrets delivery) are the *opposite* of
the original research-only defaults, because choosing CI-driven deploy early in the discussion
changed what made sense for secrets later. Downstream agents should treat only this version as
current.

### Build & Deploy Strategy
- **D-01:** The arm64 Docker image is built on a native GitHub Actions `ubuntu-24.04-arm` runner —
  not on the Hetzner host. No QEMU cross-build (rejected per PITFALLS.md: slow, occasionally flaky
  NIF cross-compiles). — **Reversibility:** reversible — a `deploy.yml`/workflow change.
- **D-02:** `kamal deploy` is **CI-driven**: GitHub Actions runs it automatically on every merge to
  `main`, immediately after a successful build+push. There is no manual "click deploy" step and no
  required-reviewer gate in front of it (the user explicitly chose plain repo secrets over GitHub
  Environments with required reviewers in D-08). — **Reversibility:** reversible, but see D-08 —
  this choice is *why* the secrets mechanism had to change from the original plan.
- **D-03:** Container registry: **GitHub Container Registry (ghcr.io)**, not Docker Hub — keeps
  auth inside GitHub (see D-10).
- **D-04:** Single CI pipeline, not split workflows: PRs run `mix quality` (format/credo/sobelow/
  test) as the merge gate; merging to `main` re-runs `mix quality`, then builds, pushes, and
  deploys. A broken merge to `main` never reaches production — the quality gate is not bypassed
  for the deploy path.

### Migration Safety on Deploy
- **D-05:** Entrypoint-gated migrations — a custom Docker `ENTRYPOINT` runs the
  `phx.gen.release`-generated `bin/migrate` (wraps `Ecto.Migrator` directly, no `Mix` dependency) to
  completion before `exec bin/server`. Kamal's `GET /up` health check only passes once migrations
  succeed, so zero-downtime cutover naturally gates traffic on migration success.
- **D-06:** **Acceptance requires a live proof, not just code review**: before Phase 0 is
  considered done, ship an actual trivial schema-change migration through the full
  CI → build → Kamal pipeline and confirm the new container only goes live after migrations
  succeed. This must be an explicit task in the plan (per PITFALLS.md Pitfall 2).
- **D-07:** Failure mode is intentionally minimal for Phase 0: if a migration fails, the new
  container never becomes healthy, the old container keeps serving, and the developer finds out via
  the failed GitHub Actions run / `kamal deploy` output. No separate alerting service (Slack/email/
  webhook) is added in Phase 0 — the CI run failing is considered sufficient signal at this stage.

### Secrets Management
*(Supersedes the original "plain local `.kamal/secrets`" default — that only made sense for manual,
local-machine deploys. Since deploy is now CI-driven (D-02), secrets must be available to GitHub
Actions.)*
- **D-08:** Real secret values live as **GitHub Actions repo secrets**. `.kamal/secrets` (gitignored,
  never containing literal values) reads them via `$VAR`/command substitution at deploy time inside
  the CI job — never literal values in the file or in git history (PITFALLS.md Pitfall 3). Secrets
  covered: `SECRET_KEY_BASE`, `DATABASE_URL`, `KAMAL_REGISTRY_PASSWORD`, Cloudflare R2 access
  key/secret (nightly backup job), and the Sentry DSN (see D-17). `PHX_HOST` and other non-sensitive
  config stay `clear` in `deploy.yml`.
- **D-09:** `SECRET_KEY_BASE` (via `mix phx.gen.secret`) and the Postgres password behind
  `DATABASE_URL` are generated once locally and pasted into GitHub repo secrets manually. No
  rotation runbook is written in Phase 0 — rotate manually if/when ever needed.
- **D-10:** ghcr.io auth in CI uses the **built-in `GITHUB_TOKEN`** (already scoped for
  `packages:write` on the same repo) — no separate Personal Access Token. Valid for the lifetime of
  the CI job, which covers both the build/push step and the `kamal deploy` step that pulls the image
  onto the host, since both happen inside the same job run.
- **D-11:** Explicitly declare which secrets each Kamal role/accessory needs in `deploy.yml` rather
  than assuming global availability — an undeclared secret silently produces a blank env var
  (PITFALLS.md Pitfall 3).

### Infrastructure Readiness & Scope
- **D-12:** The Hetzner CAX31 **does not exist yet**. Phase 0's plan must include explicit
  provisioning steps as prerequisite tasks: create the server, install Docker, add the deploy SSH
  key (used by the CI job to reach the host), configure the firewall (see D-15 below re: binding
  Postgres to `127.0.0.1`).
- **D-13:** `pukllay.club` is **already registered with a DNS provider the user controls**. Phase 0
  only needs to add/point an A/AAAA record at the new server's IP once it's provisioned — no domain
  registration or DNS-provider setup is in scope.
- **D-14:** Placeholder page = **stock Phoenix welcome page, unmodified**. No branding tweak, no
  custom copy — matches "no gold-plating."
- **D-15 (carried forward, unchanged):** Bind the Postgres accessory to `127.0.0.1` only — never
  `0.0.0.0`, and don't rely on UFW alone since Docker's iptables rules bypass it. Use the
  `pgvector/pgvector:pg17` image even though the `vector` extension isn't installed yet, to avoid a
  database engine swap in Phase 2. The OTP release boots with its full default supervision tree
  (not a stripped "no background jobs" config), so adding Oban's supervisor later is additive.

### Local Dev Toolchain
- **D-16:** Add Elixir + Erlang/OTP pins to the existing `mise.toml` (currently only pins `node`,
  for GSD's own tooling) — matching whatever `mix phx.new` scaffolds (Elixir 1.19.x / OTP 28.x per
  project research). Keeps local dev, CI, and the Docker builder image on the same versions,
  avoiding "works on my machine" drift.

### Observability
- **D-17:** Add **Sentry free tier** (`sentry-elixir`) in Phase 0, even though there's no product
  code yet — catches boot-time and deploy-time crashes early rather than waiting for Phase 1+. The
  Sentry DSN is supplied as a GitHub repo secret, wired through `.kamal/secrets` the same way as the
  other secrets (D-08 pattern) — no separate mechanism.
- **D-18:** Sentry is additive, not a replacement for logging — default Phoenix `Logger` output to
  stdout (captured by Docker/journald, viewable via `kamal app logs`) stays as-is. No log
  aggregation/dashboarding service is added in Phase 0.

### Claude's Discretion
- Nightly `pg_dump` → R2 mechanism (host cron/systemd timer vs. a scheduled GitHub Actions
  workflow that SSHes in) — raised as an option during discussion but not selected for deep-dive;
  left open for research/planning. Given D-01/D-02's CI-centric pattern, a scheduled GitHub Actions
  workflow is a reasonable default to consider, but not mandated.
- Backup retention policy and restore-testing cadence — not decided. Keep simple for Phase 0 (e.g.
  keep last N dumps in R2); PITFALLS.md flags "upload succeeded ≠ backup is good," so a periodic
  manual restore-test is good practice but isn't required to be automated in Phase 0.
- CI caching key: `mix.lock` hash (not `mix.exs`) — standard, no discussion needed.
- CI Postgres service image: plain `postgres:17` for Phase 0 (not `pgvector/pgvector`) since no
  vector columns are tested yet — switch when Phase 2 lands.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope & requirements
- `.planning/PROJECT.md` — Phase 0 scope statement and the three decisions originally flagged as
  "deferred to Phase 0 planning" (§"Open decisions deferred to Phase 0 planning") — now resolved
  above, with the build/secrets decisions revised from the doc's original assumption
- `.planning/REQUIREMENTS.md` §Deploy (DEPLOY-01..05) — the five requirements this phase must satisfy
- `.planning/ROADMAP.md` §Phase 0 — goal, success criteria, requirement mapping

### Stack & implementation research (backs most decisions above)
- `.claude/CLAUDE.md` §"Technology Stack" — full stack table, Dockerfile/Kamal/secrets rationale,
  `mix quality` alias pattern, GitHub Actions CI pattern, version compatibility table
- `.planning/research/STACK.md` — underlying stack research
- `.planning/research/PITFALLS.md` — Pitfalls 1-4 are Phase-0-specific (ARM Docker build, migration
  safety, secrets, Kamal health checks) and directly back D-05 through D-11 above
- `.planning/research/ARCHITECTURE.md` §"Build-Order Implications for Phase 0's Skeleton" — what
  Phase 0 must leave room for (Postgres image choice, release supervision tree, secrets shape)
  without building it

### Not yet created
- No AGENTS.md exists yet — DEPLOY-05 requires creating it in this phase (TDD loop, `mix quality`
  alias, manual-merge-gate rule, project non-goals). No existing template to follow.

</canonical_refs>

<code_context>
## Existing Code Insights

Repo is empty of application code — no `mix phx.new` has been run yet. No GitHub remote is
configured yet (needed before any CI/Actions work — provisioning that remote is an implicit
prerequisite, not called out as its own decision above since it's a one-command `git remote add` /
`gh repo create` step, not a gray area). An existing `mise.toml` pins only `node` (for GSD's own
tooling) — D-16 adds Elixir/Erlang to it. No other existing codebase to scout for reusable assets
or patterns.

</code_context>

<specifics>
## Specific Ideas

- Deploy pipeline should be fully CI-driven end to end: PR → quality gate → merge to `main` →
  quality gate again → build (native arm64 GH Actions runner) → push to ghcr.io → `kamal deploy`,
  all inside GitHub Actions, no manual steps once a PR is merged.
- Even a zero-product-code Phase 0 should have Sentry wired up from day one, so crash visibility
  exists before Phase 1 adds real product surface area.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. The two follow-up areas (local toolchain pinning,
observability) are adjacent operational concerns for a "proven deploy pipeline," not new product
capabilities, so they were folded into this phase's decisions rather than deferred.

</deferred>

---

*Phase: 0-Walking Skeleton to Production*
*Context gathered: 2026-07-24 (revised after full discussion)*
