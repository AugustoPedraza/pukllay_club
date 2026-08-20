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

## Round 4 — pill row wrapping, tag content
- **Pills now hold to one line.** The jugadores/tiempo/dificultad pill row was wrapping to 2 lines
  inside the 300px poster column (the "Nivel experto" pill alone was pushing past the available
  width). Fixed with tighter pill padding/gap (`5px 10px`, 4px internal gap, 6px between pills),
  `flex-wrap: nowrap`, and widening the poster column slightly (300px → 320px). **Hierarchy check:**
  confirmed image → pills → title is the right order (facts before the name mirrors how the browse
  card's own hover-preview/sheet already work per sketch 002) — the fix here was purely a sizing
  bug, not a structural one.
- **Tag chips now use real-feeling Spanish editorial tags** instead of the placeholder English
  "Sci-fi" — two tags, "Duelos Memorables" and "Equipo Ganador", both filter-linked like the other
  chips. Two tags (not one) also matches production's real cap — sketch 002's grounding notes
  that the current card shows "up to 2 editorial tags." **Flagging:** these two specific strings
  are illustrative, chosen for length/flavor, not verified against `01-VOCABULARY.md`'s actual
  editorial tag list (same caveat as the "Nivel experto" weight-band label in Round 3).

## Round 5 — pills grouped with the title, not the image
Round 3/4 put the pill row inside the poster column, directly under the carousel — grouped with
the *image*. That's not what sketch 002 actually settled: there, pills sit "directly above the
title" as part of the same text block as the title, regardless of where the poster sits (the
hover-portal and mobile sheet both keep pills+title glued together, with the poster as a separate
element). Moved the pill row out of `.poster-col` and into the title column, directly above `<h1>`.
On mobile this is a no-op visually (DOM order still stacks image → pills → title, since the poster
column still renders first) — the fix only changes desktop, where pills now sit beside the image in
the title column rather than below the image in the poster column. Also removed now-dead CSS
(mobile gutter-padding compensation for pills, which was only needed while they lived inside the
full-bleed poster column).

## Round 6 — pill/title values byte-matched against sketch 002's real component
Checked the pill and title CSS directly against `002-card-hierarchy/index.html` rather than
continuing to approximate. Real differences found and fixed:
- **`.pill`** (sketch 002) is `11px`/`600`-weight, muted (`color-text-muted`) text, `1px solid
  var(--color-border)` border, `4px 9px` padding. My pill was `text-xs`(12px)/`700`-weight, full
  `color-text`, borderless — visibly heavier/darker than the real component.
- **Difficulty dots**: sketch 002's filled dot is `background: var(--color-text-muted)` (deliberately
  muted — "a standalone colored badge tested as louder than a metadata detail should be," per its
  own comment) at `5px`, `3px` gap. Mine used `var(--color-primary)` (bright brand purple) at
  `8px`/`6px`, `4px` gap — a meaningfully different, louder treatment of the exact same field.
- **Title**: neither sketch 002's `.card-title` nor production's real `show.ex` h1
  (`font-display text-3xl`, no transform) force `text-transform: uppercase` — Bebas Neue reads
  cap-height on its own, and forcing it would mangle a mixed-case title like "7 Wonders Duel".
  Dropped the uppercase transform I'd added; kept the larger font-size appropriate for a full-page
  `<h1>` vs. a small card caption, added the same `0.01em` letter-spacing as `.card-title`.

Class names still differ (`.pk-pill` vs `.pill`) since these live in separate sketch files — but
the values now byte-match. When this becomes a real shared component, per the project's own
established principle (sketch 001/002's biggest recurring bug source), these should share one
actual CSS class, not two independently-declared rules with matching values that can drift apart
again exactly like this.

## Round 7 — action clarity: description toggle, CTA, share button, zoom hint
- **"Leer más" toggle was too heavy and read as disconnected from the paragraph.** Was bold,
  primary-color, left-aligned — competing with the real CTA below it rather than reading as a small
  trailing control on the text it belongs to. Now muted (`color-text-muted`, 600-weight, `text-xs`),
  right-aligned under the paragraph (`margin-left: auto`), turning primary-color only on hover.
- **Primary CTA ("¡Quiero Jugarlo!") gained a subtle shadow + hover lift** (`box-shadow` +
  `translateY(-1px)` on hover) so it reads unambiguously as the page's elevated primary action, not
  flat colored text.
- **Share button was an icon-only circle with a bare "↗" glyph** — not a recognized share icon on
  its own, and previously only showed its "Compartir" text label on mobile, so on desktop it was
  just an ambiguous arrow in a circle. Now an always-labeled outlined pill ("↗ Compartir") at every
  viewport, same height/shape family as the primary CTA but secondary (bordered, not filled) —
  legible on its own instead of relying on a hover state or narrow viewport to explain itself.
- **Carousel zoom hint** (the ⤢ icon, top-right of the image) grows and brightens on hover now, and
  the carousel carries a `title="Ampliar imagen"` tooltip as a fallback cue, since a lone corner
  glyph at rest can read as decoration rather than an affordance.

## Round 8 — toggle actually inline in the text; CTA shape differentiated from pills
- **"Leer más" moved inside the `<p>` itself**, as the paragraph's own trailing inline content —
  not a sibling element positioned near it. Round 7's right-alignment fix addressed weight/color
  but the toggle was still a structurally separate element below the text, which is why it kept
  reading as "isolated" even after that pass. Now it's literally part of the same text run: same
  font-size/family as the body copy, only a muted color + underline signal it's interactive.
  **Mobile clamp bumped 2 → 3 lines** as a consequence — with the toggle now trailing inside the
  clamped box rather than below it, a 2-line clamp risked cutting the toggle text off entirely
  (no visible way to expand) if the description filled both lines first.
- **CTA/share button shape now differs from pills/tags.** Round 7 gave the share button the same
  fully-rounded capsule shape as the primary CTA, but that's also the exact shape already used for
  every fact pill and tag chip — so both buttons read as "bigger, stronger versions of the same
  pill component" rather than a distinct control type. Switched both to `radius-lg` (a rounded
  rectangle), keeping capsule/`radius-full` exclusively for pills and tags. One consistent rule
  going forward: **pills and tags are capsules; buttons are rounded rectangles.**

## Round 9 — "Leer más" visibility bug fixed; CTA style lab added
- **Real bug, not just a style miss:** Round 8 put the toggle inside the clamped `<p>` as trailing
  inline content. `-webkit-line-clamp` clips trailing content along with the rest of the overflow
  when it doesn't fit inside the visible lines — so the toggle could (and did) vanish entirely with
  no visible way to expand the text. That's a real CSS limitation of line-clamp, not a preference
  question. Fixed by moving the toggle back OUT as a sibling (guaranteed visible — a sibling isn't
  subject to the paragraph's own `overflow: hidden`), while keeping the "attached to the text" goal
  via: zero top margin, left-aligned flush with the paragraph, identical `text-base` font-size to
  the body copy, and a leading "… " implying it continues the cut-off sentence. Reverted mobile's
  clamp back to 2 lines (the 3-line bump from Round 8 was specifically to route around the
  visibility bug, which no longer applies now that the toggle can't be clipped).
- **CTA still didn't land after Round 8's shape change** — rather than guess a third time, added a
  **sketch-only "CTA style lab"**: a small control strip above the masthead with 5 buttons (A:
  current rounded-rect, B: large pill/capsule, C: outlined/ghost, D: flat minimal/sharp corners, E:
  gradient) that apply live to the real "¡Quiero Jugarlo!" CTA in the masthead below, so styles can
  be compared directly in context instead of via more rounds of blind guessing. Pick one and it
  becomes the real style; the lab strip itself is not part of the shipped page.

## Round 10 — CTA position lab
Style A (the rounded-rect from Round 8) is confirmed as the winner — no more style guessing needed
there. But the CTA **row's layout/position** still didn't feel right, so rather than guess a third
time, added a second **sketch-only lab strip** (same pattern as Round 9's style lab) with 4 live
position alternatives applied to the real `.cta-row`:
- **A: Actual** — primary + share side by side, roughly equal width, left-aligned in flow.
- **B: Primary ancho + ícono** — primary CTA grows to fill available width; share shrinks to an
  icon-only circle pinned to the row's end (`justify-content: space-between`).
- **C: Apilado** — primary full-width on its own row; share demoted to a plain muted text link
  below it (no button box, no border) — treats sharing as a clearly lower-priority secondary action
  rather than a co-equal button.
- **D: Alineado a la derecha** — same two buttons as A, but the whole row shifts to the right edge
  of the column instead of sitting left-aligned under the description.

## Round 11 — buy box (desktop) + sticky action bar (mobile)
All 4 of Round 10's position alternatives still broke the rhythm, because they were all just
rearranging two buttons *within the reading column* — the real problem was that buttons don't
belong in a prose flow at all, regardless of internal arrangement. Rebuilt around a named,
well-established pattern instead of another guess:

- **Desktop — "buy box" pattern** (Amazon/Shopify/Airbnb product & listing pages): the image,
  facts pills, and the primary CTA now form one self-contained decision panel in the left column
  (`.poster-col`, a flex column with its own internal `gap`), fully separated from the right
  column, which is now pure reading content — title, tag chips, description. The CTA never
  interrupts the prose because it's structurally not part of that column anymore.
  - **Note on Round 5:** this deliberately moves the facts pills again — back into the image
    column, alongside the CTA. Round 5 grouped pills with the title specifically because that's
    how sketch 002's *compact card* (hover-portal/mobile-sheet) does it — but a compact card and a
    full detail page's two-column buy-box are genuinely different contexts serving different
    purposes (one glanceable unit vs. an image+specs+action panel beside a reading column). Both
    decisions are correct for their own context; this isn't silently reversing Round 5, the
    compact card is untouched.
  - The CTA row itself also had to shrink to fit the narrower 320px buy-box column — two
    full-labeled buttons side by side don't reliably fit there, so the primary CTA now grows to
    fill the row and the share button shrinks to icon-only (`title="Compartir"` tooltip as the
    accessible fallback for Round 7's labeling concern, since there's no room for a permanent
    label in this narrower context).
- **Mobile — sticky bottom action bar** (Amazon app / Booking.com / Airbnb mobile / most food-
  delivery apps, for exactly this scenario: one primary action on a long content page): a new
  `position: fixed` bar at the bottom of the viewport, duplicating the same CTA/share actions,
  always reachable regardless of scroll position. The inline `cta-row` inside the buy-box column
  is now `display: none` on mobile (it would just be a redundant second copy of the same buttons
  mid-page) — the fixed bar is the only CTA surface below 768px. `body` gets `padding-bottom` on
  mobile so the bar doesn't cover the footer's last content.
- Removed both Round 9/10 comparison labs (CTA style + position) now that both questions are
  resolved — style A stands, and the position question is superseded by this restructure rather
  than answered from within the old A–D set.

## Round 12 — facts pills moved back to the title, out of the buy box
Round 11's buy box grouped facts pills with the image and CTA. Moved the pill row back out of
`.poster-col` to sit directly above `<h1>` in the reading column, restoring Round 5's original
placement (which Round 11 had deliberately overridden).

- **Why this is different from just re-litigating Round 5/11 again:** the pills are metadata about
  *what's being read* (players, playtime, difficulty), not part of the *purchase decision* the buy
  box exists to isolate — grouping them with the CTA was defensible on the "self-contained decision
  panel" logic, but sitting at the top of the title block matches the home shelf's own card pattern
  (pills directly above the title) more closely, and keeps the buy box focused purely on image +
  action.
- **Buy box now holds only image + CTA.** `.poster-col`'s flex `gap` still separates carousel from
  CTA row; nothing else changed about the mobile sticky bar or desktop CTA shrinking from Round 11 —
  those are unaffected by where the pills live.
- On mobile, DOM order is unchanged in effect: carousel (full-bleed) → pills → title → tags →
  description, same stacking as before Round 11 ever moved the pills.


You mentioned wanting to eventually add social/community information to this page — comments,
in-page embedded YouTube (rules explainer or playthrough videos), and similar. Noting this as a
known future direction so the current layout isn't designed in a way that fights against adding it
later — the accordion pattern used for mechanics/ficha técnica could extend to a "Videos" or
"Comentarios" section using the same collapsed-by-default treatment. Not scoped or designed here.

## Round 13 — CTA affordance: elevation moved to the resting state
The primary CTA's depth (`box-shadow`) lived almost entirely in `:hover` (`shadow-sm` at rest →
`shadow-md` on hover, plus a lift). A hover-only cue never fires on touch — nothing hovers on tap —
so on mobile (and on a static screenshot) the button could read as a flat colored label rather than
a raised, pressable control. Now `shadow-md` is the resting state, `:hover` goes further to
`shadow-lg` with the same lift, and a new `:active` state flattens back to `shadow-sm` with no lift
so a tap/click gives a visible "pressed" response. Applies everywhere `.cta-primary` is used
(desktop buy box and the mobile sticky bar both share the class, so both get the fix for free).

## What to Look For
- Click through the carousel arrows/dots, then click the image to open the lightbox — confirm it
  opens on the same slide the carousel was on, and its own arrows keep both in sync.
- Compare desktop vs. mobile (📱 375): on desktop, image + CTA form the buy-box unit in the left
  column; the right column leads with the facts pills directly above the title, then
  tags/description as pure prose with no button interrupting it. On mobile, does the sticky bottom
  bar feel like the right tradeoff (always reachable, but permanently covering ~76px of viewport)
  vs. an inline CTA you'd have to scroll back up for?
- Scroll the mobile view — confirm the sticky bar stays fixed and never overlaps the footer's last
  content.
- Open "Más información" — does the ficha técnica's row-list style feel consistent with the
  chips/pills used elsewhere?
- Click a mechanic/theme chip or a pill — given the flagged URL-persistence gap, treat this as
  reviewing the *link targets and labels*, not a working filter yet.
- Description: on desktop, does a 4-line clamp feel like the right "before it needs collapsing"
  threshold, now that it sits alone in a column without a CTA immediately following it?
- Is the icon-only share button (both in the desktop buy-box and the mobile bar) legible enough
  now, relying on the `title` tooltip + adjacency to the primary CTA instead of a permanent label?
