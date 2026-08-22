---
schema_version: 1
open_count: 8
waived_count: 0
fixed_count: 0
total_count: 8
last_updated: 2026-08-22T19:27:49.892Z
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
  }
]
````
