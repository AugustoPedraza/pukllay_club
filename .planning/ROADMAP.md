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

- [x] **Phase 0: Walking Skeleton to Production** - Deploy pipeline only (CI, Kamal, migrations, backups) — no product features (completed 2026-07-27)
- [x] **Phase 1: Catalog v1** - Public browse/filter/search catalog with complexity-teaching UX, no auth, no AI (completed 2026-08-18)
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
  3. `kamal deploy` ships a change to the production host with zero downtime and runs Ecto migrations as part of the deploy (see 00-CONTEXT.md D-20: host is GCP e2-micro, not the originally-planned Hetzner CAX31)
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

**Plans**: 12/12 plans executed (6 original + 3 gap-closure executed; 3 sketch-implementation plans pending)
**UI hint**: yes

**Wave 1**

- [x] 01-01-PLAN.md — BGG application token + R2 catalog bucket + seed dependencies (blocking human checkpoint) (CATALOG-09)
- [x] 01-02-PLAN.md — Brand identity: daisyUI theme tokens, self-hosted Bebas Neue/Inter, header lockup (CATALOG-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-03-PLAN.md — TRACER: one real game from CSV row through BGG, resize, R2, DB, to a public browse LiveView (CATALOG-01, CATALOG-08, CATALOG-09)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-04-PLAN.md — Full 434-game seed: D-20 data-quality rules, Spanish cover + gallery, search vector and GIN indexes (CATALOG-01, CATALOG-03, CATALOG-05, CATALOG-07, CATALOG-09)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 01-05-PLAN.md — Browse: vocabulary, composed filter/search/sort query, filter drawer, carousels, load-more (CATALOG-01, CATALOG-02, CATALOG-03, CATALOG-04, CATALOG-06, CATALOG-08)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 01-06-PLAN.md — Complexity-teaching UX: weight bands, plain-Spanish chips, game detail page, CSP (CATALOG-05, CATALOG-06, CATALOG-07)

**Gap closure — Wave 1** *(from 01-UAT.md, run via `/gsd-execute-phase 1 --gaps-only`)*

- [x] 01-07-PLAN.md — Card chip hierarchy, weight-band badge overflow, app-wide focus ring (G-01-2, G-01-6, G-01-7)
- [x] 01-09-PLAN.md — `is_expansion` column, seed classifier + migration backfill, expansion-free recency row (G-01-5)

**Gap closure — Wave 2** *(blocked on 01-07: shared `catalog_live/index.ex`)*

- [x] 01-08-PLAN.md — Section heading differentiation and persistent carousel scroll controls (G-01-3, G-01-4)

**Sketch implementation — Wave 1** *(from `/gsd-sketch` 001/002, run via `/gsd-execute-phase 1`)*

- [x] 01-10-PLAN.md — Minimal resting card, shared hover-portal + mobile-sheet preview surfaces, difficulty dots (CATALOG-01, CATALOG-05, CATALOG-06, CATALOG-07)

**Sketch implementation — Wave 2** *(blocked on 01-10: shared `app.css` block and `game_card.ex`)*

- [x] 01-11-PLAN.md — Full-bleed edge-fade shelves, shared gutter token, `Ver todo` tile, narrow-viewport rail density (CATALOG-01, CATALOG-05, CATALOG-06, CATALOG-07)

**Sketch implementation — Wave 3** *(blocked on 01-11: shared `app.css` block, `layouts.ex` and `catalog_live/index.ex`)*

- [x] 01-12-PLAN.md — Sticky gutter-aligned nav with shelf anchors and search, mobile category chips, design-system record (CATALOG-01, CATALOG-05, CATALOG-06, CATALOG-07)

### Phase 01.1: Site Shell & Content Pages (INSERTED)

**Goal**: The sketch-validated designs that are not yet built in real code — a shared page shell, the about page, an upgraded detail page, the filter/search modal, and empty/loading/error states — are live in the app, composed together without reintroducing the drift the sketch composition rounds (007/011/012) already found and fixed once.
**Depends on**: Phase 1 (reuses the card/shelf components sketches 001/002 already shipped in 01-10/11/12)
**Requirements**: SHELL-01, SHELL-02, SHELL-03, SHELL-04, SHELL-05
**Success Criteria** (what must be TRUE):

  1. Catalog, detail, and about pages share one adaptive header and one footer (mission/links/BGG attribution), not per-page forks
  2. An about page exists and communicates the club's mission, how borrowing works, and a FAQ/vocabulary section
  3. The game detail page (`/juegos/:id`) shows a buy-box (cover + reservation CTA) beside a reading column and a "Juegos similares" shelf, on both desktop and mobile
  4. The catalog's filter/search UI is a centered modal with checklist-style facets, reachable from a live-narrowing nav search box
  5. The catalog and detail pages show a minimal, on-brand empty/loading/error state for no-results, in-flight, and failure conditions

All findings for this phase are already captured in `.claude/skills/sketch-findings-pukllay_club/` — this phase implements them, it does not design them.

**Plans:** 9/9 plans complete
**UI hint**: yes

> **Header rework inserted 2026-08-22.** Sketches 013–017 reworked the header plan 01.1-01 shipped;
> the developer approved 017-E and asked for it before the remaining waves continue. Plans 01.1-08
> and 01.1-09 are **numbered last but execute second and third** — plan numbers are stable identities,
> waves are execution order, and renumbering six pending plans would have broken every
> cross-reference between them. Plans 01.1-02 through 01.1-07 each moved down two waves; their
> `depends_on` chain is unchanged except 01.1-02, which now waits on 01.1-09.

Plans:

**Wave 1**

- [x] 01.1-01-PLAN.md — TRACER: `/club` + `/quienes-somos` routes, 3-state header, shared footer (SHELL-01)

**Wave 2** *(blocked on Wave 1: shared `layouts.ex` and `app.css`)*

- [x] 01.1-08-PLAN.md — Header rework (sketch 017-E): expandable search-morph on Catálogo + Detalle, Sumate CTA relocated to the About hero (D-05 superseded), theme toggle relocated to the footer as bare icons, `--pk-header-h` published (SHELL-01, SHELL-04)

**Wave 3** *(blocked on Wave 2: shared `layouts.ex` and `app.css`)*

- [x] 01.1-09-PLAN.md — Mobile nav drawer (list rows, left-accent active state, bottom-pinned theme toggle + socials) and the About-scoped mobile sticky join-CTA bar (SHELL-01)

**Wave 4** *(blocked on Wave 3: shared `about_live.ex` and `app.css`)*

- [x] 01.1-02-PLAN.md — About page content: photo rail, two-column band, dark FAQ band, Juntadas/Contacto, closing CTA (SHELL-02)

**Wave 5** *(blocked on Wave 4: shared `app.css`)*

- [x] 01.1-03-PLAN.md — Detail desktop: `Catalog.similar_games/1`, buy-box masthead, reading column, ficha técnica, "Juegos similares" shelf (SHELL-03)

**Wave 6** *(blocked on Wave 5: shared `catalog_live/show.ex` and `app.css`)*

- [x] 01.1-04-PLAN.md — Detail mobile chrome: fixed CTA bar, sticky title-echo bar, lightbox, share (SHELL-03)

**Wave 7** *(blocked on Wave 6: shared `catalog_live/show.ex`)*

- [x] 01.1-05-PLAN.md — Reservation flow: runtime-configured number, name-capture modal, `wa.me` deep link (SHELL-03)

**Wave 8** *(blocked on Wave 7: shared `catalog_live/show.ex` and `app.css`)*

- [x] 01.1-06-PLAN.md — Filter/search surface, entry point inside the search-morph, URL filter params, filter-linked chips (SHELL-04)

**Wave 9** *(blocked on Wave 8: shared `catalog_live/index.ex` and `catalog_live_test.exs`)*

- [x] 01.1-07-PLAN.md — Empty/loading/error states and the branded 404 page (SHELL-05)

### Phase 01.2: Catalog & Detail Navigation Polish (INSERTED)

**Goal:** The curated carousels are the catalog's browse surface and the grid is exclusively the search/filter results view with auto-loading scroll; the game detail page presents a self-contained buy-box beside an honest spec list, a "Juegos similares" shelf ranked by shared mechanics/themes, and a breadcrumb that returns a member to the filtered view they arrived from.
**Requirements**: CATALOG-01, SHELL-03, SHELL-04 (refined — this inserted phase adds no new requirement IDs and does not change their acceptance criteria)
**Depends on:** Phase 1 (and Phase 1.1's shared shell/detail-page components)
**Plans:** 5/5 plans executed

Plans:
**Wave 1**

- [x] 01.2-01-PLAN.md — D-08 tracer: breadcrumb carries catalog filters forward (new shared `CatalogFilters` parse/encode/sanitise module)
- [x] 01.2-02-PLAN.md — D-06: rank "Juegos similares" by shared mechanics/themes within the weight band

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01.2-03-PLAN.md — D-01/D-02: grid becomes exclusively the search/filter results view; modal CTA is the explicit-submission signal
- [x] 01.2-04-PLAN.md — D-04/D-05/D-07: Ficha técnica cleanup, players/duration de-duplication, buy-box redesign

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01.2-05-PLAN.md — D-03: auto-loading infinite scroll replaces the manual results-grid pagination control

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
| 0. Walking Skeleton to Production | 6/6 | Complete    | 2026-07-27 |
| 1. Catalog v1 | 12/12 | In Progress|  |
| 2. Natural-Language Spanish Search + Auth | 0/TBD | Not started | - |
| 3. RAG Rules Oracle | 0/TBD | Not started | - |
| 4. Club Operations | 0/TBD | Not started | - |
