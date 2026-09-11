# Page Shell (Header + Footer)

This reference documents sketch 011's final state after 9 rounds of real revision — it replaces the
original sketch 003 design entirely (the two-tier "Mission Band" footer and the `Catálogo`/`Acerca de`
nav it describes below were superseded). If a source predates this note, treat this file as
authoritative. **Sketch 044 (2026-09-01/02) further revises the footer's `≤480px` state only** — see
"Mobile Footer: Reduced to BGG Compliance Only" below; the desktop footer described in the rest of
this file is unaffected.

## Design Decisions

**One header component, three states — not three headers.** The same `.app-nav` adapts per page type
instead of forking into separate components, toggled via `data-catalog-only`/`data-detail-only`/
`data-about-only` attributes:
- **Catálogo (Inicio):** full nav — Inicio + Quiénes Somos links, search box (grows to fill space),
  mobile chip row.
- **Detalle:** links/search disappear; a real breadcrumb (`Ludoteca / {game name}`) takes their
  place — this is the one page that's a genuine drill-down (catalog → one specific item), so a
  breadcrumb is the right pattern. Collapses to a plain "‹ Ludoteca" back-link on mobile (a full
  breadcrumb trail doesn't survive `flex-shrink` neighbors at narrow widths).
- **Quiénes Somos (About):** **not a crumb** — the same nav-links row Inicio has, with "Quiénes Somos"
  marked active instead of "Inicio". About isn't nested under Inicio the way a game page is; it's a
  sibling top-level page, so a crumb ("Inicio / Quiénes Somos") implied a parent/child relationship
  that doesn't exist and read as disharmonious. Crumbs stay reserved for Detalle.
- Logo, theme toggle, and sticky scroll-tint behavior (flat background fade-in, no blur) stay
  identical across all three states.
- **The logo is a real "go home" link on every page** (`onclick` → catalog), not inert `href="#"` —
  the universal way back, present everywhere, independent of the crumb/nav-links.

**Vocabulary: two names on purpose, not drift.** "Inicio" is the nav item's wayfinding label
everywhere it appears (`.links`, the mobile drawer) — a "take me home" action, same as clicking the
logo. "Ludoteca" (a real Spanish word for a game/toy lending library — fits the club's actual lending
angle far better than "Catálogo," which read e-commerce) is the *name* of that section, used only
where a page is naming it rather than linking to it — currently that's exclusively Detalle's
breadcrumb. This is deliberately different from every other naming decision in this shell (which was
always "stop having two words for the same thing") — here the two words mean two different things
(an action vs. a name), so keeping them distinct is correct. "Quiénes Somos" replaced "Acerca de"
everywhere as real product chrome — "El Club" was rejected as redundant with the "PUKLLAY CLUB"
wordmark already in the logo, "Nosotros" alone as too cold.

**Header balance: don't let a flex-grow element eat space its own content doesn't fill.** The
original bug (Round 4): `.links` had `flex: 1`, so it grew to consume all remaining row width, but
its `<a>` children stayed left-aligned inside that grown box — the empty space landed as a dead gap
*after* the last link, not evenly distributed. Fixed three ways: (1) `.links` is `flex: 0 0 auto`
(natural width, doesn't swallow space it doesn't use); (2) on Catálogo, `.search` itself grows
(`flex: 1 1 auto; max-width: 360px; margin-left: auto`) to actually fill the gap; (3) the theme toggle
gets its own `margin-left: auto` (scoped to the real header only, not the drawer's reused
`.theme-toggle` close button) as a universal fallback — load-bearing on Quiénes Somos, which has
neither a crumb nor a search box to consume leftover space; a no-op on Catálogo/Detalle where
search/crumb already do.

**Content-width alignment: every section shares the exact same 1280px box as the header.** Capping
the header/footer to `max-width: 1280px` without capping everything else the same way created a new
bug: catalog shelves and the detail page's "Juegos similares" rail had padding only, no max-width, so
they visibly overflowed past the header/footer edges on a wide monitor. Fixed by giving every content
section (`.row-header`, `.rail-wrap`, the footer) the identical `max-width: 1280px; margin: 0 auto`
recipe — **and the padding has to live on the same element as the max-width, not on an outer wrapper
around it**, or the two nest and double-inset (found as a second instance of this exact bug in the
footer: `.footer-d` had its own horizontal padding outside `.footer-row`'s max-width box).

**Footer: one single row, no divider — not a two-tier Mission Band.** The original two-tier design
(a full-bleed colored persuasion band over a thin utility bar) read as two visually mismatched
weights stacked, not one footer. Replaced with a single flex row, two natural-width clusters
(`justify-content: space-between`, same two-cluster recipe validated on the header): **left** — brand
mark + Club links (FAQ/Contacto/Juntadas) laid out horizontally, not stacked; **right** — social
icons + a de-emphasized meta line. No border/divider splits it into pieces. Content was also trimmed:
a redundant "Explorar" link column (it exactly duplicated the header's own nav links) and a full
mission paragraph (redundant with the hero/header's own pitch) were both cut — the footer only
carries what the header doesn't.

**BGG attribution stays present but de-emphasized, per compliance + explicit direction.**
BoardGameGeek's terms require a visible "Powered by BGG" mention on any public page surfacing their
data — that requirement doesn't go away, but nothing says it has to be a bordered, backgrounded
"badge" competing visually with the rest of the footer. Demoted to plain small-print text next to the
copyright (`© 2026 Pukllay Club · datos de BoardGameGeek`), underlined, no box — still legible and
clickable. **The sketch's badge/text is a placeholder** — confirm the exact required wording/format
against BGG's current API/brand terms before shipping.

**Social icons are real minimal line-icons, not text-letter badges.** Replaced "IG"/"WA"/"DC" text
abbreviations with minimal stroke-SVG glyphs (Instagram/WhatsApp/Discord) in the same 32px circle
chrome, using `currentColor` so the existing hover-recolor (muted → primary background, white icon)
keeps working with no extra CSS.

**Isologo placeholder** (unchanged from sketch 003): no vector isologo asset exists in the repo yet —
the sketch uses a hexagon placeholder mark so header proportions are right. Swap in the real isologo
SVG when it exists; no structural change needed.

**Mobile Footer: Reduced to BGG Compliance Only (sketch 044).** Real-device feedback on the shipped
`≤480px` footer (already tightened once by quick task 260901-ty6: shorter gap, smaller wordmark,
smaller link text) still read as too heavy and unbalanced against the page's left-aligned content.
Two rounds of alignment-only and content-reduction variants (A–G — centering tweaks, one-line
brand lockup, icon-only mark, a bounded card frame) were all rejected as indecisive; the user's own
framing broke the stalemate: *"the only thing I need there is the BGG compliance."* That framing plus
this file's own since-resolved open item ("confirm the exact required wording/format against BGG's
terms before shipping" — resolved: it's exactly "Powered by BGG" + logo, linking to
boardgamegeek.com, per the shipped `bgg_attribution/1` component's documented D-04 decision)
converged on the winning direction: **on `≤480px` only, the footer is nothing but the BGG
attribution line** — brand name, tagline, copyright, and the FAQ/Contacto/Juntadas nav links are
all removed. Verified via grep (not assumed) that those three links exist nowhere else in the app —
removing them from the footer doesn't make the About page unreachable, but it does remove the direct
jump to its FAQ/Contact/Meetups sections. Accepted as a known, deliberate tradeoff, not an oversight.
Desktop's two-cluster footer (`>480px`) is completely unaffected by this change.

## What Was Tried and Rejected

- **A sticky shelf-jump index bar** (Round 7), pinned directly under the already-sticky header,
  pointing at the catalog's real shelf titles. Removed (Round 8): a second sticky bar read as chrome
  overload, and this project's own reference point (Netflix's row-first catalog) doesn't have one
  either — people just scroll past shelves to browse. No replacement; shelves are reachable by
  scrolling like everything else.
- **A crumb for Quiénes Somos** ("Inicio / Acerca de") — see Design Decisions above; rejected because
  About isn't a drill-down.
- **"Catálogo"** as the section name (reads e-commerce) and **"Colección"** (considered, passed over —
  doesn't carry "Ludoteca"'s lending connotation).
- **"El Club"** and **"Nosotros"** for the about nav label — redundant with the logo wordmark, and
  too cold, respectively.
- **Two-tier Mission Band footer** — see Design Decisions above; the two visual weights read as two
  footers, not one.
- **Mobile footer variants A–G (sketch 044)** — alignment-only tweaks (centered-tightened,
  left-aligned, hybrid) were rejected as indecisive ("anyone feels correct... something clear?");
  content-reduction variants that still kept the brand name and/or nav links (one-line lockup,
  icon-only mark, a distinct bounded card, "minimal but keeps links") were all superseded once the
  BGG-only requirement was made explicit. See "Mobile Footer" above for the winner (H).

## CSS Patterns

```css
/* Header shell — full-bleed bar, content capped/centered inside it */
.app-nav { position: sticky; top: 0; z-index: 100; background: var(--color-bg); border-bottom: 1px solid transparent; }
.app-nav-inner { display: flex; align-items: center; gap: var(--space-6); max-width: 1280px; margin: 0 auto; padding: var(--space-3) var(--space-6); }
.app-nav .brand { display: flex; align-items: center; gap: var(--space-2); flex: 0 0 auto; text-decoration: none; }
.app-nav .links { display: flex; gap: var(--space-4); flex: 0 0 auto; } /* natural width — does not swallow space */
.app-nav .links a.active { border-color: var(--color-primary); color: var(--color-primary); }
.app-nav .crumb { flex: 1; display: flex; align-items: center; gap: 6px; font-size: var(--text-sm); color: var(--color-text-muted); }
.app-nav .search { flex: 1 1 auto; min-width: 160px; max-width: 360px; margin-left: auto; /* grows to fill the gap */ }
.app-nav-inner .theme-toggle { margin-left: auto; } /* scoped to the real header, not the drawer close button */
.app-nav.scrolled { background: color-mix(in srgb, var(--color-bg) 94%, transparent); box-shadow: var(--shadow-sm); }

@media (max-width: 480px) {
  .app-nav .links, .app-nav .search { display: none; }
  .app-nav .crumb { flex: 0 1 auto; min-width: 0; overflow: hidden; }
  .app-nav .crumb .sep, .app-nav .crumb .current { display: none; }
  .app-nav .crumb a { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; }
  .app-nav .crumb a::before { content: '‹ '; }
}

/* Footer — one row, two natural-width clusters, no divider */
footer.pk-footer { background: var(--color-surface); border-top: 1px solid var(--color-border); margin-top: var(--space-8); }
.footer-d { padding: var(--space-4) 0; }
.footer-d .footer-row { max-width: 1280px; margin: 0 auto; padding: 0 var(--space-6); display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: var(--space-3) var(--space-6); }
.footer-d .footer-left, .footer-d .footer-right { display: flex; align-items: center; gap: var(--space-6); }
.footer-links { list-style: none; margin: 0; padding: 0; display: flex; gap: var(--space-4); flex-wrap: wrap; }
.footer-social a { width: 28px; height: 28px; border-radius: 50%; border: 1px solid var(--color-border); display: flex; align-items: center; justify-content: center; color: var(--color-text-muted); transition: all var(--duration-fast) var(--ease-standard); }
.footer-social a:hover { background: var(--color-primary); color: var(--color-primary-content); border-color: var(--color-primary); }
.footer-meta { font-size: var(--text-xs); color: var(--color-text-muted); white-space: nowrap; }
.bgg-note { color: inherit; text-decoration: underline; text-decoration-color: var(--color-border); text-underline-offset: 2px; }
.bgg-note:hover { color: var(--color-primary); text-decoration-color: currentColor; }

/* ≤480px: footer reduced to the BGG attribution line only (sketch 044, winner H).
   .footer-left (brand + nav links) and .footer-social are hidden entirely;
   .footer-copyright is hidden so only .bgg-note remains inside .footer-meta.
   Desktop (>480px) keeps the two-cluster layout above, completely unchanged. */
@media (max-width: 480px) {
  .footer-d .footer-row { padding-top: var(--space-2); padding-bottom: var(--space-2); }
  .footer-d .footer-left,
  .footer-social,
  .footer-copyright,
  .footer-dot { display: none; }
}
```

## HTML Structures

```html
<div class="app-nav" data-scroll-nav>
  <div class="app-nav-inner">
    <a class="brand" onclick="goHome()">...logo + wordmark...</a>

    <!-- Catálogo state -->
    <div class="links" data-catalog-only>
      <a class="active">Inicio</a>
      <a onclick="showAbout()">Quiénes Somos</a>
    </div>
    <div class="search" data-catalog-only>...</div>

    <!-- Detalle state -->
    <div class="crumb" data-detail-only>
      <a onclick="goHome()">Ludoteca</a><span class="sep">/</span><span class="current">{Game Name}</span>
    </div>

    <!-- Quiénes Somos state — nav-links, NOT a crumb -->
    <div class="links" data-about-only>
      <a onclick="goHome()">Inicio</a>
      <a class="active">Quiénes Somos</a>
    </div>

    <button class="theme-toggle">...</button>
  </div>
</div>

<footer class="pk-footer footer-d">
  <div class="footer-row">
    <div class="footer-left">
      <a class="footer-brand-mark">...logo + wordmark...</a>
      <ul class="footer-links"><li><a>FAQ</a></li><li><a>Contacto</a></li><li><a>Juntadas</a></li></ul>
    </div>
    <div class="footer-right">
      <div class="footer-social">...instagram/whatsapp/discord icons...</div>
      <span class="footer-meta"><span class="footer-copyright">© 2026 Pukllay Club</span> <span class="footer-dot">·</span> <a class="bgg-note">datos de BoardGameGeek</a></span>
    </div>
  </div>
</footer>
```

## What to Avoid

- Don't fork the header into separate per-page components — one component with state-driven content
  (nav-links vs. breadcrumb vs. nav-links-again) keeps scroll-tint/logo/theme-toggle behavior from
  drifting between pages.
- Don't give a page a breadcrumb unless it's a genuine drill-down. About-style sibling top-level
  pages get the same nav-links row as the page they're a sibling of, not a crumb.
- Don't let a `flex: 1`/flex-grow element consume space its own content doesn't visually fill —
  either give the *actual* filler element the grow, or fall back to `margin-left: auto` on whatever
  should land at the far edge.
- Don't cap the header/footer's width without capping everything else on the page to the same value
  — a real, twice-repeated bug (see `layout-navigation.md`, and the footer's own padding-vs-max-width
  nesting mistake above).
- Don't ship the sketch's placeholder BGG mention as the real compliance-approved wording/asset —
  **resolved**: the shipped `bgg_attribution/1` component uses the real required wording ("Powered by
  BGG" + logo, linking to boardgamegeek.com), confirmed against BGG's own terms.
- Don't let a footer's visual weight go unchecked against sparse pages — the original two-tier design
  specifically looked footer-heavy under a thin page; check the thinnest page, not just the richest.
- On mobile specifically, don't assume every desktop footer element earns its place just because it's
  already there — re-litigate against the actual compliance requirement (sketch 044: only the BGG
  line survived that test) rather than only trimming spacing/alignment around unchanged content.

## Origin
Synthesized from sketch 011 (full-shell-composition), superseding sketch 003's original design after
9 rounds of revision (shell composition → mobile fixes → header/footer rework → content-width
alignment → vocabulary pass).
Source file available in: `sources/011-full-shell-composition/`

Mobile footer section synthesized from sketch 044 (mobile-footer-balance, winner H, 2026-09-01/02) —
two rounds of variants (A–G) plus real-device feedback and a codebase grep for the FAQ/Contacto/
Juntadas links' only usage. Desktop footer unaffected.
Source file available in: `sources/044-mobile-footer-balance/`
