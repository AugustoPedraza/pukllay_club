---
phase: quick-260910-l7q
plan: 01
subsystem: ui
tags: [css, daisyui, oklch, color-tokens, design-system, wcag]

requires:
  - phase: quick-260910-if9
    provides: oklch-audit.mjs's sRGB<->OKLab<->OKLCh math, --pk-ink-brand token
provides:
  - A single shared --pk-ramp-* OKLCh colour ramp (11 stops, H313.1) declared once in
    assets/css/app.css, consumed by both daisyUI theme blocks via var() reads
  - ramp-audit.mjs: a committed, re-runnable ramp generator + role-by-role JOIN/OFF-RAMP audit
  - A hard invariant (catalog_show_test.exs) proving no role can silently drift off the ramp
affects: [any future palette/theme quick task, sketch-findings-pukllay_club theme provenance]

actuals:
  tokens: 17903
  tasks: 5
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Shared OKLCh ramp (Material-3-style tonal palette, Tailwind-numeric stop naming) as the
       single upstream source for daisyUI --color-* tokens, consumed via var() indirection"
    - "One-hop var(--pk-ramp-*) dereference taught to every text-parsing verification gate
       (shell, ExUnit, Node) so a role's colour is enforced to come FROM the ramp, not just
       documented as such"

key-files:
  created:
    - .planning/quick/260910-l7q-redesign-the-light-dark-color-palette-as/ramp-audit.mjs
  modified:
    - assets/css/app.css
    - .planning/sketches/themes/default.css
    - .planning/sketches/themes/check-theme-drift.sh
    - .planning/quick/260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs
    - test/pukllay_club_web/live/catalog_show_test.exs
    - test/pukllay_club_web/motion_rhythm_test.exs
    - test/pukllay_club_web/header_capacity_test.exs

key-decisions:
  - "D1 (Task 3): FLAT envelope (k=0.85), not the plan's recommended ANCHORED — developer chose
     FLAT because it is the only envelope that delivers the true 3-way shared swatch
     (light primary / light accent-content / dark base-200 all -> #45105C); ANCHORED's merged
     L30 stop misses that join by dE 0.0168, just over the 0.012 threshold."
  - "D2 (Task 3): sketch mirror (default.css) keeps resolved hexes, not ramp tokens —
     check-theme-drift.sh's deref helper (added Task 1) resolves upstream's var() reads before
     comparing, so the mirror itself stays plain hex, no build step."
  - "D-InkBrand: --pk-ink-brand's value stays standing (#C791E5), annotated with its nearest
     stop (--pk-ramp-400) rather than folded in, since folding would move an already-approved
     value."
  - "D-Semantics: info/success/warning/error + their -content slots carry no ramp reference,
     grouped under one categorical comment per theme rather than per-role nearest-stop
     annotations, since their exclusion is a policy (other hues), not an audited finding."

patterns-established:
  - "Off-ramp roles annotate their nearest ramp stop + exclusion reason on the line ABOVE the
     declaration (never trailing), so a future red-proof rewrite by exact line shape still finds
     something to mutate."
  - "A text-parsing test/script that assumes 'the first :root block' breaks the moment a second
     plain :root block is introduced — every occurrence found in this codebase now disambiguates
     by CONTENT (presence of a distinguishing declaration), not match order."

requirements-completed: [QUICK-260910-L7Q]

coverage:
  - id: D1
    description: "One-hop var(--pk-ramp-*) indirection proven end-to-end (CSS declaration ->
      compiled output -> all three verification gates) with a two-sided red proof"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs — token_value/2 dereference + ramp_root_block/0"
        status: pass
      - kind: other
        ref: ".planning/sketches/themes/check-theme-drift.sh deref helper, red-proofed against an unresolvable stop"
        status: pass
    human_judgment: false
  - id: D2
    description: "ramp-audit.mjs generates FLAT and ANCHORED 11-stop candidates from the live
      palette and audits every role's JOIN/OFF-RAMP eligibility with ΔE + contrast math"
    verification:
      - kind: other
        ref: "node .planning/quick/260910-l7q-redesign-the-light-dark-color-palette-as/ramp-audit.mjs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Full FLAT ramp written into assets/css/app.css; every JOIN role rewired to
      var(--pk-ramp-*), every OFF-RAMP role annotated with its nearest stop and reason"
    verification:
      - kind: unit
        ref: "mix test test/pukllay_club_web/live/catalog_show_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "Sketch mirror (default.css) resynced to the new resolved hexes; new ExUnit
      describe block locks single-source declaration, no-silent-drift, the shared swatch, and
      ramp monotonicity/gamut-headroom as hard invariants"
    verification:
      - kind: other
        ref: ".planning/sketches/themes/check-theme-drift.sh (39/39 pairs OK)"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs — 'quick task 260910-l7q: shared OKLCh ramp invariants'"
        status: pass
    human_judgment: false
  - id: D5
    description: "Live two-theme (light/dark) visual walkthrough confirming the moved values
      read correctly on real screens"
    verification: []
    human_judgment: true
    rationale: "This executor has no browser/CDP access in this session; contrast is proven by
      arithmetic above, but 'looks right' requires a human (or a future session with browser
      tooling) to actually view both themes live, per this project's human_verify_mode:
      end-of-phase convention and the precedent set by 260910-if9/260910-hdc."

duration: ~90min
completed: 2026-09-10
status: complete
---

# Quick Task 260910-l7q: Shared OKLCh Ramp Summary

**Replaced 16 independently-invented per-theme hexes with one shared, generated 11-stop OKLCh
ramp (`--pk-ramp-50…950`, FLAT envelope, H313.1, k=0.85) that both themes read via `var()` —
7 roles now literally share a physical swatch across the two themes, including the developer's
own "Reservar para el sábado" motivating example (light `primary`/`accent-content` and dark
`base-200` all resolve to the identical `#45105C`), enforced by a hard ExUnit invariant instead
of a comment.**

## Performance

- **Duration:** ~90 min across 5 tasks (2 auto tasks, 1 tracer, 1 blocking-human checkpoint, 1 auto)
- **Tasks:** 5 (Task 1 tracer, Task 2 generator/audit, Task 3 developer checkpoint, Task 4 full
  ramp write, Task 5 sketch sync + invariant lock)
- **Files modified:** 8 (1 created: `ramp-audit.mjs`)

## Task 3 Decisions (recorded verbatim, with the reuse counts they were shown against)

Presented at the checkpoint: `ramp-audit.mjs`'s real output for both FLAT (k=0.85) and ANCHORED
candidates — FLAT: **7 on-ramp, 35 off-ramp, 2 shared stops, 0 broken WCAG floors**; ANCHORED:
**9 on-ramp, 33 off-ramp, 2 shared stops, 0 broken WCAG floors**. Critically, ANCHORED's own
2-shared-stops count did NOT include the 3-way share (dark `base-200` missed the join under
ANCHORED by ΔE 0.0168, just over the 0.012 threshold), while FLAT's did (`stop 900: 3 roles —
light.primary, light.accent-content, dark.base-200`).

**D1 — chroma envelope: FLAT (option B).** Developer's answer, verbatim intent: "FLAT gives the
real motivating outcome... Developer explicitly accepted FLAT's cost — several already-approved
colors... move to OFF-RAMP status or shift by the amounts your audit already reported." This
overrides the plan's own "(A) ANCHORED — recommended" default, specifically because ANCHORED
does not deliver the true 3-way share.

**D2 — sketch mirror form: (i) resolved hexes.** "Do not add ramp tokens to
`.planning/sketches/themes/default.css`... Your existing Task 1 `deref` logic in
`check-theme-drift.sh`... is exactly what makes this work — the mirror itself stays plain hexes."

**k choice within FLAT's 0.85–0.90 sweep:** used k=0.85 (the developer's own message: "unless
your own plan guidance says to pick differently... use your judgment"). 0.85 is the baseline
value `ramp-audit.mjs` reports first and the one already measured against every pinned WCAG
floor in the plan's `<measured_baseline>`; no reason surfaced during the audit to prefer 0.87 or
0.90 (all three sweep values were reported in Task 2's output and are nearly indistinguishable —
ΔC ≤ 0.013 between adjacent k values at every stop).

## The Final 11 FLAT Stops (H313.1, k=0.85)

| stop | L | C | H | hex |
|------|---|---|---|-----|
| 50  | 97.6 | 0.013 | 313.1 | `#FAF5FE` |
| 100 | 95.3 | 0.027 | 313.1 | `#F6EAFD` |
| 200 | 88.9 | 0.065 | 313.1 | `#EACEFA` |
| 300 | 81.4 | 0.113 | 313.1 | `#DCADF6` |
| 400 | 73.9 | 0.163 | 313.1 | `#CE89F3` |
| 500 | 61.0 | 0.258 | 313.1 | `#B739ED` |
| 600 | 50.2 | 0.212 | 313.1 | `#8C2AB7` |
| 700 | 42.7 | 0.180 | 313.1 | `#702093` |
| 800 | 35.2 | 0.149 | 313.1 | `#551670` |
| 900 | 30.6 | 0.129 | 313.1 | `#45105C` |
| 950 | 26.7 | 0.113 | 313.1 | `#380B4C` |

(All 11 values are pure generator output — FLAT hand-nudges nothing, unlike ANCHORED.)

## JOIN Set (7 roles, both themes)

| role | stop | hex | ΔE from shipped |
|------|------|-----|------------------|
| light `--color-base-200` | 100 | `#F6EAFD` | 0.0085 |
| light `--color-primary` (D-HueMove, forced) | 900 | `#45105C` | 0.0382 |
| light `--color-accent-content` (D-HueMove, forced) | 900 | `#45105C` | 0.0382 |
| dark `--color-base-200` | 900 | `#45105C` | 0.0115 |
| dark `--color-base-300` | 800 | `#551670` | 0.0098 |
| dark `--color-base-content` | 100 | `#F6EAFD` | 0.0085 |
| dark `--color-primary` | 600 | `#8C2AB7` | 0.0021 |

**Shared stops:** stop 100 (light base-200, dark base-content); **stop 900 — the headline
result — 3 roles** (light primary, light accent-content, dark base-200), one physical swatch
worn as a light-theme button fill and a dark-theme card surface.

## OFF-RAMP Set (35 roles, with reasons)

**Light (17):** `base-100`/`primary-content`/`secondary-content`/`neutral-content` (achromatic
white — no ramp stop invented for white); `base-300` (chroma tier, ΔE 0.0239); `base-content`
(chroma tier, ΔE 0.0581); `secondary` (chroma tier, ΔE 0.0720); `accent` (chroma tier, ΔE
0.0266); `neutral` (chroma tier, ΔE 0.1462); `pk-ink-brand` (chroma tier, ΔE 0.0382 — this is
the light READ of `--color-primary`, tracked separately from the CSS role); `info`/
`info-content`/`success`/`success-content`/`warning`/`warning-content`/`error`/`error-content`
(D-Semantics — other hues, never join regardless of ΔE).

**Dark (16, excluding `pk-ink-brand` counted above):** `base-100` (chroma tier, ΔE 0.0132);
`primary-content`/`secondary-content` (achromatic white); `secondary` (chroma tier, ΔE 0.0549);
`accent` (chroma tier, ΔE 0.0465); `accent-content` (chroma tier, ΔE 0.0271); `neutral` (chroma
tier, ΔE 0.0635); `neutral-content` (chroma tier, ΔE 0.1041); `pk-ink-brand` (chroma tier, ΔE
0.0324 — nearest stop 400, kept standing per D-InkBrand, NOT folded in); the 8
info/success/warning/error(+content) roles (D-Semantics).

Every off-ramp value carries this same nearest-stop + reason as a one-line comment directly
above its declaration in `assets/css/app.css` (Task 4).

## Before/After Contrast for Every Moved (JOIN) Value

| pair | before | after | floor |
|------|--------|-------|-------|
| light `neutral` on `base-200` | 5.34:1 | 5.31:1 | 4.5 |
| light `primary`/`accent-content` (fill/text) on `base-100`/white | 14.40:1 | 14.17:1 | 4.5 |
| light `accent-content` (ink) on `accent` | 11.46:1 | 11.28:1 | 4.5 |
| dark `neutral` on `base-200` | 6.09:1 | 6.18:1 | 4.5 |
| dark `base-content` (text) on `base-100` | 13.67:1 | 13.61:1 | 4.5 |
| dark `--pk-ink-brand` on `base-200` | 5.72:1 | 5.81:1 | 4.5 |
| dark `--pk-ink-brand` on `base-300` | 4.93:1 | 4.96:1 | 4.5 |
| dark `primary-content` on `primary` | 6.70:1 | 6.71:1 | 4.5 |

**Every pinned WCAG floor holds with margin.** No floor regressed; the ramp cost 0.03–0.29:1 of
margin per pair at most, all still 4.5:1+ above the required floor.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end ramp indirection tracer** — `e73f3f9` (feat)
2. **Task 2: Ramp generator + JOIN/OFF-RAMP audit** — `c3990cf` (feat)
3. **Task 3: Developer decision checkpoint** — no commit (decision only, recorded here)
4. **Task 4: Write the full FLAT ramp and rewire JOIN roles** — `e18c49d` (feat)
5. **Task 5: Sync sketch mirror + lock the on-ramp invariant** — `4663c4f` (test)

_Note: SUMMARY.md and STATE.md are intentionally NOT committed by this executor — the
orchestrator handles that afterward, per explicit instruction._

## Files Created/Modified

- `assets/css/app.css` — the 11-stop `--pk-ramp-*` block; both `daisyui-theme` blocks rewired
  (7 JOIN roles to `var()`, 35 OFF-RAMP roles annotated); `--pk-ink-brand`'s stale contrast
  comment corrected
- `.planning/quick/260910-l7q-redesign-the-light-dark-color-palette-as/ramp-audit.mjs` — new,
  committed, re-runnable ramp generator + audit
- `.planning/quick/260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs` — widened
  to dereference `var(--pk-ramp-*)`, exported its math/parsers for `ramp-audit.mjs` to import,
  guarded its own `main()` behind an entry-point check
- `.planning/sketches/themes/check-theme-drift.sh` — new `extract_ramp_block` + `deref` helper,
  hard-fails on an unresolvable stop
- `.planning/sketches/themes/default.css` — resynced to the FLAT ramp's resolved hexes (D2-i)
- `test/pukllay_club_web/live/catalog_show_test.exs` — `token_value/2` taught the one-hop
  dereference; new `"quick task 260910-l7q: shared OKLCh ramp invariants"` describe block (4
  tests); one existing 260910-if9 test updated to the new (legitimately moved) light base-200 value
- `test/pukllay_club_web/motion_rhythm_test.exs`, `test/pukllay_club_web/header_capacity_test.exs`
  — Rule 1 fixes for a second-`:root`-block regression (see Deviations)

## Decisions Made

See "Task 3 Decisions" above (D1 FLAT, D2 resolved-hexes mirror) — both developer-directed, not
executor discretion. Executor-discretion decisions:

- k=0.85 within the developer-blessed 0.85–0.90 sweep (see above).
- Non-anchor "gap"/"headroom" ramp stops (50, 300, 500, 700) derived by interpolation between
  bracketing anchor lightnesses, except the L≈61 gamut-peak stop, which is FOUND via a
  gamut-chroma-maximizing search rather than interpolated (matches Q3 research's finding that
  sRGB's chroma ceiling at this hue humps around L60).
- `ramp-audit.mjs`'s contrast-pair model is scoped PER THEME to match `<measured_baseline>`'s
  own pinned floor table exactly (e.g. "primary vs base-100" is light-only, since dark's primary
  is a fill only post-260910-gck) — an earlier draft applied pairs symmetrically across both
  themes and produced false "contrast failure" verdicts for dark `primary`; caught and fixed
  before Task 3's checkpoint output was generated.
- Semantic-hue off-ramp roles get ONE grouped comment per theme (not 8 individual nearest-stop
  annotations) since their exclusion is categorical (D-Semantics), not an audited per-role finding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pre-existing test assumed "the first plain `:root` block" — broke 3 times as
`--pk-ramp-*` introduced a second one**
- **Found during:** Task 1 (introduced the ramp's own `:root` block) and Task 4 (expanded it to
  11 stops, triggering 2 more latent instances)
- **Issue:** `app.css` already had ONE plain `:root { ... }` block (carrying `--pk-ink-brand`,
  `--pk-gutter`, motion tokens, etc.). Placing the new ramp `:root` block ABOVE it made three
  separate pre-existing tests — one inline finder in `catalog_show_test.exs`, and one each in
  `motion_rhythm_test.exs` and `header_capacity_test.exs` — silently grab the WRONG `:root`
  block, since each used a first-match `Regex.run`/`Enum.find_value` rather than disambiguating
  by content.
- **Fix:** All three now scan every plain `:root` block and select the one containing a
  distinguishing declaration (`--pk-ink-brand:`, `--duration-fast:`, `--pk-gutter:`
  respectively) — the same content-disambiguation idiom this stylesheet's OTHER multi-`:root`
  tests (e.g. `oklch-audit.mjs`'s `parsePlainRootPkInkBrand`) already used before this task.
- **Files modified:** `test/pukllay_club_web/live/catalog_show_test.exs`,
  `test/pukllay_club_web/motion_rhythm_test.exs`, `test/pukllay_club_web/header_capacity_test.exs`
- **Verification:** Full suite (917 tests) passes; each fix's own test still asserts the same
  underlying fact it always did.
- **Committed in:** `e73f3f9` (1 instance, Task 1), `e18c49d` (2 instances, Task 4)

**2. [Rule 1 - Bug] `--pk-pill-*` fill-vs-border contrast check produced false "DISQUALIFIED"
verdicts on values the live app already ships**
- **Found during:** Task 2, while building `ramp-audit.mjs`'s WCAG floor recheck
- **Issue:** An early draft compared each ROLE_TABLE tone's `fill` against its `border` at a 3:1
  floor. Several tones deliberately set `fill === border` (e.g. `.pk-pill-selected`), which
  reads as 1:1 always — a false failure on a comparison the app never actually makes. Worse, a
  genuine `base-300`-vs-`base-100`/`base-200` "border visibility" pair fails 3:1 in the CURRENTLY
  SHIPPED palette already (unrelated to any ramp candidate), so treating it as a floor
  disqualified every candidate on a constraint the app doesn't enforce today.
- **Fix:** Replaced with an ink-vs-ground check (generalizing the ONE pair actually pinned in
  `catalog_show_test.exs`, `.pk-pill-tag`'s ink-vs-fill text floor) and removed the invented
  border-vs-page check entirely.
- **Files modified:** `.planning/quick/260910-l7q-.../ramp-audit.mjs`
- **Verification:** Re-ran the audit; all 24 ink/ground pairs now correctly report HOLDS for
  both candidates, 0 broken floors.
- **Committed in:** `c3990cf` (Task 2)

**3. [Rule 1 - Bug] "primary vs base-100" contrast pair applied symmetrically to both themes**
- **Found during:** Task 2, same pass as #2
- **Issue:** The same generic pair list applied to both light and dark meant dark's `primary`
  (a fill-only role since 260910-gck moved its outline-CTA text off primary) was wrongly
  evaluated as if it needed to be legible as bare TEXT against dark's own `base-100` — a
  constraint the real app doesn't have (2.35:1 there is fine because nothing renders primary as
  text on the page in dark theme).
- **Fix:** Scoped contrast pairs per theme, matching `<measured_baseline>`'s own pinned floor
  table exactly (light gets `primary`-vs-`base-100` and `neutral`-vs-`base-200`; dark gets
  `neutral`-vs-`base-100` and the `pk-ink-brand` trio).
- **Files modified:** `.planning/quick/260910-l7q-.../ramp-audit.mjs`
- **Verification:** dark `primary` now correctly evaluates JOIN (it was falsely OFF-RAMP before
  this fix) in both FLAT and ANCHORED candidates, matching `<measured_baseline>`'s own
  observation that "dark `--color-primary` ... negligible" ΔE from its nearest candidate stop.
- **Committed in:** `c3990cf` (Task 2)

**4. [Rule 1 - Bug] Ramp stop's near-white top stop failed the 2° hue-tolerance invariant**
- **Found during:** Task 5, writing the ramp-monotonicity/hue tripwire
- **Issue:** `--pk-ramp-50` (`#FAF5FE`, C≈0.013, near-white) measured OKLCh hue 310.5°, 2.6° off
  H313.1 — a real 8-bit hex-quantization artifact, not a genuine hue drift (every OTHER stop,
  C≥0.028, measures within 0.4° of H313.1). Hue is numerically near-undefined as chroma
  approaches zero (`atan2(b, a)` amplifies rounding noise).
- **Fix:** Exempted only stops with C < 0.02 from the hue check, with the measured evidence
  documented inline (not a general escape hatch — the threshold sits precisely between the one
  affected stop and the next-lowest-chroma stop).
- **Files modified:** `test/pukllay_club_web/live/catalog_show_test.exs`
- **Verification:** Test passes; the chroma-ceiling and monotonicity assertions for that same
  stop are UNCHANGED and still enforced.
- **Committed in:** `4663c4f` (Task 5)

---

**Total deviations:** 4 auto-fixed (all Rule 1 — bugs found and fixed inline, none architectural)
**Impact on plan:** All four were necessary for correctness (either a real pre-existing-test
regression from adding a second `:root` block, or a bug in this task's OWN measurement script
that would have shown the developer misleading numbers at the Task 3 checkpoint). No scope creep.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The shared ramp is live, tested, and enforced. A future palette edit that reverts a JOIN role
  to an inline hex, duplicates the ramp, or un-shares the stop-900 swatch will fail
  `mix test` (Task 5's invariant), not just look wrong in review.
- **Deferred (see coverage D5):** a live light/dark browser walkthrough confirming the moved
  values (`#F3ECFA`→`#F6EAFD`, `#3D096D`→`#45105C`, `#441659`/`#531B6D`→`#45105C`/`#551670`,
  `#8C2BB6`→`#8C2AB7`) read correctly on real screens. This executor had no browser/CDP access in
  this session. All moves are sub-0.04 ΔE (imperceptible-to-barely-perceptible under a "just
  noticeable difference" threshold) and every WCAG floor holds with margin, but "looks right" is
  a human judgment this task's own `<verification>` section explicitly defers, matching the
  260910-if9/260910-hdc precedent.
- The 35-role OFF-RAMP set (chroma-tier and D-Semantics exclusions) is fully documented inline
  in `app.css` and in this SUMMARY — a future task widening the envelope (the plan's costed but
  unchosen D1 option C) has a complete, reasoned starting point rather than needing to re-derive
  the audit from scratch.

---
*Phase: quick-260910-l7q*
*Completed: 2026-09-10*

## Self-Check: PASSED

All claimed files found on disk (`assets/css/app.css`, `ramp-audit.mjs`, `default.css`,
`check-theme-drift.sh`, `catalog_show_test.exs`). All claimed commit hashes (`e73f3f9`,
`c3990cf`, `e18c49d`, `4663c4f`) found in `git log --oneline --all`.
