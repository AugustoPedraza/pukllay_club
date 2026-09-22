# About Page — Mobile Sticky CTA Bar

The `/quienes-somos` page's mobile-only sticky "Sumate" bar (`.pk-about-cta-bar`, rendered by
`AboutLive` only — never by `Layouts`). Two sketches ran at it back to back: **052** picked a
floating compact pill, which shipped and was then **rejected on real-device UAT for covering the
footer's "Powered by BGG" line**; **053** replaced it. 053's winner D is current. 052 is in
*What to Avoid* — its rejection is the most transferable thing either sketch produced.

## Design Decisions

**Full-width, flush, surfaced bar — not a floating pill.** `position: fixed; left/right/bottom:
0`, opaque `--color-base-100` fill, 1px top border, an upward shadow for elevation. Mobile only:
the base rule is `display: none` and the single trailing `@media (max-width: 480px)` block flips
it to `display: block`.

**Entry trigger reuses the page's existing docked boolean — no new scroll mechanism.** The bar is
absent through the whole hero and slides in the moment the hero's own Sumate scrolls out of view,
driven by `body:has(#about-hero.is-docked)` — the same single boolean `.AboutHeaderMorph` already
computes per frame for the isologo→header morph and the hero eyebrow. No `IntersectionObserver`,
no second listener, no footer-proximity check anywhere in the mechanism.

**Once shown, it never hides again.** 053 was picked with an auto-hide-near-footer leg (like its
A and B variants, the Shopify/Booking.com "Add to Cart" pattern), then refined twice: first the
trigger was tightened with lead time, then the auto-hide was **dropped entirely** — the developer
wants the bar always visible once it appears. There is deliberately no auto-hide rule for this bar
in either scroll direction.

**Footer overlap is solved by reserved clearance, not by hiding the bar.** A document-end
`body:has(.pk-about-cta-bar) { padding-bottom }` sized to the bar's **live-measured** height. The
measurement comes from a page-owned colocated hook, `.AboutCtaBarMeasure` — a `ResizeObserver` on
the bar publishing `Math.ceil(getBoundingClientRect().height)` as `--pk-about-cta-bar-h` on
`documentElement`, mirroring `.CatalogNav`'s `--pk-header-h` publisher verbatim. `Math.ceil` means
the published value is always ≥ the real height, so the reservation can never come up short.

**The reservation is the bar's height and NOTHING else — no additive breathing term.** A `+ 1rem`
"breathing step" was carried into the first port and was a real bug, not merely unfaithful: this
is `body` padding, outside `.pk-footer`'s border-box, so every pixel of it paints the page
background (`--color-base-100`) instead of the footer's page-scoped `--color-base-300` fill. The
bar covers exactly `--pk-about-cta-bar-h`, so the additive term is by construction the one part
that can never be covered. Measured at 390×844: footer bottom 759.39, bar top 775.00 — a 15.61px
permanently-visible band of page background between two differently-coloured surfaces. The
breathing step was never missing; `.pk-footer-row`'s own `--pk-footer-pad-block` already supplies
12px below the BGG line *inside* the footer's fill (measured clearance to the bar's border:
11.61px). **If this boundary ever reads cramped, the lever is
`body:has(.pk-about-cta-bar) .pk-footer { padding-bottom }` — grow the footer's own box, never
the body padding.**

**Hidden means absent, not transparent.** `transform: translateY(110%)` + `opacity: 0` +
`visibility: hidden` at rest. `visibility: hidden` removes the anchor from the tab order and the
a11y tree — opacity alone would leave a focusable invisible link over the page.

**Transitions are declared as four longhands, never the shorthand.** Only the longhand form lets
`visibility` carry its own delay independent of `transform`/`opacity`: on the way **out**
visibility waits `--duration-slow` so the element goes non-visible only after the slide finishes;
on the way **in** it flips instantly (`transition-delay: 0s`, uniform). The reveal rule must
re-declare `transition-delay: 0s` explicitly — without it the higher-specificity rule inherits the
base rule's per-property delay list for properties it doesn't redeclare. (Secondary reason:
`motion_rhythm_test.exs` only audits the `transition:` shorthand for hardcoded timing, so the
longhand form is also this file's established way to stage one property behind another while
keeping every duration token-driven.)

**Border colour is `--color-neutral`, deliberately not `--color-base-300`.** base-300 as a hairline
against base-100 measures 1.406:1 light / 1.19:1 dark — under the 3:1 WCAG 1.4.11 non-text floor.
`--color-neutral` measures 5.785:1 / 7.128:1.

**Token substitutions made when porting the sketch** (following the same precedent as the earlier
port): sketch `--color-bg` → `--color-base-100`; sketch `--color-border` → `--color-neutral` (see
above); the sketch's `color-mix(… var(--color-text) 10% …)` shadow → `--pk-shadow-color` at the
same 10% (this app has no `--color-text` token); the sketch's literal 16px inline padding →
`var(--pk-gutter)`, so the full-width button's edges land on the page's own gutter line
(0.875rem inside the 480px block) instead of 2px off it.

**Deliberate non-goal: no `env(safe-area-inset-bottom)` padding.** `root.html.heex`'s viewport
meta has no `viewport-fit=cover`, so `env()` resolves to 0 here. Revisit only if that meta changes.

**Verification status.** Winner D was human-confirmed at UAT test 20 (result: pass) — but via
fresh headless-Chrome screenshots of the live dev server (375px / 1280px × light / dark) reviewed
by the developer, backed by a clean `test/visual/about_geometry.mjs` run. That is *not* a hands-on
real-device pass, which is precisely the kind of check that caught 052's defect. The sketch itself
was viewed in a 320×620 phone frame.

## CSS Patterns

```css
.pk-about-cta-bar {
  display: none;                 /* mobile-only; flipped to block in the 480px block below */
  position: fixed;
  left: 0; right: 0; bottom: 0;
  z-index: 40;
  margin-block-end: 0;           /* see note below — load-bearing */
  background: var(--color-base-100);
  border-top: 1px solid var(--color-neutral);
  box-shadow: 0 -6px 16px color-mix(in srgb, var(--pk-shadow-color) 10%, transparent);
  padding: 10px var(--pk-gutter);
  transform: translateY(110%);
  opacity: 0;
  visibility: hidden;
  transition-property: transform, opacity, visibility;
  transition-duration: var(--duration-slow), var(--duration-base), var(--duration-slow);
  transition-timing-function: var(--ease-out-soft), var(--ease-standard), linear;
  transition-delay: 0s, 0s, var(--duration-slow);   /* visibility trails the slide-out */
}

/* The reveal. Must follow the base rule in source order. */
body:has(#about-hero.is-docked) .pk-about-cta-bar {
  transform: translateY(0);
  opacity: 1;
  visibility: visible;
  transition-property: transform, opacity, visibility;
  transition-duration: var(--duration-slow), var(--duration-base), 0s;
  transition-timing-function: var(--ease-out-soft), var(--ease-standard), linear;
  transition-delay: 0s;          /* explicit — otherwise inherits the base rule's delay list */
}

@media (max-width: 480px) {
  .pk-about-cta-bar { display: block; }

  /* Document-end clearance, live-measured. Fallback covers only the
     pre-connect first paint, composed from the bar's own declared parts:
     10px top padding + 48px button min-height + 10px bottom padding + 1px border. */
  body:has(.pk-about-cta-bar) {
    padding-bottom: var(--pk-about-cta-bar-h, calc(10px + 48px + 10px + 1px));
  }
}
```

`margin-block-end: 0` is not defensive noise. The shell wraps every page's inner block in
`<div class="mx-auto space-y-4">`, and Tailwind v4's `space-y-*` compiles to `margin-block-end` on
every non-last child (v3 used `margin-top` on non-first). This bar is not the last child
(`#pk-about-morph-mark` and a `<noscript>` marker follow it), so un-neutralised it gets a real
16px margin that pushes a `bottom: 0` fixed box 16px off the viewport edge.

Button geometry is owned entirely by the shared `.pk-sumate-btn` — the bar declares none of it, so
the three Sumate placements can never drift to different sizes:

```css
.pk-sumate-btn { min-height: 48px; padding-inline: 28px; border-radius: 9999px; font-size: 1rem; }
.pk-sumate-btn-solid { background: var(--color-primary); color: var(--color-primary-content);
                       border-color: var(--color-primary); }
.pk-sumate-btn-solid:hover { filter: brightness(1.08); }
```

`.pk-sumate-btn-solid` is a **modifier**, applied through `sumate_cta/1`'s existing caller-class
merge (`class={["btn btn-outline btn-primary pk-sumate-btn", @class]}`) — a caller can add a class
through that merge but cannot remove one. It declares no geometry and no `box-shadow`: elevation
belongs to the bar now (winner D dropped the pill's own shadow and its `pointer-events: auto`,
which existed only to punch through the removed transparent wrapper).

## HTML Structures

```heex
<div id="pk-about-cta-bar" class="pk-about-cta-bar" phx-hook=".AboutCtaBarMeasure">
  <script :type={Phoenix.LiveView.ColocatedHook} name=".AboutCtaBarMeasure">
    export default {
      mounted() {
        this.lastHeight = null
        this.publish = () => {
          const height = Math.ceil(this.el.getBoundingClientRect().height)
          if (height > 0 && height !== this.lastHeight) {
            this.lastHeight = height
            document.documentElement.style.setProperty("--pk-about-cta-bar-h", height + "px")
          }
        }
        this.observer = new ResizeObserver(this.publish)
        this.observer.observe(this.el)
        this.publish()
      },
      destroyed() {
        this.observer?.disconnect()
        document.documentElement.style.removeProperty("--pk-about-cta-bar-h")
      }
    }
  </script>
  <Layouts.sumate_cta class="pk-sumate-btn-solid w-full" />
</div>
```

Both guards in `publish()` are load-bearing, not defensive noise:
- `height > 0` — above 480px the bar is `display: none`, and publishing a 0 during a resize down
  through the threshold would collapse the document-end reservation.
- `height !== this.lastHeight` — the published var feeds `body`'s `padding-bottom`; an
  unconditional write on every callback is how `ResizeObserver` loops start.

`id` exists solely because LiveView requires a DOM id for `phx-hook`. The hook name must be a
**static** string literal — a dynamic expression fails at runtime. A hidden
(`translateY`/`opacity`/`visibility`) bar still measures correctly, so this publishes the right
height even at page top.

## What to Avoid

- **Don't ship a fixed floating overlay with no reserved document-end clearance.** This is 052
  winner B's rejection, verbatim from round-3 UAT: a content-sized solid pill at `bottom: 20px`
  with `box-shadow: var(--shadow-lg)` looked clean in the sketch and **covered the footer's
  "Powered by BGG" attribution line at the real scrolled page bottom** — the one element that
  footer may never hide at any width. The developer's report: *"everything pass except 3. I need a
  full width-bard floating but not a the footer becasue it overlay the disclaimer on the footer."*
  A scrolling sketch frame will not surface this: it only bites at the **true** end of the
  document, against the page's **last** content. Any persistent bottom overlay must reserve
  clearance for itself at the end of the document — treat that as part of the design, not an
  implementation detail.
- Don't reserve that clearance with an in-flow spacer placed before `<footer>`. The original
  `.pk-about-cta-spacer` did exactly that and cleared the *closing band* (which needed none) while
  leaving the footer — the element the fixed bar actually overlays — still covered.
- Don't reserve it with a hard literal either. A `4.5rem` literal was 3px loose against a 69px bar,
  then went 1px **tight** when the button grew to 48px: the direction of the error flipped. Derive
  it (a `calc()` from the bar's own parts) or, better, measure it live.
- Don't add a breathing term to the body reservation. It lands outside the footer's border-box,
  paints the page background, and is by construction the one strip the bar can never cover — a
  permanently visible ~16px band between two differently-filled surfaces. Grow the footer's own
  `padding-bottom` instead.
- Don't solve footer overlap by auto-hiding the bar near the footer, however standard the pattern
  is (Shopify/Booking.com do it). 053 sketched it as variants A and B, picked D with that leg, and
  then removed it in refinement — a CTA that vanishes exactly where the user has finished reading
  is the wrong trade.
- Don't hide a sticky CTA with `opacity: 0` alone — it stays in the tab order and the a11y tree.
- Don't use the `transition:` shorthand when one property needs its own delay; and when a
  higher-specificity reveal rule redeclares some properties, redeclare `transition-delay`
  explicitly or it inherits the base rule's list.
- Don't use `--color-base-300` for this bar's top border — 1.406:1 / 1.19:1, under the 3:1 non-text
  floor. Use `--color-neutral`.
- Don't fill the bar with `--color-base-200` "to separate it from the page." A 6-arm differential
  proved base-100 correct for this bar: base-200 was inert on the reported symptom and worse at
  the real page bottom.
- Don't give a `position: fixed` child of the shell's `space-y-4` wrapper a real margin — neutralise
  `margin-block-end` or a flush bar renders 16px off the viewport edge.
- Don't add `env(safe-area-inset-bottom)` padding here while `root.html.heex`'s viewport meta lacks
  `viewport-fit=cover` — it resolves to 0 and reads as cargo cult.
- Don't promote `.pk-sumate-btn-solid` to a page-wide button style. It is a mobile-overlay
  treatment for this bar; the hero and closing-band Sumate placements stay outline in light mode
  (dark mode fills them for a separate, contrast-driven reason — see `dark-mode-palette.md`).

## Origin
Synthesized from sketches: 053 (4 directions named after real industry patterns — auto-hide
full-width edge-to-edge, inset docked card, static full-width + reserved clearance, hero-synced —
plus the shipped-and-rejected pill reproduced with a live overlap flag; winner D, refined twice
after selection), and 052 (3 alternatives + a "Today" reference; winner B, shipped, then rejected
at UAT round 3 as G-01.5-12). Shipped implementation (`.pk-about-cta-bar`, `.pk-sumate-btn`,
`.AboutCtaBarMeasure`, the 480px block) and the UAT record were read directly from
`assets/css/app.css`, `lib/pukllay_club_web/live/about_live.ex` and `01.5-UAT.md`.
Source files available in: sources/052-about-mobile-cta-alternatives/,
sources/053-about-mobile-cta-bar-footer-clearance/
