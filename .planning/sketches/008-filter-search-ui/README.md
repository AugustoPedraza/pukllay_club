---
sketch: 008
name: filter-search-ui
question: "What does the catalog's own filter surface look like, and how should the nav search box's live-narrowing/typeahead behave — given sketch 005's detail-page chips already link to real query params that need somewhere to land?"
winner: "C (Search-First Overlay)"
tags: [filter, search, navigation, information-architecture]
---

# Sketch 008: Filter / Search UI

## Design Question
Sketch 005's detail page links mechanics/themes/tags/difficulty chips to constructed catalog URLs
(`/?mechanics=Construcción+de+motor`, `/?weight_bands=Nivel+experto`, etc.) — but the catalog page
itself has never had a designed filter surface for those links to land on, and the nav search box
(present since sketch 001) has only ever been a static input with no results/typeahead behavior.
This sketch designs both together, since a chip-bar filter UI and a search-first UI shape the search
box very differently.

## Grounding
Filter dimensions (`weight_bands`, `mechanics`, `max_playtime`, free-text `q`) are the real assign
names from `CatalogLive.Index`'s `mount/3`, per sketch 005's own grounding notes. **Same caveat
sketch 005 flagged applies here too:** `CatalogLive.Index` has no `handle_params/3` and doesn't
`push_patch` — filter state today lives only in socket assigns, not the URL. This sketch filters a
real, client-side dataset live (proving the *interaction*), but wiring an actual `?mechanics=...`
URL to pre-select a filter on page load needs that backend work first — not proven here.

## How to View
open .planning/sketches/008-filter-search-ui/index.html

## Winner: C — Search-First Overlay
A large, centered search input leads the page (closer to the project's core value — "describe what
you want in plain Spanish" — than a typical filter bar), with quick-filter suggestion chips
appearing live below it as you type, and a "Más filtros ▾" trigger for the rest. Chosen over the
other two originally-sketched variants (**A: Chip Bar + Popovers** — Airbnb-style row under the
nav; **B: Sidebar Drawer** — classic e-commerce facet sidebar/drawer, assumed a flat results grid
that didn't obviously coexist with the shelf/carousel browsing model). A and B are not preserved as
tabs in this file — the design question was resolved decisively enough that the user asked to drop
them rather than keep them for comparison.

Two rounds of refinement after the initial build:

1. **Results as a horizontal shelf, not a vertical grid.** Filtered results render in the same
   edge-fade rail (`.rail-wrap`/`.rail`, reused verbatim from 001-D's real shelf mechanics) as the
   home page's shelves, instead of a wrapping grid — so a filtered catalog view reads as the same
   Netflix-shelf language, not a different UI mode. Real mobile treatment was added at the same
   time (the original draft had none): tighter search-hero padding, and the suggestion-chip row +
   results rail both go horizontal-scroll with edge-fade at ≤640px.
2. **"Más filtros" opens a real filters panel**, not an inline expand-in-place row. Desktop gets an
   anchored popover (positioned under the trigger, matching the popover interaction already
   established in this sketch set's original variant A); mobile gets a bottom-sheet drawer (slide up
   from the bottom with a drag-handle affordance, matching the card's mobile-sheet pattern from
   002-D/007) — reusing two already-validated interaction patterns from elsewhere in the project
   rather than inventing a third one just for this panel. Both share the same filter-group content
   (Dificultad / Mecánica / Duración) and end in a "✕ Limpiar filtros" row, disabled when no filter
   is active.

## What to Look For
- Type a partial title — do the mechanic suggestion chips feel fast/relevant without competing
  visually with the results rail below?
- Open "Más filtros" on desktop width — does the popover feel anchored/connected to the trigger, or
  does it read as an unrelated floating box?
- Shrink to mobile width and open "Más filtros" — does the bottom-sheet drawer feel consistent with
  how the game cards already expand on mobile (002-D/007), or like a different pattern?
- Apply 2+ filters together (e.g. Ingenio estratega + a mechanic) — does the empty state ("Ningún
  juego coincide…") read as helpful or like a dead end?
- Scroll the results rail on both desktop (hover) and mobile (touch) — does the edge-fade read
  correctly at both card sizes (190px desktop / 128px mobile)?
