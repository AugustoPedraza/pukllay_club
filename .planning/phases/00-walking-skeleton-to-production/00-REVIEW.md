---
phase: 00-walking-skeleton-to-production
reviewed: 2026-07-27T20:21:55Z
depth: standard
files_reviewed: 66
files_reviewed_list:
  - AGENTS.md
  - assets/css/app.css
  - assets/js/app.js
  - assets/tsconfig.json
  - assets/vendor/heroicons.js
  - assets/vendor/topbar.js
  - .claude/CLAUDE.md
  - config/config.exs
  - config/deploy.yml
  - config/dev.exs
  - config/prod.exs
  - config/runtime.exs
  - config/test.exs
  - .credo.exs
  - docker-entrypoint
  - Dockerfile
  - .dockerignore
  - .formatter.exs
  - .github/workflows/backup.yml
  - .github/workflows/ci.yml
  - .github/workflows/deploy.yml
  - .gitignore
  - lib/pukllay_club/application.ex
  - lib/pukllay_club.ex
  - lib/pukllay_club/mailer.ex
  - lib/pukllay_club/release.ex
  - lib/pukllay_club/repo.ex
  - lib/pukllay_club_web/components/core_components.ex
  - lib/pukllay_club_web/components/layouts.ex
  - lib/pukllay_club_web/components/layouts/root.html.heex
  - lib/pukllay_club_web/controllers/error_html.ex
  - lib/pukllay_club_web/controllers/error_json.ex
  - lib/pukllay_club_web/controllers/health_controller.ex
  - lib/pukllay_club_web/controllers/page_controller.ex
  - lib/pukllay_club_web/controllers/page_html.ex
  - lib/pukllay_club_web/controllers/page_html/home.html.heex
  - lib/pukllay_club_web/endpoint.ex
  - lib/pukllay_club_web.ex
  - lib/pukllay_club_web/gettext.ex
  - lib/pukllay_club_web/router.ex
  - lib/pukllay_club_web/telemetry.ex
  - mise.toml
  - mix.exs
  - mix.lock
  - priv/gettext/en/LC_MESSAGES/errors.po
  - priv/gettext/errors.pot
  - priv/repo/migrations/20260727154440_create_deploy_proof.exs
  - priv/repo/migrations/.formatter.exs
  - priv/repo/seeds.exs
  - priv/static/favicon.ico
  - priv/static/images/logo.svg
  - priv/static/robots.txt
  - README.md
  - rel/overlays/bin/createdb
  - rel/overlays/bin/migrate
  - rel/overlays/bin/migrate.bat
  - rel/overlays/bin/server
  - rel/overlays/bin/server.bat
  - .sobelow-conf
  - test/pukllay_club_web/controllers/error_html_test.exs
  - test/pukllay_club_web/controllers/error_json_test.exs
  - test/pukllay_club_web/controllers/health_controller_test.exs
  - test/pukllay_club_web/controllers/page_controller_test.exs
  - test/support/conn_case.ex
  - test/support/data_case.ex
  - test/test_helper.exs
findings:
  critical: 2
  warning: 4
  info: 3
  total: 9
status: issues_found
---

# Phase 00: Code Review Report

**Reviewed:** 2026-07-27T20:21:55Z
**Depth:** standard
**Files Reviewed:** 66
**Status:** issues_found

## Summary

Phase 0 stands up a full Phoenix "walking skeleton" plus its deploy pipeline (Docker, Kamal,
GitHub Actions CI/CD, nightly backup). The vast majority of the reviewed files are unmodified
`mix phx.new`/`phx.gen.release` generator boilerplate (assets, gettext, error views, layouts,
core_components, test/support helpers) and are sound as shipped by the framework — no findings
were raised against that boilerplate beyond one doc-quality note (README).

Scrutiny focused on the hand-written infrastructure: `lib/pukllay_club/release.ex`,
`docker-entrypoint`, `Dockerfile`, `config/runtime.exs`/`config/prod.exs`, `config/deploy.yml`,
and the three GitHub Actions workflows. Two BLOCKER-level issues were found that would surface
at runtime rather than at "code compiles / tests pass" time, which is exactly the kind of defect
this pipeline's `mix quality` gate cannot catch:

1. The `deploy` job in `.github/workflows/deploy.yml` never grants itself `packages: read`
   permission, so the `GITHUB_TOKEN` it hands to Kamal for `ghcr.io` authentication cannot pull
   the image the previous job just pushed — the deploy step should fail every time it runs.
2. The nightly backup workflow's remote `pg_dump | gzip` pipeline has no `pipefail` on the
   *remote* shell, so a failed/auth-denied `pg_dump` can silently produce a "successful" empty
   backup file that gets uploaded to R2 without failing the job — a direct threat to the one
   documented disaster-recovery mechanism this project has.

Four warnings and three info-level items are also recorded below (secret handling on the backup
host, a quoting fragility in the same SSH command, an unhelpful crash message in the release
migration helper, DB traffic left unencrypted between app and db containers, workflow
duplication, floating Action version pins, and a stale README).

## Critical Issues

### CR-01: Deploy job's GITHUB_TOKEN lacks `packages: read`, so Kamal cannot pull the image it just built

**File:** `.github/workflows/deploy.yml:126-187` (specifically the missing `permissions:` block on
the `deploy` job, and the token usage at lines 165-177)

**Issue:** The workflow sets a restrictive top-level default:

```yaml
permissions:
  contents: read
```

`build-and-push` explicitly overrides this with `contents: read, packages: write` for its own job
— but `deploy` has no `permissions:` block of its own, so it inherits the workflow-level default
of `contents: read` only. The `deploy` job then does:

```yaml
env:
  KAMAL_REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
  ...
run: kamal deploy --skip-push
```

`kamal deploy` SSHs to the production host and runs `docker login ghcr.io` / `docker pull` using
this token (via `.kamal/secrets`). Because the `deploy` job's token was minted with only
`contents: read`, it has no `packages` scope at all, and `docker login`/`pull` against
`ghcr.io/augustopedraza/pukllay_club` will be rejected. This is a full pipeline break: every
push to `main` would build and push the image successfully, then fail during the actual deploy
step. This is exactly the kind of runtime-only failure that unit tests and `mix quality` (which
never runs against ghcr) cannot catch.

**Fix:**
```yaml
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read
    steps:
      ...
```

### CR-02: Nightly backup can silently upload an empty/corrupt dump without failing the job

**File:** `.github/workflows/backup.yml:47-54`

**Issue:**
```yaml
- name: Dump production database over SSH
  env:
    POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
  run: |
    set -euo pipefail
    ssh -o StrictHostKeyChecking=accept-new "deploy@${{ secrets.DEPLOY_HOST }}" \
      "sudo docker exec -e PGPASSWORD='$POSTGRES_PASSWORD' db pg_dump -U postgres pukllay_club_prod | gzip" \
      > "backup-$(date +%F).sql.gz"
```

`set -euo pipefail` only applies to the *local* runner shell that invokes `ssh`. The command
string handed to `ssh` (`"... pg_dump ... | gzip"`) is executed by the *remote* host's default
shell, which has no `pipefail` set. `ssh`'s own exit status reflects only the exit status of the
last command in that remote pipeline — `gzip` — not `pg_dump`. `gzip` reading from a closed or
empty stdin (e.g., because `docker exec`/`pg_dump` failed due to a bad password, missing
container, or `sudo` prompting for a password non-interactively) still exits `0` and emits a
valid (but empty/near-empty) gzip stream. The local redirect `> "backup-...sql.gz"` then
"succeeds," the step exits `0`, and a broken backup is uploaded to R2 with no signal anywhere
that the dump actually failed. This directly undermines the project's only backup/disaster
recovery mechanism (nightly `pg_dump` -> R2, called out as important in CLAUDE.md).

**Fix:** Force `pipefail` on the remote shell and validate the resulting artifact before upload:
```yaml
- name: Dump production database over SSH
  env:
    POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
  run: |
    set -euo pipefail
    ssh -o StrictHostKeyChecking=accept-new "deploy@${{ secrets.DEPLOY_HOST }}" \
      "sudo docker exec -e PGPASSWORD='$POSTGRES_PASSWORD' db bash -c 'set -o pipefail; pg_dump -U postgres pukllay_club_prod | gzip'" \
      > "backup-$(date +%F).sql.gz"

    # Fail loudly instead of uploading a silently-broken/empty dump.
    gzip -t "backup-$(date +%F).sql.gz"
    test -s "backup-$(date +%F).sql.gz"
```

## Warnings

### WR-01: `PGPASSWORD` passed as a `docker exec -e` argument is visible in the remote host's process list

**File:** `.github/workflows/backup.yml:47-54`

**Issue:** `sudo docker exec -e PGPASSWORD='<password>' db pg_dump ...` embeds the literal
Postgres password as part of the command line executed on the production host. For the duration
of the `docker exec`, any other local process/user able to read `ps aux` or `/proc/<pid>/cmdline`
on that host can see the plaintext password. On a genuinely single-tenant host this is low risk,
but it is a common secret-leak vector and worth avoiding given the password is also reused for
the Postgres accessory itself.

**Fix:** Prefer a `.pgpass` file (mode 0600, already present in the `db` container's home) or a
`--env-file` sourced from a temp file with restricted permissions instead of putting the secret
directly on the `docker exec` command line.

### WR-02: Backup SSH command is fragile if `POSTGRES_PASSWORD` ever contains a single quote

**File:** `.github/workflows/backup.yml:51-54`

**Issue:** The remote command string is built as:
```
"sudo docker exec -e PGPASSWORD='$POSTGRES_PASSWORD' db pg_dump -U postgres pukllay_club_prod | gzip"
```
`$POSTGRES_PASSWORD` is expanded by the *local* shell before being sent to `ssh`, and the
resulting literal value is wrapped in single quotes for the *remote* shell to parse. If the
secret value ever contains a `'` character, the remote single-quoted string terminates early,
breaking the command (at best a hard failure, at worst executing unintended remote shell
fragments depending on what follows). Password-rotation practices that allow arbitrary special
characters could hit this silently.

**Fix:** Escape single quotes before interpolation (`${POSTGRES_PASSWORD//\'/\'\\\'\'}`), or avoid
building a shell string with the secret entirely (e.g., base64-encode the password locally, decode
it inside the remote command).

### WR-03: `PukllayClub.Release.createdb/0` surfaces a bare `MatchError` instead of a diagnosable failure

**File:** `lib/pukllay_club/release.ex:8-14, 39-45`

**Issue:**
```elixir
def createdb do
  load_app()

  for repo <- repos() do
    :ok = ensure_repo_created(repo)
  end
end
...
defp ensure_repo_created(repo) do
  case repo.__adapter__().storage_up(repo.config()) do
    :ok -> :ok
    {:error, :already_up} -> :ok
    {:error, term} -> {:error, term}
  end
end
```
When `storage_up/1` returns an error other than `:already_up` (e.g. connection refused, auth
failure, insufficient privilege), `ensure_repo_created/1` returns `{:error, term}`, and the `:ok =
...` match in `createdb/0` raises a generic `MatchError: no match of right hand side value:
{:error, ...}`. Since `docker-entrypoint` runs `createdb` before `migrate` before every server
start, this is the very first thing that can fail on a bad deploy — and whoever is reading
`kamal app logs` after a failed health check gets an opaque match error instead of a clear
"failed to create database storage: <reason>" message.

**Fix:**
```elixir
def createdb do
  load_app()

  for repo <- repos() do
    case ensure_repo_created(repo) do
      :ok -> :ok
      {:error, term} -> raise "failed to create storage for #{inspect(repo)}: #{inspect(term)}"
    end
  end
end
```

### WR-04: Production Postgres connection has TLS explicitly disabled with no compensating control documented in code

**File:** `config/runtime.exs:59-65`

**Issue:**
```elixir
config :pukllay_club, PukllayClub.Repo,
  # ssl: true,
  url: database_url,
  ...
```
`ssl` is commented out, so the app-to-database connection (including the initial auth handshake
carrying `DATABASE_URL`'s embedded credentials) travels in plaintext over the Docker bridge
network between the app container and the `db` accessory. `config/deploy.yml` binds the
accessory's *host port* to `127.0.0.1` only, but that binding governs host-level exposure, not
the inter-container Docker network path the app's Postgres connection actually uses — traffic
between the two containers still traverses the (unencrypted) `kamal` Docker network, not the
loopback interface. This is a defense-in-depth gap: acceptable for a single-tenant host today,
but there's no code comment recording it as an accepted risk, so a future reviewer/AI agent has
no signal this was a deliberate tradeoff versus an oversight.

**Fix:** Either enable `ssl: true` (self-signed cert is fine for an internal accessory link) or
add an explicit comment recording why it's intentionally omitted for this deployment topology, so
it isn't silently "fixed" or silently left as a latent gap later.

## Info

### IN-01: `ci.yml` and `deploy.yml` duplicate the entire `quality` job verbatim

**File:** `.github/workflows/ci.yml:12-60`, `.github/workflows/deploy.yml:10-60`

**Issue:** The Postgres service definition, Elixir/OTP setup, dependency cache step, and `mix
quality` invocation are copy-pasted between the two workflow files. This duplication is called
out as intentional in CLAUDE.md/AGENTS.md (re-running the gate on `main` before deploy), but the
duplication itself is still a maintenance hazard: a future bump to `elixir-version`/`otp-version`,
the cache key strategy, or the Postgres image made in one file and forgotten in the other would
let the two gates silently diverge.

**Fix:** Extract the shared job into a reusable workflow (`workflow_call`) invoked by both
`ci.yml` and `deploy.yml` so they can never drift out of sync.

### IN-02: Several third-party Actions are pinned to floating major-version tags rather than commit SHAs

**File:** `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`, `.github/workflows/backup.yml`

**Issue:** `actions/checkout@v4`, `erlef/setup-beam@v1`, `actions/cache@v4`,
`docker/login-action@v3`, `docker/setup-buildx-action@v3`, `docker/metadata-action@v5`,
`docker/build-push-action@v6`, and `ruby/setup-ruby@v1` are all pinned to mutable tags. (Contrast
with `webfactory/ssh-agent@v0.9.0`, which a prior commit in this same phase already tightened
specifically because a floating tag was unresolvable — the same class of risk applies to the
other actions, just latent rather than already having caused a break.) These jobs have access to
`DEPLOY_SSH_KEY`, `SECRET_KEY_BASE`, `DATABASE_URL`, `SENTRY_DSN`, and `POSTGRES_PASSWORD` — a
compromised upstream tag on any of them is a credible supply-chain path to those secrets.

**Fix:** Pin to a specific commit SHA (with the resolved version as a trailing comment) for at
least the actions that run in jobs with secret access (`deploy`, `backup`).

### IN-03: `README.md` is the untouched `mix phx.new` scaffold and doesn't describe this project

**File:** `README.md`

**Issue:** The README still reads as generic Phoenix boilerplate ("To start your Phoenix
server..."), with no mention of PukllayClub, the Postgres/pgvector setup, `mix quality`, or the
Kamal/GitHub Actions deploy pipeline that this phase built out. A new contributor arriving via
README alone gets no signal that any of this infrastructure exists.

**Fix:** Replace with project-specific setup/dev instructions, or at minimum link to
`AGENTS.md`/`.claude/CLAUDE.md` for conventions and the deploy pipeline.

---

_Reviewed: 2026-07-27T20:21:55Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
