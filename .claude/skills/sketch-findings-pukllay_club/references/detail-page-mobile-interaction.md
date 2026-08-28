# Detail Page — Mobile & Interaction Patterns

Behavior patterns from sketch 005 (36 rounds), with the sticky-chrome trigger mechanism corrected by
sketch 011 (see below — both the CTA bar and the title-echo bar switched from `IntersectionObserver`
to plain scroll listeners). Several of these are general-purpose mobile patterns worth reusing
anywhere a page needs fixed bottom chrome or sticky context, not just this one page. Layout/content
decisions are in `detail-page-layout.md`.

## Design Decisions

### Mobile CTA bar: visible at rest, hides while scrolling, parks at the footer

Three-state behavior on `position: fixed; bottom: 0`, stacked full-width primary + share buttons
(Amazon/Booking.com/Airbnb mobile pattern):

1. **Visible by default**, including on first render — no scroll needed.
2. **Hides for the duration of an active scroll gesture**, reveals ~200ms after scrolling stops.
   Debounced, not direction-based (`.is-hidden`, a small `translateY(12%)` + opacity nudge, not a
   full off-screen slide — this state is meant to read as "paused," not "gone").
3. **Parks once the real `<footer>` scrolls into view** (`.is-parked`, full `translateY(100%)` +
   opacity 0 — this one reads as "gone"). `position: fixed` has no native concept of a boundary to
   stop at the way `position: sticky` does, so this needs an explicit "has the footer entered the
   viewport" check. The bar's reserved `body` padding (space so it never overlaps the last real
   content) collapses to 0 in the same transition, so the footer renders full-bleed instead of
   leaving dead reserved space once the bar's gone.

**Superseded mechanism — do not use `IntersectionObserver` for this**, same reason as the sticky
title bar below: it throttles/suspends in a backgrounded tab, which silently broke this. Sketch 011
drives it off a plain `scroll` listener + `getBoundingClientRect()` instead:

```js
// Debounced hide-while-scrolling
let scrollEndTimer;
window.addEventListener('scroll', () => {
  if (footerReached) return; // don't fight the parked state
  bar.classList.add('is-hidden');
  clearTimeout(scrollEndTimer);
  scrollEndTimer = setTimeout(() => bar.classList.remove('is-hidden'), 200);
});

// Park at the footer — the position:fixed equivalent of position:sticky's
// natural "unstick at the container boundary"
function checkFooterScroll() {
  footerReached = footer.getBoundingClientRect().top < window.innerHeight;
  document.body.classList.toggle('is-cta-parked', footerReached);
  bar.classList.toggle('is-parked', footerReached);
}
window.addEventListener('scroll', checkFooterScroll, { passive: true });
```

```css
.mobile-cta-bar {
  display: none; position: fixed; left: 0; right: 0; bottom: 0; z-index: 60;
  background: var(--color-surface); /* NOT --color-bg — see "color overlapping" below */
  transition: transform var(--duration-base) var(--ease-out-soft), opacity var(--duration-base) var(--ease-out-soft);
}
.mobile-cta-bar.is-hidden { transform: translateY(12%); opacity: 0; pointer-events: none; }
.mobile-cta-bar.is-parked { transform: translateY(100%); opacity: 0; pointer-events: none; }
body { padding-bottom: 148px; transition: padding-bottom var(--duration-base) var(--ease-out-soft); }
body.is-cta-parked { padding-bottom: 0; } /* class beats bare element selector, wins regardless of source order */
```

**Real bug worth remembering generally: equal-specificity cascade order.** The bar was `display:
none` at *every* viewport width for several rounds before this was caught — its base `display:
none` rule and the `@media (max-width: 768px) { display: flex }` override have equal specificity,
and the base rule sat *after* the media query in source order (it lived next to a visually-related
rule further down the file). CSS resolves equal-specificity ties by source order, not by which
media query matches — so the base rule silently won at every width. **Fix: order matters when
specificity ties; verify by reading literal source-line order, not by guessing from a screenshot.**

**Real bug worth remembering generally: `container-type` breaks `position: fixed` descendants.**
An attempt to make an in-page viewport-preview toolbar trigger real breakpoints used CSS container
queries (`container-type: inline-size` on the wrapping frame). This implicitly made that wrapper a
new *containing block* for any `position: fixed` descendant (the same effect `transform` has) — the
CTA bar's `bottom: 0` stopped anchoring to the true viewport and started anchoring to the wrapper's
own (much taller) box instead, silently laying it out far below the fold. Reverted back to plain
`@media` queries. **If a fixed element goes missing/mispositioned right after adding
`container-type`, `transform`, `filter`, `perspective`, `contain`, or `will-change` to *any*
ancestor — that's the first thing to check.**

### Mobile CTA bar internal layout: stacked, not side-by-side (Phase 01.2 gap-closure, sketch 028)

UAT flagged the bar's internal balance as off — a `flex-1` reserve button next to a fixed 44px
circular share button computed to roughly an 87%/13% width split (~7:1) at a real 390px repro
width, compounded by a fill-vs-outline stylistic mismatch (root cause confirmed in the phase's own
debug log — not a regression, a pre-existing condition since the bar's original build). Three
row-rebalance attempts (capping the reserve button's width, filling the share circle solid, pairing
both as same-shape pills) were all rejected as still not reading right. **The winning fix changes
the internal layout instead of the width ratio**: reserve button becomes a full-width row on its
own, share drops to a smaller, quiet outline pill on a second row below it — trading ~40px of extra
bar height for an unambiguous primary action and a share control that still reads as reachable.

```css
.pk-mobile-cta-bar .cta-bar-inner { flex-direction: column; align-items: stretch; gap: 0.5rem; }
.pk-mobile-cta-bar .reserve-btn { width: 100%; }
.pk-mobile-cta-bar .share-btn { width: 100%; min-height: 38px; border-radius: var(--radius-md); border: 1px solid var(--color-border); background: var(--color-bg); color: var(--color-text-muted); }
```

A distinct "floating contrasted circle, detached from the row" idea was tried and reverted: a
`position: absolute` share circle overhanging above the bar's own box overlaps whatever page
content is scrolled underneath it (the bar is `position: fixed`, so its overhang is *fixed screen
space*, not anchored to one bounded panel the way the buy-box's own share icon is in normal
document flow — see `detail-page-layout.md`). If a "floating/elevated" feel is wanted on an
in-bar control, get it from a shadow + contrast ring, never from a position that spills past the
bar's own box.

**Bar content caps to the same column width as the buy-box, not edge-to-edge.** The bar's
*background* may span the full viewport edge-to-edge, but its buttons should cap to the same
1100px max-width as the desktop masthead/buy-box and center within it — otherwise on any viewport
wider than that, the buttons stretch across the raw browser window instead of aligning under the
content column above them. Below 1100px (every real mobile/tablet width) the cap is a no-op.

```css
.pk-mobile-cta-bar { position: fixed; left: 0; right: 0; bottom: 0; background: var(--color-surface); }
.pk-mobile-cta-bar .cta-bar-inner { max-width: 1100px; margin: 0 auto; padding: 0 var(--pk-gutter); }
```

### Color contrast on stacked controls

The CTA bar's background was `--color-bg` (`#FFFFFF`) — identical to its own outlined share
button's background, separated only by a 1px near-white border. Everything at the bottom of the
screen visually fused into one white mass. **Fix: give a bar of stacked controls a background one
step darker/tinted than the controls sitting on it** (`--color-surface` here), not the same token —
verify with computed `backgroundColor`, not by eye, since near-identical tints are easy to miss on a
screen.

### Sticky title-echo bar (top), title-only, with a bounce-to-top affordance

A condensed copy of the masthead's title (not the full facts+title+tags block — that duplicated the
real masthead and read as overloaded when tried) fades in under the site header once the real title
has scrolled fully out of view, so "what game is this" survives scrolling a long page.

**Superseded mechanism — do not use `IntersectionObserver` for this.** The original approach drove
this off an `IntersectionObserver` on the real title block. Sketch 011 replaced it with a plain
`scroll` listener + `getBoundingClientRect()`, for a real reason: Chrome throttles/suspends
`IntersectionObserver` callbacks whenever `document.visibilityState` isn't `"visible"` (a backgrounded
window, some remote-control/automation contexts) — which made this sticky bar silently never appear
in exactly that condition, despite the trigger geometry being correct. A plain scroll listener has no
such dependency.

```js
function checkTitleScroll() {
  const scrolledPast = titleBlock.getBoundingClientRect().bottom < 64; // 64px = site header height
  stickyTitleBar.classList.toggle('is-visible', scrolledPast && !footerReached);
}
window.addEventListener('scroll', checkTitleScroll, { passive: true });
```

**If this bar (or any global scroll listener) can run while its trigger element isn't mounted or is
hidden**, guard the rect read with `el.offsetParent !== null` before trusting it — `offsetParent` is
`null` exactly when an ancestor is `display: none`, and a hidden element's `getBoundingClientRect()`
is always `(0,0,0,0)`, which reads as "scrolled past" (`bottom < 64`) whether or not that's true. This
bit sketch 011 for real: a global listener kept firing on other pages while the detail page was
`display: none` (a single-page toggle unmounts nothing), and `bottom(0) < 64` was trivially true —
the sticky bar showed the last-viewed game's title over unrelated pages. Won't reproduce once this
ships as separate LiveView routes (a route change actually unmounts the DOM), but the defensive
pattern is worth keeping for any listener whose trigger element isn't guaranteed mounted:
```js
scrolledPastIdentity = identity.offsetParent !== null && identity.getBoundingClientRect().bottom < 64;
```

Paired with a small circular scroll-to-top button (`window.scrollTo({top:0, behavior:'smooth'})`)
riding a continuous, gentle `translateY` bounce (not a one-shot on-appear animation) — it needs to
keep reading as "there's more above, tap me" for as long as the bar itself is visible, not just at
the moment it fades in.

**Also parks at the footer**, on the same `footerReached` flag as the CTA bar — even though it
doesn't spatially overlap the footer (it lives right under the header), retracting both together at
the end of content reads as "you've reached the end, chrome's put away" as a coherent pair rather
than leaving one sticky element on-screen after the other's gone.

### Header must actually be tested at real narrow width, not assumed

A breadcrumb (`flex: 1 0 auto` — refuses to shrink) plus a non-shrinking theme toggle squeezed the
brand text below its own content's minimum width at ~390px, wrapping "Pukllay Club" across multiple
lines and blowing the header past its assumed fixed height — which then broke the sticky title
bar's `top: 64px` assumption (a taller real header sits underneath/behind an element positioned
assuming 64px). **This session's own automation browser tool capped at ~335px width and never
reproduced it** — only surfaced via a real Chrome DevTools 390px screenshot. Collapsed the
breadcrumb to a plain "‹ Ludoteca" back-link on mobile (see `page-shell.md` for the "Ludoteca" naming
decision — "Catálogo" was renamed after this pattern was first built) instead of forcing a full breadcrumb trail to
survive a width it can't: a multi-box flex row (link/separator/current-page span) can't
`text-overflow: ellipsis` as one text run — clipping it just chops mid-word with no ellipsis
("CLUBCat").

### Lightbox / carousel sync

Masthead image carousel and its full-screen lightbox share one `carouselIndex` state — opening the
lightbox opens on whichever slide the carousel is currently on, and either one's arrows keep both
in sync (`carouselShow(index)` updates both the inline carousel *and* calls `lightboxShow(index)`).

### Lightbox backdrop must use a fixed dark value, not a theme color token (Phase 01.2 gap-closure
round 2, sketch 033)

**Real bug worth remembering generally: a backdrop/scrim built from a *text* color token inverts in
dark theme.** UAT flagged the lightbox as not contrasting against the page. Root cause: the
backdrop was mixing the app's *text* color token into the scrim rather than a background color. In
light theme the text color is dark, so the scrim reads fine; in dark theme the text color is
near-white, so the "dimming" scrim was actually a pale veil laid over an already-dark page — the
opposite of what a lightbox backdrop needs. **Any scrim/backdrop must be built from a fixed dark
value (or an explicitly background-derived token) that never inverts across themes** — this app
already has exactly that token (a single fixed shadow/scrim color used by every other floating
surface: sheets, drawers, popovers) — reuse it rather than reaching for a semantic text-color
variable that happens to look right in only one theme.

```css
.pk-lightbox { background: color-mix(in srgb, var(--pk-shadow-color, #150826) 72%, transparent); }
```

**Always check a backdrop/scrim fix in BOTH themes before calling it done** — this class of bug is
invisible in light mode and only shows up in dark mode, so testing only the default theme will miss
it every time.

### Lightbox needs standard prev/next navigation, not just a close button

A sketch round that only mocked the close (✕) control missed that production's real lightbox
already ships left/right chevron navigation — industry-standard for any multi-image lightbox.
Caught in review, not by grounding the sketch in the real markup closely enough the first time.
Fix: `‹`/`›` buttons, absolutely positioned and vertically centered at the lightbox's left/right
edges, plus `ArrowLeft`/`ArrowRight` keyboard support alongside the existing `Escape`-to-close.
**Resolved (Phase 01.2 gap-closure round 3, sketch 038), then CORRECTED (round 6, G-01.2-28): the
diagnosis was right, the mechanism was wrong, twice.** UAT confirmed the leftover open question
above was the real bug: the lightbox photo caps at a standalone `min(90vw, 60rem)` instead of the
page's own shell content width, so at wide desktop the photo sits in a small central column while
the arrows stay pinned to the *viewport* edge — a lot of empty scrim between button and photo,
which read as "the overlay isn't correct, it displays background" even though the scrim itself
composites correctly (verified pixel-by-pixel across 5 viewports before concluding this). Neither
"viewport edge" nor "image edge" alone was the right framing — the photo and the arrows need to be
measured against the **same** boundary. That diagnosis is correct and is exactly what round 6
shipped. What round 3 got wrong was the MECHANISM, in two independent ways, both corrected below.

**First wrong mechanism: widening a cap.** Round 3's fix — `max-width: var(--pk-shell-content-width,
1216px)` — was live UAT-tested and found to change nothing visible. Root cause: a `max-width` can
only ever SHRINK an element, never grow one, and this project's seed pipeline (see the catalog fact
below) produces every detail-page photo at a fixed intrinsic width well under any cap this rule has
ever carried — so both the old cap and the widened one sat unused above an image already smaller
than either. **General lesson, transferable beyond this lightbox:** a cap only shrinks, so any
surface whose content is already smaller than its cap needs a real size, not a wider ceiling — and a
box widened without a fill of its own still reveals whatever is behind it, which is why round 6's
photo also gained an opaque `background`, not only a `width`.

```css
.pk-lightbox-img {
  width: var(--pk-shell-content-width);
  height: 100vh;
  height: 100dvh;
  background: var(--pk-shadow-color); /* opaque, full strength — not mixed toward transparency */
}
```

**G-01.2-18, round 7: the carried-forward height was itself the bug.** Round 6 kept the prior
round's `80vh` unchanged on purpose — "the lightbox keeps the exact vertical footprint a human
already approved... picking a different number is a design decision with its own UAT item" — and
that footprint fell 20% short of the viewport. Because `.pk-lightbox` **centres** its child rather
than stretching it, that shortfall didn't shrink the box quietly; it rendered as two symmetric
bands of `.pk-lightbox`'s own translucent scrim, one above the stage and one below it, at every
viewport — and the user reported exactly that ("the background should be full screen"). The
mechanism that replaced it: the property is declared TWICE, the older `100vh` unit as a fallback
and the dynamic-viewport `100dvh` unit immediately after, because on a mobile browser with a
collapsing toolbar the older unit measures the toolbar-COLLAPSED (larger) viewport, so a box
pinned to it alone renders taller than the screen actually showing at any given scroll position.
`.pk-app-shell` in `assets/css/app.css` is this project's original, fully-argued instance of the
same idiom — read that rule's own comment for the complete case for keeping both lines. **General
lesson, transferable beyond this lightbox:** a full-viewport surface is sized against the dynamic
viewport with the static unit kept only as a fallback, and a centring full-inset parent means any
child that falls short of that height shows the parent's own background rather than simply
rendering smaller. One more thing worth carrying forward: the mobile letterbox around the
near-square photo GREW when the stage reached full height — the photo kept its own size while the
solid field around it got larger — and that is expected, not a regression to answer by narrowing
the stage again: the stage IS the full-screen background that was asked for.

**Second wrong mechanism: a bounds wrapper for the arrows.** This section's own snippet used to
propose a separate `.pk-lightbox-bounds` element — full-inset, its own copy of the shell-width
formula — with the arrows repositioned inside it. Round 6 considered that and rejected it: it would
have added a second, hand-written copy of the shell-width formula (the exact drift this file's own
opening claim about "the same boundary" argues against), an element that exists only to hold that
copy, and a `pointer-events` dance to keep the wrapper from intercepting clicks meant for the
overlay beneath it — three new things to get right for a number the stylesheet could already read
directly. The wrapper was the right idea only because, when it was written, nothing in the project
yet named the shell's content width — there was no token to read. Round 6 added one
(`--pk-shell-content-width`, `assets/css/app.css`'s `:root` block), so what shipped instead is a
shared token read three times — by the photo's own `width` and by one horizontal-inset rule per
chevron — with no wrapper element at all:

```css
.pk-lightbox-img { width: var(--pk-shell-content-width); }
.pk-lightbox-chevron-prev { left: calc(50% - (var(--pk-shell-content-width) / 2)); }
.pk-lightbox-chevron-next { right: calc(50% - (var(--pk-shell-content-width) / 2)); }
```

The token IS real now — declared once in `:root`, formula `calc(min(100vw,
var(--container-7xl, 80rem)) - (2 * var(--pk-gutter)))` — so a reader can no longer copy either
snippet above and get a rule that silently resolves to nothing, the way the earlier draft of this
paragraph did before this token existed. **Read it bare, with no fallback literal beside it**: a
fallback is a second, silently-diverging opinion about the shell's width, and defeats the entire
point of naming the boundary once. **Sharper general lesson:** when two elements must agree about a
boundary, name the boundary once and have both read the name directly — don't build a box for one
of them to sit inside, because a box is a second place the number can live, and a second place is
exactly what re-introduces the drift a shared boundary was supposed to close.

**Related, separate bug from the same UAT round: mobile's left chevron rendered behind the image.**
The prev/next buttons and the `<img>` are DOM siblings with no explicit `z-index`; with
`z-index: auto`, paint order follows DOM order, so the image (positioned between the two chevrons
in markup) painted over the prev button wherever their boxes overlapped — at mobile widths the
image's near-full-width cap left only ~20px margin, putting the edge-anchored prev button directly
under the image's edge. Fix: give both chevrons an explicit `z-index` above the image's own
stacking level, don't rely on DOM order alone once elements can visually overlap.

**This stacking-order lesson got MORE load-bearing in round 6 (G-01.2-28), not less.** Before round
6 the chevrons only overlapped the photo incidentally, at phone widths where the image's cap left
little margin. Round 6 moves both chevrons onto the lightbox's new opaque stage deliberately, at
EVERY width — so the explicit `z-index` this fix added is now permanently load-bearing everywhere,
not only in the one narrow band that originally exposed the bug. Removing or weakening it now hides
the arrows at every viewport, not just a phone-width edge case.

**Catalog-specific fact worth carrying forward: the photo can never reach the shell's width on its
own pixels.** The seed pipeline (`PukllayClub.Catalog.Seed.ImagePipeline`) emits a fixed-width,
near-square variant for the detail page — well below the shell's content width at every desktop
viewport. That is exactly why round 6's fix has to be a real box around the photo (a sized, filled
stage) rather than a bigger cap on the photo itself: raising the cap can never outrun a fixed
intrinsic size, only a real box with its own fill can.

### Lightbox open/close needs a soft transition, not an instant `display` toggle

An instant `display: none`/`flex` toggle was flagged as feeling abrupt against this app's otherwise
soft motion language. `display` can't be transitioned directly — switch to
`opacity` + `visibility` + `pointer-events` (the same technique this file's other animated floating
surfaces already use — see the mobile CTA bar's `.is-hidden`/`.is-parked` above), paired with a
small `scale()` on the image card. Use the app's own validated motion tokens
(`--duration-base`/`--ease-out-soft`, see `motion-system.md`) rather than a hand-picked timing
value — no overshoot, small amplitude, consistent with every other transition in this app.

```css
.pk-lightbox { opacity: 0; visibility: hidden; pointer-events: none; transition: opacity var(--duration-base) var(--ease-out-soft), visibility 0s linear var(--duration-base); }
.pk-lightbox.is-open { opacity: 1; visibility: visible; pointer-events: auto; transition: opacity var(--duration-base) var(--ease-out-soft); }
.pk-lightbox-img-wrap { transform: scale(0.96); transition: transform var(--duration-base) var(--ease-out-soft); }
.pk-lightbox.is-open .pk-lightbox-img-wrap { transform: scale(1); }
```

### Share: native Web Share API first, icon-popover fallback second

```js
function toggleShare(btn, evt) {
  if (navigator.share) { navigator.share(shareData()).catch(() => {}); return; }
  // fallback: popover with WhatsApp/X intent links + copy-link (shows a toast)
}
```

### Reservation flow: name-capture modal → pre-filled WhatsApp deep link

Primary CTA → modal asks for name (required-field validation) → constructs a pre-filled reservation
message → shows a preview plus a real, working `wa.me/{number}?text=...` link. **The WhatsApp
number is hardcoded in the sketch only because a static mockup has no config layer** — in the real
app this belongs in runtime env config, not a template literal.

## What to Avoid

- Don't reserve dead `body` padding for a fixed bar without also collapsing it once the bar parks —
  otherwise the footer gets an empty gap once the bar it was protecting against is already gone.
- Don't give a "gesture paused" state (scroll-hide) and a "content ended" state (footer-park) the
  same CSS class or the same visual treatment — they need independent lifecycles (the debounce timer
  must not fight the parked state).
- Don't add `container-type`/`transform`/`contain`/`will-change`/`filter`/`perspective` to an
  ancestor of any `position: fixed` element without checking whether that element goes missing.
- Don't repeat a full facts+title+tags block in a sticky echo bar — title alone is enough context,
  and it's the difference between a 3-line and a 1-line sticky bar.
- Don't assume a header's height for other elements' positioning math without testing real narrow
  widths — a flex row with non-shrinking siblings can silently grow past its assumed height.
- Don't hardcode a business phone number/config value in a sketch and forget to flag it as
  sketch-only — mark it explicitly so it doesn't get copy-pasted into the real app.
- Don't drive scroll-triggered UI off `IntersectionObserver` if it needs to keep working in a
  backgrounded/non-visible tab — Chrome throttles/suspends its callbacks there. Use a plain `scroll`
  listener + `getBoundingClientRect()` instead.
- Don't read a possibly-hidden element's `getBoundingClientRect()` without guarding on
  `offsetParent !== null` first — a hidden element's rect is always `(0,0,0,0)`, which can silently
  satisfy a "scrolled past" check that isn't actually true.
- Don't try to fix a lopsided fixed-bottom bar by rebalancing the width ratio of its existing
  side-by-side controls alone — three width/fill variants were all rejected; switching to a
  stacked internal layout is what actually read as balanced.
- Don't position a control to overhang above the edge of a `position: fixed` bar — that overhang is
  fixed screen space, not anchored to one panel, and will overlap whatever page content is
  scrolled underneath it at some scroll position.
- Don't let a fixed bottom bar's buttons stretch edge-to-edge past the page's own content
  max-width — cap and center them to match the column above, same as the buy-box.
- Don't build a modal/overlay backdrop from a semantic *text* color token — it will invert
  (go pale instead of dark) in dark theme. Use a fixed dark value, or a token explicitly derived
  from a background color, never a text-color token.
- Don't ship a lightbox with only a close control — check the real production markup for prev/next
  navigation before assuming a mockup covers the standard interaction set.
- Don't toggle an overlay's visibility with `display: none`/`flex` if it needs to transition —
  `display` can't animate; use `opacity`/`visibility`/`pointer-events` instead.
- Don't cap a full-screen overlay's content to a standalone width value (`90vw`, a hardcoded `rem`
  cap) independent of the page's own shell content width — measure the photo AND its navigation
  controls against the same shared boundary, not the raw viewport, or the two will drift apart at
  wide desktop widths even though each one looks "correct" in isolation.
- Don't rely on DOM order alone to control paint order between elements that can visually overlap
  (a chevron button next to a wide image) — set an explicit `z-index` once overlap is possible,
  don't assume `z-index: auto` will do the right thing.

## Origin
Synthesized from sketches: 005, 028, 033, 038; sticky-title-bar mechanism corrected by sketch 011.
Source files available in: sources/005-detail-page/, sources/011-full-shell-composition/,
sources/028-mobile-cta-balance/, sources/033-lightbox-contrast/, sources/038-lightbox-shell-width/
