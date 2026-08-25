---
status: resolved
trigger: "On mobile when the search icon is expanded this just jump. I want to follow a subtle fluid smooth transition/animation. Be sure to record that as project knowledge and then evaluate any transition/animation to have same rhythm"
created: 2026-08-25
updated: 2026-08-25
resolved: 2026-08-25
human_verify: CONFIRMED
---

## Symptoms

- **Expected behavior:** Tapping the mobile header's search icon should expand the search box (and collapsing it should reverse) with a subtle, fluid, smooth transition/animation.
- **Actual behavior:** The search box snaps open/closed instantly with no transition — a hard jump, not an animation.
- **Error messages:** None. Purely a visual/motion issue — no console errors expected.
- **Timeline:** Always jumped. This has never animated smoothly since it was built — not a regression.
- **Reproduction:** On a mobile viewport, tap the search icon in the header to expand the search box (appears instantly, no transition); tap again or elsewhere to collapse it (also instant, no transition). Reproduces in both directions.

## Additional scope (user request)

1. Fix the search-expand jump so it animates with a subtle, fluid, smooth transition.
2. Record the resulting transition/animation rhythm (duration, easing, properties animated) as project knowledge (design-system/motion pattern), not just a one-off fix.
3. Audit all other existing transitions/animations in the codebase (nav drawer, carousel, theme toggle, etc.) against that same rhythm standard and flag/fix any inconsistencies, as part of this same debug session.

## Current Focus

**SESSION CLOSED — `status: resolved`, human-verified CONFIRMED on 2026-08-25.** No next action.
The one item still outstanding is the 481-1099px squeezed-open-pill defect recorded at the bottom
of this file under *Open finding*; it is **recorded only** and a separate `/gsd-debug` session for
it has **not** been started. Everything below is the historical investigation record.

- **bug_class:** Bohrbug — deterministic, reproduces every time in both directions, no timing dependence.
- **known_pattern_candidate:** `catalog-preview-modal-jump` (KB) explicitly swept `.pk-search-morph` and fixed its `width` curve (77.2px → 1.97px first frame) — but that was the **>480px** case. Its own comment at `app.css:771-776` **deferred the ≤480px case by name**. Per `carousel-scroll-easing-jump` lesson (vi): *a deferred lead is not a closed lead.*
- **hypothesis:** At ≤480px the mobile override (`app.css:2637-2644`) changes `.pk-search-morph.is-open` to `position: absolute; inset: 0 var(--pk-gutter); width: auto; height: 100%; box-shadow: ...`. The base rule's transition list is only `width, background-color, border-color`. `width: 44px → auto` is **not interpolable** (no `interpolate-size`/`calc-size()` in this sheet), and `position`/`inset`/`height`/`box-shadow` are either discrete-animated or absent from the transition list entirely. So the geometry change has **no animatable channel at all** on mobile — an ABSENCE of motion, not a badly-distributed curve.
- **discriminator (from KB `catalog-preview-modal-jump` lesson iii):** the reporter idiom "jumps, not a polished animation" is ambiguous between *motion never declared* and *motion badly distributed*, and **`transitionrun` firing is the one-line separator**. Predict: on mobile `transitionrun` does **NOT** fire for `width`; on desktop it does.
- **test:** headless-Chrome CDP harness against the running dev server at a ≤480px viewport; instrument `transitionrun`/`transitionend` on the morph and sample `getBoundingClientRect` per rAF, anchored on the RESTING value (KB measurement gotcha).
- **expecting:** mobile = zero width `transitionrun` + a single-frame 100%-of-travel step; desktop (control arm, 1280px) = `transitionrun` fires and travel spreads across ~17 frames at ~2px first frame.
- **next_action:** build the CDP harness and run the 2-arm mobile/desktop differential.

## Evidence

- **checked:** `.planning/debug/knowledge-base.md` — semantic match on motion entries.
  **found:** Four prior motion sessions establish the project's motion doctrine: `category-menu-scroll-animation` (absence of a declaration), `catalog-preview-modal-jump` (amplitude-inappropriate curve; `--ease-out-soft` is an ACCENT curve valid below ~50px travel), `carousel-scroll-easing-jump` (**for a FROM-REST interaction the entire ease-out family is disqualified, `v0` must be 0**), `reduced-motion-order-bug` (global `!important` guard at end-of-file).
  **implication:** The rhythm standard this session must record is already 80% established in prose across four KB entries — deliverable 2 is to consolidate it into `app.css` as durable, discoverable design-system documentation rather than invent it fresh.

- **checked:** `assets/css/app.css:238-242` — motion token definitions.
  **found:** `--duration-fast: 100ms`, `--duration-base: 180ms`, `--duration-slow: 280ms`, `--ease-standard: cubic-bezier(0.4, 0, 0.2, 1)`, `--ease-out-soft: cubic-bezier(0.16, 1, 0.3, 1)`.
  **implication:** Tokens exist and are correct. What is missing is the **selection rule** (which token for which amplitude/interaction kind), which is currently scattered across four rule-level comments and four KB entries.

- **checked:** `assets/css/app.css:754-786` — `.pk-search-morph` base rule.
  **found:** `transition: width var(--duration-slow) var(--ease-standard), background-color var(--duration-base) var(--ease-standard), border-color var(--duration-base) var(--ease-standard)`. Only three properties are transitioned.
  **implication:** Any mobile-only property change outside `{width, background-color, border-color}` is unanimated by construction.

- **checked:** `assets/css/app.css:771-776` — comment inside that base rule.
  **found:** Verbatim: *"At <=480px .is-open switches to `width: auto` (the overlay rule at the bottom of this file), which is NOT interpolable — that state snaps in one frame regardless of curve. Fixing that is a different problem (a non-interpolable value, not a front-loaded curve) and is deliberately not addressed here."*
  **implication:** **The prior session diagnosed this exact defect, wrote it down, and deferred it.** The root cause was already in the repo in plain language. This is the third time in this codebase that grepping its own prose located the defect faster than reasoning about the cascade (KB `category-menu-scroll-animation` lesson ii).

- **checked:** `assets/css/app.css:2637-2644` — the `@media (max-width: 480px)` override.
  **found:** `.pk-search-morph.is-open { position: absolute; inset: 0 var(--pk-gutter); width: auto; height: 100%; z-index: 5; box-shadow: ... }`.
  **implication:** Five property changes on mobile; **only `width` is in the transition list, and it changes to the one value that cannot interpolate.** `position` is not an animatable property at all.

- **checked:** CDP 2-arm differential (mobile 390px vs desktop 1280px control), real click on the rendered toggle, per-frame `getBoundingClientRect` anchored on the resting value.
  **found:** **MOBILE:** `transitionrun` fires for `border-*-color` only — **never for `width`**. 1 moving frame, **318px = 100.0% of a 318px travel**. Identical in both directions (expand `+318`, collapse `-318`). **DESKTOP CONTROL:** `transitionrun:width` **does** fire, `transitionend` at `elapsedTime 0.28`; 17 frames, first frame **2.0px = 0.8%**, peak 37.1px.
  **implication:** The probe **discriminates** (control arm proves it can see a working transition), and the discriminator answers cleanly: this is **ABSENCE of motion** (`category-menu-scroll-animation` class), *not* badly-distributed motion (`catalog-preview-modal-jump` class). The desktop arm also reproduces the KB's recorded `--ease-standard` figures (2.0px first frame, peak ~37px, 17 frames) exactly, confirming the harness is calibrated.

- **checked:** structural probe of `.pk-nav-inner` and its children at 390px and 480px, closed vs open.
  **found:** morph closed `{x:332, right:376, y:9.5, w:44, h:44, position:relative}`; open `{x:14, right:376, y:9.5, w:362, h:44, position:absolute}`. **The right edge (376) and the whole vertical box (y 9.5, h 44) are IDENTICAL in both states — only the left edge moves.** Siblings (`hamburger x:14 w:44`, `brand x:66 w:36`) are byte-identical in both states. `--pk-gutter: 0.875rem` = 14px; `.pk-nav-inner` is `position: relative`, padding-box 0..390, so it is the containing block.
  **implication:** The desired motion is exactly the desktop motion — grow leftward with the right edge pinned. Nothing else needs to move. And because `margin-left: auto` was already absorbing all free space, taking the morph out of flow cannot shift any sibling.

- **checked:** 3-arm fix differential — baseline vs **C1** (break condition 1 only: interpolable width, `position` still tied to `.is-open`) vs **C2** (break both: `position: absolute` in BOTH states).
  **found:** **C1 EXPAND looks perfect** — `transitionrun:width` fires, 15 frames, 0.8% first frame, no overflow. **C1 COLLAPSE is broken:** `overflowedDuring: true`, `maxScrollWDuring: 444` against `clientWidth 390`, right edge walking `376 → 444 → 441.6 → 432.9 → 414.7`. **C2 is clean in both directions:** 16/11 frames, 0.8% first frame both ways, right edge pinned at 376 throughout, `scrollWidth == clientWidth == 390` at all times.
  **implication:** **AND-gate CONFIRMED, and C1 is the trap.** On collapse `position` reverts to `relative` at t=0 while `width` is still ~362px, so a 362px box re-enters a 390px flex row that already holds hamburger+brand — and `.is-open`'s `flex-shrink: 1` left with the class, so base `flex: 0 0 auto` refuses to shrink and the row overflows. C1 would ship a **horizontal scrollbar flashing for 280ms on every collapse** — a regression in the exact class `footer-overflow-tablet-width` already fixed once and guards with `footer_overflow_test.exs`.

- **checked:** C2 on `/juegos/177` (the Detalle page, the only surface with `.pk-nav-crumb`, which is `flex: 0 1 auto; min-width: 0; overflow: hidden` and could in principle expand into the freed 44px).
  **found:** crumb `right: 181.1, width: 71.1` — **identical** before, during and after, in both baseline and C2. Header height 64px and `--pk-header-h: 64px` unchanged in every arm. `scrollWidth == clientWidth == 390` throughout.
  **implication:** The crumb cannot grow into the vacated slot because `flex: 0 1 auto` has `flex-grow: 0` — it only ever shrinks. Measured rather than reasoned, per KB practice. The header-height risk (the `header-height-wordmark-wrap` class) is also cleared: the 44px hamburger holds the row height independently of the morph.

- **checked:** full static inventory of every `transition`/`animation` declaration in `assets/css/app.css` (brace-matching parser over **comment-stripped** source — this file discusses transitions at length in prose and a naive grep matches the commentary), plus `assets/js/` and colocated hooks in `lib/`.
  **found:** 35 declarations. Divergences from the token rhythm: `.pk-nav-links a` = `150ms ease` (a curve in **neither** token — CSS `ease` is `cubic-bezier(0.25,0.1,0.25,1)`); `.pk-nav` and `.pk-portal` = raw `220ms cubic-bezier(0.16,1,0.3,1)` literals (220ms is the abandoned sketch-001/002 value the KB already identified); `.pk-footer-social a` and `.pk-drawer-social a` = `transition: all`; `.pk-search-morph-toggle` = `width` → `auto` (same non-interpolable defect as the main bug, on a child); `.pk-theme-toggle button` = hover + active colour change with **no transition declared at all**; `core_components.ex:463-481` = stock `transition-all ease-out duration-300` / `ease-in duration-200`.
  **implication:** Eight divergences to fix. Everything else already consumes tokens correctly, and the five surfaces the KB deliberately left on `--ease-out-soft` (`.pk-title-echo` 8px, `.pk-portal` 18-23px, `.pk-scroll-top` 3px keyframe, `.pk-dimmable` no travel, `.pk-search-morph-toggle` 12px) are **settled decisions to preserve, not divergences to "fix"** — the KB explicitly warns that restoring consistency by swapping curves is the recurrence path.

## Eliminated

- **hypothesis:** The user has OS-level reduced motion enabled, so the global `!important` guard is collapsing every transition to 1ms.
  **evidence:** `matchMedia('(prefers-reduced-motion: reduce)').matches === false` in the harness, and in the same run the desktop control arm played a full 280ms 17-frame width transition while mobile played none. A global guard cannot be selective by viewport.
  **timestamp:** 2026-08-25

- **hypothesis:** Amplitude-inappropriate easing curve (`--ease-out-soft` front-loading the travel), i.e. the `catalog-preview-modal-jump` root cause recurring on this surface.
  **evidence:** The morph's computed `transitionTimingFunction` is already `cubic-bezier(0.4, 0, 0.2, 1)` (`--ease-standard`) on all three properties, and `transitionrun` for `width` never fires at all — there is no curve being evaluated to be wrong. A front-loaded curve still produces 11-17 painted frames; this produces exactly 1.
  **timestamp:** 2026-08-25

- **hypothesis:** Fix it by making `auto` interpolable via `interpolate-size: allow-keywords` / `calc-size()` on `:root`.
  **evidence:** Two independent disqualifications. (1) It does not touch condition (2) — `position` is not an animatable property at all, so the C1 collapse overflow (measured: `scrollWidth` 444 vs 390) would remain. (2) It is a Chrome-only feature; this project's primary surface is mobile, where iOS Safari is dominant, so the accommodation would silently not apply on the exact devices that matter and the bug would persist unnoticed on the primary platform.
  **timestamp:** 2026-08-25

- **hypothesis:** C1 — the minimal fix: make the open width an interpolable `calc()` and leave `position` tied to `.is-open`.
  **evidence:** Measured directly. Expand is flawless (15 frames, 0.8% first frame) but collapse drives `documentElement.scrollWidth` to **444px against a 390px client width**, with the morph's right edge overshooting to 444 and walking back. Exactly the `reduced-motion-order-bug` lesson: with one firing and one armed condition, verifying against today's symptom cannot distinguish the fix that breaks both from the fix that breaks one — here the *expand* arm alone would have gone green and shipped the trap.
  **timestamp:** 2026-08-25

## Current Focus — reasoning_checkpoint

```yaml
reasoning_checkpoint:
  hypothesis: >
    At <=480px the mobile override gives .pk-search-morph.is-open a geometry change with NO
    animatable channel: width goes 44px -> auto (non-interpolable, so the width transition never
    starts) and position goes relative -> absolute (not an animatable property at all). The box
    therefore relocates in a single frame, 100% of a 318px travel, in both directions.
  confirming_evidence:
    - "transitionrun for `width` never fires on mobile, while it does fire on the 1280px control arm in the same harness run (direct observation, both arms)."
    - "1 moving frame carrying 318px = 100.0% of the travel, symmetric in both directions."
    - "Desktop control reproduces the KB's recorded --ease-standard signature exactly (2.0px first frame, peak 37px, 17 frames), proving the probe discriminates rather than printing a constant."
    - "The prior session wrote this exact diagnosis into app.css:771-776 and deferred it by name."
  falsification_test: >
    If `transitionrun:width` had fired on mobile with multi-frame motion, the cause would be curve
    distribution, not absence, and the fix would be a curve swap. It did not fire. Conversely, if
    making width interpolable alone produced clean motion in BOTH directions, condition (2) would be
    inert and C1 would be the correct minimal fix. It did not - collapse overflowed to 444px.
  fix_rationale: >
    Break BOTH AND-gate conditions structurally: at <=480px anchor .pk-search-morph as
    position: absolute; top: 0; right: var(--pk-gutter); height: 100% in BOTH states, so the ONLY
    thing the .is-open class changes is an interpolable width (44px -> calc(100% - 2*gutter)).
    This addresses the root cause rather than the symptom: the right edge and vertical box are
    already provably identical across states, so pinning them in CSS removes the discontinuity by
    construction instead of compensating for it with hardcoded offsets.
  blind_spots:
    - "Headless Chrome is not a real iOS Safari; calc()-vs-length interpolation and the absolute-in-both-states layout must be confirmed on a real phone. Routed to the human-verify checkpoint per the standing rule from search-right-align-mobile-cycle-3."
    - "Only /, /juegos/:id measured. /quienes-somos has no search slot (the hook is guarded on this.morph existing), so it is unaffected by construction."
    - "Landscape phones <=480px tall are not a case: the media query is max-WIDTH."
  candidate_causes:
    - "code (CSS): width: auto is non-interpolable - CONFIRMED, dominant."
    - "code (CSS): position is a non-animatable property changing on the same class toggle - CONFIRMED, armed and it fires on collapse."
    - "environment: OS-level prefers-reduced-motion collapsing all motion - ELIMINATED by measurement (matches === false, control arm animated)."
    - "config (build): LightningCSS dropping or reordering the rule - ELIMINATED; the rule is present and applying (computed position IS absolute, width IS 362px)."
  and_gate: >
    YES - two conditions, and this is the load-bearing finding. Condition (1) alone explains why
    nothing animates today. Condition (2) is armed but only fires on COLLAPSE, and was invisible
    until C1 was measured: fixing only (1) yields a perfect expand and a 444px horizontal overflow
    on collapse. The fix must break both, which is why it is structural (absolute in both states)
    rather than the one-line calc() swap.
```

## Resolution

**root_cause:** AND-gate fired — two conditions on `.pk-search-morph.is-open` inside `@media (max-width: 480px)`, and the fix had to break both.
1. **DOMINANT — non-interpolable target value.** `width: 44px → auto`. `auto` is not an interpolable value, so the base rule's `transition: width var(--duration-slow) var(--ease-standard)` **never started**: `transitionrun` for `width` never fired on mobile while it fired normally at 1280px in the same harness run. 318px of travel in a single painted frame, symmetric in both directions.
2. **ARMED, fires only on COLLAPSE — a non-animatable property on the same class toggle.** `position: relative → absolute`. `position` is not an animatable property at all. Invisible on expand (the two states' right edge and vertical box are provably identical, so the discrete flip has no visual consequence there), but on collapse `.is-open` leaves at t=0 and the still-362px box drops back into the flex row; `.is-open`'s `flex-shrink: 1` leaves with it, so the base `flex: 0 0 auto` refuses to give and the row overflows — measured `documentElement.scrollWidth` **444px against a 390px viewport**.

**Discriminator against the near-miss:** this is the `category-menu-scroll-animation` class (motion **absent**), not the `catalog-preview-modal-jump` class (motion **badly distributed**). Both present as "it jumps"; `transitionrun` firing is the one-line separator, and here it did not fire.

**Provenance:** the root cause was already written in the repo. `app.css:771-776` diagnosed it verbatim and deferred it as "a different problem… deliberately not addressed here". Third time in this codebase that grepping its own prose beat reasoning about the cascade.

**fix:**
- `assets/css/app.css` ≤480px block: `.pk-search-morph` is now `position: absolute; top: 0; right: var(--pk-gutter); left: auto; height: 100%` in **both** states, so the only thing `.is-open` changes is `width: calc(100% - 2 * var(--pk-gutter))` — the identical rendered value `auto` produced (362px at 390px), as a length the browser can interpolate. Safe because the right edge (376px) and vertical box (y 9.5, h 44) were measured identical across states, and `margin-left: auto` was already absorbing all free space so no sibling moves.
- Added `box-shadow` to the base transition list so the overlay's shadow fades in lockstep instead of popping at full strength on frame one.
- **Measured result: 318px in 1 frame (100%) → 2.7px first frame (0.8%) spread over 17 frames, both directions**, right edge pinned at 376 throughout, zero overflow. Verified at 320/375/390/430/480px (4/4 clean reps at 320px after one noisy outlier).

**Second defect, found by the audit and fixed** — pre-existing, verified byte-identical on the untouched tree: `.pk-search-morph` base `flex: 0 0 auto` → `flex: 0 1 auto; min-width: 44px`. Above 480px the row cannot seat a full 17.5rem pill, so `.is-open`'s `flex-shrink: 1` squeezes it; a `width` transition interpolates the **specified** value with flex shrinking applied on top, so when the class left, shrink permission left with it and the used width snapped from the shrunk value up to the full specified 280px before easing down — **331.5% of travel in frame one at 481px** (84.8% at 768px, 124.8% at 900px), right edge through the viewport, `scrollWidth` overflowing. Keeping shrink permission constant across states removes it; `min-width: 44px` now pins the locked touch floor that `flex-shrink: 0` used to (it cannot be left to `min-width: auto` — `overflow: hidden` collapses the automatic minimum to zero). Result: **zero horizontal overflow and right edge pinned at every width 481-1440px**, settled geometry byte-identical.

**Audit sweep (deliverable 3)** — 35 declarations inventoried via a brace-matching parser over comment-stripped source. Eight divergences fixed:

| Surface | Divergence | Fix |
|---|---|---|
| `.pk-search-morph` ≤480px | no animatable channel at all | the root-cause fix above |
| `.pk-search-morph` flex | collapse pop + overflow ≥481px | `flex: 0 1 auto; min-width: 44px` |
| `.pk-search-morph-toggle` | `width: auto` — never animated | `width: 2rem` (measured value of `auto`, identical at 390/1280px) |
| `.pk-nav-links a` | `150ms ease` — a curve in **neither** token | `var(--duration-fast) var(--ease-standard)` |
| `.pk-nav` | raw `220ms cubic-bezier(0.16,1,0.3,1)` | `var(--duration-base) var(--ease-standard)` |
| `.pk-portal` | raw `220ms cubic-bezier(...)` | tokenised; **curve deliberately kept** `--ease-out-soft` per the measured 18-23px KB decision |
| `.pk-footer-social a` | `transition: all` | explicit `background-color, color, border-color` |
| `.pk-drawer-social a` | `transition: all` | explicit `background-color, color` |
| `.pk-theme-toggle button` | hover + active colour change with **no transition at all** | `color var(--duration-fast) var(--ease-standard)` |
| `core_components.ex` `show/hide` | stock `transition-all ease-out duration-300` / `ease-in duration-200` | `duration-[var(--duration-slow|base)] ease-[var(--ease-standard)]`, `time:` synced to 280/180 |

**Deliberately NOT changed** — the five surfaces the `catalog-preview-modal-jump` sweep measured and left on `--ease-out-soft` (`.pk-title-echo` 8px, `.pk-portal` 18-23px, `.pk-dimmable` no travel, `.pk-search-morph-toggle` 12px, `.pk-scroll-top` 3px keyframe). That decision makes the finding a *threshold*, not a ban, and the KB explicitly names "restoring consistency" as the recurrence path. `.pk-scroll-top`'s raw `1.6s` is also kept: it is an ambient loop period, not a UI-response tier, and none of the three response tokens fits.

**verification:**
- `mix quality` green end to end — hex.audit, deps.audit, format (+Styler), credo --strict, sobelow, **474 tests / 0 failures** (was 466; +8 from the new guard and the split gutter test).
- CDP sweep at 320/375/390/430/480/481/768/1280px: `transitionrun:width` fires in both directions at every width, right edge and vertical box pinned throughout, `scrollWidth == clientWidth` everywhere.
- **Reduced-motion guard re-verified and NOT regressed** (commits 98b2198 / b430789): under `--force-prefers-reduced-motion` the morph and every newly-touched surface — including the brand-new `.pk-theme-toggle button` transition, which needed no registration because the guard is universal — report `0.001s`, and expand/collapse complete in exactly 1 frame.
- Screenshots at 390/800/1280px in `.planning/debug/assets/mobile-search-expand-jump/`.
- **HUMAN VERIFY: CONFIRMED (2026-08-25).** Checkpoint answered "confirmed fixed" on real-device
  review. This closes the blind spot the reasoning checkpoint flagged and could not close by
  measurement — headless Chrome is not iOS Safari, so `calc()`-vs-length interpolation and the
  absolute-in-both-states layout needed a real phone. Per the standing rule from
  `search-right-align-mobile-cycle-3`, measurement establishes MECHANISM and cannot establish
  PERCEPTUAL SUFFICIENCY; the fix was routed to a human **before** being declared resolved, and
  confirmed on the first attempt (as with `carousel-scroll-easing-jump`).

**recurrence guard:** `test/pukllay_club_web/motion_rhythm_test.exs` — 7 tests written as **audit rules over every animated rule in the stylesheet**, not assertions about specific selectors, so they cover the class rather than the instance. **5 RED-verified** by `git stash`ing the fix and re-running (non-interpolable dimension, hardcoded literals, `transition: all`, the accent-curve boundary, the Elixir-side tokens), each with its intended diagnostic. The remaining 2 are **boundary neighbours, green in both states by design**: the token values themselves (guards a retune silently invalidating every recorded amplitude threshold) and the large-amplitude surfaces already fixed by the prior session. `header_search_gutter_test.exs`'s `inset`-shorthand assertion was rewritten to pin the **invariant** (both horizontal edges derive from `--pk-gutter`) rather than the **mechanism**, plus a new test pinning `position` to the base rule — that one fails on exactly the C1 partial fix.

**files_changed:** `assets/css/app.css`, `lib/pukllay_club_web/components/core_components.ex`, `test/pukllay_club_web/motion_rhythm_test.exs` (new), `test/pukllay_club_web/header_search_gutter_test.exs`, `.claude/skills/sketch-findings-pukllay_club/references/motion-system.md`. Commit `40fd646`.

**guard artifacts re-verified at archive time:** `mix test test/pukllay_club_web/motion_rhythm_test.exs test/pukllay_club_web/header_search_gutter_test.exs` → **14 tests, 0 failures**. Both paths and all named tests exist as recorded (a stale guard path is worse than none, since a future Phase-0 match would surface it as if it were real).

## Prevention — blameless postmortem

### Branching 5-Whys

Started from the `reasoning_checkpoint.candidate_causes` branches rather than re-derived, per RCA
practice. **No blame attaches to any person or agent at any node below**: every individual decision
here reads as correct in isolation, and each branch terminates in a missing *affordance*, not a
missing *effort*.

**Branch A — CODE (the dominant condition): a transitioned property given a non-interpolable value.**
1. *Why did the mobile search not animate?* `transitionrun` for `width` never fired.
2. *Why?* The target value was `auto`, which is not interpolable, so the browser generates no
   transition at all — not a slow one, not a bad one, **none**.
3. *Why was `auto` used?* Because the mobile overlay treatment expresses "fill the row between the
   gutters" as `inset: 0 var(--pk-gutter); width: auto` — a layout idiom that is entirely correct
   for **static** layout and silently incompatible with **animated** layout.
4. *Why was the incompatibility invisible?* CSS offers **no affordance whatsoever**: an unanimatable
   transition is not an error, not a warning, not a degraded state — it is simply a transition that
   never starts. Meanwhile the `transition: width ...` declaration sits in the base rule and *reads*
   as covering this case. The author of the base rule and the author of the overlay rule were both
   right; the defect exists only in the 1900-line gap between them.
5. **Actionable condition:** nothing in the stylesheet enforced that a property named in a
   `transition` list may not be assigned a non-interpolable value by any *other* rule. → guard A.

**Branch B — CODE (the armed condition): a non-animatable property riding the same class toggle.**
1. *Why did the minimal fix (C1) overflow to 444px on collapse?* `position` reverted to `relative`
   at t=0 while `width` was still ~362px.
2. *Why?* `position` is not an animatable property at all, so the class toggle flips it discretely
   while the width is still mid-flight.
3. *Why was `position` on `.is-open` at all?* The overlay was authored as one state change ("when
   open, become an overlay") rather than as an invariant plus a delta ("always an overlay; only the
   width changes"). The former is the more natural way to *write* it and the wrong way to *animate* it.
4. *Why was the trap invisible?* Because the discrete flip has **no visual consequence on expand** —
   the two states' right edge (376px) and vertical box (y 9.5, h 44) are provably identical — and
   only bites on **collapse**. A one-directional check goes green on the trap.
5. **Actionable condition:** a class toggle that changes both an animatable and a non-animatable
   property is a latent trap, and **verifying only the forward direction cannot see it**. → guard B.

**Branch C — PROCESS: the deferred lead.**
1. *Why did a bug present since the feature was built survive four prior motion sessions?* Because
   `catalog-preview-modal-jump` **diagnosed it verbatim** at `app.css:771-776` and deferred it.
2. *Why did the deferral become permanent?* The comment recorded the deferral and its reasoning but
   **no re-open trigger** — so a well-reasoned "not now" decayed into "never" by default.
3. *Why is that the default?* Deferring is free at the moment of deferral and its cost is paid by a
   later session that has to rediscover the whole thing; nothing in the artifact charged interest.
4. **Actionable condition:** this is `carousel-scroll-easing-jump` lesson (vi) — *a deferred lead is
   not a closed lead* — now observed a **second** time in this codebase, which promotes it from an
   anecdote to a standing rule. → guard D (KB) plus the fact that the fix's own comments now record
   the arithmetic rather than a deferral.

**Branch D — CONFIG / TOOLCHAIN.** `mix quality` (hex.audit, deps.audit, format+Styler, credo
--strict, sobelow, test) parses **Elixir sources only** and never evaluates `app.css`. ExUnit cannot
observe `transitionrun`, a computed style, or a per-frame displacement. The asset pipeline
(Tailwind v4 / LightningCSS) passed the non-interpolable value through verbatim and exited 0 —
correctly, since it is valid CSS. There is still **no visual-regression or headless-layout gate in
CI**, so a header control can fail to animate entirely without failing anything.

**Branch E — ENVIRONMENT.** ELIMINATED as a cause by measurement (`prefers-reduced-motion` matched
`false`; the 1280px control arm animated in the same run — a global guard cannot be selective by
viewport). But it left a **residual limitation, not a cause**: headless Chrome is not iOS Safari,
which is why this session could not self-certify and routed to a human checkpoint.

**Branch F — DATA/CONTENT.** Not a cause of the reported bug, but the reason the ≥481px sibling
defect exists at all: `width: 17.5rem` is achievable or not depending on the *content strings* in
the row (wordmark, nav links), so the capacity defect is latent in the CSS and surfaces only for
particular copy — the same content-dependence `header-height-wordmark-wrap` recorded. This is the
open finding below.

### Why wasn't this caught?

**No gate existed for this class** — and this session sharpens the finding past its four
predecessors, because here **the diagnosis was already committed to the repository in plain
language and still did not stop the bug**. `app.css:771-776` named the mechanism, named the
viewport band, and explained why it was being left alone. Code review therefore had the answer in
front of it and was *right* to pass the diff: the comment documented a deliberate, reasoned
deferral, and reviewing a deferral is not the same as reviewing a defect. Every automated layer was
blind for the reasons in Branch D. UAT was blind for a mundane reason too: the search box **worked**
— it opened, it closed, it was usable — so nothing about it fails a functional walkthrough; only its
motion was absent, and absent motion is much harder to notice than wrong motion (there is no jarring
artifact to catch the eye, just an instant state change that reads as "snappy" until someone asks
for polish). **The user was the only available detector**, exactly as in `footer-desktop-overloaded`.

### Recurrence guard

Four artifacts, verified present and green at archive time (14 tests, 0 failures):

- **(A) `test/pukllay_club_web/motion_rhythm_test.exs`** (new, 7 tests, **5 RED-verified** by
  `git stash`ing the fix). Written as **audit rules over every animated rule in the stylesheet**,
  not as assertions about specific selectors, so they close the *class*: no element may transition a
  dimension another rule sets to `auto` (branch A); no `transition` shorthand may hardcode a duration
  or curve; no rule may use `all` to pick what animates; large-amplitude surfaces may not use the
  accent curve. Two are **boundary neighbours, green in both states by design** — the token values
  themselves (so a retune cannot silently invalidate every recorded amplitude threshold) and the
  already-fixed large-amplitude surfaces.
- **(B) `test/pukllay_club_web/header_search_gutter_test.exs`** — a new test pins `position` to the
  base rule so the box is absolutely positioned in **both** states. This one **fails on exactly the
  C1 partial fix**, which is the whole point: it is the assertion that distinguishes breaking one
  AND-gate condition from breaking both. The pre-existing `inset`-shorthand assertion was rewritten
  to pin the **invariant** (both horizontal edges derive from `--pk-gutter`) rather than the
  **mechanism**, so the guard survives a legitimate refactor.
- **(C) `.claude/skills/sketch-findings-pukllay_club/references/motion-system.md`** — the rhythm
  standard (deliverable 2), now a five-rule document auto-loaded during UI implementation: duration
  by *what* is changing, curve by *amplitude*, `v0 = 0` for from-rest interactions, **preconditions —
  motion that cannot happen at all** (this session's contribution), and reduced motion is global.
  This is documentation-as-guard: it reaches the next author *before* they write the rule, which no
  test can do.
- **(D) This knowledge-base entry**, matched by its error patterns, carrying the prior-art note so
  the deferred lead cannot be re-deferred a third time.

**Oracle type: derived (contract).** Stated honestly, and it is the same caveat every CSS-behaviour
session in this codebase has recorded: the true oracle is `transitionrun` firing and a per-frame
displacement curve, which ExUnit **cannot** observe. The assertions pin the structural preconditions
that behaviour depends on. The behavioural proof was the CDP sweep (318px/1 frame → 2.7px first
frame over 17 frames, 8 viewport widths, both directions) plus human confirmation on a real device.
**This is the fifth instance of the standing pattern: CSS-behaviour defects are closed by a browser
and a human, and only *fenced* by ExUnit.**

**Most likely regression path:** someone re-authoring the mobile overlay as a single state change
(`.is-open { position: absolute; width: auto }`) because that is the more natural way to express
"become an overlay when open" — which re-arms **both** conditions at once. Guard B fails on it. The
second path is a future tidy-up reading `width: calc(100% - 2 * var(--pk-gutter))` as a verbose way
to write `auto` and "simplifying" it; the rule-level comment records why it is a length.

## Open finding — RECORDED ONLY, not fixed, needs a design decision

The audit surfaced a **layout/capacity defect** at 481-1099px that is not a motion bug and cannot be fixed by motion tuning. Pre-existing (settled geometry verified byte-identical before and after this session's changes) and out of the reported mobile scope.

`.pk-search-morph.is-open`'s `width: 17.5rem` is not achievable across most of that band, so `flex-shrink: 1` squeezes the open pill. Measured settled open widths: **481px → 98.7px, 560 → 177.7, 640 → 257.7, 720 → fits, 768 → 171.7 (the wordmark reveals at 48rem and re-consumes the room), 800 → 49px, 900 → 149, 1000 → 249, 1024 → 273, 1100+ → fits.**

**At 800px the "open" pill settles at 49px — 5px wider than the closed 44px icon.** The screenshot (`open-800-squeezed.png`) shows the result: tapping search dims the header and leaves a ~49px circle containing only the filter glyph — no input, no placeholder, no close button. The search box is effectively unreachable at that width.

This session's flex fix removed the *overflow* half of the symptom in that band, and the residual "hold, then run" collapse (the transition spends part of its duration animating a specified value above the used ceiling) is a symptom of the capacity problem, not a curve problem. Fixing it properly means a design decision — most likely extending the mobile overlay treatment upward to the width where 17.5rem genuinely fits (~1100px), which is how the ≤480px case already works. Surfaced rather than decided unilaterally.

### Status of this finding at archive time

**RECORDED ONLY — deliberately NOT started.** No debug session exists or has been opened for it; no
`.planning/debug/*.md` file was created for it. A separate `/gsd-debug` session will be started for
it later by the orchestrator. It is recorded here and in the knowledge-base entry so that whoever
picks it up inherits the measurements rather than re-deriving them.

**What the next session inherits, already measured — do not re-measure:**

- Settled open widths across the band: **481 → 98.7px, 560 → 177.7, 640 → 257.7, 720 → fits,
  768 → 171.7** (the wordmark reveals at 48rem and re-consumes the room), **800 → 49px, 900 → 149,
  1000 → 249, 1024 → 273, 1100+ → fits.**
- The worst point is **800px, where the "open" pill settles at 49px — 5px wider than the closed
  44px icon**, containing only the filter glyph: no input, no placeholder, no close button. Evidence
  screenshot: `.planning/debug/assets/mobile-search-expand-jump/open-800-squeezed.png`.
- **It is pre-existing, not a regression of this session** — settled geometry was verified
  byte-identical before and after this session's changes, and it is out of the reported mobile scope.
- It is a **layout/capacity defect, not a motion defect**, and cannot be fixed by motion tuning. The
  residual "hold, then run" collapse in that band is a *symptom* of the capacity problem; treating it
  as a curve problem is the trap.
- Per `carousel-scroll-easing-jump` lesson (vi) and Branch C of the postmortem above — *a deferred
  lead is not a closed lead* — this deferral carries an explicit re-open trigger rather than a bare
  "not now": **it re-opens as its own `/gsd-debug` session, on the orchestrator's schedule.**
