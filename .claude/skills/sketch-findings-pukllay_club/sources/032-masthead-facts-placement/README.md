---
sketch: 032
name: masthead-facts-placement
question: "Where should the facts pills (players/tiempo/dificultad) sit relative to the poster carousel, how should the Reservar CTA be visually separated from it, and does the whole page column need to match the header/footer shell width?"
winner: "A"
tags: [detail, masthead, buybox, cta, layout, gap-closure]
---

# Sketch 032: Masthead Facts Placement

## Design Question
UAT gaps G-01.2-11 (mobile) and G-01.2-12 (desktop), both against the shipped
`CatalogLive.Show` detail page (`lib/pukllay_club_web/live/catalog_live/show.ex`,
`assets/css/app.css` `.pk-detail-masthead` block):

- The facts pills (`GamePreview.facts_row`) currently render as an **absolute overlay on top of
  the poster image** on mobile (`.pk-facts-overlay`) — user wants them **above** the carousel, not
  over it, spanning the column width with justified balance.
- The mobile gallery dots (`.pk-gallery-dots`) aren't centered (currently left-aligned by default
  flex behavior).
- On desktop, the Reservar button (`.pk-poster-reserve`) sits **inside** the same bordered/shadowed
  `.pk-poster-col` panel as the poster image and thumbnails — reads as "part of the carousel."
  User wants it visually separated.
- The masthead (`.pk-detail-masthead`, capped at `--pk-detail-col-width: 1100px`) is narrower than
  the header/footer's own shell width (`max-w-7xl` + `pk-gutter` = 1280px box, 1216px content) —
  "the content isn't using the width defined by header and footer." The "Juegos similares" shelf
  below already correctly uses the wider shell width, per the user's own note — so the masthead is
  the one that needs to widen, not the shelf that needs to narrow.

## Grounding
Real component/class names throughout: `.pk-facts-row`/`.pk-fact` (`GamePreview.facts_row`),
`.pk-poster-col`/`.pk-poster-frame` (sketch 027 winner B, elevated-shadow panel),
`.pk-gallery-dots` (sketch 011.2-17 D3 winner), `.pk-mobile-cta-bar`/`.pk-cta-bar-inner` (sketch
028 winner D, later simplified to single-button by 01.2-18), `.pk-divider`/`.pk-shelf-separator`
(01.2-18). Sample game content (`Terraforming Mars: Ares Expedition`, mecánicas/temáticas/ficha
técnica) reused verbatim from sketch 005 for continuity across the sketch series. Deliberately
**out of scope** for this sketch (handled by sibling sketches instead, so this one doesn't
conflate three separate questions): the redundant category-pill/descriptor block (034), the image
lightbox's contrast (033), and section-to-section whitespace rhythm (035) — this sketch's editorial
tags/weight-badge/chip rows below the divider render unchanged from production.

## How to View
open .planning/sketches/032-masthead-facts-placement/index.html

Widen/narrow the real browser window past 768px to see the desktop⇄mobile swap — use real window
resizing or devtools device emulation, not the toolbar's viewport buttons alone (see sketch 005's
own note on why a capped `max-width` wrapper can't drive `@media`). Each variant's dashed "Header"
and "Footer" reference bars share the exact same 1280px+gutter box as the real shell, so the
masthead/shelf/CTA-bar width fix is directly checkable by eye — the poster/text column edges
should now land flush with those dashed bars at every width above 768px.

## Winner: A — Pills Above, CTA Detached
Minimal-diff from production: same 2-column grid; pills move from an absolute image overlay to a
plain in-flow row above the poster panel (justified on mobile). Reservar moves out of the
bordered/shadowed poster panel with a visible gap below it — reads as a separate action, not fused
with the poster/carousel. Picked directly, no revision requested.

## Round history
- **Round 1** — three structural directions explored: **A Pills Above, CTA Detached** (minimal
  diff from today's layout); **B Full-Width Bar, Standalone Buy Panel** (pills become a full-bleed
  bar above the whole two-column grid, CTA becomes its own standalone panel — most dramatic
  separation); **C Buy-Box in Text Column** (CTA moves entirely into the text column next to the
  title, e-commerce buy-box pattern, desktop-only).
- **Bug found before review** — the three `.variant` wrapper `<div>`s only carried an `id`
  matching the CSS selectors (`id="variant-b"`), not the actual class the layout rules targeted
  (`.variant-b ...`). Every variant-scoped rule silently matched nothing, so all three variants
  rendered as plain stacked divs regardless of viewport width — including the desktop two-column
  grid, which never activated. Fixed by adding the matching class (`class="variant variant-a"`,
  etc.) alongside each `id`. Flagged here since it's exactly the kind of mistake worth watching for
  in future multi-variant sketches: verify the tab-switching `id` and the layout-scoping `class`
  are the same string on the same element, not just similarly named.
- **Decision** — A picked directly once the bug was fixed and the real desktop layout was visible.
  No further rounds requested. B/C removed from `index.html` (A only).

## What to Look For
- Do the pills read as clearly separate from the poster image (not overlapping/obscuring it) at
  both viewports?
- Does the Reservar button read as a deliberate, separate decision — not a fourth carousel control?
- On mobile, do the pills feel balanced across the column width (not cramped to one side)?
- Are the dots visibly centered under the poster?
- Does the masthead's left/right edges now align with the dashed header/footer reference bars at
  desktop widths, instead of reading narrower?
- Which CTA placement (A: below panel / B: standalone full-width bar / C: buy-box near title) best
  matches "the reserve button as the single primary decision, separated from the carousel"?
