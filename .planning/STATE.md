---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 01
current_phase_name: catalog-v1
status: executing
stopped_at: Completed 01-05-PLAN.md
last_updated: "2026-08-11T15:53:26.306Z"
last_activity: 2026-08-10
last_activity_desc: Phase 01 execution resumed (wave continue)
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 12
  completed_plans: 11
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-24)

**Core value:** A member can describe what they want in plain Spanish and find a game that fits —
even without already knowing board-game vocabulary.
**Current focus:** Phase 01 — catalog-v1

## Current Position

Phase: 01 (catalog-v1) — EXECUTING
Plan: 2 of 6
Status: Ready to execute
Last activity: 2026-08-18 - Completed quick task 260818-fro: Integrate Tidewave (dev-only) MCP plug into Phoenix endpoint
structure (0-4)

Progress: [█████████░] 92%

## Performance Metrics

**Velocity:**

- Total plans completed: 6
- Average duration: - min
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 00 | 6 | - | - |

**Recent Trend:**

- Last 5 plans: none yet
- Trend: -

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 00 P01 | 35min | 3 tasks | 60 files |
| Phase 00 P02 | 5min | 1 tasks | 2 files |
| Phase 00 P03 | 90min | 3 tasks | 3 files |
| Phase 00 P04 | 197min | 3 tasks | 6 files |
| Phase 00 P05 | 50min | 3 tasks | 8 files |
| Phase 00 P06 | 20min | 2 tasks | 1 files |
| Phase 01 P02 | 30min | 3 tasks | 11 files |
| Phase 01 P01 | 63min | 2 tasks | 8 files |
| Phase 01 P03 | 85min | 2 tasks | 24 files |
| Phase 01 P05 | 26min | 3 tasks | 10 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Project init: Fixed 5-phase roadmap order (0 Deploy Skeleton -> 1 Catalog -> 2 NL Search+Auth ->
  3 Rules Oracle -> 4 Club Ops), no reordering, later work never pulled forward

- Project init: Elixir/Phoenix 1.8 LiveView, single Postgres DB (pgvector + tsvector), Kamal 2 to a
  single Hetzner CAX31 (ARM), no umbrella, no microservices, no separate vector DB/search/auth
  service

- Project init: Local CPU embeddings (Bumblebee/EXLA) + remote free-tier LLM (Gemini via
  InstructorLite), split so no LLM call ever sits on the request hot path

- [Phase ?]: mise.toml pins elixir 1.19.5-otp-28 / erlang 28.5, matching phx.gen.release's own builder image tag (D-16)
- [Phase ?]: Credo Design.AliasUsage exit_status set to 0 for phx.new-generated boilerplate under --strict; Sobelow Config.CSP explicitly ignored with reviewed rationale (deferred to Phase 1) rather than disabling exit codes wholesale
- [Phase ?]: Sentry.LoggerHandler attached manually via :logger.add_handler/3 with enable_logs: true (not the config-only auto-attach path), keeping the call site explicit in application.ex
- [Phase ?]: AGENTS.md conventions (DEPLOY-05): appended TDD loop, mix quality order, manual-merge-gate rule, and Phase 0 non-goals into the phx.new-generated AGENTS.md rather than overwrite it
- [Phase ?]: D-19: repo flipped private->public during 00-03 execution (explicit user decision) — GitHub Free doesn't support branch protection/rulesets on private repos; verified no secrets in git history or ci.yml before flipping
- [Phase ?]: Branch protection on main requires the 'quality' status check (strict, enforce_admins=true, no bypass) — future plans must land main commits via PR, not direct push, since a required check now blocks bare git push to main
- [Phase ?]: 00-04: Kamal deploy.yml/servers.web and the db accessory host use a placeholder pending 00-05 host provisioning (D-12); webfactory/ssh-agent pinned to v0.9.0 (v0.9 is not a resolvable tag)
- [Phase ?]: 00-05: D-20 executed — GCP e2-micro (x86_64) production host wired into config/deploy.yml + deploy.yml workflow (ssh.user: deploy, builder.arch: amd64, ubuntu-latest runner), superseding the Hetzner CAX31/arm64 assumption
- [Phase ?]: 00-05: kamal setup used once for first-time GCP bootstrap, then switched to kamal deploy --skip-push (D-02 steady state) once confirmed healthy; CI builds+pushes the image directly (docker/build-push-action) and Kamal only pulls the matching git-SHA tag
- [Phase ?]: 00-05: PukllayClub.Release.createdb/0 added as a permanent, idempotent database-bootstrap step (not a one-off manual CREATE DATABASE) since this project has already had to re-provision its production host once this phase
- [Phase ?]: 00-05: DEPLOY-01 and DEPLOY-03 proven live via two checkpoint:human-verify gates — HTTPS+/up+localhost-Postgres, and a real migration shipped through CI->build->Kamal proven to gate zero-downtime cutover (D-06)
- [Phase ?]: 00-06: Nightly backup mechanism = scheduled GitHub Actions over SSH (not host cron/systemd), keeping R2 credentials in GitHub secrets (D-08 pattern); 60-day scheduled-workflow auto-disable risk (D-19) explicitly accepted, no keepalive added
- [Phase ?]: 01-02: daisyUI theme values kept as hex (not oklch) per 01-UI-SPEC.md, preserving traceability to the brand manual
- [Phase ?]: 01-02: info/success/warning -content colors (unspecified by UI-SPEC's 17-var table) converted to brand hex to eliminate all remaining stock oklch values
- [Phase ?]: 01-02: fixed pre-existing invalid 'E' regex modifier in config/runtime.exs live_reload patterns that blocked mix test in every environment (Rule 3 blocking fix)
- [Phase ?]: 01-01: Config key for BGG/R2 seed credentials is PukllayClub.Catalog.Seed (not .Credentials), shared across dev.exs/test.exs/dev.secret.exs.example so future seed modules reuse one config block
- [Phase ?]: 01-01: config/dev.secret.exs routed as dev-machine-only gitignored secret, deliberately not through Kamal, since the seed pipeline never runs on the production host
- [Phase ?]: Quick task 260806-rq8: Wired Styler (adobe/elixir-styler, mix format plugin) + mix_audit into mix quality (7-step: hex.audit, deps.audit, deps.unlock --check-unused, format, credo, sobelow, test); first-run rewrite manually reviewed per hunk, one misplaced comment corrected
- [Phase ?]: 01-03: games.csv_row (not bgg_id) is the upsert conflict target — re-runnable one-time seed task (D-02) and preserves both duplicate-BGG_ID 163412 rows (D-19)
- [Phase ?]: 01-03: ImagePipeline enforces its 15MB download cap via a hand-rolled Req into: accumulator (pinned req has no max_length option) — same T-01-10 mitigation, different mechanism
- [Phase ?]: 01-03: seed modules (R2Storage/BggClient) never read secrets from Application env directly — every call takes an explicit Credentials.t() struct built once by the mix task (T-01-11)
- [Phase ?]: 01-03: GameCard's Ver detalles CTA renders as an inert button, not a link to a not-yet-existing /games/:id route — game detail page is explicit 01-06 scope
- [Phase ?]: 01-05: The 8 D-09 carousel rows include 3 weight-band rows in addition to Destacados/3 editorial hashtags/Recientemente añadidos, resolving an under-specified plan prose against the plan's own artifact list and row-count
- [Phase ?]: 01-05: filter_games/1 composes search+OR-within-facet+AND-across-facets+scalar filters+sort+pagination into one Ecto maybe_* pipeline; sort/facet keys parsed via literal string clauses, never String.to_atom/1
- [Phase ?]: 01-05: loading skeletons use LiveView's disconnected/connected two-phase mount (:loading = not connected?(socket)) rather than simulated async latency, since Catalog reads are synchronous and fast at this row count

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 0: Three implementation decisions are explicitly deferred to Phase 0
  discuss-phase/plan-phase rather than assumed now — Dockerfile strategy for aarch64, safe Ecto
  migrations via Kamal, and minimal secrets management approach (see PROJECT.md "Open decisions")

- Phase 2: Embedding runtime throughput/latency for local CPU embeddings is a genuine open
  unknown (research/SUMMARY.md) — must be resolved via an explicit spike before committing to
  Bumblebee vs. an alternative runtime or a specific model; do not skip or shortcut this spike.
  **Compounded by 00-CONTEXT.md D-20:** production moved from the originally-planned Hetzner CAX31
  (ARM, 8 vCPU/16GB) to a GCP e2-micro (x86_64, 2 vCPU shared/1GB RAM) due to a capacity shortage —
  1GB RAM is very likely inadequate for local embedding inference even for a small model. The
  spike must verify against this box's actual constraints, not the original sizing; be ready to
  fall back to the documented remote-embedding-API Plan B (CLAUDE.md "Alternatives Considered")
  rather than assume local CPU embeddings will fit.

- Phase 2: Gemini free-tier model name and RPM/RPD limits need re-verification at implementation
  time (documentation churns faster than research can track)

- Phase 0 (plans 00-04 onward): main is now branch-protected requiring the 'quality' CI check — direct 'git push origin main' is rejected once a required status check exists. Future plan executors must land commits via a short branch + PR (gh pr create -> wait for CI -> gh pr merge), not a bare push, even though .planning/config.json still has git.branching_strategy:
- Plan 00-06 (nightly backup): repo is now public (00-03 D-19), so GitHub's 60-day scheduled-workflow auto-disable applies to the nightly pg_dump->R2 cron workflow. Must accept this risk explicitly or add a keepalive mechanism when planning/executing 00-06.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260806-rq8 | Add Styler + mix_audit quality gates (superseded credence) to mix quality | 2026-08-06 | 9477e7f | [260806-rq8-add-credence-semantic-ast-elixir-linter-](./quick/260806-rq8-add-credence-semantic-ast-elixir-linter-/) |
| 260818-fro | Integrate Tidewave (dev-only) MCP plug into Phoenix endpoint | 2026-08-18 | d3761dd | [260818-fro-integrate-tidewave-dev-only-into-phoenix](./quick/260818-fro-integrate-tidewave-dev-only-into-phoenix/) |

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-08-11T15:53:26.241Z
Stopped at: Completed 01-05-PLAN.md
verified against the roadmap (no edits needed)
Resume file: None
