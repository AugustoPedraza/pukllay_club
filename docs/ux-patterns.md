# UX pattern reference

This is a vendor-neutral reference for common UX questions, built by reading eight public
design-system and usability sources. Every claim below is sourced from a page listed in the
source ledger and actually fetched during this research pass — nothing here is filled in from
memory. This doc does not override `.claude/skills/ui-design-system/SKILL.md` where the two
conflict; that skill's daisyUI-specific rules win for PukllayClub's own UI work.

## Source ledger

| # | Source | Pages read | Status |
|---|--------|------------|--------|
| 1 | Shopify Polaris | | |
| 2 | Base Web | | |
| 3 | Atlassian Design System | | |
| 4 | GOV.UK Design System | | |
| 5 | Carbon Design System | | |
| 6 | Material 3 | https://m3.material.io/styles/typography/type-scale-tokens <br> https://m3.material.io/foundations/interaction/states/state-layers <br> https://m3.material.io/foundations/layout/breakpoints <br> https://m3.material.io/foundations/layout/canonical-examples | read |
| 7 | Apple HIG | | |
| 8 | NN/g web usability | | |

## A. Information hierarchy

### A1. Typographic scale — how many distinct sizes/weights a screen should use

- **Default:** Use one type scale containing a small, named set of type styles (Material 3 defines
  15 baseline styles from Display Large to Label Small) and select only the subset a given product
  actually needs — no single product should use every style in the scale.
- **Flips when:** A style set is being extended for emphasis (Material 3's "emphasized" variants,
  a heavier-weight companion to each baseline style) — those are meant to be layered on top of the
  baseline scale for bold/selection states, not to replace it.
- **Why:** A fixed, named scale keeps typography consistent across a product; ad hoc one-off sizes
  erode that consistency.
- **Source:** [Material 3 — Typography](https://m3.material.io/styles/typography/type-scale-tokens)

### A2. Signaling importance without adding size (weight, color, position, whitespace)

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### A3. Ordering data in a record view — what belongs above the fold

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### A4. Table column priority and what to drop first when space runs out

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### A5. Numeric and tabular data presentation — alignment, units, precision

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

## B. Component interaction

### B6. Master/detail — split pane vs drill-down vs modal, and the breakpoint that flips it

- **Default:** Use a single-pane, drill-down layout at compact and medium window widths (under
  840dp) — Material 3 states "compact and medium breakpoints: a single pane works best." Above
  that, switch to a two-pane list-detail layout, dividing the window into a list pane and a detail
  pane shown side by side.
- **Flips when:** The window reaches an expanded breakpoint (840dp+), where "two panes are
  recommended"; at extra-large (1600dp+) a third pane can be added (e.g. list, detail, and a
  supporting pane).
- **Why:** Cramming two panes into a narrow window forces low information density and reduces
  usability; splitting only becomes worthwhile once there is enough width for both panes to carry
  real content simultaneously.
- **Source:** [Material 3 — Breakpoints](https://m3.material.io/foundations/layout/breakpoints),
  [Material 3 — Canonical layout examples (list-detail)](https://m3.material.io/foundations/layout/canonical-examples)

### B7. Long lists — pagination vs infinite scroll vs load-more

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### B8. Navigation — sidebar vs top nav vs bottom bar; depth limits; where "back" goes

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### B9. Carousels — when they're justified at all, and what they must have if used

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### B10. Create/edit — inline vs modal vs full page

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### B11. Destructive actions — confirmation vs undo toast

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### B12. Form validation — timing, placement, wording

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### B13. Async feedback — spinner vs skeleton vs optimistic

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### B14. Filter and search on a list

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### B15. Multi-step flows — wizard vs single long form

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

## C. Affordance

### C16. What makes a control read as interactive without relying on hover

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### C17. Disabled vs hidden vs enabled-with-error, and which to choose

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### C18. Signaling that a click will navigate away, open a modal, or mutate data

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### C19. Icon-only controls — when acceptable, and labeling requirements

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### C20. Minimum hit target sizes and spacing between adjacent targets

- **Default:** Size the interactive/touch target to 48dp even when the visible control (icon,
  state layer) is drawn smaller — Material 3 states "the size of state layers is 40dp while the
  interactive target size is 48dp," i.e. the tappable area extends beyond the visible element.
- **Flips when:** A control sits in a dense desktop/pointer-driven layout where the mouse's
  higher pointing precision makes the full mobile touch-target minimum less necessary.
- **Why:** A visible control smaller than the finger's effective contact area causes mis-taps;
  padding the invisible hit area out to a consistent minimum fixes that without changing the
  control's visual size.
- **Source:** [Material 3 — States](https://m3.material.io/foundations/interaction/states/state-layers)

## D. Density

### D21. Progressive disclosure — what to hide behind expansion, what must stay visible

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### D22. Evidence on how many primary actions a screen should offer

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### D23. When a dashboard should be split into multiple pages

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

## E. Responsive / mobile / PWA

### E24. Breakpoint strategy and mobile-first ordering

- **Default:** Design against five named breakpoints keyed to available width rather than specific
  devices — Material 3's compact (under 600dp), medium (600-839dp), expanded (840-1199dp), large
  (1200-1599dp), and extra-large (1600dp+) — and decide per breakpoint transition what to reveal,
  divide, resize, reposition, or swap.
  Design for the compact breakpoint first, then progressively reveal/add panes and content as width
  grows, since "products should automatically adapt to any breakpoint" rather than target a fixed
  device list.
- **Flips when:** Available window height (not just width) is unusually constrained, e.g. a
  landscape phone or a resizable desktop window — Material 3 notes height breakpoints exist but
  are rarely needed "since most layouts contain vertically scrolling content."
- **Why:** Window size is dynamic (multi-window mode, foldables, resizing) and doesn't map 1:1 to
  a physical device, so keying layout logic to specific devices breaks as soon as the assumption
  doesn't hold.
- **Source:** [Material 3 — Breakpoints](https://m3.material.io/foundations/layout/breakpoints)

### E25. Touch vs pointer — what breaks when hover doesn't exist

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### E26. Safe areas, notches, on-screen keyboard displacing viewport

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### E27. PWA: offline state, install prompt, splash/theme color, standalone-mode differences from browser tab

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD
