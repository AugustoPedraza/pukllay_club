---
created: 2026-09-07T19:07:10.558Z
title: Surface "Pukllay Club" brand name in site content
area: ui
severity: cosmetic
files:
  - lib/pukllay_club_web/live/about_live.ex
  - lib/pukllay_club_web/components/layouts.ex
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
