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

## Reference Points

Airbnb-style card grid (big image, minimal chrome), Netflix web/SmartTV catalog (row-first
navigation, poster-primary cards, focus/hover expand-to-reveal-details pattern).

## Sketches

| # | Name | Design Question | Winner | Tags |
|---|------|----------------|--------|------|
| 001 | shelf-structure | Does the page read as distinct Netflix-style shelves with a real nav bar, or one continuous scroll? | D (Edge-Fade, refined) | layout, navigation, carousel |
| 002 | card-hierarchy | What belongs on the card at rest vs. behind an expand, given the real schema fields (players, playtime, age, weight, tags, mechanics)? | D (hybrid, pop-forward preview) | card, information-architecture, interaction |
| 003 | motion-system | Is a dedicated motion system worth it, and what should hover-expand / row-scroll / focus transitions feel like? | TBD | motion, interaction |
