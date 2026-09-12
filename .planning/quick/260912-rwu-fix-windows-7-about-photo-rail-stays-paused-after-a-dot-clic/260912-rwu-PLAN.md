---
phase: quick-260912-rwu
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
files_modified:
  - lib/pukllay_club_web/live/about_live.ex
  - test/pukllay_club_web/about_carousel_hook_test.exs
  - .planning/debug/about-rail-dot-click-pause.md
  - .planning/debug/resolved/about-rail-dot-click-pause.md
files_deleted:
  - .planning/debug/about-rail-dot-click-pause.md

must_haves:
  truths:
    - "At 390px touch, tapping a photo-rail dot on /quienes-somos pauses auto-advance, and auto-advance resumes about 6s after that tap"
    - "Pressing a dot with the keyboard (Enter/Space on the native button, which fires click with no pointerdown) pauses auto-advance and it resumes about 6s later"
    - "Swiping the rail after a dot tap restarts the 6s idle window: autoplay resumes 6s after the LAST touch, not 6s after the dot tap"
    - "With a mouse, resting on the rail keeps autoplay paused even if a dot was clicked less than 6s earlier (mouseenter cancels the pending resume timer); leaving the rail resumes"
    - "A source-contract ExUnit test file fails if the dot click path goes back to a pause with no armed resume, or if mouseenter stops cancelling the pending resume timer"
    - "The debug session is status resolved, lives at .planning/debug/resolved/about-rail-dot-click-pause.md, root_cause unchanged, fix/verification/files_changed filled"
    - "mix quality passes; .planning/WINDOWS.md is untouched"
  artifacts:
    - path: "lib/pukllay_club_web/live/about_live.ex"
      provides: ".AboutCarousel hook with one shared this.pauseThenResume helper called from onClick and onPointerDown"
    - path: "test/pukllay_club_web/about_carousel_hook_test.exs"
      provides: "Source-contract + rendered-DOM regression tests scoped to the .AboutCarousel <script> block: dot tap, keyboard dot press, swipe after dot tap, mouse-on-rail"
    - path: ".planning/debug/resolved/about-rail-dot-click-pause.md"
      provides: "Closed debug session with fix, verification, files_changed"
  key_links:
    - from: "about_live.ex .AboutCarousel this.onClick (listener on this.el, which contains [data-dots])"
      to: "this.pauseThenResume"
      via: "direct call replacing the old pause-only assignment"
      pattern: "this\\.pauseThenResume\\(\\)"
    - from: "about_live.ex .AboutCarousel this.onMouseEnter (listener on this.rail)"
      to: "this.resumeTimer"
      via: "clearTimeout(this.resumeTimer) so a pending dot-click resume cannot fire under a resting mouse"
      pattern: "clearTimeout\\(this\\.resumeTimer\\)"
---

<objective>
Fix WINDOWS #7: on /quienes-somos, tapping, clicking or keyboard-pressing a photo-rail dot pauses
auto-advance for the rest of the page's life. The root cause is already diagnosed and confirmed in
`.planning/debug/about-rail-dot-click-pause.md`. Do NOT re-investigate. In short, `onClick` (on
`#about-carousel`) pauses with no resume, and the only resume paths (`pointerdown` 6s timer,
`mouseleave`) are on `[data-rail]`, which does not contain `[data-dots]`.

Fix (user-specified, implement exactly):
1. One shared pause-then-resume helper in the `.AboutCarousel` hook. It sets paused, clears any
   pending resume timer, then arms the 6000ms resume timer.
2. Both `onClick` (dot activation by tap, mouse or keyboard) and `onPointerDown` (rail swipe) call
   that helper. Neither assigns paused on its own.
3. `mouseenter`/`mouseleave` stay registered on the rail. `mouseenter` MUST cancel the pending 6s
   resume timer, so autoplay does not resume while the mouse rests on the rail.
4. Regression tests for dot tap, keyboard dot press, and swipe after a dot tap. They follow this
   repo's existing hook-testing pattern: ExUnit source-contract assertions scoped to the hook's own
   `<script>` block, as in `test/pukllay_club_web/about_header_morph_test.exs`. No new test
   framework.
5. Close the debug session: fill in Resolution, set status to resolved, and `git mv` it into
   `.planning/debug/resolved/`.

Purpose: at 390px (mobile-first, the primary target), a member who taps a dot to see a photo gets
autoplay back after they stop interacting. This is the behaviour WR-01 (commit 991a22d) intended,
but it only delivered it for rail swipes.
Output: patched hook, new `test/pukllay_club_web/about_carousel_hook_test.exs`, resolved debug
session.

Scope guard: sibling batch items 260912-rwt and 260912-rwv edit `layouts.ex` and `assets/css/app.css`
in separate worktrees. This plan touches ONLY the `.AboutCarousel` `<script>` body in
`about_live.ex`, the new test file, and the debug session file. No markup, CSS, `layouts.ex` or
`app.css` edits. Do NOT edit `.planning/WINDOWS.md`.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md
@.planning/debug/about-rail-dot-click-pause.md
@lib/pukllay_club_web/live/about_live.ex
@test/pukllay_club_web/about_header_morph_test.exs

Interfaces the executor needs, extracted so no re-exploration is required:

- `.AboutCarousel` colocated hook: `about_live.ex` lines ~436-549, inside
  `<script :type={Phoenix.LiveView.ColocatedHook} name=".AboutCarousel">`. The same file also holds a
  second hook, `.AboutHeaderMorph`, so any file-wide text match is meaningless. Always scope to the
  `.AboutCarousel` block.
- Current handler shapes, each a single-level arrow-function body that ends at a line holding only
  a closing brace: `this.onClick = (e) => {` (~483, registered via
  `this.el.addEventListener("click", this.onClick)`), `this.onPointerDown = () => {` (~517),
  `this.onMouseEnter = () => {` (~522), `this.onMouseLeave = () => {` (~526). The last three are
  registered on `this.rail` (~530-532). `this.resumeTimer = null` is at ~516. `destroyed()` clears
  `this.timer` and `this.resumeTimer` and removes all listeners (~539-547).
- DOM: `#about-carousel` > `div[data-rail]` (5 `figure.pk-about-slide`) and, as a SIBLING,
  `div[data-dots]` (5 `<button type="button" data-goto="N" aria-label="Foto N">`). Dots are native
  buttons, so Enter/Space fire `click` with no `pointerdown`.
- Existing test idiom (`about_header_morph_test.exs` lines 23-36): a private
  `about_header_morph_hook_source/1` does `Regex.run(~r/name="\.AboutHeaderMorph">\s*(.*?)<\/script>/s, src)`
  and flunks if nil. It reads the file via `File.read!("lib/pukllay_club_web/live/about_live.ex")`.
  Rendered-DOM checks use `live(conn, ~p"/quienes-somos")` + `LazyHTML.from_document/1` +
  `LazyHTML.query/2`. Module uses `PukllayClubWeb.ConnCase, async: true` and
  `import Phoenix.LiveViewTest`.
- `mix quality` = hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted
  (Styler plugin), credo --strict, sobelow --config, test --warnings-as-errors.
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Shared pause-then-resume helper in .AboutCarousel, pinned by RED-first source-contract tests</name>
  <files>test/pukllay_club_web/about_carousel_hook_test.exs, lib/pukllay_club_web/live/about_live.ex</files>
  <behavior>
    - Dot tap: the click listener sits on the hook root (`this.el`, which contains `[data-dots]`), and `onClick` calls `this.pauseThenResume()`, so a tapped dot arms the 6s resume timer. `onClick` makes no direct paused assignment.
    - Keyboard dot press: the dots render as `button[type="button"]` inside `#about-carousel`, and arming the resume happens in the CLICK path, not only in pointerdown. `onClick` calls the helper, so a click with no pointerdown (Enter/Space) still resumes.
    - Swipe after a dot tap: `onPointerDown` is registered on `this.rail` and calls `this.pauseThenResume()`. Inside the helper, `clearTimeout(this.resumeTimer)` comes BEFORE `this.resumeTimer = setTimeout(`, so a later swipe restarts the 6s window. The hook block has exactly one `setTimeout(` (one resume timer, no second timer path).
    - Helper contract: the `this.pauseThenResume` body contains `this.paused = true`, `clearTimeout(this.resumeTimer)`, `this.resumeTimer = setTimeout(` and `6000`.
    - Mouse on rail: `mouseenter` and `mouseleave` are registered on `this.rail`. `onMouseEnter` contains both `this.paused = true` and `clearTimeout(this.resumeTimer)`. `onMouseLeave` contains `this.paused = false` and `clearTimeout(this.resumeTimer)`.
    - No pause-only path: after stripping `//` comment lines, the literal `this.paused = true` occurs EXACTLY 2 times in the `.AboutCarousel` block (the helper and `onMouseEnter`).
    - DOM premise (render test, passes before and after the fix, pins WHY the click path must own the resume): `#about-carousel [data-dots] [data-goto]` counts 5, and `#about-carousel [data-rail] [data-goto]` counts 0.
    - Teardown still intact: `destroyed()` still calls `clearTimeout(this.resumeTimer)` and still removes the click listener from `this.el` and the pointerdown listener from `this.rail`.
  </behavior>
  <action>
RED first. Create `test/pukllay_club_web/about_carousel_hook_test.exs` as
`PukllayClubWeb.AboutCarouselHookTest`, mirroring `about_header_morph_test.exs`: `use
PukllayClubWeb.ConnCase, async: true`, `import Phoenix.LiveViewTest`, and a header comment. The
comment says this file is the source-contract regression gate for WINDOWS #7 / debug session
about-rail-dot-click-pause, that ExUnit cannot run the hook's timers, and that timer behaviour
itself was proven by an out-of-tree Node execution of the real hook source (Task 2).

Add these private helpers:
(a) `about_carousel_hook_source/0`. It reads `lib/pukllay_club_web/live/about_live.ex` and
captures the `.AboutCarousel` block with the same regex shape the morph test uses, but
`name="\.AboutCarousel"`. It flunks with a clear message when there is no match, then removes whole
`//` comment lines with a multiline regex (`~r{^\s*//.*$}m`). JS comments are prose, not code, so a
code token quoted inside a comment must never satisfy or break a gate. This is the same reasoning
as the CSS `strip_comments/1` idiom.
(b) `handler_body/2`. Given the stripped hook source and a member name (for example `"onClick"`),
it captures from `this.<name> = ` through the arrow-function opening brace, lazily up to the first
line holding only a closing brace. It flunks naming the handler when not found. The member name
must be regex-escaped.

Write one `describe` per behavior group listed in `<behavior>`: dot tap, keyboard dot press, swipe
after a dot tap, helper contract, mouse on rail, no pause-only path, DOM premise, teardown. Name
tests after the user scenario (e.g. "a dot tap arms the 6s resume (WINDOWS #7)"). Give every
failure message a line of why, in the style of the morph test. Registration-target assertions match
the literal listener lines: `this.el.addEventListener("click", this.onClick)`,
`this.rail.addEventListener("pointerdown", this.onPointerDown)`,
`this.rail.addEventListener("mouseenter", this.onMouseEnter)`,
`this.rail.addEventListener("mouseleave", this.onMouseLeave)`. For the helper ordering assertion,
compare `:binary.match/2` offsets inside the helper body. Run the file and confirm the
helper/dot-tap/keyboard/swipe/no-pause-only tests FAIL against the unfixed hook. The DOM-premise,
mouse-on-rail and teardown tests are expected to pass already. Commit the RED state per the TDD
cycle.

GREEN. In the `.AboutCarousel` `<script>` block of `about_live.ex` only:
- Define `this.pauseThenResume = () => { ... }` right after `this.resumeTimer = null`. It sets paused
  true, clears `this.resumeTimer`, then assigns `this.resumeTimer = setTimeout(() => { this.paused =
  false }, 6000)`. It must be defined before any handler can fire. Handlers run only after
  `mounted()` finishes, so defining it after `onClick`'s declaration is fine at runtime. For
  readability, declare `this.resumeTimer` + the helper ABOVE `this.onClick`, moving that
  declaration up from its current spot.
- `this.onClick`: keep the `closest("[data-goto]")` + `this.el.contains(button)` guard, replace the
  pause-only assignment with `this.pauseThenResume()`, then `this.goTo(...)` as before.
- `this.onPointerDown`: body becomes just the helper call. It stays registered on `this.rail`.
  Do not move it to `this.el`: the click path already covers dots for every input modality, and
  per the user decision the rail remains the swipe/hover surface.
- `this.onMouseEnter` / `this.onMouseLeave`: keep them unchanged and registered on the rail.
  `onMouseEnter` already cancels the pending timer, and that cancel is exactly the user-required
  guarantee that a dot-click resume cannot fire under a resting mouse. Keep it and do not weaken
  it. Do NOT add a hover flag or any extra guard beyond what the user specified.
- Rewrite the WR-01 comment block into plain prose. It must state that dot activation (tap, mouse
  or keyboard, via the root click listener) and rail swipes share one pause-then-resume helper, that
  the dots live outside the rail so rail-scoped listeners never see them (WINDOWS #7), and that
  mouseenter cancels a pending resume so a resting mouse keeps the rail paused. The comment must not
  quote code tokens such as assignment statements or timer calls; describe them in words.
- `destroyed()` stays as is.
- Mobile-first check (390px): no markup, class, CSS or touch-target change is needed or allowed.
  The dots already carry `min-h-11 min-w-11`.

Run the new test file until green. Then run `mix format` (Styler may rewrite the test file; review
the `git diff` of every Styler rewrite before committing, per CLAUDE.md) and commit the GREEN state.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && mix test test/pukllay_club_web/about_carousel_hook_test.exs test/pukllay_club_web/about_header_morph_test.exs test/pukllay_club_web/live/about_live_test.exs --warnings-as-errors</automated>
  </verify>
  <done>New test file exists and was observed failing on the unfixed hook, then passing. `.AboutCarousel` has one `this.pauseThenResume` helper called from both `onClick` and `onPointerDown`, and neither handler assigns paused directly. mouseenter/mouseleave are still on the rail, and mouseenter still cancels the resume timer. The morph and about_live suites stay green. No file outside the two listed was modified.</done>
</task>

<task type="auto">
  <name>Task 2: Execution-level proof of the fixed hook, debug-session close-out, and mix quality gate</name>
  <files>.planning/debug/about-rail-dot-click-pause.md, .planning/debug/resolved/about-rail-dot-click-pause.md</files>
  <action>
Behavioural proof (NOT committed; lives only in the executor's own session scratchpad directory):
the ExUnit gate is textual, so prove the timers really behave by running the REAL fixed hook source
the same way the debug session did (Evidence 2026-09-12T23:52). If
`/tmp/claude-1000/-home-apedraza-projects-pukllay-club/8d9ea666-ed72-48ff-8d18-60586f9bae3c/scratchpad/carousel_sim.mjs`
still exists, copy it into your own scratchpad and adapt it. Otherwise write an equivalent. The
script extracts the `.AboutCarousel` script body verbatim from `about_live.ex`, strips `export
default`, and mounts it against a DOM stub mirroring the HEEx tree (root > rail > 5 slides; root >
dots > 5 `data-goto` buttons) with real event bubbling, fake timers, `document.hasFocus()` true and
reduced-motion false. Run it with the mise-provided `node` (v22) and record pass/fail with
timestamps for:
K1 dot tap: pointerdown + click on dot 2 after idle. Paused, then cleared exactly 6000ms after the
tap, and autoplay scrolls resume on the following 4500ms ticks.
K2 keyboard dot press: click ONLY on dot 2, no pointerdown. Same resume as K1.
K3 swipe after a dot tap: dot tap at t, rail-slide pointerdown at t+3000. Still paused at t+6000,
cleared at t+9000.
K4 mouse resting on the rail after a dot click: dot click at t, rail mouseenter at t+2000, no
mouseleave for 20s. Zero autoplay scrolls during that window and paused still true after
t+6000. Then mouseleave, and autoplay resumes on the next tick.
K5 control, rail swipe alone: resumes after 6000ms (unchanged WR-01 behaviour).
If any scenario fails, fix the hook in Task 1's scope, re-run Task 1's verify, and re-run the
simulation. Never weaken a scenario to make it pass.

Debug session close-out, editing `.planning/debug/about-rail-dot-click-pause.md` in place first:
- Frontmatter: `status: resolved`, and set `updated:` to the current UTC timestamp.
- Current Focus: update `next_action` to say the session is resolved by quick 260912-rwu. Leave the
  diagnosis fields as the historical record.
- Resolution: leave `root_cause` text unchanged. Fill in `fix:` (one shared pause-then-resume helper
  in the `.AboutCarousel` hook, called from the root click listener and the rail pointerdown
  listener; mouseenter/mouseleave kept on the rail, and mouseenter cancels the pending 6s timer;
  cite quick 260912-rwu and the GREEN commit hash). Fill in `verification:` as a block scalar: the
  K1-K5 simulation results with timings, the new test file's name + test count, `mix quality` exit
  status + total tests/failures. Also state honestly that no live browser re-check at 390px was
  performed in this run (if none was), and that WINDOWS.md was intentionally left untouched per
  instruction. Fill in `files_changed:` with `lib/pukllay_club_web/live/about_live.ex` and
  `test/pukllay_club_web/about_carousel_hook_test.exs`.
- Leave the Specialist Review section's content as is.
Then `git mv .planning/debug/about-rail-dot-click-pause.md .planning/debug/resolved/about-rail-dot-click-pause.md`.

Final gate: run `mix quality` from the repo root, which must exit 0. Confirm
`git status --porcelain .planning/WINDOWS.md` prints nothing. Commit the session move + edits as
`docs(quick-260912-rwu): resolve about-rail-dot-click-pause debug session`.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && test -f .planning/debug/resolved/about-rail-dot-click-pause.md && test ! -e .planning/debug/about-rail-dot-click-pause.md && grep -q '^status: resolved' .planning/debug/resolved/about-rail-dot-click-pause.md && grep -q 'pauseThenResume' .planning/debug/resolved/about-rail-dot-click-pause.md && test -z "$(git status --porcelain .planning/WINDOWS.md)" && mix quality</automated>
  </verify>
  <done>K1-K5 all pass against the real fixed hook source, with results recorded in the session's verification field. The session file exists only under `.planning/debug/resolved/`, with `status: resolved`, unchanged root_cause, and filled fix/verification/files_changed. `mix quality` exits 0. `.planning/WINDOWS.md` is unmodified. No simulation script is committed.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| none new | Client-side timer/state change inside an existing colocated hook. No new input is read, and nothing is sent to the server, fetched, stored or rendered from user data. `data-goto` values are server-rendered static literals parsed with `parseInt`, same as before. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-rwu-01 | Denial of Service | `.AboutCarousel` resume timer across LiveView remounts | low | mitigate | The helper always clears the previous resume timer before arming a new one (a single timer handle, asserted by the one-`setTimeout(` and clear-before-set tests), and `destroyed()` keeps clearing both the interval and the resume timer. Repeated taps or remounts therefore cannot pile up timers or write to a detached element. |
| T-rwu-02 | Tampering | `data-goto` attribute read in `onClick` | low | accept | Unchanged from the shipped hook. A DOM-tampered value only changes the client's own local scroll target (clamped by the browser's scroll bounds). No server effect, no injection sink. |
| T-rwu-03 | Information Disclosure | out-of-tree Node simulation script | low | accept | Lives only in the executor's session scratchpad, reads a public source file, and is never committed. No secrets involved. |
</threat_model>

<verification>
- `mix test test/pukllay_club_web/about_carousel_hook_test.exs` is green, and was observed RED on the unfixed hook.
- K1-K5 execution of the real hook source passes: dot tap, keyboard dot press, swipe after dot tap, mouse resting on the rail, and the swipe control.
- `mix quality` exits 0.
- `git diff --name-only` for this item lists only `lib/pukllay_club_web/live/about_live.ex`, `test/pukllay_club_web/about_carousel_hook_test.exs`, and the debug-session rename. `.planning/WINDOWS.md`, `layouts.ex` and `app.css` are untouched.
</verification>

<success_criteria>
At 390px and on desktop, a dot tap, click or keyboard press on the About photo rail pauses
auto-advance, which resumes 6s after the last interaction. A swipe after a dot tap extends that
window. A mouse resting on the rail keeps it paused until the mouse leaves. The behaviour is gated
by a source-contract ExUnit file in the existing repo pattern and was proven by executing the real
hook source. The debug session is resolved and moved. `mix quality` passes.
</success_criteria>

<output>
Create `.planning/quick/260912-rwu-fix-windows-7-about-photo-rail-stays-paused-after-a-dot-clic/260912-rwu-SUMMARY.md` when done
</output>
