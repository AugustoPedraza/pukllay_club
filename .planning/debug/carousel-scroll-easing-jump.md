---
status: awaiting_human_verify
trigger: "Follow-up from resolved session catalog-preview-modal-jump (commit 78642fa): the .CarouselScroll colocated hook in lib/pukllay_club_web/components/carousel_row.ex (mounted(), lines ~66-96) drives the carousel row's prev/next arrow-click scroll with a hand-rolled quintic ease-out (`1 - Math.pow(1 - t, 5)`) over `0.85 * rail.clientWidth`, which the just-closed session's report estimated at roughly 107px on mobile widths up to ~365px on desktop container widths. This is the same 'easing curve validated at small amplitude, reused at large amplitude' bug class fixed in app.css this session (see knowledge-base.md's catalog-preview-modal-jump entry for the CSS-side pattern and its ~35/51/73px --ease-out-soft safety thresholds at fast/base/slow durations — this JS curve is a different function, not directly covered by those numbers, so its own safety threshold must be derived independently). User instruction: 'Fix both using gsd-debug' (this + the reduced-motion source-order bug, filed separately as reduced-motion-order-bug)."
created: 2026-08-25T12:00:00Z
updated: 2026-08-25T12:00:00Z
---

## Current Focus

bug_class: Bohrbug (deterministic — a pure arithmetic property of a curve, no timing dependence)

prior_art_verdict: NOT PREVIOUSLY CLEARED. Both cited sessions concern DIFFERENT code paths; see
Evidence entries 2 and 3. This path has never been investigated.

hypothesis: UNVERIFIED — carried forward as a lead, not a conclusion. The comment at
carousel_row.ex:66-71 explicitly frames `easeOutSoft` as "the project's own soft ease-out curve
(--ease-out-soft's JS twin)" — i.e. it was deliberately modeled on the same CSS token now known to
be amplitude-inappropriate above ~50px of travel. If the JS quintic front-loads similarly to the CSS
cubic-bezier at travel distances in the hundreds of pixels, arrow-click scrolling would read as a
"jump-then-crawl" the same way `.pk-sheet` did pre-fix.
test: DONE — closed-form evaluation validated against the prior session's known figures, times a
LIVE-MEASURED `rail.clientWidth * 0.85`, plus a real-hook-click vs native-`scrollBy` differential.
expecting: MET — defect CONFIRMED at desktop amplitudes. See reasoning_checkpoint.

reasoning_checkpoint:
  hypothesis: >
    The arrow scroll pops because `easeOutSoft(t) = 1 - (1-t)^5` is an ease-OUT, whose velocity at
    t=0 is MAXIMAL (v0 = 5A/D), applied to a rail scroll that starts from REST. At the measured
    desktop amplitude (0.85 x 1216px = 1033.6px) that is 25,840 px/s out of a standing start,
    placing 35.28% of the whole travel — 364.6px, more than TWO full 176px card pitches — into the
    first 16.7ms frame. The eye reads a discontinuity of that size at motion onset as a teleport,
    after which the remaining frames decay below the threshold of perceived motion.
    The deeper error is a category mistake in the code's own stated intent (carousel_row.ex:66-71,
    "so an arrow click matches the free-momentum touch scroll's feel"): a touch fling IS an ease-out
    and reads as continuous ONLY because the finger already supplied that velocity — the hand is the
    ease-in. A CLICK has no prior motion, so transplanting the fling's curve to it reproduces the
    fling's second half without its first, which is precisely a velocity discontinuity.
  confirming_evidence:
    - "MEASURED live via the real hook click (not simulated): clean contiguous rep (maxGap 16.7ms) first frame = 341px of a 1034px travel, motion effectively complete in 7 frames (98.6% by frame 7), then 4 frames of sub-10px crawl."
    - "Closed-form predicts 364.6px at t=16.667/200; the measured 341px back-solves to t=15.4ms, i.e. the sub-frame offset between click handler and first rAF callback. Prediction and measurement agree."
    - "Amplitude is MEASURED, not assumed: rail.clientWidth = 1216px for every viewport >= 1440 (max-w-7xl 1280 minus 2x2rem gutter), so amplitude is hard-capped at 1033.6px. Confirmed at 1440/1920/2560."
    - "Same-session differential against the platform's own calibrated answer for this exact job: native scrollBy({behavior:'smooth'}) over the IDENTICAL 1034px measures first frame 0px, peak 136px/frame, ~32 frames. The hook's FIRST frame (341px) exceeds native's PEAK frame by 2.5x."
    - "Harness validated against a KNOWN result before use: the cubic-bezier evaluator reproduces the prior session's 68.6/46.7/32.7% and 35.0/51.4/73.4px figures exactly."
  falsification_test: >
    If AMPLITUDE (not the curve family) were the operative variable, holding the curve and enlarging
    the duration would rescue it. Computed: to bring the quintic's first frame under 24px at
    1033.6px you need D = 3591ms — 18x the current duration and absurd for a carousel arrow. And if
    the EXPONENT were the problem, a lower-order ease-out would fix it: the cubic 1-(1-t)^3 still
    measures 237.5px first frame at v0 = 15,504 px/s. Both falsifications FAILED, which generalises
    the finding: every curve of the form 1-(1-t)^n has v0 = nA/D > 0, so the ENTIRE ease-out family
    is disqualified from a from-rest scroll at this amplitude, regardless of exponent or duration.
    Only v0 = 0 — an ease-in-out — can fix it. The fix is therefore forced, not preferred.
  fix_rationale: >
    Replace the quintic ease-out with the JS twin of the project's own `--ease-standard`,
    cubic-bezier(0.4, 0, 0.2, 1), leaving the 200ms duration untouched. It satisfies the forced
    requirement v0 = 0 (first frame 364.6 -> 17.8px, a 20x reduction, and below the 24px inherited
    threshold), and among ease-in-outs it best preserves the author's documented momentum intent: its
    deceleration tail is 48% of the run vs symmetric smoothstep's 28% (the current quintic's is 72%),
    so it keeps the fling character while starting from rest. It is also the codebase's single
    validated large-amplitude curve — the sweep moved five CSS surfaces onto exactly this bezier — so
    the hook stops being the last outlier and a future reader meets one curve, not two. CURVE ONLY,
    never duration, per the KB's explicit lesson from catalog-preview-modal-jump.
  blind_spots:
    - "Headless x86 Chrome, not a real device. Mitigated as the prior sessions did: the conclusion rests on the arithmetic-derived first-frame value, which matched measurement; frame TIMING is treated as noise. Noisy reps split the pop across two frames (109+333, 146+320, 160+319) whose SUMS (442-479px) all exceed the clean rep's 341px — noise moves in the worse direction only, never better."
    - "'Pop' is perceptual. The 24px threshold is inherited from the prior session and is a bright line, not a measured constant — which is exactly why this session anchors on the MEASURED native-smooth-scroll profile (0px first frame, 136px peak) as an independent, platform-calibrated reference instead of relying on the inherited number alone."
    - "Not human-verified on a real device yet, and this was never a user-reported symptom. It is a measured mechanism; perceptual sufficiency needs the user's eye (cf. search-right-align-mobile-cycle-3)."
    - "Peak velocity RISES under the replacement (364.6px first frame but 228.1px peak vs the quintic's 364.6px peak). That is the intended trade — moving the peak off frame one and into the middle of the run is the whole point — but it means the fix is not a uniform slowdown."
  candidate_causes:
    - "code (JS): the easing function is an ease-OUT, so v0 is maximal from rest. CONFIRMED — dominant and sufficient."
    - "code (JS): amplitude 0.85 x clientWidth, uncapped up to 1033.6px. CONTRIBUTING but NOT independently defective — the identical amplitude under an ease-in-out measures 17.8px first frame. Held constant across the fix to prove the curve is the operative variable."
    - "config (duration): the fixed 200ms. TESTED AND ELIMINATED — scaling it cannot rescue the quintic (needs 3591ms) and shortening it makes it worse. Duration is not implicated."
    - "environment: headless dropped frames. ELIMINATED — the contiguous rep (maxGap 16.7ms) gives 341px; noisy reps only ever push the two-frame sum higher."
    - "data: card count / scrollWidth. ELIMINATED — amplitude derives from clientWidth (viewport geometry), not content; scrollWidth varied 2550 vs 5104 across runs with no effect on first-frame behaviour."
  and_gate: >
    NO — single sufficient cause, unlike `.pk-sheet`'s curve x token-drift AND. There is no enabling
    second condition here: the curve is a JS literal with no token system to drift from, and the
    amplitude is not independently a defect. Proven by holding amplitude constant at 1033.6px and
    varying only the curve: 364.6px -> 17.8px. One condition, one fix.

next_action: DONE — fix applied and verified (341px -> 2px measured first frame, prediction matched
term for term, `mix quality` green at 466 tests). AWAITING HUMAN VERIFICATION on a real pointer-fine
display >= 1440px, where the amplitude sits at its 1033.6px cap. Do NOT archive until confirmed.

## Symptoms

expected: Clicking a carousel row's prev/next arrow button should scroll the rail smoothly, feeling
like one continuous motion comparable to the free-momentum feel of a touch swipe — not a pop
followed by a slow crawl.
actual: Not independently confirmed by human report in this session — surfaced as a code-pattern
match during the prior sweep's cleanup ("carousel_row.ex:66's JS quintic ease-out puts ~107px
(mobile) to ~365px (desktop) into frame one"), not as a user-reported symptom. Treat as a hypothesis
to verify, not an established defect, until measured.
errors: None expected — this is a motion-feel question, not a functional error.
reproduction: On both a mobile-width and desktop-width viewport, load the catalog page, locate a
carousel row wide enough to overflow (so prev/next arrows render — gated to
`(hover: hover) and (pointer: fine)` on desktop per the component's own moduledoc, so mobile touch
devices may not show the arrows at all — confirm arrow visibility per viewport before testing), and
click the next/prev arrow. Observe whether the rail's scroll position visibly pops on the first
animation frame.
started: Not a regression — this hook and curve have been in place since sketch 023-B; only
surfaced as a candidate concern now, by analogy to the CSS-side finding, not by a new user report.

## Eliminated

(none yet)

## Evidence

- timestamp: 2026-08-25T12:00:00Z
  checked: lib/pukllay_club_web/components/carousel_row.ex, mounted() hook body, lines 60-97
  found: `const easeOutSoft = (t) => 1 - Math.pow(1 - t, 5)` (quintic ease-out) over
  `scrollDuration = 200` ms, applied to `delta = direction * this.rail.clientWidth * 0.85`, written
  to `this.rail.scrollLeft` inside a `requestAnimationFrame` loop. A `prefers-reduced-motion: reduce`
  check already exists and short-circuits to an instant jump (no animation at all) when set — so this
  investigation only concerns the non-reduced-motion path.
  implication: Confirms the code matches the pattern flagged in the sweep report; gives an exact
  formula and duration to evaluate closed-form, the same technique used to establish the CSS-side
  root cause without relying on frame-timing measurements alone.

- timestamp: 2026-08-25T13:05:00Z
  checked: knowledge-base.md's `category-menu-scroll-animation` entry, specifically its
  "Deliberately NOT built" clause naming "the JS per-frame `easeOutSoft` scroller (the
  `.CarouselScroll` pattern, carousel_row.ex:80-95)".
  found: DIFFERENT CODE PATH — confirmed, not assumed. That session's subject is the DOCUMENT
  scroller (`html { scroll-behavior: smooth }`) animating native fragment navigation to
  `href="#carousel-KEY"` anchors. It cites `.CarouselScroll` only as a PATTERN it considered
  COPYING into a new handler for that anchor-scroll use case, and then dropped ("it would have
  added an animation loop, a reduced-motion branch and a second scroll-position writer"). It never
  executed, measured or evaluated the existing arrow-click rail scroller. Its one substantive
  contact with this hook is a COMPATIBILITY note in the opposite direction (app.css:264-268): the
  new `html` rule is scoped so it can NOT reach `.pk-rail`, precisely BECAUSE `.CarouselScroll`
  writes `rail.scrollLeft` every frame and two curves would fight. That is a statement about
  coexistence, not a clearance of the curve.
  implication: The "deliberately NOT built" record does NOT clear this path. It is about whether to
  ADD a second JS scroller elsewhere; this session is about the curve inside the one that already
  exists. Prior art consumed, not re-derived — and it does not close the question.

- timestamp: 2026-08-25T13:08:00Z
  checked: .planning/debug/G-01-4-carousel-affordance.md (full read).
  found: DIFFERENT CONCERN, and now partly obsolete. That session diagnosed a missing `w-full` on a
  daisyUI `.carousel` rail causing page-level horizontal scroll. Its only contact with this hook was
  `sync()` — the `scrollWidth > clientWidth` OVERFLOW-VISIBILITY check (its Evidence entry
  2026-08-18T23:18) — never `onClick`, never `easeOutSoft`, never the animation loop. It also
  predates the current markup: carousel_row.ex's moduledoc now records "Not daisyUI's `.carousel`
  component (used pre-01-11)", so the rail is `.pk-rail` and that session's root cause no longer
  exists in this file.
  implication: G-01-4 did not investigate or clear the easing path either. Combined with entry 2,
  NO prior session has examined this curve. The lead is genuinely un-investigated, so measuring it
  is not redundant work.

- timestamp: 2026-08-25T13:12:00Z
  checked: catalog-preview-modal-jump's `noted_outside_the_css_sweep` and its
  `verification_drawer.signal_grep_for_encoded_old_value`.
  found: The two records CONTRADICT each other, and the later one retracts the earlier. The drawer
  grep-signal cleared carousel_row.ex:66 as "correct usage on a correct amplitude" because
  row-scroll is one of the two surfaces sketch 006 validated. The subsequent sweep re-opened it:
  "that justification is weaker than it looked, since 107-365px is not a small amplitude. Row-scroll
  IS one of the two surfaces sketch 006 validated, but it was validated as a FEEL, not at these
  travels." It was then explicitly NOT swept, for four stated reasons (JS not CSS; different curve
  so no token swap applies; unreported; changing a hook is a behaviour change).
  implication: The prior session's own final position is "unresolved, needs its own measurement" —
  which is exactly this session's remit. It also supplies the reusable harness gotcha: anchor
  per-frame deltas on the RESTING value, never on the first post-event sample.

- timestamp: 2026-08-25T13:30:00Z
  checked: Arrow renderability per pointer type — headless Chrome 151, two instances, identical
  markup and identical `data-overflows="true"`, differing ONLY in the emulated pointer/hover
  capability (instance 2 launched with
  `--blink-settings=primaryHoverType=2,availableHoverTypes=2,primaryPointerType=4,availablePointerTypes=4`).
  found: A clean 2-arm differential on the media query itself. Instance 1 reported
  `hover: none, pointer: none` -> `(hover: hover) and (pointer: fine)` FALSE -> `.pk-rail-btn`
  computed `display: none` at ALL 11 viewports (292-1216px rail widths) despite `data-overflows`
  being true everywhere. Instance 2 reported `hover: hover, pointer: fine` -> query TRUE ->
  `display: flex` at all 11. HARNESS ARTIFACT CAUGHT AND CHASED DOWN: the first amplitude sweep
  reported "arrows never render anywhere", which was headless Chrome reporting `pointer: none`, not
  a property of the app — it would have falsely cleared the whole investigation as moot.
  implication: CONFIRMS the directive's hypothesis for real touch devices: a phone reports
  `hover: none, pointer: coarse`, the query fails, and the arrows are `display: none` — never
  rendered, no dead tap target, so the phone amplitude case IS moot. But it does NOT make narrow
  viewports moot: a DESKTOP browser resized to 320-480px keeps `pointer: fine`, so arrows render
  there at 292-437px rail widths. The reachable-with-arrows amplitude range is therefore
  248-1034px, all of it on pointer-fine devices.

- timestamp: 2026-08-25T13:34:00Z
  checked: `rail.clientWidth` measured live at 11 viewports; amplitude = clientWidth * 0.85; first
  frame = amplitude * 35.28%.
  found: clientWidth 292 (320px vp) / 362 (390) / 402 (430) / 437 (480) / 689 (768) / 945 (1024) /
  1201 (1280) / 1216 (1440, 1920, 2560 — CAPPED by max-w-7xl 1280 minus 2x2rem gutter). Amplitudes
  248.2 -> 1033.6px. First frames 87.6 -> 364.6px. The prior sweep's estimates ("~107px mobile,
  ~365px desktop") are CONFIRMED: 108.5px at 390px width, 364.6px at the 1216px cap.
  implication: The amplitude is real, bounded, and large. It caps at 1033.6px rather than growing
  with the monitor, so the worst case is fully characterised and reachable on any >=1440px display.

- timestamp: 2026-08-25T13:41:00Z
  checked: Same-session interleaved 2-arm differential, 4 reps each, at 1440x900. Arm A = the REAL
  hook (dispatching an actual click on `.pk-rail-btn[data-scroll="next"]`). Arm B = native
  `rail.scrollBy({left: clientWidth*0.85, behavior:'smooth'})` over the identical delta. Per-frame
  `scrollLeft` sampled every rAF and ANCHORED ON THE RESTING VALUE captured before the trigger, per
  the KB's measurement gotcha.
  found: Both arms travel exactly 1034px. ARM A clean rep (maxGap 16.7ms): first frame 341px, then
  262, 175, 113, 69, 39, 21, 9, 3, 1, 1 — 98.6% of the travel complete by frame 7 (~117ms). The
  three noisier reps split the onset across two frames (109+333, 146+320, 160+319) whose sums
  (442-479px) all EXCEED the clean rep, i.e. noise degrades in the worse direction only. ARM B clean
  rep: first frame 0px, then 2, 8, 16, 26, 44, 72, 112, 136, 117, 90, 69, 55, 45, 38, 32, 27, 23,
  20, 17, 15, 13, 12, 9, 8, 7, 6, 5, 3, 3 — a bell, peak 136px at frame 9, ~32 frames (~530ms).
  implication: The decisive comparison, and it needs no invented threshold. The platform's own
  calibrated answer to "scroll this scroller by one page" begins at EXACTLY zero velocity and peaks
  at 136px/frame. The hook's very FIRST frame is 341px — 2.5x native's PEAK — out of a standing
  start. This is an onset velocity discontinuity, not merely a fast scroll.

- timestamp: 2026-08-25T13:47:00Z
  checked: Falsification of the two non-curve explanations, closed-form at A=1033.6px.
  found: (1) DURATION-SCALING CANNOT RESCUE IT. Keeping the quintic, the first frame is 273.1px at
  280ms, 198.1px at 400ms, 135.8px at 600ms, 83.3px at 1000ms, 42.4px at 2000ms — it needs
  D = 3591ms to reach 24px. (2) A LOWER-ORDER EASE-OUT CANNOT EITHER: the cubic 1-(1-t)^3 measures
  237.5px first frame at v0 = 15,504 px/s.
  implication: Generalises the root cause beyond this one exponent. Every curve of the form
  1-(1-t)^n has v0 = nA/D > 0, so the WHOLE ease-out family starts at maximum velocity and the
  entire family is disqualified for a from-rest scroll at this amplitude — no exponent and no
  duration saves it. The requirement v0 = 0 is forced, which means an ease-in-out is the only
  admissible class. This also rules out the directive's own suggested "lower-order ease" option.

- timestamp: 2026-08-25T13:52:00Z
  checked: Candidate ease-in-outs at both amplitude extremes, plus shape analysis (time to
  20/50/80/95% and deceleration-tail share).
  found: At A=1033.6px — `--ease-standard` bezier(0.4,0,0.2,1) @200ms: first frame 17.8px, peak
  228.1px, v0=0, 12 frames, decel tail 48% of run. Symmetric smoothstep t^2(3-2t) @200ms: first
  frame 20.3px, peak 128px, v0=0, 12 frames, decel tail 28%. Current quintic: 364.6px, tail 72%.
  At A=248.2px (narrowest arrow-bearing window) the bezier gives 4.3px first frame / 54.8px peak,
  so the fix does not over-damp small scrolls.
  implication: Both candidates satisfy the forced v0=0 requirement, so the choice falls to secondary
  criteria. The bezier wins on two of three: it is the codebase's single validated large-amplitude
  curve (the sweep moved five CSS surfaces onto exactly it), and its 48% decel tail sits between the
  quintic's 72% and smoothstep's 28% — preserving most of the author's documented momentum/fling
  character while starting from rest, where symmetric smoothstep would read more mechanical.
  Smoothstep wins only on implementation simplicity (one line vs a ~14-line bezier solver).

## Resolution

verdict: DEFECT CONFIRMED AND FIXED — but only after measurement, and the measurement changed the
shape of the finding twice. The lead was raised as "same class as the CSS `--ease-out-soft` bug".
It is NOT the same class: the CSS surfaces were defective because a specific curve was
amplitude-inappropriate, and the fix was to pick a different curve from the same token set. Here
the entire ease-OUT FAMILY is inadmissible for this interaction regardless of curve or duration,
because the interaction starts from rest. The CSS thresholds (~35/51/73px) do not transfer and were
never used.

root_cause: >
  `.CarouselScroll`'s arrow-click scroller animated the rail with
  `easeOutSoft(t) = 1 - Math.pow(1 - t, 5)`, a quintic ease-OUT. An ease-out's velocity is MAXIMAL
  at t=0 (v0 = nA/D), and an arrow click starts the rail from REST — so the motion begins with a
  velocity discontinuity rather than an acceleration. At the measured amplitude cap
  (0.85 x 1216px = 1033.6px, where 1216px is `max-w-7xl` 1280 minus the 2x2rem gutter, reached on
  any display >= 1440px) that is 25,840 px/s out of a standing start, placing 35.28% of the entire
  travel into the first 16.7ms frame. MEASURED through the real hook: 341px in frame one — more than
  two 176px card pitches, and 2.5x the PEAK frame of the browser's own `scrollBy({behavior:'smooth'})`
  over the identical 1034px. 98.6% of the travel completed within 7 frames (~117ms), leaving four
  frames of sub-10px crawl below the threshold of perceived motion.

  The underlying error is a category mistake in the code's own stated intent — carousel_row.ex:66-71
  justified the curve as matching "the free-momentum touch scroll's feel". A touch fling genuinely IS
  an ease-out, but it reads as continuous ONLY because the finger already supplied the launch
  velocity: the hand is the ease-in. Transplanting that curve to a click reproduces the fling's
  second half without its first, which is exactly a discontinuity. So the curve was not carelessly
  chosen — it was chosen by a reasonable analogy that omits the user's hand.

  AND-gate: NO. Single sufficient cause, unlike `.pk-sheet`'s curve x token-drift AND. There is no
  enabling second condition: the curve is a JS literal with no token system to drift from, and the
  amplitude is not independently defective — proven by holding amplitude constant at 1033.6px and
  changing only the curve (364.6px -> 17.8px predicted, 341px -> 2px measured).

fix: >
  CURVE ONLY, duration untouched at 200ms. `lib/pukllay_club_web/components/carousel_row.ex`:
  replaced the quintic `easeOutSoft` with `easeStandard`, a closed-form cubic-bezier solver
  evaluating `cubic-bezier(0.4, 0, 0.2, 1)` — the JS twin of the project's `--ease-standard`, the
  exact curve the catalog-preview-modal-jump sweep moved five CSS surfaces onto. The single call
  site `delta * easeOutSoft(t)` became `delta * easeStandard(t)`.

  WHY THIS CURVE, derived rather than copied. The requirement v0 = 0 is FORCED, not preferred: every
  curve of the form 1-(1-t)^n has v0 = nA/D > 0, so no exponent rescues it (the cubic n=3 still
  computes 237.5px), and no duration rescues it either (the quintic needs D = 3591ms to reach a 24px
  first frame at this amplitude). Only an ease-in-out qualifies. Among ease-in-outs, this bezier was
  chosen over symmetric smoothstep because its deceleration tail is 48% of the run vs smoothstep's
  28% (the old quintic's was 72%) — it therefore preserves most of the author's documented momentum
  character while starting from rest, where smoothstep would read more mechanical. It is also the
  codebase's single validated large-amplitude curve, so the hook stops being the last outlier.

  DELIBERATELY NOT DONE, each with its reason:
  - Native `scrollBy({behavior:'smooth'})`, despite being the platform's calibrated answer and the
    reference this session measured against. MEASURED at ~530ms for the same 1034px — 2.65x the
    current duration. Adopting it would reverse sketch 023-B's explicit "snappier than native"
    decision, and would require `.pk-rail` to stop pinning `scroll-behavior: auto`, which is load-
    bearing: the hook writes `scrollLeft` every frame, and native smooth mode would start a
    competing animation per assignment. `category_anchor_scroll_test.exs` asserts that `auto`, and
    the category-menu-scroll-animation session deliberately scoped `html { scroll-behavior: smooth }`
    so it could never reach the rail. Three independent records agree; not touched.
  - Amplitude-scaled duration. Ruled out arithmetically as a STANDALONE fix (3591ms), and unnecessary
    once the curve is correct — the fixed 200ms measures well at both amplitude extremes.
  - The `prefers-reduced-motion: reduce` short-circuit — untouched and re-verified working.
  - The separate reduced-motion CSS source-order defect (session `reduced-motion-order-bug`). Out of
    scope per the brief; this hook's reduced-motion check is JS `matchMedia`, unaffected by CSS
    source order, and was verified independently.

  The rule-level comment records the amplitude arithmetic, names the category error explicitly, and
  carries the "don't restore consistency by putting an ease-OUT back, and don't try to fix a pop by
  lengthening the duration" warning — matching the pattern the CSS sweep set, because the realistic
  recurrence path here is someone reinstating an ease-out for "momentum feel".

verification:
  guardrail_verdict: accepted
  method: >
    Headless Chrome 151 over CDP. TWO browser instances differing only in emulated pointer
    capability, because the default headless instance reports `pointer: none` and would have falsely
    cleared the whole question — instance 2 launched with
    `--blink-settings=primaryHoverType=2,availableHoverTypes=2,primaryPointerType=4,availablePointerTypes=4`.
    Arms interleaved in one session; per-frame `scrollLeft` sampled every rAF and ANCHORED ON THE
    RESTING VALUE captured before the trigger, per the KB's measurement gotcha. Triggered through a
    REAL click on the rendered `.pk-rail-btn`, never by calling the easing function directly.
    HARNESS VALIDATED FIRST: the cubic-bezier evaluator had to reproduce the prior session's known
    68.6/46.7/32.7% and 35.0/51.4/73.4px figures before being trusted — it did, exactly.
  signal_reproduce_before: >
    PASS — pre-fix, the clean contiguous rep (maxGap 16.7ms) measured first frame 341px of a 1034px
    travel, against 364.6px predicted closed-form at t=16.667ms; the 341px back-solves to a 15.4ms
    click-to-rAF offset, so prediction and measurement agree. The three noisier reps split the onset
    across two frames (109+333, 146+320, 160+319) whose sums (442-479px) all EXCEED the clean rep —
    headless noise degrades in the worse direction only, never better, exactly as the KB predicts.
  signal_fixed_after: >
    PASS — post-fix first frame 2px in 3 of 4 reps and 5px in the fourth, all four contiguous
    (maxGap 16.7ms). 341px -> 2px measured. The peak moved OFF frame one to frame five (228px), and
    frames carrying motion rose 11 -> 13. Measured `2, 32, 96, 189, 228, 173, 116, 78, 53, 35, 20,
    10, 2` against the offset-matched prediction `2, 33, 97, 190, 227, 172, 116, 78, 52, 34, 20, 10,
    2` — MAX PER-FRAME DEVIATION 1px OVER 13 FRAMES, totals 1034px vs 1033px.
  signal_mechanism_understood: >
    PASS — the replacement was selected from closed-form arithmetic BEFORE the edit, and the
    post-fix per-frame sequence matched the prediction term for term. The inferred click-to-first-rAF
    offset (5.92ms) accounts for the whole apparent right-shift versus the naive 16.7ms prediction,
    with 0.00px residual, so nothing in the profile is unexplained.
  signal_falsification: >
    PASS, and it generalised the root cause rather than merely surviving. Two competing explanations
    were computed and both refuted: amplitude-scaled duration (the quintic needs 3591ms at this
    amplitude — 18x current) and a lower-order ease-out (the cubic still computes 237.5px at
    v0 = 15,504 px/s). Since v0 = nA/D > 0 for every 1-(1-t)^n, the refutation covers the entire
    ease-out family, which is what makes the fix forced rather than chosen.
  signal_differential_controls: >
    PASS — the same harness, same session, same document, alternating arms, was used before and
    after. The independent control is the platform itself: native `scrollBy({behavior:'smooth'})`
    over the identical 1034px measured first frame 0px / peak 136px / ~32 frames in every clean rep,
    so the comparison rests on a measured platform reference rather than on the inherited 24px
    threshold. Noisy reps always correlate with a measured 50-117ms rAF gap.
  signal_no_regression: >
    PASS — `mix quality` exit 0, 466 tests 0 failures, both before and after the test-message edit.
    Behaviour re-verified live in four dimensions: (1) REDUCED MOTION still short-circuits — under
    emulated `reduce` the scroll completes in a SINGLE frame of 1034px with no animation, confirming
    the short-circuit the brief required be preserved; (2) BOTH DIRECTIONS — prev mirrors next
    (total -1034px, first frame -14px, peak -226px, 12 frames); (3) RAPID CLICKS — three clicks in
    one task settle at exactly one page (1034px) with no orphaned loop still writing scrollLeft,
    so the `cancelAnimationFrame` guard survives; (4) SMALL AMPLITUDE — at the narrowest
    arrow-bearing window (320px) the 235px travel gives first frame 1px, peak 51px, 12 frames, so
    the fix does not over-damp short scrolls. Total travel is unchanged at every amplitude, so
    paging semantics are untouched.
  signal_solver_correctness: >
    PASS — the solver was extracted VERBATIM from the shipped `carousel_row.ex` (not retyped) and
    diffed against an independent reference evaluator: max deviation 2.67e-6 across [0,1], f(0)=0,
    f(1)=1, monotonic non-decreasing, NaN-free, and correctly clamped outside [0,1] (f(-0.5)=0,
    f(1.5)=1). The Newton-Raphson loop is bounded at 8 iterations with a zero-derivative guard, so
    it cannot spin inside an animation frame.
  signal_grep_for_encoded_old_value: >
    PASS, with one real hit found and fixed. No test asserts the curve or duration. But
    `category_anchor_scroll_test.exs:145` named `easeOutSoft` inside an assertion FAILURE MESSAGE —
    not an assertion, so it could never have failed, but my change is what made it stale. Updated to
    name `easeStandard` and cross-reference this session. The assertion itself (`.pk-rail` keeps
    `scroll-behavior: auto`) is untouched and still green.
  signal_built_bundle: >
    PASS — after `mix compile --force` the colocated hook is extracted into the served bundle with
    `const easeStandard = cubicBezier(0.4, 0, 0.2, 1)` and the call site
    `delta * easeStandard(t)`; `curl` of the running dev server confirms it is actually served. The
    string `easeOutSoft` and the literal `1 - Math.pow(1 - t, 5)` survive nowhere in `lib/`,
    `assets/` or the built bundle except inside the new explanatory comment.
  signal_human_verify: >
    NOT DONE — this is the one signal that cannot be self-certified, and it matters more than usual
    here because this was never a user-reported symptom. Measurement establishes MECHANISM, not
    PERCEPTUAL SUFFICIENCY (KB: search-right-align-mobile-cycle-3). Requires a click on a real
    pointer-fine display >= 1440px, where the amplitude is at its 1033.6px cap.

files_changed:
  - "lib/pukllay_club_web/components/carousel_row.ex: `.CarouselScroll` hook's easing replaced — quintic ease-out `1 - Math.pow(1 - t, 5)` -> `easeStandard`, a closed-form cubic-bezier(0.4, 0, 0.2, 1) solver (the JS twin of --ease-standard). Duration, amplitude, reduced-motion short-circuit and rAF cancellation all unchanged. Rule-level comment added recording the amplitude arithmetic, the fling-vs-click category error, and the don't-revert warning."
  - "test/pukllay_club_web/category_anchor_scroll_test.exs: assertion failure message updated to name `easeStandard` instead of the now-nonexistent `easeOutSoft`. Message text only — no assertion changed."

follow_ups_not_done:
  - "Real-device human verification (signal_human_verify above). The measured mechanism is unambiguous; the perceptual judgement is not mine to make."
  - "The rail's amplitude is `0.85 * clientWidth` with a fixed 200ms, so average scroll VELOCITY scales 4.2x across the arrow-bearing viewport range (248px travel at 320px wide, 1034px at >=1440px). This is NOT the reported defect and is not fixed — after the curve fix both extremes measure well (first frame 1px and 2px). Recorded only because if a future report says 'too fast on a big monitor', an amplitude-scaled duration is the lever, and it should be reached for deliberately rather than by reintroducing a front-loaded curve."
  - "Untouched, and confirmed still open: the `prefers-reduced-motion: reduce` CSS source-order defect (session `reduced-motion-order-bug`). Unrelated to this hook, whose reduced-motion branch is JS `matchMedia` and was verified working."
