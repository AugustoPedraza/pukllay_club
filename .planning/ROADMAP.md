# Roadmap: PukllayClub

## Milestones

- ✅ **v1.0 MVP Catalog** — Phase 0, Phase 1 (+ insertions 01.1–01.6) (shipped 2026-09-11)
- 🚧 **v1.1 Sharable Version** — Phase 01.7, Phase 01.8 (in progress, started 2026-09-11)
- ⏳ **Later (unnamed)** — Phase 2, Phase 3, Phase 4 (not yet started, numbers and scope unchanged)

## Phases

<details>
<summary>✅ v1.0 MVP Catalog (Phase 0, Phase 1 + insertions 01.1–01.6) — SHIPPED 2026-09-11</summary>

Full phase-by-phase detail (goals, success criteria, plans) archived at
`.planning/milestones/v1.0-ROADMAP.md`. Summary:

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

**🚧 v1.1 Sharable Version (current milestone)** — inserted ahead of Phase 2 per the project's
established decimal-insertion convention (01.1 … 01.6 all ran this way). Phase 2/3/4 keep their
numbers and their scope; nothing from them is pulled forward.

- [x] **Phase 01.7: Production Catalog Data & Security Hardening** - Load the real ~400+ game catalog into production via a safe repeatable path, then close the cookie/HSTS/CSP/CSRF gaps and sweep git history for secrets (completed 2026-09-11)
- [x] **Phase 01.8: SEO, Structured Data & Social Sharing** - Per-game meta/OG/Twitter tags, `Game` + `LocalBusiness` JSON-LD under a nonced CSP, live `sitemap.xml`, real `robots.txt`, and real image `alt` text (completed 2026-09-12)
- [ ] **Phase 01.8.1: Staff Admin — Ludoteca, Shelves & Curated Destacados** - Invite-only staff magic-link auth, ludoteca CRUD, per-game shelf locations with walk-the-shelf assignment, curated first carousel, CSV-band vs BGG-weight audit (inserted 2026-09-13, prioritized ahead of Phase 2/3)

### Phase 01.7: Production Catalog Data & Security Hardening (INSERTED)

**Goal**: The live site at pukllay.club serves the real ~400+ game catalog instead of an empty
state, and the production app meets baseline web-security practice appropriate for a now-public
repo and a link that gets passed around.
**Depends on**: Phase 1 (the shipped v1.0 catalog this loads data into and hardens)
**Requirements**: SEED-01, SEED-02, SEC-01, SEC-02, SEC-03, SEC-04, AUDIT-01, AUDIT-02
**Success Criteria** (what must be TRUE):

  1. https://pukllay.club shows the real catalog — carousels, filters, search, and game detail pages populated with the same ~400+ games dev has, not the empty state
  2. Re-running the seed against production is a documented, repeatable operation: a second run is idempotent (changes nothing), and BGG/R2 credentials are never committed and never hand-edited onto the production host
  3. `curl -I https://pukllay.club/` shows a `Strict-Transport-Security` header with a sane `max-age` and a session `Set-Cookie` carrying `Secure`, while local HTTP dev still serves and holds a session normally
  4. After the CSP review, the About page's live Google Maps embed still renders, and a LiveView page still reconnects cleanly after a simulated network drop (websocket connect-time CSRF, not just plain form posts)
  5. A full-git-history secrets sweep (not just currently-tracked files) is recorded with every hit explicitly triaged: real-and-rotated, false-positive-and-dismissed (e.g. `signing_salt`), or inert-historical-and-accepted

**Plans**: 5/5 plans executed

Plans:
**Wave 1**

- [x] 01.7-01-PLAN.md — SEED-01: restore the real catalog from dev into production over the SSH tunnel (phase tracer), proven by a live game detail page
- [x] 01.7-02-PLAN.md — SEC-01/SEC-02: env-gated `Secure` session cookie with an assertable accessor, plus live HSTS and `/up` health-probe verification
- [x] 01.7-03-PLAN.md — SEC-03/SEC-04: directive-by-directive CSP audit pinned as regression assertions, plus LiveView websocket CSRF confirmation
- [x] 01.7-04-PLAN.md — AUDIT-01/AUDIT-02: full-git-history Gitleaks sweep, per-hit adjudication, and a blocking-human rotation gate

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01.7-05-PLAN.md — SEED-02: opt-in `DATABASE_URL` dev Repo target, upsert idempotency proof, and the AGENTS.md re-seed runbook

> **Build order inside this phase (from `research/SUMMARY.md`):** the seed-to-production work
> (SEED-01/02) and the secrets sweep (AUDIT-01/02) have no dependency on the security work or on
> each other and can run in parallel; the security items (SEC-01…04) are four independently-verified
> checkpoints, not one "add security headers" checkbox (PITFALLS.md Pitfall 5). Two standing
> hazards to respect: `force_ssl`'s `exclude` list must stay in sync with kamal-proxy's `/up`
> health check, and `csp.ex`'s single third-party `frame-src` (`ClubLinks.maps_embed_origin/0`) is
> deliberate — do not "tighten" it away (Pitfall 6).

### Phase 01.8: SEO, Structured Data & Social Sharing (INSERTED)

**Goal**: A game link dropped into WhatsApp/Facebook/Twitter renders an appealing, on-brand preview
card, and Google can discover, crawl, and understand every game page in the catalog.
**Depends on**: Phase 01.7 (needs real production data to demonstrate a share card against, and
builds its JSON-LD on the CSP baseline that phase establishes)
**Requirements**: SEO-01, SEO-02, SEO-03, SEO-04, SEO-05, SEO-06, SHARE-01, SHARE-02, SHARE-03, SHARE-04, SHARE-05, SEC-05
**Success Criteria** (what must be TRUE):

  1. `curl` against a live game detail URL — no JS, no websocket, exactly what a crawler sees — returns that specific game's meta description, Open Graph tags, and Twitter Card tags, never the site-wide fallback
  2. Sharing a game link via the existing native-share control produces a preview card on WhatsApp/Facebook/Twitter showing that game's own cover art at 1200×630 plus its title and description; pages with no natural hero image (catalog index, About) fall back to the branded isologo/wordmark card
  3. Google's Rich Results Test validates `Game` structured data on a live game detail page and `LocalBusiness` (Jujuy) site-wide, with no CSP violation in the browser console and `script-src` still carrying no `unsafe-inline`
  4. `https://pukllay.club/sitemap.xml` lists the catalog index plus every publicly-reachable game — count matches the live catalog, `lastmod` tracks each game's own `updated_at` — and `robots.txt` allows crawling and points at it
  5. Catalog card and hover-preview images announce the actual game (to a screen reader, and when an image fails to load) instead of being skipped as decorative

**Plans**: 7/7 plans executed (2 gap-closure plans added after UAT)

Plans:
**Wave 1**

- [x] 01.8-01-PLAN.md — Wave 1 · CSP nonce refactor plus the crawler-visible per-game SEO chain: `GameSEO`/`SiteSEO` plugs, the `SEO` payload builder, `SEOTags`, meta description, Open Graph/Twitter tags and `Game` JSON-LD (SEC-05, SEO-01, SEO-05, SHARE-01, SHARE-02)
- [x] 01.8-02-PLAN.md — Wave 1 · Real `alt` text across all six cover render branches on `GameCard` and `GamePreview`, via one shared generator that handles the sparse-publishers case (SEO-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01.8-03-PLAN.md — Wave 2 · Request-time `sitemap.xml` from the live catalog, plus real `robots.txt` content pointing at it (SEO-03, SEO-04)
- [x] 01.8-04-PLAN.md — Wave 2 · The 1200x630 og-card letterbox transform, its one-time `catalog.backfill_og_cards` batch, and the real run against the live catalog (SHARE-03, SHARE-05)
- [x] 01.8-05-PLAN.md — Wave 2 · `LocalBusiness` JSON-LD from the locked club facts, `ClubLinks.public_phone/0`, and the sketch-approved branded OG fallback card (SEO-06, SHARE-04)

**Gap closure — G-01.8-3** *(UAT: WhatsApp link preview shows no cover art)*

- [x] 01.8-06-PLAN.md — Wave 1 · Rebuild `SEOTags.seo_tags/1` as an escaping-safe markup builder so LiveView's `root_tag_attribute` stamp no longer sits between `<meta` and `property=`, re-anchor every served-response Open Graph assertion on the strict tag form, and ship a self-testing strict-crawler smoke oracle (SHARE-01, SHARE-02)
- [x] 01.8-07-PLAN.md — Wave 2 · Prove the fix on the live deployed host with a WhatsApp user agent across a game page and both branded-fallback routes, then close the debug session and register the pattern in the debug knowledge base (SHARE-01, SHARE-02, SHARE-03, SHARE-04)

> **Build order inside this phase (from `research/SUMMARY.md`):** the CSP nonce refactor
> (`CSP.policy/0` → `policy/1`, per-request nonce in `put_csp/2` — SEC-05) comes first because the
> JSON-LD blocks cannot render at all under this app's existing strict `script-src 'self'` without
> it; then the `GameSEO` plug + `SEOTags` component + OG/JSON-LD chain. Alt text, `sitemap.xml`, and
> `robots.txt` are independent of that chain and can run in parallel.
>
> **Accepted scope constraint (PITFALLS.md Pitfall 1 + 2).** SEO metadata must be computed in a Plug
> that writes to `conn.assigns` before the LiveView mounts — anything gated on `connected?(socket)`
> is invisible to every crawler. Correspondingly, `<head>` tags going stale during LiveView
> client-side navigation is an accepted, documented limitation (José Valim's own guidance), not a
> bug to engineer around with a JS head-patching hook.

### Phase 01.8.1: Staff Admin — Ludoteca, Shelves & Curated Destacados (INSERTED)

**Goal:** Club staff (owner + up to 3 invited accounts) can sign in, manage the ludoteca, record
where each physical game lives, curate the first home carousel, and fix mis-banded games —
prioritized ahead of Phase 2/3 for Saturday operations and a living home page.
**Mode:** mvp
**Requirements**: TBD
**Depends on:** Phase 01.8; production outbound email (todo `email-provider-and-dns`)
**Context:** `.planning/notes/staff-admin-decisions.md`
**Success Criteria** (what must be TRUE):

  1. Staff sign in via passwordless magic link (`phx.gen.auth`, staff role); registration is invite-only — no public sign-up path exists, and `/admin` routes reject non-staff
  2. Staff can add, edit, and remove games in the ludoteca
  3. Each game carries a shelf-level storage location; staff can bulk-assign locations on a phone by picking a shelf and tapping the games on it, and can view games listed in shelf order (pick/restore list)
  4. Staff manage the home page's sections: create, rename, reorder and hide them; each is hand-picked (type-ahead add, ↑/↓, remove) or automatic by rule (difficulty band, recently added), the first is a hand-picked featured hero capped at ~20 games, empty sections are hidden, and the catalog filter offers a sections facet *(rewritten 2026-09-13 per 01.8.1-CONTEXT.md D-17..D-28 — supersedes "rename the first carousel; all other rows remain automatic")*
  5. Staff can see games whose CSV `weight_band` disagrees with their `bgg_weight`, and either correct the band or explicitly keep it

**Plans:** 6/14 plans executed
**UI hint**: yes

Plans:
**Wave 1**

- [x] 01.8.1-01-PLAN.md — Tracer: invite-only magic-link staff sign-in via `phx.gen.auth` (registration/password/settings removed), role gate, `/admin` dashboard shell, owner release command (SC-1)
- [x] 01.8.1-02-PLAN.md — `games.status` draft/published/retired with a `published` deploy default, published-only public reads everywhere (checkpoint: retired-URL behavior) (SC-2)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01.8.1-03-PLAN.md — Production email: provider decision checkpoint, Swoosh HTTP adapter + `MAILER_API_KEY` plumbing, SPF/DKIM/DMARC (human action) (SC-1, D-36)
- [x] 01.8.1-04-PLAN.md — Retire the CSV seed path and clobbering upsert (checkpoint: remove vs disable), guard remaining backfills, rewrite the AGENTS.md runbook (D-09)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01.8.1-05-PLAN.md — Juegos admin: edit club-owned fields, publish/retire/restore, list with search + Cargar más, public Admin/Editar affordances (SC-2)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 01.8.1-06-PLAN.md — Add a game by BGG ID: Oban, async enrichment worker reusing BGG/R2/OG/Gemini modules, live-updating draft row (SC-2)
- [ ] 01.8.1-07-PLAN.md — Owner invites (max 3) and removes staff with immediate session disconnect (SC-1)

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 01.8.1-08-PLAN.md — Add-by-BGG hardening: failure + Reintentar, duplicate rejection, BGG URL/expansions, production enrichment secrets (SC-2)

**Wave 6** *(blocked on Wave 5 completion)*

- [ ] 01.8.1-09-PLAN.md — Shelves + phone-first walk-the-shelf tap-to-assign with undo, pick/restore list, staff-only location (SC-3)
- [ ] 01.8.1-10-PLAN.md — DB-driven home sections: tags→sections backfill migration (checkpoint: fate of `games.tags`), featured hero, hide-empty (SC-4)

**Wave 7** *(blocked on Wave 6 completion)*

- [ ] 01.8.1-11-PLAN.md — Sections filter facet + `?sections=` landing, public chips per the `games.tags` decision (SC-4)
- [ ] 01.8.1-12-PLAN.md — Staff section management: create/rename/reorder/hide, sort rules, phone member picker, featured cap (SC-4)

**Wave 8** *(blocked on Wave 7 completion)*

- [ ] 01.8.1-13-PLAN.md — Band audit with shared `Vocabulary.implied_weight_band/1`, correct / drift-aware keep, complete dashboard (SC-5)

**Wave 9** *(blocked on Wave 8 completion)*

- [ ] 01.8.1-14-PLAN.md — Production rollout: pre-deploy baseline, green PR, merge + owner creation (human action), live smoke verification (SC-1..SC-5)

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
Phases execute in numeric order: 0 → 1 → 01.7 → 01.8 → 01.8.1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Walking Skeleton to Production | 6/6 | Complete | 2026-07-27 |
| 1. Catalog v1 (+ 01.1–01.6) | 87/87 | Complete — shipped v1.0 | 2026-09-11 |
| 01.7. Production Catalog Data & Security Hardening | 5/5 | Complete    | 2026-09-11 |
| 01.8. SEO, Structured Data & Social Sharing | 7/7 | Complete    | 2026-09-12 |
| 01.8.1. Staff Admin — Ludoteca, Shelves & Curated Destacados | 6/14 | In Progress|  |
| 2. Natural-Language Spanish Search + Auth | 0/TBD | Not started | - |
| 3. RAG Rules Oracle | 0/TBD | Not started | - |
| 4. Club Operations | 0/TBD | Not started | - |
