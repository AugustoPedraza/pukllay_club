# Sketch Wrap-Up Summary

**Date:** 2026-08-19
**Sketches processed:** 2
**Design areas:** Layout & Navigation, Card & Preview Interaction
**Skill output:** `./.claude/skills/sketch-findings-pukllay_club/`

## Included Sketches
| # | Name | Winner | Design Area |
|---|------|--------|-------------|
| 001 | shelf-structure | D (Edge-Fade, refined) | Layout & Navigation |
| 002 | card-hierarchy | D (hybrid, pop-forward preview) | Card & Preview Interaction |

## Excluded Sketches
| # | Name | Reason |
|---|------|--------|
| — | — | none |

Note: sketch 003 (motion-system) was proposed during initial decomposition but never built — no
`.planning/sketches/003-*` directory exists, so it isn't part of this wrap-up. It remains an open
item for a future `/gsd-sketch` session if a dedicated motion system is still worth exploring.

## Design Direction
Full-bleed, edge-fade Netflix-style shelves with a real sticky nav (desktop) / category-chip row
(mobile). Cards are minimal at rest (poster + single-line title only); all secondary detail
(players, playtime, a beginner-legible difficulty indicator replacing raw min-age, one editorial
tag, CTA) lives behind interaction — a fixed-size hover-portal on desktop (rendered outside the
scrolling rail to avoid a real CSS overflow-clipping bug) and a full-screen bottom sheet on mobile.

## Key Decisions
- **Layout:** full-bleed rows, edge-fade scroll cue (not hover-only prev/next), nav padding
  strictly matched to row-content padding, mobile category-chip row replacing nav links,
  trailing "Ver todo" tile per shelf, hashtag row titles rendered as plain text.
- **Card:** poster + title only at rest, no metadata; single-line ellipsis title (not multi-line
  clamp — avoids a reserved-space empty-gap problem); title anchored to the poster edge, not
  centered.
- **Interaction:** 300ms hover-intent delay before the desktop preview appears; preview rendered
  through a `position:fixed` portal outside the rail (sidesteps `overflow-x:auto`'s implied
  `overflow-y:auto` clipping); preview sized as a fixed "modal" width, not a multiple of the small
  resting card.
- **Consistency discipline:** every field meant to look identical between the desktop preview and
  the mobile sheet (title, description, facts row, poster aspect-ratio, CTA style) uses one shared
  CSS class — the recurring bug pattern this session was two independently-declared "matching"
  rules quietly drifting apart.
- **Difficulty over age:** raw `min_age` replaced everywhere with a 3-dot difficulty indicator
  (muted color) paired with the existing weight-band label, not a second invented vocabulary.
- **CTA:** secondary/outlined everywhere on this card, not filled — it's a lower-commitment action
  than the interaction that revealed it.

## Open Items Carried Forward
- Whether "Ver detalles" from the mobile sheet should be a real `/juegos/:id` navigation or stay
  an in-page sheet.
- Whether mechanic chips or editorial tags deserve a place in the compact desktop preview
  (currently: no — only the mobile sheet shows the tag; mechanics never appear on the card).
- Touch diagonal-swipe scroll ambiguity on the horizontal rails needs device testing once this
  ships as real Phoenix/LiveView markup (`touch-action: pan-y`/`pan-x` is the standard mitigation).
- The hover-portal positioning logic (`getBoundingClientRect()`-based) should carry directly into
  a colocated LiveView hook, mirroring `carousel_row.ex`'s existing `.CarouselScroll` hook pattern.
