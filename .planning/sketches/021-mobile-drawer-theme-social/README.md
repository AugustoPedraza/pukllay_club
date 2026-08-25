---
sketch: 021
name: mobile-drawer-theme-social
question: "How should the mobile drawer's bottom block (theme control + social links) look and read — is a switcher a better mobile component than the current 3 bare icon buttons, does it match the app's real spacing rhythm, does it communicate that Tema (a config) and social links (destinations) are different kinds of things without adding visual weight, is it correct that the drawer covers the header/logo when open, and should Tema read as a small centered drawer-footer rather than another list row?"
winner: "E1 — Icon-Only, Centered (Round 6)"
tags: [drawer, mobile, theme-toggle, social, rhythm, hierarchy, navigation]
---

# Sketch 021: Mobile Drawer — Theme + Social

## Design Question

Polish the mobile nav drawer's bottom block (`.pk-drawer-bottom`: divider + theme toggle + social
links) — better balance, rhythm consistent with the rest of the mobile UI, whether a "switcher"
component beats the current 3-button bare-icon theme toggle, and (as of Round 3) whether the block
correctly communicates that Tema and social links are different *kinds* of things, not two peer
sections.

## Grounded in a real bug

While reading `lib/pukllay_club_web/components/layouts.ex` and `assets/css/app.css` to prep this
sketch, found that `.pk-drawer-utility`'s CSS is `justify-content: space-between` — it pushes the
"Tema" label to the left edge and the icon buttons to the right edge of the drawer's full width,
even though the component's own doc comment claims it already groups them as one atom "the same
way" the footer does. The footer's real fix (`.pk-footer-theme`, shipped on this branch) instead
wraps label + toggle with a tight `gap: var(--pk-footer-gap-item)` (8px) — the drawer never got
the equivalent treatment. The drawer's social row also uses incidental `0.75rem`/`0.5rem` spacing
that doesn't map onto the app's real 4-tier proximity scale (item 8px / list 16px / group 24px /
cluster 32px, `--pk-footer-gap-*` in `app.css`). Every round below fixes this bug; they differ in
component shape, spacing, and (Round 3) semantic hierarchy.

## How to View
```
open .planning/sketches/021-mobile-drawer-theme-social/index.html
```
The live file holds only the final winning design (Round 6's E1) — every earlier round's variants
were removed from `index.html` after being superseded, following this project's established
sketch convention of pruning non-winning variants once a direction converges. The full history
below (Rounds 1-6) documents what was tried and why, recoverable without git archaeology.

## Round 1 — dramatic differences (component-type question)

Three variants, exploring whether the theme control should change shape entirely:

- **A: Refined Atom** — same 3 bare icons, grouped as one pill-backed atom with the "Tema" label
  (item-gap), plus a matching bordered-circle + "Seguinos" label treatment for social links. No
  new component type — a rhythm/balance fix only.
- **B: Segmented Switcher** — the 3 icons move into one bordered track with a sliding
  active-indicator (the literal "switcher" the design question raised), still preserving
  system/claro/oscuro parity. Social links become a matching capsule directly below it.
- **C: Simplified Switch** — a true binary light/dark switch; "usar tema del sistema" demoted to a
  small secondary link underneath. Social links become a parallel labeled settings row ("Seguinos"
  + icons), matching the theme row's height/rhythm.

**Picked: A's direction** (bare icons, no new switch/track component) — but flagged as still too
heavy: "Currently is taking like 25% of the space. This must be something subtle." Measured
against the real DOM: A's bottom block (divider + theme atom + social row) rendered at **183px,
28.7%** of the 638px drawer height — confirming the estimate. For reference, the entire 2-item
nav-links list above it is only 88px.

## Round 2 — subtler refinements within A (2026-08-24)

Three tighter variants, same bare-icon philosophy, pulling back the pill background, the
group-tier (24px) spacing, and one or both visible labels:

- **A1 — Merged Single Row:** theme + social share one flat row, no visible labels (icons +
  `aria-label` only). **Measured: 59px, 9.2%.**
- **A2 — Tightened, 1 Label:** two rows, but only "Tema" keeps a visible label (the one control
  whose icon alone is ambiguous); "Seguinos" dropped, matching how social already ships
  everywhere else with no label. **Measured: 109px, 17.1%.**
- **A3 — Micro-Eyebrows:** both rows keep a label, demoted to a 10px uppercase eyebrow stacked
  tightly above its icons instead of beside them. **Measured: 147px, 23.0%.**

A1 required shrinking icons further than A2/A3 (26px theme / 24px social, vs. 32/28) to fit the
merged row inside the drawer's real 213px inner width without horizontal overflow — a vertical
divider between the two icon groups was tried first but its column collapsed to 0px under flex
shrink before the icons did, so that layout used a bare gap instead.

**Picked: A3's direction** (both rows labeled) — but flagged a real problem: both rows used the
*identical* pattern (eyebrow label above an icon row), so they read as "two sections of the same
[thing]" even though they aren't. Social links are destinations you tap to leave the app; Tema is
a config control that changes how the current page looks. Social links were also called out as
the more important of the two — needing different representation, not just different size.

## Round 3 — Content vs. Control

Differentiates the two rows by **shape**, not just size or labeling, so the distinction reads
without relying on text:

- **Social — first, bare, unlabeled.** No eyebrow, no container, full-strength icon color (not
  the faded/muted treatment used for Tema). Placed immediately after the divider, right below the
  real nav links — reads as a continuation of "places you can go." Matches how social already
  ships everywhere else in the app: icons + `aria-label` only, never a visible text label.
- **Tema — last, contained, quiet.** Wrapped in its own small pill (`var(--color-surface)`
  background, label + icons together as one chip). Nothing else in the drawer uses this shape —
  the container itself is what marks it as a control, borrowing the "this is a widget" signal
  Round 1's segmented-track (B) and switch (C) had, scoped down to a small chip instead of
  full-width chrome. It sits at the drawer's quietest position: the very last thing, after social.

**Measured:** divider + social row + capsule renders at 113px — 17.7% of the drawer's height
(down from Round 1's 28.7%, same order of magnitude as Round 2's A2/A3).

**Picked directionally**, but flagged: "still looks like theme has major weight" — the filled pill
was the single most visually prominent shape in the block (nothing else on the page has a filled
background), so it drew the eye more than the more-important social links above it. Two more
questions raised: should Tema take the full width, and is it correct that the drawer opens from
the right and covers the logo?

## Round 4 — Full-Width Row, No Container

**Tema drops the container.** It's now a full-width row using the *exact* same edge-to-edge
recipe and padding as `.nav-drawer-links a` above it (same negative-margin bleed, same
`var(--space-2) var(--space-4)` padding, same 44px height) — it borrows the list's own rhythm
instead of having a shape of its own. What still marks it as "a control, not a link" is the
*content* pattern, not a container: a trailing icon-group instead of a trailing chevron — the
same distinction real settings screens use (adjust here, right on this row / navigate away,
follow the chevron). Social stays a compact bare-icon cluster, not full-width — it isn't a
settings-style label+control row, so it shouldn't borrow that shape.

**Drawer covering the logo:** checked the real shipped CSS — `.pk-drawer` is already `top: 0`
today, so it already covers the header (and the logo) whenever it's open; this isn't something
introduced by the sketch. It's also a common pattern (WhatsApp, Instagram, most hamburger drawers
work this way) precisely because the drawer immediately presents its own "Menú" title + close
(✕) — you're never in doubt about where you are or how to get back. The live sketch now has a
toggle above the phone frame that swaps the drawer between `top: 0` (covers header, today's real
behavior) and tucked below the measured header height (logo stays visible) — built so this can be
judged by comparison instead of from a description alone. No recommendation to change the real
app's behavior is made here; it's included as a documented finding for a separate decision.

**Measured:** Tema's row alone is 48px; the whole block (divider + social + Tema row) is 111px —
17.4% of the drawer's height.

**Drawer-covers-header: confirmed.** "Keep covering the header, this is good." Matches the real
shipped app's current `top: 0` behavior. The comparison toggle built to judge this is removed from
the live file now that it's decided.

**But Tema still felt heavy** — "Why still Tema label take too much weight? that breaks the
balance and rhythm" — even without the pill, plus a direct question: is a divider between social
and Tema better?

## Round 5 — Grouped, Not Spread

Re-reading the CSS turned up the actual cause: `.theme-row-final` used
`justify-content: space-between` — **the exact same bug Round 1 fixed on the real shipped
`.pk-drawer-utility`, reintroduced here** when Round 4 borrowed the nav-links' full-width row
shape. It pinned "Tema" to the row's far-left edge and its icon-group to the far-right edge,
leaving the label isolated with nothing anchoring it — an unattached bold word is what read as
disproportionate weight, not its font size or color.

**Fix:** label + icons are one tight group again (item-gap, 8px), left-aligned, with real
trailing whitespace on the row — it doesn't need to fill edge-to-edge the way a nav link does.
The label is also demoted to `text-xs`/muted so it sits in the same "weight class" as its own
faded icons, instead of matching the bold `text-sm` nav-link labels above it (which is what the
eye was actually comparing it against).

**Divider added between social and Tema** — reuses the same `.rhythm-divider-tight` rule already
separating the nav links from this whole block, rather than inventing a new lighter-weight rule.
Recommended and kept: once the pill was gone, social and Tema were separated only by an 8px gap
with no other cue between them — a hairline is a clean boundary for near-zero extra ink, cheaper
than trying to make spacing alone carry the whole distinction.

**Measured:** whole block (divider + social + divider + Tema row) is 144px — 22.6% of the
drawer's height. Up from Round 4's 111px/17.4% — the added divider plus its own margins account
for the difference.

## What to Look For (Round 5, history)
- Does "Tema" still draw the eye disproportionately, or does grouping it with its icons resolve that?
- Does the divider read as a clean boundary, or as one rule too many now that the label itself is quieter?
- Does the row's trailing whitespace (no longer filled edge-to-edge) look intentional/quiet, or does it look unfinished?

**Feedback:** "That is better, but the Tema label looks 'overloading'. Could that be centered like
a 'footer' of that drawer? alternatives?" — even grouped and muted, the label + icons still read
as another list row competing with the real nav links above it.

## Round 6 — Centered Footer, 3 Alternatives → Winner

Stopped treating Tema as a row entirely and tried it as a small, centered signature strip at the
very bottom of the drawer instead — the way a page footer's legal line sits centered and quiet,
separate from the content above it. Built a tab switcher (social + dividers held constant) so
three alternatives could be compared directly:

- **E1 — Icon-only, centered.** No text at all — mirrors how social already ships with zero
  visible label. Most minimal; least discoverable if "Tema" as a word matters for a first-time
  visitor.
- **E2 — Caption below, centered.** Icons centered, "Tema" underneath in the exact scale/weight
  as the real footer's legal line (`.pk-footer-meta`, 0.75rem muted) — reused, not invented.
  Reads closest to an actual page-footer signature.
- **E3 — Centered inline.** Same label-beside-icons pairing as Round 5, but centered as one unit
  instead of left-aligned — isolates "does centering alone fix it" as its own variable.

*(An initial comparison used a `#measure-part1`/`#measure-part2` wrapper pair to exclude the
sketch-only tab switcher from each variant's measured height — those wrapper `<div>`s were plain
blocks, not flex items, so their children's margins collapsed through them, undercounting every
figure reported at the time (104px/126px/104px). The final numbers below, measured directly
against the drawer's real flex-item container after pruning to the winner, are the correct ones.)*

**Picked: E1 — Icon-Only, Centered.** Final, no more open questions on this design.

## Final: E1 — Icon-Only, Centered

Social links lead (bare, full-color, first, no label) → divider → Tema trails as three small
centered icon buttons with no label, no container, and no row shape of its own — mirroring
exactly how social itself carries no visible text. Discoverability rests on the monitor/sun/moon
icons plus each button's `aria-label`, the same contract social already ships under everywhere
else in the app.

**Measured:** divider + social + divider + Tema icons is 136px — 21.3% of the drawer's height,
down from the first working version's 183px / 28.7%.
