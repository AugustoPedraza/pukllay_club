---
sketch: 042
name: editorial-tags-divider
question: "Where do editorial hashtag pills sit relative to the description and the ficha-técnica divider, and does that divider still earn its place?"
winner: "Below Title, row (10px gap), text-sm (14px), no divider, sibling chevron (align-self: flex-end), 16px to fact grid"
tags: [detail, editorial-tags, divider, gap-closure]
---

# Sketch 042: Editorial Tags & Divider

## Design Question
Phase 01.3 UAT gap G-01.3-1's original complaint: editorial hashtags (`#DuelosMemorables`-style)
render as a bare, unlabelled pill row today, positioned *after* the divider (between it and
Mecánicas). User's suggestion: give it a real "category section," or move it before the divider.
Also open since sketch 040 dropped "Sobre el juego"'s own heading: does the divider still earn its
place?

## Winner
Hashtags sit right after the title (8px gap), before the description — "Below Title" beat "Above
Title" (a kicker line before the game's own name read as disorienting). Rendered as a wrapping row
(reverted from round 11's vertical stack — the row shape suits sitting beside the title better),
10px gap between pills (widened from the stack's 4px — the type is now description-scale, needs more
air than the pill's original tiny-text gap gave it). No divider (removed round 13 — no clear job left
once section headings were already dropped in sketch 040).

## Round History
- **Round 1 — placement:** A (move before divider, still bare) picked over B (labelled "Categorías,"
  no divider) and C (folded into fact grid).
- **Round 2 — rhythm:** tag row promoted from sharing the title/description section (8px gap) to its
  own section (32px gap both sides).
- **Round 3 — color:** solid accent-fill pill ("too heavy") softened to a semi-transparent tint, no
  border.
- **Round 4 — shape:** "wondering if those still should look like pills since are hashtags." Four
  options — A (the round-3 pill, reference), B (plain text), **C (Ghost Chip — picked)**, D (flat
  underline label).
- **Round 5 — social-hashtag scale:** "should them be more like a social network hashtag?" C's 11px
  is a UI-label size, not how a hashtag reads in a caption. Three body-scale follow-ups tested — E
  (C's hover-reveal at `text-sm`), F (bold, `text-base`, tightly packed — closest to Instagram), G
  (always-underlined, `text-sm`, solves touch-discoverability). **All three rejected — the original
  11px Ghost Chip (C) was picked as "the best."**
- **Round 6 — rhythm again:** "improve spacing (top and below)." The winning ghost chip's full 32px
  surrounding gap read as excess dead space, since nothing is visible there at rest. Attempted fix: a
  negative margin on the tag row, stacked on top of `.text-col`'s shared 32px flex `gap`, to fake a
  24px result. **This broke the rendered layout** ("that last change killed the design of details").
- **Round 7 — misdiagnosed fix:** first assumed the negative-margin technique itself was the problem
  and replaced it with an explicit-`margin-top` model (`.rhythm-24`/`.rhythm-32` classes, no shared
  `gap`). Still reported broken — a screenshot showed the *actual* fault: the fact grid and Comunidad
  BGG had fallen back to unstyled browser `<dl>` defaults (stacked, indented, no gaps between BGG
  stats). The real root cause was that the round-6 rewrite (finalizing "C only") had **silently
  dropped** `.spec-list`/`.fact-cols`/`.fact-col dt`/`.bgg-link`/`.bgg-label`/`.bgg-row`/`.bgg-stat`/
  `.bgg-foot` from the stylesheet entirely — a copy-paste omission, not a spacing/margin bug at all.
- **Round 8 — actual fix:** restored the missing CSS block verbatim. The explicit-margin rhythm model
  from round 7 was correct and is kept; the fact grid and Comunidad BGG render with their intended
  styling again.
- **Round 9 — composed against the real neighbor + asymmetric rhythm:** asked to check the hashtags
  against "the accordion that today production has" — verified against the code that **no accordion
  exists on the detail page at all** (only the unrelated filter-modal checklist has one; production's
  own design doc explicitly retired an accordion here). The real neighboring interactive element is
  the description's "Ver más/Ver menos" clamp toggle — added it, functional, so the tag row's
  position can be checked in both collapsed and expanded states. Also: "hashtags look disconnected"
  persisted at symmetric 24px/24px even after round 8's fix. Made the rhythm asymmetric instead of
  retuning one shared value — 16px to the description above (tags are commentary ON it, so sit
  closer) vs. 24px to the divider below (unchanged — still a separate zone from what follows).
- **Round 10 — chevron affordance:** "improve the 'accordion' affordance with a chevron (instead of
  the text) to make it minimal and improve balance." Replaced the "Ver más"/"Ver menos" text link
  with an icon-only chevron button that rotates 180° on expand — one less piece of primary-colored
  text competing with the tag row directly below it. Built with a plain `margin-top`, not a negative
  margin against `.text-col`'s flex `gap` (the exact pattern that broke round 6) — deliberately
  avoided repeating that bug. Tap target is 32px rather than the usual 44px floor, following this
  app's own precedent for a smaller de-emphasized icon control in a secondary, low-frequency spot
  (the footer theme-toggle, shrunk to 28px, footer-scoped). `aria-expanded` drives the rotation and
  is the real accessible state; `aria-label` carries "Ver más"/"Ver menos" for screen readers since
  the chevron alone has no text.
- **Round 11 — stacked, tighter bottom:** "what if are stacked and with less bottom padding?"
  Hashtags now render one per line (`flex-direction: column`) instead of wrapping horizontally, with
  a tighter 4px internal gap (vs. the row's usual 6px wrap-gap). The divider below moved from 24px to
  16px, so the stack sits equally close (16px) to both the description above and the divider below,
  rather than the previous 16px/24px asymmetry. Scoped to this row only via a new `.tag-stack` class
  — the fact grid's own pill rows (Diseñadores, Ilustradores, Mecánicas, Temáticas) keep wrapping
  horizontally, unchanged.
- **Round 12 — match the description's typography:** "the font and its spacing should be similar to
  the description text." Round 5 tested body-scale hashtags and rejected them, but that was in the
  horizontal wrapped-row context — worth revisiting now that the layout is stacked. Hashtag type now
  matches `.desc` exactly: 16px, normal weight (not 600), 1.5 line-height, instead of the pill's
  11px/600 UI-label scale — the stack reads as a continuation of the paragraph's own typography. The
  stack's internal gap dropped from 4px to 0, since the matched line-height now supplies the vertical
  rhythm between lines on its own (a separate gap on top would have doubled it up). Shape, color, and
  the hover-reveal interaction are unchanged.
- **Round 13 — reposition relative to the title (current):** "still that hashtag breaks the
  rhythm... top? or bottom?" — clarified as relative to the title itself, not top-of-page vs.
  end-of-section (an earlier draft of this round misread it that way and built the wrong comparison;
  corrected before finalizing). Two variants:
  - **Above Title:** tags render first, before "Spirit Island" — a kicker line introducing the game,
    no margin needed above it (first element in the column).
  - **Below Title:** tags sit right after the title (8px gap, matching the reading-section's own
    internal rhythm), before the description.
  - **Divider removed in both** ("since we don't have it") — resolves the open question from round 1:
    with section headings already gone (sketch 040) and rhythm alone doing the separating work, the
    `.pk-divider` line no longer has a clear job on this page.

## How to View
open .planning/sketches/042-editorial-tags-divider/index.html — click "Ver más"/"Ver menos" to check
the tag row's position holds up against the description toggle in both variants.

## What to Look For
- Above vs. Below: does either finally resolve "breaks the rhythm," or does the tag row need a
  fundamentally different treatment regardless of where it sits relative to the title?
- Above: do hashtags introducing the game before its own name read as a natural kicker, or as
  disorienting (leading with tags before you even know what game this is)?
- Below: does pairing tags with the title (both "about this game," ahead of the prose) work better
  than commentary-on-the-description did?
- Now that the divider is gone, does the description→facts→BGG transition still read clearly from
  rhythm alone, or is something missing without it?
- **Round 14 — row, not stack:** "below looks better, but now could take full width (row) instead of
  be stacked." Reverted to the base `.pill-row`'s horizontal wrap; gap widened from 4px to 10px since
  the pill's original 6px row-gap was tuned for 11px text, not the 16px description-matched type.
- **Round 15 — smaller than main text:** "better balance, less than main text." Round 12's exact
  match with `.desc` made hashtags compete at equal weight with the title/description. Stepped down
  one size, 16px → `text-sm` (14px), so they read as secondary/supporting content while staying well
  above the original 11px pill-label scale.
- **Round 16 — chevron polish (current):** "arrow better at right" + "polished subtle animation,
  specially on mobile." Chevron: `align-self: flex-end` moves it to the column's right edge (was
  left by default). Motion: rotation switched from the generic `--duration-fast/--ease-standard` to
  `--duration-base/--ease-out-soft` — sketch 006's own validated "Subtle/Soft" motion pair, not a
  default. Added a real `:active` tap state (scale + tint), since hover never fires on touch and
  mobile needs its own feedback signal. The revealed description text now fades in on expand instead
  of snapping into view.
- **Round 17 — inline chevron + tighter fact-grid gap:** "chevron is totally disconnect of its
  function" — round 16's right-aligned block button sat isolated at the far edge, nothing tying it
  to the text. Moved inside the `<p>` as its last inline child (flush with the last visible word, the
  common "Read more ›" pattern). "A lot of space from the description to the next part" — the fact
  grid's margin-top dropped from 32px to 16px (kept in round 18).
- **Round 18 — revert the nesting, real bug fix (current):** "I can't see the chevron. Also still
  touching any part of the text makes the behaviour show/hidden." Root cause: nesting an interactive
  `<button>` inside a `-webkit-line-clamp` paragraph's `display: -webkit-box` context is a
  known-fragile combination — icon disappeared, click hit-area spread across the whole clamped block.
  Reverted to a plain sibling button (round 16's shape), `align-self: flex-end` for position, tight
  `margin-top: 0` so it still reads as connected without the broken nesting trick.
