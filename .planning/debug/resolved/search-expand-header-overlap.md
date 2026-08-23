---
status: resolved
trigger: "expandable search on the header for mobile and desktop is misplaced and on open totally wrong overlapping and taking wrong space"
created: 2026-08-23T00:00:00.000Z
updated: 2026-08-23T22:40:00Z
---

## Current Focus

hypothesis: A premature CSS comment terminator at assets/css/app.css:582 (`(--duration-*/`) closes the comment one line early. The leftover prose on line 583 then lands in CSS context, and the parser consumes it as the *selector* for the block that follows — so the entire `.pk-search-morph` base rule (position/display/height/width/margin-left/overflow/border/background) is discarded as an invalid qualified rule.
test: Repair only the comment delimiter, rebuild assets, re-measure header geometry in headless Chrome at desktop widths and at 375px via a sized iframe.
expecting: The morph becomes a 44px flex pill pinned to the row's right edge; children sit inline instead of stacking; `.pk-nav-inner` collapses from 132px back to ~48px. All four sub-symptoms resolve from this one change.
next_action: NONE — session closed. Human verify returned "confirmed fixed" (real browser, ~335px, catalog index AND /juegos/177: single-line inline pill, no stacking, no chip overlap, closes cleanly). Fix committed as 325a86e (assets/css/app.css + test/pukllay_club_web/stylesheet_integrity_test.exs), this file archived to .planning/debug/resolved/, and .planning/debug/knowledge-base.md created with this session as its first entry.

guardrail_verdict: accepted

bug_class: Bohrbug — fully deterministic, reproduces on every load at every viewport width, no timing or concurrency component.

reasoning_checkpoint:
  hypothesis: "assets/css/app.css:582 ends the wildcard token name `--duration-*` with a `/`, forming `*/`, which the CSS tokenizer reads as the comment's close delimiter. Line 583 (`--ease-*), not literal timing values. */`) therefore lands in CSS context; the parser scans forward for the next `{`, making `--ease-*), not literal timing values. */ .pk-search-morph` a single invalid selector, so per CSS error recovery the whole `.pk-search-morph { ... }` qualified rule is dropped."
  confirming_evidence:
    - "Built CSS priv/static/assets/css/app.css:3479 literally contains `--ease-*), not literal timing values. */` as a bare line immediately preceding `.pk-search-morph {` — the garbage survives the build, proving the source comment closed early."
    - "getComputedStyle in headless Chrome: .pk-search-morph resolves position=static (declared relative), overflow=visible (declared hidden), height=132px (declared 44px). Every property declared in that one block is absent."
    - "Its children stack vertically at y=8 / y=52 / y=96 (three 44px blocks) — direct proof `display: flex` from that block never applied. This matches the user's desktop screenshot exactly: icon, then placeholder text, then X, one per row."
    - "margin-left:auto never applied: the closed morph sits at x=477.5, flush after .pk-nav-links, instead of the row's right edge — which is precisely the user's 'search icon top-center' observation in the mobile collapsed screenshot."
    - "The adjacent blocks parse fine and DO apply: .pk-search-morph.is-open widens the box to 280px (17.5rem) as measured, and .pk-search-morph-toggle's 44x44 applies. Only the single block preceded by the broken comment is dead — exactly the block CSS error recovery would discard."
    - "A comment-tokenizer walk over the entire stylesheet finds exactly ONE premature close, at line 582 — the same line."
  falsification_test: "Repair only the comment delimiter, changing nothing else, rebuild, and re-measure. If .pk-search-morph still computes position=static / height=132px / vertically stacked children, the hypothesis is wrong and something else is suppressing the rule."
  fix_rationale: "The declarations inside the .pk-search-morph block are themselves correct and intentional — they were simply never delivered to the browser. Restoring the comment delimiter re-admits that block into the cascade. This addresses the root cause (a stylesheet parse error) rather than the symptom (bad geometry); patching the geometry with new overrides would leave both the dead rule and the parse error in place."
  blind_spots:
    - "Chrome headless floors --window-size at 500px, so the <=480px mobile branch was not measured in the first pass; it must be verified via a sized iframe before claiming mobile is fixed."
    - "The repro is a static reconstruction of header_inner/1 on the catalog index, not the live LiveView — and the user's desktop screenshot is the Detalle page (it shows a breadcrumb), whose nav_search slot differs. Both must be checked after the fix."
    - "The user's mobile screenshot also reports chips showing THROUGH the search box. That is expected to dissolve once the morph is a 44px pill that never reaches into the chip row, but it is a second observable that must be re-checked rather than assumed fixed."
    - "Whether the restored geometry matches the sketch 017-E design intent is a design question measurement cannot answer; needs human visual confirmation."
  candidate_causes:
    - "code (CSS source): premature comment terminator drops the .pk-search-morph base rule — CONFIRMED"
    - "config (build pipeline): Tailwind v4 / LightningCSS mangling or layer-demoting the rule — REFUTED, the built output contains the declarations verbatim and in source order; the corruption exists in the source, not introduced by the build"
    - "environment (browser): engine-specific CSS parsing difference — REFUTED, comment tokenization is spec-defined and identical across engines, and the user reports identical breakage on both mobile and desktop devices"
    - "data: N/A — a static stylesheet has no data input"
  and_gate: "no — a single dropped rule accounts for every sub-symptom with a 1:1 mapping (dead `margin-left:auto` -> misplaced/centred icon; dead `display:flex` -> children stack vertically, which is the three-row box in the screenshots; dead `height:44px` -> 132px row and the downward overflow past the header edge; dead `overflow:hidden` -> content bleeds out of the pill). No second contributing condition is required and no residual symptom is left unexplained."

## Symptoms

expected: The header's expandable search (the `.pk-search-morph` toggle button in `header_inner/1`, lib/pukllay_club_web/components/layouts.ex) should morph in place — expanding into an inline pill/input right where the search icon sits in the header, on both mobile and desktop, without disrupting neighboring nav items.
actual: On open, the expanded search overlaps the nav links/logo, renders at the wrong width/position (not aligned with where the toggle button was), and changes the header's height unexpectedly. Reported as broken on both mobile and desktop viewports.
errors: None — user confirmed no console errors, purely a visual/layout issue.
reproduction: Catalog/ludoteca page (the page using the `nav_search` slot) — click/tap the search icon in the header to expand it.
started: Always broken — not a regression, has never worked correctly since the search-morph feature was built.

## Eliminated

- hypothesis: The `[data-search-expanded="true"]` / `.is-open` expanded-state rule overrides `display`/`flex-direction` and is what breaks the row into a vertical stack.
  evidence: The stack is present in the CLOSED state too — measured children at y=8/52/96 with the morph 132px tall before `.is-open` is ever added. The expanded-state blocks parse and apply correctly (they are what still produces the 280px width). The `display: flex` was never applied in the first place; nothing overrides it.
  timestamp: 2026-08-23T21:55:30Z

- hypothesis: The build pipeline (Tailwind v4 / LightningCSS) reorders or layer-demotes `.pk-search-morph`, letting a Tailwind utility or daisyUI base rule win the cascade.
  evidence: priv/static/assets/css/app.css:3480-3495 contains the block verbatim, in source order, in the same unlayered position as its working neighbours. The build is faithful; the defect is upstream in the source file.
  timestamp: 2026-08-23T21:56:00Z

- hypothesis: `.pk-nav-inner` is not laying out as a flex row, so its children fall out of alignment.
  evidence: Measured child offsets are exactly what flex + align-items:center predicts for a 132px-tall row — brand (48px) at y=50 = 8+(132-48)/2, links (36px) at y=56 = 8+(132-36)/2. `.pk-nav-inner` behaves correctly; it is merely being stretched by an over-tall child.
  timestamp: 2026-08-23T21:56:30Z

- hypothesis: The mobile `position: absolute; inset: 0` overlay rule (the <=480px block) causes the overlap.
  evidence: The overlap reproduces at 1280/900/700/560px, where that media query does not apply at all. The <=480px block also parses and applies cleanly. It is not the cause — though it inherits the same dead base rule.
  timestamp: 2026-08-23T21:57:00Z

- hypothesis: The expanded search lacks an opaque background, which is a second independent defect from the stacking.
  evidence: `.pk-search-morph.is-open` does set `background: var(--color-base-100)` and that rule parses and applies. The transparency the user saw is a consequence of the dead base rule's `overflow: hidden` plus the 132px box reaching down into the chip row, not a missing background declaration. Folded into the single root cause rather than tracked as a separate defect — to be re-confirmed at verification.
  timestamp: 2026-08-23T21:57:45Z

## Evidence

- timestamp: 2026-08-23T18:51:18Z
  source: user screenshot (desktop) — /home/apedraza/Pictures/Screenshots/Screenshot from 2026-08-23 18-51-18.png
  observation: Expanded search renders as a TALL STACKED BOX on the header's right side, not an inline single-line pill. Three separate rows inside the box, top to bottom: (1) magnifying-glass icon alone, (2) "Buscar juegos..." placeholder text, (3) an X close button. Header row otherwise correct: logo left, breadcrumb "Ludoteca / amazonia" center. The stacked box overflows DOWNWARD past the header's bottom edge into the page content area.
  implication: Children of the expanded search container are laying out as block-level (one per line) rather than in a row. Suggests the expanded-state rule drops/overrides `display: flex` (or forces `flex-direction: column` / `display: block`) on `.pk-search-morph[data-search-expanded="true"]`. The vertical overflow past the header edge is a direct consequence of the stacked height, and indicates the expanded height is NOT reflected in the `--pk-header-h` measurement.

- timestamp: 2026-08-23T18:51:34Z
  source: user screenshot (mobile, collapsed) — /home/apedraza/Pictures/Screenshots/Screenshot from 2026-08-23 18-51-34.png
  observation: Baseline/control for header height. Hamburger + logo top-left, small search icon top-center. Chip nav row ("Destacados del club", "Crea conexiones", "Equipo g...") sits directly BELOW the header with no overlap. Collapsed state looks correct.
  implication: Collapsed layout is fine — the defect is isolated to the expanded state. The chip nav (`subnav` slot) is immediately adjacent below the header, so any extra expanded height has nowhere to go but on top of the chips.

- timestamp: 2026-08-23T18:51:41Z
  source: user screenshot (mobile, expanded) — /home/apedraza/Pictures/Screenshots/Screenshot from 2026-08-23 18-51-41.png
  observation: Expanded search pill ("Busca por título, autor... o editorial...") OVERLAPS the chip nav row. The "Destacados del club" chip is rendered ON TOP OF / THROUGH the search box — the search placeholder text is partially obscured by the chip pill, and the chips are clearly visible through the search element's area. X button sits on a line below. Same stacked (non-inline) layout as desktop.
  implication: TWO compounding defects visible in one frame: (a) the expanded search element has no opaque background (chips show through), and (b) the chips paint ABOVE the search in z-order — the search loses the stacking contest against the `subnav` slot's stacking context. Combined with the stacked-height overflow, the expanded search extends into the chip row's space and then loses to it on z-index.
  errors: none (visual only, consistent with reported "no console errors")

- timestamp: 2026-08-23T18:51:41Z
  source: cross-screenshot synthesis
  observation: The same stacked/three-row rendering appears on BOTH desktop and mobile, and the user reports it never worked. Consistent, viewport-independent.
  implication: Root cause is more likely a single unconditional CSS rule in the expanded state than a breakpoint-specific media-query bug. Investigate `.pk-search-morph` in assets/css/app.css (~lines 584-778): the `[data-search-expanded="true"]` block's `display`/`flex-direction`, whether it sets `position: absolute`/`fixed`, its `background`/`z-index` versus the `subnav` slot's stacking context, and whether the expanded height feeds the `--pk-header-h` ResizeObserver measurement.

- timestamp: 2026-08-23T21:50:00Z
  checked: Knowledge base at .planning/debug/knowledge-base.md
  found: Does not exist — no prior resolved sessions to match against.
  implication: No known-pattern shortcut available; full investigation required. This session will create the KB.

- timestamp: 2026-08-23T21:52:00Z
  checked: Source of the search-morph — layouts.ex header_inner/1 (lines 386-437), the .CatalogNav hook (lines 199-249), and assets/css/app.css lines 525-810 plus the <=480px block at 1641-1787.
  found: Markup and JS are straightforward — the hook only toggles `.is-open` on `.pk-search-morph` and `.is-search-open` on `.pk-nav-inner`. All geometry is CSS-owned.
  implication: A pure CSS layout defect; the JS toggle is not implicated. Investigate the cascade, not the hook.

- timestamp: 2026-08-23T21:54:00Z
  checked: Built a static reconstruction of the catalog header DOM against the real built stylesheet and measured getBoundingClientRect + getComputedStyle in headless Chrome at 1280/900/700/560px, closed and open, with transitions disabled so measurements are final-state.
  found: CLOSED at 1280 — morph x=477.5 (not right-aligned), h=132 (declared 44), position=static (declared relative), overflow=visible (declared hidden); children stack vertically at y=8/52/96 rather than inline. `.pk-nav-inner` 132px tall, header 149px instead of ~64px. OPEN — the morph width does become 280px and the toggle/region/close widths do respond, but the stack stays vertical.
  implication: Every property declared in the `.pk-search-morph` base block is missing, while the `.is-open`, `-toggle`, `-close` and descendant blocks all apply. One specific rule is being discarded by the parser. Independently reproduces the exact three-row box in the user's screenshots.

- timestamp: 2026-08-23T21:55:00Z
  checked: The built stylesheet immediately above the rule — priv/static/assets/css/app.css:3479.
  found: A bare, un-commented line of prose sits directly before the selector: `--ease-*), not literal timing values. */`
  implication: The preceding comment closed early in the source. The parser reads that prose plus `.pk-search-morph` as one invalid selector and discards the entire following block — the exact failure mode observed.

- timestamp: 2026-08-23T21:57:30Z
  checked: Tokenized every CSS comment in assets/css/app.css looking for a close delimiter preceded by an identifier character.
  found: Exactly one hit — line 582, `itself. New rules reference the shared motion tokens (--duration-*/`. The trailing `*` of the wildcard `--duration-*` combines with the following `/` to form `*/`, terminating the comment one line early.
  implication: Root cause confirmed and bounded to a single site. No sibling occurrences anywhere else in the stylesheet.

## Resolution

root_cause: "assets/css/app.css:582 writes the motion-token wildcard as `(--duration-*/` inside a prose comment. The trailing `*` of `--duration-*` combines with the following `/` to form `*/`, closing the comment one line early. Line 583 (`--ease-*), not literal timing values. */`) is then parsed as CSS; the parser scans forward for the next `{` and treats `--ease-*), not literal timing values. */ .pk-search-morph` as a single invalid selector, so CSS error recovery discards the whole `.pk-search-morph { ... }` base rule. The morph therefore loses display:flex (children stack vertically -> the three-row box), height:44px (row grows to 132px -> unexpected header height and downward overflow), margin-left:auto (icon sits beside the nav links instead of the row's right edge -> 'misplaced'), plus overflow:hidden, position:relative, border-radius and background. The `.is-open` rule parses normally, which is why the box still widens on open while everything else is wrong."
fix: "assets/css/app.css:582 — rewrote `(--duration-*/` as `(--duration-* and`, so the wildcard no longer forms a `*/` and the comment runs to its intended terminator. This alone restores the whole `.pk-search-morph` base rule to the cascade. Restoring that rule also re-applied its `flex: 0 0 auto`, which (correctly) stops the open pill from being squeezed — and that exposed a latent gap: between 481px and ~790px the row cannot seat brand + nav links + a full 17.5rem pill, so the row began overflowing the viewport horizontally. Added `min-width: 0; flex-shrink: 1` to `.pk-search-morph.is-open` so the open pill yields in that band instead of raising a horizontal scrollbar; the collapsed icon stays pinned at exactly 44px via the base rule. Added test/pukllay_club_web/stylesheet_integrity_test.exs as the recurrence guard."

verification:
  method: "Static reconstruction of header_inner/1 measured against the real built stylesheet in headless Chrome (getBoundingClientRect + getComputedStyle, transitions disabled so values are final-state), at 1280/900/790/700/560px directly and at 375px through a sized iframe — Chrome's --window-size floors near 500px, so the <=480px branch is only reachable inside an iframe with its own viewport."
  isolation: "Three single-variable states measured in sequence — S0 unmodified (broken), S1 comment repaired only, S2 comment + shrink guard — so each change's effect is attributable."
  signal_bug_returns_on_revert: "PASS — reintroducing only the `*/` typo returns the exact original geometry (morph 132px tall, position=static, overflow=visible, children stacked at y=8/52/96) and makes 2 of the 3 guard tests fail. Removing it restores correct geometry and green tests."
  signal_regression_test_is_real: "PASS — the guard was run red BEFORE and green AFTER on the actual defect, not merely green after. Both the source-level check (premature comment close) and the build-output check (selector preceded by stray text) fail on the real bug. The build-output assertion was deliberately tightened after an initial version passed on the broken build: anchoring on `^` let it through because the orphaned prose also started its own line, so it now anchors on the previous rule's `}`."
  signal_not_deletion_only: "PASS — the diff repairs a comment delimiter and adds 2 declarations plus a test; nothing was deleted or disabled to make a symptom go away."
  signal_adjacent_functionality: "PASS — `mix quality` green end to end: hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted (Styler), credo --strict, sobelow, and 342 tests / 0 failures. Sobelow's low-confidence directory-traversal notes are pre-existing findings in the CSV seed code, untouched by this change."
  geometry_at_rest: "Morph is 44x44 with position=relative and overflow=hidden, pinned to the row's right edge at every width measured (e.g. 1280 -> right=1248 = viewport minus the 32px gutter; 375 -> right=361 = viewport minus the 14px gutter). Fixes the user's 'search icon top-center' observation. Header 65px desktop / 64px mobile, down from 149px."
  geometry_on_open: ">=790px: 280px (17.5rem) pill growing leftward from the pinned right edge, children inline on one 44px line, header height unchanged at 65px. <=480px: full-width overlay (position=absolute, inset 0, z-index 5, 375x44) confined to the header row, header unchanged at 64px — the intended sketch 017-E mobile sheet."
  no_horizontal_overflow: "PASS — scrollWidth == clientWidth at all six widths measured, in both states. (Pre-guard, S1 overflowed by 38px at 560px.)"
  residual_pre_existing: "In roughly the 481-750px band, opening the search still grows the header from 65px to 97px because the brand wordmark text wraps to two lines once the pill takes the room. Measured identically BEFORE the fix (brand height 80px in both S0 and S2), so it is pre-existing and not introduced here. Left unfixed deliberately: closing it means either a new breakpoint or hiding the wordmark earlier, and ux-responsive states this repo uses only Tailwind's sm/lg today and that a new breakpoint 'is a new convention and needs a reason'. Flagged for the user rather than decided unilaterally."
  human_confirmed: "PASS — user verified live in a real browser at mobile width (~335px) on BOTH the catalog index and a game detail page (/juegos/177): the search expands as a single-line inline pill, no stacking, no overlap with the chip nav, and it closes cleanly. This closes all three items that the static harness could not settle — the running LiveView (not a reconstruction), the Detalle page's differing nav_search slot, and the 'chips showing through the search box' observation. Together with the headless-Chrome desktop measurements above, the fix is confirmed at both mobile and desktop."

  follow_up_out_of_scope: "The pre-existing wordmark-wrap header-height issue disclosed under residual_pre_existing (roughly the 481-750px band, header 65px -> 97px on open because the brand wordmark wraps to two lines) was reviewed by the user and deliberately split out into its own /gsd-debug session. It is NOT part of this session's scope and did not block resolution here."

files_changed:
  - "assets/css/app.css — root-cause comment-delimiter repair at line 582; open-state shrink guard on .pk-search-morph.is-open"
  - "test/pukllay_club_web/stylesheet_integrity_test.exs — new; recurrence guard for silent CSS parse errors"
