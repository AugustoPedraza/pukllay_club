---
phase: quick-260902-glf
plan: 01
subsystem: ui
tags: [css, layout, footer, sticky-footer, flexbox, cdp-measurement, regression-guard]

requires:
  - phase: quick-260901-ty6
    provides: "--pk-footer-offset / --pk-footer-pad-block tokens driving .pk-footer's margin-top, which this task's A/B measurement checks for margin-collapse interaction"
  - phase: quick-260902-fdm
    provides: "the ≤480px footer content reduction (BGG-attribution-only), the fixture this task's short-page CDP measurement renders against"
provides:
  - "Removal of the site-wide sticky-footer mechanism (.pk-app-shell's min-height floor + main-child flex-grow) that pushed the footer to the viewport bottom on pages shorter than one screen"
  - "Live CDP measurement discipline extended to a flex-column A/B determination (toggling display via injected override CSS, not a page reload)"
  - "A dated superseding-note precedent in app.css covering a full mechanism withdrawal, including retiring two threat-register findings by name"
affects: [footer, catalog-empty-state, detail-page-cta-bar]

actuals:
  tokens: 6500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Live CDP A/B measurement via an injected override <style> tag (`.pk-app-shell { display: block !important; }`) inside a single page load, rather than two separate navigations — used to isolate one CSS property's effect while holding everything else (LiveView connection state, DOM content) constant"

key-files:
  created: []
  modified:
    - assets/css/app.css
    - lib/pukllay_club_web/components/layouts/root.html.heex
    - test/pukllay_club_web/components/layouts_test.exs
    - test/pukllay_club_web/live/catalog_show_test.exs

key-decisions:
  - "Reverted the Phase 01.2 sticky-footer mechanism per explicit developer choice (offered as 'revert' vs. 'investigate a possible missing-content bug first'); the re-accepted tradeoff is plain background below the footer on short pages, not a defect discovered mid-task."
  - "The flex column (display: flex; flex-direction: column) was NOT removed by assumption alongside the height floor/growth factor — its fate was held open through Tasks 1-2 and settled only by a live A/B measurement in Task 3, which found it fully vestigial (main carries no bottom margin, so there was nothing for flex's margin-collapse suppression to protect)."
  - "Once the flex column proved vestigial, the shell class was retired completely and consistently: deleted from app.css, dropped from root.html.heex's <body>, and its three presence tests plus the CSS-facts describe deleted from layouts_test.exs — no half-applied branch."

requirements-completed: [SHELL-01]

coverage:
  - id: D1
    description: "The .pk-app-shell min-height pair and .pk-app-shell main flex-grow rule are deleted outright from app.css (not commented out)"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/stylesheet_integrity_test.exs (full suite pass, catches a comment that closes early)"
        status: pass
      - kind: other
        ref: "git show 8a38396 -- assets/css/app.css: both declarations and the flex-grow rule appear only as diff deletions, never as commented-out lines"
        status: pass
    human_judgment: false
  - id: D2
    description: "On a page shorter than the viewport (no-results catalog search state, 390x1400), the footer now sits immediately after content with no gap above it; remaining space falls below the footer as plain background (the accepted tradeoff)"
    requirement: SHELL-01
    verification:
      - kind: automated_ui
        ref: "live CDP measurement (headless Chrome, scratchpad script, not committed): gapMainToFooter=16px (== --pk-footer-offset at <=480px, i.e. the deliberate margin, not an artifact), gapFooterBottomToDocEnd=785px (space below the footer, the reintroduced tradeoff)"
        status: pass
    human_judgment: true
    rationale: "Plan's own Task 3 verify lists this as a <human-check> (live-measured/visually-confirmed geometry), matching the measurement discipline 260901-ty6/260902-fdm/260902-g21 each established for this surface. CDP numerically substantiates it and a clipped screenshot visually confirms it, but the plan's designated oracle is a human read of the real render, not yet performed as of this SUMMARY."
  - id: D3
    description: "On a page longer than the viewport (game detail page, 390x844), every measured geometry number is unchanged, including the CTA-bar reserved bottom clearance (confirmed live, not trusted from the retired comment's claim)"
    requirement: SHELL-01
    verification:
      - kind: automated_ui
        ref: "live CDP measurement: scrollHeight=1658px, footer gap=16px, bodyPaddingBottom (CTA-bar clearance)=148px, gapFooterBottomToDocEnd=147.71875px -- matching the original comment's historical before-measurement (147.7px) almost exactly, confirming the CTA-bar interaction was already a no-op as claimed"
        status: pass
    human_judgment: true
    rationale: "Same live-measurement/visual-confirmation oracle as D2 -- plan's Task 3 <human-check>, not yet eyeballed by a human on a real device as of this SUMMARY."
  - id: D4
    description: "The flex column's fate (keep vs. remove) is settled by an A/B measurement and applied consistently across app.css, root.html.heex, and layouts_test.exs -- no half-applied branch"
    requirement: SHELL-01
    verification:
      - kind: automated_ui
        ref: "live CDP A/B: .pk-app-shell { display: block !important; } injected mid-page-load at 390px on both the short and long page fixtures -- scrollHeight, footer top/bottom, main-to-footer gap, and footer-to-doc-end gap were byte-identical with the flex column present vs. removed"
        status: pass
      - kind: unit
        ref: "mix test (762/762 passing after removal); grep -rn 'pk-app-shell' across lib/assets/test finds only historical prose in comments, no live selector/class/assertion"
        status: pass
    human_judgment: false
  - id: D5
    description: "The superseded sticky-footer rationale is retired with a dated (2026-09-02, quick task 260902-glf) note carrying what changed, why, the tradeoff, and both retired threat findings (T-01.2-24-01, T-01.2-24-02) -- not silently deleted"
    requirement: SHELL-01
    verification:
      - kind: other
        ref: "assets/css/app.css lines ~372-457 (superseding note) -- opens 'SUPERSEDED 2026-09-02 (quick task 260902-glf)', names WHAT/WHY/tradeoff/both threat IDs and their retirement reasoning, and records the flex-column A/B measurement that later also retired the class entirely"
        status: pass
    human_judgment: false
  - id: D6
    description: "All three in-file cross-references naming the removed declarations as their premise (.pk-title-echo audit, .pk-lightbox audit, .pk-lightbox-img's dual-height citation) are corrected; the dual-declaration viewport-unit idiom stays citable"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs .pk-lightbox-img height assertions (still pass, citation repointed at app.css's superseded-mechanism note site above .pk-gutter)"
        status: pass
      - kind: other
        ref: "assets/css/app.css: both containing-block audits (.pk-title-echo ~3573-3597, .pk-lightbox ~3793-3814) carry a second RE-CHECKED AGAIN paragraph dated 2026-09-02 describing the class's full removal; conclusions unchanged"
        status: pass
    human_judgment: false
  - id: D7
    description: "All four named test files audited: layouts_test.exs and catalog_show_test.exs updated, header_chip_band_separation_test.exs and footer_rhythm_test.exs confirmed to have no tie"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "mix test test/pukllay_club_web/components/layouts_test.exs test/pukllay_club_web/live/catalog_show_test.exs test/pukllay_club_web/header_chip_band_separation_test.exs test/pukllay_club_web/footer_rhythm_test.exs (all pass)"
        status: pass
      - kind: other
        ref: "grep -n 'pk-app-shell\\|min-height\\|sticky' against header_chip_band_separation_test.exs and footer_rhythm_test.exs: matches are the sticky HEADER mechanism and the theme button's own min-height, both unrelated -- confirmed, not assumed"
        status: pass
    human_judgment: false
  - id: D8
    description: "mix test, mix format --check-formatted, and mix compile --warnings-as-errors all pass"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "mix test (762/762), mix format --check-formatted (clean), mix compile --warnings-as-errors (clean)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-09-02
status: complete
---

# Quick Task 260902-glf: Remove the Site-Wide Sticky-Footer Layout Summary

**Deleted `.pk-app-shell`'s min-height/flex-grow sticky-footer mechanism outright (not commented out), then a live CDP A/B measurement found the accompanying flex column vestigial too — so the entire `.pk-app-shell` class, its three presence tests, and its CSS-facts test contract were retired, leaving `<body>` with no class at all.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-09-02T12:00:00-03:00 (approx.)
- **Completed:** 2026-09-02T12:15:02-03:00
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Deleted `.pk-app-shell`'s `min-height: 100vh; min-height: 100dvh;` pair and the `.pk-app-shell main { flex-grow: 1; }` rule (with its explanatory comment) outright from `app.css` — the mechanism that pushed the footer to the viewport bottom on pages shorter than one screen, which had itself become the cause of an empty band **above** the footer on those same pages.
- Replaced the long doc comment with a dated (2026-09-02, 260902-glf) superseding note covering what changed, why (a real mobile screenshot of the above-footer gap), the knowingly reintroduced tradeoff (plain background below the footer on short pages), the retirement of both threat-register findings (T-01.2-24-01 containing-block safety, T-01.2-24-02 reserved bottom clearance), and kept the dual-declaration viewport-unit idiom citable for the two other places in the repo that name it.
- Corrected the three in-file cross-references whose premise named the removed declarations (`.pk-title-echo`'s containing-block audit, `.pk-lightbox`'s containing-block audit, `.pk-lightbox-img`'s dual-height citation) — all three conclusions survive unchanged, only the premise text was updated.
- Ran a live CDP A/B measurement (headless Chrome, scratchpad script, not committed) toggling `.pk-app-shell { display: block !important; }` mid-page-load at 390px against both a short page (no-results catalog search) and a long page (game detail): **every** geometry number was byte-identical with the flex column present vs. removed, because `<main>` carries only padding (never a bottom margin) so there was nothing for `.pk-footer`'s top margin to collapse against either way.
- Since the flex column proved fully vestigial, retired `.pk-app-shell` completely and consistently: deleted the class from `app.css`, dropped it from `root.html.heex`'s `<body>` (now carries no class), and deleted the three "carries pk-app-shell" tests plus the `pk-app-shell CSS facts` describe from `layouts_test.exs`, replaced by a dated removal note.
- Closed the four-file test audit: `layouts_test.exs` and `catalog_show_test.exs` updated; `header_chip_band_separation_test.exs` and `footer_rhythm_test.exs` confirmed (not assumed) to have no tie — their matches are the sticky header and the theme button's own `min-height`, respectively.
- Live-verified: short page shows the footer immediately after content with the accepted tradeoff space below it; long page's geometry is unchanged, including the CTA-bar reserved clearance (148px, matching the original comment's historical 147.7px measurement almost exactly); confirmed via clipped screenshots at 390px (both pages) and 1280px desktop (byte-identical rendering).

## Task Commits

Each task was committed atomically:

1. **Task 1: Invert the layouts_test.exs CSS-facts contract into a regression guard (RED)** - `6770f69` (test)
2. **Task 2: Delete the mechanism, write the superseding note, correct the three cross-references (GREEN)** - `8a38396` (feat)
3. **Task 3: Decide the flex column by measurement, live-verify short/long/CTA-bar, close the test audit** - `0e0690c` (feat)

**Plan metadata:** not yet committed (orchestrator handles the docs commit)

_Note: Task 1's RED proof observed exactly three assertion-text failures (min-height absence, main-descendant-rule absence, main-growth-factor absence) against the unmodified stylesheet — no compile errors, no silently-empty-regex false positives._

## Files Created/Modified

- `assets/css/app.css` - Deleted `.pk-app-shell`'s min-height pair, the `.pk-app-shell main` flex-grow rule, and (after Task 3's A/B measurement) the entire `.pk-app-shell` rule including `display: flex; flex-direction: column`. Replaced the original mechanism comment with a dated superseding note; corrected three cross-references in `.pk-title-echo`'s and `.pk-lightbox`'s containing-block audits and `.pk-lightbox-img`'s dual-height citation.
- `lib/pukllay_club_web/components/layouts/root.html.heex` - `<body class="pk-app-shell">` → `<body>` (the class's only markup consumer).
- `test/pukllay_club_web/components/layouts_test.exs` - Inverted the `pk-app-shell CSS facts` describe into an absence guard (Task 1), then deleted that describe plus the three `carries pk-app-shell` tests entirely (Task 3) once the class was fully retired, replaced by a dated removal note.
- `test/pukllay_club_web/live/catalog_show_test.exs` - Repointed the `.pk-lightbox-img` dual-height assertion's comment/failure-message citation at app.css's superseded-mechanism note site (its own assertion contract is unaffected).

## Decisions Made

- Reverted the sticky-footer mechanism per the developer's explicit choice (offered as "revert" vs. "investigate a possible missing-content bug first" — this plan does not relitigate that decision).
- Held the flex column's fate open through Tasks 1-2 (kept `display: flex; flex-direction: column` and its two pending-marked test assertions) rather than removing it on the unverified assumption it only ever served the sticky-footer mechanism — settled it in Task 3 by live A/B measurement instead of argument.
- A/B result: the flex column was vestigial (byte-identical geometry with it present vs. removed on both a short and a long page), because `<main>` carries only padding, never a bottom margin — margin-collapse suppression had nothing to protect. Retired the class completely and consistently (CSS, markup, tests) rather than leaving a half-applied branch.
- Used an injected `<style>` override (`.pk-app-shell { display: block !important; }`) mid-page-load for the A/B toggle, rather than two separate page loads with different CSS — isolates the one property change while holding LiveView connection state and DOM content constant.

## Deviations from Plan

None — plan executed exactly as written, including the three-way branch structure (RED → GREEN → measure-then-decide) and every requirement in `must_haves`.

## Issues Encountered

None. The dev server was already running (`mix phx.server`); headless Chrome (`google-chrome --headless=new --remote-debugging-port=9333`) drove the CDP measurements against it directly, following the exact precedent (`getBoundingClientRect()` over CDP, `Page.captureScreenshot` with `captureBeyondViewport: true` for clipped confirmation screenshots) set by 260901-ty6/260902-fdm/260902-g21.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The site-wide sticky-footer mechanism and its accompanying `.pk-app-shell` class are fully removed from the codebase — `grep -rn "pk-app-shell"` across `lib/`, `assets/`, `test/` returns only historical prose inside CSS comments, no live selector, class, or assertion.
- D2/D3 (the plan's own live-viewport visual reads) are substantiated by CDP measurement and clipped screenshots in this session but have not yet been eyeballed by a human on a real device — flagged as `human_judgment: true` in this SUMMARY's coverage block per the plan's own verification design, matching the precedent 260901-ty6/260902-fdm/260902-g21 each set.
- SHELL-01's footer-shape work is now four quick tasks deep (260901-ty6 chrome retune, 260902-fdm content reduction, 260902-g21 alignment flip, 260902-glf this sticky-footer reversion) — no further footer/shell layout work is queued.

---
*Phase: quick-260902-glf*
*Completed: 2026-09-02*

## Self-Check: PASSED

- FOUND: `assets/css/app.css`
- FOUND: `lib/pukllay_club_web/components/layouts/root.html.heex`
- FOUND: `test/pukllay_club_web/components/layouts_test.exs`
- FOUND: `test/pukllay_club_web/live/catalog_show_test.exs`
- FOUND: commit `6770f69` (RED)
- FOUND: commit `8a38396` (GREEN)
- FOUND: commit `0e0690c` (Task 3)
