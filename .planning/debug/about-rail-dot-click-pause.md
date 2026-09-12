---
status: diagnosed
trigger: "WINDOWS entry 7 browser-verification FAIL — clicking/tapping a photo-rail dot on /quienes-somos pauses auto-advance permanently; it never resumes."
created: 2026-09-12T23:30:00Z
updated: 2026-09-12T23:53:00Z
goal: find_root_cause_only
---

## Current Focus

hypothesis: Dot click sets `paused = true` in onClick (listener on #about-carousel) but nothing arms the 6s resumeTimer, because the only timer-arming path (onPointerDown) and the only mouse resume path (onMouseLeave) are registered on [data-rail], which does not contain [data-dots].
bug_class: Bohrbug (deterministic — reproduces on every dot click, no timing dependence)
status_of_hypothesis: CONFIRMED (code reading + direct execution of the real hook source; see Evidence)
candidate_causes:
  - "code: dot pause path (onClick on this.el) has no resume; resume listeners are scoped to [data-rail], which excludes [data-dots]" (CONFIRMED)
  - "environment: document.hasFocus() false or prefers-reduced-motion matching suppresses the tick" (ELIMINATED)
and_gate: "yes. The failure needs both (a) onClick setting paused=true with no timer and (b) the resume listeners (pointerdown/mouseleave) being on [data-rail] instead of an ancestor of the dots. Removing either one stops the permanent pause for pointer input. Keyboard dot activation (click with no pointerdown) depends on (a) alone."
next_action: return ROOT CAUSE FOUND (diagnose-only; no fix applied)

## Symptoms

expected: (WINDOWS entry 7 checklist) At 390px, swiping the rail OR tapping a dot pauses auto-advance, which then resumes about 6s after the last touch. With a mouse, hovering the rail pauses and leaving resumes.
actual: After clicking a dot ("Foto 3", data-goto="2"), the rail correctly jumps and dot 3 becomes active, but auto-advance never resumes. Observed at a real 1440px viewport with the page focused (document.hasFocus() true throughout), mouse NOT over the rail, prefers-reduced-motion not matching: zero advances over 44s after the click. It only resumed after the mouse entered and left the rail (mouseenter → mouseleave clears `paused`).
errors: none
timeline: Found 2026-09-12 during the browser verification of waived WINDOWS.md entries (todo 2026-09-12-browser-verification-session-for-waived-windows-ui-entries.md).
reproduction: Local dev server. Open /quienes-somos#fotos, keep the mouse off the rail, confirm auto-advance every ~4.5s, then click any dot below the rail and move the mouse away from the rail. Wait >10s — no further advance.

suspected_mechanism (from reading, not yet proven — verify):
- lib/pukllay_club_web/live/about_live.ex AboutCarousel hook: `this.onClick` (listener on this.el) sets `this.paused = true` for any `[data-goto]` button, but does not arm `this.resumeTimer`.
- The 6s resume timer is only armed in `this.onPointerDown`, which is registered on `this.rail` only. The dots (`[data-dots]`) are NOT inside `[data-rail]` (measured: `#fotos [data-rail] [data-goto]` → null), so a dot tap never reaches onPointerDown.
- `mouseleave` is also registered on the rail only, so with a mouse the dot click is not undone either, and on touch devices it never is.
- Consequence at 390px touch: tapping a dot pauses autoplay for the rest of the page's life (the WR-01 bug the resume timer was added to fix, but only for rail swipes).

other_entry7_observations (2026-09-12):
- PASS: manual rail scroll tracks the active dot (.is-active + aria-current) incl. last dot at max scroll; dot click jumps; idle auto-advance ~4.5s; hover pause; mouseleave resume on next tick.
- NOT RUN: "switch tab → autoplay stops while unfocused" and "prefers-reduced-motion: reduce → no autoplay" (browser automation could not background the tab or emulate the media feature).
- Side note (not a failure): autoplay from index 2 → goTo(3) lands near max scroll so dot 4 only flashes ~0.4s before dot 5 activates at 1440px.

relevant_files:
- lib/pukllay_club_web/live/about_live.ex (AboutCarousel hook ~lines 440-550, dots markup ~590-625)

## Evidence

- timestamp: 2026-09-12T23:45:00Z
  checked: Phase 0 knowledge base (.planning/debug/knowledge-base.md) for carousel/autoplay/pause/resume patterns
  found: No prior entry matches this symptom class (no MemPalace query performed in this diagnose-only run)
  implication: Proceed with open-ended investigation; SBFL skipped (hook JS has no per-test coverage, and about_live_test.exs only counts [data-goto] server-side at line 417)

- timestamp: 2026-09-12T23:47:00Z
  checked: lib/pukllay_club_web/live/about_live.ex lines 483-489 (onClick)
  found: `this.onClick` is registered on `this.el` (#about-carousel). For any `[data-goto]` button it sets `this.paused = true` and calls goTo(). It never touches `this.resumeTimer`.
  implication: A dot click is a pause-only path with no built-in resume.

- timestamp: 2026-09-12T23:47:00Z
  checked: about_live.ex lines 516-532 (WR-01 resume logic) and 530-532 (registration targets)
  found: The only code that arms the 6000ms resume timeout is `onPointerDown`. The only immediate resume is `onMouseLeave`. `pointerdown`, `mouseenter` and `mouseleave` are all registered on `this.rail` (`[data-rail]`), not on `this.el`.
  implication: Resume paths fire only for interactions whose target is inside [data-rail].

- timestamp: 2026-09-12T23:48:00Z
  checked: HEEx DOM structure, about_live.ex lines 436, 550, 591-592, 624-625
  found: `#about-carousel` has two sibling children: `<div data-rail>` (closes at line 591) and `<div data-dots>` (line 592). The dot buttons are descendants of [data-dots], not of [data-rail]. assets/css/app.css:3666 `.pk-about-dots` is plain in-flow flex with `margin-top: 1rem` (no absolute positioning), so the dots don't overlap the rail visually either. This matches the live measurement `#fotos [data-rail] [data-goto]` returning null.
  implication: A dot's pointerdown bubbles dot -> [data-dots] -> #about-carousel and skips [data-rail]. onPointerDown never runs, so no resume timer. Hovering a dot doesn't fire the rail's mouseenter/mouseleave either.

- timestamp: 2026-09-12T23:49:00Z
  checked: every other place `paused` is read or written, and any focus/visibility/tick resume path (full hook, lines 439-547)
  found: `paused` is written only in onClick (true), onPointerDown (true, plus a 6s timeout back to false), onMouseEnter (true) and onMouseLeave (false). The setInterval tick (534-537) only reads `paused`, `document.hasFocus()` and `reducedMotion.matches`, and returns early without clearing anything. No visibilitychange, focus, blur or focusin/focusout listeners exist. onScroll, goTo and setActive never touch `paused`. destroyed() only tears down.
  implication: No other path clears `paused` after a dot click. It stays true until the user mouses into and back out of the rail (mouse only) or the hook remounts. Touch users have no recovery at all, and neither do keyboard users (Enter/Space on a dot fires click with no pointerdown).

- timestamp: 2026-09-12T23:50:00Z
  checked: git history. 991a22d "fix(01.4): WR-01 add touch-equivalent autoplay resume to photo carousel"
  found: WR-01 turned onPointerDown from `paused = true` into pause-plus-6s-timeout, and its comment says "touch devices fire pointerdown on every swipe/dot tap". The listener stayed on `this.rail`, and onClick's `paused = true` (present since 320fc4b) was left unchanged.
  implication: WR-01 assumed dot taps reach the rail's pointerdown listener, but the DOM structure makes that false. The regression was never fixed for dots, only for rail swipes. It was never caught because no JS hook test exists and the WR-01 fix was never checked with a dot tap.

- timestamp: 2026-09-12T23:52:00Z
  checked: executed the REAL hook source (extracted verbatim from about_live.ex) in Node 22 against a DOM stub mirroring the HEEx tree (root > rail > 5 figures; root > dots > 5 buttons), with event bubbling and fake timers (scratchpad/carousel_sim.mjs)
  found: |
    A) dot tap (pointerdown + click on [data-goto=2]) after 10s idle (2 autoplay advances): paused=true, 0 autoplay scrolls in the following 44s (only the click's own goTo at t=10000), no pending resume timeout.
    B) rail swipe (pointerdown on a slide), the control case: paused cleared at t=16000, autoplay resumed at t=18000 and advanced every 4500ms (9 scrolls in 44s).
    C) dot click, then rail mouseenter+mouseleave 2s later: autoplay resumed on the next tick (t=13500), matching the user's observed workaround exactly.
  implication: Hypothesis confirmed by direct execution, and reproduces the browser observation (zero advances over 44s, only recoverable by hovering in and out of the rail).

## Eliminated

- hypothesis: Autoplay is suppressed by the environment, i.e. the page lost focus (`document.hasFocus()` false) or `prefers-reduced-motion: reduce` matches
  evidence: Symptoms record hasFocus() true throughout and reduced-motion not matching. The Node simulation stubs both to "allow autoplay" and still shows 0 advances after a dot tap, while the rail-swipe control resumes under identical stubs.
  timestamp: 2026-09-12T23:52:00Z

- hypothesis: The dots visually overlap the rail, so a real pointer on a dot is also over the rail (and the bug is instead in the timer logic itself)
  evidence: .pk-about-dots is in-flow below the rail (margin-top: 1rem, no positioning), and event bubbling follows DOM containment, not visuals. The timer logic itself works: case B resumes after exactly 6000ms.
  timestamp: 2026-09-12T23:52:00Z

## Specialist Review

- specialist_hint: general (mapped skill: engineering:debug)
- result: NOT RUN. The session manager had no Skill tool in this run, so no specialist verdict exists. No review result has been made up.
- session-manager note (not a specialist verdict): with a shared pause-then-resume helper, the 6s timer could fire while a mouse is resting on the rail (for example, click a dot, then hover the rail within 6s), which would clear the hover pause. The resume should check a hover flag, or `mouseenter` should cancel the pending timer. The debugger's "mouse resting on rail after dot click stays paused" regression check covers this.

## Resolution

root_cause: Two things combine. First, the AboutCarousel hook's onClick handler (about_live.ex:483-488, registered on #about-carousel) sets `this.paused = true` for dot clicks without arming any resume. Second, both resume paths, the WR-01 6s idle timeout in onPointerDown and the immediate resume in onMouseLeave, are registered only on `[data-rail]` (about_live.ex:530-532), and the `[data-dots]` container is a sibling of the rail, not a descendant (lines 550/591/592). A dot's pointerdown therefore never reaches onPointerDown, and no other code (the tick, focus/visibility handlers, onScroll) ever clears `paused`. Autoplay stays stopped until a mouse enters and leaves the rail. On touch or keyboard it stays stopped for the rest of the page's life.
fix:
verification:
files_changed:
