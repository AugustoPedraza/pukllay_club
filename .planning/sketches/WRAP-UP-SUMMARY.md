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

---

**Date:** 2026-09-07
**Sketches processed:** 2 (050-051)
**Design areas:** About Page Content (folded into existing area, not a new one)
**Skill output:** `./.claude/skills/sketch-findings-pukllay_club/`

## Included Sketches
| # | Name | Winner | Design Area |
|---|------|--------|-------------|
| 050 | about-morph-companion-text | Companion wordmark baked into isologo mark (~25px), mark anchored in-flow, eyebrow synced to dock-crossing state | About Page Content |
| 051 | about-full-page-cta-rhythm | Contacto card chrome dropped at all widths; soft-chip contact links (+Facebook); Maps moved to Juntadas; Cierre full-screen desktop with unified rhythm; alternating band backgrounds page-wide | About Page Content |

## Excluded Sketches
None — both included.

## Design Direction
Continues the direct-developer-feedback revision pattern from the 2026-09-02 round (045-049):
started as a single todo ("surface Pukllay Club brand name") and expanded through live iteration
into a full CTA-rhythm and band-background pass across the whole About page. Every decision
verified live in a browser (not just reasoned about), including a real 375px iframe-based
responsive preview built specifically because the sketch toolbar's own viewport buttons couldn't
trigger real `@media` breakpoints.

## Key Decisions
- **Brand name surfaced** without adding new UI: baked into the isologo's own scroll-morph
  element rather than a separate label, so it travels/melts into the header's real wordmark.
- **CTA de-duplication and grouping is a page-wide system now**, not per-section fixes: every
  touchpoint (hero, Contacto, Cierre, mobile sticky bar) was checked together, not in isolation —
  this is what surfaced the redundancy between Cierre's own Sumate and the mobile sticky bar, and
  between Contacto's Instagram link and the closing meta line.
- **Band backgrounds became a reusable page pattern**: FAQ's existing dark band (already shipped)
  inspired an alternating plain/tint rhythm for the rest of the page, with FAQ explicitly kept as
  the one bold exception rather than diluted into the alternation.

## Real bugs found and fixed during sketching (5 total, not design decisions)
1. Sketch theme's shared `default.css` never loaded the real Bebas Neue font file (fixed at the
   theme level — benefits every sketch, not just this one).
2. Header's `.brand-slot` never reserved space for the docked mark icon, causing text overlap.
3. Debug annotation flags were positioned inside their target's box, hiding small buttons
   entirely.
4. A shared `.band p` CSS rule silently out-specified a target's own single-class font-size rule
   for multiple rounds before a layout change (2-line wrap) made the wrong size visible.
5. A rebuild of Cierre's spacing system silently dropped its `text-align: center` rule; invisible
   until multi-line content exposed the missing alignment.

## Open items for implementation (not resolved by sketching)
- Moving the Maps thumbnail from Contacto to Juntadas reopens sketch 048's original placement
  decision — flag for developer sign-off before shipping.
- The closing meta line's simplification (dropping its Instagram link) resolves an open question
  already flagged in the real `about_live.ex` code comment, but is itself a content decision, not
  purely visual — confirm before shipping.
- Contacto's new soft-chip link style (`.cl-soft`) and its mobile icon-only variant have no
  real-app CSS class yet; would need to be built as actual classes, and the real `Contacto` call
  site needs `icons={[:whatsapp, :instagram, :facebook]}` added.
