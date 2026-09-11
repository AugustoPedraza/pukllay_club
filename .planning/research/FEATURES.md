# Feature Research

**Domain:** SEO / social sharing / security hardening for a small, local (Jujuy) board-game club catalog site
**Researched:** 2026-09-11
**Confidence:** MEDIUM (websearch, cross-checked across multiple independent sources per topic; no HIGH-confidence official-docs lookups were available in this pass — see Sources)

This is organized by the three feature areas named in the milestone, since they have almost no
feature overlap and different downstream owners (SEO = discoverability, social = share-control
integration, security = hardening an already-live app). Within each area: Table Stakes →
Differentiators → Anti-Features, per the standard template.

---

## SEO

### Table Stakes (Users/Search Engines Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Per-page `<title>` via `live_title` | Google truncates/rewrites titles that don't exist; the catalog's ~400 detail pages are currently indistinguishable in search results | LOW | `root.html.heex` already wires `<.live_title default="PukllayClub" suffix=" · PukllayClub">`; each LiveView just needs to assign `:page_title` (game name for detail pages, "Catálogo" for index) — mostly plumbing, not new infra. |
| Per-page `<meta name="description">` | Google shows this as the search-result snippet; missing it means Google auto-extracts arbitrary page text, which reads badly for a Spanish/Jujuy audience | LOW-MEDIUM | Needs a real content decision, not just a template: for game pages, a short natural Spanish sentence per game (could reuse/trim the existing Gemini-translated Spanish description from Phase 01.3 rather than writing 400 new ones by hand) capped ~150-160 chars to avoid truncation. Catalog/index and About pages need one hand-written description each mentioning "Jujuy". |
| Real `alt` text on catalog card / hover-preview images | Screen readers and Google Images both rely on it; currently `alt=""` on every card image is a real accessibility + image-search gap | LOW | Detail pages already do this correctly (`alt={game.name}`) — the fix is applying the same pattern to `game_preview.ex`/`carousel_row.ex` card markup. Straightforward, no design changes. |
| `robots.txt` allowing crawl + pointing at the sitemap | Current file is the unedited `phx.new` scaffold (fully commented out, no `Sitemap:` line) — search engines have no signal at all right now | LOW | Two-line real change: explicit `User-agent: *` / `Allow: /` (or simply no disallow) plus `Sitemap: https://pukllay.club/sitemap.xml`. |
| `sitemap.xml` covering catalog index, all ~400 detail pages, About | Lets Google discover every detail page without depending on internal-link crawling alone; also a light ranking signal (freshness `lastmod`) | LOW-MEDIUM | At 400 URLs this is far under the 50k-URL/50MB single-sitemap limit — no sitemap index needed. A hand-rolled Phoenix controller action querying `Catalog` and rendering XML is simpler than pulling in the `sitemap` hex package at this scale; must only include indexable, canonical, 200-status URLs (i.e., published games only, if a "hidden/draft" concept ever exists). |
| Canonical URL (`<link rel="canonical">`) on every page | Prevents duplicate-content dilution if a game is ever reachable by more than one path/query string | LOW | The share control already computes a canonical `url(~p"/juegos/#{game.id}")` — reuse that exact same string as the `og:url` value and the `<link rel="canonical">` value so there's one source of truth, not two independently-built URLs. |
| `schema.org` JSON-LD on detail pages: `Game` | Enables rich-result eligibility and gives Google structured signals (name, description, image, audience) beyond raw HTML text — directly named in PROJECT.md's target features | MEDIUM | `Game` (not `VideoGame`) is the correct type for a physical board game; map existing fields (name, description, image, minAge/players if modeled) into it. No `offers`/`price` — this isn't commerce. |
| `schema.org` JSON-LD site-wide: `LocalBusiness` | "Club" is an explicitly named canonical `LocalBusiness` example in schema.org's own docs — this is the correct type, not generic `Organization`, because the club has a real physical location (already shown via the About page's live Maps embed) | LOW-MEDIUM | Populate `name`, `address`, `geo` (reuse whatever lat/long backs the existing Maps embed), `areaServed`/`address.addressRegion: "Jujuy"`. Place once, likely in the root layout, not per-page. |
| `hreflang`/`lang="es"` correctness | Already set (`<html lang="es">`) | DONE | No work needed — confirmed already correct in `root.html.heex`; noted here only so it isn't "rediscovered" as a task. |

### Differentiators (Nice-to-Have SEO)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `ItemList` JSON-LD on the catalog/browse page | Slightly richer structured-data coverage of the full catalog, not just individual games | LOW-MEDIUM | Wrap the currently-rendered page of games (or a stable top-N) as an `ItemList` of `Game` items with `position`/`url`. Lower priority than per-page `Game` schema since Google's catalog-listing rich results are less commonly triggered by `ItemList` alone. |
| Google Business Profile listing (Jujuy) | The single highest-leverage local-SEO lever for a physical club — appears in Maps/local-pack results independent of on-site SEO | LOW (no code) | Not a coding task; flag as a companion action for the club, outside this milestone's scope, but worth naming since it's the thing local SEO guides consistently rank above any on-page tactic. |
| `lastmod` freshness signal per game in sitemap | Minor crawl-priority signal | LOW | Only worth it if games have a real `updated_at` already tracked (they likely do via Ecto timestamps) — cheap to add once the sitemap controller exists. |

### Anti-Features (Skip These)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| `Product` schema instead of `Game` | Feels "standard" because most schema.org tutorials are e-commerce-flavored | Implies commerce (price, availability, purchase reviews) that doesn't exist here — the club doesn't sell games online; a `Reservar`-via-WhatsApp flow isn't a checkout | Use `Game` (physical board game type) for detail pages; keep `LocalBusiness` for the club itself. |
| Hand-writing 400 unique meta descriptions from scratch | Feels more "SEO-correct" than reusing existing copy | High content-effort for near-zero marginal SEO gain versus trimming the Spanish descriptions Phase 01.3 already wrote and Gemini-translated | Truncate/summarize the existing per-game Spanish description field into a ≤160-char meta description programmatically, with manual review only for outliers. |
| Full internationalization / `hreflang` alternates for other languages | Looks like SEO best practice in generic guides | The club and its members are Spanish/Rioplatense-only (per user memory: Argentina/voseo locale) — building multi-language infra serves no real audience and adds real maintenance cost | Single `lang="es"`, already correct; do not add. |

---

## Social Sharing (Open Graph / Twitter Card)

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Core OG tags on detail pages: `og:title`, `og:description`, `og:image` (+`og:image:width`/`height`/`alt`), `og:url` | These four tags are what every consuming platform (Facebook, WhatsApp, X, Discord, Slack, iMessage, Telegram) reads at minimum — currently zero exist anywhere, so every shared link renders as a bare blue link with no preview at all | LOW-MEDIUM | Direct dependency: the share control (`share_control/1` in `catalog_live/show.ex`) already computes `@share_url` via `url(~p"/juegos/#{game.id}")` — reuse that exact value for `og:url` rather than recomputing it, and reuse `game.name`/the existing Spanish description for `og:title`/`og:description`. |
| `og:image` sized 1200×630 (1.91:1) | This single dimension renders cleanly, uncropped, across Facebook, X, LinkedIn, Discord, Slack, WhatsApp, and iMessage simultaneously — no per-platform image needed | MEDIUM | Direct dependency: the existing per-game box-art/gallery images (from the Phase 01.3.1 `ImagePipeline`) are letterboxed/near-square for in-page display, not 1.91:1 — this needs either a dedicated share-image render size or an on-the-fly crop/pad step, likely reusing the same image-processing pipeline rather than building a new one. |
| Fallback share image when a game has no cover art | ~sourced from BGG, and Phase 01.3.1 already found some games lack usable art — sharing a broken/missing-image link looks worse than sharing a generic branded one | LOW-MEDIUM | Direct dependency: PROJECT.md already names "a site-wide brand fallback (isologo/wordmark)" — reuse the isologo/wordmark asset already built for the About page header morph (Phase 01.4/01.5), rendered at 1200×630 with brand background, as the single fallback image for every game missing real art. |
| `twitter:card` = `summary_large_image` + `twitter:title`/`twitter:description` | Without an explicit card type, X falls back to a minimal `summary` card (small thumbnail) even when a good image exists | LOW | X reads `twitter:image` first, then falls back to `og:image` automatically — if the `og:image` is already correctly sized, `twitter:image` can often be omitted entirely, reducing duplicate tag maintenance. Only `twitter:card` really needs to be set explicitly. |
| `og:type` = `website` (not `article`) | `article:*`/`product:*` sub-properties are silently ignored by consuming platforms when `og:type` doesn't match, so picking the wrong type either does nothing or misrepresents the content | LOW | Neither `article` (this isn't a blog post) nor `product` (no commerce) cleanly fits; `website` is the safe, correct default for a catalog/detail page. The richer semantics belong in `schema.org` `Game` JSON-LD (SEO section above), not in `og:type`. |
| Image file size discipline for `og:image` | WhatsApp previews frequently fail to load images over ~300-600KB, especially on mobile data — a broken preview is worse than a plain link for a link that's meant to be forwarded in chat | LOW-MEDIUM | Direct dependency: whatever share-image render step is added (see above) should target a compressed JPEG/PNG well under that ceiling — this is a size constraint on the same new pipeline step, not a separate feature. |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Cache-busting query param on share URLs (`?v=` or similar) | WhatsApp caches link previews very aggressively with no public debug/refresh tool; if a game's cover art is corrected later (as already happened once, in Phase 01.3.1), old shares keep showing the stale preview for days/weeks with no way to force a refresh except changing the URL | LOW | Only worth adding if stale-preview complaints actually surface after launch — flagging here so it's a known, deliberate deferral rather than an oversight if it comes up. |
| Site-wide OG/Twitter fallback tags (About/catalog-index pages, not just detail pages) | A shared link to the homepage or About page currently has no preview either | LOW | Same tag set as detail pages but using the brand fallback image and a generic club description everywhere except `/juegos/:id`. |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| Per-platform custom images (separate Facebook/Twitter/WhatsApp image assets) | Some guides recommend platform-specific dimensions (e.g., a distinct 1200×675 for Twitter vs 1200×630 for Facebook) | Real-world overlap between the two aspect ratios is close enough that a single 1200×630 image renders acceptably everywhere; maintaining N image variants per game for marginal cropping differences is not worth it for a 400-game catalog run by a solo dev | One shared 1200×630 `og:image`, reused for `twitter:image` via fallback (or an identical explicit `twitter:image` value). |
| Dynamic/generated OG images with game stats overlaid (weight badge, mechanic chips rendered onto the share image) | Looks impressive, matches the "complexity-teaching UX" theme elsewhere in the product | Meaningful new rendering pipeline (server-side image composition) for a v1.1 milestone whose stated goal is "make the existing catalog shareable," not build new visual features; real box-art alone already communicates far more than a generated badge overlay would in a chat thumbnail | Ship with real (or brand-fallback) box art only; revisit a designed share-card generator as a future differentiator once basic sharing is proven useful. |

---

## Security Hardening

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Explicit `secure: true` on the session cookie | Currently `@session_options` in `endpoint.ex` sets `store: :cookie`, `signing_salt`, and `same_site: "Lax"` but **not** `secure: true` — the cookie is signed (tamper-proof) but not marked HTTPS-only, so it could in theory be sent over a stray plain-HTTP request | LOW | This is a one-line addition to the existing `@session_options` list in `lib/pukllay_club_web/endpoint.ex` — genuinely missing today, not already covered by `force_ssl`. `force_ssl` redirects HTTP→HTTPS but does not itself add the `Secure` cookie attribute. |
| HSTS via `Plug.SSL`'s `force_ssl: [hsts: true]` (or explicit `expires:`) | Already partially in place — `config/prod.exs` sets `force_ssl` with `rewrite_on`/`exclude` for the `/up` health check, but does not set an explicit `hsts:`/`expires:` value, so it's relying on `Plug.SSL`'s default | LOW | Confirm/set an explicit `expires` (OWASP recommends 2 years / 63072000s once confident the site is permanently HTTPS-only; a shorter 6-12 month value is the safer starting point for a solo-dev site with no tested HTTP-fallback plan) rather than leaving it implicit. `includeSubDomains` only matters if subdomains exist — currently they don't. |
| CSP already exists — audit/tighten it, don't build it from scratch | `router.ex` already has a `put_csp` plug calling `PukllayClubWeb.CSP.policy()`, added specifically to close a Phase 0 Sobelow `Config.CSP` finding, and Phase 01.4 already extended it once for the Google Maps `frame-src` | LOW-MEDIUM | This milestone's CSP work is an **audit pass** on existing policy, not new infrastructure: confirm `default-src 'self'`, check that any inline `<script>` (colocated hooks like `.ShareButton` already use `Phoenix.LiveView.ColocatedHook`, which Phoenix generates with its own nonce/hash — verify this isn't accidentally requiring `unsafe-inline`), and confirm the JSON-LD `<script type="application/ld+json">` tags this milestone adds don't trip the same CSP `script-src` restrictions (typically fine since JSON-LD isn't executable script, but worth a explicit check against the current policy). |
| `X-Content-Type-Options: nosniff`, `X-Frame-Options` | Prevents MIME-sniffing attacks and clickjacking; `put_secure_browser_headers` (already in the `:browser` pipeline in `router.ex`) sets Phoenix's default secure-header set, which includes these | DONE (verify) | Already wired via the existing `plug :put_secure_browser_headers` — this milestone's job is to confirm the defaults are actually present in production response headers (e.g. via a header-check tool), not to add new plugs. |
| CSRF protection (`protect_from_forgery`) | Already in place | DONE | Already the `:browser` pipeline's second-to-last plug in `router.ex` — no action needed, confirming only. |
| One-time secrets sweep: git history + all tracked config | PROJECT.md explicitly calls this out — repo just went/is going public, and D-19 already establishes real secrets are gitignored going forward, but that doesn't retroactively clean anything already committed in earlier history | LOW-MEDIUM (mostly manual verification, not new code) | No new tooling needed per PROJECT.md's own note. Practically: grep git history (`git log -p` / a one-off `gitleaks`/`trufflehog` pass, used ad hoc rather than installed as a dependency) for API keys, DB URLs, the Kamal registry password, and the Gemini key; if anything real is found, it must be rotated (not just scrubbed from history — anything ever pushed to a public remote should be treated as burned) before/alongside any history rewrite. |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|--------------------|------------|-------|
| Basic rate limiting (Hammer + `Hammer.Plug`, ETS-backed) on any public form-submission endpoint | Protects against scripted abuse now that the repo/site is more widely shared; ETS backend is single-node/in-memory, which matches this project's single-host Kamal deploy with no distributed cache | LOW-MEDIUM | Not urgent today: the current app has no login/magic-link form yet (that's Phase 2) and no other public POST endpoint — there's arguably nothing to rate-limit yet beyond generic abuse protection on the WhatsApp-deeplink/share flows, which are client-side only (no server POST). Worth adding defensively at low cost, but genuinely optional for *this* milestone; becomes table-stakes once Phase 2's magic-link auth form ships. |
| `.sobelow-conf` review pass | Sobelow already runs in CI/`mix quality` per the project's fixed tooling — a security-focused milestone is a natural moment to re-review any existing allowlisted findings, not just add new checks | LOW | Confirm no stale exemptions are hiding a now-relevant finding; this is a review task, not new infrastructure. |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| `SameSite: Strict` on the session cookie | Sounds like the "more secure" choice on a security-hardening pass | Breaks cross-site navigation into the app (e.g., a WhatsApp-forwarded link opening a fresh session correctly) more often than it protects against anything `Lax` doesn't already cover for a read-mostly, no-login-yet site | Keep the already-configured `same_site: "Lax"` — correct as-is, don't "upgrade" it. |
| A CSP nonce/hash system built from scratch for this milestone | Feels like the "proper" way to harden CSP further | The project already has a working CSP plug closing the one Sobelow finding it was built for; a full nonce-based inline-script system is a meaningfully larger lift than this milestone's stated scope ("audit and fixes") and isn't blocking anything named in PROJECT.md | Audit the existing policy against the new JSON-LD/OG tags this milestone adds; only reach for nonces if something concrete in that audit actually requires `unsafe-inline` and can't be avoided otherwise. |
| Installing `gitleaks`/`trufflehog` as a permanent CI dependency | Feels like the thorough, "do it right" choice for a secrets sweep | PROJECT.md explicitly scopes this as "no new tooling" — a one-time ad hoc scan (or even manual `git log -p` diligence for a repo this size/age) satisfies the stated requirement without adding a new tool to maintain forever | Run a one-time scan with a temporary/uninstalled tool invocation (e.g. `npx`/`docker run` a scanner once) or manual review; don't add a new mix dependency or CI step for this. |
| Full WAF / bot-blocking service (Cloudflare proxy mode, etc.) | "Security hardening" broadly suggests adding a CDN/WAF layer | Directly contradicts the project's existing infra constraints (Kamal + kamal-proxy only, no Caddy/extra proxy layer, ~€15/mo budget) and isn't named anywhere in this milestone's actual scope | Rely on the existing kamal-proxy + Plug-level headers/CSP/rate-limiting stack; revisit only if real abusive traffic is observed post-launch. |

---

## Feature Dependencies

```
[Share control canonical URL (already exists)]
    └──feeds──> [og:url tag] ──must-match──> [<link rel="canonical">]

[Existing per-game images / ImagePipeline]
    └──requires-new-step──> [1200x630 og:image render/crop]
                                └──requires──> [Brand fallback image (isologo/wordmark)]
                                                  for games with no usable art

[Existing Spanish game descriptions (Phase 01.3 Gemini translation)]
    └──feeds──> [meta description] ──reused-by──> [og:description] ──reused-by──> [twitter:description]

[schema.org Game JSON-LD per detail page]
    └──enhances──> [sitemap.xml entry for the same page] (both use the same canonical URL)

[schema.org LocalBusiness JSON-LD]
    └──requires──> [About page's existing address/geo data] (already surfaced via the live Maps embed)

[Existing CSP plug + policy module]
    └──must-be-audited-before──> [JSON-LD <script> tags] and [any new inline script]
                                     to avoid breaking `script-src`

[Existing session cookie config]
    └──requires-one-line-fix──> [secure: true] (currently missing, independent of force_ssl)

[Phase 2 magic-link auth form] (future, not this milestone)
    └──will-require──> [rate limiting on the login/magic-link endpoint]
                            (optional now, table-stakes once that form exists)
```

### Dependency Notes

- **og:image requires a new image-render step, not new source images:** the actual box-art assets already exist from Phase 01.3.1's `ImagePipeline`/`GalleryBackfill` work; what's missing is a 1.91:1 crop/pad variant sized for social platforms, plus the brand-fallback asset for games lacking real art.
- **og:url/canonical must share one source of truth:** the share control already builds `url(~p"/juegos/#{game.id}")` — every other URL-bearing tag (OG, canonical, sitemap `<loc>`, JSON-LD `url` field) should derive from that same helper, not be independently constructed, to avoid drift.
- **JSON-LD and CSP interact:** because a CSP policy already exists and is actively audited by Sobelow, any new `<script type="application/ld+json">` block must be checked against the current `script-src` directive before assuming it "just works."
- **Rate limiting is soft-blocked on Phase 2, not required now:** there's no login/POST form in the app yet, so Hammer-based rate limiting has no obvious target beyond generic defensive posture — reasonable to defer to Phase 2 without it being a scope cut.

## MVP Definition

### Launch With (v1.1 — this milestone)

- [ ] `page_title` + meta description on catalog index, About, and every game detail page — table stakes, currently fully absent
- [ ] Real `alt` text on catalog card/preview images (detail pages already correct) — cheap accessibility + image-SEO fix
- [ ] `robots.txt` with real allow rules + `Sitemap:` reference, and a working `sitemap.xml` covering all published games — currently the unedited scaffold
- [ ] `schema.org` `Game` JSON-LD per detail page + `LocalBusiness` JSON-LD site-wide (Jujuy address/geo) — explicitly named in PROJECT.md's target features
- [ ] Canonical `og:title`/`og:description`/`og:image`/`og:url` + `twitter:card=summary_large_image` on detail pages, reusing the share control's existing canonical URL
- [ ] 1200×630 share-image render per game + one brand-fallback image (isologo/wordmark) for games without usable art
- [ ] Site-wide OG/Twitter fallback tags on non-detail pages (index, About) using the same brand fallback image
- [ ] `secure: true` added to the session cookie config (currently missing)
- [ ] Explicit HSTS `expires` value set (currently relying on `Plug.SSL` default)
- [ ] CSP audit pass confirming the existing policy still holds against new JSON-LD/OG additions
- [ ] One-time git-history + tracked-config secrets sweep, with rotation of anything real found

### Add After Validation (v1.x)

- [ ] `ItemList` JSON-LD on the catalog browse page — lower-value structured data, add once per-page `Game` schema is confirmed working
- [ ] Cache-busting/refresh strategy for stale WhatsApp previews — only if stale-preview complaints actually surface
- [ ] Basic Hammer rate limiting — becomes table-stakes once Phase 2's magic-link auth form exists; optional filler now

### Future Consideration (v2+)

- [ ] Google Business Profile setup for the club — real local-SEO leverage, but an out-of-band/non-code action, not part of this codebase milestone
- [ ] Dynamically generated share-card images (stats/badges overlaid on box art) — a genuine future differentiator, explicitly deferred as scope creep for a "make it shareable" milestone

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|----------------------|----------|
| Per-page title/meta description | HIGH | LOW | P1 |
| robots.txt + sitemap.xml | HIGH | LOW-MEDIUM | P1 |
| Card image alt text | MEDIUM | LOW | P1 |
| Game + LocalBusiness JSON-LD | HIGH | MEDIUM | P1 |
| OG/Twitter tags on detail pages | HIGH | LOW-MEDIUM | P1 |
| 1200x630 share-image render + brand fallback | HIGH | MEDIUM | P1 |
| Site-wide OG fallback (non-detail pages) | MEDIUM | LOW | P1 |
| Secure cookie flag | HIGH | LOW | P1 |
| HSTS explicit expires | MEDIUM | LOW | P1 |
| CSP audit vs new tags | HIGH | LOW-MEDIUM | P1 |
| Secrets sweep + rotation | HIGH | LOW-MEDIUM | P1 |
| ItemList JSON-LD | LOW-MEDIUM | LOW-MEDIUM | P2 |
| WhatsApp cache-busting | LOW | LOW | P3 |
| Hammer rate limiting | LOW (today) / HIGH (post-Phase 2) | LOW-MEDIUM | P2 |
| Google Business Profile | HIGH (local reach) | N/A (not code) | P2 (parallel action) |
| Generated share-card images | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for this milestone (v1.1)
- P2: Should have, add when possible / when its real trigger condition arrives
- P3: Nice to have, future consideration

## Sources

- Codebase inspection (this session): `lib/pukllay_club_web/components/layouts/root.html.heex`, `lib/pukllay_club_web/live/catalog_live/show.ex` (share control), `lib/pukllay_club_web/router.ex`, `lib/pukllay_club_web/endpoint.ex`, `config/prod.exs`, `priv/static/robots.txt` — HIGH confidence (direct read of current production code)
- `.planning/PROJECT.md` — HIGH confidence (project's own source of truth for scope/history)
- Open Graph image sizing and required-tag guides (multiple independent sources cross-checked: krumzi.com, ogfixer.com, myog.social, screenhance.com, thatdevpro.com) — MEDIUM confidence
- og:type semantics (feather.so, seotest.app, opengraph.to) — MEDIUM confidence
- Twitter/X Card size/fallback behavior (opengraphplus.com, screenhance.com, ogpreview.io, seotest.app) — MEDIUM confidence
- WhatsApp link-preview requirements and caching behavior (developers.facebook.com, ogrilla.com, opengraphplus.com) — MEDIUM confidence
- schema.org `Game`/`VideoGame` type definitions (schema.org, schemantra.com) — MEDIUM confidence
- schema.org `LocalBusiness` vs `Organization` guidance, including "club" as a named `LocalBusiness` example (schema.org, localsearchforum.com, resocial.us, searchxpro.com) — MEDIUM confidence
- robots.txt/sitemap.xml conventions (rankai.ai, straightnorth.com, danschultzer.com re: Phoenix XML feeds, elixirforum.com sitemap thread) — MEDIUM confidence
- Local SEO practices for small regional businesses/clubs (business.nextdoor.com, seoprofy.com, boulderseomarketing.com) — MEDIUM confidence
- Phoenix/Plug security headers (github.com/anotherhale/secure_headers, danschultzer.com CSP+LiveView post, hexdocs.pm Sobelow Config.CSP) — MEDIUM confidence
- Hammer / Hammer.Plug rate limiting (hexdocs.pm/hammer, elixirforum.com, paraxial.io, github.com/ExHammer) — MEDIUM confidence
- OWASP Cheat Sheet Series — CSP and HSTS (cheatsheetseries.owasp.org) — MEDIUM confidence (summarized via search, not a direct page fetch this session)

---
*Feature research for: SEO / social sharing / security hardening on PukllayClub v1.1*
*Researched: 2026-09-11*
