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
