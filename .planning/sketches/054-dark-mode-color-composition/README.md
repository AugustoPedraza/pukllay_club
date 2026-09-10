---
sketch: 054
name: dark-mode-color-composition
question: "The shipped dark theme (assets/css/app.css's `dark` daisyUI block) reads as too dark. Two questions in sequence: (1) is the base bg/surface/surface-2 ladder too low, too flat, too chromatic, or is the near-black-to-near-white text blowout the real problem — and (2) once that's fixed, does the dark theme's soft-lavender `--color-primary` still feel right, or should it move toward something warmer and more professional within the same violet brand family?"
winner: "A (Lifted Ladder) + W2 (Deep Jewel) — base ladder raised (bg #2F154E / surface #391B62 / surface-2 & border #462278), primary shifted to a deeper, more saturated magenta-violet (#8C2BB6) with white primary-content, secondary/accent-bg/accent-text re-derived alongside it"
tags: [dark-mode, color, palette, theme, contrast, accessibility, brand, primary]
---

# Sketch 054: Dark Mode Color Composition

## Design Question

Round 1 (base ladder): the shipped dark theme's `--color-base-100: #170A26` sits at roughly 9%
lightness with a near-black-to-near-white blowout against `--color-base-content: #F3ECFA`, and a
barely-separated 3-step surface ladder (`#170A26` / `#22103A` / `#2F1750`). Which reading of "too
dark" is correct — is the ground itself too low, is the surface ladder too flat to read as
elevation, are the bases too chromatic/muddy, or is the near-black-to-near-white text jump the
real culprit?

Round 2 (primary warmth, developer-directed follow-up after round 1's decision): with the base
ladder settled, does the dark theme's `--color-primary: #A97FD1` (soft, cool lavender) still feel
right, or should it move toward "something warm and professional, within our brand identity" —
i.e. richer/more saturated within the existing violet-magenta family, not a different hue
altogether?

## Winner: A (Lifted Ladder) + W2 (Deep Jewel)

Picked in two rounds, each a direct pick (no synthesis needed — the winning base and the winning
primary set were each chosen outright from the options presented):

**Round 1 — base ladder.** Four hypotheses were tested against the shipped `Control`, each with a
live WCAG contrast readout (text/bg, muted/bg, text/surface, primary-content/primary) and a CLI
oracle (`contrast-check.mjs`) gating all four at 4.5:1:

- **Control ("Hoy")** — today's shipped values, reproduced for comparison. `bg #170A26 / surface
  #22103A / surface-2 & border #2F1750`.
- **A — Lifted Ladder (WINNER)** — the ground is simply too low: raise all three base steps
  together, same hue/chroma relationship, same relative step spacing. `bg #2F154E / surface
  #391B62 / surface-2 & border #462278` (bg luminance 0.0169, ~3.1x Control's 0.0054).
- **B — Elevated Surfaces** — the ground is fine, the ladder is flat: keep `bg` near today's,
  widen the surface steps. `bg #170A26 (unchanged) / surface #3D2163 / surface-2 & border
  #58358D`.
- **C — Quieter Ground** — the bases are too chromatic/muddy: pull chroma toward near-neutral
  charcoal. `bg #211B27 / surface #2D2735 / surface-2 & border #3C3546` (bg luminance 0.0125).
- **D — Softened Ink** — the ground is fine, the blowout is the problem: keep the bases, step text
  down (`#F3ECFA -> #E0D7EA`), lift muted (`#B8A6CC -> #C6BCD2`) and accent
  (`accent-bg #3D2A56 -> #4E376C`, `accent-text #E4D3F5 -> #D1BCE6`).

Developer picked **A** directly. All 5 variants passed the 4.5:1 floor; A was chosen for
perceptually lifting the whole ground while preserving the palette's existing hue/chroma
character rather than flattening it (C) or leaving the ground untouched (B/D).

**Round 2 — primary warmth.** With A's ladder held fixed, 3 candidates shifted
`--color-primary`/`--color-secondary`/`--color-accent-bg`/`--color-accent-text`/
`--color-primary-content` toward a warmer, more saturated violet-magenta (never a different hue
family), alongside an `A` reference frame showing today's lavender unchanged on the new ladder:

- **A (reference)** — `primary #A97FD1` (today's lavender, unchanged).
- **W1 — Warm Lift** — modest hue shift (270°→278°, toward magenta), lightness held close to
  today's. `primary #B073D3`, `primary-content #2F154E` (dark ink, 4.66:1).
- **W2 — Deep Jewel (WINNER)** — bigger hue shift (270°→282°) + much more saturation, deeper/
  darker — closer in character to the light theme's own rich `#3D096D` primary. `primary
  #8C2BB6`. This depth breaks the dark-ink-on-primary pattern (a dark ladder color can't clear
  4.5:1 against a primary this saturated/deep), so it flips to **white** `primary-content`
  instead — the same convention the light theme already uses for its own deep primary (white text
  on `#3D096D`). 6.70:1, the highest contrast margin of any candidate tested.
- **W3 — Warm Bright** — same hue family as W1, pushed lighter for a punchier CTA, dark ink kept.
  `primary #BA80DB`, `primary-content #2F154E` (5.38:1).

Developer picked **W2 — Deep Jewel** directly: the richer, more saturated, deeper primary reads
as "warm and professional" in a way the subtler W1 shift didn't, and the white-ink CTA text gives
it the best measured contrast margin of the three warm candidates.

### Full winning token table (13 tokens — this is the follow-up implementation task's input)

| Sketch token | Value | Maps to (`assets/css/app.css` daisyUI var) |
|---|---|---|
| `--color-bg` | `#2F154E` | `--color-base-100` |
| `--color-surface` | `#391B62` | `--color-base-200` |
| `--color-surface-2` | `#462278` | `--color-base-300` |
| `--color-border` | `#462278` | `--color-base-300` |
| `--color-text` | `#F3ECFA` | `--color-base-content` |
| `--color-text-muted` | `#B8A6CC` | `--color-neutral` |
| `--color-primary` | `#8C2BB6` | `--color-primary` |
| `--color-primary-content` | `#FFFFFF` | `--color-primary-content` |
| `--color-secondary` | `#642C77` | `--color-secondary` |
| `--color-accent-bg` | `#3A1F47` | `--color-accent` |
| `--color-accent-text` | `#EBD7F4` | `--color-accent-content` |
| `--color-danger` | `#E06B90` | `--color-error` (unchanged from today) |
| `--color-success` | `#5FBE95` | `--color-success` (unchanged from today) |

Measured contrast (all pass the 4.5:1 floor, verified by `contrast-check.mjs`):

| Pair | Ratio |
|---|---|
| text / bg | 13.59:1 |
| muted / bg | 7.00:1 |
| text / surface | 12.07:1 |
| primary-content / primary | 6.70:1 |

**Note:** only the dark theme was revised. Light mode (`assets/css/app.css`'s `name: "light"`
block, `themes/default.css`'s `:root` block) was not touched or re-examined in this sketch — its
`--color-primary: #3D096D` / `--color-primary-content: #FFFFFF` pairing is untouched and was only
referenced as a design precedent (the winner's white-on-deep-primary pattern mirrors it).

This sketch stays throwaway/sketch-only: `assets/css/app.css` and
`.planning/sketches/themes/default.css` were verified byte-identical to their pre-task state at
every task boundary (`git diff --quiet` gate + `check-theme-drift.sh` regression, both passing).
**Implementing this winner in production — editing `assets/css/app.css`'s dark theme block, then
re-syncing `themes/default.css` and re-running `check-theme-drift.sh` — is a separate, explicit
follow-up quick task, not part of this one.**

## How to View

```
open .planning/sketches/054-dark-mode-color-composition/index.html
```

(File-protocol previews are blocked in some browser setups — if it opens blank, serve
`.planning/sketches/` with any static file server and open it over `http://`, the same note every
prior sketch README carries.)

The page now shows only the final winning composition (round 1's and round 2's other 8 variants
were trimmed from `index.html` once the decision landed — their full hex values and hypotheses are
recorded above). Use the theme selector in the bottom-right toolbar only as a sanity check that
light mode is unaffected — it is not under revision here.

## What to Look For

- One phone-width composed screen (header, real photo, two game cards, accent band, CTA + muted
  line, footer) rendered with the final palette.
- The live contrast readout at the bottom of the frame: all four ratios pass (green ✓).
- The CTA button, brand wordmark, header icon dot, and the two card-poster gradients all carry the
  new deeper, more saturated magenta-violet primary with white CTA text — this is what
  `--color-primary` touches everywhere in the real app.
