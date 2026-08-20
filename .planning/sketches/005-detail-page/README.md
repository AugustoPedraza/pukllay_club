---
sketch: 005
name: detail-page
question: "What does the full game detail page (/juegos/:id) look like inside the shell — hero, facts, description, mechanics — given production's current plain, undesigned layout?"
winner: "B"
tags: [layout, detail, card, accordion, share, whatsapp, reservation, mobile, carousel, lightbox, filtering]
---

# Sketch 005: Game Detail Page

## Design Question
`CatalogLive.Show` (`lib/pukllay_club_web/live/catalog_live/show.ex`) already renders every real
field — cover image, gallery, name, weight band, editorial tags, mechanic/theme chips,
players/playtime/age/year, designers, publishers, description — but as a plain, unstyled `<dl>`
list. This sketch explores what a properly designed detail page looks like, reusing the
difficulty-dots/chip patterns already settled in sketch 002 and the shell settled in 003.

## Grounding
All fields and their real names come from `show.ex`'s `<dl>` block and `lib/pukllay_club/catalog/game.ex`
directly — no invented data shape. Header (breadcrumb, quiet state) and footer (two-tier mission
band) are sketch 003 winner C, unmodified. Filter query params referenced below (`mechanics`,
`themes`, `tags`, `players`, `max_playtime`, `min_age`) are the real assign names read from
`CatalogLive.Index`'s `mount/3` — not invented — see "Round 3" for the important caveat on this.

## How to View
open .planning/sketches/005-detail-page/index.html

Click/drag the carousel arrows or dots to cycle images; click the image itself to open the
lightbox. Shrink to mobile (toolbar → 📱 375) to see the mobile masthead layout.

## History
Started as 3 variants (poster-left sticky split, full-width hero band, magazine/editorial).
Variant B ("full-width hero band") was picked, then went through three refinement rounds based on
review feedback — documented below. **Variants A and C were removed** once B was confirmed as the
direction; only the single, refined design remains in this file now (no tab switcher).

## Round 1 — reworking the original hero band
- **Poster reuses the browse-card's visual materials, not a cinematic backdrop.** The original
  pitch used a wide, full-bleed 16:9 gradient backdrop with the title overlaid via a scrim —
  visually disconnected from the shelf card the user just clicked. Replaced with the same 3:4
  poster proportions/rounded corners/gradient materials as the browse card, sitting in a soft
  two-tone wash band — this also sidesteps the original design's real risk: it needed a strong
  cover image to not look empty, against the catalog's inconsistent real box-cover photography
  (the same problem sketch 002 flagged for dropping card captions).
- **Advanced info moved behind an accordion.** Mechanics, themes, and the full "ficha técnica"
  (designers, illustrator, publisher, weight, BGG rank) are decision-irrelevant for "will this work
  tonight" — the same principle sketch 002 already established for the browse card. Collapsed by
  default under a single **"Más información"** accordion.
- **Ficha técnica grounded in the real `Game` schema**, with flagged gaps:
  - **Diseñadores, Editorial, Año, Edad mínima, Peso (BGG)** — real fields (`designers`,
    `publishers`, `year_published`, `min_age`, `bgg_weight`). Peso is distinct from the already-shown
    `weight_band` category label.
  - **"Ver ficha completa en BoardGameGeek ↗"** links out via the real `bgg_id` column. Per
    `show.ex`'s own convention this must be conditionally rendered — **~9% of the catalog has no
    `bgg_id`** (D-18), so the link needs to disappear entirely for those rows.
  - **⚠ Ilustrador — schema gap.** No illustrator field exists on `Game` at all; shown explicitly
    labeled "No disponible" rather than faking data.
  - **⚠ "Puesto en el ranking BGG" — needs extraction work.** No dedicated rank column; would need
    to be pulled from the existing untyped `bgg_payload` map. Shown as representative placeholder,
    explicitly marked "dato de ejemplo, no confirmado."
  - **Per-person BGG links weren't built.** `designers`/`publishers` are plain string arrays with no
    BGG entity id per person/publisher — only the game's own `bgg_id` exists.
- **Share button: native Web Share API first, icon fallback second.** Clicking share calls
  `navigator.share()` first; browsers without support fall back to a popover (WhatsApp/X intent
  links + copy-link with a toast). **Scope note:** the card hover-portal/mobile-sheet preview from
  sketch 002 doesn't have a share affordance yet — flagged as a follow-up, not built here.
- **"¡Quiero Jugarlo!" primary CTA → name capture modal → WhatsApp handoff.** Flow: click → modal
  asks for name → submit (required-field validation) → constructs a pre-filled reservation message
  → shows a preview plus a real, working `wa.me/{number}?text=...` link, wired to the club's actual
  WhatsApp Business number (+54 9 3884 10-3255). In the real app this number belongs in runtime env
  config, not hardcoded in a template — hardcoded here only because a static sketch has no config
  layer.

## Round 2 — mobile masthead restructure + modal polish
- Facts became a **pill row** (icon + value), reusing the exact pattern already settled for the
  card hover-portal/mobile sheet in sketch 002.
- **Image goes full-bleed on mobile** — the poster breaks out of the masthead's gutter padding via
  a negative-margin breakout, while title/facts/description/CTA keep their normal inset.
- **Description became collapsible** (initially 2-line clamp with a "Leer más ▾" toggle).
- **Primary CTA became full-width on mobile**; share became a full-width labeled button instead of
  a bare icon circle.
- **Modal polish:** added a game-preview row (poster swatch + name), backdrop blur, input focus
  glow, circular success-icon treatment.

## Round 3 — carousel + lightbox, rhythm fixes, filterable data
Three separate pieces of feedback, addressed together since they touch the same masthead area:

### 1. Minimal carousel + lightbox replaces the thumbnail strip
The round-1/2 gallery was a static main image with a row of small thumbnails below it that swapped
the image on click — and round 1 additionally put a redundant mini-title caption under the image
(copying the browse-card's caption element), which was pointless here since the page already has a
full-size `<h1>`. Both are gone. The image is now a **minimal carousel** — arrows + dots overlaid
directly on the image, same interaction shape as the carousel built in sketch 004 — with a
**lightbox**: clicking the image opens a full-size overlay viewer, synced to whichever slide the
carousel was on, with its own prev/next controls. One carousel component, same on mobile and
desktop (mobile inherits it full-bleed via the existing breakout CSS).

### 2. Rhythm fix: pills now come *before* the title, not after
A reference screenshot showed the pattern already settled in sketch 002 for the card
preview/sheet — pills sit **above** the title, not below it (round 2 had this backwards). Fixed to
match: carousel → pills → title → tag chip → description → CTA, on both mobile and desktop. On
desktop's two-column layout, the pills stay grouped with the image in the left column (directly
under the carousel) rather than migrating into the text column with the title — matching "below
the image carousel" literally and keeping the image+pills read as one compact unit beside the
title/description column.
  - Also dropped the separate "🎯 Experto" weight-badge chip that sat next to the title — it was
    showing the exact same information as the difficulty pill (dots + weight-band label) a few
    lines away, which is the same "same field rendered twice, slightly differently" mistake sketches
    001/002 already flagged and fixed elsewhere. The tag chip ("Sci-fi") is the only badge left next
    to the title now.
  - **Weight-band label corrected to real vocabulary.** Earlier rounds used a generic "Experto"
    label. Sketch 001's real shelf names (`Destacados del club, Descubre el hobby, Ingenio
    estratega, Nivel experto, Recientemente añadidos`) strongly suggest `weight_band` values use
    these same friendly phrases, not generic Ligero/Medio/Experto — matching what your reference
    screenshots show ("Descubre el hobby", "Ingenio estratega" as pill text, not generic labels).
    Updated the sample to "Nivel experto" accordingly. **Flagging, not fully confirmed:** haven't
    read `01-VOCABULARY.md`'s actual weight-band label list — verify these are the literal stored
    `weight_band` strings before implementation.

### 3. Description clamp: 4 lines desktop, 2 lines mobile
Was 2 lines everywhere; desktop has the horizontal room for more before "Leer más" is needed, so
desktop now clamps at 4 lines and mobile keeps 2.

### 4. Fixed the "disconnected, two divider lines" accordion rhythm
The masthead band's own bottom border and the accordion's separate top border sat right next to
each other (~8px apart) — two divider lines doing one job. Removed the accordion's own border,
relying on the single masthead-band divider. Also gave the whole "Más información" section the
same max-width/gutter rhythm as the rest of the page via `.detail-b .body` instead of floating
independently.

### 5. "Ficha técnica" redesigned as a spec-list, not a cramped dt/dd grid
The old 2-column CSS grid (`.tech-sheet`) didn't match any other pattern on the page (chips, pills)
and read as visually foreign — your words, "looks awful, not following either pattern." Replaced
with `.spec-list`: full-width rows, label left / value right, one hairline divider between rows —
a much more common "spec sheet" pattern, consistent type scale with the rest of the page.

### 6. Filterable data — chips/pills become real links, with a significant caveat
Mechanics, themes, the tag chip, and the difficulty/players/duration pills are now `<a>` elements
pointing at constructed catalog URLs (e.g. `/?mechanics=Construcción+de+motor`,
`/?weight_bands=Nivel+experto`, `/?min_age=12`). Grounded against the real filter dimensions that
exist in `CatalogLive.Index`'s `mount/3` assigns: `:q, :mechanics, :themes, :weight_bands, :tags,
:players, :max_playtime, :min_age`.

**⚠ Important gap, checked directly against the code:** `CatalogLive.Index` has **no
`handle_params/3`** and never calls `push_patch` — filter state lives purely in LiveView socket
assigns, not the URL. That means **these links wouldn't actually pre-filter anything in production
today** — the query string would just be ignored on load. Making this real needs a genuine backend
change (a common LiveView pattern: `push_patch` on filter change + `handle_params` to hydrate
filter state from the URL on mount/patch), not just a template change. Built the links anyway to
prove the intended interaction and URL shape, but this is the load-bearing dependency before any of
them do something on click.

**Fields deliberately left unlinked:** Diseñadores and Editorial (designer/publisher name) — you
asked for this ("type a designer's name, get filtered games"), but `designers`/`publishers` aren't
structured filter dimensions in `CatalogLive.Index` at all (not even in-memory, let alone
URL-persisted) — only the free-text `:q` search comes close, and it's unconfirmed whether the
`search_vector` full-text index even covers designer/publisher names. Linking these to `?q=...`
would imply exact-filter behavior a fuzzy text search wouldn't actually deliver, so left as plain
text rather than building a link that overpromises. Peso (BGG)/año/BGG rank are also unlinked —
none are real filter dimensions today.

## Future considerations (flagged, not built)
You mentioned wanting to eventually add social/community information to this page — comments,
in-page embedded YouTube (rules explainer or playthrough videos), and similar. Noting this as a
known future direction so the current layout isn't designed in a way that fights against adding it
later — the accordion pattern used for mechanics/ficha técnica could extend to a "Videos" or
"Comentarios" section using the same collapsed-by-default treatment. Not scoped or designed here.

## What to Look For
- Click through the carousel arrows/dots, then click the image to open the lightbox — confirm it
  opens on the same slide the carousel was on, and its own arrows keep both in sync.
- Compare desktop vs. mobile (📱 375) — on desktop, pills sit under the image in the left column;
  on mobile everything stacks in one flow (image → pills → title → tag → description → CTA). Does
  keeping pills "attached" to the image column on desktop read right, or should they move next to
  the title instead?
- Open "Más información" — does the ficha técnica's new row-list style feel consistent with the
  chips/pills used elsewhere now?
- Click a mechanic/theme chip or a pill — given the flagged URL-persistence gap, treat this as
  reviewing the *link targets and labels*, not a working filter yet.
- Description: on desktop, does a 4-line clamp feel like the right "before it needs collapsing"
  threshold?
