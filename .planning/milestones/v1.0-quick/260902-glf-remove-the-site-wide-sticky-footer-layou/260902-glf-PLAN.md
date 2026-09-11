---
phase: quick-260902-glf
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - assets/css/app.css
  - test/pukllay_club_web/components/layouts_test.exs
  - test/pukllay_club_web/live/catalog_show_test.exs
  - lib/pukllay_club_web/components/layouts/root.html.heex
autonomous: true
requirements: [SHELL-01]
tags: [shell, layout, footer, sticky-footer, css-removal, stale-comment, flexbox]

estimate:
  tokens: 30000
  raw_tokens: 30000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "`.pk-app-shell` no longer declares `min-height` at any value, and no `.pk-app-shell main` rule exists anywhere in `assets/css/app.css` — both are deleted outright, not commented out."
    - "On a page whose content is shorter than the viewport, the footer's top edge sits immediately after the last content band with no artificially inserted gap — confirmed by live CDP measurement, not by screenshot impression."
    - "On a page whose content already exceeds one viewport (a game detail page), every measured geometry number is unchanged from before this task — including `body.pk-has-cta-bar`'s reserved bottom clearance, which is confirmed live rather than trusted from the removed comment's claim."
    - "The fate of `display: flex; flex-direction: column` on `.pk-app-shell` is DECIDED BY MEASUREMENT and the decision plus its evidence is recorded in-file — not left as an unexamined leftover and not removed on the assumption that it was only ever there for the sticky footer."
    - "The superseded sticky-footer rationale is retired with a dated (2026-09-02, quick task 260902-glf) note carrying what changed, why, and the tradeoff being knowingly reintroduced — following the same in-file superseding-note precedent 260902-fdm and 260902-g21 set, not silently deleted."
    - "The dual-declaration `100vh`-then-`100dvh` viewport-unit argument survives somewhere citable, because two other places in this repo point at it by name; no cross-reference to `.pk-app-shell`'s comment is left dangling."
    - "All four named test files are checked and their state recorded — every assertion that was tied to the removed mechanism is either rewritten to the new contract or deleted, and the ones with no tie are explicitly recorded as checked-and-unchanged rather than silently skipped."
    - "`mix test` is fully green and `mix format --check-formatted` passes."
  artifacts:
    - assets/css/app.css
    - test/pukllay_club_web/components/layouts_test.exs
  key_links:
    - "`.pk-app-shell`'s removed `min-height: 100vh; min-height: 100dvh;` pair ↔ `.pk-lightbox-img`'s own dual `height` declarations (app.css ~3930-3938) and `catalog_show_test.exs:3689/3696`, both of which cite `.pk-app-shell`'s comment as THE canonical explanation of that idiom. Deleting the paragraph without repointing those citations leaves a live test's failure message pointing at prose that no longer exists."
    - "`.pk-app-shell`'s removed declarations ↔ the two containing-block audits that name them as their premise (`.pk-title-echo` ~3583-3601, `.pk-lightbox` ~3783-3795). Their CONCLUSIONS survive (removing properties cannot newly establish a containing block) but their premise text becomes factually wrong the moment the declarations go."
    - "`display: flex; flex-direction: column` on `<body>` ↔ `.pk-footer`'s `margin-top: var(--pk-footer-offset)` (3rem, retuned by 260901-ty6). A flex container suppresses margin collapsing between its items; block flow does not. This is the one measurable thing the flex column could still be buying, and it is the specific number Task 3's A/B measurement must settle."
    - "`display: flex; flex-direction: column` ↔ `root.html.heex`'s `<body class=\"pk-app-shell\">` and the three `carries pk-app-shell` tests in `layouts_test.exs`. If the flex column also goes, `.pk-app-shell` has no rules left at all and those three tests would keep dead markup alive for the wrong reason — the branch must be resolved consistently, not half-applied."
    - "Any negative CSS assertion in `layouts_test.exs` ↔ the new superseding comment, which WILL contain the very selector and property names those assertions look for. The assertions must match against comment-stripped source or they fail against the very note this task is required to write."
---

<objective>
Delete the site-wide sticky-footer layout mechanism from `assets/css/app.css` — the `min-height`
pair on `.pk-app-shell` and the `flex-grow` on `.pk-app-shell main` — so the footer follows content
naturally instead of being pushed to the bottom of the viewport on pages shorter than one screen.

Purpose: a real mobile screenshot from the developer showed a large, empty, unstyled band between
the catalog page's last content row and the footer. The cause is this mechanism, added deliberately
in Phase 01.2 gap-closure round 4 (G-01.2-14 / G-01.2-24 task 3) to stop the footer floating
mid-page with plain background below it. On a page whose real content can legitimately fall short of
a tall viewport, it produces the opposite-but-equally-bad defect: a gap ABOVE the footer instead of
below it. The developer was offered "revert the mechanism" vs. "investigate a possible
missing-content bug first" and explicitly chose to revert — this is a confirmed decision to accept
the original tradeoff back, not an open question this plan should relitigate.

Output: the two declarations gone from `app.css`, a dated superseding note in their place, the three
in-file cross-references that name them corrected, `layouts_test.exs`'s CSS-facts contract inverted
into a regression guard, the other three named test files audited, and a live CDP measurement record
covering a short page, a long page, and the `.pk-has-cta-bar` interaction.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

Project skills to load before touching CSS or markup (both live under `.claude/skills/`):
- `ux-responsive` — this repo's real breakpoint values and viewport idioms; confirms which widths
  the live measurement should use and what `dvh` is doing in this codebase.
- `ui-design-system` — banned styling patterns; confirms a pure-deletion change introduces no new
  token or literal.

Source files — read exactly the named ranges once each, extract everything needed in that pass, and
do not re-read a range already in context.

- `assets/css/app.css`
  - lines 372-458 — the whole unit this task acts on: the long sticky-footer doc comment (372-442),
    the `.pk-app-shell` rule (443-448: `display: flex; flex-direction: column; min-height: 100vh;
    min-height: 100dvh;`), the descendant-selector comment (450-455), and the `.pk-app-shell main`
    rule (456-458: `flex-grow: 1;`).
  - lines 1896-1910 — `.pk-footer`'s `--pk-footer-offset: 3rem` and its `margin-top` read of that
    token (retuned by quick task 260901-ty6). This is the margin that could newly collapse if the
    body's flex column is dropped; Task 3's A/B measurement is about this number.
  - lines 3583-3601 — `.pk-title-echo`'s containing-block audit, whose RE-CHECKED paragraph names
    `<body>`'s flex column and `min-height` as its premise.
  - lines 3783-3795 — `.pk-lightbox`'s containing-block audit, same premise.
  - lines 3928-3940 — `.pk-lightbox-img`'s "declared TWICE for the same reason `.pk-app-shell`
    declares `min-height` twice (see that rule's own comment)" citation.
  - line 3532 (`body.pk-has-cta-bar`, reserved bottom padding) and line 4255 (its `≤480px`
    override) — requirement 4's subject.
- `lib/pukllay_club_web/components/layouts/root.html.heex`, line 14 — `<body class="pk-app-shell">`.
  This is the class's ONLY markup consumer; there is no JS that queries it.
- `lib/pukllay_club_web/components/layouts.ex`, lines 626-635 — `<main>` carries `pb-20 pt-8
  sm:pt-20` (padding, no margin) and is immediately followed by `<.footer />`. Relevant because it
  means `<main>` contributes no bottom margin for `.pk-footer`'s 3rem top margin to collapse with.
- `test/pukllay_club_web/components/layouts_test.exs`
  - lines 539-572 — the `root layout sticky-footer app shell` describe: three tests asserting
    `<body>` carries the class on catalog / detail / about.
  - lines 574-626 — the `pk-app-shell CSS facts` describe: `@css_path`, `shell_css_source/0`,
    `pk_app_shell_block/0`, and the two tests that assert the removed declarations. NOTE:
    `shell_css_source/0` reads the file raw — it does NOT strip comments, and the existing
    `refute ... > main` assertion at 622 already carries that latent flaw.
- `test/pukllay_club_web/live/catalog_show_test.exs`, lines 3685-3700 — `.pk-lightbox-img`'s dual
  `height` assertion. Its own contract is NOT affected by this task; only its in-comment and
  in-failure-message pointers at `.pk-app-shell`'s comment are.

Already-completed grep audit (do not redo the discovery, but DO confirm it as instructed in Task 3):
`pk-app-shell` appears in exactly these places repo-wide — `app.css` (2 rules + 3 comment
cross-references), `root.html.heex:14`, `layouts_test.exs` (2 describes), and
`catalog_show_test.exs:3689` (a comment pointer only). `header_chip_band_separation_test.exs` and
`footer_rhythm_test.exs` contain NO reference to it; their `min-height` hits are `.pk-chip`'s 44px
touch target (line 243) and the footer theme button's box (line 931) respectively, and their
"sticky" hits are the sticky HEADER, a different mechanism entirely.

Live-measurement precedent to follow: headless Chrome driven over CDP from a throwaway scratchpad
script (never committed), reading `getBoundingClientRect()` directly rather than inferring geometry
from a screenshot, with numbers recorded in the SUMMARY. Set by 260901-ty6, 260902-fdm and
260902-g21 on this exact surface. 260902-g21 also recorded that `window.scrollTo` can clamp short of
the true document bottom on some pages, and that `Page.captureScreenshot` with
`captureBeyondViewport: true` plus a computed `clip` sidesteps that — reuse that workaround rather
than rediscovering it.
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Invert the layouts_test.exs CSS-facts contract into a regression guard (RED)</name>
  <files>test/pukllay_club_web/components/layouts_test.exs</files>
  <read_first>
    Read `test/pukllay_club_web/components/layouts_test.exs` lines 539-626 in one pass. The two
    tests inside the `pk-app-shell CSS facts` describe are what this task rewrites; the three tests
    in the describe above it are NOT touched in this task (their fate is Task 3's branch decision).
  </read_first>
  <behavior>
    Rewrite the `pk-app-shell CSS facts` describe so it asserts the POST-removal contract. Four
    assertions, each with a multi-line failure message explaining the mechanism in this file's
    established style:

    - The `.pk-app-shell` declaration body contains no minimum-height declaration at any value or
      unit. Match against the body captured by the existing `pk_app_shell_block/0` regex, so the
      assertion sees declarations only and cannot be satisfied or defeated by surrounding prose.
      Failure message must say WHY: a viewport-height floor on the shell is what pushed the footer
      down on short pages, which is the defect this task removed.
    - No rule pairing the shell class with a `main` descendant exists anywhere in the stylesheet.
      This one MUST match against comment-stripped source — the superseding note Task 2 writes
      names that selector in prose, and a raw-source match would be defeated by the very comment
      this plan requires. Add a `strip_comments/1` helper to this file (or reuse the shape
      `footer_rhythm_test.exs` and `catalog_show_test.exs` already use — read one of them and copy
      the idiom rather than inventing a third variant) and route this assertion through it.
    - The stylesheet declares no growth factor on any `main` element under the shell class. Same
      comment-stripped source. This is the second half of the same regression guard: the height
      floor and the growth factor are independent halves and restoring either one alone would
      re-open half the defect.
    - The existing `refute` guarding against a direct-child combinator between the shell class and
      `main` is DELETED, not kept — with the descendant rule gone there is no longer a correct
      selector for it to be the wrong variant of, so keeping it would be a test passing for a
      reason that no longer exists. Note that removal in the describe's own comment.

    Rewrite the describe's name and its preamble comment: it currently declares itself the guard on
    "the three declarations that together push the footer down", which is the exact claim this task
    reverses. The new prose must state that this describe now guards the ABSENCE of that mechanism
    and name the task and date (2026-09-02, quick task 260902-glf) that inverted it.

    Deliberately NOT decided in this task: whether the shell class still declares a flex formatting
    context. Leave the existing `display: flex` and `flex-direction: column` assertions exactly as
    they are — they are true today and stay true unless Task 3's measurement says otherwise. Record
    in the describe's comment that those two assertions are pending Task 3's determination so a
    reader does not mistake them for a settled contract.

    RED proof: run this file BEFORE touching `app.css`. The three new assertions must be observed
    failing against the current stylesheet, and the failure must be the assertion text, not a
    compile error or a regex that silently matched nothing.
  </behavior>
  <action>
    Edit only `test/pukllay_club_web/components/layouts_test.exs`. Do not touch `app.css` in this
    task — observing the new guard fail against the unmodified stylesheet is the whole point of
    running it here.

    Reuse the file's existing `@css_path` / `shell_css_source/0` / `pk_app_shell_block/0` helpers
    rather than adding parallel ones; the only new helper is the comment stripper.

    Record which assertions were RED and their exact failure text for the SUMMARY.
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/components/layouts_test.exs</automated>
  </verify>
  <done>
    `mix test test/pukllay_club_web/components/layouts_test.exs` fails, and the failures are exactly
    the three new absence assertions. The three `carries pk-app-shell` tests above still pass. No
    file other than the test file is modified.
  </done>
</task>

<task type="auto">
  <name>Task 2: Delete the mechanism, write the superseding note, correct the three cross-references (GREEN)</name>
  <files>assets/css/app.css</files>
  <read_first>
    Already listed in `<context>`: `app.css` lines 372-458, 3583-3601, 3783-3795, 3928-3940. Read
    each range once. The superseding-note SHAPE to copy is the pair of dated withdrawal notes quick
    task 260902-fdm left in the `@media (max-width: 480px)` block, which 260902-g21 then followed —
    read one of them for the format before writing.
  </read_first>
  <action>
    Delete, outright and not by commenting out:

    1. Both minimum-height declarations from the shell rule (lines 446-447).
    2. The entire growth-factor rule targeting the shell's `main` descendant (lines 456-458),
       together with the explanatory comment that sits directly above it (lines 450-455) — that
       comment exists solely to justify a selector that no longer exists, so it goes with its rule
       rather than being orphaned.

    Leave `display: flex; flex-direction: column` in place for now. Task 3 decides its fate on
    evidence; changing it here on a hunch is exactly what requirement 1 forbids.

    Then replace the long doc comment above the rule. Do NOT silently delete it — follow this
    codebase's dated-superseding-note precedent. The replacement must carry, in this order:

    - A dated superseding note (2026-09-02, quick task 260902-glf) opening with WHAT changed: the
      height floor and the growth factor are withdrawn.
    - WHY, stated concretely: a real mobile screenshot from the developer showed a large empty
      unstyled band between the catalog page's last content row and the footer. The mechanism was
      added to prevent the footer floating mid-page with plain background below it; on a page whose
      genuine content can fall short of a tall viewport it instead inserts that band ABOVE the
      footer, which the developer judged the worse of the two defects.
    - The TRADEOFF being knowingly reintroduced: on a page shorter than the viewport the footer now
      sits immediately after its content, with plain page background below it down to the true
      viewport bottom. State explicitly that this was offered to the developer as a choice against
      "investigate a possible missing-content bug first" and was chosen deliberately — so a future
      reader does not read it as an oversight and restore the mechanism.
    - The two threat-register findings the original comment recorded, preserved in condensed form
      with their outcome noted: the containing-block safety finding (T-01.2-24-01) and the reserved
      bottom-clearance finding (T-01.2-24-02). Both were mitigations for hazards the REMOVED
      declarations introduced; removing the declarations retires the hazards rather than reopening
      them. Say that, so the register's history stays legible instead of vanishing with the rule.
    - The dual-declaration viewport-unit argument — the older static unit first as a fallback, the
      dynamic-viewport unit second — KEPT as a live, citable explanation rather than dropped with
      the declarations that motivated it. This is load-bearing and not optional: `.pk-lightbox-img`
      (app.css ~3928-3940) and a failure message in `catalog_show_test.exs` (~3689-3697) both name
      this comment as THE canonical explanation of that idiom, and both must still resolve to real
      prose after this edit. Frame it as "this file's idiom for a viewport-height envelope,
      documented here because two other places cite this spot", not as a description of a rule that
      no longer exists.

    Finally, correct the three in-file cross-references that name the removed declarations as their
    premise. Their CONCLUSIONS all survive — deleting properties cannot newly establish a containing
    block for a fixed-position descendant, so both audits get strictly safer, not riskier. Only
    their premise text is now false:

    - `.pk-title-echo`'s RE-CHECKED paragraph (~3583-3601) — it asserts `<body>` now carries a flex
      column plus a height floor. Update it to describe the shell's actual current state and note
      that the audit's conclusion is unaffected and why.
    - `.pk-lightbox`'s audit (~3783-3795) — same correction, same reasoning.
    - `.pk-lightbox-img`'s citation (~3928-3940) — it justifies its own duplicated property by
      pointing at the shell rule's duplicated one. Repoint it at the idiom paragraph in the new
      superseding note. Its own two declarations and `catalog_show_test.exs`'s assertion on them
      are untouched and must stay green.

    Do not edit any other rule. Do not touch `root.html.heex` or any `.ex` file in this task.
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/components/layouts_test.exs test/pukllay_club_web/stylesheet_integrity_test.exs</automated>
    <automated>mix test</automated>
    <automated>mix format --check-formatted</automated>
  </verify>
  <done>
    Task 1's three absence assertions are now green, `mix test` is fully green, and
    `mix format --check-formatted` passes — which is exactly the proof that the shell rule's
    declaration body carries no height floor and that comment-stripped source contains no
    shell-plus-`main` growth rule, since those are the assertions Task 1 wrote. The superseding note
    carries the dated header, the screenshot-driven why, the explicitly-accepted tradeoff, both
    retired threat findings, and a still-citable dual-declaration idiom paragraph. All three
    cross-reference sites describe the shell's real current state.
  </done>
</task>

<task type="auto">
  <name>Task 3: Decide the flex column by measurement, live-verify short/long/CTA-bar, close the test audit</name>
  <files>assets/css/app.css, test/pukllay_club_web/components/layouts_test.exs, test/pukllay_club_web/live/catalog_show_test.exs, lib/pukllay_club_web/components/layouts/root.html.heex</files>
  <read_first>
    Everything needed was read in Tasks 1-2 plus `<context>`. Do not re-read those ranges. The only
    range not yet read at this point is `catalog_show_test.exs` 3685-3700 — read it once, here.
  </read_first>
  <action>
    Three concerns, in this order. All three are settled by live measurement against the running dev
    server, never by argument from the prose this task is retiring.

    (A) LIVE VERIFICATION — requirements 4 and 5. Drive headless Chrome over CDP from a throwaway
    scratchpad script (not committed), following the precedent named in `<context>`. Read
    `getBoundingClientRect()` directly; a screenshot is confirmation, never the measurement.

    Capture, at minimum:
    - SHORT PAGE: a catalog page state whose real content falls well short of the viewport, at a
      deliberately tall viewport so the shortfall is unambiguous. A no-results catalog state (a
      search query that matches nothing, driving the empty state) is the most deterministic fixture
      available and is preferred over trying to scroll a full catalog to a short position; if a
      different fixture is used instead, say which and why in the SUMMARY. Measure the vertical
      distance between the last content element's bottom edge and the footer's top edge, and the
      distance from the footer's bottom edge to the document's end. The success condition is that
      the footer now begins immediately after content, with any remaining space falling BELOW the
      footer — the accepted tradeoff — rather than above it.
    - LONG PAGE: a game detail page at 390px. Every number must be unchanged from before this task.
      Capture `document.documentElement.scrollHeight`, the footer's top and bottom edges, and the
      gap from the footer's bottom edge to the document's end.
    - CTA-BAR INTERACTION (requirement 4): on that same detail page, with the reserved-clearance
      body class actually applied, confirm the reserved bottom clearance still measures what it did
      before. The removed comment CLAIMED this was already a no-op because detail content exceeds
      one viewport by a wide margin. Do not trust that claim — confirm it live and record the
      measured number. If it is NOT a no-op, that is a real finding: report it, do not paper over
      it, and adjust only the minimum needed with the measurement documented as the justification.

    (B) THE FLEX-COLUMN DETERMINATION — requirement 1. The shell class has exactly one markup
    consumer (`root.html.heex`'s body class) and no JS consumer, so the question reduces to a single
    measurable one: with the height floor and growth factor gone, does a flex column on `<body>`
    render any differently from ordinary block flow?

    There is exactly one candidate mechanism, and it is a real one — a flex container suppresses
    margin collapsing between its items, block flow does not. The margin at stake is `.pk-footer`'s
    top offset (3rem, a value quick task 260901-ty6 deliberately tuned). The offsetting fact is that
    `<main>` carries only padding, no bottom margin, so there may be nothing for it to collapse
    against. Which of those wins is a measurement, not a deduction.

    Run the A/B: take the short-page and long-page measurement sets from (A) once with the flex
    declarations present and once with them removed (toggle live via CDP or a temporary edit picked
    up by live reload — either is fine, the artifact is the numbers).

    - If EVERY number is identical: the flex column is vestigial. Remove it, and complete the
      removal consistently rather than half-applying it — with no declarations left, the class is
      dead markup, so also drop it from `root.html.heex` and delete the three `carries
      pk-app-shell` tests plus the now-empty CSS-facts describe from `layouts_test.exs`. Leave
      behind a dated note at the deletion site in `app.css` recording that the shell rule existed,
      what it did, and the measurement that retired it.
    - If ANY number differs: keep `display: flex; flex-direction: column`, keep the body class and
      its three tests, and record the measured delta and its cause in the superseding note as the
      positive reason the flex column survives — replacing "it was part of the sticky footer" with
      what it actually still does.

    Either way, remove the two pending-determination assertions Task 1 left in place and replace
    them with whichever contract the measurement settled, and delete the "pending Task 3" note from
    the describe's comment. Do not leave the plan's own scaffolding in the committed test.

    (C) CLOSE THE FOUR-FILE TEST AUDIT — requirement 3. Confirm, do not assume, the audit recorded
    in `<context>`: search all four named test files for the shell class name, height-floor and
    growth-factor properties, and "sticky". For each file, record in the SUMMARY either what was
    changed or an explicit checked-and-nothing-to-change with the reason. Expected outcomes, to be
    confirmed rather than trusted:
    - `layouts_test.exs` — rewritten by Tasks 1 and 3(B).
    - `catalog_show_test.exs` — its own assertion is unaffected; only its comment and failure-message
      pointers at the retired prose need to resolve to the note Task 2 wrote. Update the pointer
      text if Task 2's rewording moved what it names.
    - `header_chip_band_separation_test.exs` — no tie; its matches are the sticky header and a chip
      touch target.
    - `footer_rhythm_test.exs` — no tie; its match is the footer theme button's box.
  </action>
  <verify>
    <automated>mix test</automated>
    <automated>mix format --check-formatted</automated>
    <automated>mix compile --warnings-as-errors</automated>
    <human-check>
      Eyeball the real render at the measured viewports: on the short page the footer reads as
      following its content rather than floating, and any leftover space sits below the footer as
      plain page background — the knowingly accepted tradeoff, not a new defect. On the detail page
      nothing has visibly moved. Record the confirming clipped screenshots and every measured number
      (short page, long page, CTA-bar clearance, and both sides of the flex-column A/B) in the
      SUMMARY, following the measurement-recording discipline 260901-ty6 / 260902-fdm / 260902-g21
      each established for this surface.
    </human-check>
  </verify>
  <done>
    `mix test` fully green, `mix format --check-formatted` and `mix compile --warnings-as-errors`
    pass. The flex-column question is answered with A/B numbers in the SUMMARY and the chosen branch
    is applied consistently across `app.css`, `root.html.heex` and `layouts_test.exs` — no branch is
    half-applied. The short page shows no gap above the footer and the long page's numbers match
    their pre-change values, including the reserved CTA-bar clearance. All four test files have a
    recorded audit outcome. No plan scaffolding ("pending Task 3") remains in committed code.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| *(none crossed)* | A stylesheet deletion, comment rewrite and test update. No input is parsed, no data crosses a trust boundary, no dependency is added, no package-manager install occurs. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-glf-01 | Repudiation | `assets/css/app.css` sticky-footer doc comment | medium | mitigate | This comment carries the only in-repo record of two threat findings (T-01.2-24-01 containing-block safety, T-01.2-24-02 reserved bottom clearance) and of a live browser verification. Deleting it wholesale would erase security-register history. Task 2's action requires both findings preserved in condensed form with their retirement noted, under a dated superseding note — the same pattern 260902-fdm and 260902-g21 used. |
| T-glf-02 | Tampering | `.pk-title-echo` / `.pk-lightbox` containing-block audits | low | mitigate | Both audits' premises name the declarations this task removes. Removing properties cannot newly establish a containing block for a fixed-position descendant, so both conclusions get strictly safer — but leaving the premise text wrong would let a future audit be re-derived from a false statement. Task 2 corrects both sites; Task 3(A)'s live detail-page measurement re-confirms the fixed-position chrome still anchors to the true viewport. |
| T-glf-03 | Tampering | `layouts_test.exs` absence assertions | medium | mitigate | A negative CSS assertion matched against raw source is self-invalidating here, because Task 2's required comment names the very selector and properties being negated — the guard would pass or fail on prose rather than on the cascade. Task 1's behavior block mandates comment-stripped source for both absence assertions and requires reusing an existing stripper idiom rather than inventing a third. |
| T-glf-SC | Tampering | npm/pip/cargo installs | n/a | accept | No package-manager install task exists in this plan; no `mix.exs` / `mix.lock` change. The package-legitimacy gate is not applicable. |
</threat_model>

<verification>
1. `mix test` is green after Task 3 (767+ tests; the repo's configured test command).
2. `mix format --check-formatted` passes — `.formatter.exs` runs Styler and the LiveView HTML
   formatter as plugins, so this is also the Styler gate.
3. `mix compile --warnings-as-errors` passes (the repo's configured build command).
4. `stylesheet_integrity_test.exs` is green — this task rewrites a very large CSS comment, exactly
   the change class that file exists to catch (a comment that closes early swallows the next rule
   silently).
5. `git diff assets/css/app.css` shows the two declarations and the `.pk-app-shell main` rule
   removed as deletions, not as commented-out lines, and shows hunks at exactly the four expected
   regions (the shell rule + its comment, and the three cross-reference sites).
6. Searching comment-stripped `app.css` for a shell-class-plus-`main` rule returns nothing, and the
   shell rule's declaration body contains no minimum-height declaration.
7. The SUMMARY records: short-page gap before/after, long-page geometry before/after, the CTA-bar
   reserved-clearance number, both sides of the flex-column A/B, and a per-file audit outcome for
   all four named test files.
</verification>

<success_criteria>
- A page shorter than the viewport shows the footer immediately after its content, with no
  artificial gap above it — proven by measurement, not impression.
- A page longer than the viewport is byte-for-byte unaffected in measured geometry, including the
  reserved CTA-bar bottom clearance, which is confirmed live rather than trusted from the retired
  comment's claim.
- The flex column's fate is settled by an A/B measurement and applied consistently — including the
  body class and its three tests if it is dropped.
- The superseded rationale is retired with a dated 2026-09-02 / 260902-glf note carrying what
  changed, why, the deliberately accepted tradeoff, and the two retired threat findings — never
  silently deleted.
- No cross-reference anywhere in the repo points at prose that no longer exists; the
  dual-declaration viewport-unit idiom remains citable.
- No test is left passing for the wrong reason: every absence assertion matches comment-stripped
  source, and every one of the four named test files has an explicit recorded audit outcome.
- `mix test`, `mix format --check-formatted` and `mix compile --warnings-as-errors` all pass.
</success_criteria>

<output>
Create `.planning/quick/260902-glf-remove-the-site-wide-sticky-footer-layou/260902-glf-SUMMARY.md` when done.
</output>
