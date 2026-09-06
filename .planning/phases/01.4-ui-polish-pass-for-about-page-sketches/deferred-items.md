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

## 01.4-12

- **Still present, unchanged.** `mix format --check-formatted` still fails on
  `test/pukllay_club_web/components/layouts_test.exs` (same missing blank
  line around line 1259, verified byte-identical against the 01.4-07 note
  above via `git stash`). Not in this plan's `files_modified` list, not
  touched by any of this plan's commits. Same pre-existing drift, still out
  of scope. All files this plan actually modified
  (`lib/pukllay_club_web/{club_links,csp}.ex`,
  `lib/pukllay_club_web/live/about_live.ex`,
  `test/pukllay_club_web/live/{about_live,catalog_live}_test.exs`) are
  individually clean under `mix format --check-formatted`.
