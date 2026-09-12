---
created: 2026-09-07T19:07:10.558Z
title: Surface "Pukllay Club" brand name in site content
area: ui
severity: cosmetic
files:

  - lib/pukllay_club_web/live/about_live.ex
  - lib/pukllay_club_web/components/layouts.ex

audit_acknowledged:
  milestone: v1.0
  at: 2026-09-11
completed: 2026-09-12
status: completed
---

## Problem

Raised by the user immediately after Phase 01.4's final UAT checkpoint (isologo scroll-morph
motion) passed: browsing the site, "Pukllay Club" as a written name never actually appears
anywhere — only the isologo mark (a graphic wordmark/symbol) renders in the header/footer and
About page. A first-time visitor who doesn't already know the club's name has no text anchor to
read, search for, or reference it by (e.g. when telling a friend, or via search engines/social
previews that can't parse a raster brand mark).

Out of scope for Phase 01.4, which covered About-page sketch fidelity (spacing, motion, Maps
thumbnail) — not copy/content strategy for brand-name placement. The user explicitly asked to
sketch this before deciding on an approach, rather than have it implemented ad hoc.

## Solution

TBD — candidate approaches to explore via `/gsd-sketch` when this is picked up:

- Add "Pukllay Club" as visible text near the isologo in the header/footer brand lockup (not just
  alt text)
- Add it explicitly in the About page's opening copy/hero if not already present in prose form
  (verify — the current copy may reference "el club" without the proper name)
- Check `<title>`/meta tags and social-preview (OpenGraph) tags for the literal club name, since
  those matter for search/sharing independent of any on-page visual fix

## Resolution

**Date:** 2026-09-12

Already satisfied by shipped work — no new implementation needed for this item. The Solution
section's "explore via `/gsd-sketch` when picked up" step is obsolete: Sketch 050 (01.5-01, D-15)
already ran and shipped, and it directly addresses this todo. Re-verified all three candidate
areas by content against the current tree (line numbers below, not the numbers recorded at
todo-creation time, which have since drifted):

- **Brand text near the isologo (About hero wordmark + header lockup text):**
  `lib/pukllay_club_web/live/about_live.ex:34` carries a moduledoc note
  (`**Sketch 050 (01.5-01, D-15):** the pending todo "Surface Pukllay Club...`) recording that this
  todo is satisfied by the hero isologo's companion wordmark, rendered at
  `lib/pukllay_club_web/live/about_live.ex:970` as
  `<span class="pk-about-morph-name">PUKLLAY CLUB</span>`, styled by `.pk-about-morph-name` defined
  in `assets/css/app.css:4206` (plus a docked-state rule at `assets/css/app.css:4298`). The site
  header carries the same literal text via the horizontal logo lockup at
  `lib/pukllay_club_web/components/layouts.ex:80` (`PUKLLAY CLUB`).
- **About-page prose name (Cierre signature):**
  `lib/pukllay_club_web/live/about_live.ex:843` — the Cierre closing signature reads
  `Pukllay Club ·<br class="pk-about-closing-break" /> San Salvador de Jujuy, Argentina`.
- **Title/meta/OG tags (seo.ex description + JSON-LD name):**
  `lib/pukllay_club_web/components/layouts.ex:1073` — footer
  `<span class="pk-footer-meta pk-footer-copyright">© {@copyright_year} Pukllay Club</span>`.
  `lib/pukllay_club_web/seo.ex:32` — `@site_description "La ludoteca de juegos de mesa de Pukllay
  Club, Jujuy — encontrá tu próximo juego."`, consumed as `description: @site_description` at
  `lib/pukllay_club_web/seo.ex:95` (meta/OG description tag). `lib/pukllay_club_web/seo.ex:37` —
  `@local_business_name "Pukllay Club"`, consumed as `"name" => @local_business_name` at
  `lib/pukllay_club_web/seo.ex:150` (JSON-LD `LocalBusiness` structured data, Phase 01.8 work).

Factual observation, not acted on: `lib/pukllay_club_web/seo.ex:31` sets `@site_title
"PukllayClub"` (no space between the two words), consumed as `title: @site_title` at
`lib/pukllay_club_web/seo.ex:94`. This does not block closure of this todo and must not be changed
here.
