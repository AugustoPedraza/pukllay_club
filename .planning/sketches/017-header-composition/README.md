---
sketch: 017
name: header-composition
question: "With 013/014/015 decided (E / D-refined / A), does the full header row still feel overloaded — and if so, what's the real structural alternative? Covers mobile+desktop together."
winner: null
tags: [header, composition, search, navigation, mobile, information-architecture]
---

# Sketch 017: Header Composition

## Design Question

013–016 fixed individual elements (CTA weight, toggle weight, active-link signal) in isolation, at
desktop only. After seeing them, developer feedback stepped back to a bigger question: even with
every element individually calm, does cramming search + CTA + nav-links + theme-toggle into one row
still feel overloaded — and is the row itself the right structure at all? This sketch also explicitly
covers mobile for the first time in this session (prior sketches were desktop-only).

## How to View
```
open .planning/sketches/017-header-composition/index.html
```

## Variants
- **A: Converged Baseline** — today's structure, with 013-E + 014-D + 015-A applied faithfully, at
  both desktop and mobile. Answers "does it still feel overloaded" directly, without editorializing.
- **B: Expandable Search** — search collapses to a bare icon at rest (Netflix/Amazon pattern), expands
  inline on click, dims the rest of the cluster while open.
- **C: Fully Contextual** — search stays Catálogo-only (already validated in 003/011, correctly
  composed here with the new winners for the first time), and nav-links move into a left-side
  brand+nav identity cluster, separated by a divider from a right-side actions cluster.

## What to Look For
- Does A still feel busy once every element is individually fixed, or was "overloaded" actually
  about the individual elements all along?
- Does B's expand/collapse feel fast and legible, especially on mobile where it becomes the sole
  search entry point?
- Does C's two-cluster split (brand+nav vs. actions) make the nav links feel less like they're
  floating without a clear role?

## Composing the Winners (how E/D/A combine)

013-E and 015-A both touch nav-link styling but answer different questions — E is about REST weight
(should anything be bold when nothing is being interacted with), A is about the ACTIVE signal (which
link is the current page). They aren't in conflict once split that way: `.links-plain a` uses E's flat,
borderless treatment at rest, and gains A's exact active-state signal (color + a thick 3px offset
underline) only on the current page's link. This composition wasn't tested in 013–016 individually —
017 is the first place all three winners exist in the same row together.

## A Real Discrepancy Found While Building

The real shipped `assets/css/app.css` (as of quick task 260822-2v9) does **not** implement a
hamburger/drawer today. At ≤480px it hides `.pk-nav-links` outright and shows a separate mobile
filter-chip row instead — no drawer, no hamburger button exists in the shipped code. Sketch 011 (Round
4+) built and validated a hamburger→drawer pattern (search + nav + Filtros trigger, single entry
point), but that pattern was apparently never carried into the actual Phase 01.1 build.

Variant A renders 011's drawer as its mobile baseline (per this round's instruction — it's the last
fully validated mobile pattern for this shell), which means **A's mobile view does not match what's
currently live in production.** This is worth an explicit decision before any of this gets
implemented: either the real code should be brought in line with 011's validated drawer, or the
simpler "hide nav, show chips, no drawer" behavior currently shipped should be treated as the accepted
mobile pattern going forward and 011's drawer treated as superseded. Flagging rather than silently
picking one.

## Variant B's Mobile Call

Documented per this round's instruction to make a judgment call and explain it: on mobile, the search
icon becomes the **only** search entry point. Tapping it opens a full-width overlay across the header
(260px of inline expansion has nowhere to go on a 390px frame), and the hamburger drawer no longer
carries its own duplicate search field — just nav links. Two separate search entry points on one small
viewport (an icon in the header *and* a field inside the drawer) would be redundant chrome competing
for the same job. One icon, reachable without opening the drawer first, is a shorter path to the thing
people actually reach for search to do.

## Variant C's Nav Treatment

Directly responds to "the navigation still looks weird": rather than guess at a single alternative
styling for `.links-plain` in isolation, C changes nav's *position and grouping* instead — paired with
the brand/logo in one left-side cluster (visually separated from the right-side actions cluster by a
thin divider), rather than sitting alone in the middle of an undifferentiated row. The hypothesis: the
"weird" feeling wasn't about how the links themselves were styled (013–015 already addressed that) but
about them having no clear relationship to anything else in the row.
