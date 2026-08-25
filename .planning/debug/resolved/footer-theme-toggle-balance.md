---
status: resolved
# All three flagged tradeoffs are human-CONFIRMED and ACCEPTED. Do not revert or re-litigate:
# (a) the footer's "Tema" label stays SR-ONLY — the reversal of 01.1-08-PLAN.md's discoverability
#     decision is accepted on the Geist evidence. Do NOT restore the visible text label.
# (b) the footer theme buttons stay 28px — accepted against the repo's 44px floor at 481-1024px,
#     on WCAG 2.2 SC 2.5.8's 24px AA minimum plus consistency with the 28px social links in the
#     same row. Do NOT bump to 32px or back to 44px. The mobile drawer keeps its 44px floor.
# (c) the left/right cluster width ratio 1.087x -> 1.468x is accepted as fine. No further layout
#     change for cluster balance.
trigger: "For desktop version, the footer was wrong balance for social links and theme color. Tema takes too much attention (even tema label looks like breaks rhythm). shouldn't this be a simple toggle switcher? what does community have? I think the hierarchy is social links are more important than theme switcher. BE sure to research industry patterns for this"
created: 2026-08-24T09:26:48.000Z
updated: 2026-08-24
---

## Current Focus

bug_class: Bohrbug (deterministic — static CSS/markup, reproduces at every desktop width, both themes)
known_pattern_candidate: "footer-desktop-imbalance + footer-desktop-overloaded — same footer, same
  right cluster, prior sessions fixed PROXIMITY (spacing tiers) and KIND (legal band promoted out).
  Neither touched the theme control's BOX SIZE. Prior quick task 260824-7mt tried subordination via
  glyph-only levers (fade 75%, 16->14px, tone active) — ink channel only, footprint untouched."
hypothesis: >
  The theme control out-weighs the social links because its BOX geometry, not its ink, is oversized:
  3 buttons x 44px (min-h-11 min-w-11) + 2x2px gap = 136px, exactly equal to the entire 4-icon
  social row (4x28 + 3x8 = 136px), and .pk-footer-theme adds the 31.1px "Tema" label + 8px item gap
  on top, making the subordinate concern 175.1px against the dominant concern's 136px (1.29x).
  Per-control area is worse: 3 x 1936px^2 vs 4 x 784px^2 = 1.85x. The 260824-7mt glyph shrink to
  14px made the box/ink ratio WORSE, not better: 3x14 = 42px of glyph inside 136px of footprint is
  30.9% fill, against the social row's 4x28 = 112px inside 136px = 82.4% fill — so the theme control
  reads as a wide sparse band and the social row as four dense discrete objects.
test: measure the rendered footer geometry at desktop widths in both themes via CDP
expecting: >
  .pk-footer-theme wider than .pk-footer-social; theme-button box 44px vs social 28px; theme glyph
  14px vs social 16px (ink already subordinate, footprint not)
outcome: >
  CONFIRMED and fixed. All five guardrail signals pass (see Resolution.verification): 15/15 mutants
  killed, 390 tests green, `mix quality` exit 0, geometry re-measured byte-identical across 10
  width/theme combinations, mobile untouched.
next_action: >
  NONE — session closed. Human verification came back on 2026-08-24 as full sign-off with no
  requested changes: all three surfaced tradeoffs were ACCEPTED as implemented (see
  Resolution.verification.human_verify for the itemised answers). The fix is committed and this
  session file is archived to .planning/debug/resolved/ with the knowledge base updated.

  Recording the shape of that closure honestly, because this footer has now had a `human_verify`
  turn out premature twice (footer-desktop-overloaded's blind spot #1, closed CONFIRMED and
  falsified by a same-day re-report). What the user confirmed here is that the delivered geometry
  reads correctly AND that three named costs are acceptable — not that no cost exists. The three
  are deliberate, documented tradeoffs that were surfaced and accepted, NOT defects that
  disappeared under measurement. The 28px touch target in the 481-1024px band in particular is a
  real, knowingly-accepted deviation from this repo's own 44px floor, and it should be re-opened
  as a decision (not re-diagnosed as a bug) if touch-tablet feedback ever contradicts it.

reasoning_checkpoint:
  hypothesis: >
    The footer's theme control out-weighs the social links because its BOX geometry is oversized
    while its INK was shrunk — the two levers point in opposite directions. Three bare 44x44px
    buttons (the global touch floor from 260821-dah, never re-measured against the 28x28 social
    links beside them) span exactly 136.00px, identical to the entire 4-icon social row, and the
    31.06px visible "Tema" label plus its 8px gap take the theme concern to 175.06px = 1.287x the
    social row. Because the buttons are bare (no border/background), those 136px hold only 3x14px
    of glyph — 30.88% ink fill against social's 82.35% — so the control reads as a wide, sparse
    band claiming primary real estate for a subordinate concern.
  confirming_evidence:
    - "Measured directly via CDP on the running app at 5 widths x 2 themes, byte-identical at all
       10: social row 136.00px / theme toggle 136.00px / .pk-footer-theme 175.06px (1.287x)."
    - "Per-item area ratio theme-button:social-link = 2.469x (44x44 vs 28x28), measured."
    - "Theme buttons are the tallest objects in the cluster and set .pk-footer-right's 44px height
       on their own; the social row is 28px."
    - "Ink fill 30.88% (theme) vs 82.35% (social), measured — the 260824-7mt glyph shrink to 14px
       LOWERED this number inside an unchanged box, which is why that ink-only fix failed."
    - "Vercel Geist ships the inverse for footers: box 24px (data-[small]:h-6), glyph 16px
       (size-4) — small box, full glyph. This repo has a large box and a shrunk glyph."
  falsification_test: >
    Shrink ONLY the footer-scoped button box to 28px (matching .pk-footer-social a exactly) and
    change nothing else, then re-measure. If the hypothesis is right, .pk-theme-toggle drops
    136.00px -> 88.00px (0.647x of social), cluster height drops 44px -> 28px, and ink fill rises
    30.88% -> 47.73%. If the control still reads as dominant after that, the binding constraint was
    never footprint and the hypothesis is refuted.
  fix_rationale: >
    Addresses the root cause (footprint), not the symptom (perceived weight). Every prior fix moved
    ink; this moves the one channel never touched. Sizing the theme buttons to 28px is not an
    invented number — it is .pk-footer-social a's own value, so the cluster's two icon rows finally
    share ONE sizing system instead of two, which is a consistency repair against an in-repo pattern
    (KB lesson (iv)) rather than a new design. The 44px floor is preserved where it is actually the
    touch surface: min-h-11/min-w-11 stay on the shared component for the mobile drawer, and the
    override is scoped to .pk-footer-theme only. The label is CONVERTED, not deleted — it stays in
    the DOM as the control's sr-only accessible group name, which keeps the documented decision's
    intent, matches Geist's sr-only <legend>, and is a net a11y gain (no group label exists today).
  blind_spots: >
    (1) TOUCH TARGETS AT 481-1024px. The drawer only exists <=480px, so touch tablets get the
    footer control at 28px — below this repo's locked 44px floor. Mitigations: the social links
    already ship at 28px in the same row at those widths, and 28px clears WCAG 2.2 SC 2.5.8's 24px
    AA minimum. This is a real, deliberate tradeoff and MUST go to the human checkpoint, not be
    shipped silently. (2) DISCOVERABILITY REVERSAL. Hiding the visible label is a genuine reversal
    of a documented decision; the Geist evidence falsifies its premise but the user should confirm.
    (3) CLUSTER WIDTH RATIO. The right cluster shrinks 335.06px -> ~248px, moving left/right from
    1.087x to ~1.47x — footer-desktop-imbalance worked to reach 1.09x, so I must re-measure and
    check this does not read as a new imbalance. (4) The active-state ::after underline insets
    (left/right 8px) were tuned for a 44px button and will need re-measuring on a 28px one.
  candidate_causes:
    - "code (CSS/markup): 44x44 button boxes applied unscoped to a footer context, giving the
       subordinate control a 136px footprint equal to the dominant one"
    - "code (markup): the visible 31.06px 'Tema' text run adds width and injects a TEXT kind into
       a row of two icon rows"
    - "config/design-decision: the label's documented justification ('users are not used to looking
       in the footer') is falsified by the industry convention the reporter asked us to check"
    - "environment: RULED OUT — geometry byte-identical across 5 widths and both themes"
    - "data: RULED OUT — no dynamic content participates in this layout"
  and_gate: >
    YES — fires between the two code causes. Neither alone yields subordination: removing only the
    label leaves 136px vs 136px = exactly 1.00x (peer, not subordinate); shrinking only the box
    leaves (31.06 + 8 + 88) = 127.06px vs 136px = 0.934x (still near-peer, and the text run still
    breaks the icon-row rhythm the reporter named separately). Both together give 88px vs 136px =
    0.647x, which is the first value that actually reads as subordinate. root_cause is therefore a
    SET of two contributing causes, matching the reporter's own two-part complaint.

## Symptoms

expected: >
  On desktop, the footer should read as visually balanced between social links and the theme
  control, with hierarchy reflecting relative importance: social links (community-facing, more
  important) should read as the primary element, and the theme control should be a lightweight,
  low-attention control — plausibly a simple icon-only toggle switch (light/dark) rather than a
  labeled control. Reporter also wants a check of what other/similar sites (community sections
  particularly) do for a "theme" control's visual weight relative to social links, i.e. research
  industry patterns before deciding.
actual: >
  On desktop, the footer's balance between social links and the theme color control looks wrong.
  The "Tema" (Theme) text label draws too much visual attention and appears to break the
  footer's rhythm/hierarchy — it currently reads as more prominent than it should relative to
  the social links.
errors: None — this is a visual/UX hierarchy issue, not a functional error.
reproduction: >
  Load the site in a desktop viewport and inspect the footer. Footer markup lives in
  lib/pukllay_club_web/components/layouts.ex (rendered app-wide); social links are defined in
  lib/pukllay_club_web/club_links.ex.
started: >
  Footer/theme control appears to have shipped as part of "Phase 00–01.1 (catalog, site shell,
  footer/header UI polish)" — commit 320fc4b / PR #28.

## Eliminated

- hypothesis: "Reducing the theme control's INK (colour fade / glyph size / active tint) makes it
    read as subordinate to the social links."
  evidence: >
    Already shipped and already falsified by this very re-report. Sketch 018 (winner B) +
    quick task 260824-7mt applied all three ink levers on 2026-08-24: rest colour faded to 75%,
    glyph 16px -> 14px, active state toned to a muted-primary mix. Sketch 018's README records it
    was raised by the SAME user complaint ("Social links are more relevant, aren't?") during the
    footer-desktop-imbalance session. The user is now re-reporting the same defect, which means the
    ink channel was not the binding constraint. Measurement shows why the ink fix made one number
    WORSE: shrinking the glyph inside an unchanged 44px box dropped the toggle's ink-fill from
    ~35% to 30.88% against the social row's 82.35%, so the control became sparser, not smaller.
  timestamp: 2026-08-24

- hypothesis: "Collapse the control to a simple 2-state light/dark toggle switch (the reporter's
    own suggested fix)."
  evidence: >
    Blocked by two independent sources that agree. (1) In-repo: sketch 014 tested exactly this as
    variant B and rejected it — a 2-state toggle "loses the persistent 3rd 'match system' control
    once someone has toggled manually", i.e. it silently drops live OS-following. Sketch 018
    re-confirmed: "collapsing to a 2-state toggle was already tested and rejected in sketch 014".
    (2) Industry: Vercel Geist's Theme Switcher docs say "Use Theme Switcher for the canonical
    Light / System / Dark control" and explicitly "Don't rebuild a theme picker with Switch or
    three icon buttons" — the canonical control is 3-state, not a binary Switch. The correct move
    is to make the 3-state control SMALL, not BINARY.
  timestamp: 2026-08-24

- hypothesis: "Re-introduce a container/segmented pill around the toggle (as Geist renders it) so
    it reads as one compact object."
  evidence: >
    Blocked by sketch 014 Round 2, which rejected exactly this on this user's own feedback: "A
    variants looks nice but still is overbalanced since takes too much relevancy". The finding was
    that "the card/border/background container itself is what makes the toggle read as its own
    distinct 'control' competing with the CTA, independent of how heavy that container's styling
    is." Winner D (bare icons, no card) stands. Geist's visible pill is therefore NOT the part of
    the industry pattern to copy — its SIZING is.
  timestamp: 2026-08-24

- hypothesis: "The clusters' spacing tiers regressed (a return of footer-desktop-overloaded)."
  evidence: >
    Measured intact at every width: .pk-footer-theme gap 8px (item tier), .pk-footer-right gap 24px
    (group tier), .pk-footer-social gap 8px (item tier). The 3x item/group contrast the prior
    session installed is present and correct. Spacing is not the defect this time.
  timestamp: 2026-08-24

## Evidence

- timestamp: 2026-08-24
  checked: Knowledge base + resolved sessions for this exact surface
  found: >
    Four prior sessions on this footer. footer-overflow-tablet-width (min-content floor),
    footer-desktop-overloaded (spacing tiers / proximity), footer-desktop-imbalance (baseline,
    ink mass, KIND asymmetry, band fill). Plus sketch 014 (toggle chrome), sketch 018 + quick task
    260824-7mt (toggle ink). Every one of them worked a DIFFERENT channel.
  implication: >
    The channels already addressed are chrome, proximity, KIND, ink and fill. The one channel never
    measured on this control is its BOX GEOMETRY. That is where to look first.

- timestamp: 2026-08-24
  checked: DOM structure — layouts.ex:644-650 (footer right cluster) and 860-891 (theme_toggle/1)
  found: >
    .pk-footer-right holds exactly two concerns: .pk-footer-social (4 anchors) and .pk-footer-theme
    (a span.pk-footer-toggle-tag "Tema" + .pk-theme-toggle with 3 bare buttons). Each theme button
    carries the Tailwind utilities `min-h-11 min-w-11 p-2` (the 44px touch floor locked by quick
    task 260821-dah) wrapping a `size-4` hero icon. Each social anchor is CSS-sized to 28x28 with a
    1px border and a 16x16 inline SVG.
  implication: >
    Two adjacent icon rows in ONE cluster are sized by two different systems — the social row to a
    28px visual circle, the theme row to the 44px touch floor — and the 44px system was applied to
    the subordinate concern. Candidate root cause on the code/CSS branch.

- timestamp: 2026-08-24
  checked: >
    Rendered geometry of the live app (http://localhost:4000) via CDP, 5 widths x 2 themes
    (1440/1280/1024/768/481px, light+dark)
  found: >
    Byte-identical at all 10 combinations. .pk-footer-social = 136.00px wide, 28px tall, item box
    28x28, glyph 16px, pitch 36px, ink fill 82.35%. .pk-theme-toggle = 136.00px wide, 44px tall,
    item box 44x44, glyph 14px, pitch 46px, ink fill 30.88%. .pk-footer-toggle-tag ("Tema") =
    31.06px + an 8px item gap. .pk-footer-theme total = 175.06px. Ratio themeWrapper/social =
    1.287x. Per-item area ratio (theme button / social link) = 2.469x. .pk-footer-right's own
    height is 44px — set entirely by the theme buttons, since social is 28px. Zero horizontal
    overflow at every width (prior sessions' fixes intact).
  implication: >
    Direct confirmation. The SUBORDINATE control claims EXACTLY the same 136px horizontal band as
    the entire 4-icon social row, is 1.287x wider once its label is counted, occupies 2.469x the
    area per item, and is the tallest thing in the cluster. Hierarchy is not merely absent — it is
    inverted on the footprint channel, while being correct on the ink channel. That split is
    precisely why the previous ink-only fix did not resolve the complaint.

- timestamp: 2026-08-24
  checked: >
    Industry research (explicit reporter requirement). Vercel Geist design system's Theme Switcher
    docs, fetched and parsed directly from https://vercel.com/geist/theme-switcher
  found: >
    Verbatim best-practice guidance: "Use Theme Switcher for the canonical Light / System / Dark
    control." / "Place it once per app, IN THE FOOTER or settings, not duplicated across pages." /
    "Pass `small` for DENSE CHROME (FOOTERS, dropdowns); use the default size on a settings page
    where there's room for the LABELS to breathe." / "Don't rebuild a theme picker with Switch or
    three icon buttons. Theme Switcher already handles the icons, the aria-label per option, and
    System detection."
    Shipped markup measured from the same page:
      <fieldset class="... h-8 w-fit ... data-[small]:h-6">
        <legend class="sr-only">Select a display theme:</legend>
        <input aria-label="system" type="radio" value="system">
        <label ...><span class="sr-only">system</span><span class="size-4"><svg width=16 height=16>
    i.e. default box 32px (h-8), FOOTER box 24px (h-6), glyph 16px (size-4), and the group label is
    a VISUALLY HIDDEN <legend>, never visible text.
  implication: >
    Three findings, each load-bearing. (1) The footer is the CANONICAL home for this control, which
    FALSIFIES the stated premise behind the visible "Tema" label — 01.1-08-PLAN.md:430-431 justifies
    it "so the control is discoverable in a place users are not yet used to looking for it". Users
    ARE used to looking there. (2) The industry answer to footer density is a SMALLER BOX, and the
    glyph stays at 16px — this repo did the exact inverse (kept a 44px box, shrank the glyph to
    14px). (3) The group label survives as sr-only, so the accessibility/semantics half of the
    label decision can be kept while its visual weight is dropped.

- timestamp: 2026-08-24
  checked: Provenance of the "Tema" label before proposing removal (KB lesson (v))
  found: >
    01.1-08-PLAN.md:429-433 — render the toggle "preceded by a small
    <span class='pk-footer-toggle-tag'>Tema</span> label so the control is discoverable in a place
    users are not yet used to looking for it (sketch 017 Round 2's stated reason for choosing the
    footer)". Sketch 018 README:43 and :53-55 both reaffirm it. The rationale is SOLELY
    discoverability-in-an-unfamiliar-location — there is no other stated reason.
  implication: >
    The decision is real and must not be silently reverted, but its single stated premise is
    contradicted by the Geist evidence above. The honest move is to CONVERT the label rather than
    delete it: keep the element and the string, make it sr-only, and promote it to the control's
    accessible group name — which is both what Geist ships and a net accessibility GAIN, since the
    3 buttons currently have per-button aria-labels but NO group label at all.

- timestamp: 2026-08-24
  checked: Shared-component blast radius — theme_toggle/1 call sites
  found: >
    Rendered twice: layouts.ex:503 inside .pk-drawer-utility (mobile drawer, <=480px, alongside its
    own VISIBLE span.pk-drawer-utility-label "Tema"), and layouts.ex:648 inside .pk-footer-theme.
    The footer copy is display:none below 480px; the drawer copy is display:none above it. Existing
    CSS already reaches into the shared component from outside (.pk-theme-toggle button > span sets
    the 14px glyph) — but UNSCOPED, so it currently shrinks the drawer's glyphs too.
  implication: >
    Any sizing change must be scoped to .pk-footer-theme so the drawer keeps the 44px touch floor
    intact. This maps cleanly onto Geist's own two-context guidance: footer = dense chrome = small
    + hidden label; drawer = settings-like surface with room = full size + visible label.

- timestamp: 2026-08-24
  checked: Test guards that will constrain or break under a fix
  found: >
    layouts_test.exs:352-353 asserts theme_toggle/1 renders exactly 3x `min-h-11` and 3x `min-w-11`
    (COMPONENT-level, so keeping those utilities and overriding size in footer-scoped CSS keeps it
    green). layouts_test.exs:212 asserts the footer contains "pk-footer-toggle-tag" and "Tema".
    footer_overflow_test.exs:210 asserts .pk-footer-right .pk-footer-toggle-tag count == 1.
    footer_rhythm_test.exs:164-171 asserts .pk-footer-theme is a direct child of the right cluster
    and wraps both .pk-footer-toggle-tag and .pk-theme-toggle.
  implication: >
    Keeping the span (as sr-only) and keeping min-h-11/min-w-11 on the shared component keeps all
    four guards green by construction. The fix therefore lands as a footer-scoped CSS override plus
    two markup attributes — no test churn from deletion, and the 44px floor is preserved everywhere
    the component is actually the touch surface.

## Resolution

root_cause: >
  A SET of two contributing causes (AND-gate fired), both on the FOOTPRINT channel — the one
  channel four prior sessions on this footer never measured.

  (1) OVERSIZED BOX. `theme_toggle/1`'s three buttons carry `min-h-11 min-w-11` (the 44px touch
  floor locked by quick task 260821-dah) and that value was never re-measured against the 28x28
  social links sitting beside them in the same cluster. Measured on the live app, byte-identical
  at 481/768/1024/1280/1440px in both themes: `.pk-theme-toggle` and `.pk-footer-social` were BOTH
  exactly 136.00px wide, so the subordinate control claimed precisely the same horizontal band as
  the entire four-icon social row — 2.469x the area per item, and the tallest object in the
  cluster (44px vs 28px), setting `.pk-footer-right`'s whole height on its own.

  (2) VISIBLE TEXT LABEL. The 31.06px "Tema" span plus its 8px item gap took the theme concern to
  175.06px = 1.287x the social row, and injected a TEXT kind between two icon rows.

  AND-gate: neither alone yields subordination. Label only -> 136 vs 136 = exactly 1.000x (peer).
  Box only -> 127.06 vs 136 = 0.934x (near-peer, text run still breaking the rhythm). Both ->
  88 vs 136 = 0.647x, the first value that reads as subordinate.

  Why the previous fix failed: sketch 018 / quick task 260824-7mt attacked this same complaint one
  day earlier using three INK levers (colour fade to 75%, glyph 16px -> 14px, toned active tint).
  Shrinking the glyph inside an unchanged 44px box LOWERED the toggle's ink fill to 30.88% against
  the social row's 82.35% — it made the control sparser, not smaller, which is why the user
  re-reported the identical defect the next day. Ink and box were being moved in opposite
  directions.

fix: >
  Fixes the footprint channel; changes no ink value, no state count, and no interaction contract.

  (1) BOX. New footer-scoped rule `.pk-footer-theme .pk-theme-toggle button { min-width: 28px;
  min-height: 28px; padding: 0 }`. 28px is not invented — it is `.pk-footer-social a`'s own
  declared value five rules up, so the cluster's two icon rows finally share ONE sizing system
  instead of two (consistency repair against an in-repo pattern). `padding: 0` is load-bearing:
  the component's `p-2` would otherwise win the box back to 30px. Scoping to `.pk-footer-theme`
  is what preserves the 44px floor in the mobile drawer, which renders the same shared component
  and IS the touch surface below 480px; `min-h-11`/`min-w-11` therefore stay on the markup and
  the component-level 44px test stays honest rather than worked around.

  (2) LABEL. Converted, not deleted: `sr-only` plus `role="group"` + `aria-labelledby` promoting
  the same "Tema" string to the control's accessible group name. This is a net accessibility GAIN
  — the three buttons had per-button aria-labels but the control had no group name at all. The
  drawer keeps its visible label.

  (3) UNDERLINE. The active `::after` insets became tokens (`--pk-toggle-underline-inset`,
  `--pk-toggle-underline-bottom`) declared on `.pk-theme-toggle` and retuned by the footer scope
  to 5px/1px. Necessary because the control now renders at two box sizes, and the first attempt —
  a plain `.pk-footer-theme .pk-theme-toggle button::after` override — was measured SILENTLY
  LOSING: it is specificity (0,2,2) against the active-state rules' (0,4,2). Custom properties
  resolve by inheritance, so specificity never enters into it.

  Evidence base for the design: Vercel Geist's Theme Switcher docs, which say the footer IS the
  canonical home ("Place it once per app, in the footer or settings"), prescribe a SMALL box for
  footers while keeping the glyph at 16px, and ship an sr-only `<legend>` rather than visible text.
  This repo had done the exact inverse on both levers.

verification:
  guardrail_verdict: accepted
  signal_1_original_defect_resolved: >
    PASS. CDP re-measurement of the running app at the same 5 widths x 2 themes, byte-identical at
    all 10: theme concern 175.06px -> 88.00px, ratio to social 1.287x -> 0.647x, per-item area
    ratio 2.469x -> 1.000x, button box 44px -> 28px, cluster height 44px -> 28px, ink fill 30.88%
    -> 47.73%, "Tema" label 31.06px -> 1px (sr-only, out of flow, spends no flex gap slot). Social
    row unchanged at 136.00px / 82.35%. Every predicted value hit exactly.
  signal_2_regressions: >
    PASS. `mix quality` exit 0; 390 tests, 0 failures (385 before + 5 new). Mobile re-measured at
    320/375/430/480px: drawer buttons still 44x44 x3, drawer's visible "Tema" label still static
    and rendered, footer theme/social still hidden, footer height still exactly 179px (the value
    footer-desktop-imbalance recorded), zero horizontal overflow. Zero overflow also at every
    desktop width. Verified in all three theme states (light/dark/system) — the active underline
    renders correctly on whichever button is current.
  signal_3_bug_returns_on_revert: >
    PASS. Source reverted via `git stash push` on the two source files ONLY, keeping the new tests,
    per the mechanics the footer-desktop-imbalance entry documented. 4 of the 5 new tests went red
    with their intended messages ("The footer-scoped ... rule is gone", "The footer's \"Tema\"
    label is visible again", "`--pk-toggle-underline-inset` is missing"). The 5th (the unscoped-
    shrink guard) was green pre-change and is labelled a FORWARD-LOOKING guard, not counted as
    evidence. The before/after CDP sweeps are the geometric half of the same check.
  signal_4_mutation: >
    PASS. 15/15 fix-site mutants killed. Two rounds were required and both findings are recorded
    because they were real, not cosmetic. Round 1 left 2 SURVIVORS, and both were genuine holes in
    the new guards rather than acceptable gaps: `src =~ token` was satisfied by the footer scope's
    own re-declaration after the base declaration was deleted, and `src =~ "var(token)"` was
    satisfied by `right:` after `left:` was hardcoded. Both assertions were rewritten to match
    inside the specific rule block. A third finding came from mutation analysis before running it:
    dropping `padding: 0` renders a 30px box while every min-* number still reads correct, so an
    explicit assertion was added. Mutants killed include box->44/34/30px, min-height only, rule
    deleted, padding dropped, both token declarations, the hardcoded literal, the reintroduced
    losing `button::after` override, an unscoped shrink reaching the drawer, label made visible,
    role/aria-labelledby dropped, and the 44px floor stripped from the shared component.
    HARNESS BUG FOUND AND FIXED MID-CHECK, and it is the transferable warning: the kill detector
    grepped for `[0-9]+ failures` and ExUnit prints "1 failure" SINGULAR, so 11 of 15 genuine kills
    were being reported as inconclusive. Every CSS mutation was also block-scoped by regex rather
    than string-replaced file-wide, per the prior session's finding that `min-width` / `padding: 0`
    occur many times in app.css.
  signal_5_diff_scope: >
    PASS. Three files, +344/-5. No deletion-only changes; the one removal is the two hardcoded
    underline inset literals, replaced by the tokens that supersede them. No unrelated edits.
  human_verify: >
    CONFIRMED 2026-08-24. The user reviewed all four screenshots in
    .planning/debug/assets/footer-theme-toggle-balance/ (footer-light.png, footer-dark.png,
    right-cluster-light.png, right-cluster-dark.png), answered all three flagged items, and
    accepted every recommended option. Full sign-off, no requested changes.

    (a) "Tema" LABEL — sr-only vs restoring visible text: KEEP SR-ONLY. The fix is accepted as
    implemented; the visible text label is NOT to be restored. This confirms the documented
    reversal of 01.1-08-PLAN.md:429-433's discoverability decision, made on the Geist evidence
    that the footer IS the canonical home for this control (so the decision's single stated
    premise — "a place users are not yet used to looking" — is false). The string stays in the
    DOM as the control's sr-only accessible group name, so the semantic half of the original
    decision survives.

    (b) TOUCH TARGET — 28px vs bumping to 32px: ACCEPT 28px. The size is NOT to be changed. The
    user's stated grounds match the two mitigations put to them: it matches the social icons in
    the same row, and it clears WCAG 2.2 SC 2.5.8's 24px AA minimum. Recorded plainly: this is an
    ACCEPTED DEVIATION from this repo's own locked 44px floor for the 481-1024px touch-tablet
    band, not a refutation of it. The floor stays enforced on the shared component and in the
    mobile drawer, which is the actual touch surface below 480px. The related side discovery
    stands — .pk-footer-social a has always been 28px there too, so that band now has two
    controls under the floor by deliberate choice rather than one by oversight.

    (c) CLUSTER WIDTH RATIO — 1.087x -> 1.468x: LOOKS FINE. No further layout change is needed
    for cluster balance. This closes blind spot (3), which flagged that footer-desktop-imbalance
    had worked specifically to reach 1.09x and that shrinking the right cluster moves away from
    it. The user judged the new ratio acceptable with that history stated.

    NOT claimed by this confirmation: that the three costs are zero. They are tradeoffs the
    reporter was shown and chose to absorb. Blind spot (1)'s underlying condition (28px targets
    on touch tablets) is still true; it is now an accepted decision rather than an open defect.

files_changed:
  - assets/css/app.css
  - lib/pukllay_club_web/components/layouts.ex
  - test/pukllay_club_web/footer_rhythm_test.exs

side_discoveries:
  - >
      NOT FIXED, recorded only (unevidenced-edit rule). `.pk-theme-toggle button > span { width:
      14px }` from quick task 260824-7mt is UNSCOPED, so the drawer's glyphs were shrunk to 14px
      too as a side effect of a change whose stated rationale was purely about the footer's
      relationship to its social icons. Pre-existing, invisible in this session's before/after, and
      changing it would alter the mobile drawer's appearance without a reported complaint.
  - >
      `.pk-footer-social a` is a 28x28 tappable anchor and has always been below the app's own 44px
      touch floor at every width 481px and up. This is what makes the 28px theme button defensible
      as a consistency repair, but it also means the footer has TWO controls under the floor on
      touch tablets, not one. Flagged for the checkpoint rather than silently widened.
