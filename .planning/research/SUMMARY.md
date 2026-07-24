# Project Research Summary

**Project:** PukllayClub
**Domain:** Board-game catalog / discovery / recommendation product (small club scale, ~400 games), built on Elixir/Phoenix LiveView, deployed single-node ARM
**Researched:** 2026-07-24
**Confidence:** MEDIUM-HIGH

## Executive Summary

PukllayClub is a board-game catalog and discovery product for a small club (~400 games), whose core differentiator is teaching non-hobbyists what a game actually plays like — translating BGG's opaque 1-5 complexity number and jargon-heavy mechanic taxonomy into plain Spanish — rather than being "a smaller BoardGameGeek." Research confirms this is a genuinely underserved niche: no competitor (BGG, board-game-cafe SaaS, existing NL recommenders) solves plain-language complexity translation or offers Spanish-language, rulebook-grounded rules Q&A at small-catalog scale. The already-fixed phase order (0: deploy skeleton, 1: catalog, 2: NL search + auth, 3: RAG rules oracle, 4: rental tracking) is validated by both the feature-dependency graph and the architecture: each phase adds exactly one new Elixir context on a stable base, and heavier phases (2, 3) reuse a shared local-embedding runtime rather than duplicating it.

The recommended approach is a single Phoenix 1.8/LiveView BEAM node behind Kamal 2 (kamal-proxy for TLS/zero-downtime cutover) on a single Hetzner CAX31 ARM box, with one Postgres 17 (pgvector + native tsvector) doing double duty as system-of-record and Oban's job queue — no separate services, no message broker. The single most load-bearing technical fact from this research is that EXLA ships a precompiled `aarch64-linux-gnu` (glibc) XLA binary, meaning local CPU embeddings via Bumblebee/Nx are *plumbing-feasible* on ARM without a slow from-source build — but actual embedding *throughput/latency* on real CAX31 hardware is genuinely unverified by any source found, which is exactly why the project's plan to spike this first in Phase 2 is correct and should not be skipped or shortcut.

The dominant risk cluster is deployment plumbing, not product features: cross-building the ARM image under QEMU (should build natively instead), Kamal having no built-in migration hook (needs a custom entrypoint gating on the generated `Release.migrate`), secrets ending up in `.kamal/secrets` history, and health-check/readiness misconfiguration once Phase 2 adds embedding-model boot weight. A second risk cluster appears in Phase 2: pgvector index choice (use HNSW, not IVFFlat, at this row count), `maintenance_work_mem` defaults causing silent index-quality degradation, Oban concurrency starving the shared Ecto pool, and treating the free-tier Gemini API as dependable rather than building the fallback/backoff path the async architecture already makes cheap. All of these are addressed with concrete, low-cost mitigations documented in PITFALLS.md and should be treated as Phase 0/Phase 2 "definition of done" items, not later hardening work.

## Key Findings

### Recommended Stack

Core stack is already fixed by the project (Elixir/Phoenix/Kamal/single-Postgres/Hetzner); this research de-risks library-level choices within it rather than proposing alternatives. Elixir 1.19.x / OTP 28.x / Phoenix 1.8.9 / LiveView 1.2.7 are current-stable and version-compatible. Deploy via `mix phx.gen.release --docker`, Debian-slim (not Alpine) runner base — required both for Phoenix's own DNS-safety convention and because EXLA's ARM binaries only target glibc — built natively for `linux/arm64` (never QEMU). Postgres 17 via the `pgvector/pgvector:pg17` image as a Kamal accessory, bound to localhost only. AI/search stack: Bumblebee + EXLA (with `Nx.default_backend(EXLA.Backend)` explicitly set — the single most important non-obvious config step, or embeddings silently fall back to a >60x slower pure-Elixir path) for local CPU embeddings, `intfloat/multilingual-e5-small` as the candidate model (confirm via Phase 2 spike), pgvector + native Postgres `tsvector`/Spanish full-text search for hybrid RRF ranking, Oban (free tier) for async jobs, InstructorLite + Gemini adapter for structured LLM parsing. Quality gates: Credo `--strict`, Sobelow, `mix format --check-formatted`, `mix test --warnings-as-errors`, wired into a `mix quality` alias and `erlef/setup-beam`-based CI.

**Core technologies:**
- Phoenix 1.8 + LiveView — real-time UI, streams for all lists, already fixed
- PostgreSQL 17 + pgvector + native tsvector — single system-of-record for catalog, embeddings, jobs, auth
- Bumblebee/Nx/EXLA (CPU) — in-process local embeddings, no Python sidecar; must explicitly set EXLA as the Nx backend
- Oban — Postgres-backed async queue for every LLM/embedding call, keeps the request hot path under ~50ms
- InstructorLite + Gemini adapter — structured LLM output for NL query parsing (Phase 2) and grounded rules answers (Phase 3)
- Kamal 2 + kamal-proxy — zero-downtime deploy + TLS, no separate Caddy/Traefik

### Expected Features

The domain is board-game catalog/discovery for a small club; research confirms table-stakes catalog features are well-understood and cheap, while the real differentiator work is in translation/UX (complexity, mechanics) and true Spanish NL search — both genuinely uncommon in this space.

**Must have (table stakes):**
- Browse/filter catalog by player count, playtime, category/mechanic/theme, keyword search — no account required
- Own resized cover images (recognition is the primary browsing cue)
- Complexity/weight indicator and minimum-age filter, sortable results, mobile-first fast UI

**Should have (competitive differentiators):**
- Plain-Spanish weight-band complexity descriptor (not a bare 1-5 number) — highest-leverage UX move, no competitor solves this well
- Plain-Spanish mechanic/theme chips (curated ~15-25 vocabulary, not BGG's 100+ taxonomy)
- Natural-language Spanish query → matched games (Phase 2 hero feature) — genuinely rare in this space
- Rules Q&A grounded in official rulebooks with citations (Phase 3), scoped per-game to control hallucination risk
- Lightweight rental tracking (Phase 4) — deliberately smaller than cafe-SaaS ops suites

**Defer / reject (anti-features):**
- BGG-style public ratings/rank, full 100+ mechanic taxonomy, collaborative "users who liked X" recs (no data volume at this scale), table/session reservation systems, general cross-game rules chatbot, voice interface, membership/payment features, icon-only complexity/mechanic cues (increases cognitive load for the target non-hobbyist audience)

### Architecture Approach

Single Phoenix release on one BEAM node: LiveView modules call plain-Elixir contexts (one per roadmap phase — `Catalog`, `Search`, `RulesOracle`, `ClubOps`, `Accounts`) for fast (<50ms) synchronous reads/writes; anything slower (LLM calls, embeddings, RAG, ingestion) is enqueued as an Oban job and results delivered back via a request-scoped `Phoenix.PubSub` topic, never called inline from `handle_event`. A shared `embeddings/runtime.ex` infra module (not a business context) wraps the local Nx.Serving model and is used by both `Search` and `RulesOracle` without either context reaching into the other. Tags/mechanics use native `text[]` + GIN (no join table) at this scale. One Postgres database holds catalog data, embeddings (HNSW-indexed), rulebook chunks, rentals, auth, and Oban's own job tables.

**Major components:**
1. `Catalog` context (Phase 1) — games, copies, tags; foundational, browse/filter is the fast synchronous baseline every later phase must not degrade
2. `Search` context (Phase 2) — hybrid NL query parsing (LLM) + local embedding + RRF-fused pgvector/tsvector ranking, enqueue-and-subscribe pattern
3. `RulesOracle` context (Phase 3) — per-game-scoped RAG: chunk/embed rulebooks (admin ingestion pipeline), retrieve top-k, grounded LLM answer with citation
4. `ClubOps` context (Phase 4) — rental tracking (copy status + holder), FK's into Catalog's copy schema, needs an admin-role concept distinct from member magic-link auth
5. `Accounts` (phx.gen.auth, Phase 2) — member magic-link auth + `Scope` struct consumed by other contexts needing authorization

### Critical Pitfalls

1. **QEMU cross-build for the ARM image** — 5-20x slower and can crash under Erlang JIT; build natively (arm64 CI runner or the CAX31 host itself), never `--platform=linux/arm64` from an amd64 runner.
2. **No built-in Kamal migration hook** — wire a custom entrypoint that runs the generated `Release.migrate` before `bin/server` starts, gating traffic cutover on migration success via the health check; never run `mix ecto.migrate` against a release (Mix isn't available).
3. **Secrets in `.kamal/secrets`** — gitignore it, source real values via CI-injected env substitution (never literals), scope secrets per role/accessory explicitly, rotate anything ever committed.
4. **ARM embedding runtime performance is unverified** — plumbing works (EXLA has a precompiled aarch64-linux-gnu binary) but throughput/latency on real CAX31 hardware is a genuine unknown; the Phase 2 "spike first" plan is correct and must not be skipped — benchmark before committing, prefer FP32/INT8 over FP16 on ARM.
5. **pgvector index and memory tuning at small scale** — use HNSW (not IVFFlat, whose centroids get baked in if built before the full seed loads); raise `maintenance_work_mem` before `CREATE INDEX` or builds silently degrade/spill to disk.
6. **Free-tier Gemini as a hard dependency** — build retry/backoff and a non-LLM (keyword/embedding-only) fallback into Phase 2's search flow from the start, since rate limits and quota changes are real and undocumented in advance.

## Implications for Roadmap

The project's phase order (0-4) is already fixed in PROJECT.md; this research validates that order and adds concrete definition-of-done items per phase rather than proposing a different structure.

### Phase 0: Deploy Skeleton
**Rationale:** Prove the full deploy loop (CI → native arm64 Docker build → Kamal → migrations-on-deploy → HTTPS → nightly backup) before any product/AI code exists — architecture research explicitly warns against gold-plating this phase with pgvector/Oban "to save a migration later."
**Delivers:** Working Kamal+Postgres deploy pipeline with zero-downtime, migration-gated releases and a tested nightly `pg_dump`→R2 backup+restore drill.
**Addresses:** No product features — infra only.
**Avoids:** Pitfalls 1-4 (QEMU cross-build, missing migration hook, plaintext secrets, misconfigured health check) — all four are explicitly flagged Phase 0 decisions.

### Phase 1: Catalog v1
**Rationale:** Feature research confirms browse/filter/complexity-translation is the minimum viable product that validates the core hook (teaching complexity, not assuming it) — and architecture research confirms this phase sets the `text[]`+GIN and `tsvector` precedent that Phase 2/3 hybrid search reuses.
**Delivers:** Public, no-auth catalog browse/filter/search with weight-band complexity descriptors and plain-Spanish mechanic/theme chips.
**Addresses:** All table-stakes features + the plain-Spanish complexity/mechanic differentiators from FEATURES.md.
**Avoids:** Establishes the tag-vocabulary contract Phase 2's NL parser depends on — retrofitting it later would require redoing the parser's target schema.

### Phase 2: NL Search + Auth
**Rationale:** The hero differentiator (Spanish NL query matching) sits on top of a proven catalog; architecture requires local embeddings + LLM parsing to be split into separate async jobs/queues with independent retry policies, and this is also where the ARM embedding spike must happen first.
**Delivers:** Spike-validated local embedding runtime, hybrid RRF search, magic-link auth (`phx.gen.auth`) + favorites.
**Uses:** Bumblebee/EXLA, pgvector (HNSW), InstructorLite/Gemini, Oban (`:llm` and `:embeddings` queues sized against Postgres `max_connections`).
**Implements:** `Search` context, `embeddings/runtime.ex` shared infra, enqueue-and-subscribe pattern (Pattern 1).

### Phase 3: Rules Oracle (RAG)
**Rationale:** Depends on stable per-game identity from Phase 1 and the shared embedding runtime from Phase 2; scoping Q&A to one selected game at a time (not open cross-catalog chat) controls hallucination risk per the competitor pattern research validated (cite-the-passage builds trust).
**Delivers:** Admin rulebook ingestion pipeline + member-facing per-game rules Q&A with citations.
**Addresses:** Rules Q&A differentiator from FEATURES.md.
**Avoids:** Anti-pattern of a general-purpose cross-game chatbot (explicitly rejected in FEATURES.md).

### Phase 4: Club Ops (Rental Tracking)
**Rationale:** Deliberately last — built against a stable schema per PROJECT.md, and feature research confirms this needs an admin-role concept not yet introduced by Phase 2's member-only magic-link auth.
**Delivers:** Copy status + holder tracking (check-out/check-in), admin-only mutation path.
**Addresses:** Lightweight rental tracking differentiator, deliberately scoped smaller than cafe-SaaS competitors.
**Avoids:** Anti-features (reservation/scheduling systems, payments) explicitly rejected in FEATURES.md.

### Phase Ordering Rationale

- Each phase adds exactly one new Elixir context without restructuring earlier ones (architecture's "one context per phase" principle) — this is why the fixed 0→1→2→3→4 order works without rework.
- Feature dependencies confirm the order is forced, not arbitrary: complexity-teaching UX requires Phase 1's data; NL search requires Phase 1's tag vocabulary; Rules Q&A requires Phase 1's stable game identity; rental tracking requires an admin-role concept only worth introducing once the schema (Phase 1-3) is stable.
- Deployment/infra pitfalls cluster entirely in Phase 0; AI/data pitfalls cluster entirely in Phase 2 — this maps cleanly onto the phase boundaries and argues for treating both phases' pitfall checklists as literal done-criteria, not follow-up hardening.

### Research Flags

Needs deeper research during planning:
- **Phase 2:** ARM embedding runtime throughput is a genuine open unknown (no ARM-specific benchmark exists anywhere) — plan an explicit spike/benchmark step before committing to Bumblebee vs. Ortex or a specific model. Also re-verify Gemini's current free-tier model name/RPM limits at implementation time (documentation churns faster than this research can track).
- **Phase 3:** RAG chunking/retrieval quality and citation UX have no reference implementation to copy from competitors (per FEATURES.md) — expect iteration once real rulebooks are ingested.

Phases with standard, well-documented patterns (research-phase likely unnecessary):
- **Phase 0:** Kamal+Phoenix deploy pattern is well-documented across multiple independent sources (AppSignal, Fly.io Phoenix Files, official Kamal/Phoenix docs) — follow STACK.md/PITFALLS.md directly.
- **Phase 1:** Standard Ecto/Phoenix context + `text[]`/GIN/tsvector patterns, confirmed against official hexdocs.
- **Phase 4:** Simple CRUD-style rental tracking on top of an already-stable schema; low technical risk per architecture research.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Versions verified directly against hex.pm/GitHub release APIs (HIGH); deployment/config patterns cross-checked across 2+ sources (MEDIUM); ARM embedding feasibility has a real open risk (throughput unverified) |
| Features | MEDIUM | Cross-checked across multiple community/vendor sources, no primary product documentation exists for this exact niche — directional, not settled fact, especially the weight-band descriptor wording |
| Architecture | MEDIUM | Phoenix/Ecto/phx.gen.auth patterns confirmed against official hexdocs (HIGH); pgvector hybrid-search and Bumblebee/ARM patterns cross-checked across 2-3 independent write-ups (MEDIUM); ARM CPU throughput numbers are from non-ARM, non-Elixir benchmarks |
| Pitfalls | MEDIUM | Web-sourced, cross-checked across multiple independent sources per topic; no official case study exists for this exact stack combination, so scale numbers are directional |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- ARM CPU embedding latency/throughput for `multilingual-e5-small` (or equivalent) on real CAX31 hardware — no source anywhere gives concrete numbers on ARM64; must be resolved via the Phase 2 spike, not assumed from this research.
- Gemini free-tier model name and RPM/RPD limits — verify against Google AI Studio's current pricing page at Phase 2 implementation time, not from this document.
- Exact weight-band wording/format for the plain-Spanish complexity descriptor — no competitor reference implementation exists; will need its own design iteration during Phase 1 UI design.
- Whether the source CSV data includes a minimum-age field — confirm during Phase 1 planning.
- Postgrex is mid-transition to 1.0.0 (currently `-rc.1`) — check for a final stable release at Phase 0 implementation time.

## Sources

### Primary (HIGH confidence)
- hex.pm package API — version numbers for Phoenix, LiveView, Ecto SQL, Postgrex, Oban, pgvector, InstructorLite, Bumblebee, EXLA, Nx, xla, Credo, Sobelow, Req, Finch
- github.com/elixir-nx/xla releases API — confirmed `aarch64-linux-gnu` precompiled XLA binary exists
- hexdocs.pm/phoenix (Contexts, Cross-context Boundaries, mix phx.gen.auth, Releases) — official Phoenix docs
- hexdocs.pm/ecto_sql — Ecto.Migration official docs
- hexdocs.pm/pgvector — official pgvector-elixir library docs

### Secondary (MEDIUM confidence)
- AppSignal Blog — Deploying/Advanced Strategies for Phoenix with Kamal
- kamal-deploy.org — secrets, environment variables, healthcheck configuration docs
- Fly.io Phoenix Files — Safe Ecto Migrations, Tag All the Things, GitHub Actions CI
- Jonathan Katz / Crunchy Data / Tembo — pgvector hybrid search and HNSW vs IVFFlat tuning
- DockYard — Ortex/ONNX on Elixir
- Elixir Forum threads — Bumblebee/EXLA backend performance, InstructorLite Gemini adapter, ARM Docker build issues
- BGG community threads, NN/g UX research, board-game-cafe SaaS vendor sites (TWICE, GameLedger, GameShelf), rules-Q&A AI products (RulesBot.ai, Boardside, BGRB) — feature landscape and competitor analysis

### Tertiary (LOW confidence)
- Nixiesearch/Medium — non-ARM, non-Elixir embedding quantization benchmark, used only as directional illustration of FP16-on-ARM risk, not a guarantee

---
*Research completed: 2026-07-24*
*Ready for roadmap: yes*
