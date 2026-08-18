# Technology Stack

**Analysis Date:** 2026-08-18

## Languages

**Primary:**
- Elixir 1.19.5 - Core application logic, Phoenix web framework
- HEEX - Server-rendered HTML templates for LiveView components (`lib/pukllay_club_web/components/`, `lib/pukllay_club_web/live/`)
- JavaScript - Minimal asset bundling via Esbuild; no heavy SPA framework
- CSS - Tailwind 4.3.0 with daisyUI 5.5.20 for styling

**Secondary:**
- Bash - Docker entrypoint and deployment scripts (`docker-entrypoint`, deployment workflows)
- SQL - Ecto migrations and raw queries via Postgrex

## Runtime

**Environment:**
- Erlang/OTP 28.5 - BEAM runtime, paired with Elixir 1.19.5
- Phoenix 1.8.9 - Web framework, handles routing, plugs, and request lifecycle

**Package Manager:**
- Mix 1.19.5 - Elixir's built-in package manager
  - Lockfile: `mix.lock` (present, 100+ dependencies resolved)
- npm/Node.js - For asset bundling (Tailwind, Esbuild) during build only, not runtime

## Frameworks

**Core:**
- Phoenix 1.8.9 - Web framework for routing, controllers, and plugs
- Phoenix LiveView 1.2.7 - Real-time interactive UI components without writing JavaScript (`lib/pukllay_club_web/live/`)

**Testing:**
- ExUnit - Elixir's built-in unit testing framework
- ExCoveralls 0.18.5 - Code coverage tracking with multiple output formats

**Build/Dev:**
- Esbuild 0.10.0 - JavaScript asset bundler
- Tailwind 0.5.1 - CSS framework compiler
- Phoenix CodeReloader - Hot module reloading in development
- Dialyxir 1.4.7 - Static type checking via Dialyzer (optional, in `quality.full` alias)

**Quality:**
- Credo 1.7.19 - Style and consistency linting with `--strict` mode
- Sobelow 0.14.1 - Phoenix-specific security static analysis
- Styler 1.12.2 - Idiomatic Elixir formatter plugin (integrated with `mix format`)
- mix_audit 2.1.5 - Dependency vulnerability scanning against elixir-security-advisories

## Key Dependencies

**Critical:**
- `postgrex` 0.22.3 - PostgreSQL driver for Ecto
- `ecto_sql` 3.14.0 - SQL adapter for Ecto ORM and query builder
- `phoenix_ecto` 4.7.0 - Integration between Phoenix and Ecto

**Infrastructure:**
- `ex_aws` 2.7.0 - AWS SDK for service integration (used for R2/S3)
- `ex_aws_s3` 2.5.9 - S3 client for Cloudflare R2 uploads
- `sentry` 13.3.0 - Error tracking and crash reporting integration
- `swoosh` 1.26.3 - Mail abstraction layer (Local adapter in dev, configurable for prod)

**Web/HTTP:**
- `bandit` 1.12.1 - HTTP server adapter for Phoenix (handles socket, TLS termination delegated to kamal-proxy)
- `req` 0.6.3 - Modern HTTP client for outbound requests
- `finch` 0.23.0 - Connection pooling HTTP client (transitive via `req`)
- `plug` 1.20.3 - Plug ecosystem for request/response middleware
- `websock_adapter` 0.6.0 - WebSocket support for LiveView

**Data Processing:**
- `sweet_xml` 0.7.5 - XML parsing (used by ex_aws for S3 responses)
- `nimble_csv` 1.3.0 - Streaming CSV parsing for game catalog imports
- `image` 0.72.0 - Image manipulation (vix/evision bindings) for catalog cover processing
- `jason` 1.4.5 - JSON encoding/decoding (Phoenix's default JSON library)

**Utilities:**
- `gettext` 1.0.2 - Internationalization framework (wired for Spanish support)
- `telemetry` 1.4.2 - Metrics and observability foundation
- `telemetry_metrics` 1.1.0 - Structured metrics collection
- `telemetry_poller` 1.3.0 - Periodic telemetry emission
- `dns_cluster` 0.2.0 - DNS-based node discovery (configured but not active in single-node deploy)

## Configuration

**Environment:**
- `config/config.exs` - Compile-time base configuration (Esbuild, Logger, Phoenix, Sentry, Tailwind)
- `config/dev.exs` - Development-specific config with Postgres credentials (`postgres:postgres@localhost:5432`)
- `config/test.exs` - Test environment configuration with test database setup
- `config/prod.exs` - Production base config (minimal, runtime overrides in `runtime.exs`)
- `config/runtime.exs` - Runtime configuration loaded at startup (env vars: `DATABASE_URL`, `SECRET_KEY_BASE`, `SENTRY_DSN`, `R2_PUBLIC_BASE_URL`)
- `config/dev.secret.exs` - Gitignored file for local dev secrets (BGG token, R2 credentials) — see `config/dev.secret.exs.example` for template
- `.kamal/secrets` - Gitignored deployment secrets file (env var references, not literal values)

**Build:**
- `Dockerfile` - Multi-stage Docker build (builder: Elixir 1.19.5-OTP 28.5, runner: Debian trixie-slim)
- `docker-entrypoint` - Runs `bin/migrate` before `bin/server` for zero-downtime migration gating
- `mix.exs` - Project definition, dependencies, compilation configuration, test coverage config (ExCoveralls)

## Platform Requirements

**Development:**
- Elixir 1.19.5 (via `.tool-versions` or manual installation)
- Erlang/OTP 28.5
- PostgreSQL 17 (local or via Docker; pgvector extension required for production, optional in dev)
- Node.js/npm (for Tailwind CLI and Esbuild during asset building)

**Production:**
- Deployment: Kamal 2.12.0 orchestrator (Docker-based release)
- Target host: GCP e2-micro (x86_64, 2 vCPU, 1 GB RAM + 2 GB swap)
- Container runtime: Docker with custom Kamal configuration
- Database container: `pgvector/pgvector:pg17` (includes PostgreSQL 17 + pgvector extension)
- Reverse proxy: kamal-proxy (built into Kamal 2) for TLS/HTTPS
- DNS: Google Cloud DNS for `pukllay.club` domain
- Backups: Cloudflare R2 (nightly `pg_dump` via GitHub Actions scheduled job)

## Architecture & Deployment Pattern

**Release Process:**
1. GitHub Actions CI runs `mix quality` (format, credo, sobelow, dialyzer, test) on every PR and push to main
2. On main push, `docker/build-push-action` builds native x86_64 image (no cross-compilation)
3. Image tagged with full git SHA, pushed to ghcr.io (GitHub Container Registry)
4. Kamal deploy job pulls image, runs migrations via entrypoint, zero-downtime traffic cutover via kamal-proxy

**Database:**
- PostgreSQL 17 running in Kamal accessory container on same host
- Ecto migrations run on every deploy via `bin/migrate` (wrapped in entrypoint)
- No TLS between app and db (accepted risk: same single-tenant host, unencrypted Docker bridge network)

**Image Storage:**
- Cloudflare R2 (S3-compatible) for game cover images and catalog assets
- Credentials: `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_CATALOG_BUCKET`, `R2_PUBLIC_BASE_URL`
- Managed via `ex_aws_s3` Elixir client in seed pipeline (`lib/pukllay_club/catalog/seed/r2_storage.ex`)

---

*Stack analysis: 2026-08-18*
