---
sketch: 042
name: editorial-tags-divider
question: "Where do editorial hashtag pills sit relative to the description and the ficha-técnica divider, and does that divider still earn its place?"
winner: "Below Title, row (10px gap), text-sm (14px), justified, no divider, 16px to fact grid. Chevron: Variant E — icon-only, truly inline on the truncated text's last line via a float trick (not nested in the clamped <p>), real text-overflow ellipsis. Known deferred issue: '…'/chevron ink alignment not fully resolved in the static mockup — re-tune against the real font at implementation time (see round 27)."
tags: [detail, editorial-tags, divider, gap-closure]
---

# Sketch 042: Editorial Tags & Divider

## Design Question
Phase 01.3 UAT gap G-01.3-1's original complaint: editorial hashtags (`#DuelosMemorables`-style)
render as a bare, unlabelled pill row today, positioned *after* the divider (between it and
Mecánicas). User's suggestion: give it a real "category section," or move it before the divider.
Also open since sketch 040 dropped "Sobre el juego"'s own heading: does the divider still earn its
place?

## Winner
Hashtags sit right after the title (8px gap), before the description — "Below Title" beat "Above
Title" (a kicker line before the game's own name read as disorienting). Rendered as a wrapping row
(reverted from round 11's vertical stack — the row shape suits sitting beside the title better),
10px gap between pills (widened from the stack's 4px — the type is now description-scale, needs more
air than the pill's original tiny-text gap gave it). No divider (removed round 13 — no clear job left
once section headings were already dropped in sketch 040).

## Round History
- **Round 1 — placement:** A (move before divider, still bare) picked over B (labelled "Categorías,"
  no divider) and C (folded into fact grid).
- **Round 2 — rhythm:** tag row promoted from sharing the title/description section (8px gap) to its
  own section (32px gap both sides).
- **Round 3 — color:** solid accent-fill pill ("too heavy") softened to a semi-transparent tint, no
  border.
- **Round 4 — shape:** "wondering if those still should look like pills since are hashtags." Four
  options — A (the round-3 pill, reference), B (plain text), **C (Ghost Chip — picked)**, D (flat
  underline label).
- **Round 5 — social-hashtag scale:** "should them be more like a social network hashtag?" C's 11px
  is a UI-label size, not how a hashtag reads in a caption. Three body-scale follow-ups tested — E
  (C's hover-reveal at `text-sm`), F (bold, `text-base`, tightly packed — closest to Instagram), G
  (always-underlined, `text-sm`, solves touch-discoverability). **All three rejected — the original
  11px Ghost Chip (C) was picked as "the best."**
- **Round 6 — rhythm again:** "improve spacing (top and below)." The winning ghost chip's full 32px
  surrounding gap read as excess dead space, since nothing is visible there at rest. Attempted fix: a
  negative margin on the tag row, stacked on top of `.text-col`'s shared 32px flex `gap`, to fake a
  24px result. **This broke the rendered layout** ("that last change killed the design of details").
- **Round 7 — misdiagnosed fix:** first assumed the negative-margin technique itself was the problem
  and replaced it with an explicit-`margin-top` model (`.rhythm-24`/`.rhythm-32` classes, no shared
  `gap`). Still reported broken — a screenshot showed the *actual* fault: the fact grid and Comunidad
  BGG had fallen back to unstyled browser `<dl>` defaults (stacked, indented, no gaps between BGG
  stats). The real root cause was that the round-6 rewrite (finalizing "C only") had **silently
  dropped** `.spec-list`/`.fact-cols`/`.fact-col dt`/`.bgg-link`/`.bgg-label`/`.bgg-row`/`.bgg-stat`/
  `.bgg-foot` from the stylesheet entirely — a copy-paste omission, not a spacing/margin bug at all.
- **Round 8 — actual fix:** restored the missing CSS block verbatim. The explicit-margin rhythm model
  from round 7 was correct and is kept; the fact grid and Comunidad BGG render with their intended
  styling again.
- **Round 9 — composed against the real neighbor + asymmetric rhythm:** asked to check the hashtags
  against "the accordion that today production has" — verified against the code that **no accordion
  exists on the detail page at all** (only the unrelated filter-modal checklist has one; production's
  own design doc explicitly retired an accordion here). The real neighboring interactive element is
  the description's "Ver más/Ver menos" clamp toggle — added it, functional, so the tag row's
  position can be checked in both collapsed and expanded states. Also: "hashtags look disconnected"
  persisted at symmetric 24px/24px even after round 8's fix. Made the rhythm asymmetric instead of
  retuning one shared value — 16px to the description above (tags are commentary ON it, so sit
  closer) vs. 24px to the divider below (unchanged — still a separate zone from what follows).
- **Round 10 — chevron affordance:** "improve the 'accordion' affordance with a chevron (instead of
  the text) to make it minimal and improve balance." Replaced the "Ver más"/"Ver menos" text link
  with an icon-only chevron button that rotates 180° on expand — one less piece of primary-colored
  text competing with the tag row directly below it. Built with a plain `margin-top`, not a negative
  margin against `.text-col`'s flex `gap` (the exact pattern that broke round 6) — deliberately
  avoided repeating that bug. Tap target is 32px rather than the usual 44px floor, following this
  app's own precedent for a smaller de-emphasized icon control in a secondary, low-frequency spot
  (the footer theme-toggle, shrunk to 28px, footer-scoped). `aria-expanded` drives the rotation and
  is the real accessible state; `aria-label` carries "Ver más"/"Ver menos" for screen readers since
  the chevron alone has no text.
- **Round 11 — stacked, tighter bottom:** "what if are stacked and with less bottom padding?"
  Hashtags now render one per line (`flex-direction: column`) instead of wrapping horizontally, with
  a tighter 4px internal gap (vs. the row's usual 6px wrap-gap). The divider below moved from 24px to
  16px, so the stack sits equally close (16px) to both the description above and the divider below,
  rather than the previous 16px/24px asymmetry. Scoped to this row only via a new `.tag-stack` class
  — the fact grid's own pill rows (Diseñadores, Ilustradores, Mecánicas, Temáticas) keep wrapping
  horizontally, unchanged.
- **Round 12 — match the description's typography:** "the font and its spacing should be similar to
  the description text." Round 5 tested body-scale hashtags and rejected them, but that was in the
  horizontal wrapped-row context — worth revisiting now that the layout is stacked. Hashtag type now
  matches `.desc` exactly: 16px, normal weight (not 600), 1.5 line-height, instead of the pill's
  11px/600 UI-label scale — the stack reads as a continuation of the paragraph's own typography. The
  stack's internal gap dropped from 4px to 0, since the matched line-height now supplies the vertical
  rhythm between lines on its own (a separate gap on top would have doubled it up). Shape, color, and
  the hover-reveal interaction are unchanged.
- **Round 13 — reposition relative to the title (current):** "still that hashtag breaks the
  rhythm... top? or bottom?" — clarified as relative to the title itself, not top-of-page vs.
  end-of-section (an earlier draft of this round misread it that way and built the wrong comparison;
  corrected before finalizing). Two variants:
  - **Above Title:** tags render first, before "Spirit Island" — a kicker line introducing the game,
    no margin needed above it (first element in the column).
  - **Below Title:** tags sit right after the title (8px gap, matching the reading-section's own
    internal rhythm), before the description.
  - **Divider removed in both** ("since we don't have it") — resolves the open question from round 1:
    with section headings already gone (sketch 040) and rhythm alone doing the separating work, the
    `.pk-divider` line no longer has a clear job on this page.

## How to View
open .planning/sketches/042-editorial-tags-divider/index.html — click the A/B/C/D tabs, then click
"Ver más"/"Ver menos" in each to compare the chevron's collapsed vs. expanded position.

## What to Look For (round 21)
- **D vs. A/B/C:** does dropping the circular icon-button chrome for a plain text+chevron label
  finally read as "part of the text," or does it now compete with the description at too-similar a
  weight (the exact thing round 15 stepped hashtags down in size to avoid, applied to a different
  element)?
- This reopens round 10's icon-only decision — confirm or reject explicitly rather than letting it
  drift; if D wins, round 10's rationale (reduce colored-text competing with the tag row) needs a
  fresh answer for why a *muted-gray* label is fine where a *primary-colored* one wasn't.

## What to Look For (round 20)
- **A vs. B vs. C:** now that C has a real ellipsis + a plain non-overlapping trigger (the
  researched standard), does it read as connected enough on its own, or does A's overlap-on-text
  still earn its extra CSS complexity?
- Open question from research, not yet decided: should the chevron gain a visible text label
  ("Ver más ▾" instead of icon-only) and grow to a 44px visual touch target? That would reverse
  round 10's icon-only call — flag a preference either way.

## What to Look For (round 19)
- **A vs. B:** does sitting directly on the truncated text (A) actually read as more connected than
  proximity alone (B), or does the fade gradient feel like an extra visual trick rather than a fix?
- Check both viewports — does the fade width in A ever clip a real word rather than trailing
  whitespace, given the description text is fixed but line-wrap differs at 700px vs. 390px?
- Expand and collapse a few times in each — does the button's position jump distractingly between
  states, or does the transition feel continuous?

## What to Look For (earlier rounds)
- Above vs. Below: does either finally resolve "breaks the rhythm," or does the tag row need a
  fundamentally different treatment regardless of where it sits relative to the title?
- Above: do hashtags introducing the game before its own name read as a natural kicker, or as
  disorienting (leading with tags before you even know what game this is)?
- Below: does pairing tags with the title (both "about this game," ahead of the prose) work better
  than commentary-on-the-description did?
- Now that the divider is gone, does the description→facts→BGG transition still read clearly from
  rhythm alone, or is something missing without it?
- **Round 14 — row, not stack:** "below looks better, but now could take full width (row) instead of
  be stacked." Reverted to the base `.pill-row`'s horizontal wrap; gap widened from 4px to 10px since
  the pill's original 6px row-gap was tuned for 11px text, not the 16px description-matched type.
- **Round 15 — smaller than main text:** "better balance, less than main text." Round 12's exact
  match with `.desc` made hashtags compete at equal weight with the title/description. Stepped down
  one size, 16px → `text-sm` (14px), so they read as secondary/supporting content while staying well
  above the original 11px pill-label scale.
- **Round 16 — chevron polish (current):** "arrow better at right" + "polished subtle animation,
  specially on mobile." Chevron: `align-self: flex-end` moves it to the column's right edge (was
  left by default). Motion: rotation switched from the generic `--duration-fast/--ease-standard` to
  `--duration-base/--ease-out-soft` — sketch 006's own validated "Subtle/Soft" motion pair, not a
  default. Added a real `:active` tap state (scale + tint), since hover never fires on touch and
  mobile needs its own feedback signal. The revealed description text now fades in on expand instead
  of snapping into view.
- **Round 17 — inline chevron + tighter fact-grid gap:** "chevron is totally disconnect of its
  function" — round 16's right-aligned block button sat isolated at the far edge, nothing tying it
  to the text. Moved inside the `<p>` as its last inline child (flush with the last visible word, the
  common "Read more ›" pattern). "A lot of space from the description to the next part" — the fact
  grid's margin-top dropped from 32px to 16px (kept in round 18).
- **Round 18 — revert the nesting, real bug fix:** "I can't see the chevron. Also still
  touching any part of the text makes the behaviour show/hidden." Root cause: nesting an interactive
  `<button>` inside a `-webkit-line-clamp` paragraph's `display: -webkit-box` context is a
  known-fragile combination — icon disappeared, click hit-area spread across the whole clamped block.
  Reverted to a plain sibling button (round 16's shape), `align-self: flex-end` for position, tight
  `margin-top: 0` so it still reads as connected without the broken nesting trick.
- **Round 19 — better chevron integration (current):** the crash fix in round 18 left a new design
  gap — `align-self: flex-end` parks the button at the *container's* right edge, which rarely lines
  up with where the clamped text's own last visible word actually ends, so it read as disconnected
  again, just no longer broken. Two variants, both keeping the safe sibling-button shape (neither
  re-nests inside the `<p>`):
  - **A — Overlay fade:** the button is absolutely positioned over a new `.desc-shell` wrapper so it
    visually overlaps the clamped text's last line, with a gradient fade (matching the surface
    background) standing in for a truncation ellipsis — reads as one "...text ⌄" unit, the standard
    "Read more" pattern. Drops out of the overlay into normal right-aligned flow once expanded, since
    there's nothing left to truncate.
  - **B — Baseline tuck:** no absolute positioning — the sibling button is pulled up with a small
    negative margin to overlap the last line's own line-height slack, and moved to the left edge
    (`flex-start`) so it continues the reading direction instead of jumping to the opposite corner.
    Simpler and more conservative than A, but doesn't sit on the actual text the way A does.
- **Round 19.1 — post-feedback fixes (current):** "on A I can't see it" — a CSS `::after`
  pseudo-element is generated as its host's last child for paint order, so variant A's fade
  gradient (also absolutely positioned, no `z-index`) was painting directly on top of the chevron
  and hiding it completely; fixed with an explicit `z-index` on the button. "the text must to
  justified instead of be aligned to left" — added `text-align: justify` to `.desc`, which also
  changes the geometry both variants depend on: every line but the last now stretches edge-to-edge,
  so trailing whitespace only ever exists on the right (the last line). "on the B is aligned to
  left" — B's original `flex-start` placement no longer related to where the text actually ends
  once justified, so it's flipped to `flex-end` to match A's side.
- **Round 19.2 — soften the fade (current):** "A looks better, but need softer integration of fade."
  The 2-stop linear gradient held a flat, fully-opaque rectangle for its last third, so it read as a
  hard-edged box dropped onto the text — visible straight edges cut across the last line's own
  ascenders/descenders. Replaced with a radial gradient anchored at the corner (no straight edges at
  all, fading outward in every direction — the same vignette technique mobile apps use for corner
  "more" affordances), sized slightly larger so the falloff has more room to happen gradually.
- **Round 20 — industry-practice research (current):** "need more standard industry practices for
  this, research it." Researched the CSS-Tricks canonical text-fade/read-more pattern and
  uxpatterns.dev's expandable-text guidance. Findings:
  1. A gradient fade over a hard cutoff is the standard workaround for `max-height`-based
     truncation, which has no native ellipsis available — it is *not* the standard companion to
     `-webkit-line-clamp`, which already produces a real ellipsis character via
     `text-overflow: ellipsis`. Added that property to all three variants' collapsed state, so
     truncation now shows an actual "…" instead of a hard cut a custom fade had to compensate for.
  2. The standard trigger placement is a clearly separate element — inline-after or its own line —
     not overlapping the truncated text. Added **Variant C: Standard (Ellipsis + Below)**, pairing
     the real ellipsis with a plain non-overlapping trigger positioned just below with a small
     positive gap: the shape production sites (Medium, App Store descriptions, etc.) actually ship.
  3. Sources recommend pairing the icon with a visible text label ("don't rely on icons alone") and
     hitting a 44×44px touch target. Both cut directly against this project's round-10 decision to
     go icon-only at a 26px visual size (justified there against this app's own precedent for small
     de-emphasized controls, e.g. the 28px footer theme toggle). Not silently overridden — flagged
     back to the user as an open decision rather than reopened unilaterally. Applied the accessibility
     win available without touching the visual call: every variant's button keeps its 26px visible
     size but gained an invisible `::before` hit-area expansion (`inset: -9px`, ~44px effective
     tappable region) plus `aria-controls` linking the button to its paragraph.

  Sources:
  - [Text Fade Out / Read More Link — CSS-Tricks](https://css-tricks.com/text-fade-read-more/)
  - [Expandable Text Pattern — UX Patterns for Developers](https://uxpatterns.dev/patterns/content-management/expandable-text)
  - [How to use CSS line-clamp to trim lines of text — LogRocket](https://blog.logrocket.com/css-line-clamp/)
  - [Line Clampin' (Truncating Multiple Line Text) — CSS-Tricks](https://css-tricks.com/line-clampin/)
- **Round 21 — strip the button chrome, not the distance (current):** "still the arrow to
  expand/collapse looks so disconnected of text" — after three straight rounds (18, 19, 20) of
  proximity fixes (overlap-on-text, negative-margin tuck, standard ellipsis+below) that all *kept a
  circular ghost-icon button*, the same complaint kept recurring. Diagnosis: the chrome itself — a
  distinct circle shape with its own hover halo — reads as a separate UI widget regardless of how
  close it sits; proximity fixes couldn't fix a visual-language mismatch. **Variant D — Inline text
  link:** strips the circle and fixed square size entirely; renders as a small text label
  ("Ver más"/"Ver menos") plus a shrunk chevron, set in the paragraph's own muted secondary tone, so
  it reads as continuing the sentence instead of a bolted-on control. This directly applies round
  20's research finding #3 (pair icon with a visible text label) and reopens round 10's icon-only
  decision — not changed silently: A/B/C stay available in case icon-only should be kept instead.
- **Round 22 — true inline via the float trick, verified live in Chrome (current):** "what if we
  show the chevron after the …, with the correct alignment of the paragraph?" Built **Variant E:
  True Inline (Float)** — a different technique from A-D, since none of them can put the trigger
  literally inline on the truncated text's own last line: no `-webkit-line-clamp` at all, just
  `max-height: 72px; overflow: hidden;` with the toggle **floated as the paragraph's own first
  child**, pushed down 48px (2 line-heights) via `margin-top` so lines 1-2 render untouched and only
  line 3 wraps around it — landing "…Ver más ⌄" literally inline after the last visible words, the
  actual thing asked for. This is a different, decades-old technique from round 17's crash
  (float-in-a-plain-paragraph, not an interactive flex child inside `-webkit-line-clamp`'s
  `-webkit-box` mode), so it doesn't repeat that failure.

  Given this sketch's history of "looks broken" rounds from CSS guessed without a render check
  (rounds 6, 17), this one was opened in a real Chrome tab and iterated against actual screenshots
  before presenting. That caught three real defects a static read of the CSS would have missed:
  1. **Justify + float on a sparse line = huge gap.** At 360px, only two words fit beside the float
     on the truncated line, and since more (hidden) text still follows past the visible cutoff, the
     browser never treats that line as the paragraph's true last line — so `text-align: justify`
     kept stretching it, producing one grotesquely wide gap between the two words. Fixed by setting
     `text-align: left` specifically for this variant's *collapsed* state only (the expanded full
     text, which has a real last line, keeps justify like every other variant).
  2. **Toggling stranded the button after one round-trip.** The button needs to physically move —
     staying inline-floated only works against a *known* 2-line offset, which doesn't exist for the
     expanded state's arbitrary-length last line — so JS relocates it: out to a normal trailing
     sibling on expand, back inside the `<p>` as a float on collapse. The first version of that
     logic branched on the button's *current* parent, which only ever matched the first move and
     silently no-op'd on the way back — leaving the button stranded as a flex child of
     `.desc-shell` (where `float` is ignored per spec) on every subsequent collapse. Fixed by
     branching on the *target* state instead, scoped to a `.desc-toggle-inline` marker class so it
     can't affect A-D.
  3. **The "…" prefix silently vanished after the first toggle.** `toggleDesc`'s shared label-update
     line unconditionally wrote plain "Ver más"/"Ver menos", overwriting Variant E's baked-in
     "… Ver más" the first time it ran. Fixed by branching the label text on that same marker class.

  Known tradeoff, disclosed rather than hidden: unlike every other variant (all real
  `-webkit-line-clamp`, which only activates when text actually overflows N lines), this
  `max-height` approach always reserves line-3 space for the float regardless of length — a short
  description that fits in 1-2 lines would still show a dangling "…Ver más" with nothing to reveal.
  The real component would need to only render this markup when the description is known to exceed
  3 lines (likely already necessary server-side logic, but a real constraint this technique adds
  that A-D don't have).
- **Round 23 — drop the label, icon-only (current):** "no usar el 'ver mas'. Use just the icon."
  Round 22's Variant E solved the positioning problem (genuinely inline on the truncated text) but
  still carried round 20/21's "pair icon with a text label" idea forward ("…Ver más ⌄"). This
  settles that open question from round 21's "What to Look For": icon-only wins, once paired with
  real inline placement rather than proximity-only fixes — the "Ver más"/"Ver menos" wording is
  removed from Variant E, leaving just the "…" (a real truncation cue, hidden once expanded since
  there's nothing left to hide) plus the chevron alone. Verified live in Chrome again after the
  change: collapsed/expanded round-trip, `aria-label`, and the ellipsis's visibility toggle all
  still behave correctly.
- **Round 24 — justify back on, verified it no longer breaks (current):** "Be sure the E variant
  has justified alignment, included the ... and arrow." Round 22 had forced `text-align: left` for
  Variant E's collapsed state specifically because justify produced a huge gap on a 360px line where
  only 1-2 real words fit beside the float. That bug came from the float's *width* (the old
  "…Ver más ⌄" label ate most of the line), not from justify itself — round 23 already shrank the
  float to icon-only ("…⌄"), leaving far more width for real words. Re-enabled
  `text-align: justify` on Variant E's collapsed state and re-verified live in Chrome at both
  viewports: enough words now fit per line for justify to read normally, no repeat of the round-22
  gap. The expanded state was never affected (it already justified normally, having a real last
  line). Confirmed via direct DOM inspection that both collapsed and expanded states report
  `text-align: justify` and the toggle still round-trips correctly.
- **Round 25 — fix the "…"/chevron vertical alignment (current):** "3 dots and chevron aren't
  aligned" (screenshot showed the chevron sitting visibly lower than the "…"). Measured both via
  `getBoundingClientRect()` in a live Chrome tab rather than guessing: the ellipsis span and the
  svg were already centered on each other correctly *inside* the button (identical centerY), but
  the whole button sat ~2-3px above the real text's own line box — floats are positioned at the top
  of their line per CSS float rules, with no baseline alignment against surrounding inline text the
  way a normal (non-floated) inline element gets. Nudged the float's `margin-top` from 48px to 50px
  to close that exact measured gap; re-measured after the fix and confirmed the button's box lands
  within 1px of the real text's box at both desktop and mobile widths.
- **Round 26 — the actual ink still didn't line up (current):** "Alignment still is broken,"
  with a screenshot showing the same gap. Round 25's fix only matched the *bounding boxes*
  (`getBoundingClientRect` centerY) of the ellipsis span and the svg — not their *ink*. A period's
  glyph sits low within its own em box, near the baseline, while the svg's chevron path is drawn
  dead-center in its own box; centering the two boxes on each other left the visible glyphs offset
  even though the boxes matched. Confirmed this time with cropped, upscaled screenshots (not just
  numeric rects) showing the chevron sitting visibly below the dots. Nudged the svg with
  `transform: translateY()` and iterated against re-cropped screenshots at -2px/-3px/-4px until the
  two inks actually lined up visually — -4px was the closest match, confirmed at both desktop and
  mobile widths (a screenshot mis-measurement first suggested a mobile-specific gap, but that was a
  wrong crop region — recomputing with the tab's real viewport scale showed mobile matches desktop).
  Re-verified the collapse/expand toggle still round-trips cleanly on both frames after the change.
- **Round 27 — stopping here, known issue deferred to implementation (current):** "Still si [sic]
  the same, but I don't want to expend more cycles on this (I'll do it on the final
  implementation)." Round 26's `translateY(-4px)` nudge did not fully resolve the "…"/chevron
  vertical-ink mismatch from the user's perspective — closing this precisely from a static HTML
  mockup hit diminishing returns (font-rendering/glyph-metrics tuning is exactly the kind of thing
  that's faster to eyeball directly against the real Phoenix-rendered font stack than to keep
  iterating blind against a sketch). **Deferred, not abandoned:** when this pattern is implemented
  for real, re-check the `.desc-toggle svg`'s `transform: translateY()` value (currently -4px)
  against the actual shipped font rather than assuming the sketch's value transfers as-is — different
  font metrics (weight, hinting, the real `--font-sans` stack) can shift where a period's ink sits.
