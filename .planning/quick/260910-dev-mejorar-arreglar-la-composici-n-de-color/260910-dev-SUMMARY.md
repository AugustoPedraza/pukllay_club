---
phase: quick-260910-dev
plan: 01
subsystem: ui
tags: [dark-mode, color, palette, theme, contrast, css, sketch, brand]

# Dependency graph
requires: []
provides:
  - "Sketch 054 (.planning/sketches/054-dark-mode-color-composition/) validating a replacement dark-mode palette against the shipped 'too dark' complaint"
  - "Developer-approved 13-token winning palette (base ladder from round 1 + warm primary from round 2), recorded verbatim below and in the sketch's own README"
  - "contrast-check.mjs, a reusable zero-dependency WCAG oracle pattern for future palette-comparison sketches"
  - "One MANIFEST.md row (sketch 054) documenting both decision rounds"
affects: [dark-theme-implementation, assets/css/app.css, .planning/sketches/themes/default.css]

# Actuals (#2632)
actuals:
  tokens: 8965
  tasks: 3
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-frame CSS custom-property overrides for palette-comparison sketches: each `.pk-sk-frame[data-variant=\"X\"]` block declares its full mapped token set directly, shadowing the shared theme via normal custom-property inheritance — no specificity battle, no shared-file edit"
    - "Zero-dependency Node WCAG contrast oracle co-located with the sketch, parsing token values directly out of index.html's own CSS so the on-screen readout and the CLI can never disagree about a variant's values"
    - "Multi-round palette sketches: hold the previously-decided tokens fixed, vary only the specific token set under question this round, and always keep an unchanged 'reference' frame for direct before/after comparison"

key-files:
  created:
    - .planning/sketches/054-dark-mode-color-composition/index.html
    - .planning/sketches/054-dark-mode-color-composition/contrast-check.mjs
    - .planning/sketches/054-dark-mode-color-composition/README.md
  modified:
    - .planning/sketches/MANIFEST.md

key-decisions:
  - "Round 1 (base ladder): Variant A 'Lifted Ladder' wins — bg/surface/surface-2/border raised together (#170A26/#22103A/#2F1750 -> #2F154E/#391B62/#462278), preserving hue/chroma relationship and relative step spacing, picked directly over Control/B (Elevated Surfaces)/C (Quieter Ground)/D (Softened Ink)"
  - "Round 2 (primary warmth, developer-directed follow-up mid-checkpoint): W2 'Deep Jewel' wins — primary shifted from #A97FD1 to a deeper, more saturated magenta-violet #8C2BB6, closer in character to the light theme's own rich #3D096D; flips primary-content from dark ink to white since a primary this deep can't clear 4.5:1 against dark ink, mirroring the light theme's own white-on-deep-primary convention"
  - "Sketch stays throwaway: assets/css/app.css and .planning/sketches/themes/default.css verified byte-identical to pre-task state at every task boundary (git diff --quiet gate + check-theme-drift.sh regression, both passing). Implementing this winner in production is an explicit separate follow-up quick task, not part of this one"
  - "index.html trimmed to the single final winning frame after both decisions landed; all 8 non-winning variants across both rounds (hex values + hypotheses) preserved in README.md, not deleted from the record"

patterns-established:
  - "Palette-comparison sketch mechanic: identical composed-screen markup stamped from one shared JS template string across all frames, so the substrate provably cannot drift between variants — only the wrapping data-variant attribute (CSS token block) and label copy differ"
  - "WCAG oracle contract: exactly N variant blocks parsed from index.html's own CSS, all N declaring the full mapped token set, all required pairs >= 4.5:1, non-reference variants asserted distinct from the reference (dropped once a sketch trims to a single winner)"

requirements-completed: [QUICK-260910-DEV]

coverage:
  - id: D1
    description: "A replacement dark-mode color composition (base ladder + primary/secondary/accent) is validated against the 'too dark' complaint and approved by the developer, with its full 13-token values recorded for the follow-up production implementation task"
    requirement: QUICK-260910-DEV
    verification:
      - kind: other
        ref: ".planning/sketches/054-dark-mode-color-composition/contrast-check.mjs"
        status: pass
    human_judgment: true
    rationale: "Color composition is an inherently perceptual/brand judgment call. The developer already reviewed the rendered sketch and made both decisions live during this session (round 1: Variant A; round 2: W2 Deep Jewel) — recorded here as an already-confirmed decision, not a pending UAT item."

duration: 27min
completed: 2026-09-10
status: complete
---

# Quick Task 260910-dev: Dark Mode Color Composition Summary

**Validated and developer-approved a replacement dark-mode palette (raised base ladder + a deeper, more saturated warm-violet primary with white CTA text) as a throwaway sketch — zero production files touched.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-09-10T12:45:45Z
- **Completed:** 2026-09-10T13:12:57Z
- **Tasks:** 3
- **Files modified:** 4 (3 created, 1 modified)

## Accomplishments

- Built sketch 054: 5 directly comparable dark-mode palette variants over one real composed
  screen (header, real photo, two game cards, accent band, CTA + muted line, footer), each
  declaring its own full 13-token set and its own live-computed WCAG contrast readout.
- Round 1 decision checkpoint: developer picked **Variant A — Lifted Ladder** as the winning base
  bg/surface/surface-2/border ladder, resolving the "is the ground too low, the ladder too flat,
  the bases too chromatic, or the text blowout the problem" question.
- Mid-checkpoint, the developer directed a second round: with A's ladder held fixed, 3 new
  candidates explored a warmer, more saturated primary/secondary/accent set within the existing
  violet brand family (not a hue-family change). Developer picked **W2 — Deep Jewel**.
- Extended `contrast-check.mjs` in place across both rounds to keep gating the live set of
  variants on the same 4.5:1 floor and the same 4 real pairs (text/bg, muted/bg, text/surface,
  primary-content/primary) — never hardcoded, always parsed from the sketch's own CSS.
- Trimmed `index.html` to the single final winning composition once both decisions landed, with
  the full record of every discarded variant (round 1's Control/B/C/D, round 2's A-reference/
  W1/W3) preserved in the sketch's README rather than deleted.
- Recorded the winner's complete 13-token table in README.md and appended one row to
  `MANIFEST.md` documenting both decision rounds.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build sketch 054 — 5 dark palettes over one real composed screen** - `8d678ee` (feat)
   - **Task 1, round 2 (developer-directed mid-checkpoint):** replaced the 5-frame base-ladder set
     with 4 warm-primary candidates on A's chosen ladder - `b575e8a` (feat)
2. **Task 2: Developer picks the winning dark palette** - decision checkpoint, no code commit
   (two rounds resolved live: round 1 = A, round 2 = W2)
3. **Task 3: Record findings — sketch README + MANIFEST row** (also trimmed index.html/
   contrast-check.mjs to the final winner) - `b532c6a` (feat)

**Plan metadata:** pending final docs commit (this SUMMARY.md + STATE.md)

## Files Created/Modified

- `.planning/sketches/054-dark-mode-color-composition/index.html` - 5-frame (round 1) then
  4-frame (round 2) then 1-frame (final) dark-palette comparison over one real composed screen,
  with per-frame token overrides and a live contrast readout
- `.planning/sketches/054-dark-mode-color-composition/contrast-check.mjs` - zero-dependency Node
  oracle asserting per-variant token completeness, WCAG floors, and (during multi-variant rounds)
  non-no-op distinctness from a reference
- `.planning/sketches/054-dark-mode-color-composition/README.md` - frontmatter (sketch/name/
  question/winner/tags) + full two-round design history, the winner's complete 13-token table,
  how-to-view, what-to-look-for
- `.planning/sketches/MANIFEST.md` - one appended row for sketch 054 recording both rounds'
  questions and winners

## Decisions Made

- **Round 1 — base ladder:** Variant A (Lifted Ladder) — raise `bg`/`surface`/`surface-2`/
  `border` together, same hue/chroma relationship and step spacing as today. Picked directly over
  Control (today, reproduced for comparison), B (Elevated Surfaces — keep bg, widen surface
  steps), C (Quieter Ground — pull chroma toward neutral charcoal), D (Softened Ink — keep bases,
  step text/muted/accent instead).
- **Round 2 — primary warmth (developer-directed, requested mid-checkpoint):** W2 (Deep Jewel) —
  primary shifted to a deeper, more saturated magenta-violet closer to the light theme's own rich
  primary, with white `primary-content` (a design branch this depth required, since dark ink can't
  clear 4.5:1 against a primary this saturated). Picked directly over the A reference (today's
  lavender unchanged), W1 (Warm Lift — subtle hue shift, similar brightness), W3 (Warm Bright —
  same hue family, lighter/punchier).
- Production implementation of the winner (editing `assets/css/app.css`'s dark theme block, then
  re-syncing `themes/default.css` and re-running `check-theme-drift.sh`) is explicitly deferred to
  a separate follow-up quick task — not started here.

## Deviations from Plan

### Auto-fixed Issues

None — no Rule 1/2/3 auto-fixes were needed; nothing in this task hit a bug, missing critical
functionality, or a blocking issue.

### Scope Extension (developer-directed mid-checkpoint, not a deviation rule)

The plan's Task 2 checkpoint originally covered only the base-ladder decision (5 variants). Mid-
checkpoint, the coordinator relayed the developer's live decision plus a follow-up request: keep
Variant A's ladder, but explore warmer primary/secondary/accent options. This was executed as an
explicit, developer-authorized in-session extension of Task 2's decision loop — not a Rule 1-4
auto-fix — since it was a direct instruction from the user, not something discovered and resolved
unilaterally. The plan's original scope guard (no production CSS edits, sketch-only) was preserved
throughout both rounds.

---

**Total deviations:** 0 auto-fixed. One developer-directed scope extension (round 2 of the
decision checkpoint), handled as instructed rather than guessed.
**Impact on plan:** No scope creep into production files at any point — verified via
`git diff --quiet -- assets/css/app.css .planning/sketches/themes/` at every task boundary across
both rounds.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The winning 13-token dark-mode palette is fully recorded (this SUMMARY + the sketch's README)
  and ready to be consumed by a follow-up quick task that edits `assets/css/app.css`'s `dark`
  daisyUI theme block, then re-syncs `.planning/sketches/themes/default.css` and re-runs
  `check-theme-drift.sh` to confirm no drift.
- **Winning token table** (verbatim, for that follow-up task):

| Sketch token | Value | Maps to (`assets/css/app.css` daisyUI var) |
|---|---|---|
| `--color-bg` | `#2F154E` | `--color-base-100` |
| `--color-surface` | `#391B62` | `--color-base-200` |
| `--color-surface-2` | `#462278` | `--color-base-300` |
| `--color-border` | `#462278` | `--color-base-300` |
| `--color-text` | `#F3ECFA` | `--color-base-content` |
| `--color-text-muted` | `#B8A6CC` | `--color-neutral` |
| `--color-primary` | `#8C2BB6` | `--color-primary` |
| `--color-primary-content` | `#FFFFFF` | `--color-primary-content` |
| `--color-secondary` | `#642C77` | `--color-secondary` |
| `--color-accent-bg` | `#3A1F47` | `--color-accent` |
| `--color-accent-text` | `#EBD7F4` | `--color-accent-content` |
| `--color-danger` | `#E06B90` | `--color-error` (unchanged from today) |
| `--color-success` | `#5FBE95` | `--color-success` (unchanged from today) |

  Measured contrast: text/bg 13.59:1, muted/bg 7.00:1, text/surface 12.07:1, primary-content/
  primary 6.70:1 — all above the 4.5:1 WCAG AA floor.

- Light mode (`assets/css/app.css`'s `name: "light"` block) was not touched or re-examined in this
  task and needs no follow-up.
- No blockers.

---
*Phase: quick-260910-dev*
*Completed: 2026-09-10*

## Self-Check: PASSED

All 5 claimed files confirmed present on disk; all 3 claimed task commit hashes (`8d678ee`,
`b575e8a`, `b532c6a`) confirmed present in git history.
