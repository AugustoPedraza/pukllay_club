# Codebase Concerns

**Analysis Date:** 2026-08-18

## Tech Debt

**Incomplete Pattern Matching in Weight Classification:**
- Issue: `classify_weight/4` in `lib/mix/tasks/catalog.seed.ex` (lines 114-136) uses a case statement that is not exhaustive over all possible combinations of `true_count` and `resolution` results. A future divergence between the hash-tag count and peso tie-break logic could trigger an unhandled `CaseClauseError`.
- Files: `lib/mix/tasks/catalog.seed.ex`
- Impact: One-time seed task failure if unhandled case appears; task is dev-only and manual, so risk is low but correctness gap is real
- Fix approach: Add a catch-all clause logging the divergence or explicitly document the exhaustiveness guarantee with a comment; add additional test cases for edge conditions

**Error Handling Without Logging:**
- Issue: `CatalogLive.Index.safe_filter_games/1` in `lib/pukllay_club_web/live/catalog_live/index.ex` swallows all exceptions with `rescue _error -> :error`, returning a bare `:error` atom with no logging of what went wrong
- Files: `lib/pukllay_club_web/live/catalog_live/index.ex`
- Impact: Silent failures make debugging production issues harder; users see an empty state but operators have no insight into whether it's a query error, timeout, or data issue
- Fix approach: Add `Logger.error/2` before returning `:error`; include the caught exception and relevant filter parameters for debugging

**Integer Parsing with Exceptions:**
- Issue: `parse_int/1` in `lib/mix/tasks/catalog.seed.ex` raises (via `String.to_integer/1`) on a non-numeric, non-blank CSV cell instead of reporting it as a data quality finding
- Files: `lib/mix/tasks/catalog.seed.ex`
- Impact: Crashes the entire seed run if a single cell contains unexpected data; seed task must be re-run after fixing the CSV
- Fix approach: Wrap `String.to_integer/1` in a try/catch or `Integer.parse/1`, report the error to the `Report` accumulator, and continue with a default/nil value

**Redundant Cover Selection:**
- Issue: `select_cover/1` is called twice per row in `lib/mix/tasks/catalog.seed.ex` — once in `process_row/5` to get the URL and again in `process_gallery/3` to exclude it from gallery candidates
- Files: `lib/mix/tasks/catalog.seed.ex`, `lib/pukllay_club/catalog/seed/image_pipeline.ex`
- Impact: Unnecessary computation and network calls during gallery processing; cosmetic/minor correctness gap
- Fix approach: Cache the result in `process_row/5` and pass it to `process_gallery/3` to avoid recomputation

**Misleading Function Name:**
- Issue: `HashtagNormalizer.truthy?/1` in `lib/pukllay_club/catalog/seed/hashtag_normalizer.ex` has a name that suggests a boolean return (`truthy?`), but actually returns `true`/`false`/`nil` (a tri-state, not binary)
- Files: `lib/pukllay_club/catalog/seed/hashtag_normalizer.ex`
- Impact: Function name invites misuse as a boolean predicate; callers might treat `nil` as falsy when they should explicitly check
- Fix approach: Rename to `parse_hashtag_value/1` or add a docstring clarifying the tri-state return; update all call sites

## Known Issues

**Sort Dropdown Overlaps Filter Trigger (Blocker):**
- Symptoms: The sort dropdown on `CatalogLive.Index` renders above the "Filtros" button and intercepts clicks meant for the button
- Files: `lib/pukllay_club_web/live/catalog_live/index.ex`, `lib/pukllay_club_web/components/*`
- Trigger: Open the browse page, click sort dropdown to open it, then attempt to click the "Filtros" button — the dropdown blocks the click
- Workaround: Close the sort dropdown before opening the filter drawer
- Recommendation: Add `z-index` layering or reposition dropdown to not overlap the filter button; marked blocker in STATE.md pending todos

**Inadequate Touch Targets (Major × 2):**
- Symptoms:
  1. "Ver detalles" card CTA button on game cards measures 28px vertically instead of the 44px minimum recommended (affects 183 elements)
  2. Theme toggle (light/dark) in top-right measures 32px, below the 44px minimum
- Files: `lib/pukllay_club_web/components/game_card.ex`, `lib/pukllay_club_web/components/layouts.ex`
- Impact: Mobile users cannot reliably tap the buttons; accessibility violation (WCAG AA)
- Recommendation: Increase padding/height to 44px minimum; adjust surrounding spacing if needed

**Missing Accessible Names (Major):**
- Symptoms: Theme toggle button has no `aria-label` and no text content, only an icon
- Files: `lib/pukllay_club_web/components/layouts.ex`
- Impact: Screen reader users cannot understand button purpose
- Recommendation: Add `aria-label="Cambiar tema"` or equivalent; consider adding visible text alternative for low-vision users

**Font Combination Inconsistency (Minor):**
- Symptoms: The catalog browse page uses 10 different font weight/family combinations instead of the designed limit of 3
- Files: `lib/pukllay_club_web/components/*`, `assets/css/app.css`
- Impact: Visual inconsistency; harder to maintain design system
- Recommendation: Audit and consolidate to 3 designed combinations; enforce via component-level defaults

**Button Styling Fragmentation (Minor):**
- Symptoms: 184 elements share `.btn-primary` class but there is no secondary button tier for tertiary actions
- Files: `assets/css/app.css`, `lib/pukllay_club_web/components/*`
- Impact: All buttons look equally important; no visual hierarchy for secondary/tertiary actions
- Recommendation: Define `.btn-secondary` and `.btn-tertiary` classes; audit page for which buttons should use them

**Brand Style Violations (Cosmetic):**
- Symptoms:
  1. Brand tagline uses `text-[10px]` and `text-base-content/70` opacity, which violates the UI-SPEC.md ban on arbitrary Tailwind values
  2. Brand logo link measures 42px instead of 44px minimum
- Files: `lib/pukllay_club_web/components/layouts.ex`
- Impact: Inconsistent design system enforcement; tiny text may be unreadable on small screens
- Recommendation: Replace arbitrary values with design-system tokens; increase logo link to 44px

## Security Considerations

**Bare Scheme Sources in CSP (Low-Risk, Reviewed):**
- Risk: CSP header includes `connect-src 'self' ws: wss:` (bare scheme sources), which is broader than necessary
- Files: `lib/pukllay_club_web/csp.ex`
- Current mitigation: This is a known reviewed decision (WR-04 in 01-REVIEW.md), accepted as low-risk for a single-tenant host with no sensitive data transmission over WebSocket; documented in code comments
- Recommendations: For multi-tenant or shared infrastructure, tighten to `connect-src 'self' wss://pukllay.club`; revisit if Phase 2 introduces real-time features via WebSocket

**Database Connection TLS Disabled (Accepted Risk):**
- Risk: App-to-database traffic runs unencrypted over the Docker bridge network (WR-04 in 00-REVIEW.md)
- Files: `config/runtime.exs` (lines 117-126)
- Current mitigation: Accepted as low-risk for a single-tenant host where the accessory is bound to `127.0.0.1:5432` and traffic never leaves the host; documented in code
- Recommendations: If multi-tenant or shared host is ever introduced, enable `ssl: true` with a self-signed certificate in the accessory; document the trade-off

## Performance Bottlenecks

**Unknown Embedding Runtime Performance (Phase 2 Blocker):**
- Problem: Local CPU embedding inference (Bumblebee + EXLA) latency/throughput is unmeasured on the actual production host
- Files: Not yet implemented; risk identified in research phase for Phase 2
- Cause: Original design assumed Hetzner CAX31 (ARM, 8 vCPU/16GB RAM); Phase 0 pivot to GCP e2-micro (x86_64, 2 vCPU shared/1GB RAM) during execution — 1GB RAM is likely inadequate for model loading + inference
- Improvement path: Phase 2 must include an explicit spike to measure embedding latency/memory on the actual GCP e2-micro box; fallback to remote Gemini embeddings API (documented in CLAUDE.md Alternatives) if local inference proves too slow or OOM-prone

## Fragile Areas

**Seed Pipeline Error Resilience:**
- Files: `lib/mix/tasks/catalog.seed.ex`, `lib/pukllay_club/catalog/seed/*`
- Why fragile: The seed task is the single import path for the entire catalog. Network errors (BGG API rate limiting, R2 upload failures) are retried with exponential backoff (BggClient) and per-image error handling (ImagePipeline), but a failure at any step requires manual intervention and a full re-run
- Safe modification: Add comprehensive error reporting to `priv/repo/seed_data/catalog_seed_report.md` so partial failures can be resumed; consider breaking the task into smaller re-runnable steps (parse CSV, fetch BGG, process images, write DB) so a failure does not require re-fetching the entire catalog
- Test coverage: `test/pukllay_club/catalog/seed/` has 12 test files covering BggClient retries, ImagePipeline download caps, and R2 idempotency; no integration test for multi-step failure recovery

**Query Composition Robustness:**
- Files: `lib/pukllay_club/catalog.ex` (lines 186-251)
- Why fragile: `filter_games/1` composes 8 `maybe_*` filter functions via a pipeline; adding a new filter requires adding a function and updating the `base_filtered_query/2` call site — easy to forget the update and silently skip the new filter
- Safe modification: Add a test case for each new filter; consider centralizing filter metadata in a module attribute rather than spreading it across function clauses
- Test coverage: `test/pukllay_club/catalog_test.exs` includes tests for each filter in isolation and in combination (34 tests); no regression test for "new filter not applied" scenarios

**Database Migration Safety:**
- Files: `priv/repo/migrations/`
- Why fragile: The `:search_vector` column is `GENERATED ALWAYS` (read-only from the app); upserts must exclude it via `on_conflict: {:replace_all_except, [:id, :inserted_at, :search_vector]}`, or Postgres raises an error. Future migrations adding more GENERATED columns or constraints could introduce silent failures
- Safe modification: Document the `on_conflict` pattern in comments; add a test upsert for the edge case of re-running the full seed
- Test coverage: `test/pukllay_club/catalog_test.exs` includes tests for `upsert_game!/1` with real seeded data; schema is tested

## Scaling Limits

**Catalog Seed Memory and Time:**
- Current capacity: 434 games, seeded in ~10 minutes locally (estimation from Phase 1 completion)
- Limit: Memory limit is the 15 MB per-image download cap (enforced in ImagePipeline); time limit is BGG API rate limits (20 ids/request, 2 req/sec practical limit, ~1500ms inter-request delay)
- Scaling path: Batching is already maxed out at the BGG API's practical limit; memory is capped; time scales linearly with game count. At 1000 games, expect ~30 min seed time. Optimize image processing (multithreading, skipping unchanged images) if this becomes a bottleneck

**Production Database Accessory:**
- Current capacity: Single Postgres 17 container on the GCP e2-micro host with 1GB RAM
- Limit: Shared RAM with app container; under high concurrent search load with complex queries (faceted search + full-text) could cause OOM or query timeouts
- Scaling path: Monitor `pg_stat_statements` and query execution time during Phase 2 real-world usage; if needed, upgrade host or scale to a managed Postgres service (Neon, Supabase, etc.)

**R2 Storage Requests:**
- Current capacity: ~868 image objects (434 games × 2 variants per cover + 3 per game gallery = ~2603 objects). R2 has no rate limit for the free tier, but egress charges apply
- Limit: egress charges at $0.20/GB; at 0.5 MB per image = ~$260 total egress cost for full catalog at current rate (high risk if image delivery is not optimized)
- Scaling path: Use R2's cache API or a Cloudflare Worker to cache images in local edge nodes; or mirror images to a cheaper CDN if egress cost becomes a problem; cache control headers are already set to `immutable` (365 days)

## Dependencies at Risk

**Postgrex Release Candidate (Documented):**
- Risk: `mix.exs` pins `{:postgrex, ">= 0.0.0"}` which currently resolves to the latest `0.22.x`, but `1.0.0-rc.1` exists and could be auto-selected in a future `mix deps.update` run
- Impact: RC versions can still change behavior before final release; production stability risk
- Migration plan: Explicit `{:postgrex, "~> 0.22"}` pin recommended until `1.0.0` final is released and tested

**Elixir Version Compatibility:**
- Risk: `mix.exs` pins `elixir: "~> 1.17"` but CLAUDE.md recommends `1.19.x`; this creates a gap if a developer runs an older `1.17.x` and misses a new feature or bug fix
- Impact: Inconsistent behavior between dev and CI/production
- Migration plan: Update to `elixir: "~> 1.19"` and pin `otp: "28.x"` in `mise.toml` or similar to enforce consistency

**Sentry Configuration (No Verification Test):**
- Risk: Sentry error reporting is wired in `application.ex` but there is no test that verifies it actually sends an error to Sentry (tests mock or stub Sentry)
- Impact: Silent configuration drift; errors might not be reported in production
- Migration plan: Add an integration test or a separate CI job that verifies Sentry can receive a test event

## Missing Critical Features

**No Graceful Handling of Image Upload Failure:**
- Problem: If R2 upload fails during seed, the game is inserted into the database but without cover image URLs, resulting in broken image references on the frontend. The report documents upload failures but does not block the seed
- Blocks: Phase 1 is complete and live; Phase 2 queries depend on valid image URLs
- Recommendation: Decide whether to retry failed uploads, mark games as `:incomplete`, or fail the entire seed on upload errors; document the policy in the seed task

**No Real-Time Inventory Sync:**
- Problem: The `units` column is seeded but never decremented when games are borrowed (Phase 4 work); live page shows stale counts
- Blocks: Phase 4 rental tracking is deferred
- Recommendation: Phase 2-3 should plan how to expose `units` on the detail page (if needed) before Phase 4 borrow/return logic

## Test Coverage Gaps

**Edge Cases in Weight Band Resolution:**
- What's not tested: The `classify_weight/4` case exhaustiveness gap (WR-01) is not covered by a test that explicitly exercises all four branches
- Files: `lib/mix/tasks/catalog.seed.ex`
- Risk: Silent failures if logic diverges; one-time seed task so production impact is low but development risk is real
- Priority: Medium (one-time task, dev-only)

**Filter Composition at Boundary Values:**
- What's not tested: Filters with edge-case inputs (empty arrays, `nil` mixing with values, boundary numbers like 0 or 999)
- Files: `lib/pukllay_club/catalog.ex`
- Risk: Undetected query bugs; low risk since the most common queries are well-tested
- Priority: Low (existing tests cover the happy path and basic combinations)

**CSP Header Validation in All Environments:**
- What's not tested: CSP header is asserted in unit tests (dev environment) but there is no test that verifies CSP headers are actually present in production or staging deploys
- Files: `test/pukllay_club_web/live/catalog_live_test.exs`
- Risk: CSP could be accidentally removed during a production deployment without test failure
- Priority: Low (CSP is verified via 01-VERIFICATION.md manual check on production; monitoring during Phase 2 is recommended)

---

*Concerns audit: 2026-08-18*
