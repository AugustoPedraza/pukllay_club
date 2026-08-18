---
phase: 01-catalog-v1
plan: 08
subsystem: ui
tags: [phoenix-liveview, daisyui, tailwind, colocated-hooks, gap-closure]

requires:
  - phase: 01-catalog-v1 (01-05)
    provides: CarouselRow component, 8 fixed D-09 carousel rows, Catalog.list_carousel_rows/0
  - phase: 01-catalog-v1 (01-07)
    provides: GameCard/GameChips chip hierarchy this plan's headers now sit above

provides:
  - CarouselRow.carousel_row/1 variant/subtitle attrs (hero colour ranking + one-line
    plain-Spanish row descriptions), with skeleton_row/1 footprint-matched
  - CatalogLive.Index row_variant/1 and row_subtitle/1 wiring per-row copy from
    PukllayClub.Catalog.Vocabulary, plus a titled main-grid section header
  - A .CarouselScroll colocated LiveView hook giving every carousel rail
    persistent, self-hiding prev/next scroll controls
affects: []

actuals:
  tokens: 3085
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Phoenix.LiveView.ColocatedHook (<script :type={...} name=\".Hook\">) defined inside the
      same component template as its caller, extracted at compile time into
      _build/*/phoenix-colocated with zero app.js/config.exs edits"
    - "ResizeObserver-driven controls-visibility sync (classList.toggle('hidden', ...)) as the
      pattern for any future rail/overflow-dependent affordance in this app"

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/components/carousel_row.ex
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - test/pukllay_club_web/live/catalog_live_test.exs

key-decisions:
  - "row_variant/1 ranks only :destacados_del_club as :hero (text-primary h2), all other 7 rows stay :standard — colour is the emphasis lever, not a fourth type size, per ui-design-system's 3-level cap"
  - "6 of 8 row subtitles reuse already-user-reviewed D-05/D-06 copy verbatim: 3 editorial-hashtag rows pull Vocabulary.editorial_tags/0's :meaning, 3 weight-band rows pull Vocabulary.weight_band/1's :descriptor — this also teaches the complexity band at the shelf header, not just on the detail page"
  - "2 new subtitles authored for :destacados_del_club (\"La selección del club — los juegos que más recomendamos ahora mismo.\") and :recientemente_anadidos (\"Las incorporaciones más nuevas a la ludoteca.\") — both under 60 chars, warm second-person-adjacent register matching the existing descriptors; NOT yet user-reviewed, flagged below"
  - "Main grid heading text is state-dependent via filters_active?/1: \"El catálogo completo\" unfiltered, \"Resultados\" filtered — \"the whole catalogue\" would be a false claim once filters narrow the set; the header itself always renders, including on the zero-result view"
  - "ux-patterns B9's 5-frame carousel cap does NOT apply here and @carousel_limit stays at 20: B9's cap is written for a hero/banner carousel where one frame must stand in for the whole; a GameCard content rail is the explicit flip case ('every single frame alone still gives an accurate impression') since each card is independently meaningful on its own"
  - "Controls-visibility uses Tailwind's own cascade order (verified: .hidden{display:none} is emitted after .flex{display:flex} in the compiled stylesheet, so a static 'hidden flex items-center gap-2' class list correctly starts hidden and correctly shows once JS removes 'hidden') — same idiom already shipped in game_card.ex's cover-image fallback, not a new pattern"

patterns-established:
  - "Colocated-hook-per-component for any future rail/scroll/overflow affordance: define the hook inline in the same .ex file as its markup rather than a standalone assets/js/hooks/*.js file"

requirements-completed: [CATALOG-01, CATALOG-05, CATALOG-07]

coverage:
  - id: G-01-4-subtitles
    description: "Each of the 8 carousel rows carries its own plain-Spanish one-line subtitle so no two section boundaries read identically"
    requirement: "CATALOG-05"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — 'the hero row renders in the primary colour and a weight-band row renders its Vocabulary descriptor as a subtitle'"
        status: pass
    human_judgment: true
    rationale: "The two newly-authored subtitle strings (destacados_del_club, recientemente_anadidos) are unreviewed editorial copy — plan output explicitly requires human sign-off on tone/register at end-of-phase UAT, per the plan's own <human-check> block."
  - id: G-01-4-hero-rank
    description: "The curated hero row is visually ranked above the other 7 rows by colour (text-primary), without introducing a fourth type size"
    verification:
      - kind: unit
        ref: "grep -c 'text-primary' lib/pukllay_club_web/components/carousel_row.ex -> 1 (class list, conditional on :hero variant)"
        status: pass
    human_judgment: false
  - id: G-01-4-grid-header
    description: "The main catalog grid reads as its own titled section (font-display h2) rather than trailing off a muted result-count line"
    requirement: "CATALOG-05"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — 'the unfiltered landing render contains the main-grid section heading', 'a filtered render shows the results-wording heading and hides the carousel block'"
        status: pass
    human_judgment: false
  - id: G-01-3-controls
    description: "Persistent, self-hiding prev/next scroll controls make every carousel rail's scrollability discoverable without hover, dragging, or accidental discovery; controls hide themselves on a rail with nothing to scroll to"
    requirement: "CATALOG-07"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — 'the landing render includes the rail marker and both scroll controls with Spanish aria-labels, and no inline script tag'"
        status: pass
      - kind: other
        ref: "mix assets.build && grep -c 'CarouselScroll' priv/static/assets/js/app.js -> 1 (hook bundled, not inlined)"
        status: pass
    human_judgment: true
    rationale: "Self-hiding behavior (ResizeObserver + scrollWidth/clientWidth comparison) and actual click-to-scroll interaction need a real browser render to confirm visually — plan's own <human-check> puts the G-01-3 reclassification question directly to the user at end-of-phase UAT."
  - id: skeleton-footprint
    description: "The loading skeleton keeps the same two-line-header footprint as the real row after the subtitle line is added, so the page does not reflow when data arrives"
    verification:
      - kind: other
        ref: "carousel_row.ex skeleton_row/1 wraps two skeleton bars in the same space-y-1 div as the real h2+p pair"
        status: pass
    human_judgment: false

duration: ~20min (commit-span; excludes upfront context-reading time)
completed: 2026-08-18
status: complete
---

# Phase 01 Plan 08: UAT gap closure — differentiated section headers, titled main grid, discoverable carousel scroll Summary

**8 carousel rows now carry distinct hero-ranked/subtitle headers sourced from Vocabulary D-05/D-06 copy, the main grid gained its own font-display section heading, and every rail got a persistent self-hiding prev/next scroll affordance via a colocated LiveView hook — closing G-01-4 and G-01-3.**

## Performance

- **Duration:** ~20 min (commit-span)
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- `CarouselRow.carousel_row/1` gained `:variant` (`:standard | :hero`) and `:subtitle` attrs — the hero row (Destacados del club) renders `text-primary`, and any row with a subtitle renders it as `text-neutral text-sm` beneath the heading in a shared `space-y-1` unit; `skeleton_row/1` reserves the identical two-line footprint so no layout shift occurs on data arrival
- `CatalogLive.Index` wires `row_variant/1`/`row_subtitle/1` per D-09 row key: 3 editorial-hashtag rows and 3 weight-band rows reuse already-user-reviewed `Vocabulary.editorial_tags/0`/`weight_band/1` copy verbatim; 2 rows (Destacados del club, Recientemente añadidos) got newly authored one-line Spanish copy flagged below for review
- The main `#games` grid now renders under its own `font-display text-2xl` heading (`El catálogo completo` unfiltered, `Resultados` filtered via `filters_active?/1`), with the existing result-count paragraph demoted to its subtitle line — the header always renders, including on the zero-result empty-state view
- A `.CarouselScroll` colocated hook (`Phoenix.LiveView.ColocatedHook`, zero `app.js`/`config.exs` edits) gives every non-empty carousel row persistent `btn-circle size-11` prev/next controls with Spanish `aria-label`s; a `ResizeObserver` + `scrollWidth`/`clientWidth` comparison hides the controls whenever a rail has nothing to scroll to
- The `carousel_row.ex` moduledoc now records the G-01-3 reclassification: the rail's horizontal scroll was always intentional (daisyUI `.carousel`), not the responsive `#games` grid — the missing affordance was daisyUI's `scrollbar-width: none` removing the only native scroll cue

## Task Commits

Each task was committed atomically:

1. **Task 1: Give carousel_row/1 a variant and a subtitle, keep the skeleton in step** - `7ba31b4` (feat)
2. **Task 2: Wire per-row copy from the vocabulary and give the main grid its own section header** - `61e4ba1` (feat)
3. **Task 3: Add persistent, self-hiding scroll controls to every carousel rail** - `72a8451` (feat)

**Post-task fix:** `8e4a1d5` (style — `mix format` on Task 2/3 files, caught by `mix quality`)

## Files Created/Modified

- `lib/pukllay_club_web/components/carousel_row.ex` — variant/subtitle attrs, matching skeleton footprint, `.CarouselScroll` colocated hook, persistent prev/next controls, moduledoc records G-01-3 reclassification
- `lib/pukllay_club_web/live/catalog_live/index.ex` — `alias PukllayClub.Catalog.Vocabulary`, `row_variant/1`, `row_subtitle/1`, `main_grid_heading/1`, titled `#games` section header
- `test/pukllay_club_web/live/catalog_live_test.exs` — new coverage for hero colour + weight-band subtitle, main-grid heading (unfiltered/filtered), rail markers/controls/no-inline-script; one pre-existing 01-07 test scoped to `grid_html/1` (see Deviations)

## Decisions Made

- `row_variant/1` ranks only `:destacados_del_club` as `:hero` — every other row stays `:standard`; colour, not a fourth type size, is the emphasis lever (ui-design-system's 3-level cap)
- 6 of 8 subtitles are Vocabulary reuse (D-05/D-06, already user-reviewed); 2 are newly authored (`:destacados_del_club`, `:recientemente_anadidos`) and are **not yet user-reviewed** — see "Known Stubs / Unreviewed Copy" below
- Main grid heading wording is state-dependent (`El catálogo completo` / `Resultados`) since "the whole catalogue" is a false claim once filters narrow the result set; the header block itself is unconditional so the zero-result empty state still shows it
- ux-patterns B9's 5-frame carousel cap does not apply and `@carousel_limit` stays at 20 — B9's cap targets a hero/banner carousel where one frame must stand for the whole; a `GameCard` content rail is the explicit flip case since every card is independently meaningful. Recorded per the plan's design-system-contract instruction.
- The controls wrapper's static `"hidden flex items-center gap-2"` class list relies on Tailwind's compiled cascade order (`.hidden{display:none}` is emitted after `.flex{display:flex}` in `priv/static/assets/css/app.css`, verified directly) rather than JS toggling both classes — the same idiom `game_card.ex`'s cover-image fallback already ships, not a new pattern introduced here

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Scoped a pre-existing 01-07 test assertion that collided with this plan's new subtitle feature**
- **Found during:** Task 2, running the LiveView test suite after wiring `row_subtitle/1`
- **Issue:** `test/pukllay_club_web/live/catalog_live_test.exs`'s "renders the card's weight-band label but not its descriptor (CATALOG-05)" test asserted `refute html =~ "Reglas de 15-20 minutos"` (the `ingenio_estratega` weight-band descriptor) against the *whole page*. Once Task 2 wired weight-band descriptors into the matching carousel row's subtitle, a fixture with `weight_band: "ingenio_estratega"` legitimately causes that descriptor text to appear in the "Ingenio estratega" row's subtitle — a correct, intended G-01-4 behavior that the old whole-page assertion misread as a regression.
- **Fix:** Scoped both the `assert`/`refute` in that test to `grid_html/1` (the file's existing `#games`-scoped helper, established in 01-05 for exactly this class of whole-page-vs-region collision), so the assertion targets only the card badge and is unaffected by the new row-subtitle feature.
- **Files modified:** `test/pukllay_club_web/live/catalog_live_test.exs`
- **Verification:** Full `catalog_live_test.exs` suite green (34 tests, 0 failures) before and after.
- **Committed in:** `61e4ba1` (Task 2 commit)

**2. [Rule 3 - Blocking] Ran `mix format` on Task 2/3 files after `mix quality` flagged them**
- **Found during:** post-Task-3 `mix quality` run
- **Issue:** Two `row_subtitle/1` clauses in `index.ex` exceeded the formatter's line-length preference (unsplit `defp ... , do: "..."` on one line) and a new test in `catalog_live_test.exs` was missing a blank line before a multi-line assignment — both caught by `mix format --check-formatted`.
- **Fix:** Ran `mix format` on the two affected files.
- **Files modified:** `lib/pukllay_club_web/live/catalog_live/index.ex`, `test/pukllay_club_web/live/catalog_live_test.exs`
- **Verification:** `mix quality` green end to end afterward (163 tests, 0 failures; only the two pre-existing accepted Credo/Sobelow findings noted in 01-07's summary, neither newly introduced).
- **Committed in:** `8e4a1d5`

---

**Total deviations:** 2 auto-fixed (1 test-scoping bug fix, 1 formatting fix). No scope creep.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None — no external service configuration required.

## Known Stubs / Unreviewed Copy

Not a stub, but flagged per the plan's own output spec: two subtitle strings are newly authored editorial copy that has **not** been through the user review pass the rest of the Vocabulary module's D-05/D-06 strings received:

- `:destacados_del_club` → "La selección del club — los juegos que más recomendamos ahora mismo."
- `:recientemente_anadidos` → "Las incorporaciones más nuevas a la ludoteca."

Both are defined as private clauses of `row_subtitle/1` in `lib/pukllay_club_web/live/catalog_live/index.ex` (not in `Vocabulary`, since they are page-level copy, not glossary terms). Correct in place at end-of-phase UAT if the club's voice doesn't land — this is exactly the check the plan's Task 2 `<human-check>` calls for.

## Next Phase Readiness

- G-01-4 and G-01-3 closed per the plan's success criteria: 8 visually/semantically distinct shelves, a titled main grid, hero row ranked by colour, and persistent discoverable scroll controls on every rail
- `mix quality` passes end to end (hex.audit, deps.audit, deps.unlock --check-unused, format, credo --strict, sobelow, test — 163 tests, 0 failures); only pre-existing accepted findings remain (same Credo `Design.AliasUsage` note on `core_components.ex`, same 4 low-confidence Sobelow `Traversal.FileModule` findings on the seed pipeline, both noted in 01-07)
- `mix assets.build` succeeds; `.CarouselScroll` confirmed present in the bundled `priv/static/assets/js/app.js` (1 occurrence) with zero `app.js`/`config.exs` diff
- Human-check items remain for end-of-phase UAT per the plan's own `<human-check>` blocks, per `human_verify_mode: end-of-phase`: (1) visual confirmation that all 8 shelves + main grid read as distinct sections and the hero row visibly outranks the rest; (2) the two newly authored subtitles read naturally in Spanish and match the club's voice; (3) clicking the prev/next controls actually scrolls a rail and a short rail shows no controls; (4) the direct G-01-3 reclassification question — was the originally reported "~20 columns forcing horizontal scroll" a carousel rail or the `#games` grid — was not answered during this autonomous run and needs the user's direct confirmation
- No blockers for phase verification

---
*Phase: 01-catalog-v1*
*Completed: 2026-08-18*

## Self-Check: PASSED

All 3 modified files confirmed present on disk with expected content; all 4 commits
(`7ba31b4`, `61e4ba1`, `72a8451`, `8e4a1d5`) confirmed in `git log`.
