# Phase 1: Catalog v1 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 1-Catalog v1
**Areas discussed:** Source data & images, Plain-Spanish vocabulary, Browse layout, Filter & search UX

---

## Source data & images

| Option | Description | Selected |
|--------|-------------|----------|
| I'll provide a CSV/Excel export | Full club data ready to hand over | |
| Pull from BGG API | No club file, source everything from BGG | |
| Combination | Club file for titles/tags, BGG enrichment for weight/mechanics/min age | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Seed script -> R2 | One-time seed task downloads, resizes, uploads to Cloudflare R2 | ✓ |
| Seed script -> local volume | Same but stored on Kamal-mounted host volume | |
| User supplies files directly | User provides pre-resized images | |

| Option | Description | Selected |
|--------|-------------|----------|
| Ready to hand over | Club title list + editorial tags ready now | ✓ |
| Titles only, no tags yet | Tags need curating separately | |
| Needs to be compiled from scratch | Neither exists yet | |

| Option | Description | Selected |
|--------|-------------|----------|
| One-time mix task, run manually | Matches Phase 0's no-Oban scope | ✓ |
| Oban-backed seed job | Resumable/rate-limit-friendly but out of Phase 1 scope | |

| Option | Description | Selected |
|--------|-------------|----------|
| Club file includes BGG IDs | Most reliable, no fuzzy matching | ✓ |
| Match by title, review before commit | Fuzzy match + manual review | |
| Match by title, best-effort automatic | Fuzzy match, no review | |

| Option | Description | Selected |
|--------|-------------|----------|
| One size fits all | Single resized cover reused everywhere | |
| Two variants | Small thumbnail + larger detail image | ✓ (expanded into a small gallery per game) |
| You decide | Claude picks during planning | |

**User's choice:** Two image variants, plus the user clarified they want a small gallery per game
(cover/portrait + a couple of "table setup"/component photos), and raised that images should match
the game's physical language edition (Spanish/English/German) where the club owns non-Spanish
copies, focused on Spanish overall.

Follow-up: cover art must match owned language edition; extra gallery photos are best-effort
(not guaranteed language-matched, since BGG doesn't reliably tag interior photos by language).
Club file doesn't track owned language edition — default to Spanish, flag exceptions. Full gallery
(not just cover) ships in Phase 1, not deferred.

**Notes:** This turned out to be the highest-stakes area — no CSV/Excel file currently exists
anywhere in the repo despite PROJECT.md referencing "the existing Excel catalog." Confirmed the
user will hand over a real file with BGG IDs and editorial hashtags already populated.

---

## Plain-Spanish vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Use researched style | Adopt research's example band names/framing | |
| I have different wording | User provides own band names | ✓ |
| You decide | Claude picks band names/copy | |

| Option | Description | Selected |
|--------|-------------|----------|
| 4 bands | Matches research example | |
| 3 bands | Simpler: beginner/intermediate/advanced | ✓ |
| You decide | Claude picks count from data distribution | |

**User's choice (free text):** Provided 6 hashtags total:
`#DescubreElHobby`, `#IngenioEstratega`, `#NivelExperto` (weight bands) and `#CreaConexiones`,
`#EquipoGanador`, `#DuelosMemorables` (other editorial signals).

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, that split is correct | 3 weight bands + 3 separate editorial tags | ✓ |
| No, all 6 are one vocabulary | Flat set of 6 chips, no categorical split | |

| Option | Description | Selected |
|--------|-------------|----------|
| Already tagged in the file | Excel file already has these hashtags per game | ✓ |
| New taxonomy, needs applying | Claude/mix task needs to derive which hashtags apply | |

| Option | Description | Selected |
|--------|-------------|----------|
| This is the full list | 6 hashtags is everything | ✓ |
| There are more | Additional hashtags exist in the file | |

| Option | Description | Selected |
|--------|-------------|----------|
| Claude drafts it | Derive ~15-25 term mechanic/theme glossary from seeded BGG data | ✓ |
| I have a glossary | User provides existing mapping | |

| Option | Description | Selected |
|--------|-------------|----------|
| Just the label | Only hashtag name exists, Claude drafts descriptive copy | ✓ |
| Full description exists | User/file already has explanatory text | |

**Notes:** The user's 6-hashtag list is exact, verbatim, user-provided content — not to be
reworded. Confirmed split between weight-band hashtags (CATALOG-05) and other editorial hashtags
(CATALOG-07). Mechanic/theme glossary (CATALOG-06) is entirely separate and doesn't exist yet.

---

## Browse layout

| Option | Description | Selected |
|--------|-------------|----------|
| Themed carousels + full grid | Curated carousel rows + full grid | ✓ |
| Single filterable grid | No carousels, just one grid | |
| You decide | Claude proposes layout | |

| Option | Description | Selected |
|--------|-------------|----------|
| Club favorite / beginner-friendly | Existing CATALOG-07 signals | ✓ |
| The 6 hashtags | One row per hashtag | ✓ |
| Not applicable | N/A (not chosen) | |

**User's choice (free text):** Also proposed "recently added," "últimas novedades," and "ganadores
Spiel" as carousel ideas, then self-corrected: "that should be dynamic... take note of that for the
future."

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, fixed rows for Phase 1 | Hardcode a set of carousel rows now, defer dynamic system | ✓ |
| Reconsider — smaller set | Trim the fixed list | |

| Option | Description | Selected |
|--------|-------------|----------|
| It's in the file | Award-winner data tracked in Excel | |
| Drop for Phase 1 | Not tracked, skip this carousel | ✓ |

**User's choice (free text):** Confirmed award winners and themed collections (e.g. "colección
árabe") are examples of the future dynamic/admin-configurable carousel idea, not Phase 1 scope.

**User's choice (free text, Google Stitch):** Flagged that UI will be designed via Google Stitch,
not started yet. Confirmed Stitch output should be the source of truth for `/gsd-ui-phase`, not
just inspiration.

**Notes:** Dynamic/admin-configurable carousels and award-winner data sourcing captured as deferred
ideas (see CONTEXT.md `<deferred>`), likely Phase 4 fit.

---

## Filter & search UX

| Option | Description | Selected |
|--------|-------------|----------|
| Live-updating | Results update immediately, no submit button | ✓ |
| Apply button | Explicit submit after picking filters | |

| Option | Description | Selected |
|--------|-------------|----------|
| Slide-over/drawer panel | Filters open via triggered drawer/bottom sheet | ✓ |
| Persistent sidebar | Always-visible sidebar, collapsing on mobile | |
| You decide | Claude picks based on Stitch design | |

| Option | Description | Selected |
|--------|-------------|----------|
| Tag pills, toggle multi-select | Click pills, OR logic within facet | ✓ |
| Checkboxes, AND logic | Must match all selected tags | |
| You decide | Claude picks | |

| Option | Description | Selected |
|--------|-------------|----------|
| Same experience, combined | Search box narrows results within active filters | ✓ |
| Separate search page/mode | Distinct flow from filter-browsing | |

**Notes:** No follow-up questions requested — user was ready to move to context after this area.

---

## Claude's Discretion

- One-line plain-Spanish descriptive copy for the 3 weight-band hashtags — Claude drafts, user
  reviews during planning.
- The ~15-25 term mechanic/theme glossary (CATALOG-06) — Claude derives from actual seeded BGG
  data, user reviews during planning.
- Exact image resize dimensions/format for the two variants — reasonable defaults, revisit once
  Stitch UI design is available.

## Deferred Ideas

- Dynamic/admin-configurable carousel system (admin defines new rows like award winners or themed
  collections without a code change) — flagged for Phase 4 (Club Ops / admin dashboard).
- Spiel des Jahres / award-winner data sourcing — not in the club's file, BGG's award data is
  unreliable to query; revisit only if the dynamic carousel system above gets built.
