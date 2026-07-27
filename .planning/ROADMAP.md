# Roadmap: PukllayClub

## Overview

PukllayClub goes from an empty repo to a fully-featured Spanish-language board-game catalog and
recommender in five fixed phases. Phase 0 proves the entire deploy pipeline (CI, native ARM
Docker build, Kamal zero-downtime deploy, migrations-on-deploy, nightly R2 backups) with no
product code, so every later phase ships against infrastructure that already works. Phase 1 builds
the public catalog — the complexity-teaching UX (plain-Spanish weight bands, mechanic/theme chips)
that is the product's foundational hook — with no auth and no AI. Phase 2 is the hero feature:
natural-language Spanish search over the catalog (local embeddings + pgvector hybrid ranking + LLM
query parsing), paired with magic-link auth and favorites, the minimum auth surface the search
feature needs. Phase 3 adds a per-game RAG rules oracle grounded in official rulebooks. Phase 4
closes the loop with club operations — admin catalog/copy management and in-person rental
tracking — built last, against a schema that has been stable since Phase 1. This order is fixed by
the user in PROJECT.md and independently validated by research/SUMMARY.md's dependency analysis:
each phase adds exactly one new Elixir context on top of a stable base, and no later capability can
be pulled forward without breaking that dependency chain.

## Phases

**Phase Numbering:**

- Phase 0 is the walking-skeleton deploy phase (fixed by the user, precedes Phase 1)
- Integer phases (0, 1, 2, 3, 4): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED), appear between surrounding
  integers in numeric order

- [ ] **Phase 0: Walking Skeleton to Production** - Deploy pipeline only (CI, Kamal, migrations, backups) — no product features
- [ ] **Phase 1: Catalog v1** - Public browse/filter/search catalog with complexity-teaching UX, no auth, no AI
- [ ] **Phase 2: Natural-Language Spanish Search + Auth** - Hero feature: NL search via hybrid ranking, plus magic-link auth and favorites
- [ ] **Phase 3: RAG Rules Oracle** - Per-game rules Q&A grounded in official rulebooks with citations
- [ ] **Phase 4: Club Operations** - Admin catalog/copy management and in-person rental tracking

## Phase Details

### Phase 0: Walking Skeleton to Production

**Goal**: A trivial but real Phoenix app is deployed to production with a proven, repeatable deploy pipeline — no product features, no gold-plating.
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: DEPLOY-01, DEPLOY-02, DEPLOY-03, DEPLOY-04, DEPLOY-05
**Success Criteria** (what must be TRUE):

  1. The production domain (pukllay.club) responds over HTTPS with a placeholder response and a working `/up` health endpoint
  2. Every PR runs CI (`mix quality`: format --check-formatted, credo --strict, sobelow, test --warnings-as-errors) against a Postgres service, and must pass before merge
  3. `kamal deploy` ships a change to the Hetzner CAX31 with zero downtime and runs Ecto migrations as part of the deploy
  4. A nightly `pg_dump` backup job runs automatically and lands a dump in Cloudflare R2
  5. AGENTS.md documents the TDD loop, the `mix quality` alias, the manual-merge-gate rule, and the project's non-goals

**Plans**: 6/6 plans executed
**Wave 1**

- [x] 00-01-PLAN.md — Phoenix scaffold, `/up` health route, mise toolchain pins, `mix quality` alias, Sentry (DEPLOY-01)
- [x] 00-02-PLAN.md — AGENTS.md: TDD loop, quality alias, merge-gate rule, non-goals (DEPLOY-05)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 00-03-PLAN.md — CI quality-gate workflow + private repo + branch protection (DEPLOY-02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 00-04-PLAN.md — Entrypoint-gated migrations, Kamal deploy.yml/secrets, arm64 deploy workflow (DEPLOY-03, DEPLOY-01)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 00-05-PLAN.md — Host provisioning, first production deploy, D-06 live migration proof (DEPLOY-03, DEPLOY-01)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 00-06-PLAN.md — Nightly pg_dump → Cloudflare R2 backup workflow (DEPLOY-04)

### Phase 1: Catalog v1

**Goal**: Members can browse, filter, sort, and search a public catalog of ~400 games, with UX that teaches complexity instead of assuming hobbyist vocabulary.
**Mode:** mvp
**Depends on**: Phase 0
**Requirements**: CATALOG-01, CATALOG-02, CATALOG-03, CATALOG-04, CATALOG-05, CATALOG-06, CATALOG-07, CATALOG-08, CATALOG-09
**Success Criteria** (what must be TRUE):

  1. Member can browse the full ~400-game catalog as image-forward carousels/cards, with no account required
  2. Member can filter by player count, playtime, category/mechanic/theme, and minimum age, and sort by playtime or complexity
  3. Member can search the catalog by keyword (title, designer, publisher)
  4. Each game displays a plain-Spanish weight-band descriptor and plain-Spanish mechanic/theme chips instead of a bare 1-5 number or raw hobbyist jargon
  5. Each game shows the club's own resized cover image and any editorial "club favorite"/"beginner-friendly" tag carried over from the existing Excel catalog

**Plans**: TBD
**UI hint**: yes

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
Phases execute in numeric order: 0 → 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Walking Skeleton to Production | 6/6 | In Progress|  |
| 1. Catalog v1 | 0/TBD | Not started | - |
| 2. Natural-Language Spanish Search + Auth | 0/TBD | Not started | - |
| 3. RAG Rules Oracle | 0/TBD | Not started | - |
| 4. Club Operations | 0/TBD | Not started | - |
