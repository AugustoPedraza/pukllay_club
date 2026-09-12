---
phase: quick-260912-im6
plan: 01
subsystem: ui
tags: [phoenix, liveview, heex, seo, copy, spanish-locale]

requires: []
provides:
  - "Single site-wide name for the browse surface: 'ludoteca' everywhere it renders (tab title, unfiltered grid heading, load-error state, 404 body/CTA, site-level meta/og:description), matching the detail-page breadcrumb"
affects: [catalog-index, game-detail-404, seo-meta]

actuals:
  tokens: 2201
  tasks: 3
  commits: 3
plan_head_before: 42d7814cb0792225436f4ccdb77e0f3a76286514

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/controllers/error_html/404.html.heex
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - lib/pukllay_club_web/seo.ex
    - lib/pukllay_club_web/components/layouts.ex
    - test/pukllay_club_web/controllers/error_html_test.exs
    - test/pukllay_club_web/live/catalog_live_test.exs
    - .claude/skills/sketch-findings-pukllay_club/references/empty-loading-error-states.md

key-decisions:
  - "Every retired 'catálogo' user-facing string (404 body/CTA, catalog index tab title/heading/load-error, site-level meta description) renamed to 'ludoteca', matching the detail-page breadcrumb that already said Ludoteca since 01.2-01"
  - "No identifiers renamed: PukllayClub.Catalog, CatalogLive.*, catalog_live/, @catalog_path, routes, DB columns all left byte-identical, verified via git diff grep for Catalog"
  - "sketch-findings-pukllay_club/references/empty-loading-error-states.md gets an additive dated note (not a rewrite) pointing future UI work at the new strings, preserving the original sketch 003/01.1-07 record"

patterns-established: []

requirements-completed: [QUICK-260912-IM6-01]

coverage:
  - id: D1
    description: "404 page body sentence and CTA name the ludoteca; the four existing security refutes (Not Found/Exception/stacktrace/Ecto) are unmodified"
    requirement: "QUICK-260912-IM6-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/controllers/error_html_test.exs#renders 404.html"
        status: pass
    human_judgment: false
  - id: D2
    description: "Catalog index tab title reads Ludoteca, unfiltered grid heading reads Toda la ludoteca (asserted on the grid surface, refuted on the carousel surface), and the load-error heading reads No pudimos cargar la ludoteca"
    requirement: "QUICK-260912-IM6-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#pressing the filter modal's primary CTA with no facets selected renders the #games container and the full-catalog heading, and hides the carousel surface"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#the unfiltered landing renders the carousel-rows container and no results grid (D-01)"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#when the catalog query raises, the page renders the error-state banner instead of crashing"
        status: pass
    human_judgment: false
  - id: D3
    description: "Site-level @site_description (SEO.site_default/1) names the ludoteca and stays under the 155-char max_description_length; no test pins this literal in production, so the file-wide negative grep plus a positive grep on the new string are the only guards"
    requirement: "QUICK-260912-IM6-01"
    verification:
      - kind: other
        ref: "grep -q 'La ludoteca de juegos de mesa' lib/pukllay_club_web/seo.ex"
        status: pass
    human_judgment: false
  - id: D4
    description: "lib/ and test/ contain zero remaining occurrences of the retired term (rendered strings and comments); no identifier (Catalog/CatalogLive/@catalog_path/routes/DB columns) was renamed"
    requirement: "QUICK-260912-IM6-01"
    verification:
      - kind: other
        ref: "! grep -rniE 'cat[áa]logo' lib/ test/"
        status: pass
      - kind: other
        ref: "git diff --stat 42d7814..HEAD (7 files, matches files_modified) + git diff grep for Catalog shows no identifier rename"
        status: pass
    human_judgment: false
  - id: D5
    description: "mix quality (hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted incl. Styler, credo --strict, sobelow, test) passes green with zero Styler churn beyond the intended string edits"
    requirement: "QUICK-260912-IM6-01"
    verification:
      - kind: other
        ref: "mix quality (1017 tests, 0 failures, exit code 0)"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-09-12
status: complete
---

# Phase quick-260912-im6 Plan 01: Rename user-facing "catálogo" copy to "ludoteca" Summary

**Site-wide browse-surface renamed from "catálogo" to "ludoteca" across the 404 page, catalog index (tab title/heading/load-error), and site-level SEO description — now matching the detail-page breadcrumb that already said "Ludoteca".**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-12T13:31:14-03:00
- **Completed:** 2026-09-12T13:48:31-03:00
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- 404 page body sentence and CTA now name "la ludoteca" (`404.html.heex`), proven via a RED→GREEN TDD tracer slice before being repeated elsewhere
- Catalog index tab title ("Ludoteca"), unfiltered grid heading ("Toda la ludoteca"), and load-error heading ("No pudimos cargar la ludoteca") renamed in `CatalogLive.Index`, with both stale code comments requoted to match
- Site-level `@site_description` (`seo.ex`, feeds `og:description`/`<meta name="description">`) renamed to name the ludoteca, still well under the 155-char cap (81 chars)
- `layouts.ex` rationale comment naming the header search pages updated (Catálogo → Ludoteca)
- `sketch-findings-pukllay_club/references/empty-loading-error-states.md` gained an additive, dated note pointing future UI work at the four new strings, without erasing the original sketch 003/01.1-07 record
- `mix quality` passes clean (1017 tests, 0 failures) with zero Styler churn — confirming this was a pure copy change

## Task Commits

Each task was committed atomically:

1. **Task 1: 404 page end-to-end — assertion first, then the rendered string** - `cfd57ed` (feat, tdd)
2. **Task 2: expand the rename to the catalog index and the site-level SEO description** - `d1fa340` (feat, tdd)
3. **Task 3: close the regression door and run the full quality gate** - `a6bbad5` (docs)

_TDD tasks (1, 2) each ran RED → GREEN as a single commit per plan's own atomic-commit-per-task instruction; the RED step's failing assertions were confirmed live before the GREEN edit, not committed separately._

## Files Created/Modified
- `lib/pukllay_club_web/controllers/error_html/404.html.heex` - body sentence + CTA renamed to ludoteca
- `lib/pukllay_club_web/live/catalog_live/index.ex` - page_title, main_grid_heading/1, load-error heading renamed; 2 comments requoted
- `lib/pukllay_club_web/seo.ex` - `@site_description` renamed
- `lib/pukllay_club_web/components/layouts.ex` - rationale comment's page name updated
- `test/pukllay_club_web/controllers/error_html_test.exs` - 2 assertions updated
- `test/pukllay_club_web/live/catalog_live_test.exs` - 4 assert/refute lines updated (both directions)
- `.claude/skills/sketch-findings-pukllay_club/references/empty-loading-error-states.md` - additive dated note with the 4 new strings

## Decisions Made
- Kept the plan's TDD RED→GREEN discipline literally: for Task 2, ran the updated test file first and confirmed exactly the two expected asserts (:424, :802) failed while both refutes (:759, :775) correctly still passed (asymmetric-by-design, per plan's own explanation) — confirming the refutes track real rendered output, not vacuous truth
- No architectural or identifier changes were needed; this was a pure literal-string rename exactly as scoped

## Deviations from Plan

None - plan executed exactly as written. No Rule 1/2/3 auto-fixes were required; the codebase had no bugs or missing functionality touching this copy change.

## Issues Encountered
- The worktree had no `deps/` installed (`mix deps.get` had not been run in this fresh worktree checkout) — ran `mix deps.get` once at the start of Task 1 to unblock `mix test`. This is a one-time worktree-bootstrap step, not a plan deviation (no plan file changed as a result).
- The sandboxed shell blocked writes to the shared `.git/worktrees/<name>/` metadata directory (used by the executor workflow's optional commit-count ledger convention) — worked around by recording the plan's starting SHA (`42d7814cb0792225436f4ccdb77e0f3a76286514`) directly and computing `git rev-list --count` against it at SUMMARY time instead of persisting a ledger file. `commits: 3` was independently confirmed via `git log --oneline` and `git rev-list --count`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The browse surface now has exactly one user-facing name ("ludoteca") across every rendered surface and the site-level SEO description; no further copy-consistency follow-up needed for this term.
- `sketch-findings-pukllay_club` now carries the current canonical strings for empty/loading/error/404 states, so future UI passes on these surfaces won't reintroduce "catálogo".
- No blockers for Phase 2 (Natural-Language Spanish Search + Auth) — this quick task touched no identifiers or routes Phase 2 planning would need to account for.

---
*Phase: quick-260912-im6*
*Completed: 2026-09-12*

## Self-Check: PASSED

All 8 claimed files verified present on disk (7 modified source/test files + this SUMMARY.md).
All 3 task commit hashes (`cfd57ed`, `d1fa340`, `a6bbad5`) verified present via `git log --oneline`.
