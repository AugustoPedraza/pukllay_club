# Stack Research

**Domain:** SEO metadata, Open Graph/Twitter Card social-sharing, JSON-LD structured data, sitemap.xml, and security hardening — additive to an existing Elixir/Phoenix 1.8 LiveView app
**Researched:** 2026-09-11
**Confidence:** HIGH (Phoenix/Plug core behavior, verified against `hexdocs.pm` + the app's own `endpoint.ex`/`router.ex`/`csp.ex`/`config/prod.exs`) / MEDIUM (third-party package evaluation, verified against each package's own hexdocs but not hands-on)

## Headline Recommendation

**Zero new runtime dependencies are required for this milestone.** Every one of the four feature
areas (meta/OG/Twitter tags, JSON-LD, sitemap.xml, cookie/HSTS hardening) is fully covered by
Phoenix/Plug primitives already vendored into this app (`mix.exs` already has `phoenix`, `jason`,
`plug`, `sobelow`). The only changes needed are: two new HEEx function components, one new
lightweight controller/route, one config line (`secure: true`), and content edits to two static
files (`robots.txt`, and a new `sitemap.xml`-serving route). This matches the project's own stated
principle of avoiding unnecessary abstraction for a solo-dev, near-zero-ops app — see "What NOT to
Use" below for the two packages that were evaluated and explicitly rejected for this scale.

## Recommended Stack

### Core Technologies (no version changes — already pinned)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Phoenix (existing) | 1.8.9 | LiveView `assign`s drive per-page `<title>` (`<.live_title>`) today; the same mechanism extends to meta/OG tags | All three browser routes (`CatalogLive.Index`, `CatalogLive.Show`, `AboutLive`) are LiveViews, not controller-rendered — there is no `conn.assigns` path to worry about, only socket assigns flowing into one shared `root.html.heex`. This simplifies the integration to a single pattern, not two. |
| Plug (existing, transitive via Phoenix) | current via Phoenix 1.8.9 | `Plug.SSL` (HSTS), `Plug.Session` (`secure`/`same_site` cookie flags), `Plug.Static` (serves `robots.txt`/future static assets verbatim) | Already doing 90% of the hardening work — `force_ssl` is already configured in `config/prod.exs` and `put_secure_browser_headers`/`put_csp` are already wired in the `:browser` pipeline. The gaps are one missing key (`secure: true`) and verification, not new plugs. |
| Jason (existing) | `~> 1.4` (resolves 1.4.4/1.4.5) | Encodes JSON-LD `@context`/`@type` maps for `schema.org` `Game`/`LocalBusiness` | Already a direct dependency (`mix.exs:90`) and Phoenix's default JSON library — no reason to add a schema.org-specific encoding library on top of a general JSON encoder for two static-shaped maps. |

### Feature-by-feature approach

| Feature | Approach | Why |
|---------|----------|-----|
| Per-page meta description, OG tags, Twitter Card tags | **Hand-rolled**: a `PukllayClubWeb.SEO` HEEx function component rendered once in `root.html.heex`, reading a socket assign (e.g. `@meta`) that each LiveView sets in `mount/3`/`handle_params/3`; falls back to site-wide defaults (brand isologo/wordmark, generic description) when a LiveView doesn't set it | Phoenix LiveView has **no built-in primitive** for per-page `<head>` metadata beyond `<.live_title>` — this is a long-standing, still-open framework gap (`phoenixframework/phoenix_live_view#1194`). The community-standard workaround *is* exactly this pattern: assign a map/struct per-LiveView, render conditionally in the root layout. With only 3 routes (1 needing truly dynamic per-item data — `CatalogLive.Show`), a ~30-line function component is simpler than adopting a package built around N routes and multiple content types. |
| JSON-LD (`Game` on detail pages, `LocalBusiness`/Jujuy site-wide) | **Hand-rolled**: a second small HEEx component that takes a plain map and renders `<script type="application/ld+json">{Phoenix.HTML.raw(Jason.encode!(data))}</script>` | schema.org JSON-LD is just a JSON object with `@context`/`@type` keys — there is no meaningful abstraction a library adds over "build a map, `Jason.encode!/1` it." Two gotchas to bake into the component itself (see Version Compatibility below): (1) HEEx auto-escapes by default, so the encoded JSON must go through `Phoenix.HTML.raw/1` or the quotes/braces get HTML-entity-mangled; (2) escape literal `</` sequences in the encoded output (e.g. `String.replace(json, "</", "<\\/")`) as defense-in-depth against a game title/description ever containing `</script>` and prematurely closing the tag — a known JSON-in-`<script>` gotcha, not Phoenix-specific. |
| `robots.txt` | **Already fully wired — content edit only, zero code** | `PukllayClubWeb.static_paths/0` (`lib/pukllay_club_web.ex:20`) already includes `robots.txt` in the list `Plug.Static` serves from `priv/static/`, and `priv/static/robots.txt` already exists (currently the `phx.new` placeholder). Just replace its contents with real `User-agent: *` / `Allow: /` / `Sitemap: https://pukllay.club/sitemap.xml` directives. No router change, no new plug. |
| `sitemap.xml` | **Hand-rolled**: one new plain (non-LiveView) controller action + router route, querying game ids/slugs and rendering XML directly (`put_resp_content_type("application/xml")` + `send_resp/3`), not a static file | The catalog is ~400 rows behind a single indexed query — cheap enough to render per-request with an HTTP `cache-control` header (e.g. `max-age: 3600`) rather than committing a static file that goes stale every time a game is added/removed, or wiring a background-job regeneration pipeline that doesn't exist yet (Oban is a *Phase 2* addition per the project roadmap — pulling it forward just for sitemap regeneration would be scope creep). Route it through its own pipeline (`plug :accepts, ["xml"]`), the same pattern already used for `/up`'s `:health` pipeline in `router.ex`. |
| Secure session cookie (`secure: true`) | **One config-line change** to `@session_options` in `endpoint.ex`, gated to compile-time `Mix.env() == :prod` | The `Secure` cookie attribute requires HTTPS to transmit the cookie at all. Firefox and (partially) Chrome exempt `http://localhost` from this requirement for local dev convenience, but **Safari does not** — testing this app locally in Safari with an unconditional `secure: true` would silently drop the session cookie (breaking flash messages / LiveView reconnect state in dev). The existing `endpoint.ex` already has a precedent for exactly this compile-time-env-gated pattern (`if Mix.env() == :dev do plug Tidewave end`, line 30) — mirror it: `secure: true` only when `Mix.env() == :prod`. This is compile-time, not `config/runtime.exs`, because `Plug.Session`'s options are captured once at compile time via the `plug` macro (same reason the existing `force_ssl` comment notes "required to be set at compile-time"). |
| HSTS (`Strict-Transport-Security` header) | **Verify only — likely already emitted, no code change** | `Plug.SSL.init/1` defaults `:hsts` to `true` with `expires: 31_536_000` (1 year) whenever `force_ssl` is configured at all — which `config/prod.exs` already does (`rewrite_on: [:x_forwarded_proto]`, plus the `/up`/`localhost` excludes). Because nothing in the current config explicitly sets `hsts: false`, the header should already be going out on every HTTPS response except the excluded `/up` health-check path. **Action item is verification, not implementation**: `curl -sI https://pukllay.club/ | grep -i strict-transport-security` against production. `:subdomains` and `:preload` both default to `false` — leave them off unless the site adds a `www.` subdomain or the team decides to submit to hstspreload.org (submitting requires `includeSubDomains` + `preload` + a 1-year+ max-age, and is a one-way ratchet — don't do it casually on a domain with any subdomain plans). |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Sobelow (existing, `~> 0.14` in `mix.exs`, resolves 0.14.1) | Already gates `mix quality`; its `Config.*` checks are exactly the family that flags a missing `secure: true` on session cookies and missing/weak HTTPS config | Current stable on hex.pm is **0.15.0** (the pinned `~> 0.14` constraint does *not* auto-resolve to it, since `~>` treats the second-to-last segment as the floor for `0.x` versions). Optional, low-priority: bump to `~> 0.15` to pick up any newer checks before running the security-hardening pass — not required for this milestone to succeed, but worth doing opportunistically since Sobelow is precisely the tool auditing this milestone's own deliverable. |
| `curl -I` / browser DevTools Network tab | Manual verification of `Strict-Transport-Security`, `Set-Cookie: ...Secure`, and CSP headers against the live production origin | No package needed — this is the standard way to confirm headers actually reached the wire, since `force_ssl`/`Plug.Session` config correctness and "the header is actually present in the deployed response" are two different claims. |
| Google Rich Results Test / schema.org validator (web tools, not hex packages) | Validate the hand-written `Game`/`LocalBusiness` JSON-LD parses as valid structured data | External, free, no integration — just paste a rendered page's JSON-LD blob in. Do this once per structured-data type added, not per game. |
| Mozilla Observatory / securityheaders.com (web tools) | Independent second opinion on the full header set (CSP, HSTS, `X-Content-Type-Options`, etc.) once cookie/HSTS changes ship | Complements Sobelow (which is static analysis of the *code*) with a live check of what the *deployed* endpoint actually sends — same rationale as the `curl` verification step above. |

## Installation

No `mix.exs` changes required for the four feature areas themselves. Optional Sobelow version bump:

```elixir
# mix.exs — optional, not required
{:sobelow, "~> 0.15", only: [:dev, :test], runtime: false}
```

```bash
mix deps.update sobelow
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|--------------------------|
| Hand-rolled HEEx component + LiveView socket assigns for meta/OG/Twitter/JSON-LD | [`phoenix_seo`](https://hex.pm/packages/phoenix_seo) (dbernheisel), current v0.3.1 — a protocol-based framework with `use SEO`, per-domain config modules (Open Graph/Twitter/Facebook/Site/JSON-LD), a compile-time JSON-LD builder registration step, and a `<SEO.juice>` root-layout component | If the site grows to many distinct content types each needing structured metadata (e.g. blog posts, events, multiple locales) *and* the team wants compile-time protocol dispatch instead of hand-checking assigns. At 3 routes (1 truly dynamic), the package's config-module/protocol-implementation ceremony costs more than it saves; it's a legitimate, actively-maintained package (last updated within this research's lookback window) worth revisiting if this milestone's scope expands significantly in Phase 4 (admin/catalog CMS-like features). |
| Hand-rolled controller route rendering `sitemap.xml` per-request from a single Ecto query | [`sitemapper`](https://hex.pm/packages/sitemapper) (breakroom), current v0.10.0 — stream-based generator supporting file/S3 persistence, image-sitemap extension, multi-file sitemap indexes | If the catalog grows past the low thousands of URLs, gains additional URL-bearing content types (e.g. per-designer or per-mechanic pages), or the team already has Oban wired up (Phase 2+) to run scheduled regeneration jobs. `sitemapper`'s design center is million-URL sites regenerated on a schedule and persisted to disk/S3 — none of which this milestone's ~400-game catalog needs; a live per-request query is simpler and always fresh. |
| Compile-time `Mix.env() == :prod` guard on `secure: true` in `@session_options` | Environment-variable-driven runtime toggle (e.g. reading `PHX_SERVER`/a custom env var in `config/runtime.exs`) | Only if the team ever needs to run a "staging" environment that serves over HTTPS but isn't the `:prod` Mix env — not the case here (single production host, single Mix env per the project's constraints). The compile-time guard is simpler and matches the codebase's own existing convention. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| `phoenix_seo` or any similarly-scoped SEO framework, for this milestone | Adds a protocol-implementation and compile-time-config-module layer to solve a problem (3 routes, 1 dynamic) that a single ~30-line function component solves just as correctly, with less to learn/maintain for a solo dev | Hand-rolled `PukllayClubWeb.SEO` (or similarly named) function component(s), assigned per-LiveView |
| `sitemapper` or any stream/S3-persistence sitemap generator, for this milestone | Built for scale (millions of URLs, scheduled background regeneration) this app doesn't have yet; would also implicitly pull forward a "when does this regenerate" scheduling question that only has a good answer once Oban exists (Phase 2) | A dynamic controller/plug route rendering XML directly from a single Ecto query, cached via HTTP headers |
| Committing a static, hand-generated `sitemap.xml` file into `priv/static/` | Goes stale the moment a game is added, removed, or its `updated_at` changes — silently wrong sitemap is worse than no sitemap for crawl-budget purposes | The dynamic route above — same infra cost, always correct |
| Unconditional `secure: true` on `@session_options` (no env gate) | Silently drops the session cookie in Safari during local dev (Safari does not exempt `localhost` from the Secure-cookie-requires-HTTPS rule, unlike Firefox/Chrome) | Compile-time `Mix.env() == :prod` gate, mirroring the existing `Mix.env() == :dev` Tidewave pattern already in `endpoint.ex` |
| Manually constructing/duplicating the `Strict-Transport-Security` header via a custom plug | `Plug.SSL` (already active through `force_ssl` in `config/prod.exs`) already emits it correctly by default — a hand-rolled second header risks either duplicating it or silently disagreeing with `Plug.SSL`'s own max-age/subdomains/preload values | Verify the existing header via `curl`; only pass explicit `hsts: [...]` sub-options to `force_ssl` if the defaults (1 year, no subdomains, no preload) are deliberately being changed |
| Escaping/omitting `type="application/ld+json"` script tags from the CSP `script-src` allowlist review, or worse, adding `'unsafe-inline'` to `script-src` to "make JSON-LD work" | Unnecessary and actively weakens the existing CSP: `<script>` elements whose `type` is not a JS MIME type (blank, `module`, `importmap`, or a JS type) are excluded from `script-src` enforcement entirely per the CSP spec — `application/ld+json` already renders fine under the current `script-src 'self'` policy with zero CSP changes | Leave `csp.ex`'s `script-src 'self'` exactly as-is; the JSON-LD `<script type="application/ld+json">` tags need no CSP accommodation |

## Stack Patterns by Variant

**If the catalog's public URL surface grows well beyond games** (e.g. per-designer pages, per-mechanic pages, a blog/news section is added in a later milestone):
- Revisit `sitemapper` once there's a real multi-content-type, multi-thousand-URL sitemap to assemble and Oban (Phase 2+) exists to schedule its regeneration
- Because Oban is already the project's fixed async-job mechanism from Phase 2 onward, `sitemapper`'s typical "generate + persist" usage would slot in as a periodic Oban job rather than needing any new scheduling infrastructure

**If the site adds locales beyond Rioplatense Spanish, or many more structured-data types** (events, reviews, FAQ pages):
- Revisit `phoenix_seo` — its per-domain config-module/protocol design starts paying for itself once there are more than a couple of content shapes needing metadata, especially across locales
- Until then, the hand-rolled component keeps the mental model at "one map in, one `<meta>`/`<script>` block out"

**If Phase 2's magic-link auth (`phx.gen.auth`) lands and introduces its own "remember me" cookie:**
- Apply the same `secure: true` (compile-time-prod-gated) treatment to that cookie's options — `phx.gen.auth`'s generated `UserAuth` module has its own `@remember_me_cookie` options list, separate from `@session_options` in `endpoint.ex`; don't assume fixing one fixes both

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|------------------|-------|
| `Plug.SSL.init/1` defaults | `force_ssl: [rewrite_on: [:x_forwarded_proto], exclude: [...]]` (already in `config/prod.exs`) | `:hsts` defaults to `true`, `:expires` to `31_536_000` (1 year), `:subdomains` and `:preload` both default to `false` — the app's current config already emits HSTS with these defaults; nothing further is required unless the defaults are deliberately being overridden |
| `Plug.Session` cookie options | `:secure`, `:http_only`, `:same_site`, `:domain`, `:max_age` all forward to `Plug.Conn.put_resp_cookie/4` | `:http_only` already defaults to `true` at the `Plug.Conn` layer (not something this app needs to set explicitly); `:secure` defaults to `false` and must be set explicitly — this is the one gap in the current `@session_options` |
| Session cookie `:secure` flag | Safari **does not** treat `http://localhost` as a secure context for cookie purposes; Firefox and Chrome (partial) do | Load-bearing fact for the `Mix.env() == :prod` compile-time gate recommended above — without the gate, local Safari testing silently loses session state |
| CSP `script-src` directive | `<script type="application/ld+json">` elements | Per the CSP spec, `script-src` enforcement only applies to `<script>` elements whose `type` is empty, a JS MIME type, `module`, or `importmap` — `application/ld+json` is none of these, so it is exempt by spec, not by any explicit allowlisting. No change needed to `PukllayClubWeb.CSP.policy/0`. |
| HEEx auto-escaping | `Jason.encode!/1` output embedded in a `<script>` tag | HEEx escapes interpolated content by default; embedding pre-encoded JSON requires `Phoenix.HTML.raw/1` (or the `raw/1` import) around the `Jason.encode!/1` result, or the JSON's quotes/braces get corrupted into HTML entities |
| Sobelow `~> 0.14` (pinned) | Current stable `0.15.0` | `~>` treats the second segment as the ceiling for `0.x` releases (`~> 0.14` allows `>= 0.14.0, < 0.15.0`), so the existing constraint will **not** auto-pick-up 0.15.0 — a manual `mix.exs` bump is needed if the newer version's checks are wanted for this security-hardening milestone |

## Sources

- `hexdocs.pm/phoenix/using_ssl.html` (via WebSearch) — `force_ssl`/`Plug.SSL` compile-time requirement, HSTS behavior — MEDIUM confidence (search summary, cross-checked against Plug's own docs below)
- `plug.hexdocs.pm/Plug.SSL.html` (via WebFetch) — `:hsts`, `:expires`, `:subdomains`, `:preload`, `:rewrite_on`, `:exclude` defaults — HIGH confidence (direct fetch of the authoritative module doc)
- `plug.hexdocs.pm/Plug.Session.html` (via WebFetch) — `:secure`/`:http_only`/`:same_site` option list, deference to `Plug.Conn.put_resp_cookie/4` — MEDIUM confidence (doc page didn't spell out every default explicitly; cross-checked against known Plug.Conn cookie defaults)
- This app's own `lib/pukllay_club_web/endpoint.ex`, `lib/pukllay_club_web/router.ex`, `lib/pukllay_club_web/csp.ex`, `lib/pukllay_club_web.ex`, `config/prod.exs`, `mix.exs` (direct file reads) — current `@session_options`, `force_ssl` config, CSP policy, `static_paths/0` already including `robots.txt`, existing `Mix.env() == :dev` compile-time-gate precedent, Sobelow/Jason version pins — HIGH confidence (primary source, the actual code)
- `phoenix-seo.hexdocs.pm/SEO.html` (via WebFetch) — `phoenix_seo` v0.3.1 install/config shape, LiveView `SEO.assign/2` pattern, `<SEO.juice>` root-layout integration — MEDIUM confidence (single-source doc fetch, cross-checked against its GitHub README summary from search)
- `sitemapper.hexdocs.pm/readme.html` (via WebFetch) — `sitemapper` v0.10.0 storage backends (`FileStore`/`S3Store`), stream-based design, serving via `Plug.Static` vs controller — MEDIUM confidence
- `github.com/phoenixframework/phoenix_live_view` issue #1194 (via WebSearch) — confirms no built-in LiveView primitive for per-page `<head>` meta beyond `<.live_title>`, as of this research — MEDIUM confidence (issue referenced via search summary, consistent with known LiveView architecture — root layout renders once, LiveView content is patched, not the `<head>`)
- `mathiasbynens.be/notes/json-dom-csp` (referenced via WebSearch summary) — the `</script>`-in-JSON escaping gotcha for `<script type="application/json">`/`application/ld+json"` blocks — MEDIUM confidence
- CSP spec behavior for non-JS `<script>` `type` attributes being exempt from `script-src` (via WebSearch, cross-referencing MDN's `script-src` page summary) — MEDIUM confidence
- `hex.pm/api/packages/{sobelow,phoenix_seo,sitemapper,jason}` (via direct `curl`) — exact current version numbers — HIGH confidence (direct registry API)
- Mozilla/Chromium bug trackers (`bugzilla.mozilla.org` #1618113, #1648993) referenced via WebSearch summary — Firefox/Chrome `localhost`-as-secure-context exemption for the `Secure` cookie attribute, Safari's stricter behavior — MEDIUM confidence (cross-checked across two independent bug reports plus a summarizing article)

---
*Stack research for: SEO/social-sharing/security-hardening additions to PukllayClub v1.1*
*Researched: 2026-09-11*
