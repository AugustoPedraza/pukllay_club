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

All four found by real-browser measurement (rect/resolved-style/real-event, never source text) against the live dashboard + Staff screens. None of these files were touched by plan 12 (`files_modified`: `test/visual/*`, `01.8.2-DEVICE-PASS.md` only) — logged per the scope-boundary rule, not fixed.

- **SEVERE — `assets/js/hooks/admin_sheet.js`'s `isOpen = () => this.el.offsetParent !== null`
  (plan `01.8.2-08`'s file) is a no-op guard.** `offsetParent` is
  unconditionally `null` for a `position: fixed` element in Chrome — proven
  empirically (`test/visual/admin_components.mjs`'s own header comment).
  `.pk-admin-overlay-root` (`sheet/1`/`dialog/1`'s mount point) IS
  `position: fixed`, so `isOpen()` always returns `false`. Confirmed
  against the real Staff screen (`admin_components.mjs`'s interactive
  checks, re-run stably twice): **Esc does not close an open sheet or
  dialog; drag-down on the grabber does not close the sheet; initial focus
  never moves to the sheet's close control or the dialog's Cancelar on
  open; focus is never returned to the invoking control on close.** A real
  pointer tap on the SCRIM does still close it (that path is wired via a
  direct `phx-click` in the markup, independent of the hook). D-19o's
  press-state CSS rule itself is unaffected and confirmed working
  (`[data-pk-pressable]:active` paints `--color-surface-2` correctly on a
  real mouse press). Fix candidate: replace the `offsetParent` check with
  a resolved-`display` check (`getComputedStyle(this.el).display !== 'none'`),
  matching what `admin_components.mjs`'s own `isOverlayOpen` now does.

- **SEVERE — a short sheet's bottom-most row(s) can be untappable at any
  viewport height.** `.pk-admin-overlay-root` and `.pk-admin-tab-bar`
  share the identical `z-index: 70` (`components.css`/`chrome.css`), and
  both are anchored flush to the viewport's bottom edge (`bottom: 0`
  / `position: fixed`). Confirmed via a real coordinate click +
  `elementFromPoint` (not source text) against the Staff screen's single-
  row options sheet: a tap at "Quitar del staff"'s own centre point lands
  on the tab bar's Estantes icon instead, reproduced on every run. Affects
  any sheet whose last row falls in the tab bar's 67px band — which, given
  both are bottom-anchored, is every sheet with content short enough to
  not scroll that row out of the band. Fix candidate: raise
  `.pk-admin-overlay-root`'s `z-index` above the tab bar's (e.g. match the
  snackbar's `80`), or reserve `--pk-tab-bar-h` of bottom padding inside
  the sheet's own scrollable rows.

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

- **Cosmetic — same-run D-19f focus check reported failing on the dialog
  too** (Cancelar does not carry initial focus on open), same root cause
  as the sheet's focus-on-open failure above (shared `admin_sheet.js`
  hook) — not a separate defect, listed for completeness since it will
  clear when the hook fix above lands.
