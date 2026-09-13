---
status: resolved
trigger: "WINDOWS entry 18 browser-verification FAIL — tappable creator pills on /juegos/:id render 26.5px tall, under the project's 44px touch-target minimum."
created: 2026-09-12T23:30:00Z
updated: 2026-09-13T00:20:00Z
goal: find_root_cause_only
---

## Current Focus

bug_class: Bohrbug (deterministic — pure CSS box geometry, same height at 390px and 1440px)
known_pattern_candidate: none (KB has no touch-target / pill-height entry; closest entries are unrelated CSS cascade bugs)
hypothesis: CONFIRMED — creator_pills/1 renders the dense `.pk-pill` base with no height floor (11px x 1.5 line-height = 16.5 + 8 padding + 2 border = 26.5px); `.pk-pill-interactive` carries no min-height, and the 44px floor exists only as a per-call-site `min-h-11` utility that creator_pills/1 never received.
test: done — live CDP measurement (26.5px, min-height auto) + injected min-height:44px (all fact-grid pills -> 44px, no wrap/overflow change)
expecting: n/a
next_action: closed by quick task 260912-rwv (option A applied — min-height:44px added to `.pk-pill-interactive`); no further action

reasoning_checkpoint:
  hypothesis: "Creator pills are 26.5px tall because `.pk-pill`'s dense geometry (11px/1.5 line-height, 4px vertical padding, 1px border) sums to 26.5px and neither `.pk-pill-interactive` nor creator_pills/1's class string supplies a min-height floor."
  confirming_evidence:
    - "Computed styles on the live page: line-height 16.5px, padding 4px/4px, border 1px, min-height auto -> 26.5px, matching the reported value exactly"
    - "Injecting only `min-height: 44px` makes every creator/Mecánicas/Temáticas pill exactly 44px with unchanged widths and line counts"
    - "The two pill call sites that DO reach 44px (filter_modal chip_class/1, index active-filter chip) carry an explicit `min-h-11` utility; `.pk-pill-interactive` (c33e7f1) declares only cursor + transition, although sketch 036 specified min-height:44px for interactive chips"
  falsification_test: "If adding a 44px min-height did NOT bring the pill to 44px (e.g. an overflow/height clamp on dd/.pk-chip-row) the hypothesis would be wrong — tested, it did reach 44px"
  fix_rationale: "Moving the 44px floor into the variant that means 'tappable' (or at minimum onto creator_pills/1) addresses why the pill is short, not a symptom; it restores sketch 036's interactive-chip contract"
  blind_spots: "Real-device tap behaviour not tested (only box geometry); visual acceptance of 44px-tall outline pills in the fact grid and in the masthead facts row has not been reviewed by the developer; 1440px re-measure after injection not run (two-column grid, same geometry expected)"
  candidate_causes:
    - "code: creator_pills/1 (show.ex:1254) omits `min-h-11` — per-call-site convention not applied"
    - "config/design-system: `.pk-pill-interactive` (app.css:1232) does not own the touch floor, so the variant set allows composing a 'tappable' pill below 44px"
    - "environment: viewport/media-query dependent sizing — eliminated (same at 390/1440)"
    - "data: long names compressing the pill — eliminated (nowrap, all names 26.5px)"
  and_gate: "yes — the failure needs BOTH the variant lacking a floor AND the call site lacking `min-h-11`; either one present yields 44px. root_cause is recorded as a two-item set."

## Symptoms

expected: (WINDOWS entry 18 checklist) Creator pills under "Diseñadores" / "Ilustradores" on the game detail page have a measured tap target of at least 44px tall at 390px (project touch-target minimum, see ux-responsive skill). The todo explicitly flagged: "`creator_pills/1` carries no `min-h-11`, unlike the index chips, so a measured height under 44px is a real finding."
actual: At 390px (and 1440px), `a.pk-pill.pk-pill-outline.pk-pill-interactive` for "Antoine Bauza" and "Miguel Coimbra" on /juegos/179 measure 26.5px tall (widths 96.9 / 103.8px). No ::before/::after hit-area expansion (both `content: none`); elementFromPoint 1px above or below the box misses the pill.
errors: none
timeline: Found 2026-09-12 during the browser verification of waived WINDOWS.md entries (todo 2026-09-12-browser-verification-session-for-waived-windows-ui-entries.md).
reproduction: Local dev server, viewport 390px. Open /juegos/179 (7 Wonders Duel), scroll to "Diseñadores", measure the "Antoine Bauza" link's getBoundingClientRect().height.

other_entry18_observations (2026-09-12) — all PASS:
- Outline pill style (1px solid border, radius 9999px); at 1440px hover shifts border and text from rgb(227,211,240)/rgb(107,91,123) to brand ink rgb(69,16,92).
- "Antoine Bauza" → /?designers=Antoine+Bauza with "Resultados" heading, "Diseñador: Antoine Bauza" chip, 7 Wonders Duel in results (both widths).
- "Miguel Coimbra" → /?artists=Miguel+Coimbra with "Ilustrador: Miguel Coimbra" chip, 7 Wonders Duel in results (both widths).
- /juegos/137 (Wingspan) at 390px: four artist pills wrap on two rows, no overflow (doc scrollWidth == clientWidth).

relevant_files:
- lib/pukllay_club_web/live/catalog_live/show.ex (creator_pills/1)
- assets/css/app.css (.pk-pill, .pk-pill-outline, .pk-pill-interactive)
- index-page chips that do carry min-h-11 (for comparison)

## Evidence

- timestamp: 2026-09-12T23:40:00Z
  checked: .planning/debug/knowledge-base.md headings (grep pill/touch/tap/chip)
  found: no prior touch-target or pill-height resolution; chip-related entries are cascade/layout bugs (search-expand-header-overlap, search-right-align-mobile-cycle-*), not this class
  implication: no known-pattern shortcut; investigate fresh

- timestamp: 2026-09-12T23:41:00Z
  checked: lib/pukllay_club_web/live/catalog_live/show.ex:1248-1260 (creator_pills/1)
  found: each creator renders `<.link class="pk-pill pk-pill-outline pk-pill-interactive">` inside `div.pk-chip-row.flex.flex-wrap.gap-2`; no size variant, no `min-h-11`, no hit-area pseudo-element
  implication: the pill's height is whatever the dense `.pk-pill` base produces

- timestamp: 2026-09-12T23:42:00Z
  checked: assets/css/app.css:1054-1064 (.pk-pill), 1078-1082 (.pk-pill-outline), 1213-1216 (.pk-pill-comfortable), 1232-1252 (.pk-pill-interactive + :hover)
  found: `.pk-pill` = inline-flex, font-size 11px, padding 4px 9px, border 1px; no line-height and no min-height. `.pk-pill-outline` = colors only. `.pk-pill-interactive` = cursor:pointer + border-color/color transition only; its :hover changes border/color only. `.pk-pill-comfortable` = font 0.75rem, padding 0 12px (ZERO vertical padding — it depends on something else for height). No rule anywhere in the pill system declares min-height.
  implication: arithmetic 11px x 1.5 (Tailwind preflight html line-height) = 16.5 + 8 padding + 2 border = 26.5px — matches the reported 26.5px to the tenth. "Interactive" in the variant set means pointer affordance only, never touch sizing.

- timestamp: 2026-09-12T23:43:00Z
  checked: how the 44px "index chips" reach 44px — lib/pukllay_club_web/live/catalog_live/index.ex:1098, lib/pukllay_club_web/components/filter_modal.ex:534/538 (chip_class/1), assets/css/app.css:4462-4479 (.pk-chip)
  found: (a) index active-filter chip class = `pk-active-filter-chip pk-pill pk-pill-accent pk-pill-comfortable pk-pill-interactive min-h-11`; (b) filter modal chip_class/1 = `[pk-pill, pk-pill-selected|pk-pill-outline, pk-pill-comfortable, pk-pill-interactive, min-h-11]`; (c) category-nav `.pk-chip` is OUTSIDE the pill system and declares `min-height: 44px` in its own CSS rule. In both pill-system cases the floor comes from the Tailwind `min-h-11` utility appended at the CALL SITE, not from any pill variant.
  implication: the 44px touch floor is a per-call-site convention (ux-responsive SKILL.md "min-h-11 is this app's minimum for any tappable pill or button"), not encoded in the pill system. Any call site that composes `pk-pill-interactive` without remembering `min-h-11` silently ships a sub-44px target. creator_pills/1 (01.3-07, commit 68e88eb) is such a call site.

- timestamp: 2026-09-12T23:44:00Z
  checked: other call sites that compose `pk-pill-interactive` without `min-h-11` (grep lib/)
  found: GameChips.chip_row/1 linked branch (game_chips.ex:107, detail-page Mecánicas/Temáticas — IDENTICAL class string to creator_pills/1); GameChips.editorial_tags/1 linked branch (game_chips.ex:167, `pk-pill-tag` overrides padding to 0 3px and font to 0.875rem); GamePreview.facts_row/1 linked branches (game_preview.ex:76/90/104, `pk-fact pk-pill pk-pill-neutral pk-pill-interactive`)
  implication: creator pills are one instance of a systemic gap; the Mecánicas/Temáticas links in the same fact grid must be sub-44px by the same arithmetic. To confirm by measurement.

- timestamp: 2026-09-12T23:45:00Z
  checked: tests pinning these class strings (constrains the fix direction)
  found: catalog_show_test.exs:2553 regex `class="pk-pill pk-pill-outline pk-pill-interactive"` on chip_row/1's linked branch (exact attribute string, so appending `min-h-11` there breaks it); catalog_show_test.exs:58 exact equality on facts_row link class `"pk-fact pk-pill pk-pill-neutral pk-pill-interactive"`; catalog_live_test.exs:1040 token-membership only (tolerant); catalog_show_test.exs:4576 tone-variant gate forbids border-radius/padding/font-size on TONE variants only (min-height on `.pk-pill-interactive` or a size variant is not policed); catalog_live_test.exs:2402 bespoke-chip drift gate ignores selectors containing `pk-pill`. No existing test asserts creator_pills/1's class string or any pill's height floor.
  implication: no gate existed for "tappable pill must have a 44px floor"; a CSS-side fix (on `.pk-pill-interactive`) needs no test edits, while a call-site `min-h-11` on chip_row/1 would need the 2553 regex updated.

- timestamp: 2026-09-12T23:55:00Z
  checked: live measurement, headless Chrome via CDP (scratchpad measure.mjs), http://localhost:4000/juegos/179, viewport 390px, every `a.pk-pill`
  found: html line-height 24px (16px x 1.5); each pill's computed line-height 16.5px (11px x 1.5 inherited), padding 4px/4px, border 1px, min-height `auto`. Heights — Diseñadores (Antoine Bauza, Bruno Cathala) 26.5px; Ilustradores (Miguel Coimbra) 26.5px; Mecánicas x5 26.5px; Temáticas x5 26.5px; GamePreview facts row x3 (`pk-fact pk-pill pk-pill-neutral pk-pill-interactive`) 26.5px; editorial hashtag `#DuelosMemorables` (`pk-pill-tag pk-pill-interactive`) 23px. Chip rows: Diseñadores/Ilustradores 1 line, Mecánicas/Temáticas 2 lines each (61px, row-gap 8px). Doc scrollWidth 390 == clientWidth.
  implication: CONFIRMS the arithmetic mechanism by direct observation, and confirms the defect is systemic — 15 fact-grid links plus 3 masthead facts plus 1 hashtag, all sub-44px. Only the 3 creator pills were in entry 18's scope.

- timestamp: 2026-09-12T23:57:00Z
  checked: same page/viewport with an injected `.pk-fact-col .pk-pill-interactive { min-height: 44px; }` (no other change)
  found: every creator and Mecánicas/Temáticas pill measures exactly 44px; widths unchanged (96.9 / 95.1 / 103.8 ...); line count per row unchanged (1/1/2/2); Mecánicas/Temáticas rows 61px -> 96px; still no horizontal overflow (390 == 390). Total fact-grid vertical growth at 390px ~= 105px (17.5 x 2 single-line rows + 35 x 2 two-line rows). Text stays vertically centered (pill is inline-flex + align-items:center).
  implication: the missing min-height floor alone accounts for the whole deficit — nothing else (line-height, padding, pseudo-element, wrapper) is needed to reach 44px. The main regression cost is vertical: visibly taller outline pills and a ~105px longer fact grid on mobile, not wrapping or overflow.

- timestamp: 2026-09-12T23:59:00Z
  checked: design intent — .planning/sketches/036-pill-chip-unification/README.md + index.html (the sketch the pill system was built from), and origin commit of `.pk-pill-interactive` (git log -S: c33e7f1, feat(01.2-26) task 2)
  found: sketch 036's winner explicitly gives interactive ("action") chips "a real 44px touch height" (`.uni-pill[data-role="action"] { min-height: 44px; padding: 0 12px }`, round 2: "44px touch height kept, that's an a11y floor not a style choice"). It classed facts/Mecánicas/Temáticas as "info — nothing to tap". c33e7f1 ported `.pk-pill-interactive` as cursor + transition only — the min-height did NOT travel into the variant; the two call sites that already had `min-h-11` (filter modal chip_class/1, active-filter chip) kept it as a utility, masking the omission. Meanwhile facts_row/chip_row links (01.1-06) were given `pk-pill-interactive` with no floor, and 01.3-07's creator_pills/1 copied chip_row/1's linked class string verbatim.
  implication: root cause is an AND of (1) the pill system's interactive variant not owning the touch floor its source sketch specified, and (2) creator_pills/1 (like chip_row/1 before it) not applying the per-call-site `min-h-11` convention. Either one present would have yielded 44px.

## Eliminated

- hypothesis: viewport/breakpoint-specific sizing (a media query shrinking the pill on some widths)
  evidence: identical 26.5px at 390px and 1440px (symptoms); `.pk-pill` has no media-query override; only `.pk-fact-cols` changes at 48rem and it touches columns, not pill geometry
  timestamp: 2026-09-12T23:55:00Z

- hypothesis: a `min-h-11` exists in markup but is missing from the built stylesheet (stale asset build / Tailwind source-scan miss)
  evidence: creator_pills/1 source class string (show.ex:1254) contains no `min-h-11`; the utility is emitted and works elsewhere (filter modal chips, active-filter chip); computed min-height is `auto`
  timestamp: 2026-09-12T23:55:00Z

- hypothesis: an intended invisible hit-area expansion (::before/::after) exists but is broken
  evidence: no pseudo-element rule exists for any `.pk-pill*` selector in app.css; symptoms show content:none on both pseudo-elements and elementFromPoint 1px outside the box misses
  timestamp: 2026-09-12T23:55:00Z

- hypothesis: data-dependent (long names wrapping and compressing the pill)
  evidence: `.pk-pill` is white-space:nowrap; short and long names (Bruno Cathala 95px, Construye ciudades 127px) all measure the same 26.5px
  timestamp: 2026-09-12T23:55:00Z

## Specialist Review

- timestamp: 2026-09-13T00:10:00Z
  specialist_hint: general (mapped skill: engineering:debug)
  result: NOT RUN — the skill-invocation tool is not available in this session-manager context; diagnose-only session, no fix direction was applied. Review the fix options (A: min-height on `.pk-pill-interactive`; B: `min-h-11` on creator_pills/1; middle: `.pk-fact-col .pk-pill-interactive` scoped rule) when the fix is planned.

- timestamp: 2026-09-13T00:20:00Z
  specialist_hint: n/a — user decision, recorded post-diagnosis
  result: User chose option A (min-height on `.pk-pill-interactive`) over option B (`min-h-11` on creator_pills/1 alone) and the scoped middle option (`.pk-fact-col .pk-pill-interactive`). Option A fixes every tappable-pill call site at once — creator pills, the Mecánicas/Temáticas links, the masthead facts row, and the editorial hashtag links — rather than patching one call site or one scoped region, and it restores sketch 036's original 44px interactive-chip contract that the c33e7f1 port dropped, closing the "AND-gate" so no future call site can compose `pk-pill-interactive` below 44px by omission.

## Resolution

root_cause: (1) lib/pukllay_club_web/live/catalog_live/show.ex:1254 — creator_pills/1 composes `pk-pill pk-pill-outline pk-pill-interactive` with no size variant and no `min-h-11` (copied verbatim from GameChips.chip_row/1's linked branch), so the pill takes the dense base height 11px x 1.5 + 4px + 4px + 1px + 1px = 26.5px; (2) assets/css/app.css:1232 — `.pk-pill-interactive` declares only cursor + transition, so the pill system's "tappable" variant does not carry the 44px touch floor sketch 036 specified for interactive chips (dropped in the c33e7f1 port); the floor survives only as a per-call-site `min-h-11` utility on the filter-modal and active-filter chips, which is what makes those look correct and hid the gap. Same defect also hits GameChips.chip_row/1 links (Mecánicas/Temáticas, 26.5px), GamePreview.facts_row/1 links (26.5px) and editorial_tags/1 hashtag links (23px) — outside entry 18's scope.
fix: >
  Quick task 260912-rwv, user-chosen option A: added a single `min-height: 44px;` declaration
  (with a provenance comment above it) to the top-level `.pk-pill-interactive` rule in
  assets/css/app.css, alongside its existing `cursor: pointer` and `transition`. This closes
  AND-gate item 2 (the pill system's tappable variant now owns the 44px touch floor), which
  makes AND-gate item 1 (creator_pills/1's missing per-call-site `min-h-11`) moot — for
  creator_pills/1 and for every other current or future call site that composes
  `pk-pill-interactive` (GameChips.chip_row/1's Mecánicas/Temáticas links,
  GameChips.editorial_tags/1's hashtag links, GamePreview.facts_row/1's links). No markup was
  changed at any call site. The redundant `min-h-11` Tailwind utilities on filter_modal.ex's
  chip_class/1 and index.ex's active-filter chip were deliberately left in place (harmless,
  out of scope — removing them would touch class strings pinned by existing tests). A new
  CSS-source regression describe block ("pill system interactive touch-target floor") was
  added to catalog_show_test.exs pinning the 44px floor, its floor-only geometry (no fixed
  height/max-height/width/padding/font-size), and the base `.pk-pill`'s inline-flex +
  align-items:center centring (with `.pk-pill-tag` overriding neither).
verification: >
  RED/GREEN TDD cycle (commits b207211 RED, 3e0989b GREEN in the 260912-rwv worktree branch):
  Test A ("declares a 44px min-height touch floor") failed before the app.css edit (min-height
  absent) and passed after it; Tests B (floor-only geometry) and C (base flex centring)
  passed both before and after, as expected since neither assertion depended on the fix.
  `git diff b207211^..3e0989b -- assets/css/app.css` shows only added lines, all at the
  `.pk-pill-interactive` rule and its preceding comment. `mix test
  test/pukllay_club_web/live/catalog_show_test.exs test/pukllay_club_web/stylesheet_integrity_test.exs`
  — 218 tests, 0 failures (includes the unmodified pill tone-variant geometry gate).
  `mix quality` — all seven steps exit 0, 1043 tests, 0 failures (hex.audit: no retired
  packages; deps.audit: no vulnerabilities; credo --strict: 891 mods/funs, no issues; sobelow:
  three pre-existing low-confidence findings unrelated to this change, no new findings).

  Live 390px-viewport CDP probe (headless Chrome, mobile emulation, worktree's own dev server
  on PORT=4010, throwaway scratchpad script, not committed):
  - /juegos/137 (Wingspan): h1 confirms the page. All 16 `a.pk-pill-interactive` pills
    (facts row x3, 13 chip-row/creator links) measure exactly 44px tall. The
    "Ilustradores"/artist pill row spans 2 distinct top offsets (still wraps onto multiple
    rows, unchanged from the pre-fix 26.5px-tall wrapping). Every chip-row pill's right edge
    (max 314.2px) stays inside its `.pk-chip-row` container's right edge (376px) — no
    overflow. `document.documentElement.scrollWidth` (390) equals `clientWidth` (390).
  - /juegos/179 (7 Wonders Duel): h1 confirms the page. All 17 `a.pk-pill-interactive` pills
    (facts row x3, hashtag, 13 chip-row/creator links) measure exactly 44px tall, including
    creator pills (Antoine Bauza, Bruno Cathala, Miguel Coimbra — the three pills WINDOWS #18
    originally reported at 26.5px) and Mecánicas/Temáticas links. Creator pills' single row
    unchanged (artistRowCount 1). The `#DuelosMemorables` hashtag link measures 44px tall;
    getComputedStyle reports `display: flex` (not literal `inline-flex`) because the element
    is itself a flex item of its flex-wrap parent — Chrome's computed-style API reports the
    spec's "blockified" used value for flex items that specify an inline `display`, which is
    expected CSS behaviour, not a regression; the CSS-source test above already pins the
    literal `display: inline-flex` declaration on `.pk-pill`. `align-items: center` reported
    as-is. The hashtag's own box vertical midpoint (636.39px) matches its text node's
    vertical midpoint (636.39px) exactly — confirms centring. scrollWidth (390) equals
    clientWidth (390) — no overflow.
  Blind spots remaining, honestly noted: real-device tap behaviour was not tested (box
  geometry only, as in the original diagnosis); the developer's own visual acceptance of the
  now visibly taller outline pills in the fact grid and masthead facts row has not been
  reviewed — the fix trades a sub-44px tap target for a taller (per the earlier injected-fix
  evidence, roughly +105px total) fact grid on mobile, which was flagged as the expected cost
  during diagnosis but not yet signed off on visually.
files_changed:
  - assets/css/app.css
  - test/pukllay_club_web/live/catalog_show_test.exs

follow_up_note: >
  The ux-responsive skill's "min-h-11 on every tappable pill" per-call-site wording predates
  this variant-level floor (not edited by this quick task) — a future pass could update that
  skill's guidance to point at `.pk-pill-interactive` instead of a per-call-site utility.
