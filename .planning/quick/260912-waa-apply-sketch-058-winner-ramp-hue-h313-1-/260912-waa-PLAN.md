---
phase: quick-260912-waa
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
requirements:
  - SKETCH-058-WINNER
files_modified:
  - .planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs
  - assets/css/app.css
  - test/pukllay_club_web/live/catalog_show_test.exs
  - .planning/sketches/themes/default.css
  - lib/pukllay_club/catalog/seed/image_pipeline.ex
  - test/pukllay_club/catalog/seed/og_card_backfill_test.exs

estimate:
  tokens: 70000
  raw_tokens: 70000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "All 11 --pk-ramp-* stops in assets/css/app.css equal sketch 058's winning H300 token set byte-for-byte (#F8F6FE #F1ECFD #DFD3FA #CBB5F6 #B896F3 #9959ED #7B2DCE #6222A6 #4A187F #3C1269 #300D56)"
    - "Dark theme base-100/secondary/accent/accent-content/neutral and dark --pk-ink-brand equal the README's winner column (#2E154E #553384 #33224D #E3D9F9 #B8A0E5 #B797F0)"
    - "Every other chromatic purple literal in BOTH daisyUI theme blocks is hue-rotated to H300 with its own L and C held (light base-300, base-content, warning-content, accent, neutral; dark neutral-content and the four dark semantic -content inks), so both themes share one uniform purple hue"
    - "Light --color-secondary stays exactly #7E4CA5 (the brand manual's Violeta), and the SUMMARY calls this out for the developer to revisit"
    - "Every WCAG contrast pair the palette is gated on still passes (h300-audit.mjs --check exits 0; the sketch 054 pinned floors and catalog_show_test.exs contrast tests stay green)"
    - "Current-state H313.1 provenance comments in app.css now say H300 and cite sketch 058; dated historical UPDATED records stay as history"
    - "The CSS compiles (mix assets.build), the sketch theme mirror matches (check-theme-drift.sh exits 0), and mix test passes"
  artifacts:
    - path: ".planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs"
      provides: "H300 generator + fixed-point/contrast gate (propose mode and --check mode)"
    - path: "assets/css/app.css"
      provides: "H300 ramp, rotated off-ramp roles in both themes, updated provenance comments"
    - path: "test/pukllay_club_web/live/catalog_show_test.exs"
      provides: "@l7q_ramp_hue 300 and updated light base-200/base-300 value assertions"
    - path: ".planning/sketches/themes/default.css"
      provides: "Resolved-hex mirror (D2-i) of the new palette"
    - path: "lib/pukllay_club/catalog/seed/image_pipeline.ex"
      provides: "@og_card_background tracking the new --pk-ramp-600 (#7B2DCE)"
  key_links:
    - from: "assets/css/app.css --pk-ramp-* block"
      to: "catalog_show_test.exs 'shared OKLCh ramp invariants' describe"
      via: "@l7q_ramp_hue module attribute (every stop within 2 degrees of it)"
      pattern: "@l7q_ramp_hue 300"
    - from: "assets/css/app.css theme blocks"
      to: ".planning/sketches/themes/default.css"
      via: "check-theme-drift.sh hex compare (derefs var(--pk-ramp-NNN))"
      pattern: "--color-primary: #7B2DCE;"
    - from: "assets/css/app.css --pk-ramp-600"
      to: "lib/pukllay_club/catalog/seed/image_pipeline.ex @og_card_background"
      via: "comment-documented verbatim copy, pinned by og_card_backfill_test.exs @brand_hex_rgb"
      pattern: "@og_card_background \"#7B2DCE\""
---

<objective>
Apply sketch 058's winner (variant C, ramp hue H313.1 -> H300) to the production palette in
`assets/css/app.css`. Per the developer's instruction to "keep consistency with light version to
uniform color", also rotate the light theme's off-ramp purple roles to H300 so both themes share
one purple hue. `#7E4CA5` (brand Violeta) is the one exception and stays unchanged.

Purpose: dark mode's purple reads fuchsia because the shared ramp sits 13 degrees toward magenta
from the brand manual's Lila Oscuro (#3D096D, H300.1). The developer compared variants
side by side and picked H300.

Output: an H300 audit/gate script, the rotated palette in app.css, updated test pins, the sketch
theme mirror, the OG-card background constant, and H300/sketch-058 provenance comments.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md
@.planning/sketches/058-dark-purple-hue/README.md
@.planning/milestones/v1.0-quick/260910-l7q-redesign-the-light-dark-color-palette-as/ramp-audit.mjs
@.planning/milestones/v1.0-quick/260910-l7q-redesign-the-light-dark-color-palette-as/260910-l7q-SUMMARY.md

<planning_findings>
These were measured during planning with scratch copies of the generator. They are not assumptions.

1. BOTH archived audit scripts are broken in place. The if9 `oklch-audit.mjs` exports
   `APP_CSS_PATH = join(__dirname, "../../../assets/css/app.css")`, which was correct under
   `.planning/quick/` but now resolves to `.planning/assets/css/app.css` because the dir was
   archived one level deeper into `.planning/milestones/v1.0-quick/`. `ramp-audit.mjs` also cannot
   be imported, because it calls `main()` unguarded at the bottom. Do not edit either archived file.

2. Running `ramp-audit.mjs` unmodified with `HUE = 300` does NOT reproduce the README table at two
   stops. It gives stop 500 as `#8D35EA` (README `#9959ED`) and stop 950 as `#310D56` (README
   `#300D56`). Cause: its `buildLadder` recomputes stop 500's L as the gamut peak at the NEW hue
   (L55.3 at H300, versus L61.0 at H313.1). Its stop 950 L comes from the dark base-100 anchor,
   not the shipped stop. The README says the winner kept "same per-stop lightness as the shipped
   H313.1 ramp". Verified: FLAT `C = 0.85 * maxC(L, 300)` evaluated at each SHIPPED stop's own
   OKLCh L reproduces all 11 README stops byte-for-byte. Rotating the six dark roles (L and C
   held, H=300) also reproduces the README's dark column byte-for-byte. Both transforms are fixed
   points: running them on their own output gives the same hexes. The README values are the ones
   the developer actually looked at and picked, so they are authoritative. The shipped-L method is
   how they are reproduced.

3. Expected rotations beyond the README (measured with the same method, L and C held, H=300):
   light base-300 #E3D3F0 -> #DED4F3; light base-content and light warning-content #241238 ->
   #231339; light accent #EDE1F7 -> #E9E2F9; light neutral #6B5B7B -> #675C7D; dark
   neutral-content and dark info/success/warning/error-content #170A26 -> #160A27. Light secondary
   #7E4CA5 measures H308.1 and stays unchanged.

4. Expected contrast after the full change: dark text/bg 13.62 (floor 13.593), muted/bg 6.90
   (6.847), text/surface 12.25 (12.069), white/primary 6.76 (6.696); dark --pk-ink-brand on
   base-100/200/300 6.52 / 5.87 / 5.03; light primary on white 14.16; light neutral on base-200
   5.33; light white/secondary 6.06. All pass.

5. Things that pin the current values and must move together:
   `test/pukllay_club_web/live/catalog_show_test.exs` (`@l7q_ramp_hue 313.1`; a test name
   mentioning H313.1; the ramp-50 hue-noise comment; `token_value(light_block, "--color-base-200")`
   pinned to the old ramp-100 hex; `token_value(light_block, "--color-base-300")` pinned to the old
   light base-300 hex). Also `.planning/sketches/themes/default.css` (the resolved-hex mirror checked
   by `.planning/sketches/themes/check-theme-drift.sh`, which passes today), and
   `lib/pukllay_club/catalog/seed/image_pipeline.ex` `@og_card_background` (documented as a verbatim
   copy of `--pk-ramp-600`) plus its pixel pin `@brand_hex_rgb` in
   `test/pukllay_club/catalog/seed/og_card_backfill_test.exs`. No other lib/, assets/js, or
   priv/static file carries a palette literal. app.css has no `oklch(... 31x)` values.

6. The sketch 054 floors in catalog_show_test.exs (13.593 / 6.847 / 12.069 / 6.696), the 260910-hdc
   2-degree neutral-vs-primary tripwire, and the 260910-if9 8-degree hue-family spread all still
   pass at H300 without edits. Everything moves together (measured spread 299.7-300.0).
</planning_findings>
</context>

<tasks>

<task type="tracer">
  <name>Task 1: Tracer, H300 audit script, then ramp and dark winner roles end to end (CSS, test pin, mirror, build)</name>
  <files>.planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs, assets/css/app.css, test/pukllay_club_web/live/catalog_show_test.exs, .planning/sketches/themes/default.css</files>
  <read_first>
    - .planning/sketches/058-dark-purple-hue/README.md ("Winning token set" tables)
    - .planning/milestones/v1.0-quick/260910-l7q-redesign-the-light-dark-color-palette-as/ramp-audit.mjs (inverse OKLCh math, buildContrastPairs, recheckPinnedFloors)
    - .planning/milestones/v1.0-quick/260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs lines 1-120 and 170-280 (exports: buildPalette, oklab, toOklch, oklchLightness, oklchChroma, oklchHue, contrastRatio, ROLE_TABLE, resolveRoleToken)
    - assets/css/app.css lines 228-380 (ramp :root block and both daisyui-theme blocks) and 600-602 (dark --pk-ink-brand)
    - test/pukllay_club_web/live/catalog_show_test.exs lines 5235-5256 and 5347-5573
    - .planning/sketches/themes/default.css lines 40-60 and 150-190
  </read_first>
  <action>
Step A: create the audit script. Write `h300-audit.mjs` in this quick task's directory as a
zero-dependency Node ES module. It must:
- Import buildPalette, oklab, toOklch, oklchLightness, oklchChroma, oklchHue, contrastRatio,
  ROLE_TABLE and resolveRoleToken from
  `../../milestones/v1.0-quick/260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs`.
  Importing is safe because that file guards its own main with an import.meta.url check.
- Not use that module's exported APP_CSS_PATH, which is stale after archiving (planning finding 1).
  Compute its own path as `join(__dirname, "../../../assets/css/app.css")` from this quick dir.
- Copy these functions from the archived ramp-audit.mjs, with a header comment naming the source
  file and explaining that it cannot be imported because main() is unguarded: oklchToLab,
  labToLinearRgb, linearToSrgbChannel, isInGamut, maxChroma, oklchToHex, deltaE. Use the same
  matrices and the same 40-iteration bisection.
- Declare these constants: HUE = 300; K = 0.85; SKETCH_058_RAMP, the 11 README winner hexes keyed
  by stop; SKETCH_058_DARK, the six README dark roles (base-100, secondary, accent,
  accent-content, neutral, pk-ink-brand); BRAND_VIOLETA for the light secondary, which must stay
  unchanged.
- Derive the ramp with the shipped-per-stop-L method from planning finding 2, NOT ramp-audit's
  buildLadder. For each LIVE `--pk-ramp-N` stop parsed from app.css, compute
  L = oklchLightness(liveHex) and output oklchToHex(L, K * maxChroma(L, HUE), HUE). Put a comment
  on this function explaining why buildLadder is not used (its stop-500 gamut-peak recompute and
  its stop-950 anchor). Note that the transform is a fixed point on its own output.
- Rotate with rotated(hex) = oklchToHex(toOklch(hex).l, toOklch(hex).c, HUE).
- Define the rotation set as explicit role lists. Dark: base-100, secondary, accent,
  accent-content, neutral, neutral-content, info-content, success-content, warning-content,
  error-content, pk-ink-brand. Light: base-300, base-content, warning-content, accent, neutral.
- Exclude these from rotation, with the reason in a comment: #FFFFFF roles (achromatic); the
  info/success/warning/error FILL roles in both themes (D-Semantics, other hues); light secondary
  (brand Violeta); every role that is a `var(--pk-ramp-*)` read (it follows the ramp); and
  `--pk-shadow-color` (a fixed theme-invariant near-black shadow in :root, not a theme role).

Default mode (no flag) is propose. It prints the ramp table (stop, live hex, proposed hex, README
hex, MATCH or DIFF) and the rotation table (theme.role, live hex, live hue, proposed hex, proposed
hue). It exits 1 if any proposed ramp stop or any SKETCH_058_DARK role differs from the README;
otherwise it exits 0.

`--check` mode asserts all of the following, prints every failure, and exits 1 on any failure:
(a) every live ramp stop equals SKETCH_058_RAMP and is a fixed point of the ramp transform;
(b) every role in the rotation set is a fixed point of rotated(), meaning it already sits at H300;
(c) the six SKETCH_058_DARK roles equal the README;
(d) light secondary equals BRAND_VIOLETA;
(e) every contrast pair passes. Port the pair lists from ramp-audit.mjs: buildContrastPairs for
    both themes including every X-content/X pair, the recheckPinnedFloors checks, and the
    ROLE_TABLE ink-on-ground loop, all evaluated on buildPalette(liveCss). Add the four sketch 054
    floors from catalog_show_test.exs: dark base-content/base-100 >= 13.593, neutral/base-100
    >= 6.847, base-content/base-200 >= 12.069, primary-content/primary >= 6.696.

`--check` also prints, informationally, each literal (non-var) purple role's nearest applied ramp
stop, that stop's hex, and the OKLab deltaE to it. Task 3 uses this for the per-role annotations.

Step B: run propose mode against the UNMODIFIED app.css with
`node .planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs`.
It must exit 0 with all 11 stops and all six dark roles MATCH. If anything reads DIFF, STOP: do
not edit app.css, and report the table (orchestrator instruction). Save the output for the
SUMMARY.

Step C: apply the winner values to app.css (values only; comments are Task 3):
- The 11 `--pk-ramp-*` stops in the plain :root block, set to the README's H300 column.
- In the dark daisyui-theme block: --color-base-100 #2E154E, --color-secondary #553384,
  --color-accent #33224D, --color-accent-content #E3D9F9, --color-neutral #B8A0E5.
- In the `:root[data-theme="dark"]` rule: --pk-ink-brand #B797F0.
- Do not change which roles are var(--pk-ramp-*) reads and which are literals. On-ramp and
  off-ramp membership is out of scope, and the l7q allow-list test pins it.

Step D: in catalog_show_test.exs:
- Set `@l7q_ramp_hue` to 300. Extend the comment above it to say sketch 058 / quick task
  260912-waa moved the ramp hue from 313.1 to 300.
- Rename the test "the ramp is a ramp: ... within 2 degrees of H313.1 ..." so it says H300.
- Update the ramp-50 hue-noise comment with the values h300-audit.mjs or a one-off measurement
  reports at H300. Planning measured ramp-50 at C about 0.011, 2.4 degrees off, and every other
  stop within 0.7 degrees. The c >= 0.02 exemption still exempts only ramp-50.
- Change the light `--color-base-200` value assertion to `#F1ECFD`, with the message still naming
  --pk-ramp-100.
- Leave the sketch 054 floor attributes, the 260910-hdc and 260910-if9 thresholds, and all other
  assertions untouched.

Step E: update the resolved-hex mirror `.planning/sketches/themes/default.css`. Per l7q D2-i, keep
plain hexes and add no ramp tokens.
- In BOTH dark regions (the prefers-color-scheme media query and `:root[data-theme="dark"]`):
  --color-bg #2E154E, --color-surface #3C1269, --color-surface-2 #4A187F, --color-border #4A187F,
  --color-text #F1ECFD, --color-text-muted #B8A0E5, --color-primary #7B2DCE,
  --color-secondary #553384, --color-accent-bg #33224D, --color-accent-text #E3D9F9.
- In the light :root region: --color-surface #F1ECFD, --color-primary #3C1269,
  --color-accent-text #3C1269.
- Do NOT touch `.claude/skills/sketch-findings-pukllay_club/sources/themes/default.css`. It is
  already a stale, older copy that the drift gate does not check. Note it in the SUMMARY.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && node .planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs && sh .planning/sketches/themes/check-theme-drift.sh && grep -q '@l7q_ramp_hue 300' test/pukllay_club_web/live/catalog_show_test.exs && grep -q -- '--pk-ramp-500: #9959ED;' assets/css/app.css && grep -q -- '--pk-ink-brand: #B797F0;' assets/css/app.css && mix assets.build && mix test test/pukllay_club_web/live/catalog_show_test.exs</automated>
  </verify>
  <done>h300-audit.mjs exists. Propose mode ran MATCH on all 11 stops and 6 dark roles before any
  edit, and still exits 0 after it. app.css carries the README H300 ramp, the five dark roles and
  dark --pk-ink-brand #B797F0. catalog_show_test.exs pins H300 and the new light base-200 hex, and
  the file passes. The default.css mirror passes check-theme-drift.sh. mix assets.build succeeds.</done>
</task>

<task type="auto">
  <name>Task 2: Rotate the light off-ramp roles and the near-black -content inks to H300 (uniform hue), plus the OG-card background</name>
  <files>assets/css/app.css, test/pukllay_club_web/live/catalog_show_test.exs, .planning/sketches/themes/default.css, lib/pukllay_club/catalog/seed/image_pipeline.ex, test/pukllay_club/catalog/seed/og_card_backfill_test.exs</files>
  <read_first>
    - assets/css/app.css lines 283-380 (both theme blocks, after Task 1)
    - lib/pukllay_club/catalog/seed/image_pipeline.ex lines 38-47
    - test/pukllay_club/catalog/seed/og_card_backfill_test.exs lines 10-14 and 95-105
  </read_first>
  <action>
Step A: take the proposed hexes for the remaining rotation-set roles from h300-audit.mjs propose
mode. Planning finding 3 lists the expected values. If the script disagrees with those values,
use the script's values and record the difference in the SUMMARY. Then edit app.css:
- Light theme block: --color-base-300 -> #DED4F3; --color-base-content -> #231339;
  --color-warning-content -> #231339 (it carries the same literal as base-content today, so it
  moves with it to avoid splitting one ink into two); --color-accent -> #E9E2F9;
  --color-neutral -> #675C7D.
- Dark theme block: --color-neutral-content, --color-info-content, --color-success-content,
  --color-warning-content and --color-error-content -> #160A27.
- Leave light --color-secondary at #7E4CA5 (brand manual Violeta, H308.1, per the sketch 058
  README). Leave all semantic FILL colors (info/success/warning/error), all #FFFFFF roles, and
  --pk-shadow-color unchanged.

Step B: in catalog_show_test.exs, change the light `--color-base-300` value assertion to `#DED4F3`.
Rewrite its failure message so it stays true: the 260910-if9 C2 rotation never touched light, and
quick task 260912-waa later rotated this value to H300 (sketch 058, uniform hue across themes).
Keep the test's name and intent otherwise. Do not edit
`test/pukllay_club_web/header_chip_band_separation_test.exs`. Its hex mentions are a historical
pixel-scan record inside a message string, not an assertion.

Step C: update the default.css light :root region to match: --color-surface-2 #DED4F3,
--color-border #DED4F3, --color-text #231339, --color-text-muted #675C7D,
--color-accent-bg #E9E2F9. --color-secondary stays #7E4CA5.

Step D: the OG card. In image_pipeline.ex, set `@og_card_background` to "#7B2DCE" and update the
comment's verbatim quote of `--pk-ramp-600` to the new hex. That comment currently calls ramp-600
the LIGHT theme's --color-primary, but app.css maps light primary to ramp-900 and dark primary to
ramp-600. Correct that theme label in the comment only. Do not change which stop D-07 uses. In
og_card_backfill_test.exs, set `@brand_hex_rgb` to [0x7B, 0x2D, 0xCE]. Do NOT run the OG-card
backfill or touch R2. Already-uploaded OG cards keep the old letterbox color until a future
backfill run; record that in the SUMMARY.

Step E: run `mix format` on the two .ex/.exs files touched in this task.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && node .planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs --check && sh .planning/sketches/themes/check-theme-drift.sh && grep -q -- '--color-secondary: #7E4CA5;' assets/css/app.css && grep -q '@og_card_background "#7B2DCE"' lib/pukllay_club/catalog/seed/image_pipeline.ex && mix format --check-formatted && mix test test/pukllay_club_web/live/catalog_show_test.exs test/pukllay_club/catalog/seed/og_card_backfill_test.exs</automated>
  </verify>
  <done>Every rotation-set role in both themes is a fixed point at H300, and `--check` exits 0
  with all contrast pairs passing. Light secondary is still #7E4CA5. The mirror matches. The OG
  constant and its pixel pin are #7B2DCE. Both test files pass, and formatting is clean.</done>
</task>

<task type="auto">
  <name>Task 3: Update the provenance comments to H300 / sketch 058, refresh the per-role annotations, and run the full-suite gate</name>
  <files>assets/css/app.css, .planning/sketches/themes/default.css</files>
  <read_first>
    - assets/css/app.css lines 123-380, 539-602, 1155-1170, 1420-1432
    - .planning/sketches/themes/default.css lines 1-20 and 110-150
  </read_first>
  <action>
All edits in this task are to comments. No value changes.

Step A: run `h300-audit.mjs --check` and capture its nearest-stop/deltaE listing and the contrast
ratios. Every number written below must come from that output, rounded to 2 decimals for ratios
and 4 decimals for deltaE. Never estimate a number by eye.

Step B: update these CURRENT-STATE claims in app.css:
1. The `--pk-ramp-*` header comment block, above the ramp :root block:
   - The envelope sentence must read exactly "one fixed hue (H300)".
   - The formula becomes `C = k · maxC(L, H300)`.
   - Add a sentence explaining that sketch 058 (winner C, quick task 260912-waa) rotated the hue
     from 313.1 to 300 and held each stop's lightness from the previous ramp, and that this is
     why stop 500 does not sit at the H300 gamut peak.
   - The headline shared swatch hex becomes --pk-ramp-900 (#3C1269).
   - The "Regenerate and re-audit with" line points to
     `node .planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs --check`.
     Mention that the archived l7q ramp-audit.mjs keeps its H313.1 history.
2. Every `/* off-ramp: nearest --pk-ramp-N (#hex), chroma tier (dE ...) */` annotation in both
   theme blocks: refresh the stop, hex and deltaE from the --check listing. If a role's deltaE is
   now at or below 0.012, do NOT change its on-ramp or off-ramp status. Keep the annotation
   truthful and list the role in the SUMMARY as a candidate for a future join decision.
3. The D-Semantics comments in both theme blocks ("ramp at H313.1") now say H300.
4. The light D-HueMove comment above --color-primary: the ramp now sits at H300, 0.3 degrees from
   the brand manual's Lila Oscuro (#3D096D, H300.1). Say that sketch 058 reversed the original
   13-degree move.
5. The --pk-ink-brand :root comment's current-state sentence "This token is dark's brand hue
   (H313.1)" now says H300. Leave the paragraph that describes the historical 260910-hdc defect
   as history.
6. The dark --pk-ink-brand comment above `:root[data-theme="dark"]`:
   - New value #B797F0 with its measured OKLCh L/C/H.
   - The three MEASURED CONSTRAINTS lines against the new base-100 (#2E154E), base-200 (#3C1269)
     and base-300 (#4A187F).
   - The D-InkBrand nearest-stop reference refreshed from --check.
   - Add a sketch 058 note.
7. The two `.pk-*` comments that say the brand hue is "(H313.1, from `--color-primary`)" (around
   lines 1163 and 1427) now say H300.
8. The brand-manual header comment that calls dark's primary a "deep, saturated magenta-violet"
   now says violet and cites sketch 058.

Step C: append ONE dated paragraph, "UPDATED (quick task 260912-waa, sketch 058, 2026-09-12)", at
the end of the sketch 054 / 260910-hdc / 260910-if9 provenance comment block, just before its
closing `*/`. It must record:
- the ramp hue moved from 313.1 to 300, with per-stop L and k=0.85 held;
- every rotated role, in both themes, with before -> after hexes;
- light secondary #7E4CA5 kept as the brand manual's Violeta;
- --pk-shadow-color deliberately left unchanged, and why;
- the four sketch 054 pinned pairs re-measured, with numbers from --check.
Do NOT rewrite the older dated UPDATED records or their transition figures (for example, the
260910-if9 "-> #361148 (L26.7 C0.101 H312.4)" lines). They are history.

Step D: in default.css, append a "Re-derived (quick task 260912-waa, sketch 058)" note to its
re-derivation comment chain. Summarize the H313.1 -> H300 rotation of the mirrored hexes and note
that the mirror still keeps resolved hexes (D2-i).

Step E: run `grep -n '313' assets/css/app.css`. Sort every remaining hit into historical record
(keep) or current-state claim (fix it). List the kept hits by line in the SUMMARY with a one-word
reason.

Step F: SUMMARY callouts, all required:
(1) #7E4CA5 kept unchanged: the brand Violeta sits at H308.1, 8 degrees off the new uniform hue.
    The developer may want to revisit it.
(2) The generator discrepancy from planning finding 2 and the shipped-per-stop-L method used.
(3) --pk-shadow-color left unchanged (H302.5, L16.9).
(4) Already-uploaded OG cards are not regenerated.
(5) The skill copy of default.css is stale and was left untouched.
(6) The archived if9/l7q audit scripts have broken APP_CSS_PATH resolution after archiving and
    were not modified.
(7) Before/after tables for every changed token and every re-measured contrast pair.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && grep -q 'one fixed hue (H300)' assets/css/app.css && test "$(grep -c 'sketch 058' assets/css/app.css)" -ge 5 && grep -q '260912-waa' .planning/sketches/themes/default.css && node .planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs --check && sh .planning/sketches/themes/check-theme-drift.sh && mix assets.build && mix test</automated>
  </verify>
  <done>The ramp header, per-role annotations, D-Semantics, D-HueMove, --pk-ink-brand (both) and
  .pk-* brand-hue comments describe the H300 palette and cite sketch 058. One dated UPDATED
  paragraph records the full rotation and re-measured pairs, and older history is untouched.
  --check, the drift check, mix assets.build and the full mix test suite all pass.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| none new | Static CSS tokens, test pins, a planning-only Node script, and one compile-time image constant. No new input, endpoint, dependency or secret. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-waa-01 | Tampering (accessibility regression) | assets/css/app.css theme blocks | medium | mitigate | h300-audit.mjs --check fails on any WCAG pair below its floor (all l7q pairs, ROLE_TABLE inks, X-content/X, the sketch 054 floors). catalog_show_test.exs contrast tests stay in the gate. |
| T-waa-02 | Tampering (silent palette drift) | --pk-ramp-* and off-ramp literals | low | mitigate | --check requires README byte equality and H300 fixed-point status for every rotated role. The l7q on-ramp/off-ramp allow-list test and check-theme-drift.sh stay green. |
| T-waa-03 | Repudiation (stale social previews) | Already-uploaded OG cards in R2 | low | accept | Constant updated for future generation only. Backfill deliberately not run. Recorded in SUMMARY. |
</threat_model>

<verification>
- `node .planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs --check` exits 0
- `sh .planning/sketches/themes/check-theme-drift.sh` exits 0
- `mix assets.build` succeeds (the Tailwind + daisyUI theme plugin compiles the new tokens)
- `mix format --check-formatted` clean
- `mix test` passes (includes the catalog_show_test.exs ramp/contrast invariants and og_card_backfill_test.exs)
- Commit only the six files in files_modified plus the SUMMARY. The pre-existing uncommitted
  `ideas.txt` change and the untracked `.planning/quick-batches/` dirs are not part of this task.
</verification>

<success_criteria>
- Both themes' purple tokens sit on one uniform hue, H300 (the brand manual's Lila Oscuro hue).
  The only exception is the brand Violeta #7E4CA5, which is kept and flagged.
- The ramp and dark roles match sketch 058's winning token set byte-for-byte.
- Every gated contrast pair passes, and the full test suite and asset build are green.
- The provenance comments describe the shipped H300 palette and cite sketch 058.
</success_criteria>

<output>
Create `.planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/260912-waa-SUMMARY.md` when done
</output>
