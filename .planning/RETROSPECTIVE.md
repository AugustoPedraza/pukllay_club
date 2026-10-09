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

## Milestone: v1.1 — Sharable Version

**Shipped:** 2026-10-09 (override closeout)
**Phases:** 5 | **Plans:** 63 | **Tasks:** 166 | **Commits:** 630 | **Span:** 2026-09-11 → 2026-10-09 (28 days)

### What Was Built

Production got its real catalog (434 games restored over an SSH tunnel), then the three things
that make the site shareable and staff-operable: SEO/OG/JSON-LD so a link unfurls correctly,
a magic-link staff admin with `games.status` lifecycle and BGG-driven enrichment, and a
phone-first admin redesign across Juegos, Estantes and Web — copies as rows with per-estante
position, staff-owned sections replacing hardcoded carousels, and one shared component system
(sheets, dialogs, snackbars, save bars) behind a left-side drawer and a 5-tab staff bar.

### What Worked

- **Real-device UAT caught what every harness missed.** The 2026-09-27 phone walk found seven
  defects after `admin_shell.mjs` had reported ALL CHECKS PASSED three separate times against
  the same code. The probe measures the DOM; it cannot see how a band reads to an eye.
- **Decimal insertion absorbed scope discovery without renumbering.** 01.7 → 01.8.3 all inserted
  ahead of Phase 2; Phase 2/3/4 kept their numbers and scope throughout.
- **RED-before-GREEN evidence transcripts.** Plans 08-14 of 01.8.3 each carry a measured failing
  run before the fix. That is what made the round-2 gap closure auditable rather than asserted.
- **Verification re-runs found real gaps.** 01.8.2's re-verify surfaced D-37 as genuinely
  unimplemented — `failure_reason` exists nowhere in the code — after STATE.md had described it
  as "accepted" with no acceptance on record anywhere.

### What Was Inefficient

- **A plausible-but-wrong diagnosis cost a whole planning cycle.** PR #72's red CI showed
  `1878 tests, 0 failures` and exit 1. That was attributed to a compiler warning under
  `--warnings-as-errors`, and a quick task was planned and written against it. The real cause was
  three `mint` CVEs failing `mix hex.audit` — the alias's FIRST step, stopping the VM
  asynchronously so everything downstream still ran. Both the existence of the warning and the
  exit code were confirmed; that it was *fatal* never was. **Lesson: confirming a symptom is not
  confirming a cause.**
- **`origin/main` is branch-protected while `branching_strategy: "none"`.** Local `main`
  accumulated 36 then 7 commits that could never be pushed directly, needing a sync branch + PR
  each time. Known and documented in CLAUDE.md, still paid twice this milestone.
- **Worktree isolation degraded to sequential every time.** The harness forks worktrees from
  `origin/HEAD`, which goes stale the moment local `main` runs ahead — so every quick task and
  gap-closure run this milestone fell back to the main tree.
- **Stale verification fingerprints.** 01.7/01.8/01.8.1 all reported `verification=stale` at
  milestone close purely because later commits landed. Each was verified when closed; the
  fingerprint just cannot say so.

### Patterns Established

- **Superseded, not overwritten.** A UAT test that failed and was later fixed keeps
  `result: issue` plus a `superseded_by` annotation naming the test that closes it. Flipping it to
  `pass` would erase the evidence that the first walk failed — and that failure is why the fix
  phase exists.
- **Skipped-with-reason is a definitive result.** It closes a session exactly as a pass does,
  without the record claiming an observation nobody made. The honest way to accept an unwalked
  checkpoint.
- **Waivers carry a name and a date.** D-37 and open item 1 closed 01.8.2 as
  `accepted_by: developer, accepted_at: 2026-10-09` — not as satisfied criteria.
- **Verify the artefact, not the prose.** `DEVICE-PASS.md` was confirmed blank on disk rather
  than inferred from a UAT line claiming the checklist was run.

### Key Lessons

1. **A passing automated suite is not a verified UI.** This milestone's harness reported green
   over six-plus live defects, twice.
2. **Check whether a confirmed symptom is actually the cause.** See the `mint` CVE story above.
3. **An "accepted" gap with no attributed acceptance is an open gap.** D-37 sat as "accepted" in
   STATE.md for weeks with no name or date anywhere.
4. **Device-only checks never close themselves.** Android tap-highlight, edge-swipe vs back
   gesture, thumb reach and iOS Safari scroll lock all remain open — no harness in this repo can
   settle any of them, by design.

### Cost Observations

- Model mix: opus for planning/verification, sonnet for execution, haiku for plan checking
- Notable: the single largest avoidable cost was the misdiagnosed CI failure — a full
  planner+executor cycle produced a correct, useful latent fix that fixed nothing that was broken

### Debt Carried Into The Next Milestone

- **D-37** — enrichment failures persist the bare string `"failed"`; staff see `Reintentar` with
  no cause. The reason is already computed at the failure site and discarded.
- **Device pass** — `01.8.2-DEVICE-PASS.md` unfilled; sketches 069-080 never confirmed on a phone.
- **iOS Safari scroll lock** — `01.8.3-UAT.md` test 7, blocked: nobody on the team owns an iPhone.
- **12 acknowledged artifacts** — 3 diagnosed debug sessions, 2 quick tasks, 2 todos, 1 UAT gap,
  4 deferred items. See STATE.md `## Deferred Items`.
- **No milestone audit** — requirements coverage and E2E flows were never checked at the
  milestone level.

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
