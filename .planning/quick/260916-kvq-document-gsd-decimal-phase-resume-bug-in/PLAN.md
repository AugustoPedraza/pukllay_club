---
quick_id: 260916-kvq
slug: document-gsd-decimal-phase-resume-bug-in
type: quick
date: 2026-09-16
files_modified:
  - .claude/CLAUDE.md
roadmap_phase: none
autonomous: true
---

## Objective

Record, in `.claude/CLAUDE.md`, a verified GSD bug: `execute-phase.md`'s `safe_resume_gate`
cannot detect partially-executed plans in decimal-numbered phases (`01.7`, `01.8`, `01.8.1`),
so a bare `/gsd-execute-phase` would silently re-run a half-done plan from Task 1.

This is documentation only. No code, no tests, no ROADMAP phase line (a phase line would
create a permanent W006 for a quick task).

## Context

Discovered 2026-09-16 while deciding how to resume phase 01.8.1's plan 14 (production
rollout), which has production commits but no SUMMARY.

Verified empirically in this session:

```
$ PHASE_N=$((10#01.8.1))
zsh: bad floating point constant

$ git log --oneline -E --grep='^[a-z]+\((0*1)-(0*14)\):' -30
(no output — 0 commits)

$ git log --oneline --grep='01.8.1-14' -5
0baeafc feat(01.8.1-14): add production rollout smoke script with pre-deploy baseline
```

## Tasks

<task type="auto">
  <name>Task 1: Add the "GSD Decimal-Phase Resume Bug" section to CLAUDE.md</name>
  <files>.claude/CLAUDE.md</files>
  <read_first>
    .claude/CLAUDE.md lines 188-226 — the existing "## Git Sync Discipline" section, for prose
    style and heading level, and the exact insertion boundary described below.
  </read_first>
  <behavior>
    A new `## GSD Decimal-Phase Resume Bug` section exists in CLAUDE.md, placed after the
    Git Sync Discipline section's last bullet and BEFORE the `<!-- GSD:conventions-start -->`
    marker. No other section is modified.
  </behavior>
  <action>
    INSERTION BOUNDARY (critical). The Git Sync Discipline section's final content is the
    bullet ending:

        `git fetch origin && git checkout main && git merge --ff-only origin/main`.

    Immediately after it comes a blank line, then the GSD-managed block marker
    `<!-- GSD:conventions-start source:CONVENTIONS.md -->`.

    Insert the new section AFTER that final bullet and BEFORE the
    `<!-- GSD:conventions-start ... -->` marker. Content placed inside the
    GSD:conventions-start/end block is machine-managed and WILL be overwritten by a future
    GSD docs regeneration — the new section must sit outside it.

    Match the existing section's style: `##` heading, a bolded lead-in for the root cause,
    prose paragraphs wrapped at roughly 88 columns, bolded lead-ins on actionable bullets,
    and fenced code blocks for commands and regexes.

    The section must record all six points:

    1. `safe_resume_gate` computes `PHASE_N=$((10#{phase_number}))`, which errors with
       `bad floating point constant` on this project's decimal phase numbers
       (`01.7`, `01.8`, `01.8.1`).
    2. Even if that arithmetic resolved, the gate's anchored regex
       `^[a-z]+\((0*PHASE_N)-(0*PLAN_N)\):` expects a scope like `feat(1-14):`, but real
       commits in this repo are scoped `feat(01.8.1-14):` — so it matches 0 commits.
       Verified empirically against commit `0baeafc` on 2026-09-16.
    3. Consequence: a plan that has production commits but no SUMMARY is NOT detected as
       partially executed. Because the `has_summary` filter only skips plans that HAVE a
       summary, `execute-phase` dispatches an executor that re-runs the plan from Task 1.
    4. The concrete near-miss: plan `01.8.1-14` Task 1 captures a PRE-deploy baseline via
       `--baseline` into `01.8.1-prod-baseline.json` (`sitemap_count: 435`). Re-running it
       AFTER a deploy would overwrite that with the post-deploy count, making Task 3's
       `--expect-baseline` comparison pass trivially — silently destroying the only check
       that proves the one-way `games.status` migration did not unpublish the live catalog.
    5. The workaround: for a half-executed plan in a decimal phase, do NOT run a bare
       `/gsd-execute-phase`. Writing the SUMMARY first is also wrong, because `has_summary`
       then skips the plan's remaining tasks entirely. Instead use the recovery option
       `safe_resume_gate` itself documents — "close out manually: inspect commits, write
       SUMMARY.md, then update STATE/ROADMAP" — i.e. run the remaining tasks' steps
       directly, then write the SUMMARY covering all tasks.
    6. Note that this shares a root shape with the `branching_strategy: "none"` mismatch
       documented in the preceding section: GSD assumptions that do not hold for this
       repo's decimal-insertion convention.
  </action>
  <verify>
    <automated>grep -c "^## GSD Decimal-Phase Resume Bug" .claude/CLAUDE.md</automated>
    <fails_when>output is not exactly 1</fails_when>
    <automated>awk '/^## GSD Decimal-Phase Resume Bug/{f=1} /GSD:conventions-start/{if(f)print "AFTER_MARKER"; exit}' .claude/CLAUDE.md</automated>
    <fails_when>prints nothing (section is missing, or sits after the conventions marker instead of before it)</fails_when>
    <automated>git diff --name-only</automated>
    <fails_when>any file other than .claude/CLAUDE.md appears</fails_when>
  </verify>
  <acceptance_criteria>
    - `.claude/CLAUDE.md` contains exactly one `## GSD Decimal-Phase Resume Bug` heading.
    - The new section appears AFTER the Git Sync Discipline bullets and BEFORE
      `<!-- GSD:conventions-start source:CONVENTIONS.md -->`.
    - All six points above are present and factually intact — especially the
      `bad floating point constant` error string, the `feat(01.8.1-14):` vs `feat(1-14):`
      contrast, `sitemap_count: 435`, and the "do NOT write the SUMMARY first" warning.
    - `git diff --name-only` lists only `.claude/CLAUDE.md`.
    - No content was added inside the `GSD:conventions-start`/`end` block.
  </acceptance_criteria>
  <done>A future session reading CLAUDE.md learns, before touching /gsd-execute-phase on a
  decimal phase, that the resume guard is blind there and what to do instead.</done>
</task>

## Out of Scope

- Fixing the GSD bug itself (it lives in `~/.claude/gsd-core/`, not this repo).
- Any change to `.planning/` artifacts, ROADMAP.md, or plan 01.8.1-14.
- Any other section of CLAUDE.md.
