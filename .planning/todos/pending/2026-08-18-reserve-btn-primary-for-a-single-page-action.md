---
created: 2026-08-18T19:00:34.489Z
title: Give the design system a secondary button tier so btn-primary isn't shared 184x
area: ui
severity: minor
files:
  - lib/pukllay_club_web/components/core_components.ex:104-125
  - lib/pukllay_club_web/components/game_card.ex:73-75
  - lib/pukllay_club_web/components/filter_drawer.ex:36-38
---

## Problem

On the catalog browse screen, `.btn-primary` (solid violet fill) is used for one page-level utility
action ("Filtros") and 183 identical per-card CTAs ("Ver detalles" — one per rendered card across the
grid and every carousel row). 184 elements sharing the loudest visual treatment on the page means
"primary" carries no reserved salience anywhere — `CoreComponents.button/1` only exposes
`variant: "primary"` or an unstyled `btn-soft`, with no middle tier for "important, but not the page's
one action."

Not a bug in the strict sense (color is applied consistently per the design system's own rule that
"weight and color... is the emphasis lever") — it's a systemic gap in the component vocabulary itself.

Found during a retroactive UI audit against the `ui-design-system` skill. Full audit:
https://claude.ai/code/artifact/f067cf3b-84ec-41d5-970c-71e035bc7f90

## Solution

TBD — likely needs a second button variant (e.g. `btn-secondary`/`btn-outline` as the default for
repeated per-item actions like "Ver detalles", reserving solid `btn-primary` for true page-level
single actions like "Filtros" or a future checkout/submit action) added to
`CoreComponents.button/1`'s `variants` map, then applied selectively. Low priority relative to the
touch-target and overlap findings — a hierarchy/polish issue, not a functional one.
