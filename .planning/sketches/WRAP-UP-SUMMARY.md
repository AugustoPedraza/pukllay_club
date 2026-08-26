# Sketch Wrap-Up Summary

## Session: 2026-08-19

**Sketches processed:** 2
**Design areas:** Layout & Navigation, Card & Preview Interaction
**Skill output:** `./.claude/skills/sketch-findings-pukllay_club/`

## Included Sketches
| # | Name | Winner | Design Area |
|---|------|--------|-------------|
| 001 | shelf-structure | D (Edge-Fade, refined) | Layout & Navigation |
| 002 | card-hierarchy | D (hybrid, pop-forward preview) | Card & Preview Interaction |

## Excluded Sketches
| # | Name | Reason |
|---|------|--------|
| — | — | none |

Note: sketch 003 (motion-system) was proposed during initial decomposition but never built — no
`.planning/sketches/003-*` directory exists, so it isn't part of this wrap-up. It remains an open
item for a future `/gsd-sketch` session if a dedicated motion system is still worth exploring.

## Design Direction
Full-bleed, edge-fade Netflix-style shelves with a real sticky nav (desktop) / category-chip row
(mobile). Cards are minimal at rest (poster + single-line title only); all secondary detail
(players, playtime, a beginner-legible difficulty indicator replacing raw min-age, one editorial
tag, CTA) lives behind interaction — a fixed-size hover-portal on desktop (rendered outside the
scrolling rail to avoid a real CSS overflow-clipping bug) and a full-screen bottom sheet on mobile.

## Key Decisions
- **Layout:** full-bleed rows, edge-fade scroll cue (not hover-only prev/next), nav padding
  strictly matched to row-content padding, mobile category-chip row replacing nav links,
  trailing "Ver todo" tile per shelf, hashtag row titles rendered as plain text.
- **Card:** poster + title only at rest, no metadata; single-line ellipsis title (not multi-line
  clamp — avoids a reserved-space empty-gap problem); title anchored to the poster edge, not
  centered.
- **Interaction:** 300ms hover-intent delay before the desktop preview appears; preview rendered
  through a `position:fixed` portal outside the rail (sidesteps `overflow-x:auto`'s implied
  `overflow-y:auto` clipping); preview sized as a fixed "modal" width, not a multiple of the small
  resting card.
- **Consistency discipline:** every field meant to look identical between the desktop preview and
  the mobile sheet (title, description, facts row, poster aspect-ratio, CTA style) uses one shared
  CSS class — the recurring bug pattern this session was two independently-declared "matching"
  rules quietly drifting apart.
- **Difficulty over age:** raw `min_age` replaced everywhere with a 3-dot difficulty indicator
  (muted color) paired with the existing weight-band label, not a second invented vocabulary.
- **CTA:** secondary/outlined everywhere on this card, not filled — it's a lower-commitment action
  than the interaction that revealed it.

## Open Items Carried Forward
- Whether "Ver detalles" from the mobile sheet should be a real `/juegos/:id` navigation or stay
  an in-page sheet.
- Whether mechanic chips or editorial tags deserve a place in the compact desktop preview
  (currently: no — only the mobile sheet shows the tag; mechanics never appear on the card).
- Touch diagonal-swipe scroll ambiguity on the horizontal rails needs device testing once this
  ships as real Phoenix/LiveView markup (`touch-action: pan-y`/`pan-x` is the standard mitigation).
- The hover-portal positioning logic (`getBoundingClientRect()`-based) should carry directly into
  a colocated LiveView hook, mirroring `carousel_row.ex`'s existing `.CarouselScroll` hook pattern.

---

## Session: 2026-08-20

**Sketches processed:** 3
**Design areas added:** Page Shell (Header + Footer), About Page Content, Detail Page — Layout &
Content, Detail Page — Mobile & Interaction Patterns
**Skill output:** `./.claude/skills/sketch-findings-pukllay_club/` (updated in place)

## Included Sketches
| # | Name | Winner | Design Area |
|---|------|--------|-------------|
| 003 | page-shell | C (Two-Tier Mission Band) | Page Shell (Header + Footer) |
| 004 | about-page | B (Alternating Bands, w/ image carousel) | About Page Content |
| 005 | detail-page | B (36 refinement rounds) | Detail Page — Layout & Content / Mobile & Interaction Patterns |

## Excluded Sketches
| # | Name | Reason |
|---|------|--------|
| — | — | none |

Note: sketch 006 (motion-system) is still only a placeholder row in `MANIFEST.md` — no
`.planning/sketches/006-*` directory exists, so it isn't part of this wrap-up either. Same open
item as before, carried forward again.

## Design Direction
Extended the browse-screen direction outward into a full site shell: one header component with
three states (full nav / breadcrumb / static label) shared across catalog, detail, and about; a
Two-Tier Mission Band footer (persuasion band + utility bar) on every page, carrying a
compliance-required BGG attribution badge; an alternating-band about page built to hold real content
without structural rework later; and a fully designed detail page — desktop buy-box beside a
scrolling reading column, mobile sticky chrome (CTA bar + title-echo bar) that both park at the
footer, and a "Juegos similares" shelf reusing the real home-page carousel component as the page's
exit hook back into browsing.

## Key Decisions
- **Shell:** one adaptive header, not per-page forks; footer splits mission (persuasion) from
  links/badge/copyright (utility) into two visually distinct bands.
- **About:** alternating image+text bands with a real (not static) carousel per band; FAQ as a
  closing band, not an accordion, until there's enough volume to justify hiding it by default.
- **Detail layout:** buy-box pattern (image+CTA as one sticky decision panel) separate from the
  reading column; no accordion — mecánicas/temas/ficha técnica flow inline; every schema gap
  (missing illustrator field, unconfirmed BGG rank, ~9% of catalog missing `bgg_id`) shown
  explicitly rather than faked.
- **Detail mobile:** `position: fixed` CTA bar fakes `position: sticky`'s "unstick at a boundary"
  via `IntersectionObserver` on the real footer, since a page-spanning fixed bar has no natural
  containing block to bound it the way a sidebar does; a "gesture paused" state (scroll-hide) and a
  "content ended" state (footer-park) need independent lifecycles, not one shared class.
- **Reusability over reinvention:** the "Juegos similares" shelf and the desktop sticky poster
  column both deliberately reuse existing real patterns (the home page's `CarouselRow` component;
  native `position: sticky`) instead of building new ones for this one page.
- **Cross-cutting lesson:** equal-specificity CSS rules resolve by source order — caught one real,
  multi-round bug (a mobile bar `display: none` at every width) this way, worth checking first
  whenever a media-query override doesn't seem to be taking effect.

## Open Items Carried Forward
- Sketch 006 (motion-system) — still unbuilt, same as the previous session's note.
- Filter-linked chips/pills throughout the detail page point at real `CatalogLive.Index` query
  params, but URL-persistence round-tripping was never proven — review as link targets/labels only.
- The about page's mission statement appears in both the page's own lead section and the shared
  footer's mission band directly below it — flagged as possibly redundant, not resolved.
- The detail page's sticky title-echo bar and mobile CTA bar were verified extensively in a
  browser-automation tab that stays backgrounded (`document.visibilityState: 'hidden'`), which
  throttles rAF-driven smooth-scroll and IntersectionObserver timing — underlying logic was
  confirmed correct via computed styles and instant (`behavior:'auto'`) scrolling, but the actual
  smooth-animated feel is worth one real-device confirm.
- The real WhatsApp club number is hardcoded in the sketch's reservation flow — must move to
  runtime env config before this becomes real `CatalogLive.Show` code, not copied as a literal.

---

## Session: 2026-08-20 (continued)

**Sketches processed:** 4 (1 partial)
**Design areas added:** Motion System, Empty / Loading / Error States
**Design areas replaced:** Page Shell (Header + Footer) — sketch 011 supersedes sketch 003 entirely
**Skill output:** `./.claude/skills/sketch-findings-pukllay_club/` (updated in place)

## Included Sketches
| # | Name | Winner | Design Area |
|---|------|--------|-------------|
| 006 | motion-system | D (Subtle/Soft synthesis) | Motion System |
| 007 | composed-catalog-page | — (partial) | Card/rail-gap correction folded into Layout & Navigation |
| 009 | empty-loading-error-states | A (Minimal/Utilitarian) | Empty / Loading / Error States |
| 011 | full-shell-composition | — (consistency check, 9 rounds) | Page Shell (Header + Footer) — replaces sketch 003 |

## Excluded Sketches
| # | Name | Reason |
|---|------|--------|
| 008 | filter-search-ui | User: "requires more polishing" — deliberately left off the processed list so a future `/gsd-sketch --wrap-up` reconsiders it once it's had another sketch pass, rather than treating today's "not ready" as a permanent exclusion. |

## Design Direction
This continuation is mostly a **correction and consolidation pass**, not new visual ground: sketch
011 took the already-approved shell (003) and catalog composition (007) through 9 real revision
rounds driven by direct user feedback on the actual composed page — header balance, content-width
alignment across every section (not just the shell), a full footer redesign (two-tier Mission Band →
one undivided row), a deliberate vocabulary pass (Inicio/Ludoteca/Quiénes Somos), and a real
scroll-vs-IntersectionObserver bug fix that also corrected two other reference files' guidance.
006 and 009 are the two new design areas — motion timing and non-happy-path states — both simple,
decisive winners with no multi-round drama.

## Key Decisions
- **Page shell (011, replaces 003):** one header with 3 *states* (nav-links / breadcrumb / nav-links
  again — not nav-links / breadcrumb / static label as originally designed), crumbs reserved for
  genuine drill-downs only (Detalle), a single-row footer with no divider, "Inicio" (nav action) kept
  deliberately distinct from "Ludoteca" (the catalog's actual name, used in the crumb) — two different
  words for two different jobs, not drift. Full detail in `references/page-shell.md`.
- **Content-width alignment (011, cross-cutting):** every page section — not just the header/footer —
  must share the identical `max-width: 1280px; margin: 0 auto` box, with padding living on the same
  element as the max-width rather than a wrapper around it. Caught as a real bug twice: once between
  the shell and the catalog rail, once again inside the footer's own markup.
- **IntersectionObserver → scroll listener (011, corrects 005's original guidance):** Chrome
  throttles/suspends `IntersectionObserver` callbacks in a backgrounded tab, which silently broke
  both the mobile CTA bar's footer-park and the sticky title bar. Both now use a plain `scroll`
  listener + `getBoundingClientRect()`. This correction propagated into `detail-page-layout.md`,
  `detail-page-mobile-interaction.md`, and the top-level `design_direction` principle in SKILL.md —
  all three previously recommended the now-superseded approach.
- **Card/rail sizing (007, folds into `layout-navigation.md`):** the shared rail gap is
  `var(--space-4)` (24px), not `var(--space-3)` (16px) — 001 and 002 had disagreed on this without
  either sketch noticing; 007 caught it composing them together, 011 confirmed it's still the
  shipped value.
- **Motion (006):** 100/180/280ms, no-overshoot soft ease-out, `-3px` hover-lift — already live in
  the shared theme, not just a validated proposal.
- **Empty/loading/error (009):** flat, terse, one action per state — the illustrated/warm alternative
  was rejected as trying too hard for a moment a user wants to get past quickly.
- **Theme file refreshed:** `sources/themes/default.css` was stale (missing the real light/dark
  toggle mechanism and 006's motion tokens) — re-copied from the live sketch theme as part of this
  wrap-up.

## Open Items Carried Forward
- Sketch 008 (filter-search-ui) — excluded this round per direct feedback ("requires more polishing"),
  not added to the processed list. Revisit with a focused polish pass before the next wrap-up.
- About page's own *content* (mission/how-it-works/club/FAQ) was explicitly flagged by the user as
  needing its own dedicated future sketch session — 011 only touched the shell/header around it, not
  the page itself. `about-page-content.md` is unchanged and still reflects sketch 004.
- The about-page's mission-statement redundancy flagged in the previous session (appears in both the
  page's own lead section and the footer) is now moot — the footer's mission paragraph was removed
  entirely in 011's footer redesign.

---

## Session: 2026-08-24

**Sketches processed:** 15 (016 excluded — no confirmed winner)
**Design areas added:** Filter & Search, Header/Navigation & Drawer, Carousel Mechanics — Native Feel
**Skill output:** `./.claude/skills/sketch-findings-pukllay_club/` (updated in place)

## Included Sketches
| # | Name | Winner | Design Area |
|---|------|--------|-------------|
| 008 | filter-search-ui | Round 8 — centered modal, checklist-in-dropdown | Filter & Search |
| 012 | filter-modal-in-shell | consistency check — fixed 1 crash risk | Filter & Search |
| 019 | filter-modal-finish | D — pill chips + accent-card sections | Filter & Search |
| 013 | header-action-cluster | E (scope claim later superseded by shipped code) | Header, Navigation & Drawer |
| 014 | theme-toggle-weight | D | Header, Navigation & Drawer |
| 015 | active-nav-treatment | A | Header, Navigation & Drawer |
| 017 | header-composition | E | Header, Navigation & Drawer |
| 018 | theme-toggle-subtlety | B | Header, Navigation & Drawer |
| 020 | catalog-index-row | C (refined) | Header, Navigation & Drawer |
| 021 | mobile-drawer-theme-social | E1 | Header, Navigation & Drawer |
| 022 | carousel-arrow-behavior | C | Carousel Mechanics — Native Feel |
| 023 | carousel-scroll-physics | B | Carousel Mechanics — Native Feel |
| 024 | row-position-indicator | A | Carousel Mechanics — Native Feel |
| 025 | carousel-loading-repopulation | B | Carousel Mechanics — Native Feel |
| 026 | composed-native-carousel | single composed view | Carousel Mechanics — Native Feel |

## Excluded Sketches
| # | Name | Reason |
|---|------|--------|
| 016 | mobile-nav-scale | No confirmed winner (README frontmatter `winner: null`; MANIFEST only notes "Round 2: C refines B's balance, scale path validated" without a final call). User confirmed excluding rather than locking in an unresolved decision. |

## Design Direction
Two very different kinds of work landed in one wrap-up round. Filter & Search and Header/Navigation
& Drawer (008–021, minus 016) turned out to be **retroactive documentation of already-shipped
production code** — a separate implementation stream (quick tasks, debug sessions) had built and, in
places, further refined these areas after the sketches were drawn, faster than they were wrapped up.
Carousel Mechanics (022–026) is this session's actual new design work: closing the gap between the
shelf-row carousel's current behavior and a genuinely native, Netflix-inspired feel — arrows,
momentum/snap physics, pagination, and loading state — grounded in real research on Netflix's own
pattern and the modern CSS scroll-snap platform, not reinvented from scratch.

**A real grounding check changed the outcome.** Before writing findings into the skill, production
code was checked against every sketch's claims (per explicit user instruction: "base the answers on
what we already have working"). This caught two real discrepancies:
1. Sketch 013/017 both record the "Sumate" CTA as staying persistent site-wide — production's
   `sumate_cta/1` doc comment states this was explicitly superseded later ("the developer's direct,
   twice-repeated instruction"): the CTA now lives only on the About page hero + a mobile CTA bar,
   asserted absent from the header by test.
2. Sketches 001/006 described the carousel's "current shipped" arrow behavior as hover-reveal — a
   separate debug session (G-01-3/G-01-4) had already reworked it to always-visible, header-embedded
   circular buttons (any pointer type) before this sketch session started. Sketch 022's exploration
   and its winner (C — pointer-fine-gated edge-overlay arrows) were reframed as an **approved but
   not-yet-implemented change** against that real baseline, not a restatement of "current" behavior.
   Two of the four carousel sketch conclusions (023's free-momentum physics, 024's no-indicator)
   turned out to already match production exactly — confirmed as correct via code, not proposed.

## Key Decisions
- **Filter & Search (already shipped):** centered modal / bottom sheet, always-visible primary chip
  clusters in cards, no age filter (Nivel substitutes), editorial-tags group deliberately cut pending
  a future presentation decision. See `references/filter-search.md`.
- **Header/Navigation/Drawer (already shipped):** CTA is About-page-hero-only, not persistent — this
  wrap-up's reference file documents the real shipped rule, not sketch 013/017's now-superseded one.
  Bare-icon, `sr-only`-labeled theme toggle (75% rest fade, not the sketch's 55% — the sketch's value
  failed a real WCAG contrast check). Underline active-nav. Search morphs from a 44px icon, not a
  fixed box. Category mega-menu shares its scroll-spy target attribute with the mobile chip row —
  one mechanism, not two. Drawer bottom block is icon-only, centered, no label. See
  `references/header-navigation-drawer.md`.
- **Carousel — already correct, no change needed:** free-momentum scroll (no `scroll-snap-type`),
  `overscroll-behavior-x: contain`, `touch-action: manipulation`, no position indicator, flat
  no-shimmer skeleton for full-page load.
- **Carousel — approved change:** relocate prev/next from header-embedded circular buttons to
  Netflix-style edge-overlay icon arrows, gated by `@media (hover: hover) and (pointer: fine)` so
  they're absent from the DOM on touch (not just hidden) rather than shown on every pointer type as
  today.
- **Carousel — genuinely new:** a shimmer treatment scoped specifically to a shelf repopulating after
  a filter change — a moment that doesn't exist as a distinct state in the LiveView today at all.
  Deliberately retested 009's "no shimmer" call in this narrower context rather than assuming it
  still applied, and confirmed shimmer reads differently (acceptable) here than on a full-page load.
- **`layout-navigation.md` corrected in place:** its arrow-behavior paragraph was stale relative to
  the real carousel rework; a warning note now points to `carousel-mechanics.md` as authoritative.

## Open Items Carried Forward
- Sketch 016 (mobile-nav-scale) — excluded, no confirmed winner. Revisit once a winner is picked.
- The carousel's arrow relocation (edge-overlay, pointer-fine-gated) and the filter-repopulation
  shimmer are both approved designs, not yet implemented — next natural step is a `/gsd-plan-phase`
  or quick task against `carousel_row.ex`/`app.css`.
- Sketch 023's custom-eased arrow-click scroll (006-D's curve, replacing the current plain
  `scroll-behavior: smooth`) is a nice-to-have, explicitly not required for correctness — flagged as
  optional in `carousel-mechanics.md` rather than bundled into the arrow-relocation work.

## Session: 2026-08-26

**Sketches processed:** 5
**Design areas:** Detail Page — Layout & Content, Detail Page — Mobile & Interaction Patterns,
Filter & Search, Connection Feedback (new)
**Skill output:** `./.claude/skills/sketch-findings-pukllay_club/`

Phase 01.2 UAT gap-closure round — five sketches answering the visual/copy half of five UAT gaps
diagnosed in `.planning/debug/G-01.2-5` through `G-01.2-8` (plus the missing-affordance sub-issue
of `G-01.2-3/4`). Three other UAT gaps in the same phase (`href-parity`, `search-input-broken`, the
search-morph state-machine bug) were pure code fixes with no design question and are out of scope
for this wrap-up.

## Included Sketches
| # | Name | Winner | Design Area |
|---|------|--------|-------------|
| 027 | buybox-panel-boundary | B (Elevated Shadow) | Detail Page — Layout & Content |
| 028 | mobile-cta-balance | D (Stacked) | Detail Page — Mobile & Interaction Patterns |
| 029 | active-filters-chip-row | C (Inline with Heading, rebalanced) | Filter & Search |
| 030 | connection-lost-banner | A (Inline Bar, recolored) | Connection Feedback |
| 031 | similar-games-fallback | C (Always-Full Guarantee) | Detail Page — Layout & Content |

## Excluded Sketches
| # | Name | Reason |
|---|------|--------|
| — | — | none — all 5 included |

## Design Direction
No new aesthetic direction — this round is gap-closure within the already-locked visual system
(26 prior sketches), so mood/reference intake was skipped and the session went straight to
decomposition. Each sketch answers one UAT-flagged visual defect against the existing brand tokens.

## Key Decisions
- **Buy-box boundary (027):** a soft shadow lift read as a self-contained panel better than either
  a stronger border or a stronger fill — purely additive on top of `.poster-col`'s existing fill,
  no token change.
- **Mobile CTA bar (028):** the bar's ~87/13 width imbalance between the reserve button and the
  share control isn't fixable by rebalancing that ratio (3 attempts rejected) — switching to a
  stacked internal layout (reserve full-width, share as a quiet second row) is what read as
  balanced. Also fixed globally: the bar's content now caps to the same 1100px column as the
  buy-box instead of stretching edge-to-edge past it. A floating/overhanging share circle was tried
  and reverted — a `position: fixed` bar's overhang is fixed screen space and can overlap whatever
  page content scrolls underneath it.
- **Active-filters chip row (029):** not yet built. Chips sit inline with the "Resultados" heading;
  reusing the filter modal's own solid-filled chip style outweighed the heading, so this row gets a
  lighter accent-tint treatment instead — a deliberately different chip style from the modal's.
- **Connection-lost banner (030):** not yet built. Replaces the stock, unbranded, English `phx.new`
  toast with an on-brand, centered, Spanish inline bar under the header. Recolored off
  `--color-danger` (alarming for a usually self-recovering reconnect) to the app's own accent tint.
- **Similar-games fallback (031):** the shelf's layout stays completely invariant regardless of
  same-band pool size — the query is responsible for always widening enough to fill it (a separate,
  not-yet-designed backend decision); an "Ampliado" badge + subtitle swap is the only visible sign
  widening happened. Whether the title itself should also swap to "Otras sugerencias" (the user's
  original proposal) is flagged as still open.

## Open Items Carried Forward
- 031: whether "Juegos similares" should fully retitle to "Otras sugerencias" when widened, versus
  the winning badge-only treatment — needs a call once this is actually built and can be judged
  against real widened results.
- 031's actual query-layer widening strategy (adjacent-band distance / dropped band filter /
  `bgg_weight` proximity — three candidates in the phase's debug log) is unresolved; this round only
  covered the visual/copy layer.
- 027's underlying cascade-layer positioning bug (unlayered `.pk-*` CSS beating layered Tailwind
  utilities, breaking the share control's containing block below 768px) and the G-01.2-3/4
  search-morph state-machine/grid-jump issues are still open code fixes, untouched by this round.
- 029 and 030 are both design-approved but not yet implemented — next step is `/gsd-plan-phase`
  (or a quick task) against `CatalogLive.Index`'s Resultados header and
  `PukllayClubWeb.Layouts.flash_group/1` respectively.
