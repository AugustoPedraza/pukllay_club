---
phase: 01-catalog-v1
plan: 05
subsystem: catalog
tags: [phoenix-liveview, ecto, postgres-fts, gin, daisyui, streams, elixir]

requires:
  - phase: 01-catalog-v1 (01-04)
    provides: full 434-game seed, search_vector generated tsvector column (spanish_unaccent config), GIN indexes on search_vector/mechanics/themes/tags
  - phase: 01-catalog-v1 (01-03)
    provides: PukllayClub.Catalog context boundary, CatalogLive.Index tracer, GameCard component
provides:
  - PukllayClub.Catalog.Vocabulary — the plain-Spanish mechanic/theme/weight-band/editorial-tag vocabulary, copied verbatim from 01-VOCABULARY.md
  - Catalog.filter_games/1 and .count_games/1 — one composed query for search + OR-within-facet filtering + AND-across-facets + scalar filters + sort + pagination
  - Catalog.facet_options/0 and .list_carousel_rows/0 (8 fixed D-09 rows)
  - Live-updating filter drawer (FilterDrawer), search box, sort control, load-more grid on CatalogLive.Index
  - CarouselRow component (carousel_row/1, skeleton_row/1, skeleton_card/1) and the two-phase (disconnected→connected) loading-skeleton pattern
affects: [01-06]

actuals:
  tokens: 15400
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "One composed maybe_* Ecto pipeline (search, facets, scalars, sort, pagination) rather than branching search-mode vs filter-mode, per 01-RESEARCH.md Pattern 3"
    - "OR-within-facet via array-overlap && fragment (never @>, which is AND/contains) — verified by grep gate in the plan's own acceptance criteria"
    - "apply_filters/1 as the single funnel that resets pagination + resets the :games stream on every filter-changing event; load-more is the only appending path (01-RESEARCH.md Pattern 4)"
    - "LiveView two-phase (disconnected/connected) mount trick for loading skeletons: :loading = not connected?(socket), set once in mount, drives skeleton branches with zero added latency machinery"
    - "Catalog reads wrapped in a rescue -> :load_error assign so a crafted/oversized scalar value degrades to the UI-SPEC error banner instead of an Elixir stacktrace (T-01-24), verified with a genuine DBConnection.EncodeError trigger through the public event interface"

key-files:
  created:
    - lib/pukllay_club/catalog/vocabulary.ex
    - lib/pukllay_club_web/components/filter_drawer.ex
    - lib/pukllay_club_web/components/carousel_row.ex
    - test/pukllay_club/catalog_test.exs
    - test/pukllay_club/catalog/vocabulary_test.exs
  modified:
    - lib/pukllay_club/catalog.ex
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - lib/pukllay_club_web/components/game_card.ex
    - test/pukllay_club_web/live/catalog_live_test.exs
    - test/support/fixtures/catalog_fixtures.ex

key-decisions:
  - "The 8 carousel rows are: destacados_del_club, 3 editorial-hashtag rows, 3 weight-band rows, recientemente_anadidos — resolving an internal plan ambiguity where the Task 1 prose only named 5 rows but the plan's own Artifacts section and Task 3's '8 carousel rows' behavior bullet both require weight-band rows too; the artifact list + explicit row count were treated as authoritative over the abbreviated prose"
  - "Sort/facet-key parsing from client strings uses explicit case/cond clauses (never String.to_atom/1), matching AGENTS.md's memory-leak guidance and the plan's own T-01-23 mitigation"
  - "GameCard gained an optional :class passthrough attr so the same component renders correctly at grid width and at carousel-rail width, without CarouselRow needing to know GameCard's internals"
  - "Loading-skeleton visibility uses the LiveView disconnected-vs-connected two-phase mount (:loading = not connected?(socket)), not a real async fetch — Catalog reads are synchronous and fast at this row count, so this is the standard technique for painting instantly on first byte rather than a timing simulation"

patterns-established:
  - "maybe_* private-function query composition pipeline in a context (Catalog.filter_games/1) as the standard shape for any future multi-predicate LiveView query in this app"
  - "Test helper scoping via LazyHTML.query/2 (e.g. #games, #carousel-rows) to isolate grid-card assertions from carousel-card assertions on the same rendered page — needed once a page has more than one region reusing the same component"

requirements-completed: [CATALOG-01, CATALOG-02, CATALOG-03, CATALOG-04]

coverage:
  - id: D1
    description: "A member with no account filters the catalog by player count, playtime, mechanic/theme, and minimum age; results update immediately with no Apply button (CATALOG-02, D-12)"
    requirement: "CATALOG-02"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog_test.exs — min_players/max_playtime/min_age filter tests"
        status: pass
      - kind: integration
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — 'typing into the search input re-renders...', 'toggling a mechanic pill re-renders...'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Two mechanic pills return games matching EITHER (OR within facet); a mechanic + theme pill together narrows to AND across facets (D-14)"
    requirement: "CATALOG-02"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog_test.exs — 'two mechanic labels return games matching EITHER', 'the OR-within-facet result set is strictly larger than the AND-of-both-mechanics result set', 'one mechanic label and one theme label return only games matching both facets'"
        status: pass
      - kind: other
        ref: "grep -c '@>' lib/pukllay_club/catalog.ex == 0; grep -c '&&' present"
        status: pass
    human_judgment: false
  - id: D3
    description: "The single search box narrows the currently-filtered results by title/designer/publisher without clearing active filters (CATALOG-03, D-15)"
    requirement: "CATALOG-03"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog_test.exs — search-matches-title/designer/publisher, accent-free spelling, search+mechanic combined, adversarial input"
        status: pass
      - kind: integration
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — 'search text and an active mechanic pill apply together — clearing search restores the pill-filtered set'"
        status: pass
    human_judgment: false
  - id: D4
    description: "A member sorts by playtime and by complexity and the order changes accordingly, with null sort keys sorting last (CATALOG-04)"
    requirement: "CATALOG-04"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog_test.exs — 'sort: :playtime_asc and sort: :complexity_desc produce different, correctly-ordered results', 'sort: :complexity_asc places a game with a null weight_band after every banded game'"
        status: pass
      - kind: integration
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — 'changing the sort control reorders the rendered cards'"
        status: pass
    human_judgment: false
  - id: D5
    description: "Filter facet labels are plain-Spanish glossary terms; no raw English BGG mechanic/category string is ever offered as a filter option (CATALOG-06 — filter-surface portion only)"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog/vocabulary_test.exs — mechanic_options()==25, theme_options()==22, mechanic_label/theme_label round-trips"
        status: pass
    human_judgment: false
  - id: D6
    description: "The browse page opens with curated carousel rows (Destacados/editorial hashtags/weight bands/Recientemente añadidos) above the full grid, stepping aside while a filter is active (D-08, D-09)"
    verification:
      - kind: integration
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — 8-row-order test, zero-games-row-renders-nothing test, carousel-absent-when-filtered test"
        status: pass
      - kind: other
        ref: "grep -c 'carousel-item' and 'skeleton' lib/pukllay_club_web/components/carousel_row.ex >= 1"
        status: pass
    human_judgment: false
  - id: D7
    description: "Filters live in a slide-over drawer (not a sidebar), with 44px touch targets on the trigger and pills (D-13)"
    verification:
      - kind: other
        ref: "grep -c 'drawer-side' filter_drawer.ex >= 1; grep -c 'min-h-11' filter_drawer.ex >= 2"
        status: pass
    human_judgment: false
  - id: D8
    description: "The grid paginates via a Cargar más button (not infinite scroll); pressing it appends without re-rendering existing cards, and any filter change resets pagination to page 1"
    verification:
      - kind: integration
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — 'pressing Cargar más appends the next page...', 'changing any filter resets pagination back to the first page'"
        status: pass
    human_judgment: false
  - id: D9
    description: "Result count reads in correct Spanish singular/plural; zero-result state renders the empty-state heading/body/Limpiar filtros; a catalog query failure renders the inline error banner instead of crashing"
    verification:
      - kind: integration
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — result-count singular/plural test, empty-state + Limpiar filtros test, query-exception error-banner test (genuine DBConnection.EncodeError trigger)"
        status: pass
    human_judgment: false
  - id: D10
    description: "The catalog grid and each carousel row show skeleton card placeholders while the initial query is in flight, with no layout jump when real content arrives"
    verification:
      - kind: manual_procedural
        ref: "mix phx.server + curl http://localhost:4000/ (disconnected first response): confirmed 354 'skeleton' occurrences and 48 'carousel-item' occurrences, and zero leaked real carousel titles, in the disconnected-render HTML"
        status: pass
    human_judgment: true
    rationale: "01-UI-SPEC.md marks both loading states as backstops with no visual mock — true pixel-level 'does the skeleton footprint match a populated card with no shift' confirmation needs an actual browser render. This plan verified the correct markup renders at the correct volume via a real running dev server (not just unit tests), which is the strongest automatable proxy available in this headless execution environment. Full visual sign-off is deferred to the project's configured `human_verify_mode: end-of-phase` gate, per .planning/config.json — not a per-plan checkpoint."

duration: ~26min (commit-span; excludes upfront context-reading time)
completed: 2026-08-11
status: complete
---

# Phase 01 Plan 05: Browse — carousels, live filtering, sort, and Spanish keyword search Summary

**The tracer's minimal grid became the full CATALOG-02/03/04 browse experience: one composed Ecto query serves OR-within-facet mechanic/theme pills, AND-across-facets, scalar player/playtime/age filters, Spanish accent-insensitive keyword search, and sort — all live-updating with no submit button — plus 8 fixed curated carousel rows and a genuine two-phase loading-skeleton treatment, against the real 434-game catalog.**

## Performance

- **Duration:** ~26 min (span between first and last task commit; excludes upfront context-reading)
- **Started:** 2026-08-11T12:18:35-03:00
- **Completed:** 2026-08-11T12:44:03-03:00
- **Tasks:** 3
- **Files modified:** 10 (5 created, 5 modified)

## Accomplishments

- `PukllayClub.Catalog.Vocabulary` holds the weight bands, 3 editorial hashtags, 25-term mechanic glossary, and 22-term theme glossary copied verbatim from 01-VOCABULARY.md — the only mechanic/theme surface the rest of the app touches
- `Catalog.filter_games/1` composes search (`websearch_to_tsquery` against the `spanish_unaccent` `search_vector`), OR-within-facet mechanic/theme/tag filters (`&&`, never `@>`), AND-across-facets, scalar player/playtime/min-age filters, six sort orders with nulls-last, and pagination into one `maybe_*` pipeline — verified with adversarial search input, a real 434-row-scale accent test, and an explicit OR-vs-AND count comparison
- `CatalogLive.Index` now holds full filter state in assigns; every filter-changing event funnels through `apply_filters/1`, the single place that resets pagination and the `:games` stream; `"load-more"` is the only appending path
- `FilterDrawer` renders a daisyUI `drawer-side` slide-over with OR-toggle facet pills (44px touch targets) and a single `set-scalar` form for player count/playtime/min age
- `CarouselRow` renders the 8 fixed D-09 rows (Destacados del club, 3 editorial hashtags, 3 weight bands, Recientemente añadidos) above the grid, stepping aside whenever a filter or search term is active, with a genuine disconnected/connected two-phase loading-skeleton treatment verified live against a running `mix phx.server`
- Catalog query failures (verified with a real oversized-integer `DBConnection.EncodeError`, not a simulated stub) render the UI-SPEC error banner instead of crashing the LiveView

## Task Commits

Each task was committed atomically (TDD: separate RED test commit + GREEN implementation commit per task):

1. **Task 1: Vocabulary module and the single composed catalog query** — `818f49b` (test), `95caa7d` (feat)
2. **Task 2: Live filter drawer, search box, sort control, and load-more grid** — `168b781` (test), `6cacc74` (feat)
3. **Task 3: Curated carousel rows and skeleton loading placeholders** — `eaf2af0` (test), `510aec3` (feat)

## Files Created/Modified

- `lib/pukllay_club/catalog/vocabulary.ex` — weight_bands/0, weight_band/1, editorial_tags/0, mechanic_label/1, theme_label/1, mechanic_terms_for/1, theme_terms_for/1, covered_mechanics/1, covered_themes/1, mechanic_options/0, theme_options/0
- `lib/pukllay_club/catalog.ex` — filter_games/1, count_games/1, facet_options/0, list_carousel_rows/0, the `maybe_*` predicate pipeline, `normalize_sort/1`
- `lib/pukllay_club_web/components/filter_drawer.ex` — FilterDrawer.filter_drawer/1, private facet_pill/1
- `lib/pukllay_club_web/components/carousel_row.ex` — CarouselRow.carousel_row/1, .skeleton_row/1, .skeleton_card/1
- `lib/pukllay_club_web/live/catalog_live/index.ex` — full filter-state assigns, apply_filters/1, handle_event for search/toggle-facet/set-scalar/sort/clear-filters/load-more, two-phase :loading gate, carousel + grid skeleton rendering
- `lib/pukllay_club_web/components/game_card.ex` — added optional `:class` passthrough attr for grid vs. carousel-rail sizing
- `test/pukllay_club/catalog_test.exs`, `test/pukllay_club/catalog/vocabulary_test.exs` — 34 tests total covering every `<behavior>` bullet plus acceptance-criteria-specific assertions
- `test/pukllay_club_web/live/catalog_live_test.exs` — extended from 6 to 20 tests (filter/search/sort/pagination/empty/error + carousel/skeleton coverage)
- `test/support/fixtures/catalog_fixtures.ex` — default `mechanics`/`themes` switched to raw BGG-glossary-covered values so fixtures exercise the real Vocabulary translation path

## Decisions Made

- Resolved an internal plan ambiguity: Task 1's prose named only 5 carousel rows (Destacados, 3 editorial hashtags, Recientemente añadidos), but the plan's own "New carousel row keys" artifact list and Task 3's "renders 8 carousel rows" behavior bullet both require 3 additional weight-band rows. Implemented the 8-row set (matching the explicit count and the artifact list) rather than the under-specified prose.
- Client-supplied sort/facet keys are matched against closed sets of literal string clauses (never `String.to_atom/1`), both in `Catalog.normalize_sort/1` and `CatalogLive.Index.parse_sort/1` — defense in depth against T-01-23, matching AGENTS.md's memory-leak guidance.
- `GameCard` gained an optional `:class` attr so the same component serves both the grid and the horizontally-scrolling carousel rail without either caller needing to know the other's layout.
- The loading-skeleton state uses LiveView's standard disconnected/connected two-phase mount (`:loading = not connected?(socket)`), not an artificial delay — Catalog reads are synchronous and fast at ~434 rows, so this technique paints instantly on first byte and is the correct fit rather than simulating async latency that doesn't exist.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Whole-page substring test assertions collided once carousel rows and the grid both render `GameCard`/pill markup with the same class strings**
- **Found during:** Task 3, running the newly-added carousel-order and sort tests
- **Issue:** `card_count/1` and `position/2` test helpers searched the entire rendered page. Once Task 3 added carousel rows (which reuse `GameCard`'s `"card bg-base-200"` classes) and weight-band facet pills (whose labels — "Descubre el hobby", "Ingenio estratega", "Nivel experto" — are identical strings to the carousel row titles), two tests broke: a card count that expected 24 counted 104 (grid + all carousel cards), and a sort-order position test found the wrong (drawer-pill) occurrence of a weight-band label string.
- **Fix:** Scoped the affected test helpers with `LazyHTML.query/2` against `#games` (grid) and `#carousel-rows` (carousel section) so assertions target the correct DOM region instead of the whole page.
- **Files modified:** `test/pukllay_club_web/live/catalog_live_test.exs`
- **Verification:** All 20 LiveView tests pass; full suite green.
- **Committed in:** `510aec3` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (test-only, no production code bug). No scope creep.

## Issues Encountered

None beyond the deviation above. `mix quality` passed on every task with only the two pre-existing, already-accepted findings (Credo's `Design.AliasUsage` note on `core_components.ex`, Sobelow's four low-confidence `Traversal.FileModule` findings on the seed pipeline's `File.stream!`/`File.write!` calls) — neither newly introduced by this plan.

## User Setup Required

None.

## Next Phase Readiness

- `Catalog.Vocabulary`, `filter_games/1`, `facet_options/0`, and `list_carousel_rows/0` are the stable read surface 01-06 (weight-band chips, mechanic/theme chip rendering on `GameCard`, and the game detail page) extends.
- `GameCard`'s `Ver detalles` CTA is still the inert button from 01-03 — the detail-page route (`GameLive.Show`) remains explicit 01-06 scope, unchanged by this plan.
- 01-06 is also where the glossary gets its planned real-data review pass (per 01-VOCABULARY.md's own "Follow-up built into the plan" note): `catalog_seed_report.md`'s uncovered-mechanic/category list should be checked against `Vocabulary`'s 25/22-term coverage before the theme glossary is treated as final — not done in this plan, not required by it.
- No blockers for 01-06.

## Known Stubs

None new. (01-03's pre-existing `Ver detalles` inert-button stub remains, tracked there — explicitly 01-06 scope, unaffected by this plan.)

## Self-Check: PASSED

All 10 listed files confirmed present on disk; all 6 task commits (`818f49b`, `95caa7d`, `168b781`, `6cacc74`, `eaf2af0`, `510aec3`) confirmed in `git log`.

---
*Phase: 01-catalog-v1*
*Completed: 2026-08-11*
