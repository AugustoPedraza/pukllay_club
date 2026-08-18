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
