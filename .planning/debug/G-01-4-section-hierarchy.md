---
status: diagnosed
trigger: "G-01-4: The catalog's ~8 sections on the main page all look the same — no clear visual hierarchy, spacing, or heading treatment separating one section from the next."
created: 2026-08-18T00:00:00.000Z
updated: 2026-08-18T00:00:00.000Z
audit_acknowledged:
  milestone: v1.0
  at: 2026-09-11
  status: diagnosed
---

## Current Focus

hypothesis: CONFIRMED — see Resolution.root_cause
test: static code read of index.ex, carousel_row.ex, catalog.ex, cross-checked against ui-design-system's documented type-hierarchy and spacing-scale rules
expecting: n/a — diagnosis complete, goal is find_root_cause_only
next_action: none — return ROOT CAUSE FOUND to caller

reasoning_checkpoint:
  hypothesis: "All ~8 catalog sections read as visually identical because (a) every one of the 8 D-09 carousel-row headings shares one hardcoded, unvaried `<h2 class=\"font-display text-2xl\">` regardless of the row's semantic importance (hero row vs. weight-band row vs. recency row), and (b) the 9th/most prominent section — the main `#games` grid — has no heading at all, only a small muted `text-neutral text-sm` result-count line, so the one boundary that most needs a strong visual break has none."
  confirming_evidence:
    - "carousel_row.ex:23 — the h2 markup is a single literal string with no per-row variation; every one of the 8 `list_carousel_rows/0` entries (catalog.ex:141-158) renders through this exact same component call with no style-varying attr."
    - "grep across lib/pukllay_club_web for `font-display text-2xl` shows it used for: the brand wordmark (layouts.ex:34, different context/tracking), the empty-state heading (index.ex:296), and all 8 carousel-row headings (carousel_row.ex:23) — i.e. every section-level heading on this page (and only this page) shares one identical class string, so heading style carries zero differentiating signal anywhere on /."
    - "index.ex:290-318 — between the closing `#carousel-rows` block and the `#games` grid there is no `<h2>`/`<h3>` at any font-display size; the only text present is `<p class=\"text-neutral text-sm\">{result_count_text(@total)}</p>`, which per ui-design-system's own convention (`text-neutral text-sm` = muted/secondary text) is styled as the least prominent text tier, not a section label — so the largest, most important section on the page opens with the visually weakest text on the page."
    - "grep for `space-y-8` shows exactly one occurrence in the whole web app (index.ex:270, the `#carousel-rows` wrapper) — not part of the documented `space-y-2/3/6` rhythm scale, and while more generous than space-y-6 (so not the deficiency itself), it confirms the section-to-section spacing was set ad hoc rather than by the established convention."
  falsification_test: "If any of the 8 carousel_row/1 call sites (or Catalog.list_carousel_rows/0) passed a distinguishing style/weight/variant attr into carousel_row/1, or if index.ex's grid section had its own font-display heading, the 'all sections look the same' complaint would be false — neither is present in the source."
  fix_rationale: "n/a — diagnose-only mode (goal: find_root_cause_only); no fix applied in this session."
  blind_spots: "Not verified against a live rendered screenshot/browser — this is a static-markup diagnosis. Have not measured actual on-screen contrast/visual-weight; relying on the fact that byte-identical Tailwind/daisyUI classes necessarily render identically. Have not checked GameCard.game_card/1 internals for any row-differentiating visual cue that might partially offset this (out of scope per task instructions — that file is covered by the separate 7-item UI audit backlog, not this gap)."
  candidate_causes:
    - "code: carousel_row.ex:23 hardcodes one identical h2 style for all 8 rows regardless of semantic importance"
    - "code: index.ex's main grid section (the 9th/most prominent section) has no heading element at all — only a muted result-count paragraph"
  and_gate: "yes — both conditions must hold simultaneously to produce the full symptom as reported. Uniform-but-present headings alone (8 rows all same) would still leave the grid's absence of a heading as one distinguishing (if wrong-direction) break; a headed grid alone would still leave all 8 carousel rows indistinguishable from each other. Both live in the same category (code/markup) — no config, environment, or data-level cause contributes; the issue is 100% reproducible from source with no dependency on data volume, environment, or configuration."

## Symptoms

expected: The catalog's ~8 sections on the main page are visually distinguishable from one another.
actual: User reported all ~8 sections look the same — no clear visual hierarchy, spacing, or heading treatment separating one section from the next.
errors: None reported
reproduction: Test 2 in .planning/phases/01-catalog-v1/01-UAT.md — load the main catalog page (/) and scroll through the ~8 sections (carousel rows per D-09, plus the main grid)
started: Discovered during UAT (Phase 01-catalog-v1)

## Eliminated

(none — first hypothesis confirmed directly from source)

## Evidence

- timestamp: 2026-08-18T00:00:00.000Z
  checked: lib/pukllay_club_web/live/catalog_live/index.ex (full file)
  found: "The page has 9 visually sequential sections in the unfiltered view: 8 D-09 carousel rows (rendered inside `#carousel-rows`, index.ex:270-284) followed by the main `#games` grid (index.ex:305-319). The outer page container uses `space-y-6` (index.ex:226) for top-level page blocks; the carousel-rows wrapper overrides with its own `space-y-8` (index.ex:270) for the 8 rows internally. Between the end of the carousel-rows block and the grid there is only a `<p class=\"text-neutral text-sm\">` result-count line (index.ex:290) — no heading."
  implication: The grid section — the largest and arguably most important section on the page — has no section-heading treatment at all, unlike every carousel row above it.

- timestamp: 2026-08-18T00:00:00.000Z
  checked: lib/pukllay_club_web/components/carousel_row.ex (full file)
  found: "carousel_row/1 (line 20-31) renders exactly one hardcoded heading for every row: `<h2 class=\"font-display text-2xl\">{@title}</h2>` (line 23). No attr varies this — no weight/size/color/variant is passed per row, and the component has no notion of 'this is the hero/featured row' vs 'this is a subordinate row'."
  implication: All 8 carousel-row headings are byte-identical in markup/class, differing only in text content — there is no visual (weight/size/color) signal distinguishing e.g. the flagship 'Destacados del club' row from a niche weight-band row like 'Nivel experto'.

- timestamp: 2026-08-18T00:00:00.000Z
  checked: lib/pukllay_club/catalog.ex list_carousel_rows/0 (lines 138-159)
  found: "The 8 fixed D-09 rows, in render order: Destacados del club (editorial hashtag, capped 20), Crea conexiones, Equipo ganador, Duelos memorables (3 single-hashtag rows), Descubre el hobby, Ingenio estratega, Nivel experto (3 weight-band rows), Recientemente añadidos (recency row) — 4 semantically distinct row *types* (curated/hero, per-hashtag, per-weight-band, recency), all rendered through the one undifferentiated carousel_row/1 heading."
  implication: The row set is semantically heterogeneous (a genuine, useful hierarchy exists conceptually — 'featured' vs 'browse by complexity' vs 'new arrivals') but the rendering collapses all of it to one repeated visual pattern.

- timestamp: 2026-08-18T00:00:00.000Z
  checked: "grep -rn 'space-y-8\\|space-y-6\\|font-display text-2xl' across lib/pukllay_club_web"
  found: "`font-display text-2xl` appears at: layouts.ex:34 (brand wordmark, different tracking/uppercase context), carousel_row.ex:23 (all 8 rows), index.ex:296 (empty-state heading) — i.e. it is the ONE heading style used throughout the whole catalog page. `space-y-8` appears exactly once in the entire web app (index.ex:270) — not part of ui-design-system's documented space-y-2/3/6 rhythm scale, i.e. an ad hoc, one-off spacing value rather than a deliberately chosen differentiator."
  implication: Confirms zero heading-style variation exists anywhere on the catalog page, and that the one deviation from the documented spacing scale (space-y-8) is more generous than the norm, not a spacing *deficiency* — ruling out 'insufficient pixel gap' as the mechanism and pointing squarely at heading-treatment sameness (plus the grid's missing heading) as the cause.

- timestamp: 2026-08-18T00:00:00.000Z
  checked: ".claude/skills/ui-design-system SKILL.md — Type hierarchy and Spacing/typography scale sections"
  found: "Documented rule: 'Weight and color, not a new size, are the emphasis lever — reserve a size bump for a genuinely larger content unit.' Also: 'Cap a single screen at 3 distinct size/weight levels (heading, body, muted).' Documented spacing rhythm: 'space-y-6 between major page sections, space-y-3 within one section.'"
  implication: The design system explicitly anticipates and licenses using weight/color (not just size) to create hierarchy between headings of the same nominal level — a lever the current carousel_row.ex implementation never uses. The codebase currently has exactly ONE heading level in active use on this page (font-display text-2xl), i.e. it is under the 3-level cap but has collapsed what should be a hero-vs-subordinate distinction into a single flat level.

## Resolution

root_cause: "Two combined code-level omissions in the unfiltered catalog view, both in the same category (markup/styling, not config/environment/data): (1) `CarouselRow.carousel_row/1` (lib/pukllay_club_web/components/carousel_row.ex:23) renders an identical, unvaried `<h2 class=\"font-display text-2xl\">{@title}</h2>` for all 8 D-09 rows regardless of the row's semantic role (hero/curated row vs. per-hashtag row vs. per-weight-band row vs. recency row) — the design system's own documented emphasis levers (weight, color) are never used to differentiate them; (2) `CatalogLive.Index.render/1` (lib/pukllay_club_web/live/catalog_live/index.ex, between lines 284 and 305) gives the main `#games` grid — the 9th and most prominent section, containing the full filtered catalog — no heading treatment at all, only a `text-neutral text-sm` (muted/secondary-tier) result-count line where a section label would be. Together these mean every section boundary on the page is either a repeat of the exact same heading style or has no heading at all, which is functionally indistinguishable from 'no clear visual hierarchy... separating one section from the next' as reported."
fix: ""
verification: ""
files_changed: []
