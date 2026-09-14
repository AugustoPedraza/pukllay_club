---
title: Saturday sessions tracking + fully managed carousels
trigger_condition: After the Staff Admin phase ships (staff auth, shelf locations, curated Destacados are live)
planted_date: 2026-09-13
---

# Saturday sessions + fully managed carousels

## Saturday sessions

If Saturday attendees start using the app, turn rental tracking (Phase 4) into a session model:

1. A **session** = a Saturday date.
2. Members **request** games for that session (requires member auth — Phase 2).
3. Staff **confirm** the bring-list.
4. Staff mark games **packed** (using the shelf-sorted pick list) and later **returned**.

Builds directly on shelf locations from the Staff Admin phase — locations drive the pick and
restore lists.

## Fully managed carousels (Option B)

Evolve from "only the first slot is curated" to every row being managed:
- Reorder / hide / rename any row.
- Each row is either **hand-picked** (ordered game list) or **automatic** (hashtag or
  weight-band rule, like today's `Catalog.carousel_row_specs/0`).
- Optional **date windows** (e.g. "Juegos de Spiel" visible Oct 20 – Nov 30, then auto-hides).

See `.planning/notes/staff-admin-decisions.md`.
