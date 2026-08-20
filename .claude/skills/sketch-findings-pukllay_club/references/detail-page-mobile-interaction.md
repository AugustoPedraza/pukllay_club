# Detail Page — Mobile & Interaction Patterns

Behavior patterns from sketch 005 (36 rounds). Several of these are general-purpose mobile
patterns worth reusing anywhere a page needs fixed bottom chrome or sticky context, not just this
one page. Layout/content decisions are in `detail-page-layout.md`.

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
   stop at the way `position: sticky` does, so this is faked with an `IntersectionObserver`
   watching the actual footer element directly — not a scroll-position pixel threshold, so it
   stays correct regardless of how tall the page content ends up being. The bar's reserved `body`
   padding (space so it never overlaps the last real content) collapses to 0 in the same
   transition, so the footer renders full-bleed instead of leaving dead reserved space once the
   bar's gone.

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
new IntersectionObserver(([entry]) => {
  footerReached = entry.isIntersecting;
  document.body.classList.toggle('is-cta-parked', footerReached);
  bar.classList.toggle('is-parked', footerReached);
}, { threshold: 0 }).observe(document.querySelector('footer'));
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
has scrolled fully out of view, so "what game is this" survives scrolling a long page. Driven by
`IntersectionObserver` on the real title block (not a scroll-position threshold), with the
observer's `rootMargin` top offset accounting for the site header's own height so "out of view"
means "scrolled under the header," not just past `y=0`.

```js
new IntersectionObserver(([entry]) => {
  const scrolledPast = !entry.isIntersecting && entry.boundingClientRect.top < 0;
  stickyTitleBar.classList.toggle('is-visible', scrolledPast && !footerReached);
}, { rootMargin: '-64px 0px 0px 0px', threshold: 0 }).observe(titleBlock);
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
breadcrumb to a plain "‹ Catálogo" back-link on mobile instead of forcing a full breadcrumb trail to
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

## Origin
Synthesized from sketch: 005
Source file available in: sources/005-detail-page/
