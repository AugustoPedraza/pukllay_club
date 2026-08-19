---
status: complete
phase: 01-catalog-v1
source: [01-VERIFICATION.md]
started: 2026-08-18T22:20:00Z
updated: 2026-08-18T22:42:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Weight-band badge no longer overlaps the title at narrow/mobile widths (G-01-2)
expected: At a narrow/mobile viewport (<640px, 2-column grid), load `/` and confirm the weight-band
badge (e.g. 'Descubre el hobby') no longer overlaps the game title above it, and that its box
visibly grows rather than clipping when the label wraps to two lines. Badge text stays entirely
inside its own tinted box with no visual collision with the title.
result: pass

### 2. Card visual hierarchy — primary badge dominant over grouped secondary chips (G-01-6)
expected: On the same narrow viewport, confirm the weight-band badge reads as clearly the most
visually dominant chip on the card, with the editorial-hashtag row (capped at 2 + `+N`) and
mechanic-chip row (capped at 4 + `+N`) reading as one smaller, grouped secondary block beneath it
— three visually ranked tiers, not five flat, co-equal rows.
result: pass

### 3. Single focus ring on search box and sort dropdown (G-01-7)
expected: Tab into (or click) the search box and the sort dropdown; confirm each shows exactly one
visible focus indicator (a single darkened border), not two concentric near-black rectangles, and
that focus is still clearly visible (not silently removed).
result: pass

### 4. Carousel sections visually distinct, main grid titled (G-01-4)
expected: Load `/` unfiltered and scroll top to bottom. Confirm: (1) each of the 8 carousel shelves
is distinguishable from the next via its heading + one-line subtitle; (2) the 'Destacados del club'
row is visibly ranked above the others by color; (3) the main grid at the bottom reads as its own
titled section, not a trailing count line; (4) the two newly-authored subtitles ('La selección del
club…' and 'Las incorporaciones más nuevas…') read naturally in Spanish and match the club's voice
— they have not been through the vocabulary's existing review pass.
result: issue
reported: "This looks more like a simple vertical list without clear affordance that there are multiple carousels. Also the horizontal scrolling is happening at window level, not individual carousel."
severity: major

### 5. Carousel scroll controls and G-01-3 root-cause reclassification
expected: On a desktop-width browser, confirm each non-empty carousel row shows round prev/next
controls next to its heading, that clicking them scrolls the row, and that a row with only a couple
of games shows no controls at all. Then directly answer: was the originally-reported '~20 columns
forcing horizontal scroll' one of these carousel rails, or the `#games` grid at the bottom of the
page?
result: skipped
reason: "I don't understand this. skip for now"

### 6. Expansions excluded from "Recientemente añadidos", still searchable (G-01-5)
expected: Scroll to the 'Recientemente añadidos' shelf and confirm it shows only ordinary base
games, no titles ending in '(expa)', containing 'Expansión', or reading as promo miniatures. Then
search for a known expansion title (e.g. 'Wingspan Europa') and confirm it is still findable in the
main catalog — expansions must remain searchable, only excluded from this one shelf.
result: pass

### 7. Re-run previously-skipped Tests 3 and 4 (gallery swap, skeleton layout stability)
expected: Re-run UAT Test 3 (game detail page gallery swap, no-BGG-enrichment game rendering) and
Test 4 (loading-skeleton layout stability), both of which were skipped in the prior UAT session
because the CSP img-src bug (G-01-1) blocked all images at the time. Both should now run to
completion since G-01-1 was resolved in a prior session; no new regressions.
result: pass

## Summary

total: 7
passed: 5
issues: 1
pending: 0
skipped: 1
blocked: 0

## Gaps

- gap_id: G-01-4
  truth: "Carousel sections are visually distinct via heading + one-line subtitle, and each row scrolls independently rather than the whole page/window scrolling horizontally"
  status: failed
  reason: "User reported: This looks more like a simple vertical list without clear affordance that there are multiple carousels. Also the horizontal scrolling is happening at window level, not individual carousel."
  severity: major
  test: 4
  artifacts: []
  missing: []
