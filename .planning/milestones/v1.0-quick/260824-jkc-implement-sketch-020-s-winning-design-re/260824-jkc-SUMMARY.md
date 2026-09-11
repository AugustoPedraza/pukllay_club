---
phase: quick-260824-jkc
plan: 01
subsystem: ui
tags: [phoenix, liveview, daisyui, tailwind, header, navigation, catalog, scroll-spy]

# Dependency graph
requires:
  - phase: 01.1-08
    provides: the .CatalogNav colocated hook (search-morph, drawer, --pk-header-h publisher) this plan extends
provides:
  - Desktop "Explorar categorías" mega-menu (Layouts.category_menu/1) opened from a bare trigger in the header
  - Refined bare-outline, edge-faded, soft-tint-active mobile chip index row
  - One shared scroll-spy (widened [data-chip-target] selector) driving both surfaces' active state
  - Header-height-derived shelf landing offset (replacing a hardcoded constant)
affects: [catalog-header, catalog-navigation, site-shell]

actuals:
  tokens: 7351
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "General-sibling CSS override (.a ~ .b { margin-left: 0 }) to neutralise a second element's own margin-left:auto only when a specific preceding sibling is actually present in the DOM — lets one shared component (.pk-search-morph) keep its own auto-margin default on pages without the new trigger, while ceding it on pages that have one"
    - "Live-measured breakpoint selection: when an existing shared breakpoint's arithmetic doesn't hold after a new element joins the row, bisect the real overflow threshold via a headless-Chrome CDP session instead of re-guessing a round number"

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/components/layouts.ex
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - assets/css/app.css
    - test/pukllay_club_web/live/catalog_live_test.exs

key-decisions:
  - "daisyUI's dropdown component checked first and rejected: no first-class way to pair a dimmed backdrop, a document-level Escape handler, and the scroll-spy's is-active class on individual rows — hand-rolled instead, following the mobile drawer's existing inert/aria-expanded/idempotent-close pattern as this page's own precedent"
  - "One derived shelf list (CatalogLive.Index.index_rows/1) feeds BOTH the chip row and the mega-menu panel, under the same not-filters_active? guard — never two independently-built lists"
  - "data-chip-target reused verbatim on .pk-cat-item (not a new attribute) so the desktop panel joins the existing scroll-spy for free instead of needing a second, parallel mechanism"
  - "Rule 1 auto-fix: .pk-cat-trigger's margin-left:auto competed with .pk-search-morph's own margin-left:auto — flexbox splits free space evenly between multiple auto margins instead of grouping them, measured as a 303px gap at 1280px instead of 'adjacent'. Fixed with a general-sibling override (.pk-cat-trigger ~ .pk-search-morph { margin-left: 0 }) scoped so pages without the trigger (Detalle) are unaffected"
  - "Rule 1 auto-fix: the trigger's label reveal reused the plan's specified 48rem breakpoint, but live measurement showed the label's ~155px broke the existing 481-768px arithmetic — closed row overflowed 10px at 768px and the opened search pill was squeezed to a useless 2px. Bisected the real threshold (persisted to 775px, cleared at 780px) and moved the reveal to a dedicated 50rem breakpoint with measured headroom, documented as a deviation from the plan's literal breakpoint choice"

patterns-established:
  - "Scroll-spy widened from a single-class selector to a shared data attribute selector ([data-chip-target]) so multiple surfaces (mobile chips, desktop panel rows) can join one IntersectionObserver without a second parallel one"

requirements-completed: [SHELL-01]

coverage:
  - id: D1
    description: "Desktop 'Explorar categorías' trigger opens a right-anchored (explicit width, no opposing left/inset), unboxed 2-column panel listing every populated shelf as plain typographic rows, joined to the same scroll-spy as the chip row"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#desktop category mega-menu (SHELL-01, sketch 020, quick-260824-jkc) (3 tests: item-per-shelf/target-parity, zero-games shelf omitted, filtered render hides both)"
        status: pass
      - kind: automated_ui
        ref: "headless Chrome CDP session at 1280px, light + dark theme — measured panel/trigger/nav-inner bounding rects and computed background-color"
        status: pass
    human_judgment: false
  - id: D2
    description: "Mobile chip row renders bare-outline at rest, a soft accent tint (not solid fill) when active, an edge fade at both ends, no scroll buttons, no promoted/hero chip"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs (4 pre-existing chip-row tests, unmodified + 1 new .pk-chip-nav-wrap test)"
        status: pass
      - kind: automated_ui
        ref: "headless Chrome CDP at 390px, light + dark theme — computed background/border/color of a rest-state chip and an active chip"
        status: pass
    human_judgment: false
  - id: D3
    description: "A shelf jump lands its heading below the live header (not underneath it) at both a narrow viewport (taller header, chip row attached) and desktop, via a header-height-derived offset"
    requirement: "SHELL-01"
    verification:
      - kind: automated_ui
        ref: "headless Chrome CDP at 390px — clicked a chip, measured heading top offset (124.9px) vs published header height (109px) post-jump"
        status: pass
    human_judgment: false
  - id: D4
    description: "The header row does not overflow (no document horizontal scrollbar) between 481px and 768px with the search box open or closed"
    requirement: "SHELL-01"
    verification:
      - kind: automated_ui
        ref: "headless Chrome CDP — documentElement.scrollWidth vs clientWidth at 481px and 768px, search open and closed, post-fix (all four states equal, 0 overflow)"
        status: pass
    human_judgment: false

duration: ~40min
completed: 2026-08-24
status: complete
---

# Quick Task 260824-jkc: Sketch 020 Catalog Index Row Summary

**Production now matches sketch 020's Round 2 minimalism + Round 3 alignment fix: a bare-outline, edge-faded, soft-tint-active mobile chip row, and a borderless "Explorar categorías" trigger opening a right-anchored, unboxed mega-menu on desktop — both driven by one widened scroll-spy, both jumping to a header-height-derived landing offset, verified live in a real headless Chrome via CDP at every required viewport and theme.**

## Performance

- **Duration:** ~40 min
- **Tasks:** 3
- **Files modified:** 4
- **Commits:** 3

## Accomplishments

- New `Layouts.category_menu/1`: a bare icon+label trigger (`hero-squares-2x2` + rotating `hero-chevron-down-micro`), a dimmed backdrop, and a right-anchored (`right: var(--pk-gutter)` + explicit `width`, never an opposing `left`/`inset`) 2-column panel of plain typographic rows — no per-item box/border/fill beyond a hairline divider. `.CatalogNav` gained an open/close/Escape/backdrop block modelled line-for-line on the existing drawer block.
- `CatalogLive.Index.index_rows/1` is the one derived shelf list now feeding both the `:subnav` chip row and the new `:nav_menu` panel — never two independently-built lists.
- `.pk-chip` retuned to sketch 020 Round 2: transparent-at-rest border/text (matching `filter_modal.ex`'s existing chip idiom), a soft `--color-accent` tint (not solid fill) when active via the `-content` pairing for dark-theme contrast, no promoted/hero chip, no scroll buttons. New `.pk-chip-nav-wrap` owns the edge fade (mirroring `.pk-rail-wrap`) and the `<=480px` viewport swap.
- `.CatalogNav`'s scroll-spy widened from a `.pk-chip`-only selector to `[data-chip-target]`, so the desktop panel's rows join the one existing `IntersectionObserver` instead of needing a second. `.pk-shelf`'s landing offset now derives from `--pk-header-h` instead of a hardcoded `6rem`.
- **Two real bugs found and fixed via live browser measurement (Task 3), not caught by any ExUnit test:** a flexbox dual-`margin-left:auto` conflict that put 303px of dead space between the trigger and search pill instead of grouping them, and a genuine 10px horizontal overflow (plus the search pill collapsing to an unusable 2px) at 768px once the trigger's text label joined the existing breakpoint arithmetic. Both confirmed fixed with before/after measurements.

## Task Commits

Each task was committed atomically:

1. **Task 1: Desktop "Explorar categorías" mega-menu, wired end to end** - `88483cd` (feat)
2. **Task 2: Mobile chip row refinement, shared scroll-spy, and header-aware landing offset** - `c61e6a6` (feat)
3. **Task 3: Full quality gate and live two-viewport confirmation** - `9b88168` (fix — two Rule 1 auto-fixes found during live verification)

**Plan metadata:** not committed by this executor — orchestrator handles the docs commit separately per this quick task's own instructions.

## Files Created/Modified

- `lib/pukllay_club_web/components/layouts.ex` - `nav_menu` slot on `app/1` (both sticky/non-sticky branches), threaded into `header_inner/1` and rendered immediately before `.pk-search-morph`; new `category_menu/1` function component; `.CatalogNav` hook gained a cat-menu open/close/Escape/backdrop block plus the widened `[data-chip-target]` scroll-spy
- `lib/pukllay_club_web/live/catalog_live/index.ex` - new `index_rows/1` private helper feeding both `:subnav` and `:nav_menu`; chip `<nav>` wrapped in `.pk-chip-nav-wrap`
- `assets/css/app.css` - `.pk-cat-*` (trigger/label/chevron/backdrop/panel/grid/item) inside PK CATALOG SURFACES; `.pk-chip` retuned to bare-outline-at-rest + soft-tint-active; new `.pk-chip-nav-wrap` edge fade; `.pk-shelf` scroll-margin-top derived from `--pk-header-h`; a dedicated `50rem` breakpoint for the trigger label (Rule 1 fix, see Deviations); a general-sibling override neutralising `.pk-search-morph`'s auto margin when a trigger precedes it (Rule 1 fix)
- `test/pukllay_club_web/live/catalog_live_test.exs` - new "desktop category mega-menu" describe block (3 tests); new `.pk-chip-nav-wrap` assertion; 4 pre-existing chip-row tests left byte-identical and still passing

## Decisions Made

See `key-decisions` in frontmatter — summarized: daisyUI's `dropdown` was checked and rejected for lacking a first-class backdrop+Escape+scroll-spy story; one derived shelf list feeds both surfaces; `data-chip-target` is reused verbatim (not a new attribute) so the panel joins the existing scroll-spy for free.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Trigger and search pill competed for the same flex auto-margin instead of grouping**
- **Found during:** Task 3 (live verification at 1280px)
- **Issue:** `.pk-cat-trigger` (per plan) and `.pk-search-morph` (pre-existing) both carried `margin-left: auto` in the same flex row. Flexbox distributes free space **equally across every auto margin on a line**, not "first one wins" — measured a 303px gap between the trigger's right edge (930px) and the panel's right-anchored edge (1233px) instead of the panel visually hanging "adjacent" to the trigger+search group as the plan intended.
- **Fix:** Added `.pk-cat-trigger ~ .pk-search-morph { margin-left: 0; }` — a general-sibling override (specificity 0,2,0, beats the base rule's 0,1,0 by cascade, not source order) that only fires when a `.pk-cat-trigger` actually precedes `.pk-search-morph` in the DOM. Pages with search but no trigger (Detalle) keep `.pk-search-morph`'s own auto margin unchanged.
- **Files modified:** `assets/css/app.css`
- **Verification:** Re-measured post-fix: trigger right edge 1165px, panel right edge 1233px — the 68px gap is exactly the collapsed search pill (44px) + the row's own 1.5rem gap (24px), i.e. genuinely adjacent.
- **Committed in:** `9b88168`

**2. [Rule 1 - Bug] Trigger label's reveal breakpoint (per plan's own 48rem instruction) caused a real overflow the plan's arithmetic didn't anticipate**
- **Found during:** Task 3 (live verification at 768px)
- **Issue:** The plan explicitly asked to reuse the existing `48rem` breakpoint for revealing the trigger's text label, reasoning that "the row width arithmetic is tightest" there and citing pre-existing numbers that didn't include this new ~155px-wide label. Live measurement at 768px (closed state) showed `documentElement.scrollWidth` (763px) exceeding `clientWidth` (753px) by 10px — a real horizontal scrollbar — and with the search box opened, `.pk-search-morph.is-open`'s existing shrink-to-fit mechanism squeezed the pill down to a functionally useless 2px.
- **Fix:** Bisected the actual safe threshold live (overflow persisted through 775px, cleared at 780px) and moved `.pk-cat-trigger-label`'s reveal to its own dedicated `50rem`/800px breakpoint — the next round number above the measured value with real headroom, confirmed 0 overflow in all four states (closed/open × before/after toggling).
- **Files modified:** `assets/css/app.css`
- **Verification:** Re-measured at 768px: `scrollWidth === clientWidth === 753` in every state; open search pill width improved from 2px to 157px.
- **Committed in:** `9b88168`

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs caught only by live measurement, not by ExUnit or the plan's own automated `<verify>` checks)
**Impact on plan:** Both fixes are corrections to the plan's own stated implementation details (a shared auto-margin assumption, and a breakpoint-arithmetic claim), made necessary by hard measurement rather than assumption. No scope creep — both stay inside `assets/css/app.css`, the file the plan already listed for Task 3.

## Issues Encountered

- **No MCP browser-automation tools available in this executor's tool set.** Per the same fallback pattern used by prior quick tasks in this project, verification was done with a from-scratch Node script (~150 lines, zero npm installs) using Node 22's built-in `fetch`/`WebSocket` to drive a headless `google-chrome --remote-debugging-port` instance over the raw Chrome DevTools Protocol (`Page.navigate`, `Runtime.evaluate`, `Emulation.setDeviceMetricsOverride`). The already-running dev server on `localhost:4000` (the user's own, pre-existing) was reused rather than starting a second one; only the headless Chrome instance this task launched was killed afterward.

## Live Two-Viewport Confirmation (Task 3, mandatory — recorded per plan instruction)

All three items below were measured with real computed styles / bounding rects against the running dev server, in both themes where applicable — not eyeballed.

**(a) 1280px — panel anchoring, light + dark:**
| | Light | Dark |
|---|---|---|
| Trigger right edge | 1165px | 1165px |
| Panel right edge | 1233px | 1233px |
| Header content column (`.pk-nav-inner`) right edge minus `--pk-gutter` (32px) | 1233px | 1233px |
| Panel background (computed) | — | `rgb(23, 10, 38)` = `--color-base-100` dark ✓ |

Panel's right edge lines up exactly with the header's shared content column edge in both themes; trigger sits genuinely adjacent to the search pill (68px = 44px collapsed pill + 24px row gap) after the Rule 1 fix above.

**(b) 390px — scroll-spy + jump landing, light + dark:**
- Scrolling to `y=1200` (no interaction) auto-activated `carousel-descubre_el_hobby`'s chip in both themes — scroll-spy works unattended.
- Active-chip tint (light): `background: rgb(237, 225, 247)` (`--color-accent`), `color: rgb(61, 9, 109)` (`--color-primary`, via `--color-accent-content` resolving identically in light).
- Active-chip tint (dark): `background: rgb(61, 42, 86)` (`--color-accent` dark), `color: rgb(228, 211, 245)` (`--color-accent-content` dark) — confirms the `-content` pairing clears contrast in dark where a literal `--color-primary` text color would not have.
- Rest-state chip (light, `:not(.is-active)`): `background: rgba(0,0,0,0)` (transparent), `border-color: rgb(227, 211, 240)` (`--color-base-300`), `color: rgb(107, 91, 123)` (`--color-neutral`) — bare outline confirmed, not the old filled block.
- Jump: clicked the `carousel-equipo_ganador` chip. Post-jump: published header height `109px` (taller mobile header, chip row attached); shelf heading's `top` after the jump = `124.875px` — **below** the header by ~16px (the `+1rem` gap), not underneath it.
- Edge fade `::before` gradient (light): `linear-gradient(90deg, rgb(243, 236, 250), rgba(0,0,0,0))` — `rgb(243, 236, 250)` = `--color-base-200`, the exact same token as `.pk-chip-nav-wrap`'s own background, confirming the fade-to-wrapper-background match required for both themes.

**(c) 481px and 768px — no horizontal scrollbar, search open/closed, post-fix:**
| Width | State | scrollWidth | clientWidth | Overflow |
|---|---|---|---|---|
| 481px | closed | 466 | 466 | 0 |
| 481px | open | 466 | 466 | 0 |
| 768px | closed | 753 | 753 | 0 |
| 768px | open | 753 | 753 | 0 |
| 768px | closed again | 753 | 753 | 0 |

Before the Rule 1 breakpoint fix, 768px closed measured `763 vs 753` (10px overflow) and open measured a `.pk-search-morph` width of 2px; both are 0/153px respectively after the fix.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Sketch 020's approved design (Round 2 minimalism + Round 3 alignment fix) is now live in production on both surfaces; no further catalog-index-row visual work is queued.
- No blockers for Phase 2 (Natural-Language Spanish Search + Auth), which remains the project's next planned phase per STATE.md.

## Self-Check: PASSED

All 4 modified files confirmed present on disk. All 3 task commit hashes (`88483cd`, `c61e6a6`, `9b88168`) confirmed present in `git log --oneline`. `mix quality` re-verified green (425 tests, 0 failures) after the Task 3 fixes.

---
*Phase: quick-260824-jkc*
*Completed: 2026-08-24*
