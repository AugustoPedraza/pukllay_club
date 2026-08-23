---
status: resolved
trigger: "Pre-existing issue surfaced as a disclosure during the search-expand-header-overlap debug session (see .planning/debug/resolved/search-expand-header-overlap.md once archived): at roughly 481-750px viewport width, opening the header search grows the header from 65px to 97px because the brand wordmark (PUKLLAY CLUB + tagline in brand_logo/1, lib/pukllay_club_web/components/layouts.ex) wraps onto a second line. Measured identically before and after that session's fix, so this is not a regression from it — it's an independent, pre-existing bug. User decided to fix it now rather than leave it or just log it."
created: 2026-08-23T00:00:00.000Z
updated: 2026-08-24T00:10:00Z
---

## Current Focus

bug_class: Bohrbug — deterministic CSS layout; reproduces on every load at any width in the band, no timing/concurrency component. Route: deterministic reproduction -> binary search over viewport width -> differential (which flex item yields).

hypothesis: CONFIRMED — see Resolution.root_cause. The brand lockup is simultaneously shrinkable and wrappable inside a single-line auto-height flex row, so any row over-subscription is absorbed as wordmark text wrap, which the row's height then inherits.
test: applied fix + differential re-measure of the same sweep (S0 broken vs S1 fixed), on the live app, both header variants.
expecting: header height constant across closed/open at every width, wordmark line boxes never exceeding 1/1, no horizontal overflow introduced.
next_action: NONE — session closed. Guardrail accepted, human verification confirmed, fix committed, session archived, knowledge base entry written.

reasoning_checkpoint:
  hypothesis: "`.pk-nav-inner` is a nowrap, auto-height, `align-items: center` flex row. Its brand item is shrinkable (`flex: 0 1 auto` via `flex-initial` on header_inner/1's wrapper div) and its text is wrappable (`white-space: normal`). When the row's natural width exceeds the viewport, the brand shrinks below its 250px max-content width and the 206px tagline reflows onto extra line boxes; the row, having no fixed height, grows to match, and `--pk-header-h` publishes the inflated height."
  confirming_evidence:
    - "Direct line-box counts, not inferred from height: `Range.getClientRects().length` over the tagline returns 1 at ≥850px, 2 at 481-790px open, and 3 at 481-560px open — stepping in exact lockstep with header height 65/81/97/129px."
    - "Natural-width arithmetic predicts both failure boundaries to the pixel: 572.3px closed and 808.3px open. Measured recovery happens between 560 and 600 (closed) and between 790 and 850 (open). Nothing about those numbers is a breakpoint — they are the sum of the row's content."
    - "Computed style on the live brand `<a>` is literally `flex: 0 1 auto` with `white-space: normal` — both preconditions of the mechanism are observed, not assumed."
    - "Brand width is measured shrinking below max-content exactly where the wrap appears: 250px natural -> 195.2px at 481 closed -> 118.7px at 481 open, bottoming out at the wordmark's min-content (79.1px = the word 'MODERNOS')."
    - "The ≤480px branch, which is the one place the header wordmark is hidden, is the one band that is immune — removing the wordmark from the row removes the failure."
    - "Live app and static reconstruction agree value-for-value at all 13 widths ≥481px, so this is a property of the shipped page, not of a harness."
  falsification_test: "Pin the two text items (brand + nav links) so they can neither shrink nor wrap, and guarantee the row has capacity by hiding the wordmark below the width where it fits. If the header height still varies between closed and open at ANY width, or wordmark line boxes still exceed 1/1, the mechanism is not what I claim and the diagnosis is wrong."
  fix_rationale: "The fix removes the mechanism's two preconditions rather than patching the symptom's pixel values. (1) `white-space: nowrap` + non-shrinking brand and nav links means the row's text can no longer reflow at all, so the row's height becomes structurally constant — this is what makes 'header height changes' impossible rather than merely unlikely. (2) With text pinned, the row must actually have room, so the wordmark is hidden below the measured width at which the row can seat it — reusing the treatment `@media (max-width: 480px)` already applies, just at the width the arithmetic actually calls for instead of 480px. The search pill is left as the single element allowed to yield, which is the sibling session's already-accepted shrink guard. Patching only the reported 481-750px open-state symptom (e.g. a one-off height clamp) would leave the closed-state 481-560px failure and the 750-808px tail in place."
  blind_spots:
    - "Hiding the header wordmark from 481px up to 768px is a visible DESIGN change on tablet widths, not just a bug fix. Measurement can prove the row cannot fit the wordmark there; it cannot decide whether the user prefers that to the alternative (a second breakpoint near 576px plus extending the mobile full-width search overlay up to 768px, which keeps the wordmark visible from 576px). Must be surfaced at the human-verify checkpoint, not decided silently."
    - "Pinning brand and nav links with `flex-shrink: 0` trades a wrapping failure for a horizontal-overflow failure if the row's natural content ever grows again (a third nav link, a longer tagline). That is a deliberate trade — a visible scrollbar is diagnosable where silent header inflation was not — but it is a real behavioural change worth stating."
    - "Text metrics depend on Bebas Neue/Inter actually loading. The harness loads the real self-hosted woff2 files, but a client on a slow connection renders the fallback font briefly during swap; if the fallback is wider, the row could be momentarily over-subscribed. `nowrap` means that now shows as brief overflow rather than a header height jump, which is the better failure, but it is untested."
    - "Not verified on a real touch device — measured in headless Chrome only, at devicePixelRatio 1."
  candidate_causes:
    - "code (CSS + markup): brand and nav links are shrinkable+wrappable in an auto-height single-line flex row, and no rule hides or pins them above 480px — CONFIRMED, and sufficient to explain every measured value"
    - "data (content): the tagline string 'JUEGOS DE MESA MODERNOS' is 206px, the widest line in the lockup by 95px, and is what sets the brand's 250px max-content width — CONTRIBUTING. It sets WHERE the band starts, not WHETHER the bug exists; a shorter tagline narrows the band but 'PUKLLAY CLUB' (111.3px) would still wrap eventually. Not fixed by editing copy — that would be tuning the trigger, not removing the mechanism."
    - "config (build pipeline): Tailwind v4/LightningCSS dropping or reordering a header rule, as in the sibling session — REFUTED. The built stylesheet contains the header rules intact, the ≤480px wordmark rule demonstrably applies, and the live app matches the static reconstruction exactly."
    - "environment (browser/engine): engine-specific flex or text-wrap behaviour — REFUTED. This is spec-defined flex shrink plus normal line breaking, it is fully deterministic across reloads, and the user observed it on real devices before any harness existed."
  and_gate: "YES — two conditions must hold simultaneously: (a) the row is over-subscribed, AND (b) the brand/nav-links text is allowed to reflow. Neither alone produces the symptom: below 480px the row is over-subscribed but the wordmark is hidden, so nothing wraps; above 808px the text is free to reflow but there is room, so nothing wraps. This is why the fix deliberately attacks both — pinning the text (removes b) makes the failure mode structural rather than silent, and restoring capacity (removes a) means the pinned text never has to overflow. Fixing only one leaves a live failure mode: pinning text alone converts the wrap into horizontal overflow at 481-572px, and restoring capacity alone leaves the wrap one content change away from returning."

## Symptoms

expected: The header's height (and the `--pk-header-h` CSS var it publishes via the `.CatalogNav` ResizeObserver hook) should stay stable when the search toggle opens, at every viewport width — matching the behavior already confirmed fixed at <=480px (mobile) and at desktop widths.
actual: At approximately 481px-750px viewport width, opening the search causes the brand wordmark ("PUKLLAY CLUB" + tagline, in `brand_logo/1`) to wrap onto a second line, growing the header's rendered height from ~65px to ~97px. This shifts page content below the sticky header.
errors: None expected — this is a pure CSS/layout issue, same class of bug as the sibling session (no JS errors).
reproduction: Load any page with the header search (e.g. the catalog/ludoteca page), resize the browser to a width between ~481px and ~750px, then open the search toggle. Header height grows visibly.
started: Pre-existing — present before and after the search-expand-header-overlap fix (2026-08-23), not a new regression. Likely present since the search-morph feature and the `@media (max-width: 480px)` mobile override were first built, since that override only covers <=480px and this gap sits just above it.

## Eliminated

- hypothesis: This is a gap between the `@media (max-width: 480px)` mobile override and the `sm:` (640px) Tailwind breakpoint — i.e. a missing rule in a 481-640px window.
  evidence: The failing band does not end at 640px. Measured on the live app, the index header still inflates on open at 640/700/750/790px (81px) and only returns to a stable 65px at 850px. The band's upper edge is set by arithmetic, not by any breakpoint: the row needs brand 250 + gap 24 + links 166.3 + gap 24 + pill 280 + gutters 64 = 808.3px, and 808.3 is exactly where the measurements flip. There is no "missing breakpoint rule" — there is a capacity shortfall.
  timestamp: 2026-08-23T23:30:00Z

- hypothesis: The bug is confined to the OPEN state — the header is correct at rest and only grows when the search expands.
  evidence: Refuted on the live app. On the catalog index at 481/500/520/560px the header is already 81px CLOSED (inner 64px, brand 64px, tagline on 2 line boxes) before the search is ever touched. Opening then takes it to 129px. The prior session missed this because its harness used the short tagline "Ludoteca"; the real header renders brand_logo/1's default "JUEGOS DE MESA MODERNOS", which is 206px wide and is the widest line in the lockup.
  timestamp: 2026-08-23T23:32:00Z

- hypothesis: `.pk-search-morph.is-open`'s shrink guard (`min-width: 0; flex-shrink: 1`, added by the sibling session) is what causes the wrap, by letting the row stay over-subscribed instead of overflowing.
  evidence: Refuted — the guard is load-bearing in the opposite direction and the wrap survives without it. The closed state carries no `.is-open` rule at all and still wraps at 481-560px. The wrap is driven by the brand being shrinkable, not by the pill being shrinkable.
  timestamp: 2026-08-23T23:34:00Z

- hypothesis: The wordmark wraps because the row's flex line runs out of room and `.pk-nav-inner` wraps its items.
  evidence: Refuted — `.pk-nav-inner` is `display: flex` with the initial `flex-wrap: nowrap`; no rule sets `flex-wrap`. The row never breaks into two flex lines. What grows is a single flex item (the brand) whose own TEXT wraps internally, and `align-items: center` on an auto-height row then stretches the row to that item's height.
  timestamp: 2026-08-23T23:36:00Z

## Evidence

- timestamp: 2026-08-23T23:05:00Z
  checked: Knowledge base at .planning/debug/knowledge-base.md
  found: Still does not exist — the sibling session (search-expand-header-overlap) is `awaiting_human_verify`, so it has not archived or written its KB entry yet.
  implication: No known-pattern shortcut. Full investigation required. Note for archival: this session and the sibling both need KB entries, and the sibling's entry must be written first since it owns the KB's creation.

- timestamp: 2026-08-23T23:08:00Z
  checked: Rebuilt the measurement harness from scratch. The prior session's measure.js is unrunnable (it requires a `./ws-min.js` that does not exist and calls `window.__measure`/`window.__open`, which its repro.html never defines). New harness serves the page over HTTP rooted at priv/static so `/assets/css/app.css` AND the self-hosted `/fonts/*.woff2` resolve exactly as in the app, and sets viewport width via CDP `Emulation.setDeviceMetricsOverride` instead of `--window-size`.
  found: Both fidelity gaps in the prior harness are now closed — real Bebas Neue/Inter metrics (text metrics ARE the bug here, so a fallback font would have invalidated the run) and no ~500px window-size floor, so 375-470px is measurable directly rather than through an iframe.
  implication: Measurements below are trustworthy at every width, including the ≤480px branch.

- timestamp: 2026-08-23T23:12:00Z
  checked: The harness's markup fidelity against source — layouts.ex header_inner/1 (386-437) and brand_logo/1 (45-72), plus the two real call sites, CatalogLive.Index (433-459: nav_links + nav_search, no crumb) and CatalogLive.Show (173-190: crumb + nav_search, no nav_links).
  found: The prior session's repro.html rendered the tagline as "Ludoteca". The real header calls `<.brand_logo />` with no tagline attr, so it renders the attr default "JUEGOS DE MESA MODERNOS". Only the FOOTER overrides the tagline (to "Conectá jugando", layouts.ex:557).
  implication: The prior session measured a brand lockup roughly 55px narrower than the one that actually ships. That single substitution is why it recorded a mild "65px -> 97px in 481-750px" residual instead of the real, larger failure — and why it never saw the closed-state half of the bug at all.

- timestamp: 2026-08-23T23:20:00Z
  checked: Width sweep 375-1280px on the LIVE running app (mix phx.server on :4321, LiveView connected, morph opened by clicking the real `.pk-search-morph-toggle` so the actual .CatalogNav hook drives it), catalog index. Transitions disabled so every value is final-state.
  found: Header height (and the `--pk-header-h` var, which tracks it exactly) by width — closed/open. 375: 108/108. 470: 108/108. 481: 81/129. 500: 81/129. 520: 81/129. 560: 81/97. 600: 65/81. 640: 65/81. 700: 65/81. 750: 65/81. 790: 65/81. 850: 65/65. 1280: 65/65. Wordmark line-box counts (name/tagline) track it 1:1 — 481 closed 1/2, 481 open 2/3, 560 open 1/3, 600-790 open 1/2, 850+ 1/1.
  implication: Three findings. (1) The reported "65 -> 97" understates it: the real worst case is 65 -> 129px at 481-520px. (2) The band's upper edge is 808px, not 750px. (3) The header is ALREADY broken at rest (81px) at 481-560px — the reported open-state growth is only the louder half of one defect.

- timestamp: 2026-08-23T23:22:00Z
  checked: Same sweep run against the static reconstruction and against the live app, value by value.
  found: Every header/inner/brand/wordmark/links/morph number matches EXACTLY at all 13 widths ≥481px (e.g. 481 open: header 129, inner 112, brand 118.7x112, wordmark 79.1, links 116.3, morph 315..449). Live-only differences are explained: below 481 the live `#app-header` also contains the `subnav` chip row (+47px), which the reconstruction omits.
  implication: The static harness is validated against reality, and the prior session's explicitly-stated blind spot ("measured on a static reconstruction, not the running LiveView") is closed for this bug. Also confirms `--pk-header-h` publishes the inflated height, so page content below the sticky header really does shift — the reported downstream symptom is real, not cosmetic.

- timestamp: 2026-08-23T23:26:00Z
  checked: Natural (max-content) widths of every header row item, measured by cloning each out of the flex context on the live page, plus the row's own box values and the brand's computed flex properties.
  found: brand lockup 250px (isologo 36 + gap 8 + wordmark 206); nav links 166.3px; wordmark line widths — "PUKLLAY CLUB" 111.3px, "JUEGOS DE MESA MODERNOS" 206px; `.pk-nav-inner` gap 24px, padding 32px each side; brand `<a>` computed `flex: 0 1 auto`, `white-space: normal`.
  implication: The mechanism is now arithmetic, not inference. The TAGLINE is the widest line in the lockup by 95px, so it is the first thing to wrap and it alone sets the brand's 250px max-content width. Required row width = 250 + 24 + 166.3 + 24 + (44 closed | 280 open) + 64 gutters = 572.3px closed / 808.3px open. Both thresholds match the measured flip points exactly (closed recovers between 560 and 600; open recovers between 790 and 850).

- timestamp: 2026-08-23T23:28:00Z
  checked: Detail-page variant (crumb instead of nav links) across the same sweep.
  found: Closed is correct at every width ≥481 (65px). Open inflates to 81px from 481 to 640 and is correct from 680 up. The crumb (`flex: 1; min-width: 0`) collapses to 0px width before the brand yields.
  implication: Same root cause, narrower band — the crumb can shrink to nothing where nav links cannot, so the detail row needs 250+24+0+24+280+64 = 642px. Confirms the mechanism generalises across both header variants and that the failing band is a pure function of the row's content, not a property of one page.

- timestamp: 2026-08-23T23:29:00Z
  checked: Which elements actually exceed the document's client width in the failing band (shallowest offenders first), live app.
  found: `documentElement.scrollWidth` is pinned at 653px for every viewport from 481 to 652px, and the shallowest offenders are `.pk-footer-right` (depth 5, w 602.8) -> `.pk-footer-meta` -> `.pk-bgg-note`. The header row itself never overflows — it absorbs the pressure by wrapping instead. At ≥700px the overflow is gone.
  implication: A SEPARATE, pre-existing horizontal-overflow bug lives in the FOOTER at 481-652px (the footer only switches to its column layout at ≤480px, so between 481 and 652 its one-row layout is wider than the viewport). It is present in the closed state with the search untouched, has a different root cause and a different owner element, and is therefore deliberately OUT OF SCOPE for this session — recorded here so it is not lost, and surfaced to the user rather than silently bundled into this fix.

- timestamp: 2026-08-23T23:40:00Z
  checked: Why `.pk-nav-links` cannot simply be left to absorb the shortfall — measured its width in the failing band.
  found: Nav links shrink from their natural 166.3px down to 116.3px (their min-content) at 481-600px open, i.e. "Quiénes Somos" wraps too.
  implication: Shrink-proofing only the brand would move the wrap into the nav links rather than eliminate it — the row would still grow, just less. Any fix must pin BOTH flexible text items and leave the search pill as the only element allowed to yield.

## Resolution

root_cause: |
  `.pk-nav-inner` is a single-line flex row (no `flex-wrap`) with `align-items: center` and no
  fixed height, so its height is whatever its tallest item needs. The brand lockup is a flex item
  that is BOTH shrinkable (`<div class="flex-initial">` in header_inner/1 = `flex: 0 1 auto`) and
  wrappable (`.pk-brand-wordmark` inherits `white-space: normal`; nothing anywhere sets `nowrap`).
  Whenever the row's natural content exceeds the viewport, the flex algorithm shrinks the brand
  below its 250px max-content width, and the wordmark's tagline — "JUEGOS DE MESA MODERNOS", 206px,
  the widest line in the lockup by 95px — reflows onto 2 then 3 line boxes. The row grows with it
  (48 -> 64 -> 80 -> 112px), the header grows with the row (65 -> 81 -> 97 -> 129px), and the
  `.CatalogNav` ResizeObserver faithfully publishes the inflated value as `--pk-header-h`, so every
  sticky-offset element below shifts too. `.pk-nav-links` is shrinkable and wrappable on exactly the
  same terms and wraps as a second-order effect (166.3 -> 116.3px min-content).

  The row is over-subscribed by arithmetic, not by a missing breakpoint: it needs
  250 + 24 + 166.3 + 24 + (44 closed | 280 open) + 64 gutters = 572.3px closed / 808.3px open, and
  the measured failure boundaries match those numbers exactly. `@media (max-width: 480px)` already
  hides the header wordmark, which is the ONLY reason ≤480px is immune — the defect is the whole
  481px-to-808px band above that rule, where nothing shrink-proofs, hides, or nowraps the wordmark.

fix: |
  Removes both preconditions of the mechanism rather than patching the symptom's pixel values.

  1. Pin the row's text items so nothing in the header can reflow, making the row's height
     structurally constant instead of merely usually-correct:
     - layouts.ex header_inner/1: the brand wrapper `<div class="flex-initial">` becomes
       `<div class="shrink-0">`. In a nowrap auto-height row a shrinkable brand does not render
       narrower — it reflows and the row inherits the height.
     - `.pk-nav-inner .pk-brand-wordmark` (new base rule): `white-space: nowrap`, header-scoped so
       the footer's shared brand_logo/1 is untouched.
     - `.pk-nav-links`: `flex-shrink: 0`; `.pk-nav-links a`: `white-space: nowrap`. Measured as
       required, not precautionary — the links were independently collapsing 166.3 -> 116.3px and
       wrapping "Quiénes Somos", so pinning only the brand would have relocated the bug.
     This leaves `.pk-search-morph.is-open`'s existing shrink guard as the row's single point of
     give, which is what the sibling session added it for.

  2. Give the row the capacity it needs, by applying the treatment ≤480px already used at the
     width the arithmetic actually calls for: `.pk-nav-inner .pk-brand-wordmark` is now
     `display: none` by default and revealed by a new `@media (min-width: 48rem)` block. 48rem is
     an existing breakpoint in this stylesheet, deliberately reused rather than inventing one; the
     row needs 808.3px for brand + links + a full pill, and the pill's shrink guard covers the
     40.3px shortfall (239.7px at 768px, above the 220px the search box carried pre-01.1-08).
     640px/sm was measured and rejected — it leaves the pill 111.7px, narrower than its own 44px
     toggle plus 44px close control together.

  The now-superseded duplicate in the ≤480px block was removed so one visual property has exactly
  one owner, per this layer's stated rule. The reveal block is positioned after every base rule it
  overrides, per the ordering pitfall documented on the adjacent 48rem block.

  Commit `5438fa0`.

verification:
  method: "Differential width sweep on the LIVE running app (mix phx.server, LiveView connected, morph opened by clicking the real .pk-search-morph-toggle so the actual .CatalogNav hook drives it), transitions disabled so all values are final-state, viewport set via CDP Emulation.setDeviceMetricsOverride (no ~500px --window-size floor). 18 widths from 375 to 1280px, closed and open, on all three header variants: catalog index, Detalle, and the About page."
  harness_fidelity: "The static reconstruction was first validated against the live app value-for-value at all 13 widths ≥481px before being trusted, and the live app was then used for every result below. Both of the prior session's stated harness gaps are closed: real self-hosted Bebas Neue/Inter metrics (text metrics ARE this bug, so a fallback font would have invalidated the run) and no window-size floor."
  signal_bug_returns_on_revert: "PASS — reverting only the two source files and re-measuring returns the exact pre-fix geometry: 481px header 81px with brand 195.2x64 and the tagline on 2 line boxes; 560px header 81px with brand 242.6x64. Restoring returns 64px and 1/1 lines. Measured, not inferred."
  signal_regression_test_is_real: "PASS — all 5 guards in test/pukllay_club_web/header_row_height_test.exs were run RED against the reverted tree (each failing with its own diagnostic, not a crash) and green after. They were not merely written green."
  signal_not_deletion_only: "PASS — the diff adds one base rule, one media block, three declarations and a test file, and changes one utility class. The single deletion (the ≤480px wordmark rule) is a duplicate whose property is now owned by the base rule; verified in the built stylesheet, which contains exactly two `.pk-nav-inner .pk-brand-wordmark` rules (the base hide and the 48rem reveal) and none inside the ≤480px block."
  signal_adjacent_functionality: "PASS — `mix quality` green end to end: hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted (Styler), credo --strict, sobelow, 347 tests / 0 failures (342 pre-existing + 5 new). Sobelow's low-confidence directory-traversal notes are pre-existing findings in the CSV seed code, untouched. The About page (nav_links, no search) and Detalle (crumb, no nav_links) were both measured and are stable at every width."
  header_height_is_now_constant: "The contract holds at every width measured, on every variant. Index: 108/108 (≤480, includes the chip subnav), 64/64 (481-767), 65/65 (768+) — closed vs open identical in every row, and --pk-header-h matches the rendered height exactly, so nothing below the sticky header shifts. Detalle: 64/64 then 65/65. About: 64/64 then 65/65. Wordmark line-box counts never exceed 1/1 at any width in any state."
  open_pill_geometry: "Index — 166.7px at 481px growing to the full 280px from 600px up (predicted 594.3px), 239.7px at 768px where the wordmark returns, back to 280px from 850px (predicted 808.3px). Detalle keeps the full 280px at every width ≥481 because its crumb yields first. Every measured value matches the capacity arithmetic, which is what makes the 48rem choice checkable rather than a guess."
  no_new_horizontal_overflow: "PASS — documentElement scrollWidth is byte-identical before and after the fix at every width (481 +172, 500 +153, 520 +133, 560 +93, 600 +53, 640 +13, ≥700 clean). The fix neither introduced nor worsened it. That residue is the separate pre-existing FOOTER bug recorded in Evidence."
  human_verification: "CONFIRMED FIXED (2026-08-24). User verified in a real browser and explicitly accepted the isologo-only header at 481-767px as-is — the design tradeoff my measurements could not decide is now decided. The 48rem reveal breakpoint stands as implemented; the alternative I had costed (a second breakpoint near 576px plus extending the mobile full-width search overlay up to 768px to keep the wordmark visible from 576px) was considered and declined. Do not retune."

  not_yet_verified: "Headless Chrome only, devicePixelRatio 1, no real touch device beyond the user's own confirmation pass. Font-swap behaviour on a slow connection is untested (nowrap now turns that into brief overflow rather than a header height jump — the better failure, but still unobserved). The design-tradeoff question that previously sat here is closed — see human_verification above."

guardrail_verdict: accepted

files_changed:
  - "lib/pukllay_club_web/components/layouts.ex — header brand wrapper pinned (flex-initial -> shrink-0) with a comment recording why"
  - "assets/css/app.css — new `.pk-nav-inner .pk-brand-wordmark` base rule (display:none + nowrap); `.pk-nav-links` flex-shrink:0; `.pk-nav-links a` nowrap; new `@media (min-width: 48rem)` wordmark reveal; superseded duplicate removed from the ≤480px block"
  - "test/pukllay_club_web/header_row_height_test.exs — new; 5 recurrence guards for the header row height contract, each verified red-before/green-after"
