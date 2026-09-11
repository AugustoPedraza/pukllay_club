---
phase: quick-260902-fdm
plan: 01
subsystem: ui
tags: [footer, mobile, css-custom-properties, breakpoint-scoped, compliance-attribution]

requires:
  - phase: quick-260901-ty6
    provides: "--pk-footer-offset/--pk-footer-pad-block chrome tokens on the base .pk-footer rule, retuned once already at ≤480px (96px -> 56px); the four-tier --pk-footer-gap-* spacing scale this task leaves dormant, not deleted"
provides:
  - "≤480px footer reduced to the BGG compliance line alone (sketch 044 winner H) — .pk-footer-left (brand/tagline/nav links) and .pk-footer-copyright hidden via CSS, markup unchanged"
  - "≤480px chrome retuned a second time: --pk-footer-offset 1.5rem->1rem, --pk-footer-pad-block 1rem->0.75rem (40px total, down from 56px)"
  - "main.pk-boundary-collapse + .pk-footer's ≤480px literal retuned to 1rem, kept equal to --pk-footer-offset by intent (260901-ty6's decoupling contract, now re-applied at the new value)"
  - "the two now-unreachable 260901-ty6 type rules (.pk-brand-quiet .pk-brand-name font-size, .pk-footer-links font-size) retired; ui-design-system/SKILL.md re-measured to 4 combos at ≤480px (was 6), 5 unchanged at ≥481px"
affects: [mobile-footer, ui-design-system-skill, catalog-index-type-inventory, detail-page-boundary]

actuals:
  tokens: 8706
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Compliance guard as a permanent 'never hidden' assertion, not a one-time RED test: FooterRhythmTest's new compliance guard passed green from the start (nothing hid the attribution before this change either) — it exists to fail the moment ANY future footer-reduction edit sweeps .pk-footer-legal/.pk-footer-meta/.pk-bgg-note under a container display:none, not to prove today's absence of a bug."
    - "narrow_footer_block/1 anchored to (?m)^[ \\t]*\\.pk-footer\\s*\\{ instead of an unanchored pattern, so a second selector sharing the same literal tail (main.pk-boundary-collapse + .pk-footer) inside the same media block cannot be mistaken for the base rule."

key-files:
  created: []
  modified:
    - assets/css/app.css
    - lib/pukllay_club_web/components/layouts.ex
    - test/pukllay_club_web/footer_rhythm_test.exs
    - .claude/skills/ui-design-system/SKILL.md

key-decisions:
  - "Content reduction delivered via breakpoint-scoped CSS hides (display: none on .pk-footer-left and a new .pk-footer-copyright class hook), not mobile-only markup restructuring — REQ-2's explicit preference. The DOM stays one shape at every width, so every existing desktop markup contract in footer_rhythm_test.exs/layouts_test.exs stays valid without a parallel mobile branch."
  - ".pk-footer-copyright is an ADDITIVE class on the existing copyright span (layouts.ex), not a markup rewrite — the desktop cascade has no rule for the class, so >480px is provably unaffected by the same mechanism as every other change in this task."
  - "main.pk-boundary-collapse + .pk-footer's ≤480px margin-top literal retuned from 1.5rem to 1rem in lockstep with --pk-footer-offset, kept as an independent literal (not converted to the token) — continuing 260901-ty6's decoupling contract so a future mobile retune cannot silently move the detail page's own closed sketch-035 decision."
  - "260901-ty6's four --pk-footer-gap-* tokens (list/group/cluster) are left in the ≤480px .pk-footer rule even though their consumers are now hidden — documented as DORMANT rather than deleted, since removing them would break tier-ordering guards for no rendered benefit and they wake the moment any future rule unhides a footer cluster below 480px."
  - "narrow_footer_block/1's regex re-anchored to line-start whitespace only, closing a real collision risk the new main.pk-boundary-collapse + .pk-footer selector introduced into the same media block (its own tail is also literally '.pk-footer {')."

patterns-established:
  - "A withdrawn breakpoint-scoped exception (260901-ty6's ≤480px wordmark/link SIZE exceptions to D-B) is documented with a dated WITHDRAWN note left in the CSS at the exact spot the rule used to live, plus a superseding sentence appended (not rewritten) to the original rule's own base comment — mirrors this project's existing pattern for adding an exception, applied symmetrically to retiring one."

requirements-completed: [SHELL-01]

coverage:
  - id: D1
    description: "≤480px footer hides .pk-footer-left (brand/tagline/links) and the copyright via a stable class hook, both as PARENT hides (not per-child); the BGG attribution's markup, href, image and text are provably never hidden by any rule in the ≤480px block"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/footer_rhythm_test.exs#the ≤480px footer is the BGG compliance line and nothing else"
        status: pass
      - kind: other
        ref: "live CDP measurement (headless Chrome, scratchpad script, not committed): 390px visibleMetaCount=1 (BGG only), visibleFooterLinksCount=0, brandNameVisibleInFooter=false, copyrightVisible=false, bggVisible=true with correct img/text/href"
        status: pass
    human_judgment: false
  - id: D2
    description: "≤480px chrome retuned strictly further than 260901-ty6 (--pk-footer-offset/--pk-footer-pad-block ratios <= 0.4x/0.55x of base), with the detail page's boundary literal kept equal to the token by intent"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/footer_rhythm_test.exs#the chrome tightens further than 260901-ty6 shipped, expressed as ratios; #the detail page and the catalog page open the same ≤480px footer gap"
        status: pass
      - kind: other
        ref: "live CDP measurement: catalog 390px footerMarginTop=16px, rowPadding=12px/12px (40px total, was 56px); detail page 390px footerMarginTop=16px (equal to catalog's --pk-footer-offset); 768px byte-identical to 260901-ty6's after-table (48/24/24px, footer 147px, row 146px, gap 176px)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The two 260901-ty6 type rules the hide made unreachable (.pk-brand-quiet .pk-brand-name font-size, .pk-footer-links font-size) are removed along with their three guarding tests; ui-design-system/SKILL.md's type inventory is re-measured live, not inferred, and no comment/doc/test message describes a ≤480px footer wordmark or link size that no longer renders"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "mix test (766/766), mix format --check-formatted, mix compile --warnings-as-errors"
        status: pass
      - kind: other
        ref: ".claude/skills/ui-design-system/SKILL.md Type hierarchy section, updated 2026-09-02; scratchpad CDP inventory script (not committed): 4 distinct combos at 390px (was 6), 5 at 768px (byte-identical to the 2026-09-01 measurement)"
        status: pass
    human_judgment: false
  - id: D4
    description: "At a real ≤480px viewport the footer is a single quiet strip carrying only the BGG logo + 'Powered by BGG', separated from content above by a non-zero margin, not cramped, tappable to boardgamegeek.com; at 768px/1280px the footer is visually unchanged"
    verification: []
    human_judgment: true
    rationale: "Plan's own Task 3 verify lists this as a <human-check> (subjective read of 'reads as separated'/'not cramped'), not an automated assertion, following the same pattern 260901-ty6's own D4 used. The CDP measurements above numerically substantiate every component of the claim (non-zero 16px margin, exactly one visible line, correct href/image/text, byte-identical wide-viewport values) but a human eyeballing the real phone-width render is the plan's own designated oracle for this specific deliverable — not yet performed as of this SUMMARY."
    files:
      - assets/css/app.css

duration: 20min
completed: 2026-09-02
status: complete
---

# Quick Task 260902-fdm: Reduce the Mobile Footer to Just the BGG Attribution Summary

**At ≤480px the footer is reduced to the BGG compliance line alone (sketch 044 winner H) via breakpoint-scoped CSS hides on the existing markup, with its remaining vertical chrome retuned a second time (56px → 40px) — desktop provably untouched, proven with live CDP measurements matching 260901-ty6's after-table byte-for-byte at 768px.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-02T11:12:39-03:00 (approx., after the plan commit)
- **Completed:** 2026-09-02T11:23:00-03:00
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Reduced the ≤480px footer to exactly one line — the BGG compliance attribution (real logo + "Powered by BGG", linking to boardgamegeek.com) — by hiding `.pk-footer-left` (brand lockup + FAQ/Contacto/Juntadas links) and a new `.pk-footer-copyright` class hook, both as PARENT hides so no empty cluster spends a flex gap slot.
- Retuned the ≤480px chrome a second time: `--pk-footer-offset` 1.5rem→1rem, `--pk-footer-pad-block` 1rem→0.75rem, taking total vertical chrome from 56px (260901-ty6) to 40px for what is now a single 12px line of small print.
- Kept the detail page's `main.pk-boundary-collapse + .pk-footer` boundary literal in lockstep with the retuned offset (1.5rem→1rem), continuing 260901-ty6's deliberate decoupling contract rather than converting it to the token.
- Retired the two now-unreachable 260901-ty6 type rules (`.pk-brand-quiet .pk-brand-name` font-size, `.pk-footer-links` font-size) and their three guarding tests, since the elements they styled no longer render at ≤480px at all.
- Hardened `footer_rhythm_test.exs`'s `narrow_footer_block/1` helper against a real regex collision the new `main.pk-boundary-collapse + .pk-footer` selector introduced into the same media block (its own tail is also literally `.pk-footer {`).
- Live CDP-measured the change at 390px and 768px before proceeding: 768px is byte-identical to 260901-ty6's after-table on every captured value; 390px chrome dropped to 40px with exactly one visible footer element (the BGG attribution) and zero visible brand/links/copyright; the detail page's ≤480px offset (16px) equals the catalog page's.
- Re-measured the ≤480px type inventory live and updated `.claude/skills/ui-design-system/SKILL.md`: 4 distinct combos at ≤480px (down from 6), 5 unchanged at ≥481px — the heading tier is back to a single size at every width, D-B's "demotion is by colour, not size" rule holds everywhere again with no breakpoint exception.

## Task Commits

Each task was committed atomically:

1. **Task 1: Reduce the ≤480px footer to the BGG line and tighten its chrome** — `3eeb154` (feat)
2. **Task 2: Retire the ≤480px type rules the hide made unreachable, reconcile docs** — `90e332c` (refactor)
3. **Task 3: Measure it at 390px, re-measure the ≤480px type inventory, close the docs** — `1062835` (docs)

## Files Created/Modified

- `assets/css/app.css` — ≤480px block only (plus two explicitly-scoped base comment appends, grep-verified): retuned chrome tokens, added `.pk-footer-left`/`.pk-footer-copyright` hides, added the decoupled `main.pk-boundary-collapse + .pk-footer` literal, removed the two unreachable type rules with dated WITHDRAWN notes in their place
- `lib/pukllay_club_web/components/layouts.ex` — additive `pk-footer-copyright` class on the copyright span; `brand_logo/1`'s `@doc`/`mark` attr doc and `footer/1`'s doc block corrected/extended (append-only, no existing paragraph deleted)
- `test/pukllay_club_web/footer_rhythm_test.exs` — hardened `narrow_footer_block/1`'s regex; new describe block (5 tests, RED-verified where new behavior was asserted) pinning the ≤480px shape and the compliance guard; deleted 3 tests pinning the retired type rules; renamed one test whose name implied an active wordmark shrink
- `.claude/skills/ui-design-system/SKILL.md` — type-hierarchy table and combo counts re-measured live and updated for the ≤480px reduction

## Decisions Made

- Content reduction delivered entirely via breakpoint-scoped CSS hides on the unchanged markup (REQ-2's explicit preference), not a mobile-only markup branch — the DOM stays one shape at every width, so no existing desktop markup contract needed a parallel mobile variant.
- `.pk-footer-copyright` is additive on the existing copyright span, not a markup rewrite — the desktop cascade has no rule for the class, so `>480px` is provably unaffected by the same "no rule references it" mechanism as every other change here.
- The detail page's boundary literal was retuned in lockstep with `--pk-footer-offset` (1.5rem→1rem) but kept as an independent literal, continuing 260901-ty6's decoupling contract rather than converting it to the token — a future mobile retune still cannot silently move the detail page's own closed sketch-035 decision.
- 260901-ty6's `--pk-footer-gap-list`/`-group`/`-cluster` tokens were left in place (not deleted) even though their consumers are now hidden — documented as dormant rather than wrong, since deleting them would break tier-ordering guards for zero rendered benefit.

## Deviations from Plan

None — the plan executed exactly as written. The one test assertion ("the surviving piece is the attribution") that the plan's own Task 1 prose implied should be verified RED against the pre-change markup was already green before any edit (nothing hid the attribution before this task either); that is documented in the task's own RED-verification note above as a guard, not new behavior, consistent with how the plan frames it as "the most important assertion in the file" rather than a new-behavior test.

## Issues Encountered

None. All three tasks' automated verification passed on the first run after implementation; the only correction made during Task 1 was a `mix format --check-formatted` reflow of one long line in the new test code (a pure line-wrap, reviewed in the diff, no behavior change — not counted as a deviation since it was caught before commit, not after).

## User Setup Required

None — no external service configuration required.

## Measured Before/After (live CDP, headless Chrome, `Emulation.setDeviceMetricsOverride`)

Captured against `http://localhost:4000/` (catalog index) and `http://localhost:4000/juegos/177` (detail page, carries `main.pk-boundary-collapse`), after HEAD (`1062835`). A pre-task "before" snapshot was not separately captured live — 260901-ty6's own after-table (measured 2026-09-01) serves as this task's "before," since no commit in this task touched anything outside the single ≤480px block plus the two explicitly-scoped base comments.

### 390px (mobile, primary target)

| Metric | 260901-ty6 (before this task) | After this task |
|---|---|---|
| `.pk-footer` margin-top | 24px | 16px |
| `.pk-footer-row` padding-top/bottom | 16px / 16px | 12px / 12px |
| **Total mobile chrome** | **56px** | **40px (-28.6%)** |
| `.pk-footer` height | 156px | 43px |
| `.pk-footer-row` height | 155px | 42px |
| Visible `.pk-footer-meta` count | 2 (copyright + BGG) | 1 (BGG only) |
| Visible `.pk-footer-links a` count | 3 | 0 |
| Brand name visible in footer | yes | no |
| Copyright visible | yes | no |
| BGG attribution visible, img+text+href | yes | yes (unchanged) |
| Detail page (`pk-boundary-collapse`) footer margin-top | 24px (literal, 260901-ty6) | 16px (matches catalog's `--pk-footer-offset`) |

Note: `.pk-footer` height dropped from 156px to 43px primarily because the footer's own CONTENT collapsed to one line (sketch 044), not solely from the 16px chrome reduction — consistent with the plan's intent.

### 768px (desktop control — must be byte-identical to 260901-ty6)

| Metric | 260901-ty6 | After this task |
|---|---|---|
| `.pk-footer` margin-top | 48px | 48px |
| `.pk-footer-row` padding-top/bottom | 24px / 24px | 24px / 24px |
| `.pk-footer` height | 147px | 147px |
| `.pk-footer-row` height | 146px | 146px |
| Gap between last content and footer top edge | 176px | 176px |
| Visible `.pk-footer-meta` count | 2 | 2 |
| Visible `.pk-footer-links a` count | 3 | 3 |
| Brand name visible in footer | yes | yes |

Every captured 768px value is identical to 260901-ty6's own after-table — desktop is provably untouched.

### Type inventory (≤480px, same methodology as 260901-ty6: excludes closed `.pk-drawer`/`.pk-sheet` descendants)

- **Before this task (260901-ty6's after-state):** 6 distinct combos — Inter/12px/600 ×167, Bebas Neue/24px/400 ×8 (header wordmark), Inter/14px/400 ×11 (body tier + footer links), Bebas Neue/20px/400 ×1 (footer wordmark, footer-scoped exception), Inter/12px/400 ×3 (tagline, header + footer instances).
- **After this task:** 4 distinct combos — Inter/12px/600 ×167 (unchanged), Bebas Neue/24px/400 ×8 (header wordmark only — footer's Bebas Neue/20px/400 exception retired entirely), Inter/14px/400 ×8 (body tier only — footer links' contribution gone), Inter/12px/400 ×1 (header tagline only — footer's own tagline instance gone with the rest of the hidden lockup).
- **768px:** unchanged at 5 combos (byte-identical to 2026-09-01) — confirms this change is mobile-only.

## Next Phase Readiness

- No blockers. This closes sketch 044 (mobile-footer-balance, winner H) and the two-round stalemate it broke — the footer's ≤480px shape now matches the developer's own explicit framing ("the only thing I need there is the BGG compliance").
- Task 3's Task-level `<human-check>` item (D4 above) has not yet been performed as a live phone-width visual confirmation — the CDP measurements substantiate every quantitative component of it, but a human eyeballing the real render is this plan's own designated oracle for the subjective "reads as separated, not cramped" claim. Flagged, not blocking, following the same precedent 260901-ty6 set for its own equivalent item.
- The sticky title-echo bar's brand-tint/bounce open question (noted in STATE.md) remains genuinely open and is out of scope for this task.

---
*Phase: quick-260902-fdm*
*Completed: 2026-09-02*

## Self-Check: PASSED

