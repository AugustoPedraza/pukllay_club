# Dark Mode Palette & Brand Ramp

Four sketches form one chain, not four snapshots: **054** set the dark base ladder and picked a
primary; **055** fixed that primary failing WCAG when used as *text*; **056** fixed the
outline-primary *CTAs* failing the same floor; **058** changed the **hue** of the whole shared
ramp, overriding most of 054's literal hexes. Three intervening quick tasks (`260910-hdc`,
`260910-if9`, `260910-l7q`) also rewrote values along the way. **This file states the resolved
end state — what is in `assets/css/app.css` today. Do not implement 054's hexes.**

## Design Decisions

**A colour role is a POSITION on one shared OKLCh ramp, not an independently-typed hex.** Quick
task `260910-l7q` replaced per-theme hand-picked hexes with a single `--pk-ramp-50…950` scale
both themes read from. Envelope is FLAT: one fixed hue and one safety factor across all 11 stops,
`C = 0.85 · maxC(L, H300)` where `maxC` is the maximum in-gamut sRGB chroma at that
lightness/hue. Every stop is pure generator output — none hand-nudged. Before inventing a new
purple, find its ramp stop.

**058 overrode 054's hue: the ramp sits at H300, the brand manual's own Lila Oscuro hue
(`#3D096D`, H300.1).** 054's winning primary `#8C2BB6` was taken from that sketch's own dark CTA
fill, not the manual, and `260910-l7q` then generated the whole ramp at that colour's hue,
H313.1 — 13° toward magenta. The developer reported the dark purple "looks fuchsia." Sketch 058
compared H313 (control), H305, **H300 (winner C)** and H292, holding per-stop lightness and
`k=0.85` fixed so **only hue changed**. Every WCAG pair moved by ≤0.1:1, so this was a pure hue
call, decided by eye: at H313 the solid CTA (`#8C2AB7`), the most saturated stop (`ramp-500`
`#B739ED`) and the brand ink (`#C791E5`) read pink; H300's `#7B2DCE` / `#9959ED` / `#B797F0` read
violet. H292 was drawn to find where it turns indigo. Light theme's roles were rotated onto the
same H300 at the developer's request ("keep consistency with light version to uniform color"),
so no purple in either theme sits off-hue.

**What 058 overrode from 054 — the full delta.** 054's 13-token table is superseded; only
`--color-primary-content` (`#FFFFFF`), `--color-error` (`#E06B90`) and `--color-success`
(`#5FBE95`) survive it byte-for-byte.

| Role | 054's value | Shipped today | Changed by |
|---|---|---|---|
| `--color-base-100` | `#2F154E` | `#2E154E` | `260910-if9` (→`#361148`), then 058 |
| `--color-base-200` | `#391B62` | `var(--pk-ramp-900)` = `#3C1269` | `if9` → `l7q` (joins ramp) → 058 |
| `--color-base-300` (also the border role) | `#462278` | `var(--pk-ramp-800)` = `#4A187F` | same chain |
| `--color-base-content` | `#F3ECFA` | `var(--pk-ramp-100)` = `#F1ECFD` | `l7q`, 058 |
| `--color-primary` | `#8C2BB6` | `var(--pk-ramp-600)` = `#7B2DCE` | `l7q` (`#8C2AB7`), 058 |
| `--color-primary-content` | `#FFFFFF` | `#FFFFFF` | unchanged |
| `--color-neutral` (muted ink) | `#B8A6CC` | `#B8A0E5` | `260910-hdc` (→`#C59CDC`), 058 |
| `--color-secondary` | `#642C77` | `#553384` | 058 |
| `--color-accent` | `#3A1F47` | `#33224D` | 058 |
| `--color-accent-content` | `#EBD7F4` | `#E3D9F9` | 058 |
| `--color-error` | `#E06B90` | `#E06B90` | unchanged |
| `--color-success` | `#5FBE95` | `#5FBE95` | unchanged |

What 054 *did* settle and 058 did **not** touch: the per-step **lightness** of the ladder (054's
"Lifted Ladder" variant A raised all three base steps together — bg luminance 0.0169, ~3.1× the
pre-054 `#170A26`'s 0.0054), the white-on-deep-primary CTA convention (054 round 2's W2 broke the
dark-ink-on-primary pattern because a dark ladder colour cannot clear 4.5:1 against a primary
that saturated, so it flipped to white ink, matching what light theme already did), and all four
pinned contrast floors below.

**Three deliberate purple tiers in dark, one hue, separated by chroma.** This is the single most
load-bearing structural decision to preserve when adding a new dark-mode purple:

| Tier | Token | Value | OKLCh chroma | Role |
|---|---|---|---|---|
| Fill | `--color-primary` | `#7B2DCE` | C0.21 | solid backgrounds only (CTA fill, gradients, wordmark) |
| Interactive ink | `--pk-ink-brand` | `#B797F0` | C0.129 | branded text + border — nav-active, hashtags, outline CTAs |
| Muted ink | `--color-neutral` | `#B8A0E5` | C0.10 | genuinely quiet/secondary text (labels, stats) |

**`--color-primary` can NEVER be text or a border in dark mode.** This is 055's finding and it is
unconditional. Measured against all three ladder tones (055's own matrix, recomputed by WCAG
relative luminance because the original checkpoint only checked `base-100`):

| Candidate | vs base-100 | vs base-200 | vs base-300 |
|---|---|---|---|
| dark `--color-primary` (then `#8C2BB6`) | 2.34:1 FAIL | 2.08:1 FAIL | 1.78:1 FAIL |
| accent-content `#EBD7F4` | 11.63:1 | 10.32:1 | 8.84:1 |
| neutral `#B8A6CC` | 7.00:1 | 6.21:1 | 5.32:1 |
| 054-W1 `#B073D3` | 4.66:1 | 4.14:1 **FAIL** | 3.54:1 **FAIL** |
| 054-W3 `#BA80DB` | 5.38:1 | 4.78:1 | 4.09:1 **FAIL** |

055 rejected "just pick a lighter primary" (C1/C2) precisely because neither clears 4.5:1 on
every surface a text-role primary could land on. Only a separate ink token is unconditionally
safe. 055's own winner (A2, re-point the 17 rules to `--color-neutral`) was correct on contrast
but **wrong on hue** — it collapsed the branded-interactive role to ~38% of light theme's branded
ink chroma, so "Ver detalles" and nav-active read as *disabled*. Quick task `260910-hdc`
superseded it with the dedicated `--pk-ink-brand` token above. **Use `--pk-ink-brand`, not
`--color-neutral`, for anything branded-and-interactive.**

**Outline CTAs are split by role (056, "Option D"), and the split still stands.** All four
outline-primary CTAs failed at 2.34:1/2.08:1. 056 rejected one uniform treatment:
- **Sumate** (hero + closing band — the site's actual primary call to action) gets a **solid
  fill** in dark: `--color-primary` bg + `--color-primary-content` text, 6.70:1 — the same pair
  already proven on the mobile sticky bar. Light mode keeps its outline (`#3D096D` on white,
  14.4:1) and is untouched.
- **`.pk-preview-cta` and `.pk-btn-secondary`** ("Ver detalles", "Reintentar" — genuinely
  secondary) keep the outline and get an **ink swap** on both `color` *and* `border-color`
  (055's rules only touched `color`; none of those 17 were border roles). Originally
  `--color-neutral`; now `--pk-ink-brand` per the same `260910-hdc` correction.
- No `:hover` override needed on the ink-swapped pair: daisyUI's `.btn-outline` excludes `:hover`
  from its own guard, so hover already falls through to the filled `.btn-primary` pair (6.70:1).
  The *solid* variants DO need an explicit `:hover` — `btn-outline`'s fill-on-hover inversion is
  meaningless once the rest state is already filled.

**One physical swatch, two roles.** `--pk-ramp-900` (`#3C1269`) is simultaneously light theme's
`--color-primary`/`--color-accent-content` and dark theme's `--color-base-200`. This is the
FLAT envelope's headline result and the reason FLAT was chosen over the plan's recommended
ANCHORED envelope (ANCHORED missed the join by ΔE 0.0168, just over the 0.012 threshold).

**Four pinned contrast floors — do not "improve" these by eye.** Re-measured post-058 via
`h300-audit.mjs --check`; every one holds at or above its pre-rotation floor:

| Pair | Ratio | Pinned floor |
|---|---|---|
| text `#F1ECFD` / bg `#2E154E` | 13.62:1 | 13.593 |
| muted `#B8A0E5` / bg `#2E154E` | 6.90:1 | 6.847 |
| text `#F1ECFD` / surface `#3C1269` | 12.25:1 | 12.069 |
| white / primary `#7B2DCE` | 6.76:1 | 6.696 |
| `--pk-ink-brand` `#B797F0` / base-100 | 6.52:1 | 4.5 (WCAG 1.4.3) |
| `--pk-ink-brand` / base-200 `#3C1269` | 5.87:1 | 4.5 |
| `--pk-ink-brand` / base-300 `#4A187F` | 5.03:1 | 4.5 |
| white / light primary `#3C1269` | 14.16:1 | — |

## CSS Patterns

The shared ramp, declared once in a plain unlayered `:root` immediately above the theme blocks —
this IS the file's single upstream palette source, never a per-theme copy:

```css
:root {
  --pk-ramp-50:  #F8F6FE;  --pk-ramp-500: #9959ED;
  --pk-ramp-100: #F1ECFD;  --pk-ramp-600: #7B2DCE;
  --pk-ramp-200: #DFD3FA;  --pk-ramp-700: #6222A6;
  --pk-ramp-300: #CBB5F6;  --pk-ramp-800: #4A187F;
  --pk-ramp-400: #B896F3;  --pk-ramp-900: #3C1269;
                           --pk-ramp-950: #300D56;
}
```

Dark theme roles (daisyUI theme block) — on-ramp roles are `var()` reads, off-ramp roles carry a
comment naming their nearest stop and the ΔE that kept them off:

```css
/* name: "dark" */
--color-base-100: #2E154E;              /* off-ramp, nearest ramp-950, dE 0.0208 */
--color-base-200: var(--pk-ramp-900);
--color-base-300: var(--pk-ramp-800);
--color-base-content: var(--pk-ramp-100);
--color-primary: var(--pk-ramp-600);
--color-primary-content: #FFFFFF;
--color-secondary: #553384;
--color-secondary-content: #FFFFFF;
--color-accent: #33224D;
--color-accent-content: #E3D9F9;
--color-neutral: #B8A0E5;
--color-neutral-content: #160A27;
/* semantics never join the ramp — other hues by construction */
--color-info: #7C9AD1; --color-success: #5FBE95;
--color-warning: #D9A24B; --color-error: #E06B90;
```

The branded-interactive ink token — the file's only theme-scoped `--pk-*`. Light is a **variable
read**, not a copied hex, so it can never drift from the brand manual:

```css
:root { --pk-ink-brand: var(--color-primary); }          /* light: #3C1269, 14.4:1 as text */
:root[data-theme="dark"] { --pk-ink-brand: #B797F0; }    /* dark:  L73.9% C0.129 H299.8 */
```

`:root[data-theme="dark"]`, **not** a bare `[data-theme="dark"]`: `data-theme` is set on `<html>`
by `assets/js/theme.js`, so a bare attribute selector ties `:root` on specificity and would
depend on source order; the compound form wins outright.

Branded-interactive usage — text, border, focus ring, and a `color-mix` tint for hover/active
(never a solid fill; `--pk-ink-brand` has no `-content` counterpart because nothing paints with it):

```css
.pk-row-cue        { color: var(--pk-ink-brand); }
.pk-row-link:focus-visible { outline: 2px solid var(--pk-ink-brand); outline-offset: 4px; }
.pk-row-link:hover  .pk-row-cue { border-color: var(--pk-ink-brand);
  background-color: color-mix(in srgb, var(--pk-ink-brand)  8%, transparent); }
.pk-row-link:active .pk-row-cue { border-color: var(--pk-ink-brand);
  background-color: color-mix(in srgb, var(--pk-ink-brand) 14%, transparent); }
```

056's split-by-role, exactly as shipped:

```css
/* Secondary tier — outline kept, ink+border swapped (dark only) */
[data-theme="dark"] .pk-preview-cta,
[data-theme="dark"] .pk-btn-secondary {
  color: var(--pk-ink-brand);
  border-color: var(--pk-ink-brand);
}

/* Primary tier — solid fill (dark only). :not() excludes the sticky bar,
   which already declares the identical pair via its own unscoped class. */
[data-theme="dark"] .pk-sumate-btn:not(.pk-sumate-btn-solid) {
  background: var(--color-primary);
  color: var(--color-primary-content);
  border-color: var(--color-primary);
}
[data-theme="dark"] .pk-sumate-btn:not(.pk-sumate-btn-solid):hover { filter: brightness(1.08); }
```

## HTML Structures

No markup is specific to the palette — the theme is selected by `data-theme` on `<html>`
(written by `assets/js/theme.js`), and everything else resolves through daisyUI roles:

```html
<html lang="es" data-theme="dark"> … </html>
```

```heex
<%!-- secondary CTA: bare daisyUI classes + one .pk-* hook to target from CSS --%>
<button class="btn btn-outline btn-primary pk-btn-secondary">Reintentar</button>
```

`core_components.ex`'s `variant="secondary"` renders `"btn-outline btn-primary pk-btn-secondary"`
— the `.pk-*` hook exists purely so the dark ink-swap has something to select that does not also
match `.pk-sumate-btn` (which carries the same two daisyUI classes).

## What to Avoid

- **Don't implement sketch 054's hex table.** Nine of its thirteen tokens were overridden — the
  base ladder by `260910-if9` and then 058, the primary and text by `260910-l7q` + 058, the muted
  ink by `260910-hdc` + 058. Read the theme block in `app.css`, not the sketch README.
- Don't use `--color-primary` as a text or border colour in dark mode, ever — 2.34:1 / 2.08:1 /
  1.78:1 against the three ladder tones. Use `--pk-ink-brand`.
- Don't fix a primary-as-text contrast failure by picking a lighter primary. 055 measured both
  lighter candidates: neither clears 4.5:1 on every surface a text-role primary could sit on. An
  ink token is the only unconditionally safe answer.
- Don't reach for `--color-neutral` for anything branded or interactive. It is the *muted/quiet*
  ink tier (C0.10) and overloading it is exactly the bug `260910-hdc` had to undo — on dark's
  saturated ground a low-chroma purple reads as "disabled," and it puts two purples in one theme.
- Don't check a dark-mode contrast ratio against `--color-base-100` alone. 055's original
  checkpoint did, and it hid the fact that two candidates fail on base-200/base-300. Check all
  three ladder tones even if today's call sites all happen to sit on base-100 (they do — this app
  uses base-200/300 for borders and hover backgrounds, not surface fills — but the next component
  on a card or modal will not).
- Don't invent a new purple hex. Find its ramp stop, or declare it off-ramp with the ΔE that
  justifies it, following the comment convention already in the theme blocks. A role's on/off-ramp
  membership is decided once, not re-decided every time ΔE happens to cross the 0.012 threshold.
- Don't hand-nudge a ramp stop to preserve a prior value — that is the ANCHORED envelope's
  mechanism, and this project deliberately shipped FLAT instead.
- Don't rotate hue and lightness in the same change. 058 worked because it held per-stop lightness
  and `k` fixed, which is what made "contrast is unchanged, this is a pure hue call" a provable
  claim rather than an assertion.
- Don't give an outline CTA a solid fill just because a sibling outline CTA needed one. 056 split
  by role on purpose: solid fill signals *primary* action; the secondary tier stays outline with
  swapped ink.
- Don't add a `:hover` override to the ink-swapped secondary CTAs — daisyUI's `.btn-outline`
  already falls through to a passing filled hover. Do add one to any *solid* variant, where the
  inherited fill-on-hover inversion is meaningless.
- Don't scope a theme override with a bare `[data-theme="dark"]` when overriding something also
  declared on `:root` — it ties on specificity and resolves by source order.

## Origin
Synthesized from sketches: 054 (2 rounds — base-ladder hypotheses Control/A/B/C/D with a
`contrast-check.mjs` CLI oracle gating all at 4.5:1, then primary-warmth candidates A/W1/W2/W3;
winner A + W2), 055 (real affected elements, not a swatch grid; 4 candidates + the full-surface
contrast matrix found while building it; winner A2, later superseded by `--pk-ink-brand`), 056
(4 candidates across all 4 real outline CTAs; winner B, "split by role"), 058 (4 hues
A/B/C/D at fixed lightness and chroma; winner C, H300). Resolved end state cross-checked against
`assets/css/app.css` (ramp block, both daisyUI theme blocks, the `--pk-ink-brand` token and its
dark override, and the two 056 rule pairs) rather than taken from the READMEs.
Source files available in: sources/054-dark-mode-color-composition/,
sources/055-dark-primary-as-text-contrast-fix/, sources/056-dark-cta-contrast-fix/,
sources/058-dark-purple-hue/
