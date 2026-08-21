---
sketch: 008
name: filter-search-ui
question: "What does the catalog's own filter surface look like, and how should the nav search box's live-narrowing/typeahead behave — given sketch 005's detail page chips already link to real query params that need somewhere to land?"
winner: null
tags: [filter, search, navigation, information-architecture]
---

# Sketch 008: Filter / Search UI

## Design Question
Sketch 005's detail page links mechanics/themes/tags/difficulty chips to constructed catalog URLs
(`/?mechanics=Construcción+de+motor`, `/?weight_bands=Nivel+experto`, etc.) — but the catalog page
itself has never had a designed filter surface for those links to land on, and the nav search box
(present since sketch 001) has only ever been a static input with no results/typeahead behavior.
This sketch designs both together, since a chip-bar filter UI and a search-first UI shape the search
box very differently.

## Grounding
Filter dimensions (`weight_bands`, `mechanics`, `max_playtime`, free-text `q`) are the real assign
names from `CatalogLive.Index`'s `mount/3`, per sketch 005's own grounding notes. **Same caveat
sketch 005 flagged applies here too:** `CatalogLive.Index` has no `handle_params/3` and doesn't
`push_patch` — filter state today lives only in socket assigns, not the URL. This sketch filters a
real, client-side dataset live (proving the *interaction*), but wiring an actual `?mechanics=...`
URL to pre-select a filter on page load needs that backend work first — not proven here.

## How to View
open .planning/sketches/008-filter-search-ui/index.html

## Status: Round 8 in progress — not yet approved

**Round 1–2 (original build):** landed on **C — Search-First Overlay**: a large, centered search
input leading the page, quick-filter suggestion chips appearing live below it, a "Más filtros ▾"
trigger for the rest (desktop popover / mobile bottom-sheet). Results rendered as a horizontal
shelf rail rather than a grid. **A: Chip Bar + Popovers** and **B: Sidebar Drawer** were sketched
and rejected but not preserved as tabs — the user asked to drop them once C read as decisive.

**Round 3 (superseded, discarded):** by the time this sketch was revisited, sketch 011's full-shell
composition had already shipped its own real header with a compact nav-embedded search box and a
mobile-only filters trigger — diverging from Round 1–2's giant hero. Round 3 reconciled 008 to
that reality: two variants (**A: Filtro en el lugar** — dim/hide non-matching cards in place within
each shelf, per-shelf empty state; **B: Resultados dedicados** — collapse the whole browse view to
one dedicated results rail) both wired to a live search dropdown and a real desktop "Filtros"
trigger (011 never had one). Both were built and browser-verified working. **Discarded per direct
feedback** before a winner was picked — the user wants a different information architecture
entirely, not a refinement of this direction. Not preserved as tabs in the current file.

**Round 4 (superseded, discarded):** full redo per feedback. Direction: minimalist, industry-standard
faceted filter bar (chip-toggle buttons), prioritized Jugadores/Duración/Dificultad as an
always-visible primary cluster, Tipo (Cooperativo/Competitivo/Equipo) as a secondary cluster, and
Autor/Mecánica behind a "Más filtros ▾" overflow. BGG's own advanced search filters on the same
top-3 (player count/time/weight) — the closest real "industry standard" for this exact domain — but
as dense numeric range inputs, rejected as too hobbyist for a newcomer-first catalog; chips kept the
same facets tap-friendly instead. Filtering was in-place (dim/hide within each shelf, per-shelf empty
state). **Found + fixed a real bug during the build:** the "Más filtros" Autor/Mecánica radios used
inline `onchange="setFilter('author', ${JSON.stringify(a)})"` — `JSON.stringify`'s double-quoted
output broke the already double-quoted `onchange="..."` HTML attribute mid-way through, silently
no-op'ing every click; fixed with `data-key`/`value` attributes plus one delegated `change` listener.
Confirmed live in-browser after the fix. **Rejected per direct feedback** before a winner was picked:
the facet semantics/priorities were right, but the chip-button chrome (borders, filled backgrounds)
made the bar "too heavy — heavier than the content itself." Not preserved as a tab in the current file.

**Round 5 (current, active):** three lightweight alternatives to Round 4's chip-button styling, same
facet semantics/priorities/in-place filtering carried over unchanged, same 14-game dataset with
`author`/`type` fields, desktop-only (mobile still explicitly deferred). Built as real tabs (not just
mockup previews) since two build-then-reject rounds already happened and a rough ASCII sketch wasn't
enough signal on its own:
- **A — Texto plano:** no chrome at all. Each facet (Jugadores/Duración/Dificultad/Tipo/Más filtros)
  is a plain text trigger — muted gray at rest, colored+underlined with the picked value appended in
  parens once active (e.g. "Jugadores (4)") — that opens a small text-only dropdown listing options.
- **B — Resumen colapsado:** the most dramatic option. At rest it's a single muted summary line
  ("Cualquier cantidad de jugadores · cualquier duración · cualquier dificultad") plus a "Filtrar ▾"
  trigger — filters take almost zero space until engaged. Clicking "Filtrar" opens one popover with
  every facet (including Autor/Mecánica — no separate nested "más filtros" needed since the whole
  thing is already one click away) as chip-toggle buttons; the summary line updates in place with the
  actual selections once picked, popover stays open across multiple selections in one session.
- **C — Franja sin bordes:** same always-visible layout as Round 4, but with every button
  border/background stripped — flat icon+text pairs, active state shown via color+underline only
  (no filled pill). Closest to "just destyle Round 4" as an answer.

All three browser-verified working (filtering, empty states, combined facets, Autor/Mecánica radios)
with no console errors.

**Round 5 outcome:** user picked **B — Resumen colapsado** as the best of the three, but flagged two
real problems: the centered popover it opened "isn't meaningful and breaks navigation and rhythm",
and the "Filtrar" trigger sat far from search instead of next to it as requested. User asked directly
what Airbnb/Netflix (this project's stated references, see MANIFEST "Reference Points") do here —
researched before building further rather than guessing: **Airbnb** puts its own "Filters" trigger
near search, but opens a **centered modal** on click — the exact pattern just rejected. **Netflix**
doesn't do real-time faceted filtering during browse at all (search just expands inline in the nav;
genres are separate pages). Neither reference actually uses a side drawer for filters on desktop —
that's more of a mobile e-commerce convention (Amazon/Etsy apps). Decided to proceed anyway: this
project already has its own validated slide-in drawer (011's mobile nav-drawer), so reusing that
project-internal mechanic is well-grounded independent of what either reference does.

**Round 6 (current, active):** single build (direction was concrete enough this round — no need for
3 variants). Same facet semantics/priorities/dataset/in-place shelf filtering carried over unchanged
from Rounds 4/5. Changed:
- The filter trigger is now a small icon button (🎚) living directly in the header, grouped tightly
  with the search box via `.search-filter-cluster` — "closer to search" taken literally, not just
  visually near but in the same flex cluster.
- Clicking it opens a **right-side slide-in drawer** (not a centered popover/modal) — mirrors 011's
  mobile nav-drawer mechanic (same transform/backdrop/timing), but slides from the right instead of
  the left, so the two roles stay spatially distinct: site navigation = left, refining *this page's*
  content = right (common e-commerce convention, e.g. cart drawers).
- All facets (Jugadores/Duración/Dificultad/Tipo/Autor/Mecánica) live in one scrollable drawer body,
  no separate nested "más filtros" — the drawer itself is already the progressive-disclosure step.
- **Nothing added to the page at rest** beyond the header icon — no summary bar, no placeholder text
  row. Active-filter feedback is a small count badge on the icon itself (e.g. "🎚 ①") plus the
  shelves' own dimming/empty-state, rather than a persistent status line.
- Drawer footer: live match count ("13 juegos coinciden" / "14 juegos en total" at rest) + "✕ Limpiar
  filtros" (disabled when nothing's active).

Browser-verified working: drawer opens/closes correctly (confirmed via DOM inspection when a stale
screenshot capture made it look like nothing happened — transform/opacity were actually already
correct), chip selection updates the badge/shelves/footer count live, combining filters narrows
correctly, no console errors.

**Round 6 outcome:** the icon-next-to-search placement worked and carried forward. The right-side
drawer itself did not — user asked to switch to a centered modal instead, explicitly reasoning that
a centered dialog with a strong backdrop *focuses* the user on the modal rather than "avoid
overlaying anything" (a different rationale than Round 5's rejection of the earlier popover — that
one was about the popover feeling meaningless/disruptive to page rhythm, this is a deliberate
preference for focus-lock). Also asked for the modal content to have "clean balance, hierarchy,
guiding the user to use the most common filters, not being technical," reuse existing icons only
(no new iconography), and ground the structure in what a game's own pills/detail page already show.

**Round 7 (current, active):** single build, same facet semantics/priorities/dataset/in-place shelf
filtering carried over unchanged. Changed:
- **Centered modal** (à la Airbnb) replaces the right-side drawer — dimmed backdrop (deliberately
  more opaque than the drawer's, since focus-lock is now the explicit goal), scale+fade transition,
  closes via ✕, Escape key, or clicking the backdrop outside the modal.
- **Content hierarchy grounded in the pills a game already shows.** Jugadores/Duración/Dificultad
  are the exact same three facts every card's hover-portal and the detail page already surface as
  "pills" (001-D/002-D/005/011's `pillsRowHTML`) — so they lead the modal, get a bigger heading
  (`--text-base`, bold) and bigger chip touch targets (10px/16px padding) than everything below.
  Tipo is a secondary cluster (smaller heading, smaller chips) below a dashed divider — still common,
  but not one of the three "pill" facts. Autor/Mecánica — the fields closest to hobbyist jargon — are
  pushed into a visually quiet "Más específico" zone using plain `<select>` dropdowns instead of a
  wall of buttons, so the modal doesn't read as technical at a glance.
- **No new icons.** 👥/⏱/🎯/🤝/⚔️ are the same glyphs already used on card pills and in Rounds 4–6 —
  none invented for this round.
- Footer keeps the Airbnb shape: "✕ Limpiar filtros" (disabled when nothing's active, left) + a
  primary "Ver N juegos" button (right) that updates its count live and doubles as the close action —
  filtering is already live underneath, so there's nothing to "apply," just a satisfying way to exit.

Browser-verified working: modal opens/closes (✕, Escape, backdrop click), chip + `<select>` combos
update the live count and shelf filtering correctly (confirmed combining 3 primary filters + Autor
correctly narrows to 0 with the right empty states), no console errors. One tooling note: this
session's `getComputedStyle` reads via the JS-exec tool briefly showed `opacity: 0` on the backdrop
right after opening it — a screenshot taken moments later showed the modal fully visible and
correctly styled, so that was a CDP timing artifact in the verification tooling, not a real rendering
bug (this project's own sketches have hit similar wide-viewport tooling quirks before, per 007/011's
notes).

**Round 7 bug fix (same round, after user report):** user reported the modal content was "totally
broken" with a screenshot from their own machine. Root cause, found by diffing every CSS custom
property used in this file against what `themes/default.css` actually defines: **`var(--space-5)`
does not exist in this project's spacing scale** (`--space-1/2/3/4/6/8/12` only — there is no
`--space-5`, confirmed by grepping the theme file directly). Four rules used it —
`.filter-modal-header`/`.filter-modal-body`/`.filter-modal-footer` padding and
`.fm-primary-group` margin-bottom — and per CSS spec, a shorthand `padding`/`margin` declaration
referencing one undefined custom property with no fallback is invalid *at computed-value time*,
which drops the **entire** declaration back to its initial value (0). So the header, body, and
footer all silently had **zero padding**: content sat flush against the modal's edges, and because
the modal now also (correctly) clips to its own rounded corners, that flush content visually read as
"bleeding past" the rounded silhouette — exactly what the screenshot showed (icons appearing cut off
at the left edge, the close button poking above the header, the footer buttons crowding the bottom
corner). Fixed by replacing all four with `var(--space-6)` (32px, the nearest defined step, matching
the generous Airbnb-style spacing already intended). Also hardened against a second, independent
risk while in there: wrapped every icon glyph (👥/⏱/🎯/🤝/🎚) in a fixed-size `.icon-box` span
(`inline-flex`, `overflow: hidden`) rather than letting them sit as part of the heading's running
text — some multi-part emoji can paint wider than their character cell on certain font stacks, and a
clipped box guarantees containment regardless of the specific glyph's paint bounds. Also added
`overflow: hidden` to `.filter-modal` itself (needed for the rounded corners to actually clip
children — border-radius alone doesn't do that) and to `.theme-toggle`, keeping `.filter-icon-btn`
unclipped since its notification badge intentionally overlaps the button's own edge. Re-verified live
after the fix: header/body/footer all show correct padding, icons sit fully inside the modal with
clean left alignment, close button sits centered inside the header with room to spare, no console
errors.

**Round 7 typography/hierarchy fix (same round, second user report):** user flagged that the modal's
pills didn't match the detail page's real pills, and the group labels looked like a different font.
Checked against ground truth in 011 (the real composed page) rather than eyeballing it:
- 011's actual card/detail **`.pill`** (`pillsRowHTML`) is a small, muted, *display-only* fact badge —
  11px, `color: var(--color-text-muted)`, no active state, never meant to be clicked. Using its exact
  styling for a *toggleable filter chip* would have removed the selected-state affordance entirely
  (a passive badge and a tap-to-select control shouldn't look identical). 011 already has the right
  reference for a **clickable** chip instead — its real mobile category-filter `.chip`/`.chip.active`
  (`text-xs`, `6px 14px` padding, `radius-full`, resting `color: var(--color-text)`, active = filled
  primary). Round 7's `.chip-toggle` had drifted from that (bigger `text-sm`, bulkier padding) —
  realigned to match `.chip` exactly, so filter chips now read as the same *family* of control as the
  chip already used elsewhere in this project, not an invented one-off.
- 011's real **`.filter-group h5`** (the filters-panel's own group-label style, already used in
  Rounds 4–6 too) is a small uppercase micro-label: `text-xs`, `uppercase`, `letter-spacing: 0.06em`,
  muted color. Round 7 had given primary groups a bold `text-base` heading and secondary a different
  `text-sm` heading — two bespoke styles, neither matching the established one, which is what read as
  "a different font." Unified every group heading (Jugadores/Duración/Dificultad/Tipo) back to the
  same micro-label formula "Más específico" already used — hierarchy between primary and secondary is
  now carried by order + a small chip-padding bump on primary only (8px vs 6px), not by typography.

Re-verified live: all four group headings now render as the same uppercase micro-label style, chips
are visibly smaller/more consistent with the rest of the site, active state (filled primary) still
reads clearly at the smaller size, live count/badge still update correctly, no console errors.

**Round 7 interaction follow-ups (same round, third round of feedback):** three more questions,
answered and built:

1. **Instant vs. submit-based filtering?** User pushed back correctly on the first answer given —
   "client-side, zero latency" was true of *this sketch's* fake in-memory array, not the real system.
   Corrected: in production this hits Postgres through a Phoenix LiveView `handle_event` → Ecto query
   → socket diff-patch, not a page reload, but not literally free either. Kept instant anyway, for the
   right reason this time — LiveView is built exactly for this, and ~400 rows filtered on indexed
   columns is sub-10ms at the DB level, so the round-trip still *feels* instant. Real production
   nuance flagged for implementation (not built here, this is still a client-side demo): the free-text
   search input should get `phx-debounce="300"`; discrete chip/combobox clicks don't need debouncing,
   they're already rate-limited by human click speed.
2. **Autor/Mecánica as single-select `<select>` vs. searchable multiselect?** Agreed a multiselect is
   correct — a flat alphabetical dropdown doesn't scale once the real ~400-game catalog has far more
   authors/mechanics than this 14-game demo, and single-select can't express "Draft O Cooperativo" at
   all. Replaced both `<select>` elements with a type-to-filter combobox: typing narrows a suggestion
   list, clicking adds a removable chip, multiple values combine with OR within that facet (still AND
   across facets, unchanged).
3. **"Más específico" label removed.** Same reasoning as before applied one level deeper — a label
   that announces "this part is more technical" is itself a technical thing to say. Replaced with no
   label at all: a plain text link ("Buscar por autor o mecánica ›") that's collapsed by default (so
   Autor/Mecánica don't compete with the primary facets at rest) and auto-expands if either already
   has a selection, so re-opening the modal never hides an active choice.

**Bug found + fixed while building the combobox:** the suggestion dropdown, positioned directly below
its input via `top: 100%`, could render past the bottom edge of the scrollable `.filter-modal-body`
when the combobox is near the bottom of the current scroll position (which it usually is, being the
last section) — invisible until the user manually scrolled, discovered via DOM inspection (the box
had the `open` class and correct content, but its rect started 3px past the body's clipped bottom
edge). Fixed by calling `scrollIntoView({block:'nearest'})` on the suggestion box the moment it opens.
Also found calling that with `behavior:'smooth'` (or wrapped in `requestAnimationFrame`) didn't
reliably complete when triggered in the same tick as the box's `display:none→block` toggle — switched
to instant scroll, which resolved it cleanly (confirmed via direct `scrollTop` inspection before/after).

Re-verified live: typing "dra" surfaces "Draft", clicking adds a chip and updates the live count
("Ver 2 juegos"), the input stays focused afterward for adding more values, removing a chip via ✕
reverts state and shelf filtering correctly, the disclosure auto-expands on re-render whenever
`state.authors`/`state.mechanics` is non-empty even if manually collapsed first, no console errors.

**Round 8 (current, active):** four targeted polish fixes on Round 7's modal, per direct feedback —
no new variants, same facet semantics/dataset/filtering logic carried over unchanged:

1. **Title→options rhythm rebalanced.** Each group's internal gap (its `h5`/`h6` label to the chip
   row/inputs beneath it) is now tighter (`--space-3`, 12px) than the gap *between* groups
   (`--space-6`, 32px, up from a flat `--space-4` for both) — the Gestalt proximity cue that makes
   "this label belongs to these options" read clearly, which the previous flat spacing didn't
   provide. Applied to the primary groups, the secondary Tipo group, and the "Buscar por autor o
   mecánica" disclosure's own border-top gap, for one consistent rhythm top to bottom.
2. **All icons dropped**, not just "no *new* icons" (Round 7's bar). Removed the 👥/⏱/🎯/🤝 glyphs
   from every group heading, and — found while auditing for this — the Tipo chips themselves had
   emoji baked into their option labels (`🤝 Cooperativo`, `⚔️ Competitivo`, `👥 Equipo`), which
   Round 7 hadn't flagged as "icons" since they weren't in a heading, but are exactly the kind of
   icon the feedback meant. Both removed; labels are plain text now. The header's own 🎚 filter-
   trigger button icon was left alone — that's a distinct nav affordance outside the modal's
   title/options content, not part of this feedback.
3. **Autor/Mecánica forced into a true 50/50 split.** `.fm-tertiary-row` was `flex:1` columns with a
   `min-width`, which lets one column's own content (e.g. a wrapped chip row after picking a value)
   push it wider than its sibling at in-between widths — the two comboboxes never reliably lined up.
   Switched to CSS grid (`grid-template-columns: 1fr 1fr`), which is unaffected by either column's
   content. Also unified the `h6` labels ("Autor"/"Mecánica") to the exact same text-xs/uppercase/
   letter-spacing formula as every `h5` above them — they were already similar but not identical
   (no uppercase/tracking), which read as a subtly different, less-considered treatment for this
   last section versus the rest of the modal. Mobile (`max-width:640px`) still stacks these two
   columns to one, since a 50/50 split gets too cramped for a text input at phone widths.
4. **"Limpiar filtros" restyled as a real secondary button**, not a plain color-text link. It
   previously had no chrome of its own and reused `--color-primary` — the same hue as the filled
   "Ver juegos" button beside it — so the two read as similarly weighted despite one being the
   primary action and one being a reset. Replaced with this project's own established outlined-pill
   secondary-button pattern, ported verbatim from sketch 011's real `.pill-btn` (itself originally
   ported from an earlier round of *this* sketch): neutral border + `--color-text` at rest,
   `--color-primary` border/text on hover, same disabled-when-inactive state as before. Now clearly
   subordinate to the filled primary button next to it.

Browser-verified live: modal opens/closes correctly, chip toggles and the Autor/Mecánica combobox
(typed "kla" → suggested "Klaus Teuber" → added as a chip) still filter and combine correctly,
"Limpiar filtros" is disabled at rest and enables once a filter is active, clicking it resets all
state and re-collapses the autor/mecánica disclosure, no console errors.

**Round 8 follow-up (same round, after user report):** user flagged, with a screenshot, that the
Autor combobox "still breaks rhythm" once several chips are selected and wrap to a second line
(reproduced: Antoine Bauza / Don Eskridge / Alan R. Moon in Autor). Root cause: the label→options
rhythm fix above was applied to every group's `h5`/`h6` heading gap and the space *between* groups,
but the combobox's own internal chip-stack spacing (`.fm-combobox-chips`'s wrap gap and its
margin-bottom down to the input) was left at its old flat 6px from Round 7 — invisible with 0–1
chips, but glaringly tight and inconsistent with the new breathing room everywhere else the moment
chips wrap to a second row. Fixed: `.fm-combobox-chips` now uses `gap: var(--space-3) 6px` (12px
row-gap between wrapped chip rows, keeping a tighter 6px column-gap since chips on the same row are
one list, not separate groups) and `margin-bottom: var(--space-3)` down to the input — same space-3
rhythm as every label→options pairing elsewhere. Also bumped `.fm-tertiary`'s own margin-top
(the gap between the "Buscar por autor o mecánica" toggle and the Autor/Mecánica columns) from
`--space-4` to `--space-6`, which had the same leftover-from-Round-7 inconsistency. Re-verified live
with the exact reported 3-chip scenario: chip rows now read as clearly separated, input reads as a
distinct next step rather than a fourth cramped row, no console errors.

**Round 8 second follow-up (same round, third user report):** user pushed back that it "still looks
weird" — chips at the left with orphaned whitespace to the right of a row, sitting above a
separately-bordered input, still read as broken rhythm even with the space-3 gap fix. Correct
diagnosis this time: the *previous* fix only opened up the gap between two disconnected blocks
(a floating chip cluster, then a separately-boxed input below it) — it never addressed that they
were two visually distinct controls in the first place, which is what actually reads as "weird"
when a row has a chip on the left and nothing filling out to the right. Real fix: merged chips +
input into **one bordered field** — the standard tag-input pattern (Gmail's "To:" field, Notion's
multi-select property tags) — so the text caret sits inline right after the last chip and wraps
together with them inside a single `border`/`radius-md`/`background:var(--color-surface)` box,
with `:focus-within` swapping the border to primary on type (replacing the input's own former focus
ring, since it no longer has its own border). No separate `.fm-combobox-chips` wrapper anymore —
chips render as direct flex children of `.fm-combobox-field` alongside the input. Re-verified live
with the same 3-author scenario: chips and the "Buscar autor…" caret now sit inside one visibly
contained box, matching the resting "Buscar mecánica…" field beside it exactly (chips vs. empty are
just two states of the same control now, not two different-looking things), no console errors.

**Round 8 third follow-up (same round, after user pushback):** user rejected the merged tag-field
fix outright ("this is so weird") and asked directly what alternatives exist and what the common
pattern actually is — the right question, since two rounds of spacing/merging tweaks on the same
inline-chip idea hadn't worked. Stepped back to compare patterns instead of tweaking again:
- **Inline growing tag field** (both prior attempts) is the standard pattern for *assigning* values
  to a record — Gmail's "To:" field, Notion's multi-select property, GitHub's label picker. It grows
  and its input's position shifts as you add values.
- **Checklist-in-dropdown** — fixed search box on top, scrollable checkbox list below, selection
  count shown as a small badge on the field's own label instead of inline chips — is the actual
  standard for *filtering* a large-cardinality field: Amazon/Etsy sidebar filters, Airbnb's own
  filters, Linear, GitHub Issues, Notion filter views all use this shape, not a tag field.

This modal is a filter, not a form, so the tag-field genre was the wrong fit from the start — no
amount of spacing polish was going to fix that. Presented both patterns plus two lighter variants
(un-merge chips from a fixed search box; keep the tag field but truncate to "+N más") with ASCII
previews; user picked checklist-in-dropdown.

Rebuilt Autor/Mecánica as `.fm-checklist`: a bordered box containing a fixed search input (border-
bottom divider) over a `max-height:160px` scrollable list of checkbox rows — nothing in the box
grows or moves as selections change, so there's no rhythm left to break. Selection count now shows
as a small `(3)` suffix on the "AUTOR"/"MECÁNICA" label itself. Selected values pin to the top of
the list when the search box is empty (so a pick stays visible without scrolling); an active search
query shows only matches, selected or not, since pinning during a filtered view would be confusing.
The 160px scroll cap is the piece that actually matters for the real ~400-game catalog — a checklist
this size handles hundreds of authors/mechanics the same way it handles today's 14, unlike a chip
field that would keep growing per pick.

Removed entirely: the suggestion-dropdown positioning/scroll-into-view logic, the outside-click
listener to close it, and the merged `.fm-combobox-field` tag-input CSS from the prior two attempts
— none of it is needed once selection lives in checkbox state instead of a chip list. Re-verified
live: checking "Antoine Bauza" pins it to the top with `AUTOR (1)` and narrows to 1 game; typing
"don" filters the list live without losing input focus; checking "Don Eskridge" while filtered adds
it, and clearing the query shows both picks pinned together (`AUTOR (2)`, "Ver 2 juegos"); "Limpiar
filtros" resets everything including both search queries; no console errors.

**Round 8 confirmed working** — user verified the checklist-in-dropdown live and confirmed it's
correct. All four original Round 8 asks (title/options balance, no icons, Autor/Mecánica balance,
"Limpiar filtros" as a secondary CTA) plus the two follow-up rhythm fixes on the multiselect are
resolved.

## What to Look For (Round 8)
- Does the tighter title→options / looser between-groups rhythm actually read as better "balance,"
  or does the extra 32px between groups make the modal feel emptier/taller than it should?
- With every icon gone (including from the Tipo chips), does anything now feel harder to scan at a
  glance, or does plain text read cleanly on its own?
- Does "Limpiar filtros" now clearly register as the secondary action next to "Ver N juegos"?
- Does the Autor/Mecánica 50/50 grid feel balanced now, or was "no balance" pointing at something
  else in that section (e.g. the combobox interaction itself, not the column widths)?
