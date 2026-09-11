# Component System — Pills & Chips

Cross-cutting, not page-specific: the same "small labeled shape" appears on the detail page
(facts pills, Mecánicas/Temáticas chips, editorial hashtags), on the catalog page (active-filters
chip row, see `filter-search.md`), and in the filter modal (facet/scalar chips) — five
independently hand-tuned implementations existed with no shared base before this sketch (Phase
01.2 gap-closure round 3, UAT gap G-01.2-15: "why is there a kind of pill for difficulty, time and
# of players, but another kind of pills for mecanicas, temáticas? ... We need 1 representation and
its variants").

## Design Decisions

**The dividing line is interactivity, not content type.** The instinct is to unify by giving
every pill/chip the same chrome (same border, same fill) — five rounds of exploration found that's
the wrong axis. The real split is: **does tapping this do anything?**

- **Informational** (facts row, Mecánicas/Temáticas, editorial hashtags) — nothing happens on tap.
  These render as a bordered outline pill (see the supersession note just below) — transparent
  fill, real 1px border at rest, no tap affordance.
- **Interactive** (catalog active-filters chip, filter-modal facet/scalar chip) — tapping removes
  or toggles something. These keep a real pill shape with an **always-visible 1px border at rest**
  (not just on `:hover`), a 44px minimum touch height (WCAG 2.5.5 AAA target size — don't shrink
  this to "balance" sizes against the informational pills; it's an accessibility floor, not a
  style choice), and a genuine `:active` press-feedback (scale-down + background flash).

**Superseded (sketches 039-041, later + UAT-validated on this exact content): informational pills
are bordered outline pills, not flat/borderless.** This file originally called for flat, fully
borderless, middot-separated informational pills (no background, no border, no radius). Sketches
039-041 — a later, more focused pass specifically over Ficha técnica/Mecánicas/Temáticas, with real
user sign-off ("the new pills look a lot cleaner, I want to be sure we will update it to be
consistent everywhere") — landed on `.pill-outline` instead: transparent fill, but a real 1px
border at rest, same shape family as the interactive chips minus the tap affordance and touch-target
floor. **Treat `.pill-outline` as current for every informational call site** (facts row,
Mecánicas/Temáticas, creators/Diseñadores/Ilustradores — editorial hashtags kept their own accent
fill, unaffected by this change); the flat/borderless/middot idea did not survive contact with the
real page.

```css
.pill-outline { background: transparent; border-color: var(--color-border); color: var(--color-text-muted); }
.pill-outline:hover { border-color: var(--color-primary); color: var(--color-primary); }
```

**Border-only-at-rest is the industry pattern for signaling tappability with no hover state.**
Touch devices have no pre-tap hover cue the way desktop pointers do — Material Design's "filter
chip" and Airbnb's own filter pills both keep a visible outline at rest for exactly this reason.
A fully transparent/borderless resting state (tried and rejected) only works for elements that
genuinely don't respond to touch; anything tappable needs *some* always-visible signal, and a tap
press-feedback state substitutes for the hover cue mobile doesn't have.

**Superseded (sketch 041): selected/active state stays in the outline family — no full fill.**
This file originally called for a full `--color-primary` fill + shadow on selected/active chips.
Sketch 041 tested that literal outline-everywhere first, then compared it directly against the
real filter modal: a selected chip rendered **pixel-identical** to its unchecked siblings in the
same control (caught before finalizing, not shipped) — outline alone isn't enough signal for a
selection state sitting next to unselected peers, but a full fill was never re-tested as the fix;
instead selected/active permanently carries the pill's own **hover** treatment as its resting
selected state (primary border + primary text, no fill, no shadow, `font-weight: 700`) — the same
signal for both a removable active-filter chip (paired with a small `✕`) and a selected
filter-modal facet chip.

```css
.pill-selected { background: transparent; border-color: var(--color-primary); color: var(--color-primary); font-weight: 700; }
```

**Superseded (sketches 039-041): informational-pill text is the muted variant, not the theme's full
text color.** This file originally called for `--color-text` on informational pills specifically to
avoid an unintentional "default gray" look. 039-041's `.pill-outline` uses
`color: var(--color-text-muted)` instead, paired with the new bordered treatment above — the muted
tone now reads as intentional secondary-content styling once it has a real border to anchor it,
rather than looking like unstyled default text the way it did on the old flat/borderless shape.

**No decorative icons or symbol prefixes on pills.** Emoji icons on the facts pills (👤⏱🎯) and the
`#` prefix on editorial hashtag chips were both dropped — plain label text only. Icons on
unlabeled glyphs add visual noise without adding information (and are invisible to screen readers
unless separately labeled), and the hashtag symbol duplicated what the "Editorial" section heading
already establishes.

## CSS Patterns

**Current (039-041), confirmed against the real call sites** — plain modifier classes, not a
`data-role`/`data-state` attribute API (036's original proposal never shipped in that shape; the
real components — `GameChips.chip_row/1`, `GameChips.editorial_tags/1`, `GamePreview.facts_row/1`,
`filter_modal.ex`'s `chip_class/1`, `catalog_live/index.ex`'s active-filter row — all resolve to one
of the four classes below):

```css
/* Base — structural only, shape lives in the modifier rules below */
.pk-pill {
  display: inline-flex; align-items: center; font-size: 11px; font-weight: 600;
  padding: 4px 9px; border-radius: var(--radius-full); border: 1px solid transparent;
  text-decoration: none; cursor: pointer;
  transition: all var(--duration-fast) var(--ease-standard);
}

/* Informational — facts row, Mecánicas/Temáticas, creators, Diseñadores/Ilustradores */
.pk-pill-outline { background: transparent; border-color: var(--color-border); color: var(--color-text-muted); }
.pk-pill-outline:hover { border-color: var(--color-primary); color: var(--color-primary); }

/* Editorial hashtags — the one informational call site that keeps its own accent fill */
.pk-pill-accent { background: var(--color-accent-bg); border-color: var(--color-accent-bg); color: var(--color-accent-text); }

/* Interactive, unselected — filter-modal facet/scalar chip (already .pk-pill-outline at rest,
   same class as informational; the touch-target floor below is what interactive adds) */
.pk-pill-outline { min-height: 44px; } /* WCAG 2.5.5 AAA — only on the interactive call sites, not the facts row */

/* Interactive, selected/active — filter-modal selected chip + catalog active-filter chip */
.pk-pill-selected { background: transparent; border-color: var(--color-primary); color: var(--color-primary); font-weight: 700; }
.pk-pill-selected:active { transform: scale(0.96); }

/* Removable-chip "x" (active-filter row) */
.pk-pill-x { display: inline-flex; align-items: center; justify-content: center; width: 16px; height: 16px; border-radius: 50%; margin-left: 4px; }
```

## HTML Structures

```html
<!-- Informational — bordered outline, no tap affordance -->
<div class="pill-row">
  <span class="pk-pill pk-pill-outline">2-4 jugadores</span>
  <span class="pk-pill pk-pill-outline">30 min</span>
  <span class="pk-pill pk-pill-outline">Intermedio</span>
</div>

<!-- Editorial hashtags — accent fill, unaffected by the outline supersession -->
<a class="pk-pill pk-pill-accent" href="#">#CooperativoPuro</a>

<!-- Interactive, selectable (filter modal) -->
<button class="pk-pill pk-pill-selected">Estrategia</button>
<button class="pk-pill pk-pill-outline">Familiar</button>

<!-- Interactive, removable (active filters) -->
<button class="pk-pill pk-pill-selected">2-4 jugadores <span class="pk-pill-x">✕</span></button>
```

## What to Avoid

- Don't unify pills/chips by giving everything the same chrome — unify by *interactivity role*
  first (informational vs. tappable), then let chrome differ accordingly.
- Don't shrink an interactive chip's touch height to "balance" it visually against a smaller
  informational pill — 44px is an accessibility floor (WCAG 2.5.5 AAA), not a size to negotiate.
- Don't rely on `:hover` alone to signal that a chip is tappable — touch devices have no hover;
  keep a visible border at rest, and add a real `:active` press-feedback state for tap confirmation.
- Don't decorate a pill with an emoji icon or a symbol prefix (like `#`) that isn't independently
  meaningful — it adds visual noise without adding information, and isn't labeled for screen readers.
- Don't build five independent pill/chip components across a codebase, even if each one's individual
  CSS looks reasonable in isolation — check for an existing base before adding a sixth.
- Don't leave informational pills fully borderless/flat "for lightness" — 036's flat/middot idea
  looked reasonable in isolation but didn't survive a later, more focused pass over the exact same
  content (039-041); a real border at rest is what makes the pill read as a pill instead of loose
  text on the page.
- Don't jump straight to a full-color fill the moment outline-alone fails to distinguish a selected
  state from its unselected siblings — 041 tried literal outline-everywhere first, found it made a
  selected filter-modal chip pixel-identical to unchecked ones next to it, and reached for the
  pill's own existing hover treatment (border + text color) as the fix, not a new fill.
- Don't assume a design decision from an earlier, broader unification sketch is still current —
  036's flat-informational and full-fill-selected rules were both quietly superseded by later,
  narrower, UAT-validated passes over the same exact elements (039-041). Check the most recent
  sketch touching a given component, not just the one that first proposed a system for it.

## Origin
Synthesized from sketches: 036 (5 rounds — see its README for the full round-by-round history:
A/B/C size-and-tone directions, balance refinement, theme-color/no-icon polish, minimalism
exploration, and the final A+B synthesis with tap-affordance research); 039 (ficha-técnica creators,
first real use of `.pill-outline` on this content), 040 (Mecánicas/Temáticas absorbed into the same
outline family), 041 (site-wide outline spread across all 5 real pill/chip call sites + the
selected/active-state revision, verified against the real call-site inventory, not assumed).
Source files available in: sources/036-pill-chip-unification/, sources/039-ficha-tecnica-creators/,
sources/040-reading-column-composition/, sources/041-pill-system-outline/
