---
status: diagnosed
trigger: "WINDOWS entry 4 browser-verification FAIL — About page floating isologo paints above the open mobile nav drawer on /quienes-somos at 390px (light and dark)."
created: 2026-09-12T23:30:00Z
updated: 2026-09-13T00:05:00Z
goal: find_root_cause_only
---

## Current Focus

hypothesis: CONFIRMED — The drawer (z 61) and backdrop (z 60) are local to #app-header's stacking context (.pk-header-sticky, z 50), so they composite into the root at z 50; #pk-about-morph-mark is a root-context fixed layer at z 60 (load-bearing for the header dock), so it paints above the whole header context, drawer included.
bug_class: Bohrbug (deterministic visual stacking defect, reproduces every time in both themes)
test: done — baseline repro + EXP-A/B/C + close-transition sampling + flash-toast probe (see Evidence)
next_action: none (diagnose-only). Hand the suggested fix direction in Resolution to a /gsd-quick or fix session.

reasoning_checkpoint:
  hypothesis: "The mark covers the open drawer because the drawer and its backdrop are position:fixed descendants of .pk-header-sticky (position: sticky; z-index: 50), which forms a stacking context, so their z 61/60 only order them inside the header; in the root context the whole header — drawer included — sits at 50, below the root-level .pk-about-morph-mark at 60."
  confirming_evidence:
    - "elementFromPoint at the drawer's 'Menú' centre returns the mark IMG in headless Chrome at 390px, light and dark; the mark has no stacking-context ancestor (root layer)"
    - "EXP-A: raising ONLY the header context (body.pk-drawer-open .pk-header-sticky { z-index: 70 }) makes the same point hit the drawer title SPAN — nothing about the mark changed"
    - "The app.css:2819 comment documents the confined-context assumption verbatim; git -S shows the mark's z 60 arrived 10 days later in fddc0f6"
  falsification_test: "If raising the header context above 60 had NOT changed the hit result, or the mark had a stacking-context ancestor, the hypothesis would be wrong. Neither happened."
  fix_rationale: "The drawer is a modal (role=dialog, aria-modal=true) whose effective z is capped by its parent's stacking context; the fix must lift the drawer/backdrop's EFFECTIVE root-context z above every non-modal root layer (re-tier out of the header, or lift the header context while open), not special-case the mark — which would leave the flash toast (z 50, later in DOM) still painting over the drawer."
  blind_spots: "Not verified on a real iOS Safari/Android Chrome device (stacking-context rules are spec-level and engine-independent, so low risk). LiveView DOM patching of JS-set is-open/inert attributes if the drawer is moved outside the hook's root was not exercised. Desktop .pk-cat-* mega-menu shares the confinement but was not probed against the flash toast visually."
  candidate_causes:
    - "code/markup: nav_drawer/1 rendered inside #app-header.pk-header-sticky (layouts.ex:511, 521) — CONTRIBUTING"
    - "code/css: .pk-about-morph-mark z-index 60 in the root context (app.css:4150) — CONTRIBUTING (but load-bearing, EXP-B)"
    - "environment: browser/theme-specific layering — ELIMINATED (spec behaviour; identical in light/dark, headless and headed Chrome)"
    - "data: none applicable (no data drives z-order)"
  and_gate: "yes — both conditions are required simultaneously: (1) drawer confined to the z-50 header stacking context AND (2) a root-context layer with z > 50 geometrically overlapping the drawer while it is openable. Inicio/Detalle have (1) without (2) and are fine; a root-level drawer tiered above 60 would beat the mark despite (2)."

## Symptoms

expected: The open mobile nav drawer (#pk-nav-drawer) and its backdrop overlay everything on the page — standard drawer behaviour, confirmed by the user during the 2026-09-12 browser verification session ("the drawer menu should overlay everything from the page").
actual: On /quienes-somos at 390px, after scrolling so the header is docked, opening the drawer shows `.pk-about-morph-mark` (the floating About isologo) painted ON TOP of the drawer panel, covering the "Menú" title in the drawer header. Reproduces in light and dark themes.
errors: none (visual stacking defect)
timeline: Found 2026-09-12 during the browser verification of waived WINDOWS.md entries (todo 2026-09-12-browser-verification-session-for-waived-windows-ui-entries.md). Not known whether it ever worked.
reproduction: Local dev server, viewport 390px wide. Load /quienes-somos, scroll down past the hero (~600px) so `#about-hero.is-docked` is set and the header shows. Tap "Abrir menú" (.pk-nav-hamburger). Look at the drawer's top-left: the isologo sits over "Menú".

measured_in_browser (2026-09-12, Chrome, same-origin iframe at exactly 390px):
- elementFromPoint at the centre of the drawer's "Menú" title returns the isologo IMG inside `DIV.pk-about-morph-mark is-entered is-first-play` (position: fixed, z-index: 60).
- `#pk-nav-drawer` (ASIDE.pk-drawer.is-open) is position: fixed, z-index: 61, but its parent is `DIV.pk-header.pk-header-sticky.is-docked` (position: sticky, z-index: 50), which creates its own stacking context — so the drawer effectively competes at z=50 in the root context, below the mark's 60.
- Only /quienes-somos is affected (the only route rendering .pk-about-morph-mark). Drawer on / and /juegos/179 is fine.
- The `.pk-drawer-backdrop` is also inside the sticky header, so the same stacking applies to it.
- All other Entry 4 criteria passed (rows 320x45 with chevrons, aria-current="page" accent, .pk-drawer-bottom pinned 16px from panel bottom, footer shows only "Powered by BGG").

screenshots:
- /tmp/claude-1000/-home-apedraza-projects-pukllay-club/8d9ea666-ed72-48ff-8d18-60586f9bae3c/scratchpad/shots/e4-drawer-390-light.png
- /tmp/claude-1000/-home-apedraza-projects-pukllay-club/8d9ea666-ed72-48ff-8d18-60586f9bae3c/scratchpad/shots/e4-drawer-390-dark.png

relevant_files:
- lib/pukllay_club_web/components/layouts.ex (drawer markup, inside header)
- lib/pukllay_club_web/live/about_live.ex (AboutHeaderMorph hook, .pk-about-morph-mark)
- assets/css/app.css (.pk-header-sticky, .pk-drawer, .pk-drawer-backdrop, .pk-about-morph-mark z-index rules)

## Evidence

- timestamp: 2026-09-12T23:40:00Z
  checked: .planning/debug/knowledge-base.md (Phase 0)
  found: No prior resolution about z-index / stacking contexts / drawer overlays. Only header-height-wordmark-wrap and search-expand-header-overlap touch the header, neither is about stacking.
  implication: No known-pattern candidate; investigate from scratch.

- timestamp: 2026-09-12T23:42:00Z
  checked: assets/css/app.css z-index inventory (every `z-index:` declaration mapped to its selector)
  found: root-context fixed layers — .pk-about-cta-bar 40, .pk-title-echo 40, .pk-mobile-cta-bar 45, .pk-header-sticky 50 (stacking context), .pk-about-morph-mark 60 (app.css:4146-4154), .pk-portal 500, .pk-sheet-backdrop 600, .pk-sheet 601, .pk-lightbox 700. Inside the header's context — .pk-drawer-backdrop 60 (2803-2812), .pk-drawer 61 (2824-2852), .pk-cat-backdrop 60, .pk-cat-panel 62, .pk-search-morph.is-open 5.
  implication: .pk-about-morph-mark is the ONLY root-context layer between 50 and 500. Everything else that shares the drawer's routes is either <50 (loses to the header context, correct) or a modal at 500+ that cannot coexist with an open drawer.

- timestamp: 2026-09-12T23:43:00Z
  checked: app.css:2819-2823 comment on .pk-drawer
  found: "`.pk-header-sticky`'s z-index: 50 creates a stacking context; the drawer is a position: fixed child of it, so its z-index only needs to beat .pk-nav within that context, not the page at large." The design EXPLICITLY assumed nothing outside the header would ever sit above z 50.
  implication: The drawer's 61 is a local (intra-header) z-index. Its effective root z is 50. The assumption was true when written (01.1-09) and was invalidated later when the About morph mark (phase 01.4) shipped at z 60 in the root context.

- timestamp: 2026-09-12T23:45:00Z
  checked: lib/pukllay_club_web/components/layouts.ex:202-212 (sticky branch) and nav_drawer/1 at 806-842; about_live.ex:958-972
  found: `<.nav_drawer>` (backdrop + aside#pk-nav-drawer) is rendered INSIDE div#app-header.pk-header-sticky. #pk-about-morph-mark is rendered by AboutLive as a child of `<main><div class="mx-auto space-y-4">` — no ancestor of it declares position+z-index, transform, opacity<1, filter, contain or isolation, so its z 60 participates in the ROOT stacking context. The .CatalogNav drawer block reaches the drawer only via `this.el.querySelector` (layouts.ex:340-344).
  implication: Mark (root z 60) vs header context (root z 50, containing drawer 61 + backdrop 60) — the mark wins by z-index outright, not by DOM order. Both the panel and the backdrop lose. Matches the measured elementFromPoint result in Symptoms.

- timestamp: 2026-09-12T23:47:00Z
  checked: why the mark is at z 60 at all — about_live.ex:207-238 (dockRect/write) + app.css:4257-4310 + app.css:1618-1631 (.pk-nav)
  found: When docked, the hook parks the floating mark exactly on the header's `.pk-brand-mark` rect, and `body:has(#about-hero[data-morph-armed]) #app-header .pk-brand-mark { opacity: 0 }` hides the header's own isologo permanently on About — the floating mark IS the header logo while docked. `.pk-nav` background is fully opaque `var(--color-base-200)` (G-01.5-7 made it opaque on purpose).
  implication: The mark MUST paint above the header context (>50) in the docked state, or the header renders with no logo at all (opaque bar over it). So "globally lower the mark below 50" is not a viable fix — z 60 is load-bearing for the dock. The conflict is only while the drawer is open.

- timestamp: 2026-09-12T23:48:00Z
  checked: About header reachability — app.css:4257-4275 and about_live.ex:132, 270, 336
  found: While undocked the whole #app-header is `visibility: hidden` + `inert`; the hamburger is only clickable once `.is-docked` is set. At dock the mark sits on the brand slot (just right of the 44px hamburger, x≈58-94 at 390px) and the drawer panel is right-anchored, 82% / max 20rem → left edge ≈ x 70 at 390px, with 1rem padding putting "Menú" at x≈86.
  implication: Every time the drawer can be opened on About, the mark is docked and geometrically overlaps the drawer's top-left — the defect is 100% reproducible, not scroll-position dependent beyond "docked". Consistent with the report.

- timestamp: 2026-09-12T23:55:00Z
  checked: Headless Chrome (Playwright 1.63, channel chrome) at 390x844 against the running dev server, scrollY 700, light + dark (scratchpad/stack-probe.cjs)
  found: BASELINE (both themes) — header z 50, mark z 60, mark rect [66,12,36,40], drawer rect [70,0,320,844], "Menú" rect [86,24,31,28]; elementFromPoint at "Menú" centre = the mark's IMG (IMG.dark:hidden light / IMG.hidden.dark:block dark). Walking the mark's ancestors for stacking-context triggers (positioned+z, transform, opacity, filter, isolation, contain, will-change) returns [] — it is a root-context layer. Reproduced independently of the original in-browser session.
  implication: Symptom reproduced deterministically; the mark is in the root stacking context, confirming the z 60 vs z 50 comparison is what decides.

- timestamp: 2026-09-12T23:56:00Z
  checked: EXP-A — injected `body.pk-drawer-open .pk-header-sticky { z-index: 70 }` (no source edit), drawer open, both themes
  found: elementFromPoint at "Menú" = SPAN.font-display.text-lg (the drawer title); at the mark centre = ASIDE#pk-nav-drawer. Screenshot probe-light-expA.png shows "MENÚ" fully visible, no isologo.
  implication: Falsification test passed — changing ONLY the header context's root z-index (nothing about the mark) removes the defect. Confirms the stacking-context confinement is causal.

- timestamp: 2026-09-12T23:57:00Z
  checked: EXP-B — injected `.pk-about-morph-mark { z-index: 49 !important }`, docked, drawer CLOSED, both themes
  found: elementFromPoint at the mark centre = IMG.pk-brand-mark (the header's own, opacity 0 on About). Screenshot probe-dark-expB-mark-z49.png: header shows hamburger + "PUKLLAY CLUB" with an EMPTY brand slot — the isologo is gone behind the opaque .pk-nav bar.
  implication: z 60 on the mark is load-bearing for the docked state. A global "lower the mark below 50" fix would regress the About header dock. Any fix must be drawer-open-scoped or re-tier the drawer, not the mark.

- timestamp: 2026-09-12T23:58:00Z
  checked: EXP-C — injected `body.pk-drawer-open .pk-about-morph-mark { visibility: hidden }`, drawer open, both themes
  found: "Menú" hit = drawer SPAN; mark centre hit = drawer ASIDE.
  implication: About-scoped point fix also works, but only for this one competitor (see flash probe below).

- timestamp: 2026-09-12T23:59:00Z
  checked: Close-transition sampling for EXP-A (header z 600 while open) and EXP-C, per-rAF elementFromPoint at the mark centre for 400ms after tapping .pk-drawer-close (scratchpad/close-probe.cjs)
  found: .CatalogNav's closeDrawer() removes body.pk-drawer-open synchronously (layouts.ex:361-371), so in BOTH variants the mark is top-most again from the first sampled frame (7ms, drawerLeft=70) while the panel is still sliding over x 66-102 (drawerLeft reaches 102 at ~47-56ms). Symmetrically on open, the class is added before the panel arrives, so the docked logo blinks out ~a full --duration-slow before the panel covers the slot.
  implication: Any class-toggled z-index/visibility fix carries a ~3-frame "logo pops back over the closing panel" edge and a "logo blinks out on open" edge. Only a fix that needs NO toggle — drawer/backdrop tiered above the mark permanently — avoids both.

- timestamp: 2026-09-13T00:00:00Z
  checked: Latent same-trap competitor — core_components.ex:68 flash toast (`toast toast-top toast-end z-50`, rendered by flash_group/1 at the END of Layouts.app, same parent as #app-header). Injected an identical toast with the drawer open on / and /quienes-somos (scratchpad/flash-probe.cjs)
  found: toast position fixed, z 50, rect [70,18,288,41] — elementFromPoint at its centre = the alert DIV, i.e. it paints OVER the open drawer on both routes (z tie at 50 with the header context, later in tree order wins). `grep put_flash lib` returns nothing, so no flash is currently emitted.
  implication: Second, currently-latent instance of the same defect class on EVERY route with the drawer. A drawer-scoped fix (A or re-tier) closes it; the About-only mark fix (C) does not.

- timestamp: 2026-09-13T00:01:00Z
  checked: git history — `git log -S` on app.css
  found: The drawer-inside-header stacking assumption (app.css:2819 comment, drawer z 61) landed in 320fc4b (2026-08-24, PR #28, phase 01.1). `.pk-about-morph-mark { z-index: 60 }` landed in fddc0f6 (2026-09-03, "feat(01.4-05): tracer — isologo entrance, 1:1 scroll tracking, and header dock").
  implication: The defect has existed since fddc0f6 — never worked since the morph shipped. Neither change is wrong alone; the second silently invalidated the first's documented assumption. No test/gate checks cross-component z-order (CSS contract tests only pin per-rule declarations, e.g. catalog_show_test.exs:4145 for .pk-lightbox-chevron).

- timestamp: 2026-09-13T00:02:00Z
  checked: Other root-context layers on drawer routes, for completeness
  found: .pk-about-cta-bar 40 (About), .pk-title-echo 40 and .pk-mobile-cta-bar 45 (Detalle) are below 50 — correctly under the drawer (matches the session's "drawer on /juegos/179 is fine"). .pk-portal 500, .pk-sheet-backdrop/.pk-sheet 600/601 (game_preview.ex:371-372), .pk-lightbox 700 (show.ex:844) are root-level modals ABOVE the header context, but mutually exclusive with an open drawer (each has its own backdrop / the drawer backdrop blocks their triggers). The desktop .pk-cat-backdrop 60 / .pk-cat-panel 62 mega-menu is ALSO confined to the header context — same structural trap, currently only exposed to the z-50 flash toast. The dark "Sign in" pill visible bottom-left in probe screenshots is an injected dev-tool overlay, not app markup.
  implication: The About mark is the only CURRENTLY rendered competitor; the flash toast is the only latent one; the cat mega-menu shares the confinement.

## Eliminated

- hypothesis: The mark wins by DOM order inside some shared ancestor stacking context (a z-index tie), not by z-index outright
  evidence: Ancestor walk of #pk-about-morph-mark finds zero stacking-context triggers; computed z is 60 vs header 50 — a strict inequality in the root context, no tie involved.
  timestamp: 2026-09-12T23:55:00Z

- hypothesis: Theme-specific — a dark-mode :has()/dark: rule changes the mark's layering
  evidence: Identical elementFromPoint results and z values in light and dark (only the visible IMG variant differs).
  timestamp: 2026-09-12T23:55:00Z

- hypothesis: (fix candidate) Globally lowering .pk-about-morph-mark below the header (z < 50) is a safe fix
  evidence: EXP-B — at z 49 the docked brand slot hit-tests to the header's opacity-0 .pk-brand-mark and the screenshot shows the header with no isologo; the opaque .pk-nav bar covers the mark. z 60 is load-bearing for the dock.
  timestamp: 2026-09-12T23:57:00Z

## Resolution

root_cause: (AND-gate, two contributing causes) (1) The mobile nav drawer and its backdrop (`nav_drawer/1`, layouts.ex:806-842) are rendered INSIDE `#app-header.pk-header-sticky` (layouts.ex:511/521), and `.pk-header-sticky { position: sticky; z-index: 50 }` (app.css:1550-1554) creates a stacking context — so `.pk-drawer { z-index: 61 }` / `.pk-drawer-backdrop { z-index: 60 }` only order them inside the header, and the whole drawer composites into the root at effective z 50 (the assumption is written down in the app.css:2819-2823 comment: "its z-index only needs to beat .pk-nav within that context, not the page at large"); (2) `#pk-about-morph-mark` (about_live.ex:958) is a root-context `position: fixed; z-index: 60` layer (app.css:4146-4154, added in fddc0f6) that, whenever the drawer is openable on About (header docked), sits on the header brand slot at x 66-102 — inside the right-anchored drawer's area (left edge x 70 at 390px). 60 > 50 in the root context, so the mark paints over the drawer panel and backdrop. The mark's z 60 is load-bearing (it must sit above the opaque .pk-nav to BE the docked header logo), so neither decision is wrong alone; the second silently invalidated the first's assumption.

suggested_fix_direction: |
  Preferred (structural, no toggle, consistent with the existing modal-overlay pattern):
    Re-tier the drawer like every other modal overlay in the app — .pk-portal (500), .pk-sheet-backdrop/.pk-sheet (600/601, game_preview.ex:371-372), .pk-lightbox (700, show.ex:844) are all rendered OUTSIDE the header in the root context. Move `<.nav_drawer>` out of both #app-header branches to a root-level sibling (like #connection-status), and give .pk-drawer-backdrop / .pk-drawer z-indexes in the modal band (e.g. 600/601, or a dedicated pair) — NOT 60/61: at a 60 tie the mark (later in tree order, inside <main>) would still beat the backdrop. Result: header 50 < mark 60 < backdrop < panel, permanently — the docked logo gets dimmed by the backdrop along with the rest of the header and is covered by the panel, with no pop on open or close. Costs: .CatalogNav's drawer block must look the drawer up outside `this.el` (layouts.ex:340-344 — the hook already reaches #app-subnav outside its root, so there is precedent; update the "never outside it" comment), the app.css:2819 comment must be rewritten, and layouts_test drawer assertions should still pass (they query by class/id, not by #app-header ancestry — re-run to confirm). Also closes the latent flash-toast trap (core_components.ex:68, z-50) and the same confinement for nothing else.
  Minimal alternative (CSS-only, one rule): `body.pk-drawer-open .pk-header-sticky { z-index: <modal band, e.g. 600> }` — reuses the body class .CatalogNav already toggles (like body.pk-sheet-open). Verified by EXP-A. Fixes the whole class for the drawer (mark AND flash toast). Trade-off, measured: the docked logo blinks out when the drawer opens (the opaque header bar covers it before the panel arrives) and pops back over the closing panel for ~3 frames (~50ms) because closeDrawer() drops the class synchronously. Acceptable if the user signs off on that edge; a transition-delayed z-index would be fighting the body:has(#about-hero...) #app-header `transition` rules (app.css:4257-4275), so do not try to smooth it that way.
  Not recommended: `body.pk-drawer-open .pk-about-morph-mark { visibility: hidden }` (EXP-C) — same blink/pop edges as the minimal alternative, but About-only: leaves the flash toast painting over the drawer on every route and leaves the drawer's broken "only needs to beat .pk-nav" assumption in place for the next root layer > 50. Globally lowering the mark below 50 is ruled out (EXP-B: removes the docked header logo).
  Recurrence guard to add with the fix: a browser-level check (elementFromPoint at the drawer title with the drawer open on /quienes-somos docked === drawer descendant) plus a CSS contract test that the drawer's effective root z exceeds .pk-about-morph-mark's z and the flash toast's z-50 — no existing gate checks cross-component z-order.
  Other elements that can hit the same stacking-context trap: flash toast `.toast.toast-top.toast-end.z-50` (core_components.ex:68) — ties the header at 50 and wins by tree order, measured painting over the open drawer on / and /quienes-somos (latent: no put_flash in lib today); the desktop "Explorar categorías" mega-menu (.pk-cat-backdrop 60 / .pk-cat-panel 62, Inicio) is confined to the same z-50 header context and would lose to any root layer >= 50 (today only the flash toast); any future root-level fixed layer with z > 50. Safe today: .pk-about-cta-bar 40, .pk-title-echo 40, .pk-mobile-cta-bar 45 (below the header), and the 500-700 modals (mutually exclusive with an open drawer) — if the drawer is re-tiered into that band, pick values that do not collide.
fix: (not applied — diagnose-only; see suggested_fix_direction)
verification: (not applicable — diagnose-only)
files_changed: [] (proposed: lib/pukllay_club_web/components/layouts.ex, assets/css/app.css, plus a regression test under test/pukllay_club_web/)
