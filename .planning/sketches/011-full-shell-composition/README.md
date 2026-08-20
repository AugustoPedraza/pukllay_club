---
sketch: 011
name: full-shell-composition
question: "Does the real shell (003-C/007) hold together once it wraps the real, winning detail page (005-B) and about page (004-B) — instead of the light placeholder skeletons 007 left in their place — and what drift shows up when they're actually composed?"
winner: "single composed view (consistency check, not a design alternative)"
tags: [consistency, layout, detail, about, shell]
---

# Sketch 011: Full Shell Composition

## Design Question
Sketch 007 composed the real shell (003-C's header/footer) with the real catalog shelves/cards
(001-D/002-D) and found two real drift bugs doing it — but 007 explicitly left `#page-detail` and
`#page-about` as light placeholder skeletons, deferring "does the shell actually hold together with
the real detail and about page content" to a future sketch. This is that sketch: it replaces 007's
placeholders with the real, winning content from 005 (detail page, variant B) and 004 (about page,
variant B), and — same as 007 — actively looks for what didn't line up rather than assuming it
would.

## Grounding
Header, footer, page-switcher, catalog shelves/cards, and hover-portal/mobile-sheet interaction are
copied verbatim from `007-composed-catalog-page` (which itself copied them verbatim from
001-D/002-D/003-C). Detail-page masthead/buy-box/carousel/lightbox/CTA/spec-list/reservation-modal
are copied from `005-detail-page` variant B. About-page hero/alternating-bands/carousel/FAQ are
copied from `004-about-page` variant B. Every deviation from a straight copy-paste is called out
below — nothing was changed silently.

## How to View
open .planning/sketches/011-full-shell-composition/index.html

Use the dashed **Sketch control** bar to switch Catálogo / Detalle / Acerca de. On Detalle, hover
"Juegos similares" cards (desktop) or tap them (mobile) to confirm they get the same hover-portal/
sheet interaction as the catalog's own cards, scroll to see the mobile sticky CTA bar and
game-identity bar (resize to ≤768px), and open the image carousel/lightbox and the "¡Quiero
Jugarlo!" reservation modal.

## Real drift found while composing

1. **Two independent header implementations.** 007's shell has one `.app-nav` component with three
   grafted states (full nav / breadcrumb / quiet label), switched via `data-catalog-only`/
   `data-detail-only`/`data-about-only` and `showPage()`. Both 005 and 004 each shipped their *own*
   separate header (`.pk-header`/`.pk-nav`/`.pk-brand`/`.pk-nav-crumb`/`.pk-theme-toggle`) — different
   class names, a different sticky `z-index` (40 vs the shell's 100), and dead `☀`/`🌙` toggle buttons
   with no `onclick` at all. Composed naively, the page would have shipped two stacked headers on
   detail/about. Fixed by discarding 005's and 004's header markup/CSS entirely and using only the
   shell's already-adapted breadcrumb/quiet-label states — which already say exactly what 005/004's
   own headers were trying to say ("Catálogo / {game}" and "Acerca de").

2. **`--pk-gutter` duplicated the shared `--space-6` token, and the footer was declared three
   times.** 005 and 004 each independently declared `:root { --pk-gutter: 2rem; }` and used it for
   every horizontal gutter, instead of the shared theme's `--space-6` (also 32px) that the shell/
   catalog use for the same purpose. Numerically identical today, but two independently-declared
   "the same value" tokens is exactly the drift risk this project's own findings have flagged
   repeatedly (001-D vs 002-D's card size, 007's rail gap) — a future edit to one wouldn't touch the
   other. Compounding this, 005 and 004 *each* redeclared the entire `.footer-c`/`.bgg-badge`/
   `.footer-social` footer block a second and third time (007 already has it once), using
   `var(--pk-gutter)` where 007's copy uses `var(--space-6)` for the identical padding. Fixed:
   `--pk-gutter`/`.pk-gutter` removed entirely, every occurrence replaced with `var(--space-6)`; only
   one footer declaration survives (007's), reused for all three pages since it's a single shared
   element outside the page-switcher's `.page` divs.

3. **005's "Juegos similares" shelf had its own, already-drifted card/rail — same failure mode 007
   already found once between 001-D and 002-D.** 005's README states this shelf is "the same real,
   shipped home page pattern... reused here rather than invented fresh" — but its actual
   implementation (`.pk-poster-card`/`.pk-rail`) never actually pointed at the real component: `160px`
   width vs the real `.card`'s `190px`, `border-radius: var(--radius-lg)` vs the real card's
   `var(--radius-md)`, `translateY(-2px)` hover-lift vs the real `-4px`, `108px` mobile width vs the
   real `96px` — and it was a plain `<a>` link with none of the hover-portal (desktop) / tap-to-sheet
   (mobile) interaction every other card on the site has. Fixed: the shelf now renders with the real
   `cardHTML()`/`.card`/`.rail`/`.rail-wrap` used by the catalog above, wired to the same
   `handleCardEnter`/`handleCardTap`/hover-portal/mobile-sheet — "similar games" cards now behave
   identically to catalog cards instead of being inert.

4. **A silent CSS class collision on `.chip` — the most serious drift found.** 007's shell already
   defines `.chip` for the mobile category-filter row (`border-radius: full; padding: 6px 14px;
   background: var(--color-bg); color: var(--color-text)`). 005's "más información" section
   *independently* defines its own `.chip`/`.chip.tag` for mechanic/theme tags, with different values
   (`padding: 4px 10px`, `background: var(--color-surface)`, `color: var(--color-text-muted)`).
   Composed on one page as two bare `.chip { }` rules, CSS resolves by source order at equal
   specificity — whichever rule's `<style>` block appears later would have silently won for *every*
   `.chip` on the page, breaking either the mobile filter row or the mechanic/theme tags with no
   error, only a wrong-looking element. Fixed: renamed 005's chips to `.info-chip`/`.info-chip.tag`
   (and `.chip-row` to `.info-chip-row`) — a real bug, not a hypothetical one, exactly the class this
   whole composing exercise exists to catch.

5. **Two carousels defined the same global JS function names with incompatible signatures.** 004's
   about-page band carousel and 005's detail-page masthead carousel both define global
   `carouselShow`/`carouselStep`/`carouselGoTo` — but with different signatures: 004's take an
   element argument (`carouselShow(el, index)`, generic/reusable across all three about-page bands),
   005's took none (`carouselShow(index)`, closing over one module-level `carouselEl`/`carouselIndex`
   pair scoped to its single masthead carousel). On one page, plain `function` declarations overwrite
   each other in load order — whichever script block loaded last would silently hijack the other
   carousel's arrow/dot clicks (e.g. clicking an about-page band's arrow could drive the detail page's
   masthead carousel instead, or throw on a null element). Fixed: renamed 005's masthead-carousel
   functions to a `detailCarousel*` prefix (`detailCarouselShow`/`detailCarouselStep`/
   `detailCarouselGoTo`/`setupDetailCarouselDots`) and updated its `onclick` handlers; 004's already-
   generic, already-parameterized functions needed no change.

6. **Detail-page scroll listeners/IntersectionObservers keep running while `#page-detail` is
   `display:none`.** The page-switcher hides pages via CSS, it never unmounts them — so 005's
   `IntersectionObserver`s (watching `#game-identity` and the footer) and scroll listeners for the
   mobile sticky CTA bar / game-identity bar keep firing regardless of which page is active. Switching
   away from Detalle and back could leave stale `is-cta-parked`/`is-hidden`/`is-visible` state from
   whatever scroll position was last observed. This is a sketch-page-switcher-only artifact (the real
   app has separate LiveView routes, not a single-page toggle, so it won't reproduce in production)
   but was still visibly wrong in the demo itself. Fixed with a minimal `resetDetailStickyChrome()`
   hook, called from `showPage()` whenever the detail page becomes active, that forces the sticky
   chrome back to "just landed at the top of the page" state.

**Checked and NOT a problem:** z-index stacking across the modal (100) / lightbox (150) / hover-portal
(500) / sheet-backdrop (600) / mobile-sheet (601) / share-toast (200) — no numeric collisions,
confirmed by reading every declaration rather than assuming.

**Observed but not fixed (out of scope for this pass):** the catalog card's difficulty indicator
(`.difficulty`/`.dot`/`.dot.filled`) and the detail page's pill difficulty indicator
(`.pk-difficulty`/`.pk-difficulty-dot`/`.pk-difficulty-dot.is-filled`) are the same visual widget
under two different class vocabularies — 005's own comments confirm the *values* were deliberately
byte-matched against 002's real component, so there's no visible bug today, but it's the same
duplicate-declaration shape as finding #2 and could drift on a future edit to either one. Left alone
here since resolving it means touching 005's own file, which this sketch's scope (compose, don't
redesign) doesn't cover — flagged for a future pass. Same observation applies to `.pill`/`.pk-pill`.

## What to Look For
- Switch Catálogo → Detalle → Acerca de several times — does the header read as one adapting
  component, and does the mobile sticky CTA bar/game-identity bar (≤768px) come back in a sane state
  every time you return to Detalle, or does it ever appear stuck/flashing?
- On Detalle, hover a "Juegos similares" card (desktop) — does it get the same hover-portal treatment
  as a catalog card now?
- On Acerca de, click through all three band carousels' arrows — do they still work independently
  after visiting Detalle (which also has a carousel)?
- Open the mobile category-filter chips (Catálogo, ≤480px) and the "más información" mechanic/theme
  chips (Detalle) side by side — do they now look like two intentionally different chip styles, not
  an accidentally-shared one?
