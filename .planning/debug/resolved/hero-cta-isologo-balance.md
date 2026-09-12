---
status: resolved
trigger: "The first \"sumate\" CTA doesn't play correct balance with isologo and so on"
created: 2026-09-08T16:00:00Z
updated: 2026-09-12
resolved: 2026-09-12
gap_id: G-01.5-1
artifacts: .planning/debug/assets/hero-cta-isologo-balance/
audit_acknowledged:
  milestone: v1.0
  at: 2026-09-11
  status: diagnosed
---

## Current Focus

bug_class: Bohrbug (deterministic, purely visual — reproduces at every load, no timing/concurrency)
known_pattern_candidates:

  - "footer-theme-toggle-balance — 'wrong balance' between adjacent concerns; the diagnostic instrument
     is a CHANNEL INVENTORY (chrome / proximity / KIND / fill / ink / BOX GEOMETRY): enumerate the
     channels prior work already touched, attack the unmeasured one."
  - "footer-desktop-overloaded — ONE gap value serving every spacing tier switches off proximity, the
     only grouping cue a divider-less design has. Applies directly: #about-hero uses a flat space-y-3."
  - "footer-desktop-imbalance — hierarchy has 3 channels (proximity, weight/contrast, colour); fixing
     one and declaring victory is how 'still unbalanced' survives a correct spacing fix. Also: fill
     ratio / ink mass, and 'flush box != flush ink'."
hypothesis: |
  CONFIRMED. `sumate_cta/1`'s `min-h-12` is a raw one-axis height utility standing in for a daisyUI
  size step, so the CTA's height was stretched 35px -> 48px (+37.1%) while `--btn-p` (16px) and
  `--fontsize` (14px) stayed at the default step — collapsing its horizontal:vertical padding ratio
  to 1.03:1 (every alternative is 1.78-2.00:1) and leaving it the narrowest object in the hero.
test: |
  DONE — in-browser mutation of the live CTA across 4 variants at 375 and 1280px, measured and
  screenshotted; plus a differential against sketches 050/051 (the design source) rendered in the
  same browser.
expecting: |
  Confirmed as predicted: variant 1 (`min-h-12` removed) exposed the 35px natural height; variant 2
  (`btn-lg`) restored button proportions with radius and stack-gap untouched, answering the AND-gate
  "no".
next_action: |
  NONE — diagnose-only mode (goal: find_root_cause_only). Root cause returned to the caller; no fix
  applied. Fix direction and the in-repo precedent (show.ex:502 `btn-lg` + `min-h-11`) are recorded
  in Resolution.

reasoning_checkpoint:
  hypothesis: "`min-h-12` on sumate_cta/1 stretches only the height of a daisyUI button whose padding and font-size are governed by coupled size-step tokens, producing a squat 1.03:1-padding box that is the narrowest object in the hero."
  confirming_evidence:
    - "Measured: removing min-h-12 in-browser drops the height to exactly 35px, matching --size-field: 0.21875rem x 10 — the stretch is +37.1% on one axis only."
    - "Measured: padding ratio 1.03:1 shipped vs 1.78 / 1.90 / 2.00:1 for daisyUI default, btn-lg and the design source."
    - "Measured: 85.41 x 48 byte-identical at 375/430/768/1280px in both themes, i.e. narrower than the 111.19px companion wordmark and 52.3% of the 163.45px isologo."
    - "Grep: min-h-12 occurs exactly once in the codebase; the app's own hero-scale CTA (show.ex:502) uses btn-lg + min-h-11."
    - "Provenance: 260822-2v9-SUMMARY.md records min-h-12 was added purely to match the theme toggle's 48px in a header row that no longer exists."
  falsification_test: "Apply btn-lg (a real size step) in-browser with radius and stack gap untouched. If the button still reads unbalanced, the size step is not the cause."
  fix_rationale: "Addresses the mechanism (a size step governs height+padding+font together) rather than the symptom (the button looks small). Composing a size step with min-h-11 is the pattern show.ex:502 already uses, so it is a consistency repair against in-repo precedent."
  blind_spots:
    - "Perceptual sufficiency is not established by measurement — per search-right-align-mobile-cycle-3, a correctly-diagnosed, arithmetically-bounded fix can still be rejected on human review. Which size step (btn-lg vs the design source's 16px/28px pill) is a design choice the user must make."
    - "The 4px radius vs the sketch's pill is a genuine open design question I deliberately did not resolve."
    - "I did not test 481-639px, where the sticky bar and the Cierre button swap; that band belongs to G-01.5-3."
  candidate_causes:
    - "code: min-h-12 substitutes for a daisyUI size step (CONFIRMED — primary)"
    - "code: flat space-y-3 gives one 12px tier to four boundaries (secondary amplifier)"
    - "code: CTA is fixed-size while .pk-about-h1 is fluid clamp(2.75rem, 8vw, 5.5rem) (context — doubles the mismatch on desktop)"
    - "config: --size-field: 0.21875rem puts daisyUI's default btn at 35px, below the project's own 44px touch floor — which is WHY a raw height utility was reached for"
    - "config: --radius-field 4px vs the sketch theme's --radius-full pill (secondary, kind channel)"
    - "process: sketch 050/051's button claims in its own comment to be sumate_cta/1 but renders 16px/28px/pill; check-theme-drift.sh gates colour only, by design"
  and_gate: "NO — one cause is sufficient. The btn-lg mutation fixes only the size step, leaving the 12px stack gap and the 4px radius in place, and already reads as a correct button. The spacing and radius findings are amplifiers, recorded and demoted in Eliminated rather than folded into root_cause. NOTE: the AND-gate does fire on the FIX, not the cause — a size step alone lands at 42px, so it must be composed with min-h-11 to hold the 44px touch floor."

## Symptoms

expected: |
  Per phase 01.5's design decisions D-01/D-02/D-04, the isologo + PUKLLAY CLUB wordmark + eyebrow
  (and any CTA button rendered alongside/near them at rest, e.g. the sticky-header "Sumate" CTA that
  appears near the isologo after the header morph) should read as one visually balanced, grouped
  block — consistent sizing, spacing, and alignment relative to the isologo.
actual: |
  User reported (verbatim): "The first \"sumate\" CTA doesn't play correct balance with isologo and
  so on" — implying the CTA button next to/near the isologo looks visually off-balance (size,
  spacing, or alignment mismatch) compared to the isologo/wordmark.
errors: None reported
reproduction: |
  Visit /quienes-somos on mobile (375px) and desktop, both light/dark themes. Look at the header/hero
  area where the isologo, wordmark, and the "Sumate" CTA button appear together (header/hero morph
  area implemented in phase 01.5, plans 01.5-01 and 01.5-04).
started: Discovered during end-of-phase UAT for phase 01.5 (2026-09-08)

## Eliminated

<!-- APPEND only -->

- hypothesis: |
    The isologo's designed clearance (`--pk-about-mark-clear: 80px`, derived in G-01.4-3 as "the
    ENTIRE perceived separation") was silently half-consumed when 01.5-01 inserted the companion
    wordmark at `position: absolute; top: 100%; margin-top: 12px` inside it, so the brand lockup now
    crowds the copy below and the whole hero reads unbalanced.
  evidence: |
    Real but NOT a deviation from the design source, and not the reported symptom. Measured ink gap
    wordmark -> eyebrow: production 36px; sketch 050 10.56px; sketch 051 21.56px. Production is
    LOOSER than both sketches, not tighter. The mechanism is real (48.45px of the 80px box budget is
    consumed by an absolutely-positioned child the anchor's `calc(180px + 80px)` cannot see) and is
    worth a note, but it cannot explain "the CTA doesn't play correct balance".
  timestamp: 2026-09-08T16:48:00Z

- hypothesis: |
    Horizontal mis-centering — the floating fixed-position mark drifts off the hero column's centre,
    so the CTA below it looks misaligned.
  evidence: |
    Refuted by direct measurement at 4 widths x 2 themes. Mark/wordmark centre 187.73 vs CTA centre
    187.50 at 375px (0.23px), and 640.23 vs 640.00 at 1280px. Sub-pixel; invisible. Per
    footer-desktop-imbalance's lesson (v), "flush is a property of edges; the complaint may be about
    MASS" — every edge here is flush, so alignment is not the channel.
  timestamp: 2026-09-08T16:40:00Z

- hypothesis: |
    Flat `space-y-3` (12px between all four hero tiers) is the primary cause — proximity is switched
    off, so the CTA reads as the fourth line of the text stack rather than a distinct object
    (the footer-desktop-overloaded pattern).
  evidence: |
    Demoted from primary to SECONDARY AMPLIFIER, not eliminated. It is real (ink gaps 8/10/14px, a
    single tier across three semantically different boundaries) but it is not a deviation of KIND
    from the design source: both sketch 050 and 051 use a flat `.hero { gap: 16px }` column and the
    human approved sketch 051's hero composition "as-is". Production's 12px is only 25% tighter than
    the approved 16px. Decisively, the `btn-lg` mutation (variant 2) leaves the 12px stack untouched
    and already reads correct — so this condition is neither necessary nor sufficient.
  timestamp: 2026-09-08T17:10:00Z

- hypothesis: |
    The 4px `--radius-field` (vs the design source's pill) is the primary cause — the CTA is the only
    right-angled rectangle in a hero full of organic/display forms.
  evidence: |
    Demoted to SECONDARY (the "kind" channel). `--radius-field: 0.25rem` is a real, global, app-owned
    daisyUI token used by every button in the app, so the pill is a sketch-theme value, not an app
    decision — and `check-theme-drift.sh` explicitly does not gate radius. The `btn-lg` mutation keeps
    the 4px radius and still reads as a proper button, so shape is not required to explain the report.
  timestamp: 2026-09-08T17:12:00Z

## Evidence

<!-- APPEND only -->

- timestamp: 2026-09-08T16:05:00Z
  checked: Knowledge base (.planning/debug/knowledge-base.md, 20 entries) queried on "balance", "isologo", "CTA"
  found: |
    Three prior sessions on the SAME failure class ("wrong balance", purely visual, zero console
    errors, every gate green): footer-desktop-overloaded (flat gap kills proximity),
    footer-desktop-imbalance (ink mass / fill ratio / KIND), footer-theme-toggle-balance (BOX
    GEOMETRY — the channel four prior sessions never measured).
  implication: |
    The transferable instrument is footer-theme-toggle-balance's CHANNEL INVENTORY. Do not guess a
    hypothesis; measure every channel (footprint, proximity, ink, kind, alignment) and let the
    outlier name itself. Also: no gate in this repo observes rendered geometry, so measurement must
    be CDP against the running app, not ExUnit.

- timestamp: 2026-09-08T16:10:00Z
  checked: lib/pukllay_club_web/live/about_live.ex:69-411 (hero markup) and layouts.ex:896-909 (sumate_cta/1)
  found: |
    #about-hero is `class="space-y-3 pt-2 pb-12 text-center"` with FIVE flow children in order:
      1. <div data-morph-anchor class="pk-about-mark-anchor mb-0">  (in-flow spacer for the mark)
      2. <p class="pk-about-hero-eyebrow ... text-xs uppercase tracking-widest text-neutral">
      3. <h1 class="font-display pk-about-h1">Conectá jugando</h1>
      4. <p ... text-base text-neutral sm:hidden> + <p ... hidden ... sm:block>  (one visible)
      5. <div class="flex justify-center"><Layouts.sumate_cta /></div>
    sumate_cta/1 renders `<a class="btn btn-outline btn-primary min-h-12">Sumate</a>` — natural
    (content) width, no w-full, outline variant.
  implication: |
    `space-y-3` compiles to a flat 12px margin between EVERY adjacent pair — the identical
    one-value-for-every-tier shape footer-desktop-overloaded recorded. The CTA is therefore 12px
    from the tagline, exactly the same distance as eyebrow→h1 (which are one lockup).

- timestamp: 2026-09-08T16:14:00Z
  checked: assets/css/app.css:3158-3197 (:root mark tokens + .pk-about-mark-anchor) and :3258-3285 (.pk-about-morph-name)
  found: |
    --pk-about-mark-h: 180px; --pk-about-mark-clear: 80px; --pk-about-mark-name-scale: 0.135
    .pk-about-mark-anchor { height: calc(180px + 80px) = 260px }
    .pk-about-morph-name { position: absolute; top: 100%; margin-top: 12px;
                           font-size: calc(180px * 0.135) = 24.3px }
    The 80px clearance's own derivation comment (G-01.4-3, phase 01.4) states it is "the ENTIRE
    perceived separation from the copy below it" because both isologo PNGs are cropped tight to
    their ink with zero transparent padding.
  implication: |
    The companion wordmark added by 01.5-01 is ABSOLUTELY POSITIONED at top:100% + 12px, i.e. it
    lands INSIDE the 80px clearance and contributes nothing to the anchor's height. The 80px was
    derived when no wordmark existed. Candidate: the isologo lockup's designed clearance is now
    silently ~half-consumed. Needs measurement. [LATER ELIMINATED — see Eliminated.]

- timestamp: 2026-09-08T16:35:00Z
  checked: CDP geometry sweep of the running app, /quienes-somos, 375/430/768/1280px x light/dark
  found: |
    Hero flow stack (375px, box edges): anchor 104..364 (260px) | eyebrow 364..380 | h1 392..436 |
    tagline 448..472 | CTA wrapper 484..532. Box gaps: 0 | 12 | 12 | 12 (the leading 0 is `mb-0`
    neutralizing space-y-3 on the anchor, as documented). Ink-to-ink gaps: mark->name 15,
    name->eyebrow 36, eyebrow->h1 8, h1->tagline 10, tagline->CTA-box 14.
    CTA: 85.41 x 48 box, label ink 51.41 x 17, font-size 14px, font-weight 600, padding-inline 16px,
    border-width 1px, border-radius 4px. BYTE-IDENTICAL at 375, 430, 768 and 1280px, both themes.
    h1: 44px at 375 -> 61.44px at 768 -> 88px at 1280 (ink width 243.28 -> 486.56).
  implication: |
    Two facts fall out. (1) The CTA is the only hero object that does NOT scale — while the h1
    doubles, the CTA is frozen, so CTA-width / h1-ink-width falls 35.1% -> 17.6% between 375 and
    1280px. (2) The CTA at 85.41px wide is the narrowest visible object in the hero, narrower than
    the 111.19px companion wordmark and 52.3% of the isologo's 163.45px.

- timestamp: 2026-09-08T16:45:00Z
  checked: |
    Differential vs the design source — sketch 050 (`.hero-cta`) and sketch 051 (`.btn-sumate`),
    both rendered in the same headless Chrome at 375 and 1280px
  found: |
    | property     | production        | sketch 050 & 051 |
    |--------------|-------------------|------------------|
    | box          | 85.41 x 48        | 119.11 x 48 (050: x50) |
    | label ink    | 51.41 x 17        | 61.11 x 22 |
    | font-size    | 14px              | 16px |
    | font-weight  | 600               | 600 (same) |
    | padding-inl. | 16px              | 28px |
    | border-radius| 4px               | 9999px (pill) |
    Production is 28.3% narrower than the design source, at both widths, in both sketches.
    Sketch 051's `.btn-sumate` carries the comment: "Real 'Sumate' button (layouts.ex's sumate_cta/1:
    btn-outline btn-primary min-h-12)" — it claims to BE production's button and is not.
  implication: |
    Phase 01.5's entire "CTA rhythm" design judgement (sketch 051's stated purpose) was made against
    a button production cannot render. This is a design-source fidelity break, not a porting mistake
    in the phase's own plans.

- timestamp: 2026-09-08T16:52:00Z
  checked: .planning/sketches/themes/check-theme-drift.sh header comment
  found: |
    Verbatim: "Only colour tokens are checked — typography, spacing, radius, shadow and motion tokens
    have no daisyUI counterpart and are sketch-only".
  implication: |
    The repo's ONLY sketch<->app parity guard is scoped to colour by design, so a sketch button that
    differs from production on radius, padding and font-size is invisible to it. This is the
    "why not caught" answer for the fidelity break above.

- timestamp: 2026-09-08T17:00:00Z
  checked: |
    daisyUI `.btn` rule extracted from the compiled priv/static/assets/css/app.css, plus the app's
    own `--size-field`
  found: |
    `.btn { padding-inline: var(--btn-p); height: var(--size); font-size: var(--fontsize, 0.875rem);
             font-weight: 600; --size: calc(var(--size-field, 0.25rem) * 10) }`
    `.btn-sm { --fontsize: 0.75rem;  --btn-p: 0.75rem; --size: calc(var(--size-field) * 8) }`
    `.btn-lg { --fontsize: 1.125rem; --btn-p: 1.25rem; --size: calc(var(--size-field) * 12) }`
    App declares `--size-field: 0.21875rem` -> default `.btn` height = 35px.
  implication: |
    daisyUI's size steps move height, padding-inline AND font-size together. `min-h-12` moves ONLY
    the height. That is the mechanism.

- timestamp: 2026-09-08T17:08:00Z
  checked: |
    In-browser mutation experiment on the live production CTA at 375 and 1280px (4 variants,
    measured + screenshotted)
  found: |
    | variant                      | box            | font | h-pad | v-pad | h:v pad | CTA/h1@1280 |
    |------------------------------|----------------|------|-------|-------|---------|-------------|
    | 0 shipped                    | 85.41 x 48     | 14px | 16px  | 15.5  | 1.03:1  | 17.6%       |
    | 1 `min-h-12` removed         | 85.41 x **35** | 14px | 16px  |  9.0  | 1.78:1  | 17.6%       |
    | 2 `btn-lg` (no min-h)        | 108.09 x 42    | 18px | 20px  | 10.5  | 1.90:1  | 22.2%       |
    | 3 design-source spec         | 116.75 x 48    | 16px | 28px  | 14.0  | 2.00:1  | 24.0%       |
    Variant 1 proves the natural `.btn` height in this app is 35px, so `min-h-12` is a +37.1%
    one-axis stretch. Screenshots: variant 0 reads as an input box; variants 2 and 3 read as buttons.
  implication: |
    CONFIRMS the hypothesis and gives its falsifiable signature: the shipped CTA is the ONLY variant
    whose horizontal:vertical padding ratio is ~1.0:1. Also answers the AND-gate — variant 2 fixes
    only the size step (radius still 4px, stack gap still 12px) and already resolves the perceived
    imbalance, so no second condition is required.

- timestamp: 2026-09-08T17:15:00Z
  checked: grep of every `.btn` / `min-h-*` call site in lib/, and the planning record for `min-h-12`
  found: |
    `min-h-12` occurs EXACTLY ONCE in the codebase — layouts.ex:904, `sumate_cta/1`. The other 36
    touch-floor utilities are all `min-h-11` (44px). The app's own hero-scale primary CTA,
    `lib/pukllay_club_web/live/catalog_live/show.ex:502`, is
    `class="btn btn-primary btn-lg min-h-11 w-full pk-poster-reserve"` — a real SIZE STEP composed
    with the touch floor. `filter_modal.ex:408` additionally uses `min-w-40` to give a primary action
    a declared width. `sumate_cta/1` is the only content-width `.btn` in the app with neither a size
    step nor a width floor; every other content-width `.btn` is `w-full`, `btn-block` or `btn-circle`.
    Provenance: quick task 260822-2v9-SUMMARY.md:132/157 — "the Sumate CTA dropped its small-size
    modifier and gained `min-h-12`" so it would "rise to the theme toggle's fixed 48px anchor"
    in the desktop header row. `.pk-nav-actions` (that header cluster) no longer exists anywhere in
    lib/, and `sumate_cta/1`'s own moduledoc now states the CTA is absent from `#app-header`.
  implication: |
    (a) The in-repo pattern that solves this correctly already exists (`btn-lg` + `min-h-11`), so the
    fix is a consistency repair, not a new design. (b) `min-h-12` is an ORPHANED CONSTRAINT — the
    header row it was derived for was deleted, and the class outlived it. (c) The fix cannot simply
    drop `min-h-12`: that ships a 35px button, below the project's 44px touch floor. `btn-lg` alone
    gives 42px, still 2px short — so a size step must be COMPOSED with `min-h-11`, exactly as
    show.ex:502 already does.

## Resolution

root_cause: |
  `Layouts.sumate_cta/1` (lib/pukllay_club_web/components/layouts.ex:904) sizes the button with a
  RAW ONE-AXIS HEIGHT UTILITY (`min-h-12`) instead of a daisyUI size step. daisyUI's `.btn` is a
  three-token coupled system — `--size` (height), `--btn-p` (padding-inline), `--fontsize` — and its
  size modifiers move all three together (`.btn-lg` = 1.125rem / 1.25rem / --size x12). `min-h-12`
  moves only the rendered height: this app's `--size-field: 0.21875rem` puts the default `.btn` at
  35px, and `min-h-12` stretches it to 48px (+37.1%) while `--btn-p` stays at 16px and `--fontsize`
  stays at 14px.

  The measurable signature is the button's PADDING RATIO. Vertical slack collapses onto horizontal
  padding: (48 - 17)/2 = 15.5px vertical vs 16px horizontal = **1.03 : 1**. Every alternative sits
  at 1.78-2.00 : 1 (daisyUI default 1.78, `.btn-lg` 1.90, the design source 2.00). At ~1.0 : 1 the
  element is geometrically a square-padded label box, not a button — which is exactly how it reads
  next to the isologo.

  Consequences against its hero siblings (measured, byte-identical at 375px and 1280px, both themes):
  85.41 x 48 box, 51.41px of label ink, 14px type — the NARROWEST visible object in the hero,
  narrower even than the 111.19px companion wordmark, and 52.3% of the isologo's 163.45px width. It
  is also fixed-size while `.pk-about-h1` is `clamp(2.75rem, 8vw, 5.5rem)`, so CTA-width / h1-ink
  falls from 35.1% at 375px to 17.6% at 1280px — the imbalance doubles on desktop.

  PROVENANCE (why this class exists at all): quick task 260822-2v9 changed `sumate_cta/1` from
  `btn-sm min-h-11` to `min-h-12` for one reason recorded in its own SUMMARY — "Sumate CTA rises to
  the theme toggle's fixed 48px anchor... rather than shrinking the toggle" — i.e. a HEIGHT-MATCHING
  constraint in the desktop header row. It dropped the `btn-sm` size step and landed on the default
  step, but the whole change was reasoned about as one number (48px), so padding/font were never
  re-derived. That header call site has since been REMOVED (`.pk-nav-actions` no longer exists
  anywhere in lib/; `sumate_cta/1`'s own moduledoc now asserts the CTA is absent from `#app-header`).
  The constraint that produced `min-h-12` is gone; the class it produced still governs all three
  remaining call sites. `min-h-12` is the ONLY occurrence in the codebase — the other 36 buttons all
  use `min-h-11` (44px, the documented touch floor).

  AND-gate: NO. This single cause is sufficient — the in-browser `btn-lg` mutation resolves the
  perceived imbalance on its own, with the 12px stack gap and the 4px radius left untouched. Two
  secondary amplifiers are recorded in Evidence (flat `space-y-3` proximity; 4px radius vs the
  design source's pill) but neither is required to produce the reported symptom.

  SCOPE NOTE (cross-gap, not this agent's lane): all three `sumate_cta/1` call sites share this
  geometry. The sticky bar passes `class="w-full"`, so the bar dictates its width and it looks fine.
  The two NATURAL-WIDTH call sites are the hero (line 409) and the Cierre band (line 831) — exactly
  the two the UAT flagged (G-01.5-1 and G-01.5-3 item 5, "on the close band, the CTA doesn't have
  the correct balance"). One root cause very likely explains both.

fix: |
  RETROACTIVE CLOSURE (quick 260912-mxr, 2026-09-12) — fix landed after this diagnosis, in two
  plans:

  Plan 01.5-05 (commit eaf9f76, "Sumate CTA size-step fix") first replaced the orphaned
  `min-h-12` one-axis height utility on `Layouts.sumate_cta/1` with daisyUI's `btn-lg` size step
  composed with the project's `min-h-11` touch-floor utility, so height/padding-inline/font-size
  moved together instead of height alone.

  Plan 01.5-10 (commit 0e99941, "Sumate Button Geometry & Sticky Bar Edge") then superseded that
  composition entirely: it retired `btn-lg`/`min-h-11` and introduced a single new CSS class,
  `.pk-sumate-btn` (assets/css/app.css:3045), which owns height (48px `min-height`), horizontal
  padding (28px `padding-inline`), radius (9999px pill) and font-size (1rem) all in one coupled
  declaration — restoring sketch 051's approved button geometry (measured 116.75x48, padding ratio
  2.00:1, vs. the diagnosed defect's 1.03:1) at the component's single source, reaching all three
  `sumate_cta/1` call sites (hero, Cierre band, mobile sticky bar).
verification: |
  `grep -n "min-h-12" lib/pukllay_club_web/components/layouts.ex assets/css/app.css` (2026-09-12)
  finds exactly one match, at layouts.ex:880 — inside prose ("the button had been a bare
  `min-h-12` one-axis height...") documenting the historical defect, not a live class. The live
  `sumate_cta/1` definition (layouts.ex:917-925) renders
  `class={["btn btn-outline btn-primary pk-sumate-btn", @class]}` — no `min-h-12`, no `btn-lg`, no
  `min-h-11`. `.pk-sumate-btn` (app.css:3045-3050) declares `min-height: 48px; padding-inline:
  28px; border-radius: 9999px; font-size: 1rem;` in one rule — height, horizontal padding, radius
  and font-size are coupled together, the opposite of the diagnosed one-axis stretch. Landing
  commits: eaf9f76 (01.5-05-SUMMARY.md) and 0e99941 (01.5-10-SUMMARY.md, which superseded 01.5-05's
  `btn-lg`+`min-h-11` composition with the current `.pk-sumate-btn` class — 01.5-10-SUMMARY.md
  measures the live result at 116.75x48, padding ratio 2.00:1, matching this diagnosis's own
  falsification-test prediction almost exactly).
files_changed:
  - "lib/pukllay_club_web/components/layouts.ex — sumate_cta/1's class list changed from `btn
     btn-outline btn-primary min-h-12` (01.5-05: to `btn-lg min-h-11`; 01.5-10: superseded again)
     to the current `btn btn-outline btn-primary pk-sumate-btn`"
  - "assets/css/app.css — new `.pk-sumate-btn` class (01.5-10) owning min-height/padding-inline/
     border-radius/font-size in one coupled declaration, replacing daisyUI's btn-lg size step"
