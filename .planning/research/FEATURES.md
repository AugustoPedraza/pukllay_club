# Feature Research

**Domain:** Board-game catalog / discovery / recommendation product (small club scale, ~400 games)
**Researched:** 2026-07-24
**Confidence:** MEDIUM (cross-checked web sources — BGG community threads, NN/g UX research, multiple
board-game-cafe SaaS vendors, multiple rules-Q&A AI products; no single source is primary/official
documentation, so treat specifics as directional, not gospel)

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in any board-game catalog/discovery product. Missing these makes the
product feel incomplete regardless of how good the differentiators are.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Browse full catalog with cover images | Every board-game site (BGG, cafe apps) leads with box art — it's the primary recognition cue, especially for non-hobbyists who don't know titles by name | LOW | Already scoped Phase 1. Own resized images, not hotlinked BGG images (licensing + control). |
| Filter by player count | Universal metadata field across BGG, BGA, cafe SaaS (TWICE/GameLedger/GameShelf) and library cataloging guides — the single most load-bearing filter for a club (group size varies by session) | LOW | Scalar column filter, already scoped Phase 1. |
| Filter by playtime/duration | Second most universal filter field; club members often decide "what fits in the time we have" before anything else | LOW | Scalar column filter, already scoped Phase 1. |
| Filter/facet by category, mechanic, theme | Standard across BGG, BGA, Wikidata board-game schema — table stakes for any catalog beyond a flat list | LOW–MEDIUM | Already scoped as `text[]` + GIN, Phase 1. Complexity is in *labeling in plain Spanish*, not the filter mechanism itself (see Differentiators). |
| Keyword/text search on title, designer, publisher | Users who already know what they want (a specific title) need a fast path that doesn't require browsing | LOW | `tsvector`, already scoped Phase 1. |
| Complexity/weight indicator per game | BGG's Weight (1.0–5.0) is the de facto industry-standard signal; every serious catalog surfaces *some* complexity signal, or experienced users assume the catalog is amateurish | LOW–MEDIUM | Already scoped Phase 1 as "visual weight." The differentiator is *translating* the number for non-hobbyists (see below) — the raw scalar alone is table stakes, not a differentiator. |
| Minimum recommended age | Present in nearly every catalog schema (BGG, library cataloging guides); club members filtering for family sessions need it | LOW | Not yet explicit in PROJECT.md scope — flag as a candidate Phase 1 filter column if CSV data has it. |
| Sorting by rating/rank/complexity/playtime | BGG threads confirm users expect to reorder results, not just filter; a filter-only catalog without sort feels rigid | LOW | Cheap to add alongside filters — same query, different `ORDER BY`. |
| Mobile-first, fast-loading UI | Club members browse on phones during/before a session, not at a desk; cafe-management SaaS (TWICE, GameLedger) lean heavily on QR-code-at-table flows, implying phone-first usage is the norm in this domain | LOW–MEDIUM | Already implied by "native-feeling PWA" durable principle. |
| No account required to browse | Every catalog product (BGG, cafe apps' public menus) lets you look before you log in; forcing signup to browse a catalog is a known conversion killer | LOW | Matches PROJECT.md: Phase 1 fully public, auth deferred to Phase 2 favorites. |

### Differentiators (Competitive Advantage)

Features that set PukllayClub apart from a generic catalog. These should concentrate around the
stated hook: teaching complexity to non-hobbyists, and true NL recommendation.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Plain-Spanish complexity translation (not just a number) | Research finding: BGG's 1–5 weight scale is non-linear (each integer step ≈ doubles perceived complexity) and has no public rubric — a bare number or star rating is meaningless to someone who's never played a "3.5". Translating "3.2" into a short plain-language descriptor ("Requiere explicar reglas ~20 min, decisiones con varios pasos") is the single highest-leverage UX move for this audience and is *not* something any competitor product does well (no polished beginner-facing weight visualization found in research) | MEDIUM | Concrete pattern: map the 1–5 continuum to ~4 labeled bands (e.g. "Para empezar" / "Un paso más" / "Te vas a enganchar" / "Para veteranos"), each with a one-line plain-language description of what that means in practice (rules-explanation time, decision depth), shown as a chip/badge, not a bare decimal. Avoid icon-only cues — research shows icons *increase* cognitive load for non-hobbyists unless paired with text. |
| Plain-language mechanic/theme chips (translated, not jargon) | "Card drafting", "worker placement", "área de control" mean nothing to a non-hobbyist. Research confirms exposing raw hobbyist taxonomy is a documented onboarding pitfall. A club-curated glossary that renders `worker_placement` as something like "Turnos por turnos, colocás para conseguir recursos" is a differentiator competitors (BGG, BGA) don't offer because they serve an already-fluent audience | MEDIUM | Requires a small curated mapping table (mechanic code → plain Spanish chip label + optional tooltip). Cheap once built; the cost is curation, not engineering. Already scoped Phase 1 ("plain-language mechanic/theme chips") — this research validates and sharpens that scope. |
| Natural-language Spanish query → matched games (hero feature) | Research confirms existing recommenders (Quantic Foundry, Boreg, Try These Games, LogicBalls) are collaborative/content-based filtering on BGG data in English — true conversational NL matching in Spanish, scoped to a curated ~400-game catalog, is genuinely uncommon in this space, not a solved/commodity feature | HIGH | Already scoped Phase 2. Validated as a real differentiator, not a reinvention of an existing wheel — worth the investment. |
| Rules Q&A grounded in official rulebooks with citations | Research shows the pattern (RulesBot.ai, Boardside, BGRB) is proven and users trust it *because* answers cite the rulebook page/section — the citation, not just the answer, is what builds trust. Differentiator here is Spanish-language + scoped to the club's actual 400-game collection (competitors are English, broad, subscription-gated) | HIGH | Already scoped Phase 3. Adopt the "cite the source passage" pattern from competitors — it's the trust mechanism, not optional polish. Also adopt "select game first, then ask" scoping (no open-ended cross-game Q&A) to keep RAG grounded and reduce hallucination risk. |
| Progressive disclosure across the whole catalog UX | Research (NN/g, Zombie Kidz Evolution onboarding pattern) shows successful products reveal complexity in layers rather than front-loading a glossary. Applied to a catalog: show weight-band + one plain-language line by default; put full mechanic list, designer, publisher, BGG rank behind a "ver más" expand | LOW–MEDIUM | This is a layout/interaction decision for Phase 1 card/detail design, not a new backend feature — flag for UI-SPEC when Phase 1 is designed. |
| Lightweight rental tracking (who has which copy) | Cafe-management SaaS (TWICE, GameLedger, GameShelf) prove the pattern works at small scale: copy status (available/checked-out) + who + due-back. PukllayClub's version is deliberately smaller — a club, not a commercial venue | LOW–MEDIUM | Already scoped Phase 4. Research confirms the *core primitive* is simple (a copy has a status and a holder) — resist scope creep toward the fuller cafe-SaaS feature set (see Anti-Features). |

### Anti-Features (Commonly Requested, Often Problematic)

Features that competitor products have, that a small club catalog should deliberately not build —
either because they don't fit the scale/budget/audience, or because they actively work against the
"teach complexity, don't assume it" goal.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| BGG-style user ratings/reviews & rank | "Every catalog has ratings" — feels like a missing feature if omitted | Requires moderation, a critical mass of raters (400 games / small club membership won't reach statistical usefulness), and re-introduces the exact numeric-rating-without-context problem this project exists to avoid | Curate a single club-editorial "good for beginners" / "club favorite" tag instead of a public rating system |
| Full BGG-style taxonomy browsing (100+ mechanics, categories, families) | Power users expect BGG-depth faceting | Directly contradicts the core value prop — a non-hobbyist facing 100+ unfamiliar mechanic facets is the exact overwhelm this project is designed to prevent; also 400 games don't need BGG's faceting depth (built for 100K+ games) | Curated, small (~15-25) plain-Spanish mechanic/theme tags, chosen for teaching value not taxonomic completeness |
| Table/session reservation & scheduling system | Cafe SaaS (TWICE, GameLedger, Anolla) bundle this as standard | PukllayClub is a catalog + rental tracker for a club, not a venue-booking business; scheduling is a different problem domain (calendars, capacity, payments) explicitly out of scope per PROJECT.md (no online payments, single tenant) | None needed — Phase 4 rental tracking (copy in/out) is sufficient; if session scheduling is ever needed, treat as a new milestone, not scope creep into Phase 4 |
| Collaborative filtering "users who liked X also liked Y" recommendations | Standard on BGG/Boreg/Try These Games, feels like an obvious addition once you have a catalog | Needs a critical mass of user rating/interaction data a ~small club won't generate for years; also explicitly deferred in PROJECT.md ("Group or 'for you' recommendations — deferred until individual NL recommendation is proven") | Individual NL query recommendation (Phase 2) is the validated bet; revisit collaborative filtering only after Phase 2 proves out and usage data exists |
| General-purpose / cross-game rules chatbot | Users may ask "what's a good rule for X in general" expecting an open Q&A bot | Un-scoped Q&A across many rulebooks increases hallucination risk and dilutes trust (the "citation to specific rulebook" pattern that makes competitor rules-bots trustworthy requires scoping to one game at a time) | Rules Q&A always scoped to "select this specific game, then ask" per Phase 3 RAG design — matches how RulesBot.ai/Boardside/BGRB actually work |
| Voice interface for rules Q&A | Feels natural for "hands full during a game session" use case; some competitor apps market this | Already explicitly out of scope in PROJECT.md, and adds real complexity (speech-to-text, noisy game-night audio) for a use case text chat on a phone already covers adequately | Text-based rules Q&A (Phase 3), revisit voice only if usage data shows friction |
| Membership/loyalty/payment features (cafe SaaS bundles these) | Cafe SaaS vendors bundle memberships, payments, usage analytics as part of "operations" | PROJECT.md explicitly excludes online payments and multi-tenancy; this is an internal club tool, not a commercial cafe product — payment/membership infra is unnecessary ops burden at this scale | Manual club operations (already the stated approach); if dues/payment tracking is ever needed, it's a separate small feature, not baked into the catalog/rental core |
| Icon-only complexity/mechanic indicators | Visually clean, used in some game UIs (e.g. Minecraft: Builders & Biomes) to save space | Research directly flags icon-only cues as *increasing* cognitive load for people unfamiliar with the underlying convention — exactly this project's target audience | Pair every icon with a short plain-language label; never rely on icon-only communication for weight/mechanics |

## Feature Dependencies

```
[Complexity-teaching UX (weight bands + plain-Spanish chips)]
    └──requires──> [Catalog browse/filter UI (Phase 1)]
                       └──requires──> [~400 games seeded + own resized images]

[NL Spanish search (Phase 2)]
    └──requires──> [Catalog browse/filter UI (Phase 1)]  (fallback UI when NL search has no/weak match)
    └──requires──> [Plain-Spanish mechanic/theme labels]  (query parsing maps free text to these same
                     curated tags, so the vocabulary must exist before NL parsing can target it)

[Favorites]
    └──requires──> [phx.gen.auth magic-link (Phase 2)]

[Rules Q&A citations (Phase 3)]
    └──requires──> [Per-game scoping]  (game must be selected/identified before RAG retrieval,
                     which itself requires the catalog's game identity/slug from Phase 1)

[Rental tracking: copy status + holder (Phase 4)]
    └──requires──> [Catalog + physical copy identity (Phase 1)]
    └──requires──> [Admin auth/roles]  (not yet scoped — flag for Phase 4 discuss/plan: rental
                     tracking needs an admin-only mutation path, distinct from member magic-link auth)

[Club favorite / editorial tag] ──enhances──> [Complexity-teaching UX]
    (a light editorial signal instead of BGG-style ratings — reinforces "teach, don't assume"
     without requiring a rating system)

[Collaborative "users who liked X" recs] ──conflicts──> [Small catalog / small user base]
    (explicitly deferred per PROJECT.md; do not combine with Phase 2 — needs interaction-volume
     data Phase 2 won't yet have produced)
```

### Dependency Notes

- **Complexity-teaching UX requires the Phase 1 browse/filter UI:** the weight-band badges and
  plain-language mechanic chips are rendering decisions on top of the same catalog data — they
  cannot precede having games and their metadata seeded.
- **NL Spanish search requires plain-Spanish mechanic/theme labels to exist first:** if Phase 2's
  LLM query parser maps "algo de negociación estilo Catan" to internal tags, those tags need
  consistent, already-curated plain-language names from Phase 1 — retrofitting vocabulary after
  Phase 2 ships would mean redoing the parser's target schema. Confirm during Phase 1 planning that
  the tag/chip vocabulary is treated as a stable contract, not a UI-only concern.
- **Rules Q&A requires per-game scoping, which requires stable game identity from Phase 1:** the
  RAG retrieval needs to know which game's rulebook to search *before* running retrieval — this
  argues for a durable `game_id`/slug established in Phase 1 that Phase 3 can hang rulebook
  documents off of without renaming/migrating IDs.
- **Rental tracking needs an admin/role concept not yet in scope:** Phase 2 introduces
  `phx.gen.auth` for members (magic-link, favorites). Phase 4's "mark copy out/returned" needs an
  admin capability distinct from member auth — flag this explicitly for Phase 4's
  `/gsd-discuss-phase` (roles: member vs. admin, and how admin auth differs from magic-link).
- **Collaborative filtering conflicts with current scale:** already correctly deferred in
  PROJECT.md; research confirms this is the right call — every competitor recommender relying on
  "users who liked X" needs rating volume a ~400-game/small-club product won't have for a long
  time, and it doesn't serve the stated non-hobbyist audience anyway (rating-based recs still
  assume vocabulary fluency to interpret).

## MVP Definition

Mapped onto PukllayClub's already-fixed phase order (Phase 0–4). This section reframes that roadmap
through a feature-value lens, not a new sequence — it validates the phase boundaries and flags a few
additions/watch-items within each phase.

### Launch With (v1 — Phase 1, "Catalog v1")

Minimum viable product — what's needed to validate that a catalog can excite a non-hobbyist.

- [ ] Browse/filter catalog (player count, playtime, category/mechanic/theme, keyword search) —
      table stakes, without it there's no product
- [ ] Own resized cover images per game — recognition is the primary browsing cue for this audience
- [ ] Weight-band + plain-language complexity descriptor (not a bare 1–5 number) — the core hook;
      this is what makes Phase 1 differentiated rather than "a smaller BGG"
- [ ] Plain-Spanish mechanic/theme chips (curated small vocabulary, not full BGG taxonomy) —
      required both as a standalone differentiator and as the vocabulary contract Phase 2's NL
      parser will depend on
- [ ] Minimum age filter, if present in source CSV data — cheap, expected, flag for confirmation
      during Phase 1 planning whether the CSV has this field

### Add After Validation (v1.x — Phase 2–3 as already scoped)

Features to add once the core catalog is validated and getting real usage.

- [ ] NL Spanish search + favorites + magic-link auth (Phase 2) — trigger: Phase 1 catalog is live
      and members are actually browsing/filtering it; NL search is the hero bet on top of a proven
      base, not a replacement for it
- [ ] Rules Q&A with rulebook citations (Phase 3) — trigger: catalog + NL search are stable; RAG
      quality risk is high enough that it deserves its own focused phase per PROJECT.md

### Future Consideration (v2+ — Phase 4 and beyond)

Features to defer until the recommender/catalog core has product-market fit within the club.

- [ ] Rental tracking (copy in/out, admin dashboard, promotions) — defer until schema is stable;
      Phase 4 is explicitly built "against a stable schema" per PROJECT.md
- [ ] Club-editorial "favorite"/"beginner-friendly" tag — nice differentiator, but not required for
      MVP; consider bundling into Phase 1 only if curation effort is trivial, otherwise Phase 4+
- [ ] Collaborative/"users who liked X" recommendations — explicitly deferred until Phase 2's
      individual NL recommendation is proven and enough interaction data exists
- [ ] Voice rules Q&A — explicitly deferred past Phase 3's text RAG

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Browse/filter catalog (player count, playtime, tags, search) | HIGH | LOW | P1 |
| Own resized images | HIGH | LOW | P1 |
| Weight-band + plain-language complexity descriptor | HIGH | MEDIUM | P1 |
| Plain-Spanish mechanic/theme chips | HIGH | MEDIUM | P1 |
| Minimum age filter | MEDIUM | LOW | P1 (if data available) |
| NL Spanish search + hybrid ranking | HIGH | HIGH | P1 (within Phase 2) |
| Favorites + magic-link auth | MEDIUM | LOW–MEDIUM | P1 (within Phase 2, enabling favorites) |
| Rules Q&A with citations | HIGH | HIGH | P1 (within Phase 3) |
| Rental tracking (copy status + holder) | MEDIUM | LOW–MEDIUM | P1 (within Phase 4) |
| Club-editorial "favorite" tag | MEDIUM | LOW | P2 |
| Collaborative recommendations | LOW (at this scale) | HIGH | P3 |
| Table/session reservation system | LOW (not the product) | HIGH | P3 / reject |
| Voice rules Q&A | LOW | HIGH | P3 |
| Full BGG-depth taxonomy | LOW (actively hurts audience fit) | HIGH | Reject |

**Priority key:**
- P1: Must have for the phase it belongs to (each phase already has its own launch bar per
  PROJECT.md's fixed roadmap)
- P2: Should have, add when curation/engineering bandwidth allows
- P3: Nice to have or explicitly rejected — see Anti-Features for rejection rationale

## Competitor Feature Analysis

| Feature | BoardGameGeek | Board-game-cafe SaaS (TWICE / GameLedger / GameShelf) | Our Approach |
|---------|--------------|--------------------------------------------------------|--------------|
| Complexity signal | Bare 1.0–5.0 "Weight" number, no rubric, non-linear scale, historically weak native filter/sort | Usually inherits BGG weight via import, same raw-number problem | Weight *band* + one-line plain-Spanish description, not a bare decimal — the explicit differentiator |
| Taxonomy/tags | 100+ mechanics/categories, built for 100K+ games, power-user depth | Inherits BGG taxonomy via import (same depth problem) | Small curated (~15-25) plain-Spanish tag vocabulary, chosen for teaching value |
| Search | Advanced search with many facets, powerful but jargon-dependent | Menu/catalog browse, often QR-code-at-table, less about NL query | NL Spanish query (Phase 2) — genuinely differentiated per research; no competitor found doing this in Spanish at small-catalog scale |
| Ratings | Public aggregate user ratings + rank | Sometimes surfaced via BGG import | Deliberately omitted (see Anti-Features) — replace with light editorial "club favorite" tag if any signal is needed |
| Rules help | None native; third-party apps (RulesBot.ai, Boardside) fill this gap, in English, subscription-gated, cross-catalog | None found in cafe SaaS research | Rules Q&A scoped to club's own ~400 games, in Spanish, with citations (Phase 3) — matches the proven "cite the rulebook passage" trust pattern from competitors |
| Rental/inventory ops | N/A (not a physical-copy tracker) | Full ops suite: QR checkout, reservations, memberships, payments, analytics | Minimal slice only: copy status + holder (Phase 4) — deliberately smaller, matches club (not commercial venue) scale |
| Access model | Public browse, account for collection/ratings | Often public menu + booking, membership for perks | Fully public catalog (no auth) through Phase 1; auth only enters at Phase 2 for favorites — matches table-stakes expectation that browsing shouldn't require signup |

## Sources

- [Custom Filter – Board Game Stats](https://www.bgstatsapp.com/explanations/custom-filter/)
- [Browse Board Games by Complexity | BGG](https://boardgamegeek.com/thread/1918236/browse-board-games-by-complexity)
- [Sort / filter search results by "weight"/"complexity" | BGG](https://boardgamegeek.com/thread/3058887/sort-filter-search-results-by-weight-complexity)
- [Sort by complexity rating | BGG](https://boardgamegeek.com/thread/2685309/sort-by-complexity-rating)
- [Boardgame Recommender System and Web App | John Burt](https://johnmburt.github.io/boardgame_recommender.html)
- [Building Recommendation Systems for Boardgames | Medium](https://chrisgrannan.medium.com/building-recommendation-systems-for-boardgames-6dc4a37fc869)
- [AI Board Game Recommendation Tool — LogicBalls](https://logicballs.com/tools/board-game-recommendation)
- [Board Game Recommendation Engine — Quantic Foundry](https://apps.quanticfoundry.com/recommendations/tabletop/boardgame/)
- [Try These Games — Board Game Recommender](https://trythesegames.com/)
- [Boreg](https://boreg.app/)
- [Understanding Board Game Weights — Chits & Giggles](https://chitsandgiggles.games/understanding-board-game-weights)
- [Board Game Weight: Weighing in on Game Complexity — Ask The Bellhop](https://tabletopbellhop.com/gaming-advice/board-game-weight/)
- [Usability Heuristics Applied to Board Games — NN/g](https://www.nngroup.com/articles/usability-heuristics-board-games/)
- [Board Game Complexity Scales | Wiki | BGG](https://boardgamegeek.com/wiki/page/Board_Game_Complexity_Scales)
- [Board Game Rental Software — TWICE](https://www.twicecommerce.com/rent/boardgames)
- [GameLedger — Board Game Café Software](https://www.gameledger.io/)
- [GameShelf — Board game cafe operating system](https://gameshelfapp.com/)
- [Rulesbot.ai](https://www.rulesbot.ai/)
- [Boardside — AI app for board game rules | BGG](https://boardgamegeek.com/thread/3631492/boardside-ai-app-for-board-game-rules)
- [Board Game Rulebook Chatbot (BGRB)](https://www.boardgamerulebook.com/)
- [Ludomentor — Board Game AI (Google Play)](https://play.google.com/store/apps/details?id=com.awakenrealms.ludomentor)
- [Learning Board Games with RAG | Medium](https://medium.com/@thesammiller/learning-board-games-with-rag-61894c3cc1f7)
- [Cataloguing and classifying board and tabletop games — CILIP](https://cdn.ymaws.com/www.cilip.org.uk/resource/collection/D44BB270-A31A-428E-AD19-2C0E0BB44433/catalogue_and_index_issue_189_mcculloch_cataloguing_and_classifying_board_and_tabletop_games.pdf)
- [Cataloging Your Tabletop Games — ALA Games and Gaming Round Table](https://games.ala.org/tabletop-cataloging-guide/)
- [Game database model: dbmodel.sql — Board Game Arena](https://en.boardgamearena.com/doc/Game_database_model:_dbmodel.sql)

**Confidence caveat:** all sources above are general web search (community forums, vendor marketing
pages, blog posts) rather than primary product documentation or academic sources — MEDIUM confidence
because findings were cross-checked across multiple independent sources per topic, but treat as
directional input for roadmap/requirements discussion, not settled fact. Areas most worth
re-verifying with direct product trials before Phase 1 UI design: the exact wording/format that
works best for the weight-band descriptors (no competitor solves this well, so there's no reference
implementation to copy — this will need its own design iteration, not just research).

---
*Feature research for: Board-game catalog/discovery/recommendation product, small-club scale*
*Researched: 2026-07-24*
