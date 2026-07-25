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

### Repository Visibility (revised during 00-03 execution)
- **D-19 (supersedes the original private-repo assumption in plan 00-03's Task 1 and this phase's
  earlier "private repo" framing):** The `pukllay_club` GitHub repository was flipped from
  **private to public** during 00-03 execution, on explicit, informed user confirmation, after
  the plan's Task 3 (branch protection requiring the CI `quality` check on `main`) failed on a
  private repo with `403 Upgrade to GitHub Pro or make this repository public to enable this
  feature.` GitHub Free (personal accounts) only supports branch protection / rulesets on public
  repositories.
  - **Rationale:** (1) the project is also intended as part of the user's professional portfolio —
    public visibility is a feature, not just a workaround for the branch-protection limitation;
    (2) verified before flipping: no secrets exist anywhere in git history or tracked files;
    `.github/workflows/ci.yml` references zero repository secrets and uses the safe
    `on: pull_request` trigger (not `pull_request_target`), so public visibility introduces no
    secret-exposure risk for the CI workflow as authored; (3) GitHub Actions repository secrets
    (Settings -> Secrets and variables -> Actions) are visibility-agnostic — encrypted, write-only,
    usable only by accounts with write access (just the user) — so future secrets (D-08's
    `SECRET_KEY_BASE`, `DATABASE_URL`, `KAMAL_REGISTRY_PASSWORD`, R2 keys, Sentry DSN) remain safe
    under public visibility.
  - **Accepted tradeoff, flagged forward to plan 00-06 (nightly backup):** GitHub's "60-day
    scheduled-workflow auto-disable" quirk (previously assumed moot per 00-RESEARCH.md's private-
    repo framing) **does apply to public repos**. Accepted as a minor, mitigable risk — a repo
    under active multi-phase development is unlikely to go 60 days without a commit, and a trivial
    monthly keepalive workflow (or any commit cadence) is the documented fallback if the nightly
    backup workflow (`schedule:` cron) ever silently disables. **Plan 00-06 must account for this
    when authoring the nightly `pg_dump` -> R2 workflow** — either accept the risk explicitly in
    that plan's context or add a lightweight keepalive step.
  - **Reversibility:** reversible (repo visibility can be flipped back to private at any time via
    `gh repo edit --visibility private`), but flipping back would immediately break the
    branch-protection-on-`main` gate re-established here (Task 3) unless GitHub Pro is purchased
    first.

### Compute Provider & Architecture (revised during 00-05 execution)
- **D-20 (supersedes CLAUDE.md's "Hetzner CAX31 (ARM/aarch64)" deploy constraint and D-12/D-13's
  Hetzner-specific provisioning framing):** The production host is **Google Cloud e2-micro**
  (x86_64), not a Hetzner CAX31 (ARM/aarch64), provisioned in `us-central1-a`.
  - **Why:** A 2026 industry-wide DRAM/NVMe hardware shortage left Hetzner's CAX (ARM) line, its
    entire Cost-Optimized (CX, x86) tier, *and* Oracle Cloud's Always Free ARM tier (in the user's
    home region, Vinhedo/Brazil) all out of capacity at time of provisioning — not a pricing issue,
    a stock issue, confirmed via direct account attempts on all three. The only immediately
    purchasable Hetzner option (Regular Performance/CPX tier) quoted ~$14/mo for just 1 vCPU/2GB —
    poor value given the project's real traffic profile.
  - **Rationale for GCP e2-micro specifically:** (1) genuinely the cheapest viable option found —
    Compute is Always-Free-tier ($0/mo); only cost is GCP's mandatory external-IPv4 charge
    (~$0.005/hr, ~$3.60/mo, in effect since Feb 2024, applies to ephemeral *and* static IPs equally
    and is not covered by Always Free) — well under the original ~€15/mo total budget line; (2)
    e2-micro is old, commodity hardware Google has provisioned since 2017 and was not observed to be
    affected by the 2026 shortage that hit newer/premium instance types; (3) actual expected load
    (~50 users on a weekend, per the user's own estimate) is comfortably served by 2 shared vCPU /
    1GB RAM for a lean Phoenix/LiveView app + Postgres — the original CAX31 sizing (8 vCPU/16GB) had
    headroom for later phases, not a Phase 0 requirement.
  - **Downstream changes this forces:**
    - **Architecture:** x86_64, not ARM/aarch64. `Dockerfile`'s builder platform and the CI/deploy
      workflow's build target (00-04's `deploy.yml` GitHub Actions workflow assumed a native arm64
      build via a `ubuntu-24.04-arm` runner per D-01) must switch to plain `ubuntu-latest` (x86) —
      this is a simplification, not just a change: no more native-arm64-runner or cross-build
      concern. It also *de-risks* Phase 2 (EXLA/XLA precompiled binaries are more broadly available
      for x86_64 than the arm64-specific verification CLAUDE.md's stack research had to do).
    - **CLAUDE.md's "Deploy" constraint** must be updated to reflect GCP e2-micro (x86_64) in place
      of Hetzner CAX31 (ARM/aarch64) — flagged per CLAUDE.md's own "fixed; flag before deviating"
      rule, not silently changed.
    - **SSH access model:** GCP's metadata-based SSH key provisioning creates a non-root sudo-capable
      user (`deploy`), not direct root access (the Hetzner/Oracle assumption). `config/deploy.yml`
      needs `ssh: { user: "deploy" }`, and Kamal's Docker operations on the host run via sudo.
    - **Memory mitigation:** a 2GB swap file (`/swapfile`, `fstab`-persisted) was added on the host —
      not part of the original plan — specifically because Kamal's zero-downtime deploy briefly runs
      two app containers simultaneously during cutover, which a bare 1GB physical RAM box would risk
      OOM-killing. Swap converts that risk into "briefly slower," not "deploy fails" — and per D-05,
      a failed/unhealthy new container never gets cut over regardless (old container keeps serving).
    - **IP:** a GCP **static reserved** external IP (`pukllay-club-ip`) was chosen over ephemeral —
      unlike Hetzner/Oracle, GCP charges the *same* (~$3.60/mo) for ephemeral vs. static, so static
      was picked purely for DNS stability across stop/start at no cost premium (the same "ephemeral
      IP changes on restart, breaks DNS" risk flagged for Oracle applies equally to GCP's ephemeral
      option, but the usual free-vs-paid tradeoff that made Oracle's static IP a clear win doesn't
      apply here — it's just strictly better on GCP).
    - **`DATABASE_URL` is unaffected** by the provider change — Kamal's accessory networking (the app
      reaches the Postgres accessory via its declared name, `db`, as a Docker network alias) is
      provider-agnostic. Already set as a GitHub secret:
      `ecto://postgres:{password}@db:5432/pukllay_club_prod`.
  - **Accepted tradeoffs, flagged forward:**
    - Latency: `us-central1-a` (Iowa, USA) instead of an EU/Hetzner location — worse for
      Argentina-based users than the originally-planned EU host, but still far better than the
      Singapore alternative considered for Oracle. Accepted given no other viable option existed at
      provisioning time.
    - **Phase 2 sizing risk (important):** 2 vCPU (shared) / 1GB RAM is very likely inadequate for
      local Bumblebee/EXLA embedding inference, even for `intfloat/multilingual-e5-small`. This
      compounds the Phase 2 spike CLAUDE.md already flags as a genuine open risk — resolving it may
      now require either a host resize/re-provision (once capacity conditions improve) *or* falling
      back to the documented Plan B (a remote embedding API called async via Oban), rather than
      treating local CPU embeddings as the default assumption. Do not skip or shortcut Phase 2's
      spike on the assumption that "it'll fit" — verify against this box's real constraints.
  - **Reversibility:** reversible in principle (re-provision on Hetzner/another ARM host once
    capacity frees up, or upsize within GCP), but not a trivial single-setting flip like D-19 — it
    means redoing host provisioning, `deploy.yml` wiring, DNS, and secrets again.

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
