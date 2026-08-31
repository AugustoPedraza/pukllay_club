---
schema_version: 1
open_count: 16
waived_count: 0
fixed_count: 0
total_count: 16
last_updated: 2026-08-31T00:12:03.091Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | quick-260818-gdb | deviation | config/runtime.exs |  | Pre-existing unstaged formatting/sobelow issues (config/runtime.exs unformatted, low-confidence Traversal.FileModule findings in seed/csv_import.ex + seed/report.ex, a Software Design credo suggestion in core_components.ex) block 'mix quality passes clean' -- none touched by this plan; task's own files (layouts.ex, tests, SKILL.md) are individually clean. | open |  | 2026-08-18T14:57:00.671Z |  |
| 2 | quick-260822-2v9 | deviation | assets/css/app.css |  | Header row overflows horizontally at 375px (brand wordmark wraps, horizontal scrollbar) after the desktop header polish — narrow-viewport block confirmed byte-identical, out of scope per plan C-1, deliberately not fixed | open |  | 2026-08-22T05:30:01.096Z |  |
| 3 | 01.1-09 | unrun-verify | lib/pukllay_club_web/components/layouts.ex |  | Task 1 human-check: drawer opens/traps focus/closes every way (Escape, close button, backdrop, link nav) on all three routes at 390px, absent+unreachable at 1440px -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | open |  | 2026-08-22T14:11:54.024Z |  |
| 4 | 01.1-09 | unrun-verify | assets/css/app.css |  | Task 2 human-check: drawer rows read as full-width tappable list with chevrons and left-accent active state, toggle+socials pinned hard to the panel's bottom edge, footer sheds toggle/socials but keeps copyright+BGG attribution at 390px -- deferred to end-of-phase visual verification | open |  | 2026-08-22T14:11:54.190Z |  |
| 5 | 01.1-09 | unrun-verify | lib/pukllay_club_web/live/about_live.ex |  | Task 3 human-check: About sticky CTA bar stays pinned above the fold with the footer fully readable underneath at 390px scrolled to bottom, absent at 1440px and on other routes at every scroll position -- deferred to end-of-phase visual verification | open |  | 2026-08-22T14:11:54.347Z |  |
| 6 | 01.1-02 | deviation | lib/pukllay_club_web/live/about_live.ex |  | Four photo-rail slides render as labelled placeholders (D-12, no real club photography exists yet) -- intentional per plan, resolves when real photos are swapped in (structural no-op) | open |  | 2026-08-22T14:30:46.847Z |  |
| 7 | 01.1-02 | unrun-verify | lib/pukllay_club_web/live/about_live.ex |  | Photo rail human-check: dots scroll-sync, click-to-jump, auto-advance every 4.5s, pauses on pointer interaction/unfocused tab/reduced-motion -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | open |  | 2026-08-22T14:30:53.492Z |  |
| 8 | 01.1-03 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | Manual human-check: at 1440px scroll /juegos/:id -- the poster column pins below the header with no overlap/gap and releases at the end of the masthead; at 390px the layout is a single column and the ficha tecnica is one column wide -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | open |  | 2026-08-22T19:27:49.892Z |  |
| 9 | 01.1-04 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | Manual human-check: at a real 390px viewport, the CTA bar is visible on first paint with no scroll, retracts during an active scroll and returns ~200ms after it stops, parks with the footer while body padding-bottom collapses in the same transition, and the title-echo bar fades in only after the h1 has fully scrolled past the header -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | open |  | 2026-08-22T20:00:25.349Z |  |
| 10 | 01.1-04 | unrun-verify | assets/css/app.css |  | Manual human-check: the mobile CTA bar's computed backgroundColor is visibly distinct from its own outlined share button's background (verify via computed style, not by eye) -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | open |  | 2026-08-22T20:00:32.776Z |  |
| 11 | 01.2-13 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | Task 2 human-check: buy-box reads as one bounded panel lifted off the page (not fading into the reading column) at ~390px and >=1280px in both light and dark themes, share icon anchored over the panel's top-right corner at both widths, cover art fills its frame with no letterboxing, reserve button unambiguously the page's one primary action -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | open |  | 2026-08-26T22:28:46.824Z |  |
| 12 | 01.2-13 | unrun-verify | assets/css/app.css |  | Task 3 human-check: at ~390px the stacked reserve+share bar reads balanced with reserve unmistakably primary, scroll-hide/reveal timing and footer-park behavior unchanged with no new jump, last real content never hidden behind the taller bar, and past 1100px (but below 768px) the bar's controls align under the content column instead of stretching edge-to-edge -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | open |  | 2026-08-26T22:28:47.008Z |  |
| 13 | 01.2 | unmet-truth | lib/pukllay_club_web/live/catalog_live/index.ex |  | Active-filters chip row's visual weight balance vs the Resultados heading (sketch 029 Round 2's 'clearly secondary' intent) is asserted only via class/no-shadow presence in tests; needs a human eyeballing a live render in both themes — no browser tool available to this executor (01.2-12 D6). | open |  | 2026-08-26T22:51:30.480Z |  |
| 14 | 01.3-02 | unrun-verify | lib/mix/tasks/catalog.enrich_bgg_stats.ex |  | Task 3 human-check: open 2-3 real game detail pages and confirm Valoración BGG shows a plausible 10-point score and links to that game's own BGG page -- deferred to end-of-phase UAT per human_verify_mode: end-of-phase; underlying data spot-checked via SQL (Wingspan 7.99/10 rank 38, Spirit Island 8.34/10 rank 11) | open |  | 2026-08-30T23:17:30.343Z |  |
| 15 | 01.3-02 | todo | lib/pukllay_club/catalog/seed/bgg_client.ex |  | BggClient.fetch_batch/2 raises ArgumentError (:erlang.binary_to_integer("")) when called with an empty bgg_ids list, discovered via an ad hoc verification script during 01.3-02; not reachable through StatsEnricher's normal flow (chunk_every never yields an empty chunk from a non-empty candidate list) but is a latent crash if ever called with []; pre-existing 01.3-01 code, out of scope for this plan's no-code-changes constraint | open |  | 2026-08-30T23:17:30.601Z |  |
| 16 | 01.3-04 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | Human-check: open three game detail pages (short/long/unusual-title descriptions), confirm as a Spanish speaker the description reads naturally in Argentine Spanish (voseo), proper nouns/mechanic names survive untranslated, no stray escapes, and Ver mas/Ver menos still expands/collapses at mobile+desktop widths -- deferred to end-of-phase UAT per human_verify_mode: end-of-phase; text quality already reviewed by the executor against a 5-game sample (all 5 criteria incl. voseo) before the full batch ran | open |  | 2026-08-31T00:12:03.091Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "quick-260818-gdb",
    "file": "config/runtime.exs",
    "line": null,
    "description": "Pre-existing unstaged formatting/sobelow issues (config/runtime.exs unformatted, low-confidence Traversal.FileModule findings in seed/csv_import.ex + seed/report.ex, a Software Design credo suggestion in core_components.ex) block 'mix quality passes clean' -- none touched by this plan; task's own files (layouts.ex, tests, SKILL.md) are individually clean.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-18T14:57:00.671Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "quick-260822-2v9",
    "file": "assets/css/app.css",
    "line": null,
    "description": "Header row overflows horizontally at 375px (brand wordmark wraps, horizontal scrollbar) after the desktop header polish — narrow-viewport block confirmed byte-identical, out of scope per plan C-1, deliberately not fixed",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-22T05:30:01.096Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "unrun-verify",
    "phase": "01.1-09",
    "file": "lib/pukllay_club_web/components/layouts.ex",
    "line": null,
    "description": "Task 1 human-check: drawer opens/traps focus/closes every way (Escape, close button, backdrop, link nav) on all three routes at 390px, absent+unreachable at 1440px -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-22T14:11:54.024Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "unrun-verify",
    "phase": "01.1-09",
    "file": "assets/css/app.css",
    "line": null,
    "description": "Task 2 human-check: drawer rows read as full-width tappable list with chevrons and left-accent active state, toggle+socials pinned hard to the panel's bottom edge, footer sheds toggle/socials but keeps copyright+BGG attribution at 390px -- deferred to end-of-phase visual verification",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-22T14:11:54.190Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "unrun-verify",
    "phase": "01.1-09",
    "file": "lib/pukllay_club_web/live/about_live.ex",
    "line": null,
    "description": "Task 3 human-check: About sticky CTA bar stays pinned above the fold with the footer fully readable underneath at 390px scrolled to bottom, absent at 1440px and on other routes at every scroll position -- deferred to end-of-phase visual verification",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-22T14:11:54.347Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "01.1-02",
    "file": "lib/pukllay_club_web/live/about_live.ex",
    "line": null,
    "description": "Four photo-rail slides render as labelled placeholders (D-12, no real club photography exists yet) -- intentional per plan, resolves when real photos are swapped in (structural no-op)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-22T14:30:46.847Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "unrun-verify",
    "phase": "01.1-02",
    "file": "lib/pukllay_club_web/live/about_live.ex",
    "line": null,
    "description": "Photo rail human-check: dots scroll-sync, click-to-jump, auto-advance every 4.5s, pauses on pointer interaction/unfocused tab/reduced-motion -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-22T14:30:53.492Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "unrun-verify",
    "phase": "01.1-03",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "Manual human-check: at 1440px scroll /juegos/:id -- the poster column pins below the header with no overlap/gap and releases at the end of the masthead; at 390px the layout is a single column and the ficha tecnica is one column wide -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-22T19:27:49.892Z",
    "resolved_at": null
  },
  {
    "id": 9,
    "kind": "unrun-verify",
    "phase": "01.1-04",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "Manual human-check: at a real 390px viewport, the CTA bar is visible on first paint with no scroll, retracts during an active scroll and returns ~200ms after it stops, parks with the footer while body padding-bottom collapses in the same transition, and the title-echo bar fades in only after the h1 has fully scrolled past the header -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-22T20:00:25.349Z",
    "resolved_at": null
  },
  {
    "id": 10,
    "kind": "unrun-verify",
    "phase": "01.1-04",
    "file": "assets/css/app.css",
    "line": null,
    "description": "Manual human-check: the mobile CTA bar's computed backgroundColor is visibly distinct from its own outlined share button's background (verify via computed style, not by eye) -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-22T20:00:32.776Z",
    "resolved_at": null
  },
  {
    "id": 11,
    "kind": "unrun-verify",
    "phase": "01.2-13",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "Task 2 human-check: buy-box reads as one bounded panel lifted off the page (not fading into the reading column) at ~390px and >=1280px in both light and dark themes, share icon anchored over the panel's top-right corner at both widths, cover art fills its frame with no letterboxing, reserve button unambiguously the page's one primary action -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T22:28:46.824Z",
    "resolved_at": null
  },
  {
    "id": 12,
    "kind": "unrun-verify",
    "phase": "01.2-13",
    "file": "assets/css/app.css",
    "line": null,
    "description": "Task 3 human-check: at ~390px the stacked reserve+share bar reads balanced with reserve unmistakably primary, scroll-hide/reveal timing and footer-park behavior unchanged with no new jump, last real content never hidden behind the taller bar, and past 1100px (but below 768px) the bar's controls align under the content column instead of stretching edge-to-edge -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T22:28:47.008Z",
    "resolved_at": null
  },
  {
    "id": 13,
    "kind": "unmet-truth",
    "phase": "01.2",
    "file": "lib/pukllay_club_web/live/catalog_live/index.ex",
    "line": null,
    "description": "Active-filters chip row's visual weight balance vs the Resultados heading (sketch 029 Round 2's 'clearly secondary' intent) is asserted only via class/no-shadow presence in tests; needs a human eyeballing a live render in both themes — no browser tool available to this executor (01.2-12 D6).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T22:51:30.480Z",
    "resolved_at": null
  },
  {
    "id": 14,
    "kind": "unrun-verify",
    "phase": "01.3-02",
    "file": "lib/mix/tasks/catalog.enrich_bgg_stats.ex",
    "line": null,
    "description": "Task 3 human-check: open 2-3 real game detail pages and confirm Valoración BGG shows a plausible 10-point score and links to that game's own BGG page -- deferred to end-of-phase UAT per human_verify_mode: end-of-phase; underlying data spot-checked via SQL (Wingspan 7.99/10 rank 38, Spirit Island 8.34/10 rank 11)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-30T23:17:30.343Z",
    "resolved_at": null
  },
  {
    "id": 15,
    "kind": "todo",
    "phase": "01.3-02",
    "file": "lib/pukllay_club/catalog/seed/bgg_client.ex",
    "line": null,
    "description": "BggClient.fetch_batch/2 raises ArgumentError (:erlang.binary_to_integer(\"\")) when called with an empty bgg_ids list, discovered via an ad hoc verification script during 01.3-02; not reachable through StatsEnricher's normal flow (chunk_every never yields an empty chunk from a non-empty candidate list) but is a latent crash if ever called with []; pre-existing 01.3-01 code, out of scope for this plan's no-code-changes constraint",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-30T23:17:30.601Z",
    "resolved_at": null
  },
  {
    "id": 16,
    "kind": "unrun-verify",
    "phase": "01.3-04",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "Human-check: open three game detail pages (short/long/unusual-title descriptions), confirm as a Spanish speaker the description reads naturally in Argentine Spanish (voseo), proper nouns/mechanic names survive untranslated, no stray escapes, and Ver mas/Ver menos still expands/collapses at mobile+desktop widths -- deferred to end-of-phase UAT per human_verify_mode: end-of-phase; text quality already reviewed by the executor against a 5-game sample (all 5 criteria incl. voseo) before the full batch ran",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-31T00:12:03.091Z",
    "resolved_at": null
  }
]
````
