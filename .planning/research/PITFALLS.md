# Pitfalls Research: SEO/Social-Sharing/Security-Hardening on an Existing LiveView App

**Domain:** Adding SEO metadata, OG/Twitter Card tags, JSON-LD, sitemap.xml, and security hardening to an existing, publicly-deployed Phoenix 1.8 LiveView app (PukllayClub, v1.1 milestone)
**Researched:** 2026-09-11
**Confidence:** MEDIUM-HIGH (LiveView head/meta-tag limitations are corroborated by Phoenix LiveView's own GitHub issue tracker and a José Valim forum reply — HIGH; CSP/nonce and secret-scanning specifics are MEDIUM, cross-checked across 2-3 independent sources each)

## Critical Pitfalls

### Pitfall 1: OG/Twitter meta tags computed in `handle_params`/`mount` never reach the crawler

**What goes wrong:**
Social preview tags (`og:title`, `og:description`, `og:image`, `twitter:card`, etc.) get added as LiveView `assign`s and referenced in `root.html.heex` the same way `@page_title` is (which already works, via `<.live_title>`). But `<.live_title>` is special-cased by LiveView — it has its own JS-side DOM patch mechanism (`live_title_tag`) that updates `document.title` after connect. Plain `<meta>` tags have no equivalent: LiveView's diff/patch protocol only touches `@inner_content` inside `<body>`; the `<head>` outside a `<.live_title>` tag is rendered once, from the plug pipeline's connection assigns, on the **disconnected mount**, and is never touched again by the socket. If OG tags are wired to a LiveView `assign` set inside `mount/3` or `handle_params/3`, they render correctly when Phoenix does the full HTTP disconnected render (which is what crawlers see) *only if* that assign is already resolved and available at that render — but many implementations reach for a LiveView-idiomatic pattern (fetch game in `handle_params`, `assign(:og_image, ...)`) that works fine for the connected, JS-hydrated render a real browser sees, while the crawler — which never opens a websocket — gets whatever was true at the very first HTTP response. If the OG-tag-setting code path is guarded by anything that only exists after `connected?(socket)` (a common but wrong "only do expensive work once connected" habit carried over from other LiveView code in this app), the crawler gets the *default* fallback tags, not the game-specific ones, on every single share.

**Why it happens:**
Developers pattern-match this feature against `<.live_title>`, which *does* work across connect/disconnect and navigation, and assume the same mechanism generalizes to arbitrary meta tags. It doesn't — `live_title` is one hardcoded exception in LiveView's rendering pipeline, not a general "reactive head" primitive. Phoenix LiveView's own maintainers have an open feature request (`phoenixframework/phoenix_live_view#1194`) asking for exactly this "more control over the head" capability — it does not exist as of Phoenix LiveView 1.2.x.

**How to avoid:**
- Set OG/Twitter/canonical tags from the **root layout**, driven by data assigned in `mount/3`'s connection setup or by a **plug that runs before the LiveView pipeline starts** (a `:browser` pipeline plug, or `on_mount` hook that populates `conn`/socket assigns before the first render) — not by anything gated on `connected?/1`.
- The values must be correct in the **first, disconnected HTTP render** — this is the only render a crawler (WhatsApp/Facebook/Twitter/Google) ever executes JS-free. Verify this concretely: `curl -s https://pukllay.club/juegos/<slug> | grep 'og:'` must show the real game's title/image, not the site-wide fallback — no `Selenium`/headless-browser step should be required to see correct tags.
- For per-route dynamic values (game title, cover image URL, description) on a LiveView route, the two proven patterns from the wider Elixir community are: (1) a `Plug` that inspects `conn.request_path` before the LiveView takes over and assigns tag data into `conn.assigns`, consumed by the root layout; or (2) fetching the record synchronously in `mount/3`'s non-connected branch (`if connected?(socket) do ... else preload eagerly end`) so the very first render already has the real game data — **the opposite of the "defer until connected" habit** used elsewhere for expensive work.
- This game's detail page already fetches the record in `mount/3` for the main content (LiveView Streams pattern from `ARCHITECTURE` conventions) — reuse the *same* already-fetched struct to populate OG assigns rather than adding a second lookup; don't invent a parallel data path just for meta tags.

**Warning signs:**
- `curl` (no JS, no cookies) against a live game detail URL shows the generic site-wide `og:image`/`og:title`, not the specific game's.
- Facebook's Sharing Debugger / Twitter's Card Validator show the fallback brand image on a game link.
- The OG-tag code references `@socket.assigns` values that are only set inside an `if connected?(socket) do` branch.

**Phase to address:** SEO/OG plan (this milestone) — must be verified with `curl`, not just browser DevTools, before considering this requirement done.

---

### Pitfall 2: Stale meta tags leaking between routes during LiveView client-side navigation

**What goes wrong:**
Once a visitor is inside the app and navigates via `live_patch`/`live_redirect`/`<.link navigate={}>` (client-side, no full page reload), the root layout's `<head>` — including any OG/canonical/meta-description tags — is **not re-rendered**, because LiveView's DOM patching only touches content inside the LiveView's own render tree, not the static shell it was mounted into. Concretely: a member browses the catalog, opens Game A's detail page (correct OG tags for Game A were rendered on that disconnected mount), then clicks through to Game B via client-side navigation. Game B's page content updates correctly (Streams/LiveView diffing works as expected), but if any static `<meta>` tag in `root.html.heex` was written assuming it reflects "the current route" (canonical URL, description), it now silently shows **Game A's** data while displaying Game B's content — this is real staleness a user could screenshot and report as a bug, and it also means the meta-description/canonical values become actively wrong (not just missing) after the first navigation.
This does **not** affect the OG social-share use case (Pitfall 1's concern) — José Valim's own guidance on this exact question is that canonical/OG-style meta tags don't need to update on live navigation because crawlers only ever see the disconnected initial render, never live-patched state. But it **does** matter for anything a same-session user could actually observe going stale (e.g., a page `<title>` already handled correctly by `live_title`, but also any visible "copy link" affordance, or `document.title` read by a JS integration, or `<meta name="description">` if this app ever surfaces it in-page).

**Why it happens:**
LiveView's core value proposition (SPA-like navigation without a SPA framework) means the browser's document, including `<head>`, genuinely does NOT reload between routes within a `live_session`. Treating `<head>` content as "per-request" the way it would be in a traditional MVC controller silently breaks the moment client-side nav is involved — this is a structural property of LiveView, not a bug to patch around per-tag.

**How to avoid:**
- Explicitly scope this milestone's OG/canonical work to **what crawlers see** (the disconnected render) and treat same-session staleness of invisible `<head>` tags (canonical, meta description) as **out of scope / accepted** for a LiveView app, matching the documented Phoenix core-team position — don't over-engineer a live-patchable `<head>` update mechanism that doesn't exist in the framework.
- If the existing native Web Share API control (already in place per this milestone's system description) builds its own canonical URL client-side at share time rather than reading it from a stale `<meta>` tag, confirm that share-time URL construction is unaffected by this pitfall — it likely already sidesteps it since it doesn't read the DOM's meta tags.
- Do NOT attempt a JS hook that mutates `<head>` `<meta>` tags on every `handle_event`/patch — this was tried and found ineffective/fragile in community discussion (ElixirForum thread, see Sources) and adds complexity for a benefit (same-session meta accuracy) with no real payoff, since the same-session user isn't the audience these tags serve.
- If per-route canonical tags in the *disconnected* render matter for SEO deduplication (e.g., Google indexing `/juegos/pinta-y-jala` vs `/juegos/pinta-y-jala/` are treated as duplicates), set canonical from the initial mount only, and don't attempt to keep it "live."

**Warning signs:**
- QA finds `<meta name="description">` or `<link rel="canonical">` in DevTools' Elements panel shows the *previous* game's data after clicking through several detail pages without a full reload.
- A future contributor "fixes" this with a JS hook that manually rewrites `document.head` on every `handle_event` — flag this as unnecessary scope creep unless there's a concrete crawler-facing reason (there usually isn't, since crawlers don't live-navigate).

**Phase to address:** SEO/OG plan — document this as an explicit, accepted limitation in the plan itself so a future debug session doesn't reopen it as a "bug."

---

### Pitfall 3: New inline JSON-LD `<script type="application/ld+json">` gets silently blocked by the app's own existing CSP

**What goes wrong:**
This app's CSP (`lib/pukllay_club_web/csp.ex`) currently sets `script-src 'self'` with **no `'unsafe-inline'` and no nonce mechanism** (confirmed by reading the file directly — `style-src` has `'unsafe-inline'`, but `script-src` deliberately does not, per the module's own moduledoc history of closing a Sobelow finding). Any inline `<script type="application/ld+json">{...}</script>` added directly into a `.heex` template — the standard, simplest way to embed JSON-LD — will be **silently blocked by the browser** under this policy: the browser won't execute it as script (technically JSON-LD blocks aren't "executed" as JS, but browsers still gate `<script>` elements including `type="application/ld+json"` under `script-src` per the CSP spec — Chrome/Firefox both refuse to even parse a same-origin inline `<script>` tag lacking a matching nonce/hash when `script-src` doesn't include `'unsafe-inline'`), meaning Google's Rich Results Test will report **zero structured data found** even though the markup is clearly present in view-source. This will look like a templating bug ("the JSON-LD isn't rendering") when it's actually a CSP policy interaction — an easy trap because there's no console error in some browsers for blocked non-executing script types, or the console warning is easy to miss amid other CSP noise.

**Why it happens:**
CSP's `script-src` directive governs *all* `<script>` elements regardless of their `type` attribute unless the browser's implementation explicitly special-cases `application/ld+json` (implementations vary and cannot be relied upon) — developers reasonably but incorrectly assume "it's just data, not code" exempts it from `script-src`. It doesn't, in the general case that must be assumed here.

**How to avoid:**
- **Do not weaken `script-src` to `'unsafe-inline'`** to solve this — that reopens exactly the XSS surface this app's CSP was deliberately hardened against (per `csp.ex`'s own moduledoc, this was a deliberate Sobelow-finding closure).
- Preferred fix for this app's architecture (server-rendered JSON-LD, no dynamic per-request nonce infrastructure currently in place): add a specific **hash-source** (`script-src 'self' 'sha256-<hash>'`) to `PukllayClubWeb.CSP.policy/0` for each *static* JSON-LD payload shape. This only works cleanly if the JSON-LD content is static/templated in a predictable way (e.g., the site-wide `LocalBusiness` block is identical on every page) — a fixed hash is trivial. For the per-game `Game` JSON-LD (dynamic content — title, image, rating vary per game), a hash-source is **not viable** (a different hash per game defeats the purpose of a fixed CSP header).
- For the per-game dynamic JSON-LD case, the two real options are: (a) implement the **nonce pattern** referenced in Dan Schultzer's Phoenix+LiveView CSP writeup — generate a per-request cryptographic nonce via `:crypto.strong_rand_bytes(24) |> Base.encode64(padding: false)`, add it to `script-src` for that request's response header, and stamp the same nonce onto the JSON-LD `<script nonce={@csp_nonce}>` tag — noting this requires threading the nonce through LiveView's `connect_info`/`on_mount` the same way session data is threaded, since a reconnecting LiveView socket needs the *same* nonce the disconnected render used, not a freshly generated one; or (b) serve JSON-LD as an **external same-origin script file** (e.g., `/juegos/<slug>.jsonld.js` served by a plug/controller) referenced via `<script src="...">`, since `script-src 'self'` already permits same-origin *external* script sources without needing inline-script exceptions at all — this is the simplest fix for this codebase and avoids nonce-threading complexity entirely.
- Whichever approach is chosen, verify with Google's Rich Results Test **and** a manual CSP-violation check (browser DevTools Console, `Content-Security-Policy` report — or temporarily add a `report-uri`) — don't rely on visual "it's in the HTML" inspection, since that's exactly what looks fine while being silently blocked.

**Warning signs:**
- JSON-LD is present in `view-source:` / server-rendered HTML but Google's Rich Results Test or Facebook Sharing Debugger reports no structured data detected.
- Browser console shows a `Refused to execute inline script because it violates the following Content Security Policy directive: "script-src 'self'"` warning that gets scrolled past during manual QA.

**Phase to address:** Security plan should own the CSP change (nonce infra or external-script-file decision) since it touches `csp.ex`; the SEO/OG plan should own the actual JSON-LD content/schema and must not merge until the CSP compatibility is confirmed working end-to-end (cross-plan dependency — sequence security's CSP change before or alongside the JSON-LD implementation, not after).

---

### Pitfall 4: Sitemap goes stale or includes dead/404 URLs because it's hand-authored or generated once, not derived live from the catalog

**What goes wrong:**
With ~400 games plus ongoing catalog corrections (this project's history shows multiple re-enrichment/backfill passes already — BGG re-enrichment, gallery backfill, description rewrites), any sitemap that is (a) hand-written, (b) generated once and committed as a static file, or (c) generated at compile-time and never regenerated on deploy will drift from the actual catalog within days: games get added/removed/renamed (slug changes), and a sitemap listing a slug that 404s is actively harmful — Google Search Console flags "Submitted URL not found (404)" errors, which can suppress crawl priority for the *entire* sitemap, not just the broken entries. The inverse failure — a sitemap that's stale in the other direction, i.e. doesn't include games added since the sitemap was last generated — silently under-indexes new content with no error signal at all, making it easy to miss.

**Why it happens:**
Sitemap generation is often treated as a one-time SEO checklist item ("add a sitemap.xml") rather than a data-driven feature that needs the same lifecycle awareness as any other database-backed page. A compile-time-generated sitemap (a legitimate pattern per community sources, and normally fine "because you're recompiling on every deploy anyway") becomes a trap *specifically* for this project if catalog edits (admin corrections, future Phase 4 catalog management) can happen **without** a full app redeploy — at that point the sitemap silently stops reflecting reality until the next deploy, with no warning.

**How to avoid:**
- Generate the sitemap **at request time** from the same `Ecto` query source of truth used to render the catalog (e.g., a `SitemapController` that queries all published/visible games' slugs + `updated_at`), not from a hand-maintained list or a compile-time snapshot — this project's catalog is actively edited outside of deploys often enough (seed reruns, backfills) that request-time generation is the safer default given the project's actual operational pattern, even though it costs one extra DB query per sitemap fetch (acceptable at this traffic scale, and crawlers fetch it infrequently).
- Use `updated_at` (or an explicit `published_at`) from the `games` table as `<lastmod>` — do not fabricate a `<lastmod>` value or set it to "now" on every request (that signals "always freshly changed" to Google, which can be counterproductive — it's supposed to mean "this URL's content actually changed").
- Skip `<priority>` and `<changefreq>` entirely unless there's a specific reason to differentiate — Google has publicly stated it largely ignores these fields; don't spend implementation time hand-tuning priority values across ~400 games.
- Only include URLs that are actually publicly reachable with a 200 — if the catalog has any soft-deleted/hidden/draft game concept (even informally, e.g. games missing required data), filter those out of the sitemap query explicitly, mirroring whatever visibility filter the catalog LiveView itself already applies (don't let the sitemap use a *different*, more permissive query than the actual page-rendering query — that's exactly how a listed-but-404 URL happens).
- Add the sitemap URL to `robots.txt` (`Sitemap: https://pukllay.club/sitemap.xml`) — the current `priv/static/robots.txt` is still the unmodified Phoenix default stub with no real directives and no sitemap reference; this is trivial to miss since the file already exists and "looks done."

**Warning signs:**
- Google Search Console (once submitted) shows "Submitted URL not found (404)" or "Submitted URL not selected as canonical" entries.
- Sitemap `<lastmod>` values are identical (all "now") across every URL, or never change between deploys.
- A game removed from the catalog (rare, but Phase 4 admin tooling will make this a real operation) is still listed in the sitemap weeks later.

**Phase to address:** SEO/OG plan (sitemap.xml is explicitly listed as this milestone's deliverable) — verify by cross-referencing a fresh sitemap fetch against the actual catalog's live game count/slugs, not just "the file exists and is valid XML."

---

### Pitfall 5: `put_secure_browser_headers` + an existing CSP plug create a false sense of "security hardening done," while HSTS, cookie, and CSRF gaps remain unaddressed

**What goes wrong:**
This app already calls `plug :put_secure_browser_headers` and a custom `:put_csp` plug in the router (confirmed in `lib/pukllay_club_web/router.ex`). It's easy for a hardening pass to treat this as "headers: done" and move on, missing that `put_secure_browser_headers` only sets a small, fixed set of headers (`x-frame-options`, `x-content-type-options`, `x-xss-protection` (deprecated/no-op in modern browsers), `x-download-options`, `x-permitted-cross-domain-policies`) and — critically — **does not set a CSP by default at all** (this app's own code comment in `router.ex` already notes this explicitly, since a real CSP had to be hand-built in `csp.ex` separately). Meanwhile:
- **HSTS** is controlled entirely by `force_ssl: [hsts: true]` in `config/prod.exs` — this project's current config sets `force_ssl` with an `exclude` list for `/up` and `localhost`/`127.0.0.1` but does not show `hsts: true` explicitly in the block read from `config/prod.exs` (only the comment above it references it) — if the milestone's "HSTS" checklist item is satisfied merely by force_ssl already being present from Phase 0, without confirming the `Strict-Transport-Security` response header is actually present on production responses, this is a silent gap. `force_ssl`'s HSTS defaults to `max-age=31536000` (1 year) when enabled, which is a genuinely risky value to turn on incorrectly (a browser that receives a valid HSTS header will refuse plain HTTP for a year, including for the excluded `/up` path if the exclude list is ever narrowed or the health check path changes) — the `exclude` list must stay in sync with kamal-proxy's actual health-check behavior, or a future Kamal/kamal-proxy config change could silently break deploys again the way D-05/D-06 required care around originally.
- **Cookie `secure: true`** is a `Plug.Session` option, entirely separate from `put_secure_browser_headers`/CSP — this project's `@session_options` in `endpoint.ex` currently has `store: :cookie, key: ..., signing_salt: ..., same_site: "Lax"` with **no `secure: true`** (confirmed by reading `endpoint.ex` directly) — this is exactly the gap the milestone context flags, and it is invisible to any header-based audit tool that only inspects response headers, since a missing `secure` flag is a cookie *attribute*, not an HTTP header.
- **CSRF** in this app has two independent surfaces: the traditional per-form token (`Plug.CSRFProtection`, driven by the `<meta name="csrf-token">` in root layout, already present) and LiveView's own **websocket connect-time** CSRF check (the `_csrf_token` connect param the JS client sends when opening `/live` websocket, validated against the *same* signed session). Hardening the cookie (`secure: true`, and especially any future `same_site` tightening) must be re-verified against **both** surfaces — a cookie change that breaks session/CSRF-token continuity for regular HTTP form posts will also, independently, break the websocket's connect-time CSRF validation, and the failure mode for the latter is a confusing "LiveView won't connect" / infinite reconnect loop in production rather than a clear 403, which is much harder to diagnose post-deploy.

**Why it happens:**
Phoenix's security-relevant configuration is deliberately spread across several independent mechanisms (`Plug.Session` options, `force_ssl`/HSTS, `put_secure_browser_headers`, a hand-rolled CSP plug, LiveView's own CSRF connect-param handling) precisely because each addresses a different threat — but that same separation makes it easy to fix one and assume the others are covered by the same fix, especially when several of them look similar in the router/endpoint diff.

**How to avoid:**
- Treat this milestone's security requirement as **four separate, independently-verified items**, not one "add security headers" task: (1) `secure: true` + reconfirm `same_site` on `@session_options` in `endpoint.ex`; (2) confirm `Strict-Transport-Security` header is actually present on a real production response (`curl -I https://pukllay.club/`) with a sane `max-age`, and that the `force_ssl` `exclude` list still matches kamal-proxy's actual health-check path/behavior after any hardening changes; (3) review the existing `csp.ex` directive-by-directive against current OWASP CSP guidance (this app is already close — `default-src 'self'`, no `unsafe-eval`, `frame-ancestors 'none'` — but any change here must re-run the About page's Google Maps `frame-src` test, see Pitfall 6); (4) explicitly test that a real LiveView **websocket reconnect** still succeeds after the cookie change (not just a fresh page load) — this is the surface most likely to break silently, since local dev testing rarely simulates a mid-session reconnect the way a real network blip or `secure` cookie edge case would in production over HTTPS.
- Do not treat Sobelow's clean output (or the `.sobelow-conf` allowlist) as proof of completeness for this milestone — Sobelow does static analysis of a fixed, known set of Phoenix misconfiguration patterns; it already didn't catch that `secure: true` was missing from `@session_options` (confirmed: current `.sobelow-conf`/CI presumably passes today with this gap present) — cookie flags need a runtime/response-header check (`curl -I` inspecting the `Set-Cookie` header for `Secure`), not just a static-analysis pass.

**Warning signs:**
- `curl -I https://pukllay.club/` after the change doesn't show `Strict-Transport-Security` at all, or the `Set-Cookie` header lacks `Secure`.
- LiveView pages work fine on first load in manual QA but silently fail to reconnect after simulating a network drop (Chrome DevTools → Network → Offline → Online) — this is the CSRF/cookie interaction failure mode described above.
- The About page's Google Maps embed silently stops loading after a CSP review pass (see Pitfall 6) — a sign the hardening pass touched `frame-src` without re-testing.

**Phase to address:** Security-hardening plan — should explicitly enumerate all four items above as separate verification checkpoints, not a single "harden security headers" checkbox.

---

### Pitfall 6: A CSP tightening pass accidentally removes or narrows the existing Google Maps `frame-src` allowance

**What goes wrong:**
The existing CSP (`csp.ex`) has exactly one third-party frame allowance — `frame-src #{ClubLinks.maps_embed_origin()}` — added specifically and carefully for the About page's live Google Maps embed (per the module's own moduledoc, this was a deliberate, debugged decision: `frame-ancestors` and `frame-src` are easy to confuse, and a prior debug session — `G-01.4-4` — had to establish the distinction explicitly). A security-hardening pass done by someone reviewing CSP "from scratch" against generic best-practice guidance (most generic CSP hardening checklists don't mention `frame-src` at all, since most sites don't embed third-party iframes) has a real chance of treating this app's `frame-src` as an oversight to tighten or remove, since it's the *only* non-`'self'` origin anywhere in the policy and stands out as an exception in an otherwise strict, single-origin-scoped CSP.

**Why it happens:**
Security hardening work is often done with a "tighter is always better" mental model applied uniformly, without re-deriving *why* each existing exception exists — and this exception's rationale lives in a moduledoc and a resolved debug-session file (`.planning/debug/resolved/G-01.4-4-maps-thumbnail-approach.md`), not in the CSP module's active code path, so it's easy to miss without deliberately reading history before editing.

**How to avoid:**
- Before touching `csp.ex`, read its full moduledoc (already comprehensive) and the referenced `G-01.4-4` debug file — the module's own documentation already explains this is intentional and derived from `ClubLinks.maps_embed_origin/0`, not a literal to "clean up."
- After any CSP edit, re-run (or manually re-verify) the About page's Maps embed in a real browser — this app already has an automated check for this per the codebase (`about_live_test.exs` references CSP `frame-src` derivation directly) — make sure that test still passes and is not accidentally loosened/skipped as part of the same change.
- If CSP directives are reorganized (e.g., introducing a nonce for JSON-LD per Pitfall 3), diff the *entire* policy string before/after, not just the directive being changed — a joined `Enum.join(..., "; ")`-built policy string is easy to accidentally reorder or drop a member from during a refactor.

**Warning signs:**
- The About page's Maps embed shows a blank/broken iframe in production after a security-hardening deploy, with a CSP violation in the console (`Refused to frame ... because it violates ... frame-src`).
- `about_live_test.exs`'s existing CSP-related assertions fail or get modified/removed as part of the same PR that touches `csp.ex` for unrelated hardening reasons.

**Phase to address:** Security-hardening plan — explicit regression check against the About page Maps embed should be a stated verification step, not an incidental catch.

---

### Pitfall 7: A one-time git-history secrets sweep that only greps *current* tracked files misses secrets introduced-then-removed in earlier commits

**What goes wrong:**
The most common mistake in a "secrets sweep" is running a scanner (or even `grep -r`) against the working tree / `HEAD` only — this finds secrets that are *currently* present in tracked files, but git history retains every prior version of every file, including commits where a secret was added and later removed (e.g., an early commit that hardcoded an API key before it was moved to `.kamal/secrets` or GitHub Actions secrets, or a `config/dev.secret.exs` accidentally committed once before the `.gitignore` entry was added). A secret that was ever committed, even briefly, remains fully readable by anyone with `git log -p` or `git clone` access to the full history — and this project's repo is now public (D-19), meaning that history has been publicly cloneable since the flip. This project's own STATE.md already records that D-19's public-flip decision included a check ("verified no secrets in git history or ci.yml before flipping") — but a v1.1 requirement for a fresh, dedicated sweep exists precisely because ~880 commits and multiple phases of work have landed *since* that check, and the earlier check's actual scope/rigor (a manual review vs. a tool-driven full-history scan) isn't independently documented, so it shouldn't be assumed sufficient on its own.

**Why it happens:**
`grep`-ing the working directory is the intuitive first instinct and catches the common case (a secret still present today), but git's entire value proposition — full history retention — is exactly what makes a working-tree-only check insufficient for this specific task.

**How to avoid:**
- Run a **full-history** scan, not a working-tree scan. For a solo dev doing a one-off check (not standing up ongoing CI scanning, per this milestone's explicit scope), `gitleaks detect --source . --log-opts="--all"` (or gitleaks' default full-history mode, which scans all commits by default when given a git source, not just `HEAD`) is the right weight of tool — it's a single static-binary CLI, no service to configure, and is explicitly designed for exactly this one-time audit use case.
- Consider running **both** Gitleaks and TruffleHog if time allows: Gitleaks is regex/entropy-based (fast, but will surface a higher false-positive count needing manual triage); TruffleHog additionally attempts live-credential verification against the actual service APIs (AWS, GitHub, etc.), which is valuable for triage — a TruffleHog-verified hit is unambiguously real and urgent, while an unverified Gitleaks hit needs a human to look at it. For a solo one-off sweep, Gitleaks alone is sufficient if the review is done carefully; TruffleHog is worth adding specifically to fast-triage which of Gitleaks' hits (if any) are still-live credentials requiring immediate rotation vs. already-inert.
- Scope the scan to the *entire* git history from the very first commit, including the pre-public-repo commits from before D-19's flip — those commits are just as much a part of the current public history as anything after the flip.
- **Order of operations matters**: if a real, currently-valid secret is found anywhere in history, **rotate/revoke it first**, then scrub history — scrubbing history (BFG/`git filter-repo`) does not retroactively invalidate an already-exposed credential; anyone who cloned the repo before the scrub already has it. For this project specifically: check whether any of the Phase 0/D-08 GitHub Actions repo secrets, R2 credentials, or the Gemini API key referenced in the STACK research were ever committed literally (even in an early draft `config/runtime.exs` or a debug log committed by accident) before they were moved to GitHub Actions secrets / `.kamal/secrets`.
- If a real secret is found and needs full removal, only reach for `git filter-repo` (preferred over the older BFG for a modern one-off job — it's the tool GitHub's own docs currently recommend) if history rewriting is actually necessary — for a solo-dev repo with no other clones/forks/collaborators to disrupt, a force-push after `filter-repo` is low-risk, but should still be confirmed no one else has a local clone or fork that would keep the exposed history reachable.

**Common secret-shaped false positives to expect (and how to correctly triage them):**
- `signing_salt` (e.g., this app's `@session_options`'s `signing_salt: "NLUjW6HL"` in `endpoint.ex`, committed in plaintext in tracked source) — **this is not a secret in the sense of needing rotation/revocation.** Per Phoenix's own documentation, the session's confidentiality guarantee comes from `secret_key_base` (which Phoenix generates via `mix phx.gen.secret` and which **should** live outside the repo, typically in runtime env/`.kamal/secrets`), not from `signing_salt`, which is a non-secret input used to *derive* per-purpose keys from `secret_key_base` — Phoenix's generator itself commits a `signing_salt` value into `endpoint.ex` by default and this is expected/documented behavior. A scanner may flag its high-entropy-looking string; the correct triage is "not a finding," not "rotate this."
- `secret_key_base` itself, if found: **this genuinely is a secret** and must never be committed — if a scan finds a literal `secret_key_base` value in any historical commit (e.g., an early `config/prod.secret.exs` before `phx.gen.release`'s runtime-env pattern was adopted), treat it as a real, urgent finding requiring both history scrubbing and rotation (regenerate via `mix phx.gen.secret` and redeploy with the new value in `.kamal/secrets`).
- Public, non-sensitive identifiers that pattern-match secret-shaped regexes: this app's public R2 image host / bucket base URL (already explicitly documented in `csp.ex`'s moduledoc as intentionally public — "This is a public [origin], never hardcode..." for the *value*, not because it's sensitive), the app's own domain/hostnames, and Google Maps embed origin (`ClubLinks.maps_embed_origin/0`) are all meant to be public and will not be genuine findings even if a scanner's heuristics flag a long alphanumeric string near words like "key" or "token" in a comment.
- Test/fixture data: any BGG API interaction test fixtures or seed-script sample data that includes an-looking API key string for test purposes should be checked for whether it's a real historical key (rotate if so) vs. an intentionally fake placeholder (no action, but consider adding a scanner allowlist comment/`.gitleaksignore` entry so future ad-hoc scans don't re-flag it, even though this milestone isn't setting up ongoing CI scanning).

**Warning signs:**
- A scan run only against `HEAD`/working tree comes back "clean," creating false confidence — always confirm the scan tool's invocation actually walked full history (`--log-opts="--all"` for gitleaks, or explicit confirmation the tool defaults to all-commits mode) before trusting a clean result.
- A large number of raw hits with no triage — don't let "gitleaks found 40 things" become "we'll deal with it later"; each hit needs an explicit real/false-positive/inert-and-safe classification recorded somewhere (even a throwaway triage note) so the sweep has a defensible, closed conclusion.

**Phase to address:** Secrets-sweep task (standalone, one-time — not the SEO or security plan) — should produce an explicit triage list (real/rotated, false-positive/documented, inert-historical/accepted) as its concrete deliverable, not just "ran gitleaks, looked fine."

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|--------------------|-----------------|------------------|
| Compile-time-generated sitemap.xml committed as a static file | Zero runtime cost, no controller/query to write | Silently stale the moment catalog data changes without a full redeploy (Pitfall 4) | Never for this project — catalog edits (seed reruns, future admin tooling) can happen independently of deploys |
| Weakening `script-src` to `'unsafe-inline'` to unblock JSON-LD quickly | Fastest fix, no nonce/hash infra needed | Reopens the exact XSS surface the CSP was hardened to close; a real regression, not just risk | Never — use hash-source (static JSON-LD) or same-origin external script file instead |
| Skipping a full-history secrets scan and only grepping tracked files | Faster, simpler to run | False confidence; a historically-committed-then-removed secret remains fully exposed in a now-public repo | Never for this specific one-time sweep — the whole point is history, not working tree |
| Treating Sobelow's clean CI output as proof security hardening is complete | No extra manual verification step | Misses runtime-only gaps Sobelow's static analysis can't see (missing `secure: true` cookie flag, actual `Strict-Transport-Security` header presence) | Never as the sole check — always pair with a `curl -I` runtime check for this milestone's specific items |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|--------------|------------------|-------------------|
| Facebook/Twitter/WhatsApp link-preview crawlers | Assuming they behave like a real browser (execute JS, open the LiveView socket) | Verify tags with `curl` / Facebook Sharing Debugger / Twitter Card Validator against the raw disconnected HTML — these crawlers are JS-free HTTP clients |
| Google Search Console / Rich Results Test | Trusting "it's in the HTML source" as proof structured data works | Explicitly re-test after any CSP change — CSP can silently block inline JSON-LD even when server-rendered HTML looks correct (Pitfall 3) |
| kamal-proxy health check (`/up`) vs. `force_ssl`'s `exclude` list | Narrowing or restructuring the `exclude` list during a security pass without re-verifying kamal-proxy's actual health-check request shape | Re-deploy to a staging-like check (or carefully review D-05/D-06's original reasoning) any time `force_ssl`'s `exclude` config changes — a broken health check silently blocks all future deploys, not just a security regression |
| LiveView websocket connect vs. session cookie changes | Testing only fresh page loads after a cookie/CSRF-adjacent change, not a live reconnect | Explicitly simulate a network drop/reconnect (DevTools → Offline → Online) after any `Plug.Session` option change and confirm the LiveView socket re-establishes without a CSRF/session error |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Assuming `put_secure_browser_headers` sets a CSP | No CSP at all in a codebase that believes headers are "handled" | Confirm (as this app already does) that CSP is a separate, explicit plug — verify its actual header value with `curl -I`, not just that the plug is called |
| Overly broad `force_ssl` `hsts: true` with no `exclude` re-verification during hardening | A future kamal-proxy config change plus a strict HSTS `max-age` could make the health check or a misconfigured host permanently unreachable over plain HTTP for up to a year in browsers that cached the HSTS policy | Re-verify the `exclude` list against kamal-proxy's actual health-check behavior every time `force_ssl` config is touched, not just at initial Phase 0 setup |
| Rotating a leaked secret without also scrubbing git history (or vice versa) | Either the secret stays live and exploitable (scrub-without-rotate) or it stays permanently visible to anyone with a prior clone (rotate-without-scrub, giving false closure) | Always do both, in the order: rotate/revoke first, then scrub history |
| Flagging `signing_salt` as a secret needing rotation | Wasted effort; churns a value that Phoenix's own generator intentionally commits in plaintext | Confirm which specific value class (`secret_key_base` vs. `signing_salt`) a scanner hit actually is before acting on it |

## "Looks Done But Isn't" Checklist

- [ ] **OG tags "work"**: Often verified only via browser DevTools (which shows the connected/JS-hydrated DOM) instead of `curl`/view-source — verify against the raw disconnected HTML a crawler actually receives.
- [ ] **JSON-LD "is present"**: Often verified by "I can see it in the template/HTML source" — verify with Google's Rich Results Test AND a CSP-violation console check, since CSP can block it silently while still being visible in source.
- [ ] **`robots.txt` "exists"**: The file already exists in this repo, but is still the unmodified Phoenix default stub with commented-out placeholder directives and no `Sitemap:` reference — existing-but-unconfigured, not done.
- [ ] **Security headers "added"**: `put_secure_browser_headers` + a CSP plug being present is often mistaken for complete hardening — separately verify cookie `Secure` flag, actual `Strict-Transport-Security` response header, and a live-reconnect CSRF test, none of which a header-presence check alone confirms.
- [ ] **Secrets sweep "done"**: A clean `grep`/scan of the current working tree is often mistaken for a complete sweep — confirm the tool actually walked full git history (`--all`/equivalent flag), not just `HEAD`.
- [ ] **Sitemap "generated"**: A sitemap that renders once and validates as XML is often mistaken for finished — confirm its URL list and `<lastmod>` values actually track the live `games` table query, not a snapshot.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|-----------------|-----------------|
| OG tags only correct on connected render, wrong on crawler-visible disconnected render | LOW | Move the tag-populating logic out of any `connected?(socket)`-gated branch into the initial synchronous mount path or a pre-LiveView plug; re-verify with `curl` |
| JSON-LD blocked by CSP | LOW–MEDIUM | Either add a hash-source for static JSON-LD, or switch dynamic per-game JSON-LD to a same-origin external script file (avoids nonce infra); re-run Rich Results Test |
| CSP tightening broke the Maps `frame-src` | LOW | Revert the specific `frame-src` line to `ClubLinks.maps_embed_origin()`-derived value; re-run `about_live_test.exs` |
| Historical secret found in git history (still live) | MEDIUM–HIGH | Rotate/revoke immediately at the provider first (this stops the bleeding regardless of repo state), then decide separately whether a full `git filter-repo` history rewrite + force-push is worth doing given the repo has been public since D-19 (some exposure window already existed) |
| Missing `secure: true` cookie flag shipped to production | LOW | Add the flag, redeploy — no data migration needed since this only affects future `Set-Cookie` responses, not existing session validity beyond requiring users to reauthenticate/reconnect once |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|--------------------|----------------|
| OG tags never reach crawler-visible disconnected HTML | SEO/OG plan | `curl` a live game detail URL and grep for `og:` tags showing real game data, not fallback |
| Stale meta tags across LiveView client-side navigation | SEO/OG plan | Explicit written note in the plan accepting this as out-of-scope for invisible `<head>` tags, consistent with José Valim's documented guidance |
| JSON-LD blocked by existing CSP `script-src 'self'` | Security plan (CSP change) + SEO/OG plan (content), sequenced together | Google Rich Results Test + browser console CSP-violation check |
| Sitemap staleness / 404s | SEO/OG plan | Cross-check generated sitemap's URL count/slugs against live `games` table count at time of verification |
| False sense of security-headers completeness (cookie/HSTS/CSRF gaps) | Security plan | `curl -I` production response for `Strict-Transport-Security` and `Set-Cookie: ...Secure`; live LiveView reconnect test after network drop simulation |
| CSP tightening breaks Maps `frame-src` | Security plan | Manual About-page Maps embed check + existing `about_live_test.exs` CSP assertions still passing |
| Secrets sweep misses history-only exposures | Secrets-sweep task | Confirm scan tool invocation explicitly covers full git history (not just `HEAD`); produce an explicit triage list of every hit |

## Sources

- `phoenixframework/phoenix_live_view` GitHub issue #1194, "Feature request: More control over the head of the document" — HIGH confidence (primary/official issue tracker, confirms no general reactive-head primitive exists as of Phoenix LiveView 1.2.x)
- ElixirForum, "Updating metatags in Phoenix LiveView (rel canonical etc)" — includes a direct reply from José Valim (Elixir's creator) stating canonical/OG tags don't need live-patch updates since crawlers don't execute client-side navigation — HIGH confidence (primary-source framework-creator statement)
- mariovega.dev, "Building Dynamic OpenGraph Tags with Phoenix LiveView" — MEDIUM confidence (single blog implementation walkthrough, but consistent with the GitHub issue and forum thread)
- Dan Schultzer, "Content Security Policy header with Phoenix LiveView" (danschultzer.com) — MEDIUM confidence (single blog source, but the nonce-threading-through-`connect_info` mechanism described is architecturally consistent with how this app already threads session data through the LiveView socket)
- FullstackPhoenix, "Phoenix LiveView and Invalid CSRF token" — MEDIUM confidence (single tutorial source, corroborated by the general community-known "LiveView mounts twice" CSRF behavior referenced across multiple GitHub issues)
- OWASP Content Security Policy Cheat Sheet; MDN CSP / `script-src` docs — HIGH confidence (canonical, authoritative web-standards references) for the nonce-vs-`unsafe-inline` mutual-exclusivity fact and general CSP hardening guidance
- DEV Community / AppSecSanta / Secrails, various 2026 "Gitleaks vs TruffleHog" comparison posts — MEDIUM confidence (cross-checked across 3+ independent comparison write-ups converging on the same tool-selection guidance: Gitleaks for fast regex/entropy scans, TruffleHog for live-credential verification)
- Warp/Simon Willison/Harness/CoreUI, various "remove secrets from git history" guides — MEDIUM confidence (cross-checked across 4 independent sources converging on the same BFG-vs-`git filter-repo` guidance and the "rotate first, scrub second" ordering)
- This project's own source, read directly: `lib/pukllay_club_web/csp.ex`, `lib/pukllay_club_web/endpoint.ex`, `lib/pukllay_club_web/router.ex`, `config/prod.exs`, `priv/static/robots.txt`, `.planning/STATE.md` (D-19 entry) — HIGH confidence (primary source, the actual current-state code this milestone modifies)

---
*Pitfalls research for: SEO/social-sharing/security-hardening on an existing production Phoenix LiveView app*
*Researched: 2026-09-11*
