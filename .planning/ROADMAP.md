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
- [ ] **Phase 01.8: SEO, Structured Data & Social Sharing** - Per-game meta/OG/Twitter tags, `Game` + `LocalBusiness` JSON-LD under a nonced CSP, live `sitemap.xml`, real `robots.txt`, and real image `alt` text

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

**Plans**: 5 plans

Plans:
**Wave 1**

- [ ] 01.8-01-PLAN.md — Wave 1 · CSP nonce refactor plus the crawler-visible per-game SEO chain: `GameSEO`/`SiteSEO` plugs, the `SEO` payload builder, `SEOTags`, meta description, Open Graph/Twitter tags and `Game` JSON-LD (SEC-05, SEO-01, SEO-05, SHARE-01, SHARE-02)
- [ ] 01.8-02-PLAN.md — Wave 1 · Real `alt` text across all six cover render branches on `GameCard` and `GamePreview`, via one shared generator that handles the sparse-publishers case (SEO-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 01.8-03-PLAN.md — Wave 2 · Request-time `sitemap.xml` from the live catalog, plus real `robots.txt` content pointing at it (SEO-03, SEO-04)
- [ ] 01.8-04-PLAN.md — Wave 2 · The 1200x630 og-card letterbox transform, its one-time `catalog.backfill_og_cards` batch, and the real run against the live catalog (SHARE-03, SHARE-05)
- [ ] 01.8-05-PLAN.md — Wave 2 · `LocalBusiness` JSON-LD from the locked club facts, `ClubLinks.public_phone/0`, and the sketch-approved branded OG fallback card (SEO-06, SHARE-04)

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
Phases execute in numeric order: 0 → 1 → 01.7 → 01.8 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Walking Skeleton to Production | 6/6 | Complete | 2026-07-27 |
| 1. Catalog v1 (+ 01.1–01.6) | 87/87 | Complete — shipped v1.0 | 2026-09-11 |
| 01.7. Production Catalog Data & Security Hardening | 5/5 | Complete    | 2026-09-11 |
| 01.8. SEO, Structured Data & Social Sharing | 0/TBD | Not started | - |
| 2. Natural-Language Spanish Search + Auth | 0/TBD | Not started | - |
| 3. RAG Rules Oracle | 0/TBD | Not started | - |
| 4. Club Operations | 0/TBD | Not started | - |
