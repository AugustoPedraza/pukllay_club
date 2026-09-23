# Runbook: production BGG stats re-enrichment (quick task 260922-veq)

**This is an operator-run runbook.** The code it invokes shipped in quick task 260922-veq; running
the steps below is a separate, human-authorized action that happens after that plan merges and
deploys — no command here was executed by that plan. Quick task 260922-w5o (2026-09-22) corrected
this runbook's invocation after the `rpc` command was found unavailable on the production
container — the original version of this document told operators to use `rpc`, which does not
work on this deployment; see the "Why not `rpc`" subsection below for what was observed.

## Context

Quick task 260922-tum fixed `BggClient.parse_items/1`'s xpath scoping (`.//` -> `./`), which was
folding nested `boardgameversion` publishers/artists into the base game's own lists. That fix is
**already live in production** (merged `a160e22` via PR #65; deploy run `35806389437` succeeded),
so production parses correctly *going forward*. But every existing production row still carries
the pre-fix, contaminated `publishers`/`artists` lists — the fix only changes what a *future* BGG
fetch returns, it does not retroactively touch rows already in the database.

Dev already went through this repair (`mix catalog.enrich_bgg_stats`, quick task 260922-tum): the
worst publisher list fell from 178 entries to 45, rows carrying a duplicate entry fell to 0,
`mechanics.max` stayed at 20 and `designers.max` stayed at 7 (the two controls, untouched). That is
the target shape for production too.

Mix does not exist inside a compiled release, so there is no way to run
`mix catalog.enrich_bgg_stats` against production directly. `PukllayClub.Release.enrich_bgg_stats/1`
and `PukllayClub.Release.bgg_stats_report/0` (quick task 260922-veq) are the release-callable
replacement.

## Preconditions

- The `BggClient` scoping fix is live on the currently-deployed image (confirmed above).
- `BGG_API_TOKEN` is present in Kamal `env.secret` — it already is, added in 01.8.1-08, and kept in
  sync by `test/pukllay_club/deploy_secrets_contract_test.exs`.
- **Proven on the production host, 2026-09-22:** `PukllayClub.Catalog.Seed.Credentials.fetch()`,
  run through `eval` with the preamble below, returned `{:ok, _}`. `BGG_API_TOKEN` demonstrably
  resolves in-process from Kamal's `env.secret` on the live host — this closes one of
  260922-veq's SUMMARY items that was previously only "provable by the operator at invocation
  time." The other two items in that list (the real before/after enrichment numbers, and whether
  the `kamal app exec --reuse` form reaches the running container) remain unproven; do not treat
  this precondition as covering those.
- A recent nightly `pg_dump` exists in R2 and you have confirmed its date — that dump is this
  runbook's rollback.

## Invocation: `eval` with the required-processes preamble

Both `enrich_bgg_stats/1` and `bgg_stats_report/0` are invoked with the release's `eval` command,
carrying a preamble that starts exactly the processes `ensure_live_node!/1` requires:

```elixir
{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()
```

The first line starts `Req.Finch`, the `:req` application's default Finch pool — it is not
started by this app's own supervision tree. The **`:ecto_sql` line is not optional, and is the
easiest thing to get wrong**: skip it and `PukllayClub.Repo.start_link()` fails with a missing
`DBConnection.Watcher` process, because `:db_connection`'s supervision tree is not running.
Every invocation below carries all three expressions — never copy a shorter form.

**The guard is a safety net, not an obstacle.** `ensure_live_node!/1` checks for the *registered
processes* `PukllayClub.Repo` and `Req.Finch` — it cannot see which command started them. An
`eval` that runs the preamble above satisfies the guard exactly as legitimately as a booted node
would, and an `eval` that forgot the preamble still gets a clean refusal instead of a half-run
that fails mid-batch on a missing HTTP pool.

**Why this shape is also better**, not merely a fallback: it runs the ~90s job in its own
short-lived node rather than inside the live web node on a 1 GB host, so it never competes with
request serving.

### Why not `rpc`

On 2026-09-22 the release's `rpc` command, run against the running production container, returned:

```
--rpc-eval : RPC failed with reason :noconnection
```

The following was ruled out on that host, as observations only:

- EPMD was up and the node WAS registered (`epmd -names` reported `name pukllay_club at port
  36929`)
- Distribution WAS enabled (PID 1's cmdline carried `-sname` and `-setcookie`)
- The cookie was NOT mismatched — sha256 of the `-setcookie` cmdline value,
  `/app/releases/COOKIE`, and PID 1's `RELEASE_COOKIE` env were all identical
- The short hostname WAS resolvable — `/etc/hosts` mapped both the full container hostname suffix
  and its truncated short form to the container's own address
- `Node.ping/1` from a probe node inside the same container still returned `:pang`

**The root cause is NOT established.** Every plausible mechanism above was checked and came back
healthy — do not assume one anyway, and do not "fix" distribution on this host based on a guess.
The operational fact is simply that `rpc` is unavailable on this deployment; `eval` is proven to
work and is what every diagnostic above was itself run through.

## Invocation shape

The proven path: `ssh` to the host, discover the running web container, then run the release
binary's `eval` command inside it via `docker exec`. No `-t` anywhere in this runbook — every
command here is non-interactive, and a TTY injects carriage returns into the JSON captures Steps 1
and 4 redirect to files.

```bash
ssh deploy@34.41.63.138
docker ps   # find the running pukllay_club-web-<suffix> container; don't hardcode the suffix
docker exec pukllay_club-web-<container-suffix> bin/pukllay_club eval '
{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()
PukllayClub.Release.bgg_stats_report()
'
```

The equivalent alternative via Kamal, carrying the same `eval` expression:

```bash
kamal app exec --reuse "bin/pukllay_club eval '
{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()
PukllayClub.Release.bgg_stats_report()
'"
```

**Confirm the exact `kamal app exec` flags with `kamal help app exec` before running anything** —
flag spellings differ across Kamal 2 minors; don't trust the spelling in this document blindly.
This exact Kamal form has not been exercised on this host — 260922-veq's SUMMARY already lists it
as operator-provable only, and this correction does not upgrade that status.

To keep each step below short, you may define the preamble once as a shell variable in your own
session and reference it in every step — for example:

```bash
PREAMBLE='{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()'
```

If you do, still write out the fully expanded form at least once so an operator in a fresh shell
can reconstruct it from this document alone — every step below shows the expanded form.

## Capturing output

Both functions print their JSON payload to stdout (`IO.puts`) rather than relying on `eval`'s
return value, so the operator captures it by redirecting. `docker exec`/`kamal app exec` may
interleave their own progress lines with the container's stdout, so filter to just the JSON line
(it's the only line starting with `{`) before redirecting — this holds for either invocation form:

```bash
docker exec pukllay_club-web-<container-suffix> bin/pukllay_club eval '
{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()
PukllayClub.Release.bgg_stats_report()
' | grep '^{' > .planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/prod-bgg-stats-before.json
```

Name the two capture files exactly:

- `.planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/prod-bgg-stats-before.json`
- `.planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/prod-bgg-stats-after.json`

Both functions also emit the same payload via `Logger.info`, so the same JSON is recoverable from
`kamal app logs` and — because `Sentry.LoggerHandler` is attached with `enable_logs: true`
(`application.ex`) — from Sentry's Logs UI, as backups if the operator's terminal capture is lost.

## Step 1 — BEFORE measurement

```bash
docker exec pukllay_club-web-<container-suffix> bin/pukllay_club eval '
{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()
PukllayClub.Release.bgg_stats_report()
' | grep '^{' > .planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/prod-bgg-stats-before.json
```

Read the file back and confirm it is non-degenerate: `total_games` should be in the expected
~400s, and `publishers.rows_with_duplicates` should be greater than zero. **If
`rows_with_duplicates` is already zero, production is not contaminated — stop here and
investigate before running anything else in this runbook.**

## Step 2 — DRY RUN

```bash
docker exec pukllay_club-web-<container-suffix> bin/pukllay_club eval '
{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()
PukllayClub.Release.enrich_bgg_stats(dry_run: true)
'
```

Expect `updated` close to `candidates` and `failed_batches` empty (or very small — a transient BGG
5xx is possible and does not indicate a problem with this code). Then re-run the report:

```bash
docker exec pukllay_club-web-<container-suffix> bin/pukllay_club eval '
{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()
PukllayClub.Release.bgg_stats_report()
' | grep '^{'
```

**This is the real gate.** Confirm the fresh report matches `prod-bgg-stats-before.json` on every
field except `run_at` — the dry run proving to itself that it wrote nothing, rather than being
trusted to.

## Step 3 — LIVE RUN

```bash
docker exec pukllay_club-web-<container-suffix> bin/pukllay_club eval '
{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()
PukllayClub.Release.enrich_bgg_stats()
'
```

Expect roughly 60-90 seconds for the full catalog (about 20 batches of 20 at the enricher's
1500ms default spacing). The work runs in the foreground of the invoking node itself, so waiting
60-90 seconds is expected and is not a sign anything hung — do not detach the session. Save the
printed summary alongside the before/after snapshots.

## Step 4 — AFTER measurement

```bash
docker exec pukllay_club-web-<container-suffix> bin/pukllay_club eval '
{:ok, _} = Application.ensure_all_started(:req)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = PukllayClub.Repo.start_link()
PukllayClub.Release.bgg_stats_report()
' | grep '^{' > .planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/prod-bgg-stats-after.json
```

## Step 5 — COMPARE (the acceptance gate)

Fill in this table from the two captured JSON files. The pass condition is stated as a property,
not a fixed number — production's catalog need not match dev's exactly:

| Metric | Before | After | Passes when |
|---|---|---|---|
| `publishers.rows_with_duplicates` | > 0 | | is exactly 0 |
| `artists.rows_with_duplicates` | > 0 | | is exactly 0 |
| `publishers.max` | | | strictly decreased |
| `artists.max` | | | strictly decreased |
| `mechanics.max` | | | unchanged (control) |
| `designers.max` | | | unchanged (control) |
| `total_games` | | | unchanged (control) |

**If any control row moved, stop and restore from the nightly dump** — the run touched something
outside its intended allowlist.

Also note the corrected expectation quick task 260922-tum established: a post-fix `publishers.max`
in the 40s is *correct*, not residual contamination — some club titles genuinely carry 40+ real
distinct international publishers, and that finding was cross-checked byte-for-byte against BGG's
raw XML for bgg_id 432. The falsifiable property is duplicate-freeness plus a strict decrease,
never a specific ceiling.

## Step 6 — Record

Commit both JSON files and a one-paragraph outcome note. `main` is branch-protected — land this
via a branch and PR, never a direct push.

## Rollback

Restore from the nightly R2 `pg_dump` (see `docs/runbooks/production-secrets.md` for the R2
backup-bucket credentials). The enrichment itself is idempotent — it overwrites the same narrow
column allowlist from BGG's current data — so an interrupted or partial run is safely **re-run**
rather than restored; a restore is only needed for the case where Step 5 finds a moved control
metric.
