---
created: 2026-08-18T19:00:34.489Z
title: Add accessible names and fix hit target on theme toggle buttons
area: ui
severity: major
files:
  - lib/pukllay_club_web/components/layouts.ex:149-171
---

## Problem

`Layouts.theme_toggle/1` renders three icon-only `<button>` elements (system/light/dark), each with
only a `<.icon>` child. None carries an `aria-label`, `title`, or visually-hidden text — a
screen-reader user reaches three identically-announced "button, button, button" controls with no way
to tell system/light/dark apart.

The correct pattern already exists two components away in the same file: the flash close button
(`layouts.ex`, via `CoreComponents.flash/1`) correctly sets `aria-label={gettext("close")}`. This
wasn't reused for the theme toggle.

Each button also measures **32×32px** live — under the app's 44px (`min-h-11`) minimum on both axes
(`class="flex p-2 cursor-pointer w-1/3"`, no size floor applied).

`theme_toggle/1` renders in `Layouts.app/1`, so this affects every page in the app, not just the
catalog screen — found while auditing `CatalogLive.Index` (the page that pulled it in). Found during a
retroactive UI audit against the `ui-design-system`/`ux-patterns`/`ux-responsive` skills. Full audit:
https://claude.ai/code/artifact/f067cf3b-84ec-41d5-970c-71e035bc7f90

Measured: 32×32px per button, 0/3 have any accessible name.

## Solution

Add `aria-label` to each of the three buttons in `layouts.ex:149-171` (e.g. "Usar tema del sistema" /
"Usar tema claro" / "Usar tema oscuro" — plain Spanish per app convention). Increase each button's hit
area to meet `min-h-11`/`min-w-11` — likely needs adjusting the `p-2 w-1/3` sizing inside the
`rounded-full` segmented-control container without breaking its current pill shape. Re-measure post-fix
and confirm with a screen reader (or accessibility tree read) that each button now announces distinctly.

## Resolution

**Date:** 2026-08-21

**Fixed here.** Each of the three buttons in `layouts.ex`'s `theme_toggle/1` gained
`aria-label="Usar tema del sistema"` / `"Usar tema claro"` / `"Usar tema oscuro"` — exactly the
suggested Spanish copy, matching the app's existing `Cerrar filtros`/`Cerrar` tone precedent. No
`title` attribute was added alongside (one accessible name per control, per `ui-design-system`).

Hit target: `min-h-11 min-w-11` added to each button's class list, using the app's one documented
hit-target number (`ui-design-system` explicitly forbids introducing a second). `w-1/3` was kept
untouched so the sliding indicator (sized off the container, not off an individual button) stays
aligned with whichever third is active. Added `items-center justify-center` alongside the existing
`flex` so the icon stays centred now that the button's box is bigger than the icon — previously the
single-child flex box defaulted to `justify-content: flex-start`, which would have left the icon
top-left of the enlarged hit area. The `rounded-full` pill shape on the outer container is
untouched by this change (only the inner buttons grew).

Guarded by `test/pukllay_club_web/components/layouts_test.exs` (asserts 3 distinct Spanish
`aria-label`s present, and exactly 3 occurrences each of `min-h-11`/`min-w-11`).

This closes the still-open human-verification item in `01-VERIFICATION.md` for the theme toggle
specifically; the sliding-indicator alignment and pill-shape checks are re-confirmed visually in
this plan's Task 5 browser checkpoint.
