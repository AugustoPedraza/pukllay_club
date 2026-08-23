---
status: resolved
trigger: "Found as a side-discovery during the header-height-wordmark-wrap debug session (.planning/debug/resolved/header-height-wordmark-wrap.md once archived), not independently reported by the user: the site footer overflows horizontally at roughly 481-652px viewport width. That session's own measurement showed the footer's scrollWidth pinned at 653px in that band, tracing into the .pk-footer-right -> .pk-footer-meta -> .pk-bgg-note chain, which only switches to a column layout at <=480px (same shape of gap as the header bug: a mobile override that stops one breakpoint too early). Different component, different root cause from the header sessions — recorded here as its own session per user decision, not folded into either header session."
created: 2026-08-23T00:00:00.000Z
updated: 2026-08-23T01:40:00.000Z
---

## Current Focus

bug_class: Bohrbug — deterministic, width-driven CSS layout. Reproduces identically on every reload at a
  given viewport width (the sibling session measured the same 653px scrollWidth across a 13-width sweep).
  Route per taxonomy: deterministic reproduction -> binary search over the breakpoint band. SBFL skipped
  (Phase 1.25 gate not met: no test suite exercises rendered CSS geometry, so there is no per-test coverage
  spectrum to rank).

known_pattern_candidate: none in knowledge-base.md. The only KB entry
  (search-expand-header-overlap) is a dropped-CSS-rule/comment-terminator cause and its error patterns
  (getComputedStyle disagreeing with declared CSS, rule missing from cascade) do NOT match here — the
  footer rules below are all present and applying. Not a match; investigating from first principles.
  The nearer prior art is the sibling header session's "mobile override stops one breakpoint too early"
  shape, which is a hypothesis to TEST, not a diagnosis to assume.

hypothesis: CONFIRMED by measurement (see Evidence 01:12/01:14/01:16). `.pk-footer-right` is a
  non-wrapping `display: flex` row whose min-content width (602.8px) is a hard floor it sits on at
  every viewport from 481px to 660px.

reasoning_checkpoint:
  hypothesis: "`.pk-footer-right` is a flex row with no `flex-wrap`, whose four children (two of them
    `white-space: nowrap` text runs, two of them fixed-size icon rows) each default to
    `min-width: auto` = their min-content. The cluster's minimum is therefore the SUM of the four
    (530.9px) plus 3x1.5rem gaps (72px) = 602.8px, and the real ink reaches 652.8px because
    `.pk-bgg-note` spills 18px past its squeezed parent. That 652.8px is invariant to viewport width,
    so every viewport from 481px (where the ≤480px override stops collapsing the cluster) to 652px
    overflows horizontally by exactly 652.8 minus the viewport width."
  confirming_evidence:
    - "Direct, not inferred: `.pk-footer-right`'s measured width EQUALS its separately-measured
      `width: min-content` (602.8 = 602.8) at 481/500/560/600/640/652/660px — it is provably sitting on
      its floor, which is why narrowing the viewport moves it zero pixels."
    - "The floor's composition is arithmetic, not a guess: social 136 + toggle-tag 31.1 +
      theme-toggle 136 + meta 227.8 = 530.9, plus 3 gaps x 24 = 602.9, matching the measured 602.8."
    - "The band's edges are measured, not estimated: overflow 172px at 481, 153 at 500, 93 at 560,
      53 at 600, 13 at 640, 1 at 652, 0 at 660 — a clean linear decay to zero exactly where the
      viewport reaches the invariant 652.8px ink edge."
    - "The shallowest overflowing box in a depth-ordered walk is `.pk-footer-right` itself (depth 4),
      with `.pk-footer-meta` (5) and `.pk-bgg-note` (6) merely inside it."
    - "The 18px discrepancy between the cluster box (634.8) and scrollWidth (653) is fully accounted
      for by the measured 18px BGG logo `<img>` spilling out of the squeezed meta span — no
      unexplained residue."
    - "Two independently-written harnesses (sibling session's drive-live.js, this session's footer.js)
      report the identical 653px against the running app."
  falsification_test: "Add `flex-wrap: wrap` to the cluster and re-measure. If the diagnosis is right,
    the cluster's min-content must drop from the SUM of its children to the MAX of them (602.8 ->
    ~245.8), the cluster must reflow onto 2 lines in the band, and documentElement.scrollWidth must
    equal clientWidth at every width from 260px to 1280px. If scrollWidth stays pinned at 653 after
    wrapping is enabled, the floor is not coming from the flex line-packing and the hypothesis is wrong."
  fix_rationale: "The defect is that the cluster has exactly one line to place four items on and no
    escape. `flex-wrap: wrap` changes the cluster's minimum from `sum(children)` to `max(children)` —
    a structural change to how the floor is COMPUTED, not a tuned value that happens to fit today's
    content. It is also the footer's own established idiom: `.pk-footer-row` (app.css:895) and
    `.pk-footer-links` (app.css:912) already declare `flex-wrap: wrap`; the two cluster divs are the
    only flex containers in the footer that omit it, which reads as an omission rather than a decision.
    Crucially it hides nothing — the alternative (extending the ≤480px `display: none` override up
    through the band) is eliminated, because the drawer those controls supposedly relocate into is
    itself `display: none` above 480px."
  blind_spots:
    - "Headless Chrome at devicePixelRatio 1 only; no real tablet hardware, no iOS Safari. Flex line
      packing is spec-defined and unlikely to differ, but it is unobserved."
    - "The fix makes the footer TALLER in the band (the right cluster reflows to 2 lines). That is
      correct behaviour, but whether the resulting stacked arrangement looks right is a visual
      judgement measurement cannot make — it needs the human-verify checkpoint."
    - "Font-swap: all measurement is post-`document.fonts.ready`. A slow connection rendering the
      Inter fallback briefly could produce different text widths; with wrapping enabled this now
      degrades into an extra wrapped line rather than overflow, but it is untested."
    - "`.pk-footer-meta` keeps `white-space: nowrap`, so the cluster retains a 245.8px single-item
      floor. Measured as safe (417px available at the band's worst point, and no overflow anywhere
      from 260px up) but it IS the remaining hard floor in this component."
  candidate_causes:
    - "code (CSS): `.pk-footer-left, .pk-footer-right` (app.css:899-904) declares `display: flex` with
      no `flex-wrap`, so four items must share one line — CONFIRMED as the binding constraint."
    - "code (CSS): `white-space: nowrap` on `.pk-footer-meta` (:986) and `.pk-footer-toggle-tag` (:980)
      raises each text child's min-content to its full single-line width — CONTRIBUTING, it is what
      makes the per-child terms of the sum large, but not sufficient alone (the icon rows and gaps are
      375px of the 602.8px floor on their own)."
    - "config (breakpoint): every mitigation — columning, hiding 3 of 4 children, and the
      2rem->0.875rem gutter — is gated behind the single `@media (max-width: 480px)` block, while the
      content actually needs 653px+ — REAL, and it is why the band exists at all. Rejected as the
      fix site because the ≤480px treatment depends on a drawer that does not exist above 480px."
    - "environment (engine/fonts): engine-specific flex or text metrics — REFUTED, see Eliminated."
    - "data (content length): the dynamic copyright year and the BGG attribution string set the meta's
      width — REAL but not causal here; meta is only 38% of the floor and the year is always 4 digits."
  and_gate: "YES — the bug requires two conditions simultaneously: (a) all four children are present
    and over-subscribe one line, AND (b) the cluster has no reflow escape. Below 481px (a) is false
    (three children are hidden, floor collapses to 227.8px) and there is no bug even though (b) still
    holds. Above 660px (b) still holds but (a) is false and there is no bug. Both must be true, and
    they are true together only in 481-652px.
    Unlike the sibling header session — which had to attack both conditions because removing only one
    CONVERTED the wrap into overflow — removing (b) here is sufficient AND introduces no new failure
    mode, because the outcome of reflow is a taller footer (benign) rather than overflow (the defect).
    Deliberately NOT also stripping the meta's nowrap: measurement shows it causes no overflow at any
    width from 260px to 1280px, so changing it would be an unevidenced edit."

test: DONE — applied `flex-wrap: wrap` to the shared `.pk-footer-left, .pk-footer-right` base rule and
  re-ran the identical sweep, the revert check, the mutation checks and `mix quality`.
expecting: MET on every prediction. scrollWidth == clientWidth at all 18 widths 260-1536px; the
  cluster's min-content dropped 602.8 -> 227.8 (max(children), as predicted by the falsification test);
  nothing hidden at any width; >=700px and <=480px geometry byte-identical to the pre-fix baseline.
next_action: NONE — session closed. The human-verify checkpoint was answered CONFIRMED FIXED on
  2026-08-23: the user reviewed before-481.png / after-481.png / after-700.png and approved the fix,
  explicitly accepting the 3-row reflow in the 481-652px band as correct ("clean fix, footer overflow
  eliminated, reflows to a 3rd row in the 481-652px band only, no change outside it"). That resolves
  the one open blind spot measurement could not settle — the design judgement on the stacked
  arrangement. Fix committed as a725c4b; this file archived to .planning/debug/resolved/; the
  knowledge-base entry (with its Prevention block) appended. Dev server on http://localhost:4321 is
  no longer needed for this session.

## Symptoms

expected: The site footer should never cause horizontal overflow/scroll at any viewport width — content should wrap or reflow to fit, same as the header's now-fixed behavior.
actual: At roughly 481-652px viewport width, the footer overflows horizontally (document/footer scrollWidth pinned at ~653px regardless of narrower viewport width). The `.pk-footer-right` -> `.pk-footer-meta` -> `.pk-bgg-note` chain appears responsible; footer switches to a column layout only at <=480px, leaving this band unhandled.
errors: None expected — pure CSS/layout issue, same class as the two header bugs in this debugging session (no JS errors reported for those).
reproduction: Load any page with the site footer (footer appears to be shared across pages via layouts.ex), resize the browser to a width between ~481px and ~652px, observe horizontal overflow/scrollbar.
started: Pre-existing — discovered 2026-08-23 as a side-effect of investigating the header wordmark-wrap bug; not caused by either header fix. Likely present since the footer's `@media (max-width: 480px)` column override was first built, since it only covers <=480px.

## Eliminated

- hypothesis: (carry-over from the sibling session's side-discovery, stated in this session's own
    trigger) "Same shape of gap as the header bug: a mobile override that stops one breakpoint too
    early" — i.e. the fix is to move/extend the `@media (max-width: 480px)` footer override so the
    481-652px band gets the same treatment.
  evidence: Refuted as a FIX PATH by app.css:1007-1008 + 1754-1764. That override hides
    `.pk-footer-social`, `.pk-footer-toggle-tag` and `.pk-theme-toggle` on the explicit justification
    (its own comment, app.css:1805-1810) that they "move into the drawer" — but `.pk-nav-hamburger`,
    `.pk-drawer` and `.pk-drawer-backdrop` are ALL `display: none` at base and only switched on inside
    that same ≤480px query. Above 480px there is no drawer to move anything into. Extending the hide
    would silently delete all four social links and the entire theme control from every viewport in the
    band. The mechanism-level half of the carry-over ("mitigations gated one breakpoint too low") is
    correct and retained; the proposed remedy is not.
  timestamp: 2026-08-23T01:19:00Z

- hypothesis: The offender is `.pk-footer-meta` / `.pk-bgg-note` (the chain the sibling session named),
    so shrinking, wrapping or hiding the copyright/BGG line resolves the overflow.
  evidence: Refuted by per-child measurement at 481px. `.pk-footer-meta` accounts for 227.8px of the
    cluster's 602.8px floor (38%); the other 375px is social (136) + toggle-tag (31.1) + theme-toggle
    (136) + 3x1.5rem gaps (72). The shallowest overflowing box is `.pk-footer-right` at depth 4, not
    the meta at depth 5. Removing the meta line entirely would still leave a ~351px + gutters floor,
    i.e. still overflowing below ~415px — and would delete D-04's required BGG attribution, which
    app.css:1808-1810 states must stay visible at every viewport width.
  timestamp: 2026-08-23T01:14:00Z

- hypothesis: Engine/environment-specific flex or text-measurement behaviour (a headless-Chrome or
    font-loading artifact rather than a real property of the shipped page).
  evidence: Refuted three ways. (1) The harness awaits `document.fonts.ready` and serves the real
    self-hosted woff2 files through the running app, the fidelity gap the sibling session closed. (2)
    Two independently-written harnesses (the sibling's drive-live.js and this session's footer.js)
    report the same 653px scrollWidth across the same band. (3) The behaviour is spec-defined: a flex
    item's default `min-width: auto` resolves to its min-content size, and a `white-space: nowrap` run
    has no break opportunity — this is deterministic, not engine-dependent. Bug class recorded as
    Bohrbug on this basis.
  timestamp: 2026-08-23T01:22:00Z

## Evidence

- timestamp: 2026-08-23T01:00:00Z
  checked: `.planning/debug/knowledge-base.md` (Phase 0 — semantic + keyword match against this session's
    symptoms; MemPalace not available in this environment, so the file is the fallback per protocol).
  found: One entry only — `search-expand-header-overlap`. Its error patterns are about a CSS rule being
    silently DROPPED from the cascade (premature `*/`, getComputedStyle disagreeing with source). Overlap
    with this session is limited to the generic "purely visual, no console errors" token.
  implication: No usable prior hypothesis. Do not anchor on the comment-terminator cause. Investigate
    from the markup/CSS directly.

- timestamp: 2026-08-23T01:02:00Z
  checked: The footer's real markup — `footer/1` in lib/pukllay_club_web/components/layouts.ex:555-578.
  found: `.pk-footer-row` (max-w-7xl + pk-gutter) holds exactly two clusters. `.pk-footer-left` =
    `<.brand_logo tagline="Conectá jugando" />` + `.pk-footer-links` (FAQ/Contacto/Juntadas).
    `.pk-footer-right` = `.pk-footer-social` (4 icons) + `.pk-footer-toggle-tag` ("Tema") +
    `.pk-theme-toggle` (3 buttons) + `.pk-footer-meta` (`© {year} Pukllay Club · <.bgg_attribution />`).
  implication: `.pk-footer-right` carries FOUR independent children, not one. The sibling session named
    `.pk-footer-meta`/`.pk-bgg-note` as the offender, but that was a depth-first walk to the deepest
    node — it does not establish that the meta line alone is the binding constraint. All four children
    must be measured before blaming one.

- timestamp: 2026-08-23T01:03:00Z
  checked: The footer CSS block, assets/css/app.css:883-999, and the `@media (max-width: 480px)`
    override block at app.css:1799-1815.
  found: Base rules — `.pk-footer-row` is `flex; flex-wrap: wrap; justify-content: space-between;
    gap: 0.75rem 1.5rem`. `.pk-footer-left, .pk-footer-right` are `flex; align-items: center;
    gap: 1.5rem` with NO `flex-wrap`, NO `min-width: 0`, NO `flex-shrink` control.
    `.pk-footer-toggle-tag` (:980) and `.pk-footer-meta` (:986) each declare `white-space: nowrap`.
    The ≤480px block does two separate things: (a) `.pk-footer-row, .pk-footer-left, .pk-footer-right
    { flex-direction: column }` and (b) `display: none` on `.pk-footer-right .pk-theme-toggle`,
    `.pk-footer-toggle-tag` and `.pk-footer-social` (they move into the mobile drawer). It also drops
    `--pk-gutter` from 2rem to 0.875rem (app.css:1712-1715).
  implication: Every mitigating force in this design — columning, hiding three of four children, and a
    56% narrower gutter — is gated behind ONE breakpoint at 480px. Above it, `.pk-footer-right` is an
    unwrappable, non-shrinking row containing two `nowrap` text runs. `flex-wrap: wrap` on the parent
    `.pk-footer-row` lets the two CLUSTERS stack, but that does nothing for a single cluster that is
    itself wider than the viewport. This is the mechanism to confirm by measurement.

- timestamp: 2026-08-23T01:12:00Z
  checked: Rebuilt the sibling session's CDP harness for the footer (scratchpad/footer.js, adapted from
    its already-live-validated drive-live.js) and swept the RUNNING Phoenix app at localhost:4321,
    14 widths 375-1280px, measuring documentElement scrollWidth/clientWidth, both footer clusters,
    every child of `.pk-footer-right`, each cluster's directly-measured `width: min-content`, and a
    shallowest-first walk of every element whose box exceeds the viewport.
  found: |
    w     clientW scrollW ovf   right.w  right.min-content  left.w  left.min-content  gutter    dir
    375   375     375     0     245.8    227.8              201.1   76                0.875rem  column
    440   440     440     0     245.8    227.8              201.1   76                0.875rem  column
    470   470     470     0     245.8    227.8              201.1   76                0.875rem  column
    481   481     653     172   602.8    602.8              408.1   169.6             2rem      row
    500   500     653     153   602.8    602.8              408.1   169.6             2rem      row
    560   560     653     93    602.8    602.8              408.1   169.6             2rem      row
    600   600     653     53    602.8    602.8              408.1   169.6             2rem      row
    640   640     653     13    602.8    602.8              408.1   169.6             2rem      row
    652   652     653     1     602.8    602.8              408.1   169.6             2rem      row
    660   660     660     0     602.8    602.8              408.1   169.6             2rem      row
    700   700     700     0     620.8    602.8              408.1   169.6             2rem      row
    1280  1280    1280    0     620.8    602.8              408.1   169.6             2rem      row
  implication: The hypothesis is CONFIRMED and quantified. `.pk-footer-right` measures EXACTLY its own
    min-content width (602.8 = 602.8) at every viewport from 481px to 660px — it is sitting on a hard
    floor and further narrowing the viewport moves it not at all, which is precisely why scrollWidth is
    pinned. Below 481px the same cluster's floor collapses to 227.8 and the overflow vanishes; at ≥700px
    the cluster is at its natural 620.8 (above the floor) and there is slack. The reported band is exact:
    overflow is 172px at 481px, decays linearly to 1px at 652px, and is 0 from 660px up.

- timestamp: 2026-08-23T01:14:00Z
  checked: Per-child arithmetic inside `.pk-footer-right` at 481px, to test whether `.pk-footer-meta`
    (the sibling session's named offender) is actually the binding constraint.
  found: Children measure social 136 + toggle-tag 31.1 + theme-toggle 136 + meta 227.8 = 530.9, plus
    3 gaps x 1.5rem (72) = 602.9 — matching the cluster's 602.8 floor to within rounding. The shallowest
    overflowing element is `.pk-footer-right` itself at depth 4 (w 602.8, left 32, right 634.8);
    `.pk-footer-meta` is depth 5 and `.pk-bgg-note` depth 6.
  implication: The sibling session's `.pk-footer-right -> .pk-footer-meta -> .pk-bgg-note` chain was a
    depth-first walk to the deepest node, and blaming `.pk-bgg-note`/`.pk-footer-meta` would have been
    wrong. The meta line is only 227.8 of the 602.8 floor — 38%. Even deleting it outright would leave
    a 351px floor, still overflowing below 415px+gutters. The binding constraint is the CLUSTER: four
    non-shrinking children in a row that cannot wrap. Blaming the deepest node would have produced a
    fix that did not fix.

- timestamp: 2026-08-23T01:16:00Z
  checked: Why scrollWidth reads 653px when `.pk-footer-right`'s right edge is only 634.8px — an 18.2px
    discrepancy that must be explained, not rounded away.
  found: `.pk-bgg-note` (`inline-flex`) measures left 534.6, right 652.8 (652.8 -> scrollWidth 653),
    while its own parent `.pk-footer-meta` ends at 634.8. The child overflows its parent by exactly 18px
    — the width of the BGG logo `<img>` (measured w=18 at depth 7). At >=700px the meta box is 245.8
    wide and the note ends flush at 652.8; at 481px the meta box is squeezed to 227.8 and the note still
    ends at 652.8.
  implication: `.pk-footer-meta` DOES flex-shrink, but only by 18px, and because its child is an
    atomic `inline-flex` containing a fixed-size raster logo, the shrink produces child-overflows-parent
    spill rather than any reflow. So the true ink edge of the footer is 652.8px and is completely
    invariant to viewport width — this is the number that sets the 652px upper bound of the band, and it
    is 18px worse than the cluster box alone suggests.

- timestamp: 2026-08-23T01:19:00Z
  checked: Whether the obvious fix — extending the ≤480px override upward so the band gets the same
    treatment (`.pk-footer-right .pk-theme-toggle`, `.pk-footer-toggle-tag`, `.pk-footer-social`
    become `display: none`, app.css:1811-1815) — is viable. That override's own comment justifies the
    hide by saying those controls "move into the drawer".
  found: `.pk-nav-hamburger` is `display: none` in its base rule (app.css:1007-1008) and is switched to
    `display: flex` ONLY inside `@media (max-width: 480px)` (app.css:1754-1756). `.pk-drawer`
    (:1758-1760) and `.pk-drawer-backdrop` (:1762-1764) are gated identically. Confirmed live: at 375px
    the drawer exists in the box walk; the hamburger is the only way to open it.
  implication: This ELIMINATES the breakpoint-extension fix. Above 480px there is no hamburger and no
    drawer, so hiding the social links and the theme toggle in the 481-652px band would not relocate
    them — it would delete the club's four social links and the entire light/dark/system control from
    every tablet-width viewport with no replacement anywhere on the page. That is a functional
    regression dressed as a bug fix. The hide-at-≤480px trade is only sound BECAUSE the drawer exists
    there, and that precondition is false in this band.

- timestamp: 2026-08-23T01:21:00Z
  checked: `.pk-footer-left` as a possible second instance of the same defect (it is the sibling cluster
    under the same base rule `.pk-footer-left, .pk-footer-right { display:flex; align-items:center;
    gap:1.5rem }`).
  found: Left measures 408.1px natural with a min-content of 169.6px — i.e. it is NOT pinned to its
    floor and retains 238px of compressibility, because `.pk-footer-links` already carries
    `flex-wrap: wrap` (app.css:912) and the brand lockup's text can break. At the band's worst case
    (481px) the row's content box is 481 - 2x32 = 417px against left's 408.1px, so it fits with 8.9px
    to spare and never appears in the offender walk at any measured width.
  implication: The left cluster is not part of this bug and must not be changed on suspicion — but the
    8.9px margin is the reason it escapes, not any structural guarantee. The contrast is the crispest
    statement of the root cause: two sibling clusters share one base rule, yet left's min-content is
    169.6px and right's is 602.8px — 3.5x larger despite holding LESS text — purely because right's
    children are two `white-space: nowrap` text runs plus two fixed-size icon rows with no wrap escape.

## Resolution

root_cause: |
  `.pk-footer-left, .pk-footer-right` (assets/css/app.css:899-904) declared `display: flex` with no
  `flex-wrap`, so each cluster had exactly one line to place all its children on. Because a flex item's
  default `min-width: auto` resolves to its min-content, a NON-WRAPPING flex container's minimum width
  is the SUM of its children's min-contents rather than the max. For `.pk-footer-right` that sum is
  social 136 + toggle-tag 31.1 + theme-toggle 136 + meta 227.8 = 530.9, plus 3 x 1.5rem gaps (72) =
  a hard 602.8px floor — confirmed by the cluster's measured width equalling its separately-measured
  `width: min-content` at every viewport in the band. Two of those children (`.pk-footer-toggle-tag`,
  `.pk-footer-meta`) additionally carry `white-space: nowrap`, which is what makes their individual
  terms in that sum full single-line widths.
  The real ink edge is 18px worse still, at 652.8px: `.pk-footer-meta` does flex-shrink, but only by
  18px, and since its child `.pk-bgg-note` is an atomic `inline-flex` wrapping a fixed-size 18px BGG
  logo, that shrink produces child-overflows-parent spill rather than any reflow.
  652.8px is invariant to viewport width, so documentElement.scrollWidth sat pinned at 653px and every
  viewport narrower than that scrolled horizontally. The lower edge of the band is 481px purely because
  `@media (max-width: 480px)` (app.css:1799-1815) collapses the cluster below it — columning the row,
  hiding three of its four children, and narrowing the gutter from 2rem to 0.875rem. 480px was never
  the width at which the cluster starts fitting; it needs 653px.
  AND-gate: YES, two conditions had to hold together — (a) all four children present and
  over-subscribing one line, and (b) no reflow escape. Below 481px (a) is false; above 660px (a) is
  false. Only 481-652px has both. The fix removes (b), which is sufficient here (unlike the sibling
  header bug) because the outcome of reflow is a taller footer, not a new failure mode.

fix: |
  Added `flex-wrap: wrap` to the shared `.pk-footer-left, .pk-footer-right` base rule
  (assets/css/app.css:899-922 after the change), with a comment recording the measured floor
  arithmetic and the eliminated alternative. This changes how the cluster's minimum is COMPUTED —
  from sum(children) to max(children), i.e. 602.8px -> 227.8px — rather than tuning a value that
  happens to fit today's content. It is also the footer's own existing idiom: `.pk-footer-row` (:895)
  and `.pk-footer-links` (:912) already wrap; these two clusters were the only flex containers in the
  component that did not.
  Explicitly NOT done, and recorded in Eliminated: extending the ≤480px `display: none` override up
  through the band. That override is only sound because those controls relocate into the drawer, and
  `.pk-nav-hamburger`/`.pk-drawer`/`.pk-drawer-backdrop` are themselves `display: none` above 480px —
  so it would have deleted all four social links and the entire theme control from tablet widths with
  nowhere to reach them.
  Also explicitly NOT done: stripping `white-space: nowrap` from `.pk-footer-meta`. Measured as
  causing no overflow at any width from 260px to 1536px, so changing it would be an unevidenced edit.
  Commit `a725c4b`.

oracle_type: derived (contract) — the true oracle for this bug is rendered browser geometry, which
  ExUnit cannot observe. `test/pukllay_club_web/footer_overflow_test.exs` therefore pins the structural
  preconditions that geometry depends on, following the pattern and rationale already established by
  `header_row_height_test.exs`. The geometric oracle itself was exercised directly through the CDP
  harness against the running app (18-width sweep), not merely asserted in ExUnit.

verification:
  signal_original_symptom_gone: |
    PASS — measured, not inferred. documentElement.scrollWidth == clientWidth with 0px overflow at all
    18 swept widths (260, 320, 375, 470, 481, 500, 560, 600, 640, 652, 653, 660, 700, 768, 850, 1024,
    1280, 1536) on the live app. Pre-fix the same sweep gave 653px pinned with 172px of overflow at
    481px decaying to 1px at 652px. `.pk-footer-right`'s min-content dropped 602.8 -> 227.8 exactly as
    the falsification test predicted.
  signal_bug_returns_on_revert: |
    PASS — measured. Reverting assets/css/app.css to HEAD and re-measuring restored the defect
    value-for-value: 481px scrollWidth 653 / overflow 172, 560px 653/93, 652px 653/1, 700px clean, with
    `.pk-footer-right` back at 602.8 = its min-content. Restoring the fix returned it to 0 everywhere.
  signal_regression_test_red_then_green: |
    PASS — the 3 wrap-contract tests in test/pukllay_club_web/footer_overflow_test.exs were run against
    the ACTUAL pre-fix tree (file reverted, not simulated) and failed with the intended messages;
    the same 3 pass after restoring the fix. 6 tests, 0 failures post-fix.
  signal_mutation_guardrail: |
    PASS — three mutants introduced at and around the fix site, all killed:
    (1) `flex-wrap: wrap` -> `nowrap` on the cluster rule => 3 failures;
    (2) deleting `flex-wrap: wrap` from the adjacent `.pk-footer-row` => 1 failure;
    (3) widening `@media (max-width: 480px)` to 660px — i.e. the eliminated fix path — => 2 failures.
    The suite bites on the fix site itself, on the neighbouring container, and on the wrong-fix path.
  signal_not_deletion_only: |
    PASS — the diff is +19/-0 on assets/css/app.css: one added declaration plus its rationale comment.
    Nothing removed, nothing hidden, no control lost at any viewport width.
  signal_no_regression_elsewhere: |
    PASS on three axes. (1) `mix quality` green end-to-end: hex.audit, deps.audit, deps.unlock,
    format --check-formatted (Styler-augmented), credo --strict, sobelow, and 353 tests / 0 failures.
    Sobelow's only findings are pre-existing low-confidence Directory-Traversal notes in unrelated seed
    code. (2) All three page variants that render the shared footer measured clean at 375-1280px:
    `/` (CatalogLive.Index), `/quienes-somos` (AboutLive), `/juegos/1` (CatalogLive.Show).
    (3) Geometry OUTSIDE the band is byte-identical to pre-fix: at >=700px the right cluster is still
    620.8px wide and 44px tall with the meta at x=407.1, and at <=480px it is still 245.8px wide and
    23px tall — mobile, which is this project's stated primary target, is untouched.
  visual_confirmation: |
    Screenshots captured at devicePixelRatio 2. Pre-fix at 481px shows the copyright line truncated
    mid-word at the right edge ("© 2026 Pukll…") with the BGG attribution entirely off-screen. Post-fix
    at 481px the footer reads as three tidy left-aligned rows (brand + links / social + Tema + theme
    toggle / copyright + BGG) fully inside the viewport. Post-fix at 700px is visually identical to
    pre-fix. Files: scratchpad before-481.png, after-481.png, after-560.png, after-700.png.
  guardrail_verdict: accepted
  signal_human_verified: |
    PASS — checkpoint answered 2026-08-23. The user reviewed the captured screenshots
    (before-481.png, after-481.png, after-700.png) and confirmed: overflow eliminated, the footer
    reflows to a 3rd row in the 481-652px band ONLY, and nothing changes outside that band.
    Verdict: "clean fix — confirmed fixed", approved. This closes the one blind spot measurement
    could not settle: whether the stacked 3-row arrangement is the DESIRED look in the band is a
    design judgement, and it was accepted rather than assumed. No design revision requested.
  not_yet_verified: |
    Headless Chrome only (dPR 1 for measurement, dPR 2 for screenshots) — no real tablet hardware and
    no iOS Safari. Flex line-packing is spec-defined so divergence is unlikely, but it is unobserved.
    Font-swap on a slow connection is untested; with wrapping enabled that now degrades to an extra
    wrapped line rather than overflow, which is the better failure, but it has not been watched.
    These two remain open after resolution; both are benign-failure-mode risks, not correctness risks.

files_changed:
  - assets/css/app.css (+19/-0) — `flex-wrap: wrap` on the shared `.pk-footer-left, .pk-footer-right`
    rule, plus a comment recording the measured floor arithmetic and the eliminated alternative.
  - test/pukllay_club_web/footer_overflow_test.exs (new, 6 tests) — regression guard for the class:
    every footer flex container must wrap, and the footer's social/theme controls may only be hidden
    inside a block that also opens the drawer (blocking the wrong fix), plus a max-width-breakpoint
    creep assertion and a markup contract test keeping the BGG attribution present.
