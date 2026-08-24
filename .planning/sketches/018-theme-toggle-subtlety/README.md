---
sketch: 018
name: theme-toggle-subtlety
question: "The bare-icon theme toggle (sketch 014 winner D) matches the social icons' rest color exactly, and its active state can outweigh them. How should it read as clearly subordinate to social links?"
winner: "B"
tags: [footer, theme-toggle, hierarchy, accessibility]
---

# Sketch 018: Theme Toggle Subtlety vs Social Icons

## Design Question

Follow-up to sketch 014 (winner D: bare icons, no card, monochromatic). That sketch solved
*footprint* — the toggle stopped reading as a boxed widget bolted onto the row. It did not solve
*weight relative to its neighbors*: the shipped toggle's rest-state icon color
(`--color-neutral` / `--color-text-muted`) is identical to the social icons' rest color, and its
active state jumps to full `--color-primary` + underline — which can make the "on" icon heavier
than any social icon at rest.

Raised during the `footer-desktop-imbalance` debug session (2026-08-23/24): after that session
shipped a spacing/alignment fix, the user looked at the result and said the theme toggle's 3 icons
carried the same visual weight as the social icons row, and asked for it to be de-emphasized —
"Social links are more relevant, aren't?"

## How to View
```
open .planning/sketches/018-theme-toggle-subtlety/index.html
```

## Variants
- **A: Fainter, Unchanged Active** — one lever: rest-state icon color faded ~55% toward the
  surface. Active state and icon size untouched. Tests whether dimming idle icons alone is enough.
- **B: Fainter + Smaller + Toned Active** — three levers together: same faded rest color as A,
  glyph size matched down to the social icons' own 14px (from today's 17px), and the active
  indicator toned to a muted-primary tint with a shorter underline so even "on" doesn't outweigh a
  hovered social icon.
- **C: Opacity Envelope** — single lever applied to the whole control (icons + "Tema" label) as a
  unit: 50% opacity at rest, full opacity on hover or keyboard focus. The common "utility chrome
  recedes until touched" pattern (GitHub docs, VS Code status bar).

All three keep all 3 states (system/light/dark) — collapsing to a 2-state toggle was already
tested and rejected in sketch 014 (would silently drop the live OS-following behavior). All three
keep the "Tema" label — it exists for discoverability (01.1-08-PLAN.md, sketch 017 Round 2). All
three reconstruct the real `.pk-footer-social` / `.pk-theme-toggle` markup and values from
`assets/css/app.css`, not an approximation, so the weight comparison is against shipped reality.

## Winner: B (2026-08-24)

Picked **B — Fainter + Smaller + Toned Active**. A was rejected after live-checking dark theme:
its rest-state icons (faded color, unchanged 17px size) become nearly invisible against the dark
purple background — a real legibility regression, not a hypothetical risk. B's tighter glyph size
(matched to the social icons' own 14px) and toned-down active state read as deliberately subtle
rather than broken, in both themes. C (opacity envelope) was not selected — the discoverability
risk of a control that reads as disabled at rest cuts against the documented reason the "Tema"
label exists in the first place.

### Implemented in quick-260824-7mt (2026-08-24)

Shipped with two measured divergences from this sketch's assumptions, both recorded so a future
reader doesn't mistake them for implementation errors:

- **Fade shipped at 75%, not 55%.** The 55% mix measured 2.25:1 against the light-theme footer
  surface, missing WCAG 2.1 SC 1.4.11's 3:1 non-text-contrast floor (bare icon buttons have no
  border/background, so the glyph is the control's only visual identifier). 75% clears the floor
  in both themes (3.22:1 light, 4.94:1 dark).
- **Social glyphs measured 16px, not 14px.** The sketch believed it was matching the toggle down
  to the social icons' own 14px for size parity; shipped markup has both already at 16px. So the
  toggle's 14px produces subordination (smaller than its neighbor), not the parity this variant's
  prose describes.
- **Underline geometry left unchanged.** Only its color moved to the toned active mix. Variant B's
  absolute inset values were measured on a 32px-wide demo button; the shipped button is 44px wide
  (`min-w-11`, the touch target added by quick task 260821-dah), so those numbers don't transfer
  and a re-derived value would have been an unverified guess.

## What to Look For
- Click through system/light/dark in each variant — does the "on" icon ever outweigh a resting
  social icon?
- Toggle light/dark page theme (bottom-right toolbar) — does the faded rest color stay legible in
  dark mode, or does it disappear entirely?
- Variant C: tab to the theme control with keyboard — does focus-reveal feel intentional, or does
  the control feel broken/disabled before you touch it? This is the accessibility risk specific to
  an opacity-based approach.
- Compare B's 14px glyphs directly against the social icons' 14px glyphs — same size — does the
  toggle still read as operable and distinct enough?
