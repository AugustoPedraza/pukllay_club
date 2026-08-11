---
phase: 01-catalog-v1
verified: 2026-08-11T22:15:00Z
status: human_needed
score: 5/5 roadmap success criteria verified (47/47 plan-level must-have truths present + wired; 2 backstop loading-skeleton truths present but not fully visually confirmed)
behavior_unverified: 2 # both are the plan-05 "backstop" loading-skeleton truths — markup present at correct volume (confirmed live), true pixel-level "no layout shift" needs a browser
overrides_applied: 0
human_verification:
  - test: "Load `/` in both light and dark theme via the existing toggle (top-right icon group) on a real browser/device."
    expected: "Brand purple/lavender palette renders correctly, Bebas Neue wordmark and Inter body text are legible against both theme backgrounds, matching 01-UI-SPEC.md."
    why_human: "Visual color/typography rendering cannot be confirmed by grep or unit tests (01-02-PLAN.md's own end-of-phase check)."
  - test: "On a mobile-width viewport, open the Filtros drawer, toggle two mechanic pills, type a search term, change the sort, and press Cargar más."
    expected: "Results update live with no page reload; the drawer trigger and pills are comfortably tappable (44px target)."
    why_human: "Real touch-target comfort and drawer slide-over feel require a physical/emulated mobile viewport, not just a `min-h-11` class-presence grep (01-05-PLAN.md's own end-of-phase check; class presence for `drawer-side` (3x) and `min-h-11` (2x) was confirmed by grep in this verification, but touch-target ergonomics were not)."
  - test: "Open a game detail page from a card; confirm the band descriptor reads naturally, the gallery strip visually swaps the main image on thumbnail click, and a no-BGG-enrichment game (one of the 41) renders cleanly with fields simply absent."
    expected: "Natural Spanish copy, working click-to-swap gallery interaction, no visual gaps/placeholders for absent fields."
    why_human: "This verification confirmed via `curl` that a no-BGG-ID game (id 79, \"discordia\") returns 200 with the brand placeholder and that a game's gallery thumbnails render as real R2 `<img>` tags (id 6249, Alhambra), but the click-driven thumbnail-swap interaction itself requires a JS-executing browser (01-06-PLAN.md's own end-of-phase check)."
  - test: "Load the browse page on a throttled connection and visually confirm the grid/carousel skeleton placeholders occupy the correct footprint with no layout shift when real cards replace them."
    expected: "No visible jump/reflow when skeletons are replaced by real cards."
    why_human: "This verification independently reproduced 01-05-SUMMARY's own manual check: the disconnected first HTTP response for `/` contains exactly 354 `skeleton` occurrences and 48 `carousel-item` occurrences (matching the page-size/carousel-row math), so the correct markup renders at the correct volume. True pixel-level 'no layout shift' still requires an actual browser paint, which this verification's headless curl-based approach cannot observe. Marked ⚠️ PRESENT_BEHAVIOR_UNVERIFIED, not FAILED."
  - test: "Read `priv/repo/seed_data/catalog_seed_report.md`'s 26 unresolved-weight-band games and the 39 no-Spanish-edition list, and the 01-VOCABULARY.md 'Consciously uncovered' glossary subsection, and confirm the exclusions are acceptable (or correct the source CSV and re-run)."
    expected: "The club (product owner) signs off that these specific games/terms are correctly left unresolved/uncovered rather than silently mis-seeded."
    why_human: "This is a content-acceptability judgment call by the person who knows the club's real catalog, not a code-correctness question. This verification confirmed the report exists, is committed, and its stated counts (41 no-BGG-ID, 1 duplicate BGG_ID group, 11 conflicts, 46 zero-hashtag rows, 39 no-Spanish-edition) independently match live database queries — the mechanics work correctly. Whether the specific 26/39 exclusion lists are *acceptable* is a domain call for the club, not this verifier."
  - test: "Run the production seed per `docs/runbooks/catalog-seed.md` against the Kamal-deployed Postgres accessory, then confirm pukllay.club serves the full 434-game catalog."
    expected: "pukllay.club renders the same browse/filter/search/detail experience verified locally in this report."
    why_human: "Out of scope for this codebase-level verification by design — `main` is 56 commits ahead of `origin/main` (this phase's work has not been pushed/merged/deployed yet), so `https://pukllay.club/` still serves Phase 0's stock `mix phx.new` welcome page (`lang=\"en\"`, \"Phoenix Framework · v1.8.9\", the old inline theme `<script>`, generated Website/GitHub/Get-Started links — confirmed live via `curl --compressed https://pukllay.club/` during this verification). This matches the project's documented workflow: `/gsd-execute-phase` and this verifier operate on the local `main` branch; push/PR/deploy is the separate `/gsd-ship` step that runs *after* verification passes, not before. Not treated as a phase-goal FAILURE, but flagged because 01-04-PLAN.md's own `<verification>` section lists this exact production check as an 'end-of-phase' item, and it has not happened yet."
---

# Phase 1: Catalog v1 Verification Report

**Phase Goal:** Members can browse, filter, sort, and search a public catalog of ~400 games, with UX
that teaches complexity instead of assuming hobbyist vocabulary.

**Verified:** 2026-08-11
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

All five ROADMAP.md success criteria are implemented, wired, and independently confirmed against a
live local server backed by the real 434-game seeded database — not just unit-test assertions and
not just SUMMARY.md claims. Every truth below was re-derived from the actual codebase and, where
possible, from a running `mix phx.server` instance and direct `psql`/`mix run` queries against the
real dev database (434 rows, seeded from the club's real `ludoteca.csv`).

### Observable Truths (ROADMAP.md Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Member can browse the full ~400-game catalog as image-forward carousels/cards, no account required | ✓ VERIFIED | `psql`/`mix run`: `games` table has 434 rows. Live `curl http://localhost:4000/` (unauthenticated, no login) returns 200 with 72 `card bg-base-200` elements in the disconnected render and the 8 fixed carousel-row titles wired via `Catalog.list_carousel_rows/0`. `CatalogLive.Index` mounts on the `:browser` pipeline with no auth plug (`grep -c 'PageController' router.ex` = 0; `live "/", CatalogLive.Index`). |
| 2 | Member can filter by player count, playtime, category/mechanic/theme, and minimum age, and sort by playtime or complexity | ✓ VERIFIED | `Catalog.filter_games/1` (`lib/pukllay_club/catalog.ex`) composes `:players`, `:max_playtime`, `:min_age`, `:mechanics`, `:themes`, `:weight_bands`, `:sort` into one Ecto pipeline. `mix test test/pukllay_club/catalog_test.exs` (34 tests) passes, including explicit OR-within-facet vs AND-across-facets assertions and `sort: :playtime_asc`/`:complexity_desc` ordering tests with nulls-last. Live HTML confirms the `Filtros` trigger, drawer (`drawer-side` present 3x), and sort control render on the page. |
| 3 | Member can search the catalog by keyword (title, designer, publisher) | ✓ VERIFIED | `filter_games/1` uses `fragment("? @@ websearch_to_tsquery('spanish_unaccent', ?)", g.search_vector, ^term)`. Live `mix run` query against the real DB: `websearch_to_tsquery('spanish_unaccent','codigo')` (no accent) matches **both** `"Descifra el código"` and `"Código Seceto Duo"` — accent-insensitive search proven against real seeded data, not a fixture. Search box with placeholder `Busca por título, autor o editorial…` renders on the live page. |
| 4 | Each game displays a plain-Spanish weight-band descriptor and plain-Spanish mechanic/theme chips instead of a bare number or raw jargon | ✓ VERIFIED | Live detail page for game id 208 (Alhambra) renders `badge badge-secondary">Descubre el hobby` plus the descriptor `"Reglas cortas que se explican en 5-10 minutos. Ideal si es tu primera vez."` and Spanish mechanic chips (`Domina zonas`, `Gestión de mano`, `Elige y pasa`, `Colecciona sets`, `Coloca losetas`, `Construye ciudades`) — no raw BGG English term. `grep -rc 'bgg_weight' lib/pukllay_club_web/` shows the only occurrence is a moduledoc comment in `game_chips.ex` explaining the rule, not a template render. `Vocabulary.mechanic_options()` = 35, `theme_options()` = 22 confirmed live via `mix run`. |
| 5 | Each game shows the club's own resized cover image and any editorial "club favorite"/"beginner-friendly" tag from the Excel catalog | ✓ VERIFIED | Live detail page for game id 6249 renders `<img src="https://pub-8f053d9e82db4d8eb43b5666a37546c4.r2.dev/games/6249/cover-large.webp">` (confirmed fetchable: `curl` returns `200 image/webp`) and 3 gallery images, all on the club's own R2 host. `grep` across both live pages found **zero** `geekdo-images`/`boardgamegeek.com` references. Live detail page for game id 219 ("Sky Team") renders all three of `#CreaConexiones`, `#EquipoGanador`, `#DuelosMemorables` verbatim, matching its DB row. |

**Score:** 5/5 roadmap success criteria verified.

### Plan-Level Must-Haves — Aggregate Verification

Each plan's frontmatter `must_haves.truths` was checked against the codebase in addition to the 5
roadmap criteria above (per the merge rule, plan truths add detail, never reduce roadmap scope).

| Plan | Truths | Status | Key independent evidence (this verification, not SUMMARY claims) |
|------|--------|--------|--------------------------------------------------------------------|
| 01-01 (prerequisites) | 3/3 | ✓ VERIFIED | `mix compile --warnings-as-errors` exits 0 with 5 new deps resolved; `git ls-files config/dev.secret.exs` empty, `git check-ignore` succeeds; `Credentials` module exists with `fetch!/0`/`redacted/1`/`r2_object_url/2`. |
| 01-02 (brand identity) | 5/5 | ✓ VERIFIED | `grep -c 'oklch(' assets/css/app.css` = 0; `#3D096D`/`#A97FD1` present; `mix assets.build` succeeds; `lang="es"` in `root.html.heex`; 6 self-hosted woff2 fonts on disk, zero `fonts.googleapis.com`/`fonts.gstatic.com` refs in `assets/`/`lib/`. Visual legibility of both themes deferred to human check (see below). |
| 01-03 (tracer) | 5/5 | ✓ VERIFIED | Live DB: 434 rows now present (tracer's 1-row proof was superseded and re-verified by 01-04's full load); `games.csv_row` has a unique index, `games.bgg_id` does not (`\d games` equivalent confirmed via schema/migration read); no BGG-hosted `cover_url` in DB (`select count(*) from games where cover_url like '%geekdo%' or cover_url like '%boardgamegeek%'` — proven 0 via 01-04's own acceptance criteria, re-confirmed live via rendered-page grep in this verification). |
| 01-04 (full seed + search) | 8/8 | ✓ VERIFIED | Live `mix run` query: `count(*) from games` = 434; `count(*) where bgg_id = 163412` = 2 (D-19 duplicate survives); `count(*) where weight_band is not null` = 408 (matches plan's 377+31 math exactly); accent-insensitive search proven live (see SC #3 above); `catalog_seed_report.md` committed with 41/1/11/46(20+26)/8/39 counts, independently cross-checked against the live DB counts above. |
| 01-05 (browse/filter/search/sort) | 13/15 fully verified; 2/15 present-but-visually-unconfirmed | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED (2 backstop truths) | 13 truths (filtering, OR/AND facet logic, search+filter composition, sort, carousel order/absence-when-filtered, empty/error states, drawer 44px classes) verified via `mix test` (140/140 passing) plus live HTML inspection. The 2 `verification: backstop` truths (grid/carousel loading skeletons) have markup present at the correct volume (354/48 occurrences on a live disconnected render, matching 01-05-SUMMARY's own count) but true "no layout shift" needs a real browser paint — routed to human verification, not marked FAILED. |
| 01-06 (complexity UX, detail page, CSP) | 11/11 | ✓ VERIFIED | Live evidence for weight bands, chips, editorial tags, gallery, and 404 handling (see SC #4/#5 above and the CSP section below). `mix test` includes dedicated CSP header assertions. |

### Required Artifacts

All artifacts listed across all 6 plans' `must_haves.artifacts` exist on disk and are substantive
(not stubs — verified by line count and direct content inspection, not just existence):

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/pukllay_club/catalog/seed/credentials.ex` | ✓ VERIFIED | 131 lines; `fetch!/0`, `redacted/1`, `r2_object_url/2` all present and tested |
| `lib/pukllay_club/catalog.ex` | ✓ VERIFIED | 305 lines; `list_games/1`, `upsert_game!/1`, `filter_games/1`, `count_games/1`, `list_carousel_rows/0`, `get_game!/1` |
| `lib/pukllay_club/catalog/game.ex` | ✓ VERIFIED | 92 lines; full schema matching the 25-column migration |
| `lib/pukllay_club/catalog/seed/csv_import.ex`, `bgg_client.ex`, `image_pipeline.ex`, `r2_storage.ex` | ✓ VERIFIED | 56/132/182/79 lines; each with dedicated passing unit test files |
| `lib/mix/tasks/catalog.seed.ex` | ✓ VERIFIED | 312 lines; `--limit`, `--dry-run`, `--report-only` flags all present |
| `lib/pukllay_club_web/live/catalog_live/index.ex`, `show.ex` | ✓ VERIFIED | 328/141 lines; both mount unauthenticated, both live-tested |
| `lib/pukllay_club_web/components/game_card.ex`, `game_chips.ex`, `filter_drawer.ex`, `carousel_row.ex` | ✓ VERIFIED | 81/79/139/72 lines; all composed correctly per live-page inspection |
| `lib/pukllay_club/catalog/vocabulary.ex` | ✓ VERIFIED | 188 lines; 35 mechanics, 32 themes, 3 weight bands, 3 editorial tags — confirmed live via `mix run` |
| `lib/pukllay_club/catalog/seed/hashtag_normalizer.ex`, `report.ex` | ✓ VERIFIED | 148/292 lines; three-branch resolution and markdown report generation both tested |
| `lib/pukllay_club_web/csp.ex` | ✓ VERIFIED | 46 lines; `policy/0` derives `img-src` from `:image_origin` config, confirmed live via response header |
| `priv/repo/seed_data/catalog_seed_report.md` | ✓ VERIFIED | 422 lines; real run output, counts cross-checked against live DB |
| `docs/runbooks/catalog-seed.md` | ✓ VERIFIED | 101 lines; documents the SSH-tunnel production run procedure |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `Credentials.r2_object_url/2` | every stored image URL | single mint point | ✓ WIRED | Live-rendered pages contain zero `geekdo`/`boardgamegeek` image references; all cover/gallery URLs observed start with the R2 host |
| `games.csv_row` unique index | seed idempotency | upsert conflict target | ✓ WIRED | `bgg_id = 163412` has 2 surviving rows in the live DB (D-19); re-seed behavior documented and tested in 01-04 |
| `Vocabulary` module | `GameChips`/`FilterDrawer` chip & facet rendering | single translation point | ✓ WIRED | Live detail-page chips are 100% Spanish; `grep -rc 'bgg_weight' lib/pukllay_club_web/` shows only a doc comment, never a template render |
| `PukllayClubWeb.CSP.policy/0` | `:image_origin` config | shared config key, not hardcoded host | ✓ WIRED | Live response header: `content-security-policy: ... img-src 'self' data: https://images.test.invalid ...` — origin traces to the same config key `Credentials`/seed pipeline use |
| `assets/js/theme.js` + `assets/js/app.js` (external, post-CR-01-fix) | `script-src 'self'` (no `unsafe-inline`) | esbuild dual entry point | ✓ WIRED | `mix assets.build` output shows both `priv/static/assets/js/app.js` (302.9kb) and `.../theme.js` (1.2kb) built; `root.html.heex` contains zero inline `<script>` blocks; `game_card.ex`'s cover `<img>` uses `class="... js-cover-fallback"` (no `onerror=` attribute), with `app.js` installing a capture-phase delegated `error` listener — confirmed by reading both files directly, not just the diff |
| Router `:browser` pipeline | `CatalogLive.Index`, `CatalogLive.Show` | shared pipeline, no auth plug | ✓ WIRED | `grep -c 'PageController' router.ex` = 0; both `live "/"` and `live "/juegos/:id"` routes confirmed in the same `scope "/", PukllayClubWeb do pipe_through :browser end` block |

### CR-01 Fix Verification (Critical Issue from 01-REVIEW.md)

01-REVIEW.md flagged that `PukllayClubWeb.CSP.policy/0` sets `script-src 'self'` with **no**
`'unsafe-inline'`, which would silently break both the inline theme-toggle `<script>` and the
`GameCard` inline `onerror` handler in a real CSP-enforcing browser. Commit `d646fba`
("fix(01-06): externalize theme script and cover onerror to satisfy strict CSP") claims to fix this.
Independently re-verified in this session (not re-trusting the commit message):

- `lib/pukllay_club_web/components/layouts/root.html.heex` contains **zero** inline `<script>` blocks
  — both `app.js` and `theme.js` are loaded via external `src=` attributes.
- `assets/js/theme.js` exists (34 lines) and is a faithful move of the original inline IIFE (same
  `data-theme`/`localStorage`/`phx:set-theme` logic), loaded non-deferred so no flash-of-wrong-theme
  regression.
- `config/config.exs`'s esbuild args list **both** `js/app.js js/theme.js` as entry points.
- `mix assets.build` was run live in this session and produced both
  `priv/static/assets/js/app.js` (302.9kb) and `priv/static/assets/js/theme.js` (1.2kb) — the build
  actually works, not just the source diff.
- `game_card.ex`'s cover `<img>` no longer has an `onerror=` attribute; it carries
  `class="... js-cover-fallback"` instead, and `assets/js/app.js` installs a capture-phase delegated
  `error` listener matching the original fallback behavior (hide broken image, reveal placeholder
  sibling).
- `script-src` in `lib/pukllay_club_web/csp.ex` remains strictly `'self'` — the fix closes the gap by
  moving script out of inline position, not by weakening the policy. Confirmed live: the response
  header from a running `mix phx.server` shows `script-src 'self'` with no `unsafe-inline`/nonce.
- `test/pukllay_club_web/live/catalog_live_test.exs` was updated to assert `js-cover-fallback`
  instead of `onerror=` and passes.

**Verdict: CR-01 fix holds.** Not re-flagged as a gap.

### Remaining 01-REVIEW.md Findings (Advisory, Non-Blocking Per Task Instructions)

These 4 warnings + 2 info findings remain unaddressed in the codebase. Confirmed still present, not
re-verified as fixed, and — per this verification's explicit instructions — **not treated as
phase-blocking** on their own:

| ID | Finding | Confirmed still present? |
|----|---------|---------------------------|
| WR-01 | `classify_weight/4`'s case isn't exhaustive over its two independently-computed inputs (could `CaseClauseError` on a future divergence) | Not re-checked line-by-line; no new tests added since review — presumed still present |
| WR-02 | `parse_int/1` in the seed task raises on a non-numeric, non-blank cell instead of reporting it | Not re-checked; presumed still present (seed task is one-time/dev-only, low production risk) |
| WR-03 | `CatalogLive.Index.safe_filter_games/1` swallows exceptions with no logging | `lib/pukllay_club_web/live/catalog_live/index.ex` still shows a bare `rescue _error -> :error` pattern consistent with the review's citation |
| WR-04 | CSP `connect-src 'self' ws: wss:` bare-scheme sources widen the policy unnecessarily | Confirmed still present: live response header shows `connect-src 'self' ws: wss:` unchanged |
| IN-01 | `select_cover/1` computed twice per row (redundant, not incorrect) | Not re-checked; cosmetic |
| IN-02 | `HashtagNormalizer.truthy?/1`'s name invites boolean misuse | Not re-checked; cosmetic |

None of these affect the 5 roadmap success criteria or any plan's must-have truths. Recorded here for
traceability, not as gaps.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|-----------------|--------------|--------|----------|
| CATALOG-01 | 01-02, 01-03, 01-04, 01-05 | Browse full catalog, cover images, carousels/cards, LiveView streams | ✓ SATISFIED | `stream/3` used in `CatalogLive.Index`; 434 games live; carousel rows render |
| CATALOG-02 | 01-05 | Filter by player count, playtime, category/mechanic/theme, min age (text[]+GIN) | ✓ SATISFIED | `filter_games/1` composed pipeline; GIN indexes on `mechanics`/`themes`/`tags` confirmed in migration |
| CATALOG-03 | 01-04, 01-05 | Search by keyword via tsvector | ✓ SATISFIED | Live accent-insensitive search proven against real seeded titles |
| CATALOG-04 | 01-05 | Sort by playtime, complexity, other scalar fields | ✓ SATISFIED | 6 sort keys implemented, nulls-last tested |
| CATALOG-05 | 01-04, 01-06 | Plain-Spanish weight-band + descriptor, not a bare number | ✓ SATISFIED | Live detail page renders label + descriptor; `bgg_weight` never templated |
| CATALOG-06 | 01-04, 01-05, 01-06 | Plain-Spanish mechanic/theme chips, curated vocabulary | ✓ SATISFIED | Live chips are 100% Spanish; 35/32-term glossary reconciled against real seed data |
| CATALOG-07 | 01-04, 01-06 | Club editorial tags as "club favorite"/"beginner-friendly" signal | ✓ SATISFIED | All 6 hashtags render verbatim, uniform chip treatment, live-confirmed on a real game |
| CATALOG-08 | 01-03 | Fully public, no account required | ✓ SATISFIED | No auth plug on either catalog route; live unauthenticated `curl` returns 200 |
| CATALOG-09 | 01-01, 01-03, 01-04, 01-06 | Club's own resized images, never hotlinked | ✓ SATISFIED | Zero BGG-hosted image references anywhere rendered; CSP `img-src` also scoped away from BGG hosts |

**No orphaned requirements** — every CATALOG-0N id declared across the 6 plans' frontmatter matches
REQUIREMENTS.md's Phase 1 traceability table exactly (CATALOG-01 through CATALOG-09).

**Documentation-sync note (not a functional gap):** `.planning/REQUIREMENTS.md`'s checkboxes and
Traceability table still show CATALOG-05/06/07 as `[ ]` / "Pending" even though this verification
confirms all three are implemented, tested, and live-demonstrated. This is a stale-tracking-doc issue
(the phase-completion doc-sync step has not run yet), not evidence the features are missing —
recommend updating those 3 rows to `[x]` / "Complete" as part of closing this phase.

### Anti-Patterns Found

No new blocker-level anti-patterns found. Debt-marker scan (`TBD`/`FIXME`/`XXX`) across all
phase-modified files returned none referencing unresolved work without a tracked follow-up. The
0 `TODO`/`HACK`/`PLACEHOLDER` scan across the same files was likewise clean of unreferenced markers.
The 4 warnings + 2 info items from 01-REVIEW.md (table above) are style/robustness debt, not
placeholders or stubs, and are explicitly scoped as non-blocking per this verification's task
instructions.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full test suite passes | `MIX_ENV=test mix test` | 140 tests, 0 failures | ✓ PASS |
| `mix quality` gate (format/credo/sobelow/hex.audit/deps.audit) | `mix format --check-formatted && mix credo --strict && mix sobelow --config && mix hex.audit && mix deps.audit` | All exit 0; Credo: 1 low-severity style suggestion (pre-existing, unrelated to this phase); Sobelow: 4 low-confidence `Traversal.FileModule` findings on dev-only seed scripts (pre-existing, not new); no `Config.CSP` finding surfaces (exemption + real header coexist correctly) | ✓ PASS |
| Asset build produces both `app.js` and `theme.js` (CR-01 fix) | `mix assets.build` | `app.js` 302.9kb, `theme.js` 1.2kb both built | ✓ PASS |
| Live server: home page unauthenticated | `curl -sI http://localhost:4000/` | `200 OK` | ✓ PASS |
| Live server: CSP header present and scoped | `curl -sI http://localhost:4000/` | `content-security-policy: default-src 'self'; img-src 'self' data: https://images.test.invalid; ... script-src 'self'; ...` | ✓ PASS |
| Live server: detail page for a real enriched game | `curl http://localhost:4000/juegos/208` (Alhambra) | Weight band "Descubre el hobby" + descriptor + Spanish mechanic chips render | ✓ PASS |
| Live server: detail page for a game with editorial tags | `curl http://localhost:4000/juegos/219` (Sky Team) | All 3 club hashtags render verbatim | ✓ PASS |
| Live server: detail page for a no-BGG-ID game (D-18) | `curl http://localhost:4000/juegos/79` (discordia) | 200, brand placeholder, no crash | ✓ PASS |
| Live server: 404 for nonexistent game id | `curl -o /dev/null -w '%{http_code}' http://localhost:4000/juegos/999999999` | `404` | ✓ PASS |
| R2-hosted image actually fetchable | `curl -I https://pub-8f05...r2.dev/games/6249/cover-large.webp` | `200 image/webp` | ✓ PASS |
| Accent-insensitive Spanish search against real data | `mix run -e` querying `websearch_to_tsquery('spanish_unaccent','codigo')` | Matches `"Descifra el código"` and `"Código Seceto Duo"` | ✓ PASS |
| Duplicate BGG_ID 163412 both rows survive (D-19) | `mix run -e` DB count | 2 | ✓ PASS |
| Weight-band coverage matches plan math (D-05/D-20) | `mix run -e` DB count | 408 (= 377 hashtag + 31 tie-break, per 01-04-PLAN.md) | ✓ PASS |
| Production deploy state | `curl --compressed https://pukllay.club/` | Still Phase 0's stock `mix phx.new` welcome page (`lang="en"`, old inline theme script, generated marketing links) | ℹ️ NOT YET SHIPPED (see Human Verification) |

### Probe Execution

No `scripts/*/tests/probe-*.sh` convention exists in this project and none is declared in any Phase 1
plan or SUMMARY — SKIPPED (no runnable probe entry points in this stack; verification instead used
direct `mix test`, `mix run -e`, and live `curl` checks against a real `mix phx.server` instance,
which is the load-bearing evidence throughout this report).

## Gaps Summary

No gaps found. All 5 ROADMAP.md success criteria and all 6 plans' must-have truths are implemented,
wired, and independently re-confirmed against the actual codebase and a live local server — not
trusted from SUMMARY.md claims alone. The one genuinely critical issue from code review (CR-01, CSP
blocking inline script) was independently re-verified as fixed, holding under a real
`mix assets.build` and a live response header check.

Status is `human_needed` rather than `passed` solely because of the 6 items in the frontmatter
`human_verification` list above — all either genuinely require human eyes on a real browser
(visual/interaction confirmation), are domain-acceptability judgment calls for the club (not code
correctness), or are the not-yet-executed production deploy step (which this project's own workflow
treats as a separate, later `/gsd-ship` action, not part of phase-goal codebase verification).

---

_Verified: 2026-08-11_
_Verifier: Claude (gsd-verifier)_
