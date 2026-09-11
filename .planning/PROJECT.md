# PukllayClub

## What This Is

A Spanish-language board-game catalog and recommender for a board-game club (~400 games). Members
browse a curated catalog and, in later phases, describe what they want in plain Spanish ("algo de
negociación estilo Catan") to get matches, ask rules questions and get AI-backed answers, and
(further out) track in-person rentals. Built for a casual or new board-game player — the UX must
teach the complexity of board games (weight, mechanics, authors, themes) rather than assume
familiarity.

## Core Value

A member can describe what they want in plain Spanish and find a game that fits — even without
already knowing board-game vocabulary. Everything before that (a working, deployed catalog) exists
to make that possible; everything after it (rules Q&A, rental tracking) is a differentiator on top.

## Requirements

### Validated

- [x] A trivial but real Phoenix app is deployed to production at pukllay.club over HTTPS, with CI,
      zero-downtime deploys, migrations-on-deploy, and nightly backups (Validated in Phase 0 —
      walking skeleton; live-verified against production, not just code review) — v1.0
- [x] Members can browse and filter a catalog of ~400 games with carousels/cards/streams, own
      resized images, complexity-teaching UX (visual weight, plain-language mechanic/theme chips),
      hard filters, and keyword search — fully public, no auth (Phase 1; shell/detail-page chrome
      shipped in Phase 1.1; catalog-grid and detail-page navigation/layout polished across 32 plans
      and 10 UAT gap-closure rounds in Phase 01.2, completed 2026-08-29; game detail page content
      accuracy — BGG stat/rank display, natural Argentine-Spanish descriptions, designer/artist
      filtering, reading-column layout — completed across 12 plans in Phase 01.3, 2026-09-01) — v1.0
- [x] Game gallery images are correctly cropped/letterboxed Spanish-edition box art, not
      cross-cropped or wrong-edition covers (Phase 01.3.1, 2 plans) — v1.0
- [x] The About page communicates the club clearly on every device: isologo scroll-morph with a
      companion wordmark, de-chromed Contacto links, a live Maps embed, and a full-viewport closing
      band with one consistent CTA rhythm — including a mobile sticky CTA that went through three
      design rounds (full bar → floating pill → hero-synced full bar) before landing on the
      industry-standard pattern the user asked for (Phases 01.4 + 01.5, 25 plans + 1 quick-task
      fix, 260910-av6) — v1.0
- [x] Light and dark themes read as one coherent system instead of two unrelated palettes — the
      whole UI rebuilt onto one shared, algorithmically-generated OKLCh ramp so specific roles
      literally share hex values across themes (Phase 01.6, 6 quick tasks) — v1.0

### Active

- [ ] Members can search the catalog with natural-language Spanish queries via local embeddings +
      pgvector hybrid ranking + LLM query parsing, and save favorites behind magic-link auth
      (Phase 2 — hero feature)
- [ ] Members can ask rules questions and get answers grounded in official rulebooks via RAG
      (Phase 3)
- [ ] Club admins can manage the catalog/copies and track in-person rentals (mark copy
      out/returned), with promotions (Phase 4)

### Out of Scope

- Multi-tenancy — single club, single tenant, no need
- Microservices / Kubernetes — solo dev, single production node, unnecessary ops burden
- Message broker — Oban (Postgres-backed) covers async work at this scale
- Separate vector DB, search service, or auth provider — pgvector + Postgres text search +
  phx.gen.auth keep everything in one database and one deploy
- GPU inference — local CPU embeddings + remote free-tier LLM generation only; no LLM call ever sits
  on the request hot path
- Online payments / MercadoPago — not needed for any current phase; club operations stay manual
- Group or "for you" recommendations — deferred until individual NL recommendation (Phase 2) is
  proven
- Voice interface for rules Q&A — deferred past Phase 3's text RAG

## Context

**Current state (after v1.0):** Live and deployed at https://pukllay.club. Public catalog of ~400
games with full browse/filter/keyword-search, complexity-teaching UX, game detail pages, an About
page, and a unified light/dark theme — no auth, no AI yet. ~39,800 LOC across
Elixir/HEEx/JS/CSS, 880 commits since 2026-07-24 (v1.0 spans 2026-07-24 to 2026-09-10, ~48 days).
24 known-debt items acknowledged at milestone close (19 diagnosed-but-unfixed debug sessions, all
cosmetic/minor UI findings; 1 pending content todo — surface the "Pukllay Club" brand name more
prominently; 3 stale `mix format` drift notes, mostly self-resolved by later plans) — see
STATE.md's Deferred Items table for the full list. Next milestone's hero feature (Phase 2:
natural-language Spanish search + magic-link auth) has not started.

**Target user:** a casual or new board-game player. The product must get them excited immediately,
which means the UX teaches board-game complexity (weight, mechanics, authors, themes) instead of
assuming the visitor already speaks the hobby's vocabulary.

**Phased roadmap (fixed order — later work does not pull forward):**
- **Phase 0 (this milestone's first phase):** Walking skeleton to production. `mix phx.new` app,
  AGENTS.md conventions (TDD loop, `mix quality` alias, manual-merge-gate rule), CI, Dockerfile for
  linux/arm64, Kamal deploy to a Hetzner CAX31, nightly pg_dump backups to Cloudflare R2. No product
  features, no auth, no AI/embeddings/Oban/BGG — the goal is a proven deploy pipeline, not
  gold-plating.
- **Phase 1 — Catalog v1:** fully public, no auth. Browse/filter UI, ~400 games seeded from CSV,
  own resized images, complexity-teaching UX, hard filters (scalar columns + text[] GIN), tsvector
  keyword search. No AI.
- **Phase 2 — Natural-language Spanish search (hero feature):** spike the ARM embedding runtime
  first, then local embeddings + pgvector + hybrid ranking + LLM query parsing (InstructorLite on
  Gemini free tier) + Oban. `phx.gen.auth` magic-link + favorites enter here. No group/"for you"
  recs yet.
- **Phase 3 — RAG rules oracle:** answers grounded in official rulebooks. Own focused effort —
  highest quality risk. Voice deferred.
- **Phase 4 — Club operations:** admin dashboard, catalog/copies management, in-person rental
  tracking (mark copy out/returned), promotions. Built late, against a stable schema. No online
  payments.

**Durable architecture principles (apply from the phase that introduces the relevant feature):**
- Local CPU embeddings + remote free-tier LLM generation, split; never an LLM call on the request
  hot path.
- Multi-valued tags as Postgres `text[]` + GIN indexes, not join tables, until a tag needs its own
  metadata.
- LiveView Streams for all collections; heavy work off the request path (Oban/async + PubSub).
- Anything slower than ~50ms never runs synchronously in `handle_event`.
- Native-feeling PWA + complexity-teaching UX is a standard on every screen, not a phase.

**Open decisions deferred to Phase 0 planning** (the user wants these discussed, not assumed, when
`/gsd-discuss-phase` and `/gsd-plan-phase` run for Phase 0):
- Phoenix release Dockerfile strategy for aarch64 (build approach, image size)
- Running Ecto migrations safely on deploy via Kamal
- Minimal secrets management approach (Kamal secrets vs env)

## Constraints

- **Tech stack**: Elixir + Phoenix 1.8 LiveView, single Phoenix app (no umbrella without a strong
  case), one PostgreSQL database for everything, Tailwind + daisyUI (phx.new defaults) — fixed;
  flag before deviating
- **Deploy**: Docker via Kamal to a single GCP e2-micro (x86_64, 2 vCPU shared / 1 GB RAM + 2GB
  swap, Always Free tier + ~$3.60/mo reserved external IP), kamal-proxy for reverse-proxy +
  automatic TLS, real domain (pukllay.club) — do not layer Caddy on top of Kamal. *(Originally
  planned as Hetzner CAX31 ARM/aarch64; switched during Phase 0 execution due to a 2026
  industry-wide DRAM/NVMe capacity shortage — see 00-CONTEXT.md D-20 and Key Decisions below.)*
- **Budget**: solo dev, ~€15/mo total — every infra choice optimizes for a live URL fast and
  near-zero ops
- **CI/tracking**: GitHub Actions for CI, GitHub Issues for backlog, AGENTS.md at repo root for
  agent conventions
- **Backups**: nightly `pg_dump` to Cloudflare R2 (S3-compatible, no egress fees)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Elixir/Phoenix LiveView + single Postgres DB, no umbrella | Solo dev, near-zero ops, one deploy target | ✓ Good — live in Phase 0 |
| Docker + Kamal to a single production host | ~€15/mo budget, zero-downtime deploys without k8s | ✓ Good, provider changed — planned Hetzner CAX31 (ARM), but a 2026 industry-wide capacity shortage forced a pivot to GCP e2-micro (x86_64) during Phase 0 execution; see 00-CONTEXT.md D-20. Live and verified at ~$3.60/mo, well under budget |
| Local CPU embeddings + remote free-tier LLM, never on request hot path | Keeps latency and cost predictable on a GPU-less single node | — Pending (Phase 2). Flagged risk: the GCP e2-micro host (1GB RAM) is smaller than originally planned — Phase 2's spike must verify against this box's real constraints |
| text[] + GIN for multi-valued tags instead of join tables | Avoids premature normalization until a tag needs its own metadata | — Pending |
| Cloudflare R2 for nightly backup storage | S3-compatible, no egress fees, fits budget | ✓ Good — live in Phase 0, manually verified |
| Business Context section omitted | Internal club tool — no payments, no revenue model | ✓ Good |
| Dockerfile strategy, migration safety, secrets management | Deferred to Phase 0 discuss/plan rather than decided at project init | ✓ Resolved in Phase 0 — entrypoint-gated migrations (D-05), GitHub Actions repo secrets (D-08), live-proven via a real migration shipped through the pipeline (D-06) |
| Phase 1.1 inserted (Site Shell & Content Pages) then Phase 01.2 inserted (Catalog & Detail Navigation Polish) — both urgent, both ahead of Phase 2 | Phase 1's catalog UX needed a real shared header/footer/about/detail shell before the hero NL-search feature would have anything worth searching into, then that shell's own mobile layout and lightbox needed a dedicated polish pass once real usage surfaced gaps | ✓ Good — both inserted phases complete; 01.2 in particular closed a 10-round UAT gap-closure chain (chip-system unification, lightbox rebuild, mobile masthead restructure) |
| Phase 01.3 inserted (Game Detail Layout & Content Accuracy) — real BGG re-enrichment (385/393 games) + a full Gemini-translated Spanish description batch (384/385 games), plus designer/artist filtering, reading-column layout rework, and a 3-round chevron/toggle CSS gap-closure chain (float→native line-clamp→absolute-overlay) | Phase 1/01.2 shipped the detail page's layout and navigation but its actual game data (BGG stats, English descriptions) and information hierarchy still needed correcting before NL search (Phase 2) surfaces it to members | ✓ Good — 12 plans, 8/8 UAT checkpoints passed (incl. 2 real-device WebKit confirmations), threats_open: 0. One gap (G-01.3-1, empty hashtag row) resolved as intended behavior — CSV-derived tag coverage is only 26% of the catalog, accepted rather than fixed |
| Phase 01.3.1 inserted (Game Image Quality & Multi-Image Gallery) — corrected `ImagePipeline.process_gallery/3` + catalog-wide `GalleryBackfill` re-run over ~434 games, plus a shared `.pk-poster-img` letterbox/contain class applied to every artwork surface except the lightbox and 64x64 selector chips | BGG's gallery images could be other-edition/other-language box covers (not photos of the actual game) and box art was being cropped to fill a fixed near-square frame — both silently broke the already-Complete CATALOG-01/CATALOG-09 requirements | ✓ Good — 2/2 plans, both UAT checkpoints passed (letterbox rendering across all surfaces; motivating example BGG id 305096 shows the correct Spanish/Fantasía cover with no stray thumbnail/dot strip). D-02 scope constraint: BGG's XML API v2 exposes no reachable gameplay/component photos (one image per thing/version, no caption/category, direct site probes 403) — gallery scope reduced to Spanish-edition box art only rather than the original multi-photo ask |
| Phase 01.4 inserted (UI Polish Pass for About Page Sketches) — real April-2021 origin/$5.000-$7.000 pricing copy, 80rem band width fix, 5-photo rail, de-duplicated Contacto card, isologo scroll-morph header mechanic, and (after a 3-round gap-closure arc) a live keyless Google Maps embed replacing the original static screenshot thumbnail | The About page sketches (D-01..D-15 in 01.4-CONTEXT.md) needed to ship as real code before the site could be called "finished" for members, and two UAT rounds surfaced that the isologo motion and the Maps thumbnail both needed real code fixes, not just tuning | ✓ Good — 11/11 plans (plan 01.4-11 superseded/discarded by 01.4-12, absorbed cleanly), 7/7 UAT checkpoints passed after a 4-gap closure arc (G-01.4-1..4), 01.4-VERIFICATION.md round 3: 11/12 truths verified + 1 human-confirmed at end. Google Maps embed reopened mid-phase per the user's own question ("what if we integrate google maps..."), requiring a new CSP `frame-src` directive (first third-party frame origin) — closed with 46 threats registered across all 12 plans, threats_open: 0 (01.4-SECURITY.md) |
| Phase 01.5 inserted (About Page CTA Rhythm & Header Morph Refinement) — isologo scroll-morph gains a companion "PUKLLAY CLUB" wordmark synced to the header dock boolean, Cierre band becomes a full-viewport closing destination with unified gap-based rhythm, and the mobile sticky CTA went through three rounds (full-width bar → user-rejected floating pill → hero-synced full-width bar, quick task 260910-av6) before satisfying the user's ask for an industry-standard pattern | Round-1 and round-2 UAT found the hero/Cierre CTA composition, band whitespace, and Cierre/footer contrast all needed real fixes, not just the sketch's static mockup; round-3 then rejected the shipped mobile-CTA design outright as a UX preference, not a defect | ✓ Good — 14 plans + 1 follow-up quick task, 20/20 UAT tests resolved (14 pass, 2 superseded-by-later-fix, 4 marked superseded from earlier rounds), final end-of-phase human walkthrough confirmed 2026-09-10 against a live re-run of test/visual/about_geometry.mjs (0 failures) |
| Phase 01.6 inserted (Light/Dark Theme Color-Family Consistency) — six quick tasks progressively fixed dark-mode composition, CTA contrast, interactive-vs-muted ink split, and a chip/pill hue mismatch, then rebuilt the whole palette on one shared 11-stop OKLCh ramp so specific roles (e.g. a CTA fill and its dark-mode card-surface counterpart) literally share the same hex value | Developer complaint that dark mode felt "too dark" and inconsistent with light mode; researched prior art and found only Material Design 3 does literal cross-theme value reuse, adopted that approach here | ✓ Good — 6/6 quick tasks executed and deployed (PR #35), enforced going forward by a drift-blocking test invariant |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-09-11 after v1.0 milestone*
