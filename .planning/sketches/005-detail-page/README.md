---
sketch: 005
name: detail-page
question: "What does the full game detail page (/juegos/:id) look like inside the shell — hero, facts, description, mechanics — given production's current plain, undesigned layout?"
winner: "B"
tags: [layout, detail, card, accordion, share, whatsapp, reservation, mobile]
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
trick. Header (breadcrumb, quiet state) and footer (two-tier mission band) are sketch 003 winner C,
unmodified.

## How to View
open .planning/sketches/005-detail-page/index.html

Click the gallery thumbnails — the main image swaps, same as production. Shrink to mobile
(toolbar → 📱 375) to see the mobile-specific masthead layout described below.

## History
Started as 3 variants (poster-left sticky split, full-width hero band, magazine/editorial).
Variant B ("full-width hero band") was picked, then went through two refinement rounds based on
review feedback — documented below. **Variants A and C were removed** once B was confirmed as the
direction; only the single, refined design remains in this file now (no more tab switcher).

## Round 1 — reworking the original hero band
- **Poster now reuses the real browse-card component, not a cinematic backdrop.** The original
  pitch used a wide, full-bleed 16:9 gradient backdrop with the title overlaid via a scrim —
  visually disconnected from the shelf card the user just clicked. It's now a full-size version of
  the **exact same card** (`.pk-poster-art`-style 3:4 poster + `.pk-card-caption`-style title box
  directly beneath it, same border-radius, same materials), sitting in a soft two-tone wash band
  for some hero presence without needing a strong cover photo to carry the whole page — this also
  sidesteps the original design's real risk: it needed a strong cover image to not look empty,
  against the catalog's inconsistent real box-cover photography (the same problem sketch 002
  flagged for dropping card captions).
- **Advanced info moved behind an accordion.** Mechanics, themes, and the full "ficha técnica"
  (designers, illustrator, publisher, weight, BGG rank) are decision-irrelevant for "will this work
  tonight" — the same principle sketch 002 already established for the browse card. Collapsed by
  default under a single **"Más información"** accordion. The facts row and description stay
  always-visible.
- **Ficha técnica grounded in the real `Game` schema** (`lib/pukllay_club/catalog/game.ex`), with
  two flagged gaps:
  - **Diseñadores, Editorial, Año, Edad mínima** — real fields, shown as plain text.
  - **Peso (BGG)** — the real `bgg_weight` float column (e.g. "3.8 / 5"), distinct from the
    already-shown `weight_band` category label (e.g. "Experto").
  - **"Ver ficha completa en BoardGameGeek ↗"** links out using the real `bgg_id` column. Per
    `show.ex`'s own convention this must be conditionally rendered — **~9% of the catalog has no
    `bgg_id`** (D-18), so the link needs to disappear entirely for those rows.
  - **⚠ Ilustrador — schema gap.** No illustrator field exists on `Game` at all; shown explicitly
    labeled "No disponible aún" rather than faking data.
  - **⚠ "Puesto en el ranking BGG" — needs extraction work.** No dedicated rank column; would need
    to be pulled from the existing untyped `bgg_payload` map. Shown as representative placeholder.
  - **Per-person BGG links weren't built.** `designers`/`publishers` are plain string arrays with no
    BGG entity id per person/publisher — only the game's own `bgg_id` exists, so only one link out
    exists (the game's BGG page), not per-designer/per-publisher links.
- **Share button: native Web Share API first, icon fallback second.** Clicking share calls
  `navigator.share()` first (the OS-level share sheet); browsers without support fall back to a
  popover (WhatsApp/X intent links + copy-link with a toast). **Scope note:** the card
  hover-portal/mobile-sheet preview from sketch 002 doesn't have a share affordance yet — flagging
  as a follow-up consistency pass, not built here.
- **"¡Quiero Jugarlo!" primary CTA → name capture modal → WhatsApp handoff.** Replaces the old plain
  "Ver en BGG" CTA. Flow: click → modal asks for name → submit (required-field validation) →
  constructs a pre-filled reservation message → shows a preview plus a real, working
  `wa.me/{number}?text=...` link, wired to the club's actual WhatsApp Business number
  (+54 9 3884 10-3255). In the real app this number belongs in runtime env config, not hardcoded in
  a template — it's hardcoded here only because a static sketch has no config layer.

## Round 2 — mobile masthead restructure + modal polish
Prompted by a reference screenshot showing a compact mobile card: pill-style facts row (icon +
value) directly under the title, not the earlier stacked label/value blocks.
- **Facts row is now a pill row**, reusing the exact icon+value pill pattern already settled for
  the card hover-portal/mobile sheet in sketch 002 — 👥 players, ⏱ duration, and a combined
  dots+label difficulty pill (e.g. "••● Experto"). Dropped "Edad mínima" from this row to match
  that settled 3-pill pattern exactly (age moved into the "Más información" accordion instead,
  alongside Año).
- **Image goes full-bleed on mobile.** Below 768px, the poster card breaks out of the masthead's
  gutter padding (negative-margin breakout, not by stripping padding from the whole masthead) so
  the image spans edge-to-edge, while title/facts/description/CTA keep their normal inset. Title,
  facts pills, and CTA sit below it in that order — image → title → facts → description → CTA.
- **Description is now collapsible** (2-line clamp with a "Leer más ▾" / "Leer menos ▴" toggle),
  independent of the mechanics/ficha-técnica accordion — this manages long description length
  specifically, not advanced/secondary info.
- **Primary CTA is full-width on mobile**; the share button becomes a full-width labeled button
  ("↗ Compartir") instead of a bare icon circle, stacked below it — an icon-only circle at full
  width reads oddly, so a text label was added (hidden on desktop, shown only in the mobile media
  query).
- **Modal polish pass:** added a small game-preview row (poster swatch + name) at the top so it's
  unambiguous which game is being reserved, a subtle backdrop blur, a focus glow on the name input,
  a circular icon treatment for the success checkmark, and tightened spacing throughout. The
  primary "Reservar por WhatsApp" button is now full-width in the modal at all viewports (was
  previously flex:1 alongside empty space).

## Future considerations (flagged, not built)
You mentioned wanting to eventually add social/community information to this page — comments,
in-page embedded YouTube (e.g. rules explainer or playthrough videos), and similar. Noting this
now as a known future direction so the current layout isn't accidentally designed in a way that
would fight against adding those later (e.g. the accordion pattern used for mechanics/ficha técnica
could extend to a "Videos" or "Comentarios" section using the same collapsed-by-default treatment).
Not scoped or designed in this round.

## What to Look For
- Shrink to mobile (📱 375) — confirm the image reads as full-bleed, the pill row lands right after
  the title, the description starts collapsed, and the CTA/share buttons are both full-width and
  stacked.
- Open the "Más información" accordion — does collapsing mechanics/themes/ficha técnica by default
  feel right, or does hiding mechanics specifically go too far for players who *do* care about them
  at a glance?
- Click "Leer más" on the description — does a 2-line clamp feel like the right default, or too
  aggressive for a description that's naturally short?
- Click "¡Quiero Jugarlo!" — walk through the whole flow (empty-name validation error → fill name →
  submit → message preview → "Abrir WhatsApp" link, which now opens a real chat with the club's
  actual number). Is asking only for a name enough, or does a real reservation need more (preferred
  date, phone number)?
- Click the share icon (or its mobile full-width variant) — on a browser without Web Share API
  support you'll see the icon popover; try copy-link and confirm the toast appears.
