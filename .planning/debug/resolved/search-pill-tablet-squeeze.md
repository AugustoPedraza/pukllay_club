---
status: resolved
trigger: "Follow-up from the mobile-search-expand-jump debug session's audit: between 481-1099px viewport width, the open search pill is squeezed down to near the closed icon's width, leaving no visible input or close button."
created: 2026-08-25
updated: 2026-08-25
resolved: 2026-08-25
decision: "Option D (2026-08-25) — re-derive both reveal breakpoints for the in-flow treatment, PLUS an overlay scoped only to the band where the row provably cannot fit."
---

## Symptoms

- **Expected behavior:** In the 481-1099px viewport band, tapping the header search icon should expand it into a usable search pill with a visible input field and a close control (matching the working behavior at ≤480px and ≥1100px).
- **Actual behavior:** The open pill gets squeezed down to as little as 49px wide at 800px viewport — only ~5px wider than the closed 44px icon. It reads as a bare dimmed circle with just the filter glyph; no input box, no close button are usably visible/reachable.
- **Error messages:** None. Purely a layout/capacity issue — no console errors expected.
- **Timeline:** Pre-existing, not a regression. Surfaced during the motion-rhythm audit in the prior session (`.planning/debug/resolved/mobile-search-expand-jump.md`), not reported directly by a user encountering it fresh.
- **Reproduction:** Open the site in a viewport between roughly 481px and 1099px wide (e.g. 800px), tap the header search icon to expand it. Evidence screenshot from the prior session: `.planning/debug/assets/mobile-search-expand-jump/open-800-squeezed.png`.

## Current Focus

- **bug_class:** Bohrbug — deterministic, settled-state geometry, reproduces at every width in the band. No timing dependence (the prior session already proved the *motion* half is fixed; what remains is static capacity).
- **known_pattern_candidate:** `header-height-wordmark-wrap` + `footer-overflow-tablet-width` (KB). Both are **capacity** defects in this same header/footer row, both AND-gated, and both taught the same lesson: *a breakpoint chosen by convention rather than derived from the row's content arithmetic masks the bug on the devices the author tested and exposes it on the ones they did not.* Treating as hypothesis candidate, not diagnosis.
- **hypothesis:** `.pk-nav-inner` is over-subscribed for an open 17.5rem pill across 481-1099px, and `.pk-search-morph.is-open`'s `min-width: 0; flex-shrink: 1` (added by `search-expand-header-overlap` specifically to stop horizontal overflow) makes the pill the row's **single point of give** — every other item in the row is `flex-shrink: 0` / `shrink-0` by deliberate prior fixes. So 100% of the shortfall lands on the pill, with **no floor**, and it collapses below the width of its own chrome. Further: the shortfall is **non-monotonic** because two reveal breakpoints (48rem wordmark, 50rem cat-trigger label) each re-consume the room the wider viewport just added — predicting a sawtooth, not a single band.
- **test:** CDP sweeps against the running dev server — closed-form capacity model over 24 widths, pill-internals decomposition, Detalle control arm, and a 3-arm runtime-injected fix differential with screenshots.
- **expecting:** (met) settled widths reproduce the inherited table; input text area at or near 0px wherever the pill is under ~142px of chrome; demand steps exactly at the two reveal breakpoints.
- **STATUS: RESOLVED — option D implemented, machine-verified, and CONFIRMED BY THE USER ON A REAL
  DEVICE (2026-08-25).** The CDP sweep is green on all four header shapes at 47 widths each,
  `mix quality` exits 0 (482 tests, was 474), the recurrence guard is mutation-verified, and the
  standing blind spot — headless Chrome is not iOS Safari, so measurement establishes MECHANISM and
  never PERCEPTUAL SUFFICIENCY — has now been closed by the only instrument that can close it, a
  person looking at the real screen. See **Resolution** and **Prevention** at the bottom.
- **STATUS (historical): DECISION RECEIVED — implementing option D.** Root cause confirmed and characterised in closed form (validated at 24/24 widths). The checkpoint asked which of four measured fixes to adopt; the user chose **D** (re-derive both reveal breakpoints for the in-flow treatment + an overlay scoped only to the band that provably cannot fit), and additionally directed: sweep 481-1440px on **both** the catalog index and Quiénes Somos (do not assume they match — the blind_spot flagged Quiénes Somos as unswept), write a recurrence guard that **recomputes** the row's arithmetic rather than pinning the content-dependent 662.3px literal, and run `mix quality`.
- **next_action:** implement D against the clean tree (all four candidate builds were reverted), then run the full CDP sweep on both surfaces, add the recomputing guard, run `mix quality`, and route to `request_human_verification` — the blind_spot stands: headless Chrome establishes MECHANISM, never PERCEPTUAL SUFFICIENCY.

## Current Focus — implementation plan (option D)

The band boundaries are **derived from the row's own arithmetic**, not chosen by convention —
that is the specific failure mode all four prior sessions in this header recorded.

| term | value | source |
|---|---|---|
| isologo-only brand | 36px | measured max-content |
| brand lockup (isologo + 8 + wordmark 206) | 250px | measured max-content |
| nav links | 166.3px | measured max-content |
| cat-trigger, icon only | 44px | measured |
| cat-trigger label | +154.7px | measured (fixedDemand step 596.3 → 751.0) |
| row gap | 24px | `.pk-nav-inner { gap: 1.5rem }` |
| gutters | 2 × 32px | `:root { --pk-gutter: 2rem }` |
| open pill | 280px | `.pk-search-morph.is-open { width: 17.5rem }` |

- **overlay ceiling** = 36 + 24 + 166.3 + 24 + 44 + 24 + 280 + 64 = **662.3px** → `max-width: 662px`
  (the last integer width that cannot seat the row). **No headroom added deliberately**: just above
  the ceiling the in-flow pill degrades *gracefully* (280 → 279 → …), so a few px of content drift
  costs a few px of input width, not a cliff.
- **wordmark reveal** = the same sum with the 250px lockup = **876.3px** → `56rem` (896px).
  **1rem of headroom deliberately added**: a reveal is a **cliff** (+214px of demand in one step), so
  content drift here does not degrade, it detonates. This is the 68px arithmetic error corrected —
  the old 48rem comment's 808.3px sum omitted `.pk-cat-trigger` (44px) and its gap (24px).
- **label reveal** = 876.3 + 154.7 = **1031.0px** → `66rem` (1056px), same 1rem cliff headroom.
  Replaces 50rem/800px, which was bisected on the CLOSED row only and merely relocated the cliff.

**Mechanism for the overlay band (mirrors the ≤480px treatment already in the file, which the
`mobile-search-expand-jump` session proved):** `.pk-search-morph` becomes `position: absolute;
top: 0; right: var(--pk-gutter); left: auto; height: 100%` in **BOTH** states, so `.is-open`
changes only an interpolable `width` (44px → the base rule's own 17.5rem, which now renders in
full because an out-of-flow box is not flex-shrunk). No `position` flip on the class toggle — that
is the C1 trap the prior session measured at 444px of overflow. No `display: none` on the animated
path. Right edge = `var(--pk-gutter)` in both states by declaration, so the closed-vs-open
right-edge invariant holds by construction rather than by compensation.

**Two hazards this plan handles explicitly:**
1. **Detalle must not be dragged in.** Its `.pk-nav-crumb` is `flex: 1`, so taking the morph out of
   flow would let the crumb grow 68px and run the game title under the search icon — a *new* defect
   on the one surface measured clean. Scoped to `.pk-nav-links ~ .pk-search-morph`, which matches
   the catalog index (both filter states) and never Detalle (crumb, no links).
2. **The closed row must not reflow.** Out of flow, the morph stops consuming its 44px + 24px gap,
   so `.pk-cat-trigger`'s `margin-left: auto` would slide the trigger 68px right — directly under
   the closed search icon. Reserved back with `margin-right: calc(44px + 1.5rem)` on the trigger.
   Reserving it on `.pk-nav-inner`'s padding instead was rejected: `app.css:206-210` makes
   `.pk-gutter` the single owner of horizontal padding on aligned surfaces.

**Cascade:** the band block is `@media (max-width: 662px)`, which deliberately OVERLAPS the ≤480px
block rather than starting at `min-width: 481px` — the `search-right-align-mobile` lesson is that a
`min-width: N+1` complement leaves a sub-pixel band (480.5px) matching NEITHER rule, and here that
band would render the squeezed pill. It is placed BEFORE the ≤480px block and its selector is
written `.pk-search-morph:where(.pk-nav-links ~ *)` so `:where()` holds it at `.pk-search-morph`'s
own 0-1-0 specificity: plain source order then lets the ≤480px block win in the overlap, instead of
a higher-specificity rule silently outranking it and freezing the mobile values.

## Current Focus — reasoning_checkpoint

```yaml
reasoning_checkpoint:
  hypothesis: >
    .pk-nav-inner allocates the open search pill's width as LEFTOVER. The pill is the row's only
    yielder (min-width: 0; flex-shrink: 1) while every sibling is flex-shrink: 0 by two deliberate
    prior fixes, so pill = min(280, viewport - fixedDemand) with no floor. fixedDemand steps up at
    two reveal breakpoints (48rem wordmark +214px, 50rem cat-trigger label +154.7px) that were each
    derived against the CLOSED row, so each fires at a width where the pill had just recovered -
    producing a sawtooth whose cliffs make a WIDER viewport strictly worse.
  confirming_evidence:
    - "Closed-form model pill = min(280, vw - fixedDemand) matches measured width at 24/24 widths, 0 mismatches."
    - "fixedDemand takes exactly 3 values (382.3 / 596.3 / 751.0) whose step points are exactly 768px and 800px, the two reveal breakpoints."
    - "Cliffs measured directly: 767->768 drops the pill 280->171.7; 799->800 drops it 202.7->49."
    - "The 48rem comment's own sum omits .pk-cat-trigger (44px + 24px gap); it predicts 239.7px at 768px, measured 171.7px - short by exactly the omitted 68px."
    - "Detalle control arm: pill = 280px at all 10 widths because .pk-nav-crumb (flex: 1) yields instead. Proves the mechanism is the yielder identity, not the viewport."
    - "Pill internals: chrome is a fixed 142px, so textArea = pill - 142; measured 0px at 481-524 and 800-893."
  falsification_test: >
    If the pill's width were set by something other than leftover row space, the closed-form model
    would mis-predict at some width - it does not, at 24/24. If the reveals were not the cause of the
    sawtooth, suppressing them (arm C) would not restore a full pill above 663px - it does. If the
    yielder identity were irrelevant, Detalle would squeeze too - it does not.
  fix_rationale: >
    PENDING USER DECISION. All four candidates address the root cause rather than the symptom - none
    tunes the pill's own width. A and B change WHO yields (take the pill out of flow / make the
    dimmed items stop consuming space); C and D fix the breakpoint derivations that create the
    cliffs. What differs is the visible cost, which is a UX judgement rather than a correctness one.
  blind_spots:
    - "Headless Chrome is not iOS Safari. Standing rule from search-right-align-mobile-cycle-3: measurement establishes MECHANISM, never PERCEPTUAL SUFFICIENCY - the chosen fix must still be human-verified on a real device."
    - "Only the catalog index measured for the defect; Quienes Somos shares the same header shape but was not swept. Detalle measured and cleared."
    - "Option A's overlay was measured for geometry but its MOTION was not re-measured across 481-1030px; the prior session only proved the curve at <=480px."
    - "The 662.3px figure depends on the content strings in the row (nav link copy, tagline) - it is content-dependent and will drift if copy changes. This is KB branch-F content-dependence, and it argues for a guard that recomputes rather than a pinned literal."
  candidate_causes:
    - "code (CSS): pill is the sole yielder with no floor - CONFIRMED, dominant."
    - "code (CSS): pill chrome is an incompressible 142px, so a squeezed pill loses the INPUT first - CONFIRMED, this is what converts 'narrow' into 'unusable'."
    - "config (breakpoints): all three header breakpoints (480/768/800) derived against the closed row - CONFIRMED, this is what makes it a sawtooth rather than one gentle band."
    - "data (content): fixedDemand is a sum of rendered content strings - CONFIRMED as a contributing/latency factor, same as header-height-wordmark-wrap."
    - "environment: browser/zoom/scrollbar effects - ELIMINATED; model is exact across 24 widths and 3 reps, --hide-scrollbars set, no overflow anywhere."
  and_gate: >
    YES - three conditions. (1) Over-subscription alone would merely shrink the pill gracefully.
    (2) Sole-yielder-without-floor alone would be harmless in a row with slack. (3) Closed-row
    breakpoint derivation alone would be cosmetic. It takes all three: the row is over-subscribed,
    100% of the shortfall lands on one element that has no floor, and the reveals re-break it at
    exactly the widths where it had recovered. Note (1) and (2) are each the DELIBERATE, DOCUMENTED
    outcome of a prior resolved session, which is why both obvious fixes are pre-blocked.
```

## Evidence

- **checked:** `.planning/debug/knowledge-base.md` — semantic match on capacity/layout entries in this same header/footer row.
  **found:** Three prior capacity sessions establish the doctrine this bug sits in: `header-height-wordmark-wrap` (row over-subscribed by arithmetic, not by a missing breakpoint; pinned brand + nav-links to `flex-shrink: 0`, leaving the pill's shrink guard as "the row's single point of give, which is what it was added for"), `footer-overflow-tablet-width` (blame the **shallowest** overflowing box; a *pinned* dimension is the signature of a floor; fix how the minimum is **computed**, not the value), `search-expand-header-overlap` (added `min-width: 0; flex-shrink: 1` to `.is-open` specifically to stop horizontal overflow in this band).
  **implication:** The pill being the sole yielder is not an accident — it is the **deliberate, documented outcome of two prior fixes**. Any fix that re-grants shrink to brand/nav-links directly regresses `header-height-wordmark-wrap`, and any fix that gives the pill a hard floor without removing demand directly regresses `footer-overflow-tablet-width`. Both obvious moves are pre-blocked.

- **checked:** CDP sweep of the running dev server, catalog `/`, 24 widths 481-1440px, open-state settled geometry, in-flow children only (`.pk-cat-backdrop` is `position: fixed` and `.pk-cat-panel` is `position: absolute` — both are children of `.pk-nav-inner` but consume **zero** flex space; an earlier pass that summed them produced nonsense).
  **found:** A closed-form model that is **exact at all 24 widths, zero mismatches**:
  `pill = min(280, viewport − fixedDemand)`, where `fixedDemand = brand + nav-links + cat-trigger + 3×24px gap + 64px gutters` (the morph itself excluded).
  `fixedDemand` takes exactly **three** values, stepped by the two reveal breakpoints:
  | band | fixedDemand | what changed | pill across band | full-280 needs |
  |---|---|---|---|---|
  | 481-767 | 382.3 | — | 98.7 → 280 | ≥ 662.3px |
  | 768-799 | 596.3 | wordmark reveals at 48rem (+214) | 171.7 → 202.7 | ≥ 876.3px |
  | 800-1030 | 751.0 | cat-trigger label reveals at 50rem (+154.7) | 49 → 279 | ≥ **1031px** |
  **implication:** The defect is fully characterised in closed form. It is **not one band but a sawtooth with two cliffs**, and at each cliff a *wider* viewport makes the search box *worse*: 767→768 drops the pill 280 → 171.7, and **799→800 drops it 202.7 → 49**. One extra pixel of viewport destroys the search box. The threshold for a full pill is 1031px, matching the reported "≈1100px" upper edge.

- **checked:** decomposition of the open pill's own children against its `overflow: hidden` clip box.
  **found:** The pill's chrome is fixed and incompressible: toggle 32 (`width: 2rem`, `flex: 0 0 auto`) + gap 4 + input padding 16 + filter-trigger 44 (`flex: 0 0 auto`) + close 44 (`width: 2.75rem`, `flex: 0 0 auto`) = **142px before a single character of text**. Only `.pk-nav-search` (`flex: 1 1 auto; min-width: 0`) can yield, so `textArea = pill − 142`. Measured: 481→**0px**, 500→0, 524→0, 768→29.7, 800→**0**, 850→0, 893→0, 1000→107, ≥1031→138.
  At 800px the toggle is laid out at x 689..721 while the pill's box is 719..768 — **only 2px of the 32px search glyph is inside the clip box**; the filter glyph, input and close are stacked overlapping each other. That is exactly the reported "bare dimmed circle with just the filter glyph".
  **implication:** Two genuinely **unusable** sub-bands (zero text area): **481-524px and 800-893px**. Cramped (<80px text): 525-639, 768-799, 894-999. Usable: 640-767 and ≥1000. The user-visible severity is worst at 800-893, not uniformly across 481-1099.

- **checked:** the same sweep against Detalle `/juegos/177`, whose header carries `.pk-nav-crumb` instead of `.pk-nav-links` and has no `.pk-cat-trigger`.
  **found:** **Pill = 280px at every width 481-1280px.** `.pk-nav-crumb` is `flex: 1; min-width: 0` — flex-grow 1 AND flex-shrink 1 — so the crumb absorbs and yields the row's slack and the pill always gets its full specified width. The model's `fixedDemand` deliberately mismatches here, which is the tell.
  **implication:** **The defect is scoped to headers carrying nav-links + cat-trigger (catalog index, Quiénes Somos) — Detalle is unaffected.** More usefully: **the repo already contains the correct priority on another surface.** On Detalle the row yields to the search box; on the catalog the search box yields to the row. This is `footer-desktop-overloaded` lesson (iv) — *check whether another surface already solves the same pair correctly* — and it means the fix direction is a **consistency repair against an in-repo pattern**, not a newly invented design.

- **checked:** the arithmetic written in the `@media (min-width: 48rem)` wordmark-reveal comment (`app.css:2538-2544`) against measured reality.
  **found:** The comment states the row "needs 808.3px to seat brand + nav links + a full 17.5rem pill" and predicts the pill "lands at 239.7px at 768px". Its sum is `250 + 24 + 166.3 + 24 + 280 + 64 = 808.3` — **three items and two gaps. It omits `.pk-cat-trigger` entirely (44px) and its gap (24px) = 68px.** The true requirement is 876.3px, and the measured pill at 768px is **171.7px, not the predicted 239.7px** — short by exactly 68px.
  **implication:** A concrete, provable arithmetic error in the documented derivation, and the direct cause of the 768px cliff being worse than its author predicted. The breakpoint was derived from a row inventory that was missing a row item.

- **checked:** the `@media (min-width: 50rem)` cat-trigger-label comment (`app.css:2555-2567`).
  **found:** Verbatim: *"measured live at 48rem/768px with the label forced visible, the closed row overflowed the viewport by 10px … and the open search pill was squeezed down to a functionally useless 2px … Measured the real threshold by bisection: overflow persisted through 775px and cleared at 780px. 50rem/800px is the next breakpoint above that measured value."*
  **implication:** **This exact defect was already observed once, at 2px, and the response measured only the CLOSED row.** Bisecting on `scrollWidth` cleared the overflow at 780px and the label was moved to 800px — but the *open pill* was never re-measured at the new breakpoint, where it is 49px. **The cliff was relocated from 768px to 800px, not removed.** Fourth instance in this codebase of the standing lesson *a breakpoint chosen without the row's full content arithmetic masks the bug where it was tested and exposes it elsewhere* — and the first where the arithmetic error is pinpointed to a specific omitted term.

- **checked:** runtime-injected 3-arm fix differential (no repo files touched), catalog `/` at 481/560/800/900/1000px, plus header screenshots at 481/800/1000px into `.planning/debug/assets/search-pill-tablet-squeeze/`.
  **found:** All three candidate fixes achieve **pill 280px / textArea 138px with zero horizontal overflow** at every width tested, except **C at 481-662px, which is unchanged from baseline (98.7px / 0px text)** — as its arithmetic predicts.
  | arm | 481 | 560 | 800 | 900 | 1000 | headerH while open |
  |---|---|---|---|---|---|---|
  | baseline | 98.7 / **0** | 177.7 / 35.7 | 49 / **0** | 149 / 7 | 249 / 107 | 64-65 |
  | A overlay | 280 / 138 | 280 / 138 | 280 / 138 | 280 / 138 | 280 / 138 | 64-65 (unchanged) |
  | B collapse-on-open | 280 / 138 | 280 / 138 | 280 / 138 | 280 / 138 | 280 / 138 | **64 everywhere (was 65)** |
  | C re-derived breakpoints | 98.7 / **0** | 177.7 / 35.7 | 280 / 138 | 280 / 138 | 280 / 138 | 64-65 (unchanged) |
  **implication:** Three defensible fixes, each with a different visible cost, and the screenshots make the cost concrete: **A** clips a nav link mid-word ("Quiénes Somos" → "Qu…") because the opaque pill floats over the row; **B** empties the header to just the isologo + a category glyph, and `display: none` is not animatable so all three items snap away at t=0 — reintroducing a reflow jump into the interaction the prior session just made smooth, plus a 1px header-height change that `--pk-header-h` republishes; **C** looks the cleanest of the three at 800px (links intact, icon-only trigger, full pill) but does not touch the 481-662px band at all. **This is a genuine UX tradeoff, not a correctness question — routing to a checkpoint.**

- **checked:** whether the mis-derived-breakpoint pattern is confined to the two reveals, by comparing each header breakpoint's stated justification against the open-pill arithmetic.
  **found:** **All three of this header's breakpoints were derived against the CLOSED row; none accounts for the open pill.**
  | breakpoint | stated basis | arithmetic incl. open pill | error |
  |---|---|---|---|
  | 480px — hamburger/drawer swap (`app.css:2633`) | *"Nav links stop fitting below this breakpoint"* | row cannot seat links + trigger + open pill until **662.3px** | 182px |
  | 48rem/768px — wordmark reveal | sum of 808.3px, **omits `.pk-cat-trigger` 44px + 24px gap** | **876.3px** | 68px |
  | 50rem/800px — cat-trigger label | bisected on closed-row `scrollWidth` (cleared 780px) | **1031px** | 251px |
  **implication:** The defect is **systemic, not a one-off**. The pill is the row's only yielder, so it absorbs 100% of every breakpoint derivation error, and each reveal fires at a width where the pill had just recovered — which is precisely what turns three independent errors into one sawtooth. Any fix that only retunes one breakpoint leaves the class open.

- **checked:** hybrid arm **D** — option C (both reveal breakpoints re-derived from the row's real arithmetic: wordmark 48rem→876.3px, label 50rem→1031px) **plus** option A scoped only to 481-662px, the single band where the row provably cannot seat brand + links + trigger + a full pill. Swept 22 widths 481-1440px in **both** states.
  **found:** **pill = 280px and textArea = 138px at all 22 widths**, zero horizontal overflow in both the closed and open state, and — the load-bearing invariant — the morph's **right edge is identical closed vs open at every width** (449/449 at 481px … 1248/1248 at 1280px). Header height stable at 64px below 880px and 65px above, matching current behaviour. Screenshots at the 662/663 handover show a **near-seamless boundary**: the nav links do not move, and the only difference is whether the category glyph is visible beside the pill or covered by it.
  **implication:** D fully resolves the defect across the whole reported band while keeping the in-flow treatment wherever the arithmetic permits and using the overlay **only** where it provably cannot fit — and its boundary (662.3px) is *derived*, not conventional, which is the specific failure mode all four prior sessions recorded. It is also the only candidate whose closed-state geometry appears unchanged from today's at every width (to be re-verified per-child before commit).

## Eliminated

- **hypothesis:** The 767px arm genuinely differs from its neighbours (one measurement showed pill = 53px at 767px while 720px and 768px behaved per model).
  **evidence:** Measurement artifact, not a defect. Re-ran 755/760/765/766/767/768/769/775px × 3 reps each with an explicit wait for `.phx-connected` plus a double-rAF settle: **24/24 reps match the model exactly** (767 → 280px in 3/3). The original outlier came from measuring a LiveView dead render before the connected render replaced the DOM. Harness hardened; no further non-determinism observed anywhere in the sweep.
  **timestamp:** 2026-08-25

- **hypothesis:** Re-grant shrink permission to `.pk-brand-wordmark` / `.pk-nav-links` so the shortfall is shared across the row instead of landing entirely on the pill.
  **evidence:** Directly regresses `header-height-wordmark-wrap` (KB), which pinned exactly these two items to `flex-shrink: 0` **because** letting them shrink made the tagline and "Quiénes Somos" reflow and grew the header 65 → 129px, republishing a wrong `--pk-header-h` to every sticky element. That session's own note states the pill's shrink guard is now "the row's single point of give, which is what it was added for." Blocked by a resolved decision, not by preference.
  **timestamp:** 2026-08-25

- **hypothesis:** Give `.pk-search-morph.is-open` a usable floor (e.g. `min-width: 220px`) and let the row do what it must.
  **evidence:** Reintroduces horizontal overflow in exactly the band `footer_overflow_test.exs` guards — the row has no slack to give at 800px (demand 751 of 800), so a 220px floor forces `scrollWidth` past `clientWidth`. This is the mirror image of `search-expand-header-overlap`'s fix, which added `min-width: 0; flex-shrink: 1` here *specifically* to stop that overflow. Reverting it re-opens the resolved bug.
  **timestamp:** 2026-08-25

- **hypothesis:** The defect affects all pages with a header search box.
  **evidence:** Measured false on Detalle `/juegos/177` at 10 widths 481-1280px: **pill = 280px at every one.** `.pk-nav-crumb` is `flex: 1; min-width: 0` (grow AND shrink), so it is the yielder there and the pill always gets its specified width. Scope is limited to headers carrying `.pk-nav-links` + `.pk-cat-trigger` — catalog index and Quiénes Somos.
  **timestamp:** 2026-08-25

## Resolution

**root_cause (CONFIRMED — AND-gate fired, three contributing conditions):**

`.pk-nav-inner` hands the open search pill whatever is **left over** after every other item in the row has taken its space, and three conditions combine to make that leftover collapse below the pill's own chrome:

1. **DOMINANT — the pill is the row's only yielder, and it has no floor.** `.pk-search-morph.is-open` is `min-width: 0; flex-shrink: 1` while `.pk-brand-wordmark` (`shrink-0`), `.pk-nav-links` (`flex-shrink: 0`) and `.pk-cat-trigger` (`flex: 0 0 auto`) cannot give at all. So **100% of any shortfall lands on the search box**, down to zero. Closed form, exact at 24/24 measured widths: `pill = min(280, viewport − fixedDemand)`.
2. **The pill's chrome is incompressible, so the INPUT is what disappears first.** toggle 32 + gap 4 + input padding 16 + filter 44 + close 44 = **142px** of `flex: 0 0 auto` before one character of text. Only `.pk-nav-search` yields, so `textArea = pill − 142` → **zero usable input at 481-524px and 800-893px**. This is what turns "narrow" into "unreachable": at 800px only 2px of the 32px search glyph is even inside the pill's `overflow: hidden` box, leaving the bare dimmed circle with the filter glyph from the report.
3. **All three of this header's breakpoints were derived against the CLOSED row**, so each reveal fires at a width where the pill had just recovered — turning what would be one gentle ramp into a sawtooth where a **wider viewport is strictly worse**: 767→768 drops the pill 280→171.7px; **799→800 drops it 202.7→49px**. The 48rem derivation is provably short by one omitted row item (`.pk-cat-trigger`, 44px + 24px gap = 68px: it predicts 239.7px at 768px, measurement gives 171.7px). The 50rem block bisected on closed-row `scrollWidth` only, after having already observed this very defect at "a functionally useless 2px" — which **relocated the cliff from 768px to 800px rather than removing it**.

Conditions (1) and (2) are each the deliberate, documented outcome of a prior resolved session (`header-height-wordmark-wrap` pinned the siblings; `search-expand-header-overlap` added the pill's shrink guard to stop overflow), which is why both obvious fixes — let the siblings shrink, or give the pill a floor — are pre-blocked as direct regressions.

**Scope (CORRECTED at fix time — the investigation cycle got this wrong):** **the catalog index
only.** The pre-fix Resolution said "catalog index and Quiénes Somos", inferred from the two pages
sharing `.pk-nav-links`. The user's checkpoint instruction was to *measure* Quiénes Somos rather
than assume, and measurement falsifies the inference: **`/quienes-somos` renders no `nav_search`
slot at all**, so `header_inner/1`'s `:if={@nav_search != []}` never emits a `.pk-search-morph` —
there is no search box on that page to squeeze. Swept at 47 widths: no morph, no overflow, zero
geometry change outside the deliberate wordmark-reveal band. (The prior session had recorded this
correctly — "`/quienes-somos` has no search slot" — and this session's scope note contradicted it
without checking. Two surfaces sharing a *selector* is not two surfaces sharing a *defect*.)
Detalle is likewise unaffected: `.pk-nav-crumb` is `flex: 1; min-width: 0`, so it yields and the
pill keeps its full 280px at every width. **The repo already contains the correct priority on
another surface.**

---

## fix (option D — chosen at the checkpoint, implemented 2026-08-25)

Three changes in `assets/css/app.css`, all derived from the row's arithmetic rather than chosen.

**1. Wordmark reveal `48rem` → `56rem` (768 → 896px).** Requirement recomputed as
`250 + 24 + 166.3 + 24 + 44 + 24 + 280 + 64 = 876.3px`. The old 48rem was wrong by a provable 68px:
its documented sum counted three items and two gaps, omitting `.pk-cat-trigger` and its gap.

**2. Cat-trigger label reveal `50rem` → `66rem` (800 → 1056px).** Requirement `876.3 + 154.7 =
1031.0px`. The old 50rem was bisected on the **closed** row's `scrollWidth`, which cannot see this
constraint at all — the open row is 251px wider.

Both reveals take **1rem of headroom** above the requirement, deliberately: a reveal is a *cliff*
(the whole revealed item's width lands in one pixel of viewport), the sums are rendered-text widths
measured in headless Chrome, and real-device font metrics will not reproduce them to the pixel.

**3. A new `@media (max-width: 662px)` block** — the band where the row provably cannot seat
`36 + 24 + 166.3 + 24 + 44 + 24 + 280 + 64 = 662.3px` at any breakpoint setting. There the morph
becomes `position: absolute; top: 0; right: var(--pk-gutter); left: auto; height: 100%` in **both**
states, so `.is-open` changes nothing but an interpolable width and the pill overlays the row
instead of competing for it — the same mechanism `≤480px` has always used, now applied at the width
the arithmetic calls for. Plus `margin-right: calc(44px + 1.5rem)` on `.pk-cat-trigger`, reserving
the footprint the morph stops occupying so the **closed** row does not reflow.

**This boundary takes NO headroom, deliberately unlike the two reveals** — it is a *ramp*, not a
cliff: one pixel above it the in-flow pill is 280px, then 279, then 278, so content drift costs a
few px of input width and nothing else. Adding headroom would instead overlay widths that fit.

Three details are load-bearing and each is pinned by a mutation-verified test:
- **`:where()`**, not a bare `.pk-nav-links ~ .pk-search-morph`. The band deliberately *overlaps*
  the ≤480px block rather than starting at `min-width: 481px`, because the
  `search-right-align-mobile` lesson is that a `min-width: N+1` complement leaves a sub-pixel band
  (480.5px) matching NEITHER rule — and here that gap would render the squeezed pill. The overlap is
  resolved by **source order**, which only works if the rule stays at `.pk-search-morph`'s own 0-1-0
  specificity. At 0-2-0 it would outrank the mobile block on the catalog page and freeze the phone
  overlay at these values.
- **Scoped to `.pk-nav-links ~`**, so Detalle cannot match. Unscoped, taking the morph out of flow
  there lets the `flex: 1` crumb grow into the vacated 68px and run the game title under the search
  icon — a *new* defect on the one surface measured clean.
- **`position` on the base rule, never on `.is-open`.** That is the C1 trap the prior session
  measured at 444px of overflow on every collapse while passing every expand-direction check.

Also corrected: three comments elsewhere in `app.css` that recorded the **wrong** arithmetic
(the base wordmark rule's `808.3px` sum, `.is-open`'s "roughly 790px", `.pk-cat-trigger-label`'s
"below 50rem"), and `header_row_height_test.exs`'s comment carrying the same 808.3px error. The
prior session's postmortem found that *the diagnosis was already committed to the repository in
plain language and still did not stop the bug*; leaving a wrong derivation in the file is the same
failure with the polarity flipped.

## verification

**Harness:** headless Chrome via CDP against the running dev server, `--hide-scrollbars
--force-device-scale-factor=1`, hardened per the investigation cycle (wait for `.phx-connected`
before measuring — a LiveView dead render produced the one non-deterministic outlier already in
**Eliminated** — then a double-rAF settle).

**Settled-geometry sweep — 47 widths × 4 header shapes × closed and open = 0 problems.**
Assertions run per width: right edge identical closed vs open; no horizontal overflow in either
state; open pill ≥ 280px; closed pill = 44px; open input slot ≥ 80px.

| surface | 481-662 | 663-895 | 896-1055 | 1056-1440 |
|---|---|---|---|---|
| catalog (`/`) | 280 / abs | 280 / in-flow | 280 (wordmark) | 280 (label) |
| catalog, filters active (`/?q=`) | 280 / abs | 280 | 280 | 280 |
| Quiénes Somos | no morph | no morph | no morph | no morph |
| Detalle (`/juegos/177`) | 280 / in-flow | 280 | 280 | 280 |

Headline, catalog, baseline → fixed (open pill / input slot):
`481: 98.7/20.7 → 280/202` · `560: 177.7/99.7 → 280/202` · `768: 171.7/93.7 → 280/202` ·
**`800: 49/0 → 280/202`** · `850: 99/21 → 280/202` · `893: 142/64 → 280/202` · `1000: 249/171 →
280/202`. Every squeezed and every zero-input width is gone.

**The 662.3px boundary is confirmed empirically, not just derived:** on the *baseline* tree the
in-flow pill measures **279.7px at 662px and exactly 280px at 663px** — the model's predicted
threshold, landing between two adjacent integers.

**Closed-state differential vs the unmodified tree — the load-bearing claim.** Per-child rect diff
(x/right/w/h/y) plus header height, every width, every surface:
**zero closed-state geometry changes outside the two reveal bands, on all four surfaces.** Inside
them the changes are exactly the deliberate ones (wordmark hidden 768-895, label hidden 800-1055,
header 65 → 64px in 768-895). Open-state changes are confined to **481-662px on the catalog** and
**481-560px on catalog-filtered** — i.e. only where the pill was genuinely squeezed. **Detalle and
Quiénes Somos: zero open-state changes at every width.**

**Motion, per-rAF through the whole transition in both directions**, 16 widths spanning all three
bands (390 / 480 / 481 / 500 / 560 / 640 / 661 / 662 / 663 / 700 / 800 / 895 / 896 / 1000 / 1056 /
1280): `transitionrun:width` fires **every time in both directions**; first painted frame **0.8% of
travel** spread over ~17 frames, matching the `--ease-standard` signature the KB records;
**`documentElement.scrollWidth == clientWidth` in every sampled frame** (not merely at rest — this
is the check the C1 trap failed); **the right edge is a single constant across every frame of every
run.** The new band is indistinguishable from the in-flow band in motion terms.

**Reduced motion re-verified, not regressed.** Under `--force-prefers-reduced-motion` at 390 / 481 /
560 / 662 / 663 / 900 / 1280px: morph and trigger both report `transition-duration: 0.001s` and the
expand completes in 1 frame. The newly-overlaid band needed **no registration** — the global
`!important` guard from `reduced-motion-order-bug` covers it automatically, which is the whole point
of that rule being universal.

**One flagged outlier, re-run and eliminated as a harness artifact.** The first motion pass reported
`1280px collapse: frame 1 carried 20.9% of travel`. Six reps at each of 1280 / 663 / 560px:
**0.8% in 17 of 18 reps**, and the single recurrence (560px rep 5, 36.1%) carries a **95.1ms rAF gap**
immediately before the first observed step — the sampler missed ~5 frames, so one *observed* step
aggregates five *real* ones. Every low-frame-count run correlates with a long rAF gap, and the right
edge is pinned in all 18 reps. Same class as the 767px artifact already in **Eliminated**; recorded
here with its diagnostic so it is not re-litigated.

**`mix quality` exits 0** — hex.audit, deps.audit, deps.unlock, format (+Styler), credo --strict,
sobelow, **482 tests / 0 failures** (was 474; +8 from the new guard). Styler's rewrites in the new
test file were reviewed per project rule: all are `Regex.scan(re, str)` → `re |> Regex.scan(str)`
pipe-order changes, behaviour-preserving; none of the `case`→`if` class Styler's own README warns
can change semantics.

**Built-stylesheet check:** `mix assets.build`, then confirmed the shipped
`priv/static/assets/css/app.css` contains the band verbatim — `:where()` intact (LightningCSS did
not expand it) and the 662px block still immediately preceding the 480px block, so the **source-order
resolution of the deliberate overlap survives the build**. That mattered enough to check: the whole
`:where()` argument is worthless if the pipeline reorders or expands it.

**One pre-existing guard was rewritten, not suppressed.** `footer_overflow_test.exs`'s "no wider
media query hides the footer's controls" failed on this change. Inspected rather than worked around:
it asserted `t <= 480` for *every* `@media (max-width: Npx)` literal in the file — banning the mere
**existence** of a wider max-width block regardless of contents. That is the MECHANISM, not the
INVARIANT, and it is the same false-positive class `header_search_gutter_test.exs` already had to
correct once. Rewritten to assert what it actually protects: a wider max-width block may exist, but
may not `display: none` `.pk-footer-social` / `.pk-footer-right` / `.pk-footer-theme`. **Strictly
stronger than before** — the old check only ever inspected the *bodies* of min-width blocks and used
"no wide max-width block exists" as a proxy for the other half, so a wide max-width block that hid
the cluster would have walked through if the threshold were ever relaxed. RED-verified by injecting
`.pk-footer-right { display: none }` into the new band.

**HUMAN VERIFY: CONFIRMED FIXED (2026-08-25).** Deliberately not self-certified. Standing rule from
`search-right-align-mobile-cycle-3`, carried through the checkpoint: **measurement establishes
MECHANISM, never PERCEPTUAL SUFFICIENCY.** Headless Chrome is not iOS Safari, this project's primary
surface, and the two things measurement could not settle here were (a) whether the pill covering
"Quiénes Somos" at 481-570px reads as *backgrounded* or as *broken* on a real screen, and (b)
whether real-device font metrics keep the 1rem of reveal headroom sufficient. **The user has now
verified the fix on a real device and reports it fixed** — both open questions resolved in the
affirmative, and the sixth instance of the standing pattern (CSS-behaviour defects are closed by a
browser and a human, and only *fenced* by ExUnit) closes the way the five before it did.

**Artifacts re-verified at archive time**, per the rule that an unverified guard path is worse than
none because a future Phase-0 match surfaces it as if it were real: `mix test` on the three touched
test files → **20 tests, 0 failures**; full suite → **482 tests, 0 failures**. The corrected scope
claim was re-checked at the source rather than re-asserted: `grep -rn "nav_search" lib/` returns the
slot definition in `layouts.ex` and exactly **two** call sites — `catalog_live/index.ex` and
`catalog_live/show.ex`. Quiénes Somos is not among them.

## recurrence guard

**`test/pukllay_club_web/header_capacity_test.exs`** (new, 8 tests). Per the checkpoint instruction,
it **RECOMPUTES the row's arithmetic instead of pinning the content-dependent 662.3px literal.**

It parses `--pk-gutter`, `.pk-nav-inner { gap }`, `.pk-search-morph { width }` and
`.pk-search-morph.is-open { width }` out of the stylesheet, adds a measured content inventory
(isologo 36 / lockup 250 / links 166.3 / trigger 44 / label 154.7, each corroborated by a step in
the measured `fixedDemand` function), and asserts every declared breakpoint against the sum that
comes out — with the cliff/ramp asymmetry encoded (reveals need ≥1rem and <2rem of headroom; the
band ceiling must be exactly `ceil(required) - 1`).

**Content-dependence is fenced, which is the KB branch-F failure this bug's own blind_spot named.**
A tripwire pins the *exact* header copy the widths were measured from and fails with the new string
plus a RE-MEASURE instruction. Its first version used `String.contains?` and was **caught failing
its own mutation test**: containment is satisfied by "Quiénes Somos y Nuestra Historia", so it was
blind to *lengthening* a label — the only drift direction that actually widens the row. Rewritten to
extract and compare whole strings.

**7 of 8 RED-verified against the pre-fix tree** (the 8th, the copy tripwire, is green in both
states by design — it guards the *inputs* to the arithmetic, not the arithmetic). More importantly,
**10 mutations each fail exactly the intended test** — a guard that only fires on *absent* is a weak
guard:

| mutation | caught by |
|---|---|
| `position` moved onto `.is-open` (the C1 trap) | "positions the morph in BOTH states" |
| reservation `1.5rem` → `1rem` | "reserves the footprint" |
| band ceiling 680px (over-reaches) / 640px (leaves a gap) | "the band must end at …" (both directions) |
| `:where()` dropped | "holds `.pk-search-morph`'s own specificity" |
| wordmark reveal reverted to 48rem / set to 55rem (no headroom) | wordmark reveal (requirement / headroom) |
| label reveal 65rem (no headroom) | label reveal headroom |
| **pill retuned `17.5rem` → `20rem`** | **3 tests move at once — the proof it recomputes rather than pins** |
| nav label lengthened / tagline changed | copy tripwire, with before/after |

**Oracle type: derived (contract)** — stated honestly, and it is the same caveat every CSS-behaviour
session in this codebase has recorded. The true oracle is rendered geometry across 47 widths, which
ExUnit cannot observe; these assertions pin the arithmetic that geometry depends on. **Sixth
instance of the standing pattern: CSS-behaviour defects are closed by a browser and a human, and
only *fenced* by ExUnit.**

**Most likely regression path:** someone reading `margin-right: calc(44px + 1.5rem)` as an arbitrary
magic number and deleting it, which slides the category trigger under the closed search icon at
481-662px — invisible unless you look at that band with the search *closed*. The reservation test
recomputes it from the morph's own width plus the row gap and fails with both numbers. Second path:
"simplifying" `.pk-search-morph:where(.pk-nav-links ~ *)` to the plainer sibling form, which reads
identically and silently freezes the phone overlay.

**files_changed:** `assets/css/app.css`, `test/pukllay_club_web/header_capacity_test.exs` (new),
`test/pukllay_club_web/header_row_height_test.exs`, `test/pukllay_club_web/footer_overflow_test.exs`

**Evidence assets:** `.planning/debug/assets/search-pill-tablet-squeeze/FIX-*.png` — catalog closed
and open at 481 / 560 / 662 / 663 / 800 / 896 / 1056, Quiénes Somos closed at 481 / 662 / 800 / 896
/ 1056. The 662 vs 663 pair is the handover: nav links do not move and the pill is identical; the
only difference is whether the category glyph sits beside the pill or under it.

---

## Prevention (blameless postmortem)

### Branching 5-whys

Branched across the Ishikawa categories the `reasoning_checkpoint` already enumerated, rather than
collapsed into one linear chain — the AND-gate fired, so a single chain would misrepresent the bug.
No branch terminates at a person: where a branch reaches "someone got the arithmetic wrong", the
question asked next is *why was that error possible and why did nothing catch it*.

**Branch A — code (CSS): a single point of give with no floor.**
Why did the open pill collapse to 49px? The row hands it whatever is left over. → Why is it the only
one that gives? Every sibling is `flex-shrink: 0` / `flex: 0 0 auto`; only the pill is
`min-width: 0; flex-shrink: 1`. → Why is it arranged that way? **Two prior resolved sessions
deliberately made it so**: `header-height-wordmark-wrap` pinned the brand and nav links *because*
letting them shrink made them **reflow** and grew the header 65 → 129px, and
`search-expand-header-overlap` added the pill's shrink guard *specifically* to stop horizontal
overflow. → Why did two correct fixes compose into a defect? Because each was locally correct and
**neither owned the row's total**. The shrink guard was designed as a safety valve for a few px of
slack; **nothing anywhere bounded how much it could be asked to absorb.** → *Actionable condition:*
a sole yielder without a floor is safe only while total demand is bounded, and nothing bounded it —
so the guard silently converted "the row is over-subscribed" into "the input ceases to exist". The
fix therefore had to **remove demand** (or remove the pill from the competition) rather than re-grant
shrink or add a floor; both of those regress a resolved session, which is why the two obvious moves
were pre-blocked.

**Branch B — config (breakpoints): all three derived against the CLOSED row.**
Why is a *wider* viewport strictly worse (799 → 800px drops the pill 202.7 → 49px)? Because each
reveal fires at a width where the pill had just recovered. → Why do the reveals sit there? All three
of this header's breakpoints (480 / 48rem / 50rem) were derived against the **closed** row. → Why the
closed row? **Because it is the state that is simply *there*.** It is what renders on load, what a
screenshot captures, and what a `scrollWidth` bisection measures; the open state exists only after a
deliberate interaction, and nothing in the pipeline renders it. Each author measured the thing they
were changing, in the state in front of them. → Why did the one prior sighting not close it? **It was
seen — the 50rem comment records this very defect at "a functionally useless 2px" — and the response
was to move the breakpoint 768 → 800.** → *Actionable condition:* **moving a conventional breakpoint
relocates the cliff; only re-deriving it from the row's worst-case content arithmetic removes the
cliff.** The worst case is the OPEN state, which is exactly the state nobody was measuring.

**Branch C — data (content): the ceiling is a sum of rendered strings.**
Why is the boundary 662.3px rather than a round number? It is a sum of measured max-content text
widths (nav-link copy, wordmark, trigger label). → Why does that matter after the fix? Because a
future copy change moves the threshold **silently, with no diagnostic anywhere**. → *Actionable
condition:* a guard that pinned the 662.3px literal would rot into a lie the first time the copy
changed. The guard must **recompute** the arithmetic *and* **fence its inputs** — hence the copy
tripwire. (This is KB branch-F content-dependence, and this bug's own `blind_spots` named it before
the fix was written.)

**Branch D — process (scope): a defect inferred from a shared selector.**
Why did the investigation record Quiénes Somos as affected? It shares `.pk-nav-links` with the
catalog index. → Why was sharing a selector read as sharing a defect? Because the selector is what
the CSS fix keys on, so it reads as the natural unit of scope. → Why is that wrong here? Because the
defect requires the morph to **exist**, and slot presence is a **template** fact, not a stylesheet
fact: `header_inner/1`'s `:if={@nav_search != []}` never emits a `.pk-search-morph` on that page.
→ *Actionable condition:* **two surfaces sharing a selector is not two surfaces sharing a defect.**
Scope must be measured per surface. Note the mechanism that caught it: the user's checkpoint
instruction was *measure Quiénes Somos, do not assume it matches* — and measurement falsified the
inference. The prior session had in fact recorded this correctly ("`/quienes-somos` has no search
slot"); this session's scope note contradicted it without checking. **Recorded as corrected, not
silently dropped**, because the reusable warning is the inference itself.

**Branch E — code (test guards): a guard that pinned MECHANISM, not INVARIANT.**
Why did a correct fix fail a green pre-existing test? `footer_overflow_test.exs` asserted `t <= 480`
for *every* `@media (max-width: Npx)` literal in the stylesheet — banning the **existence** of any
wider max-width block regardless of its contents. → Why was it written that way? "No wide max-width
block exists" was a cheap proxy for "no wide block hides the footer controls". → Why is the proxy
worse than the real assertion? **It fails in both directions**: a false positive on a header-only
change that never mentions the footer, and a false *negative* — the old check only ever inspected the
bodies of `min-width` blocks, so a wide max-width block that genuinely hid the cluster would have
walked through if the threshold were ever relaxed. → *Actionable condition:* **a guard must assert
the invariant it protects, not the implementation that happened to satisfy it.** Second instance in
this repo; `header_search_gutter_test.exs` needed the identical correction (it pinned the literal
`inset` shorthand instead of "both horizontal edges derive from `--pk-gutter`").

**Environment: eliminated, not deferred.** Browser/zoom/scrollbar effects were ruled out during
investigation — the closed-form model is exact at 24/24 widths across 3 reps with `--hide-scrollbars`
set and no overflow anywhere.

### Why wasn't this caught?

**No gate existed for OPEN-state header capacity — and that is the whole finding, because it is
precisely why three successive breakpoint fixes each left the cliff standing.** Every existing header
and footer guard measures the **closed** row: `header_row_height_test.exs`, `footer_overflow_test.exs`
and the `scrollWidth` bisection recorded in the 50rem comment all reason about the default render.
The open state is one class toggle away and is where the row's demand is 251px higher, so the single
most over-subscribed configuration in the entire header was the one configuration nothing ever
looked at.

*Code review* had no chance by inspection: the arithmetic error is a **missing term in a sum written
in prose** (`.pk-cat-trigger`, 44px + its 24px gap = 68px), and the sum *looks* complete and
self-consistent — you can only catch it by re-deriving it against the live row inventory. *Config:*
`mix quality` (hex.audit, deps.audit, format+Styler, credo --strict, sobelow, test) parses Elixir
sources only and never evaluates `app.css`; Tailwind v4/LightningCSS exits 0 **correctly**, because
an over-subscribed flex row is valid CSS, not an error, not a warning, not a degraded state. *UAT:*
blind for the same mundane reason as `mobile-search-expand-jump` — **on a phone and on a desktop the
search box works perfectly.** The defect lives entirely in the tablet band between them, and both
ends of the range that a developer actually looks at are clean. Worse, the failure is
**non-monotonic**: the natural way to sanity-check a responsive bug is to widen the window, and
widening it *through 800px makes this bug dramatically worse*, which reads as noise rather than as
signal. *Process:* the defect had already been **observed and recorded in the repository in plain
language** (the 50rem comment, "squeezed down to a functionally useless 2px") and was answered by
moving the breakpoint. **Third consecutive session in this header where the diagnosis was already
committed to the repo and still did not stop the bug** — which promotes the standing lesson from
anecdote to rule: *a written observation is not a guard; only an executable assertion is.*

### Recurrence guard

**`test/pukllay_club_web/header_capacity_test.exs`** (new, 8 tests) — **re-verified at archive time:
`mix test` on the three touched files → 20 tests, 0 failures; full suite → 482 tests, 0 failures.**

It **recomputes the row's arithmetic instead of pinning the content-dependent 662.3px literal**
(the checkpoint instruction, and Branch C's actionable condition): it parses `--pk-gutter`,
`.pk-nav-inner { gap }` and both morph widths out of the stylesheet, adds a measured content
inventory each term of which is corroborated by a step in the measured `fixedDemand` function, and
asserts every declared breakpoint against the sum that comes out — **with the cliff/ramp asymmetry
encoded**: the two reveals must carry ≥1rem and <2rem of headroom (a reveal detonates), while the
band ceiling must be exactly `ceil(required) - 1` (a ramp degrades gracefully, and headroom there
would overlay widths that fit).

**Mutation-verified, which is the part that matters** — 7 of 8 RED against the pre-fix tree, and
**10 mutations each fail exactly the intended test**, including both directions of the band ceiling
(680px over-reaches, 640px leaves a gap), the C1 `position`-on-`.is-open` trap, dropping `:where()`,
and reverting either reveal. The load-bearing one: **retuning the pill `17.5rem` → `20rem` moves
three tests at once**, which is the proof it recomputes rather than pins. The 8th test is the **copy
tripwire**, green in both states by design because it guards the *inputs* to the arithmetic; its
first version used `String.contains?` and was **caught failing its own mutation test** — containment
is satisfied by "Quiénes Somos y Nuestra Historia", so it was blind to *lengthening* a label, the
one drift direction that actually widens the row.

**Second guard, strengthened not suppressed:** `footer_overflow_test.exs` now asserts the invariant
(a wider max-width block may exist but may not `display: none` the footer control cluster) instead of
the mechanism, RED-verified by injecting `.pk-footer-right { display: none }` into the new band.

**Documentation-as-guard:** four wrong derivations were corrected in place rather than left standing
(`app.css`'s 808.3px sum, `.is-open`'s "roughly 790px", `.pk-cat-trigger-label`'s "below 50rem", and
`header_row_height_test.exs`'s comment carrying the same 808.3px error). Leaving a wrong derivation
in the file is the previous session's failure with the polarity flipped: there, a correct diagnosis
sat in the repo and did not prevent the bug; here, an *incorrect* one sat in the repo and actively
caused the next author to reproduce it.

**Oracle type: derived (contract)** — stated honestly. The true oracle is rendered geometry across 47
widths, which ExUnit cannot observe; these assertions pin the arithmetic that geometry depends on.
**Sixth instance of the standing pattern: CSS-behaviour defects are closed by a browser and a human,
and only *fenced* by ExUnit.**

**Most likely regression path:** someone reading `margin-right: calc(44px + 1.5rem)` as an arbitrary
magic number and deleting it, which slides the category trigger under the closed search icon at
481-662px — invisible unless you look at that band with the search **closed**. The reservation test
recomputes it from the morph's own width plus the row gap and fails with both numbers. Second path:
"simplifying" `.pk-search-morph:where(.pk-nav-links ~ *)` to the plainer sibling form, which reads
identically and silently freezes the phone overlay at these values.
