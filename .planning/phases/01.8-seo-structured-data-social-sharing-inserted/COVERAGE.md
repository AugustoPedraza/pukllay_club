# Phase 01.8 — API Coverage

**Generated:** 2026-09-12 (end-of-phase UAT, `verify:pre` api-coverage gate)
**Gate:** `workflow.api_coverage_gate = true`

## Detector Result

The detector fired, and it is correct: this phase is not purely presentational. Plan 01.8-04
added a real write path to **Cloudflare R2's S3-compatible API** — `mix catalog.backfill_og_cards`
letterboxes every game's stored cover onto a 1200x630 brand canvas and uploads it as
`<key>/og-card.webp`, so social crawlers have a card image to fetch.

## Scope Scanned

Plans 01.8-01 → 01.8-07. The external-surface-bearing files are:

| File | Nature of change |
|------|------------------|
| `lib/pukllay_club/catalog/seed/r2_storage.ex` | `list_keys/2` paginated past S3/R2's 1000-key page cap (`befe7e9`) |
| `lib/pukllay_club/catalog/seed/og_card_backfill.ex` | New — batch iterator calling `Storage.impl().put/4` per game |
| `lib/mix/tasks/catalog.backfill_og_cards.ex` | New — Mix task wrapper, `--dry-run` |
| `lib/pukllay_club/catalog/seed/image_pipeline.ex` | New `og_card/1` transform; outbound HTTPS GET of the stored cover |
| `lib/pukllay_club/catalog/og_card.ex` | Object key/URL derivation (no I/O) |

Every other file in the phase (`seo_tags.ex`, `seo.ex`, the `game_seo`/`site_seo` plugs,
`sitemap_controller.ex`, `csp.ex`, `robots.txt`, `root.html.heex`) only *renders* markup or
*serves* responses. Facebook's Sharing Debugger, Twitter's Card Validator, Google's Rich Results
Test and WhatsApp's link-preview crawler all appear in this phase's UAT as **inbound** crawlers
and human-driven web tools — we expose markup to them, we never call their APIs.
`test/production/og_tags_whatsapp_ua.mjs` fetches **our own** production host with a WhatsApp
user-agent string; it is a self-test oracle, not a third-party integration.

## Coverage Matrix

Surface: Cloudflare R2, reached two ways — the S3-compatible API via `ex_aws_s3` (credentialed,
`<account>.r2.cloudflarestorage.com`) and the public bucket origin over plain HTTPS
(uncredentialed, the `:image_origin` host).

| capability | decision | reason |
|---|---|---|
| R2 S3 PutObject — write og-card.webp | INTEGRATE | Core of SHARE-03; writes image/webp with a one-year immutable Cache-Control |
| R2 S3 HeadObject — pre-upload existence check | INTEGRATE | Makes the backfill idempotent (D-02); an existing key returns its URL unchanged |
| R2 S3 ListObjectsV2 + continuation pagination | INTEGRATE | Implements the behaviour's "every key under prefix" contract; 01.8-04 fixed the 1000-key truncation |
| R2 public-origin HTTPS GET — read a stored cover | INTEGRATE | ImagePipeline.og_card/1 fetches the game's own cover-large.webp as the letterbox source |
| R2 S3 GetObject — credentialed read | OPT-OUT | Reads go through the public origin instead, keeping R2 secrets off the read path entirely |
| R2 S3 DeleteObject | OPT-OUT | T-01.8-17 accepted: og-cards are immutable; revising the canvas needs a deliberate manual purge, not app code |
| R2 S3 CopyObject | OPT-OUT | Every og-card is generated from its source cover; no server-side copy or rename path exists |
| R2 S3 multipart upload | OPT-OUT | An og-card is well under 1 MB, far below the single-PUT ceiling; multipart would add failure modes for no gain |
| R2 S3 presigned URLs | OPT-OUT | The catalog bucket is public-read via its own origin, so no signed-URL handoff is needed |
| R2 S3 bucket lifecycle, CORS and versioning config | OPT-OUT | Provisioned once by hand in the Cloudflare dashboard; app code must not mutate bucket-level config |
| Cloudflare REST management API — buckets, tokens, domains | OPT-OUT | Infrastructure provisioning is a Kamal/dashboard concern, deliberately outside the release image |
| BoardGameGeek XML API v2 | OPT-OUT | 01.8 reads only the already-seeded cover_url; it adds no BGG call and needs no new BGG data |
| Google Gemini API | OPT-OUT | Optional credential for the one-off 01.3-03 translation task; untouched by every plan in this phase |

**Counts:** 13 capabilities — 4 INTEGRATE, 9 OPT-OUT.

## Known Residue

Two R2-related items were found during this phase and recorded in `deferred-items.md` rather
than fixed. Neither is a coverage gap; both are logged here so the matrix and the deferrals agree:

- `og:image` is WebP-only, with no JPEG/PNG fallback for consumers that cannot decode WebP.
- `og:image` is served from Cloudflare's `pub-*.r2.dev` development URL, which Cloudflare
  documents as unsuitable for production (rate-limited, excluded from edge caching). A custom
  domain on the bucket is the eventual fix.
