---
phase: quick-260912-rwt
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
files_modified:
  - lib/pukllay_club_web/components/layouts.ex
  - assets/css/app.css
  - test/pukllay_club_web/components/nav_drawer_stacking_test.exs
  - .planning/debug/about-logo-over-nav-drawer.md
  - .planning/debug/resolved/about-logo-over-nav-drawer.md
files_deleted:
  - .planning/debug/about-logo-over-nav-drawer.md

must_haves:
  truths:
    - "With the About header docked on /quienes-somos at 390px and the mobile drawer open, the drawer panel and its backdrop paint above #pk-about-morph-mark — the drawer's 'Menú' title is not covered by the floating isologo (WINDOWS #4, user-chosen structural fix)"
    - "The mobile drawer (.pk-drawer-backdrop + aside#pk-nav-drawer) is rendered exactly once per page as a page-level sibling of #app-header in Layouts.app/1, in BOTH the sticky and non-sticky branches — never a descendant of #app-header"
    - "The drawer's effective z-index is a root-context value in the 500-700 overlay band that is strictly above .pk-about-morph-mark (60), .pk-header-sticky (50) and the flash toast (z-50), panel above backdrop, and equal to none of .pk-portal 500 / .pk-sheet-backdrop 600 / .pk-sheet 601 / .pk-lightbox 700"
    - "The drawer still opens from the hamburger, closes via close button / backdrop tap / Escape, traps Tab, returns focus and releases the body.pk-drawer-open scroll lock on /, /quienes-somos and a /juegos/:id page at 390px — the .CatalogNav hook reaches the drawer outside this.el by id"
    - "With the drawer CLOSED, the About docked header logo is unchanged (#pk-about-morph-mark z-index stays 60 and still sits over the header brand slot)"
    - "A regression test fails if the drawer re-enters #app-header, if its z-index drops to or below the morph mark / header / flash toast z, or if it collides with an existing modal tier — every competitor z value is parsed from source, not hardcoded"
    - "Debug session about-logo-over-nav-drawer is status resolved, lives at .planning/debug/resolved/about-logo-over-nav-drawer.md, root_cause text unchanged, fix/verification/files_changed filled honestly; WINDOWS.md is untouched"
  artifacts:
    - path: "lib/pukllay_club_web/components/layouts.ex"
      provides: "nav_drawer/1 rendered once outside both #app-header branches; backdrop carries id pk-nav-drawer-backdrop; .CatalogNav drawer block looks the drawer up by id outside this.el with rewritten comment"
    - path: "assets/css/app.css"
      provides: ".pk-drawer-backdrop z-index 550 and .pk-drawer z-index 551 (root context), rewritten stacking comment above .pk-drawer"
    - path: "test/pukllay_club_web/components/nav_drawer_stacking_test.exs"
      provides: "Markup ancestry + CSS-source cross-component z-order regression test for WINDOWS #4"
    - path: ".planning/debug/resolved/about-logo-over-nav-drawer.md"
      provides: "Closed debug session with fix, verification, files_changed"
  key_links:
    - from: ".CatalogNav hook drawer block (layouts.ex ~334-345)"
      to: "aside#pk-nav-drawer and div#pk-nav-drawer-backdrop (page-level siblings of #app-header)"
      via: "document.getElementById lookups — the same cross-root pattern the hook already uses for #app-subnav"
      pattern: "getElementById\\(\"pk-nav-drawer"
    - from: ".pk-drawer / .pk-drawer-backdrop z-index (app.css ~2803-2852)"
      to: ".pk-about-morph-mark z-index 60 (app.css ~4146) and flash toast z-50 (core_components.ex flash/1)"
      via: "root stacking context comparison — only valid because the drawer has no stacking-context ancestor"
      pattern: "z-index: 55[01]"
---

<objective>
Fix WINDOWS #4: on /quienes-somos at 390px, with the header docked, the floating About isologo
(#pk-about-morph-mark, root-context position: fixed; z-index: 60) paints over the open mobile nav
drawer. Root cause is already diagnosed in .planning/debug/about-logo-over-nav-drawer.md — do NOT
re-investigate. The drawer and its backdrop are children of #app-header.pk-header-sticky
(position: sticky; z-index: 50), which forms a stacking context, so the drawer's 61/60 only order it
inside the header and the whole drawer composites into the root at effective z 50, below the mark's
60. The mark's 60 is load-bearing for the docked header logo (EXP-B) and must not change.

Implements the USER-CHOSEN structural decision (the debug session's "Preferred" direction): move
nav_drawer/1 out of both #app-header branches to a page-level sibling, re-tier
.pk-drawer-backdrop / .pk-drawer into the 500-700 overlay band without colliding with .pk-portal
500, .pk-sheet-backdrop/.pk-sheet 600/601, .pk-lightbox 700, update the .CatalogNav hook's drawer
lookup (layouts.ex ~340-344) and its comment (~335-339), rewrite the app.css ~2819 comment, add a
CSS-source/markup regression test, and resolve + move the debug session. This also closes the
latent same-class trap where the flash toast (z-50, later in tree order) paints over the open
drawer on every route. The desktop .pk-cat-* mega-menu is not part of this item and is not touched.

Z-index values (Claude's discretion within the user's band): backdrop 550, panel 551 — strictly
above the portal (500) and every non-modal root layer, below the sheet (600/601) and lightbox (700),
which are mutually exclusive with an open drawer, and colliding with none of them.

Purpose: the drawer is a modal (role=dialog, aria-modal=true) and must overlay everything on the
page permanently — no body-class z toggle, so no logo blink on open and no logo pop over the
closing panel (the measured edge cases of the rejected CSS-only alternatives).
Output: patched layouts.ex + app.css, new stacking regression test, resolved debug session.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md
@.planning/debug/about-logo-over-nav-drawer.md

Project skills to load before editing (Skill tool): `ui-design-system` (daisyUI/.pk-* conventions,
banned styling patterns) and `ux-responsive` (real breakpoints — the drawer is only displayed in
app.css's `@media (max-width: 480px)` block; 44px touch floors). Mobile-first: 390px is the primary
verification width.

Source locations (verified at plan time — re-grep if lines drifted):
- lib/pukllay_club_web/components/layouts.ex: app/1 at ~192; sticky #app-header branch ~202 with the
  colocated .CatalogNav hook; drawer block ~334-408 (lookups ~340-344, comment ~335-339); updated()
  ~463-484 and destroyed() ~485-501; the two nav_drawer calls at ~511 (sticky) and ~521
  (non-sticky); #connection-status sibling + its placement comment ~524-565; nav_drawer/1 ~806-842.
  `attr :sticky` defaults to false (~134), so render_component with default assigns renders the
  non-sticky branch.
- assets/css/app.css: .pk-portal 500 (~1427), .pk-sheet-backdrop 600 (~1464), .pk-sheet 601
  (~1482), .pk-header-sticky 50 (~1550), .pk-drawer-backdrop 60 (~2803), comment ~2819-2823,
  .pk-drawer 61 (~2824), body.pk-drawer-open (~2987), .pk-about-morph-mark 60 (~4146),
  .pk-lightbox 700 (~5520), ≤480px drawer display rules (~6449-6455, indented inside @media).
- lib/pukllay_club_web/core_components.ex flash/1 (~68): class "toast toast-top toast-end z-50".
- Existing CSS-source test precedents: test/pukllay_club_web/live/catalog_show_test.exs ~4145
  (`(?m)^\.selector\s*\{([^}]*)\}` rule-body regex) and layouts_test.exs ~722-735
  (app_css_without_comments/0 comment stripping).
- Existing drawer tests that must stay green: layouts_test.exs "app/1 mobile nav drawer (01.1-09)"
  describe (~1110-1310) and ~906-918, about_live_test.exs ~83, catalog_show_test.exs ~331-360,
  catalog_live_test.exs ~1666, footer_overflow_test.exs ~159, motion_rhythm_test.exs ~62.

Batch note: sibling item 260912-rwv also edits assets/css/app.css (.pk-pill-interactive, far away).
Keep app.css edits strictly to the two drawer z-index declarations and the comment above .pk-drawer.
Put the regression test in its own new file (not layouts_test.exs) to avoid merge overlap.
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Tracer — drawer re-tiered to a page-level overlay (markup + CSS + hook lookup), pinned by a failing-first stacking test</name>
  <files>test/pukllay_club_web/components/nav_drawer_stacking_test.exs, lib/pukllay_club_web/components/layouts.ex, assets/css/app.css</files>
  <behavior>
    - Test A (markup, both branches): rendering Layouts.app/1 with default assigns (sticky false) AND with sticky: true, the parsed document has exactly one #pk-nav-drawer and exactly one .pk-drawer-backdrop; LazyHTML queries "#app-header #pk-nav-drawer" and "#app-header .pk-drawer-backdrop" return nothing; "body > #pk-nav-drawer" and "body > .pk-drawer-backdrop" each match exactly one element (page-level sibling of #app-header, not nested in main/footer/any wrapper).
    - Test B (markup): the backdrop element carries id="pk-nav-drawer-backdrop" (the hook's by-id lookup target) and the drawer still carries role="dialog", aria-modal="true" and inert at rest.
    - Test C (CSS source, comments stripped): the integer z-index parsed from the top-level .pk-drawer-backdrop rule body is strictly greater than the z-index parsed from .pk-about-morph-mark, from .pk-header-sticky, and from the flash toast's z-NN utility parsed out of lib/pukllay_club_web/core_components.ex ("toast toast-top toast-end z-(\d+)"); the .pk-drawer z-index is strictly greater than the backdrop's.
    - Test D (CSS source): both drawer z-indexes lie strictly between the .pk-portal z (500) and the .pk-lightbox z (700) as parsed from source, and neither equals the parsed .pk-portal, .pk-sheet-backdrop, .pk-sheet or .pk-lightbox value.
    - Every parse helper flunks with a descriptive message naming the selector if its rule or z-index is not found (never a silent pass), and failure messages name WINDOWS #4 and the stacking-context reason.
  </behavior>
  <action>
RED first. Create test/pukllay_club_web/components/nav_drawer_stacking_test.exs as module PukllayClubWeb.NavDrawerStackingTest (use PukllayClubWeb.ConnCase, async: true; import Phoenix.LiveViewTest; alias PukllayClubWeb.Layouts), with a moduledoc/comment citing WINDOWS #4 and .planning/debug/resolved/about-logo-over-nav-drawer.md and explaining that no other gate checks cross-component z-order. Implement Tests A-D from the behavior block. Render via render_component(&Layouts.app/1, %{flash: %{}, inner_block: []}) plus the same map with sticky: true; parse with LazyHTML.from_document. For CSS: read assets/css/app.css, strip every CSS block comment (non-greedy, dotall — same approach as layouts_test.exs app_css_without_comments/0) BEFORE matching, then extract each top-level rule body with a column-0 anchored multiline regex of the form used at catalog_show_test.exs ~4145 (column-0 anchoring deliberately skips the indented ≤480px @media copies of .pk-drawer / .pk-drawer-backdrop, which carry no z-index), and pull the integer from its z-index declaration. Selector regexes must not let .pk-drawer match .pk-drawer-backdrop or .pk-sheet match .pk-sheet-backdrop (require optional whitespace then the opening brace directly after the class name). Parse the toast z from core_components.ex source text. Run the test file and confirm it FAILS (drawer currently nested in #app-header; z 60/61 not above the band floor) before touching implementation.

GREEN — markup (layouts.ex, per the user-chosen structural fix): delete the nav_drawer call from BOTH #app-header branches (~511 and ~521) and render it ONCE, immediately after the closing tag of the non-sticky #app-header branch and before the #connection-status HEEx comment, as a direct child of app/1's template (no wrapper element — any wrapper risks becoming a stacking-context ancestor). Add a HEEx comment (curly-bang style) above it stating: this is a modal overlay, deliberately a page-level sibling of #app-header like #connection-status; #app-header.pk-header-sticky is a z-index 50 stacking context, so inside it the drawer composited at root z 50 and lost to the root-level About isologo (#pk-about-morph-mark, z 60) and to the z-50 flash toast (WINDOWS #4, debug session about-logo-over-nav-drawer); it must stay outside the header with no ancestor that creates a stacking context (positioned + z-index, transform, opacity below 1, filter, contain, isolation, will-change); it stays inside the LiveView root so it is still rendered/patched by LiveView; .CatalogNav reaches it by id. Do not quote the component call syntax itself inside that comment (keeps the call-site count gate exact). In nav_drawer/1, add id="pk-nav-drawer-backdrop" to the backdrop div; change nothing else in that component.

GREEN — CSS (app.css, tightly scoped): .pk-drawer-backdrop z-index 60 becomes 550; .pk-drawer z-index 61 becomes 551. No other declaration in either rule changes (display/transition/transform/box-shadow untouched). Do NOT change .pk-about-morph-mark, .pk-header-sticky, the flash toast, or any modal tier.

GREEN — hook (layouts.ex drawer block ~340-344): the drawer lookup becomes document.getElementById for "pk-nav-drawer"; the backdrop lookup becomes document.getElementById for "pk-nav-drawer-backdrop"; the close-button lookup is scoped to the found drawer element (this.drawer.querySelector for .pk-drawer-close) instead of this.el; the hamburger lookup stays on this.el because the hamburger remains inside the header. Keep the existing if (this.drawer) guard, open/close/keydown/focus-trap logic, updated()'s idempotent closeDrawer call and destroyed()'s cleanup byte-identical. (Comment rewrite for this block is Task 2.)

Run the new test file (GREEN), then the existing drawer-bearing test files listed in context.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && mix test test/pukllay_club_web/components/nav_drawer_stacking_test.exs test/pukllay_club_web/components/layouts_test.exs test/pukllay_club_web/live/about_live_test.exs --warnings-as-errors && test "$(grep -c '<.nav_drawer active_nav=' lib/pukllay_club_web/components/layouts.ex)" -eq 1 && test "$(grep -c 'id="pk-nav-drawer-backdrop"' lib/pukllay_club_web/components/layouts.ex)" -eq 1 && test "$(grep -c 'this.el.querySelector("#pk-nav-drawer")' lib/pukllay_club_web/components/layouts.ex)" -eq 0 && test "$(grep -c 'this.el.querySelector(".pk-drawer-backdrop")' lib/pukllay_club_web/components/layouts.ex)" -eq 0 && grep -A10 '^\.pk-drawer {' assets/css/app.css | grep -q 'z-index: 551;' && grep -A10 '^\.pk-drawer-backdrop {' assets/css/app.css | grep -q 'z-index: 550;' && grep -A6 '^\.pk-about-morph-mark {' assets/css/app.css | grep -q 'z-index: 60;'</automated>
  </verify>
  <done>New stacking test observed RED before the implementation and GREEN after; the drawer + backdrop render once, as body-level siblings of #app-header in both sticky branches; backdrop 550 / panel 551 in app.css; .pk-about-morph-mark still 60; .CatalogNav finds drawer, backdrop and close button without this.el; layouts_test.exs and about_live_test.exs pass unchanged.</done>
</task>

<task type="auto">
  <name>Task 2: Rewrite the stale stacking comments and verify the drawer end-to-end at 390px</name>
  <files>lib/pukllay_club_web/components/layouts.ex, assets/css/app.css</files>
  <action>
Comments (per the user decision's comment-update requirement):

(a) layouts.ex .CatalogNav drawer block comment (~335-339): replace the sentence claiming the drawer block reaches its DOM only through this.el with an accurate account — the drawer and backdrop are page-level siblings of #app-header (moved out for WINDOWS #4 because the sticky header's z-index 50 stacking context capped the drawer below the About isologo and the flash toast), so they are looked up by id outside this.el, the same named-root cross-root pattern the scroll-spy block already uses for #app-subnav; the hamburger stays inside the header and is still found via this.el; the body-class scroll lock remains the other documented reach outside the header. Keep the "guarded on this.drawer existing" and "extends this one hook rather than adding a second" facts.

(b) app.css comment directly above .pk-drawer (~2819-2823): replace the old confined-context rationale (the claim that the drawer's z-index only matters inside the header's context) with: the drawer and .pk-drawer-backdrop are page-level siblings of #app-header, NOT children of .pk-header-sticky — that header's z-index 50 creates a stacking context, and while nested there the drawer composited at root z 50 and lost to the root-level .pk-about-morph-mark (60) and the z-50 flash toast (WINDOWS #4, .planning/debug/resolved/about-logo-over-nav-drawer.md); they now compete in the root context at 550 (backdrop) / 551 (panel), inside the 500-700 overlay band above .pk-portal 500 and below .pk-sheet-backdrop/.pk-sheet 600/601 and .pk-lightbox 700 (mutually exclusive with an open drawer), colliding with none; the values only work while the drawer has no stacking-context ancestor, which the nav_drawer_stacking_test pins. KEEP the existing, still-true sentence that position: sticky/fixed viewport anchoring needs no transform/filter/contain/will-change hack, reworded for the new placement (the drawer's containing block is the viewport). Optionally add a one-line pointer on .pk-drawer-backdrop to the .pk-drawer comment. Touch no other app.css lines.

End-to-end browser check (mobile-first, 390x844), best effort: if the dev environment can boot (mix phx.server against the dev DB) and a Chrome/Playwright or CDP client is available, write a THROWAWAY probe in the session scratchpad directory (never under the repo; test/visual/about_geometry.mjs is the zero-dependency CDP precedent to borrow connection boilerplate from) that: (1) loads /quienes-somos, scrolls to ~700px, waits for #app-header.is-docked, taps .pk-nav-hamburger, waits past the --duration-slow slide, and asserts document.elementFromPoint at the centre of the drawer's "Menú" title span AND at the centre of #pk-about-morph-mark both resolve to a descendant of #pk-nav-drawer; (2) closes via .pk-drawer-close, asserts body lacks pk-drawer-open and elementFromPoint at the mark centre resolves to the mark again (docked logo intact); (3) repeats open then Escape-close, and open then backdrop-tap-close, on /, /quienes-somos and one /juegos/:id page, confirming focus returns to the hamburger and the page scrolls again; (4) runs in light and dark themes on /quienes-somos. While the About header is undocked, note whether any new artifact appears at the viewport's right edge from the closed drawer's box-shadow (the closed drawer was previously hidden along with the invisible header on About); parity with / (where the header is always visible) is acceptable — record the observation, do not expand scope. If the server or a browser cannot be run in this environment, do not fake it: record explicitly that no live browser check was performed and leave the human-check below for UAT.

Then run the remaining drawer/CSS-contract test files.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && mix test test/pukllay_club_web/components/nav_drawer_stacking_test.exs test/pukllay_club_web/footer_overflow_test.exs test/pukllay_club_web/motion_rhythm_test.exs test/pukllay_club_web/live/catalog_show_test.exs test/pukllay_club_web/live/catalog_live_test.exs --warnings-as-errors && test "$(grep -c 'only needs to beat .pk-nav' assets/css/app.css)" -eq 0 && test "$(grep -c 'never outside it' lib/pukllay_club_web/components/layouts.ex)" -eq 0 && grep -B20 '^\.pk-drawer {' assets/css/app.css | grep -q 'WINDOWS #4'</automated>
    <human-check>At 390px on /quienes-somos, scroll until the header docks, tap "Abrir menú": the "Menú" title and the whole drawer panel sit above the isologo, the backdrop dims the header logo along with the rest of the page, no logo blink on open and no logo flash over the closing panel; close it and the docked header logo is back. Drawer open/close still works on / and a game detail page, light and dark.</human-check>
  </verify>
  <done>Both stale comments rewritten to describe the page-level placement and the 550/551 root-context tiers; the old confined-context claims are gone from app.css and layouts.ex; all drawer-related test files pass; the browser check result (or an explicit "not performed" with reason) is captured for the debug session's verification field and the SUMMARY.</done>
</task>

<task type="auto">
  <name>Task 3: Resolve and move the debug session, then pass mix quality</name>
  <files>.planning/debug/about-logo-over-nav-drawer.md, .planning/debug/resolved/about-logo-over-nav-drawer.md</files>
  <action>
Edit .planning/debug/about-logo-over-nav-drawer.md (format precedent: .planning/debug/resolved/G-01-7-double-focus-ring.md): set frontmatter status to resolved and updated to the current ISO timestamp; in Current Focus set next_action to none (resolved by quick 260912-rwt). Leave Symptoms, Evidence, Eliminated, root_cause and suggested_fix_direction text unchanged. Replace the Resolution placeholders:
- fix: a quoted one-paragraph statement naming quick 260912-rwt and its commit short SHA(s) — nav_drawer/1 moved out of both #app-header branches to a single page-level sibling (user-chosen structural fix, the session's Preferred direction), .pk-drawer-backdrop / .pk-drawer re-tiered 60/61 to 550/551 in the root context (above .pk-about-morph-mark 60, the header 50 and the z-50 flash toast; no collision with .pk-portal 500, .pk-sheet 600/601, .pk-lightbox 700), backdrop given id pk-nav-drawer-backdrop, .CatalogNav drawer lookups switched to by-id outside this.el, both stale comments rewritten; the mark's load-bearing z 60 unchanged; latent flash-toast instance closed too.
- verification: a block list recording the RED-then-GREEN run of the new stacking test with its test/failure counts, the other drawer test files' results, the grep evidence from Tasks 1-2, the mix quality result, and the Task 2 browser check outcome stated honestly (elementFromPoint results per route/theme if run; otherwise an explicit line that no live browser check was performed and the human-check is pending UAT). Note the closed-drawer right-edge shadow observation if one was made.
- files_changed: list lib/pukllay_club_web/components/layouts.ex, assets/css/app.css, test/pukllay_club_web/components/nav_drawer_stacking_test.exs.

Move it with git mv to .planning/debug/resolved/about-logo-over-nav-drawer.md (history preserved). Do not edit WINDOWS.md or any other planning ledger/row.

Finally run mix quality from the repo root (hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted with Styler, credo --strict, sobelow --config, test --warnings-as-errors). If format or Styler flags the new test or layouts.ex, run mix format, review the git diff hunk by hunk (Styler can change semantics), and re-run until mix quality exits 0. Any failure outside this item's files that pre-exists on main must be reported in the SUMMARY, not silently worked around.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && test -f .planning/debug/resolved/about-logo-over-nav-drawer.md && test ! -e .planning/debug/about-logo-over-nav-drawer.md && grep -q '^status: resolved' .planning/debug/resolved/about-logo-over-nav-drawer.md && grep -q '^fix: .*260912-rwt' .planning/debug/resolved/about-logo-over-nav-drawer.md && grep -A4 '^files_changed:' .planning/debug/resolved/about-logo-over-nav-drawer.md | grep -q 'nav_drawer_stacking_test.exs' && git diff --quiet HEAD -- .planning/WINDOWS.md && mix quality</automated>
  </verify>
  <done>Debug session resolved and git-moved to .planning/debug/resolved/ with fix, verification and files_changed filled and root_cause untouched; .planning/WINDOWS.md has no uncommitted change and appears in none of this item's commits; mix quality exits 0.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| none new | Server-rendered static markup and CSS stacking order only; no user input, data, auth, network or package changes cross any boundary in this item |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-rwt-01 | Spoofing (UI redress) | Mobile nav drawer vs root-level layers (.pk-about-morph-mark, flash toast) | low | mitigate | Drawer re-tiered to page-level 550/551 so no non-modal layer can paint over or intercept taps on the modal drawer's controls; pinned by nav_drawer_stacking_test.exs parsing every competitor z from source |
| T-rwt-02 | Denial of Service (availability) | .CatalogNav drawer wiring after the DOM move | low | mitigate | By-id lookups outside this.el with the existing if (this.drawer) guard; open/close/focus-trap and destroyed()'s body.pk-drawer-open cleanup kept byte-identical so a teardown can never leave the page unscrollable; Task 2 exercises open/close/Escape/backdrop on three routes at 390px |
| T-rwt-03 | Information Disclosure | Drawer markup | low | accept | Drawer contains only public nav links, public social links and the theme toggle; moving it in the DOM exposes nothing new |
</threat_model>

<verification>
- New test/pukllay_club_web/components/nav_drawer_stacking_test.exs: RED before implementation, GREEN after.
- Existing drawer tests (layouts_test, about_live_test, catalog_show_test, catalog_live_test, footer_overflow_test, motion_rhythm_test) pass.
- Grep gates: single nav_drawer call site, backdrop id present, no this.el-scoped drawer/backdrop lookups, 550/551 in the top-level drawer rules, mark still 60, stale comment claims gone.
- 390px browser check on /quienes-somos (docked, light + dark), / and /juegos/:id — or an explicit record that it was not performed.
- mix quality exits 0; WINDOWS.md untouched; debug session resolved under .planning/debug/resolved/.
</verification>

<success_criteria>
- On /quienes-somos at 390px with the header docked, the open drawer and backdrop paint above the floating isologo in both themes; closing the drawer restores the docked logo with no toggle-induced blink/pop.
- The drawer is a single page-level sibling of #app-header at z 550/551, above the mark (60), header (50) and flash toast (z-50), colliding with no modal tier.
- Drawer interaction (open, close button, backdrop tap, Escape, focus trap, focus return, scroll lock release) is unchanged on /, /quienes-somos and /juegos/:id.
- Regression test guards ancestry and cross-component z-order from source.
- Debug session about-logo-over-nav-drawer resolved and moved; mix quality green.
</success_criteria>

<output>
Create `.planning/quick/260912-rwt-fix-windows-4-mobile-nav-drawer-painted-under-the-about-floa/260912-rwt-SUMMARY.md` when done
</output>
