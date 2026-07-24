---
phase: 0
slug: walking-skeleton-to-production
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-24
---

# Phase 0 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

**Note:** Authored pre-planning from `00-RESEARCH.md` §"Validation Architecture". Task ID / Plan /
Wave / Threat Ref columns are `TBD` until the planner assigns tasks and a `<threat_model>` block —
reconcile against the actual `*-PLAN.md` files once written.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (ships with `mix phx.new`; not yet scaffolded — Wave 0 must run `mix phx.new`) |
| **Config file** | none yet — created by `mix phx.new` (`test/test_helper.exs`) |
| **Quick run command** | `mix test` |
| **Full suite command** | `mix quality` (format --check-formatted, credo --strict, sobelow, test --warnings-as-errors) |
| **Estimated runtime** | ~10-30 seconds (near-empty app; no product code this phase) |

---

## Sampling Rate

- **After every task commit:** Run `mix test`
- **After every plan wave:** Run `mix quality` (format, credo --strict, sobelow, test --warnings-as-errors)
- **Before `/gsd-verify-work`:** Full suite (`mix quality`) must be green, PLUS the DEPLOY-03 live
  migration proof (D-06) and a real `curl -sf https://pukllay.club/up` check — both manual-only,
  see below
- **Max feedback latency:** ~30 seconds (empty app; will grow once Phase 1+ adds product code)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | DEPLOY-01 | — | `/up` returns 200 with no auth required | unit/controller | `mix test test/pukllay_club_web/controllers/health_controller_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DEPLOY-02 | — | CI blocks merge on any `mix quality` failure | integration (CI) | `.github/workflows/ci.yml` against a `postgres:17` service | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DEPLOY-03 | T-0-05 | New container only serves traffic after migrations succeed | manual-only (live proof, D-06) | see Manual-Only Verifications below | N/A | ⬜ pending |
| TBD | TBD | TBD | DEPLOY-04 | T-0-01 / T-0-04 | Nightly dump lands in R2 without leaking credentials to host disk | smoke (manual trigger) | `gh workflow run backup.yml` then verify R2 bucket contents | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DEPLOY-05 | — | AGENTS.md documents TDD loop, `mix quality`, merge-gate rule, non-goals | smoke (file + grep) | `test -f AGENTS.md && grep -q "TDD" AGENTS.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mix phx.new pukllay_club --database postgres` (or equivalent) — the scaffold itself; nothing
      exists in this repo yet
- [ ] `test/pukllay_club_web/controllers/health_controller_test.exs` — stub covering DEPLOY-01's `/up`
- [ ] `.github/workflows/ci.yml` — covers DEPLOY-02 (mix quality gate)
- [ ] `.github/workflows/deploy.yml` — covers DEPLOY-03 (build+push+deploy; the migration-gating
      live proof itself is a manual D-06 task, not a file)
- [ ] `.github/workflows/backup.yml` — covers DEPLOY-04 (nightly pg_dump → R2)
- [ ] `AGENTS.md` — covers DEPLOY-05

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `kamal deploy` ships zero-downtime + migrations-on-deploy | DEPLOY-03 | Inherently an end-to-end infra proof (D-06) — no unit test can prove real container-swap timing against a live Hetzner host | Ship an actual trivial schema-change migration through the full CI → build → Kamal pipeline; confirm the new container only serves traffic after migrations succeed (old container keeps serving during the migration window); check `schema_migrations` plus the GitHub Actions / `kamal deploy` logs |
| Production HTTPS + placeholder page reachable | DEPLOY-01 | External, internet-facing infra check — not assertable from ExUnit | `curl -sf https://pukllay.club/up` (run manually, or add as a post-deploy CI smoke step) |
| Nightly `pg_dump` lands in R2 | DEPLOY-04 | Requires a real R2 bucket and a real cron/schedule firing — can't be unit tested | Manually trigger via `gh workflow run backup.yml` (`workflow_dispatch`), then verify a new dump object appears in the R2 bucket |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
