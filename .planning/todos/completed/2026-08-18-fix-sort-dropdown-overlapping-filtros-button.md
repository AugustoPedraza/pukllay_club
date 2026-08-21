---
created: 2026-08-18T19:00:34.489Z
title: Fix sort dropdown overlapping and stealing clicks from Filtros button
area: ui
severity: blocker
files:
  - lib/pukllay_club_web/components/filter_drawer.ex:33-38
  - lib/pukllay_club_web/live/catalog_live/index.ex:239-266
---

## Problem

On the catalog browse screen (`CatalogLive.Index`), the sort `<select>` visually and functionally
overlaps the "Filtros" drawer-trigger button, identically at 375px/768px/1440px (not a responsive-only
regression — structural).

Root cause: `FilterDrawer.filter_drawer/1` wraps its trigger in daisyUI's `.drawer` class
(`display: grid`), with `w-auto` on the wrapper. The computed grid track daisyUI assigns is 58–70px,
narrower than the "Filtros" label's actual content width (102px). The label overflows its grid cell
and paints on top of the adjacent `<select name="sort">` in the parent flex row (`index.ex:238-267`).

Confirmed with `document.elementFromPoint` in headless Chrome: a tap on the last ~17px of the
"Filtros" label (covering the letter "s") resolves to the `<select>` underneath it, not the drawer
toggle — so this isn't just cosmetic, part of the button is dead for its stated purpose.

This directly answers (negatively) the still-open human-verification item in
`.planning/phases/01-catalog-v1/01-VERIFICATION.md` ("the drawer trigger and pills are comfortably
tappable") — found during a retroactive UI audit against the `ui-design-system`/`ux-patterns`/
`ux-responsive` skills. Full audit: https://claude.ai/code/artifact/f067cf3b-84ec-41d5-970c-71e035bc7f90

Measured (375px):
- `.drawer` track width: 58–70px
- "Filtros" label content width: 102px
- Overlap: ~17px, receiving `<select>` clicks

## Solution

TBD — likely needs the trigger's `.drawer` wrapper taken out of the grid-sizing path (e.g. an explicit
`inline-flex`/`w-fit` context around just the trigger label, or restructuring so `.drawer`'s grid only
governs the trigger+drawer-side pairing and doesn't sit as a flex sibling of the `<select>` with
`w-auto` fighting the grid track). Verify the fix by re-running `elementFromPoint` on the former
overlap zone and confirming it resolves to the drawer-toggle label, not the select, at all three
breakpoints.

## Resolution

**Date:** 2026-08-21

**Fixed here.** `filter_drawer.ex`'s wrapper class changed from `drawer drawer-end w-auto` to
`drawer drawer-end w-fit shrink-0` (the plan's first-choice fix, no fallback needed). `w-fit`
replaces the collapsing `w-auto` override so the grid track daisyUI assigns to the trigger's
`.drawer-content` column can no longer shrink below the "Filtros" label's own content width;
`shrink-0` stops the parent `flex items-center justify-end gap-4` row in `index.ex` from squeezing
the wrapper back down. `drawer`/`drawer-end` (load-bearing for the panel's side and open/close
checkbox behaviour) were left untouched, and no restructuring of the toolbar row in `index.ex` was
needed.

Guarded by `test/pukllay_club_web/components/filter_drawer_test.exs` (asserts `w-fit`/`shrink-0`
present, refutes `w-auto`, and asserts the trigger label keeps `min-h-11` + the `Filtros` text).

The geometric proof — `document.elementFromPoint` resolving to the drawer-toggle label across the
full label width at 375px/768px/1440px, and an actual click opening the drawer — is deferred to
this plan's Task 5 browser checkpoint, per the plan's own scope split (rendered-HTML assertions can
prove the classes are present, not that the resulting boxes are the right size).
