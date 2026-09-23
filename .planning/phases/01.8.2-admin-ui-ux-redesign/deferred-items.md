# Deferred Items — Phase 01.8.2

Out-of-scope discoveries found while executing a plan, logged rather than fixed
(scope boundary rule: only auto-fix issues directly caused by the current
task's own changes).

## From plan 05 (2026-09-23)

- **`priv/repo/migrations/20260923122000_unpublish_still_empty_games.exs`** and
  **`test/pukllay_club/catalog_test.exs`** (both plan `01.8.2-04`'s files) fail
  `mix format --check-formatted`. Discovered running the full `mix quality`
  alias while executing plan 05; neither file was touched by plan 05, and the
  drift predates it. Needs a future `mix format` pass + review of the diff
  (Styler can change program behavior per this project's own CLAUDE.md
  caveat — do not blind-format without reviewing the hunk).
