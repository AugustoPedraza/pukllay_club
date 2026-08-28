---
status: resolved
trigger: "lightbox-close-button-dark-contrast — The lightbox's close button (.pk-lightbox-close) needs a little more contrast against its background in dark theme now that the surrounding lightbox stage was recently made taller (plan 01.2-29, full-viewport height)."
created: 2026-08-28T00:00:00Z
updated: 2026-08-28T17:44:00Z
---

## Current Focus

hypothesis: CONFIRMED — `.pk-lightbox-close` carries no explicit background/border color of its
own; it inherits daisyUI's default (unmodified) `.btn` fill, which resolves to
`var(--color-base-200)`. In dark theme `--color-base-200` (`#22103A`) is nearly the same luminance
as `--pk-shadow-color` (`rgb(20 8 34)` / `#140822`) — the single fixed dark literal this file uses
for BOTH the lightbox scrim (`--pk-overlay-scrim: color-mix(in srgb, var(--pk-shadow-color) 72%,
transparent)`) and the opaque stage fill (`.pk-lightbox-img { background: var(--pk-shadow-color) }`,
shipped by plan 01.2-29/G-01.2-18). Computed WCAG contrast between `#22103A` and `#140822` ≈
**1.1:1** — the button's own circular fill essentially disappears into whichever of those two
near-identical dark backdrops sits behind it; only its icon (`--btn-fg: var(--color-base-content)`,
`#F3ECFA`, near-white) stays visible, so the control reads as a floating X glyph rather than a
button. In light theme the same unmodified default resolves `--color-base-200` to `#F3ECFA`
(near-white), which contrasts strongly (>10:1) against that same fixed dark backdrop — explaining
why the defect is dark-theme-specific exactly as reported.
test: N/A (goal: find_root_cause_only — diagnosis complete, no fix applied)
expecting: N/A
next_action: Return ROOT CAUSE FOUND to caller.

## Symptoms

expected: The close button reads unmistakably as a button in both light and dark theme, per UAT
test 20 and plan 01.2-29's own human-check, which explicitly named this as a possible follow-up
design item (not a defect to fix during 01.2-29's own execution).
actual: User reports (verbatim): "On the dark needs a little more constrant" — in dark theme, the
close button's contrast against its background is not quite enough.
errors: None reported
reproduction: Open the lightbox on the running dev server in dark theme at desktop width
(~1440px+) on any game with 2+ gallery images; look at the close button (top-right corner, a
daisyUI `btn btn-circle` with a hero X icon) against its current background.
started: Surfaced in UAT test 20, immediately after plan 01.2-29's lightbox height change
(G-01.2-18); the plan's own human-check flagged this exact risk in advance ("Does it still read
unmistakably as a button? If it sinks into the stage in either theme, say so — that is a designed
contrast value in a follow-up round").

## Eliminated

- hypothesis: "Plan 01.2-29 changed the close button's position/z-index/markup, which broke
  contrast."
  evidence: Byte-for-byte comparison of `.pk-lightbox-close` (app.css:3470-3475, unchanged since
  before 01.2-29) and its markup (show.ex:746-754, unchanged) confirms neither was touched by
  01.2-29 — only `.pk-lightbox-img`'s `height` changed. Ruled out as the mechanism; the button's
  own styling was ALREADY marginal before 01.2-29, the height change only made the low-contrast
  surface surround it more consistently (full-height stage vs. a shorter 80vh stage with the same
  underlying dark tone in its margins).
  timestamp: 2026-08-28

## Evidence

- timestamp: 2026-08-28
  checked: `assets/css/app.css` lines 3470-3475 (`.pk-lightbox-close` rule) and
  `lib/pukllay_club_web/live/catalog_live/show.ex` lines 746-754 (close button markup)
  found: The rule declares only `position: absolute; top: 1rem; right: 1rem; z-index: 2;` — no
  `background`, `border`, or color property of any kind. Markup class list is
  `"pk-lightbox-close btn btn-circle min-h-11 min-w-11"` — no daisyUI color modifier
  (`btn-primary`/`btn-neutral`/`btn-ghost`/etc.), so the button relies entirely on daisyUI's
  unmodified `.btn` default fill.
  implication: The button's visual identity in the lightbox is 100% determined by daisyUI's
  default `--btn-color` fallback and whatever surface sits behind it — nothing in this project's
  own CSS gives it an intentional, theme-aware contrast treatment.

- timestamp: 2026-08-28
  checked: daisyUI bundle source (`deps/daisyui/packages/bundle/daisyui.mjs`, `.btn` rule)
  found: Unmodified `.btn` sets `--btn-bg: var(--btn-color, var(--color-base-200))` and
  `--btn-fg: var(--color-base-content)`. With no `--btn-color` set on this element (no color
  modifier class), the button's fill resolves to the theme's `--color-base-200` and its icon to
  `--color-base-content`. Border resolves to `color-mix(in oklab, var(--btn-bg), #000 5%)` — only
  5% darker than the button's own (already-dark) fill, so it adds no meaningful edge definition
  against an even-darker backdrop.
  implication: Confirms the button's fill color is theme-driven (`base-200`), not an
  independently-chosen "always legible" color — it inherits whatever `base-200` happens to be in
  the active theme.

- timestamp: 2026-08-28
  checked: `assets/css/app.css` `:root` and both `@plugin daisyui-theme` blocks (lines 139-207)
  found: Dark theme (`name: "dark"`): `--color-base-100: #170A26`, `--color-base-200: #22103A`,
  `--color-base-content: #F3ECFA`. Light theme (`name: "light"`): `--color-base-200: #F3ECFA`
  (near-white). `--pk-shadow-color: rgb(20 8 34)` (`#140822`) is declared once in `:root` (theme-
  invariant, WR-04) and is the literal every floating-surface shadow/scrim/opaque-fill in this file
  reads from — including `--pk-overlay-scrim: color-mix(in srgb, var(--pk-shadow-color) 72%,
  transparent)` (the lightbox's own background) and `.pk-lightbox-img`'s `background:
  var(--pk-shadow-color)` (the opaque stage fill shipped by plan 01.2-29).
  implication: In dark theme the button's fill (`#22103A`) and the backdrop it sits against
  (built from `#140822` at 72% or 100% strength) are both very dark, closely related purples. In
  light theme the button's fill (`#F3ECFA`, near-white) sits against that SAME fixed dark backdrop
  — a strong, unambiguous contrast. This is the theme-asymmetry mechanism: a theme-color button
  plotted against a theme-INVARIANT dark surface reads fine in light theme and poorly in dark
  theme, by construction, regardless of exactly which of the two near-identical dark surfaces
  (scrim margin vs. opaque stage) is directly behind the button pixel-for-pixel.

- timestamp: 2026-08-28
  checked: WCAG relative-luminance contrast calculation, `#22103A` (dark-theme `base-200`, the
  button's fill) vs. `#140822` (`--pk-shadow-color`, the scrim/stage backdrop)
  found: Computed contrast ratio ≈ **1.11:1** — far under the WCAG 1.4.11 non-text-contrast floor
  of 3:1, and consistent with this project's own knowledge-base precedent (prior sessions in this
  same codebase measured this app's surface-token ladder topping out around 1.1-1.4:1 for adjacent
  `base-2xx` pairs against `--pk-shadow-color`-derived surfaces; see knowledge-base.md entries on
  chip-nav/header adjacency and footer contrast). Light-theme equivalent (`#F3ECFA` vs. `#140822`)
  computes to a very high ratio (>10:1).
  implication: Directly explains the reported symptom in mechanistic, falsifiable terms — the
  close button's own fill is sub-perceptually close in luminance to its dark-theme backdrop,
  regardless of exactly which surface (scrim or stage) sits behind it, while the identical
  unmodified default is comfortably legible in light theme.

- timestamp: 2026-08-28
  checked: `.planning/phases/01.2-catalog-detail-navigation-polish/01.2-29-PLAN.md` (human-check
  block) and `01.2-UAT.md` test 20
  found: Plan 01.2-29's own human-check explicitly flagged this exact risk before it was reported:
  "Look at the close button specifically, in BOTH themes... Does it still read unmistakably as a
  button? If it sinks into the stage in either theme, say so — that is a designed contrast value in
  a follow-up round, not a colour picked during execution." UAT test 20 confirms the user's answer
  was "issue" with the verbatim report "On the dark needs a little more constrant."
  implication: Corroborates that this is a known, previously-scoped-out follow-up design item
  (not a regression the plan introduced blindly) — the plan's author already understood the button
  had no dedicated color treatment and deferred the contrast decision to this round.

## Resolution

root_cause: "`.pk-lightbox-close` (assets/css/app.css:3470-3475) declares no background/border
color of its own and carries no daisyUI color modifier class in its markup
(lib/pukllay_club_web/live/catalog_live/show.ex:751), so it falls back to daisyUI's default `.btn`
fill (`--btn-color` unset -> `var(--color-base-200)`). In dark theme, `--color-base-200` (#22103A)
is a very dark purple whose WCAG contrast against `--pk-shadow-color` (rgb(20 8 34) / #140822 —
the fixed literal both the lightbox scrim and the opaque stage fill are built from) computes to
approximately 1.1:1, well under the 3:1 non-text-contrast floor — so the button's circular chip
nearly disappears into the dark backdrop, leaving only its near-white icon visible. In light
theme the same unmodified default resolves base-200 to a near-white fill, which contrasts
strongly against that same fixed dark backdrop, so the identical unstyled button reads fine there.
This is a theme-color-vs-theme-invariant-surface asymmetry, not a defect introduced by plan
01.2-29's height change (which only made the surrounding dark surface more consistently present,
not the root color mismatch)."
fix: "(not applied — goal: find_root_cause_only)"
verification: "(not applicable — no fix applied)"
files_changed: []
