---
phase: quick-260821-dah
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/pukllay_club_web/components/filter_drawer.ex
  - lib/pukllay_club_web/components/layouts.ex
  - lib/pukllay_club_web/components/core_components.ex
  - assets/css/app.css
  - test/pukllay_club_web/components/filter_drawer_test.exs
  - test/pukllay_club_web/components/layouts_test.exs
  - test/pukllay_club_web/components/core_components_test.exs
  - .claude/skills/ui-design-system/SKILL.md
  - .planning/todos/pending/*.md
  - .planning/todos/completed/*.md
autonomous: false
requirements: [UI-AUDIT-01, UI-AUDIT-02, UI-AUDIT-03, UI-AUDIT-04, UI-AUDIT-05, UI-AUDIT-06, UI-AUDIT-07]

estimate:
  tokens: 90000
  raw_tokens: 45000
  tasks: 5
  confidence: low

must_haves:
  truths:
    - "A tap anywhere on the Filtros label opens the filter drawer — no part of it resolves to the sort select underneath."
    - "A screen-reader user hears three distinctly-named theme controls (system / claro / oscuro), not three anonymous buttons."
    - "Every tappable control in the shared app header measures at least 44px on both axes."
    - "The brand tagline renders through theme tokens only — no arbitrary-value or opacity-suffixed color class."
    - "CoreComponents.button/1 offers a non-filled tier, so a filled btn-primary reads as the page's one action."
    - "The catalog browse screen's distinct font size/weight/family combinations are measured, and every surviving combo above the 3-tier cap is a documented, deliberate exception."
    - "All 7 audit todos are recorded as resolved in .planning/todos/completed/ with a Resolution section."
  artifacts:
    - test/pukllay_club_web/components/filter_drawer_test.exs
    - test/pukllay_club_web/components/core_components_test.exs
    - .planning/todos/completed/2026-08-18-fix-sort-dropdown-overlapping-filtros-button.md
    - .planning/todos/completed/2026-08-18-fix-theme-toggle-accessible-names-and-hit-target.md
    - .planning/todos/completed/2026-08-18-fix-brand-logo-link-touch-target.md
    - .planning/todos/completed/2026-08-18-fix-brand-tagline-banned-tailwind-patterns.md
    - .planning/todos/completed/2026-08-18-reserve-btn-primary-for-a-single-page-action.md
    - .planning/todos/completed/2026-08-18-fix-ver-detalles-card-cta-touch-target.md
    - .planning/todos/completed/2026-08-18-reduce-font-combos-on-catalog-screen.md
  key_links:
    - "FilterDrawer's grid wrapper -> the flex toolbar row in CatalogLive.Index that hosts it alongside the sort select"
    - "Layouts.theme_toggle/1 + Layouts.brand_logo/1 -> every page in the app via Layouts.app/1"
    - "ui-design-system SKILL.md -> the rules future UI work is checked against; fixes that change a convention must land there too"
---

<objective>
Close all 7 UI audit findings logged against `CatalogLive.Index` on 2026-08-18, and record each one
as resolved under `.planning/todos/completed/`.

Purpose: these findings are the developer-chosen manual follow-up to Phase 01's still-open
human-verification item in `01-VERIFICATION.md` ("the drawer trigger and pills are comfortably
tappable"). One is a live blocker — part of the Filtros button is dead for its stated purpose.

Output: a catalog screen with no overlapping controls, a screen-reader-navigable and
44px-compliant app header, a real secondary button tier, a measured type inventory, and 7 closed
todos.

## Reconciliation: the audit predates plans 01-07..01-12

The audit was taken on 2026-08-18 against the then-current code. Plans 01-10/01-11/01-12 have since
landed and moved code the audit measured. Verified against `main` at plan time:

| # | Finding | Severity | Status against current code |
|---|---------|----------|------------------------------|
| 1 | Sort select overlaps Filtros | blocker | **LIVE.** `filter_drawer.ex:33` still carries the same wrapper classes; `index.ex:376-408` still places it as a flex sibling of the sort select. Root cause reconfirmed below. |
| 2 | Ver detalles CTA 28px x183 | major | **ALREADY RESOLVED** by 01-10. The CTA moved out of `GameCard` into `GamePreview.preview_body/1` (`game_preview.ex:112-117`), already carries `min-h-11 btn-block`, and now renders inside an inert `<template>` — one live instance at a time in the portal/sheet, not 183 painted per page. Task 3 verifies and closes it; it does not re-fix it. |
| 3 | Theme toggle: no names, 32px | major | **LIVE.** `layouts.ex:249-271` — three icon-only buttons, `flex p-2 cursor-pointer w-1/3`, zero accessible names. |
| 4 | 10 font combos vs cap of 3 | minor | **STALE MEASUREMENT.** The card/preview type scale is now owned by the `pk-*` block in `app.css`, not by the classes the audit sampled. Requires a fresh measurement before any change — Task 4. |
| 5 | btn-primary shared 184x | minor | **PARTIALLY RESOLVED.** Ver detalles is now `btn-outline btn-primary` and lives in a template. Live filled `.btn-primary` today: the Filtros trigger and the empty-state "Limpiar filtros". The *component-vocabulary gap* the todo actually describes is still real — `CoreComponents.button/1`'s variants map still offers only `btn-primary` or `btn-primary btn-soft`. Task 3 closes that gap. |
| 6 | Tagline banned patterns | cosmetic | **LIVE.** `layouts.ex:35`. |
| 7 | Brand logo link 42px | cosmetic | **LIVE.** `layouts.ex:31` — no hit-target floor. |

Tasks 1-4 each move the todo files they resolve into `.planning/todos/completed/` in the same
commit. `.planning/todos/completed/` is currently empty, so this plan establishes the convention:
move the file unchanged and append a `## Resolution` section (date, what actually changed, and
whether it was fixed here or verified as already-fixed).
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

Project skills — read before touching any template or styling:
- `.claude/skills/ui-design-system/SKILL.md` (banned patterns, theme tokens, type hierarchy, hit-target rule, the `pk-*` catalogue surface layer and its "one CSS class, shared verbatim" rule)
- `.claude/skills/ux-responsive/SKILL.md` (breakpoints in force, the 44px minimum)

Source under change:
@lib/pukllay_club_web/components/filter_drawer.ex
@lib/pukllay_club_web/components/layouts.ex
@lib/pukllay_club_web/components/core_components.ex

Todo files being resolved (all under `.planning/todos/pending/`):
- `2026-08-18-fix-sort-dropdown-overlapping-filtros-button.md`
- `2026-08-18-fix-theme-toggle-accessible-names-and-hit-target.md`
- `2026-08-18-fix-brand-logo-link-touch-target.md`
- `2026-08-18-fix-brand-tagline-banned-tailwind-patterns.md`
- `2026-08-18-reserve-btn-primary-for-a-single-page-action.md`
- `2026-08-18-fix-ver-detalles-card-cta-touch-target.md`
- `2026-08-18-reduce-font-combos-on-catalog-screen.md`
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Stop the filter drawer's grid wrapper from overflowing onto the sort select</name>
  <files>lib/pukllay_club_web/components/filter_drawer.ex, test/pukllay_club_web/components/filter_drawer_test.exs</files>

  <read_first>
    `lib/pukllay_club_web/components/filter_drawer.ex` lines 31-43 (the wrapper, the toggle
    checkbox, the `drawer-content` label, and the `drawer-side` panel) and
    `lib/pukllay_club_web/live/catalog_live/index.ex` lines 374-410 (the toolbar row that hosts the
    drawer next to the sort `select`).

    Compiled daisyUI rules confirming the mechanism, from `priv/static/assets/css/app.css`:
    - `.drawer` (line 1132): `position: relative; display: grid; width: 100%; grid-auto-columns: max-content auto;`
    - `.drawer-content` (line 1352): `grid-column-start: 2; grid-row-start: 1; min-width: 0;`
    - `.drawer-end` (line 1359): `grid-auto-columns: auto max-content;` and, under a sibling
      `.drawer-toggle`, moves `.drawer-content` to `grid-column-start: 1` and `.drawer-side` to
      column 2.
  </read_first>

  <behavior>
    - Rendering `filter_drawer/1` produces a wrapper that constrains its own width (daisyUI's
      `width: 100%` must still be overridden — do not simply delete the current override, or the
      drawer will consume the whole toolbar row).
    - The wrapper's width is content-driven, so the grid track holding the trigger label is at
      least as wide as the label's own content.
    - The wrapper does not shrink under flex pressure from its sibling sort select.
    - The trigger label keeps its existing hit-target floor and its icon+text pairing.
    - The drawer still opens and closes purely via the `drawer-toggle` checkbox — no JS hook, no
      breakpoint logic (per `ux-responsive`'s drawer row).
  </behavior>

  <action>
    Diagnosis (confirmed, not a guess): under `drawer-end`, the trigger label sits in the grid's
    first track, which daisyUI sizes `auto`. The wrapper's current width override collapses the
    grid to a shrink-to-fit box inside a `flex items-center justify-end gap-4` row, and the `auto`
    track ends up narrower than the label's content (measured 58-70px track vs 102px label). The
    label overflows its cell and paints over the adjacent select. `.drawer-content`'s
    `min-width: 0` is what permits the collapse rather than forcing the track open.

    First-choice fix: on the wrapper element, swap the current width override for a content-fitting
    width utility (`w-fit`) and add `shrink-0`. The first stops the grid from collapsing below its
    content, the second stops the flex parent from squeezing it back. Keep `drawer` and
    `drawer-end` untouched — they are load-bearing for the panel's side and open/close behaviour.

    Fallback if `w-fit` alone still under-sizes the track (verify in the browser, do not assume):
    add `min-w-fit` alongside it, or lift the trigger label out of the grid path entirely by giving
    `.drawer-content` its own `w-fit` — in that order of preference, stopping at the first that
    passes the browser check. Do not restructure the toolbar row in `index.ex` unless both wrapper-
    level fixes fail; if you reach that point, stop and report rather than redesigning the toolbar.

    Write `test/pukllay_club_web/components/filter_drawer_test.exs` (new file) following the
    `render_component/2` + `assert html =~` shape already used in
    `test/pukllay_club_web/components/layouts_test.exs`. Assert the rendered wrapper carries the
    content-fitting and non-shrinking utilities, and `refute` the collapsing width utility the fix
    removes. Add a comment on the refute pointing at this todo, so a future reader knows the
    assertion is guarding a real regression and not style preference. Also assert the trigger label
    still renders its hit-target floor class and the `Filtros` text, so the fix cannot silently
    regress the parts that were already correct.

    Then move `.planning/todos/pending/2026-08-18-fix-sort-dropdown-overlapping-filtros-button.md`
    to `.planning/todos/completed/`, appending a `## Resolution` section recording the date, the
    exact class change, and the browser check that proved it.
  </action>

  <verify>
    <automated>mix test test/pukllay_club_web/components/filter_drawer_test.exs</automated>
    <human-check>Deferred to Task 5's browser measurement — the geometric proof cannot be asserted from rendered HTML alone.</human-check>
  </verify>

  <done>
    `mix test test/pukllay_club_web/components/filter_drawer_test.exs` passes, the wrapper still
    overrides daisyUI's full-width default, and the sort-dropdown todo file is in
    `.planning/todos/completed/` with a Resolution section.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Fix the shared app header — theme-toggle names and hit target, logo hit target, tagline tokens</name>
  <files>lib/pukllay_club_web/components/layouts.ex, test/pukllay_club_web/components/layouts_test.exs</files>

  <read_first>
    `lib/pukllay_club_web/components/layouts.ex` lines 27-41 (`brand_logo/1`) and lines 244-274
    (`theme_toggle/1`). Note the toggle's absolutely-positioned sliding indicator at line 247 — it
    is sized `w-1/3 h-full` off the container, so it tracks whatever height the buttons establish;
    the three buttons each own `w-1/3`, which is what keeps the indicator aligned.

    `ui-design-system` SKILL.md: the "Banned — never write these" list, the `text-neutral text-sm`
    muted-text convention, and the `min-h-11` hit-target rule.

    `CoreComponents.flash/1` in `core_components.ex` for the in-repo accessible-name precedent
    (`aria-label={gettext("close")}`).
  </read_first>

  <behavior>
    - Each of the three theme buttons exposes a distinct accessible name in plain Spanish, naming
      the theme it selects (system / light / dark).
    - Each theme button satisfies the app's 44px floor on both axes, and the sliding indicator
      still lines up with the three thirds of the pill container.
    - The pill container keeps its fully-rounded segmented-control shape.
    - The brand logo link satisfies the 44px floor on its height axis.
    - The brand tagline renders through theme tokens with no arbitrary Tailwind value and no
      opacity-suffixed color class.
    - `brand_logo/1` still renders the wordmark, the tagline text, and degrades without a broken
      image reference when the isologo asset is absent (the existing tests at
      `layouts_test.exs:9-23` must keep passing untouched).
  </behavior>

  <action>
    Theme toggle (`layouts.ex:244-274`): give each of the three buttons an `aria-label` naming the
    theme it activates, in plain Spanish matching the app's copy register — the drawer overlay's
    `Cerrar filtros` label in `filter_drawer.ex:41` and the preview sheet's `Cerrar` in
    `game_preview.ex:327` are the in-repo tone precedent. Do not add a `title` as well; one
    accessible name per control. Raise each button to the app's hit-target floor on both axes using
    the same utility family already used elsewhere in the app rather than inventing a pixel value —
    `ui-design-system` explicitly forbids introducing a second hit-target number. Keep `w-1/3` on
    each button so the sliding indicator stays aligned; add the height/width floors alongside it,
    and centre the icon within the enlarged button so it does not sit top-left once the box grows.
    Re-check the container's rounded-full shape after the size change.

    Brand logo link (`layouts.ex:31`): add the hit-target floor to the `<a>` without disturbing the
    lockup's vertical alignment inside the navbar — the anchor is already `flex items-center`, so a
    height floor alone should suffice; verify the wordmark and tagline stay optically centred.

    Tagline (`layouts.ex:35`): replace the arbitrary size value and the opacity-suffixed color with
    the app's documented muted-text convention from `ui-design-system` ("Muted/secondary text:
    `text-neutral text-sm`"). `text-sm` may read large for a tagline sitting under a `text-2xl`
    wordmark — if it does, drop to the next token-based step down rather than reaching back for an
    arbitrary value, and record which you chose and why in the todo's Resolution section. Keep
    `font-sans`, `uppercase`, and `tracking-widest` as-is; only the size and color classes are in
    scope.

    Extend `test/pukllay_club_web/components/layouts_test.exs` — add cases to the existing
    `brand_logo/1` and `app/1 header` describe blocks rather than creating a new file. Assert each
    theme button's accessible name is present and that the three names are distinct; assert the
    hit-target class appears on the theme buttons and on the brand anchor; and `refute` the two
    banned classes the tagline fix removes, with a comment tying each refute to its todo.
  </action>

  <verify>
    <automated>mix test test/pukllay_club_web/components/layouts_test.exs</automated>
  </verify>

  <done>
    All pre-existing tests in `layouts_test.exs` still pass alongside the new ones; the three theme
    buttons announce distinctly; and the theme-toggle, brand-logo-link, and brand-tagline todo files
    are in `.planning/todos/completed/` with Resolution sections.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Add a secondary button tier, and close the two findings the 01-10 preview work already resolved</name>
  <files>lib/pukllay_club_web/components/core_components.ex, test/pukllay_club_web/components/core_components_test.exs, .claude/skills/ui-design-system/SKILL.md</files>

  <read_first>
    `lib/pukllay_club_web/components/core_components.ex` lines 90-125 — `button/1`, its
    `attr :variant, :string, values: ~w(primary)` declaration, and the `variants` map at line 105
    which currently offers only a filled primary and a soft primary.

    `lib/pukllay_club_web/components/game_preview.ex` lines 73-79 and 112-117 — the moduledoc
    already states the Ver detalles CTA "is never the filled primary button", and the markup already
    renders it outlined at the app's hit-target floor and full width. This is the evidence that
    finding #2 is resolved and finding #5's practical symptom is gone.

    `ui-design-system` SKILL.md, the "Component inventory" table row for `CoreComponents.button/1`.
  </read_first>

  <behavior>
    - `button/1` accepts a third variant naming a non-filled, non-soft tier for repeated or
      secondary actions, and its `values:` list accepts it without an ArgumentError.
    - Rendering with no `variant` keeps today's exact output — this must not become a breaking
      change for existing call sites.
    - Rendering with the existing `"primary"` variant keeps today's exact output.
    - Rendering with the new variant produces a daisyUI outline-tier class combination, not a
      filled fill.
  </behavior>

  <action>
    Add one new entry to `button/1`'s `variants` map and to its `attr :variant` `values:` list,
    naming the middle tier for "important, but not the page's one action" — the todo's own framing.
    Use daisyUI's outline modifier composed with the primary color, matching the treatment
    `GamePreview`'s CTA already uses live, so the new variant and the existing hand-written CTA are
    the same visual tier rather than two competing secondaries. Do not change the `nil` default or
    the `"primary"` entry; both have live call sites.

    Do NOT retrofit existing call sites in this task. The two filled `btn-primary` instances live
    today (`filter_drawer.ex:36`, `index.ex:448`) are each genuinely the single action of their
    surface — the drawer trigger for the toolbar, the recovery action for the empty state — so both
    are correct as filled primaries under the todo's own rule. Record that reasoning in the
    Resolution section rather than changing them.

    Add `test/pukllay_club_web/components/core_components_test.exs` (new file) covering all three
    variant paths — no variant, `"primary"`, and the new one — asserting the class string each
    produces, plus a case proving the new variant is accepted by the `values:` list. Follow the
    `render_component/2` shape used in `layouts_test.exs`.

    Update the `CoreComponents | button/1` row in `ui-design-system` SKILL.md's Component inventory
    to name the available variants, so the next UI task discovers the secondary tier from the skill
    rather than rediscovering the gap.

    Then close two todos. Move
    `.planning/todos/pending/2026-08-18-reserve-btn-primary-for-a-single-page-action.md` with a
    Resolution recording the new variant plus the reasoning above. Move
    `.planning/todos/pending/2026-08-18-fix-ver-detalles-card-cta-touch-target.md` with a Resolution
    stating it was verified as already resolved by 01-10's preview-surface work — cite
    `game_preview.ex:112-117` and the fact that the CTA now renders inside an inert `<template>`,
    so the 183-instance measurement no longer describes the page. Task 5's browser check confirms
    the live geometry before this is considered closed.
  </action>

  <verify>
    <automated>mix test test/pukllay_club_web/components/core_components_test.exs</automated>
  </verify>

  <done>
    `button/1` exposes three working variants with the default and `"primary"` paths byte-identical
    to before; the SKILL.md inventory row names them; and both todo files are in
    `.planning/todos/completed/` with Resolution sections.
  </done>
</task>

<task type="auto">
  <name>Task 4: Re-measure the catalog type inventory and resolve it against the 3-tier cap</name>
  <files>assets/css/app.css, .claude/skills/ui-design-system/SKILL.md</files>

  <precondition>The dev server is runnable (`mix phx.server`) and the catalog page renders with seeded games — the measurement is of live computed styles, not of source classes.</precondition>

  <read_first>
    `assets/css/app.css`, the block between the `PK CATALOG SURFACES START` and
    `PK CATALOG SURFACES END` markers — specifically the `font-size` declarations at lines 291,
    320, 356, 375, 385, 526, 575, and the narrow-viewport overrides at 634.

    `ui-design-system` SKILL.md, "Type hierarchy" (the 3-distinct-levels cap and the "weight and
    color, not a new size, are the emphasis lever" rule) and the "Catalogue surface layer" rules —
    in particular that this block is the only sanctioned custom-CSS layer, that its narrow-viewport
    `@media` block must stay last in the file, and the "one CSS class, shared verbatim by both
    surfaces" rule.
  </read_first>

  <action>
    The todo's "10 combos" figure was measured on 2026-08-18, before 01-10/01-11/01-12 moved the
    card and preview type scale into the `pk-*` CSS layer, and before Task 2 of this plan removed
    the tagline's arbitrary size. Treat it as stale: re-measure first, then decide.

    Measure: run the app, load the catalog browse screen, and collect the distinct
    `font-family` + `font-size` + `font-weight` triples across every rendered element at 375px,
    768px, and 1440px. Record the resulting list with, for each combo, which element(s) produce it
    and whether the size comes from this app's CSS, a daisyUI component default, or a Tailwind
    utility in a template. This inventory is the deliverable — write it into the todo's Resolution
    section, not into a separate report file.

    Then classify each combo against the skill's heading/body/muted tiers:
    - Combos this app owns in the `pk-*` block that duplicate a neighbouring tier with no
      functional reason: normalize them onto the shared value, editing the existing declarations in
      place. Respect the "one CSS class, shared verbatim" rule — if two surfaces must look
      identical, they resolve through one declaration, not two matching ones.
    - Combos that are genuinely distinct content units (the Bebas Neue display sizes for the page
      heading vs a preview title are the likely defensible pair) — keep them.
    - Combos inherited from daisyUI component defaults (`badge`, `badge-sm`, `select`, `input`):
      do NOT override daisyUI's component internals to chase the count. That would trade a
      cosmetic-severity inconsistency for a fight with the design system's own "prefer daisyUI"
      core rule. Document them as accepted instead.

    Record the outcome in `ui-design-system` SKILL.md's "Type hierarchy" section: state the measured
    post-fix combo count for the catalogue screen, and list the specific combos accepted as
    deliberate exceptions with their one-line reason. This makes the cap enforceable next time
    instead of re-litigable.

    If the measurement shows the count already at or near the cap once daisyUI defaults are
    excluded, say so plainly and change no CSS — a measurement that disproves the finding is a
    valid resolution. Do not manufacture edits to justify the task.

    Then move `.planning/todos/pending/2026-08-18-reduce-font-combos-on-catalog-screen.md` to
    `.planning/todos/completed/` with the inventory and the disposition of each combo.
  </action>

  <verify>
    <automated>mix test</automated>
    <human-check>The measured combo inventory (before and after) is recorded in the completed todo, and every combo above the cap is listed as an accepted exception in SKILL.md's Type hierarchy section.</human-check>
  </verify>

  <done>
    The full test suite passes, the catalogue screen's type inventory is measured and documented,
    any duplicate app-owned sizes are collapsed, and the font-combos todo is in
    `.planning/todos/completed/` with the inventory in its Resolution section.
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking-human">
  <name>Task 5: Verify all fixes live at 375px / 768px / 1440px</name>

  <what-built>
    All 7 audit findings are now closed in code: the filter drawer's grid wrapper no longer
    overflows onto the sort select (Task 1); the three theme-toggle buttons have distinct Spanish
    accessible names and meet the 44px floor, the brand logo link meets the 44px floor, and the
    tagline uses theme tokens only (Task 2); `CoreComponents.button/1` gained a non-filled
    secondary tier and the two findings already resolved by 01-10's preview work are verified and
    closed (Task 3); and the catalogue type inventory has been re-measured with its exceptions
    documented (Task 4).

    What could not be proven from tests: every remaining item here is geometric or announced —
    pixel measurements, `elementFromPoint` hit resolution, and the accessibility tree. Rendered-HTML
    assertions can prove the classes are present but not that the resulting boxes are the right
    size or that the right element receives a tap.
  </what-built>

  <how-to-verify>
    Run `mix phx.server` and open the catalog browse screen. Check each item at 375px, 768px, and
    1440px (devtools device toolbar).

    1. **Filtros / sort overlap (blocker).** The Filtros button and the sort select no longer touch
       or overlap. In the devtools console, use `document.elementFromPoint` to probe the last ~20px
       of the Filtros label — including the final letter — and confirm every probe resolves to the
       drawer-toggle label, not to the select. Repeat at each width. Then click that same zone and
       confirm the drawer actually opens.
    2. **Theme toggle.** Each of the three buttons measures at least 44px on both axes. Open
       devtools > Accessibility pane and confirm the three announce as three distinct Spanish
       names, not three anonymous buttons. The sliding indicator still lines up with whichever
       third is active, and the container is still a rounded pill.
    3. **Brand logo link.** The wordmark anchor measures at least 44px tall, and the isologo /
       wordmark / tagline lockup is still optically aligned in the navbar.
    4. **Tagline.** Renders in a theme token color at a token size, still legible under the
       wordmark, in both light and dark theme.
    5. **Ver detalles CTA.** Hover a card on desktop and tap a card on a narrow viewport; in both
       the portal and the mobile sheet the CTA measures at least 44px tall, and the card body does
       not overflow or reflow around it.
    6. **Button hierarchy.** With the filter drawer closed, count the filled violet buttons on
       screen — the toolbar's Filtros should be the only one (the empty-state "Limpiar filtros"
       appears only when a filter combination returns nothing). Ver detalles reads as outlined,
       visibly a lower tier.
    7. **Type.** Spot-check that the heading / body / muted tiers still read as three distinct
       levels and that nothing regressed visually from Task 4's normalization.

    This checkpoint also closes the still-open human-verification item in
    `.planning/phases/01-catalog-v1/01-VERIFICATION.md` ("the drawer trigger and pills are
    comfortably tappable") — record the result there as well as in the summary.
  </how-to-verify>

  <resume-signal>
    Reply "verified" when all 7 checks pass at all three widths. If any item fails, reply with the
    item number, the width it failed at, and the measured value — that becomes the fix scope before
    this plan can close.
  </resume-signal>

  <done>
    All 7 checks pass at all three widths, the result is recorded in `01-VERIFICATION.md` against
    the previously-open tappability item, and `.planning/todos/pending/` contains none of the 7
    audit files.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| (none introduced) | This plan changes presentation-layer classes, static `aria-label` string literals, and one component's variant map. No new input crosses a trust boundary, no new dependency is installed, no data flow changes. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-DAH-01 | Tampering | `assets/css/app.css` `pk-*` block (Task 4) | low | mitigate | Every edit stays inside the delimited `PK CATALOG SURFACES` block and resolves color through theme CSS variables — no literal hex, no inline `style=`, matching the design-system rule. The narrow-viewport `@media` block stays last in the file. |
| T-DAH-02 | Elevation of Privilege | `filter_drawer.ex` wrapper (Task 1) | low | accept | The drawer's open/close is a bare CSS checkbox with no server round-trip and no authorization semantics; a sizing change cannot expose state a user could not already reach. |
| T-DAH-03 | Tampering | package-manager installs | n/a | n/a | No `mix deps.get`, npm, pip, or cargo install occurs in this plan. No Package Legitimacy Audit is required. |
</threat_model>

<verification>
- `mix quality` passes end to end (it runs `format --check-formatted` with the Styler plugin,
  `credo --strict`, `sobelow`, and the full test suite). Review the `git diff` for any Styler
  rewrite before committing, per the project's standing Styler caveat.
- No arbitrary Tailwind value, raw hex/rgb color, or inline `style=` attribute is introduced
  anywhere in this plan's diff.
- `.planning/todos/pending/` contains none of the 7 audit files; `.planning/todos/completed/`
  contains all 7, each with a `## Resolution` section.
- Task 5's human checks all pass at 375px, 768px, and 1440px.
</verification>

<success_criteria>
1. A tap on any pixel of the Filtros label opens the drawer at all three breakpoints, proven by
   `elementFromPoint`.
2. The three theme-toggle buttons announce as three distinct Spanish names and each measures
   at least 44px on both axes.
3. The brand logo link measures at least 44px tall; the tagline uses only theme tokens.
4. `CoreComponents.button/1` exposes a non-filled secondary tier, documented in
   `ui-design-system` SKILL.md, with the default and `"primary"` paths unchanged.
5. The catalogue screen's font-combination inventory is freshly measured and every combo above
   the 3-tier cap is a documented, accepted exception.
6. All 7 todo files are in `.planning/todos/completed/` with Resolution sections.
7. `mix quality` passes.
</success_criteria>

<output>
Create `.planning/quick/260821-dah-fix-7-ui-audit-findings-on-cataloglive-i/260821-dah-SUMMARY.md` when done.
</output>
