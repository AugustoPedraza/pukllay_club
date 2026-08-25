---
status: resolved
trigger: "on mobile and on desktop, typing on a category(from the index menu) must to have a polished continuous subtle animation, not just a kind of \"instant\" scrolling."
created: 2026-08-25T00:00:00Z
updated: 2026-08-25T08:55:00Z
---

## Current Focus

hypothesis: CONFIRMED, fixed, and human-verified. Root cause was the absence of
`scroll-behavior: smooth` on the document scrolling element.
test: Human confirmation that the animation reads as "polished, continuous, subtle" — the one
criterion no automated signal could settle, since native smooth scroll's easing curve is
browser-controlled and the complaint was aesthetic, not functional.
expecting: User taps a category on mobile and clicks one on desktop and sees a continuous glide
rather than a jump.
next_action: NONE — session complete. The user tested both surfaces in a real browser (desktop
mega-menu and mobile chips, adjacent-shelf and long first-to-last jumps) and confirmed the motion
reads as polished, continuous and subtle. The escalation that was on standby — the JS per-frame
`easeOutSoft` scroller (carousel_row.ex:80-95), which would have made duration and curve tunable
against `--ease-out-soft` — was NOT needed and was deliberately not built: native smooth scroll
answered the complaint, so adding a JS animation loop would have been unbacked complexity.

reasoning_checkpoint:
  hypothesis: "Category anchors scroll instantly because no `scroll-behavior: smooth` is ever
    declared on the document scrolling element (`html`), so the CSS initial value `auto` governs
    every fragment navigation. The only two real `scroll-behavior` declarations that reach the
    browser are a deliberate `auto` scoped to `.pk-rail` and a `smooth` inside daisyUI's `.carousel`
    component, which this app does not use."
  confirming_evidence:
    - "Authored CSS (assets/css/app.css) contains exactly ONE `scroll-behavior` declaration:
      `auto` at line 296, scoped to `.pk-rail` (horizontal carousel), deliberately documented."
    - "Compiled CSS (priv/static/assets/css/app.css) contains exactly TWO real declarations:
      the `.pk-rail` `auto`, and `smooth` at line 2573 inside daisyUI's `.carousel` block — a
      component this project explicitly does NOT use (ui-design-system names the hand-rolled
      `.pk-rail` as the sanctioned exception). Neither targets `html`, `:root`, or `body`."
    - "Both surfaces are plain native anchors: desktop `.pk-cat-item` is
      `<a href={\"#carousel-#{row.key}\"}>` (layouts.ex:639-647); mobile `.pk-chip` is the same
      `<a href={\"#carousel-#{row.key}\"}>` (catalog_live/index.ex:549-556). Identical mechanism on
      both, which is exactly why the symptom reproduces on both."
    - "The `.CatalogNav` hook does NOT intercept the navigation: `onCatItemClick = () =>
      this.closeCatMenu()` (layouts.ex:408) only closes the panel. No preventDefault, no
      scrollIntoView, no scrollTo. The browser's default fragment navigation is what runs."
    - "`html`/`body` carry no `overflow` in their default state (only the transient
      `body.pk-sheet-open` / `body.pk-drawer-open` scroll locks), so the viewport/`html` IS the
      document scrolling element whose `scroll-behavior` governs the jump."
    - "The codebase's own comments already call this interaction a *jump* — app.css:249 and 486
      both say \"a chip-anchor jump\" — corroborating that instant motion is the current behavior
      and was never animated."
  falsification_test: "If a `scroll-behavior: smooth` declaration matching `html`/`:root`/`body`
    existed anywhere in the compiled bundle, or if the hook called preventDefault and ran its own
    scroll, this hypothesis would be false. Both were checked directly and neither is present."
  fix_rationale: "The root cause is a missing CSS declaration, not faulty logic. Declaring
    `scroll-behavior: smooth` on `html` makes the browser animate the very same fragment
    navigation both surfaces already perform — it addresses the mechanism itself rather than
    layering a JS scroll animation on top of it. The anchor targets already carry
    `.pk-shelf { scroll-margin-top: calc(var(--pk-header-h, 4.5rem) + 1rem) }` (app.css:257), so
    the landing offset is already correct; only the animation was missing. No markup, no JS, and
    no hook changes."
  blind_spots: "Native smooth scroll uses a browser-controlled easing curve that cannot be tuned
    to `--ease-out-soft`; if the user judges the specific curve or duration wrong, a JS per-frame
    scroller (the `.CarouselScroll` easeOutSoft pattern in carousel_row.ex:80-95) would be the
    escalation. Very long jumps (top shelf to 8th shelf) travel further and so take longer —
    needs a human eye to confirm it reads as polished rather than slow. Not yet observed in a
    live browser at the time of the fix."
  candidate_causes:
    - "code: anchors rely on native fragment navigation with no JS animation — CONFIRMED as the
      mechanism, but the code itself is correct; the anchors are the right approach."
    - "config/styling: no `scroll-behavior: smooth` declared for the document scroller — CONFIRMED
      as the actual defect."
    - "environment: a user OS-level `prefers-reduced-motion: reduce` setting would suppress smooth
      scrolling — RULED OUT as the cause (nothing is declared at all, so the setting is moot), but
      it is a real condition the FIX must respect, hence the no-preference wrapper."
    - "data: N/A — the row keys and section ids match by construction (`carousel-#{row.key}` on
      both the anchor and the `<section id={@id} class=\"pk-shelf\">`), and the jump does land on
      the right section today, only instantly."
  and_gate: "no — one condition fully explains the symptom, and one declaration fixes it.
    Critically, `scroll-behavior` is NOT an inherited property, so `html { scroll-behavior:
    smooth }` cannot leak into any nested scroller. Verified the only per-frame scroll-position
    writer is `.CarouselScroll` assigning `rail.scrollLeft` (carousel_row.ex:85,92) on `.pk-rail`,
    which both sits outside the inheritance path AND declares its own `auto` — the exact
    animation-fight scenario app.css:289-296 warns about therefore cannot occur. The two explicit
    programmatic scrolls (`about_live.ex:94`, `show.ex:255`) both pass `behavior: \"smooth\"`
    explicitly and are unaffected by CSS. `.pk-cat-panel` is `position: absolute` closing via
    opacity/visibility (app.css:1061-1084), so closing the menu mid-scroll cannot reflow the
    document and disturb an in-flight animation."

## Symptoms

expected: When a user taps/clicks a category from the index/nav menu (on both mobile and desktop),
the page should transition to that category's section with a continuous, subtle, polished scroll
animation — not an abrupt jump.
actual: Selecting a category from the index menu produces an "instant" scroll — the page jumps to
the target section with no perceptible animation, which reads as jarring rather than polished.
errors: None reported — this is a visual/UX polish issue, not a functional error.
reproduction: On mobile or desktop, open the category index/nav menu (from the catalog page) and
tap/click any category entry. Observe that the view jumps immediately to the corresponding section
instead of smoothly/continuously scrolling into place.
started: Not specified as a regression — appears to be the current/existing behavior of the
category index menu's scroll-to-section interaction, reported as needing polish.

## Eliminated

- hypothesis: The `.CatalogNav` hook intercepts the category click and performs its own instant
  programmatic scroll (scrollIntoView / scrollTo without a behavior), overriding any CSS.
  evidence: Read the full hook (layouts.ex:174-448). Its only category-click handler is
  `onCatItemClick = () => this.closeCatMenu()` (line 408) — no preventDefault, no scroll call of
  any kind. A repo-wide grep for `scrollIntoView` returns zero hits. The browser's own default
  fragment navigation is what runs, unmodified.
  timestamp: 2026-08-25T08:02:00Z

- hypothesis: The section ids don't match the anchor hrefs, so the browser finds no target and the
  "jump" is actually a failed navigation.
  evidence: Anchors are `href="#carousel-#{row.key}"` and targets are
  `<section id={@id} class="pk-shelf space-y-3">` (carousel_row.ex:227) rendered with
  `id={"carousel-#{row.key}"}`. They match by construction, and the reported symptom is that the
  page DOES reach the correct section — just instantly. Navigation succeeds; only motion is absent.
  timestamp: 2026-08-25T08:04:00Z

- hypothesis: A `prefers-reduced-motion: reduce` rule in the stylesheet is suppressing an
  otherwise-declared smooth scroll.
  evidence: The `reduce` block (app.css:886-905) only sets `transition-duration: 1ms` on a fixed
  list of overlay/transition classes — it contains no `scroll-behavior` declaration at all, and
  none of its selectors is `html`. There is no smooth scroll anywhere for it to suppress.
  timestamp: 2026-08-25T08:06:00Z

- hypothesis: Tailwind preflight, daisyUI, or the asset pipeline strips/overrides a
  `scroll-behavior: smooth` that the app intends to set.
  evidence: Nothing is authored to be stripped — the authored CSS declares `scroll-behavior` exactly
  once (`auto`, on `.pk-rail`). Inspecting the COMPILED output confirms the pipeline adds no
  document-level smooth scroll either: the sole `smooth` belongs to daisyUI's unused `.carousel`.
  timestamp: 2026-08-25T08:07:00Z

## Evidence

- timestamp: 2026-08-25T07:58:00Z
  checked: Knowledge base (.planning/debug/knowledge-base.md) for prior matching sessions.
  found: No prior entry on scroll animation or fragment navigation. The nearest neighbours
  (search-expand-header-overlap, search-right-align-mobile) are header-layout issues, not motion.
  implication: No known-pattern shortcut applies; investigate from first principles.

- timestamp: 2026-08-25T07:59:00Z
  checked: Repo-wide grep for `scrollIntoView|scroll-behavior|scroll_to|scrollTo` across lib/ and
  assets/.
  found: Only five hits. `about_live.ex:94` and `show.ex:255` are explicit
  `behavior: "smooth"` programmatic scrolls on unrelated surfaces. `app.css:296` is
  `scroll-behavior: auto`. The remaining two are `overscroll-behavior-x`, a different property.
  implication: Nothing in the app animates the category anchor navigation, and nothing declares
  smooth scrolling for the page itself.

- timestamp: 2026-08-25T08:01:00Z
  checked: Both category surfaces' markup — `Layouts.category_menu/1` (desktop mega-menu) and the
  `:subnav` chip row on `CatalogLive.Index`.
  found: Both render plain native anchors to the same target scheme —
  `<a href={"#carousel-#{row.key}"} data-chip-target={...}>` at layouts.ex:639-647 and
  index.ex:549-556.
  implication: One shared mechanism drives both surfaces, which explains why the symptom
  reproduces identically on mobile and desktop. A single fix at the mechanism level covers both.

- timestamp: 2026-08-25T08:02:00Z
  checked: The full `.CatalogNav` colocated hook (layouts.ex:174-448).
  found: The category-item listener is `onCatItemClick = () => this.closeCatMenu()` (line 408) —
  it closes the panel and nothing else. No preventDefault, no scroll invocation.
  implication: The click's default action (native fragment navigation) proceeds untouched, so the
  scroll animation is 100% governed by CSS `scroll-behavior`, not by JS.

- timestamp: 2026-08-25T08:03:00Z
  checked: `.pk-shelf` rule (app.css:244-258) and the anchor targets in carousel_row.ex.
  found: Targets are `<section id={@id} class="pk-shelf space-y-3">`, and `.pk-shelf` already
  declares `scroll-margin-top: calc(var(--pk-header-h, 4.5rem) + 1rem)`.
  implication: The landing OFFSET is already solved and header-aware. The defect is strictly the
  absence of animation — no positioning work is needed as part of the fix.

- timestamp: 2026-08-25T08:05:00Z
  checked: `html`/`body` overflow declarations, to identify the real document scrolling element.
  found: Neither carries `overflow` in its default state; the only hits are the transient
  `body.pk-sheet-open` (app.css:576) and `body.pk-drawer-open` (app.css:1767) scroll locks.
  implication: The viewport/`html` is the document scrolling element, so `html`'s
  `scroll-behavior` is the property that governs fragment-navigation animation. It is unset.

- timestamp: 2026-08-25T08:07:00Z
  checked: The COMPILED bundle (priv/static/assets/css/app.css) for every `scroll-behavior` value,
  to rule out the pipeline injecting one.
  found: Exactly two real declarations. `auto` (`.pk-rail`), and `smooth` at line 2573 nested
  inside daisyUI's `.carousel` component under `@media (prefers-reduced-motion: no-preference)`.
  Neither targets `html`/`:root`/`body`.
  implication: ROOT CAUSE CONFIRMED — no smooth scroll ever applies to the page scroller, so the
  CSS initial value `auto` governs and every category anchor jumps instantly, per spec. It also
  supplies the precedent: daisyUI itself gates smooth scrolling behind a no-preference query.

- timestamp: 2026-08-25T08:08:00Z
  checked: AND-gate — whether a global `html` smooth could disturb any other scroller (the exact
  animation-fight failure app.css:289-296 documents for `.pk-rail`).
  found: `scroll-behavior` is not an inherited property. The only per-frame scroll writer is
  `.CarouselScroll` setting `rail.scrollLeft` (carousel_row.ex:85,92) on `.pk-rail`, which is
  outside the inheritance path and additionally pins its own `auto`. `.pk-chip-nav` scrolls
  horizontally but is never driven programmatically. `.pk-cat-panel` is `position: absolute`
  (app.css:1061) closing via opacity/visibility, so it cannot reflow the document mid-scroll.
  implication: A single `html`-scoped declaration is both sufficient and side-effect-free. No
  second contributing condition exists — the fix is one declaration.

- timestamp: 2026-08-25T08:25:00Z
  checked: FIX VERIFICATION — computed styles in real headless Chrome against the compiled bundle,
  using a harness page carrying `.pk-rail`, `.pk-shelf#carousel-x` and a `.pk-chip` anchor.
  found: `html.scrollBehavior = smooth`; `document.scrollingElement === document.documentElement`
  is true; `pk-rail.scrollBehavior = auto`; `body.scrollBehavior = auto`;
  `pk-shelf.scrollMarginTop = 88px` (the 4.5rem fallback + 1rem, resolving as designed).
  implication: The fix reaches exactly the element that governs fragment-navigation animation, and
  reaches nothing else. `body` and `.pk-rail` both still computing `auto` is direct empirical proof
  of the non-inheritance argument in the AND-gate — the carousel's per-frame scrollLeft writer
  cannot be disturbed.

- timestamp: 2026-08-25T08:30:00Z
  checked: REVERT TEST (guardrail signal — does the bug return when the fix is removed?). Restored
  `git show HEAD:assets/css/app.css`, rebuilt assets, re-measured, then restored the fix and
  rebuilt again.
  found: Before fix `html.scrollBehavior = auto`; after fix `html.scrollBehavior = smooth`. Every
  other measured value byte-identical across both runs, including `pk-rail = auto`.
  implication: The single added declaration is causally responsible for the behavior change, with
  zero collateral effect. This is the strongest available confirmation that the diagnosed cause is
  the real one — removing it reproduces the reported symptom exactly.

- timestamp: 2026-08-25T08:33:00Z
  checked: Reduced-motion behavior, via Chrome's `--force-prefers-reduced-motion`.
  found: `html.scrollBehavior = auto` — the smooth scroll correctly disappears for a visitor who
  has asked for reduced motion.
  implication: The accessibility gate works as intended; the no-preference wrapper is doing real
  work rather than being decorative.

- timestamp: 2026-08-25T08:37:00Z
  checked: Regression gates — full `mix quality` (hex.audit, deps.audit, deps.unlock --check-unused,
  format --check-formatted incl. Styler, credo --strict, sobelow, test) and the diff shape.
  found: Exit code 0. 453 tests, 0 failures. Diff is 37 insertions / 0 deletions on one file. The
  only sobelow output is pre-existing low-confidence findings in untouched files
  (seed/report.ex:142, catalog_live/index.ex:178).
  implication: No regression, and the change is purely additive — nothing was deleted or weakened
  to make the symptom disappear.

- timestamp: 2026-08-25T08:48:00Z
  checked: HUMAN VERIFICATION — the one signal no measurement could supply. User exercised both
  surfaces in a real browser: the desktop mega-menu and the mobile chip row, on both adjacent-shelf
  hops and long first-to-last jumps (the case the blind-spot note flagged as most likely to read
  as slow, since native smooth scroll's duration grows with distance).
  found: "Confirmed fixed" — the motion reads as polished, continuous and subtle on both mobile
  and desktop. No escalation requested.
  implication: The aesthetic criterion at the heart of the original report is met by the browser's
  own easing curve. The standby escalation (a JS per-frame `easeOutSoft` scroller) is therefore NOT
  built — it would have added an animation loop, a `prefers-reduced-motion` branch and a second
  scroll-position writer to solve a problem the user says does not exist. Native behaviour won on
  its merits, not by default.

- timestamp: 2026-08-25T08:52:00Z
  checked: RECURRENCE GUARD — wrote `test/pukllay_club_web/category_anchor_scroll_test.exs` and
  RED-verified it by reverting `assets/css/app.css` to HEAD, rebuilding assets, and re-running.
  found: 3 of 7 assertions fail on the pre-fix tree with their intended diagnostics (the `html`
  smooth declaration, the reduced-motion gate, and the built-bundle end-to-end check); all 7 green
  once the fix is restored and assets rebuilt. Full `mix quality` exit 0 afterwards — 460 tests
  (453 + 7), 0 failures.
  implication: The guard fails on the real defect rather than merely passing on the fix, which is
  the only version of that claim worth recording. The 4 assertions that stayed green by
  construction are boundary neighbours guarding the opposite wrong changes, not filler.

## Resolution

root_cause: The category index menu's entries — on BOTH surfaces (the desktop `.pk-cat-item`
mega-menu rows in `Layouts.category_menu/1` and the mobile `.pk-chip` row on `CatalogLive.Index`)
— are plain native anchors (`<a href="#carousel-KEY">`), and the `.CatalogNav` hook deliberately
does not intercept their click (`onCatItemClick` only closes the panel). Native fragment
navigation is animated only when the document's scrolling element computes
`scroll-behavior: smooth`. `assets/css/app.css` never declares that for `html`: its single
authored `scroll-behavior` is a deliberate `auto` scoped to `.pk-rail`, and the only `smooth` that
reaches the compiled bundle belongs to daisyUI's `.carousel` — a component this app does not use.
With the CSS initial value `auto` in force on `html`, an instantaneous jump is the
specification-mandated behavior. The section offset was never the problem: `.pk-shelf` already
carries a header-aware `scroll-margin-top`, so the jump lands correctly — it simply lands
instantly.

fix: Declared `scroll-behavior: smooth` on `html`, wrapped in
`@media (prefers-reduced-motion: no-preference)`, inside the sanctioned PK CATALOG SURFACES block
in `assets/css/app.css` — placed immediately above `.pk-shelf`, whose `scroll-margin-top` is the
other half of the same interaction (that rule says where an anchor lands; this one says how it
gets there). One declaration, no markup and no JS changes, because both category surfaces were
already riding the same native browser mechanism. The no-preference wrapper follows the file's
existing motion discipline (`.pk-scroll-top`'s bounce) and daisyUI's own `.carousel` rule, which
gates its smooth scroll identically.

verification:
  - signal: "root cause reaches the governing element"
    result: PASS — headless Chrome computes `html.scrollBehavior = smooth`, and
      `document.scrollingElement === document.documentElement` confirms `html` is the scroller
      whose value governs fragment navigation.
  - signal: "revert test — does the bug return without the fix?"
    result: PASS — reverting app.css to HEAD and rebuilding returns `html.scrollBehavior = auto`
      (the reported instant-jump behavior); restoring the fix returns `smooth`. Causality proven
      in both directions, all other measured values unchanged.
  - signal: "no collateral damage to other scrollers"
    result: PASS — `.pk-rail` and `body` both still compute `auto`, empirically confirming
      `scroll-behavior` did not inherit and that the carousel's per-frame `scrollLeft` writer
      (`.CarouselScroll`) cannot enter the competing-animation fight app.css:289-296 warns about.
  - signal: "accessibility gate"
    result: PASS — under `--force-prefers-reduced-motion`, `html.scrollBehavior` falls back to
      `auto`, so a reduced-motion visitor keeps the instant jump.
  - signal: "regression suite + static analysis"
    result: PASS — `mix quality` exit code 0; 453 tests, 0 failures.
  - signal: "diff shape (not a deletion that merely hides the symptom)"
    result: PASS — 37 insertions, 0 deletions, single file, additive only.
  - signal: "landing offset preserved"
    result: PASS — `.pk-shelf` still computes `scroll-margin-top: 88px`, so the header-aware
      landing position is unchanged; only the motion between positions was added.
  - signal: "human judgement that the motion reads as polished/subtle"
    result: PASS — the reported complaint's aesthetic core, and the one signal no measurement could
      settle. User exercised both surfaces in a real browser (desktop mega-menu, mobile chips;
      adjacent-shelf hops and long first-to-last jumps) and reported "Confirmed fixed" — polished,
      continuous, subtle. The standby escalation (the JS per-frame `easeOutSoft` scroller in
      carousel_row.ex:80-95) was explicitly NOT needed and was not built.
  - signal: "recurrence guard fails on the real defect"
    result: PASS — `test/pukllay_club_web/category_anchor_scroll_test.exs`, RED-verified by
      reverting app.css to HEAD and rebuilding: 3 of 7 assertions fail with their intended
      diagnostics, all 7 green once the fix is restored. `mix quality` exit 0, 460 tests.
  guardrail_verdict: accepted — every signal PASS, including the human aesthetic criterion that
    was the whole point of the report.

files_changed:
  - assets/css/app.css: added an `html { scroll-behavior: smooth }` rule gated on
    `prefers-reduced-motion: no-preference`, above `.pk-shelf` in the PK CATALOG SURFACES block.
  - test/pukllay_club_web/category_anchor_scroll_test.exs: new recurrence guard (7 assertions,
    3 RED-verified).

## Prevention

why_not_caught: No gate existed for this class, and none of the branches could have caught it.
*Code:* there is no defect to see — both surfaces' anchors are correct, idiomatic and identical,
and `.CatalogNav` not intercepting the click is deliberate. The bug is an ABSENT declaration, and
absence has no diff to review; nothing in `app.css` looked wrong because nothing in `app.css` was
wrong, it was merely incomplete. *Config:* `mix quality` (hex.audit, deps.audit, format, credo
--strict, sobelow, test) parses Elixir sources only and never reasons about CSS semantics, and
LightningCSS has no opinion about a property you did not write. *Environment:* the CSS initial
value for `scroll-behavior` is `auto`, so the browser was behaving exactly to spec — there is no
console warning, no error, no degraded state to detect. The symptom was visible only to a human
watching the page move, which is why it survived from the feature's original build rather than
arriving as a regression.

generalizable_lesson: A missing CSS declaration whose initial value is *also* a valid behaviour is
invisible to every layer of a toolchain — the page works, it just works in the un-designed way.
The tell here was linguistic rather than technical: the codebase's own comments already called the
interaction a "chip-anchor jump" (app.css:249, 486), i.e. the code had been describing the defect
in plain language the whole time. When a symptom is "the app does the boring default", check
whether anyone ever declared the interesting one, before looking for something that broke it.
Second lesson: a fix that costs one declaration should not be talked up into a JS animation loop.
The escalation was scoped, held in reserve, and dropped the moment the cheap fix cleared the bar it
was actually judged against.

recurrence_guard: `test/pukllay_club_web/category_anchor_scroll_test.exs` — 7 assertions, running
inside `mix test` and therefore inside `mix quality` and CI. Oracle type: **derived (contract)** —
the real proof is a browser animating a scroll over ~500ms, which ExUnit cannot observe, so the
assertions pin the declarations and the markup mechanism that animation is a function of.
**RED-verified (3):** the `html { scroll-behavior: smooth }` declaration, its
`prefers-reduced-motion: no-preference` gate, and an end-to-end check that the rule survives
LightningCSS into `priv/static/assets/css/app.css` (skipped when assets are unbuilt) — all three
fail on the reverted tree with their intended diagnostics. **Boundary neighbours (4), green by
construction, each guarding a specific opposite wrong change:** `.pk-rail` keeps its explicit
`scroll-behavior: auto` (the belt to non-inheritance's braces — without it `.CarouselScroll`'s
per-frame `scrollLeft` writes would fight the browser); `.pk-shelf` keeps its `scroll-margin-top`
(dropping it does not restore the old bug, it makes a worse one — a smooth, deliberate glide to a
heading hidden under the header); both surfaces keep their native `href="#carousel-KEY"` anchors;
and `onCatItemClick` still does not `preventDefault`, with no `scrollIntoView` in layouts.ex —
converting either surface to a JS handler bypasses the CSS mechanism entirely and silently
restores the instant jump.
