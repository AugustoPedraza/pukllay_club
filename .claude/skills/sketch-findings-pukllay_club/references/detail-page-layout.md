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
`position: fixed` CTA bar has to fake with a scroll-driven `getBoundingClientRect()` check instead
(see the mobile reference file — not `IntersectionObserver`, which was tried first and found to
throttle in a backgrounded tab) — prefer `position: sticky` over `fixed` whenever the element's
container naturally bounds where it should stop, which it does not for a fixed-bottom mobile bar
spanning the whole page.

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

**Buy-box panel boundary: elevated shadow, not a fill/border change (Phase 01.2 gap-closure,
sketch 027).** UAT flagged the buy-box as not reading like "one self-contained panel distinct from
the reading column" (root cause: `bg-base-200`/`bg-base-100` measured at 1.415:1/1.086:1 contrast
in a prior debug session, well under this app's own 3:1 non-text floor). Three fixes were sketched
— a stronger border, a stronger fill, and a soft shadow lift — **the shadow lift won**: it separates
the panel on a plain background without changing `.poster-col`'s existing fill token at all, so the
fix is purely additive (shadow + no border) on top of whatever fixes the panel's separate CSS
cascade-layer positioning bug (unlayered `.pk-*` rules beating layered Tailwind utilities — a code
fix, not a design decision, see the phase's own debug log).

```css
.pk-poster-col { background: var(--color-bg); border: 1px solid var(--color-border); box-shadow: var(--shadow-md); }
```

**Facts pills relocate to the poster panel, and the CTA leaves it (Phase 01.2 gap-closure round 2,
sketch 032) — revises "Facts pills sit with the title, not the CTA" above.** A later UAT round
flagged the masthead again: on mobile the pills had drifted to an absolute overlay *on top of* the
poster image (not living with the title at all — an undocumented change from this file's original
sketch 005 decision), and on both viewports the Reservar button sat *inside* the same
bordered/shadowed panel as the poster, reading as "part of the carousel" rather than a separate
decision. Sketch 032 compared three structural fixes — pills-above-panel/CTA-detached-below;
a full-width pills bar + fully standalone buy panel; CTA relocated into the text column as an
e-commerce-style buy box — **the minimal-diff option won**: pills move to a plain in-flow row
directly above the poster panel (justified full-width on mobile, centered gallery dots), and the
Reservar button moves *outside* the bordered/shadowed panel with a visible gap below it. The
buy-box principle above is revised to: **image + pills live together in one panel; the CTA is a
separate, adjacent element below it, not inside the same bordered box.**

**Masthead width now matches the header/footer shell — the separate 1100px cap is gone.** UAT
flagged that the masthead/CTA-bar/shelf-separator's own narrower content-width token read
noticeably narrower than the header/footer's own `max-w-7xl` + `pk-gutter` box (1280px). The
"Juegos similares" shelf below already correctly used the wider shell width, so the masthead
needed to widen to match it, not the other way around — don't give one section of a page its own
independent width cap when every other section shares one.

```css
.pk-detail-masthead { max-width: 1280px; margin: 0 auto; display: grid; grid-template-columns: 1fr; gap: var(--space-4); }
@media (min-width: 768px) { .pk-detail-masthead { grid-template-columns: 22rem 1fr; } }
.pk-poster-col .pk-facts-row { justify-content: space-between; } /* mobile: justified full-width */
.pk-poster-reserve { margin-top: var(--space-2); } /* outside the bordered panel, not inside it */
.pk-gallery-dots { justify-content: center; } /* was left-aligned by default flex behavior */
```

**Don't show the same fact twice at two different sizes (Phase 01.2 gap-closure round 2, sketch
034).** A weight-band badge + explanatory sentence ("Nivel experto" / "Requiere varias partidas
para dominarlo...") that an earlier round deliberately kept below the divider turned out to just
duplicate the same dificultad fact already shown compactly in the facts pill row above the title —
a later UAT round reversed that keep-decision and removed the badge+sentence entirely. When a fact
already has a home in a compact summary row, don't give it a second, more verbose home lower on the
same page.

**Mecánicas/Temáticas chips need real border/background contrast, not the bare daisyUI default.**
The chip row's default badge styling ships with no custom override — tight padding, background
that barely reads against the page. Fix is real breathing room + a background token that actually
contrasts, keeping the same border+fill shape:

```css
.pk-chip-row .badge { padding: 6px 14px; background: var(--color-surface); border: 1px solid var(--color-border); }
```

**Section spacing: one deliberate value at each boundary, not stacked independent declarations
(Phase 01.2 gap-closure round 2, sketch 035).** Two additive bugs, both worth checking for
elsewhere in this codebase: (1) the sticky title-echo bar (see `detail-page-mobile-interaction.md`)
is unconditionally rendered and only hidden via `opacity: 0` — as `position: sticky` it still
occupies real layout space even while invisible, silently padding out the header→masthead gap by
~60-70px on top of the page's own top padding. (2) three independent spacing rules stacked at the
footer boundary (the page content wrapper's own bottom padding + the footer's own top margin + the
footer's inner row's own top padding) summed to over 150px — each reasonable alone, far too much
together. Fix: collapse both boundaries to one deliberate value, and — after discussion — make it
the *same* value at top and bottom (24px) rather than asymmetric: a uniform, minimal rhythm read
better than giving the footer boundary more room just "because it's the page ending."

**"Juegos similares" shelf never goes sparse — the shelf itself always looks identical (Phase 01.2
gap-closure, sketch 031).** UAT pushback: a 1-2 card rail for a thin weight-band pool "isn't
acceptable." Rather than a distinct sparse-state layout (compact cluster, no edge-fade — tried and
rejected as an unnecessary second visual mode), the winning direction keeps `.pk-shelf`'s layout
completely invariant and makes the *query* responsible for always filling it (widen to adjacent
bands / broader overlap / `bgg_weight` proximity when the same-band pool is thin — a
`Catalog.similar_games/1` change, not covered here). The only visible signal that widening
happened is a small pill badge next to the title plus a subtitle swap — title itself stays "Juegos
similares" rather than switching to "Otras sugerencias" (flagged as still open: verify this reads
as different enough from a true same-band match once built).

```css
.pk-shelf-badge { display: inline-flex; align-items: center; font-size: var(--text-xs); font-weight: 700; color: var(--color-primary); background: var(--color-accent-bg); padding: 2px 9px; border-radius: var(--radius-full); margin-left: 8px; vertical-align: middle; }
```
```html
<h3>Juegos similares<span class="pk-shelf-badge" :if={@similares_widened}>Ampliado</span></h3>
<p class="pk-shelf-subtitle">{if @similares_widened, do: "Otras opciones que te van a encantar", else: "Mismo nivel de dificultad, mecánicas y temática parecidas"}</p>
```

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
- Don't try to fix the buy-box's "doesn't read as a panel" complaint by strengthening its fill
  color alone — a shadow lift on the existing fill won over both a stronger border and a stronger
  fill in sketch 027's comparison.
- Don't give a sparse "Juegos similares" rail its own distinct compact layout — fix it at the
  query layer (always widen the pool to fill the shelf) so the shelf's visual treatment stays one
  invariant thing, not two.
- Don't put the CTA button inside the same bordered/shadowed panel as the poster image — it reads
  as "part of the carousel" rather than a separate decision, even though both live in the buy-box
  column.
- Don't give one page section (e.g. the masthead) its own independent content-width cap when every
  other section on the page shares one — cross-check against the header/footer's actual width, not
  a value chosen in isolation.
- Don't show the same fact twice at two visual weights on the same page (a compact pill, then a
  larger badge+sentence lower down) — pick one home for it.
- Don't leave a sticky element unconditionally rendered and only hidden via `opacity: 0` — as
  `position: sticky` (or any non-`fixed`/non-`absolute` positioning) it still occupies real layout
  space while invisible, silently padding out whatever comes after it.
- Don't let independently-reasonable spacing rules stack at the same page boundary (e.g. a
  wrapper's bottom padding + the next section's own top margin + that section's own inner padding)
  — collapse to one deliberate value per boundary.

## Origin
Synthesized from sketches: 005, 027, 031, 032, 034, 035
Source files available in: sources/005-detail-page/, sources/027-buybox-panel-boundary/,
sources/031-similar-games-fallback/, sources/032-masthead-facts-placement/,
sources/034-chip-cleanup/, sources/035-detail-page-rhythm/
