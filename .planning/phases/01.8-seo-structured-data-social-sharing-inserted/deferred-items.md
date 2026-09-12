# Deferred Items — Phase 01.8

Out-of-scope discoveries logged during plan execution, per the executor's
scope-boundary rule (only auto-fix issues directly caused by the current
task's changes).

## Pre-existing async-DB-pollution flakiness in `catalog_live_test.exs` / `catalog_show_test.exs`

**Found during:** 01.8-01, Task 1 and Task 2 verification.

**Symptom:** Running `mix test test/pukllay_club_web/live/catalog_live_test.exs`
and/or `catalog_show_test.exs` in isolation intermittently fails 4-9 tests
(counts vary run to run), e.g.:

- `card_count(html) == 1` returns `3`
- `"0 juegos encontrados"` not found
- `"Otros juegos del mismo nivel: Nivel experto"` not found
- `refute html =~ "Ampliado"` fails
- `refute html =~ "pk-difficulty"` fails

**Root cause (not investigated further — out of this plan's scope):** appears
to be cross-test fixture/DB-sandbox pollution under `async: true` — likely
`csv_row`/similar-games queries picking up rows seeded by a concurrently
running test in the same sandbox, not anything this plan's CSP/SEO changes
touch.

**Confirmed pre-existing, not a regression from this plan:** verified by
running the identical test files (same `--seed`) against a clean
`git worktree` checked out at this plan's pre-execution HEAD
(`861bed65e510bd950c4e5d592a119a043d54f3cf`) — the same test names fail with
the same counts on unmodified code. Full-suite `mix test` also matches
exactly: 933 tests/26 failures on baseline vs. 939 tests/26 failures on this
plan's branch (the 6 new tests are this plan's `game_seo_test.exs`, all
passing).

**Action:** not fixed — out of scope for this plan. Worth a dedicated
debug/quick-task pass whenever `catalog_live_test.exs`/`catalog_show_test.exs`
async isolation is next touched.

## `og:image` has no non-WebP variant (latent finding, G-01.8-3 debug session)

**Found during:** `.planning/debug/whatsapp-og-image-preview.md` (2026-09-12), while diagnosing
G-01.8-3's WhatsApp cover-art failure.

**Symptom:** Both `og:image` code paths — `OgCard`'s per-game object (`og-card.webp`) and `SEO`'s
branded fallback (`og-fallback.webp`) — terminate in WebP with no non-WebP escape hatch. Every
page on the site emits a WebP `og:image`.

**Root cause:** D-08's batch-backfill artifact and `SEO.@og_fallback_path` were both authored
WebP-only; no JPEG/PNG variant was ever produced.

**Action:** deferred, not implemented in this plan. Adding a JPEG variant is a new decision, not a
defect fix — it goes beyond D-08's single-artifact batch backfill and would require re-running the
backfill across the ~385 cover-having games plus deciding multi-value `og:image` precedence.
**Explicitly did NOT contribute to G-01.8-3**: the debug session confirmed WhatsApp does support
WebP as an `og:image` format, and the served image independently verified as HTTP 200,
`image/webp`, 42 KB, and exactly 1200x630 decoded (VP8X container header).

## `og:image` served from Cloudflare R2's development `pub-*.r2.dev` origin (latent finding, G-01.8-3 debug session)

**Found during:** `.planning/debug/whatsapp-og-image-preview.md` (2026-09-12), while diagnosing
G-01.8-3's WhatsApp cover-art failure.

**Symptom:** `og:image` values resolve to `https://pub-<hash>.r2.dev/...`, Cloudflare's development
bucket URL, which Cloudflare documents as unsuitable for production — rate-limited and excluded
from edge caching. A shared link is exactly the crawler-burst traffic pattern most likely to trip
that.

**Root cause:** `OgCard.url_for/1` derives its object URL directly from the game's stored absolute
`cover_url`, which was seeded pointing at the R2 dev origin; no custom domain was ever configured
on the bucket.

**Action:** deferred, not implemented in this plan. Needs Cloudflare dashboard configuration (a
custom domain on the bucket, plus DNS) and a resolution path for the absolute `cover_url` values
already stored in the database, since `OgCard.url_for/1` derives its object URL from them — a new
decision, not a defect fix. **Explicitly did NOT contribute to G-01.8-3**: the debug session
confirmed the image returned a clean HTTP 200 to both a WhatsApp UA and a `facebookexternalhit` UA
in 0.5s with no throttling.
