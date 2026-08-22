---
sketch: 017
name: header-composition
question: "With 013/014/015 decided (E / D-refined / A), does the full header row still feel overloaded, is a row-based structure even right, and should the CTA/theme-toggle live in the header at all? Covers mobile+desktop together."
winner: "E"
tags: [header, composition, search, navigation, mobile, information-architecture, cta-placement, footer]
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

## Round 2 (2026-08-22): Does It Belong in the Header at All?

Even after picking B (Expandable Search) as the overall composition winner, developer feedback was
that the row still feels overloaded, and that nav "breaks rhythm" because Inicio/landing get different
representations of the same idea — prompting a bigger question than styling: should the CTA and theme
toggle be in the header at all, and is there really only one semantic thing "navigation" is doing here?

**Research grounding this round:**
- CTA placement: persistent/sticky header CTAs earn their keep mainly on mobile scroll; on desktop "a
  prominent in-layout button is often enough" *where the value case has already been made* (after a
  hero, after social proof) — not floating in a nav bar with no surrounding context.
- Toggle placement: the footer is specifically called out in UX literature as the conventional
  "affordable area" for utility controls like theme/language switchers, precisely because users already
  expect to find them there.
- Nav semantics: today's header tries to make three treatments (Catálogo nav-links, Acerca de
  nav-links-with-active, Detalle crumb) read as one consistent "navigation" component, but there are
  really only two semantically distinct jobs — top-level peer navigation (Inicio ↔ Quiénes Somos) and a
  drill-down back-affordance (Detalle → back to Ludoteca, which is *not* a peer relationship). Forcing a
  crumb to visually resemble nav-links fights the fact that they're different affordances; a back-link
  is supposed to look different, that's correct signaling, not broken rhythm.

Two existing, already-validated precedents got reused rather than inventing new patterns: sketch
004-about-page's hero (where a join-CTA has actual context) and sketch 005-detail-page's mobile sticky
CTA bar (already-validated, page-scoped CTA reinforcement, not a global mechanism).

### D: Minimal Header
The boldest reduction. Header = logo (home) + one plain "Quiénes Somos" link + Catálogo-only
expandable search (B's exact mechanism). CTA and toggle are both removed from the header entirely.
- **CTA** moves to the Acerca de hero (reusing 004's hero-CTA pattern) — the developer's own research
  question ("maybe just search for catalog and CTA for landing page") applied directly. Mobile gets a
  sticky CTA bar, but scoped to Acerca de only (mirroring 005's per-page, not site-wide, sticky bar) —
  a site-wide sticky bar would just reintroduce "asking before context" on every other page.
- **Toggle** moves to the footer's right cluster, next to the social icons, tagged "Tema" for
  discoverability.
- **Side effect worth naming, not engineered on purpose:** with only one link and one icon left, there's
  nothing left to hide at narrow widths — no hamburger, no drawer. That fell out of the reduction itself
  rather than being a separate mobile decision.

### E: Toggle-Out Only
Isolates one variable against your current favorite (B): identical expandable search, CTA still in the
header, same drawer — the *only* change is the toggle relocating to the footer (same markup/CSS as D's
footer toggle, confirmed byte-identical between the two so neither reads as a different component).
Purpose: D changes three things (CTA, toggle, nav) at once, so it can't isolate which one was actually
driving "still feels overloaded." E changes exactly one thing from B, so the toggle's specific
contribution can be judged on its own.

### F: Nav Semantics Fix
Isolated from the CTA/toggle question on purpose — identical to B in every other respect. The real
finding here: Catálogo and Acerca de already share one `.links-plain` treatment (that was never actually
inconsistent). The genuine mismatch is Detalle's crumb, styled just close enough to nav-links to read as
a third, slightly-off variant of the same thing, when it's actually a different affordance (back
navigation, not peer navigation). Fixed by replacing "Ludoteca / Catan" with a small, deliberately
distinct "‹ Ludoteca" back-caret — muted color, no border, no active-underline, no game-name segment
(the page's own heading already says which game this is). This is exactly the real shipped app.css's own
narrow-viewport crumb collapse behavior (`.pk-nav-crumb a::before { content: "‹ "; }`, today gated to
≤480px) — F asks whether it's simply the right treatment at every width, not a mobile-only concession.

### What to Look For (Round 2)
- D: does identity + one link + search feel like *enough* header? Does the CTA land better with hero
  context around it than it did floating in the header? Does the footer toggle placement feel
  discoverable?
- E: compared directly against B, does removing just the toggle meaningfully calm the row — or does it
  still feel busy, meaning the toggle wasn't the (only) source of the overload?
- F: does "‹ Ludoteca" read clearly as "go back," distinct from Inicio/Quiénes Somos? Does dropping the
  CTA/toggle question from Detalle's fix change how "weird" it feels, versus D/E's structural cuts?

## Round 3 (2026-08-22): E Wins — Real Search-Morph, Mobile-Verified, CTA Landing-Only

The developer picked **E** and closed out the round with three concrete refinements, then asked to
drop the other variants. All applied directly to E; A/B/C/D/F are removed from the live HTML (full
reasoning for each stays recoverable via this README's Round 1/2 sections and git history at
`0338a24`/`9f59023`/`1253a23`).

**1. The search icon now genuinely converts into the input, not two elements swapping.** The earlier
B/E implementation toggled visibility between a separate trigger icon and an expanded input — visually
two things, not one. Rebuilt as a single `.search-morph` element: a 44px circular icon at rest, whose
`width` animates open to 260px on click (this project's own validated motion timing/easing from sketch
006, not a new value), with the magnifying-glass icon sliding to become a leading glyph inside the now-
open pill and a close (✕) button fading in on the trailing edge. Same DOM node, same left anchor point,
throughout — it reads as one element transforming, not a swap.

**2. Verified — not assumed — on mobile.** At the ~390px viewport (checked via the sketch's own
viewport toggle) `.search-morph.is-open` switches to a full-width overlay (`position: absolute; inset:
0`) instead of a fixed 260px pill, since a fixed desktop-sized pill wouldn't leave usable room in a
mobile header. The rest of the row (brand text, nav links) dims to 0.35 opacity while search is open
(`.e-row.search-open`) so the expanding input doesn't visually compete with content it's now overlapping.

**3. CTA is landing-only.** "Sumate" no longer renders in the header on any page — Catálogo and Detalle
now have no CTA at all in the action cluster. It lives only on Acerca de: in the hero (reusing sketch
004's hero-CTA pattern) and, on mobile, in a sticky bar scoped to Acerca de only (mirroring 005's
per-page, not site-wide, sticky bar — this is the second time in this project the developer has pointed
at "CTA should only be where the context justifies it," first in 013's original scope question, now
here).

**Implementation flag, not resolved here:** the real shipped code hardcodes `sumate_cta/1` as an
always-rendered non-slot inside `header_inner/1`, specifically to prevent per-page omission
(`01.1-PATTERNS.md` D-05). Landing-only placement is now the developer's explicit, repeated direction —
implementing this for real means deliberately reopening D-05 (e.g. making the CTA a caller-owned slot
again, with Acerca de being the only caller that renders it), not just moving a template block. Flagged
here so it isn't lost between sketch and build.

### What to Look For (Round 3)
- Click the search icon — does it read as one element transforming, or can you still tell it's two
  things?
- Switch to mobile and try search again — same morph, full-width this time, rest of the row dims.
- Switch pages: Catálogo/Detalle have no CTA at all now; Acerca de has it in the hero, plus (mobile) the
  sticky bar.
