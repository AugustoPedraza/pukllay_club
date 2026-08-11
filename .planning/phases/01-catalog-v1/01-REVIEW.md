---
phase: 01-catalog-v1
reviewed: 2026-08-11T00:00:00Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - config/dev.exs
  - config/dev.secret.exs.example
  - config/prod.exs
  - config/runtime.exs
  - config/test.exs
  - lib/mix/tasks/catalog.seed.ex
  - lib/pukllay_club/catalog.ex
  - lib/pukllay_club/catalog/game.ex
  - lib/pukllay_club/catalog/seed/bgg_client.ex
  - lib/pukllay_club/catalog/seed/credentials.ex
  - lib/pukllay_club/catalog/seed/csv_import.ex
  - lib/pukllay_club/catalog/seed/hashtag_normalizer.ex
  - lib/pukllay_club/catalog/seed/image_pipeline.ex
  - lib/pukllay_club/catalog/seed/r2_storage.ex
  - lib/pukllay_club/catalog/seed/report.ex
  - lib/pukllay_club/catalog/seed/storage.ex
  - lib/pukllay_club/catalog/vocabulary.ex
  - lib/pukllay_club_web/components/carousel_row.ex
  - lib/pukllay_club_web/components/core_components.ex
  - lib/pukllay_club_web/components/filter_drawer.ex
  - lib/pukllay_club_web/components/game_card.ex
  - lib/pukllay_club_web/components/game_chips.ex
  - lib/pukllay_club_web/components/layouts.ex
  - lib/pukllay_club_web/components/layouts/root.html.heex
  - lib/pukllay_club_web/csp.ex
  - lib/pukllay_club_web/live/catalog_live/index.ex
  - lib/pukllay_club_web/live/catalog_live/show.ex
  - lib/pukllay_club_web/router.ex
  - priv/repo/migrations/20260806234228_create_games.exs
  - priv/repo/migrations/20260810172415_add_games_search_and_indexes.exs
  - .sobelow-conf
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-08-11
**Depth:** standard
**Files Reviewed:** 30
**Status:** issues_found

## Summary

Phase 1 (catalog-v1) is a large, well-documented body of work: a credential-resolution seam, a
BGG-enrichment/image/R2 seed pipeline, a Postgres `tsvector` search+GIN index setup, and a full
LiveView browse/filter/detail experience. The Ecto query layer is consistently disciplined about
parameterization (`^` pins throughout, no string-built SQL), the seed pipeline's SSRF/XSS/DoS
mitigations (host allowlist, download-size cap, `dtd: :none`, `redacted/1`) are real and correctly
wired, and the data-quality handling (D-18/D-19/D-20) is unusually thorough for a one-time script.

The one blocking issue found is a genuine, high-confidence functional regression: the
Content-Security-Policy shipped in this phase (`lib/pukllay_club_web/csp.ex`) sets
`script-src 'self'` with no `'unsafe-inline'`/nonce/hash, which silently disables both the
pre-existing theme-toggle inline `<script>` in `root.html.heex` and the phase's own new
`onerror` broken-image fallback in `GameCard` — neither can execute in a CSP-enforcing browser.
Unit tests only assert the header's string value, so this was never caught by any automated check.
The remaining findings are robustness/observability gaps in the seed task and the browse LiveView's
blanket exception-swallowing, plus two minor code-quality notes.

## Critical Issues

### CR-01: Content-Security-Policy blocks the app's own inline script and onerror handler

**File:** `lib/pukllay_club_web/csp.ex:19-34` (interacts with `lib/pukllay_club_web/components/layouts/root.html.heex:11-38` and `lib/pukllay_club_web/components/game_card.ex:47`)

**Issue:** `CSP.policy/0` emits `"script-src 'self'"` with no `'unsafe-inline'`, nonce, or hash
source. Two pieces of markup in this codebase depend on inline JavaScript executing:

1. `root.html.heex`'s `<head>` contains an inline `<script>` block (not `src=`-loaded) that reads
   `localStorage`, sets `data-theme`, and installs the `phx:set-theme` listener the theme-toggle
   buttons in `Layouts.theme_toggle/1` dispatch via `JS.dispatch("phx:set-theme")`. `assets/js/app.js`
   has no equivalent logic (verified: no `theme`/`set-theme` reference in `app.js`), so this inline
   block is the *only* implementation.
2. `GameCard.game_card/1`'s cover `<img>` carries an inline `onerror="this.style.display='none'; ..."`
   attribute — the moduledoc explicitly frames this as this phase's mechanism for degrading a failed
   image load to the brand placeholder.

Per the CSP spec (true since CSP Level 1), both classic inline `<script>` blocks and inline event
handler attributes (`onerror`, `onclick`, etc.) are governed by `script-src`, and are blocked by any
browser enforcing this header unless `'unsafe-inline'` (or a matching nonce/hash) is present. Since
`style-src` explicitly carries `'unsafe-inline'` in this same policy but `script-src` does not, this
reads as an oversight rather than an intentional hardening choice — the policy is internally
inconsistent with the markup it ships alongside.

**Effect once enforced by a real browser:** the theme toggle silently stops working entirely (no
console-visible app error, only a CSP violation report), and the broken-cover-image fallback this
same phase (01-06) added never fires — a failed image load leaves a broken `<img>` icon on screen
instead of degrading to the brand placeholder the design explicitly calls for. Neither regression is
caught by the existing test suite, because ExUnit/LazyHTML assertions on rendered markup cannot
detect that a browser would refuse to execute inline script.

**Fix:** Either move both scripts to an external `src=`-loaded file under `script-src 'self'` (cleanest —
matches how `app.js` is already loaded), or add a per-request nonce and apply it to both the `<script>`
tag and the `onerror` attribute (CSP3 also requires `'unsafe-hashes'` or a nonce for inline *event
handler* attributes specifically — moving the onerror to a small `assets/js/app.js` hook/event listener
avoids that extra complexity). Example external-script fix for the theme toggle:

```js
// assets/js/theme.js (loaded via <script defer src={~p"/assets/js/theme.js"}>)
(() => { /* existing IIFE body, unchanged */ })();
```

```heex
<img
  :if={@game.thumbnail_url}
  src={@game.thumbnail_url}
  alt={@game.name}
  loading="lazy"
  class="h-full w-full object-cover js-cover-fallback"
/>
```
```js
// assets/js/app.js
document.addEventListener("error", (e) => {
  if (e.target.matches?.(".js-cover-fallback")) {
    e.target.style.display = "none";
    e.target.nextElementSibling?.classList.remove("hidden");
  }
}, true);
```

Whichever approach is taken, add a real browser-level regression check (e.g. Wallaby/Playwright, or
at minimum a manual verification step in the phase checkpoint) — a header-value assertion alone
cannot catch this class of bug.

## Warnings

### WR-01: `Mix.Tasks.Catalog.Seed.classify_weight/4`'s case is not exhaustive over its own two independently-computed inputs

**File:** `lib/mix/tasks/catalog.seed.ex:114-136` (see also `lib/pukllay_club/catalog/seed/hashtag_normalizer.ex:78-88,116-124`)

**Issue:** `classify_weight/4` branches on `{true_count, resolution}` where `true_count` comes from
the mix task's own `weight_hashtag_true_count/1` and `resolution` comes from
`HashtagNormalizer.resolve_weight_band/1` — two separately-implemented traversals of the same three
weight-hashtag columns that happen to agree today only because both apply the same `truthy?/1`
predicate over the same column list. The `case` only covers `{1, {:ok, _, :hashtag}}`,
`{count>=2, {:ok, _, :peso_tie_break}}`, `{0, {:ok, _, :peso_tie_break}}`,
`{count>=2, {:unresolved, :conflict}}`, and `{0, {:unresolved, :missing}}`. There is no clause for
`{1, {:ok, _, :peso_tie_break}}`, `{1, {:unresolved, _}}`, or any other combination that would arise
if the two computations ever diverge (e.g. a future edit to one without the other, or a code path
that reorders/filters `@weight_columns` differently). Every other malformed-data scenario in this
same module degrades to a `Report` entry for manual review; this one would instead raise
`CaseClauseError` inside `Enum.map_reduce/3` and abort the entire 434-row run with no report written
for any row processed so far in that batch.

**Fix:** Either compute `true_count` from the same `true_bands` list `resolve_weight_band/1` already
derives (return it alongside the resolution, or expose a single function that returns both), or add a
catch-all clause that reports the row as unresolved instead of letting the case fail:

```elixir
{_count, resolution} ->
  finding = %{row: row_number, name: name, resolution: "unexpected combination: #{inspect(resolution)}"}
  {nil, Report.add(report, :weight_conflicts, finding)}
```

### WR-02: `parse_int/1` in the seed task crashes the whole run on a non-numeric, non-blank cell

**File:** `lib/mix/tasks/catalog.seed.ex:171-177`

**Issue:** `BGG_ID` and `Unidades` values are parsed with:

```elixir
defp parse_int(nil), do: nil

defp parse_int(value) do
  case String.trim(value) do
    "" -> nil
    trimmed -> String.to_integer(trimmed)
  end
end
```

Unlike every other real-data quirk this module handles (hashtag typos, weight conflicts, missing
BGG ids, duplicate BGG ids — all logged to `Report` rather than raised), a stray non-numeric,
non-blank value in either column (e.g. a data-entry artifact like `"12,5"` or `"N/A"`) makes
`String.to_integer/1` raise `ArgumentError`, aborting the entire `mix catalog.seed` run rather than
being surfaced in `catalog_seed_report.md` for review like every other cell-level anomaly.

**Fix:** Mirror the tolerant pattern already used for `Peso_BGG` parsing elsewhere in this codebase
(`HashtagNormalizer.parse_peso/1`'s `Float.parse` + `:error` fallback):

```elixir
defp parse_int(value) do
  case value |> String.trim() |> Integer.parse() do
    {int, ""} -> int
    _ -> nil
  end
end
```
and, ideally, add a `Report` entry when the fallback fires so an unparseable cell is visible in the
manual-review output rather than silently becoming `nil`.

### WR-03: `CatalogLive.Index.safe_filter_games/1` swallows every exception with no logging

**File:** `lib/pukllay_club_web/live/catalog_live/index.ex:199-203`

**Issue:**

```elixir
defp safe_filter_games(opts) do
  {:ok, Catalog.filter_games(opts)}
rescue
  _error -> :error
end
```

This is used by both `apply_filters/1` (every filter-changing event) and the `"load-more"` handler.
The intent (T-01-24: degrade to the UI-SPEC error banner instead of crashing on a crafted/oversized
scalar) is sound, but the exception term is discarded entirely — nothing is logged. A genuine
application bug (e.g. a future filter option that produces an invalid query, an Ecto/Postgrex
regression, a real outage) degrades to the same generic "no pudimos cargar el catálogo" banner as a
malicious request, with zero telemetry to distinguish the two in production. This directly
contradicts the ability to diagnose the very failure mode this code exists to handle gracefully.

**Fix:**

```elixir
defp safe_filter_games(opts) do
  {:ok, Catalog.filter_games(opts)}
rescue
  error ->
    Logger.warning("Catalog.filter_games/1 failed", opts: inspect(opts), error: Exception.format(:error, error, __STACKTRACE__))
    :error
end
```
(requires `require Logger` at the top of the module).

### WR-04: CSP `connect-src` uses bare `ws:`/`wss:` scheme sources, which match any origin

**File:** `lib/pukllay_club_web/csp.ex:27`

**Issue:** `"connect-src 'self' ws: wss:"` — a bare-scheme CSP source expression (`ws:`, `wss:` with
no host) matches a WebSocket connection to **any** host using that scheme, not just the app's own
origin. Per the CSP3 "self" source matching algorithm, `'self'` already covers same-origin
`ws:`/`wss:` upgrades from `http:`/`https:` for `connect-src`, so the extra bare-scheme entries are
almost certainly unnecessary and meaningfully widen the policy: if an XSS vector is ever introduced
elsewhere in the app, this directive would let injected script open a WebSocket to an
attacker-controlled host for data exfiltration — exactly the class of attack a CSP is meant to
constrain.

**Fix:** Drop the bare schemes and rely on `'self'`, verifying the LiveView websocket still connects:

```elixir
"connect-src 'self'",
```
If `'self'` genuinely proves insufficient in some deployment topology (e.g. a separate WS host),
scope the source explicitly to that host/scheme rather than to the bare scheme.

## Info

### IN-01: `select_cover/1` is computed twice per enriched row

**File:** `lib/mix/tasks/catalog.seed.ex:282-294`, `lib/pukllay_club/catalog/seed/image_pipeline.ex:69-91`

**Issue:** `image_urls/4` calls `ImagePipeline.select_cover(item)` once to get the cover URL, then
calls `ImagePipeline.process_gallery(item, key_prefix, credentials)`, which internally calls
`select_cover(item)` again to determine which version image to exclude from the gallery. The
function is pure/deterministic so this isn't a correctness bug, just redundant work and a minor
readability cost (a reader has to confirm both calls really do agree).

**Fix:** Have `image_urls/4` pass the already-resolved `cover_source_url` into `process_gallery/4`
(new arity) instead of recomputing it.

### IN-02: `HashtagNormalizer.truthy?/1`'s name invites misuse as a boolean in `if`

**File:** `lib/pukllay_club/catalog/seed/hashtag_normalizer.ex:55-65`

**Issue:** `truthy?/1` returns `true | false | {false, {:unrecognized, value}}`. Every current call
site correctly guards with `== true`, but in Elixir only `nil` and `false` are falsy — a 2-tuple like
`{false, {:unrecognized, "di"}}` is truthy. A future caller who writes `if HashtagNormalizer.truthy?(v)`
(reasonable given the `?`-suffixed, boolean-sounding name) would silently treat an unrecognized cell
as `true`. Not exploitable today — every existing call site is correct — but it's a footgun baked
into the public API shape.

**Fix:** Rename to something that signals the three-way return (e.g. `classify_cell/1`), or split
into a strict `truthy?/1 :: boolean()` plus a separate `unrecognized_value/1 :: String.t() | nil`
so the boolean-sounding name only ever returns a boolean.

---

_Reviewed: 2026-08-11_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
