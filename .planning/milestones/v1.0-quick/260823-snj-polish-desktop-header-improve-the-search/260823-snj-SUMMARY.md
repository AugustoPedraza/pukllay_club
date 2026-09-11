---
phase: quick-260823-snj
plan: 01
subsystem: ui
tags: [phoenix, liveview, tailwind, daisyui, heroicons, css]

requires:
  - phase: 01.1-08
    provides: the search-morph 44px toggle/pill and the theme-aware isologo pair this plan revises
provides:
  - A desktop header search control that reads as a bordered, filled 44px button (hero-magnifying-glass/size-5, base-100 fill, base-content icon) instead of a 16px decorative glyph
  - hover AND focus-within parity on the search control (both drive border+icon to primary), not hover-only
  - brand_logo/1's mark attr (default true) so the isologo pair renders on the header only; the footer renders wordmark+tagline only, demoted to the neutral colour tier via pk-brand-quiet
affects: [layouts, header, footer, brand-identity, ui-design-system-skill]

actuals:
  tokens: 3439
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "brand_logo/1 mark attr: a declared boolean attr (not the isologo? test-only assign_new seam) that gates both the isologo <img> pair and a pk-brand-quiet colour-demotion class from a single call-site flag"
    - "hover/focus-within pairing on interactive chrome: :hover:not(.is-open) and :focus-within:not(.is-open) share one selector list so pointer and keyboard reach the same affordance, never hover-only"

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/components/layouts.ex
    - assets/css/app.css
    - test/pukllay_club_web/components/layouts_test.exs
    - .claude/skills/ui-design-system/SKILL.md

key-decisions:
  - "D-A (from plan): the isologo mark becomes header-only; the footer gives it up, since 481-767px relies on the header mark as the only brand identity in that band while the footer has no such constraint"
  - "D-B (from plan): footer wordmark demoted by colour (neutral token) not by size, keeping the catalogue's measured type inventory at its existing 3-tier cap"

patterns-established:
  - "Pattern: a component's test-only assign_new seam (isologo?) and its real declared attrs (tagline, mark) are kept separate rather than merged — the seam stays invisible to production call sites, declared attrs get normal attr/doc treatment"

requirements-completed: [SHELL-01]

coverage:
  - id: D1
    description: "Header search toggle raised from a 16px muted glyph to a 44px bordered, filled control with a 20px icon at full contrast"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#app/1 search-morph (01.1-08) - the toggle's icon is the full hero-magnifying-glass at size-5 (260823-snj)"
        status: pass
      - kind: automated_ui
        ref: "chromium headless CDP screenshot, http://localhost:4001/ at 1440px, resting + :hover + :focus-within states"
        status: pass
    human_judgment: false
  - id: D2
    description: "Hover and keyboard focus both drive the search pill's border and glyph to primary — neither state is pointer-only"
    requirement: "SHELL-01"
    verification:
      - kind: other
        ref: "awk-scoped grep confirming .pk-search-morph:hover:not(.is-open), .pk-search-morph:focus-within:not(.is-open) share one border-color rule"
        status: pass
      - kind: automated_ui
        ref: "chromium headless CDP mouse-hover and element.focus() screenshots at 1440px — both show primary border+icon"
        status: pass
    human_judgment: false
  - id: D3
    description: "Header search control geometry unchanged: 44px x 44px, no shift to --pk-header-h or horizontal overflow at 481px/768px"
    requirement: "SHELL-01"
    verification:
      - kind: other
        ref: "awk-scoped greps: .pk-search-morph rule body contains exactly one height: 44px and one width: 44px declaration"
        status: pass
      - kind: automated_ui
        ref: "chromium headless screenshots at 768px and 481px viewport widths — single-line header, no clipped/overflowing content"
        status: pass
    human_judgment: false
  - id: D4
    description: "The isologo mark renders once per page (header only); the footer renders the wordmark+tagline lockup with no <img>"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#brand_logo/1 theme-aware isologo pair (260821-v7q) - the footer's .pk-footer-left cluster renders no mark (D-A, 260823-snj)"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#brand_logo/1 theme-aware isologo pair (260821-v7q) - the header still renders exactly two <img> marks (header-only, not removed, 260823-snj)"
        status: pass
      - kind: automated_ui
        ref: "chromium headless CDP screenshot scrolled to .pk-footer at 1440px, light and dark theme"
        status: pass
    human_judgment: false
  - id: D5
    description: "The footer's PUKLLAY CLUB wordmark renders at the same Bebas 24px size but in the muted/neutral colour tier, not matching the header's contrast"
    requirement: "SHELL-01"
    verification:
      - kind: other
        ref: "awk-scoped grep: .pk-brand-quiet .pk-brand-name rule resolves through var(--color-neutral)"
        status: pass
      - kind: automated_ui
        ref: "chromium headless CDP screenshot of .pk-footer at 1440px light and dark theme — wordmark visibly quieter than header, legible in both"
        status: pass
    human_judgment: false
  - id: D6
    description: "brand_logo/1's mark attr composes correctly: mark: false renders no <img> but keeps the wordmark and any passed tagline; the true default is byte-identical to prior behaviour"
    requirement: "SHELL-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#brand_logo/1 mark attr (260823-snj) - mark: false renders no <img> but still renders the wordmark"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#brand_logo/1 mark attr (260823-snj) - mark: false composes with a passed tagline"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/components/layouts_test.exs#brand_logo/1 mark attr (260823-snj) - mark: false emits pk-brand-quiet; the header default does not"
        status: pass
    human_judgment: false
  - id: D7
    description: "mix quality (7 steps) and mix compile --warnings-as-errors both pass clean"
    verification:
      - kind: other
        ref: "mix quality"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false

duration: 46min
completed: 2026-08-24
status: complete
---

# Quick Task 260823-snj: Polish Desktop Header, Improve the Search Summary

**Raised the header's search toggle from a 16px decorative glyph to a 44px bordered control (hover+keyboard focus parity, byte-identical geometry) and made the isologo mark header-only via a new `brand_logo/1` `mark` attr, demoting the footer's now-mark-free wordmark to the neutral colour tier.**

## Performance

- **Duration:** 46 min
- **Started:** 2026-08-23T23:25:00Z
- **Completed:** 2026-08-24T00:11:28Z
- **Tasks:** 3 (2 code tasks + 1 verification-only task)
- **Files modified:** 4

## Accomplishments

- Header search toggle icon swapped from `hero-magnifying-glass-micro`/`size-4` to `hero-magnifying-glass`/`size-5`, with `title="Buscar"` added alongside the existing `aria-label`
- `.pk-search-morph` resting state gained a real `base-100` fill + `base-300` border (was fully transparent); `.pk-search-morph-toggle` resting colour raised from `neutral` to `base-content`
- Hover AND `:focus-within` (not hover-only) now drive both the border and the glyph to `primary`, at byte-identical 44px x 44px geometry
- `brand_logo/1` gained a `mark` attr (default `true`); the header keeps the default (renders the isologo pair), the footer passes `mark={false}` (renders wordmark + tagline only, no `<img>`) — the isologo now appears exactly once per page
- `mark={false}` adds a `pk-brand-quiet` class that demotes the footer's `PUKLLAY CLUB` wordmark to `var(--color-neutral)`, keeping the same Bebas 24px size (no new type-inventory combo)
- `ui-design-system`'s `brand_logo/1` component-inventory row documents the new `mark` attr

## Task Commits

Each task was committed atomically:

1. **Task 1: Raise the header search toggle from decoration to control** - `8356543` (feat)
2. **Task 2: Make the isologo mark header-only and quiet the footer wordmark** - `b98e229` (feat)
3. **Task 3: Full quality gate and desktop visual confirmation** - verification only, no code changes; no separate commit

## Files Created/Modified

- `lib/pukllay_club_web/components/layouts.ex` - header search icon/title swap; `brand_logo/1` gains `mark` attr, `pk-brand-quiet`/`pk-brand-name` hooks, updated `@doc`; footer call site passes `mark={false}`
- `assets/css/app.css` - `.pk-search-morph` resting fill/border, `.pk-search-morph-toggle` resting colour, hover+focus-within border rule, `.pk-brand-quiet .pk-brand-name` colour-demotion rule
- `test/pukllay_club_web/components/layouts_test.exs` - 3 new search-morph tests (Task 1), 2 inverted footer-mark tests + 4 new tests (Task 2)
- `.claude/skills/ui-design-system/SKILL.md` - `brand_logo/1` inventory row documents the `mark` attr

## Decisions Made

- D-A (plan-authored, applied as written): the isologo mark is header-only; the footer gives it up since the header alone carries the brand at 481-767px
- D-B (plan-authored, applied as written): footer wordmark demoted by colour (`neutral` token), not by shrinking size, to keep the catalogue's type inventory at its existing 3-tier cap

## Deviations from Plan

None - plan executed exactly as written. Task 3's environment setup required starting a dev server from this worktree on `PORT=4001` (the port-4000 server already running on the machine was serving the main checkout's stale code, not this worktree's changes) — a read-only, in-scope environment step, not a plan deviation.

## Issues Encountered

- This worktree's branch (`worktree-agent-a70589b7a995fd622`) was 304 commits behind the repo's current `main` tip when execution started (last synced at Phase 0 completion, long before the plan file or the current `layouts.ex`/`app.css` even existed in this worktree). Resolved via `git merge --ff-only main` — safe because the worktree branch had zero commits of its own that weren't already in `main` (`git rev-list --count main..HEAD` = 0), so the fast-forward could not lose any work.
- No MCP browser-automation tool (e.g. `claude-in-chrome`) was available in this execution context. Built a small ~90-line Node script (`cdp_shot.mjs`, scratchpad-only, not committed) driving the system's `google-chrome --headless=new --remote-debugging-port` binary directly over the Chrome DevTools Protocol using Node 22's built-in `fetch`/`WebSocket` globals (no npm install). Used it to capture real screenshots — resting/hover/focus states, light and dark theme, and all three breakpoints (1440/768/481px) — providing genuine pixel-level confirmation of Task 3's `<human-check>` criteria rather than a structural-only proxy. The headless Chrome instance used its own isolated profile (confirmed via a distinct, independently-killable PID; the user's pre-existing desktop Chrome session and its tabs were never touched). All screenshot/server processes were torn down after verification (dev server on port 4001, headless Chrome on port 9333) — nothing was left running.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Both developer-raised complaints (decorative search icon, doubled isologo mark) are resolved and verified pixel-for-pixel at the three breakpoints identified in the plan, in both light and dark theme.
- `mix quality` (7 steps) and `mix compile --warnings-as-errors` both pass clean on the final state.
- No blockers for Phase 2 (Natural-Language Spanish Search + Auth) — this was a shell-scoped (SHELL-01) polish task with no schema, dependency, or architectural changes.

## Self-Check: PASSED

All 5 claimed files exist on disk; both commit hashes (`8356543`, `b98e229`) resolve in `git log --all`.

---
*Phase: quick-260823-snj*
*Completed: 2026-08-24*
