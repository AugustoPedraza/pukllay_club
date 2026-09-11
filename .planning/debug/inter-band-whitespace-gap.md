---
status: diagnosed
trigger: "there are space between bands"
created: 2026-09-08
updated: 2026-09-08
audit_acknowledged:
  milestone: v1.0
  at: 2026-09-11
  status: diagnosed
---

## Current Focus

bug_class: Bohrbug (deterministic, always reproduces at the same DOM boundary, no timing/concurrency)

known_pattern_candidate: |
  Partial match against knowledge-base entry `search-right-align-mobile-cycle-5`
  ("the entire 80px gap was `<main class="py-20">` — a flat desktop-scale padding shipped
  unconditionally") — same SHAPE: an unremarkable spacing utility on the SHARED SHELL
  (layouts.ex) being the whole of a gap the user attributes to the PAGE. Treat as
  hypothesis candidate, test first.

hypothesis: |
  H1: The gap is `margin-block-end: 1rem` (16px) contributed by
  `<div class="mx-auto space-y-4">` in `layouts.ex:670`, the shell wrapper around
  `render_slot(@inner_block)`. Every `<section class="pk-band">` on the About page is a
  DIRECT child of that div, so Tailwind v4's `space-y-4` puts 16px of margin below each
  non-last band. That margin paints `--color-base-100` (the page background), so it reads
  as a white strip between the tint band (base-200) and the dark FAQ band (primary).

test: |
  Render /quienes-somos in a real browser (CDP), measure
  `faq.getBoundingClientRect().top - tintBand.getBoundingClientRect().bottom`, and read
  `getComputedStyle(tintBand).marginBlockEnd`.

expecting: |
  CONFIRMS H1 if gap == 16px AND marginBlockEnd == 16px AND `.pk-band` /
  `.pk-band-tint` / `.pk-band-dark` themselves declare zero margin.
  REFUTES H1 if the gap is a different magnitude, or the margin comes from a
  page-owned `.pk-*` rule instead of the shell's utility.

result: |
  H1 CONFIRMED, and confirmed as the SOLE cause by differential test (see Evidence E-05).
  Measured gap == 16px, tint band marginBottom == 16px, FAQ marginTop == 0px. Neutralising
  ONLY the space-y-4 margin drives the gap to exactly 0px with no residual; neutralising
  .pk-band's own padding instead leaves the gap fully intact.

next_action: |
  DIAGNOSE-ONLY MODE (goal: find_root_cause_only) — investigation is complete, no fix applied.
  Hand the root cause to the plan-phase --gaps flow for G-01.5-2.

rca_branching:
  candidate_causes:
    - "code: shell wrapper `<div class=\"mx-auto space-y-4\">` (layouts.ex:670) puts margin-block-end: 1rem on every non-last child — CONFIRMED"
    - "code: `.pk-band` / `.pk-band-tint` / `.pk-band-dark` declare their own margin — REFUTED (E-03)"
    - "code: the gap is band PADDING, not margin — REFUTED by control experiment (E-05)"
    - "config: Tailwind v4.1 changed space-y-* from margin-top-on-`~`-siblings to margin-block-end-on-`:not(:last-child)` — CONTRIBUTING CONTEXT only, changes WHICH element carries the margin, not whether the gap exists (E-02)"
    - "environment: browser UA default `<section>` margin — REFUTED (Tailwind preflight in @layer base zeroes it; every band's computed marginTop is 0px, E-03)"
    - "data: content length changing band heights — REFUTED, gap is a fixed 16px at 390/768/1280px regardless of content (E-06)"
  and_gate: |
    Split answer, and the distinction matters for the fix.
    EXISTENCE of the gap: single cause, AND-gate NO — removing the shell margin alone takes it
    to 0px with zero residual (E-05). No second condition is required for the defect to exist.
    VISIBILITY of the gap: AND-gate YES — the 16px strip has existed at EVERY band boundary
    since commit 320fc4b (2026-08-24), but it only becomes a *reportable* stripe where it
    separates two bands that both paint a non-base-100 background. D-14 (commit 4d77558,
    2026-09-08, today) is what put base-200 immediately above #faq's primary and thereby
    exposed it. So D-14 is the EXPOSURE condition, not a second root cause — correctly
    recorded here rather than folded into root_cause.

## Symptoms

expected: |
  Per phase 01.5 design decision D-14, the full-page scroll should show bands alternating
  plain -> tint -> dark (FAQ) -> plain -> tint, with each section visibly separated by
  background color/tint change alone — not by an unintended blank/white gap between bands.
actual: |
  User reported (verbatim): "there are space between bands" — with a screenshot showing a
  visible white/blank horizontal strip of whitespace between the "Qué hacemos / Nuestra
  historia" two-column band (light background) and the dark purple FAQ band immediately
  below it. The gap looks like unintended spacing (margin/padding mismatch, wrapper div gap,
  or missing full-bleed background) rather than an intentional visual separator.
errors: None reported
reproduction: |
  Visit /quienes-somos on desktop, scroll to the boundary between the "Qué hacemos / Nuestra
  historia" section and the FAQ section immediately below it. A gap of blank/background-colored
  whitespace is visible between the two bands instead of them sitting flush.
started: Discovered during end-of-phase UAT for phase 01.5 (2026-09-08)

## Eliminated

- hypothesis: "`.pk-band` (or `.pk-band-tint` / `.pk-band-dark`) declares its own margin"
  evidence: |
    `assets/css/app.css:2582` — `.pk-band { padding: 4.5rem 0; }` is the rule's ENTIRE body,
    no margin. `.pk-band-tint` (:2741) declares only `background: var(--color-base-200)`;
    `.pk-band-dark` (:2719) only `background` + `color`. Confirmed live: every one of the five
    `section.pk-band` elements computes `marginTop: 0px`, and their `marginBottom: 16px` is
    traced to the shell utility, not to any `.pk-*` rule.
  timestamp: 2026-09-08

- hypothesis: "The gap is band vertical PADDING (a padding/background scoping mismatch)"
  evidence: |
    Control experiment E-05: injecting
    `.pk-band { padding-top: 0 !important; padding-bottom: 0 !important; }`
    changed the bands' computed padding from 72px to 0px and shrank the document by 576px,
    yet the tint->#faq gap stayed at exactly 16px. Padding is not the gap. (Background does
    paint the padding box, so a padding mismatch could never have produced a strip anyway.)
  timestamp: 2026-09-08

- hypothesis: "A browser UA default margin on `<section>` is leaking through"
  evidence: |
    Tailwind preflight (`@layer base`, compiled app.css:44+) zeroes element margins, and every
    band measures `marginTop: 0px`. A UA margin would also have shown as a symmetric
    top+bottom value, not the one-sided 16px actually observed.
  timestamp: 2026-09-08

- hypothesis: "The bands are missing a full-bleed background (background not reaching the edge)"
  evidence: |
    Backgrounds are correct and full-width: `.pk-band` sections are direct children of
    `<div class=\"mx-auto space-y-4\">` which has NO width cap (the `max-w-7xl` cap lives on
    `.pk-band-inner`, one level deeper). The tint band measures
    `backgroundColor: rgb(243, 236, 250)` == `--color-base-200` `#F3ECFA`, and #faq measures
    `rgb(61, 9, 109)` == `--color-primary` `#3D096D`. The strip is vertical dead space between
    two correctly-painted boxes, not an unpainted region of either box.
  timestamp: 2026-09-08

- hypothesis: "This is a regression introduced by plan 01.5-04 / D-14"
  evidence: |
    `git log -S 'mx-auto space-y-4' -- lib/pukllay_club_web/components/layouts.ex` -> `320fc4b`
    (2026-08-24). `git log -S 'pk-band-tint' -- assets/css/app.css` -> `4d77558` (2026-09-08).
    The 16px gap predates D-14 by ~2 weeks and has been present at every About-page band
    boundary since the shell was built. D-14 EXPOSED it (by putting two painted backgrounds on
    either side of it); it did not create it.
  timestamp: 2026-09-08

## Evidence

- timestamp: 2026-09-08
  id: E-01
  checked: "`lib/pukllay_club_web/components/layouts.ex:660-673` — the `<main>` block wrapping `render_slot(@inner_block)`"
  found: |
    ```heex
    <main class={[...]}>
      <div class="mx-auto space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>
    ```
    `space-y-4` is on the SHARED shell wrapper, unconditional — no attr (`fullbleed`,
    `boundary_collapse`, `bottom_collapse`) gates it.
  implication: |
    Whatever a page passes as its inner block becomes a direct child of a `space-y-4` container.
    For the About page those children are the `.pk-band` sections themselves.

- timestamp: 2026-09-08
  id: E-02
  checked: "compiled `priv/static/assets/css/app.css:3204-3210` — what `space-y-4` actually emits under Tailwind v4"
  found: |
    ```css
    .space-y-4 {
      :where(& > :not(:last-child)) {
        --tw-space-y-reverse: 0;
        margin-block-start: calc(calc(var(--spacing) * 4) * var(--tw-space-y-reverse));
        margin-block-end: calc(calc(var(--spacing) * 4) * calc(1 - var(--tw-space-y-reverse)));
      }
    }
    ```
    with `--spacing: 0.25rem` (compiled app.css:10) -> `margin-block-end: 1rem = 16px`.
  implication: |
    Tailwind v4 puts the spacing as `margin-block-END` on every NON-LAST child (v3 used
    `margin-top` on `~` siblings). So the margin is carried by the band ABOVE the boundary —
    the tint "Qué hacemos/Historia" section — which is why `#faq` itself measures
    `marginTop: 0px` and looks innocent. This is the detail that makes the cause easy to
    misattribute to the FAQ band.

- timestamp: 2026-09-08
  id: E-03
  checked: "Live CDP measurement of every direct child of `main > div.space-y-4` at 1280x900 on the running dev server"
  found: |
    | # | element                        | marginBottom | backgroundColor        | top    | bottom |
    |---|--------------------------------|--------------|------------------------|--------|--------|
    | 0 | div.mx-auto...space-y-6 (hero) | 16px         | transparent            | 145    | 673    |
    | 1 | section#fotos.pk-band          | 16px         | transparent            | 689    | 1373   |
    | 2 | section.pk-band.pk-band-tint   | 16px         | rgb(243, 236, 250)     | 1389   | 1789   |
    | 3 | section#faq.pk-band.pk-band-dark | 16px       | rgb(61, 9, 109)        | 1805   | 2449   |
    | 4 | section.pk-band                | 16px         | transparent            | 2465   | 3018   |
    | 5 | section#cierre.pk-band.pk-band-tint | 16px    | rgb(243, 236, 250)     | 3034   | 3934   |
    Every band: `marginTop: 0px`, `paddingTop/Bottom: 72px`.
    All four consecutive band-to-band gaps measure exactly **16px**
    (fotos->tint, tint->faq, faq->plain, plain->cierre).
  implication: |
    The defect is uniform across the whole page, not local to the reported boundary. The user
    reported it at tint->#faq because that is the ONLY boundary where the white strip sits
    between two SATURATED backgrounds. At fotos->tint and faq->plain one side is transparent
    (i.e. white), so the same 16px reads as ordinary band padding and is invisible.

- timestamp: 2026-09-08
  id: E-04
  checked: "The reported boundary specifically, plus the ancestor background chain above `#faq`"
  found: |
    boundary: gapPx 16, prevMarginBottom "16px", faqMarginTop "0px",
              prevBg rgb(243,236,250), faqBg rgb(61,9,109)
    ancestor chain from #faq upward, computed backgroundColor:
      div.mx-auto.space-y-4  -> rgba(0,0,0,0)   (transparent)
      main.pb-20.pt-8...     -> rgba(0,0,0,0)
      div.phx-connected      -> rgba(0,0,0,0)
      body                   -> rgba(0,0,0,0)
      html                   -> rgb(255,255,255)   <-- the painter
    Tokens: `--color-base-100: #FFFFFF`, `--color-base-200: #F3ECFA`, `--color-primary: #3D096D`.
  implication: |
    Nothing between the band and `<html>` paints, so the 16px margin strip shows `<html>`'s
    `#FFFFFF` — literally the "white/blank horizontal strip" in the user's screenshot, sitting
    between `#F3ECFA` above and `#3D096D` below. Mechanism and observed pixel colour agree.
    Dark theme is affected identically (the strip becomes `--color-base-100: #170A26` between
    `#22103A` and `#A97FD1`) — a dark stripe rather than a white one, but the same 16px defect.
    Relevant to UAT walkthrough item (7), the dark-theme band legibility re-check.

- timestamp: 2026-09-08
  id: E-05
  checked: "Differential / falsification experiment via injected stylesheet, same page load, measure -> mutate -> restore -> control"
  found: |
    BASELINE                                     gap = 16px  (docHeight 4225)
    EXP1  margin-block-end: 0 on space-y-4 kids  gap =  0px  (docHeight 4129)
    RESTORED (style element removed)             gap = 16px  (docHeight 4225)
    EXP2  CONTROL: .pk-band padding -> 0         gap = 16px  (docHeight 3649)
    docHeight delta for EXP1 = 96px = 6 in-flow non-last children x 16px — the arithmetic
    closes exactly, with no unexplained residual.
  implication: |
    Decisive. Removing ONLY the shell's `space-y-4` margin closes the gap completely (0px, not
    "smaller"), and the effect is reversible on the same page load. The control proves the gap
    is margin, not padding. The shell utility is the entire cause; nothing else contributes.

- timestamp: 2026-09-08
  id: E-06
  checked: "Same measurement re-run at 390px, 768px and 1280px viewport widths"
  found: "gap = 16px, tint marginBottom = 16px, faq marginTop = 0px — identical at all three widths."
  implication: |
    Unconditional: no media query gates `space-y-4`, so the defect ships to mobile and desktop
    alike. Rules out any breakpoint/viewport-band explanation (the shape of three prior bugs in
    this repo's knowledge base) and rules out content-length/data as a factor.

- timestamp: 2026-09-08
  id: E-07
  checked: "Cascade-layer position of the two competing rules in the compiled stylesheet"
  found: |
    `@layer theme, base, components, utilities;` declared at compiled app.css:3.
    `@layer utilities { ... }` spans lines 192-3920; `.space-y-4` sits INSIDE it at :3204,
    and its selector is `:where(& > :not(:last-child))` — the `:where()` contributes ZERO
    specificity.
    `.pk-band` sits at compiled :4999, UNLAYERED (after every layer block closes).
  implication: |
    An unlayered `.pk-*` rule beats any rule inside a cascade layer regardless of specificity —
    the hazard app.css's own top-of-file note warns about works in the fix's favour here. A
    page-owned `margin-block-end: 0` on `.pk-band` would win deterministically with NO
    `!important` needed. (Confirming this now is what makes the suggested fix direction sound
    rather than speculative — it does not constitute applying the fix.)

- timestamp: 2026-09-08
  id: E-08
  checked: "`git log -S` for both competing change dates, and the set of `Layouts.app` callers"
  found: |
    `mx-auto space-y-4` in layouts.ex  -> `320fc4b` (2026-08-24, Phase 00-01.1 shell sync)
    `pk-band-tint` in app.css          -> `4d77558` (2026-09-08, plan 01.5-04, D-14)
    `Layouts.app` callers: catalog_live/index.ex:886, catalog_live/show.ex:261,
    about_live.ex:52 — all three pass `fullbleed`, so `fullbleed` cannot discriminate.
    catalog_live/show.ex:292 carries an explicit comment: "The inner `space-y-4` div reproduces
    the exact gap Layouts.app's own [wrapper provides]" — the catalog pages DEPEND on the 16px.
  implication: |
    Two constraints on any fix. (1) This is a latent pre-existing defect exposed by D-14, not a
    D-14 regression — reverting D-14 would hide the symptom without touching the cause.
    (2) The 16px rhythm is LOAD-BEARING for the two catalog pages, so deleting `space-y-4` from
    the shell, or gating it on `fullbleed`, would break them. The fix must be scoped to the
    full-bleed band recipe (`.pk-band`) or to a new explicit opt-out attr, not to the shared
    default.

- timestamp: 2026-09-08
  id: E-09
  checked: "The four D-14 tests in `test/pukllay_club_web/live/about_live_test.exs` (describe: \"About page band background alternation (plan 01.5-04, D-14)\", ~lines 1256-1330)"
  found: |
    All four are CSS-SOURCE / class-attribute oracles: `.pk-band-tint` declares exactly one
    property; `.pk-band-dark` unchanged; `section.pk-band` class attributes in document order
    yield plain/tint/dark/plain/tint; exactly 2 tint + 1 dark and no section carries both.
    Not one of them observes vertical geometry or margins.
    01.5-04-SUMMARY.md's own verification block concedes this, deferring "whether adjacent
    sections actually READ as visually separated" to the end-of-phase human walkthrough.
  implication: |
    The defect was structurally invisible to the gate that was supposed to cover D-14. The
    tests assert the bands have the right COLOURS; the bug is that they are not TOUCHING.
    Consistent with the four prior knowledge-base entries: nothing in this toolchain observes
    rendered geometry, so a 16px stripe fails nothing in CI.

## Resolution

root_cause: |
  `lib/pukllay_club_web/components/layouts.ex:670` — the shared `Layouts.app` shell wraps
  `render_slot(@inner_block)` in `<div class="mx-auto space-y-4">`. Under Tailwind v4 that
  utility compiles to `:where(& > :not(:last-child)) { margin-block-end: 1rem }` (16px, with
  `--spacing: 0.25rem`), so EVERY direct child of the shell wrapper except the last carries
  16px of bottom margin.

  The About page's five `<section class="pk-band">` bands are direct children of that wrapper,
  so each one is pushed 16px away from the next. `.pk-band` itself declares only
  `padding: 4.5rem 0` and no margin, and `.pk-band-tint`/`.pk-band-dark` declare only
  background/colour — so the bands never had a chance to own their own outer spacing; the
  shell owns it, invisibly, from another file.

  Margin is outside the background box, so nothing paints in that 16px strip. The nearest
  painting ancestor is `<html>` at `--color-base-100` (`#FFFFFF` light / `#170A26` dark),
  which is exactly the blank stripe in the screenshot, sitting between the tint band's
  `#F3ECFA` and `#faq`'s `#3D096D`.

  The gap is identical (16px) at all four band boundaries and at 390/768/1280px. It became
  REPORTABLE only at the tint -> `#faq` boundary because that is the sole place where the
  strip separates two saturated backgrounds; at the other three boundaries at least one
  neighbour is transparent, so the same 16px reads as ordinary band padding.

  Timeline: the `space-y-4` wrapper landed 2026-08-24 (`320fc4b`); `.pk-band-tint` landed
  2026-09-08 (`4d77558`, D-14). This is therefore a latent pre-existing shell defect that
  D-14 exposed, NOT a D-14 regression — the fix belongs at the band/shell spacing boundary,
  not in D-14's colour work.

fix: "NOT APPLIED — diagnose-only mode (goal: find_root_cause_only)."

verification: "n/a — no fix applied. Root cause established by differential test E-05 (isolating the shell margin drives the gap to exactly 0px; the padding control leaves it at 16px)."

files_changed: []

suggested_fix_direction: |
  Give `.pk-band` ownership of its own outer spacing, the same way it already owns its inner
  spacing — i.e. add a `margin-block-end: 0` (or `margin: 0`) declaration to the existing
  unlayered `.pk-band` rule at `assets/css/app.css:2582`, with a comment naming
  `layouts.ex:670`'s `space-y-4` as the thing it is cancelling and why. E-07 confirms this
  wins deterministically without `!important`, because `.pk-band` is unlayered and
  `space-y-4` lives inside `@layer utilities` behind a zero-specificity `:where()`.

  Constraints the fixer must respect (all evidenced above, not guesses):
  - Do NOT delete `space-y-4` from `layouts.ex`, and do NOT gate it on `fullbleed`. All three
    `Layouts.app` callers pass `fullbleed`, and `catalog_live/show.ex:292` documents that the
    catalog pages deliberately reproduce that exact 16px gap (E-08).
  - Do NOT treat this as a D-14 problem. Reverting or retuning the tint would hide the stripe
    without removing the 16px, which still exists at all four boundaries (E-03, E-08).
  - The FIRST wrapper child (the hero `<div class="mx-auto ... space-y-6">`) also carries the
    16px, so a `.pk-band`-scoped fix leaves hero -> `#fotos` at 16px. That gap is invisible
    (both sides transparent) and is arguably desired boundary spacing — decide deliberately
    rather than by omission.
  - `#cierre` is the last `.pk-band` and also carries the 16px below it. Zeroing it removes
    16px from the space between the Cierre band and the footer — which OVERLAPS the sibling
    investigation G-01.5-3 ("Cierre band whitespace"). Coordinate: 16px of G-01.5-3's reported
    bottom whitespace is this same margin, but it is only a small fraction of the ~291px
    measured below `#cierre`, so G-01.5-3 has a separate primary cause of its own.
  - A recurrence guard for this class needs a GEOMETRIC oracle (adjacent `.pk-band` rects must
    touch), not another CSS-source assertion — E-09 shows all four existing D-14 tests are
    colour/class oracles and are structurally incapable of catching a spacing defect.
