---
phase: quick-260912-mxq
plan: 01
subsystem: docs
tags: [debug-lifecycle, planning-hygiene, catalog, about-page, cierre]

requires: []
provides:
  - "12 of 13 diagnosed G-01.x debug sessions verified against current code and closing gap-closure plans, moved to .planning/debug/resolved/ with filled fix/verification/files_changed"
  - "1 of 13 (G-01-7) left diagnosed with a newly-identified live recurrence documented for follow-up"
affects: [debug-knowledge-base, planning-hygiene]

actuals:
  tokens: 11700
  tasks: 3
  commits: 3
plan_head_before: bd3592c292bdd4aa9e697c7360b45a69169f7836

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - .planning/debug/resolved/G-01-2-badge-title-overlap.md
    - .planning/debug/resolved/G-01-3-catalog-grid-overflow.md
    - .planning/debug/resolved/G-01-4-carousel-affordance.md
    - .planning/debug/resolved/G-01-4-section-hierarchy.md
    - .planning/debug/resolved/G-01-5-expansions-in-recent.md
    - .planning/debug/resolved/G-01-6-card-info-density.md
    - .planning/debug/resolved/G-01.4-1-isologo-morph-blink.md
    - .planning/debug/resolved/G-01.4-2-map-thumb-coverage.md
    - .planning/debug/resolved/G-01.5-4-hero-cierre-composition-balance.md
    - .planning/debug/resolved/G-01.5-5-cierre-footer-gap.md
    - .planning/debug/resolved/G-01.5-6-cierre-top-bottom-whitespace.md
    - .planning/debug/resolved/G-01.5-7-cta-bar-background-visible.md

key-decisions:
  - "G-01-6's root cause (three stacked chip/badge rows on the resting GameCard) was resolved not by its own closing plan (01-07, which grouped/capped the rows) but by a LATER plan (01-10) that stripped the resting card to poster+title only and moved every chip to GamePreview — applied decision rule 4(c) (mechanism replaced/removed entirely) rather than treating 01-07 as the sole fix"
  - "G-01-7 (double focus ring) stays diagnosed: while the original reproduction sites (nav search box, sort select) are fixed via CoreComponents.input/1's focus:outline-hidden suppression, a later quick task (260824-b71) introduced a new raw <input class=\"input input-ghost\"> in filter_modal.ex's checklist search box that bypasses CoreComponents.input/1 and still exhibits the exact daisyUI double-ring mechanism this root cause diagnosed — the general architectural claim (not just the literal reproduction) still holds somewhere in the app"
  - "For G-01.4-2 and G-01.5-4, cited both the closing plan AND a subsequent superseding plan (01.4-12 replacing the map screenshot with a live embed; the fidelity fix in 01.5-10 being separate from the process/bookkeeping half of G-01.5-4) since the root cause's mechanism moved between plans without ever reverting"

patterns-established: []

requirements-completed: []

coverage: []

duration: ~55min
completed: 2026-09-12
status: complete
---

# Phase quick-260912-mxq Plan 01: Close out the 13 diagnosed G-01.x debug sessions Summary

**12 of 13 stale `status: diagnosed` G-01.x debug sessions verified against current code and their closing gap-closure plans, then moved to `.planning/debug/resolved/` with plan-id + commit-cited fix/verification; the 13th (G-01-7, double focus ring) stays diagnosed because a later quick task introduced a new unsuppressed plain-`.input` render site reproducing the exact daisyUI double-ring mechanism.**

## Performance

- **Duration:** ~55 min
- **Tasks:** 3
- **Files modified:** 12 (moved + edited); 1 left byte-identical (G-01-7)

## Accomplishments
- Verified all 13 G-01.x debug sessions' `root_cause` against current `lib/`/`assets/` code, citing concrete `path:line` evidence and the plan id + commit sha(s) that closed each one
- 12 sessions moved to `.planning/debug/resolved/` with `status: resolved`, a one-line `fix:`, a per-cause `verification:` block, and a non-empty `files_changed:` list — `root_cause` preserved byte-identical to baseline in every case
- G-01-7 correctly identified as still-live: the closing plan's fix (01-07) holds at its original sites, but `filter_modal.ex`'s later-added checklist search input (quick task 260824-b71) bypasses the suppression and reproduces the same daisyUI `.input:focus` double-ring defect
- `.planning/debug/` now lists only genuinely open investigations from this item's scope (G-01-7 plus the 6 non-G-01 sessions owned by sibling item 260912-mxr)

## Task Commits

Each task was committed atomically:

1. **Task 1: Close out the seven G-01-* catalog debug sessions** - `e99c2ab` (docs)
2. **Task 2: Close out the two G-01.4-* About-page debug sessions** - `b3516b1` (docs)
3. **Task 3: Close out the four G-01.5-* Cierre/CTA debug sessions** - `01ef0eb` (docs)

## Files Created/Modified
- `.planning/debug/resolved/G-01-2-badge-title-overlap.md` - resolved by plan 01-07 (`2fae9a7`)
- `.planning/debug/resolved/G-01-3-catalog-grid-overflow.md` - resolved by plans 01-08/01-11
- `.planning/debug/resolved/G-01-4-carousel-affordance.md` - resolved by plan 01-11
- `.planning/debug/resolved/G-01-4-section-hierarchy.md` - resolved by plan 01-08
- `.planning/debug/resolved/G-01-5-expansions-in-recent.md` - resolved by plan 01-09
- `.planning/debug/resolved/G-01-6-card-info-density.md` - resolved by plan 01-10 (superseding 01-07's own fix)
- `.planning/debug/resolved/G-01.4-1-isologo-morph-blink.md` - resolved by plan 01.4-06
- `.planning/debug/resolved/G-01.4-2-map-thumb-coverage.md` - resolved by plan 01.4-07 (fix reused over 01.4-12's live embed)
- `.planning/debug/resolved/G-01.5-4-hero-cierre-composition-balance.md` - resolved by plan 01.5-10
- `.planning/debug/resolved/G-01.5-5-cierre-footer-gap.md` - resolved by plan 01.5-09
- `.planning/debug/resolved/G-01.5-6-cierre-top-bottom-whitespace.md` - resolved by plan 01.5-09
- `.planning/debug/resolved/G-01.5-7-cta-bar-background-visible.md` - resolved by plan 01.5-10
- `.planning/debug/G-01-7-double-focus-ring.md` - **unchanged**, stays diagnosed (see below)

## Decision Table (13 of 13)

| Debug file | Decision | Closing plan id(s) | Commit sha(s) | Key current-code evidence |
|---|---|---|---|---|
| G-01-2-badge-title-overlap | resolved | 01-07 | `2fae9a7` | `lib/pukllay_club_web/components/game_chips.ex:52` — `badge-lg h-auto whitespace-normal` still on the weight-band `<span>` |
| G-01-3-catalog-grid-overflow | resolved | 01-08, 01-11 | `7ba31b4`/`61e4ba1`/`72a8451`/`8e4a1d5`, `2265d13`/`31b63a0`/`a9155f3`/`7c642c8` | `lib/pukllay_club_web/components/carousel_row.ex:236-278` — daisyUI `.carousel` replaced by `.pk-rail-wrap`/`.pk-rail` with visible prev/next controls; 0 hits for `carousel-item`/`class="carousel` |
| G-01-4-carousel-affordance | resolved | 01-11 | `2265d13`/`31b63a0`/`a9155f3`/`7c642c8` | `carousel_row.ex:236` `.pk-rail-wrap` carries `w-full`; `.CarouselScroll`'s overflow check now fires against a clipped rail |
| G-01-4-section-hierarchy | resolved | 01-08 | `7ba31b4`/`61e4ba1` | `lib/pukllay_club_web/live/catalog_live/index.ex:785-786` (`row_variant/1`), `:837-839` (`main_grid_heading/1`) |
| G-01-5-expansions-in-recent | resolved | 01-09 | `7a3ea20`/`f94bc85`/`0ef4ef4`/`9896692`/`9846086`/`65d9930` | `lib/pukllay_club/catalog.ex:438-441` `recent_query/0`'s `where: g.is_expansion == false` |
| G-01-6-card-info-density | resolved | 01-10 (supersedes 01-07) | `5944382` (`5e95f1e` was the earlier, later-superseded attempt) | `lib/pukllay_club_web/components/game_card.ex:66-107` — zero chip/badge rendering on the resting card; 0 hits for `weight_band_badge\|editorial_tags\|chip_row` |
| G-01-7-double-focus-ring | **stays diagnosed** | — | — | `lib/pukllay_club_web/components/filter_modal.ex:478-484` — raw `<input class="input input-ghost">` bypasses `CoreComponents.input/1`'s suppression |
| G-01.4-1-isologo-morph-blink | resolved | 01.4-06 | `13a45ea`/`2fce58f`/`6a268bf` | `lib/pukllay_club_web/live/about_live.ex:80-81` (`data-morph-armed`), `assets/css/app.css:4257-4260` (untransitioned `body:has()` hide); transform-based `.write()`/`.frame()` driver, `--ease-standard` |
| G-01.4-2-map-thumb-coverage | resolved | 01.4-07 (reused over 01.4-12) | `3238c3d`/`150cd1d`/`a83c0e5`; `f35393e`/`95176d2`/`01b32ad`/`f1215b9`/`37b3479` | `about_live.ex:769-772` short/long caption split; `app.css:4060-4079` opaque bordered single-line chip; `app.css:3937-3939` `min-height: 7rem` floor |
| G-01.5-4-hero-cierre-composition-balance | resolved | 01.5-10 | `0e99941` | `lib/pukllay_club_web/components/layouts.ex:915-921` `.pk-sumate-btn`; `app.css:3045-3049` 28px padding-inline/9999px radius/16px font/48px height; 01.5-UAT.md `status: closed` |
| G-01.5-5-cierre-footer-gap | resolved | 01.5-09 | `5a5d7c3` | `app.css:6069-6072` `body:has(#cierre) main.* + .pk-footer { margin-top: 0 }`, shared 1.5rem rule intact for catalog/detail |
| G-01.5-6-cierre-top-bottom-whitespace | resolved | 01.5-09 | `50c41b0` | `app.css:3499-3501` `padding-block: 5rem` (8rem gone); `test/visual/about_geometry.mjs` — `CIERRE_DESKTOP_GAP_TARGET_PX` deleted, `checkCierreRunRatioBudget` added |
| G-01.5-7-cta-bar-background-visible | resolved | 01.5-10 | `e42d713` | `app.css:3251` `border-top: 1px solid var(--color-neutral)`; `app.css:6888-6889` `padding-bottom: var(--pk-about-cta-bar-h, ...)` |

## Still Diagnosed

**G-01-7-double-focus-ring** (`.planning/debug/G-01-7-double-focus-ring.md`, left completely untouched).

- **Cause that still holds:** daisyUI's `.input`/`.select` component renders a persistent field border PLUS a separate `outline: 2px solid var(--input-color); outline-offset: 2px` on `:focus`/`:focus-within` (confirmed still present at `priv/static/assets/css/app.css:1300-1306`). Plan 01-07 correctly suppressed this on every render site that goes through `CoreComponents.input/1` (`focus:outline-hidden focus-within:outline-hidden` on all three branches, confirmed live) and on the raw sort `<select>` that existed at the time. But `lib/pukllay_club_web/components/filter_modal.ex`'s `checklist/1` component — added later by quick task 260824-b71, well after phase 01 closed — renders a raw `<input type="text" ... class="input input-ghost ...">` (line 478-484) that deliberately bypasses `CoreComponents.input/1` (per the component's own comment: "A raw `<input>` is used ... which wraps its field in a fieldset this layout has no room for") and carries no suppression classes at all.
- **Current path:line:** `lib/pukllay_club_web/components/filter_modal.ex:478-484` (the `<input>` element), class list at line 482.
- **UAT status of the gap:** G-01-7 is recorded as closed/passed in `01-VERIFICATION.md` and the v1.0 milestone audit ("Passed (5/7): ... G-01-7 focus ring ...") — that verification is correct for the sites it covered (nav search box, sort select) and predates the filter-modal checklist input's introduction, so it never had a chance to catch this.
- **Recommended next step:** a `/gsd-debug` session (or a direct fix) scoped to `filter_modal.ex`'s `checklist/1` component, applying the same `focus:outline-hidden focus-within:outline-hidden` suppression pattern plan 01-07 established, OR routing the checklist search input through `CoreComponents.input/1` if the fieldset-wrapping concern that originally justified the raw `<input>` can be worked around. Left as a new/renewed finding rather than resolved on assumption, per this item's scope fence against editing files outside its 13-file list.

## Decisions Made

- Applied decision rule 4(c) (code replaced/removed entirely) for G-01-6: its own closing plan (01-07) is not what makes the root cause false today — a later plan (01-10) removed the entire mechanism the root cause lived in. Cited both commits in `fix:` rather than only the original closing plan, so a future reader isn't misled into thinking 01-07 alone is why the card looks the way it does now.
- Applied decision rule 4(c) again for G-01.4-2: the underlying screenshot the root cause diagnosed was later replaced by a live Google Maps embed (plan 01.4-12), but the caption-chip fix from the original closing plan (01.4-07) is reused verbatim over the new embed, so the root cause is genuinely gone rather than accidentally still-true.
- Did NOT resolve G-01-7 on the strength of its own UAT "closed" status alone (per the plan's explicit Step 4 instruction) — grepped the live codebase for any plain `.input`/`.select` render site bypassing `CoreComponents.input/1`, found one, and kept the file diagnosed rather than assuming the historical UAT closure still applies to code written after it.
- For G-01.5-4, treated the diagnosis's two independent causes (visual button-geometry fidelity + process/bookkeeping mis-attribution) as both required to be closed before marking resolved; verified each independently against current code and the reconciled `01.5-UAT.md` record rather than inferring the process half was fixed just because the visual half was.

## Deviations from Plan

None - plan executed exactly as written. All 13 files were processed per the closure_protocol; no auto-fixes, blocking issues, or architectural decisions arose outside the diagnosis-verification work itself.

## Issues Encountered

None. All evidence was gathered via static `grep`/`Read`/`git log`/`git show` per the plan's evidence-only constraint (no dev server started, no `mix` run).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `.planning/debug/` no longer carries stale `diagnosed` entries for the 12 sessions this item resolved; the directory now more accurately reflects genuinely open work.
- G-01-7 remains as a real, currently-reproducing defect (not a stale record) and should be picked up as its own small fix or folded into a future UI-polish pass on `filter_modal.ex`.
- Sibling batch item 260912-mxr owns the remaining 6 non-G-01 diagnosed sessions in `.planning/debug/` and was not touched by this item.

---
*Phase: quick-260912-mxq*
*Completed: 2026-09-12*

## Self-Check: PASSED

All 13 debug files verified present at their expected location (12 in `.planning/debug/resolved/`, 1 still at `.planning/debug/`) via `ls`. All 3 task commit hashes (`e99c2ab`, `b3516b1`, `01ef0eb`) confirmed present via `git log --oneline`.
