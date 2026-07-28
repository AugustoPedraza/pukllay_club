# Phase 1: Catalog v1 - Research

**Researched:** 2026-07-28
**Domain:** Board-game catalog browse/filter/search UX on Phoenix LiveView + Postgres, plus a
one-time BGG-enrichment/image-pipeline seed script
**Confidence:** MEDIUM (stack-level facts are HIGH via direct hex.pm registry checks; the BGG API
authentication finding is MEDIUM/cross-checked web sources; exact per-field BGG XML response shape
is LOW/training-knowledge since BGG's own docs pages returned bot-challenge 403s during this
research session and could not be fetched directly)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** The ~400-game dataset combines the club's Excel file (titles, BGG IDs — one column per
  game, no fuzzy matching needed — and the 6 editorial hashtags) with BGG XML API enrichment
  (weight, mechanics, categories, min age) keyed off the BGG ID. User hands over the Excel file
  before/during planning.
- **D-02:** The BGG-enrichment + image-resize + R2-upload pipeline is a **one-time `mix` task, run
  manually** — not an Oban job. Reversible (dev-time script, re-runnable).
- **D-03:** Cover/gallery images downloaded from BGG by the seed task, resized to **two variants**
  (small thumbnail, larger detail), uploaded to **Cloudflare R2**. App serves R2 URLs directly — no
  BGG hotlinking at runtime, no local-disk storage. Costly to reverse (re-run pipeline + update
  every stored URL).
- **D-04:** Each game gets a **small image gallery** (cover/portrait + a couple of table-setup/
  component photos) from BGG's gallery for that game. Only **cover art** must match the club's
  owned language edition (Spanish preferred; some games owned in English/German); gallery photos are
  best-effort, not guaranteed language-matched. Excel file does not track owned language edition —
  seed task defaults to Spanish box art where available, falls back otherwise, flags exceptions for
  manual review rather than silently guessing.
- **D-05:** Weight (CATALOG-05) maps to **3 bands** using the club's existing hashtags (already
  applied per-game in Excel, not derived): `#DescubreElHobby` (beginner), `#IngenioEstratega`
  (moderate), `#NivelExperto` (expert). Excel has only the hashtag label, not explanatory copy —
  Claude drafts the one-line plain-Spanish descriptive copy per band during planning, for user
  review.
- **D-06:** A **separate set of 3 editorial hashtags** (CATALOG-07, not weight-related), also
  already applied per-game in Excel: `#CreaConexiones` (simple/family-friendly), `#EquipoGanador`
  (cooperative), `#DuelosMemorables` (2-player only). Treat like weight hashtags — no derivation
  needed. This 6-hashtag list (3 weight + 3 editorial) is the full/exhaustive Phase 1 vocabulary.
- **D-07:** CATALOG-06's mechanic/theme chip glossary (BGG raw mechanics/categories → plain
  Spanish) is separate from the 6 hashtags and does not exist yet. Claude drafts a curated ~15-25
  term glossary during planning, derived from actual seeded-game BGG mechanics/categories, for user
  review before locking in.
- **D-08:** Home/browse page = **themed carousels + a full filterable grid** (not a single flat
  grid).
- **D-09:** Phase 1 ships a **fixed, hardcoded set of carousel rows**: Club Favorite/
  Beginner-Friendly, one row per editorial hashtag (the 6 from D-05/D-06), and Recently Added.
  Reversible (hardcoded query changes are cheap).
- **D-10 (forward note only, out of scope for Phase 1):** User wants a fully dynamic/admin-
  configurable carousel system eventually — fits Phase 4's admin dashboard. Award-winner data is
  not in the Excel file and BGG's award data is inconsistent — do not source it in Phase 1.
- **D-11:** Superseded — see 01-UI-SPEC.md: the brand identity PDF ("Manual de Identidad Visual"),
  not the originally-planned Google Stitch export, is the approved visual source of truth.
- **D-12:** Filtering is **live-updating** — results update immediately via LiveView push as filters
  change, no submit/"Apply" button.
- **D-13:** Filters live in a **slide-over/drawer panel** triggered by a button (mobile-first), not
  a persistent sidebar.
- **D-14:** Mechanic/theme facets (`text[]` + GIN) use **tag pills with toggle multi-select**;
  selecting multiple tags within the facet uses **OR logic** (matches ANY selected tag).
- **D-15:** Keyword search (title/designer/publisher via tsvector) is **combined with filtering** in
  the same experience — one search box narrows results while respecting active filters.

### Claude's Discretion

- Exact one-line plain-Spanish descriptive copy for the 3 weight bands (D-05) — draft during
  planning, present for user review.
- The ~15-25 term mechanic/theme glossary (D-07) — derive from actual seeded data, present for user
  review.
- Image resize dimensions/format specifics for the two variants (D-03) — pick reasonable defaults;
  can be revisited once real card/detail sizing needs are known (see UI-SPEC's spacing/typography
  scale for sizing hints).

### Deferred Ideas (OUT OF SCOPE)

- **Dynamic/admin-configurable carousel system** — admin-defined new carousel rows without a code
  change. Natural fit for Phase 4 (Club Ops/admin dashboard), not Phase 1's fully-public no-auth
  scope. See D-10.
- **Spiel des Jahres/award-winner data sourcing** — not in the Excel file, BGG's award data is
  inconsistent to query reliably. Revisit only if/when the dynamic carousel system is built.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CATALOG-01 | Browse ~400-game catalog, cover images, carousels/cards, LiveView streams | `stream/3` for the grid + one `stream` per carousel row; "Cargar más" load-more pattern (see Code Examples); no account required (public LiveView routes) |
| CATALOG-02 | Filter by player count, playtime, category/mechanic/theme (`text[]`+GIN), min age | Scalar `WHERE` for player count/playtime/min age; `&&` array-overlap on `mechanics`/`themes` GIN-indexed columns (Architecture Patterns) |
| CATALOG-03 | Keyword search (title, designer, publisher) via tsvector | Postgres native `tsvector`/`to_tsvector('spanish', ...)` + GIN index, combined with filter `WHERE` clauses in one Ecto query (Code Examples) |
| CATALOG-04 | Sort by playtime, complexity, or other scalar fields | Plain `ORDER BY` on indexed scalar columns — same query, no new infra |
| CATALOG-05 | Plain-Spanish weight-band + one-line descriptor instead of bare number | D-05 hashtag-to-band mapping; `weight_band` column populated from Excel hashtag, not derived from BGG's raw `averageweight` (see Common Pitfalls: don't re-derive bands from the float) |
| CATALOG-06 | Plain-Spanish mechanic/theme chips from curated vocabulary | D-07 glossary drafted from real seeded BGG `boardgamemechanic`/`boardgamecategory` link values (see BGG XML API research below) |
| CATALOG-07 | Club's editorial curation tags carried over from Excel | D-06 hashtags ingested verbatim as `text[]` alongside weight-band hashtag |
| CATALOG-08 | Catalog fully public, no account required | No `phx.gen.auth` dependency in Phase 1; router pipeline has no auth plug on catalog routes |
| CATALOG-09 | Club's own resized images, not hotlinked | D-03/D-04 seed pipeline: download from BGG once, resize via Vix/`image`, upload to R2, store R2 URLs only |
</phase_requirements>

## Summary

Phase 1 has two genuinely new technical surfaces beyond what `.planning/research/{STACK,ARCHITECTURE,
PITFALLS}.md` already covered at the project level: (1) a one-time, manually-run `mix` task that
enriches the club's Excel-exported ~400-game list against the BGG XML API and produces two resized,
R2-hosted image variants per game, and (2) the first real "hybrid keyword+facet" Ecto query in the
codebase, combining Spanish `tsvector` full-text rank, `text[]`+GIN array-overlap facet filtering,
and scalar range/sort filters, rendered via LiveView Streams with a "Cargar más" load-more button
rather than infinite scroll. Both are well-trodden Elixir patterns with mature, actively-maintained
libraries — the standard stack below (`sweet_xml`, `vix`/`image`, `ex_aws`+`ex_aws_s3`) resolves the
"no dominant XML library" and "which image library" questions the orchestrator flagged, all verified
directly against the hex.pm registry (HIGH confidence on versions/maintenance status).

The one finding that materially changes how Phase 1 planning must proceed: **BoardGameGeek's XML
API now requires application registration and a Bearer-token `Authorization` header for all
programmatic access** (enforced since July 2, 2025 per community reports; confirmed live during
this research session — an unauthenticated `curl` to `/xmlapi2/thing` returned `HTTP 401` with
`WWW-Authenticate: Bearer realm="xml api"`). D-01/D-02 were scoped assuming free/anonymous BGG
access, which is no longer true. The user (or Claude, if delegated) must register an application at
`boardgamegeek.com/applications/create` and obtain a token **before** the seed `mix` task can run —
this is a blocking prerequisite the plan must surface as an explicit early checkpoint, not an
implementation detail to discover mid-build.

**Primary recommendation:** Convert the Excel file to CSV once (manual step, zero new dependency)
and parse with the already-transitively-available `NimbleCSV`; use `sweet_xml` for BGG XML parsing
(ergonomic XPath sigils, and BGG's per-game responses are small — its memory overhead vs. `saxy`
only matters on multi-MB documents, not here); use the `image` package (high-level Vix wrapper) for
the two resize variants; use `ex_aws`+`ex_aws_s3` configured against R2's S3-compatible endpoint for
upload; register a BGG application and obtain an API token as the first concrete Phase 1 task, before
writing any enrichment code.

## Architectural Responsibility Map

Phoenix LiveView collapses the typical browser/API split: LiveView modules are server-rendered
("Frontend Server" tier) but call plain Elixir context modules directly in-process (no separate
network-bound "API" tier exists for Phase 1 — that collapse is a documented project-level
architecture decision, not new to this phase).

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Carousel rows + full grid rendering, live filter/search updates | Frontend Server (LiveView, `stream/3`) | Backend (`Catalog` context Ecto queries) | LiveView owns markup + `handle_event`; all query logic lives in the `Catalog` context per the project's context-per-phase pattern |
| Filter/sort/search query execution (tsvector rank, GIN overlap, scalar `WHERE`/`ORDER BY`) | Backend (`Catalog` context) | Database | One composed Ecto query; well under 50ms at ~400 rows, no Oban needed (matches ARCHITECTURE.md's "Phase 1 stays synchronous" pattern) |
| Plain-Spanish vocabulary (weight bands, 6 hashtags, mechanic/theme glossary) | Database (seeded `text[]`/enum columns) | Backend (lookup/translation helpers) | Static, seed-time data — no runtime derivation |
| Cover/gallery image serving | CDN/Static (Cloudflare R2, optionally behind a custom domain) | — | Browser fetches R2 URLs directly; the Phoenix app never proxies image bytes (D-03) |
| BGG enrichment + image resize + R2 upload pipeline | Backend (one-time `mix` task) | External services (BGG API, R2) | Explicitly NOT a web-request-serving component; runs on a dev machine or CI, not the 1GB-RAM production box (D-02) |
| Game detail page (full mechanic list, gallery, designer/publisher) | Frontend Server (LiveView) | Backend (`Catalog` context) | Same tier split as browse; just a different `Catalog` read function |

## Standard Stack

### Core (already fixed by the project, no change this phase)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.9 | Web framework | Existing `mix.exs` pin, confirmed via `mix.exs` read this session |
| Phoenix LiveView | ~> 1.2.0 (currently 1.2.7 per hexdocs) | Real-time UI, Streams | Existing pin; `stream/3` is the required rendering primitive for CATALOG-01 |
| Ecto SQL | ~> 3.13 | DB layer | Existing pin |
| Postgrex | existing (`>= 0.0.0`, resolves to a recent stable) | Postgres driver | Existing pin |
| PostgreSQL | 17 via `pgvector/pgvector:pg17` accessory | Database | Already running from Phase 0 (bound to `127.0.0.1`); Phase 1 doesn't need `vector` yet but the image already has it |
| daisyUI | v5.5.20 (vendored via `github: "saadeghi/daisyui"`, `sparse: "packages/bundle"`) | UI components | Existing `mix.exs` dependency, confirmed this session; approved 01-UI-SPEC.md is the styling source of truth |
| Heroicons | v2.2.0 | Icons | Existing dependency |
| `req` | 0.6.3 (mix.lock) / 0.7.0 latest on hex.pm [VERIFIED: hex.pm registry] | HTTP client | Already a dependency (InstructorLite's default per project stack doc); reused here for BGG XML fetch + image download |

### New for Phase 1

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `sweet_xml` | 0.7.5 [VERIFIED: hex.pm registry, published 2025-01-07] | Parse BGG's `/xmlapi2/thing` XML responses | XPath-sigil ergonomics (`~x`) fit BGG's nested `<item><link type="boardgamemechanic">` shape well; per-game responses are small (single-digit KB), so its higher memory use vs. `saxy` on large documents is irrelevant at this data size [CITED: AppSignal "Faster XML Parsing with Elixir" blog, cross-referenced against Saxy's own README] |
| `image` | 0.72.0 [VERIFIED: hex.pm registry, published 2026-07-21] | High-level image resize (2 variants) | Idiomatic wrapper (`Image.thumbnail/2`) around Vix/libvips; avoids hand-rolling `Vix.Vips.Operation` calls for a simple two-size resize job |
| `vix` | 0.40.0 [VERIFIED: hex.pm registry] | libvips NIF (transitive dep of `image`) | Ships precompiled binaries for Linux — no `apt-get install libvips`/ImageMagick needed on the machine running the seed task (dev laptop or GitHub Actions runner), unlike Mogrify which shells out to the ImageMagick CLI |
| `ex_aws` | 2.7.0 [VERIFIED: hex.pm registry] | S3-compatible client core | 70M+ all-time downloads, actively maintained; project's `swoosh` dependency already lists `ex_aws` as an optional peer, so it's a known-compatible addition |
| `ex_aws_s3` | 2.5.9 [VERIFIED: hex.pm registry] | S3 `put_object`/bucket operations | Paired release with `ex_aws`; used for R2 upload (R2 is S3-API-compatible) |
| `nimble_csv` | 1.3.0 [VERIFIED: hex.pm registry] | Parse the club's game-list export as CSV | Already resolvable as an optional transitive dep of `req`; add directly rather than rely on the transitive resolution. See Common Pitfalls re: converting the Excel file to CSV first. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `sweet_xml` | `saxy` | Choose `saxy` only if BGG response sizes turn out much larger than expected (e.g. if `stats=1` + full history bloats responses) or if streaming becomes necessary; for ~400 small per-game XML docs this is unlikely to matter |
| `image`/`vix` | `Mogrify` (ImageMagick CLI wrapper) | Mogrify is simpler to read for one-off scripts but requires ImageMagick installed on whatever machine runs the seed task and is measurably slower (community-reported ~4-5x for comparable resize operations); acceptable only if Vix's precompiled binaries fail to install in a given CI/dev environment |
| `ex_aws`+`ex_aws_s3` | Raw `req`-based multipart PUT with manual AWS SigV4 signing (`aws_signature` package) | Only needed if going the *presigned-URL-from-browser* upload route (relevant to future direct-upload features, not this phase); the seed task uploads server-side, so `ex_aws_s3`'s built-in signing is simpler and battle-tested |
| CSV import via `NimbleCSV` | `umya_spreadsheet_ex` (read `.xlsx` directly, no manual conversion) | Avoids one manual "export to CSV" step, but see Package Legitimacy Audit — this package has very low adoption (few downloads, single release as of this research) that doesn't yet meet the bar for an unattended dependency in a data-import path; only use if the user is unwilling to do a one-time CSV export |

**Installation:**
```bash
mix deps.get
# add to mix.exs deps():
# {:sweet_xml, "~> 0.7.5"}
# {:image, "~> 0.72.0"}
# {:ex_aws, "~> 2.7.0"}
# {:ex_aws_s3, "~> 2.5.9"}
# {:nimble_csv, "~> 1.3.0"}
```

**Version verification:** All versions above were checked directly against the hex.pm package API
(`https://hex.pm/api/packages/<name>`) during this research session — not training-data recall.
`sweet_xml`'s last release (0.7.5) is from January 2025; `saxy`, `ex_aws`, `ex_aws_s3`, `vix`, and
`image` all have releases within the last few months of this research date, confirming active
maintenance.

## Package Legitimacy Audit

> The automated `gsd-tools query package-legitimacy check` seam only supports `npm`/`pypi`/`crates`
> ecosystems, not `hex` — this audit was performed via direct `hex.pm` API queries (registry
> existence, `inserted_at`, `downloads`, linked source repo) since no automated hex-ecosystem gate
> exists yet.

| Package | Registry | Age | Downloads (all-time) | Source Repo | Verdict | Disposition |
|---------|----------|-----|----------------------|-------------|---------|-------------|
| `sweet_xml` | hex.pm | ~11.5 yrs (since 2014-07) | 70.5M | github.com/kbrw/sweet_xml | OK | Approved |
| `saxy` | hex.pm | ~8 yrs (since 2018-01) | 8.9M | github.com/qcam/saxy | OK | Approved (alternative, not primary pick) |
| `vix` | hex.pm | ~5.5 yrs (since 2020-11) | 1.7M | github.com/akash-akya/vix | OK | Approved |
| `image` | hex.pm | ~4 yrs (since 2022-05) | 1.26M | github.com/elixir-image/image | OK | Approved |
| `ex_aws` | hex.pm | ~11 yrs (since 2015-03) | 70.1M | github.com/ex-aws/ex_aws | OK | Approved |
| `ex_aws_s3` | hex.pm | ~8.5 yrs (since 2017-11) | 58.5M | github.com/ex-aws/ex_aws_s3 | OK | Approved |
| `nimble_csv` | hex.pm | ~10 yrs (since 2016-07) | 18.2M | dashbitco (José Valim's org) | OK | Approved |
| `aws_signature` | hex.pm | ~4.5 yrs (since 2021-08) | 3.2M | github.com/aws-beam/aws_signature | OK | Not needed this phase (only for presigned-URL flow) — noted, not installed |
| `umya_spreadsheet_ex` | hex.pm | ~1 yr (since 2025-06) | 1,807 (all-time) | github.com/alexiob/umya_spreadsheet_ex | SUS | Flagged — only use if user declines the manual CSV-export step; planner must add a `checkpoint:human-verify` before installing if chosen |
| `xlsxir` | hex.pm | ~10 yrs, but **last published 2019-03** (7 years stale) | not queried (deprioritized) | github.com/jsonkenl/xlsxir | SUS (unmaintained) | Rejected — do not use; superseded in practice by the CSV-conversion approach or `umya_spreadsheet_ex` |

**Packages removed due to `[SLOP]` verdict:** none.
**Packages flagged as suspicious `[SUS]`:** `umya_spreadsheet_ex` (low adoption/single release — gate
behind `checkpoint:human-verify` if chosen instead of manual CSV export), `xlsxir` (unmaintained
since 2019 — do not use regardless).

*All package names above were discovered via WebSearch/hex.pm lookup this session, not prior
training-data recall of a specific version — but hex.pm registry confirmation plus an actively
maintained GitHub source repo for the "OK" rows meets this project's bar for `[VERIFIED: hex.pm
registry]`. `umya_spreadsheet_ex` and `xlsxir` remain `[ASSUMED]`-tier recommendations pending
user confirmation given their weak adoption/staleness signals.*

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────────────────┐
                         │   ONE-TIME, MANUAL (not request path)    │
                         │                                           │
   Club Excel file       │  mix task: seed.enrich_catalog            │
   (titles, BGG ids, ────┼─▶ 1. CSV parse (NimbleCSV)                │
    6 hashtags)          │  2. BGG XML API /thing?id=... (sweet_xml) │
                         │     [requires registered app + Bearer     │
                         │      token — see Common Pitfalls]         │
                         │  3. Download cover + gallery images       │
                         │     (req)                                 │
                         │  4. Resize to 2 variants (image/Vix)      │
                         │  5. Upload to Cloudflare R2 (ex_aws_s3)    │
                         │  6. Insert/update `games` rows             │
                         └───────────────────┬───────────────────────┘
                                             │ (writes once, before Phase 1 goes live)
                                             ▼
                                   ┌───────────────────┐
                                   │   Postgres 17      │
                                   │  games table:       │
                                   │  - scalar cols       │
                                   │    (players/time/age)│
                                   │  - mechanics text[]  │
                                   │    + themes text[]   │
                                   │    (GIN indexes)     │
                                   │  - search_vector      │
                                   │    tsvector (GIN,      │
                                   │    'spanish' config)   │
                                   │  - weight_band, tags   │
                                   │    (6 hashtags)         │
                                   │  - cover_url/gallery_urls│
                                   │    (R2 URLs, not BGG)    │
                                   └─────────┬────────────────┘
                                             │ read (Ecto, <50ms, synchronous)
                                             ▼
        Browser ──▶ CatalogLive.Index (LiveView, public route, no auth)
                     │
                     ├─ handle_event("filter", ...) ─▶ Catalog.filter_games/1
                     │     (scalar WHERE + text[] && GIN + tsvector rank,
                     │      ORDER BY per CATALOG-04, LIMIT/OFFSET for
                     │      "Cargar más")
                     │        ↓
                     ├─ stream(:games, results, reset: true|false)
                     │        ↓
                     └─ diff patched to DOM (grid + carousel rows)

        Browser ──▶ image <img src="https://<r2-domain>/games/123/thumb.webp">
                     (direct R2 fetch — Phoenix app never proxies image bytes)
```

### Recommended Project Structure
```
lib/pukllay_club/
├── catalog/
│   ├── game.ex              # schema: mechanics/themes {:array,:string}+GIN,
│   │                         #   search_vector tsvector, weight_band, tags{:array}
│   └── seed/
│       ├── bgg_client.ex     # req-based BGG API client, batches ids, respects
│       │                     #   rate limit, requires Authorization: Bearer token
│       ├── xml_parser.ex     # sweet_xml extraction of thing response -> map
│       ├── image_pipeline.ex # download -> Image.thumbnail/2 (x2 variants) -> R2 upload
│       └── excel_import.ex   # NimbleCSV parse of the converted CSV export
├── catalog.ex                # context: filter_games/1, list_carousel/1, get_game!/1
lib/pukllay_club_web/live/
├── catalog_live/
│   ├── index.ex               # browse page: carousels + grid + drawer + search
│   └── show.ex                # game detail page
├── components/
│   ├── game_card.ex            # card component (cover, weight-band chip, hashtags)
│   ├── filter_drawer.ex         # slide-over drawer (D-13), tag-pill toggles (D-14)
│   └── carousel_row.ex          # one horizontally-scrollable carousel row
priv/repo/migrations/
├── ..._create_games.exs          # scalar cols + text[] cols (no GIN yet)
├── ..._add_games_gin_indexes.exs  # GIN indexes — separate migration, run AFTER seed
priv/catalog_seed/
└── games_export.csv               # user-provided (converted from Excel), gitignored if it contains any non-public data
```

### Pattern 1: Bulk-load before GIN-indexing (seed-then-index ordering)

**What:** Create the `games` table and its scalar columns in one migration; run the ~400-row seed
insert; only then run a second migration that adds the GIN indexes on `mechanics`, `themes`, and the
`search_vector` tsvector column.
**When to use:** Any one-time bulk load into a table that will carry array/tsvector GIN indexes.
**Why:** This is the same "seed before index" discipline the project's own PITFALLS.md documents for
Phase 2's HNSW/IVFFlat pgvector index (`.planning/research/PITFALLS.md` Pitfall 6) — GIN on
`text[]`/`tsvector` does not have IVFFlat's centroid-training correctness bug (GIN is a plain
inverted index, not a clustering index, so building it early doesn't corrupt results), but building
it before the bulk insert still means every one of the ~400 inserts pays per-row index-maintenance
cost instead of one bulk index build — a performance-only concern at this row count, not a
correctness one, but cheap to avoid entirely. [ASSUMED — general Postgres bulk-load practice, not
found verbatim in project research for the GIN case specifically; PITFALLS.md's precedent is for
IVFFlat/HNSW, not GIN]

### Pattern 2: text[] + GIN, OR-logic facet filter (per D-14)

**What:** D-14 requires "match ANY selected tag" (OR), which is Postgres's array-overlap operator
`&&`, not the array-containment operator `@>` (which means "has ALL of these" / AND).

**Example:**
```elixir
# migration (after seed load, per Pattern 1)
create index(:games, [:mechanics], using: :gin)
create index(:games, [:themes], using: :gin)
create index(:games, [:tags], using: :gin)   # the 6 hashtags, D-05/D-06

# Catalog context query — D-14 "select multiple mechanic pills, ANY match"
from(g in Game,
  where: fragment("? && ?", g.mechanics, ^selected_mechanics),
  where: fragment("? && ?", g.themes, ^selected_themes)
)
# NOTE: mechanics and themes are separate facets (each internally OR'd);
# selecting across both facets together is effectively AND-between-facets,
# OR-within-a-facet — confirm this reading against D-14 wording during planning.
```
Source: `.planning/research/ARCHITECTURE.md` Pattern 2 (project-level precedent for `text[]`+GIN,
already documents both `@>` and `&&` forms) — reused and specialized to D-14's OR requirement.

### Pattern 3: Combined tsvector rank + facet filter + scalar filter/sort in one query

**What:** CATALOG-02/03/04/15 all apply to the *same* result set simultaneously (search box narrows
whatever the active filters show, per D-15). Compose all predicates into one Ecto query rather than
branching into separate "search mode" vs. "filter mode" code paths.

**Example:**
```elixir
def filter_games(params) do
  Game
  |> maybe_search(params[:q])
  |> maybe_filter_players(params[:min_players], params[:max_players])
  |> maybe_filter_playtime(params[:max_playtime])
  |> maybe_filter_age(params[:min_age])
  |> maybe_filter_mechanics(params[:mechanics])
  |> maybe_filter_themes(params[:themes])
  |> apply_sort(params[:sort_by])
  |> limit(^page_size())
  |> offset(^params[:offset])
  |> Repo.all()
end

defp maybe_search(query, nil), do: query
defp maybe_search(query, term) do
  from g in query,
    where: fragment("? @@ websearch_to_tsquery('spanish', ?)", g.search_vector, ^term),
    order_by: [desc: fragment("ts_rank(?, websearch_to_tsquery('spanish', ?))", g.search_vector, ^term)]
end
```
`websearch_to_tsquery` (not the older `to_tsquery`) tolerates raw user input (quotes, `-`, `OR`)
without raising on malformed syntax, which matters for a public search box. [ASSUMED — standard
Postgres full-text pattern, not verified against a Phase-1-specific source this session; the
project's own STACK.md confirms the `'spanish'` config choice generally, not the `websearch_to_tsquery`
function specifically]

### Pattern 4: LiveView Streams + "Cargar más" (load-more, not infinite scroll)

**What:** Per 01-UI-SPEC.md's resolved "populated" state, pagination is a below-the-fold button, not
scroll-triggered. `stream/3` for the initial page; `handle_event("load-more", ...)` fetches the next
page and appends via a second `stream/3` call with `at: -1` (append) rather than `reset: true`
(which would replace the whole collection).

**Example:**
```elixir
# CatalogLive.Index
def mount(_params, _session, socket) do
  games = Catalog.filter_games(%{offset: 0, limit: @page_size})
  {:ok, socket |> assign(:offset, @page_size) |> stream(:games, games)}
end

def handle_event("load-more", _params, socket) do
  more = Catalog.filter_games(%{offset: socket.assigns.offset, limit: @page_size})
  {:noreply,
   socket
   |> assign(:offset, socket.assigns.offset + @page_size)
   |> stream(:games, more, at: -1)}
end

def handle_event("filter-changed", params, socket) do
  games = Catalog.filter_games(Map.put(params, :offset, 0))
  {:noreply, socket |> assign(:offset, @page_size) |> stream(:games, games, reset: true)}
end
```
[CITED: flop-phoenix "Load More and Infinite Scroll" guide — same `push_patch`/`handle_params`
shape, adapted here to a plain `handle_event` since Phase 1 doesn't require URL-shareable pagination
state; core `stream/3` `reset:`-vs-append behavior is documented Phoenix LiveView behavior]

### Anti-Patterns to Avoid

- **Re-deriving weight bands from BGG's raw `averageweight` float:** D-05 is explicit that the 3
  bands come from the club's own already-applied Excel hashtags, not a Claude-invented cutoff on
  BGG's 1.0-5.0 scale. Don't build a `case averageweight do ... end` mapping — read the hashtag
  column directly.
- **Building GIN indexes in the same migration as `create table`, before the seed task has run:**
  works correctness-wise for GIN (unlike IVFFlat) but pays needless per-row index-maintenance cost
  during the ~400-row bulk insert; split into two migrations per Pattern 1.
- **Treating the drawer's OR-logic tag-pill filter as AND across the whole facet system:** D-14 is
  specific that *within* a facet, selections OR; don't silently apply `@>` (AND/contains) semantics
  when wiring up the pill toggle handler.
- **Calling the BGG API without a registered application token:** as of this research date, BGG
  actively rejects unauthenticated `/xmlapi2/thing` requests with `401`. Don't discover this mid-seed
  -task-build; register first (see Common Pitfalls).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| BGG XML parsing | A regex-based or manual DOM-walking XML extractor | `sweet_xml`'s `~x` XPath sigils | BGG's `<item><link type="boardgamemechanic" id="..." value="..."/></item>` shape is exactly what XPath selectors are built for; hand-rolled string parsing of XML is fragile against attribute-order/whitespace variance |
| Image resizing | Shelling out to raw `convert`/ImageMagick via `System.cmd/3` | `image` (Vix/libvips wrapper) | Precompiled NIF avoids a system ImageMagick dependency on whatever machine runs the seed task; also measurably faster |
| S3-compatible signing for R2 upload | Hand-rolled AWS SigV4 request signing | `ex_aws`/`ex_aws_s3` | SigV4 signing has subtle correctness requirements (canonical request construction, header ordering); `ex_aws` has done this correctly for a decade across many S3-compatible backends |
| Spanish accent-insensitive search | A custom "strip accents" pre-processing function applied to every stored/queried string | Postgres's built-in `unaccent` extension, layered into a custom text-search configuration alongside `'spanish'` (see Common Pitfalls) | `unaccent`'s `unaccent.rules` file already handles the full Unicode diacritic-stripping table; a hand-rolled version will miss edge cases (ligatures, combining characters) |
| Excel/CSV parsing | A hand-rolled line-splitter for the exported game list | `NimbleCSV` (after converting Excel → CSV once) | CSV quoting/escaping rules (embedded commas, quoted newlines) are exactly the kind of "looks simple, isn't" parsing problem a dedicated library exists to solve |

**Key insight:** Every "don't hand-roll" item above is a solved problem with a well-adopted,
actively-maintained Elixir library (all verified this session against the hex.pm registry) — the
actual work in Phase 1's seed task is orchestration (fetch → parse → resize → upload → persist) and
data-quality judgment calls (D-04's "flag exceptions for manual review"), not algorithm-building.

## Common Pitfalls

### Pitfall 1: BGG XML API now requires registration + a Bearer token (breaking change vs. assumed-free access)

**What goes wrong:** D-01/D-02 were scoped assuming the BGG XML API is freely/anonymously callable,
as it has been historically. As of July 2, 2025, BGG requires every application (commercial and
non-commercial) to register at `boardgamegeek.com/applications/create` and include an
`Authorization: Bearer <token>` header on XML API requests, with a narrow exception (downloading
one's *own* collection while logged in) that does not apply to `/xmlapi2/thing` batch-by-id lookups.
**Why it happens:** This is a genuinely recent (within the last ~1 year of this research date)
platform-side change; most existing tutorials/blog posts/community client libraries predate it and
still show unauthenticated example requests.
**How to avoid:** Register a BGG application (free, per community reports) before writing any seed
-task code that calls `/xmlapi2/thing`; store the resulting token via the project's existing
`.kamal/secrets`-style pattern for local dev (e.g. a `.env`/`config/dev.secret.exs`-style local file,
gitignored) since this is a dev-machine/CI script per D-02, not a production runtime secret routed
through Kamal.
**Warning signs:** `HTTP 401` with a `WWW-Authenticate: Bearer realm="xml api"` response header
(confirmed live during this research session via direct `curl`); community threads titled
"XML API2 doesn't work anymore" / "the XML APIcalypse is coming."
**Phase to address:** Phase 1, as the very first concrete task — before any BGG-calling code is
written, not discovered as a runtime surprise mid-seed-script-build.

### Pitfall 2: Undocumented/community-only BGG rate limit

**What goes wrong:** BGG's XML API has no current official rate-limit documentation (last officially
documented figure dates to 2014 per community threads); the practical community-observed limit is
roughly 2 requests/second, and exceeding it risks `429`/temporary blocks.
**Why it happens:** ~400 games means ~400 `/thing` calls if not batched; BGG's `/thing` endpoint
does support comma-separated multi-id batching in one request (confirmed via community
documentation), which is the main lever to stay well under any rate limit — batch by ~10-20 ids per
request rather than one request per game.
**How to avoid:** Batch ids into groups (e.g. 20 per request → ~20 requests total for 400 games,
not 400), add an explicit inter-request delay (e.g. 1-2 req/sec), and implement retry-with-backoff
on `429`/`5xx` responses.
**Warning signs:** Intermittent `429` or connection resets partway through a seed run.
**Phase to address:** Phase 1 — build batching and backoff into `bgg_client.ex` from the start
rather than retrofitting after a failed seed run.

### Pitfall 3: Re-deriving weight bands instead of reading the Excel hashtag

**What goes wrong:** It's tempting to compute the 3 weight bands from BGG's `averageweight` float
(e.g. `< 2.0 → beginner`) since that data is readily available and numeric. D-05 is explicit this is
wrong — the bands come from the club's own already-applied Excel hashtags, which may not align
perfectly with any cutoff Claude would invent from BGG's raw scale.
**Why it happens:** BGG's `averageweight` is the more "complete" numeric-looking data source, so it's
an easy trap to reach for it as ground truth instead of the (less structured-looking) hashtag column.
**How to avoid:** Ingest `weight_band` directly from the Excel hashtag column; treat BGG's
`averageweight` as supplementary/informational only (if surfaced at all), not authoritative for
band assignment.
**Warning signs:** A `weight_band` migration/derivation function that references `averageweight`
thresholds instead of reading an Excel column.
**Phase to address:** Phase 1 seed task design.

### Pitfall 4: Spanish full-text search without accent-folding

**What goes wrong:** Postgres's `'spanish'` text-search configuration handles stemming (e.g.
"estrategia"/"estratégico" reducing to a common lexeme) but does not automatically fold accented
characters the way a naive user's search input might expect (e.g. searching "diseno" should probably
still surface "diseño" and vice versa) unless the `unaccent` extension is layered into a custom
search configuration.
**Why it happens:** `unaccent` is a separate contrib extension, not enabled by `to_tsvector('spanish',
...)` alone; easy to miss since the base Spanish config already looks "handled."
**How to avoid:** `CREATE EXTENSION unaccent;` then define a custom text search configuration that
copies `spanish` and inserts `unaccent` as a filter dictionary ahead of the Spanish stemmer, per
Postgres's own `unaccent` documentation pattern. Verify with a real accented query (e.g. "negociación"
without the accent) against the seeded catalog before considering CATALOG-03 done.
**Warning signs:** A search for an accent-variant spelling of a title/designer returns zero results
despite the correctly-accented version existing in the data.
**Phase to address:** Phase 1, when the `tsvector` generated column and its GIN index are defined.
[ASSUMED — general Postgres full-text-search practice, not verified against a Phase-1-specific
source this session; flag for planner/human confirmation that this matters enough for a ~400-game
Spanish catalog to add the extra migration step]

### Pitfall 5: daisyUI v4→v5 class renames leaking into the implementation if any reference markup used v4 conventions

**What goes wrong:** daisyUI 5 renamed several component modifier classes (e.g. `card-bordered` →
`card-border`, `input-bordered` removed/replaced by a default-bordered + `input-ghost` opt-out,
`tabs-bordered` → `tabs-border`). The project already vendors daisyUI v5.5.20, so this only matters
if any implementer references older v4-era tutorials/snippets while building the carousel/drawer/tag
-pill components.
**Why it happens:** Most web tutorials and Stack Overflow answers still show v4 class names since v5
is comparatively recent.
**How to avoid:** Confirmed this session: **carousel** (`carousel`, `carousel-item`) and **drawer**
(`drawer`, `drawer-toggle`, `drawer-side`, `drawer-content`, `drawer-overlay`, `drawer-button`) class
names are unchanged between v4 and v5 — daisyUI's own upgrade guide's ~15-item changelist does not
mention either component. Badge/tag-pill styling uses plain `badge`/`badge-*` classes, also unchanged.
Only the renamed classes above (card/input/select/tabs/menu/footer/mockup-phone/table/forms) need
v5-aware attention if referenced from memory or an old tutorial.
**Warning signs:** A component renders with no border/background because a removed v4 modifier class
(e.g. `input-bordered`) is silently ignored by v5's Tailwind-plugin-based CSS generation.
**Phase to address:** Phase 1 UI implementation — cross-check any hand-written component markup
against `daisyui.com/docs/upgrade/`'s current class list before relying on memory.

### Pitfall 6: Running the seed task's image/BGG pipeline on the production e2-micro box

**What goes wrong:** The production host is a 1GB-RAM/2GB-swap GCP e2-micro (per 00-CONTEXT.md
D-20) — running BGG XML parsing + image download + libvips resize + R2 upload for ~400 games
concurrently with the live app risks memory pressure or a slow/flaky deploy window.
**Why it happens:** It's tempting to run "just a mix task" via SSH on the production host since
that's where the app and its secrets already live.
**How to avoid:** D-02 already specifies this is a manual, one-time task — confirmed reasonable to
run on a developer machine or a CI runner (e.g. a GitHub Actions job with a generous memory limit),
not the production box. The Postgres accessory the task writes to is only bound to `127.0.0.1` on
the production host (00-CONTEXT.md D-15), so running the seed task from a dev machine requires an
SSH tunnel or a temporary bound port — plan for this connectivity detail explicitly rather than
assuming a direct connection works.
**Warning signs:** OOM-killed seed task; a deploy window blocked by a long-running SSH session.
**Phase to address:** Phase 1 planning — decide the seed task's execution environment (dev machine +
SSH tunnel to Postgres, vs. a one-off CI job) before writing the task.

## Code Examples

### Ecto migration: games table + text[] columns (index deferred, per Pattern 1)
```elixir
# Source: adapted from project's own ARCHITECTURE.md Pattern 2, extended per Phase 1 CONTEXT.md
create table(:games) do
  add :name, :string, null: false
  add :bgg_id, :integer, null: false
  add :min_players, :integer
  add :max_players, :integer
  add :min_playtime, :integer
  add :max_playtime, :integer
  add :min_age, :integer
  add :weight_band, :string          # "descubre_el_hobby" | "ingenio_estratega" | "nivel_experto"
  add :tags, {:array, :string}, default: []     # 6 editorial hashtags (D-05/D-06)
  add :mechanics, {:array, :string}, default: []
  add :themes, {:array, :string}, default: []
  add :cover_url, :string             # R2 URL, detail-size variant
  add :thumbnail_url, :string         # R2 URL, small variant
  add :gallery_urls, {:array, :string}, default: []
  timestamps()
end
create unique_index(:games, [:bgg_id])

# priv/repo/migrations/<later timestamp>_add_games_search_and_gin_indexes.exs
# run AFTER the seed task has populated ~400 rows
execute "ALTER TABLE games ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (to_tsvector('spanish', coalesce(name,'') || ' ' ||
    coalesce(designer,'') || ' ' || coalesce(publisher,''))) STORED"
create index(:games, [:search_vector], using: :gin)
create index(:games, [:mechanics], using: :gin)
create index(:games, [:themes], using: :gin)
create index(:games, [:tags], using: :gin)
```

### BGG batch fetch with `req` + `sweet_xml`
```elixir
# Source: composed from req's documented HTTP client usage + sweet_xml's XPath README pattern
# (BGG XML API2 endpoint shape per boardgamegeek.com/wiki/page/BGG_XML_API2, and the July-2025
# auth requirement confirmed live this session — see Common Pitfalls #1)
defmodule PukllayClub.Catalog.Seed.BggClient do
  import SweetXml

  @endpoint "https://boardgamegeek.com/xmlapi2/thing"

  def fetch_batch(bgg_ids, token) when length(bgg_ids) <= 20 do
    ids = Enum.join(bgg_ids, ",")

    Req.get!(@endpoint,
      params: [id: ids, type: "boardgame", stats: 1],
      headers: [{"authorization", "Bearer #{token}"}]
    )
    |> Map.fetch!(:body)
    |> parse_items()
  end

  defp parse_items(xml) do
    xml
    |> xpath(~x"//item"l,
      bgg_id: ~x"./@id"i,
      name: ~x".//name[@type='primary']/@value"s,
      min_age: ~x"./minage/@value"i,
      average_weight: ~x".//statistics/ratings/averageweight/@value"f,
      mechanics: ~x".//link[@type='boardgamemechanic']/@value"sl,
      categories: ~x".//link[@type='boardgamecategory']/@value"sl,
      image: ~x"./image/text()"s,
      thumbnail: ~x"./thumbnail/text()"s
    )
  end
end
```
[ASSUMED — the exact XPath field names (`averageweight`, `minage`, link `type` attribute values)
are drawn from training-data knowledge of BGG XML API2's schema, not confirmed via a live fetch this
session (BGG's own wiki page and a direct API call both returned bot-challenge/auth-wall responses
during this research pass — see Assumptions Log). Verify against a real authenticated response
during Phase 1 execution, once a token is registered, before finalizing the parser.]

### R2 upload via `ex_aws_s3`
```elixir
# Source: composed from ex_aws_s3 hexdocs usage pattern + community-confirmed R2 config overrides
# config/runtime.exs (or a seed-task-specific config)
config :ex_aws,
  access_key_id: System.get_env("R2_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("R2_SECRET_ACCESS_KEY"),
  region: "auto"

config :ex_aws, :s3,
  scheme: "https://",
  host: "#{System.get_env("R2_ACCOUNT_ID")}.r2.cloudflarestorage.com",
  region: "auto"

# in the seed task
ExAws.S3.put_object("pukllay-club-images", "games/#{bgg_id}/thumb.webp", thumb_binary,
  content_type: "image/webp"
)
|> ExAws.request!()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Unauthenticated BGG XML API access (any request works) | Registered application + Bearer token required | July 2, 2025 (per community reports) | Every existing BGG-import tutorial/blog post/community library predating this date will fail with `401` unless updated — do not copy example code verbatim without adding the auth header |
| daisyUI v4 config via `tailwind.config.js` `plugins: [require("daisyui")]` | daisyUI v5 config-less, CSS-native `@plugin "daisyui"` directive (Tailwind v4 style) | daisyUI v5 release | Already fully migrated in this project's `assets/css/app.css` — confirmed this session, no action needed |
| pgvector-style IVFFlat-first tutorials | HNSW as the small-dataset default (project-level decision, Phase 2 concern) | n/a — noted here only because Phase 1's GIN-index-ordering discipline is the same underlying "don't index before you have data" lesson | Not a Phase 1 blocker; cross-referenced for consistency with the project's own PITFALLS.md |

**Deprecated/outdated:** Any BGG API client library or code sample that does not send an
`Authorization: Bearer` header should be treated as outdated regardless of how recently a blog post
about it was written, given how recent the auth requirement is.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact BGG `/xmlapi2/thing` XML field names/shapes (`averageweight`, `minage`, `link[@type=...]` values, image/thumbnail element locations) | Code Examples, Architecture Patterns | If BGG's actual schema differs from training-data recall, the `xpath/2` extraction calls in `bgg_client.ex`/`xml_parser.ex` will silently return `nil`/empty lists rather than erroring — must be verified against one real authenticated API response early in Phase 1 execution, not assumed correct from this research alone |
| A2 | BGG's registration process is free and has no meaningful approval delay for a small non-commercial club app | Summary, Common Pitfalls #1 | If registration requires manual BGG-staff approval with a multi-day turnaround, this becomes a hard blocking dependency on the Phase 1 timeline — register as early as possible, ideally before Phase 1 planning finalizes a schedule |
| A3 | GIN index build-before-vs-after-seed is a performance-only concern for `text[]`/`tsvector` (unlike IVFFlat's correctness bug) | Architecture Patterns Pattern 1 | Low risk — if wrong, worst case is a slower-than-necessary seed run, not incorrect search results; not a blocking assumption |
| A4 | `websearch_to_tsquery('spanish', ...)` is the right query-construction function (vs. `plainto_tsquery`/`to_tsquery`) for a public search box | Architecture Patterns Pattern 3 | If wrong, malformed user input (stray quotes, operators) could raise a Postgres error instead of degrading gracefully — verify with adversarial input during Phase 1 implementation |
| A5 | Postgres `unaccent` + custom search-config layering is worth the added migration complexity for this catalog's search quality | Common Pitfalls #4 | If the club's game titles/designer names rarely have accent-sensitive collisions in practice, this could be deferred without much UX cost — confirm with the user or defer to a fast-follow if it doesn't come up in review |
| A6 | `umya_spreadsheet_ex`/`xlsxir` package assessment (low adoption / staleness) reflects real risk, not just unfamiliarity | Package Legitimacy Audit | Low risk either way, since the recommended primary path (manual CSV export + `NimbleCSV`) avoids needing either package |

**If this table is empty:** N/A — see rows above.

## Open Questions

1. **Does the club's Excel file need a manual one-time CSV conversion, or should the seed task read `.xlsx` directly?**
   - What we know: `NimbleCSV` is a well-established, zero-friction dependency; both `.xlsx`-reading
     candidates (`umya_spreadsheet_ex`, `xlsxir`) carry adoption/staleness concerns (see Package
     Legitimacy Audit).
   - What's unclear: Whether the user considers a manual "export to CSV" step acceptable friction
     given D-02 already frames the whole pipeline as a manual one-time task.
   - Recommendation: Default to CSV conversion + `NimbleCSV` in the plan; only reach for
     `umya_spreadsheet_ex` (behind a `checkpoint:human-verify`) if the user explicitly prefers not to
     convert the file.

2. **Exact BGG registration turnaround time and any per-application rate-limit tier.**
   - What we know: Registration is required and is done via `boardgamegeek.com/applications/create`;
     community reports confirm the requirement is live and enforced.
   - What's unclear: Whether approval is instant/automatic or requires manual BGG review, and whether
     registered applications get a documented (vs. still-informal ~2 req/sec) rate limit.
   - Recommendation: Register as the literal first Phase 1 task (before any other seed-task code),
     so any approval delay surfaces immediately rather than blocking the seed task at the end of
     the phase.

3. **Does the production Postgres accessory's `127.0.0.1`-only binding (00-CONTEXT.md D-15) mean the
   seed task must run via SSH tunnel, or is a temporary bound port acceptable?**
   - What we know: The accessory is intentionally not exposed beyond localhost on the production
     host.
   - What's unclear: The concrete mechanism planning should specify (SSH port-forward vs. a
     temporary Kamal-side change) for the one-time seed run against production data.
   - Recommendation: Plan should include a concrete "how does the seed task reach the production DB"
     step rather than leaving it implicit — likely `ssh -L` port-forwarding, matching the pattern
     already used for other one-off production access needs in this project.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Erlang (mise-managed) | All Phase 1 work | ✓ (installed, but mismatched) | Installed: 1.17.3-otp-27; `mise.toml` pins 1.19.5-otp-28 | Run `mise install` before starting Phase 1 execution to match the pinned toolchain — do not implement against the older installed version |
| PostgreSQL | `games` table, GIN/tsvector indexes | ✓ | 16.14 (local `psql` client); production accessory runs `pgvector/pgvector:pg17` per Phase 0 | — |
| Docker | Local dev/prod parity, not strictly required for Phase 1 dev work | ✓ | 28.4.0 | — |
| `libvips` (system library) | Image resize via `vix`/`image` | Not found via `ldconfig` on this research machine | — | `vix` ships precompiled binaries that bundle/fetch their own libvips build at `mix deps.get`/compile time — no manual `apt-get install libvips` expected to be necessary, but confirm this succeeds in whatever environment (dev machine or CI) actually runs the seed task |
| ImageMagick (`convert`) | Only relevant if the Mogrify alternative is chosen instead | Not installed | — | Not needed if using the recommended `image`/`vix` path |
| BGG XML API access | Seed task's enrichment step | ✗ — requires a registered application + Bearer token (see Common Pitfalls #1); no anonymous fallback | — | None — this is a hard blocking prerequisite; register before starting seed-task implementation |
| Cloudflare R2 credentials | Image upload | Assumed available (already used for nightly `pg_dump` backups per Phase 0) | — | Reuse existing R2 account; a separate bucket or path prefix for catalog images is a Phase 1 planning decision, not a new external dependency |

**Missing dependencies with no fallback:**
- BGG XML API registered application/token — must be obtained before the seed task can run at all.

**Missing dependencies with fallback:**
- System `libvips`/ImageMagick — `vix`'s precompiled binaries are expected to cover this; verify at
  first `mix deps.get`/compile in the actual seed-task execution environment.
- Local Elixir/Erlang version mismatch — resolved by `mise install`, not a missing dependency per se.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir; already wired via `mix test` alias in `mix.exs`) |
| Config file | none dedicated — `test/test_helper.exs` exists (`Ecto.Adapters.SQL.Sandbox.mode(PukllayClub.Repo, :manual)`), confirmed this session |
| Quick run command | `mix test test/pukllay_club/catalog_test.exs` (or the relevant single file, once created) |
| Full suite command | `mix test` (already aliased to run `ecto.create --quiet && ecto.migrate --quiet && test`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CATALOG-01 | Browse full catalog, carousels/cards, streams, no account required | LiveView integration | `mix test test/pukllay_club_web/live/catalog_live_test.exs` | ❌ Wave 0 |
| CATALOG-02 | Filter by player count/playtime/mechanic/theme/min age | Context unit | `mix test test/pukllay_club/catalog_test.exs` | ❌ Wave 0 |
| CATALOG-03 | Keyword search via tsvector | Context unit + LiveView integration | `mix test test/pukllay_club/catalog_test.exs test/pukllay_club_web/live/catalog_live_test.exs` | ❌ Wave 0 |
| CATALOG-04 | Sort by playtime/complexity | Context unit | `mix test test/pukllay_club/catalog_test.exs` | ❌ Wave 0 |
| CATALOG-05 | Plain-Spanish weight-band descriptor rendering | LiveView integration (rendered HTML assertion) | `mix test test/pukllay_club_web/live/catalog_live_test.exs` | ❌ Wave 0 |
| CATALOG-06 | Plain-Spanish mechanic/theme chip rendering from glossary | LiveView integration | `mix test test/pukllay_club_web/live/catalog_live_test.exs` | ❌ Wave 0 |
| CATALOG-07 | Editorial tag ("club favorite"/etc.) carried through to card | Context unit + LiveView integration | same as above | ❌ Wave 0 |
| CATALOG-08 | Catalog is public, no auth required | LiveView/router integration (unauthenticated connection succeeds) | `mix test test/pukllay_club_web/live/catalog_live_test.exs` | ❌ Wave 0 |
| CATALOG-09 | Images are R2-hosted, not BGG-hotlinked | Seed-task unit test (asserts stored URL host, not a runtime catalog test) | `mix test test/pukllay_club/catalog/seed/image_pipeline_test.exs` (mock R2/HTTP boundary) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the relevant single test file(s) from the map above via `mix test <file>`.
- **Per wave merge:** `mix test` (full suite).
- **Phase gate:** Full suite green (plus `mix quality`, per project convention) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/pukllay_club/catalog_test.exs` — context-level filter/sort/search coverage for
      CATALOG-02/03/04
- [ ] `test/pukllay_club_web/live/catalog_live_test.exs` — LiveView integration coverage for
      CATALOG-01/03/05/06/07/08
- [ ] `test/pukllay_club/catalog/seed/image_pipeline_test.exs` — seed-task image-pipeline unit
      coverage for CATALOG-09 (mock the BGG HTTP fetch + R2 upload boundary; do not hit real
      external services in CI)
- [ ] `test/support/fixtures/catalog_fixtures.ex` — shared `Game` fixture factory (weight bands,
      hashtags, mechanics/themes) for both the context and LiveView test files above
- [ ] Test-DB fixture data must include at least one game per weight band and per editorial hashtag
      to exercise CATALOG-05/06/07 rendering paths meaningfully (not just a single generic fixture
      game)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | Phase 1 has no auth (CATALOG-08 is explicitly public); `phx.gen.auth` is out of scope until Phase 2 |
| V3 Session Management | No | No session-bound state introduced this phase beyond Phoenix's default LiveView socket lifecycle |
| V4 Access Control | No | No role/permission distinctions in Phase 1 (all routes are public reads) |
| V5 Input Validation | Yes | Ecto's parameterized queries (`fragment/1` with `^`-pinned values, `where:` with pinned params) prevent SQL injection by construction — never interpolate raw search/filter strings into a query string. `websearch_to_tsquery/2` (Pattern 3) additionally tolerates malformed search-box input without raising, rather than needing hand-rolled input sanitization |
| V6 Cryptography | No | No new cryptographic operations this phase (R2/BGG credentials are transport-layer HTTPS + API tokens, not application-level crypto) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| SQL injection via filter/search params | Tampering | Ecto's `fragment/2` with `^`-pinned parameters (never string-interpolate user input into a query fragment); already the idiomatic Ecto pattern, not a new control to add |
| Leaking BGG API token or R2 credentials into client-visible code/logs | Information Disclosure | Store as environment variables read only by the seed `mix` task (server/dev-side); never pass through to any LiveView assign or rendered template; keep out of git via the project's existing gitignore/secrets conventions |
| Unbounded/expensive search query (e.g. a pathological search term causing a slow sequential scan) | Denial of Service | GIN index on `search_vector` plus a reasonable `LIMIT` on every query (already required for the "Cargar más" pagination pattern) bounds both result size and, in practice, query cost at ~400 rows |
| Serving a hotlinked/attacker-supplied image URL | Tampering / Spoofing | Not applicable this phase — CATALOG-09 already mandates images are re-hosted on the club's own R2 bucket, not stored as arbitrary external URLs pulled from user input |

## Sources

### Primary (HIGH confidence)
- `hex.pm` package API (`/api/packages/<name>`) for every version/age/download figure in the Standard
  Stack and Package Legitimacy Audit tables (`sweet_xml`, `saxy`, `vix`, `image`, `ex_aws`,
  `ex_aws_s3`, `nimble_csv`, `aws_signature`, `umya_spreadsheet_ex`, `xlsxir`, `req`) — direct
  registry queries, not search-result recall
- Live `curl` against `boardgamegeek.com/xmlapi2/thing` and `boardgamegeek.com/using_the_xml_api`
  during this research session, confirming the `401`/`Bearer realm="xml api"` response and the
  Cloudflare bot-challenge behavior on the docs pages
- Direct reads of this project's `mix.exs`, `mix.lock`, `mise.toml`, `assets/css/app.css`, and
  `test/test_helper.exs` — confirms current dependency pins and test-framework setup

### Secondary (MEDIUM confidence)
- WebSearch results on BGG's July 2025 authentication requirement, cross-checked across multiple
  independent community threads (BGG's own Geek Tools forum, an unrelated GitHub issue, a Ruby gem
  README) reaching the same conclusion
- WebSearch + WebFetch (`flop-phoenix` hexdocs "Load More and Infinite Scroll" guide) for the
  LiveView Streams load-more pattern
- WebSearch (`daisyui.com/docs/upgrade/` via WebFetch) for the v4→v5 class-rename changelist
- WebSearch results on `sweet_xml` vs. `saxy` performance/API tradeoffs, cross-checked across the
  AppSignal blog post and Saxy's own hexdocs README
- WebSearch results on `ExAws`/Cloudflare R2 configuration (Elixir Forum thread + Medium/Tigris docs
  cross-reference)

### Tertiary (LOW confidence)
- Exact BGG `/xmlapi2/thing` XML field/attribute names in the Code Examples section — drawn from
  training-data recall since a live authenticated fetch was not possible this session (see
  Assumptions Log A1); flagged for verification during Phase 1 execution
- BGG's ~2 req/sec community rate-limit figure — informal community consensus, not an official
  documented number as of this research date

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - every package version/age/download figure confirmed via direct hex.pm API
  query this session
- Architecture: MEDIUM - patterns are standard Ecto/LiveView idioms and reuse this project's own
  documented `text[]`+GIN precedent, but the specific tsvector-query-function choice
  (`websearch_to_tsquery`) and the GIN-before-vs-after-seed performance framing are ASSUMED, not
  independently verified this session
- Pitfalls: MEDIUM overall, but the single most important pitfall (BGG API auth requirement) is
  MEDIUM/cross-checked-across-multiple-community-sources and independently confirmed live via a
  direct `curl` during this session — treat that one specifically as reliable

**Research date:** 2026-07-28
**Valid until:** ~30 days for the stack/version facts (hex.pm-verified, stable ecosystem); the BGG
API authentication finding specifically should be re-confirmed at the start of Phase 1 execution
regardless of elapsed time, since it is the single highest-impact/most-recent platform change this
research surfaced and its exact registration/rate-limit mechanics could not be fully confirmed this
session (BGG's own documentation pages returned bot-challenge responses to automated fetches).
