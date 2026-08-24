# Carousel Mechanics — Native Feel

**Status: mixed.** Unlike the other groups in this skill, the shelf-row carousel
(`lib/pukllay_club_web/components/carousel_row.ex` + `.pk-rail`/`.pk-rail-wrap` in
`assets/css/app.css`) had already been reworked by a separate debug session (G-01-3/G-01-4,
2026-08-18–24) *before* sketches 022–026 were drawn. Sketches 001/006's own README claims about
"current shipped behavior" are stale relative to that rework. Verify against the real files below
before assuming either a sketch's or an older reference file's framing is current — this file
supersedes `layout-navigation.md`'s carousel-arrow claim.

## Already correct in production — do not "fix" these

- **Free-momentum scroll, no snap.** `.pk-rail` has `overflow-x: auto; scroll-behavior: smooth;`
  and **no** `scroll-snap-type`. This already matches sketch 023's winner (B — Free Momentum,
  Netflix's own approach). Sketch 023's README frames `overscroll-behavior-x: contain` as "fixing"
  001's flagged open question — it doesn't need fixing, it's already there, with its own documented
  rationale (a horizontal overscroll must not chain to the page or trigger the browser's back
  gesture).
- **`touch-action: manipulation` on `.pk-rail`.** Neither 001 nor 023 considered this specific
  value — 001's README speculated about a `pan-y`/`pan-x` split instead. Production chose
  `manipulation` deliberately: it opens a tap immediately (no double-tap-zoom delay before the
  mobile preview sheet appears) while keeping both scroll axes available, trading a minor
  diagonal-swipe ambiguity for not breaking vertical page scroll that starts on a card.
- **No position/pagination indicator.** Matches sketch 024's winner (A — none, edge-fade only).
- **Flat, no-shimmer skeleton for full-page/initial load.** `CarouselRow.skeleton_row/1` already
  renders `.pk-skel` (flat, no animation) — matches sketch 009's winner. This is a *different*
  moment from 025's shimmer (below) — don't conflate the two.

## Approved change, not yet implemented — arrow placement + touch gating

**Current shipped behavior:** prev/next are `btn btn-circle size-11` — solid daisyUI buttons
sitting in `.pk-row-header`, next to the row title (`data-controls`, toggled `hidden` by
`.CarouselScroll`'s `sync()` based on `scrollWidth > clientWidth`). They render on **every**
pointer type — touch included — whenever the row overflows. There is no edge-overlay arrow and no
hover/pointer-type gating anywhere in the current implementation.

**Approved target (sketch 022, winner C):** relocate to Netflix-style edge-overlay icon buttons —
`position: absolute` inside `.pk-rail-wrap`, transparent background, drop-shadowed icon (no boxed
chrome) — gated by `@media (hover: hover) and (pointer: fine)` so they're removed from the
rendered layout entirely on touch, not just hidden by opacity (no dead 44px tap target sitting
over the swipe area). This is a deliberate, explicit decision to change current behavior, made
after comparing both options directly — not an oversight to "restore." It composes with the
already-correct edge-fade (`.pk-rail-wrap::before/::after`) as the sole scroll affordance on touch.
Implementing this means:
1. Moving the two buttons from `.pk-row-header`'s `data-controls` div into `.pk-rail-wrap`,
   positioned at the rail's left/right edges (see `sources/022-carousel-arrow-behavior/index.html`
   for the exact CSS).
2. Replacing the `hidden`-class-toggle-on-overflow visibility logic with the CSS media-query gate —
   the overflow check can stay (still hide when there's nothing to scroll), it now combines with
   the pointer-fine gate rather than replacing it.
3. Swapping `btn btn-circle` styling for the bare drop-shadowed icon treatment.

**Arrow-click scroll curve:** production's `.CarouselScroll` hook uses plain
`rail.scrollBy({..., behavior: "smooth"})` — the browser's one fixed easing curve. Sketch 023-B's
custom `requestAnimationFrame` scroller (motion-system's validated soft ease-out, 200ms — see
`motion-system.md`) is a nice-to-have upgrade for consistency with touch-driven momentum, not a
correctness requirement. Reasonable to defer if the plain `scrollBy` already feels acceptable.

## Genuinely new — not built at all yet

**Shimmer scoped to filter-triggered row repopulation (sketch 025, winner B).** There is currently
no distinct "this shelf is repopulating after a filter change" moment in the LiveView — a filter
change just re-renders via normal assign diffing, with no skeleton/transition state at all. This is
new surface area, not a change to existing behavior: it needs a way for the LiveView to briefly
render `skeleton_row/1`'s markup (or a dedicated shimmer variant of it — do not reuse the flat
`.pk-skel` styling verbatim, this context calls for the shimmer treatment `sources/
025-carousel-loading-repopulation/index.html` demonstrates) between the old and new card sets,
scoped narrowly to the row(s) actually changing. This is **separate** from — and does not change —
009's flat-skeleton decision for full-page/initial load, which stays as-is.

## What to Avoid

- Treating 001/006's sketch READMEs as the current source of truth for arrow behavior — they
  predate the G-01-3/G-01-4 production rework
- Reusing `.pk-skel`'s flat (no-shimmer) treatment for the repopulation moment — that's a
  deliberately different, narrower context than full-page load (025 retested and confirmed shimmer
  specifically here, after 009 rejected it for the bigger, full-page moment)
- Hiding the arrow via opacity/`display:none` alone on touch without the `@media (hover: hover) and
  (pointer: fine)` gate — that still leaves a dead tap target sitting over the swipe area
- Adding `scroll-snap-type` to `.pk-rail` — deliberately not present; matches Netflix's own rows

## Origin
Synthesized from sketches: 022, 023, 024, 025, 026
Source files available in: `sources/022-carousel-arrow-behavior/`, `sources/023-carousel-scroll-physics/`,
`sources/024-row-position-indicator/`, `sources/025-carousel-loading-repopulation/`,
`sources/026-composed-native-carousel/`
Real implementation: `lib/pukllay_club_web/components/carousel_row.ex`, `.pk-rail`/`.pk-rail-wrap`/
`.pk-poster-card` rules in `assets/css/app.css`
