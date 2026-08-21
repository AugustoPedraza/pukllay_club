---
created: 2026-08-18T19:00:34.489Z
title: Bump brand logo home link to 44px minimum (currently 42px)
area: ui
severity: cosmetic
files:
  - lib/pukllay_club_web/components/layouts.ex:31-39
---

## Problem

The wordmark link wrapping the isologo and "PUKLLAY CLUB" text (`Layouts.brand_logo/1`) measures
**172×42px** live — 2px under this app's documented 44px (`min-h-11`) hit-target minimum. Small
relative to the card-CTA and theme-toggle findings, but same category, and it's the page's implicit
"go home" control on every page.

Found during a retroactive UI audit against the `ui-design-system` skill. Full audit:
https://claude.ai/code/artifact/f067cf3b-84ec-41d5-970c-71e035bc7f90

## Solution

Add `min-h-11` (or equivalent padding adjustment) to the `<a>` in `layouts.ex:31-39` without disturbing
the logo/wordmark's visual alignment in the navbar. Re-measure post-fix to confirm ≥44px.

## Resolution

**Date:** 2026-08-21

**Fixed here.** Added `min-h-11` directly to the `<a>` in `Layouts.brand_logo/1` (`flex-1 flex
w-fit items-center gap-2 min-h-11`). The anchor was already `flex items-center`, so the height
floor alone was sufficient — no padding restructuring needed; the isologo/wordmark/tagline lockup
stays vertically centred inside the taller box.

Guarded by `test/pukllay_club_web/components/layouts_test.exs` (asserts `min-h-11` present on the
rendered `brand_logo/1` output). Optical alignment in the live navbar is re-confirmed in this
plan's Task 5 browser checkpoint.
