---
phase: quick-260910-hdc
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - assets/css/app.css
  - test/pukllay_club_web/live/catalog_show_test.exs
  - .planning/sketches/themes/default.css
autonomous: false
requirements: [QUICK-260910-hdc]

estimate:
  tokens: 48000
  raw_tokens: 48000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "In dark mode the nav links (Inicio / Quiénes Somos), the outline `Ver detalles` CTA, and the editorial hashtag pills render in a visibly SATURATED brand purple, not a grey-lavender — measured chroma at least 2x today's, on the dark theme's own brand hue."
    - "Every purple that reads as interactive or branded in dark mode sits on ONE hue line (the dark theme's own `--color-primary` hue), in three deliberate chroma tiers: fill > interactive ink > muted ink."
    - "The muted purple backing the mechanics/theme pills, the AÑO / DISEÑADORES / MECÁNICAS labels and the Comunidad BGG stats sits on that same hue line instead of 6.6 degrees off it at one third the chroma."
    - "Light theme renders byte-identically to today — every value it resolves is unchanged."
    - "Every re-pointed ink still clears WCAG 1.4.3 (4.5:1) as text and WCAG 1.4.11 (3:1) as a border against base-100, base-200 and base-300 in its own theme."
    - "No copy, markup, or Spanish text string changes — only CSS custom properties and CSS declarations."
  artifacts:
    - assets/css/app.css
    - test/pukllay_club_web/live/catalog_show_test.exs
    - .planning/sketches/themes/default.css
  key_links:
    - "`--pk-ink-brand` is declared in BOTH theme scopes (`:root` and `:root[data-theme=\"dark\"]`) — a dark-only declaration would leave light resolving an undefined variable and silently inherit."
    - "The light declaration reads `var(--color-primary)` rather than a copied hex, so light stays single-sourced from the brand manual and cannot drift."
    - "`.planning/sketches/themes/default.css`'s `--color-text-muted` is mirrored in BOTH of its dark regions — `check-theme-drift.sh` checks the media-query region against app.css AND the two dark regions against each other."
    - "The sketch-055 and sketch-056 tripwire tests in `catalog_show_test.exs` assert the override blocks resolve to a specific token by name — they fail closed when the token changes and must be moved deliberately, not deleted."
---

<objective>
Dark mode's branded-interactive ink and its muted pill/label ink are both drifting off the
brand purple, which is why they read as "disabled" and as a different purple from the solid
`Reserva` CTA. Replace the two ad-hoc dark-scoped `--color-neutral` ink-swaps with one
semantic token on the brand hue, and pull the muted ink onto that same hue line.

Purpose: the developer asked for ONE consistent purple palette that adapts per theme instead
of an ad-hoc "soft/muted" variant that drifts in hue and ends up looking disabled.
Output: a `--pk-ink-brand` token, a retuned dark `--color-neutral`, updated tripwire tests, a
re-synced sketch theme mirror.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

Load before editing any CSS: `Skill("ui-design-system")` (daisyUI conventions, the banned-patterns
list, and the "`assets/css/app.css` is the single source of truth for theme blocks" rule) and
`Skill("sketch-findings-pukllay_club")` (sketch 054/055/056 palette decision record).

@assets/css/app.css
@.planning/sketches/themes/default.css
@.planning/sketches/themes/check-theme-drift.sh
</context>

<measured_root_cause>
Measured directly off `assets/css/app.css`'s own two `daisyui-theme` blocks (sRGB -> OKLCh,
WCAG 2.1 relative luminance). These are the numbers the plan's chosen values derive from — do
not re-derive by eye.

| Token | Theme | Hex | OKLCh | vs base-100 | vs base-200 | vs base-300 |
|-------|-------|-----|-------|-------------|-------------|-------------|
| `--color-primary` | light | `#3D096D` | L30.4% **C0.151** H300.1 | 14.40 | 12.47 | 10.18 |
| `--color-neutral` | light | `#6B5B7B` | L49.9% C0.053 H307.3 | 6.16 | 5.34 | 4.36 |
| `--color-primary` | dark | `#8C2BB6` | L50.2% **C0.210 H313.1** | 2.34 | 2.08 | 1.78 |
| `--color-neutral` | dark | `#B8A6CC` | L75.3% **C0.057** H306.5 | 7.00 | 6.21 | 5.32 |

Two independent defects, both real:

1. **The "disabled" look is a chroma collapse, not a contrast failure.** Sketch 055 + 056
   re-pointed dark's branded-interactive TEXT and BORDER role from `--color-primary` to
   `--color-neutral` because the new deep-jewel primary measured 2.34:1 as text. That fixed
   contrast (7.00:1) but landed the role on a **C0.057** ink while the same role in light
   carries **C0.151** — 38% of the light theme's saturation. On a dark ground that is itself
   saturated (dark base-200 is C0.119) a C0.057 ink reads as grey-on-purple. Light's ground is
   near-neutral (base-200 C0.020), which is why the identical mechanism looks correct there.
   `--color-neutral` is genuinely this file's muted/quiet ink; it was never a brand ink, and
   overloading it for both roles is the defect.

2. **Two purples in one theme.** Dark's `--color-primary` sits at H313.1 while dark's
   `--color-neutral` sits at H306.5 — 6.6 degrees apart, at a 3.7x chroma ratio. The developer
   named the solid `Reserva` CTA fill (`--color-primary`, H313.1) as the correct brand purple,
   so H313.1 is dark's brand hue and the muted ink is the outlier.

**Both dark hex values that define the brand are developer-locked and must NOT move.**
`#8C2BB6` is sketch 054 round 2's chosen winner ("W2 Deep Jewel", 6.70:1 with white ink) and
is the very colour the developer cites as correct; `#3D096D` is the brand manual's own value.
The fix moves the INK roles onto those hues — it does not reopen either fill decision.

Light theme's own spread (primary H300.1, secondary H308.1) is the brand manual's spread, so
an ~8 degree family width is within brand tolerance and **light needs no change at all**.

**Derived values** (all in sRGB gamut, verified):

- `--pk-ink-brand`, dark = **`#C791E5`** — OKLCh L74% C0.13 H313.1 (dark's brand hue exactly).
  Contrast 6.43 / 5.71 / 4.89 on base-100/200/300: clears the 4.5:1 text floor on all three
  grounds and the 3:1 border floor with wide margin. **C0.13 vs today's C0.057 = 2.3x chroma**,
  and comparable to light's own branded ink at C0.151 — this is the whole fix for defect 1.
- `--pk-ink-brand`, light = **`var(--color-primary)`** — resolves to `#3D096D`, byte-identical
  to today. Declared as a variable read, not a copied hex, so light cannot drift.
- `--color-neutral`, dark = **`#C59CDC`** — OKLCh L75.3% C0.10 H313.1: the same lightness as
  today (so every existing contrast assertion holds — 6.85 / 6.08 / 5.20 on base-100/200/300,
  8.27 against `--color-neutral-content`, all still far above their 4.5:1 and 3:1 floors), moved
  onto the brand hue with chroma lifted 0.057 -> 0.10. Stays clearly quieter than
  `--pk-ink-brand` (C0.13) and the fill (C0.21), giving **one hue, three deliberate chroma
  tiers** — the "one consistent purple palette" that was asked for.

**Recorded, deliberately out of scope** (measured while auditing, not reported by the developer,
not on a reported surface): 9 further rules use `--color-primary` as a `border-color` and are
never dark-scoped, so their border resolves to `#8C2BB6` at 1.78-2.34:1 against its own ground
— under WCAG 1.4.11's 3:1 non-text floor. Sketch 055's own comment admits it skipped the border
role. Sites: `.pk-nav-links a[aria-current="page"]` (line ~1471), `.pk-search-morph.is-open`
(~1578), `.pk-search-morph:focus-within:not(.is-open)` (~1608), `.pk-footer-social a:hover`
(~2261), `.pk-drawer-links a[aria-current="page"]` (~2669), `.pk-about-contact-links a:hover`
(~3504), `.pk-chip:focus-visible` (~4226), `.pk-chip.is-active` (~4239),
`.pk-share-trigger:hover` (~5569). `.pk-pill-interactive:hover` (~1006) is the tenth and IS on a
reported surface (the mechanics/theme pills), so it alone is fixed here. Raise the other 9 as a
follow-up rather than widening this task.
</measured_root_cause>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: One brand-ink token, wired end-to-end through both dark override blocks</name>
  <files>assets/css/app.css, test/pukllay_club_web/live/catalog_show_test.exs</files>
  <read_first>
    - `assets/css/app.css` lines 109-235 (the `@theme` block, both `daisyui-theme` plugin blocks,
      and the `@custom-variant dark` declaration) — read the cascade-layer hazard note at the top
      of the file too.
    - `assets/css/app.css` lines 280-390 — the `:root` token block. `--pk-shadow-color` and
      `--pk-overlay-scrim` there are this file's established precedent for a `--pk-*` token that
      has no daisyUI counterpart; the new token follows that precedent, and its provenance comment
      should match their density.
    - `assets/css/app.css` lines 867-1010 — `.pk-pill-tag`, its sketch-055 provenance comment, the
      25-selector dark override block, `.pk-pill-interactive` and `.pk-pill-interactive:hover`.
    - `assets/css/app.css` lines 1125-1165 — `.pk-preview-cta`, the sketch-056 provenance comment,
      and the 2-selector dark override block.
    - `test/pukllay_club_web/live/catalog_show_test.exs` lines 3960-3995 (`dark_theme_plugin_block/0`,
      `token_value/2`, `relative_luminance/1`) and lines 4320-4500 (`dark_pill_tag_text_override_block/0`,
      `dark_secondary_cta_ink_swap_block/0` and the three tests that consume them).
  </read_first>
  <behavior>
    - The compiled stylesheet defines `--pk-ink-brand` under both theme scopes; neither scope is
      missing, so no rule ever resolves it as undefined.
    - Light: `--pk-ink-brand` resolves to the same value `--color-primary` resolves to, so every
      re-pointed rule paints exactly what it paints today.
    - Dark: `--pk-ink-brand` resolves to a hex whose contrast against dark `--color-base-100`,
      `-200` and `-300` is at least 4.5:1 (text) and at least 3:1 (border).
    - Dark: `--pk-ink-brand`'s OKLCh chroma is at least 0.11 — the assertion that actually
      encodes "reads as brand purple, not as disabled grey". A future retune that walks it back
      toward `--color-neutral`'s C0.057 must fail here rather than ship.
    - The dark override block covering `.pk-pill-tag` resolves its `color` from `--pk-ink-brand`.
    - The dark override block covering `.pk-preview-cta` / `.pk-btn-secondary` resolves BOTH
      `color` and `border-color` from `--pk-ink-brand`.
    - `.pk-pill-interactive:hover` resolves both `color` and `border-color` from `--pk-ink-brand`,
      and is no longer listed in the 25-selector dark override block (that entry became redundant
      once its base rule reads the token — leaving both would put two rules in competition over one
      property, the failure mode this file has already fixed twice).
    - Light theme's own branded-ink contrast assertion still passes unchanged.
  </behavior>
  <action>
    Declare the new semantic token in two theme-scoped rules, then re-point the three Role-B rules
    at it. Per D-01 (see measured_root_cause) the dark value is `#C791E5` and the light value is a
    variable read of `--color-primary`, never a copied hex.

    Placement: add the light declaration into the existing `:root` block that already holds
    `--pk-shadow-color`, and add a NEW `:root[data-theme="dark"]` rule immediately after that
    block for the dark declaration. Use `:root[data-theme="dark"]`, not a bare
    `[data-theme="dark"]`: `data-theme` is set on `<html>` by `assets/js/theme.js`, so a bare
    attribute selector ties with `:root` on specificity and would depend on source order, while
    the compound form wins outright — and it is the same idiom
    `.planning/sketches/themes/default.css` already uses for its own dark region. This is the
    file's first theme-scoped `--pk-*` token; say so in the comment so the next author knows it is
    a deliberate new shape rather than drift.

    Write the token's provenance comment at the density this file uses: name the chroma collapse
    as the defect (C0.057 against light's C0.151 in the same role), name H313.1 as dark's brand
    hue taken from the developer-locked `--color-primary`, record the three measured ground
    ratios, and record that the light declaration is a variable read specifically so light stays
    single-sourced from the brand manual. State plainly that this token is an INK role only — it
    is never a background fill and has no `-content` counterpart.

    Then, in the dark override block whose selector list begins with `.pk-pill-tag`, change its one
    `color` declaration to read the new token. In the dark override block for `.pk-preview-cta` /
    `.pk-btn-secondary`, change both its `color` and its `border-color` declarations to read the new
    token. In the base `.pk-pill-interactive:hover` rule, change both its `color` and its
    `border-color` declarations to read the new token — this is what closes that pill's 2.08:1
    hover border, and because light resolves the token to the identical value it changes nothing in
    light. Remove the now-redundant `.pk-pill-interactive:hover` entry from the 25-selector block's
    selector list.

    Update each of the two superseded provenance comments in place rather than deleting them:
    keep sketch 055's and 056's measurements and reasoning (they are the evidence for why the
    primary cannot be used as text or as a border in dark), and append what this task changed and
    why the muted token was the wrong home for a branded role. Do not restate the whole history.

    In `catalog_show_test.exs`, add one helper beside `dark_theme_plugin_block/0` that extracts the
    body of the new `:root[data-theme="dark"]` rule so `token_value/2` can read the token out of it,
    and add a small OKLCh-chroma helper (sRGB -> linear -> OKLab -> chroma magnitude) beside
    `relative_luminance/1`. Then update the three affected tests: the sketch-055 `.pk-pill-tag`
    test and the sketch-056 secondary-CTA test must assert their override block resolves to the new
    token and must measure the new token's value (not the plugin block's muted token) against the
    three dark grounds; add the chroma-floor assertion to one of them. Keep the existing light-theme
    assertions and the existing "must not be re-declared by a second dark-scoped rule" refutation
    exactly as they are. Add one assertion that light's declaration is a variable read of
    `--color-primary`, so a future author cannot quietly replace it with a literal.

    Do not touch any `.heex` template, any Spanish string, or the two `daisyui-theme` plugin blocks
    in this task.
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/live/catalog_show_test.exs && grep -q 'pk-ink-brand' assets/css/app.css && mix format --check-formatted</automated>
  </verify>
  <done>
    `mix test test/pukllay_club_web/live/catalog_show_test.exs` passes with the three updated tests
    asserting the new token by name, its three ground ratios above 4.5:1 and 3:1, and its chroma at
    or above 0.11. The 25-selector block no longer lists the pill-hover selector. `mix format
    --check-formatted` is clean.
  </done>
  <reversibility rating="reversible">A token declaration plus four declaration edits in one CSS file; revert is a single `git revert`.</reversibility>
</task>

<task type="auto">
  <name>Task 2: Pull dark's muted ink onto the brand hue and re-sync the sketch mirror</name>
  <files>assets/css/app.css, .planning/sketches/themes/default.css, test/pukllay_club_web/live/catalog_show_test.exs</files>
  <read_first>
    - `assets/css/app.css` lines 143-192 — the dark `daisyui-theme` block and sketch 054's
      MEASURED CONSTRAINTS comment above it, which records the muted-on-bg ratio that this task
      changes.
    - `.planning/sketches/themes/default.css` lines 1-45 (the mapping-table header and the `:root`
      light region) and lines 115-152 (the `@media (prefers-color-scheme: dark)` region and the
      `:root[data-theme="dark"]` region) — `--color-text-muted` appears in both dark regions.
    - `.planning/sketches/themes/check-theme-drift.sh` — the `neutral->text-muted` mapped pair and
      the dark-regions agreement loop are what gate this edit.
    - `test/pukllay_club_web/live/catalog_show_test.exs` around lines 3395-3450 (the `.pk-title-echo`
      border test, which measures this token in BOTH themes) and around lines 4010-4080 (the
      lightbox-close test, which measures it as a FILL against `--color-neutral-content`).
  </read_first>
  <action>
    Change dark `--color-neutral` from its current value to `#C59CDC` in the dark `daisyui-theme`
    plugin block in `assets/css/app.css`, per D-02. Leave every other value in that block, and the
    entire light block, untouched — including `--color-neutral-content`, whose 8.27:1 pairing with
    the new value still clears its floor.

    Update sketch 054's MEASURED CONSTRAINTS comment above the block so its recorded muted-on-bg
    ratio matches the new measured value instead of the superseded one, and append one line naming
    why the value moved: the muted ink sat 6.6 degrees off dark's brand hue at roughly one third
    its chroma, which is what made the pills, the uppercase fact labels and the Comunidad BGG stats
    read as a second, greyer purple. Record that lightness was deliberately held at the previous
    value so every contrast assertion that already gates this token keeps its measured margin.

    Mirror the new value into `.planning/sketches/themes/default.css`'s `--color-text-muted` in
    BOTH dark regions — the `prefers-color-scheme` media query region AND the
    `:root[data-theme="dark"]` region. The drift gate checks app.css against the media-query region
    and then checks the two dark regions against each other, so updating only one region fails the
    gate. Leave the light `:root` region's own value alone.

    Add one test asserting the dark muted token's OKLCh hue sits within 2 degrees of the dark
    `--color-primary`'s hue, reusing Task 1's chroma/OKLab helper. This is the tripwire that
    encodes "one hue per theme" — the actual thing being fixed — and it is what makes a future
    palette retune that re-splits the family fail here rather than ship. Also assert the new value's
    chroma is strictly below `--pk-ink-brand`'s, so the muted tier can never overtake the
    interactive tier.
  </action>
  <verify>
    <automated>.planning/sketches/themes/check-theme-drift.sh && mix test test/pukllay_club_web/live/catalog_show_test.exs</automated>
  </verify>
  <done>
    `check-theme-drift.sh` exits 0 with the muted pair reported OK in both the light and dark
    sections and both dark regions in agreement. The full `catalog_show_test.exs` suite passes,
    including the pre-existing title-echo border and lightbox-close fill contrast tests (unchanged
    assertions, new value) and the new hue-alignment and chroma-ordering tests.
  </done>
  <reversibility rating="reversible">Three hex literals and one comment; `git revert` restores the sketch-054 value exactly.</reversibility>
</task>

<task type="checkpoint:human-verify">
  <name>Task 3: Confirm the purple family in both themes, mobile and desktop</name>

  <what-built>
    Dark mode's branded-interactive ink (nav links, the outline `Ver detalles` CTA, editorial
    hashtag pills, every pill/chip hover state) now resolves from one new `--pk-ink-brand` token
    on dark's own brand hue at 2.3x its previous saturation, replacing the muted grey-lavender
    token sketch 055/056 had borrowed for that role. Dark's muted ink (mechanics/theme pills, the
    `AÑO` / `DISEÑADORES` / `MECÁNICAS` labels, Comunidad BGG stats) moved onto that same hue with
    its chroma lifted, so the theme now carries one purple hue in three tiers — fill, interactive
    ink, muted ink — instead of two purples 6.6 degrees apart. Light theme resolves every value to
    exactly what it resolved to before.
  </what-built>

  <how-to-verify>
    Run `mix quality` first and report the result. Then start the server and walk the developer
    through the four reported surfaces in BOTH themes, at a mobile viewport (390px — the primary
    target per project convention) and at desktop:

    1. Nav bar — `Inicio` and `Quiénes Somos` at rest, on hover, and on the current page.
    2. A catalog card's outline `Ver detalles` CTA.
    3. A game detail page — the mechanics/theme pills, the editorial hashtag pills, the
       `AÑO` / `DISEÑADORES` / `MECÁNICAS` uppercase labels, and the Comunidad BGG stats.
    4. The same detail page's solid `Reserva` CTA, in frame with the pills, so the developer can
       judge whether the pill purple now reads as the same family as the CTA purple.

    Ask three questions and wait for an answer to each:
    - Do the nav links and the `Ver detalles` button now read as interactive rather than disabled?
    - Do the pills, labels and stats read as the same purple family as the `Reserva` CTA?
    - Is light mode indistinguishable from before? (It should be — every light value resolves to
      what it resolved to previously; a visible light-mode change means something was mis-scoped
      and is a bug, not a preference.)

    If the dark ink still reads too quiet, the lever is `--pk-ink-brand`'s chroma and the measured
    headroom is recorded in this plan: C0.15 (`#CC8DED`) still clears 4.89:1 on base-300. Do not
    reach for `--color-primary` as text — it measures 2.34:1 and is why this whole thread exists.
  </how-to-verify>

  <resume-signal>
    Developer answers all three questions — either approving, or naming the specific surface and
    theme still wrong so the chroma lever above can be adjusted and this checkpoint re-run.
  </resume-signal>

  <done>Developer has answered all three questions and either approved or named a specific surface still wrong.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| (none crossed) | This plan changes only CSS custom properties and CSS declarations in a stylesheet already served publicly. No input parsing, no new markup, no data flow, no dependency, no configuration. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-hdc-01 | Tampering | `assets/css/app.css` theme blocks | low | mitigate | `check-theme-drift.sh` (Task 2 verify) plus the ExUnit contrast/chroma/hue assertions fail closed on any unintended token change, including an accidental edit to the light block or to a value outside this plan's scope. |
| T-hdc-02 | Information Disclosure | rendered UI legibility | medium | mitigate | Every re-pointed ink carries an ExUnit assertion against the 4.5:1 (WCAG 1.4.3) and 3:1 (WCAG 1.4.11) floors on base-100/200/300, so a value that renders content unreadable cannot ship. Task 3 adds a two-theme human confirmation. |
| T-hdc-03 | Repudiation | palette decision provenance | low | accept | Each edited value's provenance comment records the measured basis and the superseded value in place, matching this file's existing convention; the sketch 054/055/056 decision records stay intact and are amended rather than replaced. |
</threat_model>

<verification>
- `mix quality` passes (7-step alias: `hex.audit`, `deps.audit`, `deps.unlock --check-unused`,
  `format --check-formatted`, `credo --strict`, `sobelow`, `test`) with no new failures against
  the ~907-test baseline.
- `.planning/sketches/themes/check-theme-drift.sh` exits 0.
- `git diff --stat` touches exactly three files: `assets/css/app.css`,
  `test/pukllay_club_web/live/catalog_show_test.exs`,
  `.planning/sketches/themes/default.css`. Any `.heex`, `.ex` (other than none), or locale file in
  that diff is a scope breach — the developer's constraint was colours only, no copy.
- `git diff assets/css/app.css` shows no change to the light `daisyui-theme` plugin block.
</verification>

<success_criteria>
- In dark mode the nav links, the outline `Ver detalles` CTA and the editorial hashtag pills
  resolve their ink from `--pk-ink-brand` at OKLCh chroma at or above 0.11 on dark's brand hue —
  at least 2x the chroma they carry today — with every ground clearing 4.5:1 and 3:1.
- Dark's muted ink sits within 2 degrees of dark's `--color-primary` hue, at a chroma strictly
  between the old muted value and `--pk-ink-brand`, so the theme has one purple hue in three
  deliberate tiers.
- Light theme resolves every value to what it resolves to today; the light theme block is
  untouched in the diff.
- `mix quality` and `check-theme-drift.sh` both pass.
- The developer has confirmed all three Task 3 questions.
</success_criteria>

<output>
Create `.planning/quick/260910-hdc-fix-inconsistent-purple-cta-colors-acros/260910-hdc-SUMMARY.md` when done.
</output>
</content>
</invoke>
