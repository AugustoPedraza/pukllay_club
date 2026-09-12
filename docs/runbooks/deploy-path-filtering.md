# Runbook: docs-only pushes skip the build and deploy

`deploy.yml` runs a `changes` job on every push to `main` that classifies the diff. When a push
touches **only** documentation paths, `build-and-push` and `deploy` are skipped — no Docker image
is built, nothing is pushed to `ghcr.io`, and Kamal never runs. `quality` always runs regardless.
Source of truth for the exact wiring is the `changes` job in `.github/workflows/deploy.yml` itself
(this runbook does not restate its YAML).

## Which paths count as documentation

A push is classified docs-only when every changed file matches at least one of these patterns
(the `code` filter's negations, `predicate-quantifier: every`):

- `!**/*.md`
- `!*.md`
- `!.planning/**`
- `!.claude/**`
- `!docs/**`

Anything else — `lib/`, `config/`, `priv/`, `assets/`, `rel/`, `Dockerfile`,
`docker-entrypoint`, `mix.exs`, `mix.lock`, `.github/**`, `ideas.txt`, `.gsd/` — is treated as
code and still triggers a full build-and-deploy. That list is a deny-list of documentation, not
an allow-list of code, so anything not explicitly named above defaults to triggering a deploy.

## Why skipping a docs-only push is safe

`Dockerfile` never copies the whole build context — its `COPY` sources are `mix.exs`, `mix.lock`,
`config/`, `priv`, `lib`, `assets`, `rel`, `docker-entrypoint`, plus the `--from=builder` release
copy at the final stage. None of those paths overlap `.planning/`, `.claude/`, or `docs/`, so a
change confined to documentation paths provably cannot alter a single byte of the built image.
This holds even though `.dockerignore` does not exclude those paths — the Dockerfile's selective
`COPY` list is what makes the skip safe, not `.dockerignore`.

## `quality` always runs and always reports

The `quality` job in `deploy.yml` carries no `if:` and no `needs:` on the `changes` gate — it runs
on every single push to `main`, documentation-only or not, and on every pull request via
`ci.yml`'s own `quality` job (the one GitHub branch protection actually requires on PRs, since
`deploy.yml` has no `pull_request` trigger). Skipping `quality` itself was never on the table:
a required status check that stops reporting blocks merges indefinitely instead of passing them.

## The gate is fail-open

If `dorny/paths-filter` errors, is unavailable, or cannot resolve the base commit for any reason,
the push is treated as code and the normal build-and-deploy runs — it never silently skips a real
deploy. An unnecessary rebuild costs a few CI minutes; a silently skipped deploy would leave
production stale with no visible signal. Every degradation path in the gate resolves to "deploy."

## The footgun: no image exists for a docs-only commit

After a documentation-only push, `build-and-push` was skipped, so **no image is tagged with that
commit's SHA in `ghcr.io`**. Kamal computes the image version it expects to pull from the full git
SHA of whatever commit is checked out. If an operator later runs `kamal deploy --skip-push` from a
docs-only `HEAD`, Kamal's own `validate_image` check will fail, complaining that the image for
that version is missing from the registry. The error message points at the registry — it will not
mention path filtering, so if you hit this, this is why.

This is not breakage. CI-driven deploys always build the exact commit they deploy; the gap only
appears if you try to deploy a commit that CI itself decided not to build.

### Escape hatches when a deploy is genuinely wanted from a docs-only `HEAD`

- **Run Kamal locally without `--skip-push`.** This makes Kamal build and push the image itself
  before deploying, so there is no dependency on a `ghcr.io` tag CI never created.
- **Land any commit that touches a non-documentation path**, even a trivial one, and let the
  normal CI build-then-deploy pass run.

**Not an escape hatch:** re-running the skipped `deploy.yml` workflow run in the GitHub Actions
UI. A re-run re-evaluates the same diff against the same base commit, gets classified docs-only
again, and skips `build-and-push`/`deploy` again.

## How to confirm the gate behaved correctly

On the next docs-only push to `main` (any GSD planning commit under `.planning/` qualifies), run:

```bash
gh run list --workflow=deploy.yml --limit 3
```

Open the newest run: `quality` should show a green result, while `build-and-push` and `deploy`
show as skipped. On the next push that touches a non-documentation path, all four jobs
(`changes`, `quality`, `build-and-push`, `deploy`) should run and the site should redeploy.
