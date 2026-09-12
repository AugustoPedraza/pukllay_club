# Deferred Items — Phase 01.8

Out-of-scope discoveries logged during plan execution, per the executor's
scope-boundary rule (only auto-fix issues directly caused by the current
task's changes).

## Pre-existing async-DB-pollution flakiness in `catalog_live_test.exs` / `catalog_show_test.exs`

**Found during:** 01.8-01, Task 1 and Task 2 verification.

**Symptom:** Running `mix test test/pukllay_club_web/live/catalog_live_test.exs`
and/or `catalog_show_test.exs` in isolation intermittently fails 4-9 tests
(counts vary run to run), e.g.:

- `card_count(html) == 1` returns `3`
- `"0 juegos encontrados"` not found
- `"Otros juegos del mismo nivel: Nivel experto"` not found
- `refute html =~ "Ampliado"` fails
- `refute html =~ "pk-difficulty"` fails

**Root cause (not investigated further — out of this plan's scope):** appears
to be cross-test fixture/DB-sandbox pollution under `async: true` — likely
`csv_row`/similar-games queries picking up rows seeded by a concurrently
running test in the same sandbox, not anything this plan's CSP/SEO changes
touch.

**Confirmed pre-existing, not a regression from this plan:** verified by
running the identical test files (same `--seed`) against a clean
`git worktree` checked out at this plan's pre-execution HEAD
(`861bed65e510bd950c4e5d592a119a043d54f3cf`) — the same test names fail with
the same counts on unmodified code. Full-suite `mix test` also matches
exactly: 933 tests/26 failures on baseline vs. 939 tests/26 failures on this
plan's branch (the 6 new tests are this plan's `game_seo_test.exs`, all
passing).

**Action:** not fixed — out of scope for this plan. Worth a dedicated
debug/quick-task pass whenever `catalog_live_test.exs`/`catalog_show_test.exs`
async isolation is next touched.
