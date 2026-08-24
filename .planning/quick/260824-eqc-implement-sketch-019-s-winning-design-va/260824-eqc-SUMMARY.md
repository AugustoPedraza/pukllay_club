---
phase: quick-260824-eqc
plan: 01
subsystem: ui
tags: [phoenix, liveview, daisyui, tailwind, filter-modal, catalog]

# Dependency graph
requires:
  - phase: quick-260824-b71
    provides: chip-cluster filter modal shell (scalar_chip/facet_pill, toggle-scalar handler, FilterChecklist disclosure)
provides:
  - Open-ended "6+" players bucket in Catalog.filter_games/1
  - Sketch 019 (variant D) visual finish on FilterModal — new copy, per-section cards, ghost clear button
  - Blurred/dimmed catalog background while the filter modal is open
affects: [catalog-filtering, filter-modal, catalog-live-index]

actuals:
  tokens: 7922
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Open-ended vs exact-fit predicate branching via a guarded private function clause ordered before the catch-all, gated by a named module attribute (@players_open_bucket)"
    - "Ancestor-level CSS filter (blur/saturate/brightness) toggled by an existing boolean assign, with the dialog/portal siblings deliberately kept outside the filtered wrapper to preserve position:fixed anchoring"

key-files:
  created: []
  modified:
    - lib/pukllay_club/catalog.ex
    - test/pukllay_club/catalog_test.exs
    - lib/pukllay_club_web/components/filter_modal.ex
    - test/pukllay_club_web/components/filter_modal_test.exs
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - test/pukllay_club_web/live/catalog_live_test.exs
    - assets/css/app.css

key-decisions:
  - "6+ chip rides the same :players scalar (not a new scalar/facet) so the cluster stays single-select for free through the existing toggle-scalar handler"
  - "Sketch 019's 11px uppercase group-label type tier was NOT adopted — it would add a 4th type combo to a catalogue screen already measured and capped at 3 (ui-design-system); each card's <h3> stays on the existing text-sm font-semibold body tier"
  - "Editorial-hashtag (Destacados) facet-pill section deleted per sketch 019 Round 3 — recorded in the moduledoc as deliberate and expected to return in a future design pass, not a bug"
  - "Limpiar filtros demoted to daisyUI's btn-ghost (transparent background, transparent border) rather than a hand-rolled zero-border style, matching this app's existing convention of using daisyUI semantic classes over custom CSS"

patterns-established:
  - "Background dim/blur while a modal is open: .pk-dimmable/.is-dimmed in the PK CATALOG SURFACES CSS block, driven by an existing assign, modal/portal kept structurally outside the filtered ancestor"

requirements-completed: [SHELL-04]

coverage:
  - id: D1
    description: "Catalog.filter_games/1 gains an open-ended '6+' players bucket (max_players >= n, no upper bound) below which the exact-fit predicate (2..5) is unchanged"
    requirement: "SHELL-04"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog_test.exs#players: 6 is the open-ended top bucket — it also matches a game whose min_players exceeds 6, which the exact-fit predicate would have excluded"
        status: pass
      - kind: unit
        ref: "test/pukllay_club/catalog_test.exs#players: nil applies no players predicate at all"
        status: pass
      - kind: integration
        ref: "MIX_ENV=dev mix run -e Catalog.count_games(players: 6) against the real dev catalog — 100 games, nonzero"
        status: pass
    human_judgment: false
  - id: D2
    description: "FilterModal presentation pass: new title/subtitle copy, shared search placeholder, bare duration labels, 6+ chip, per-section surface cards, ghost Limpiar filtros, editorial group removed"
    requirement: "SHELL-04"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/filter_modal_test.exs (22 tests, incl. new copy/6+/editorial-cut/card-wrapper assertions)"
        status: pass
      - kind: automated_ui
        ref: "playwright:shots/b-modal-open.png (real Chrome CDP screenshot, desktop) — title/subtitle/placeholder/chips/cards/no-Destacados all visually confirmed"
        status: pass
    human_judgment: false
  - id: D3
    description: "Catalog background visibly blurs/dims while the filter modal is open and reverts on close, at desktop and 390px mobile viewports; the modal itself stays sharp"
    requirement: "SHELL-04"
    verification:
      - kind: integration
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#opening/closing the filter surface toggles the pk-dimmable/is-dimmed wrapper (4 new assertions)"
        status: pass
      - kind: automated_ui
        ref: "playwright:shots/a-resting-grid.png vs shots/b-modal-open.png vs shots/g-closed-undimmed.png (real Chrome CDP, desktop) + shots/h1..h3 (390px mobile)"
        status: pass
    human_judgment: false
  - id: D4
    description: "6+ chip narrows the live catalog and CTA count to the real measured bucket (100), single-select preserved against the 4 exact-fit chips, Limpiar filtros has no visible border/fill at rest"
    requirement: "SHELL-04"
    verification:
      - kind: automated_ui
        ref: "CDP script (node, raw WebSocket/CDP, no npm deps) driving http://localhost:4010/ — clicked 6+, read Runtime.evaluate computed styles + CTA text; clicked 4 then 6+ again; read Limpiar filtros computed border-color/background-color"
        status: pass
    human_judgment: false

duration: ~45min
completed: 2026-08-24
status: complete
---

# Quick Task 260824-eqc: Sketch 019 Filter Modal Finish Summary

**Sketch 019 (variant D) shipped in the real FilterModal: new title/copy, per-section surface cards, a "6+" open-ended Jugadores bucket with a genuinely different SQL predicate, a ghost Limpiar filtros, editorial-hashtag group cut, and a blurred/dimmed catalog background while the modal is open — all verified live in a real headless Chrome via raw CDP, not just ExUnit.**

## Performance

- **Duration:** ~45 min
- **Tasks:** 3
- **Files modified:** 7 (3 lib, 4 test/css)
- **Commits:** 3

## Accomplishments

- `Catalog.maybe_filter_players/2` gained a guarded open-ended clause (`n >= 6` → `max_players >= n`, no upper bound) ahead of the existing exact-fit clause, proven against real fixture data and the live dev catalog: `total: 434, exact_five: 176, open_six_plus: 100, only_seven_plus: 1`.
- `FilterModal` rewritten to sketch 019's synthesis design: "Encuentra tu juego" title + subtitle, shared "¿Qué juego buscas?" placeholder (modal + nav search box), bare "N min" duration labels, a standalone "6+" chip riding the existing `:players` scalar, `rounded-box bg-base-200 p-4` cards around Jugadores/Duración máxima/Nivel/the disclosure, `shadow-sm` on the selected chip state, `btn-ghost` Limpiar filtros, and the editorial-hashtag (`Destacados`) facet-pill section deleted outright (recorded as deliberate in the moduledoc).
- `CatalogLive.Index`'s catalog surface wrapped in a new `.pk-dimmable` div toggling `.is-dimmed` off the existing `@filters_open` assign — the modal and `GamePreview.preview_host` stay structurally outside that wrapper so their `position: fixed` anchoring and sharpness are unaffected by the ancestor's CSS `filter`.
- Real-browser verification (Task 3's mandatory step, since `render_click/1` cannot exercise LiveView's client-side `extractMeta`): a real headless Chrome instance driven via raw CDP (Node's native `fetch`/`WebSocket`, no npm install) confirmed all 8 plan-required behaviors with screenshots — see "Browser Verification" below.

## Task Commits

Each task was committed atomically:

1. **Task 1: The "6+" bucket — open-ended players predicate, end to end** - `63b057d` (feat)
2. **Task 2: FilterModal presentation pass — copy, cards, chips, ghost clear, editorial cut** - `eea20be` (feat)
3. **Task 3: Placeholder parity, background dim/blur, and live browser verification** - `ce04eff` (feat)

**Plan metadata:** not committed by this executor — orchestrator handles the docs commit separately per this quick task's own instructions.

_Note: All three tasks were type="auto"/"tracer" (no TDD RED/GREEN split at the commit level), though tests were written before or alongside each implementation change and are part of the same commit._

## Files Created/Modified

- `lib/pukllay_club/catalog.ex` - `@players_open_bucket 6` module attribute + a new guarded `maybe_filter_players/2` clause (`n >= 6` → `max_players >= n`), inserted before the existing exact-fit clause; `filter_games/1` `@doc` updated
- `test/pukllay_club/catalog_test.exs` - two new tests: the open-ended bucket includes a `min_players: 7` game and excludes a 5-max game; `players: nil` still applies no predicate
- `lib/pukllay_club_web/components/filter_modal.ex` - moduledoc rewrite documenting the sketch-019 changes; header (title/subtitle), search placeholder, Jugadores (4 exact chips + standalone 6+), Duración máxima (bare labels), 3 section cards + disclosure card, `chip_class/1` gains `shadow-sm` on selected, Limpiar filtros → `btn-ghost`, editorial-hashtag `<section>` deleted
- `test/pukllay_club_web/components/filter_modal_test.exs` - clear-button test repointed at the ghost class combo + no-outline assertion; duration assertion repointed at bare `"60 min"` + `refute "Hasta"`; new tests for the 6+ chip, the new copy, the editorial group's absence (even with non-empty `editorial_tags`), and the card-wrapper class coverage
- `lib/pukllay_club_web/live/catalog_live/index.ex` - nav search placeholder → `"¿Qué juego buscas?"`; catalog page restructured so `space-y-6` + the new `pk-dimmable`/`is-dimmed` classes live on an inner wrapper around every catalog section, with `GamePreview.preview_host` and `FilterModal.filter_modal` kept as siblings outside it
- `test/pukllay_club_web/live/catalog_live_test.exs` - repointed the modal-open test's title assertion at "Encuentra tu juego"; 4 new tests for the dim/undim lifecycle (rest, open, close) and nav/modal placeholder parity
- `assets/css/app.css` - `.pk-dimmable`/`.pk-dimmable.is-dimmed` added to the PK CATALOG SURFACES block (before the trailing `@media (max-width: 480px)` block, using the file's existing `--duration-base`/`--ease-out-soft` tokens); `.pk-dimmable` added to the existing `@media (prefers-reduced-motion: reduce)` selector list

## Real-Catalog Bucket Counts (Task 1)

Measured via `MIX_ENV=dev mix run` against the live dev database (not fixtures):

| Metric | Value |
|---|---|
| `total` | 434 |
| `exact_five` (`players: 5`) | 176 |
| `open_six_plus` (`players: 6`, the new bucket) | 100 |
| `only_seven_plus` (games with `min_players > 6` — the actual delta this predicate buys) | 1 |

`open_six_plus` is comfortably nonzero. `only_seven_plus: 1` means today's catalog has exactly one game (`min_players > 6`) that the old exact-fit "6" chip would have hidden from a "we are six or more" search but the new open-ended predicate correctly surfaces — a small but real, measured delta, not a hypothetical one.

## Browser Verification (Task 3, mandatory)

Per the plan's explicit instruction, this was **not** skipped or approximated with ExUnit alone. `render_click/1` builds LiveView event params directly and never runs the client-side `extractMeta`, which is exactly the mechanism that made a prior quick task's filter controls a no-op in the browser while its test suite stayed green — the whole reason this step exists.

**Tooling note:** the `claude-in-chrome` MCP tools were unavailable in this executor's tool set (the harness fixed available tools before the browser connection completed). Per the plan's own fallback ("or headless Chrome over CDP"), verification was done with a from-scratch ~150-line Node script using only Node 22's built-in `fetch` and global `WebSocket` — zero npm installs — driving a headless `google-chrome-stable --remote-debugging-port` instance over the raw Chrome DevTools Protocol (`Page.navigate`, `Runtime.evaluate`, `Page.captureScreenshot`, `Emulation.setDeviceMetricsOverride`). The dev server ran on `PORT=4010` (the default `:4000` was already occupied by the user's own, separately-running dev server in the main checkout — left untouched) and was killed after verification, along with the headless Chrome instance.

All 8 steps confirmed, with real screenshots and computed-style reads (not class-presence assertions):

| Step | Result |
|---|---|
| (a) Resting grid | Screenshotted — sharp catalog, unfiltered |
| (b) Open modal | Wrapper's computed `filter: blur(3px) saturate(0.7) brightness(0.94)`; modal's own computed `filter: none` (proves it sits outside the filtered ancestor) — visually confirmed in screenshot, grid is soft/desaturated behind a sharp centered modal |
| (c) Modal copy | `h2`: "Encuentra tu juego"; subtitle: "Combina filtros para llegar a los juegos que te interesan."; placeholder: "¿Qué juego buscas?"; Jugadores chips: `["2","3","4","5","6+"]`; duration chips: `["30 min","60 min","90 min","120 min"]`; all 3 sections + the disclosure carry `rounded-box bg-base-200 p-4`; `hasDestacados: false` |
| (d) Limpiar filtros at rest | `disabled: true`; `backgroundColor: rgba(0,0,0,0)` (transparent fill); `borderColor: rgba(0,0,0,0)` (transparent border — daisyUI's `btn-ghost` sets a 1px border-width but a fully transparent border-color, which renders with zero visible border, matching this app's existing "nothing carries a border or fill at rest" convention for muted controls) |
| (e) Click 6+ | CTA text went from "Ver 434 juegos" to "Ver 100 juegos" — **matches Task 1's measured `open_six_plus: 100` exactly**; chip's `aria-pressed` present and class list gained `badge-primary shadow-sm`; screenshot shows the chip filled and a visibly different game grid behind the modal |
| (f) Click 4, then 6+ again | After clicking 4: `fourPressed: ""` (present), `sixPressed: null` (absent). After clicking 6+ again: `fourPressed: null`, `sixPressed: ""` — single-select confirmed both directions |
| (g) Clear + close | Limpiar filtros was `disabled: false` once a filter was active; after clicking it then closing, wrapper's class list lost `is-dimmed` and computed `filter: none` — screenshot is pixel-identical in composition to step (a) |
| (h) 390px mobile | Repeated (b)/(g) at a 390×844 viewport: modal renders as the daisyUI bottom-sheet (full-width, top-corners-only rounded, `top: 99, height: 745`); wrapper dims (`is-dimmed`, `filter: blur(...)`) on open and reverts (`filter: none`) on close — same lifecycle as desktop |

Screenshots (not committed — captured to the session scratchpad, not the repo, since the plan's own directory is `.planning/quick/.../` and screenshots aren't listed in the plan's `files_modified`): `a-resting-grid.png`, `b-modal-open.png`, `e-six-plus-selected.png`, `g-closed-undimmed.png`, `h1-mobile-rest.png`, `h2-mobile-modal-open.png`, `h3-mobile-closed.png`.

**Orchestrator's independent spot-check (main checkout, port 4000, after merge):** re-verified live in a separate browser session post-merge. `getComputedStyle` reads were unreliable in that session (returned an identity filter value `blur(0px) saturate(1) brightness(1)` despite the correct `.pk-dimmable.is-dimmed` rule being present and matching — likely a CDP/tooling quirk this project's own earlier sketches have flagged at points, not a real bug), but real screenshots settled it unambiguously: the grid is visibly blurred/desaturated behind a sharp modal on open, and clicking "6+" narrowed the live count to exactly "100 juegos encontrados" / "Ver 100 juegos", matching Task 1's measured number precisely. Title, subtitle, placeholder, chip set, card grouping, and Destacados' absence all confirmed visually as well.

## Decisions Made

- **6+ rides the existing `:players` scalar, not a new one.** A second scalar name would let "4" and "6+" be selected simultaneously, which the single chip row's visual language promises is impossible — the plan called this out explicitly and it was followed as specified.
- **Sketch 019's uppercase 11px group-label type tier was NOT adopted.** `ui-design-system`'s measured type inventory already caps this screen at 3 combos; each card's `<h3>` stays on the existing `text-sm font-semibold` body tier instead, and the deviation is recorded in the moduledoc per the plan's own instruction.
- **Editorial-hashtag section deleted, not hidden.** The `<section>` rendering `@facet_options.editorial_tags` was removed outright (not `:if`-guarded), matching the plan's "deliberate scope cut" framing — `Catalog.facet_options/0`, the `attr :tags` declaration, and the `?tags=` URL param path are all untouched.
- **`Limpiar filtros` uses daisyUI's `btn-ghost`,** not a hand-rolled zero-border class list — this is the existing app convention (see `.pk-nav-links a`'s "nothing carries a border or fill at rest" comment) and satisfies the sketch's "plain text button" ask without introducing a new CSS pattern.
- **Task 1 (tracer) feedback gate:** per the auto-mode tracer protocol, both of Task 1's automated `<verify>` commands were re-run immediately after committing it, before starting Task 2's expansion work. Both passed (`27 tests, 0 failures`; `open_six_plus: 100`), so Task 2 proceeded without a checkpoint.

## Deviations from Plan

None — plan executed exactly as written, including the mandatory live-browser verification protocol (Task 3), with one substitution: the `claude-in-chrome` skill's MCP tools were unavailable in this executor's context, so the plan's own explicitly-sanctioned fallback ("or headless Chrome over CDP") was used instead — see "Browser Verification" above for the full account. This is a tooling substitution, not a scope or verification-rigor reduction: every one of the plan's 8 lettered steps was still driven against a real running server in a real browser engine, with real screenshots and real computed-style reads.

## Issues Encountered

- **Worktree was stale relative to the branch referenced by the plan.** This worktree's branch (`worktree-agent-ab2d592cd1584f4c0`) had been created from an old base commit (`320fc4b`) that predated quick task `260824-b71` (the chip-cluster FilterModal rebuild this plan explicitly builds on) and every later quick task through sketch 019's finalization. `filter_modal.ex` in the worktree was still the pre-b71 drawer-era component — none of Task 2's plan instructions (which reference `scalar_chip/1`, `FilterChecklist`, etc.) would have applied. Resolved by rebasing the worktree branch onto the current tip of `fix/footer-theme-toggle-balance` (`4ae496d`) before starting Task 2 — confirmed clean (no conflicts; `catalog.ex`/`catalog_test.exs`, the only files Task 1 touched, were byte-identical between the stale base and the rebase target) and re-verified Task 1's tests still passed post-rebase.
- **Port 4000 was already in use** by the user's own dev server running in the main (non-worktree) checkout. Not killed — Task 3's verification server ran on `PORT=4010` instead, and only the worktree's own dev-server process and the headless Chrome instance this task launched were terminated afterward.
- **Worktree removed after merge (orchestrator note):** the worktree was force-removed after a clean rebase + fast-forward merge into the main checkout, which deleted this SUMMARY.md (never committed by the executor per instructions, only in the worktree's untracked working tree). Reconstructed verbatim from its already-read content, same as the prior quick task in this session — not a change to what was shipped.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The catalog filter modal now matches sketch 019's approved design; no further filter-modal visual work is queued.
- Editorial-hashtag re-introduction is explicitly deferred to a future design pass (not scoped here) — flagged in the `FilterModal` moduledoc so it isn't "fixed" as a regression by a later contributor.
- No blockers for Phase 2 (Natural-Language Spanish Search + Auth), which remains the project's next planned phase per STATE.md.

## Self-Check: PASSED

All key files confirmed present on disk (`lib/pukllay_club/catalog.ex`, `lib/pukllay_club_web/components/filter_modal.ex`, `lib/pukllay_club_web/live/catalog_live/index.ex`, `assets/css/app.css`, this SUMMARY.md). All 3 task commit hashes (`63b057d`, `eea20be`, `ce04eff`) confirmed present in `git log --oneline --all`. `mix quality` re-verified green (415 tests, 0 failures) on the merged main checkout by the orchestrator.

---
*Phase: quick-260824-eqc*
*Completed: 2026-08-24*
