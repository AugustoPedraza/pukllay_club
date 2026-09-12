---
phase: quick-260912-hrx
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .github/workflows/deploy.yml
  - docs/runbooks/deploy-path-filtering.md
  - .planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py
autonomous: true
requirements: [QUICK-260912-HRX-01]

estimate:
  tokens: 25000
  raw_tokens: 25000
  tasks: 2
  confidence: low

must_haves:
  truths:
    - "A push to main whose diff touches only `.planning/**`, `.claude/**`, `docs/**`, or any `*.md` runs `quality` and skips both `build-and-push` and `deploy`."
    - "A push to main touching any other path (lib/, config/, priv/, assets/, rel/, Dockerfile, docker-entrypoint, mix.exs, mix.lock, .github/**) still builds and deploys exactly as it does today."
    - "`quality` in deploy.yml runs on every push with no `if:` and no `needs:` — it never becomes conditional on the gate."
    - "ci.yml's `quality` job (the job whose name main's branch protection actually requires on PRs) is not modified by this change."
    - "If the filter action errors, is unavailable, or cannot resolve the base commit, the workflow deploys anyway — it never silently skips a real deploy."
  artifacts:
    - .github/workflows/deploy.yml
    - docs/runbooks/deploy-path-filtering.md
    - .planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py
  key_links:
    - "`changes.outputs.code` -> `build-and-push.if` -> `deploy.if` — the whole gate chain; a typo in the output name yields an empty string, which the fail-open expression resolves to deploy."
    - "`build-and-push.needs` must keep `quality` while gaining `changes` — dropping `quality` would let a broken merge reach production (D-04)."
    - "deploy.yml `quality` job name <-> branch protection's required check name — must stay unconditional."
    - "docs path list <-> Dockerfile's selective COPY set — the docs list is only safe to skip because no COPY pulls the whole build context."
---

<objective>
Stop rebuilding the Docker image and redeploying to the GCP e2-micro for documentation-only
pushes to main. Roughly 590 of this repo's tracked markdown files live under `.planning/` and
`.claude/`, and every GSD planning commit currently triggers a full Elixir release build, a ghcr.io
push, and a Kamal deploy that cannot change a single byte of the running app.

Purpose: cut wasted CI minutes and pointless production container swaps, without ever weakening the
`quality` required status check or risking a skipped real deploy.
Output: an always-run `changes` gate job in deploy.yml that classifies the push, `build-and-push`
and `deploy` made conditional on it, an operator runbook, and a committed structural checker that
proves the gate is wired and `quality` stayed unconditional.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.github/workflows/deploy.yml
@.github/workflows/ci.yml
@Dockerfile

Grounding already established at plan time (do not re-derive):

- **Two workflows define a job named `quality`.** `ci.yml` runs on `pull_request` AND `push` to
  main; `deploy.yml` runs on `push` to main only. Branch protection requires a check named
  `quality`; on a PR only ci.yml can report it. **ci.yml is therefore the required check and is
  out of scope — do not touch it.** deploy.yml's `quality` is the D-04 re-run guard against a
  broken merge and also stays unconditional, per this task's constraints.
- **deploy.yml has no `pull_request` trigger** (`on: push: branches: [main]` only).
- **The Dockerfile never copies the whole build context.** Its COPY sources are `mix.exs`,
  `mix.lock`, `config/`, `priv`, `lib`, `assets`, `rel`, `docker-entrypoint`, plus the
  `--from=builder` release copy. This is the load-bearing reason a docs-only change provably
  cannot alter the built image. `.dockerignore` does *not* exclude `.planning/` or `docs/`, so
  the Dockerfile's selective COPY is the only thing making this safe — the checker asserts it.
- **Action pinning convention in this repo:** moving major tag (`actions/checkout@v4`,
  `docker/build-push-action@v6`, `erlef/setup-beam@v1`), with one exact-version exception
  (`webfactory/ssh-agent@v0.9.0`, because `v0.9` was not a resolvable tag). Match the major-tag
  convention.
- **`dorny/paths-filter` facts verified against the action's own v4 `action.yml` at plan time:**
  current major is `v4` (v4.0.3, runtime `node24`; `v3` still exists but is the older major).
  It accepts `predicate-quantifier` with values `some` (default), `every` ("file is included only
  if it matches all of the patterns"), and `some-with-excludes`. Its `base` input defaults to the
  repository default branch, and "if it references same branch it was pushed to, changes are
  detected against the most recent commit before the push" — which is exactly the wanted behavior
  for push-to-main, so `base` is left unset. Patterns are evaluated with picomatch.
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Wire the always-run changes gate through build-and-push and deploy</name>
  <files>.planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py, .github/workflows/deploy.yml</files>
  <behavior>
    - RED: run the checker against the unmodified deploy.yml. It must exit 1 with exactly these
      five failures — no `changes` gate job; build-and-push does not need `changes`; build-and-push
      is not gated on needs.changes.outputs.code; deploy does not need `changes`; deploy is not
      gated on needs.changes.outputs.code. Any other RED output means the repo drifted from plan
      time — stop and report rather than editing.
    - The same RED run must NOT report anything about `quality` or the Dockerfile: those
      invariants already hold today, which is what makes them regression assertions rather than
      goals.
    - GREEN: after the deploy.yml edit the checker exits 0.
  </behavior>
  <action>
    First write the checker verbatim from this plan's `<verification>` section to
    `.planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py` and run it
    from the repo root to observe the RED state above. It is a planning artifact under `.planning/`
    on purpose: it is developer/executor-invoked, never added to `mix quality` or to CI, and it is
    itself docs-only so it can never trigger a deploy.

    Then edit `.github/workflows/deploy.yml` only. Leave `on:`, `permissions:`, the `quality` job,
    and every existing step and comment byte-identical. Do not add a `workflow_dispatch` trigger
    (it would create an unreviewed deploy path around a protected branch). Do not open or modify
    `.github/workflows/ci.yml`.

    Add a new first job under `jobs:` named `changes`, placed above `quality`, with
    `runs-on: ubuntu-latest` and a job-level `permissions:` of `contents: read` (least privilege —
    this job runs third-party code and must not inherit anything the deploy job uses). Give it an
    `outputs:` map whose `code` key is the expression `steps.filter.outputs.code != 'false'`. That
    comparison, rather than reading the raw output, is what makes the gate fail-open: an empty
    output from a failed or skipped step is not the literal string `false`, so it resolves to true
    and the deploy proceeds.

    Its steps are exactly two. Step one is `Checkout` using `actions/checkout@v4` with
    `fetch-depth: 0`, because the filter compares a same-branch push against the commit before the
    push and full history guarantees that commit is present locally. Step two is
    `Classify changed paths` with `id: filter`, `uses: dorny/paths-filter@v4`, and
    `continue-on-error: true`. Under `with:`, set `predicate-quantifier: 'every'` (quoted) and a
    `filters:` block-scalar defining a single filter named `code` whose five entries are, in order,
    the quoted negations of `**/*.md`, `*.md`, `.planning/**`, `.claude/**`, and `docs/**`.

    The quantifier is load-bearing. Under the default `some`, those negations are OR'd, so a
    `.planning` markdown file would satisfy "not under .claude" and be classed as code. With
    `every`, a file counts as code only if it is simultaneously not markdown, not under
    `.planning`, not under `.claude`, and not under `docs` — which is the intended "anything that
    is not documentation" semantics. Note for your own confidence while editing: even that
    mis-quantified failure mode deploys rather than skips.

    Keep this list a deny-list of documentation paths, never an allow-list of code paths, so a
    source directory added in a future phase is treated as code by default. `ideas.txt`, `.gsd/`,
    and `.github/**` are deliberately outside the documentation list and will keep triggering
    deploys; that is the conservative direction and is intended, not an oversight.

    Then change `build-and-push` from `needs: quality` to `needs: [changes, quality]` and add
    `if: needs.changes.outputs.code == 'true'`. Retaining `quality` in that list is required —
    it is the D-04 guard that keeps a broken merge from reaching production. Change `deploy` from
    `needs: build-and-push` to `needs: [changes, build-and-push]` and add the identical `if:`.
    A skipped need already skips its dependents, so deploy's condition is redundant today; state
    it anyway so the gate survives a future edit that relaxes this job's `needs`.

    Comment the new job in this file's established voice — dense inline comments explaining
    non-obvious choices. Cover at minimum: why `quality` is deliberately not a dependency of the
    gate (a required status check that never reports blocks merges indefinitely), why the output
    expression is fail-open and which direction of failure is cheap, why `every` is set, and why
    the list is a deny-list.
  </action>
  <verify>
    <automated>cd "$(git rev-parse --show-toplevel)" && python3 .planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py</automated>
  </verify>
  <done>
    The checker prints the single OK line and exits 0. `git diff --stat` shows
    `.github/workflows/deploy.yml` as the only modified tracked file, and
    `git diff -- .github/workflows/ci.yml` is empty. Parsing deploy.yml shows four jobs where
    `changes` and `quality` each carry no `needs` and no `if`, while `build-and-push` and `deploy`
    each need `changes` and are gated on `needs.changes.outputs.code == 'true'`.
  </done>
</task>

<task type="auto">
  <name>Task 2: Document the skip semantics and the missing-image footgun for operators</name>
  <files>docs/runbooks/deploy-path-filtering.md</files>
  <action>
    Create a short runbook alongside the existing `docs/runbooks/catalog-seed.md`, written in the
    same operator-facing register. It exists because this change introduces one genuinely
    surprising operational consequence that nobody will find by reading workflow comments.

    That consequence: after a documentation-only push, no image is tagged with that commit's SHA in
    ghcr.io, because `build-and-push` was skipped. Kamal computes its image version from the
    checked-out commit's full git SHA, so an operator who later runs `kamal deploy --skip-push`
    from a docs-only HEAD will hit a Kamal `validate_image` failure complaining that the image for
    that version is missing. This is not breakage — CI-driven deploys always build the commit they
    deploy — but the error message points at the registry, not at path filtering, so document the
    connection explicitly.

    Give the operator the two real escape hatches when a deploy is genuinely wanted from a docs-only
    HEAD: run Kamal locally without the skip-push flag so it builds and pushes the image itself, or
    land any commit that touches a non-documentation path and let CI do its normal build-then-deploy
    pass. Re-running the skipped workflow is not an escape hatch — it re-evaluates the same diff and
    skips again.

    Also cover, briefly: which paths are treated as documentation (reproduce all five filter
    patterns exactly as they appear in the workflow, so the checker's drift assertion can match
    them), why skipping is provably safe (the Dockerfile copies named paths, never the whole build
    context, so a documentation change cannot alter the image), that `quality` still runs on every
    single push and PR so the required status check always reports, and that the gate is fail-open
    so an action or runner failure produces an unnecessary deploy rather than a missed one.

    Do not restate the full workflow YAML in the runbook — point at
    `.github/workflows/deploy.yml`'s `changes` job as the source of truth.
  </action>
  <verify>
    <automated>cd "$(git rev-parse --show-toplevel)" && python3 .planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py && test -f docs/runbooks/deploy-path-filtering.md</automated>
    <human-check>On the next docs-only push to main (any GSD planning commit), run `gh run list --workflow=deploy.yml --limit 3` and open the newest run: `quality` shows a green result while `build-and-push` and `deploy` show as skipped. On the next code-touching push, all four jobs run and the site is redeployed.</human-check>
  </verify>
  <done>
    `docs/runbooks/deploy-path-filtering.md` exists, the checker's drift assertions pass (it
    contains all five filter patterns verbatim plus `validate_image` and `--skip-push`), and the
    checker still exits 0.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| pushed diff -> gate job | The content of the push (attacker- or mistake-influenced file paths) now decides whether the build/deploy boundary is crossed at all |
| third-party action -> job runtime | `dorny/paths-filter@v4` executes vendored JavaScript on the runner with a GitHub token |
| CI runner -> production host | Unchanged by this plan (registry push + Kamal SSH), but the new gate is what decides whether it is crossed |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-QH-01 | Tampering | `changes` job running `dorny/paths-filter@v4` | medium | mitigate | Job-level `permissions: contents: read` so the action never sees `packages: write` or any deploy secret — `SECRET_KEY_BASE`, `DATABASE_URL`, `DEPLOY_SSH_KEY`, `POSTGRES_PASSWORD` are referenced only in the `deploy` job's own env and remain unreachable from this job. Pinned to the `v4` major tag, matching the convention already used by all nine actions in this repo. |
| T-QH-02 | Tampering | gate classification logic | high | mitigate | A misclassification that skips a real deploy leaves production silently stale — the worse failure mode. Mitigated on four independent axes: `predicate-quantifier: 'every'` gives correct AND-of-negations semantics; the output expression `!= 'false'` resolves any empty/absent output to deploy; `continue-on-error: true` turns an action failure into a deploy rather than a skip; `fetch-depth: 0` prevents a silent base-commit resolution failure. Every degradation path deploys. |
| T-QH-03 | Elevation of Privilege | `quality` required status check | high | mitigate | A path-filtered required check that never reports blocks merges indefinitely, and inviting a "just make it non-required" fix would remove the quality gate from main entirely. Mitigated by leaving `quality` with no `if:` and no `needs:` in deploy.yml, not touching ci.yml at all (it is the workflow that reports on PRs), and asserting both structurally in the committed checker. |
| T-QH-04 | Repudiation | deploy provenance | low | accept | Docs-only commits will have no corresponding image in ghcr.io, so the registry no longer holds an image for every main commit. Accepted: the deployed image's tag is still the exact SHA of the code commit that produced it, which is the property that matters for tracing production back to source. Documented in the Task 2 runbook. |
| T-QH-SC | Tampering | supply chain | medium | mitigate | This plan runs no npm/pip/cargo install, so the package-legitimacy gate does not apply. The one new third-party dependency is the GitHub Action itself, verified at plan time against `dorny/paths-filter`'s own published `action.yml` and release tags on the real repository rather than from memory; residual risk of a moving major tag is bounded by T-QH-01's least-privilege job scope. |
</threat_model>

<verification>
Write this file verbatim to
`.planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py`. It was
authored and exercised at plan time against three states: RED on the current repo (five failures,
exit 1), GREEN on a simulated target workflow (exit 0), and drift-detecting when a stub runbook is
present (seven failures, exit 1).

It asserts structure by parsing YAML, not by grepping for text, so a comment mentioning `if:` or
`needs:` can never satisfy or break an assertion.

```python
import sys, re, yaml

DOCS = ("!**/*.md", "!*.md", "!.planning/**", "!.claude/**", "!docs/**")
f = []

def key(d):  # PyYAML (YAML 1.1) parses a bare `on:` key as boolean True
    return "on" if "on" in d else True

dep = yaml.safe_load(open(".github/workflows/deploy.yml"))
ci = yaml.safe_load(open(".github/workflows/ci.yml"))
j = dep["jobs"]

# 1. quality in deploy.yml must stay unconditional and independent of the gate
q = j["quality"]
if "if" in q: f.append("deploy.yml quality has an `if:` - required check must never be conditional")
if "needs" in q: f.append("deploy.yml quality gained `needs:` - must not depend on the gate")

# 2. ci.yml quality (the job branch protection actually requires on PRs) untouched
cq = ci["jobs"]["quality"]
if "if" in cq: f.append("ci.yml quality has an `if:`")
if "needs" in cq: f.append("ci.yml quality has `needs:`")

# 3. gate job
if "changes" not in j:
    f.append("no `changes` gate job")
else:
    g = j["changes"]
    if g.get("permissions") != {"contents": "read"}: f.append("gate job not scoped to contents:read")
    if "code" not in (g.get("outputs") or {}): f.append("gate job exposes no `code` output")
    elif "!= 'false'" not in g["outputs"]["code"]: f.append("gate output is not fail-open (`!= 'false'`)")
    steps = g.get("steps", [])
    co = [s for s in steps if str(s.get("uses", "")).startswith("actions/checkout@")]
    if not co or (co[0].get("with") or {}).get("fetch-depth") != 0:
        f.append("gate checkout lacks fetch-depth: 0")
    pf = [s for s in steps if str(s.get("uses", "")).startswith("dorny/paths-filter@")]
    if not pf:
        f.append("gate job does not use dorny/paths-filter")
    else:
        s = pf[0]
        if s["uses"] != "dorny/paths-filter@v4": f.append("paths-filter not pinned to @v4: " + s["uses"])
        if s.get("continue-on-error") is not True: f.append("paths-filter step is not continue-on-error (fail-open)")
        w = s.get("with") or {}
        if w.get("predicate-quantifier") != "every":
            f.append("predicate-quantifier is not 'every' - OR'd negations invert the logic")
        pats = tuple((yaml.safe_load(w.get("filters", "")) or {}).get("code", []))
        if pats != DOCS: f.append("filter patterns %r != expected %r" % (pats, DOCS))

# 4. both heavy jobs gated on the gate output, build still gated on quality
for name, extra in (("build-and-push", "quality"), ("deploy", "build-and-push")):
    job = j[name]
    needs = job.get("needs", [])
    needs = [needs] if isinstance(needs, str) else needs
    if "changes" not in needs: f.append("%s does not need `changes`" % name)
    if extra not in needs: f.append("%s lost its `needs: %s`" % (name, extra))
    if "needs.changes.outputs.code == 'true'" not in str(job.get("if", "")):
        f.append("%s is not gated on needs.changes.outputs.code" % name)

# 5. load-bearing invariant: docs paths cannot reach the image (no catch-all COPY)
for line in open("Dockerfile"):
    m = re.match(r"\s*COPY\s+(.*)", line)
    if not m or "--from=" in line: continue
    for src in m.group(1).split()[:-1]:
        if src in (".", "./") or src.startswith(("docs", ".planning", ".claude")) or src.endswith(".md"):
            f.append("Dockerfile COPY pulls a docs path into the image: " + line.strip())

# 6. once the runbook exists it must not drift from the real filter patterns
import os
RB = "docs/runbooks/deploy-path-filtering.md"
if os.path.exists(RB):
    t = open(RB).read()
    for p in DOCS:
        if p not in t: f.append("runbook omits filter pattern " + p)
    for k in ("validate_image", "--skip-push"):
        if k not in t: f.append("runbook does not cover " + k)

print("\n".join("FAIL: " + x for x in f) if f else "OK: path-filter gate wired, quality unconditional")
sys.exit(1 if f else 0)
```

Phase-level checks:

1. `python3 .planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/check_gate.py`
   exits 0 from the repo root.
2. `git diff -- .github/workflows/ci.yml` is empty — the required check's workflow is untouched.
3. No Elixir source changed, so `mix quality` is unaffected; CI will run it on the PR as usual.
4. Human check (deferred per this project's `human_verify_mode: end-of-phase`): the next docs-only
   push to main shows `quality` green with `build-and-push` and `deploy` skipped; the next
   code-touching push runs all four jobs and redeploys.
</verification>

<success_criteria>
- Docs-only pushes to main no longer build a Docker image or run Kamal; `quality` still runs.
- Code, config, Dockerfile, and workflow changes still build and deploy with unchanged behavior.
- `quality` carries no `if:` and no `needs:` in deploy.yml; ci.yml is byte-identical.
- Every failure path of the gate (action error, runner incompatibility, base-commit lookup failure,
  wrong quantifier) results in a deploy, never a silent skip.
- The committed checker reproduces all of the above structurally and is runnable by hand.
</success_criteria>

<output>
Land via a short branch + PR (main is branch-protected and rejects direct pushes — see CLAUDE.md
"Git Sync Discipline"). Suggested commit subject: `ci: skip build and deploy for docs-only pushes`.

Create `.planning/quick/260912-hrx-add-path-based-filtering-to-github-workf/260912-hrx-SUMMARY.md`
when done.
</output>
