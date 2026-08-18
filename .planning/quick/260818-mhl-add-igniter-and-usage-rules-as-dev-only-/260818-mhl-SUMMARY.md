---
phase: quick-260818-mhl
plan: 01
subsystem: build-tooling
tags: [mix, usage_rules, igniter, agents-md, dev-tooling]
status: complete
dependency-graph:
  requires: []
  provides: [rules.sync-alias, usage-rules-md-link-mode]
  affects: [mix.exs, AGENTS.md]
tech-stack:
  added: [usage_rules ~> 1.1 (dev-only), igniter ~> 0.6 (dev-only)]
  patterns: [config-driven mix.exs :usage_rules key, link-not-inline for dep-authored markdown]
key-files:
  created: []
  modified: [mix.exs, mix.lock, AGENTS.md]
decisions:
  - "Used {:usage_rules, sub_rules: [\"elixir\", \"otp\"]} instead of the bare :usage_rules atom, to pin exactly 3 inlined sections (main + elixir + otp) regardless of future usage_rules releases adding more sub-rules"
  - "Catch-all link regex excludes usage_rules itself via a negative lookahead (^(?!usage_rules$).+) — without this exclusion the regex would re-resolve the usage_rules package a second time in link mode, producing duplicate marker blocks"
metrics:
  duration: ~35min
  completed: 2026-08-18
actuals:
  tokens: 8500
  tasks: 3
  commits: 1
---

# Quick Task 260818-mhl: Add usage_rules + igniter as dev-only deps Summary

Wired `usage_rules` (1.2.7, satisfying `~> 1.1`) and `igniter` (0.8.3, satisfying `~> 0.6`) as
dev-only dependencies, then used the config-driven `mix rules.sync` alias to regenerate
AGENTS.md's existing `<!-- usage-rules-start -->`/`<!-- usage-rules-end -->` marker block in link
mode — collapsing 19.5KB of inlined phoenix rules into 5 markdown links, while keeping the
hand-written policy preamble (lines 1-95) byte-identical.

## What Was Built

1. **`mix.exs` deps** — `{:usage_rules, "~> 1.1", only: [:dev]}` and
   `{:igniter, "~> 0.6", only: [:dev]}` added near the other tooling deps (credo/sobelow/styler/
   mix_audit/tidewave). Resolved to 1.2.7 and 0.8.3 respectively; both dev-only, excluded from
   the production release.

2. **`usage_rules/0` private config function**, wired into `project/0` as `usage_rules:
   usage_rules()`:
   ```elixir
   defp usage_rules do
     [
       file: "AGENTS.md",
       usage_rules: [
         {:usage_rules, sub_rules: ["elixir", "otp"]},
         {~r/^(?!usage_rules$).+/, link: :markdown}
       ]
     ]
   end
   ```
   - `file: "AGENTS.md"` is required — without it `usage_rules.sync` writes to its own default
     target (`CLAUDE.md`) instead.
   - `{:usage_rules, sub_rules: ["elixir", "otp"]}` inlines exactly usage_rules' own main
     `usage-rules.md` plus its `elixir` and `otp` builtin sub-rules — 3 sections, pinned
     explicitly rather than relying on the bare `:usage_rules` atom's `sub_rules: :all` default
     (see Deviations for why).
   - The catch-all regex links every *other* dependency's usage rules (currently `phoenix`'s 5
     sub-rules and `igniter`'s main file), picking up future deps automatically with no further
     mix.exs edits. It explicitly excludes `usage_rules` via a negative lookahead so that package
     isn't resolved a second time in link mode (see Deviations).
   - No `skills:` key — omitted per the plan's constraint (repo already has 3 hand-written
     project skills under `.claude/skills/`).

3. **`rules.sync` alias**, merged into the existing `aliases/0` list alongside
   `setup`/`precommit`/`quality` (none removed): `"rules.sync": ["usage_rules.sync"]`.

4. **AGENTS.md marker block regenerated** in link mode. `mix rules.sync --yes` run twice —
   second run left the file byte-identical (idempotent). The `--yes` flag was required because
   `usage_rules.sync` (Igniter-based) prompts for confirmation and this task runs
   non-interactively.

## The Four Requested Facts

**1. `git diff --stat AGENTS.md`:**
```
 AGENTS.md | 512 +++++++++++++++++---------------------------------------------
 1 file changed, 135 insertions(+), 377 deletions(-)
```
Byte delta: 25,492 -> 12,336 bytes (**-13,156 bytes, -51.6%**). This is negative, as
expected — link mode replaced the 19.5KB of previously-inlined phoenix sub-rules with 5 short
markdown links (phoenix.md, ecto.md, html.md, liveview.md, elixir.md), plus added the new
usage_rules/igniter sections. Every one of the 377 removed lines was verified recoverable from
`deps/` (0 unaccounted — see fact 4).

**2. Deps that shipped usage rules, and link vs inline:**

| Package | On-disk shape | Inlined or linked |
|---------|---------------|--------------------|
| `phoenix` | `deps/phoenix/usage-rules/` directory (5 sub-rules: `ecto.md`, `elixir.md`, `html.md`, `liveview.md`, `phoenix.md`) | **Linked** — 5 markdown links to `deps/phoenix/usage-rules/*.md` |
| `usage_rules` | `deps/usage_rules/usage-rules.md` (main) + `deps/usage_rules/usage-rules/` dir (`elixir.md`, `otp.md`) | **Inlined** — main + both sub-rules (3 sections) |
| `igniter` | `deps/igniter/usage-rules.md` (flat file) | **Linked** — 1 markdown link to `deps/igniter/usage-rules.md` |

No other current dependency ships usage rules.

**3. New AGENTS.md size:** 12,336 bytes, vs the 25,492-byte starting size (-13,156 bytes).

**4. No pre-existing content lost:**
- Preamble sha256 (`head -95 AGENTS.md`) = `44d022191910bfe0d29e9da21cd5534da9c8109258dd38fd6eebe2e16c9a4177` —
  matches the recorded baseline exactly, both immediately after Task 1's sync and after the
  idempotent second run.
- Zero of the 377 removed lines are unaccounted for against the concatenated on-disk
  `deps/*/usage-rules*.md` sources (Task 2 audit, `${TMPDIR}/mhl-unaccounted.txt` = empty).
- Preamble sections that survived by name: **Project guidelines**, **TDD Loop**, **`mix quality`
  Alias**, **Manual Merge Gate**, **Non-Goals (Phase 0)**, **Phoenix v1.8 guidelines**, **JS and
  CSS guidelines**, **UI/UX & design guidelines**.

## Operational Notes for the Developer

- **Link targets live under gitignored `deps/`** (`.gitignore` line 8) — the linked rules
  (phoenix's 5 sub-rules, igniter's rules) are unreadable on a fresh clone until `mix deps.get`
  runs. This is inherent to link mode, not a bug.
- **T-QT-02 (accepted risk):** dependency-authored markdown now enters agent context via those
  `deps/` links without passing through git diff review — a compromised dependency's usage-rules
  content would bypass the review that inlined content would have gotten. Accepted because the
  same trust boundary is already crossed by compiling the dependency; the linked files are
  read-only markdown.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Igniter confirmation prompt required `--yes` for non-interactive runs**
- **Found during:** Task 1, first `mix rules.sync` run
- **Issue:** `usage_rules.sync` (Igniter-based) prints a diff preview and prompts
  `Proceed with changes? [Y/n]`, which raises `RuntimeError: No input detected` when stdin isn't
  a TTY.
- **Fix:** Ran `mix rules.sync --yes` for all subsequent (and idempotence-proving) invocations.
  Not an mix.exs change — purely an invocation detail, documented here for future re-runs.
- **Files modified:** none (invocation-only)
- **Commit:** N/A (no code change)

**2. [Rule 1 - Bug avoidance] Explicit `sub_rules: ["elixir", "otp"]` instead of bare `:usage_rules`, and negative-lookahead regex to exclude `usage_rules` from the catch-all**
- **Found during:** Task 1, `<read_first>` review of `deps/usage_rules/lib/mix/tasks/usage_rules.sync.ex`
- **Issue:** The installed source revealed two duplication traps not obvious from the README
  alone: (a) a bare `:usage_rules` atom resolves with `sub_rules: :all` by default, so it would
  auto-include *any* future usage_rules sub-rule beyond elixir/otp — drifting from the "exactly
  3 things inlined" requirement; (b) a naive catch-all regex like `~r/.*/` matches the
  `usage_rules` package name too, causing it to be resolved a **second time** in link mode
  (`resolve_usage_rules` concatenates results per-spec with no cross-spec dedup), which would
  have produced duplicate `<!-- usage_rules-start -->` / `<!-- usage_rules:elixir-start -->` /
  `<!-- usage_rules:otp-start -->` marker blocks in the same file.
- **Fix:** Used `{:usage_rules, sub_rules: ["elixir", "otp"]}` (pins exactly 3 sections
  permanently) and `{~r/^(?!usage_rules$).+/, link: :markdown}` (excludes `usage_rules` from the
  catch-all via negative lookahead, verified with `Regex.match?/2` in `project_eval` before
  writing to mix.exs).
- **Files modified:** mix.exs
- **Commit:** e775f45

None of the plan's `<established_facts>` were contradicted — the installed source confirmed the
v1.x config-driven API shape and the `skills:` key behavior exactly as hypothesized. No
architectural changes; no Rule 4 escalations.

## Self-Check: PASSED

- `mix.exs` — FOUND (modified, contains `usage_rules()`, `{:usage_rules, ...}`, `{:igniter,
  ...}`, `"rules.sync": [...]`)
- `mix.lock` — FOUND (modified, +9 lines: usage_rules/igniter + transitive deps pinned)
- `AGENTS.md` — FOUND (modified, 12,336 bytes, preamble sha256-verified intact)
- Commit `e775f45` — FOUND in `git log --oneline`
- `mix compile --warnings-as-errors` — exit 0
- `mix format --check-formatted mix.exs` — exit 0
- Idempotence (`mix rules.sync --yes` run twice) — AGENTS.md byte-identical between runs
- Zero unaccounted removed lines against `deps/*/usage-rules*.md` — confirmed
- `.claude/`, `lib/`, `test/`, `priv/` — no new git modifications
- No root `CLAUDE.md` created

## Known Stubs

None.
