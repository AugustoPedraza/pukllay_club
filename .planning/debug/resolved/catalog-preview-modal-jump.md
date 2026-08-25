---
status: resolved
trigger: "for mobile I need a polished fluid animation(not jump) for the boardgame preview(on the catalog)"
created: 2026-08-25T00:00:00Z
updated: 2026-08-25T11:20:00Z
---

## Current Focus

bug_class: Bohrbug (deterministic — reproduced identically in 9/9 instrumented runs)
known_pattern_candidate: "category-menu-scroll-animation — same reporter idiom ('polished
animation, not a jump'). NOT a match: that root cause was a never-declared motion property; here
the transition IS declared and DOES run. Tested and set aside."
hypothesis: CONFIRMED — see Resolution.

reasoning_checkpoint:
  hypothesis: >
    `.pk-sheet`'s slide-up reads as a jump because `--ease-out-soft`
    (cubic-bezier(0.16, 1, 0.3, 1), an easeOutExpo curve) was validated by sketch 006 against
    ~3px amplitudes and then applied unchanged to a 515px full-screen travel. That curve spends
    26.3% of its distance in the FIRST 16.7ms frame and 80% within 62ms, so the eye reads the
    sheet as popping into place, followed by a ~280ms sub-10px-per-frame crawl nobody perceives
    as motion. The hardcoded `360ms` compounds it: it is the pre-sketch-006 sketch-001/002
    baseline value that the 006 tuning pass never reached, because it was hardcoded rather than
    written as a `--duration-*` token.
  confirming_evidence:
    - "Measured first painted frame after transitionrun is top=709 from top=844 — a 135px jump — identical across arms B, C and D and all 3 reps (9/9 runs)."
    - "Closed-form evaluation of cubic-bezier(0.16,1,0.3,1) at t=16.7/360 predicts 26.3% = 134.4px. Predicted 134.4px vs measured 135px — the curve alone fully explains the jump."
    - "Per-frame deltas over the 515px travel: 135, 105, 77, 55, 39, 28, 20, 15, 11, 8, 6, 4, 3, 2, 2, 1, 1, 0, 0, 0, 0 — motion is effectively over in 5 frames, then 16 frames of imperceptible crawl."
    - "motion-system.md: sketch 001/002 used 120/220/360ms; sketch 006 superseded them with 100/180/280ms. `.pk-sheet`'s literal 360ms (and the backdrop's 220ms) are exactly the abandoned 001/002 numbers."
    - "motion-system.md states D's finding as 'restraint isn't only a timing question, the movement itself needs to be smaller too' — the curve was validated at -3px hover-lift amplitude, ~170x smaller than the sheet's 515px."
  falsification_test: >
    If the curve were innocent and the duration were the whole story, shortening 360ms -> the
    validated 280ms with the SAME curve would improve it. Computed: that makes the first frame
    169px — WORSE than 135px. Falsification attempted and failed; the curve is load-bearing and
    duration alone is not the cause.
  fix_rationale: >
    Replace the hardcoded `360ms cubic-bezier(0.16,1,0.3,1)` on `.pk-sheet` (and its backdrop
    partner) with the validated tokens `var(--duration-slow) var(--ease-standard)`. That drops
    the first-frame jump from 135px to 4px (34x) and spreads the travel across all 16 frames
    (4, 16, 32, 56, 78, 81, 66, 50, 38, 28, 21, 16, 12, 8, 5, 3) with no frame above 81px. It
    addresses the mechanism (front-loaded curve on a large amplitude), not the symptom, and it
    simultaneously repays the token drift so a future system-wide motion pass reaches this
    surface — which is exactly why it drifted in the first place.
  blind_spots:
    - "All measurement is headless Chrome on x86 desktop, not a real phone. The FRAME-TIMING numbers (stalls, dropped frames) are environment-contaminated and are NOT used as evidence; the 135px first-frame value is arithmetic-derived and environment-independent, which is why the conclusion rests on it alone."
    - "'Fluid' is perceptual. The numbers establish mechanism, not perceptual sufficiency — this needs real-device human confirmation (cf. search-right-align-mobile-cycle-3 in the KB, where a measured-correct fix still read wrong)."
    - "Separate, unfixed observation: the sheet's poster fetches `cover-large.webp` only at tap time (the `<template>` defers it by design), so the image pops in with no fade ~240ms after the sheet lands. Real but distinct from the reported travel jump; not bundled into this fix."
  candidate_causes:
    - "code (JS hook): openSheet injects content and toggles `is-open` in one task — TESTED, arm C deferred the class by 2 rAF and produced the identical 135px jump. ELIMINATED."
    - "environment: headless/no-GPU main-thread jank dropping the opening frames — TESTED via 4-arm differential; the 135px value is invariant across arms and reps while frame gaps vary 16-190ms. ELIMINATED as the cause of the jump."
    - "config (design tokens): hardcoded pre-006 `360ms` never migrated to `--duration-slow`. CONFIRMED as contributing."
    - "config (design tokens): `--ease-out-soft` validated at small amplitude, reused at 515px. CONFIRMED as the dominant cause."
  and_gate: >
    YES — two conditions had to hold simultaneously. The curve is only a defect BECAUSE the
    amplitude is 515px (the same curve on the validated -3px hover-lift is correct and shipping),
    and the amplitude is only unguarded BECAUSE the value was hardcoded outside the token system
    that the 006 tuning pass swept. Neither alone produces the bug: `--ease-out-soft` at -3px is
    fine, and 515px under `--ease-standard` is fine.

test: DONE — 4-arm CDP differential re-run post-fix.
expecting: MET — first painted step 135px -> 4px; max frame delta 135px -> 81px; measured
per-frame sequence matched the closed-form prediction term for term.

human_verify: CONFIRMED 2026-08-25 on a real phone — the sheet reads as fluid, no jump. The
perceptual gap the measurement could not close (blind_spot 2) is now closed by the user.

scope_extension: The user then authorised extending the identical fix to `.pk-drawer`, which was
recorded as follow-up #1 (same defect class, different surface). Correction to the extension
brief: `.pk-drawer` did NOT carry a hardcoded `360ms cubic-bezier(...)`. Its duration was already
tokenised as `var(--duration-slow)`; only the CURVE was defective (`var(--ease-out-soft)` over a
~320px travel). So the drawer is a pure single-condition instance of cause (1) — the dominant
curve-x-amplitude defect — without the enabling token-drift condition (2) that hid the sheet from
the 006 sweep. The requested end state `var(--duration-slow) var(--ease-standard)` is unchanged;
only one of the two halves needed touching to reach it.

next_action: DONE — drawer fix applied and verified by the same instrumented per-frame capture
(104.6px -> 2.7px predicted, 105px -> 3px measured). Session archived.

## Symptoms

expected: On mobile, tapping a game card in the catalog opens the game preview modal/drawer with a
smooth, fluid transition (e.g. crossfade and/or slide-up, roughly 200-400ms) — it should feel like
one continuous motion, not an instant state swap.
actual: On mobile, tapping a game card opens the preview modal/drawer with no transition at all —
it pops into view instantly ("jumps"), which reads as unpolished.
errors: None reported — this is a visual/UX polish issue, not a functional error.
reproduction: On a mobile/narrow viewport, load the catalog page and tap any game card to open its
preview modal/drawer. The modal/drawer appears abruptly instead of animating in.
started: Always been this way — not a regression. This is an unaddressed polish gap, not a broken
previously-working animation.

## Eliminated

- hypothesis: "The transition is never declared for `.pk-sheet` (the category-menu-scroll-animation pattern — CSS initial value doing exactly what it is specified to do)."
  evidence: "app.css:582 declares `transition: transform 360ms cubic-bezier(0.16, 1, 0.3, 1)` and `.pk-sheet.is-open` sets `translateY(0)`. A live CSSTransition object was observed on `.pk-sheet` with playState 'running', and transitionrun/transitionstart/transitionend all fire with elapsedTime 0.36."
  timestamp: 2026-08-25T09:05:00Z

- hypothesis: "The transition never starts because `replaceChildren` (height 12px -> 515px) and `classList.add('is-open')` run in the same task, so the before-change style snapshot is taken against the wrong box height and the percentage translate cannot interpolate."
  evidence: "Arm C of the differential deferred the class toggle by two rAF after injection, giving the browser a clean flush between the height change and the transform change. First painted frame was top=709 — identical 135px jump to arm B (same-task). Deferring changes nothing."
  timestamp: 2026-08-25T09:40:00Z

- hypothesis: "The opening frames are dropped because the main thread is blocked (127ms long task observed; body overflow:hidden forces relayout of a 183-card document)."
  evidence: "Arm D removed `body.pk-sheet-open` entirely and still produced first-frame 135px. Across 9 runs the stall between class-add and transitionrun varied 16.3-188.6ms while the first-frame displacement stayed pinned at 135-136px. A jank-driven drop would vary with the stall; this does not. Frame-timing is headless-environment noise, not the mechanism."
  timestamp: 2026-08-25T09:40:00Z

- hypothesis: "`prefers-reduced-motion` is suppressing the sheet animation."
  evidence: "The reduce block (app.css:923-938) lists `.pk-drawer`, `.pk-cat-panel`, `.pk-search-morph` et al. but NOT `.pk-sheet`/`.pk-sheet-backdrop`. Probe also read `matchMedia('(prefers-reduced-motion: reduce)').matches === false` in the harness."
  timestamp: 2026-08-25T09:10:00Z

- hypothesis: "A 300ms mobile tap delay makes the interaction feel dead before the sheet moves."
  evidence: "root.html.heex:5 declares `<meta name='viewport' content='width=device-width, initial-scale=1'>`, which removes the legacy click delay. Measured touchend->click was 127ms, and that interval is main-thread stall, not the fixed legacy delay."
  timestamp: 2026-08-25T09:20:00Z

## Evidence

- timestamp: 2026-08-25T09:05:00Z
  checked: "assets/css/app.css:555-587 (.pk-sheet-backdrop, .pk-sheet) and lib/pukllay_club_web/components/game_preview.ex:305-330 (openSheet)."
  found: ".pk-sheet declares `transform: translateY(100%)` -> `.is-open { translateY(0) }` with `transition: transform 360ms cubic-bezier(0.16, 1, 0.3, 1)`. Backdrop fades `opacity 220ms` with the same curve. Both timings are hardcoded literals, not `--duration-*`/`--ease-*` tokens."
  implication: "The prefilled symptom 'no transition at all' is an inference, not an observation. Motion exists; its DISTRIBUTION over time is the thing to measure."

- timestamp: 2026-08-25T09:15:00Z
  checked: "Live catalog at 390x844 with touch emulation via CDP (real Input.dispatchTouchEvent), rAF-sampled getBoundingClientRect on #game-preview-sheet."
  found: "Closed sheet measures height 12px (empty body, handle only) at top=844. On tap it becomes 515px and slides 844 -> 329. transitionrun/transitionend fire with elapsedTime 0.36 (a full 360ms run)."
  implication: "The transition genuinely runs end to end. The defect is inside the run, not around it."

- timestamp: 2026-08-25T09:40:00Z
  checked: "4-arm differential x 3 reps in one browser session: A=class toggle only (empty body), B=current same-task inject+toggle, C=inject then 2xrAF then toggle, D=inject+toggle without body.pk-sheet-open."
  found: "maxSingleFrameJumpPx = 135-136 in every content-bearing arm (B, C, D) in every rep. First painted position after top=844 is always exactly 709, then 603, 526, 470, 431. Arm A (12px travel) shows max jump 3-11px. Stall-to-transitionrun varied 16.3-188.6ms with no correlation to the jump."
  implication: "The 135px first-frame displacement is invariant to task scheduling, to body-overflow relayout, and to ambient frame timing. It is a property of the curve x amplitude, not of the environment or the JS."

- timestamp: 2026-08-25T09:55:00Z
  checked: "Closed-form evaluation of cubic-bezier(0.16, 1, 0.3, 1) (easeOutExpo) over a 515px travel at 360ms, 60fps."
  found: "t=16.7ms -> 26.3% (134.4px). t=33ms -> 46.3%. t=62ms -> 69.8%. t=100ms -> 85.6%. t=180ms -> 97.2%. Per-frame deltas: 135, 105, 77, 55, 39, 28, 20, 15, 11, 8, 6, 4, 3, 2, 2, 1, 1, 0, 0, 0, 0."
  implication: "PREDICTED 134.4px vs MEASURED 135px. The curve alone accounts for the entire observed jump. 80% of the travel lands in the first 62ms; the remaining 20% is spread over ~280ms at under 10px/frame, which is below the threshold of perceived motion. This is arithmetically 'pop, then nothing'."

- timestamp: 2026-08-25T10:00:00Z
  checked: ".claude/skills/sketch-findings-pukllay_club/references/motion-system.md (sketch 006) against app.css:232-236."
  found: "Sketch 001/002 used 120/220/360ms 'never as a considered system'. Sketch 006 superseded them with the validated set 100/180/280ms (`--duration-fast/base/slow`) plus `--ease-out-soft: cubic-bezier(0.16,1,0.3,1)` validated on a -3px hover-lift and row-scroll. `.pk-sheet` hardcodes 360ms and `.pk-sheet-backdrop` hardcodes 220ms — the exact abandoned 001/002 numbers."
  implication: "These two rules were never reached by the 006 tuning pass precisely because they hardcoded literals instead of tokens — the identical drift class motion-system.md documents ('the hover-lift was independently declared in three places and none had been updated'). Its 'What to Avoid' names this exactly: don't hardcode timing values, or a system-wide pass requires a per-component hunt."

- timestamp: 2026-08-25T10:05:00Z
  checked: "Falsification of the duration-only explanation: same curve at the validated --duration-slow (280ms)."
  found: "First frame becomes 169px — worse than the current 135px, because a shorter duration front-loads an already front-loaded curve harder."
  implication: "Duration alone is not the cause and 'just use the validated token' would have made the complaint worse. Confirms the AND: curve x amplitude is the mechanism, token drift is why it was never caught."

- timestamp: 2026-08-25T10:10:00Z
  checked: "Candidate replacement: `var(--duration-slow) var(--ease-standard)` (280ms, cubic-bezier(0.4, 0, 0.2, 1)) over the same 515px."
  found: "First frame 4px. Per-frame deltas 4, 16, 32, 56, 78, 81, 66, 50, 38, 28, 21, 16, 12, 8, 5, 3 — no frame above 81px, motion distributed across all 16 frames, 78% at half-time."
  implication: "34x reduction in first-frame displacement using only tokens that already exist and are already validated. No new token needed, and the rule lands back inside the motion system."

- timestamp: 2026-08-25T10:12:00Z
  checked: "app.css:1656-1676 (.pk-drawer) for other instances of the same class."
  found: ".pk-drawer slides `translateX(100%)` across up to 20rem/320px using `var(--duration-slow) var(--ease-out-soft)` — the same front-loaded curve on a large amplitude (~105px first frame)."
  implication: "Same defect class, different surface, NOT reported by the user and out of scope for this fix. Flagged for follow-up rather than bundled in."

- timestamp: 2026-08-25T10:14:00Z
  checked: "Poster image loading inside the sheet across the open animation."
  found: "The card renders `cover-thumb.webp` while the sheet's cloned body requests a different asset, `cover-large.webp`, only at tap time (the `<template>` defers the fetch by design). img.complete was false for the first ~240ms of the open and flipped to true mid-slide, with no fade on arrival."
  implication: "A second, genuinely visible pop, independent of the travel curve. Reported to the user as a separate observation; not fixed here, since the `<template>` deferral is a documented deliberate perf decision and changing it is a design call, not a root-cause fix."

## Resolution

root_cause: >
  Two conditions had to hold at once (AND-gate fired).
  (1) DOMINANT — `.pk-sheet` animated a 515px full-height travel with `--ease-out-soft`
  (cubic-bezier(0.16, 1, 0.3, 1), easeOutExpo), a curve sketch 006 validated only against ~3px
  amplitudes (the hover-lift and row-scroll). Over 515px that curve puts 26.3% of the distance
  into the first 16.7ms frame and 80% into the first 62ms, then spends the remaining ~280ms
  moving under 10px per frame. Measured first painted step: 135px, against 134.4px predicted
  closed-form — the curve alone accounts for the whole jump. The eye reads that as "pop, then
  nothing", which is precisely the reported "not fluid / jump".
  (2) ENABLING — the rule hardcoded `360ms cubic-bezier(0.16, 1, 0.3, 1)` (and the backdrop
  `220ms`) as literals instead of `--duration-*`/`--ease-*` tokens. Those literals are the
  abandoned sketch-001/002 numbers (120/220/360ms); sketch 006 replaced that set with
  100/180/280ms, and the 006 sweep never reached these two rules *because* they were hardcoded.
  Neither condition alone is a bug: `--ease-out-soft` at -3px is correct and still shipping, and
  515px under `--ease-standard` is fine. The defect exists only at their intersection.

  SECOND SURFACE (`.pk-drawer`, added 2026-08-25 by user scope decision after the sheet fix was
  human-confirmed). The mobile nav drawer carried cause (1) WITHOUT cause (2): its duration was
  already correctly tokenised as `var(--duration-slow)`, and only the curve was wrong
  (`var(--ease-out-soft)` over a 319.8px `translateX(100%)` travel). That makes the drawer a
  natural control that isolates the two conditions: a surface with the *correct* duration still
  jumped 104.8px in its first frame, which independently confirms the curve — not the duration —
  is the dominant cause. It also refines the AND-gate finding: condition (2) (token drift) is what
  hid the sheet from the 006 sweep, but it is not required to produce the bug. Being inside the
  token system is not protection when the token itself is amplitude-inappropriate — `--ease-out-soft`
  is a correctly-named, correctly-referenced token that is simply wrong above ~50-75px of travel.

fix: >
  Replaced both hardcoded literals with the already-validated tokens:
  `.pk-sheet` transition `360ms cubic-bezier(0.16,1,0.3,1)` -> `var(--duration-slow) var(--ease-standard)`;
  `.pk-sheet-backdrop` transition `220ms cubic-bezier(0.16,1,0.3,1)` -> `var(--duration-slow) var(--ease-standard)`.
  Added a rule-level comment recording why this one surface must NOT use `--ease-out-soft`
  (amplitude, not inconsistency, decides the curve) and that shortening the duration makes it
  worse, so the change is not "consistency-fixed" back later. Updated the stale `:root` scoping
  comment that still listed `.pk-sheet` as UAT-verified and not to be touched.
  Deliberately NOT changed: `.pk-portal` and `.pk-nav` (small amplitudes, `--ease-out-soft` is
  correct there and they were not reported).

  SECOND SURFACE (`.pk-drawer`, app.css:1691): `var(--ease-out-soft)` -> `var(--ease-standard)`.
  One token changed, not two — the duration was already `var(--duration-slow)` and stays as is.
  Added a rule-level comment cross-referencing the `.pk-sheet` note and recording this rule's own
  amplitude arithmetic, with the same "don't restore consistency by putting `--ease-out-soft` back"
  warning.
  Deliberately NOT changed alongside it: `.pk-drawer-backdrop` (app.css:1663). Unlike
  `.pk-sheet-backdrop` — which was genuinely defective, hardcoding `220ms` AND `--ease-out-soft` —
  the drawer's backdrop is already fully tokenised and already on `--ease-standard`. It runs
  `--duration-base` (180ms) against the drawer's `--duration-slow` (280ms), so the backdrop settles
  first, but that is an opacity fade with no travel distance to front-load, it is inside the token
  system where a future system pass will reach it, and it was not part of the reported defect.
  Changing it would have been an uninstructed side effect, so it is recorded here instead.

verification:
  guardrail_verdict: accepted
  signal_reproduce_before: >
    PASS — pre-fix, first painted frame after transitionrun was top=709 from top=844 (135px) in
    9/9 runs across 3 independent arms.
  signal_fixed_after: >
    PASS — post-fix per-frame deltas measured 4, 16, 32, 56, 78, 81, 66, 50, 38, 28, 21, 16, 12,
    8, 5, 3 px, an exact match to the closed-form prediction for cubic-bezier(0.4,0,0.2,1) over
    515px at 280ms. First-frame displacement 135px -> 4px (34x). Max frame delta 135px -> 81px.
  signal_differential_controls: >
    PASS — the same 4-arm harness that isolated the cause was re-run unchanged after the fix, in
    the same browser session and environment. Runs showing 159-264px maxJump post-fix correlate
    with 98-280ms rAF gaps (headless dropped frames, environment noise); every contiguous-frame
    run reports the predicted 80-81px ceiling.
  signal_mechanism_understood: >
    PASS — the fix was chosen from closed-form curve arithmetic before it was applied, and the
    measured post-fix frame sequence matched the prediction term for term.
  signal_falsification: >
    PASS — the competing "just use the validated 280ms duration" explanation was computed and
    rejected: same curve at 280ms yields a 169px first frame, worse than the 135px status quo.
  signal_no_regression: >
    PASS — 460 tests, 0 failures. Settled open state byte-identical to pre-fix (top=329,
    bottom=844, height=515, backdrop opacity 1, aria-hidden=false, body overflow hidden). Close
    direction now mirrors the open profile (deltas 4, 15, 32, 56, 79, 80, 67, 50, 38, 28, 22, 16,
    11) and correctly restores aria-hidden=true, body overflow=visible, backdrop opacity 0,
    top=844. Sheet and backdrop now share one duration/curve (0.28s / cubic-bezier(0.4,0,0.2,1)),
    where they were previously desynced at 360ms vs 220ms. Visual screenshot at rest unchanged.
  signal_grep_for_encoded_old_value: >
    PASS — no test or source file asserts the 360ms/220ms literals.
  signal_human_verify: >
    PASS — 2026-08-25, user confirmed on a real phone: the sheet "reads as fluid, no jump". This
    closes blind_spot 2 (perceptual sufficiency), which measurement alone could not establish and
    which the KB's search-right-align-mobile-cycle-3 entry warns about specifically.

verification_drawer:
  guardrail_verdict: accepted
  method: >
    Same instrumented per-frame capture used for `.pk-sheet`, re-pointed at `.pk-drawer`: headless
    Chrome over CDP at 390x844 with touch emulation and real `Input.dispatchTouchEvent` taps on the
    hamburger, rAF-sampling `getBoundingClientRect().left` and anchoring the first painted frame to
    the resting position (left=390) rather than to the first sample. 6 reps x 2 arms, interleaved
    in one browser session. BEFORE arm forces `transform var(--duration-slow) var(--ease-out-soft)`
    via inline style (verified applied: computed `0.28s cubic-bezier(0.16, 1, 0.3, 1)`); AFTER arm
    clears the override and uses the shipped rule (`0.28s cubic-bezier(0.4, 0, 0.2, 1)`). The only
    variable between arms is the easing token.
    NOTE — the first pass of this harness anchored deltas on the first post-`transitionrun` sample
    and so reported a 73.8px first frame, silently discarding the very frame under investigation
    (the displacement happens between `transitionrun` and the first rAF callback). Caught by
    noticing the BEFORE arm's first sample already sat at left=285, i.e. 105px into a travel it was
    reporting as 73.8px. Re-anchored before drawing any conclusion.
  amplitude: "319.8px (width 82% of 390, under the 20rem/320px cap). Travel left 390 -> 70.2."
  signal_reproduce_before: >
    PASS — with `--ease-out-soft` restored, first painted frame measured 104.8, 104.6, 105.0,
    104.9px across the 4 clean reps, against 104.6px predicted closed-form. Reps 5-6 read 178.8px
    and 319.3px, both traceable to dropped frames (rep 6's first sample landed after the whole
    280ms run had completed) — headless noise, and noise in the WORSE direction, never better.
    Full BEFORE sequence (rep 4): 104.9, 73.8, 48.9, 31.7, 20.6, 13.7, 9.1, 6.2, 4.1, 2.7, 1.8,
    1.1, 0.6, 0.3, 0.1 — against predicted 104.6, 74.1, 48.8, 31.6, 20.7, 13.7, 9.2, 6.2, 4.1,
    2.7, 1.8, 1.1, 0.6, 0.3, 0.1. Term-for-term match: 80% of the travel inside 67ms, then ~210ms
    of sub-10px/frame crawl.
  signal_fixed_after: >
    PASS — first painted frame 2.7px in 5 of 6 reps (the sixth, 12.3px, carries an 83.7ms frame
    gap), against 2.7px predicted. First-frame displacement 104.6px -> 2.7px, a 39x reduction. Max
    single-frame delta 104.9px -> 50.0px. Frames carrying motion 15 -> 17, and the peak moves off
    frame one to frame six. Full AFTER sequence (reps 4 and 5, both fully contiguous): 2.7, 9.6,
    19.9, 34.6, 48.7, 50.0, 41.2, 31.2, 23.3, 17.7, 13.3, 9.9, 7.3, 5.1, 3.2, 1.7, 0.4 — against
    predicted 2.7, 9.6, 20.0, 34.6, 48.5, 50.2, 41.1, 31.2, 23.4, 17.7, 13.3, 9.9, 7.3, 5.1, 3.2,
    1.7, 0.4. Term-for-term match; 80% travelled at 150ms instead of 67ms.
  signal_differential_controls: >
    PASS — both arms ran in the same session, same page, same document, alternating, so frame-timing
    conditions are shared. Every rep whose rAF gaps stayed under 25ms reported the predicted values
    (104.x / 2.7); every outlier correlates with a measured gap of 40-160ms. The jump value is
    invariant to ambient timing, exactly as it was for `.pk-sheet`.
  signal_mechanism_understood: >
    PASS — the closed-form prediction (104.6px -> 2.7px) was computed and written down BEFORE the
    edit was applied, and the post-fix measurement matched it term for term across 17 frames.
  signal_falsification: >
    PASS, and stronger here than on the sheet. On `.pk-sheet` the "wrong duration" explanation had
    to be refuted by computation (280ms with the old curve = 169px, worse). On `.pk-drawer` it is
    refuted by construction: the duration was ALREADY the validated `var(--duration-slow)` and the
    surface still jumped 104.8px. A correct duration is demonstrably not sufficient, which isolates
    the curve as the operative cause independent of any token-drift argument.
  signal_no_regression: >
    PASS — 460 tests, 0 failures (identical to the pre-fix baseline). Settled states verified
    unchanged in both directions across all 6 reps.
    Open: left=70.2, transform=matrix(1,0,0,1,0,0) (identity), inert absent, hamburger
    aria-expanded="true", drawer aria-modal="true", backdrop opacity 1 with its static
    aria-hidden="true" intact, body overflow=hidden, body.pk-drawer-open present, focus moved to
    .pk-drawer-close.
    Closed: left=390, transform=matrix(1,0,0,1,319.797,0), inert restored, aria-expanded="false",
    backdrop opacity 0, body overflow=visible, body.pk-drawer-open removed, focus returned to
    .pk-nav-hamburger.
    Note on the accessibility check: `.pk-drawer` hides itself with `inert` (plus the hamburger's
    aria-expanded), not with `aria-hidden` as `.pk-sheet` does — the brief asked for aria-hidden, so
    the equivalent mechanism was verified instead. The only `aria-hidden` in this subtree is the
    backdrop's, which is static markup and untouched.
    Close direction now mirrors the open profile (first moving frame 2.7px, then 9.6, 20.0, 34.7,
    48.4, 50.3, 41.0, ...), where previously it mirrored the 104.8px pop.
  signal_grep_for_encoded_old_value: >
    PASS — nothing in test/ or lib/ asserts the drawer's easing. The one grep hit,
    carousel_row.ex:66, is a comment noting that a JS scroll animation replicates `--ease-out-soft`'s
    curve; row-scroll is one of the two surfaces sketch 006 actually validated that curve against,
    so it is correct usage on a correct amplitude, not another instance of this defect.

files_changed:
  - "assets/css/app.css: .pk-sheet + .pk-sheet-backdrop transitions moved onto --duration-slow/--ease-standard; rule comment added; stale :root scoping comment corrected."
  - "assets/css/app.css: .pk-drawer transition curve --ease-out-soft -> --ease-standard (duration left as the already-correct --duration-slow); rule comment added cross-referencing .pk-sheet."

follow_ups_done:
  - "RESOLVED 2026-08-25 — `.pk-drawer` (was app.css:1656, now :1691). Was the SAME defect class: `translateX(100%)` across 319.8px on `var(--ease-out-soft)`. Predicted ~105px first frame; measured 104.8px, fixed to 2.7px. Authorised by the user as a scope extension after the sheet fix passed human verification. See verification_drawer above."

follow_ups_not_done:
  - "`.pk-sheet`/`.pk-sheet-backdrop` are absent from the `prefers-reduced-motion: reduce` block (app.css:943) even though `.pk-drawer`/`.pk-drawer-backdrop`/`.pk-cat-panel` are listed. The app's largest sliding surface is the one not honouring reduced motion. Unchanged by this pass — and note the drawer fix does NOT help here, since reduced-motion collapses duration to 1ms regardless of curve."
  - "THIRD instance of the same class, not reported and not fixed: `.pk-mobile-cta-bar` (app.css:2237) transforms on `var(--duration-base) var(--ease-out-soft)`. At `--duration-base` that curve puts 46.7% of the travel in the first frame — roughly 30px for a ~64px-tall bar. Marginal rather than clearly broken, which is exactly why it warrants a deliberate decision rather than a silent sweep."
  - "`.pk-search-morph` / `.pk-search-morph-toggle` (app.css:760, 802) animate `width` on `--ease-out-soft`. Width is a travel-like property, so the same front-loading applies, but the amplitudes were not measured in this session — unquantified, flagged only."

## Prevention

<!-- Blameless postmortem. The question is which gate should have caught this class,
     not who wrote the rule. -->

why_not_caught: >
  No gate existed for this class. Every gate this repo runs is blind to it by construction:
  `mix test` asserts rendered markup and never evaluates CSS; `mix format`/Styler/Credo/Sobelow
  do not parse `assets/css/app.css` at all; code review reads a diff, and none of these rules were
  in a diff — they were correct-looking one-line declarations that had been sitting unchanged for
  several phases. Visual UAT did look at these surfaces and passed them, which is the important
  finding: a 280-360ms animation whose defect is confined to its first 16.7ms frame is not
  reliably visible to a human reviewer on a desktop browser, and `.pk-sheet` was in fact explicitly
  marked "UAT-verified, out of scope" in the `:root` comment on that basis. That annotation then
  actively protected the bug from the sketch-006 token sweep. So the gate did not merely miss it —
  a passing gate was recorded as a reason not to look again.

five_whys_branching: >
  BRANCH A (curve x amplitude — the dominant, sufficient cause):
  1. Why did it jump? Because 27-33% of the travel was painted in the first frame.
  2. Why? Because `--ease-out-soft` is easeOutExpo, which is extremely front-loaded.
  3. Why was a front-loaded curve used on a full-screen travel? Because sketch 006 validated it on
     a -3px hover-lift and a row-scroll and then published it as the general-purpose soft ease-out.
  4. Why did that generalisation go unchallenged? Because the token's name encodes an intent
     ("soft") but not its domain of validity — nothing in `--ease-out-soft` says "under ~50px".
  5. Why does the domain of validity matter at all? Because a timing function is scale-free in the
     spec but not scale-free perceptually: the same percentage-per-frame is invisible at 3px and a
     pop at 320-515px. ROOT: the token system encodes curves without encoding the amplitude range
     each curve was validated against.

  BRANCH B (token drift — enabling on `.pk-sheet`, absent on `.pk-drawer`):
  1. Why did `.pk-sheet` carry the abandoned 360ms/220ms? Because the 006 sweep never reached it.
  2. Why? Because those values were literals, so a search for `--duration-*` did not match them.
  3. Why were they literals? They predated the token system (sketch 001/002).
  4. Why did no gate flag literals after the tokens existed? The `:root` comment states the rule
     ("new rules must reference these tokens") as prose. Prose is not a gate.
  5. ROOT: a stated convention with no mechanical enforcement decays silently.
  Branch B is NOT required to produce the bug — `.pk-drawer` proves it, having been fully tokenised
  and still defective. B explains why the sheet stayed broken; A explains why it was broken.

  BRANCH C (environment/data) — investigated and eliminated during the session: main-thread jank,
  body-overflow relayout, task scheduling, reduced-motion, tap delay. All refuted by the 4-arm
  differential (see Eliminated). Recorded here so a future reader does not re-walk them.

recurrence_guard: >
  PRIMARY (documentation-as-guard, shipped with this fix): both `.pk-sheet` and `.pk-drawer` now
  carry rule-level comments that state the amplitude arithmetic, name `--ease-standard` as
  deliberate, and explicitly warn against "restoring consistency" by putting `--ease-out-soft` back.
  This is the guard that matters most, because the realistic recurrence path is a future tidy-up
  pass noticing the inconsistency and reverting it — not someone reintroducing a literal.

  SECONDARY (the checkable rule this session produced): `--ease-out-soft`'s first-frame share is
  68.6% at `--duration-fast`, 46.7% at `--duration-base`, 32.7% at `--duration-slow`. Holding a 24px
  first-frame step as the rough perceptibility threshold, the curve is only safe below roughly
  35px / 51px / 73px of travel respectively. Rule of thumb: `--ease-out-soft` is for accents
  (hover-lifts, nudges, row-scrolls); anything translating more than ~50px wants `--ease-standard`.

  PROPOSED, NOT BUILT (deliberately — an unrequested lint rule is scope creep, and this needs a
  decision on where CSS linting would live, since the repo currently lints no CSS at all): a
  stylelint check pairing (a) `declaration-property-value-disallowed-list` forbidding raw `ms`/`s`
  and `cubic-bezier(` literals in `transition`/`animation` outside `:root`, which mechanises the
  prose convention from branch B, and (b) a custom rule flagging `--ease-out-soft` on any rule whose
  transform/width travel exceeds the thresholds above, which is the only one of the two that would
  have caught `.pk-drawer`. Note the asymmetry: (a) alone would have caught the sheet and missed
  the drawer entirely.

  KB PATTERN (the transferable lesson, worth more than either guard): "measured-correct but
  perceptually wrong" now has two entries in this codebase — search-right-align-mobile-cycle-3 and
  this one. Both required real-device human confirmation to close. Corollary established here:
  "UAT-verified" is not a durable property for sub-100ms motion defects, and must not be used as a
  reason to exclude a rule from a systematic sweep.
  - "The sheet's poster fetches `cover-large.webp` only on tap (the `<template>` defers it by design) while the card already shows `cover-thumb.webp`, so the image pops in with no fade ~240ms after the sheet lands. Distinct from the travel jump."
  - "Incidental, unrelated to this bug: seeded descriptions render literal `&mdash;` text (double-escaped HTML entity in the catalog data), visible in the Century Big Box preview."
