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

Reference points: Airbnb-style card grid (big image, minimal chrome), Netflix web/SmartTV catalog
(row-first navigation, poster-primary cards, focus/hover expand-to-reveal-details).

Sketch sessions wrapped: 2026-08-19
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
</design_direction>

<findings_index>
## Design Areas

| Area | Reference | Key Decision |
|------|-----------|--------------|
| Layout & Navigation | references/layout-navigation.md | Full-bleed edge-fade shelves + aligned sticky nav; mobile gets a category-chip row instead of nav links |
| Card & Preview Interaction | references/card-interaction.md | Minimal resting card (poster + title only); fixed-size hover-portal (desktop) / full-screen sheet (mobile) rendered outside the scrolling rail, sharing identical CSS classes for every field |

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
</metadata>
