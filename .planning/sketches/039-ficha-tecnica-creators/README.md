---
sketch: 039
name: ficha-tecnica-creators
question: "How should Ficha técnica handle a dropped Edad mínima, navigable Diseñadores/Ilustradores, and an 'Avanzado' label that isn't a real section?"
winner: "Community Rating Row (round 3 lightened version of round-2 winner E)"
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

## Winner
**Community Rating Row** — "Ficha técnica" is renamed "Sobre el juego" (año + two-column
Diseñadores/Ilustradores, collapsing to stacked on mobile). "Estadísticas BGG"/"Avanzado" is dropped
entirely as a section — peso/valoración/ranking render as one quiet inline row of small bold numbers
+ muted labels, no border/background/card, followed by a one-line human context sentence ("Según la
comunidad de BoardGameGeek") and a "Ver ficha completa" link. No spec-sheet framing anywhere in the
BGG data.

## How to View
open .planning/sketches/039-ficha-tecnica-creators/index.html

## Round History

**Round 1 — structure (A/B/C, removed from index.html):**
- A: Minimal Diff — same 2-column grid, Edad mínima dropped, Diseñadores/Ilustradores as pill links,
  "Avanzado" promoted to its own section (then still called "Estadísticas BGG").
- B: Two-Column Creators — same, but Diseñadores/Ilustradores in two side-by-side sub-columns on
  desktop. **Picked** (carried into round 2/3).
- C: Full Section Split — B's two-column creators, plus Ficha técnica/Estadísticas BGG as two fully
  independent sections instead of one grid with an internal sub-label.

**Round 2 — "Ficha técnica"/"Estadísticas BGG" read as spec-sheet jargon, not human-friendly, per the
project's own core value (teach a casual player in plain Spanish, not hobbyist vocabulary) (D/E,
removed from index.html):**
- D: Plain-Language Headings — kept B's layout, renamed headings only ("Sobre el juego" / "Opinión de
  la comunidad").
- E: Community Rating Card — dropped the BGG spec-list for a bordered card with 3 big-number tiles +
  a context line. **Picked**, but flagged as too heavy.

**Round 3 — "the Community Rating card should have less weight" (winner, this file):**
- Removed the card's border/background/shadow entirely — no shared container, matching this
  project's own established rule from sketch 037 ("don't default to a bordered container to make a
  cluster read as grouped — try proximity/rhythm first").
- Shrunk the big display-font tile numbers down to small inline bold numbers with muted labels, so
  the row reads at the same visual weight as the rest of the page, not as a second callout box.

## What to Look For
- Does the inline rating row read clearly at a glance without a labelled section heading over it, or
  does it need at least a quiet visual anchor?
- Multiple illustrator pills wrapping — does that hold up with 3 names, and would it survive more?
- Check both themes (🌙/☀ toggle) — pill contrast against the accent background, row text contrast
  against the plain page background now that there's no card fill behind it.
