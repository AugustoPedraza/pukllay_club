---
created: 2026-08-18T19:00:34.489Z
title: Fix brand tagline's banned arbitrary-value and non-token color classes
area: ui
severity: cosmetic
files:
  - lib/pukllay_club_web/components/layouts.ex:35
---

## Problem

`Layouts.brand_logo/1` sets `text-[10px]` (arbitrary Tailwind value — explicitly banned by the
`ui-design-system` skill: "never these") and `text-base-content/70` (a color explicitly called out as
a holdover not to propagate — the app's actual convention is `text-neutral text-sm`).

Renders on every page via the shared layout (`Layouts.app/1`), not scoped to any one LiveView — found
while auditing `CatalogLive.Index`, the page that pulled it in. It's also the direct source of the
`10px/400` entry in the related "10 font combos vs cap of 3" todo.

Found during a retroactive UI audit against the `ui-design-system` skill. Full audit:
https://claude.ai/code/artifact/f067cf3b-84ec-41d5-970c-71e035bc7f90

## Solution

Replace `text-[10px] ... text-base-content/70` in `layouts.ex:35` with the app's documented convention
(`text-neutral text-sm`, or the closest token-based size if `text-sm` reads too large for a tagline —
check against the brand's actual UI-SPEC sizing intent, not just swap-and-ship). Re-check the resulting
font-combo count on the catalog screen drops by one entry.
