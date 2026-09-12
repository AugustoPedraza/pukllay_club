---
schema_version: 1
open_count: 0
waived_count: 8
fixed_count: 18
total_count: 26
last_updated: 2026-09-12T21:52:17.249Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | quick-260818-gdb | deviation | config/runtime.exs |  | Pre-existing unstaged formatting/sobelow issues (config/runtime.exs unformatted, low-confidence Traversal.FileModule findings in seed/csv_import.ex + seed/report.ex, a Software Design credo suggestion in core_components.ex) block 'mix quality passes clean' -- none touched by this plan; task's own files (layouts.ex, tests, SKILL.md) are individually clean. | fixed | Fixed 2026-09-12 in quick 260912-pnw (def1307): function-level sobelow_skip on reviewed operator-only seed paths; mix quality passes. | 2026-08-18T14:57:00.671Z | 2026-09-12T21:52:17.249Z |
| 2 | quick-260822-2v9 | deviation | assets/css/app.css |  | Header row overflows horizontally at 375px (brand wordmark wraps, horizontal scrollbar) after the desktop header polish — narrow-viewport block confirmed byte-identical, out of scope per plan C-1, deliberately not fixed | fixed |  | 2026-08-22T05:30:01.096Z | 2026-09-12T20:35:45.479Z |
| 3 | 01.1-09 | unrun-verify | lib/pukllay_club_web/components/layouts.ex |  | Task 1 human-check: drawer opens/traps focus/closes every way (Escape, close button, backdrop, link nav) on all three routes at 390px, absent+unreachable at 1440px -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | waived | Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). Mobile drawer focus/close behaviours never exercised by a human UAT; residual risk accepted, re-check opportunistically. | 2026-08-22T14:11:54.024Z | 2026-09-12T21:18:08.219Z |
| 4 | 01.1-09 | unrun-verify | assets/css/app.css |  | Task 2 human-check: drawer rows read as full-width tappable list with chevrons and left-accent active state, toggle+socials pinned hard to the panel's bottom edge, footer sheds toggle/socials but keeps copyright+BGG attribution at 390px -- deferred to end-of-phase visual verification | waived | Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). Mobile drawer visual layout never exercised by a human UAT; residual risk accepted, re-check opportunistically. | 2026-08-22T14:11:54.190Z | 2026-09-12T21:18:08.436Z |
| 5 | 01.1-09 | unrun-verify | lib/pukllay_club_web/live/about_live.ex |  | Task 3 human-check: About sticky CTA bar stays pinned above the fold with the footer fully readable underneath at 390px scrolled to bottom, absent at 1440px and on other routes at every scroll position -- deferred to end-of-phase visual verification | waived | Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). About sticky CTA bar/footer readability at 390px not confirmed by a dedicated human check (later 01.5 CTA work touched this area); residual risk accepted. | 2026-08-22T14:11:54.347Z | 2026-09-12T21:18:08.628Z |
| 6 | 01.1-02 | deviation | lib/pukllay_club_web/live/about_live.ex |  | Four photo-rail slides render as labelled placeholders (D-12, no real club photography exists yet) -- intentional per plan, resolves when real photos are swapped in (structural no-op) | fixed |  | 2026-08-22T14:30:46.847Z | 2026-09-12T20:35:45.695Z |
| 7 | 01.1-02 | unrun-verify | lib/pukllay_club_web/live/about_live.ex |  | Photo rail human-check: dots scroll-sync, click-to-jump, auto-advance every 4.5s, pauses on pointer interaction/unfocused tab/reduced-motion -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | waived | Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). About photo rail interaction (dot sync, click-to-jump, auto-advance, pause) not human-verified; 01.4-UAT only checked photo content. Residual risk accepted. | 2026-08-22T14:30:53.492Z | 2026-09-12T21:18:08.832Z |
| 8 | 01.1-03 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | Manual human-check: at 1440px scroll /juegos/:id -- the poster column pins below the header with no overlap/gap and releases at the end of the masthead; at 390px the layout is a single column and the ficha tecnica is one column wide -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | fixed |  | 2026-08-22T19:27:49.892Z | 2026-09-12T20:35:45.907Z |
| 9 | 01.1-04 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | Manual human-check: at a real 390px viewport, the CTA bar is visible on first paint with no scroll, retracts during an active scroll and returns ~200ms after it stops, parks with the footer while body padding-bottom collapses in the same transition, and the title-echo bar fades in only after the h1 has fully scrolled past the header -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | fixed |  | 2026-08-22T20:00:25.349Z | 2026-09-12T20:35:46.113Z |
| 10 | 01.1-04 | unrun-verify | assets/css/app.css |  | Manual human-check: the mobile CTA bar's computed backgroundColor is visibly distinct from its own outlined share button's background (verify via computed style, not by eye) -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | fixed |  | 2026-08-22T20:00:32.776Z | 2026-09-12T20:35:46.320Z |
| 11 | 01.2-13 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | Task 2 human-check: buy-box reads as one bounded panel lifted off the page (not fading into the reading column) at ~390px and >=1280px in both light and dark themes, share icon anchored over the panel's top-right corner at both widths, cover art fills its frame with no letterboxing, reserve button unambiguously the page's one primary action -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | fixed |  | 2026-08-26T22:28:46.824Z | 2026-09-12T20:35:46.538Z |
| 12 | 01.2-13 | unrun-verify | assets/css/app.css |  | Task 3 human-check: at ~390px the stacked reserve+share bar reads balanced with reserve unmistakably primary, scroll-hide/reveal timing and footer-park behavior unchanged with no new jump, last real content never hidden behind the taller bar, and past 1100px (but below 768px) the bar's controls align under the content column instead of stretching edge-to-edge -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase | fixed |  | 2026-08-26T22:28:47.008Z | 2026-09-12T20:35:46.750Z |
| 13 | 01.2 | unmet-truth | lib/pukllay_club_web/live/catalog_live/index.ex |  | Active-filters chip row's visual weight balance vs the Resultados heading (sketch 029 Round 2's 'clearly secondary' intent) is asserted only via class/no-shadow presence in tests; needs a human eyeballing a live render in both themes — no browser tool available to this executor (01.2-12 D6). | waived | Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). Subjective visual-weight judgment (active-filter chip row vs Resultados heading); structural intent pinned by tests. Accepted as-is. | 2026-08-26T22:51:30.480Z | 2026-09-12T21:18:09.033Z |
| 14 | 01.3-02 | unrun-verify | lib/mix/tasks/catalog.enrich_bgg_stats.ex |  | Task 3 human-check: open 2-3 real game detail pages and confirm Valoración BGG shows a plausible 10-point score and links to that game's own BGG page -- deferred to end-of-phase UAT per human_verify_mode: end-of-phase; underlying data spot-checked via SQL (Wingspan 7.99/10 rank 38, Spirit Island 8.34/10 rank 11) | fixed |  | 2026-08-30T23:17:30.343Z | 2026-09-12T20:27:42.288Z |
| 15 | 01.3-02 | todo | lib/pukllay_club/catalog/seed/bgg_client.ex |  | BggClient.fetch_batch/2 raises ArgumentError (:erlang.binary_to_integer("")) when called with an empty bgg_ids list, discovered via an ad hoc verification script during 01.3-02; not reachable through StatsEnricher's normal flow (chunk_every never yields an empty chunk from a non-empty candidate list) but is a latent crash if ever called with []; pre-existing 01.3-01 code, out of scope for this plan's no-code-changes constraint | fixed | Fixed 2026-09-12 in quick 260912-pnv (048f607): fetch_batch([], _) returns {:ok, []} without a request; regression test added. | 2026-08-30T23:17:30.601Z | 2026-09-12T21:52:17.249Z |
| 16 | 01.3-04 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | Human-check: open three game detail pages (short/long/unusual-title descriptions), confirm as a Spanish speaker the description reads naturally in Argentine Spanish (voseo), proper nouns/mechanic names survive untranslated, no stray escapes, and Ver mas/Ver menos still expands/collapses at mobile+desktop widths -- deferred to end-of-phase UAT per human_verify_mode: end-of-phase; text quality already reviewed by the executor against a 5-game sample (all 5 criteria incl. voseo) before the full batch ran | fixed |  | 2026-08-31T00:12:03.091Z | 2026-09-12T20:35:46.958Z |
| 17 | 01.3 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | Manual visual verification of the D-03/D-04 reading-column rhythm and D-06 Avanzado group at 390px/1440px against 01.3-UI-SPEC.md not run interactively (no browser tool available to this executor); deferred to end-of-phase UAT per workflow.human_verify_mode: end-of-phase. | fixed |  | 2026-08-31T00:35:26.436Z | 2026-09-12T20:35:47.148Z |
| 18 | 01.3 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | 01.3-07 manual visual verification at 390px/1440px (hashtag position/tone, no divider, tappable creator pills, fact-grid pairing/stacking, Comunidad BGG label) deferred to end-of-phase UAT per workflow.human_verify_mode | waived | Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). 01.3-UAT test 1 confirmed 4 of 5 sub-items; only 'tappable creator pills' was never explicitly confirmed. Residual risk accepted. | 2026-08-31T20:19:55.896Z | 2026-09-12T21:18:09.464Z |
| 19 | 01.3 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | 01.3-08 Task 3 human-check deferred to end-of-phase UAT (human_verify_mode=end-of-phase): verify description justify + mid-word-cut risk (fallback pre-decided) + chevron/ellipsis ink alignment (translateY(-2px), tuned but unverified against real Inter render) + repeated tap round-trips, across 3 real games x 2 widths (390/1440) x 2 themes; if any of the 6 combos cuts mid-word, apply this plan's pre-decided fallback CSS (real -webkit-line-clamp:3 + trailing-sibling toggle, recorded in 01.3-08-PLAN.md's planner_note) rather than re-sketching. | fixed |  | 2026-08-31T20:39:49.123Z | 2026-09-12T20:35:47.351Z |
| 20 | 01.3 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | 01.3-10 Task 2 human-check deferred to end-of-phase UAT (human_verify_mode=end-of-phase): verify on a real iOS/Mobile-Safari device (the engine G-01.3-4 reproduced on, not Blink) that the chevron sits inside the text column at 390px, the clipped third line ends on a whole word, tapping expands/collapses reliably across round trips, and the description stays justified at 390px/1440px, across light+dark theme and a short + long description game. | fixed |  | 2026-08-31T23:15:03.802Z | 2026-09-01T11:03:15.503Z |
| 21 | 01.3-11 | unrun-verify | assets/css/app.css |  | 01.3-11 Task 2 human-check deferred to end-of-phase UAT (human_verify_mode=end-of-phase): at 390px, both light and dark theme, on a long game name with an accented capital and one that truncates, verify the sticky bar's title reads as a deliberate title (holds its own against the scroll-to-top button), stays on ONE line ending in an ellipsis, accented capitals render complete, and the bar's fill/border/button remain visually unchanged from before this plan. | fixed |  | 2026-08-31T23:29:56.119Z | 2026-09-01T02:15:46.887Z |
| 22 | 01.3-12 | unrun-verify | lib/pukllay_club_web/live/catalog_live/show.ex |  | 01.3-12 Task 2 human-check deferred to end-of-phase UAT (human_verify_mode=end-of-phase): on a real iOS/Mobile-Safari device at 390px and 1440px, both light and dark theme, across Honey Buzz (113)/Mille Fiori (193)/Illusion (396)/a short-description game/7 Wonders Duel, verify the chevron trails the clipped third line (not a row below it), the reserved right gutter reads acceptably on lines 1-2 at 390px (else apply the planner_note's pre-decided padding-right:1.75rem + hover/active-background-neutralised fallback pair, not a hand-tuned middle value), a near-full-width third line stays clear of the chevron, repeated expand/collapse stays reliable with no jump/flicker at the absolute/in-flow position switch, and the description stays justified with the third line ending on a whole word. | fixed |  | 2026-09-01T01:54:50.616Z | 2026-09-01T11:03:15.710Z |
| 23 | 01.4 | stub | priv/static/images/about-maps-thumb-dark.jpg |  | Dark Maps thumbnail is a byte-identical copy of the light asset — no genuine dark-mode capture achieved this session; needs a real dark-tile capture (likely via the Maps mobile app), no code change required | fixed | moot; the dark asset was deleted in plan 01.4-12 along with its light twin when D-11 replaced the static screenshot pair with a live embed. There is no longer a dark capture to obtain. | 2026-09-05T14:47:28.044Z | 2026-09-06T01:50:23.255Z |
| 24 | 01.5 | unrun-verify | .planning/phases/01.5-about-page-cta-rhythm-header-morph-refinement-implement-sket/01.5-07-SUMMARY.md |  | Cierre band 70vh proportion + visual balance at 768px/1280px deferred to end-of-phase human walkthrough (coverage D6) | waived | Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). Cierre band proportion verified at 375px/1280px (01.5-UAT test 20) and by automated CDP probe; 768px never human-checked. Residual risk accepted. | 2026-09-08T17:30:26.779Z | 2026-09-12T21:18:09.701Z |
| 25 | quick-260910-efe | deviation | test/pukllay_club_web/live/catalog_show_test.exs | 4316 | Rewrote .pk-pill-tag WCAG contrast test to measure what actually renders per theme (--color-primary in light, dark-scoped --color-neutral override in dark) instead of a stale hardcoded-token comparison, after sketch 055 Option A changed dark's primary-as-text mechanism; 4.5:1 floor unchanged | waived | Accepted per quick-260910-efe SUMMARY.md: .pk-pill-tag contrast test deliberately rewritten (Rule 1 auto-fix) to measure the actually-rendered ink per theme after sketch 055 Option A's dark-scoped --color-neutral override made the old hardcoded --color-primary comparison structurally false; 4.5:1 WCAG floor unchanged, test passes (catalog_show_test.exs:4692) | 2026-09-10T14:35:17.674Z | 2026-09-12T20:35:55.391Z |
| 26 | 01.8-05 | stub | priv/static/images/og-fallback.webp |  | OG-fallback branded share card (SHARE-04, D-04/D-05) not yet on disk -- blocked on a /gsd-sketch round (Task 2 checkpoint, gate=blocking-human); GET / and GET /club's og:image/twitter:image 404 until the sketch-approved asset lands | fixed |  | 2026-09-12T03:07:10.127Z | 2026-09-12T03:32:01.626Z |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "quick-260818-gdb",
    "file": "config/runtime.exs",
    "line": null,
    "description": "Pre-existing unstaged formatting/sobelow issues (config/runtime.exs unformatted, low-confidence Traversal.FileModule findings in seed/csv_import.ex + seed/report.ex, a Software Design credo suggestion in core_components.ex) block 'mix quality passes clean' -- none touched by this plan; task's own files (layouts.ex, tests, SKILL.md) are individually clean.",
    "status": "fixed",
    "reason": "Fixed 2026-09-12 in quick 260912-pnw (def1307): function-level sobelow_skip on reviewed operator-only seed paths; mix quality passes.",
    "recorded_at": "2026-08-18T14:57:00.671Z",
    "resolved_at": "2026-09-12T21:52:17.249Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "quick-260822-2v9",
    "file": "assets/css/app.css",
    "line": null,
    "description": "Header row overflows horizontally at 375px (brand wordmark wraps, horizontal scrollbar) after the desktop header polish — narrow-viewport block confirmed byte-identical, out of scope per plan C-1, deliberately not fixed",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-22T05:30:01.096Z",
    "resolved_at": "2026-09-12T20:35:45.479Z"
  },
  {
    "id": 3,
    "kind": "unrun-verify",
    "phase": "01.1-09",
    "file": "lib/pukllay_club_web/components/layouts.ex",
    "line": null,
    "description": "Task 1 human-check: drawer opens/traps focus/closes every way (Escape, close button, backdrop, link nav) on all three routes at 390px, absent+unreachable at 1440px -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "waived",
    "reason": "Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). Mobile drawer focus/close behaviours never exercised by a human UAT; residual risk accepted, re-check opportunistically.",
    "recorded_at": "2026-08-22T14:11:54.024Z",
    "resolved_at": "2026-09-12T21:18:08.219Z"
  },
  {
    "id": 4,
    "kind": "unrun-verify",
    "phase": "01.1-09",
    "file": "assets/css/app.css",
    "line": null,
    "description": "Task 2 human-check: drawer rows read as full-width tappable list with chevrons and left-accent active state, toggle+socials pinned hard to the panel's bottom edge, footer sheds toggle/socials but keeps copyright+BGG attribution at 390px -- deferred to end-of-phase visual verification",
    "status": "waived",
    "reason": "Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). Mobile drawer visual layout never exercised by a human UAT; residual risk accepted, re-check opportunistically.",
    "recorded_at": "2026-08-22T14:11:54.190Z",
    "resolved_at": "2026-09-12T21:18:08.436Z"
  },
  {
    "id": 5,
    "kind": "unrun-verify",
    "phase": "01.1-09",
    "file": "lib/pukllay_club_web/live/about_live.ex",
    "line": null,
    "description": "Task 3 human-check: About sticky CTA bar stays pinned above the fold with the footer fully readable underneath at 390px scrolled to bottom, absent at 1440px and on other routes at every scroll position -- deferred to end-of-phase visual verification",
    "status": "waived",
    "reason": "Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). About sticky CTA bar/footer readability at 390px not confirmed by a dedicated human check (later 01.5 CTA work touched this area); residual risk accepted.",
    "recorded_at": "2026-08-22T14:11:54.347Z",
    "resolved_at": "2026-09-12T21:18:08.628Z"
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "01.1-02",
    "file": "lib/pukllay_club_web/live/about_live.ex",
    "line": null,
    "description": "Four photo-rail slides render as labelled placeholders (D-12, no real club photography exists yet) -- intentional per plan, resolves when real photos are swapped in (structural no-op)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-22T14:30:46.847Z",
    "resolved_at": "2026-09-12T20:35:45.695Z"
  },
  {
    "id": 7,
    "kind": "unrun-verify",
    "phase": "01.1-02",
    "file": "lib/pukllay_club_web/live/about_live.ex",
    "line": null,
    "description": "Photo rail human-check: dots scroll-sync, click-to-jump, auto-advance every 4.5s, pauses on pointer interaction/unfocused tab/reduced-motion -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "waived",
    "reason": "Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). About photo rail interaction (dot sync, click-to-jump, auto-advance, pause) not human-verified; 01.4-UAT only checked photo content. Residual risk accepted.",
    "recorded_at": "2026-08-22T14:30:53.492Z",
    "resolved_at": "2026-09-12T21:18:08.832Z"
  },
  {
    "id": 8,
    "kind": "unrun-verify",
    "phase": "01.1-03",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "Manual human-check: at 1440px scroll /juegos/:id -- the poster column pins below the header with no overlap/gap and releases at the end of the masthead; at 390px the layout is a single column and the ficha tecnica is one column wide -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-22T19:27:49.892Z",
    "resolved_at": "2026-09-12T20:35:45.907Z"
  },
  {
    "id": 9,
    "kind": "unrun-verify",
    "phase": "01.1-04",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "Manual human-check: at a real 390px viewport, the CTA bar is visible on first paint with no scroll, retracts during an active scroll and returns ~200ms after it stops, parks with the footer while body padding-bottom collapses in the same transition, and the title-echo bar fades in only after the h1 has fully scrolled past the header -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-22T20:00:25.349Z",
    "resolved_at": "2026-09-12T20:35:46.113Z"
  },
  {
    "id": 10,
    "kind": "unrun-verify",
    "phase": "01.1-04",
    "file": "assets/css/app.css",
    "line": null,
    "description": "Manual human-check: the mobile CTA bar's computed backgroundColor is visibly distinct from its own outlined share button's background (verify via computed style, not by eye) -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-22T20:00:32.776Z",
    "resolved_at": "2026-09-12T20:35:46.320Z"
  },
  {
    "id": 11,
    "kind": "unrun-verify",
    "phase": "01.2-13",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "Task 2 human-check: buy-box reads as one bounded panel lifted off the page (not fading into the reading column) at ~390px and >=1280px in both light and dark themes, share icon anchored over the panel's top-right corner at both widths, cover art fills its frame with no letterboxing, reserve button unambiguously the page's one primary action -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-26T22:28:46.824Z",
    "resolved_at": "2026-09-12T20:35:46.538Z"
  },
  {
    "id": 12,
    "kind": "unrun-verify",
    "phase": "01.2-13",
    "file": "assets/css/app.css",
    "line": null,
    "description": "Task 3 human-check: at ~390px the stacked reserve+share bar reads balanced with reserve unmistakably primary, scroll-hide/reveal timing and footer-park behavior unchanged with no new jump, last real content never hidden behind the taller bar, and past 1100px (but below 768px) the bar's controls align under the content column instead of stretching edge-to-edge -- no browser test runner in this suite, deferred to end-of-phase per human_verify_mode: end-of-phase",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-26T22:28:47.008Z",
    "resolved_at": "2026-09-12T20:35:46.750Z"
  },
  {
    "id": 13,
    "kind": "unmet-truth",
    "phase": "01.2",
    "file": "lib/pukllay_club_web/live/catalog_live/index.ex",
    "line": null,
    "description": "Active-filters chip row's visual weight balance vs the Resultados heading (sketch 029 Round 2's 'clearly secondary' intent) is asserted only via class/no-shadow presence in tests; needs a human eyeballing a live render in both themes — no browser tool available to this executor (01.2-12 D6).",
    "status": "waived",
    "reason": "Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). Subjective visual-weight judgment (active-filter chip row vs Resultados heading); structural intent pinned by tests. Accepted as-is.",
    "recorded_at": "2026-08-26T22:51:30.480Z",
    "resolved_at": "2026-09-12T21:18:09.033Z"
  },
  {
    "id": 14,
    "kind": "unrun-verify",
    "phase": "01.3-02",
    "file": "lib/mix/tasks/catalog.enrich_bgg_stats.ex",
    "line": null,
    "description": "Task 3 human-check: open 2-3 real game detail pages and confirm Valoración BGG shows a plausible 10-point score and links to that game's own BGG page -- deferred to end-of-phase UAT per human_verify_mode: end-of-phase; underlying data spot-checked via SQL (Wingspan 7.99/10 rank 38, Spirit Island 8.34/10 rank 11)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-30T23:17:30.343Z",
    "resolved_at": "2026-09-12T20:27:42.288Z"
  },
  {
    "id": 15,
    "kind": "todo",
    "phase": "01.3-02",
    "file": "lib/pukllay_club/catalog/seed/bgg_client.ex",
    "line": null,
    "description": "BggClient.fetch_batch/2 raises ArgumentError (:erlang.binary_to_integer(\"\")) when called with an empty bgg_ids list, discovered via an ad hoc verification script during 01.3-02; not reachable through StatsEnricher's normal flow (chunk_every never yields an empty chunk from a non-empty candidate list) but is a latent crash if ever called with []; pre-existing 01.3-01 code, out of scope for this plan's no-code-changes constraint",
    "status": "fixed",
    "reason": "Fixed 2026-09-12 in quick 260912-pnv (048f607): fetch_batch([], _) returns {:ok, []} without a request; regression test added.",
    "recorded_at": "2026-08-30T23:17:30.601Z",
    "resolved_at": "2026-09-12T21:52:17.249Z"
  },
  {
    "id": 16,
    "kind": "unrun-verify",
    "phase": "01.3-04",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "Human-check: open three game detail pages (short/long/unusual-title descriptions), confirm as a Spanish speaker the description reads naturally in Argentine Spanish (voseo), proper nouns/mechanic names survive untranslated, no stray escapes, and Ver mas/Ver menos still expands/collapses at mobile+desktop widths -- deferred to end-of-phase UAT per human_verify_mode: end-of-phase; text quality already reviewed by the executor against a 5-game sample (all 5 criteria incl. voseo) before the full batch ran",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-31T00:12:03.091Z",
    "resolved_at": "2026-09-12T20:35:46.958Z"
  },
  {
    "id": 17,
    "kind": "unrun-verify",
    "phase": "01.3",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "Manual visual verification of the D-03/D-04 reading-column rhythm and D-06 Avanzado group at 390px/1440px against 01.3-UI-SPEC.md not run interactively (no browser tool available to this executor); deferred to end-of-phase UAT per workflow.human_verify_mode: end-of-phase.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-31T00:35:26.436Z",
    "resolved_at": "2026-09-12T20:35:47.148Z"
  },
  {
    "id": 18,
    "kind": "unrun-verify",
    "phase": "01.3",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "01.3-07 manual visual verification at 390px/1440px (hashtag position/tone, no divider, tappable creator pills, fact-grid pairing/stacking, Comunidad BGG label) deferred to end-of-phase UAT per workflow.human_verify_mode",
    "status": "waived",
    "reason": "Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). 01.3-UAT test 1 confirmed 4 of 5 sub-items; only 'tappable creator pills' was never explicitly confirmed. Residual risk accepted.",
    "recorded_at": "2026-08-31T20:19:55.896Z",
    "resolved_at": "2026-09-12T21:18:09.464Z"
  },
  {
    "id": 19,
    "kind": "unrun-verify",
    "phase": "01.3",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "01.3-08 Task 3 human-check deferred to end-of-phase UAT (human_verify_mode=end-of-phase): verify description justify + mid-word-cut risk (fallback pre-decided) + chevron/ellipsis ink alignment (translateY(-2px), tuned but unverified against real Inter render) + repeated tap round-trips, across 3 real games x 2 widths (390/1440) x 2 themes; if any of the 6 combos cuts mid-word, apply this plan's pre-decided fallback CSS (real -webkit-line-clamp:3 + trailing-sibling toggle, recorded in 01.3-08-PLAN.md's planner_note) rather than re-sketching.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-31T20:39:49.123Z",
    "resolved_at": "2026-09-12T20:35:47.351Z"
  },
  {
    "id": 20,
    "kind": "unrun-verify",
    "phase": "01.3",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "01.3-10 Task 2 human-check deferred to end-of-phase UAT (human_verify_mode=end-of-phase): verify on a real iOS/Mobile-Safari device (the engine G-01.3-4 reproduced on, not Blink) that the chevron sits inside the text column at 390px, the clipped third line ends on a whole word, tapping expands/collapses reliably across round trips, and the description stays justified at 390px/1440px, across light+dark theme and a short + long description game.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-31T23:15:03.802Z",
    "resolved_at": "2026-09-01T11:03:15.503Z"
  },
  {
    "id": 21,
    "kind": "unrun-verify",
    "phase": "01.3-11",
    "file": "assets/css/app.css",
    "line": null,
    "description": "01.3-11 Task 2 human-check deferred to end-of-phase UAT (human_verify_mode=end-of-phase): at 390px, both light and dark theme, on a long game name with an accented capital and one that truncates, verify the sticky bar's title reads as a deliberate title (holds its own against the scroll-to-top button), stays on ONE line ending in an ellipsis, accented capitals render complete, and the bar's fill/border/button remain visually unchanged from before this plan.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-31T23:29:56.119Z",
    "resolved_at": "2026-09-01T02:15:46.887Z"
  },
  {
    "id": 22,
    "kind": "unrun-verify",
    "phase": "01.3-12",
    "file": "lib/pukllay_club_web/live/catalog_live/show.ex",
    "line": null,
    "description": "01.3-12 Task 2 human-check deferred to end-of-phase UAT (human_verify_mode=end-of-phase): on a real iOS/Mobile-Safari device at 390px and 1440px, both light and dark theme, across Honey Buzz (113)/Mille Fiori (193)/Illusion (396)/a short-description game/7 Wonders Duel, verify the chevron trails the clipped third line (not a row below it), the reserved right gutter reads acceptably on lines 1-2 at 390px (else apply the planner_note's pre-decided padding-right:1.75rem + hover/active-background-neutralised fallback pair, not a hand-tuned middle value), a near-full-width third line stays clear of the chevron, repeated expand/collapse stays reliable with no jump/flicker at the absolute/in-flow position switch, and the description stays justified with the third line ending on a whole word.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-01T01:54:50.616Z",
    "resolved_at": "2026-09-01T11:03:15.710Z"
  },
  {
    "id": 23,
    "kind": "stub",
    "phase": "01.4",
    "file": "priv/static/images/about-maps-thumb-dark.jpg",
    "line": null,
    "description": "Dark Maps thumbnail is a byte-identical copy of the light asset — no genuine dark-mode capture achieved this session; needs a real dark-tile capture (likely via the Maps mobile app), no code change required",
    "status": "fixed",
    "reason": "moot; the dark asset was deleted in plan 01.4-12 along with its light twin when D-11 replaced the static screenshot pair with a live embed. There is no longer a dark capture to obtain.",
    "recorded_at": "2026-09-05T14:47:28.044Z",
    "resolved_at": "2026-09-06T01:50:23.255Z"
  },
  {
    "id": 24,
    "kind": "unrun-verify",
    "phase": "01.5",
    "file": ".planning/phases/01.5-about-page-cta-rhythm-header-morph-refinement-implement-sket/01.5-07-SUMMARY.md",
    "line": null,
    "description": "Cierre band 70vh proportion + visual balance at 768px/1280px deferred to end-of-phase human walkthrough (coverage D6)",
    "status": "waived",
    "reason": "Accepted by user 2026-09-12 to unblock /gsd-ship (260912-mxt follow-up). Cierre band proportion verified at 375px/1280px (01.5-UAT test 20) and by automated CDP probe; 768px never human-checked. Residual risk accepted.",
    "recorded_at": "2026-09-08T17:30:26.779Z",
    "resolved_at": "2026-09-12T21:18:09.701Z"
  },
  {
    "id": 25,
    "kind": "deviation",
    "phase": "quick-260910-efe",
    "file": "test/pukllay_club_web/live/catalog_show_test.exs",
    "line": 4316,
    "description": "Rewrote .pk-pill-tag WCAG contrast test to measure what actually renders per theme (--color-primary in light, dark-scoped --color-neutral override in dark) instead of a stale hardcoded-token comparison, after sketch 055 Option A changed dark's primary-as-text mechanism; 4.5:1 floor unchanged",
    "status": "waived",
    "reason": "Accepted per quick-260910-efe SUMMARY.md: .pk-pill-tag contrast test deliberately rewritten (Rule 1 auto-fix) to measure the actually-rendered ink per theme after sketch 055 Option A's dark-scoped --color-neutral override made the old hardcoded --color-primary comparison structurally false; 4.5:1 WCAG floor unchanged, test passes (catalog_show_test.exs:4692)",
    "recorded_at": "2026-09-10T14:35:17.674Z",
    "resolved_at": "2026-09-12T20:35:55.391Z"
  },
  {
    "id": 26,
    "kind": "stub",
    "phase": "01.8-05",
    "file": "priv/static/images/og-fallback.webp",
    "line": null,
    "description": "OG-fallback branded share card (SHARE-04, D-04/D-05) not yet on disk -- blocked on a /gsd-sketch round (Task 2 checkpoint, gate=blocking-human); GET / and GET /club's og:image/twitter:image 404 until the sketch-approved asset lands",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-12T03:07:10.127Z",
    "resolved_at": "2026-09-12T03:32:01.626Z"
  }
]
````
