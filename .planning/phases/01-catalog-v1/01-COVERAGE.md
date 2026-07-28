# Phase 1 — External API Coverage Decision Matrix

**Produced:** 2026-07-28 (plan-phase)
**Gate:** `api-coverage.verify-pre` — a malformed/partial matrix blocks the phase seal.
**Rule:** Full coverage by default. Every capability starts as `INTEGRATE`; every `OPT-OUT` carries
a one-line reason. Rows are never omitted — an un-enumerated capability is an invisible hole.

External services integrated this phase:

1. **BoardGameGeek XML API 2** (`https://boardgamegeek.com/xmlapi2/…`) — one-time enrichment
   (D-01/D-02). Requires a registered application + `Authorization: Bearer <token>` since
   2025-07-02 (01-RESEARCH.md Pitfall 1).
2. **Cloudflare R2** (S3-compatible, via `ex_aws_s3`) — club-owned resized image hosting
   (D-03/D-04, CATALOG-09).

---

## 1. BoardGameGeek XML API 2

### 1a. `/xmlapi2/thing` — capability surface (parameter-level)

| Capability | Decision | Rationale |
|-----------|----------|-----------|
| `id=` batched multi-id lookup (comma-separated, ≤20 per request) | **INTEGRATE** | The whole enrichment path is id-keyed off the CSV's `BGG_ID` column (D-01/D-17). Batching is also the primary rate-limit lever (Pitfall 2). |
| `type=boardgame` filter | **INTEGRATE** | Guards against an id resolving to a `boardgameexpansion`/`videogame` object. |
| `stats=1` → `averageweight`, `average`, `usersrated`, `bayesaverage`, `ranks` | **INTEGRATE** | `averageweight` is persisted in the raw payload (D-17 "persist the fuller fetched payload"). Weight-band assignment itself is CSV-hashtag-driven (D-05/Pitfall 3), not derived from this field. |
| Core `thing` scalars: `minplayers`, `maxplayers`, `minplaytime`, `maxplaytime`, `playingtime`, `minage`, `yearpublished` | **INTEGRATE** | Directly power CATALOG-02 (player count / playtime / min age filters) and CATALOG-04 (sort). |
| `link[@type='boardgamemechanic']` | **INTEGRATE** | Canonical source for `mechanics` (CATALOG-02 facet, CATALOG-06 chips). |
| `link[@type='boardgamecategory']` | **INTEGRATE** | Canonical source for `themes` (CATALOG-02 facet, CATALOG-06 chips). The CSV `Categorias` column is unusable at 1/434 fill (D-17). |
| `link[@type='boardgamedesigner']` | **INTEGRATE** | Required by CATALOG-03 (keyword search over designer). |
| `link[@type='boardgamepublisher']` | **INTEGRATE** | Required by CATALOG-03 (keyword search over publisher). |
| `link[@type='boardgamefamily']`, `boardgameartist`, `boardgameimplementation`, `boardgameexpansion` | **INTEGRATE** | Zero marginal cost — they arrive in the same response. Persisted into `bgg_payload` (jsonb) per D-17 so a later phase never re-runs the one-time pipeline to backfill. Not surfaced in Phase 1 UI. |
| `description` (long HTML-ish blurb) | **INTEGRATE** | Same response, zero extra call. Persisted; Phase 1 renders it on the detail page only. |
| `image` / `thumbnail` elements | **INTEGRATE** | Source of the cover art that gets downloaded, resized to two variants, and re-hosted on R2 (D-03, CATALOG-09). |
| `versions=1` → per-edition `<item type="boardgameversion">` with its own `image`/`thumbnail` and `link[@type='language']` | **INTEGRATE** | The **only** documented XMLAPI2 surface exposing language-specific box art. Serves D-04's "cover art must match the owned language edition, Spanish preferred" AND supplies the small gallery. See the Constraint note below. |
| `videos=1` | **OPT-OUT** | Phase 1 renders no video; catalog is image-forward per D-08/UI-SPEC. |
| `comments=1` / `ratingcomments=1` | **OPT-OUT** | REQUIREMENTS.md "Out of Scope": BGG-style public ratings/comments are explicitly excluded — they reintroduce the numeric-rating-without-context problem this product exists to avoid. |
| `marketplace=1` | **OPT-OUT** | No commerce surface in any roadmap phase (REQUIREMENTS.md excludes payments). |
| `historical=1` (historical rank/rating series) | **OPT-OUT** | Time-series rank data has no consumer in Phases 1-4 and materially bloats each response, worsening the rate-limit budget. |
| `page` / `pagesize` (paging within comments) | **OPT-OUT** | Only meaningful alongside `comments=1`, which is opted out above. |

### 1b. Other `/xmlapi2/*` endpoints

| Endpoint | Decision | Rationale |
|----------|----------|-----------|
| `/xmlapi2/search` (title → id) | **OPT-OUT** | D-01 is explicit: the CSV carries `BGG_ID` per row, so no title-matching/fuzzy-search step is needed. The 41 rows with no `BGG_ID` (D-18) are confirmed to ship with degraded data, **not** to be resolved by fuzzy title search — that would risk silently attaching the wrong game's data to a club row. |
| `/xmlapi2/hot` (BGG hotness list) | **OPT-OUT** | Carousel rows are a fixed hardcoded set from the club's own editorial hashtags (D-09). BGG-global popularity is not a club editorial signal. |
| `/xmlapi2/collection` (user collection) | **OPT-OUT** | The club's owned-copy inventory is the CSV (`Unidades` column), not a BGG user account. No BGG account maps to the club. |
| `/xmlapi2/user` | **OPT-OUT** | No BGG user identity is modelled; Phase 1 is fully public/no-auth (CATALOG-08) and Phase 2 auth is magic-link, not BGG OAuth. |
| `/xmlapi2/guild` | **OPT-OUT** | The club is not registered as a BGG guild; no data to fetch. |
| `/xmlapi2/plays` | **OPT-OUT** | Play/session logging is not in any v1 requirement (rental tracking in Phase 4 is club-internal, not BGG-sourced). |
| `/xmlapi2/family` | **OPT-OUT** | Family grouping duplicates `link[@type='boardgamefamily']` already captured from `thing`; a second call adds rate-limit cost for no new data. |
| `/xmlapi2/forumlist`, `/forum`, `/thread` | **OPT-OUT** | Forum/community content is out of product scope entirely (REQUIREMENTS.md excludes community/rating surfaces). |
| Image CDN fetch (`cf.geekdo-images.com` URLs returned by `thing`/`versions`) | **INTEGRATE** | Required to download-once and re-host on R2 (CATALOG-09 forbids runtime hotlinking). Downloads are host-allowlisted and size-capped — see the threat register in `01-03-PLAN.md`. |

### Constraint flagged for the developer (not a scope reduction)

BGG XML API 2 exposes **no documented gallery/component-photo endpoint**. The `thing` response
carries exactly one `image` + one `thumbnail`; the website's own photo gallery is served by an
undocumented, unauthenticated-in-flux AJAX JSON route that is not part of the registered-application
XML API surface.

D-04's requested gallery is therefore built from the **documented** `versions=1` surface: primary
cover + up to 3 additional edition/version box images. This satisfies D-04's stated shape (a small
per-game gallery, cover language-matched with Spanish preferred, extras best-effort) using only
supported API surface. "Table setup / component photos" specifically are **not obtainable** from the
documented API — this is a missing-information constraint on BGG's side, recorded here rather than
silently under-delivered. If the developer wants component photos, that is a separate decision about
using an undocumented endpoint and should be raised before Phase 2.

---

## 2. Cloudflare R2 (S3-compatible, via `ex_aws` / `ex_aws_s3`)

| Capability | Decision | Rationale |
|-----------|----------|-----------|
| `put_object` | **INTEGRATE** | Core of D-03: upload both resized variants (and gallery variants) for every game. |
| `head_object` | **INTEGRATE** | Makes the one-time seed task (D-02) safely re-runnable — an already-uploaded key is skipped instead of re-downloaded/re-resized/re-uploaded. |
| `list_objects_v2` | **INTEGRATE** | Powers the seed task's `--verify` reconciliation pass (object count vs. seeded row count) and the manual-review report. |
| `get_object` | **OPT-OUT** | The browser fetches R2 URLs directly; the Phoenix app never proxies image bytes (D-03, and 01-RESEARCH.md's Architectural Responsibility Map puts image serving on the CDN tier). No server-side read path exists. |
| `delete_object` | **OPT-OUT** | Phase 1 has no destructive actions at all (UI-SPEC Copywriting Contract records "Destructive: not applicable"). Image lifecycle/cleanup belongs to Phase 4's admin catalog management (CLUBOPS-03). |
| Presigned URLs (`presigned_url`) | **OPT-OUT** | Images are public, world-readable catalog covers served from a public R2 base URL. Presigning would add per-request signing cost and URL churn for content that has no access-control requirement (CATALOG-08 — the catalog is fully public). |
| Multipart upload (`initiate_multipart_upload` / `upload_part` / `complete_multipart_upload`) | **OPT-OUT** | Both variants are capped well under 5 MB (thumbnail ≤300 px, detail ≤800 px, WebP). Multipart is only required above 5 GB and only beneficial above ~100 MB. |
| `put_object_acl` / object-level ACLs | **OPT-OUT** | R2 does not implement per-object ACLs; public read is granted at the bucket level (r2.dev subdomain or custom domain), configured once by hand — see `user_setup` in `01-01-PLAN.md`. |
| Bucket CORS config (`put_bucket_cors`) | **OPT-OUT** | `<img src>` fetches are not CORS-gated. No canvas/`fetch()` reads of image bytes exist in Phase 1. |
| Bucket lifecycle / versioning config | **OPT-OUT** | One-time seed writes immutable, content-addressed-by-`bgg_id` keys. No expiry or version-history requirement; nightly `pg_dump` → R2 (DEPLOY-04) already covers the durability story for the data that references these keys. |
| Bucket creation | **OPT-OUT (human)** | Performed once in the Cloudflare dashboard by the developer as part of the `01-01-PLAN.md` `checkpoint:human-action`, together with enabling public read access. Not automated — it is a one-time account-level action with billing implications. |

---

## Seal-time checklist

- [ ] Every `INTEGRATE` row above has a corresponding implementation in a Phase 1 plan
      (`01-03-PLAN.md` for the tracer subset, `01-04-PLAN.md` for the full surface).
- [ ] Every `OPT-OUT` row carries a reason (verified above — no bare omissions).
- [ ] The `versions=1` gallery constraint note has been read by the developer.
