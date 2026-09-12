---
phase: quick-260912-pnv
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/pukllay_club/catalog/seed/bgg_client.ex
  - test/pukllay_club/catalog/seed/bgg_client_test.exs
  - .planning/WINDOWS.md
autonomous: true

must_haves:
  truths:
    - "BggClient.fetch_batch([], credentials) returns {:ok, []} and never raises"
    - "An empty id list makes zero HTTP requests (proved by a Req.Test stub that reports any call to the test process)"
    - "All pre-existing fetch_batch/2 behaviours are unchanged: non-empty batches still hit BGG, >20 ids still fail the function-clause guard, error/retry tuples unchanged"
    - "WINDOWS.md entry 15 is closed via the `windows fixed` CLI verb if the CLI permits it; if the CLI refuses, the ledger is left byte-identical and the refusal is recorded in SUMMARY"
  artifacts:
    - path: "lib/pukllay_club/catalog/seed/bgg_client.ex"
      provides: "Empty-list fetch_batch/2 clause returning {:ok, []} before any request is built"
      contains: "def fetch_batch([], %Credentials{})"
    - path: "test/pukllay_club/catalog/seed/bgg_client_test.exs"
      provides: "Regression test for WINDOWS #15 asserting {:ok, []} and no request"
      contains: "WINDOWS #15"
  key_links:
    - from: "fetch_batch/2 empty-list clause"
      to: "do_request/3"
      via: "clause ordering — the [] clause must be defined BEFORE the guarded clause so do_request/3 is never reached"
      pattern: "def fetch_batch\\(\\[\\]"
---

<objective>
Fix WINDOWS.md ledger entry #15: `PukllayClub.Catalog.Seed.BggClient.fetch_batch/2`
(lib/pukllay_club/catalog/seed/bgg_client.ex line 33) crashes with `ArgumentError`
(`:erlang.binary_to_integer("")`) when called with an empty `bgg_ids` list, because the
`length(bgg_ids) <= 20` guard admits `[]`, which then builds an `id=""` request and parses a
BGG response that cannot be integer-cast. Add an early `{:ok, []}` return that makes no HTTP
request, pin it with a TDD regression test, then close ledger entry 15 through the
`windows fixed` CLI verb (entry 15 is currently `waived`, so the CLI may refuse — see Task 2).

Purpose: removes a latent crash in seed tooling so any future caller passing `[]` (e.g. a
filtered-to-empty candidate list) gets a graceful empty result, matching the module's own
"this client never raises mid-seed" contract in its moduledoc.
Output: one new function clause + updated @doc, one new ExUnit test, and a ledger closure
attempt with its outcome recorded in SUMMARY.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md
@lib/pukllay_club/catalog/seed/bgg_client.ex
@test/pukllay_club/catalog/seed/bgg_client_test.exs

<interfaces>
Existing contract (bgg_client.ex lines 25-36), unchanged except for the new clause:
- `@spec fetch_batch([integer()], Credentials.t()) :: {:ok, [map()]} | {:error, term()}`
- Current single clause: `def fetch_batch(bgg_ids, %Credentials{} = credentials) when length(bgg_ids) <= @max_batch_size`
- `@max_batch_size 20`; above it, callers get `FunctionClauseError` by design
  (StatsEnricher clamps against `BggClient.max_batch_size/0` for that reason — keep that behaviour).

Test HTTP stubbing (already wired, no new config needed):
- config/test.exs line 55: `config :pukllay_club, :bgg_req_options, plug: {Req.Test, PukllayClub.Catalog.Seed.BggClient}`
- Tests register stubs with `Req.Test.stub(BggClient, fn conn -> ... end)`; the existing retry
  test relies on the stub running in the test process (it uses `Process.get/put`), so a message
  sent to a captured `test_pid` is received by the test process.
- Test module is `use ExUnit.Case, async: true`; `setup` yields `%{credentials: credentials}`
  from `Credentials.fetch()` (token "test-token" in test env).

Windows ledger CLI (verified during planning by reading
~/.claude/gsd-core/bin/lib/broken-windows.cjs): subcommands are `status`, `append`, `waive`,
`fixed` only — there is no reopen verb. `markFixed` calls `assertOpen(entry)`, which throws
reason `windows_already_resolved` ("Window 15 is already waived (resolved_at=...)") for any
entry whose status is not `open`, and throws BEFORE writing the file.
</interfaces>
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: RED/GREEN — empty bgg_ids list returns {:ok, []} with no HTTP request</name>
  <files>test/pukllay_club/catalog/seed/bgg_client_test.exs, lib/pukllay_club/catalog/seed/bgg_client.ex</files>
  <behavior>
    - Test: `BggClient.fetch_batch([], credentials)` returns exactly `{:ok, []}`.
    - Test: no request reaches the Req.Test plug — a stub registered for `BggClient` that sends `{:bgg_request_made, conn.query_string}` to the test pid is never invoked (`refute_received {:bgg_request_made, _}`).
    - Regression guard (existing tests, must stay green): single-id fixture parse, unranked normalization, hostile-DTD error tuple, 401 error tuple, 429 retry, `req_options/0`.
  </behavior>
  <action>
    RED first. In test/pukllay_club/catalog/seed/bgg_client_test.exs, inside the existing
    `describe "fetch_batch/2"` block, add a test named along the lines of
    "returns {:ok, []} for an empty id list without making an HTTP request (WINDOWS #15)" that
    takes `%{credentials: credentials}` like its siblings. Capture `test_pid = self()` before
    registering the stub. Register `Req.Test.stub(BggClient, fn conn -> ... end)` whose body
    first does `send(test_pid, {:bgg_request_made, conn.query_string})` and then responds 200
    with content type "text/xml" and a minimal well-formed empty document `<items></items>`
    (a well-formed body is deliberate: on the current code the call returns without crashing,
    so the RED failure is the precise "a request was made" assertion rather than an incidental
    parse crash). Assert `assert {:ok, []} = BggClient.fetch_batch([], credentials)` followed by
    `refute_received {:bgg_request_made, _}`. Add a one-line comment citing WINDOWS.md entry 15
    (latent crash: `[]` passed the length guard and built an `id=""` request). Run the test file
    and confirm the new test FAILS on the refute (request made) before touching lib/. Commit the
    failing test: `test(quick-260912-pnv): add failing test for empty bgg_ids fetch_batch`.

    GREEN. In lib/pukllay_club/catalog/seed/bgg_client.ex, directly after the existing
    `@spec fetch_batch(...)` line and BEFORE the guarded clause, add a new clause
    `def fetch_batch([], %Credentials{}), do: {:ok, []}`. Keep the `%Credentials{}` pattern so
    passing a non-Credentials second argument still fails the same way as before; do not
    change the existing guarded clause, the `@max_batch_size` cap, or the `@spec` (the return
    type already covers `{:ok, []}`). Extend the existing `@doc` for fetch_batch/2 with one
    sentence stating that an empty id list returns `{:ok, []}` immediately without contacting
    BGG. Re-run the test file — all tests (new + existing) must pass. Run
    `mix format` on both touched files (the formatter includes the Styler plugin — review the
    `git diff` of any Styler rewrite before accepting it, per CLAUDE.md) and
    `mix credo --strict` on both files; fix anything flagged. Commit:
    `fix(quick-260912-pnv): return {:ok, []} from BggClient.fetch_batch/2 on empty id list`.
  </action>
  <verify>
    <automated>mix test test/pukllay_club/catalog/seed/bgg_client_test.exs && mix format --check-formatted lib/pukllay_club/catalog/seed/bgg_client.ex test/pukllay_club/catalog/seed/bgg_client_test.exs && mix credo --strict lib/pukllay_club/catalog/seed/bgg_client.ex test/pukllay_club/catalog/seed/bgg_client_test.exs && grep -q 'def fetch_batch(\[\], %Credentials{})' lib/pukllay_club/catalog/seed/bgg_client.ex</automated>
  </verify>
  <done>
    New test was observed failing before the lib/ change and passes after it; every test in
    bgg_client_test.exs passes; both touched files are format-clean and credo --strict clean;
    `fetch_batch([], creds)` returns `{:ok, []}` with no request reaching the stub; two commits
    exist (failing test, then fix).
  </done>
</task>

<task type="auto">
  <name>Task 2: Close WINDOWS.md entry 15 via the CLI (record refusal instead of hand-editing)</name>
  <files>.planning/WINDOWS.md</files>
  <action>
    Run `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows fixed 15` from the repo root and
    capture its full stdout/stderr and exit code.

    Expected outcome (verified while planning from broken-windows.cjs `markFixed` ->
    `assertOpen`): the CLI REFUSES with reason `windows_already_resolved` because entry 15's
    status is `waived`, and it exits non-zero without writing the file. This refusal is NOT a
    task failure. In that case: leave .planning/WINDOWS.md untouched — do not hand-edit the
    table or JSON block, do not run `windows waive`, and do not `windows append` a duplicate
    entry to mark it fixed (that would fabricate ledger history). Record in SUMMARY.md under a
    "Ledger" heading: the exact command, the exact error text/reason code, that entry 15
    remains `waived` with its existing reason, that the underlying bug is now fixed by Task 1's
    commit (cite its hash), and a follow-up note that the CLI has no reopen/waived->fixed
    transition (only status/append/waive/fixed exist), so flipping it requires either a GSD
    CLI enhancement or an explicit user-approved manual ledger edit.

    If instead the CLI ACCEPTS (a newer gsd-core allows waived->fixed): confirm with
    `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows status` that the ledger parses and
    counts are consistent, record the command output in SUMMARY, and include
    .planning/WINDOWS.md in the docs commit.
  </action>
  <verify>
    <automated>node ~/.claude/gsd-core/bin/gsd-tools.cjs windows status >/dev/null && grep -A6 '"id": 15,' .planning/WINDOWS.md | grep -qE '"status": "(fixed|waived)"'</automated>
  </verify>
  <done>
    `windows fixed 15` was executed exactly once and its outcome captured; the ledger still
    parses via `windows status`; entry 15 is either `fixed` (CLI accepted) or unchanged
    `waived` with the refusal, reason code, and fix commit hash recorded in SUMMARY.md;
    WINDOWS.md was never hand-edited.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| seed tooling -> BGG xmlapi2 | Outbound HTTP to an external API whose XML response is untrusted (existing T-01-08 DTD-disabled parse) |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-260912-pnv-01 | Denial of Service | BggClient.fetch_batch/2 with [] | low | mitigate | New `[]` clause returns `{:ok, []}` before any request is built, removing the `binary_to_integer("")` crash that would abort a `mix catalog.seed`/enrich run |
| T-260912-pnv-02 | Information Disclosure | Bearer token on a pointless `id=""` request | low | mitigate | Same clause — no request (and so no Authorization header) is sent for an empty batch; asserted by the stub-never-called test |
| T-260912-pnv-03 | Repudiation | .planning/WINDOWS.md ledger integrity | low | mitigate | Ledger changed only via the `windows` CLI; refusal recorded in SUMMARY instead of hand-editing or appending a fabricated entry |
</threat_model>

<verification>
- `mix test test/pukllay_club/catalog/seed/bgg_client_test.exs` passes (all 7 tests).
- `mix format --check-formatted` and `mix credo --strict` clean on both touched Elixir files.
- `git log` shows a failing-test commit preceding the fix commit.
- `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows status` succeeds; entry 15 status is `fixed` or unchanged `waived` with the CLI refusal documented in SUMMARY.
</verification>

<success_criteria>
- Calling `BggClient.fetch_batch([], credentials)` returns `{:ok, []}` with zero HTTP requests.
- No regression in existing BggClient behaviour or tests.
- Ledger entry 15 handled strictly through the CLI, with outcome recorded.
</success_criteria>

<output>
Create `.planning/quick/260912-pnv-fix-windows-md-entry-15-bggclient-fetch-batch-2-lib-pukllay/260912-pnv-SUMMARY.md` when done
</output>
