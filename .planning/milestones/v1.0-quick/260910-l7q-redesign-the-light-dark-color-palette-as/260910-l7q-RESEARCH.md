# Quick Task 260910-l7q: Shared OKLCh Ramp — Research

**Researched:** 2026-09-10
**Domain:** Design-system color-token architecture (OKLCh ramps) × daisyUI 5 / Tailwind v4 CSS-first theming
**Confidence:** HIGH on Q2 and Q3 (both settled by probes run this session against the repo's own
toolchain); MEDIUM on Q1's Radix/Primer half (docs-only), HIGH on Q1's Material 3 / Tailwind half
(source read this session).

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Reuse scope**
- **Everything the contrast budget allows.** Do not pre-restrict which roles may share a literal
  value. The research/audit phase should determine, role by role, which pairs of (light role, dark
  role) CAN share one ramp stop without violating that role's own contrast requirement, and which
  cannot (e.g. a button that must pop on its own theme's background may be structurally unable to
  share a stop with a background role) — report both the sharable set and the ones blocked by
  contrast math, rather than assuming up front that only backgrounds/surfaces qualify.

**Architecture approach**
- **Defer to research.** Compare two candidate approaches against how production design systems
  (Radix Colors, Tailwind's palette, Material Design 3, GitHub Primer, etc.) structure this:
  1. New `--pk-ramp-*` tokens as the single source of truth; daisyUI's existing `--color-base-100`/
     `--color-primary`/etc. keep being declared directly per theme as today, but each theme's chosen
     hex must now be picked FROM the shared ramp and documented as such (low blast radius, reuse is
     documented/convention-enforced, not structurally enforced).
  2. daisyUI's `--color-*` slots become `var()` references into `--pk-ramp-*` variables directly
     (higher blast radius — touches daisyUI's own token resolution mechanism — but makes reuse
     impossible to silently drift off-ramp in a future edit).
  Research should recommend one, with rationale grounded in how the surveyed systems actually do it
  and in this project's own constraint of not breaking existing daisyUI component styling or the
  260910-hdc/if9 tripwire tests.

**Ramp granularity**
- **~9–12 stops**, matching the common industry pattern (Radix/Tailwind-style 50–950 scales). Confirm
  or adjust this count in the audit based on whether the ramp's real stops can land close enough to
  already-shipped, developer-approved values (light's `#3D096D` button, `--pk-ink-brand`'s `#C791E5`,
  etc.) without forcing a re-litigation of colors the developer already signed off on in prior quick
  tasks (260910-efe/gck/hdc/if9).

### Claude's Discretion
- Whether the shared ramp is generated algorithmically (one hue, computed L/C steps) or hand-tuned
  stop by stop — pick whichever the research phase's industry survey suggests is standard practice
  and whichever better preserves the already-approved anchor colors.
- Whether `--pk-ink-brand` (introduced by 260910-hdc) gets folded into the new ramp as one of its
  named stops, or is left standing alongside the ramp as a pre-existing anchor token the ramp must
  be compatible with. Decide based on whether folding it in changes its value — if it would change
  the already-approved `#C791E5`/light-reads-primary shape, leave it standing and note the ramp stop
  nearest to it instead.
- Exact stop-naming convention (numeric like `--pk-ramp-500`, or semantic-plus-index) — follow
  whichever convention the research survey shows is dominant, for familiarity to future maintainers.

### Deferred Ideas (OUT OF SCOPE)
*(CONTEXT.md declares no Deferred Ideas section.)*
</user_constraints>

---

## Summary

**Q1 (industry survey).** Of the four systems surveyed, exactly **one** does what this task asks —
literal value reuse across themes for *different* semantic roles — and it is **Material Design 3**.
M3 builds one tonal palette per key colour and both schemes index into that same palette by tone
number: `primary` is tone 40 in light and tone 80 in dark, `surface` is tone 98 in light and tone 6
in dark, `primaryContainer` tone 90 / tone 30. The palette itself is theme-agnostic. **Tailwind's**
50–950 scale is the same shape in practice: `text-slate-800 dark:bg-slate-800` is one literal value
worn as light-mode ink and dark-mode surface, and that is the idiomatic way teams wire it. **Radix
Colors** and **GitHub Primer**, by contrast, give each theme its *own* independently-generated set
of values and share only the **step number / functional token name** — Radix's step 1 is near-white
in light and near-black in dark; Primer explicitly *inverts* its neutral scale for dark. Their reuse
is nominal, not literal. So the developer's instinct has real, first-tier prior art (M3), and the
naming convention with the most maintainer familiarity is Tailwind's numeric `50…950`.

**Q2 (daisyUI integration).** Settled empirically, not from docs. daisyUI 5's `daisyui-theme` plugin
is a **pure pass-through**: it destructures the block's options and spreads them verbatim into
`addBase()`, doing no colour parsing at all. A build probe run this session against this repo's own
Tailwind 4.3.0 binary and daisyUI 5.5.20 confirms `--color-primary: var(--pk-ramp-800)` survives to
the output CSS unchanged, and that `bg-primary/50` still compiles to
`color-mix(in oklab, var(--color-primary) 50%, transparent)` — a runtime construct that is
indifferent to the indirection. **Approach (b) is mechanically supported.** Its cost is not in
daisyUI; it is in this repo's three hex-parsing verification instruments, all of which currently
`flunk`/report DRIFT on a `var()` value.

**Q3 (ramp construction).** An evenly-stepped, fixed-hue, **fixed-chroma** OKLCh ramp is not merely
suboptimal — at this project's brand hue it is *impossible*. A gamut probe run this session shows
sRGB's maximum chroma at H313.1 peaks at C≈0.30 around L60 and collapses to C≈0.05 at both L11 and
L93. Chroma **must** taper. But it does not need hand-tuning: M3 generates algorithmically at
constant hue+chroma and lets its HCT solver clamp — "the hue and L\* will be sufficiently close, and
chroma will be maximized". Tailwind v4's own purple ramp shows the same hump empirically. The right
method here is **algorithmic generation with a gamut-clamped chroma envelope, then hand-nudge only
the stops that must land on already-approved anchors.**

**Primary recommendation:** Build an 11-stop numeric ramp (`--pk-ramp-50 … --pk-ramp-950`) at the
brand hue H313.1, chroma = a fixed fraction of the per-lightness sRGB gamut maximum, declared once in
plain `:root`; wire daisyUI's `--color-*` slots to it via **`var()` (approach b)**, and budget the
plan for updating the three hex-parsing gates that this breaks.

---

## Q1 — How production systems structure light/dark ramps

| System | One ramp shared by both themes? | Reuse is… | Evidence |
|--------|--------------------------------|-----------|----------|
| **Material Design 3** | **Yes — literally.** Tonal palettes (Primary/Secondary/Tertiary/Neutral/Neutral-Variant) are theme-agnostic; each scheme maps roles to different *tone numbers* in the same palette. | **Structural + literal.** A tone-40 swatch is `primary` in light; the very same palette's tone 80 is `primary` in dark. Tone 90 is `primaryContainer` in light and `onPrimaryContainer` in dark — same palette, roles swap. | `[VERIFIED: material-color-utilities/typescript/dynamiccolor/color_spec_2021.ts, fetched this session]` — see role table below |
| **Tailwind CSS** | **Yes in practice.** One 50–950 ramp per hue; the `dark:` variant selects a different index of the *same* ramp. | **Literal.** `bg-slate-800` as dark surface and `text-slate-800` as light ink are byte-identical values in different roles. | `[VERIFIED: tailwind 4.3.0 build output, this session]` |
| **Radix Colors** | **No.** Ships a paired *but separately valued* dark scale per hue (`blue` / `blueDark`). | **Nominal only.** "Every scale has 12 steps … with perfectly matched light and dark variants"; step 1 is "an almost white blue in light mode and an almost black blue in dark mode." Same step number ⇒ same *role*, never the same *value*. | `[CITED: radix-ui.com/colors/docs/palette-composition/understanding-the-scale]` |
| **GitHub Primer** | **No.** | **Nominal, via inversion.** "There are two versions of the neutral scale: light and dark, with the light scale starting with white and the dark scale starting with black. By inverting the scales, light and dark themes are able to share many of the same **functional color tokens** without custom overrides." Sharing happens one layer up, at the functional token, not at the swatch. | `[CITED: primer.style/primitives/colors/ + github.blog Primer colour-system post]` |

### Material 3's role→tone map (the closest prior art)

Read this session from `color_spec_2021.ts` — every line is a literal `s.isDark ? <darkTone> : <lightTone>`:

| Role | Palette | Light tone | Dark tone | Source line |
|------|---------|-----------|-----------|-------------|
| `surface` | neutral | 98 | 6 | 145 |
| `onSurface` (via surface pairing) | neutral | 10 | 90 | 154 / 248 |
| `surfaceVariant`-family container | neutral | 90 | 30 | 258 |
| `outline` | neutralVariant | 50 | 60 | 296 |
| `inverseSurface` | neutral | 80 → 30 pairing | 30 / 80 | 306 |
| `primary` | primary | **40** | **80** | 343–350 |
| `onPrimary` | primary | 100 | 20 | 369–371 |
| `primaryContainer` | primary | 90 | 30 | 387–389 |
| `onPrimaryContainer` | primary | 30 | 90 | 409–411 |
| `secondary` | secondary | 40 | 80 | 332 |
| `error` | error | 40 | 80 | 436 |

Verbatim from the file (line 349): `return s.isDark ? 80 : 40;`, and (line 145): `tone: (s) => s.isDark ? 6 : 98,`.

**What this means for the plan.** The pattern that actually generalises is not "light and dark share
some swatches by luck" but **"a role's light tone and dark tone are a mirrored pair about the ramp's
midpoint."** Light 40 ↔ dark 80; light 90 ↔ dark 30; light 98 ↔ dark 6; light 100 ↔ dark 20. In a
50–950 ramp with 11 stops that reads as: light role at index *i* ⇒ dark role at index *n−i*. Adopt
that as the ramp's design law and the "which roles can share" question resolves mechanically instead
of case-by-case.

**Stop count and naming.** M3 publishes 13 tones (0/10/…/90/95/99/100); Tailwind and Radix use 11 and
12. All three sit inside CONTEXT.md's "~9–12". Recommend **11 stops, Tailwind-numeric naming**
(`--pk-ramp-50, -100, -200, … -900, -950`) — it is the convention with the widest maintainer
familiarity, it matches the CONTEXT.md preference, and (see Q3) the shipped anchors land on it
cleanly. `[ASSUMED — a judgement call, not a measured fact]`

---

## Q2 — Layering a shared ramp under daisyUI 5

### The mechanism (settled by reading the vendored plugin)

daisyUI 5.5.20's theme plugin does **no** colour parsing. `[VERIFIED: deps/daisyui/packages/bundle/daisyui-theme.js:58-96]` — verbatim:

```js
var theme_default = plugin.withOptions((options = {}) => {
  return ({ addBase }) => {
    const { name = "custom-theme", default: isDefault = false, prefersdark = false,
      "color-scheme": colorScheme = "normal", root = ":root", ...customThemeTokens } = options;
    let selector = `${root}:has(input.theme-controller[value=${name}]:checked),[data-theme="${name}"]`;
    ...
    const baseStyles = { [selector]: { "color-scheme": ..., ...themeTokens } };
    ...
    addBase(baseStyles);
  };
});
```

Everything that is not `name` / `default` / `prefersdark` / `color-scheme` / `root` is spread through
untouched. Downstream, daisyUI's component CSS only ever *reads* these tokens through `var()` and
`color-mix()` — `[VERIFIED: deps/daisyui/packages/bundle/daisyui.js — 30 occurrences of
`color-mix(in oklab`, e.g. `color-mix(in oklab, var(--color-primary) 80%, #000)`]`. Nothing in the
bundle ever needs the literal value at build time.

Note that the widely-circulated GitHub-discussion claim that daisyUI "needs to know the value of the
color so it can apply the color opacity" is a **daisyUI 4 / Tailwind 3** constraint and does not
apply here `[CITED: github.com/saadeghi/daisyui discussions #1811, #2939]`.

### Falsification probe (run this session, this repo's own binaries)

A scratch build with `--color-primary: var(--pk-ramp-800)` inside a real
`@plugin "daisyui/packages/bundle/daisyui-theme"` block, compiled with
`_build/tailwind-linux-x64-4.3.0` + `deps/daisyui` (v5.5.20). Output:

```css
@layer base {
  :where(:root),:root:has(input.theme-controller[value=probe]:checked),[data-theme="probe"] {
    color-scheme: light;
    --color-primary: var(--pk-ramp-800);      /* passed through verbatim */
    --color-base-100: var(--pk-ramp-100);
  }
}
/* ...and the utilities still resolve at runtime: */
.bg-primary\/50 {
  background-color: var(--color-primary);
  @supports (color: color-mix(in lab, red, red)) {
    background-color: color-mix(in oklab, var(--color-primary) 50%, transparent);
  }
}
```

`[VERIFIED: build probe, tailwindcss 4.3.0 + daisyUI 5.5.20, exit 0]`. `btn`/`btn-primary`/
`btn-outline`/`border-primary`/`text-primary-content` all emitted normally.

**One cascade detail worth carrying into the plan:** the probe's plain `:root { --pk-ramp-* }` block
was emitted **unlayered**, while daisyUI's theme block lands inside `@layer base`. Per this file's own
cascade-layer hazard note (`assets/css/app.css:12-38`), unlayered beats layered — which is harmless
here (nothing else declares `--pk-ramp-*`) and is the same shape the existing `--pk-ink-brand` token
already uses. `[VERIFIED: probe output + assets/css/app.css:454-504]`

### The real cost of approach (b): three hex-parsing gates break

| Gate | Why it breaks | Verbatim evidence |
|------|---------------|-------------------|
| `.planning/sketches/themes/check-theme-drift.sh` | `value_of()` extracts the raw declaration text and hex-compares it against `default.css`. It would extract the string `var(--pk-ramp-800)` and report DRIFT against the sketch's hex. | `[VERIFIED: .planning/sketches/themes/check-theme-drift.sh:39-43]` — `value_of() { grep -m1 -- "$2:" "$1" 2>/dev/null \| sed -E 's/^[^:]*:[[:space:]]*([^;]+);.*/\1/' \| tr -d '[:space:]' }` |
| ExUnit OKLCh tripwires (260910-hdc/if9) | `parse_rgb/1` accepts **only** `#RRGGBB` or `rgb(r g b)`; anything else `flunk`s. `token_value/2` returns the raw declaration text. | `[VERIFIED: test/pukllay_club_web/live/catalog_show_test.exs:3990-4013]` — `case Regex.run(~r/^#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/, String.trim(color))` … `nil -> flunk("Could not parse colour value for contrast computation: …")` |
| `260910-if9/oklch-audit.mjs` | Same shape — parses `#RRGGBB` out of the theme blocks. | `[VERIFIED: .planning/quick/260910-if9-.../oklch-audit.mjs:125-165 (parseThemeBlock/parsePlainRootPkInkBrand/parseDarkRootPkInkBrand)]` |

All three need the **same** one-hop dereference: given a value matching `var(--pk-ramp-NNN)`, look
the stop up in the `:root` ramp block and continue with that hex. That is a small, shared, testable
helper in each of the three languages — and it is *strictly better* than the status quo, because once
it exists the gates can additionally assert "every `--color-*` value is either a `var()` into the ramp
or an explicitly-annotated off-ramp exception," which is exactly the drift protection approach (b)
exists to buy.

### Recommendation: **approach (b)**, `var()` references into a `:root`-declared ramp

Approach (a)'s only advantage was avoiding daisyUI's token resolution — and the probe shows there is
nothing to avoid: daisyUI never resolves these values, it forwards them. That removes (a)'s entire
risk premium while leaving its central weakness intact, which is that "the hex must be picked from
the ramp" is a comment, and comments do not fail CI. This repo's own recent history is a four-task
chain (260910-efe → gck → hdc → if9) of exactly that failure mode: independently-invented hexes
drifting apart until a measurement instrument had to be built to find them. The one-time cost of
teaching three parsers a single `var()` hop is smaller than the recurring cost of that drift, and it
converts the ramp from documentation into an invariant the existing tripwires can enforce. Precedent
also already exists in-file: light's `--pk-ink-brand` is deliberately declared as
`var(--color-primary)` rather than a copied hex, "so light cannot drift"
`[VERIFIED: assets/css/app.css:482-485]` — approach (b) is that same decision, generalised.

**Scope guard for the planner:** keep `--color-*-content` slots that are pure `#FFFFFF` off-ramp (or
add a neutral `--pk-ramp-white`), and leave `info`/`success`/`warning`/`error` off the brand ramp
entirely — they are other hues and must stay so.

---

## Q3 — Ramp granularity and OKLCh construction

### Fixed chroma is not achievable at this hue

Gamut probe, sRGB maximum chroma at the brand hue **H313.1** (binary search on the OKLab→linear-sRGB
inverse, `[VERIFIED: computed this session]`):

| L% | 11 | 22 | 33 | 44 | 55 | **60** | 66 | 77 | 88 | 93 |
|----|----|----|----|----|----|--------|----|----|----|----|
| max C | 0.056 | 0.108 | 0.162 | 0.217 | 0.271 | **0.299** | 0.263 | 0.171 | 0.087 | 0.047 |

A constant-chroma ramp at the current dark `--color-primary`'s C=0.21 would be out of gamut at
**8 of 17** sampled lightnesses — every stop below L≈44 and above L≈71 would silently clip, which in
practice means the browser flattens it toward a different hue and the ramp stops being perceptually
even in exactly the region backgrounds and inks live. So: **OKLCh gives you even *lightness* for
free; it does not give you a usable ramp at constant chroma.**

### But production systems do not hand-tune this — they clamp

- **Material 3** requests a *constant* hue+chroma per tonal palette and delegates the taper to its
  solver: `TonalPalette.tone(t)` is literally `Hct.from(this.hue, this.chroma, tone)`, and the solver's
  contract is — verbatim — *"The color has sufficiently close hue, chroma, and L\* to the desired
  values, if possible; **otherwise, the hue and L\* will be sufficiently close, and chroma will be
  maximized.**"* `[VERIFIED: material-color-utilities typescript/palettes/tonal_palette.ts:61-72 and
  hct/hct_solver.ts:519-522, fetched this session]`
- **Tailwind v4** ships the same hump, baked in. Its own `purple` ramp, extracted from this repo's
  Tailwind 4.3.0 binary `[VERIFIED: build output, this session]`:

  | stop | 50 | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 950 |
  |------|----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
  | L% | 97.7 | 94.6 | 90.2 | 82.7 | 71.4 | 62.7 | 55.8 | 49.6 | 43.8 | 38.1 | 29.1 |
  | C | 0.014 | 0.033 | 0.063 | 0.119 | 0.203 | 0.265 | **0.288** | 0.265 | 0.218 | 0.176 | 0.149 |
  | H | 308.3 | 307.2 | 306.7 | 306.4 | 305.5 | 303.9 | 302.3 | 301.9 | 303.7 | 305.0 | 302.7 |

  Three things to read off this: lightness steps are **not** uniform (ΔL runs 3.1 → 11.3 → 5.7);
  chroma is a **hump peaking at 600**, tracking the gamut boundary; and hue **drifts 6.4°** across the
  ramp. Tailwind's is a hand-finished ramp — but every one of those three departures from "even" is
  the same departure the gamut envelope forces anyway.

**Method to use:** generate algorithmically — fixed hue, an L ladder, and `C = k · maxC(L, H)` with a
single safety factor `k` (≈0.85–0.9 keeps every stop comfortably inside sRGB rather than pinned to a
clipping edge) — then hand-nudge only the stops that must land on a shipped anchor. Reuse
`oklch-audit.mjs`'s existing sRGB↔OKLab math; the only new function needed is the ~10-line `maxC`
bisection. Do **not** hand-pick all 11 stops from scratch, and do **not** use a flat chroma.

### The shipped anchors already fit — one decision aside

A candidate 11-stop ramp at H313.1 with `C = 0.88 · maxC(L)`, using an L ladder shaped to hit the
approved values, versus what is already in `app.css` `[VERIFIED: computed this session from
assets/css/app.css:227-295 and :488-504]`:

| Approved anchor | Current | Nearest candidate stop | Δ |
|-----------------|---------|------------------------|---|
| dark `--color-primary` | `#8C2BB6` (L50.2 C0.210 **H313.1**) | `--pk-ramp-600` `#8E25BA` (6.72:1 on white; today's is 6.70:1) | negligible |
| dark `--pk-ink-brand` | `#C791E5` (L73.9 C0.131 **H312.9**) | `--pk-ramp-400` `#CF87F5` | small chroma lift |
| dark `--color-base-100` | `#361148` (L26.7 C0.101 **H312.4**) | `--pk-ramp-950` `#39094D` | small |
| light `--color-base-200` = dark `--color-base-content` | `#F3ECFA` (already literally shared today) | `--pk-ramp-100` `#F5E7FD` | small |
| light `--color-primary` | `#3D096D` (L30.4 C0.151 **H300.1**) | `--pk-ramp-900` `#470E5E` | **hue moves 13°** |

**The one real decision this hands the planner:** light's `--color-primary` `#3D096D` sits at
**H300.1**, while 260910-if9 deliberately rotated dark's entire ladder onto **H313.1**. A single
fixed-hue ramp cannot contain both. Either light's primary moves ~13° onto the brand hue (re-litigating
a colour signed off in 260910-efe), or the ramp allows a Tailwind-style hue drift across its length,
or light's primary is documented as a deliberate off-ramp anchor. This is a `checkpoint:human-verify`
for the plan, not a Claude call.

### Reuse opportunity already latent in the current palette

Cross-theme pairs within ΔL < 4 today `[VERIFIED: computed this session]` — the shortlist the
contrast audit should start from:

| light role | dark role | ΔL | ΔH | Status |
|------------|-----------|----|----|--------|
| `--color-base-200` `#F3ECFA` | `--color-base-content` `#F3ECFA` | 0.0 | 0.0 | **already literally shared** |
| `--color-base-100` `#FFFFFF` | `--color-primary-content` / `--color-secondary-content` | 0.0 | 0.0 | **already literally shared** |
| `--color-primary` `#3D096D` | `--color-base-200` `#441659` | 0.4 | 13.0 | blocked only by the H300 vs H313 split above — this is the developer's own motivating example |
| `--color-secondary` `#7E4CA5` | `--color-primary` `#8C2BB6` | 1.2 | 5.0 | near-shareable; chroma differs 0.067 |
| `--color-base-300` `#E3D3F0` | `--color-accent-content` `#EBD7F4` | 1.5 | 5.4 | near-shareable |
| `--color-neutral` `#6B5B7B` | `--color-primary` `#8C2BB6` | 0.3 | 5.8 | **not** shareable — ΔC 0.157 is the whole point of light's muted ink |

Two pairs already share literally; three more are one hue-unification away. That is enough to make
the ramp worth building, and it confirms the ~11-stop granularity is right — the distinct lightness
levels the palette actually occupies cluster into roughly that many bands.

---

## Don't Hand-Roll

| Problem | Don't build | Use instead |
|---------|-------------|-------------|
| sRGB↔OKLab↔OKLCh conversion | A fourth copy of the math | `oklch-audit.mjs`'s existing `oklab/1`, `oklchChroma`, `oklchHue` — already mirrored byte-for-byte in `catalog_show_test.exs` and `sketches/054/contrast-check.mjs`. Extend, don't duplicate (CONTEXT.md canonical refs). |
| Per-stop chroma tuning by eye | 11 hand-picked hexes | One `maxC(L, H)` bisection + a single safety factor — this is what M3's HCT solver does internally |
| Deciding whether daisyUI accepts `var()` | Reading more blog posts | The probe in Q2 is reproducible in ~5 seconds; re-run it if daisyUI is ever upgraded |

---

## Common Pitfalls

1. **Assuming OKLCh's perceptual uniformity extends to chroma.** It does not bound gamut. Any ramp
   that holds C constant will clip at both ends — verified above at this project's exact hue.
2. **Forgetting the three hex parsers.** Approach (b) is a five-line CSS change and a
   three-instrument test change. Planning it as the former alone will red the suite.
3. **Putting `--pk-ramp-*` inside a `@layer`.** Keep it unlayered in plain `:root`, matching
   `--pk-ink-brand`'s existing shape and this file's documented cascade-layer hazard.
4. **Folding non-brand semantics onto the brand ramp.** `info`/`success`/`warning`/`error` live at
   H258/H162/H77/H7. They are not ramp stops.
5. **Treating "same step number" as "same value."** Radix and Primer look like they share a ramp and
   do not. Only M3 and Tailwind-with-`dark:` actually share literals. Don't cite Radix as prior art
   for this task's specific goal.

---

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | 11 stops with Tailwind-numeric naming is the best fit for maintainer familiarity | Q1 | Low — cosmetic; any count in 9–12 satisfies CONTEXT.md |
| A2 | `k ≈ 0.85–0.9` is the right gamut safety factor | Q3 | Low — tune empirically during the plan's audit step |
| A3 | Radix ships genuinely different literal values per theme (docs describe behaviour, I did not read the `@radix-ui/colors` source this session) | Q1 | Low — does not change the recommendation, only the survey framing |
| A4 | Tailwind teams idiomatically cross-use one ramp index as light-ink / dark-surface | Q1 | Low — the M3 evidence carries the argument regardless |

---

## Open Questions

1. **Does light's `--color-primary` move onto H313.1?**
   - Known: it is at H300.1; dark's whole ladder was deliberately rotated to H313.1 by 260910-if9;
     a single-hue ramp cannot hold both.
   - Unclear: whether the developer will accept re-toning a colour approved in 260910-efe.
   - Recommendation: `checkpoint:human-verify` in the plan, with the three options costed
     (move light / allow ramp hue drift / document as off-ramp anchor).
2. **Does `--pk-ink-brand` fold into the ramp?** Its nearest candidate stop (`--pk-ramp-400`
   `#CF87F5`) is not byte-identical to the approved `#C791E5`. Per CONTEXT.md's own discretion rule
   ("if it would change the already-approved `#C791E5` … leave it standing"), the default answer is
   **leave it standing** and annotate the nearest stop — unless the developer opts into the small move.
3. **Does `.planning/sketches/themes/default.css` mirror the ramp, or resolved hexes?** Mirroring the
   ramp keeps one source of truth; mirroring hexes keeps `check-theme-drift.sh` simple. Plan decision.

---

## Sources

### Primary (HIGH — read/executed this session)
- `deps/daisyui/packages/bundle/daisyui-theme.js:58-96` and `daisyui.js` — plugin pass-through, `color-mix` consumption
- Build probe: `_build/tailwind-linux-x64-4.3.0` (v4.3.0) + daisyUI 5.5.20, `var()` in a theme block
- `test/pukllay_club_web/live/catalog_show_test.exs:3963-4013` — `token_value/2`, `parse_rgb/1`
- `.planning/sketches/themes/check-theme-drift.sh:35-43` — `value_of()`
- `.planning/quick/260910-if9-.../oklch-audit.mjs:121-165` — palette parser
- `assets/css/app.css:12-38, 227-295, 454-504` — cascade hazard note, both theme blocks, `--pk-ink-brand`
- `material-color-utilities` `typescript/dynamiccolor/color_spec_2021.ts`, `palettes/tonal_palette.ts:61-72`, `hct/hct_solver.ts:513-523` (raw.githubusercontent.com, fetched this session)
- Gamut + candidate-ramp computations (Node, this session)

### Secondary (MEDIUM — documentation)
- radix-ui.com/colors — 12-step scale semantics, paired light/dark scales
- primer.style/primitives/colors + github.blog Primer colour-system post — inverted neutral scale, functional tokens
- m3.material.io/styles/color — role/tone system overview
- github.com/saadeghi/daisyui discussions #1811, #2939 — the (superseded) daisyUI 4 `var()` limitation

## Metadata

**Confidence breakdown:**
- Q1 survey: HIGH for M3/Tailwind (source read + binary output), MEDIUM for Radix/Primer (docs only)
- Q2 daisyUI integration: HIGH — settled by a reproducible build probe against this repo's own toolchain
- Q3 ramp construction: HIGH — gamut arithmetic and Tailwind's shipped ramp both measured this session

**Research date:** 2026-09-10
**Valid until:** ~30 days, or until daisyUI/Tailwind are upgraded (re-run the Q2 probe if so)
