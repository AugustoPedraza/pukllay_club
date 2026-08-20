---
sketch: 003
name: page-shell
question: "Does a shared header+footer shell work across catalog, detail, and about page skeletons — with the header going quiet off-catalog and the footer carrying mission, links, contact, and required BGG attribution?"
winner: "C"
tags: [layout, header, footer, navigation, compliance]
---

# Sketch 003: Page Shell (Header + Footer)

## Design Question
The catalog nav (logo, sticky behavior, shelf anchors, mobile chip row) is already settled and
shipped to production (sketch 001 winner D → `Layouts.app`/`.pk-nav`). This sketch asks the next
question: does a **shared** shell hold up once there are three page types — catalog (shelf
browsing), detail (`/juegos/:id`), and a new "about" page (static content) — and what does the
**footer** look like, since none exists yet anywhere in the project?

## Grounding
- Header markup/class names (`.pk-header`, `.pk-nav`, `.pk-nav-links`, `.pk-nav-search`,
  `.pk-chip-nav`, `.pk-chip`, `.pk-gutter`) mirror the real, already-shipped
  `PukllayClubWeb.Layouts.app/1` component and `assets/css/app.css` — this isn't a hypothetical
  header, it's the real one, extended with a "quiet" state.
- Detail skeleton's fields (name, cover, players, playtime, difficulty) come from the real
  `CatalogLive.Show` liveview (`lib/pukllay_club_web/live/catalog_live/show.ex`) — currently a
  plain, undesigned `<dl>` list. Full detail-page design is sketch 005; this sketch only proves the
  shell wraps it.
- About page content sections (mission, how it works, the club, FAQ/vocabulary) come directly from
  your answer to the sketch intake — no about route or content exists in production yet. Full
  content design is sketch 004; this sketch only proves the shell wraps it.
- **BGG attribution is a compliance requirement, not a design choice** — you flagged that
  BoardGameGeek's terms require a visible "Powered by BGG" badge on any public-facing app that
  surfaces their data. Every variant below includes it. The badge here is a **labeled placeholder**
  (a simple "BGG" mark + text) — before shipping, pull the actual approved badge asset from BGG's
  API/brand terms page; don't ship the placeholder as-is.
- **Isologo placeholder:** no vector isologo asset exists in the repo yet (`priv/static/images/`
  only has the Phoenix default `logo.svg`; production's `Layouts.brand_logo/1` already gates on the
  file's absence and falls back to a text wordmark). This sketch uses a simple hexagon placeholder
  mark in the header so the layout proportions are right — swap in the real isologo SVG when it
  exists, no structural change needed.

## How to View
open .planning/sketches/003-page-shell/index.html

Use the **Sketch control** bar (dashed background, just under the header) to switch between
Catálogo / Detalle / Acerca de within each variant — watch the header change with it.

## Variants
- **A: Minimal Single Bar** — logo/tagline, inline link row, BGG badge, and copyright all in one
  slim horizontal bar. Cheapest to ship, smallest footprint, but has no room for a mission blurb or
  contact info beyond a link.
- **B: Multi-Column Rich** — four columns (brand + mission blurb, Explorar links, Club links,
  Contacto + BGG badge) over a slim copyright bottom bar. Fits everything from your content answer
  (mission, links, contact, legal) with clear grouping, at the cost of a taller footer.
- **C: Two-Tier (Mission Band)** — a full-width primary-color band leads with the mission statement
  and social icons (the "why we exist" pitch lives in the footer of every page), then a slim
  utility bar underneath carries links, the BGG badge, and copyright. Splits "persuasion" from
  "utility" instead of blending them.

## Header behavior (same across all 3 variants)
- **Catalog page:** full header — shelf anchor links, search box, mobile chip row.
- **Detail page:** anchors/search/chips disappear; a breadcrumb (`Catálogo / {game name}`) takes
  their place so there's still a way back and a sense of location.
- **About page:** anchors/search/chips disappear; just "Acerca de" as a static label — no breadcrumb
  needed since it's a top-level destination, not a drill-down.
- Logo, theme toggle, and sticky scroll-tint behavior stay identical everywhere.

## Winner
**C — Two-Tier (Mission Band).** The primary-color mission band leads with the "why we exist"
pitch on every page (not just about), then a slim utility bar underneath carries links, the BGG
badge, and copyright — splitting persuasion from utility instead of blending them into one dense
block (A) or four columns (B).

## What to Look For
- Switch between Catálogo / Detalle / Acerca de in each variant — does the header change feel like
  the same component adapting, or like a different header on each page?
- Compare footer weight against page content — does B or C feel too heavy under the sparse detail-
  skeleton, or does A feel too thin under the about-skeleton's four sections?
- Is the BGG badge visible enough to satisfy a compliance requirement, or does it read as an
  afterthought in any variant?
- Shrink the viewport (toolbar → 📱 375) — check the header's mobile chip row (catalog only) and how
  each footer variant's columns/bar collapse.
- Scroll down on any page — confirm the header's scroll-tint (flat background, no blur) still
  triggers correctly.
