---
phase: 00-walking-skeleton-to-production
fixed_at: 2026-07-27T20:50:21Z
review_path: .planning/phases/00-walking-skeleton-to-production/00-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 5
skipped: 1
status: partial
---

# Phase 00: Code Review Fix Report

**Fixed at:** 2026-07-27T20:50:21Z
**Source review:** .planning/phases/00-walking-skeleton-to-production/00-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (CR-01, CR-02, WR-01, WR-02, WR-03, WR-04 — the 3 Info findings were out of
  scope for this fix pass)
- Fixed: 5
- Skipped: 1

All fixes were developed and committed on an isolated worktree/branch
(`gsd-reviewfix/00-121369`), landed via PR #24 after the required `quality` CI check passed
(branch protection on `main` requires this — no bare push), then fast-forward-merged into local
`main`.

## Fixed Issues

### CR-01: Deploy job's GITHUB_TOKEN lacks `packages: read`, so Kamal cannot pull the image it just built

**Files modified:** `.github/workflows/deploy.yml`
**Commit:** `165bed9`
**Applied fix:** Added an explicit `permissions: { contents: read, packages: read }` block to the
`deploy` job, matching the review's suggested fix exactly — the job no longer inherits the
workflow-level `contents: read`-only default, so `KAMAL_REGISTRY_PASSWORD` (the job's
`GITHUB_TOKEN`) now carries the `packages: read` scope Kamal needs for `docker login`/`pull`
against `ghcr.io`.

### CR-02: Nightly backup can silently upload an empty/corrupt dump without failing the job

**Files modified:** `.github/workflows/backup.yml`
**Commit:** `8af075d`
**Applied fix:** Wrapped the remote `pg_dump | gzip` pipeline in `bash -c 'set -o pipefail; ...'`
so a `pg_dump` failure now propagates through the pipe's exit status instead of being masked by
`gzip`'s own success. Added `gzip -t` and `test -s` validation of the resulting artifact
immediately after the SSH step, before the upload step runs — a broken/empty dump now fails the
job loudly instead of being uploaded to R2.

### WR-01: `PGPASSWORD` passed as a `docker exec -e` argument is visible in the remote host's process list

**Files modified:** `.github/workflows/backup.yml`
**Commit:** `1bf29ce`
**Applied fix:** Redesigned the remote command so the password is never embedded as a
`docker exec -e ...` argument (nor interpolated into any part of the remote command string at
all). The password is now sent over SSH's stdin channel (a here-string on the local side) to a
remote script whose own argv contains no secret; that script writes the stdin data into a
`mktemp`-created, `chmod 600` temp file (removed via `trap ... EXIT`) and passes it to
`docker exec --env-file`. This also incidentally avoids exposing the password in the top-level
remote shell's own `ps aux` cmdline, which a purely command-line-based fix would not have
addressed.

### WR-03: `PukllayClub.Release.createdb/0` surfaces a bare `MatchError` instead of a diagnosable failure

**Files modified:** `lib/pukllay_club/release.ex`
**Commit:** `df7bae8`
**Applied fix:** Applied the review's suggested fix verbatim — `createdb/0` now pattern-matches on
`ensure_repo_created/1`'s result and `raise`s a descriptive `"failed to create storage for
#{inspect(repo)}: #{inspect(term)}"` error instead of letting a bare `:ok = {:error, term}` match
fail with an opaque `MatchError`. Verified the file still parses correctly with
`Code.string_to_quoted!/1`.

### WR-04: Production Postgres connection has TLS explicitly disabled with no compensating control documented in code

**Files modified:** `config/runtime.exs`
**Commit:** `2aa113a`
**Applied fix:** Chose the "document as an accepted risk" branch of the review's two suggested
options (rather than flipping `ssl: true`, which would require provisioning a self-signed
accessory cert as a separate, out-of-scope change and risks breaking the deploy if landed without
that provisioning). Added a code comment directly above the commented-out `# ssl: true,` line
recording the accepted-risk rationale (Docker bridge network exposure, the 127.0.0.1 host-port
binding's limited scope, and the condition under which this should be revisited), following the
same `ACCEPTED RISK` comment convention already used in `.github/workflows/backup.yml`.

## Skipped Issues

### WR-02: Backup SSH command is fragile if `POSTGRES_PASSWORD` ever contains a single quote

**File:** `.github/workflows/backup.yml:51-54` (pre-fix line numbers; superseded by WR-01)
**Reason:** Already resolved as a side effect of the WR-01 fix. The WR-01 redesign eliminated the
single-quoted, locally-interpolated `PGPASSWORD='$POSTGRES_PASSWORD'` string entirely — the
password is now delivered as raw stdin data (via a here-string) and only ever read into a file by
`cat`, never re-embedded into any shell-quoted command string on either the local or remote side.
Since there is no longer any quoting construct wrapping the password value, a literal `'`
character in the password can no longer break command parsing (it is simply a byte in the
resulting env-file content, not a quote character to a shell). Applying WR-02's originally
suggested escaping fix on top would be a no-op with no code left needing it.
**Original issue:** `$POSTGRES_PASSWORD` was expanded locally into a single-quoted segment of the
remote command string; a `'` in the value would have terminated that quoted string early on the
remote shell, at best breaking the command, at worst executing unintended remote shell fragments.

---

_Fixed: 2026-07-27T20:50:21Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
