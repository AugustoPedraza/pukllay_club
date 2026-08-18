# External Integrations

**Analysis Date:** 2026-08-18

## APIs & External Services

**Board Game Geek (BGG):**
- Service: BoardGameGeek XML API v2 for catalog data import
- What it's used for: One-time D-02 seed pipeline retrieves game metadata (mechanics, themes, weight, designers, publishers)
- SDK/Client: `req` HTTP client (modern Elixir HTTP library) with sweet_xml parsing
- Auth: Bearer token via `BGG_API_TOKEN` environment variable or `config/dev.secret.exs`
- Location: `lib/pukllay_club/catalog/seed/bgg_fetch.ex` (seed pipeline)

**Sentry:**
- Service: Sentry.io for error tracking and crash reporting
- What it's used for: Production crash reporting and error logs aggregation
- SDK/Client: `sentry` 13.3.0 Elixir package
- Auth: DSN via `SENTRY_DSN` environment variable (unset in dev/test disables reporting)
- Configuration: `config/config.exs` and `config/runtime.exs`, integrated with Logger via `Sentry.LoggerHandler`
- Features: Structured logging via telemetry, source code context enabled
- Location: `lib/pukllay_club/application.ex` (Sentry logger handler setup)

## Data Storage

**Databases:**

**PostgreSQL 17:**
- Type: Primary relational database
- Connection: Via `DATABASE_URL` env var (Ecto URI format: `ecto://USER:PASS@HOST/DATABASE`)
- Client: `postgrex` 0.22.3 driver + `ecto_sql` 3.14.0 ORM
- Location: Single Kamal accessory container (`pgvector/pgvector:pg17`) on production host
- Schema: Defined via Ecto migrations in `priv/repo/migrations/`
- Backup: Nightly `pg_dump` to Cloudflare R2 via `.github/workflows/backup.yml`
- Notes: pgvector extension included for future Phase 2 vector search (not actively used in Phase 1)

**File Storage:**

**Cloudflare R2 (S3-Compatible):**
- Service: Object storage for game cover images and catalog assets
- What it's used for: Persisting game cover images uploaded/processed during D-02 seed pipeline
- SDK/Client: `ex_aws` 2.7.0 + `ex_aws_s3` 2.5.9 (S3-compatible API)
- Auth: `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY` env vars (or `config/dev.secret.exs` in dev)
- Configuration:
  - `R2_ACCOUNT_ID` - Account identifier
  - `R2_CATALOG_BUCKET` - Bucket name (e.g., `pukllay-catalog`)
  - `R2_PUBLIC_BASE_URL` - Public HTTPS URL for accessing images via browser (e.g., `https://r2.example.com/pukllay-catalog/`)
- CSP Policy: `R2_PUBLIC_BASE_URL` origin is enforced in Content-Security-Policy header (`img-src` directive)
- Location: `lib/pukllay_club/catalog/seed/r2_storage.ex` (upload/fetch operations)
- Credentials resolution: `lib/pukllay_club/catalog/seed/credentials.ex` (env var priority, then `config/dev.secret.exs`)

**Caching:**
- None currently configured; Redis/Memcached not in use
- Phoenix LiveView provides real-time subscriptions via PubSub in-process (no external cache needed for Phase 1)

## Authentication & Identity

**Auth Provider:**
- None (not implemented in Phase 1)
- Future phases may add auth for user profiles/preferences

**Mailer:**
- Framework: Swoosh 1.26.3 (mail abstraction layer)
- Development: Local adapter stores emails in memory, viewable at `/dev/mailbox` (dev-only route)
- Production: Requires configuration in `config/prod.exs` (commented example for Mailgun shown)
- Suggested adapters: Mailgun, SendGrid, AWS SES, or SMTP
- API client: Swoosh can use `req` (configured) or Finch for HTTP calls to mail providers

## Monitoring & Observability

**Error Tracking:**
- Sentry 13.3.0 - Captures exceptions, crashes, and structured log entries
- Configuration: `SENTRY_DSN` env var must be set; empty/unset disables all reporting
- Logs: Sentry's structured Logs UI enabled via `enable_logs: true` in LoggerHandler config

**Logs:**
- Local: Stdout logging to console (dev) or container logs (production Docker)
- Format: Structured logger with request_id metadata
- Aggregation: Production logs viewable via Docker logs or Kamal CLI (`kamal app logs`)
- Telemetry: `telemetry` and `telemetry_metrics` packages provide instrumentation hooks (not actively consumed in Phase 1)

**Health Checks:**
- Kamal-proxy health check endpoint: `GET /up` (default Phoenix health check endpoint)
- Used by kamal-proxy to determine if container is ready for traffic (zero-downtime deploy gate)

## CI/CD & Deployment

**Hosting:**
- Platform: GCP Compute Engine (e2-micro instance, x86_64)
- Deployment: Kamal 2.12.0 orchestrator (Docker + Ruby gem)
- Load balancer: kamal-proxy (built into Kamal 2, not separate nginx/Caddy)
- Domain: pukllay.club (Google Cloud DNS)

**CI Pipeline:**
- Provider: GitHub Actions (free tier)
- Workflows:
  - `.github/workflows/ci.yml` - Runs `mix quality` on every PR and push
  - `.github/workflows/deploy.yml` - Quality gate + Docker build/push + Kamal deploy (main branch only)
  - `.github/workflows/backup.yml` - Nightly scheduled `pg_dump` to R2 (8 AM UTC)

**CI Configuration Details:**

**Quality Job:**
- Runs on: `ubuntu-latest` (x86_64)
- Service: PostgreSQL 17 container for test database
- Cache: Mix dependencies and build artifacts (keyed on `mix.lock`)
- Steps: `mix deps.get` → `mix quality` (format + credo + sobelow + test)

**Build Job:**
- Runs on: `ubuntu-latest` (native x86_64, matches production target)
- Docker registry: ghcr.io (GitHub Container Registry)
- Image tags: Full git SHA (40-char) for Kamal consistency, plus `latest` tag
- Labels: OCI metadata + `service=pukllay_club` (required by Kamal validation)
- No cross-compilation: Runner is x86_64, production target is x86_64

**Deploy Job:**
- Runs on: `ubuntu-latest` (orchestration only, doesn't execute on target)
- Kamal version: 2.12.0 (pinned in workflow)
- SSH: Via `webfactory/ssh-agent@v0.9.0` with `DEPLOY_SSH_KEY` secret
- Secrets: Written to `.kamal/secrets` file (gitignored) at deploy time
- Command: `kamal deploy --skip-push` (image already built/pushed by previous job)
- Migrations: Automatic via Docker entrypoint (no separate hook needed)

**Backup Job:**
- Trigger: Schedule (nightly at 8 AM UTC) or manual workflow dispatch
- SSH: Connects to `DEPLOY_HOST` as `deploy` user
- Procedure:
  1. Run `pg_dump` inside `db` container over SSH
  2. Gzip output in-pipeline
  3. Validate dump integrity with `gzip -t`
  4. Upload to R2 via `aws s3 cp` with S3-compatible endpoint
- Secrets: `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `POSTGRES_PASSWORD`, `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`
- Retention: No automated cleanup (responsibility of R2 lifecycle policies or manual cleanup)

## Environment Configuration

**Required Environment Variables (Production):**

- `DATABASE_URL` - Ecto URI for Postgres connection (e.g., `ecto://user:pass@host:5432/db`)
- `SECRET_KEY_BASE` - 64+ random characters for signing cookies/sessions (generate via `mix phx.gen.secret`)
- `PHX_HOST` - Public domain (e.g., `pukllay.club`)
- `R2_PUBLIC_BASE_URL` - Public HTTPS URL for image origin (e.g., `https://cdn.example.com/images/`)
- `SENTRY_DSN` - Full Sentry DSN for error reporting (optional; unset disables it)
- `POSTGRES_PASSWORD` - Password for Postgres user in Kamal accessory
- `KAMAL_REGISTRY_PASSWORD` - GitHub token for ghcr.io image pull (via GitHub Actions)

**Optional Environment Variables:**

- `PORT` - HTTP port (defaults to 4000, overridden by kamal-proxy which listens on 80/443)
- `ECTO_IPV6` - Set to `true` or `1` to enable IPv6 socket connections
- `POOL_SIZE` - Ecto connection pool size (defaults to 10)
- `DNS_CLUSTER_QUERY` - DNS name for node clustering (not used in single-node architecture)

**Secrets Location:**

- GitHub Actions: Repository secrets (visible in `.github/workflows/deploy.yml` and `.github/workflows/backup.yml`)
  - `SECRET_KEY_BASE`
  - `DATABASE_URL`
  - `SENTRY_DSN`
  - `POSTGRES_PASSWORD`
  - `R2_ACCESS_KEY_ID`
  - `R2_SECRET_ACCESS_KEY`
  - `R2_ENDPOINT`
  - `DEPLOY_SSH_KEY` (private SSH key for Kamal access)
  - `DEPLOY_HOST` (production server IP/hostname)

- Local Development: `config/dev.secret.exs` (gitignored)
  - `BGG_API_TOKEN`
  - `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_CATALOG_BUCKET`, `R2_PUBLIC_BASE_URL`

- Production Deployment: `.kamal/secrets` (gitignored, written fresh on each deploy)
  - `KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD`
  - `SECRET_KEY_BASE=$SECRET_KEY_BASE`
  - `DATABASE_URL=$DATABASE_URL`
  - `SENTRY_DSN=$SENTRY_DSN`
  - `POSTGRES_PASSWORD=$POSTGRES_PASSWORD`

## Webhooks & Callbacks

**Incoming:**
- None (no external services call the app)

**Outgoing:**
- Sentry error events (automatic, triggered by crash/exception)
- Cloudflare R2 uploads (S3 PUT requests via `ex_aws_s3`)

---

*Integration audit: 2026-08-18*
