---
phase: 01-catalog-v1
plan: 06
subsystem: ui
tags: [phoenix-liveview, csp, sobelow, elixir, i18n]

requires:
  - phase: 01-catalog-v1
    provides: 01-05's Vocabulary module, filter_games/1, and CatalogLive.Index (drawer/search/sort/carousels)
provides:
  - Plain-Spanish weight-band badges with descriptors (never a raw 1-5 number)
  - Curated mechanic/theme/editorial chip rows with +N overflow handling
  - PukllayClubWeb.CatalogLive.Show — the game detail page with gallery thumbnail-swap
  - A real Content-Security-Policy header, closing Phase 0's deferred Sobelow Config.CSP finding
  - A reconciled Vocabulary glossary (35 mechanics, 32 themes) against the real seed report's uncovered-term lists
affects: []

actuals:
  tokens: 9800
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Chip components never read a raw mechanics/themes/tags value directly — every label passes through PukllayClub.Catalog.Vocabulary, the single enforcement point for CATALOG-06"
    - "CSP img-src is derived from the same :pukllay_club, :image_origin config key that mints stored image URLs, so the policy can't drift from where images actually live"
    - "Client-supplied gallery image selection is validated against the game's own [cover_url | gallery_urls] list before being assigned to img src — never echoed unchecked"

key-files:
  created:
    - lib/pukllay_club_web/components/game_chips.ex
    - lib/pukllay_club_web/live/catalog_live/show.ex
    - lib/pukllay_club_web/csp.ex
    - test/pukllay_club_web/components/game_chips_test.exs
    - test/pukllay_club_web/live/catalog_show_test.exs
  modified:
    - lib/pukllay_club_web/components/game_card.ex
    - lib/pukllay_club/catalog.ex
    - lib/pukllay_club/catalog/vocabulary.ex
    - lib/pukllay_club_web/router.ex
    - .sobelow-conf
    - .planning/phases/01-catalog-v1/01-VOCABULARY.md

key-decisions:
  - "weight_band_badge/1 renders nothing (no badge, no descriptor) for a nil band rather than a placeholder — matches the plan's planner_assumption omission table"
  - "Editorial hashtag chips use one uniform badge bg-accent text-accent-content treatment for all six tags — no per-hashtag color, per 01-UI-SPEC.md"
  - "CatalogLive.Show validates an incoming image-select url against the game's own cover_url/gallery_urls list before assigning it, rather than trusting the client event payload"
  - "CSP applied via a private put_csp/2 plug in the router's :browser pipeline (after put_secure_browser_headers) rather than trying to make Sobelow's static Config.CSP check see it directly — the .sobelow-conf exemption documents why the check can't observe a header set by a separate plug"
  - "Glossary reconciliation added only uncovered terms occurring on 8+ seeded games (10 mechanics, 10 themes); the rest are recorded as consciously uncovered in 01-VOCABULARY.md rather than added speculatively"

patterns-established:
  - "Per-field omission table (this plan's planner_assumption): an absent optional field removes its rendered element entirely — never a blank, a zero, or an empty label"

requirements-completed: [CATALOG-05, CATALOG-06, CATALOG-07]

coverage:
  - id: D1
    description: "Weight bands render as a plain-Spanish label plus one-line descriptor; the raw bgg_weight number never reaches a template"
    requirement: "CATALOG-05"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/game_chips_test.exs"
        status: pass
      - kind: other
        ref: "grep -rc 'bgg_weight' lib/pukllay_club_web/ -> 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Mechanic/theme chips render only curated Spanish labels; uncovered raw BGG strings never reach a member's screen"
    requirement: "CATALOG-06"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/game_chips_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "All six club editorial hashtags render verbatim with one uniform chip treatment"
    requirement: "CATALOG-07"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/game_chips_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "Game detail page (CatalogLive.Show) renders full chip lists, gallery thumbnail-swap, metadata, and 404s on a nonexistent id"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "Content-Security-Policy header present on every browser response, img-src scoped to self/data:/configured image origin, no BGG origin ever allowed"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs (Content-Security-Policy describe block)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Vocabulary glossary reconciled against the real seed report's uncovered-term lists"
    verification:
      - kind: other
        ref: "lib/pukllay_club/catalog/vocabulary.ex (@mechanics 35 entries, @themes 32 entries); .planning/phases/01-catalog-v1/01-VOCABULARY.md consciously-uncovered section"
        status: pass
    human_judgment: false

duration: ~2h active
completed: 2026-08-11
status: complete
---

# Phase 01 Plan 06: Complexity-teaching UX — bands, chips, detail page, CSP Summary

**Weight-band badges with plain-Spanish descriptors, curated chip rows, a full game detail page with gallery thumbnail-swap, and a real Content-Security-Policy that closes Phase 0's deferred Sobelow finding.**

## Performance

- **Duration:** ~2h active work
- **Tasks:** 3
- **Files modified:** 16

## Accomplishments
- `PukllayClubWeb.GameChips` (`weight_band_badge/1`, `chip_row/1`, `editorial_tags/1`) renders every complexity/mechanic/theme/editorial signal in plain Spanish — no raw `bgg_weight` number and no uncovered raw BGG string ever reaches a template
- `GameCard` composes the chip components with the plan's per-field omission table applied uniformly (absent field -> no element, never a blank/zero/empty label), plus a runtime `onerror` fallback to the brand placeholder for failed image loads
- `PukllayClubWeb.CatalogLive.Show` — the game detail page at `/juegos/:id`, with full (non-truncated) chip lists, gallery thumbnail-swap (validated against the game's own `[cover_url | gallery_urls]`, never trusting the client event payload directly), and a 404 (not a crash) for a nonexistent id
- `PukllayClubWeb.CSP.policy/0` plus a `put_csp/2` router plug apply a real Content-Security-Policy to every browser response, closing the `.sobelow-conf` `Config.CSP` deferral from Phase 0, with `img-src` scoped to the app's own configured image origin and never a BGG host
- `Catalog.Vocabulary`'s mechanic and theme glossaries reconciled against `priv/repo/seed_data/catalog_seed_report.md`'s real "uncovered terms" output from the 01-04 full seed run (25->35 mechanics, 22->32 themes), with consciously-uncovered terms recorded in `01-VOCABULARY.md`

## Task Commits

Each task was committed atomically:

1. **Task 1: Weight-band badge, plain-Spanish chips, and editorial hashtag chips** - `f6e196a` (test), `5ced12f` (feat)
2. **Task 2: Game detail page with gallery and full vocabulary** - `50e8b47` (test), `59e7ed5` (feat)
3. **Task 3: CSP header and glossary reconciliation** - `5eb00a9` (feat)

_Note: Tasks 1 and 2 are TDD tasks with a red test commit followed by a green implementation commit._

## Files Created/Modified
- `lib/pukllay_club_web/components/game_chips.ex` - weight_band_badge/1, chip_row/1, editorial_tags/1
- `lib/pukllay_club_web/components/game_card.ex` - composes the chip components, image onerror fallback, links Ver detalles to the detail route
- `lib/pukllay_club_web/live/catalog_live/show.ex` - PukllayClubWeb.CatalogLive.Show, the game detail page
- `lib/pukllay_club/catalog.ex` - get_game!/1
- `lib/pukllay_club_web/router.ex` - /juegos/:id route, put_csp plug in the :browser pipeline
- `lib/pukllay_club_web/csp.ex` - PukllayClubWeb.CSP.policy/0
- `.sobelow-conf` - Config.CSP exemption rationale updated to point at the closing implementation
- `lib/pukllay_club/catalog/vocabulary.ex` - glossary reconciliation (35 mechanics, 32 themes)
- `.planning/phases/01-catalog-v1/01-VOCABULARY.md` - records the reconciliation and consciously-uncovered terms
- `test/pukllay_club_web/components/game_chips_test.exs`, `test/pukllay_club_web/live/catalog_show_test.exs`, `test/pukllay_club_web/live/catalog_live_test.exs`, `test/pukllay_club/catalog/vocabulary_test.exs` - test coverage

## Decisions Made
- `weight_band_badge/1` renders nothing at all for a nil band (no placeholder), matching the plan's per-field omission table
- CSP applied via a separate `put_csp/2` plug rather than trying to satisfy Sobelow's static `Config.CSP` check directly — the check inspects `put_secure_browser_headers`'s own call arguments and structurally cannot see a header set by a different plug, which is why `.sobelow-conf`'s exemption still needs to exist even though the finding is now genuinely closed
- Glossary reconciliation was scoped to uncovered terms appearing on 8+ seeded games rather than every uncovered term in the report, to keep the glossary curated rather than exhaustive

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness
- Phase 01 (catalog-v1) is now feature-complete across all 6 plans: prerequisites, brand identity, tracer, full 434-game seed with search indexes, browse (filter/search/sort/carousels), and this plan's complexity-teaching UX + detail page + CSP
- No blockers for phase verification

---
*Phase: 01-catalog-v1*
*Completed: 2026-08-11*
