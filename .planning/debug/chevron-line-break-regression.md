# Debug Session: G-01.3-6 — Chevron drops to its own line below clamped text

**Status:** diagnosed
**Phase:** 01.3-game-detail-layout-content-accuracy
**Reported:** Real iOS/Mobile-Safari device UAT, 390px, "7 Wonders Duel" description card — chevron
sits inside the text column (G-01.3-4 fixed the horizontal overflow) but renders on its own line
below the clamped 3rd line of text, instead of trailing that line next to the "…".

## Root cause

`.pk-desc-toggle` is positioned solely by `align-self: flex-end` inside `.pk-desc-shell`, a
column-direction flex container (`display:flex; flex-direction:column`) — `app.css:3096-3099`. In
a column flex container the main axis is vertical, so each child (the clamped `<p>` and the
`<button>`) gets its own row; `align-self` only affects the cross axis (horizontal), so it can push
the button flush right but cannot pull it up to share the paragraph's last visible line. The button
therefore always renders as a full new block-level row below the entire clamped paragraph box.

This is a direct, foreseeable gap left by the 01.3-10 fix (see `.planning/debug/resolved/
chevron-outside-text-column.md`): that fix correctly solved the *horizontal* overflow bug by
pulling the toggle out to a DOM sibling and dropping `float`, but the replacement mechanism
(flex-column + `align-self`) only re-solved the horizontal axis — it never re-established
vertical/inline trailing placement, which the old (rejected) float mechanism used to provide for
free.

## Artifacts

- `assets/css/app.css:3096-3099` (`.pk-desc-shell`) — `flex-direction:column` forces every child
  onto its own row; no positioning context for an overlay approach.
- `assets/css/app.css:3159-3163` (`.pk-desc-toggle`) — `align-self:flex-end` is the *only*
  positioning declaration; cross-axis only.
- `assets/css/app.css:3136-3142` (`.pk-desc.is-clamped`) — `-webkit-line-clamp:3` gives a
  deterministic box height (3 × line-height, `overflow:hidden`, no padding) a fix can anchor
  against.
- `lib/pukllay_club_web/live/catalog_live/show.ex:546-570` — toggle is a true DOM sibling of
  `<p id="game-description">`, never nested. Must stay that way (G-01.3-4's structural guarantee).
- `test/pukllay_club_web/live/catalog_show_test.exs:806-824` — requires literal `align-self:
  flex-end;` in the toggle rule and forbids `float:` / `calc(N * 1.5em)` line-height margins.
- `test/pukllay_club_web/live/catalog_show_test.exs:881-912` — scans the whole `.pk-desc*` family
  for `float:`.
- `test/pukllay_club_web/live/catalog_show_test.exs:829-858` — DOM containment test (unaffected by
  CSS positioning changes).
- **Coverage gap:** no test measures actual rendered geometry/bounding boxes — all `.pk-desc*`
  tests are DOM-structure or literal-CSS-source checks, which is why this shipped past CI (mirrors
  G-01.3-4, which also needed an ad hoc CDP measurement to catch).

## Recommended fix

Keep the DOM structure unchanged (button stays a sibling, never nested). Change only the
collapsed-state positioning mechanism from flex-column/`align-self` to an absolute-position overlay
anchored to the paragraph's own box:

1. Add `position: relative;` to `.pk-desc-shell`.
2. Add a collapsed-state-only override scoped via the existing `.is-expanded` class:
   `.pk-desc-shell:not(.is-expanded) .pk-desc-toggle { position: absolute; bottom: 0; right: 0; }`
3. Reserve horizontal space on the clamped paragraph so text/ellipsis doesn't render under the
   button: add `padding-right` to `.pk-desc.is-clamped` sized to the chevron's visual footprint
   plus a small gap (tune against the actual icon, not the larger touch target).
4. Leave the **expanded** state untouched (flex column + `align-self:flex-end`, block-level below
   full text) — bug is collapsed-state only. Keep `align-self: flex-end;` as the base/expanded rule
   so the existing test at line 806-824 still finds it; the `:not(.is-expanded)` override wins for
   collapsed state.
5. Do NOT use `float` (forbidden, and the documented source of G-01.3-4's engine divergence) and do
   NOT use a line-height-derived margin pull-up (same documented fragility).

Verify at 390px and 1440px, both themes, short/long descriptions (reuse Honey Buzz id 113, Mille
Fiori id 193, Illusion id 396 from the G-01.3-4 debug session) — check the reserved `padding-right`
doesn't create an awkward gap on lines 1-2 or let a near-full-width 3rd line collide with the
button. Verify expanded→collapsed round-trip doesn't jump/flicker from the state-conditional
`position` switch. Re-verify on a real iOS/Mobile-Safari device before closing — this class of bug
has already diverged from Blink/DevTools emulation once (G-01.3-4).

## Missing (next actions)

1. Write the CSS changes above (not applied yet — diagnosis only).
2. Pick and record the exact `padding-right` value via visual QA at 390px/1440px in both themes
   against the three reference games; consider a CSS custom property.
3. Update `test/pukllay_club_web/live/catalog_show_test.exs`:
   - Confirm the line 806-824 assertions still pass, or deliberately rewrite them if `align-self`'s
     role changes.
   - Re-check/extend the float scan (line 881-912) to cover any new selectors.
   - Add a geometry-based regression test (bounding-box check) — the actual coverage gap that let
     both G-01.3-4 and G-01.3-6 ship past CI.
4. Re-verify on a real iOS/Mobile-Safari device before closing the gap.
5. Update app.css's inline comments (block at 3090-3158 narrating 01.3-10's rationale) to record
   this follow-up and retire the stale "align-self is the ONLY thing positioning it" claim for the
   collapsed state.
