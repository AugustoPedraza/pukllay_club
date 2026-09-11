---
phase: quick-260818-n4l
plan: 01
subsystem: testing
tags: [dialyxir, excoveralls, mix, coverage, dialyzer, tooling]

requires: []
provides:
  - "excoveralls dep wired with test_coverage: [tool: ExCoveralls] and coveralls/coveralls.detail/coveralls.html routed to MIX_ENV=test"
  - "dialyxir dep wired with a fixed PLT path + plt_add_apps, resolvable under MIX_ENV=test, PLT not built"
  - "quality.full alias (quality + dialyzer) for a slower per-phase static-type gate"
  - "non-mutating precommit alias safe for GSD's unattended auto-commit executor"
affects: [ci, quality-gates, future-quick-tasks-touching-mix-exs]

actuals:
  tokens: 2107
  tasks: 3
  commits: 3

tech-stack:
  added: ["excoveralls 0.18.5 (only: :test)", "dialyxir 1.4.7 (only: [:dev, :test], runtime: false)"]
  patterns: ["cli/0 preferred_envs (not deprecated project/0 preferred_cli_env) as the single source of truth for per-task MIX_ENV routing on Elixir 1.19.5", "check-only alias steps (--check-unused, --check-formatted) for any alias the unattended executor runs unattended"]

key-files:
  created: []
  modified: ["mix.exs", "mix.lock", ".gitignore"]

key-decisions:
  - "preferred_cli_env goes in cli/0, not project/0 — project/0's :preferred_cli_env is deprecated/superseded on Elixir 1.19.5; adding it there would be a silent no-op and mix coveralls would run under MIX_ENV=dev"
  - "dialyxir is only: [:dev, :test], not only: [:dev] as literally described — quality.full ends in test --warnings-as-errors, so a :dev-only dialyxir would make quality.full die with 'The task dialyzer could not be found'"
  - ".gitignore covers both /priv/plts/*.plt and /priv/plts/*.plt.hash — dialyxir writes a hash sidecar next to the PLT that a *.plt-only ignore would leave tracked"
  - "\"quality.full\": :test added to preferred_envs — without it mix quality.full runs under MIX_ENV=dev and its nested test --warnings-as-errors step executes in the wrong environment/DB/sandbox"

patterns-established:
  - "New unattended-safe aliases must use check-only flags (deps.unlock --check-unused, format --check-formatted), never the mutating variants — the quality alias already established this; precommit now matches it"

requirements-completed: [QT-N4L-01, QT-N4L-02, QT-N4L-03, QT-N4L-04, QT-N4L-05, QT-N4L-06, QT-N4L-07]

coverage:
  - id: D1
    description: "excoveralls + dialyxir added as tooling deps at hex-registry-confirmed versions (~> 0.18 -> 0.18.5, ~> 1.4 -> 1.4.7), no guessed version strings"
    requirement: QT-N4L-01
    verification:
      - kind: other
        ref: "mix hex.info excoveralls / mix hex.info dialyxir (output quoted below)"
        status: pass
    human_judgment: false
  - id: D2
    description: "project/0 carries test_coverage: [tool: ExCoveralls]"
    requirement: QT-N4L-02
    verification:
      - kind: other
        ref: "mix run --no-start -e 'IO.puts(inspect(Mix.Project.config()[:test_coverage]))' -> [tool: ExCoveralls]"
        status: pass
    human_judgment: false
  - id: D3
    description: "mix coveralls proven green from a dropped test database — coveralls resolves in MIX_ENV=test and gets a migrated DB via the existing test alias"
    requirement: QT-N4L-03
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix ecto.drop --quiet && mix coveralls -> exit 0, 143 tests, 0 failures, TOTAL 57.5%"
        status: pass
    human_judgment: false
  - id: D4
    description: "dialyzer config (plt_file + plt_add_apps) present, PLT artifacts gitignored, PLT deliberately not built"
    requirement: QT-N4L-04
    verification:
      - kind: other
        ref: "MIX_ENV=test mix help dialyzer (exit 0); git check-ignore priv/plts/dialyzer.plt + .plt.hash (exit 0); test ! -e priv/plts/dialyzer.plt"
        status: pass
    human_judgment: false
  - id: D5
    description: "precommit alias made non-mutating (check-only flags); quality alias byte-identical"
    requirement: QT-N4L-05
    verification:
      - kind: other
        ref: "mix run --no-start alias introspection (precommit and quality values quoted below), negative mutating-step gate"
        status: pass
    human_judgment: false
  - id: D6
    description: "quality.full alias = quality + dialyzer, routed to MIX_ENV=test"
    requirement: QT-N4L-06
    verification:
      - kind: other
        ref: "mix run --no-start alias introspection -> QFULL: quality | dialyzer; preferred_envs contains \"quality.full\": :test"
        status: pass
    human_judgment: false
  - id: D7
    description: "mix precommit executed; halted at the pre-existing formatting gate on config/runtime.exs without rewriting it"
    requirement: QT-N4L-07
    verification:
      - kind: other
        ref: "mix precommit output (quoted below); git status confirms config/runtime.exs unmodified beyond its pre-existing dirty state"
        status: pass
    human_judgment: true
    rationale: "The deliberate-stop branch is a judgment call about whether the halt was correctly diagnosed as pre-existing vs. task-caused — worth a human glance at the SUMMARY's listed file before accepting."

duration: 25min
completed: 2026-08-18
status: complete
---

# Quick Task 260818-n4l: Add dialyxir + excoveralls, make precommit non-mutating Summary

**Wired excoveralls (0.18.5) and dialyxir (1.4.7) into mix.exs with a proven MIX_ENV=test coverage path, a fixed-PLT dialyzer config (PLT deliberately not built), a new `quality.full` alias, and a `precommit` alias converted to check-only flags so the unattended GSD executor can never auto-commit a silent formatter/lockfile rewrite.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3 (all `type="auto"`/`type="tracer"`, no checkpoints)
- **Files modified:** 3 (mix.exs, mix.lock, .gitignore)

## Accomplishments

- Excoveralls wired end-to-end and proven, not assumed: `mix coveralls` exits 0 with a full per-module coverage table and TOTAL line, run immediately after `MIX_ENV=test mix ecto.drop --quiet` — no coveralls alias override was needed because the coverage task correctly resolves the existing `test` alias (`ecto.create --quiet`, `ecto.migrate --quiet`, `test`) via `cli/0`'s `preferred_envs`.
- Dialyxir wired with a fixed `plt_file`/`plt_add_apps` config and confirmed resolvable under `MIX_ENV=test mix help dialyzer` — the PLT itself was deliberately **not built** (multi-minute cost, out of scope for this task).
- `precommit` converted from a mutating alias (`deps.unlock --unused`, `format`) to a check-only one (`deps.unlock --check-unused`, `format --check-formatted`) — closes the silent-mutation hole where an unattended `mix precommit` run could rewrite a tracked file and fold it into an automated commit.
- New `quality.full` alias (`["quality", "dialyzer"]`, referencing the existing `quality` alias by name so the two can never drift) plus `"quality.full": :test` added to `preferred_envs`.
- `mix precommit` actually executed: halted at the formatting gate on the single pre-existing unformatted file `config/runtime.exs` — left unmodified, exactly the documented expected outcome.

## Version facts (mix hex.info, run live — not guessed)

- `mix hex.info excoveralls` -> **Config: `{:excoveralls, "~> 0.18.5"}`**, current releases: 0.18.5, 0.18.4, 0.18.3, ... . Written to mix.exs as `{:excoveralls, "~> 0.18", only: :test}` (two-segment `~> MAJOR.MINOR` style matching the existing `{:sobelow, "~> 0.14", ...}` convention).
- `mix hex.info dialyxir` -> **Config: `{:dialyxir, "~> 1.4"}`**, current releases: 1.4.7, 1.4.6, 1.4.5, ... . Written to mix.exs as `{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}`.

## `mix coveralls` proof (Task 1)

Run immediately after `MIX_ENV=test mix ecto.drop --quiet` (test database genuinely dropped first, not assumed to exist):

```
Running ExUnit with seed: 412403, max_cases: 8
Finished in 3.6 seconds (2.8s async, 0.7s sync)
143 tests, 0 failures
----------------
COV    FILE                                        LINES RELEVANT   MISSED
...
[TOTAL]  57.5%
----------------
```

Exit code: 0. No coveralls alias override (`coveralls: ["ecto.create --quiet", "ecto.migrate --quiet", "coveralls"]`) was needed — the plain `coveralls`/`coveralls.detail`/`coveralls.html` -> `:test` entries in `preferred_envs` were sufficient because `mix coveralls` internally invokes the project's `test` task pipeline, which is aliased to run `ecto.create --quiet` and `ecto.migrate --quiet` first.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end coverage — excoveralls dep -> config -> preferred env -> a green `mix coveralls` from a dropped database** - `dea0c71` (feat)
2. **Task 2: dialyxir wired and resolvable in the env quality.full runs in — without building the PLT** - `a61e908` (feat)
3. **Task 3: Make precommit non-mutating, add quality.full, then run precommit and HALT on pre-existing unformatted files** - `c11b257` (fix)

## Files Created/Modified

- `mix.exs` - excoveralls + dialyxir deps; `test_coverage:` and `dialyzer:` keys in `project/0`; `cli/0` `preferred_envs` extended with `coveralls`/`coveralls.detail`/`coveralls.html`/`quality.full` -> `:test`; `precommit` alias rewritten to check-only flags; new `quality.full` alias added; `quality` alias untouched
- `mix.lock` - excoveralls, dialyxir, and erlex (dialyxir's transitive dep) pinned with checksums
- `.gitignore` - added `/priv/plts/*.plt` and `/priv/plts/*.plt.hash`

## Decisions Made

All four are mechanism corrections the plan pre-specified as deviations from the literal task description — restated here per the plan's explicit instruction:

**1. `preferred_cli_env` goes in `cli/0`, not `project/0`.** This project already defines `def cli/0` with `preferred_envs: [precommit: :test, quality: :test]`. On Elixir 1.19.5 (confirmed live: `elixir --version` -> 1.19.5 / OTP 28), `project/0`'s `:preferred_cli_env` is deprecated and superseded by `cli/0`. Adding the coveralls entries to `project/0` would have been a silent no-op and `mix coveralls` would have run under `MIX_ENV=dev`. Added to the existing `cli/0` `preferred_envs` list instead — same outcome, correct mechanism.

**2. dialyxir is `only: [:dev, :test]`, not `only: [:dev]`.** The literal task description said `only: [:dev]`, but its own requirement for `quality.full` (= `quality` + `dialyzer`) needs the `dialyzer` task available in `MIX_ENV=test` (`quality` ends in `test --warnings-as-errors`, so `quality.full` runs entirely under `MIX_ENV=test`). A `:dev`-only dialyxir would have made `quality.full` fail with "The task dialyzer could not be found". `[:dev, :test]` matches the existing convention for every other tooling dep in this file (credo, sobelow, styler, mix_audit are all `only: [:dev, :test], runtime: false`).

**User follow-up note:** because `quality.full` runs dialyzer under `MIX_ENV=test` against the single fixed `priv/plts/dialyzer.plt` path, the recommended manual PLT build command is `MIX_ENV=test mix dialyzer --plt` (not a plain dev-env `mix dialyzer`, which would alternate updating the same PLT file from a different env and thrash it). A one-line alternative — `plt_file: {:no_warn, "priv/plts/dialyzer-#{Mix.env()}.plt"}` (env-suffixed PLT paths) — is offered as an optional follow-up the user can accept or reject; it was **not** applied in this task.

**3. `.gitignore` also covers `*.plt.hash`.** dialyxir writes a hash sidecar next to the PLT; ignoring only `*.plt` would have left that artifact tracked. Both `/priv/plts/*.plt` and `/priv/plts/*.plt.hash` are ignored, confirmed via `git check-ignore -q` on both paths (exit 0 for each).

**4. `"quality.full": :test` added to `preferred_envs` too.** Without it, `mix quality.full` would run under `MIX_ENV=dev` and its nested `test --warnings-as-errors` step would execute the suite in the dev environment against the wrong database/sandbox config.

## Deviations from Plan

None beyond the four pre-specified deviations restated above (they are documented mechanism corrections baked into the plan itself, not discoveries made during execution).

## Structural verification (Task 3)

Alias values read via `Mix.Project.config()[:aliases]` (comment-immune, not raw file text):

```
PRECOMMIT: compile --warnings-as-errors | deps.unlock --check-unused | format --check-formatted | test
QUALITY:   hex.audit | deps.audit | deps.unlock --check-unused | format --check-formatted | credo --strict | sobelow --config | test --warnings-as-errors
QFULL:     quality | dialyzer
```

`quality` is byte-identical to its pre-task definition. `precommit`'s negative gate (no `format` or `deps.unlock --unused` as a whole entry) passes. `preferred_envs` contains `"quality.full": :test` alongside the pre-existing `precommit: :test` / `quality: :test` and the new `coveralls`/`coveralls.detail`/`coveralls.html` -> `:test` entries.

`mix quality.full` was **not executed end-to-end** — its `dialyzer` step would build a multi-minute PLT and blow the execution timeout. It is verified structurally only: the alias value above plus Task 2's `MIX_ENV=test mix help dialyzer` exit-0 check, which confirms the `dialyzer` task actually resolves in the environment `quality.full` runs in.

## `mix precommit` outcome — deliberate stop at the formatting gate

`mix precommit` was executed and **failed at the `format --check-formatted` step**, exactly as expected. This is a **pre-existing condition, not caused by this task**: `config/runtime.exs` was already modified and already unformatted in the working tree before this task started (visible in `git status` from the very first command of this session).

Unformatted file reported, verbatim:

```
/home/apedraza/projects/pukllay_club/config/runtime.exs
```

The diff shown by the formatter is a comment-block reordering (moving a comment above the code it describes) — cosmetic, not a logic change. **Per the plan, this file was NOT edited, NOT reformatted, and NOT staged by this task.** The reformat is left to the user as a separate, isolated commit they make themselves.

Because `precommit` never reached its `test` step in this branch (compile and `deps.unlock --check-unused` passed silently before the formatting gate stopped it), note that Task 1's `mix coveralls` run already exercised the full 143-test suite green (0 failures) immediately before this, so the codebase's test health is independently confirmed.

## Scope fence confirmation

`git status --short` after all three commits shows only the pre-existing dirty files that were already modified/untracked before this task started (`.planning/STATE.md`, `.planning/config.json`, `.planning/phases/01-catalog-v1/01-UAT.md`, `.planning/phases/01-catalog-v1/01-VOCABULARY.md`, `config/dev.exs`, `config/runtime.exs`, plus untracked `.gsd/` and `.planning/research/.cache/*`, `.planning/WINDOWS.md`) — none touched by this task. `mix.exs`, `mix.lock`, and `.gitignore` are clean (all changes committed). Nothing under `lib/`, `test/`, `priv/repo/`, or `.planning/` gained a modification from this task.

## Issues Encountered

None.

## Next Phase Readiness

- `mix coveralls` / `mix coveralls.detail` / `mix coveralls.html` are ready to use on demand for real coverage numbers.
- `mix quality.full` is ready once the user manually builds the PLT with `MIX_ENV=test mix dialyzer --plt` (multi-minute, not run here by design).
- `mix precommit` is now safe for GSD's unattended executor — it can no longer silently rewrite a tracked file into an automated commit.
- Outstanding, pre-existing, and explicitly out of scope for this task: `config/runtime.exs` needs a standalone `mix format` commit (comment-reorder only) whenever the user chooses to make it.

## Self-Check: PASSED

- FOUND: mix.exs
- FOUND: mix.lock
- FOUND: .gitignore
- FOUND: dea0c71 (Task 1 commit)
- FOUND: a61e908 (Task 2 commit)
- FOUND: c11b257 (Task 3 commit)

---
*Quick task: 260818-n4l*
*Completed: 2026-08-18*
