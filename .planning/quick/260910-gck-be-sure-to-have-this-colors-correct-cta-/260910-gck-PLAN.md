---
phase: quick-260910-gck
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md
  - assets/css/app.css
  - test/pukllay_club_web/live/catalog_show_test.exs
autonomous: false
requirements: [QUICK-260910-GCK]

estimate:
  tokens: 72000
  raw_tokens: 36000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "Every dark-mode CTA that renders --color-primary as label TEXT clears the 4.5:1 WCAG 1.4.3 floor against its own real ground (base-100 #2F154E for the About hero, .pk-preview-cta, and the Reintentar retry; base-200 #391B62 for the closing band)."
    - "Every dark-mode CTA that renders --color-primary as a BORDER clears the 3:1 WCAG 1.4.11 non-text floor against that same ground."
    - "The choice of fix was made by the developer at a blocking checkpoint from measured evidence — not selected unilaterally by the planner or the executor."
    - "Surfaces already passing are untouched: the About mobile sticky bar's .pk-sumate-btn-solid (white on #8C2BB6, 6.70:1), the Contacto accent chips (#EBD7F4 on #3A1F47), and every light-theme CTA (#3D096D on #FFFFFF, 14.4:1)."
    - "An automated test in the existing contrast harness pins the fix, so the next palette retune re-fires the tripwire instead of silently regressing."
    - "mix quality passes end to end with no WCAG assertion weakened, skipped, or deleted."
  artifacts:
    - ".planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md — the call-site inventory + measured contrast matrix + WCAG-role verdict per surface"
    - "assets/css/app.css — the chosen dark-scoped CTA fix plus its provenance comment"
    - "test/pukllay_club_web/live/catalog_show_test.exs — regression test for the chosen fix, reusing dark_theme_plugin_block/0, token_value/2, relative_luminance/1, contrast_ratio/2"
  key_links:
    - "The dark-scoped selector list <-> all 3 class-declaration sites (layouts.ex:921, game_preview.ex:163, core_components.ex:107) and the 5 rendered placements they fan out to — a missed site leaves a silent remaining failure with no test to catch it."
    - "The new CSS rule <-> the regex the new test uses to read it back — sketch 055's own test broke on exactly this seam (its assertion measured a token the architecture had stopped rendering)."
    - "daisyUI's layered .btn-outline/.btn-primary utilities <-> this file's unlayered .pk-* rules — unlayered always wins with no !important, the same cascade direction .pk-sumate-btn-solid already depends on (app.css top-of-file CASCADE-LAYER HAZARD note)."
---

<objective>
Resolve the dark-mode contrast failure on the site's outline-primary CTA buttons — the same
regression class quick task 260910-efe closed for 17 secondary rules, but on the one element
family that fix deliberately did not cover.

The shipped palette is correct. Pixel-sampling the developer's live screenshots confirms the CSS
custom properties are byte-exact per sketch 054: the hero Sumate button paints exactly `#8C2BB6`
on `#2F154E`, the closing-band Sumate exactly `#8C2BB6` on `#391B62`, and the Contacto chips
exactly `#EBD7F4` on `#3A1F47`. This is not a wrong-hex bug. It is `--color-primary` in its TEXT
and BORDER role again: 2.34:1 and 2.08:1 respectively, both under the 4.5:1 WCAG AA text floor.
These buttons escaped 260910-efe's sweep because they take their `color`/`border-color` from
daisyUI's generated `.btn-outline.btn-primary` utilities, not from a literal
`color: var(--color-primary)` line in `app.css` that a grep over that file would find.

The fix is NOT mechanical. Sketch 055's `--color-neutral` ink swap was chosen for *secondary*
signal rules (nav-active, hover states) where losing brand colour was an acceptable trade. Sumate
is the site's primary call to action — it exists to carry brand primary prominently. Applying the
same swap here could mute the one element most meant to stand out. So this plan gathers real
evidence, then routes the choice to a blocking developer checkpoint, exactly as 260910-efe /
sketch 055 established.

Purpose: close the last open dark-mode WCAG debt from the sketch 054 palette ship, without the
planner or executor unilaterally deciding how loud the site's primary CTA is allowed to be.
Output: a measured evidence artifact, a developer decision, the chosen CSS fix, and a regression
test that pins it.

No tracer task: this is a single-layer CSS/contrast change with no architecture to prove
end-to-end, and Task 3 already walks the full path (rule -> rendered ink -> measured ratio ->
automated gate) for every affected selector in one rule. The real risk gate here is the decision
checkpoint, not an integration seam.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md

Project skills — load before touching CSS or .heex:
@.claude/skills/ui-design-system/SKILL.md
@.claude/skills/sketch-findings-pukllay_club/SKILL.md

The precedent this plan follows (read for the pattern, not to copy the answer):
@.planning/quick/260910-efe-implementar-en-assets-css-app-css-el-the/260910-efe-SUMMARY.md
@.planning/sketches/055-dark-primary-as-text-contrast-fix/README.md

Source under change:
@assets/css/app.css
@lib/pukllay_club_web/components/layouts.ex
@lib/pukllay_club_web/components/game_preview.ex
@lib/pukllay_club_web/components/core_components.ex
</context>

<pre_verified_facts>
Confirmed by reading the real files at planning time. Re-verify anything you depend on; do not
re-derive what is already stated here.

**Dark theme tokens** (`assets/css/app.css`, dark `@plugin "daisyui-theme"` block, ~L159-192):
`--color-base-100: #2F154E`, `--color-base-200: #391B62`, `--color-base-300: #462278`,
`--color-primary: #8C2BB6`, `--color-primary-content: #FFFFFF`, `--color-neutral: #B8A6CC`,
`--color-accent: #3A1F47`, `--color-accent-content: #EBD7F4`.

**Class-declaration sites** — `grep -rn "btn-outline btn-primary" lib/` returns exactly 3
(the fourth mention in `layouts.ex` prose at ~L871 is a doc comment split across a line break and
does not match):
1. `lib/pukllay_club_web/components/layouts.ex:921` — `sumate_cta/1`,
   `class={["btn btn-outline btn-primary pk-sumate-btn", @class]}`
2. `lib/pukllay_club_web/components/game_preview.ex:163` —
   `class="pk-preview-cta btn btn-outline btn-primary btn-block min-h-11"`
3. `lib/pukllay_club_web/components/core_components.ex:107` —
   `"secondary" => "btn-outline btn-primary"`

**Rendered placements and their real grounds:**
| Placement | Source | Ground selector | Ground token |
|---|---|---|---|
| About hero Sumate | `about_live.ex:418` | `#about-hero` (declares no background of its own) | page `--color-base-100` `#2F154E` |
| About closing-band Sumate | `about_live.ex:840` | `section#cierre.pk-band.pk-band-tint` -> `.pk-band-tint { background: var(--color-base-200) }` (app.css ~L3255) | `--color-base-200` `#391B62` |
| About mobile sticky Sumate | `about_live.ex:943` | adds `pk-sumate-btn-solid` -> `background: var(--color-primary); color: var(--color-primary-content)` (app.css ~L2803) | **already filled, 6.70:1 — PASSES, out of scope** |
| Catalog preview CTA | `game_preview.ex:163` | `.pk-portal { background: var(--color-base-100) }` (~L1141) and `.pk-sheet { background: var(--color-base-100) }` (~L1193) | `--color-base-100` `#2F154E` |
| "Reintentar" retry | `catalog_live/index.ex:1257` via `<.button variant="secondary">` | catalog page ground | `--color-base-100` `#2F154E` |

**NOT affected, do not touch:** `catalog_live/show.ex:1150,1162,1171` use bare
`btn btn-outline` with no `btn-primary` (they resolve to base-content, not primary).
`.pk-band-dark` (FAQ) fills with `--color-primary` and inks with `--color-primary-content` — a
fill role, already correct. Contacto's chip buttons use accent-bg/accent-text, already correct.

**Existing harness to reuse, do not write a second one** — in
`test/pukllay_club_web/live/catalog_show_test.exs`: `css_source/0`, `dark_theme_plugin_block/0`,
`light_theme_plugin_block/0`, `token_value/2`, `relative_luminance/1` (~L3987),
`contrast_ratio/2` (~L4009), and the `dark_pill_tag_text_override_block/0` idiom (~L4322) that
reads a dark-scoped override's real declaration body back out of `app.css` by regex.

**Cascade fact:** every `.pk-*` rule in `app.css` is unlayered and therefore beats daisyUI's
`@layer utilities` rules regardless of specificity — `.pk-sumate-btn-solid` already relies on
exactly this to out-specify `btn-outline`/`btn-primary` with no `!important`. See the
CASCADE-LAYER HAZARD note at the top of `app.css`.

**Environment:** `deps/` is not fetched in a fresh worktree (260910-efe hit this) — run
`mix deps.get` before any `mix test`/`mix quality`. `mix quality` runs
`hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted, credo --strict,
sobelow, test`.
</pre_verified_facts>

<tasks>

<task type="auto">
  <name>Task 1: Measure every affected CTA surface and write the evidence artifact</name>
  <files>.planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md</files>
  <precondition>`deps/` is populated (`mix deps.get` has been run in this worktree) — the daisyUI source at `deps/daisyui/packages/bundle/` must be readable to confirm what `.btn-outline`/`.btn-primary` actually paint.</precondition>
  <action>
Produce the measured evidence the Task 2 checkpoint will be decided from. Write it to the
EVIDENCE.md path above. Do not change any application file in this task.

Establish four things, in this order:

(1) **Call-site inventory — verify, do not assume.** Re-run `grep -rn "btn-outline btn-primary" lib/`
and `grep -rn "variant=\"secondary\"\|sumate_cta\|pk-preview-cta" lib/`. Confirm the 3
class-declaration sites and 5 rendered placements recorded in `<pre_verified_facts>` are still
accurate and still complete. If you find a placement not listed there, add it — the pre-verified
table is a floor, not a ceiling.

(2) **What daisyUI actually paints.** Read `.btn-outline` and `.btn-primary` in
`deps/daisyui/packages/bundle/` and record, verbatim, which CSS properties each sets and from
which custom property. Confirm concretely that `btn-outline btn-primary` resolves the button's
`color` AND `border-color` to `--color-primary` with a transparent background. This is the
premise the whole plan rests on; if daisyUI 5.5.20 resolves it differently, stop and record what
it does instead.

(3) **The WCAG-role analysis, done properly — not assumed.** For each affected placement,
determine the applicable floor, and record the reasoning:
  - The button LABEL ("Sumate", the preview CTA label, "Reintentar") is real text content, so
    WCAG 2.1 SC 1.4.3 Contrast (Minimum) applies. Its floor is 4.5:1 for normal text, or 3:1 only
    if the rendered text qualifies as LARGE (>= 24px, or >= 18.66px when bold/>=700). Resolve the
    ACTUAL rendered `font-size` and `font-weight` per placement before picking a floor —
    `.pk-sumate-btn` declares `font-size: 1rem` (app.css ~L2740) while `.pk-preview-cta` and the
    Reintentar button inherit daisyUI `.btn`'s own size; read daisyUI's `.btn` for the weight.
    State the resulting floor per placement explicitly.
  - The button BORDER is a visual boundary of a user-interface component, so WCAG 2.1 SC 1.4.11
    Non-text Contrast applies, floor 3:1.
  This settles whether "leave it as it is" is defensible on the merits or not — record the verdict
  either way, with the numbers behind it.

(4) **The contrast matrix.** Compute WCAG 2.1 relative luminance and contrast ratios for
`#8C2BB6` against `#2F154E` and `#391B62`, and for each candidate replacement ink against those
same two grounds: `--color-neutral` `#B8A6CC`, `--color-accent-content` `#EBD7F4`, and the solid
pair `#FFFFFF` on `#8C2BB6`. Use a throwaway Node script in the session scratchpad (the sketch
054 `contrast-check.mjs` is not reusable here — it parses that one sketch's `index.html`). Do not
add a script to the repo.

Write EVIDENCE.md with: the verified call-site table (site -> rendered placement -> ground token
-> ground hex), the daisyUI resolution finding from (2), the per-placement floor verdict from
(3), and the ratio matrix from (4) with a PASS/FAIL against each placement's own applicable
floor. Keep it a reference table, not prose — Task 2 reads it out loud to the developer.
  </action>
  <verify>
    <automated>test -f .planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md && grep -qi 'pk-sumate-btn' .planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md && grep -qi 'pk-preview-cta' .planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md && grep -qi 'core_components' .planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md && grep -qi '1\.4\.11' .planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md && grep -qi '1\.4\.3' .planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md && grep -c '2F154E' .planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-EVIDENCE.md</automated>
  </verify>
  <done>EVIDENCE.md exists and records: all 3 class-declaration sites and every rendered placement found (>= the 5 in the pre-verified table), what daisyUI's `btn-outline btn-primary` resolves `color`/`border-color`/`background` to, the applicable WCAG floor per placement with the rendered font-size/weight that determined it, and a ratio matrix covering `#8C2BB6` plus all three candidate inks against both `#2F154E` and `#391B62`, each marked PASS or FAIL against its own floor. No application file changed.</done>
</task>

<task type="checkpoint:decision" gate="blocking">
  <name>Task 2: Developer decides how to fix the dark-mode CTA contrast</name>
  <reversibility rating="costly">This sets the dark-mode treatment of the site's primary call to action. Reversing it later is cheap in CSS but re-opens a visual-composition judgement the developer already made against sketches 051/052/054 — a taste decision with a real cost to redo, not a mechanical toggle.</reversibility>
  <decision>
How to restore WCAG contrast on the dark-mode outline-primary CTA buttons (both About Sumate
placements, the catalog preview CTA, and the generic `variant="secondary"` button) — specifically,
whether the site's primary call to action keeps brand-primary colour in dark mode, and by which
mechanism.
  </decision>
  <context>
STOP. Present the Task 1 evidence and wait for the developer's choice. Do not implement any
option, do not pick a default, and do not proceed on silence — `workflow.auto_advance` does not
apply to this checkpoint.

Present, in this order:

**What was checked and what is fine.** The shipped palette is byte-exact and correct. The mobile
sticky Sumate (`.pk-sumate-btn-solid`, 6.70:1) and the Contacto accent chips both pass. This is
not a wrong-colour bug.

**What fails.** Read the EVIDENCE.md matrix out: each failing placement, its ground, its measured
ratio, its applicable floor, and the numbers behind the floor choice. Include the 1.4.11 border
verdict alongside the 1.4.3 label verdict.

**The tension, stated plainly.** The identical mechanical fix shipped hours ago (sketch 055,
`--color-neutral` ink swap) was chosen for 17 *secondary* signal rules where losing brand violet
was an acceptable trade. Sumate is the primary CTA — it exists to carry brand primary
prominently. Applying the same swap here mutes the one element most meant to stand out. That is a
taste call, so it is the developer's.

Present every option below with its real measured numbers from EVIDENCE.md, and adjust or add
options if Task 1 turned up something that changes the picture. Record the developer's verbatim
choice and their reasoning before continuing. If they choose `sketch-first`, stop and hand back —
Task 3 does not run until a winner exists.
  </context>
  <options>
    <option id="solid-fill">
      <name>A — dark-scoped SOLID fill (primary background, primary-content ink)</name>
      <pros>Reuses the exact pair already audited at 6.70:1 and already live on this same button at the About mobile sticky bar. Brand primary stays fully visible — arguably more prominent than the outline. One already-proven mechanism, no new token.</pros>
      <cons>Dark mode's CTA rest state diverges from light's outline-at-rest treatment that sketch 013-E / 051 composed. `btn-outline`'s fill-on-hover inversion becomes meaningless once the rest state is already filled, so an explicit hover is needed — the existing `.pk-sumate-btn-solid:hover { filter: brightness(1.08) }` is the established answer.</cons>
    </option>
    <option id="neutral-ink">
      <name>B — dark-scoped ink + border swap to `--color-neutral` (#B8A6CC)</name>
      <pros>The literal sketch 055 precedent — one mechanism across the whole file, one token, nothing new to learn. 7.00:1 on base-100 and 6.21:1 on base-200, clear on both grounds.</pros>
      <cons>The primary CTA reads as a muted grey-lilac outline in dark — exactly the muting risk this checkpoint exists to surface. The site's loudest element becomes its quietest colour.</cons>
    </option>
    <option id="accent-content-ink">
      <name>C — dark-scoped ink + border swap to `--color-accent-content` (#EBD7F4)</name>
      <pros>Brighter than B (11.63:1 on base-100, 10.32:1 on base-200) and closer to CTA-grade presence. Still an existing mapped token, still one mechanism.</pros>
      <cons>Not brand violet either; may read as a plain near-white outline button, borrowing the Contacto chips' ink for a different role.</cons>
    </option>
    <option id="split-by-role">
      <name>D — split by role: solid fill for Sumate, ink swap for the secondary CTAs</name>
      <pros>Matches the actual hierarchy — the two Sumate placements are the site's primary CTA and keep full brand primary; `.pk-preview-cta` and `<.button variant="secondary">` are genuinely secondary and can take B's quieter ink.</pros>
      <cons>Two mechanisms instead of one, and a future reader has to know which button belongs to which. More comment surface to keep true.</cons>
    </option>
    <option id="sketch-first">
      <name>E — sketch A/B/C/D side by side before deciding</name>
      <pros>Buys a visual decision instead of one made from numbers, on the real hero + closing band + preview card — exactly what sketch 055 did for the previous regression, and this is a taste call.</pros>
      <cons>Costs a round trip through `/gsd-sketch`; Task 3 does not run this session.</cons>
    </option>
  </options>
  <resume-signal>Select: solid-fill, neutral-ink, accent-content-ink, split-by-role, or sketch-first (and say why, so the reasoning lands in the CSS comment).</resume-signal>
  <verify>
    <human-check>Developer has stated their chosen option and reasoning, and that choice is recorded verbatim in the task notes carried into Task 3.</human-check>
  </verify>
  <done>The developer has chosen one option (or directed a sketch round via `sketch-first`). The choice and its reasoning are recorded. Nothing was implemented before the choice arrived.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Implement the chosen fix and pin it with a regression test</name>
  <files>assets/css/app.css, test/pukllay_club_web/live/catalog_show_test.exs</files>
  <precondition>Task 2's checkpoint returned a developer-chosen implementable option (`solid-fill`, `neutral-ink`, `accent-content-ink`, or `split-by-role`). If the developer chose `sketch-first`, this task does not run.</precondition>
  <behavior>
    - The dark-mode label ink of every affected CTA clears that placement's applicable WCAG 1.4.3 floor against its own ground (base-100 `#2F154E` for hero / preview / retry, base-200 `#391B62` for the closing band).
    - The dark-mode border colour of every affected CTA clears the 3:1 WCAG 1.4.11 floor against those same grounds.
    - The test reads the ACTUALLY-RENDERED ink and border out of `app.css` (the way `dark_pill_tag_text_override_block/0` does) rather than asserting a hardcoded token pair — a hardcoded pair is what broke sketch 055's own test and had to be rewritten mid-execution.
    - Light theme still resolves these CTAs from `--color-primary` (`#3D096D` on `#FFFFFF`, 14.4:1) and that assertion still passes.
    - The `.pk-sumate-btn-solid` sticky-bar pair (`#FFFFFF` on `#8C2BB6`, 6.70:1) still passes and is not re-declared by the new rule.
  </behavior>
  <action>
Implement exactly the option the developer chose in Task 2. Nothing more.

**CSS (`assets/css/app.css`).** Express the fix as a dark-scoped override rule, grouping every
affected selector into one rule — the same shape as the existing sketch 055 block at ~L940-966
and `.pk-lightbox-close`'s dark-scoped fix, and placed adjacent to the `.pk-sumate-btn` group so a
future reader finds it where the button lives. Constraints that hold regardless of which option
won:
  - Change no value in either `@plugin "daisyui-theme"` block. The palette is not reopened.
  - Scope to `[data-theme="dark"]` only. Light mode is correct and stays untouched.
  - No `!important`. `[data-theme="dark"]` plus an unlayered `.pk-*` selector already out-specifies
    daisyUI's layered utilities — this is the mechanism `.pk-sumate-btn-solid` already relies on.
  - Cover all three declaration sites' selectors. `.pk-sumate-btn` and `.pk-preview-cta` are
    addressable directly. `core_components.ex`'s `variant="secondary"` produces only
    `btn btn-outline btn-primary` with no `.pk-*` hook — decide between adding a `.pk-*` class to
    that variant string in `core_components.ex` and targeting daisyUI's own class combination in
    the selector, and record in the rule comment which you chose and why. Note that editing the
    variant map changes a shared component, so its existing tests must still pass.
  - Exclude the sticky bar: `.pk-sumate-btn-solid` already declares the passing filled pair, and
    a new rule that also set `color`/`border-color` on it would create the two-rules-compete-on-
    one-property failure this file has already fixed twice (see `.pk-sumate-btn`'s own size
    history comment).
  - Write the rule's provenance comment in this file's established voice: what was measured,
    against which ground, which option the developer chose and why, and what was deliberately left
    alone. Update `.pk-sumate-btn`'s own comment block to record that dark mode now diverges
    here, so the next reader of that rule is not surprised.

**Test (`test/pukllay_club_web/live/catalog_show_test.exs`).** Add a test in the same describe
block as the existing `.pk-pill-tag` contrast test (~L4258-4362), reusing `css_source/0`,
`dark_theme_plugin_block/0`, `light_theme_plugin_block/0`, `token_value/2`,
`relative_luminance/1` and `contrast_ratio/2`. Write no second contrast harness. Follow
`dark_pill_tag_text_override_block/0`'s idiom: match the real dark-scoped rule by its literal
selector text, pull its declaration body, resolve the token it actually names, then measure that
token against both `--color-base-100` and `--color-base-200` and assert against the floors
`<behavior>` states. Keep the ExUnit computed test name (describe prefix plus test string) under
255 characters — 260910-efe hit that `SystemLimitError` ceiling.

Weaken nothing. No existing WCAG assertion may be lowered, skipped, or deleted. If an existing
assertion becomes structurally false because of the architecture change (the way sketch 055's did),
rewrite it to measure what the code now actually paints while keeping its floor exactly where it
is, and record that as a Rule 1 deviation.

Run `.planning/sketches/themes/check-theme-drift.sh` to confirm the sketch theme mirror is still
in sync — no option here changes a token, so it should pass untouched; if it does not, stop and
report rather than editing `default.css`.
  </action>
  <verify>
    <automated>mix deps.get && mix test test/pukllay_club_web/live/catalog_show_test.exs && .planning/sketches/themes/check-theme-drift.sh && mix quality</automated>
  </verify>
  <done>`mix quality` passes end to end (hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted, credo --strict, sobelow, test) with zero failures. The new test fails if the dark-scoped CTA rule is removed or its ink regressed below the floor — confirm by temporarily reverting the CSS rule, watching the test fail, and restoring it. `check-theme-drift.sh` reports zero drift. Neither `@plugin "daisyui-theme"` block was modified. `.pk-sumate-btn-solid` is not re-declared by the new rule.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| none crossed | This task changes only stylesheet declarations and a test. No user input is parsed, no network boundary is crossed, no data is stored or transmitted, and no package is installed. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-gck-01 | Denial of Service (accessibility availability) | Dark-mode outline-primary CTA buttons | medium | mitigate | The failing state IS the threat: at 2.08-2.34:1 the primary call to action is effectively unavailable to low-vision users and in bright ambient light. Task 3's fix plus its regression test restore and pin the WCAG 1.4.3 / 1.4.11 floors. |
| T-gck-02 | Tampering | Existing WCAG assertions in `catalog_show_test.exs` | medium | mitigate | A fix that "passes" by lowering, skipping, or deleting an existing contrast assertion would silently remove the tripwire that caught this. Task 3's `<action>` forbids weakening any assertion and requires any structurally-false one to be rewritten at its existing floor; the `mix quality` gate runs the full suite. |
| T-gck-SC | Tampering | package-manager installs | low | accept | No new package is added. `mix deps.get` resolves only the existing `mix.lock`-pinned set — no legitimacy gate required. |
</threat_model>

<verification>
- `mix quality` green end to end, with the full test suite passing and no assertion weakened.
- Every placement in EVIDENCE.md's table marked PASS against its own applicable floor after the
  fix — re-measure, do not assume the fix generalised across both grounds.
- `git diff assets/css/app.css` shows no change inside either `@plugin "daisyui-theme"` block.
- Removing the new dark-scoped rule makes the new test fail (the tripwire is real, not decorative).
</verification>

<success_criteria>
- The developer chose the fix at a blocking checkpoint, from measured evidence, and that choice is
  recorded verbatim.
- Every dark-mode CTA rendering `--color-primary` as label text or border clears its applicable
  WCAG floor on its own real ground.
- Nothing that already passed was disturbed: sticky-bar solid pair, Contacto accent chips, light
  theme, and both theme token blocks.
- An automated test pins the fix inside the existing contrast harness, with no second harness
  introduced.
</success_criteria>

<output>
Create `.planning/quick/260910-gck-be-sure-to-have-this-colors-correct-cta-/260910-gck-SUMMARY.md` when done.
</output>
