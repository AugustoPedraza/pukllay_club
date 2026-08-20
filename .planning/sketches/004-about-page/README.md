---
sketch: 004
name: about-page
question: "Do the about page's four sections (mission, how it works, the club, FAQ/vocabulary) read well as one page, and what structure suits them — flowing narrative, marketing-style bands, or narrative + accordion?"
winner: "B"
tags: [content, about, faq, carousel]
---

# Sketch 004: About Page Content

## Design Question
There's no about page or route in production yet. You confirmed the content should cover four
things: mission/why we exist, how it works, the club itself, and an FAQ/vocabulary primer. This
sketch explores how those four sections should be structured on the page.

## Grounding
Built inside sketch 003's winning shell (variant C: quiet "Acerca de" header, two-tier mission-band
footer). Copy is real draft Spanish copy for this project's actual value prop (plain-language
matching, no jargon assumed), not lorem ipsum — treat it as a first draft, not final.

## How to View
open .planning/sketches/004-about-page/index.html

## Variants
- **A: Single Flowing Scroll** — a centered lead statement, then all four sections stacked with
  plain dividers, FAQ as a simple definition list. Cheapest, most textual, closest to a classic
  "about" page.
- **B: Alternating Bands** — full-width bands alternating background tint and left/right image-
  placeholder + text layout (marketing-page style), FAQ collapsed into a simpler closing band.
  Most visually rich, but the most net-new component work (band layout, visual placeholders with
  no real photography yet).
- **C: Narrative + FAQ Accordion** — "how it works" becomes 3 icon step-cards up top (more scannable
  than prose), mission/club stay as narrative sections, and FAQ/vocabulary becomes an interactive
  accordion — since Q&A content benefits from being scannable/collapsible rather than a wall of
  text at the bottom of an already-long page.

## Winner
**B — Alternating Bands**, refined: each band's static gradient placeholder became a working
image carousel (arrows + dots, 3 slides) instead of a single static visual — since a real "club"
section will eventually have several photos (meetups, game shelf, people playing), not one hero
image per section. Structurally this is a real `<img>` carousel once photography exists; the
sketch's slides are gradient-tinted placeholders standing in for photos.

**Fixed a real desktop alignment bug:** the tinted "Cómo funciona" band applied the `--pk-gutter`
horizontal padding twice — once on its full-bleed wrapper, again implicitly via its inner
`max-width: 1100px` box — so its content sat ~2rem wider than the flanking non-tint bands on
desktop. Invisible on mobile, since the viewport is already narrower than 1100px there, so the
double-padding never has room to manifest. Fixed by moving the wrapper to vertical-only padding
and letting `.band-inner` carry the horizontal gutter itself, matching the non-tint bands' box
math exactly.

**Real content (copy, final photos, FAQ answers) is deliberately deferred** — the layout is built
to hold roughly-real copy lengths and a multi-image carousel now, so it won't need structural
rework once real content lands; writing the actual mission statement / club photos / FAQ answers
is a separate content task, not blocked on this layout decision.

## What to Look For
- Does the mission statement feel redundant appearing both in the page's lead section AND the
  footer's mission band right below it? (Worth flagging if so — may want to vary the footer's
  copy specifically on the about page, or drop the lead entirely and let the footer carry it.)
- In variant B: the `band-visual` placeholders are just gradient boxes with an emoji — there's no
  real photography/illustration for "the club" yet. Does this direction only work once real photos
  exist, or does it need a fallback?
- In variant C: click through the FAQ accordion — does collapsing make the page feel shorter/more
  approachable, or does hiding content by default work against a page whose whole point is
  explaining things to newcomers?
- Which variant would you actually want to keep reading past the mission section on mobile?
