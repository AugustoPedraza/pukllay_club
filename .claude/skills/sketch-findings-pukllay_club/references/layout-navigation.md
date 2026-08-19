# Layout & Navigation

## Design Decisions

**Full-bleed rows with edge-fade, not hover-only prev/next.** The catalog browse page reads as
distinct Netflix-style shelves via full-bleed rows (break out of any content max-width) with a
gradient edge-fade at each rail's left/right edges. This replaced the production carousel's
hover-revealed prev/next buttons, which its own code comments admit reads as "an unresponsive
grid" — daisyUI's `.carousel` hides the scrollbar with no other visible scroll cue. Edge-fade
gives a passive, always-visible hint that content continues, without requiring hover.

**A real top nav, padding-aligned to row content.** Logo (left), section anchor links, search —
sticky, translucent-on-scroll (flat tint, no blur). The nav's horizontal padding must match the
row content's own edge padding exactly, or elements like the search box read as visually
misaligned with everything below it — this was a real bug caused by using two different spacing
tokens (nav used a smaller value than the row content).

**Mobile needs a second navigation dimension.** Below ~480px, the desktop nav's anchor links don't
fit. Replace them with a horizontally-scrollable row of category chips beneath the nav — this
becomes mobile's equivalent way to jump between shelves.

**Denser mobile card sizing, tuned to actually show the peek.** Target ~3.3 cards visible on a
390px viewport (iPhone 12 Pro width) so the next card visibly peeks in, hinting scrollability.
Getting the numbers right isn't enough on its own — the edge-fade gradient's width must be
narrower than the peeking sliver of the next card, or the fade visually swallows the exact cue
you're trying to create. (Cards ~96-104px, gaps ~8-10px, side padding ~14px, edge-fade ~16-24px
wide, at that viewport width.)

**A trailing "Ver todo {categoría}" tile caps each row** — an explicit way to go deeper into a
shelf's full category instead of relying purely on scrolling further. Same card footprint/rhythm
as the poster cards, dashed border to read as a distinct affordance rather than another game.

**Editorial hashtag rows render as plain text, not raw hashtags.** `#DuelosMemorables` becomes
"Duelos Memorables" (strip the `#`, split on capital letters) as a shelf/row title — raw hashtag
strings as page headings broke visual harmony with the surrounding normal-Spanish-phrase headings.
This is purely a *display* transform for headings; it does not change any underlying hashtag data
or chip labels elsewhere in the app.

## CSS Patterns

Full-bleed row with edge-fade (requires the row's own padding to visually align with the sticky
nav's padding — same token, not independently chosen):

```css
main { max-width: 100%; padding-left: 0; padding-right: 0; }
.app-nav { padding-left: var(--space-6); padding-right: var(--space-6); } /* must match rail-wrap */
.row-header, .rail-wrap { padding: 0 var(--space-6); }

.rail-wrap { position: relative; }
.rail-wrap::before, .rail-wrap::after {
  content: ""; position: absolute; top: 0; bottom: 0; width: 48px; z-index: 4; pointer-events: none;
}
.rail-wrap::before { left: 0; background: linear-gradient(90deg, var(--color-bg), transparent); }
.rail-wrap::after  { right: 0; background: linear-gradient(270deg, var(--color-bg), transparent); }

.rail {
  display: flex; gap: var(--space-3); overflow-x: auto; scroll-behavior: smooth;
  scrollbar-width: none; padding: var(--space-2) 0;
}
.rail::-webkit-scrollbar { display: none; }
```

Nav-on-scroll (flat tint, deliberately not blurred):

```css
.app-nav.scrolled {
  background: color-mix(in srgb, var(--color-bg) 94%, transparent);
  border-color: var(--color-border); box-shadow: var(--shadow-sm);
}
```

Mobile: narrower edge-fade + denser cards + mobile chip nav, all at the same breakpoint:

```css
@media (max-width: 480px) {
  .app-nav .links { display: none; }         /* anchor links replaced by chips below */
  .rail-wrap::before, .rail-wrap::after { width: 16px; }
  .rail { gap: 10px; }
  .poster-card { width: 96-104px; }           /* tune against actual viewport for ~3.3 visible */
  .mobile-chip-nav { display: flex; }
}
```

Mobile chip-row scroll gutter — **do not put padding directly on a horizontally-scrolling element**.
iOS Safari is known to clip the *trailing* padding of a scroll container once scrolled to its end
(the leading/left padding always renders correctly since that's the resting scroll position, but
the far end silently loses its padding). Reserve the margin as real flex-item spacer elements
instead:

```css
.mobile-chip-nav { display: flex; gap: var(--space-2); padding: 0; overflow-x: auto; }
.chip-edge-spacer { flex: 0 0 14px; } /* first and last child */
```

Hashtag-to-plain-text heading transform:

```js
function humanizeHashtag(tag) {
  return tag.replace(/^#/, '').replace(/([a-z])([A-Z])/g, '$1 $2');
}
```

## HTML Structures

```html
<nav class="app-nav" data-scroll-nav>
  <a class="brand">...</a>
  <div class="links">...</div>          <!-- hidden < 480px -->
  <div class="search">...</div>
</nav>
<div class="mobile-chip-nav">...</div>   <!-- flex, only visible < 480px -->
<main>
  <section class="shelf">
    <div class="row-header"><h2>...</h2><p class="row-subtitle">...</p></div>
    <div class="rail-wrap">
      <div class="rail">
        <!-- poster cards -->
        <div class="see-all-tile">Ver todo →</div> <!-- trailing tile, same footprint as cards -->
      </div>
    </div>
  </section>
</main>
```

## What to Avoid

- **Don't rely on hover-only scroll affordances (prev/next buttons that only appear on `:hover`)**
  for the primary scroll cue — invisible on touch devices, and even on desktop it's a secondary
  signal at best. Edge-fade + peeking next-card is the real cue.
- **Don't give the nav and the row content independently-chosen padding values** — even if they
  look close, any mismatch reads as misalignment on inspection (search box, edges).
- **Don't put padding directly on a horizontally-scrolling flex container** if you need guaranteed
  start/end margins — use spacer flex items instead, due to the iOS trailing-padding-clip bug.
- **Don't show raw hashtag strings (`#DuelosMemorables`) as page/row headings** — fine as a small
  chip/badge elsewhere, but reads as broken visual harmony next to normal-Spanish-phrase headings.
- A hero/featured shelf background wash (gradient panel behind the row) tested as "muddy" against
  a white background — a plain heading + thin divider read as cleaner than a light-lavender panel.

## Origin
Synthesized from sketch 001 (shelf-structure), winning variant D.
Source file available in: `sources/001-shelf-structure/index.html`
