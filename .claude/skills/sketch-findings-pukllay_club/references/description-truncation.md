# Description Truncation & "Read More" Toggle

The game detail page's description is a 3-line clamp with a "Ver más"/"Ver menos" toggle. This
looks like a small, one-off UI element but took 27 rounds (sketch 042) to land — first a crash, then
five straight rounds of "it still looks disconnected from the text" despite each round genuinely
fixing the specific thing reported. This file exists because that history is the actual value: the
final CSS is a few lines, but *why* every simpler-looking alternative failed first is what makes it
reusable anywhere else in the app that needs a truncate-and-reveal control.

## Design Decisions

**The chevron must NOT be nested inside the clamped `<p>` as a flex child (this crashed once,
concretely — round 17).** Nesting an interactive `<button>` inside a `-webkit-line-clamp` paragraph
(`display: -webkit-box`) is a known-fragile browser combination: the icon disappeared and the click
hit-area spread across the entire clamped text block. This is NOT "any button inside a paragraph is
risky" — plain buttons inside plain paragraphs are fine everywhere else on the web. It's specifically
`-webkit-line-clamp`'s `-webkit-box` rendering mode that doesn't compose reliably with an interactive
flex-participating child.

**Proximity alone does not fix "the chevron looks disconnected from the text" — the chrome itself
was the problem (rounds 18-20 vs. round 21).** Three straight rounds moved the same circular
ghost-icon button progressively closer to the text (overlapping it via absolute position, tucking it
via negative margin, placing it in the "standard" position right below the clamped paragraph) and
the same complaint kept recurring. The actual fix was dropping the circular icon-button chrome
entirely — a distinct circle with its own hover halo reads as a separate UI widget no matter how
close it sits. **If a small icon control keeps reading as "bolted on" despite being spatially close
to what it controls, suspect the chrome (shape/background/hover-halo) before spending another round
on position.**

**Industry-standard research changed the direction, not just the polish (round 20 → 21).**
Researched the CSS-Tricks canonical text-fade/read-more pattern and a UX-patterns reference for
expandable text. Two findings that mattered: (1) a gradient fade over a hard truncation cutoff is
the standard workaround for `max-height`-based truncation with no native ellipsis — it is *not* the
standard companion to `-webkit-line-clamp`, which already has a real ellipsis via
`text-overflow: ellipsis`. (2) sources recommend pairing an icon with a visible text label ("don't
rely on icons alone"). This directly informed dropping the custom fade-gradient overlay approach and
trying an icon+label variant — though the FINAL winner (below) went icon-only anyway, once genuine
inline placement solved the underlying complaint the label was trying to compensate for.

**Winner: the chevron sits literally inline, on the truncated text's own last line, via a float
trick — not `-webkit-line-clamp` at all (round 22).** What was actually being asked for the whole
time: "…⌄" flush after the last visible word, not merely close to it. This can't be done by nesting
inside a `-webkit-line-clamp` paragraph (that's the round-17 crash), so it uses an entirely different,
older technique instead: no line-clamp, just `max-height` + `overflow: hidden`, with the toggle
**floated as the paragraph's own first child**. A `margin-top` of two line-heights keeps the float
from affecting the first two lines (they render full-width, untouched); text only wraps around the
float once it reaches the float's vertical position — which lands exactly on the 3rd/last visible
line. `max-height` (3 line-heights) then clips anything past that point. Floats inside plain
paragraphs are a decades-old, universally-supported combination — not the specific flex/-webkit-box
interaction that broke round 17.

```css
.desc.is-clamped { display: block; max-height: 72px; overflow: hidden; text-align: justify; text-justify: inter-word; }
.desc-toggle { float: right; clear: right; margin: 50px 0 0 4px; /* 2 line-heights, tuned +2px vs. text's box */
  width: auto; height: auto; border-radius: var(--radius-sm); padding: 1px 3px; color: var(--color-text-muted); }
.desc-toggle-ellipsis { font-size: var(--text-base); line-height: 1; } /* the actual "…" character, not text-overflow */
.desc-toggle[aria-expanded="true"] .desc-toggle-ellipsis { display: none; } /* nothing left to truncate once expanded */
.desc-toggle svg { width: 12px; height: 12px; transform: translateY(-4px); } /* see ink-alignment note below */
```

**Icon-only wins over icon+label, once paired with real inline placement (round 23) — settles the
round-20 research finding above, but in the opposite direction it first suggested.** Round 22's
inline chevron still carried the "pair icon with a text label" idea forward ("…Ver más ⌄"). Direct
feedback: "no usar el 'ver mas'. Use just the icon." The "don't rely on icons alone" research
guidance turned out to be compensating for icons sitting in the wrong place, not for icons per se —
once the chevron is genuinely inline on the text itself, the text label became redundant. The visible
label is gone; `aria-label`/`aria-expanded` still carry "Ver más"/"Ver menos" for screen readers.

**Justified text, including the truncated line the chevron sits on (round 24, then round 26 for the
mobile-specific failure mode).** A justified `text-align` on a line that also has a float competing
for its width can produce a single grotesquely wide inter-word gap when very few words fit beside
the float — this actually happened once, when the toggle still carried the "Ver más" text label
(a much wider float than the icon-only version). Confirmed the fix was really the icon-only change
(round 23) shrinking the float's footprint, not disabling justify — re-verified live at both
viewports after re-enabling it.

**The DOM node must physically relocate between collapsed and expanded state — and the relocation
logic must branch on the TARGET state, not the button's current parent.** Staying float-positioned
only works against a *known* fixed offset (2 line-heights), which doesn't exist for the expanded
state's arbitrary-length last line. JS moves the button out to a normal trailing sibling position on
expand, and back inside the `<p>` as a float on collapse:

```js
function toggleDesc(id, btn) {
  var el = document.getElementById(id);
  var shell = btn.closest('.desc-shell');
  var expanded = el.classList.toggle('is-clamped') === false;
  shell.classList.toggle('is-expanded', expanded);
  btn.setAttribute('aria-expanded', expanded ? 'true' : 'false');
  // Branch on the TARGET state (expanded), not btn.parentElement — a version that checked
  // "is the button currently inside <p>?" only ever matched the FIRST expand, then silently
  // no-op'd on every subsequent collapse, stranding the button as a flex child of the shell
  // (where `float` is ignored per the flexbox spec) permanently after one round-trip.
  if (expanded && btn.parentElement !== shell) { shell.appendChild(btn); }
  else if (!expanded && btn.parentElement !== el) { el.insertBefore(btn, el.firstChild); }
}
```

## Known Issues, Deferred to Implementation (found in a sketch, not fixed in one)

**"…"/chevron vertical ink alignment.** The ellipsis span and the svg chevron were measured as
correctly centered on each other's *bounding boxes* (`getBoundingClientRect()`, identical centerY),
but a period's glyph sits low within its own em-box near the baseline while an svg path is drawn
centered in its box — centering the boxes doesn't center the ink. A `transform: translateY(-4px)`
on the svg was tuned against cropped/upscaled screenshots and got close but user feedback after the
fix still read it as slightly off. **Diminishing returns from a static HTML mockup — re-tune this
value directly against the real Phoenix-rendered `--font-sans` stack** (different font
weight/hinting shifts where a period's ink actually sits) rather than assuming the sketch's -4px
transfers as-is.

**The float trick can cut text mid-word, not just mid-alignment — a more serious version of the
above (discovered composing this pattern into a full page at a different width, sketch 043).**
`-webkit-line-clamp` + `text-overflow: ellipsis` (which this technique deliberately doesn't use — see
the round-20/21 finding above) is the only mechanism with a *native* clean-cut guarantee. This
`max-height`-based float trick has no equivalent: wherever the hard pixel cutoff lands, it lands,
mid-glyph if necessary. Sketch 042's own demo happened to land on a clean word boundary at its
700px desktop frame; composing the identical CSS into a 760px frame (sketch 043) cut mid-word
("...expulsar a l..." — the real text continues "los invasores"), and reproduced at the mobile
frame too. **Before shipping: validate against real game descriptions at the real card width.** If
mid-word cuts turn out to be common with production content, fall back to the "Standard" variant
this sketch also built and rejected only on aesthetic grounds — real `-webkit-line-clamp` +
`text-overflow: ellipsis`, trigger positioned as a plain non-overlapping element below the text
(no float, no DOM relocation, no ink-alignment problem at all):

```css
.desc.is-clamped { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 3; overflow: hidden; text-overflow: ellipsis; }
.desc-toggle { align-self: flex-end; margin-top: 6px; } /* sibling of <p>, never nested inside it */
```

## What to Avoid

- Don't nest an interactive element as a flex child inside a `-webkit-line-clamp` paragraph — that
  specific combination (not "any button in a paragraph") is fragile and can silently break rendering
  and hit-testing.
- Don't keep repositioning the same icon-button chrome closer and closer to fix "looks
  disconnected" — after two proximity fixes don't resolve the complaint, suspect the chrome itself
  (a circular ghost-button with its own hover halo reads as separate no matter how close it sits).
- Don't pair an icon with a text label as a blanket fix for "icons alone aren't enough" — check
  whether the icon is just in the wrong position first; genuine inline placement made the label
  redundant here.
- Don't branch DOM-relocation logic on an element's *current* parent to decide whether to move it —
  branch on the *target* state. A current-parent check only ever fires once in one direction and
  silently stops working on the return trip.
- Don't assume two bounding boxes being centered on each other means their visible ink is aligned —
  different glyph types (a text character vs. a vector icon) can occupy very different portions of
  their own box.
- Don't reach for a `max-height` + float trick to get truly inline truncation-plus-trigger unless a
  native-ellipsis alternative has been ruled out — it has no clean-cut guarantee at all, and can chop
  a real word mid-glyph depending on exact width/content, which `-webkit-line-clamp` +
  `text-overflow: ellipsis` never does.
- Don't validate a truncation pattern at only one container width — sketch 043 found the mid-word
  cut specifically by composing the identical CSS into a 60px-wider frame than the original sketch
  ever tested.

## Origin
Synthesized from sketch: 042 (27 rounds — see the sketch's own README for the complete round-by-
round history) and sketch 043 (composition at a different width surfaced the mid-word-cut risk).
Source files available in: sources/042-editorial-tags-divider/, sources/043-composed-full-detail-page/
