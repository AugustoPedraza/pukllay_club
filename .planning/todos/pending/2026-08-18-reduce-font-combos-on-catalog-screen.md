---
created: 2026-08-18T19:00:34.489Z
title: Reduce distinct font-size/weight combos on catalog screen (10 vs cap of 3)
area: ui
severity: minor
files:
  - lib/pukllay_club_web/live/catalog_live/index.ex
  - lib/pukllay_club_web/components/game_card.ex
  - lib/pukllay_club_web/components/carousel_row.ex
  - lib/pukllay_club_web/components/game_chips.ex
  - lib/pukllay_club_web/components/filter_drawer.ex
---

## Problem

Measured live on the catalog browse screen: 10 distinct rendered font-size/weight/font-family
combinations — `10px/400`, `12px/400`, `12px/600`, `14px/400`, `14px/600`, `16px/400` across two
different font-family stacks ("Inter" and "Inter Variable"), `16px/600`, `20px/400` and `24px/400`
(both Bebas Neue). The design system's own rule (`ui-design-system` skill) caps a single screen at 3
distinct size/weight levels (heading, body, muted).

Identical at 375px/768px/1440px — nothing collapses on resize. Some of the spread is inherited from
daisyUI's own component defaults (`badge`, `badge-sm`, `select`, `input` each carry their own
font-size) rather than hand-authored in this app's templates, so a full fix may mean normalizing
component-level type sizes, not just app code. See related todo for the `text-[10px]` /
`text-base-content/70` banned-pattern finding in `layouts.ex`, which is one direct contributor to this
count.

Found during a retroactive UI audit against the `ui-design-system` skill. Full audit:
https://claude.ai/code/artifact/f067cf3b-84ec-41d5-970c-71e035bc7f90

## Solution

TBD — audit each of the 10 combos against the skill's heading/body/muted 3-tier scale, decide which
are genuinely necessary (e.g. Bebas Neue at two sizes for h2 vs h3-equivalent may be defensible) vs.
which are unmanaged daisyUI defaults that could be normalized via a shared class or CSS override. Not
urgent — visual noise/consistency issue, not a functional defect.
