---
status: resolved
trigger: "Investigate issue: lightbox-still-not-full-screen — plan 01.2-29 changed .pk-lightbox-img's CSS height from height: 80vh to height: 100vh; height: 100dvh; (dual declaration), independently confirmed correct in source, built stylesheet, and passing tests (645/645) — yet the user's live browser (mobile + desktop ~1920px screenshots) still shows a light-lavender/purple scrim band above/below the dark stage, the exact symptom the fix was supposed to close."
created: 2026-08-28T17:15:00Z
updated: 2026-08-28T17:44:00Z
---

## Current Focus

hypothesis: CONFIRMED — the project's `config/dev.exs` has never (in its full git history) configured `:live_reload` `:patterns` for the Phoenix endpoint. `Phoenix.LiveReloader`'s plug/socket are wired into `endpoint.ex` and the reload iframe IS injected into every served page, but with no patterns configured there is nothing for its file-watcher backend to watch, so it never fires a reload/CSS-patch event when `priv/static/assets/css/app.css` is rebuilt. A LiveView page's `<link rel="stylesheet">` is fetched exactly once, at real page load/navigation — client-side `phx-click`/socket-push interactions (opening the lightbox, stepping through gallery images) never re-fetch it. Any already-open browser tab from before plan 01.2-29's CSS landed (or any tab that was never hard-reloaded after it landed) is therefore still running the pre-fix `height: 80vh` stylesheet it originally fetched, while the server, the built asset, the source, and every automated check now correctly show the post-fix `height: 100vh; height: 100dvh;` pair.
test: n/a — goal is find_root_cause_only; no fix applied this session.
expecting: n/a
next_action: Return ROOT CAUSE FOUND to caller. Recommended fix direction (not applied): add a `:live_reload` `:patterns` block to `config/dev.exs` (the standard `phx.new` scaffold block, covering `priv/static/**/*.{js,css,png,jpeg,jpg,gif,svg}`, `priv/gettext/**/*.po`, and `lib/pukllay_club_web/{controllers,live,components}/**/*.{ex,heex}`) so future dev-mode asset changes propagate to already-open tabs automatically; and confirm with the user that a hard reload (not just re-opening the lightbox) of the actual page they're testing on now shows the full-height stage.

## Symptoms

expected: No scrim/lavender band above or below the lightbox's opaque stage at any viewport, per plan 01.2-29 and UAT test 19.
actual: User reports (verbatim): "on mobile and desktop, the backgroun must to be full screen(not leaving any part not covered by the \"black\")\nI think for desktop too" — with screenshots showing a light-lavender band still occupying roughly the top third and bottom third of the viewport at desktop 1920px, and a thinner sliver at mobile top/bottom.
errors: None reported
reproduction: Open the lightbox on the running dev server at http://localhost:4000/juegos/<any game with 2+ gallery images> — click a gallery thumbnail or the main image to open the lightbox, then check at both a mobile width (~390px) and a wide desktop width (~1920px).
started: Discovered during UAT test 19, immediately after plan 01.2-29 (which was verified correct by both the executor and the phase verifier) executed and merged.

## Eliminated

- hypothesis: "The `.pk-lightbox-img` CSS declaration itself is wrong or was not correctly applied (source-level bug)."
  evidence: Read `assets/css/app.css:3449-3464` directly in this worktree — the rule declares `height: 100vh;` immediately followed by `height: 100dvh;`, exactly as plan 01.2-29 specifies, with no third `height` declaration anywhere in the brace body and no other declaration touched. Byte-identical to what the plan's SUMMARY and the phase verifier already confirmed.
  timestamp: 2026-08-28T17:16:00Z

- hypothesis: "A CSS specificity/cascade conflict — a second rule targeting `.pk-lightbox-img` (or an ancestor) sets a competing height that wins the cascade."
  evidence: `grep -n "pk-lightbox" assets/css/app.css` surfaced exactly one other rule touching `.pk-lightbox-img`: `.pk-lightbox.is-open .pk-lightbox-img { transform: scale(1); }` at line 3466 — it sets only `transform`, no `height`/`max-height`/`min-height`. No Tailwind utility class is mixed onto the `<img class="pk-lightbox-img">` element in `show.ex:781-786` (single class, nothing else), so there is no unlayered-vs-layered Tailwind conflict either (and the file's own cascade-layer hazard comment at the top of app.css already documents that pattern and would have applied equally to the width fix in the prior round, which is confirmed working).
  timestamp: 2026-08-28T17:18:00Z

- hypothesis: "`.pk-lightbox-img` in the rendered DOM isn't the element the user is visually reading as 'the stage' — they're judging `.pk-lightbox` itself or some wrapper instead."
  evidence: `show.ex:781-786` confirms `.pk-lightbox-img` IS the `<img>` tag directly (no wrapper div) inside `.pk-lightbox` (`position: fixed; inset: 0`, flex-centered, background `var(--pk-overlay-scrim)`). `--pk-overlay-scrim` resolves to `color-mix(in srgb, var(--pk-shadow-color) 72%, transparent)` and `--pk-shadow-color` is `rgb(20 8 34)` (dark violet) — a 72%-strength dark-violet tint over a light theme's page background renders exactly as a light-lavender/purple translucent band, matching the user's own description of what surrounds "the dark stage." The user is correctly identifying `.pk-lightbox-img` as the dark stage and `.pk-lightbox`'s own scrim as the band around it — this is precisely the mechanism the plan's own comment (`app.css:3425-3429`) describes as the bug, not a misidentification.
  timestamp: 2026-08-28T17:20:00Z

- hypothesis: "The built/served stylesheet on the machine the user is actually testing against does not carry the fix (a build-pipeline or worktree-isolation staleness issue)."
  evidence: This debug session is running inside git worktree `.claude/worktrees/agent-a5c51ee8330adafb4` (branch `worktree-agent-a5c51ee8330adafb4`), separate from the main checkout at `/home/apedraza/projects/pukllay_club` (branch `main`) where the actual running `mix phx.server` process (PID 2320792) and its `tailwind --watch` (PID 2320931) / `esbuild --watch` (PID 2320930) processes live (confirmed via `/proc/<pid>/cwd`). Read `/home/apedraza/projects/pukllay_club/assets/css/app.css` (main checkout, no `cd`+`git` combo, plain read) directly: it already carries the identical `height: 100vh; height: 100dvh;` pair, byte-identical in content/size (193640 bytes) to this worktree's copy, just a different inode — meaning the fix has already reached the main checkout's source. `curl -s -D - http://localhost:4000/assets/css/app.css` against the actual running dev server returned HTTP 200 with the correct dual-declaration rule present in the response body (confirmed via grep on the curled bytes at line 5071-5072 of the served file). So the server the user's browser talks to is demonstrably serving the fixed CSS right now, on demand.
  timestamp: 2026-08-28T17:28:00Z

## Evidence

- timestamp: 2026-08-28T17:16:00Z
  checked: `assets/css/app.css` lines 3357-3464 (`.pk-lightbox`, `.pk-lightbox-img`, `.pk-lightbox.is-open .pk-lightbox-img`) and `lib/pukllay_club_web/live/catalog_live/show.ex` lines 664-798 (lightbox markup)
  found: `.pk-lightbox` is `position: fixed; inset: 0; display: flex; align-items: center; justify-content: center; background: var(--pk-overlay-scrim);` — a centering, non-stretching flex parent. `.pk-lightbox-img` is the bare `<img class="pk-lightbox-img">` (no wrapper div, no extra Tailwind classes), with `width: var(--pk-shell-content-width); height: 100vh; height: 100dvh; background: var(--pk-shadow-color); object-fit: contain; ...`. No third height declaration, no override in any later rule.
  implication: The CSS mechanism itself is correct and matches the plan's spec exactly. If the browser is still short of full height, the cause is not in this rule's declarations.

- timestamp: 2026-08-28T17:20:00Z
  checked: `ps aux | grep -E "phx.server|tailwind|esbuild"` plus `/proc/<pid>/cwd` for each matched PID
  found: `mix phx.server` (PID 2320792, started "Aug27" — i.e. running since before today's plan landed), `esbuild --watch` (PID 2320930), and `tailwind --watch` (PID 2320931) are all running with cwd `/home/apedraza/projects/pukllay_club` — the MAIN checkout, not this debug session's isolated worktree.
  implication: This is the process actually serving `localhost:4000` to the user's browser. Any staleness has to be evaluated against the main checkout's files and this running server's live HTTP responses, not against files in this worktree alone.

- timestamp: 2026-08-28T17:24:00Z
  checked: `stat`/`grep` on `/home/apedraza/projects/pukllay_club/assets/css/app.css` (main checkout source) and `/home/apedraza/projects/pukllay_club/priv/static/assets/css/app.css` (main checkout built/served file)
  found: Both already contain the dual `height: 100vh; height: 100dvh;` declaration, byte-size-identical (193640 bytes) to this worktree's source copy. The built file's mtime (1787933161) is 3 seconds after the source's mtime (1787933158), consistent with the tailwind watcher having rebuilt it promptly after the source changed.
  implication: The fix genuinely reached the main checkout that the dev server is running from — this rules out worktree-isolation staleness as the mechanism. The watcher pipeline worked correctly.

- timestamp: 2026-08-28T17:26:54Z
  checked: `curl -s -D - http://localhost:4000/assets/css/app.css`
  found: HTTP 200, `content-length: 175139`, `cache-control: public` (no `max-age`/`Expires`), `etag: "616E7E9"`. Body contains, at its own line 5071-5072, `height: 100vh;` immediately followed by `height: 100dvh;` inside `.pk-lightbox-img { ... }`.
  implication: The live, currently-running dev server DOES serve the correct, fixed CSS to any fresh request right now. Whatever the user is seeing in their browser is not what a fresh HTTP fetch of this URL returns today.

- timestamp: 2026-08-28T17:31:00Z
  checked: `config/dev.exs` in full, plus `grep -n "LiveReloader\|code_reloading\|live_reload" lib/pukllay_club_web/endpoint.ex`
  found: `endpoint.ex` wires `socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket` and `plug Phoenix.LiveReloader` when `code_reloading?` is true (dev only) — standard. `config/dev.exs`'s `PukllayClubWeb.Endpoint` config block, however, contains no `:live_reload` key at all — no `patterns:` list, nothing. `curl http://localhost:4000/juegos/22 | grep phoenix/live_reload` confirms the reload iframe script IS injected into the served page (so the plug/socket machinery is present and wired), but `Phoenix.LiveReloader`'s backend reads `endpoint.config(:live_reload, [])[:patterns]` to know which files to watch — with no patterns configured, it has nothing to watch and will never broadcast a reload/CSS-patch event, regardless of how many times the asset pipeline rebuilds `priv/static/assets/css/app.css`.
  implication: Any browser tab that isn't independently, manually reloaded after a CSS change ships will never pick that change up automatically in this project — this has been true since the app's very first scaffold commit (see next entry), not something plan 01.2-29 introduced or broke.

- timestamp: 2026-08-28T17:33:00Z
  checked: `git log --oneline --all -- config/dev.exs` and `git log -p --all -- config/dev.exs | grep -n "live_reload"`
  found: Six commits touch `config/dev.exs` across the project's full history, starting from the very first scaffold commit (`f432d98 feat(00-01): scaffold Phoenix app + /up health route`). Not one of them, at any point, ever introduces a `live_reload:` key.
  implication: This is not a regression from plan 01.2-29 or any recent round — the project has never had working dev-mode CSS live-reload. It has simply gone unnoticed until now because most prior CSS-affecting rounds were verified via fresh page loads (new dev-server sessions, new tabs) rather than an already-open tab surviving across the fix landing.

## Resolution

root_cause: "The `.pk-lightbox-img` CSS fix from plan 01.2-29 is correct and live on the server (confirmed via direct source read, built-stylesheet read, and a live `curl` against the running dev server — all three show `height: 100vh; height: 100dvh;`). The user's browser is not seeing it because `config/dev.exs` has never configured `Phoenix.LiveReloader`'s `:live_reload` `:patterns` option (verified absent across the project's entire git history) — so, although the reload-iframe plug/socket are wired into the endpoint, there is nothing for its file-watcher backend to watch, and rebuilding `priv/static/assets/css/app.css` never triggers a push to any already-open browser tab to re-fetch or hot-patch its stylesheet. A LiveView page's `<link rel=\"stylesheet\">` is fetched once, at real page load; opening/stepping through the lightbox is all client-side socket/DOM activity that never re-requests it. Any tab that was open (or was reloaded without a genuine hard refresh) before this round's CSS landed is still rendering the pre-fix `height: 80vh` stage, reproducing exactly the reported light-lavender scrim band above/below it — on every device that tab happens to be open on, mobile or desktop alike, independent of viewport width."
fix: (not applied — goal: find_root_cause_only)
verification: (not applicable — no fix applied this session)
files_changed: []
