---
phase: quick-260910-if9
plan: 01
subsystem: ui
tags: [dark-mode, color, oklch, palette, theme, contrast, css, tdd]

# Dependency graph
requires:
  - phase: quick-260910-hdc
    provides: "--pk-ink-brand theme-scoped token and dark's ink family rotated onto H313.1, the token this task's audit compares the base ladder against"
provides:
  - "oklch-audit.mjs, a reusable zero-dependency Node OKLCh audit script reading assets/css/app.css directly (no palette copy) — reusable for future light/dark hue-family checks"
  - "Dark's --color-base-100/200/300 rotated onto the brand hue (H313.1), closing a 14.6-15.0 degree intra-theme hue split the pill/chip surface inherited from sketch 054"
  - "A new OKLCh tripwire describe block in catalog_show_test.exs extending the existing token_value/oklch_hue/oklch_chroma/contrast_ratio helper set"
affects: [dark-theme-implementation, assets/css/app.css, .planning/sketches/themes/default.css]

# Actuals (#2632)
actuals:
  tokens: 13985
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "OKLCh audit-instrument pattern: a zero-dependency Node script that parses the real upstream palette out of assets/css/app.css (no hardcoded hex copy), converts to OKLCh, and prints a per-tone verdict table plus a SUMMARY of failures — exit-0 always, so it stays usable for exploring candidate palettes before any test/CSS change lands"
    - "Hue-family threshold as a confirmed-by-decision module attribute: Task 1's script proposes a starting threshold with its own justification (light's own worst intra-tone spread); Task 2's developer decision either confirms or revises it before Task 3 encodes it as an ExUnit @module_attribute"

key-files:
  created:
    - .planning/quick/260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs
    - .planning/quick/260910-if9-fix-light-dark-theme-color-family-consis/AUDIT.md
  modified:
    - assets/css/app.css
    - test/pukllay_club_web/live/catalog_show_test.exs
    - .planning/sketches/themes/default.css

key-decisions:
  - "Pick 1 (chip family): C2 — rotate dark's --color-base-100/200/300 onto the brand hue (H313.1), holding each token's own L and C. Picked over C1 (retone the pill surface only via color-mix — narrower blast radius but caps out around a 10-degree residual hue gap before the mix's own contrast margin breaks the 4.5:1 floor) and C3 (equalise the cross-theme relationship via a shared color-mix recipe — structurally symmetric but does not close dark's own internal split, the actual reported defect)."
  - "Pick 2 (label ink): W1 — no change. Measured: dark's label-to-body lightness gap (ΔL 20.1) is already tighter than light's own gap (ΔL 26.9) and the label ink clears 6.85:1 contrast — not a contrast failure. The developer deferred any further label-ink decision until viewing C2's result on the real page."
  - "Hue-family threshold: 8 degrees (Task 1's audit proposal, light's own worst intra-tone spread is .pk-pill-accent at 9.8 degrees), taken as confirmed since Task 2's decision did not contest the number — C2's rotation lands the whole base ladder within ~1 degree of the ink hue regardless, well under any reasonable threshold."

patterns-established:
  - "Sketch 054's four pinned WCAG contrast assertions get a dedicated regression test whenever a future task touches the dark base ladder — this task's C2-only test is the second instance of that pattern (260910-hdc's own describe block re-asserts related but distinct ratios)."

requirements-completed: [QUICK-260910-IF9]

coverage:
  - id: D1
    description: "The detail page's masthead facts pills (players / tiempo / dificultad) read as one hue family across light and dark instead of a pale near-grey lavender in light vs. a saturated purple in dark"
    requirement: QUICK-260910-IF9
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#quick task 260910-if9: dark base ladder rotated onto the brand hue (C2) dark's --color-base-100/200/300 sit within the hue-family threshold of dark's ink (--color-neutral), closing the F1 split (260910-if9 AUDIT.md)"
        status: pass
      - kind: other
        ref: ".planning/quick/260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs"
        status: pass
    human_judgment: true
    rationale: "Automated OKLCh/WCAG assertions confirm the measured hue split closed (15.0 -> 0.4 degrees) and contrast held, but whether the two themes' pills genuinely READ as one colour family to a human eye is a perceptual judgment the plan's own verify step calls for as a two-theme walkthrough. That walkthrough was DEFERRED — see Next Phase Readiness below — this executor cannot render the app in a browser."
  - id: D2
    description: "Dark's secondary/metadata label tier (AÑO / DISEÑADORES / MECÁNICAS / COMUNIDAD BGG) carries the developer's explicitly chosen treatment"
    requirement: QUICK-260910-IF9
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#quick task 260910-if9: dark base ladder rotated onto the brand hue (C2) dark's uppercase/inline label ink rules still read var(--color-neutral) -- W1 (no change) leaves the label tier untouched"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every colour still resolves through a theme CSS custom property; no call site gained a literal colour value; regression is gated by ExUnit OKLCh tripwires extending the existing helper set"
    requirement: QUICK-260910-IF9
    verification:
      - kind: unit
        ref: "mix test test/pukllay_club_web/live/catalog_show_test.exs (191 tests, 0 failures)"
        status: pass
      - kind: other
        ref: ".planning/sketches/themes/check-theme-drift.sh"
        status: pass
      - kind: other
        ref: "mix quality (913 tests, 0 failures; credo --strict, sobelow, hex.audit, deps.audit all clean)"
        status: pass
    human_judgment: false

duration: ~7min (Task 1) + ~1h21m (Task 3, dominated by first-time full mix deps.get/compile in this worktree — no cached _build/deps existed)
completed: 2026-09-10
status: complete
---

# Quick Task 260910-if9: Light/Dark Chip and Label Colour-Family Fix Summary

**Rotated dark's `--color-base-100/200/300` onto the brand hue (H313.1), holding L and C, closing a 14.6-15.0 degree intra-theme hue split between the pill/chip surface and its own ink — developer picked C2 (root-cause fix) over C1/C3, and W1 (no change) for the label-ink question.**

## Performance

- **Duration:** ~7 min (Task 1: audit script + AUDIT.md) + ~1h21m (Task 3: TDD tripwires, CSS rotation,
  sketch resync, quality gates — most of this elapsed time was first-time `mix deps.get`/dependency
  compilation in a fresh worktree with no cached `_build`/`deps`, not active editing)
- **Started:** 2026-09-10T13:22:48-03:00
- **Completed:** 2026-09-10T14:50:50-03:00
- **Tasks:** 3 (Task 1 auto, Task 2 blocking-human decision checkpoint, Task 3 auto/tdd)
- **Files modified:** 5 (2 created in Task 1, 3 modified in Task 3)

## Accomplishments

- Built `oklch-audit.mjs`: a zero-dependency Node script that parses the real light/dark palette
  directly out of `assets/css/app.css` (no hardcoded hex copy), converts to OKLCh using the same
  math already vendored in the ExUnit test helpers, and prints a per-tone (8 pill/chip tones)
  intra-theme hue-spread verdict plus a cross-theme comparison.
- `AUDIT.md`: verbatim script output, findings F1 (dark's 14.6-15.0 degree intra-theme hue split,
  which light never had), F2 (6x cross-theme chroma jump), F3 (dark's label-to-body lightness gap
  is already tighter than light's, not a contrast failure), and six costed options (C1/C2/C3 for
  chip family, W1/W2/W3 for label ink) with real hex/L/C/H/contrast figures.
- Developer decision (Task 2, relayed by the coordinator): **C2 + W1** (see Decisions below).
- TDD: wrote 5 new tests extending the existing OKLCh/contrast helper set, confirmed RED (the
  hue-spread test failed at 15.0 degrees against the unrotated palette — the other 4 tests already
  passed, which is expected since they assert floors/unchanged-state, not a diff), then applied the
  C2 rotation and confirmed GREEN (191/191 tests in the targeted file).
- Rotated `--color-base-100/200/300` in `assets/css/app.css`'s dark `daisyui-theme` block, with a
  provenance comment matching `--pk-ink-brand`'s established density (before/after OKLCh figures,
  the C2 pick, C1/C3 rejected with one-line reasons, W1 recorded for Pick 2).
- Re-synced `.planning/sketches/themes/default.css`'s `--color-bg/-surface/-surface-2/-border` in
  both the `prefers-color-scheme` and explicit `[data-theme="dark"]` regions; `check-theme-drift.sh`
  passes clean.
- Re-ran `oklch-audit.mjs` post-change and appended a "Post-change measurement" section to
  `AUDIT.md` with a before/after summary table.
- Full `mix quality` gate passes: 913 tests, 0 failures; `credo --strict`, `sobelow`, `hex.audit`,
  `deps.audit` all clean (the one pre-existing Credo "software design" suggestion in
  `core_components.ex` and the 5 pre-existing low-confidence Sobelow findings are unrelated to this
  task's files and were not introduced by it).

## Task Commits

Each task was committed atomically:

1. **Task 1: OKLCh audit instrument** — `80df964` (feat)
2. **Task 2: Developer picks the chip-family fix and the label-ink treatment** — decision
   checkpoint, no code commit (C2 + W1, relayed by the coordinator and recorded verbatim below)
3. **Task 3: Apply the chosen values behind OKLCh tripwires, re-sync the sketch mirror, run the
   gates** — two commits following the plan's TDD gate sequence:
   - RED: `e287d3a` (test) — 5 new tripwires, confirmed 1 failure (the hue-spread test) against
     the unrotated palette before any CSS moved
   - GREEN: `054ded5` (feat) — C2 rotation applied, sketch mirror re-synced, AUDIT.md post-change
     section appended, all gates green

**Plan metadata:** pending final docs commit (this SUMMARY.md + STATE.md)

## Files Created/Modified

- `.planning/quick/260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs` - the
  zero-dependency OKLCh audit instrument (Task 1)
- `.planning/quick/260910-if9-fix-light-dark-theme-color-family-consis/AUDIT.md` - findings, costed
  options, and (now) the post-change measurement (Task 1 + Task 3)
- `assets/css/app.css` - dark `--color-base-100/200/300` rotated onto H313.1, holding L and C;
  provenance comment recording the C2/W1 decision
- `test/pukllay_club_web/live/catalog_show_test.exs` - new describe block extending the existing
  OKLCh/contrast helper set with 5 tripwires (hue-family, light-unchanged, WCAG floor, sketch 054's
  four pinned ratios, label-unchanged)
- `.planning/sketches/themes/default.css` - `--color-bg/-surface/-surface-2/-border` re-synced to
  the same three rotated hex values in both dark regions

## Decisions Made

- **Pick 1 (chip family): C2** — rotate dark's `--color-base-100/200/300` onto the brand hue
  (H313.1), holding each token's own L and C:
  - `--color-base-100`: `#2F154E` (L26.8 C0.100 H300.7) -> `#361148` (L26.7 C0.101 H312.4)
  - `--color-base-200`: `#391B62` (L30.7 C0.119 H298.5) -> `#441659` (L30.8 C0.118 H313.1)
  - `--color-base-300`: `#462278` (L35.2 C0.139 H298.1) -> `#531B6D` (L35.2 C0.139 H312.7)
  - Rejected C1 (retone the pill surface only via `color-mix`): narrower blast radius, but the
    hue gap only closes to ~8-10 degrees before the mix's own contrast margin against
    `--color-neutral` drops below the 4.5:1 WCAG floor — does not reach root cause.
  - Rejected C3 (equalise the cross-theme relationship, leave hues alone): makes the two themes
    structurally symmetric but does not close dark's own internal 14.6/15.0-degree split, the
    actual reported defect.
  - Re-verified against sketch 054's four pinned contrast assertions post-rotation: text-on-bg
    13.67:1 (was 13.59:1), muted-on-bg 6.89:1 (was 6.85:1), text-on-surface 12.09:1 (was 12.07:1),
    primary-content-on-primary 6.70:1 (unchanged — primary untouched). All hold at or above their
    pre-rotation margin.
- **Pick 2 (label ink): W1 — no change.** Dark's label-to-body lightness gap (ΔL 20.1,
  `--color-neutral` L75.2 -> `--color-base-content` L95.3) is already tighter than light's own gap
  (ΔL 26.9), and the label ink clears 6.85:1 against `--color-base-100` — not a contrast failure.
  The developer deferred any further label-ink decision until viewing C2's result on the real page.
  `.pk-fact-col dt` / `.pk-bgg-label` / `.pk-bgg-lbl` / `.pk-bgg-foot` are unchanged and pinned by a
  new regression test asserting they still read `var(--color-neutral)`.
- **Hue-family threshold: 8 degrees**, Task 1's audit proposal (light's own worst intra-tone spread
  is `.pk-pill-accent` at 9.8 degrees). Not contested by Task 2's decision, taken as confirmed.

## Audit-Flagged Tones Deliberately Left Alone

Two tones the audit's SUMMARY still lists as intra-theme hue-family failures after C2, both
out of scope for this task and left untouched:

- **`.pk-pill-selected`** (149.8°/136.8° "spread" in light/dark) — a measurement artefact, not a
  real defect: its ink role is `--color-primary-content`, pure white (`#FFFFFF`, C0.000) in both
  themes, and OKLCh hue is mathematically undefined at zero chroma. White-ink-on-solid-fill is a
  deliberate, correct pattern here.
- **`.pk-pill-accent`** (light, 9.9°) and **`.pk-chip.is-active`** (light, 9.9°) — a genuine small
  spread driven by `--color-accent-content` (H300.1) sitting 9.9 degrees from
  `--color-accent`/`--color-primary` fill (H309.9). Neither tone is in Task 2's C1/C2/C3 option set
  (which targets the base-100/200/300-driven tones only) — flagged for visibility, not fixed here.
  A future task could revisit `--color-accent-content` if the developer wants this closed too.

## Deviations from Plan

None - plan executed exactly as written. The plan's Task 3 `<behavior>` section listed W2/W3-only
tests as conditional on the developer's label-ink pick; since W1 (no change) was picked, those
tests were correctly omitted rather than written and skipped — matching the plan's own instruction
("write the ones the picks demand, skip the ones they do not").

## Issues Encountered

- This worktree had no cached `_build`/`deps` directories, so the first `mix test` run required a
  full `mix deps.get` plus fresh compilation of the entire dependency tree (Phoenix, Ecto, Credo,
  Sobelow, Dialyxir, etc.) across both `:test` and `:dev` environments — this dominated Task 3's
  wall-clock time (~1h21m) even though the actual code changes were small. Not a defect in the
  plan or the fix itself, just first-run cost in a fresh worktree.
- Confirmed a genuine TDD RED phase required care: an earlier attempt was contaminated by editing
  `assets/css/app.css` while a background `mix test` run was still mid-compile (the test file's
  `css_source/0` reads the file live via `File.read!` at test-run time, not at compile time). This
  was caught and corrected by explicitly reverting `assets/css/app.css` to HEAD via
  `git checkout -- assets/css/app.css` (a single-file revert, not a destructive workspace-wide
  operation), re-running the full test file to confirm exactly 1 failure (the hue-spread test),
  then reapplying the CSS change via a saved patch.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The C2 rotation is fully applied, gated by 5 new ExUnit tripwires, and verified clean against
  `mix quality`, `check-theme-drift.sh`, and the re-run `oklch-audit.mjs`.
- **Two-theme visual walkthrough: DEFERRED.** The plan's Task 3 `<verify>` includes a
  `<human-check>` ("Walk the game detail page in both themes side by side...") — this executor has
  no browser access and cannot perform it. The developer should view `/catalogo/<juego>` in both
  light and dark theme to confirm the masthead facts pills now read as one hue family before
  considering this task's `D1` coverage item fully closed (see `coverage:` frontmatter above,
  `human_judgment: true`).
- Label-ink question (Pick 2) was explicitly deferred by the developer pending that same
  walkthrough — if the "reads as disabled" perception persists after seeing C2 live, a follow-up
  quick task can revisit W2/W3 using the candidate values already costed in `AUDIT.md`.
- `.pk-pill-selected`'s achromatic-hue false-positive in the audit script's SUMMARY output is
  expected and documented (see AUDIT.md's Findings caveat) — not a regression to chase.
- No blockers.

---
*Phase: quick-260910-if9*
*Completed: 2026-09-10*

## Self-Check: PASSED

All 6 claimed files confirmed present on disk; all 3 claimed task commit hashes (`80df964`,
`e287d3a`, `054ded5`) confirmed present in git history.
