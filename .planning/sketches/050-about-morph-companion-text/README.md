---
sketch: 050
name: about-morph-companion-text
question: "How should a 'PUKLLAY CLUB' companion wordmark behave alongside the About page's floating isologo during its scroll-morph into the header, so the mark is never text-less?"
winner: "Baked-in companion (~25px, 'V3 — Confident'), mark anchored in-flow with the hero content, eyebrow hide/reveal tied to the same dock-crossing state"
tags: [about, header, motion, isologo, brand-name, wordmark]
---

# Sketch 050: About Morph Companion Text

## Design Question
Backlog todo `2026-09-07-surface-pukllay-club-brand-name-in-content.md`: the site never spells
out "Pukllay Club" as plain text near the isologo mark. Investigation found the header/footer
lockup (`brand_logo/1`) already renders the name as real text everywhere — **except** on the
About page, where the whole header (including that text) stays hidden while the isologo scroll-
morphs down from the hero (sketch 045's approved mechanic), and the hero copy right where the
mark sits ("Club de juegos de mesa · Jujuy" / "Conectá jugando") never says the actual name. A
first-time visitor scrolling About sees a large graphic mark with no text anchor until it docks
into the header.

This sketch does **not** re-litigate 045's morph mechanic (hidden-until-scroll header, live 1:1
tracking, snap-dock at the crossing point — all kept verbatim). It only adds a companion
"PUKLLAY CLUB" wordmark alongside the mark through the scroll.

## How to View
```
open .planning/sketches/050-about-morph-companion-text/index.html
```
Scroll down slowly on each tab to watch the mark travel toward the header and see how its
companion text behaves along the way. Reload (or switch tabs) to reset scroll position — each
tab activation scrolls to top automatically.

## Round 1 — three approaches (superseded)
- **A: Static label, fades early** — text sits below the mark at rest as its own element, fades
  out fast (first third of the scroll).
- **B: Baked-in, travels with the mark** — text lives inside the same box as the isologo image,
  scaling/fading in the exact same proportion as the mark shrinks. **Picked** — feels like one
  piece melting into the header's own wordmark as it docks.
- **C: Fixed chip, crossfades at threshold** — constant-size pill beside the mark, crossfades out
  past ~40% of the scroll travel.

A/C removed from `index.html` (B carried forward only).

## Round 2 — refining B's weight/balance
Feedback on B: render it in the real logo font, with more weight for better balance. Two real
findings while grounding that request:

1. **The shared sketch theme never actually loaded Bebas Neue** — `themes/default.css` only did
   `src: local("Bebas Neue")`, so on any machine without that font installed it silently fell back
   to a generic system sans, which is why the companion text looked thin/wrong. Fixed at the theme
   level (not just this sketch) by adding the real self-hosted `.woff2` as a fallback source,
   referenced via the same relative-path pattern the isologo image already uses. This fixes every
   sketch that renders Bebas Neue, not only this one.
2. **A heavier `font-weight` isn't available** — `assets/css/app.css` explicitly documents that
   Bebas Neue is self-hosted at weight 400 ONLY, and calls out that any heavier value is a silent
   browser-faked bold the codebase deliberately avoids elsewhere. So "more weight" is explored here
   through size, tracking, and composition instead of a fake bold.

Two refinements of B, replacing A/B/C in `index.html`:
- **B1: One line, larger + tighter** — same single-line "PUKLLAY CLUB", bumped size (~30% larger
  relative to the mark) and tighter letter-spacing for a denser, more confident read. **Picked.**
- **B2: Two-line lockup (name + tagline)** — reproduces the header's own real lockup shape (name
  atop a smaller muted tagline) instead of a lone line. Not picked — retired below.

## Round 3 — balancing the whole hero, not just the companion
Feedback on B1: needs "better balance on all the fonts and lines." Clarified scope: rebalance the
companion text together with the hero's eyebrow, H1, and subtext as one coherent stack, not the
floating label in isolation.

Grounding found the real cause wasn't font size in isolation — it was **grouping**. The mark and
companion were positioned against the whole hero *section's* top edge
(`heroEl().getBoundingClientRect()`), while the eyebrow/H1/subtext/CTA centered separately, lower,
in a 92vh section. That left an arbitrary, viewport-dependent gap between the floating brand bit
and the actual message — two disconnected clusters, not one composition.

Fixed the way the real About page does it (`about_live.ex`'s `data-morph-anchor` pattern): an
in-flow spacer as the first child of `.hero`, so the mark's "natural" position now tracks that
spacer instead of the section edge. The flex column's existing `gap`/`justify-content: center`
then centers mark + companion + eyebrow + H1 + subtext + CTA as **one** block with one consistent
rhythm.

On top of that structural fix, the companion text itself was sized down from round 2's 27px to
~21px, so the vertical stack reads as a deliberate scale — companion (21px) → eyebrow (12px,
muted) → H1 (40–72px, the one dominant element) → subtext (18px, muted) — rather than the
companion rivaling the H1 for "biggest text" attention. B2 is dropped; only the refined single
composition remains in `index.html` (no tab bar — nothing left to switch between).

## Round 4 — three sizes within the confirmed structure
Round 3's grouping fix (in-flow anchor) confirmed good. Feedback: "I need some variants" — bring
back a comparison, but only tuning what's left open (companion size/tracking/gap), since the
structural fix isn't being revisited.

- **V1: Compact (~17px)** — smaller, looser tracking, closer to the eyebrow's own quiet register.
- **V2: Balanced (~21px)** — round 3's picked size, kept here as the middle reference point.
- **V3: Confident (~25px)** — larger, tighter tracking — more presence, still below round 2's
  original 27px (which read as competing directly with the H1). **Picked.**

All three share the exact same anchor-based grouping mechanic; only `COMPANION_STYLE`'s
`nameScale`/`nameTracking`/`marginTop` differ per tab.

## Round 5 — eyebrow hides/reveals on the same dock crossing
Feedback: when the isologo "becomes" the header (docks), the hero's eyebrow line ("Club de
juegos de mesa · Jujuy") should disappear — and scrolling back up should reverse it.

Rather than let this happen incidentally from scroll position (which would vary by viewport
height and could leave the eyebrow half-visible or vanish at the wrong moment), the eyebrow now
reads the exact same `docked` boolean that already drives the header reveal and the companion
text's hide. `updateHeaderChrome()` toggles an `.is-docked` class on the eyebrow alongside the
header's own classes, with a matched `opacity` transition — so all three (header in, eyebrow out,
companion out) change at the identical crossing-point instant, symmetric in both scroll
directions for free (since `docked` already flips back on scroll-up).

V3 is the default/active tab now (the round 4 pick); V1/V2 remain navigable for reference.

## Final
Confirmed working (2026-09-07). `index.html` collapsed to the single winning composition —
V1/V2 and the tab bar removed, since there's nothing left to switch between. Winner:
- Companion "PUKLLAY CLUB" baked into the isologo's own box, ~25px at rest, tight tracking,
  scaling/fading in lockstep with the mark as it docks (round 1/2/4's picks).
- Mark anchored to an in-flow spacer so mark+companion+eyebrow+H1+subtext+CTA center as one
  block (round 3's grouping fix).
- Hero eyebrow hides the instant the mark docks and reappears the instant it undocks — reads the
  same `docked` boolean as the header reveal and companion fade, so all three change at the exact
  same crossing-point instant in both scroll directions (round 5).

## What to Look For
- Does the eyebrow's disappearance read as *the same event* as the mark docking — one coordinated
  moment — rather than two things that happen to line up?
- Scroll back up: does the eyebrow reappear at the exact same point the mark undocks?
- Which of the three companion sizes reads as correctly weighted next to the mark — not lost, not
  competing with the H1?
- Does the whole hero read as one composed group at rest in all three, instead of a floating mark
  with a stray gap before the eyebrow/H1 block?
- With the real font loading, does "PUKLLAY CLUB" finally read as the actual brand typeface —
  same weight/character as the header's own wordmark once it docks?
- Check at 375px (mobile) — does the anchor's reserved height feel right for all three, or does
  the largest (V3) start to crowd the eyebrow?
