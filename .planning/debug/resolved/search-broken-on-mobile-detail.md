---
status: resolved
trigger: "Search doesn't work on a game's detail page on mobile"
created: 2026-09-12
updated: 2026-09-12
---

# Debug: search-broken-on-mobile-detail

## Symptoms

- **Expected:** Searching from a game's detail page behaves the same as searching on `/` (home route) — results for the query.
- **Actual:** Tapping search does nothing.
- **Errors:** None visible.
- **Environment:** Production (pukllay.club), Android Chrome, mobile viewport.
- **Timeline:** Never worked on mobile detail pages (not a regression as far as the user knows).
- **Reproduction:** Open any game detail page on Android Chrome, tap the search control → no response.

## Current Focus

- bug_class: Bohrbug (deterministic — every tap, every device)
- known_pattern_candidate: none directly (KB search-* entries are CSS/visual; phx-value-collision is the "inert control, green tests" class — checked, not applicable: toggle uses phx-click with no phx-value)
- hypothesis: CatalogLive.Show hardcodes `search_expanded={false}` and handles `open-search` as a no-op, so the header toggle's server round trip never adds `.is-open`; the input stays `width:0; opacity:0; pointer-events:none` (app.css `.pk-search-morph .pk-nav-search`). Affects ALL viewports, not just mobile.
- status: RESOLVED — human confirmed fixed on device (2026-09-12)
- next_action: none — session archived; code committed on local main (not pushed; origin/main is PR-only)

reasoning_checkpoint:
  hypothesis: "Show's no-op open-search handler + hardcoded search_expanded={false} means the server never renders .is-open on .pk-search-morph, so the collapsed input (width 0 / opacity 0 / pointer-events none) is never revealed after a tap"
  confirming_evidence:
    - "LiveViewTest clicking the real .pk-search-morph-toggle on /juegos/:id renders no .pk-search-morph.is-open (4/5 new tests RED)"
    - "app.css only reveals .pk-nav-search under .pk-search-morph.is-open; no media query opens it by default"
    - "git 2798cd5 removed client-side is-open toggling and gave Show only no-op clauses"
  falsification_test: "If after making Show's handlers set :search_expanded the tests still render no .is-open, or if the input were reachable in the closed state via some CSS path, the hypothesis is wrong"
  fix_rationale: "The morph's open state is by contract (01.2-11) owned by the page's assign; giving Show a real assign driven by the same two events Index uses restores the only mechanism that can open it — root cause, not a CSS workaround"
  blind_spots: "Cannot browser-verify on Android Chrome here: (a) hook's programmatic focus() after the round trip may not raise the soft keyboard (same as Index — user still taps the input); (b) implicit Enter-submission of the native GET form from Android keyboard not exercised by LiveViewTest"
  candidate_causes:
    - "code: Show no-op handlers / hardcoded false assign (CONFIRMED)"
    - "config/environment: CSS breakpoint rule hiding the morph or a colocated hook failing to register in prod — eliminated: hook owns only focus, no class toggling; CSS has no default-open path at any width"
    - "data: phx-value collision on toggle — eliminated: toggle has no phx-value-*"
  and_gate: "no — single sufficient cause: even with perfect CSS/hook, no .is-open is ever rendered. Contributing gap (not a cause): the event-coverage class guard only asserts a clause exists"

## Eliminated

- hypothesis: phx-value-value collision (KB phx-value-collision) makes the toggle inert
  evidence: toggle/close buttons carry only phx-click, no phx-value-* attrs
  timestamp: 2026-09-12

- hypothesis: mobile-only CSS (<=480px block) hides the input even when open
  evidence: closed-state hiding lives in the base (all-viewport) rule; <=480px block only repositions the pill; bug is viewport-independent, opening never happens at all
  timestamp: 2026-09-12

- hypothesis: detail page is a dead render so phx-click does nothing
  evidence: router mounts /juegos/:id as `live` CatalogLive.Show; LiveViewTest render_click reaches handle_event (no crash, returns render)
  timestamp: 2026-09-12

## Evidence

- timestamp: 2026-09-12
  checked: lib/pukllay_club_web/components/layouts.ex header_inner/1 (lines 731-760)
  found: `.pk-search-morph` gets `is-open` ONLY from `@search_expanded`; toggle button has `phx-click="open-search"`, close has `phx-click="close-search"`. No client JS adds/removes is-open (CatalogNav hook only moves focus on data-search-expanded transitions).
  implication: whether the pill opens is entirely decided by the page LiveView's handler + assign.

- timestamp: 2026-09-12
  checked: lib/pukllay_club_web/live/catalog_live/show.ex lines 132-143 and render/1 line 313
  found: `handle_event("open-search", _, socket), do: {:noreply, socket}` (no-op) and `<Layouts.app ... search_expanded={false}>` hardcoded.
  implication: tapping the icon on the detail page round-trips, changes nothing, re-renders nothing — "tap does nothing, no error" exactly matches symptoms.

- timestamp: 2026-09-12
  checked: assets/css/app.css `.pk-search-morph .pk-nav-search` (1904-1917) and `.pk-search-morph.is-open .pk-nav-search` (2037-2041); grep of all later @media blocks
  found: closed state = `width: 0; opacity: 0; pointer-events: none` at every viewport; only `.is-open` restores it. No breakpoint renders the morph open by default.
  implication: the detail-page GET form input is unreachable at ALL widths (desktop included), not only mobile; user reported mobile because that is their primary device.

- timestamp: 2026-09-12
  checked: git show 2798cd5 (feat(01.2-11): make search-morph open/closed state server-owned, 2026-08-26)
  found: before this commit, `.CatalogNav` JS toggled `.is-open` client-side on every page (Show included). The commit moved state to the server, gave Index a real :search_expanded assign, and gave Show no-op clauses only to avoid a crash, with the premise "Show never varies search_expanded".
  implication: regression introduced 2026-08-26 — the premise was wrong: without varying the assign, the morph on Show can never open. The no-op fixed the crash but left the control inert.

- timestamp: 2026-09-12
  checked: test/pukllay_club_web/live/catalog_show_test.exs "every event the detail page can dispatch is handled" class guard
  found: asserts only that open-search/close-search are in the handled event set — a no-op clause satisfies it.
  implication: why no gate caught it — existence-of-clause is tested, effect-of-clause is not.

- timestamp: 2026-09-12
  checked: RED run of new describe "header search-morph opens and closes on the detail page (search-broken-on-mobile-detail)" (5 tests)
  found: 4 failures — toggle click, close/reopen cycle, idempotent open, open-survives-unrelated-event all render no .is-open; baseline "renders closed on arrival" passes.
  implication: bug reproduced deterministically through the real phx-click binding. Hypothesis CONFIRMED.

## Resolution

- root_cause: CatalogLive.Show answered the header search-morph's `open-search`/`close-search` events with no-op clauses and passed a hardcoded `search_expanded={false}` to Layouts.app. Since 01.2-11 (2798cd5) the morph's `.is-open` class is rendered ONLY from that assign, so the detail page's search input stayed collapsed (width 0 / opacity 0 / pointer-events none) forever — at every viewport, not just mobile.
- fix: CatalogLive.Show now owns a real `:search_expanded` assign (false in mount/3, true on open-search, false on close-search) and passes `search_expanded={@search_expanded}` to Layouts.app; the stale "no-op is fine" contract in Layouts' nav_search slot doc and Show's comment corrected. No CSS/JS change needed — the ≤480px overlay rule was already designed around Detalle's crumb row.
- oracle_type: specified (layout contract: `.is-open` iff search_expanded; toggle opens, close closes)
- verification:
  - signal_1_repro_red_then_green: PASS — new describe (5 tests) 4 RED before fix, 5/5 GREEN after
  - signal_2_revert_bug_returns: PASS — equivalent to RED run on unfixed code (mutant A below also restores the original hardcoded render and fails 4/5)
  - signal_3_mutation_at_fix_site: PASS — 4/4 mutants killed: A render `search_expanded={false}` (4 fail), B open-search no-op (4 fail), C close-search no-op (1 fail), D close-search sets true (2 fail)
  - signal_4_regression_suite: PASS — `mix quality` (hex.audit, deps.audit, unlock check, format+Styler, credo --strict, sobelow, 1068 tests) 0 failures; existing "every event the detail page can dispatch" guard unchanged and green
  - signal_5_diff_shape: PASS — additive, minimal (1 assign, 2 handler bodies, 1 attr binding, doc/comment corrections); no deletion-only change
  - boundary_neighbors: closed-on-arrival baseline, open idempotent (open twice), close on already-closed, close->reopen cycle, open survives unrelated event (toggle-description)
  - not_self_verifiable: real Android Chrome tap/paint, soft keyboard, implicit Enter submission of the native GET form
  - guardrail_verdict: accepted
  - human_verification: "confirmed fixed" (2026-09-12)
  - archive_recheck: `mix test test/pukllay_club_web/live/catalog_show_test.exs` → 214 tests, 0 failures
- files_changed: [lib/pukllay_club_web/live/catalog_live/show.ex, lib/pukllay_club_web/components/layouts.ex, test/pukllay_club_web/live/catalog_show_test.exs]

## Prevention

- five_whys (branching, blameless):
  - branch_code: Why did tapping search do nothing? Show never rendered `.is-open`. Why? Its open/close handlers were no-ops and the assign was hardcoded `false`. Why was that written? 2798cd5 (01.2-11) moved open-state from client JS to the server and added no-op clauses to Show purely to stop a missing-clause crash, on the premise that "Show never varies search_expanded". Why did the premise survive? The Layouts slot doc codified it ("even as a no-op"), so the contract itself licensed an inert control.
  - branch_config_environment: Why "mobile only"? It wasn't — the closed-state CSS hides the input at every width; mobile is simply the user's primary device. No breakpoint or hook failure contributed.
  - branch_process: Why not noticed in UAT for ~2 weeks? UAT of 01.2-11 exercised search on `/` (Index, which got a real assign); the detail page's search was not re-walked after the state-ownership move.
- why_not_caught: The test gate existed but asserted the wrong property — the "every event the detail page can dispatch is handled (catalog-show-no-clause class guard)" describe in catalog_show_test.exs checks only that a handle_event clause EXISTS for open-search/close-search; a no-op clause satisfies it. Existence-of-handler was tested, effect-of-handler was not. Same "inert control, green tests" class as KB phx-value-collision.
- recurrence_guard: Regression describe "header search-morph opens and closes on the detail page (search-broken-on-mobile-detail)" at test/pukllay_club_web/live/catalog_show_test.exs:3222 (5 tests, clicks the real `.pk-search-morph-toggle` and asserts `.pk-search-morph.is-open` appears/disappears); mutation-verified (4/4 mutants killed); runs in `mix quality` and CI. Plus documentation-as-guard: the Layouts `nav_search` slot doc now states a no-op clause is worse than a crash and that every page filling the slot must flip `search_expanded`.
- transferable_lesson: When state ownership moves from client to server, every page that renders the component must gain a real state transition — a "no-op to avoid the crash" handler converts a loud failure into a silent one. Guard the effect of an event (rendered state change), not the presence of its clause.
