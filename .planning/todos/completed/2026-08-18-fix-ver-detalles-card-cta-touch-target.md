---
created: 2026-08-18T19:00:34.489Z
title: Fix Ver detalles card CTA undersized touch target (28px vs 44px)
area: ui
severity: major
files:
  - lib/pukllay_club_web/components/game_card.ex:73-75
---

## Problem

`GameCard.game_card/1` renders "Ver detalles" as `btn btn-primary btn-sm`, which measures **95×28px**
live. This app's own convention adds `min-h-11` (44px) to any tappable control under that size — the
filter trigger and every facet pill in `FilterDrawer` already do this correctly (measured 44px exactly
on all 73 pills checked) — but `GameCard` never applies it.

This is the single most-repeated interactive element on the catalog page: every rendered card, in the
main grid and every one of the 8 carousel rows (183 instances measured live), ships the same
undersized target for its only action — the primary conversion action of the whole browse screen.

Directly answers (negatively) the still-open human-verification item in
`.planning/phases/01-catalog-v1/01-VERIFICATION.md` about comfortable 44px tap targets. Found during a
retroactive UI audit against the `ui-design-system`/`ux-patterns`/`ux-responsive` skills. Full audit:
https://claude.ai/code/artifact/f067cf3b-84ec-41d5-970c-71e035bc7f90

Measured: 95×28px actual vs 44px minimum (36% shortfall on height), 183 instances on the live page.

## Solution

Add `min-h-11` to the CTA's class list in `game_card.ex:73-75` (matching the pattern already used for
`filter_drawer.ex`'s trigger and facet pills). Re-measure post-fix to confirm ≥44px height across the
grid and all carousel-row instances, and re-check the card body doesn't visually break (button sits
inside a `space-y-2` card-body with `p-4` — confirm no unwanted overflow/reflow once the button grows).

## Resolution

**Date:** 2026-08-21

**Verified as already resolved by 01-10's preview-surface work — not re-fixed here.** The audit's
`btn btn-primary btn-sm` (95×28px, 183 instances) no longer exists: `GameCard.game_card/1` doesn't
render a "Ver detalles" CTA at all (confirmed by grep — no `Ver detalles`/`btn-primary`/`btn-sm` in
`game_card.ex`). The CTA moved to `GamePreview.preview_body/1`
(`lib/pukllay_club_web/components/game_preview.ex:112-117`), where it already renders
`btn btn-outline btn-primary btn-block min-h-11` — outlined, not filled, and already at the app's
44px floor.

The 183-instance measurement also no longer describes the page's live geometry: `preview_body/1` is
rendered once per card inside an inert `<template>` (`preview_template/1`,
`game_preview.ex:123-134`) and cloned into a single shared portal/sheet on hover or tap — one live,
painted instance at a time, not 183 simultaneously-rendered undersized buttons.

This plan's Task 5 browser checkpoint confirms the live geometry (≥44px, no overflow/reflow in
either the desktop portal or the mobile sheet) before this closure is considered final, per the
plan's own scope split between rendered-HTML proof and geometric proof.
