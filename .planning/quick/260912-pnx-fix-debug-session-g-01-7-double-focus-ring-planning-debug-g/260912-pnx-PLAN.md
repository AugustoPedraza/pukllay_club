---
phase: quick-260912-pnx
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
files_modified:
  - lib/pukllay_club_web/components/filter_modal.ex
  - test/pukllay_club_web/components/filter_modal_test.exs
  - .planning/debug/G-01-7-double-focus-ring.md
  - .planning/debug/resolved/G-01-7-double-focus-ring.md
files_deleted:
  - .planning/debug/G-01-7-double-focus-ring.md

must_haves:
  truths:
    - "Both filter-modal checklist search inputs (data-fc-input mechanics and themes) render with the exact suppression pair CoreComponents.input/1 already uses: focus:outline-hidden focus-within:outline-hidden"
    - "A focused checklist search input still shows exactly one visible focus indicator (its own bottom border darkening to base-content), not zero and not two"
    - "A regression test in filter_modal_test.exs fails if either suppression token is removed from either checklist search input"
    - "No other raw text/select/textarea control outside core_components.ex lacks the suppression (sweep result recorded in the debug file)"
    - "G-01-7 debug session is status resolved, lives at .planning/debug/resolved/G-01-7-double-focus-ring.md, root_cause text unchanged, fix/verification/files_changed filled, and verification states honestly whether a live browser focus check was performed"
  artifacts:
    - path: "lib/pukllay_club_web/components/filter_modal.ex"
      provides: "checklist/1 raw search input carrying focus:outline-hidden focus-within:outline-hidden focus:border-base-content"
    - path: "test/pukllay_club_web/components/filter_modal_test.exs"
      provides: "LazyHTML class-token test pinning the suppression on input[data-fc-input]"
    - path: ".planning/debug/resolved/G-01-7-double-focus-ring.md"
      provides: "Closed debug session with fix, verification, files_changed"
  key_links:
    - from: "filter_modal.ex checklist/1 input class"
      to: "core_components.ex input/1 catch-all branch default class (line ~307)"
      via: "identical focus:outline-hidden focus-within:outline-hidden token pair"
      pattern: "focus:outline-hidden focus-within:outline-hidden"
---

<objective>
Close the last live reproduction of G-01-7 (daisyUI `.input:focus` double ring). The original
sites (nav search, sort select) were fixed by plan 01-07 via the suppression pair
`focus:outline-hidden focus-within:outline-hidden` baked into every default class in
`CoreComponents.input/1` (core_components.ex lines 260 select, 284 textarea, 307 text). Quick
task 260824-b71 later added a raw `<input class="input input-ghost ...">` in
`FilterModal.checklist/1` (filter_modal.ex ~line 478-484) that bypasses input/1 and therefore
still draws daisyUI's 2px offset outline on focus. Apply the same suppression there, pin it with
a test, then resolve and move the debug session.

Purpose: one consistent, single focus indicator across every text field in the app, and a
test so the next hand-rolled input in this component cannot silently regress it.
Output: patched filter_modal.ex, new test, resolved debug file under .planning/debug/resolved/.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md
@.planning/debug/G-01-7-double-focus-ring.md
@lib/pukllay_club_web/components/filter_modal.ex
@lib/pukllay_club_web/components/core_components.ex
@test/pukllay_club_web/components/filter_modal_test.exs

Planner sweep results (verified 2026-09-12, executor re-runs the sweep in Task 1 verify):

- Suppression source of truth: `CoreComponents.input/1` default class strings at
  core_components.ex:260 (`w-full select focus:outline-hidden focus-within:outline-hidden`),
  :284 (textarea, same pair), :307 (`w-full input focus:outline-hidden focus-within:outline-hidden`).
  No app.css rule suppresses it globally; the only CSS-side suppression is the nav morph's
  `.pk-search-morph .pk-nav-search .input { outline: none }` (assets/css/app.css ~2034), which is
  scoped to the nav and not a pattern to copy here.
- Raw form controls outside core_components.ex (`grep -rn '<input\|<select\|<textarea' lib`):
  ONLY filter_modal.ex:478 (checklist text search input — the defect, in scope) and
  filter_modal.ex:491 (`<input type="checkbox" class="checkbox checkbox-sm">` — out of scope:
  daisyUI `.checkbox` uses a single focus-visible outline, not the `.input`/`.select`
  border-bump-plus-offset-outline mechanism, and CoreComponents.input/1's own checkbox branch
  also ships `checkbox checkbox-sm` unsuppressed, so it already matches the project convention).
  No `<select>` or `<textarea>` exists outside core_components.ex. No JS in assets/js creates
  input/select/textarea elements.
- Every `<.input>` call site passes NO `class` attr (filter_modal.ex:233, catalog_live/index.ex:922,
  catalog_live/show.ex:325, catalog_live/show.ex:1050), so none of them overrides away the
  default suppression. Only the one raw input is defective.
- CSS layering fact that drives the discretion choice in Task 1: in the compiled CSS, daisyUI's
  `.input` / `.input-ghost` rules live in a nested `@layer daisyui.l1.l2` inside
  `@layer utilities`, while plain utilities like `.border-base-300` sit directly in
  `@layer utilities` and therefore outrank them. On this element `border-base-300` pins the
  bottom border color, so daisyUI's focus `--input-color` border bump (the one indicator that
  survives suppression on every CoreComponents input) never happens here. Suppressing the outline
  alone would leave this field with no visible focus indicator beyond the caret.
- Existing test coverage: filter_modal_test.exs:358-370 asserts `data-fc-input` presence only;
  no test anywhere asserts `outline-hidden`. The file already uses the LazyHTML
  `query` + `attribute("class")` + `String.split` token pattern (lines ~169-197) — reuse it.
- Sibling batch items touch bgg_client.ex, seed/, .sobelow-conf and a todo file — no overlap.
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Suppress the double focus ring on the filter-modal checklist search input, pinned by a test</name>
  <files>test/pukllay_club_web/components/filter_modal_test.exs, lib/pukllay_club_web/components/filter_modal.ex</files>
  <behavior>
    - Test: rendering FilterModal.filter_modal/1 with @empty_facet_options, LazyHTML query `input[data-fc-input]` returns exactly 2 class attributes (mechanics + themes).
    - Test: for each, the whitespace-split class tokens include "input", "input-ghost", "focus:outline-hidden", "focus-within:outline-hidden" and "focus:border-base-content".
    - RED: before the markup change the test fails on the missing "focus:outline-hidden" token.
  </behavior>
  <action>
    RED first. In test/pukllay_club_web/components/filter_modal_test.exs, inside the existing
    `describe "filter_modal/1 rendering"` block and directly after the test named "both
    checklists carry the max-h-40 list cap and a data-fc-input search box", add a test named
    "both checklist search inputs carry CoreComponents.input/1's focus-ring suppression (G-01-7)".
    Precede it with a short comment explaining: daisyUI's .input draws a border plus a separate
    2px-offset outline on focus (the G-01-7 double ring); CoreComponents.input/1 suppresses the
    outline by default, but checklist/1 renders a raw input that bypasses input/1, so the pair is
    pinned here explicitly, and focus:border-base-content keeps exactly one visible indicator.
    Render with `id: "filter-modal"` and `facet_options: @empty_facet_options`, build
    `LazyHTML.from_document(html)`, query `input[data-fc-input]`, take `LazyHTML.attribute("class")`,
    assert the list length is 2, and for each class string assert the five tokens from
    <behavior> are members of `String.split(class_list)` (token membership, not substring
    matching, mirroring the pk-pill token test already in this file). Run the file and confirm it
    fails.

    GREEN. In lib/pukllay_club_web/components/filter_modal.ex `checklist/1` (~line 482), change
    the raw search input's class from
    `input input-ghost w-full rounded-none border-0 border-b border-base-300` to
    `input input-ghost w-full rounded-none border-0 border-b border-base-300 focus:outline-hidden focus-within:outline-hidden focus:border-base-content`.
    The `focus:outline-hidden focus-within:outline-hidden` pair is copied verbatim from
    CoreComponents.input/1's default class strings (the suppression the project already uses —
    per the item's "apply the same suppression" instruction). `focus:border-base-content` is a
    planner-discretion addition, documented here: CoreComponents inputs keep one indicator after
    suppression because daisyUI darkens their border to `--color-base-content` on focus, but on
    this element the `border-base-300` utility outranks daisyUI's layered border rule, so that
    darkening never happens; `focus:border-base-content` restores exactly that one indicator
    (bottom border only, since border-0 border-b leaves only the bottom edge with width). It is a
    theme-token color class, allowed by ui-design-system (no arbitrary values, no raw colors, no
    inline style). Do not touch the checkbox input at ~line 491 (see context sweep: out of scope,
    matches CoreComponents' own unsuppressed checkbox branch), core_components.ex, or app.css.

    Extend the existing comment above `defp checklist` (the lines explaining why a raw input is
    used instead of CoreComponents.input/1) with one or two sentences: because it bypasses
    input/1 it must carry input/1's focus:outline-hidden focus-within:outline-hidden pair by hand
    (G-01-7, .planning/debug/resolved/G-01-7-double-focus-ring.md), plus focus:border-base-content
    because border-base-300 would otherwise pin the border and leave no focus indicator.

    Re-run the test file (GREEN), then `mix format` on both files so Styler/HTMLFormatter
    normalizes the attribute layout, then run the gates. Also run `mix assets.build` and confirm
    Tailwind emitted the new `focus:border-base-content` utility into the compiled CSS
    (priv/static/assets is untracked, so this does not dirty git). Re-run the raw-control sweep
    and confirm it still lists only filter_modal.ex's two input lines.

    Optional, nice-to-have: if a dev server and browser are available, focus the mechanics
    checklist search box in the filter modal at a mobile width and confirm a single bottom-line
    indicator with no offset ring in both themes. Record in the SUMMARY whether this was actually
    done; never claim it if it was not.

    Commit test + markup together as `fix(quick-260912-pnx): suppress daisyUI double focus ring on filter-modal checklist search (G-01-7)`
    and note the short sha for Task 2.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && mix test test/pukllay_club_web/components/filter_modal_test.exs && mix format --check-formatted && mix credo --strict && grep -n 'class="input input-ghost[^"]*focus:outline-hidden focus-within:outline-hidden' lib/pukllay_club_web/components/filter_modal.ex && mix assets.build && grep -c 'focus\\:border-base-content' priv/static/assets/css/app.css && grep -rn '<input\|<select\|<textarea' lib | grep -v core_components.ex</automated>
  </verify>
  <done>
    filter_modal_test.exs passes including the new token test (which was observed failing before
    the markup change); the checklist search input class carries
    focus:outline-hidden focus-within:outline-hidden focus:border-base-content; format and
    credo --strict are clean; compiled CSS contains the focus:border-base-content rule; the sweep
    shows no raw text/select/textarea control outside core_components.ex other than this one
    (now suppressed) input; one fix commit exists.
  </done>
</task>

<task type="auto">
  <name>Task 2: Resolve the G-01-7 debug session and move it to .planning/debug/resolved/</name>
  <files>.planning/debug/G-01-7-double-focus-ring.md, .planning/debug/resolved/G-01-7-double-focus-ring.md</files>
  <action>
    Run `git mv .planning/debug/G-01-7-double-focus-ring.md .planning/debug/resolved/G-01-7-double-focus-ring.md`
    first, then Edit the file at its new path. Match the frontmatter/Resolution shape of the
    already-resolved sibling .planning/debug/resolved/G-01-2-badge-title-overlap.md.

    Frontmatter: set `status: resolved` and `updated: 2026-09-12`. Leave `trigger`, `created`, and
    the whole `audit_acknowledged` block unchanged.

    Current Focus: set `next_action: n/a — resolved by quick 260912-pnx` (leave hypothesis as is).

    Evidence: append one new timestamped entry (timestamp 2026-09-12) recording that quick
    260912-mxq confirmed the original sites were fixed by plan 01-07 (the focus:outline-hidden
    focus-within:outline-hidden pair in CoreComponents.input/1 at core_components.ex:260/284/307)
    but found a live recurrence at filter_modal.ex checklist/1's raw input added by quick
    260824-b71, plus the layering finding that border-base-300 outranks daisyUI's layered border
    rule on that element.

    Resolution: leave `root_cause` byte-for-byte unchanged. Replace the placeholder `fix:` with ONE
    double-quoted line beginning `quick 260912-pnx (commit <sha from Task 1>):` that states the
    original sites were fixed by plan 01-07 via CoreComponents.input/1's default suppression pair,
    and that the remaining raw checklist search input in FilterModal.checklist/1 now carries the
    same pair plus focus:border-base-content so exactly one focus indicator remains. Replace
    `verification:` with a `|` block of bullets citing: the grep hit (file:line) for the patched
    class in filter_modal.ex; the new test's name and the filter_modal_test.exs result (test
    count, 0 failures), noting it was observed RED before the fix; `mix format --check-formatted`
    and `mix credo --strict` clean; the compiled-CSS grep for focus:border-base-content; the
    raw-control sweep result (only filter_modal.ex's search input and its checkbox remain outside
    core_components.ex, checkbox deliberately unchanged and why); and a final bullet stating
    plainly whether a live browser focus check was performed — if Task 1 did not do it, write
    that no visual browser check was performed and verification is class/test/compiled-CSS
    evidence only. Replace `files_changed: []` with a list of
    lib/pukllay_club_web/components/filter_modal.ex and
    test/pukllay_club_web/components/filter_modal_test.exs.

    Do not touch any other file under .planning/debug/ (whatsapp-og-image-preview.md,
    knowledge-base.md, assets/, other resolved files). Commit as
    `docs(quick-260912-pnx): resolve G-01-7 double focus ring debug session`, staging both the
    deletion side and the new resolved path.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && test ! -e .planning/debug/G-01-7-double-focus-ring.md && grep -n '^status: resolved' .planning/debug/resolved/G-01-7-double-focus-ring.md && grep -n '^fix: "quick 260912-pnx' .planning/debug/resolved/G-01-7-double-focus-ring.md && grep -n 'filter_modal.ex' .planning/debug/resolved/G-01-7-double-focus-ring.md && grep -n 'browser' .planning/debug/resolved/G-01-7-double-focus-ring.md && git status --porcelain .planning/debug/</automated>
  </verify>
  <done>
    The old path no longer exists; .planning/debug/resolved/G-01-7-double-focus-ring.md has
    status resolved, updated 2026-09-12, unchanged root_cause and audit_acknowledged, a one-line
    fix citing quick 260912-pnx and its commit sha, a verification block with grep/test/CSS/sweep
    evidence and an honest browser-check statement, and files_changed listing the two touched
    files; the move is committed and `git status` shows no unstaged changes under .planning/debug/.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| none new | Change is a static CSS class list on an existing client-side filter input plus a test and a planning doc; no new input handling, events, endpoints, or data flow |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-260912-pnx-01 | Denial of Service (accessibility) | filter_modal.ex checklist/1 search input | low | mitigate | Removing the outline could leave keyboard users with no focus indicator; focus:border-base-content keeps one visible indicator, pinned by the Task 1 token test |
| T-260912-pnx-02 | Tampering | test/markup class tokens | low | accept | Purely presentational tokens; regression is caught by the new test, no security impact |
</threat_model>

<verification>
- mix test test/pukllay_club_web/components/filter_modal_test.exs passes (new G-01-7 token test included)
- mix format --check-formatted and mix credo --strict are clean
- grep -rn '<input\|<select\|<textarea' lib | grep -v core_components.ex lists only filter_modal.ex's checklist search input (suppressed) and its checkbox (intentionally unchanged)
- .planning/debug/resolved/G-01-7-double-focus-ring.md exists with status resolved; .planning/debug/G-01-7-double-focus-ring.md does not
- No changes to bgg_client.ex, lib/pukllay_club/seed/, .sobelow-conf, core_components.ex, app.css, or other debug files
</verification>

<success_criteria>
- Every text-type control in the app now carries CoreComponents.input/1's outline suppression, with exactly one focus indicator each
- The recurrence cannot silently return in FilterModal: a class-token test fails if the pair is dropped
- G-01-7 is closed with evidence-backed fix/verification that does not claim an unperformed visual check
</success_criteria>

<output>
Create `.planning/quick/260912-pnx-fix-debug-session-g-01-7-double-focus-ring-planning-debug-g/260912-pnx-SUMMARY.md` when done
</output>
