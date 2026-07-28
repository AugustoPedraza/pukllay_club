---
phase: 01-catalog-v1
plan: 02
subsystem: ui
tags: [tailwind-v4, daisyui, phoenix-liveview, brand-identity, self-hosted-fonts]

# Dependency graph
requires: []
provides:
  - "Brand daisyUI theme tokens (light + dark) replacing the stock phx.new orange/slate palette"
  - "Self-hosted Bebas Neue + Inter woff2 fonts wired to Tailwind's font-sans/font-display utilities"
  - "PukllayClubWeb.Layouts.brand_logo/1 component (wordmark + tagline lockup, isologo-gated)"
  - "Rewritten app/1 header carrying the brand identity instead of Phoenix marketing chrome"
  - "Spanish document language (lang=\"es\") in the root layout"
affects: [01-03, 01-04, 01-05, 01-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Compile-time asset gating via @external_resource + File.exists?/1 module attribute (isologo?)"
    - "Tailwind v4 @theme block for brand font tokens, consumed via font-sans/font-display utilities"

key-files:
  created:
    - priv/static/fonts/bebas-neue-400-latin.woff2
    - priv/static/fonts/bebas-neue-400-latin-ext.woff2
    - priv/static/fonts/inter-400-latin.woff2
    - priv/static/fonts/inter-400-latin-ext.woff2
    - priv/static/fonts/inter-600-latin.woff2
    - priv/static/fonts/inter-600-latin-ext.woff2
    - test/pukllay_club_web/components/layouts_test.exs
  modified:
    - assets/css/app.css
    - lib/pukllay_club_web/components/layouts.ex
    - lib/pukllay_club_web/components/layouts/root.html.heex
    - config/runtime.exs

key-decisions:
  - "Kept daisyUI theme values in hex form (not oklch) per the design contract, to preserve direct traceability to the brand manual's stated RGB/hex values"
  - "info/success/warning -content variants (not specified in the UI-SPEC's 17-var table) converted to brand-consistent hex to satisfy the plan's own zero-oklch acceptance criterion"
  - "app/1's marketing-link/theme-toggle/wordmark behavior is tested via render_component(&Layouts.app/1, ...) rather than a live GET / request, because PageController's home.html.heex does not wrap its content in <Layouts.app> — that route only inherits the root layout, so lang=\"es\" is the only app/1-independent assertion GET / can validate"

patterns-established:
  - "Brand asset gating: @isologo_path / @external_resource / @isologo? compile-time attributes let a future isologo.svg drop-in complete the logo lockup with zero code changes"

requirements-completed: [CATALOG-01]

coverage:
  - id: D1
    description: "Self-hosted Bebas Neue + Inter woff2 fonts wired to Tailwind font-sans/font-display, no runtime request to any third-party font CDN"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "mix assets.build && grep -c '@font-face' assets/css/app.css (== 6)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Light and dark daisyUI theme blocks carry the brand palette from 01-UI-SPEC.md; zero stock oklch values remain"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "grep -c 'oklch(' assets/css/app.css (== 0); grep -F '#3D096D'/'#A97FD1' assets/css/app.css"
        status: pass
    human_judgment: false
  - id: D3
    description: "brand_logo/1 renders PUKLLAY CLUB wordmark + JUEGOS DE MESA MODERNOS tagline, degrades gracefully without the isologo asset; app/1 drops Phoenix marketing links but keeps the theme toggle; root layout declares lang=\"es\""
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs (7 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Both light and dark themes render legibly end-to-end via the existing theme toggle in a real browser"
    human_judgment: true
    verification: []
    rationale: "Requires visual inspection of rendered brand colors and typography in both themes — deferred to the phase's end-of-phase human checkpoint per 01-02-PLAN.md's <verification> section, not re-litigated per-plan"

duration: 30min
completed: 2026-07-28
status: complete
---

# Phase 01 Plan 02: Brand Identity Summary

**Replaced the stock phx.new daisyUI theme with the PUKLLAY CLUB brand palette, self-hosted Bebas Neue/Inter typography, and a real Spanish-language header lockup.**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-07-28
- **Tasks:** 3
- **Files modified:** 11 (6 new font files, 1 new test file, 4 modified source files)

## Accomplishments
- Self-hosted 6 woff2 font files (Bebas Neue 400, Inter 400/600, latin + latin-ext each) under `priv/static/fonts/`, with matching `@font-face` rules and a Tailwind v4 `@theme` block exposing `--font-sans`/`--font-display` — zero runtime requests to any third-party font CDN
- Replaced both `light` and `dark` daisyUI theme blocks in `assets/css/app.css` with the 01-UI-SPEC.md brand hex palette; no stock `oklch(...)` value survives
- Added `PukllayClubWeb.Layouts.brand_logo/1`, gated on compile-time isologo asset presence, and rewired `app/1`'s header to use it while dropping the generated Website/GitHub/Get Started links
- Declared `lang="es"` in the root layout and updated the `<.live_title>` suffix to `" · PukllayClub"`

## Task Commits

Each task was committed atomically:

1. **Task 1: Self-host Bebas Neue and Inter, wire them as Tailwind theme fonts** - `7ea8320` (feat)
2. **Task 2: Replace both daisyUI theme blocks with the brand palette** - `1bf5eff` (feat)
3. **Task 3: Brand header lockup and Spanish document language** - `d6401cb` (test, RED) → `b230707` (feat, GREEN)

**Plan metadata:** (this commit)

_Note: Task 3 is TDD — RED test commit followed by a GREEN implementation commit._

## Files Created/Modified
- `priv/static/fonts/bebas-neue-400-latin.woff2`, `bebas-neue-400-latin-ext.woff2` - Self-hosted Bebas Neue 400 woff2 subsets
- `priv/static/fonts/inter-400-latin.woff2`, `inter-400-latin-ext.woff2`, `inter-600-latin.woff2`, `inter-600-latin-ext.woff2` - Self-hosted Inter 400/600 woff2 subsets
- `assets/css/app.css` - `@font-face` rules, `@theme` font tokens, brand-palette daisyUI theme blocks (light + dark)
- `lib/pukllay_club_web/components/layouts.ex` - `brand_logo/1` component, rewritten `app/1` header
- `lib/pukllay_club_web/components/layouts/root.html.heex` - `lang="es"`, `<.live_title>` suffix
- `test/pukllay_club_web/components/layouts_test.exs` - New test file (7 tests) for `brand_logo/1` and `app/1`
- `config/runtime.exs` - Fixed a pre-existing invalid regex modifier blocking all `mix test` runs (see Deviations)

## Decisions Made
- Kept daisyUI theme values in hex form, not `oklch()`, per the design contract's explicit instruction to preserve traceability to the brand manual's stated hex values.
- `info`/`success`/`warning` `-content` color variants (not specified in the UI-SPEC's 17-variable table for either theme) were converted from the original stock `oklch(...)` values to brand-consistent hex, since the plan's own acceptance criterion demands zero `oklch(` values remain in `app.css`.
- `app/1`'s wordmark/tagline/marketing-link/theme-toggle behavior is tested via `render_component(&Layouts.app/1, ...)` rather than a live `GET /` request: `PageController`'s `home.html.heex` does not wrap its content in `<Layouts.app>` (it only inherits the root layout), so a real `/` request never exercises the header at all in this phase. The root-layout-level `lang="es"` assertion is still tested via a real `GET /` request, since that is genuinely shared across every route.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed invalid regex modifier in config/runtime.exs blocking all test execution**
- **Found during:** Task 3 (writing the RED test and attempting to run it)
- **Issue:** `config/runtime.exs`'s dev-only `live_reload` patterns used `~r"..."E` (an invalid Elixir regex sigil modifier — "E" is not a recognized option). Because macro expansion for literal `~r/.../` sigils happens eagerly across the whole file regardless of which runtime `if` branch executes, this raised `Regex.CompileError` and prevented `mix test` from running in *any* environment (dev/test/prod), not just this plan's new test.
- **Fix:** Removed the stray `E` suffix from all 4 `~r"..."` sigils in the dev `live_reload` config block.
- **Files modified:** `config/runtime.exs`
- **Verification:** `mix test` now compiles config and runs the full suite (13 tests, 0 failures) instead of crashing before any test executes.
- **Committed in:** `b230707` (Task 3 GREEN commit)

**2. [Rule 1 - Bug] Converted remaining oklch() semantic content colors to brand hex**
- **Found during:** Task 2 verification
- **Issue:** The UI-SPEC's daisyUI variable table only specifies 17 vars per theme (base, primary, secondary, accent, neutral, error, and their `-content` pairs where applicable), omitting `-content` for `info`/`success`/`warning`. Applying only the specified replacements left 6 stock `oklch(...)` values in place, failing the plan's own "no oklch(" remains" acceptance criterion.
- **Fix:** Set `info-content`/`success-content`/`warning-content` to brand-consistent hex (white/dark-violet-charcoal, matching the pattern used for `primary-content`/`error-content` in each theme) rather than leaving stock values or introducing new unreviewed hues.
- **Files modified:** `assets/css/app.css`
- **Verification:** `grep -c 'oklch(' assets/css/app.css` returns 0; `mix assets.build` succeeds.
- **Committed in:** `1bf5eff` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes were necessary for the plan's own stated acceptance criteria to pass and for `mix test` to run at all. No scope creep — no files outside the plan's declared scope were touched beyond the one pre-existing bug fix required to unblock TDD execution.

## Issues Encountered
- The plan's Task 3 description assumed a `GET /` request would exercise the `app/1` header (for asserting wordmark/marketing-link/theme-toggle content). In practice, Phase 0's `PageController` renders `home.html.heex` directly under the root layout only, without `<Layouts.app>` — no LiveView using the app layout exists yet in this phase. Resolved by testing `app/1` directly via `render_component/2` (as the plan already specified for `brand_logo/1`) and reserving the real `GET /` request for the one assertion that genuinely is root-layout-wide (`lang="es"`). This is a test-authoring correction, not a change to shipped behavior — `app/1` will be exercised for real once `01-03`'s catalog LiveView (which does use `<Layouts.app>`) lands.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Brand theme tokens, self-hosted fonts, and the header lockup are in place before any catalog component is authored, satisfying this plan's stated purpose (no component gets built against throwaway colors).
- `priv/static/images/isologo.svg` is still not supplied (only the brand identity PDF exists) — `brand_logo/1` will pick it up automatically the moment it's added, no code change needed.
- Human visual verification of both themes (light/dark, brand colors, Bebas Neue/Inter rendering) is deferred to the phase's end-of-phase checkpoint per 01-02-PLAN.md, once the catalog LiveView (01-03+) gives the header something substantial to render alongside.

---
*Phase: 01-catalog-v1*
*Completed: 2026-07-28*

## Self-Check: PASSED

All created files verified present on disk (6 woff2 fonts, layouts_test.exs, this SUMMARY.md).
All 5 referenced commit hashes verified present in git history (7ea8320, 1bf5eff, d6401cb,
b230707, 0c154d5).
