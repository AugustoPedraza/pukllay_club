# Phase 1: Catalog v1 - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Members can browse, filter, sort, and search a fully public (no-auth) catalog of ~400 games, with
complexity-teaching UX: plain-Spanish weight bands, plain-Spanish mechanic/theme chips, the club's
own resized images (including a small per-game gallery), and the club's existing editorial hashtag
signals. No AI/embeddings/NL search (Phase 2), no auth/favorites (Phase 2), no admin/rental
tracking (Phase 4).

</domain>

<decisions>
## Implementation Decisions

### Source Data & Seeding
- **D-01:** The ~400-game dataset is a **combination**: the club's existing Excel file provides
  game titles, BGG IDs (one column per game — no title-matching/fuzzy-search needed), and the 6
  editorial hashtags (see D-06); numeric/taxonomy data (weight, mechanics, categories, min age) is
  enriched from the **BGG XML API** keyed off the BGG ID. The user will hand over this file before/
  during planning.
- **D-02:** The BGG-enrichment + image-resize + R2-upload pipeline is a **one-time `mix` task, run
  manually** — not an Oban job. Matches PROJECT.md's scope (Oban is introduced in Phase 2).
  — **Reversibility:** reversible — it's a dev-time script, re-runnable.
- **D-03:** Cover images (and gallery images, see D-04) are downloaded from BGG by the seed mix
  task, resized to **two variants** (small thumbnail for card/carousel, larger for detail page),
  and uploaded to **Cloudflare R2** (already used for nightly backups — S3-compatible, no egress
  fees). The app serves R2 URLs directly — no hotlinking to BGG at runtime, no local-disk image
  storage. — **Reversibility:** costly — reversing means re-running the pipeline against a
  different storage target and updating every stored image URL.
- **D-04:** Each game gets a **small image gallery**, not just a single cover: cover/portrait +
  a couple of "table setup" and component photos, sourced from BGG's image gallery for that game.
  Only the **cover art** is required to match the game's specific owned language edition (Spanish
  preferred, since the club owns some English/German copies); extra gallery photos are
  **best-effort**, not guaranteed language-matched (BGG doesn't reliably tag interior/component
  photos by language). The club's Excel file does **not** track which language edition is owned
  per game — the seed task defaults to Spanish box-art where BGG has it, falls back to whatever's
  available otherwise, and should flag exceptions for manual review rather than silently guessing.

### Plain-Spanish Vocabulary
- **D-05:** Weight (CATALOG-05) maps to **3 bands**, using the club's own existing hashtags (found
  in the Excel file, already applied per-game — not derived by Claude):
  - `#DescubreElHobby` — beginner / new to the hobby
  - `#IngenioEstratega` — moderate strategy
  - `#NivelExperto` — demanding / expert
  The Excel file has only the hashtag label per game, **not** one-line explanatory copy — Claude
  drafts the plain-Spanish descriptive line for each band during planning (rules-explanation time /
  decision depth framing, per research/FEATURES.md), for user review.
- **D-06:** A **separate set of 3 editorial hashtags** (CATALOG-07, not weight-related) is also
  already applied per-game in the Excel file — treat these exactly like weight hashtags for
  ingestion (already-tagged data, no derivation needed):
  - `#CreaConexiones` — simple rules, family-friendly / guaranteed fun
  - `#EquipoGanador` — cooperative
  - `#DuelosMemorables` — 2-player only
  This confirmed 6-hashtag list (3 weight + 3 editorial) is the **full/exhaustive** vocabulary for
  Phase 1 — no additional hashtags exist in the source file.
- **D-07:** CATALOG-06's mechanic/theme chip glossary (translating BGG's raw mechanics/categories
  into plain Spanish, e.g. "worker placement" → readable Spanish) is **separate from the 6
  hashtags** and does **not** exist yet. Claude drafts a curated ~15-25 term glossary during
  planning, derived from whichever BGG mechanics/categories actually show up across the seeded 400
  games, for user review before locking in.

### Browse Layout
- **D-08:** Home/browse page = **themed carousels + a full filterable grid** (not a single flat
  grid). PROJECT.md's "carousels/cards/streams" language is realized as curated carousel rows up
  top, full grid below/on the browse view.
- **D-09:** Phase 1 ships a **fixed, hardcoded set of carousel rows**: Club Favorite /
  Beginner-Friendly (existing CATALOG-07 signals), one row per editorial hashtag (the 6 from
  D-05/D-06), and Recently Added. — **Reversibility:** reversible — hardcoded query changes are
  cheap to add/remove.
- **D-10 (Claude's Discretion / forward note):** The user explicitly wants a **fully
  dynamic/admin-configurable carousel system** eventually (e.g. so an admin could define new rows
  like "Ganadores Spiel" (Spiel des Jahres award winners) or a themed collection like "colección
  árabe" without a code change). This is **out of scope for Phase 1** — it fits naturally with
  Phase 4's admin dashboard (CLUBOPS). Flagged forward so Phase 4 planning doesn't reinvent this
  from scratch. Award-winner data specifically is **not** in the club's Excel file and BGG's award
  data is inconsistent — do not attempt to source it in Phase 1.
- **D-11:** The user will design the UI using **Google Stitch** (Google's AI UI-design tool)
  before/during Phase 1 planning — not started yet. When `/gsd-ui-phase` runs for this phase, the
  Stitch output (HTML/CSS or Figma-style export) is the **source of truth** for layout/visual
  design, not just inspiration — Claude's job is translating it into Phoenix LiveView +
  Tailwind/daisyUI components (matching phx.new defaults), not inventing the design from scratch.

### Filter & Search UX
- **D-12:** Filtering is **live-updating** — results update immediately via LiveView push as
  filters change, no submit/"Apply" button. Matches the project's LiveView Streams principle.
- **D-13:** Filters live in a **slide-over/drawer panel** triggered by a button (mobile-first,
  keeps the grid full-width) rather than a persistent sidebar.
- **D-14:** Mechanic/theme facets (`text[]` + GIN) use **tag pills with toggle multi-select**;
  selecting multiple tags within the facet uses **OR logic** (matches ANY selected tag, not ALL).
- **D-15:** Keyword search (title/designer/publisher via tsvector) is **combined with filtering**
  in the same experience — one search box at the top of the browse grid that narrows results while
  respecting whatever filters are currently active, not a separate search mode/page.

### Claude's Discretion
- Exact one-line plain-Spanish descriptive copy for the 3 weight bands (D-05) — draft during
  planning, present for user review.
- The ~15-25 term mechanic/theme glossary (D-07) — derive from actual seeded data, present for user
  review.
- Image resize dimensions/format specifics for the two variants (D-03) — pick reasonable defaults;
  can be revisited once the Stitch UI design (D-11) shows actual card/detail sizing needs.

### Real Data Findings (`LUDOTECA.csv`, confirmed 2026-07-28)

The club's CSV export arrived during Phase 1 planning and is committed at
`priv/repo/seed_data/ludoteca.csv` (the canonical path the seed mix task should read from — not
the original `~/Downloads/LUDOTECA.csv` handoff location, which won't exist outside this machine).
434 real game rows (28 raw columns incl. 7 empty trailing `Columna N` artifacts — proper CSV
parsing must respect quoted multi-line fields; a naive line-count gives 2817, not 434). These
findings correct/confirm assumptions in the decisions above and must inform the seed task (D-01/
D-02) and glossary work (D-07):

- **D-16:** The CSV has **10 hashtag columns, not 6** — beyond D-05/D-06's confirmed set it also
  has `#InicioRápido` (101/434 games), `#GestionaTusRecursos` (147/434), `#DominaElTablero`
  (111/434), `#ArteEnLaMesa` (135/434). **Confirmed: ignore these 4 columns for Phase 1** — not
  seeded, not displayed. They're a candidate input for a future admin-configurable hashtag/
  carousel system (ties to D-10, Phase 4 territory), not Phase 1 scope. No UI-SPEC change needed —
  the hardcoded 6-hashtag-row carousel design (D-09) stands as-is.
- **D-17:** The CSV also has pre-existing `Peso_BGG`, `Mecanicas`, `Categorias`, `Rating_BGG`,
  `Tiempo_Juego`, `Min_Jugadores`, `Max_Jugadores` columns — incidental/possibly-stale data from
  a prior export, **not the canonical source**. `Categorias` is populated on only 1/434 rows
  (unusable); `Mecanicas` on 394/434; `Peso_BGG`/`Rating_BGG`/`Tiempo_Juego`/`Min_Jugadores` on
  ~407-408/434. **Confirmed: per D-01, live BGG XML API (`/xmlapi2/thing`, keyed by `BGG_ID`,
  `stats=1`) stays the canonical source for weight, mechanics, categories, min age, and images —
  in one call per game (batched, multiple IDs per request) since all of these come back together.
  Persist the fuller fetched payload (not just what Phase 1's UI displays)** so a later phase
  doesn't need to re-run the one-time enrichment pipeline (D-02) just to backfill one more field.
  These CSV columns are reference/ignorable, not merged into the canonical record.
- **D-18:** **41/434 games (~9%) have no `BGG_ID` at all** — no BGG enrichment possible (no
  images, no min age, no API-sourced mechanics/categories/weight for these). **Confirmed: still
  list them in the v1 catalog with degraded data** (omit the missing chip/badge/gallery, per the
  UI-SPEC's existing "partial" state design for missing optional fields) — do not exclude them
  from the catalog.
- **D-19:** 1 duplicate `BGG_ID` (`163412`) shared by two CSV rows. Seed task flags this for
  manual review rather than silently deduping or dropping either row.
- **D-20:** Hashtag column values are inconsistently entered — `si`/`Sí`/`sí` (case/accent
  variants) all mean true; stray values (`n`, `s`, `di`, `su`, `ai`) are observed data-entry slips.
  Seed task treats any `si`/`sí` case-insensitive match as true, everything else as false, and
  **logs any non-empty value that isn't a recognized si/no variant** for manual review (don't
  silently coerce typos). Separately: 11 games have **2 of the 3 weight-band hashtags marked true
  simultaneously** (conflict) — derive the band from `Peso_BGG` when available as a tie-break,
  otherwise flag for manual review (don't pick arbitrarily). 46 games have **zero weight-band
  hashtags set** — 20 of those have `Peso_BGG` to derive a band from instead; the remaining 26
  have neither and show no weight badge (same "omit missing chip" pattern as D-18).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope & requirements
- `.planning/PROJECT.md` — Phase 1 scope statement, core value, durable architecture principles
  (LiveView Streams, text[]+GIN for tags, no LLM on request hot path)
- `.planning/REQUIREMENTS.md` §Catalog (CATALOG-01..09) — the nine requirements this phase must
  satisfy
- `.planning/ROADMAP.md` §Phase 1 — goal, success criteria, requirement mapping

### Stack & implementation research
- `.claude/CLAUDE.md` §"Technology Stack" — full stack table (Phoenix 1.8, LiveView Streams,
  text[]+GIN, tsvector), version compatibility
- `.planning/research/FEATURES.md` — weight-band framing precedent (example band structure/tone,
  even though exact wording is now user-provided per D-05), mechanic/theme chip rationale,
  BGG-vs-cafe-SaaS competitive comparison, anti-features (no BGG-depth taxonomy, no public ratings)
- `.planning/research/PITFALLS.md` — seeding/index-order pitfalls relevant to the ~400-game seed
  (e.g. build any future index after full seed load, not before)
- `.planning/research/ARCHITECTURE.md` — build-order implications, Oban/embedding boundaries (Phase
  1 stays Oban-free per D-02)
- `.planning/phases/00-walking-skeleton-to-production/00-CONTEXT.md` — D-15 (Postgres accessory
  already uses `pgvector/pgvector:pg17` image, bound to `127.0.0.1`), D-20 (production is GCP
  e2-micro x86_64, 1GB RAM + 2GB swap — relevant for sizing the seed task's memory use during BGG
  enrichment/image resizing)

### Not yet created (expected inputs before/during planning)
- Club's Excel/CSV export (titles, BGG IDs, 6 editorial hashtags) — user to provide, referenced in
  D-01/D-05/D-06 but not yet in the repo
- Google Stitch UI export — user to provide before/during `/gsd-ui-phase`, referenced in D-11
- Mechanic/theme plain-Spanish glossary (D-07) and weight-band descriptive copy (D-05) — to be
  drafted by Claude during planning, no existing source

</canonical_refs>

<code_context>
## Existing Code Insights

Repo contains only Phase 0's walking-skeleton Phoenix app — stock `mix phx.new` scaffolding (no
custom branding per Phase 0's D-14), a placeholder page, `/up` health check, and one no-op
migration (`create_deploy_proof`). No catalog schema, no LiveView beyond the generated defaults, no
custom components beyond `core_components.ex`. `priv/repo/seeds.exs` exists but is empty (phx.new
default) — Phase 1's seed mix task is new work, not an extension of existing seeding logic. The
Postgres accessory already runs `pgvector/pgvector:pg17` (Phase 0 D-15), so no database image
change is needed even though Phase 1 itself doesn't use `vector` columns yet.

</code_context>

<specifics>
## Specific Ideas

- The 6 club hashtags (`#DescubreElHobby`, `#IngenioEstratega`, `#NivelExperto`,
  `#CreaConexiones`, `#EquipoGanador`, `#DuelosMemorables`) are exact, user-provided strings —
  use them verbatim as the editorial tag vocabulary, don't rename or reframe them.
- Cover art should prefer the Spanish-language edition where the club's physical copy is Spanish,
  since some games in the collection are owned in English or German but the product's focus is
  Spanish-language presentation.
- User plans to design the UI in Google Stitch and treat that output as the visual source of truth
  for `/gsd-ui-phase` — flag this early in that step rather than defaulting to a from-scratch
  daisyUI design.

</specifics>

<deferred>
## Deferred Ideas

- **Dynamic/admin-configurable carousel system** — admins define new curated carousel rows (e.g.
  "Ganadores Spiel", themed collections like "colección árabe") without a code change. Natural fit
  for Phase 4 (Club Ops / admin dashboard), not Phase 1's fully-public no-auth scope. See D-10.
- **Spiel des Jahres / award-winner data sourcing** — not in the club's Excel file, BGG's award
  data is inconsistent to query reliably. Revisit only if/when the dynamic carousel system (above)
  is built and the value of sourcing this data is reassessed.

### Reviewed Todos (not folded)
None — no pending todos matched this phase (`todo.match-phase` returned 0 matches).

</deferred>

---

*Phase: 1-Catalog v1*
*Context gathered: 2026-07-27*
