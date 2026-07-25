<!-- GSD:project-start source:PROJECT.md -->

## Project

**PukllayClub**

A Spanish-language board-game catalog and recommender for a board-game club (~400 games). Members
browse a curated catalog and, in later phases, describe what they want in plain Spanish ("algo de
negociación estilo Catan") to get matches, ask rules questions and get AI-backed answers, and
(further out) track in-person rentals. Built for a casual or new board-game player — the UX must
teach the complexity of board games (weight, mechanics, authors, themes) rather than assume
familiarity.

**Core Value:** A member can describe what they want in plain Spanish and find a game that fits — even without
already knowing board-game vocabulary. Everything before that (a working, deployed catalog) exists
to make that possible; everything after it (rules Q&A, rental tracking) is a differentiator on top.

### Constraints

- **Tech stack**: Elixir + Phoenix 1.8 LiveView, single Phoenix app (no umbrella without a strong
  case), one PostgreSQL database for everything, Tailwind + daisyUI (phx.new defaults) — fixed;
  flag before deviating

- **Deploy**: Docker via Kamal to a single GCP e2-micro (x86_64, 2 vCPU shared / 1 GB RAM + 2GB
  swap, Always Free tier + ~$3.60/mo reserved external IP), kamal-proxy for reverse-proxy +
  automatic TLS, real domain (pukllay.club) — do not layer Caddy on top of Kamal. *(Originally
  planned as Hetzner CAX31 ARM/aarch64; switched during Phase 0 execution due to a 2026 industry-
  wide DRAM/NVMe capacity shortage affecting Hetzner's CAX/CX tiers and Oracle Cloud's free ARM
  tier alike — see 00-CONTEXT.md D-20 for full rationale and downstream implications, including a
  flagged Phase 2 sizing risk for local embedding inference.)*

- **Budget**: solo dev, ~€15/mo total — every infra choice optimizes for a live URL fast and
  near-zero ops

- **CI/tracking**: GitHub Actions for CI, GitHub Issues for backlog, AGENTS.md at repo root for
  agent conventions

- **Backups**: nightly `pg_dump` to Cloudflare R2 (S3-compatible, no egress fees)

<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->

## Technology Stack

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir | 1.19.x | Language | Current stable (Oct 2025 release); up to 4x faster compilation for large projects, enhanced type checking. Requires OTP 28.1+. Phoenix 1.8 only requires Elixir 1.15+, so this is headroom, not a hard requirement — pin to whatever `mix phx.new` scaffolds if it lags slightly. |
| Erlang/OTP | 28.x | BEAM runtime | Paired with Elixir 1.19. `hexpm/elixir` Docker images (used by `mix phx.gen.release --docker`) are multi-arch and publish `linux/arm64` builds for every Elixir+OTP+Debian combination — no ARM-specific Dockerfile changes needed for the builder stage. |
| Phoenix | 1.8.9 | Web framework | Already the project's fixed choice. 1.8.x is the current stable line (1.8.0 → 1.8.9 as of this research). |
| Phoenix LiveView | 1.2.7 | Real-time UI | Ships with Phoenix 1.8 scaffolding; use whatever `mix phx.new` pins — don't hand-pick a different minor. |
| Ecto SQL | 3.14.x | DB layer | Standard Postgres adapter for Phoenix; no ARM concerns (pure Elixir + Postgrex, no NIFs). |
| Postgrex | 1.0.0-rc.1 (or last stable 0.22.x) | Postgres driver | Prefer the last stable `0.22.x` over the `1.0.0-rc` for a production app unless you specifically need rc features — rc tags can still shift before final release. |
| PostgreSQL | 17 (via `pgvector/pgvector:pg17` image if self-hosting in a Kamal accessory) | Database | One DB for everything per project constraint. Use the `pgvector/pgvector` image (not vanilla `postgres`) so the extension is present from container boot — it publishes multi-platform (amd64+arm64) images, confirmed via Docker Hub layer listings for `pg17`, `pg17-trixie`, `pg17-bookworm` tags. |

### Deployment Stack (Items 1–2: Docker release + ARM)

| Technology | Version/Approach | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `mix phx.gen.release --docker` | Built into Phoenix 1.8 | Generates the production Dockerfile | This is the standard, framework-blessed path — don't hand-roll a Dockerfile from a blog post. It generates a multi-stage build: a `hexpm/elixir:<elixir>-erlang-<otp>-debian-<codename>-<date>` builder stage that compiles deps + assets + the release, and a slim `debian:<codename>-<date>-slim` runner stage that only contains the built release + runtime libs (openssl, libncurses, locales). |
| Runner base image | `debian:trixie-slim` (glibc), **not Alpine** | Final image OS | Two independent reasons converge here: (1) Phoenix's own generator avoids Alpine specifically because of musl-related DNS resolution issues in production; (2) EXLA's precompiled XLA binaries for ARM64 target `aarch64-linux-**gnu**` (glibc) — there is no musl/Alpine precompiled variant, so if Phase 2's embedding work ships in the same release, Alpine would force a from-source XLA build (Bazel + Clang 18, "usually takes a very long time" per the XLA README) on every image build. Debian slim avoids that entirely. |
| Buildx / native arm64 build | `docker buildx build --platform linux/arm64` on a native ARM builder (or the Hetzner box itself), not QEMU-emulated | Producing the deploy image | Cross-compiling Elixir/Erlang NIFs (bcrypt_elixir, EXLA, etc.) under QEMU emulation is slow and occasionally flaky. Prefer building natively: either build directly on an ARM CI runner (e.g. GitHub-hosted `ubuntu-24.04-arm` or a self-hosted ARM runner) or let Kamal build on the target Hetzner host itself (`builder: { arch: arm64 }` — the default in Kamal when you don't override `remote`). Since the whole deploy target is single-arch (CAX31 is ARM-only), there's no need for multi-arch manifests at all — just build for `linux/arm64` and stop. |
| Image size | Expect roughly 150-250MB post multi-stage (Elixir release + Debian slim + a handful of runtime `.so` libs) | — | ERTS is bundled inside the Mix release itself, so the runner image doesn't need Erlang/Elixir installed — this is *why* a plain Debian slim base still ends up smaller than trying to strip Alpine packages by hand. If Bumblebee/EXLA ships in the same release (Phase 2), expect the image to grow substantially (EXLA's XLA extension + a bundled ONNX/tokenizer model can each be 50-150MB) — this is a acceptable one-time cost, not a per-deploy cost, since Kamal only pulls layers that changed. |

### Deployment Stack (Item 2: Kamal)

| Technology | Version/Approach | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Kamal | 2.x (`kamal-deploy.org`) | Deploy orchestrator | Already the project's fixed choice. Kamal 2 replaced Traefik with **kamal-proxy**, a purpose-built Ruby reverse proxy that does instant traffic-cutover zero-downtime deploys and automatic Let's Encrypt TLS — exactly matching the constraint "kamal-proxy for TLS/reverse-proxy, do not layer Caddy on top." |
| Migrations on deploy | Custom Docker `ENTRYPOINT` script that runs `/app/bin/migrate` before `exec /app/bin/server` | Safe migration-on-deploy | Kamal has **no** Heroku-style `release_command` hook. The idiomatic Elixir/Kamal pattern (used across every Phoenix+Kamal guide found) is: intercept the entrypoint, and only when the container's command is `bin/server`, run `bin/migrate` first. Because Kamal's zero-downtime deploy only routes traffic to a new container **after** it passes its health check, a migration failure inside the entrypoint simply prevents the new container from ever becoming healthy — the old container keeps serving traffic and Kamal reports a failed deploy. This gives you migration-gated zero-downtime deploys for free, without a separate hook mechanism. Phoenix's `phx.gen.release` already generates the `bin/migrate` overlay script and a `Release.migrate/0` function using `Ecto.Migrator` directly (no `Mix` dependency) — use that, don't shell out to `mix ecto.migrate` in production (Mix isn't available in a release). |
| Secrets | `.kamal/secrets` (gitignored, dotenv-format, supports variable/command substitution) | Secrets handling | Kamal's built-in secrets file is the right default over plain env vars for anything sensitive (`SECRET_KEY_BASE`, `DATABASE_URL`, registry password, Gemini API key): `deploy.yml` declares which env vars are `clear` (inline, non-secret, e.g. `PHX_HOST`) vs `secret` (name only — the value is resolved from `.kamal/secrets` at deploy time and written to an env file on the host, never baked into the image or committed to git). For a solo-dev budget project, plain `.kamal/secrets` with values entered directly (no 1Password/Bitwarden integration) is sufficient — the command-substitution feature exists for scaling to a team, which this project explicitly is not. |
| Postgres hosting | Kamal **accessory** (not managed DB) running `pgvector/pgvector:pg17`, with a host-mounted volume (`/var/lib/postgresql/data`) | Database process | Matches "single Hetzner node, ~€15/mo" — a managed Postgres add-on would blow the budget. Accessories are Kamal's mechanism for long-running non-app containers (DB, Redis) on the same host; use the `pgvector/pgvector` image specifically instead of vanilla `postgres` so the extension is present without a manual `apt install postgresql-*-pgvector` step. Back this up via the project's existing nightly `pg_dump` → R2 plan — Kamal accessories do not include backup automation, that has to be a cron/Oban job. |
| kamal-proxy | Built into Kamal 2, `proxy: { ssl: true, host: pukllay.club }` | TLS termination + reverse proxy | Automatic Let's Encrypt cert issuance/renewal, holds requests during container swap for zero-downtime. No separate Caddy/nginx needed — confirms the project's constraint is directly supported, not a workaround. |

### AI/Search Stack (Items 3–6, Phase 2)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Bumblebee | 0.7.1 | Elixir ML inference wrapper (HF models) | The standard (only real option) for running HF-hosted embedding models directly in the BEAM without a Python sidecar — matches the project's "no separate service" architecture principle. |
| Nx / EXLA | 0.13.0 / 0.13.0 | Tensor ops + compiled backend for Bumblebee | **Must explicitly configure `Nx.default_backend(EXLA.Backend)`** (or set it in config). Without it, Bumblebee falls back to pure-Elixir tensor ops, which one Elixir Forum thread reported taking **over 60 seconds** for a single embedding vs sub-second with EXLA — this is the single most important non-obvious configuration step for this whole stack. |
| `xla` (EXLA's native dependency) | 0.10.0 | Precompiled XLA extension | **Verified directly against the `elixir-nx/xla` GitHub release assets**: `xla_extension-0.10.0-aarch64-linux-gnu-cpu.tar.gz` exists. This means EXLA CPU inference on ARM64 Linux uses a **precompiled binary** — no `XLA_BUILD=true` + Bazel/Clang from-source build is required on the Hetzner box or in CI. This directly de-risks the project's stated "spike the ARM embedding runtime first" plan for Phase 2: the runtime dependency itself is not the risk, only inference *speed* is (see Pitfalls/risk flag below). |
| Embedding model | `intfloat/multilingual-e5-small` (384-dim, 100 languages, 12 layers) — preferred over `paraphrase-multilingual-MiniLM-L12-v2` (118M params, 384-dim) | Spanish sentence embeddings | Both are standard small multilingual sentence-transformer models with Spanish support and are explicitly described as CPU-servable; e5-small is smaller (better CPU latency headroom) at comparable quality for retrieval-style tasks. Confirm the final pick during the Phase 2 spike with real latency numbers on the actual CAX31 (or an equivalent ARM box) — this is exactly the kind of decision the project has correctly deferred to a spike rather than locking in from research. |
| pgvector (Postgres extension) | via `pgvector/pgvector:pg17` image | Vector column type + ANN indexes | Standard vector extension for Postgres; multi-platform image confirmed (arm64 included). |
| `pgvector` (hex package) | 0.4.0 | Ecto/Postgrex vector type + query helpers | Supports `:vector`/`:halfvec`/`:bit`/`:sparsevec` Ecto types, HNSW/IVFFlat index creation via normal Ecto migrations, and — notably — ships a **hybrid search (tsvector + vector, Reciprocal Rank Fusion) example** in its own repo that combines Postgres full-text search with vector similarity, which is exactly the item-4 requirement. Use this as the starting implementation reference rather than building RRF from scratch. |
| Postgres full-text search | Native `tsvector`/`tsquery` + GIN index, `ts_rank`/`ts_rank_cd` | Keyword half of hybrid search | No extra package needed — this is built into Postgres. Spanish-language search needs the `spanish` text search configuration (`to_tsvector('spanish', ...)`), which ships with stock Postgres (no extra extension). |
| Oban | 2.23.0 | Postgres-backed async job queue | Already the project's fixed choice; current stable, actively maintained (last release within the last ~2 months of this research date). Free/OSS tier is sufficient at this scale — Oban Pro/Web are not required (Oban Web 2.12.6 exists as an optional dashboard but is a paid add-on beyond the free `oban` core; skip it for a solo-dev budget project and use `oban`'s own instrumentation/telemetry + logs instead). |
| InstructorLite | 1.2.0 | Structured output extraction from LLMs | Already the project's fixed choice. Ships adapters for OpenAI, Anthropic, **Gemini**, Llamacpp, and OpenAI-compatible providers. Response validation is Ecto-schema-based: define a schema with `use Ecto.Schema, use InstructorLite.Instruction`, pass it as `response_model`, and InstructorLite derives the JSON schema and validates the LLM's structured response against it — this fits naturally with an existing Ecto-based codebase (no separate JSON-schema-authoring step). |
| Gemini model (via InstructorLite's Gemini adapter) | `gemini-2.0-flash` or `gemini-2.5-flash` (verify current free-tier model name/limits at implementation time — Google changes free-tier model availability faster than most docs stay current) | Query parsing LLM | The Gemini adapter requires manually passing `json_schema` alongside `response_model` (InstructorLite's docs note Gemini needs this explicitly, unlike the OpenAI adapter) and an API key via `adapter_context: [api_key: ...]`. **Flag:** free-tier rate limits and available model names change; re-verify the exact model id and RPM/RPD limits against Google's current AI Studio pricing page during Phase 2 planning, not from this research (LOW confidence on any specific free-tier number as of this write-up). |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `req` | 0.6.3 | HTTP client | InstructorLite's default HTTP client; also good general-purpose choice for any other outbound HTTP (BGG API in later phases, R2 backup upload if not using `aws-cli`/rclone directly). |
| `finch` | 0.23.0 | HTTP connection pooling | Transitive dependency of `req`; no direct action needed, just don't fight it with a second HTTP client stack. |
| Tailwind + daisyUI | phx.new 1.8 defaults | UI | Already fixed by the project; no research needed beyond confirming it's still the `phx.new` default (it is, as of Phoenix 1.8). |

### Development Tools (Item 7: Quality Tooling + CI)

| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| Credo | 1.7.19 | Static analysis / style | Run with `--strict` as specified. Current stable. |
| Sobelow | 0.14.1 | Phoenix-specific security static analysis | Checks for XSS, SQL injection, insecure config, CSRF, etc. specific to Phoenix apps — complements Credo, which is style/complexity-focused, not security-focused. |
| `mix format --check-formatted` | Built into Elixir | Formatting gate | No install needed. |
| `mix test --warnings-as-errors` | Built into Elixir/ExUnit | Test gate that also fails on compiler warnings | Standard practice — catches unused-variable/deprecated-function drift before it becomes a real bug. |
| `erlef/setup-beam` GitHub Action | `@v1` (auto-resolves latest within v1) | CI toolchain setup | The standard, Elixir-team-maintained action for pinning Elixir+OTP versions in GitHub Actions — every current Elixir CI guide found uses this over manually installing Erlang. |

## `mix quality` Alias Pattern

- `sobelow --config` reads a `.sobelow-conf` file for allowlisting known-safe findings (e.g. a specific `Mix.env() != :prod` check) — create this file empty initially and only add exceptions when Sobelow flags a reviewed false positive, not preemptively.
- Order matters for fast local feedback: cheapest/fastest checks first (`format`, `credo`) before the slower `test` run, so a formatting typo fails in seconds, not after a 30s+ test suite run. `sobelow` before `test` is a judgment call either way; the ordering above front-loads all static checks before the dynamic test run.
- Do **not** add `dialyzer` to this same alias unless you're prepared for its first-run PLT build cost (~2-5 min) — if you want type-checking, run it as a separate CI job with its own PLT cache, not inline in the fast local `mix quality` loop.

## GitHub Actions CI Pattern

- Use plain `postgres:17` (not `pgvector/pgvector`) for CI **unless** Phase 2 tests exercise real vector columns — at that point switch the CI service image to `pgvector/pgvector:pg17` too, so `CREATE EXTENSION vector` succeeds in the test DB. Do this switch when Phase 2 lands, not in Phase 0.
- Cache key on `mix.lock` hash is the standard invalidation trigger — don't key on `mix.exs` alone, `mix.lock` is what actually pins resolved versions.
- `ubuntu-latest` (amd64) runners are fine for CI even though production is arm64 — nothing in this stack is architecture-sensitive at the *test* level (no NIF compilation differences that would produce different test behavior); only the *deploy image build* needs to target arm64.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|--------------------------|
| Bumblebee + EXLA (local CPU embeddings) | Remote embedding API (OpenAI, Voyage, Cohere) | If the Phase 2 spike shows CPU embedding latency/throughput on the CAX31 is unacceptable even after tuning (batch size, sequence length caps) — this is explicitly the fallback the project should be ready to reach for. Remote embeddings would violate the stated "never an LLM call on the request hot path" principle only if called synchronously; called via Oban async it's compatible with the architecture, just costs money per embedding and adds a network dependency. Treat this as the documented Plan B, not a first choice. |
| `pgvector/pgvector:pg17` accessory | Managed Postgres (Neon, Supabase, Crunchy Bridge) | If backup/ops burden of self-hosting Postgres on the CAX31 becomes the actual bottleneck later — but this contradicts the €15/mo budget constraint today, so not recommended now. |
| Debian slim runner image | Alpine runner image | Only if you deliberately drop EXLA/Bumblebee from the release entirely (e.g. embeddings moved to a remote API) — then Alpine's smaller footprint has no offsetting cost, since musl DNS issues are the only real objection and can be worked around. Not recommended here because the project's stated plan keeps local embeddings in-process. |
| Entrypoint-script migration gating | A separate `kamal deploy` pre-hook (`.kamal/hooks/pre-deploy`) that SSHs in and runs `mix ecto.migrate` | Kamal hooks run on the *deployer's* machine/CI runner, not inside the release container, and `mix` isn't available inside a release — so hooks would need a separate `mix ecto.migrate` invocation against the release, which is more moving parts than the single self-contained entrypoint approach. Prefer the entrypoint pattern. |
| `.kamal/secrets` plain file | 1Password/Bitwarden CLI integration via Kamal's command-substitution support | Once this becomes a team project or the number of secrets/environments grows — for a solo dev with one production destination, the added CLI/vault setup is unnecessary process overhead. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| Alpine-based Docker runner image (if Phase 2 embeddings ship) | No precompiled `aarch64` XLA binary targets musl; would force a slow from-source Bazel/Clang XLA build on every image rebuild, and Phoenix's own generator avoids Alpine already for DNS reasons | `debian:trixie-slim` (or whatever Debian codename `phx.gen.release --docker` currently generates) |
| `mix ecto.migrate` invoked directly against a Mix release in production | `Mix` is a build tool, not included in compiled OTP releases — this command will not exist/work at runtime | The generated `bin/migrate` overlay script, which wraps `Ecto.Migrator` directly (no Mix dependency) |
| Traefik or a hand-rolled Caddy container in front of Kamal | Redundant — kamal-proxy (Kamal 2's built-in reverse proxy) already does TLS + zero-downtime traffic cutover; the project's constraint explicitly forbids layering Caddy on top | kamal-proxy (default, nothing extra to configure beyond `proxy: { ssl: true, host: ... }` in `deploy.yml`) |
| Running Bumblebee/EXLA without setting `EXLA.Backend` as the Nx default backend | Silently falls back to pure-Elixir tensor math; one real-world report showed a single embedding going from >60s to sub-second purely by fixing this config | `Nx.default_backend(EXLA.Backend)` in `config/runtime.exs` (or wherever Bumblebee's serving is configured), plus tuned `compile: [batch_size:, sequence_length:]` options on the `Bumblebee.Text.text_embedding` serving for short Spanish search queries |
| Oban Pro/Web as a first-phase requirement | Paid add-ons; the free `oban` core package covers everything the project's stated use case (async embedding + LLM query parsing, off the request path) needs | Free `oban` package + its own telemetry/logging; revisit Oban Web only if a real operational need for a dashboard emerges |
| Postgrex `1.0.0-rc.1` in production | Release-candidate tag; can still change before the real 1.0.0 | Latest stable `0.22.x` line, which `mix phx.new` will pin by default unless overridden |

## Stack Patterns by Variant

- Fall back to a remote embedding API (still called async via Oban, never on the request path)
- This preserves every other architectural decision (pgvector, hybrid search, Oban) — only the embedding *source* changes, not the storage/search layer
- Switch the CI Postgres service image from `postgres:17` to `pgvector/pgvector:pg17` so `CREATE EXTENSION vector` works in CI, not just in the Kamal accessory
- `libcluster` + `libcluster_postgres` (using the shared Postgres DB as a node registry) is the documented pattern for Kamal+Phoenix clustering — noted here only so it's not rediscovered from scratch if a future milestone needs it; not relevant to the current single-node architecture

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|------------------|-------|
| Phoenix 1.8.9 | Elixir 1.15+ (project should use 1.19.x), Phoenix LiveView 1.2.x | `mix phx.new` pins compatible versions automatically — don't hand-override unless there's a specific reason. |
| EXLA 0.13.0 | `xla` 0.10.0, Nx 0.13.0 | These three are released in lockstep by the `elixir-nx` org; always bump together, never pin EXLA/Nx to mismatched minors. |
| `xla` 0.10.0 precompiled binary | `aarch64-linux-gnu` (glibc) only, not musl | This is the load-bearing compatibility fact for the ARM Docker base image decision — see "What NOT to Use." |
| `pgvector` hex package 0.4.0 | Postgres with the `pgvector` extension installed (any recent pgvector extension version; use `pgvector/pgvector:pg17` image) | The hex package is a thin Ecto/Postgrex type wrapper — the real version dependency is the *Postgres extension*, which the Docker image bundles. |
| Oban 2.23.0 | Postgres-backed (also supports SQLite3/MySQL, irrelevant here) | No special version pinning needed against Ecto/Postgrex beyond normal Hex dependency resolution. |
| InstructorLite 1.2.0 | Ecto (for `response_model` schemas), `req` (HTTP), `Jason` (only needed pre-Elixir-1.18, irrelevant here since we're on 1.19) | Gemini adapter specifically requires manually passing `json_schema` in addition to `response_model` — don't assume it's auto-derived the same way as the OpenAI adapter. |

## Sources

- `hex.pm` API (`/api/packages/<name>`) for every version number above — Phoenix, Phoenix LiveView, Ecto SQL, Postgrex, Oban, pgvector, InstructorLite, Bumblebee, EXLA, Nx, xla, Credo, Sobelow, Req, Finch, Oban Web — **HIGH confidence** (direct registry API, not a search result)
- `github.com/elixir-nx/xla` releases API (`/repos/elixir-nx/xla/releases/latest`) — confirmed `xla_extension-0.10.0-aarch64-linux-gnu-cpu.tar.gz` asset exists — **HIGH confidence** (direct GitHub API, the single most load-bearing fact in this document for de-risking Phase 2 on ARM)
- `hexdocs.pm/phoenix/releases.html` and `Mix.Tasks.Phx.Gen.Release` docs (via WebSearch) — Dockerfile generation behavior, Debian-not-Alpine rationale — MEDIUM confidence (cross-checked across search summary + generator behavior is well-documented framework behavior)
- `github.com/pgvector/pgvector-elixir` README (via WebFetch) — Ecto migration examples, HNSW/IVFFlat index syntax, hybrid search example location — MEDIUM confidence
- `github.com/martosaur/instructor_lite` README (via WebFetch) — adapter list, Gemini-specific `json_schema` requirement, Ecto-schema-based validation — MEDIUM confidence
- AppSignal Blog, "Deploying Phoenix Applications with Kamal" (2025-06-10) and "Advanced Strategies..." (2025-07-08) (via WebFetch) — Kamal builder/proxy config, entrypoint-based migration pattern, secrets clear-vs-secret split, accessory pattern — MEDIUM confidence (single blog source per specific claim, but pattern is consistent with Kamal's own docs structure)
- `kamal-deploy.org/docs/configuration/environment-variables/` (via WebSearch summary) — `.kamal/secrets` dotenv format, variable/command substitution, `KAMAL_REGISTRY_PASSWORD` — MEDIUM confidence
- Elixir Forum thread, "Bumblebee/Axon vs. Python: Performance for sentence embedding" (via WebFetch) — the >60s-without-EXLA-backend finding — MEDIUM confidence (single anecdotal forum report, but mechanism — pure-Elixir fallback tensor ops — is consistent with how Nx backends work)
- `elixir-lang.org` blog, "Elixir v1.19 released" (Oct 2025, via WebSearch) — Elixir 1.19/OTP 28.1+ pairing — MEDIUM confidence
- Docker Hub `pgvector/pgvector` tag listings (via WebSearch) — multi-platform (amd64+arm64) image confirmation — MEDIUM confidence
- Docker Hub `hexpm/elixir` tag/layer listings (via WebSearch) — multi-arch builder image confirmation — MEDIUM confidence
- Fly.io "Phoenix Files" — GitHub Actions for Elixir CI (via WebFetch) — CI workflow shape, `erlef/setup-beam`, caching key strategy — MEDIUM confidence

## Open Risk Flags for Roadmap

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
