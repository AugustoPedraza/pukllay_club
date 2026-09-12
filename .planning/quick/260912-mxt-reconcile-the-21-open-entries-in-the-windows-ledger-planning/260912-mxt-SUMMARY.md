---
phase: quick-260912-mxt
plan: 01
subsystem: docs
tags: [windows-ledger, bookkeeping, gsd-ship-gate]

# Dependency graph
requires:
  - phase: v1.0 (all phases)
    provides: the 26-entry Broken Windows ledger accumulated across the v1.0 milestone
provides:
  - "Reconciled .planning/WINDOWS.md — 21 entries re-checked against current code/tests/UAT records, 10 closed fixed, 1 waived, 9 confirmed still genuinely open"
  - "Per-entry evidence trail (this SUMMARY's decision table) for every close/waive/leave-open decision"
affects: [gsd-ship, windows-ledger]

# Actuals (#2632)
actuals:
  tokens: 7128
  tasks: 3
  commits: 2
plan_head_before: a3124f9ca48db19d0f9ab8e6c6418ed58efe49b7

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/quick/260912-mxt-reconcile-the-21-open-entries-in-the-windows-ledger-planning/260912-mxt-SUMMARY.md
  modified:
    - .planning/WINDOWS.md

key-decisions:
  - "Entry 14 closed first as a tracer to confirm the `windows fixed`/`windows waive` CLI verb shapes before mutating the remaining 20 entries"
  - "Entries 10 and 12 closed fixed as 'moot' (not literally re-verified as passing) because the elements they compared no longer coexist after the 01.2 masthead redesign moved the share control off the CTA bar entirely — following the precedent already set by ledger entry 23's 'moot' closure"
  - "Entry 1 stays open despite `mix format`/`mix credo --strict`/`mix sobelow --config` all exiting 0: two of the three originally-named Sobelow findings (Traversal.FileModule in csv_import.ex and report.ex) are still literally present in the sobelow output, and the entry's own instructions require the named items be absent, not just the exit code be clean"
  - "Entry 24 stays open: the 70vh mechanism it named was replaced by a padding-block mechanism, closed only via an automated CDP probe (not a human-performed check), and no later human UAT record names 768px specifically"

patterns-established: []

requirements-completed: []

duration: 55min
completed: 2026-09-12
status: complete
---

# Quick Task 260912-mxt: Reconcile the 21 Open Windows Ledger Entries Summary

**Re-checked all 21 open Broken Windows ledger entries against current code, tests, and UAT/VERIFICATION records: closed 10 as fixed, waived 1 as an accepted deliberate change, and left 9 genuinely open with a documented reason and a concrete unblock action for each.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-09-12T20:20:00Z
- **Completed:** 2026-09-12T21:15:00Z
- **Tasks:** 3
- **Files modified:** 1 (`.planning/WINDOWS.md`)

## Decision Table

All 21 entries open at plan start (ids 1-19, 24, 25). Escaped `|` where a cell needed one.

| id | kind | phase | decision | evidence/reason |
|----|------|-------|----------|------------------|
| 1 | deviation | quick-260818-gdb | open | `MIX_ENV=test mix format --check-formatted` exit 0; `MIX_ENV=test mix credo --strict` exit 0 (887 mods/funs, no issues \| core_components.ex suggestion gone); `MIX_ENV=test mix sobelow --config` exit 0 BUT still reports `Traversal.FileModule` at `lib/pukllay_club/catalog/seed/csv_import.ex:41,27` and `lib/pukllay_club/catalog/seed/report.ex:143,142` — two of the three named items are still literally present in the output, so per the entry's own instructions it stays open even though all three exit codes are clean |
| 2 | deviation | quick-260822-2v9 | fixed | Commit `ecdb6c4` (2026-09-09) replaced the two-line brand lockup with a single-line "PUKLLAY CLUB" wordmark (155.3px vs the old 250px) and added `white-space: nowrap` on `.pk-brand-wordmark` (`assets/css/app.css:1678-1680`); `test/pukllay_club_web/header_capacity_test.exs` (re-run this session, 7 tests, 0 failures) is a derived-contract test that recomputes the row's content-arithmetic requirement from the stylesheet's own declarations and proves the row seats all content — brand + nav + trigger — at every width, with no cliff left where it cannot fit |
| 3 | unrun-verify | 01.1-09 | open | No `01.1-UAT.md` file exists for phase 01.1 (only `01-UAT.md` for the earlier catalog-v1 phase). Grepped every `*-UAT.md` in the repo for "drawer" — zero matches. 01.1-VERIFICATION's "Human Verification Required: None" is a verifier's own opinion, not a performed human check (as the plan's own evidence pointer flags) |
| 4 | unrun-verify | 01.1-09 | open | Same search as entry 3 — no UAT ever exercised the mobile drawer's rows/toggle/footer layout |
| 5 | unrun-verify | 01.1-09 | open | Same search as entry 3 — no UAT ever exercised the About sticky CTA bar / footer interaction this entry names |
| 6 | deviation | 01.1-02 | fixed | `lib/pukllay_club_web/live/about_live.ex:423-425` code comment: "Five-slide photo rail of real club photography (sketch 046, D-08, D-09) — the 'no real club photography exists yet' placeholder flag carried since D-07/D-12 is retired." Confirmed 5 real JPGs on disk: `priv/static/images/about-{juego,explicacion,ludoteca,comunidad,festejo}.jpg` (110KB-344KB each, non-placeholder file sizes) |
| 7 | unrun-verify | 01.1-02 | open | 01.4-UAT test 3 ("375px and 1280px screenshots of the five-photo rail", result: pass) covers only photo *content* (no face/hand/board cropping) — it does not cover the rail's interaction mechanics (dots scroll-sync, click-to-jump, auto-advance every 4.5s, pause-on-pointer/unfocused-tab/reduced-motion) that entry 7 names. No passed record found for those interaction claims |
| 8 | unrun-verify | 01.1-03 | fixed | Original 01.1-03 detail-page masthead structure was fully superseded by 01.2's redesign. 01.2-UAT test 3 ("Mobile masthead visual read at ~390px", result: pass, live-reconfirmed 2026-08-29) and test 9 ("Desktop masthead width + panel/CTA separation at 1280px/1440px" — "the poster column still sticks while the reading column scrolls", result: pass) cover the same sticky-poster/single-column-at-mobile observable on the current masthead |
| 9 | unrun-verify | 01.1-04 | fixed | 01.2-UAT test 7 ("Single-control CTA bar and recomputed body-padding clearance, live" — "the bar still hides mid-scroll and reappears with no new stutter; scrolling to the footer parks the bar with no leftover empty band", result: pass) and test 13 ("Title-echo bar's live scroll behavior" — mobile-only, single-line, footer-retraction reconfirmed live 2026-08-29, result: pass) cover the redesigned masthead's CTA-bar-visibility and title-echo-timing observable |
| 10 | unrun-verify | 01.1-04 | fixed | Moot: 01.2-UAT test 7 confirms the CTA bar now "holds only Reservar" (single control) — the share button entry 10 compared it against was relocated to the poster's own corner (test 3's "share icon reads as sitting on the artwork's corner"). The two elements this entry's comparison names no longer coexist in the same UI region to compare |
| 11 | unrun-verify | 01.2-13 | fixed | 01.2-UAT tests 4 (desktop buy-box/Reservar separation, pass), 9 (desktop sticky column, pass), 3/8/14/15 (mobile pills+photo+dots read as one bordered/shadowed card, share icon on the poster's corner, all pass, several live-reconfirmed 2026-08-29) collectively re-verify the "buy-box reads as one bounded panel" observable at both widths in both themes across the G-01.2-11/13 fix chain |
| 12 | unrun-verify | 01.2-13 | fixed | Moot: the stacked reserve+share bar entry 12 targets was replaced by 01.2-18's single-control bar (test 7: "holds only Reservar", share moved off the bar entirely onto the poster corner). Scroll-hide/reveal timing and footer-park behavior for the CURRENT bar are confirmed pass in that same test |
| 13 | unmet-truth | 01.2 | open | 01.2-UAT test 16 ("Chip system reads as visually unified... all four UAT-named surfaces", result: pass) confirms the catalog's "búsqueda activa" chips share one shape/radius/weight family with the other three chip surfaces — but does not judge the chip row's visual weight specifically against the Resultados heading, which is the comparison entry 13 names. No other record found addressing that specific comparison |
| 14 | unrun-verify | 01.3-02 | fixed | Closed in Task 1 (tracer). `01.3-UAT.md` test 2 ("BGG stat rows link to the correct game on real pages", result: pass) covers the exact observable named (formatted 10-point Valoración value, correct `boardgamegeek.com/boardgame/{bgg_id}` link); file frontmatter `status: complete` |
| 15 | todo | 01.3-02 | open | `lib/pukllay_club/catalog/seed/bgg_client.ex:33` — `fetch_batch/2`'s guard is still only `length(bgg_ids) <= @max_batch_size`, no `[]`-handling clause added. `git log --oneline -- lib/pukllay_club/catalog/seed/bgg_client.ex` shows no fix commit since the entry was recorded. Code change is out of this task's scope |
| 16 | unrun-verify | 01.3-04 | fixed | 01.3-UAT test 3 ("Spanish description language quality", result: pass) human-checked the language-quality half; its note states the expand/collapse mechanism is now covered by "an automated 6-transition round-trip test" — confirmed present and passing: `test/pukllay_club_web/live/catalog_show_test.exs:717` ("round trip: expand, collapse... three full cycles"), re-run this session, 1 test, 0 failures |
| 17 | unrun-verify | 01.3 | fixed | 01.3-UAT test 1 ("Recomposed reading-column visual read at 390px and 1440px", result: pass) confirms the title→hashtags→description→fact-grid→Comunidad BGG composition, no divider line, fact grid pairing/stacking, and "Avanzado" renamed to "Comunidad BGG" — matches entry 17's D-03/D-04/D-06 observables exactly |
| 18 | unrun-verify | 01.3 | open | 01.3-UAT test 1 (pass) covers 4 of entry 18's 5 named sub-items (hashtag position/tone, no divider, fact-grid pairing/stacking, Comunidad BGG label) but not "tappable creator pills" (Diseñadores/Ilustradores links). `01.3-07-SUMMARY.md` itself deferred that exact sub-item to end-of-phase UAT and no later test closes it — stays open for that one sub-item |
| 19 | unrun-verify | 01.3 | fixed | 01.3-UAT test 4 ("Description justify, mid-word-cut risk, and toggle ink alignment", result: pass) matches entry 19 verbatim: justify + mid-word-cut risk + chevron/ellipsis ink alignment + repeated round-trips, across 3 games x 2 widths x 2 themes |
| 24 | unrun-verify | 01.5 | open | The 70vh/70dvh mechanism entry 24 names was replaced by a fixed `padding-block: 5rem` mechanism (G-01.5-6, plan 01.5-09) and closed via an automated live CDP probe only (`01.5-VERIFICATION.md`: gapTop=gapBottom=80.00px at 768/1280px) — not a human-performed check. `01.5-UAT.md` test 18's human walkthrough covered the retuned page but its `result: issue` addressed different complaints (footer grouping/color, mobile balance, CTA style), not this specific top/bottom-proportion item; no passed human record names 768px specifically |
| 25 | deviation | quick-260910-efe | waived | Accepted per `260910-efe-SUMMARY.md`: a deliberate Rule 1 auto-fix rewrote the `.pk-pill-tag` contrast test to measure the actually-rendered ink per theme after sketch 055 Option A's dark-scoped `--color-neutral` override made the old hardcoded `--color-primary` comparison structurally false; the 4.5:1 WCAG floor was explicitly kept unchanged. Test still exists and passes: `test/pukllay_club_web/live/catalog_show_test.exs:4692`, re-run this session, 1 test, 0 failures |

## Before/After Ledger Counts

| | open | fixed | waived | total |
|---|------|-------|--------|-------|
| **Before** | 21 | 5 | 0 | 26 |
| **After** | 9 | 16 | 1 | 26 |

Prior 5 fixed entries (20, 21, 22, 23, 26) were untouched by this run.

## Still Open

- **1** (mix quality, quick-260818-gdb) — Sobelow (`mix sobelow --config`) still reports low-confidence `Traversal.FileModule` findings in `lib/pukllay_club/catalog/seed/csv_import.ex` and `lib/pukllay_club/catalog/seed/report.ex`. Closes when either the findings are reviewed and added to `.sobelow-conf`'s `ignore` list with a documented rationale, or the code is refactored to use a non-dynamic path argument.
- **3, 4, 5** (mobile drawer, 01.1-09) — No UAT round in this repo has ever exercised the mobile drawer (open/trap-focus/close via Escape/backdrop/link-nav; row/toggle/footer layout; About sticky CTA bar + footer). Closes with a dedicated human pass at 390px/1440px across all three drawer routes, or an automated Playwright/Wallaby-style interaction test if one gets added later.
- **7** (photo rail interaction, 01.1-02) — Only photo content was human-checked (01.4-UAT test 3); dots scroll-sync, click-to-jump, auto-advance timing, and pause-on-interaction were never confirmed. Closes with a real-browser check of those four interaction claims.
- **13** (active-filters chip weight, 01.2) — Chip-family shape/radius/weight unification is confirmed (test 16) but the specific "clearly secondary vs. the Resultados heading" visual-weight judgment was never made. Closes with a human eyeballing the catalog index in both themes and confirming that specific relationship.
- **15** (BggClient.fetch_batch/2 empty-list crash, 01.3-02) — Still unguarded at `lib/pukllay_club/catalog/seed/bgg_client.ex:33`. Closes with a code fix adding an empty-list clause (or an explicit `ArgumentError`-safe guard), which is out of scope for this bookkeeping-only task.
- **18** (tappable creator pills, 01.3) — 4 of 5 named sub-items are covered by 01.3-UAT test 1; "tappable creator pills" (Diseñadores/Ilustradores as links) was never independently confirmed. Closes with a targeted human tap-check on a real device.
- **24** (Cierre band 768px proportion, 01.5) — The specific mechanism was replaced and re-verified only by an automated CDP probe, not a human. Closes with a human visual check at 768px specifically (the entry's own named width), confirming the retuned `padding-block: 5rem` composition reads proportionate there too.

## Entry 1 Command Log

Run from the repository root, `MIX_ENV=test`:

| Command | Exit code | Result |
|---|---|---|
| `mix format --check-formatted` | 0 | pass — `config/runtime.exs` now formatted |
| `mix credo --strict` | 0 | pass — 887 mods/funs, no issues (the `core_components.ex` Software Design suggestion is gone) |
| `mix sobelow --config` | 0 | scan completes, but still lists `Traversal.FileModule` (Low Confidence) at `lib/pukllay_club/catalog/seed/csv_import.ex:41,27` and `lib/pukllay_club/catalog/seed/report.ex:143,142` |

No code under `lib/`, `assets/`, `test/`, `config/`, or `priv/` was changed by this task — confirmed via `git status --porcelain -- lib assets test config priv` returning empty after every task.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end close of ONE entry (id 14) through the CLI** - `a3124f9` (docs)
2. **Task 2: Classify and resolve the remaining 20 open entries** - `0277a2f` (docs)
3. **Task 3: Write the SUMMARY decision table** - this file (committed by the orchestrator per this task's constraints)

## Files Created/Modified

- `.planning/WINDOWS.md` — reconciled ledger: 10 entries closed fixed, 1 waived, 9 confirmed still open, all via `windows fixed`/`windows waive`, never hand-edited
- `.planning/quick/260912-mxt-reconcile-the-21-open-entries-in-the-windows-ledger-planning/260912-mxt-SUMMARY.md` — this file

## Decisions Made

- Closed entry 14 first as a tracer to confirm CLI verb argument shapes before mutating the other 20 entries (per the plan's own Task 1 design).
- Treated entries 10 and 12 as "moot" fixed closures (the compared elements no longer coexist after the 01.2 redesign) rather than open, following the precedent set by the pre-existing entry 23 ("moot" closure already in the ledger).
- Applied the plan's conservative default everywhere evidence was partial or the exact named sub-item wasn't independently confirmed (entries 1, 3, 4, 5, 7, 13, 15, 18, 24) — left open rather than stretched to a "fixed"/"waived" close.

## Deviations from Plan

None — plan executed exactly as written. All decisions followed the plan's decision rules (A/B/C) in order; entry-specific instructions for entries 1, 15, and 25 were followed exactly.

## Issues Encountered

None.

## Next Phase Readiness

- `/gsd-ship` is now blocked by 9 open ledger entries instead of 21 — each with a concrete, named unblock action in "Still Open" above.
- Entry 15's code fix (empty-list guard in `BggClient.fetch_batch/2`) and entries 3/4/5/7/13/18/24's human visual/interaction checks are the natural next quick-tasks before a future ship attempt, if `workflow.windows_enforce` is active.

## Self-Check: PASSED

- FOUND: `.planning/WINDOWS.md`
- FOUND: commit `a3124f9` (Task 1)
- FOUND: commit `0277a2f` (Task 2)
- FOUND: `.planning/milestones/v1.0-phases/01.3-game-detail-layout-content-accuracy/01.3-UAT.md`
- FOUND: `.planning/milestones/v1.0-phases/01.2-catalog-detail-navigation-polish/01.2-UAT.md`
- FOUND: `.planning/milestones/v1.0-phases/01.4-ui-polish-pass-for-about-page-sketches/01.4-UAT.md`
- FOUND: `.planning/milestones/v1.0-phases/01.5-about-page-cta-rhythm-header-morph-refinement-implement-sket/01.5-UAT.md`
- FOUND: `.planning/milestones/v1.0-quick/260910-efe-implementar-en-assets-css-app-css-el-the/260910-efe-SUMMARY.md`
- FOUND: `priv/static/images/about-juego.jpg`, `about-explicacion.jpg`, `about-ludoteca.jpg`, `about-comunidad.jpg`, `about-festejo.jpg`
- FOUND: `test/pukllay_club_web/header_capacity_test.exs` (7 tests, 0 failures, re-run this session)
- FOUND: `test/pukllay_club_web/live/catalog_show_test.exs:717` and `:4692` (both re-run this session, 0 failures)

---
*Phase: quick-260912-mxt*
*Completed: 2026-09-12*
