# Deferred Items — Phase 01.4

Out-of-scope discoveries logged during plan execution, not auto-fixed per the
executor's scope-boundary rule (only issues directly caused by the current
task's changes are auto-fixed).

## 01.4-07

- **`mix format --check-formatted` fails on `test/pukllay_club_web/components/layouts_test.exs`**
  (missing blank line around line 1259). This file is not in plan 01.4-07's
  `files_modified` list and was not touched by either of its commits — last
  modified by commit `fddc0f6` (an earlier, unrelated plan). Pre-existing
  drift, out of scope for this plan. Not fixed here; flag for a future
  formatting pass or `mix format` run.
