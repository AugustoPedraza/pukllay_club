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
