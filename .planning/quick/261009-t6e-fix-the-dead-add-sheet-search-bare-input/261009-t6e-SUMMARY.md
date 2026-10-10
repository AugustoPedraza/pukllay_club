---
phase: quick-261009-t6e
plan: 01
subsystem: ui
tags: [phoenix-liveview, forms, admin, css, user-select, regression-tests]
requires:
  - phase: 01.8.4
    provides: the Web add-sheet, the shared placement sheet and the rail "+" slots this fixes
provides:
  - three admin search fields (Web add-sheet, "Donde va?" sheet, Estantes "Que juego va aca?") that work in a real browser
  - four DOM-driven regression tests that each failed against the pre-fix bare-input markup
  - one inherited text-selection suppression on the pressable hook, covering all three "+" slot families
affects: [01.8.4 UAT, admin sheets]
actuals:
  tokens: 3576
  tasks: 5
  commits: 8
plan_head_before: 5a0939b57c8b15dadb455f2299b0e245a2f82886
tech-stack:
  added: []
  patterns:
    - "A phx-change input needs an enclosing form: bind change and submit on the form, never on the input"
    - "Regression tests for LiveView inputs start at the DOM (form/2 + render_change/1), not at a hand-built param map"
    - "Selection suppression lives once on the bare [data-pk-pressable] hook, not on :root or :active"
key-files:
  created: []
  modified:
    - lib/pukllay_club_web/live/admin/section_live/index.ex
    - lib/pukllay_club_web/components/admin_components.ex
    - lib/pukllay_club_web/live/admin/estante_live/index.ex
    - assets/css/admin/tokens.css
    - test/pukllay_club_web/live/admin/section_live_test.exs
    - test/pukllay_club_web/live/admin/estante_live_test.exs
    - test/pukllay_club_web/live/admin/game_live_test.exs
    - test/pukllay_club_web/admin_tokens_test.exs
key-decisions:
  - "No handler clause added, removed or edited, and no catch-all added to the three handlers that lack one: nothing is ever sent to them on the broken path"
  - "phx-submit bound to the same event as phx-change on all three forms, so a soft keyboard Go key cannot natively submit the page (T-T6E-02)"
  - "Selection suppression declared once on the bare [data-pk-pressable] hook; the guard test enforces that structurally"
requirements-completed: [QUICK-261009-T6E-01, QUICK-261009-T6E-02]
duration: 15min
completed: 2026-10-09
status: complete
---

# Phase quick-261009-t6e Plan 01: Dead add-sheet search Summary

**Three admin search inputs wrapped in real forms (change and submit bound on the form) so LiveView's client can serialize `q`, four DOM-driven regression tests that were RED first, and a single inherited `user-select: none` on `[data-pk-pressable]` that stops the rail "+" selection band on all three slot families.**

## Performance

- **Duration:** about 15 min
- **Started:** 2026-10-10T00:20Z (approx.)
- **Completed:** 2026-10-10T00:34Z
- **Tasks:** 5
- **Files modified:** 8

## Accomplishments

- The Web destacada add-sheet search (`#web-add-sheet-form`), the shared `placement_sheet/1` search (`#donde-va-search-form`, one fix serving both `EstanteLive.Index` and `GameLive.Form`) and the Estantes `Que juego va aca?` search (`#que-va-aca-search-form`) now sit inside a `<form>` carrying `phx-change` and `phx-submit` on the same event. Each event is bound exactly once per file as change and once as submit.
- Four new regression tests (one per surface, two for the shared component) start at the DOM with `form/2` + `render_change/1`. Each was recorded failing against its pre-fix markup before that surface changed.
- One bare `[data-pk-pressable]` rule in `tokens.css` suppresses text selection (prefixed and unprefixed). A new tokens guard pins both declarations to that bare rule and was negative-tested twice.
- `mix quality` exits 0: 2028 tests, 0 failures.

## Task Commits

1. **Task 1 (tracer): Web add-sheet search**
   - `68275f45` test (RED)
   - `8ff36803` fix (GREEN)
   - `f66cdf46` test: reworded the new test's comment and formatted it (see Deviations)
2. **Task 2: shared placement sheet, two consumers**
   - `588cb04a` test (RED, both consumers)
   - `40b9adf2` fix
3. **Task 3: Estantes `Que juego va aca?`**
   - `e1e555df` test (RED)
   - `84d97a56` fix
4. **Task 4: rail "+" selection**
   - `0fb5c62b` fix (CSS rule, guard test)
5. **Task 5: quality gate**: no commit needed. `mix quality` made no formatting rewrites, so there was no `style` commit.

**Plan metadata:** not committed by the executor; the orchestrator owns the docs commit.

## RED evidence — surface A

Hand-translated from ExUnit output (`mix test` emits no TAP).

- Command: `mix test test/pukllay_club_web/live/admin/section_live_test.exs:826`
- Failing test: `SectionLive.Index — the sheet's recents, ranked search and no-match branch (01.8.4, ADD-03/04/07) a keystroke in the real search field reaches the handler and renders a match (browser-reachability, not handler-reachability)`
- Failure: `** (ArgumentError) expected selector "#web-add-sheet-form" to return a single element, but got none within: <the full rendered page>` at `code: lv |> form("#web-add-sheet-form", %{q: "cat"}) |> render_change()`
- Result: `1 test, 1 failure (87 excluded)`, exit status `2`.
- The failure is on the planned behavior (the real form does not exist), on the target test, with the sheet open and the bare `<input ... phx-change="add-sheet-search">` visible in the rendered HTML. The test did not pass pre-fix, so the halt condition did not trip.

## RED evidence — surface B

Both run against the same pre-fix `placement_sheet/1` markup.

**Consumer 1, `EstanteLive.Index`:**

- Command: `mix test test/pukllay_club_web/live/admin/estante_live_test.exs:491`
- Failing test: `«¿Dónde va?» — placing a copy with no spot (D-00c, plan 01.8.2-16) a keystroke in the real ¿Dónde va? search field renders a matching estante row`
- Failure: `** (ArgumentError) expected selector "#donde-va-search-form" to return a single element, but got none within: ...` at `code: lv |> form("#donde-va-search-form", %{q: "destino"}) |> render_change()`
- Result: `1 test, 1 failure (69 excluded)`, exit status `2`.

**Consumer 2, `GameLive.Form`:**

- Command: `mix test test/pukllay_club_web/live/admin/game_live_test.exs:809`
- Failing test: `GameLive.Form — the ESTANTE block opens the real «¿Dónde va?» sheet (D-32, plan 01.8.2-21) a keystroke in the real ¿Dónde va? search field renders a matching estante row`
- Failure: `** (ArgumentError) expected selector "#donde-va-search-form" to return a single element, but got none within: ...` at `code: lv |> form("#donde-va-search-form", %{q: "uno"}) |> render_change()`
- Result: `1 test, 1 failure (68 excluded)`, exit status `2`.

## RED evidence — surface C

- Command: `mix test test/pukllay_club_web/live/admin/estante_live_test.exs:622`
- Failing test: `the "+" slots and «¿Qué juego va acá?» (D-08, plan 01.8.2-16 Task 2) a keystroke in the real ¿Qué juego va acá? search field renders a matching game row`
- Failure: `** (ArgumentError) expected selector "#que-va-aca-search-form" to return a single element, but got none within: ...` at `code: lv |> form("#que-va-aca-search-form", %{q: "a0"}) |> render_change()`
- Result: `1 test, 1 failure (69 excluded)`, exit status `2`.
- Captured twice: once alongside the B tests, and again after re-inserting the test for its own RED commit (the plan's per-surface commit order required the C test to be held out of the B commit).

## Guard negative-test evidence

Guard: `text selection is suppressed exactly once, on the bare [data-pk-pressable] hook (D-19o)` in `test/pukllay_club_web/admin_tokens_test.exs`. Each mutation was applied, run, confirmed to fail, then reverted and confirmed green (`6 tests, 0 failures`).

**Mutation A, both declarations deleted from the rule:** exit status `2`, `6 tests, 1 failure`:

```
Expected exactly one unprefixed `user-select` declaration in assets/css/admin/tokens.css (it inherits, so one declaration on the [data-pk-pressable] hook covers every pressable surface). Do not repeat it on a component selector, and do not put it on :root.
```

**Mutation B, both declarations moved into `[data-pk-pressable]:active`, bare rule deleted:** exit status `2`, `6 tests, 1 failure`:

```
Expected exactly one bare `[data-pk-pressable] { ... }` rule in assets/css/admin/tokens.css. The selection suppression belongs on the bare attribute hook — not on :root (it inherits, so every admin string would become unselectable) and not on `:active` (a selection begins on pointer-down, before the press state applies).
```

The first run of Mutation B failed with a bare `MatchError` (`no match of right hand side value: []`), because `assert [[_, body]] = ...` ignores its message on a match failure. That was not readable, so the guard was restructured (`bare_rules = Regex.scan(...)`, `assert length(bare_rules) == 1, "..."`, then destructure) and Mutation B was re-run. The message above is from the re-run. Mutation A was re-run against the final guard as well.

## Mechanism correction (do not reintroduce the original brief's version)

The brief said a bare input "sends the value under `\"value\"`", the `%{"q" => q}` clause never matches, and the catch-all at `section_live/index.ex:165` silently swallows every keystroke. **That mechanism is wrong.** LiveView 1.2.9's client `pushInput` begins with `if (!inputEl.form) throw new Error("form events require the input to be inside a form")`, so on a formless `phx-change` input the client throws and **sends nothing at all**. Consequences:

- The catch-all at `section_live/index.ex:165` is not the swallower; it is never reached on this path. It stays as a forged-payload guard.
- The three handlers with no catch-all (`estante_live/index.ex:156`, `:248`, `game_live/form.ex:316`) never risked a `FunctionClauseError`, because no payload arrives. No catch-all was added to any of them.
- The observable symptom on all three surfaces was a dead field plus an uncaught console error, not a crash.

The diagnosis's conclusion and the fix are unaffected. The comments in the new tests describe the real mechanism.

## Files Created/Modified

- `lib/pukllay_club_web/live/admin/section_live/index.ex` - Web add-sheet search is a `<form id="web-add-sheet-form">` with change and submit bindings; the input lost its binding.
- `lib/pukllay_club_web/components/admin_components.ex` - `placement_sheet/1` search is a `<form id="donde-va-search-form">`; clear button (already `type="button"`) stays inside; lists and rail stay outside as siblings.
- `lib/pukllay_club_web/live/admin/estante_live/index.ex` - `#que-va-aca-sheet` search is a `<form id="que-va-aca-search-form">`.
- `assets/css/admin/tokens.css` - new bare `[data-pk-pressable]` rule with `-webkit-user-select: none; user-select: none;` and a D-19o-voice comment.
- `test/pukllay_club_web/live/admin/section_live_test.exs`, `estante_live_test.exs`, `game_live_test.exs` - four DOM-driven regression tests.
- `test/pukllay_club_web/admin_tokens_test.exs` - the selection-suppression guard.

## Decisions Made

- No handler change at all. The fix is markup plus one CSS rule.
- `phx-submit` was added to all three forms even though neither shipped precedent (`estantes-search-form`, `game_live/index.ex:641`) carries one, to close the soft-keyboard native-submit hole the new forms would otherwise open (T-T6E-02).
- The fixed `donde-va-search-form` id follows the component's own fixed-`donde-va-*` convention and does not trip the `game_live_test.exs:896` composition guard (it matches neither `dónde-va` nor `donde_va`).

## Bug 2 reach: three slot families, one declaration

The single `[data-pk-pressable]` declaration inherits to the `+` glyph's child text node in all three slot families: `.pk-admin-web-slot` (`section_live/index.ex`), `.pk-donde-va-slot` (`admin_components.ex`) and `.pk-estantes-slot` (`estante_live/index.ex`). This plan edited neither `screens.css` nor `estantes.css`, both byte-identical to merge-base. `.pk-donde-va-slot` and `.pk-estantes-slot` markup was not edited for the CSS fix; their files were touched only for the unrelated form wrapper. `grep user-select assets/css` shows exactly the two lines in `tokens.css`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test comment inflated its own count gate, and the new test was unformatted**

- **Found during:** Task 1, running the `<verify>` count gates after the fix commit
- **Issue:** my explanatory comment in the new test quoted the literal `render_change(lv, "add-sheet-search"`, taking the file's count from 15 to 16 and failing the gate that asserts the 15 pre-existing handler-level call sites are untouched. Separately `mix format --check-formatted` flagged the long test-name line.
- **Fix:** reworded the comment to describe the sibling tests without the literal, ran `mix format` on the test file, re-confirmed count 15 and the module green (88 tests, 0 failures).
- **Files modified:** `test/pukllay_club_web/live/admin/section_live_test.exs`
- **Verification:** `grep -o 'render_change(lv, "add-sheet-search"' ... | wc -l` is 15; module green.
- **Committed in:** `f66cdf46` (a follow-up commit; the fix commit `8ff36803` had already landed, and rewriting it was not worth the history churn)

**2. [Rule 1 - Bug] Guard test's first-written form gave an unreadable failure for Mutation B**

- **Found during:** Task 4, negative-testing the guard
- **Issue:** `assert [[_, body]] = Regex.scan(...), "message"` raised a bare `MatchError` and discarded the message when the bare rule was absent, which is exactly the "failed readably" bar the plan sets.
- **Fix:** restructured to `assert length(bare_rules) == 1, "..."` followed by destructuring; re-ran both mutations.
- **Files modified:** `test/pukllay_club_web/admin_tokens_test.exs`
- **Committed in:** `0fb5c62b` (the guard was never committed in its first form)

**Task ordering note, not a deviation of substance:** the C test was authored during Task 2 and then held out of the B commit (and re-inserted in Task 3) so each surface got its own RED commit as the plan specifies. Its RED was recorded in both places.

---

**Total deviations:** 2 auto-fixed (both Rule 1, both test-code only)
**Impact on plan:** none on production code or scope; no plan-promised behavior changed.

## Issues Encountered

- `mix quality` credo output lists 4 pre-existing "nested module could be aliased" suggestions (`catalog_live/show.ex`, `layouts.ex`, `conn_case.ex`, `db_source_of_truth_test.exs`) and sobelow 3 pre-existing low-confidence findings (`seo_tags.ex`, `catalog_live/index.ex`, `seo.ex`). None are in files this plan touched; none gate the alias, which exited 0. Out of scope.

## User Setup Required

None - no external service configuration required.

## Out-of-scope and carried-forward notes

- **`01.8.4-UAT.md` is absent from this branch.** `/gsd-pr-branch` classified it, the four phase SUMMARYs, `REVIEW.md` and `VERIFICATION.md` as transient reviewer noise and excluded them from the PR, so they live only on `gsd/phase-01.8.4-the-rail-becomes-the-add-surface`. The authority for these findings is the developer's live session. Recovering those artifacts is a separate task and was not done here.
- **Phase 01.8.4 remains PENDING human UAT.** This task closes UAT findings 1 and 2 and the two latent surfaces that shared finding 1's root cause. It does not close the phase.
- **Code-review warning WR-01** (older writers lacking the section row lock) was explicitly out of scope and untouched.
- **Human check still owed (Task 4 `<human-check>` and the plan's verification item 6):** on a real phone, typing in all three sheets renders matches; a Go/Search keypress does not navigate away from any of the three sheets; tap-with-drag on a rail `+` paints no band and still opens its sheet on the Web destacada, Estantes and "Donde va?" rails; a game name elsewhere in the admin is still long-press selectable. ExUnit cannot prove the browser-side outcome.

## Known Stubs

None. No stub, placeholder or empty-value pattern was introduced in any touched file.

## Threat Flags

None. The only new surface is the three forms the plan's threat model already registers (T-T6E-02, T-T6E-03), each mitigated by `phx-submit` on the same event and by keeping sibling controls outside the form boundary.

## Next Phase Readiness

- Branch `quick-261009-t6e-add-sheet-search-form` holds 8 code commits; `ideas.txt` remains modified in the working tree and was never staged or committed.
- The phone check above is the remaining step before 01.8.4 UAT can be closed out.

## Self-Check: PASSED

- All eight in-scope files exist and carry the expected changes; created files: none beyond this SUMMARY.
- All eight commit hashes resolve on the branch (`git log` since merge-base lists exactly `68275f45`, `8ff36803`, `f66cdf46`, `588cb04a`, `40b9adf2`, `e1e555df`, `84d97a56`, `0fb5c62b`); `commits: 8` is measured from the persisted ledger.
- Non-`.planning/` files touched since merge-base with `origin/main` are exactly the eight in-scope files (list comparison); `ideas.txt` is in no commit and still ` M`; the index is empty.
- `section_live/edit.ex`, `game_live/form.ex`, `screens.css` and `estantes.css` are byte-identical to merge-base.
- `mix quality`: exit 0, `2028 tests, 0 failures`.

---
*Phase: quick-261009-t6e*
*Completed: 2026-10-09*
