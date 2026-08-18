# UX pattern reference

This is a vendor-neutral reference for common UX questions, built by reading ten public
design-system and usability sources. Every claim below is sourced from a page listed in the
source ledger and actually fetched during this research pass — nothing here is filled in from
memory. This doc does not override `.claude/skills/ui-design-system/SKILL.md` where the two
conflict; that skill's daisyUI-specific rules win for PukllayClub's own UI work.

## Source ledger

| # | Source | Pages read | Status |
|---|--------|------------|--------|
| 1 | Shopify Polaris | https://polaris.shopify.com <br> https://polaris.shopify.com/components/data-table <br> https://polaris.shopify.com/patterns/creating-and-editing <br> https://polaris.shopify.com/patterns (retried this pass, HTTP 301 -> https://shopify.dev/docs/api/polaris) <br> https://polaris.shopify.com/components/layout-and-structure/empty-state (retried this pass, HTTP 301 -> https://shopify.dev/docs/api/polaris) | unreachable |
| 2 | Base Web | https://baseweb.design <br> https://baseweb.design/components/form-control/ <br> https://baseweb.design/components/spinner/ <br> https://baseweb.design/components/skeleton/ | unreachable |
| 3 | Atlassian Design System | https://atlassian.design <br> https://atlassian.design/foundations/content <br> https://atlassian.design/foundations/content/designing-messages <br> https://atlassian.design/foundations/content/designing-messages/error-messages <br> https://atlassian.design/components/inline-edit/examples | read |
| 4 | GOV.UK Design System | https://design-system.service.gov.uk (sitemap) <br> https://design-system.service.gov.uk/patterns/question-pages/ <br> https://design-system.service.gov.uk/components/table/ <br> https://design-system.service.gov.uk/patterns/complete-multiple-tasks/ <br> https://design-system.service.gov.uk/patterns/validation/ <br> https://design-system.service.gov.uk/components/pagination/ <br> https://design-system.service.gov.uk/components/button/ <br> https://design-system.service.gov.uk/patterns/check-answers/ | read |
| 5 | Carbon Design System | https://carbondesignsystem.com/elements/typography/overview/ <br> https://carbondesignsystem.com/components/pagination/usage/ <br> https://carbondesignsystem.com/components/data-table/usage/ <br> https://carbondesignsystem.com/guidelines/content/action-labels/ | read |
| 6 | Material 3 | https://m3.material.io/styles/typography/type-scale-tokens <br> https://m3.material.io/foundations/interaction/states/state-layers <br> https://m3.material.io/foundations/layout/breakpoints <br> https://m3.material.io/foundations/layout/canonical-examples | read |
| 7 | Apple HIG | https://developer.apple.com/design/human-interface-guidelines/layout <br> https://developer.apple.com/design/human-interface-guidelines/pointing-devices <br> https://developer.apple.com/design/human-interface-guidelines/buttons | read |
| 8 | NN/g web usability | https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content/ <br> https://www.nngroup.com/articles/designing-effective-carousels/ <br> https://www.nngroup.com/articles/skeleton-screens/ <br> https://www.nngroup.com/articles/mobile-navigation-patterns/ | read |
| 9 | Linear docs | https://linear.app/docs <br> https://linear.app/docs/select-issues | read |
| 10 | Microsoft Learn | https://learn.microsoft.com/en-us/windows/apps/design/controls/list-details | read |

**Attempted this pass and not usable:**
- Linear keyboard-shortcuts page: `https://linear.app/docs/keyboard-shortcuts` — HTTP 404.
- Microsoft Learn singular `list-detail` URL: `https://learn.microsoft.com/en-us/windows/apps/design/controls/list-detail` — HTTP 404.
- Gmail reading-pane support page: `https://support.google.com/mail/answer/187605` — HTTP 404 (redirects to an unrelated topic page).
- Pages that returned a title with no rendered body (client-rendered, JavaScript required, nothing to quote):
  `https://developer.apple.com/design/human-interface-guidelines/split-views`,
  `https://developer.apple.com/design/human-interface-guidelines/sidebars`, and
  `https://m3.material.io/components/navigation-bar/guidelines`.

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

- **Default:** Put the most important information first and format it to stand out, because
  eyetracking shows users default to scanning, not reading — NN/g's F-pattern research: "in the
  absence of any signals to guide the eye, they will choose the path of minimum effort and will
  spend most of their fixations close to where they start reading," concentrated at the top and
  left. Their stated antidotes: "include the most important points in the first two paragraphs,"
  use headings that front-load the information-bearing words, and bold/visually group the content
  that matters most.
- **Flips when:** The page has "strong cues to attract the eyes towards meaningful information" —
  NN/g is explicit that "the F-pattern is the default pattern when there are no strong cues," and
  that good formatting (headings, bold, visual grouping) is what breaks the default and lets users
  actually find content positioned lower on the page.
- **Why:** Users optimize their own cost/benefit ratio across the whole web, not just one page —
  they scan to get the gist fast rather than read every word, so whatever isn't visually prioritized
  in the natural top-left scan path risks being missed entirely, not just read later.
- **Source:** [NN/g — The F-Shaped Pattern of Reading on the Web](https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content/)

### A4. Table column priority and what to drop first when space runs out

- **Default:** Don't drop the column — wrap and truncate instead: Carbon's stated rule is "in
  cases where a column title is too long, wrap the text to two lines and then truncate the rest
  of the text. The full text should be shown in a tooltip on hover." Column titles should also be
  kept to one or two words in the first place.
- **Flips when:** The table itself, not just a header label, is competing for horizontal space
  with other page content — Carbon's placement guidance is to give the data table the most width
  on the page and avoid nesting it in smaller containers, i.e. resolve the space problem at the
  page-layout level before resorting to column truncation.
- **Why:** Truncating with a hover tooltip keeps every column present and scannable while still
  fitting tight widths; dropping columns silently removes information the user may have been
  relying on without any indication it's missing.
- **Source:** [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/)

### A5. Numeric and tabular data presentation — alignment, units, precision

- **Default:** Right-align numbers in table cells — GOV.UK: "when comparing columns of numbers,
  align the numbers to the right in table cells" (its `govuk-table__cell--numeric` modifier).
  Currency examples in the same component keep the unit symbol attached to the figure and a
  consistent decimal precision within a column (e.g. "£109.80 per week" / "£4,282.20"), rather
  than a separate units column.
- **Flips when:** The column is text-like even though it contains digits (a reference number, a
  date, a phone number) rather than a value meant to be compared/summed — GOV.UK's own components
  list treats those (National Insurance numbers, phone numbers) as ordinary text fields, not as the
  numeric-aligned table format.
- **Why:** Right-alignment lets the decimal points and digit counts line up vertically, which is
  what makes a column of numbers scannable and comparable at a glance; left-aligned numbers don't
  visually stack by magnitude.
- **Source:** [GOV.UK — Table](https://design-system.service.gov.uk/components/table/)

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
  cost of losing a fixed position. GOV.UK adds a concrete accessibility reason to avoid infinite
  scroll specifically: "avoid using the 'infinite scroll' technique to automatically load content
  when the user approaches the bottom of the page. This causes problems for keyboard users."
- **Source:** [Carbon — Pagination usage](https://carbondesignsystem.com/components/pagination/usage/),
  [GOV.UK — Pagination](https://design-system.service.gov.uk/components/pagination/)

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

- **Default:** Avoid them where a static hero or content directly in the page UI would work —
  NN/g's core finding: "people often immediately scroll past these large images and miss all of
  the content within them, or at least the content that's in any frame other than the first," and
  a static hero "may be less likely to distract users than a rotating element." If a carousel is
  used anyway, NN/g's specific requirements are: 5 or fewer frames ("it's unlikely users will
  engage with more than that"), visible/discoverable navigation controls placed inside the
  carousel (not below it or cut off by a fold), and — if auto-forwarding — a pace slow enough
  that people can actually read each frame's content before it changes.
- **Flips when:** Multiple pieces of content genuinely need to share one piece of prime real
  estate and each frame individually gives an accurate impression on its own — NN/g's caution here
  is that a designer sees "a collection of images" but "a user often considers just the one image
  he sees," so this only holds if any single frame alone would still represent the message
  correctly.
- **Why:** Carousels create a false sense of security that every frame will be seen, which leads
  teams to bury important content in later frames that most users will never scroll to; important
  information shown in a carousel should also live somewhere else in the UI as a backup.
- **Source:** [NN/g — Designing Effective Carousels](https://www.nngroup.com/articles/designing-effective-carousels/)

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
  [Atlassian — Designing messages](https://atlassian.design/foundations/content/designing-messages),
  [GOV.UK — Check answers](https://design-system.service.gov.uk/patterns/check-answers/)
- **Disagreement:** GOV.UK avoids inline edit even for a single answer: its check-answers pattern
  uses a "Change" link that takes the user to the original full question page to edit, then returns
  them via the page's own "Continue" button — "you should provide a 'Change' link next to each
  section on your check answers page so that users can add or change the information." Rather than
  editing in place, GOV.UK routes every edit, however small, back through its one-question-per-page
  flow (B15).

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

- **Default:** For waits under roughly 10 seconds, use a spinner for a single module (a card, a
  video) and a skeleton screen when the whole page is loading — NN/g: "spinners are typically best
  used on a single module... skeleton screens... are better when the full screen is loading because
  the wireframe gives users a sense of what the page will look like." Under 1 second, skip both —
  "they likely won't make a difference to the users' experience" and a flashing skeleton can
  actually feel worse than nothing.
- **Flips when:** The wait crosses roughly 10 seconds, or the process isn't a full-page load at all
  — "progress bars are strongly recommended for any page that takes longer than 10 seconds,"
  because unlike a spinner or skeleton they communicate how much longer is left. And skeleton
  screens are specifically for full-page loads: "whenever some other process (e.g., download,
  upload, convert a file) is involved, it does not make sense... to show a skeleton screen" —
  use a progress bar or step-based wizard instead.
- **Why:** A skeleton screen reduces cognitive load by letting the user build a mental model of the
  page structure before content arrives, and creates "the illusion of a shorter wait time" — but
  only if it mimics real layout; a frame-only skeleton with no content wireframe is "essentially
  equivalent to a spinner" and should be avoided since it gives no structural information.
- **Source:** [NN/g — Skeleton Screens 101](https://www.nngroup.com/articles/skeleton-screens/),
  [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/)
- **Disagreement:** NN/g scopes spinners to single modules ("a video or a card which is on a
  dashboard") and reserves skeletons for full-screen loads, but Carbon recommends skeleton over
  spinner even at the sub-page, single-component level: "if extra load time is expected to display
  information, use skeleton states instead of spinners" for its data table component specifically.
  Both agree skeleton beats spinner when there's real structure to preview; they disagree on
  whether module-level loading is still spinner territory or already skeleton territory.

### B14. Filter and search on a list

- **Default:** Put search and filtering in a dedicated toolbar above the list/table, collapsed
  behind a search icon by default — Carbon: "a search field can be triggered through an icon
  button in the data table toolbar... the search is closed by default, and placed below the
  table title."
  Reserve the toolbar for global actions (search, complex filters, exporting) and cap it at five
  visible actions before moving the rest into an overflow menu.
- **Flips when:** Search is a primary, frequently-used entry point for that view rather than an
  occasional refinement — Carbon offers an "open search" variant that stays always-visible on the
  left of the table for exactly that case.
- **Why:** A collapsed-by-default search keeps the toolbar uncluttered for the common case, while
  still making the escape hatch (open search) available for lists where search is the primary task.
- **Source:** [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/)

### B15. Multi-step flows — wizard vs single long form

- **Default:** Split the flow into one question per page rather than one long form — GOV.UK:
  "asking just one question per question page helps users understand what you're asking them to
  do, and focus on the specific question and its answer." Each step still needs a back link, a page
  heading, and a continue button, and a progress indicator only "if research shows it's helpful."
  Never ask for the same piece of information twice in one journey — pre-populate or offer the
  carried-forward answer instead.
- **Flips when:** The fields are tightly related enough that splitting them would break the user's
  mental model of a single answer — GOV.UK's own date-of-birth example keeps day/month/year as one
  fieldset on one page rather than three separate pages, because those three inputs together
  represent one question, not three.
- **Why:** One question at a time reduces the chance of a user skimming past or misreading a field
  buried in a long form, and it lets validation happen per-step instead of surfacing every error at
  once at the end.
- **Source:** [GOV.UK — Question pages](https://design-system.service.gov.uk/patterns/question-pages/)

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
- **Source:** [Carbon — Data table usage](https://carbondesignsystem.com/components/data-table/usage/),
  [GOV.UK — Button](https://design-system.service.gov.uk/components/button/)
- **Disagreement:** Carbon treats disabling as the normal, expected way to represent a temporarily
  unavailable action; GOV.UK is far more reluctant: "disabled buttons have poor contrast and can
  confuse some users, so avoid them if possible. Only use disabled buttons if research shows it
  makes the user interface easier to understand." GOV.UK's default leans toward leaving the control
  enabled and handling the invalid case as a validation error after the attempt, rather than
  disabling it beforehand.

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
- **Disagreement:** Material 3 (48dp) and Apple HIG disagree on the exact minimum: HIG states "a
  button needs a hit region of at least 44x44 pt — in visionOS, 60x60 pt — to ensure that people
  can select it easily, whether they use a fingertip, a pointer, their eyes, or a remote." Both
  agree on the underlying principle (pad the invisible hit region past the visible control), they
  just standardize on different numbers (44pt HIG vs 48dp Material) — pt and dp are comparable
  density-independent units, so this is a genuine ~9% numeric disagreement, not a units mismatch.

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

- **Default:** Split into a hub-and-task overview once the work spans multiple sessions or multiple
  distinct groups of activity — GOV.UK's stated trigger: "only use a complete multiple tasks page
  for longer transactions involving multiple tasks that users may need to complete over a number of
  sessions," showing it "at the start of the transaction" and "at the start of each returning
  session," with each task's completion status visible on the hub.
- **Flips when:** The work is simple enough to reduce to fewer tasks — GOV.UK explicitly says to
  "try to simplify the transaction before you use a complete multiple tasks page... you might not
  need one," i.e. splitting is the fallback, not the default, when the underlying task count can be
  cut down instead.
- **Why:** A single dashboard trying to hold every group of activity at once becomes unscannable
  once there's enough of it to span multiple sessions; a hub page that shows task-level status lets
  the user pick up where they left off without re-parsing everything each time.
- **Source:** [GOV.UK — Complete multiple tasks](https://design-system.service.gov.uk/patterns/complete-multiple-tasks/)

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

- **Default:** Never make hover the only way to reveal something the user needs, and design the
  primary interaction so it fully works by touch/tap alone — Apple HIG frames pointer support on
  iPad explicitly as additive, not a replacement: "the iPadOS pointing system gives people an
  additional way to interact with apps and content — it doesn't replace touch," and recommends you
  "distinguish between pointer and finger input only if it provides value" rather than by default.
- **Flips when:** The distinction genuinely adds a capability touch can't offer, not just a visual
  nicety — HIG's own example is a video scrubber: "people can drag the playhead using either the
  pointer or touch, but they can use the pointer to click a precise seek destination," a case where
  the pointer's higher precision does something touch structurally cannot.
- **Why:** Hover is a state that only pointer/mouse input can produce — a touchscreen has no
  equivalent continuous "nearby but not yet pressed" signal, so any control that depends on hover
  to be discovered or operated is invisible or broken on a touch-only device.
- **Source:** [Apple HIG — Pointing devices](https://developer.apple.com/design/human-interface-guidelines/pointing-devices)

### E26. Safe areas, notches, on-screen keyboard displacing viewport

- **Default:** Lay content out relative to the platform's safe area, not the raw screen bounds —
  Apple HIG: "a safe area defines the area within a view that isn't covered by a toolbar, tab bar,
  or other views a window might provide. Safe areas are essential for avoiding a device's
  interactive and display features, like Dynamic Island on iPhone." Use the system-provided safe
  area/margin guides to reposition content dynamically "when sizes change," rather than hardcoding
  offsets for one device's notch/camera-housing geometry.
- **Flips when:** The layout deliberately wants edge-to-edge visual elements (a background image or
  full-bleed color) rather than interactive content — HIG's own full-width-button guidance shows
  the line: "avoid full-width buttons... if you need to include a full-width button, make sure it
  harmonizes with the curvature of the hardware and aligns with adjacent safe areas," i.e. decor can
  bleed to the edge, but interactive/legible content should still respect the safe inset.
  On tvOS specifically, HIG gives a concrete number for this trade-off: inset primary content 60pt
  from top/bottom and 80pt from the sides of the screen.
- **Why:** A device's own display/system features (notches, camera housings, home indicators,
  toolbars) physically occlude or crowd fixed regions of the screen; anchoring layout to the safe
  area instead of absolute screen coordinates keeps content from being cropped or obscured as those
  regions vary across devices and orientations.
- **Source:** [Apple HIG — Layout](https://developer.apple.com/design/human-interface-guidelines/layout)

### E27. PWA: offline state, install prompt, splash/theme color, standalone-mode differences from browser tab

- **Default:** None of the eight sources read in this pass addresses installable-web-app-specific
  concerns (offline state UI, install prompts, splash/theme color, or standalone-vs-browser-tab
  chrome differences) — Material 3, Apple HIG, Carbon, and GOV.UK all cover native or
  responsive-web layout, but not the PWA manifest/service-worker layer specifically. The closest
  adjacent guidance actually fetched is Apple HIG's safe-area and adaptive-layout material (E24,
  E26), which addresses cross-device layout robustness but not offline/installability.
- **Flips when:** This stays unresolved regardless of context — it isn't that the recommendation
  changes under some condition, it's that no fetched source made a PWA-specific recommendation at
  all within this pass's fetch budget.
- **Why:** All eight allowed sources are native-app or general responsive-web design systems; PWA
  installability (manifest, service worker, offline UI) is a distinct, narrower topic none of them
  document, so answering it here would require citing outside the eight-source allowlist.
- **Source:** _none read_ — checked Material 3 (layout/breakpoints pages), Apple HIG (layout,
  pointing-devices, buttons pages), Carbon (typography, pagination, data-table, action-labels
  pages), and GOV.UK (question-pages, table, complete-multiple-tasks pages); none covers PWA
  install/offline/standalone-mode concerns.
- **Scope:** out of scope for this repo until a web app manifest and a service worker actually
  exist — see F35. The two sources added in this pass (Linear docs, Microsoft Learn) likewise
  carry no PWA install, offline, or standalone-mode guidance, so E27's original finding is
  unchanged.

## Named reference points (B28-B32 extend section B)

### B28. Dense list rows — Linear's issue list navigation, selection, and property editing

- **Default:** keyboard-first navigation and selection over a dense list, with property changes
  routed through a command bar rather than a modal or a click-to-edit field. Linear's docs:
  highlighting uses "↑ / ↓ or J / K to navigate the page to the issue"; once highlighted, "press
  X" to select; hold "Shift and click your mouse on the issue" to select with the pointer; "hover
  near the left edge of an issue to reveal its checkbox"; to extend a range, "hold down Shift
  after selecting the first issue, then use the ↑ / ↓ keys to increase the selected range one
  issue at a time"; "Cmd/Ctrl A to select all issues on a board or list"; "press Esc to clear the
  selected issues"; and once one or more issues are selected, "use Cmd/Ctrl K to open the command
  bar and select the preferred action or right-click anywhere on the selected issue(s) to open the
  contextual menu."
- **Flips when:** the user is a pointer user who does not know the shortcuts — the same selection
  model stays reachable via the checkbox revealed on hover near the row's left edge. Note that
  this is a hover-revealed affordance, which C16 already flags as undiscoverable on touch devices.
- **Why:** a dense list is scanned far more often than it is clicked, so binding navigation and
  selection to keys keeps the hand off the pointer for the common case; routing actions through a
  command bar also means the row itself does not have to carry a visible control per action
  (see C19 and D22 on per-row and per-toolbar action caps).
- **Source:** [Linear — Select issues](https://linear.app/docs/select-issues)
- **Disagreement:** B10 records Atlassian's inline edit as a component that "switches between
  reading and editing on the same page." Linear's documented path for changing a property on a
  selected row — "select them with shortcuts or the mouse and then update the issue field like you
  would any issue" via the command bar or contextual menu — is list -> transient overlay ->
  committed change, not an in-place field swap. The fetched page documents no click-to-edit-in-
  place behavior, so none is described here.

### B29. Forms — GOV.UK is this doc's reference point

- **Default:** GOV.UK is this doc's forms reference point. For validation timing and wording, see
  **B12** (validate after the action has been taken, 1-2 sentences giving the reason and the next
  step). For multi-field flows, see **B15** (one question per page, with a back link, a page
  heading, and a continue button).
- **Flips when:** this does not apply — B29 is an index entry, not a new recommendation. Where
  GOV.UK conflicts with another system, the conflict is already written up on the entry itself:
  the Disagreement bullets on B10 and C17 are both GOV.UK-vs-other-system.
- **Why:** an index entry keeps the doc's cross-reference convention (rule 3: cross-reference, do
  not repeat) intact for the forms topic without restating B12/B15's content here.
- **Source:** _no new page fetched_ — see ledger row 4 for the pages behind B12 and B15.

### B30. Empty states and onboarding — Shopify Polaris (unreachable)

- **Default:** unresolved. No default is recorded because no source could be fetched this pass.
- **Flips when:** unresolved for the same reason — no fetched source to key a condition off of.
- **Why:** unresolved for the same reason — no fetched source to explain a rationale.
- **Source:** `unreachable`. `https://polaris.shopify.com/patterns` returned HTTP 301 to
  `https://shopify.dev/docs/api/polaris`, retried live this pass.
  `https://polaris.shopify.com/components/layout-and-structure/empty-state` returned the same
  HTTP 301 to the same target, also retried live this pass. The redirect target renders
  successfully (HTTP 200) but documents only app surfaces — App Home (iframe/UI extension), Admin,
  Checkout, Customer accounts, and POS UI extensions — with no empty-state pattern or onboarding
  guidance anywhere on the page. Nothing about empty states is recorded here from memory.

### B31. Master/detail in practice — Microsoft's list/details pattern

- **Default:** "when an item in the list is selected, the details pane is updated," in both of
  Microsoft's two styles. In the side-by-side style, "the list in the list pane has a selection
  visual to indicate the currently selected item" and "selecting a new item in the list updates
  the details pane." In the stacked style, "only one pane is visible at a time: the list or the
  details. The user starts at the list pane and 'drills down' to the details pane by selecting an
  item in the list. To the user, it appears as though the list and details views exist on two
  separate pages," with back-navigation handled by real page-level navigation history between the
  two pages.
- **Flips when:** available window width crosses Microsoft's stated threshold: "320 epx-640 epx"
  recommends the stacked style, "641 epx or wider" recommends side-by-side.
- **Why:** the side-by-side form exists so that repeated selection does not cost a page-level
  navigation each time; Microsoft names the fit explicitly — "build an email app, address book, or
  any app that is based on a list-details layout" and support "working back-and-forth between
  contexts."
- **Source:** [Microsoft Learn — List/details pattern](https://learn.microsoft.com/en-us/windows/apps/design/controls/list-details)
- **Disagreement:** against **B6** — both agree the rule is keyed to width and that narrow means
  drill-down while wide means two panes, but B6 records Material 3 holding a single pane through
  compact and medium and only recommending two panes at 840dp+, whereas Microsoft switches at
  641 epx — roughly 200 units earlier. B6's general breakpoint rule is not re-derived here.

### B32. Mobile navigation — visible tab bar over hamburger/drawer, and when that flips

- **Default:** pick the visible tab bar over a hidden hamburger/drawer menu. NN/g: a navigation
  menu (hamburger) "makes the navigation options least discoverable"; opening one costs a decision
  because "users will have to make a decision to open it and check whether the individual
  navigation options are relevant." By contrast a tab bar is "persistent, that is, they are always
  visible on the screen, whether the user scrolls down the page or not," whereas ordinary
  navigation bars "usually start out being present at the top of the page but disappear once the
  user has scrolled one or more screens down." Tab bars and navigation bars are "well suited for
  sites with relatively few navigation options. If your site has more than 5 options, it's hard to
  fit them in a tab or navigation bar," while a hidden menu "can contain a fairly large number of
  navigation options in a tiny space and can also easily support submenus."
- **Flips when:** the destination count exceeds what a bar can hold (NN/g's stated line is above
  5 options), or the persistence argument that justified the pick is itself lost — a navigation
  bar that scrolls away with the page no longer offers the always-visible property a tab bar has.
  Cross-reference **B8** for the breakpoint-keyed swap between a bottom bar and a rail; this entry
  only picks the mobile shape, it does not re-derive when to swap it.
- **Why:** below about five destinations, discoverability and interaction cost both favor keeping
  the options visible over hiding them behind a menu the user has to remember to open.
- **Source:** [NN/g — Basic Patterns for Mobile Navigation: A Primer](https://www.nngroup.com/articles/mobile-navigation-patterns/)

## F. Answers — LiveView fit, device target, PWA scope

### F33. Which patterns translate cleanly to LiveView, and which need a JS hook

- **Answer:** most of the interaction patterns in this doc translate to plain LiveView with a
  server round-trip per interaction. Two do not: rapid keyboard row navigation, and anything that
  advances on a clock.
- **Evidence — translates cleanly:**
  - The view-to-edit toggle shape behind B28 and B10 is `phx-click` plus assign-driven conditional
    rendering; no client state is needed. Already proven in this repo:
    `CatalogLive.Show.handle_event("select-image", ...)` swaps `@selected_image` on a server
    round-trip per click (`lib/pukllay_club_web/live/catalog_live/show.ex`), and `FilterDrawer`'s
    facet pills do the same via `phx-click` with `phx-value-facet` / `phx-value-value`
    (`lib/pukllay_club_web/components/filter_drawer.ex`).
  - Drawer and master/detail panel open-close (B31) needs neither LiveView nor JS: `FilterDrawer`
    holds its open state in a bare checkbox input driven by daisyUI's drawer classes
    (`lib/pukllay_club_web/components/filter_drawer.ex`), so the transition is pure CSS.
  - Mobile nav open-close (B32) is the same mechanism as that drawer — no hook.
  - Debounced search-as-you-type (B14) already works without a hook: the catalog search input
    carries `phx-debounce="300"` (`lib/pukllay_club_web/live/catalog_live/index.ex`).
- **Evidence — needs a client-side JS hook:**
  - B28's arrow-key / `J` / `K` row navigation is the latency-sensitive case. A server round-trip
    per keypress would feel laggy during rapid navigation, so the highlighted-row state has to be
    held client-side in a hook, contacting the server only on an actual selection or edit commit —
    not on every key.
  - Carousel auto-advance and pacing (B9), and any timed animation, need a hook because LiveView
    has no client-side timer primitive of its own.
- **Implication:** the split falls on whether the user is already waiting. An interaction whose
  result the user waits for anyway (a click that changes content) tolerates a round-trip; an
  interaction the user expects to be instantaneous and repeats rapidly (held or repeated
  keypresses, clock-driven motion) does not.

### F34. Device target — ambiguous, leaning mobile-considered rather than desktop-primary

- **Answer:** ambiguous, and not committed either way yet. State this plainly; do not force a pick.
- **Evidence for mobile-considered:** the catalog card grid is mobile-first — a two-column grid is
  the base, scaling up at the `sm` and `lg` breakpoints, rather than a desktop base scaled down
  (`lib/pukllay_club_web/live/catalog_live/index.ex`). Touch targets are explicitly sized to a
  44px minimum — matching the Apple HIG figure recorded in C20 — on both the filter-drawer trigger
  button and every facet pill (`lib/pukllay_club_web/components/filter_drawer.ex`). The detail
  page's thumbnail strip is a horizontally scrolling swipe strip rather than a wrapping grid
  (`lib/pukllay_club_web/live/catalog_live/show.ex`).
- **Evidence it is not committed:** there is no dedicated mobile navigation at all — no bottom bar
  and no hamburger. `Layouts.app`'s header is a single navbar whose only breakpoint-dependent
  change is horizontal padding (`lib/pukllay_club_web/components/layouts.ex`), so the nav shape
  never swaps, which is exactly what B8 and B32 describe doing. And no desktop split-pane layout
  exists: the detail page is a single centred column at every viewport
  (`lib/pukllay_club_web/live/catalog_live/show.ex`), so the two-pane branch of B6 and B31 has
  never been built.
- **Implication:** do not resolve this by assumption. B6/B31 (master/detail) and B8/B32 (nav
  shape) both need a device-target answer before either can be implemented, and that answer is not
  in the code yet.

### F35. PWA scope — no, and section E is scoped to responsive web only

- **Answer:** no. This is not a PWA and nothing in the repo is building toward one.
- **Evidence (verified against the working tree this pass):** no `manifest.json` and no
  `.webmanifest` file exists anywhere in the repository — searched by filename across the whole
  tree excluding `deps`, `_build`, and `node_modules`, zero hits. No service worker is registered:
  `assets/js/` contains no occurrence of `serviceWorker`, zero hits. And the document head in
  `lib/pukllay_club_web/components/layouts/root.html.heex` contains only a charset meta, a
  viewport meta, a CSRF-token meta, the live title, one stylesheet link, and two script tags — it
  carries no manifest link element and no theme-colour meta tag.
- **Implication:** scope section E to responsive web only for now. E24 (breakpoints), E25 (touch
  versus pointer) and E26 (safe areas) remain valid general responsive-web guidance and apply
  today. E27 (PWA offline state, install prompt, splash, standalone-mode differences) is out of
  scope until a manifest and a service worker actually exist here — do not build UI against it
  prematurely.
