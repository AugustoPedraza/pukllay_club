---
phase: 01-catalog-v1
plan: 09
subsystem: database
tags: [ecto, postgres, migration, seed, elixir, catalog]

requires:
  - phase: 01-catalog-v1
    provides: 01-04's full 434-game seed pipeline (CsvImport, HashtagNormalizer, catalog.seed mix task, Catalog.upsert_game!/1)
provides:
  - "games.is_expansion — a real queryable column, seed-time-derived and migration-backfilled, closing G-01-5"
  - "PukllayClub.Catalog.Seed.ExpansionClassifier — the single Elixir source of truth for the marker + reviewed-override rules"
  - "recent_query/0 excludes is_expansion rows, so the Recientemente añadidos carousel row surfaces base games again"
affects: [01-UAT]

actuals:
  tokens: 3985
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Elixir/SQL rule mirroring: a seed-time Elixir classifier and a migration-time SQL backfill express the identical business rule from two independent code paths, deliberately kept in plain substring/ILIKE form (no regex) so the two cannot silently drift out of parity"
    - "Migration-time backfill for a seed-derived flag: rather than requiring a re-run of a one-time, credential-gated seed task, the backfill ships inside the schema migration itself so Kamal's deploy-gated migration step corrects production data on the next deploy"

key-files:
  created:
    - lib/pukllay_club/catalog/seed/expansion_classifier.ex
    - priv/repo/migrations/20260818222551_add_games_is_expansion.exs
    - test/pukllay_club/catalog/seed/expansion_classifier_test.exs
  modified:
    - lib/pukllay_club/catalog/game.ex
    - lib/mix/tasks/catalog.seed.ex
    - lib/pukllay_club/catalog.ex
    - test/pukllay_club/catalog_test.exs

key-decisions:
  - "Marker list settled at 3 plain lowercase substrings: '(expa' (open-paren form, e.g. '(expa)', '(expa 1)'), 'expansi' (the spelled-out expansion stem, deliberately truncated before the accented/unaccented divergence so one substring matches 'Expansion', 'Expansión', and the club's one 'Expanción' typo), and 'promo'"
  - "Reviewed override list: csv_row 414, 415, 417, 421 — the 4 club-confirmed expansion/promo rows (01-UAT.md Test 5) that carry no text marker at all: the two 'Viajes por la Tierra Media' Lord of the Rings sub-sets, 'abyss leviatan', and 'viniculture tuscany'"
  - "ExpansionClassifier and the add_games_is_expansion migration's SQL backfill are documented mirrors — both moduledocs state explicitly that changing one requires changing the other"
  - "No index added on is_expansion — the only consumer is a LIMIT 20 carousel query over 434 rows; documented in the migration as a deliberate omission, not an oversight"
  - "Exclusion scoped to recent_query/0 only — filter_games/1, count_games/1, and the other 7 carousel rows are untouched by design, verified by an explicit regression test, so club-owned expansions remain searchable and present in the main grid"

patterns-established:
  - "Rule-mirroring across Elixir and raw migration SQL: keep the rule as plain substring/ILIKE matching (never regex) specifically so an Elixir classifier and a migration backfill can express the identical predicate without independently re-deriving word-boundary/escaping semantics"

requirements-completed: [CATALOG-01]

coverage:
  - id: D1
    description: "games.is_expansion column exists (null: false, default: false), backfilled to exactly 26 flagged rows in dev matching the club-reviewed set, and the migration rolls back/re-applies cleanly"
    requirement: "CATALOG-01"
    verification:
      - kind: other
        ref: "mix ecto.migrate && mix run -e '... count == 26' && mix ecto.rollback --step 1 && mix ecto.migrate — all passed live against dev DB"
        status: pass
    human_judgment: false
  - id: D2
    description: "ExpansionClassifier.expansion?/2 correctly classifies all marker forms, the 4 reviewed overrides, ordinary base games, and a nil name — and streaming the real ludoteca.csv through it yields exactly the 26 confirmed rows, csv_row 410..435"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog/seed/expansion_classifier_test.exs — 8 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "The recientemente_anadidos carousel row excludes expansion-flagged games while every other carousel row, filter_games/1, and count_games/1 are unaffected — an expansion remains searchable and counted"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog_test.exs — 'the recientemente_anadidos row excludes expansions...', 'the other seven carousel rows are unaffected...', 'an expansion-flagged game is still findable by search and still counted' — all pass"
        status: pass
    human_judgment: false
  - id: D4
    description: "A re-run of mix catalog.seed reproduces the is_expansion flag rather than resetting it, since both build_rows_and_report/1 and base_attrs/2 now set it via ExpansionClassifier and upsert_game!/1's on_conflict replace_all_except already refreshes new columns automatically"
    verification:
      - kind: other
        ref: "code inspection of catalog.seed.ex row map + base_attrs/2, plus mix catalog.seed --dry-run --report-only completing without error"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-08-18
status: complete
---

# Phase 01 Plan 09: is_expansion column + carousel exclusion (G-01-5) Summary

**Added `games.is_expansion` (seed-time classifier + migration backfill mirror) and filtered it out of the "Recientemente añadidos" carousel row, closing G-01-5 without re-running the credential-gated BGG/R2 seed pipeline.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-08-18 (this session, following 01-07)
- **Completed:** 2026-08-18T22:28:45Z
- **Tasks:** 3
- **Files modified:** 7 (3 created, 4 modified)

## Accomplishments
- `PukllayClub.Catalog.Seed.ExpansionClassifier.expansion?/2` — a marker list (`(expa`, `expansi`, `promo`) plus a 4-row reviewed-override list (`csv_row` 414, 415, 417, 421) — classifies all 26 club-confirmed expansion/promo rows correctly, verified by a real-CSV regression test streaming `ludoteca.csv` and asserting exactly `csv_row` 410..435
- `add_games_is_expansion` migration adds `games.is_expansion` (`null: false, default: false`) and backfills it via a literal-value SQL `UPDATE` that is a documented, deliberate mirror of the classifier's marker/override rules — verified to flag exactly 26 rows in dev and to roll back/re-apply cleanly
- `Game.seed_changeset/2` casts `:is_expansion`; `catalog.seed.ex` sets it via the classifier in both the row map and `base_attrs/2`, so a re-seed reproduces the flag on every row (enriched and unenriched) rather than resetting it
- `Catalog.recent_query/0` now filters `is_expansion == false`, closing the actual G-01-5 symptom — the carousel row no longer surfaces the tail-of-CSV block of expansions/promos — while `filter_games/1`, `count_games/1`, and the other 7 carousel rows are explicitly untouched and covered by a regression test proving expansions remain searchable and present in the main grid

## Task Commits

Each task was committed atomically (TDD tasks 1 and 3 have separate RED/GREEN commits):

1. **Task 1: Add the ExpansionClassifier as the single source of truth** - `7a3ea20` (test, RED), `f94bc85` (feat, GREEN)
2. **Task 2: Add the is_expansion column, backfill it in the migration, and populate it during seeding** - `0ef4ef4` (feat)
3. **Task 3: Exclude expansions from the recency carousel query** - `9896692` (test, RED), `9846086` (feat, GREEN)

## Files Created/Modified
- `lib/pukllay_club/catalog/seed/expansion_classifier.ex` - `expansion?/2`, the two documented module attributes (`@markers`, `@reviewed_overrides`)
- `test/pukllay_club/catalog/seed/expansion_classifier_test.exs` - marker cases, override cases, base-game negatives, nil-name handling, real-CSV regression
- `priv/repo/migrations/20260818222551_add_games_is_expansion.exs` - `add_games_is_expansion` column + literal-SQL backfill mirroring `ExpansionClassifier`
- `lib/pukllay_club/catalog/game.ex` - `is_expansion` field, added to `seed_changeset/2`'s cast list
- `lib/mix/tasks/catalog.seed.ex` - `ExpansionClassifier` alias wired into `build_rows_and_report/1`'s row map and `base_attrs/2`
- `lib/pukllay_club/catalog.ex` - `recent_query/0` filters `is_expansion == false`; `list_carousel_rows/0` docstring records the G-01-5 scope decision
- `test/pukllay_club/catalog_test.exs` - carousel exclusion test, "other 7 rows unaffected" regression, `filter_games`/`count_games` still-findable regression

## Decisions Made
- Marker list is `["(expa", "expansi", "promo"]` — plain lowercase substrings (no regex), chosen specifically so the migration's SQL `ILIKE '%marker%'` backfill can express the identical rule without independently re-deriving word-boundary/escaping semantics
- The 4-row reviewed-override list (`414, 415, 417, 421`) keys on `csv_row` since it is the seed pipeline's stable natural key and `Catalog.upsert_game!/1`'s conflict target
- No index added on `is_expansion` — documented in the migration as a deliberate cost/benefit call given the `LIMIT 20` carousel query over only 434 rows
- Exclusion scope is deliberately narrow to `recent_query/0` only, per the plan's explicit scope-discipline instruction — a member searching for a specific expansion the club owns must still find it

## Deviations from Plan

None - plan executed exactly as written. One incidental correction made and immediately reverted (see Issues Encountered) — not a deviation from the plan's own scope, since it never touched a file in `files_modified`.

## Issues Encountered
- Running `mix catalog.seed --dry-run --report-only` (as specified in the plan's overall `<verification>` section) regenerated `priv/repo/seed_data/catalog_seed_report.md` with a stripped-down report (report-only mode skips the BGG fetch, so BGG-derived sections like "BGG ids with no returned item" and "No Spanish edition found" collapsed to zero). This would have silently destroyed the real seed report committed in 01-04. Caught immediately via `git status`/`git diff`, restored with `git checkout -- priv/repo/seed_data/catalog_seed_report.md` (a single named file, not a blanket reset), and the file was never staged or committed. No lasting effect.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- G-01-5 is closed: `is_expansion` is a real column, all 26 club-confirmed rows carry it in dev, and the next Kamal deploy's migration backfill will bring production data into agreement without re-running the seed pipeline
- No blockers for remaining 01-catalog-v1 gap-closure plans or for end-of-phase UAT re-verification of Test 5

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: lib/pukllay_club/catalog/seed/expansion_classifier.ex
- FOUND: priv/repo/migrations/20260818222551_add_games_is_expansion.exs
- FOUND: test/pukllay_club/catalog/seed/expansion_classifier_test.exs
- FOUND: 7a3ea20, f94bc85, 0ef4ef4, 9896692, 9846086 (all present in `git log --oneline`)

---
*Phase: 01-catalog-v1*
*Completed: 2026-08-18*
