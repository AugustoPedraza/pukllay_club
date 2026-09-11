---
phase: 01-catalog-v1
reviewed: 2026-08-18T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - lib/mix/tasks/catalog.seed.ex
  - lib/pukllay_club/catalog.ex
  - lib/pukllay_club/catalog/game.ex
  - lib/pukllay_club/catalog/seed/expansion_classifier.ex
  - lib/pukllay_club_web/components/carousel_row.ex
  - lib/pukllay_club_web/components/core_components.ex
  - lib/pukllay_club_web/components/game_card.ex
  - lib/pukllay_club_web/components/game_chips.ex
  - lib/pukllay_club_web/live/catalog_live/index.ex
  - priv/repo/migrations/20260818222551_add_games_is_expansion.exs
  - test/pukllay_club/catalog/seed/expansion_classifier_test.exs
  - test/pukllay_club/catalog_test.exs
  - test/pukllay_club_web/components/game_chips_test.exs
  - test/pukllay_club_web/live/catalog_live_test.exs
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-08-18T00:00:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

This review is scoped to the changes introduced by phase 01's three gap-closure plans (01-07:
three-tier `GameChips` hierarchy / overflow-safe weight badge / double-focus-ring fix; 01-08:
carousel row `variant`/`subtitle` + persistent scroll controls + titled main grid; 01-09:
`ExpansionClassifier` + `games.is_expansion` + `recent_query/0` exclusion), not the full phase.
I read every listed file in full, then diffed each against `27c0edb` (the commit immediately
preceding this batch of work) to isolate exactly what these three plans changed, and traced the
changed logic against its callers (`CatalogLive.Show`'s continued use of `GameChips`,
`CatalogFixtures.game_fixture/1`'s `is_expansion` cast path, the migration's SQL mirror of
`ExpansionClassifier`'s marker/override lists).

To verify claims rather than eyeball them, I additionally: ran the four listed test files (73
tests, 0 failures), ran `mix compile --warnings-as-errors --force` (clean), ran
`mix format --check-formatted` on the changed files (clean), ran `mix credo --strict` on the
changed files (one pre-existing, out-of-diff suggestion only), and — because one finding below
hinges on Tailwind's CSS cascade order rather than something readable from source — actually ran
`mix tailwind pukllay_club` (both normal and `--minify`) and diffed byte offsets of the generated
`.hidden`/`.flex` utility rules to confirm the real runtime behavior instead of guessing.

Overall this is a small, well-tested, tightly-scoped diff (each plan's commits show
tests-before-implementation), and I did not find a correctness, security, or data-integrity
blocker in the reviewed files. The two warnings below are both about relying on implicit,
untested-by-the-suite mechanisms (CSS cascade order; a CSS pseudo-class with no functional effect
in its current markup context) rather than about anything the shipped feature currently gets
wrong.

## Warnings

### WR-01: Scroll-control visibility depends on unstated Tailwind cascade order, not an explicit state

**File:** `lib/pukllay_club_web/components/carousel_row.ex:78` (paired with the JS at line 57)

**Issue:** The persistent prev/next control wrapper is given two simultaneously-present,
display-contradicting static classes:

```heex
<div data-controls class="hidden flex items-center gap-2">
```

and the colocated hook only ever toggles the `hidden` class:

```js
this.controls.classList.toggle("hidden", !overflows)
```

This "works" only because Tailwind v4 happens to emit `.hidden{display:none}` *after*
`.flex{display:flex}` in the generated stylesheet (alphabetical ordering within `@layer
utilities` — I confirmed this by building `priv/static/assets/css/app.css` and diffing byte
offsets: `.flex` at offset 61003, `.hidden` at offset 61041, in both the normal and `--minify`
builds). Because both classes have identical specificity, the later rule wins, so the element is
`display:none` by default until JS removes `hidden`, leaving `flex` to take over — which happens
to be the intended "hidden until JS proves the rail overflows" behavior.

Nothing in the source documents that this depends on utility declaration order, and nothing in
the test suite can catch a regression here: `catalog_live_test.exs`'s G-01-3 test only asserts
the *markup* (`data-controls`, `data-scroll`, aria-labels) is present, never the actual computed
`display` value. If a future Tailwind bump changes core-utility ordering, or a purge/minify step
reorders rules differently, the controls would render permanently visible (or permanently hidden)
with zero CI signal.

**Fix:** Don't co-declare contradictory display classes. Start with only `hidden` in the
template and have the hook explicitly add/remove `flex` alongside `hidden`, e.g.:

```js
this.sync = () => {
  const overflows = this.rail.scrollWidth > this.rail.clientWidth
  this.controls.classList.toggle("hidden", !overflows)
  this.controls.classList.toggle("flex", overflows)
}
```

```heex
<div data-controls class="hidden items-center gap-2">
```

This makes the visible/hidden state explicit and order-independent instead of depending on
Tailwind's internal utility ordering.

### WR-02: `chip_row`/`editorial_tags` cap values are unnamed magic numbers repeated across call sites

**File:** `lib/pukllay_club_web/components/game_card.ex:85-86`

**Issue:**

```heex
<GameChips.editorial_tags tags={@game.tags} limit={2} />
<GameChips.chip_row terms={@mechanic_labels} limit={4} />
```

`2` and `4` are the browse-card's overflow caps (G-01-6's fix), but they're bare literals with no
named constant, no doc reference back to the design rule that fixes them at 2/4, and nothing
guards them from drifting out of sync with `CarouselRow`'s reuse of `GameCard.game_card/1` at a
narrower `w-40 shrink-0` width (the carousel rail renders the exact same card at a *smaller*
footprint than the grid, via `class="w-40 shrink-0 sm:w-48"` in `carousel_row.ex:99`, yet gets the
same `limit={2}`/`limit={4}` caps tuned for the grid's wider card). This isn't a functional bug
today (both existing tests pass at both widths), but a future width change to either grid or
carousel card sizing has no single source of truth to check.

**Fix:** Lift these into module attributes with a comment tying them to G-01-6, e.g.:

```elixir
# G-01-6: browse-card overflow caps — tuned for the grid card's width;
# CarouselRow reuses this same card at a narrower w-40/sm:w-48 footprint.
@tag_limit 2
@mechanic_limit 4
```

and reference `@tag_limit`/`@mechanic_limit` in the template instead of the bare literals.

## Info

### IN-01: `focus-within:outline-hidden` has no effect on the leaf form controls it's applied to

**File:** `lib/pukllay_club_web/components/core_components.ex:249, 273, 296`

**Issue:** The 01-07 fix ("collapse double focus ring on plain input/select/textarea") adds
`focus-within:outline-hidden` alongside `focus:outline-hidden` on the bare `<select>`,
`<textarea>`, and `<input>` elements themselves:

```heex
class={[
  @class || "w-full select focus:outline-hidden focus-within:outline-hidden",
  ...
]}
```

`:focus-within` matches an element if *the element itself or any descendant* is focused. These
three elements are leaves with no focusable descendants in this codebase's markup (no compound
`<label class="input">…</label>` wrapper pattern is used here — `input/1`'s wrapping `<label>`
contains the input as a sibling-of-nothing child, and the class is applied to the input itself,
not the label). So `:focus-within` on the input/select/textarea reduces to exactly `:focus`, and
`focus-within:outline-hidden` adds nothing beyond the already-present `focus:outline-hidden`. It's
harmless (dead CSS, not a bug), but it also doesn't verifiably fix anything on its own — if the
"double ring" the commit fixed was coming from a `:focus-within` rule elsewhere (e.g. a daisyUI
compound-input style), this is the right selector to counter but the wrong element to put it on.

**Fix:** No action required if the fix has been visually verified (the commit message suggests
it was). If not yet visually verified in a browser, confirm the double-ring is actually gone;
otherwise this line can be safely deleted with no behavior change.

### IN-02: `ExpansionClassifier`'s substring markers can false-positive on base-game titles

**File:** `lib/pukllay_club/catalog/seed/expansion_classifier.ex:55`

**Issue:** The `"expansi"` marker matches any name containing that literal substring anywhere,
case-insensitively — not just a trailing "(Expansión)"/"Expansion" suffix. A hypothetical base
game titled e.g. "La Expansión del Universo" (a real base-game title pattern, not a BGG
expansion) would be misclassified as an expansion/promo. This is explicitly a documented,
deliberate trade-off in the moduledoc (substring matching chosen over regex specifically so the
Elixir rule and the migration's raw-SQL `ILIKE` mirror can never diverge), and the regression test
(`streaming ludoteca.csv yields exactly the 26 confirmed expansion/promo rows`) confirms it
produces zero false positives against the *current* 434-row club export. Flagging only because the
risk is real for any *future* CSV row added to the club's collection, not because the current
implementation is wrong for the data it was built and tested against.

**Fix:** No change needed now. If a future `mix catalog.seed` run against an updated CSV export
produces a classification the club didn't expect, the `catalog_seed_report.md`
observed-terms/duplicate-style reporting mechanism this task already has could be extended with an
`is_expansion`-flagged-row listing so a human reviews new marker hits before they go live — but
that's a Phase-4-scale enhancement, not a fix to land now.

---

_Reviewed: 2026-08-18T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
