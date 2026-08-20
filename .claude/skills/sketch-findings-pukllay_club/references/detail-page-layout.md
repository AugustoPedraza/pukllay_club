# Detail Page — Layout & Content

`CatalogLive.Show` renders every real field (cover image, gallery, name, weight band, editorial
tags, mechanic/theme chips, players/playtime/age/year, designers, publishers, description) but as a
plain, unstyled `<dl>`. This sketch (36 rounds) is what a designed version looks like. This file
covers structure/content; behavior and interaction patterns (mobile sticky chrome, lightbox, share,
reservation flow) are in `detail-page-mobile-interaction.md`.

## Design Decisions

**Desktop: "buy box" pattern (Amazon/Shopify/Airbnb), not a hero band.** The image + primary CTA
live together as one self-contained decision panel (`.poster-col`), separate from the long-form
reading content (title/description/mecánicas/temas/ficha técnica, `.text-col`). Every earlier
attempt to fix CTA placement kept rearranging buttons *inside* the reading column — the actual
problem was that buttons don't belong in a prose flow at all, regardless of arrangement.

**`.poster-col` is `position: sticky`, not fixed, on desktop.** As the (much taller) text column
scrolls, the image+CTA stay pinned in view via native sticky positioning — it naturally un-sticks at
the real end of `.masthead`'s containing block, no JS needed. This is the boundary case mobile's
`position: fixed` CTA bar has to fake with an `IntersectionObserver` instead (see the mobile
reference file) — prefer `position: sticky` over `fixed` whenever the element's container naturally
bounds where it should stop, which it does not for a fixed-bottom mobile bar spanning the whole
page.

```css
.detail-b .masthead { max-width: 1100px; margin: 0 auto; display: grid; grid-template-columns: 320px 1fr; gap: var(--space-8); align-items: start; }
.detail-b .poster-col { position: sticky; top: calc(64px + var(--space-4)); } /* 64px clears the sticky header */
```

**Facts pills sit with the title, not the CTA.** Players/playtime/difficulty are metadata *about
what's being read* (the title block), not part of the purchase decision — they read naturally above
`<h1>`, matching the browse card's own pill pattern (sketch 002), not bundled with the buy box.

**No accordion — "más información" flows inline.** Mechanics, themes, and ficha técnica used to
live behind a single "Más información" accordion trigger (Round 1). Retired (Round 24): users
already scroll long pages routinely, and gating supplementary spec data behind a click just adds
friction without meaningfully shortening the page. It's now one continuous reading column with
`.section-heading` labels between subsections.

**Ficha técnica: 2-column grid, not a definition-list with per-row dividers.** Label stacked above
value (not a `<dt>`/`<dd>` inline row), uppercase muted labels — auto-flows 2-per-row for short
values, with a `.spec-row--wide` escape hatch that forces long values (linked names, explanatory
sentences) to take the full row at any viewport width.

**Ground every field in the real schema — including its gaps.** Don't invent data to make a mockup
look complete:
- **Ilustrador** — no such field exists on `Game`. Shown explicitly labeled "No disponible" rather
  than faked.
- **Puesto en el ranking BGG** — no dedicated rank column; would need extraction from the existing
  untyped `bgg_payload` map. Shown as a representative placeholder, explicitly marked "dato de
  ejemplo, no confirmado."
- **"Ver ficha completa en BoardGameGeek"** link — real `bgg_id` column, but **~9% of the catalog
  has no `bgg_id`** — must be conditionally rendered, not assumed present.
- **Per-person BGG links weren't built** — `designers`/`publishers` are plain string arrays with no
  BGG entity id per person, only the game's own `bgg_id`.

**Filter-linked chips/pills throughout** (`?players=`, `?max_playtime=`, `?weight_bands=`,
`?mechanics=`, `?themes=`, `?tags=`, `?min_age=`, `?q=`) — every pill/chip on the page is a link
back into `CatalogLive.Index`'s real filter query params (confirmed against `mount/3`, not
invented). **Flagged gap: URL-persistence isn't proven** — review these as link targets/labels, not
as a working filter round-trip yet.

**Description: 4-line clamp on desktop, 2-line on mobile**, both toggleable — full width of the
reading column (a 62ch typographic cap was tried and dropped: it left visible dead space to the
right since the actual column is wider than 62ch at the shell's 1100px max-width).

**"Juegos similares" shelf** — a "more like this" row between the last detail content and the
footer, giving the reader an exit hook back into browsing instead of a dead end (standard pattern —
Netflix, Amazon, Airbnb all do it). Not a new component: it's the real, already-shipped home page
shelf (`PukllayClubWeb.CarouselRow` + `GameCard`, `assets/css/app.css`'s
`.pk-shelf`/`.pk-rail`/`.pk-card*`) reused as-is, including its resting-card restraint (poster + one
line of title, nothing else — every secondary fact lives behind hover/tap on the real component,
not on the card). Two departures from the home page's usage: no `.pk-see-all` trailing tile (a
detail page's "more like this" has no natural "see all" destination the way a tag/weight-band shelf
does), and it activates `CarouselRow`'s `subtitle` prop (unused by any home-page caller today) to
explain *why* these games are surfaced.

## CSS Patterns

```css
/* Ficha técnica grid */
.spec-list { display: grid; grid-template-columns: 1fr 1fr; gap: var(--space-4) var(--space-6); }
.spec-row--wide { grid-column: 1 / -1; }
.spec-row dt { font-size: var(--text-xs); font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; color: var(--color-text-muted); }

/* Facts pill row */
.pk-pill-row { display: flex; gap: 6px; flex-wrap: nowrap; margin: 0 0 var(--space-2); }
.pk-pill { /* same visual family as browse-card pills, sketch 002 */ }

/* Similar-games shelf — real component classes, see detail-page-mobile-interaction.md
   for the mobile-only header-stacking fix this needed */
.pk-shelf { margin: var(--space-8) 0 0; }
.pk-row-header { display: flex; align-items: flex-end; justify-content: space-between; gap: var(--space-4); }
.pk-rail-wrap { position: relative; }
.pk-rail-wrap::before, .pk-rail-wrap::after { content: ''; position: absolute; top: 0; bottom: 0; width: 48px; pointer-events: none; }
.pk-rail { display: flex; gap: var(--space-4); overflow-x: auto; scroll-behavior: smooth; scrollbar-width: none; overscroll-behavior-x: contain; }
```

## What to Avoid

- Don't put CTA buttons inside the prose/reading column — give them a dedicated buy-box panel.
- Don't use `position: fixed` for an element that has a natural container boundary to stop at —
  `position: sticky` gets the "un-stick at the end" behavior for free.
- Don't cap reading-column paragraph width independently of the column's actual measured width —
  check the real rendered width at the shell's actual max-width before picking a `ch` cap.
- Don't fake schema fields that don't exist (illustrator, BGG rank) — label the gap explicitly.
- Don't add a `.pk-see-all` tile to a "similar games" shelf — there's no real destination for it
  the way there is for a home-page tag/weight-band shelf.

## Origin
Synthesized from sketch: 005
Source file available in: sources/005-detail-page/
