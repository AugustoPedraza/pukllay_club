<!-- refreshed: 2026-08-18 -->
# Architecture

**Analysis Date:** 2026-08-18

## System Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│                  Web Layer (Phoenix LiveView)                    │
├───────────────────────┬─────────────────────┬──────────────────┤
│   Browse/Index Page   │  Game Detail Page   │  Error Handlers  │
│ `CatalogLive.Index`   │  `CatalogLive.Show` │  Controllers     │
│ (CATALOG-01-04, 08)   │  (CATALOG-05-08)    │  `/up` health    │
└───────────────┬───────┴─────────┬───────────┴────────┬─────────┘
                │                 │                    │
                └────────┬────────┴────────┬───────────┘
                         │                 │
                         ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│              Business Logic Layer (Contexts)                     │
│         `PukllayClub.Catalog` (query composition)                │
│     `PukllayClub.Catalog.Vocabulary` (lookups)                   │
│      `PukllayClub.Catalog.Game` (schema/validation)              │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│              Data Layer (Ecto + PostgreSQL)                      │
│   `PukllayClub.Repo` + `games` table with search vectors         │
│  Full-text search (tsvector), weight bands, array columns        │
└─────────────────────────────────────────────────────────────────┘
                       ▲
                       │
┌──────────────────────┴──────────────────────────────────────────┐
│        Seed/ETL Pipeline (One-time data ingestion)               │
├───────────┬──────────┬─────────────┬──────────┬──────────────────┤
│ CSV Parse │ BGG Enr. │ Image Fetch │ R2 Upload│ Hash Normalize   │
│ `CsvImport`│`BggClient`│`ImagePipeline`│`R2Storage`│`HashtagNorm.`  │
└────────────┴──────────┴─────────────┴──────────┴──────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| **CatalogLive.Index** | Browse page: render carousel, game grid, filters, search, sorting, pagination | `lib/pukllay_club_web/live/catalog_live/index.ex` |
| **CatalogLive.Show** | Detail page: render full game info, gallery, image selection | `lib/pukllay_club_web/live/catalog_live/show.ex` |
| **GameCard** | Stateless card component: render one game in browse grid | `lib/pukllay_club_web/components/game_card.ex` |
| **FilterDrawer** | UI component: filter facet pills and scalar inputs | `lib/pukllay_club_web/components/filter_drawer.ex` |
| **CarouselRow** | UI component: horizontal scrolling carousel of games | `lib/pukllay_club_web/components/carousel_row.ex` |
| **GameChips** | UI component: weight badge, editorial tags, mechanic chips | `lib/pukllay_club_web/components/game_chips.ex` |
| **Catalog** | Main context: all read queries (filter, search, sort, count, get) | `lib/pukllay_club/catalog.ex` |
| **Vocabulary** | Lookup tables: mechanic/theme/weight labels, editorial tags | `lib/pukllay_club/catalog/vocabulary.ex` |
| **Game** | Ecto schema: validates changeset for seed, never for web | `lib/pukllay_club/catalog/game.ex` |
| **CsvImport** | Seed stage 1: parse `ludoteca.csv` row-by-row | `lib/pukllay_club/catalog/seed/csv_import.ex` |
| **BggClient** | Seed stage 2: batch BGG API calls, resolve enrichments | `lib/pukllay_club/catalog/seed/bgg_client.ex` |
| **ImagePipeline** | Seed stage 3: fetch cover (Spanish-preferred) + gallery, resize | `lib/pukllay_club/catalog/seed/image_pipeline.ex` |
| **R2Storage** | Seed stage 4: upload images to Cloudflare R2 | `lib/pukllay_club/catalog/seed/r2_storage.ex` |
| **Report** | Seed audit: accumulate findings (unrecognized tags, missing BGG, conflicts) | `lib/pukllay_club/catalog/seed/report.ex` |
| **Repo** | Ecto repo: PostgreSQL connection, all SQL execution | `lib/pukllay_club/repo.ex` |
| **Endpoint** | Phoenix HTTP entry point: sockets, plugs, static files | `lib/pukllay_club_web/endpoint.ex` |
| **Router** | Request routing: pipelines (browser/api/health), scope handlers | `lib/pukllay_club_web/router.ex` |

## Pattern Overview

**Overall:** Context-based, single-context architecture (no umbrella project). Query composition via `Ecto.Query` with a single `base_filtered_query/2` pipeline in `Catalog.filter_games/1`. No N+1 queries; single `Repo.all/1` per request.

**Key Characteristics:**
- **Unauthenticated public browsing** — no auth plug, no user context (Phase 1 scope)
- **LiveView-first UI** — all state management (filters, pagination, streams) in `CatalogLive.Index` assigns
- **Query composition** — `maybe_*` predicate chain in `base_filtered_query/2` rather than branching logic
- **One-time seed** — manual `mix catalog.seed` run, not a continuous job; all data changes via this task
- **Component-driven templating** — stateless `Phoenix.Component` cards (not LiveComponents) for grid/carousel items
- **Error resilience** — filter query failures wrapped in `safe_filter_games/1` rescue to show error banner, not crash

## Layers

**Web/UI Layer:**
- Location: `lib/pukllay_club_web/`
- Purpose: HTTP request handling, WebSocket connections, template rendering, user interaction
- Contains: Router, Endpoint, LiveView pages, Components, Controllers (error, health)
- Depends on: `PukllayClub.Catalog`, Phoenix, Gettext (i18n)
- Used by: External HTTP clients

**Business Logic Layer:**
- Location: `lib/pukllay_club/catalog/`
- Purpose: Query composition, data validation, business rules (weight band lookup, vocabulary mapping)
- Contains: Main `Catalog` context, `Vocabulary` lookup module, `Game` schema
- Depends on: Ecto, `PukllayClub.Repo`
- Used by: Web layer (`CatalogLive.*`), Seed pipeline

**Data Layer:**
- Location: `lib/pukllay_club/catalog/game.ex`, `lib/pukllay_club/repo.ex`
- Purpose: Ecto schema definition and PostgreSQL connection management
- Contains: `Game` schema (16 fields + 3 array columns + 1 generated tsvector), `Repo` adapter
- Depends on: Ecto, Postgrex, PostgreSQL 17
- Used by: `Catalog` context

**Seed/ETL Layer:**
- Location: `lib/pukllay_club/catalog/seed/`, `lib/mix/tasks/catalog.seed.ex`
- Purpose: One-time catalog ingestion from CSV → BGG enrichment → image processing → database
- Contains: CSV parser, BGG API client, image resizer, R2 uploader, audit report generator, credential manager
- Depends on: `PukllayClub.Catalog`, Req (HTTP), Image (resize), AWS SDK (R2)
- Used by: `mix catalog.seed` task (manual invocation)

## Data Flow

### Primary Request Path: Browse Catalog (GET /)

1. **Router** (`router.ex:25`) receives `GET /` → routes to `CatalogLive.Index` (mount)
2. **Mount (disconnected)** (`index.ex:40`) — LiveView two-phase: render skeleton placeholders, no DB hit
3. **Mount (connected)** (`index.ex:38-71`) — WebSocket connects, `apply_filters/1` called with empty filters
4. **Catalog.filter_games** (`catalog.ex:78-87`) — composes query: `base_filtered_query` → `apply_sort` → `limit` → `Repo.all`
5. **Query Execution** — PostgreSQL executes `SELECT * FROM games WHERE ... ORDER BY ... LIMIT 24`
6. **LiveView Render** (`index.ex:223`) — updates assigns, renders grid of `GameCard` components
7. **User Action** — phx-change/phx-click events trigger `handle_event` callbacks
8. **Re-filter** — `apply_filters/1` re-runs `Catalog.filter_games`, `Catalog.count_games`, updates stream

### Secondary Request Path: Game Detail (GET /juegos/:id)

1. **Router** (`router.ex:26`) receives `GET /juegos/123` → routes to `CatalogLive.Show` with id param
2. **Mount** (`show.ex:26-35`) — `Catalog.get_game!(id)` fetches via `Repo.get!` (raises 404 if not found)
3. **Assign Vocabulary** — `Vocabulary.covered_mechanics`, `Vocabulary.covered_themes` transform raw BGG terms to Spanish labels
4. **Render Detail** (`show.ex:48`) — displays cover, gallery, chips, metadata fields
5. **Image Selection** (`show.ex:39-45`) — `handle_event("select-image")` validates URL is in game's gallery, updates `selected_image` assign

### Seed Flow: CSV → Database (mix catalog.seed)

1. **CSV Parse** (`csv_import.ex`) — streams `ludoteca.csv` row-by-row
2. **Weight Classification** (`catalog.seed.ex:97`) — resolves weight band from cell hashtags (#CreaConexiones, etc.)
3. **BGG Enrichment** (`bgg_client.ex`) — batches 20 rows, calls BGG XML API with inter-batch delay (1.5s), extracts mechanics/themes/designers/publishers
4. **Image Pipeline** (`image_pipeline.ex`) — fetches cover (Spanish-preferred) + gallery images, resizes thumbnails
5. **R2 Upload** (`r2_storage.ex`) — uploads resized images to Cloudflare R2 bucket
6. **Database Upsert** (`catalog.ex:53-66`) — `Catalog.upsert_game!` via `ON CONFLICT DO UPDATE` on `:csv_row` unique index
7. **Report** (`report.ex`) — accumulates findings (unrecognized hashtags, missing BGG, conflicts) and writes audit report

**State Management:**
- **Browse page**: Filter state (`:q`, `:mechanics`, `:themes`, `:weight_bands`, `:tags`, `:players`, `:max_playtime`, `:min_age`, `:sort`, `:offset`) lives in `CatalogLive.Index` socket assigns
- **Detail page**: Image state (`:selected_image`) lives in `CatalogLive.Show` socket assigns
- **Seed pipeline**: Report accumulator (`Report` map) passed through the pipeline; no intermediate state persisted

## Key Abstractions

**Query Composition (`base_filtered_query/2`):**
- Purpose: One pipeline for filtering, searching, faceting, sorting without branching logic
- Pattern: Chain of `maybe_*` predicates, each returning early if condition is nil/empty
- Location: `lib/pukllay_club/catalog.ex:187-197`
- Example: `query |> maybe_search(q) |> maybe_filter_mechanics(mech) |> ... |> Repo.all`
- Security: Every user-supplied value pinned via `^` in Ecto fragments; no string interpolation

**Vocabulary Mapping (`Vocabulary.covered_*`):**
- Purpose: Transform raw BGG mechanic/theme strings to curated Spanish labels
- Pattern: Lookup in hardcoded `@mechanics`/`@themes` maps; return Spanish label or nil
- Location: `lib/pukllay_club/catalog/vocabulary.ex`
- Behavior: Uncovered terms silently dropped (not displayed, not filterable)

**Stream-Based Rendering (`phx-update="stream"`):**
- Purpose: Efficient incremental DOM updates for game grid
- Pattern: `handle_event("load-more")` appends new games to `:games` stream at `-1` position
- Location: `lib/pukllay_club_web/live/catalog_live/index.ex:126-139` (event) + template (render)
- Benefit: Only new cards are added to DOM; old cards untouched

**Carousel Row Composition:**
- Purpose: Display 8 curated rows (Destacados, hashtags, weight bands, Recently Added)
- Pattern: Hardcoded row definitions in `list_carousel_rows/0`; each row is `%{key:, title:, games:}`
- Location: `lib/pukllay_club/catalog.ex:138-159`
- Design: No configuration table or admin UI; deferred to Phase 4

**Two-Phase LiveView Mount:**
- Purpose: Render skeleton instantly (disconnected), then replace with real data (connected)
- Pattern: Check `connected?(socket)` in mount; assign `loading: true` if disconnected
- Location: `lib/pukllay_club_web/live/catalog_live/index.ex:40, 60-69`
- UI: Grid shows skeleton cards on first render; re-renders real cards after WebSocket connects

## Entry Points

**Web:**
- `GET /` → `CatalogLive.Index` — browse/filter the catalog
- `GET /juegos/:id` → `CatalogLive.Show` — view game detail
- `GET /up` → `HealthController.up` — Kamal deployment health check
- `POST /dev/dashboard` (dev only) — LiveDashboard metrics

**Command-Line:**
- `mix catalog.seed` — seed catalog from CSV (see moduledoc in `lib/mix/tasks/catalog.seed.ex` for options)

**Application Boot:**
- `PukllayClub.Application.start/2` — starts supervision tree: Telemetry, Repo, DNSCluster, PubSub, Endpoint

## Architectural Constraints

- **Single context**: One `Catalog` context, never refactored into umbrella until scaling demands justify it
- **Stateless components**: Game cards are `Phoenix.Component` (not `LiveComponent`); state lives only in parent LiveView
- **No N+1 queries**: Every page load is exactly one `Repo.all/1` or `Repo.get!/1` call per logical operation
- **No streaming**: Response bodies are static HTML + WebSocket after mount; no SSE or chunked responses
- **One database**: Single PostgreSQL 17 instance for all data; no read replicas yet
- **No auth yet**: All routes public; Phase 2 (query parsing) defers auth to that phase
- **Global state**: Two singletons via Sentry LoggerHandler (crash reporting) and DNSCluster config; no mutable module-level state
- **Error resilience**: Filter queries catch all errors; empty result set + error banner shown, never crashes the page
- **Immutable data**: Once a game is seeded, only re-seeding the entire catalog updates it (no edit endpoints)

## Anti-Patterns

### Direct Repo.get/Repo.all in Controllers

**What happens:** Some teams call `Repo` directly in LiveView/Controllers instead of via `Catalog` context.

**Why it's wrong:** Breaks single-source-of-truth for queries; if multiple callers need the same query, it gets duplicated; refactoring becomes dangerous (must find all callers).

**Do this instead:** Route all reads through `lib/pukllay_club/catalog.ex` functions. The context is the public API; direct Repo calls are only acceptable in the context module itself.

### Unchecked Image URL in Detail Page

**What happens:** Echoing a user-supplied `url` parameter into an `<img src>` without validation.

**Why it's wrong:** Open redirect / content injection vulnerability; a crafted URL could load an arbitrary image or trigger unexpected behavior.

**Do this instead:** Validate URL against the game's own gallery list: `if url in gallery_thumbnails(@game) do ... end` (see `show.ex:40`).

## Error Handling

**Strategy:** Pessimistic — catch errors early, show user-friendly messages, never crash the page.

**Patterns:**
- **Query errors** → `safe_filter_games/1` rescue wraps `Catalog.filter_games` in try/rescue; returns `:error` on any Exception; LiveView shows error banner (`index.ex:286`)
- **Missing game** → `Catalog.get_game!` raises `Ecto.NoResultsError` (implements `Plug.Exception`); Phoenix renders generated 404 page
- **Seed task errors** → Accumulate non-fatal findings in `Report`; write audit file regardless; fatal errors (e.g., R2 permission) halt the task and bubble to caller

## Cross-Cutting Concerns

**Logging:** 
- Method: Sentry crash reporting (Phase 0 D-18) attached in `Application.start/2` via `LoggerHandler`
- Behavior: Crashes are forwarded to Sentry; logs are also printed to stdout (Elixir default Logger)
- Configuration: `config/runtime.exs` reads `SENTRY_DSN` env var

**Validation:**
- Schema level: `Game.seed_changeset/2` validates `:name`, `:csv_row` required; `:enrichment_status` in allowed list
- Query level: `Catalog.normalize_sort/1`, `Catalog.maybe_filter_*/2` accept any input but normalize/ignore invalid values
- UI level: `CatalogLive.Index` parses inputs via `parse_int/1`, `parse_sort/1` before passing to `Catalog`

**Authentication:**
- Current: None (Phase 1 scope is public browse only)
- Future: Phase 2+ will add auth for query parsing + admin features

**Internationalization (i18n):**
- Tool: Gettext (Phoenix default)
- Spanish copy: All user-facing strings are Spanish-only; no English UI yet
- Configuration: `lib/pukllay_club_web/gettext.ex` defines backend

---

*Architecture analysis: 2026-08-18*
