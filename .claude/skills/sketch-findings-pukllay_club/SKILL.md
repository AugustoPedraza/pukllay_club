---
name: sketch-findings-pukllay_club
description: Validated design decisions, CSS patterns, and visual direction from sketch experiments. Auto-loaded during UI implementation on pukllay_club.
---

<context>
## Project: pukllay_club

Rework of the already-shipped Phase 1 catalog browse screen (approved brand-locked UI-SPEC, live
and UAT-verified — not greenfield). The original complaint: card hierarchy/rhythm was broken
(title, weight badge, editorial tags, and mechanic chips crammed into one dense stack), and the
carousel rows read as one continuous scrollable grid rather than distinct Netflix-style shelves.

Direction: poster-forward, human-first (teach through plain Spanish, not hobbyist jargon), riffing
on Netflix's TV/web catalog pattern — section/row name + poster carry the resting visual weight,
secondary detail (players, playtime, difficulty, one editorial tag, CTA) lives behind a hover/tap
interaction rather than being permanently visible on a dense card.

Extended outward from the browse screen to the rest of the site: a shared page shell (header +
footer) that adapts across the catalog, the game detail page (`/juegos/:id`), and a new static
"about" page — the detail page itself (desktop buy-box, mobile sticky chrome, reservation flow),
and the about page's content structure.

Reference points: Airbnb-style card grid (big image, minimal chrome), Netflix web/SmartTV catalog
(row-first navigation, poster-primary cards, focus/hover expand-to-reveal-details), Amazon/Airbnb/
Booking.com mobile product pages (sticky bottom action bar, buy-box pattern).

Sketch sessions wrapped: 2026-08-19 (sketches 001–002), 2026-08-20 (sketches 003–005)
</context>

<design_direction>
## Overall Direction

Full-bleed, edge-fade Netflix-style shelves with a real sticky nav (desktop) / category-chip row
(mobile) for navigation. Cards are deliberately minimal at rest — poster + single-line title only,
no metadata — with all secondary detail (players, playtime, a beginner-legible difficulty
indicator, one editorial tag, CTA) revealed through interaction: a fixed-size, fixed-content
preview that pops forward on desktop hover (outside the scrolling rail, to sidestep a real CSS
overflow-clipping bug), and a full-screen bottom sheet on mobile tap.

The single most load-bearing principle across both sketches: **when two surfaces are meant to look
the same, give them one shared CSS class per field — never two independently-declared rules with
matching values.** Every real bug found during iteration (misaligned nav padding, divergent title/
description font-sizes, divergent poster aspect-ratios, the mobile "broken" expand) traced back to
either independently-declared "matching" values drifting apart, or a panel escaping/being clipped
by a scrolling container's implied overflow behavior.

Palette, typography, and spacing tokens: `sources/themes/default.css` (mirrors the real brand
tokens in `assets/css/app.css` / 01-UI-SPEC.md — Bebas Neue display + Inter body, the brand
purple/lavender palette, 4px-multiple spacing scale).

Two more load-bearing principles emerged from the shell/detail/about sketches:

- **Prefer `position: sticky` over `position: fixed` whenever the element has a natural container
  boundary to stop at** (a sidebar beside scrolling content) — it un-sticks for free at the end of
  that container, no JS needed. Reach for `fixed` + an `IntersectionObserver` watching a real
  boundary element (like `<footer>`) only when there's no natural containing block to bound it,
  e.g. a page-spanning mobile action bar.
- **Equal-specificity CSS rules resolve by source order, not by which condition is "more specific"
  feeling** — a base rule and its `@media` override at the same specificity silently pick whichever
  is declared later in the file, regardless of which media query actually matches. Caused a real,
  multi-round bug (a mobile CTA bar was `display: none` at every width for several rounds). Verify
  cascade order by reading literal source-line order when two rules target the same property at the
  same specificity, not by guessing from a screenshot.
</design_direction>

<findings_index>
## Design Areas

| Area | Reference | Key Decision |
|------|-----------|--------------|
| Layout & Navigation | references/layout-navigation.md | Full-bleed edge-fade shelves + aligned sticky nav; mobile gets a category-chip row instead of nav links |
| Card & Preview Interaction | references/card-interaction.md | Minimal resting card (poster + title only); fixed-size hover-portal (desktop) / full-screen sheet (mobile) rendered outside the scrolling rail, sharing identical CSS classes for every field |
| Page Shell (Header + Footer) | references/page-shell.md | One header component with 3 states (full nav / breadcrumb / static label) across catalog, detail, about; Two-Tier Mission Band footer splits persuasion from utility; BGG attribution badge is compliance-required |
| About Page Content | references/about-page-content.md | Alternating tinted/untinted bands, each with a working image carousel instead of a static hero; FAQ as a closing band, not an accordion |
| Detail Page — Layout & Content | references/detail-page-layout.md | Desktop buy-box (sticky image+CTA) beside a scrolling reading column, no accordion; ficha técnica as a 2-col grid; every field grounded in the real schema including its gaps; "Juegos similares" shelf reuses the real home-page carousel component |
| Detail Page — Mobile & Interaction Patterns | references/detail-page-mobile-interaction.md | Mobile CTA bar hides while scrolling, parks at the footer via IntersectionObserver; sticky title-echo bar with bounce-to-top; lightbox/carousel sync; WhatsApp reservation flow |

## Theme

The winning theme file is at `sources/themes/default.css`.

## Source Files

Original sketch HTML files are preserved in `sources/` for complete reference — each is a
self-contained, interactive HTML mockup (no build step) that can be opened directly in a browser.
</findings_index>

<metadata>
## Processed Sketches

- 001-shelf-structure
- 002-card-hierarchy
- 003-page-shell
- 004-about-page
- 005-detail-page
</metadata>
