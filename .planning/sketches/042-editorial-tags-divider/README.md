---
sketch: 042
name: editorial-tags-divider
question: "Where do editorial hashtag pills sit relative to the description and the ficha-técnica divider, and does that divider still earn its place?"
winner: null
tags: [detail, editorial-tags, divider, gap-closure]
---

# Sketch 042: Editorial Tags & Divider

## Design Question
Phase 01.3 UAT gap G-01.3-1's original complaint: editorial hashtags (`#DuelosMemorables`-style)
render as a bare, unlabelled pill row today, positioned *after* the divider (between it and
Mecánicas). User's suggestion: give it a real "category section," or move it before the divider.
Also open since sketch 040 dropped "Sobre el juego"'s own heading: does the divider still earn its
place, now that this reading column increasingly relies on small labels + rhythm instead of dividing
lines?

## Winner
**Variant A, rebalanced.** Tags move up to sit right after the description, still with no label
(closest to the user's literal suggestion, picked over B's "Categorías" label and C's fold-into-grid).
Round 1 had the tag row crammed inside the same reading-section as title+description, only 8px from
the description text — too tight. Promoted to its own `.reading-section`, so it now gets the full
32px between-section rhythm both above (from the description) and below (to the divider) — reads as
its own beat instead of a tacked-on line under the prose.

## Round History
- **A: Move Before Divider, Still Bare** (picked) — tags before the divider, no label.
- B: Labelled "Categorías," No Divider — dropped.
- C: Folded Into the Fact Grid — dropped.
- Round 2 (spacing) — "I want to see it with a better balance": tag row promoted from sharing the
  title/description section (8px gap) to its own section (32px gap both sides).
- Round 3 (color) — "the colored pills... [are] too heavy": the solid `accent-bg` fill + matching
  border was the one full-opacity, "painted" element left on a page that 039-041 had otherwise moved
  entirely to outline/muted tones. Softened to a semi-transparent tint of `accent-bg` (`color-mix`
  toward the page background) with no border — still reads as "a different kind of thing" via hue,
  no longer the loudest thing on the page. Pure color change; pill shape/size/spacing untouched, so
  round 2's rhythm fix isn't affected.

`GameChips.editorial_tags/1` (the real component this replaces) has exactly one call site
(`show.ex:543`, the detail page) — this fix has no other pages to check for consistency, unlike the
site-wide sweep sketch 041 needed for the outline pill tone.

**Round 4 (current) — "wondering if those still should look like pills since are hashtags":**
questioning the pill *shape* itself, not just its color. Four tabs, all keeping round 2/3's position
and links unchanged:
- **A: Pill (current)** — round 3's softened-tint pill, kept as the reference point.
- **B: Plain Text** — no chip at all: larger, bolder colored link text, underline on hover, `#` is
  the only visual marker. Closest to how a hashtag actually reads on social platforms.
- **C: Ghost Chip** — same tap-target size/shape as every pill on the page, but invisible at rest
  (no border, no fill); the tint only appears on hover/focus.
- **D: Flat Label** — small corner radius (not full pill), a thin underline-style bottom border
  instead of a boxed border, no background.

## How to View
open .planning/sketches/042-editorial-tags-divider/index.html

## What to Look For
- A vs. B/C/D: does dropping the pill shape read as "more honestly a hashtag," or does it lose the
  visual consistency of "this row is one interactive group" that a pill shape gives for free?
- C specifically: is an invisible-until-hover treatment discoverable on mobile (no hover state) —
  does it need a permanent minimal cue (e.g. a faint underline) so touch users know it's tappable?
- D: does the underline read as "tag" or does it read as broken/missing-border pill?
- Divider still present here — worth a final check once this is composed with 039/040/041 together:
  does it still earn its place, or is it now one boundary too many?
