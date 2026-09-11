---
status: diagnosed
trigger: "G-01-2: The game title and weight-band badge in a catalog card overlap on narrow/mobile viewport widths."
created: 2026-08-18T21:21:47.000Z
updated: 2026-08-18T21:21:47.000Z
audit_acknowledged:
  milestone: v1.0
  at: 2026-09-11
  status: diagnosed
---

## Current Focus

hypothesis: CONFIRMED — see Resolution.root_cause
test: n/a — diagnose-only mode, static/CSS-math analysis of daisyUI's compiled `.badge`/`.card-body` rules against actual grid math (no code changed)
expecting: n/a
next_action: n/a — return ROOT CAUSE FOUND to caller for fix routing

## Symptoms

expected: The game title and weight-band badge in a catalog card render without overlapping at any viewport width, including narrow/mobile widths.
actual: User reported: badge (e.g. "Descubre el hobby") visually overlaps the game title on a narrow viewport; not present at full desktop width. Card markup is lib/pukllay_club_web/components/game_card.ex (title h3 + GameChips.weight_band_badge), badge/chip rendering is lib/pukllay_club_web/components/game_chips.ex. No absolute/relative-positioned or breakpoint-gated classes found on this markup by an initial source scan, and the compiled app.css contains all expected utility classes — root cause not yet isolated (possibly Firefox-specific line-clamp/box rendering, or something not yet checked).
errors: None reported
reproduction: Test 2 in .planning/phases/01-catalog-v1/01-UAT.md — narrow/mobile-width viewport on the catalog page (/)
started: Discovered during UAT (Phase 01-catalog-v1)

## Eliminated

- hypothesis: "H3 title's `line-clamp-2` doesn't render correctly in Firefox, causing a box-height miscalculation that pushes the badge upward into the title."
  evidence: Tailwind's `line-clamp` utility compiles to `overflow:hidden; display:-webkit-box; -webkit-box-orient:vertical; -webkit-line-clamp:2;` — `-webkit-line-clamp` has been supported unprefixed/prefixed in Firefox for years and behaves identically across engines for this simple 2-line clamp case. No evidence of engine-specific line-clamp divergence was found, and the actual mechanism (below) is layout-engine-agnostic (pure flexbox box-sizing math), so it reproduces in any browser, not Firefox-specifically. The original report's "possibly Firefox-specific" note was a plausible-sounding guess, not a confirmed cause.
  timestamp: 2026-08-18T21:21:47.000Z
- hypothesis: "An absolute/relative-positioned or breakpoint-gated class is present somewhere in the badge/title markup causing the overlap."
  evidence: Read game_card.ex and game_chips.ex in full — no `absolute`, `relative`, `fixed`, negative-margin, or `sm:`/`lg:`-prefixed positioning classes anywhere on the h3, the badge wrapper div, or the badge span. Confirmed this scan was accurate (matches the report's own note); the real cause is in the daisyUI component CSS, not the call-site markup.
  timestamp: 2026-08-18T21:21:47.000Z

## Evidence

- timestamp: 2026-08-18T21:21:47.000Z
  checked: lib/pukllay_club_web/components/game_card.ex (full file)
  found: "`card-body space-y-2 p-4` wraps `<h3 class=\"line-clamp-2 ...\">{@game.name}</h3>` immediately followed by `<GameChips.weight_band_badge game={@game} show_descriptor={false} />` — a plain vertical stack, no positioning classes, no fixed heights on either element."
  implication: Overlap is not caused by explicit positioning in the call site; must come from the daisyUI component classes (`.card-body`, `.badge`) or from grid math at narrow widths.

- timestamp: 2026-08-18T21:21:47.000Z
  checked: lib/pukllay_club_web/components/game_chips.ex `weight_band_badge/1`
  found: "Renders `<div :if={@band} class=\"space-y-1\"><span class=\"badge badge-secondary\">{@band.label}</span>...</div>` — with `show_descriptor=false` (the value game_card.ex passes), only the single badge `<span>` renders, no descriptor `<p>`."
  implication: The overlap-causing element is exactly one `<span class=\"badge badge-secondary\">` containing the label text, immediately below the title with only the `card-body` flex `gap` (8px) separating them.

- timestamp: 2026-08-18T21:21:47.000Z
  checked: lib/pukllay_club/catalog/vocabulary.ex `@weight_bands`
  found: "Three labels: `\"Descubre el hobby\"` (18 chars, 3 words — the one in the bug report), `\"Ingenio estratega\"` (18 chars, 2 words), `\"Nivel experto\"` (13 chars, 2 words). All are multi-word Spanish phrases, none can be safely assumed to fit on one line at narrow widths."
  implication: The specific reported label is the longest one, and is a 3-word phrase — a strong candidate for wrapping at narrow badge widths.

- timestamp: 2026-08-18T21:21:47.000Z
  checked: deps/daisyui/packages/bundle/daisyui.mjs — compiled `.card-body` rule
  found: "`.card-body { display: flex; flex: auto; flex-direction: column; gap: calc(0.25rem * 2); padding: var(--card-p, 1.5rem); ... }` — confirmed a vertical flexbox column (not block layout) with an 8px `gap` between children (the h3 and the badge div are direct flex-item siblings)."
  implication: Title and badge are flex-column siblings with only 8px between their boxes — any vertical overflow of the badge's own box by more than ~8px will visually intrude into the title's box above it.

- timestamp: 2026-08-18T21:21:47.000Z
  checked: deps/daisyui/packages/bundle/daisyui.mjs — compiled `.badge` rule
  found: "`.badge { display: inline-flex; align-items: center; justify-content: center; ...; width: fit-content; --size: calc(var(--size-selector, 0.25rem) * 6); height: var(--size); padding-inline: calc(var(--size) / 2 - var(--border)); }` — with this project's theme `--size-selector: 0.21875rem`, `--size` resolves to `1.3125rem` (~21px). Critically: **no `white-space: nowrap` and no `overflow: hidden`** are set anywhere in the `.badge` rule (confirmed by reading the full rule body, not truncated)."
  implication: "`.badge` has a FIXED, single-line-sized `height` (21px) but does not prevent its text from wrapping onto multiple lines (default `white-space: normal` applies, `width: fit-content` lets the box shrink below the label's natural single-line width when its container is narrow) and does not clip overflow. If the label wraps to 2 lines inside a box that is only tall enough for 1 line, the extra line is NOT clipped — it visually bleeds outside the fixed-height box, centered via `align-items: center` (so it bleeds both above AND below the nominal badge position)."

- timestamp: 2026-08-18T21:21:47.000Z
  checked: lib/pukllay_club_web/live/catalog_live/index.ex:305-318 (grid markup) vs. lib/pukllay_club_web/components/carousel_row.ex:26 (carousel card width)
  found: "The main catalog grid renders `GameCard.game_card` with NO explicit `:class` (grid classes only: `grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4`), so each card's width is fully determined by `minmax(0, 1fr)` grid-column sizing — i.e. `(container width − gaps) / 2` on narrow/mobile viewports below Tailwind's `sm:` (640px) breakpoint. `game_card.ex`'s `card-body` then applies `p-4` (16px each side), leaving roughly ~130-160px of actual content width on a typical ~360-390px-wide phone viewport once the page's own outer padding and the 16px inter-card grid gap are subtracted."
  implication: "This computed available width (~130-160px) is at or below the natural single-line width of `\"Descubre el hobby\"` at the badge's `font-size: 0.875rem` (roughly ~145-155px including the badge's own `padding-inline`), which is exactly the threshold where `width: fit-content` clamps the badge narrower than its single-line content needs, forcing the text to wrap. At `sm:grid-cols-3`/`lg:grid-cols-4` (desktop), columns are wide enough (300px+) that the label always fits on one line, so the bug is invisible there — matching the report's 'not present at full desktop width' observation exactly."

## Resolution

root_cause: "daisyUI's `.badge` component (used unmodified by `GameChips.weight_band_badge/1` in lib/pukllay_club_web/components/game_chips.ex, called from lib/pukllay_club_web/components/game_card.ex with the label 'Descubre el hobby') sets a FIXED single-line `height: var(--size)` (~21px) but does not set `white-space: nowrap` or `overflow: hidden`, while also setting `width: fit-content` — a shrink-to-fit width that a flexbox/grid ancestor is free to compress. In game_card.ex, the badge sits as a flex-column sibling of the title `<h3>` inside daisyUI's `.card-body` (`display:flex; flex-direction:column; gap: 8px`), inside a catalog grid cell that is only `minmax(0, 1fr)`-wide (lib/pukllay_club_web/live/catalog_live/index.ex's `grid-cols-2` — no explicit card width, unlike carousel_row.ex's fixed `w-40`/`w-48`). At narrow/mobile viewports (below the `sm:` 640px breakpoint, 2 columns), each card's available content width (~130-160px after grid gap + card-body p-4 padding) drops below the natural single-line width of the 3-word label 'Descubre el hobby' (~145-155px). The badge's `width: fit-content` then clamps its box to the narrower available width, its text wraps onto 2 lines (default `white-space: normal`), but its `height` stays pinned at the single-line 21px value. Because `.badge` has no `overflow: hidden`, the now-2-line, vertically-centered text visibly overflows the fixed-height box both upward and downward — the upward bleed crosses the mere 8px `card-body` flex gap and collides with the h3 title sitting directly above it. This reproduces in any browser (it is pure flexbox box-sizing math, not a Firefox-specific line-clamp/rendering quirk as the original UAT report speculated) and only at column widths narrow enough to force the wrap — matching 'not present at full desktop width' exactly. This module/pattern is shared: any future weight-band label (or possibly-long term) rendered through this same `.badge` treatment at narrow widths is equally exposed."
fix: ""
verification: ""
files_changed: []
