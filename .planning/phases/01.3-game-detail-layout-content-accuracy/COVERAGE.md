# Phase 01.3 — External API Coverage Decision Matrix

**Produced:** 2026-08-29 (plan-phase)
**Gate:** `api-coverage.verify-pre` — a malformed/partial matrix blocks the phase seal.
**Rule:** Full coverage by default. Every capability starts as `INTEGRATE`; every `OPT-OUT` carries
a one-line reason. Rows are never omitted — an un-enumerated capability is an invisible hole.

## Detector note

The detector fired on a `hex.pm/api/packages/instructor_lite` URL fragment in 01.3-RESEARCH.md — a
false-positive trigger on its own, but the phase genuinely does integrate one new external service
(Gemini, via `InstructorLite`) and extends field extraction on one already-integrated service (BGG
XML API 2). Both are covered below rather than opted out wholesale.

External services touched this phase:

1. **Gemini (via `InstructorLite` + `InstructorLite.Adapters.Gemini`)** — NEW this phase. One-off
   Spanish-translation task for `Game.description` (D-01), run at seed/enrichment time only, never on
   the request hot path.
2. **BoardGameGeek XML API 2** — NOT a new integration. Already fully decided in
   `../01-catalog-v1/01-COVERAGE.md` §1a, where `stats=1` (`averageweight`, `average`, `usersrated`,
   `bayesaverage`, `ranks`) was marked `INTEGRATE` and the response is already fetched per game. This
   phase only completes the field-level extraction of two attributes (`average`, `ranks`) that the
   parameter was already integrated for but `BggClient` never actually parsed out (D-06). No new BGG
   capability decision is being made — see note below instead of a re-litigated matrix.

---

## 1. Gemini (via `InstructorLite`)

`InstructorLite` is a thin structured-output wrapper, not a full product SDK — its "capability
surface" for this integration is the set of Gemini/LLM call shapes it exposes, not a REST resource
tree. Enumerated below at that level.

| Capability | Decision | Rationale |
|-----------|----------|-----------|
| Structured single-turn text generation with `response_model` (Ecto schema) + `json_schema` | **INTEGRATE** | Core of D-01: one `InstructorLite.instruct/2` call per game, `adapter: InstructorLite.Adapters.Gemini`, validates the Spanish translation against an Ecto changeset before it's ever stored. |
| API key via `adapter_context: [api_key: ...]`, sourced from `Credentials.gemini_api_key` | **INTEGRATE** | Required to authenticate every call; must follow the existing `Credentials` module's env-var-first pattern (already used for `bgg_api_token`), not a new parallel secrets convention. |
| Retry/error handling on translation failure (keep existing English text) | **INTEGRATE** | Explicit fallback behavior locked in the Validation Strategy (`01.3-VALIDATION.md`) — a failed/malformed LLM response must not blank out or corrupt the existing description. |
| Streaming responses | **OPT-OUT** | Not needed — this is an offline/batch Mix task, not an interactive UI, so there is no partial-output consumer. |
| Function calling / tool use | **OPT-OUT** | Not needed — a single translation call with a fixed input/output shape, no multi-step tool orchestration. |
| Vision / multimodal input (image understanding) | **OPT-OUT** | Not needed — the translation input is plain text (`description`), no image analysis is in scope this phase. |
| Embeddings generation | **OPT-OUT** | Explicitly out of scope for this phase — reserved for Phase 2's NL-search feature per `PROJECT.md`'s AI/Search Stack (Bumblebee/local embeddings, a different mechanism entirely from InstructorLite/Gemini). |
| Safety settings / content-filter tuning | **OPT-OUT** | Not needed yet — BGG descriptions are curated third-party content, not arbitrary user input; default Gemini safety settings are sufficient for this narrow, low-risk use case (also see Prompt Injection note in `01.3-VALIDATION.md`'s Security Domain). |
| Conversation/multi-turn context (chat history) | **OPT-OUT** | Not applicable — each translation call is stateless and independent, one game at a time. |
| Rate-limit-aware batching/backoff tuned to a specific RPM/RPD number | **OPT-OUT (deferred)** | `01.3-RESEARCH.md` Assumption A1 flags Gemini free-tier RPM/RPD as LOW confidence (conflicting third-party sources, no authenticated dashboard read). ~400 one-off calls run manually over multiple sessions is very unlikely to hit any plausible limit; the planner should not hard-code a specific sleep/batch interval without checking `aistudio.google.com/rate-limit` at implementation time. A simple sequential run (no aggressive concurrency) is sufficient for this phase's scale. |

---

## 2. BoardGameGeek XML API 2 — extraction completion, not a new decision

No new capability matrix is produced for BGG. The relevant capability (`stats=1` →
`average`/`ranks`) was already decided `INTEGRATE` in Phase 1's `01-COVERAGE.md` §1a — the response
was already being fetched with these fields present in the raw XML, they were simply never parsed
into `BggClient`'s output map. This phase adds the two missing XPath extractions
(`.//statistics/ratings/average/@value`, `.//statistics/ratings/ranks/rank[@name='boardgame']/@value`)
to `parse_items/1`, reusing the same already-hardened parsing path (`dtd: :none`, no new attack
surface — see `01.3-RESEARCH.md` Security Domain V5).

This phase also runs a full re-enrichment pass against BGG for all ~400 games to populate these two
new fields for existing rows. This reuses `BggClient.fetch_batch/2` (Phase 1's already-`INTEGRATE`d
batched `id=` lookup capability) — not a new endpoint or parameter, a re-run of the existing one.

---

## Seal-time checklist

- [ ] Every `INTEGRATE` row above (Gemini section) has a corresponding implementation in a Phase 01.3 plan.
- [ ] Every `OPT-OUT` row carries a reason (verified above — no bare omissions).
- [ ] The Gemini rate-limit deferral note has been read by the developer before running the full ~400-game translation batch.
