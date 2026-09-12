---
status: diagnosed
trigger: "WhatsApp link preview for a PukllayClub game page does not show the cover-art thumbnail, even though Google Rich Results Test, Facebook Sharing Debugger, and Twitter Card Validator all passed structured-data/social-card validation for the same content in this phase's UAT."
created: 2026-09-12T00:00:00Z
updated: 2026-09-12T05:12:00Z
---

## Current Focus

bug_class: Bohrbug (deterministic — reproduces on every /juegos/:id URL, fixed input → fixed wrong output; no timing/concurrency component). SBFL skipped: no failing test exists, the failure is in a third-party renderer outside any test suite.

known_pattern_candidate: none — knowledge-base.md has no og:image / social-preview / image-format entry (grep for og:image, og_image, whatsapp, webp, social: zero hits across 272 lines).

hypothesis: H1 — WhatsApp's link-preview image renderer does not support WebP. 100% of this app's og:image values are WebP (per-game `og-card.webp` in R2, and the branded fallback `/images/og-fallback.webp`), so WhatsApp has no decodable image for ANY page, while Facebook/Twitter (both WebP-capable) and Google Rich Results (which ignores og:image entirely) all pass on the same URL.

test: Eliminate every non-format OG contract requirement against the live response (absolute URL, HTTPS, 200 no-redirect, Content-Type, byte size, declared-vs-actual dimensions, presence in JS-free server HTML), then confirm image format is the sole surviving differentiator, and corroborate WhatsApp's WebP limitation against external sources.

expecting: If H1 is true, every other OG requirement passes cleanly AND the only property that distinguishes WhatsApp from the three passing validators is WebP decode support.

next_action: Diagnosis complete (goal: find_root_cause_only). Return ROOT CAUSE FOUND. No fix applied. The one human-gated falsification test is: share `https://pukllay.club/juegos/221?v=2` in WhatsApp — a cache-busted URL WhatsApp has never seen.

reasoning_checkpoint:
  hypothesis: "WhatsApp re-displayed a STALE cached link preview for https://pukllay.club/juegos/221 that it had generated during the 2026-09-11 window when production served real game content (post-01.7 catalog restore) but had not yet deployed phase 01.8's OG tags. The current OG block is correct and was never consumed."
  confirming_evidence:
    - "Three-for-three exact field match: reported title 'Llamaland · PukllayClub' is the <title> with live_title's ' · PukllayClub' suffix (og:title is the bare 'Llamaland'); reported bare domain is what WhatsApp shows when NO description exists (og:description and meta description are both present and populated now); no image because none existed then."
    - "git show 1cb2708~1:.../root.html.heex proves the pre-01.8 head had ONLY charset/viewport/csrf/live_title/assets — no meta description, no og:*, no twitter:*, no canonical. That state produces precisely the reported preview."
    - "WhatsApp's documented precedence is og:title FIRST, <title> only as fallback — so a fresh fetch of current production could not have rendered the suffixed title."
    - "Every mechanical OG requirement independently verified as PASSING server-side: absolute HTTPS URL, HTTP 200, zero redirects, no auth, 0.5s, Content-Type image/webp matching the real bytes, 43,186 bytes (42KB, far under the documented ~300KB WhatsApp ceiling), and VP8X-decoded dimensions of exactly 1200x630 matching the declared width/height."
    - "The three validators that PASSED (Facebook Sharing Debugger, Twitter Card Validator) are precisely the ones that force a re-scrape and bypass Meta's cache; Google Rich Results does not evaluate og:image at all. WhatsApp is the only surface with no cache-bypass mechanism — the single property differentiating pass from fail."
  falsification_test: "Share https://pukllay.club/juegos/221?v=2 (a URL WhatsApp has never cached) in WhatsApp. If the 1200x630 cover art appears WITH title 'Llamaland' (no suffix) and the Spanish description, the hypothesis is confirmed. If the image is still absent on that virgin URL, this hypothesis is REFUTED and the surviving candidates are H2 (phx-r attribute defeating WhatsApp's meta parser) or a WhatsApp-side WebP decode failure."
  fix_rationale: "No code fix is indicated for the reported symptom — the root cause is external cached state, not a defect. WhatsApp exposes no invalidation API; the clean URL self-heals as the entry ages out (days-to-weeks). The ?v=2 test is safe and non-polluting because canonical_url for a game is built as url(~p\"/juegos/#{id}\") with no query string, so a shared ?v=2 URL still declares the clean canonical to search engines."
  blind_spots:
    - "I cannot execute WhatsApp's own fetch/render path — it runs on the sender's device. Every server-side precondition is verified, but the final confirmation is necessarily human-gated. Confidence in the root cause is HIGH but not experimentally closed."
    - "The reported preview title/domain detail is a human's recollection recorded in 01.8-UAT.md, not a captured screenshot. The entire refutation of H1 rests on the ' · PukllayClub' suffix being accurate. If the user actually saw the bare 'Llamaland', H1/H2 return to contention."
    - "Whether the URL was genuinely shared on WhatsApp during the 2026-09-11 pre-deploy window is inferred (the site is a 'passed-around link' per STATE.md 01.7, the footer carries a WhatsApp link, and 01.7 UAT had the user clicking the live catalog) — not directly observed."
  candidate_causes:
    - "data/state (CONFIRMED): stale third-party cached preview record keyed on the exact URL, generated from a metadata-less page state"
    - "code (ELIMINATED as cause of this report; retained as latent gap): og:image has no non-WebP variant anywhere — both OgCard's og-card.webp and SEO's og-fallback.webp are WebP, so there is zero escape hatch if any consumer cannot decode WebP"
    - "config (ELIMINATED as cause; retained as real production risk): og:image is served from Cloudflare's pub-*.r2.dev DEVELOPMENT URL, which Cloudflare documents as not for production use, variably rate-limited to HTTP 429, and excluded from edge caching"
    - "environment (context, not cause): WhatsApp generates previews client-side on the sender's device and publishes no cache-invalidation tool, which is what makes a stale entry unfixable from the server"
  and_gate: "NO — the stale cache alone fully and precisely accounts for all three observed fields (suffixed title, bare domain instead of description, absent image). No second condition needs to co-occur; each field is individually explained by the pre-01.8 head and individually inconsistent with a fresh fetch. The WebP-monoculture and r2.dev findings are independent latent risks that did NOT contribute to this symptom (verified: WebP is WhatsApp-supported, and the image returned a clean 200 at 42KB to two crawler UAs)."

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: Sharing a game page URL (e.g. https://pukllay.club/juegos/221) on WhatsApp shows a link preview card with the game's own cover art (or the branded fallback image) at 1200x630, plus title and description — matching the Open Graph contract validated for Facebook/Twitter/Google.
actual: WhatsApp preview shows the title ("Llamaland · PukllayClub") and the bare domain (pukllay.club) but renders NO image thumbnail at all.
errors: None reported by the user; no console errors mentioned. Purely an absent link-preview image.
reproduction: Share https://pukllay.club/juegos/221 (or any /juegos/:id game detail page) as a link in WhatsApp and observe the generated preview card.
started: Discovered during UAT for phase 01.8 (SEO structured data + social sharing), 2026-09-12. Facebook Sharing Debugger and Twitter Card Validator against the SAME URL passed with the expected 1200x630 image in this same UAT session. WhatsApp-only image-preview failure.

## Eliminated
<!-- APPEND only -->

- hypothesis: H1 — WhatsApp's renderer cannot decode WebP, so the WebP og-card yields no thumbnail
  evidence: Two independent refutations. (1) WhatsApp documents/behaves as supporting WebP alongside JPG/PNG per multiple external sources. (2) Far stronger and format-independent: the preview also showed the WRONG TITLE (the `<title>` "Llamaland · PukllayClub" rather than og:title "Llamaland") and NO description despite og:description being present. An image-decode failure cannot corrupt the title or drop the description. WhatsApp never consumed the OG block at all, so the image's format was never reached.
  timestamp: 2026-09-12T04:48:00Z

- hypothesis: og:image is a relative URL that WhatsApp will not resolve
  evidence: Live served value is fully absolute: `https://pub-8f053d9e82db4d8eb43b5666a37546c4.r2.dev/games/330038/og-card.webp`. Both code paths (`OgCard.url_for/1` off the stored absolute cover_url, and `fallback_image_url/0` off `Endpoint.url()`) are structurally incapable of emitting a relative path.
  timestamp: 2026-09-12T04:43:00Z

- hypothesis: og:image is injected by LiveView JS after mount, so a JS-free crawler sees nothing
  evidence: The tag is present in the raw `curl` response body with no JS executed. By design, SEO.for_game/2's payload is written to `conn.assigns[:seo]` by a pre-mount Plug and read only from conn.assigns by root.html.heex/SEOTags — the moduledocs cite this exact crawler pitfall.
  timestamp: 2026-09-12T04:43:00Z

- hypothesis: The image is unreachable, redirected, auth-gated, or too slow/large for WhatsApp's fetch budget
  evidence: HTTP 200 direct, num_redirects=0, no auth challenge, 0.5s, Content-Length 43,186 bytes (42 KB) — an order of magnitude under the commonly cited ~300KB WhatsApp ceiling. Identical response for a WhatsApp UA and a facebookexternalhit UA (no UA-based divergence).
  timestamp: 2026-09-12T04:44:00Z

- hypothesis: Wrong/missing Content-Type on the image response
  evidence: R2 serves `Content-Type: image/webp`, which correctly and truthfully matches the RIFF/WEBP magic bytes in the payload. Plug.Static serves the fallback as image/webp too.
  timestamp: 2026-09-12T04:44:00Z

- hypothesis: Declared og:image:width/height (1200x630) do not match the real image, so WhatsApp rejects it
  evidence: Decoded the VP8X container header directly — canvas width-1 = 0x0004af = 1199 and height-1 = 0x000275 = 629, i.e. exactly 1200x630. Declared and actual agree.
  timestamp: 2026-09-12T04:44:30Z

- hypothesis: H2 — the `phx-r` attribute interposing between `<meta` and `property=` breaks WhatsApp's meta parser (this repo's own test regex demonstrably broke on exactly this, per 01.8-05's recorded fix)
  evidence: Not the cause of THIS report, on two grounds. (1) It cannot explain the symptom's timing: the same `phx-r` markup is what Facebook's Sharing Debugger parsed successfully in the same UAT session. (2) The stale-cache explanation already accounts for all three observed fields without it, and the pre-01.8 head had no og tags for any parser to mis-read. Retained as a live secondary risk to re-test after cache-busting, NOT as a confirmed cause — it is the one hypothesis that would survive a cache bust.
  timestamp: 2026-09-12T04:53:00Z

## Evidence
<!-- APPEND only -->

- timestamp: 2026-09-12T04:40:00Z
  checked: .planning/debug/knowledge-base.md (272 lines) grepped for og:image, og_image, whatsapp, webp, social, image
  found: No prior entry for any social-preview / OG-image / image-format bug class
  implication: No known-pattern shortcut; investigate from scratch. This is a new bug class for this project's KB.

- timestamp: 2026-09-12T04:41:00Z
  checked: lib/pukllay_club_web/seo.ex — how og:image is constructed
  found: `og_image_url/1` = `OgCard.url_for(game) || fallback_image_url()`. `fallback_image_url/0` = `Endpoint.url() <> "/images/og-fallback.webp"` (@og_fallback_path, line 29). Both branches are absolute URLs built off Endpoint.url(), never relative.
  implication: The "relative URL" hypothesis is dead. BUT both branches terminate in a `.webp` file — noted as the first format signal.

- timestamp: 2026-09-12T04:41:30Z
  checked: lib/pukllay_club/catalog/og_card.ex — the per-game og-card object naming
  found: `@object_name "og-card.webp"` (line 17). `url_for/1` derives the og-card URL by replacing the stored cover_url's `cover-large.webp` suffix with `og-card.webp`. There is no non-WebP variant anywhere in the module.
  implication: 100% of per-game og:image values are WebP, and 100% of the fallback path is WebP. Every single page on the site emits a WebP og:image. This exactly matches the user's report that the failure occurs on "any /juegos/:id game detail page".

- timestamp: 2026-09-12T04:42:00Z
  checked: lib/pukllay_club_web/components/seo_tags.ex — the emitted head block
  found: og:image is followed immediately by og:image:width=1200 and og:image:height=630 (hardcoded literals, lines 39-40). twitter:image reads the same @seo.image_url field. No `og:image:type` tag is emitted, and no `og:image:secure_url`.
  implication: Ordering and width/height presence requirements are satisfied. og:image:type absence noted as a possible secondary contributor (candidate, not yet tested).

- timestamp: 2026-09-12T04:43:00Z
  checked: `curl -A "WhatsApp/2.23.20.0 A" https://pukllay.club/juegos/221` — the raw, JS-free server-rendered HTML actually served to a WhatsApp-UA client
  found: HTTP 200, 29,538 bytes. og:image IS present in the raw server HTML at ~line 12 of <head>, literal value `https://pub-8f053d9e82db4d8eb43b5666a37546c4.r2.dev/games/330038/og-card.webp`. Full tag set present: og:type/title/description/url/image/image:width/image:height + twitter:card(summary_large_image)/title/description/image.
  implication: Two hypotheses eliminated at once — (a) og:image is absolute HTTPS, not relative; (b) the tag is in the server's initial HTML render, NOT injected by LiveView JS after mount, so a non-JS-executing crawler sees it. The og:image is also well within the first 30KB, so no crawler read-budget truncation.

- timestamp: 2026-09-12T04:44:00Z
  checked: `curl -I` the literal og:image URL with both a WhatsApp UA and a facebookexternalhit UA
  found: Both return HTTP/1.1 200 OK, `Content-Type: image/webp`, `Content-Length: 43186` (42 KB), `Cache-Control: public, max-age=31536000, immutable`, Server: cloudflare. Zero redirects (num_redirects=0), no auth challenge, no UA-based divergence between the two crawler identities, 0.5s response time.
  implication: Eliminates the reachability/redirect/auth/timeout/size-budget hypotheses AND the "wrong Content-Type" hypothesis — the header correctly and honestly declares image/webp. 42KB is far under every cited WhatsApp size budget (~300KB-600KB). The image is not too big, not too slow, not gated, not redirected.

- timestamp: 2026-09-12T04:44:30Z
  checked: Downloaded the og-card bytes and decoded the RIFF/VP8X container header directly (xxd) to read the real canvas dimensions rather than trusting the declared meta values
  found: Magic `RIFF....WEBPVP8X` — extended WebP. VP8X canvas width-1 = 0x0004af = 1199 → width 1200; canvas height-1 = 0x000275 = 629 → height 630.
  implication: Actual pixel dimensions are EXACTLY 1200x630, matching the declared og:image:width/height literals. The dimension-mismatch hypothesis is eliminated. Every OG contract requirement now verified as satisfied except one property: the image ENCODING FORMAT is WebP.

- timestamp: 2026-09-12T04:47:00Z
  checked: External research — does WhatsApp's link-preview renderer support WebP, and does WhatsApp prefer og:title or <title>?
  found: (a) WhatsApp DOES support WebP as an og:image format alongside JPG/JPEG/PNG — multiple independent sources agree. (b) WhatsApp's precedence is og:title FIRST, falling back to <title> only when og:title is absent; same for og:description -> meta description.
  implication: H1 (WebP unsupported) is substantially WEAKENED. More importantly, (b) turns the user's reported preview TITLE into a discriminating measurement I had been treating as decoration.

- timestamp: 2026-09-12T04:48:00Z
  checked: Re-read the reported symptom against the live tag values. Reported preview title = "Llamaland · PukllayClub"; live og:title = "Llamaland" (no suffix); reported preview body = the bare domain "pukllay.club"; live og:description + meta description = "Descubrí Llamaland, un juego de Cumple encargos, ...".
  found: The preview WhatsApp rendered used the `<title>` element (WITH the " · PukllayClub" suffix), not og:title, AND showed no description at all despite og:description and meta description both being present and populated.
  implication: MAJOR REDIRECT. WhatsApp did not merely fail to load the image — it did not use the Open Graph block AT ALL. Since WhatsApp prefers og:title when present, a fresh fetch of current production would have rendered "Llamaland" and the Spanish description. This REFUTES H1 outright: an image-format failure cannot explain a wrong title and a missing description. Whatever WhatsApp rendered came from a page state that had NO og tags and NO meta description.

- timestamp: 2026-09-12T04:49:00Z
  checked: Full `<head>` as served to a WhatsApp UA, read whole (not grepped) — looking for malformed markup that could break a lightweight parser before it reaches the og block
  found: Head is well-formed. Order: charset, viewport, csrf-token, <title>, meta description, canonical, the 7 og:* tags, the 4 twitter:* tags, THEN the two JSON-LD <script> blocks, then stylesheet/JS. Every og tag sits within the first ~2KB of the document. No unclosed tags, no stray characters, no content before <head>.
  implication: Eliminates "malformed head breaks the parser" and "og tags beyond the crawler's read budget". A conforming HTML parser reaches og:image trivially. (`phx-r` is a legitimate, deliberate production attribute — config/config.exs sets `root_tag_attribute: "phx-r"` for LiveView colocated-CSS scoping — not a dev-mode leak; config/dev.exs's debug_heex_annotations/debug_attributes are separate and dev-only.)

- timestamp: 2026-09-12T04:51:00Z
  checked: `git show 1cb2708~1:lib/pukllay_club_web/components/layouts/root.html.heex` — the production `<head>` immediately BEFORE phase 01.8 added any SEO tags
  found: The pre-01.8 head contained EXACTLY five things: charset, viewport, csrf-token, `<.live_title default="PukllayClub" suffix=" · PukllayClub">`, and the stylesheet/2 script tags. NO meta description. NO og:* tags. NO twitter:* tags. NO canonical.
  implication: DECISIVE. A WhatsApp preview generated against that page state would render (1) title "Llamaland · PukllayClub" — the live_title suffix, the ONLY title source available; (2) no description text, so WhatsApp falls back to displaying the bare domain "pukllay.club"; (3) no image whatsoever. That is a field-for-field, three-for-three EXACT match to the reported symptom — and each of the three is individually INCONSISTENT with a fresh fetch of current production. The preview the user saw was generated from the pre-01.8 page.

- timestamp: 2026-09-12T04:52:00Z
  checked: Timeline reconstruction from git dates, R2 object Last-Modified, and the UAT record
  found: 01.8-01's OG tags committed 2026-09-11 22:42/22:50 -0300 (= 2026-09-12 01:42/01:50 UTC). og-card.webp R2 objects created 2026-09-12 02:37:09 UTC (Last-Modified header). og-fallback.webp committed 03:25 UTC. STATE.md records 01.8-05 complete at 03:32 UTC, so UAT test 3 ran after that. Phase 01.7 (2026-09-11) had already restored production's real ~434-game catalog, so /juegos/221 rendered real "Llamaland" content BEFORE 01.8's tags existed. STATE.md 01.7 notes describe the site as a "passed-around link", and the footer carries a WhatsApp social link.
  implication: There was a real window on 2026-09-11 in which /juegos/221 was live in production, rendered "Llamaland · PukllayClub", and carried zero other metadata — precisely the state that produces the reported preview. Any WhatsApp share of that URL during that window cached this preview. WhatsApp caches previews per exact URL for days-to-weeks and Meta publishes no invalidation tool.

- timestamp: 2026-09-12T04:53:00Z
  checked: Why Facebook Sharing Debugger / Twitter Card Validator / Google Rich Results all PASSED on the same URL in the same session
  found: The Facebook Sharing Debugger explicitly re-scrapes and refreshes Meta's cache on demand (that is its purpose), as does Twitter's validator; Google's Rich Results Test validates JSON-LD structured data and does not evaluate og:image at all. WhatsApp's in-app preview has NO equivalent cache-bypass or re-scrape mechanism.
  implication: The three passing validators and the one failing surface differ in EXACTLY one property — whether the fetch bypassed a cache. This fully explains the "passed everywhere else, failed only on WhatsApp" pattern WITHOUT requiring any defect in the OG tags, which independent server-side verification has already shown to be correct on every mechanical dimension.

## Update 2026-09-12: H1 refuted, H2 confirmed

- timestamp: 2026-09-12T05:10:00Z
  checked: Human falsification test — shared https://pukllay.club/juegos/221?v=2 (never-before-cached URL) in WhatsApp
  found: Cover art still absent. User: "No, doesn't show on WhatsApp."
  implication: H1 (stale cache) is REFUTED — a virgin URL cannot have a stale cache entry. Per reasoning_checkpoint.falsification_test, the surviving candidate is H2 (phx-r attribute defeating WhatsApp's meta parser).

- timestamp: 2026-09-12T05:12:00Z
  checked: `curl -A "WhatsApp/2.23.20.0 A" https://pukllay.club/juegos/221` re-run and grepped for the literal served markup
  found: Every og/twitter meta tag is rendered as `<meta phx-r property="og:image" content="...">` (phx-r as the FIRST attribute, before property=), confirmed for og:type/title/description/url/image/image:width/image:height.
  implication: H2 CONFIRMED as the root cause. `config/config.exs:31` sets `root_tag_attribute: "phx-r"` for Phoenix.LiveView.ColocatedCSS, which stamps `phx-r` onto every root-level tag emitted by a HEEx template. `seo_tags.ex`'s `seo_tags/1` component renders 13 sibling `<meta>`/`<link>` tags with no wrapping element, so each one is individually a template root and gets phx-r injected. This project already hit this exact pattern once: 01.8-05-SUMMARY.md records a test regex anchored on `<meta property="og:image" content="..."` matching zero occurrences for the identical reason, and switched to a property-order-agnostic regex — a test-only workaround that left the production markup itself unchanged. WhatsApp's link-preview crawler does not tolerate the interposed attribute (Facebook's and Twitter's crawlers do, and Google's Rich Results Test doesn't evaluate og:image at all), which fully explains "passes everywhere except WhatsApp."

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: |
  CONFIRMED: Phoenix LiveView's root_tag_attribute config ("phx-r", set in config/config.exs:31 for
  Phoenix.LiveView.ColocatedCSS) stamps a phx-r="..." attribute as the FIRST attribute on every
  root-level tag emitted by a HEEx template. lib/pukllay_club_web/components/seo_tags.ex's seo_tags/1
  renders 13 sibling <meta>/<link> tags with no wrapping element, so each is individually a template
  root, producing `<meta phx-r property="og:image" content="...">` in the actual served HTML.
  WhatsApp's link-preview crawler cannot parse this (interposed attribute before property=), while
  Facebook Sharing Debugger and Twitter Card Validator both parse it correctly and Google Rich Results
  Test doesn't evaluate og:image at all — explaining the "passes everywhere except WhatsApp" pattern.
  H1 (stale cache) was refuted by a human test on a cache-busted, never-before-seen URL
  (https://pukllay.club/juegos/221?v=2) that still failed to show the image.

  AND-gate: NO. phx-r attribute ordering alone fully explains all three original symptom fields
  (wrong title, missing description, missing image) since it prevents WhatsApp from reading ANY
  og:*/twitter:* tag, not just og:image.

fix: |
  Not applied — goal was find_root_cause_only. Recommended direction:
  (1) PRIMARY FIX: prevent phx-r from being injected into the SEO/OG/Twitter <meta>/<link> tags in
      seo_tags.ex — e.g. wrap the tags in a container so they are no longer individual template roots,
      or otherwise suppress root-tag stamping for this component — so property=/name= is not preceded
      by phx-r in the served markup. Re-verify via curl with a WhatsApp UA that the tags read
      `<meta property="..." ...>` with no interposed attribute, then re-test a real WhatsApp share on
      a fresh cache-busted URL.
  (2) LATENT GAP (separate, non-blocking): add a JPEG og-card variant — both og:image paths are
      WebP-only (OgCard @object_name "og-card.webp", SEO @og_fallback_path "/images/og-fallback.webp").
  (3) PRODUCTION RISK (separate, non-blocking): og:image is served from the Cloudflare pub-*.r2.dev
      DEVELOPMENT URL, which Cloudflare documents as not for production. Move the image origin to a
      custom domain.
  (4) RECURRENCE GUARD (process): this phase's social verification used only cache-bypassing/tolerant
      validators, which structurally cannot detect a strict-parser failure like WhatsApp's. Any future
      OG/meta change should include a raw curl check with a WhatsApp UA, not just Facebook/Twitter/Google
      validators.

verification: Human-confirmed on a cache-busted URL that the fix is still needed (image absent). The
  primary fix itself is NOT yet applied or verified.
files_changed: []
