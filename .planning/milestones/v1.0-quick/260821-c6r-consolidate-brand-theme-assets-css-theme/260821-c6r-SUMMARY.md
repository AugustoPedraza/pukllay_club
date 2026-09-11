---
status: complete
---

# Summary: Consolidate brand theme (260821-c6r)

Executed inline via `/gsd-fast` against the replanned `260821-c6r-PLAN.md`, using the plan's
default decisions (approved without further discussion).

## Decisions taken (Task 1)

- **D1 — geometry tokens (radius/border/size/depth): DEFERRED.** No change to `assets/css/app.css`.
  The proposed alternative (rounder radii, `1px` border, flat `depth:0`) remains recorded in the
  plan's comparison table for a future follow-up task; not re-derived here.
- **D2 — sketch dark palette: CONFORM to the app.** `.planning/sketches/themes/default.css`'s two
  dark regions were re-derived from `assets/css/app.css`'s shipped `dark` daisyUI theme block.
- **D2b — orphan file: RETIRE properly.** `dark-purple.css` deleted; its two live consumers
  (sketches 006 and 009) converted to the real `data-theme` toggle mechanism first.

Net effect: **zero change to the live app's rendering** — only `.planning/sketches/` and
`.claude/skills/ui-design-system/SKILL.md` were touched.

## Before/after: sketch dark palette (D2)

| Variable | Before (dark-purple fork) | After (conforms to `app.css`'s dark theme) |
|---|---|---|
| `--color-bg` | `#150826` | `#170A26` |
| `--color-surface` | `#22103A` | `#22103A` (unchanged) |
| `--color-surface-2` | `#2E1750` | `#2F1750` |
| `--color-text` | `#F3ECFA` | `#F3ECFA` (unchanged) |
| `--color-text-muted` | `#A78FC0` | `#B8A6CC` |
| `--color-primary` | `#9D5CE6` | `#A97FD1` |
| `--color-primary-content` | `#FFFFFF` | `#170A26` |
| `--color-secondary` | `#C9A6F5` | `#7E4CA5` |
| `--color-accent-bg` | `#2E1750` | `#3D2A56` |
| `--color-accent-text` | `#E4D4FA` | `#E4D3F5` |
| `--color-border` | `#3A2159` | `#2F1750` |
| `--color-danger` | `#E0607F` | `#E06B90` |
| `--color-success` | `#5CC79A` | `#5FBE95` |

Applied identically to both of `default.css`'s dark regions (`@media (prefers-color-scheme: dark)`
and `:root[data-theme="dark"]`) — confirmed still byte-identical to each other by
`check-theme-drift.sh`. `--shadow-*` overrides were left untouched (black-based, no upstream
daisyUI equivalent).

## Retired: `dark-purple.css`

Deleted. Its 13 original color values are preserved in `.planning/sketches/MANIFEST.md`'s
`## Themes` section (2026-08-21 entry) so the exploration remains recoverable without git
archaeology. Sketches 006 and 009 — its only two live consumers, via a theme-file-swap `<select>`
— were converted first to the real `data-theme` toggle (same mechanism as 007/011), so no
theme-switcher option in the repo points at a missing file. Sketches 001–005 keep their old,
harmless file-swap `<select>` (only offers `default`, which exists) — not touched, out of scope.

## New artifact: `check-theme-drift.sh`

`.planning/sketches/themes/check-theme-drift.sh` — proven against the real pre-fix drift before
any value changed: 13/13 light pairs OK, 11/13 dark pairs drifting (matching the plan's F6/F7
findings exactly). After the D2 fix: all 13 light + 13 dark pairs OK, and both dark regions agree
— exits 0.

## Also done (Task 4)

`.claude/skills/ui-design-system/SKILL.md`'s `## Theme tokens` section now states: `app.css` is
the sole file allowed to declare a `daisyui-theme` block; theme names are locked to `light`/`dark`
(four hardcoded dependents listed); sketch themes mirror `app.css` via `default.css`'s mapping
table, checked by `check-theme-drift.sh`.

## Verification

- `check-theme-drift.sh` exits 0 (26/26 color pairs, both dark regions agree).
- No sketch theme-switcher option points at a missing file (checked across all of 001–009).
- Zero stray `#RRGGBB` hex literals in `lib/` or `assets/js/`.
- Exactly one file in the repo declares `daisyui-theme` blocks: `assets/css/app.css`.
- `mix quality` passes (format, Credo, Sobelow — pre-existing low-confidence findings in
  `csv_import.ex`/`report.ex` unrelated to this change — and 191 tests, 0 failures).
- Task 5 (human browser visual-check) was not run: D1 was deferred, so nothing under `assets/`
  changed and there is no live-app rendering risk from this task. Worth doing before the D1
  follow-up task, since that one *does* change rendered pixels.

## Left for later

D1 (geometry tokens) is still open. See `260821-c6r-PLAN.md` Task 1's comparison table for the
proposed radius/border/size/depth values and the `<if_adopting_d1>` block for how to apply them
safely (byte-level diff gate, `01-UI-SPEC.md` update, mandatory Task 5 visual check).
