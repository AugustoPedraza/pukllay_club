---
status: diagnosed
phase: 01-catalog-v1
source: [01-VERIFICATION.md]
started: 2026-08-11T22:20:11.241Z
updated: 2026-08-18T18:54:00.000Z
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
  root_cause: "daisyUI's .badge component (used unmodified by GameChips.weight_band_badge/1 in lib/pukllay_club_web/components/game_chips.ex, called from lib/pukllay_club_web/components/game_card.ex with label 'Descubre el hobby') sets a FIXED single-line height:var(--size) (~21px) but sets neither white-space:nowrap nor overflow:hidden, while also setting width:fit-content (a shrink-to-fit width a flex/grid ancestor is free to compress). The badge sits as a flex-column sibling of the title <h3> inside daisyUI's .card-body (flex-direction:column, gap:8px), inside a catalog grid cell that is only minmax(0,1fr)-wide (grid-cols-2 on index.ex, no explicit card width unlike carousel_row.ex's fixed w-40/w-48). At narrow/mobile viewports (below the sm: 640px breakpoint, 2 columns), each card's available content width (~130-160px after grid gap + card-body p-4 padding) drops below the natural single-line width of the 3-word label 'Descubre el hobby' (~145-155px). width:fit-content clamps the badge to the narrower available width, the text wraps to 2 lines (default white-space:normal), but height stays pinned at the single-line 21px value. With no overflow:hidden, the vertically-centered 2-line text bleeds outside the fixed-height box both upward and downward — the upward bleed crosses the 8px card-body flex gap and collides with the h3 title above it. Pure flexbox box-sizing math, not Firefox-specific; reproduces in any browser only at column widths narrow enough to force the wrap, matching 'not present at full desktop width' exactly."
  artifacts:
    - path: "lib/pukllay_club_web/components/game_chips.ex"
      issue: "weight_band_badge/1 renders daisyUI's default .badge span with no override for its fixed single-line height or missing white-space:nowrap/overflow:hidden, so a wrapping 3-word label (e.g. 'Descubre el hobby') bleeds outside the badge box at narrow (2-column, <640px) grid widths and collides with the title above it."
  missing:
    - "Override badge rendering so a wrapped/long weight-band label cannot exceed its box: either constrain to one line (whitespace-nowrap + overflow-hidden + text ellipsis/truncate, verifying the label still reads at narrow widths) or let the box grow with its content (remove reliance on the fixed --size height, e.g. h-auto/py adjustments) so a second line is never clipped or bleeding — precise approach left to gap-closure planning, consulting ui-design-system for the approved badge/chip pattern."
  debug_session: ".planning/debug/G-01-2-badge-title-overlap.md"

- gap_id: G-01-3
  truth: "The catalog grid on the main page (/) renders a responsive number of columns per viewport width, with no horizontal scrolling"
  status: failed
  reason: "User reported roughly 20 columns of game cards rendering side by side on the main page, forcing horizontal scrolling. Expected the responsive grid (grid-cols-2 sm:grid-cols-3 lg:grid-cols-4, per lib/pukllay_club_web/live/catalog_live/index.ex:314) to constrain column count per viewport — actual behavior suggests the grid/flex layout isn't wrapping or constraining item width correctly. Not yet investigated."
  severity: major
  test: 2
  root_cause: "NOT a defect in the responsive #games grid at lib/pukllay_club_web/live/catalog_live/index.ex:314 — its grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4 classes are correctly compiled, unconflicted, and correctly escalate by breakpoint (verified against priv/static/assets/css/app.css). The reported '~20 columns side by side, forcing horizontal scrolling' matches the BY-DESIGN behavior of the CarouselRow component (lib/pukllay_club_web/components/carousel_row.ex), rendered as one of 8 D-09 carousel rows ABOVE the grid on the same unfiltered landing page. It uses daisyUI's .carousel (display:inline-flex; overflow-x:scroll, no wrap) + .carousel-item (flex:none) — an intentional horizontal-scrolling rail, not a wrapping grid. Each row is capped at exactly @carousel_limit = 20 games (lib/pukllay_club/catalog.ex:21), a near-exact numeric match to the user's 'roughly 20' observation (vs. @page_size = 24, the grid's actual page size). Contributing factor: daisyUI's .carousel also sets scrollbar-width:none, hiding the native scrollbar — removing the visual cue that the row is meant to scroll, plausibly causing the misattribution of this intentional carousel behavior to 'the grid isn't responsive.'"
  artifacts:
    - path: "lib/pukllay_club_web/live/catalog_live/index.ex"
      issue: "Lines 305-319 — the actual responsive grid; confirmed correct, not the source of the reported symptom."
    - path: "lib/pukllay_club_web/components/carousel_row.ex"
      issue: "Likely actual source of the observed horizontal-scroll behavior — this is by design (daisyUI .carousel), not a bug."
    - path: "lib/pukllay_club/catalog.ex"
      issue: "@carousel_limit = 20 (line 21) governs each carousel row's item count — matches the reported '~20 columns' exactly."
  missing:
    - "Not a code fix — needs re-verification with the user (screenshot or live walkthrough) to confirm whether they were looking at a carousel row or the #games grid."
    - "If it was a carousel row: close as 'working as designed'; optionally file a smaller UX improvement for a visible scroll affordance (arrows/peek/fade edge) since scrollbar-width:none hides the only native scroll cue — consult ui-design-system/ux-patterns for the approved carousel affordance pattern."
    - "If the user can still reproduce a genuinely unresponsive #games grid after re-verification, that falsifies this hypothesis and needs a live browser re-investigation (devtools computed styles), not further static review."
  debug_session: ".planning/debug/G-01-3-catalog-grid-overflow.md"

- gap_id: G-01-4
  truth: "The catalog's ~8 sections on the main page are visually distinguishable from one another"
  status: failed
  reason: "User reported all ~8 sections look the same — no clear visual hierarchy, spacing, or heading treatment separating one section from the next. Not yet investigated."
  severity: major
  test: 2
  root_cause: "Two combined markup-level omissions. (1) CarouselRow.carousel_row/1 (lib/pukllay_club_web/components/carousel_row.ex:23) renders an identical, unvaried <h2 class=\"font-display text-2xl\">{@title}</h2> for every one of the 8 D-09 rows — regardless of whether the row is the curated hero row ('Destacados del club'), a per-hashtag row, a per-weight-band row, or the recency row. No attr passes weight/color/variant per row, so the design system's own documented emphasis lever ('weight and color, not a new size, are the emphasis lever') is never exercised. (2) CatalogLive.Index.render/1 (lib/pukllay_club_web/live/catalog_live/index.ex, between the #carousel-rows block ending at line 284 and the #games grid starting at line 305) gives the main grid — the 9th and most prominent section — NO heading at all; the only text there is <p class=\"text-neutral text-sm\">{result_count_text(@total)}</p>, styled as muted/secondary text by this repo's own convention, not a section label. Together: every section boundary either repeats the exact same heading style (all 8 carousel rows) or has none (the grid) — functionally identical to 'no clear visual hierarchy.' Ruled out: inter-section pixel spacing — space-y-8 on the #carousel-rows wrapper (index.ex:270) is the only occurrence of that value in the whole app and is MORE generous than the documented space-y-6 convention, so spacing is not the deficiency."
  artifacts:
    - path: "lib/pukllay_club_web/components/carousel_row.ex"
      issue: "Line 23 — hardcoded, unvaried font-display text-2xl heading for all 8 rows regardless of semantic type (curated/hero, per-hashtag, per-weight-band, recency)."
    - path: "lib/pukllay_club_web/live/catalog_live/index.ex"
      issue: "Lines 284-305 — main grid section has no heading element at all; only a muted result-count line."
    - path: "lib/pukllay_club/catalog.ex"
      issue: "Lines 138-159 — list_carousel_rows/0 defines 4 semantically distinct row types that get flattened to one visual treatment on render."
  missing:
    - "Give the curated/hero row ('Destacados del club') a distinct weight/color treatment from the other 7 rows, per ui-design-system's 'weight and color, not size' emphasis rule."
    - "Add a matching font-display heading (e.g. 'Todo el catálogo') to the main grid section so it reads as its own section rather than trailing off a muted result-count line."
    - "Consult ui-design-system during gap-closure planning for the exact token combination (weight/color values) to use."
  debug_session: ".planning/debug/G-01-4-section-hierarchy.md"

- gap_id: G-01-5
  truth: "The 'Recién añadidos' (recently added) section on the main page never includes game expansions"
  status: failed
  reason: "User reported expansions appearing in the 'Recién añadidos' section. Per the Test 5 data review, expansions are only identifiable via text markers in the CSV Nombre field (no dedicated is_expansion column) — this section's query likely needs to exclude them, but the underlying data model/query has not yet been inspected."
  severity: major
  test: 2
  root_cause: "Two jointly-necessary causes (AND-gate). (1) [data] The Game schema has no is_expansion/parent_game_id column at all — the only expansion signal is a free-text marker embedded in the Nombre field (e.g. '(expa)', 'Expansión', 'Expansion'), never parsed out during seeding; weight_band being nil is not a safe proxy either since it's also nil for several genuine base games lacking a BGG_ID. (2) [code] recent_query/0 in lib/pukllay_club/catalog.ex (backing the :recientemente_anadidos row) applies ZERO filter — order_by: [desc: g.inserted_at, desc: g.csv_row], limit: 20 — unlike sibling queries (weight_band_query/1, tags_query/1) which at least filter on a real column. The source CSV (priv/repo/seed_data/ludoteca.csv) physically clusters nearly all expansion/promo rows as a contiguous block at the very tail of the sheet (lines 2794-2818 of 2817, csv_row ~410-435 of 434). Because mix catalog.seed inserts rows strictly in ascending CSV order, inserted_at is monotonically correlated with csv_row for this single bulk-seed run — so the query's inserted_at desc sort collapses to 'return the highest-csv_row rows first,' exactly the expansions tail block. list_carousel_rows/0's own docstring already self-documents the ordering mechanism ('effectively reverse-CSV order') but frames it only as a staleness quirk, not this specific expansion-surfacing failure."
  artifacts:
    - path: "lib/pukllay_club/catalog.ex"
      issue: "recent_query/0 (~line 178) and list_carousel_rows/0 (~line 138) — the query rendering 'Recientemente añadidos' has no expansion exclusion filter."
    - path: "lib/pukllay_club/catalog/game.ex"
      issue: "Schema has no field to filter expansions on even if the query tried."
    - path: "lib/mix/tasks/catalog.seed.ex"
      issue: "Confirms sequential insertion order that makes inserted_at track csv_row, which is why the recency sort surfaces the CSV's tail-clustered expansions."
  missing:
    - "Data-model fix, not just a query tweak: add a proper is_expansion (or parent_game_id) column populated during seeding by parsing the Nombre marker — markers are inconsistent (e.g. 'Star Wars: Las Guerras Clon - Promo Miniaturas' has no '(expa)' marker), so a manually reviewed list may be needed alongside the parser."
    - "Once the column exists, recent_query/0 must add where: g.is_expansion == false."
    - "A quick ILIKE-on-Nombre filter in recent_query/0 alone would be a partial, fragile patch — not every expansion/promo row carries a recognizable text marker."
  debug_session: ".planning/debug/G-01-5-expansions-in-recent.md"

- gap_id: G-01-6
  truth: "The game card on the main page presents information with clear visual hierarchy (primary vs. secondary fields), matching CLAUDE.md's 'teach complexity, don't overwhelm' UX principle for a casual/new player"
  status: failed
  reason: "User reported the card shows too much information at once with no hierarchy ('overloaded'). Needs a redesign pass prioritizing which fields are primary vs. secondary, not yet investigated or scoped."
  severity: major
  test: 2
  root_cause: "Two jointly-contributing causes (AND-gate). (1) [code] GameCard.game_card/1 (lib/pukllay_club_web/components/game_card.ex:67-77) stacks three semantically distinct chip/badge collections — GameChips.weight_band_badge/1 (the single primary complexity-teaching signal), GameChips.editorial_tags/1 (secondary curatorial flavor), and GameChips.chip_row/1 (tertiary mechanic detail) — directly beneath the title with uniform space-y-2 rhythm and no grouping. Two of the three (weight_band_badge/1 and editorial_tags/1, game_chips.ex:32,75) render at the IDENTICAL default badge size, differentiated only by background-color hue (badge-secondary violet vs. bg-accent light-lavender) — violating ui-design-system's own documented rule that color alone, without a complementary size/weight difference, is too weak an emphasis signal. Only the mechanic chip row uses badge-sm, and it sits last, not clearly demoted relative to the tags row above it. (2) [code+spec] GameChips.editorial_tags/1 (game_chips.ex:65-78) has NO cap/limit and no overflow indicator, unlike its sibling chip_row/1 in the same file which already implements the correct limit:4 + '+N' overflow pattern. A game can plausibly carry 2-3 of the 3 known editorial hashtags (each a long #CamelCase string), so this row can wrap to multiple lines with no ceiling. 01-UI-SPEC.md's own 'UI Considerations' table capped the mechanic row but never made an equivalent density decision for editorial tags — traces back to the phase spec, not only the implementation. Net effect: the card unconditionally renders 3 stacked badge/chip rows (1 primary + 2 effectively co-equal, visually-competing 'secondary' rows, one uncapped) with no structural or strong visual signal for which to read first. Player count/playtime/age (present on the Game schema) are NOT rendered on the card, confirming the density problem is specifically these 3 badge/chip collections, not raw metadata bloat."
  artifacts:
    - path: "lib/pukllay_club_web/components/game_card.ex"
      issue: "Lines 67-77 — stacks 3 badge/chip rows with uniform space-y-2 spacing and no tiering/grouping wrapper."
    - path: "lib/pukllay_club_web/components/game_chips.ex"
      issue: "weight_band_badge/1 (line 32) and editorial_tags/1 (line 75) share identical default badge size; editorial_tags/1 (lines 65-78) has no cap/overflow pattern unlike chip_row/1's existing limit:4 implementation (lines 45-51)."
    - path: ".planning/phases/01-catalog-v1/01-UI-SPEC.md"
      issue: "Capped mechanic chips explicitly (UI Considerations table) but never scoped a density/cap rule for editorial tags — a phase-spec gap, not just an implementation gap."
  missing:
    - "Give the weight-band badge a genuinely distinct visual tier (e.g. a size bump, not just color) per ui-design-system's 'size gap outranks weight alone' rule, so it reads unambiguously as the primary field."
    - "Demote editorial tags and mechanic chips to a visually lighter, smaller, grouped secondary row."
    - "Cap editorial_tags/1 with a limit+overflow pattern matching chip_row/1's existing implementation."
  debug_session: ".planning/debug/G-01-6-card-info-density.md"

- gap_id: G-01-7
  truth: "The main-page search input shows a single, clean focus ring when focused, consistent with the rest of the UI's focus styling"
  status: failed
  reason: "User reported the search input renders what looks like a 'double' black border on focus, likely a browser-default outline and a custom Tailwind/daisyUI focus-ring class both applying simultaneously. Not yet investigated."
  severity: minor
  test: 2
  root_cause: "daisyUI v5.5.20's .input component (compiled at priv/static/assets/css/app.css:646-712) renders two concentric focus indicators BY DESIGN, not because of a project-introduced class conflict. On :focus/:focus-within it (1) bumps the field's own persistent border-color from a ~20%-opacity mix to the full-opacity --color-base-content (#241238, near-black in this project's light theme), and (2) separately adds outline: 2px solid var(--input-color); outline-offset: 2px — a second rectangle drawn 2px outside the input's edge, in the IDENTICAL color variable. Both render as near-black lines 2px apart, perceived as a 'double black border.' The search input (index.ex:229-235) uses CoreComponents.input/1's untouched, phx.new-generated catch-all branch — class=\"w-full input\" applied directly to the native <input>, no custom class, no override. A full grep of lib/pukllay_club_web for focus:/focus-within:/focus-visible:/ring-/outline-none/outline-hidden returned ZERO matches — there is no custom Tailwind/daisyUI focus-ring class anywhere in the app to collide with a browser default, ruling out the mechanism originally suspected. Confirmed NOT localized to the search box: the sort <select class=\"select select-bordered\"> (index.ex:251) uses the identical direct-on-native-element pattern with the byte-for-byte same border+offset-outline focus mechanism in its compiled CSS — every plain .input/.select control in the app currently shows this same double-ring look; the search field is just the one Test 2 happened to interact with. daisyUI's own docs confirm this is .input's genuine default appearance, and some of daisyUI's own showcased examples explicitly suppress it via a focus:outline-none/focus-within:outline-none-style override when a single clean ring is wanted."
  artifacts:
    - path: "lib/pukllay_club_web/components/core_components.ex"
      issue: "input/1 default branch (lines 282-302) renders .input with no focus-ring override — root location for a fix."
    - path: "lib/pukllay_club_web/live/catalog_live/index.ex"
      issue: "Search field call site (line 229) and sort <select> (line 251) — both affected, confirming this is app-wide, not search-specific."
  missing:
    - "Suppress one of the two concentric indicators (most likely focus:outline-none/focus-within:outline-none layered onto .input/.select, keeping the border/box-shadow as the single visible ring) — consistent with daisyUI's own documented pattern for this look."
    - "Scope the fix at CoreComponents.input/1 (and the raw <select> in index.ex) rather than only the search field, since this affects all plain .input/.select controls app-wide."
    - "Consult ui-design-system for the approved token/approach before implementing."
  debug_session: ".planning/debug/G-01-7-double-focus-ring.md"
