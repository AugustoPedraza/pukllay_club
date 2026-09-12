---
status: resolved
trigger: "G-01-6: The game card on the catalog main page presents too much information at once with no clear visual hierarchy between primary and secondary fields — feels 'overloaded' for a casual/new player."
created: 2026-08-18T20:30:00.000Z
updated: 2026-09-12
audit_acknowledged:
  milestone: v1.0
  at: 2026-09-11
  status: diagnosed
---

## Current Focus

hypothesis: CONFIRMED (see Resolution)
test: n/a — diagnose-only mode
expecting: n/a
next_action: none — diagnosis complete, hand off to gsd-planner for gap-closure scoping

## Symptoms

expected: The game card on the main page presents information with clear visual hierarchy (primary vs. secondary fields), matching CLAUDE.md's "teach complexity, don't overwhelm" UX principle for a casual/new player.
actual: User reported the card shows too much information at once with no hierarchy ("overloaded"). Needs a redesign pass prioritizing which fields are primary vs. secondary.
errors: None reported
reproduction: Test 2 in .planning/phases/01-catalog-v1/01-UAT.md — load the main catalog page (/) and look at any game card
started: Discovered during UAT (Phase 01-catalog-v1)

## Eliminated

(none — single coherent hypothesis, confirmed directly by source inspection, no false starts)

## Evidence

- timestamp: 2026-08-18T20:35:00Z
  checked: lib/pukllay_club_web/components/game_card.ex (full read)
  found: >
    Card body (`card-body space-y-2 p-4`) stacks exactly 5 children with UNIFORM `space-y-2`
    (8px) rhythm and no grouping wrapper: (1) `<h3>` title, (2) `GameChips.weight_band_badge/1`,
    (3) `GameChips.editorial_tags/1`, (4) `GameChips.chip_row/1` (mechanics), (5) CTA button. No
    field is conditionally hidden/collapsed based on card context (grid vs. carousel — both call
    the same component). Player count / playtime / age (all present on `Game` schema) are NOT
    rendered on the card at all — the density problem is not "too many raw metadata fields," it
    is specifically 3 independently-sourced badge/chip collections competing for attention.
  implication: >
    The card has no structural (spacing/grouping) signal distinguishing "read this first" from
    "optional detail" — every row gets the exact same visual rhythm as every other row.

- timestamp: 2026-08-18T20:40:00Z
  checked: lib/pukllay_club_web/components/game_chips.ex (full read)
  found: >
    weight_band_badge/1 (line 32): `<span class="badge badge-secondary">` — no size modifier
    (default/medium badge size). editorial_tags/1 (line 75): `<span class="badge bg-accent
    text-accent-content">` — ALSO no size modifier (same default/medium badge size as the
    weight-band badge). chip_row/1 (mechanics, line 59): `<span class="badge badge-sm">` — the
    ONLY one of the three that uses a smaller size. So weight-band (the single most important
    complexity-teaching signal per CATALOG-05/01-06 moduledoc) and editorial hashtags (a
    secondary curatorial flavor signal) render at the IDENTICAL badge size — the only
    differentiation between them is background-color hue (violet `badge-secondary` vs.
    light-lavender `bg-accent`).
  implication: >
    Per ui-design-system's own documented rule ("weight and color, not a new size, are the
    emphasis lever... a large enough size gap still outranks weight alone"), using color alone to
    separate a primary field from a secondary one — with no complementary size/weight difference
    — is a weak, easily-missed signal, especially for a casual/new-player audience the app is
    explicitly designed to teach rather than assume familiarity from.

- timestamp: 2026-08-18T20:45:00Z
  checked: "editorial_tags/1 vs. chip_row/1 cap behavior (game_chips.ex:38-63 vs. 65-78)"
  found: >
    chip_row/1 (mechanics) explicitly caps rendering: `attr :limit, :integer, default: 4` plus a
    trailing "+N" overflow badge (lines 48-51) — an established, already-working pattern in this
    same file for "render up to N, then summarize the rest." editorial_tags/1 has NO limit attr
    and NO cap at all (lines 70-78) — it unconditionally renders every tag a game has.
  implication: >
    The file already contains the correct pattern for demoting an overflow-prone secondary field
    (chip_row's cap+overflow), but editorial_tags/1 does not use it — it is the one collection on
    the card with no ceiling on how much space it can consume.

- timestamp: 2026-08-18T20:48:00Z
  checked: lib/pukllay_club/catalog/vocabulary.ex (@editorial_tags, lines 46-50)
  found: >
    Only 3 editorial hashtags exist system-wide (#CreaConexiones, #EquipoGanador,
    #DuelosMemorables — not the 6 in the older/superseded 01-UI-SPEC.md list), each a fairly long
    string (13-17 chars incl. "#"). A single game can plausibly carry 2-3 of these simultaneously
    (e.g., a simple 2-player cooperative game qualifies for all three), so the uncapped
    editorial_tags/1 row can itself wrap to 2 lines, on top of the weight-band badge above it and
    the (separately capped-at-5) mechanic chip row below it.
  implication: >
    Confirms the uncapped collection is not a theoretical risk — a real, plausible game can push
    the editorial-tags row past 1 line, compounding the stacked-badge density.

- timestamp: 2026-08-18T20:50:00Z
  checked: .planning/phases/01-catalog-v1/01-UI-SPEC.md "Visual Hierarchy" and "Color" sections
  found: >
    The UI-SPEC's card-level color reservation table only distinguishes 2 tiers by design intent
    — "primary" (accent/CTA-reserved, `#3D096D`) and everything else — and explicitly locks
    editorial hashtags to "a single consistent style, all hashtags... no per-hashtag colors" with
    no stated cap or truncation rule for how many hashtags may render on one card. The spec's own
    "UI Considerations" table (line 243) DOES cap the mechanic chip row ("Cap visible chips at
    3-4 per card with a '+N' overflow indicator") but has no equivalent row for editorial tags —
    the spec itself never made a density decision for that field, which is consistent with the
    code's gap.
  implication: >
    This is not a code-only oversight — the phase's own UI-SPEC never scoped a density/cap rule
    for editorial tags, only for mechanics. The gap traces back to spec, not just implementation.

## Resolution

root_cause: >
  Two jointly-contributing causes (AND-gate: both must co-occur to produce "overloaded, no
  hierarchy" as reported — either alone would be a minor nit).

  (1) [code] `GameCard.game_card/1` (lib/pukllay_club_web/components/game_card.ex:67-77) stacks
  three semantically distinct chip/badge collections — `GameChips.weight_band_badge/1` (the
  single primary complexity-teaching signal, CATALOG-05), `GameChips.editorial_tags/1` (secondary
  curatorial flavor, CATALOG-07), and `GameChips.chip_row/1` (tertiary mechanic detail,
  CATALOG-06) — directly beneath the title with uniform `space-y-2` rhythm and no grouping. Two
  of the three (`weight_band_badge/1` and `editorial_tags/1`, lib/pukllay_club_web/components/
  game_chips.ex:32,75) render at the IDENTICAL default badge size, differentiated only by
  background-color hue — violating the project's own documented emphasis-lever rule that color
  alone (without a complementary size/weight distinction) is too weak a signal, especially for a
  casual/new-player audience. Only the mechanic chip row uses a smaller size (`badge-sm`),
  and it sits visually last, not clearly "more secondary" than the tags row above it.

  (2) [code+spec] `GameChips.editorial_tags/1` (lib/pukllay_club_web/components/game_chips.ex:
  65-78) has no cap/limit and no overflow indicator, unlike its sibling `chip_row/1` in the same
  file which already implements the correct `limit` + "+N" pattern. A game can plausibly carry
  2-3 editorial hashtags (each a long `#CamelCase` string), so this row can itself wrap to
  multiple lines with no ceiling. `.planning/phases/01-catalog-v1/01-UI-SPEC.md`'s own "UI
  Considerations" table capped the mechanic row but never made an equivalent density decision for
  editorial tags — the gap originates in the phase spec, not only the implementation.

  Together: the card unconditionally renders 3 stacked badge/chip rows (1 primary + 2 effectively
  co-equal "secondary" rows, one of which is uncapped) with no structural or strong visual signal
  telling a first-time viewer which one to read first — matching the reported "too much
  information at once with no hierarchy" precisely.
fix: "plan 01-07 (commit `5e95f1e`) first grouped the three chip/badge rows with a `badge-lg`/cap treatment, but plan 01-10 (commit `5944382`, `feat(01-10): strip resting card to poster plus single-line title`) superseded that entirely — the resting `GameCard.game_card/1` now renders ONLY the cover image and a single-line title, and every chip/badge (weight band, editorial tags, mechanic chips) was moved off the resting card into `GamePreview`'s desktop hover-intent portal / mobile full-screen sheet. The root cause's mechanism (three stacked chip rows inside `card-body`) no longer exists in the resting card at all."
verification: |
  - `grep -n 'weight_band_badge\|editorial_tags\|chip_row\|GameChips\.' lib/pukllay_club_web/components/game_card.ex` -> 0 hits (only a prose mention of `GameChips` in the moduledoc, referring to the detail page, not this component's own render): the three co-equal chip/badge rows this root cause names are entirely absent from game_card.ex's render function (lib/pukllay_club_web/components/game_card.ex:66-107) — the card now renders only `<figure class="pk-card-poster">` (cover) and `<h3>{@game.name}</h3>` (lines 76-103).
  - lib/pukllay_club_web/components/game_card.ex:9-16 (moduledoc): "Every secondary fact — players, tiempo, difficulty, one editorial tag, the `Ver detalles` CTA — lives behind interaction in `PukllayClubWeb.GamePreview` ... None of it renders on the resting card."
  - 01-10-SUMMARY.md's coverage row D1: "Resting card shows only poster + single-line title, no weight badge/tags/mechanics/CTA", verified by test `test/pukllay_club_web/live/catalog_live_test.exs#a resting grid card carries no chip, badge, or button markup for a game with tags and mechanics (sketch 002)`, status pass.
  - The uncapped-editorial-tags half of the AND-gate is also independently closed: `GameChips.editorial_tags/1` (lib/pukllay_club_web/components/game_chips.ex:147-149) now has a `limit` attr with overflow `+N` handling, mirroring `chip_row/1`'s existing cap pattern — though this component no longer has any call site on GameCard at all (game_chips.ex:70-71, 125-126: "GameCard uses neither this nor chip_row/1").
files_changed:
  - lib/pukllay_club_web/components/game_card.ex
  - lib/pukllay_club_web/components/game_preview.ex
  - lib/pukllay_club_web/components/game_chips.ex
