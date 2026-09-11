---
phase: quick-260818-gdb
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/pukllay_club_web/components/layouts.ex
  - test/pukllay_club_web/components/layouts_test.exs
  - test/pukllay_club_web/live/catalog_live_test.exs
  - test/pukllay_club_web/live/catalog_show_test.exs
  - .claude/skills/ui-design-system/SKILL.md
autonomous: true
requirements: [QUICK-260818-GDB]

estimate:
  tokens: 30000
  raw_tokens: 30000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "Visiting `/` renders the catalog at the LiveView's own `max-w-7xl` width — no ancestor element caps the page to 672px"
    - "Visiting `/juegos/:id` renders the detail page at its own `max-w-4xl` width"
    - "`Layouts.app`'s content wrapper imposes no page-level width cap of its own"
    - "`CatalogLive.Show` still receives horizontal and vertical page padding from the layout's `<main>` element (it declares none itself)"
    - "The design-system skill's page-container rule describes the fixed behaviour, not a known defect"
  artifacts:
    - lib/pukllay_club_web/components/layouts.ex
    - test/pukllay_club_web/components/layouts_test.exs
    - test/pukllay_club_web/live/catalog_live_test.exs
    - test/pukllay_club_web/live/catalog_show_test.exs
    - .claude/skills/ui-design-system/SKILL.md
  key_links:
    - "`Layouts.app`'s inner wrapper div ↔ each LiveView's own `mx-auto max-w-*` container — the layout must not compete with the page for width authority"
    - "`Layouts.app`'s `<main>` padding ↔ `CatalogLive.Show`, which declares no padding of its own and would lose its gutters if `<main>` padding were also stripped"
    - "`.claude/skills/ui-design-system/SKILL.md` page-container rule ↔ the actual code in `layouts.ex` — the rule must not keep describing a defect that no longer exists"
---

<objective>
`Layouts.app/1` wraps every page's `inner_block` in `mx-auto max-w-2xl`. Because that wrapper sits
*outside* each LiveView's own container (`max-w-7xl` in `CatalogLive.Index`, `max-w-4xl` in
`CatalogLive.Show`), the narrower outer constraint wins and silently caps every page at 672px —
the inner container is inert.

Remove the width cap from the layout wrapper so page width becomes each LiveView's own
responsibility, per the `page container` rule in `.claude/skills/ui-design-system/SKILL.md`.

Purpose: the catalog grid (`grid-cols-2 sm:grid-cols-3 lg:grid-cols-4`) and the detail page are
both currently rendered inside a column narrower than they were designed for; every future page
inherits the same trap.

Output: a width-cap-free layout wrapper, regression tests at both the component and page level,
and an updated design-system rule that no longer documents this as an open bug.

**Explicitly out of scope:** the `<main>` element's own padding (`px-4 py-20 sm:px-6 lg:px-8`)
stays exactly as-is. `CatalogLive.Show` declares no padding of its own and depends on it. The
resulting double horizontal padding on `CatalogLive.Index` (which does declare its own) is a
pre-existing cosmetic condition, unchanged by this fix, and is not addressed here.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/skills/ui-design-system/SKILL.md
@lib/pukllay_club_web/components/layouts.ex
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: End-to-end — a catalog page renders at its own container width</name>
  <files>test/pukllay_club_web/live/catalog_live_test.exs, test/pukllay_club_web/live/catalog_show_test.exs, lib/pukllay_club_web/components/layouts.ex</files>
  <precondition>PostgreSQL is reachable for the `test` env — `MIX_ENV=test mix ecto.create` succeeds, since both test files use `PukllayClubWeb.ConnCase` with the Ecto sandbox and `PukllayClub.CatalogFixtures`.</precondition>
  <reversibility rating="reversible">Deleting one Tailwind utility token from one wrapper div; restoring it is a one-token edit.</reversibility>
  <read_first>
    - `lib/pukllay_club_web/components/layouts.ex` lines 80-84 — the `<main>` element and the inner
      wrapper div that currently reads `class="mx-auto max-w-2xl space-y-4"`.
    - `lib/pukllay_club_web/live/catalog_live/index.ex` line 226 — the page container
      `class="mx-auto max-w-7xl space-y-6 px-4 py-6 sm:px-6 lg:px-8"`.
    - `lib/pukllay_club_web/live/catalog_live/show.ex` line 51 — the page container
      `class="mx-auto max-w-4xl space-y-6"` (note: no padding of its own).
    - `test/pukllay_club_web/live/catalog_live_test.exs` lines 1-20 and
      `test/pukllay_club_web/live/catalog_show_test.exs` lines 1-20 — the existing
      `game_fixture()` + `live(conn, ~p"...")` mount pattern to mirror.
  </read_first>
  <behavior>
    RED first — write both assertions before touching `layouts.ex`; they must fail against the
    current layout.

    - Test 1 (`catalog_live_test.exs`, inside the existing `describe "GET /"` block, named for the
      672px cap regression): after `game_fixture()`, `{:ok, _view, html} = live(conn, ~p"/")` —
      `assert html =~ "max-w-7xl"` and `refute html =~ "max-w-2xl"`.
    - Test 2 (`catalog_show_test.exs`, inside the existing `describe "GET /juegos/:id"` block):
      after `game = game_fixture()`, `{:ok, _view, html} = live(conn, ~p"/juegos/#{game.id}")` —
      `assert html =~ "max-w-4xl"` and `refute html =~ "max-w-2xl"`.

    GREEN: both pass once the layout wrapper stops declaring a width cap.
  </behavior>
  <action>
    Write the two RED tests described in `<behavior>` first and confirm both fail, then make them
    pass with a single edit in `lib/pukllay_club_web/components/layouts.ex`: in `app/1`, the div
    nested directly inside `<main>` currently declares `mx-auto`, a fixed page-width utility, and
    `space-y-4`. Drop the fixed page-width utility from that class list, keeping `mx-auto` and
    `space-y-4` intact — page width is each LiveView's own responsibility per the design-system
    skill's page-container rule.

    Do NOT touch the `<main>` element's own class list — `CatalogLive.Show` declares no padding
    and depends on those gutters.

    Do NOT leave an explanatory code comment in `layouts.ex` naming the removed utility class:
    the verify gate greps this file for that token and a comment mentioning it would fail a
    correct change. Record the rationale in the commit message instead.
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/live/catalog_live_test.exs test/pukllay_club_web/live/catalog_show_test.exs && [ "$(grep -v '^[[:space:]]*#' lib/pukllay_club_web/components/layouts.ex | grep -c 'max-w-2xl')" -eq 0 ]</automated>
    <human-check>Run `mix phx.server`, open `/` on a desktop-width viewport, and confirm the catalog grid now spans well past ~672px (reaching 4 columns at `lg`) instead of sitting in a narrow centred column; then open a `/juegos/:id` page and confirm it renders wider than before with its left/right gutters intact.</human-check>
  </verify>
  <done>`/` renders inside the LiveView's `max-w-7xl` container and `/juegos/:id` inside `max-w-4xl`; no ancestor element caps either page; both new tests pass and the layout file no longer declares the 672px utility outside of comments.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Component-level regression guard on the layout wrapper</name>
  <files>test/pukllay_club_web/components/layouts_test.exs</files>
  <read_first>
    - `test/pukllay_club_web/components/layouts_test.exs` — the existing
      `describe "app/1 header"` block and its `render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})`
      call pattern; mirror it exactly rather than inventing a new invocation.
  </read_first>
  <behavior>
    One new test, `describe "app/1 content wrapper"`, rendering via
    `render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})`:

    - `refute html =~ "max-w-2xl"` — the layout imposes no 672px page-width cap.
    - `assert html =~ "mx-auto"` — the wrapper still centres its slot content.
  </behavior>
  <action>
    Add the `describe` block and single test specified in `<behavior>` below the existing header
    block, reusing the file's existing `render_component/2` invocation verbatim rather than
    inventing a new one.

    Name the test so a future reader understands it guards against reintroducing the 672px page
    cap, and cite the design-system page-container rule in the test name or a short comment above
    the describe block. Do not name the removed utility class in that comment — describe it as the
    672px cap.

    This is the component-level counterpart to Task 1's page-level tests: Task 1 proves the two
    real pages render wide, this one pins the layout contract itself so a new page added later
    cannot silently inherit a cap.
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/components/layouts_test.exs && mix compile --warnings-as-errors</automated>
  </verify>
  <done>`mix test test/pukllay_club_web/components/layouts_test.exs` passes with the new wrapper test included, and the suite compiles with no warnings.</done>
</task>

<task type="auto">
  <name>Task 3: Update the design-system page-container rule</name>
  <files>.claude/skills/ui-design-system/SKILL.md</files>
  <read_first>
    - `.claude/skills/ui-design-system/SKILL.md` — the `Page container:` bullet at the end of the
      `## Spacing/typography scale (observed, not invented)` section. Its trailing parenthetical
      currently flags this as an unfixed defect in `layouts.ex` and tells readers not to copy the
      pattern. After Tasks 1-2 that guidance is stale and actively misleading to any future agent
      that loads this skill.
  </read_first>
  <action>
    Rewrite the `Page container:` bullet so it describes the post-fix contract. Keep the opening
    prescription unchanged (one `mx-auto max-w-{size} px-4 py-6 sm:px-6 lg:px-8` per page). Replace
    the rest with three facts: (1) page width is each LiveView's own responsibility; (2)
    `Layouts.app`'s inner wrapper deliberately declares no `max-w-*` so the page's own container is
    the one that wins — never add a width cap back to the layout; (3) never nest two `max-w-*`
    containers, because the narrower one silently wins regardless of nesting order.

    Delete the trailing parenthetical that flags this as an open defect in `layouts.ex` — the
    condition it describes no longer exists in the codebase.

    Also add a one-line caution that `Layouts.app`'s `<main>` still owns
    `px-4 py-20 sm:px-6 lg:px-8`, and that `CatalogLive.Show` relies on it (it declares no padding
    of its own) — so stripping `<main>`'s padding is a separate, breaking change, not a cleanup.

    Keep the file's existing bullet style, line width, and inline-backtick convention; change no
    other section.
  </action>
  <verify>
    <automated>[ "$(grep -c 'existing bug in' .claude/skills/ui-design-system/SKILL.md)" -eq 0 ] && grep -q 'Page container' .claude/skills/ui-design-system/SKILL.md && grep -q 'py-20' .claude/skills/ui-design-system/SKILL.md</automated>
  </verify>
  <done>The page-container rule states that page width belongs to each LiveView and that the layout deliberately carries no width cap; the stale open-defect parenthetical is gone; the `<main>` padding caution is present.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| browser → Phoenix LiveView render | The only boundary in scope. This change alters a static Tailwind class list on a server-rendered wrapper element; no user-controlled input crosses it as a result of this plan. |
| repo → package registries | Not crossed — this plan installs no packages and touches neither `mix.exs` nor `mix.lock`. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-260818-GDB-01 | Information Disclosure | `Layouts.app/1` content wrapper | low | accept | The wrapper renders the identical `render_slot(@inner_block)` content before and after; only its CSS max-width changes. No previously-hidden data becomes visible — CSS width is not an access-control mechanism here, and nothing in the slot was hidden by overflow (the wrapper has no `overflow-hidden`). |
| T-260818-GDB-02 | Tampering | `.claude/skills/ui-design-system/SKILL.md` | low | accept | The skill file is agent guidance loaded from the repo, already under version control and code review; Task 3 edits one bullet and the verify gate asserts the surrounding rule survives. |
| T-260818-GDB-SC | Tampering | npm/pip/cargo/hex installs | n/a | accept | No package-manager install tasks exist in this plan (no `mix.exs`/`mix.lock` changes), so the package-legitimacy gate is not applicable. Any executor that finds itself needing a new dependency must stop and re-plan. |
</threat_model>

<verification>
Run the project's full quality gate once all three tasks are complete:

```
mix quality
```

This runs `hex.audit`, `deps.audit`, `deps.unlock --check-unused`, `format --check-formatted`
(Styler-augmented), `credo --strict`, `sobelow`, and the full `mix test` suite. It must pass
clean — in particular the pre-existing `catalog_live_test.exs` / `catalog_show_test.exs` /
`layouts_test.exs` assertions must all still pass, proving the width change broke no other
rendering expectation.

Confirm the human-check in Task 1 has been performed and the wider layout looks correct in both
light and dark themes.
</verification>

<success_criteria>
- `lib/pukllay_club_web/components/layouts.ex` `app/1` wrapper declares `mx-auto space-y-4` with no `max-w-*` utility.
- `<main>`'s class list in `app/1` is byte-identical to before this plan.
- `/` renders inside `max-w-7xl`; `/juegos/:id` renders inside `max-w-4xl`; neither has a 672px ancestor cap.
- Three new tests exist (page-level index, page-level show, component-level wrapper) and all pass.
- `.claude/skills/ui-design-system/SKILL.md`'s page-container rule documents the fixed contract, not an open defect.
- `mix quality` passes.
</success_criteria>

<output>
Create `.planning/quick/260818-gdb-fix-the-max-w-2xl-container-bug-in-lib-p/260818-gdb-SUMMARY.md` when done
</output>
