---
sketch: 020
name: catalog-index-row
question: "Does a refined chip strip give the mobile shelf-jump index better affordance/rhythm, and does a single header-integrated pattern give desktop an equivalent 'orientation + jump' without reintroducing the second sticky bar sketch 011 (Rounds 7-8) explicitly rejected?"
winner: "C — Hero-ranked chips + mega-menu (Round 2: stripped to the app's real restraint — bare-outline chip, no boxed scroll buttons, bare-icon trigger, unboxed list menu; A/B removed from index.html)"
tags: [navigation, index, mobile, desktop, carousel, header, netflix, minimal]
---

# Sketch 020: Catalog Index Row

## Design Question

Today `.pk-chip-nav` — the horizontal jump-to-shelf strip ("Destacados del club",
"Crea conexiones", "Equipo ganador"...) — only renders on mobile (≤480px, plain
outlined pills, no active state, no scroll-affordance fade). Desktop has no
equivalent at all.

Request: give the mobile row better affordance/balance/rhythm, and build a real
desktop equivalent — inspired by Netflix and similar streaming catalogs.

**Load-bearing precedent (found before sketching):** sketch 011 (Rounds 7-8)
already built and then explicitly *removed* a desktop shelf-jump bar, because
stacking it under the header as a second sticky row read as chrome overload —
"the project's own Netflix reference doesn't have one." All variants below were
designed to respect that finding: none of them add a second persistent sticky
row to the desktop header.

## How to View
open .planning/sketches/020-catalog-index-row/index.html

**Note:** `index.html` now shows only the winning design (C, Round 2) directly —
no tab bar, no A/B/C variant switching. Round 1's three variants are described
below for the historical record only.

## Round 1 — three directions (historical record, no longer in index.html)

- **A: Filled Chips + Header Dropdown** — Mobile: the current pill-chip shape,
  refined (consistent 40px pills, real active state, edge-fade like the
  carousel rails). Desktop: a single "Categorías ▾" trigger in the existing
  header row opens a small dropdown panel listing all 8 shelves — orientation
  and jump both live behind one on-demand overlay, zero added persistent
  chrome.
- **B: Underline Tabs + Non-Sticky Inline Strip** — Mobile: lighter-weight
  underline tabs (same active-state language as sketch 015's nav links)
  instead of filled pill chrome. Desktop: the *same* tab component, always
  visible, but placed in-flow at the top of the page content — literally the
  real estate the removed sort-`<select>` (quick-260824-i8e) vacated — so it
  scrolls away with the page instead of stacking under the sticky header.
- **C: Hero-Ranked Chips + Mega-Menu** — Mobile: chips get real visual
  hierarchy (the "Destacados del club" hero shelf's chip is filled/promoted
  at rest, not just on active) plus explicit prev/next scroll buttons since 8
  items don't all fit. Desktop: a single "Explorar categorías" trigger opens
  a full mega-menu overlay — a 2-column grid of shelf name + one-line
  subtitle, the richest orientation view of the three, still 100% on-demand.

All three shared a scroll-spy (IntersectionObserver): whichever shelf is in
view gets its nav item highlighted automatically — carried forward into the
winner below.

**User picked C**, then asked for a second pass: "more minimalistic and
elegant, following similar balance that the rest of the app [has]."

## Round 2 — Minimalism pass (winner, final)

Grounded in what the *real app* already does, not another sketch guess:
production's actual filter chip is a bare daisyUI `badge` — 1px outline at
rest, filled only when genuinely selected (`chip_class/1`,
`lib/pukllay_club_web/components/filter_modal.ex:494-495`) — and the header's
only other utility control, the theme toggle, is bare-icon-no-box at rest
(sketch 018-B's validated "de-emphasized utility chrome" finding). Round 1's
version of C was heavier than both of those real references. Applied:

1. **Chip: 1px border, not 1.5px; no fill until active.** Active (current
   shelf, via scroll-spy) gets a soft `--color-accent-bg` tint + primary
   border/text — not a solid filled block. Matches the outline-at-rest,
   tint/fill-only-when-true logic of the real filter chip, just reused for
   "you are here" instead of "this is selected."
2. **No separate hero-chip treatment.** Round 1 gave the "Destacados del
   club" chip a permanent filled/promoted look. Cut: the hero shelf already
   announces itself once you land there (primary-colored heading, sketch
   002) — restating it on the index chip too was double-signalling, and the
   rest of the app doesn't stack two hierarchy cues on one element.
3. **No boxed prev/next scroll buttons.** Round 1 added explicit chevron
   buttons over a gradient background at each edge. Cut: the edge-fade alone
   (same mechanism the carousel rails already use) plus native touch/
   trackpad scroll is enough for a fixed 8-item strip — the buttons were
   chrome this row didn't need.
4. **Desktop trigger: bare icon + label, no border/fill at rest.** Round 1's
   trigger was a bordered pill button. Cut to the same restraint as the
   footer theme toggle: transparent background, no border, color-only hover/
   open state, chevron rotates on open.
5. **Mega-menu panel: plain typographic rows, not a bordered card grid.**
   Round 1 boxed every shelf entry in its own bordered/filled card. Cut to a
   hairline-divider list — title + muted subtitle, color-shift on hover, no
   per-item box. The panel container itself still carries a surface + shadow
   (unavoidable — it's an overlay), but its *contents* stay unboxed.

Verified live (headless Chrome, DOM/class assertions — this automation
session's compositor doesn't paint screenshots or animate `scrollBehavior:
"smooth"`, confirmed via an `"auto"` vs `"smooth"` A/B test that isolated it
to the session, not the sketch):
- 8 chips render, zero `.chip-scroll-btn` elements remain.
- Clicking a chip sets `.is-active` on exactly that chip and computes the
  correct scroll offset (`target.offsetTop − live header height − 8`,
  re-measured per click so mobile's taller header and desktop's shorter one
  both land correctly).
- Desktop trigger computes to a fully transparent background and `border:
  none`.
- Mega-menu opens on trigger click, closes on item click / backdrop click /
  Escape; items carry no top/left border (confirms the unboxed-list
  treatment actually shipped, not just described).

## What to Look For

- Does the mobile chip row now read as "this app's chip," not a separate
  component with its own visual rules?
- Does the desktop trigger feel appropriately quiet next to the theme
  toggle's own bare-icon restraint — or does it still ask for more visual
  weight to be discoverable?
- Does the unboxed mega-menu list still give enough structure/scannability
  without the per-item card boundary Round 1 had?
- Scroll the frame directly (not just clicking) — the scroll-spy should
  highlight the current shelf's chip/menu-item automatically in both
  viewports.
