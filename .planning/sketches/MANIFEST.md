# Sketch Manifest

## Design Direction

Rework the already-shipped Phase 1 catalog browse screen (approved brand-locked UI-SPEC, live and
UAT-verified) — not greenfield. The complaint: card hierarchy/rhythm is broken (title, weight
badge, editorial tags, and 4 mechanic chips crammed into one dense stack), and the carousel rows
read as one continuous scrollable grid rather than distinct Netflix-style shelves. Direction is
poster-forward, human-first (teach through plain Spanish, not hobbyist jargon), riffing on
Netflix's TV catalog pattern: section/row name + poster carry the resting weight, secondary detail
(players, playtime, weight band, one editorial tag, CTA) lives behind a hover/tap expand rather
than being permanently visible. Considering whether a dedicated motion system (hover-expand,
row-scroll easing) is worth the investment once structure and card content are settled.

Extending outward from the browse screen: the site needs a shared page shell (header + footer)
that works across the catalog (master), the game detail page, and a new static "about" page —
plus a footer that carries club mission/links/contact and a required BoardGameGeek attribution
badge (compliance, not optional).

## Reference Points

Airbnb-style card grid (big image, minimal chrome), Netflix web/SmartTV catalog (row-first
navigation, poster-primary cards, focus/hover expand-to-reveal-details pattern).

## Themes

- `default.css` — the approved light brand palette (winner across sketches 001–005).
- `dark-purple.css` — exploratory fork requested during the 006–009 frontier session ("play with a
  dark purple background for better visual identity"). Same typography/spacing/shape/motion tokens
  as default; only the color block changes (deep-purple `--color-bg`, brighter promoted `--color-primary`
  since the light theme's near-black primary disappears on a dark ground). Selectable via every
  sketch's theme switcher (006–009); not yet applied to 001–005's own switchers.
  **Open decision (2026-08-20), not yet resolved:** user liked it and asked whether it should become
  *the* default, vs. shipping both a light and dark theme that follow system/user preference — note
  sketch 003's header already mocks an unwired `☀/🌙` theme-toggle button, so a light+dark toggle was
  implicitly anticipated by the shell design even before this question came up. Resolving this
  requires a scope decision (dark-only vs. light+dark+toggle) before any retrofit work, since sketches
  001–005 have only ever been visually validated in the light `default` theme — going dark-default or
  dual-theme means re-checking all five for dark-mode contrast/legibility, not just flipping a
  variable. Tracked as a candidate future sketch/consistency pass once the scope is decided.

## Sketches

| # | Name | Design Question | Winner | Tags |
|---|------|----------------|--------|------|
| 001 | shelf-structure | Does the page read as distinct Netflix-style shelves with a real nav bar, or one continuous scroll? | D (Edge-Fade, refined) | layout, navigation, carousel |
| 002 | card-hierarchy | What belongs on the card at rest vs. behind an expand, given the real schema fields (players, playtime, age, weight, tags, mechanics)? | D (hybrid, pop-forward preview) | card, information-architecture, interaction |
| 003 | page-shell | Does a shared header+footer shell work across catalog, detail, and about page skeletons, with a quiet off-catalog header and a footer carrying mission/links/contact/BGG attribution? | C (Two-Tier Mission Band) | layout, header, footer, navigation, compliance |
| 004 | about-page | Do the about page's four sections (mission, how it works, the club, FAQ/vocabulary) read well as one page? | B (Alternating Bands, w/ image carousel) | content, about, carousel |
| 005 | detail-page | What does the full game detail page (`/juegos/:id`) look like inside the shell — hero, facts, description, mechanics? | B (carousel+lightbox masthead, pill facts, spec-list accordion, filter-linked data, WhatsApp reservation CTA) | layout, detail, card, accordion, share, whatsapp, carousel, lightbox, filtering |
| 006 | motion-system | Is a dedicated motion system worth it, and what should hover-expand / row-scroll / page-transition / focus transitions feel like? | D (Subtle/Soft synthesis — fast durations + no-overshoot ease, smaller hover amplitude) | motion, interaction |
| 007 | composed-catalog-page | Does the real shell (003-C) hold together once it wraps the real shelves (001-D) and cards (002-D), instead of the shell's own placeholder skeleton? | single composed view — consistency check, found+fixed real drift (see README) | consistency, layout, navigation, card, carousel, shell |
| 008 | filter-search-ui | What does the catalog's own filter surface look like, and how should the nav search box's live-narrowing/typeahead behave? | TBD | filter, search, navigation, information-architecture |
| 009 | empty-loading-error-states | What should the catalog/detail page's non-happy-path states (loading, no results, load error, 404) look like — utilitarian or on-brand illustrated? | A (Minimal/Utilitarian) | empty-state, loading, error, 404, edge-case |
