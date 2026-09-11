---
phase: 01-catalog-v1
plan: 01
subsystem: infra
tags: [ex_aws, ex_aws_s3, sweet_xml, image, nimble_csv, credentials, r2, bgg, secrets]

# Dependency graph
requires:
  - phase: 00-deploy-skeleton
    provides: working Phoenix app, CI, deploy pipeline, and the .gitignore /
      dev-secrets convention (/.kamal/secrets) this plan extends
provides:
  - Five new hex dependencies (sweet_xml, image, ex_aws, ex_aws_s3, nimble_csv) compiling cleanly
  - A gitignored config/dev.secret.exs holding real BGG + R2 credentials, with a committed
    config/dev.secret.exs.example template
  - PukllayClub.Catalog.Seed.Credentials as the single credential-resolution seam for all
    later seed-pipeline plans (D-01/D-02/D-03)
affects: [01-02, 01-03, 01-04, 01-05, 01-06]

# Actuals (#2632)
actuals:
  tokens: 7600
  tasks: 2
  commits: 3

# Tech tracking
tech-stack:
  added: [sweet_xml ~> 0.7.5, image ~> 0.72.0, ex_aws ~> 2.7, ex_aws_s3 ~> 2.5, nimble_csv ~> 1.3]
  patterns:
    - "Gitignored dev-secret config file (config/dev.secret.exs) conditionally imported from
      config/dev.exs via File.exists?/1, with a committed .example placeholder template"
    - "Single credential-resolution module (env var first, then Application config) as the only
      place any later code reads a secret from"

key-files:
  created:
    - lib/pukllay_club/catalog/seed/credentials.ex
    - test/pukllay_club/catalog/seed/credentials_test.exs
    - config/dev.secret.exs.example
    - config/dev.secret.exs (gitignored, not tracked)
  modified:
    - mix.exs
    - mix.lock
    - .gitignore
    - config/dev.exs
    - config/test.exs

key-decisions:
  - "BGG application registered and R2 catalog bucket provisioned by the user directly on
    boardgamegeek.com and the Cloudflare dashboard (human-only actions); token verified live
    against a real BGG game id before Task 2 began"
  - "R2 credentials routed through a dev-machine-only gitignored config file, not through Kamal,
    since the seed pipeline never runs on the production host"

patterns-established:
  - "Credentials.fetch!/0 / fetch/0 / redacted/1 / r2_object_url/2 as the standard shape for any
    future secret-resolution module in this codebase"

requirements-completed: [CATALOG-09]

coverage:
  - id: D1
    description: "Five Phase-1 seed dependencies (sweet_xml, image, ex_aws, ex_aws_s3, nimble_csv)
      added to mix.exs and resolving/compiling cleanly"
    requirement: CATALOG-09
    verification:
      - kind: other
        ref: "mix compile --warnings-as-errors (exit 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Gitignored config/dev.secret.exs holds real BGG + R2 credentials; a committed
      config/dev.secret.exs.example documents the shape with placeholders only; no credential is
      tracked by git"
    requirement: CATALOG-09
    verification:
      - kind: other
        ref: "git check-ignore -q config/dev.secret.exs && git ls-files config/dev.secret.exs
          (empty) && git log -p scan for literal secret values (clean)"
        status: pass
    human_judgment: false
  - id: D3
    description: "PukllayClub.Catalog.Seed.Credentials resolves all six credentials (env var
      precedence over config), raises a named multi-key error when values are missing, masks
      secrets in redacted/1 and Inspect output, and provides r2_object_url/2 for single-slash
      URL joins"
    requirement: CATALOG-09
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog/seed/credentials_test.exs (10 tests)"
        status: pass
    human_judgment: false

duration: 63min
completed: 2026-08-06
status: complete
---

# Phase 01 Plan 01: Prerequisites Summary

**Five seed dependencies (sweet_xml, image, ex_aws, ex_aws_s3, nimble_csv) landed, a gitignored dev-secret config seam wired up with real BGG + R2 credentials, and `PukllayClub.Catalog.Seed.Credentials` as the one module that resolves them with a named, actionable failure mode.**

## Performance

- **Duration:** 63 min
- **Started:** 2026-08-06T18:48:53-03:00
- **Completed:** 2026-08-06T19:51:22-03:00
- **Tasks:** 2 (Task 1 — BGG registration + R2 bucket provisioning — was cleared by the user in
  chat with the orchestrator before this executor was spawned)
- **Files modified:** 8

## Accomplishments
- Registered/verified a live BGG Bearer token and a dedicated, publicly-readable R2 catalog
  bucket (Task 1, cleared before this session — see below)
- Added `sweet_xml`, `image`, `ex_aws`, `ex_aws_s3`, `nimble_csv` to `mix.exs`; `mix deps.get` and
  `mix compile --warnings-as-errors` both pass
- Built the gitignored `config/dev.secret.exs` + committed `config/dev.secret.exs.example`
  secret-config seam, with `config/dev.exs` conditionally importing the secret file only when
  present (fresh clone / CI still compile)
- Populated `config/test.exs` with obviously-fake `PukllayClub.Catalog.Seed` values so
  seed-pipeline unit tests run in CI without real credentials
- TDD'd `PukllayClub.Catalog.Seed.Credentials`: `fetch!/0`, `fetch/0`, `redacted/1`, and
  `r2_object_url/2`, with 10 passing tests covering env-var precedence, multi-key missing errors,
  secret masking in `Inspect`/`redacted/1`, and single-slash URL joins in both directions

## Task Commits

Task 1 (checkpoint:human-action) was cleared in conversation with the orchestrator before this
executor was spawned — no code changes, nothing to commit for it.

1. **Task 2: Add the five seed dependencies and the gitignored secret-config seam** - `57f9451` (feat)
2. **Task 3: Credentials resolver with a named, actionable failure mode** - `96e9a12` (test, RED), `f933145` (feat, GREEN)

_No REFACTOR commit was needed — the GREEN implementation passed `mix quality` on the first pass
after `mix format` auto-fixed a single line-length wrap._

## Files Created/Modified
- `mix.exs` - Appended sweet_xml, image, ex_aws, ex_aws_s3, nimble_csv to deps/0
- `mix.lock` - Resolved versions pinned (including transitive `vix`, `color`)
- `.gitignore` - Added `/config/dev.secret.exs` next to the existing `/.kamal/secrets` entry
- `config/dev.exs` - Conditional `import_config "dev.secret.exs"` guarded by `File.exists?/1`
- `config/test.exs` - Added obviously-fake `PukllayClub.Catalog.Seed` test values
- `config/dev.secret.exs.example` - Committed placeholder template (tracked)
- `config/dev.secret.exs` - Real BGG + R2 credentials (gitignored, not tracked — verified via
  `git check-ignore` and `git ls-files`)
- `lib/pukllay_club/catalog/seed/credentials.ex` - `PukllayClub.Catalog.Seed.Credentials` struct +
  `fetch!/0`, `fetch/0`, `redacted/1`, `r2_object_url/2`
- `test/pukllay_club/catalog/seed/credentials_test.exs` - 10 tests covering all `<behavior>`
  requirements from the plan

## Decisions Made
- Config key for all three config files (`dev.exs` import target, `test.exs`, `dev.secret.exs`,
  `dev.secret.exs.example`) is `PukllayClub.Catalog.Seed` (not `.Credentials`) — matches the
  plan's exact spec and keeps the config namespace one level above the resolver module itself, so
  future seed modules (BGG client, R2 uploader) can share the same config block without every one
  needing its own key.
- `fetch!/0` and `fetch/0` share one internal resolution pass (`resolve/2`) so there is exactly
  one implementation of "env var first, then config, treating nil/"" as missing" rather than two
  diverging code paths.
- No REFACTOR commit — the implementation was already clean after `mix format`; a separate
  refactor commit would have been a no-op.

## Deviations from Plan

None - plan executed exactly as written. Task 1's checkpoint was already cleared by the user
before this executor was spawned; Task 2 and Task 3 were executed per their `<action>` blocks with
no auto-fixes needed.

## Issues Encountered
- Initial implementation used `@config_key __MODULE__` (i.e.
  `PukllayClub.Catalog.Seed.Credentials`) instead of the plan-specified
  `PukllayClub.Catalog.Seed` config namespace, causing the first test run to fail with all six
  keys reported missing even though `config/test.exs` had them set. Caught immediately by the RED
  test suite (Rule 1 — bug in the code just written, fixed before the GREEN commit, not tracked as
  a plan deviation since it never left the working tree in a broken state).

## User Setup Required

Task 1 was a `checkpoint:human-action` (BGG application registration + Cloudflare R2 bucket
creation and public-access enablement) and was completed by the user in conversation with the
orchestrator before this executor was spawned. The BGG token was live-verified (HTTP 200 against
`thing?id=184267`) prior to this session; no further user setup is required to proceed to
01-02 / 01-03.

## Next Phase Readiness
- `PukllayClub.Catalog.Seed.Credentials.fetch!/0` is ready for any later seed-pipeline module
  (BGG client, image downloader/resizer, R2 uploader, CSV importer) to call without re-deriving
  credential resolution.
- `01-03-PLAN.md`'s tracer slice can now begin — the external-prerequisite gate this plan existed
  to clear is closed.
- No blockers.

---
*Phase: 01-catalog-v1*
*Completed: 2026-08-06*

## Self-Check: PASSED

All created files verified present on disk (`lib/pukllay_club/catalog/seed/credentials.ex`,
`test/pukllay_club/catalog/seed/credentials_test.exs`, `config/dev.secret.exs.example`, this
SUMMARY.md). All three task commits (`57f9451`, `96e9a12`, `f933145`) verified present in
`git log --oneline --all`.
