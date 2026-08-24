---
phase: quick-260821-umm
plan: 01
subsystem: web-shell
tags: [layouts, footer, brand, tagline, tdd]
status: complete
dependency-graph:
  requires: []
  provides:
    - "Layouts.brand_logo/1 tagline attr"
    - "footer left-cluster tagline override"
  affects:
    - lib/pukllay_club_web/components/layouts.ex
tech-stack:
  added: []
  patterns:
    - "Phoenix.Component optional attr with default, overridden at one call site (matches Layouts.app/1's fullbleed/sticky pattern and CarouselRow.carousel_row/1's variant/subtitle pattern)"
key-files:
  created: []
  modified:
    - lib/pukllay_club_web/components/layouts.ex
    - test/pukllay_club_web/components/layouts_test.exs
    - .claude/skills/ui-design-system/SKILL.md
decisions:
  - "D-01: parameterize brand_logo/1 with an optional tagline attr (default = existing header literal) rather than duplicate the lockup markup in a second footer-only component — keeps the isologo compile-time gate and wordmark markup in one place, matches house style (Layouts.app/1, CarouselRow.carousel_row/1 already use optional-attr variation)"
  - "D-02: kept the tagline span's existing classes (font-sans text-xs uppercase tracking-widest text-neutral) unchanged, only swapping the text content — avoids reopening the just-closed 260821-dah type-inventory cap (5/3 combos) with a sixth combo"
  - "Corrected the task description's quoted tagline from 'Conecta jugando' to 'Conectá jugando' (accented voseo imperative) — the actual about_live.ex line 43 <h1> string, verified character-for-character via grep against both files post-change"
metrics:
  duration: 20min
  completed: 2026-08-21
actuals:
  tokens: 6500
  tasks: 3
  commits: 3
---

# Quick Task 260821-umm: Footer Left Cluster Tagline Summary

Parameterized `Layouts.brand_logo/1` with an optional `tagline` attr (default: the existing
header subtitle literal) and made the footer's left cluster the one call site that overrides it
with the About page's hero tagline, stopping the footer from repeating the header's brand
subtitle.

## What Was Built

- `Layouts.brand_logo/1` gained `attr :tagline, :string, default: "JUEGOS DE MESA MODERNOS"`. The
  hardcoded second-line text in the template was replaced with `{@tagline}`. Every existing call
  site (the header at `header_inner/1`, and the two `render_component(&Layouts.brand_logo/1, %{})`
  test calls) renders byte-identically since the default matches the prior hardcoded literal.
- `footer/1`'s left cluster now calls `<.brand_logo tagline="Conectá jugando" />` — the accented
  string copied verbatim from `about_live.ex` line 43's `<h1>`.
- Five new tests added to `layouts_test.exs`, scoped with `LazyHTML` to `.pk-footer-left` and
  `#app-header` so the assertions can't pass vacuously: footer renders the tagline, footer does
  NOT render the header subtitle, header still renders its original subtitle and NOT the tagline,
  a no-attr `brand_logo/1` render is unchanged, and the footer still emits no `isologo.svg`
  reference.
- `.claude/skills/ui-design-system/SKILL.md` row 181 (`Layouts` / `brand_logo/1`) updated to
  document the new optional `tagline` attr, its default, and that the footer is the one override
  site — matching the house format already used by the `app/1` and `carousel_row/1` rows.

## Correction to the Task Description

The task description quoted the tagline as `Conecta jugando`. That string does not exist in the
codebase. `about_live.ex` line 43's actual `<h1>` reads `Conectá jugando` (acute accent, Argentine
voseo imperative). Since the task's own binding constraint is verbatim match to `about_live.ex`,
the accented form is authoritative and was used throughout. Confirmed post-implementation via
`grep -n "Conectá jugando" lib/pukllay_club_web/components/layouts.ex lib/pukllay_club_web/live/about_live.ex`
— both files contain the identical string.

## Decisions

**D-01 (parameterize vs. duplicate):** Chose to add an optional `tagline` attr to
`brand_logo/1` rather than build a second, footer-local brand component. The constraint's
parenthetical ("the header still needs its subtitle") states the real intent is that the header's
rendered output must not change — parameterizing satisfies that while avoiding a duplicated
isologo compile-time gate and a second entry in the design-system component inventory. This also
matches how `Layouts.app/1` (`fullbleed`, `sticky`) and `CarouselRow.carousel_row/1` (`variant`,
`subtitle`) already express optional per-call-site variation in this codebase.

**D-02 (type treatment unchanged):** The tagline `<span>`'s classes
(`font-sans text-xs uppercase tracking-widest text-neutral`) were left exactly as-is; only the
text content changed. Quick task `260821-dah` had just re-measured this screen's font-combination
inventory at 5/3-cap; introducing a differently-styled tagline treatment for the footer would have
reopened that just-closed todo. Since `uppercase` is a CSS text-transform, the DOM text stays
`Conectá jugando` (what the tests assert on) while the rendered footer visually displays it in
small caps.

## Human-Check Outcome (visual, non-blocking per `human_verify_mode: end-of-phase`)

Not performed via a live browser session in this run — `human_verify_mode` for this plan is
`end-of-phase`, making the visual check non-blocking. Verified programmatically instead: the
`Conectá jugando` string is byte-identical between `layouts.ex`'s footer call site and
`about_live.ex`'s `<h1>` (confirmed via `grep`), and the tagline `<span>` reuses the exact same
`uppercase` CSS class already proven to render Latin-1 accented characters correctly elsewhere in
the app (the header's own subtitle uses the same class treatment). If the accented capital reads
badly in the rendered caps treatment, that's flagged as a follow-up styling decision per the
plan's own verification note — not a fix inside this task, since changing it would reopen the
type-inventory cap.

## Deviations from Plan

None — plan executed exactly as written, including the TDD RED/GREEN sequence for Task 1.

## TDD Gate Compliance

- RED: `test(quick-260821-umm): add failing tests for footer tagline override` (commit `c141fa4`)
  — confirmed Tests 1-2 failed and Tests 3-5 passed before any implementation change.
- GREEN: `feat(quick-260821-umm): footer's left cluster uses About hero tagline` (commit `9734f18`)
  — all 26 tests in the file pass.
- REFACTOR: not needed — the minimal diff (one attr declaration, one interpolation, one call-site
  override) required no cleanup pass.

## Verification

- `mix test test/pukllay_club_web/components/layouts_test.exs` — 26 tests, 0 failures.
- `mix quality` — exits 0 (hex.audit, deps.audit, deps.unlock --check-unused, format
  --check-formatted, credo --strict, sobelow, test all pass). Credo flagged one pre-existing
  Software Design suggestion in `core_components.ex` and Sobelow flagged four pre-existing
  low-confidence directory-traversal warnings in `csv_import.ex`/`report.ex` — both unrelated to
  this change's files, out of scope per the plan's Task 3 instruction, not fixed.
- `git diff --stat` across the three task commits shows exactly three files changed:
  `.claude/skills/ui-design-system/SKILL.md`, `lib/pukllay_club_web/components/layouts.ex`,
  `test/pukllay_club_web/components/layouts_test.exs`. No footer/header markup outside the left
  cluster, `about_live.ex`, or the isologo asset appear in the diff.

## Self-Check: PASSED

- FOUND: lib/pukllay_club_web/components/layouts.ex (modified, tagline attr + footer override present)
- FOUND: test/pukllay_club_web/components/layouts_test.exs (modified, 5 new tests present)
- FOUND: .claude/skills/ui-design-system/SKILL.md (modified, row 181 updated)
- FOUND commit c141fa4 (test: RED)
- FOUND commit 9734f18 (feat: GREEN)
- FOUND commit 38941d9 (docs: inventory row)
