# Runbook: running `mix catalog.seed` against production

`mix catalog.seed` is a one-time, manually-run task (D-02) — it is **never** run on the
production host itself. The production e2-micro is 1GB RAM / 2GB swap (00-CONTEXT.md D-20);
running BGG XML parsing, libvips image resizing, and R2 upload for ~400 games there risks OOM
and blocks the deploy window (01-RESEARCH.md Pitfall 6). Instead, the task runs on the
**developer machine**, connecting to the production Postgres accessory over an SSH tunnel.

This is a rare operation — expect to run this once at initial launch, then again only if the
club's source CSV (`priv/repo/seed_data/ludoteca.csv`) is updated with new games or corrections.

## 1. Required environment variables

Resolve via `PukllayClub.Catalog.Seed.Credentials.fetch!/0` — env var takes precedence over
`config/dev.secret.exs`. When running against production, set every value as an environment
variable rather than relying on the gitignored dev file (which should hold dev-only defaults,
not be assumed present on whichever machine happens to run this):

```bash
export BGG_API_TOKEN="..."          # registered BGG application token
export R2_ACCOUNT_ID="..."
export R2_ACCESS_KEY_ID="..."
export R2_SECRET_ACCESS_KEY="..."
export R2_CATALOG_BUCKET="pukllay-club-catalog"
export R2_PUBLIC_BASE_URL="https://<bucket>.r2.dev"   # or the custom domain, if configured
```

`mix catalog.seed` calls `Credentials.fetch!/0` at startup and raises immediately, naming every
missing key, if any of the above is absent — it never proceeds partway through a run without full
credentials.

## 2. Open an SSH tunnel to the production Postgres accessory

The Kamal `pgvector/pgvector:pg17` accessory binds only to `127.0.0.1` on the production host
(00-CONTEXT.md D-15) — there is no direct network path from a developer machine to production
Postgres. Forward a local port through SSH instead:

```bash
ssh -N -L 55432:127.0.0.1:5432 deploy@<production-host>
```

Leave this running in its own terminal/session for the duration of the seed run. `-N` means "no
remote command" — the SSH session exists purely to hold the port forward open.

## 3. Point `DATABASE_URL` at the tunnel

In a second terminal, on the same developer machine:

```bash
export DATABASE_URL="ecto://<db_user>:<db_password>@127.0.0.1:55432/<db_name>"
```

Use the same credentials `config/runtime.exs` already resolves for the production app (see
`.kamal/secrets` for where those live) — the tunnel makes the accessory reachable at
`127.0.0.1:55432` from the developer machine's point of view, even though the app itself talks to
it as `127.0.0.1:5432` from inside the production host.

## 4. Run the seed task against the release, from the developer machine

```bash
MIX_ENV=prod mix catalog.seed
```

Running under `MIX_ENV=prod` (still `mix`, not a compiled release — Mix and the source tree are
available on the developer machine, unlike inside the deployed release container) ensures the
task uses the same `runtime.exs` config resolution the real app would, while every expensive step
— BGG parsing, libvips resize, R2 upload — consumes the **developer machine's** CPU/RAM, never
the production box's. Only the final `INSERT ... ON CONFLICT` traffic crosses the SSH tunnel to
production Postgres.

Optional flags, useful when validating before a full run:

- `mix catalog.seed --report-only` — audits the CSV's data-quality findings with **no** BGG call,
  no image work, no database write. Safe to run against `MIX_ENV=dev` too; it never touches
  `DATABASE_URL`.
- `mix catalog.seed --limit N --dry-run` — enriches the first N rows via a real BGG call but skips
  the database write and the R2 upload. Useful for a final smoke test against production
  credentials before committing to the full ~35-second, ~1,500-object run.

## 5. Re-run semantics (safe to re-run)

`mix catalog.seed` is idempotent by design (D-02):

- **Database:** upserts on `games.csv_row` (not `bgg_id`) as the conflict target — re-running
  over the same CSV updates existing rows in place rather than duplicating them, and preserves
  both rows sharing duplicate `BGG_ID` 163412 (D-19).
- **R2 images:** `R2Storage.put/4` calls `head_object` before uploading; an already-present key is
  skipped and its existing URL returned rather than re-downloaded/re-resized/re-uploaded.

This means a partial run (e.g. interrupted by a dropped SSH tunnel) can simply be re-run from the
top — already-processed rows and already-uploaded images are cheap no-ops on the second pass.

## 6. Where to read the review report

Every run (including `--report-only`) writes `priv/repo/seed_data/catalog_seed_report.md` —
listing every unrecognized hashtag cell (D-20), weight-band conflict and how it resolved,
zero-hashtag rows split into Peso-resolved vs. unresolved, rows with no `BGG_ID` (D-18), duplicate
`BGG_ID` groups (D-19), BGG ids that returned no item, games with no Spanish edition found (D-04),
and every observed BGG mechanic/category term not yet covered by the plain-Spanish glossary (for
01-06 to act on). Review this file after every full run before considering the catalog data final
— it is the audit trail for every case this task could not resolve without guessing.
