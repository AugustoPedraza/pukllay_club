---
status: resolved
trigger: "G-01.3-5: The mobile sticky title-echo bar's visual styling (colors, font weight, size, font) is not well balanced on the game detail page at 390px (Phase 01.3, PukllayClub board-game catalog, Phoenix LiveView)."
created: 2026-08-31T00:00:00Z
updated: 2026-08-31T23:35:00Z
---

## Current Focus

hypothesis: CONFIRMED — `.pk-title-echo-name` (the sticky bar's title text) has zero explicit
typography (no font-family, font-weight, font-size, or color) at either the CSS-rule level or the
HEEx markup level, so it silently inherits the page's ambient default body text style (Inter,
default/normal weight, base default size, base-content color) instead of any deliberately chosen
"title" treatment. This is visually adjacent to `.pk-scroll-top`, a bold solid
`var(--color-primary)`-filled 44px circular button — a heavy, saturated element next to plain,
undifferentiated text — which reads as exactly the "colors, weight, size and font" imbalance
reported.
test: Compared `.pk-title-echo-name`'s declared CSS + HEEx classes against (a) the real page H1
it echoes (`font-display text-3xl`) and (b) the breadcrumb's own echo of the same game name
(`.pk-crumb-current`, ambient 0.875rem / `--color-neutral` via `.pk-nav-crumb`) — both of those
surfaces make a deliberate typographic choice; the title-echo bar's span makes none.
expecting: If confirmed, `.pk-title-echo-name` and its HEEx `<span>` would show no font-family/
weight/size/color declarations anywhere in their cascade chain, while sibling "title" surfaces on
the same page do declare them.
next_action: none — root cause confirmed, diagnose-only mode, returning to caller for fix routing.

## Symptoms

expected: |
  At 390px, scroll a long game page until the mobile sticky title bar appears, in both light and
  dark theme. The bar should read as a visually distinct surface over the content passing beneath
  it (not blending into the page background), its title should truncate cleanly with an ellipsis
  rather than wrapping, and its left/right content edges should line up with the masthead's. Note:
  the bar's brand-tint/color treatment and `.pk-scroll-top`'s bounce animation were deliberately
  left unchanged this round (see 01.3-09-SUMMARY.md "Open design questions") — this check is only
  about separation, legibility and alignment, not overall brand styling.
actual: |
  User reports: "Needs a better balance with colors, weight, size and font" — a general
  visual/design quality complaint about the sticky bar's color, font-weight, size, and
  font-family treatment.
errors: None reported
reproduction: Test 5 in UAT — at 390px viewport, scroll a long game detail page until the sticky
  title bar appears, in both light and dark theme.
started: Discovered during UAT of Phase 01.3. Plan 01.3-09 worked on the sticky title-echo bar;
  its "Open design questions" section already flagged the bar's brand-tint/color treatment (the
  bar's own background fill) and `.pk-scroll-top`'s fill/bounce as deliberately deferred — but
  did NOT discuss or touch `.pk-title-echo-name`'s typography at all.

## Eliminated

- hypothesis: This is the same "brand-tint/color treatment" open design question already logged
    and deferred in 01.3-09-SUMMARY.md, so no new investigation is needed.
  evidence: |
    01.3-09-PLAN.md's own scope statement is explicit about what was left open: "whether the bar
    should carry a brand tint (accent/primary/translucent primary) instead of a neutral base
    step, and whether `.pk-scroll-top`... is the actual source of the 'balance is off' reading."
    That is entirely about the BAR'S OWN BACKGROUND FILL and the SCROLL-TOP BUTTON's fill/bounce.
    The plan's "Deliberately unchanged" artifact list explicitly names `.pk-title-echo-name` as
    untouched, and Task 1's action text confirms: "Do NOT change:... `.pk-title-echo-name`'s four
    truncation properties." No task, decision option, or SUMMARY note in 01.3-09 ever discusses
    the title span's font-family, font-weight, or font-size. The deferred question and this UAT
    report overlap in vocabulary ("balance," "colors") but are not the same defect — one is about
    the bar's fill/button color, the other (this one) is about the title text having no
    typography decision made for it at all.
  timestamp: 2026-08-31

## Evidence

- timestamp: 2026-08-31
  checked: assets/css/app.css lines 3524-3594 (`.pk-title-echo`, `.pk-title-echo-inner`,
    `.pk-title-echo-name`)
  found: |
    `.pk-title-echo` declares only position/layout/background/border/opacity/transform — no font
    properties. `.pk-title-echo-inner` declares only flex layout properties. `.pk-title-echo-name`
    declares only `min-width: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;`
    (truncation only, added in a prior round for a two-line-wrap bug, G-01.2-14/24). None of the
    three rules sets font-family, font-weight, font-size, or color.
  implication: The title text has no deliberate typographic identity in the stylesheet at all.
- timestamp: 2026-08-31
  checked: lib/pukllay_club_web/live/catalog_live/show.ex line 375-387 (`#detail-title-echo`
    markup)
  found: |
    `<span class="pk-title-echo-name">{@game.name}</span>` — no Tailwind typography utility
    classes (no `font-display`/`font-sans`, no `text-*` size, no `font-bold`/`font-semibold`, no
    text-color class). Its sibling, `.pk-scroll-top` (the scroll-to-top button), is a fixed
    2.75rem (44px) circle with `background: var(--color-primary)` — a bold, saturated, solid-fill
    element.
  implication: The title text inherits ambient default body typography (Inter, default weight,
    default size, base-content color) by omission, not by decision — and sits directly beside a
    visually heavy, brand-primary-colored button, producing an unbalanced pairing.
- timestamp: 2026-08-31
  checked: lib/pukllay_club_web/live/catalog_live/show.ex line 513 (the real page H1) and
    line 269-273 (`.pk-crumb-current`, the breadcrumb's own echo of the game name)
  found: |
    The real title: `<h1 id="detail-title-block" class="font-display text-3xl">{@game.name}</h1>`
    — explicit brand display font (`--font-display: "Bebas Neue"`) at a large size. The
    breadcrumb's echo: `<span class="pk-crumb-current">{@game.name}</span>` inside
    `.pk-nav-crumb`, which sets `font-size: 0.875rem; color: var(--color-neutral);` — a
    deliberately small, muted treatment appropriate for secondary navigation text.
  implication: Two other places on this exact page that also render the game's name each made an
    explicit, deliberate typographic choice appropriate to their role (primary title = bold
    display font/large; breadcrumb echo = small/muted). The sticky bar's title — which functions
    as a "title echo," a reduced restatement of the H1 as it scrolls off-screen — made no such
    choice at all.
- timestamp: 2026-08-31
  checked: .planning/phases/01.3-game-detail-layout-content-accuracy/01.3-09-PLAN.md (full plan)
    and 01.3-09-SUMMARY.md ("Open design questions" section)
  found: |
    The plan's must_haves, Task 1 action text, and "Deliberately unchanged" artifact list all
    scope the open design question to the bar's background fill (`.pk-title-echo`'s `background`
    token) and `.pk-scroll-top`'s solid fill + infinite bounce. `.pk-title-echo-name` is
    explicitly listed as untouched/unchanged, and its typography was never part of the
    discussion, the options offered at the Task 3 checkpoint, or the developer's
    accept-mechanical decision.
  implication: This UAT report (item 7 in the new round, gap G-01.3-5) surfaces a genuinely new,
    previously-unaddressed implementation gap — not a re-report of the already-logged-and-deferred
    brand-tint question, even though both use similar vocabulary ("balance," "colors").

## Resolution

root_cause: |
  The sticky title-echo bar's title text (`.pk-title-echo-name`, rendered from a bare
  `<span class="pk-title-echo-name">{@game.name}</span>` in show.ex) has no explicit font-family,
  font-weight, font-size, or color declared anywhere in its cascade — neither in the CSS rule
  itself, its ancestor rules (`.pk-title-echo`, `.pk-title-echo-inner`), nor as Tailwind utility
  classes in the markup. It silently falls back to the page's ambient default body typography
  (Inter/`--font-sans`, default weight, default size, inherited `base-content` color), which was
  never a deliberate choice for a "title" role. This is visually inconsistent with (a) the actual
  H1 it echoes, which uses the brand display font (`--font-display`, Bebas Neue) at `text-3xl`,
  (b) the breadcrumb's own echo of the same game name, which is deliberately small (0.875rem) and
  muted (`--color-neutral`), and (c) its own sibling in the bar, `.pk-scroll-top`, a bold
  solid-`--color-primary`-filled 44px circle. The plain, undifferentiated text next to a heavy,
  saturated button is the concrete mechanism behind "Needs a better balance with colors, weight,
  size and font." This is a distinct, previously-unaddressed implementation gap — plan 01.3-09
  explicitly scoped its "open design question" to the bar's own background fill and
  `.pk-scroll-top`'s fill/bounce, and explicitly listed `.pk-title-echo-name` as deliberately
  unchanged; the title text's typography was never part of that discussion.
fix: (not applied — diagnose-only mode)
verification: (not applicable — diagnose-only mode)
files_changed: []
