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

## Sketches

| # | Name | Design Question | Winner | Tags |
|---|------|----------------|--------|------|
| 001 | shelf-structure | Does the page read as distinct Netflix-style shelves with a real nav bar, or one continuous scroll? | D (Edge-Fade, refined) | layout, navigation, carousel |
| 002 | card-hierarchy | What belongs on the card at rest vs. behind an expand, given the real schema fields (players, playtime, age, weight, tags, mechanics)? | D (hybrid, pop-forward preview) | card, information-architecture, interaction |
| 003 | page-shell | Does a shared header+footer shell work across catalog, detail, and about page skeletons, with a quiet off-catalog header and a footer carrying mission/links/contact/BGG attribution? | C (Two-Tier Mission Band) | layout, header, footer, navigation, compliance |
| 004 | about-page | Do the about page's four sections (mission, how it works, the club, FAQ/vocabulary) read well as one page? | B (Alternating Bands, w/ image carousel) | content, about, carousel |
| 005 | detail-page | What does the full game detail page (`/juegos/:id`) look like inside the shell — hero, facts, description, mechanics? | TBD | layout, detail, card |
| 006 | motion-system | Is a dedicated motion system worth it, and what should hover-expand / row-scroll / focus transitions feel like? | TBD | motion, interaction |
