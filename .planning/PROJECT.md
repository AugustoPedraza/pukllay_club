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

(None yet — ship to validate)

### Active

- [ ] A trivial but real Phoenix app is deployed to production at pukllay.club over HTTPS, with CI,
      zero-downtime deploys, migrations-on-deploy, and nightly backups (Phase 0 — walking skeleton)
- [ ] Members can browse and filter a catalog of ~400 games with carousels/cards/streams, own
      resized images, complexity-teaching UX (visual weight, plain-language mechanic/theme chips),
      hard filters, and keyword search — fully public, no auth (Phase 1)
- [ ] Members can search the catalog with natural-language Spanish queries via local embeddings +
      pgvector hybrid ranking + LLM query parsing, and save favorites behind magic-link auth
      (Phase 2 — hero feature)
- [ ] Members can ask rules questions and get answers grounded in official rulebooks via RAG
      (Phase 3)
- [ ] Club admins can manage the catalog/copies and track in-person rentals (mark copy
      out/returned), with promotions (Phase 4)

### Out of Scope

- Multi-tenancy — single club, single tenant, no need
- Microservices / Kubernetes — solo dev, single Hetzner node, unnecessary ops burden
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
- **Deploy**: Docker via Kamal to a single Hetzner CAX31 (ARM/aarch64, 8 vCPU / 16 GB, no GPU),
  kamal-proxy for reverse-proxy + automatic TLS, real domain (pukllay.club) — do not layer Caddy on
  top of Kamal
- **Budget**: solo dev, ~€15/mo total — every infra choice optimizes for a live URL fast and
  near-zero ops
- **CI/tracking**: GitHub Actions for CI, GitHub Issues for backlog, AGENTS.md at repo root for
  agent conventions
- **Backups**: nightly `pg_dump` to Cloudflare R2 (S3-compatible, no egress fees)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Elixir/Phoenix LiveView + single Postgres DB, no umbrella | Solo dev, near-zero ops, one deploy target | — Pending |
| Docker + Kamal to a single Hetzner CAX31 (ARM) | ~€15/mo budget, zero-downtime deploys without k8s | — Pending |
| Local CPU embeddings + remote free-tier LLM, never on request hot path | Keeps latency and cost predictable on a GPU-less single node | — Pending |
| text[] + GIN for multi-valued tags instead of join tables | Avoids premature normalization until a tag needs its own metadata | — Pending |
| Cloudflare R2 for nightly backup storage | S3-compatible, no egress fees, fits budget | — Pending |
| Business Context section omitted | Internal club tool — no payments, no revenue model | ✓ Good |
| Dockerfile strategy, migration safety, secrets management | Deferred to Phase 0 discuss/plan rather than decided at project init | — Pending |

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
*Last updated: 2026-07-24 after initialization*
