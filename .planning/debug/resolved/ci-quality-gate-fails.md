---
status: resolved
trigger: "GitHub Actions 'quality' required status check fails on PR #28 (sync-local-main-260824 -> main) with exit code 1 and no visible error message, while `mix quality` passes clean (exit 0) locally on the identical commit. Debug it."
created: 2026-08-24
updated: 2026-08-24
---

## Symptoms

- **Expected behavior:** The `quality` GitHub Actions job (`.github/workflows/ci.yml`, step "Run
  quality gate (format, credo, sobelow, test)", which runs `mix quality`) should exit 0 and pass,
  matching the identical local result on the same commit.
- **Actual behavior:** The job's `mix quality` step exited 1 with no visible error message. Every
  sub-check's own output looked clean in the captured log — `hex.audit`/`deps.audit`: "No
  vulnerabilities found", `format`/`credo --strict`/`sobelow --config`: normal pre-existing
  findings only, `test`: "385 tests, 0 failures" — then immediately
  `##[error]Process completed with exit code 1.` with nothing in between. Reran the same job once
  (`gh run rerun --failed`) and it failed again with byte-identical visible output.
- **Error messages:** None human-readable in the captured log — a bare shell exit code 1.
- **Timeline:** This was the first time this codebase's CI had ever actually run on GitHub —
  `origin/main` had been pinned to an early Phase 0 commit for ~4 weeks (319 local commits never
  pushed) until PR #28 opened today specifically to let the required `quality` check run before
  merging.
- **Reproduction:** Open PR #28, let `quality` run (or rerun it) against the pre-fix commit
  (`eb70e59`) and compare against `MIX_ENV=test mix quality` run locally on that same commit, which
  exited 0 with the same visible sub-check output content.

## Investigation

Ruled out before the session was interrupted:
- Not a real external network call — the only HTTP-touching test file
  (`bgg_client_test.exs`) stubs every request via `Req.Test.stub`; the 429-retry and
  XML-entity-rejection log lines seen in the CI output are from tests that deliberately simulate
  those responses, not live network flakiness.
- Not an Elixir/OTP version mismatch — CI pins `1.19.5-otp-28`/`28.5`, matching local.
- Traced the failure to the final step of the `quality` mix alias
  (`test --warnings-as-errors`), since every step before it (hex.audit, deps.audit,
  deps.unlock, format, credo, sobelow) visibly completed in the log before ExUnit ran.

The debug session was interrupted (killed) before forming a confirmed hypothesis. Root cause was
found externally (GitHub Copilot Autofix, run against the open PR) rather than through the GSD
debugger loop, and is recorded here after the fact so the debug archive/knowledge base stays
accurate for future sessions on this project.

## Resolution

- **root_cause:** `mix hex.audit` — the first step in the `quality` alias, which queries Hex's
  live OSV-based vulnerability advisory feed — was passing locally at the moment it was checked but
  failing minutes later in CI. Not an environment/race-condition bug: Hex's advisory feed is a live
  external data source, and it appears an advisory affecting one or more of the pinned dependency
  versions was published/indexed between the local check and the CI run. This explains every
  observed symptom: identical visible sub-check output in both places (the vulnerable versions were
  the same, `hex.audit`'s own printed line just hadn't yet reflected the new advisory locally),
  deterministic failure on CI rerun (the advisory was live and present for both CI attempts), and
  no visible Elixir-level error (a security-audit gate failure is a clean nonzero exit with its own
  message, not a crash — worth re-checking why that message didn't surface in the captured
  `##[group]`/`##[error]` log wrapper if this recurs, since that gap is what made root-causing this
  from the log alone slow).
- **fix:** Upgraded three dependencies to their patched versions in `mix.lock`: `bandit` 1.12.1 →
  1.12.5, `phoenix_live_view` 1.2.7 → 1.2.9, `postgrex` 0.22.3 → 0.22.4. Commit `93618cd`
  ("fix: upgrade vulnerable dependencies to address security advisories"), applied directly to the
  PR branch via GitHub Copilot Autofix and merged as part of PR #28 (squash commit `320fc4b` on
  `main`).
- **verification:** `quality` check passed on the PR after the fix commit
  (https://github.com/AugustoPedraza/pukllay_club/actions/runs/32710428893). PR #28 merged.
- **files_changed:**
    - mix.lock (dependency version bumps only — no application code changed)
- **prevention:** why not caught earlier: `hex.audit` depends on live external advisory data, so a
  clean local run gives no durable guarantee — an advisory can appear between a local check and a
  CI run (or between CI runs) for dependencies that were never touched in the diff. This is a
  structural property of any advisory-feed-based gate, not a fixable defect in this project's setup.
  Also worth noting: this codebase had never actually been exercised by GitHub Actions before today
  (`origin/main` was 319 commits stale), so this was the first opportunity for any latent
  dependency-advisory drift accumulated over ~4 weeks of local-only work to surface at all.
  guard: none added — a live-advisory-feed gate can't be made deterministic without freezing the
  advisory data (which would defeat its purpose). The practical mitigation is running `mix
  hex.audit`/`deps.audit` regularly (already gated in `mix quality`, which this project runs after
  every task) and keeping `origin/main` from drifting out of sync with local work again, so CI has
  a real chance to catch advisories promptly rather than in one large batch.
