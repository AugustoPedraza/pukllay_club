---
phase: quick-260902-fdm
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - assets/css/app.css
  - lib/pukllay_club_web/components/layouts.ex
  - test/pukllay_club_web/footer_rhythm_test.exs
  - .claude/skills/ui-design-system/SKILL.md
autonomous: true
requirements: [SHELL-01]
tags: [footer, mobile, css-custom-properties, breakpoint-scoped, compliance-attribution]

estimate:
  tokens: 35000
  raw_tokens: 35000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "At ≤480px the footer shows exactly one line: the BGG attribution (logo + \"Powered by BGG\"), linking to boardgamegeek.com."
    - "At ≤480px the brand name/tagline lockup, the FAQ/Contacto/Juntadas links, and the © copyright line are all absent from the rendered footer."
    - "At >480px the footer renders byte-identically to before this change — same two clusters, same legal band, same spacing, same type sizes."
    - "At ≤480px the footer's vertical chrome (own top margin + row padding top/bottom) is strictly tighter than the 56px quick task 260901-ty6 shipped."
    - "The catalog page and the detail page (main.pk-boundary-collapse) still open the same vertical gap above the footer at ≤480px."
    - "No stylesheet rule or documentation claims a ≤480px footer wordmark size or footer link size that no longer renders."
  artifacts:
    - assets/css/app.css
    - lib/pukllay_club_web/components/layouts.ex
    - test/pukllay_club_web/footer_rhythm_test.exs
    - .claude/skills/ui-design-system/SKILL.md
  key_links:
    - "`.pk-footer-copyright` class in layouts.ex ↔ the ≤480px `display: none` rule in app.css — the class is the only hook; if it is renamed on one side the copyright silently returns."
    - "≤480px `--pk-footer-offset` ↔ the ≤480px `main.pk-boundary-collapse + .pk-footer` margin-top literal — two independent declarations that must carry the same number by intent (the 260901-ty6 decoupling contract)."
    - "`narrow_footer_block/1` in footer_rhythm_test.exs ↔ the new `main.pk-boundary-collapse + .pk-footer` rule inside the ≤480px block — the helper's unanchored regex would match the wrong rule body and silently mis-read every chrome token."
    - "app.css ≤480px type rules ↔ ui-design-system/SKILL.md type-inventory table — the table asserts what actually renders at ≤480px; hidden elements must leave it."
---

<objective>
On `≤480px` only, reduce the site footer to the BGG compliance attribution line and nothing else,
and tighten the footer's remaining vertical chrome to what a single line needs.

Purpose: sketch 044 (winner H, `.planning/sketches/044-mobile-footer-balance/`) closed a two-round
stalemate with the developer's own framing — *"the only thing I need there is the BGG compliance."*
Quick task 260901-ty6 already shrank this footer once (96px → 56px chrome, smaller wordmark,
smaller links) and real-device feedback still read it as too heavy. This is the content-reduction
answer that alignment tuning could not reach, already synthesized into the project skill at
`.claude/skills/sketch-findings-pukllay_club/references/page-shell.md` ("Mobile Footer: Reduced to
BGG Compliance Only").

Output: a breakpoint-scoped CSS change (plus one additive class hook) that hides the left cluster
and the copyright span at `≤480px`, retunes `--pk-footer-offset`/`--pk-footer-pad-block` downward,
retires the now-dead `≤480px` type rules 260901-ty6 introduced, and reconciles every document that
described them.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md

Design authority for this change (read both — the second is the synthesized version the skill serves):
@.planning/sketches/044-mobile-footer-balance/README.md
@.claude/skills/sketch-findings-pukllay_club/references/page-shell.md

Project skills that constrain the implementation:
- `Skill("ui-design-system")` — type inventory + the "re-measure before adding/removing a type combo
  on this screen" rule this plan's Task 3 obeys.
- `Skill("ux-responsive")` — the repo's real breakpoint values and the 44px touch floor.

Immediately-preceding work this builds on (read the "Measured Before/After" and "Decisions Made"
sections — they carry the numbers Task 1 must beat and the decoupling contract Task 1 must honour):
@.planning/quick/260901-ty6-reduce-the-mobile-480px-footer-s-visual-/260901-ty6-SUMMARY.md

Source files:
@assets/css/app.css
@lib/pukllay_club_web/components/layouts.ex
@test/pukllay_club_web/footer_rhythm_test.exs
@.claude/skills/ui-design-system/SKILL.md
</context>

<interface_context>
Concrete anchors the executor needs, so no exploratory reading is required:

**app.css — base declarations (do NOT change these; they are the desktop cascade):**
- `.pk-footer` base rule (~line 1859-1901) declares the four gap tiers plus
  `--pk-footer-offset: 3rem` and `--pk-footer-pad-block: 1.5rem`, and sets
  `margin-top: var(--pk-footer-offset)`.
- `.pk-footer-row` (~line 1903) reads `padding-top`/`padding-bottom` from `var(--pk-footer-pad-block)`.
- `.pk-brand-quiet .pk-brand-name` (~line 1230) — the D-B "demotion is by colour, not size" rule.
  Its comment stays; only the ≤480px SIZE exception layered on top of it is withdrawn.
- `main.pk-boundary-collapse + .pk-footer` (~line 4312-4321) — a deliberate `margin-top: 1.5rem`
  LITERAL, not the token. Its comment explains why: sketch 035's closed equal-24px-boundary
  decision must not be moved by a mobile retune of the token.

**app.css — the single `@media (max-width: 480px)` block (opens ~line 4583, closes ~line 4907).
Everything this plan adds or removes lives inside it:**
- `.pk-footer-row, .pk-footer-left, .pk-footer-right { flex-direction: column }` (~4724) — leave as is.
- `.pk-footer { --pk-footer-gap-group: 1rem; --pk-footer-gap-cluster: 1.5rem;
  --pk-footer-offset: 1.5rem; --pk-footer-pad-block: 1rem; --pk-footer-gap-list: 0.75rem }` (~4756) —
  the two chrome tokens are what Task 1 retunes.
- `.pk-brand-quiet .pk-brand-name { font-size: 1.25rem }` (~4800) — becomes unreachable; Task 2 removes it.
- `.pk-footer-links { font-size: 0.875rem }` (~4818) — becomes unreachable; Task 2 removes it.
- `.pk-footer-right { display: none }` (~4843) — the existing hide, and the pattern Task 1 mirrors.
  Its comment carries the load-bearing rule: hide the PARENT, because a `display: none` child is
  skipped by flex `gap` but an empty flex parent still consumes a slot in the column.
- `.pk-footer-legal { width: auto }` (~4862) — stays; it is what centres the surviving line.

**layouts.ex:**
- `footer/1` at line 971; its documentation block runs lines 870-970.
- Footer markup lines 975-997. The copyright span is line 993:
  `<span class="pk-footer-meta">© {@copyright_year} Pukllay Club</span>`
- `bgg_attribution/1` at line 1125, doc block lines 1097-1124. Renders
  `<a href="https://boardgamegeek.com/" ... class="pk-bgg-note"><img .../><span>Powered by BGG</span></a>`
  as a PLAIN inline anchor. Nothing in this plan touches it.
- `brand_logo/1` @doc lines 37-43 and the `mark` attr doc lines 51-52 both currently cite the
  ≤480px size exception Task 2 withdraws.

**footer_rhythm_test.exs helpers (Task 1 hardens one of them):**
- `strip_comments/1`, `base_footer_block/1` (anchored `(?m)^\.pk-footer\s*\{`),
  `narrow_viewport_tail/1`, `narrow_footer_block/1` (**unanchored** `~r/\.pk-footer\s*\{([^}]*)\}/`),
  `footer_token!/2`, `rem_token!/2`, `mobile_effective_gap!/1`.
</interface_context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Reduce the ≤480px footer to the BGG line and tighten its chrome</name>
  <files>test/pukllay_club_web/footer_rhythm_test.exs, assets/css/app.css, lib/pukllay_club_web/components/layouts.ex</files>

  <behavior>
Write these assertions FIRST and confirm each one fails against the current stylesheet/markup before
touching app.css or layouts.ex. Record the observed RED failure for each in the SUMMARY — this test
file's own convention is that every assertion is verified red, not merely green afterwards.

New helper hardening (do this before the new tests, it is a prerequisite for them being trustworthy):
- `narrow_footer_block/1` currently matches `~r/\.pk-footer\s*\{([^}]*)\}/` on the narrow tail.
  That pattern also matches the `.pk-footer {` tail of `main.pk-boundary-collapse + .pk-footer {`,
  which this task is about to add to the same media block. Whichever appears first in source order
  wins, so the helper would silently return a body with no tokens in it and every chrome-token test
  would flunk for the wrong reason. Re-anchor it to `~r/(?m)^[ \t]*\.pk-footer\s*\{([^}]*)\}/` —
  leading horizontal whitespace only, so it still matches the indented rule inside the media block
  but cannot match a rule whose selector has a combinator in front of it. Leave a comment saying
  exactly that, naming the rule that made it necessary.

New describe block: "the ≤480px footer is the BGG compliance line and nothing else"
- Test: the ≤480px block hides `.pk-footer-left` itself, not its children — assert the narrow tail
  matches a `.pk-footer-left` rule declaring `display: none`. Failure message must state the reason
  the sibling `.pk-footer-right` comment already gives: a hidden child is skipped by flex `gap`, an
  empty visible parent still takes a slot in the column, so hiding `.brand_logo` and the link list
  individually would leave a zero-height box spending a cluster gap.
- Test: the ≤480px block hides the copyright through its own named hook — assert the narrow tail
  matches a `.pk-footer-copyright` rule declaring `display: none`, and assert the rendered footer
  puts that class on exactly one `.pk-footer-legal > .pk-footer-meta` whose text contains
  "Pukllay Club". Failure message must state why a positional `:first-child` selector was rejected:
  the two `.pk-footer-meta` spans are documented as load-bearing and independently ordered, so a
  positional hook silently hides the wrong one if they are ever swapped.
- Test (the compliance guard — this is the most important assertion in the file): the surviving
  piece is the attribution. Assert the rendered footer still contains exactly one `.pk-bgg-note`
  anchor whose `href` is `https://boardgamegeek.com/`, that it carries an `img` and a `span`, and
  that NO rule anywhere in the narrow tail declares `display: none` on `.pk-footer-legal`,
  on an unscoped `.pk-footer-meta`, or on `.pk-bgg-note`. Failure message: D-04 makes this
  attribution a compliance requirement at every viewport width; a footer-reduction change is
  precisely where it could be swept away by a container hide.
- Test: the chrome tightened FURTHER than 260901-ty6 shipped, expressed as ratios against the base
  values rather than hardcoded rem numbers (the idiom this file already uses, so a future retune
  that keeps the direction stays green). Assert
  `mobile_offset / base_offset <= 0.4` (today 1.5/3.0 = 0.5, so this is RED now) and
  `mobile_pad / base_pad <= 0.55` (today 1.0/1.5 = 0.667, RED now). Keep the existing
  "strictly downward, with a non-zero offset" test untouched — it still applies and must stay green.
- Test: the detail page and the catalog page open the same gap above the footer at ≤480px. Read the
  `margin-top` rem value out of the ≤480px `main.pk-boundary-collapse + .pk-footer` rule and assert
  it EQUALS the ≤480px `--pk-footer-offset` value. Assert equality of the two extracted numbers, not
  a literal, so the invariant survives any future retune. Failure message must name the contract:
  260901-ty6 deliberately kept these as two independent declarations that "coincide by intent, not
  by a shared declaration"; retuning only the token would silently leave the detail page 8px looser
  than the catalog page on the project's primary surface.
  </behavior>

  <action>
Implement only after the assertions above are red.

**layouts.ex — one additive class, no restructuring.** On the copyright span at line 993, change
`class="pk-footer-meta"` to `class="pk-footer-meta pk-footer-copyright"`. Nothing else in `footer/1`
markup changes: both spans stay, the legal band stays, `bgg_attribution/1` is not touched. This is a
labelling change, not the markup rewrite requirement 2 warns against — the desktop cascade has no
rule for the new class, so `>480px` is provably unaffected.

**app.css — all edits inside the existing `@media (max-width: 480px)` block.**

1. Retune the two chrome tokens on the existing `.pk-footer` rule there: `--pk-footer-offset` from
   `1.5rem` to `1rem`, `--pk-footer-pad-block` from `1rem` to `0.75rem`. `1rem` is the number sketch
   044's own "What Changes in the Real App" section names (16px, against 260901-ty6's already-reduced
   24px). `0.75rem` is not a new number either — it is the value the same block already carries for
   `--pk-footer-gap-list`. Together this takes the mobile footer's vertical chrome from 56px to 40px
   for what is now a single 12px line of small print. Extend the existing comment above that rule
   (append a dated paragraph — do not rewrite or delete what 260901-ty6 wrote there; requirement 5):
   state that 260901-ty6's 1.5rem was tuned for a 3-line footer, that sketch 044 winner H reduced the
   content to one line, and that the boundary cue is still the footer's own background/border surface
   change so the margin only has to supply breathing room.

2. Add a `.pk-footer-left { display: none; }` rule, placed adjacent to the existing
   `.pk-footer-right` hide so the two live together. Its comment must draw the distinction that the
   existing `.pk-footer-right` comment makes load-bearing, because the two hides are NOT the same
   kind of act: the right cluster may be hidden because every child relocates to the mobile drawer,
   whereas the left cluster's FAQ/Contacto/Juntadas links relocate NOWHERE. That is a deliberate,
   developer-accepted content removal (sketch 044's "Real Tradeoff, Verified" section: those three
   anchors were grepped and exist nowhere else in the app; the About page stays reachable from the
   header, only the direct jump to its FAQ/Contact/Meetups sections is lost). Say so explicitly, so
   nobody later "restores" the links believing the hide was an oversight, and nobody adds a fourth
   concern to that cluster assuming it has a drawer equivalent. Mirror the parent-not-children
   reasoning verbatim in spirit: the empty flex parent would still spend a cluster gap slot.

3. Add a `.pk-footer-copyright { display: none; }` rule next to it. Comment: the copyright notice
   carries no compliance requirement (sketch 044's research pass established that the BGG attribution
   does and the copyright line does not), it survives untouched at `>480px`, and the class exists
   solely as a stable hook so the hide is not positional.

4. Add a `main.pk-boundary-collapse + .pk-footer { margin-top: 1rem; }` rule inside the same media
   block, as a LITERAL and not `var(--pk-footer-offset)`. This preserves 260901-ty6's deliberate
   decoupling: the detail page's boundary is an independently-made decision that must be re-decided
   visibly rather than dragged along by a token retune. Comment it as exactly that, and record that
   sketch 044 is the new sketch round that legitimately reopens sketch 035's closed 24px boundary
   decision **at ≤480px only** — the `>480px` literal at ~line 4320 is untouched and sketch 035's
   desktop decision still stands. Place this rule AFTER the `.pk-footer` token rule in the block, and
   note in the comment that the ordering matters to nothing in the cascade but that the test helper
   is anchored precisely so it never has to.

Do not touch `bgg_attribution/1`, `.pk-bgg-note`, or any `.pk-bgg-note` CSS: requirement 4 pins the
real logo image plus the "Powered by BGG" text, plain `inline` and never `inline-flex`, at the
documented `href`. FooterAttributionTest already guards all of that and must stay green untouched.
  </action>

  <verify>
    <automated>mix test test/pukllay_club_web/footer_rhythm_test.exs test/pukllay_club_web/footer_attribution_test.exs test/pukllay_club_web/footer_overflow_test.exs test/pukllay_club_web/stylesheet_integrity_test.exs test/pukllay_club_web/header_row_height_test.exs</automated>
    <automated>mix test</automated>
  </verify>

  <done>
The full suite is green. At ≤480px the stylesheet hides `.pk-footer-left` and the copyright hook and
nothing else in the footer; the attribution anchor, its `href`, its image and its text are unchanged
in markup and in CSS; both chrome tokens are retuned downward past the 260901-ty6 values; the
detail-page boundary literal and the mobile offset token carry the same number; and no rule outside
the `@media (max-width: 480px)` block was edited.
  </done>
</task>

<task type="auto">
  <name>Task 2: Retire the ≤480px type rules the hide made unreachable, and reconcile every document that described them</name>
  <files>assets/css/app.css, lib/pukllay_club_web/components/layouts.ex, test/pukllay_club_web/footer_rhythm_test.exs</files>

  <action>
Task 1 made two rules from quick task 260901-ty6 unreachable. `.pk-brand-quiet` is added only by
`brand_logo/1` when `mark={false}`, and `footer/1` is that component's only such call site — which
Task 1 just hid at ≤480px. `.pk-footer-links` exists only inside that same hidden cluster. Leaving
either rule in place, still guarded by a passing test, is the exact stale-contract failure mode
260901-ty6's own Task 3 discovered and fixed in the type-inventory table. Close it in the same
direction.

**app.css (inside the `@media (max-width: 480px)` block only):**
- Remove the `.pk-brand-quiet .pk-brand-name { font-size: 1.25rem }` rule together with its comment
  block. In its place leave a short dated note recording that the ≤480px SIZE exception to D-B is
  WITHDRAWN — the footer lockup no longer renders at this breakpoint at all (sketch 044) — so D-B
  ("demotion is by colour, not size") once again holds at every viewport width with no exception.
  Also append one sentence to the BASE `.pk-brand-quiet .pk-brand-name` rule's comment (~line 1214)
  saying the same thing, so a reader who lands on the base rule is not left believing a breakpoint
  exception still exists. Do not otherwise edit that base comment — D-B's own reasoning is closed
  and stays verbatim (requirement 5).
- Remove the `.pk-footer-links { font-size: 0.875rem }` rule together with its comment block. Leave
  a short dated note in its place recording that the links do not render at ≤480px anymore, and
  keeping the one fact from the removed comment that is still true and still useful: the stale
  `native <select>` row 260901-ty6 corrected in the type-inventory table stays corrected, and the
  ≥481px links still render at the inherited 1rem.
- KEEP `--pk-footer-gap-list`, `--pk-footer-gap-group` and `--pk-footer-gap-cluster` in the ≤480px
  `.pk-footer` rule. Their consumers are now hidden, so they are dormant rather than wrong; they are
  one-line tokens on a shared scale, and deleting them would break the tier-ordering guards for no
  rendered benefit. Append one sentence to that rule's comment marking them dormant at this
  breakpoint and naming what would wake them (any future rule that unhides a footer cluster below
  480px), so the dormancy is documented rather than discovered.

**test/pukllay_club_web/footer_rhythm_test.exs:**
- Delete the three tests that pin the two removed rules: "the footer wordmark's mobile font-size is
  scoped through .pk-brand-quiet", "the mobile wordmark keeps an internal hierarchy: smaller than
  desktop, larger than the tagline", and "the ≤480px block declares a .pk-footer-links font-size
  strictly less than 1rem". Each asserts a rule that must no longer exist; leaving them would
  require reintroducing dead CSS to keep the suite green.
- KEEP "no unscoped .pk-brand-name font-size rule reaches the header's wordmark", "no rule in the
  ≤480px block reintroduces the banned 10px/0.625rem size", "the effective mobile tier scale reads
  item < list < group <= cluster", and "the brand anchor keeps its 44px touch floor after the
  wordmark shrink". All four are refutes or scale guards that remain true and remain useful. Rename
  the last one's failure message only if it now reads as if a wordmark shrink still ships; the
  `min-h-11` assertion itself stays, because `brand_logo/1` is still the header's lockup.
- Update the surviving describe block's header comment for that block: append (do not delete) a
  dated paragraph explaining that the ink/density half of 260901-ty6 was superseded by sketch 044's
  content reduction, so the tests that measured it were removed rather than weakened.

**lib/pukllay_club_web/components/layouts.ex:**
- `brand_logo/1`'s `@doc` (lines 37-43) and the `mark` attr doc string (lines 51-52) both currently
  tell the reader the footer wordmark also shrinks below 480px. That is no longer true. Rewrite just
  those two references to say the footer lockup is hidden entirely below 480px per sketch 044, while
  keeping the D-A/D-B statements around them intact.
- `footer/1`'s documentation block (lines 870-970): APPEND a new dated paragraph at the end of it —
  do not edit or delete the existing paragraphs, which document sketch 011, the theme-control
  grouping, the `footer-desktop-overloaded` and `footer-desktop-imbalance` debug history, and the
  legal-band split, all of which remain accurate at `>480px` (requirement 5). The new paragraph must
  say: at ≤480px this footer renders as the BGG attribution line alone; the left cluster and the
  copyright span are hidden in CSS rather than removed from the markup, so every desktop contract
  above continues to describe the shipped DOM; the FAQ/Contacto/Juntadas removal is a
  developer-accepted tradeoff from sketch 044, not an oversight; and the attribution is the one
  element that may never be hidden at any width (D-04).
  </action>

  <verify>
    <automated>mix test</automated>
    <automated>mix format --check-formatted</automated>
  </verify>

  <done>
The suite is green with the two unreachable rules and their three guarding tests gone. No stylesheet
comment, component doc, or test failure message tells a reader that a footer wordmark size or footer
link size applies at ≤480px. The base D-B comment and the whole existing `footer/1` documentation
block are intact, with new dated paragraphs appended rather than substituted.
  </done>
</task>

<task type="auto">
  <name>Task 3: Measure it at 390px, re-measure the ≤480px type inventory, close the docs</name>
  <files>.claude/skills/ui-design-system/SKILL.md</files>

  <precondition>
The Phoenix dev server is reachable at http://localhost:4000 and a headless Chrome with a CDP
endpoint is available — the same measurement setup quick task 260901-ty6 used to produce its
before/after tables. If either is unavailable, halt and report rather than writing measured numbers
into SKILL.md from inference: this task exists specifically because that table's own text prescribes
"Re-measure before adding a new type combo to this screen", and a guessed count is the stale row it
already had to fix once.
  </precondition>

  <action>
**Measure, at 390px (mobile, the primary target) and 768px (desktop control):**
- `.pk-footer` computed `margin-top`; `.pk-footer-row` computed `padding-top`/`padding-bottom`;
  `.pk-footer` and `.pk-footer-row` rendered heights; the gap between the last content block and the
  footer's top edge. Compare against 260901-ty6's SUMMARY tables (390px: 24 / 16 / 16, footer 156px;
  768px: 48 / 24 / 24, footer 147px). Every 768px number must come back byte-identical — that is the
  proof requirement 2 asks for, and if any of them moves, stop and report rather than proceeding.
- Do the same on the detail page (a route whose `main` carries `pk-boundary-collapse`) at 390px, to
  confirm the boundary literal Task 1 added lands the same gap the catalog page gets.
- At 390px, confirm what actually renders inside `.pk-footer`: exactly one visible `.pk-footer-meta`,
  containing the `.pk-bgg-note` anchor, whose `href` is `https://boardgamegeek.com/`, with a visible
  `img` and the text "Powered by BGG". Confirm zero visible `.pk-footer-links a`, zero visible
  `.pk-brand-name` inside the footer, and no rendered "©" run.

**Re-measure the ≤480px type inventory** using the methodology the table documents, including the
refinement 260901-ty6's summary recorded: exclude descendants of a closed `.pk-drawer`/`.pk-sheet`,
because those keep `display: flex`/`block` and move off-canvas by `transform`, so a plain
`display !== 'none'` filter counts content no user can see.

**Update `.claude/skills/ui-design-system/SKILL.md`'s type-hierarchy section** from the measurement,
not from inference:
- The `Bebas Neue / 20px / 400 — footer lockup, ≤480px only` row (~line 115) no longer has a source —
  the footer wordmark does not render at ≤480px. Remove the row and, in the paragraph below the table
  (~lines 122-126) that describes the heading tier "gaining a second SIZE at ≤480px", correct that
  claim: the heading tier is back to one size at every width.
- The `Inter / 14px / 400` row (~line 117) currently cites `.pk-footer-links a`'s ≤480px 0.875rem as
  landing on that tier. Drop that clause — those links do not render at ≤480px anymore. The row
  itself stays (regular copy still uses it).
- The `Inter / 16px / 400 (≥481px only)` row (~line 119) is unaffected in substance; verify the
  measurement still shows it at 768px and leave the 260824-i8e stale-`<select>` correction it carries
  intact.
- Update the distinct-combo counts on ~lines 109-110 to the measured values at ≤480px and ≥481px,
  and update the measurement date. Do not carry forward the old counts.

Record every before/after number in the SUMMARY as a table, matching the shape 260901-ty6 used, so
the next person reading this footer's history gets one continuous series rather than two disconnected
snapshots.
  </action>

  <verify>
    <automated>mix test</automated>
    <human-check>At a real ≤480px viewport (390px is the reference), the footer is a single quiet strip carrying only the BGG logo and "Powered by BGG", it still reads as separated from the content above it rather than butted against it, the strip does not read as cramped, and tapping the attribution opens boardgamegeek.com. At 768px and 1280px the footer is visually unchanged from before this task — same brand lockup, same three links, same social row, same theme toggle, same copyright and attribution on the legal band.</human-check>
  </verify>

  <done>
Measured 768px values are byte-identical to 260901-ty6's after-table; measured 390px values show the
chrome down from 56px to 40px with a non-zero separating margin; the detail page and catalog page
report the same 390px footer offset; the ≤480px render contains the attribution and nothing else
from the footer; and SKILL.md's type inventory carries freshly measured combo counts with no row
describing an element that no longer renders at that breakpoint.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| app → third-party trademark/attribution terms | The BGG attribution is a licensing obligation (D-04); the app is the party that must keep rendering it. |
| app → visitor (public, unauthenticated page render) | Presentational only; no input crosses this boundary in this change. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-260902fdm-01 | Repudiation | `bgg_attribution/1` / `.pk-bgg-note` at ≤480px | medium | mitigate | A container-level `display: none` is the plausible way this footer reduction silently drops a compliance-required attribution. Task 1's compliance guard asserts, in the ≤480px cascade AND in the rendered markup, that `.pk-footer-legal`, unscoped `.pk-footer-meta` and `.pk-bgg-note` are never hidden and that the anchor keeps its `href`, image and text; Task 3 re-confirms it against a real 390px render. |
| T-260902fdm-02 | Information disclosure | copyright notice removal at ≤480px | low | accept | The "© {year} Pukllay Club" line carries no compliance or legal-protection requirement (sketch 044's research pass established this; copyright subsists without notice) and it remains rendered at every width above 480px. Removal at ≤480px is the developer's explicit decision (sketch 044 winner H). |
| T-260902fdm-03 | Denial of service | footer link reachability at ≤480px | low | accept | FAQ/Contacto/Juntadas are deep links into the About page; sketch 044 verified by grep that the header still reaches that page and that these three anchors exist nowhere else. Loss of the direct section jump on mobile is a developer-accepted tradeoff, documented in the CSS comment Task 1 writes and the `footer/1` doc paragraph Task 2 appends. |
| T-260902fdm-SC | Tampering | npm/pip/cargo installs | n/a | accept | No package-manager install occurs in this plan — no dependency is added, removed or upgraded. The Package Legitimacy Gate does not apply. |
</threat_model>

<verification>
1. `mix test` is green after every task (the repo's configured test command).
2. `mix format --check-formatted` passes — this repo's `.formatter.exs` runs Styler and the LiveView
   HTML formatter as plugins, so formatting is a real gate on both the `.ex` and `.heex` edits.
   Review the `git diff` for any Styler-produced rewrite before committing (the stack's own guidance:
   Styler can change program behaviour).
3. `mix compile --warnings-as-errors` passes (the repo's configured build command).
4. Task 3's 768px measurement matches 260901-ty6's after-table byte for byte — this is the primary
   evidence that requirement 2 (desktop completely unaffected) holds, and it is stronger than any
   CSS-text assertion because it observes the rendered cascade.
5. Grep confirmation that every edit to `app.css` landed inside the single
   `@media (max-width: 480px)` block, except the two explicitly-scoped comment appends (the base
   `.pk-brand-quiet .pk-brand-name` rule and the base `.pk-footer` mobile token comment).
</verification>

<success_criteria>
- At 390px the footer renders exactly one line — the BGG logo plus "Powered by BGG", linking to
  `https://boardgamegeek.com/` — with the brand lockup, tagline, three nav links, and copyright all
  absent.
- At 768px every measured footer value is identical to the values 260901-ty6 recorded.
- The ≤480px footer's vertical chrome is 40px (16px offset + 12px + 12px row padding), down from 56px.
- The catalog page and the `pk-boundary-collapse` detail page open the same footer gap at 390px.
- `footer_rhythm_test.exs` pins the new mobile shape (both hides, the compliance guard, both chrome
  ratios, the offset/boundary equality) and no longer pins any rule that cannot render.
- No stylesheet comment, component doc, test message, or SKILL.md row describes a ≤480px footer
  wordmark size or footer link size.
- The existing `footer/1` and D-B documentation is intact with new dated paragraphs appended.
</success_criteria>

<source_audit>
## Multi-Source Coverage Audit

No ROADMAP phase goal, REQUIREMENTS.md phase_req_ids, or RESEARCH.md apply — this is a quick task
with an inline requirement list, backed by a sketch and its synthesized skill reference. Those are
the authoritative sources and every item in them is audited below.

| Source | Item | Covered by | Status |
|--------|------|-----------|--------|
| GOAL | Reduce the ≤480px footer to just the BGG attribution line, per sketch 044 winner H | Tasks 1, 3 | COVERED |
| REQ-1 | Hide brand name/tagline, FAQ/Contacto/Juntadas, and the copyright line at ≤480px; leave only `<.bgg_attribution />` | Task 1 (`.pk-footer-left` + `.pk-footer-copyright` hides, compliance guard) | COVERED |
| REQ-2 | Desktop >480px completely unaffected; prefer CSS in the existing `@media (max-width: 480px)` block over markup restructuring | Task 1 (all rules inside the existing media block; the only markup change is one additive class with no desktop rule), verification item 4 (768px byte-identical measurement) | COVERED |
| REQ-3 | Tighten the ≤480px `.pk-footer`/`.pk-footer-row` vertical gap further than 260901-ty6's value | Task 1 (`--pk-footer-offset` 1.5rem→1rem, `--pk-footer-pad-block` 1rem→0.75rem; ratio guards RED-verified against today's values) | COVERED |
| REQ-4 | BGG line keeps the real logo + "Powered by BGG", plain `inline`, `href="https://boardgamegeek.com/"` | Task 1 (explicitly out of bounds for edits; compliance guard asserts it; FooterAttributionTest stays green untouched), Task 3 (confirmed on a real 390px render) | COVERED |
| REQ-5 | Read and respect `footer/1`'s existing documentation style — add to it, do not contradict or delete | Task 1 (appends to the ≤480px `.pk-footer` comment), Task 2 (appends a dated paragraph to `footer/1`'s block and one sentence to the base D-B comment; only comments whose own rule was deleted are removed) | COVERED |
| CONSTRAINT | An existing footer rhythm/CSS contract test from 260901-ty6 must be identified and updated (TDD), not left silently broken | Task 1 (`test/pukllay_club_web/footer_rhythm_test.exs` — helper hardening + new describe block, RED-first), Task 2 (removes the three superseded tests) | COVERED |
| SKETCH-044 | `assets/css/app.css`: the ≤480px `.pk-footer` gap tightens to 16px | Task 1 (`--pk-footer-offset: 1rem`) | COVERED |
| SKETCH-044 | `layouts.ex`: the footer's mobile-only content reduces to the attribution; brand block, links list and copyright span go | Task 1 — delivered via breakpoint-scoped CSS hides rather than mobile-only markup, per REQ-2's explicit preference. The rendered mobile result is identical; the DOM stays one shape, which is what keeps every existing desktop markup contract in `footer_rhythm_test.exs` and `layouts_test.exs` valid. | COVERED (mechanism differs from the sketch's note, by REQ-2's instruction) |
| SKETCH-044 | The FAQ/Contacto/Juntadas removal is a verified, developer-accepted tradeoff | Task 1 (CSS comment), Task 2 (`footer/1` doc paragraph), threat T-260902fdm-03 | COVERED |
| SKILL page-shell.md | Desktop footer described in the rest of that file is unaffected | REQ-2 coverage above; no page-shell.md edit needed (the decision is already synthesized there) | COVERED |
| DERIVED | 260901-ty6's ≤480px wordmark and link type rules, and the SKILL.md inventory rows citing them, become unreachable/stale | Task 2 (rule + test removal, doc reconciliation), Task 3 (live re-measurement and inventory update) | COVERED |

No item is MISSING. Nothing is deferred.
</source_audit>

<output>
Create `.planning/quick/260902-fdm-reduce-the-mobile-footer-to-just-the-bgg/260902-fdm-SUMMARY.md` when done.
</output>
