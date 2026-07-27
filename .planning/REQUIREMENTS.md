# Requirements: PukllayClub

**Defined:** 2026-07-24
**Core Value:** A member can describe what they want in plain Spanish and find a game that fits — even without already knowing board-game vocabulary.

## v1 Requirements

Requirements for this milestone (Phases 0-4, per PROJECT.md's fixed roadmap). Each maps to a roadmap phase.

### Deploy

- [x] **DEPLOY-01**: App is deployed to production at pukllay.club over HTTPS with a placeholder page and `/up` health endpoint
- [x] **DEPLOY-02**: CI runs `mix quality` (format --check-formatted, credo --strict, sobelow, test --warnings-as-errors) on every PR via GitHub Actions, with a Postgres service and dependency/build caching
- [x] **DEPLOY-03**: `kamal deploy` ships a change to the CAX31 with zero downtime and runs Ecto migrations as part of the deploy
- [x] **DEPLOY-04**: A nightly `pg_dump` backup runs automatically and lands in Cloudflare R2
- [x] **DEPLOY-05**: AGENTS.md documents the TDD loop (test from acceptance criteria -> red -> green -> refactor), the `mix quality` alias, the manual-merge-gate rule, and the project's non-goals

### Catalog

- [ ] **CATALOG-01**: Member can browse the full catalog (~400 games) with cover images, presented as carousels/cards in LiveView streams
- [ ] **CATALOG-02**: Member can filter by player count, playtime, category/mechanic/theme (text[] + GIN), and minimum age
- [ ] **CATALOG-03**: Member can search the catalog by keyword (title, designer, publisher) via tsvector
- [ ] **CATALOG-04**: Member can sort results by playtime, complexity, or other scalar fields
- [ ] **CATALOG-05**: Each game shows a plain-Spanish weight-band + one-line complexity descriptor instead of a bare 1-5 number
- [ ] **CATALOG-06**: Each game shows plain-Spanish mechanic/theme chips translated from a curated vocabulary, not raw hobbyist jargon
- [ ] **CATALOG-07**: Each game carries the club's existing editorial curation/custom tags (from the Excel catalog) as a lightweight "club favorite"/"beginner-friendly" signal
- [ ] **CATALOG-08**: Catalog is fully public — no account required to browse
- [ ] **CATALOG-09**: Catalog images are the club's own resized copies, not hotlinked/BGG-sourced

### Search

- [ ] **SEARCH-01**: Member can enter a natural-language Spanish query (e.g. "algo de negociación estilo Catan") and get matched games via hybrid vector+keyword ranking
- [ ] **SEARCH-02**: Natural-language query parsing maps free text onto the same plain-Spanish tag vocabulary established in Phase 1 (CATALOG-06)
- [ ] **SEARCH-03**: Search runs local CPU embeddings + async LLM query parsing via Oban — never synchronously on the request path
- [ ] **SEARCH-04**: If the LLM/embedding pipeline is unavailable or rate-limited, search degrades gracefully to keyword-only results

### Auth

- [ ] **AUTH-01**: Member can sign in via magic-link (phx.gen.auth), no password
- [ ] **AUTH-02**: Member can mark/unmark games as favorites
- [ ] **AUTH-03**: Member's favorites persist across sessions

### Rules Q&A

- [ ] **RULES-01**: Member can select a specific game and ask a rules question in Spanish
- [ ] **RULES-02**: Answers are grounded in that game's official rulebook and cite the specific passage/section
- [ ] **RULES-03**: Rules Q&A is scoped per-game (no open-ended cross-game questions)

### Club Ops

- [ ] **CLUBOPS-01**: Admin (a role distinct from member magic-link auth) can mark a physical copy as checked-out or returned
- [ ] **CLUBOPS-02**: Admin can view which copies are currently checked out and to whom
- [ ] **CLUBOPS-03**: Admin can manage the catalog and physical copies (add/edit/remove)
- [ ] **CLUBOPS-04**: Admin can manage promotions

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Recommendations

- **REC-01**: Collaborative "users who liked X also liked Y" recommendations — needs interaction-volume data Phase 2 won't yet have produced

### Rules Q&A

- **RULES-04**: Voice interface for rules Q&A — text chat already covers the "hands full during a game" use case adequately

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| BGG-style public ratings/rank | Needs rater volume a small club won't reach; reintroduces the numeric-rating-without-context problem this project exists to avoid — use the CATALOG-07 editorial tag instead |
| Full BGG-depth taxonomy (100+ mechanics/categories) | Directly contradicts the "teach, don't assume" core value; 400 games don't need faceting built for 100K+ |
| Table/session reservation & scheduling | Different problem domain (calendars, capacity, payments); PukllayClub is a catalog + rental tracker, not a venue-booking business |
| General-purpose cross-game rules chatbot | Un-scoped Q&A increases hallucination risk and dilutes the citation-based trust pattern; Rules Q&A stays per-game (RULES-03) |
| Membership/loyalty/payment features | No online payments or multi-tenancy; internal club tool, not a commercial cafe product |
| Icon-only complexity/mechanic indicators | Increases cognitive load for non-hobbyists unless paired with plain-language text |
| Online payments / MercadoPago | Not needed for any current phase |
| Multi-tenancy | Single club, single tenant |
| Microservices / Kubernetes | Solo dev, single Hetzner node |
| Message broker | Oban (Postgres-backed) covers async work at this scale |
| Separate vector DB, search service, or auth provider | pgvector + Postgres text search + phx.gen.auth keep everything in one database |
| GPU inference | Local CPU embeddings + remote free-tier LLM only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEPLOY-01 | Phase 0 | Complete |
| DEPLOY-02 | Phase 0 | Complete |
| DEPLOY-03 | Phase 0 | Complete |
| DEPLOY-04 | Phase 0 | Complete |
| DEPLOY-05 | Phase 0 | Complete |
| CATALOG-01 | Phase 1 | Pending |
| CATALOG-02 | Phase 1 | Pending |
| CATALOG-03 | Phase 1 | Pending |
| CATALOG-04 | Phase 1 | Pending |
| CATALOG-05 | Phase 1 | Pending |
| CATALOG-06 | Phase 1 | Pending |
| CATALOG-07 | Phase 1 | Pending |
| CATALOG-08 | Phase 1 | Pending |
| CATALOG-09 | Phase 1 | Pending |
| SEARCH-01 | Phase 2 | Pending |
| SEARCH-02 | Phase 2 | Pending |
| SEARCH-03 | Phase 2 | Pending |
| SEARCH-04 | Phase 2 | Pending |
| AUTH-01 | Phase 2 | Pending |
| AUTH-02 | Phase 2 | Pending |
| AUTH-03 | Phase 2 | Pending |
| RULES-01 | Phase 3 | Pending |
| RULES-02 | Phase 3 | Pending |
| RULES-03 | Phase 3 | Pending |
| CLUBOPS-01 | Phase 4 | Pending |
| CLUBOPS-02 | Phase 4 | Pending |
| CLUBOPS-03 | Phase 4 | Pending |
| CLUBOPS-04 | Phase 4 | Pending |

**Coverage:**

- v1 requirements: 28 total
- Mapped to phases: 28
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-24*
*Last updated: 2026-07-24 after initial definition*
