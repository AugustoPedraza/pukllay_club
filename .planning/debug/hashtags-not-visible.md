---
status: diagnosed
trigger: "G-01.3-1: Hashtags below the game title are not visible on the game detail page (Phase 01.3, PukllayClub board-game catalog, Phoenix LiveView)."
created: 2026-08-31T21:30:00Z
updated: 2026-08-31T22:20:00Z
---

## Current Focus

hypothesis: CONFIRMED — GameChips.editorial_tags/1 correctly renders nothing (`:if={@tags != []}`)
  for the 74% of games (286/393 BGG-enriched, 322/434 total) whose `game.tags` array is empty,
  because HashtagNormalizer.editorial_tags/1 only derives hashtags from 3 narrow CSV columns
  (#CreaConexiones/#EquipoGanador/#DuelosMemorables) that are rarely true. On games that DO carry
  tag data (verified directly: Wingspan Asia -> #DuelosMemorables, Spirit Island -> #EquipoGanador)
  the row renders correctly and is visually legible in both themes at both 390px and 1440px. The
  UAT report is best explained by the user having spot-checked at least one game without hashtag
  data during the session (e.g. base "Wingspan" — confirmed empty tags in DB, vs. the UAT text's
  own named example "Wingspan Asia" which has tags) — the empty case is indistinguishable from "broken"
  since there is no placeholder/fallback when the row is omitted.
test: Rendered Wingspan Asia (id 125) and Spirit Island (id 13) via curl (disconnected-mount HTML)
  and headless Chrome screenshots at 390px/1440px, light and forced-dark theme; rendered base
  Wingspan (id 137, confirmed tags={} in DB) at 390px for contrast.
expecting: If CSS/component were broken, hashtags would be absent/invisible on Wingspan Asia and
  Spirit Island too. If this is a data-coverage gap, hashtags would render correctly on
  tag-bearing games and be silently absent (no row at all) on empty-tag games.
next_action: Return ROOT CAUSE FOUND to orchestrator — diagnose-only mode, no fix applied.

## Symptoms

expected: |
  Open a fully-enriched game's detail page (e.g. Wingspan Asia, Spirit Island) at both 390px and
  1440px widths. The composition should read as title → lightweight accent-coloured hashtags →
  description → one two-column fact grid (Diseñadores/Ilustradores/Mecánicas/Temáticas) →
  Comunidad BGG, with no divider line inside the reading column. The hashtags should read as text,
  not a filled pill. The fact grid should visually pair up into two columns at 1440px and stack to
  one column at 390px. "Comunidad BGG" should read as a sensible group label, not "Avanzado".
actual: User reports "I can't see the hashtags below title" — the hashtags are not rendering/visible at all.
errors: None reported
reproduction: Open a fully-enriched game's detail page (e.g. Wingspan Asia, Spirit Island) in a browser at 390px and 1440px widths and look directly below the title.
started: Discovered during UAT of Phase 01.3 (game detail layout recomposition), plans 01.3-01 through 01.3-09.

## Eliminated

- hypothesis: The hashtag row markup/CSS is broken or missing after the 01.3-07 recomposition
    (e.g. `.pk-pill-tag` not shipped, wrong selector, gap/margin hiding it, low-contrast color
    token, display:none at some breakpoint).
  evidence: |
    Fetched the live dev server's disconnected-mount HTML for Spirit Island (`/juegos/13`) and
    Wingspan Asia (`/juegos/125`) via curl — both contain
    `<a href="/?tags=%23EquipoGanador" class="pk-pill pk-pill-tag pk-pill-interactive">#EquipoGanador</a>`
    (and `#DuelosMemorables` for Wingspan Asia) positioned correctly between the `<h1>` and the
    description. Fetched the served `/assets/css/app.css` and confirmed `.pk-pill-tag` exists with
    `color: var(--color-primary)` and `--color-primary` resolves to real hex values (`#3D096D`
    light / `#A97FD1` dark), not transparent/inherit. Headless Chrome screenshots (google-chrome
    --headless) at 390px (light and forced-dark via --force-dark-mode) and 1440px (light) for both
    named example games show `#EquipoGanador` / `#DuelosMemorables` clearly rendered and legible
    directly below the title, in both themes, at both widths.
  timestamp: 2026-08-31T22:10:00Z
- hypothesis: Editorial hashtag data was re-seeded/backfilled AFTER the user's UAT test, so the DB
    state I'm querying now doesn't reflect what the user actually saw.
  evidence: |
    `games.updated_at` for Spirit Island (2026-08-30 23:53:51 UTC) and Wingspan Asia
    (2026-08-30 23:55:40 UTC) both predate the UAT test session (started 2026-08-31T20:55:00Z per
    01.3-UAT.md frontmatter) by nearly a full day — the tag data was already present at test time,
    not added afterward.
  timestamp: 2026-08-31T22:12:00Z

## Evidence

- timestamp: 2026-08-31T21:45:00Z
  checked: "lib/pukllay_club_web/components/game_chips.ex editorial_tags/1"
  found: |
    `<div :if={@tags != []} class={["flex flex-wrap gap-1", @class]}>` — the entire hashtag row is
    conditionally omitted with NO placeholder/fallback when `game.tags == []`. This is the
    documented zero-one-many backstop pattern used throughout this page (01.3-07-PLAN.md's own
    `must_haves` truth #10: "A game missing any given field still renders no empty label, no empty
    column and no empty section").
  implication: An empty-tags game will show literally nothing where the hashtag row would be —
    visually indistinguishable from "broken."

- timestamp: 2026-08-31T21:50:00Z
  checked: "lib/pukllay_club/catalog/seed/hashtag_normalizer.ex editorial_tags/1 + @editorial_columns"
  found: |
    Editorial tags are derived from exactly 3 CSV hashtag columns (`#CreaConexiones`,
    `#EquipoGanador`, `#DuelosMemorables`) — each only true for a minority of the 434 seeded rows
    (distinct from the 3 weight-band columns used for `weight_band`, and the seed report's "Tags |
    26" line, which is an unrelated uncovered *BGG mechanic* term, not this field).
  implication: Most games are expected, by the seed pipeline's own design, to have zero editorial
    hashtags.

- timestamp: 2026-08-31T21:55:00Z
  checked: "Direct Postgres query against pukllay_club_dev.games"
  found: |
    `select count(*) filter (where tags = '{}') as empty, count(*) filter (where tags <> '{}') as
    has_tags from games` -> 322 empty / 112 has_tags out of 434 total (74% empty). Restricted to
    BGG-enriched games only (`bgg_id is not null`, n=393): 286 empty / 107 has_tags (still 73%
    empty). `select name, tags from games where name ilike '%wingspan%' or name ilike '%spirit
    island%'` -> Spirit Island: `{#EquipoGanador}`; Wingspan Asia: `{#DuelosMemorables}`; plain
    "Wingspan" (base game, no "Asia"/"Europa"/"Oceania" suffix): `{}` (empty).
  implication: The two games the UAT truth statement names by example DO have tag data and DO
    render the row correctly (see Eliminated above). But a near-identically-named sibling game
    (the base "Wingspan," easy to click into by mistake instead of "Wingspan Asia") has empty
    tags and would show nothing — and 3 out of 4 games overall would show nothing.

- timestamp: 2026-08-31T22:00:00Z
  checked: "Headless Chrome screenshot of /juegos/137 (plain 'Wingspan', tags={}) at 390px"
  found: |
    Title "WINGSPAN" is immediately followed by the description paragraph with NO hashtag line in
    between at all — reproduces "I can't see the hashtags below title" exactly, because the row
    genuinely does not exist in the DOM for this game.
  implication: This is the most direct, reproducible match to the reported symptom found during
    investigation. Confirms the mechanism (conditional omission on empty data) rather than a
    render/CSS defect.

## Resolution

root_cause: |
  Not a code/CSS defect in the 01.3-07 hashtag recomposition — GameChips.editorial_tags/1 renders
  correctly (legible accent-coloured text, correct position right after the title) on every game
  that has editorial hashtag data, verified directly on both UAT-named example games (Wingspan
  Asia, Spirit Island) in both light/dark themes and at both 390px/1440px. The reported symptom is
  explained by a data-coverage gap combined with a silent-omission UX pattern: HashtagNormalizer's
  editorial-tag CSV mapping (3 narrow columns: #CreaConexiones/#EquipoGanador/#DuelosMemorables)
  leaves 74% of games (322/434, including the base "Wingspan" entry as opposed to "Wingspan Asia")
  with an empty `tags` array, and GameChips.editorial_tags/1's `:if={@tags != []}` guard renders
  absolutely nothing (no placeholder, no empty-state text) in that case — making "no hashtag data"
  visually indistinguishable from "hashtags are broken" to anyone spot-checking multiple game
  pages during UAT.
fix: (not applied — diagnose-only investigation)
verification: (not applicable — no fix applied)
files_changed: []
