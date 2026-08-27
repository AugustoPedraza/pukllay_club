---
name: sketch-findings-pukllay_club
description: Validated design decisions, CSS patterns, and visual direction from sketch experiments. Auto-loaded during UI implementation on pukllay_club.
---

<context>
## Project: pukllay_club

Rework of the already-shipped Phase 1 catalog browse screen (approved brand-locked UI-SPEC, live
and UAT-verified — not greenfield). The original complaint: card hierarchy/rhythm was broken
(title, weight badge, editorial tags, and mechanic chips crammed into one dense stack), and the
carousel rows read as one continuous scrollable grid rather than distinct Netflix-style shelves.

Direction: poster-forward, human-first (teach through plain Spanish, not hobbyist jargon), riffing
on Netflix's TV/web catalog pattern — section/row name + poster carry the resting visual weight,
secondary detail (players, playtime, difficulty, one editorial tag, CTA) lives behind a hover/tap
interaction rather than being permanently visible on a dense card.

Extended outward from the browse screen to the rest of the site: a shared page shell (header +
footer) that adapts across the catalog, the game detail page (`/juegos/:id`), and a new static
"about" page — the detail page itself (desktop buy-box, mobile sticky chrome, reservation flow),
and the about page's content structure.

Reference points: Airbnb-style card grid (big image, minimal chrome), Netflix web/SmartTV catalog
(row-first navigation, poster-primary cards, focus/hover expand-to-reveal-details), Amazon/Airbnb/
Booking.com mobile product pages (sticky bottom action bar, buy-box pattern).

Sketch sessions wrapped: 2026-08-19 (sketches 001–002), 2026-08-20 (sketches 003–005),
2026-08-20 continued (sketches 006, 007 partial, 009, 011 — the shell went through 9 real revision
rounds; see `references/page-shell.md`, which now supersedes the original sketch 003 design entirely),
2026-08-24 (sketches 008, 012–015, 017–026 — filter/search, header/nav/drawer, and carousel-native-
feel groups; 016 excluded, no confirmed winner), 2026-08-26 (sketches 027–031 — Phase 01.2
UAT gap-closure round: buy-box panel boundary, mobile CTA bar balance, an active-filters chip row
that's not yet built, a replacement for the still-unbranded stock connection-lost banner, and the
similar-games shelf's sparse-pool fallback), 2026-08-27 (sketches 032–035 — Phase 01.2 UAT
gap-closure round 2, a second UAT pass over the same masthead/detail area after round 1 shipped:
masthead facts-pill/CTA placement + shell-width fix, a dark-theme lightbox contrast bug + nav/
motion polish, redundant weight-band info + chip contrast cleanup, and de-bugged section spacing),
2026-08-27 continued (sketches 036–038 — Phase 01.2 UAT gap-closure round 3, a third UAT pass:
a new cross-cutting pill/chip design-system unification (036, 5 rounds — the round-2 masthead/chip
fixes had each been styled independently, with no shared base across the five real pill/chip
surfaces in the app), a further mobile masthead grouping revision (037, proximity-only won over
032's panel-based grouping), and the lightbox arrow-anchoring question 033 had left explicitly
open (038, resolved: anchor to the shell width, not the viewport))

**Note on this wrap-up round:** most of the Filter & Search and Header/Navigation/Drawer sketches
turned out to already be implemented in production by the time this wrap-up ran — a separate
implementation stream (quick tasks, debug sessions) had shipped and, in at least one case (the
"Sumate" CTA's scope — see `header-navigation-drawer.md`), *revised* what a sketch's own README
records as its winner. Where that happened, the reference files below document the real shipped
state and flag the drift explicitly, rather than repeating the sketch's now-stale claim. The
carousel group had a similar but narrower drift (arrow behavior) — see `carousel-mechanics.md`.

**Note on the 032–035 round:** several of these sketches actively revise decisions this skill
previously recorded as settled (facts-pill placement, the buy-box's CTA-inside-the-panel rule, a
weight-band badge an earlier round had deliberately kept) — a second real UAT pass on the same
shipped area found the first round's fixes didn't fully land. `detail-page-layout.md` flags each
revision explicitly against the text it supersedes, rather than silently overwriting it.
</context>

<design_direction>
## Overall Direction

Full-bleed, edge-fade Netflix-style shelves with a real sticky nav (desktop) / category-chip row
(mobile) for navigation. Cards are deliberately minimal at rest — poster + single-line title only,
no metadata — with all secondary detail (players, playtime, a beginner-legible difficulty
indicator, one editorial tag, CTA) revealed through interaction: a fixed-size, fixed-content
preview that pops forward on desktop hover (outside the scrolling rail, to sidestep a real CSS
overflow-clipping bug), and a full-screen bottom sheet on mobile tap.

The single most load-bearing principle across both sketches: **when two surfaces are meant to look
the same, give them one shared CSS class per field — never two independently-declared rules with
matching values.** Every real bug found during iteration (misaligned nav padding, divergent title/
description font-sizes, divergent poster aspect-ratios, the mobile "broken" expand) traced back to
either independently-declared "matching" values drifting apart, or a panel escaping/being clipped
by a scrolling container's implied overflow behavior.

Palette, typography, and spacing tokens: `sources/themes/default.css` (mirrors the real brand
tokens in `assets/css/app.css` / 01-UI-SPEC.md — Bebas Neue display + Inter body, the brand
purple/lavender palette, 4px-multiple spacing scale). This file also now carries a **real light/dark
mode mechanism**, not just a light palette: `:root` is light, `@media (prefers-color-scheme: dark)`
overrides to a dark purple palette unless an explicit `[data-theme="light"]` opts back out, and
`[data-theme="dark"]` forces dark regardless of system preference — "data-theme wins" in both
directions, driven by `document.documentElement.dataset.theme` from a real toggle button (see
`page-shell.md`'s `.theme-toggle`). Motion tokens (`--duration-*`/`--ease-*`) are validated, not
incidental — see `references/motion-system.md`.

Three more load-bearing principles emerged from the shell/detail/about sketches:

- **Cap every section of a page to the same content max-width, with padding on the same element as
  the max-width — never on a wrapper around it.** Capping only the header/footer while leaving page
  content uncapped (or vice versa) is a real bug this project hit three times: once between the
  shell and the catalog rail, once inside the footer's own markup, and once more when the detail
  page's masthead was given its own independent (narrower) width token instead of sharing the
  shell's. See `page-shell.md`'s "content-width alignment" note and `detail-page-layout.md`'s
  masthead-width fix (sketch 032).

- **Prefer `position: sticky` over `position: fixed` whenever the element has a natural container
  boundary to stop at** (a sidebar beside scrolling content) — it un-sticks for free at the end of
  that container, no JS needed. For a page-spanning element with no natural containing block (e.g. a
  mobile action bar that needs to "park" at the real `<footer>`), reach for `fixed` + a plain
  `scroll` listener checking `boundaryEl.getBoundingClientRect()` — **not** `IntersectionObserver`.
  Superseded guidance: an earlier session recommended `IntersectionObserver` here; sketch 011 found
  Chrome throttles/suspends its callbacks whenever `document.visibilityState` isn't `"visible"`
  (backgrounded window, some automation contexts), which silently broke exactly this pattern. See
  `detail-page-mobile-interaction.md` for the corrected implementation. If the boundary/trigger
  element isn't guaranteed mounted, also guard the rect read with `el.offsetParent !== null` —
  a hidden element's rect is always `(0,0,0,0)`, which can satisfy a threshold check that isn't
  actually true.
- **Equal-specificity CSS rules resolve by source order, not by which condition is "more specific"
  feeling** — a base rule and its `@media` override at the same specificity silently pick whichever
  is declared later in the file, regardless of which media query actually matches. Caused a real,
  multi-round bug (a mobile CTA bar was `display: none` at every width for several rounds). Verify
  cascade order by reading literal source-line order when two rules target the same property at the
  same specificity, not by guessing from a screenshot.
</design_direction>

<findings_index>
## Design Areas

| Area | Reference | Key Decision |
|------|-----------|--------------|
| Layout & Navigation | references/layout-navigation.md | Full-bleed edge-fade shelves + aligned sticky nav; mobile gets a category-chip row instead of nav links |
| Card & Preview Interaction | references/card-interaction.md | Minimal resting card (poster + title only); fixed-size hover-portal (desktop) / full-screen sheet (mobile) rendered outside the scrolling rail, sharing identical CSS classes for every field |
| Page Shell (Header + Footer) | references/page-shell.md | One header component with 3 states (nav-links / breadcrumb / nav-links, not 3 headers); crumbs reserved for genuine drill-downs only; single-row footer, no divider; "Inicio" (nav action) vs. "Ludoteca" (section name) kept deliberately distinct; every section capped to the same 1280px content width as the header |
| About Page Content | references/about-page-content.md | Alternating tinted/untinted bands, each with a working image carousel instead of a static hero; FAQ as a closing band, not an accordion |
| Detail Page — Layout & Content | references/detail-page-layout.md | Desktop buy-box (sticky image) beside a scrolling reading column, no accordion; ficha técnica as a 2-col grid; every field grounded in the real schema including its gaps; "Juegos similares" shelf reuses the real home-page carousel component. Gap-closure round 2 (sketch 032) revises the buy-box: CTA now lives *outside* the poster's bordered panel, not inside it; pills moved from an overlay/inline-with-title placement to a plain row above the poster; masthead width now matches the header/footer shell (1280px, not a separate 1100px cap). Also: redundant weight-band badge+description removed (034), chip contrast fixed (034), section spacing de-bugged to a uniform 24px (035). Gap-closure round 3 (sketch 037): mobile grouping resolved as proximity-only (no shared container) + compacted dot spacing + fixed a panel-padding margin mismatch |
| Detail Page — Mobile & Interaction Patterns | references/detail-page-mobile-interaction.md | Mobile CTA bar hides while scrolling, parks at the footer; sticky title-echo bar with bounce-to-top — both driven by a plain `scroll` listener + `getBoundingClientRect()`, not `IntersectionObserver` (throttles in a backgrounded tab); lightbox/carousel sync; WhatsApp reservation flow. Gap-closure round 1 (028): the bar's reserve/share controls stack vertically instead of sharing one row, content caps to the shared shell width instead of stretching edge-to-edge. Gap-closure round 2 (033): fixed a dark-theme lightbox contrast bug (backdrop was built from a text-color token, not a background one), added prev/next nav + keyboard arrows, soft fade/scale-in open-close transition. Gap-closure round 3 (038): resolved 033's leftover open question — lightbox photo + nav arrows now anchor to the shared shell content width, not the raw viewport; fixed a mobile chevron z-index bug |
| Component System — Pills & Chips | references/pills-chips.md | Cross-cutting (facts pills, Mecánicas/Temáticas, editorial tags, catalog active-filters, filter-modal chips): unify by interactivity role, not content type — informational pills render flat (no chrome, middot-separated), interactive chips keep an always-visible border + 44px touch height + `:active` tap-press feedback (the Material/Airbnb "filter chip" pattern for signaling tappability with no hover state) |
| Motion System | references/motion-system.md | Validated timing: 100/180/280ms, no-overshoot soft ease-out, `-3px` hover-lift — faster and smaller than every tested alternative, already live in the shared theme |
| Empty / Loading / Error States | references/empty-loading-error-states.md | Flat gray skeletons (no shimmer), terse plain-Spanish copy, one action per state — illustrated/warm treatment tried and rejected as trying too hard for a low-stakes moment |
| Filter & Search | references/filter-search.md | Already shipped: centered modal (desktop) / bottom sheet (mobile), always-visible primary chip clusters in cards, no age filter, editorial-tags group deliberately cut. Gap-closure addition (not yet built): an active-filters chip row inline with the "Resultados" heading, lighter accent-tint chips — never reuse the modal's own solid-filled `.chip.active` for this row. Chip visual treatment itself is now unified with the rest of the app's pills/chips — see `pills-chips.md` |
| Connection Feedback | references/connection-feedback.md | Not yet built: replaces the stock, unbranded, English `phx.new` connection-lost toast with an on-brand, centered, Spanish inline bar under the header, using the accent tint rather than danger-red |
| Header, Navigation & Drawer | references/header-navigation-drawer.md | Already shipped: CTA lives on About-page hero only (NOT persistent — supersedes 013/017's recorded winner), bare-icon `sr-only`-labeled theme toggle, underline active-nav, search-icon-morph, category mega-menu, icon-only drawer bottom block |
| Carousel Mechanics — Native Feel | references/carousel-mechanics.md | Free-momentum scroll + no position indicator already shipped; edge-overlay pointer-fine-gated arrows approved but not yet built (relocates from today's header-embedded circular buttons); shimmer scoped to filter-repopulation is new surface area, distinct from the flat full-page skeleton |

## Theme

The winning theme file is at `sources/themes/default.css`.

## Source Files

Original sketch HTML files are preserved in `sources/` for complete reference — each is a
self-contained, interactive HTML mockup (no build step) that can be opened directly in a browser.
</findings_index>

<metadata>
## Processed Sketches

- 001-shelf-structure
- 002-card-hierarchy
- 003-page-shell
- 004-about-page
- 005-detail-page
- 006-motion-system
- 007-composed-catalog-page (partial — card/rail sizing correction only; shell findings superseded by 011)
- 009-empty-loading-error-states
- 011-full-shell-composition (replaces 003's page-shell design entirely)
- 008-filter-search-ui
- 012-filter-modal-in-shell
- 013-header-action-cluster (CTA-scope claim superseded by shipped `sumate_cta/1` — see header-navigation-drawer.md)
- 014-theme-toggle-weight
- 015-active-nav-treatment
- 017-header-composition
- 018-theme-toggle-subtlety
- 019-filter-modal-finish
- 020-catalog-index-row
- 021-mobile-drawer-theme-social
- 022-carousel-arrow-behavior
- 023-carousel-scroll-physics
- 024-row-position-indicator
- 025-carousel-loading-repopulation
- 026-composed-native-carousel
- 027-buybox-panel-boundary
- 028-mobile-cta-balance
- 029-active-filters-chip-row
- 030-connection-lost-banner
- 031-similar-games-fallback
- 032-masthead-facts-placement (revises 005's original facts-pill/buy-box CTA-placement decisions)
- 033-lightbox-contrast
- 034-chip-cleanup
- 035-detail-page-rhythm
- 036-pill-chip-unification (new "Component System — Pills & Chips" area; 5 rounds)
- 037-masthead-grouping (revises 032's masthead grouping treatment; proximity-only won)
- 038-lightbox-shell-width (resolves 033's leftover open question on arrow anchoring)
</metadata>
