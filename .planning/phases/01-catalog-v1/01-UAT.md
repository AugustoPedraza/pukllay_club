---
status: partial
phase: 01-catalog-v1
source: [01-VERIFICATION.md]
started: 2026-08-11T22:20:11.241Z
updated: 2026-08-18T00:00:00.000Z
---

## Current Test

[testing paused — 1 item outstanding]

## Tests

### 1. Light/dark theme legibility on a real browser
expected: Load `/` in both light and dark theme via the existing toggle (top-right icon group) on a real browser/device. Brand purple/lavender palette renders correctly, Bebas Neue wordmark and Inter body text are legible against both theme backgrounds, matching 01-UI-SPEC.md.
result: pass
note: "Originally failed (CSP blocked R2 img-src, see resolved gap G-01-1). Fixed directly in config/runtime.exs during this session and confirmed working by user — images now load."

### 2. Mobile filter drawer, pills, search, sort, load-more
expected: On a mobile-width viewport, open the Filtros drawer, toggle two mechanic pills, type a search term, change the sort, and press Cargar más. Results update live with no page reload; the drawer trigger and pills are comfortably tappable (44px target).
result: issue
reported: "On a narrow/mobile-width viewport, the game-card weight-band badge (e.g. 'Descubre el hobby') visually overlaps the game title instead of sitting below it. Confirmed via screenshot; not present at full desktop width. No console errors, app.css loads (200/304), all relevant Tailwind/daisyUI classes (card-body, space-y-2, badge-secondary, line-clamp-2, sm:grid-cols-3) confirmed present in the compiled CSS — root cause not yet isolated."
severity: major

### 3. Game detail page gallery swap and field omission
expected: Open a game detail page from a card; confirm the band descriptor reads naturally, the gallery strip visually swaps the main image on thumbnail click, and a no-BGG-enrichment game (one of the 41) renders cleanly with fields simply absent.
result: skipped
reason: "Blocked by the same CSP img-src issue from Test 1 — gallery images not rendering, couldn't meaningfully test"

### 4. Loading-skeleton layout stability
expected: Load the browse page on a throttled connection and visually confirm the grid/carousel skeleton placeholders occupy the correct footprint with no layout shift when real cards replace them.
result: skipped
reason: "Blocked by the same CSP img-src issue from Test 1 — user reports it's blocking basically everything"

### 5. Club sign-off on unresolved/uncovered data exclusions
expected: Read `priv/repo/seed_data/catalog_seed_report.md`'s 26 unresolved-weight-band games and the 39 no-Spanish-edition list, and the 01-VOCABULARY.md "Consciously uncovered" glossary subsection, and confirm the exclusions are acceptable (or correct the source CSV and re-run).
result: pass
note: "Reviewed case-by-case interactively. (1) 26 unresolved weight-band games: all confirmed expansions/promos needing no independent band — 22 self-marked in the CSV Nombre field, 4 more (rows 414/415/417/421) confirmed by user despite no explicit marker. No CSV change needed. (2) 39 no-Spanish-edition games: traced ImagePipeline.select_cover/1 + catalog.seed.ex's image_urls/4 — these games are already fully in the catalog via the existing Spanish-preferred-with-primary-fallback path (verified live in dev DB: Nemesis, Museum, Abyss, COYOTE all present with valid cover URLs); the report section is an informational flag, not an exclusion list. No code/data change needed. (3) 01-VOCABULARY.md 'Consciously uncovered' glossary (43 mechanics + 11 categories): accepted as-is, same rationale (too niche/jargon-heavy) for every term. Found and fixed one transcription artifact — 'Worker Placement, Different Worker Types' is a single compound BGG mechanic value (bgg_client.ex:117 parses one <link> per value) that had been incorrectly split into two comma-separated list items in the doc's prose, fabricating a false duplicate of the already-covered 'Worker Placement' chip. Corrected in 01-VOCABULARY.md to a quoted single term."

### 6. Production deploy verification (post-ship)
expected: Run the production seed per `docs/runbooks/catalog-seed.md` against the Kamal-deployed Postgres accessory, then confirm pukllay.club serves the full 434-game catalog. Note: `main` is not yet pushed/deployed — this test only applies after `/gsd-ship` runs.
result: blocked
blocked_by: prior-phase
reason: "main not yet pushed/deployed — test only applies after /gsd-ship runs"

## Summary

total: 6
passed: 2
issues: 1
pending: 0
skipped: 2
blocked: 1

## Gaps

- gap_id: G-01-1
  truth: "Game cover images (R2-hosted, e.g. https://pub-8f053d9e82db4d8eb43b5666a37546c4.r2.dev/games/253344/cover-thumb.webp) load on the catalog page in a real browser"
  status: resolved
  reason: "User reported: Content-Security-Policy blocked img-src load from https://pub-8f053d9e82db4d8eb43b5666a37546c4.r2.dev/games/253344/cover-thumb.webp — CSP img-src directive only allows 'self' data: https://images.test.invalid, not the real R2 public bucket host"
  severity: major
  test: 1
  root_cause: "config/dev.exs computed the CSP image_origin from the R2_PUBLIC_BASE_URL env var only, at compile time — before config/dev.secret.exs's Application config (which holds the real R2 URL) is merged into Application env. So the CSP always fell back to the images.test.invalid placeholder in local dev."
  artifacts:
    - path: "config/runtime.exs"
      issue: "Added a dev-env-only block that resolves R2_PUBLIC_BASE_URL (env var, then dev.secret.exs's Application config) and overrides :image_origin, mirroring PukllayClub.Catalog.Seed.Credentials' fallback chain."
    - path: "config/dev.exs"
      issue: "Updated comment to point at runtime.exs for the real resolution; placeholder fallback left in place for a fresh clone with no secrets configured."
  missing: []
  resolved_by: "Manual interactive fix during /gsd-verify-work session (not routed through gsd-planner/gap_closure pipeline) — verified via `mix run -e` and browser reload."
  resolved_at: "2026-08-12"

- gap_id: G-01-2
  truth: "The game title and weight-band badge in a catalog card render without overlapping at any viewport width, including narrow/mobile widths"
  status: failed
  reason: "User reported: badge (e.g. 'Descubre el hobby') visually overlaps the game title on a narrow viewport; not present at full desktop width. Card markup is lib/pukllay_club_web/components/game_card.ex (title h3 + GameChips.weight_band_badge), badge/chip rendering is lib/pukllay_club_web/components/game_chips.ex. No absolute/relative-positioned or breakpoint-gated classes found on this markup by an initial source scan, and the compiled app.css contains all expected utility classes — root cause not yet isolated (possibly Firefox-specific line-clamp/box rendering, or something not yet checked)."
  severity: major
  test: 2
  artifacts: []
  missing: []

- gap_id: G-01-3
  truth: "The catalog grid on the main page (/) renders a responsive number of columns per viewport width, with no horizontal scrolling"
  status: failed
  reason: "User reported roughly 20 columns of game cards rendering side by side on the main page, forcing horizontal scrolling. Expected the responsive grid (grid-cols-2 sm:grid-cols-3 lg:grid-cols-4, per lib/pukllay_club_web/live/catalog_live/index.ex:314) to constrain column count per viewport — actual behavior suggests the grid/flex layout isn't wrapping or constraining item width correctly. Not yet investigated."
  severity: major
  test: 2
  artifacts: []
  missing: []

- gap_id: G-01-4
  truth: "The catalog's ~8 sections on the main page are visually distinguishable from one another"
  status: failed
  reason: "User reported all ~8 sections look the same — no clear visual hierarchy, spacing, or heading treatment separating one section from the next. Not yet investigated."
  severity: major
  test: 2
  artifacts: []
  missing: []

- gap_id: G-01-5
  truth: "The 'Recién añadidos' (recently added) section on the main page never includes game expansions"
  status: failed
  reason: "User reported expansions appearing in the 'Recién añadidos' section. Per the Test 5 data review, expansions are only identifiable via text markers in the CSV Nombre field (no dedicated is_expansion column) — this section's query likely needs to exclude them, but the underlying data model/query has not yet been inspected."
  severity: major
  test: 2
  artifacts: []
  missing: []

- gap_id: G-01-6
  truth: "The game card on the main page presents information with clear visual hierarchy (primary vs. secondary fields), matching CLAUDE.md's 'teach complexity, don't overwhelm' UX principle for a casual/new player"
  status: failed
  reason: "User reported the card shows too much information at once with no hierarchy ('overloaded'). Needs a redesign pass prioritizing which fields are primary vs. secondary, not yet investigated or scoped."
  severity: major
  test: 2
  artifacts: []
  missing: []

- gap_id: G-01-7
  truth: "The main-page search input shows a single, clean focus ring when focused, consistent with the rest of the UI's focus styling"
  status: failed
  reason: "User reported the search input renders what looks like a 'double' black border on focus, likely a browser-default outline and a custom Tailwind/daisyUI focus-ring class both applying simultaneously. Not yet investigated."
  severity: minor
  test: 2
  artifacts: []
  missing: []
