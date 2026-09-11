---
phase: quick-260824-q8z
plan: 01
subsystem: ui
tags: [phoenix-liveview, daisyui, accessibility, mobile-drawer, theme-toggle]

requires:
  - phase: quick-260824-7mt
    provides: desktop footer theme-control ink-mass subordination (superseded by footer-theme-toggle-balance)
  - phase: debug/footer-theme-toggle-balance
    provides: "the sr-only role=group + aria-labelledby pattern this plan mirrors on the drawer"
provides:
  - "Mobile nav drawer's .pk-drawer-bottom reads as social-content-leads / theme-footer-trails: full-width 44px social row (Task 1), then a small centered sr-only-labelled theme strip (Task 2)"
  - "role=group + aria-labelledby accessible-name pattern now applied identically on both the desktop footer and the mobile drawer's theme control"
affects: [mobile-nav-drawer, desktop-footer, layouts.ex, app.css]

actuals:
  tokens: 2341
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "role=\"group\" + aria-labelledby on a wrapper, id + sr-only on the label span it names — now the repo's standard pattern for a labelled icon-only control group (footer AND drawer)"

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/components/layouts.ex
    - assets/css/app.css
    - test/pukllay_club_web/components/layouts_test.exs

key-decisions:
  - "Applied sketch 021's own Round-6 conclusion (E1 — Icon-Only, Centered) to the drawer's theme control, converging with the desktop footer's independently-reached debug-session conclusion (footer-theme-toggle-balance) — both surfaces now carry \"Tema\" as an sr-only accessible group name only, no visible text."
  - "Drawer's theme buttons stay 44px (min-h-11/min-w-11) — NOT shrunk to the footer's 28px, since the drawer is the sole mobile home for the theme control below 480px (.pk-footer-right is display:none there)."
  - "Used a document-unique id (pk-drawer-theme-label) distinct from the footer's pk-footer-theme-label, since both render in the same document."
  - "Corrected two stale rationale comments (footer/1 preamble, .pk-footer-toggle-tag comment in app.css) that asserted the drawer's visible label was a deliberate contrast with the footer's sr-only one — that premise no longer holds now that both are sr-only."

patterns-established:
  - "Icon-only labelled control group: role=group + aria-labelledby=<id> on the wrapper, id=<id> + sr-only on the label span, keeping the label string in the DOM (never deleted) as a one-attribute-revert safety net."

requirements-completed: [SHELL-01]

coverage:
  - id: D1
    description: "Drawer theme control (.pk-drawer-utility) centered via justify-content:center, carries role=\"group\" + aria-labelledby=\"pk-drawer-theme-label\"; label span carries the matching id and sr-only, with a document-unique id (no collision with the footer's pk-footer-theme-label)"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#app/1 mobile nav drawer (01.1-09) the drawer's theme control carries role=\"group\" and aria-labelledby"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#app/1 mobile nav drawer (01.1-09) the drawer's theme label is sr-only with a document-unique id"
        status: pass
    human_judgment: false
  - id: D2
    description: "Drawer's three theme buttons stay 44px (min-h-11/min-w-11) after centering — the footer-scoped 28px shrink is not extended to the drawer"
    requirement: SHELL-01
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#app/1 mobile nav drawer (01.1-09) the drawer's three theme buttons stay 44px after centering"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/footer_rhythm_test.exs#the shrink is scoped to the footer, so the mobile drawer keeps its 44px touch targets"
        status: pass
    human_judgment: false
  - id: D3
    description: "Visual result at 375px in both light and dark themes reads as social-content-leads / theme-footer-trails, matching the mockup direction; desktop footer at 1280px remains completely unchanged"
    verification:
      - kind: automated_ui
        ref: "Headless-Chrome CDP session (this run): DOM measurement + screenshots at 375px light/dark (drawer open) and 1280px desktop — see 'Human Verification' section below for full readout and caveats"
        status: pass
    human_judgment: true
    rationale: "Automated CDP measurement and screenshots strongly support the visual claim, but the plan's own checkpoint requires the developer's own eyes on a real device/browser per Task 3's explicit human-check — the executor has no interactive human and a benign dev-only Tidewave overlay partially occludes one screenshot (see below), so final sign-off is deferred to the developer as the plan anticipated."

duration: 20min
completed: 2026-08-24
status: complete
---

# Quick Task 260824-q8z: Mobile Drawer Social/Theme Content-vs-Footer Split Summary

**Centered the mobile drawer's theme control and converted its "Tema" label to sr-only (role="group" + aria-labelledby), mirroring the desktop footer's already-shipped debug-session pattern and applying sketch 021's own Round-6 conclusion — closing out the content-leads/footer-trails redesign of `.pk-drawer-bottom` that Task 1 started.**

## Performance

- **Duration:** ~20 min (this session, Task 2 + Task 3; Task 1 was already shipped in a prior session)
- **Started:** 2026-08-24T22:09:00Z (approx, per git commit timestamps)
- **Completed:** 2026-08-24T22:36:40Z
- **Tasks:** 3 (Task 1 pre-shipped, Task 2 executed this session, Task 3 checkpoint executed this session)
- **Files modified:** 3 (`layouts.ex`, `app.css`, `layouts_test.exs`)

## Accomplishments

- `.pk-drawer-utility` (the drawer's theme control) is now centered (`justify-content: center`, was `space-between`) and carries `role="group"` + `aria-labelledby="pk-drawer-theme-label"`
- Its label span is converted to `sr-only` (kept in the DOM, not deleted) and carries the matching `id="pk-drawer-theme-label"` — document-unique, no collision with the footer's `pk-footer-theme-label`
- The three theme buttons stay at the 44px touch floor (`min-h-11 min-w-11`) — the footer's 28px shrink is deliberately NOT extended to the drawer, since the drawer is the sole mobile home for the control below 480px
- Two stale rationale comments corrected in place (the `footer/1` preamble's "the visible label survives where Geist says it should" paragraph, and the comment above `.pk-footer-toggle-tag` in `app.css`) — neither asserts a state the code no longer has
- Three new tests added (RED-then-GREEN via TDD): `role`/`aria-labelledby` presence, sr-only label with a document-unique id, and the 44px-buttons-survive-centering guard
- `mix quality` passes end to end (443 tests, 0 failures; Credo/Sobelow findings are pre-existing and unrelated to this task)

## Task Commits

Each task was committed atomically:

1. **Task 1: Reorder the drawer bottom block, widen and correct the social row** [DONE — shipped prior session] - `efdf91c` (feat), `a210dde` (style — Styler pipe rewrite)
2. **Task 2: Center the drawer's theme control and convert its label to sr-only** - `13a7a59` (test — RED), `28287b6` (feat — GREEN), `79b392b` (style — mix format)
3. **Task 3: Checkpoint — confirm the finished drawer at 375px, both themes, plus desktop footer** — executed this session; see "Human Verification" below (no code commit — verification-only task)

_TDD task: RED (`13a7a59`) confirmed 2 of 3 new tests failing against the pre-change markup for the stated reasons (the 44px-buttons guard passed pre-change too, matching the footer's own forward-looking-guard precedent), then GREEN (`28287b6`) made all 3 pass._

## Files Created/Modified

- `lib/pukllay_club_web/components/layouts.ex` — `nav_drawer/1`'s `.pk-drawer-utility` wrapper gains `role="group"` + `aria-labelledby`; its label span gains `id` + `sr-only`; `footer/1`'s preamble comment corrected to record the drawer's label conversion and its 44px-vs-28px distinguishing property
- `assets/css/app.css` — `.pk-drawer-utility`'s `justify-content` changed to `center` (with an explanatory comment); the comment above `.pk-footer-toggle-tag` corrected to say both label spans are now sr-only for the same reason
- `test/pukllay_club_web/components/layouts_test.exs` — 3 new tests in the `app/1 mobile nav drawer (01.1-09)` describe block

## Decisions Made

- **Kept the label in the DOM as sr-only rather than deleting it** — mirrors the footer's already-accepted pattern exactly; the label still supplies the control's accessible group name, which is a net a11y gain (3 buttons previously had per-button `aria-label`s but no group name at all).
- **Did not extend the footer's 28px button shrink to the drawer** — the drawer is the sole mobile-width home for the theme control (`.pk-footer-right` is `display: none` at ≤480px), so its 44px floor is load-bearing, not cosmetic.
- **Used a distinct id (`pk-drawer-theme-label` vs. the footer's `pk-footer-theme-label`)** since both render in the same document on every page — reusing one id would point both controls' `aria-labelledby` at an ambiguous target.

## Deviations from Plan

None — plan executed exactly as written. Both markup/CSS edits and both comment corrections match the plan's `<action>` block precisely; no Rule 1–4 auto-fixes were needed.

## Issues Encountered

- **Test syntax:** The first draft of the 44px-buttons guard test used `|> length() - 1` as a pipe target, which Elixir's `Kernel.-/2` doesn't accept as a pipe destination (`- ` requires exactly one more argument via the pipe, producing an `ArgumentError` at compile time, not a test failure). Fixed by rewriting as `|> length() |> Kernel.-(1)`, matching the existing style already used elsewhere in the same test file (`footer_rhythm_test.exs`'s `blank_count` pattern).
- **`mix format` reformatted** one added test (inserted a blank line between two related assertions) — applied and committed separately (`79b392b`) since it's a pure formatting change, not a content edit.

## Human Verification (Task 3)

`mix quality` was run first and passed clean (443 tests, 0 failures; the two Credo/Sobelow findings surfaced are pre-existing, low-confidence, and unrelated to files this task touched).

I do not have interactive human access to a real browser, so I drove a headless Chrome instance via the Chrome DevTools Protocol (CDP) against the locally running dev server (`localhost:4000`, already running from a separate, pre-existing session — I did not start or stop it) to get as close to real visual + structural confirmation as possible:

**375px, light theme, drawer open** — confirmed via direct DOM measurement:
- `drawerOpen: true`, `htmlDataTheme: "light"`
- `.pk-drawer-utility`: `justify-content: center`, `role="group"`, `aria-labelledby="pk-drawer-theme-label"`
- Label: `id="pk-drawer-theme-label"`, class `pk-drawer-utility-label sr-only`, rendered width 1px (visually hidden, as expected of `sr-only`)
- 3 theme buttons, each exactly 44×44px
- Social row: 275.5px wide (4 icons spanning the drawer's full 307.5px inner width edge-to-edge)
- Screenshot confirms: divider → 4 full-strength social icons in a row → divider → centered, label-free theme strip (see cropped screenshot in scratchpad)

**375px, dark theme, drawer open** — same structural readout confirmed (`htmlDataTheme: "dark"`, same centering/sizing), and visually the same layout holds in dark palette with correct color inversion.

**1280px desktop footer, light theme** — re-confirmed unchanged (no regression from this task):
- Social anchors 28×28px, theme buttons 28×28px (both untouched, as expected — this task never modifies footer-scoped CSS)
- `.pk-footer-toggle-tag` class is `pk-footer-toggle-tag sr-only` (unchanged)
- `role="group"` + `aria-labelledby="pk-footer-theme-label"` (unchanged)

**Known limitation of this automated pass, disclosed plainly:** the dev server has Tidewave's dev-only MCP plug active (`plug Tidewave` in `endpoint.ex`, gated to `:dev`), which injects its own small floating "Sign in / settings / theme" widget near the bottom-left of the viewport via a closed shadow root. In the 375px screenshots this widget's left edge visually overlaps the drawer's leftmost (system-theme) icon in the raw screenshot, even though the DOM/CSS measurement above confirms all 3 buttons render correctly at 44×44px, centered, unaffected by the widget. This overlay is a local-dev-only artifact (never present in production, and unrelated to any file this task touched) — I flag it explicitly so it isn't mistaken for a real defect if the developer sees the same thing in their own dev browser.

**What still needs the developer's own sign-off** (per the plan's explicit human-check items, since I cannot substitute for a real device/eyes):
1. Whether the four social icons genuinely "read as content" (subjective visual weight/hierarchy judgment, not just geometry)
2. Whether the centered, label-free theme strip genuinely "reads as a footer" rather than "another list row" (same subjective judgment)
3. Whether the whole bottom block, on a real full-height phone (not a synthetic 900px CDP viewport), leaves real empty space above it rather than reading as shrink-wrapped
4. Final confirmation that nothing "still looks off against the mockup" — a comparison only the developer can make against the reference they have in mind

All structural/geometric claims from `must_haves.truths` are verified programmatically above and are not in question; what remains is the qualitative visual judgment the plan's checkpoint exists to capture.

## Next Phase Readiness

This closes the mobile-drawer half of the content-vs-footer redesign (Task 1 closed the social-row half in the prior session). No blockers for other work. If the developer's own browser check surfaces any adjustment, it should be filed as a new quick task or debug session rather than reopening this one, per the project's normal workflow.

---

*Phase: quick-260824-q8z*
*Completed: 2026-08-24*

## Self-Check: PASSED

All created/modified files confirmed present on disk (`layouts.ex`, `app.css`, `layouts_test.exs`, this SUMMARY.md); all 5 referenced commit hashes (`efdf91c`, `a210dde`, `13a7a59`, `28287b6`, `79b392b`) confirmed present in git log.
