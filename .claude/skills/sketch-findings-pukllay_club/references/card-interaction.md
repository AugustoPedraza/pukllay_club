# Card & Preview Interaction

## Design Decisions

**Resting card: poster + title, nothing else.** No metadata (players, playtime, difficulty, tags)
is visible at rest — the game card is deliberately minimal, matching the layout sketch's card
exactly (poster art, then a plain caption block below it with the title in dark text on
`--color-surface`, not overlaid on the image). All metadata lives behind interaction.

**Title in the caption is single-line, always, with ellipsis truncation** — not multi-line clamp.
Reserving room for a possible 2nd line (to keep row card heights equal) was the actual source of a
"weird empty space" problem: a short title left a visible gap below it even when top-aligned.
Removing the 2nd-line possibility entirely removes the whole class of problem — every caption is
naturally the same tight height, no reserved-space trick needed.

**The caption title is anchored to the top of its box** (tight padding right under the poster),
not vertically centered. Centering it inside its own padding made it read as a floating label
disconnected from the image above; anchoring it to the poster's bottom edge is what makes a
caption read as "belonging to" its image.

**Desktop hover pops a preview forward as an enlarged floating panel — Netflix's actual behavior**,
not an inline panel that grows attached below the card. Requires a **300ms hover-intent delay**:
without it, sweeping the pointer across a row fires a preview per card passed over, which reads as
noisy, not helpful — only a card the pointer actually rests on should trigger the preview.

**The preview's size is fixed and independent of the card's own width** — not a multiple of the
resting card's (typically narrow, ~190px) size. A size *derived* from the small card makes shared
text (same font sizes as the mobile sheet) feel oversized/cramped relative to its box. Give the
preview a fixed "modal" width in the same order of magnitude as the mobile sheet's content width,
so text sized identically on both surfaces gets comparable breathing room on both.

**The preview's content must be fixed regardless of the underlying game's data**, or its size will
visibly vary card to card (a tag chip present on one game but not another, or a variable-length
description, changes the box's height). Two ways to keep this fixed: (a) exclude variable-length
content from the compact preview entirely, keeping only fixed-shape fields (title, one metadata
row, CTA), or (b) include variable content but hard-clamp it to a fixed number of lines (e.g.
`-webkit-line-clamp`) so its rendered height can never change. Prefer (b) over (a) when the content
adds real value (e.g. a short flavor/theme description) — omitting it entirely to solve a sizing
problem throws away useful information; clamping solves the same problem without that cost.

**Mobile: tap opens a full-screen sheet, not an inline expand.** Same reasoning as Netflix's own
mobile app: an inline expand inside a touch-scrolling rail is fragile on small screens, and (see
"CSS pitfall" below) can be flat-out broken by a real browser overflow-clipping behavior.

**Desktop and mobile must share identical CSS for anything meant to look the same** — not just
similar values. Divergences that crept in during iteration and had to be corrected: the preview
used a smaller title font-size than the sheet (20px vs 28px — literally different text for the
same field); the preview clamped a description to 2 lines at a smaller font while the sheet used 3
lines at a larger font (same game's description read as different text); the preview's poster used
a near-square aspect-ratio while the sheet's used 16:9 widescreen (same poster image, different
crop, depending which surface opened it). **The fix pattern that actually works: write ONE shared
CSS class per field/element (e.g. `.card-title`, `.theme-text`, `.facts-row`) and use it verbatim
on both surfaces — never scope the same visual property to each surface independently, even if the
values start out matching.** Independent same-looking values will eventually drift; a shared class
structurally cannot.

**Difficulty indicator replaces raw min-age everywhere.** A raw age-recommendation number doesn't
help someone judge whether a game is right for them; a difficulty cue derived from the existing
weight/complexity classification does. Represent it as **3 small dots (filled count = level 1-3)
paired with the real classification label already used elsewhere in the app** (not raw text alone,
not dots alone) — dots with no label tested as ambiguous on their own, and inventing a second,
different vocabulary just for this indicator (e.g. "Fácil/Moderado/Difícil") when the app already
has an official 3-tier band name elsewhere creates two parallel vocabularies for the same concept.
Reuse the existing one. Keep the dot fill a muted/neutral color, not the brand accent color — a
brightly-colored standalone difficulty badge tested as visually louder than a metadata detail
should be; folding it in as a plain third item alongside the other facts (same size/color/weight)
reads as appropriately secondary.

**CTA ("Ver detalles") is secondary (outlined, not filled) everywhere on this card family** — in
both the hover preview and the full sheet. It's a lower-commitment action than whatever
interaction (hover, tap) already got the user to this point; a filled primary button here
over-emphasizes it relative to the content around it.

**Metadata row layout: `justify-content: space-between` across a small fixed set of items**
(players, tiempo, difficulty) reads better than bunching them left with a gap, once the container
has real width to work with (e.g. inside a wider preview/sheet, not the narrow resting card).

**Open, not yet resolved:** whether mechanic chips or editorial tags deserve a place in the compact
desktop preview at all (currently: no — only the mobile sheet, which has more room, shows the
editorial tag; mechanics never appear on the card in any state, desktop or mobile).

## CSS Patterns

**The overflow-clipping pitfall (the actual root cause of "broken on mobile"):** placing an
absolutely-positioned expand/preview panel *inside* a horizontally-scrolling rail breaks on touch
devices. Per the CSS spec, once one axis of `overflow` is non-`visible` (e.g. `overflow-x: auto`
for the horizontal scroll), the other axis silently computes to `auto` too — so the rail clips
vertical overflow as well, even though you only asked for horizontal scrolling. Any child meant to
visually escape the rail's bounds (a hover-expand panel, a popover) will be invisibly clipped.

```css
/* BROKEN — .expand-panel gets clipped by .rail's implied overflow-y:auto */
.rail { overflow-x: auto; }
.card { position: relative; }
.card .expand-panel { position: absolute; top: 100%; /* ...clipped */ }
```

```css
/* FIX — render the expand surface as a single shared element OUTSIDE the
   rail entirely (position: fixed, appended once, not nested in any
   scrolling container), and position it via getBoundingClientRect() */
.hover-portal {
  position: fixed; z-index: 500; opacity: 0; pointer-events: none;
  transform: scale(0.9); transition: opacity .22s, transform .22s;
}
.hover-portal.visible { opacity: 1; pointer-events: auto; transform: scale(1); }
```
```js
function showPortal(cardEl, i) {
  const rect = cardEl.getBoundingClientRect();
  const w = PORTAL_WIDTH; // fixed, NOT rect.width * someScale
  const grow = w - rect.width;
  const left = Math.max(8, Math.min(rect.left - grow / 2, window.innerWidth - w - 8));
  const top = Math.max(16, rect.top - grow / 2);
  portalEl.style.width = w + 'px';
  portalEl.style.left = left + 'px';
  portalEl.style.top = top + 'px';
  portalEl.innerHTML = renderPreviewContent(GAMES[i]);
  portalEl.classList.add('visible');
}
```

Hover-intent delay (skip firing on a pointer just passing through):

```js
const HOVER_INTENT_DELAY = 300;
let showTimer, hideTimer;
function onCardEnter(cardEl, i) {
  clearTimeout(hideTimer); clearTimeout(showTimer);
  showTimer = setTimeout(() => showPortal(cardEl, i), HOVER_INTENT_DELAY);
}
function onCardLeave() {
  clearTimeout(showTimer);
  hideTimer = setTimeout(() => portalEl.classList.remove('visible'), 120);
}
```

Shared field styling (one class, used verbatim on both surfaces — this is the pattern, not just
an example):

```css
.card-title {
  font-family: var(--font-display); font-size: var(--text-display);
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.theme-text {
  font-size: var(--text-base); line-height: 1.5;
  display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden;
}
.facts-row { display: flex; align-items: center; justify-content: space-between; }
```

Difficulty dots:

```css
.difficulty { display: inline-flex; align-items: center; gap: 3px; }
.difficulty .dot { width: 5px; height: 5px; border-radius: 50%; background: var(--color-border); }
.difficulty .dot.filled { background: var(--color-text-muted); } /* muted, not brand accent */
```
```js
function difficultyDotsHTML(level) { // level: 1-3, from weight_band
  return `<span class="difficulty">${[1,2,3].map(n =>
    `<span class="dot${n <= level ? ' filled' : ''}"></span>`).join('')}</span>`;
}
```

Single-line ellipsis title (resting card caption — simpler and more robust than
`-webkit-line-clamp: 1`, which has flex-shrink quirks when the element shares a row with siblings):

```css
.card .cap h4 {
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
```

**A `-webkit-line-clamp` element placed beside a sibling in a flex row can bleed into that sibling**
— its intrinsic width for flex-shrink purposes isn't reliably based on its clamped size across
browsers, so a "truncated" title next to e.g. metadata pills may not actually shrink and instead
overlaps them. If a title needs to share a row with other fixed-width content, prefer giving that
other content (pills, badges) its own separate row instead of fighting this, or use standard
`white-space: nowrap; text-overflow: ellipsis;` (single-line only) rather than `line-clamp`, which
does not have this issue.

## HTML Structures

Resting card:
```html
<div class="card">
  <div class="poster-art palette-N">🎲</div>
  <div class="cap"><h4>Título del juego</h4></div>
</div>
```

Desktop hover-portal / mobile sheet content (same shape, rendered by the same helper functions):
```html
<div class="pills-row">          <!-- own row, ABOVE the title, not beside it -->
  <span class="pill">👥 3-4</span>
  <span class="pill">🕐 60-90 min</span>
  <span class="pill">●●○ Ingenio estratega</span>
</div>
<h2 class="card-title">Título completo del juego</h2>
<p class="theme-text">Descripción de ambientación/tema del juego…</p>
<span class="expand-tag">#EtiquetaEditorial</span>  <!-- sheet only -->
<button class="expand-cta">Ver detalles</button>
```

## What to Avoid

- **Don't nest an absolutely-positioned expand/preview panel inside a horizontally-scrolling
  container.** This is the single most impactful bug found across this exploration — it silently
  breaks on touch due to the CSS overflow-x/overflow-y interaction described above, and reads as
  "the UI is broken" rather than an obvious CSS issue.
- **Don't derive a preview/modal's size from the small card that triggered it.** Use a fixed size
  appropriate to the preview's own content, especially if that content shares font sizes with
  another (larger) surface like a full-screen sheet.
- **Don't let two surfaces meant to look the same have independently-declared CSS for the same
  field** (font-size, line-clamp, aspect-ratio, spacing) — even values that currently match will
  drift during iteration. Use one shared class.
- **Don't show a raw numeric age recommendation as a primary decision fact** on a card aimed at
  non-expert users — replace with an interpretable indicator paired with existing vocabulary.
- **Don't give a difficulty/complexity indicator its own bright, bordered pill/badge treatment** —
  it reads as louder than a metadata detail warrants; fold it in as a plain item alongside other
  facts instead.
- **Don't let a preview/modal's height vary with the underlying data** (conditional tag chip,
  variable-length text) unless that variability is explicitly clamped — otherwise adjacent
  previews in the same session will visibly differ in size for no apparent reason.
- Considered and rejected: dropping the title caption entirely and relying on the poster image
  alone (Netflix's own pattern for movie posters). Not a good fit for a catalog of ~400 real
  box-cover photographs of inconsistent legibility, for an audience that doesn't already recognize
  the products by sight — a guaranteed-legible UI caption is the safer choice here.

## Origin
Synthesized from sketch 002 (card-hierarchy), winning variant D (multiple iteration rounds).
Source file available in: `sources/002-card-hierarchy/index.html`
