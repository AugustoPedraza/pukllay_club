# Roadmap: PukllayClub

## Milestones

- ✅ **v1.0 MVP Catalog** — Phase 0, Phase 1 (+ insertions 01.1–01.6) (shipped 2026-09-11)
- ✅ **v1.1 Sharable Version** — Phase 01.7, 01.8, 01.8.1, 01.8.2, 01.8.3 (shipped 2026-10-09)
- ⏳ **Next (unnamed)** — Phase 2, Phase 3, Phase 4 (not yet started, numbers and scope unchanged)

## Phases

<details>
<summary>✅ v1.0 MVP Catalog (Phase 0, Phase 1 + insertions 01.1–01.6) — SHIPPED 2026-09-11</summary>

Full phase-by-phase detail archived at `.planning/milestones/v1.0-ROADMAP.md`. Summary:

- [x] Phase 0: Walking Skeleton to Production — deploy pipeline only, no product features (completed 2026-07-27)
- [x] Phase 1: Catalog v1 — public browse/filter/search catalog, no auth, no AI (completed 2026-08-18)
- [x] Phase 01.1: Site Shell & Content Pages
- [x] Phase 01.2: Catalog & Detail Navigation Polish (completed 2026-08-29)
- [x] Phase 01.3: Game Detail Layout & Content Accuracy (completed 2026-09-01)
- [x] Phase 01.3.1: Game Image Quality & Multi-Image Gallery
- [x] Phase 01.4: UI Polish Pass for About Page Sketches
- [x] Phase 01.5: About Page CTA Rhythm & Header Morph Refinement (+ quick task 260910-av6)
- [x] Phase 01.6: Light/Dark Theme Color-Family Consistency (6/6 quick tasks)

</details>

<details>
<summary>✅ v1.1 Sharable Version (Phases 01.7–01.8.3) — SHIPPED 2026-10-09 (override closeout)</summary>

Full phase-by-phase detail archived at `.planning/milestones/v1.1-ROADMAP.md`; the phase
directories themselves are at `.planning/milestones/v1.1-phases/`. 5 phases, 63 plans, 166 tasks.

- [x] Phase 01.7: Production Catalog Data & Security Hardening (5/5 plans) — completed 2026-09-11
- [x] Phase 01.8: SEO, Structured Data & Social Sharing (7/7 plans) — completed 2026-09-12
- [x] Phase 01.8.1: Staff Admin — Ludoteca, Shelves & Curated Destacados (15/15 plans) — completed 2026-09-16
- [x] Phase 01.8.2: Admin UI/UX Redesign (22/22 plans) — completed 2026-10-09
- [x] Phase 01.8.3: Admin Screen-by-Screen Refinement (14/14 plans) — completed 2026-09-28

**Closed as `override_closeout`, not a verified closeout.** 12 open artifacts acknowledged
(1 carried forward from v1.0), no milestone audit was run, and phases 01.7/01.8/01.8.1 reported
`verification=stale` at close — a fingerprint mismatch against later commits, not a finding.
Two developer-attributed waivers live inside 01.8.2 (D-37's unpersisted enrichment failure
reason; open item 1's unfilled device pass). Full disclosure in `.planning/MILESTONES.md` and
STATE.md `## Deferred Items`.

</details>

**⏳ Next milestone (unnamed)** — Phases 2, 3 and 4 below keep their original numbers and scope.
Phase 2 is the project's stated core value and the natural next milestone; run
`/gsd-new-milestone` to scope and name it.

### Phase 2: Natural-Language Spanish Search + Auth

**Goal**: Members can describe what they want in plain Spanish and get matched games — the core value of the product — then save favorites behind lightweight auth.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: SEARCH-01, SEARCH-02, SEARCH-03, SEARCH-04, AUTH-01, AUTH-02, AUTH-03
**Success Criteria** (what must be TRUE):

  1. Member can type a natural-language Spanish query (e.g. "algo de negociación estilo Catan") and get relevant matched games back, ranked by hybrid vector+keyword scoring
  2. The NL query parser maps free text onto the same plain-Spanish tag vocabulary established in Phase 1, and every embedding/LLM call runs asynchronously (local CPU embeddings + Oban-queued LLM parsing) — never on the request hot path
  3. If the LLM/embedding pipeline is unavailable or rate-limited, the member still gets usable keyword-only results instead of an error
  4. Member can sign in via a passwordless magic-link (`phx.gen.auth`) and mark/unmark games as favorites
  5. A member's favorites persist across sessions

**Plans**: TBD
**UI hint**: yes

### Phase 3: RAG Rules Oracle

**Goal**: Members can ask a specific game's rules question in Spanish and get a trustworthy answer grounded in that game's official rulebook.
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: RULES-01, RULES-02, RULES-03
**Success Criteria** (what must be TRUE):

  1. Member can select a specific game and ask a rules question in Spanish
  2. The answer is grounded in that game's official rulebook and cites the specific passage/section it draws from
  3. Rules Q&A stays scoped to the selected game — there is no open-ended cross-game question path

**Plans**: TBD
**UI hint**: yes

### Phase 4: Club Operations

**Goal**: Club admins can manage the catalog and physical copies and track in-person rentals, using an admin role distinct from member magic-link auth.

> **Scope note (2026-09-13):** staff auth, catalog add/edit/remove, and the curated first carousel
> moved forward into Phase 01.8.1 (Staff Admin). Phase 4 keeps physical copies, rental tracking,
> and promotions — revisit these criteria (and seed `saturday-sessions-and-managed-carousels`)
> when Phase 4 is planned.
>
> **Scope note (2026-09-16):** copies as rows, the copy count, and per-copy shelf position moved
> forward into Phase 01.8.2 (see `01.8.2-CONTEXT.md` D-01..D-04, D-20). Phase 4 keeps checkout/return
> state, who has a copy, the rentals dashboard, and promotions, building on 01.8.2's copies table.
> Criterion 3 ("add, edit, and remove … physical copies") is partially satisfied by 01.8.2.
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: CLUBOPS-01, CLUBOPS-02, CLUBOPS-03, CLUBOPS-04
**Success Criteria** (what must be TRUE):

  1. Admin can mark a physical copy as checked-out or returned
  2. Admin can view which copies are currently checked out and to whom, from a dashboard distinct from the member catalog view
  3. Admin can add, edit, and remove catalog entries and physical copies
  4. Admin can manage promotions

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 0 → 1 → 01.7 → 01.8 → 01.8.1 → 01.8.2 → 01.8.3 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Walking Skeleton to Production | 6/6 | Complete — shipped v1.0 | 2026-07-27 |
| 1. Catalog v1 (+ 01.1–01.6) | 87/87 | Complete — shipped v1.0 | 2026-09-11 |
| 01.7. Production Catalog Data & Security Hardening | 5/5 | Complete — shipped v1.1 | 2026-09-11 |
| 01.8. SEO, Structured Data & Social Sharing | 7/7 | Complete — shipped v1.1 | 2026-09-12 |
| 01.8.1. Staff Admin — Ludoteca, Shelves & Curated Destacados | 15/15 | Complete — shipped v1.1 | 2026-09-16 |
| 01.8.2. Admin UI/UX Redesign | 22/22 | Complete — shipped v1.1 | 2026-10-09 |
| 01.8.3. Admin Screen-by-Screen Refinement | 14/14 | Complete — shipped v1.1 | 2026-09-28 |
| 2. Natural-Language Spanish Search + Auth | 0/TBD | Not started | - |
| 3. RAG Rules Oracle | 0/TBD | Not started | - |
| 4. Club Operations | 0/TBD | Not started | - |
