---
phase: 01-catalog-v1
plan: 07
subsystem: ui
tags: [phoenix-liveview, daisyui, tailwind, gap-closure]

requires:
  - phase: 01-catalog-v1
    provides: 01-06's GameChips components (weight_band_badge/1, chip_row/1, editorial_tags/1) and GameCard
provides:
  - Overflow-safe weight-band badge that grows its box instead of bleeding into the card title
  - Three visually ranked card tiers (large primary badge > small accent editorial chips > small neutral mechanic chips), grouped under a shared secondary wrapper
  - editorial_tags/1 with an optional limit (nil = uncapped), matching chip_row/1's cap pattern
  - Single clean focus ring on every plain .input/.select/.textarea app-wide
affects: []

actuals:
  tokens: 3120
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Size step first, hue second for chip-tier emphasis: badge-lg for the primary weight band vs badge-sm for both secondary rows, per ui-design-system's 'a large enough size gap outranks weight alone' rule"
    - "editorial_tags/1 and chip_row/1 share the identical take/overflow cap shape (visible = Enum.take(terms, limit); overflow = length(terms) - length(visible); trailing +N chip) — the pattern any future capped chip row should copy"
    - "focus:outline-hidden focus-within:outline-hidden suppresses only daisyUI's outer offset outline, leaving the border-colour/box-shadow ring as the single visible focus indicator"

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/components/game_chips.ex
    - lib/pukllay_club_web/components/game_card.ex
    - lib/pukllay_club_web/components/core_components.ex
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - test/pukllay_club_web/components/game_chips_test.exs
    - test/pukllay_club_web/live/catalog_live_test.exs
    - .planning/phases/01-catalog-v1/01-UI-SPEC.md

key-decisions:
  - "weight_band_badge/1's final class list: `badge badge-secondary badge-lg h-auto whitespace-normal py-1 text-center leading-tight` — h-auto releases daisyUI's height pin (the direct cause of G-01-2), badge-lg is the size step that makes it unambiguously primary (G-01-6)"
  - "editorial_tags/1's final chip class: `badge badge-sm badge-accent` (replacing the old raw `bg-accent text-accent-content` pair, closing a standing design-system violation in the same edit) with a new `limit` attr defaulting to nil (uncapped)"
  - "Card-level editorial-tag cap chosen as limit={2}: only 3 editorial hashtags exist in the live Vocabulary module, each a long CamelCase string, and 2 keeps the secondary block to one line at 2-column widths"
  - "outline-hidden (Tailwind v4's forced-colors-safe form) compiled successfully into priv/static/assets/css/app.css — no fallback to outline-none was needed"

patterns-established:
  - "Chip-tier hierarchy convention for GameCard: primary badge at badge-lg h-auto directly under the title, secondary rows (editorial + mechanic chips) grouped in one space-y-1 wrapper below it — documented in GameCard's moduledoc so a future edit doesn't flatten it back to co-equal siblings"

requirements-completed: [CATALOG-01, CATALOG-03, CATALOG-05, CATALOG-06, CATALOG-07]

coverage:
  - id: G-01-2
    description: "The weight-band label renders fully inside its own badge box at 2-column mobile widths — a wrapped second line grows the box instead of bleeding upward into the game title"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/game_chips_test.exs (badge-lg / h-auto assertion)"
        status: pass
      - kind: other
        ref: "grep -c 'badge badge-secondary badge-lg h-auto whitespace-normal py-1 text-center leading-tight' lib/pukllay_club_web/components/game_chips.ex -> 1"
        status: pass
    human_judgment: true
  - id: G-01-6
    description: "The weight-band badge is the visually dominant chip (size step, not just hue); editorial and mechanic chips read as one grouped, lighter secondary block; the editorial row can never exceed its cap"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/game_chips_test.exs, test/pukllay_club_web/live/catalog_live_test.exs (editorial-tag +N cap tests)"
        status: pass
    human_judgment: true
  - id: G-01-7
    description: "A focused search box, sort select, or any plain .input/.select/.textarea shows exactly one visible focus indicator, with focus still visibly indicated"
    verification:
      - kind: unit
        ref: "mix test --warnings-as-errors (full suite, 148 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "grep -c 'outline-hidden' priv/static/assets/css/app.css -> 2 (compiled); grep -c 'focus:outline-hidden focus-within:outline-hidden' lib/pukllay_club_web/components/core_components.ex -> 3; ...index.ex -> 1"
        status: pass
    human_judgment: true
---

# Phase 01 Plan 07: UAT gap closure — card chip hierarchy, badge overflow, double focus ring Summary

**Overflow-safe, three-tier browse-card chip hierarchy (large weight-band badge over a grouped, capped editorial+mechanic secondary block) plus a single clean focus ring app-wide, closing G-01-2/G-01-6/G-01-7.**

## Performance

- **Duration:** ~35 min active work
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- `GameChips.weight_band_badge/1` now renders `badge badge-secondary badge-lg h-auto whitespace-normal py-1 text-center leading-tight` — the auto-height box grows to fit a wrapped 3-word label instead of bleeding into the title above it (G-01-2), and the `badge-lg` size step makes it unambiguously the card's primary field (G-01-6)
- `GameChips.editorial_tags/1` uses the semantic `badge badge-sm badge-accent` modifier (replacing a raw `bg-accent text-accent-content` pair — a standing design-system violation closed in the same edit) and accepts an optional `limit` (`nil` = uncapped, matching `chip_row/1`'s existing take/overflow `+N` pattern)
- `GameCard`'s `card-body` now groups `editorial_tags` (capped at `limit={2}`) and `chip_row` (`limit={4}`) inside one shared `space-y-1` wrapper beneath the primary badge, so the card reads as title / primary / secondary-block / actions instead of five flat siblings
- `CoreComponents.input/1`'s `select`, `textarea`, and catch-all branches, plus the raw sort `<select>` in `catalog_live/index.ex`, all carry `focus:outline-hidden focus-within:outline-hidden`, suppressing daisyUI's outer offset-outline while leaving the border-colour/box-shadow ring as the single visible focus indicator
- `.planning/phases/01-catalog-v1/01-UI-SPEC.md` gained an `overflow` row documenting the editorial-tag cap, mirroring the existing mechanic-chip row

## Task Commits

Each task was committed atomically:

1. **Task 1: Three-tier GameChips hierarchy, overflow-safe weight badge** - `2fae9a7`
2. **Task 2: Regroup browse card into title/primary/secondary-block/actions** - `5e95f1e`
3. **Task 3: Collapse the double focus ring app-wide** - `c6464ec`

## Files Created/Modified

- `lib/pukllay_club_web/components/game_chips.ex` — `weight_band_badge/1` badge-lg/h-auto treatment; `editorial_tags/1` semantic accent modifier + `limit` cap
- `lib/pukllay_club_web/components/game_card.ex` — grouped secondary block, `limit={2}` on editorial tags, moduledoc names the three tiers
- `lib/pukllay_club_web/components/core_components.ex` — focus-outline override on select/textarea/catch-all `input/1` branches
- `lib/pukllay_club_web/live/catalog_live/index.ex` — focus-outline override on the raw sort `<select>`
- `test/pukllay_club_web/components/game_chips_test.exs` — updated class-literal split, new capped/uncapped editorial-tag coverage, badge-lg/h-auto assertion
- `test/pukllay_club_web/live/catalog_live_test.exs` — new grid-scoped assertions for the editorial-tag cap and the large weight-band badge
- `.planning/phases/01-catalog-v1/01-UI-SPEC.md` — new editorial-tag overflow row

## Decisions Made

- Editorial-tag card cap set to `limit={2}`: only 3 editorial hashtags exist in the live `Vocabulary` module (`#CreaConexiones`, `#EquipoGanador`, `#DuelosMemorables`), each a long CamelCase string, and 2 keeps the secondary block to a single line at 2-column widths
- `outline-hidden` (not the `outline-none` fallback) was used — the compiled stylesheet verification (`grep -c 'outline-hidden' priv/static/assets/css/app.css` → 2) confirmed the installed Tailwind v4 recognizes the utility, so no fallback was needed
- `chip_row/1` was left byte-identical, per the plan — it was already the correct tertiary tier

## Deviations from Plan

None — plan executed exactly as written. Test additions in Task 2 required scoping new assertions to the `#games` grid via the file's existing `grid_html/1` helper (not a plan deviation, just following the file's established double-counting-avoidance convention already documented in that helper's comment) after an initial unscoped assertion false-failed against the filter drawer's own `#DuelosMemorables` facet pill.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All three gap IDs (G-01-2, G-01-6, G-01-7) closed with automated coverage; `mix quality` passes end to end (hex.audit, deps.audit, deps.unlock --check-unused, format, credo --strict, sobelow, test — 148 tests, 0 failures)
- Human-check items remain for end-of-phase UAT per the plan's own `<human-check>` blocks: visual confirmation of badge/title non-overlap at a real narrow viewport, and visual confirmation of a single (not double) focus ring on the search box and sort dropdown
- No blockers for phase verification

---
*Phase: 01-catalog-v1*
*Completed: 2026-08-18*

## Self-Check: PASSED

All files created/modified confirmed present on disk; all 3 task commits (2fae9a7, 5e95f1e, c6464ec) confirmed in git log.
