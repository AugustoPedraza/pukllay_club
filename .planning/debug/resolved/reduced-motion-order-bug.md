---
status: resolved
trigger: "Follow-up from resolved session catalog-preview-modal-jump (commit 78642fa): the sweep's own instrumentation found that the `@media (prefers-reduced-motion: reduce)` block in assets/css/app.css (starts ~line 923) is silently inert for 8 of its 14 covered selectors. User instruction: 'Fix both using gsd-debug' (this + the carousel scroll-easing amplitude issue, filed separately as carousel-scroll-easing-jump)."
created: 2026-08-25T12:00:00Z
updated: 2026-08-25T13:10:00Z
---

## Current Focus

hypothesis: CONFIRMED INDEPENDENTLY (was carried forward, now re-verified from scratch in this
session by both static cascade analysis and live browser computed styles). Media queries add no
specificity; every rule in app.css is UNLAYERED (no `@layer` anywhere in the file), so all 14
selectors and the guard block sit in the same cascade layer where plain source order decides. The
guard block at line 967 declares `transition-duration: 1ms`; the 8 selectors whose own `transition:`
SHORTHAND is declared later in the file re-expand `transition-duration` back to full, because a
shorthand resets every longhand it owns.
test: (1) brace-matching, comment-stripped parse of app.css locating every target selector's rule
line vs the guard block's line 967; (2) headless Chrome `--force-prefers-reduced-motion` reading
`getComputedStyle().transitionDuration` on all 14 selectors against the BUILT bundle.
expecting: exactly the 6 selectors declared before line 967 report 1ms; the 8 declared after report
their full 180-280ms — with no exception attributable to specificity, `!important`, longhands, a
second reduce block, or layers.
next_action: NONE — session closed. Fix applied, self-verified, and CONFIRMED BY THE USER on
2026-08-25 (both arms: reduced motion ON snaps instantly, reduced motion OFF still plays normal
motion — nothing over-suppressed). The user additionally ratified the BLANKET accommodation as the
intended shipping scope, so no per-surface follow-up exists. Session archived to
.planning/debug/resolved/ and recorded in knowledge-base.md.

reasoning_checkpoint:
  hypothesis: "The `@media (prefers-reduced-motion: reduce)` block's `transition-duration: 1ms` is
    overridden for 8 of its 14 selectors because each of those selectors declares a `transition:`
    shorthand LATER in the same unlayered cascade layer, and a shorthand resets the
    `transition-duration` longhand. The media query contributes zero specificity, so source order
    alone decides the winner."
  confirming_evidence:
    - "Direct parse: the 6 REDUCED selectors' own rules are at lines 561/576/754/807/849/928 — all
      BEFORE the guard at 967. The 8 NOT-REDUCED ones are at 1123/1144/1681/1702/2252/2298/2323/2548
      — all AFTER it. Perfect partition on the guard's line number, zero exceptions."
    - "Live browser measurement (not inference): headless Chrome with
      `--force-prefers-reduced-motion`, `matchMedia('(prefers-reduced-motion: reduce)').matches ===
      true`, reading computed styles off the real built bundle. The 6 report `0.001s`; the 8 report
      0.18-0.28s. The same probe with the flag OFF shows all 14 at full duration, proving the probe
      actually discriminates rather than always printing the same thing."
    - "Both signals agree on the identical 6/8 split, derived by two independent instruments."
  falsification_test: "If specificity/layers/`!important` were the mechanism rather than source
    order, the split would NOT align perfectly on line 967 — some later-declared selector would be
    reduced, or some earlier one not. It aligns exactly. Additionally: moving a single NOT-REDUCED
    rule above line 967 with no other change must flip it to REDUCED (position is the only variable)."
  fix_rationale: "Source order is only the proximate cause; the ROOT cause is that a user-preference
    accessibility guard was expressed as (a) a positional, non-`!important` declaration and (b) a
    hand-maintained enumeration of selectors. Those are two independent failure modes. Zeroing the 8
    named selectors, or relocating the block to the file's end, fixes only (a) and leaves the defect
    live for the next rule anyone adds. A universal-selector guard carrying `!important` removes
    both: `!important` makes it position-independent (it outranks any normal declaration regardless
    of order) and `*` makes it enumeration-independent."
  blind_spots: "Measured in Chromium only — Firefox/WebKit not exercised (the cascade rules used are
    spec-level, not engine-specific, so risk is low). Probe measures computed `transition-duration`
    on synthetic elements, not a real running LiveView, so it verifies the CASCADE, not that each
    surface is visually pleasant under reduced motion. Whether 1ms is the RIGHT accommodation per
    surface (vs keeping opacity fades and killing only transforms) is a design question this fix
    deliberately does not settle — see Resolution.judgement_calls."
  candidate_causes:
    - "code (CSS cascade): later `transition:` shorthand re-expands the longhand — CONFIRMED"
    - "code (CSS architecture): guard is an enumerated list, so new surfaces are silently uncovered
      even when correctly positioned — CONFIRMED as the second, independent failure mode"
    - "config (build tooling): LightningCSS/Tailwind reordering or hoisting rules in the bundle —
      REFUTED, built bundle preserves source order verbatim (guard still sits mid-file at 4068)"
    - "environment (cascade layers): `@import \"tailwindcss\"` introduces `@layer theme, base,
      components, utilities` — REFUTED as a cause; app.css's own rules are unlayered and unlayered
      beats layered, so layers cannot explain the split"
    - "data: n/a — no runtime data participates in a static stylesheet"
  and_gate: "YES — this failure genuinely requires >1 contributing condition, which is why the
    obvious one-line fix is wrong. Condition 1: the guard lacks `!important` (so source order can
    beat it). Condition 2: the guard enumerates selectors (so coverage must be hand-maintained).
    Today only condition 1 is firing, but fixing 1 alone leaves condition 2 armed for the next
    animated surface added anywhere in the file. The fix must break both."

## Symptoms

expected: With OS/browser "reduce motion" enabled, every animated surface in the catalog UI
(sheet, drawer, category panel, mobile CTA bar, etc.) should animate at effectively zero duration
(or otherwise respect the user's reduced-motion preference) — no surface should still play its full
transition.
actual: Verified split with zero exceptions during the prior sweep: the 6 selectors declared BEFORE
the `prefers-reduced-motion` block (~line 923) correctly reduce to ~0.001s duration; the 8 selectors
declared AFTER it — `.pk-cat-backdrop`, `.pk-cat-panel`, `.pk-drawer-backdrop`, `.pk-drawer`,
`.pk-mobile-cta-bar`, `body.pk-has-cta-bar`, `.pk-title-echo`, `.pk-dimmable` — still report their
full 0.18-0.28s duration under the reduced-motion media query. `.pk-drawer` is notable: everyone
(including the just-closed catalog-preview-modal-jump session) assumed it was already covered by
this block, and it is not.
errors: None — this is a silent accessibility defect (declared intent has no effect), not a crash
or console error.
reproduction: Enable "reduce motion" (OS setting or Chrome DevTools' "Emulate CSS media feature
prefers-reduced-motion: reduce"), then trigger any of the 8 listed surfaces (e.g. open the mobile
category drawer, or scroll to trigger the mobile CTA bar) and observe the transition duration is
still full-length rather than near-instant.
started: Not a regression — appears to have existed since each affected rule was authored; only
surfaced now because the prior sweep's per-rule instrumentation happened to check computed
transition-duration under the reduced-motion media query for all 14 rules, not just the ones under
active investigation.

## Eliminated

- hypothesis: Cascade layers explain the split — `@import "tailwindcss"` injects
  `@layer theme, base, components, utilities`, and layer precedence beats source order independently
  of position, so the guard might be losing a LAYER race rather than an ORDER race.
  evidence: `grep -n "@layer" assets/css/app.css` returns nothing — app.css declares no layers at
  all, so every one of its rules (the guard included) is unlayered. Unlayered styles win over ALL
  layered styles, so Tailwind's and daisyUI's layers cannot override any pk- rule in either
  direction. Layers are real in the built bundle but causally inert here.
  timestamp: 2026-08-25T12:20:00Z

- hypothesis: A second `prefers-reduced-motion: reduce` block elsewhere re-raises the durations.
  evidence: The built bundle genuinely contains TWO reduce blocks (source has one), which looked
  promising. Inspected both: the extra one is daisyUI's `.skeleton` rule setting
  `transition-duration: 15s`, nested inside `@layer daisyui.l1.l2.l3`. It targets no pk- selector
  and is layered (so it loses to unlayered regardless). Not a contributor.
  timestamp: 2026-08-25T12:22:00Z

- hypothesis: A competing `transition-duration` LONGHAND declared elsewhere outranks the guard.
  evidence: `grep -n "transition-duration\|animation-duration"` across the whole file returns
  exactly ONE hit — line 982, inside the guard block itself. There is no competing longhand
  anywhere; the overriding declarations are all `transition:` shorthands.
  timestamp: 2026-08-25T12:23:00Z

- hypothesis: `!important` somewhere gives the later rules their win.
  evidence: `grep -c "!important" assets/css/app.css` returned 0. The file contained no important
  declarations at all prior to this fix.
  timestamp: 2026-08-25T12:23:00Z

- hypothesis: Specificity explains it — e.g. `body.pk-has-cta-bar` (0,1,1) outranking the guard.
  evidence: The guard listed the identical selector text, so specificity is equal by construction
  and cannot break the tie. More decisively, the split partitions PERFECTLY on the guard's line
  number across 14 selectors of differing specificity (`.pk-drawer` 0,1,0 and `body.pk-has-cta-bar`
  0,1,1 both fail; `.pk-sheet` 0,1,0 succeeds) — specificity does not predict the outcome, position
  does.
  timestamp: 2026-08-25T12:24:00Z

- hypothesis: The build tool (LightningCSS/Tailwind) reorders or hoists rules, so source order is
  not what the browser sees.
  evidence: Located the guard in the built bundle at line 4068 — still mid-file, still between the
  same neighbouring rules, verbatim. Order is preserved end to end.
  timestamp: 2026-08-25T12:25:00Z

- hypothesis (fix-level): Relocating the existing block to the end of the file is a sufficient fix.
  evidence: It IS sufficient for today — proven directly (see Evidence, relocation experiment: all
  14 flip to REDUCED). Rejected anyway because it cures only one of the two conditions in the
  AND-gate: the block would remain an enumerated list, so any newly authored animated surface stays
  uncovered, and any rule appended below it re-opens the original defect. Explicitly out of scope
  per the directive's requirement for a fix robust against future selectors added below.
  timestamp: 2026-08-25T12:40:00Z

## Evidence

- timestamp: 2026-08-25T12:00:00Z
  checked: Referenced knowledge-base.md entry for catalog-preview-modal-jump (the sweep that
  surfaced this)
  found: "'A `prefers-reduced-motion: reduce` block placed in the MIDDLE of a stylesheet is silently
  inert for every rule declared after it — media queries add no specificity and each surface's own
  later `transition:` shorthand resets `transition-duration`. Verified with a perfect split and zero
  exceptions: the 6 selectors declared before the block reduce to 0.001s, the 8 declared after it
  still report their full 0.18-0.28s.'"
  implication: Strong prior evidence for the mechanism, but it was a byproduct finding from a
  differently-scoped session (motion-curve amplitude, not reduced-motion coverage) — re-verify
  directly before committing to a fix, per standard practice, rather than fixing on secondhand
  evidence alone.

- timestamp: 2026-08-25T12:15:00Z
  checked: Static cascade analysis — a purpose-written brace-matching parser over comment-stripped
  app.css, locating every one of the 14 target selectors' own rule line and its transition-related
  declarations, versus the guard block's line. (Comment-stripped deliberately: this file's prose
  discusses transitions at length and a substring grep would match commentary.)
  found: The guard sits at line 967 (NOT ~923 as the trigger estimated — the file has grown since).
  The 6 reported-REDUCED selectors declare their own `transition:` shorthand at lines 561, 576, 754,
  807, 849, 928 — all ABOVE 967. The 8 reported-NOT-REDUCED ones are at 1123, 1144, 1681, 1702,
  2252, 2298, 2323, 2548 — all BELOW it. The partition on line 967 is perfect, with no straddling.
  implication: Consistent with the source-order hypothesis, and the exact 6/8 membership matches the
  carried-forward claim. Still only static reasoning at this point — not yet observed behaviour.

- timestamp: 2026-08-25T12:26:00Z
  checked: Live measurement. Headless Chrome (`--headless=new --force-prefers-reduced-motion`)
  loading the REAL built bundle (priv/static/assets/css/app.css) against a probe page carrying one
  element per selector, reading `getComputedStyle().transitionDuration`. Probe asserts
  `matchMedia('(prefers-reduced-motion: reduce)').matches === true` in-page so the emulation itself
  is proven active rather than assumed.
  found: `REDUCED_MOTION_ACTIVE=true`. The 6 report `0.001s`; the 8 report their full 0.18-0.28s —
  identical membership to the static analysis, zero exceptions. Control run with the flag OFF shows
  all 14 at full duration, proving the probe discriminates rather than printing a constant.
  implication: The defect is now confirmed by direct observation on the real artefact, by an
  instrument independent of the static parse. The two agree exactly. Root cause confirmed, and no
  longer resting on secondhand evidence.

- timestamp: 2026-08-25T12:32:00Z
  checked: Falsification / strong-inference experiment. Took the built bundle, excised the guard
  block and re-appended it BYTE-IDENTICAL at end-of-file. Position is therefore the only variable
  changed — same rules, same specificity, same selectors, same properties.
  found: All 14 selectors flip to `0.001s` REDUCED.
  implication: Decisive. Position alone accounts for the entire split, which rules out every
  remaining specificity/longhand/layer explanation simultaneously. Root cause: SOURCE ORDER within
  a single unlayered cascade layer, where each later `transition:` shorthand resets the
  `transition-duration` longhand the guard had set.

- timestamp: 2026-08-25T12:36:00Z
  checked: Whether any JS depends on transition/animation completion events, which would constrain
  how aggressively durations may be collapsed. Grepped assets/js/ and lib/ for `transitionend`,
  `animationend`, `transitionrun`, `animationiteration`, `getAnimations`.
  found: Zero occurrences anywhere. The only reduced-motion-aware JS is carousel_row.ex:84 and
  about_live.ex:83, both of which branch on `matchMedia` themselves and are unaffected by CSS
  duration values.
  implication: Collapsing durations is safe. `1ms` rather than `0s` is nonetheless retained — a
  zero-duration transition fires no `transitionend` at all, so 1ms preserves that event contract for
  future hooks at no perceptible cost, and matches the value the old block already used.

- timestamp: 2026-08-25T12:50:00Z
  checked: POST-FIX re-run of the SAME headless-Chrome probe against the freshly rebuilt bundle,
  both with reduced motion forced and with it off.
  found: Forced — all 14 selectors report `0.001s` REDUCED (was 6/14). Off — all 14 report their
  original full 0.18-0.28s, unchanged from the pre-fix baseline.
  implication: Fix verified by the same instrument that found the bug, and the control run shows the
  guard does not leak into normal browsing — visitors without the preference keep every animation
  exactly as designed.

- timestamp: 2026-08-25T12:54:00Z
  checked: The structural claim specifically (the reason this fix was chosen over relocation).
  Appended three hostile new rules BELOW the guard in a copy of the built bundle: a plain new
  animated surface, one with deliberately inflated specificity
  (`html body div#hi-spec.pk-future-strong`) plus a `transition-delay`, and one with an `infinite`
  animation.
  found: All three report `transition=0.001s delay=0s anim-dur=0.001s iter=1` under reduced motion.
  implication: The guard is genuinely position-independent AND enumeration-independent — the two
  properties the old design lacked. A future contributor cannot silently reopen this defect by
  adding a rule below, and does not need to know the guard exists.

## Resolution

root_cause: >
  Two conditions had to hold simultaneously (AND-gate confirmed — this is why the one-line fix is
  the wrong fix).
  (1) POSITIONAL: the `@media (prefers-reduced-motion: reduce)` guard declared
  `transition-duration: 1ms` WITHOUT `!important`, from a position mid-stylesheet (line 967). A
  media query contributes no specificity, and app.css declares no `@layer`, so every rule including
  the guard shares one unlayered cascade layer where plain source order decides. Each of the 8
  affected selectors declares its own `transition:` SHORTHAND further down the file, and a shorthand
  resets every longhand it owns — silently restoring `transition-duration` to full for exactly those
  selectors that happen to be written below line 967.
  (2) ENUMERATIVE: the guard was a hand-maintained list of 14 selectors, so coverage depended on a
  human remembering to register every newly animated surface. Only condition (1) was actively
  firing, but (2) was armed and would have produced the same silent failure for the next animated
  rule added anywhere in the file.
  Net effect: a documented accessibility intent with no effect for 8 of 14 surfaces — including
  `.pk-drawer`, which the immediately-preceding session had explicitly assumed was covered.

fix: >
  Replaced the enumerated mid-file block with a single global guard at end-of-file:
  `@media (prefers-reduced-motion: reduce) { *, *::before, *::after { animation-duration: 1ms
  !important; animation-delay: 0s !important; animation-iteration-count: 1 !important;
  transition-duration: 1ms !important; transition-delay: 0s !important; scroll-behavior: auto
  !important } }`.
  `!important` kills condition (1) — an important declaration outranks every normal one regardless
  of source order, so the guard can never lose a placement race again. `*` kills condition (2) —
  there is no list left to forget to update. A breadcrumb comment is left at the old location so a
  reader who goes looking for the removed block finds where it went and learns not to re-register
  surfaces there. The guard carries a long comment recording the measured evidence, why `!important`
  is deliberate (it is the file's only one), and why relocation was rejected as the fix.

verification: >
  guardrail_verdict: accepted
  1. Original-symptom reproduction (primary instrument, headless Chrome computed styles on the real
     built bundle): PRE-FIX 6/14 REDUCED — POST-FIX 14/14 REDUCED. Same probe, same flag, rebuilt
     artefact.
  2. Control / no-regression: with reduced motion OFF, all 14 surfaces retain their original
     0.18-0.28s durations post-fix, byte-identical to the pre-fix baseline. The guard does not leak
     into normal browsing.
  3. Structural robustness (the claim that justified this fix over relocation): three hostile rules
     appended BELOW the guard — including one with inflated specificity and one `infinite` animation
     — are all still fully reduced.
  4. Falsification control: relocating the ORIGINAL block byte-identically to EOF also fixed all 14,
     confirming position was the sole variable and that the diagnosis was not over-fitted.
  5. Regression test RED-verified, not merely written: reverting app.css to HEAD and rebuilding
     makes 5 of the 6 new assertions fail with their intended diagnostics (universal-selector,
     !important on all three properties, iteration-count pinning, 1ms-not-0s, and the built-bundle
     end-to-end check). All green once the fix is restored. The 6th ("exactly one reduce block") is
     a boundary neighbour that is green in both states BY DESIGN — it guards the opposite wrong
     change, someone splitting the accommodation back into multiple blocks.
  6. Full project gate: `mix quality` passes — hex.audit, deps.audit, format (Styler), credo
     --strict, sobelow, and 466 tests, 0 failures.
  7. HUMAN VERIFICATION — CONFIRMED (2026-08-25). The user exercised BOTH arms in a real browser,
     which is the arm the instruments could not supply: with reduced motion ENABLED everything
     snaps instantly (the defect is gone across surfaces, not just in computed styles), and with
     reduced motion DISABLED normal motion still plays exactly as designed — explicitly confirming
     nothing was over-suppressed. This closes the blind spot flagged in reasoning_checkpoint, that
     the probe verified the CASCADE on synthetic elements rather than the lived behaviour of real
     LiveView surfaces.
  CAVEAT, stated explicitly: the ExUnit suite did NOT verify the reduced-motion behaviour itself.
  This is a CSS-only change and ExUnit cannot observe a computed style. The suite confirms no
  regression elsewhere and pins the guard's STRUCTURE, not its BEHAVIOUR; the behavioural proof is
  items 1-3 (the browser measurements) plus item 7 (human confirmation in a real browser).
  Sobelow's findings are pre-existing low-confidence hits in unrelated files (seed/report.ex,
  catalog_live/index.ex), untouched by this change.

judgement_calls: >
  - `1ms`, not `0s`: a zero-duration transition generates no transition, so `transitionend` never
    fires. No hook in this repo listens for it today (verified by grep), but 1ms is perceptually
    identical and preserves the event contract. Also preserves the previous block's chosen value.
  - `animation-iteration-count: 1` is not optional garnish: an `infinite` animation left at a 1ms
    duration would repeat ~1000x/second, far worse than the motion suppressed. `.pk-scroll-top`'s
    bounce is infinite (already `no-preference`-gated, so this is belt and braces for future ones).
  - Delays zeroed: the app's single `transition-delay` (100ms, staging the header search input's
    fade behind the pill's widening) becomes pure dead wait once the widening is 1ms.
  - `!important` introduced deliberately, and it is the file's only one. This is the canonical
    justified case — a user's stated motion preference is exactly what the cascade reserves
    `!important` for, outranking author intent by design. Without it the fix silently degrades back
    into a source-order race. Flagged in-comment so a future "no !important" tidy-up does not strip
    it.
  - `scroll-behavior: auto` is redundant TODAY (html's smooth scroll is already `no-preference`-
    gated by the category-anchor-scroll session) and is included only so a future ungated
    `scroll-behavior: smooth` cannot reopen this same class of defect. It does not weaken that
    session's test, which asserts on the `no-preference` block and is untouched.
  - daisyUI's `.skeleton` deliberately sets `transition-duration: 15s` under reduce (slow the
    shimmer rather than remove it); the universal guard now overrides that to 1ms. Judged
    acceptable: skeleton's actual shimmer animation is already `no-preference`-gated by daisyUI so
    it never runs under reduce, leaving the 15s value vestigial.
  - SCOPE SETTLED BY THE USER — the BLANKET accommodation is the intended shipping behaviour, not
    a stepping stone. During this session the alternative was scoped and put to the user: a
    per-surface treatment for the large sliding surfaces (.pk-sheet ~515px, .pk-drawer ~320px)
    that keeps the opacity fade — which is not vestibular — and suppresses only the transform
    travel. On real-browser review of BOTH arms the user chose the blanket guard as shipped: kill
    all transition/animation duration under reduced motion. This is a deliberate, user-ratified
    design decision, NOT a deferred item, follow-up, or known limitation. There is no
    opacity-vs-transform refinement outstanding, and a future reader should not treat this
    paragraph as an invitation to build one. Note the decision route matters as much as the
    outcome: this codebase's own KB establishes that motion judgements are perceptual questions
    that measurement cannot settle, so it was correctly closed by a human looking at it rather
    than by argument from the probe.

files_changed:
  - assets/css/app.css (guard replaced and relocated; breadcrumb left at old position)
  - test/pukllay_club_web/stylesheet_integrity_test.exs (6 new assertions, 5 RED-verified)
