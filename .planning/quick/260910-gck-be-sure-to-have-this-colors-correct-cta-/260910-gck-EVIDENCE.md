# 260910-gck: Dark-mode outline-primary CTA contrast — Evidence

Measured at planning/execution time (2026-09-10) against the current repo state. No application
file was changed while producing this document.

## 1. Call-site inventory (verified, not assumed)

Re-ran the greps from `<pre_verified_facts>`:

```
grep -rn "btn-outline btn-primary" lib/
lib/pukllay_club_web/components/layouts.ex:921:      class={["btn btn-outline btn-primary pk-sumate-btn", @class]}
lib/pukllay_club_web/components/core_components.ex:107:      "secondary" => "btn-outline btn-primary",
lib/pukllay_club_web/components/game_preview.ex:163:        class="pk-preview-cta btn btn-outline btn-primary btn-block min-h-11"
```

```
grep -rn "variant=\"secondary\"\|sumate_cta\|pk-preview-cta" lib/
```
returned the same set already recorded in `<pre_verified_facts>`, plus the `sumate_cta/1`
call sites in `about_live.ex` (hero, closing band, mobile sticky) and its two doc-comment
mentions.

**Result: exactly 3 class-declaration sites, exactly 5 rendered placements. The pre-verified
table is confirmed complete — no new placement found.**

| # | Placement | Class-declaration site | Rendered at | Ground selector | Ground token | Ground hex |
|---|---|---|---|---|---|---|
| 1 | About hero Sumate | `layouts.ex:921` (`sumate_cta/1`) | `about_live.ex:418` | `#about-hero` (no own background) | `--color-base-100` (page) | `#2F154E` |
| 2 | About closing-band Sumate | `layouts.ex:921` (`sumate_cta/1`) | `about_live.ex:840` | `section#cierre.pk-band.pk-band-tint` → `.pk-band-tint { background: var(--color-base-200) }` | `--color-base-200` | `#391B62` |
| 3 | About mobile sticky Sumate | `layouts.ex:921` (`sumate_cta/1`) + `.pk-sumate-btn-solid` modifier | `about_live.ex:943` | n/a (solid fill, not outline) | `--color-primary` bg / `--color-primary-content` ink | **already filled, 6.70:1 — PASSES, out of scope** |
| 4 | Catalog preview CTA | `game_preview.ex:163` | rendered inside `.pk-portal` / `.pk-sheet` | `.pk-portal { background: var(--color-base-100) }` / `.pk-sheet { background: var(--color-base-100) }` | `--color-base-100` | `#2F154E` |
| 5 | "Reintentar" retry | `core_components.ex:107` (`<.button variant="secondary">`), called at `catalog_live/index.ex:1257` | catalog page | catalog page ground (base-100) | `--color-base-100` | `#2F154E` |

Placements #1, #2, #4, #5 are in scope (fail). #3 is confirmed out of scope (already solid-filled,
already passing).

**Not affected, verified untouched:** `catalog_live/show.ex:1150,1162,1171` use bare `btn
btn-outline` (no `btn-primary`) → resolves `--btn-color` to the default `var(--color-base-200)`
fallback via `.btn`'s own `--btn-bg: var(--btn-color, var(--color-base-200))`, not
`--color-primary`. `.pk-band-dark` (FAQ) fills with `--color-primary` background and inks with
`--color-primary-content` — a fill role, not an outline role, already correct. Contacto's chip
buttons use accent-bg/accent-text tokens, already correct (measured below as a sanity reference).

## 2. What daisyUI actually paints (verified against `deps/daisyui/packages/bundle/daisyui.js`)

Read the compiled daisyUI 5.x plugin source directly (it ships CSS-in-JS, not a `.css` file, so
this is the authoritative source of the generated rules).

**`.btn` (base rule, `@layer daisyui.l1.l2.l3`):**
```
color: var(--btn-fg);
background-color: var(--btn-bg);
border-color: var(--btn-border);
border-width: var(--border);
font-size: var(--fontsize, 0.875rem);   /* 14px default */
font-weight: 600;
--btn-bg: var(--btn-color, var(--color-base-200));
--btn-fg: var(--color-base-content);
```

**`.btn-primary` (`@layer daisyui.l1.l2.l3`):**
```
--btn-color: var(--color-primary);
--btn-fg: var(--color-primary-content);
```

**`.btn-outline, .btn-dash` (`@layer daisyui.l1` — lower layer, applies when not
hover/active/focus/disabled):**
```
--btn-shadow: "";
--btn-bg: #0000;              /* transparent */
--btn-fg: var(--btn-color);   /* overrides .btn-primary's --btn-fg */
--btn-border: var(--btn-color);
--btn-noise: none;
```

**Resolution for `.btn.btn-outline.btn-primary` (cascade layer order: l1 < l2 < l3, but
`.btn-outline` is declared as the LAST rule targeting `--btn-fg`/`--btn-border` in source and
daisyUI's layer system gives `.btn-outline`'s l1-layer declarations priority for `--btn-fg`/
`--btn-border` over `.btn-primary`'s l3-layer `--btn-fg` for this specific combination — confirmed
by the live rendered pixel values already logged in `<pre_verified_facts>`/prior sketch sessions,
which is the empirical cross-check for this cascade claim):**

| Property | Resolves to | Value in dark theme |
|---|---|---|
| `color` (label text ink) | `var(--btn-fg)` → `var(--btn-color)` → `var(--color-primary)` | `#8C2BB6` |
| `border-color` | `var(--btn-border)` → `var(--btn-color)` → `var(--color-primary)` | `#8C2BB6` |
| `background-color` | `var(--btn-bg)` → `#0000` | transparent |

**Confirmed: the plan's premise holds exactly as stated.** `btn-outline btn-primary` resolves
both `color` and `border-color` to `--color-primary` with a transparent background. daisyUI
5.5.20 does not resolve this differently from the plan's assumption.

## 3. WCAG-role floor verdict (per placement, not assumed)

### Font-size / font-weight per placement (the fact that determines the floor)

| Placement | Class chain | Font-size source | Resolved size | Font-weight source | Resolved weight |
|---|---|---|---|---|---|
| Hero Sumate | `.pk-sumate-btn` (app.css:2740-2745) | `.pk-sumate-btn { font-size: 1rem }` | **16px** | inherited from `.btn` (no override) | **600** |
| Closing-band Sumate | `.pk-sumate-btn` (same class, same rule) | same | **16px** | same | **600** |
| Preview CTA | `.pk-preview-cta` (app.css:1125-1127) declares only `margin-top: 8px` — no font-size/weight | daisyUI `.btn` default `var(--fontsize, 0.875rem)` | **14px** | daisyUI `.btn` default | **600** |
| Reintentar | `core_components.ex:104-114` `button/1`, `variant="secondary"` → `class="btn btn-outline btn-primary"`, no size modifier | daisyUI `.btn` default `var(--fontsize, 0.875rem)` | **14px** | daisyUI `.btn` default | **600** |

WCAG 2.1's "large text" threshold for the 3:1 SC 1.4.3 floor is **≥24px (18pt) normal weight, or
≥18.66px (14pt) at ≥700 (bold) weight**. Every placement here is 14-16px, and the resolved weight
(600, daisyUI's "semibold") is below the conventional 700 "bold" cutoff used by WCAG's own
technique G18/G145 examples in any case. **None of the 4 in-scope placements qualifies as large
text under either clause** — the weight ambiguity doesn't even matter here, since all 4 sizes
(14px, 16px) sit well under the 18.66px bold-text threshold on their own.

**Verdict: SC 1.4.3 floor = 4.5:1 (normal text) for every in-scope placement's label.**

### Border floor (SC 1.4.11 Non-text Contrast)

The `btn-outline` border is a visual UI-component boundary — SC 1.4.11 applies uniformly
regardless of font size. **Verdict: 3:1 floor for every in-scope placement's border**, same value
for both hero/closing-band Sumate, preview CTA, and Reintentar (they all resolve the same
`border-color: var(--color-primary)`).

### Is "leave it as-is" defensible?

No. At the measured `#8C2BB6`-on-ground ratios (2.34:1 on base-100, 2.08:1 on base-200), BOTH the
4.5:1 text floor AND the more lenient 3:1 border floor fail on both grounds. There is no floor
this passes today — the case for "no fix needed" has no basis in the numbers.

## 4. Contrast matrix

Computed via WCAG 2.1 relative luminance / contrast ratio formulas (throwaway Node script,
session scratchpad only — not committed to the repo).

| Ink | Ground | Ratio | 1.4.3 floor (text, all in-scope placements = 4.5:1) | 1.4.11 floor (border = 3:1) |
|---|---|---|---|---|
| `--color-primary` `#8C2BB6` | base-100 `#2F154E` | **2.34:1** | **FAIL** (needs 4.5:1) | **FAIL** (needs 3:1) |
| `--color-primary` `#8C2BB6` | base-200 `#391B62` | **2.08:1** | **FAIL** (needs 4.5:1) | **FAIL** (needs 3:1) |
| `--color-neutral` `#B8A6CC` | base-100 `#2F154E` | **7.00:1** | PASS | PASS |
| `--color-neutral` `#B8A6CC` | base-200 `#391B62` | **6.21:1** | PASS | PASS |
| `--color-accent-content` `#EBD7F4` | base-100 `#2F154E` | **11.63:1** | PASS | PASS |
| `--color-accent-content` `#EBD7F4` | base-200 `#391B62` | **10.32:1** | PASS | PASS |
| `#FFFFFF` (solid pair, own fixed background `#8C2BB6`) | n/a — fill role, ink measured against its own bg | **6.70:1** | PASS (reference only — already shipped on the sticky bar) | PASS |

Sanity-check references (already-passing surfaces, confirmed untouched):
- Light theme: `#3D096D` on `#FFFFFF` → **14.40:1** — PASS by a wide margin, unaffected by this
  plan (dark-scoped fix only).
- Sticky-bar solid pair: `#FFFFFF` on `#8C2BB6` → **6.70:1** — PASS, matches the pre-verified
  6.70:1 figure exactly.
- Contacto accent chips: `#EBD7F4` on `#3A1F47` → **10.61:1** — PASS, unaffected (different
  background token, not in scope).

### Per-placement PASS/FAIL summary against the applicable floor

| Placement | Ground | Current label ratio | Label verdict (4.5:1) | Current border ratio | Border verdict (3:1) |
|---|---|---|---|---|---|
| Hero Sumate | base-100 `#2F154E` | 2.34:1 | **FAIL** | 2.34:1 | **FAIL** |
| Closing-band Sumate | base-200 `#391B62` | 2.08:1 | **FAIL** | 2.08:1 | **FAIL** |
| Preview CTA | base-100 `#2F154E` | 2.34:1 | **FAIL** | 2.34:1 | **FAIL** |
| Reintentar | base-100 `#2F154E` | 2.34:1 | **FAIL** | 2.34:1 | **FAIL** |
| Mobile sticky Sumate (solid) | n/a | 6.70:1 | PASS (out of scope, unaffected) | 6.70:1 | PASS |

## Candidate ink options (numbers behind Task 2's options B/C)

Both candidate ink swaps clear both floors on both grounds by a wide margin:

- **`--color-neutral` (#B8A6CC):** 7.00:1 / 6.21:1 — clears 4.5:1 and 3:1 comfortably on both
  grounds. This is sketch 055's precedent token, already used for 17 secondary dark-mode rules.
- **`--color-accent-content` (#EBD7F4):** 11.63:1 / 10.32:1 — clears both floors with more margin
  than neutral, brighter/closer to white.
- **Solid fill (primary bg / primary-content ink):** 6.70:1 — already proven and shipping on the
  mobile sticky Sumate bar today.

No candidate is a numeric risk; the decision at Task 2 is about visual weight/brand-prominence
trade-offs, not about whether the ink clears WCAG — all three candidates clear both floors on both
grounds.
