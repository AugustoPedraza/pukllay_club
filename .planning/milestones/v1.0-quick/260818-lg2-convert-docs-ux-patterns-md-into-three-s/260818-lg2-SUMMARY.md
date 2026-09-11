---
phase: quick-260818-lg2
plan: 01
subsystem: docs/skills
tags: [ux, skills, design-system]
dependency-graph:
  requires: [docs/ux-patterns.md, .claude/skills/ui-design-system/SKILL.md]
  provides: [.claude/skills/ux-patterns/SKILL.md, .claude/skills/ux-responsive/SKILL.md]
  affects: [.claude/skills/ui-design-system/SKILL.md]
tech-stack:
  added: []
  patterns:
    - "Claude skills as auto-loading decision tables, keyed to trigger phrases in frontmatter description"
key-files:
  created:
    - .claude/skills/ux-patterns/SKILL.md
    - .claude/skills/ux-responsive/SKILL.md
  modified:
    - .claude/skills/ui-design-system/SKILL.md
decisions:
  - "ux-patterns and ux-responsive created as new skills rather than folding everything into ui-design-system, so each loads only on its own trigger phrases (list/table/form/modal/nav vs layout/responsive/mobile) instead of one oversized always-loaded file"
  - "Sections A (hierarchy) and C (affordance) merged into ui-design-system via Edit-tool-only scoped insertions, preserving every pre-existing line/section verbatim"
  - "Where docs/ux-patterns.md source systems disagreed, each disagreement resolved to one house rule matching this repo's actual state (e.g. no inline-edit component exists, so B10 defaults to modal/full-page) rather than left as an open choice"
metrics:
  duration: 25min
  completed: 2026-08-18
status: complete
actuals:
  tokens: 42000
  tasks: 3
  commits: 3
---

# Phase quick-260818-lg2 Plan 01: Convert docs/ux-patterns.md into three skills Summary

Split the passive `docs/ux-patterns.md` research doc into two new auto-loading Claude skills
(`ux-patterns`, `ux-responsive`) and merged its remaining sections (A hierarchy, C affordance)
into the existing `ui-design-system` skill via scoped Edit-tool insertions — so the guidance
actually reaches code that touches lists, forms, navigation, and layout instead of sitting
unread in `docs/`.

## What was built

**`.claude/skills/ux-patterns/SKILL.md`** (new, 43 lines) — a single decision table (Situation |
Default | Flips when | Implement with) covering B6/B31 (master/detail), B7 (long lists), B8/B32
(navigation), B9 (carousels), B10 (create/edit), B11 (destructive actions), B12 (form
validation), B13 (async feedback), B14 (filter/search), B15 (multi-step flows), B28 (dense list
rows), B30 (empty states), D21 (progressive disclosure), D22 (action caps), D23 (dashboard
splitting). Every "Implement with" cell names a real daisyUI class, `CoreComponents` /
`FilterDrawer` / `CarouselRow` function, or `phx-*` attribute verified against this repo's
working tree — patterns not built here (master/detail, nav swap, keyboard row nav, modal
wrapper, empty states) are recorded as unbuilt/unresolved rather than invented. A "Where sources
disagree" block resolves the three recorded conflicts (B10, B13, B6) to one house rule each, and
the file closes with a one-line precedence note pointing back to `ui-design-system`.

**`.claude/skills/ux-responsive/SKILL.md`** (new, 44 lines) — opens with this repo's actual
Tailwind v4 breakpoint values (sourced from `assets/css/app.css`'s `@theme` block, which declares
no overrides) and the fact that only `sm:`/`lg:` are used anywhere in `lib/pukllay_club_web/`
today. A breakpoint table cross-references `ux-patterns` rows (grid, page container, filter
drawer, carousel card, detail page) and flags master/detail and nav-swap as unbuilt/blocked on
F34's uncommitted device-target decision. Closes with the `min-h-11`/44px touch-target rule
(cross-referencing `ui-design-system` rather than restating it), a touch-vs-pointer section from
E25, and an explicit PWA-out-of-scope line (E27/F35 — no manifest, no service worker).

**`.claude/skills/ui-design-system/SKILL.md`** (edited, 80 → 107 lines) — gained two new
sections via Edit-tool-only scoped insertions, placed directly before the pre-existing Component
inventory table:
- **Type hierarchy**: permitted type scale (`font-display`/`font-sans`/`text-sm`), a 3-level
  size/weight cap per screen, weight/color as the emphasis lever over new sizes, top-left content
  priority, table-column wrap-not-drop pointed at `CoreComponents.table/1`, and numeric
  right-alignment vs identifier-like digit strings staying left-aligned.
- **Affordance**: disabled-vs-hidden (disable for a temporary mode, hide for permanently
  inapplicable, prefer enabled+validate-after per GOV.UK's stronger objection), the
  icon-only-button cap (<3 inline row actions before a labelled menu, naming `CoreComponents.
  icon/1`/`button/1`), a `min-h-11` cross-reference (no second number introduced), hover-not-sole-
  affordance, and the precise-verb action-label rule.

All five original sections (Core rule, Banned, Theme tokens, Spacing/typography scale, Component
inventory) survive byte-for-byte; frontmatter (`name`, `description`) is unchanged.

## Diff report — Task 3 (ui-design-system, Edit-tool insertions only)

One `Edit` call was made against `.claude/skills/ui-design-system/SKILL.md`. It anchored on the
last three lines of the existing Spacing/typography scale section (the `Layouts.app`/`<main>`
padding caution) plus the `## Component inventory` heading that immediately follows, and
inserted two new sections between them — it did not touch, reorder, or delete any character
before the anchor or after it.

| Edit | Landed in | What it added |
|---|---|---|
| 1 (only edit) | New `## Type hierarchy` section, inserted after `## Spacing/typography scale` | 5 bullets: type scale + 3-level cap (A1), weight/color as emphasis lever (A2), top-left priority (A3), table wrap-not-drop -> `CoreComponents.table/1` (A4), numeric right-align vs identifier text (A5) |
| 1 (same edit) | New `## Affordance` section, inserted after Type hierarchy and before `## Component inventory` | 5 bullets: disabled-vs-hidden (C17), icon-only button cap -> `icon/1`/`button/1` (C19), `min-h-11` cross-reference, not a new number (C20), hover-not-sole-affordance (C16), precise action-verb rule (C18) |

Verification that every pre-existing section survived: `grep` for each of `Core rule`, `Banned`,
`Theme tokens`, `Spacing/typography scale`, `Component inventory` all matched post-edit, and
`git diff` shows only `27 insertions(+)`, `0 deletions(-)` — no existing line was touched. File
is 107 lines, under the 120-line cap. Frontmatter's `name: ui-design-system` and `description`
are byte-identical to before the edit.

## Verification

All three plan-level verification checks ran and passed:

1. `wc -l` on all three files: 43 / 44 / 107 — all ≤ 120. PASS
2. Each frontmatter block has exactly `name` and `description`, nothing else — verified via
   `sed`/`grep` key count on all three files. PASS
3. No file introduces a banned styling literal (arbitrary Tailwind values, hex/rgb/hsl,
   non-theme color classes) — negative grep ran clean on all three files, and separately on only
   the *added* lines of the `ui-design-system` diff via `git diff -U0 | grep '^+'`. PASS
4. `ui-design-system` diff surfaced above with every prior section confirmed intact. PASS

Each task's own `<automated>` verify command was also run individually and printed `PASS` before
that task was committed (Task 1, Task 2, Task 3 above).

## Deviations from Plan

None — plan executed exactly as written. All three tasks matched their `<action>` and `<done>`
criteria without needing a Rule 1-4 deviation.

## Known Stubs

None. This is a documentation-only change (three `SKILL.md` files); no runtime code, no UI
component, and no data flow was touched. The skills themselves explicitly record several
patterns as "not built" or "unresolved" (master/detail, nav swap, keyboard row nav, modal
wrapper, empty states) — these are accurate statements of current repo state carried over from
`docs/ux-patterns.md`'s own F34/B30 findings, not stubs introduced by this task.

## Self-Check

- `.claude/skills/ux-patterns/SKILL.md` — FOUND
- `.claude/skills/ux-responsive/SKILL.md` — FOUND
- `.claude/skills/ui-design-system/SKILL.md` — FOUND (modified)
- Commit `0d6e3db` (Task 1) — FOUND in `git log`
- Commit `e1641c9` (Task 2) — FOUND in `git log`
- Commit `3a4380e` (Task 3) — FOUND in `git log`

## Self-Check: PASSED
