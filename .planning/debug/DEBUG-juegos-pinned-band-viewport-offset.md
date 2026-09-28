---
status: diagnosed
trigger: "Diagnose UAT gaps G-01.8.3-2d and G-01.8.3-3 (pinned/sticky geometry on /admin/juegos), goal: find_root_cause_only"
created: 2026-09-27T00:00:00Z
updated: 2026-09-27T00:00:00Z
---

## Current Focus

bug_class: Bohrbug — fully deterministic, reproduces on every scroll-down past 140px,
  in headless Chrome at 390x844 exactly as on the real Brave/Android device.

reasoning_checkpoint:
  hypothesis: |
    The section captions pin at a STATIC `top: var(--pk-juegos-pinned-h)` = 60px, a
    reservation for a search row whose on-screen presence is DYNAMIC (hidden by
    `transform: translateY(-100%)` whenever `admin_list.js` sees a scroll-down past
    140px). Nothing couples the two, so on scroll-down the 60px reservation becomes an
    empty window and the band strands 60px below the viewport top with live list rows
    scrolling through the gap.
  confirming_evidence:
    - "Measured live: searchHidden=true, searchRect top=-60 bottom=0 (zero visible px), band top=60 bottom=104."
    - "elementFromPoint(195, y) for y in {1,15,30,45,59} all resolve inside .pk-admin-row while the band is pinned."
    - "Differential: scroll DOWN -> searchRect -60..0, bandTop 60 (orphan strip). Scroll UP -> searchRect 0..60, bandTop 60 (flush). bandTop never moves; only the search row does."
  falsification_test: |
    If bandTop moved with the search row's visibility (or if some ancestor overflow were
    the real cause), bandTop would differ between the scroll-down and scroll-up states.
    It does not — 60 in both. And scrollAncestors=[] rules out the overflow explanation.
  fix_rationale: n/a (find_root_cause_only)
  blind_spots: |
    Tested at 390x844 and 375x844 in headless Chrome only; the real device is Brave on
    Android. Both produce identical numbers (screenshot band offset back-solves to ~60.7
    CSS px at DPR 2.77), so engine divergence is not implicated, but iOS Safari sticky
    behaviour was not exercised.
  candidate_causes:
    - "code/CSS: `.pk-admin-juegos-section-heading-wrap { top: var(--pk-juegos-pinned-h) }` — a static sticky offset (juegos.css:186)"
    - "code/JS: `admin_list.js` onScroll sets `data-pinned-hidden` on scroll-down, hiding the row the 60px reserves for — and never writes back to the token"
    - "config/token: `--pk-juegos-pinned-h: 60px` is a declared constant, never recomputed"
    - "environment: ELIMINATED — reproduces identically in headless Chrome and on real Brave/Android"
    - "data: ELIMINATED — reproduces with the full dev catalog and is independent of row content"
  and_gate: |
    YES — the orphan strip requires BOTH conditions simultaneously: (1) the static 60px
    caption offset AND (2) the search row's hide-on-scroll-down transform. Neutralising
    either alone removes the symptom (proven by the scroll-up control, where condition 2
    is absent and the cluster reads correctly). Two contributing causes, both necessary.
    A SEPARATE, single-cause defect also exists on the FIRST section only (band overhang,
    below) and is not part of this AND.

## Symptoms

expected: |
  G-01.8.3-2d: when a section caption pins it is fixed to the TOP of the viewport
  (below the pinned search row); no game rows between viewport top and the band.
  G-01.8.3-3: the search row stays pinned at viewport top, the caption sits flush
  beneath it, no list content above the cluster, no list row occluded behind it.
actual: |
  Real device (Brave, 390px-class, 2026-09-27) and reproduced in headless Chrome:
  the «JUEGOS DEL CLUB 385» band is pinned but 60px down the viewport. No search row
  visible at all. A complete game row occupies the 60px strip above the band. The row
  below is clipped behind it.
errors: none — pure layout defect; `admin_shell.mjs`'s Juegos block reports every
  assertion PASSING against this exact screen.
reproduction: |
  /admin/juegos at 390x844 over a staff session; scroll DOWN in small increments past
  ~140px until a section caption pins. Do NOT focus the search input.
started: |
  Latent since the two mechanisms first coexisted: plan 01.8.3-01 (D-07/D-08) added the
  hide-on-scroll-down search wrap; plan 01.8.3-03 (D-15) added
  `--pk-juegos-pinned-h: 60px` + the caption sticky offset.

## Eliminated

- hypothesis: "The search row has no `position: sticky` / was never meant to pin."
  evidence: |
    `juegos.css:44-50` declares `position: sticky; top: 0; z-index: 15`. Measured in the
    scroll-UP control: searchRect top=0 bottom=60 — it pins correctly. It is *deliberately
    hidden* on scroll-down by `[data-pinned-hidden] { transform: translateY(-100%) }`
    (juegos.css:52-54), driven by `admin_list.js` onScroll. Computed transform measured as
    `matrix(1, 0, 0, 1, 0, -60)`.
  timestamp: 2026-09-27

- hypothesis: "An unexpected `overflow` (or transform/filter/contain) on an ancestor makes
  the sticky elements stick to the wrong scroll container — the classic sticky trap."
  evidence: |
    Live audit walking every ancestor of `.pk-admin-juegos-sections` up to `<html>`:
    `scrollAncestors: []` (no non-visible overflow, no transform, no filter, no contain, no
    container-type, no perspective). `getComputedStyle(html).overflowY = visible`,
    `body.overflowY = visible`, `document.scrollingElement === document.documentElement`.
    Both sticky elements reach their declared offsets exactly (0px and 60px). The scroll
    container is the document; sticky is working exactly as authored.
  timestamp: 2026-09-27

- hypothesis: "The band is 44px but the header reserves 44.2px, so the overlap on the
  screenshot's section comes from the band overhanging its own box."
  evidence: |
    For `juegos-section-published` (`--pt: 26px`) the measured
    `bandOverhangBelowStickyBox = -0.2px` — no overhang. The occlusion visible in the
    screenshot for THAT section is ordinary sticky overlap of scrolling content.
    The overhang defect is real but exists only on the FIRST section (`--pt: 14px`),
    where it measures +11.8px. Recorded as a separate, secondary cause.
  timestamp: 2026-09-27

- hypothesis: "Engine divergence (Brave/Android vs headless Chrome) — the repo has prior
  form here (Phase 01.3's WebKit-only toggle defect)."
  evidence: |
    The real-device screenshot's band offset back-solves to ~60.7 CSS px (140 displayed px
    x 1.2 scale / DPR 2.769 at 1080 physical / 390 CSS), matching the headless measurement
    of exactly 60px. Same defect, same magnitude, both engines.
  timestamp: 2026-09-27

## Evidence

- checked: `assets/css/admin/juegos.css:31-54, 184-188`
  found: |
    `.pk-admin-juegos { --pk-juegos-pinned-h: 60px }`
    `.pk-admin-juegos-search-wrap { position: sticky; top: 0; z-index: 15 }`
    `.pk-admin-juegos-search-wrap[data-pinned-hidden] { transform: translateY(-100%) }`
    `.pk-admin-juegos-section-heading-wrap { position: sticky; top: var(--pk-juegos-pinned-h); z-index: 10 }`
  implication: the caption offset is a static constant; the row it reserves for is not.

- checked: `assets/js/hooks/admin_list.js` (`onScroll`, `setupPinObserver`)
  found: |
    `onScroll` sets `data-pinned-hidden` when `goingDown && scrollY > 140`; removes it when
    the search input is focused or `scrollY <= 140`. `this.pinnedBandPx` is measured from
    the wrap's rect but used ONLY for the observer's `rootMargin`/threshold. No code path
    anywhere writes `--pk-juegos-pinned-h` (grep across assets/, lib/, test/ confirms the
    token is declared once and read twice, never written).
  implication: the two mechanisms are structurally uncoupled.

- checked: LIVE, headless Chrome 390x844, staff session, REAL incremental scroll-down
    (45px steps, no focus() hack), section `juegos-section-published` pinned
  found: |
    scrollY=641
    searchHidden=true, searchRect { top: -60, bottom: 0 }, transform matrix(1,0,0,1,0,-60)
    headerBox { top: 60, bottom: 104.2, h: 44.2 }
    ::before { top: 0px, bottom: 0.2px, bg: rgb(241,236,253) }
    band { top: 60, bottom: 104, h: 44 }
    bandOverhangBelowStickyBox = -0.2px
    bandSearchGap, computed EXACTLY as admin_shell.mjs computes it = 60px
    elementFromPoint(195, {1,15,30,45,59}) -> all inside .pk-admin-row
      "Abomination: El heredero de Frankenstein"
    rows straddling the band: "Abomination" hidden 11.9px; "Abyss" hidden 32.1px,
      only 31.9px of its 64px visible below the band
    scrollPaddingTop(html) = auto; scrollMarginTop(row) = 0px
  implication: |
    The whole 60px strip between the viewport top and the pinned band is live list
    content, and the shipped guard's own assertion value in this state is 60px — 120x its
    own ±0.5px tolerance. The screenshot's clipped row is reproduced exactly (a 64px row
    with ~32px visible below the band = year + a sliver of cover).

- checked: LIVE, same setup, first section `juegos-section-draft` (Borradores) expanded
    and pinned by a real scroll-down
  found: |
    scrollY=520, searchHidden=true, searchRect { top: -60, bottom: 0 }
    --pt = 14px
    headerBox { top: 60, bottom: 92.2, h: 32.2 }
    ::before { top: 0px, bottom: -11.8px }
    band { top: 60, bottom: 104, h: 44 }
    bandOverhangBelowStickyBox = +11.8px
    bandSearchGap as the shipped probe computes it = 60px
    elementFromPoint at y=1/15/30 -> row "Atiwa"; y=45 -> row "bot factory"
    row "bot factory" (64px) hidden 39.7px behind the band, 0px visible below it
  implication: |
    Second, independent defect, FIRST SECTION ONLY: the sticky header reserves 32.2px of
    viewport but paints 44px of opaque tint. 11.8px of that band lies outside its own
    sticky box and covers flow content no scroll offset can compensate. Algebra:
    `bottom: calc(var(--pt) - 2 * var(--bandp))` with `--bandp = (44 - 18.2)/2 = 12.9px`
    resolves to `--pt - 25.8`, i.e. NEGATIVE for any `--pt < 25.8px`. Measured -11.8 at
    `--pt: 14` and +0.2 at `--pt: 26` — matching the formula exactly.

- checked: LIVE differential control — scroll DOWN to 1600, then UP 120px
  found: |
    scrollY=1101, searchHidden=false, searchRect { top: 0, bottom: 60 },
    juegos-section-published band { top: 60, bottom: 104, h: 44 } -> gap 0px
  implication: |
    The band's viewport position is IDENTICAL (60) in the broken and the correct state.
    Only the search row moves. This is the single cleanest proof that the caption's
    offset is the static half of the pair and never chases the row.

- checked: `test/visual/admin_shell.mjs:1227-1254` (`measureJuegosSectionPinned`)
  found: |
    After confirming `data-pinned="true"`, the probe calls
    `searchInputEl.focus({ preventScroll: true })` and dispatches a synthetic
    `new Event('scroll')` specifically to drive `admin_list.js`'s `focused` branch and
    REMOVE `data-pinned-hidden` — its own comment says this is "needed for the
    band/search-row adjacency measurement".
  implication: |
    Every band/search-row number the guard reports is measured in a state a scrolling user
    never occupies. The probe manufactures the passing condition.

- checked: LIVE run of the shipped probe today (`PROBE_BASE_URL=... node test/visual/admin_shell.mjs`)
  found: |
    juegos first-section (Borradores) band: height=44px (top=60 bottom=104) bg=rgb(241, 236, 253) search-row gap=0px row-height=64px searchHidden=false
    juegos later-section (Juegos del club) band: height=44px (top=60 bottom=104) bg=rgb(241, 236, 253) search-row gap=0px row-height=64px searchHidden=false
    juegos band heights: first=44px later=44px delta=0px
    juegos ink gap-above cross-section: first=13.5px later=13.5px delta=0px
  implication: |
    The passing guard PRINTS the defect's exact magnitude — `top=60` — and prints
    `searchHidden=false` (the state it manufactured), and asserts on neither. Every Juegos
    geometry assertion passed. (Three unrelated FAILs appeared in today's run — editor-URL
    resolution, a 360px keel transient, and the sheet-open step — none touch this block.)

## Resolution

root_cause: |
  PRIMARY (both gaps, AND-gated — two simultaneously-necessary conditions):
  (1) `assets/css/admin/juegos.css:186` pins every section caption at a STATIC
      `top: var(--pk-juegos-pinned-h)` = 60px (declared once at juegos.css:33), reserving
      the search row's full rendered height; AND
  (2) `assets/css/admin/juegos.css:52-54` + `assets/js/hooks/admin_list.js`'s `onScroll`
      translate that same search row fully off-screen (`translateY(-100%)`, measured
      `matrix(1,0,0,1,0,-60)`) on every scroll-down past 140px.
  Nothing couples them — `--pk-juegos-pinned-h` is never written by any code. On
  scroll-down the 60px reservation becomes an empty window: the band strands at y=60 and
  60px of live list rows render above it. Measured: band top=60, searchRect -60..0,
  elementFromPoint at y=1..59 all inside `.pk-admin-row`.

  SECONDARY (first section only, single cause, additional occlusion):
  `assets/css/admin/juegos.css:339` — the pinned band's
  `bottom: calc(var(--pt) - 2 * var(--bandp))` resolves NEGATIVE whenever
  `--pt < 2 x --bandp` (25.8px). At the first section's `--pt: 14px` this is -11.8px, so
  the sticky header reserves a 32.2px box while painting a 44px opaque band — 11.8px of
  tint outside its own sticky box, covering flow content. Measured -11.8px at `--pt: 14`,
  +0.2px at `--pt: 26`.
fix: n/a — goal was find_root_cause_only
verification: n/a
files_changed: []
