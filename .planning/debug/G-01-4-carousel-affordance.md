---
status: diagnosed
trigger: "G-01-4-carousel-affordance: Carousel/shelf sections on the PukllayClub catalog homepage do not read as distinct carousels, and horizontal scrolling happens at the window/page level instead of within each individual carousel row."
created: 2026-08-18T23:00:00Z
updated: 2026-08-18T23:20:00Z
audit_acknowledged:
  milestone: v1.0
  at: 2026-09-11
  status: diagnosed
---

## Current Focus

hypothesis: CONFIRMED — the `.carousel` rail div in `CarouselRow.carousel_row/1` (data-rail) is
missing the `w-full` width-constraint class that daisyUI's `.carousel` component requires. Without
it, the `inline-flex` rail sizes to its full intrinsic content width (all ~20 cards) instead of
being clipped to its container, so nothing ever overflows *inside* the rail — the rail itself
overflows every unconstrained ancestor up to the window, producing page-level horizontal scroll
instead of per-row containment, and simultaneously destroying the "distinct carousel" affordance
because no row is ever visually clipped/cut-off.
test: read `.carousel`'s compiled CSS in deps/daisyui, cross-checked against daisyUI's own official
carousel examples (always `class="carousel w-full"`), then read carousel_row.ex's actual render
output for the `data-rail` div's class list.
expecting: `.carousel`'s own CSS defines no width/max-width — confirmed. Official daisyUI usage
always pairs it with `w-full` — confirmed via web search. Project's data-rail div omits `w-full`
and no ancestor (section/#carousel-rows/mx-auto max-w-7xl container/Layouts.app) supplies any
overflow-x clipping or width constraint to compensate — confirmed via full read of index.ex and
layouts.ex and grep across lib/pukllay_club_web/components for overflow rules.
next_action: return ROOT CAUSE FOUND to caller (find_root_cause_only mode — no fix applied here)

## Symptoms

expected: Load `/` unfiltered and scroll top to bottom. Each of the 8 carousel shelves should be
distinguishable from the next via its heading + one-line subtitle; the 'Destacados del club' row
should be visibly ranked above the others by color; the main grid at the bottom should read as its
own titled section, not a trailing count line. Carousel rows should each scroll horizontally within
their own bounded row (with round prev/next controls per a related UAT test), not the page/window
itself.
actual: "This looks more like a simple vertical list without clear affordance that there are
multiple carousels. Also the horizontal scrolling is happening at window level, not individual
carousel."
errors: None reported
reproduction: Load `/` unfiltered on a narrow/mobile viewport (<640px) and scroll top to bottom, per
UAT Test 4 in .planning/phases/01-catalog-v1/01-UAT.md
started: Reported in UAT re-verification round AFTER commits 7ba31b4/61e4ba1/72a8451/8e4a1d5
(01-08, gap closure for G-01-3/G-01-4) had already added variant/subtitle/hero-color/prev-next-
controls — i.e. this is a residual/regression finding even after the prior G-01-4 fix attempt, not
a fresh unaddressed gap.

## Eliminated

(none — first hypothesis, formed from direct CSS/code inspection, was confirmed on first pass)

## Evidence

- timestamp: 2026-08-18T23:05:00Z
  checked: git log + git diff on lib/pukllay_club_web/components/carousel_row.ex and
  lib/pukllay_club_web/live/catalog_live/index.ex; git status
  found: Both files are already committed at HEAD (commit 8e4a1d5, part of the 01-08 gap-closure
  series for G-01-3/G-01-4) with variant/subtitle/hero-color and a `.CarouselScroll` colocated hook
  providing prev/next controls. No uncommitted local changes to either file. This is the code the
  UAT reporter actually tested — the 01-08 fix was live at test time, yet the complaint persisted.
  implication: The reported issue is not "the G-01-4 fix wasn't applied" — it's that the applied fix
  is undermined by something else. Ruled out "stale deploy" as an explanation; need a code-level
  cause that survives the 01-08 changes.

- timestamp: 2026-08-18T23:08:00Z
  checked: lib/pukllay_club_web/components/carousel_row.ex full read (carousel_row/1, lines 38-104)
  found: The scrollable rail is `<div data-rail class="carousel carousel-center gap-4 rounded-box">`
  (line 97) — no `w-full`, `max-w-full`, or any explicit width class on this element. Its children
  are `.carousel-item` wrappers around `GameCard.game_card` fixed-width cards (`w-40 shrink-0
  sm:w-48`), up to `@carousel_limit` (20) games per row.
  implication: Candidate root cause — daisyUI's `.carousel` is `display: inline-flex`, which is
  shrink-to-fit by default; without an explicit width constraint it will size to its full content
  width rather than clipping to its container.

- timestamp: 2026-08-18T23:11:00Z
  checked: deps/daisyui/packages/bundle/daisyui.js — the compiled `.carousel`/`.carousel-item` rule
  set (grepped `\.carousel`)
  found: `.carousel { display: inline-flex; overflow-x: scroll; scroll-snap-type: x mandatory;
  scrollbar-width: none; ... }`. No `width`, `max-width`, or `flex-wrap` property is set anywhere in
  daisyUI's own `.carousel`/`.carousel-horizontal`/`.carousel-item` rules.
  implication: Confirms daisyUI deliberately leaves width/containment to the consumer — `.carousel`
  alone cannot self-clip; it needs a companion width class from the caller to have anything to
  scroll *within*.

- timestamp: 2026-08-18T23:14:00Z
  checked: Web search — daisyUI official carousel component docs/examples
  found: Every official daisyUI carousel example pairs the container class as `class="carousel
  w-full"` (e.g. `<div class="carousel w-full"><div class="carousel-item">...`). `w-full` is the
  documented, expected companion class, not optional boilerplate.
  implication: The project's `data-rail` div deviates from documented daisyUI usage by omitting
  `w-full`. This is very likely the actual defect, not a theory — it matches a known, named daisyUI
  usage requirement.

- timestamp: 2026-08-18T23:16:00Z
  checked: lib/pukllay_club_web/live/catalog_live/index.ex full render/1 (lines 270-383) and
  lib/pukllay_club_web/components/layouts.ex + layouts/ dir for any overflow-x/width compensation
  found: Ancestor chain of `data-rail` is `<section id={@id} class="space-y-3">` ->
  `<div id="carousel-rows" class="space-y-8">` -> `<div class="mx-auto max-w-7xl space-y-6 px-4
  py-6 sm:px-6 lg:px-8">` -> `Layouts.app`. None of these apply `overflow-x-hidden`, `overflow-x-
  auto`, or any width clamp beyond the outer container's own `max-w-7xl` (which bounds the
  container itself, not an unconstrained inline-flex descendant). grep for "overflow" across
  lib/pukllay_club_web/components/ shows only `overflow-hidden` on GameCard's square image
  `<figure>` (unrelated) and the carousel component's own `overflow-x: scroll` (line 19 moduledoc
  reference / compiled CSS) — nothing that would clip/contain an unconstrained inline-flex rail.
  implication: No ancestor compensates for the missing width class. The unconstrained `data-rail`
  div is free to overflow every ancestor's box up to the browser's initial containing block (the
  viewport), which is exactly what produces window/page-level horizontal scroll instead of scroll
  contained within the row.

- timestamp: 2026-08-18T23:18:00Z
  checked: The `.CarouselScroll` colocated hook's `sync()` function (carousel_row.ex lines 55-59):
  `const overflows = this.rail.scrollWidth > this.rail.clientWidth; this.controls.classList.toggle
  ("hidden", !overflows)`
  found: `scrollWidth` and `clientWidth` are measured on `this.rail` (the same unconstrained
  `data-rail` div). When a box has no explicit width and nothing clips it, its `scrollWidth` equals
  its `clientWidth` (both equal the same unclipped intrinsic content width) — there is nothing
  "extra" to scroll to *inside* the box, because the box grew to contain everything.
  implication: This is a second, compounding symptom of the same single root cause: the G-01-3
  prev/next controls (added specifically to signal "this row scrolls") never actually appear,
  because the overflow check they depend on can never be true while the rail is unconstrained. This
  explains why the human UAT round rated Test 5 (controls) as "skip, don't understand it" — the
  controls were likely invisible on every row during that test, consistent with `overflows` always
  evaluating false.

## Resolution

root_cause: "The scrollable rail element in CarouselRow.carousel_row/1
(lib/pukllay_club_web/components/carousel_row.ex line 97, `<div data-rail class=\"carousel
carousel-center gap-4 rounded-box\">`) is missing daisyUI's required `w-full` companion class.
daisyUI's `.carousel` utility is `display: inline-flex; overflow-x: scroll` with no width/max-width
of its own (confirmed in deps/daisyui's compiled CSS) — every official daisyUI carousel example
pairs it with `w-full` for exactly this reason. Without a width constraint, the rail is shrink-to-
fit and grows to its full content width (up to 20 fixed-width game cards per row), so it never has
anything to clip/scroll internally. Because no ancestor element (section > #carousel-rows > the
mx-auto max-w-7xl page container > Layouts.app) applies any compensating overflow-x containment,
the oversized rail overflows every ancestor's box up to the page's initial containing block,
producing window/page-level horizontal scroll instead of per-row scroll. This single CSS omission
produces both halves of the reported symptom simultaneously: (1) horizontal scrolling happens at
the window level rather than inside each carousel, because the rail itself never clips; and (2) the
8 shelves don't read as distinct, independently-scrollable carousels — since nothing is visually
cut off at a row boundary, all 8 rows' cards render in one continuous unclipped horizontal expanse
that only moves together when the whole page scrolls. It also silently defeats the G-01-3 prev/next
controls fix already shipped in 01-08: the `.CarouselScroll` hook's visibility check
(`this.rail.scrollWidth > this.rail.clientWidth`) can never be true while the rail is unconstrained,
because scrollWidth and clientWidth both equal the same unclipped content width — so the round
prev/next buttons never appear on any row, reinforcing the 'just a vertical list' perception."
fix: "(not applied — find_root_cause_only mode) Add `w-full` (or an equivalent explicit width/
max-width constraint) to the `data-rail` div's class list in carousel_row.ex line 97, so
`class=\"carousel carousel-center gap-4 rounded-box w-full\"`. This should be verified to also
restore the `.CarouselScroll` hook's overflow-controls visibility check once the rail is properly
clipped."
verification: (not run — diagnosis only)
files_changed: []
