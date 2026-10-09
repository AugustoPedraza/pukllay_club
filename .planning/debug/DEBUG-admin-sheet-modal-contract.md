---
status: diagnosed
trigger: "Diagnose UAT gap G-01.8.3-4a on /admin/juegos: background scrolls behind an open `aria-modal=true` admin sheet. Scope WIDER than the symptom — report the whole modal contract (scroll lock, focus trap, initial focus, Escape, focus restore, aria/inert). goal: find_root_cause_only. HARD CONSTRAINT: must not disturb the overlay geometry that makes UAT test 5 (tab bar unreachable) pass."
created: 2026-09-27T00:00:00Z
updated: 2026-09-27T00:00:00Z
audit_acknowledged:
  milestone: v1.1
  at: 2026-10-09
  status: diagnosed
---

## Current Focus

bug_class: Bohrbug — fully deterministic. The leak reproduces on every gesture,
  every time, on two independent call sites, in headless Chromium exactly as the
  developer reports on Brave/Android (both Chromium). Nothing timing-dependent.

reasoning_checkpoint:
  hypothesis: |
    `AdminComponents.sheet/1` + `dialog/1` ship a PARTIAL modal contract. The
    `AdminSheet` hook (assets/js/hooks/admin_sheet.js) implements Escape, scrim
    tap, drag-down, a focus trap and initial focus — but contains NO scroll-lock
    code at all, and `.pk-admin-overlay-root` (components.css:600-610) declares
    only `position/inset/margin/z-index/display`. Nothing anywhere writes a body
    class, `overflow`, `position: fixed` on body, `touch-action` or
    `overscroll-behavior` when a sheet opens. So the document remains fully
    scrollable behind an `aria-modal="true"` sheet.
    Independently, focus RESTORE is broken by a guard that is correct for the
    DOM-REMOVAL close path and wrong for the CLASS-TOGGLE close path.
  confirming_evidence:
    - "grep across assets/ and lib/: zero occurrences of any scroll-lock mechanism tied to `.pk-admin-overlay-root`. The app's only two scroll locks (`body.pk-drawer-open`, `body.pk-sheet-open`, app.css:3267 and 1776) belong to PUBLIC components and are never applied by the admin sheet."
    - "Measured with the `+` sheet really open at 390x844: wheel on bare scrim moved document scrollTop 0 -> 300/400; calibrated touch drag on bare scrim moved it 0 -> 185. Sheet stayed open throughout. Positive control (sheet closed) touch 285 / wheel 300, so the gesture mechanism is valid."
    - "While open: bodyOverflow `visible`, htmlOverflow `visible`, bodyPosition `static`, bodyClass empty, rootOverscroll `auto`, docScrollableBy 24265px."
    - "Same leak on a SECOND call site in a different file: /admin/juegos/177/editar, `editor-lifecycle-sheet` open, wheel on its scrim moved the document 0 -> 309 (its entire scrollable extent), overlay still open, bodyOverflow still `visible`."
    - "Focus restore: measured activeElement inside the close-class mutation microtask == the ✕ button (`BUTTON|aria-label=Cerrar`), NOT `document.body` — so admin_sheet.js:165's `document.activeElement === document.body` guard is false when it runs and the restore is skipped. activeElement then settles to BODY, with the `+` still in the document."
    - "Isolated browser-behaviour control, no app code: a focused button inside an element that gains `display:none` via a class reads activeElement == the button inside the MutationObserver microtask, and == BODY only after two rAFs."
  falsification_test: |
    If a scroll lock existed, document.scrollTop would be unchanged by a wheel or
    touch gesture while the sheet is open. It changed on every one of four
    gesture/position combinations, and the sheet-closed control proves the
    gesture mechanism works. If the focus-restore failure were something other
    than the guard, activeElement inside the close microtask would already be
    `body`; it is the ✕ button.
  fix_rationale: n/a (find_root_cause_only)
  blind_spots: |
    - Measured only in headless Chromium 390x844. The developer's device is
      Brave/Android, also Chromium, so the LEAK finding transfers directly.
      iOS Safari NOT tested and cannot be from here: `overflow: hidden` on
      `<body>` alone is known not to stop touch scroll there, so the REMEDY
      needs real-device verification on both platforms — the diagnosis does not.
    - `synthesizeScrollGesture` with `gestureSourceType: "touch"` is INERT in
      this headless build (calibrated: delta 0 on a page scrollable by 1506px,
      while `dispatchTouchEvent` gave 281 and wheel gave 300). Round 1 of this
      investigation produced a false "locked" reading from that plus a sign
      error (CDP `yDistance` is positive-to-scroll-UP, applied at scrollTop 0 —
      a no-op). Every scroll reading recorded below is from `dispatchTouchEvent`
      or `mouseWheel`, each paired with a sheet-closed positive control.
    - Scroll CHAINING out of the sheet's own `.pk-admin-sheet__rows` scroller is
      reported as LATENT, not active: the sweep found no admin sheet today whose
      rows are scrollable (all 8 measured at rowsScrollableBy 0 against a
      717.4px cap). The mechanism was proven in isolation only.
    - The focus-trap escape path (focus reaching the background, after which
      Tab walks 408 unguarded focusables) is reported as a structural
      limitation, NOT as an observed failure — no faithful user path to it was
      found on this device, and manufacturing one with `focus()` is the
      documented fabrication trap this repo already recorded.
  candidate_causes:
    - "code/CSS: `.pk-admin-overlay-root` (assets/css/admin/components.css:600-610) declares no scroll-lock property — no `overflow` on a body class, no `overscroll-behavior`, no `touch-action`. CONFIRMED as one of the two necessary halves."
    - "code/JS: `assets/js/hooks/admin_sheet.js` `onOpen`/`onClose` (lines 143-169) manage focus only — no body-class toggle. CONFIRMED as the other necessary half; the hook is the only place that knows when a sheet opens."
    - "code/JS: `admin_sheet.js:165` — `document.activeElement === document.body` guard blocks focus restore on the class-toggle close path. CONFIRMED, independent second defect."
    - "config: ELIMINATED — nothing configurable. The public site's own working locks (`body.pk-drawer-open`, `body.pk-sheet-open`) are hard-coded CSS rules plus hook code; there is no shared switch the admin sheet failed to set."
    - "environment: ELIMINATED — the leak reproduces in headless Chromium and is reported on Brave/Android; both Chromium. No engine divergence implicated in the DEFECT (only in the remedy, for iOS)."
    - "data: ELIMINATED — independent of catalog content. Reproduced on /admin/juegos (435 games) and on a single-game editor page."
  and_gate: |
    YES for the scroll leak — it is a genuine two-condition AND, and this is
    what makes it invisible to the existing guards:
      (1) NO CSS rule locks the document while an overlay is open, AND
      (2) NO JS writes any state a CSS rule could hook onto at open time.
    Neutralising either alone would close it (a `body.pk-admin-overlay-open`
    rule with a hook toggling the class; or a hook that sets
    `body.style.overflow` directly). Both are absent, which is why there is
    nothing to "simply apply" — as with G-01.8.3-4b's missing keel token, the
    mechanism has to be created, not connected.
    NO for focus restore — single cause, one line (admin_sheet.js:165).
    The two are INDEPENDENT: fixing the leak does not fix focus restore and
    vice versa. They are reported together because they are the same partial
    contract, not because they share a mechanism.

## Symptoms

expected: |
  While an `aria-modal="true"` sheet is open, the page behind it does not scroll —
  the sheet holds the user's full focus; only the sheet's own content scrolls.
actual: |
  Developer, real device (Brave/Android, ~390px CSS, 2026-09-27), verbatim:
  "This need to be fixed since the "bottom sheet" isn't trully 100% focus for the
  user, since this allow me scroll the background."
errors: none — interaction/behaviour defect, no console error.
reproduction: |
  /admin/juegos over a staff session at 390x844; real click on `#juegos-add-action`
  flips `pk-admin-overlay-root` -> `pk-admin-overlay-root pk-admin-overlay--open`;
  then a wheel or touch drag anywhere — scrim or panel — scrolls the document.
started: |
  Latent since `AdminComponents.sheet/1` and the `AdminSheet` hook were authored
  (phase 01.8.2, plan 01.8.2-08). The hook's own header comment enumerates what it
  owns — "Esc, drag-down, the focus trap and focus-return" — and scroll lock is
  absent from that list, so it was never in scope rather than having regressed.

## Eliminated

- hypothesis: "Scroll lock IS present and simply failed under the developer's gesture."
  evidence: |
    Nothing to fail. grep across `assets/` and `lib/` finds zero scroll-lock
    mechanism associated with `.pk-admin-overlay-root`. Measured while open:
    bodyOverflow `visible`, htmlOverflow `visible`, bodyPosition `static`,
    bodyClass empty, htmlClass empty, bodyTouchAction `auto`,
    rootOverscroll `auto`, rootTouchAction `auto`. docScrollableBy 24265px.
  timestamp: 2026-09-27

- hypothesis: "This is a per-call-site slip — `game_live/index.ex:682` forgot something the other call sites do."
  evidence: |
    The call site passes only `id/title/open/on_close` — there is no scroll-lock
    attr to pass; the component exposes none. Reproduced on a second, unrelated
    call site in a different file: `/admin/juegos/177/editar`'s
    `editor-lifecycle-sheet` (`form.ex:1340`), wheel on scrim moved the document
    0 -> 309 with the overlay still open. Defect is in the SHARED component.
  timestamp: 2026-09-27

- hypothesis: "Engine divergence — Brave/Android behaves differently from headless Chrome."
  evidence: |
    Both are Chromium. The leak reproduces in headless Chromium with measured
    deltas (touch 185, wheel 300/400) and the developer reports it on Brave.
    Same defect, same direction. (Divergence IS relevant to the REMEDY on iOS
    Safari — recorded under blind_spots — but not to the diagnosis.)
  timestamp: 2026-09-27

- hypothesis: "The overlay's geometry is at fault again (a re-run of G-01.8.3-2b)."
  evidence: |
    Measured while open: overlay rect {top:0,left:0,w:390,h:844} against
    innerWidth 390 / innerHeight 844; `rootMargin: 0px`; `rootPosition: fixed`;
    coversViewport true. `elementFromPoint(195, innerHeight-12)` resolves to
    `.pk-admin-action--a1` INSIDE the overlay (the sheet's own Agregar button),
    not the tab bar. G-01.8.3-2b's fix holds exactly as UAT test 5 recorded.
    Coverage is correct and the leak is orthogonal to it.
  timestamp: 2026-09-27

- hypothesis: "Focus restore fails because `lastFocused` was never captured, or the `+` was removed from the DOM."
  evidence: |
    `document.getElementById('juegos-add-action')` returns truthy after close, so
    `document.contains(this.lastFocused)` would pass. The failing condition is the
    THIRD one: activeElement inside the close-class mutation microtask is the ✕
    button, not `document.body`. Proven twice — on the real sheet and in an
    isolated no-app-code control.
  timestamp: 2026-09-27

- hypothesis: "Scroll chaining out of the sheet's own scroller is an ACTIVE contributor today."
  evidence: |
    Swept all 8 admin screens, opening every `open*`/`ask*` control with real
    clicks: every sheet that opened measured `rowsScrollableBy: 0` against a
    `max-height` cap of 717.4px (add-game-sheet 215px, shelf-name-sheet 247px,
    shelf-options-sheet 189px, web-member-sheet 141px, niveles-sheet 221px,
    editor-lifecycle-sheet 189px). No sheet's own rows scroll today, so chaining
    contributes nothing to the reported symptom. Recorded as LATENT only.
  timestamp: 2026-09-27

## Evidence

- checked: `assets/js/hooks/admin_sheet.js` in full (229 lines)
  found: |
    The hook implements, on `.pk-admin-overlay-root`:
      Escape (lines 73-78), scrim tap (88-91), drag-down dismissal (99-132),
      focus trap (171-185), initial focus (143-149), focus return (164-169),
      open/close detection via a MutationObserver on `class` (190-196).
    It contains NO scroll-lock code: no `document.body.classList`, no
    `body.style.overflow`, no `overscroll-behavior`, no `touch-action`, no
    saved/restored scrollY. The file's own header comment lists what it owns —
    "Esc, drag-down, the focus trap and focus-return" — and scroll lock is not
    in that list.
  implication: |
    The one component that knows WHEN a sheet opens never signals it to CSS.
    This is half of the AND; the other half is that no CSS rule exists to
    receive such a signal.

- checked: `assets/css/admin/components.css:600-702` (`.pk-admin-overlay-root`,
    `.pk-admin-overlay-scrim`, `.pk-admin-sheet`, `.pk-admin-sheet__rows`)
  found: |
    `.pk-admin-overlay-root { position: fixed; inset: 0; margin: 0; z-index: 75;
    display: none }` and `.pk-admin-overlay-root.pk-admin-overlay--open
    { display: block }`. That is the entire open-state contract. No `overflow`
    on any body/html selector, no `overscroll-behavior`, no `touch-action`.
    `.pk-admin-sheet__rows { flex: 1 1 auto; overflow-y: auto; padding-top: 8px;
    padding-bottom: 8px }` — `overscroll-behavior` left at its `auto` default.
    grep over `assets/css/admin/*.css`: the only `overflow` hits are
    `overflow-wrap` (332), `.pk-admin-sheet`'s `overflow: hidden` (636, a
    radius-clip) and `.pk-admin-sheet__rows`' `overflow-y: auto` (699).
  implication: |
    No CSS rule anywhere in the admin locks the document for an open overlay.
    The other half of the AND.

- checked: the app's OWN working precedents — `app.css:3267` / `1776` and their hooks
  found: |
    TWO scroll locks already exist in this codebase, both on the PUBLIC side:
      `body.pk-drawer-open { overflow: hidden }` (app.css:3267), toggled by the
        `.NavDrawerFocus` colocated hook in `layouts.ex` (1572 on mount, 1601 in
        `updated()`, 1619 defensively in `destroyed()`).
      `body.pk-sheet-open  { overflow: hidden }` (app.css:1776), toggled by
        `game_preview.ex` (348 add, 357 + 371 remove).
    `layouts.ex:1530` states the public drawer's contract explicitly: "Escape-to-
    close, Tab focus-trapping while open, moving focus into the panel on open and
    back to whatever had it before on close, and the `body.pk-drawer-open` scroll
    lock". The public drawer ALSO carries `inert={!@open}` (layouts.ex:1558).
    Measured live on /admin/juegos: `#pk-nav-drawer` has `inert`, `role="dialog"`,
    `aria-modal="true"`, and the `pk-drawer-open` CSS rule resolves.
  implication: |
    The admin sheet did not invent a new problem — it DIVERGED from a working
    contract this repo already ships twice, keeping the focus half and dropping
    the scroll-lock and `inert` halves. `[inert]` measured on the live page lists
    exactly one element: `pk-nav-drawer`. The admin overlay is not in that list.

- checked: LIVE, headless Chromium 390x844 (mobile:true, touch emulation on),
    real staff session, /admin/juegos (document scrollable by 24265px). Sheet
    opened by a REAL CDP mouse click on `#juegos-add-action` — never by flipping
    the class, never by `focus()`. GESTURE CALIBRATION FIRST (see blind_spots):
    `synthesizeScrollGesture` touch = 0 (inert here), `dispatchTouchEvent` drag =
    281, `mouseWheel` = 300, measured on a known-scrollable public page.
  found: |
    POSITIVE CONTROL, sheet CLOSED:
      touchDrag 500->200       scrollTop 0 -> 285   (delta 285)
      wheel deltaY=300         scrollTop 0 -> 300   (delta 300)
      => gesture mechanism valid on this page.
    SHEET OPEN (panel top edge y=629; y<629 is bare scrim):
      touchDrag 569->369 on SCRIM        0 -> 185  (delta 185)  sheetOpen=true
      wheel  deltaY=300  on SCRIM        0 -> 300  (delta 300)  sheetOpen=true
      wheel  deltaY=300  on PANEL BODY   0 -> 300  (delta 300)  sheetOpen=true
      touchDrag          on PANEL BODY   0 ->  85  (delta  85)  sheetOpen=true
    STATE while open:
      bodyClass "(empty)"   htmlClass "(empty)"
      bodyOverflow visible  htmlOverflow visible  bodyPosition static
      bodyTouchAction auto  rootOverscroll auto   rootTouchAction auto
      rowsOverflowY auto    rowsOverscroll auto   rowsScrollableBy 0
      docScrollableBy 24265 px
  implication: |
    Scroll lock is ABSENT, not merely weak. Every gesture in every position moves
    the document while an `aria-modal="true"` sheet is open, and the sheet stays
    open throughout — exactly the developer's report. Note the PANEL-BODY readings
    leak too: because `rowsScrollableBy` is 0 the gesture finds no scroller inside
    the sheet and goes straight to the document, so even a finger placed ON the
    sheet scrolls the page behind it.

- checked: LIVE — does the leak survive the close?
  found: |
    With the sheet open, wheel deltaY=600 on the scrim: scrollTop 0 -> 600.
    Real click on the ✕: sheet closes, scrollTop still 600.
  implication: |
    The user does not merely see the background move — they are returned to a
    DIFFERENT part of a 435-row list than the one they opened the sheet from,
    with no way to tell what happened. This is the "not truly 100% focus"
    complaint's full consequence, beyond the visual distraction.

- checked: LIVE — BLAST RADIUS on a second call site, different file
  found: |
    `/admin/juegos/177/editar` (document scrollable by 309px) mounts EIGHT
    overlay roots at rest: `editor-lifecycle-sheet`, `editor-weight-band-sheet`,
    `editor-is-expansion-sheet`, `editor-name-sheet`, `editor-description-sheet`,
    `editor-bgg-link-sheet` (sheets) plus `editor-discard-dialog`,
    `editor-retire-dialog` (dialogs).
    Real click on the `open-menu` control opened `editor-lifecycle-sheet`; wheel
    on its scrim moved the document 0 -> 309 — its ENTIRE scrollable extent —
    with the overlay still open, bodyClass "" and bodyOverflow `visible`.
  implication: |
    Not a Juegos-only slip. The same shared component leaks identically from a
    call site in `game_live/form.ex`, and `dialog/1` shares the same overlay root
    and the same hook, so the dialog variant is exposed on the same terms.

- checked: LIVE — full-sweep inventory of real sheets, opened by real clicks
  found: |
    /admin                      no sheet reachable from an open*/ask* control
    /admin/juegos               add-game-sheet         h=215  rowsScrollableBy 0
    /admin/staff                none reachable at rest
    /admin/estantes             none reachable at rest
    /admin/estantes/administrar shelf-name-sheet       h=247  rowsScrollableBy 0
                                shelf-options-sheet    h=189  rowsScrollableBy 0
    /admin/secciones            web-member-sheet       h=141  rowsScrollableBy 0
    /admin/niveles              niveles-sheet          h=221  rowsScrollableBy 0
    /admin/juegos/177/editar    editor-lifecycle-sheet h=189  rowsScrollableBy 0
    All against `.pk-admin-sheet`'s `max-height: 85vh` = 717.4px.
    Page scrollability: /admin/juegos 24265px, editor 309px,
    /admin/estantes 0, /admin/estantes/administrar 0.
  implication: |
    Every admin sheet is well under the 85vh cap today, so NO sheet's own rows
    scroll — which is why the panel-body gesture leaks straight through, and why
    `overscroll-behavior: auto` on `.pk-admin-sheet__rows` is a LATENT rather
    than an active contributor. The user-visible severity tracks page
    scrollability: worst by far on /admin/juegos (24265px), real on the editor
    (309px), invisible today on the two Estantes screens (0px) — but those two
    will leak the moment their content grows past a viewport.

- checked: LIVE — aria / role / labelling / inert, sheet OPEN
  found: |
    On `[data-pk-sheet-panel]`: role `dialog`, aria-modal `true`,
    aria-labelledby `add-game-sheet-title`, which resolves to an element whose
    text is "Agregar juego". tabindex `-1`. All present and correct.
    (`dialog/1` uses role `alertdialog` + aria-labelledby on its question — same
    shape, admin_components.ex:906-910.)
    BACKGROUND: `[inert]` on the whole page lists exactly one element,
    `pk-nav-drawer` (the closed PUBLIC drawer). `#juegos-page` inert=false
    aria-hidden=null; `<main>` inert=false aria-hidden=null;
    `.pk-admin-tab-bar` inert=false aria-hidden=null.
    Background focusable count while open: 408.
  implication: |
    The ARIA contract is correct and complete — `aria-modal="true"` does tell an
    AT to treat the background as unavailable, which is why this is not an
    outright screen-reader failure. But nothing ENFORCES it in the DOM: 408
    background controls remain focusable and hit-testable-in-principle, and the
    public drawer's own `inert={!@open}` pattern (layouts.ex:1558) is not applied
    here. Pointer taps are nonetheless blocked, by coverage alone (test 5).

- checked: LIVE — initial focus, focus trap (real Tab/Shift-Tab keys, no `focus()`)
  found: |
    Initial focus after a real click on `+`: the ✕ button
    (`.pk-admin-action--a3`, aria-label "Cerrar") — inSheet=true.
    Panel focusables: exactly two — the ✕ and `#add-game-sheet-input`.
    8 consecutive real Tab presses: ✕ -> input -> ✕ -> input -> ... inSheet=true
      on every single one; focus never reached the background.
    6 consecutive real Shift-Tab presses: same two-element cycle, inSheet=true
      throughout.
  implication: |
    Initial focus WORKS and the focus trap WORKS as measured. Reported as
    working — not manufactured into a failure. Structural limitation worth
    naming (NOT an observed defect): admin_sheet.js:177-182 only calls
    `preventDefault()` when activeElement is exactly the first or last focusable
    INSIDE the panel, so if focus ever reaches the background the trap never
    pulls it back and Tab walks the 408 unguarded controls. No faithful user
    path to that state was found on this device; `inert` on the background is
    what would close it structurally.

- checked: LIVE — Escape to close
  found: |
    Real Escape keydown with the sheet open: `pk-admin-overlay--open` removed
    within the poll window; sheet closed. Path is
    `onKeydown` -> `requestClose()` -> `closeControl.click()` (admin_sheet.js
    62-78), i.e. the same `phx-click` a pointer tap would fire.
  implication: Escape WORKS.

- checked: LIVE — focus restore, and WHY it fails (two independent proofs)
  found: |
    OBSERVED: after Escape-close, activeElement = BODY. After a real ✕-click
    close, activeElement = BODY. Expected `#juegos-add-action`. Body class after
    close: "" (so nothing was left behind either).
    MECHANISM, proof 1 — on the real sheet. A spy MutationObserver registered on
    `#add-game-sheet`'s class runs in the SAME microtask as the hook's own
    observer and immediately after it (registration order), so what it reads is
    what the hook's guard read:
      at the close-class mutation: openClassStillPresent=false
      activeElement INSIDE that microtask: BUTTON|aria-label=Cerrar   <-- the ✕
      activeElement settled afterwards:    BODY
      `#juegos-add-action` still in the document: true
    MECHANISM, proof 2 — ISOLATED, no app code. A focused button inside a div
    that gains `display:none` via a class:
      activeBeforeHide                          probe-btn
      activeInsideMutationObserverMicrotask     probe-btn   <-- still focused
      activeAfterTwoRafs                        BODY
  implication: |
    `admin_sheet.js:165`'s third guard condition —
    `document.activeElement === document.body` — is FALSE when `onClose` runs on
    a class-toggle close, so `this.lastFocused.focus()` is never reached. The
    first two conditions would both have passed (`lastFocused` is the `+`, and it
    is still in the document). By the time activeElement really is `body` (next
    style recalc), nothing is listening.
    The guard's own comment (admin_sheet.js:150-163) justifies itself with "the
    browser's own removal-of-focused-element behaviour resets
    `document.activeElement` to `body` synchronously". That is true for DOM
    REMOVAL — `staff_live/index.ex`'s `:if={@selected_staff}` pattern, the case
    plan 01.8.2-12 Task 3 was fixing — and false for a STAY-MOUNTED sheet that
    closes by gaining `display: none`, which only unfocuses its descendant at
    the next style recalc. Proof 2 establishes that asymmetry with no app code
    involved. So the guard added to protect the sheet->dialog handoff silently
    disabled focus-return for every stay-mounted `open={...}` call site.

- checked: LATENT secondary mechanism — scroll chaining out of the sheet's own scroller
  found: |
    ISOLATED control inside a `position: fixed; inset: 0` overlay, using a
    scroller with the SAME computed properties as `.pk-admin-sheet__rows`
    (verified side by side: probe overflowY `auto` / overscroll `auto` vs real
    rows overflowY `auto` / overscroll `auto`):
      overscroll-behavior: auto (today's value)  inner pinned at end (900/900),
        document 0 -> 400  => CHAINS OUT
      overscroll-behavior: contain (remedy)      inner pinned at end (900/900),
        document 0 -> 0    => contained
  implication: |
    Once a scroll lock lands, this is the remaining leak path for a finger placed
    inside a sheet whose rows DO scroll. Not active today (no such sheet exists —
    see the sweep) but it arms itself the first time a sheet's content passes
    85vh, and the fix is one declaration in the same rule.

- checked: HARD CONSTRAINT — does a candidate lock disturb test 5's geometry?
    Applied live, with the sheet really open, then re-measured:
    `body.pk-admin-overlay-open { overflow: hidden }` +
    `overscroll-behavior: contain` on `.pk-admin-overlay-root` and
    `.pk-admin-sheet__rows`.
  found: |
                          BEFORE (shipped)            AFTER (candidate)
      overlay rect        {0,0,390,844}               {0,0,390,844}   IDENTICAL
      coversViewport      true                        true
      tabBarRect          {top:777,h:67}              {top:777,h:67}  IDENTICAL
      elementFromPoint(195, innerH-12)
                          .pk-admin-action--a1        .pk-admin-action--a1
      hitIsInsideOverlay  true                        true
      wheel leak on scrim 400                         0
      touch leak on scrim (400 equiv.)                0
    => geometry disturbed: FALSE
  implication: |
    A body-class + `overscroll-behavior` lock closes the leak for both wheel and
    touch while leaving the overlay rect, the tab-bar coverage and the
    `elementFromPoint` hit target bit-identical. G-01.8.3-2b's `margin: 0` fix
    and UAT test 5's passing result are untouched: the candidate adds properties
    to `<body>` and to overscroll behaviour, and changes nothing about the
    overlay's own box model, position, inset or margin.

- checked: why every existing guard passes
  found: |
    `test/visual/admin_shell.mjs` — plan 01.8.3-07's overlay check (header comment
    at line ~276) asserts an open overlay's RECT covers the viewport and that
    `elementFromPoint` inside the sheet's bounds never resolves outside the
    overlay ("overlay real-open walk attempted=6 covered=6, overlay measuring
    844x844", per UAT test 4's `why_human`). Both are COVERAGE assertions. Neither
    scrolls anything, so neither can observe scroll state.
    grep over `test/`: no occurrence of `scrollTop` in any admin overlay
    assertion, no `dispatchTouchEvent`, no `synthesizeScrollGesture`, no
    `overscroll`, no `body.classList` / `overflow` assertion tied to an open sheet.
    G-01.8.3-2b's own `missing:` list asked for exactly two guards — "an open
    overlay's rect covers the full viewport" and "`elementFromPoint` inside the
    sheet's own bounds never resolves outside the overlay" — and both were
    delivered. Neither mentions scrolling; the gap was scoped to coverage.
    Focus restore: no test asserts `document.activeElement` after a sheet close.
  implication: |
    The guards are not wrong, they are aimed one axis away. Coverage (can a tap
    reach through?) and lock (can a gesture move what is behind?) are independent
    properties of the same overlay, and only the first was ever specified. This
    is the same shape as G-01.8.3-2c/4b: an assertion that passes truthfully
    while the developer's eye reads a different quantity entirely.

## Resolution

root_cause: |
  `AdminComponents.sheet/1` and `dialog/1` ship a PARTIAL modal contract. Six
  obligations, four met, two broken — and the two broken ones are independent of
  each other and of the coverage fix that UAT test 5 confirms.

  DEFECT 1 — scroll lock is ABSENT (the reported symptom). An AND of two
  simultaneously necessary conditions, which is why there is nothing to
  "simply apply":
    (1) `assets/css/admin/components.css:600-610` — `.pk-admin-overlay-root`'s
        entire open-state contract is `position: fixed; inset: 0; margin: 0;
        z-index: 75; display: none` -> `display: block`. No rule anywhere in
        `assets/css/admin/` locks the document for an open overlay: no
        `overflow` on a body/html selector, no `overscroll-behavior`, no
        `touch-action`; AND
    (2) `assets/js/hooks/admin_sheet.js` — the hook is the ONLY code that knows
        when a sheet opens (`onOpen`/`onClose`, lines 143-169, driven by a
        MutationObserver on the root's `class`), and it writes nothing a CSS rule
        could hook onto. Its own header comment scopes it to "Esc, drag-down, the
        focus trap and focus-return"; scroll lock was never in scope.
  Measured at 390x844 with the `+` sheet really open (real CDP click, never a
  class flip, never `focus()`), against a document scrollable by 24265px:
  touch drag on bare scrim moved it 185px, wheel on bare scrim 300-400px, and
  gestures on the PANEL itself leaked too (wheel 300, touch 85) because
  `rowsScrollableBy` is 0 so no scroller inside the sheet claims them. The sheet
  stayed open throughout. Sheet-closed positive control: touch 285 / wheel 300.
  While open: bodyOverflow `visible`, htmlOverflow `visible`, bodyPosition
  `static`, bodyClass empty, rootOverscroll `auto`. The scroll also PERSISTS
  past the close (scrollTop 600 before, 600 after), so the user is returned to a
  different part of a 435-row list than the one they opened the sheet from.

  This is a DIVERGENCE, not an oversight without precedent: the same repo ships
  two working scroll locks on the public side — `body.pk-drawer-open`
  (`app.css:3267`, toggled by `.NavDrawerFocus` in `layouts.ex:1572/1601/1619`)
  and `body.pk-sheet-open` (`app.css:1776`, toggled by `game_preview.ex:348/357/
  371`) — and `layouts.ex:1530` names the full contract the public drawer meets,
  scroll lock included. The admin sheet kept the focus half of that contract and
  dropped the scroll-lock and `inert` halves.

  DEFECT 2 — focus restore never runs (independent, single cause, not reported
  by the developer). `assets/js/hooks/admin_sheet.js:165` guards the restore on
  `document.activeElement === document.body`. Measured inside the close-class
  mutation microtask on the real sheet, activeElement is the ✕ button, NOT
  `body`, so the guard is false and `this.lastFocused.focus()` is never reached;
  activeElement then settles to `body` at the next style recalc with nothing
  listening. The other two conditions would both have passed. Proven
  independently with no app code: a focused button inside an element that gains
  `display: none` via a class reads as still-focused inside the MutationObserver
  microtask and as `BODY` only after two rAFs. The guard's own comment
  (lines 150-163) justifies itself with "the browser's own removal-of-focused-
  element behaviour resets `document.activeElement` to `body` synchronously" —
  true for the DOM-REMOVAL close path it was written for (`staff_live`'s
  `:if={@selected_staff}`, plan 01.8.2-12 Task 3) and false for a stay-mounted
  `open={...}` sheet that closes via `display: none`. So a fix for the
  sheet->dialog focus handoff silently disabled focus-return for every
  class-toggle call site. Measured: focus after Escape-close = BODY; after
  ✕-click close = BODY; `#juegos-add-action` still in the document.

  WHAT IS NOT BROKEN (measured, not assumed): initial focus (lands on the ✕),
  the focus trap (8 real Tabs + 6 real Shift-Tabs, every one inSheet=true, never
  escaped), Escape-to-close, and the full ARIA set (`role="dialog"`,
  `aria-modal="true"`, `aria-labelledby` resolving to "Agregar juego",
  `tabindex="-1"`). `inert`/`aria-hidden` on the background is ABSENT (408
  background focusables, the only `[inert]` on the page being the closed public
  drawer) — but `aria-modal="true"` is doing the assistive-tech half of that job,
  and pointer taps are blocked by coverage, so this is an enforcement gap rather
  than an outright failure.

  LATENT, not active today: `.pk-admin-sheet__rows` (components.css:697-702)
  leaves `overscroll-behavior` at `auto`, so a finger inside a sheet whose rows
  scroll would chain out to the document at the boundary. Proven in isolation
  (auto -> document moved 400px; `contain` -> 0). Contributes nothing to the
  reported symptom because no admin sheet's rows scroll today — all 8 measured
  at `rowsScrollableBy: 0` against a 717.4px `max-height` cap — but it arms
  itself the first time a sheet's content passes 85vh.

  BLAST RADIUS: the shared component, not any call site. 15 `AdminComponents.
  sheet` + 5 `AdminComponents.dialog` call sites across 8 files, all mounting
  `.pk-admin-overlay-root` with `phx-hook="AdminSheet"`. Reproduced on two
  independent ones (`game_live/index.ex:682` and `game_live/form.ex:1340`).

fix: n/a — goal was find_root_cause_only
verification: n/a
files_changed: []
