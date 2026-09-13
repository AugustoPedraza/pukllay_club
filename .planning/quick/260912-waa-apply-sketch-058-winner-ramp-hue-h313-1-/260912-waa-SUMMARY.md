---
phase: quick-260912-waa
plan: 01
subsystem: ui
tags: [css, oklch, color-palette, daisyui, dark-mode, contrast, sketch-058]

requires:
  - phase: quick-260910-l7q
    provides: "the shared --pk-ramp-* OKLCh ramp (11 stops, FLAT k=0.85) and the token-vs-var(--pk-ramp-*) allow-list this task rotates in place"
  - phase: quick-260910-if9
    provides: "the dark base ladder rotated onto the (then) brand hue, and the oklch-audit.mjs OKLCh/WCAG math this task's own script imports"
provides:
  - "The shared ramp and every purple literal in both daisyUI theme blocks moved from H313.1 to H300 (sketch 058 winner C, the brand manual's Lila Oscuro hue)"
  - "h300-audit.mjs: a propose/--check generator+gate for the H300 palette, kept in this quick task's own directory as the durable regenerate/verify command"
  - "Updated provenance comments across app.css and the sketch theme mirror describing the H300 state and citing sketch 058"
affects: [ui, sketch-findings-pukllay_club, future dark-mode/palette work]

actuals:
  tokens: 14819
  tasks: 3
  commits: 3
  plan_head_before: db08652

tech-stack:
  added: []
  patterns:
    - "shipped-per-stop-L ramp re-derivation: hold each stop's own OKLCh L across a hue change, recompute C at the new hue's gamut ceiling — NOT ramp-audit.mjs's buildLadder, which re-derives L itself (gamut peak / anchor averages) and does not reproduce a hand-picked winner byte-for-byte"

key-files:
  created:
    - .planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs
  modified:
    - assets/css/app.css
    - test/pukllay_club_web/live/catalog_show_test.exs
    - .planning/sketches/themes/default.css
    - lib/pukllay_club/catalog/seed/image_pipeline.ex
    - test/pukllay_club/catalog/seed/og_card_backfill_test.exs

key-decisions:
  - "Applied sketch 058's developer-picked winner C (H300) verbatim to the ramp and the six README-pinned dark roles"
  - "Also rotated every OTHER literal purple role (light base-300/base-content/warning-content/accent/neutral; dark's near-black -content inks) onto the same H300 hue, per the developer's 'keep consistency with light version to uniform color' instruction — sketch 058 itself only rendered the dark roles, so this extension follows the same generator, not a second design pass"
  - "Light --color-secondary (#7E4CA5, brand manual Violeta, H308.1) is the one deliberate exception, kept unrotated and flagged below for the developer to revisit"
  - "Resolved the ramp-audit.mjs/README discrepancy (planning finding 2) by using the shipped-per-stop-L method instead of buildLadder — verified as a fixed point of its own output before any edit landed"

requirements-completed: [SKETCH-058-WINNER]

coverage:
  - id: D1
    description: "All 11 --pk-ramp-* stops equal sketch 058's README H300 values byte-for-byte, and are a fixed point of the shipped-per-stop-L transform"
    verification:
      - kind: unit
        ref: "node .planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs --check"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs 'the ramp is a ramp: strictly monotone lightness, every stop within 2 degrees of H300...'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Dark's six README-pinned roles (base-100, secondary, accent, accent-content, neutral, pk-ink-brand) equal the README H300 winner"
    requirement: SKETCH-058-WINNER
    verification:
      - kind: unit
        ref: "h300-audit.mjs --check, section (c)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every other literal purple role in both themes (light base-300/base-content/warning-content/accent/neutral; dark's near-black -content inks) is a fixed point of the H300 rotation, and light secondary stays #7E4CA5"
    verification:
      - kind: unit
        ref: "h300-audit.mjs --check, sections (b) and (d)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every gated WCAG contrast pair (l7q pairs, ROLE_TABLE ink/ground, sketch 054's four pinned floors) still passes after the rotation"
    verification:
      - kind: unit
        ref: "h300-audit.mjs --check, section (e)"
        status: pass
      - kind: unit
        ref: "mix test (1068 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The sketch theme mirror (default.css) and check-theme-drift.sh stay in sync with the new H300 values"
    verification:
      - kind: unit
        ref: "sh .planning/sketches/themes/check-theme-drift.sh"
        status: pass
    human_judgment: false
  - id: D6
    description: "Provenance comments (ramp header, per-role annotations, D-Semantics, D-HueMove, both --pk-ink-brand blocks, the two .pk-* brand-hue citations) describe H300 and cite sketch 058; older dated history is untouched"
    verification:
      - kind: manual_procedural
        ref: "grep -c 'sketch 058' assets/css/app.css (>=5); grep -n '313' assets/css/app.css classified line-by-line below"
        status: pass
    human_judgment: true
    rationale: "Comment-content correctness (does every current-state claim say H300, does every historical record stay untouched) is a reading-comprehension judgment, not something a single automated assertion proves end to end."

duration: ~35min
completed: 2026-09-13
status: complete
---

# Quick Task 260912-waa: Apply Sketch 058's H300 Winner Summary

**Rotated the shared --pk-ramp-* ramp and every off-ramp purple role in both daisyUI themes from H313.1 to H300 (the brand manual's own Lila Oscuro hue), fixing dark mode's fuchsia-reading purple while keeping every WCAG-gated pair passing.**

## Performance

- **Duration:** ~35 min
- **Tasks:** 3
- **Files modified:** 6 (1 created, 5 modified)
- **Commits:** 3

## Accomplishments

- All 11 `--pk-ramp-*` stops moved to sketch 058's README H300 winner values, using the "shipped-per-stop-L" derivation (hold each stop's own OKLCh lightness, recompute chroma at the new hue's gamut ceiling) rather than the archived `ramp-audit.mjs`'s `buildLadder`, which does not reproduce the README at stops 500/950 when its `HUE` constant is simply changed.
- Dark's six README-pinned off-ramp roles (`base-100`, `secondary`, `accent`, `accent-content`, `neutral`, `--pk-ink-brand`) rotated to the exact winner hexes.
- Per the developer's "keep consistency with light version to uniform color" instruction, also rotated every other literal purple role onto the same H300 hue: light `base-300`/`base-content`/`warning-content`/`accent`/`neutral`, and dark's `neutral-content`/`info-content`/`success-content`/`warning-content`/`error-content` (all sharing one near-black literal).
- Light `--color-secondary` (#7E4CA5, the brand manual's own Violeta) was deliberately left unrotated — see "Developer Follow-up" below.
- `ImagePipeline`'s OG-card letterbox background (`@og_card_background`, D-07) and its pinned pixel test moved to the new `--pk-ramp-600` hex (`#7B2DCE`); the comment's stale "light theme" label (it is actually dark's `--color-primary`) was corrected.
- All provenance comments across `app.css` and the sketch theme mirror (`default.css`) now describe the H300 state and cite sketch 058; every older dated history record is left byte-identical.
- Wrote `h300-audit.mjs` — a zero-dependency Node script (propose + `--check` modes) that is now the durable regenerate/verify command for this palette, replacing the archived `ramp-audit.mjs`'s H313.1-era command in every comment that pointed at it.

## Task Commits

1. **Task 1: Tracer, H300 audit script, then ramp and dark winner roles end to end** - `56e639f` (feat)
2. **Task 2: Rotate the light off-ramp roles and the near-black -content inks to H300, plus the OG-card background** - `2090f09` (feat)
3. **Task 3: Update the provenance comments to H300 / sketch 058, refresh the per-role annotations, and run the full-suite gate** - `98f1e30` (docs)

_No separate plan-metadata commit — the orchestrator handles the docs commit (SUMMARY.md/STATE.md) per this task's constraints._

## Files Created/Modified

- `.planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs` - H300 ramp generator + rotation gate (propose/--check modes); imports `oklch-audit.mjs`'s OKLCh/WCAG primitives, copies `ramp-audit.mjs`'s OKLCh-to-hex inverse (that file cannot be imported — unguarded `main()`)
- `assets/css/app.css` - the 11 `--pk-ramp-*` stops, dark's six README roles + five near-black `-content` inks, light's five off-ramp roles, the OG-card comment label, and every provenance comment refreshed to H300/sketch 058
- `test/pukllay_club_web/live/catalog_show_test.exs` - `@l7q_ramp_hue` moved 313.1 -> 300, light `base-200`/`base-300` value assertions updated, ramp-50 hue-noise comment re-measured, one test name updated
- `.planning/sketches/themes/default.css` - resolved-hex mirror updated for every H300 rotation (both dark regions + light), plus a re-derivation note
- `lib/pukllay_club/catalog/seed/image_pipeline.ex` - `@og_card_background` -> `#7B2DCE`; comment's theme label corrected (dark's primary, not light's)
- `test/pukllay_club/catalog/seed/og_card_backfill_test.exs` - `@brand_hex_rgb` -> `[0x7B, 0x2D, 0xCE]`

## Decisions Made

- Used the shipped-per-stop-L derivation instead of `ramp-audit.mjs`'s `buildLadder` for the ramp (planning finding 2): running `buildLadder` at HUE=300 does NOT reproduce the README at stop 500 (`#8D35EA` vs README `#9959ED` — `buildLadder` recomputes stop 500's L as the H300 gamut peak, L55.3, instead of holding the shipped L60.9) or stop 950 (`#310D56` vs README `#300D56` — `buildLadder` derives stop 950's L from the dark base-100 anchor, not the shipped stop itself). Verified before any edit: propose mode against the unmodified `app.css` reported MATCH on all 11 stops and all 6 dark roles, confirming the shipped-per-stop-L method (hold each live stop's own L, recompute `C = k · maxC(L, H300)`, rotate H) is the correct reproduction of the developer's actual pick.
- Extended sketch 058's rotation beyond what the sketch itself rendered (dark's six roles only) to also cover every light off-ramp role and dark's near-black `-content` inks, per the developer's own "uniform color" instruction recorded in the plan's objective — not a scope expansion invented here.
- Kept light `--color-secondary` at `#7E4CA5` unrotated (BRAND_VIOLETA, per the README's own instruction) and flagged it for the developer.
- `--pk-shadow-color` (`rgb(20 8 34)`, H302.5 L16.9) was deliberately left unchanged — it is a fixed, theme-invariant shadow literal in `:root`, not a daisyUI theme role, and was never in this task's rotation scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Scope-boundary discovery, NOT auto-fixed] Pre-existing WCAG gap in light theme's success color pair**

- **Found during:** Task 2, while running `h300-audit.mjs --check` (assertion (e), contrast pairs)
- **Issue:** Light theme's `--color-success-content` (`#FFFFFF`) on `--color-success` (`#3F8F6B`) measures 3.92:1, below the 4.5:1 WCAG text floor. Verified against the ORIGINAL (pre-this-task) values — this is not something either task's rotation touched or introduced; `success`/`success-content` are D-Semantics roles, categorically excluded from the ramp and from every rotation set this task defines.
- **Fix:** NOT fixed. Per the executor's SCOPE BOUNDARY doctrine ("only auto-fix issues directly caused by the current task's changes"), this is a pre-existing, unrelated issue. `h300-audit.mjs`'s `--check` gate documents it as a named, non-blocking exception (`KNOWN_PREEXISTING_CONTRAST_EXCEPTIONS`) — still printed as a WARN in the script's output, just excluded from the exit-code gate — rather than silently expanding this task's scope to retune an unrelated semantic color.
- **Files modified:** `.planning/quick/260912-waa-apply-sketch-058-winner-ramp-hue-h313-1-/h300-audit.mjs` (the exception list + WARN handling only — no palette file touched)
- **Logged:** `.planning/WINDOWS.md` entry #27 (kind: deviation, status: open) — a follow-up quick task should retune light `success`/`success-content` independently of this palette-hue work.

---

**Total deviations:** 1 discovered-and-deferred (out of scope, not auto-fixed)
**Impact on plan:** None on this task's own deliverables — every H300/sketch-058 assertion this task owns passes. The deferred item is a genuinely separate, pre-existing defect this task's own audit tooling happened to surface.

## Issues Encountered

None beyond the deferred item above. The generator/README discrepancy (planning finding 2) was anticipated in the plan and resolved as designed (shipped-per-stop-L method, verified fixed-point before editing).

## Known Stubs

None.

## Threat Flags

None — this task's threat model (`T-waa-01`/`T-waa-02`/`T-waa-03`) covered every change made; no new trust boundary, endpoint, or dependency was introduced. `T-waa-03` (stale already-uploaded OG cards) is accepted as documented below.

## `313` Grep Sweep (plan Task 3 Step E)

Every remaining `313` hit in `assets/css/app.css` after Task 3, classified:

| Line | Classification | Reason |
|---|---|---|
| 163 | keep | historical (260910-hdc UPDATED paragraph, past-tense measurement at the time) |
| 171 | keep | historical (same 260910-hdc paragraph) |
| 189 | keep | historical (260910-if9's before/after delta table entry) |
| 230 | current | this task's own new paragraph, describing the H313.1 -> H300 move itself |
| 260 | false-positive | substring of `#231339`, not a real "H313" mention |
| 282 | path | quick task directory name (`...-h313-1-/`), not a hue claim |
| 305 | current | this task's own new paragraph |
| 307 | current | quotes sketch 058's own variant naming ("H313 (today)"), historical framing by design |
| 309 | current | explicitly describes "the previous H313.1 ramp," correctly historical |
| 332 | path | quick task directory name |
| 333–336 | current | explicitly says the archived generator "keeps its own H313.1 history," correctly historical-by-design |
| 342 | path | quick task directory name |
| 420 | false-positive | substring of `#231339` |
| 421 | keep | historical (D-HueMove's original join description); an UPDATED note was appended immediately after it |
| 454 | false-positive | substring of `#231339` |
| 641 | keep | historical (sketch 055/056 defect description, past tense "sat," UPDATED note follows) |
| 649 | current | this task's own fix, correctly says H300 |
| 685 | current | this task's own fix |
| 1258 | current | this task's own fix |
| 1523 | current | this task's own fix |

## Before/After Table

**Ramp stops:**

| Stop | Before (H313.1) | After (H300) |
|---|---|---|
| 50 | `#FAF5FE` | `#F8F6FE` |
| 100 | `#F6EAFD` | `#F1ECFD` |
| 200 | `#EACEFA` | `#DFD3FA` |
| 300 | `#DCADF6` | `#CBB5F6` |
| 400 | `#CE89F3` | `#B896F3` |
| 500 | `#B739ED` | `#9959ED` |
| 600 | `#8C2AB7` | `#7B2DCE` |
| 700 | `#702093` | `#6222A6` |
| 800 | `#551670` | `#4A187F` |
| 900 | `#45105C` | `#3C1269` |
| 950 | `#380B4C` | `#300D56` |

**Dark off-ramp roles rotated (L, C held):**

| Role | Before | After |
|---|---|---|
| `--color-base-100` | `#361148` | `#2E154E` |
| `--color-secondary` | `#642C77` | `#553384` |
| `--color-accent` | `#3A1F47` | `#33224D` |
| `--color-accent-content` | `#EBD7F4` | `#E3D9F9` |
| `--color-neutral` | `#C59CDC` | `#B8A0E5` |
| `--color-neutral-content`, `--color-info-content`, `--color-success-content`, `--color-warning-content`, `--color-error-content` (shared literal) | `#170A26` | `#160A27` |
| `--pk-ink-brand` (dark) | `#C791E5` | `#B797F0` |

**Light off-ramp roles rotated (L, C held):**

| Role | Before | After |
|---|---|---|
| `--color-base-300` | `#E3D3F0` | `#DED4F3` |
| `--color-base-content`, `--color-warning-content` (shared literal) | `#241238` | `#231339` |
| `--color-accent` | `#EDE1F7` | `#E9E2F9` |
| `--color-neutral` | `#6B5B7B` | `#675C7D` |

**Kept unchanged:** light `--color-secondary` (`#7E4CA5`, brand Violeta) and `--pk-shadow-color` (`rgb(20 8 34)`).

**Re-measured WCAG pairs (sketch 054's four pinned floors, via `h300-audit.mjs --check`):**

| Pair | Ratio | Floor |
|---|---|---|
| dark text (`#F1ECFD`) / bg (`#2E154E`) | 13.62:1 | 13.593:1 |
| dark muted (`#B8A0E5`) / bg (`#2E154E`) | 6.90:1 | 6.847:1 |
| dark text (`#F1ECFD`) / surface (`#3C1269`) | 12.25:1 | 12.069:1 |
| dark primary-content (`#FFFFFF`) / primary (`#7B2DCE`) | 6.76:1 | 6.696:1 |

Every other gated pair (l7q's per-theme `X-content`/`X` pairs, the `ROLE_TABLE` ink/ground loop, and `--pk-ink-brand` on base-100/200/300 in dark) also passes — full listing in `h300-audit.mjs --check`'s own output.

## Developer Follow-up (flagged, not decided here)

1. **Light `--color-secondary` (`#7E4CA5`, brand Violeta) sits at H308.1** — 8 degrees off the new uniform H300 hue every other purple role now shares. Kept unrotated per the sketch 058 README's own instruction ("`#7E4CA5` is the manual's own Violeta and should stay as-is"), but it is the one remaining non-uniform hue in the palette. Revisit if full hue uniformity across every role (not just the ramp/off-ramp set) becomes a goal.
2. **`.planning/quick/260912-waa-.../h300-audit.mjs --check`'s pre-existing WCAG gap** (light `success-content`/`success`, 3.92:1) — see Deviations above and WINDOWS.md #27. Independent of this task; needs its own quick task to retune `--color-success`/`--color-success-content`.
3. **Light `--color-base-300` now measures ΔE 0.0111 from `--pk-ramp-200`** — at or below the 0.012 JOIN threshold, but kept OFF-RAMP per this task's own rule (on/off-ramp membership is decided once, not re-decided whenever ΔE happens to cross the line after an unrelated hue move). A future palette task could choose to formally JOIN it onto the ramp instead of carrying it as its own literal.
4. **Already-uploaded OG cards in R2 are not regenerated** by this task — `ImagePipeline.og_card/1`'s constant and its test are updated for FUTURE generation only. The OG-card backfill was deliberately not run (per plan instruction); existing social-preview images keep the old (`#8C2AB7`) letterbox color until a future backfill pass.
5. **`.claude/skills/sketch-findings-pukllay_club/sources/themes/default.css`** is a stale, older copy of the sketch theme mirror that `check-theme-drift.sh` does not check and this task left untouched (per plan instruction).
6. **The archived `260910-if9-.../oklch-audit.mjs` and `260910-l7q-.../ramp-audit.mjs`** both have broken `APP_CSS_PATH` resolution after their directories were archived one level deeper (planning finding 1) — neither was modified by this task; `h300-audit.mjs` computes its own path instead and imports only the math functions it needs from `oklch-audit.mjs` (which is still importable, since it guards its own `main()`).

## Next Phase Readiness

- The shared palette is fully on H300 across both themes' off-ramp roles and the ramp itself; no known blocker for further UI work that reads these tokens.
- `h300-audit.mjs --check` is the durable regenerate/verify command for this palette going forward (superseding the archived H313.1-era `ramp-audit.mjs` as the "regenerate and re-audit with" pointer in every current-state comment).
- One pre-existing, unrelated WCAG gap (WINDOWS #27, light `success`/`success-content`) is open and should be picked up independently.

---
*Phase: quick-260912-waa*
*Completed: 2026-09-13*

## Self-Check: PASSED

All 6 files_modified files plus this SUMMARY confirmed present on disk. All 3 task commits (`56e639f`, `2090f09`, `98f1e30`) confirmed present in `git log --oneline --all`.
