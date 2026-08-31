---
sketch: 039
name: ficha-tecnica-creators
question: "How should Ficha técnica handle a dropped Edad mínima, navigable Diseñadores/Ilustradores, and an 'Avanzado' label that isn't a real section?"
winner: "Sobre el juego (2-col creators, outline pills) + Comunidad BGG (plain text, no container)"
tags: [detail, ficha-tecnica, creators, gap-closure]
---

# Sketch 039: Ficha Técnica & Creators

## Design Question
Phase 01.3 UAT (Gap G-01.3-1) flagged four things in the ficha técnica block: Edad mínima adds no
value, Diseñadores/Ilustradores should be navigable, "Avanzado" isn't a semantic section name, and
desktop should use a two-column layout for the creators. This sketch answers: what does the fixed
block look like, and how far should the restructuring go?

**Flagged gap, not pure CSS:** `Diseñadores`/`Ilustradores` link to `/?designers=`/`/?artists=`,
following the page's existing filter-linked-chip pattern — but neither param is wired in
`CatalogLive.Index` yet. This is a real implementation follow-up. Also corrects a stale note in
`detail-page-layout.md`: the `artists` field *does* exist on `Game` now (added since that doc was
written) — it's not a missing schema field.

**Field/font parity, verified against the real code (not assumed):** "Sobre el juego" covers every
field `ficha_tecnica?/1` (show.ex:1190) gates — `year_published`, `designers`, `artists` — nothing
dropped except `min_age` (removed per feedback). "Comunidad BGG" covers everything
`advanced_stats?/1` (show.ex:1204) gates — `bgg_weight`, `bgg_rating`, `bgg_rank` — plus the
standalone `bgg_id` link, folded into "Fuente: BoardGameGeek" (keeps `bgg_id`'s own `:if` guard —
~9% of the catalog has none). Fonts: only the `<h2>` uses the display face (Bebas Neue); every
label/value/pill inherits the body face (Inter), matching production's
`.pk-section-heading`/`.pk-spec-row`/`.pk-pill` exactly.

## Winner
**"Sobre el juego"** — año + two-column Diseñadores/Ilustradores (stacked on mobile), each name an
individually-clickable outline pill (production's actual lightest pill tone —
`.pk-pill`/`.pk-pill-outline`/`.pk-pill-interactive`, not a heavier solid fill). **"Comunidad BGG"**
— no card, no pills, no border: a small muted label, then peso/valoración/ranking as plain
normal-weight text (not bold/colored — that read as too loud), then "Fuente: **BoardGameGeek**"
where the site name itself is the BGG link (no separate "Ver ficha completa" CTA).

## How to View
open .planning/sketches/039-ficha-tecnica-creators/index.html

## Round History

**Round 1 — structure:**
- A: Minimal Diff — 2-col grid, Edad mínima dropped, creators as pill links, "Avanzado" promoted to
  its own section (still called "Estadísticas BGG").
- B: Two-Column Creators — same, but Diseñadores/Ilustradores side by side on desktop. **Picked.**
- C: Full Section Split — B + Ficha técnica/Estadísticas BGG as two fully independent sections.

**Round 2 — "Ficha técnica"/"Estadísticas BGG" read as spec-sheet jargon, not human-friendly, per
the project's core value (teach a casual player in plain Spanish, not hobbyist vocabulary):**
- D: Plain-Language Headings — B's layout, renamed headings ("Sobre el juego" / "Opinión de la
  comunidad").
- E: Community Rating Card — BGG data as a bordered card with 3 big-number tiles. **Picked, flagged
  too heavy.**

**Round 3 — "the Community Rating card should have less weight":**
- Stripped the card's border/background/shadow entirely (matches sketch 037's own "don't default to
  a bordered container" rule) and shrunk the tile numbers to small inline text. **Feedback: now reads
  as "lost" — too quiet.**

**Round 4 — "Plays a better balance" (multiple iterations):**
- F: Labelled Row — small dt-style "Comunidad BGG" label above the bare row.
- G: Soft Background Strip — tinted `color-mix` fill, no border/shadow.
- H: Bigger Numbers, Still Bare — larger type scale instead of chrome.
- G+H (requested synthesis) — flagged: broke the page's own 32px/8px rhythm with a bespoke padding
  value.
- I: Pill Semantic — BGG stats reuse the same pill as creator names. **Feedback: pills too heavy**
  (v1 used a solid accent fill) → rebuilt as the actual production outline-pill tone (v2). Accepted
  as better, but…
- J: No Pills, Plain Text — Comunidad BGG drops pills entirely, back to plain text under the label.
  v1's bold `--color-primary` numbers still broke balance → v2 dropped to normal body-text weight.
  **Accepted as "better."**
- Copy: "Según la comunidad de BoardGameGeek" → "Fuente: BoardGameGeek" (simpler).
- Final: removed the separate "Ver ficha completa" link — "BoardGameGeek" itself is now the link.

## What to Look For
- Multiple illustrator pills wrapping — does that hold up with 3 names, and would it survive more?
- Check both themes (🌙/☀ toggle) — outline-pill border contrast in dark mode, where
  `--color-border` sits close to `--color-bg`.
