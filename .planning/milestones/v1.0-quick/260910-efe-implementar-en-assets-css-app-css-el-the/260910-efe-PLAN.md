---
phase: quick-260910-efe
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - assets/css/app.css
  - .planning/sketches/themes/default.css
autonomous: false
requirements: [SKETCH-054]
user_setup: []

estimate:
  tokens: 60000
  raw_tokens: 30000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "assets/css/app.css's `name: \"dark\"` daisyUI block declares sketch 054's winner byte-exact: base-100 #2F154E, base-200 #391B62, base-300 #462278, primary #8C2BB6, primary-content #FFFFFF, secondary #642C77, accent #3A1F47, accent-content #EBD7F4."
    - "The dark block's error/success/info/warning/neutral tokens, and every `*-content` ink literal other than primary-content, are byte-identical to their pre-task values — the sketch's 13-token table is the complete change set, nothing outside it moved."
    - "The light theme block in app.css and the `:root` light block in default.css are byte-identical to their pre-task state — sketch 054 revised the dark theme only."
    - ".planning/sketches/themes/check-theme-drift.sh exits 0: all 13 mapped pairs agree in both light and dark, and default.css's two dark regions agree with each other."
    - "`mix quality` passes end to end, including the WCAG contrast gates in catalog_show_test.exs that read the dark theme block's own tokens out of the real file."
    - "The dark-mode primary-as-text contrast regression (17 CSS rules, 6.00:1 -> 2.34:1) is resolved by an explicit recorded developer decision, never by silently re-tuning the winner's hex values or lowering a WCAG floor on the executor's own authority."
  artifacts:
    - "assets/css/app.css — dark daisyUI theme block with 8 changed colour declarations, plus a sketch-054 provenance comment and reconciliation of the in-file comments that state now-false hex values for changed tokens"
    - ".planning/sketches/themes/default.css — both dark regions (the prefers-color-scheme media query and the explicit :root[data-theme=\"dark\"] selector) re-synced, 9 changed declarations each"
  key_links:
    - "app.css `name: \"dark\"` block -> default.css's two dark regions, via the mapping table in default.css's own header, gated end-to-end by check-theme-drift.sh"
    - "app.css dark block tokens -> catalog_show_test.exs's dark_theme_plugin_block()/token_value()/contrast_ratio() gates — those tests parse the real app.css at runtime, so a palette edit is a direct test input, not an unrelated change"
    - "--color-primary as a TEXT colour (17 rules in app.css) -> --color-base-100/200/300 in dark — the seam sketch 054 never composed, and the one this plan must route to a human"
---

<objective>
Ship sketch 054's winning dark theme ("A — Lifted Ladder" base ladder + "W2 — Deep Jewel" primary)
into production by editing `assets/css/app.css`'s `name: "dark"` daisyUI block, then re-synchronise
the sketch-side mirror `.planning/sketches/themes/default.css` and prove zero drift with
`check-theme-drift.sh`.

Purpose: the shipped dark theme reads as too dark (base-100 sat at ~9% lightness with a
near-black-to-near-white text blowout). Sketch 054 tested 5 base hypotheses and 4 primary
candidates over one composed real screen with a live WCAG oracle, and the developer picked A + W2
directly across two rounds. This task moves that validated decision from throwaway sketch into the
real app.

Output: an updated dark theme block, a re-synced sketch theme mirror, a passing drift check, and an
explicit developer decision on the one downstream consequence the sketch did not measure.

**Planning-time finding the executor must not re-litigate.** Sketch 054 composed `--color-primary`
only as a FILL (CTA button background, wordmark, header dot, card-poster gradients) and measured
four pairs, none of which was primary-as-text. The real app also uses `--color-primary` as a TEXT
colour in **17 rules** in `app.css` (nav active/focus states, drawer active links, `.pk-pill-tag`
hashtags, chip focus rings, BGG-note/filter-trigger/share-trigger hovers). Measured against the
winner's own ladder:

| Pair | Before (old palette) | After (winner) | Floor |
|---|---|---|---|
| `--color-primary` on `--color-base-100` | 6.00:1 | **2.34:1** | 4.5:1 |
| `--color-primary` on `--color-base-200` | — | **2.08:1** | 4.5:1 |
| `--color-primary` on `--color-base-300` | — | **1.78:1** | 4.5:1 |

There is an existing shipped test that gates exactly this and **will fail** once Task 1 lands:
`test/pukllay_club_web/live/catalog_show_test.exs:4316` — `".pk-pill-tag's --color-primary text
meets the 4.5:1 contrast floor against --color-base-100 in both themes"`. It is not a flaky or
incidental test; `app.css`'s own comment above `.pk-pill-tag` calls it "the baseline for any future
palette retune", i.e. it is a deliberately-placed tripwire that has now fired as designed.

Every other contrast gate in the suite was recomputed at planning time and **passes** on the new
palette: base-content/base-200 12.07:1 (floor 4.5), neutral-border/base-100 7.00:1 (floor 3.0),
neutral/`--pk-shadow-color` 8.61:1 (floor 3.0, both sides unchanged), neutral-content/neutral
8.45:1 (floor 4.5, both sides unchanged). All four of the sketch's own advertised ratios reproduce
exactly: 13.59 / 7.00 / 12.07 / 6.70.

Task 3 routes the primary-as-text regression to the developer as a blocking decision. The executor
resolves it per the developer's choice and never on its own authority.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/sketches/054-dark-mode-color-composition/README.md
@.planning/sketches/themes/check-theme-drift.sh

Project skill (read before touching theme tokens — it names `assets/css/app.css` as the only file
allowed to declare a `daisyui-theme` block, and locks the theme names to `light`/`dark`):
@.claude/skills/ui-design-system/SKILL.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Apply sketch 054's winner to app.css's dark theme block</name>
  <files>assets/css/app.css</files>
  <action>
Edit ONLY the `@plugin "daisyui/packages/bundle/daisyui-theme"` block whose body starts with
`name: "dark";` (it begins around line 139 and its colour declarations run roughly lines 144-163).
Change exactly these 8 declarations to sketch 054's winning values, preserving the file's existing
uppercase-hex convention and the declaration order already in the block:

| Declaration | From | To | Sketch token |
|---|---|---|---|
| `--color-base-100` | `#170A26` | `#2F154E` | `--color-bg` |
| `--color-base-200` | `#22103A` | `#391B62` | `--color-surface` |
| `--color-base-300` | `#2F1750` | `#462278` | `--color-surface-2` / `--color-border` |
| `--color-primary` | `#A97FD1` | `#8C2BB6` | `--color-primary` |
| `--color-primary-content` | `#170A26` | `#FFFFFF` | `--color-primary-content` |
| `--color-secondary` | `#7E4CA5` | `#642C77` | `--color-secondary` |
| `--color-accent` | `#3D2A56` | `#3A1F47` | `--color-accent-bg` |
| `--color-accent-content` | `#E4D3F5` | `#EBD7F4` | `--color-accent-text` |

Leave every other declaration in the dark block byte-identical, specifically: `--color-base-content`
(`#F3ECFA`), `--color-neutral` (`#B8A6CC`), `--color-error` (`#E06B90`), `--color-success`
(`#5FBE95`), `--color-info`, `--color-warning`, `--color-secondary-content`, all five remaining
`*-content` ink literals, and the whole radius/size/border/depth/noise tail.

Two deliberate non-changes, both decided at planning time — do not "improve" either:

1. `--color-neutral-content`, `--color-info-content`, `--color-success-content`,
   `--color-warning-content` and `--color-error-content` each currently hold the literal that used
   to also be `--color-base-100`. They are ink-on-coloured-chip literals, not references to the
   page ground, and the sketch's 13-token table does not map them. Leaving them alone also keeps
   the neutral-content/neutral gate at its verified 8.45:1. Do not chase them onto the new ladder.
2. `--color-secondary-content` stays `#FFFFFF`; white on the new `#642C77` measures 9.68:1.

Do NOT touch the `name: "light"` block — sketch 054 explicitly revised the dark theme only and
recorded light mode as untouched and not re-examined.

Then reconcile the in-file comments that now state a false hex or ratio for a token you just
changed. These are the sites found by grep at planning time; treat this list as the complete set
and re-grep to confirm before finishing:

- The brand-manual comment immediately above the dark block: its closing line asserts that dark
  mode "lifts primary to L=66%". The winner moves the opposite direction (a deeper, more saturated
  primary with white ink, mirroring the light theme's own `#3D096D` + white convention). Rewrite
  that one line to describe what now ships.
- The comment above `.pk-pill-tag` (around lines 850-859): it records dark primary-on-base-100 as
  6.00:1 and dark secondary-on-base-100 as 3.1:1. On the new palette those are 2.34:1 and 1.62:1.
  Do NOT rewrite this comment in Task 1 — its whole claim is the subject of Task 3's decision.
  Leave it exactly as-is for now so Task 3 has the original tripwire text to work from.
- The comment near line 3553 naming `--color-base-200` as `#22103A`.
- The comment near line 4836 naming the dark pair `#170A26 -> #22103A`.
- The comment near lines 5229-5232 stating dark `--color-base-200` (`#22103A`) against
  `--pk-shadow-color` (`#140822`) measures approximately 1.1:1. On the new palette that pair
  measures 1.39:1 — still far under the 3:1 floor, so the rule's conclusion and the shipped fix are
  unchanged; only the two numbers in the narrative need updating.

For each of those, update the hex and the measured ratio to the real current value. Keep the
surrounding rationale prose intact — these comments are the project's written record of why each
rule exists, and the conclusions all still hold. Where a comment is explicitly historical ("the
failing pair this round replaces"), keep it historical; just make its numbers true.

Finally, add a short provenance comment directly above the dark block recording: sketch 054, winner
"A (Lifted Ladder) + W2 (Deep Jewel)", the date, and the four measured pairs (text/bg 13.59:1,
muted/bg 7.00:1, text/surface 12.07:1, primary-content/primary 6.70:1). Match the house style of
the brand-manual comment already above it — measured constraints stated as numbers, with the
standing instruction not to adjust them by eye.

Do not run `mix quality` in this task; `catalog_show_test.exs:4316` is expected to fail here by
design and is Task 3's subject.
  </action>
  <verify>
    <automated>test "$(awk '/name: "dark";/{f=1} f{print} f&&/^}/{exit}' assets/css/app.css | grep -cE -- '--color-(base-100: #2F154E|base-200: #391B62|base-300: #462278|primary: #8C2BB6|primary-content: #FFFFFF|secondary: #642C77|accent: #3A1F47|accent-content: #EBD7F4);')" = 8 &amp;&amp; test "$(awk '/name: "dark";/{f=1} f{print} f&&/^}/{exit}' assets/css/app.css | grep -cE -- '--color-(base-content: #F3ECFA|neutral: #B8A6CC|error: #E06B90|success: #5FBE95);')" = 4 &amp;&amp; test "$(awk '/name: "light";/{f=1} f{print} f&&/^}/{exit}' assets/css/app.css | grep -cE -- '--color-primary: #3D096D;')" = 1 &amp;&amp; echo "dark=winner 8/8, preserved 4/4, light untouched"</automated>
  </verify>
  <done>
The dark block declares all 8 winner values and still declares the 4 named unchanged tokens; the
light block still declares its own primary. `git diff assets/css/app.css` shows changes confined to
the dark theme block and to comment bodies — no rule declarations elsewhere in the file moved.
  </done>
</task>

<task type="auto">
  <name>Task 2: Re-sync the sketch theme mirror and prove zero drift</name>
  <files>.planning/sketches/themes/default.css</files>
  <action>
`default.css` mirrors app.css's palette for sketches, via the mapping table in its own header. It
carries the dark palette TWICE — once inside `@media (prefers-color-scheme: dark)` on
`:root:not([data-theme="light"])`, and once on `:root[data-theme="dark"]` — and
`check-theme-drift.sh` checks both against app.css AND against each other.

Apply the same 9 value changes to BOTH dark regions, keeping them identical to each other:

| Sketch variable | From | To |
|---|---|---|
| `--color-bg` | `#170A26` | `#2F154E` |
| `--color-surface` | `#22103A` | `#391B62` |
| `--color-surface-2` | `#2F1750` | `#462278` |
| `--color-border` | `#2F1750` | `#462278` |
| `--color-primary` | `#A97FD1` | `#8C2BB6` |
| `--color-primary-content` | `#170A26` | `#FFFFFF` |
| `--color-secondary` | `#7E4CA5` | `#642C77` |
| `--color-accent-bg` | `#3D2A56` | `#3A1F47` |
| `--color-accent-text` | `#E4D3F5` | `#EBD7F4` |

`--color-surface-2` and `--color-border` both map from app.css's single `--color-base-300`, which
is why both take `#462278`.

Leave unchanged in both regions: `--color-text` (`#F3ECFA`), `--color-text-muted` (`#B8A6CC`),
`--color-danger` (`#E06B90`), `--color-success` (`#5FBE95`), and all three `--shadow-*` values. The
shadows are re-based on black deliberately and have no upstream daisyUI counterpart — the drift
script does not check them and the file's own comment explains why they must stay black-based.

Do not touch the `:root` light block, the typography/spacing/shape/motion tokens, the `@font-face`
rules, or anything below them.

Update the dated provenance comment above the first dark region: it currently says the dark palette
was "re-derived 2026-08-21 from assets/css/app.css's shipped dark daisyUI theme block". Extend it
to record that the values were re-derived again from sketch 054's winner, keeping the existing note
about the retired `dark-purple.css` fork intact.
  </action>
  <verify>
    <automated>.planning/sketches/themes/check-theme-drift.sh &amp;&amp; echo "DRIFT CHECK: exit 0"</automated>
  </verify>
  <done>
`check-theme-drift.sh` exits 0. Its output reports OK for all 13 pairs under `== light ==`, OK for
all 13 under `== dark (media-query region) ==`, and OK for all 13 under
`== dark regions agreement ==`. No line in the output contains the word DRIFT.
  </done>
</task>

<task type="checkpoint:decision" gate="blocking">
  <name>Task 3: Decide how to resolve the dark-mode primary-as-text contrast regression</name>
  <files>assets/css/app.css</files>

  <decision>
How should the dark theme handle `--color-primary` used as a TEXT colour, now that sketch 054's
winning primary (`#8C2BB6`) measures 2.34:1 against the new ground instead of the old palette's
6.00:1 — failing the 4.5:1 WCAG AA floor across 17 rules in `app.css`?
  </decision>

  <context>
Sketch 054 composed `--color-primary` only as a FILL — CTA button background, wordmark, header
dot, card-poster gradients — and measured four pairs, none of them primary-as-text. As a fill the
winner is excellent: white-on-primary is 6.70:1, the best margin of any candidate tested across
both rounds. As a text colour on the new ladder it fails everywhere: 2.34:1 on `--color-base-100`,
2.08:1 on `--color-base-200`, 1.78:1 on `--color-base-300`.

The regression is caught by an existing shipped gate — `catalog_show_test.exs:4316`, ".pk-pill-tag's
--color-primary text meets the 4.5:1 contrast floor against --color-base-100 in both themes". This
is not incidental: `app.css`'s own comment above `.pk-pill-tag` records the old ratios and calls
them "the baseline for any future palette retune". The tripwire fired exactly as designed.

Worth noting when weighing the options: the ladder lift alone was not the cause. The OLD primary
`#A97FD1` measures 4.96:1 on the NEW ground — still passing. It is specifically W2's shift toward a
deeper, more saturated jewel tone that breaks primary-as-text. That is the same depth the developer
chose it for, and the same depth that earns it the 6.70:1 white-ink fill margin.

Light mode is unaffected throughout: `#3D096D` on white is 14.4:1.
  </context>

  <options>
    <option id="dark-scoped-token">
      <name>A — Dark-scoped text token for the primary-as-text rules</name>
      <pros>Keeps the winner's palette byte-exact — no part of the two-round decision is reopened. `app.css` already has an in-file precedent for this exact shape: the `.pk-lightbox-close` rule near line 5240 is scoped to dark only, with a written rationale that an invariant rule "would fix the broken theme by degrading the working one". Measured candidates on base-100 all clear the floor comfortably: `--color-base-content` `#F3ECFA` 13.59:1, `--color-accent-content` `#EBD7F4` 11.63:1, `--color-neutral` `#B8A6CC` 7.00:1.</pros>
      <cons>Requires deciding whether all 17 rules share one replacement token or split by the surface each sits on. Swapping primary for a neutral/near-white ink in nav-active and drawer-active states removes the brand colour from the very affordances that use it to signal "you are here" in dark mode.</cons>
    </option>
    <option id="separate-ink-token">
      <name>B — Add a separate dark "primary-as-text" token beside the fill primary</name>
      <pros>Makes the fill-vs-ink split explicit and reusable instead of a per-rule patch, so future rules inherit the right answer by construction. Keeps a violet in the text role rather than falling back to neutral ink — the old `#A97FD1` measures 4.96:1 on the new ground and would still pass.</pros>
      <cons>Adds a token to `app.css`, to `default.css`'s mapping table, and to `check-theme-drift.sh`, whose 13 pairs are hardcoded — the widest blast radius of the four options. Introduces two brand violets in dark mode, which needs its own look at whether they read as intentional rather than as drift.</cons>
    </option>
    <option id="revisit-primary">
      <name>C — Revisit the winner's primary so one value serves both fill and text</name>
      <pros>Restores a single primary that works in every role, which is what every other rule in the file already assumes. The round-2 candidate set is already measured and on record.</pros>
      <cons>Partly reverses a decision already made with the evidence in hand — W1 `#B073D3` and W3 `#BA80DB` were the lighter candidates the developer explicitly passed over in favour of W2's depth, and the stated reason for picking W2 was that the richer, deeper tone read as "warm and professional" where the subtler shift did not. Also gives up the 6.70:1 white-ink fill margin.</cons>
    </option>
    <option id="rescope-gate">
      <name>D — Declare primary-as-text unsupported in dark mode and re-scope the affected rules</name>
      <pros>Names the real constraint directly instead of working around it, and stops the same tripwire firing on every future retune.</pros>
      <cons>Touches the intent of 17 rules rather than one palette value, and means retiring or rewriting a WCAG assertion — the largest change to the project's accessibility contract of the four, and the one hardest to reverse later.</cons>
    </option>
  </options>

  <resume-signal>Select: dark-scoped-token, separate-ink-token, revisit-primary, or rescope-gate — and say which replacement token or hex you want if the choice needs one.</resume-signal>

  <action>
Before presenting the decision, gather the real current evidence rather than trusting this plan's
numbers:

1. Run `mix test test/pukllay_club_web/live/catalog_show_test.exs` and capture the actual failure
   text from the `.pk-pill-tag` contrast test (it prints the measured ratio and both hex values).
2. Run `grep -nE '^\s*color: var\(--color-primary\)' assets/css/app.css` to list every rule that
   uses the primary as a TEXT colour, and note which surface each sits on. Planning-time count was
   17 rules: `.pk-pill-tag`, `.pk-pill-interactive:hover`, `.pk-nav-links a:focus-visible`,
   `.pk-nav-links a[aria-current="page"]`, `.pk-search-morph` toggle focus-within,
   `.pk-filter-trigger:hover`, `.pk-clear-filters-link:hover`, `.pk-nav-crumb a:focus-visible`,
   `.pk-cat-trigger.is-open`, `.pk-cat-item.is-active`, `.pk-bgg-note:hover`, two
   `.pk-drawer-links a[aria-current="page"]` rules, `.pk-chip:focus-visible`,
   `.pk-desc-toggle:focus-visible`, `.pk-bgg-stat:hover`, `.pk-share-trigger:hover`. Confirm the
   count and correct it if the file has moved on.

Then present the four options exactly as written in this task's `<options>` block, alongside the
numbers you just measured. Do not pre-pick one and do not rank them by difficulty — the tradeoff
here is a brand/accessibility judgement, not an engineering-cost judgement.

**Executor constraints — these are absolute:**
- Do NOT change any of the 8 hex values shipped in Task 1 unless the developer explicitly picks
  `revisit-primary`. The palette is a recorded two-round developer decision, not an executor
  variable.
- Do NOT lower, loosen, delete, `@tag :skip`, or otherwise neutralise the 4.5:1 assertion in
  `catalog_show_test.exs` to make the suite green. It is a WCAG AA floor and it fired correctly.
  Only the developer may retire it, and only under `rescope-gate`.
- If the developer's answer is ambiguous, ask again rather than inferring.

After the developer chooses, implement that option, and only then reconcile the `.pk-pill-tag`
comment left untouched in Task 1 so it records the resolution and the new measured numbers —
preserving its role as the tripwire for the next palette retune. If the chosen option adds or
renames a token, update `default.css`'s mapping table and `check-theme-drift.sh`'s pair list to
match, and re-run the drift check.

Record the chosen option, the developer's stated reasoning, and the final measured ratios in the
task summary.
  </action>
  <verify>
    <automated>mix quality &amp;&amp; .planning/sketches/themes/check-theme-drift.sh &amp;&amp; echo "quality + drift check both green"</automated>
  </verify>
  <done>
The developer's chosen option is implemented and named in the summary alongside their reasoning.
`mix quality` passes in full (format, credo --strict, sobelow, and the whole test suite including
every WCAG contrast gate that reads the dark theme block). `check-theme-drift.sh` still exits 0.
The winner's 8 hex values are unchanged from Task 1 unless the developer chose `revisit-primary`.
No WCAG assertion was weakened, skipped, or deleted unless the developer chose `rescope-gate` and
said so explicitly.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| *(none introduced)* | This plan edits two static CSS files. No user input is parsed, no network or database call is added, no dependency is installed, and no template or LiveView handler changes. The existing client-to-server boundaries are untouched. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-quick-260910-efe-01 | Tampering | `assets/css/app.css` dark theme block | low | mitigate | A palette edit can silently degrade a shipped WCAG guarantee — the accessibility analogue of tampering with a security control. Mitigated by the existing computed-contrast gates in `catalog_show_test.exs`, which parse the real file at test time; Task 3 is blocked on `mix quality` passing them, and the plan forbids weakening any assertion to go green. |
| T-quick-260910-efe-02 | Tampering | `.planning/sketches/themes/default.css` | low | mitigate | The sketch mirror silently diverging from the app makes every future sketch preview a lie, which is how the retired `dark-purple.css` fork drifted in 11 of 13 values. Mitigated by `check-theme-drift.sh` gating both Task 2 and Task 3. |
| T-quick-260910-efe-03 | Information Disclosure | — | low | accept | No secret, credential, or user data is touched. No supply-chain surface: zero package-manager installs in this plan, so no legitimacy gate applies. |
</threat_model>

<verification>
1. `.planning/sketches/themes/check-theme-drift.sh` exits 0, reporting OK for all 13 pairs in the
   light region, all 13 in the dark media-query region, and all 13 in the dark-regions-agreement
   sweep.
2. `mix quality` passes end to end.
3. `git diff --stat` lists exactly the two files in `files_modified`, plus any file the developer's
   Task 3 decision required (`check-theme-drift.sh` and/or a test file under Option B or D).
4. Spot-check the running app in dark mode at `/` and `/quienes-somos` — the ground should read
   visibly lifted, the CTA button should carry the deeper magenta-violet with white label text, and
   no text should have become hard to read.
</verification>

<success_criteria>
- Sketch 054's winning dark palette ships in `assets/css/app.css` byte-exact, with light mode
  untouched.
- `.planning/sketches/themes/default.css` mirrors it in both dark regions, drift check green.
- The primary-as-text regression is closed by a recorded developer decision, with `mix quality`
  green and no WCAG floor weakened without an explicit instruction to do so.
- In-file comments that stated a now-false hex or ratio for a changed token tell the truth again.
</success_criteria>

<output>
Create `.planning/quick/260910-efe-implementar-en-assets-css-app-css-el-the/260910-efe-SUMMARY.md` when done.

The summary must record, at minimum: the 8 changed app.css declarations, the Task 3 option the
developer chose with their reasoning, the final measured contrast ratios for every gate that reads
the dark block, and — as an explicit open note for the next palette retune — that the five
`*-content` ink literals were deliberately left on their old value rather than following the new
ladder.
</output>
