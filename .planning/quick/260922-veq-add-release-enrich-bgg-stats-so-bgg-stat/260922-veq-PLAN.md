---
phase: quick-260922-veq
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/pukllay_club/release.ex
  - lib/pukllay_club/catalog/seed/stats_audit.ex
  - test/pukllay_club/release_test.exs
  - test/pukllay_club/catalog/seed/stats_audit_test.exs
  - docs/runbooks/production-bgg-reenrichment.md
  - AGENTS.md
autonomous: true
requirements: [QUICK-260922-VEQ-01]
user_setup: []

estimate:
  tokens: 35000
  raw_tokens: 35000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "An operator can run the BGG stats re-enrichment on the live production node with no Mix present, via `bin/pukllay_club rpc 'PukllayClub.Release.enrich_bgg_stats()'`"
    - "A `dry_run: true` invocation fetches from BGG, reports counters, and writes nothing to the database"
    - "The run summary survives the container: it is printed as one JSON line to the operator's stdout AND emitted via Logger — no file is written under priv/"
    - "An `eval` invocation refuses to run with an actionable error rather than half-running with no HTTP pool"
    - "No raw credential value appears in anything either release function prints or logs"
    - "A production BEFORE/AFTER publisher-and-artist distribution can be captured as two structurally comparable JSON snapshots"
    - "The measurement is falsifiable: it fails its own test suite if it cannot see a deliberately seeded duplicate entry"
  artifacts:
    - lib/pukllay_club/release.ex
    - lib/pukllay_club/catalog/seed/stats_audit.ex
    - test/pukllay_club/release_test.exs
    - test/pukllay_club/catalog/seed/stats_audit_test.exs
    - docs/runbooks/production-bgg-reenrichment.md
  key_links:
    - "Release.enrich_bgg_stats/1 -> StatsEnricher.enrich_from_bgg/2 (the exact code path the dev fix was verified against — no second implementation)"
    - "Release.enrich_bgg_stats/1 -> Credentials.fetch!/0 -> BGG_API_TOKEN from Kamal env.secret (config/deploy.yml)"
    - "Release.bgg_stats_report/0 -> Catalog.Seed.StatsAudit.report/0"
    - "ensure_live_node!/1 -> registered process names PukllayClub.Repo and Req.Finch"
---

<objective>
Add two release-callable entry points so the already-deployed BGG xpath fix can finally be
applied to production's ~400 contaminated rows, and so the repair can be **proved** to have
worked.

Purpose: quick task 260922-tum fixed `BggClient.parse_items/1`'s `.//` -> `./` scoping and
re-enriched the dev catalog. That fix is live in production (merged a160e22 / PR #65), so
production parses correctly *going forward* — but every existing production row still carries
folded-in `boardgameversion` publishers/artists. Dev repaired via `mix catalog.enrich_bgg_stats`,
and Mix does not exist in a compiled Mix release, so production currently has no way to invoke
the repair at all.

Output: `PukllayClub.Release.enrich_bgg_stats/1` (the repair vehicle),
`PukllayClub.Release.bgg_stats_report/0` + `PukllayClub.Catalog.Seed.StatsAudit.report/0`
(the read-only before/after measurement), tests for all three, and a runbook holding the exact
commands the operator will run later.

**THIS PLAN SHIPS CODE AND DOCS ONLY.** No task in this plan connects to, reads from, or writes
to the production host or the production database. The dry run, the live repair run and the
re-measurement are a separate, human-authorized step that happens after this plan merges and
deploys.

## Grounding: four facts verified at planning time

These were checked directly against this repo's `deps/` and against a live local Elixir 1.19.5
probe. They are load-bearing — do not re-derive them, but do not contradict them either.

**F1. `rpc` does NOT print the expression's return value.**
`Kernel.CLI.process_command({:rpc_eval, node, expr})` (elixir 1.19.5,
`lib/elixir/lib/kernel/cli.ex` ~line 429) calls `:erpc.call(node, Kernel.CLI, :rpc_eval, [expr])`
and then matches only `:ok -> :ok` or a raise. The evaluated term is discarded.
**Consequence:** a function meant to be read by an operator over `rpc` must print its own output.
Returning a map is not enough.

**F2. Remote `IO.puts` DOES reach the caller's stdout.**
Verified live with a two-node probe (`elixir --sname target --no-halt` +
`elixir --sname client --rpc-eval target@host 'IO.puts("..."); :done'`): the string appeared on
the caller's stdout, and `:done` did not (confirming F1 in the same run).
**Consequence:** `IO.puts` of a single JSON line is a working, redirectable capture channel.

**F3. `:erpc.call/4` has no caller-side timeout.**
The 4-arity form defaults to `:infinity`. A ~60-90s enrichment run will not be cut off at the
rpc layer.

**F4. `Ecto.Migrator.with_repo/2` is wrong for a live node.**
`deps/ecto_sql/lib/ecto/migrator.ex`: `ensure_repo_started/2` (~line 816) returns `{:ok, :restart}`
when `repo.start_link/1` answers `{:error, {:already_started, _pid}}` — which is exactly the case
on a running production node. The `after` block then runs `after_action(repo, :restart)` (~line
846), which reaches into `Ecto.Adapter.lookup_meta(repo)` and calls `Supervisor.restart_child/2`
against the live connection pool. That teardown branch exists to clean up a repo *the caller
started*; under `rpc` this call started nothing.
**Consequence:** `create_owner/1`'s `with_repo` wrapper must NOT be copied onto either new
function. The correct replacement is an explicit liveness assertion (Task 1).

## Why `eval` cannot work here, restated precisely

`StatsEnricher.enrich_from_bgg/2` -> `BggClient.fetch_batch/2` -> `Req.get/2`, and Req's HTTP pool
is `Req.Finch`, started by `Req.Application`'s own supervisor (`deps/req/lib/req/application.ex`).
An `eval` node starts no supervision tree, so `Req.Finch` does not exist there. `with_repo/2`
would start only the Repo — making the run *look* viable right up until the first BGG request.
The failure mode is therefore a half-run, not a clean refusal. Task 1 turns it into a clean
refusal.

## Where the durable record lives (decision)

The dev Mix task writes `priv/repo/seed_data/bgg_stats_enrichment_report.md`. In a release, `priv/`
lives inside the container and is discarded on the next deploy, so that record would silently
vanish. **Neither new function writes any file.** The record lives in three places instead:

1. **Primary — the operator's machine.** Both functions print exactly one JSON line to stdout
   (F2), so `... > snapshot.json` captures it. The runbook commits `prod-bgg-stats-before.json`
   and `prod-bgg-stats-after.json` into this quick task's own directory, mirroring the
   `01.8.1-prod-baseline.json` discipline CLAUDE.md documents.
2. **Secondary — the container logs.** Both also emit the same payload via `Logger.info`, so
   `kamal app logs` carries it even if the operator's terminal is lost.
3. **Tertiary — Sentry.** `Sentry.LoggerHandler` is attached with `enable_logs: true`
   (`application.ex`), so those Logger entries are forwarded off-host automatically.

## Measurement vehicle: recommendation and justification

**Recommended: a read-only `Release.bgg_stats_report/0` backed by a tested
`Catalog.Seed.StatsAudit.report/0` module. NOT ad-hoc SQL against the Postgres Kamal accessory.**

1. **Falsifiability.** An SQL string pasted into a `docker exec psql` shell is unversioned and
   untested. A subtly wrong `array_length(...)` expression reports "0 duplicate rows" and the
   post-repair reading then proves nothing — the exact unfalsifiable-guard trap this project has
   hit before. A module gets a negative test (a seeded duplicate MUST be reported) that runs in
   `mix quality` forever.
2. **One channel, not two.** The repair already needs `kamal app exec --reuse ... rpc`. Reusing
   that shape for the measurement means no second credential path — no `POSTGRES_PASSWORD`, no
   opening a shell on the DB container, no SSH tunnel.
3. **Comparable artifacts.** It emits JSON, so before/after are two diffable files. `psql` table
   output is eyeballed, which is how a control metric quietly drifts unnoticed.
4. **Safe to ship independently.** `StatsAudit` has no write path whatsoever, so it lands in
   production on the same deploy as the repair function with no added risk.

Cost: one extra module (~60 lines). Accepted.

## Computed in Elixir, not SQL (decision)

`StatsAudit.report/0` loads the ~400 catalog rows and reduces them in Elixir rather than issuing
a hand-written `unnest`/`DISTINCT` SQL statement. This follows the precedent already set in
01.8.1-13 (`BandAudit.mismatches/0` computes entirely in Elixir, "never a second threshold copy in
SQL"), keeps the duplicate rule readable and unit-testable, and keeps the module clear of Sobelow's
raw-query surface. At this row count the cost is irrelevant.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./.claude/CLAUDE.md
@.planning/quick/260922-tum-fix-the-bgg-xpath-bug-and-re-enrich/260922-tum-SUMMARY.md

@lib/pukllay_club/release.ex
@lib/pukllay_club/catalog/seed/stats_enricher.ex
@lib/pukllay_club/catalog/seed/credentials.ex
@lib/mix/tasks/catalog.enrich_bgg_stats.ex
@test/pukllay_club/catalog/seed/stats_enricher_test.exs

## Interface facts the executor needs

- `StatsEnricher.enrich_from_bgg(%Credentials{}, opts)` accepts `:limit`, `:dry_run`,
  `:batch_size` (default 20, clamped to `BggClient.max_batch_size/0`), `:delay_ms` (default 1500).
  Returns `%{candidates:, fetched:, updated:, missing_from_bgg: [bgg_id], unranked: [bgg_id],
  failed_batches: [{ids, reason}]}`.
- **`failed_batches` holds 2-tuples. `Jason.encode!/1` RAISES on a tuple.** If the summary is
  encoded naively, a production run that hits one bad batch will complete all ~400 rows and then
  blow up at the final encode, destroying the only record of the run. Normalize before encoding.
- `Credentials.fetch!/0` resolves env-var-first then Application config. `Credentials.redacted/1`
  returns a plain map with `bgg_api_token`/`r2_access_key_id`/`r2_secret_access_key`/
  `gemini_api_key` replaced by `"[REDACTED]"`.
- Registered process names, both confirmed live via `mix run`: `PukllayClub.Repo` and `Req.Finch`.
- `Game` array columns: `publishers`, `artists`, `mechanics`, `designers` — all
  `{:array, :string}, default: []`. `bgg_id` is `:integer` and nullable.
- Test env already wires `config :pukllay_club, :bgg_req_options, plug: {Req.Test,
  PukllayClub.Catalog.Seed.BggClient}` and `bgg_api_token: "test-token"` (config/test.exs), so
  `Req.Test.stub/2` works and `Credentials.fetch!/0` resolves without any developer secret.
- `PukllayClub.CatalogFixtures.game_fixture/1` takes an attrs map and generates a unique
  `csv_row`; pass array columns directly.
- Existing fixture `test/support/fixtures/bgg_thing_on_mars.xml` (bgg_id 184_267) is the stub
  body already used by `stats_enricher_test.exs`.

## Project conventions that bind this plan

- Verification gate is `mix quality` (hex.audit, deps.audit, deps.unlock --check-unused,
  format --check-formatted, credo --strict, sobelow --config, test --warnings-as-errors).
- **Styler runs inside `mix format` and can change program behaviour** (CLAUDE.md, Development
  Tools). After the first `mix format`, read `git diff` for every Styler-produced rewrite before
  committing — do not accept rewrites on trust.
- `main` is branch-protected: land via a branch + PR, never `git push origin main`.
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Release.enrich_bgg_stats/1 — the repair vehicle, end to end</name>

  <files>lib/pukllay_club/release.ex, test/pukllay_club/release_test.exs</files>

  <read_first>
lib/pukllay_club/release.ex (all of it — `create_owner/1` is the shape precedent, but its
`Ecto.Migrator.with_repo/2` wrapper is deliberately NOT copied here, per F4 in the objective).
lib/pukllay_club/catalog/seed/stats_enricher.ex (the summary map shape, including the
`failed_batches` tuples).
lib/mix/tasks/catalog.enrich_bgg_stats.ex (the dev equivalent — same `Credentials.fetch!/0` +
`redacted/1` + summary-counter shape; the `write_report!/2` half is what this task must NOT port).
  </read_first>

  <behavior>
This is the thinnest slice that touches every layer the task will use — operator entry point ->
liveness guard -> credential resolution -> the existing enricher -> JSON on stdout. Write these
tests first, in `test/pukllay_club/release_test.exs` (`use PukllayClub.DataCase, async: true`;
`import ExUnit.CaptureIO`; `Req.Test.stub(PukllayClub.Catalog.Seed.BggClient, ...)` returning the
on-mars fixture with `content-type: text/xml` and status 200):

- **Live run prints one decodable JSON line.** Insert `game_fixture(%{bgg_id: 184_267,
  bgg_rank: nil})`. `out = capture_io(fn -> Release.enrich_bgg_stats(delay_ms: 0) end)`.
  Assert `Jason.decode!(String.trim(out))` succeeds and carries `"candidates" => 1`,
  `"updated" => 1`, `"dry_run" => false`, `"failed_batches" => []`, and a `"run_at"` string.
  Assert the game reloads with a non-nil `bgg_rank` (the write really happened).
- **Dry run writes nothing and says so.** Same stub. Insert a game with `bgg_rank: nil`.
  `capture_io(fn -> Release.enrich_bgg_stats(dry_run: true, delay_ms: 0) end)`; assert the decoded
  payload has `"dry_run" => true` and `"updated" => 1`, and that the reloaded game's `bgg_rank` is
  still nil.
- **A failed batch is still encodable.** Stub a `403` response (non-retryable — `BggClient` returns
  `{:error, reason}` immediately, so this test does not sit through the 1s/2s 5xx backoff ladder).
  Assert the captured output still `Jason.decode!`s, that `"failed_batches"` is a non-empty list,
  and that its first element is a map whose `"reason"` is a **string** and whose `"ids"` is a list
  of integers. This is the regression guard for the tuple-encoding trap.
- **No raw credential in the output.** Reuse the live-run capture. `refute out =~ "test-token"`
  (the configured test value of `bgg_api_token`). Also capture the Logger output for the same call
  via `ExUnit.CaptureLog.capture_log/1` and `refute log =~ "test-token"`.
- **Nothing is written under priv/.** Before the live-run call, snapshot
  `before = File.read("priv/repo/seed_data/bgg_stats_enrichment_report.md")` (the tuple form, so a
  missing file is handled). After the call, assert `File.read(same_path) == before`.
- **The guard refuses a node that is missing a required process.**
  `assert_raise RuntimeError, ~r/rpc/, fn -> Release.ensure_live_node!([:gsd_no_such_process]) end`
  and assert the message also names `:gsd_no_such_process`.
- **The guard passes on a real node.** `assert Release.ensure_live_node!() == :ok` — this asserts
  the *real* required-process list is satisfiable, so the list can never drift into naming a
  process that is never running.
  </behavior>

  <action>
In `PukllayClub.Release`, add `require Logger` and aliases for
`PukllayClub.Catalog.Seed.Credentials` and `PukllayClub.Catalog.Seed.StatsEnricher` (keep aliases
alphabetically ordered for `credo --strict`).

Add a module attribute listing the process names a live node must have registered: the app Repo
and Req's HTTP pool (`Req.Finch`). Expose it through a `@doc false` zero-arity reader, and add a
`@doc false` `ensure_live_node!/1` taking a list of registered names, defaulting to that reader.
It returns `:ok` when every name resolves via `Process.whereis/1`, and otherwise raises a
`RuntimeError` that (a) names every missing process, (b) states that this entry point must be
invoked through the release's `rpc` command against the running node, and (c) states that the
release's `eval` command starts no supervision tree, so Req's HTTP pool does not exist there and
every BGG request would fail. Taking the name list as an argument is what makes the failure branch
testable without killing a real supervisor.

Add `enrich_bgg_stats/1` taking a keyword list (default `[]`). In order: assert liveness via the
guard; resolve credentials with `Credentials.fetch!/0`; emit one `Logger.info` line naming the run
and carrying `Credentials.redacted(credentials)` — never the struct's raw fields; delegate to
`StatsEnricher.enrich_from_bgg/2`, passing through only `:limit`, `:dry_run`, `:batch_size` and
`:delay_ms` from the caller's options (use `Keyword.take/2` so an unknown key cannot silently
reach the enricher); then publish the result and return the raw summary map.

Publishing means: build a JSON-encodable map from the summary — a UTC ISO8601 run timestamp, the
dry-run boolean as resolved from the options, the three integer counters, the two id lists, and
`failed_batches` **converted from `{ids, reason}` 2-tuples into maps with an id list and an
`inspect/1`-rendered reason string**. Encode it once with `Jason.encode!/1`, then both `IO.puts`
it (so an operator running it over `rpc` captures it — the release `rpc` command discards return
values, so printing is the only way the operator sees anything) and `Logger.info` it (so
`kamal app logs` and Sentry hold a copy). Write no file anywhere.

Do NOT call the existing private `load_app/0` and do NOT wrap any of this in
`Ecto.Migrator.with_repo/2`. Record the reason in the function's `@doc`, citing the concrete
mechanism: on a running node `with_repo/2` takes its already-started branch and then runs a
teardown action against a connection pool this call never started. The `@doc` must also carry the
literal operator invocations for a dry run and a live run, and state the expected ~60-90s duration
for a full ~400-game catalog (about 20 batches of 20 at the enricher's 1500ms default spacing) and
that there is no caller-side rpc timeout to worry about.

The `@doc` must additionally state that this function deliberately carries no `:limit` batching,
offset paging or resumability: the whole catalog fits in one ~90s pass, and the enricher's
candidate query has no offset and orders by id, so a `:limit` "next batch" would re-process the
same head rows.
  </action>

  <verify>
    <automated>mix test test/pukllay_club/release_test.exs</automated>
  </verify>

  <done>
`mix test test/pukllay_club/release_test.exs` is green with all seven behaviors above asserted.
A live call updates the row and prints one JSON line; a dry-run call prints `"dry_run": true` and
leaves the row untouched; a failing batch still produces decodable JSON with a string reason; the
configured BGG token appears in neither stdout nor the log; `priv/repo/seed_data/` is byte-identical
after the call; the guard raises an rpc-naming error for a missing process and returns `:ok`
against the real list.
  </done>

  <reversibility rating="reversible">New function on an existing module; no schema change, no data
  write outside the already-existing enricher path, and nothing runs against production.</reversibility>
</task>

<task type="auto" tdd="true">
  <name>Task 2: StatsAudit.report/0 + Release.bgg_stats_report/0 — the falsifiable measurement</name>

  <files>lib/pukllay_club/catalog/seed/stats_audit.ex, test/pukllay_club/catalog/seed/stats_audit_test.exs, lib/pukllay_club/release.ex, test/pukllay_club/release_test.exs</files>

  <read_first>
lib/pukllay_club/catalog/seed/stats_enricher.ex (module layout, `import Ecto.Query` usage and the
alias block — mirror this file's shape; the new module is its read-only sibling).
lib/pukllay_club/catalog/game.ex lines 20-60 (the four array columns and `bgg_id`).
test/support/fixtures/catalog_fixtures.ex (`game_fixture/1` signature and defaults).
  </read_first>

  <behavior>
Write `test/pukllay_club/catalog/seed/stats_audit_test.exs` first
(`use PukllayClub.DataCase, async: true`, `import PukllayClub.CatalogFixtures`). These four tests
exist specifically so a production reading of "zero rows with duplicates" is falsifiable — without
the second one, that reading would prove nothing.

- **Clean catalog reports real maxima and zero duplicates.** Two games with distinct publisher
  lists of length 3 and 1. Assert `publishers.max == 3` and `publishers.rows_with_duplicates == 0`,
  and that `total_games == 2`.
- **A seeded duplicate IS reported (the negative test).** One game with `publishers:
  ["Devir", "Asmodee", "Devir"]`. Assert `publishers.rows_with_duplicates == 1` and
  `publishers.max == 3` (the raw length, not the deduplicated length — the measurement reports what
  is stored, it does not silently repair it).
- **Columns are not cross-wired.** One game with duplicated `publishers` and clean `mechanics` and
  `designers`. Assert `publishers.rows_with_duplicates == 1` while
  `mechanics.rows_with_duplicates == 0` and `designers.rows_with_duplicates == 0`. This catches the
  copy-paste-the-field-name bug class that would make the control metrics meaningless.
- **Empty and absent arrays are counted as zero, not crashes.** One game with `publishers: []` and
  one with no `bgg_id`. Assert the call returns without raising, `publishers.max == 0`, and
  `games_with_bgg_id` counts only the row that has one.

Then extend `test/pukllay_club/release_test.exs` with one more test: `bgg_stats_report/0` prints a
single decodable JSON line carrying `"total_games"`, `"games_with_bgg_id"`, `"run_at"`, and a
nested object for each of the four array columns, and returns the same data as a map.
  </behavior>

  <action>
Create `PukllayClub.Catalog.Seed.StatsAudit` — a read-only audit of the columns `StatsEnricher`
writes. Its `@moduledoc` must state that it has no write path at all, that it exists so a
production repair run can be proved rather than assumed, and that it is the measurement half of
this quick task's before/after discipline.

`report/0` loads every game in one query, selecting only `id`, `bgg_id` and the four array columns
(`publishers`, `artists`, `mechanics`, `designers`), ordered by id, and reduces them **in Elixir**.
Follow the 01.8.1-13 `BandAudit.mismatches/0` precedent — the duplicate rule is expressed once, in
Elixir, never as a second copy in SQL. Return a map with a UTC ISO8601 `run_at`, the total row
count, the count of rows carrying a `bgg_id`, and one nested stats map per array column.

Each per-column stats map carries: the maximum entry count across all rows, the `id` and `bgg_id`
of the row holding that maximum (so an operator can spot-check the worst case against BGG's raw
XML the way quick task 260922-tum did for bgg_id 432), and the number of rows whose stored entry
count differs from its unique entry count. Treat a nil column as an empty list. Handle an empty
catalog without raising — the maxima are zero and the worst-row identifiers are nil.

Add a `@doc` noting which metrics are the *subject* of the repair (publishers and artists) and
which are *controls* that the repair must leave unchanged (mechanics and designers, plus the total
row count) — the executor should not invent an interpretation; this pairing is what the runbook's
comparison table keys off.

Then add `Release.bgg_stats_report/0`. It asserts liveness through Task 1's guard, but with a
narrower requirement: this one needs only the Repo, not the HTTP pool. Pass the narrow list
explicitly rather than relaxing the guard. It delegates to `StatsAudit.report/0`, encodes once with
`Jason.encode!/1`, `IO.puts`es that line and `Logger.info`s it, and returns the map. Its `@doc`
must carry the literal operator invocation, state that it performs no write of any kind, and state
why it is still `rpc`-only rather than `eval`-capable (an `eval` node has no started Repo, and the
`with_repo/2` wrapper that would start one carries the same live-pool teardown hazard documented on
`enrich_bgg_stats/1`).
  </action>

  <verify>
    <automated>mix test test/pukllay_club/catalog/seed/stats_audit_test.exs test/pukllay_club/release_test.exs</automated>
  </verify>

  <done>
Both test files pass. A catalog with a deliberately seeded duplicate publisher entry is reported as
exactly one row with duplicates while its mechanics and designers report zero, proving the
measurement can actually distinguish contaminated from clean data. `Release.bgg_stats_report/0`
prints one decodable JSON line carrying the four per-column stats objects and returns the same map.
  </done>

  <reversibility rating="reversible">New read-only module plus a new read-only release function.
  No writes, no schema change.</reversibility>
</task>

<task type="auto">
  <name>Task 3: The production runbook — the commands the operator will actually run</name>

  <files>docs/runbooks/production-bgg-reenrichment.md, AGENTS.md</files>

  <read_first>
docs/runbooks/production-secrets.md and docs/runbooks/catalog-seed.md (house style for this
repo's runbooks — headings, command-block conventions, how constraints are stated).
AGENTS.md lines ~135-180 (the catalog data runbook section that ends with the
`bin/pukllay_club eval 'PukllayClub.Release.create_owner(...)'` block — the new pointer goes
immediately after it).
config/deploy.yml (service name `pukllay_club`, host `34.41.63.138`, proxy host `pukllay.club`,
and the `env.secret` list that already carries `BGG_API_TOKEN`).
  </read_first>

  <action>
Write `docs/runbooks/production-bgg-reenrichment.md`. This is the operator-facing half of this
quick task — the plan ships it; a human runs it later. Cover, in order:

**Context.** The `BggClient` scoping fix (quick task 260922-tum) is deployed, so production parses
correctly going forward, but existing rows still carry folded-in `boardgameversion` publishers and
artists. Name the dev outcome as the target shape: worst publisher list fell 178 -> 45, rows with
duplicate entries fell to 0, mechanics max stayed 20 and designers max stayed 7.

**Preconditions.** The fix is live on the deployed image; `BGG_API_TOKEN` is present in Kamal
`env.secret` (it already is, added in 01.8.1-08, and kept in sync by
`test/pukllay_club/deploy_secrets_contract_test.exs`); a recent nightly `pg_dump` exists in R2 and
its date has been confirmed, because that dump is the rollback.

**The one hard rule.** Both functions must be invoked with the release's `rpc` command against the
running node, never with `eval`. Explain the mechanism in one sentence (an `eval` node starts no
supervision tree, so Req's HTTP pool is absent) and note that the guard will refuse rather than
half-run. Give the invocation shape as `kamal app exec --reuse` wrapping
`bin/pukllay_club rpc '<expression>'`, plus an `ssh` + `docker exec` fallback against the same host
for when Kamal is unavailable. Tell the operator to confirm the exact `app exec` flags with
`kamal help app exec` rather than trusting a flag spelled in this document.

**Capturing output.** The release `rpc` command discards return values, so both functions print
their payload as a single JSON line; the operator redirects it to a file. Because `kamal app exec`
interleaves its own progress lines, pipe through a filter that keeps only the JSON line (a `grep`
for a line beginning with an opening brace) before redirecting. Name the two capture files
explicitly, both inside this quick task's own directory
(`.planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/`):
`prod-bgg-stats-before.json` and `prod-bgg-stats-after.json`. Note that the same payload is also in
`kamal app logs` and in Sentry, as backups.

**Step 1 — BEFORE measurement.** Run `PukllayClub.Release.bgg_stats_report()`, capture to
`prod-bgg-stats-before.json`. Read it back and confirm it is non-degenerate: `total_games` is in
the expected ~400s and `publishers.rows_with_duplicates` is greater than zero. State plainly that
if `rows_with_duplicates` is already zero, production is not contaminated and the rest of this
runbook must not be run — investigate first.

**Step 2 — DRY RUN.** Run `PukllayClub.Release.enrich_bgg_stats(dry_run: true)`. Expect `updated`
close to `candidates` and `failed_batches` empty. Then re-run the report and confirm it matches
`prod-bgg-stats-before.json` on every field except `run_at` — this is the dry run proving to itself
that it wrote nothing, rather than being trusted to.

**Step 3 — LIVE RUN.** Run `PukllayClub.Release.enrich_bgg_stats()`. Expect ~60-90 seconds for the
full catalog. Tell the operator to keep the session in the foreground; there is no caller-side rpc
timeout, so waiting is correct. Save the printed summary alongside the snapshots.

**Step 4 — AFTER measurement.** Run the report again, capture to `prod-bgg-stats-after.json`.

**Step 5 — COMPARE (the acceptance gate).** Give a table the operator fills in from the two files,
with the pass condition stated as a property rather than as a fixed number, since production's
catalog need not match dev's exactly:

| Metric | Before | After | Passes when |
|---|---|---|---|
| `publishers.rows_with_duplicates` | > 0 | | is exactly 0 |
| `artists.rows_with_duplicates` | > 0 | | is exactly 0 |
| `publishers.max` | | | strictly decreased |
| `artists.max` | | | strictly decreased |
| `mechanics.max` | | | unchanged (control) |
| `designers.max` | | | unchanged (control) |
| `total_games` | | | unchanged (control) |

State explicitly: **if any control row moved, stop and restore from the nightly dump** — the run
touched something outside its intended allowlist. Also note the corrected expectation quick task
260922-tum established: a post-fix `publishers.max` in the 40s is *correct*, not residual
contamination — some club titles genuinely carry 40+ real distinct international publishers, and
that finding was cross-checked byte-for-byte against BGG's raw XML for bgg_id 432. The falsifiable
property is duplicate-freeness plus a strict decrease, never a specific ceiling.

**Step 6 — Record.** Commit both JSON files and a one-paragraph outcome note. Land it via a branch
and PR, since `main` is protected.

**Rollback.** Restore from the nightly R2 `pg_dump`. Note that the enrichment is idempotent — it
overwrites the same narrow column allowlist from BGG's current data — so an interrupted or partial
run is safely re-run rather than needing a restore, and a restore is only for the case where a
control metric moved.

Then add a short pointer to AGENTS.md, immediately after the existing `create_owner` block in the
catalog data runbook section. It should name both new functions, state the `rpc`-not-`eval` rule in
one line with its reason, state that neither writes a file (unlike the dev Mix task, whose report
under `priv/` would be discarded on the next deploy), and link to the new runbook. Keep it to a
short paragraph plus the two invocations — AGENTS.md is a conventions index, not the runbook itself.
  </action>

  <verify>
    <automated>test -f docs/runbooks/production-bgg-reenrichment.md && grep -q 'production-bgg-reenrichment' AGENTS.md && grep -q 'bgg_stats_report' docs/runbooks/production-bgg-reenrichment.md && grep -q 'enrich_bgg_stats' docs/runbooks/production-bgg-reenrichment.md && echo RUNBOOK_WIRED</automated>
  </verify>

  <done>
`docs/runbooks/production-bgg-reenrichment.md` exists and walks all six steps in order with
copy-pasteable commands, an explicit rpc-not-eval rule, named capture filenames, the seven-row
comparison table with property-shaped pass conditions, the stop-and-restore rule for a moved
control, and a rollback section. AGENTS.md links to it from the catalog data runbook section.
No command in the document was executed by this plan.
  </done>

  <reversibility rating="reversible">Documentation only.</reversibility>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| operator laptop -> production node | An authenticated administrative command channel (`kamal app exec` over SSH) through which arbitrary Elixir is evaluated on the live node. Pre-existing — `create_owner/1` already uses it. |
| production node -> BGG xmlapi2 | Untrusted external XML crosses inward on every batch. Already mitigated at the parse layer (`dtd: :none`, T-01-08) and unchanged by this plan. |
| release function -> stdout / Logger / Sentry | Secrets could cross outward into a captured file, `kamal app logs`, and off-host into Sentry. This is the one genuinely new boundary this plan creates. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-VEQ-01 | Information disclosure | `Release.enrich_bgg_stats/1` log + stdout payload | medium | mitigate | Log only `Credentials.redacted/1`, never the struct or a raw field. Task 1 asserts `refute out =~ "test-token"` against both the captured stdout and the captured log, so a future edit that starts printing the struct fails the suite. |
| T-VEQ-02 | Tampering | `eval` invocation half-running the repair | medium | mitigate | `ensure_live_node!/1` raises before `Credentials.fetch!/0` and before any database write, naming the missing process and the correct `rpc` form. Task 1 negative-tests the raise branch by passing a name that is not registered. |
| T-VEQ-03 | Repudiation | Run record discarded with the container | medium | mitigate | No file is written under `priv/`. The summary reaches the operator's redirected stdout (primary), `kamal app logs` (secondary) and Sentry via `Sentry.LoggerHandler` (tertiary). Task 1 asserts `priv/repo/seed_data/` is byte-identical after a live call. |
| T-VEQ-04 | Tampering | Unfalsifiable measurement | high | mitigate | `StatsAudit.report/0` is negative-tested: a deliberately seeded duplicate publisher entry MUST be reported as one row with duplicates, and a cross-wiring test proves the control columns are read from the columns they name. Without these, a production "0 duplicates" reading would be worthless. |
| T-VEQ-05 | Denial of service | Repeated or concurrent repair invocation | low | accept | The channel is operator-only and manual; the enricher's writes are idempotent overwrites of a narrow column allowlist; a full pass is ~90s against ~20 BGG batches at the default 1500ms spacing, well inside BGG's rate limit. The runbook states a partial run is safely re-run rather than restored. |
| T-VEQ-06 | Elevation of privilege | Arbitrary code evaluation via the release `rpc` command | low | accept | Pre-existing property of every Mix release, over a channel already authenticated by Kamal/SSH and already used by `create_owner/1`. This plan adds two named functions to that surface; it adds no new channel, no new port and no new credential. |
| T-VEQ-07 | Information disclosure | Captured JSON snapshots committed to the repo | low | accept | The report carries only counts, maxima and internal row ids — no credentials, no member data, no personal data. The repo is public (00-03 D-19), and this payload is already derivable from the public catalog. |
| T-VEQ-SC | Tampering | Package-manager installs | n/a | n/a | No npm/pip/cargo install task exists in this plan — no new dependency of any kind is added. The package-legitimacy gate does not apply. |

Configured level is ASVS L1 with a blocking threshold of `high`. The single `high` entry
(T-VEQ-04) is mitigated inside this plan by Task 2's negative tests, so nothing is left blocking.
</threat_model>

<verification>
Run the full project gate once, after all three tasks:

```
mix quality
```

Expect: `format --check-formatted`, `credo --strict`, `sobelow --config` and
`test --warnings-as-errors` all clean.

**Styler review (mandatory, CLAUDE.md).** Styler is wired as a `mix format` plugin, and its own
README documents that it can change program behaviour. After the first `mix format` touches
`release.ex` and `stats_audit.ex`, read `git diff` and review every Styler-produced rewrite before
committing. Do not accept rewrites on trust.

**Known environmental noise.** Quick task 260922-tum recorded that this suite's live-network tests
occasionally surface transient BGG 5xx and Gemini timeouts unrelated to the change under test. If
such a failure appears, confirm it is in a pre-existing test file untouched by this plan before
treating it as a regression.

**What this plan genuinely cannot verify, stated honestly.** A release-only function cannot be
exercised inside a release from the test environment, so the split is:

*Automated here:* option passthrough, dry-run wiring, credential redaction in both output channels,
the tuple-to-JSON normalization of `failed_batches`, the liveness guard's pass and raise branches,
the absence of any `priv/` write, and the entire measurement including its negative tests.

*Only provable by the operator at invocation time:* that `Credentials.fetch!/0` actually resolves
on the production host from Kamal's `env.secret` (strongly implied by
`deploy_secrets_contract_test.exs` and by `Workers.EnrichGameWorker` already running there, but
not proven by this plan); that `kamal app exec --reuse` reaches the running container; that the
printed JSON survives Kamal's own output interleaving; and the real before/after numbers.
The runbook is written so each of those becomes a checked step rather than an assumption.

<human-check>
Before any production run, read `docs/runbooks/production-bgg-reenrichment.md` end to end and
confirm three things: the capture commands work on your machine's Kamal version (flag spellings
differ across Kamal 2 minors — verify with `kamal help app exec`), a recent nightly R2 `pg_dump`
exists and you know its date, and you accept the ~60-90s foreground wait. The dry run in Step 2 is
the real gate: it must leave the report byte-identical apart from `run_at`.
</human-check>
</verification>

<success_criteria>
- `PukllayClub.Release.enrich_bgg_stats/1` exists, delegates to `StatsEnricher.enrich_from_bgg/2`
  (no second implementation of the enrichment), supports `dry_run: true`, and refuses to run on a
  node that is missing the Repo or Req's HTTP pool.
- `PukllayClub.Release.bgg_stats_report/0` and `PukllayClub.Catalog.Seed.StatsAudit.report/0`
  exist, are read-only, and report publisher/artist maxima and duplicate-row counts alongside
  unchanged mechanics/designers controls.
- Both release functions print exactly one JSON line and write no file.
- No raw credential value reaches stdout or the log, asserted by test.
- The measurement fails its own suite if it cannot distinguish a seeded duplicate from clean data.
- `docs/runbooks/production-bgg-reenrichment.md` holds the exact six-step operator sequence, and
  AGENTS.md points to it.
- `mix quality` passes.
- **Nothing in this plan was executed against the production host or the production database.**
</success_criteria>

<output>
Create `.planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/260922-veq-SUMMARY.md`
when done.
</output>