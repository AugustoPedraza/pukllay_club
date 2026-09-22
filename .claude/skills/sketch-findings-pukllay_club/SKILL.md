---
name: sketch-findings-pukllay_club
description: Validated design decisions, CSS patterns, and visual direction from sketch experiments, covering both the public site and the staff admin. Auto-loaded during UI implementation on pukllay_club.
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
open (038, resolved: anchor to the shell width, not the viewport)), 2026-08-31 (sketches 039–043 —
Phase 01.3 UAT gap-closure: ficha-técnica creators become navigable pills (039), Mecánicas/
Temáticas absorbed into one fact grid with the section heading dropped (040), site-wide pill-outline
spread that superseded 036's flat-informational/full-fill-selected decisions after finding them
pixel-indistinguishable in the real filter modal (041), editorial-tags placement + divider removal
+ a 27-round chevron/read-more journey now in its own `description-truncation.md` (042), and a
full-page consistency check that found 2 real composition bugs but also found its own lightbox
recomposition was stale against further real-implementation gap-closure work (043)),
2026-09-02 (sketch 044 — post-shipment real-device feedback on the mobile footer: two rounds of
alignment/content-reduction variants rejected as indecisive, resolved once the BGG attribution was
identified as the only actual compliance requirement; mobile footer now carries nothing else,
revising `references/page-shell.md`'s mobile footer section — desktop unaffected), 2026-09-02
continued (sketches 045-049 — a full revision pass over the shipped About page based on real
developer feedback, not a continuation of the original 004 exploration: a scroll-linked header
with an isologo that morphs into the header's own brand mark at the exact geometric crossing point
(045); an auto-advancing photo rail extending the existing carousel mechanism + a revised mobile
hero tagline (046); developer-authored final content-band copy that also caught a real live bug —
the shipped page says "Empezamos en 2024," the real origin is April 2021 (047); a real shared-
class width bug found (`.pk-band-inner` narrower than the shell, affecting every band, not just
FAQ) plus a rebuilt Contacto card with real icons/links/Maps and corrected pricing copy (048); and
a closing-CTA de-duplication plus a real mobile-centering bug fix (049)), 2026-09-07 (sketches 050–051), **2026-09-22 (sketches 052–080 — 29 sketches: dark-mode/palette chain, share card, About mobile CTA, and the whole staff admin surface; see the note below)**

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

**2026-09-22 — the admin surface arrives (sketches 052–080, 29 sketches).** Everything wrapped
before this was the public site. Sketches 059 onward are a **second application** in the same
Phoenix app: the staff admin, used standing at a shelf on a phone, with its own shell, its own
button system and its own composition rules. It is not a smaller version of the public site, and
the areas prefixed `admin-` below should be read as a set.

Its rules, established across 059–080: mobile-first at phone width; **one row anatomy, one field
anatomy, one list label, one component per job** (065's ten rounds of drift-hunting); **a value is
a row that opens a sheet** (d33) and such a row carries **no chevron** (d34); one outline button
system (064's S3 "Contorno", cited as "064 A1" by every later sketch); **status is a dot + text**,
never a pill; and **"la hoja PREPARA, el pie escribe"** (080) — sheets stage edits into a draft, a
fixed footer bar commits. Pages are shaped by what staff actually do, measured against real dev-DB
counts, rather than by the filter-and-table habit (071, 069 and 070 all opened that way).

**Two restarts run through this batch, and neither is visible from the sketch numbers.** 069
replaces everything 065-R8 and 066 drew for estantes (the developer's words were *"let's start over
all of this UI"*); and 071 states that 061 and 063 "predate the estante restart and the Web
redesign, so they are the starting point to question, not the target." 061, 063, 066, 067 and 068
therefore appear only in the **What to Avoid** sections of the files that replaced them.

**Sketch 075 is closed with no winner**, and it still changed the product: the broken-BGG-game
scenario was removed rather than designed for. The 49 games with no/bad BGG id become **drafts, not
deletions** (`.planning/notes/staff-admin-decisions.md`). A draft is not on the web, so d38's
accusation copy *«Se está viendo así en la web»* **must not ship on one** — the single easiest thing
for a build to get wrong here. See `admin-game-editor.md`.

**Caveat that applies to the whole admin set: none of 069–080 is confirmed on a real device.** Every
one of those sketches says so in its own status line; they are decided on measurements taken in
headless Chrome at 375×667 and 360×640.

**Two live staleness bugs were found while wrapping up, not while sketching.** The shipped
`priv/static/images/og-fallback.webp` is baked at `#551670` — the *pre-058* ramp-800 — while the
current `--pk-ramp-800` is `#4A187F`; verified by reading the file's own pixels, and the per-game
card pipeline was updated while the fallback was not (see `share-card.md`). And sketch 054's README
token table is now actively misleading as an implementation input, because 058 rotated the ramp
underneath it — `dark-mode-palette.md` records the resolved end state and says so.

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
| Page Shell (Header + Footer) | references/page-shell.md | One header component with 3 states (nav-links / breadcrumb / nav-links, not 3 headers); crumbs reserved for genuine drill-downs only; single-row footer, no divider (desktop); "Inicio" (nav action) vs. "Ludoteca" (section name) kept deliberately distinct; every section capped to the same 1280px content width as the header; on mobile (≤480px) only, the footer carries nothing but the BGG compliance line (sketch 044) |
| About Page Content | references/about-page-content.md | Alternating tinted/untinted bands, each with a working image carousel instead of a static hero; FAQ as a closing band, not an accordion. **2026-09-02 revision (sketches 045-049) of the SHIPPED page**: scroll-linked header + isologo-morphs-into-header-mark (045); auto-advance photo rail + revised mobile tagline (046); developer-authored copy that fixed a real live bug (page said "2024," real origin is April 2021) (047); real shared-class width bug found (`.pk-band-inner` narrower than the shell, affects every band) + Contacto rebuilt as one card + corrected pricing copy (048); closing-CTA de-duplication + a real mobile-centering bug fix (049). **2026-09-07 revision (sketches 050-051)**: isologo scroll-morph gets a companion wordmark baked into the mark itself, eyebrow synced to the same dock-crossing state (050); full-page CTA rhythm pass — Contacto card chrome dropped everywhere, reach-out links as soft accent chips, Maps thumbnail moved to Juntadas, Cierre full-screen on desktop with one gap-based rhythm, bands alternate plain/tint backgrounds page-wide (051, 14 rounds, 4 real bugs found+fixed) |
| Detail Page — Layout & Content | references/detail-page-layout.md | Desktop buy-box (sticky image) beside a scrolling reading column, no accordion; ficha técnica as a 2-col grid; every field grounded in the real schema including its gaps; "Juegos similares" shelf reuses the real home-page carousel component. Gap-closure round 2 (sketch 032) revises the buy-box: CTA now lives *outside* the poster's bordered panel, not inside it; pills moved from an overlay/inline-with-title placement to a plain row above the poster; masthead width now matches the header/footer shell (1280px, not a separate 1100px cap). Also: redundant weight-band badge+description removed (034), chip contrast fixed (034), section spacing de-bugged to a uniform 24px (035). Gap-closure round 3 (sketch 037): mobile grouping resolved as proximity-only (no shared container) + compacted dot spacing + fixed a panel-padding margin mismatch. Phase 01.3 gap-closure (sketches 039/040/042): creators become navigable outline pills, Edad mínima + fake "Avanzado" heading dropped (039); Mecánicas/Temáticas absorbed into the SAME fact grid, "Sobre el juego" heading dropped entirely (040); editorial hashtags moved to right after the title, the divider removed for good, description now justified (042 — its chevron/read-more pattern has its own file, see below). Consistency-checked full-page composition (sketch 043): confirmed it all holds together, scoped the desktop-standalone-CTA vs. mobile-fixed-CTA-bar so they don't double up — but its lightbox recomposition is stale, see `detail-page-mobile-interaction.md` instead |
| Description Truncation & "Read More" | references/description-truncation.md | 27-round history of a chevron/read-more toggle for the 3-line-clamped description: why it can't nest inside a `-webkit-line-clamp` paragraph (crashes), why proximity fixes alone didn't solve "looks disconnected" (the icon-button chrome itself was the problem), the winning true-inline float technique, and two known issues deferred to real implementation (ink-alignment nudge needs re-tuning against the real font; the float technique can cut text mid-word at some widths — validate against real content before shipping) |
| Detail Page — Mobile & Interaction Patterns | references/detail-page-mobile-interaction.md | Mobile CTA bar hides while scrolling, parks at the footer; sticky title-echo bar with bounce-to-top — both driven by a plain `scroll` listener + `getBoundingClientRect()`, not `IntersectionObserver` (throttles in a backgrounded tab); lightbox/carousel sync; WhatsApp reservation flow. Gap-closure round 1 (028): the bar's reserve/share controls stack vertically instead of sharing one row, content caps to the shared shell width instead of stretching edge-to-edge. Gap-closure round 2 (033): fixed a dark-theme lightbox contrast bug (backdrop was built from a text-color token, not a background one), added prev/next nav + keyboard arrows, soft fade/scale-in open-close transition. Gap-closure round 3 (038): resolved 033's leftover open question — lightbox photo + nav arrows now anchor to the shared shell content width, not the raw viewport; fixed a mobile chevron z-index bug |
| Component System — Pills & Chips | references/pills-chips.md | Cross-cutting (facts pills, Mecánicas/Temáticas, editorial tags, catalog active-filters, filter-modal chips): unify by interactivity role, not content type. **Superseded by sketches 039-041** (later, UAT-validated on this exact content): informational pills are bordered `.pk-pill-outline` (muted text), not the originally-documented flat/borderless/middot shape; selected/active state stays in the outline family (primary border + text, `font-weight: 700`) rather than a full color fill — outline-everywhere was tried first and found to make a selected chip pixel-identical to its unchecked siblings. Interactive chips still keep an always-visible border + 44px touch height + `:active` tap-press feedback |
| Motion System | references/motion-system.md | Validated timing: 100/180/280ms, no-overshoot soft ease-out, `-3px` hover-lift — faster and smaller than every tested alternative, already live in the shared theme |
| Empty / Loading / Error States | references/empty-loading-error-states.md | Flat gray skeletons (no shimmer), terse plain-Spanish copy, one action per state — illustrated/warm treatment tried and rejected as trying too hard for a low-stakes moment |
| Filter & Search | references/filter-search.md | Already shipped: centered modal (desktop) / bottom sheet (mobile), always-visible primary chip clusters in cards, no age filter, editorial-tags group deliberately cut. Gap-closure addition (not yet built): an active-filters chip row inline with the "Resultados" heading, lighter accent-tint chips — never reuse the modal's own solid-filled `.chip.active` for this row. Chip visual treatment itself is now unified with the rest of the app's pills/chips — see `pills-chips.md` |
| Connection Feedback | references/connection-feedback.md | Not yet built: replaces the stock, unbranded, English `phx.new` connection-lost toast with an on-brand, centered, Spanish inline bar under the header, using the accent tint rather than danger-red |
| Header, Navigation & Drawer | references/header-navigation-drawer.md | Already shipped: CTA lives on About-page hero only (NOT persistent — supersedes 013/017's recorded winner), bare-icon `sr-only`-labeled theme toggle, underline active-nav, search-icon-morph, category mega-menu, icon-only drawer bottom block |
| Carousel Mechanics — Native Feel | references/carousel-mechanics.md | Free-momentum scroll + no position indicator already shipped; edge-overlay pointer-fine-gated arrows approved but not yet built (relocates from today's header-embedded circular buttons); shimmer scoped to filter-repopulation is new surface area, distinct from the flat full-page skeleton |
| Dark Mode & Palette | references/dark-mode-palette.md | **Read as one chain, never in isolation**: 054's lifted ladder + 055's text-contrast fix + 056's split-by-role CTA fix + 058's rotation of the whole shared `--pk-ramp-*` to H300. 9 of 054's 13 tokens were overridden — `--color-primary` is now `var(--pk-ramp-600)` = `#7B2DCE`, base-100 `#2E154E`. Sketch 054's own README token table is stale and misleading as an implementation input |
| Share Card (OG fallback) | references/share-card.md | 1200×630 centered stack on ramp-800: isologo-dark 190px, Bebas Neue 68px wordmark, Inter 27px tagline. **Live bug flagged:** the shipped `og-fallback.webp` is still baked at the pre-058 `#551670` while the current ramp-800 is `#4A187F` — the per-game pipeline was updated, the fallback was not |
| About — Mobile CTA | references/about-mobile-cta.md | Full-width flush bar, entry triggered off the existing hero-morph boolean, **never auto-hides**, footer clearance from a live-measured `--pk-about-cta-bar-h`. The anti-pattern is load-bearing: 052's content-sized floating pill was rejected on real-device UAT for covering the footer's "Powered by BGG" line — a defect a scrolling sketch frame cannot surface |
| Admin — Shell & Navigation | references/admin-shell-navigation.md | One header across 6 states, right drawer with a pinned theme block, phone tab bar (Admin·Juegos·Web·Estantes·Perfil), two-step in-sheet logout; plus 065's cross-cutting consistency rules — one row anatomy, one field anatomy, one list label, one counter source, one save bar, one sheet shell. **065's Estantes work (R8/R9/R10) is dead — replaced by 069** |
| Admin — Button System | references/admin-button-system.md | 064 S3 "Contorno" — 44px / 8px radius / 14px-600 / 16px icon, four roles, resolved light+dark hex (dark must swap Principal to `--color-accent-text`: `#7B2DCE` on `#2E154E` is 2.33:1). Cited as "064 A1" by every later admin sketch. **Its "no disabled buttons" rule is in open conflict** with 074/078/079 and with 080's deliberately-disabled fixed-foot `Guardar` — recorded unresolved, not smoothed over |
| Admin — Juegos (list, search, create) | references/admin-juegos.md | Search-first single list, shaped by real dev-DB counts rather than the filter-and-table habit (estado chips would have filtered 435 into 435). 071's d10/11/13/14/15 superseded by its own d17. Create→pending is ONE scenario across 076+077: `+` sheet → "Se abre" → toast «Ver» → the pending sheet speaks alone |
| Admin — Game Editor | references/admin-game-editor.md | The 072→080 chain resolved into one current chrome: bar `‹ · título · ⋮` with the kebab as its **only** control (074's one-CTA slot is gone), body = note → E3 ficha mirror → club fields, fixed foot bar with 064-A1 `Guardar` at natural width, 14px keel, enabled only when dirty. "La hoja PREPARA, el pie escribe". **075 closed: never ship d38's «Se está viendo así en la web» on a draft** |
| Admin — Estantes | references/admin-estantes.md | 069's restart, 68 developer decisions: search → the cover lifted between its neighbours → "+" spots → full-height "¿Dónde va?" → Mover as one transaction. 9 estantes of 46–50 boxes. 067's letter-tile cover fallback and 2-line clamp survived; 066's single-open focus and 068 did not |
| Admin — Web / Destacados | references/admin-web-destacados.md | One page: the destacada rail edited inline, every other home row grouped under "Otras filas"; name-as-sheet-button, "+" in every gap. **070's README is stale on four points** the artefact contradicts (pencil, chevron, separate Filas del inicio page, Quitar confirmation) — the file documents the artefact |

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
- 039-ficha-tecnica-creators
- 040-reading-column-composition (revises 039's own "Sobre el juego" heading within the same round)
- 041-pill-system-outline (supersedes sketch 036's flat-informational + full-fill-selected pill decisions)
- 042-editorial-tags-divider (27 rounds — chevron/read-more pattern synthesized separately into description-truncation.md)
- 043-composed-full-detail-page (consistency check; its lightbox recomposition is stale — see detail-page-mobile-interaction.md instead)
- 044-mobile-footer-balance (mobile-only footer revision, winner H; folded into page-shell.md's footer section)
- 045-about-header-scroll-isologo (winner A3, 180px scroll-linked pin; revises the About page's header behavior only — every other page keeps the always-visible header from page-shell.md)
- 046-about-photo-rail-mobile-hero (winner A, autoplay crossfade+snap extending the shipped carousel; mobile tagline revised)
- 047-about-content-bands (developer-authored final copy; caught and flags a real live bug — "Empezamos en 2024" should be April 2021)
- 048-about-faq-contacto (winner A, confirms existing FAQ color; found the real `.pk-band-inner` width bug affecting every About-page band; Contacto rebuilt as one card)
- 049-about-closing-cta-mobile (winner A, single CTA; found and fixed a real mobile-centering bug on the CTA bar)
- 050-about-morph-companion-text (companion wordmark baked into isologo mark, ~25px; mark anchored in-flow fixing a real grouping bug; eyebrow synced to dock-crossing state; found+fixed a missing-webfont theme bug and a header mark-slot layout bug)
- 051-about-full-page-cta-rhythm (14 rounds; Contacto card chrome dropped at all widths, soft-chip contact links + Facebook, Maps moved to Juntadas, Cierre full-screen desktop + unified rhythm, alternating band backgrounds; found+fixed 4 real bugs including a CSS specificity bug and a silently-dropped text-align rule)
- 052-about-mobile-cta-alternatives (SUPERSEDED by 053 — winner B rejected on real-device UAT; kept as the anti-pattern in about-mobile-cta.md)
- 053-about-mobile-cta-bar-footer-clearance
- 054-dark-mode-color-composition (its README token table is STALE — 058 rotated the ramp underneath it)
- 055-dark-primary-as-text-contrast-fix
- 056-dark-cta-contrast-fix
- 057-og-fallback-share-card (live bug flagged: shipped og-fallback.webp still at the pre-058 colour)
- 058-dark-purple-hue (rotates the shared --pk-ramp-* to H300; overrides 9 of 054's 13 tokens)
- 059-admin-shell
- 060-admin-panel-entries (supersedes 059 on tab names/counts)
- 061-admin-juegos-page (SUPERSEDED by 071 — pre-01.8.2 restart; kept as anti-pattern)
- 062-admin-list-rows
- 063-admin-game-editor (SUPERSEDED by the 072-080 chain — pre-01.8.2 restart; kept as anti-pattern)
- 064-admin-button-system (the canonical admin button; "064 A1" is cited by 074/078/079/080)
- 065-admin-composition (10 rounds, 11 drift bugs — but its R8/R9/R10 Estantes work is DEAD, replaced by 069)
- 066-estante-focus (SUPERSEDED by 069)
- 067-estante-read (SUPERSEDED by 069, but its cover letter-tile + 2-line clamp survived)
- 068-locate-box (winner null; the developer's "start over all of this UI" is what produced 069)
- 069-estantes-ubicar (restart — 68 developer decisions, no variants)
- 070-web-destacados (README stale on four points; the artefact is the record)
- 071-admin-juegos (d10/11/13/14/15 superseded by its own d17)
- 072-admin-game-editor (d33 spine + d34 no-chevron — governs every editable value)
- 073-admin-bgg-state (its r2 action bar superseded by 074/079/080; its d38 accusation copy must NOT ship on a draft)
- 074-admin-header (its one-CTA slot was later removed entirely by 079)
- 075-admin-remedy-dirty (CLOSED, no winner — scenario removed from the product; the 49 broken games become drafts, not deletions)
- 076-admin-create-visibility
- 077-admin-pending-sheet
- 078-admin-publish-gate
- 079-admin-lifecycle
- 080-admin-guardar-fijo (the current editor chrome)
</metadata>
