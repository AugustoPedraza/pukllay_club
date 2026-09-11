---
phase: 01-catalog-v1
plan: 04
subsystem: database
tags: [ecto, postgres, tsvector, gin-index, bgg-api, elixir, seed]

requires:
  - phase: 01-catalog-v1
    provides: 01-03's proven tracer pipeline (BggClient, ImagePipeline, R2Storage, CsvImport, catalog.seed mix task)
provides:
  - All 434 club games loaded into the games table with real-data-quality handling applied
  - HashtagNormalizer's three-branch weight-band resolution (hashtag > Peso_BGG tie-break > unresolved)
  - Spanish-preferred cover art selection with recorded no_spanish_edition exceptions
  - A capped 3-image gallery built from distinct BGG version images
  - A reviewable catalog_seed_report.md covering every data-quality finding
  - search_vector generated tsvector column (spanish_unaccent config) plus GIN/btree indexes on games
  - A verified re-runnable seed pipeline (second run produces neither duplicate rows nor duplicate uploads)
affects: [01-05, 01-06]

actuals:
  tokens: 12500
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Three-branch weight-band resolution: single hashtag wins outright, two-or-more falls back to Peso_BGG threshold tie-break, zero-and-unusable stays unresolved and reported — never silently guessed"
    - "Bulk-load before GIN-indexing: the search_vector column and its GIN index are added in a migration that runs AFTER the full seed load, not before"
    - "unaccent() is STABLE not IMMUTABLE, so accent folding is layered into a named text search configuration (spanish_unaccent) rather than called inline in the generated column expression"
    - "GENERATED ALWAYS columns must be excluded from on_conflict: {:replace_all_except, [...]} — Postgres rejects an explicit SET on a generated column"

key-files:
  created:
    - lib/pukllay_club/catalog/seed/hashtag_normalizer.ex
    - lib/pukllay_club/catalog/seed/report.ex
    - priv/repo/migrations/20260810172415_add_games_search_and_indexes.exs
    - priv/repo/seed_data/catalog_seed_report.md
    - docs/runbooks/catalog-seed.md
  modified:
    - lib/pukllay_club/catalog/seed/bgg_client.ex
    - lib/pukllay_club/catalog/seed/image_pipeline.ex
    - lib/pukllay_club/catalog/game.ex
    - lib/pukllay_club/catalog.ex
    - lib/mix/tasks/catalog.seed.ex
    - test/support/fixtures/catalog_fixtures.ex

key-decisions:
  - "Peso_BGG tie-break thresholds applied exactly as reviewed in 01-VOCABULARY.md: below 1.9 -> descubre_el_hobby, 1.9 through 3.1 inclusive -> ingenio_estratega, above 3.1 -> nivel_experto"
  - "versions=1 added to the BGG thing request; per-item xpath narrowed from //item to /items/item since nested boardgameversion items inside <versions> would otherwise be wrongly matched as top-level games"
  - "search_vector excluded from catalog.ex's on_conflict replace_all_except list alongside :id/:inserted_at — discovered by actually re-running the full seed to prove D-02's re-runnability requirement, not anticipated up front"
  - "catalog_seed_report.md and docs/runbooks/catalog-seed.md are committed as real review/reference artifacts (this run's actual output), not placeholders"

patterns-established:
  - "Pattern 1 (01-RESEARCH.md): bulk-load before GIN-indexing — apply generated columns/GIN indexes in a migration that runs after the bulk data load, not before"
  - "Report accumulator pattern: PukllayClub.Catalog.Seed.Report collects findings during a run and renders markdown with an explicit count per section, including zero"

requirements-completed: [CATALOG-01, CATALOG-03, CATALOG-05, CATALOG-07, CATALOG-09]

coverage:
  - id: D1
    description: "All 434 club games are seeded into the database, including the 41 rows with no BGG_ID"
    requirement: "CATALOG-01"
    verification:
      - kind: other
        ref: "psql: SELECT count(*) FROM games -> 434; catalog_seed_report.md 'Rows with no BGG_ID (D-18)' Count: 41"
        status: pass
    human_judgment: false
  - id: D2
    description: "Weight-band resolution follows the exact three-branch order (hashtag wins over Peso_BGG, tie-break thresholds, unresolved-and-reported)"
    requirement: "CATALOG-05"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog/seed/hashtag_normalizer_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Keyword search matches accent-insensitive spellings (searching without an accent finds an accented title)"
    requirement: "CATALOG-03"
    verification:
      - kind: other
        ref: "psql: plainto_tsquery('spanish_unaccent', 'codigo') matches 'Descifra el código' and 'Código Seceto Duo'"
        status: pass
    human_judgment: false
  - id: D4
    description: "Cover art prefers a Spanish-language BGG edition when available, with no_spanish_edition exceptions recorded rather than silently accepted"
    requirement: "CATALOG-09"
    verification:
      - kind: other
        ref: "catalog_seed_report.md 'No Spanish edition found (D-04)' Count: 39"
        status: pass
    human_judgment: false
  - id: D5
    description: "A second full seed run neither duplicates rows nor re-uploads already-present images"
    requirement: "CATALOG-07"
    verification:
      - kind: other
        ref: "manual re-run of mix catalog.seed against the live dev DB; row count stayed at 434 before and after"
        status: pass
    human_judgment: false
  - id: D6
    description: "The manual-review report (unrecognized cells, conflicts, duplicate BGG_ID group, missing items, Spanish-edition exceptions) matches the plan's specified counts"
    verification:
      - kind: other
        ref: "priv/repo/seed_data/catalog_seed_report.md — 8 unrecognized cells, 11 conflicts, 46 zero-hashtag (20 resolved/26 unresolved), 1 duplicate BGG_ID group, 8 missing items, 39 no-Spanish-edition"
        status: pass
    human_judgment: false

duration: ~3h active (spread across two sessions, 2026-08-06 and 2026-08-10/11)
completed: 2026-08-11
status: complete
---

# Phase 01 Plan 04: Full 434-game seed, data-quality rules, gallery, search indexes Summary

**Loaded all 434 club games with three-branch weight-band resolution, Spanish-preferred cover art, a capped gallery, and a Postgres GIN-indexed accent-insensitive search_vector column — verified idempotent on a second run.**

## Performance

- **Duration:** ~3h active work, spread across two sessions (Task 1 on 2026-08-06; Tasks 2-3 on 2026-08-10/11)
- **Started:** 2026-08-06T22:01:55-03:00
- **Completed:** 2026-08-11T12:00:13-03:00
- **Tasks:** 3
- **Files modified:** 14

## Accomplishments
- `HashtagNormalizer` resolves every game's weight band via the exact three-branch order from 01-RESEARCH.md Pitfall 3, with all D-16 out-of-scope hashtags explicitly excluded and every unrecognized cell reported rather than swallowed
- `Report` accumulates and renders every data-quality finding as a markdown audit with an explicit count per section (including zero), regenerated by every seed run
- BGG client extended with `versions=1` to expose per-edition, language-specific box art; cover selection prefers a Spanish-language version with a recorded `no_spanish_edition` exception on fallback, and a capped 3-image gallery is built from distinct version images
- The full 434-row `ludoteca.csv` is seeded into the `games` table (verified via direct DB count, not just the mix task's own exit code)
- `search_vector` generated `tsvector` column (via a `spanish_unaccent` text search configuration layering `unaccent` over `spanish_stem`) plus GIN indexes on `search_vector`/`mechanics`/`themes`/`tags` and btree indexes on the facet columns, added in a post-seed migration per Pattern 1
- Verified live: accent-insensitive search actually works, and a second full seed run left the row count unchanged with no duplicate rows

## Task Commits

Each task was committed atomically:

1. **Task 1: Hashtag normalization and three-branch weight-band resolution** - `445fad6` (test), `7eddd47` (feat)
2. **Task 2: Spanish-preferred cover, small gallery, and the manual-review report** - `7e2d12a` (test), `8071c5f` (feat)
3. **Task 3: Run the full 434-game seed, then build the search vector and GIN indexes** - `3059449` (feat)

_Note: Tasks 1 and 2 are TDD tasks with a red test commit followed by a green implementation commit._

## Files Created/Modified
- `lib/pukllay_club/catalog/seed/hashtag_normalizer.ex` - truthy?/1, resolve_weight_band/1, editorial_tags/1, unrecognized_cells/1
- `lib/pukllay_club/catalog/seed/report.ex` - accumulates seed-run findings, renders catalog_seed_report.md
- `lib/pukllay_club/catalog/seed/bgg_client.ex` - versions=1 param, per-version image/language extraction, /items/item xpath fix
- `lib/pukllay_club/catalog/seed/image_pipeline.ex` - select_cover/1 (Spanish-preferred), process_gallery/3 (capped at 3)
- `lib/pukllay_club/catalog/game.ex` - search_vector field (read-only, Postgres-generated)
- `lib/pukllay_club/catalog.ex` - on_conflict excludes :search_vector (generated column re-run fix)
- `lib/mix/tasks/catalog.seed.ex` - wires HashtagNormalizer + Report, adds --report-only
- `priv/repo/migrations/20260810172415_add_games_search_and_indexes.exs` - unaccent extension, spanish_unaccent config, search_vector column, GIN/btree indexes
- `priv/repo/seed_data/catalog_seed_report.md` - the real run's manual-review output
- `docs/runbooks/catalog-seed.md` - how to run/re-run the seed pipeline
- `test/pukllay_club/catalog/seed/hashtag_normalizer_test.exs`, `test/pukllay_club/catalog/seed/report_test.exs`, `test/support/fixtures/catalog_fixtures.ex` - test coverage and fixture defaults

## Decisions Made
- Peso_BGG tie-break thresholds applied exactly as reviewed: `<1.9` beginner, `1.9`-`3.1` inclusive middle, `>3.1` expert
- `versions=1` BGG request param plus xpath narrowed from `//item` to `/items/item` to avoid nested `boardgameversion` items being misread as top-level games
- `search_vector` explicitly excluded from `catalog.ex`'s `on_conflict: {:replace_all_except, [...]}` list — a Postgres `GENERATED ALWAYS` column can only be set to `DEFAULT`, so re-run upserts must never attempt to write it directly

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `catalog.ex` upsert crashed on generated column during re-run verification**
- **Found during:** Task 3 (verifying the plan's re-runnability requirement by actually running `mix catalog.seed` a second time against the live dev DB)
- **Issue:** `on_conflict: {:replace_all_except, [:id, :inserted_at]}` implicitly tries to `SET search_vector = EXCLUDED.search_vector` on conflict; Postgres rejects any explicit write to a `GENERATED ALWAYS ... STORED` column
- **Fix:** Added `:search_vector` to the `replace_all_except` exclusion list
- **Files modified:** `lib/pukllay_club/catalog.ex`
- **Verification:** Second full `mix catalog.seed` run completed without error; `games` row count stayed at 434 before and after
- **Committed in:** `3059449` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary for correctness — without it the plan's own "second run doesn't break" acceptance criterion would fail. No scope creep; `catalog.ex` wasn't in the plan's original `files_modified` list but the fix is a direct, minimal consequence of adding the generated column this same plan introduces.

## Issues Encountered
- The plan's Task 3 network-heavy full seed run (and the idempotency re-run used to verify D-02) each took roughly 20-25 minutes end-to-end (BGG rate-limit-aware batching + ~1,500 R2 image objects) — no failures, just genuinely long-running I/O, consistent with the plan's own precondition note.

## User Setup Required

None — no external service configuration required. `config/dev.secret.exs` (gitignored, provisioned in 01-01) already carried live BGG + R2 credentials.

## Next Phase Readiness
- The `games` table now holds the full real catalog with weight bands, tags, gallery images, and an indexed `search_vector` column — everything 01-05's browse/filter/search/sort surface and 01-06's complexity-teaching UX need to query against
- No blockers for 01-05

---
*Phase: 01-catalog-v1*
*Completed: 2026-08-11*
