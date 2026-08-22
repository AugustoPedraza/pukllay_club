---
sketch: 014
name: theme-toggle-weight
question: "The theme toggle is a 3-button segmented control (system/light/dark, 3×44px ≈134px) — the widest single element in the header cluster. Compress it, and if so, how?"
winner: null
tags: [header, theme-toggle, navigation, accessibility]
---

# Sketch 014: Theme Toggle Weight

## Design Question

The shipped `theme_toggle/1` is a 3-way segmented control — system/light/dark — where each button
is `min-h-11 min-w-11` (44px, this project's locked touch-target floor from quick task 260821-dah).
That's ~134px of total width plus a 2px border and card shadow, next to a 44px-tall CTA. This is
the concrete, measurable cause of "too big / breaking rhythm" — not a vague impression.

## How to View
```
open .planning/sketches/014-theme-toggle-weight/index.html
```

## Variants
- **A: Tighter 3-Way Segmented** — keeps all 3 states, strips the heavy chrome (no card shadow,
  thinner border, smaller icons). Same ~134px footprint, lighter visual weight.
- **B: 2-State Icon Toggle** — single 44px button, light/dark only. System preference still applies
  on first visit via `prefers-color-scheme`; loses the persistent 3rd "match system" control once
  someone has toggled manually.
- **C: Icon + Dropdown** — single 44px button at rest showing the active mode's icon; click opens a
  small menu with all 3 options. Same capability as today, not permanently spread across the row.

Every variant keeps each remaining clickable control ≥44px — the project's locked touch-target
floor is never violated, only the *total row width* changes.

## What to Look For
- Compare each variant's footprint directly against the "Sumate" CTA next to it — which one reads
  as a matched pair vs. one element dominating?
- B and C both trade away the always-visible "system" option — is that acceptable, or is explicit
  system-matching a control worth keeping visible?

## Round 2 (2026-08-22): Strip the Container, Not Just the Chrome

Feedback on A: "A variants looks nice but still is overbalanced since takes too much relevancy
(that is related to correct placement defined by 013)." A's lighter chrome (thinner border, no
shadow) wasn't enough — the card/border/background container itself is what makes the toggle read
as its own distinct "control" competing with the CTA, independent of how heavy that container's
styling is.

- **D: Bare Icons, No Card** — same 3 states (system/light/dark), same 44px-per-button touch
  targets, but the container is gone entirely: three bare icon buttons, minimal gap, active state
  marked by a small underline instead of a sliding background pill. Reads as a peer of the nav
  links rather than a boxed settings widget. Identical markup/CSS to sketch 013's Round 2 D/E
  toggle, by design — same component, two contexts.

### What to Look For (Round 2)
- Click through system/light/dark — is the underline sufficient feedback without the sliding pill?
- Does removing the card make the toggle feel like it belongs to the header's navigation, rather
  than a separate control bolted onto the end of the row?
- Cross-check against sketch 013 D/E — same toggle, does it hold up consistently in both?
