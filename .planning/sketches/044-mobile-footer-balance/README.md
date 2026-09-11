---
sketch: 044
name: mobile-footer-balance
question: "Now that the mobile footer's chrome has been tightened (quick task 260901-ty6), does it still need to be centered, or does left-aligning it to the page's own gutter read as more balanced — and does merging the brand name + tagline onto one line help either way?"
winner: "H"
tags: [footer, mobile, alignment, spacing, gap-closure, minimalism]
---

# Sketch 044: Mobile Footer Balance

## Design Question

Real-device feedback on the shipped mobile footer (post quick-task 260901-ty6, which already
shrank the vertical chrome, wordmark size, and link ink) flagged three remaining issues: too much
empty space above the footer, the brand name + tagline sitting on two lines, and a centered layout
that read unbalanced against the page's left-aligned content.

## How to View

open .planning/sketches/044-mobile-footer-balance/index.html

## Decision History (A–H)

Two rounds of exploration, both removed from `index.html` now that H won outright — kept here for
the record:

- **Round 1 (alignment-only, A/B/C):** kept all existing content, varied only spacing/alignment
  (centered-tightened, left-aligned, hybrid). User's reaction: "anyone feels correct... something
  clear?" — none of these felt decisive because they only rearranged the same content.
- **Round 2 (content reduction, D/E/F):** dropped the tagline (redundant with the header),
  explored an icon-only mark, and a visually distinct bounded card. Better, but still framed as
  "how much to keep," not "what's actually required."
- **Research pass:** the only actual compliance requirement is the BGG attribution ("Powered by
  BGG" + logo, linking to boardgamegeek.com — confirmed via the existing `bgg_attribution/1`
  component's own documented D-04 decision in `layouts.ex`). The copyright line has no such
  requirement. 2026 mobile-footer UX consensus (UXPin, Eleken, LogRocket) also favors minimal,
  single-row, essentials-only footers over multi-line ones.
- **G (Minimal — BGG Only):** dropped tagline + copyright line, kept name + nav links + BGG line.
- **H (BGG Only, Literally) — WINNER:** user's explicit call after seeing G still had the brand
  name and nav links — "remove the another." Footer reduced to exactly the BGG compliance line,
  nothing else.

## Real Tradeoff, Verified (Not Assumed)

`FAQ`/`Contacto`/`Juntadas` are anchor links into specific sections of the "Quiénes Somos" (About)
page. Grepped the codebase to confirm: the footer was the **only** place these three links
existed — the header nav links to the About page as a whole, never to these sections directly.
Removing them from the footer doesn't make the About page unreachable, but it does remove the
direct jump to FAQ/Contact/Meetups within it. User confirmed accepting this when picking H.

## Final Implementation Notes

- `index.html` now shows only the winning variant (H) — A–G were removed from the file per an
  explicit request to declutter, not the default "preserve all variants" convention. Full
  variant text is preserved above for anyone who wants to revisit.
- The footer's icon is the **real** `priv/static/images/bgg-logo.jpeg` asset (embedded as a data
  URI in the sketch for portability), not a placeholder — confirming the actual logo reads clearly
  at the real 16×16 size used in the shipped component.
- The anchor markup deliberately mirrors the real `bgg_attribution/1` component's own documented
  reasoning (`layouts.ex:1104-1120`): plain `inline`, never `inline-flex`, so the image and text
  share one baseline by construction.

## What Changes in the Real App

- `lib/pukllay_club_web/components/layouts.ex`: the `footer/1` function's mobile-only markup
  reduces to just `<.bgg_attribution />` inside `.pk-footer-row` — brand block, links list, and
  copyright span are removed (desktop layout is a separate, unaffected question — not part of
  this sketch's scope).
- `assets/css/app.css`: the ≤480px `.pk-footer` block's gap tightens further (16px vs the
  260901-ty6 quick task's already-reduced 24px), since there's now only one line of content to
  separate from the page above it.
