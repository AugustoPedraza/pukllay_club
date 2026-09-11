---
gsd_state_version: 1.0
milestone: v1.0
current_phase: 02
current_phase_name: Natural-Language Spanish Search + Auth
status: planning
stopped_at: Phase 01.4 complete, ready to plan Phase 02
last_updated: "2026-09-07T19:05:24.168Z"
last_activity: 2026-09-07
last_activity_desc: Phase 01.4 complete, transitioned to Phase 02
state_head: 68d16b58caeccc931c1a03f7cd0a4ad90a46bc43
progress:
  total_phases: 9
  completed_phases: 6
  total_plans: 73
  completed_plans: 73
milestone_name: milestone
---

Total Phases: 7

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-07)

**Core value:** A member can describe what they want in plain Spanish and find a game that fits —
even without already knowing board-game vocabulary.
**Current focus:** Phase 02 — Natural-Language Spanish Search + Auth

## Current Position

Phase: 02 — Natural-Language Spanish Search + Auth
Plan: Not started
Status: Ready to plan
Last activity: 2026-09-07 — Phase 01.4 complete, transitioned to Phase 02

Progress: [░░░░░░░░░░░░░░░░░░░░] 73/73 plans (Phase 02 not yet planned)

## Performance Metrics

**Velocity:**

- Total plans completed: 76
- Average duration: - min
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 00 | 6 | - | - |
| 01 | 9 | - | - |
| 01.1 | 9 | - | - |
| 01.2 | 27 | - | - |
| 01.3 | 12 | - | - |
| 01.3.1 | 2 | - | - |
| 01.4 | 11 | - | - |

**Recent Trend:**

- Last 5 plans: none yet
- Trend: -

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 00 P01 | 35min | 3 tasks | 60 files |
| Phase 00 P02 | 5min | 1 tasks | 2 files |
| Phase 00 P03 | 90min | 3 tasks | 3 files |
| Phase 00 P04 | 197min | 3 tasks | 6 files |
| Phase 00 P05 | 50min | 3 tasks | 8 files |
| Phase 00 P06 | 20min | 2 tasks | 1 files |
| Phase 01 P02 | 30min | 3 tasks | 11 files |
| Phase 01 P01 | 63min | 2 tasks | 8 files |
| Phase 01 P03 | 85min | 2 tasks | 24 files |
| Phase 01 P05 | 26min | 3 tasks | 10 files |
| Phase 01 P07 | 35min | 3 tasks | 7 files |
| Phase 01 P09 | 35min | 3 tasks | 7 files |
| Phase 01 P08 | 20min | 3 tasks | 3 files |
| Phase 01 P10 | 55min | 3 tasks | 7 files |
| Phase 01 P11 | 65min | 3 tasks | 6 files |
| Phase 01 P12 | 90min | 3 tasks | 6 files |
| Phase 01.1 P01 | 115min | 3 tasks | 9 files |
| Phase quick-260821-v7q P01 | 35min | 3 tasks | 6 files |
| Phase quick-260824-jkc P01 | 40min | 3 tasks | 4 files |
| Phase 01.2 P01 | 50min | 2 tasks | 7 files |
| Phase 01.2 P02 | 10min | 2 tasks | 2 files |
| Phase 01.2 P03 | 55min | 3 tasks | 3 files |
| Phase 01.2 P04 | 11min | 3 tasks | 2 files |
| Phase 01.2 P05 | 15min | 3 tasks | 3 files |
| Phase 01.2 P11 | 40min | 3 tasks | 5 files |
| Phase 01.2 P13 | 35min | 3 tasks | 3 files |
| Phase 01.2 P12 | 45min | 3 tasks | 5 files |
| Phase 01.2 P14 | 25min | 3 tasks | 5 files |
| Phase 01.2 P15 | 15min | 3 tasks | 4 files |
| Phase 01.3 P02 | 25min | 3 tasks | 1 files |
| Phase 01.3 P04 | 45min | 2 tasks | 2 files |
| Phase quick-260902-glf P01 | 25min | 3 tasks | 4 files |
| Phase 01.4 P06 | 40min | 2 tasks | 3 files |
| Phase 01.4 P07 | 25min | 2 tasks | 3 files |
| Phase 01.4 P08 | 20min | 2 tasks | 3 files |
| Phase 01.4 P09 | 20min | 3 tasks | 5 files |
| Phase 01.4 P10 | 55min | 3 tasks | 4 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Project init: Fixed 5-phase roadmap order (0 Deploy Skeleton -> 1 Catalog -> 2 NL Search+Auth ->
  3 Rules Oracle -> 4 Club Ops), no reordering, later work never pulled forward

- Project init: Elixir/Phoenix 1.8 LiveView, single Postgres DB (pgvector + tsvector), Kamal 2 to a
  single Hetzner CAX31 (ARM), no umbrella, no microservices, no separate vector DB/search/auth
  service

- Project init: Local CPU embeddings (Bumblebee/EXLA) + remote free-tier LLM (Gemini via
  InstructorLite), split so no LLM call ever sits on the request hot path

- [Phase ?]: mise.toml pins elixir 1.19.5-otp-28 / erlang 28.5, matching phx.gen.release's own builder image tag (D-16)
- [Phase ?]: Credo Design.AliasUsage exit_status set to 0 for phx.new-generated boilerplate under --strict; Sobelow Config.CSP explicitly ignored with reviewed rationale (deferred to Phase 1) rather than disabling exit codes wholesale
- [Phase ?]: Sentry.LoggerHandler attached manually via :logger.add_handler/3 with enable_logs: true (not the config-only auto-attach path), keeping the call site explicit in application.ex
- [Phase ?]: AGENTS.md conventions (DEPLOY-05): appended TDD loop, mix quality order, manual-merge-gate rule, and Phase 0 non-goals into the phx.new-generated AGENTS.md rather than overwrite it
- [Phase ?]: D-19: repo flipped private->public during 00-03 execution (explicit user decision) — GitHub Free doesn't support branch protection/rulesets on private repos; verified no secrets in git history or ci.yml before flipping
- [Phase ?]: Branch protection on main requires the 'quality' status check (strict, enforce_admins=true, no bypass) — future plans must land main commits via PR, not direct push, since a required check now blocks bare git push to main
- [Phase ?]: 00-04: Kamal deploy.yml/servers.web and the db accessory host use a placeholder pending 00-05 host provisioning (D-12); webfactory/ssh-agent pinned to v0.9.0 (v0.9 is not a resolvable tag)
- [Phase ?]: 00-05: D-20 executed — GCP e2-micro (x86_64) production host wired into config/deploy.yml + deploy.yml workflow (ssh.user: deploy, builder.arch: amd64, ubuntu-latest runner), superseding the Hetzner CAX31/arm64 assumption
- [Phase ?]: 00-05: kamal setup used once for first-time GCP bootstrap, then switched to kamal deploy --skip-push (D-02 steady state) once confirmed healthy; CI builds+pushes the image directly (docker/build-push-action) and Kamal only pulls the matching git-SHA tag
- [Phase ?]: 00-05: PukllayClub.Release.createdb/0 added as a permanent, idempotent database-bootstrap step (not a one-off manual CREATE DATABASE) since this project has already had to re-provision its production host once this phase
- [Phase ?]: 00-05: DEPLOY-01 and DEPLOY-03 proven live via two checkpoint:human-verify gates — HTTPS+/up+localhost-Postgres, and a real migration shipped through CI->build->Kamal proven to gate zero-downtime cutover (D-06)
- [Phase ?]: 00-06: Nightly backup mechanism = scheduled GitHub Actions over SSH (not host cron/systemd), keeping R2 credentials in GitHub secrets (D-08 pattern); 60-day scheduled-workflow auto-disable risk (D-19) explicitly accepted, no keepalive added
- [Phase ?]: 01-02: daisyUI theme values kept as hex (not oklch) per 01-UI-SPEC.md, preserving traceability to the brand manual
- [Phase ?]: 01-02: info/success/warning -content colors (unspecified by UI-SPEC's 17-var table) converted to brand hex to eliminate all remaining stock oklch values
- [Phase ?]: 01-02: fixed pre-existing invalid 'E' regex modifier in config/runtime.exs live_reload patterns that blocked mix test in every environment (Rule 3 blocking fix)
- [Phase ?]: 01-01: Config key for BGG/R2 seed credentials is PukllayClub.Catalog.Seed (not .Credentials), shared across dev.exs/test.exs/dev.secret.exs.example so future seed modules reuse one config block
- [Phase ?]: 01-01: config/dev.secret.exs routed as dev-machine-only gitignored secret, deliberately not through Kamal, since the seed pipeline never runs on the production host
- [Phase ?]: Quick task 260806-rq8: Wired Styler (adobe/elixir-styler, mix format plugin) + mix_audit into mix quality (7-step: hex.audit, deps.audit, deps.unlock --check-unused, format, credo, sobelow, test); first-run rewrite manually reviewed per hunk, one misplaced comment corrected
- [Phase ?]: 01-03: games.csv_row (not bgg_id) is the upsert conflict target — re-runnable one-time seed task (D-02) and preserves both duplicate-BGG_ID 163412 rows (D-19)
- [Phase ?]: 01-03: ImagePipeline enforces its 15MB download cap via a hand-rolled Req into: accumulator (pinned req has no max_length option) — same T-01-10 mitigation, different mechanism
- [Phase ?]: 01-03: seed modules (R2Storage/BggClient) never read secrets from Application env directly — every call takes an explicit Credentials.t() struct built once by the mix task (T-01-11)
- [Phase ?]: 01-03: GameCard's Ver detalles CTA renders as an inert button, not a link to a not-yet-existing /games/:id route — game detail page is explicit 01-06 scope
- [Phase ?]: 01-05: The 8 D-09 carousel rows include 3 weight-band rows in addition to Destacados/3 editorial hashtags/Recientemente añadidos, resolving an under-specified plan prose against the plan's own artifact list and row-count
- [Phase ?]: 01-05: filter_games/1 composes search+OR-within-facet+AND-across-facets+scalar filters+sort+pagination into one Ecto maybe_* pipeline; sort/facet keys parsed via literal string clauses, never String.to_atom/1
- [Phase ?]: 01-05: loading skeletons use LiveView's disconnected/connected two-phase mount (:loading = not connected?(socket)) rather than simulated async latency, since Catalog reads are synchronous and fast at this row count
- [Phase ?]: Quick task 260818-jpm: extended docs/ux-patterns.md with B28-B32 (Linear/GOV.UK/Shopify-unreachable/Microsoft/NN.g reference points) and section F (LiveView fit, device target ambiguous, not a PWA); WebFetch tool unavailable to executor, substituted curl+HTML-strip for all 12 live fetches, same fetch-then-cite discipline
- [Phase ?]: Quick task 260818-mhl: added usage_rules ~> 1.1 (1.2.7) + igniter ~> 0.6 (0.8.3) as dev-only deps; AGENTS.md is a usage_rules-managed file (mix phx.new-seeded markers) — configured link-mode sync (`file: "AGENTS.md"`, no `skills:` key) so dependency-authored rules (phoenix, igniter) resolve via `deps/<pkg>/usage-rules*.md` links instead of inlining; only usage_rules' own + elixir/otp builtin rules stay inlined; `mix rules.sync` alias added; AGENTS.md shrank 25,492 -> 12,336 bytes (marker-block-only change, hand-written preamble lines 1-95 byte-identical, sha256-verified)
- [Phase ?]: Quick task 260818-n4l: Added excoveralls (0.18.5) + dialyxir (1.4.7) tooling deps; test_coverage/dialyzer config wired via cli/0 preferred_envs (not deprecated project/0 preferred_cli_env); dialyxir only:[:dev,:test] (not [:dev]) so quality.full resolves; PLT deliberately not built; precommit alias converted to check-only flags (deps.unlock --check-unused, format --check-formatted) closing an unattended-executor silent-mutation hole; new quality.full = quality + dialyzer alias added
- [Phase ?]: 01-07: weight_band_badge/1 uses badge-lg h-auto whitespace-normal (releases daisyUI's height pin, the direct G-01-2 cause) + badge-lg size step establishes it as the card's primary tier (G-01-6)
- [Phase ?]: 01-07: editorial_tags/1 gained an optional limit (nil=uncapped) mirroring chip_row/1's take/overflow pattern; card-level cap set to limit={2} since only 3 editorial hashtags exist in the live Vocabulary module
- [Phase ?]: 01-07: G-01-7 double focus ring fixed via focus:outline-hidden focus-within:outline-hidden on select/textarea/catch-all input branches + raw sort select, suppressing only daisyUI's outer offset outline; outline-hidden compiled successfully, no outline-none fallback needed
- [Phase ?]: 01-09: ExpansionClassifier marker list ((expa, expansi, promo) + reviewed csv_row override list 414/415/417/421) is a documented mirror of the add_games_is_expansion migration's SQL backfill — both must change together (G-01-5)
- [Phase ?]: 01-09: recent_query/0 filters is_expansion == false; exclusion deliberately scoped to only that carousel row (filter_games/1, count_games/1, other 7 rows untouched) so club-owned expansions remain searchable
- [Phase ?]: 01-08: CarouselRow gains variant/subtitle (hero colour ranking, no fourth type size) + main-grid section header (G-01-4); 6/8 row subtitles reuse Vocabulary D-05/D-06 copy, 2 newly authored and flagged for review
- [Phase ?]: 01-08: .CarouselScroll colocated hook adds persistent, self-hiding prev/next rail controls (ResizeObserver + scrollWidth/clientWidth), zero app.js/config.exs edits; @carousel_limit stays at 20 per ux-patterns B9's content-rail flip case (G-01-3)
- [Phase 01]: Quick task 260821-dah: closed all 7 2026-08-18 UI audit findings on CatalogLive.Index (filter-drawer overlap, theme-toggle a11y/hit-target, logo/tagline tokens, button.secondary variant, re-measured type inventory at 5 combos/3-tier cap); closes the 01-05-PLAN.md drawer/pills tappability thread, recorded as an addendum in 01-VERIFICATION.md
- [Phase 01.1]: Task 2(a) BGG attribution: 'Powered by BGG' link to boardgamegeek.com with the real logo mark; (b) footer social set revised post-Task-1 to WhatsApp/Facebook/Instagram/Email (linktree_url removed); (c) catalog header nav links replaced with the About page's Inicio/Quiénes Somos wayfinding links
- [Phase 01.1]: Quick task 260821-v7q: assign_new/3 replaces a compile-time isologo? constant so tests can force the wordmark-only fallback branch that becomes unreachable once both real mark PNGs exist on disk; production behaviour byte-identical since no call site passes the key
- [Phase 01.1]: Quick task 260822-2v9: header surface base-200 (matches footer token), brand wrapper flex-1->flex-initial, .pk-nav-actions groups Sumate CTA + theme toggle with margin-left:auto fallback, CTA rises to the toggle's fixed 48px anchor (min-h-12, small-size modifier dropped), CoreComponents.input/1's fieldset wrapper neutralized via header-scoped selector (not the shared component), .pk-nav-links demoted to neutral with a new aria-current active-state rule
- [Phase 2]: Quick task 260824-jkc: shipped sketch 020's winning design — desktop 'Explorar categorías' mega-menu (Layouts.category_menu/1, right-anchored panel, one shared derived shelf list feeding both surfaces) + refined bare-outline/soft-tint mobile chip row; scroll-spy widened to [data-chip-target] so both surfaces share one IntersectionObserver; .pk-shelf landing offset derived from --pk-header-h. Two Rule-1 auto-fixes found via live headless-Chrome CDP measurement (not caught by ExUnit): dual flex margin-left:auto competing between trigger/search (fixed via general-sibling override) and the trigger label's 48rem reveal overflowing the row at 768px (moved to a measured 50rem breakpoint).
- [Phase 01.2]: 01.2-01: mirrored (not extracted into a shared module) the three-clause detail_path/2 helper in both GameCard and GamePreview so both routes into the detail page carry identical ?from= state; PukllayClubWeb.CatalogFilters is now the single filter-parsing/validation authority, consumed by both CatalogLive.Index (URL read) and CatalogLive.Show (breadcrumb sanitiser)
- [Phase 01.2]: 01.2-02: D-06 similar_games/1 ranks same-weight-band candidates by a single Postgres fragment/2 set-intersection score (mechanics x2 + themes x1, desc, then name/id asc tie-break) instead of alphabetical order; overlap ranks but never filters, so a zero-overlap band-mate is still returned last
- [Phase 01.2]: 01.2-03: browsing_results?/1 wraps filters_active?/1 (never restates it) as the single gate for carousel vs. grid; a Rule 1 bugfix (:carousel_needs_reset/sync_carousel_visibility) was required so phx-update="stream" carousel rows actually repopulate every time the member returns from the grid, since D-01/D-02 removed the grid's always-visible fallback
- [Phase 01.2]: 01.2-04: Ficha técnica trimmed to Edad mínima/Año/Diseñadores/Editorial/BGG link with a new ficha_tecnica?/1 section-level guard closing the zero-one-many backstop; playtime_text/1 removed with its two sole call sites (D-04/D-05)
- [Phase 01.2]: 01.2-04: buy-box redesigned per UI-SPEC D-07 — pk-card-poster aspect, bg-base-200/rounded-box/p-4 panel, btn-lg full-width reserve CTA, top-right-anchored btn-sm share control (also fixing the mobile CTA bar's weight split since share_control/1 is shared), and a js-cover-fallback cover-failure fallback; mobile bar's flex-1/height/padding/timing and .DetailChrome untouched
- [Phase 01.2]: 01.2-05: .GridScroll colocated hook (vertical twin of .CarouselScroll) drives grid infinite scroll via an IntersectionObserver sentinel; data-exhausted folds in the new :more_error assign so a mid-scroll failure parks the hook instead of auto-retrying, and apply_filters/1 resets :more_error on both branches alongside :load_error
- [Phase 01.2]: 01.2-11: search-morph open/closed state moved fully server-side (Layouts.header_inner/1 renders is-open/is-search-open/aria-expanded/tabindex from a :search_expanded assign); .CatalogNav hook reduced to focus-only management and the document-level outside-click listener deleted (fixed G-01.2-2/G-01.2-3)
- [Phase 01.2]: 01.2-11: handle_params/3 widens :search_expanded only on a filters_active? false->true transition (not a plain OR against current state) so a same-query re-run never resurrects a box the member explicitly closed; CatalogLive.Show gained no-op open-search/close-search handlers since header_inner/1's buttons now dispatch these unconditionally on every nav_search-slot page
- [Phase 01.2]: [Phase 01.2]: 01.2-13: .pk-poster-col position: static -> relative (unlayered .pk-* rule was silently defeating the layered Tailwind relative utility below 768px, G-01.2-5); cascade-layer hazard documented at top of app.css; audit of all 18 .pk-* position rules found no second instance
- [Phase 01.2]: [Phase 01.2]: 01.2-13: buy-box panel ported sketch 027 variant B's Elevated Shadow (fill+border+shadow, per the rendered artifact, not detail-page-layout.md's fill-only prose summary); share_control/1 gained a variant attr (:panel/:bar) with two real shapes, both at the 44px floor rather than the sketch's smaller sizes
- [Phase 01.2]: [Phase 01.2]: 01.2-13: mobile CTA bar restructured to sketch 028's stacked layout (.pk-cta-bar-inner, reserve w-full not flex-1, share as a labelled full-width pill), capped to 68.75rem; body.pk-has-cta-bar padding recomputed 9.25rem -> 12.5rem (148+44+8px, derived); .DetailChrome scroll state machine untouched
- [Phase 01.2]: 01.2-12: :rendered_results assign now holds the SETTLED background surface (distinct from browsing_results?/1's DESIRED-surface predicate); settle_surface/1 is a no-op while @filters_open is true so the carousel/grid never restructures behind the open modal, and apply-filters/close-filters/clear-filters all now re-enter apply_filters/1 after closing the modal to settle + repopulate the reappearing container's stream in one round trip
- [Phase 01.2]: 01.2-12: active-filters chip row (sketch 029 winner C) added to the Resultados header — .pk-active-filter-chip is deliberately distinct from filter_modal.ex's own selection-chip class (no shadow, soft accent tint); chip removal reuses toggle-facet/toggle-scalar verbatim, new parameterless clear-query handler for the query chip
- [Phase 01.2]: 01.2-14: Catalog.similar_games/1's weight_band hard filter replaced by a band-preference array_position order_by term (nearest-band-first, derived from Vocabulary.weight_band_level/1) — shelf always fills to 12 cards, including for no-band games; D-06's intra-band overlap order kept byte-identical (G-01.2-7)
- [Phase 01.2]: 01.2-14: carousel_row/1 gained an optional badge attr (daisyUI badge-accent, rounded-full) defaulting nil; CatalogLive.Show derives :similares_widened by comparing returned games' bands and swaps in sketch 031's Ampliado badge + widened subtitle only when the shelf had to widen past the viewed game's own band
- [Phase 01.2]: 01.2-15: deleted flash_group/1's #client-error/#server-error toast entirely and replaced with .pk-conn-banner (element-id-targeted phx-disconnected/phx-connected bindings, accent tint, Spanish copy) as a sibling of #app-header inside the LiveView root but outside the header so it never shifts --pk-header-h
- [Phase 01.2]: 01.2-15: reduced-motion for .pk-conn-spinner uses @media (prefers-reduced-motion: no-preference) gating the animation itself (matching .pk-scroll-top's idiom), not a new per-selector reduce-block override, since app.css already retired that pattern in favor of one universal * guard
- [Phase 01.2]: 01.2-15: UI-SPEC's D-03 auto-load-more error row rescoped to a live query failure only (safe_filter_games/1, requires an established socket); a new connection-status row added for the transport-disconnect surface; header row-count corrected from a pre-existing 36/31 (already off-by-one against actual 37/32) to 38/33/3/2 after recounting
- [Phase 01.2, 2026-08-29]: Phase closed after 32 plans and 10 UAT gap-closure rounds (G-01.2-9 through G-01.2-21) — the mobile detail-page masthead was rebuilt (facts pills above the poster, one buy-box card, compact dot row), a single shared pill/chip base component replaced five independently-styled chip implementations, the lightbox was rebuilt from scratch (full-screen opaque stage, shell-width photo cap, own selection state independent of the gallery carousel, unified dark/light control family), and a site-wide sticky-footer layout + mobile-only title-echo bar shipped. Final UAT gate closed 2026-08-29: 23/28 checkpoints reconfirmed via a live mobile (390px) browser spot-check; the remaining 5 desktop-only claims (shell-width alignment at 1280/1440/1920px) were accepted on existing exact-DOM-coordinate measurements already on record in the Gaps section, since this session's browser automation tool would not resize its rendering viewport past ~390px (resize_window reported success but window.innerWidth stayed pinned at 339px) — worth re-verifying live on a real desktop browser if that tool limitation is ever hit again for future UI work.
- [Phase 01.3]: 01.3-02: D-06 checkpoint resolved run-now — full BGG re-enrichment ran against all 393 bgg_id-carrying games (385 updated, 8 missing from BGG, 14 unranked), plus artists backfilled/deduplicated for 385 games; Task 1's array_length(artists,1) IS NULL acceptance check has a Postgres empty-array-returns-NULL gap, verified as a false positive not a real skip (377+8=385)
- [Phase 01.3]: 01.3-04: Ran the real Spanish translation batch (D-01) -- 384/385 games translated to natural Argentine (Rioplatense) Spanish; found and fixed a Rule 1 bug where --only-english's exact-match resumability filter silently skipped 214/385 real candidates because bgg_payload drifts independently via 01.3-02's re-enrichment; the one legitimate failure (id 252, Mysterium) hit Gemini's deterministic RECITATION/copyright filter and correctly kept its prior English text.
- [Phase 01.3, 2026-09-01]: Phase closed after 12 plans and a 3-round chevron/toggle CSS gap-closure chain (float-in-justified-paragraph → native -webkit-line-clamp + trailing-sibling button → position:relative + :not(.is-expanded) absolute overlay) — final failure mode only reproduced on real WebKit/Mobile-Safari, not headless Chromium, confirming this codebase's established engine-divergence risk for this exact toggle-in-clamped-paragraph pattern. 8/8 UAT checkpoints passed, including 2 real-device confirmations (G-01.3-4+6 combined, G-01.3-5). G-01.3-1 (empty hashtag row) resolved as intended — HashtagNormalizer only derives tags from 3 CSV columns, giving 26% catalog coverage; accepted rather than widening the mapping. threats_open: 0 across 58 registered threats (01.3-SECURITY.md).
- [Phase 01.3]: designer/artist catalog filtering added (`?designers=`/`?artists=` open-text params) — first non-whitelisted list param this app accepts; parameterized via `type(^values, {:array, :string})` + `fragment("? && ?", ...)`, capped at 20 values × 120 chars each, GIN-indexed.
- [Phase 01.3]: `gemini_api_key` added alongside `bgg_api_token` in `Credentials` (`@secret_fields` + `@derive {Inspect, only: [...]}`, gitignored `config/dev.secret.exs` only); `instructor_lite` (hex.pm) is this phase's one new dependency, manually audited and approved in `01.3-RESEARCH.md` since it falls outside the automated npm/pypi/crates package-legitimacy seam.
- [Phase 01.3.1, 2026-09-01]: Phase closed after 2 plans, both UAT checkpoints passed on first pass (letterbox rendering across catalog grid/hover/mobile-sheet/detail surfaces; motivating example BGG id 305096 confirmed showing the correct Spanish/Fantasía cover, no stray thumbnail/dot strip). D-02 checkpoint resolved BGG's XML API v2 exposing no reachable gameplay/component photos by narrowing gallery scope to Spanish-edition box art only; `GalleryBackfill` re-ran live over ~434 games; one shared `.pk-poster-img` letterbox class now applied verbatim across every artwork surface except the lightbox and 64x64 selector chips.
- [Phase 02]: Quick task 260902-glf: reverted Phase 01.2's sticky-footer app shell (.pk-app-shell min-height/flex-grow) per developer's explicit choice; live CDP A/B measurement then found the accompanying flex column vestigial too (main carries only padding, no bottom margin, so nothing collapsed), so the entire .pk-app-shell class + its 3 presence tests + CSS-facts test contract were retired -- root.html.heex's <body> now carries no class at all
- [Phase 01.4]: 01.4-06: S1 blink fixed via server-rendered data-morph-armed marker + body:has() CSS guard (visibility:hidden, transition:none on hide, eased only on .is-docked reveal), replacing the client-JS-applied hiding class; mb-8 gives the mark anchor its own spacing tier (S2); morph rewritten to per-frame transform interpolation (single rAF scheduler, both live rects re-read every frame, bisected cubic-bezier matching --ease-standard) replacing the CSS layout-property transition (S3)
- [Phase 01.4]: 01.4-06: found and fixed (Rule 1) that the plan's literal <noscript><style> no-JS escape hatch is exempted from scripting-disabled-only behavior by the HTML spec's noscript child allowlist and would have permanently defeated S1 in every browser; replaced with a <noscript><div> marker (correctly parser-discarded when scripting is enabled) plus explicit hook-side removal, since LiveView's own connect-time DOM reconciliation was found to resurrect the parser-discarded marker on its own
- [Phase 01.4]: 01.4-07: G-01.4-2 map thumbnail coverage gap closed via lg-breakpoint (not sm) two-caption variant pair + opaque single-line inset chip + min-height floor on the thumb — all three independently-necessary per the debug session's differential experiment; human-check for perceptual sufficiency deferred to end-of-phase UAT per this phase's human_verify_mode=end-of-phase convention
- [Phase 01.4]: 01.4-08: --pk-about-mark-h reconciled 200px->180px (approved sketch 045 A3) and decoupled from anchor height via new --pk-about-mark-clear (80px, derived 44.4% of mark height) + calc(); #about-hero py-12 -> pt-2 pb-12 fixing inverted above/below allocation; closes G-01.4-3, human-check deferred to end-of-phase UAT
- [Phase 01.4]: 01.4-09: Maps thumbnail chip shrink-wrap/concentric-nesting fixed (--pk-map-label-inset single-source), light asset recaptured (tighter zoom, dominant pin, attribution in frame); pin-label truncation accepted as permanent per human confirmation in Google Maps, full venue name already carried in surrounding text
- [Phase 01.4]: 01.4-09: light/dark theme-variant <img> pair wired for the Maps thumbnail (mirrors brand_logo/1's isologo pattern, .pk-about-map-thumb img's display:block removed to avoid the 01.4-05 cascade hazard); real dark-mode capture NOT achieved (3 avenues exhausted: Maps web UI has no dark toggle, Chrome force-dark only recolors overlay text not tiles, OS dark mode leaves tiles light) — dark asset ships as an interim byte-identical copy of the light asset, tracked as an open stub (WINDOWS.md #23), deferring root cause (C) to a future pass
- [Phase 01.4]: 01.4-10: G-01.4-5 closed — .pk-about-map-thumb's aspect-ratio now derives from --pk-map-thumb-w/-h (the asset's real 1656x804 dimensions) instead of a stale 21:9 literal that was cropping Google's Maps attribution off every render; ExUnit gate reads real JPEG dimensions off disk to prevent recurrence
- [Phase 01.4]: 01.4-10: shipped test/visual/ — a zero-dependency Node+CDP+PIL visual probe that renders the live About page in real headless Chrome and independently confirms the crop geometry against painted pixels; deliberately excluded from mix quality/CI (needs a real browser + booted server), developer-invoked only
- [Phase 01.4]: 01.4-12: G-01.4-4/G-01.4-5 closed for good — static Maps screenshot pair (light+dark, plan 01.4-09/10) retired entirely in favor of a live keyless Google Maps embed iframe (D-11..D-15); new CSP `frame-src` directive derived from `ClubLinks.maps_embed_origin/0` (first third-party frame origin in the project), `sandbox="allow-scripts allow-same-origin"`, `pointer-events:none` + overlay click-out link, dark-theme `invert()` filter human-approved as-is (D-13); plan 01.4-11 (figcaption-legibility approach) superseded/discarded mid-flight once the embed decision reversed its premise
- [Phase 01.4, 2026-09-07]: Phase closed after 11/11 plans (plan 01.4-11 superseded/discarded by 01.4-12, cleanly absorbed) and a 4-gap UAT closure arc (G-01.4-1..4: isologo blink/spacing/motion, Maps thumbnail coverage → live embed). 7/7 UAT checkpoints passed; 01.4-VERIFICATION.md round 3: 11/12 truths verified directly + isologo motion human-confirmed in this session's final checkpoint. Security review: 46 threats registered across all 12 plans' own threat models, threats_open: 0 (01.4-SECURITY.md, ASVS L1 short-circuit — ASVS L1 grep/read verification, no auditor subagent needed since register_authored_at_plan_time was true for every plan and all mitigations were directly confirmed in code)

### Pending Todos

1 pending: "Surface 'Pukllay Club' brand name in site content" (cosmetic, ui) —
`.planning/todos/pending/2026-09-07-surface-pukllay-club-brand-name-in-content.md`. Raised
2026-09-07 right after Phase 01.4's final UAT checkpoint passed — the site never spells out the
club's name as text, only the isologo mark. User wants it sketched, not implemented ad hoc.

The 7-item retroactive UI audit of `CatalogLive.Index` (logged 2026-08-18 against
`ui-design-system`/`ux-patterns`/`ux-responsive`) was closed 2026-08-21 by quick task 260821-dah —
all 7 moved to `.planning/todos/completed/` with dated Resolution sections; see
`260821-dah-SUMMARY.md`. This also closes the touch-target human-verification thread from
`01-05-PLAN.md` ("the drawer trigger and pills are comfortably tappable"), recorded as an addendum
in `01-VERIFICATION.md`. Full original audit: https://claude.ai/code/artifact/f067cf3b-84ec-41d5-970c-71e035bc7f90

| Severity | Todo | Resolution |
|----------|------|------------|
| blocker | Sort dropdown overlaps and steals clicks from Filtros button | Fixed: `w-fit shrink-0` on the drawer wrapper |
| major | Ver detalles card CTA touch target (28px vs 44px, ×183) | Verified already resolved by 01-10 (`GamePreview`, `btn-outline ... min-h-11`) |
| major | Theme toggle: no accessible names + undersized (32px) | Fixed: 3 distinct `aria-label`s + `min-h-11 min-w-11` |
| minor | 10 font combos on catalog screen vs cap of 3 | Re-measured live: 5 combos, already at cap — no CSS changed |
| minor | 184 elements share `.btn-primary` weight — no secondary button tier | Fixed: `button/1` gained a `"secondary"` (outline) variant |
| cosmetic | Brand tagline: banned `text-[10px]` / `text-base-content/70` | Fixed: `text-xs text-neutral` |
| cosmetic | Brand logo link: 42px vs 44px minimum | Fixed: `min-h-11` on the anchor |

### Blockers/Concerns

- Phase 0: Three implementation decisions are explicitly deferred to Phase 0
  discuss-phase/plan-phase rather than assumed now — Dockerfile strategy for aarch64, safe Ecto
  migrations via Kamal, and minimal secrets management approach (see PROJECT.md "Open decisions")

- Phase 2: Embedding runtime throughput/latency for local CPU embeddings is a genuine open
  unknown (research/SUMMARY.md) — must be resolved via an explicit spike before committing to
  Bumblebee vs. an alternative runtime or a specific model; do not skip or shortcut this spike.
  **Compounded by 00-CONTEXT.md D-20:** production moved from the originally-planned Hetzner CAX31
  (ARM, 8 vCPU/16GB) to a GCP e2-micro (x86_64, 2 vCPU shared/1GB RAM) due to a capacity shortage —
  1GB RAM is very likely inadequate for local embedding inference even for a small model. The
  spike must verify against this box's actual constraints, not the original sizing; be ready to
  fall back to the documented remote-embedding-API Plan B (CLAUDE.md "Alternatives Considered")
  rather than assume local CPU embeddings will fit.

- Phase 2: Gemini free-tier model name and RPM/RPD limits need re-verification at implementation
  time (documentation churns faster than research can track)

- Phase 0 (plans 00-04 onward): main is now branch-protected requiring the 'quality' CI check — direct 'git push origin main' is rejected once a required status check exists. Future plan executors must land commits via a short branch + PR (gh pr create -> wait for CI -> gh pr merge), not a bare push, even though .planning/config.json still has git.branching_strategy:
- Plan 00-06 (nightly backup): repo is now public (00-03 D-19), so GitHub's 60-day scheduled-workflow auto-disable applies to the nightly pg_dump->R2 cron workflow. Must accept this risk explicitly or add a keepalive mechanism when planning/executing 00-06.

- [Phase 01, acknowledged 2026-08-18] Two UI/UX items from Phase 1's final human UAT were left open on purpose (developer chose to close the phase and fix these manually, section-by-section, rather than route through automated gap-closure — see `01-VERIFICATION.md` "Acknowledged Gaps"):
  - **G-01-4 (major):** Carousel shelves on `/` read as a single vertical list with no visible affordance that there are multiple carousels, and horizontal scroll happens at the window level instead of being scoped to each carousel row. A diagnosis was opened at `.planning/debug/G-01-4-carousel-affordance.md`.
  - **G-01-3 (unresolved):** The carousel prev/next scroll-controls test was skipped by the user ("I don't understand this") — whether the originally-reported "~20 columns forcing horizontal scroll" was a carousel rail or the `#games` grid is still an open question.
  - These two remain the next manual UI/UX pass's starting point. The third item originally grouped here — the 7-item UI audit — was closed 2026-08-21 by quick task 260821-dah (see "Pending Todos" above).
- [Resolved by quick task 260901-ty6, 2026-09-01] Mobile footer visual weight — the footer (not the full shell) had its ≤480px vertical chrome (margin+padding), wordmark, and link ink/gap all retuned down (96px→56px chrome); CDP-measured, 764/764 tests pass. Deferred item closed; if visual weight concerns resurface on other shell surfaces (header, drawer), that remains its own shell-wide phase.
- Deferred (not a blocker): sticky title-echo bar's brand-tint/bounce question — mechanical separation/contrast/typography fixes shipped in 01.3-09 and 01.3-11 (both deliberately left the bar's own background fill and `.pk-scroll-top`'s bounce animation untouched, per each plan's own "Open design questions"); brand treatment itself still undecided, reported at least twice now (01.2 and 01.3).

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260824-9zo | On desktop, make the content respect the shell width | 2026-08-24 | 9b47d4e | | [260824-9zo-on-desktop-make-the-content-respect-the-](./quick/260824-9zo-on-desktop-make-the-content-respect-the-/) |
| 260824-b71 | Polish catalog search filtering UX: mechanics, content hierarchy, desktop no-scroll, mobile bottom sheet | 2026-08-24 | 64a4cde | Complete | [260824-b71-polish-catalog-search-filtering-ux-defin](./quick/260824-b71-polish-catalog-search-filtering-ux-defin/) |
| 260824-eqc | Implement sketch 019 (variant D) in FilterModal: new copy, per-section cards, 6+ Jugadores bucket, ghost Limpiar filtros, background dim/blur, Destacados cut | 2026-08-24 | ce04eff | Complete | [260824-eqc-implement-sketch-019-s-winning-design-va](./quick/260824-eqc-implement-sketch-019-s-winning-design-va/) |
| 260824-jkc | Implement sketch 020's winning design: refined mobile chip index row + desktop mega-menu | 2026-08-24 | 9b88168 | Complete | [260824-jkc-implement-sketch-020-s-winning-design-re](./quick/260824-jkc-implement-sketch-020-s-winning-design-re/) |
| 260824-u5d | Implement pagination for the catalog carousels/sections: in-row horizontal infinite scroll (30-game ceiling), Ver todo tile removed | 2026-08-24 | 218accf | Complete | [260824-u5d-implement-pagination-for-the-catalog-car](./quick/260824-u5d-implement-pagination-for-the-catalog-car/) |
| 260806-rq8 | Add Styler + mix_audit quality gates (superseded credence) to mix quality | 2026-08-06 | 9477e7f | | [260806-rq8-add-credence-semantic-ast-elixir-linter-](./quick/260806-rq8-add-credence-semantic-ast-elixir-linter-/) |
| 260818-fro | Integrate Tidewave (dev-only) MCP plug into Phoenix endpoint | 2026-08-18 | d3761dd | | [260818-fro-integrate-tidewave-dev-only-into-phoenix](./quick/260818-fro-integrate-tidewave-dev-only-into-phoenix/) |
| 260823-snj | Polish desktop header: search icon relevance + header-only isologo (footer de-duplicated) | 2026-08-23 | f0484a0 | | [260823-snj-polish-desktop-header-improve-the-search](./quick/260823-snj-polish-desktop-header-improve-the-search/) |
| 260824-7mt | Implement sketch 018 winner B — mute theme toggle color/size and tone active state vs social icons | 2026-08-24 | c6d378b | | [260824-7mt-implement-sketch-018-winner-variant-b-mu](./quick/260824-7mt-implement-sketch-018-winner-variant-b-mu/) |
| 260818-lg2 | Convert docs/ux-patterns.md into ux-patterns + ux-responsive skills, merge hierarchy/affordance into ui-design-system | 2026-08-18 | 3a4380e | | [260818-lg2-convert-docs-ux-patterns-md-into-three-s](./quick/260818-lg2-convert-docs-ux-patterns-md-into-three-s/) |
| 260818-gdb | Fix the max-w-2xl container bug in Layouts.app | 2026-08-18 | b44d927 | | [260818-gdb-fix-the-max-w-2xl-container-bug-in-lib-p](./quick/260818-gdb-fix-the-max-w-2xl-container-bug-in-lib-p/) |
| 260818-h9p | Build UX pattern reference doc at docs/ux-patterns.md from research | 2026-08-18 | 703a919 | | [260818-h9p-build-ux-pattern-reference-doc-at-docs-u](./quick/260818-h9p-build-ux-pattern-reference-doc-at-docs-u/) |
| 260818-jpm | Add Linear/GOV.UK/Shopify/Microsoft/NN.g reference points (B28-B32) and LiveView-fit/device-target/PWA-scope answers (F33-F35) to docs/ux-patterns.md | 2026-08-18 | 58a2b6c | | [260818-jpm-add-linear-gov-uk-shopify-master-detail-](./quick/260818-jpm-add-linear-gov-uk-shopify-master-detail-/) |
| 260818-mhl | Add igniter and usage_rules as dev-only dependencies and wire up dependency usage-rules syncing into AGENTS.md | 2026-08-18 | e775f45 | Verified | [260818-mhl-add-igniter-and-usage-rules-as-dev-only-](./quick/260818-mhl-add-igniter-and-usage-rules-as-dev-only-/) |
| 8 | Add a .mcp.json file at the repo root that configures the Tidewave MCP server as an HTTP (streamable) server pointing at http://localhost:4000/tidewave/mcp, matching the standard Tidewave README setup. | 2026-08-18 | 808e34a | — | — |
| 260818-n4l | Add dialyxir and excoveralls, make precommit non-mutating, add quality.full alias | 2026-08-18 | c11b257 | Verified | [260818-n4l-add-dialyxir-and-excoveralls-and-make-th](./quick/260818-n4l-add-dialyxir-and-excoveralls-and-make-th/) |
| 9 | Add dialyxir and excoveralls, make precommit non-mutating, add quality.full alias | 2026-08-18 | c11b257 | — | — |
| 11 | Add mix precommit/quality workflow rules to .planning/codebase/CONVENTIONS.md | 2026-08-18 | 4811893 | — | — |
| 12 | Merge theme.css's brand-manual provenance/WCAG docs into app.css; remove non-compiling orphaned theme.css | 2026-08-21 | a3967fe | — | — |
| 13 | Reconcile sketch theme with app.css (D2 conform, D2b retire dark-purple.css), add check-theme-drift.sh; D1 geometry deferred | 2026-08-21 | 34a40f0 | — | — |
| 14 | Fix 7 UI audit findings on CatalogLive.Index (drawer overlap, theme-toggle a11y/hit-target, logo/tagline, button hierarchy, type inventory) — quick-260821-dah | 2026-08-21 | b90b499 | — | — |
| 260821-umm | Footer's left cluster now shows the About hero tagline ("Conectá jugando") instead of repeating the header's "JUEGOS DE MESA MODERNOS" subtitle | 2026-08-21 | 9734f18 | | [260821-umm-footer-left-cluster-in-layouts-ex-footer](./quick/260821-umm-footer-left-cluster-in-layouts-ex-footer/) |
| 260821-v7q | Wired the real isologo mark into Layouts.brand_logo/1 with theme-aware light/dark images and rebuilt favicon.ico from the purple isologo lockup | 2026-08-21 | aff2b1d | | [260821-v7q-wire-up-the-real-isologo-mark-theme-awar](./quick/260821-v7q-wire-up-the-real-isologo-mark-theme-awar/) |
| 17 | Polish the desktop header: base-200 surface, rebalanced pk-nav-actions cluster, shared 48px height/centre line, muted+active nav-link tiers | 2026-08-22 | 9195443 | — | — |
| 260824-hu1 | On mobile the expanded header search now aligns its own edges (not just its contents) to the shared gutter line, restoring the fully-rounded pill shape | 2026-08-24 | 0fcc255 | Complete | [260824-hu1-on-mobile-the-expanded-search-looks-awfu](./quick/260824-hu1-on-mobile-the-expanded-search-looks-awfu/) |
| 260824-i8e | Removed the stale native sort `<select>` (Nombre/Duración/Complejidad/Más recientes) from the catalog page; sort machinery underneath (parse_sort/1, :sort assign, see-all/URL deep links) left fully intact | 2026-08-24 | c3b14b3 | Complete | [260824-i8e-the-select-for-nombre-duracion-etc-looks](./quick/260824-i8e-the-select-for-nombre-duracion-etc-looks/) |
| 260824-q8z | Mobile drawer bottom block: social links reordered as a full-width, high-contrast, 44px CONTENT row; theme control centered and its "Tema" label converted to sr-only as a quiet FOOTER strip (mirrors the desktop footer's shipped pattern, applies sketch 021's Round-6 conclusion) | 2026-08-24 | 79b392b | Complete | [260824-q8z-for-mobile-the-social-links-at-the-botto](./quick/260824-q8z-for-mobile-the-social-links-at-the-botto/) |
| 260824-t7g | New carousel arrow layer from sketches 022-026: relocated prev/next controls to Netflix-style edge-overlay chevrons gated to pointer-fine devices (022-C), replaced the browser's fixed smooth-scroll with the project's own 200ms soft ease-out curve (023-B) | 2026-08-24 | d106248 | Partial (live-smoothness sub-check needs a human eyeballing it in a foregrounded tab — see SUMMARY) | [260824-t7g-new-carousel-from-latest-sketches](./quick/260824-t7g-new-carousel-from-latest-sketches/) |
| 260901-ty6 | Reduce the mobile (<=480px) footer's visual weight: shrink .pk-footer margin-top and .pk-footer-row vertical padding on mobile, shrink the footer brand_logo, and shrink footer-links font-size/gap on mobile. Desktop untouched. | 2026-09-01 | ed51bab | Complete (764/764 tests, mix quality passes; CDP-measured mobile chrome 96px→56px; one human-judgment visual check flagged in SUMMARY) | [260901-ty6-reduce-the-mobile-480px-footer-s-visual-](./quick/260901-ty6-reduce-the-mobile-480px-footer-s-visual-/) |
| 260902-fdm | Reduce the mobile footer to just the BGG attribution line per sketch 044 (winner H): remove brand name/tagline, FAQ/Contacto/Juntadas links, and the copyright line from the <=480px footer; keep only <.bgg_attribution />; tighten the <=480px gap further. Desktop untouched. | 2026-09-02 | 1062835 | Complete (766/766 tests, mix format/compile clean; CDP-measured mobile chrome 56px→40px; one human-judgment visual check flagged in SUMMARY, same precedent as 260901-ty6) | [260902-fdm-reduce-the-mobile-footer-to-just-the-bgg](./quick/260902-fdm-reduce-the-mobile-footer-to-just-the-bgg/) |
| 260902-g21 | On mobile (<=480px), right-align the footer (now just the BGG attribution line) instead of centering it; retire the stale centering-rationale comment; desktop unaffected. | 2026-09-02 | c2ff6a3 | Complete (767/767 tests, mix format clean; CDP-measured 320/390px right-edge alignment confirmed, desktop byte-identical at 768/1280px; one human-judgment visual check flagged in SUMMARY, same precedent as prior footer tasks) | [260902-g21-on-mobile-480px-right-align-the-footer-i](./quick/260902-g21-on-mobile-480px-right-align-the-footer-i/) |
| 260902-glf | Delete the site-wide sticky-footer app shell mechanism (.pk-app-shell min-height/flex-grow) so the footer follows content instead of being pushed to the viewport bottom on short pages; live CDP A/B measurement then found the accompanying flex column vestigial too, so the entire .pk-app-shell class and its tests were retired. | 2026-09-02 | 0e0690c | Complete (762/762 tests, mix format/compile clean; CDP-measured short-page/long-page/CTA-bar geometry + flex-column A/B all byte-identical; two human-judgment visual checks flagged in SUMMARY, same precedent as prior footer tasks) | [260902-glf-remove-the-site-wide-sticky-footer-layou](./quick/260902-glf-remove-the-site-wide-sticky-footer-layou/) |
| 260902-il3 | Fix the catalog page's ("/") last-shelf-to-footer gap: main's default pb-20 (80px) was stacking with .pk-shelf's trailing margin and .pk-footer's own margin-top since CatalogLive.Index never opted into the existing boundary_collapse mechanism the detail page uses. Added a new bottom_collapse attr (bottom-only, doesn't touch top spacing) sharing one CSS declaration with the detail page's footer-margin rule. | 2026-09-02 | cf95f7b | Complete (773/773 tests, mix quality clean; CDP-measured gap 128px/176px -> 16px/24px at 390px/1280px matching the detail page exactly; top spacing + detail/about pages unaffected; a stale test wrongly justifying catalog bottom padding as "CTA-bar clearance" found and fixed; D-03 shipped 16/24px split (matching detail page) not a flat 24px, flagged for confirmation) | [260902-il3-fix-the-large-empty-gap-between-the-last](./quick/260902-il3-fix-the-large-empty-gap-between-the-last/) |

### Roadmap Evolution

- Phase 01.1 edited: cleaned up title/goal/requirements/success-criteria after insertion; added SHELL-01..05 to REQUIREMENTS.md
- Phase 01.2 inserted after Phase 1: Catalog & Detail Navigation Polish — polish the catalog index page and game detail page navigation and layout, refining what Phase 1/1.1 shipped (URGENT)
- Phase 01.3 inserted after Phase 01.2: Game detail page layout needs to be clearer/more scannable and the game information shown needs to be accurate; requested after Phase 01.2's navigation/mechanics polish shipped (URGENT)
- Phase 01.3.1 inserted after Phase 01.3: Game Image Quality & Multi-Image Gallery (URGENT)
- Phase 5 added: UI polish pass for About page sketches
- Phase 01.4 inserted after Phase 1: UI polish pass for About page sketches (URGENT)

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-09-07T19:05:24.168Z
Stopped at: Phase 01.4 complete, ready to plan Phase 02
Resume file: None
