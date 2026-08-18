# UX pattern reference

This is a vendor-neutral reference for common UX questions, built by reading eight public
design-system and usability sources. Every claim below is sourced from a page listed in the
source ledger and actually fetched during this research pass — nothing here is filled in from
memory. This doc does not override `.claude/skills/ui-design-system/SKILL.md` where the two
conflict; that skill's daisyUI-specific rules win for PukllayClub's own UI work.

## Source ledger

| # | Source | Pages read | Status |
|---|--------|------------|--------|
| 1 | Shopify Polaris | https://polaris.shopify.com <br> https://polaris.shopify.com/components/data-table <br> https://polaris.shopify.com/patterns/creating-and-editing | unreachable |
| 2 | Base Web | https://baseweb.design <br> https://baseweb.design/components/form-control/ <br> https://baseweb.design/components/spinner/ <br> https://baseweb.design/components/skeleton/ | unreachable |
| 3 | Atlassian Design System | https://atlassian.design <br> https://atlassian.design/foundations/content <br> https://atlassian.design/foundations/content/designing-messages <br> https://atlassian.design/foundations/content/designing-messages/error-messages <br> https://atlassian.design/components/inline-edit/examples | read |
| 4 | GOV.UK Design System | | |
| 5 | Carbon Design System | https://carbondesignsystem.com/elements/typography/overview/ <br> https://carbondesignsystem.com/components/pagination/usage/ <br> https://carbondesignsystem.com/components/data-table/usage/ <br> https://carbondesignsystem.com/guidelines/content/action-labels/ | read |
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

- **Default:** Use font weight and color, not size, as the primary secondary signal for hierarchy:
  Carbon's guidance is that "a bold weight will always have more emphasis than a lighter weight
  font of the same size," and to reserve color for a specific job — neutral color in running text,
  a single brand color reserved for primary actions/links, and a muted secondary color for
  secondary actions.
- **Flips when:** A lighter-weight style is set at a significantly larger size than a bold one —
  Carbon states the larger light-weight text can "rank hierarchically higher than a bold font" in
  that case, so size still dominates weight once the size gap is large enough.
- **Why:** Reserving a small, consistent set of weight/color signals (rather than inventing new
  sizes) keeps the type scale from sprawling while still giving designers a way to differentiate
  emphasis.
- **Source:** [Carbon — Typography overview](https://carbondesignsystem.com/elements/typography/overview/)

### A3. Ordering data in a record view — what belongs above the fold

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### A4. Table column priority and what to drop first when space runs out

- **Default:** Don't drop the column — wrap and truncate instead: Carbon's stated rule is "in cases
  where a column title is too long, wrap the text to two lines and then truncate the rest of the
  text. The full text should be shown in a tooltip on hover." Column titles should also be kept to
  one or two words in the first place.
- **Flips when:** The table itself, not just a header label, is competing for horizontal space with
  other page content — Carbon's placement guidance is to give the data table the most width on the
  page and avoid nesting it in smaller containers, i.e. resolve the space problem at the page-layout
  level before resorting to column truncation.
- **Why:** Truncating with a hover tooltip keeps every column present and scannable while still
  fitting tight widths; dropping columns silently removes information the user may have been
  relying on without any indication it's missing.
- **Source:** [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/)

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

- **Default:** Prefer discrete pagination attached below the list/table it paginates. Carbon's
  stated when-to-use cases are: "when it could take a considerable amount of time to load the
  available data at once or in a scrolling view," when there's too much data to show in one view,
  and to give users control over how much they see per page.
- **Flips when:** The content is a single continuous feed rather than a table/list with discrete
  records — Carbon's own component distinguishes a data-table-attached "pagination" variant from a
  page-level "pagination nav" variant, implying the on-page-content case (an editorial feed) can
  reasonably use a different navigation shape than a data table can.
- **Why:** Pagination gives users a stable, bookmarkable position and predictable load cost per
  page, at the expense of an extra click; unlimited scrolling optimizes for skimming a feed at the
  cost of losing a fixed position.
- **Source:** [Carbon — Pagination usage](https://carbondesignsystem.com/components/pagination/usage/)

### B8. Navigation — sidebar vs top nav vs bottom bar; depth limits; where "back" goes

- **Default:** Key the navigation shape to breakpoint, not a fixed choice: Material 3's swappable
  component table specifies a bottom **navigation bar** at compact width, a **collapsed
  navigation rail** at medium and expanded widths, and a **standard (open) expanded navigation
  rail** at large/extra-large widths — "swap a navigation bar in a compact layout for a navigation
  rail in a medium or expanded layout" is called out as the recommended ("Do") transition.
- **Flips when:** The window narrows back down past that breakpoint — the same swap runs in
  reverse, collapsing the rail back to a bottom bar; Material 3 warns against swapping between
  components that aren't functionally equivalent (e.g. "don't swap a button for a chip" as the
  general version of this caution) so the nav-bar/nav-rail swap works because both serve the exact
  same top-level-navigation purpose.
- **Why:** A bottom bar fits thumb reach on a narrow phone but wastes vertical space once there's
  enough width for a persistent side rail; keying the swap to breakpoint rather than device type
  keeps it correct even as a window is resized or a device rotates.
- **Source:** [Material 3 — Breakpoints](https://m3.material.io/foundations/layout/breakpoints)

### B9. Carousels — when they're justified at all, and what they must have if used

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### B10. Create/edit — inline vs modal vs full page

- **Default:** Use inline edit for a single field edited in place — Atlassian: "an inline edit
  displays a custom input component that switches between reading and editing on the same page,"
  with no navigation or overlay involved. Use a modal dialog when the edit is a short, focused task
  that still belongs to the current context: "use modal dialogs to present a short-term task the
  user needs to perform," displayed "in a layer above the page."
- **Flips when:** The create/edit task has enough fields or steps that it stops being "short-term"
  — at that point neither inline (too cramped for many fields) nor a modal (bounded by viewport,
  and Atlassian's own component notes several overlay components as "Caution"/deprecated for
  heavier use) fits, and a full page is the fallback for a genuinely multi-field or multi-step edit.
- **Why:** Inline edit keeps the user's place in the surrounding context for a trivial one-field
  change; a modal borrows a layer above the page for a bounded task without a full navigation; a
  full page is needed once the task is too large to reasonably float above existing content.
- **Source:** [Atlassian — Inline edit](https://atlassian.design/components/inline-edit/examples),
  [Atlassian — Designing messages](https://atlassian.design/foundations/content/designing-messages)

### B11. Destructive actions — confirmation vs undo toast

- **Default:** Warn before the action, using Atlassian's "warning message" type, defined as one
  that "gives advanced notice of a potential change that may result in loss of data or an error
  state" — i.e. a confirmation-style message shown before the destructive action commits, not
  after.
- **Flips when:** The message is reporting a change that has already happened rather than one
  that's about to happen — Atlassian draws this exact line: "an error message alerts people of a
  problem that has already occurred. By contrast, a warning message alerts people of a condition
  that might cause a problem in the future," which is the same distinction that separates a
  pre-action confirmation from a post-action undo toast.
- **Why:** For genuinely destructive, hard-to-reverse actions, warning before commit avoids ever
  entering the lost-data state; an undo toast only helps if the reversal window is reliably seen
  and used in time.
- **Source:** [Atlassian — Designing messages](https://atlassian.design/foundations/content/designing-messages)

### B12. Form validation — timing, placement, wording

- **Default:** Validate and message the error **after** the person has taken the action, not while
  they're still typing — Atlassian: "an error message... appears after someone has taken an
  action." Keep the message to 1-2 sentences stating the reason for the error and what to do next,
  in sentence case, without inventing a cause you don't actually know ("if you don't know the
  reason for an error, don't make one up — just say that something's gone wrong and offer a
  solution").
- **Flips when:** The condition is one that *might* cause a problem later rather than one that has
  already happened — that's a warning message, shown proactively, not an error shown reactively
  (see B11).
- **Why:** Messaging every keystroke as invalid mid-entry interrupts a still-in-progress action and
  reads as premature; validating on a completed action (blur, submit) matches when the user
  actually expects feedback.
- **Source:** [Atlassian — Error messages](https://atlassian.design/foundations/content/designing-messages/error-messages)

### B13. Async feedback — spinner vs skeleton vs optimistic

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

### B14. Filter and search on a list

- **Default:** Put search and filtering in a dedicated toolbar above the list/table, collapsed
  behind a search icon by default — Carbon: "a search field can be triggered through an icon button
  in the data table toolbar... the search is closed by default, and placed below the table title."
  Reserve the toolbar for global actions (search, complex filters, exporting) and cap it at five
  visible actions before moving the rest into an overflow menu.
- **Flips when:** Search is a primary, frequently-used entry point for that view rather than an
  occasional refinement — Carbon offers an "open search" variant that stays always-visible on the
  left of the table for exactly that case.
- **Why:** A collapsed-by-default search keeps the toolbar uncluttered for the common case, while
  still making the escape hatch (open search) available for lists where search is the primary task.
- **Source:** [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/)

### B15. Multi-step flows — wizard vs single long form

- **Default:** TBD
- **Flips when:** TBD
- **Why:** TBD
- **Source:** TBD

## C. Affordance

### C16. What makes a control read as interactive without relying on hover

- **Default:** Show the control's icon persistently rather than only on hover, when the device
  can't reliably produce a hover state — Carbon's data table explicitly detects this: "for mobile
  and touch devices the data table will detect if the user agent supports hover-over and persist
  the overflow menus even if the `overflowMenuOnHover` prop is enabled."
- **Flips when:** The pointer device genuinely supports hover (desktop/mouse) — Carbon's own
  default sort-icon behavior leans the other way there: "unsorted icons are only visible on hover,"
  used deliberately to reduce visual clutter when hover is a reliable signal.
- **Why:** Hover-only affordance is invisible on touch devices with no hover state at all, so a
  control that depends on it becomes undiscoverable; feature-detecting hover support and falling
  back to a persistent icon keeps the control discoverable everywhere.
- **Source:** [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/)

### C17. Disabled vs hidden vs enabled-with-error, and which to choose

- **Default:** Disable, don't hide, a control that's temporarily unavailable because of another
  active mode on the same screen — Carbon: "when batch mode is active, single action icons and
  overflow menus on the row should be disabled," rather than removed, while batch mode is on.
- **Flips when:** The control being unavailable is a permanent condition of the current context
  rather than a temporary mode (e.g. a feature the user's role can never access) — a persistently
  irrelevant control is better hidden than shown disabled forever, since a disabled control implies
  the state is reachable.
- **Why:** Disabling keeps the control's position stable and communicates "not right now, but this
  exists," which matches a mode that will end shortly (exiting batch mode); hiding is reserved for
  controls that are never applicable in this context, where showing a permanently-disabled control
  would just be clutter.
- **Source:** [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/)

### C18. Signaling that a click will navigate away, open a modal, or mutate data

- **Default:** Use a standardized, specific verb as the label itself rather than a generic one —
  Carbon's action-label glossary assigns each verb an exact, non-overlapping meaning, e.g. "Delete"
  = "destroys an existing object so that it no longer exists," "Close" = "closes the current page
  or window," "Apply" = "saves changes without closing the dialog." The label is the affordance
  signal; a user who knows the house vocabulary can predict the consequence category (navigate,
  overlay-dismiss, or mutate) before clicking.
- **Flips when:** The action has a genuinely destructive or hard-to-reverse consequence beyond what
  the verb alone conveys — Carbon calls that out specifically for Cancel: "warn the user of any
  possible negative consequences of stopping an action from progressing, such as data corruption,"
  i.e. add an explicit warning on top of the verb rather than relying on word choice alone.
- **Why:** A shared, precise verb vocabulary lets users build a mental model of what each label does
  across the whole product, instead of having to infer intent from context on every screen.
- **Source:** [Carbon — Action labels](https://carbondesignsystem.com/guidelines/content/action-labels/)

### C19. Icon-only controls — when acceptable, and labeling requirements

- **Default:** Icon-only buttons are acceptable for row-level actions when there are few of them —
  Carbon: "when the overflow menu contains fewer than three options, keep the actions inline as
  icon buttons instead. This approach reduces a click" versus opening a menu first.
- **Flips when:** There are three or more possible actions on that row — at that point Carbon
  switches back to a labeled overflow menu rather than three-plus bare icons, since an icon row
  that wide stops being reliably scannable/identifiable at a glance.
- **Why:** A small number of icon-only actions can stay recognizable from icon shape alone and
  saves a click; past a small count, unlabeled icons compete for identification and a
  text-labeled menu is safer for the user to parse correctly.
- **Source:** [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/)

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

- **Default:** Keep the identifying/summary data in the always-visible row and put supplementary
  detail behind an expand control — Carbon's data table "expandable variant helps present large
  amounts of data in a small space. Users can expand and collapse row panels to reveal and hide
  additional information," while the column headers, sort state, and row-level actions stay on the
  always-visible row.
- **Flips when:** The hidden information is required to complete the primary task, not just
  supplementary — Carbon's own selection guidance keeps the row's action affordances (checkboxes,
  overflow menu) outside the collapsed panel specifically because those are needed without forcing
  an expand step first.
- **Why:** Hiding truly secondary detail behind expansion keeps the default view scannable at a
  glance; anything the user needs to act on the row for should not require an extra click to reveal.
- **Source:** [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/)

### D22. Evidence on how many primary actions a screen should offer

- **Default:** Cap a toolbar-style action group at a small fixed number and move the rest to
  overflow — Carbon's stated rule for the data table toolbar: "include up to five actions within
  the table toolbar. More actions can be made available through an overflow menu, combo button, or
  similar components."
- **Flips when:** The actions are row-level rather than global — there Carbon's cap is tighter
  still: fewer than three inline icon actions per row (see C19) before switching to a menu.
- **Why:** A capped, small action count keeps the primary-action area scannable and prevents action
  sprawl from competing with the content itself for attention; overflow gives less-used actions a
  home without inflating the visible set.
- **Source:** [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/)

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
