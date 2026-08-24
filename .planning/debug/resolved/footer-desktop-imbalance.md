---
status: resolved
# A + B (alignment, mark weight) are human-CONFIRMED and closed. Do not revert or re-litigate.
# C (the legal band on its own row) is human-CONFIRMED KEPT — the user rejected the band's
# left-aligned TREATMENT, not the split itself. Do NOT revert to the single-row option A.
# D (split: copyright left / BGG right, edge-anchored) is the user's CHOSEN treatment, made
# with the ~984px separation cost stated and accepted. Applying it now.
# The flush-left claim is measured and closed (all deltas 0.00 at every width 481-1920px).
trigger: "on desktop, the footer content feels so overloaded: it's a full of data and lack of clear hierarchy. Also, coppyright vs powered by bgg isn't aligned. What best practices used by industry can I use on the footer to have a better clean balance?"
created: 2026-08-23
updated: 2026-08-24
---

## Symptoms

- **Expected behavior:** The desktop footer should read as clean and balanced, with a
  clear visual hierarchy across its concerns (brand, nav, social, theme, legal), and the
  copyright line and the "Powered by BGG" attribution should be visually aligned with
  each other (not offset/misaligned). The user is asking what industry-standard footer
  patterns could be applied to achieve this balance.
- **Actual behavior:**
  1. Despite the same-day fix in the resolved session `footer-desktop-overloaded` (spacing
     hierarchy tokens + `.pk-footer-theme` grouping wrapper, commit applied and accepted by
     the user via checkpoint), the user is now reporting the desktop footer STILL feels
     overloaded / lacking clear hierarchy. This may be a residual dissatisfaction with the
     3-concern `.pk-footer-right` cluster the user previously chose to keep as-is (see
     `.planning/debug/resolved/footer-desktop-overloaded.md`, Resolution / human_verify), or
     a distinct/new contributor not covered by that fix.
  2. NEW, specific defect not addressed by the prior session: the copyright text and the
     "Powered by BGG" attribution are not aligned. Preliminary code read
     (`lib/pukllay_club_web/components/layouts.ex:608` and `:712-726`,
     `assets/css/app.css:1071-1087`): `.pk-footer-meta` is a plain inline `<span>` containing
     literal text ("© {year} Pukllay Club · ") followed by the `.bgg_attribution` component,
     which renders `.pk-bgg-note` as `inline-flex items-center gap-1` wrapping an 18x18px
     `<img>` + text. An inline-flex element next to plain text with no `vertical-align`
     override defaults to `vertical-align: baseline`, i.e. the BOTTOM of the flex box aligns
     to the surrounding text's baseline — plausible mechanism for a visible vertical offset
     between the copyright text and the BGG logo+text, since the flex box (driven by the
     18px image) is taller than the 0.75rem text line-height. Not yet measured/confirmed —
     candidate hypothesis only.
- **Error messages:** None — purely visual/UX, consistent with all four prior footer/header
  sessions in the knowledge base (no console errors on any of them).
- **Timeline:** Reported same day as the `footer-desktop-overloaded` fix (2026-08-23),
  immediately after that fix was applied and accepted. Not clear whether this is a
  regression from that fix, a pre-existing defect newly noticed once the grouping fix made
  the rest of the footer read better, or unchanged dissatisfaction with a decision the user
  made at that session's checkpoint.
- **Reproduction:** View any page at a desktop viewport width (particularly >=1070px where
  the footer is single-line) and inspect `.pk-footer-right`'s meta line — compare the
  vertical position of the copyright text baseline against the BGG logo/text inside
  `.pk-bgg-note`.

## Current Focus

- bug_class: Bohrbug — deterministic, reproducible at a fixed viewport, no timing/concurrency
  component. Route: deterministic reproduction -> direct measurement. SBFL skipped (Phase 1.25):
  no per-test coverage exists for rendered CSS geometry; ExUnit cannot observe layout.
- hypothesis: |
    (H1/H2/H3 — the inline-flex baseline, the mark's weight, and the structural asymmetry — are all
    CLOSED. See Resolution (A)/(B)/(C). The live hypothesis is now H4.)

    H4: the legal band reads as an orphaned fragment because of FILL, not alignment. 241.75px of
    ink is being asked to occupy a 1216px band — 19.88% filled, with the remaining 80.1% sitting
    as ONE unbroken 974.25px void. Left/centre/right only choose WHERE that void sits; all three
    measure the same 19.88%. The band therefore cannot read as a peer band under any pure
    alignment change, because a stub in a wide band reads as a stub wherever you put it. Only a
    treatment that makes the band's ink span its full width (anchoring a piece at each edge)
    changes the property the eye is actually responding to.
- test: Build all four treatments by runtime CSS/DOM injection and measure fill%, both edge
    relationships and footer height at 1280px, at 560px (the wrapped band, where `space-between`
    degenerates to left-flush and a treatment can silently break), and at 320/375/430px (mobile,
    the primary surface). Screenshot each in both themes — the objection is visual, and pure
    geometry already mispredicted it once on this element.
- expecting: If H4 holds, left/centre/right all measure an IDENTICAL fill% and differ only in void
    placement, while the split treatment is the sole outlier.
    Falsification: if the three alignment variants had produced materially different fill or void
    structure, H4 would be dead and this would be a genuine alignment choice.
    RESULT: H4 CONFIRMED — 19.88% / 19.88% / 19.88% vs 100.00%.
- checkpoint_open: |
    CLOSED. The DECISION checkpoint came back **D — split, copyright left / "Powered by BGG"
    right, spanning the full row width**. The user reviewed all four screenshot sets plus D at
    dark/wrapped/mobile, read the fill-percentage and edge-anchoring measurements, and accepted
    the stated cost (copyright and BGG separated by ~984px at 1280px while remaining on one
    shared baseline) knowingly. Do NOT re-surface that tradeoff as a concern.
- next_action: |
    NONE — session closed. Treatment D is applied, guarded and committed; the session file is
    archived to .planning/debug/resolved/ and the knowledge base updated.

    All four parts (A alignment, B mark weight, C structural band, D fill/edge-anchoring) are in
    one working tree and were committed together — A/B/C had never been committed, so D's
    red-check was run by reducing the source from D back to C rather than by `git stash`, which
    would have reverted four fixes at once.

    Residual, non-blocking and deliberately NOT re-checkpointed (the user pre-authorised closing
    on green): (1) the user has not yet seen D applied in their own browser — they chose it from
    measured options and screenshots; (2) at 260-279px the band now wraps to two lines, taking
    the footer 179 -> 213px, which is below any real device width and replaces a text bleed that
    had gone undetected for three sessions.
- history_resumed: |
    RESUMED after the (C) human-verify checkpoint came back NEGATIVE-with-a-direction. User's
    verbatim reaction: "Copyright and BGG compliance doesn't look correctly aligned to left."
    Decision: KEEP the legal band on its own row (option B stays, do NOT revert to A); change its
    PLACEMENT/ALIGNMENT within that row so it stops reading as an orphaned fragment. User
    explicitly asked for alternatives (right-align under the utilities cluster, centre, or another
    option) rather than defaulting back to left.

    Step 1 (BLOCKING, before any treatment work): CONFIRM OR REFUTE by live CDP measurement that
    `.pk-footer-legal`'s left edge is actually flush with `.pk-footer-left`'s. The orchestrator's
    static read says they must be (both direct children of the only padded element, no per-child
    margin) — that is a strong PRIOR, not a measured fact, and geometry has already failed once to
    predict this user's perception. If a real offset exists it is a positioning defect and takes
    priority over any composition treatment.
    Step 2: only if flush — measure 2-3 candidate treatments, screenshot both themes, and either
    pick one with rationale or take two to a checkpoint.
- checkpoint_history: |
    (A) alignment + (B) 14px mark: CONFIRMED ACCEPTED by the user. Closed. Never re-litigate.
    (C) option B (legal line on its own row): CONFIRMED KEPT by the user. The +50px desktop height
    cost was surfaced at the checkpoint and drew no objection. Do NOT revert to option A.
    OPEN: only the legal row's own placement/alignment treatment.
- history: |
    Parts (A) and (B) are APPLIED and human-CONFIRMED (checkpoint answered: alignment + 14px mark
    look correct in both themes). Do not revert or re-litigate them.

    Then implemented the structural half, which the checkpoint answered as alternative **B**:
    split the legal line (copyright + BGG attribution) out of `.pk-footer-right` into its OWN row
    below the social/theme/nav row. Social + theme stay together, so the right cluster drops from
    3 concerns to 2 and matches the left cluster's 2 — the ink/void asymmetry (right 604.81px/3
    vs left 364.11px/2, 1.66x) is then resolved structurally rather than by spacing. Alternatives
    A (keep as-is) and C were explicitly declined. Footer height growth is accepted as the
    tradeoff; measure and report the real number rather than assuming it.

    Constraints carried in: preserve the four spacing tokens from footer-desktop-overloaded;
    sketch 011's no-divider rule stands (the row gap does the work, no border/rule between rows);
    mobile is primary, so the stacked footer must not regress in layout OR height; do not
    recolour/background-strip/re-badge the BGG mark.
- structural_hypothesis: |
    The remaining "overloaded" residue is a STRUCTURAL asymmetry, not a spacing one. Confirmed
    unchanged after the (A)/(B) fixes: `.pk-footer-right` carries three concerns of two different
    KINDS — two interactive utilities (social, theme) plus one passive legal/compliance run — while
    `.pk-footer-left` carries two of one kind. Peer-level clusters holding unlike content is what
    makes the row read as a run rather than as two balanced blocks, and it is why the legal line
    (the least important content) sat inside the same proximity band as the utilities.

    Fix direction: promote the legal line to its own full-width band, so KIND maps to ROW.
    Open sub-question the evidence must settle: whether row-to-row separation needs a tier ABOVE
    `--pk-footer-gap-cluster`, or whether the legal row is a peer block that should sit at the
    cluster tier. Decide from the wrapped 481-1070px band, where `.pk-footer-row`'s row-gap is
    actually visible — if the legal row sat at the same tier as the cluster wrap gap, the wrapped
    state would flatten into three equidistant blocks, re-creating the exact defect
    footer-desktop-overloaded fixed.
- reasoning_checkpoint:
    hypothesis: |
      Two mechanisms, one shared culprit element (`.pk-bgg-note`).

      (A) ALIGNMENT. The anchor is `inline-flex items-center`, so it has no baseline-aligned flex
      item and per CSS Flexbox §8.3 must SYNTHESIZE its inline baseline from the first flex item's
      border box — the 18x18 img. The img's bottom edge therefore becomes the anchor's baseline and
      lands on the copyright text's baseline, throwing "Powered by BGG" 5.00px high and inflating
      the meta line box 18px -> 23px.

      (B) HIERARCHY. The same element is also the footer's heaviest ink: an opaque, high-chroma
      trademark tile sized against LINE-HEIGHT rather than cap-height. That makes the compliance
      footnote the loudest object in a footer whose actual utilities are the quietest — hierarchy
      present but INVERTED, which is what "full of data and lack of clear hierarchy" describes now
      that proximity has already been repaired.
    confirming_evidence:
      - "Measured: the copyright baseline (text bottom 5491.69 minus 3px descent = 5488.69) equals
         the img's bottom edge (5488.69) to the hundredth of a pixel. That is the synthesized
         baseline itself, observed — not inferred from the 5px symptom."
      - "copyTop-bggTop = copyBottom-bggBottom = 5.00px with textHeightsEqual = true. A constant
         offset on identical 12px type is a baseline shift, and excludes line-height/font drift."
      - "Rendered-pixel analysis: bggImg is 100% ink and meanChroma 0.32, vs 6.3-28.4% ink and
         0.06-0.10 chroma for every other footer region. Its 324px² carries ink mass 248.08 — as
         much as the entire 4-icon social row's 240.84 across 11.75x the area (12.1x per pixel)."
      - "page-shell.md:69-75 already REQUIRED this: attribution 'de-emphasized ... not a bordered,
         backgrounded badge competing visually with the rest of the footer ... no box'. The shipped
         asset is a 400x400 JPEG with a baked-in dark background — the badge, reintroduced by asset
         format when D-04 added the logo."
      - "01.1-01-SUMMARY.md:49 sized it '~18px (roughly text line-height)'. Sizing an inline mark to
         line-height (18px) rather than cap-height (~8.7px at 12px Inter) is exactly why it fills
         the whole line box and towers over the type it annotates."
      - "01.1-01-SUMMARY.md:117 flagged this precise thing `human_judgment: true` — 'the BGG logo's
         visual sizing/placement ... is a judgment call flagged for human confirmation'. It was
         never confirmed. This report IS that confirmation arriving, negative."
    falsification_test: |
      (A) dies if the two text baselines measure equal (delta 0) — they measure 5.00px apart, and
      the img-bottom/baseline coincidence would have to be a 1-in-10000 accident.
      (B) dies if the attribution mark were NOT an ink/chroma outlier — if bggImg's per-pixel ink
      density sat within the 0.037-0.139 band the other regions occupy. It measures 0.766, i.e. 5.5x
      the next densest region (meta text) and 12.1x the social row.
      Post-fix: (A) is falsified-or-confirmed by re-measuring delta == 0; (B) by re-measuring ink
      mass and confirming the mark is no longer the footer's per-pixel maximum.
    fix_rationale: |
      Both parts attack the mechanism, not the symptom.

      (A) The symptom-fix would be a magic `vertical-align: -5px` compensator — it would break the
      instant the font-size or the logo size changed, because it hard-codes the output of the very
      computation that is wrong. The root-cause fix removes the synthesized-baseline path entirely:
      stop making the anchor a flex container, so the attribution text sits in the SAME inline
      formatting context as the copyright text and shares one baseline BY CONSTRUCTION, with no
      number to keep in sync. The mark then aligns as a normal inline image (`vertical-align:
      middle`), which self-adjusts to the parent's x-height.

      (B) Re-grounds the size on the metric it should always have used (the type it annotates)
      rather than the line box it happens to sit in. This restores a documented constraint that was
      dropped, and closes a judgment call the phase record explicitly left open — it is not a new
      design invention.

      Deliberately NOT doing: recolouring, desaturating, opacity-fading or background-stripping the
      mark. BGG's terms state the BoardGameGeek logo is a trademark and that you 'may not frame or
      utilize framing techniques to enclose any trademark, logo, or other proprietary information'.
      Scaling is a normal, permitted use; altering the mark's colour or enclosing it in chrome is
      not something to do unilaterally. Size is the safe lever.
    blind_spots: |
      (1) Whether fixing weight+alignment is SUFFICIENT for "overloaded", or whether the structural
      asymmetry (right cluster 3 concerns/604.81px vs left 2/364.11px, 1.66x, with a 247.08px void)
      also has to change. That is a design decision the user already answered once ("A — keep as
      fixed") and it is NOT being changed unilaterally; it goes to the checkpoint with the industry
      research attached. Note the prior session made exactly this blind spot its #1 and its
      human_verify closed it as sufficient — wrongly. I am not repeating that closure.
      (2) Dark theme not separately measured; the footer background inverts there, so the opaque
      dark tile may actually read QUIETER on dark. Must check both themes before claiming the ink
      result, because the whole (B) argument is contrast-against-background dependent.
      (3) Headless Chrome at dPR 1-2, not a physical device.
      (4) The exact BGG XML API attribution clause could not be retrieved (search returned only the
      page index, not the clause text). I am therefore preserving the mark and its colours as-is and
      changing only its scale — the conservative direction under that uncertainty.
    candidate_causes:
      - "code/CSS+markup: `inline-flex items-center` on an anchor that lives inside a text run —
         synthesized baseline (mechanism A). Category: code."
      - "data/asset: the attribution mark is a 400x400 opaque JPEG with a baked-in dark background
         rather than a transparent glyph, so it renders as 100%-ink chroma-0.32 tile. Category: data
         (the artifact), and it is the direct cause of the ink outlier."
      - "config/decision-record: the sizing rule of record ('~18px, roughly text line-height') picks
         the wrong reference metric, and the page-shell.md 'de-emphasized, no badge' constraint had
         no gate to enforce it once D-04 layered the logo on top. Category: config/process."
      - "environment: NOT a cause — reproduces deterministically at every desktop width, no
         device/browser/timing dependence. Explicitly checked and excluded."
    and_gate: |
      YES for (B), NO for (A).

      (A) is single-cause and fully sufficient on its own: the flex baseline synthesis alone
      produces the 5px offset regardless of asset, colour or size.

      (B) fires. Neither contributing cause is sufficient alone — a transparent/muted mark at 18px
      would read as an icon rather than a badge, and an opaque tile at cap-height (~9px) would be
      too small to dominate. It takes the opaque high-chroma tile AND the line-height-derived size
      simultaneously to make a compliance footnote outweigh the entire social row. So `root_cause`
      is a set, and the (B) fix must move BOTH levers to the extent trademark constraints allow —
      which, since colour is off-limits, means size plus removing the line-box inflation.

## Evidence

- timestamp: 2026-08-23T23:05:00Z
  checked: Knowledge base (`.planning/debug/knowledge-base.md`) — 4 resolved entries, all on this
    same shell (search-expand-header-overlap, header-height-wordmark-wrap, footer-overflow-tablet-width,
    footer-desktop-overloaded).
  found: `footer-desktop-overloaded` (today) is a near-exact match on the "overloaded / lacks
    hierarchy" HALF of this report and is already fixed — its guard is
    test/pukllay_club_web/footer_rhythm_test.exs. NO KB entry mentions baseline alignment,
    vertical-align, or inline-flex-next-to-text. But `footer-overflow-tablet-width`'s error-pattern
    list contains "atomic `inline-flex` wrapping a fixed-size `<img>`" for this SAME element
    (`.pk-bgg-note`) — that session hit the element's INLINE-LEVEL atomicity in the horizontal axis.
  implication: The alignment defect is a NEW class for this repo, but the culprit element already
    has a documented history of behaving as an unexpectedly atomic inline-level box. That raises,
    rather than lowers, prior probability on H1. Treat as hypothesis candidate, not diagnosis.

- timestamp: 2026-08-23T23:12:00Z
  checked: CDP measurement of `.pk-footer-meta` internals on the LIVE app (localhost:4000) at
    1280x900, transitions disabled. Measured text-node baselines via `Range.getBoundingClientRect()`
    (identical 12px font on both runs, so delta-of-tops == delta-of-baselines) plus the img box and
    computed styles. Harness: scratchpad/cdp.js + scratchpad/meta-align.js.
  found: |
    H1 CONFIRMED, and the numbers land on the predicted mechanism exactly.

      .pk-bgg-note   display: inline-flex   align-items: center   vertical-align: baseline
      copyright text rect   top 5476.69  bottom 5491.69  h 15
      "Powered by BGG" rect top 5471.69  bottom 5486.69  h 15
      img (18x18)           top 5470.69  bottom 5488.69

      copyTop - bggTop        = 5.00px   (BGG text sits 5px HIGHER)
      copyBottom - bggBottom  = 5.00px   (constant offset, not a line-height artifact)
      textHeightsEqual        = true     (both 15px — same font, so this is a pure baseline shift)
      .pk-footer-meta height  = 23px     (vs the 18px line-height it would be with text alone)

    The decisive number: the copyright text's baseline computes to 5491.69 - 3px descent =
    **5488.69**, which is *exactly* the img's bottom edge (5488.69). The 18px image's bottom margin
    edge IS the anchor's baseline — the synthesized-baseline mechanism, observed directly, to the
    hundredth of a pixel.
  implication: Root cause of the alignment half is mechanical and settled: per CSS Flexbox §8.3, an
    inline-level flex container with NO baseline-aligned item (here `align-items: center`)
    synthesizes its baseline from the first flex item's border box. The first item is the 18px img,
    so the img's BOTTOM sits on the surrounding text's baseline. Consequences are twofold, and both
    are visible: (a) the logo rises 18px above a baseline the 12px text only rises ~9px above, so it
    towers over the copyright line; (b) "Powered by BGG", centred against that 18px img, floats
    5.00px above the copyright text. Also explains a side effect nobody had attributed: the meta
    line box is inflated 18px -> 23px, so the anchor is silently making the footer 5px taller.

- timestamp: 2026-08-23T23:14:00Z
  checked: Whether `align-items: center` is the cause. Falsification probe: if the flex container
    had a baseline-aligned item, the spec takes the item's real baseline instead of synthesizing.
  found: `.pk-bgg-note` is `inline-flex items-center gap-1` (layouts.ex:724). `items-center` is what
    removes every baseline-participating item, forcing the synthesized path. `.pk-bgg-note`'s CSS
    rule (app.css:1077-1082) sets only colour/underline — the display and alignment come entirely
    from the Tailwind utilities in the markup, which is why the CSS block reads as innocent.
  implication: The fix lane is at the anchor's inline-level alignment, not in `.pk-footer-meta`.
    Confirms this is NOT a spacing-tier problem and therefore NOT a regression from
    footer-desktop-overloaded's token work — that fix never touched vertical alignment.

- timestamp: 2026-08-23T23:26:00Z
  checked: Whether footer-desktop-overloaded's spacing fix is still intact (i.e. is this new report a
    REGRESSION of that fix?). Measured live gaps between the right cluster's three concerns at 1280px.
  found: Fix fully intact. social ends x=779, theme starts x=803 -> 24px (group tier). theme ends
    x=978, meta starts x=1002 -> 24px (group tier). "Tema" binds to its toggle at 8px (item tier).
    Zero horizontal overflow. The four tokens are present and the tier order holds.
  implication: NOT a regression. The spacing hierarchy is doing exactly what it was built to do, and
    the user is STILL reporting "overloaded / lacks clear hierarchy". This empirically ANSWERS the
    prior session's own blind spot #1 ("whether restoring a spacing hierarchy is SUFFICIENT") — the
    answer is NO. Its `human_verify: CONFIRMED ... it was sufficient` was premature; a same-day
    re-report falsifies it. Some OTHER hierarchy channel must be the remaining cause.

- timestamp: 2026-08-23T23:34:00Z
  checked: Rendered-pixel analysis of the real footer at 1280px. Captured the footer via
    `Page.captureScreenshot`, fed the PNG back into the page, and computed per-region ink density
    (fraction of pixels whose WCAG relative luminance departs from the footer background by >0.05),
    ink MASS (summed departure), and chroma. Harness: scratchpad/ink.js.
  found: |
    region        box       inkPct   inkMass   inkMass/px   meanChroma   maxChroma   %px chroma>0.3
    social       136x28      21.9%    240.84     0.0632        0.06        0.13          0.0%
    theme        175x44       6.3%    284.32     0.0369        0.06        0.39          1.8%
    meta         246x23      28.4%    784.76     0.1387        0.10        1.00          4.1%
    bggImg        18x18     100.0%    248.08     0.7657        0.32        1.00         23.8%
    leftCluster  364x48      17.5%   1645.47     0.0942        0.08        0.55          4.1%
    rightCluster 605x44      11.0%   1309.91     0.0492        0.07        1.00          1.4%

    Three numbers carry this:
    1. `meta` — the LEGAL SMALL PRINT — is the densest concern in the right cluster (28.4% ink vs
       social 21.9% vs theme 6.3%) and accounts for **59.9% of the entire right cluster's ink mass**
       (784.76 / 1309.91) while occupying only 40.7% of its width.
    2. `bggImg` is **100% ink** — every pixel departs from the background, because the asset is an
       opaque JPEG with a baked-in background rather than a transparent glyph. It is the only
       100%-ink element in the footer.
    3. Per-pixel, the 18x18 BGG logo is **12.1x** denser than the social row (0.7657 vs 0.0632) and
       **20.7x** denser than the theme control (0.7657 vs 0.0369). In absolute ink mass, that 324px²
       logo (248.08) carries **as much visual weight as the entire 4-icon social row** (240.84)
       which is 11.75x its area. Its meanChroma 0.32 is 3-5x every other region, and 23.8% of its
       pixels exceed chroma 0.3 where nothing else in the footer exceeds 4.1%.
  implication: The remaining defect is a **visual-weight hierarchy that runs BACKWARDS**. Hierarchy
    has three channels — proximity, weight/contrast, and colour. footer-desktop-overloaded repaired
    proximity; the other two were never examined, and both point the wrong way: the loudest thing in
    the footer is the compliance footnote, and the quietest is an actual interactive utility. An eye
    entering this footer lands on the small print first. That is precisely what "full of data and
    lack of clear hierarchy" describes — the hierarchy isn't missing, it's INVERTED.

- timestamp: 2026-08-23T23:38:00Z
  checked: Provenance of the BGG logo treatment, to see whether the badge look was ever a decision or
    is drift. Read page-shell.md (sketch findings) against layouts.ex:711-729 and D-04.
  found: |
    The design record states the constraint explicitly and the implementation violates it:

      page-shell.md:69-75 — "BGG attribution stays present but de-emphasized, per compliance +
      explicit direction. ... nothing says it has to be a bordered, backgrounded **'badge' competing
      visually with the rest of the footer**. Demoted to plain small-print text next to the
      copyright, underlined, **no box**."

    The sketch shipped that as text only (`© 2026 Pukllay Club · datos de BoardGameGeek`) with NO
    image. D-04 (Task 2 checkpoint) later changed the wording to the compliance-exact "Powered by
    BGG" AND added the logo mark — layouts.ex:713-717 records the asset as "a flat 400x400 JPEG with
    its own baked-in background, not a transparent icon."
  implication: Same accretion pattern as the prior session, one layer up. D-04 correctly satisfied
    the WORDING/compliance requirement but silently dropped the co-equal "de-emphasized, not a
    backgrounded badge" half of the same decision — an opaque JPEG with a baked-in background IS the
    backgrounded badge page-shell.md rejected. Nobody chose the badge; it arrived as a side effect of
    an asset format. This is the mechanism behind measurement #3 above, and it means the fix restores
    an existing documented constraint rather than inventing a new design.

- timestamp: 2026-08-23T23:52:00Z
  checked: Blind spot #2 — re-ran the identical ink analysis with `data-theme="dark"` forced, because
    the whole (B) argument is contrast-against-background dependent and could be a light-theme-only
    artifact. Harness: scratchpad/ink-dark.js.
  found: |
    PARTIAL FALSIFICATION of (B)'s ink-mass claim. Dark footer bg = rgb(34,16,58).

    region        inkPct   inkMass   mass/px   meanChroma   %px chroma>0.3
    brand          23.2%    421.74   0.0632      0.18            6.5%
    links          19.5%    430.78   0.0893      0.19            9.3%
    social          7.0%     71.56   0.0188      0.17            0.0%
    theme           5.3%     99.83   0.0130      0.17            1.9%
    meta           16.4%    196.25   0.0347      0.19            6.5%
    bggImg         25.6%     17.47   0.0539      0.32           23.8%

    In dark theme the mark's baked-in dark-navy background CAMOUFLAGES against the dark footer:
    ink coverage collapses 100% -> 25.6% and per-pixel ink mass 0.766 -> 0.0539, which is BELOW
    both `links` (0.0893) and `brand` (0.0632). It is not an ink outlier on dark at all.

    What survives both themes: chroma. meanChroma 0.32 and 23.8% of pixels above chroma 0.3 are
    intrinsic to the asset and identical in both themes — still the footer's highest, against a
    next-highest of 0.19 / 9.3%.
  implication: The honest, narrowed claim: (B)'s **ink-mass** half is LIGHT-THEME-ONLY; its
    **chroma** half is theme-independent. This does not retract the root cause — light is a shipped,
    default-reachable state (the un-forced headless render is light, and it is where the user's
    screenshot-equivalent lives), and a 12.1x per-pixel ink outlier there is a real defect. But it
    does correct the scope: I must not claim "the logo dominates the footer" unqualified. It
    dominates on light; on dark it merely carries the highest chroma. It also validates the chosen
    lever — reducing SIZE shrinks both the light-theme ink mass and the high-chroma pixel count in
    BOTH themes, whereas any contrast-based tweak would have helped one theme and hurt the other.

- timestamp: 2026-08-24T00:20:00Z
  checked: Structural half implemented (checkpoint decision **B**). Measured the live app with a
    batched CDP sweep — one Chrome, 16 viewport widths, both themes — before and after moving
    `.pk-footer-meta` out of `.pk-footer-right` into a full-width `.pk-footer-legal` band.
    Harness: scratchpad/cdp-sweep.js + scratchpad/struct.js.
  found: |
    Cluster symmetry achieved, and it is the metric the decision was made on:

      right cluster   604.81px / 3 concerns  ->  335.06px / 2 concerns
      left cluster    364.11px / 2 concerns  ->  364.11px / 2 concerns  (unchanged)
      ratio           1.66x                  ->  1.09x

    Single-line threshold for the main row moved 1070px -> 791px (measured: 790px still wraps,
    800px does not), because the row no longer has to fit the 246px legal run.

    Height, per band (light and dark identical — spacing is colour-independent):
      <=430px   179 -> 179   unchanged. Mobile did not regress.
      481-790   215/173 -> 223
      800-1069  173 -> 147   SHORTER by 26px
      >=1070     97 -> 147   TALLER by 50px

    Everything the two prior sessions fixed survived, re-measured at every width: baselineDelta
    0.00px, metaH 18px, item tier 8px ("Tema" -> toggle), group tier 24px (social -> theme),
    cluster tier 32px, horizontal overflow 0 from 260px to 1920px.
  implication: The decision's own success criterion is met — the clusters are peers again (1.09x)
    and each carries 2 concerns. The height cost is REAL and larger than the "~20px" estimated at
    the checkpoint: it is +50px at >=1070px, because the cost is exactly the legal line (18px) plus
    one cluster-tier gap (32px) and the gap cannot go below the cluster tier without re-inverting
    proximity in the 481-790px wrapped band. Partly offset: the 800-1069px band gets 26px SHORTER,
    since the main row now fits on one line 279px earlier. Flagging the estimate miss explicitly
    rather than letting the number pass silently.

- timestamp: 2026-08-24T00:26:00Z
  checked: First implementation measured 6px TALLER at every viewport including mobile (185px vs
    179px), even though the moved content is the same 18px line. Traced the extra 6px.
  found: `.pk-footer-legal` was a plain block. `.pk-footer-meta` sets `font-size: 0.75rem`, but the
    wrapper inherits the footer's 1rem — and a block box's line box is at least as tall as its OWN
    font's strut. So an 18px line was being rendered inside a 24px anonymous line box. Fixed by
    making the wrapper `display: flex`, which has no strut and no anonymous line box: measured
    legalH 24px -> 18px, footer back to 179px on mobile.
  implication: A self-inflicted sub-bug, caught by measuring rather than by assuming the move was
    height-neutral. Worth recording because it is invisible to inspection — the CSS looked right and
    the content was unchanged; only the rendered box was wrong. Mobile is this project's primary
    surface, so shipping a silent +6px there to fix a desktop complaint would have been a
    straightforward regression. Now guarded by a test asserting `display: flex` on this wrapper.

- timestamp: 2026-08-24T00:31:00Z
  checked: Blind spot from the constraints — whether the new row structure regresses the mobile
    stacked footer. Compared every mobile box position before and after at 260/320/375/430px.
  found: |
    Two mobile-only defects, both found by measurement and both fixed:

    (1) The legal line LEFT-ALIGNED while everything above it stayed centred. The stacked footer is
        a centred column: `.pk-footer-row` keeps `align-items: center` from the base rule, which
        flips from "centre the clusters vertically" to "centre the stack horizontally" when the
        direction changes. `width: 100%` opts a box out of that. Measured at 320px: meta x moved
        39.13 -> 14. Fixed by resetting `width: auto` in the <=480px block; x is back to 39.13.

    (2) An emptied `.pk-footer-right` would have spent a gap slot. Below 480px its remaining two
        children (social, theme) both `display: none` into the drawer, leaving a zero-height but
        VISIBLE flex parent. Flex `gap` skips a hidden child but not an empty visible parent, so the
        mobile column would have spent an extra 24px cluster gap on nothing. Fixed by hiding the
        cluster itself instead of its two children.
  implication: Mobile is byte-for-byte unchanged after both fixes — 179px tall, same centred stack,
    same 24px separation before the legal line, zero overflow down to 260px. Fix (2) also SIMPLIFIED
    the <=480px block (two selectors -> one) and is only legitimate because the cluster's contents
    are now exactly the two controls that relocate to the drawer; that precondition is what
    FooterRhythmTest's child-count assertion now exists to hold.

- timestamp: 2026-08-24T00:40:00Z
  checked: Re-ran the rendered-pixel ink analysis at 1280px light (the same measurement that framed
    the original complaint) against the new structure, INCLUDING the metrics that could have gone
    the wrong way. Harness: scratchpad/ink2.js.
  found: |
    region        box        inkPct   inkMass   mass/px   meanChroma
    brand        139x48       28.85    998.55    0.1497      0.10
    links        201x24       23.47    646.92    0.1341      0.11
    social       136x28       21.90    240.88    0.0633      0.06
    theme        175x44        6.25    284.88    0.0370      0.06
    meta         242x18       34.09    686.72    0.1576      0.11
    bggImg        14x14      100.00    150.07    0.7657      0.32
    leftCluster  364x48       17.50   1645.47    0.0942      0.08
    rightCluster 335x44        8.92    525.77    0.0357      0.06
    legal       1216x18        6.78    686.72    0.0314      0.07

    WHAT IMPROVED. Within the content row, weight now descends in the right order for the first
    time: brand 0.1497 > links 0.1341 > social 0.0633 > theme 0.0370. And the legal band as a whole
    is 0.0314 mass/px — the QUIETEST region in the footer, where `meta` used to be the densest
    concern in its cluster (0.1387 against social's 0.0632 and theme's 0.0369) and 59.9% of that
    cluster's total ink. It is now 0% of it.

    WHAT DID NOT IMPROVE, stated plainly:
      - Cluster ink-mass ratio got WORSE, not better: left/right was 1645.47/1309.91 = 1.26x, now
        1645.47/525.77 = 3.13x. Moving 686.72 of ink out of the right cluster is exactly why.
      - The central void GREW: 247.08px -> 516.83px (1216 - 364.11 - 335.06).
      - `meta`'s own per-pixel density is unchanged at ~0.16, still denser than the social icons.
        It is the same 12px text; only its neighbours changed.
      - bggImg is unchanged per-pixel at 0.7657 / chroma 0.32 — the tile is still opaque. Confirms
        the earlier size-only fix is intact and still at the ceiling of what scaling alone can do.
  implication: The hierarchy repair is real but it is a SEPARATION result, not a weight result — the
    legal line stopped competing because it left the band, not because it got quieter. That matters
    for how the outcome is described: "the clusters are balanced" is true by concern count (2 vs 2)
    and by width (1.09x), and false by ink mass (3.13x). The two metrics that moved the wrong way
    are both consequences of the same intended move, and neither is a defect on its own — a footer
    whose brand block outweighs its icon block, with generous space between, is the conventional
    shape. But the checkpoint framed B as "resolving the ink/void imbalance", and by the literal
    ink/void numbers it does not; it resolves the CONCERN-COUNT and WIDTH imbalance. Recording the
    distinction so the next session inherits the honest version.

- timestamp: 2026-08-24T01:05:00Z
  checked: |
    THE BLOCKING CHECK the constraints demanded: confirm or refute by live measurement that
    `.pk-footer-legal`'s left edge is actually flush with `.pk-footer-left`'s. Measured BOTH the
    box edge and the INK edge — a flush box does not imply flush ink, because fonts carry left
    side bearing, and a few px of bearing is exactly the kind of offset a box-only read misses.
    Ink edge taken via a Range over each block's first non-empty text node (leading whitespace
    skipped). Swept 15 widths, 320->1920. Harness: scratchpad/flush.js + flush-sweep.js.
  found: |
    CONFIRMED FLUSH — the orchestrator's static prior survives, and at the stronger ink level.

      width band   d_box(legal-left)   d_box(meta-left)   d_ink(meta-brand)
      481-1920px         0.00                0.00               0.00
      320-430px        -20.30              -20.30             -51.38   <- mobile, EXPECTED

    At 1280px the "©" glyph's first painted pixel and "PUKLLAY CLUB"'s first painted pixel BOTH
    start at x=32.00. Not "within a pixel" — identical.

    The mobile deltas are not a defect: <=480px is a centred stack, `.pk-footer-legal` is
    `width: auto` there, so it shrink-wraps and centres. Two centred boxes of different widths
    have different x by construction. fillPct=100 (shrink-wrapped) and footerH=179 confirm the
    intended centring, unchanged.
  implication: |
    There is NO positioning defect. The composition treatment is the correct lane, and per the
    constraints it does not have to yield to a geometry fix. Recording this explicitly because it
    is the second time on this element that correct geometry has failed to predict the user's
    perception — the lesson is that "flush" is a property of edges, and the complaint is about a
    property of MASS.

- timestamp: 2026-08-24T01:12:00Z
  checked: What the user is actually reacting to, given the edges are provably flush. Measured the
    legal band's fill ratio and void distribution at every width, and looked at the rendered
    footer in both themes (scratchpad/cur-1280-light.png, cur-1280-dark.png).
  found: |
    The mechanism is FILL, not alignment:

      width    legal band w    meta ink w    fill%    contiguous void
      481          417            241.75     57.97        175.25
      790          726            241.75     33.30        484.25
      1280        1216            241.75     19.88        974.25

    At 1280px the band is 1216px wide holding 241.75px of ink — 80.1% empty, in ONE unbroken
    974.25px run to the right of the text.

    And the stub's right edge aligns with nothing: meta ends at 273.75 while the left cluster ends
    at 396.11. So it starts flush with the brand but dies 122.36px short of the cluster it is
    nominally in a column with. Rendered, the left side reads as a three-line stack — wordmark,
    tagline, then the legal line — where the first two are tight and the third is 32px adrift.
  implication: |
    The legal line does not read as a band; it reads as a fourth line of the brand block that got
    pushed too far down. That is the "orphaned fragment" perception, and it is a MASS/fill problem
    that left-alignment cannot fix — it is caused by 241.75px of ink being asked to occupy a
    1216px band. Critically, this reframes the option space: moving the stub left/centre/right
    only relocates the same 80% void, it does not reduce it.

- timestamp: 2026-08-24T01:20:00Z
  checked: Design record for prior art on a stacked footer, since option B made this footer
    two-tier. Read page-shell.md (sketch 011) "What Was Tried and Rejected".
  found: |
    Sketch 011 explicitly rejected a two-tier footer, and its stated REASON is the user's exact
    complaint arriving from the other direction:

      "Footer: one single row, no divider — not a two-tier Mission Band. The original two-tier
      design ... read as two visually mismatched weights stacked, not one footer."

    The rejected version was heavier (a full-bleed coloured persuasion band), so this is not a
    verbatim repeat. But the failure MODE it names — "two visually mismatched weights stacked" —
    is precisely what a dense 44px utility row above a 18px 20%-filled stub produces.
  implication: |
    Option B did not break a rule (the user chose it, and the no-divider rule is intact), but it
    re-entered a shape this project has already failed once. That raises the bar on the treatment:
    the legal band has to read as a deliberate PEER BAND, not as a thin remainder under a heavy
    row. It also supplies the success criterion — the two tiers must not look like mismatched
    weights — which is a stronger and more honest target than "is it flush".

- timestamp: 2026-08-24T01:35:00Z
  checked: Built and measured 4 placement treatments by injecting CSS/DOM at runtime (no source
    file touched until one is chosen), at 1280px, 560px (the wrapped band) and 320/375/430px
    (mobile), both themes. Harness: scratchpad/variant.js.
  found: |
    At 1280px:

      variant      ink span          fill%   alignsLeft   alignsRight   footerH
      v0 left      32 -> 273.75      19.88      0.00        -974.25       147
      v1 right   1006.25 -> 1248     19.88    974.25           0.00       147
      v2 center   519.13 -> 760.88   19.88    487.13        -487.12       147
      v3 split     32 -> 1248       100.00      0.00           0.00       147

    THE decisive number: v0/v1/v2 all measure the SAME 19.88% fill. They are the same stub in
    three positions — each buys one edge relationship and forfeits the other (v2 forfeits both,
    buying symmetry instead). Only v3 changes the fill ratio, and it is the only treatment where
    BOTH `alignsLeft` and `alignsRight` are 0.00 simultaneously.

    Height is 147px for all four — no variant costs anything on top of option B's accepted +50px.

    THE WRAPPED BAND (560px) SPLITS THEM, and this is not visible at 1280px. There both clusters
    sit at x=32, because `space-between` degenerates to left-flush once each item owns its own
    flex line:
      v0  legal at 32          -> flush with both clusters above. Consistent.
      v1  legal at 286.25      -> the ONLY right-aligned thing in the footer. Reads broken.
      v2  legal at 159.13      -> the ONLY centred thing in the footer. Reads broken (worst).
      v3  copyright at 32      -> flush with both clusters; BGG anchors the band's right edge.

    Mobile (v3 refined with a gap, since `space-between` has no free space once the <=480px block
    shrink-wraps the band and the two pieces would otherwise butt together):
      320/375/430px -> footerH 179 UNCHANGED, zero overflow, run stays exactly centred
      (36.22..283.77 at 320px = centre 160.0 = viewport centre).
  implication: |
    v1 and v2 are wide-desktop-only treatments: both look deliberate at 1280px and both become the
    single odd element in the 481-790px wrapped band, which is a real shipped state (223px tall).
    Had this been judged from a 1280px screenshot alone — the width the user reported from — either
    would have shipped a new defect into a band nobody was looking at.

    v3 is the only treatment that attacks the measured mechanism (fill 19.88% -> 100%) rather than
    relocating the void, and the only one correct in both the wide and wrapped states. Its cost is
    real and must go to the user, not be decided here: it separates the copyright from the BGG
    attribution by ~984px, and this session OPENED with the user complaining those two were not
    aligned. They would remain on one shared baseline (same flex line, `align-items` unchanged), so
    the (A) fix is not undone — but "far apart" is a judgment the user has to make, not me.

- timestamp: 2026-08-24T05:00:00Z
  checked: Treatment D applied to source, then measured on the live app across 28 widths
    (260-1920px) in BOTH themes. Harness: scratchpad/d-measure.js + cdp-sweep.js + d-table.js.
  found: |
    Every invariant holds, and the two themes are byte-identical.

      band fill            19.88% -> 100.00% at every width >=481px
      alignsLeftWithBrand  0.00 at every width >=481px  (© glyph flush with "PUKLLAY CLUB")
      alignsRightWithEdge  0.00 at every width >=481px  (BGG closes the row's right gutter)
      baselineDelta        0.00 at every width >=280px  (the CONSTRAINT — measured via Range
                           over each run's text node, so it is a real baseline, not a box edge)
      sameLine             true at every width >=280px  (one flex line = one shared baseline)
      metaH                18px everywhere (no line-box inflation reintroduced)
      overflow             0 at every width, both themes
      footerH              147 at >=800px, 223 at 481-791px, 179 at 280-480px — IDENTICAL to
                           treatment C at every width >=280px. D costs no additional height.
      group/item tiers     24px / 8px intact at every width — the prior sessions survive.

    The wrapped 481-790px band, which is where v1/v2 broke and which is invisible at 1280px:
    copyright at x=32 flush with both left-flush clusters, BGG anchored to the band's right
    edge, one shared baseline. Screenshot: FINAL-D-560-WRAPPED.png.
  implication: D delivers exactly what the measurement predicted and breaks nothing the three
    prior fixes established. The shared-baseline constraint the user carried in is satisfied at
    the text level, not merely at the box level.

- timestamp: 2026-08-24T05:02:00Z
  checked: Mobile no-regression (<=430px) against the pre-D tree, and the narrow-width floor.
    Both states measured with the same probe (scratchpad/bleed.js) rather than compared from
    memory.
  found: |
    A REAL PRE-EXISTING DEFECT, found by the D sweep rather than by looking for it.

    At 260px the pre-D merged run was 241.75px of nowrap ink inside a 232px flex-item box: the
    text escaped its own box by 9.75px and ran INTO the right gutter. `documentElement
    .scrollWidth` still reported ZERO overflow, because the ink stopped 4.25px short of the
    viewport edge — which is why the earlier "zero overflow down to 260px" claim measured clean
    while the text was already out of bounds. A shrinkable box wrapping unshrinkable text fails
    silently to a document-level overflow probe.

    D fixes it: `flex-wrap: wrap` breaks the band BETWEEN its two pieces, so at 260px the ink
    ends 114.67px inside the band with no bleed at all. Cost: the band takes two lines there,
    footer 179 -> 213px, at a width below any real device (smallest common phone is 320px; 260
    was a stress floor introduced by the tablet-overflow session).

      width        pre-D                             D
      260          bleeds 9.75px into the gutter     wraps clean, 213px, no bleed
      280-480      179px, centred                    179px, centred — UNCHANGED
      320          run 39.13..280.88 (241.75)        run 36.22..283.77 (247.55), centre 160.0
                                                     = viewport centre exactly

    The +5.8px width is the "·" plus its two spaces being replaced by the 16px group-tier gap.
  implication: Mobile does not regress at any real device width — identical height, identical
    centring, zero overflow. Below 280px D is strictly BETTER than the state the user approved,
    because it contains text that previously escaped into the gutter. Recording the pre-existing
    bleed explicitly: it was invisible to the overflow gate that has guarded this footer through
    three sessions, and that gate's blind spot is now covered by its own test.

- timestamp: 2026-08-24T05:05:00Z
  checked: Boundary neighbours on the defect's own equivalence class — the `justify-content`
    values that LOOK like distribution but anchor nothing. Injected each at runtime at 1280px.
    Harness: scratchpad/near-miss.js.
  found: |
      justify           fill%    alignsLeftWithBrand    alignsRightWithBandEdge
      space-between    100.00                   0.00                       0.00
      space-around      60.51                 240.11                    -240.11
      space-evenly      47.34                 320.14                    -320.16
      center            21.02                 480.22                    -480.23
      flex-end          21.02                 960.45                       0.00
      normal            21.02                   0.00                    -960.45

    Only `space-between` anchors a piece to each edge. `space-around`/`space-evenly` reserve a
    half- or third-gap OUTSIDE the first and last item, so they reproduce the reported defect at
    60.51%/47.34% while reading as a deliberate distribution choice in code review.
  implication: A guard that merely refuted `flex-start` would have admitted both near-misses.
    The regression test refutes all four non-anchoring values by name and carries these measured
    numbers in its failure message, so a future edit is told what it costs rather than just that
    it is disallowed.

## Investigation guidance (from orchestrator pre-check)

- A resolved session on this exact element exists from earlier today:
  `.planning/debug/resolved/footer-desktop-overloaded.md`. Read it first — it already
  measured and fixed the spacing-hierarchy/grouping problem in `.pk-footer-right` and
  established the current token scale (`--pk-footer-gap-item/list/group/cluster`). Do not
  re-derive that work; treat its Resolution as the starting state of the footer.
- The user's own message frames this explicitly as wanting industry-standard footer best
  practices research, not just a narrow CSS tweak — the investigation should look outward
  (common footer patterns: legal/copyright rows separated from nav content, multi-column
  grouped footers, attribution placement conventions) as candidate causes/fixes for the
  "still overloaded" complaint, in addition to measuring the concrete alignment defect.
- The prior session's checkpoint asked the user to choose between keeping the 3-concern
  right cluster as-is (chosen: "keep as fixed") vs. shedding a concern into its own row —
  the user declined shedding a concern at that time. Given the same-day follow-up
  complaint, it is reasonable to re-offer restructuring alternatives at this session's own
  checkpoint rather than assume that decision is still final — but do not silently revert
  or restructure without a checkpoint, since it was an explicit prior choice.

## Eliminated

- hypothesis: "This is a regression from the same-day footer-desktop-overloaded fix — its spacing
    tokens or the new `.pk-footer-theme` wrapper broke the meta line's alignment."
  evidence: Measured the live app before touching anything: the group tier still separates the
    right cluster's three concerns at exactly 24px (social->theme, theme->meta) and the item tier
    still binds "Tema" to its toggle at 8px, at every width >=700px. All four tokens present, tier
    order intact, zero overflow. That fix is doing its job untouched. Separately, the alignment
    defect is produced by `inline-flex` on `.pk-bgg-note`, which has been in the markup since
    01.1-01 (2026-08-21) — two days BEFORE that session. Pre-existing, not a regression.
  timestamp: 2026-08-23T23:26:00Z

- hypothesis: "The 'not aligned' complaint is about HORIZONTAL alignment — the meta line's right
    edge not lining up with the cluster/gutter above it, or the two clusters sitting on different
    vertical centres."
  evidence: `.pk-footer-meta` ends at x=1248, exactly the 1280-32 gutter edge, flush with every
    other capped section. Both clusters share a vertical centre at y=5482.19 (left top 5458.19 +
    24 = right top 5460.19 + 22); their differing top coordinates are just their differing heights
    under `align-items: center`, not a misalignment. The real defect is VERTICAL and INTERNAL to
    the meta line: a 5.00px baseline split between two text runs 20px apart horizontally.
  timestamp: 2026-08-23T23:12:00Z

- hypothesis: "The remaining 'overloaded' feeling is still a PROXIMITY/spacing problem, so the fix
    is to widen the group tier further or add a fourth spacing tier."
  evidence: The spacing hierarchy measures correct and is already at a 3x item/group contrast. Ink
    analysis found the actual asymmetry is in a channel spacing cannot reach: the least important
    concern (`meta`) carries 59.9% of the right cluster's ink mass, and an 18px compliance mark
    carried as much ink as the entire four-icon social row. Adding more space between concerns
    cannot fix a weight inversion INSIDE one of them — and would have cost footer height and pushed
    the single-line threshold further right for no benefit.
  timestamp: 2026-08-23T23:34:00Z

- hypothesis: "The user's report 'Copyright and BGG compliance doesn't look correctly aligned to
    left' is a POSITIONING defect — `.pk-footer-legal`'s left edge is genuinely offset from
    `.pk-footer-left`'s by a gutter, margin or sub-pixel error."
  evidence: Measured live at 15 widths, at BOTH the box edge and the rendered INK edge (Range over
    the first text node, so font side-bearing is included rather than assumed away). At every width
    from 481px to 1920px: d_box(legal - left) = 0.00, d_box(meta - left) = 0.00, and
    d_ink(© glyph - "PUKLLAY CLUB" glyph) = 0.00. Both first painted pixels land on x=32.00 at
    1280px. The only non-zero deltas are <=430px, where the stack is deliberately centred and
    `.pk-footer-legal` is `width: auto` — two centred boxes of different widths necessarily differ
    in x, and footerH there is the unchanged 179px. Refuted at the strongest available resolution;
    the complaint is about visual mass, not edges.
  timestamp: 2026-08-24T01:05:00Z

- hypothesis: "Left/centre/right are three meaningfully different fixes for the orphaned-fragment
    reading, so picking the best ALIGNMENT for the legal stub will resolve it."
  evidence: All three measure an identical 19.88% band fill at 1280px (241.75px of ink in a 1216px
    band). They relocate the same 974.25px void rather than reducing it: left forfeits the right
    edge relationship (-974.25), right forfeits the left (+974.25), centre forfeits both (+/-487).
    Alignment cannot change a fill ratio. Only splitting the line into two edge-anchored pieces
    moved the number (19.88% -> 100%). Kept as a live option set for the user anyway, because
    which void placement LOOKS best is a judgment call — but recorded here so the fill finding is
    not mistaken for a preference.
  timestamp: 2026-08-24T01:35:00Z

- hypothesis: "Reduce the mark's dominance by desaturating / fading / stripping the background off
    the BGG logo — the direct way to kill a 0.32-chroma 100%-ink tile."
  evidence: BGG's terms state the BoardGameGeek logo is a trademark of BoardGameGeek, LLC and that
    you "may not frame or utilize framing techniques to enclose any trademark, logo, or other
    proprietary information" without written consent. The exact XML API attribution clause could
    not be retrieved to confirm what latitude exists. Under that uncertainty, altering a trademark's
    appearance is not a unilateral call. Additionally, the dark-theme measurement showed a
    contrast-based tweak would be actively wrong: the tile already camouflages on dark
    (ink mass/px 0.054, below the nav links' 0.089), so reducing its contrast would help light and
    over-hide it on dark. Scaling is ordinary permitted use and is the only lever that improves
    both themes at once.
  timestamp: 2026-08-23T23:52:00Z

## Resolution

- root_cause: |
    Two independent defects sharing one culprit element, `.pk-bgg-note`. Neither is a regression;
    both predate footer-desktop-overloaded and survived it untouched because that session was
    scoped to proximity.

    (A) ALIGNMENT — single cause, AND-gate does not fire.
        The attribution anchor carried `inline-flex items-center gap-1` while living inside a text
        run ("© {year} Pukllay Club · " immediately precedes it). Per CSS Flexbox §8.3, an
        inline-level flex container with no baseline-aligned item — and `align-items: center`
        removes every one — must SYNTHESIZE its baseline from the first flex item's border box.
        The first item is the 18px logo, so the IMAGE'S BOTTOM EDGE became the link's baseline.
        Measured: the copyright text's baseline (5491.69 - 3px descent = 5488.69) and the img's
        bottom edge (5488.69) coincided exactly. Consequences: "Powered by BGG" sat 5.00px above
        the copyright text it annotates, and the meta line box was inflated from 18px to 23px.

    (B) VISUAL-WEIGHT HIERARCHY INVERTED — AND-gate FIRES, two contributing causes.
        (B1) The mark is an opaque 400x400 JPEG with a baked-in dark background rather than a
             transparent glyph, so it renders as a solid tile: 100% ink, meanChroma 0.32.
        (B2) It was sized "~18px (roughly text line-height)" (01.1-01-SUMMARY.md:49). Line-height
             is the wrong reference metric for an inline mark — matching the line box means filling
             it edge to edge, which is both why the line inflated and why the tile stood at ~2x the
             cap height of the 12px type beside it.
        Together (light theme, 1280px): 12.1x the social row's per-pixel ink density, and those
        324px² carried as much total ink mass (248.08) as the ENTIRE four-icon social row (240.84)
        spread over 11.75x the area. The footer's loudest object was its least important content.
        AND-gate: neither alone suffices — a transparent mark at 18px reads as an icon, an opaque
        tile at cap-height is too small to shout. Both were required.
        Scope correction from the dark-theme check: (B)'s ink-mass half is LIGHT-THEME-ONLY (on
        dark the tile camouflages and ranks below the nav links); its chroma half holds in both.

    (C) STRUCTURAL ASYMMETRY — the residue (A) and (B) could not reach, settled by user decision B.
        `.pk-footer-right` carried three concerns of two different KINDS: two interactive utilities
        (social, theme) plus one passive compliance run (the copyright + BGG line). Sketch 011
        specified the two clusters as PEERS; measured at 1280px they were not — right 604.81px/3
        concerns against left 364.11px/2 (1.66x), with `.pk-footer-meta` alone accounting for 59.9%
        of the right cluster's ink mass on 40.7% of its width.
        This is NOT a spacing defect and was provably not fixable by spacing: footer-desktop-
        overloaded's four-tier scale was re-measured fully intact (8/24/32px, zero overflow) at the
        moment the complaint was re-reported. Proximity can only say "these belong together"; the
        problem was that they don't. Fix direction therefore had to be structural — KIND maps to
        ROW — and because it changes a shape the user had explicitly chosen once before, it went to
        a checkpoint rather than being applied unilaterally.

    WHY IT SURVIVED: page-shell.md:69-75 already required this attribution be "de-emphasized ...
    not a bordered, backgrounded 'badge' competing visually with the rest of the footer ... no box".
    D-04 later satisfied the compliance WORDING ("Powered by BGG" + logo) and silently dropped that
    co-equal half — an opaque JPEG IS the badge, no CSS box required. Nobody chose it; it arrived
    as a side effect of an asset format. 01.1-01-SUMMARY.md:117 flagged exactly this
    `human_judgment: true` ("the BGG logo's visual sizing/placement ... is a judgment call flagged
    for human confirmation") and it was never confirmed. This report is that confirmation arriving.
- fix: |
    1. `.pk-bgg-note` is now PLAIN INLINE — `inline-flex items-center gap-1` removed from the
       anchor (layouts.ex). The attribution words therefore share one inline formatting context,
       and so one baseline BY CONSTRUCTION, with the copyright text they follow. Deliberately not
       a `vertical-align: -5px` compensator: that would hard-code the output of the very
       computation that was wrong and break on the next font-size or logo-size change.
    2. The words are wrapped in a `<span>` and the underline moved from the anchor onto it
       (app.css). On a plain-inline anchor an anchor-level underline is drawn straight across the
       logo tile; page-shell.md's "underlined small print" requirement survives intact.
    3. `.pk-bgg-note img` gains `display: inline-block` (Tailwind preflight sets `img{display:block}`,
       which would split the anchor's inline flow) + `vertical-align: middle` (self-adjusting to the
       parent's x-height, no magic offset) + `margin-right: 0.25rem` replacing the removed `gap-1`.
    4. The mark is 18px -> 14px, re-grounded on the TYPE it annotates rather than the line box it
       sits in. Colour, saturation, opacity and background are untouched — trademark, see Eliminated.

    (C) STRUCTURAL — alternative B, as chosen by the user at the checkpoint. A + B are preserved
    unchanged underneath it.

    5. The copyright + BGG line moved out of `.pk-footer-right` into its own `.pk-footer-legal`
       band, a direct child of `.pk-footer-row` and a peer of the two clusters (layouts.ex).
       The right cluster drops to two concerns and matches the left's two; measured width ratio
       1.66x -> 1.09x.
    6. `.pk-footer-legal { width: 100% }` is the entire break mechanism — a full-width item can
       never share a line in a wrapping flex row, so the band exists at every width from 481px up.
       Deliberately NOT `flex-basis: 100%`: flex-basis is the MAIN size, so it would silently
       become a HEIGHT at <=480px where the row turns into a column. `width` is correct in both
       orientations and needs no media-query patch to work.
    7. No fifth spacing token. The separation above the band is `.pk-footer-row`'s own row-gap —
       the cluster tier — because the legal band is a peer top-level block, not a super-group. All
       four tokens from footer-desktop-overloaded are untouched, and sketch 011's no-divider rule
       holds: the gap does the work, there is no border between the rows.
    8. `.pk-footer-legal` is also `display: flex`, to suppress its own strut. As a plain block it
       inherited the footer's 1rem font-size and rendered the 0.75rem legal line inside a 24px
       anonymous line box, silently adding 6px to the footer at EVERY viewport including mobile.
    9. Two mobile-only consequences of the move, both found by measurement and both fixed in the
       <=480px block: `.pk-footer-legal { width: auto }` returns the band to the centred stack
       (it had left-aligned to the gutter while everything above stayed centred, x 39.13 -> 14 at
       320px), and the hide rule became `.pk-footer-right { display: none }` instead of hiding its
       two children — flex `gap` skips a hidden child but still spends a slot on an empty visible
       parent, which would have pushed the legal line 24px further down the mobile stack.

    (D) FILL — treatment D, as chosen by the user at the decision checkpoint. A + B + C are
    preserved unchanged underneath it.

    10. The legal run is SPLIT into two sibling `.pk-footer-meta` spans — copyright, attribution
        — and the inline "·" separator is dropped (layouts.ex). Two items is the fix, not a
        formatting preference: `justify-content: space-between` distributes free space BETWEEN
        items, so over a single item it is a silent no-op and the band returns to a 19.88% stub
        with the stylesheet still reading as if it were anchored.
    11. `.pk-footer-legal` gains `justify-content: space-between`, which anchors one piece to
        each edge of the band and takes its fill from 19.88% to 100.00%. This attacks the
        measured mechanism instead of relocating it: left, centre and right all measured the
        IDENTICAL 19.88%, because alignment moves a void rather than reducing one.
    12. `align-items: baseline` — a CONSTRAINT, not a default. The two pieces now sit ~984px
        apart at 1280px, and this session opened with a report that they were not aligned. The
        initial `stretch` default also aligned them, but only because both boxes measured
        exactly 18px; baseline alignment makes the shared baseline structural at any separation
        and survives a future font-size or logo-size change. Measured 0.00px at every width.
    13. `gap: var(--pk-footer-gap-group)` — load-bearing on mobile, a no-op on desktop.
        `space-between` has no free space to distribute once the <=480px block shrink-wraps the
        band to `width: auto`, so without it the two pieces butt together on the primary
        viewport. The group tier is correct because these are two distinct concerns.
    14. `flex-wrap: wrap` — the narrow-width escape, and it fixes a pre-existing silent defect
        rather than only serving the split. Both pieces are `white-space: nowrap`, so below the
        width where both fit the band now breaks BETWEEN them. Pre-D at 260px the merged run
        overflowed its own shrunk flex item by 9.75px and ran into the right gutter while
        `scrollWidth` reported zero overflow — a shrinkable box holding unshrinkable text fails
        invisibly to a document-level overflow probe.
- verification: |
    guardrail_verdict: accepted

    - regression_test: 7 new tests in test/pukllay_club_web/footer_attribution_test.exs.
      Oracle type: derived (contract) — ExUnit cannot observe rendered geometry or pixels, so the
      tests pin the declarations geometry depends on. RED-verified honestly: stashing the fix
      produced 5 failures of 7. The other 2 were green pre-fix and are labelled in the file as
      forward-looking guards, NOT counted as evidence this fix worked (they close the alternate
      CSS route to the same mechanism, and guard against a non-uniform resize distorting a
      trademark). Boundary neighbour on the defect's own equivalence class: the size bound is
      expressed as a RATIO to `.pk-footer-meta`'s declared font-size, not a literal, because the
      invariant is "sized against the type it annotates" — a hard-coded 14 would still pass if the
      small print were rescaled underneath it. Bound is [1.0x, 1.25x] of font-size.
    - mutation_check: PASS, targeted at the fix site. 16px -> the size test FAILS with the ratio
      message (1.33x); 18px (the original defect) -> FAILS; 15px and 12px -> pass, confirming the
      bound is inclusive where intended and not accidentally pinned to one value.
    - revert_check: PASS. `git stash` of the two source files restores the defect conditions and
      5 of the 7 tests fail; `stash pop` returns all 7 green.
    - live_geometry: PASS. CDP sweep of the running app at 320/375/430/481/652/700/900/1024/1060/
      1070/1280/1440/1920px. **baselineDeltaPx = 0 at EVERY width** (was 5.00px), metaH = 18px at
      every width (was 23px), overflowPx = 0 at every width (the footer-overflow-tablet-width fix
      is intact), and the prior session's tiers survive untouched — 24px group gaps, 8px item gap.
      Mobile footer height improved 184px -> 179px as a side effect of the de-inflated line box.
    - live_pixels: PASS. Light theme, re-measured: the mark's ink mass falls 248.08 -> 150.07
      (-39.5%), so it no longer equals the four-icon social row (240.88) but sits at 62% of it, and
      its share of the right cluster's ink drops 18.9% -> 12.4%. Note honestly: its per-pixel
      density is unchanged at 0.7657, because the tile is still opaque — only its area shrank. That
      is the ceiling of what a size-only lever can do under the trademark constraint.
    - both_themes: PASS. Rendered and inspected at 1280px in light and dark; alignment correct in
      both, and dark is unharmed by the size change (the tile already camouflaged there).
    - full_suite: PASS. 373 tests, 0 failures (was 366; +7 new).
    - static_gates: PASS. `mix format --check-formatted` clean. `mix credo --strict` reports only
      the pre-existing `core_components.ex:214` nested-alias suggestion, untouched by this change.
    - not_deletion_only: PASS. 79 insertions / 9 deletions across two files, plus a new test file.
      No content, functionality or compliance requirement was removed — the attribution keeps its
      exact required wording, its link, and its logo.

    - human_verify (A + B): CONFIRMED. The user reviewed the working tree at desktop width in both
      themes and confirmed the copyright and "Powered by BGG" sit on one baseline and the BGG mark
      reads proportionate rather than dominant. A and B are closed and are NOT to be re-litigated.

    --- (C) STRUCTURAL, the checkpoint's chosen alternative B ---

    guardrail_verdict: accepted

    - regression_test: 9 new/rewritten guards. FooterRhythmTest gains a describe block for the
      legal band (full-width row outside both clusters; cluster symmetry left==right; width-based
      break with an explicit refutation of `flex-basis: 100%`; `display: flex` strut suppression;
      no border, per sketch 011; the <=480px centring reset; the <=480px cluster hide) and its
      child-count assertion moves 3 -> 2. FooterOverflowTest's hide test moves to the cluster
      selector and its meta-floor test now pins the full-width band instead of cluster wrapping.
      Oracle type: derived (contract) — ExUnit cannot observe rendered geometry, so these pin the
      declarations and structure the measured geometry depends on.
    - red_check: PASS, honestly. `git stash` of the two source files fails 9 of these guards (plus
      the 5 pre-existing (A)/(B) attribution guards, which is the expected carry-over). Every one
      of the 9 was verified failing against the pre-change tree, not merely passing after it.
    - mutation_check: PASS, 6 mutations at the fix site, each caught by the intended guard:
      `width: 100%` -> `flex-basis: 100%` (the direction trap) -> 2 failures; dropping
      `display: flex` (the strut bug) -> 1; dropping the <=480px `width: auto` (mobile centring)
      -> 1; reverting to per-child hides -> 2; adding a `border-top` (sketch 011's divider) -> 1;
      moving `.pk-footer-meta` back into `.pk-footer-right` -> 4.
    - revert_check: PASS. Stashing restores the defect conditions; `stash pop` returns all green.
    - live_geometry: PASS. CDP sweep at 260/320/375/430/481/560/652/700/790/800/900/1024/1070/
      1280/1440/1920px in BOTH themes, byte-identical between them. Cluster ratio 1.66x -> 1.09x
      (604.81/364.11 -> 335.06/364.11), concerns 3 -> 2 matching the left's 2. Zero horizontal
      overflow at every width. Everything the two prior sessions fixed survives: baselineDelta
      0.00px, metaH 18px, item tier 8px, group tier 24px, cluster tier 32px. Legal band and both
      gutter edges align at x=32 / right edge 1248 at 1280px, flush with `.pk-nav-inner`.
    - mobile_no_regression: PASS. 179px tall at <=430px — identical to before the change — same
      centred stack (meta x=39.13 at 320px, 66.63 at 375px, both exactly the pre-change values),
      same 24px separation before the legal line, zero overflow down to 260px. Two mobile defects
      introduced mid-implementation (left-aligned legal band; an empty right cluster spending a gap
      slot) were caught by measurement and fixed before this claim.
    - live_pixels: PASS with an honest scope note. Within the content row, weight now descends
      correctly for the first time — brand 0.1497 > links 0.1341 > social 0.0633 > theme 0.0370
      mass/px — and the legal band is the QUIETEST region in the footer at 0.0314, where `meta` was
      previously the densest concern in its cluster and 59.9% of its ink. NOT claimed: the literal
      "ink/void" numbers the checkpoint named. Cluster ink-mass ratio went 1.26x -> 3.13x and the
      central void 247.08px -> 516.83px, both direct consequences of the intended move. B resolves
      the CONCERN-COUNT and WIDTH imbalance; it does not resolve an ink-mass one.
    - height_cost: ACCEPTED, and larger than estimated at the checkpoint. +50px at >=1070px (the
      18px line plus one 32px cluster-tier gap — the gap cannot go below the cluster tier without
      re-inverting proximity in the 481-790px wrapped band), +8px to +50px across 481-790px, and
      -26px across 800-1069px, where the main row now fits on one line 279px earlier (single-line
      threshold 1070px -> 791px). Mobile unchanged. The checkpoint said "~20px"; the real figure at
      wide desktop is 50px and that estimate miss is flagged rather than buried.
    - full_suite: PASS. 379 tests, 0 failures (was 373; +6 net after rewrites).
    - static_gates: PASS. `mix format --check-formatted` clean. `mix credo --strict` reports only
      the pre-existing `core_components.ex:214` nested-alias suggestion, untouched by this change.
    - not_deletion_only: PASS. No content, functionality or compliance requirement removed — the
      attribution keeps its exact required wording, its link and its logo, and is now asserted to
      render OUTSIDE the cluster that gets hidden on phones, which is a stronger D-04 guarantee
      than before. The <=480px hide rule got shorter (two selectors -> one), but that is a
      simplification the moved content made valid, and it is covered by its own guard.

    - human_verify (C): SUPERSEDED by the (D) decision checkpoint. The user reviewed the split
      footer, kept the band, and rejected only its left-aligned placement — which is what
      treatment D resolves.

    --- (D) FILL, the decision checkpoint's chosen treatment ---

    guardrail_verdict: accepted

    - regression_test: 6 new tests in FooterRhythmTest ("the legal band's ink reaches both edges
      instead of stubbing at one") plus 3 updated assertions across FooterRhythmTest and
      FooterOverflowTest. Oracle type: derived (contract) — ExUnit cannot observe rendered
      geometry, so these pin the declarations and structure the measured geometry depends on.
      Boundary neighbours on the defect's OWN equivalence class: the guard refutes
      `space-around`, `space-evenly`, `center` and `flex-end` by name, not merely `flex-start`,
      because the first two distribute free space while still anchoring nothing (measured 60.51%
      and 47.34% fill, 240px and 320px off the brand edge) and would have passed a naive check.
    - red_check: PASS, honestly. The working tree was reduced from D back to C — NOT `git stash`,
      because A/B/C are all uncommitted and stashing would have reverted four fixes at once and
      manufactured failures that say nothing about D. 8 of the 9 changed/new assertions failed
      against the pre-D source. The 9th ("the full-width band holds at every width above the
      mobile breakpoint") was green pre-change and is labelled a forward-looking guard — it is
      NOT counted as evidence this fix worked; it closes the route by which a future `width:
      auto` at a wider breakpoint would break the 481-790px band silently.
    - mutation_check: PASS, 11 mutations at the fix site, all killed. space-between -> flex-start;
      -> space-around; align-items baseline -> center; align-items dropped; gap dropped; gap
      token -> literal; flex-wrap dropped; width:100% -> flex-basis:100%; the two pieces
      re-merged; the "·" re-added; a border-top added.
      A HARNESS BUG WAS FOUND AND FIXED MID-CHECK, and it matters: the first run reported 3
      survivors, but `String.replace` with a string pattern hits the FIRST occurrence in the
      file, and `justify-content: space-between;` appears 7 times in app.css while
      `  width: 100%;` appears twice — so those mutations were silently mutating unrelated rules
      at lines 334/393 and the guards were never actually challenged. Scoping every CSS mutation
      to the `.pk-footer-legal` block killed all three. A mutation check that mutates the wrong
      code reports false gaps, and would equally report false PASSES in the other direction.
    - revert_check: PASS. Reducing the source to C restores the defect conditions and the guards
      fail; restoring D returns all green.
    - live_geometry: PASS. CDP sweep, 28 widths from 260px to 1920px, in BOTH themes, results
      byte-identical between them. fill 19.88% -> 100.00% and BOTH edge deltas 0.00 at every
      width >=481px; baselineDelta 0.00 and sameLine true at every width >=280px; metaH 18px;
      zero overflow everywhere. Everything the three prior fixes established survives: group tier
      24px, item tier 8px, cluster tier, no overflow. Wrapped 481-790px band verified explicitly
      at 481/500/540/560/600/650/700/750/780/790/791px — the band where the rejected right and
      centre treatments broke, and which is invisible in the 1280px screenshot this was reported
      from.
    - mobile_no_regression: PASS at every real device width. 179px tall and identically centred
      at 280-480px (at 320px the run spans 36.22..283.77, centre 160.0 = viewport centre
      exactly). The run is 5.8px wider than before — the "·" plus its two spaces replaced by the
      16px group-tier gap. Below 280px the band wraps to two lines (213px at 260px), which is a
      deliberate improvement, not a regression: see height_cost.
    - pre_existing_defect_fixed: at 260px the pre-D merged run was 241.75px of nowrap ink in a
      232px box — the text escaped its own flex item by 9.75px into the right gutter, while
      `documentElement.scrollWidth` reported ZERO overflow because the ink stopped 4.25px short
      of the viewport edge. Three sessions of "no overflow down to 260px" measured clean over a
      text bleed. `flex-wrap: wrap` fixes it (114.67px of clearance, no bleed), and the blind
      spot now has its own test.
    - both_themes: PASS. Rendered and inspected at 1280px light/dark, 560px wrapped and 375px
      mobile. Screenshots at .planning/debug/assets/footer-legal-options/FINAL-D-*.png.
    - height_cost: NONE at any width >=280px — 147/223/179px, identical to treatment C. The
      accepted +50px from C is not added to. At 260-279px the footer grows 179 -> 213px because
      the band wraps; that is below any real device (smallest common phone is 320px) and it
      replaces a text bleed, so it is taken as a strictly better trade rather than a cost.
    - full_suite: PASS. 385 tests, 0 failures (was 379; +6 new).
    - static_gates: PASS. `mix format --check-formatted` clean. `mix credo --strict` reports only
      the pre-existing `core_components.ex:214` nested-alias suggestion, untouched by this change.
    - not_deletion_only: PASS. The D slice adds 4 CSS declarations and splits one span into two;
      the only removal is the now-meaningless "·" separator. No content, functionality or
      compliance requirement removed — the attribution keeps its exact required wording, its link
      and its logo, and is still asserted to render outside the cluster hidden on phones.

    - human_verify (D): PENDING — the user chose D from measured options and screenshots, but has
      not yet seen it applied in their own browser.

    prevention: |
      why not caught: no gate existed for this class, twice over.

        (1) COMPOSITION. Every footer gate to date is functional — overflow, wrap thresholds,
        spacing-token ordering, structure. A band can pass all of them while holding 19.88% ink
        in 80.1% void, because none of them can express "does this band's ink reach its edges".
        The defect was introduced BY the previous fix in this same session (promoting the legal
        line to its own full-width row), which is the sharpest possible demonstration: a fix
        that satisfies every existing gate can still create the next complaint.

        (2) SILENT INK BLEED. `footer_overflow_test.exs` and three sessions of CDP sweeps all
        asserted on `documentElement.scrollWidth`. That probe cannot see a shrinkable flex item
        whose unshrinkable nowrap text has escaped its box but not yet reached the viewport
        edge — which is exactly what was happening at 260px the whole time. Worse, that test's
        own comment had PREDICTED the failure ("if a second nowrap sibling were ever added
        beside it without wrapping, the floor becomes their sum again") without anyone noticing
        the single-item case was already leaking.

      guard: test/pukllay_club_web/footer_rhythm_test.exs — a 6-test describe block pinning the
        edge-anchoring mechanism (two pieces, since space-between over one is a no-op),
        `justify-content: space-between` with all four non-anchoring near-misses refuted BY NAME
        and by measured fill percentage, the shared-baseline constraint (`align-items: baseline`,
        with box-edge alignments refuted), the mobile gap floor, the wrap escape, the
        wide-cascade `width: auto` trap, and the removal of the "·" separator. Plus
        test/pukllay_club_web/footer_overflow_test.exs — its single-item assumption test is
        rewritten around the mitigation (`flex-wrap: wrap`) now that the warned-of two-nowrap-
        sibling condition is real, and it carries the measured 260px bleed numbers so the next
        reader knows scrollWidth is not a sufficient oracle for this element. All 11 fix-site
        mutants are killed by these guards.
- files_changed:
    - lib/pukllay_club_web/components/layouts.ex (bgg_attribution/1: plain inline anchor, text span, 14px mark; footer/1: .pk-footer-legal band, legal run split into two edge-anchored spans, "·" dropped, rationale comments)
    - assets/css/app.css (.pk-bgg-note inline treatment, underline moved to the span, img alignment rule; .pk-footer-legal band + space-between/baseline/gap/wrap; <=480px centring reset + cluster hide; rationale comments)
    - test/pukllay_club_web/footer_attribution_test.exs (new — 7 regression tests for A + B)
    - test/pukllay_club_web/footer_rhythm_test.exs (legal-band describe block, child count 3 -> 2, new edge-anchoring/baseline/wrap describe block)
    - test/pukllay_club_web/footer_overflow_test.exs (cluster-level hide, two-nowrap-piece floor rewritten around flex-wrap, legal line rendered outside the hidden cluster)
