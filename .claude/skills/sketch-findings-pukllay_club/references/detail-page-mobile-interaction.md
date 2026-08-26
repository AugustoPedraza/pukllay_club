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

## Origin
Synthesized from sketches: 005, 028; sticky-title-bar mechanism corrected by sketch 011.
Source files available in: sources/005-detail-page/, sources/011-full-shell-composition/,
sources/028-mobile-cta-balance/
