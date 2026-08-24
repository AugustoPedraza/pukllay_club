# About Page Content

## Design Decisions

**Alternating Bands (winner over Single Flowing Scroll and Narrative + FAQ Accordion).**
Full-width bands alternate background tint and left/right image + text layout, marketing-page
style, for the four required sections (mission, how it works, the club, FAQ). Rejected: a single
flowing scroll (cheapest, most textual, but reads as a plain "about" wall of text) and a
narrative-plus-accordion hybrid (icon step-cards for "how it works" + collapsible FAQ — more
net-new component work than justified here).

**Each band's static placeholder became a working image carousel** (arrows + dots, 3 slides)
instead of one static gradient hero — a real "club" section will eventually have several photos
(meetups, game shelf, people playing), not one hero image per section. Structurally this is a real
`<img>` carousel once photography exists; the sketch's slides are gradient-tinted placeholders
standing in for photos.

**FAQ collapsed into a simpler closing band**, not the full interactive accordion explored in the
rejected variant C — Q&A content here reads better as a scannable closing section than as
collapsible content at the bottom of an already-long page (open question in the README: does hiding
content by default work against a page whose whole point is explaining things to newcomers — worth
revisiting if the FAQ list grows much longer).

**Real content is deliberately deferred.** The layout holds roughly-real copy lengths and a
multi-image carousel now, so it won't need structural rework once real content lands — writing the
actual mission statement / club photos / FAQ answers is a separate content task, not blocked on
this layout decision.

## CSS Patterns — the gutter-padding bug (real, worth remembering generally)

The tinted "Cómo funciona" band applied `--pk-gutter` horizontal padding **twice** — once on its
full-bleed wrapper, again implicitly via its inner `max-width: 1100px` box — so its content sat
~2rem wider than the flanking non-tint bands on desktop. Invisible on mobile (viewport already
narrower than 1100px, so the double-padding never has room to manifest) — this exact class of bug
only shows up above the content's own max-width, so verify full-bleed tinted sections at desktop
width specifically, not just mobile.

```css
/* WRONG — double gutter on tinted bands only */
.band.is-tinted { padding: var(--space-8) var(--pk-gutter); }
.band-inner { max-width: 1100px; margin: 0 auto; padding: 0 var(--pk-gutter); }

/* FIXED — full-bleed wrapper carries vertical padding only;
   .band-inner alone carries the horizontal gutter, matching non-tint bands' box math exactly */
.band.is-tinted { padding: var(--space-8) 0; }
.band-inner { max-width: 1100px; margin: 0 auto; padding: 0 var(--pk-gutter); }
```

## HTML Structures

```html
<section class="band is-tinted">
  <div class="band-inner band-split">
    <div class="band-visual">
      <div class="band-carousel" data-carousel>
        <div class="slide is-active">...</div>
        <div class="slide">...</div>
        <div class="slide">...</div>
        <button class="cs-arrow prev">‹</button>
        <button class="cs-arrow next">›</button>
        <div class="cs-dots"></div>
      </div>
    </div>
    <div class="band-text">
      <h2>{section title}</h2>
      <p>{section copy}</p>
    </div>
  </div>
</section>
```

## What to Avoid

- Don't apply gutter padding on both a full-bleed wrapper and its inner max-width box — pick one.
- Don't build the FAQ as a full accordion component before there's enough Q&A volume to justify
  hiding content by default on an explanatory page.
- Don't treat the band visuals as final — they're gradient placeholders standing in for real club
  photography that doesn't exist yet.

## Origin
Synthesized from sketch: 004
Source file available in: sources/004-about-page/
