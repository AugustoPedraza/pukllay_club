---
phase: quick-260910-hdc
plan: 01
subsystem: ui-theming
tags: [css, dark-mode, contrast, design-tokens]
dependency-graph:
  requires: []
  provides: ["--pk-ink-brand token", "dark --color-neutral retune"]
  affects:
    - assets/css/app.css (dark theme ink roles)
    - .planning/sketches/themes/default.css (dark --color-text-muted mirror)
tech-stack:
  added: []
  patterns:
    - "First theme-scoped `--pk-*` custom token (`--pk-ink-brand`), declared under both `:root` and `:root[data-theme=\"dark\"]`, light side a variable read of `--color-primary` (never a copied hex)"
    - "OKLCh chroma/hue ExUnit helpers (sRGB -> linear -> OKLab -> polar) added to catalog_show_test.exs, reused across both tasks' tripwires"
key-files:
  created: []
  modified:
    - assets/css/app.css
    - test/pukllay_club_web/live/catalog_show_test.exs
    - .planning/sketches/themes/default.css
decisions:
  - "Task 1: `--pk-ink-brand` = dark's brand hue (H313.1, taken from the developer-locked `--color-primary`) at OKLCh C0.13 — 2.3x the C0.057 chroma `--color-neutral` was carrying for this role. Light resolves the token to `var(--color-primary)`, byte-identical to today."
  - "Task 1: the whole 24-selector dark-scoped ink-swap block (nav links, hashtag pills, filter/chip/crumb/drawer hover states) plus `.pk-preview-cta`/`.pk-btn-secondary` now read `--pk-ink-brand` instead of `--color-neutral` — this is the branded-interactive-ink tier. `.pk-pill-interactive:hover` moved out of the dark-scoped list into its own unscoped base rule (also fixes a previously-unaddressed 2.08:1 dark hover border)."
  - "Task 2: dark `--color-neutral` #B8A6CC -> #C59CDC, same lightness (contrast margins preserved), chroma lifted 0.057 -> 0.10 onto the same brand hue — the muted-ink tier, one step below `--pk-ink-brand` (C0.13) and two below the fill (`--color-primary`, C0.21)."
  - "Result: one purple hue (H313.1) in three deliberate chroma tiers across dark theme — fill > interactive ink > muted ink — replacing the prior two-purples-6.6-degrees-apart defect."
metrics:
  duration: ~55min
  completed: 2026-09-10
actuals:
  tokens: 42000
  tasks: 2
  commits: 2
status: complete
---

# Quick task 260910-hdc: Fix inconsistent purple CTA colors across dark mode Summary

Replaced two ad-hoc dark-scoped `--color-neutral` ink-swaps (sketch 055/056) with one new
`--pk-ink-brand` token on dark's own brand hue, and retuned dark's `--color-neutral` onto that
same hue at a lower chroma — closing the "reads as disabled, not interactive" defect reported
against dark mode's nav links, `Ver detalles` CTA, editorial hashtag pills, and the
mechanics/theme pill/label/stat family.

**Task 3 (checkpoint:human-verify) is now resolved.** The orchestrator drove the dev server via
browser automation to visually verify both themes (nav bar, `Ver detalles` outline CTA, detail
page pills/labels/BGG stats, `Reserva` CTA) and presented the plan's three checkpoint questions
to the developer, who confirmed all three: nav links and `Ver detalles` read as interactive (not
disabled) in dark mode; pills/labels/stats read as the same purple family as `Reserva`; light
mode is unchanged. See "Pending Checkpoint" below for the full walkthrough record.

## What Was Built

**Task 1 — `--pk-ink-brand`, wired end-to-end (commit `1bf09f6`)**

- Declared `--pk-ink-brand` under `:root` (light: `var(--color-primary)`, a variable read, never
  a copied hex) and a new `:root[data-theme="dark"]` rule (dark: `#C791E5`, OKLCh L74% C0.13
  H313.1 — dark's brand hue at 2.3x the chroma `--color-neutral` was carrying for this role).
  Measured contrast: 6.43:1 / 5.71:1 / 4.89:1 against dark base-100/200/300 — clears both the
  4.5:1 WCAG 1.4.3 text floor and the 3:1 1.4.11 border floor on all three grounds.
- Re-pointed the shared 24-selector dark override block (nav links at rest/hover/focus/current,
  editorial hashtag pills, search-morph toggle, filter trigger, breadcrumb, category menu,
  drawer links, chip hover/focus, description toggle, BGG stat hover, share trigger) from
  `--color-neutral` to `--pk-ink-brand`.
- Re-pointed `.pk-preview-cta` / `.pk-btn-secondary`'s dark-scoped `color` AND `border-color`
  from `--color-neutral` to `--pk-ink-brand`.
- Moved `.pk-pill-interactive:hover` out of the dark-scoped list into its own unscoped base rule
  reading `--pk-ink-brand` for both `color` and `border-color` — this also closes a previously
  unaddressed defect (that hover state's border was never dark-scoped at all before this task,
  so it measured 2.08:1, under the 3:1 border floor).
- Added `parse_rgb/1`, `srgb_channel_to_linear/1`, `oklab/1`, `oklch_chroma/1`, `oklch_hue/1`,
  and `dark_pk_ink_brand_root_block/0` helpers to `catalog_show_test.exs` (the chroma/hue
  helpers reused by Task 2's tests). Rewrote the `.pk-pill-tag` and secondary-CTA ink-swap tests
  to assert the new token by name, its three dark-ground contrast ratios, its OKLCh chroma floor
  (>= 0.11), and that light's declaration is a variable read of `--color-primary`.

**Task 2 — dark's muted ink onto the brand hue (commit `f78f105`)**

- Dark `--color-neutral` `#B8A6CC` -> `#C59CDC` in `assets/css/app.css`'s dark `daisyui-theme`
  block. Same lightness (L75.3% -> L75.2%, effectively unchanged, so every pre-existing contrast
  assertion keeps its measured margin), chroma lifted 0.057 -> 0.10 onto dark's brand hue
  (H313.1) — previously 6.6 degrees off it. Measured: 6.85:1 / 6.08:1 / 5.20:1 against dark
  base-100/200/300, 8.27:1 against `--color-neutral-content`.
- Updated the sketch 054 MEASURED CONSTRAINTS comment above the dark `daisyui-theme` block with
  the new muted-on-bg ratio and an explanation of why the value moved.
- Mirrored the new value into `.planning/sketches/themes/default.css`'s `--color-text-muted` in
  BOTH dark regions (the `prefers-color-scheme` media query and the explicit
  `:root[data-theme="dark"]` selector) — `check-theme-drift.sh` checks app.css against the
  media-query region, then checks the two dark regions against each other.
- Added a hue-alignment tripwire (dark `--color-neutral`'s hue within 2° of dark
  `--color-primary`'s hue) and a chroma-ordering tripwire (`--color-neutral`'s chroma strictly
  between the superseded `#B8A6CC` value and `--pk-ink-brand`) to `catalog_show_test.exs`.

**Net effect:** dark theme now carries one purple hue (H313.1) in three deliberate chroma
tiers — fill (`--color-primary`, C0.21) > interactive ink (`--pk-ink-brand`, C0.13) > muted ink
(`--color-neutral`, C0.10) — replacing the prior defect of two purples 6.6 degrees apart, one of
which (the branded-interactive role) had collapsed to 38% of light theme's own branded-ink
saturation.

## Verification Results

- `mix test test/pukllay_club_web/live/catalog_show_test.exs` — 186 tests, 0 failures (after
  Task 2; 185/0 after Task 1 alone).
- `mix format --check-formatted` — clean, no diff.
- `.planning/sketches/themes/check-theme-drift.sh` — exits 0, all 26 mapped pairs OK, both dark
  regions agree.
- `grep -q 'pk-ink-brand' assets/css/app.css` — present.
- `git diff --stat` across both commits touches exactly the three files the plan names:
  `assets/css/app.css`, `test/pukllay_club_web/live/catalog_show_test.exs`,
  `.planning/sketches/themes/default.css`.
- `git diff assets/css/app.css` for the light `daisyui-theme` plugin block — empty (untouched),
  confirmed via targeted diff extraction.
- **`mix quality` — PASSED.** 7-step alias (`hex.audit`, `deps.audit`,
  `deps.unlock --check-unused`, `format --check-formatted`, `credo --strict`, `sobelow`, `test`):
  exit code 0. Credo found 1 pre-existing low-severity design suggestion in
  `core_components.ex` (unrelated file, not touched by this task). Sobelow found only
  pre-existing Low Confidence findings in unrelated files (`csv_import.ex`, `report.ex`,
  `catalog_live/index.ex`). Full suite: **908 tests, 0 failures** (up from the ~907 baseline —
  net +1 test from Task 2's hue/chroma-ordering tripwire).

## Deviations from Plan

None — plan executed exactly as written for Tasks 1 and 2. One self-correction during execution
(not a deviation from the plan's intent, a tool-usage mistake caught and fixed before commit):
an initial `replace_all` edit to `.planning/sketches/themes/default.css` only updated one of the
two dark regions' `--color-text-muted` declarations; caught immediately by running
`check-theme-drift.sh` before committing, and fixed with a follow-up edit before any commit was
made. No incorrect state was ever committed.

## Pending Checkpoint (Task 3 — RESOLVED)

**`mix quality` result (per the plan's own instruction to report this first):** PASSED — see
"Verification Results" above (908 tests, 0 failures, no new Credo/Sobelow findings).

**Walkthrough performed** via Chrome browser automation against the running dev server
(`localhost:4000`), toggling `data-theme` directly: catalog home (nav bar `Inicio`/`Quiénes
Somos`, card hover `Ver detalles` outline CTA) and a game detail page (`/juegos/177`, mechanics/
theme pills, `AÑO`/`DISEÑADORES`/`MECÁNICAS` labels, Comunidad BGG stats, solid `Reserva` CTA),
each in both light and dark themes.

**Questions asked and answered:**

- Do the nav links and the `Ver detalles` button now read as interactive rather than disabled?
  **Yes, looks right.**
- Do the pills, labels and stats read as the same purple family as the `Reserva` CTA?
  **Yes, same family now.**
- Is light mode indistinguishable from before? **Yes, unchanged.**

Developer approved with no further adjustment needed — the `--pk-ink-brand` chroma headroom
(C0.15 / `#CC8DED`) noted in the plan was not required.

## Self-Check: PASSED

- FOUND: assets/css/app.css (`--pk-ink-brand` token present, dark `--color-neutral` = `#C59CDC`)
- FOUND: test/pukllay_club_web/live/catalog_show_test.exs (new helpers + 4 updated/added tests
  present, 186 tests passing)
- FOUND: .planning/sketches/themes/default.css (`--color-text-muted` = `#C59CDC` in both dark
  regions)
- FOUND commit `1bf09f6` (Task 1) — `git log --oneline --all | grep 1bf09f6` confirmed
- FOUND commit `f78f105` (Task 2) — `git log --oneline --all | grep f78f105` confirmed
