---
phase: quick-260818-mhl
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - mix.exs
  - mix.lock
  - AGENTS.md
autonomous: true
requirements:
  - QT-MHL-01   # deps: usage_rules ~> 1.1 + igniter ~> 0.6, dev-only
  - QT-MHL-02   # config-driven :usage_rules key in mix.exs project/0, file: "AGENTS.md"
  - QT-MHL-03   # link-not-inline for dependency rules; inline only usage_rules' own + elixir/otp builtins
  - QT-MHL-04   # rules.sync alias, re-runnable when deps change
  - QT-MHL-05   # AGENTS.md hand-written policy preamble provably intact
user_setup: []

estimate:
  tokens: 58000
  raw_tokens: 34000
  tasks: 3
  confidence: low          # no calibration samples on record for this repo

must_haves:
  truths:
    - "`mix deps.get` resolves usage_rules (1.2.x, satisfying `~> 1.1`) and igniter (0.8.x, satisfying `~> 0.6`) as `only: [:dev]` deps, and `mix compile --warnings-as-errors` exits 0 afterwards."
    - "`mix rules.sync` regenerates ONLY the region between AGENTS.md's `<!-- usage-rules-start -->` and `<!-- usage-rules-end -->` markers, driven by the `:usage_rules` key in mix.exs `project/0`."
    - "AGENTS.md lines 1-95 (the hand-written policy preamble: Project guidelines, TDD Loop, mix quality Alias, Manual Merge Gate, Non-Goals, Phoenix v1.8 / JS-CSS / UI-UX guidelines) are byte-identical before and after the sync — sha256 `44d022191910bfe0d29e9da21cd5534da9c8109258dd38fd6eebe2e16c9a4177`."
    - "Dependency rules appear in AGENTS.md as links to on-disk `deps/<pkg>/usage-rules*.md` paths, not as inlined prose; only usage_rules' own rules and the `:elixir`/`:otp` builtins are inlined."
    - "`mix rules.sync` is idempotent: a second consecutive run leaves AGENTS.md byte-identical."
    - "Every line the sync removed from AGENTS.md is byte-recoverable from a file that still exists under `deps/`."
    - "No file outside {mix.exs, mix.lock, AGENTS.md} gains a new git modification — specifically `.claude/CLAUDE.md`, `.claude/skills/`, `lib/`, `test/`, `priv/` are untouched, and no root `CLAUDE.md` is created."
  artifacts:
    - "mix.exs — two new dev-only deps, a `usage_rules/0` private config function wired into `project/0`, and a `rules.sync` alias"
    - "mix.lock — usage_rules, igniter and their transitive deps pinned with checksums"
    - "AGENTS.md — marker block regenerated in link mode; preamble untouched"
  key_links:
    - "mix.exs `project/0` `:usage_rules` key -> read by `mix usage_rules.sync` (v1.x is config-driven; the task takes no CLI arguments and treats config as the source of truth)"
    - "`file: \"AGENTS.md\"` -> without it the sync writes to its own default target (`CLAUDE.md`) instead of AGENTS.md"
    - "AGENTS.md marker pair (currently lines 96 and 498) -> the ONLY region sync may rewrite; everything above line 96 is out of bounds"
    - "each emitted link -> a real `deps/<pkg>/usage-rules.md` or `deps/<pkg>/usage-rules/<sub>.md` path that must exist on disk, or agents follow a dead link"
    - "absence of a `skills:` sub-key in the config -> prevents the sync from writing into `.claude/skills/`, which holds 3 hand-written project skills"
---

<objective>
Add `usage_rules` and `igniter` as dev-only dependencies and wire dependency usage-rules syncing into
the EXISTING hand-written AGENTS.md, in LINK mode so dependency rules stay out of the context budget.

Purpose: give agents on-demand access to every dependency's own usage rules without inlining tens of
kilobytes into AGENTS.md, and make the wiring re-runnable (`mix rules.sync`) as deps change.

Output: modified `mix.exs` (deps + `:usage_rules` config + `rules.sync` alias), updated `mix.lock`,
and a regenerated AGENTS.md marker block with the hand-written preamble provably intact.

Requirement traceability: QT-MHL-01 (deps) / QT-MHL-02 (config-driven, correct target file) /
QT-MHL-03 (link not inline) / QT-MHL-04 (`rules.sync` alias) / QT-MHL-05 (preamble integrity).
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@mix.exs
@AGENTS.md
</context>

<established_facts>
These were verified during planning against the working tree. Trust them; do not re-derive.

**AGENTS.md is ALREADY a usage_rules-managed file.** `mix phx.new` seeded it with a
`<!-- usage-rules-start -->` / `<!-- usage-rules-end -->` block. Current state:

| Region | Lines | Bytes | Nature |
|--------|-------|-------|--------|
| Preamble | 1-95 | 5,924 | **PROTECTED.** Hand-written project policy + phx.new project guidelines. sha256 `44d022191910bfe0d29e9da21cd5534da9c8109258dd38fd6eebe2e16c9a4177` |
| Marker block | 96-498 | 19,568 | **MACHINE-MANAGED.** 5 inlined phoenix sub-rules, delimited by `<!-- phoenix:elixir-start -->` … `<!-- phoenix:liveview-end -->` |
| Whole file | 498 | 25,492 | sha256 `ff5271483a43496ca42bd16a4d23af6902bebf5e3979bf2ba65565663034d300` (last line has no trailing newline) |

**Consequence you must accept and report, not fight:** the request asks for LINK mode. The 19,568
bytes currently inlined inside the marker block are verbatim copies of
`deps/phoenix/usage-rules/{elixir,phoenix,ecto,html,liveview}.md`. Link mode will collapse them into
a handful of link lines. **The expected `git diff --stat AGENTS.md` byte delta is therefore strongly
NEGATIVE (roughly -19KB), not positive.** That is the requested outcome, not a regression — but it is
the opposite of what "usage_rules appends" implies, so Task 3 must state it plainly. Task 2 proves
mechanically that every removed line is still recoverable from `deps/`.

**Package legitimacy (hex registry, checked during planning):** both packages are published by
ash-project (Zach Daniel), MIT-licensed, with long release histories and live GitHub repos.
`~> 1.1` resolves usage_rules to 1.2.7; `~> 0.6` resolves igniter to 0.8.3. Use the version
constraints exactly as specified in the request — do not "helpfully" tighten them to `~> 1.2` / `~> 0.8`.

**usage_rules v1.x API shape (from its docs — treat as a HYPOTHESIS to confirm against the installed
package in Task 1, not as gospel):** v1 replaced the v0.x CLI flags (`--all`, `--link-to-folder`,
`--link-style`) with a `:usage_rules` keyword list in `project/0`. `mix usage_rules.sync` takes no
arguments. Known keys: `file:` (output path), `usage_rules:` (`:all` or a list of atoms / `"pkg:sub"`
strings / regexes, where an entry may be wrapped as `{entry, link: :markdown | :at}` to link instead
of inline), and `skills:` (**do not use** — see below). Config is the source of truth: packages
present in the file but absent from config are removed on each sync.

**`skills:` is forbidden in this task.** usage_rules v1.2 can generate agent skills into
`.claude/skills`, which already contains 3 hand-written project skills
(`ui-design-system`, `ux-patterns`, `ux-responsive`). Omit the `skills:` key entirely.

**Only `phoenix` currently ships usage rules** — as a `deps/phoenix/usage-rules/` DIRECTORY of 5
sub-rule files, not a flat `usage-rules.md`. No other current dep ships any. After `deps.get`,
`usage_rules` and possibly `igniter` will add their own; enumerate for real in Task 1.

**Styler is a `mix format` plugin** (`.formatter.exs` line 4), so it rewrites `mix.exs` on format.
Format `mix.exs` and review the rewrite rather than letting CI catch it.

**`/deps/` is gitignored** (`.gitignore` line 8), so link targets point at untracked paths.
</established_facts>

<constraints>
- Touch ONLY `mix.exs`, `mix.lock`, `AGENTS.md`. No changes under `lib/`, `test/`, `priv/`,
  `.claude/`, or `config/`.
- Do NOT modify `.claude/CLAUDE.md`. Do NOT create a root `CLAUDE.md`.
- MERGE into the existing `setup` / `precommit` / `quality` aliases and the existing deps list —
  never replace them.
- Do NOT run `mix quality` — it surfaces unrelated pre-existing findings and is out of scope.
- `mix compile --warnings-as-errors` must pass before the task is done.
- STOP after the Task 3 report. Do not continue into unrelated cleanup.
</constraints>

<tasks>

<task type="tracer">
  <name>Task 1: Wire usage_rules end-to-end — deps, config, alias, one real sync</name>
  <precondition>Network access to hex.pm is available (`mix deps.get` must reach the registry). If it fails, halt and report rather than vendoring or pinning around it.</precondition>
  <files>mix.exs, mix.lock, AGENTS.md</files>
  <reversibility rating="reversible">AGENTS.md, mix.exs and mix.lock are all git-tracked; the entire task is undone by `git checkout -- mix.exs mix.lock AGENTS.md`.</reversibility>
  <read_first>
    After `mix deps.get` completes, read the INSTALLED package before writing any config:
    - `deps/usage_rules/README.md`
    - `deps/usage_rules/lib/mix/tasks/usage_rules.sync.ex` (its `@moduledoc` and option parsing)
    - `deps/usage_rules/CHANGELOG.md` (skim for the v0.x -> v1.x config migration)
    The installed source is authoritative. Where it contradicts the hypothesis in
    `<established_facts>`, follow the installed source and note the divergence in the SUMMARY.
  </read_first>
  <action>
    Capture baselines first, into throwaway scratch files under `${TMPDIR:-/tmp}`:
    `git status --porcelain > ${TMPDIR:-/tmp}/mhl-git-before.txt` and
    `cp AGENTS.md ${TMPDIR:-/tmp}/mhl-agents-before.md`.

    Per QT-MHL-01, append to the `deps/0` list in mix.exs, verbatim, keeping the existing entries and
    their order untouched:
    `{:usage_rules, "~> 1.1", only: [:dev]},` and `{:igniter, "~> 0.6", only: [:dev]},`.
    Place them near the other tooling deps (credo / sobelow / styler / mix_audit / tidewave). Run
    `mix deps.get`.

    Now do the `<read_first>` reading. Then enumerate what actually shipped:
    `find deps -maxdepth 2 \( -name 'usage-rules.md' -o -name 'usage-rules' -type d \)`. Record the
    result — Task 3 reports it.

    Per QT-MHL-02, add a private `usage_rules/0` function to mix.exs returning the config keyword
    list, and wire it into `project/0` as `usage_rules: usage_rules()`. It MUST set
    `file: "AGENTS.md"` — the package's own default target is a different filename, and getting this
    wrong writes a brand-new file at the repo root.

    Per QT-MHL-03, the `usage_rules:` list inlines EXACTLY three things — usage_rules' own rules and
    the two builtins (`:usage_rules`, `:elixir`, `:otp`) — and every dependency entry is wrapped in
    the installed version's link form so its rules resolve to an on-disk `deps/` path read on demand.
    Prefer a catch-all (a regex or `:all`-style entry carrying the link option) so future deps are
    picked up automatically without another mix.exs edit; if the installed version does not support
    attaching a link option to a catch-all, fall back to enumerating the packages found above, and
    say so in the SUMMARY. Do NOT add a `skills:` key.

    Per QT-MHL-04, add `"rules.sync": ["usage_rules.sync"]` to the existing `aliases/0` list
    (merge — the list already holds setup / ecto.setup / ecto.reset / test / assets.* / precommit /
    quality, all of which stay). Leave `cli/0`'s `preferred_envs` alone.

    Run `mix format mix.exs` (Styler runs as a format plugin and will rewrite it), then review the
    rewrite with `git diff mix.exs` before continuing — per the project's standing rule, never accept
    a Styler rewrite on trust.

    Run `mix rules.sync`, then run `mix rules.sync` a SECOND time to prove idempotence. Finally run
    `mix compile --warnings-as-errors`.

    If the sync alters anything above AGENTS.md line 96, stop immediately, restore with
    `git checkout -- AGENTS.md`, and report the config that caused it — do not attempt to hand-patch
    the file back into shape.
  </action>
  <verify>
    <automated>
    set -e
    # QT-MHL-01: both deps resolved, dev-only
    mix deps | grep -E 'usage_rules|igniter'
    # QT-MHL-05 HARD GATE: preamble byte-identical
    test "$(head -95 AGENTS.md | sha256sum | cut -d' ' -f1)" = "44d022191910bfe0d29e9da21cd5534da9c8109258dd38fd6eebe2e16c9a4177"
    # markers still present and still bracket the tail of the file
    grep -q '<!-- usage-rules-start -->' AGENTS.md && grep -q '<!-- usage-rules-end -->' AGENTS.md
    # QT-MHL-03: marker block is links, not 19.5KB of inlined prose
    test "$(tail -n +96 AGENTS.md | wc -c)" -lt 8000
    # QT-MHL-02: sync did not create a root CLAUDE.md
    test ! -f CLAUDE.md
    # idempotence: second run left the file untouched
    cp AGENTS.md "${TMPDIR:-/tmp}/mhl-agents-run1.md"; mix rules.sync; diff -q AGENTS.md "${TMPDIR:-/tmp}/mhl-agents-run1.md"
    # every emitted deps/ link target exists on disk
    grep -oE 'deps/[A-Za-z0-9_./-]+\.md' AGENTS.md | sort -u | while read -r p; do test -f "$p" || { echo "DEAD LINK: $p"; exit 1; }; done
    # build gate
    mix compile --warnings-as-errors
    </automated>
  </verify>
  <done>Both deps resolve dev-only at the exact requested constraints; `mix rules.sync` exists, runs, is idempotent, and emits only live `deps/` link targets; AGENTS.md lines 1-95 hash-match the recorded preamble sha256; no root CLAUDE.md exists; `mix compile --warnings-as-errors` exits 0.</done>
</task>

<task type="auto">
  <name>Task 2: Prove nothing was lost — integrity and recoverability audit</name>
  <files>AGENTS.md (read-only), mix.exs (read-only)</files>
  <action>
    This task writes no source files. It produces the evidence Task 3 reports, per QT-MHL-05.

    **Deletion accounting.** Extract every line the sync removed and prove each one still lives on
    disk under `deps/`:
    `git diff -U0 -- AGENTS.md | grep '^-' | grep -v '^---' | sed 's/^-//' > ${TMPDIR:-/tmp}/mhl-removed.txt`
    then concatenate the on-disk rule sources it should have come from
    (`cat deps/*/usage-rules.md deps/*/usage-rules/*.md > ${TMPDIR:-/tmp}/mhl-depsrules.txt`, tolerating
    missing globs). For each removed line that is neither blank nor an HTML marker comment, confirm it
    appears in the concatenated dep sources. Count the unaccounted-for lines — the count must be 0.
    Any nonzero count means real content was destroyed: restore AGENTS.md from git and stop.

    **Scope containment.** Diff `git status --porcelain` against
    `${TMPDIR:-/tmp}/mhl-git-before.txt`. The only NEW entries may be `mix.exs`, `mix.lock`,
    `AGENTS.md`, and files under `.planning/quick/260818-mhl-*`. Pre-existing dirty entries
    (`config/dev.exs`, `config/runtime.exs`, `.planning/**`, untracked `.gsd/`) were already dirty
    before this task and must be unchanged, not newly touched.

    **Format sanity.** Run `mix format --check-formatted mix.exs`. This is a single-file formatting
    check, NOT `mix quality` — do not expand it.

    Record for Task 3: the `git diff --stat AGENTS.md` line, the new AGENTS.md byte size, the
    unaccounted-line count, and the list of deps that shipped usage rules.
  </action>
  <verify>
    <automated>
    set -e
    # recoverability: zero removed lines are unaccounted for
    git diff -U0 -- AGENTS.md | grep '^-' | grep -v '^---' | sed 's/^-//' > "${TMPDIR:-/tmp}/mhl-removed.txt"
    cat deps/*/usage-rules.md deps/*/usage-rules/*.md 2>/dev/null > "${TMPDIR:-/tmp}/mhl-depsrules.txt" || true
    UNACCOUNTED=$(grep -v '^[[:space:]]*$' "${TMPDIR:-/tmp}/mhl-removed.txt" | grep -v '^<!--' | while IFS= read -r l; do grep -qxF "$l" "${TMPDIR:-/tmp}/mhl-depsrules.txt" || echo "$l"; done | wc -l)
    test "$UNACCOUNTED" -eq 0
    # scope containment: .claude/ and source trees untouched by this task
    test -z "$(git status --porcelain -- .claude/ lib/ test/ priv/)"
    test -d .claude/skills/ui-design-system && test -d .claude/skills/ux-patterns && test -d .claude/skills/ux-responsive
    # only the three intended files are newly modified
    git status --porcelain -- mix.exs mix.lock AGENTS.md | wc -l | grep -qx '3'
    # formatting (single file — NOT mix quality)
    mix format --check-formatted mix.exs
    </automated>
  </verify>
  <done>Zero removed AGENTS.md lines are unaccounted for against on-disk `deps/` rule sources; `.claude/`, `lib/`, `test/`, `priv/` carry no new modifications; all 3 hand-written project skills still present; exactly `mix.exs`, `mix.lock`, `AGENTS.md` are modified; `mix.exs` is Styler-formatted.</done>
</task>

<task type="auto">
  <name>Task 3: Report the four requested facts, then stop</name>
  <files>(none — report only)</files>
  <action>
    Emit the report the request asked for, using the evidence Task 2 gathered. Four items, no padding:

    1. `git diff --stat AGENTS.md` — the literal output, followed by one sentence flagging that the
       delta is negative because link mode replaced the previously-inlined phoenix rules, and that
       every removed line was verified recoverable from `deps/` (Task 2's zero-unaccounted result).
    2. The deps that actually shipped usage rules and were picked up, as a list with their on-disk
       paths (flat `usage-rules.md` vs a `usage-rules/` sub-rule directory) — plus which of them were
       linked vs inlined.
    3. The new AGENTS.md file size in bytes, against the 25,492-byte starting size.
    4. Explicit confirmation that no pre-existing AGENTS.md content was lost: cite the preamble
       sha256 match (`44d0221919…`) and the zero-unaccounted-lines count as the two pieces of
       evidence, and state the preamble sections that survived by name.

    Also flag two operational notes for the developer, briefly:
    - link targets live under gitignored `deps/`, so the rules are unreadable on a fresh clone until
      `mix deps.get` runs;
    - dependency-authored markdown now enters agent context via those links without passing through
      git review (threat T-QT-02 below).

    Then STOP. Do not run `mix quality`, do not touch unrelated files, do not start follow-up work.
  </action>
  <verify>
    <automated>test -f AGENTS.md && stat -c%s AGENTS.md && git diff --stat -- AGENTS.md mix.exs mix.lock</automated>
    <human-check>Developer reads the 4-item report and confirms the negative AGENTS.md byte delta is the intended link-mode outcome, not a regression.</human-check>
  </verify>
  <done>All four requested facts reported with real command output, the negative byte delta is explained rather than buried, and execution stops.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| hex.pm registry -> local build | Two new packages and their transitive deps enter the build |
| `deps/**/usage-rules*.md` -> agent context | Dependency-authored markdown is read as instructions by agents, via links |
| `mix usage_rules.sync` -> AGENTS.md | A generator writes into a file holding hand-written project policy |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-QT-01 | Tampering | `usage_rules` / `igniter` from hex.pm | high | mitigate | Both verified against the hex registry during planning (ash-project, MIT, live GitHub repos, long release history). `mix.lock` pins checksums; the existing `mix quality` alias already gates `hex.audit` + `deps.audit` on every future run. Dev-only (`only: [:dev]`) so neither ships in the production release. |
| T-QT-02 | Tampering / Elevation of Privilege | dep-authored markdown reaching agent context through `deps/` links | medium | accept | Link mode moves rule text out of git-reviewable AGENTS.md into gitignored `deps/`, so a compromised dep's instructions would bypass diff review. Accepted because the same trust is already extended by compiling the dep, and the targets are read-only markdown. Task 3 flags this explicitly to the developer. |
| T-QT-03 | Tampering | `mix usage_rules.sync` overwriting AGENTS.md policy | high | mitigate | sha256 hard gate on lines 1-95 in Task 1 `<verify>`; per-line recoverability audit in Task 2; AGENTS.md is git-tracked so any loss is `git checkout -- AGENTS.md`. |
| T-QT-04 | Tampering | `skills:` config writing into `.claude/skills/` | medium | mitigate | `skills:` key omitted entirely from the config; Task 2 asserts all 3 hand-written skill directories still exist and `.claude/` has no new git modifications. |
| T-QT-SC | Tampering | hex package installs | high | mitigate | The npm/pip/cargo package-legitimacy checkpoint does not apply (hex ecosystem); registry provenance verified during planning and recorded under T-QT-01. |
</threat_model>

<verification>
1. `mix deps | grep -E 'usage_rules|igniter'` shows both at the requested constraints, dev-only.
2. `head -95 AGENTS.md | sha256sum` equals `44d022191910bfe0d29e9da21cd5534da9c8109258dd38fd6eebe2e16c9a4177`.
3. `mix rules.sync` run twice leaves AGENTS.md byte-identical between runs.
4. Marker-block size is under 8,000 bytes (links, not inlined prose).
5. Every `deps/...md` link target in AGENTS.md exists on disk.
6. Zero removed AGENTS.md lines are unaccounted for against on-disk dep rule sources.
7. `git status --porcelain` shows exactly `mix.exs`, `mix.lock`, `AGENTS.md` newly modified; `.claude/`, `lib/`, `test/`, `priv/` clean; no root `CLAUDE.md`.
8. `mix compile --warnings-as-errors` exits 0. `mix quality` was NOT run.
</verification>

<success_criteria>
- QT-MHL-01: `{:usage_rules, "~> 1.1", only: [:dev]}` and `{:igniter, "~> 0.6", only: [:dev]}` in `deps/0`, resolved in `mix.lock`.
- QT-MHL-02: `project/0` carries `usage_rules: usage_rules()` with `file: "AGENTS.md"`; no root `CLAUDE.md` created; `.claude/CLAUDE.md` untouched.
- QT-MHL-03: only `:usage_rules`, `:elixir`, `:otp` inlined; all dependency rules emitted as live `deps/` links; marker block under 8KB.
- QT-MHL-04: `mix rules.sync` exists alongside the preserved `setup`/`precommit`/`quality` aliases and is idempotent.
- QT-MHL-05: preamble sha256 matches and zero removed lines are unaccounted for.
- The 4-item report is delivered and execution stops.
</success_criteria>

<output>
Create `.planning/quick/260818-mhl-add-igniter-and-usage-rules-as-dev-only-/260818-mhl-SUMMARY.md` when done.
</output>
</content>
</invoke>
