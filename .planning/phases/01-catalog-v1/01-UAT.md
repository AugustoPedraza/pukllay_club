---
status: testing
phase: 01-catalog-v1
source: [01-VERIFICATION.md]
started: 2026-08-11T22:20:11.241Z
updated: 2026-08-11T22:20:11.241Z
---

## Current Test

number: 1
name: Light/dark theme legibility on a real browser
expected: |
  Brand purple/lavender palette renders correctly, Bebas Neue wordmark and Inter body text are
  legible against both theme backgrounds, matching 01-UI-SPEC.md.
awaiting: user response

## Tests

### 1. Light/dark theme legibility on a real browser
expected: Load `/` in both light and dark theme via the existing toggle (top-right icon group) on a real browser/device. Brand purple/lavender palette renders correctly, Bebas Neue wordmark and Inter body text are legible against both theme backgrounds, matching 01-UI-SPEC.md.
result: [pending]

### 2. Mobile filter drawer, pills, search, sort, load-more
expected: On a mobile-width viewport, open the Filtros drawer, toggle two mechanic pills, type a search term, change the sort, and press Cargar más. Results update live with no page reload; the drawer trigger and pills are comfortably tappable (44px target).
result: [pending]

### 3. Game detail page gallery swap and field omission
expected: Open a game detail page from a card; confirm the band descriptor reads naturally, the gallery strip visually swaps the main image on thumbnail click, and a no-BGG-enrichment game (one of the 41) renders cleanly with fields simply absent.
result: [pending]

### 4. Loading-skeleton layout stability
expected: Load the browse page on a throttled connection and visually confirm the grid/carousel skeleton placeholders occupy the correct footprint with no layout shift when real cards replace them.
result: [pending]

### 5. Club sign-off on unresolved/uncovered data exclusions
expected: Read `priv/repo/seed_data/catalog_seed_report.md`'s 26 unresolved-weight-band games and the 39 no-Spanish-edition list, and the 01-VOCABULARY.md "Consciously uncovered" glossary subsection, and confirm the exclusions are acceptable (or correct the source CSV and re-run).
result: [pending]

### 6. Production deploy verification (post-ship)
expected: Run the production seed per `docs/runbooks/catalog-seed.md` against the Kamal-deployed Postgres accessory, then confirm pukllay.club serves the full 434-game catalog. Note: `main` is not yet pushed/deployed — this test only applies after `/gsd-ship` runs.
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps

None — all automated checks passed (140/140 tests, `mix quality` clean, 5/5 ROADMAP.md success criteria and 47/47 plan-level must-have truths independently re-verified against the live codebase and a real running server). The 6 items above require human judgment or a real browser/deploy step that automated verification cannot substitute for.
