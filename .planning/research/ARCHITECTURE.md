# Architecture Research — SEO / Social-Sharing / Security-Hardening Integration

**Domain:** Per-page SEO metadata, OG/Twitter Card tags, JSON-LD, sitemap.xml, and cookie/HSTS
hardening on top of an existing Elixir/Phoenix 1.8 LiveView app (PukllayClub v1.1)
**Researched:** 2026-09-11
**Confidence:** HIGH (mechanism claims verified against Phoenix/Plug docs and this repo's actual
source; CSP+JSON-LD interaction confirmed against MDN/CSP spec sources — see Sources)

This is integration research only. It assumes the existing architecture (root layout, router
pipelines, CSP module, endpoint session config) described in the milestone brief and does not
re-derive Phoenix/LiveView basics.

## The Core Risk, Stated Precisely

**The root layout (`root.html.heex`) is rendered from `conn.assigns`, not from the LiveView's
`socket.assigns`.** This is true even on the very first (disconnected/"dead") HTTP GET that a
crawler or link-unfurler makes — the one exception is `@page_title`, which Phoenix LiveView
special-cases with hardcoded internal wiring (it patches `document.title` directly / bridges the
one assign into the layout render). No other assign set inside `CatalogLive.Show.mount/3` or
`handle_params/3` (e.g. a hypothetical `assign(socket, :meta_description, ...)`) will ever reach
`root.html.heex` — this is documented explicitly in Phoenix LiveView's own guide: "If you find
yourself needing to dynamically patch other parts of the base layout... a regular, non-live, page
navigation should be used instead."

This does **not** mean LiveView content is invisible to crawlers. The disconnected/dead render
already produces the LiveView's own full HTML `@inner_content` (game name, description, cover
image markup) synchronously, before any JS/websocket exists — that's how the page already works
today with JS disabled. The gap is specifically **`<head>` metadata that only the LiveView's
`mount/3` knows how to compute** (which game, which description, which image) but that the root
layout has no channel to receive.

**Consequence for this milestone:** OG/Twitter/meta-description tags for `/juegos/:id` cannot be
threaded through `assign(socket, :meta_tags, ...)` + a root-layout read, no matter how tempting
that looks next to the existing `@page_title` pattern. They must be computed **before** the
LiveView pipeline runs, in the `conn`/Plug world, where `root.html.heex` already has full assign
access (this is exactly how `get_csrf_token()` and any future conn-derived value already flow into
that template today).

## Standard Architecture (as it should exist after this milestone)

```
┌────────────────────────────────────────────────────────────────────┐
│ Router pipeline (per-request, BEFORE LiveView ever mounts)         │
│                                                                      │
│  :browser  →  [existing] fetch_session, put_root_layout,           │
│               protect_from_forgery, put_secure_browser_headers,    │
│               put_csp (MODIFIED: now generates+assigns a nonce)    │
│                                                                      │
│  route-scoped pipe_through addition, ONLY on `/juegos/:id`:        │
│               PukllayClubWeb.Plugs.GameSEO (NEW)                   │
│               — Catalog.get_game!/1, builds one %SEO{} struct,     │
│                 assign(conn, :seo, ...)                            │
└───────────────────────────┬──────────────────────────────────────┘
                             ↓ conn.assigns now carries :csp_nonce
                             ↓ and (only on /juegos/:id) :seo
┌────────────────────────────────────────────────────────────────────┐
│ root.html.heex (MODIFIED)                                          │
│  — reads @csp_nonce, @seo (nil on every non-game route)            │
│  — renders <PukllayClubWeb.SEOTags.render seo={@seo} .../> (NEW)   │
│    → meta description / OG / Twitter Card, falls back to           │
│      site-wide brand defaults when @seo is nil                     │
│  — renders LocalBusiness JSON-LD unconditionally (static, nonced)  │
│  — renders Game JSON-LD from @seo.json_ld when present (nonced)    │
│  — {@inner_content} ← the LiveView's own rendered HTML             │
└───────────────────────────┬──────────────────────────────────────┘
                             ↓ (unaffected by any of the above)
┌────────────────────────────────────────────────────────────────────┐
│ CatalogLive.Index / CatalogLive.Show / AboutLive                   │
│  — unchanged mount/handle_params logic                             │
│  — page_title assign keeps working exactly as today                │
│  — body content (real name/description/images/alt text) already   │
│    renders on the dead request; only alt-text edits needed here    │
└────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│ PukllayClubWeb.SitemapController (NEW, controller — not a static   │
│ file), GET /sitemap.xml → live query over Catalog.Game             │
└────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | New or Modified |
|-----------|-----------------|------------------|
| `PukllayClubWeb.Plugs.GameSEO` | Fetches the one game for `/juegos/:id`, builds title/description/image/canonical-URL + the Game JSON-LD payload into `conn.assigns[:seo]` | **NEW** file, `lib/pukllay_club_web/plugs/game_seo.ex` |
| `PukllayClubWeb.SEOTags` | Function component rendering all `<meta>` OG/Twitter/description tags from `@seo` (or site-wide fallback) | **NEW** file, `lib/pukllay_club_web/components/seo_tags.ex` |
| `root.html.heex` | Renders `SEOTags`, LocalBusiness JSON-LD, and (conditionally) Game JSON-LD in `<head>`/end of `<body>`; reads `@csp_nonce` | **MODIFIED** |
| `PukllayClubWeb.Router` | New route-scoped `pipe_through` addition on `/juegos/:id` only; `put_csp/2` now generates+assigns a per-request nonce | **MODIFIED** |
| `PukllayClubWeb.CSP` | `policy/0` → `policy/1`, taking the nonce, emitting `script-src 'self' 'nonce-<n>'` | **MODIFIED** |
| `PukllayClubWeb.SitemapController` | `GET /sitemap.xml`, queries `Catalog` for id+updated_at, renders XML | **NEW** file, `lib/pukllay_club_web/controllers/sitemap_controller.ex` |
| `PukllayClub.Catalog` | New lean query, e.g. `list_game_urls/0` (selects only `id`, `updated_at`) for the sitemap — avoid loading full game structs (description/images) for this | **MODIFIED** (add one function) |
| `PukllayClubWeb.Endpoint` | `@session_options` gains `secure: Mix.env() == :prod` | **MODIFIED** |
| `config/prod.exs` | `force_ssl` gains explicit `hsts: true` (already the Plug.SSL default — see below — but make it visible/intentional rather than implicit) | **MODIFIED** |
| `priv/static/robots.txt` | Add `User-agent: *` / `Allow: /` / `Sitemap: https://pukllay.club/sitemap.xml` | **MODIFIED** (static text edit, no code) |

## Question-by-Question Findings

### 1. How do per-page dynamic meta/OG tags get threaded through the root layout?

**Not** `assign(socket, :meta_tags, ...)` read by the root layout — verified against Phoenix
LiveView's own guide, that channel does not exist for anything but `@page_title`. The idiomatic
pattern for data that is (a) only known via a DB lookup keyed off a route param, and (b) required
in the very first static HTML response, is:

1. A **Plug**, not a LiveView `on_mount` hook (`on_mount` operates on the socket, same dead end),
   scoped only to the route(s) that need dynamic per-item metadata (`/juegos/:id`). It runs inside
   the normal Plug/`conn` pipeline, before `Phoenix.LiveView.Plug` engages, and does the one DB
   lookup (`Catalog.get_game!/1`) needed to build title/description/image.
2. `assign(conn, :seo, %{...})` — a plain `conn` assign. Unlike LiveView socket assigns, **`conn`
   assigns set by earlier plugs in the pipeline DO reach `root.html.heex`** on the initial request,
   the same mechanism that already makes `get_csrf_token()` available there today. This is the load
   -bearing asymmetry to internalize: conn→root-layout is an open channel; socket→root-layout is
   closed except for `@page_title`.
3. A **dedicated function component** (`PukllayClubWeb.SEOTags`), not inline markup duplicated
   across every route, renders the actual `<meta>` tags from that assign, with a sane site-wide
   fallback (brand name, generic Spanish description, isologo/wordmark image) for every route where
   `@seo` is `nil` (`/`, `/club`, `/quienes-somos`).

This means, yes, `CatalogLive.Show.mount/3` will end up doing the **same** `Catalog.get_game!/1`
lookup a second time (once in the plug, once in the LiveView's own mount) for the initial request.
Accept this duplication rather than trying to avoid it — it is a single indexed PK lookup on a
~400-row table (sub-millisecond), and avoiding it would require stuffing a full game struct into
the signed session cookie (an anti-pattern: session should carry small identifiers, not domain
data) or a `live_session`-level `:session` MFA that reaches into the same repo call anyway. Keep it
simple: two cheap, independent lookups, one per layer that needs the data.

### 2. Does this differ for the initial GET vs. the connected-socket render?

Yes, and this is the crux of the milestone's one real architectural risk. **OG tags MUST come from
the plug+root-layout path, full stop** — they are never touched again after the dead render, because:

- Crawlers/link-unfurlers (Facebook, WhatsApp, Twitter/X, Google) issue a single HTTP GET and never
  execute JS or open the LiveView websocket. Whatever HTML comes back from that one request is the
  entirety of what they see.
- Even for a real browser, the root layout is rendered exactly **once** per dead request and is
  never patched again for the life of that page/socket — Phoenix LiveView's own docs are explicit
  that `<head>` content beyond `@page_title` cannot be dynamically patched during live navigation;
  a full non-live page load is the documented escape hatch if per-navigation head changes were ever
  needed. Since this app has no live-navigation-between-different-games flow that would need to
  swap OG tags mid-session anyway (each `/juegos/:id` visit is its own dead request from a crawler's
  perspective, and from a real user's perspective the OG tags of the page they landed on are what
  matters, not what they navigate to next), this limitation is a non-issue in practice — just don't
  reach for `assign(socket, :seo, ...)` expecting it to update anything in `<head>`.
- The plug-computed `conn.assigns[:seo]` is only ever consulted at the moment `root.html.heex`
  renders, which is precisely the dead-request moment. This is exactly right for OG/meta tags,
  which only need to be correct for the URL that was requested, not for wherever the user clicks
  next.

### 3. Where should `sitemap.xml` be generated — static file vs. live controller?

**Live controller action**, not a static file regenerated at deploy/build time. Reasoning specific
to this app's deploy shape:

- Kamal builds the Docker image **before** it is deployed, and the build step has no route to the
  running Postgres accessory (there is no DB connection available during `docker build`). A
  build-time sitemap generator would have to ship a **committed, manually-regenerated** snapshot of
  game IDs — which goes stale the moment a game is added/removed/renamed post-deploy, silently,
  with no mechanism to notice. That directly contradicts the catalog being a living, admin-editable
  dataset (Phase 4 adds catalog management on top of this same `Game` schema).
- At ~400 rows, `SELECT id, updated_at FROM games` is a trivial, sub-millisecond query with no
  N+1 risk — there is no performance argument for precomputing this file. `HealthController`
  already establishes the "plain controller action, outside the SPA/LiveView world, minimal
  pipeline" pattern this should follow.
- Concretely: `PukllayClubWeb.SitemapController.index/2` (new file, mirrors `HealthController`'s
  shape), `Catalog.list_game_urls/0` (new lean query, new file addition — do **not** reuse
  `Catalog.list_games/1`'s full struct-loading query; select only `id` and `updated_at`), router
  gets `get "/sitemap.xml", SitemapController, :index`. Content-type `application/xml`
  (`put_resp_content_type/2`), body built with `Enum.map/2` + string interpolation or a small EEx
  template — no sitemap-building library needed at 400 URLs (a `<urlset>` with `/`, `/club`,
  `/quienes-somos`, and one `<url>` per game is a handful of lines).
  - Verified: `PukllayClubWeb.static_paths/0` currently returns
    `~w(assets fonts images favicon.ico robots.txt)` — it does **not** include `sitemap.xml`, so a
    controller route at that path is safe and will not be shadowed by `Plug.Static`. Do **not** add
    `sitemap.xml` to that list, and do **not** leave a placeholder file at
    `priv/static/sitemap.xml` — `Plug.Static` runs before the router in the endpoint pipeline and
    would silently serve a stale static file forever if one existed there, never reaching the
    controller.
- No caching layer needed at this scale/traffic; if the query ever becomes a real cost (it won't at
  400 rows), an ETS/ Cachex TTL cache in front of the controller is a one-line addition later, not
  a v1.1 concern.

### 4. Where should JSON-LD (schema.org `Game` + `LocalBusiness`) actually render?

**Both belong in `root.html.heex`, driven by the same plug/conn mechanism as the OG tags — not
inline in the LiveView template.** This was not the obvious choice going in (JSON-LD doesn't
strictly require `<head>` placement, and it's tempting to add it as another private function
component inside `CatalogLive.Show`, next to `share_control/1`, since the LiveView's own render
already has `@game` in scope for free). Two things push it back to the plug/root-layout path
instead:

1. **Consistency of a single mechanism.** The plug already computes name/description/image for OG
   purposes; the Game JSON-LD payload (`@type: "Product"` or `"Game"`, name, description, image,
   URL) is built from exactly the same fields. Computing it once in `GameSEO` and stashing it on
   the same `%{seo | json_ld: ...}` struct avoids a second, independently-evolving copy of "how do
   we describe this game for machines" inside `catalog_live/show.ex`.
2. **The CSP collision (the actual non-obvious finding here).** `PukllayClubWeb.CSP.policy/0`
   currently emits `script-src 'self'` with **no** `'unsafe-inline'`. Any inline
   `<script type="application/ld+json">` — literal JSON content, not executable JS — is still
   gated by CSP's `script-src` directive; browsers block it exactly like a blocked inline `<script>`
   unless it carries a matching nonce, a matching hash, or the policy allows `'unsafe-inline'`. (The
   existing `share_control/1`'s `<script :type={Phoenix.LiveView.ColocatedHook}>` is not a
   counterexample: LiveView's colocated-hook compiler, wired via `mix.exs`'s
   `compilers: [:phoenix_live_view] ++ Mix.compilers()`, extracts that markup at compile time into
   the bundled `'self'`-origin `app.js` — it never survives as literal inline script content in the
   rendered HTML, so it was never actually exercising `script-src` the way a hand-written JSON-LD
   block would.) Silently shipping JSON-LD without addressing this would mean it renders in the
   HTML source (crawlers that read raw HTML, e.g. Google's structured-data parser, may still pick
   it up) but gets policy-blocked in an actual browser's DevTools/CSP report — an easy thing to ship
   and not notice until an audit tool flags it.
   - **Because the Game JSON-LD payload differs per game (~400 distinct payloads) and changes
     whenever a game's data is edited, a hash-based CSP source (`'sha256-...'`) is the wrong tool**
     — hashes are for static, build-time-known content and can't reasonably enumerate 400+ variants
     or track live edits. A **per-request nonce** is the CSP mechanism actually designed for
     dynamic, server-rendered inline content.
   - Recommended shape: `put_csp/2` (router.ex) generates one random nonce per request
     (`Base.encode64(:crypto.strong_rand_bytes(16))`), does `assign(conn, :csp_nonce, nonce)` (a
     plain conn assign, reaches `root.html.heex` the same way `:seo` does) and calls
     `PukllayClubWeb.CSP.policy(nonce)`, which emits `script-src 'self' 'nonce-#{nonce}'`. The
     LocalBusiness script (always rendered, static content) and the Game JSON-LD script
     (conditionally rendered from `@seo.json_ld`) both carry `nonce={@csp_nonce}` — one nonce, one
     mechanism, no need to also juggle a hash source for the static block.
   - Lower-effort fallback worth naming explicitly (and consistent with this codebase's existing
     "documented accepted risk" convention — see `config/runtime.exs`'s `WR-04` comment on
     disabled DB TLS): adding `'unsafe-inline'` to `script-src` as a one-line stopgap is a real
     option for a solo-dev, budget-constrained project if the nonce plumbing is judged not worth
     the effort this milestone. If chosen, document it the same way `WR-04` is documented (an
     explicit accepted-risk comment in `PukllayClubWeb.CSP`, not a silent addition) rather than
     defaulting to it without a decision.

The `LocalBusiness` block is genuinely static (Jujuy club context, never varies per request) — it
belongs unconditionally in `root.html.heex`, no plug needed to compute it, just co-located with the
new `SEOTags` render call and nonced identically to the Game block.

### 5. `secure: true` on the session cookie — where, precisely?

`lib/pukllay_club_web/endpoint.ex`, in the existing `@session_options` module attribute (used in
three places already: both `socket "/live"`/longpoll `connect_info` blocks and
`plug Plug.Session, @session_options` — a single edit point fixes all three call sites, which is
exactly why this attribute exists as a shared constant rather than being redeclared per use):

```elixir
@session_options [
  store: :cookie,
  key: "_pukllay_club_key",
  signing_salt: "NLUjW6HL",
  same_site: "Lax",
  secure: Mix.env() == :prod
]
```

Gate it on `Mix.env() == :prod`, not a bare `true` — this file already branches on `Mix.env()` a
few lines down (`if Mix.env() == :dev do plug Tidewave end`), so this matches an established local
convention rather than introducing a new one. A bare `secure: true` would break local dev (dev runs
over plain `http://localhost`, and a `Secure` cookie is never set/sent by the browser over a
non-HTTPS origin — this would silently break session-dependent local behavior, not just "look"
insecure). Production always serves over HTTPS (`force_ssl` + Kamal-proxy TLS), so `Mix.env() ==
:prod` is a safe, correct gate here — this doesn't need to be a runtime/env-var toggle the way
`DATABASE_URL`/`R2_PUBLIC_BASE_URL` are, because it's not environment-specific *within* prod, it's
purely dev-vs-prod.

### 6. Is HSTS actually emitted by the existing `force_ssl` config?

**Yes, already, today, with no code change required to make it fire** — `Plug.SSL`'s `:hsts` option
defaults to `true` whenever `force_ssl` is configured at all (default `expires: 31_536_000` ≈ 1
year, `subdomains: false`, `preload: false`). `config/prod.exs`'s current
`force_ssl: [rewrite_on: [:x_forwarded_proto], exclude: [...]]` does not set `:hsts` explicitly,
which means it is relying on that default — correct behavior, but implicit. Confirm rather than
assume: hit production with `curl -I https://pukllay.club` post-deploy and check for a
`strict-transport-security: max-age=31536000` response header (not present in the `/up` health
path, since that's explicitly excluded).

Recommend making it explicit in the milestone's diff even though it changes no runtime behavior —
self-documenting code over relying on an implicit library default that a future reader (or a future
security audit) would otherwise have to go look up:

```elixir
config :pukllay_club, PukllayClubWeb.Endpoint,
  force_ssl: [
    hsts: true,
    rewrite_on: [:x_forwarded_proto],
    exclude: [
      paths: ["/up"],
      hosts: ["localhost", "127.0.0.1"]
    ]
  ]
```

Do not turn on `subdomains: true` or `preload: true` — pukllay.club has no subdomains in play, and
HSTS preload is a one-way, hard-to-reverse commitment (submission to browser vendors' hardcoded
preload lists) that is not warranted for a solo-club catalog site; leave both at their safe
defaults (`false`).

## Build Order

Ordered by dependency, not by milestone-brief listing order:

1. **Security hardening first — no dependency on anything else in this milestone.**
   `endpoint.ex` (`secure: Mix.env() == :prod`), `config/prod.exs` (explicit `hsts: true`). Fast,
   isolated, zero risk of blocking later work, and it's the one item with literally no interaction
   with the SEO plumbing below.
2. **`PukllayClubWeb.CSP` nonce refactor next — a prerequisite for JSON-LD, not for OG tags.**
   `policy/0` → `policy/1`, `put_csp/2` generates+assigns the nonce. Do this before JSON-LD work so
   the nonce is already flowing through `conn.assigns` and available in `root.html.heex` by the
   time JSON-LD needs it. This does **not** block the OG/meta-tag work (tags 3–5 below need no
   nonce, they're not `<script>` elements) — sequence it here only because both this step and the
   next two share the root-layout/plug wiring and are easiest to land as one coherent pass.
3. **`PukllayClubWeb.Plugs.GameSEO` + router pipe_through change.** Build the `%{title, description,
   image, canonical_url, json_ld}` struct for `/juegos/:id`. This is the one piece every downstream
   step (OG tags, Twitter Card, Game JSON-LD) reads from.
4. **`PukllayClubWeb.SEOTags` component + `root.html.heex` edit.** Wire `@seo` (with site-wide
   fallback for every other route) into real `<meta>` tags; add the `LocalBusiness` JSON-LD
   (static, nonced) and the conditional Game JSON-LD (from `@seo.json_ld`, nonced) in the same pass
   since they share the template edit and the nonce plumbing from step 2.
5. **`priv/static/images` alt text / catalog card alt text** — independent LiveView-template-only
   edits (GameCard, GamePreview), no dependency on any of the above; can happen in parallel with
   steps 2–4 if convenient, since it never touches `root.html.heex`, the router, or CSP.
6. **`sitemap.xml` controller + `Catalog.list_game_urls/0` + `robots.txt` `Sitemap:` line last.**
   Independent of the OG/JSON-LD work entirely (separate route, separate controller, no `conn`
   assigns shared with the plug from step 3) — sequenced last only because the `robots.txt` edit
   references the sitemap URL, so the controller should exist first, even though the ordering
   risk here is cosmetic (a `Sitemap:` line pointing at a not-yet-deployed URL is harmless, not a
   hard dependency).
7. **Secrets sweep across git history** (separate milestone line item) has no code dependency on
   any of the above and can run at any point, ideally early, since it's pure audit/cleanup work
   unrelated to this file's integration points.

## Anti-Patterns to Avoid

### Anti-Pattern 1: `assign(socket, :meta_tags, %{...})` read by the root layout

**What people try:** Since `@page_title` already flows from a LiveView's `mount/3` into
`root.html.heex`, it looks natural to generalize the pattern to a `:meta_tags` (or `:og_image`,
`:meta_description`, ...) assign and read it the same way.
**Why it's wrong:** `@page_title` is not a generalizable pattern — it is one specific,
hardcoded bridge inside Phoenix LiveView's internals. No other socket assign crosses into the root
layout, on the connected render *or* the dead render. Code written this way will work in
development against nothing (there's no error — the assign is simply absent from
`root.html.heex`'s own `assigns`, so `assigns[:meta_tags]` there is always `nil`, silently) and
never appear in any crawler-visible `<head>`.
**Do this instead:** Compute the value in a Plug, before the LiveView pipeline runs, and read it
from `conn.assigns` in the root layout (see Question 1/2 above).

### Anti-Pattern 2: Precomputing `sitemap.xml` at Docker build time

**What people do:** Add a `mix sitemap.gen` task to the Dockerfile's build stage, writing
`priv/static/sitemap.xml` so `Plug.Static` serves it for free.
**Why it's wrong:** The Kamal image build has no access to the running Postgres accessory —
there is no DB connection available during `docker build`. Any build-time generator either fails
outright or has to work from a stale, manually-committed snapshot of the catalog that silently
drifts every time a game is added/edited/removed after that image was built. For a catalog that
Phase 4 will make admin-editable, this guarantees drift.
**Do this instead:** A live controller action (`PukllayClubWeb.SitemapController`), same shape as
`HealthController` — trivial query cost at ~400 rows, always correct.

### Anti-Pattern 3: Shipping JSON-LD without touching `script-src`

**What people do:** Add `<script type="application/ld+json">{...}</script>` directly into a
template and move on, since it "isn't really JavaScript."
**Why it's wrong:** CSP's `script-src` directive gates every `<script>` element regardless of its
`type` attribute — a JSON-LD block is blocked by this app's existing `script-src 'self'` exactly
like an unauthorized inline JS block would be. It will still appear in View Source (so a
structured-data linter reading raw HTML might report success) while being invisible to an actual
browser's parsed DOM/any CSP-aware validator — a gap that's easy to ship and not notice.
**Do this instead:** Thread a per-request CSP nonce through `conn.assigns` and apply it to both
JSON-LD `<script>` tags (see Question 4), or explicitly and visibly accept `'unsafe-inline'` as a
documented risk if the nonce plumbing is judged not worth it this milestone.

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|----------------|-------|
| `PukllayClubWeb.Plugs.GameSEO` ↔ `PukllayClub.Catalog` | Direct function call (`Catalog.get_game!/1`) | Same call `CatalogLive.Show.mount/3` already makes; accept the duplicate lookup, don't try to dedupe across the conn/socket boundary |
| `PukllayClubWeb.Plugs.GameSEO` ↔ `root.html.heex` | `conn.assigns[:seo]`, plain map/struct | This is the one channel that actually reaches the root layout on the dead render; do not attempt the equivalent via `socket.assigns` |
| `PukllayClubWeb.Router`'s `put_csp/2` ↔ `root.html.heex` | `conn.assigns[:csp_nonce]` | Same channel/mechanism as `:seo`; both are conn assigns set by pipeline plugs before the LiveView engages |
| `PukllayClubWeb.CSP.policy/1` ↔ `put_csp/2` | Direct function call, now takes the nonce as an argument | Signature change from `policy/0`; every call site (there is exactly one, in `router.ex`) must be updated together |
| `PukllayClubWeb.SitemapController` ↔ `PukllayClub.Catalog` | Direct function call, new lean query (`list_game_urls/0`) | Do not reuse the full-struct catalog-listing query used by `CatalogLive.Index` — select only `id`/`updated_at` |
| `Plug.Static` ↔ `PukllayClubWeb.Router` | Endpoint-pipeline ordering | `Plug.Static` runs first; `sitemap.xml` must stay a controller route, never a file under `priv/static/`, or it will be shadowed silently |

## Sources

- `phoenix-live-view.hexdocs.pm/live-layouts.html` (WebFetch, current Phoenix LiveView docs) — root
  layout rendered from `@conn` on the initial request, `@page_title` as the sole dynamic exception,
  explicit guidance to fall back to non-live navigation for other `<head>` changes — HIGH confidence
  (direct official framework documentation, load-bearing for this entire research question)
- `github.com/phoenixframework/phoenix_live_view/blob/main/guides/server/live-layouts.md` (WebFetch,
  source-of-truth guide text) — corroborates the above verbatim — HIGH confidence
- `github.com/phoenixframework/phoenix_live_view/issues/1194` (WebFetch) — community feature
  request confirming no built-in generalization of `@page_title` exists; the Plug-based workaround
  pattern (assign meta tags via a route-matching Plug before LiveView mounts) is the community's own
  documented answer to this exact gap — MEDIUM confidence (issue thread, not official docs, but
  consistent with the official guide's own stated limitation)
- `plug.hexdocs.pm/Plug.SSL.html` (WebFetch) — `:hsts` defaults to `true` (`expires: 31_536_000`,
  `subdomains: false`, `preload: false`) whenever `force_ssl` is configured — HIGH confidence
  (official Plug documentation, directly answers the milestone's HSTS confirmation question)
- MDN `Content-Security-Policy: script-src` + CSP nonce/hash guidance (WebSearch, cross-checked
  across `content-security-policy.com`, `developer.mozilla.org`, and a JSON-specific CSP discussion)
  — inline `<script type="application/ld+json">` is gated by `script-src` exactly like executable
  inline JS; nonce or hash required — MEDIUM-HIGH confidence (cross-checked across multiple
  independent sources, consistent with the CSP spec's own definition of what `script-src` gates)
- This repository's own source, read directly: `lib/pukllay_club_web/components/layouts/root.html.heex`,
  `lib/pukllay_club_web/router.ex`, `lib/pukllay_club_web/csp.ex`, `lib/pukllay_club_web/endpoint.ex`,
  `lib/pukllay_club_web/live/catalog_live/show.ex`, `lib/pukllay_club_web/controllers/health_controller.ex`,
  `lib/pukllay_club_web.ex` (`static_paths/0`), `config/prod.exs`, `config/runtime.exs`,
  `priv/static/robots.txt` — HIGH confidence (ground truth for every file/module name and existing
  convention referenced above)

---
*Architecture research for: SEO/social-sharing/security-hardening integration into an existing
Phoenix 1.8 LiveView app*
*Researched: 2026-09-11*
