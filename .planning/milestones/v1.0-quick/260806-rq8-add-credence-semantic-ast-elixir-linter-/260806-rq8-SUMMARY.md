---
phase: 260806-rq8
plan: 1
subsystem: dev-tooling
tags: [quality-gate, mix-quality, styler, mix-audit, formatter, ci]
status: complete

dependency-graph:
  requires: []
  provides:
    - "mix quality 7-step gate (hex.audit, deps.audit, deps.unlock --check-unused, format+Styler, credo, sobelow, test)"
    - "Styler mix format plugin wired via .formatter.exs"
  affects:
    - mix.exs
    - .formatter.exs
    - .claude/CLAUDE.md
    - .planning/research/STACK.md
    - AGENTS.md

tech-stack:
  added:
    - "styler ~> 1.12 (1.12.2) — mix format plugin, dev/test only"
    - "mix_audit ~> 2.1 (2.1.5) — mix deps.audit, dev/test only"
  patterns:
    - "Styler wired as a formatter plugin, not a separate mix quality alias step"
    - "hex.audit runs first in the alias per Mix's own load-order requirement"

key-files:
  created: []
  modified:
    - mix.exs
    - mix.lock
    - .formatter.exs
    - .claude/CLAUDE.md
    - .planning/research/STACK.md
    - AGENTS.md
    - config/config.exs
    - config/dev.exs
    - config/prod.exs
    - config/runtime.exs
    - config/test.exs
    - lib/pukllay_club/mailer.ex
    - lib/pukllay_club_web.ex
    - lib/pukllay_club_web/components/core_components.ex
    - lib/pukllay_club_web/telemetry.ex
    - test/support/conn_case.ex
    - test/support/data_case.ex

decisions:
  - "Used Styler (adobe/elixir-styler, 3.6M downloads, ~3yr old, Adobe-maintained) instead of the originally-scoped credence linter — credence had no project-wide CLI task and would have required a hand-rolled Mix task wrapper; this decision was made and documented in the plan's revision note before this execution started."
  - "Styler wired purely as a .formatter.exs plugin — no new mix quality alias step was needed, since it runs inside the existing format --check-formatted step."
  - "hex.audit/deps.audit/deps.unlock --check-unused placed ahead of format/credo/sobelow/test in the alias: hex.audit must run first (Mix's own requirement to avoid touching :extra_applications), and the other two are cheap metadata-only checks."

metrics:
  duration: 25min
  completed: 2026-08-06

actuals:
  tokens: 9723
  tasks: 3
  commits: 3
---

# Phase 260806-rq8 Plan 1: Add Styler + supply-chain audit gates to `mix quality` Summary

Wired Styler (a mature `mix format` plugin that auto-fixes non-idiomatic Elixir) and `mix_audit`
(dependency vulnerability scanning) into the project's `mix quality` pipeline, reviewed every
Styler first-run rewrite by hand for behavior-changing hunks, and synced the new 7-step gate order
across CLAUDE.md, STACK.md, and AGENTS.md.

## What Was Built

1. **`mix.exs` / `.formatter.exs` wiring** — Added `{:styler, "~> 1.12"}` and `{:mix_audit, "~>
   2.1"}` as `only: [:dev, :test], runtime: false` deps (versions verified live against hex.pm:
   1.12.2 and 2.1.5). Added `Styler` to `.formatter.exs`'s `plugins` list alongside
   `Phoenix.LiveView.HTMLFormatter`. Reordered the `quality` alias to the 7-step sequence:
   `hex.audit`, `deps.audit`, `deps.unlock --check-unused`, `format --check-formatted`, `credo
   --strict`, `sobelow --config`, `test --warnings-as-errors`.

2. **First-run Styler rewrite, manually reviewed** — Ran `mix format` once against the whole
   codebase. It rewrote 13 files (5 config files, 4 lib files, 2 test-support files, plus
   `mix.exs`). Every hunk was read via `git diff` and confirmed to be a pure style change:
   `config` block reordering (no cross-block dependency), `use`/`import`/`alias` grouping and
   reordering (checked for import-shadowing conflicts — none; `mix test --warnings-as-errors`
   would have caught any), long-line collapsing, `@moduledoc false` additions, and a new
   `alias Phoenix.HTML.FormField` used consistently in `core_components.ex`.

3. **One correction applied** — Styler relocated the `## JS Commands` section comment from
   directly above `show/2`/`hide/2` (where it correctly labels those two functions) to sit above
   the unrelated `list/1` doc block instead. This has zero runtime effect (comments don't execute)
   but mislabels the code, so it was manually moved back to its correct position before
   committing — not accepted on trust.

4. **`mix quality` triage** — Ran the full 7-step alias end-to-end: `hex.audit` → "No retired
   packages found", `deps.audit` → "No vulnerabilities found", `deps.unlock --check-unused` →
   silent (nothing unused), `format --check-formatted` → clean, `credo --strict` → 1 pre-existing
   "Software Design" suggestion at `core_components.ex:210` (unrelated to this task's changes,
   not introduced by the Styler rewrite, does not fail `--strict`), `sobelow --config` → clean,
   `test --warnings-as-errors` → 23 tests, 0 failures. Exit code 0.

5. **Documentation sync** — Added Styler and `mix_audit` rows to the "Development Tools" table
   in both `.claude/CLAUDE.md` and `.planning/research/STACK.md` (kept in lockstep per the
   `source:research/STACK.md` marker), updated the "`mix quality` Alias Pattern" section's code
   sample and bullets to the new 7-step order with the `hex.audit`-first rationale and
   cheapest-checks-first grouping, and updated `AGENTS.md`'s `## mix quality Alias` section with
   the new order plus a note on Styler's behavior-change caveat and the review-before-committing
   practice.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected a misplaced section comment produced by the Styler rewrite**
- **Found during:** Task 2 (mandatory first-run rewrite review)
- **Issue:** Styler's rewrite moved the `## JS Commands` section-header comment from directly
  above `show/2` (its correct position, grouping `show/2`/`hide/2`) to directly above the
  unrelated `list/1` function's `@doc` block. Not a runtime behavior change (comments have no
  execution effect), but it mislabels the code and would confuse future readers.
- **Fix:** Manually moved the comment back to sit directly above `show/2`, removing it from its
  incorrect position above `list/1`.
- **Files modified:** `lib/pukllay_club_web/components/core_components.ex`
- **Commit:** 29d0d87 (folded into the reviewed-rewrite commit, since it was caught during the
  same mandatory `git diff` review pass before that commit was made)

Otherwise: plan executed exactly as written. No auth gates encountered.

## Self-Check: PASSED

- `mix.exs` — FOUND (styler/mix_audit deps present, quality alias 7-step)
- `.formatter.exs` — FOUND (Styler in plugins list)
- `.claude/CLAUDE.md` — FOUND (hex.audit + Styler rows present)
- `.planning/research/STACK.md` — FOUND (hex.audit + Styler rows present)
- `AGENTS.md` — FOUND (hex.audit + Styler section present)
- Commit `534a336` — FOUND in `git log`
- Commit `29d0d87` — FOUND in `git log`
- Commit `9477e7f` — FOUND in `git log`
- `mix quality` — exits 0 on the working tree (verified)
