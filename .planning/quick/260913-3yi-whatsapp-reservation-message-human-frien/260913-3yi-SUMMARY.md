---
phase: quick-260913-3yi
plan: 01
subsystem: ui
tags: [phoenix, liveview, whatsapp, wa.me, uri-encoding, phoenix-param]

requires:
  - phase: quick-260913-2x6
    provides: "Game's id-slug URL contract (/juegos/{id}-{slug}) via Phoenix.Param, reused here for the wa.me message"
provides:
  - "reservation_message/2 and reservation_url/3 taking the %Game{} struct, producing a friendlier first-person wording plus the game's id-slug URL"
  - "Mobile-legible reservation modal preview (whitespace-pre-line + break-words)"
affects: [catalog_live_show, whatsapp_reservation_flow]

actuals:
  tokens: 1279
  tasks: 2
  commits: 3
  plan_head_before: 52541c0

tech-stack:
  added: []
  patterns:
    - "reservation_message/2 builds the id-slug game URL server-side via url(~p\"/juegos/#{game}\"), the same Phoenix.Param idiom share_control/1 already used"

key-files:
  created: []
  modified:
    - lib/pukllay_club_web/live/catalog_live/show.ex
    - test/pukllay_club_web/live/catalog_show_test.exs

key-decisions:
  - "reservation_message/2 and reservation_url/3 now take the Game struct (not the bare name) so the URL can be built inside the message helper itself, keeping the id-slug idiom in one place"
  - "Whole message (name + quoted game name + newline + URL) stays percent-encoded via a single URI.encode_www_form/1 call over the concatenated string — no partial encoding"

patterns-established:
  - "Preview text that must render a literal newline in HEEx uses whitespace-pre-line + break-words rather than a second differently-formatted string"

requirements-completed: [QUICK-260913-3yi]

coverage:
  - id: D1
    description: "WhatsApp reservation message reads ¡Hola! Soy {name}. Me gustaría reservar \"{game}\" para el próximo sábado en el club. + blank line + the id-slug game URL, fully percent-encoded"
    requirement: "QUICK-260913-3yi"
    verification:
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#reservation flow (SHELL-03, T-01.1-02) the reservation message asks the club to set the game up on-site — never to lend or hand it over (D-09)"
        status: pass
      - kind: unit
        ref: "test/pukllay_club_web/live/catalog_show_test.exs#reservation flow (SHELL-03, T-01.1-02) the visitor's name and the game's name are percent-encoded in the wa.me link — no raw space or accented character survives"
        status: pass
    human_judgment: false
  - id: D2
    description: "Modal preview renders the message legibly on mobile (URL on its own line, no horizontal overflow)"
    verification: []
    human_judgment: true
    rationale: "Visual/mobile-legibility claim (whitespace-pre-line + break-words rendering) requires a real narrow-viewport visual check; not exercised by ExUnit's HTML assertions"

duration: 20min
completed: 2026-09-13
status: complete
---

# Phase quick-260913-3yi: WhatsApp Reservation Message Summary

**Reservation wa.me message rewritten to first-person "Me gustaría reservar" wording with the quoted game name and its id-slug URL appended, fully percent-encoded end to end.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-13T05:35:00Z (approx)
- **Completed:** 2026-09-13T05:57:03Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- `reservation_message/2` / `reservation_url/3` now take the `%Game{}` struct and build the message as `¡Hola! Soy {name}. Me gustaría reservar "{game_name}" para el próximo sábado en el club.` + blank line + `url(~p"/juegos/#{game}")` (the same id-slug idiom `share_control/1` already used, quick task 260913-2x6)
- Both modal call sites (preview `<p>` and `<a href>`) pass `@game` instead of `@game.name`
- The entire message — name, quoted game name, newline, URL — stays percent-encoded via a single `URI.encode_www_form/1` call (T-01.1-02); D-09's on-site framing (never lending/renting) is preserved
- Modal preview gained `whitespace-pre-line break-words` so the appended URL renders on its own line and cannot overflow a narrow mobile screen
- Comments above both helpers rewritten to describe the new signature/wording without quoting the old message text

## Task Commits

Each task was committed atomically (TDD tracer task produced 2 commits):

1. **Task 1: End-to-end new reservation message with id-slug URL** - `2a7579c` (test, RED) + `16d2bf5` (feat, GREEN)
2. **Task 2: Mobile-legible preview, refreshed comments, quality gates** - `d5da6a9` (style)

## Files Created/Modified
- `lib/pukllay_club_web/live/catalog_live/show.ex` - `reservation_message/2`/`reservation_url/3` take `%Game{}`, new wording + appended id-slug URL, modal call sites pass `@game`, preview `<p>` gains `whitespace-pre-line break-words`, refreshed comments
- `test/pukllay_club_web/live/catalog_show_test.exs` - Rewritten D-09 test decodes the wa.me `text=` query and asserts the new wording + id-slug URL on its own line; percent-encoding test extended with a raw-newline refute

## Decisions Made
- Kept `reservation_url/3`'s arity unchanged (arg 3 changed type from name string to `Game` struct, not a new arg) — no call-site signature growth
- Built the id-slug URL inside `reservation_message/2` (not passed in separately) since the URL is derived purely from `game`, keeping `reservation_url/3` a thin encode-and-wrap wrapper

## Deviations from Plan

None - plan executed exactly as written (TDD RED → GREEN in Task 1, encoding/comments/format in Task 2, both per the plan's own locked wording and id-slug idiom).

## Issues Encountered
None - `mix format`, `mix credo --strict`, and the full `catalog_show_test.exs` suite (222 tests) passed clean on first run after implementation; no Styler rewrites beyond the intended edits.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- No blockers. The reservation flow's wa.me link now carries the same id-slug URL contract as `share_control/1`, the canonical link, sitemap, and JSON-LD (quick task 260913-2x6) — one consistent URL form across the whole app.
- D2 (mobile preview legibility) is a visual claim covered by Tailwind utility classes but not independently browser-verified in this session; flagged for a quick visual spot-check if/when this modal is next touched.

---
*Phase: quick-260913-3yi*
*Completed: 2026-09-13*

## Self-Check: PASSED

All created/modified files found on disk; all 3 commits (2a7579c, 16d2bf5, d5da6a9) found in git log.
