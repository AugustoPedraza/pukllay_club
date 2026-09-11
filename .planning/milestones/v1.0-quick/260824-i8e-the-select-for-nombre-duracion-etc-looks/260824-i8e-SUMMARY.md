---
phase: quick-260824-i8e
plan: 01
subsystem: ui
tags: [liveview, catalog, phoenix, ux-cleanup]

# Dependency graph
requires:
  - phase: 01-catalog
    provides: "PukllayClub.Catalog's sort surface (@allowed_sorts, normalize_sort/1, apply_sort/2) and CatalogLive.Index's :sort assign/handle_params wiring"
provides:
  - "Catalog page (/) with the native sort <select> removed; sort machinery underneath (parse_sort/1, :sort assign, see_all_selection/1, URL-param deep links) untouched and still load-bearing"
affects: [catalog-live, ux-patterns-skill]

actuals:
  tokens: 2116
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Removing a stale client control while explicitly preserving the server-side state machine underneath it (parse_sort/1, :sort assign, see_all_selection/1) for other still-live callers (URL deep links, see-all shelf expansion)"

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - test/pukllay_club_web/live/catalog_live_test.exs
    - .claude/skills/ux-patterns/SKILL.md

key-decisions:
  - "Removed the dropdown's three nested markup levels entirely (no replacement spacer) rather than collapsing to a smaller wrapper, since Layouts.app's py-20 already supplies top rhythm and the plan explicitly forbade a reintroduced empty div"
  - "Retargeted the sort-reorder test at the surviving ?sort= URL-param entry point (a fresh live/2 mount) instead of deleting the coverage, proving parse_sort/1's non-default clauses stay reachable with no client control driving them"

patterns-established: []

requirements-completed: [CATALOG-04]

coverage:
  - id: D1
    description: "Sort dropdown ('Nombre', 'Duración: ...', 'Complejidad: ...', 'Más recientes') removed from the catalog page; no orphaned handle_event clause remains"
    requirement: "CATALOG-04"
    verification:
      - kind: unit
        ref: "grep gate confirming no <select|name=\"sort\"|phx-change=\"sort\"|handle_event(\"sort\" in index.ex"
        status: pass
      - kind: unit
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sort machinery underneath (parse_sort/1's 7 clauses, :sort assign, handle_params/3 URL-param read, see_all_selection year_desc mapping) stays byte-identical/functional; Catalog module untouched"
    requirement: "CATALOG-04"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — \"a non-default ?sort= param reorders the rendered cards\""
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — \"?sort=nope falls back to name order\""
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs — recientemente_anadidos see-all ordering test (~line 838)"
        status: pass
      - kind: unit
        ref: "git diff --quiet -- lib/pukllay_club/catalog.ex"
        status: pass
    human_judgment: false
  - id: D3
    description: "Vertical rhythm between subnav chip rail and first carousel row reads correctly with the dropdown gone (no leftover row, no collapsed gap), viewed at mobile width first then desktop"
    verification: []
    human_judgment: true
    rationale: "Visual spacing/rhythm assessment requires human eyes on a rendered page at two viewport widths — not automatable. Per this plan's own <verification> section, this human-check is deliberately deferred to the end-of-phase UAT batch (workflow.human_verify_mode = end-of-phase), not a mid-flight checkpoint halt."
  - id: D4
    description: "ux-patterns skill's B14 component inventory no longer claims a sort select exists"
    verification:
      - kind: unit
        ref: "grep gates: index.ex:251 reference count 0, B14 row present, table row count unchanged vs HEAD"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-08-24
status: complete
---

# Phase quick-260824-i8e: Remove stale catalog sort dropdown Summary

**Removed the hand-rolled native `<select>` sort control (and its orphaned `handle_event("sort", ...)` clause) from the catalog page while leaving `parse_sort/1`, the `:sort` assign, and every other consumer of the sort machinery (URL-param deep links, the "Recientemente añadidos" see-all shelf) fully intact.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-08-24T13:05:56-03:00 (branch tip before this plan)
- **Completed:** 2026-08-24T13:17:44-03:00
- **Tasks:** 2 completed
- **Files modified:** 3

## Accomplishments
- Deleted the three-level dropdown markup block (outer gutter div, flex wrapper, `<select>` with 6 options) from `catalog_live/index.ex`; `#carousel-rows` is now the first child of the `space-y-6 pk-dimmable` wrapper
- Deleted the now-orphaned `handle_event("sort", %{"sort" => sort}, socket)` clause — its only caller was the removed control
- Fixed the stale comment above `see_all_selection("recientemente_anadidos")` that referenced "the main grid's sort control" — it now explains the `:year_desc` choice directly against `PukllayClub.Catalog`'s sort surface
- Retargeted the DOM-bound sort-reorder test onto the surviving `?sort=playtime_desc` URL-param entry point (a fresh `live/2` mount), proving `parse_sort/1`'s non-default clauses stay reachable with no client control driving them
- Removed the stale sort-select clause (and its dangling `index.ex:251` line reference) from the `ux-patterns` skill's B14 "Filter and search" row

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove the sort dropdown and its orphaned event handler** - `3211a86` (feat)
2. **Task 2: Retarget sort test coverage and correct the ux-patterns inventory** - `c3b14b3` (test)

## Files Created/Modified
- `lib/pukllay_club_web/live/catalog_live/index.ex` - Dropdown markup and orphaned event handler removed; stale comment fixed
- `test/pukllay_club_web/live/catalog_live_test.exs` - Sort-reorder test retargeted from `select[name=sort]` DOM interaction to `?sort=playtime_desc` URL-param mount; `?sort=nope` and `recientemente_anadidos` see-all tests left untouched
- `.claude/skills/ux-patterns/SKILL.md` - B14 row's third column no longer documents a sort select that doesn't exist

## Decisions Made
- No replacement spacer, `pt-*` utility, or empty div was added in place of the removed dropdown row — `Layouts.app`'s existing `py-20` on `<main>` already supplies top rhythm, and the plan explicitly reserved any further rhythm adjustment for the human-check step (none was needed per the automated gates; final visual confirmation deferred to end-of-phase UAT per this plan's `human_verify_mode: end-of-phase` setting)
- Kept the DOM-bound sort test rather than deleting it outright — rewrote it to hit the `?sort=` URL-param path instead, preserving regression coverage for `parse_sort/1`'s non-default clauses now that no client control exercises them directly

## Deviations from Plan

None - plan executed exactly as written. All must-have truths, artifacts, and key-links held; `git diff --stat` touched exactly the three files the plan specified (`catalog_live/index.ex`, `catalog_live_test.exs`, `ux-patterns/SKILL.md`); `lib/pukllay_club/catalog.ex` appears in no hunk.

## Verification Results

- `mix compile --warnings-as-errors` — pass (Task 1 gate)
- Task 1 automated grep gates (no `<select`/`name="sort"`/`phx-change="sort"`/`handle_event("sort"`; `parse_sort/1` still has 7 clauses; `see_all_selection`/`handle_params` sort reads intact; `catalog.ex` unmodified) — all pass
- Task 2 automated grep gates (test file no longer references `select[name=sort]`, references `sort=playtime_desc`/`sort=nope`/`phx-value-row=recientemente_anadidos`; SKILL.md has zero `index.ex:251` references, retains the B14 row, and its total `| ` row count is unchanged vs. `HEAD`) — all pass
- `mix quality` (7 steps: `hex.audit`, `deps.audit`, `deps.unlock --check-unused`, `format --check-formatted`, `credo --strict`, `sobelow --config`, `test --warnings-as-errors`) — pass, exit code 0, 421 tests / 0 failures

## Known Stubs

None.

## Threat Flags

None — this plan's own `<threat_model>` covered the only trust-boundary-relevant surface (the `?sort=` query param path), and it is unchanged: `parse_sort/1` remains literal-string-clause-only with a catch-all, no `String.to_atom/1`, no new network/auth/file-access surface introduced.

## Issues Encountered

None.

## Next Phase Readiness

Task 1's `<human-check>` (mobile-first then desktop visual confirmation of the tightened subnav→carousel gap, and a manual confirmation of the "Recientemente añadidos" → "Ver todos" ordering) is deferred to the end-of-phase UAT batch per this plan's `human_verify_mode: end-of-phase` verification note — not a blocker for closing this quick task, but should be included in the next UAT pass.

---
*Phase: quick-260824-i8e*
*Completed: 2026-08-24*

## Self-Check: PASSED

- FOUND: lib/pukllay_club_web/live/catalog_live/index.ex
- FOUND: test/pukllay_club_web/live/catalog_live_test.exs
- FOUND: .claude/skills/ux-patterns/SKILL.md
- FOUND: commit 3211a86 (Task 1)
- FOUND: commit c3b14b3 (Task 2)
