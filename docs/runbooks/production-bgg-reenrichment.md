# Runbook: production BGG stats re-enrichment (quick task 260922-veq)

**This is an operator-run runbook.** The code it invokes shipped in quick task 260922-veq; running
the steps below is a separate, human-authorized action that happens after that plan merges and
deploys — no command here was executed by that plan.

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
- A recent nightly `pg_dump` exists in R2 and you have confirmed its date — that dump is this
  runbook's rollback.

## The one hard rule: `rpc`, never `eval`

Both `enrich_bgg_stats/1` and `bgg_stats_report/0` **must** be invoked with the release's `rpc`
command against the running node — never `eval`. An `eval` node starts no supervision tree, so
Req's HTTP pool (`Req.Finch`) does not exist there and every BGG request would fail; for
`enrich_bgg_stats/1` this would be a half-run, not a clean refusal, if the code didn't guard
against it. It does: `PukllayClub.Release.ensure_live_node!/1` checks for the required processes
first and raises an actionable error naming the `rpc` form instead.

Invocation shape, via Kamal:

```bash
kamal app exec --reuse "bin/pukllay_club rpc 'PukllayClub.Release.bgg_stats_report()'"
```

Or, as a fallback when Kamal itself is unavailable, `ssh` directly to the host and run the same
`rpc` command inside the running container via `docker exec`:

```bash
ssh deploy@34.41.63.138
docker exec -it pukllay_club-web-<container-suffix> bin/pukllay_club rpc 'PukllayClub.Release.bgg_stats_report()'
```

**Confirm the exact `kamal app exec` flags with `kamal help app exec` before running anything** —
flag spellings differ across Kamal 2 minors; don't trust the spelling in this document blindly.

## Capturing output

The release `rpc` command discards the evaluated expression's return value — both functions print
their JSON payload to stdout instead (`IO.puts`), so the operator captures it by redirecting.
`kamal app exec` also interleaves its own progress lines with the container's stdout, so filter to
just the JSON line (it's the only line starting with `{`) before redirecting:

```bash
kamal app exec --reuse "bin/pukllay_club rpc 'PukllayClub.Release.bgg_stats_report()'" \
  | grep '^{' > .planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/prod-bgg-stats-before.json
```

Name the two capture files exactly:

- `.planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/prod-bgg-stats-before.json`
- `.planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/prod-bgg-stats-after.json`

Both functions also emit the same payload via `Logger.info`, so the same JSON is recoverable from
`kamal app logs` and — because `Sentry.LoggerHandler` is attached with `enable_logs: true`
(`application.ex`) — from Sentry's Logs UI, as backups if the operator's terminal capture is lost.

## Step 1 — BEFORE measurement

```bash
kamal app exec --reuse "bin/pukllay_club rpc 'PukllayClub.Release.bgg_stats_report()'" \
  | grep '^{' > .planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/prod-bgg-stats-before.json
```

Read the file back and confirm it is non-degenerate: `total_games` should be in the expected
~400s, and `publishers.rows_with_duplicates` should be greater than zero. **If
`rows_with_duplicates` is already zero, production is not contaminated — stop here and
investigate before running anything else in this runbook.**

## Step 2 — DRY RUN

```bash
kamal app exec --reuse "bin/pukllay_club rpc 'PukllayClub.Release.enrich_bgg_stats(dry_run: true)'"
```

Expect `updated` close to `candidates` and `failed_batches` empty (or very small — a transient BGG
5xx is possible and does not indicate a problem with this code). Then re-run the report:

```bash
kamal app exec --reuse "bin/pukllay_club rpc 'PukllayClub.Release.bgg_stats_report()'" | grep '^{'
```

**This is the real gate.** Confirm the fresh report matches `prod-bgg-stats-before.json` on every
field except `run_at` — the dry run proving to itself that it wrote nothing, rather than being
trusted to.

## Step 3 — LIVE RUN

```bash
kamal app exec --reuse "bin/pukllay_club rpc 'PukllayClub.Release.enrich_bgg_stats()'"
```

Expect roughly 60-90 seconds for the full catalog (about 20 batches of 20 at the enricher's
1500ms default spacing). Keep the session in the foreground — there is no caller-side `rpc`
timeout (`:erpc.call/4`'s 4-arity form defaults to `:infinity`), so waiting for it to finish is
correct, not a sign anything hung. Save the printed summary alongside the before/after snapshots.

## Step 4 — AFTER measurement

```bash
kamal app exec --reuse "bin/pukllay_club rpc 'PukllayClub.Release.bgg_stats_report()'" \
  | grep '^{' > .planning/quick/260922-veq-add-release-enrich-bgg-stats-so-bgg-stat/prod-bgg-stats-after.json
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
