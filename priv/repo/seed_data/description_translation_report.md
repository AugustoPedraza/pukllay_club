# Description Translation Report

Run window: 2026-08-30T23:53:30Z - 2026-08-31T00:09:22Z
Model: gemini-3.5-flash-lite

The batch was split across four separate `mix catalog.translate_descriptions`
invocations to stay within tool/session time limits and to work around a
resumability bug discovered and fixed mid-run in `--only-english`'s
candidate filter (see `01.3-04-SUMMARY.md`, Deviations). Each invocation
overwrites this file with its own numbers only, so the counts below are
manually consolidated across all four real invocations against the live
catalog (`pukllay_club_dev`) — this is the single reviewable record for the
whole run, not just the final invocation.

- Attempted: 385 (every game whose `bgg_payload` carries an English description)
- Translated: 384
- Failed: 1

## Run breakdown

| Invocation | Flags | Attempted | Translated | Failed |
|---|---|---|---|---|
| 1 | `--limit 60` | 60 | 60 | 0 |
| 2 | `--only-english --limit 150` (found 111 real candidates) | 111 | 111 | 0 |
| 3 | `--only-english` (post-fix, all remaining) | 214 | 213 | 1 |
| 4 | `--only-english` (retry of the id-252 failure) | 1 | 0 | 1 (same game, same reason) |
| **Total (unique games)** | | **385** | **384** | **1** |

## Failures

- id 252 (Mysterium): Gemini's `gemini-3.5-flash-lite` returned
  `finishReason: "RECITATION"` — its own content-safety filter refused to
  generate a translation, citing possible resemblance to existing
  copyrighted material (BGG's official Mysterium description, likely
  drawn closely from the publisher's own marketing copy). Reproduced
  identically on a same-prompt retry (invocation 4), confirming this is a
  deterministic content-policy block for this specific text, not a
  transient sampling issue a blind retry would clear. Per this job's
  designed per-game-failure behavior, id 252's `description` was left
  completely untouched by both attempts — it still holds its original
  English text (with its original, never-cleaned HTML entities), exactly
  as it held before this run. No description was blanked or corrupted.
