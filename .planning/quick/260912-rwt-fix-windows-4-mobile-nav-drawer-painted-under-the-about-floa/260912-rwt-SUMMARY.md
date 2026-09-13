---
phase: quick-260912-rwt
plan: 01
subsystem: ui
tags: [css, z-index, stacking-context, liveview, colocated-hook, mobile-nav, drawer]

requires:
  - phase: quick-260912 (debug session about-logo-over-nav-drawer)
    provides: root-cause diagnosis of the isologo-over-drawer defect (WINDOWS #4) and the
      user-chosen structural fix direction
provides:
  - "`nav_drawer/1` (mobile nav drawer) rendered exactly once, as a page-level sibling of
    `#app-header` in both the sticky and non-sticky branches of `Layouts.app/1` — never a
    descendant of the header"
  - "`.pk-drawer-backdrop`/`.pk-drawer` re-tiered from 60/61 (confined to the header's z-50
    stacking context) to 550/551 (root-context overlay band), permanently above
    `.pk-about-morph-mark` (60), `.pk-header-sticky` (50) and the flash toast (z-50), and inside
    the existing 500 (`.pk-portal`) - 700 (`.pk-lightbox`) modal band with no collisions"
  - "`.CatalogNav`'s drawer block now looks the drawer/backdrop up by id
    (`document.getElementById`) outside `this.el`, matching the existing `#app-subnav`
    cross-root pattern; the hamburger stays on `this.el`"
  - "New regression test/pukllay_club_web/components/nav_drawer_stacking_test.exs — markup
    ancestry + CSS-source cross-component z-order guard, the only gate in this codebase that
    checks stacking order across components"
  - "Resolved debug session .planning/debug/resolved/about-logo-over-nav-drawer.md"
affects: [ui-design-system, ux-responsive, WINDOWS #4]

actuals:
  tokens: 6899
  tasks: 3
  commits: 2
  plan_head_before: c6f3b893f0b1147dee2ab4b799734b903c978d99

tech-stack:
  added: []
  patterns:
    - "Modal/overlay components (drawer, sheet, portal, lightbox) render as page-level
      siblings of #app-header, never as descendants of it — #app-header.pk-header-sticky's
      z-index: 50 forms a stacking context that silently caps any descendant's effective root
      z at 50, regardless of its own declared z-index"
    - "Cross-component z-order is guarded by parsing every competitor's z-index live from
      source (CSS + core_components.ex) rather than hardcoding 'known good' numbers twice —
      the same idiom this repo's other CSS-source contract tests use for single-selector
      checks, extended here to compare across components"

key-files:
  created:
    - test/pukllay_club_web/components/nav_drawer_stacking_test.exs
  modified:
    - lib/pukllay_club_web/components/layouts.ex
    - assets/css/app.css
    - .planning/debug/resolved/about-logo-over-nav-drawer.md (moved from .planning/debug/, git mv)

key-decisions:
  - "Followed the debug session's user-chosen Preferred (structural) direction verbatim: move
    the drawer out of the header rather than the CSS-only body-class-toggle alternative, which
    the diagnosis measured as introducing a logo blink-on-open / pop-on-close edge"
  - "Z-index values (Claude's discretion within the user's specified 500-700 band): backdrop
    550, panel 551 — strictly above .pk-portal (500) and below .pk-sheet-backdrop/.pk-sheet
    (600/601) and .pk-lightbox (700), which are mutually exclusive with an open drawer"
  - "Task 2's comment rewrites (layouts.ex's .CatalogNav drawer-block comment, app.css's
    .pk-drawer comment) landed inside Task 1's commit since they are the same hunks as the
    markup/CSS move — no separate Task 2 commit exists; nothing was left uncommitted"

patterns-established:
  - "A live browser check using element.click() understates focus-management behavior — it
    skips the browser's native focus-on-click step, so document.activeElement capture (this
    app's drawerReturnFocus) never reflects what a real user tap produces. A genuine CDP
    Input.dispatchMouseEvent is required to honestly test focus-return logic."

requirements-completed: []

coverage:
  - id: D1
    description: "On /quienes-somos at 390px, with the header docked and the drawer open, the
      drawer panel paints above `#pk-about-morph-mark` (both light and dark themes) — the
      drawer's 'Menú' title and the isologo's own centre both hit-test to a descendant of
      `#pk-nav-drawer`"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/nav_drawer_stacking_test.exs — cross-component z-order tests"
        status: pass
      - kind: manual_procedural
        ref: "live CDP probe (headless Chrome, 390x844): elementFromPoint at the 'Menú' title AND the mark's centre both resolve inside #pk-nav-drawer, light + dark"
        status: pass
    human_judgment: false
  - id: D2
    description: "The drawer and its backdrop render exactly once, as page-level siblings of
      #app-header, never descendants of it, in both the sticky and non-sticky branches of
      Layouts.app/1"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/nav_drawer_stacking_test.exs#drawer markup ancestry (WINDOWS #4)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Drawer interaction (open via hamburger, close via close button/backdrop
      tap/Escape, focus returns to the hamburger, body scroll lock released) is unchanged on
      /, /quienes-somos and a /juegos/:id detail page"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs 'app/1 mobile nav drawer (01.1-09)' describe block"
        status: pass
      - kind: manual_procedural
        ref: "live CDP probe with real synthetic mouse events (Input.dispatchMouseEvent, not element.click()) on /, /quienes-somos, /juegos/1: open/close via escape and via backdrop, focus-return-to-hamburger, scroll-lock release — all pass"
        status: pass
    human_judgment: false
  - id: D4
    description: "With the drawer CLOSED, the About docked header logo is unchanged
      (.pk-about-morph-mark stays z-index 60 and still sits over the header brand slot); no new
      closed-drawer artifact appears at the viewport edge"
    verification:
      - kind: unit
        ref: "grep gate: .pk-about-morph-mark { z-index: 60; } unchanged"
        status: pass
      - kind: manual_procedural
        ref: "live CDP probe: closing the drawer restores elementFromPoint at the mark's centre to .pk-about-morph-mark; no new right-edge shadow artifact observed (parity with /, since the drawer's own display/transform hiding is unchanged by moving it out of the header)"
        status: pass
    human_judgment: false
  - id: D5
    description: "mix quality passes and the about-logo-over-nav-drawer debug session is
      resolved and moved to .planning/debug/resolved/ via git mv, with WINDOWS.md untouched"
    verification:
      - kind: other
        ref: "mix quality (hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted with Styler, credo --strict, sobelow, test --warnings-as-errors) exits 0: 1045 tests, 0 failures"
        status: pass
      - kind: other
        ref: "git show --stat 192c6be shows the rename; git diff --quiet HEAD -- .planning/WINDOWS.md exits 0"
        status: pass
    human_judgment: false

duration: ~70min
completed: 2026-09-12
status: complete
---

# Quick 260912-rwt: WINDOWS #4 mobile nav drawer painted under the About floating isologo — Summary

**Moved the mobile nav drawer out of `#app-header` to a page-level sibling and re-tiered it to z 550/551 (root-context overlay band), permanently fixing the isologo-over-drawer stacking defect and closing a latent identical trap against the flash toast — pinned by a new cross-component CSS-source/markup regression test.**

## Performance

- **Duration:** ~70 min
- **Tasks:** 3
- **Files modified:** 4 (lib/pukllay_club_web/components/layouts.ex, assets/css/app.css, test/pukllay_club_web/components/nav_drawer_stacking_test.exs, .planning/debug/resolved/about-logo-over-nav-drawer.md)

## Accomplishments
- `nav_drawer/1` moved out of both `#app-header` branches (sticky and non-sticky) to a single page-level render site in `Layouts.app/1`, matching `#connection-status`'s existing placement pattern — the drawer is now a genuine root-context modal overlay, never confined to the sticky header's own z-50 stacking context.
- `.pk-drawer-backdrop`/`.pk-drawer` re-tiered 60/61 → 550/551, inside the existing 500 (`.pk-portal`) – 700 (`.pk-lightbox`) overlay band, permanently above `.pk-about-morph-mark` (60, unchanged, still load-bearing for the docked About header logo), `.pk-header-sticky` (50) and the flash toast's z-50 — with no toggle, so no logo blink-on-open or pop-on-close.
- `.CatalogNav`'s drawer block now reaches the drawer/backdrop via `document.getElementById` outside `this.el` (the same cross-root pattern the hook already uses for `#app-subnav`), with the backdrop given `id="pk-nav-drawer-backdrop"` and the close button scoped via `this.drawer.querySelector`.
- New `test/pukllay_club_web/components/nav_drawer_stacking_test.exs`: markup-ancestry tests (drawer/backdrop render exactly once, as direct children of `body`, never descendants of `#app-header`, in both `sticky: false`/`sticky: true`) plus CSS-source cross-component z-order tests, parsing every competitor's z-index live from `assets/css/app.css` and `core_components.ex` rather than hardcoding numbers.
- Live browser confirmation (headless Chrome via CDP, 390×844): on `/quienes-somos`, docked + drawer open, `elementFromPoint` at both the drawer's "Menú" title and the isologo's centre resolve inside `#pk-nav-drawer`, in light and dark themes; closing restores the docked mark. Open/close/Escape/backdrop-tap and focus-return-to-hamburger all verified on `/`, `/quienes-somos` and `/juegos/1`.
- Debug session `about-logo-over-nav-drawer` resolved (root_cause and suggested_fix_direction left byte-identical) and moved to `.planning/debug/resolved/` via `git mv`.

## Task Commits

Each task was committed atomically (TDD cycle for Task 1's tracer):

1. **Task 1: Tracer — drawer re-tiered to a page-level overlay (markup + CSS + hook lookup), pinned by a failing-first stacking test**
   - `e76599a` — feat(260912-rwt): tracer — drawer re-tiered to a page-level overlay, pinned by a failing-first stacking test (RED→GREEN cycle: new test observed failing against the pre-fix markup/CSS, then passing after the move)
2. **Task 2: Rewrite the stale stacking comments and verify the drawer end-to-end at 390px** — no separate commit. The comment rewrites (layouts.ex's `.CatalogNav` drawer-block comment, app.css's `.pk-drawer` comment) are the exact same hunks as Task 1's markup/CSS move and were written in the same edit, so they landed in `e76599a`. The live browser check (this task's other deliverable) produces no source diff — its result is recorded here and in the resolved debug session.
3. **Task 3: Resolve and move the debug session, then pass mix quality**
   - `192c6be` — docs(260912-rwt): resolve and move the about-logo-over-nav-drawer debug session; mix quality green

**Plan metadata:** not committed (SUMMARY.md/STATE.md/ROADMAP.md explicitly out of scope per this quick item's constraints).

_Note: no separate "Plan metadata" docs commit — STATE.md/ROADMAP.md were not touched, per constraints._

## Files Created/Modified
- `lib/pukllay_club_web/components/layouts.ex` — moved `<.nav_drawer>` to a single page-level call site; added `id="pk-nav-drawer-backdrop"` to the backdrop; rewrote the `.CatalogNav` drawer-block lookups (`document.getElementById` outside `this.el`) and its explanatory comment.
- `assets/css/app.css` — `.pk-drawer-backdrop` 60→550, `.pk-drawer` 61→551; rewrote the stale confined-context comment above `.pk-drawer` to describe the new root-context placement and the 500-700 band.
- `test/pukllay_club_web/components/nav_drawer_stacking_test.exs` — new file: markup ancestry (2 tests) + backdrop id/role/aria/inert (1 test) + cross-component z-order parsed from source (2 tests).
- `.planning/debug/resolved/about-logo-over-nav-drawer.md` — moved from `.planning/debug/`; status `diagnosed` → `resolved`, Resolution filled with fix/verification/files_changed.

## Decisions Made
- Followed the debug session's user-chosen Preferred (structural, no-toggle) direction verbatim rather than the CSS-only body-class alternative, which the diagnosis measured as introducing a logo blink-on-open / pop-on-close edge.
- Z-index values within the user's specified 500-700 band left to this session's discretion: backdrop 550, panel 551 — strictly above `.pk-portal` (500), below `.pk-sheet-backdrop`/`.pk-sheet` (600/601) and `.pk-lightbox` (700).
- Combined Task 1 and Task 2's comment rewrites into a single commit, since they are literally the same source hunks (moving the markup and rewriting the rationale comment above it happen together) — no work was left uncommitted.

## Deviations from Plan

None - plan executed exactly as written. One probe-methodology correction was made during Task 2's browser check (not an app defect, see Issues Encountered).

## Issues Encountered
- The first pass of the live browser check used plain `element.click()` to simulate taps, which does not perform the browser's native focus-on-click step — this made the focus-return-to-hamburger assertions fail even though the app's `drawerReturnFocus` logic is byte-identical to before this plan. Switched to real `Input.dispatchMouseEvent` synthetic clicks (confirmed via a side-by-side debug probe) and all focus-return checks then passed. Also found that clicking the exact geometric centre of the full-viewport `.pk-drawer-backdrop` rect at 390px actually lands on the drawer PANEL (which visually covers most of that rect, being right-anchored and z 551 > the backdrop's 550) — corrected the probe to click the exposed left-edge strip instead, which is what a real user would tap to dismiss the drawer. Neither issue is an app defect; both are documented in the resolved debug session's verification field.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- WINDOWS #4 is closed: the mobile nav drawer permanently paints above every non-modal root-context layer, including the About page's floating isologo and the (currently latent, no `put_flash` call sites yet) flash toast.
- The same z-50 header-stacking-context trap the debug session flagged for the desktop "Explorar categorías" mega-menu (`.pk-cat-backdrop`/`.pk-cat-panel`) was NOT touched by this item — it remains confined to the header and would lose to any future root-level layer with z ≥ 50 (today only the flash toast). Worth a follow-up pass if a future root-level layer is ever added above z 50.

---
*Phase: quick-260912-rwt*
*Completed: 2026-09-12*
