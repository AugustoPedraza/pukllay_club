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

## Resolution

**Date:** 2026-08-21

**Re-measured; disproved at current count — no CSS changed.** The 10-combo figure was measured
2026-08-18, before 01-10/01-11/01-12 moved the card/preview type scale into the `pk-*` CSS layer
and before this plan's Task 2 removed the tagline's `text-[10px]` arbitrary value. Re-measured live
(not from source classes) via headless Chrome + Chrome DevTools Protocol, walking every element
with a real layout box (`display !== 'none'`, `visibility !== 'hidden'` — off-canvas surfaces like
the closed filter drawer are excluded since daisyUI's drawer sets `visibility: hidden` when
closed) on the actual dev server (434 seeded games) at 375px, 768px, and 1440px.

**Result: 5 distinct `font-family`/`font-size`/`font-weight` triples, identical at all three
breakpoints** (only which elements populate which bucket shifts between widths, not the combo
count):

| Combo | n (375px) | n (768/1440px) | Tier | Source |
|---|---|---|---|---|
| Bebas Neue / 24px / 400 | 10 | 10 | heading | `font-display text-2xl` — brand wordmark + all 8 carousel row titles + main-grid heading (one shared Tailwind utility, not independently declared per row) |
| Inter / 12px / 600 | 207 | 24 | body (semibold) | `.pk-card-caption h3` (narrow-viewport override) + `.pk-chip` + `.pk-see-all` |
| Inter / 14px / 600 | 8 | 191 | body (semibold) | `.pk-nav-links a` + `.pk-card-caption h3` (base rule, ≥481px) |
| Inter / 14px / 400 | 17 | 17 | body (regular) | `text-neutral text-sm` result-count line + native `<option>` elements in the sort `<select>` |
| Inter / 12px / 400 | 1 | 1 | muted | brand tagline (`text-xs text-neutral`, this plan's Task 2 fix) |

The two 12px/14px-at-600 rows are **one tier, not two** — a single deliberate narrow-viewport
density step (the one last-positioned `@media (max-width: 480px)` block in `app.css`), not two
independently-drifting rules. Mapped onto the skill's heading/body/muted framework: heading =
Bebas Neue 24px; body = the 12-14px band, with font-weight (600 vs 400) as the sanctioned emphasis
lever the skill already names ("weight and color, not a new size, are the emphasis lever"); muted =
12px/400. The native `<option>` elements landing in the same 14px/400 bucket as the body-regular
text is a daisyUI/browser-default coincidence, accepted as-is per "prefer daisyUI" — not overridden
to chase the count.

**This is already at the 3-tier cap.** No font-size/weight declarations were changed in
`assets/css/app.css` for this todo — a measurement that disproves the finding is a valid
resolution, and manufacturing an edit to "do something" would only add churn. Full inventory and
disposition recorded in `ui-design-system` SKILL.md's "Type hierarchy" section (measured table),
so the cap is enforceable against a concrete baseline next time rather than re-litigated from
scratch.

Measurement tooling: `python3` + `websocket-client`/`requests` against Chrome's DevTools Protocol
(`chromium --headless=new --remote-debugging-port=9333`), not a project dependency — a one-off
script used for this measurement, not committed to the repo.
