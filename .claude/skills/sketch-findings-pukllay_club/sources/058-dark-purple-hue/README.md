---
sketch: 058
name: dark-purple-hue
question: "Dark-theme purple reads fuchsia. The shared --pk-ramp-* is fixed at OKLCh H313.1, while the brand manual's two colors sit at H300.1 (#3D096D) and H308.1 (#7E4CA5). Which hue should the ramp sit on?"
winner: "C"
tags: [dark-mode, color, hue, palette, ramp, brand]
---

# Sketch 058: Dark Purple Hue

## Design Question

The developer reported that the dark-theme purple looks fuchsia. The cause is structural. Every
brand color in both themes comes from `--pk-ramp-*`, which quick task 260910-l7q generated at a
single hue, H313.1. That hue was taken from dark mode's Sumate CTA fill (sketch 054's W2 winner,
`#8C2BB6`), not from the brand manual. The manual's Lila Oscuro is H300.1 and its Violeta is
H308.1, so the ramp sits 5–13° toward magenta. The shift is hard to see at light mode's low
lightness (`ramp-900`). On dark mode's lighter, saturated fills and inks (`ramp-600`, `#C791E5`)
it reads as fuchsia.

## Winner: C (H300)

The developer compared A and C side by side and picked **C**. It uses the same hue as the brand
manual's Lila Oscuro (`#3D096D`, H300.1). A's solid CTA (`#8C2AB7`), most saturated stop
(`ramp-500` `#B739ED`) and brand ink (`#C791E5`) read pink/fuchsia on the dark ground. C's
versions (`#7B2DCE` / `#9959ED` / `#B797F0`) read violet. Contrast is unchanged (every pair
within ±0.06:1 of A), so this was a pure hue call.

### Winning token set (production follow-up input)

Ramp (FLAT, k=0.85, H300, same per-stop lightness as the shipped H313.1 ramp):

| Stop | H313.1 (today) | H300 (winner) |
|---|---|---|
| 50 | `#FAF5FE` | `#F8F6FE` |
| 100 | `#F6EAFD` | `#F1ECFD` |
| 200 | `#EACEFA` | `#DFD3FA` |
| 300 | `#DCADF6` | `#CBB5F6` |
| 400 | `#CE89F3` | `#B896F3` |
| 500 | `#B739ED` | `#9959ED` |
| 600 | `#8C2AB7` | `#7B2DCE` |
| 700 | `#702093` | `#6222A6` |
| 800 | `#551670` | `#4A187F` |
| 900 | `#45105C` | `#3C1269` |
| 950 | `#380B4C` | `#300D56` |

Dark off-ramp roles (hue rotated to 300, L and C held):

| Role | Today | Winner |
|---|---|---|
| `--color-base-100` | `#361148` | `#2E154E` |
| `--color-secondary` | `#642C77` | `#553384` |
| `--color-accent` | `#3A1F47` | `#33224D` |
| `--color-accent-content` | `#EBD7F4` | `#E3D9F9` |
| `--color-neutral` | `#C59CDC` | `#B8A0E5` |
| `--pk-ink-brand` (dark) | `#C791E5` | `#B797F0` |

Light-theme off-ramp roles (`base-300 #E3D3F0`, `base-content #241238`, `secondary #7E4CA5`,
`accent #EDE1F7`, `neutral #6B5B7B`) were not rendered in this sketch. The follow-up task should
decide whether to rotate them too, measured with the same generator. `#7E4CA5` is the manual's
own Violeta and should stay as-is.

Not yet applied to `assets/css/app.css`. That is a separate quick task (see Implementation Note).

## How to View

    open .planning/sketches/058-dark-purple-hue/index.html

Use "Las 4 lado a lado" to compare, or pick one to view it alone (← → keys cycle). The toolbar
button hides the tinted photo so you can judge flat color only.

## Variants

All four use the same FLAT generator: identical per-stop lightness and `C = 0.85·maxC(L,H)`.
Off-ramp dark roles (base-100, secondary, accent, accent-content, neutral, `--pk-ink-brand`) are
hue-rotated with L and C held. **Only hue changes.** Every WCAG pair stays within ±0.1:1 of what
ships today, and all pass.

- **A: H313 (today)**: primary `#8C2AB7`, ink `#C791E5`. Control.
- **B: H305**: primary `#822CC5`, ink `#BE94EC`. Midpoint of the two manual colors; the smallest
  move away from magenta.
- **C: H300**: primary `#7B2DCE`, ink `#B797F0`. Exact Lila Oscuro hue; light primary returns to
  the manual's hue.
- **D: H292**: primary `#6E2FDC`, ink `#AC9AF6`. Past the manual toward blue, to find where it
  starts reading as indigo.

| Pair | A 313 | B 305 | C 300 | D 292 |
|---|---|---|---|---|
| text / bg | 13.61 | 13.59 | 13.62 | 13.60 |
| ink / base-100 | 6.47 | 6.48 | 6.52 | 6.50 |
| ink / base-300 | 4.96 | 4.97 | 5.03 | 5.04 |
| muted / bg | 6.89 | 6.92 | 6.90 | 6.92 |
| white / dark primary | 6.71 | 6.74 | 6.76 | 6.77 |
| white / light primary | 14.17 | 14.17 | 14.16 | 14.20 |

## What to Look For

- The solid Reservar CTA and the brand-ink hashtags/active nav: which still reads as "purple"
  and not pink?
- The Azul card gradient (`ramp-500`) is the most saturated stop and shows the fuchsia most
  clearly.
- Light-mode strip: `ramp-900` changes too, because the ramp is shared. Check that it still
  matches the brand.
- Does D go too blue (indigo/tech-brand) and lose the warmth sketch 054 was after?

## Implementation Note

The ramp is shared, so this is a one-constant change to `HUE` in
`.planning/milestones/v1.0-quick/260910-l7q-.../ramp-audit.mjs`. After that, regenerate the
ramp, rotate the dark off-ramp hexes and `--pk-ink-brand`, and update the H313.1 provenance
comments in `assets/css/app.css`. Follow up with a quick task.
