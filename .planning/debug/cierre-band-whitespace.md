---
status: diagnosed
trigger: "3. the close \"nos vemos el sabado\" has a huge space top and bottom / 4. also on the close band there are wrong white space and the bottom has bottom space from viewport"
created: 2026-09-08
updated: 2026-09-08
audit_acknowledged:
  milestone: v1.0
  at: 2026-09-11
  status: diagnosed
---

## Current Focus

bug_class: Bohrbug (deterministic, purely declarative CSS geometry, no timing/concurrency/flakiness)

known_pattern_candidate: |
  Two shape-matches in the knowledge base, both to be treated as hypothesis candidates only:
  (a) `footer-desktop-overloaded` — "a breakpoint chosen by convention rather than derived from
      content arithmetic masks the bug on the devices the author tested"; and the meta-lesson that
      reported symptoms can MISLOCATE the state (user said "one line", real state was a wrapped
      two-tier band). Here the user says "mobile", but `#cierre .pk-about-cierre-cta {display:none}`
      at <=480px means the button in their screenshot cannot be a <=480px render.
  (b) `header-height-wordmark-wrap` / `footer-overflow-tablet-width` — a middle BAND of viewport
      widths where two mobile/desktop rules disagree about where "mobile" ends.
  Concrete trigger for (b): the Cierre band is governed by TWO different thresholds — D-10's
  `@media (min-width: 640px)` (100vh full-screen) and D-11's `@media (max-width: 480px)`
  (hide the Cierre CTA + show the sticky bar + spacer). 481-639px is governed by NEITHER.

hypothesis: |
  H1 (item 3, huge space inside the band): the D-10 full-viewport rule
  `@media (min-width:640px) { #cierre { min-height:100vh; display:flex; align-items:center;
  padding: var(--pk-header-h,4.5rem) 0 0 } }` (app.css:2699-2710) forces the band to at least a
  full viewport while its content is only a few hundred px, so `align-items:center` distributes
  the ~500-700px of leftover space as top/bottom padding. The `padding-top: --pk-header-h` that
  D-10 added to "cancel the header overlap" makes the two gaps UNEVEN (top gets +header-h),
  contradicting D-10/D-12's stated even-gap intent.

  H2 (item 4, extra empty band below Cierre before the footer): `.pk-about-cta-spacer`
  (`about_live.ex:847`, `app.css:2566-2569` `height: 4.5rem`, `display:block` only at <=480px) is
  an in-flow 72px empty div that is a DIRECT SIBLING of `#cierre` inside the shell's
  `div.mx-auto.space-y-4` wrapper. It therefore also collects its own 16px `space-y-4` margin,
  and sits on top of `<main>`'s `pb-20` (80px). That stack reads as a distinct empty band.

test: |
  Live CDP measurement of /quienes-somos on the running dev server at a width sweep
  (375, 390, 481, 600, 639, 640, 768, 1280) measuring: #cierre rect + its content-group rect,
  the true top gap vs bottom gap inside the band, every in-flow node between #cierre's bottom
  and the footer's top with its own height/margin, and the arithmetic closure of the total.
  Then differential/falsification: neutralise ONE candidate at a time and re-measure.

expecting: |
  CONFIRMS H1 if #cierre's height >= viewport height at >=640px AND (top gap - bottom gap) is
  approximately --pk-header-h, and the whitespace collapses to ~72px band padding when
  min-height is neutralised.
  REFUTES H1 if the huge gap also appears below 640px (where the rule cannot apply).
  CONFIRMS H2 if the sum (cierre margin + spacer height + spacer margin + main pb-20) closes the
  measured below-cierre distance with no unexplained residual.
  REFUTES H2 if a residual remains, or if the gap exists at widths where the spacer is display:none.

result: |
  H1 CONFIRMED and SPLIT INTO TWO exact, independent halves by differential test (E-05):
    - `min-height: 100vh` owns 100% of the whitespace VOLUME (band 900 -> 220.7 when neutralised
      alone, a 679.3px drop, exactly the leftover).
    - `padding: var(--pk-header-h) 0 0` owns 100% of the ASYMMETRY (gapTop-gapBottom = exactly
      64px = --pk-header-h at every viewport tested; neutralising padding-top alone drives it to
      0 with gaps landing at exactly 371.7/371.7).
  H1's mobile half is REFUTED as stated: at 390px the media-gated rule correctly does not apply
  (EXP A is a no-op there) — the mobile Cierre band is 230px with an EVEN 72/72 split, i.e. the
  shared `.pk-band` padding, identical to every other band. Item 3 as reported ("vertically
  centered", huge gaps) can only be the >=640px state.

  H2 CONFIRMED but NOT as a single cause: the below-Cierre void is a SUM of 5 (mobile) / 3
  (desktop) independent contributors with NO majority, arithmetic closing to exactly 0 residual
  (E-06). The `.pk-about-cta-spacer` is 72 of the 200 mobile pixels (36%), not the whole.

  THIRD, unhypothesised finding that reframes item 4 (E-07/E-08): the void is UNPAINTED white
  sandwiched between two IDENTICAL `--color-base-200` surfaces (`#cierre`'s new D-14 tint and
  `.pk-footer`'s own background). Stripping only the tint — geometry untouched — makes the
  "extra band" reading vanish entirely. The SPACE is pre-existing shell boundary stacking; D-14
  is the EXPOSURE condition that turned it into a visible band.

next_action: |
  DIAGNOSE-ONLY MODE (goal: find_root_cause_only) — investigation complete, no fix applied.
  Hand the root causes to the plan-phase --gaps flow for G-01.5-3.

rca_branching:
  candidate_causes:
    - "code: `min-height: 100vh` on #cierre at >=640px (app.css:2701) — CONFIRMED, owns the whole whitespace volume (E-05 EXP A)"
    - "code: `padding: var(--pk-header-h) 0 0` on #cierre at >=640px (app.css:2704) — CONFIRMED, owns the whole 64px asymmetry AND zeroes the shared band bottom padding (E-05 EXP B, E-09)"
    - "code: `.pk-about-cta-spacer` height 4.5rem (app.css:2568) — CONFIRMED as 72/200px of the mobile void; zero contribution above 480px (E-06 EXP G)"
    - "code: `<main>`'s default `pb-20` (layouts.ex:664) — CONFIRMED, the single largest contributor at every width (E-06 EXP E)"
    - "code: `.pk-footer { margin-top: var(--pk-footer-offset) }` (app.css:1904) — CONFIRMED, 48px >=481px / 16px <=480px (E-06 EXP F)"
    - "code: shell `space-y-4` (layouts.ex:670) — CONFIRMED, and it lands TWICE on mobile (on #cierre and again on the spacer). Already diagnosed as G-01.5-2; 32 of 200 mobile px"
    - "config: the About page never opts into `bottom_collapse`/`boundary_collapse` (about_live.ex:52) — CONFIRMED. Both catalog callers do; About is the only one taking the full default bottom stack (E-10)"
    - "environment: mobile browser chrome making 100vh larger than the visible viewport — REFUTED, the 100vh rule is gated to >=640px and verified not to apply at 375/390/430/481/600/639px (E-03)"
    - "data: content length — REFUTED, the 64px asymmetry and the below-Cierre totals are invariant across 10 widths and 6 viewport heights (E-03, E-09)"
    - "code: a duplicate/leftover spacer element or stray padding — REFUTED, every in-flow node between #cierre and the footer was enumerated and each maps to a named, intentional declaration; nothing is orphaned (E-04)"
  and_gate: |
    Fires TWICE, in different ways, and the distinction drives the fix.

    ITEM 3 asymmetry — AND-gate YES. The 64px shift needs BOTH D-10's `padding-top:
    var(--pk-header-h)` (plan 01.5-03, commit 34e254c) AND D-14's tint (plan 01.5-04, commit
    4d77558) to be a defect. D-10's own comment states its premise: "the fixed header overlaps
    the band's top edge and visually eats into the top gap." That was TRUE when authored —
    #cierre was white and `.pk-nav`'s base-200 tint contrasted against it. D-14 then painted the
    band `--color-base-200`, the EXACT colour `.pk-nav` already was (both measured
    rgb(243,236,250), E-08), so the header now blends into the band and subtracts nothing. The
    compensation survived; the thing it compensated for did not. Neither plan is wrong on its
    own; the defect lives in their interaction, across two plans of the SAME phase.

    ITEM 3 volume — AND-gate NO. `min-height: 100vh` produces the huge gaps unaided and by
    design; this is an intent/proportion defect (a 157px content group in a 900px band), not an
    interaction.

    ITEM 4 — split answer. EXISTENCE: no single cause and no AND-gate; it is straightforward
    ADDITION of five independently-reasonable declarations, and removing any one leaves the rest
    (E-06). VISIBILITY: AND-gate YES — the identical `--color-base-200` on both `#cierre` (D-14)
    and `.pk-footer` is what turns trailing page space into a band-shaped void; stripping the
    tint alone removes the symptom while changing zero geometry (E-07).

reasoning_checkpoint_note: |
  Not filled — diagnose-only mode (goal: find_root_cause_only). No fix proposed or applied, so
  the pre-fix checkpoint gate does not run. `suggested_fix_direction` below is a direction with
  its constraints evidenced, not an implementation.

## Symptoms

expected: |
  Per phase 01.5 design decisions D-10/D-12, the Cierre band should fill the viewport with the
  heading/button/signature centered as a group with EVEN top/bottom gaps (despite header overlap),
  and there should be no extra unaccounted whitespace/empty band below the Cierre content before
  the footer.
actual: |
  User reported (verbatim, mobile):
  "3. the close \"nos vemos el sabado\" has a huge space top and bottom [screenshot: the Cierre
  band shows the heading/button/signature group vertically centered with a very large amount of
  empty space above and below it — the content occupies a small fraction of the band's height]
  4. also on the close band there are wrong white space and the bottom has bottom space from
  viewport [screenshot: below the Cierre content and BEFORE the footer starts, there is an
  additional distinct empty whitespace region — visually reads as its own extra band/gap, not
  padding attached to the Cierre content]
  5. also on the close band, the CTA doesn't have the correct balance"
  (item 5 already diagnosed by sibling investigation — Layouts.sumate_cta/1 min-h-12; out of scope)
errors: None reported
reproduction: |
  Visit /quienes-somos on mobile (375px), scroll to the Cierre band ("Nos vemos el sábado"
  heading + Sumate button + "PUKLLAY CLUB · SAN SALVADOR DE JUJUY, ARGENTINA" signature) at the
  bottom of the page, just before the footer.
started: Discovered during end-of-phase UAT for phase 01.5 (2026-09-08)

## Eliminated

- hypothesis: "D-10's `min-height: 100vh` leaks to mobile / miscalculates on mobile browser chrome"
  evidence: |
    The rule is inside `@media (min-width: 640px)` and the compiled stylesheet preserves that
    gate verbatim (`priv/static/assets/css/app.css:5029-5038`). Live CDP at 375/390/430/481/600/
    639px measures `#cierre` `min-height: 0px`, `display: block`, `align-items: normal`, band
    height 230px (<=480px) or 302px (481-639px), with an EVEN 72/72 split. Injecting
    `#cierre { min-height: auto !important }` at 390px changes NOTHING (band stays 230, docH
    stays 3858). The classic mobile-100vh-vs-browser-chrome bug cannot be involved: the rule
    never applies at any width a phone reports.
  timestamp: 2026-09-08

- hypothesis: "There is a duplicate / leftover spacer element or stray padding below #cierre"
  evidence: |
    Every direct child of the shell wrapper was enumerated with its computed box (E-04). There
    are 10; each is accounted for and intentional. Between `#cierre` and `<footer>` there is
    exactly ONE in-flow element (`.pk-about-cta-spacer`, and only at <=480px). The remaining
    children after it (`.pk-about-cta-bar`, `#pk-about-morph-mark`) are `position: fixed`, out
    of flow, contributing zero height; `<noscript>` is the `:last-child` and measures 0. Nothing
    is orphaned or duplicated — the void is the SUM of named declarations, not a stray node.
  timestamp: 2026-09-08

- hypothesis: "The below-Cierre void is band PADDING (a padding/background scoping mismatch)"
  evidence: |
    Control experiment E-06 EXP I: injecting `.pk-band { padding-top: 0 !important;
    padding-bottom: 0 !important }` collapsed `#cierre` from 230px to exactly its 86px content
    at 390px and shortened the document by 720px, yet `belowCierre` stayed at exactly 200px
    (144px at 768px) — unmoved. The void is margin + `<main>` padding, not band padding.
  timestamp: 2026-09-08

- hypothesis: "This is a D-14 (band tint) regression that should be fixed by retuning/reverting the tint"
  evidence: |
    D-14 changes only `background`. Stripping `#cierre`'s tint at runtime leaves `belowCierre`
    at exactly 200px/144px — every pixel of the void survives (E-07). D-14 is the EXPOSURE
    condition (it makes the void legible by putting base-200 above it, matching the base-200
    footer below it), not its cause. Reverting the tint would hide two real defects while
    deleting a deliberate decision — the same trap the sibling session
    `inter-band-whitespace-gap` recorded.
  timestamp: 2026-09-08

- hypothesis: "The huge top/bottom gaps come from the Cierre band's own `gap: 1.5rem` (D-12) or from `align-items: center`"
  evidence: |
    `#cierre .pk-band-inner`'s `gap: 1.5rem` is INSIDE the content group and is fully contained
    in the measured `innerH` (156.7px at 768px = h2 42.7 + 24 + cta 48 + 24 + meta 18). The
    gaps under investigation are OUTSIDE that box (`inner.top - band.top` and
    `band.bottom - inner.bottom`). `align-items: center` on `#cierre` only DISTRIBUTES the
    leftover space; with `min-height` neutralised there is no leftover and the band collapses to
    220.7px (E-05 EXP A). Neither is a source of space.
  timestamp: 2026-09-08

- hypothesis: "Item 5 (CTA balance) and the whitespace share a cause"
  evidence: |
    Out of scope by instruction and independently false: the Cierre CTA
    (`about_live.ex:831`, `<Layouts.sumate_cta />`) measures 48px tall at >=481px and is
    `display: none` at <=480px (D-11, app.css:5745). Zeroing its height would change `innerH` by
    48px against a 743px whitespace surplus at 768px — 6%. Confirmed only that this call site is
    subject to the sibling's `min-h-12` diagnosis; not re-investigated.
  timestamp: 2026-09-08

## Evidence

- timestamp: 2026-09-08
  id: E-01
  checked: "`lib/pukllay_club_web/live/about_live.ex:819-848` — the shipped Cierre markup and what follows it"
  found: |
    ```heex
    <section id="cierre" class="pk-band pk-band-tint">
      <div class="pk-band-inner pk-gutter text-center">
        <h2 class="font-display text-2xl">Nos vemos el sábado</h2>
        <div class="flex justify-center pk-about-cierre-cta"><Layouts.sumate_cta /></div>
        <p class="pk-about-eyebrow pk-about-closing-meta">Pukllay Club ·<br .../> San Salvador ...</p>
      </div>
    </section>
    <div class="pk-about-cta-spacer" aria-hidden="true"></div>
    <div class="pk-about-cta-bar"><Layouts.sumate_cta class="w-full" /></div>
    ```
  implication: |
    `.pk-about-cta-spacer` is a SIBLING of `#cierre`, not a child — so it is a direct child of
    the shell's `div.mx-auto.space-y-4` wrapper and collects its own 16px margin, and it sits
    physically BETWEEN the Cierre band and the footer. This is the structural precondition for
    both halves of item 4.

- timestamp: 2026-09-08
  id: E-02
  checked: "`assets/css/app.css:2656-2710` — the two rules that govern the Cierre band's geometry (plan 01.5-03, D-10/D-12)"
  found: |
    ```css
    #cierre .pk-band-inner { display:flex; flex-direction:column; align-items:center; gap:1.5rem; }

    @media (min-width: 640px) {
      #cierre { min-height: 100vh; display: flex; align-items: center;
                padding: var(--pk-header-h, 4.5rem) 0 0; }
      #cierre h2 { font-size: clamp(2rem, 4vw, 3rem); }
    }
    ```
    The `padding` shorthand REPLACES `.pk-band`'s shared `4.5rem 0` at this width, deliberately
    (the rule's own comment says so) — top becomes the header height, bottom becomes **0**.
    Compiled output preserves the media gate verbatim (`priv/static/assets/css/app.css:5029`).
  implication: |
    Three separate behaviours ride on one media block: the 100vh floor (volume), the header-height
    top padding (asymmetry), and the zeroed bottom padding (E-09). They can and should be
    reasoned about independently — the differential test does exactly that.

- timestamp: 2026-09-08
  id: E-03
  checked: "Live CDP width sweep of /quienes-somos on the running dev server, 10 widths x 844px height"
  found: |
    | width | bandH | innerH | gapTop | gapBottom | DELTA | CTA      | belowCierre |
    |-------|-------|--------|--------|-----------|-------|----------|-------------|
    | 375   | 230   | 86     | 72     | 72        | 0     | none     | 200         |
    | 390   | 230   | 86     | 72     | 72        | 0     | none     | 200         |
    | 430   | 230   | 86     | 72     | 72        | 0     | none     | 200         |
    | 481   | 302   | 158    | 72     | 72        | 0     | 48 flex  | 144         |
    | 600   | 302   | 158    | 72     | 72        | 0     | 48 flex  | 144         |
    | 639   | 302   | 158    | 72     | 72        | 0     | 48 flex  | 144         |
    | 640   | 844   | 156.7  | 375.7  | 311.7     | 64.0  | 48 flex  | 144         |
    | 768   | 844   | 156.7  | 375.7  | 311.7     | 64.0  | 48 flex  | 144         |
    | 1024  | 844   | 168.6  | 370.2  | 305.2     | 65.0  | 48 flex  | 144         |
    | 1280  | 844   | 168.6  | 370.2  | 305.2     | 65.0  | 48 flex  | 144         |
    DELTA tracks `--pk-header-h` exactly (64px at <=768, 65px at >=1024 — the header grows 1px
    when the brand wordmark is revealed).
  implication: |
    Three distinct regimes, and the reported symptom set spans two of them.
    * <=480px: band 230px, EVEN 72/72, CTA hidden (D-11), void 200px.
    * 481-639px: band 302px, EVEN 72/72, CTA visible, void 144px. Governed by NEITHER D-10's
      640px rule nor D-11's 480px rule.
    * >=640px: band = 100vh, gaps ~6x the content group, UNEVEN by exactly the header height.
    Item 3 ("vertically centered", huge even-ish gaps) is only reproducible at >=640px. Item 4
    is worst at <=480px. The user's "mobile" label therefore mislocates item 3's state — the
    same reported-vs-actual-state mismatch the knowledge-base entry
    `footer-desktop-overloaded` records as a recurring hazard in this codebase.

- timestamp: 2026-09-08
  id: E-04
  checked: "Full in-flow node walk from `#cierre`'s bottom edge to `<footer>`'s top edge, at 375/481/640/1280px"
  found: |
    Shell wrapper children in order (390px): hero div, #fotos, tint band, #faq, plain band,
    #cierre, `.pk-about-cta-spacer`, `.pk-about-cta-bar` (fixed), `#pk-about-morph-mark`
    (fixed), `<noscript>` (last-child, h=0).
    `<main>` siblings: `#app-header` (sticky, h=64), `#connection-status` (display:none),
    `<main class="pb-20 pt-8 sm:pt-20">`, `<footer class="pk-footer">` (margin-top 16px at
    <=480px / 48px above), `#flash-group` (h=0).
    Exact chain at 390px: cierre.bottom 3655.5 -> +16 margin -> spacer 3671.5..3743.5 (h=72)
    -> +16 margin -> main.bottom 3839.5 (pb-20 = 80px) -> +16 footer margin-top
    -> footer.top 3855.5.  Sum = 16+72+16+80+16 = **200** == measured.
    Exact chain at 768px: cierre.bottom -> +16 margin -> (spacer display:none)
    -> main pb-20 80 -> footer margin-top 48 -> footer.top.  Sum = 16+80+48 = **144** == measured.
  implication: |
    The void is fully enumerated with zero unexplained residual and zero stray nodes. It is the
    ADDITION of five (mobile) / three (desktop) declarations owned by four different decisions in
    three different files. No single one is a majority: the largest is `<main>`'s `pb-20` at
    80px (40% mobile / 56% desktop), and the `.pk-about-cta-spacer` the objective flagged as the
    likely culprit is only 72px (36% mobile / 0% desktop).

- timestamp: 2026-09-08
  id: E-05
  checked: "ITEM 3 differential: measure -> mutate -> restore, injected stylesheet, same page load, 390px and 768x900px"
  found: |
    768x900 (>=640px regime):
    | experiment                                  | bandH | innerH | gapT  | gapB  | delta | docH |
    |---------------------------------------------|-------|--------|-------|-------|-------|------|
    | BASELINE                                    | 900   | 156.7  | 403.7 | 339.7 | 64    | 4216 |
    | A: `min-height: auto`                       | 220.7 | 156.7  | 64    | 0     | 64    | 3536 |
    | B: `padding-top: 0`                         | 900   | 156.7  | 371.7 | 371.7 | **0** | 4216 |
    | C: both                                     | 156.7 | 156.7  | 0     | 0     | 0     | 3472 |
    | RESTORE                                     | 900   | 156.7  | 403.7 | 339.7 | 64    | 4216 |
    390x844 (<=480px regime): EXP A is a total no-op (230/86/72/72/0/3858 unchanged).
  implication: |
    Decisive and cleanly separable, with the effect reversible on the same page load.
    * `min-height: 100vh` is 100% of the whitespace VOLUME: removing it alone drops the band
      679.3px, and C shows the residual is exactly zero (band == content).
    * `padding-top: var(--pk-header-h)` is 100% of the ASYMMETRY: removing it alone drives the
      delta from 64 to exactly 0 and lands the gaps at an identical 371.7/371.7. Nothing else
      contributes to the unevenness the objective's D-10/D-12 "EVEN top/bottom gaps" expectation
      calls out.
    * The two are orthogonal — A does not fix the asymmetry, B does not fix the volume.

- timestamp: 2026-09-08
  id: E-06
  checked: "ITEM 4 differential: one contributor neutralised at a time, plus an all-four test and a padding control"
  found: |
    `belowCierre` (px), same page load, injected then removed:
    | experiment                              | 390px      | 768px      |
    |-----------------------------------------|------------|------------|
    | BASELINE                                | 200        | 144        |
    | D: kill shell `space-y-4` margins       | 168 (-32)  | 128 (-16)  |
    | E: kill `<main>` `pb-20`                | 104 (-96)  |  48 (-96)  |
    | F: kill `.pk-footer` `margin-top`       | 184 (-16)  |  96 (-48)  |
    | G: kill `.pk-about-cta-spacer`          | 112 (-88)  | 144 ( -0)  |
    | H: kill ALL FOUR                        | **0**      | **0**      |
    | I: CONTROL `.pk-band` padding -> 0      | 200 ( -0)  | 144 ( -0)  |
    | RESTORE                                 | 200        | 144        |
    D is -32 at 390px (TWO 16px margins: one on `#cierre`, one on the spacer) but -16 at 768px
    (spacer is display:none, so only one). E over-delivers by 16px in both regimes because
    removing `<main>`'s bottom padding lets the last child's bottom margin collapse through into
    the footer's own top margin instead of stacking. G is exactly 0 above 480px.
  implication: |
    Complete closure with zero residual (H drives it to exactly 0 at both widths), and the
    control proves it is not band padding. There is no "primary" contributor to find — the
    correct framing is that the About page's bottom boundary STACKS four independently-reasonable
    declarations, which is precisely the defect class quick task 260902-il3 already named and
    built a mechanism for (E-10).

- timestamp: 2026-09-08
  id: E-07
  checked: "Why the void reads as a distinct BAND: computed backgrounds of the void's two neighbours, plus a tint-strip falsification"
  found: |
    `#cierre` backgroundColor  = rgb(243, 236, 250)   (`.pk-band-tint` -> `--color-base-200`)
    `.pk-footer` backgroundColor = rgb(243, 236, 250) (`app.css:1902`, `--color-base-200`)
    `<html>` backgroundColor  = rgb(255, 255, 255)   (`--color-base-100`) — the void's painter
    Nothing between the void and `<html>` paints (`main`, the wrapper, `body` all transparent).
    Falsification: injecting `#cierre { background: transparent !important }` — geometry
    completely untouched, `belowCierre` still exactly 200px — makes the void merge into one
    continuous white run from the Contacto icons to the footer, and the "extra band" reading
    disappears. Screenshots: `mobile-390-bottom-baseline.png` vs `mobile-390-bottom-NOTINT.png`.
  implication: |
    The void is a 144-200px unpainted strip sandwiched between two surfaces painted the SAME
    token. That is what makes it read as "its own extra band/gap" rather than as ordinary
    trailing page space. Mechanism and observed pixels agree, and it is the identical exposure
    shape the sibling session `inter-band-whitespace-gap` found at the tint->#faq boundary —
    here at 9-12x the magnitude. Dark theme is affected identically (base-100 `#170A26` void
    between two `#22103A` surfaces).

- timestamp: 2026-09-08
  id: E-08
  checked: "D-10's stated premise — 'the fixed header overlaps the band's top edge and visually eats into the top gap' (app.css:2677-2692)"
  found: |
    `#app-header` is `position: sticky; top: 0`, height 64px (65px at >=1024px), its own
    background transparent. The painted surface is `.pk-nav`:
    ```css
    .pk-nav { background: var(--color-base-200); border-bottom: 1px solid transparent; }
    .pk-nav.is-scrolled { background: color-mix(in srgb, var(--color-base-200) 94%, transparent);
                          border-bottom-color: var(--color-base-300);
                          box-shadow: 0 1px 0 color-mix(... base-content 8% ...); }
    ```
    Measured live over the Cierre band: `.pk-nav` computes rgb(243,236,250) undocked and
    color(srgb 0.952941 0.92549 0.980392 / 0.94) docked — i.e. `--color-base-200`, at 94% alpha
    over `#cierre`'s own `--color-base-200`. Identical colour. Delineation is at most a 1px
    base-300 hairline + a 1px shadow. Screenshot `tablet-768-cierre-top.png` shows the header
    and the band as one continuous surface.
    Git: D-10's rule landed `34e254c` (plan 01.5-03); `.pk-band-tint` on `#cierre` landed
    `4d77558` (plan 01.5-04, D-14) — same phase, later plan.
  implication: |
    D-10's compensation was CORRECT when written: `#cierre` was still plain white then, and the
    header's base-200 tint genuinely covered ~64px of contrasting band. D-14 then painted the
    band that exact colour, so the header no longer subtracts anything visible — but the 64px
    downward shift it compensates for is still applied unconditionally. The correction outlived
    the condition it corrected. This is why the band's group sits low AND why the geometric
    split is uneven by exactly `--pk-header-h`.

- timestamp: 2026-09-08
  id: E-09
  checked: "Short-viewport behaviour of D-10's `padding: var(--pk-header-h) 0 0` (its zeroed BOTTOM padding), 4 viewport heights at >=640px width"
  found: |
    | viewport   | bandH | innerH | gapTop | gapBottom |
    |------------|-------|--------|--------|-----------|
    | 768 x 220  | 220.7 | 156.7  | 64     | **0**     |
    | 768 x 300  | 300   | 156.7  | 103.7  | 39.7      |
    | 900 x 400  | 400   | 162    | 151.5  | 86.5      |
    | 1280 x 600 | 600   | 178    | 243.5  | 178.5     |
    gapTop - gapBottom == exactly `--pk-header-h` at every single row.
  implication: |
    Two things. (1) The 64/65px asymmetry is INVARIANT to viewport height as well as width — it
    is structural, not a rounding artifact. (2) The shorthand's `0` bottom value is a latent
    third defect in the same rule: once the 100vh floor is exhausted (short window, or a longer
    signature), the closing signature sits FLUSH against the tinted band's bottom edge with zero
    breathing room, because D-10 silently dropped `.pk-band`'s shared 4.5rem bottom padding at
    this width and relies entirely on 100vh leftover to replace it.

- timestamp: 2026-09-08
  id: E-10
  checked: "`Layouts.app`'s bottom-boundary attrs and which callers opt in (`layouts.ex:133-151`, `:661-666`; `app.css:5053-5099`)"
  found: |
    `bottom_collapse` (quick task 260902-il3) renders `main.pk-bottom-collapse` instead of
    `pb-20`, giving `padding-bottom: 0` plus `main.pk-bottom-collapse + .pk-footer
    { margin-top: 1.5rem }`. Its own CSS comment states the defect it was built for verbatim:
    "the catalog page's bottom boundary stacked three independently-reasonable declarations,
    live-measured: `<main>`'s own bottom padding (80px) + `.pk-shelf`'s own trailing margin
    (48px at 1280px / 32px at 390px) + `.pk-footer`'s own top margin (48px at 1280px / 16px at
    390px) = 176px at 1280px / 128px at 390px combined."
    Callers: `catalog_live/index.ex:889` passes `bottom_collapse`;
    `catalog_live/show.ex:267` passes `boundary_collapse` (owns both ends);
    `about_live.ex:52` passes `flash fullbleed sticky active_nav` — **neither**.
    Simulating `bottom_collapse` at runtime (`main{padding-bottom:0}` +
    `.pk-footer{margin-top:1.5rem}`): `belowCierre` 144 -> **24** at 768px, 200 -> **112** at 390px.
  implication: |
    The About page is the ONLY one of the three `Layouts.app` callers still taking the full
    default bottom stack — and its numbers (144/200px) are the same magnitude as the 176/128px
    the catalog page was already fixed for. This is not a novel defect needing a novel remedy;
    it is a known, named, already-solved defect class that About was never wired into. The
    residual 112px on mobile after simulating the attr is the `.pk-about-cta-spacer`'s 72px +
    margins, which the attr does not and should not know about.

- timestamp: 2026-09-08
  id: E-11
  checked: "Whether `.pk-about-cta-spacer` actually clears the element it exists to clear, measured at page bottom, 390px"
  found: |
    `.pk-about-cta-bar` is `position: fixed; left:0; right:0; bottom:0` (app.css:2554-2564),
    73px tall, always covering the bottom 73px of the VIEWPORT. `.pk-about-cta-spacer`
    (`height: 4.5rem` = 72px) is placed in document flow BEFORE `<footer>`. Measured scrolled to
    page bottom: `barCoversFooter: true` — footer occupies viewport y=3815.4..3858.4 relative to
    an un-scrolled origin, and the bar sits over its lower portion. Visible directly in
    `mobile-390-page-bottom.png`: the Sumate bar overlays the footer's BGG attribution row.
  implication: |
    The spacer does not protect the page's last content from the fixed bar — the footer, which
    comes after it, is still overlaid. Its 72px (plus its own 16px shell margin) therefore
    reads as pure dead whitespace inserted between the Cierre band and the footer, i.e. it
    contributes to item 4 without delivering the clearance it was added for. Whoever fixes this
    should decide whether the spacer belongs after the footer or should be removed in favour of
    `scroll-padding`/footer padding — it is a placement question, not a height question.

- timestamp: 2026-09-08
  id: E-12
  checked: "Existing test coverage for D-10/D-12 and for the page's bottom boundary"
  found: |
    `01.5-PATTERNS.md` specifies the D-10/D-12 assertions as "min-height/gap CSS-source check",
    and the D-14 assertions as class-attribute/CSS-source checks. Every one is a
    source-text oracle over `app.css` or the rendered class list. None observes rendered
    vertical geometry, a gap RATIO, or a boundary SUM. There is no test anywhere in the repo
    asserting anything about `#cierre`'s height relative to its content, the evenness of its
    top/bottom gaps, or the distance from the last band to the footer.
  implication: |
    The defect was structurally invisible to the gate meant to cover it: the tests assert that
    `min-height: 100vh` IS PRESENT — which is exactly the declaration causing item 3 — so they
    would pass on the bug and FAIL on the fix. Same pattern as all four prior UI entries in the
    knowledge base: nothing in this toolchain observes rendered geometry, so a 743px whitespace
    surplus and a 200px void fail nothing in CI.

## Resolution

root_cause: |
  THREE root causes across the two reported items. Items 3 and 4 are independent defects that
  the D-14 band tint made legible at the same moment.

  ─── ITEM 3a — the whitespace VOLUME (>=640px only) ────────────────────────────────────
  `assets/css/app.css:2701` — `@media (min-width: 640px) { #cierre { min-height: 100vh } }`
  (plan 01.5-03, D-10, commit 34e254c). The Cierre band's content group is 156.7-178px tall
  (heading + 24px gap + 48px button + 24px gap + signature); the rule floors the band at a full
  viewport, so `align-items: center` distributes 680-745px of leftover as top/bottom emptiness —
  the content occupies ~17% of the band. Neutralising `min-height` alone collapses the band from
  900px to 220.7px, exactly the leftover, with zero residual (E-05). The rule is doing precisely
  what D-10 specified; the defect is that a three-element closing signature is not enough content
  to carry a full-viewport "destination" band. Verified NOT to apply below 640px (E-03).

  ─── ITEM 3b — the top/bottom gaps being UNEVEN, by exactly the header height ───────────
  `assets/css/app.css:2704` — `padding: var(--pk-header-h, 4.5rem) 0 0` in the same rule.
  This is 100% of the asymmetry and nothing else contributes: gapTop - gapBottom == exactly
  `--pk-header-h` (64px, 65px at >=1024px) at every one of 5 widths and 6 viewport heights
  measured, and neutralising the padding alone drives the delta to exactly 0 with gaps landing at
  an identical 371.7/371.7 (E-05, E-09). This directly contradicts the stated D-10/D-12
  expectation of "EVEN top/bottom gaps (despite header overlap)".

  The compensation was correct when authored and was invalidated by a later plan in the same
  phase. D-10's comment states its premise — the header "overlaps the band's top edge and
  visually eats into the top gap while nothing touches the bottom gap" — which held while
  `#cierre` was plain white and `.pk-nav`'s `--color-base-200` tint contrasted against it. D-14
  (plan 01.5-04, commit 4d77558) then gave `#cierre` `.pk-band-tint`, i.e. `--color-base-200`:
  the EXACT colour `.pk-nav` already was. Both measure rgb(243,236,250); the docked header is
  that same colour at 94% alpha over itself, separated only by a 1px base-300 hairline (E-08).
  The header now blends into the band and subtracts nothing — but the 64px downward shift
  compensating for it is still applied unconditionally. AND-gate: neither D-10 nor D-14 is wrong
  alone; the defect lives in their interaction.

  Latent third defect in the same declaration: the shorthand's `0` bottom value drops
  `.pk-band`'s shared 4.5rem bottom padding at >=640px, so once the 100vh floor is exhausted
  (measured at 768x220: gapBottom == 0) the signature sits flush against the tinted band's bottom
  edge (E-09).

  ─── ITEM 4 — the extra empty band below Cierre, before the footer ─────────────────────
  No single cause: the About page's bottom boundary STACKS five (<=480px) / three (>=481px)
  independently-reasonable declarations owned by four different decisions in three files. Every
  one was isolated and the sum closes to exactly zero residual (E-04, E-06):

    <=480px, 200px total          |  >=481px, 144px total
    ------------------------------|---------------------------------
    16px  shell `space-y-4`       |  16px  shell `space-y-4`
          (layouts.ex:670, on     |        (layouts.ex:670, on #cierre)
          #cierre) — G-01.5-2     |
    72px  `.pk-about-cta-spacer`  |   —    (display:none above 480px)
          (app.css:2568)          |
    16px  shell `space-y-4` AGAIN |   —
          (on the spacer itself)  |
    80px  `<main>` `pb-20`        |  80px  `<main>` `pb-20`
          (layouts.ex:664)        |        (layouts.ex:664)
    16px  `.pk-footer` margin-top |  48px  `.pk-footer` margin-top
          (app.css:1904, <=480px) |        (app.css:1904, 3rem)

  The largest contributor is `<main>`'s `pb-20` (40% mobile / 56% desktop); the
  `.pk-about-cta-spacer` the objective flagged as the likely culprit is 36% on mobile and 0%
  above 480px. Killing all four drives the distance to exactly 0px; the `.pk-band` padding
  control leaves it completely unmoved (E-06).

  Why it reads as a distinct BAND rather than as trailing page space (the exposure condition,
  AND-gate YES): the whole 144-200px strip is unpainted and shows `<html>`'s `--color-base-100`
  white, sandwiched between two surfaces painted the SAME token — `#cierre`'s new D-14
  `.pk-band-tint` above and `.pk-footer`'s own `background: var(--color-base-200)`
  (app.css:1902) below. Stripping ONLY the tint, geometry untouched, leaves all 200px in place
  yet makes the void merge into a continuous white run and the "extra band" reading vanish
  (E-07). The space is pre-existing shell boundary stacking; D-14 is what made it legible.

  This defect class is already named and solved in this repo. `Layouts.app`'s `bottom_collapse`
  attr (layouts.ex:142-151, quick task 260902-il3) exists for exactly it — its CSS comment
  records the catalog page's identical measured stack ("176px at 1280px / 128px at 390px
  combined"). `catalog_live/index.ex:889` passes `bottom_collapse`; `catalog_live/show.ex:267`
  passes `boundary_collapse`; **`about_live.ex:52` passes neither** — it is the only one of the
  three `Layouts.app` callers still taking the full default bottom stack (E-10).

  Secondary, and a placement question rather than a spacing one: `.pk-about-cta-spacer` does not
  achieve what it was added for. The fixed `.pk-about-cta-bar` still overlays the footer at page
  bottom (`barCoversFooter: true`, visible in `mobile-390-page-bottom.png`), because the spacer
  sits BEFORE the footer in flow (E-11).

fix: "NOT APPLIED — diagnose-only mode (goal: find_root_cause_only)."

verification: |
  n/a — no fix applied. Root causes established by measure-mutate-restore differential testing on
  the running dev server via CDP, with controls: item 3's two halves each isolated to exactly one
  declaration (E-05), item 4's five contributors each isolated and summing to zero residual
  (E-06), a `.pk-band` padding control confirming neither is band padding (E-06 EXP I), and a
  tint-strip control confirming D-14 is the exposure condition and not the cause (E-07).

files_changed: []

suggested_fix_direction: |
  Three separable pieces of work. Do not fold them into one edit — they have different owners,
  different blast radii, and one of them is a design decision rather than a bug fix.

  (1) ITEM 3a (volume) — needs a DESIGN decision, not a code fix, and should go back to the
      developer before anything is changed. `min-height: 100vh` on a 157px content group is
      D-10 working as specified. The options are: drop the full-viewport treatment entirely
      (band falls to 220.7px); reduce the floor (e.g. `min-height: 70svh`); or give the band
      more content to justify the height. Note `100vh` should probably become `100svh`/`100dvh`
      regardless — a 640px-wide device in landscape does exist and `vh` ignores mobile browser
      chrome. Whoever decides this should look at `tablet-768-cierre-top.png` first.

  (2) ITEM 3b (asymmetry) — a real bug with a clear fix: remove
      `padding: var(--pk-header-h, 4.5rem) 0 0` from `#cierre`'s >=640px block, restoring
      `.pk-band`'s shared `4.5rem 0`. E-05 EXP B shows this alone lands the gaps at an exactly
      even 371.7/371.7, and it simultaneously closes the latent zero-bottom-padding defect
      (E-09). The header no longer eats the top gap, so there is nothing left to compensate for
      (E-08). **Update D-10's comment when doing this** — the comment is a careful, correct
      record of a premise that D-14 later invalidated, and deleting the padding without
      rewriting the rationale would leave the next reader with an explanation for code that is
      no longer there. If any residual overlap compensation is still wanted, it belongs on
      `scroll-margin-top` (which the file already uses with this token), not on padding that
      shifts the centring point at every scroll position.

  (3) ITEM 4 — pass `bottom_collapse` on `about_live.ex:52`. This is the mechanism built for
      this exact defect (E-10) and needs no new CSS: measured effect 144 -> 24px at 768px and
      200 -> 112px at 390px. Then decide separately about `.pk-about-cta-spacer`'s remaining
      88px on mobile, which `bottom_collapse` does not and should not touch — E-11 shows it is
      misplaced (it sits before the footer and so fails to clear the fixed bar from the footer
      it overlays), so this is a placement fix, not a height retune.

  Constraints the fixer must respect (all evidenced, not guesses):
  - Do NOT revert or retune D-14's tint. Stripping it leaves every pixel of both defects in
    place (E-07) while deleting a deliberate decision — the same trap the sibling session
    `inter-band-whitespace-gap` recorded.
  - Do NOT treat `.pk-about-cta-spacer` as the primary cause of item 4. It is 36% on mobile and
    exactly 0% above 480px (E-06 EXP G), yet the void is 144px at every width >=481px.
  - Do NOT touch the shell's `space-y-4` or `<main>`'s `pb-20` directly — both are load-bearing
    for the catalog pages (`catalog_live/show.ex:292` documents depending on the 16px), which is
    precisely why the opt-in `bottom_collapse` attr exists.
  - Do NOT assume "mobile". Item 3 is only reproducible at >=640px; at <=480px the Cierre band
    is 230px with an even 72/72 split identical to every other band (E-03). Item 4 IS worse on
    mobile (200 vs 144). Any fix must be checked in all three regimes — <=480px, the ungoverned
    481-639px middle band, and >=640px.
  - `#cierre .pk-band-inner`'s `gap: 1.5rem` (D-12) is NOT implicated and must not be retuned to
    compensate — it lives inside the content group and is fully contained in the measured
    `innerH`.
  - A recurrence guard for this class needs GEOMETRIC oracles, not the CSS-source assertions
    01.5 shipped: the existing D-10 test asserts `min-height: 100vh` is present, so it would
    pass on the bug and fail on the fix (E-12). The two assertions that would actually bite are
    (a) `#cierre`'s top and bottom gaps must be equal within 1px, and (b) the distance from the
    last `.pk-band`'s bottom to `<footer>`'s top must be under a stated budget — plus a cheap
    ExUnit contract test that every `Layouts.app` caller passes one of `bottom_collapse` /
    `boundary_collapse` or documents why not.

## Assets

Captured to `.planning/debug/assets/cierre-band-whitespace/`:

- `tablet-768-cierre-top.png` — item 3 at >=640px: the 157px group inside a 900px band.
- `mobile-390-page-bottom.png` — item 4 at <=480px: the 200px white void between the tinted
  Cierre band and the tinted footer, with the fixed Sumate bar overlaying the footer (E-11).
- `mobile-390-bottom-NOTINT.png` — the E-07 falsification: same geometry, tint stripped, the
  "extra band" reading gone.
- `mobile-390-bottom-SIMCOLLAPSE.png` / `tablet-768-bottom-SIMCOLLAPSE.png` — simulated
  `bottom_collapse` (E-10).
- plus `*-cierre-top.png` / `*-bottom-baseline.png` at 390/768/1280.
