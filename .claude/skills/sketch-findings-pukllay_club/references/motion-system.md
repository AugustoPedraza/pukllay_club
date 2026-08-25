# Motion System

## Design Decisions

**The shipped duration/easing tokens were chosen deliberately, not incidentally.** Sketches 001/002
picked 120/220/360ms with a standard ease-in-out while building layout and card interactions — never
as a considered system. Sketch 006 tested that baseline (**A: Minimal/Snappy**) against two
alternatives — **B: Expressive/Springy** (180/320/480ms, back-out overshoot, leans into a
welcoming/teach-the-hobby tone) and **C: Cinematic/Soft** (200/420/620ms, slow soft ease-out, closer
to a premium streaming feel) — then synthesized a fourth option after review.

**Winner: D — Subtle/Soft.** "The animation must be subtle and have a soft transition" — faster than
all three tested options (100/180/280ms, the fastest set), paired with C's no-overshoot soft ease-out
curve (not B's overshoot — reads as unpolished on frequent actions like row-scroll), and a *smaller*
hover-lift amplitude on top of the faster timing: restraint isn't only a timing question, the movement
itself needs to be smaller too.

**This is already the live system, not just a validated proposal.** Applied directly to
`themes/default.css` (both the light palette and the merged dark palette) during a 2026-08-20
consistency pass — confirm any new component reads `var(--duration-fast/base/slow)` and
`var(--ease-standard)`/`var(--ease-out-soft)` rather than hardcoding a timing value, so it inherits
this system automatically instead of drifting from it.

**Real drift found and fixed the same day:** the interactive card's hover-lift
(`.card:hover`/`.poster-card:hover`) was independently declared in three places (001, 002, 007) and
none of them had been updated to D's smaller amplitude — all three still used the pre-006
`translateY(-4px)`. Corrected to `-3px` in all three. (006's own demo baseline of "shared -6px
scale(1.03)" was never something the real component shipped — that number only ever existed inside
006's own comparison demo, so the real correction is -4px → -3px, not -6px → -3px. Don't cite -6px
as a prior value when implementing.)

## The Rhythm Standard

Sketch 006 chose the *tokens*. Five debug sessions then established the *selection rules* — which
token to reach for, and what has to be true before any of it runs at all. Those rules were only ever
recorded in rule-level CSS comments and knowledge-base entries, which is why the same classes kept
recurring; this section is the consolidated version. Enforced by
`test/pukllay_club_web/motion_rhythm_test.exs`.

### 1. Pick the duration by what is changing

| Tier | Token | Use for |
|---|---|---|
| fast | `--duration-fast` (100ms) | Paint-only state changes — hover/focus colour, border, background. Nothing moves. |
| base | `--duration-base` (180ms) | Small moves and fades — panels, backdrops, dropdown reveals, ≤~30px translations. |
| slow | `--duration-slow` (280ms) | Large travel — sheets, drawers, the header search pill, anything crossing ~100px. |

### 2. Pick the curve by AMPLITUDE, not by taste

- **`--ease-standard` for anything that TRAVELS.** This is the default; reach for it unless you have
  a measured reason not to.
- **`--ease-out-soft` for ACCENTS ONLY — under roughly 50px of travel.** It is easeOutExpo. Its
  share of the travel spent in the very first 16.7ms frame is **68.6% at fast, 46.7% at base, 32.7%
  at slow**. Holding a 24px first-frame step as the threshold of a visible "pop", that makes it safe
  below about **35px / 51px / 73px** respectively.

A timing function is scale-free in the spec but **not scale-free perceptually**. The same
percentage-per-frame is invisible at 3px and a jump at 515px, and nothing in the name
`--ease-out-soft` tells you its domain of validity. Applied unchanged to a 515px sheet it put 26.3%
of the distance into the first frame and then crawled for ~280ms — which reads as "it jumps and then
stops", not as an animation.

**Counter-intuitive corollary: do NOT try to fix a pop by lengthening the duration.** A longer
duration on a front-loaded curve is *worse*. The same curve at 280ms yields a larger first frame than
at 360ms, because a shorter duration front-loads an already front-loaded curve harder.

### 3. For a FROM-REST interaction, `v0` must be 0

This is stronger than the amplitude rule and it applies to hand-rolled JS animation, where you choose
the easing function directly.

If an animation begins from a standing start on user input — a click, a button, a keypress — then the
**entire ease-out family is disqualified at any exponent and any duration.** Every curve of the form
`1-(1-t)^n` has `v0 = nA/D > 0`, so first-frame travel scales *linearly with amplitude*. A quintic
ease-out on a 1034px carousel scroll opened with 25,840 px/s out of a standing start — 341px in frame
one. The cubic still yields 237.5px; reaching a 24px first frame would need a 3591ms duration.

**The diagnostic question: "what supplies the initial velocity?"** An ease-out is exactly right for a
*touch fling*, which genuinely does start fast because the finger already imparted the momentum —
**the hand is the ease-in**. It is exactly wrong for a click, which has no prior motion. Copying the
fling's curve onto a click handler reproduces the fling's second half without its first, which is
precisely a velocity discontinuity. Use an ease-in-out (`--ease-standard`, or its JS twin
`cubicBezier(0.4, 0, 0.2, 1)`).

### 4. Preconditions — motion that cannot happen at all

The rules above assume the transition *runs*. These four make sure it does. Each corresponds to a
shipped bug where the CSS read as correct, no gate failed, and the animation simply was not there.

- **Never animate to or from `auto`.** `auto` is not an interpolable value, so the transition never
  starts — `transitionrun` does not fire and the element teleports. Measure what `auto` resolves to
  and write that length. The mobile search pill moved 318px in a single painted frame in both
  directions for exactly this reason; `width: auto` became
  `calc(100% - 2 * var(--pk-gutter))`, the same rendered value as a length the browser can
  interpolate.
- **Never change a non-animatable property on the same class toggle.** `position` is not animatable
  at all, so flipping it alongside an animated width is a discrete teleport. If a state needs
  `position: absolute`, apply it in **both** states and let only the interpolable property change.
- **Keep flex shrink permission constant across states.** A `width` transition interpolates the
  *specified* value; flex shrinking is applied on top. If `.is-open` grants `flex-shrink: 1` and
  removing the class revokes it, the used width snaps from the shrunk value up to the full specified
  value the instant the class leaves — a 331%-of-travel first frame and a horizontal scrollbar.
  Put the shrink permission (and an explicit `min-width` floor) on the base rule.
- **Never `transition: all`.** It opts in every animatable property, including geometry the element
  never intended to animate, so a layout change made elsewhere silently acquires a transition nobody
  designed. List the properties the state change actually touches.

### 5. Reduced motion is global — do not re-register surfaces

A single `@media (prefers-reduced-motion: reduce)` block at **end of file** applies
`transition-duration: 1ms !important` (and the animation equivalents) to `*, *::before, *::after`.
Two properties are load-bearing and neither is decoration:

- **`!important`** — a media query contributes **zero specificity**, and this stylesheet has no
  `@layer`, so without it the guard loses a plain *source-order* race to every later `transition:`
  shorthand. A shorthand resets every longhand it owns, so any rule below the guard silently undoes
  it. This is the one deliberate `!important` in the file; stripping it in a tidy-up pass restores
  the bug with no test failure and no symptom for anyone not using the accommodation.
- **`*`** — there is no list to forget to update, so a new animated surface is covered automatically.
  Do **not** add per-surface entries; that is the enumeration failure mode the universal selector
  exists to remove.

Also `1ms`, never `0s`: a zero-duration transition generates no transition at all and never fires
`transitionend`.

## CSS Patterns

```css
:root {
  --duration-fast: 100ms;
  --duration-base: 180ms;
  --duration-slow: 280ms;
  --ease-standard: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-out-soft: cubic-bezier(0.16, 1, 0.3, 1); /* no-overshoot soft ease-out, D's curve */
}

.card:hover, .poster-card:hover {
  transform: translateY(-3px); /* D's validated amplitude — not -4px, not -6px */
  transition: transform var(--duration-base) var(--ease-out-soft); /* 3px: accent territory */
}

/* A box that grows: interpolable length both ends, position constant across
   states, shrink permission on the base rule, properties listed explicitly. */
.pill {
  position: absolute;
  right: var(--pk-gutter);
  width: 44px;
  flex: 0 1 auto;
  min-width: 44px;
  transition: width var(--duration-slow) var(--ease-standard);
}
.pill.is-open {
  width: calc(100% - 2 * var(--pk-gutter)); /* never `auto` */
}
```

The same tokens drive the Elixir-side `JS.show/JS.hide` transitions in `core_components.ex`, via
arbitrary-value utilities (`duration-[var(--duration-slow)] ease-[var(--ease-standard)]`). Their
`time:` argument must stay numerically in sync with the token it names — LiveView uses it to decide
when to apply and remove the classes, and an Elixir integer cannot read a CSS custom property.

Row-scroll (rail arrow clicks) needs a custom `requestAnimationFrame` scroller driven by the same
easing function, not native `scroll-behavior: smooth` — the browser's built-in smooth-scroll has one
fixed curve/duration and can't express a variant's specific overshoot or settle feel. Only relevant if
row-scroll timing is ever revisited; the shipped winner (D) has no overshoot, so this doesn't block
using native smooth-scroll today.

## What to Avoid

- **Don't hardcode timing values in new components** — always reference the `--duration-*`/`--ease-*`
  tokens so a future system-wide tuning pass (like the one 006 did) propagates automatically instead
  of requiring a per-component hunt for hardcoded numbers (exactly what happened with the three
  independently-declared `-4px` hover-lifts).
- **Don't reach for an overshoot/back-out ease on frequent actions** (row-scroll, hover) — variant B's
  "pop" read as unpolished specifically because users trigger these constantly while browsing; save
  expressive motion (if ever used) for rare, celebratory moments, not the browsing loop.
- **Don't assume a slower/cinematic feel matches the Netflix reference point better** — variant C
  (the most literal Netflix-timing match) lost specifically because row-scroll is triggered
  constantly, and its slow settle felt sluggish exactly there, even though it looked good in isolated
  single-trigger tests.
- **Don't "restore consistency" by collapsing the two curves into one.** Two curves is the design:
  `--ease-standard` for travel, `--ease-out-soft` for accents under ~50px. Four surfaces
  (`.pk-title-echo`, `.pk-portal`, `.pk-dimmable`, `.pk-search-morph-toggle`) were *measured* and
  deliberately left on the accent curve while five others were moved off it — that makes the finding
  a threshold, not a ban on the token. A tidy-up pass noticing the inconsistency and normalising it
  is the single most likely way this regresses.
- **Don't treat "UAT-verified" as durable for sub-100ms motion defects.** A 280ms animation whose
  defect is confined to its first 16.7ms frame is not reliably visible to a human reviewer on a
  desktop browser. `.pk-sheet` was explicitly marked "UAT-verified, out of scope" on that basis, and
  the annotation then actively protected the bug from a token sweep. A passing visual review is not a
  reason to exclude a rule from a systematic measurement pass.
- **Don't infer that a tokenised rule is a correct rule.** Being inside the token system is no
  protection when the token itself is wrong for the amplitude — `.pk-drawer` was correctly tokenised
  and still jumped 104.8px, and a lint that only hunted hardcoded literals would have missed it and
  three other surfaces.

## How to verify motion

Per-frame displacement is the only oracle that settles these questions, and ExUnit cannot observe it.
Drive headless Chrome over CDP against the running app and sample `getBoundingClientRect` each
`requestAnimationFrame`. Four practices make the measurement trustworthy rather than merely
convenient:

- **Anchor per-frame deltas on the RESTING value captured before the trigger**, not on the first
  post-`transitionrun` sample. The displacement under investigation happens *between* `transitionrun`
  and the first rAF callback, so naive anchoring silently discards the exact frame you care about —
  it under-reported one drawer's 104.8px jump as 73.8px.
- **Run a control arm.** A probe that always reports "broken" is indistinguishable from a real
  finding. Measuring the same interaction at a viewport where it is known-good (or with the fix
  injected) proves the probe discriminates.
- **Trigger through a real click on the rendered control**, never by calling the easing function
  directly — pointer-gated controls (`(hover: hover) and (pointer: fine)`) are `display: none` in
  default headless Chrome, which can otherwise produce a false "this never renders" conclusion.
- **Treat headless frame timing as noise but first-frame displacement as signal.** Across repeated
  runs the stall before `transitionrun` varies wildly while the jump stays pinned — and noise moves
  in the worse direction only, never better.

**`transitionrun` firing is the one-line discriminator** between the two failure modes that present
identically as "it jumps": if it does not fire, the motion was never declared or the target value is
non-interpolable (an *absence*); if it fires and runs to `transitionend` with the full `elapsedTime`,
the motion is *badly distributed* and the curve is wrong. Check it before pattern-matching to either.

## Origin
Tokens and variant D synthesized from sketch: 006 (source file in `sources/006-motion-system/`).

Selection rules, amplitude thresholds, the from-rest rule, the preconditions and the verification
method were established by five debug sessions — `category-menu-scroll-animation`,
`catalog-preview-modal-jump`, `carousel-scroll-easing-jump`, `reduced-motion-order-bug` and
`mobile-search-expand-jump` — and are recorded in full in `.planning/debug/knowledge-base.md`.
Enforced by `test/pukllay_club_web/motion_rhythm_test.exs`.
