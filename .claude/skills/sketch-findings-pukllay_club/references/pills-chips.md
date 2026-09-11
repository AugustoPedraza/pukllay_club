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
  These render **flat: no background, no border, no radius** — just label text, separated by a
  small middot (`·`) rather than a bordered container. Chrome on a non-interactive element is
  visual weight with no payoff.
- **Interactive** (catalog active-filters chip, filter-modal facet/scalar chip) — tapping removes
  or toggles something. These keep a real pill shape with an **always-visible 1px border at rest**
  (not just on `:hover`), a 44px minimum touch height (WCAG 2.5.5 AAA target size — don't shrink
  this to "balance" sizes against the flat informational pills; it's an accessibility floor, not a
  style choice), and a genuine `:active` press-feedback (scale-down + background flash).

**Border-only-at-rest is the industry pattern for signaling tappability with no hover state.**
Touch devices have no pre-tap hover cue the way desktop pointers do — Material Design's "filter
chip" and Airbnb's own filter pills both keep a visible outline at rest for exactly this reason.
A fully transparent/borderless resting state (tried and rejected) only works for elements that
genuinely don't respond to touch; anything tappable needs *some* always-visible signal, and a tap
press-feedback state substitutes for the hover cue mobile doesn't have.

**Selected/active state is a full color fill, not a border-weight change.** `--color-primary`
background + matching border + `--color-primary-content` text + `--shadow-sm` — the same treatment
for a removable active-filter chip (paired with a small `✕` in a tinted circle) and a selected
filter-modal facet chip, so both read as "this is currently applied" the same way despite being
different affordances (remove vs. toggle).

**Pill text uses the theme's full text color, not the muted variant.** An earlier round used
`--color-text-muted` for informational pills, which read as "default gray" rather than an
intentional brand choice — switched to `--color-text`, which also raises contrast against the pill
background (a genuine accessibility improvement, not just a look).

**No decorative icons or symbol prefixes on pills.** Emoji icons on the facts pills (👤⏱🎯) and the
`#` prefix on editorial hashtag chips were both dropped — plain label text only. Icons on
unlabeled glyphs add visual noise without adding information (and are invisible to screen readers
unless separately labeled), and the hashtag symbol duplicated what the "Editorial" section heading
already establishes.

## CSS Patterns

```css
/* Base — structural only, shape lives in the role-specific rules below */
.pk-pill {
  display: inline-flex; align-items: center; gap: 6px; white-space: nowrap;
  color: var(--color-text);
  transition: background-color var(--duration-fast) var(--ease-standard),
    border-color var(--duration-fast) var(--ease-standard),
    box-shadow var(--duration-fast) var(--ease-standard),
    transform var(--duration-fast) var(--ease-standard);
}

/* Informational — facts row, Mecánicas/Temáticas, editorial tags */
.pk-pill { padding: 2px 2px; font-size: 0.75rem; font-weight: 600; background: transparent; border: none; }
.pk-pill[data-accent="true"] { color: var(--color-accent-content); } /* editorial hashtags */
.pk-pill-row[data-flat="true"] { gap: 0; }
.pk-pill-row[data-flat="true"] .pk-pill:not(:last-child)::after {
  content: '·'; margin-left: 10px; color: var(--color-base-300); font-weight: 700;
}

/* Interactive — active-filters chip, filter-modal facet/scalar chip */
.pk-pill[data-role="action"] {
  min-height: 44px; padding: 0 12px; font-size: 0.75rem; border-radius: 9999px;
  background: var(--color-base-200); border: 1px solid var(--color-base-300); /* ALWAYS visible, not hover-only */
}
.pk-pill[data-role="action"]:hover { border-color: var(--color-primary); color: var(--color-primary); background: var(--color-accent); }
.pk-pill[data-role="action"]:active { transform: scale(0.96); background: var(--color-accent); }
.pk-pill[data-state] { background: var(--color-primary); border-color: var(--color-primary); color: var(--color-primary-content); box-shadow: var(--shadow-sm); }
.pk-pill[data-state]:active { transform: scale(0.96); }

/* Removable-chip "x" */
.pk-pill-x { display: inline-flex; align-items: center; justify-content: center; width: 16px; height: 16px; border-radius: 50%; }
.pk-pill[data-role="action"]:not([data-state]) .pk-pill-x { background: color-mix(in srgb, var(--color-text) 12%, transparent); color: var(--color-neutral); }
.pk-pill[data-state] .pk-pill-x { background: rgba(255,255,255,0.25); color: inherit; }
```

## HTML Structures

```html
<!-- Informational, flat, middot-separated -->
<div class="pk-pill-row" data-flat="true">
  <span class="pk-pill">2-4 jugadores</span><span class="pk-pill">30 min</span><span class="pk-pill">Intermedio</span>
</div>

<!-- Interactive, removable (active filters) -->
<button class="pk-pill" data-role="action" data-state="active">2-4 jugadores <span class="pk-pill-x">✕</span></button>

<!-- Interactive, selectable (filter modal) -->
<button class="pk-pill" data-role="action" data-state="selected">Estrategia</button>
<button class="pk-pill" data-role="action">Familiar</button>
```

## What to Avoid

- Don't unify pills/chips by giving everything the same chrome — unify by *interactivity role*
  first (informational vs. tappable), then let chrome differ accordingly.
- Don't shrink an interactive chip's touch height to "balance" it visually against a smaller
  informational pill — 44px is an accessibility floor (WCAG 2.5.5 AAA), not a size to negotiate.
- Don't rely on `:hover` alone to signal that a chip is tappable — touch devices have no hover;
  keep a visible border at rest, and add a real `:active` press-feedback state for tap confirmation.
- Don't use a muted/desaturated text color token for pill labels by default — it reads as an
  unstyled "default gray" rather than an intentional choice; use the theme's primary text color.
- Don't decorate a pill with an emoji icon or a symbol prefix (like `#`) that isn't independently
  meaningful — it adds visual noise without adding information, and isn't labeled for screen readers.
- Don't build five independent pill/chip components across a codebase, even if each one's individual
  CSS looks reasonable in isolation — check for an existing base before adding a sixth.

## Origin
Synthesized from sketch: 036 (5 rounds — see its README for the full round-by-round history:
A/B/C size-and-tone directions, balance refinement, theme-color/no-icon polish, minimalism
exploration, and the final A+B synthesis with tap-affordance research).
Source files available in: sources/036-pill-chip-unification/
