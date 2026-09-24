# API Coverage — Phase 01.8.3

No external API integration: this phase is a pure UI refactor of `/admin/juegos` (HEEx render block,
Juegos-scoped CSS, one client scroll hook, tests) around the **already-built** BGG path
(`Catalog.add_game_from_bgg/2` → `Game.draft_changeset/2` → `Workers.EnrichGameWorker` →
`{:game_enriched, id}` PubSub), adding no new endpoint, verb, SDK surface or outbound HTTP call.

## Detector record

- `api-coverage.cjs --json` over the phase scope (ROADMAP § Phase 01.8.3, no PLAN.md existing at
  detection time) returned `{"detected": false, "signals": []}` — 2026-09-24.
- The scope text mentions BGG only as the *existing* create path the `+` sheet wraps. Re-read of the
  phase scope confirms the negative verdict rather than overriding it: RESEARCH.md § Architectural
  Responsibility Map assigns "the actual insert + Oban enqueue already lives in `Catalog`, untouched
  by this phase", and RESEARCH.md § Package Legitimacy Audit records "Not applicable — this phase
  adds no new dependency".
- This declaration is recorded (rather than the checkpoint being silently skipped) because the
  seal-time gate re-runs the detector over a scope that will then include this phase's PLAN.md
  bodies, which do name BGG. A reasoned declaration is accepted in place of a matrix.

No capability matrix is fabricated: there is no external capability surface in this phase to
enumerate, and inventing rows for `Catalog.add_game_from_bgg/2` would misrepresent an internal
function as an integration decision.
