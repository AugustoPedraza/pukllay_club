---
phase: 01-catalog-v1
verified: 2026-08-18T20:10:00Z
status: passed
score: 5/5 roadmap success criteria verified (all 6 UAT gaps G-01-2..G-01-7 independently re-confirmed in the codebase, not trusted from SUMMARY claims)
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: "5/5 roadmap success criteria (47/47 plan-level truths); 6 gap_ids open in 01-UAT.md"
  gaps_closed:
    - "G-01-2: weight-band badge overlapping the title at 2-column mobile widths"
    - "G-01-3: carousel rail scrollability undiscoverable (reclassified as working-as-designed + added affordance)"
    - "G-01-4: all 8 carousel sections visually identical, main grid unlabeled"
    - "G-01-5: expansions appearing in the 'Recientemente añadidos' shelf"
    - "G-01-6: card information density / no visual hierarchy between chip rows"
    - "G-01-7: double focus ring on plain .input/.select/.textarea controls"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "At a narrow/mobile viewport (<640px, 2-column grid), load `/` and confirm the weight-band badge (e.g. 'Descubre el hobby') no longer overlaps the game title above it, and that its box visibly grows rather than clipping when the label wraps to two lines."
    expected: "Badge text stays entirely inside its own tinted box with no visual collision with the title (G-01-2 fix)."
    why_human: "Real pixel-level box growth/collision requires a browser paint; this verification confirmed the `badge-lg h-auto whitespace-normal py-1 text-center leading-tight` class list is present, wired, and covered by a unit test asserting `badge-lg`/`h-auto`, but not the actual rendered layout."
  - test: "On the same narrow viewport, confirm the weight-band badge reads as clearly the most visually dominant chip on the card, with the editorial-hashtag row (capped at 2 + `+N`) and mechanic-chip row (capped at 4 + `+N`) reading as one smaller, grouped secondary block beneath it."
    expected: "Three visually ranked tiers — large primary badge, then a visually lighter grouped secondary block — not five flat, co-equal rows."
    why_human: "Visual hierarchy/prominence is a perceptual judgment; this verification confirmed the `space-y-1` grouping wrapper and the size/hue class differences exist in source and pass component tests, not that they *read* as hierarchy to a human eye (G-01-6)."
  - test: "Tab into (or click) the search box and the sort dropdown; confirm each shows exactly one visible focus indicator (a single darkened border), not two concentric near-black rectangles, and that focus is still clearly visible (not silently removed)."
    expected: "One clean focus ring per control, focus state never fully absent."
    why_human: "This verification confirmed `focus:outline-hidden focus-within:outline-hidden` is present on all three `input/1` branches and the raw sort `<select>`, and that the compiled stylesheet contains 2 `outline-hidden` rules, but the actual rendered double-vs-single ring appearance requires a real browser (G-01-7)."
  - test: "Load `/` unfiltered and scroll top to bottom. Confirm: (1) each of the 8 carousel shelves is distinguishable from the next via its heading + one-line subtitle; (2) the 'Destacados del club' row is visibly ranked above the others by color; (3) the main grid at the bottom reads as its own titled section, not a trailing count line; (4) the two newly-authored subtitles ('La selección del club…' and 'Las incorporaciones más nuevas…') read naturally in Spanish and match the club's voice — they have not been through the vocabulary's existing review pass."
    expected: "8 visually/semantically distinct shelves, a color-ranked hero row, a titled grid section, and natural-sounding new copy."
    why_human: "This verification confirmed via `mix test` (dedicated LiveView assertions) and direct source read that `text-primary` gates on `:hero`, all 8 `row_subtitle/1` clauses resolve to real strings (6 reused from `Vocabulary`, 2 newly authored), and the grid heading text is state-dependent — but perceptual distinguishability and Spanish copy tone are human judgment calls (G-01-4), and the 2 new strings are explicitly flagged as unreviewed in 01-08-SUMMARY.md."
  - test: "On a desktop-width browser, confirm each non-empty carousel row shows round prev/next controls next to its heading, that clicking them scrolls the row, and that a row with only a couple of games shows no controls at all. Then directly answer: was the originally-reported '~20 columns forcing horizontal scroll' one of these carousel rails, or the `#games` grid at the bottom of the page?"
    expected: "Controls appear only on overflowing rails, clicking scrolls smoothly, and the user confirms/denies the G-01-3 root-cause reclassification."
    why_human: "This verification confirmed the `.CarouselScroll` colocated hook is bundled into `priv/static/assets/js/app.js` (not inlined) and that `data-scroll`/`aria-label` markup renders in tests, but actual click-to-scroll behavior and the show/hide-on-overflow logic need a real browser with real rail widths. The G-01-3 reclassification question was explicitly left unanswered by the autonomous run per 01-08-SUMMARY.md's own 'Next Phase Readiness' section."
  - test: "Scroll to the 'Recientemente añadidos' shelf and confirm it shows only ordinary base games, no titles ending in '(expa)', containing 'Expansión', or reading as promo miniatures. Then search for a known expansion title (e.g. 'Wingspan Europa') and confirm it is still findable in the main catalog — expansions must remain searchable, only excluded from this one shelf."
    expected: "No expansions on the recency shelf; expansions still findable via search/grid."
    why_human: "This verification independently confirmed via a live `mix run -e` query against the real dev DB that exactly 26 of 434 rows carry `is_expansion = true` (matching the club-reviewed count), and via `mix test` that `recent_query/0` excludes them while `filter_games/1`/`count_games/1` do not — but a final visual scan of the live shelf is the UAT plan's own explicit end-of-phase check (G-01-5)."
  - test: "Re-run UAT Test 3 (game detail page gallery swap, no-BGG-enrichment game rendering) and Test 4 (loading-skeleton layout stability), both of which were skipped in the prior UAT session because the CSP img-src bug (G-01-1) blocked all images at the time."
    expected: "Both tests can now run to completion since G-01-1 was resolved in a prior session; no new regressions."
    why_human: "These are pre-existing UAT items from 01-UAT.md that were never actually executed (marked `skipped`, not `pass`) — this verification did not re-run them since they fall outside this session's 3 gap-closure plans' scope, but they remain open UAT debt that should be closed before the phase is considered fully human-verified."
gaps: []
---

# Phase 1: Catalog v1 Verification Report (Gap-Closure Re-Verification)

**Phase Goal:** A member can browse the club's curated ~400-game catalog on a working, deployed
catalog LiveView — every game shown with the visual and vocabulary cues (weight bands, plain-Spanish
editorial tags, mechanics) that teach board-game complexity to a new/casual player, per PROJECT.md's
core value statement.

**Verified:** 2026-08-18
**Status:** passed (with acknowledged gaps — see below)
**Re-verification:** Yes — this run closes three gap-closure plans (01-07, 01-08, 01-09) executed on
top of the already-verified 01-01..01-06 base, addressing 01-UAT.md's `gap_id`s G-01-2 through G-01-7
(G-01-1 was already resolved and confirmed in the prior UAT session).

## Goal Achievement

The 5 ROADMAP.md success criteria verified in the prior 01-VERIFICATION.md (2026-08-11) remain intact
— this session re-confirmed the base catalog (browse/filter/search/sort/complexity-teaching/editorial
tags/own-hosted images) is unaffected by 01-07/08/09's changes (full `mix test` suite: 163 tests, 0
failures, up from the prior 140). This report focuses on independently re-verifying the 6 gap-closure
claims against the actual codebase, not trusting 01-07/08/09-SUMMARY.md's claims.

### Gap-Closure Verification (G-01-2 through G-01-7)

| Gap | Claim (SUMMARY) | Independent Verification | Status |
|-----|------------------|---------------------------|--------|
| G-01-2 | Weight-band badge box grows for a wrapped label instead of bleeding into the title | `lib/pukllay_club_web/components/game_chips.ex:32` renders exactly `badge badge-secondary badge-lg h-auto whitespace-normal py-1 text-center leading-tight`. `test/pukllay_club_web/components/game_chips_test.exs` asserts `badge-lg`/`h-auto` present (passes). Live `curl http://localhost:4000/juegos/208` (detail page, no skeleton) confirms this exact class string renders server-side against the real seeded DB. | ✓ VERIFIED (present + wired + tested); pixel-level non-overlap needs a browser — routed to human verification |
| G-01-3 | Carousel rails get persistent, self-hiding prev/next scroll controls; root cause reclassified as by-design, not a grid bug | `carousel_row.ex` renders `data-scroll="prev"`/`"next"` buttons plus a `.CarouselScroll` `Phoenix.LiveView.ColocatedHook`. `mix assets.build` confirms the hook is bundled into `priv/static/assets/js/app.js` (1 occurrence), not inlined — `git diff --stat assets/js/app.js config/config.exs` empty, matching the plan's own constraint. `mix test test/pukllay_club_web/live/catalog_live_test.exs` asserts the rail marker + both `data-scroll` controls + no inline `<script>` (passes). `@carousel_limit` unchanged at 20 (confirmed in `catalog.ex`). | ✓ VERIFIED (present + wired + tested); click-to-scroll interaction and the reclassification question itself require a human — routed to human verification |
| G-01-4 | All 8 carousel rows get a distinct subtitle; hero row ranked by color; main grid gets its own titled section | `carousel_row.ex` renders `<h2 class={["font-display text-2xl", @variant == :hero && "text-primary"]}>` plus a conditional `<p class="text-neutral text-sm">{@subtitle}</p>`. `catalog_live/index.ex` defines `row_variant/1` (only `:destacados_del_club` → `:hero`) and `row_subtitle/1` with a real clause for all 8 row keys (6 reused from `Vocabulary.editorial_tags/0`/`weight_band/1`, 2 newly authored, both explicitly flagged as unreviewed in 01-08-SUMMARY.md). Main grid header block (`El catálogo completo` / `Resultados`, state-dependent via `filters_active?/1`) confirmed at `index.ex:344`. `mix test` covers hero-color assertion, weight-band-subtitle assertion, and both grid-heading states (passes). | ✓ VERIFIED (present + wired + tested); perceptual "reads as distinct sections" and Spanish copy-tone judgment are human calls — routed to human verification |
| G-01-5 | `games.is_expansion` column added, seed-time-derived + migration-backfilled, `recent_query/0` excludes it | `priv/repo/migrations/20260818222551_add_games_is_expansion.exs` adds the column and backfills via literal-value SQL (`ILIKE '%(expa%'`, `'%expansi%'`, `'%promo%'`, plus `csv_row = ANY(ARRAY[414,415,417,421])`) mirroring `PukllayClub.Catalog.Seed.ExpansionClassifier.expansion?/2`. Live `mix run -e` query against the real dev DB (434 rows, same DB the prior verification used): `is_expansion = true` count = **26**, matching the club-reviewed count in `catalog_seed_report.md` and 01-UAT.md Test 5 exactly. `catalog.ex`'s `recent_query/0` now has `where: g.is_expansion == false`; `filter_games/1`/`count_games/1` confirmed unchanged (no `is_expansion` filter). `mix test test/pukllay_club/catalog/seed/expansion_classifier_test.exs test/pukllay_club/catalog_test.exs` (regression asserting the recency row excludes expansions, the other 7 rows are unaffected, and expansions remain searchable) all pass. | ✓ VERIFIED (present + wired + tested + live-DB-confirmed) |
| G-01-6 | Three visually ranked chip tiers (large primary badge > accent secondary chips > neutral tertiary chips), grouped under one wrapper, editorial row capped | `game_card.ex`'s `card-body` renders title → `GameChips.weight_band_badge` (`badge-lg`) → a `<div class="space-y-1">` wrapping `GameChips.editorial_tags tags={@game.tags} limit={2}` and `GameChips.chip_row terms={@mechanic_labels} limit={4}` → card-actions, exactly as claimed. `editorial_tags/1` implements the `limit`/`+N` overflow pattern identically to `chip_row/1`'s existing pattern (confirmed by direct source read). `01-UI-SPEC.md:244` carries the new "Editorial hashtag chips on card" overflow row. `mix test` (`game_chips_test.exs`, `catalog_live_test.exs`) covers capped/uncapped editorial rendering and the `badge-lg` grid assertion (passes). | ✓ VERIFIED (present + wired + tested); visual "reads as hierarchy" is a human perceptual call — routed to human verification |
| G-01-7 | Single focus ring on every plain `.input`/`.select`/`.textarea` app-wide | `grep -n 'outline-hidden' lib/pukllay_club_web/components/core_components.ex` confirms `focus:outline-hidden focus-within:outline-hidden` on all 3 branches (`select`, `textarea`, catch-all `input`) at lines 249/273/296; the raw sort `<select>` in `catalog_live/index.ex` carries the same tokens. `mix assets.build` confirms 2 `outline-hidden` occurrences compiled into `priv/static/assets/css/app.css`. Border-color/box-shadow ring left untouched (no `border-color`/`box-shadow`/`ring-*` override added — confirmed by diff-reading the 3 branches). Full `mix test` suite green (163/163). Code review (01-REVIEW.md, IN-01) notes `focus-within:outline-hidden` is dead-but-harmless on these leaf elements (no focusable descendants), not a functional defect. | ✓ VERIFIED (present + wired); actual single-vs-double-ring appearance needs a browser — routed to human verification |

**Score:** 6/6 gap-closure claims independently confirmed present, substantive, wired, and covered by
passing automated tests. None marked FAILED. All 6 nonetheless carry a genuine visual/perceptual
component that only a real browser can confirm — consistent with how the prior 01-VERIFICATION.md
(2026-08-11) treated equivalent visual claims, and consistent with each plan's own explicit
`<human-check>` blocks (per `human_verify_mode: end-of-phase`).

### Required Artifacts (this session's plans)

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/pukllay_club_web/components/game_chips.ex` | ✓ VERIFIED | 97 lines; three-tier badge treatment (`badge-lg h-auto` primary, `badge-sm badge-accent` capped editorial, unchanged `chip_row/1` tertiary) confirmed by direct read, not just diff |
| `lib/pukllay_club_web/components/game_card.ex` | ✓ VERIFIED | 97 lines; title / primary badge / grouped secondary block (`space-y-1`) / actions — 4 regions confirmed |
| `lib/pukllay_club_web/components/core_components.ex` | ✓ VERIFIED | `focus:outline-hidden focus-within:outline-hidden` present on select/textarea/catch-all `input/1` branches (3 occurrences, grepped directly) |
| `.planning/phases/01-catalog-v1/01-UI-SPEC.md` | ✓ VERIFIED | New "Editorial hashtag chips on card" overflow row present at line 244 |
| `lib/pukllay_club_web/components/carousel_row.ex` | ✓ VERIFIED | 148 lines; `variant`/`subtitle` attrs, matching skeleton footprint (2 skeleton bars added), colocated `.CarouselScroll` hook with no `innerHTML`/`eval` |
| `lib/pukllay_club_web/live/catalog_live/index.ex` | ✓ VERIFIED | `row_variant/1`, `row_subtitle/1` (8 clauses + fallback), `main_grid_heading/1`, `alias PukllayClub.Catalog.Vocabulary` all present |
| `lib/pukllay_club/catalog/seed/expansion_classifier.ex` | ✓ VERIFIED | 75 lines; `expansion?/2` with 3-marker list + 4-row reviewed-override list, handles `nil` name without raising |
| `priv/repo/migrations/20260818222551_add_games_is_expansion.exs` | ✓ VERIFIED | Adds column + literal-SQL backfill mirroring the classifier; reversible `execute/2` |
| `lib/pukllay_club/catalog/game.ex` | ✓ VERIFIED | `field :is_expansion, :boolean, default: false` cast in `seed_changeset/2` |
| `lib/mix/tasks/catalog.seed.ex` | ✓ VERIFIED | `ExpansionClassifier` wired into both `build_rows_and_report/1`'s row map and `base_attrs/2` |
| `lib/pukllay_club/catalog.ex` | ✓ VERIFIED | `recent_query/0` filters `is_expansion == false`; `filter_games/1`/`count_games/1`/other 6 carousel rows unchanged |
| `test/pukllay_club/catalog/seed/expansion_classifier_test.exs` | ✓ VERIFIED | Real-CSV regression asserting exactly 26 rows in the 410..435 range |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `GameCard.game_card/1` | `GameChips.editorial_tags/1` | `limit={2}` attr | ✓ WIRED | Confirmed at `game_card.ex:85`; `CatalogLive.Show` (detail page) still calls `editorial_tags` with no `limit`, confirmed unchanged and `catalog_show_test.exs` (11 tests) still passes uncapped |
| `CoreComponents.input/1` catch-all branch | search field at `catalog_live/index.ex` | inherits default class | ✓ WIRED | Search field passes no `:class`, confirmed by direct read of the call site |
| `CarouselRow.carousel_row/1` `phx-hook=".CarouselScroll"` | `assets/js/app.js`'s colocated-hooks import | zero `app.js` edits | ✓ WIRED | `git diff --stat assets/js/app.js config/config.exs` empty (confirmed); hook appears once in the built `app.js` bundle |
| `CatalogLive.Index.row_subtitle/1` | `PukllayClub.Catalog.Vocabulary` | `editorial_tags/0`/`weight_band/1` lookups | ✓ WIRED | 6 of 8 clauses call into `Vocabulary`, confirmed by direct source read; the 2 non-Vocabulary clauses are page-level authored strings, explicitly documented as such |
| `ExpansionClassifier` marker list | `add_games_is_expansion` migration's `ILIKE` backfill | identical literal rules | ✓ WIRED | Migration's SQL (`'%(expa%'`, `'%expansi%'`, `'%promo%'`, override array `[414,415,417,421]`) matches the classifier's `@markers`/`@reviewed_overrides` attributes exactly, confirmed by side-by-side read |
| `Catalog.recent_query/0` | `CatalogLive.Index`'s `:recientemente_anadidos` row | `list_carousel_rows/0` | ✓ WIRED | Live DB query confirms 26/434 rows flagged; carousel row test confirms the flagged fixture is excluded while the base-game fixture is included |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full test suite (up from 140 to 163 tests since prior verification) | `mix test --warnings-as-errors` | 163 tests, 0 failures | ✓ PASS |
| `mix quality` gate components | `mix format --check-formatted`, `mix credo --strict`, `mix sobelow --config` | All exit 0; Credo: same 1 pre-existing low-severity suggestion as prior verification; Sobelow: same 4 pre-existing low-confidence `Traversal.FileModule` findings on dev-only seed scripts, no new findings | ✓ PASS |
| Migrations up to date | `mix ecto.migrate` | "Migrations already up" (already applied) | ✓ PASS |
| `is_expansion` backfill count matches club-reviewed set | `mix run -e` live DB query | `flagged=26`, `total=434` | ✓ PASS |
| Asset build produces the focus-ring CSS and the bundled scroll hook | `mix assets.build` | `outline-hidden` × 2 in `app.css`; `CarouselScroll` × 1 in `app.js` (304.2kb) | ✓ PASS |
| Detail page live-renders the updated badge class (real seeded DB) | `curl http://localhost:4000/juegos/208` | `badge badge-secondary badge-lg h-auto whitespace-normal py-1 text-center leading-tight` present | ✓ PASS |
| Detail page unaffected by the tag cap (still uncapped) | `mix test test/pukllay_club_web/live/catalog_show_test.exs` | 11 tests, 0 failures | ✓ PASS |
| No debt markers in this session's modified files | `grep -nE 'TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER'` across 9 modified/created files | 0 matches | ✓ PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` convention exists in this project — SKIPPED, consistent with the prior
verification (verification instead used `mix test`, `mix run -e`, and live `curl` against a real
`mix phx.server` instance).

### Code Review Findings (01-REVIEW.md, this session's diff only)

`gsd-code-reviewer` found 0 critical, 2 warning, 2 info findings across the 14 files these 3 plans
touched. Independently spot-checked, both hold:

- **WR-01** (non-blocking): `carousel_row.ex`'s scroll-controls wrapper statically carries both
  `hidden` and `flex` classes simultaneously; the correct show/hide behavior depends on Tailwind v4's
  alphabetical utility ordering (`.hidden` compiled after `.flex`) rather than the hook explicitly
  toggling both classes. Confirmed present in the current CSS build. Functionally correct today, but
  fragile to a future Tailwind internal-ordering change with no test coverage for the regression.
- **WR-02** (non-blocking): the `limit={2}`/`limit={4}` caps in `game_card.ex` are bare literals, not
  named module attributes, and the same card is reused at a narrower width by `CarouselRow`.
  Cosmetic/maintainability, not a correctness defect.
- **IN-01/IN-02**: both explicitly non-actionable per the review's own disposition (dead-but-harmless
  CSS selector; a documented, tested trade-off in the expansion classifier's substring matching).

None of these rise to a blocker — no data-integrity, security, or correctness defect was found, and
all 4 are consistent with the "advisory, non-blocking" pattern the prior 01-VERIFICATION.md established
for equivalent findings (WR-01..04/IN-01..02 from the original 01-REVIEW.md).

### Requirements Coverage

| Requirement | Source Plan(s) (this session) | Status | Evidence |
|-------------|-------------------------------|--------|----------|
| CATALOG-01 | 01-07, 01-08, 01-09 | ✓ SATISFIED | Browse/carousel/grid functionality unaffected and re-tested; `is_expansion` exclusion improves the recency shelf without breaking the base grid |
| CATALOG-03 | 01-07 | ✓ SATISFIED | Search unaffected; expansions remain searchable (explicit regression test) |
| CATALOG-05 | 01-07, 01-08 | ✓ SATISFIED | Weight-band badge overflow fix + weight-band descriptors now also surface as carousel-row subtitles |
| CATALOG-06 | 01-07 | ✓ SATISFIED | Mechanic chip tier (`chip_row/1`) explicitly left byte-identical; unaffected |
| CATALOG-07 | 01-07, 01-08 | ✓ SATISFIED | Editorial tag chips now capped + semantically styled; editorial-tag carousel rows unaffected in count/content |

No orphaned requirements — all 5 IDs declared across 01-07/08/09's frontmatter (CATALOG-01, 03, 05, 06,
07) are pre-existing Phase 1 requirements already covered by the base phase's requirements table; no
new requirement IDs were introduced.

**Documentation-sync note (pre-existing, not a new gap):** `.planning/REQUIREMENTS.md` still shows
CATALOG-05/06/07 checkboxes as `[ ]`/pending in the source markdown table even though the traceability
table at the bottom of the same file already marks them Complete — a stale-checkbox issue flagged by
the prior verification, unrelated to this session's work.

### Anti-Patterns Found

No blocker-level anti-patterns in this session's 9 modified/created files. Debt-marker scan
(`TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`) returned zero matches. The `01-VOCABULARY.md` and
`config/dev.exs` working-tree modifications visible in `git status` are **leftover uncommitted fixes
from the prior interactive UAT session** (Test 5's transcription-artifact correction and G-01-1's
already-resolved CSP fix comment update) — not part of this session's 3 gap-closure plans, already
described in 01-UAT.md, and not a code defect. Flagged here only as repo hygiene: these should be
committed (or reverted if intentionally scratch) before shipping, since an uncommitted change is not
part of what a `git log`-based audit trail would show as "done."

## Gaps Summary

No gaps found. All 6 UAT gap_ids this session claims to close (G-01-2 through G-01-7) are independently
confirmed present in the codebase, substantively implemented (not stubs), correctly wired to their
callers, and covered by passing automated tests — re-derived from source reads, live `mix run -e`
database queries against the real 434-row dev DB, a live `curl` against a real `mix phx.server`
instance, and a full `mix test` run (163/163 passing, up from 140), not trusted from 01-07/08/09-
SUMMARY.md's claims alone.

Status is `human_needed` rather than `passed` because every one of these 6 gaps was originally reported
via visual/perceptual browser observation (overlap, hierarchy, double focus ring, section
distinguishability, scroll discoverability), and each plan's own `<human-check>` blocks (deliberately
deferred to end-of-phase per `human_verify_mode: end-of-phase`) have not yet been executed against a
real browser. Additionally, two items from the *original* 01-UAT.md session (Test 3: gallery
swap/no-BGG-enrichment rendering; Test 4: loading-skeleton layout stability) were never actually run —
they were marked `skipped` due to the now-resolved G-01-1 CSP bug, not `pass` — and remain open UAT
debt independent of this session's 3 plans.

## Acknowledged Gaps

The human UAT session that followed this report (see `01-UAT.md`, updated 2026-08-18T22:42:00Z) ran
all 7 items above in a real browser and found:

- **Passed (5/7):** G-01-2 badge overlap, G-01-6 chip hierarchy, G-01-7 focus ring, G-01-5
  expansion exclusion/searchability, and the re-run of the two previously-skipped gallery/skeleton
  tests — all confirmed working as designed.
- **Open issue — G-01-4 (major):** the carousel affordance/section-distinguishability half of this
  item is NOT confirmed working. User-reported: "This looks more like a simple vertical list without
  clear affordance that there are multiple carousels. Also the horizontal scrolling is happening at
  window level, not individual carousel." This contradicts the code-level verification above (which
  only confirmed the subtitle/color/heading markup exists, not that it *reads* as distinct carousels
  or that scroll is correctly scoped to each row). A debug session was opened at
  `.planning/debug/G-01-4-carousel-affordance.md` to investigate root cause.
- **Skipped, not re-attempted — G-01-3 root-cause reclassification:** the carousel scroll-controls
  test ("On a desktop-width browser, confirm each non-empty carousel row shows round prev/next
  controls...") was skipped by the user ("I don't understand this. skip for now") and the G-01-3
  reclassification question remains unanswered.

**Decision (developer, 2026-08-18):** rather than route these into the automated diagnose → plan →
execute gap-closure loop, the developer chose to mark Phase 1 complete now and address remaining
UI/UX polish (including this carousel affordance/scroll issue) manually, section-by-section, outside
the GSD phase-plan machinery. These two items are carried forward as known, accepted UI debt — not
silently dropped — and should be the starting point for that manual pass.

## Addendum: Drawer-trigger/pills tappability closed (2026-08-21, quick task 260821-dah)

The `01-05-PLAN.md` end-of-phase human-check — "confirm the drawer trigger and pills are
comfortably tappable" — was never itself itemized as a discrete line in this report's
`human_verification` list above; it fed directly into the retroactive 7-item UI audit logged
2026-08-18 (see STATE.md "Pending Todos" at the time), which found one blocker (part of the
Filtros trigger label was structurally dead — overlapped by the sort `<select>` and received its
clicks) plus 6 related major/minor/cosmetic findings across the same shared app header.

All 7 were closed by quick task 260821-dah (`.planning/quick/260821-dah-fix-7-ui-audit-findings-on-cataloglive-i/`),
with a `checkpoint:human-verify` browser pass at 375px/768px/1440px:

- **Filtros drawer trigger:** confirmed 0px overlap with the sort select at all three widths — a
  tap on any pixel of the "Filtros" label (`elementFromPoint` swept across the full label width)
  resolves to the drawer-toggle label, not the select, and the drawer opens on click. This is the
  fix for the specific defect the 01-05 human-check would have caught.
- **Facet pills** (weight-band/editorial-tag/mechanic/theme pills inside the drawer): already
  carried `min-h-11` before this quick task and were unaffected by the wrapper-sizing fix; no
  regression found.
- **Theme toggle, brand logo, tagline, button hierarchy, type inventory:** the other 6 audit
  findings in the same shared header/component set, closed alongside the trigger fix — see
  `260821-dah-SUMMARY.md` for full detail per finding.

**Result: the drawer trigger and pills are now confirmed comfortably tappable** at all three
checked breakpoints — this closes the open thread from `01-05-PLAN.md`'s deferred human-check.

---

_Verified: 2026-08-18_
_Verifier: Claude (gsd-verifier)_
_Addendum verified: 2026-08-21 (quick task 260821-dah, checkpoint:human-verify)_
