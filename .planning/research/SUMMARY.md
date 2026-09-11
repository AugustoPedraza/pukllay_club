# Project Research Summary

**Project:** PukllayClub
**Domain:** SEO / social-sharing / security-hardening addition to an existing Elixir/Phoenix 1.8
LiveView board-game catalog app
**Researched:** 2026-09-11
**Confidence:** HIGH

## Executive Summary

The v1.1 "Sharable Version" milestone adds SEO metadata, Open Graph/Twitter Card social-sharing
tags, JSON-LD structured data, and security hardening to an existing Phoenix 1.8 LiveView app —
with **zero new runtime dependencies**. Every feature area (meta/OG/Twitter tags, JSON-LD,
sitemap.xml, cookie/HSTS hardening) is covered by Phoenix/Plug primitives already vendored in this
codebase; the two third-party packages evaluated (`phoenix_seo`, `sitemapper`) were both rejected
as over-built for a ~400-game catalog with no scheduled-job infrastructure (Oban) wired until
Phase 2.

The one genuinely non-obvious architectural fact this research surfaced: **`root.html.heex`
renders from `conn.assigns`, not `socket.assigns`.** `<.live_title>` is a special-cased exception
in LiveView's own rendering pipeline, not a general pattern — assigning `:meta_tags` inside a
LiveView's `mount/3`/`handle_params/3` would silently do nothing for crawlers, because link
crawlers (Facebook, Twitter, WhatsApp, Google) only ever fetch the first disconnected HTTP
response and never open a websocket. OG/meta content for `/juegos/:id` must be computed in a new
Plug that runs before the LiveView mounts and writes to `conn.assigns`, mirroring how
`get_csrf_token()` already reaches the root layout today.

The second real risk: this app's CSP (`csp.ex`) already runs `script-src 'self'` with no
`unsafe-inline` and no nonce mechanism — a deliberate prior Sobelow fix. A naively-added inline
`<script type="application/ld+json">` JSON-LD block will be silently blocked by the browser. The
fix is a CSP nonce refactor (`policy/0` → `policy/1`, nonce generated per-request in `put_csp/2`)
for the per-game `Game` JSON-LD, or a same-origin external script file as a simpler alternative;
the static site-wide `LocalBusiness` block can use a hash-source instead since its content never
changes. Social sharing also needs one new asset-pipeline step: existing game cover images are
letterboxed/near-square (from Phase 01.3.1's `ImagePipeline`), not the 1200×630 aspect ratio
Facebook/Twitter/WhatsApp expect for link-preview cards.

## Key Findings

### Recommended Stack

No new hex dependencies. Per-page meta/OG/Twitter tags: hand-rolled HEEx function components fed
by `conn.assigns` (not LiveView socket assigns — see Architecture Approach below), since all 3
browser routes in this app are LiveViews with no controller/`conn`-based alternative path.
`robots.txt` is already fully wired (`static_paths/0` includes it, file already exists on disk) —
this is a content edit, not new code. `sitemap.xml` should be a small dynamic controller action
(query + render XML) rather than the `sitemapper` hex package, which targets a scale/scheduled-
regeneration use case this ~400-row catalog doesn't need. HSTS is very likely *already* being
emitted in production: `Plug.SSL` defaults `hsts: true` (1yr max-age) whenever `force_ssl` is set,
which `config/prod.exs` already does — this milestone's HSTS work is verification (`curl -I`
against the live site), not new implementation.

**Core technologies:**
- Hand-rolled HEEx `SEOTags` function component — per-page meta/OG/Twitter tags — no LiveView
  head-metadata primitive exists beyond `<.live_title>`, confirmed against `phoenix_live_view`
  GitHub issue #1194 (an open feature request for exactly this capability)
- A new `PukllayClubWeb.Plugs.GameSEO` plug + `PukllayClubWeb.SitemapController` — both plain
  Plug/Phoenix controller primitives, no new deps
- `Plug.SSL`'s existing `force_ssl`/HSTS default and `Plug.Session`'s `secure:` cookie option —
  both already vendored via `plug`/`phoenix`

### Expected Features

**Must have (table stakes) — this milestone's core scope:**
- Meta description, real `alt` text, `robots.txt` + `sitemap.xml`, JSON-LD (`Game` per detail
  page, `LocalBusiness` site-wide — `Game` not `Product` since this isn't commerce; `LocalBusiness`
  not `Organization` since the club has a real physical location already surfaced via the About
  page's Maps embed)
- OG + Twitter Card tags on game detail pages, reusing the existing native-share canonical URL
- Secure session cookie flag, verified HSTS, CSP audit, one-time secrets sweep

**Should have (competitive, in-scope for this milestone per user's explicit ask):**
- Branded site-wide OG fallback image (isologo/wordmark) for pages without a natural hero image
  (catalog index, About)

**Defer (v2+, explicitly out of this milestone):**
- Google Business Profile setup — highest-leverage local-SEO lever available, but it's an
  out-of-band operational task, not a codebase change
- Rate limiting (e.g. Hammer) — correctly deferred: there's no login/POST-heavy surface yet in this
  no-auth catalog; real target arrives with Phase 2's magic-link auth
- Ongoing automated secret-scanning in CI (gitleaks/trufflehog wired into the pipeline) — user
  explicitly chose a one-time sweep over new tooling for this milestone

### Architecture Approach

Per-game SEO metadata must be computed in a new route-scoped Plug (`GameSEO`) that runs *before*
the LiveView mounts, doing its own `Catalog.get_game!/1` lookup and writing to `conn.assigns[:seo]`
— the same channel `get_csrf_token()` already uses to reach `root.html.heex`. The resulting
duplicate DB lookup (plug + `CatalogLive.Show.mount/3`) is an accepted, sub-millisecond cost
(indexed PK query against ~400 rows). `sitemap.xml` is a live controller
(`PukllayClubWeb.SitemapController`, mirroring the existing `HealthController`), not a
build-time-generated static file — Kamal's Docker build has no DB access, so a build-time
generator would ship a snapshot that drifts the moment the catalog changes.

**Major components:**
1. `PukllayClubWeb.Plugs.GameSEO` (new) — resolves the game and builds SEO metadata for
   `/juegos/:id`, feeding both the OG/meta component and the per-game JSON-LD block
2. `PukllayClubWeb.CSP.policy/1` (modified from `policy/0`) — accepts a per-request nonce,
   generated in `put_csp/2`, applied to both the static `LocalBusiness` JSON-LD and the per-game
   `Game` JSON-LD blocks in `root.html.heex`
3. `PukllayClubWeb.SitemapController` (new) — live per-request XML sitemap generation, mirrors
   `HealthController`'s existing pattern
4. `SEOTags` HEEx function component (new) — renders `<meta>`/OG/Twitter tags in `root.html.heex`
   from `conn.assigns`

### Critical Pitfalls

1. **OG tags computed in LiveView `mount`/`handle_params` never reach crawlers** — crawlers only
   see the first disconnected HTTP render and never open a websocket; avoid by computing SEO
   metadata in a pre-mount Plug writing to `conn.assigns`, not a socket assign.
2. **Naively-added inline JSON-LD is silently blocked by this app's own CSP** — `script-src 'self'`
   has no `unsafe-inline` and no nonce; avoid with a per-request nonce (dynamic per-game content)
   or a hash-source (static site-wide content), verified against this app's actual `csp.ex`.
3. **Stale meta tags across LiveView client-side navigation are a real but acceptable limitation**
   — José Valim has stated canonical/OG-style tags don't need live-patch updates since crawlers
   never execute client-side navigation; document this as accepted scope rather than building a
   fragile JS-hook workaround.
4. **A false sense of completeness from `put_secure_browser_headers` alone** — this milestone has
   4 independently-verifiable security gaps (missing `secure: true` on the session cookie,
   unconfirmed actual `Strict-Transport-Security` header in production, a directive-by-directive
   CSP review that must not break the existing Google Maps `frame-src` allowance, and a LiveView
   websocket-reconnect CSRF test) — treat each as its own checkpoint, not one checkbox.
5. **A git-history secrets sweep that only checks currently-tracked files gives false confidence**
   — ~880 commits have landed since the D-19 public-flip check; the sweep must cover full git
   history. Expect common false positives (`signing_salt`, test fixtures) that should NOT be
   rotated — Phoenix's own generator commits `signing_salt` intentionally; the real secret to
   watch for is `secret_key_base`, which should never appear in history at all.

## Implications for Roadmap

Based on research, this milestone fits as **one phase** with a strict internal build order (no
phase split needed — total estimated effort ~4-5 hours of implementation across independent and
dependent pieces):

### Phase (internal step 1): Security hardening
**Rationale:** Independent of everything else, touches only `endpoint.ex`/`config/prod.exs`/CSP —
do first so later steps build on a hardened baseline.
**Delivers:** `secure: Mix.env() == :prod` on the session cookie (env-gated, not bare `true` —
Safari does not exempt `localhost` from the Secure-cookie-requires-HTTPS rule the way
Firefox/Chrome do, so an unconditional flag would break local Safari testing), explicit `hsts:
true` in `config/prod.exs`, curl-verified HSTS header, CSP directive-by-directive review with an
explicit Maps `frame-src` regression check.
**Avoids:** Pitfall 4 (false sense of completeness).

### Phase (internal step 2): CSP nonce infrastructure
**Rationale:** Prerequisite for the JSON-LD work; sequenced right after security hardening since
it modifies the same `csp.ex`/`put_csp/2` code path.
**Delivers:** `policy/0` → `policy/1` refactor, per-request nonce generated in `put_csp/2` and
assigned to `conn`.
**Uses:** `Plug.Conn` primitives already in the stack.

### Phase (internal step 3): GameSEO plug + SEOTags component
**Rationale:** Core of the OG/social-sharing work; depends on step 2's nonce plumbing for the
JSON-LD block it also introduces.
**Delivers:** `PukllayClubWeb.Plugs.GameSEO`, `SEOTags` HEEx component, per-game `Game` JSON-LD
(nonced) and site-wide `LocalBusiness` JSON-LD (hash-sourced), OG + Twitter Card tags on game
detail pages using existing cover art, a 1200×630 image-render step verified against
`ImagePipeline`'s flexibility, and a branded fallback image (isologo/wordmark) for pages without a
natural hero image.
**Implements:** Architecture components 1, 2, 4 above.

### Phase (internal step 4): SEO content — alt text, sitemap, robots.txt
**Rationale:** Fully independent of the OG/JSON-LD work; can run in parallel with step 3.
**Delivers:** Real `alt` text on catalog card/hover-preview images (currently `alt=""`),
`PukllayClubWeb.SitemapController` (live per-request XML), `robots.txt` content edit adding a
`Sitemap:` directive.
**Addresses:** SEO table-stakes from FEATURES.md.

### Phase (internal step 5): Secrets sweep
**Rationale:** No code dependency on anything else; can run anytime, ideally early to surface any
finding before other work builds on top of it.
**Delivers:** A full-git-history secrets sweep (not just tracked files) producing an explicit
triage list — real/rotated, false-positive/documented, inert-historical/accepted.
**Avoids:** Pitfall 5.

### Phase Ordering Rationale

- Security hardening first because it's fully independent and establishes a hardened baseline
  before adding new surface area (JSON-LD, sitemap).
- CSP nonce work must precede JSON-LD content since the JSON-LD blocks need the nonce to render at
  all under this app's existing strict `script-src`.
- Alt-text/sitemap/robots.txt and the secrets sweep have no dependency on the OG/JSON-LD/CSP chain
  and can be parallelized against it.
- This grouping avoids Pitfall 1 (OG-via-socket failure) by design — GameSEO is a Plug from the
  start, never a LiveView assign.

### Research Flags

Phases likely needing a short spike during planning:
- **CSP nonce infrastructure:** ~30-minute spike recommended if unfamiliar with threading a nonce
  through `connect_info`/`on_mount` so it survives LiveView websocket reconnects — well-documented
  pattern (Dan Schultzer), low risk, but non-trivial the first time.

Phases with standard, well-documented patterns (safe to skip a dedicated research-phase pass):
- Security hardening (cookie/HSTS) — verified directly against Plug's own hexdocs and this app's
  actual config.
- Alt text, sitemap, robots.txt — standard Phoenix controller/content patterns.
- Secrets sweep — standard git-history-grep/gitleaks technique, well-documented for a one-time
  solo-dev check.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified directly against Plug/Phoenix hexdocs and this app's own config files; `phoenix_seo`/`sitemapper` rejections checked against each package's own hexdocs |
| Features | MEDIUM-HIGH | schema.org type choices and sitemap/robots conventions cross-checked across 3+ sources; `og:image` 1200×630 sizing assumes `ImagePipeline` can produce that variant — needs verification during execution |
| Architecture | HIGH | Root-layout `conn.assigns` behavior verified verbatim against Phoenix LiveView's official live-layouts guide (two independent fetches, same wording); CSP+JSON-LD interaction cross-checked against MDN/OWASP; sitemap recommendation derived directly from this repo's own Kamal/Docker deploy constraints |
| Pitfalls | MEDIUM-HIGH | OG-via-socket failure corroborated by `phoenix_live_view` issue #1194 and a direct José Valim forum statement; CSP-nonce mechanism cross-checked across 2-4 independent sources; security-header/cookie/CSRF gaps grounded directly in this app's own source code |

**Overall confidence:** HIGH

### Gaps to Address

- `og:image` 1200×630 sizing: verify `ImagePipeline` can actually produce this aspect ratio from
  existing letterboxed cover art before committing to the exact rendering approach — resolve
  during phase planning/execution, not blocking roadmap creation.
- Whether to spend effort on full CSP-nonce plumbing vs. a documented-accepted-risk
  `'unsafe-inline'` shortcut for JSON-LD — both are legitimate options consistent with this
  codebase's existing accepted-risk convention (see prior `WR-04`-style entries); worth an explicit
  decision at plan time.
- Which specific brand asset (`isologo-light.png` vs `isologo-dark.png`, both under
  `priv/static/images/`) serves as the site-wide OG fallback image — a content/design choice for
  plan time, not an architecture question.
- Whether the original D-19 public-flip secrets check was a full-history tool-driven scan or a
  manual review — affects how much independent value a fresh full-history sweep adds vs. a
  since-then-only check; resolve by just running the full sweep regardless (cheap, one-time).

## Sources

### Primary (HIGH confidence)
- Phoenix LiveView official `live-layouts` guide — root layout `conn.assigns` vs `socket.assigns`
  behavior
- `phoenix_live_view` GitHub issue #1194 — open feature request confirming no general per-page
  head-metadata primitive exists beyond `<.live_title>`
- Plug's own hexdocs (`Plug.SSL`, `Plug.Session`) — HSTS default behavior, cookie `secure:` option
- This app's own source: `lib/pukllay_club_web/csp.ex`, `router.ex`, `endpoint.ex`,
  `config/prod.exs`, `live/catalog_live/show.ex` (share_control/1), `priv/static/robots.txt`

### Secondary (MEDIUM confidence)
- MDN Content-Security-Policy docs, content-security-policy.com — inline-script CSP enforcement
  applies regardless of `type` attribute (blocks JSON-LD under strict `script-src`)
- Dan Schultzer's writeup — LiveView nonce-threading via `connect_info` for websocket reconnects
- `phoenix_seo` and `sitemapper` hex package docs — evaluated and rejected as over-scoped for this
  app's size/deploy model
- José Valim forum statement — stale meta tags across LiveView client-nav is an accepted,
  documented limitation, not a bug to fix

### Tertiary (LOW confidence)
- General 2026 tool-comparison/history-scrubbing guides for gitleaks/trufflehog-style secrets
  sweeps — cross-checked across 4+ sources converging on the same guidance, but no single
  canonical source

---
*Research completed: 2026-09-11*
*Ready for roadmap: yes*
