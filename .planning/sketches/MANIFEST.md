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
  **Decision confirmed (2026-08-20):** ship both light (`default`) and dark (`dark-purple`) themes,
  following system/user preference with a real toggle — not dark-purple as the sole default. Sketch
  003's header already mocks an unwired `☀/🌙` theme-toggle button, so this was implicitly
  anticipated by the shell design before the question came up explicitly.
  **Done (2026-08-20, frontier consistency pass):** the real mechanism now lives directly in
  `default.css` — light on `:root`, dark via `@media (prefers-color-scheme: dark)` unless
  `[data-theme="light"]` opts out, and `[data-theme="dark"]` to force it explicitly regardless of
  system preference ("data-theme wins" both directions). Proved with a working `☀/🌙` toggle button
  + persisted JS, first on sketch 007 then reused verbatim on sketch 011's full composition — live
  browser-verified across catalog, detail, and about content, including the "Juegos similares"
  shelf's hover-portal and both image carousels. `dark-purple.css` is no longer needed as a
  standalone file (its values are merged into `default.css`) but is left in place for reference.
  Sketches 001–006/008/009 still only have the old toolbar `<select>` swap in their own files (now
  stale — swapping to `dark-purple.css` there loses the merged mechanism and the 006-D motion-token
  fix); only 007 and 011 carry the real toggle. Retrofitting the standalone files' toolbars is
  low-value now that 011 supersedes them as the real composed reference.

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
| 008 | filter-search-ui | What does the catalog's own filter surface look like, and how should the nav search box's live-narrowing/typeahead behave? | C (Search-First Overlay, refined: shelf-rail results + popover/bottom-sheet filters panel) | filter, search, navigation, information-architecture |
| 009 | empty-loading-error-states | What should the catalog/detail page's non-happy-path states (loading, no results, load error, 404) look like — utilitarian or on-brand illustrated? | A (Minimal/Utilitarian) | empty-state, loading, error, 404, edge-case |
| — | *(shared-theme fix, no new sketch)* | Sketch 006's validated D winner (100/180/280ms, smaller hover-lift) was never applied to `themes/default.css`/`dark-purple.css` — both still had the original incidental values. Fixed 2026-08-20: theme tokens updated, real card hover-lift (001/002/007) corrected -4px → -3px. See sketch 006's README for details. | applied | motion, consistency |
| 010 | *(real theme toggle, no new sketch dir)* | Does a real light/dark toggle mechanism (not a theme-file swap) work across real composed content? | applied — merged into `themes/default.css` + proved on 007 and 011 | theme, dark-mode, consistency |
| 011 | full-shell-composition | Does the real shell hold together once it wraps the real detail page (005-B) and about page (004-B) instead of 007's placeholder skeletons? | single composed view — consistency check, found+fixed 6 real drift bugs (Round 1) + 8 real mobile bugs (Round 2) + 3 rhythm/balance issues in the section-index/crumb/footer (Round 3) + a full rebuild of the about page (app-native statement/step-cards/band/accordion, replacing the 3x-repeated text+carousel band shape) plus a real two-cluster header and a single unified multi-column footer (Round 4, also fixed a real sticky-title-bar bleed bug) + real desktop feedback caught a content-width misalignment the header/footer cap introduced (catalog rail + detail similar-shelf + footer now share the exact same 1280px box), trimmed redundant footer text, and swapped text-initial social badges for real minimal icons (Round 5) + renamed header nav to Inicio/Para empezar/Novedades/Clásicos (crumbs updated to match) and collapsed the footer to one undivided row with horizontal Club links and a de-emphasized plain-text BGG mention (Round 6) + split global site nav (Inicio/Acerca de, everywhere, logo now a real "go home" link) from a new catalog-only shelf-jump index reusing the about-index pattern against the real SHELVES data, and fixed a residual active-tab state bug found while verifying (Round 7) + removed the shelf-jump bar entirely (two stacked sticky bars was chrome overload; the project's own Netflix reference doesn't have one) and switched Acerca de's header to real nav-links instead of a crumb (About is a sibling top-level page, not a drill-down of Inicio the way a game page is), fixing a header-balance regression that change would have introduced (Round 8) + vocabulary pass: "Ludoteca" (not "Catálogo"/"Colección") names the catalog section in Detalle's crumb, "Quiénes Somos" (not "Acerca de"/"El Club"/"Nosotros") replaces the About nav label everywhere — "Inicio" deliberately kept as the separate nav-action label, not merged with "Ludoteca" (Round 9) | consistency, layout, detail, about, shell, mobile, header, footer |
