---
status: complete
phase: 01-catalog-v1
source: [01-10-SUMMARY.md, 01-11-SUMMARY.md, 01-12-SUMMARY.md]
started: 2026-08-19T20:20:00Z
updated: 2026-08-19T20:26:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Desktop hover-intent game preview
expected: On desktop, hover over a game card in any shelf or the main grid for about 300ms. A
preview portal appears positioned outside the scrolling rail (not clipped or cut off by the
shelf's edges), showing the poster, a facts row, title, description, and a 'Ver detalles' CTA.
Moving the mouse away hides the preview.
result: pass

### 2. Mobile full-screen game sheet
expected: On a narrow/mobile viewport, tap a game card. A full-screen sheet slides up showing the
same preview content, with a close button and drag handle. Pressing Escape, tapping the backdrop,
or tapping close all dismiss it. Background scrolling is locked while the sheet is open, and focus
returns to the card after closing.
result: pass

### 3. Carousel shelves read as distinct, contained rows (re-verifies G-01-4)
expected: Load `/` unfiltered and scroll through the shelves. Each shelf shows a soft edge-fade at
both ends of its row (not an abrupt cutoff), the row heading and the rail share the same left/right
gutter as the page header, and scrolling within a shelf moves only that row's cards — it does not
scroll the whole page/window horizontally. This replaces the old daisyUI carousel component
previously reported (G-01-4) as reading like a single vertical list scrolling at the window level;
confirm that complaint no longer reproduces.
result: pass

### 4. Narrow-viewport shelf density
expected: At a narrow (~335-480px) viewport, shelves show roughly 3.5 cards visible per row (cards
partially cut off at the edge as a 'peek' cue), with a narrower edge-fade than the peek width.
Touch-scrolling a shelf feels contained (no page-level swipe hijacking).
result: pass

### 5. Sticky header with scroll tint
expected: Scroll down the page. The header stays pinned to the top of the viewport (sticky) and
visibly tints to a flat, translucent background once you've scrolled past the top — no blur
effect, just a color/opacity change.
result: pass

### 6. Mobile category chip navigation
expected: At a narrow (<480px) viewport, the header's nav links are replaced by a
horizontally-scrollable row of category chips (one per shelf), each large enough to comfortably
tap (~44px). Tapping a chip scrolls/navigates to that shelf's section. As you scroll manually
through the shelves, the chip for the currently-visible shelf should highlight (active state) —
note if it doesn't, since this specific behavior couldn't be verified in prior automated checks.
result: pass

### 7. Resting card shows poster + title only (D1, 01-10)
expected: Resting card shows only poster + single-line title, no weight badge/tags/mechanics/CTA.
result: pass
source: automated
coverage_id: D1

### 8. Difficulty shown as dots + plain-Spanish label (D4, 01-10)
expected: Difficulty shown as 3 dots + plain-Spanish weight-band label, no raw age number anywhere.
result: pass
source: automated
coverage_id: D4

### 9. Preview CTA navigates to detail page (D5, 01-10)
expected: Ver detalles from either surface navigates to /juegos/:id.
result: pass
source: automated
coverage_id: D5

### 10. Ver todo tile applies shelf selection to main grid (D2, 01-11)
expected: Ver todo tile applies each shelf's own selection to the main grid with pagination reset.
result: pass
source: automated
coverage_id: D2

### 11. Shelf anchors and header search resolve correctly (D2, 01-12)
expected: Four shelf anchor links + search box in the header, resolving to real section ids,
byte-identical detail-page header when not sticky.
result: pass
source: automated
coverage_id: D2

### 12. Design-system skill records the pk-* layer (D4, 01-12)
expected: Design-system skill records the pk-* layer, its rules, and the full component inventory.
result: pass
source: automated
coverage_id: D4

## Summary

total: 12
passed: 12
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-01-4
  truth: "Carousel sections are visually distinct via heading + one-line subtitle, and each row
    scrolls independently rather than the whole page/window scrolling horizontally"
  status: resolved
  reason: "User reported (prior UAT round): This looks more like a simple vertical list without
    clear affordance that there are multiple carousels. Also the horizontal scrolling is happening
    at window level, not individual carousel."
  severity: major
  test: 3
  resolved_by: "01-11-PLAN.md (full-bleed edge-fade .pk-shelf/.pk-rail-wrap/.pk-rail layer,
    replacing daisyUI's .carousel)"
  resolved_at: 2026-08-19
  root_cause: "Superseded — the original diagnosis (.planning/debug/G-01-4-carousel-affordance.md)
    targeted the pre-01-11 daisyUI `.carousel` markup's missing `w-full`. 01-11 replaced
    `.carousel` entirely with a custom pk-rail layer specifically because daisyUI's `.carousel`
    'hid the scrollbar with no cue.' Confirmed resolved via re-test in Test 3 of this session."
  artifacts: []
  missing: []
  debug_session: ".planning/debug/G-01-4-carousel-affordance.md (superseded by 01-11 rail rework)"
