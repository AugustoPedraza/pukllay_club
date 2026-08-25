---
phase: quick-260824-jkc
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/pukllay_club_web/components/layouts.ex
  - lib/pukllay_club_web/live/catalog_live/index.ex
  - assets/css/app.css
  - test/pukllay_club_web/live/catalog_live_test.exs
autonomous: true
requirements: [SHELL-01]

estimate:
  tokens: 72000
  raw_tokens: 72000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "At a desktop width the catalog header carries a single 'Explorar categorías' control that is transparent and borderless at rest, changes colour only on hover/open, and rotates its chevron when the panel opens — the same de-emphasised utility restraint the theme toggle already has (sketch 018-B, sketch 020 Round 2 item 4)."
    - "Clicking that control opens one overlay panel listing every populated shelf as a plain typographic row (bold title over a muted one-line subtitle) in a 2-column grid, separated by hairline dividers, with no per-item box, border or fill (sketch 020 Round 2 item 5)."
    - "The panel hangs directly under the control at the right edge of the header's shared content column — it is anchored by its right edge and an explicit width, never by two opposing horizontal offsets, which is the over-constrained-width bug sketch 020 Round 3 diagnosed and fixed."
    - "The panel closes on: clicking the control again, clicking any item in it, clicking the backdrop, and pressing Escape. Clicking an item also jumps the page to that shelf."
    - "No second persistent sticky row is added to the desktop header — orientation and jump live entirely behind that one on-demand overlay (the sketch 011 Rounds 7-8 finding this design was built to respect)."
    - "At a narrow viewport the chip index row is bare-outlined at rest: 1px border, transparent background, muted text — the same outline-at-rest logic production's real filter chip already uses (filter_modal.ex chip_class/1), not the filled block it renders today."
    - "The chip for the shelf currently in view carries a soft accent tint with a primary border, not a solid primary fill — 'you are here' reads as a tint, not a selection block (sketch 020 Round 2 item 1)."
    - "No chip gets a permanent promoted/hero treatment; the Destacados chip looks exactly like the other seven at rest (sketch 020 Round 2 item 2)."
    - "The chip row fades at both ends into the surface behind it, and carries no prev/next scroll buttons — the edge fade plus native touch scroll is the whole affordance (sketch 020 Round 2 item 3)."
    - "The scroll-spy highlights the current shelf on BOTH surfaces from one mechanism: scrolling the page updates the active chip at narrow widths and the active panel row at desktop widths, driven by a single selector in the .CatalogNav hook, not two parallel implementations."
    - "Jumping to a shelf from either surface lands it below the live header rather than under it, at both a narrow viewport (taller header — chip row attached) and a desktop viewport (shorter header), because the landing offset is derived from the --pk-header-h the header already publishes instead of a hardcoded constant."
    - "The chip row's existing iOS-Safari-safe structure is intact: the <nav class=\"pk-chip-nav\"> element still has a pk-chip-spacer span as its first and last child, and still declares no horizontal padding of its own."
    - "All four existing chip-row tests in catalog_live_test.exs still pass unmodified, and the filtered view still renders neither the chip row nor the category menu."
    - "Every new CSS class lives inside the PK CATALOG SURFACES block, resolves colour through daisyUI theme variables (never a literal hex/rgb), and both sides of every viewport display swap are declared in the one trailing max-width:480px block."
    - "`mix quality` passes end to end (hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted, credo --strict, sobelow --config, test --warnings-as-errors)."
    - "The three things ExUnit cannot prove — the panel visually hangs under its trigger, the chip row reads as this app's chip rather than a separate component, and the header row does not overflow between 481px and 768px with the search box open — are each confirmed in a real browser against a running server and recorded in the SUMMARY."
  artifacts:
    - "lib/pukllay_club_web/components/layouts.ex — a nav_menu slot on app/1 threaded into header_inner/1, a category_menu/1 function component rendering trigger + backdrop + panel, and the .CatalogNav hook extended with open/close/Escape/backdrop wiring plus a widened scroll-spy selector."
    - "lib/pukllay_club_web/live/catalog_live/index.ex — one derived shelf list feeding BOTH the subnav chip row and the nav_menu panel, under the same not-filters_active guard."
    - "assets/css/app.css — .pk-cat-trigger / .pk-cat-trigger-label / .pk-cat-backdrop / .pk-cat-panel / .pk-cat-grid / .pk-cat-item and .pk-chip-nav-wrap added inside the PK CATALOG SURFACES block; .pk-chip rest/hover/active retuned; .pk-shelf landing offset derived from --pk-header-h; the max-width:480px block updated so both sides of the chip-row/trigger swap live there; the prefers-reduced-motion selector list extended."
    - "test/pukllay_club_web/live/catalog_live_test.exs — new assertions for the category menu (one item per populated shelf, targets resolve to real section ids, absent on a filtered render) alongside the four untouched chip-row tests."
  key_links:
    - "One derived list in index.ex -> the :subnav chip row AND the :nav_menu panel. If they ever read two separate lists, the chip row and the menu silently drift apart on shelf count or subtitle copy — the exact class of bug sketch-findings names as the single most load-bearing rule in this layer."
    - "data-chip-target on both .pk-chip and .pk-cat-item -> the .CatalogNav hook's scroll-spy selector -> is-active. If the hook keeps querying .pk-chip only, the desktop panel renders but never highlights, and the scroll-spy silently becomes mobile-only again."
    - "--pk-header-h published by .CatalogNav's ResizeObserver -> .pk-shelf's landing offset. If the offset reverts to a constant, the narrow viewport (taller header) lands every shelf underneath the header."
    - ".pk-cat-panel's containing block is .pk-nav-inner (already position: relative). If any ancestor between them gains overflow/transform/filter, the panel is clipped or re-anchored — sketch-findings' recurring 'panel escaping or being clipped by its container' failure."
---

<objective>
Bring PRODUCTION code in line with sketch 020's winning design (variant C, Round 2 minimalism
pass + Round 3 alignment fix): a refined bare-outline mobile chip index row with an edge fade,
and a desktop "Explorar categorías" mega-menu opened from a bare icon+label trigger in the
header, with one shared scroll-spy driving the active state on both surfaces.

Purpose: today `.pk-chip-nav` renders only below 480px as filled pills with a solid-primary
active state and no scroll affordance, and desktop has no shelf-jump affordance at all. The
sketch resolved both without adding the second sticky desktop row that sketch 011 Rounds 7-8
explicitly rejected.

Output: an updated header shell component, one derived shelf list feeding both surfaces, new
`pk-cat-*` / `pk-chip-nav-wrap` CSS inside the existing PK CATALOG SURFACES block, and tests.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md

Load these skills before touching any template or stylesheet — they are binding, not advisory:
- `ui-design-system` (daisyUI-first rule, banned patterns, theme tokens, PK CATALOG SURFACES
  block rules, component inventory)
- `ux-patterns` (B8/B32 navigation, D21 progressive disclosure, D22 action caps)
- `ux-responsive` (breakpoints in force, 44px touch floor, touch-vs-pointer rule)
- `sketch-findings-pukllay_club` (shared-class-per-field rule, content-width alignment, the
  clipped/escaping-panel failure mode)

Winning design source (read both — the README carries the reasoning, index.html the exact
values):
@.planning/sketches/020-catalog-index-row/README.md
@.planning/sketches/020-catalog-index-row/index.html

Sketch-to-production token mapping (the sketch uses its own variable names):
@.planning/sketches/themes/default.css  — see the "Upstream mapping" table at the top.
The ones this plan needs: `--color-surface`→`--color-base-200`, `--color-border`→
`--color-base-300`, `--color-text-muted`→`--color-neutral`, `--color-accent-bg`→
`--color-accent`, `--color-accent-text`→`--color-accent-content`, `--color-bg`→
`--color-base-100`. Sketch `--space-4` is the sketch's own gutter and maps to this repo's
`--pk-gutter` token, never to a re-chosen number.

Production code being changed:
@lib/pukllay_club_web/components/layouts.ex
@lib/pukllay_club_web/live/catalog_live/index.ex
</context>

<tasks>

<task type="tracer">
  <name>Task 1: Desktop "Explorar categorías" mega-menu, wired end to end</name>
  <files>lib/pukllay_club_web/components/layouts.ex, lib/pukllay_club_web/live/catalog_live/index.ex, assets/css/app.css, test/pukllay_club_web/live/catalog_live_test.exs</files>
  <read_first>
    - `lib/pukllay_club_web/components/layouts.ex` lines 106-160 (the `app/1` attrs and slots),
      162-366 (the `.CatalogNav` colocated hook — note the existing drawer block's
      `inert` / `aria-expanded` / idempotent-close / `updated()` / `destroyed()` pattern, which
      this task copies rather than reinvents), and 404-461 (`header_inner/1`).
    - `assets/css/app.css`: the `.pk-nav-inner` rule (already `position: relative` — this is the
      panel's containing block, do not add a second positioned ancestor); the
      `.pk-search-morph` rule (`margin-left: auto`, `flex: 0 0 auto`, 44px collapsed / 17.5rem
      open) and the long comment above `.pk-search-morph.is-open` that does the row-width
      arithmetic; the `.pk-nav-inner.is-search-open` selector list; the `.pk-drawer-backdrop`
      rule; the `@media (prefers-reduced-motion: reduce)` selector list; the two existing
      `@media (min-width: 48rem)` blocks and the comment explaining why they must stay separate;
      and the trailing `@media (max-width: 480px)` block.
    - `lib/pukllay_club_web/live/catalog_live/index.ex` lines 483-496 (the `:subnav` chip row)
      and `row_subtitle/1`.
  </read_first>
  <action>
    Before writing markup, check `core_components.ex` and daisyUI's own component list for a
    dropdown/menu that already covers this (`ui-design-system`'s "state explicitly which one you
    checked and why it doesn't fit" rule). Record the outcome in a comment above the new
    component. Decision rule: if daisyUI's `dropdown` + `dropdown-end` can express the anchoring
    AND coexist with a backdrop, an Escape handler and the scroll-spy's `is-active` class, use
    it and skip the hand-rolled panel positioning below. Otherwise hand-roll inside the PK
    CATALOG SURFACES block and say so in the comment — this page's rails are already the
    sanctioned precedent for one such exception, so a second needs its reason written down.

    (1) `layouts.ex` — add `slot :nav_menu` to `app/1`, documented as "an on-demand category
    overlay rendered inside the header row; the shell owns placement, the page owns contents",
    and thread it into `header_inner/1` as a required attr alongside `nav_links`/`nav_search`/
    `crumb`. Render it inside `.pk-nav-inner` immediately BEFORE the `.pk-search-morph` div.
    Both `app/1` branches (sticky and non-sticky) pass it, matching how the other slots are
    already threaded.

    (2) `layouts.ex` — add a public `category_menu/1` function component taking one attr,
    `rows` (a list of maps with `:key`, `:title`, `:subtitle`). It renders three siblings:
      - a `<button type="button" class="pk-cat-trigger" aria-expanded="false"
        aria-controls="pk-cat-menu" aria-label="Explorar categorías">` containing
        `CoreComponents.icon/1` with `hero-squares-2x2`, a `<span class="pk-cat-trigger-label">`
        holding the visible label, and a second icon `hero-chevron-down-micro`;
      - `<div class="pk-cat-backdrop" aria-hidden="true">`;
      - `<div id="pk-cat-menu" class="pk-cat-panel" inert>` wrapping `<div class="pk-cat-grid">`
        with one `<a class="pk-cat-item" href={"#carousel-#{row.key}"}
        data-chip-target={"carousel-#{row.key}"}>` per row, whose contents are `<strong>` title
        then `<span>` subtitle.
    The `data-chip-target` attribute name is deliberate — it is the existing contract the
    scroll-spy already reads, so the panel joins the spy for free in Task 2 instead of getting
    a parallel one. `inert` on the closed panel mirrors the drawer's closed state exactly.

    (3) `index.ex` — extract the shelf list into one private helper (e.g. `index_rows/1`)
    returning `%{key:, title:, subtitle:}` for `Enum.filter(@carousel_rows, &(&1.games != []))`,
    with `subtitle` from the existing `row_subtitle/1`. Feed BOTH the existing `:subnav` chip
    row and a new `:nav_menu` slot from that single call, under the same
    `:if={not filters_active?(assigns)}` guard the chip row already carries. Two independently
    built lists here is the exact drift failure `sketch-findings-pukllay_club` names as this
    layer's most load-bearing rule — one list, two consumers.

    (4) `assets/css/app.css`, inside the PK CATALOG SURFACES block and BEFORE the trailing
    narrow-viewport block:
      - `.pk-cat-trigger` — `display: inline-flex; align-items: center; gap: 0.5rem;
        min-height: 44px;` (the repo's touch floor, `ux-responsive`), `margin-left: auto` so it
        absorbs the row's free space and lands adjacent to the search pill at the right edge,
        no border, transparent background, `color: var(--color-neutral)`, `flex: 0 0 auto`,
        and a colour-only transition using `var(--duration-fast) var(--ease-standard)`.
        `:hover`, `:focus-visible` and `.is-open` all resolve to `color: var(--color-primary)` —
        nothing gains a border or a fill in any state.
      - the trailing chevron icon rotates 180deg when the trigger has `.is-open`.
      - `.pk-cat-trigger-label` — `display: none` at base. Add a THIRD, separate
        `@media (min-width: 48rem)` block (do not merge it into either existing one; the
        comment on the second block explains why they are kept apart) revealing it. Below
        48rem the trigger is icon-only, which is why the `aria-label` above is unconditional
        and not a decoration. This reuses an existing breakpoint rather than inventing one, and
        it is what keeps the 481-768px row — where the brand wordmark is already hidden and the
        row width arithmetic is tightest — from overflowing.
      - `.pk-cat-backdrop` — share the dim treatment with the drawer rather than declaring a
        second one: split the existing `.pk-drawer-backdrop` rule so its `display: none` sits in
        its own single-selector rule, and add `.pk-cat-backdrop` to the selector list carrying
        the shared `position: fixed; inset: 0; background: color-mix(...); opacity: 0;
        pointer-events: none; transition: ...` declarations. Give `.pk-cat-backdrop` its own
        `z-index` (below the panel, above `.pk-nav`) and an `.is-open` rule setting
        `opacity: 1; pointer-events: auto`.
      - `.pk-cat-panel` — `position: absolute`, anchored to `.pk-nav-inner` by its `right`
        offset set to `var(--pk-gutter)` plus an explicit `width` (the sketch's 480px, expressed
        in rem) and a `max-width` guard. Declaring an opposing horizontal offset alongside
        `right` is forbidden here: per the CSS over-constrained-width rules the box would
        resolve start-anchored and visually detach from its trigger, which is precisely the bug
        sketch 020 Round 3 fixed. `top` resolves from the row itself (e.g. `100%` plus a small
        gap) rather than a hardcoded header height. Surface: `background:
        var(--color-base-100)`, `border: 1px solid var(--color-base-300)`, `border-radius:
        var(--radius-box)`, a shadow via the file's existing `color-mix`-for-alpha idiom,
        padding, and a closed state of `opacity: 0; visibility: hidden;
        transform: translateY(-8px)` transitioning to the open state on `.is-open`.
      - `.pk-cat-grid` — `display: grid; grid-template-columns: 1fr 1fr;`.
      - `.pk-cat-item` — `display: block`, padding, `border-bottom: 1px solid
        var(--color-base-300)` and NOTHING else boxing it: no per-item background, no radius,
        no side or top border. `:nth-last-child(-n+2)` drops the divider on each column's last
        row. `:hover` and `.is-active` shift `color` to `var(--color-primary)`; the nested
        `<strong>` is the bold title and the nested `<span>` is `font-size: 0.75rem;
        color: var(--color-neutral)` at rest.
      - extend the existing `.pk-nav-inner.is-search-open` selector list that already hides the
        nav links so the trigger yields the row when the 17.5rem search pill opens — the pill's
        width was measured against a row that did not contain this control.
      - add `.pk-cat-panel` and `.pk-cat-backdrop` to the existing
        `@media (prefers-reduced-motion: reduce)` selector list.
      - in the trailing `@media (max-width: 480px)` block, hide `.pk-cat-trigger`. Both sides of
        every viewport swap belong in that one block, per the comment that opens it.

    (5) `layouts.ex`, `.CatalogNav` hook — add a block guarded on the trigger existing (so
    Quiénes Somos and Detalle are untouched no-ops), modelled line for line on the drawer block
    directly above it: `openCatMenu` / idempotent `closeCatMenu` toggling `.is-open` on trigger,
    panel and backdrop, flipping `aria-expanded`, and adding/removing `inert` on the panel;
    trigger click toggles; backdrop click closes; a document `keydown` handler closes on Escape;
    every `.pk-cat-item` click closes (the `href` anchor does the jump, no scroll JS). Call
    `closeCatMenu?.()` from `updated()` (idempotent, same reason the drawer does) and remove
    every listener in `destroyed()`.

    (6) `test/pukllay_club_web/live/catalog_live_test.exs` — add a describe block asserting: an
    unfiltered landing render emits one `.pk-cat-item` per populated shelf; its
    `data-chip-target` values are identical to the chip row's and each resolves to a real
    section id in the document; a shelf with zero games produces no item; and a filtered render
    emits no `pk-cat-panel`. Do not touch the four existing chip-row tests.

    Verify in a browser that no ancestor between `.pk-cat-panel` and `.pk-nav-inner` clips or
    re-anchors it. If it is clipped, find and name the clipping ancestor rather than escalating
    `z-index` — an overlay escaping or being clipped by its container is the recurring failure
    `sketch-findings-pukllay_club` documents, and `z-index` does not fix an `overflow` clip.
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/live/catalog_live_test.exs</automated>
    <automated>test "$(awk '/^\.pk-cat-panel \{/,/^\}/' assets/css/app.css | grep -v '^ *[*/]' | grep -Ec '^[[:space:]]*(left|right|inset[a-z-]*):')" = 1</automated>
    <automated>test "$(awk '/^\.pk-cat-panel \{/,/^\}/' assets/css/app.css | grep -v '^ *[*/]' | grep -Ec '^[[:space:]]*width:')" = 1</automated>
    <automated>awk '/PK CATALOG SURFACES START/,/PK CATALOG SURFACES END/' assets/css/app.css | grep -q 'pk-cat-panel'</automated>
  </verify>
  <done>An unfiltered `/` render emits a `.pk-cat-trigger` plus one `.pk-cat-item` per populated shelf whose `data-chip-target` matches the chip row's; a filtered render emits neither; the panel rule anchors by `right` + an explicit width with no opposing offset; every new class sits inside the PK CATALOG SURFACES block; the four existing chip-row tests pass unmodified.</done>
</task>

<task type="auto">
  <name>Task 2: Mobile chip row refinement, shared scroll-spy, and header-aware landing offset</name>
  <files>lib/pukllay_club_web/components/layouts.ex, lib/pukllay_club_web/live/catalog_live/index.ex, assets/css/app.css, test/pukllay_club_web/live/catalog_live_test.exs</files>
  <read_first>
    - `assets/css/app.css`: the `.pk-chip-nav` / `.pk-chip-spacer` / `.pk-chip` group and the
      comment above it explaining why the spacers exist instead of padding (iOS Safari drops the
      trailing padding of a horizontally scrolling element); the `.pk-rail-wrap::before` /
      `::after` edge-fade pair, which is the mechanism to mirror; `.pk-shelf`; and the trailing
      `@media (max-width: 480px)` block where `.pk-chip-nav` is revealed today.
    - `test/pukllay_club_web/live/catalog_live_test.exs` lines 676-735 — in particular the two
      regexes asserting the first and last children inside `<nav class="pk-chip-nav">` are
      `pk-chip-spacer` spans. These must keep passing untouched, which constrains where the new
      wrapper element can go.
    - `layouts.ex` `.CatalogNav` hook lines 174-202 (the scroll-spy) and 204-215 (the
      `--pk-header-h` publisher — this hook is the sole publisher; do not add a second).
  </read_first>
  <behavior>
    - An unfiltered landing render still puts a `pk-chip-spacer` span as the very first and very
      last child inside `<nav class="pk-chip-nav">` (existing regex assertions, unmodified).
    - That `<nav>` is now wrapped by a `.pk-chip-nav-wrap` element that is its direct parent.
    - Chip count still equals populated-shelf count, and each `data-chip-target` still resolves
      to a real section id (existing assertions, unmodified).
    - A filtered render still emits no chip row.
  </behavior>
  <action>
    (1) `index.ex` — wrap the existing `<nav class="pk-chip-nav" aria-label="Categorías">` in a
    new `<div class="pk-chip-nav-wrap">`. The `<nav>` element, its `aria-label`, its class, and
    its two bracketing spacer spans stay exactly as they are: the wrapper exists only because a
    gradient pseudo-element on the scrolling element itself would scroll away with the chips,
    which is why `.pk-rail-wrap` and `.pk-rail` are already two elements rather than one. Keep
    the `:if={not filters_active?(assigns)}` guard on the outermost element.

    (2) `assets/css/app.css` — retune `.pk-chip` to the sketch's Round 2 values, translated
    through the token mapping in `<context>`:
      - rest: keep the existing 1px border, `min-height: 44px` and radius; change the background
        to `transparent` and the text to `var(--color-neutral)`. This is the same
        outline-at-rest logic `filter_modal.ex`'s `chip_class/1` already ships — the chip stops
        looking like a separate component with its own rules.
      - add `:hover` and `:focus-visible` states resolving border and text to
        `var(--color-primary)`.
      - `.is-active` becomes `background: var(--color-accent); color: var(--color-accent-content);
        border-color: var(--color-primary)` — a soft tint, not the solid primary fill it renders
        today. The `-content` pairing is deliberate over the sketch's literal `--color-primary`
        text: in the light theme the two resolve to the identical value, and in the dark theme
        only the `-content` pairing clears the contrast floor against the accent surface.
      - add the same colour/border transition duration the rest of this layer uses.
      - do NOT add any promoted or hero variant for the first chip (sketch 020 Round 2 item 2),
        and do NOT add prev/next scroll buttons (item 3).

    (3) `assets/css/app.css` — add `.pk-chip-nav-wrap`: `position: relative`, `background:
    var(--color-base-200)` and `border-top: 1px solid var(--color-base-300)` so the row reads as
    its own band under the header exactly as the sketch's index band does, plus `::before` /
    `::after` 24px gradient fades mirroring `.pk-rail-wrap`'s pair — `position: absolute;
    top: 0; bottom: 0; pointer-events: none;` with a `z-index` above the chips, each gradient
    running from `var(--color-base-200)` to `transparent`. The gradient endpoint token and the
    wrapper's own background must be the same token, declared here and nowhere else, or the fade
    visibly fails in one of the two themes.

    Move the viewport swap onto the wrapper: `.pk-chip-nav-wrap { display: none }` at base and
    `display: block` inside the trailing `@media (max-width: 480px)` block (replacing the
    `.pk-chip-nav` entry that lives there today), and make `.pk-chip-nav` itself
    unconditionally `display: flex`. The wrapper cannot use `display: contents` — that would
    discard the `position: relative` the fades depend on. Both sides of this swap and Task 1's
    trigger swap stay in that one trailing block.

    (4) `layouts.ex` `.CatalogNav` hook — widen the scroll-spy's collection query from the
    chip-only class selector to the `data-chip-target` attribute selector, so the desktop
    panel's items join the existing observer instead of getting a second one. The Map, the
    IntersectionObserver, its `rootMargin`, the topmost-entry sort, and the `is-active` class
    name all stay exactly as they are; only the collection query and the local variable naming
    change. Both surfaces then light up from the one mechanism.

    (5) `assets/css/app.css` — change `.pk-shelf`'s landing offset from its hardcoded constant
    to one derived from `var(--pk-header-h, 4.5rem)` plus a small gap, matching the fallback
    form the two existing consumers of that custom property already use. This is what makes a
    jump land correctly under BOTH the taller narrow-viewport header (chip row attached) and the
    shorter desktop one, which the sketch achieved by re-measuring the header on every click.
    Do not add a page-level smooth-scroll declaration — the jump stays the native anchor jump it
    is today; only the offset changes.

    (6) `test/pukllay_club_web/live/catalog_live_test.exs` — add one assertion that the chip
    `<nav>` is wrapped by `.pk-chip-nav-wrap`. Leave the four existing chip-row tests byte
    identical; if any of them fails, the wrapper went in the wrong place — fix the markup, not
    the test.
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/live/catalog_live_test.exs</automated>
    <automated>awk '/^\.pk-shelf \{/,/^\}/' assets/css/app.css | grep -q 'pk-header-h'</automated>
    <automated>awk '/^\.pk-chip \{/,/^\}/' assets/css/app.css | grep -v '^ *[*/]' | grep -Eq '^[[:space:]]*background:[[:space:]]*transparent'</automated>
    <automated>awk '/@media \(max-width: 480px\)/,0' assets/css/app.css | grep -q 'pk-chip-nav-wrap'</automated>
    <automated>grep -q 'a filtered render emits no chip row' test/pukllay_club_web/live/catalog_live_test.exs</automated>
    <automated>grep -q 'a shelf backed by zero games produces no chip for it' test/pukllay_club_web/live/catalog_live_test.exs</automated>
  </verify>
  <done>Chips render transparent-at-rest with a muted label, a soft accent tint when active, and an edge fade at both ends; the scroll-spy drives `is-active` on chips and panel items from one selector; `.pk-shelf`'s landing offset reads the published header height; the four existing chip-row tests are still present in the file and still pass.</done>
</task>

<task type="auto">
  <name>Task 3: Full quality gate and live two-viewport confirmation</name>
  <files>assets/css/app.css, lib/pukllay_club_web/components/layouts.ex, lib/pukllay_club_web/live/catalog_live/index.ex</files>
  <precondition>A dev server is reachable (`mix phx.server` on localhost:4000) with a seeded catalog — the shelf-jump, scroll-spy and panel-anchoring checks below all need real shelves rendered, and every one of them is invisible to ExUnit.</precondition>
  <action>
    Run `mix quality` and fix anything it reports. Styler runs inside `format --check-formatted`
    and can rewrite semantics, so review every rewrite it produces in `git diff` per hunk rather
    than accepting it on trust (CLAUDE.md's standing caveat on this tool).

    Then confirm the three behaviours ExUnit provably cannot reach, against a running server,
    and record what you observed — not just "looks right" — in the SUMMARY:
      a. At 1280px: the panel's right edge lines up with the trigger and the header's shared
         content column, not with the frame's opposite edge. Record the measured x-coordinates
         of the panel's right edge and the header row's right content edge.
      b. At 390px: scrolling the page moves the highlight from chip to chip on its own, and
         tapping a chip lands its shelf heading fully below the header rather than beneath it.
         Record the shelf heading's top offset after a jump versus the header's height.
      c. Between 481px and 768px with the search box opened: the header row stays on one line
         with no horizontal scrollbar on the document. Record the document's scrollWidth versus
         its clientWidth at 481px and at 768px, search open and closed.
    Check both themes for (a) and (b) — the fade token and the active-chip tint each resolve
    differently in light and dark, and a wrong token is invisible in exactly one of them.
  </action>
  <verify>
    <automated>mix quality</automated>
    <human-check>At 1280px the "Explorar categorías" trigger reads as quiet utility chrome next to the search control — no border, no fill — and its panel hangs directly beneath it; the panel's rows scan as a plain list, with enough structure from the hairline dividers alone that no per-item box is missed. At 390px the chip row reads as this app's chip family (the same outline-at-rest language as the filter chips), fades at both ends, and shows no scroll buttons.</human-check>
  </verify>
  <done>`mix quality` passes end to end; the three live checks above are performed in both themes with the observed numbers written into the SUMMARY.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| browser DOM → LiveView | No new boundary crossing: this task adds no form field, no `phx-click` handler, no `phx-value-*` payload and no route. The category menu is opened and closed entirely client-side by the existing `.CatalogNav` colocated hook; every item is a plain in-page `href` anchor. |
| server-rendered content → DOM | Shelf titles and subtitles come from `Vocabulary` / `row_subtitle/1` — compile-time application constants, not user or database free text — and are interpolated through HEEx, which escapes by default. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-jkc-01 | Tampering | `category_menu/1` item titles/subtitles rendered into the panel | low | mitigate | Values stay sourced from the existing `index_rows/1` helper over `Vocabulary`-backed constants and are rendered through HEEx interpolation (auto-escaped). Do not introduce `raw/1`, `Phoenix.HTML.raw` or any `innerHTML` assignment in the hook — the hook only toggles classes and attributes. |
| T-jkc-02 | Denial of Service | `.CatalogNav` IntersectionObserver / listener lifecycle | low | mitigate | The widened scroll-spy selector reuses the one existing observer rather than adding a second; every new listener added in `mounted()` is removed in `destroyed()`, matching the drawer block's existing symmetry, so repeated LiveView navigations cannot accumulate handlers. |
| T-jkc-03 | Information Disclosure | shelf list exposed by the panel on a filtered render | low | accept | The panel lists the same public shelf names the chip row and the carousel headings already render to every anonymous visitor; it is additionally suppressed on filtered renders by the same guard the chip row uses. No new data reaches the client. |
| T-jkc-SC | Tampering | npm/pip/cargo installs | high | mitigate | Not applicable — this task installs no package. `mix.exs` and `mix.lock` are not in `files_modified`; if a dependency turns out to be needed, stop and re-plan with the package-legitimacy gate rather than adding one inline. `mix quality` still runs `hex.audit` + `deps.audit` + `deps.unlock --check-unused` over the unchanged lockfile in Task 3. |
</threat_model>

<verification>
- `mix quality` passes end to end.
- The four pre-existing chip-row tests in `catalog_live_test.exs` pass without edits.
- An unfiltered `/` render emits: a `.pk-cat-trigger`, one `.pk-cat-item` per populated shelf,
  the `.pk-chip-nav-wrap` wrapper, and a `.pk-chip-nav` whose first and last children are
  still spacer spans.
- A filtered render emits neither the chip row nor the category panel.
- `.pk-cat-panel` anchors by `right` + an explicit width, with no opposing horizontal offset.
- Every new class lives between the `PK CATALOG SURFACES START` / `END` markers, uses only
  daisyUI theme variables for colour, and declares both sides of each viewport swap inside the
  single trailing `@media (max-width: 480px)` block.
- No new `@media` breakpoint value is introduced: the trigger label reuses 48rem, the chip row
  and trigger swap reuse 480px.
</verification>

<success_criteria>
Production matches sketch 020's Round 2 + Round 3 winning design at both viewports: a
bare-outline, edge-faded, soft-tint-active chip index row below 480px, and a borderless
icon+label trigger opening a right-anchored, unboxed-list mega-menu above it — both highlighted
by one shared scroll-spy, both jumping to a shelf that lands below the live header, with no
second sticky desktop row anywhere.
</success_criteria>

<output>
Create `.planning/quick/260824-jkc-implement-sketch-020-s-winning-design-re/260824-jkc-SUMMARY.md` when done.
</output>
</content>
</invoke>
