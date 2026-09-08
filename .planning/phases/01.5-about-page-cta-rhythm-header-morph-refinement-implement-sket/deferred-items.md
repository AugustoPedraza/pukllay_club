# Deferred Items — Phase 01.5

Out-of-scope discoveries logged during plan execution, per the executor's SCOPE BOUNDARY rule
(only auto-fix issues directly caused by the current task's changes).

## 01.5-02: pre-existing `mix format --check-formatted` drift in two Plan 01.5-01 files

**Found during:** Task 3 final verification (plan-level `mix format --check-formatted`, whole
project).

**Issue:** A bare, project-wide `mix format --check-formatted` reports two files as not
formatted:
- `test/pukllay_club_web/about_header_morph_test.exs`
- `test/pukllay_club_web/components/layouts_test.exs`

Both files are byte-identical to the worktree's base commit (`c986ba93679c2da3ef824958f3c3e87b9c586523`,
the post-Plan-01.5-01-merge state) — plan 01.5-02 never touched either file. Plan 01.5-01's own
SUMMARY.md claims `mix format --check-formatted` was clean at the time it ran ("Full suite re-run:
847 tests, 0 failures. `mix compile --warnings-as-errors` and `mix format --check-formatted` both
clean."), so this is either an environment/Styler-version difference between that session and this
one, or a check that was run more narrowly than the full project at the time.

**Not fixed here:** out of scope for plan 01.5-02 per the SCOPE BOUNDARY rule — these files were not
modified by this plan's tasks, and every task-level `<verify>` in 01.5-02's own PLAN.md scopes its
`mix format --check-formatted` call to the file(s) that plan actually touches
(`lib/pukllay_club_web/live/about_live.ex`), which is clean. Every file plan 01.5-02 modified passes
`mix format --check-formatted` individually; confirmed via
`mix format --check-formatted lib/pukllay_club_web/live/about_live.ex test/pukllay_club_web/live/about_live_test.exs`
(exit 0).

**Recommended resolution:** re-run `mix format` on the two named files as a small, separate
housekeeping change (or during the next plan/phase that touches either file), and confirm the
Styler rewrite is safe per this project's own "review every Styler diff" convention before
committing.
