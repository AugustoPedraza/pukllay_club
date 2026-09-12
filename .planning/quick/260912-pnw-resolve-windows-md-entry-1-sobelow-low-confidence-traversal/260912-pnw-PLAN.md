---
phase: quick-260912-pnw
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/pukllay_club/catalog/seed/csv_import.ex
  - lib/pukllay_club/catalog/seed/report.ex
  - .sobelow-conf
  - .planning/WINDOWS.md
autonomous: true

must_haves:
  truths:
    - "`mix sobelow --config --verbose` reports zero findings in lib/pukllay_club/catalog/seed/csv_import.ex and lib/pukllay_club/catalog/seed/report.ex"
    - "The suppression is function-level only: the 3 unrelated low-confidence findings (seo_tags.ex XSS.Raw, catalog_live/index.ex DOS.BinToAtom, seo.ex XSS.Raw) still appear, proving Traversal.FileModule was not ignored project-wide"
    - "Each suppressed function carries a comment naming the reviewed, operator-only source of its path"
    - "config/runtime.exs passes format --check-formatted and core_components.ex has no credo --strict issues"
    - "`mix quality` passes end to end"
    - "WINDOWS.md entry 1 is flipped to fixed via the CLI, or the CLI refusal is recorded verbatim in SUMMARY with WINDOWS.md left untouched"
  artifacts:
    - path: lib/pukllay_club/catalog/seed/csv_import.ex
      provides: "Reviewed function-level Traversal.FileModule skips on stream_rows/1 and header_row/1"
    - path: lib/pukllay_club/catalog/seed/report.ex
      provides: "Reviewed function-level Traversal.FileModule skip on write!/2"
    - path: .sobelow-conf
      provides: "skip: true (honors inline skip annotations) with a reviewed-exception comment block in the existing style"
  key_links:
    - from: .sobelow-conf
      to: "inline sobelow_skip comments in seed/csv_import.ex + seed/report.ex"
      via: "skip: true — sobelow 0.14.1 only rewrites the skip comments into @sobelow_skip attributes when skip is enabled (deps/sobelow/lib/sobelow/parse.ex read_file/1)"
      pattern: "skip: true"
---

<objective>
Resolve WINDOWS.md entry #1 by closing the four low-confidence `Traversal.FileModule` sobelow findings in
the offline seed tooling with the narrowest suppression sobelow supports (function-level inline skip,
scoped to the single `Traversal.FileModule` submodule), after confirming each flagged path is
operator-supplied and not reachable from web input. Confirm the other two parts of entry #1 are
already clean, pass `mix quality`, then flip the ledger entry.

Purpose: entry #1 was waived only to unblock /gsd-ship; this turns the waiver into a real, reviewed fix so
the finding stops reappearing in every `mix quality` run as noise.
Output: two annotated seed modules, an updated `.sobelow-conf`, ledger entry 1 fixed (or refusal recorded).
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md
@.sobelow-conf
@lib/pukllay_club/catalog/seed/csv_import.ex
@lib/pukllay_club/catalog/seed/report.ex
@lib/mix/tasks/catalog.seed.ex

## Planner findings (verified 2026-09-12 against the working tree — do not re-derive, just re-confirm)

Current `mix sobelow --config --verbose` findings (sobelow 0.14.1), all Low Confidence:
- `Traversal.FileModule` `File.stream!` — seed/csv_import.ex:27, function `stream_rows/1` (line 23)
- `Traversal.FileModule` `File.stream!` — seed/csv_import.ex:41, function `header_row/1` (line 39, private)
- `Traversal.FileModule` `File.mkdir_p!` — seed/report.ex:142, function `write!/2` (line 141)
- `Traversal.FileModule` `File.write!` — seed/report.ex:143, function `write!/2` (line 141)
- OUT OF SCOPE (not part of entry #1, do NOT suppress): `XSS.Raw` components/seo_tags.ex:55,
  `DOS.BinToAtom` live/catalog_live/index.ex:228, `XSS.Raw` seo.ex:188

Data-source trace of the flagged paths:
- `CsvImport.stream_rows/1` defaults `path` to `Application.app_dir(:pukllay_club, "priv/repo/seed_data/ludoteca.csv")`.
  Only callers: `lib/mix/tasks/catalog.seed.ex:53` (no argument — default path) and
  `test/pukllay_club/catalog/seed/expansion_classifier_test.exs:71`. `header_row/1` is private and only
  receives the same `path` from `stream_rows/1`.
- `Report.write!/2` callers: `lib/mix/tasks/catalog.seed.ex:61` and `:80`, both with `report_path/0` =
  `Path.join(File.cwd!(), "priv/repo/seed_data/catalog_seed_report.md")` (module-attribute constant), plus
  `test/pukllay_club/catalog/seed/report_test.exs:84` (tmp path).
- No module under `lib/pukllay_club_web/` calls either module (the only `Catalog.Seed` mention there is a
  moduledoc reference to `Seed.Credentials` in csp.ex). Mix tasks are not available inside the release.
  Conclusion: operator-supplied seed tooling input, not web input.

Sobelow skip mechanics (read from deps/sobelow source):
- An inline comment of the exact shape `# sobelow_skip ["Traversal.FileModule"]` placed directly above a
  `def`/`defp` suppresses only that submodule for only that function — BUT only when skip mode is on.
  `.sobelow-conf` currently has `skip: false`, so the comment alone does nothing; `skip` must become `true`.
  Parser regex: one optional space after `#`, a single space before `[`, double-quoted module names.
- `skip: true` also honors a `.sobelow-skips` fingerprint file; none exists and none must be created
  (never run `--mark-skip-all`, which would fingerprint-skip every current finding including the 3 out-of-scope ones).
- Planner dry-ran exactly this change in a scratch copy: the 4 Traversal findings disappeared, the 3
  out-of-scope findings remained, exit status 0.

Entry #1 other parts, checked by planner: `mix format --check-formatted config/runtime.exs` exits 0;
`mix credo --strict lib/pukllay_club_web/components/core_components.ex` reports no issues.

Observation for SUMMARY only (do not change in this plan): `.sobelow-conf` has `exit: true`, which sobelow
0.14.1 maps to no exit threshold (only "low"/"medium"/"high" are recognised), so the `sobelow --config` step
of `mix quality` never fails on findings. Changing that would make `mix quality` fail on the 3 out-of-scope
findings — a separate decision for the user.

Windows CLI: `markFixed` in ~/.claude/gsd-core/bin/lib/broken-windows.cjs calls `assertOpen`, which throws
WINDOWS_ALREADY_RESOLVED for any status other than `open`. Entry 1 is currently `waived`, so the CLI is
expected to refuse; there is no reopen verb.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Re-confirm operator-only path sources, then add function-level Traversal.FileModule skips and enable skip mode</name>
  <files>lib/pukllay_club/catalog/seed/csv_import.ex, lib/pukllay_club/catalog/seed/report.ex, .sobelow-conf</files>
  <read_first>lib/pukllay_club/catalog/seed/csv_import.ex, lib/pukllay_club/catalog/seed/report.ex, lib/mix/tasks/catalog.seed.ex, .sobelow-conf</read_first>
  <action>
Step A — reachability gate (must run before any edit). Run `grep -rn "CsvImport\|Seed.Report\|Seed\.{" lib test` and
`grep -rn "Catalog.Seed" lib/pukllay_club_web`. Confirm the callers match the trace in the context section:
only `lib/mix/tasks/catalog.seed.ex` and tests call `CsvImport.stream_rows` / `Report.write!`, and nothing in
`lib/pukllay_club_web/` (LiveViews, controllers, components, plugs) calls them or passes them a value derived
from params, socket assigns, conn, or uploads. If ANY web-reachable caller exists, STOP: do not add a skip,
do not edit `.sobelow-conf`, and report the caller and its data flow in SUMMARY as a real finding instead.

Step B — csv_import.ex. Directly above `def stream_rows(path \\ default_path()) do` (i.e. after its existing
`@doc` heredoc, which stays unchanged) add a short reviewed comment followed by the exact skip line
`# sobelow_skip ["Traversal.FileModule"]` as the last line before the `def`. The reviewed comment must state:
reviewed 2026-09-12 for WINDOWS #1; `path` is operator-supplied seed tooling input, defaulting to the compiled
priv/repo/seed_data/ludoteca.csv; only callers are `mix catalog.seed` and tests; no PukllayClubWeb module
reaches it and Mix tasks do not ship in the release; any future caller passing a user-derived path must drop
this skip. Do the same directly above `defp header_row(path) do` with a one-to-two-line comment noting it only
receives the already-reviewed `path` from `stream_rows/1`. Keep the skip scoped to the `Traversal.FileModule`
submodule — not the broader `Traversal` family — so any other traversal check (e.g. SendFile) would still fire.

Step C — report.ex. Directly above `def write!(%__MODULE__{} = report, path) do` (after the existing `@doc` and
`@spec`, which stay unchanged) add the same style of reviewed comment plus the exact skip line: `path` comes
from `mix catalog.seed`'s `report_path/0` (File.cwd! joined with the constant
priv/repo/seed_data/catalog_seed_report.md) or a test tmp path; never web input. One skip covers both the
`File.mkdir_p!` and `File.write!` findings since both live in `write!/2`.

Do not change any function body, signature, @doc, or @spec. Do not write the skip-comment literal anywhere
else in these files (the explanatory prose should describe it in words), so each file has exactly one skip
line per suppressed function.

Step D — .sobelow-conf. Change `skip: false` to `skip: true`. Immediately above that line, add a comment block
in the existing style of the `Config.CSP` block (reviewed-exception rationale, file references, date):
explain that `skip: true` makes sobelow honor function-level inline skip annotations (and a skips-fingerprint
file, which this project deliberately does not have); list the three annotated functions
(`CsvImport.stream_rows/1`, `CsvImport.header_row/1`, `Report.write!/2`) and that they cover the
`Traversal.FileModule` findings from WINDOWS #1; state why a function-level skip was chosen over adding the
check to the project-wide ignore list (a global ignore would hide future web-reachable traversal bugs);
"Reviewed 2026-09-12." Leave the existing `ignore: ["Config.CSP"]` line and every other key untouched
(including `exit: true` and `threshold: :low`).

Do not create a `.sobelow-skips` file and do not run sobelow with `--mark-skip-all`. Do not touch
bgg_client.ex or filter_modal.ex (sibling batch items). Do not suppress the 3 out-of-scope findings.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && test "$(mix sobelow --config --verbose 2>&1 | grep -cE '^File: lib/pukllay_club/catalog/seed/(csv_import|report)\.ex')" = "0" && test "$(mix sobelow --config 2>&1 | grep -c 'Low Confidence')" = "3" && test "$(grep -c 'sobelow_skip \["Traversal.FileModule"\]' lib/pukllay_club/catalog/seed/csv_import.ex)" = "2" && test "$(grep -c 'sobelow_skip \["Traversal.FileModule"\]' lib/pukllay_club/catalog/seed/report.ex)" = "1" && grep -q '^  skip: true,$' .sobelow-conf && grep -q 'ignore: \["Config.CSP"\],' .sobelow-conf && test ! -e .sobelow-skips && mix format --check-formatted && mix test test/pukllay_club/catalog/seed/ --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `mix sobelow --config --verbose` output contains zero `File:` lines for seed/csv_import.ex or seed/report.ex
    - `mix sobelow --config` still prints exactly 3 Low Confidence findings (seo_tags.ex, catalog_live/index.ex, seo.ex) — proves the suppression is function-scoped
    - csv_import.ex contains exactly 2 skip lines, report.ex exactly 1, each preceded by a reviewed-source comment
    - `.sobelow-conf` has `skip: true` with a dated reviewed-exception comment block; `ignore: ["Config.CSP"]` unchanged
    - No `.sobelow-skips` file exists
    - `mix format --check-formatted` passes (Styler did not rewrite anything) and the seed test directory passes
  </acceptance_criteria>
  <done>The four Traversal.FileModule findings are gone via three reviewed, commented, function-level skips; the unrelated findings still surface; seed tests and formatting are green.</done>
</task>

<task type="auto">
  <name>Task 2: Confirm the rest of entry #1 is clean, pass mix quality, and flip WINDOWS entry 1</name>
  <files>.planning/WINDOWS.md</files>
  <read_first>.planning/WINDOWS.md</read_first>
  <action>
Confirm the non-sobelow parts of entry #1: run `mix format --check-formatted config/runtime.exs` (must exit 0)
and `mix credo --strict lib/pukllay_club_web/components/core_components.ex` (must report no issues). If either
regressed since planning, stop and report it in SUMMARY rather than fixing it (it would be out of this plan's
file scope).

Run the full gate `mix quality` from the project root (hex.audit, deps.audit, deps.unlock --check-unused, format,
credo --strict, sobelow --config, test --warnings-as-errors). The test step needs the local test Postgres
running. If a test fails that is unrelated to the three files changed in Task 1 (Task 1 changed comments and a
sobelow config key only, so no runtime behavior changed), do NOT fix it — record the failing test name and
output in SUMMARY and do not proceed to the ledger flip.

Only once `mix quality` passes: run `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows fixed 1` from the project
root. Entry 1 is currently `waived`, and the CLI's markFixed only accepts `open` entries, so it is expected to
refuse with WINDOWS_ALREADY_RESOLVED ("Window 1 is already waived ..."). If it refuses: do NOT hand-edit
.planning/WINDOWS.md (no manual status, count, or JSON-block changes); record the exact command and its full
error output in SUMMARY, note that the CLI has no reopen verb so a waived entry cannot transition to fixed, and
state that the underlying defect is now actually resolved (commit hash of Task 1) so the waiver reason is
superseded. If it succeeds, confirm with `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows list` (or re-reading
the ledger frontmatter) that entry 1 status is fixed and counts were recomputed.

In SUMMARY also record, as observations only (no changes): (a) the 3 remaining out-of-scope low-confidence
sobelow findings with file:line, as candidates for a separate review; (b) `.sobelow-conf`'s `exit: true` is not
a recognised sobelow exit threshold, so the sobelow step of `mix quality` never fails on findings.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && mix format --check-formatted config/runtime.exs && mix credo --strict lib/pukllay_club_web/components/core_components.ex && mix quality</automated>
  </verify>
  <acceptance_criteria>
    - `mix format --check-formatted config/runtime.exs` exits 0 and credo --strict on core_components.ex reports no issues
    - `mix quality` exits 0
    - Either WINDOWS.md entry 1 shows status fixed with a new resolved_at and recomputed counts (written by the CLI), or WINDOWS.md is byte-identical to its pre-task state and SUMMARY quotes the CLI refusal verbatim
    - SUMMARY lists the 3 out-of-scope sobelow findings and the `exit: true` observation
  </acceptance_criteria>
  <done>mix quality passes with entry #1's three sub-issues confirmed clean, and the ledger outcome (CLI flip or recorded refusal) is captured without any hand-edit of WINDOWS.md.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| operator shell -> mix catalog.seed | Seed CSV path and report path are chosen by the developer/operator running a Mix task; not present in the release |
| browser -> PukllayClubWeb | Untrusted input boundary; must not reach File.* calls in Catalog.Seed |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-pnw-01 | Information Disclosure | CsvImport.stream_rows/1, header_row/1 (File.stream!) | low | accept | Path is the compiled priv default or a test fixture; Task 1 Step A re-greps callers and halts if any web-reachable caller exists; skip comment instructs future editors to drop the skip if a user-derived path is ever passed |
| T-pnw-02 | Tampering | Report.write!/2 (File.mkdir_p!, File.write!) | low | accept | Path is a constant under priv/repo/seed_data joined to File.cwd! inside a Mix task, or a test tmp path; same Step A reachability gate |
| T-pnw-03 | Elevation of Privilege | .sobelow-conf skip mode masking future findings | medium | mitigate | Suppression is function-level and scoped to the single Traversal.FileModule submodule (not a project-wide ignore, not a fingerprint skips file); Task 1 verify asserts the 3 unrelated findings still surface and that no skips file exists |
</threat_model>

<verification>
- `mix sobelow --config --verbose` shows no findings for seed/csv_import.ex or seed/report.ex, and still shows the 3 unrelated findings
- `mix quality` passes
- WINDOWS.md entry 1 flipped by the CLI, or refusal recorded verbatim in SUMMARY with WINDOWS.md untouched
</verification>

<success_criteria>
- Every Traversal.FileModule finding from entry #1 is closed by a reviewed, commented, function-level skip whose rationale names the operator-only path source
- No web-reachable file path was suppressed (reachability gate ran first)
- config/runtime.exs formatting and core_components.ex credo confirmed clean
- `mix quality` green; ledger outcome recorded without hand-editing
- bgg_client.ex and filter_modal.ex untouched
</success_criteria>

<output>
Create `/home/apedraza/projects/pukllay_club/.planning/quick/260912-pnw-resolve-windows-md-entry-1-sobelow-low-confidence-traversal/260912-pnw-SUMMARY.md` when done
</output>
