---
quick_id: 260916-kvq
slug: document-gsd-decimal-phase-resume-bug-in
type: quick
date: 2026-09-16
status: complete
roadmap_phase: none
files_modified:
  - .claude/CLAUDE.md
commits: 1
plan_head_before: 06af63a873c0089b587e577466d7b178ed94e6fa
---

# Quick 260916-kvq: Document the GSD decimal-phase resume bug

Recorded a verified GSD defect in `.claude/CLAUDE.md`: `execute-phase.md`'s
`safe_resume_gate` is blind to partially-executed plans in decimal-numbered phases
(`01.7`, `01.8`, `01.8.1`), so a bare `/gsd-execute-phase` would silently re-run a
half-done plan from Task 1.

## What changed

One new `## GSD Decimal-Phase Resume Bug` section in `.claude/CLAUDE.md` — 60 inserted
lines, zero deletions, single file. Placed immediately after the Git Sync Discipline
section's final bullet and **before** the `<!-- GSD:conventions-start source:CONVENTIONS.md -->`
marker, so it sits outside the machine-managed block that a future GSD docs regeneration
would overwrite. The `GSD:conventions-start`/`end` block was verified intact after the edit.

The section records all six points the plan required:

1. `PHASE_N=$((10#{phase_number}))` aborts with `bad floating point constant` on this
   repo's decimal phase numbers.
2. Even if that arithmetic resolved, the anchored scope regex
   `^[a-z]+\((0*PHASE_N)-(0*PLAN_N)\):` expects `feat(1-14):` while real commits are
   scoped `feat(01.8.1-14):` — zero matches. Verified against commit `0baeafc`.
3. Consequence: a plan with production commits but no SUMMARY is not detected as
   partially executed, because `has_summary` only skips plans that *have* a summary.
4. The concrete near-miss: `01.8.1-14` Task 1 writes the pre-deploy baseline
   (`sitemap_count: 435`); re-running it post-deploy would make Task 3's
   `--expect-baseline` check pass trivially, destroying the only proof that the one-way
   `games.status` migration did not unpublish the live catalog.
5. The workaround — and the explicit "do NOT write the SUMMARY first" warning, since that
   flips the plan into the opposite failure mode where `has_summary` skips its remaining
   tasks entirely. Correct path is the manual close-out `safe_resume_gate` documents.
6. The shared root shape with the `branching_strategy: "none"` mismatch documented in the
   preceding section.

## Verification

All three of the plan's `<automated>` checks ran; no `<fails_when>` condition was met.

```
=== VERIFY 1 ===  grep -c "^## GSD Decimal-Phase Resume Bug" .claude/CLAUDE.md
1
=== VERIFY 2 ===  awk '/^## GSD Decimal-Phase Resume Bug/{f=1} /GSD:conventions-start/{if(f)print "AFTER_MARKER"; exit}' .claude/CLAUDE.md
AFTER_MARKER
=== VERIFY 3 ===  git diff --name-only
.claude/CLAUDE.md
```

- Verify 1 output is exactly `1` (fails_when: not exactly 1) — pass.
- Verify 2 printed `AFTER_MARKER` (fails_when: prints nothing) — pass, confirming the
  section precedes the conventions marker.
- Verify 3 listed only `.claude/CLAUDE.md` (fails_when: any other file) — pass.

Supplementary: `git diff --stat` reported `1 file changed, 60 insertions(+)` with zero
deletion lines, confirming a pure insertion.

## Deviations from Plan

The quick task directory was untracked in the primary checkout, so it did not exist in
this worktree. `PLAN.md` was copied into the worktree's
`.planning/quick/260916-kvq-.../` directory so the plan and its summary commit alongside
the change. No plan content was altered.

Otherwise: none — plan executed exactly as written.

## Out of scope (respected)

No fix to GSD itself (lives in `~/.claude/gsd-core/`), no ROADMAP phase line, no other
`.planning/` artifact touched, no other CLAUDE.md section modified.
