---
sketch: 002
name: card-hierarchy
question: "What belongs on the card at rest vs. behind an expand, given the real schema fields (players, playtime, age, weight, tags, mechanics)?"
winner: "D"
tags: [card, information-architecture, interaction]
---

# Sketch 002: Card Hierarchy

## Design Question
The production card (`lib/pukllay_club_web/components/game_card.ex`) currently shows title, weight
badge, up to 2 editorial tags, and up to 4 mechanic chips — but never shows player count or
playtime, despite those being real `Game` schema fields and arguably more decision-critical for
"will this work tonight" than a wall of mechanic chips. Explored three splits of what belongs at
rest vs. behind an interaction (A: pure poster-expand, B: essentials always-visible, C: hybrid
slim-strip). **C won**, then was iterated into **D** across several rounds fixing real bugs found
along the way — A/B/C are no longer in the file; only D remains.

## Grounding
Data shape is real (`lib/pukllay_club/catalog/game.ex`'s `min_players`/`max_players`/`min_playtime`/
`max_playtime`/`weight_band`), values are representative samples, not a live seed-data pull. The 6
sample games deliberately cover edge cases: a no-tag game (Wingspan), a long title that must clamp
(Terraforming Mars: Ares Expedition), a fixed player/time count with no range (7 Wonders Duel — "2"
not "2-2"). Weight band labels are pulled verbatim from 01-VOCABULARY.md.

## How to View
open .planning/sketches/002-card-hierarchy/index.html

## Current design (variant D)
Resting card matches sketch 001 variant D's card exactly, including content — same class names
(`.poster-art`, `.cap`), same values: poster art, then a plain caption block below with just the
title in dark text on a `--color-surface` background, clamped to 2 lines. Nothing else.

Players/tiempo/dificultad are **preview-only** — they never appear on the resting card, only inside
the desktop hover-portal and the mobile sheet. An earlier round added a players/tiempo strip to the
resting card's caption block; that's been removed. (Even earlier than that, the title itself was
overlaid on the poster with a gradient scrim instead of sitting in a plain caption block below it —
also fixed, in a prior round.)

The caption's title is anchored toward the top (tight padding right under the poster, more room
trailing below) rather than vertically centered — centering made it read as a floating label
disconnected from the image above it; anchoring it to the poster edge is what makes a caption read
as "belonging to" its image in most card UIs.

**Title is single-line only, always** (settled after comparing 3 options — see below). Reserving
room for a possible 2nd line was the actual source of the "weird empty space" complaint: a short
title like "Catán" left a visible gap below it even when top-anchored. Dropping the 2-line
allowance entirely removes the whole class of problem — every caption is naturally the same tight
height, no reserved-space or row-alignment trick needed. Long titles (Terraforming Mars: Ares
Expedition) now truncate harder with an ellipsis instead of wrapping.

Options considered:
- **1-line only, always (chosen)** — simplest, no empty-space edge case possible.
- Natural height, no forced minimum — zero wasted space, but reintroduces uneven row bottoms when a
  2-line title sits next to 1-line ones (the original row-misalignment complaint).
- Keep 2-line reservation, re-centered — still leaves visible empty space for short titles, just
  repositioned rather than removed.

**Considered and rejected: dropping the caption entirely** (Netflix's own pattern — title baked into
the poster art, no separate text). Not a good fit here: Netflix's posters are professionally
designed with the title as part of the key art, and its audience often recognizes titles by poster
alone. This catalog's ~400 games are real box-cover photography of wildly inconsistent legibility
across publishers, for an audience that explicitly does *not* already recognize games by sight (the
project's whole premise). A guaranteed-legible UI caption is the safer choice for this catalog, even
at the cost of Netflix's cleaner poster-wall look.

**Desktop:** hovering a card (after a 300ms hover-intent delay, so sweeping across a row doesn't
fire a preview per card) pops a preview forward — 1.65× the card's size, centered on it, strong
shadow — matching actual desktop Netflix behavior, not an inline panel attached below the card. The
preview is fixed-size regardless of game data (title + a players/tiempo row + a weight/difficulty
badge + CTA — no tag, no long description, so nothing variable-length can change its height). It
renders through a `position: fixed` portal appended outside the scrolling rail, positioned via
`getBoundingClientRect()`, so it can never be clipped by the rail's overflow.

**Mobile:** tapping a card opens a full-screen bottom sheet instead of an inline expand — the same
pattern Netflix's own mobile app uses, for the same underlying reason (an inline expand inside a
touch-scrolling rail is fragile on small screens). The sheet has more room, so it additionally shows
the game's theme/flavor description (clamped to 3 lines) and its editorial tag, if any.

**Difficulty, not age.** Every metadata surface (strip, portal, sheet) replaced a raw `min_age`
number with a difficulty cue derived from `weight_band`: 3 dots (filled = weightLevel 1-3) paired
with the same official band label used elsewhere in the app (row headings, chips) — dots alone
tested as ambiguous, so they carry real vocabulary rather than inventing a second one. It renders as
a third item inside the same players/tiempo facts row (not a separate colored pill — a standalone
badge tested as louder than a metadata detail should be), so all three facts share identical
size/color/weight, and the row is styled once and shared verbatim by the portal and the sheet —
no per-surface overrides, so the two can't quietly drift out of sync with each other again.

**Theme text is on both surfaces now, and genuinely identical.** The desktop preview and the mobile
sheet both show the game's theme/flavor description via one shared `.theme-text` rule — same
font-size, same 3-line clamp, so the same game reads the same description either way. An earlier
round gave the portal a different clamp (2 lines) and a smaller font than the sheet, which read as
literally different text for the same game — that divergence is gone.

**Facts row: players left, tiempo center, dificultad right.** `justify-content: space-between`
across the row's 3 fixed items, applied once in the shared `.facts-row` rule so it can't diverge
between the portal and the sheet again.

CTA ("Ver detalles") is secondary (outlined, not filled) everywhere on this card — it's a
lower-commitment action than whatever interaction got the user here.

**Deliberate finding, still open:** mechanic chips and editorial tags never appear in the desktop
hover preview — only in the mobile sheet. If mechanics matter enough at a glance to justify space
even in the compact preview, that's worth flagging back rather than assuming this is final.

## Fix history (why some earlier bugs mattered)
- **Mobile "broken" expand (round 2):** the original C's expand panel was `position: absolute`
  inside the horizontally-scrolling rail. `overflow-x: auto` implicitly clips the vertical axis too
  per the CSS spec — not a mistake you can style around from inside the rail. Fixed by moving the
  desktop preview to a portal outside the rail, and mobile to a full-screen sheet entirely (both are
  the real interaction model, not sketch-only tricks).
- **Inconsistent preview size (round 4):** height varied per game because of conditional content
  (tag chip present/absent, variable-length descriptor). Fixed by removing that variable content
  from the compact preview, not by constraining a box around it.
- **Missing title text on the resting card (round 4):** `.poster-title` styling had only ever been
  written for variants A/C, never D — so D's title rendered completely unstyled, squished into the
  flex-centered poster next to the icon instead of the intended gradient-scrim overlay.

## Metadata treatment (settled)
Players/tiempo/dificultad now render as three small pills on their own row, right-aligned, directly
above the title — not stacked below it, not sharing the title's row. One shared function
(`pillsRowHTML`) used identically by the portal and the sheet.

An earlier attempt put the pills beside the title on the same row (title left, pills right,
vertically centered). That hit a real CSS bug: a `-webkit-line-clamp`-truncated title's intrinsic
width for flex-shrink purposes isn't reliably based on its clamped size across browsers, so the
"truncated" title didn't actually shrink and visually bled into the pills. Giving the pills their
own row sidesteps the bug entirely — the title is full-width with nothing to share space with, so
its normal truncation works correctly again.

Pills start left (flush with the title) and use `justify-content: space-between` across the row, so
the last pill lands flush with the row's right edge — starts aligned with the title, ends aligned
with the content's right edge, rather than either bunching left or floating fully right.

**Title is now one shared `.card-title` style for the portal and the sheet** — same font-size
(text-display, 28px), same 2-line clamp (was 1 line). The portal previously used a smaller size
(text-xl, 20px) than the sheet — same class of mistake as the theme-text divergence fixed earlier:
two different sizes for the same field read as literally different content. The 2-line allowance
also resolves the truncation trade-off from the 1-line version — a long title (Terraforming Mars:
Ares Expedition) now has room to wrap once instead of cutting off after a handful of characters.

## Portal sized as a fixed modal, not a scaled-up card
The portal's size was `rect.width * 1.65` — a multiple of the tiny 190px resting card. Since the
title/theme text share exact font sizes with the mobile sheet, a size derived from the narrow card
made that shared text feel oversized/cramped relative to its box (same px, less room than the
sheet has). Switched to a fixed `PORTAL_WIDTH = 360px`, independent of the card's own width — a
proportion closer to the mobile sheet's, so the identical fonts get comparable breathing room on
both surfaces instead of just identical pixel values in differently-proportioned boxes.

## Poster aspect-ratio unified
Found a real divergence between the two surfaces, not a deliberate one: the portal's poster used
`aspect-ratio: 1/0.8` (near-square) while the sheet's used `16/9` (widescreen) — the same poster
image rendering at two different crops/proportions depending on which surface opened it. The
sheet's `16/9` was already correct; the portal now matches it (an earlier pass mistakenly changed
both to the resting card's ratio instead — corrected).

## Follow-up / Open Question
The desktop hover-portal is a real fix, not a sketch-only trick — it's how sophisticated
hover-preview UIs (including Netflix web) actually solve this, and it should carry into the
LiveView implementation directly (a colocated hook computing `getBoundingClientRect()`, mirroring
`carousel_row.ex`'s existing `.CarouselScroll` hook pattern). The mobile sheet is likewise meant as
the real interaction model — resolve whether "Ver detalles" from the sheet should be a true
`/juegos/:id` navigation (simpler, consistent with what the CTA already implies) or stay an in-page
sheet, before this becomes an implementation plan.
