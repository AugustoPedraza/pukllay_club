# Codebase Structure

**Analysis Date:** 2026-08-18

## Directory Layout

```
pukllay_club/
├── .claude/                           # Claude Code project config
│   ├── CLAUDE.md                      # Project instructions (this file + tech stack research)
│   ├── skills/                        # Project-specific skills
│   │   ├── ui-design-system/
│   │   ├── ux-patterns/
│   │   └── ux-responsive/
│   └── worktrees/                     # Worktree tracking
├── .gsd/                              # GSD (Guided Software Development) state
├── .github/                           # GitHub configuration
│   └── workflows/                     # CI/CD pipeline definitions
├── .kamal/                            # Kamal deployment config
├── .planning/                         # Project planning artifacts
│   ├── WINDOWS.md                     # Research/documentation
│   ├── STATE.md                       # Current phase state
│   ├── config.json                    # Phase configuration
│   ├── codebase/                      # Codebase analysis documents (THIS LOCATION)
│   ├── phases/                        # Phase planning documents
│   └── research/                      # Research notes and caches
├── config/                            # Elixir/Phoenix configuration
│   ├── config.exs                     # Base config (loaded by all envs)
│   ├── dev.exs                        # Development env config
│   ├── dev.secret.exs                 # Development secrets (gitignored)
│   ├── dev.secret.exs.example         # Development secrets template
│   ├── test.exs                       # Test env config
│   ├── prod.exs                       # Production env config
│   ├── runtime.exs                    # Runtime config (respects env vars; runs in release)
│   └── deploy.yml                     # Kamal deployment manifest (not used by app)
├── lib/                               # Main application code
│   ├── pukllay_club.ex                # Root module (namespace)
│   ├── pukllay_club_web.ex            # Web setup (macros for use in controllers/views)
│   ├── pukllay_club/                  # Business logic contexts and domain
│   │   ├── application.ex             # OTP Application supervision tree
│   │   ├── catalog.ex                 # Main context: queries, facets, carousel rows
│   │   ├── repo.ex                    # Ecto repository (Postgres adapter)
│   │   ├── mailer.ex                  # Email configuration (Swoosh)
│   │   ├── release.ex                 # Release tasks (unused in this app)
│   │   └── catalog/                   # Catalog domain
│   │       ├── game.ex                # Game schema (Ecto schema + changesets)
│   │       ├── vocabulary.ex          # Lookup tables: mechanics, themes, weight bands, tags
│   │       └── seed/                  # Data ingestion pipeline (one-time seed)
│   │           ├── bgg_client.ex      # BoardGameGeek API client
│   │           ├── csv_import.ex      # CSV parsing (ludoteca.csv)
│   │           ├── image_pipeline.ex  # Image fetch/resize
│   │           ├── r2_storage.ex      # Cloudflare R2 uploader
│   │           ├── storage.ex         # Storage abstraction layer
│   │           ├── credentials.ex     # Credential fetching/redacting
│   │           ├── hashtag_normalizer.ex  # Weight band/tag resolution
│   │           └── report.ex          # Audit report accumulation
│   ├── pukllay_club_web/              # Web layer (HTTP, WebSocket, templates)
│   │   ├── endpoint.ex                # Phoenix Endpoint (HTTP entry point)
│   │   ├── router.ex                  # Request routing + pipelines
│   │   ├── telemetry.ex               # Metrics/observability setup
│   │   ├── gettext.ex                 # i18n backend
│   │   ├── csp.ex                     # Content Security Policy header
│   │   ├── controllers/               # Request handlers
│   │   │   ├── error_html.ex          # HTML error page renderer
│   │   │   ├── error_json.ex          # JSON error response
│   │   │   └── health_controller.ex   # GET /up health check
│   │   ├── components/                # Reusable UI components (Phoenix.Component)
│   │   │   ├── core_components.ex     # Base UI elements (buttons, inputs, etc.)
│   │   │   ├── game_card.ex           # Game card in grid/carousel
│   │   │   ├── game_chips.ex          # Weight badge, editorial tags, mechanics
│   │   │   ├── filter_drawer.ex       # Filter UI drawer
│   │   │   ├── carousel_row.ex        # Horizontal carousel of games
│   │   │   └── layouts/               # Page layouts
│   │   │       └── app.html.heex      # Main app layout
│   │   └── live/                      # LiveView pages
│   │       └── catalog_live/          # Catalog browsing
│   │           ├── index.ex           # Browse page (CATALOG-01/02/03/04/08)
│   │           └── show.ex            # Game detail page (CATALOG-05/06/07/08)
│   └── mix/                           # Mix task definitions
│       └── tasks/                     # Custom Mix tasks
│           └── catalog.seed.ex        # mix catalog.seed task
├── priv/                              # Private assets (not compiled)
│   ├── repo/                          # Database migrations and seeds
│   │   └── migrations/                # Ecto migrations
│   │       ├── 20260727154440_create_deploy_proof.exs    # Proof-of-life table
│   │       ├── 20260806234228_create_games.exs           # games table schema
│   │       └── 20260810172415_add_games_search_and_indexes.exs  # Full-text + indexes
│   ├── gettext/                       # Translation strings (empty; Spanish-only UI)
│   ├── plts/                          # Dialyzer PLT cache (generated)
│   └── static/                        # Pre-compiled static assets
│       ├── css/
│       ├── js/
│       ├── images/
│       └── fonts/
├── assets/                            # Frontend source code (compiled to priv/static)
│   ├── css/                           # Tailwind CSS
│   │   └── app.css                    # Main stylesheet (Tailwind imports)
│   ├── js/                            # JavaScript
│   │   └── app.js                     # Main JS (handles phx:mounted, cover fallback, etc.)
│   └── vendor/                        # Third-party JS/CSS
├── test/                              # Test suite
│   ├── test_helper.exs                # Test setup (database sandbox, factories)
│   ├── pukllay_club/                  # Business logic tests
│   │   ├── catalog_test.exs           # Catalog context tests
│   │   ├── catalog/
│   │   │   ├── vocabulary_test.exs    # Vocabulary lookup tests
│   │   │   └── seed/                  # Seed pipeline tests
│   │   │       ├── bgg_client_test.exs
│   │   │       ├── csv_import_test.exs
│   │   │       ├── hashtag_normalizer_test.exs
│   │   │       ├── image_pipeline_test.exs
│   │   │       ├── credentials_test.exs
│   │   │       ├── report_test.exs
│   │   │       └── (other seed tests)
│   └── pukllay_club_web/              # Web layer tests
│       ├── controllers/
│       │   ├── error_html_test.exs
│       │   ├── error_json_test.exs
│       │   └── health_controller_test.exs
│       ├── components/
│       │   ├── game_chips_test.exs
│       │   └── layouts_test.exs
│       └── live/
│           ├── catalog_live_test.exs  # Browse page LiveView tests
│           └── catalog_show_test.exs  # Detail page LiveView tests
├── docs/                              # Documentation
│   ├── (deployment guides, architecture diagrams, etc.)
├── rel/                               # Release configuration
│   └── overlays/                      # Release overlays (scripts, migrations)
├── _build/                            # Build output (generated)
├── deps/                              # Dependencies (generated)
├── mix.exs                            # Mix project definition
├── mix.lock                           # Dependency lock file
├── Dockerfile                         # Multi-stage production Docker image
├── docker-entrypoint                  # Container entry script (runs migrations)
├── .dockerignore                      # Docker build exclusions
├── .gitignore                         # Git exclusions
├── .credo.exs                         # Credo linting config
├── .formatter.exs                     # Elixir formatter config (includes Styler plugin)
├── .sobelow-conf                      # Sobelow security scan exemptions
├── .mcp.json                          # MCP (Model Context Protocol) config
├── AGENTS.md                          # Agent workflow conventions
├── README.md                          # Project README
└── mise.toml                          # Mise runtime version manager config
```

## Directory Purposes

**`lib/pukllay_club/`** — Business logic layer:
- Purpose: Domain logic, contexts, schemas, data access
- Contains: `Catalog` context (main query module), `Game` schema, `Vocabulary` lookups, seed pipeline
- Key files: `lib/pukllay_club/catalog.ex` (all read queries), `lib/pukllay_club/catalog/vocabulary.ex` (lookup tables)

**`lib/pukllay_club_web/`** — Web/UI layer:
- Purpose: HTTP handling, request routing, LiveView pages, UI components
- Contains: Controllers, LiveView pages, stateless components, layouts, telemetry
- Key files: `lib/pukllay_club_web/router.ex` (routes), `lib/pukllay_club_web/live/catalog_live/index.ex` (main browse page)

**`lib/pukllay_club/catalog/seed/`** — Data ingestion pipeline:
- Purpose: One-time or periodic catalog seeding from external sources
- Contains: CSV parser, BGG API client, image processor, R2 uploader, audit report
- Entry point: `mix catalog.seed` (via `lib/mix/tasks/catalog.seed.ex`)

**`config/`** — Application configuration:
- Purpose: Environment-specific settings (database, secrets, logging, third-party services)
- Files: `config.exs` (base), `dev.exs`, `test.exs`, `prod.exs`, `runtime.exs` (respects env vars at boot)
- Important: `dev.secret.exs` is gitignored; copy from `dev.secret.exs.example`

**`test/`** — Test suite:
- Purpose: Unit and integration tests for contexts, LiveViews, components
- Structure: Mirrors `lib/` structure; `*_test.exs` files co-located with their subjects

**`priv/repo/migrations/`** — Database schema:
- Purpose: Version-controlled schema changes
- Key files: `*_create_games.exs` (games table), `*_add_games_search_and_indexes.exs` (full-text search, indexes)

**`assets/`** — Frontend source:
- Purpose: CSS, JavaScript, static assets (compiled to `priv/static/` before deploy)
- Compiled by: esbuild (CSS), esbuild (JS)
- Watch/build commands in `mix.exs` asset watchers

## Key File Locations

**Entry Points:**
- `lib/pukllay_club/application.ex`: OTP Application supervision tree (starts Repo, Endpoint, etc.)
- `lib/pukllay_club_web/endpoint.ex`: HTTP entry point (plugs, static file serving)
- `lib/pukllay_club_web/router.ex`: Request routing definitions

**Main Query API:**
- `lib/pukllay_club/catalog.ex`: All public query functions (filter_games, get_game, list_carousel_rows, facet_options)

**Data Models:**
- `lib/pukllay_club/catalog/game.ex`: Game Ecto schema

**UI Entry Points (LiveView Pages):**
- `lib/pukllay_club_web/live/catalog_live/index.ex`: Browse/filter page (GET /)
- `lib/pukllay_club_web/live/catalog_live/show.ex`: Game detail page (GET /juegos/:id)

**Configuration:**
- `config/config.exs`: Base config (loaded by all environments)
- `config/runtime.exs`: Runtime config (reads env vars; runs inside release)
- `mix.exs`: Project definition and dependency list

**Database:**
- `priv/repo/migrations/`: Ecto migrations (version-controlled schema)

**Tests:**
- `test/test_helper.exs`: Test setup (database sandbox, global fixtures)
- `test/pukllay_club_web/live/catalog_live_test.exs`: Browse page tests
- `test/pukllay_club_web/live/catalog_show_test.exs`: Detail page tests

## Naming Conventions

**Files:**
- LiveView modules: `*_live.ex` or `*/index.ex`, `*/show.ex` (subdirectories per domain)
- Schema/context modules: `catalog/game.ex`, `catalog/vocabulary.ex` (singular + plural context name)
- Components: `game_card.ex`, `filter_drawer.ex` (descriptive camelCase)
- Tests: `*_test.exs` (always `_test.exs` suffix, co-located with subject)
- Migrations: `YYYYMMDDHHMMSS_description.exs` (Ecto auto-generated naming)

**Directories:**
- Contexts: `lib/pukllay_club/catalog/` (singular context names)
- Web layers: `lib/pukllay_club_web/live/`, `lib/pukllay_club_web/components/`, `lib/pukllay_club_web/controllers/`
- Tests mirror source: `test/pukllay_club/`, `test/pukllay_club_web/`

**Functions/Variables:**
- Ecto query helpers: `maybe_*` (e.g., `maybe_search`, `maybe_filter_mechanics`)
- State assignment: `:offset`, `:total`, `:loading`, `:load_error` (lowercase atoms)
- Handler functions: `handle_event`, `handle_params` (LiveView/controller conventions)

**Types/Modules:**
- PascalCase for all module names (Elixir convention)
- Aliases: `alias PukllayClub.Catalog`, `alias PukllayClubWeb.GameCard`

## Where to Add New Code

**New Filter/Search Feature:**
- Query logic: `lib/pukllay_club/catalog.ex` — add `maybe_filter_*` function, chain into `base_filtered_query/2`
- UI: `lib/pukllay_club_web/components/filter_drawer.ex` — add new pill/input for the facet
- Tests: `test/pukllay_club/catalog_test.exs` — add query test

**New Component:**
- Implementation: `lib/pukllay_club_web/components/{name}.ex` (stateless `Phoenix.Component`)
- Tests: `test/pukllay_club_web/components/{name}_test.exs`
- Import: Add to `lib/pukllay_club_web.ex` macro if globally used, or import directly in caller

**New Vocabulary/Lookup:**
- Add to: `lib/pukllay_club/catalog/vocabulary.ex` — extend `@mechanics`, `@themes`, `@weight_bands`, or `@editorial_tags`
- Update: `.planning/phases/01-catalog-v1/01-VOCABULARY.md` *first* (document is source of truth)
- Tests: `test/pukllay_club/catalog/vocabulary_test.exs` — verify new entry

**New Database Column/Migration:**
- Create: `mix ecto.gen.migration add_*_to_games` → edit `priv/repo/migrations/TIMESTAMP_*.exs`
- Update schema: `lib/pukllay_club/catalog/game.ex` — add `:field_name` field
- Update changeset: `lib/pukllay_club/catalog/game.ex` seed_changeset — add to cast list if needed
- Tests: `test/pukllay_club/catalog_test.exs` — test new field works in queries

**New LiveView Page:**
- Create: `lib/pukllay_club_web/live/{domain}_live/{view}.ex` (subdirectory + module)
- Register route: `lib/pukllay_club_web/router.ex` — add `live "/path", {DomainLive.View, :action}`
- Tests: `test/pukllay_club_web/live/{domain}_live_test.exs`
- Components: Create reusable parts in `lib/pukllay_club_web/components/`

**Shared Utilities:**
- Helpers: `lib/pukllay_club/` (not yet used; create context modules as needed)
- Components: `lib/pukllay_club_web/components/`

## Special Directories

**`priv/repo/migrations/`:**
- Purpose: Database schema version control
- Generated: Yes (via `mix ecto.gen.migration`)
- Committed: Yes (all `.exs` files in git)
- Immutable: Yes (do not edit old migrations; create new ones for changes)

**`deps/`:**
- Purpose: Elixir package dependencies (compiled/cached)
- Generated: Yes (via `mix deps.get`)
- Committed: No (add to `.gitignore` — lock file is `mix.lock`)

**`_build/`:**
- Purpose: Compiled output for current environment (dev, test, prod)
- Generated: Yes (via `mix` commands)
- Committed: No (add to `.gitignore`)

**`priv/plts/`:**
- Purpose: Dialyzer precompiled type information (PLT cache)
- Generated: Yes (via `mix dialyzer` or `mix quality`)
- Committed: No (PLTs are environment-specific; regenerate on each machine)

**`.planning/`:**
- Purpose: Project planning and research artifacts (phases, decisions, codebase analysis)
- Committed: Yes (part of decision record)
- Note: `.planning/research/.cache/` is gitignored (temporary HTTP caches)

**`config/`:**
- `config.exs`: Always loaded first (base config for all envs)
- `{dev,test,prod}.exs`: Environment-specific overrides
- `runtime.exs`: Loaded at startup in release (respects `ECTO_DATABASE_URL`, `SECRET_KEY_BASE`, etc. env vars)
- Secrets: `dev.secret.exs` is gitignored; use env vars in production (via `runtime.exs`)

---

*Structure analysis: 2026-08-18*
