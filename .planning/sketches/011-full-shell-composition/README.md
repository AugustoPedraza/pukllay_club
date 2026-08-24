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

## Round 2: Mobile Round-Trip Fixes (2026-08-20)

User testing at real mobile widths (≤480px) surfaced 6 more real issues — this composition had never
actually been driven at that width before. All fixed:

1. **No way to reach search, filters, or site nav on mobile at all.** `.app-nav .links`/`.search` are
   `display:none` below 480px with nothing replacing them. Added one hamburger button opening one
   drawer (search input + nav links + a "Filtros" trigger) — one entry point, not three separate icon
   buttons crammed into an already-tight header, matching the app's minimal-chrome direction. "Filtros"
   opens a bottom-sheet panel (ported from sketch 008's validated pattern) filtering by Dificultad/
   Duración — the real dataset here has no per-game `mechanics` field, so that dimension isn't offered.
   Filtering is real: cards get tagged `data-weight-label`/`data-max-playtime` at render and a
   `.filtered-out` class hides non-matches live.
2. **No isologo in the header.** 005's own (discarded) header had designed one — grafted onto the real
   `.app-nav .brand` instead of losing it along with the rest of that file.
3. **Footer read as two nested footers on mobile** (a full-bleed purple mission statement + a separate
   utility bar). Flattened to one compact tier on mobile: headline only (no paragraph, no social row),
   straight into the existing utility bar's links/BGG badge/copyright.
4. **About page was pure vertical scroll with no way to jump to a section.** Added a sticky chip-row
   index (reusing `.chip` — same visual language as the catalog's own mobile category row) that
   smooth-scrolls to each band and marks itself active.
5. **The sticky title bar and mobile CTA bar reported "missing" turned out to be a real regression from
   fix #1-#2 above, not a pre-existing bug**: adding the hamburger + isologo made `.app-nav` wrap onto
   a second line at narrow widths (96px tall instead of ~64px) — because `.crumb` (the full breadcrumb,
   showing the entire game title) was never hidden on mobile, the same overflow 005's own header
   already solved once ("Round 32" in its own history) and that fix never carried over when 011
   discarded that header. `.game-sticky-bar`/`.mobile-cta-bar` both assume a fixed 64px header via
   `top: 64px`, so the taller wrapped nav rendered them hidden behind it. Fixed by collapsing `.crumb`
   to a plain "‹ Catálogo" back-link on mobile, same as 005's original fix.
6. **`.game-sticky-bar`'s background was hardcoded `rgba(255,255,255,0.97)`**, not a theme token —
   invisible/washed-out in dark mode. Switched to `color-mix(in srgb, var(--color-bg) 97%, transparent)`,
   matching `.app-nav.scrolled`'s existing pattern.
7. **The sticky title bar's trigger logic used `IntersectionObserver`, silently starved of callbacks
   in a real environment condition** (`document.visibilityState` non-"visible" — backgrounded/
   unfocused window; this is how the bug first surfaced during agent testing, but it's a real class of
   failure, not just a testing artifact — the same throttling applies to real low-power-mode or
   background-tab browsing). Replaced with a plain `scroll`-event listener computing
   `getBoundingClientRect()` directly — no observer dependency, verified working. Applied the same
   change to the footer-parked observer for consistency.
8. **The sticky title bar's `.is-visible` state was never cleared when leaving Detalle for another
   page** (only reset on *entering* Detalle) — since it's a page-independent fixed element, not scoped
   inside `#page-detail`, a scrolled-then-switched-away state bled its "scrolled past the title" bar
   into Catálogo/Acerca de. Fixed: the reset now runs on every `showPage()` call, not just entries into
   Detalle.

## What to Look For (Round 2)
- At ≤480px: open the hamburger drawer, use the search input, tap "Filtros" and apply a Dificultad
  filter — do non-matching catalog cards actually hide?
- On Detalle at ≤480px, scroll down — does the sticky title bar with the game name appear, themed
  correctly in both light and dark? Scroll back up — does it hide again?
- Switch Detalle → Catálogo/Acerca de after scrolling — does the sticky title bar disappear, or does
  it linger on the wrong page?
- On Acerca de, use the section-index chips to jump between bands — does the target land below the
  sticky index bar, or does the heading get hidden underneath it?

## Round 3: Section Index, Header Rhythm, Footer Balance (2026-08-20)

Follow-up review flagged three more real issues:

1. **The section index "sucked."** Round 2's fix reused `.chip` — the catalog's filled-capsule
   filter/category-chip component — for an entirely different job (in-page reading navigation), and
   items ran left-aligned/scrollable rather than fitting the row, both contributing to the "unbalanced"
   read. Replaced with a dedicated editorial anchor-tab pattern: no fill, underline-on-active, evenly
   distributed (`flex:1` each, capped to a 640px centered row) — the standard for in-page section nav on
   long-form content, distinct from the catalog's own button vocabulary. Since the page already has
   carousel imagery per band, each tab reuses that section's own carousel icon (🎯/🧩/🎲, plus 💬 for
   FAQ which has no carousel) as a small visual anchor instead of relying on text alone.
2. **"Acerca de" next to the isologo broke the header's rhythm.** It lived in its own `.quiet-label`
   component — a bare label floating right after the brand block, different styling from how the detail
   page identifies its own page (a proper `.crumb` breadcrumb). Unified both non-catalog header states
   onto the same `.crumb` component: About now reads "Catálogo / Acerca de", matching the exact rhythm
   already established for Detalle instead of inventing a second, competing pattern next to the logo.
   Fixing this exposed a real layout bug: the wordmark itself ("PUKLLAY CLUB" in Bebas Neue at 1.5rem)
   is ~190px wide on its own — Round 2 only ever hid the *tagline*, not the wordmark — which combined
   with the hamburger + theme-toggle left the new About crumb almost no room; it rendered at
   `width: 0` (invisible, not just truncated). Fixed by also shrinking the wordmark font-size on
   mobile, the standard move (shrink the mark, don't just drop secondary text).
3. **Footer distribution/balance was broken on mobile**: Round 2's fix centered the mission-band
   headline but left the utility-bar below it `flex-start` (left-aligned, ragged) — two different
   alignments stacked on each other reads as unbalanced regardless of either one's own correctness.
   Standard minimal mobile-footer pattern instead: one alignment for the whole block (centered), link
   row and meta row (BGG badge + copyright) separated by a plain divider rather than implied by
   whitespace, matching how the rest of the footer already groups content.

Verified via a temporary unconditional style injection standing in for the ≤480px media query (this
review session's browser tooling could not obtain a genuinely narrow real viewport — window-resize
calls did not take effect on the underlying display) — same computed CSS the real media query applies,
confirmed live: About header now reads "‹ Catálogo" correctly (not width:0), section-index tabs render
evenly spaced with the active underline, and the footer renders as one consistently centered block.

## What to Look For (Round 3)
- On Acerca de at desktop width, does "Catálogo / Acerca de" read as the same pattern as Detalle's own
  breadcrumb, not a separate "page label" floating near the logo?
- Do the section-index tabs (Misión/Cómo funciona/El club/FAQ) read as in-page navigation, not as
  another set of catalog filter chips?
- At ≤480px, is the collapsed "‹ Catálogo" back-link actually visible next to the theme toggle, or does
  it disappear again (check after any future header-content addition — this is a `width:0` failure
  mode, not just visually cramped)?
- Scroll to the footer at ≤480px — does everything share one alignment, with a clear divider between
  the link row and the BGG badge/copyright row?

## Round 4: Header/Footer Rebalance + About Page Rebuild (2026-08-20)

Round 3 patched the about-page section index, header crumb, and footer mobile alignment, but the
underlying complaint persisted: the about page still "broke rhythm" and the header/footer still didn't
read as balanced. This round diagnosed and rebuilt the actual structures, not just their symptoms.
Three directions were confirmed with the user up front (each had 2 alternatives considered and
rejected — see the options each question offered):

1. **About page — app-native rebuild.** The real problem wasn't the section-index (fixed in Round 3) —
   it was that "Misión", "Cómo funciona", and "El club" were three *structurally identical* text +
   gradient-carousel bands, just mirrored left/right. Same shape repeated 3x reads as flat, not
   editorial, no matter how good the index nav is. Rebuilt with four genuinely different shapes reusing
   the site's own component vocabulary instead of a marketing-template pattern unique to this page:
   - **Misión** → a centered full-width statement (`.about-statement`), not a second copy of the band
     shape.
   - **Cómo funciona** → three numbered step-cards (`.step-card`, reusing `--radius-md`/`--shadow-sm`,
     the same surface/radius/shadow vocabulary real cards use) instead of a text+carousel band.
   - **El club** → keeps the one text+visual band (so the page still has one "editorial" beat among
     four), but its visual is now a single static image-card, not an arrow/dot carousel widget that
     only ever existed on this one page.
   - **FAQ** → a real accordion (`.accordion`/`.accordion-item`, one item open at a time,
     `toggleFaqAccordion()`) instead of a bare `<dl>` list.
   Net effect: zero `.band-carousel` instances left on the about page (all three were removed, not
   just re-skinned) — the now-dead `setupCarousel`/`carouselShow`/`carouselStep`/`carouselGoTo`
   functions were deleted from the JS entirely rather than left unused.
2. **Header — two balanced clusters.** Diagnosed the actual cause: `.links` had `flex:1`, so it grew to
   consume all remaining space in the row, but its `<a>` children still left-aligned inside that grown
   box — the empty space landed as a big dead gap *after* the last link and *before* the search box,
   not evenly distributed. Fixed with three changes: (a) `.links` is now `flex:0 0 auto` (natural
   width, no longer swallowing space it doesn't visually use); (b) `.search` now grows itself
   (`flex:1 1 auto; max-width:360px; margin-left:auto`) to actually fill part of that gap instead of
   sitting as a static 220px chip past a void; (c) all header content is wrapped in a new
   `.app-nav-inner` (`max-width:1280px; margin:0 auto`) so the remaining gap is capped on ultra-wide
   viewports instead of growing unbounded — the sticky/background `.app-nav` itself stays full-bleed.
   Live-measured at a forced 1280px width (this session's browser tooling still can't get a real wide
   viewport — see Round 3's note, same limitation): brand+links cluster spans 32–727px (695px), search
   grows to its full 360px cap, gap between the two clusters is 93px — a single contained gap between
   two intentional clusters, not the several-hundred-pixel void the flex:1 links box produced before.
3. **Footer — single unified footer.** Replaced the two-tier `footer-c` (a full-bleed colored
   `.mission-band` at `--space-8` padding stacked directly on a much thinner plain `.utility-bar` — two
   mismatched visual weights read as two footers, not one) with `footer-d`: one consistent-weight,
   single-background multi-column footer (Airbnb/Netflix pattern) — a brand+mission column (same copy
   the old mission-band carried, at normal surface weight instead of a heavy colored block) alongside
   two link columns (`Explorar`, `Club`), then one thin divided `.footer-bottom` row for the
   compliance-required BGG badge + copyright. Live-measured at forced 1280px width (mobile media query
   for the grid still applies at this session's real 335px viewport, so the 3-column rule was
   temporarily forced to confirm the desktop grid computes correctly): brand column 481px, two link
   columns 344px each, evenly gapped — confirms the grid math holds, not just the mobile single-column
   fallback already screenshotted live.

**Real bug found and fixed along the way (not part of the ask, but collided directly with the header
area under rework):** the mobile sticky game-title bar (`#game-sticky-bar`) has a global `scroll`
listener that read `#game-identity`'s `getBoundingClientRect()` to decide when to appear — but
`#game-identity` lives inside `#page-detail`, which the page-switcher hides via `display:none` rather
than unmounting. A hidden element's bounding rect is always `(0,0,0,0)`, so `bottom < 64` was trivially
**true** the instant the user scrolled at all on Catálogo or Acerca de — the sticky bar showed
"Terraforming Mars: Ares Expedition" over pages that have nothing to do with it. Round 2's
`resetDetailStickyChrome()` only patched this at the instant of a page switch; the very next scroll on
the new page recomputed it wrong again. Live-verified via scripted repro (`showPage('about')` +
scroll + dispatch — see below) before and after. Fixed by gating on `identity.offsetParent !== null`
(null exactly when an ancestor is `display:none`) before trusting the rect — confirmed via scripted
repro that Catálogo/Acerca de now never show `is-visible` on scroll, while Detalle still shows/hides it
correctly at the right scroll thresholds and still hides near the footer.

Verified live (this session's browser tooling still cannot get a real wide/narrow viewport via
resize — same limitation Round 3 hit — so desktop-width claims above used the same technique Round 3
validated: forcing the relevant CSS directly and reading real computed `getBoundingClientRect()`/
`getComputedStyle()` values rather than trusting a screenshot at the wrong width). At the real native
mobile viewport (no forcing needed): about-page statement/steps/band/accordion all render and the
accordion toggle works (verified by clicking); the footer's single-column mobile stack renders
correctly end to end.

## What to Look For (Round 4)
- On Acerca de, do Misión (statement), Cómo funciona (step-cards), El club (band), and FAQ (accordion)
  read as four different paced sections, not the same block shape repeated?
- Click through the FAQ accordion — does only one item stay open at a time, with the caret rotating?
- At desktop width, does the header's search bar visibly grow to help fill the space between the nav
  links and the theme toggle, rather than sitting as a small box past an empty gap?
- At desktop width, does the footer read as one consistent block (brand+mission, two link columns, a
  thin divided bottom bar), not a heavy colored band over a thin bar?
- Scroll on Catálogo or Acerca de — does the mobile sticky game-title bar stay hidden (it no longer
  should ever appear outside Detalle)?

## Round 5: Real Desktop Feedback — Content-Width Alignment, Footer Trim, Real Icons (2026-08-20)

Round 4's desktop claims were verified via forced computed-style measurements, because this session's
own browser tooling could not reach a real wide viewport (documented limitation, carried since Round
3). The user then supplied real desktop screenshots (a genuinely wide monitor) and found three things
that measurement-only verification had missed:

1. **Header/footer content width was capped at 1280px (Round 4), but nothing else was — so the catalog
   rail visibly overflowed past both.** `main.catalog-main`/`.row-header`/`.rail-wrap` (catalog shelves)
   and `.pk-row-header`/`#similar-games` (detail's "Juegos similares") had only `padding: 0 var(--space-6)`,
   no `max-width` — full-bleed on any viewport, however wide. Once Round 4 capped the header/footer to
   1280px, the previously-consistent "everything is full-bleed" page broke: header/footer edges now sat
   well inside the catalog rail's edges on a wide monitor, which is exactly what the screenshots showed
   (the card rail extending well past the header's hexagon logo and past the footer's brand mark).
   Fixed by giving `.row-header`, `.rail-wrap`, and `.pk-row-header` the same `max-width:1280px;
   margin:0 auto` recipe as `.app-nav-inner`/`.footer-grid` — confirmed via `getBoundingClientRect()`
   this time (not just computed max-width) that all five now share the exact same `0→1280` box.
   Also found and fixed a second, smaller version of the same bug: `#similar-games`'s own inline
   `padding:0 var(--space-6)` was stacking on top of `.rail-wrap`'s *own* identical padding (64px total
   gutter instead of 32px) — removed the redundant inline style now that `.pk-row-header`/`.rail-wrap`
   carry it correctly themselves.
   A second, more subtle version of the same class of bug turned up in the footer itself: `.footer-d`
   had its own horizontal padding *outside* `.footer-grid`'s max-width box, double-insetting the footer
   content 32px further in than the header/catalog's flush `0→1280` edge — invisible until measured
   with real rects, not just `getComputedStyle` on `max-width`. Fixed by moving the horizontal padding
   onto `.footer-grid`/`.footer-bottom` themselves (same "padding lives inside the max-width box, not
   on a wrapper around it" rule now applied everywhere).
2. **Footer text was redundant with the header.** The "Explorar" footer column
   (Catálogo/Acerca de/Para empezar/Nivel experto) was a straight duplicate of the header's own nav
   links, and the brand paragraph repeated the hero/header's own pitch in full-sentence form. Cut
   entirely: the footer now carries only what the header *doesn't* — a one-line tagline, social links,
   and a "Club" column (FAQ/Contacto/Juntadas, none of which exist in the header nav). Dropping a whole
   column while keeping the outer box at the same 1280px width would have recreated the Round 4 header
   bug (content hugging one side, big gap to the other) if left as a `grid-template-columns: 1.4fr 1fr
   1fr` stretch — switched `.footer-grid` from a full-width grid to natural-width flex items
   (`.footer-brand { flex: 0 1 320px }`, `.footer-col { flex: 0 0 auto }`) so the now-lighter content
   sits close together on the left with open space to the right, rather than being force-stretched
   across the full capped width.
3. **Social icons were "IG"/"WA"/"DC" text-letter badges, not real icons.** Replaced with minimal
   stroke/line SVG glyphs (Instagram, WhatsApp, Discord) in the same 32px circle chrome, using
   `currentColor` so the existing hover-recolor (muted → primary background, white icon) keeps working
   without any extra CSS.

Verified live at a genuinely wide viewport this time (1920px — this session's browser tooling reached
one for the first time; earlier rounds' "can't get a real wide viewport" limitation did not reproduce
here) — screenshotted the catalog, detail, and about pages and confirmed by eye that the header logo,
catalog rail cards, and footer brand mark all sit at the same left edge scrolling down the page, the
footer's two content clusters sit close together with no dead gap, and the new social icons render as
distinct minimal glyphs, not blank/broken.

## What to Look For (Round 5)
- At a wide desktop width, scroll down Catálogo — do the header logo, the shelf cards, and the footer
  brand mark all line up on the same left edge?
- Does the footer read as noticeably lighter/shorter than before, with no text that just repeats the
  header's own nav links?
- Do the three footer social icons look like real minimal icons (camera-square, speech-bubble,
  rounded-rect-with-dots), not text initials?
- On Detalle, does "Juegos similares" also align to the same left edge as the header/catalog above it?

## Round 6: Header Nav Rename, Single-Row Minimal Footer (2026-08-20)

Two more rounds of direct user feedback, both scoped and applied without new variants (the direction
was explicit, not exploratory):

1. **Header nav labels renamed.** The four `.links`/`.nav-drawer-links` items went from
   Catálogo/Para empezar/Nivel experto/Recién llegados to **Inicio/Para empezar/Novedades/Clásicos**.
   For consistency with this rename, the crumb back-links (`.crumb[data-detail-only]`,
   `.crumb[data-about-only]`, which read "Catálogo / {page}" and collapse to "‹ Catálogo" on mobile)
   were updated to "Inicio" too — same destination the nav's first item now names, so both had to agree
   or the shell would drift from itself again (exactly the class of bug this sketch exists to catch).
   Left untouched on purpose: the sketch-only page-switcher control button (dev tooling, not real
   product nav) and the `weightLabel:'Nivel experto'` data field used throughout the real game dataset/
   filters — a coincidental name collision with the old nav label, not the same thing being renamed.
2. **Footer collapsed to one single row, no divider.** Round 5's footer still had two visual pieces (a
   flex row of brand+links, then a separately bordered `.footer-bottom` bar for copyright+BGG). Direct
   feedback: no divider, "Club" links horizontal (they were vertically stacked before), and the BGG
   attribution should read as small print, not a bordered badge competing for attention — while still
   staying legible per the compliance requirement. Rebuilt as one `.footer-row`: brand mark + FAQ/
   Contacto/Juntadas (now inline, not stacked) on the left, social icons + "© 2026 Pukllay Club · datos
   de BoardGameGeek" (plain muted text, underlined link, no box/background/border) on the right — same
   two-cluster `justify-content:space-between` shape that worked for the header in Round 4, avoiding the
   dead-gap trap of stretching a full-width grid across lightweight content (the exact mistake Round 5
   had to fix once already). Padding dropped from `space-8/space-4` to a flat `space-4`, and the
   brand-mark/wordmark shrunk slightly — the whole footer is now roughly a third of Round 5's height.
   Also dropped the tagline paragraph entirely (kept in Round 5, cut here per "simplify it even more").

Verified live at a real 1920px viewport (reached for the first time this session — see Round 5) for the
desktop row, and via a forced-mobile style override (this session's `resize_window` still does not
change the actual viewport — same limitation noted every round since Round 3) for the stacked mobile
layout and the drawer's renamed links.

## What to Look For (Round 6)
- Does the header's first nav item read "Inicio", and does the "‹ Catálogo"/"Catálogo / …" crumb now
  say "Inicio" too, everywhere it appears?
- Does the footer read as one single block with no border/line splitting it into two pieces?
- Are FAQ/Contacto/Juntadas laid out horizontally, not stacked?
- Does "datos de BoardGameGeek" read as quiet small print next to the copyright, not a bordered badge?
- Is the footer noticeably shorter/less tall than before?

## Round 7: Nav Only Where It Applies, Real "Go Home", Catalog's Own Shelf Index (2026-08-20)

Follow-up to Round 6: renaming the nav to Inicio/Para empezar/Novedades/Clásicos exposed a deeper
problem, not just a wording one — three of those four labels are catalog shelf shortcuts, not site
sections, so pairing them with a game title in the Detalle crumb ("Inicio / Terraforming Mars: Ares
Expedition" would have looked fine, but the *old* four-item nav sitting above a single-game page never
would have) genuinely didn't make sense. The user's question — "how do I get from Acerca de back to the
catalog?" — also surfaced a real gap: the brand logo (`.brand`) was `href="#"` with no handler, on every
page, so the only way back to Inicio from anywhere was the small "Inicio" text inside the crumb.

Fixed both by splitting two concerns that had been living in one component:

1. **Global chrome now only carries real site-level destinations.** `.links`/`.nav-drawer-links`
   trimmed to Inicio + Acerca de — the two things that exist as actual pages, present identically on
   every page's chrome. The logo is now a real link (`onclick="showPage('catalog')"`, was inert before)
   on every page, so there are two consistent, always-visible ways back to Inicio (logo, and the
   crumb's own "Inicio" segment on Detalle/Acerca de) rather than relying on the crumb alone.
2. **Para empezar/Novedades/Clásicos moved into a new `.catalog-index`** — a page-local shelf-jump
   bar, visible only on Inicio, directly above the shelves. Deliberately reuses the About page's own
   `.about-index` interaction shape (click a tab → smooth-scroll + underline-active, via a new
   `jumpToShelf()` mirroring `jumpToAboutSection()`) for consistency between the two pages' in-page
   navs, but sized/laid out differently on purpose: natural-width tabs with a gap instead of
   `flex:1`-stretched across the box, since 4 tabs evenly stretched across 1280px (vs. about-index's
   640px) would read as oddly sparse. Rather than inventing new labels a second time, it points at the
   catalog's own real `SHELVES` array (`shelf-destacados`/`shelf-hobby`/`shelf-estratega`/`shelf-nuevos`
   — "Destacados del club"/"Descubre el hobby"/"Ingenio estratega"/"Recientemente añadidos") so the tab
   labels are guaranteed to match what's actually on the page below them. Desktop-only (`display:none`
   at ≤480px) — mobile already has its own filter-chip row directly under the header, and the drawer's
   site links cover Inicio/Acerca de; a second sticky chip row would just compete with the first.
3. **Found and fixed a small residual-state bug while testing this live:** since `showPage()` always
   resets scroll to 0, but the new `.catalog-index`'s active-tab class only ever changed on click, using
   the logo/crumb to return to Inicio from a scrolled-away state left the *last-clicked* shelf tab
   highlighted even though the page had visibly reset to the top (Destacados). Fixed by resetting
   `.catalog-index-item.active` to the first tab inside `showPage()` whenever `page === 'catalog'`.

Verified live: clicking a shelf tab smooth-scrolls to the right section with the right tab underlined
(confirmed by screenshot after the scroll animation settled); clicking the logo from Detalle returns to
Inicio; the mobile drawer (forced-mobile override, same limitation on real narrow viewports noted every
round) shows just Inicio/Acerca de; and the tab-reset fix was confirmed with a scripted repro
(click a non-first tab → navigate away → navigate back to catalog → first tab is active again).

## What to Look For (Round 7)
- On Inicio, does clicking each shelf-index tab smoothly scroll to the right shelf with the right tab
  underlined?
- On Detalle and Acerca de, does the header read as just logo + crumb + toggle — no shelf labels that
  don't apply to the current page?
- From Detalle or Acerca de, does clicking the logo return you to Inicio? Does clicking "Inicio" inside
  the crumb also work?
- Back on Inicio after using either of those, is "Destacados del club" the active shelf tab (not
  whatever tab was last clicked before you navigated away)?

## Round 8: Drop the Shelf-Jump Bar, About Gets Nav-Links Not a Crumb (2026-08-20)

Two more pieces of direct feedback on Round 7's work, both scoped and applied without new variants:

1. **`.catalog-index` removed entirely.** It was a second sticky bar pinned directly under the
   already-sticky `.app-nav` — real chrome overload, and unnecessary against this project's own stated
   reference point: Netflix's row-first catalog doesn't have a persistent "jump to row" bar either,
   people just scroll. Removed the HTML block, its CSS (`.catalog-index`/`.catalog-index-item`), the
   `jumpToShelf()` function, and the active-tab-reset logic `showPage()` gained in Round 7 to support
   it. Para empezar/Novedades/Clásicos have no replacement now — same as every other shelf, they're
   reachable by scrolling.
2. **Acerca de's header is now a real `.links` row, not a crumb.** The insight: Detalle's crumb
   ("Inicio / {game}") is a genuine drill-down — catalog → one specific item — but About isn't nested
   under Inicio at all, it's a sibling top-level page. "Inicio / Acerca de" implied a parent/child
   relationship that doesn't exist, which is exactly why it read as disharmonious. Added a second
   `.links[data-about-only]` block (Inicio + Acerca de, with Acerca de marked `.active` instead) and
   removed the `.crumb[data-about-only]` block outright — crumbs stay reserved for Detalle, the one page
   that's actually a drill-down.
3. **Found and fixed a header-balance regression this change would have introduced:** `.links` has no
   flex-grow (Round 4's fix for the opposite problem — the old links element eating space it didn't
   visually use), and About no longer has a crumb (`flex:1`) or search (`flex-grow` to 360px) to consume
   the row's leftover space before the theme toggle — without a fix, the toggle would sit right after
   "Acerca de" with a large dead zone to its right instead of at the row's edge, i.e. a new instance of
   the exact bug Round 4 fixed on Catálogo, this time on Acerca de. Fixed with
   `.app-nav-inner .theme-toggle { margin-left: auto }`, scoped to the real header (not the drawer's
   reused `.theme-toggle` close button, which is already right-aligned by its own
   `justify-content:space-between`) — a no-op on Catálogo/Detalle where search/crumb already consume
   that space, but load-bearing on Acerca de.

**About's actual content** (mission/how-it-works/club/FAQ) is explicitly out of scope for this pass —
flagged by the user as its own future session to redo as a proper landing page, not touched here. This
round only changed how the *shell* (header) treats the About page, not what's on it.

Verified live at a real 1920px viewport: the shelf-jump bar no longer renders on Inicio; Acerca de shows
"Inicio / Acerca de" as two plain nav links (Acerca de underlined-active, not a "/"-separated crumb);
Detalle's crumb is untouched; and `getBoundingClientRect()` confirmed the theme toggle sits flush at the
header's right edge (1525→1561 inside a 313→1593 box) on all three pages, not bunched left on Acerca de.

## What to Look For (Round 8)
- On Inicio, is there only one sticky bar (the header) — no second bar pinned below it?
- On Acerca de, does the header read "Inicio  Acerca de" as two plain nav links (Acerca de underlined),
  not "Inicio / Acerca de" with a separator implying hierarchy?
- On Acerca de at a wide desktop width, does the theme toggle sit at the header's right edge, or is
  there a large gap between "Acerca de" and the toggle?
- On Detalle, is the crumb ("Inicio / {game title}") still exactly as before?

## Round 9: Vocabulary — Ludoteca, Quiénes Somos (2026-08-20)

A naming pass, decided through direct back-and-forth rather than variants — "Catálogo" read
e-commerce, "Inicio" alone didn't carry a name for Detalle's crumb, and "Acerca de" said nothing about
this specific club. Landed on:

- **"Ludoteca"** (real Spanish word for a game/toy lending library) as the name of the catalog
  section — fits the club's actual lending angle far better than "Catálogo," and reads warmer than
  "Colección" (considered and passed over).
- **"Quiénes Somos"** replacing "Acerca de" — "El Club" was rejected as redundant with the "PUKLLAY
  CLUB" wordmark already in the logo; "Nosotros" alone was rejected as too cold.

**Two names on purpose, not a drift.** "Inicio" stays as the nav item's label everywhere (`.links`,
`.nav-drawer-links`) — it's a wayfinding action ("take me home"), not a name, same word implied by
clicking the logo. "Ludoteca" is the actual *name* of that section, used only where a page is naming it
rather than linking to it — right now that's exclusively Detalle's crumb ("Ludoteca / {game}"), since a
breadcrumb literally states what section you drilled in from. This is deliberately different from every
prior round's fix, which was always "stop having two words for the same thing" — here the two words mean
two different things (an action vs. a name), so keeping them distinct is correct, not drift.
"Quiénes Somos" has no such split: it replaced "Acerca de" everywhere it appeared as real product chrome
(both `.links` instances, the mobile drawer).

**Left alone on purpose:** the sketch's own page-switcher dev control (still reads
Catálogo/Detalle/Acerca de) and the JS that matches its button text — established in Round 7 as
meta-tooling, not real product nav, and this round didn't revisit that call. Updated the `<title>` tag
for consistency since it was free. About's own body copy (which still says "catálogo" as a lowercase
common noun in a sentence) was left untouched — that's the page content explicitly deferred to a future
about-page session, not the shell this sketch covers.

Verified live: Inicio's nav unchanged; Detalle's crumb reads "Ludoteca / Terraforming Mars: Ares
Expedition" and its "Ludoteca" link still correctly returns to the catalog (scripted click test); Quiénes
Somos renders with the header balance fix from Round 8 intact; the mobile drawer shows "Inicio / Quiénes
Somos"; and the mobile collapsed crumb reads "‹ Ludoteca" at a real width (62px), not the `width:0`
failure mode this project has hit before — an early manual test run without the full mobile CSS override
briefly showed width:0, which turned out to be a test-script artifact (missing `.app-nav-inner` padding
override), not a real regression, confirmed by rerunning with the complete override.

## What to Look For (Round 9)
- Does Detalle's crumb now read "Ludoteca / {game title}" instead of "Inicio / {game title}"?
- Does the nav item that takes you home still say "Inicio" everywhere (Inicio's own nav, About's nav,
  the mobile drawer)?
- Does "Quiénes Somos" appear everywhere "Acerca de" used to (both nav-links states, the mobile drawer)?
- On mobile, does the collapsed Detalle crumb read "‹ Ludoteca" clearly, not truncated or invisible?
