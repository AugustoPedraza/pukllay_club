# Sketch Wrap-Up Summary

**Date:** 2026-09-02
**Sketches processed:** 5 (045-049)
**Design areas:** About Page Content (folded into existing area, not a new one)
**Skill output:** `./.claude/skills/sketch-findings-pukllay_club/`

## Included Sketches
| # | Name | Winner | Design Area |
|---|------|--------|-------------|
| 045 | about-header-scroll-isologo | A3 — 180px hero mark, true scroll-linked pin | About Page Content |
| 046 | about-photo-rail-mobile-hero | A — Autoplay Crossfade+Snap; tagline "Volvé a jugar. Volvé a encontrarte." | About Page Content |
| 047 | about-content-bands | Developer-authored final copy | About Page Content |
| 048 | about-faq-contacto | A — Current/flat color confirmed official; merged Contacto card | About Page Content |
| 049 | about-closing-cta-mobile | A — single "Sumate" CTA | About Page Content |

## Excluded Sketches
None — all five included.

## Design Direction
A revision pass over the already-shipped About page (not greenfield), driven by direct developer
feedback across header behavior, photo carousel, content copy, FAQ/contact, and closing CTA.
Every decision reuses existing tokens, components, and patterns already established elsewhere in
the app (the footer's `social_links/1` icon pattern, the shared `.pk-band`/`.pk-band-inner`
recipe, the hero's `sumate_cta/1`, sketch 037's "one shared edge, no floating pieces" precedent)
rather than introducing new visual language.

## Key Decisions
- **Motion:** a new page-specific header pattern (hidden until scroll, isologo auto-enters then
  morphs into the header mark at the exact geometric crossing point) — deliberately scoped to the
  About page only, not proposed as a site-wide header change.
- **Copy:** developer-authored final copy beat every AI draft; the process caught a real live
  factual bug (origin date wrong on the shipped page).
- **Layout bug:** a shared-class width mismatch (`.pk-band-inner` vs. the shell) affecting every
  About-page content band, found while investigating what looked like an FAQ-only complaint.
- **Component reuse:** Contacto rebuilt from the footer's existing icon/link pattern rather than
  inventing new icons; closing CTA reuses the hero's existing button rather than adding new ones.
- **Two more real bugs caught and fixed during sketching** (not design decisions, implementation
  defects): three overlapping mark elements computing position against hidden zero-size
  containers (045), and a missing `justify-content: center` on a CTA that gets stretched to full
  width only on mobile (049) — both fixed in the sketch and now documented so the same mistake
  isn't repeated during real implementation.

## Open items for implementation (not resolved by sketching)
- No real club photography exists — every photo is a labeled placeholder.
- No real Google Maps thumbnail image exists — sourcing one (manual screenshot vs. Static Maps
  API + key/cost) is an implementation-time decision.
- The "2024 → April 2021" origin-date correction is independent of the rest of this round and
  could ship on its own if the full page rework is deferred.
