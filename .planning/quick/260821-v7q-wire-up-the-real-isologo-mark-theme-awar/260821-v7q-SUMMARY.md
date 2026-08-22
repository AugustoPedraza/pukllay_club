---
phase: quick-260821-v7q
plan: 01
subsystem: site-shell
tags: [layouts, brand, theme, isologo, tdd]
dependency-graph:
  requires: []
  provides: [theme-aware-isologo-pair]
  affects: [PukllayClubWeb.Layouts.brand_logo/1, header, footer]
tech-stack:
  added: []
  patterns:
    - "assign_new/3 test seam for an otherwise-unstubbable compile-time constant"
    - "dark: custom variant pair (dark:hidden / hidden dark:block) instead of a runtime conditional"
key-files:
  created: []
  modified:
    - lib/pukllay_club_web/components/layouts.ex
    - test/pukllay_club_web/components/layouts_test.exs
    - priv/static/images/isologo-light.png
    - priv/static/images/isologo-dark.png
    - priv/static/favicon.ico
    - .claude/skills/ui-design-system/SKILL.md
decisions:
  - "assign_new/3 replaces assign/3 for isologo? so a test can force the wordmark-only fallback branch that a compile-time constant alone makes unreachable once both marks exist on disk; production behaviour is byte-identical since no call site ever passes the key"
  - "isologo? stays an undeclared assign (not a public attr) so assign_new/3's seam works — a declared attr with a default would pre-populate the key and defeat the seam"
metrics:
  duration: 35min
  completed: 2026-08-21
status: complete
actuals:
  tokens: 2183
  tasks: 3
  commits: 4
---

# Phase quick-260821-v7q Plan 01: Wire up the real isologo mark, theme-aware Summary

Wired the two now-final isologo PNGs into `Layouts.brand_logo/1` as a theme-aware pair — dark-purple
mark for light theme, white mark for dark theme — toggled by the app's existing `dark:` custom
variant, replacing the retired single-file gate that had rendered wordmark-only since Phase 1.

## What Was Built

- **Two-path compile-time gate**: `@isologo_light_path` / `@isologo_dark_path`, each its own
  `@external_resource`, `@isologo? = File.exists?(light) and File.exists?(dark)`. If either file
  is missing, the component degrades to the wordmark + tagline lockup with zero `<img>` elements —
  never a half-rendered pair.
- **Two `<img>` elements** in `brand_logo/1`, both gated on `:if={@isologo?}`: the light mark
  carries `class="dark:hidden"`, the dark mark carries `class="hidden dark:block"`. Both keep
  `width="36"` and `alt=""` (decorative — the adjacent wordmark carries the accessible name).
- **`assign_new/3` test seam**: `assign(assigns, :isologo?, @isologo?)` became
  `assign_new(assigns, :isologo?, fn -> @isologo? end)`. `isologo?` is deliberately not a declared
  `attr`, so no production call site ever supplies it and the compile-time constant always wins —
  behaviour is byte-identical to the old `assign/3`. A test can now force
  `render_component(&brand_logo/1, %{isologo?: false})` to exercise the fallback branch, which the
  old design made untestable once real assets exist on disk (see "Correction" below).
- **Both call sites** (header via `header_inner/1`, footer via `footer/1`) render the pair
  unchanged otherwise — wordmark, `tagline` attr, `<a href="/">` wrapper, `min-h-11` are untouched.
- **Assets committed**: `priv/static/images/isologo-light.png` (78,853 bytes),
  `isologo-dark.png` (63,711 bytes), and `priv/static/favicon.ico` (6,058 bytes, multi-size
  16/32/48/64 purple-background lockup) — all three were untracked/uncommitted before this plan.
- **Design-system inventory row** (`ui-design-system` skill, `brand_logo/1` row) now states the
  mark is a theme-aware pair gated on both files existing, instead of implying a single asset.

## Already Done Outside This Plan

`priv/static/favicon.ico` had already been replaced by the developer with the multi-size
purple-background isologo lockup before this plan started. This plan only committed that file —
it was not regenerated, resized, or re-encoded.

## TDD Flow (Task 1)

- **RED** (`4aef01c`): five new tests added under `describe "brand_logo/1 theme-aware isologo pair
  (260821-v7q)"` — exactly-two-images, correct `dark:` classes + `width`/`alt` on each, both marks
  in the footer's `.pk-footer-left`, `isologo?: false` fallback, and `File.exists?/1` gate
  truthfulness. Confirmed 3 of 5 failed against the pre-change single-asset gate.
- **GREEN** (`aff2b1d`): implemented the two-path gate + two `<img>` elements +
  `assign_new/3` seam, committed together with the three binary assets (load-bearing, not
  housekeeping — without committing the PNGs, CI would compile with the gate false). All 31 tests
  passed.
- **Task 2** (`4078233`): deleted the now-vacuous `brand_logo/1` absence-only test (superseded by
  Task 1's Tests 4/5) and rewrote the footer's stale `refute ... isologo.svg` assertion into a
  positive check that both theme marks with their `dark:` classes render inside
  `.pk-footer-left`. Swept `lib/` and `test/` for remaining `isologo.svg` references — none found.
- **Task 3** (`c2c95d0`): `mix quality` gate + inventory-row update. Format found one stray blank
  line left by Task 2's test deletion (Styler rewrite reviewed — trivial whitespace, no behaviour
  change); Credo's one pre-existing `Design.AliasUsage` suggestion and Sobelow's four low-confidence
  `Traversal.FileModule` findings are unrelated to this plan's files and were left as-is (out of
  scope per the deviation rules' scope boundary).

## Correction: Why the Old Fallback-Test Pattern Couldn't Be Reused

The pre-existing fallback test asserted `refute File.exists?("priv/static/images/isologo.svg")`
then rendered and checked for the absence of a broken image reference — it worked only because the
asset genuinely didn't exist yet. Once real PNGs land on disk, `@isologo?` becomes a compile-time
`true` constant with no runtime hook to stub false. The minimum seam that (a) keeps production
behaviour identical and (b) restores testability of the fallback branch is `assign_new/3` on an
undeclared assign key — documented in the module as a test-only seam, not a new public component
API.

## Accepted Trade-off (T-v7q-03)

Both PNG variants (~143 KB combined) are fetched by mainstream browsers regardless of the active
theme, because a `display:none`-equivalent `<img>` (`dark:hidden` / `hidden dark:block`) still
downloads. Header and footer reuse the same two URLs, so this is two cached, fingerprinted static
requests per visit — a one-time cost with no per-request server work. Accepted as low severity;
revisit only if a page-weight budget is introduced.

## Verification

- `mix test test/pukllay_club_web/components/layouts_test.exs` — 30 tests, 0 failures (net -1 test
  count from Task 2's deletion of the now-vacuous absence test, +5 from Task 1, offset by removal).
- `mix assets.build` — built stylesheet contains both `dark\:hidden` and `dark\:block` (this is the
  app's first `dark:` usage under `lib/`).
- `git ls-files --error-unmatch` — all three binary assets tracked.
- `test "$(grep -c 'File.exists?' lib/.../layouts.ex)" = "2"` — gate uses exactly two
  `File.exists?/1` calls.
- Zero non-comment references to `isologo.svg` under `lib/` or `test/`.
- `mix quality` exits clean (hex.audit, deps.audit, deps.unlock --check-unused, format, credo
  --strict, sobelow, test --warnings-as-errors).
- **Human-check eye test — done via automated headless-Chrome screenshots** (dev server was
  already running on :4000 from a prior session; `mix phx.server` confirmed already up rather than
  started fresh). Screenshots at `/` and `/quienes-somos` with `--blink-settings=preferredColorScheme=0|1`
  confirmed: light theme shows the dark-purple mark at both header and footer with no white mark
  visible; dark theme shows the white mark at both call sites with no dark-purple mark visible;
  `curl` against the live page confirmed both `<img>` tags carry the correct `dark:hidden` /
  `hidden dark:block` classes at both call sites; `/favicon.ico` returns 200 with the new 6,058-byte
  multi-size purple lockup (up from the old 152-byte default).

## Deviations from Plan

None — plan executed exactly as written. The one format fix in Task 3 (a stray blank line) is
routine `mix format` output, not a deviation.

## Self-Check: PASSED

All six files in `must_haves.artifacts` found on disk. All four commit hashes
(`4aef01c`, `aff2b1d`, `4078233`, `c2c95d0`) verified present in `git log --oneline`.
