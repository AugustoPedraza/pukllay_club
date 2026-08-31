---
status: diagnosed
trigger: "G-01.3-4: On the game detail page description card, the expand/collapse chevron icon sits outside the right edge of the text column at 390px viewport width."
created: 2026-08-31T19:00:00Z
updated: 2026-08-31T19:30:00Z
---

## Current Focus

hypothesis: The `.pk-desc-toggle` reveal chevron is positioned via `float: right`
inside a `text-align: justify` / `is-clamped` paragraph — a technique the
implementing plan's own reference (`description-truncation.md`) already flags as
having "no native clean-cut guarantee" for float-vs-justify interaction on the
clamped (3rd) line, previously observed misbehaving differently at a different
frame width (sketch 043's mid-word cut). This bug (chevron overflowing the
column at 390px) is a second, horizontal-axis manifestation of the same
underlying fragility, most plausibly triggered by a WebKit/Mobile-Safari-
specific float+justify line-box computation divergence from Blink (the only
engine available for direct reproduction here).
test: Reproduced the collapsed description card for the exact reported game
(Honey Buzz, id 113) plus two more real games (longest description "Mille
Fiori" id 193, shortest "Illusion" id 396) via headless Chromium (CDP,
`Emulation.setDeviceMetricsOverride` width=390, mobile=true), measuring
`getBoundingClientRect()` for `.pk-desc`, `.pk-desc-toggle`, `.pk-desc-toggle-icon`
across light/dark theme and DPR 2/3.
expecting: If the float-vs-justify technique is the root cause and is
engine-sensitive, Blink/Chromium reproduction may show correct (flush,
non-overflowing) positioning even though WebKit does not — this would be
consistent with (not proof against) the hypothesis.
next_action: n/a — investigation complete for find_root_cause_only mode;
return ROOT CAUSE FOUND with the plan's own pre-decided fallback as the
suggested fix direction.

## Symptoms

expected: Across 3 real games with short/long/unusually-titled descriptions, at
BOTH 390px and 1440px, in BOTH light and dark theme: (1) description text is
justified at both widths; (2) the clipped third line ends on a whole word — if
any combination cuts mid-word, the pre-decided CSS fallback recorded in
01.3-08-PLAN.md's planner_note should be applied rather than re-tuned or
re-sketched; (3) the "…" and the chevron read as vertically aligned on their
visible ink; (4) tapping the chevron on a phone-width viewport expands/
collapses reliably across several round trips.
actual: User reports (with screenshot, game "Honey Buzz" at 390px): "this
fails. See how the chevron isn't inside the text limits" — the chevron sits
outside/overflowing the right edge of the description text column instead of
being contained within it, immediately after the truncated "…".
errors: None reported
reproduction: Test 4 in UAT — open the "Honey Buzz" game detail page (or
similar) at 390px viewport width, look at the collapsed description card's
third line, where "…" and the toggle chevron appear.
started: Discovered during UAT of Phase 01.3. Plan 01.3-08 implemented the
description justify/clamp/toggle work; its Task 3 human-check (mid-word-cut
risk, ink alignment, chevron/toggle round-trip across 6 viewport/theme/content
combinations) was deferred to end-of-phase UAT per `workflow.human_verify_mode:
end-of-phase` (recorded as WINDOWS.md #19) — i.e. this exact visual check was
never actually performed before UAT surfaced this bug.

## Eliminated

- hypothesis: "A long unbreakable word in the description forces `overflow-wrap:
  normal` to let content overflow past the clamped box's right edge."
  evidence: Honey Buzz's description (1381 chars, id 113) contains no unusually
  long tokens; two additional real games (longest description in the DB at
  3868 chars — Mille Fiori id 193 — and a very short one at 229 chars —
  Illusion id 396) were also tested and none show horizontal overflow. A
  long-word overflow would also be clipped by `.pk-desc.is-clamped`'s
  `overflow: hidden`, not rendered visibly "outside" the box, which
  contradicts the reported symptom.
  timestamp: 2026-08-31T19:20:00Z
- hypothesis: "The hero-chevron-down icon's Tailwind-generated default size
  (from the heroicons plugin, a `@layer utilities` rule) silently wins over
  `.pk-desc-toggle-icon`'s explicit `width:12px;height:12px`, rendering the
  icon larger than intended and pushing it past the column edge."
  evidence: `app.css`'s own top-of-file comment (lines 12-39, written during a
  prior debug session `G-01.2-5-buybox-layout.md`) documents that every
  `.pk-*` rule in this file is unlayered and therefore ALWAYS wins over any
  Tailwind `@layer utilities` rule regardless of source order or specificity
  — the heroicons plugin utility cannot be overriding `.pk-desc-toggle-icon`.
  Direct DOM measurement also confirms the icon renders at exactly 12x12px
  (`icon.width/height` in CDP measurement = 12).
  timestamp: 2026-08-31T19:22:00Z
- hypothesis: "The `<p>`/flex-item interaction gives `.pk-desc` a `min-width:
  auto` wider than its flex container, pushing the whole paragraph (and its
  flush-right float) past the column's right edge."
  evidence: Direct measurement shows `desc.width` == `textCol.width` ==
  `shell.width` (421px at 500px viewport, 362px at 390px viewport) with no
  `document.documentElement.scrollWidth > window.innerWidth` in any tested
  case — the flex item is not overflowing its container.
  timestamp: 2026-08-31T19:24:00Z
- hypothesis: "The invisible `::before` touch-target expansion (`inset:
  -13px`) is what the user perceives as the chevron sitting outside the
  column."
  evidence: `::before` has `content: ''` and no background/border — it paints
  nothing visible, so it cannot be the reported visible overflow, even though
  its own box (toggle.right + 13px) does come within ~1px of the 390px
  viewport edge in the measured case.
  timestamp: 2026-08-31T19:26:00Z

## Evidence

- timestamp: 2026-08-31T19:05:00Z
  checked: 01.3-08-PLAN.md `<planner_note>` and 01.3-08-SUMMARY.md
  found: The plan explicitly pre-acknowledges the float+justify+clamp
  technique "has no native clean-cut guarantee and was observed cutting
  mid-word when composed at a different frame width (sketch 043)" and
  pre-authors a fallback (revert `.pk-desc.is-clamped` to
  `-webkit-line-clamp: 3` and move `.pk-desc-toggle` to an always-trailing-
  sibling position, dropping the float). The SUMMARY confirms Task 3's human
  visual check (which would have caught exactly this class of bug) was
  **deferred to end-of-phase UAT** and never actually performed by the
  executor (no browser tool available) — recorded as WINDOWS.md entry #19.
  implication: This bug class was explicitly anticipated and a fix was
  pre-authored, but the verification step that would have caught it before
  UAT was structurally skipped.
- timestamp: 2026-08-31T19:10:00Z
  checked: `lib/pukllay_club_web/live/catalog_live/show.ex` lines 542-573 and
  `assets/css/app.css` lines 3090-3225 (the `.pk-desc-shell` /
  `.pk-desc` / `.pk-desc.is-clamped` / `.pk-desc-toggle` family)
  found: Collapsed-state markup renders `.pk-desc-toggle` as the FIRST CHILD
  of `<p class="pk-desc is-clamped">`, floated right (`float: right; clear:
  right; margin-top: calc(2 * 1.5em)`) so the first two lines render
  full-width and only the (clamped) 3rd line wraps around it. `text-align:
  justify; text-justify: inter-word` is unconditional on `.pk-desc`.
  implication: The chevron's horizontal position depends entirely on the
  browser correctly excluding the float from the 3rd line's justify-width
  computation — exactly the interaction the plan's fallback note exists for.
- timestamp: 2026-08-31T19:15:00Z
  checked: Live reproduction via headless Chromium (CDP `Page.navigate` +
  `Emulation.setDeviceMetricsOverride` width=390 mobile=true) against the
  actual running dev server (`localhost:4000/juegos/113`, game "Honey Buzz",
  exact game named in the bug report), then `getBoundingClientRect()` on
  `.pk-text-col`, `.pk-desc`, `.pk-desc-toggle`, `.pk-desc-toggle-icon`.
  found: At exactly 390px viewport width: `textCol.right` = `shell.right` =
  `desc.right` = `toggle.right` = 376px (all identical); `icon.right` = 373px
  (inside the toggle box); `document.documentElement.scrollWidth` (390) ==
  `window.innerWidth` (390), i.e. **zero horizontal overflow measured**. A
  visual screenshot (light theme) confirms the chevron renders flush at the
  same right edge as the poster image above it, not overflowing.
  implication: In Blink/Chromium, at the exact viewport width and exact game
  from the bug report, the CSS renders correctly — the chevron does NOT sit
  outside the column. This is strong evidence the failure is not a static/
  deterministic Blink-reproducible layout bug.
- timestamp: 2026-08-31T19:27:00Z
  checked: Repeated the same measurement for 2 additional real games (longest
  description in DB, "Mille Fiori" id 193, 3868 chars; shortest usable,
  "Illusion" id 396, 229 chars), plus dark theme + `deviceScaleFactor: 3`
  (iPhone-typical DPR) for Honey Buzz.
  found: Identical result in every combination — `toggleRight - descRight ==
  0` in all cases, no horizontal overflow, chevron always flush at the
  column's right edge.
  implication: The absence of overflow is not content-length-dependent, not
  theme-dependent, and not DPR-dependent within Blink. This narrows the
  remaining explanation almost entirely to a rendering-engine difference
  (most plausibly WebKit/Mobile Safari) rather than a deterministic CSS logic
  error visible to any standards-compliant engine.
- timestamp: 2026-08-31T19:28:00Z
  checked: 01.3-08-PLAN.md Task 2's own read_first context — sketch 042's
  round 17 crash note, quoted verbatim in the CSS comment above
  `.pk-desc.is-clamped`
  found: This exact feature (an interactive `<button>` nested inside a
  clamped `<p>`) already caused one WebKit-specific rendering peculiarity
  during design exploration ("the icon disappeared and the click hit-area
  spread across the whole clamped block" under `-webkit-line-clamp`/
  `-webkit-box-orient`), which is why the implementation switched away from
  `-webkit-line-clamp` to `max-height` + `overflow: hidden` for the clip
  mechanism. The FLOAT positioning of the toggle itself, however, was kept
  from that same sketch round and was never verified against a live WebKit
  engine post-implementation.
  implication: There is direct precedent, in this exact codebase, of this
  exact nested-button-in-paragraph pattern behaving differently in WebKit
  than in the engine used for local dev verification (Chromium/Blink).

## Resolution

root_cause: "The `.pk-desc-toggle` expand/collapse chevron is positioned with
`float: right` inside a `text-align: justify` paragraph as the mechanism for
keeping it flush against the clamped 3rd line's right edge. This float+
justify interaction on a clipped line is a technique the implementing plan's
own reference documentation already identified as lacking a 'native clean-cut
guarantee' and known to render differently across frame widths (previously a
vertical/mid-word-cut symptom; here, at 390px, a horizontal chevron-overflow
symptom of the same underlying fragility). The specific human visual check
(01.3-08-PLAN.md Task 3, covering exactly '390px... chevron... vertically
aligned... reads as part of the text') that should have caught this was
deferred to end-of-phase UAT per this project's `human_verify_mode: end-of-
phase` config and was never actually performed before this UAT pass —
confirmed via `01.3-08-SUMMARY.md`'s own `human_judgment: true` /
`verification: []` entry for coverage id D6. Direct reproduction in headless
Chromium/Blink (the only engine available in this environment), against the
exact reported game and viewport width plus two additional real games across
both themes and two device-pixel-ratios, shows ZERO measured overflow
(`toggle.right == desc.right` in every case) — meaning this is very likely an
engine-specific rendering divergence (most plausibly WebKit/Mobile Safari,
consistent with this exact nested-button-in-clamped-paragraph pattern already
having hit one other WebKit-specific rendering quirk during design, per
sketch 042 round 17) rather than a deterministic bug that would reproduce in
any standards-compliant browser."
fix: (not applied — find_root_cause_only mode)
verification: (not applicable — find_root_cause_only mode)
files_changed: []
