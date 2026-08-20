# Page Shell (Header + Footer)

## Design Decisions

**One header component, three states — not three headers.** The same `.pk-header`/`.pk-nav`
(already shipped from sketch 001) adapts per page type instead of forking into separate
components:
- **Catalog:** full nav — shelf anchor links, search box, mobile chip row.
- **Detail:** anchors/search/chips disappear; a breadcrumb (`Catálogo / {game name}`) takes their
  place, so there's still a sense of location and a way back. (Superseded on narrow mobile widths
  by sketch 005 Round 32/33's fix — see `detail-page-mobile-interaction.md`: a full breadcrumb
  doesn't survive `flex-shrink: 0` neighbors at ~390px, collapses to a plain "‹ Catálogo" back-link
  there instead.)
- **About:** anchors/search/chips disappear; just a static "Acerca de" label — no breadcrumb, since
  it's a top-level destination, not a drill-down.
- Logo, theme toggle, and sticky scroll-tint behavior (flat background fade-in, no blur) stay
  identical across all three.

**Footer: Two-Tier Mission Band (winner over Minimal Single Bar and Multi-Column Rich).** Splits
"persuasion" from "utility" into two visually distinct bands instead of blending them:
1. A full-width **primary-color mission band** leads with the club's "why we exist" pitch plus
   social icons — present on every page, not just About, so the pitch isn't quarantined to one
   route.
2. A slim **utility bar** underneath carries nav links, the BGG attribution badge, and copyright.

Rejected alternatives: a single dense bar (logo+links+badge+copyright in one row) reads cheap and
has no room for the mission blurb; four columns (brand, Explorar, Club, Contacto) fits everything
but the footer gets tall enough to visually overpower a sparse page (the detail skeleton
specifically looked footer-heavy under it).

**BGG attribution badge is a compliance requirement, not a design choice.** BoardGameGeek's terms
require a visible "Powered by BGG" badge on any public page surfacing their data. Every footer
variant includes it in the utility bar. **The sketch's badge is a labeled placeholder** (a simple
"BGG" mark + text) — pull the actual approved badge asset from BGG's API/brand terms page before
shipping; don't ship the placeholder mark as-is.

**Isologo placeholder.** No vector isologo asset exists in the repo (`priv/static/images/` only has
Phoenix's default `logo.svg`; production's `Layouts.brand_logo/1` already falls back to a text
wordmark when the file is absent). The sketch uses a simple hexagon placeholder mark so header
proportions are right — swap in the real isologo SVG when it exists, no structural change needed.

## CSS Patterns

```css
.pk-header { position: sticky; top: 0; z-index: 40; background: rgba(255,255,255,0.92); box-shadow: var(--shadow-sm); }
.pk-nav { display: flex; align-items: center; gap: var(--space-4); height: 64px; }
.pk-brand-text { display: flex; flex-direction: column; line-height: 1; }
.pk-nav-crumb { font-family: var(--font-sans); font-size: var(--text-sm); color: var(--color-text-muted); flex: 1 0 auto; display: flex; align-items: center; gap: 6px; }
.pk-nav-crumb .current { color: var(--color-text); font-weight: 600; }

/* Two-tier footer */
.footer-c .mission-band { background: var(--color-primary); color: var(--color-primary-content); padding: var(--space-8) var(--pk-gutter); text-align: center; }
.footer-social { display: flex; gap: var(--space-2); justify-content: center; }
.footer-c .utility-bar { display: flex; justify-content: space-between; align-items: center; padding: var(--space-3) var(--pk-gutter); flex-wrap: wrap; gap: var(--space-2); }
.bgg-badge { display: inline-flex; align-items: center; gap: 6px; padding: 6px 10px; border-radius: var(--radius-sm); border: 1px solid var(--color-border); background: var(--color-bg); font-size: var(--text-xs); color: var(--color-text-muted); text-decoration: none; }
```

## HTML Structures

```html
<header class="pk-header pk-gutter">
  <div class="pk-nav">
    <a href="#" class="pk-brand">...logo + wordmark...</a>
    <div class="pk-nav-crumb"><a href="#">Catálogo</a><span class="sep">/</span><span class="current">{Game Name}</span></div>
    <div class="pk-theme-toggle">...</div>
  </div>
</header>

<footer class="pk-footer footer-c">
  <div class="mission-band">
    <h3>{mission headline}</h3>
    <p>{one-line mission statement}</p>
    <div class="footer-social">...icons...</div>
  </div>
  <div class="utility-bar">
    <ul class="footer-links inline">...</ul>
    <div><a class="bgg-badge">Powered by BoardGameGeek</a><span class="footer-copyright">© 2026 Pukllay Club</span></div>
  </div>
</footer>
```

## What to Avoid

- Don't fork the header into separate per-page components — one component with state-driven
  content (nav vs. breadcrumb vs. static label) keeps scroll-tint/logo/theme-toggle behavior from
  drifting between pages.
- Don't ship the sketch's placeholder BGG badge mark as the real compliance asset.
- Don't let a footer variant's visual weight go unchecked against sparse pages — check it against
  the *thinnest* page content, not just the richest.

## Origin
Synthesized from sketch: 003
Source file available in: sources/003-page-shell/
