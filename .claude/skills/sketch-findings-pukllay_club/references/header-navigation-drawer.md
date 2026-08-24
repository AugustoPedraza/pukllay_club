# Header, Navigation & Drawer

**Status: already shipped.** This entire design area — CTA placement, theme toggle, active-nav
treatment, header composition, catalog index/mega-menu, mobile drawer — is implemented in
`lib/pukllay_club_web/components/layouts.ex` + `assets/css/app.css`, not a future target. Sketches
013–021 record the *design rationale*; the file itself now has more detail than any sketch, since
several rounds of real implementation feedback (quick tasks, debug sessions) refined it further
after the sketches were drawn. Treat `layouts.ex`'s own doc comments as the primary source; this
file is an index into them, plus the one confirmed place a sketch's recorded "winner" no longer
matches what shipped.

## ⚠️ Known drift: CTA scope (013/017 vs. shipped reality)

Sketch 013's winner (E) and sketch 017's README both record the CTA as **persistent site-wide**
("CTA scope stays persistent per D-05"). **This is no longer true.** `sumate_cta/1`'s own doc
comment states D-05 was superseded in plan 01.1-08: "Sketch 017 Round 3 reopened it on the
developer's direct, twice-repeated instruction. The CTA is no longer a header element in any
form — not a slot, not a built-in." It now renders **only** on the About page's hero
(`AboutLive`) and, below 480px, in a page-scoped mobile CTA bar. Tests assert it is absent from
`#app-header` on `/` and `/juegos/:id`. If you're implementing anything CTA-related, follow
`sumate_cta/1`'s doc comment, not sketch 013/017's stated winner.

## Design Decisions (as shipped)

**013-E — nav links carry no border/fill at rest; hierarchy comes from position, not weight.**
`.pk-nav-links a` has a transparent 3px bottom border at rest; only the active link (015-A) shows
color. This "restraint by default, weight only on activation" pattern repeats across the header
(theme toggle, CTA) — see 014/018 below.

**014/018 — theme toggle is 3 bare, monochromatic icon buttons (system/light/dark).** No visible
label at rest anywhere — the "Tema" text is `sr-only`, promoted to the control's accessible group
name via `role="group"` + `aria-labelledby` rather than deleted (a real accessibility gain: three
previously-unrelated-sounding buttons now announce as one group). Two shipped divergences from
018's own sketch assumptions, both intentional, not bugs:
- Icon fade at rest is **75%**, not the sketch's 55% — 55% measured 2.25:1 contrast against the
  light-theme footer surface, missing WCAG 2.1 SC 1.4.11's 3:1 floor. 75% clears it in both themes.
- Footer toggle buttons shrink to **28px**; drawer toggle buttons stay at the full **44px** touch
  floor, because the drawer is the sole mobile home for this control below 480px (footer's own
  right cluster is `display: none` there).
- Footer placement follows Vercel Geist's documented convention: "place [a light/system/dark
  control] once per app, in the footer or settings" — validates the footer as the control's
  canonical desktop home rather than the header.

**015-A — active nav link: colored text + a bottom rule offset by padding, not a line hugging the
text.** `.pk-nav-links a[aria-current="page"]` sets both `color` and `border-bottom-color` to
`--color-primary`; both header call sites (`CatalogLive.Index`, `AboutLive`) already emit
`aria-current="page"` — this is purely the consuming CSS.

**017-E — search becomes a 44px icon that morphs into a full search box, not a fixed permanent
box.** One element (`.pk-search-morph`) converts between states — never a trigger + a separately-
visible box. This is what let search spread to *more* pages (Catálogo and Detalle) at the same
time the CTA moved to *fewer* — search became cheap once it stopped needing permanent header real
estate; the CTA was never a space problem, it was a **context** problem (only Quiénes Somos has
made the "join" case by the time a visitor sees it).

**020 — desktop "Explorar categorías" mega-menu, mobile category chip row, same underlying
contract.** Both carry `data-chip-target` on their items — the same attribute — so one scroll-spy
mechanism (`.CatalogNav` hook) highlights whichever is currently visible, desktop or mobile, with
no second parallel implementation. The mega-menu is hand-rolled (not daisyUI's `dropdown`) because
no CSS-only component pairs a dimmed backdrop + document-level Escape + the scroll-spy's
`is-active` class all at once — it reuses the exact `inert`/`aria-expanded`/idempotent-close
pattern the mobile drawer established first.

**021 — drawer's theme+social bottom block: icon-only, centered, no label, no container** (winner
E1, 6 rounds). Social renders first (bare, full-color, unlabeled — content/destinations), a
divider, then Tema last (a config, distinguished by position not decoration). `.pk-drawer-utility`
groups the label + toggle at item-spacing rather than group-spacing — the same fix later needed on
the footer's own right cluster once it was found to have the identical "label as far from its own
buttons as from unrelated content" bug (see `.pk-footer-theme`'s comment block).

**Footer — two peer clusters + a separate legal band, not three concerns crammed into one row.**
Left: brand (wordmark only, `mark={false}` — the isologo belongs to the header alone) + FAQ/
Contacto/Juntadas links. Right: social + theme toggle. **Legal line (© year, BGG attribution) is
its own full-width `.pk-footer-legal` band**, not folded into the right cluster — putting it there
made the row read as "2 concerns left vs. 3 unlike concerns right" (interactive utilities + passive
compliance text). The legal band itself is two separate flex-item spans, not one run joined by
"·" — `justify-content: space-between` over a single flex item is a no-op, so re-merging them
silently reintroduces a mostly-empty band (measured: 19.88% fill at 1 span vs. 100% at 2).

## What to Avoid

- Treating sketch 013/017's "CTA is persistent" as current — it isn't; follow `sumate_cta/1`'s doc
  comment instead
- Re-merging the footer's two legal spans back into one "·"-joined string (silently reintroduces
  the near-empty-band bug)
- A second, parallel scroll-spy mechanism for the mega-menu instead of reusing `data-chip-target`
- Visible "Tema" label text anywhere at rest — it's `sr-only` + `aria-labelledby` in both the
  footer and the drawer, by deliberate, twice-independently-converged decision (018's debug pass,
  021's own 6-round sketch)
- IntersectionObserver for any header/footer scroll-boundary logic — see
  `detail-page-mobile-interaction.md`'s note on why (Chrome throttles it in backgrounded tabs);
  this shell uses a plain `scroll` listener + `getBoundingClientRect()` throughout

## Origin
Synthesized from sketches: 013, 014, 015, 017, 018, 020, 021
Source files available in: `sources/013-header-action-cluster/`, `sources/014-theme-toggle-weight/`,
`sources/015-active-nav-treatment/`, `sources/017-header-composition/`,
`sources/018-theme-toggle-subtlety/`, `sources/020-catalog-index-row/`,
`sources/021-mobile-drawer-theme-social/`
Real implementation: `lib/pukllay_club_web/components/layouts.ex`, relevant `.pk-*` rules in
`assets/css/app.css`
