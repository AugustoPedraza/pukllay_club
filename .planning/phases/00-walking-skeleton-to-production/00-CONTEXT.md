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

**Discussion was skipped by explicit user choice** ("none" — proceed with defaults). The three
decisions PROJECT.md flagged as "deferred to Phase 0 planning" (Dockerfile strategy, migration
safety, secrets management) are locked below using the project's own pre-existing research
(`.planning/research/STACK.md`, `.planning/research/PITFALLS.md`, `.planning/research/ARCHITECTURE.md`,
and the Technology Stack section of `.claude/CLAUDE.md`) rather than left ambiguous — that research
is deep, specific, and was already treated as authoritative going into this discussion.

### Build & Deploy Strategy
- **D-01:** `mix phx.gen.release --docker` generates the Dockerfile. Runner stage is
  `debian:trixie-slim` (glibc), not Alpine — avoids musl DNS resolution issues and keeps the door
  open for EXLA/Bumblebee in Phase 2 without a base-image swap. — **Reversibility:** reversible —
  swapping base images later is a Dockerfile edit, not a design change.
- **D-02:** The arm64 image is built natively — either on the Hetzner CAX31 host itself via Kamal's
  default `builder: { arch: arm64 }` (no `remote:` override), or on a native `ubuntu-24.04-arm`
  GitHub Actions runner if CI-driven builds are wanted later. Default for Phase 0: **build on the
  Hetzner host** — zero extra CI runner setup, matches solo-dev/near-zero-ops budget. QEMU-emulated
  cross-builds are explicitly rejected (PITFALLS.md: slow, occasionally flaky NIF cross-compiles).
  — **Reversibility:** reversible — changing the builder target is a `deploy.yml` config change.
- **D-03:** `kamal deploy` is triggered manually from the developer's machine for Phase 0, not
  CI-driven. GitHub Actions CI's job is limited to running `mix quality` gates on PRs — it does not
  deploy. — **Reversibility:** reversible.

### Migration Safety on Deploy
- **D-04:** Entrypoint-gated migrations — a custom Docker `ENTRYPOINT` that runs the
  `phx.gen.release`-generated `bin/migrate` (wrapping `Ecto.Migrator` directly, no `Mix` dependency)
  to completion *before* `exec bin/server` starts. Kamal's health check (`GET /up`) then only passes
  once migrations succeeded, so Kamal's zero-downtime cutover naturally gates traffic on migration
  success — a failed migration leaves the old container serving traffic instead of promoting a
  broken one. — **Reversibility:** reversible.
- **D-05:** Acceptance for this decision requires proving it, not just wiring it: before Phase 0 is
  considered done, deploy an actual schema change through the full Kamal pipeline and confirm the
  new container only goes live after migrations succeed (per PITFALLS.md Pitfall 2). This should be
  an explicit task/verification step in the plan, not assumed to work from code review alone.

### Secrets Management
- **D-06:** Plain `.kamal/secrets` (gitignored, dotenv-format), values entered directly on the
  developer's machine — no 1Password/Bitwarden/Doppler integration. This is safe specifically
  *because* deploys are manual/local (D-03) — the file never needs to exist in CI, so there's no
  risk of it leaking through CI logs or repo secrets. If deploys later move to CI-driven (see D-02
  reversibility), secrets must switch to env-var substitution sourced from CI-injected values at
  that point, per PITFALLS.md Pitfall 3 — not before.
- **D-07:** Clear vs. secret split: `PHX_HOST` (and other non-sensitive config) as `clear` vars in
  `deploy.yml`; `SECRET_KEY_BASE`, `DATABASE_URL`, `KAMAL_REGISTRY_PASSWORD`, and the Cloudflare R2
  access key/secret (for the nightly backup job) as `secret` vars resolved from `.kamal/secrets`.
  Explicitly declare required secrets per role/accessory rather than assuming global availability
  (PITFALLS.md Pitfall 3 — missing per-role declarations silently produce blank env vars).
  — **Reversibility:** reversible.
- **D-08:** The secrets mechanism must generalize to "one more secret" (a Gemini API key arrives in
  Phase 2) without a redesign — confirmed by D-06/D-07's shape (any new secret is just another line
  in `.kamal/secrets` + a `secret:` declaration), so no special handling needed now.

### Infrastructure Readiness & Scope
- **D-09:** Provisioning the Hetzner CAX31 and pointing `pukllay.club` DNS at it are in scope for
  Phase 0, but are manual one-time operator steps (creating a Hetzner server, configuring DNS) that
  Claude cannot perform on the user's behalf. The plan must document these as explicit prerequisite
  steps with clear instructions, not silently assume infra already exists.
- **D-10:** Bind the Postgres accessory to `127.0.0.1` only on the Hetzner host — never expose it on
  `0.0.0.0` and never rely on UFW alone (Docker's iptables rules bypass UFW), per PITFALLS.md.
- **D-11:** Use the `pgvector/pgvector:pg17` image for the Postgres accessory even though Phase 0
  never installs the `vector` extension — avoids a database engine swap when Phase 2 needs it.
  Verify once during Phase 0 setup that `CREATE EXTENSION vector` *would* succeed (a one-line check,
  not new work), per ARCHITECTURE.md's Build-Order Implications.
- **D-12:** The OTP release boots with its full default supervision tree (not a stripped-down "no
  background jobs" config) — so adding Oban's supervisor and an `Nx.Serving` child in Phase 2 is an
  additive `application.ex` change, not a restructuring of how the release boots.

### Claude's Discretion
- Placeholder page content: use Phoenix's stock generated LiveView welcome page, no custom design —
  matches Phase 0's "no gold-plating" goal. A "Pukllay Club" branded tweak is fine if trivial, but
  not required.
- Nightly `pg_dump` → R2 mechanism: a cron/systemd timer on the Hetzner host (or a scheduled GitHub
  Actions workflow that SSHes in) invoking a shell script that dumps and uploads via an S3-compatible
  client (rclone or aws-cli) — not Oban (out of scope for Phase 0). Exact choice between host-cron
  vs. GitHub Actions schedule is left to research/planning.
- Backup retention policy and restore-testing cadence: not specified by the user. Keep simple for
  Phase 0 (e.g., keep last N dumps); PITFALLS.md flags "upload succeeded ≠ backup is good" — a
  periodic manual restore-test is good practice but doesn't need full automation in Phase 0.
- GitHub Actions CI caching key: `mix.lock` hash (not `mix.exs`), per project research — standard,
  no discussion needed.
- CI Postgres service image: plain `postgres:17` for Phase 0 (not `pgvector/pgvector`) since no
  vector columns are tested yet — switch when Phase 2 lands.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope & requirements
- `.planning/PROJECT.md` — Phase 0 scope statement and the three decisions this discussion locks
  (§"Open decisions deferred to Phase 0 planning")
- `.planning/REQUIREMENTS.md` §Deploy (DEPLOY-01..05) — the five requirements this phase must satisfy
- `.planning/ROADMAP.md` §Phase 0 — goal, success criteria, requirement mapping

### Stack & implementation research (authoritative — this discussion's decisions derive from these)
- `.claude/CLAUDE.md` §"Technology Stack" — full stack table, Dockerfile/Kamal/secrets rationale,
  `mix quality` alias pattern, GitHub Actions CI pattern, version compatibility table
- `.planning/research/STACK.md` — underlying stack research
- `.planning/research/PITFALLS.md` — Pitfalls 1-4 are Phase-0-specific (ARM Docker build, migration
  safety, secrets, Kamal health checks) and directly back D-01 through D-11 above
- `.planning/research/ARCHITECTURE.md` §"Build-Order Implications for Phase 0's Skeleton" — what
  Phase 0 must leave room for (Postgres image choice, release supervision tree, secrets shape) without
  building it

### Not yet created
- No AGENTS.md exists yet — DEPLOY-05 requires creating it in this phase (TDD loop, `mix quality`
  alias, manual-merge-gate rule, project non-goals). No existing template to follow; this is new
  content for this phase.

</canonical_refs>

<code_context>
## Existing Code Insights

Repo is empty of application code — no `mix phx.new` has been run yet. No `mise.toml` pin for
Elixir/Erlang exists yet (only `node` is pinned, for GSD tooling itself). No GitHub remote is
configured yet. This phase starts from a bare git repo with only `.planning/` and `.claude/`
content — there is no existing codebase to scout for reusable assets or patterns.

</code_context>

<specifics>
## Specific Ideas

No specific UI/content requirements from the user beyond what's captured in Claude's Discretion
above (stock Phoenix placeholder page). No particular tools, services, or examples were named
beyond what's already fixed in PROJECT.md's constraints (Kamal, kamal-proxy, Hetzner CAX31,
Cloudflare R2, GitHub Actions).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. User declined to discuss any of the four proposed
gray areas (build strategy, migration safety, secrets, infra readiness) and asked Claude to decide
using existing research, which is captured above.

</deferred>

---

*Phase: 0-Walking Skeleton to Production*
*Context gathered: 2026-07-24*
