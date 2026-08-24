---
phase: 1
slug: catalog-v1
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-28
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built into Elixir; already wired via `mix test` alias in `mix.exs`) |
| **Config file** | none dedicated — `test/test_helper.exs` exists (`Ecto.Adapters.SQL.Sandbox.mode(PukllayClub.Repo, :manual)`) |
| **Quick run command** | `mix test <relevant single file>` |
| **Full suite command** | `mix test` (aliased to run `ecto.create --quiet && ecto.migrate --quiet && test`) |
| **Estimated runtime** | ~15-30 seconds (small Phase 0 baseline suite + new Phase 1 tests, ~400-row seed not required for unit/LiveView tests which use fixtures, not the real seed) |

---

## Sampling Rate

- **After every task commit:** Run `mix test <relevant single file>`
- **After every plan wave:** Run `mix test` (full suite)
- **Before `/gsd-verify-work`:** Full suite green, plus `mix quality` (project convention)
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

Task IDs are assigned during planning (step 8) — rows below map at requirement granularity per
01-RESEARCH.md's Validation Architecture section; the planner should attach these to the specific
task(s) that implement each requirement.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | CATALOG-01 | — | Public route, no auth plug | LiveView integration | `mix test test/pukllay_club_web/live/catalog_live_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CATALOG-02 | — | Ecto `fragment/2` with pinned params (no string interpolation) | Context unit | `mix test test/pukllay_club/catalog_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CATALOG-03 | T-01-01 (search DoS) | GIN-indexed `search_vector` + bounded `LIMIT` | Context unit + LiveView integration | `mix test test/pukllay_club/catalog_test.exs test/pukllay_club_web/live/catalog_live_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CATALOG-04 | — | Sort on indexed scalar columns | Context unit | `mix test test/pukllay_club/catalog_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CATALOG-05 | — | Weight-band read from hashtag/tie-break, never re-derived from raw float | LiveView integration (rendered HTML assertion) | `mix test test/pukllay_club_web/live/catalog_live_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CATALOG-06 | — | Plain-Spanish glossary chip rendering | LiveView integration | `mix test test/pukllay_club_web/live/catalog_live_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CATALOG-07 | — | Editorial tag carried to card | Context unit + LiveView integration | same as above | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CATALOG-08 | — | Unauthenticated connection succeeds | LiveView/router integration | `mix test test/pukllay_club_web/live/catalog_live_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CATALOG-09 | T-01-02 (credential/token leakage) | Stored URL host asserted as R2, not BGG; BGG/R2 tokens never in client-visible code | Seed-task unit (mock R2/HTTP boundary) | `mix test test/pukllay_club/catalog/seed/image_pipeline_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/pukllay_club/catalog_test.exs` — context-level filter/sort/search coverage for
      CATALOG-02/03/04
- [ ] `test/pukllay_club_web/live/catalog_live_test.exs` — LiveView integration coverage for
      CATALOG-01/03/05/06/07/08
- [ ] `test/pukllay_club/catalog/seed/image_pipeline_test.exs` — seed-task image-pipeline unit
      coverage for CATALOG-09 (mock the BGG HTTP fetch + R2 upload boundary; never hit real
      external services in CI)
- [ ] `test/support/fixtures/catalog_fixtures.ex` — shared `Game` fixture factory (weight bands,
      hashtags, mechanics/themes)
- [ ] Test-DB fixture data must include at least one game per weight band and per editorial hashtag
      to exercise CATALOG-05/06/07 rendering paths meaningfully (not just one generic fixture game)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Seed task's live BGG API enrichment + R2 image upload against the real ~400-game dataset | CATALOG-09 (and enrichment inputs to CATALOG-02/05/06) | Depends on a registered BGG application token and real network/R2 access — not mockable end-to-end without losing the point of the check; CI mocks the boundary (see Wave 0) but the real run must be verified manually once | Run the seed `mix` task once against a registered BGG token and the dev/staging DB; spot-check ~10 games across weight bands/hashtags/missing-BGG_ID cases render correctly in the browser; confirm R2-hosted image URLs load (not BGG hotlinks) |
| Spanish accent-insensitive search (`unaccent` + custom search config, if adopted per Pitfall 4) | CATALOG-03 | Requires a human judgment call on whether the UX gap (unaccented query missing accented title) is worth the added migration complexity for this catalog's real title/designer data | Search using an unaccented variant of a known accented title/designer in the seeded catalog; confirm expected results appear |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
