---
status: resolved
trigger: "User reported (with screenshot) on /quienes-somos at mobile width, scrolled to the true page bottom: 'Still I see a grey area between the CTA sticky bar and the footter'"
created: 2026-09-10
updated: 2026-09-10
resolved: 2026-09-10
---

## Symptoms

- **Expected behavior:** After quick task 260910-av6 (sketch 053 winner D), the footer's "Powered by BGG" line should sit with clean, intentional breathing room directly above the new full-width sticky CTA bar — the reserved document-end clearance (`calc(var(--pk-about-cta-bar-h) + 1rem)` padding-bottom on body) should read as deliberate spacing.
- **Actual behavior:** User's screenshot shows: the footer's lavender/purple background band (containing "Powered by BGG") ends abruptly right after that line, then a visually distinct plain white/light-gray band appears below it, then the dark purple CTA bar starts. The uncolored band reads as an unstyled gap/bug rather than intentional spacing — described by the user as a "grey area" between the bar and the footer.
- **Error messages:** None — purely visual.
- **Timeline:** Introduced by quick task 260910-av6 (commit range c6295aa..ac174b6, docs 829f27d), which replaced the content-sized floating pill CTA bar with a full-width bar and added a live-measured `body` `padding-bottom` clearance region. This clearance region is new — before this quick task, the bar was a floating pill with no reserved document-end space, so this uncolored band did not exist in this form before.
- **Reproduction:** Load `/quienes-somos` at <=480px width (or use device emulation), scroll to the true bottom of the document. The gap between the footer content and the CTA bar is visible without any further interaction.

## Current Focus

bug_class: **Bohrbug** — fully deterministic. Reproduces on every load, at every scroll-to-bottom, in both themes, with byte-identical geometry across all runs (gap = 15.609375px, every time). No timing, no concurrency, no flake. SBFL not applicable (CSS paint defect; no test suite observes computed geometry).

hypothesis: CONFIRMED — see `reasoning_checkpoint` below.

next_action: NONE — session closed. Fix applied, guardrail accepted, human verification CONFIRMED ("Confirmed fixed" — the footer's lavender now runs continuously into the bar's top edge, no pale/grey strip), session archived to `.planning/debug/resolved/`. The one escalation lever recorded in Eliminated (`body:has(.pk-about-cta-bar) .pk-footer { padding-bottom }`) was NOT needed and must NOT be applied — 11.61px reads adequate to the reporter.

reasoning_checkpoint:
  hypothesis: "The `+ 1rem` term added to the document-end clearance in `body:has(.pk-about-cta-bar)` (app.css:6409) reserves 16px MORE scroll space than the fixed bar occupies. That residue is `body` padding, which lies OUTSIDE the footer's border-box and therefore paints the PAGE background (`--color-base-100`), not the footer's page-scoped `--color-base-300` fill. So exactly 1rem of page background is permanently visible between the footer's bottom edge and the bar's top border at the true page bottom."
  confirming_evidence:
    - "DIRECT MEASUREMENT (CDP, 390x844): footer bottom = 759.39, bar top = 775.00, gap = 15.609375px. `document.elementFromPoint` at the gap's midpoint returns BODY — the gap is the body's own padding box, not any element."
    - "COMPUTED STYLE: body padding-bottom = 85px; `--pk-about-cta-bar-h` = 69px (published live by .AboutCtaBarMeasure). 85 - 69 = 16px = the `+ 1rem` term exactly. The residue IS the added term, arithmetically, with nothing left over."
    - "PIXEL ROW SCAN (light, CSS x=20): footer paints rgb(227,211,240) (base-300) down to y=759, then the band y=759..775 paints rgb(252,252,252)..rgb(237,236,238), then the bar's 1px border rgb(107,91,123) at y=775, then the bar interior rgb(255,255,255) (base-100). Three surfaces where the design has two."
    - "SKETCH SOURCE CONTRADICTS THE PORT: sketch 053's own JS sets `clearance.style.height = barHeight + 'px'` — the bar height EXACTLY, no additive term. Its README promises 'no overlap, no vanishing bar, no leftover empty gap'. The `+ 1rem` exists in NO sketch; it was added during the port."
    - "FALSIFICATION TEST PASSED (live CSS patch via CDP, both themes): with the clearance set to `var(--pk-about-cta-bar-h)` alone, gap goes 15.609375px -> -0.390625px and the row scan shows the footer's fill running CONTINUOUSLY to the bar's hairline (light: 227,211,240 -> 211,195,224 shadow-graded; dark: 47,23,80 -> 45,22,77). The third surface disappears entirely. Screenshots confirm visually in both themes."
  falsification_test: "Set the clearance to `var(--pk-about-cta-bar-h)` with no additive term and re-measure. If the uncolored band SURVIVED, or if the footer's fill still failed to reach the bar's border, the hypothesis would be refuted (the band would have to be coming from some other box). RESULT: band eliminated, gap -0.39px, footer fill continuous to the hairline. Hypothesis survives."
  fix_rationale: "Deleting the `+ 1rem` removes the root cause itself, not a symptom: it is the entire and only source of the residue (85 - 69 = 16, exact). It does NOT paper over the band by tinting it — it deletes the space that had nothing to paint it. It also restores fidelity to sketch 053, which the port had silently departed from. The breathing room the `+ 1rem` was reaching for already exists and is already correctly painted: `.pk-footer-row`'s own 12px bottom padding at <=480px, INSIDE the footer's lavender box. The port double-counted one spacing concern across a surface boundary."
  blind_spots:
    - "Perceptual sufficiency of 11.61px of breathing above the bar's border (was 27.61px) is measured, not proven adequate to a human — routed to the human-verify checkpoint, per the search-right-align-mobile-cycle-3 precedent that measurement establishes MECHANISM, not PERCEPTUAL SUFFICIENCY."
    - "Verified only in headless Chrome 151; not on a real iOS/Android browser where dynamic viewport chrome moves `bottom: 0`. Mitigated: the mechanism is a static box-model residue with no viewport-unit dependency, so browser chrome cannot reintroduce it."
    - "Not tested with a browser that lacks `:has()` support — but that is pre-existing to this rule, not introduced here."
  candidate_causes:
    - "code / CSS-layout: the `+ 1rem` overshoot reserves more than the bar occupies, and the residue is body padding painting page background — CONFIRMED, necessary AND sufficient."
    - "code / CSS-colour: the bar's own fill is `--color-base-100`, the SAME token as the page background, so the gap and the bar's 10px top padding merge into ONE ~27px pale band whose only internal marker is a 1px hairline — AMPLIFIER, not necessary. In dark theme the two measure rgb(22,9,37) vs rgb(23,10,38): a 1-unit difference, i.e. literally indistinguishable, which is why the band reads even larger there."
    - "code / CSS-effect: the bar's `box-shadow: 0 -6px 16px` paints a gradient UP over the gap, darkening it monotonically 252 -> 237 — AMPLIFIER, explains why the reporter said 'grey area' rather than 'white gap'. Harmless once the shadow falls on the footer's lavender instead (measured 227,211,240 -> 211,195,224, ordinary elevation)."
    - "config / environment: NONE — every figure is byte-identical across both themes and across repeated runs; no env var, viewport unit, or device metric participates."
    - "data: NONE — no dynamic or user content participates; the band renders from static CSS box geometry alone."
  and_gate: "NO. Cause 1 alone reproduces the defect and cause 1 alone eliminates it — proved by the single-term falsification patch, which changed nothing about the bar's fill or its shadow and still removed the band completely in both themes. Causes 2 and 3 are magnitude and colour amplifiers that explain the reported SEVERITY and the word 'grey', not co-necessary conditions. Deliberately recorded because the tempting fixes both target the amplifiers — retinting the bar, or dropping its shadow — and BOTH would leave the 16px band in place."

## Eliminated

- hypothesis: "The footer element fails to stretch to the document end (a sticky-footer / short-page defect), leaving page background below it."
  evidence: "Refuted twice over. (a) `document.scrollHeight` = 3623 and the footer's bottom + body padding-bottom = 759.39 + 85 = 844.39 = body's own bottom edge exactly — the footer IS the last in-flow box and there is no unaccounted space. (b) G-01.5-9 already measured /quienes-somos ARITHMETICALLY INCAPABLE of the short-page defect (footer bottom at exactly `scrollHeight`, 0.00px residual, every width, both themes). This band is deliberately-reserved padding, not a short-page residue — a different mechanism that happens to paint the same colour."
  timestamp: 2026-09-10

- hypothesis: "The fix is to break the surface-token equality — retint the bar (base-200/base-300) so it stops matching the page background, as plan 01.5-11 did for the #cierre/footer boundary (G-01.5-8)."
  evidence: "Refuted by the falsification patch, which left the bar's fill BYTE-IDENTICAL and still eliminated the band. Retinting attacks amplifier 2 and would leave all 16px of the gap in place — it would only recolour it. Additionally, plan 01.5-10's own 6-arm differential already proved base-200 for this bar 'inert on the reported symptom and worse at the real page bottom', and the FULL LADDER ARITHMETIC recorded at app.css:5674-5684 shows no pair in this app's surface ladder clears 3:1 in either theme."
  timestamp: 2026-09-10

- hypothesis: "The fix is to drop or shrink the bar's `box-shadow`, since the band is grey rather than white because of it."
  evidence: "Refuted by the same patch, which left the shadow untouched and still removed the band. The shadow is amplifier 3: it explains the reporter's word choice ('grey'), not the band's existence. With the gap closed the shadow lands on the footer's lavender (227,211,240 -> 211,195,224) and reads as ordinary elevation — it becomes correct rather than needing removal."
  timestamp: 2026-09-10

- hypothesis: "Move the `1rem` breathing step INSIDE the footer (`body:has(.pk-about-cta-bar) .pk-footer { padding-bottom: 1rem }`) so it paints lavender, keeping the total spacing."
  evidence: "Geometrically valid and it would also fix the band, but rejected as non-minimal and as a departure from the design source. It would put 12px (the footer's own `--pk-footer-pad-block` retune) + 16px = 28px between the BGG line and the bar's border, against sketch 053's 16px. Deleting `+ 1rem` yields 11.61px, far closer to the sketch, and requires no new rule. Recorded by name as the ready one-line escalation if the human-verify checkpoint says 11.61px reads cramped — reach for it as a tuning step, not a re-diagnosis."
  timestamp: 2026-09-10

- hypothesis: "The sibling detail-page mechanism (`body.pk-has-cta-bar`, app.css:4747) shares this defect and must be fixed in the same pass."
  evidence: "Refuted by reading it: its `padding-bottom: 9.25rem` is derived to be EXACTLY the bar's own clearance with no breathing overshoot (arithmetic recorded in its own comment: 200 - 44 - 8 = 148px), and it collapses to 0 via `body.pk-cta-parked` on the `footerReached` flag, so its bar parks before the footer and no uncolored band can ever show there. Different mechanism, no defect, left untouched."
  timestamp: 2026-09-10

## Evidence

- timestamp: 2026-09-10
  checked: "Knowledge base + resolved-session sweep for prior art on this boundary."
  found: "Three near-miss neighbours, all DISTINCT from this one. G-01.5-5-cierre-footer-gap: a gap ABOVE the footer (#cierre -> footer margin), fixed with `margin-top: 0`. G-01.5-8-cierre-tagline-footer-grouping: two same-token bands MERGING, fixed with a page-scoped fill change to base-300 — that fix is why this page's footer is lavender at all. G-01.5-9-footer-not-pinned-bottom: page background below a SHORT page's footer, measured impossible on this route."
  implication: "No prior session covers the footer's BOTTOM boundary against the fixed bar. This is new ground, and G-01.5-8's fix (a fill change) is specifically the wrong template here — see Eliminated."

- timestamp: 2026-09-10
  checked: "Live CDP geometry at 390x844, scrolled to true document bottom, /quienes-somos."
  found: "body padding-bottom 85px; `--pk-about-cta-bar-h` 69px (published on documentElement as an inline style, hook wired); footer rect 716.39..759.39 (h=43); bar rect 775..844 (h=69); gap 15.609375px; `elementFromPoint` at the gap midpoint = BODY; footer background rgb(227,211,240); bar background rgb(255,255,255); body background rgba(0,0,0,0) with html at rgb(255,255,255)."
  implication: "85 - 69 = 16 = the `+ 1rem` term exactly. The gap is the body's padding box painting the propagated canvas background. Root cause localized to one term in one declaration."

- timestamp: 2026-09-10
  checked: "Pixel row scan at CSS x=20 down the bottom 190px, both themes."
  found: "LIGHT: base-200 #cierre (243,236,250) -> footer base-300 (227,211,240) to y=759 -> band (252,252,252) grading to (237,236,238) at y=775 -> border (107,91,123) 1px -> bar interior (255,255,255) -> button (28,32,39) at y=787. DARK: footer (47,23,80) to y=759 -> band (22,9,37) -> border (184,166,204) -> bar interior (23,10,38)."
  implication: "Two findings. (1) The band is a monotonic GRADIENT, not a flat fill — that is the bar's own upward box-shadow painting onto white, which is why the reporter said 'grey'. (2) In dark theme the band (22,9,37) and the bar interior (23,10,38) differ by ONE unit per channel: the 16px gap and the bar's 10px padding are a single indistinguishable 27px field interrupted by a bright hairline. The hairline reads as a stray line INSIDE a grey area rather than as the bar's edge — precisely the user's description."

- timestamp: 2026-09-10
  checked: "sketch 053 source (`index.html` + README), the design this was ported from."
  found: "`clearance.style.height = barHeight + 'px'` — the live-measured bar height EXACTLY, no additive term. `.footer-clearance { background: var(--color-bg) }` (page background, harmless there because the region is 100% covered by the bar). `.about-footer { padding: 16px 20px }` supplies the breathing. README: 'no overlap, no vanishing bar, no leftover empty gap.'"
  implication: "The `+ 1rem` is a PORT ARTIFACT with no source in the design. The sketch's clearance is exactly the bar height and its breathing room lives in the footer's own padding, inside the footer's fill. The port relocated that breathing step outside the footer's box, where nothing paints it, and the README's 'no leftover empty gap' is the exact promise the port broke."

- timestamp: 2026-09-10
  checked: "Footer internal spacing at <=480px."
  found: "`.pk-footer` padding 0; `.pk-footer-row` padding-block 12px (the `--pk-footer-pad-block` mobile retune); the one visible child `.pk-footer-legal` (the BGG attribution, right-aligned) at 729.39..747.39. So BGG-line bottom -> footer bottom = 12px, all lavender; then 15.61px of page background; then the hairline."
  implication: "Breathing room between the BGG line and the bar ALREADY exists and is already correctly painted — 12px of the footer's own decided rhythm. The `+ 1rem` double-counted that concern, and did so on the wrong side of a surface boundary. Confirms deletion is the right lever, not relocation."

- timestamp: 2026-09-10
  checked: "`.AboutCtaBarMeasure` hook rounding (about_live.ex:917)."
  found: "`Math.ceil(this.el.getBoundingClientRect().height)`, guarded by `height > 0` and `height !== this.lastHeight`."
  implication: "The published height is always >= the real height, so a clearance of `var(--pk-about-cta-bar-h)` with no slack can never be SHORT. Verified in the patch: the gap goes to -0.390625px, i.e. the footer's edge sits a sub-pixel PAST the bar's top edge, and that sub-pixel lands inside the footer's 12px padding, never on text. The T-QUICK-04 threat (bar covering 'Powered by BGG') does not recur — measured clearance from the BGG line to the bar's border is 11.61px."

- timestamp: 2026-09-10
  checked: "FALSIFICATION EXPERIMENT — injected `@media (max-width: 480px){ body:has(.pk-about-cta-bar){ padding-bottom: var(--pk-about-cta-bar-h, ...) } }` live via CDP, both themes, nothing else changed."
  found: "body padding 85px -> 69px; scrollHeight 3623 -> 3607; footer-to-bar gap 15.609375 -> -0.390625px; BGG-line-to-bar-border 27.609375 -> 11.609375px. Row scan after: LIGHT footer (227,211,240) runs continuously y=732..775 grading to (211,195,224) under the shadow, then the hairline, then the bar. DARK (47,23,80) -> (45,22,77), then the hairline. Screenshots in both themes show the lavender/purple footer meeting the bar's hairline with no intervening surface."
  implication: "Root cause CONFIRMED and fix VALIDATED before any file was edited. One term, one declaration, both themes, no other rule touched."

## Resolution

root_cause: "The document-end clearance `body:has(.pk-about-cta-bar) { padding-bottom: calc(var(--pk-about-cta-bar-h) + 1rem) }` (app.css:6409) reserves 1rem MORE scroll space than the fixed bar occupies. That 16px residue is `body` padding — outside the footer's border-box — so it paints the page background (`--color-base-100`) instead of the footer's page-scoped `--color-base-300` fill, putting a permanently-visible third surface between the footer and the bar. The `+ 1rem` is a port artifact: sketch 053 sizes its clearance to the bar height EXACTLY and puts the breathing room in the footer's own padding, and this page's footer already supplies that (12px, lavender). The port double-counted one spacing concern across a surface boundary. Two amplifiers explain the reported severity but are not co-necessary: the bar's fill is the same `--color-base-100` token as the page background, merging the 16px gap with the bar's own 10px top padding into one ~27px pale field (indistinguishable in dark theme, 1 unit per channel); and the bar's upward `box-shadow` grades that field 252 -> 237, which is why it reads 'grey' rather than 'white'."

fix: "ONE TERM DELETED. `assets/css/app.css:6409` — `padding-bottom: calc(var(--pk-about-cta-bar-h, calc(10px + 48px + 10px + 1px)) + 1rem)` becomes `padding-bottom: var(--pk-about-cta-bar-h, calc(10px + 48px + 10px + 1px))`. The reservation is now the bar's live-measured height and nothing else, matching sketch 053's own `clearance.style.height = barHeight + 'px'`. Deliberately NOT a retint of the band and NOT a shadow change — both were measured inert on the band's existence (see Eliminated). The derived fallback is preserved verbatim: the `+` signs INSIDE it compose the bar's real parts and are legitimate; only the top-level additive term was the defect. The comment above the rule is rewritten to record why no additive term may return here, and to name the correct lever if the boundary ever reads cramped (`body:has(.pk-about-cta-bar) .pk-footer { padding-bottom }`, which grows the footer's OWN painted box). Safe with zero slack because `.AboutCtaBarMeasure` publishes `Math.ceil(height)`."

verification:
  guardrail_verdict: accepted
  signal_1_reproduces_before_fixed_after: "PASS — pre-fix (real tree): body padding 85px, footer-to-bar gap 15.609375px. Post-fix (real tree, dev server rebuilt): 69px, -0.390625px. Both themes identical. Visually confirmed in both themes: the footer's fill now runs continuously to the bar's 1px hairline with no intervening surface."
  signal_2_revert_reproduces: "PASS — `git stash push -- assets/css/app.css` restored body padding to 85px and the gap to 15.609375px, the exact original figures, then `git stash pop` restored the fix. The bug is causally attached to this change, not to an environmental coincidence."
  signal_3_regression_sweep: "PASS — CDP sweep, 11 widths (320/360/390/414/430/479/480/481/640/1024/1280) x 2 themes x 3 routes. /quienes-somos <=480px: body padding 69px at every width, gap -0.39..+0.41px (flush, sub-pixel), BGG-line-to-bar 11.61..12.41px and NEVER negative (T-QUICK-04 does not recur). Threshold co-location intact: 480px = bar on + 69px reserved, 481px = bar off + 0px reserved, no width with one and not the other. `/` and `/juegos/1`: body padding 0px at EVERY width in both themes — the fix is fully page-scoped and touched nothing off this route. Zero horizontal overflow at every width. Both themes byte-identical throughout."
  signal_4_not_deletion_only: "PASS — the deletion is justified by measured arithmetic (85 - 69 = 16px, the removed term exactly) and by the design source (sketch 053 has no additive term and its README promises 'no leftover empty gap'). The diff is +52/-5 in app.css: one term removed, ~50 lines of comment added recording the mechanism, the two amplifiers proven non-causal, and the correct future lever."
  signal_5_regression_guard_bites: "PASS — all three guarding assertions RED-VERIFIED against the real pre-fix tree via `git stash`, each failing with its intended diagnostic and quoting the exact defective declaration; green after `pop`. A silent revert must now argue with three tests across two files."
  signal_6_quality_gate: "PASS — `mix quality` exit 0, 903 tests, 0 failures (hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted incl. Styler, credo --strict, sobelow, test). `mix format` produced zero rewrites on the new test file, so no Styler behaviour-change review was needed."
  signal_7_human_confirm: "PASS — the reporter reloaded `/quienes-somos` at mobile width, scrolled to the TRUE document bottom (the only place this defect renders) and confirmed verbatim: 'Confirmed fixed' — the footer's lavender background now runs continuously into the CTA bar's top edge with no pale/grey strip visible. No further changes requested. This closes the loop on the ORIGINAL report ('Still I see a grey area between the CTA sticky bar and the footter') using the reporter's own reproduction path, not a proxy for it."

  human_check_outstanding: "RESOLVED — CONFIRMED by the reporter on 2026-09-10. Original concern, kept verbatim: 'Perceptual sufficiency of 11.61px of breathing between the \"Powered by BGG\" line and the bar's top border (was 27.61px, of which 15.61px was the uncoloured band). Measurement establishes MECHANISM, not PERCEPTUAL SUFFICIENCY — the search-right-align-mobile-cycle-3 precedent. Routed to the human-verify checkpoint.' OUTCOME: 11.61px reads adequate — the reporter confirmed the boundary without qualification and asked for nothing further. The escalation lever held ready in the Eliminated list (`body:has(.pk-about-cta-bar) .pk-footer { padding-bottom: 1rem }`, which would restore the 1rem INSIDE the footer's painted box) was therefore NOT needed and must NOT be applied. It stays recorded as the correct one-line lever should this boundary ever be re-reported as cramped — reach for it as a TUNING step, never as a re-diagnosis, and never re-add an additive term to the body clearance, which is the defect itself."

oracle_type: "derived (contract) — the true oracle is rendered geometry (the distance from the footer's painted bottom edge to the bar's top border), which ExUnit cannot observe. The assertions pin the CSS contract that geometry depends on, following about_band_width_test.exs and footer_rhythm_test.exs. Boundary neighbours are deliberately paired in OPPOSITE directions around the fixed defect's equivalence class: 'no top-level calc()' rejects re-adding ANY additive term (+0.5rem, +8px, +2rem — not just the +1rem that shipped), while 'fallback stays a derived calc(10px + 48px + 10px + 1px)' rejects the opposite wrong fix of flattening the fallback to a pre-added literal."

files_changed:
  - "assets/css/app.css — dropped the `+ 1rem` additive term from the `body:has(.pk-about-cta-bar)` document-end clearance (the fix); rewrote the comment paragraph that justified it."
  - "test/pukllay_club_web/about_cta_bar_clearance_test.exs — NEW, 4 tests: no top-level calc() (the equivalence class), fallback stays derived (opposite boundary neighbour), exactly one clearance rule, clearance co-located with the bar's display swap in the same 480px block."
  - "test/pukllay_club_web/live/about_live_test.exs — RETARGETED two pre-existing tests that had encoded the old `calc(...)` shape as a contract. Both were the gate working, so both were retargeted rather than deleted, and both still go RED on a revert. Their intent (pin the JS-publishes/CSS-consumes seam; never a bare literal) is unchanged and now ALSO rejects the additive form; the anti-drift assertion follows the derivation into the var()'s fallback."

## Prevention

<!-- Blameless postmortem. No person or agent is at fault here: a comment written in good
     faith documented an intent that CSS could not honour, and the one gate that touched
     this declaration had been pinned to a SHAPE rather than to a property. -->

branching_5_whys: |
  Branched per RCA discipline rather than chained, so the answer does not collapse into a
  single "someone typed the wrong number".

  WHY 1 — Why was an uncoloured band visible between the footer and the CTA bar?
    Because 16px of `body` padding-bottom sat below the footer's border-box and above the
    bar's top edge, painting the propagated page background.

  WHY 2 — Why was there padding there that nothing covered?
    Because the reservation was `calc(var(--pk-about-cta-bar-h) + 1rem)` while the fixed bar
    occupies exactly `--pk-about-cta-bar-h`. An additive term is, BY CONSTRUCTION, the one
    part of the reservation the bar can never cover.

  WHY 3 — Why was an additive term written at all?
    Two branches converge, and BOTH are needed to explain it:
      (a) INTENT: the author wanted breathing room between the "Powered by BGG" line and the
          bar, and said so in the comment ("the deliberate breathing step ... so it stays
          outside the fallback's parenthesization"). The intent was legitimate.
      (b) MODEL: the author reasoned about DISTANCE (16px between two things) without
          reasoning about WHICH BOX PAINTS that distance. `body` padding lies outside
          `.pk-footer`'s border-box, so the space had no fill. The same 16px placed one box
          inward would have been invisible and correct.

  WHY 4 — Why did the surface-boundary error survive review and the port?
    Because the breathing room it was reaching for ALREADY EXISTED, correctly painted, one
    box inward: `.pk-footer-row`'s 12px `--pk-footer-pad-block` at this breakpoint. The port
    double-counted one spacing concern across a surface boundary, and a double-count reads as
    generosity, not as a bug, in source. Compounding it: sketch 053 — the design source — has
    NO additive term (`clearance.style.height = barHeight + 'px'`) and its README explicitly
    promises "no leftover empty gap", so the port departed from its own source in the one
    place the source was most specific. Nothing compares a port against its sketch.

  WHY 5 — Why was there no gate?
    See `why_not_caught` — and note the sharp answer: a gate DID exist on this exact
    declaration, and it MANDATED the defect.

why_not_caught: |
  Branch A — CODE / AUTHORING (no affordance existed). The defect is not a typo; the source
  reads as correct and self-justifying. CSS offers no signal for "you reserved space in a box
  that paints nothing" — `calc(var(--x) + 1rem)` is valid, well-formed, and expresses a
  perfectly ordinary intent. Code review by inspection had no lever: catching it requires
  asking which BORDER-BOX owns the reserved region, which is a question about the box model,
  not about the declaration.

  Branch B — CONFIG / TOOLING (structurally blind). `mix quality` (hex.audit, deps.audit,
  deps.unlock --check-unused, format+Styler, credo --strict, sobelow, test) parses ELIXIR
  sources only and never evaluates `app.css`. Tailwind v4 / LightningCSS exits 0 CORRECTLY —
  this is valid CSS, not an error, not a warning, not a degraded state. ExUnit cannot observe
  rendered geometry at all, which is why the guard written here is necessarily a CONTRACT
  oracle rather than the true one. There is still no visual-regression or headless-layout gate
  in CI; that remains the standing structural gap for every CSS-behaviour defect in this repo.

  Branch C — THE EXISTING GATE, WHICH MANDATED THE DEFECT (the finding worth carrying).
  Two pre-existing tests in `about_live_test.exs` asserted `padding-bottom: calc(` on THIS
  declaration. They were written for a real, twice-observed drift bug (a hard `4.5rem`
  literal that was 3px loose against the 69px bar and became 1px TIGHT when plan 01.5-10 grew
  the Sumate button to 48px), and their intent — "derive, don't restate" — was and remains
  correct. But they pinned the IMPLEMENTATION SHAPE (`calc(`) instead of the INVARIANT (the
  value is derived from the bar's own parts and reserves nothing beyond them). Because a
  top-level `calc()` is the ONLY way to add a term to this value, the shape they required had
  silently become the shape the bug needs: after the correct fix, both tests went RED on
  CORRECT code. A mechanism-pinned guard fails in both directions — false-positive on a
  legitimate fix, and false-negative on the defect it was standing next to the whole time.
  THIRD instance of this exact failure mode in this repo (`footer_overflow_test.exs` banned
  the existence of a wide max-width block as a proxy; `header_search_gutter_test.exs` pinned
  the literal `inset` shorthand). Standing rule, now on its third confirmation: a guard must
  assert the INVARIANT it protects, not the IMPLEMENTATION that happened to satisfy it. Both
  tests were RETARGETED rather than deleted — they were the gate working, and both still go
  RED on a revert.

  Branch D — UAT / PROCESS (a genuinely narrow window). The band renders ONLY at the true
  document bottom, ONLY at <=480px, ONLY on `/quienes-somos`. Scrolled anywhere else the
  fixed bar overlays content and the reservation is entirely invisible; at 481px the bar and
  its clearance both switch off together. So the one place it shows is the one place a
  hand-check of a sticky bar rarely goes — you check that the bar floats, not that the
  document ENDS correctly beneath it. And the diagnosis was already in the repo in plain
  language: sketch 053's README promises "no leftover empty gap" and its JS sizes the
  clearance to the bar height exactly. FOURTH consecutive session in this repo where the
  answer was already written down and still did not stop the bug — a written observation is
  not a guard; only an executable assertion is.

  Branch E — ENVIRONMENT / DATA: NONE, and that is a real finding rather than an omission.
  Every figure is byte-identical across both themes and across repeated runs; no env var,
  viewport unit, device metric, or dynamic content participates. This is a static box-model
  residue, which is precisely why a static contract assertion can fence it.

recurrence_guard: |
  PRIMARY — `test/pukllay_club_web/about_cta_bar_clearance_test.exs` (NEW, 4 tests, runs
  inside `mix test` and therefore inside `mix quality` and CI). All RED-verified against the
  real pre-fix tree via `git stash`, each failing with its intended diagnostic:
    1. "reserves the bar's live-measured height and NOTHING more" — `refute
       String.starts_with?(value, "calc(")`. Because a top-level calc() is the only way to
       add a term, this ONE assertion is the whole equivalence class: it rejects `+ 1rem`,
       `+ 0.5rem`, `+ 8px` and `+ 2rem` identically, instead of pinning the literal that
       happened to ship. Paired with `assert String.starts_with?(value, "var(--pk-about-cta-bar-h")`
       so the JS-publishes/CSS-consumes seam stays pinned.
    2. "fallback stays DERIVED from the bar's own declared parts" — the OPPOSITE boundary
       neighbour, guarding the other wrong fix: flattening the fallback to a pre-added `69px`
       while removing the additive term would pass test 1 and silently re-open the drift bug
       that the pre-existing gate was originally written for. The `+` signs INSIDE the
       fallback are legitimate (they compose the bar's real parts) and are required to stay.
    3. "exactly one body:has(.pk-about-cta-bar) rule" — a second rule could re-add reserved
       space without ever touching the declaration the other assertions guard.
    4. "clearance is co-located with the bar's display swap" — no `@media` may sit between
       them, so "bar appears" and "clearance is reserved" cannot drift to different
       thresholds. This guards T-QUICK-04 (bar covering "Powered by BGG"), the opposite-sign
       failure of the one just fixed.
  Load-bearing implementation detail: the file strips CSS comments before matching. That is
  not boilerplate here — the fix deliberately documents the removed `+ 1rem` at length in a
  comment directly above the rule, so without stripping, every assertion would match the
  prose describing the bug.

  SECONDARY — `test/pukllay_club_web/live/about_live_test.exs`, two tests RETARGETED from
  mechanism to invariant (see Branch C). "...clearance is derived, not a bare literal" now
  asserts `padding-bottom: var(` plus the derived fallback, following the derivation INTO the
  var()'s fallback where it now lives; the seam test now asserts
  `padding-bottom: var(--pk-about-cta-bar-h` directly instead of requiring the `calc(`
  wrapper that existed solely to hold the defective term. Both keep their original intent,
  both now ALSO reject the additive form, and both still go RED on a revert. A silent revert
  must now argue with three tests across two files.

  TERTIARY — DOCUMENTATION-AS-GUARD. The comment above the rule was rewritten (~50 lines,
  +52/-5 in the diff) to record: why an additive term here is structurally a bug rather than
  merely unfaithful; the measured figures (footer bottom 759.39, bar top 775.00, band
  15.61px); that the two tempting fixes were MEASURED INERT (the bar's `--color-base-100`
  fill matching the page background, and its upward box-shadow grading the band 252 -> 237 —
  amplifiers that explain the reported severity and the word "grey", not the cause); and that
  the correct lever, if this boundary ever reads cramped, is
  `body:has(.pk-about-cta-bar) .pk-footer { padding-bottom }`, which grows the footer's OWN
  painted box. The previously-wrong justification paragraph was corrected in place, not left
  standing — the `header-capacity` lesson that an INCORRECT derivation left in the source
  actively causes the next author to reproduce the bug.

  MOST LIKELY REGRESSION PATH: someone re-reports this boundary as cramped (11.61px, down
  from an apparent 27.61px) and "fixes" it by re-adding an additive term to the body
  clearance — the single most natural edit, and an exact reproduction of the defect. Test 1
  fires immediately and its failure message names the correct lever. SECOND path: a future
  bar-geometry change flattens the fallback to a literal while keeping the var() primary,
  which reads as a simplification and re-opens the original drift bug; test 2 fires.

## Assets

Captured to `.planning/debug/assets/cta-bar-footer-gap-uncolored/`:
- `mobile-390-light-BEFORE.png` / `mobile-390-dark-BEFORE.png` — the defect at 390x844,
  scrolled to the true document bottom, both themes. The light shot shows the reported
  "grey area": a 15.61px band between the footer's lavender and the bar's hairline, graded
  rather than flat because the bar's upward box-shadow paints onto it. The dark shot is the
  more damning of the two — the band (22,9,37) and the bar's interior (23,10,38) differ by
  ONE unit per channel, so the 16px gap and the bar's 10px top padding read as a single
  ~27px field interrupted by a bright stray line, which is exactly the user's description.
- `mobile-390-light-AFTER.png` / `mobile-390-dark-AFTER.png` — the same two views post-fix:
  the footer's fill runs continuously into the bar's 1px border with no intervening surface,
  and the box-shadow now grades the footer's own lavender (227,211,240 -> 211,195,224 light;
  47,23,80 -> 45,22,77 dark), reading as ordinary elevation instead of as a defect.
- `compare.png` — the four views side by side. The single most useful image here: it shows
  that NOTHING moved except the band's disappearance — the bar, its border, its shadow and
  the footer's content are all in identical positions, which is the visual form of the
  arithmetic (85 - 69 = 16, the removed term exactly, with nothing left over).
