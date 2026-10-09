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

## Current Milestone: v1.2 Web Tab — Sketch 070 Parity

**Goal:** Bring the admin Web tab (`/admin/secciones`) to full parity with sketch 070 — the design
the developer approved after driving the artefact. Of every admin screen, this is the one whose
shipped implementation sits furthest from its settled design.

**Target features:**
- **The destacada rail becomes the add surface:** a "+" in every gap (N+1 slots, 44px hit box), the
  `¿Qué juego va acá?` full-height sheet behind each one (`Últimas novedades` idle list, search, a
  game already in the row *moves* rather than duplicates), the empty-rail dashed tile, and the
  20-game cap dimming the slots. The inline `Agregar un juego` field is **deleted** — 070's
  decision 12 forbids a second control beside the main one (D-19j).
- **`Crear «{q}»` gets designed, not stubbed:** the no-match branch is the one piece sketch 070
  never drew. It gets its own sketch round first (Estantes' equivalent is settled in sketch 069
  decision 66), then ships.
- **Moving a game:** the cover sheet grows to `Ver ficha` / `Mover` / `Quitar de la fila`, and
  `Mover` opens `¿Dónde va?` — the rail drawn *without* the moving game, so the gaps are the
  positions it can actually land in.
- **"Destacada" becomes a role, not a row** (070 decision 7): `Destacar` / `Cambiar la destacada`
  move the role between hand-picked rows. This is the milestone's only net-new product behaviour
  and its only data-model work — `sections.featured` is currently set *only* by a migration
  backfill — and it carries the "only `:manual` rows" and ">20 games cannot be destacada"
  invariants, with the cap following the role.
- **Row and page chrome:** the row name becomes a 44px button opening the row-options sheet; ⇅ and
  ＋ move into the page header; the inline `Ajustes` panel and the bottom create form collapse into
  one `Editar fila` / `Nueva fila` form sheet (subtitle textarea, 40/160 limits); `Otras filas` rows
  get the tile + corner count badge (D-19m); `Ordenar filas` gains drag and a locked `Destacada`
  row reading `Siempre primera`.
- **Context line and copy:** `{n} de 20 juegos`, the `Vacía` / `hasta 20` tails, the `● Oculta ·`
  prefix, and every snackbar — all Spanish **verbatim** from the findings note, Argentine voseo.
- **Backend for positions:** `Sections` gains insert-at-index and move-to-index, preserving the
  dense-position invariant (D-25) and the transactional 20-game cap.
- `section_live/edit.ex` becomes the same page shape with a `‹ Web` back link.

**Why this milestone exists:** phase 01.8.2 "Admin UI/UX Redesign" sealed 22/22 in v1.1, but for
this page it delivered only a slice — its own moduledoc says *"this plan changes presentation and
the removal/undo shape only."* The remaining 070 scope was never recorded as deferred: it is absent
from `01.8.2/deferred-items.md` and from the 12 artifacts acknowledged at v1.1's
`override_closeout`. The design contract is sketch 070 plus
`.claude/skills/sketch-findings-pukllay_club/references/admin-web-destacados.md`; where the two
disagree, the artefact wins (070's README is known-stale on four points).

**Scope boundary:** this milestone is the **Web tab only**. The other admin pages likely carry the
same class of sealed-phase-vs-sketch gap, but that is unmeasured — measuring it is the explicit
reassessment at the end of this milestone, not part of it.

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
- [x] Production's live database has the real ~434-game catalog loaded — restored over an SSH
      tunnel with a content-idempotent, re-runnable upsert (Phase 01.7, 2026-09-11) — v1.1
- [x] The production app follows baseline web security practice: env-gated `Secure` session
      cookie via an explicit contract, HSTS, CSP audited and pinned as regression assertions, CSRF
      confirmed to cover LiveView's websocket connect flow (Phase 01.7, 2026-09-11) — v1.1
- [x] No secrets, keys, or credentials are discoverable anywhere in the public repo or its git
      history — full-history Gitleaks sweep, one reviewed false positive, no real leaks (Phase
      01.7, 2026-09-11) — v1.1
- [x] Game detail and catalog pages carry real SEO metadata — per-page descriptions, image `alt`
      text, `robots.txt`, `sitemap.xml`, and schema.org JSON-LD — so the catalog is discoverable on
      Google and reads as a Jujuy business (Phase 01.8, 7/7 plans, 2026-09-12) — v1.1
- [x] Shared game links render an on-brand preview on WhatsApp/Facebook/Twitter — Open Graph +
      Twitter Card tags per game plus a site-wide isologo fallback, on the same canonical URL the
      native-share control already built (Phase 01.8, 2026-09-12) — v1.1
- [x] Staff can run the club's catalog from a real admin: the Ludoteca game editor, physical
      shelves (estantes) with per-copy placement, and hand-curated home rows (destacados), all
      behind staff auth (Phase 01.8.1, 15/15 plans, 2026-09-16) — v1.1
- [x] The admin reads as one designed system rather than scaffolding — a shared sheet / dialog /
      snackbar / button vocabulary, the app-wide D-19 rules (status is dot + text, chevron only
      when a row opens a page, reorder is a mode, destructive = centred dialog), and the bottom-tab
      shell (Phase 01.8.2, 22/22 plans, 2026-10-09). **Partial for the Web tab** — see Current
      Milestone above — v1.1
- [x] Each admin screen was refined individually against its own sketch, one page at a time
      (Phase 01.8.3, 14/14 plans, 2026-09-28) — v1.1

### Active

- [ ] Staff can curate the public home's destacada row entirely from the rail: tap the "+" in any
      gap to place a game at that exact spot, move a game to another spot, and move the destacada
      role itself between hand-picked rows — the admin Web tab at full sketch-070 parity (v1.2)
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
| Phase 01.7 (Production Catalog Data & Security Hardening) — production DB restored to the real ~434-game catalog over an SSH tunnel (content-idempotent upsert on `csv_row`); env-gated `Secure` session cookie via an explicit `session_options/0` contract; CSP audited directive-by-directive and pinned as regression assertions; CSRF confirmed to cover LiveView's websocket connect flow; full-git-history Gitleaks secrets sweep | The now-public repo and a link that gets passed around needed baseline web-security practice, and the live site was serving an empty catalog until the seed pipeline (dev-machine-only by design) could safely reach production | ✓ Good — 5/5 plans, 3/3 UAT checkpoints passed, threats_open: 0 (01.7-SECURITY.md). One UAT finding (missing disconnect banner) diagnosed as a test-method artifact (Chrome DevTools Offline doesn't sever WebSockets), not an app defect — re-verified via `liveSocket.disconnect()/connect()`, passed clean. Two unrelated pre-existing UI issues (banner positioning, `JS.show` display override) surfaced incidentally and logged to STATE.md Blockers/Concerns, out of this phase's scope |

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
*Last updated: 2026-10-09 after v1.1 close — opened milestone v1.2, moved the shipped
v1.1 SEO/sharing and admin phases (01.8, 01.8.1, 01.8.2, 01.8.3) into Validated.*
