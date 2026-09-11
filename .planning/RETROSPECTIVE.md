# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP Catalog

**Shipped:** 2026-09-11
**Phases:** 8 (Phase 0, Phase 1 + insertions 01.1–01.6) | **Plans:** 87 | **Tasks:** 228

### What Was Built
- A live, deployed Phoenix app at https://pukllay.club with CI, zero-downtime Kamal deploys, migrations-on-deploy, and nightly R2 backups (Phase 0).
- A public catalog of ~400 games seeded from BGG with complexity-teaching UX (plain-Spanish weight bands, mechanic/theme chips), full browse/filter/keyword search, and no auth (Phase 1).
- A shared header/footer shell, game detail pages (buy-box + reading column + similar-games shelf), and a filter modal — plus 32 plans and 10 UAT gap-closure rounds polishing catalog/detail navigation (Phases 01.1–01.2).
- Real BGG stats, natural Argentine-Spanish game descriptions (Gemini-translated), designer/artist filtering, and corrected gallery image cropping (Phases 01.3–01.3.1).
- A fully realized About page: isologo scroll-morph with a companion wordmark, de-chromed Contacto chips, a live Maps embed, and a full-viewport closing band with unified CTA rhythm (Phases 01.4–01.5).
- A unified light/dark theme built on one shared OKLCh ramp, closing a long-running "dark mode feels wrong" complaint (Phase 01.6).

### What Worked
- The decimal-phase insertion pattern (01.1, 01.2, ...) handled real mid-milestone scope growth (UI polish, gap closures) without disrupting the fixed 0→4 phase order.
- Live CDP/headless-Chrome probes (`test/visual/about_geometry.mjs` and friends) caught real rendering bugs (cascade-layer conflicts, aspect-ratio crops, whitespace strips) that DOM-declaration-level tests couldn't see — and were reusable ad hoc at milestone-close time to close out the last open verification gap without needing the Claude-in-Chrome extension.
- Routing genuine design-preference rejections (e.g. the mobile CTA) through `gsd-sketch` rather than the autonomous debug pipeline avoided several rounds of the diagnose-issues loop mis-treating a UX call as a code defect.
- Requirements traceability (DEPLOY-*, CATALOG-*, SHELL-*) stayed accurate enough that verifying "is v1.0 actually done" was a 30-second grep, not an audit.

### What Was Inefficient
- The mobile sticky CTA on the About page went through three full design/implementation rounds (full-width bar → user-rejected floating pill → hero-synced full-width bar) before landing — each round required its own sketch, plan, and UAT cycle. Earlier convergence on an industry-standard pattern reference (which the user explicitly asked for in round 2) could have skipped a round.
- ROADMAP.md and STATE.md drifted from reality more than once during the milestone (Phase 01.6 marked "complete" in STATE.md prose with no formal phase directory; PROJECT.md's Constraints section still described the original Hetzner ARM host weeks after the GCP e2-micro pivot). Neither was caught until this milestone-close review.
- The `milestone.complete` CLI's unstarted-phase guard scans the whole ROADMAP.md when no prior milestone exists to scope against — it doesn't understand "close with a narrower scope than the full document." Closing v1.0 as just Phase 0+1 (deferring Phase 2-4) required `--force` plus a manual, out-of-band phase-directory archival to avoid the tool mis-archiving Phase 2's already-created `02-UI-SPEC.md` directory into v1.0's snapshot.

### Patterns Established
- Reactive, quality-fix-only phases with no REQ-IDs (01.4, 01.5, 01.6) are acceptable when they're driven entirely by a phase's own CONTEXT.md/RESEARCH.md decisions — not every phase needs a roadmap requirement to justify its existence.
- A phase can be legitimately composed entirely of quick tasks (01.6) rather than formal PLAN/SUMMARY files, as long as ROADMAP.md documents it with the same rigor (goal, plans-executed count, key decisions).

### Key Lessons
1. When closing the *first* milestone of a project with an unscoped (version-marker-free) ROADMAP.md, `gsd_run query milestone.complete --dry-run` before the real run is essential — it surfaces exactly which phase directories the CLI would archive, and a phase with only a UI-SPEC.md (no plans) can slip in unless checked.
2. A `human_needed` verification gate that's down to one specific, narrowly-scoped perceptual check (not "re-review everything") is fast to close even without live browser tooling — a zero-dependency Node CDP script reusing the project's own existing probe pattern got screenshots in minutes.
3. Keep PROJECT.md's Constraints section as a living fact sheet, not a project-init snapshot — infra pivots (like the Hetzner→GCP switch) need to propagate there immediately, not just into a Key Decisions row.

### Cost Observations
- Sessions: many (spanning 2026-07-24 to 2026-09-11, ~48 days)
- Notable: 24 known-debt items (mostly diagnosed-but-cosmetic UI findings) were acknowledged rather than fixed at close — a deliberate tradeoff to ship v1.0 now rather than clear every minor visual finding first.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | many | 8 | First milestone — established the decimal-insertion pattern and the reactive-quality-phase (no REQ-IDs) pattern |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | 883+ | not tracked | `test/visual/*.mjs` CDP probes (2+) |

### Top Lessons (Verified Across Milestones)

1. (First milestone — no cross-milestone verification yet.)
