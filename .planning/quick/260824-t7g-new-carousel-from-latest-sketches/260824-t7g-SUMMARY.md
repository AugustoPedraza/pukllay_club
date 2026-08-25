---
phase: quick-260824-t7g
plan: 01
subsystem: ui
tags: [phoenix-liveview, tailwind, css, colocated-hook, heroicons, carousel, accessibility]

# Dependency graph
requires:
  - phase: 01.1-site-shell-content-pages-implement-the-not-yet-built-sketch
    provides: ".pk-rail/.pk-rail-wrap edge-fade carousel shell, .CarouselScroll colocated hook (G-01-3/G-01-4 rework)"
provides:
  - "Netflix-style edge-overlay prev/next chevrons on .pk-rail-wrap, gated to @media (hover: hover) and (pointer: fine), combined with a data-overflows check"
  - "Per-frame requestAnimationFrame arrow-scroll eased on the project's own soft ease-out curve (200ms, 0.85x rail width), replacing the browser's fixed behavior: smooth"
affects: [carousel-mechanics, catalog-live-index, catalog-live-show]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 2774
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Device-condition + content-condition combine via one CSS block: @media (hover: hover) and (pointer: fine) supplies the device gate, a data-overflows attribute (not a hidden-class toggle) supplies the content gate — avoids Tailwind v4's unlayered-CSS-beats-layered-utility trap that would have silently defeated a hidden class toggle."
    - "Per-frame eased scroll: cancelAnimationFrame stored frame id before starting a new loop and again on destroyed(), matchMedia(prefers-reduced-motion) queried at click time (not cached at mount) so an OS setting change mid-session is respected."

key-files:
  created: []
  modified:
    - assets/css/app.css
    - lib/pukllay_club_web/components/carousel_row.ex
    - test/pukllay_club_web/live/catalog_live_test.exs

key-decisions:
  - "Kept the exact aria-label strings and data-scroll values verbatim across the relocation so the existing accessible-name tests continued to pass unmodified."
  - "scroll-behavior flipped smooth -> auto on .pk-rail is load-bearing (Task 2), not cosmetic — documented inline so a future reader doesn't 'restore' smooth and reintroduce the stutter."

patterns-established:
  - "Edge-overlay chevron treatment (.pk-rail-btn): bare glyph, z-index 5 above the edge-fade's z-index 4, drop-shadow via color-mix(in srgb, var(--pk-shadow-color) N%, transparent) on the icon span."

requirements-completed: [CATALOG-01]

coverage:
  - id: D1
    description: "Prev/next chevrons relocated from .pk-row-header (btn-circle daisyUI buttons) to bare, drop-shadowed edge-overlay buttons inside .pk-rail-wrap, on both the landing carousel rows and CatalogLive.Show's Juegos similares shelf"
    requirement: CATALOG-01
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#sketch 022-C: each rendered shelf's two scroll buttons live inside .pk-rail-wrap, none inside .pk-row-header, and no daisyUI circular-button class remains"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#sketch 022-C: CatalogLive.Show's Juegos similares shelf gets the identical treatment with no show.ex edit"
        status: pass
      - kind: manual_procedural
        ref: "Coordinator via Chrome browser automation — hover reveal (opacity 0->1), real-Tab :focus-visible reveal, both themes, /juegos/177 similares shelf structural check"
        status: pass
    human_judgment: false
  - id: D2
    description: "Chevrons removed from the rendered layout entirely (display: none, not opacity) on touch/non-pointer-fine devices, combined with the existing overflow check"
    requirement: CATALOG-01
    verification:
      - kind: unit
        ref: "CSS gate @media (hover: hover) and (pointer: fine) reviewed against source; ExUnit assertions cover the DOM structure the gate applies to"
        status: pass
    human_judgment: true
    rationale: "The coordinator's browser-automation tool has no touch/pointer-emulation control (only viewport resize, which does not change the hover/pointer media features), so display:none-outside-pointer-fine was verified by source review + the passing structural ExUnit tests, not by an observed touch-context render. Needs a real touch device or DevTools device-emulation pass with an actual human to close fully."
  - id: D3
    description: "Chevron click scrolls the rail with a project-owned requestAnimationFrame ease-out curve (200ms, 0.85x rail width) instead of the browser's fixed behavior: smooth, with cancellation on rapid re-click and destroyed()"
    requirement: CATALOG-01
    verification:
      - kind: automated_ui
        ref: "Coordinator via Chrome browser automation — forced prefers-reduced-motion, reset scrollLeft=0, clicked next: scrollLeft jumped instantly and exactly to Math.round(clientWidth * 0.85) = 1034px on a 1216px rail, one synchronous assignment, no loop"
        status: pass
      - kind: automated_ui
        ref: "Coordinator via Chrome browser automation — non-reduced-motion click from scrollLeft=0 landed on the correct ~4-card-shifted resting position matching the same 0.85x delta"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs (mix test --warnings-as-errors, 445 tests, 0 failures) + grep gate confirming scroll-behavior: auto (1) and no remaining scroll-behavior: smooth (0)"
        status: pass
    human_judgment: true
    rationale: "The coordinator's browser-automation tab never reports document.visibilityState: visible, so Chrome pauses requestAnimationFrame entirely for it — the per-frame scroller never advances a single frame in that tool's session, meaning the live 200ms deceleration curve, visual smoothness, and rapid-double-click race behavior could not be observed frame-by-frame, only code-reviewed (cancelAnimationFrame confirmed present in both onClick and destroyed()). Target-position math and the reduced-motion path are proven exactly; the subjective 'does it feel smooth, no stutter' quality needs a human eyeballing it in a normal foregrounded tab."

# Metrics
duration: 24min
completed: 2026-08-24
status: complete
---

# Phase quick-260824-t7g: Native carousel arrow layer from sketches 022-026 Summary

**Relocated carousel prev/next controls from header-embedded daisyUI circular buttons to Netflix-style edge-overlay chevrons gated to pointer-fine devices, and replaced the browser's fixed smooth-scroll arrow click with the project's own 200ms soft ease-out curve.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-08-24T21:09:02-03:00
- **Completed:** 2026-08-24T21:32:46-03:00
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- `.pk-rail-btn`: bare, drop-shadowed edge-overlay chevron glyphs (no boxed button chrome), positioned at `.pk-rail-wrap`'s left/right edges, `z-index: 5` above the edge-fade
- Device gate (`@media (hover: hover) and (pointer: fine)`) combined with a `data-overflows` content gate on the same element — touch devices get `display: none` in the rendered layout, not merely `opacity: 0`, and a non-overflowing rail shows no chevron on any pointer type
- Both `CatalogLive.Index`'s 8 D-09 carousel rows and `CatalogLive.Show`'s `Juegos similares` shelf inherit the change with zero call-site edits, since the change is entirely inside `CarouselRow.carousel_row/1` + `.pk-rail*` CSS
- `.CarouselScroll`'s `onClick` rewritten to a `requestAnimationFrame` loop using `t => 1 - Math.pow(1 - t, 5)` (the JS twin of `--ease-out-soft`), 200ms, 0.85× rail client width — replacing `rail.scrollBy({behavior: "smooth"})`
- In-flight animation frame cancelled before a new click starts a new loop, and again in `destroyed()`
- `prefers-reduced-motion: reduce` visitors get an instant `scrollLeft` jump with no animation loop
- `.pk-rail`'s `scroll-behavior` flipped `smooth` -> `auto` (load-bearing: leaving it `smooth` would make every per-frame `scrollLeft` write kick off its own competing browser animation)

## Task Commits

Each task was committed atomically:

1. **Task 1: Edge-overlay chevrons, gated to pointer-fine devices (sketch 022-C)** - `4c95c71` (feat)
2. **Task 2: Per-frame eased arrow scroll on the project's own curve (sketch 023-B)** - `d106248` (feat)

_Note: no separate `docs:` metadata commit was made per this dispatch's constraints — the orchestrator commits SUMMARY.md/STATE.md in a later step._

## Files Created/Modified
- `assets/css/app.css` - New `.pk-rail-btn` block (base state, `data-scroll` side anchors, icon-span drop-shadow, pointer-fine + `data-overflows` gate); `.pk-rail`'s `scroll-behavior` flipped `smooth` -> `auto` with an inline rationale comment
- `lib/pukllay_club_web/components/carousel_row.ex` - Removed `.pk-row-header`'s `data-controls` div; moved both scroll buttons into `.pk-rail-wrap` (now marked `data-rail-wrap`) as siblings of `[data-rail]`; swapped `hero-chevron-{left,right}` (outline) for `hero-chevron-{left,right}-solid` at `size-8`; `.CarouselScroll`'s `sync()` now writes `data-overflows` instead of toggling `hidden`; `onClick` rewritten to the per-frame eased scroller with a reduced-motion branch and frame-id cancellation; `destroyed()` cancels any in-flight frame; moduledoc updated to describe the new arrow-layer behavior
- `test/pukllay_club_web/live/catalog_live_test.exs` - G-01-3 describe block: added structural assertions (both chevrons inside `.pk-rail-wrap`, none inside `.pk-row-header`, no `btn-circle` class, `data-rail-wrap` marker present) for the landing carousel rows and a new case rendering `/juegos/:id`'s `Juegos similares` shelf proving the same treatment reached the second call site with no `show.ex` edit

## Decisions Made
- Kept the Spanish `aria-label`s and `data-scroll` values byte-identical through the relocation so the shipped accessible-name tests kept passing unmodified — only the containing markup and CSS classes changed.
- Did not re-tune `.pk-row-header`'s now-single-cluster `flex items-end justify-between gap-4` utilities after removing the second cluster — left them in place per the plan's explicit instruction not to re-tune header layout in an arrow-layer-scoped plan.
- Documented the `scroll-behavior: auto` flip's rationale as prose (not the literal old declaration text) so the verify gate's grep for `scroll-behavior: smooth;` stays a true negative and a future reader understands *why* before "restoring" it.

## Deviations from Plan

None - plan executed exactly as written. Both tasks matched their `<action>` sections precisely; no Rule 1-4 auto-fixes were needed.

## Issues Encountered

**Task 1 tracer feedback gate and Task 2's embedded `<human-check>` both required live browser verification that this executor session had no browser-automation tool for.** The coordinating agent performed both checks via Chrome browser automation instead and reported results back mid-execution (see Human Verification below). This is expected behavior per the plan's `type="tracer"` protocol (auto mode was off: `workflow._auto_chain_active` and `workflow.auto_advance` both `false`, plan frontmatter `autonomous: false`) — the executor stopped, the checks were performed by the supervising agent, and execution resumed on confirmation each time.

## Human Verification

### Task 1 (sketch 022-C edge-overlay chevrons) — CONFIRMED, no issues found
- Desktop hover on `/`: both chevrons fade in correctly at the rail's left/right edges (computed styles: opacity 0→1, `z-index: 5`, `position: absolute`, `left: 0`/`right: 0`); legible over light and dark poster art in both themes.
- Keyboard: a real Tab keypress reaches the prev button and reveals it via `:focus-visible` (opacity 1, focus ring shown). Note for future automated checks: a scripted `.focus()` call does **not** reliably trigger `:focus-visible` the same way a real Tab does in Chrome — a false negative trap to avoid.
- `/juegos/177`'s `Juegos similares` shelf: `data-rail-wrap` present, `data-overflows="true"`, 2 `.pk-rail-btn` children — zero `show.ex` changes needed, as designed.
- Touch/mobile `display: none` absence: **not independently re-verified by browser automation** (no touch/pointer-emulation control available, only viewport resize, which doesn't change `hover`/`pointer` media features). Verified by source review of the `@media (hover: hover) and (pointer: fine)` gate plus the passing ExUnit structural assertions — treat as code-review-verified, not visually-touch-verified.
- Pre-existing, out-of-scope observation: the existing card-hover preview popover (`.pk-portal`, `z-index: 500`, `position: fixed`) can visually cover the edge chevron when hovering directly over the first/last card in a shelf (its box extends past the card into the gutter). Not a regression from this plan — flagged for awareness only.

### Task 2 (sketch 023-B eased arrow scroll) — PARTIALLY CONFIRMED
- **Reduced-motion path — confirmed exactly.** Forcing `prefers-reduced-motion: reduce`, resetting `scrollLeft=0`, and clicking "next" jumped `scrollLeft` instantly and exactly to `Math.round(clientWidth * 0.85)` = 1034px on a 1216px-wide rail, in one synchronous assignment, no loop.
- **Eased-scroll target math — confirmed correct.** A normal (non-reduced-motion) click from `scrollLeft=0` landed the row on the correct card set, a ~4-card shift matching the same 0.85×`clientWidth` delta.
- **Live easing curve / stutter / rapid-click cancellation — NOT independently observed.** The coordinator's browser-automation tab never reports `document.visibilityState: "visible"`, so Chrome pauses `requestAnimationFrame` entirely for that tab — the per-frame scroller never advances a single frame in that session; `scrollLeft` either stays at the start value or jumps straight to the resolved end value once enough wall-clock time elapses that `t=1`. The actual 200ms deceleration feel and a rapid-double-click race were therefore not visually observed. `cancelAnimationFrame(this.frame)` was confirmed present in both `onClick` (before starting a new loop) and `destroyed()` via code review, matching the required shape — this is a code-review confirmation, not an observed-behavior one. **This sub-check needs a human eyeballing it in a normal foregrounded browser tab to close fully.**

## User Setup Required

None - no external service configuration required.

## Pending Todos

**Sketch 025-B (shimmer scoped to filter-triggered row repopulation) was deliberately NOT planned or built in this task** — it is blocked on a product decision that does not exist, not dropped for difficulty. `CatalogLive.Index` wraps `#carousel-rows` in `:if={not filters_active?(assigns)}`, so a filter change removes the entire carousel section and shows one authoritative result grid instead of repopulating a shelf in place (a shipped, UAT-verified decision, 01-12) — there is no moment in the app for the shimmer to occupy today.

**Follow-up decision needed, recorded here per the plan's `<deferred>` instruction:** decide between (a) turning `CatalogLive.Show`'s `Juegos similares` shelf into an `assign_async` shelf, creating a real repopulation moment when navigating detail-to-detail for 025-B's shimmer to attach to, or (b) revisiting whether filtering should re-scope the carousel rows rather than hide them entirely. Neither option was implemented in this task.

**Live-smoothness sub-check for Task 2's eased scroll (see Human Verification above)** — a human should confirm in a normal foregrounded browser tab that the 200ms deceleration feels smooth with no stutter, and that three rapid chevron clicks don't produce visible jitter between competing animations. Automated verification (target-position math, reduced-motion path, `cancelAnimationFrame` presence) is complete and passing; only the subjective "does it feel right" observation remains open.

## Next Phase Readiness

The carousel arrow layer now matches sketch 022-C/023-B's approved decisions. `carousel-mechanics.md`'s "Approved change, not yet implemented" section for arrow placement + touch gating is now implemented; its "nice-to-have" note on the eased scroll curve is also implemented. `carousel-mechanics.md` should be updated in a future pass to move both items from "not yet implemented" to "already correct in production," alongside the two open items above (025-B decision, live-smoothness human check).

---
*Phase: quick-260824-t7g*
*Completed: 2026-08-24*

## Self-Check: PASSED

All 3 modified source files exist on disk and both task commits (`4c95c71`, `d106248`) are present in `git log --oneline --all`.
