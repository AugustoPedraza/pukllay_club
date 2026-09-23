---
phase: quick-260922-w5o
plan: 01
subsystem: docs
tags: [release, runbook, agents-md, production-ops]
status: complete
dependency-graph:
  requires: [quick-260922-veq]
  provides: [corrected-rpc-to-eval-invocation-docs]
  affects: [lib/pukllay_club/release.ex, docs/runbooks/production-bgg-reenrichment.md, AGENTS.md]
tech-stack:
  added: []
  patterns:
    - "release eval invocation with an explicit three-expression required-processes preamble"
key-files:
  created: []
  modified:
    - lib/pukllay_club/release.ex
    - test/pukllay_club/release_test.exs
    - docs/runbooks/production-bgg-reenrichment.md
    - AGENTS.md
decisions:
  - "Corrected the invocation rule from rpc-only to eval-with-preamble across all four surfaces, since rpc was found unavailable on the production container (verified 2026-09-22, :noconnection) while eval is proven to work"
  - "Root cause of the rpc failure is explicitly documented as NOT established, distinct from the fix itself, so no future reader mistakes 'we worked around it' for 'we know why'"
metrics:
  duration: ~5min (first-to-last task commit; excludes read/planning time)
  completed: 2026-09-22
actuals:
  tokens: 5506
  tasks: 3
  commits: 3
  plan_head_before: 5674757c76bab8bff42dfc52790c03635593044a
---

# Phase quick-260922-w5o Plan 01: Correct rpc -> eval production invocation docs Summary

Corrected the production invocation guidance for `PukllayClub.Release.enrich_bgg_stats/1` and
`PukllayClub.Release.bgg_stats_report/0` from `rpc` (which does not work on the deployed
production container) to `eval` with an explicit required-processes preamble, across all four
surfaces that stated the wrong rule as a hard rule: `lib/pukllay_club/release.ex` (guard message,
`@required_processes` comment, both `@doc` blocks), `test/pukllay_club/release_test.exs` (the
guard's pinned raise-message assertion), `docs/runbooks/production-bgg-reenrichment.md` (rewritten
invocation rule and Steps 1-4), and `AGENTS.md` (the catalog-data pointer section).

## What changed and why

**The corrected preamble**, now shown identically in all three source-of-truth files:

```elixir
{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()
```

`:req` starts `Req.Finch` (the `:req` application's own default Finch pool — confirmed against
`lib/pukllay_club/application.ex`, which contains no Finch entry in its children list; the
pre-existing comment claiming both required processes came from `PukllayClub.Application`'s
supervision tree was half wrong independently of the rpc/eval question, and is now corrected).
`:ecto_sql` is not optional: without it, `PukllayClub.Repo.start_link()` fails with a missing
`DBConnection.Watcher` process, because `:db_connection`'s own supervision tree isn't running.
This is named as required, with its failure mode, everywhere the preamble appears.

**The guard (`ensure_live_node!/1`)** checks registered process names only (`PukllayClub.Repo`,
`Req.Finch`), unchanged — it cannot detect invocation mode. An `eval` that runs the preamble
satisfies it exactly as legitimately as a booted node would; a bare `eval` that skips the preamble
still gets a clean refusal instead of a half-run. Its raise message now tells the operator to run
the preamble, in order, and points at the runbook — it no longer tells them to use `rpc` or claims
`eval` cannot work.

**Behaviour is unchanged**: same `@required_processes` list value, same guard semantics, same
print-don't-return design, same options (`:limit`, `:dry_run`, `:batch_size`, `:delay_ms`), same
capture filenames, no production command run. Only comments, the guard's raise message, `@doc`
strings, the runbook, and `AGENTS.md`'s pointer paragraph changed. `create_owner/1`'s existing
`eval` example (already correct) is byte-identical before and after, confirmed via diff-scoped
verify gates in all three tasks.

## Proven vs. unknown (carried forward from the plan's investigation)

**PROVEN:**

1. `rpc` fails on the production container: `docker exec <container> /app/bin/pukllay_club rpc
   'IO.puts("x")'` returned `--rpc-eval : RPC failed with reason :noconnection`. Host
   `34.41.63.138`, 2026-09-22.
2. Ruled out on that host, as observations only: EPMD up with the node registered; distribution
   enabled (`-sname`/`-setcookie` present); the cookie identical across all three sources
   (`-setcookie` value, `/app/releases/COOKIE`, `RELEASE_COOKIE` env — same sha256); the short
   hostname resolvable via `/etc/hosts`; `Node.ping/1` from an in-container probe node still
   returned `:pang`.
3. `eval` works on that container — every diagnostic above was itself run through it.
4. The preamble above was verified locally via `mix run --no-start` (which reproduces `eval`'s
   bare-node conditions): the guard passed and a real Repo query returned.
5. **`Credentials.fetch()` is now proven on production** — run by the user on the production host
   through `eval` with this preamble on 2026-09-22, returning `{:ok, _}`. `BGG_API_TOKEN`
   demonstrably resolves in-process from Kamal's `env.secret`. This closes one of
   260922-veq's SUMMARY items that was previously only "provable by the operator at invocation
   time." The runbook records this explicitly.

**UNKNOWN — stated as unknown in every surface that touches it, never explained away:**

- **WHY `rpc` fails on this container. The root cause is NOT established.** Every plausible
  mechanism (distribution, hostname truncation, cookies, EPMD) was checked and came back healthy.
  The runbook states this as its own sentence, not folded into the observations list, so a future
  reader cannot mistake "ruled out" for "diagnosed."
- Whether `kamal app exec --reuse` reaches the running container — never exercised on this host;
  the runbook keeps it marked unexercised, unchanged from 260922-veq's status.
- The real before/after enrichment numbers — still unmeasured. The repair run itself remains
  **outstanding and human-gated**; nothing in this plan ran a command against production.

## Verification

- `mix test test/pukllay_club/release_test.exs`: 8/8 tests passing, both before and after edits
  (precondition + post-edit gate).
- `mix quality`: all 7 steps green (`hex.audit`, `deps.audit`, `deps.unlock --check-unused`,
  `format --check-formatted`, `credo --strict`, `sobelow`, `test` — 1490 tests, 0 failures). No
  Styler rewrite was produced, since Task 3 (the only task after Task 1's `.ex`/`.exs` edits)
  touched only `AGENTS.md`.
- Repo-wide `grep -rn 'bin/pukllay_club rpc' lib/ test/ docs/ AGENTS.md` returns nothing.
- `grep -rn 'ensure_all_started(:ecto_sql)'` hits all three files (`release.ex`, the runbook,
  `AGENTS.md`).
- `git diff --stat` from the plan's starting commit shows exactly the four authorized files
  changed: `lib/pukllay_club/release.ex`, `test/pukllay_club/release_test.exs`,
  `docs/runbooks/production-bgg-reenrichment.md`, `AGENTS.md`.
- Diff-scoped gate on `release.ex` confirms zero added function heads, `@spec`s, or changes to the
  `@required_processes` list value — comments/heredoc/doc-string-only.

## Deviations from Plan

None — plan executed exactly as written. All must-haves, scope boundaries (authorized edit
surface, behaviour freeze), and threat-register mitigations (T-W5O-01 through T-W5O-05) were
satisfied as specified; no Rule 1-4 deviation was needed.

## Outstanding

The production repair run (Steps 1-6 of `docs/runbooks/production-bgg-reenrichment.md`) is still
outstanding and remains a separate, human-authorized action. Nothing in this plan ran any command
against production — no ssh, no kamal, no docker exec against the live host, no production
`DATABASE_URL`.

## Self-Check: PASSED

- FOUND: lib/pukllay_club/release.ex
- FOUND: test/pukllay_club/release_test.exs
- FOUND: docs/runbooks/production-bgg-reenrichment.md
- FOUND: AGENTS.md
- FOUND commit 60d7b9c (Task 1)
- FOUND commit 45276b4 (Task 2)
- FOUND commit 1e57d6a (Task 3)
