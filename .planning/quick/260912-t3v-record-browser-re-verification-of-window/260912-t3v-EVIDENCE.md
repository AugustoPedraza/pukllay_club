# 260912-t3v — Browser re-verification evidence (WINDOWS #4, #7, #18)

Date: 2026-09-12. Target: local dev server (`http://localhost:4000`), serving the quick-batch
260912-rws fixes (confirmed live: `.pk-pill-interactive` has `min-height: 44px`, `#pk-nav-drawer`
is outside `#app-header` with z-index 551, the About carousel hook has `pauseThenResume`).

Method:

- Claude in Chrome with real mouse clicks and key presses.
- 390px checks ran in a same-origin iframe sized to 390px (`innerWidth` 390).
- 1440px checks ran in the real window (`innerWidth` 1440).
- Reduced-motion and real touch-swipe checks ran in headless Google Chrome driven over raw CDP.
  The Chrome extension cannot open the DevTools Rendering panel or produce touch input. The CDP
  script (`rail_cdp.mjs`, session scratchpad) used `Emulation.setEmulatedMedia`, the same
  mechanism the DevTools emulation uses.

All three entries: **PASS**.

## Entry 4 — Drawer layout + footer at 390px (after 260912-rwt)

Route `/quienes-somos`, 390px, dark then light:

- **Opening:** the drawer was opened by a real click on "Abrir menú" after the hero isologo docked
  into the header (scrollY 500).
- **Stacking (the original failure):** `#pk-nav-drawer` is no longer inside `#app-header` and has
  z-index 551. 104 `elementFromPoint` samples across the drawer rect all hit the drawer, in both
  themes. The "Menú" label and the morph-mark centre (84,31) hit the drawer. The morph-mark sliver
  outside the panel and the Sumate CTA bar hit `pk-nav-drawer-backdrop`. `.pk-about-morph-mark`
  (z-index 60) no longer paints over the drawer.
- **Rows:** "Inicio" and "Quiénes Somos" are full-width 320×45 rows, each with a
  `.pk-drawer-chevron`. `aria-current="page"` is on Quiénes Somos.
- **Bottom block:** `.pk-drawer-bottom` is pinned to the panel bottom (16px panel padding).
- **Footer:** its only visible text is "Powered by BGG", in both themes.
- **Regression smoke (drawer relocation):**
  - On open, focus is on "Cerrar menú" and `aria-expanded="true"`.
  - Escape on `/quienes-somos` closes the drawer, restores `inert` and returns focus to "Abrir menú".
  - A backdrop click on `/` does the same.

Screenshots (Chrome extension temp dir, not committed):

- `/tmp/claude-chrome-screenshots-qWv7xY/screenshot-1789256684627-16.png` (dark)
- `/tmp/claude-chrome-screenshots-qWv7xY/screenshot-1789256718550-17.png` (light)

## Entry 7 — About photo rail interaction (after 260912-rwu)

Route `/quienes-somos#fotos`.

- **1440px, real window, `document.hasFocus()` true throughout:**
  - The "Foto 2" dot was clicked at t=4.0s and the rail jumped to slide 2.
  - Autoplay resumed at 11.3s (6s resume timer plus the next 4.5s tick) and kept a 4.5s cadence.
    The original FAIL was no resume in 44s.
- **Dot click, then hover:** the "Foto 3" dot was clicked, then the mouse rested on the rail. There
  was no advance for 20s, past the 6s timer, so mouseenter cancels the pending resume. Moving the
  mouse off the rail resumed autoplay on the next tick (<0.5s).
- **390px iframe, dot tap:** a real click on a dot jumps the rail, and autoplay resumes afterwards.
  The exact timing was gated by the iframe document's focus, which the extension's own actions
  toggle.
- **Unfocused:**
  - (a) At 390px, the iframe's document was unfocused (the parent page held focus) for 15s. There
    was no advance until focus returned, which is the hook's `document.hasFocus()` guard.
  - (b) A real background tab was opened by a trusted click on a `target=_blank` link. The About
    tab was `hidden` for about 95s with no advance, then ticked normally after returning.
  - Caveat for (b): under automation `document.hasFocus()` read `true` while hidden, so what stopped
    the rail in (b) was Chrome's background-tab throttling, not the guard. (a) is the direct
    evidence for the guard.
- **Reduced motion (headless Chrome, CDP):**
  - Setup: `Emulation.setEmulatedMedia` with `prefers-reduced-motion: reduce`, plus
    `setFocusEmulationEnabled`, so only the reduced-motion guard could stop autoplay.
  - Result: **0 advances in 20s at 1440px and at 390px**.
  - Control run (`no-preference`, 1440px): advances at 0.3, 4.8, 9.3 and 13.6s.
- **Touch swipe, 390px (headless Chrome, CDP `Input.dispatchTouchEvent`):**
  - A real touch swipe on the rail at t=6.0s moved it to the next slide.
  - The next autoplay advance came at 13.4s, 7.4s later (6s resume plus a tick). Without the pause
    it would have come at about 8.9s.
- **Side observation (not a pass criterion, no action taken):** at 1440px the last two slides share
  the rail's max scroll. During autoplay, dot 4 is active for only about 0.4s before dot 5.

## Entry 18 — Tappable creator pills (after 260912-rwv)

- **`/juegos/179`, 390px:**
  - The "Antoine Bauza" (Diseñadores) and "Miguel Coimbra" (Ilustradores) pills measure **44px**
    tall (`pk-pill pk-pill-outline pk-pill-interactive`). The original FAIL measured 26.5px.
  - A real tap on "Antoine Bauza" lands on `/?designers=Antoine+Bauza` with "Resultados", the
    "Diseñador: Antoine Bauza" chip and 7 Wonders Duel.
  - After going back, a real tap on "Miguel Coimbra" lands on `/?artists=Miguel+Coimbra` with
    "Resultados", the "Ilustrador: Miguel Coimbra" chip and 7 Wonders Duel.
- **`/juegos/137` (Wingspan), 390px:**
  - The 4 artist pills (Ana Maria Martinez Jaramillo, Natalia Rojas, Greg May (II), Beth Sobel) are
    all 44px and wrap onto 2 rows inside the 361px column.
  - No pill overflows (`scrollWidth == clientWidth`), and the document has 0 horizontal overflow.
- **1440px:** outline style, hover to brand ink, and navigation already passed in the first session.
  The fix only adds `min-height`.

Screenshots:

- `/tmp/claude-chrome-screenshots-qWv7xY/screenshot-1789256768334-18.png` (179 pills)
- `/tmp/claude-chrome-screenshots-qWv7xY/screenshot-1789256811548-19.png` (137 artists wrap)
