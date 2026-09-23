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

## From plan 12 (2026-09-23) — found by `test/visual/admin_components.mjs`/`admin_shell.mjs` against the real /admin

All four found by real-browser measurement (rect/resolved-style/real-event, never source text) against the live dashboard + Staff screens.

**FIX NOW disposition (2026-09-23, same plan, Task 3):** the user reviewed these findings and
decided the two SEVERE items below must be fixed inside plan 12 itself, before Wave 7 begins —
nine remaining plans build on the sheet/dialog and should inherit a working one. Both are now
FIXED, verified RED→GREEN by the same harness that found them
(`test/visual/admin_components.mjs`, run against a real booted dev server with a real staff
session — see `01.8.2-12-SUMMARY.md` for the full RED→GREEN→RED(revert)→GREEN(restore) evidence
and the two follow-on fixes the RED→GREEN pass itself surfaced). `files_modified` grew beyond
plan 12's original scope (`test/visual/*`, `01.8.2-DEVICE-PASS.md`) to cover the actual defects,
per explicit user direction overriding the scope-boundary rule for this specific pair.

- **FIXED — SEVERE — `assets/js/hooks/admin_sheet.js`'s `isOpen = () => this.el.offsetParent !== null`
  (plan `01.8.2-08`'s file) was a no-op guard.** `offsetParent` is
  unconditionally `null` for a `position: fixed` element in Chrome — proven
  empirically (`test/visual/admin_components.mjs`'s own header comment).
  `.pk-admin-overlay-root` (`sheet/1`/`dialog/1`'s mount point) IS
  `position: fixed`, so `isOpen()` always returned `false`. Confirmed
  against the real Staff screen (`admin_components.mjs`'s interactive
  checks, re-run stably twice): Esc did not close an open sheet or
  dialog; drag-down on the grabber did not close the sheet; initial focus
  never moved to the sheet's close control or the dialog's Cancelar on
  open; focus was never returned to the invoking control on close. A real
  pointer tap on the SCRIM still closed it (that path is wired via a
  direct `phx-click` in the markup, independent of the hook). D-19o's
  press-state CSS rule itself was unaffected and confirmed working
  (`[data-pk-pressable]:active` paints `--color-surface-2` correctly on a
  real mouse press).
  **Fix landed:** `isOpen()` now reads resolved `display`
  (`getComputedStyle(this.el).display !== 'none'`), matching what
  `admin_components.mjs`'s own `isOverlayOpen` already does. Two follow-on
  fixes were required to make this genuinely work end-to-end, both found
  by re-running the harness after the first fix (see `01.8.2-12-SUMMARY.md`
  for full detail): (1) the shipped call site (`staff_live/index.ex`)
  removes the sheet/dialog from the DOM via `:if` rather than toggling the
  open/close class on a still-mounted element, so `destroyed()` now also
  triggers the focus-return path (guarded on `wasOpen` so a stay-mounted
  usage never double-fires it); (2) the invoking row (`list_row/1`'s
  `<div>` branch) had no `tabindex`, so it was never actually focusable —
  focus-return had nothing valid to restore to — fixed by adding
  `tabindex="0"`. (3) `onClose()`'s focus-restore is now guarded on
  `document.activeElement === document.body`, because `ask-remove` closes
  this sheet and opens the confirm dialog in the SAME server diff, and the
  dialog's own `onOpen()` (which focuses Cancelar) was found to run BEFORE
  this sheet's `destroyed()` — an unconditional restore was stealing focus
  back from Cancelar.

- **FIXED — SEVERE — a short sheet's bottom-most row(s) could be untappable
  at any viewport height.** `.pk-admin-overlay-root` and `.pk-admin-tab-bar`
  shared the identical `z-index: 70` (`components.css`/`chrome.css`), and
  both are anchored flush to the viewport's bottom edge (`bottom: 0`
  / `position: fixed`). Confirmed via a real coordinate click +
  `elementFromPoint` (not source text) against the Staff screen's single-
  row options sheet: a tap at "Quitar del staff"'s own centre point landed
  on the tab bar's Estantes icon instead, reproduced on every run. Affects
  any sheet whose last row falls in the tab bar's 67px band — which, given
  both are bottom-anchored, is every sheet with content short enough to
  not scroll that row out of the band.
  **Fix landed:** `.pk-admin-overlay-root`'s `z-index` raised from `70` to
  `75` — strictly between the tab bar's `70` and the snackbar's `80`, so it
  covers the chrome it must and stays under the one component that already
  needs to paint over an open sheet/dialog too.

**Regression test updated:** `admin_components_test.exs`'s "never checks visibility via a
.hidden class — only offsetParent" test asserted the OLD (broken) `offsetParent` behaviour by
name; updated to assert the corrected guard (`refute ... offsetParent`, `assert ...
getComputedStyle`) — the underlying "never a class-name string match" rule this test enforces is
unchanged, only the concrete visibility check it names.

- **`.pk-admin-page-title { margin: 0 }` (`assets/css/admin/screens.css`,
  plan `01.8.2-11`) defeats the intended 24px page-head-to-body gap.**
  D1-D3's design intent (`01.8.2-12-PLAN.md` Task 1) states "the page head
  24px above body" (`space-y-6` = 24px, deliberately chosen by the wrapper
  div both live screens use). Measured 0px on both the dashboard and Staff
  screens, at every swept viewport/theme (`admin_components.mjs`'s D3
  check, 12 samples). Cause: `margin: 0`'s shorthand and Tailwind's
  `space-y-6` `margin-block-end` resolve to the SAME physical property
  (`margin-bottom`) in this app's writing mode; both selectors carry equal
  specificity, and `screens.css` is `@import`ed after `tailwindcss` in
  `app.css` (source-order tiebreak), so the title's `margin: 0` wins
  outright. Fix candidate: scope the reset to `margin-top: 0` only
  (leaving `margin-bottom` to `space-y-6`), or give the title's own rule a
  `margin-block-end` that matches 24px instead of a blanket `margin: 0`.

- **FIXED — same-run D-19f focus check reported failing on the dialog
  too** (Cancelar did not carry initial focus on open). Not a separate
  defect from the `isOpen()` fix above, but it did NOT clear automatically
  once that fix landed, as originally expected — a second, more subtle
  cause surfaced: `ask-remove` closes the sheet and opens the confirm
  dialog in the SAME server diff, and the dialog's own `onOpen()` (which
  focuses Cancelar) runs BEFORE the sheet's `destroyed()` — so the sheet's
  own new focus-return logic was stealing focus back from Cancelar
  immediately after it was set. Fixed by guarding the sheet's focus-restore
  on `document.activeElement === document.body` (see the `isOpen()` fix
  entry above, follow-on fix 3). Verified via the same D-19f harness
  assertion, now green.

## Open item 1 — routed to plan 01.8.2-22 (2026-09-23)

The real-device pass (open item 1: press-state, tap-highlight, drawer edge-swipe, sheet/dialog
behaviour, save-bar reachability, tab-bar-with-browser-UI, thumb reachability — the full 8-item
list) was **not run during plan 12**. The user made an explicit decision to defer it to
**post-deployment**, against the real deployed site, rather than against a local dev build now —
one phone session against production can both walk the checklist and clear open item 1 at once,
instead of walking it twice. The checklist itself is preserved verbatim, ready to fill in, at
`.planning/phases/01.8.2-admin-ui-ux-redesign/01.8.2-DEVICE-PASS.md` (status: `pending`).

**Plan `01.8.2-22` (production rollout) should pick this up as post-deploy UAT** — do not let
this evaporate. Items 4, 5 and 8 on that checklist are framed as "verify the fix" (not "expect to
fail"), since Defects A and B above are already fixed and harness-verified as of this plan; a
`FIX NOW` result on any of those three during the device pass would mean a real device diverges
from the harness's own headless-Chrome evidence.
