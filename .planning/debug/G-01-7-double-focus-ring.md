---
status: diagnosed
trigger: "G-01-7: The main-page search input renders what looks like a 'double' black border/focus ring when focused, instead of a single clean focus ring consistent with the rest of the UI."
created: 2026-08-18T21:10:00.000Z
updated: 2026-08-18T21:30:00.000Z
audit_acknowledged:
  milestone: v1.0
  at: 2026-09-11
  status: diagnosed
---

## Current Focus

hypothesis: CONFIRMED (see Resolution)
test: n/a — diagnose-only mode
expecting: n/a
next_action: none — diagnosis complete, hand off to gsd-planner for gap-closure scoping

## Symptoms

expected: The main-page search input shows a single, clean focus ring when focused, consistent with the rest of the UI's focus styling.
actual: User reported the search input renders what looks like a 'double' black border on focus, likely a browser-default outline and a custom Tailwind/daisyUI focus-ring class both applying simultaneously.
errors: None reported
reproduction: Test 2 in .planning/phases/01-catalog-v1/01-UAT.md — on the main catalog page (/), click/tab into the search input
started: Discovered during UAT (Phase 01-catalog-v1)

## Eliminated

- hypothesis: "A project-authored custom Tailwind focus-ring/outline utility class (e.g. focus:ring, focus:outline-*) collides with daisyUI's own default outline on the search input specifically."
  evidence: >
    Grepped the entire lib/pukllay_club_web tree (*.ex, *.heex) for focus:, focus-within:,
    focus-visible:, ring-, outline-none, outline-hidden — zero matches anywhere in the app.
    CoreComponents.input/1's catch-all branch (lib/pukllay_club_web/components/
    core_components.ex:282-302) is the untouched phx.new-generated default: `class={[@class ||
    "w-full input", @errors != [] && ...]}`. The search form at
    lib/pukllay_club_web/live/catalog_live/index.ex:229-235 calls `<.input type="text" .../>`
    passing no `class` attr at all, so it resolves to the bare `"w-full input"` string. There is
    no second, project-authored ring/outline class anywhere to "collide" with a daisyUI default.
  timestamp: 2026-08-18T21:15:00Z

- hypothesis: "The browser's native default focus outline is stacking on top of daisyUI's custom outline because nothing suppresses the native one."
  evidence: >
    Both are the same CSS `outline` shorthand property on the same element — an authored rule
    (`.input:focus { outline: 2px solid var(--input-color); outline-offset: 2px; }`, compiled
    app.css:709-710) has higher specificity than the UA stylesheet default, so it fully replaces
    (not stacks with) the browser's native outline. Confirmed no global reset removes outline
    project-wide either (only Preflight's standard `:-moz-focusring { outline: auto; }` at
    app.css:104-106, a Firefox-only fallback, irrelevant here). Only one `outline` value can ever
    render per element — this cannot itself produce a visual "double" line.
  timestamp: 2026-08-18T21:20:00Z

## Evidence

- timestamp: 2026-08-18T21:12:00Z
  checked: lib/pukllay_club_web/components/core_components.ex (input/1, all 5 branches) and lib/pukllay_club_web/live/catalog_live/index.ex:228-236
  found: >
    The search field is CoreComponents.input/1's default/catch-all branch, rendered as a bare
    `<input type="text" class="w-full input" .../>` — a native `<input>` element with the
    `.input` daisyUI class applied DIRECTLY to it (not wrapped in a `<label class="input">` /
    `<div class="input">` container). This is stock, unmodified phx.new-generated markup; the
    project has not customized it.
  implication: >
    Whatever visual effect appears is 100% attributable to daisyUI's own `.input` class CSS, not
    to any project-authored override — rules out an app-level styling mistake on this specific
    field.

- timestamp: 2026-08-18T21:16:00Z
  checked: priv/static/assets/css/app.css lines 646-712 (compiled `.input` class definition, daisyUI v5.5.20 via deps/daisyui)
  found: >
    Resting state sets `border-color: var(--input-color)` where `--input-color: color-mix(in
    oklab, var(--color-base-content) 20%, #0000)` — a real (not transparent) but low-opacity
    border, plus a top/bottom inset box-shadow for depth. On `&:focus, &:focus-within` (lines
    703-712) the rule does TWO things simultaneously: (a) redefines `--input-color:
    var(--color-base-content)` — bumping the *same border* to full opacity (this app's light
    theme `--color-base-content` is `#241238`, a near-black dark purple) and switches the
    box-shadow to a non-inset drop-shadow; AND (b) separately adds `outline: 2px solid
    var(--input-color); outline-offset: 2px;` — a second, concentric rectangle drawn 2px outside
    the input's own edge, in the *same* `--input-color` value. There is also a nested bare
    `:where(input) { &:focus, &:focus-within { outline-style: none } }` rule (line 688-695) meant
    to suppress a nested native `<input>`'s own default outline — but per CSS nesting rules a
    bare selector without a leading `&` compiles to a DESCENDANT combinator
    (`.input :where(input)`), so it only matches an `<input>` INSIDE a `.input`-classed wrapper.
    Since here `.input` is on the `<input>` itself (no wrapper), that suppression rule can never
    match this element — moot for this case since it wasn't suppressing this project's own
    outline anyway (see next entry).
  implication: >
    daisyUI's `.input:focus` renders TWO concentric borders 2px apart, both effectively black in
    this project's light theme, by design — a solid border (via border-color/box-shadow) plus a
    separately offset outline ring, both driven by the identical `--input-color` value. This is
    the mechanism producing the reported "double border," and it is intrinsic to the unmodified
    daisyUI `.input` component CSS itself.

- timestamp: 2026-08-18T21:22:00Z
  checked: priv/static/assets/css/app.css lines 837-922 (`.select` class definition) vs. lib/pukllay_club_web/live/catalog_live/index.ex:251 (`<select class="select select-bordered">`)
  found: >
    The sort `<select>` uses the exact same direct-on-native-element pattern (`.select` class
    applied straight to the `<select>` tag, not a wrapper) and its compiled CSS has the identical
    structure: a persistent `border-color: var(--input-color)` plus a `&:focus, &:focus-within`
    block (lines 913-922) that separately adds `outline: 2px solid var(--input-color);
    outline-offset: 2px;` alongside the border/box-shadow — byte-for-byte the same mechanism as
    `.input`.
  implication: >
    This is not localized to the search field. Every plain `.input`/`.select`-styled native form
    control in the app (search box, sort dropdown, and any future `<.input>` usage that doesn't
    pass a custom `class`) exhibits the identical double-ring focus appearance — a project-wide
    consequence of daisyUI v5's `.input`/`.select` component design combined with this codebase's
    universal "class applied directly to the native element" usage pattern (which itself matches
    daisyUI's own documented basic-usage example, not a misuse).

- timestamp: 2026-08-18T21:26:00Z
  checked: "daisyUI official docs (https://daisyui.com/components/input/), fetched live"
  found: >
    daisyUI's own showcased examples include a basic `<input type="text" class="input"/>` (direct
    usage, same pattern as this app) AND, separately, ghost/sticky-search-style Input examples
    that explicitly add `focus:outline-none` / `focus-within:outline-none` on top of `.input` to
    suppress this exact ring when a cleaner look is wanted in that context.
  implication: >
    Confirms the border+offset-outline "double ring" is `.input`'s genuine default focus
    appearance (not a rendering bug or browser quirk) — daisyUI's own docs treat suppressing it
    via an explicit `outline-none`-style override as the standard technique when a single clean
    focus indicator is desired, which is exactly what CLAUDE.md/ui-design-system implies for "a
    single, clean focus ring consistent with the rest of the UI."

## Resolution

root_cause: >
  daisyUI v5.5.20's `.input` component (deps/daisyui, compiled at priv/static/assets/css/app.css
  lines 646-712) renders TWO concentric focus indicators by design, not a project-introduced
  conflict: (1) its own persistent field border (`border-color: var(--input-color)`, plus a
  matching box-shadow), which on `:focus`/`:focus-within` is bumped from a ~20%-opacity mix to
  the full-opacity `--color-base-content` (`#241238`, a near-black dark purple in this project's
  light theme); and (2) a SEPARATE `outline: 2px solid var(--input-color); outline-offset: 2px;`
  rule added in that same `:focus`/`:focus-within` block, drawn 2px outside the input's own edge,
  using the identical color variable. Because both lines resolve to the same near-black color
  with only a 2px gap between them, they read visually as a "double black border." The search
  input at lib/pukllay_club_web/live/catalog_live/index.ex:229-235, via
  CoreComponents.input/1's untouched catch-all branch (core_components.ex:282-302), applies
  `.input` directly to the native `<input>` with no custom `class` and no suppression override —
  stock phx.new-generated markup, not a project styling mistake. The bug report's originally
  suspected mechanism (a custom Tailwind/daisyUI focus-ring class colliding with a leftover
  browser-default outline) does NOT hold: a full-codebase grep found zero `focus:`/`ring-`/
  `outline-none` classes anywhere in lib/pukllay_club_web, and the browser's native default
  outline is simply overridden (not stacked) by daisyUI's own authored `outline` rule on the same
  element/property. Confirmed project-wide, not search-box-specific: the sort `<select>`
  (index.ex:251) uses the identical direct-on-element `.select` pattern and its compiled CSS
  (app.css:837-922) has the byte-for-byte same border+offset-outline focus mechanism — so every
  plain `.input`/`.select` control in the app currently exhibits this same double-ring look; the
  search field is simply the one Test 2 happened to focus/interact with. daisyUI's own docs
  confirm this is the component's genuine default appearance and that suppressing it (e.g. via a
  `focus:outline-none`/`focus-within:outline-none`-style override, as daisyUI's own ghost/search
  Input examples do) is the standard technique for a single, clean focus ring.
fix: (not applied — diagnose-only mode per goal: find_root_cause_only)
verification: (not applicable — diagnose-only mode)
files_changed: []
