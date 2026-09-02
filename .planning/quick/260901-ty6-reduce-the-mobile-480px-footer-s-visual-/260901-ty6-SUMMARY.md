---
phase: quick-260901-ty6
plan: 01
subsystem: ui
tags: [phoenix-liveview, css-custom-properties, mobile-footer, type-inventory, cdp-measurement]

requires:
  - phase: quick-260823-snj
    provides: "D-A/D-B footer brand demotion (mark={false}, .pk-brand-quiet colour-only demotion) — this plan adds a scoped SIZE exception on top of it"
  - phase: quick-260824-i8e
    provides: "removed the catalog page's only native <select>, which is what made the ui-design-system inventory table's '16px Inter / accepted exception' row stale"
provides:
  - "--pk-footer-offset/--pk-footer-pad-block tokens, declared once on the base .pk-footer rule and retuned in the existing ≤480px block, cutting mobile footer vertical chrome from 96px to 56px"
  - "≤480px .pk-brand-quiet .pk-brand-name font-size (1.25rem/20px) — a scoped, documented SIZE exception to D-B, footer-only, header wordmark untouched"
  - "≤480px .pk-footer-links font-size (0.875rem/14px) + --pk-footer-gap-list retune (0.75rem), restoring item < list < group <= cluster on mobile"
  - "corrected ui-design-system inventory table row (stale native-<select> row was actually the footer nav links all along)"
affects: [mobile-footer, ui-design-system-skill, catalog-index-type-inventory]

actuals:
  tokens: 7464
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Chrome-shape ratio guard pattern (from footer_rhythm_test.exs) extended to a fourth spacing tier (list) and a new vertical-chrome token pair — read effective ≤480px values with base-block fallback, compare numerically rather than hardcoding, so future retunes stay green as long as direction/order holds"
    - "Off-canvas panel exclusion for live type-inventory measurement: `.pk-drawer`/`.pk-sheet` keep `display:flex/block` at some widths and move off-canvas via `transform`, so `el.getClientRects().length > 0` alone is insufficient — must also exclude descendants of a closed `.pk-drawer`/`.pk-sheet` to match what a user actually sees"

key-files:
  created: []
  modified:
    - assets/css/app.css
    - lib/pukllay_club_web/components/layouts.ex
    - test/pukllay_club_web/footer_rhythm_test.exs
    - .claude/skills/ui-design-system/SKILL.md

key-decisions:
  - "Two new tokens (--pk-footer-offset, --pk-footer-pad-block) declared once in the base .pk-footer rule, consumed by .pk-footer's margin-top and .pk-footer-row's padding-top/bottom, following the exact declare-once/retune-at-≤480px contract the four --pk-footer-gap-* tiers already use — no parallel literal introduced."
  - "main.pk-boundary-collapse + .pk-footer's 1.5rem margin-top literal (the closed sketch-035 detail-page decision) was deliberately left untouched, not converted to the new token — the mobile default (1.5rem) was chosen to coincide with it by intent, not by a shared declaration, so a future mobile retune cannot silently move an independently-made decision."
  - "The footer wordmark shrink (1.5rem -> 1.25rem) is a documented SIZE exception to D-B ('demotion is by colour, not size'), scoped to .pk-brand-quiet .pk-brand-name inside the ≤480px block only — an unlayered CSS rule intentionally beating the markup's layered text-2xl utility, following the .pk-nav-inner .pk-brand-wordmark precedent already in the file's CASCADE-LAYER HAZARD note."
  - "min-h-11 was NOT removed from brand_logo/1's anchor — the lockup's natural height is already under 44px at the shrunk size, so the touch floor (not the type) sets the box; the footer's height win comes entirely from Task 1's margin/padding retune, not from the wordmark shrink."
  - "The catalog page's own native <select> was removed by an earlier quick task (260824-i8e); the ui-design-system inventory table's '16px Inter / accepted exception / native select' row was therefore stale. Live re-measurement found its real (mislabelled) source was always .pk-footer-links a — corrected in the table rather than silently left wrong."
  - "0.875rem (14px) chosen for .pk-footer-links over inventing a new size: it lands the links on the screen's existing plain-body tier (Inter/14px/400), confirmed live to be weight 400 (not the 600-weight semibold tier initially assumed in a draft comment, corrected before commit)."

patterns-established:
  - "A mobile-scoped exception to an existing design rule (D-B colour-not-size) is documented on BOTH the original rule's comment (non-destructively appended) and the new exception's own comment, each stating the other's continued validity at the unaffected breakpoint."

requirements-completed: [SHELL-01]

coverage:
  - id: D1
    description: "Base .pk-footer rule declares --pk-footer-offset/--pk-footer-pad-block; margin-top and .pk-footer-row's padding-top/bottom read the tokens (no bare literals); ≤480px block retunes both strictly downward with a non-zero offset"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/footer_rhythm_test.exs#the mobile footer spends less vertical chrome than the desktop one"
        status: pass
      - kind: other
        ref: "scratchpad CDP measurement (not committed): 390px footerMarginTop 48px->24px, rowPaddingTop/Bottom 24px->16px; 768px byte-identical before/after (48px/24px/24px)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Footer wordmark shrinks to 20px at ≤480px, scoped through .pk-brand-quiet (header wordmark untouched); tagline stays 12px; no banned 10px/0.625rem reintroduced; .pk-footer-links shrinks to 14px and --pk-footer-gap-list retunes to 0.75rem restoring item<list<group<=cluster; brand anchor keeps min-h-11"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/footer_rhythm_test.exs#mobile-scoped ink and density: wordmark, links, and list gap"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/stylesheet_integrity_test.exs, test/pukllay_club_web/footer_overflow_test.exs, test/pukllay_club_web/header_row_height_test.exs"
        status: pass
      - kind: other
        ref: "scratchpad CDP measurement (not committed): 390px wordmark 24px->20px, links 16px->14px, gap 16px->12px, brand anchor height 48px->44px (min-h-11 floor still binds); 768px byte-identical before/after"
        status: pass
    human_judgment: false
  - id: D3
    description: "≤480px type inventory re-measured live via CDP and ui-design-system/SKILL.md updated: new footer-scoped Bebas Neue/20px/400 combo recorded, stale native-<select> row corrected to its real source (.pk-footer-links), combo count updated (6 at ≤480px, 5 at ≥481px, unchanged from baseline)"
    requirement: SHELL-01
    verification:
      - kind: other
        ref: ".claude/skills/ui-design-system/SKILL.md Type hierarchy section, updated 2026-09-01; scratchpad CDP inventory script (not committed)"
        status: pass
    human_judgment: false
  - id: D4
    description: "At a real ≤480px viewport the footer no longer reads as the heaviest block on the page, stays visibly separated from content above it, the brand lockup reads as demoted rather than cramped, and the nav links stay comfortably tappable"
    verification: []
    human_judgment: true
    rationale: "Plan's own Task 3 verify lists this as a <human-check> (visual/subjective read of 'heaviest block'/'cramped vs demoted'), not an automated assertion. The CDP measurements above numerically substantiate every claim (40px/41.7% chrome reduction, non-zero separating margin, 44px touch floor intact, links readable at 14px) but a human eyeballing the real phone-width render is the plan's own designated oracle for this specific deliverable."
    files:
      - assets/css/app.css

duration: 25min
completed: 2026-09-01
status: complete
---

# Quick Task 260901-ty6: Reduce Mobile ≤480px Footer Visual Weight Summary

**Tokenized the footer's vertical chrome and retuned it downward at ≤480px (96px → 56px), added a scoped size exception shrinking the footer wordmark and nav links, and corrected a stale row in the ui-design-system type inventory — all proven with live before/after CDP measurements at 390px and 768px.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-09-01T21:44:00-03:00 (approx.)
- **Completed:** 2026-09-01T22:09:05-03:00
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `--pk-footer-offset`/`--pk-footer-pad-block` tokens to the base `.pk-footer` rule (declared once, consumed by `.pk-footer`'s `margin-top` and `.pk-footer-row`'s `padding-top`/`padding-bottom`), retuned downward in the existing ≤480px block: mobile footer's own top margin 48px→24px, row padding 24px→16px each side.
- Shrunk the footer wordmark to 20px (`.pk-brand-quiet .pk-brand-name`, ≤480px only) — a documented, scoped SIZE exception to the D-B "demotion is by colour, not size" rule, with the header's own wordmark completely untouched.
- Shrunk `.pk-footer-links` to 14px and retuned `--pk-footer-gap-list` to 0.75rem at ≤480px, restoring the item < list < group <= cluster tier order the mobile scale had lost (list and group had collapsed onto the same 1rem value).
- Live CDP-measured the change at 390px (mobile) and 768px (desktop control) before and after: desktop is byte-identical on every captured value; mobile's total footer chrome dropped from 96px to 56px (-41.7%), while the footer's own background/border separation and a non-zero 24px margin keep it visibly separated from the content above.
- Re-measured the catalog page's ≤480px type inventory live and updated `.claude/skills/ui-design-system/SKILL.md`: found and recorded the new footer-scoped Bebas Neue/20px/400 combo, and — as a byproduct of the re-measurement — discovered and corrected a stale table row ("16px Inter / accepted exception / native `<select>`") whose real source turns out to have always been the footer nav links, since the catalog's only native `<select>` was removed by an earlier quick task (260824-i8e).

## Task Commits

Each task was committed atomically:

1. **Task 1: Tokenize the footer's vertical chrome and retune it at ≤480px** - `0f00940` (feat)
2. **Task 2: Mobile-scoped ink and density pass** - `9662fbe` (feat)
3. **Task 3: Prove it at 390px, re-measure the type inventory, close the docs** - `ed51bab` (docs)

## Files Created/Modified

- `assets/css/app.css` — two new `--pk-footer-*` chrome tokens + retune; footer wordmark and links mobile font-size rules; `--pk-footer-gap-list` mobile retune; comment updates/reconciliation across all touched regions
- `lib/pukllay_club_web/components/layouts.ex` — `brand_logo/1`'s `@doc` and the `mark` attr doc amended to name the new ≤480px size exception
- `test/pukllay_club_web/footer_rhythm_test.exs` — two new describe blocks (chrome tokens, mobile ink/density), every assertion verified RED against the pre-change stylesheet first
- `.claude/skills/ui-design-system/SKILL.md` — re-measured type-inventory table, new footer combo recorded, stale row corrected

## Decisions Made

- Tokens declared once in the base `.pk-footer` rule, retuned only in the existing single `@media (max-width: 480px)` block — no parallel literal, no second media block, matching the file's own established contract for the four `--pk-footer-gap-*` tiers.
- `main.pk-boundary-collapse + .pk-footer`'s `margin-top: 1.5rem` literal (closed sketch-035 detail-page decision) deliberately left untouched rather than converted to the new token, with an explicit comment on why the values are meant to coincide by intent, not by shared declaration.
- Footer wordmark shrink is an ink change, not a box change: `min-h-11` stays on the brand anchor since the lockup's natural height is already under 44px at the smaller size — the touch floor, not the type, sets the box.
- `.pk-footer-links` lands at 0.875rem/14px, weight 400 — placed on the screen's existing plain-body type-inventory row (Inter/14px/400) rather than inventing a new combo; a draft comment initially (incorrectly) referenced the 600-weight semibold-emphasis tier and was corrected before commit after live-measuring the actual computed weight (400).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed anchored regex bug in a newly-written test assertion**
- **Found during:** Task 2 verification run
- **Issue:** The new `.pk-footer-links` font-size test used `~r/(?m)^\.pk-footer-links\s*\{/`, which requires the selector at column 0 — but the rule lives indented inside the `@media` block, so the assertion failed for the wrong reason (a test bug, not a CSS bug) even after the correct CSS was written.
- **Fix:** Removed the `(?m)^` anchor, matching the un-anchored pattern `narrow_footer_block/1` already uses for the same media-block context.
- **Files modified:** test/pukllay_club_web/footer_rhythm_test.exs
- **Verification:** Full suite re-run, 118/118 passing.
- **Commit:** 9662fbe (Task 2 commit)

**2. [Rule 1 - Bug] Corrected stale ui-design-system inventory row discovered during live re-measurement**
- **Found during:** Task 3, live CDP inventory sweep
- **Issue:** The table's "16px Inter / accepted exception / native `<select>`" row no longer had a real source — quick task 260824-i8e removed the catalog page's only `<select>` on 2026-08-24, three days before the row's dated measurement was even taken, so the table had been silently describing a removed element. Live identification traced the actual 16px/400 elements to `.pk-footer-links a` (FAQ/Contacto/Juntadas).
- **Fix:** Corrected the row's Source/Tier framing in the table to name the footer links as the real (and now-retuned) source, and reconciled the `.pk-footer-links` app.css comment (which had also mis-cited the 600-weight tier) to the measured 400-weight body tier.
- **Files modified:** .claude/skills/ui-design-system/SKILL.md, assets/css/app.css
- **Verification:** Live CDP re-measurement confirmed no native `<select>` renders on the page in any measured state; `.pk-footer-links a`'s computed weight is 400 at both 16px (before) and 14px (after).
- **Commit:** ed51bab (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 bug fixes — one test-authoring bug, one stale-documentation bug surfaced by the task's own required re-measurement step).
**Impact on plan:** Both fixes were necessary for the plan's own stated correctness bar (accurate assertions, an inventory table that doesn't assert something the code no longer does). No scope creep — the second fix stayed inside the exact file the plan already required touching (SKILL.md) and the exact rule the plan already required touching (`.pk-footer-links`).

## Issues Encountered

- The scratchpad CDP measurement script initially over-counted the type inventory: `.pk-drawer`/`.pk-sheet` (off-canvas panels) keep `display: flex`/`block` at ≤480px and only move off-screen via `transform`, so a strict `display !== 'none'` filter (the table's own documented methodology) technically counts their closed-state content as "having a real layout box." Refined the measurement script (not committed — scratchpad-only) to also exclude descendants of a closed `.pk-drawer`/`.pk-sheet`, matching what a user actually sees on page load. This is a measurement-tooling refinement, not a CSS or test change, and does not affect any committed file.

## User Setup Required

None — no external service configuration required.

## Measured Before/After (live CDP, headless Chrome, `Emulation.setDeviceMetricsOverride`)

Captured against `http://localhost:4000/` (catalog index), before = commit `08ca877` (pre-task app.css served live), after = HEAD (`ed51bab`).

### 390px (mobile, primary target)

| Metric | Before | After |
|---|---|---|
| `.pk-footer` margin-top | 48px | 24px |
| `.pk-footer-row` padding-top/bottom | 24px / 24px | 16px / 16px |
| Footer wordmark font-size | 24px | 20px |
| Tagline font-size | 12px | 12px (unchanged) |
| `.pk-footer-links a` font-size | 16px | 14px |
| `.pk-footer-links` gap | 16px | 12px |
| **Total mobile chrome (margin + pad-top + pad-bottom)** | **96px** | **56px (-41.7%)** |
| `.pk-footer` height | 179px | 156px |
| `.pk-footer-row` height | 178px | 155px |
| Brand anchor height (`min-h-11` floor) | 48px | 44px (floor binds; not a regression) |
| Gap between last content and footer top edge | 160px | 136px (delta = exactly the 24px margin reduction) |

### 768px (desktop control — must be byte-identical)

| Metric | Before | After |
|---|---|---|
| `.pk-footer` margin-top | 48px | 48px |
| `.pk-footer-row` padding-top/bottom | 24px / 24px | 24px / 24px |
| Footer wordmark font-size | 24px | 24px |
| Tagline font-size | 12px | 12px |
| `.pk-footer-links a` font-size | 16px | 16px |
| `.pk-footer-links` gap | 16px | 16px |
| `.pk-footer` height | 147px | 147px |
| `.pk-footer-row` height | 146px | 146px |
| Brand anchor height | 48px | 48px |
| Gap between last content and footer top edge | 176px | 176px |

Every captured 768px value is identical before/after — desktop is provably untouched.

### Type inventory (≤480px, corrected methodology excluding closed `.pk-drawer`/`.pk-sheet` content)

- **Before:** 5 distinct combos (Inter/12px/600 ×167, Bebas Neue/24px/400 ×9 [header + footer wordmark, both 24px], Inter/14px/400 ×8, Inter/12px/400 ×3, Inter/16px/400 ×3 [the footer links, mislabelled in the table as a "native select" exception]).
- **After:** 6 distinct combos (Inter/12px/600 ×167, Bebas Neue/24px/400 ×8 [header wordmark only], Inter/14px/400 ×11 [body tier + the now-retuned footer links], **Bebas Neue/20px/400 ×1 [new: footer wordmark, ≤480px only]**, Inter/12px/400 ×3). The `Inter/16px/400` row disappears from ≤480px (the links now render at 14px there) but the discovery that this bucket is empty because the catalog's `<select>` was removed prompted the table correction above, which also applies to the unchanged 768px row.
- **768px:** unchanged at 5 combos both before and after (confirms the footer wordmark exception and the type-inventory change are both mobile-only).

## Next Phase Readiness

- No blockers. This closes the "Deferred (not a blocker): mobile footer visual weight" item recorded in STATE.md's Blockers/Concerns section (needed its own shell-wide phase per that note — resolved here as a scoped quick task instead, touching only the footer, not the header or other shell surfaces).
- The ui-design-system inventory table is now internally consistent again — a future re-measurement of this screen starts from an accurate baseline rather than a stale one.
- The sticky title-echo bar's brand-tint/bounce open question (also noted in STATE.md, same Blockers/Concerns entry) remains genuinely open and is out of scope for this task.

---
*Phase: quick-260901-ty6*
*Completed: 2026-09-01*

## Self-Check: PASSED

All 4 modified source files confirmed present on disk; all 3 task commits (`0f00940`, `9662fbe`, `ed51bab`) confirmed present in git history.
