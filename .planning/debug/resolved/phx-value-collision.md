---
status: resolved
trigger: "User report: 'I click some filter and nothing happens' on the catalog filter modal (Jugadores, Duración, Nivel, Destacados, Mecánicas, Temáticas chips/checkboxes)."
created: 2026-08-24T13:00:00.000Z
updated: 2026-08-24T14:15:00.000Z
---

## Current Focus

hypothesis: CONFIRMED and RESOLVED — LiveView's client-side `extractMeta` clobbers `payload.value` with the element's native `.value` DOM property, so a `phx-value-value` binding can never survive the trip to the server.
test: (complete) fix applied, then verified in real Chrome over the Chrome DevTools Protocol with a `WebSocket.prototype.send` interceptor capturing the actual frames LiveView's client JS emitted.
expecting: (met) all three control types — scalar chip, facet pill, checklist checkbox — take their selected state, narrow the grid, and update the "Ver N juegos" CTA; the checkbox un-toggle round trip fully restores the count.
next_action: none — session closed. Fix committed and archived to `.planning/debug/resolved/phx-value-collision.md`.

## Symptoms

expected: Clicking any filter control (Jugadores chip, Duración chip, Nivel pill, Destacados pill, Mecánicas/Temáticas checkbox) visually selects it and narrows the game grid + updates the "Ver N juegos" CTA count live.
actual: Clicking any of these controls does nothing — no visual selected state, no grid change, no CTA count change.
errors: None visible client-side (no console errors, no failed requests) — the LiveView event DOES fire and reach the server, but with a wrong/empty payload value, so server-side logic silently no-ops.
started: Discovered via live browser testing immediately after quick task 260824-b71 shipped a restructured filter modal (chip clusters, searchable checklists) on top of the pre-existing `facet_pill/1` component.
reproduction: `mix phx.server`, open `/`, click the filter trigger, click any "Jugadores" number chip (e.g. "4") or any Nivel/Destacados pill or a Mecánicas checklist checkbox. Confirm via server logs (`HANDLE EVENT "toggle-scalar"`/`"toggle-facet"` — the `Parameters:` map's `"value"` key is empty string or `"on"`, never the real facet/scalar value).

## Eliminated

(none — root cause found directly via LiveView client source inspection on the first hypothesis, no false starts)

## Evidence

- timestamp: 2026-08-24T12:40:00Z
  checked: "Live browser repro via claude-in-chrome — clicked 'Abrir filtros' then the 'Jugadores: 4' chip, both via computer-tool click and a raw `element.click()` JS dispatch"
  found: >
    Chip's visual state never changes (no `badge-primary`/selected styling), grid count and CTA
    text never update. Server-side console log (via read_console_messages, LiveView debug
    annotations) shows the event genuinely reaches the server: `HANDLE EVENT "toggle-scalar" in
    PukllayClubWeb.CatalogLive.Index  Parameters: %{"scalar" => "players", "value" => ""}` — the
    `value` key is an EMPTY STRING, not `"4"`, even though the DOM element's `phx-value-value`
    attribute is literally `"4"`.
  implication: >
    Not a missing/broken event handler and not a client-side hook interfering — the event fires
    and is received, but the payload's `value` key is wrong. The bug is in how the client
    constructs the payload from the button's attributes, not in the handler.

- timestamp: 2026-08-24T12:45:00Z
  checked: >
    `document.querySelector('[phx-value-scalar="players"]')` for the "4" chip via javascript_tool
    — read its `outerHTML` and native `.value` property directly
  found: >
    `outerHTML`: `<button phx-click="toggle-scalar" phx-value-scalar="players"
    phx-value-value="4" class="badge ...">4</button>`. Native `.value` property (via
    `el.value` in JS): `""` — an empty string. Also checked a pre-existing, unmodified `Nivel`
    facet pill (`phx-value-facet="weight_bands"`): same pattern, native `.value` is also `""`.
    Also checked a Mecánicas checklist `<input type="checkbox">` row: native `.value` is `"on"`
    (the browser default for a checkbox with no explicit `value=` attribute).
  implication: >
    Every one of these elements has a native `.value` DOM property distinct from its
    `phx-value-value` HTML attribute, and the native property is NOT what's in the attribute.
    This is exactly the shape of a client-side attribute-vs-property collision, not a
    server-side bug — confirmed the "Nivel" pill (pre-existing, unchanged by the 260824-b71 quick
    task) has the identical defect, so this is not new/introduced code, it's latent in
    `facet_pill/1` since it was first written.

- timestamp: 2026-08-24T12:50:00Z
  checked: >
    `deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js`, the `extractMeta(el, meta,
    value)` method (the function LiveView's client JS uses to build a click event's payload)
  found: >
    Two-pass logic. Pass 1: iterates `el.attributes`, for every attribute name starting with the
    `phx-value-` binding prefix, sets `meta[name.replace(prefix, "")] = el.getAttribute(name)` —
    this is where `phx-value-value="4"` would normally set `meta.value = "4"`. Pass 2
    (unconditional, runs AFTER pass 1, for ANY element that isn't a `<form>`):
    `if (el.value !== void 0 && !(el instanceof HTMLFormElement)) { meta.value = el.value; if
    (el.tagName === "INPUT" && CHECKABLE_INPUTS.indexOf(el.type) >= 0 && !el.checked) { delete
    meta.value } }` — this OVERWRITES `meta.value` with the element's native `.value` property
    whenever the element has one (true for `<button>`, `<input>`, `<select>`, `<textarea>` —
    false only for elements with no native value property, e.g. `<div>`/`<span>`). Buttons and
    unset checkboxes both have a native `.value` (empty string / "on" respectively), so pass 2
    always clobbers whatever `phx-value-value` set in pass 1.
  implication: >
    Definitive root cause, confirmed against LiveView's own shipped client source (not inferred
    from behavior alone). This is a general LiveView gotcha, not specific to this app: naming a
    `phx-value-*` binding "value" on any element with a native `.value` property is silently
    overwritten by that native value, with no error or warning anywhere in the stack. The fix is
    purely to rename the colliding binding — no server-side logic is wrong.

- timestamp: 2026-08-24T12:55:00Z
  checked: >
    `test/pukllay_club_web/live/catalog_live_test.exs` and
    `test/pukllay_club_web/components/filter_modal_test.exs` for how `toggle-facet`/`toggle-scalar`
    are exercised
  found: >
    Every test drives these events via `render_click(view, "toggle-facet", %{"facet" => "...",
    "value" => "..."})` (or the LiveViewTest equivalent) — i.e. the test constructs the Elixir
    params map directly and sends it straight to `handle_event/3`, bypassing the browser
    entirely. `extractMeta`'s attribute-to-payload extraction (where the actual bug lives) never
    runs in this test path.
  implication: >
    This explains why `mix quality`/`mix test` was fully green (399-405 tests passing) despite the
    feature being completely non-functional in a real browser — this whole class of
    attribute-vs-native-property collision is structurally invisible to `render_click`-based
    LiveView tests. Confirms browser verification (not just ExUnit) must be the actual gate for
    any future `phx-value-*` change.

- timestamp: 2026-08-24T14:10:00Z
  checked: >
    Applied the rename fix across all four affected files, then ran the targeted suites and the
    full `mix quality` gate. Re-grepped the whole repo (lib/ + test/, excluding deps/_build) for
    any remaining `phx-value-value` attribute or `"value"`-keyed param map bound to
    `toggle-facet`/`toggle-scalar`.
  found: >
    Renamed 3 DOM attributes (`facet_pill/1`, `scalar_chip/1`, checklist checkbox row) and both
    `handle_event` clauses. NO additional `"value"`-keyed references existed beyond the ones
    listed: `CatalogLive.Index` has exactly two clauses for these events and NO catch-all
    `handle_event/3` fallback, so there was no partially-renamed path left alive. Only `JS.push`
    in the whole app is `core_components.ex:65`'s `lv:clear-flash` (unrelated). One extra
    occurrence beyond the briefed list was found and fixed: `catalog_live_test.exs:402`, a
    MULTI-LINE `render_click(view, "toggle-scalar", %{"scalar" => "players", "value" => ...})`
    map that single-line greps for `"value" => "4"` would have missed. Targeted suites: 95 tests,
    0 failures. Full `mix quality`: exit code 0, 405 tests, 0 failures (credo's 1 design
    suggestion and sobelow's 4 low-confidence findings are pre-existing, in
    `core_components.ex`/`seed/`, untouched by this fix).
  implication: >
    Fix is applied and ExUnit-green, but ExUnit green is NOT the gate for this bug class (see the
    12:55 entry) — `render_click` never runs the client-side `extractMeta` where the collision
    lives, which is exactly why the suite was green while the feature was 100% broken. Browser
    verification is still required before this session can be marked resolved.

- timestamp: 2026-08-24T14:15:00Z
  checked: >
    BROWSER VERIFICATION of the applied fix. `claude-in-chrome` MCP was not available in this
    environment (only a `tidewave` MCP server is configured), so real Google Chrome 151 was driven
    headless over the Chrome DevTools Protocol from Node 22 (built-in WebSocket, no npm deps). A
    script injected via `Page.addScriptToEvaluateOnNewDocument` wrapped `WebSocket.prototype.send`
    to capture the raw Phoenix channel frames the LiveView client actually emitted — so every
    payload assertion below is made on a real client-generated frame, not a reconstructed map.
    LiveView client version reported: 1.2.9. Exercised all three control types plus the checkbox
    un-toggle round trip. (Env note: the dev server running since 09:26 rendered `0 juegos
    encontrados` and was restarted; after a clean restart the connected render returned the full
    catalog of 434 games. A plain `curl` of `/` also legitimately shows 0 because `handle_params/3`
    only queries when `connected?(socket)` — index.ex ~line 93 — that is the intended two-phase
    mount loading skeleton, NOT a defect.)
  found: >
    DOM after fix: `phx-value-value` occurrences = 0; `phx-value-choice` = 82; `phx-value-facet` =
    73; `phx-value-scalar` = 9. All three controls work end to end:
    (1) Jugadores scalar chip "4" — sent
    `{"type":"click","event":"toggle-scalar","value":{"scalar":"players","choice":"4","value":""}}`;
    selected false → true; count 434 → 364 in both the "N juegos encontrados" label and the "Ver N
    juegos" CTA.
    (2) Nivel facet pill "Descubre el hobby" — sent
    `{"type":"click","event":"toggle-facet","value":{"facet":"weight_bands","choice":"descubre_el_hobby","value":""}}`;
    selected false → true; count 364 → 158.
    (3) Mecánicas checklist checkbox "Ataques directos" (after expanding "Más filtros") — sent
    `{"type":"click","event":"toggle-facet","value":{"facet":"mechanics","choice":"Ataques
    directos","value":"on"}}`; checked false → true; count 158 → 19.
    UN-TOGGLE ROUND TRIP on the mechanics checkbox: check → payload carries
    `{"facet":"mechanics","choice":"Ataques directos","value":"on"}`, count 434 → 43; uncheck →
    payload is `{"facet":"mechanics","choice":"Ataques directos"}` with the `"value"` key ABSENT
    ENTIRELY (extractMeta's `delete meta.value` branch), while `"choice"` survives intact; count
    43 → 434, fully restored.
  implication: >
    THE MOST VALUABLE FACT HERE: these live payloads prove `value` is STILL being clobbered by
    `extractMeta` pass 2 — set to `""` on both buttons, to `"on"` on a checked checkbox, and
    DELETED OUTRIGHT on uncheck. The platform behaviour is unchanged and unchangeable from app
    code; the fix works precisely because the handler no longer reads that key. The rename is
    therefore the correct permanent fix, not a workaround. The uncheck frame is the single
    strongest piece of evidence: under the old `phx-value-value` naming that payload would have
    carried NO `value` key at all, so `handle_event("toggle-facet", %{"facet" => f, "value" => v},
    ...)` could not even have pattern-matched — the un-toggle path was structurally impossible,
    not merely wrong-valued. This also re-confirms the 12:55 finding: `render_click` bypasses
    `extractMeta` entirely, which is exactly how a 100%-broken feature shipped with a green suite.

## Resolution

root_cause: >
  `facet_pill/1`, `scalar_chip/1`, and the mechanics/themes checklist's checkbox rows in
  `lib/pukllay_club_web/components/filter_modal.ex` all bind their payload via
  `phx-value-value="..."`. Phoenix LiveView's client-side `extractMeta` (in
  `phoenix_live_view.esm.js`) builds the click-event payload in two passes: it first copies every
  `phx-value-*` attribute into the payload (so `phx-value-value="4"` would set `value: "4"`), then
  unconditionally overwrites `payload.value` with the clicked element's NATIVE `.value` DOM
  property for any non-form element that has one. A `<button>` with no `value=` HTML attribute has
  a native `.value` of `""`; an unset `<input type="checkbox">` has a native `.value` of `"on"`.
  Both silently clobber whatever `phx-value-value` set, with no error anywhere in the stack. This
  affects `facet_pill/1` (Nivel, Destacados — pre-existing, unchanged by the 260824-b71 quick
  task), meaning facet-toggle filtering has been non-functional since `facet_pill/1` was first
  written, not just in the newly-added scalar chips/checklist. `mix quality`/ExUnit never caught
  it because `render_click`-based tests construct the Elixir params map directly and never
  exercise the browser-side `extractMeta` attribute extraction where the collision occurs.
fix: >
  Renamed every `phx-value-value` binding to `phx-value-choice` in `filter_modal.ex`
  (`facet_pill/1`, `scalar_chip/1`, checklist checkbox row) and updated
  `handle_event("toggle-facet", %{"facet" => f, "choice" => v}, ...)` /
  `handle_event("toggle-scalar", %{"scalar" => s, "choice" => v}, ...)` in
  `catalog_live/index.ex` to read the new `"choice"` param key instead of `"value"`.
verification: >
  VERIFIED IN A REAL BROWSER — PASS on all three control types plus the un-toggle edge case.

  METHOD. ExUnit deliberately was NOT the gate here. `render_click/3` constructs the Elixir params
  map in the test process and hands it straight to `handle_event/3`, so it never executes the
  client-side `extractMeta` where this bug lives — that is precisely how a completely non-functional
  filter modal shipped with a fully green suite (see the 12:55 evidence entry). Verification was
  therefore done by driving real Google Chrome 151 headless over the Chrome DevTools Protocol from
  Node 22 (built-in WebSocket, no npm dependencies), with an interceptor injected via
  `Page.addScriptToEvaluateOnNewDocument` that wraps `WebSocket.prototype.send` and records every
  raw Phoenix channel frame. Every payload assertion below is made against the actual bytes
  LiveView's client JS emitted on the wire — i.e. against the exact code path ExUnit bypasses.
  LiveView client version reported by the page: 1.2.9. (`claude-in-chrome` MCP was unavailable in
  this environment — only `tidewave` is configured — hence the raw-CDP substitute.)

  DOM STATE AFTER FIX. `phx-value-value` occurrences in the live DOM: 0. `phx-value-choice`: 82.
  `phx-value-facet`: 73. `phx-value-scalar`: 9.

  OBSERVED BEHAVIOUR (counts read from both the "N juegos encontrados" label and the "Ver N juegos"
  CTA, which moved together every time):
    - Jugadores scalar chip "4": selected false → true, 434 → 364 games. Frame:
      `{"event":"toggle-scalar","value":{"scalar":"players","choice":"4","value":""}}`
    - Nivel facet pill "Descubre el hobby": selected false → true, 364 → 158. Frame:
      `{"event":"toggle-facet","value":{"facet":"weight_bands","choice":"descubre_el_hobby","value":""}}`
    - Mecánicas checklist checkbox "Ataques directos": checked false → true, 158 → 19. Frame:
      `{"event":"toggle-facet","value":{"facet":"mechanics","choice":"Ataques directos","value":"on"}}`
    - Un-toggle round trip (the flagged risk) on the mechanics checkbox: check → 434 → 43 with
      `value: "on"`; uncheck → 43 → 434 (fully restored) with the `"value"` key ABSENT ENTIRELY
      while `"choice"` survives.

  WHAT THE PAYLOADS PROVE. `value` is still being clobbered by `extractMeta` pass 2 in every single
  frame — `""` for buttons, `"on"` for a checked checkbox, and deleted outright on uncheck. The
  platform behaviour is unchanged; the fix works precisely because the handler no longer reads that
  key. The uncheck frame is the decisive evidence that this is a real fix rather than a cosmetic
  rename: with the old `phx-value-value` naming that payload carried no `value` key at all, so
  `handle_event("toggle-facet", %{"facet" => f, "value" => v}, ...)` could not have pattern-matched
  — the un-toggle path was structurally impossible, not merely wrong-valued.

  SUPPORTING GATES (necessary but not sufficient, per the above): targeted `mix test` 95 tests / 0
  failures; full `mix quality` exit 0, 405 tests / 0 failures. A `refute html =~ "phx-value-value"`
  regression guard now fails the suite if the colliding attribute name is ever reintroduced.

  ENVIRONMENT NOTE (not a defect). The dev server that had been running since 09:26 rendered `0
  juegos encontrados` and needed a restart; after a clean restart the connected render returned the
  full 434-game catalog. Separately confirmed that a plain `curl` of `/` legitimately shows 0
  because `handle_params/3` only queries when `connected?(socket)` (index.ex ~line 93) — that is
  the intended two-phase-mount loading skeleton.
files_changed:
  - lib/pukllay_club_web/components/filter_modal.ex (+26/-; 3 attrs renamed phx-value-value → phx-value-choice in facet_pill/1, scalar_chip/1, checklist checkbox row; moduledoc updated + why-note added)
  - lib/pukllay_club_web/live/catalog_live/index.ex (+10; toggle-facet and toggle-scalar clauses now read "choice"; why-note comment added)
  - test/pukllay_club_web/components/filter_modal_test.exs (+8; assertion → phx-value-choice, plus a `refute html =~ "phx-value-value"` regression guard)
  - test/pukllay_club_web/live/catalog_live_test.exs (+34; 8 element selectors + 9 render_click param maps renamed to choice)
  (diffstat: 4 files, 51 insertions, 27 deletions)
