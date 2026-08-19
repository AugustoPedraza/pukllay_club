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
Resting card: poster + title (gradient-scrim overlay) + a slim always-visible players/tiempo strip.

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
tested as ambiguous, so they carry real vocabulary rather than inventing a second one.

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

## Follow-up / Open Question
The desktop hover-portal is a real fix, not a sketch-only trick — it's how sophisticated
hover-preview UIs (including Netflix web) actually solve this, and it should carry into the
LiveView implementation directly (a colocated hook computing `getBoundingClientRect()`, mirroring
`carousel_row.ex`'s existing `.CarouselScroll` hook pattern). The mobile sheet is likewise meant as
the real interaction model — resolve whether "Ver detalles" from the sheet should be a true
`/juegos/:id` navigation (simpler, consistent with what the CTA already implies) or stay an in-page
sheet, before this becomes an implementation plan.
