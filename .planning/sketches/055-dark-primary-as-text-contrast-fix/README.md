---
sketch: 055
name: dark-primary-as-text-contrast-fix
question: "Sketch 054's winning primary (#8C2BB6, fill-only) fails 4.5:1 WCAG contrast when used as text in 17 real app.css rules — which replacement reads best without reopening the fill decision?"
winner: null
tags: [dark-mode, contrast, accessibility, wcag, quick-task-260910-efe]
---

# Sketch 055: Dark primary-as-text contrast fix

## Design Question

Quick task 260910-efe shipped sketch 054's winning dark palette (Variant A ladder + W2 Deep Jewel
primary, `#8C2BB6`) into `assets/css/app.css`. Sketch 054 only ever composed `--color-primary` as
a FILL (CTA background, wordmark, card gradients) — it measured 6.70:1 white-on-primary, the best
margin of any candidate tested. But the real app also uses `--color-primary` as a TEXT color in
17 existing rules (nav-active, drawer-active, pill-tag hashtags, several hover/focus states), and
there the new primary fails hard: 2.34:1 against the new `--color-base-100`, well under the 4.5:1
WCAG AA floor. An existing shipped test (`catalog_show_test.exs:4316`) catches this by design.

This sketch compares the real affected elements — not an abstract swatch grid — against the four
candidate fixes discussed with the developer, to let the choice be visual and informed rather than
picked from numbers alone.

## How to View
```
open .planning/sketches/055-dark-primary-as-text-contrast-fix/index.html
```

## Variants

- **Overview** — the contrast matrix for all candidates against all three dark ladder tones
  (base-100/200/300), plus the full-surface finding computed while building this sketch (see
  below).
- **A1: accent-content ink** — swap the 17 text rules to `--color-accent-content` (#EBD7F4,
  11.63:1). Palette stays byte-exact; CTA fill unaffected.
- **A2: neutral ink** — same approach, quieter `--color-neutral` (#B8A6CC, 7.00:1) instead.
- **C1: revisit primary → W1** — replace the shipped primary with sketch 054's round-2 W1
  candidate (#B073D3), which the developer originally passed over in favor of W2's depth. One
  color serves both fill and text.
- **C2: revisit primary → W3** — same idea with W3 (#BA80DB), the lighter of the two round-2
  candidates.

Options B (separate ink token) and D (re-scope the 17 rules + retire the WCAG gate) are not
sketched — B is visually indistinguishable from A1/A2 in a static mockup (it's the same token
role, just a new name), and D isn't a visual choice, it's a scope decision about the test suite.

## What to Look For

- Does losing the brand-violet ink in nav-active/drawer-active states (A1/A2) read as a real loss,
  or does the app still clearly communicate "you are here" through weight/underline/left-border
  alone?
- Does C1 or C2 still feel like *the same brand color* as the CTA button, or does lightening it
  for text-safety make it look like a different, weaker purple next to the deep CTA fill?
- On C1/C2, note the CTA tab: revisiting the primary means the CTA also gets a lighter fill with
  dark ink instead of W2's white-on-deep-violet — is that trade-off worth it?

## Full-surface finding (found while building this sketch, not in the original checkpoint)

The checkpoint's own numbers only checked `--color-base-100`. Computed precisely (WCAG relative
luminance) against all three dark ladder tones:

| Candidate | vs base-100 `#2F154E` | vs base-200 `#391B62` | vs base-300 `#462278` |
|---|---|---|---|
| W2 current `#8C2BB6` | 2.34:1 FAIL | 2.08:1 FAIL | 1.78:1 FAIL |
| A1 `#EBD7F4` | 11.63:1 PASS | 10.32:1 PASS | 8.84:1 PASS |
| A2 `#B8A6CC` | 7.00:1 PASS | 6.21:1 PASS | 5.32:1 PASS |
| C1 (W1) `#B073D3` | 4.66:1 PASS | 4.14:1 **FAIL** | 3.54:1 **FAIL** |
| C2 (W3) `#BA80DB` | 5.38:1 PASS | 4.78:1 PASS | 4.09:1 **FAIL** |

Neither C1 nor C2 fully clears 4.5:1 on every surface a text-role primary could sit on — only the
ink-token approach (A1/A2) is unconditionally safe. In practice this matters less than it looks:
every one of the 17 affected rules was checked against its real container in `app.css`, and all of
them sit on `--color-base-100` (header, drawer panel, category dropdown panel, and the pill-tag's
own card are all explicitly `background: var(--color-base-100)` — this app doesn't fill surfaces
with base-200/300, it only uses them for borders/hover backgrounds). So C1/C2's base-200/base-300
failure is a latent risk for *future* rules on an elevated surface, not a bug in the 17 rules that
exist today. Recorded here so it isn't rediscovered blind on the next palette or component that
puts primary-as-text on a card or modal surface.

## Next Step

Present this sketch to the developer, get a variant pick (or a synthesis), then resume the quick
task 260910-efe executor with the decision to implement Task 3.
