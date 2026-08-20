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

## Round 14 — desktop: sticky buy box + inline "más información" (accordion retired on desktop)
You asked whether a modal made sense for "más información" (mechanics/themes/ficha técnica) on
desktop. Recommended against it — a modal repeats the same "interrupts the page for low-stakes
browsing content" problem Round 11 solved for the CTA — and instead you proposed a named pattern of
your own: keep the buy box (image, CTA) fixed/sticky in the left column while the reading column
(title, pills, description, and now también the details) scrolls underneath it.

**This is a real, well-established pattern** — Airbnb's listing page (sticky booking widget beside
scrolling description/amenities/reviews) and Stripe's API reference (sticky code samples beside
scrolling docs) are both variants of it. Implemented as plain CSS `position: sticky` on
`.poster-col`, no JavaScript — the standard, simplest form of the pattern. `.masthead`'s existing
`align-items: start` is what makes a sticky grid child work at all; without it the item stretches to
the row's height and can never "detach" to stick.

**Deliberately not an independently-scrolling inner pane** (a fixed-height box with its own
`overflow-y: auto` and separate scrollbar) — that's a different, riskier variant of this same family
of pattern (nested/double scrollbars are a well-documented usability antipattern: users don't expect
a scroll gesture inside a sub-region of the page to move something other than the whole page). Plain
`position: sticky` gets the same visual effect — pinned buy box, scrolling reading column — using
the browser's one normal page scrollbar, so there's nothing new to learn or discover.

**"Más información" moved out of its own full-width section and into the description column**,
since keeping it sticky-adjacent only works if it's part of the same scrolling column as the
description — it can't stay in a separate full-width row below the masthead. On desktop this also
means the accordion mechanism itself is retired: the trigger is hidden and the panel is forced open
via CSS (`max-height: none`), since the reason it was collapsed in the first place (limited mobile
screen space) doesn't apply once it's just more of an already-scrolling desktop column. **Mobile is
unaffected** — same accordion, same collapsed-by-default trigger, same single-column stack; only the
`@media (min-width: 769px)` desktop query changes behavior.

**Scroll affordance:** with the accordion trigger gone on desktop, the explicit "there's more here,
click to see it" cue went with it. Added a small "↓ Mecánicas, temas y ficha técnica más abajo" hint
with a bouncing chevron, directly under the description — dismissed (faded, not removed, so nothing
jumps) the first time the user actually scrolls. This is the piece that's actually new work here;
the sticky positioning itself needed none.

**Clean formatting:** the mechanics/themes/ficha-técnica block is no longer visually foreign to the
description above it — same column, same `max-width: 62ch` reading measure (matching
`.desc-collapse`), separated from the description by one hairline top border (matching the divider
language `.spec-row` already uses), rather than the accordion's previous bespoke chevron/trigger
treatment.

**Flagged, not resolved:** the sticky buy box will end up shorter than the now much-taller scrolling
column once mechanics/themes/ficha técnica are inline — meaning there's real empty space below the
pinned image+CTA for most of the scroll. That's expected/normal for this pattern (Airbnb's own
booking widget has the same gap), not a bug, but worth confirming it doesn't look broken once real
content lengths are in play.

## Round 15 — desktop CTA row: stacked, not side by side
The buy box's `.cta-row` had primary + share side by side, which is why share had shrunk to an
icon-only circle (Round 11) — two full-labeled buttons don't reliably fit next to each other in a
320px column. Stacked instead: primary full-width on top, share full-width directly below it, both
the same width. This removes the width constraint that forced the icon-only compromise, so share
gets its label back ("↗ Compartir") rather than relying solely on a `title` tooltip. Also closer to
the actual classic Amazon buy-box shape (stacked full-width primary/secondary actions) than the
side-by-side version was. Mobile's sticky bottom bar is untouched — it's a different, more
space-constrained context (a permanently visible fixed bar spanning the full viewport width), where
side-by-side icon-only share still makes sense.

## Round 16 — "más información" polish: chip weight, spec-list alignment, fewer dividers
Three fixes, all in the now-inline "más información" block:

- **Mechanics/themes chips were never actually grounded, and it showed.** Unlike the pills/dots/
  title (byte-matched against sketch 002 in Round 6), `.chip`'s mecánicas/temas styling had no
  existing component to check against — sketch 002 has no chip pattern at all. It ended up
  `text-xs`/full-color-text/white-background — visibly *louder* than the muted `.pk-pill` facts row
  above the title, a hierarchy inversion (deeper, secondary detail outweighing the primary facts).
  `.chip`'s base style now byte-matches `.pk-pill` (11px/600-weight, muted text, surface background)
  so mechanics/themes read as quiet supplementary metadata, not competing for attention with the top
  pills. `.chip.tag` (the editorial tag next to the title) keeps its own separate, more prominent
  treatment — that one is meant to stand out as a highlight, so it wasn't touched.
- **Ficha técnica: fixed-width label column instead of space-between + right-align.** The reported
  "spacing between label and value" issue wasn't a gap-size bug (flex `gap` already enforced a
  minimum) — it was that each row's label/value split point moved depending on that row's label
  length, so values didn't align into a scannable column. `dt` is now a fixed `148px` flex-basis and
  `dd` is left-aligned in the remaining space — every value starts at the same left edge across all
  7 rows.
- **Dropped the per-row hairline dividers in `.spec-list`.** Combined with the section's own top
  divider (Round 14) and the surrounding chip-rows, a line under every single one of 7 rows read as
  "dividers for everything." Vertical rhythm now comes from padding alone; the one remaining divider
  in the whole "más información" block is the single top border separating it from the description.

## Round 17 — real spacing bug fixed; ficha técnica label dropped; BGG link shortened
- **Real bug, not a preference: `--space-5` doesn't exist.** The theme's spacing scale only defines
  steps 1/2/3/4/6/8/12 (`default.css`) — there's no `--space-5`. `.desc-collapse`'s `margin-bottom`
  and `.info-accordion-panel-inner`'s `gap`/`padding-bottom` were all set to `var(--space-5)` with no
  fallback, which is invalid at computed-value time and resolves to each property's initial value —
  effectively **zero**. That's exactly the "spacing between Mecánicas and Temas" complaint: the gap
  between those sections (and Ficha técnica below them) was silently collapsing to 0, not just too
  tight. Fixed by using `--space-4` (24px, the nearest real step), both here and on `.desc-collapse`.
  Also tightened `.chip-row`'s gap from `--space-2` (8px) to a literal `6px`, matching
  `.pk-pill-row`'s gap now that `.chip` byte-matches `.pk-pill`'s styling (Round 16) — same family,
  same spacing.
- **Dropped the "Ficha técnica" section-heading.** The spec-list's own row labels (Diseñadores,
  Editorial, Año, etc.) already make it obvious what the block is — a heading above it was redundant.
  "Mecánicas" and "Temas" keep theirs, since chip rows alone don't self-explain their category the
  way labeled spec rows do.
- **BGG link text shortened**: "Ver ficha completa en BoardGameGeek ↗" → "Ver en BoardGameGeek ↗" —
  tighter, reads as a simple outbound link rather than a formal call to action.

## Round 18 — ficha técnica: two columns on desktop, uppercase labels
- **Two-column grid on desktop.** With "más información" now inline in the ~62ch/700px reading
  column (Round 14), one long single-column list of 7 label/value rows was leaving a lot of that
  width unused. `.spec-list` becomes a 2-column CSS grid at `min-width: 769px` (mobile keeps the
  original single column — no spare width to split there). The two "dato no disponible/de ejemplo"
  explanatory rows (the ones using the existing `.missing` marker) span both columns via
  `:has(dd.missing)` instead of participating in the 2-up layout — they carry a full sentence, not a
  short value, and would wrap awkwardly at half-column width.
- **Labels now uppercase**, byte-matching `.section-heading`'s rhythm (`text-xs`/700-weight/
  `letter-spacing: 0.08em`/muted) — "Mecánicas" and "Temas" above already use that treatment, so the
  spec-list's own labels (Diseñadores, Editorial, etc.) were the one inconsistent piece of
  micro-typography left in the block. `dt`'s fixed width shrank alongside it (148px → 112px on
  desktop) since the smaller uppercase text needs less room.

## Round 19 — spec rows: label stacked above value, not side by side
Round 18 kept label and value side by side within each row (just paired two rows per grid line).
That's not what you meant — each field should be its own small stacked card (uppercase label on
top, value below), *then* two of those per row on desktop. Changed `.spec-row` from a horizontal
flex row to a vertical one: `dt` (uppercase, matching `.section-heading`) sits above `dd`, no fixed
label width needed anymore since there's no side-by-side column to keep aligned. Same stacked shape
on mobile and desktop — only how many sit per grid row changes (one on mobile, two on desktop, same
as Round 18). The `:has(dd.missing)` full-width span for the two explanatory rows carries over
unchanged.

## Round 20 — one shared measure, not two matching declarations
Asked to guarantee "más información" and the description are the same width. They already were —
both had their own independently-declared `max-width: 62ch` — but that's exactly the anti-pattern
this project has flagged and fixed repeatedly elsewhere in this same file (Round 6's pill/title
values): two rules with matching values today, with nothing stopping them from drifting apart the
next time either gets edited. Replaced both with one shared `.reading-measure` class, applied to
`.desc-collapse` and `.info-accordion-panel-inner`; neither declares its own `max-width` anymore.

## Round 21 — ficha técnica: two deliberate columns, not an auto-flow grid
The Round 18/19 two-column grid paired items purely by source order — whichever field landed next
took the next cell. With a full-sentence explanatory row (`.missing`) spanning both columns and
breaking the flow partway through, that produced an arbitrary-looking gap rather than a real
grouping (visible in your screenshot: Año/Peso stacked in what read as the left column with a big
empty gap to the right, not an intentional split).

Replaced the single auto-flowing `.spec-list` grid with two separate, semantically grouped `<dl>`
lists side by side in a new `.spec-columns` wrapper:
- **Left — credits/general info:** Diseñadores, Ilustrador, Editorial, Edad mínima.
- **Right — BGG-sourced stats:** Año, Peso (BGG), Puesto en ranking BGG, **Calificación BGG** (new).

Each column is its own independent stacked list now, so the `:has(dd.missing)` full-span hack from
Round 18 is gone — an explanatory row just takes its natural place in whichever column it belongs
to, no special-casing needed. Mobile stacks both `<dl>`s full-width, one after the other.

**⚠ New field, same gap as "Puesto en ranking BGG":** you asked for "Calificación BGG" (BGG's
average user rating — a different metric from `bgg_weight`, which is complexity, not quality). No
dedicated column exists in the `Game` schema for this either; like the ranking, it would need to be
extracted from the untyped `bgg_payload` map. Shown as representative placeholder data ("8.1 / 10 (dato
de ejemplo, no confirmado)"), same treatment as the ranking row.

## Round 22 — row alignment fixed, labels shortened, credits fields made navigable
- **Real alignment bug, not just cosmetic:** Round 21's two separate `<dl>`s (credits column, BGG
  stats column) don't share row heights — they're independent boxes. Ilustrador's long "no
  disponible" sentence wraps and makes the credits column's row 2 taller than the BGG column's row 2
  (Peso BGG, one line), which pushes every row below it out of alignment between the two columns.
  Fixed by going back to **one** grid instead of two boxes: all 8 fields are now one `<dl>`, placed
  into explicit grid cells via `nth-child` (not auto-flow) so the credits/BGG-stats grouping from
  Round 21 still lands in the right columns — but because it's genuinely one shared grid now, CSS
  Grid itself guarantees each row is exactly as tall on both sides, so nothing can misalign. Source
  order in the DOM stays grouped (credits, then BGG stats) specifically so mobile's single-column
  stack still reads in a sensible order, even though desktop re-places things into a 2-column grid.
- **Labels shortened:** "Peso (BGG)" → "Peso BGG", "Puesto en ranking BGG" → "Ranking BGG" (parens
  and filler words dropped, matching "Calificación BGG"'s already-terse phrasing).
- **Diseñadores and Editorial are now navigable**, linking to `/?q=<name>`. **Reopens a
  deliberately-closed gap from Round 3**, which left these unlinked on purpose: `designers`/
  `publishers` aren't structured filter dimensions in `CatalogLive.Index` at all — only the free-text
  `:q` search comes close, and whether the `search_vector` full-text index even covers designer/
  publisher names is unconfirmed. Implemented per this explicit request anyway, using `:q` as the
  closest existing mechanism, but the same caveat applies even harder now that it's live on the page,
  not just a hypothetical: **verify `search_vector` actually indexes these fields before this ships
  for real** — if it doesn't, clicking a designer's name would silently return unrelated or empty
  results. Ilustrador stays unlinked — there's no real value to link when the field itself doesn't
  exist yet.

## Round 23 — dropped the 62ch cap, real dead space on the right
Your screenshot showed real dead space to the right of the description and "más información" — not
a misalignment between the two (Round 20 already guaranteed they match each other), but both of them
being narrower than the actual available column. The text column (masthead's second grid track) is
roughly 668px at the page's 1100px max-width; 62ch is only about 500px. Meanwhile the title, tag-row,
and facts-pill-row above were never capped and already ran the column's full width — so the capped
paragraph/details section was reading as an accidental narrow column next to full-width siblings, not
an intentional design choice. `.reading-measure` now caps at `100%` instead of `62ch` — full width,
matching everything else in the column. This trades away the "~60-75 characters per line" typographic
readability convention in favor of actually using the available space; the shared class stays (so the
two blocks still can't drift apart from each other, per Round 20), it just isn't constraining either
one anymore.

## Round 24 — mobile parity: retired the accordion, unified the compact-value grid
Four mobile questions, addressed together since they're all about the same block:

- **Where's the CTA on mobile?** The fixed `.mobile-cta-bar` at the bottom of the viewport (Round
  11) — always visible regardless of scroll position. Unchanged this round, just confirming: nothing
  about "más información" affects it.
- **"Two accordions" — yes, that was a real problem, not just a feeling.** The description's own
  "Leer más" clamp-toggle and the separate "Más información" accordion trigger sat back to back,
  two different expand/collapse interactions in a row for no real reason. The better affordance
  isn't a different disclosure widget — it's no gate at all. Mobile users already scroll long pages
  routinely (product pages, feeds); hiding supplementary spec data behind a click doesn't save
  meaningful space the way it might on a much shorter page. Retired the accordion **at every width**,
  matching what Round 14 already did for desktop only — `.info-accordion` (trigger, panel,
  max-height animation, `toggleInfoAccordion`) is gone entirely, replaced by a plain `.more-info`
  divider wrapper that was never a disclosure widget in the first place. The scroll-hint that used to
  be desktop-only (replacing the trigger's implicit "there's more" cue) now runs at every width, for
  the same reason.
- **Short key/value pairs can pair up on mobile too — yes.** Round 21/22's 2-column split was
  desktop-only and placed by `nth-child`, tied to a specific credits/BGG-stats column grouping.
  Replaced with a simpler, width-independent rule: `.spec-list` is always a 2-column grid; short
  values (Editorial, Edad mínima, Año, Peso BGG) auto-flow two per row at any width, while a new
  `.spec-row--wide` class forces the genuinely long ones (Diseñadores' two linked names, the three
  `.missing` explanatory sentences) to span the full row instead of cramming into ~140px on a 375px
  screen. No more nth-child bookkeeping — auto-flow just places each row in the next open cell, in
  source order, which also means mobile and desktop finally run the exact same CSS rule instead of
  two different schemes.

## Round 25 — mobile: shorter carousel, stacked + auto-hiding CTA bar
- **Carousel was too tall.** It inherited desktop's `3:4` aspect ratio, which on a 375px-wide phone
  renders at ~500px — nearly a full screen of image before any other content is visible. Mobile now
  overrides to `4:3` (~280px), closer to how most mobile product carousels size a hero image.
- **CTA bar wasn't stacked** — it had kept its own separate side-by-side/icon-only-share layout from
  before the desktop buy-box's Round 15 restructure. Now matches: primary full-width on top, share
  full-width (with its label back, not just an icon) directly below it, same shape as the desktop
  buy box.
- **Stacking made the bar taller, so it now hides on scroll-down and reappears on scroll-up** —
  the same pattern most mobile browser chrome and app bottom-nav bars use to reclaim vertical space
  while you're actively reading, without ever making the action truly unreachable (it's one
  scroll-up away, and it's always visible near the top of the page regardless of direction). `body`'s
  reserved bottom padding grew from 76px to 148px to match the taller stacked bar.

## Round 26 — real bug: the mobile CTA bar has never actually been visible
You reported not being able to see the stacked sticky CTA at all on mobile — and that's not a
viewport/testing issue, it's a genuine CSS cascade bug that's been in this file since the bar was
first built in Round 11.

`.mobile-cta-bar { display: none; ... }` (the base rule) and `.mobile-cta-bar { display: flex; }`
(inside `@media (max-width: 768px)`) have identical specificity. CSS resolves equal-specificity
conflicts by **source order** — last declaration wins — regardless of which media query actually
matches. The base `display: none` rule sat *after* the media query in the file (it lived next to
`.cta-icon`, further down, since that's where it read naturally alongside the other CTA styles), so
it silently won at every viewport width, mobile included. The bar has been in the DOM and styled
correctly this whole time — it was just always `display: none`, no matter the screen size.

Fixed by moving the entire `.mobile-cta-bar` block (base rule, `.is-hidden`, and the
`.cta-primary`/`.cta-icon` width overrides) to before the `@media (max-width: 768px)` block, so the
mobile override now correctly wins. Nothing else about the bar changed — Round 25's stacked layout
and scroll-based hide/show were already correct, they just never had a chance to render.

## Round 27 — scroll-hint removed; mobile CTA bar now hides only while actively scrolling
- **Dropped the "↓ Mecánicas, temas y ficha técnica más abajo" scroll hint entirely** — markup, CSS
  (`.scroll-hint`, the bounce keyframes), and its JS listener are all gone, at every width. It was
  added in Round 14 specifically to replace the accordion trigger's implicit "there's more, click to
  see it" affordance; now that content just flows with no gate at all, the hint wasn't doing a job
  anyone needed done.
- **Mobile CTA bar's hide/show changed from direction-based to activity-based.** Round 25 hid it on
  scroll-down and revealed it on scroll-up. That's not what was asked for — the actual request is
  simpler: visible at rest (including on first render), hidden for the duration of an active scroll
  gesture, revealed again once scrolling actually stops, regardless of direction. Implemented as a
  debounce: every `scroll` event adds `.is-hidden` and resets a 200ms timer; the bar only reappears
  once no further scroll event fires within that window (i.e. the gesture has ended).

## Round 28 — "shows nothing" was the sketch-only dev toolbar covering it, not a real bug
Confirmed the intended pattern is correct: visible at the bottom on first render, high z-index, in
front of the reading content — that's exactly how `.mobile-cta-bar` was already built. Verified this
directly in a browser rather than guessing further (loaded the file, resized to a 375px-equivalent
viewport, inspected `#mobile-cta-bar` — `display: flex`, `opacity: 1`, correctly positioned at the
bottom, real bug from Round 26 confirmed fixed). A screenshot showed the actual cause: `#sketch-tools`
(this file's own theme/viewport picker, a review-only convention, not part of the design) sits
`position: fixed; bottom: 12px; right: 12px; z-index: 9999` — the same bottom-of-screen region as
the CTA bar, with a much higher z-index, so it was visually covering/cutting off the share button.
The CTA bar itself was rendering correctly the whole time. Moved `#sketch-tools` to sit just below
the sticky header (`top: 76px`) instead, clear of both the header's own controls and the bottom CTA
bar at every viewport width.

## Round 29 — real bug: the toolbar's viewport buttons never actually triggered mobile CSS
"Not floating at the bottom of the viewport, at the bottom of the page" pointed at a second,
different bug from Round 26/28 — this one in the sketch's own review tooling, not the design.

The toolbar's 📱375/📟768/🖥1280 buttons only set `max-width` on `.viewport-frame` (`setViewport()`
in the script) — they never touch `window.innerWidth`. Real `@media` queries respond only to the
true browser window, not an inner element's width. So on an actual wide desktop browser window,
clicking "📱 375" visually narrows the mockup but **never satisfies `@media (max-width: 768px)`** —
every mobile-only rule (single-column masthead, full-bleed carousel, and the fixed `.mobile-cta-bar`
itself) stays inactive regardless of what the toolbar shows. What's actually visible in that state is
the *desktop* buy-box's inline `.cta-row`, squeezed into the narrowed frame and positioned wherever
normal document flow puts it — which is exactly "at the bottom of the page" rather than fixed to the
viewport. The fixed bar was never display:none from a bug this time; it was legitimately not the
active CTA at all, because the media query condition was never true.

Fixed properly with CSS **container queries**: `.viewport-frame` now declares
`container-type: inline-size; container-name: sketch-frame`, and the two layout-relevant breakpoints
(`.detail-b`'s mobile block, `.spec-list`'s desktop column-gap) became `@container sketch-frame (...)`
instead of `@media (...)`. Container queries respond to the container element's own rendered width —
exactly what the toolbar buttons control — so the simulator now actually simulates. The lightbox's
own `@media (max-width: 720px)` was deliberately left as a real media query: the lightbox is a
full-screen overlay relative to the true viewport, not scoped inside `.viewport-frame`'s simulated
box, so it should keep responding to the real window.

**Verification note:** this session's sandboxed browser tool couldn't be resized past ~335px width,
so the exact "wide real window + narrowed simulator" scenario that caused the original confusion
couldn't be reproduced end-to-end here. What was verified directly: at the frame's current width,
the container query correctly matches (`.mobile-cta-bar` computed `display: flex`, `.masthead`'s
`grid-template-columns` resolved to a single track) — confirming the mechanism itself works; the
reasoning for the wide-window case rests on standard, well-documented `@container` semantics rather
than an end-to-end screenshot. Worth a real confirm in an actual wide browser window when you get a
chance.

## Round 30 — reverted Round 29: container queries broke `position: fixed`
Your screenshot was genuine Chrome DevTools device emulation (390×844, "iPhone 12 Pro") — a real
viewport resize, not the in-page toolbar's simulation. In that mode `window.innerWidth` is genuinely
390, so plain `@media (max-width: 768px)` queries already work correctly on their own, no help
needed. Round 29's `@container` fix targeted a different, narrower scenario (the in-page 📱/📟/🖥
buttons on an actually-wide browser window) — and in solving that, it broke the one that matters
more: **`container-type: inline-size` implicitly applies CSS containment, and a contained element
becomes a new containing block for `position: fixed` descendants — the same effect `transform` has.**
`#mobile-cta-bar` lives inside `.viewport-frame` (the element Round 29 made a container), so its
`bottom: 0` stopped anchoring to the real viewport and started anchoring to `.viewport-frame`'s own
box instead — which is as tall as the entire page, not just the visible screen. The bar was still
being laid out correctly, just positioned far below the fold, invisible without scrolling to the
literal end of the document. Confirmed by scrolling to `y: 1250` in a real emulated 390×844 viewport
and checking the bar's `getBoundingClientRect()` — before the revert it drifted down with the page;
after, it stayed pinned to the visible viewport regardless of scroll position (screenshot-verified).

Reverted `@container`/`container-type` back to plain `@media` queries. Net assessment: the toolbar's
📱/📟/🖥 buttons remain a rough visual approximation, not a true breakpoint simulator — but the actual
correct way to preview mobile layout (resizing the real browser window, or DevTools' device toolbar,
exactly what this screenshot used) already works fine with plain `@media`, and doesn't carry this
containment risk.

## What to Look For
- Click through the carousel arrows/dots, then click the image to open the lightbox — confirm it
  opens on the same slide the carousel was on, and its own arrows keep both in sync.
- Compare desktop vs. mobile (📱 375): on desktop, image + CTA form the buy-box unit in the left
  column; the right column leads with the facts pills directly above the title, then
  tags/description/mecánicas/temas/ficha técnica flowing as one scrolling reading column. On mobile,
  does the sticky bottom bar feel like the right tradeoff (always reachable, but permanently covering
  ~76px of viewport) vs. an inline CTA you'd have to scroll back up for?
- Scroll the mobile view — confirm the sticky bar stays fixed and never overlaps the footer's last
  content.
- **Desktop only:** scroll down past the description — confirm the buy box (image + CTA) stays
  pinned in view while mecánicas/temas/ficha técnica scroll past it, and that it un-sticks cleanly
  once you reach the footer. Does the "↓ más abajo" scroll hint register before you start scrolling,
  and does it fade out cleanly on first scroll rather than jumping the layout?
- Does the ficha técnica's row-list style feel consistent with the chips/pills used elsewhere, now
  that it's inline in the same column as the description instead of behind an accordion?
- Click a mechanic/theme chip or a pill — given the flagged URL-persistence gap, treat this as
  reviewing the *link targets and labels*, not a working filter yet.
- Description: on desktop, does a 4-line clamp feel like the right "before it needs collapsing"
  threshold, now that it sits alone in a column without a CTA immediately following it?
- Is the icon-only share button (both in the desktop buy-box and the mobile bar) legible enough
  now, relying on the `title` tooltip + adjacency to the primary CTA instead of a permanent label?
