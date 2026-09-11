---
status: diagnosed
trigger: "I don't see the banner but it reconnects wihout problem"
created: 2026-09-11T19:30:00Z
updated: 2026-09-11T19:45:00Z
---

## Current Focus

hypothesis: CONFIRMED — Chrome DevTools "Offline" network emulation does not close or block
  established WebSocket connections, so the LiveView socket never entered a disconnected state
  and `phx-disconnected` never fired. The banner is correctly wired; the UAT *procedure* cannot
  exercise it on Chrome.
test: complete (see Evidence)
expecting: n/a
next_action: hand diagnosis to /gsd-plan-phase --gaps; no fix applied (goal: find_root_cause_only)

reasoning_checkpoint:
  hypothesis: "The banner never appeared because the LiveView socket never disconnected — Chrome
    DevTools Offline throttling does not apply to WebSockets, so the WS stayed open, no
    displayError() ran, and phx-disconnected was never executed."
  confirming_evidence:
    - "Documented Chrome limitation: offline emulation does not affect WebSocket traffic
      (throttling added in Chrome 99; offline still does not close/block existing WS)."
    - "Every other link in the chain verified present and correct on the LIVE site: markup,
      bindings, CSS, utilities, DOM ancestry, CSP."
    - "Phase 01.7 touched exactly one source file (endpoint.ex, session-cookie `secure:`) —
      layouts.ex / app.css / app.js / csp.ex were NOT modified, so no regression is possible."
  falsification_test: "If DevTools Offline DID close the WS, the topbar progress bar
    (bound to phx:page-loading-start, fired by displayError) would also have appeared. User
    reported seeing nothing."
  fix_rationale: "n/a — no app defect established. Remediation is a verification-procedure change,
    plus two latent cosmetic/visibility issues flagged below."
  blind_spots:
    - "Not reproduced in a live browser by me (no browser automation available in this session)."
    - "Which browser the user used was not stated; the report says 'DevTools', which is Chrome/Edge
      terminology (Firefox calls it 'Throttling' and has no Offline entry in the same place)."
    - "Whether the user was scrolled to the top when they went offline (see contributing factor B)."
  candidate_causes:
    - "code: banner markup/bindings missing or mis-wired — RULED OUT (verified in live HTML)"
    - "config: CSP blocking the show/hide JS or inline style — RULED OUT (style-src has
      'unsafe-inline'; CSSOM writes are not CSP-governed; csp.ex unchanged in 01.7)"
    - "environment: Chrome DevTools Offline does not close WebSockets — CONFIRMED"
    - "data: n/a"
  and_gate: "yes — the primary cause (environment) fully explains the observation on its own, but
    two independent latent conditions (B: in-flow banner invisible when scrolled; C: JS.show forces
    display:block over display:flex) would degrade the banner even under a real disconnect. They are
    not required for this symptom but are real and should ride along in the fix plan."

## Symptoms

expected: "Opening DevTools -> Network -> Offline on the live site shows a LiveView disconnect
  banner, and switching back Online reconnects with no invalid-token error and no reconnect loop."
actual: "I don't see the banner but it reconnects wihout problem" (Maps embed confirmed fine)
errors: none — no invalid-token error, no reconnect loop
reproduction: Test 3 in
  .planning/phases/01.7-production-catalog-data-security-hardening-inserted/01.7-UAT.md
  (gap G-01.7-3) — DevTools -> Network -> Offline on https://pukllay.club, wait for banner,
  switch back Online
started: discovered during UAT for phase 01.7 on 2026-09-11 against the live deployed site

## Eliminated

- hypothesis: "The banner was removed / never wired up (phx.new stock toast deleted, nothing
    replaced it)"
  evidence: "Live HTML from https://pukllay.club contains exactly one
    `<div id=\"connection-status\" class=\"pk-conn-banner\" role=\"status\" aria-live=\"polite\"
    phx-disconnected=... phx-connected=... hidden>` with the Spanish copy
    'Reconectando… no encontramos tu conexión a internet'."
  timestamp: 2026-09-11T19:36:00Z

- hypothesis: "The banner element is outside the LiveView root, so LiveView's binding scan
    (execAll uses this.el.querySelectorAll) never finds it"
  evidence: "Parsed the live document tree: ancestry is html > body > div#phx-GNRbTNz5sdm8-AiR
    (data-phx-main) > div#connection-status — a DIRECT CHILD of the main view root."
  timestamp: 2026-09-11T19:38:00Z

- hypothesis: "Phase 01.7's CSP tightening blocks the show/hide JS or the banner's inline style"
  evidence: "Live CSP header is `style-src 'self' 'unsafe-inline'` — inline styles are explicitly
    allowed. Separately, LiveView's JS.show sets `el.style.display` via CSSOM, which CSP does not
    govern at all. And csp.ex was never modified by phase 01.7 (01.7-03 was a docs-only audit
    commit, 444467e/444457e `docs(01.7-03): audit CSP directive-by-directive`)."
  timestamp: 2026-09-11T19:40:00Z

- hypothesis: "This is a regression introduced by phase 01.7"
  evidence: "`git log --all --no-merges --grep='01\\.7' --name-only` over lib/ and assets/ yields
    exactly ONE source file across the whole phase: lib/pukllay_club_web/endpoint.ex (commits
    47986e4 / 21ca839, `secure: Mix.env() == :prod` on @session_options). layouts.ex, app.css,
    app.js and csp.ex are untouched. A session-cookie Secure attribute over HTTPS cannot affect
    a client-side disconnect banner."
  timestamp: 2026-09-11T19:41:00Z

- hypothesis: "The page under test is a dead (controller-rendered) view with no LiveSocket, so
    there is no socket to disconnect"
  evidence: "router.ex routes are ALL LiveViews (`live \"/\"` CatalogLive.Index, `live
    \"/juegos/:id\"`, `live \"/club\"` + `live \"/quienes-somos\"` AboutLive) and all three
    LiveViews render `<Layouts.app>`. The live `/` response carries data-phx-main."
  timestamp: 2026-09-11T19:37:00Z

- hypothesis: "The transition utility classes the banner's show/1 uses were never generated by
    Tailwind (source(none) + explicit @source list), so the element stays at opacity-0"
  evidence: "Fetched the live compiled stylesheet
    /assets/css/app-a826460fc9482a2a7eaad778a0daf3b9.css and confirmed `.opacity-0`,
    `.opacity-100`, `.translate-y-4`, `.translate-y-0`, `.transition`, `.sm\\:scale-95`,
    `.sm\\:scale-100`, `.sm\\:translate-y-0` and both arbitrary duration/ease utilities are
    all present."
  timestamp: 2026-09-11T19:39:00Z

- hypothesis: "The `hidden` attribute can never be beaten, so the banner is structurally
    unshowable"
  evidence: "Tailwind v4 preflight emits `[hidden]:where(:not([hidden=until-found])){display:none
    !important}` (confirmed in the live CSS), which DOES defeat both `.pk-conn-banner{display:flex}`
    and LiveView's inline `style.display` — BUT the binding chain is
    `[[\"show\",...],[\"remove_attr\",{\"attr\":\"hidden\"}]]`, and removing the attribute stops
    the selector matching. The escape hatch is present and correct."
  timestamp: 2026-09-11T19:40:00Z

## Evidence

- timestamp: 2026-09-11T19:35:00Z
  checked: "Live site HTML + response headers via curl https://pukllay.club/"
  found: "Banner markup present and complete; CSP = `default-src 'self'; ...
    style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self' ws: wss:; ...`;
    Set-Cookie carries `secure` (01.7-02 shipped)."
  implication: "Server-side rendering of the feature is correct and 01.7's security headers do not
    interfere."

- timestamp: 2026-09-11T19:42:00Z
  checked: "deps/phoenix_live_view/assets/js/phoenix_live_view/view.ts (v1.2.9) — the disconnect
    path"
  found: "`displayError()` (line 1388) dispatches `phx:page-loading-start` with kind 'error',
    calls `showLoader()`, sets the PHX_CLIENT_ERROR/PHX_LOADING container classes, then
    `delayedDisconnected()` (1399) schedules `execAll(this.binding('disconnected'))` after
    `liveSocket.disconnectedTimeout`. constants.ts: DISCONNECTED_TIMEOUT = 500ms."
  implication: "phx-disconnected fires 500ms after a real socket error — fast, and squarely inside
    the window the user waited. So the binding was never reached at all; the delay is not the
    explanation."

- timestamp: 2026-09-11T19:43:00Z
  checked: "deps/phoenix/assets/js/phoenix/socket.js heartbeat mechanics"
  found: "heartbeatIntervalMs defaults to 30000; `sendHeartbeat()` only declares a
    `heartbeatTimeout()` after another full interval. Detection of a silently-dead WS therefore
    takes 30–60s."
  implication: "Even if Chrome's offline mode had degraded (rather than ignored) the WS, a user
    'waiting for the banner' for a few seconds would still see nothing. Belt-and-braces support
    for the primary cause."

- timestamp: 2026-09-11T19:44:00Z
  checked: "Web research: Chrome DevTools Network Offline vs WebSockets"
  found: "Documented Chrome architectural limitation — most requests go through the Fetch path,
    which offline/throttling hooks into; WebSockets (and WebRTC) do not. WebSocket *throttling*
    landed in Chrome 99, but Offline mode does not close existing WebSocket connections nor block
    their traffic. Reproduced complaint: with the emulator set to Offline, a message pushed over
    an open WebSocket is still sent and echoed back."
  implication: "ROOT CAUSE. The LiveView socket stayed open for the entire 'offline' window, so
    the client never entered an error state, `displayError()` never ran, `phx-disconnected` never
    executed, and the banner never showed. 'It reconnects without problem' is vacuously true —
    nothing ever disconnected."

- timestamp: 2026-09-11T19:45:00Z
  checked: "test/pukllay_club_web/components/layouts_test.exs — the banner's test coverage"
  found: "Five tests, all markup-level: exactly-one-bar, `hidden` + role + both binding attributes
    present, Spanish copy, and a document-order offset assertion. No test — and no prior UAT item —
    ever exercised the banner's runtime visibility."
  implication: "The banner's real behaviour has NEVER been verified since it shipped in plan
    01.2-15 (G-01.2-8). This UAT was its first attempt, and the attempt used a method that cannot
    work. Its runtime correctness remains genuinely unknown, not proven-good."

- timestamp: 2026-09-11T19:45:30Z
  checked: "assets/css/app.css:1571 + live compiled CSS — .pk-conn-banner positioning"
  found: "No `position` declaration → static, in normal document flow, directly under the sticky
    header (#app-header carries .pk-header-sticky; CatalogLive.Index passes `sticky`)."
  implication: "LATENT CONTRIBUTING FACTOR B — on a real disconnect while the user is scrolled
    down a long catalog page, the bar is inserted above the current scroll position and is
    entirely off-screen. The layouts.ex comment ('showing this bar only pushes content down') shows
    this was a deliberate trade-off against header-height measurement, but it also means the bar
    is only visible at/near scroll top."

- timestamp: 2026-09-11T19:46:00Z
  checked: "deps/phoenix_live_view/assets/js/phoenix_live_view/js.js toggle()/defaultDisplay()"
  found: "On show, `stickyDisplay = display || this.defaultDisplay(el)` and defaultDisplay returns
    'block' for a div (line 642-646); it is written as an INLINE style via DOM.putSticky, which
    beats the unlayered `.pk-conn-banner{display:flex}`."
  implication: "LATENT CONTRIBUTING FACTOR C — when the bar does show, it renders as display:block,
    so `justify-content`, `align-items` and `gap: 10px` are all inert; the spinner and label fall
    back to inline layout. Cosmetic only (text-align:center still centres the text), but it means
    the shipped bar never looks the way sketch 030 Round 3 specified. Fixable by passing
    `display: \"flex\"` to JS.show."

## Resolution

root_cause: |
  PRIMARY (environment): Chrome DevTools' "Offline" network condition does not apply to WebSocket
  connections — a documented Chrome architectural limitation (offline/throttling hooks the Fetch
  path; WebSockets bypass it). The LiveView socket therefore never closed, phoenix_live_view's
  `View.displayError()` never ran, and the `phx-disconnected` JS binding on #connection-status was
  never executed. The banner is correctly authored, correctly placed inside the LiveView root,
  correctly served on the live site, and is not blocked by phase 01.7's CSP. The UAT test method,
  not the application, is what failed.

  CONTRIBUTING (latent, would degrade the banner under a REAL disconnect, but did not cause this
  observation):
  B. `.pk-conn-banner` is `position: static` in normal flow beneath a sticky header, so on a real
     disconnect it is invisible whenever the user is scrolled away from the top of the page.
  C. LiveView's `JS.show` writes an inline `display: block` (defaultDisplay for a div), which beats
     `.pk-conn-banner{display:flex}`, so the bar's flex centering and 10px spinner gap never apply.
fix: not applied — goal was find_root_cause_only
verification: n/a
files_changed: []

suggested_verification_method: |
  DevTools Offline cannot verify this. Use one of:
  - DevTools console: `liveSocket.disconnect()` … observe banner … `liveSocket.connect()`
    (window.liveSocket is already exposed at assets/js/app.js:77).
  - Stop/restart the app container on the host (real server-side close, exercises the true path).
  - Disable the OS network interface / Wi-Fi (not the DevTools emulator).
  Whichever is chosen, do it at scroll-top first (factor B), then repeat scrolled down to decide
  whether B needs fixing.
