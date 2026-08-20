---
sketch: 005
name: detail-page
question: "What does the full game detail page (/juegos/:id) look like inside the shell — hero, facts, description, mechanics — given production's current plain, undesigned layout?"
winner: "B"
tags: [layout, detail, card, accordion, share, whatsapp, reservation]
---

# Sketch 005: Game Detail Page

## Design Question
`CatalogLive.Show` (`lib/pukllay_club_web/live/catalog_live/show.ex`) already renders every real
field — cover image, gallery, name, weight band, editorial tags, mechanic/theme chips,
players/playtime/age/year, designers, publishers, description — but as a plain, unstyled `<dl>`
list. This sketch explores what a properly designed detail page looks like, reusing the
facts-row/difficulty-dots/chip patterns already settled in sketch 002 and the shell settled in 003.

## Grounding
All fields and their real names come directly from `show.ex` and its `<dl>` block — no invented
data shape. The gallery-thumbnail-click-swaps-main-image interaction mirrors the real
`handle_event("select-image", ...)` behavior already implemented in production, not a sketch-only
trick. Weight badge, difficulty dots, and chip styles reuse the exact classes settled in sketch
002 (`.pk-facts-row`, `.pk-fact`, `.pk-difficulty-dot`) rather than reinventing them. Header
(breadcrumb, quiet state) and footer (two-tier mission band) are sketch 003 winner C, unmodified.

## How to View
open .planning/sketches/005-detail-page/index.html

Click the gallery thumbnails in any variant — the main/hero image swaps, same as production.

## Variants
- **A: Poster-Left Split (Sticky)** — classic two-column product-page layout: poster + gallery
  thumbnails in a sticky left column, everything else (title, facts, description, mechanics,
  meta) in a scrolling right column. Familiar e-commerce pattern; poster stays visible while
  reading a long description.
- **B: Full-Width Hero Band** *(original pitch — see "Winner" below for what actually shipped)* —
  a large full-bleed hero image with a gradient scrim and the title overlaid at the bottom
  (Netflix/Prime title-page pattern), facts strip and two-column body below. Picked in first
  review, then substantially reworked: the poster now reuses the real browse-card visual language
  instead of a cinematic backdrop, precisely because that backdrop needed a strong cover image to
  not look empty — risky against the catalog's inconsistent real box-cover photography (the same
  problem sketch 002 flagged for dropping card captions).
- **C: Magazine / Editorial** — smaller inset poster beside the title, a pull-quote-style one-line
  hook, full-width facts strip, then an asymmetric two-column body (mechanics/tags left, longer
  description + meta right). Most editorial/curated feel, least reliant on the poster image
  carrying the whole page.

## Winner
**B, heavily refined** after a first review round. Kept variant B's overall page structure but
reworked it substantially based on feedback:

### 1. Poster now reuses the real browse-card component, not a cinematic backdrop
The original variant B used a wide, full-bleed 16:9 gradient backdrop with the title overlaid via
a scrim — visually disconnected from the shelf card the user just clicked. It's now a full-size
version of the **exact same card** (`.pk-poster-art`-style 3:4 poster + `.pk-card-caption`-style
title box directly beneath it, same border-radius, same materials), sitting in a soft two-tone
wash band (`--color-surface` → `--color-bg`) for some hero presence without needing a strong cover
photo to carry the whole page — this also resolves this sketch's own earlier flagged risk (a weak
or oddly-cropped real box-cover photo breaking a full-bleed cinematic treatment).

### 2. Advanced info moved behind an accordion
Mechanics, themes, and the full "ficha técnica" (designers, illustrator, publisher, weight, BGG
rank) are decision-irrelevant for "will this work tonight" — the same principle sketch 002 already
established for the browse card. They're now collapsed by default under a single **"Más
información"** accordion, collapsed on load. The primary facts strip (jugadores, duración, edad,
dificultad) and the description stay always-visible — those are the fields that actually help
someone decide.

### 3. Ficha técnica grounded in the real `Game` schema — with two flagged gaps
Checked `lib/pukllay_club/catalog/game.ex` directly rather than inventing fields:
- **Diseñadores, Editorial, Año** — real fields (`designers`, `publishers`, `year_published`),
  shown as plain text.
- **Peso (BGG)** — the real `bgg_weight` float column (e.g. "3.8 / 5"), distinct from the
  already-shown `weight_band` category label (e.g. "Experto").
- **"Ver ficha completa en BoardGameGeek ↗"** — links out using the real `bgg_id` column
  (`https://boardgamegeek.com/boardgame/{bgg_id}`). Per `show.ex`'s own convention, this must be
  conditionally rendered — **~9% of the catalog has no `bgg_id`** (D-18), so the link needs to
  disappear entirely for those rows, not point at a broken URL.
- **⚠ Ilustrador — schema gap.** There is no illustrator field on `Game` at all. The sketch shows
  it explicitly labeled "No disponible aún" rather than faking data — if this matters, it needs a
  new column + BGG enrichment change, not just a template change.
- **⚠ "Puesto en el ranking BGG" — needs extraction work.** There's no dedicated rank column;
  BGG's rank data would have to be pulled out of the existing untyped `bgg_payload` map. Shown
  here as representative placeholder data, not a proven-available field.
- **Per-person BGG links weren't built.** You asked whether "designer, illustrator, editorial..."
  should navigate to a BGG id — `designers`/`publishers` are plain string arrays with no BGG entity
  id stored per person/publisher, only the *game's own* `bgg_id` exists. So only one link out
  exists (the game's BGG page), not per-designer/per-publisher links. Getting real per-entity BGG
  links would need additional enrichment data this schema doesn't currently capture — flagging
  rather than building a link to nowhere.

### 4. Share button — native Web Share API first, icon fallback second
Clicking the share icon calls `navigator.share()` first (the OS-level share sheet — WhatsApp,
Instagram, Messages, whatever's installed — genuinely better than any hand-built icon row). Browsers
without support (`navigator.share` undefined — most desktop browsers as of today) fall back to a
small popover: WhatsApp share-intent link, X/Twitter intent link, and copy-link (via
`navigator.clipboard`, with a toast confirmation). Both paths are real, working code patterns, not
sketch-only tricks.

**Scope note:** you asked for this "always... on preview and game's details" — this sketch only
built it into the full detail page. The card hover-portal / mobile-sheet preview from sketch 002
doesn't have a share affordance yet. Flagging as a follow-up consistency pass rather than doing it
here, since sketch 002 is a separate, already-finalized sketch.

### 5. "¡Quiero Jugarlo!" primary CTA → name capture modal → WhatsApp handoff
Replaces the previous plain "Ver en BGG" as the primary action. Flow: click → modal asks for name
→ submit (client-side required-field validation) → constructs a pre-filled reservation message
(`¡Hola Pukllay Club! Quiero reservar "{game}" para jugar. Mi nombre es {name}.`) → shows the
message preview plus a real `wa.me/{number}?text=...` link the user can actually open. **The
club's real WhatsApp Business number isn't wired up** — that's a runtime config value in the real
app, not something a static sketch should hardcode; the sketch uses a clearly labeled placeholder
number so the interaction loop is provable without pointing at a fake real number silently.

## What to Look For
- Open the "Más información" accordion — does collapsing mechanics/themes/ficha técnica by default
  feel right, or does hiding mechanics specifically go too far for players who *do* care about them
  at a glance?
- Click "¡Quiero Jugarlo!" — walk through the whole flow (empty-name validation error → fill name →
  submit → message preview → "Abrir WhatsApp" link). Does the generated message read naturally in
  Spanish? Is asking only for a name enough, or does a real reservation need more (preferred date,
  phone number)?
- Click the share icon — on a browser without Web Share API support you'll see the icon popover;
  try the copy-link button and confirm the toast appears.
- Check the "Ilustrador" and rank rows in the ficha técnica — do those flagged gaps change how you'd
  prioritize backend work before this ships?
- Variants A and C are kept for reference but weren't updated with this round's refinements (no
  accordion, share, or reservation CTA) — confirm you don't want either of their base layouts
  (sticky poster column, magazine grid) revisited with B's new interaction set before this is final.
