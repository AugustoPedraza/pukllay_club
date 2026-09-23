---
phase: quick-260922-tum
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - test/support/fixtures/bgg_thing_with_versions.xml
  - test/pukllay_club/catalog/seed/bgg_client_test.exs
  - lib/pukllay_club/catalog/seed/bgg_client.ex
  - lib/pukllay_club/catalog/seed/stats_enricher.ex
  - test/pukllay_club/catalog/seed/stats_enricher_test.exs
  - lib/pukllay_club_web/game_text.ex
  - priv/repo/seed_data/bgg_stats_enrichment_report.md
autonomous: true
requirements: [QUICK-260922-TUM-01]

user_setup:
  - service: boardgamegeek
    why: "Task 3 re-fetches all ~386 enriched rows from BGG's live xmlapi2; Credentials.fetch!/0 hard-requires the token."
    env_vars:
      - name: BGG_API_TOKEN
        source: "The same value already used for prior `mix catalog.enrich_bgg_stats` runs (BGG account / project secret store). NOT set in the planning shell — confirm before Task 3."

estimate:
  tokens: 55000
  raw_tokens: 55000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "A BGG `/thing?versions=1` response parses so that `publishers` and `artists` carry ONLY the top-level `<item>`'s own link values — every link belonging to a nested `<item type=\"boardgameversion\">` is excluded, proven by a fixture whose version items deliberately carry publisher/artist/name links that must not appear in the parsed result."
    - "All six top-level link extractions in `parse_items/1` are direct-child scoped, matching the scoping fix already applied to the item selector itself (`/items/item`, not `//item`) when `versions=1` was introduced — the link selectors were missed by that same fix."
    - "`mix catalog.enrich_bgg_stats` actually repairs `games.publishers`: the column is added to `StatsEnricher.update_game_stats/2`'s cast allowlist alongside the `:artists` entry already there, so re-enrichment writes the corrected list instead of leaving the contaminated one in place."
    - "After the dev re-enrich, the freshly-measured dev `games` publisher-length distribution collapses: zero rows exceed 25 publishers (baseline measured at planning time: 366 of 386 payload-bearing rows exceeded 5, worst row 178)."
    - "`games.mechanics`, `games.themes` and `games.designers` are shown by measurement to be unaffected by the defect, so the fix is provably scoped to `artists`/`publishers` rather than assumed to be."
    - "The falsified claim in `dedup_artists/1`'s `@doc` — that the artist duplication is a property of BGG's artist data and NOT an xpath-scoping bug — is corrected in place, and `GameText`'s 'this catalog's own publisher lists are short' rationale is re-grounded on the repaired data."
    - "The production database is never contacted: every write in this plan lands in `pukllay_club_dev` only, verified by asserting the connected database name before the live run."
  artifacts:
    - test/support/fixtures/bgg_thing_with_versions.xml
    - test/pukllay_club/catalog/seed/bgg_client_test.exs
    - lib/pukllay_club/catalog/seed/bgg_client.ex
    - lib/pukllay_club/catalog/seed/stats_enricher.ex
    - priv/repo/seed_data/bgg_stats_enrichment_report.md
  key_links:
    - "`BggClient.parse_items/1` link scoping -> `item.publishers` -> `StatsEnricher.update_game_stats/2` cast allowlist -> `games.publishers` -> `GameText.editorial_text/1` -> `GameText.cover_alt/1` -> the `alt`/`aria-label` string on every catalog cover (GameCard, GamePreview). A 178-entry publisher array is currently read out verbatim by screen readers."
    - "`BggClient.parse_items/1` -> `item.artists` -> `bgg_payload[\"artists\"]` -> `StatsEnricher.backfill_artists_from_payload/1` / `mix catalog.backfill_artists`. Both consume the payload written here, so the payload must be corrected at the source, not patched downstream."
---

<objective>
Fix the xpath-scoping defect in `PukllayClub.Catalog.Seed.BggClient.parse_items/1` that folds
every nested `<item type="boardgameversion">`'s own `<link>` elements into the top-level game's
`publishers` and `artists` lists, then re-enrich the **dev** catalog so the corrected values
land in the database.

Purpose: `games.publishers` is user-visible. `GameText.cover_alt/1` builds every catalog cover's
`alt` / `aria-label` as `"Portada de {name}, editado por {every publisher joined with ', '}"`.
Rows currently carry up to 178 publishers, so a screen reader announces a 178-name list for one
cover image. `games.artists` is contaminated with version box-artists the base game never had.

Output: a scoped `parse_items/1`, a regression fixture that carries a real `<versions>` block
(no existing fixture does — which is exactly why this survived), a widened re-enrichment write
allowlist, and a repaired dev database.

## Grounding: what was measured at planning time (2026-09-22)

Read these as the *reason* for the plan, not as authority for its verification. Task 3 measures
its own baseline before writing; do not trust the numbers below as a before-state.

Against `pukllay_club_dev` (386 rows with a `bgg_payload`):

| observation | value |
|---|---|
| `corr(len(payload.versions), len(payload.publishers))` | **0.956** |
| `corr(len(payload.versions), len(payload.designers))` | -0.049 |
| rows with `len(games.publishers) > 5` | 366 of 386 |
| worst `len(games.publishers)` | 178 |
| rows with `len(games.mechanics) > 20` | 0 |
| rows with `len(games.designers) > 4` | 2 |

And decisively, `bgg_payload->'publishers'` for *When I dream* (bgg_id 198454, 23 versions) is
47 entries: 17 distinct names in BGG document order, followed by 30 entries that repeat those
same names — one group per version item. `"Repos Production"` alone appears 11 times.

## Correcting the record

`bgg_client.ex`'s `dedup_artists/1` `@doc` currently asserts: *"the sibling `designers`
extraction — using the exact same xpath shape — has zero duplicates. This is a property of
BGG's artist link data, not an xpath-scoping bug."* That inference is wrong. `designers` is
clean not because the xpath is sound but because BGG's version items carry
`boardgameartist`, `boardgamepublisher` and `language` links — and no designer link. The
selector is equally unscoped for both; only one link type happens to collide. The comment at
`parse_items/1` (lines 118-122) already documents this exact bug class for the *item* selector
(`/items/item`, not `//item`) when `versions=1` was added; the link selectors on the following
lines were never given the same treatment.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md

@lib/pukllay_club/catalog/seed/bgg_client.ex
@lib/pukllay_club/catalog/seed/stats_enricher.ex
@lib/mix/tasks/catalog.enrich_bgg_stats.ex
@lib/pukllay_club_web/game_text.ex
@test/pukllay_club/catalog/seed/bgg_client_test.exs
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Scope the link extractions to the item's own children, proven by a versions-bearing fixture</name>
  <files>test/support/fixtures/bgg_thing_with_versions.xml, test/pukllay_club/catalog/seed/bgg_client_test.exs, lib/pukllay_club/catalog/seed/bgg_client.ex</files>
  <read_first>
    - `lib/pukllay_club/catalog/seed/bgg_client.ex` lines 114-159 (`parse_items/1`) — the full
      extraction block, including the already-correct `/items/item` scoping comment and the
      nested `versions:` sub-block, whose `language` selector is already direct-child scoped.
    - `lib/pukllay_club/catalog/seed/bgg_client.ex` lines 172-190 — the `dedup_artists/1` `@doc`
      carrying the falsified claim.
    - `test/pukllay_club/catalog/seed/bgg_client_test.exs` — the `Req.Test.stub(BggClient, ...)`
      idiom every test uses, and the existing `item.artists == ["Duplicated Artist"]` assertion
      (line ~76), which asserts on a top-level triple-repeat in `bgg_unranked_item.xml` and must
      keep passing after the change.
    - `test/support/fixtures/bgg_thing_on_mars.xml` — the real captured response. Confirm for
      yourself that it contains no `<versions>` element at all, despite `do_request/4` sending
      `versions: 1` on every request. That gap between the request the client makes and the
      response the suite exercises is the reason no test caught this.
  </read_first>
  <behavior>
    RED first. Add one test to `bgg_client_test.exs` asserting, against a new fixture whose
    nested version items deliberately carry their own publisher, artist and primary-name links:

    - Test 1: `item.publishers` equals exactly the top-level item's own publisher link values,
      in document order — and contains none of the publisher names that appear only inside a
      version item.
    - Test 2: `item.artists` equals exactly the top-level item's own artist link values, with
      no version box-artist name present.
    - Test 3: `item.name` is the top-level item's primary name, not any version's primary name
      (give a version a different primary name so the assertion can actually fail).
    - Test 4: `item.versions` still parses — the version entries' own `name`, `image` and
      `languages` are unchanged by this fix. This is the guard against over-scoping.
    - Test 5: `item.designers` and `item.mechanics` are unchanged from what the fixture's
      top-level item declares (they were never colliding; prove the fix does not disturb them).

    These must fail before the source change and pass after.
  </behavior>
  <action>
    Build `test/support/fixtures/bgg_thing_with_versions.xml`. Prefer a real capture:
    `curl -s 'https://boardgamegeek.com/xmlapi2/thing?id=198454&stats=1&versions=1'` (BGG's
    public XML API 2 answers unauthenticated — the project's Bearer header is additive, so no
    token is needed to capture a fixture). Trim it to the top-level item plus two or three
    version items, keeping each version item's real link children intact, and give one version
    a primary name distinct from the game's. If the network is unavailable, hand-build the
    document from the shape `parse_items/1`'s `versions:` sub-block already encodes
    (`item > versions > item[@type='boardgameversion']` with `name`, `image`, `thumbnail` and
    `link` children) — and say so explicitly in the SUMMARY, because a hand-built fixture
    proves the fix against an assumed shape rather than a captured one.

    Do not paste any credential into the fixture; strip cookies/auth if you captured over HTTP.

    Then change the six top-level link extractions — mechanics, categories, designers,
    publishers, families, artists — from descendant-or-self traversal to direct-child
    traversal, so each selects only the top-level item's own link children. Apply the same
    scoping to the `name`, `average_weight`, `average_rating`, `rank` and `versions` selectors
    in the same block: `statistics` and `versions` are direct children of the item, and the
    item's own primary name is a direct child. (`name` resolves correctly today only because
    document order puts the item's own name before every version's and the `s` modifier takes
    the first match — that is luck, not scoping.) Leave the `/items/item` root selector and the
    entire nested `versions:` sub-block's relative selectors exactly as they are; they are
    already correct.

    Before committing, re-read each rewritten selector against the captured fixture and confirm
    the element really is a direct child — if BGG nests one of them a level deeper than assumed,
    keep that one as-is and record which and why. The test suite is the arbiter here.

    Finally, rewrite the `dedup_artists/1` `@doc` paragraph that attributes the duplication to
    BGG's artist data. State the real cause (version-item links folded in by an unscoped
    selector), note that `designers` was clean only because version items carry no designer
    link, and keep `dedup_artists/1` itself — it stays public API for
    `Mix.Tasks.Catalog.BackfillArtists` and `StatsEnricher.backfill_artists_from_payload/1`,
    both of which run against legacy payloads that may predate this fix. After the fix it is a
    harmless no-op on fresh payloads; say that rather than deleting the function.
  </action>
  <verify>
    <automated>mix test test/pukllay_club/catalog/seed/bgg_client_test.exs test/pukllay_club/catalog/bgg_editions_test.exs --warnings-as-errors</automated>
    <automated>test "$(grep -v '^\s*#' lib/pukllay_club/catalog/seed/bgg_client.ex | grep -c '~x"\./link\[@type=')" = "7" # 6 top-level link fields + the 1 pre-existing language selector inside the versions sub-block</automated>
    <automated>grep -q '~x"/items/item"l' lib/pukllay_club/catalog/seed/bgg_client.ex # root selector untouched</automated>
    <automated>grep -q 'dtd: :none' lib/pukllay_club/catalog/seed/bgg_client.ex # T-01-08 hardening survives the edit</automated>
    <automated>grep -q '<versions>' test/support/fixtures/bgg_thing_with_versions.xml</automated>
  </verify>
  <done>
    The new test fails on the pre-change parser and passes after; `mix test` for both BGG test
    files is green with no warnings; the direct-child link selector count is exactly 7; the
    `/items/item` root selector and `dtd: :none` are intact; `dedup_artists/1`'s doc no longer
    claims the duplication is a property of BGG's data.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Let the re-enrichment path actually write the repaired publishers column</name>
  <files>lib/pukllay_club/catalog/seed/stats_enricher.ex, test/pukllay_club/catalog/seed/stats_enricher_test.exs, lib/pukllay_club_web/game_text.ex</files>
  <read_first>
    - `lib/pukllay_club/catalog/seed/stats_enricher.ex` lines 143-155 (`update_game_stats/2`) —
      the narrow `Ecto.Changeset.cast/3` allowlist. Note `:artists` is already in it and
      `:publishers` is not: re-running the enrich task today would repair artists and
      `bgg_payload` while leaving the contaminated `games.publishers` untouched.
    - `lib/pukllay_club/catalog/seed/stats_enricher.ex` lines 17-24 — the module's own list of
      columns it must never touch (`cover_url`, `thumbnail_url`, `gallery_urls`, `description`,
      `name`, `csv_row`). `publishers` is not among them.
    - `lib/pukllay_club/catalog/game.ex` — confirm `:publishers` is already cast by
      `enrichment_changeset/2` as a BGG-derived field, and that nothing marks it club-owned
      under D-07. It is rendered read-only in the admin (`live/admin/game_live/form.ex`, the
      "Editorial" list item), never edited there.
    - `test/pukllay_club/catalog/seed/stats_enricher_test.exs` if it exists — reuse its existing
      setup/stub idiom rather than inventing a new one.
  </read_first>
  <behavior>
    - Test 1: a game whose stored row carries a long contaminated publisher list, re-enriched
      against a stubbed BGG response declaring two publishers, ends with exactly those two
      publishers persisted.
    - Test 2: the same run still leaves `cover_url`, `thumbnail_url`, `gallery_urls`,
      `description` and `name` untouched — the widened allowlist must not widen past one column.
    - Test 3: `--dry-run` (`dry_run: true`) writes nothing, including no publisher change.
  </behavior>
  <action>
    Add `:publishers` to `update_game_stats/2`'s attrs map and to its `Ecto.Changeset.cast/3`
    allowlist, positioned next to the `:artists` entry it mirrors. Extend the `@doc` on
    `enrich_from_bgg/2` and the module `@moduledoc`'s bullet list so both name the publishers
    column among what the function re-fetches — those docs are the contract a future reader
    checks, and leaving them listing only the old five columns would be a silent drift.

    Add a one-line note next to the new entry explaining why the column joined the allowlist
    (the scoping fix in Task 1 means a re-enrichment run is now the repair path for it), so the
    widening reads as deliberate rather than as allowlist creep.

    Do not add `:mechanics`, `:themes` or `:designers`. Task 3 measures them; the measurement at
    planning time showed zero rows above 20 mechanics and only two above 4 designers, i.e. they
    were never colliding with version-item links. Widening the allowlist to columns the defect
    never touched would put BGG-sourced writes onto curated columns for no repair benefit.

    Then update `GameText`'s `@doc` on `editorial_text/1` / the surrounding moduledoc rationale
    that asserts this catalog's publisher lists are short and therefore need no conjunction
    handling. Re-ground it: the claim is true of the repaired data and was false of the shipped
    data. Behaviour of `editorial_text/1` and `cover_alt/1` stays exactly as it is — this is a
    documentation correction, not a rendering change, and it must not alter a single assertion
    in `test/pukllay_club_web/components/game_text_test.exs`.
  </action>
  <verify>
    <automated>mix test test/pukllay_club/catalog/seed/stats_enricher_test.exs test/pukllay_club_web/components/game_text_test.exs --warnings-as-errors</automated>
    <automated>sed -n '/defp update_game_stats/,/^  end$/p' lib/pukllay_club/catalog/seed/stats_enricher.ex | grep -q ':publishers'</automated>
    <automated>test "$(sed -n '/defp update_game_stats/,/^  end$/p' lib/pukllay_club/catalog/seed/stats_enricher.ex | grep -c ':mechanics\|:themes\|:designers')" = "0" # region-scoped to the function body, so doc prose elsewhere in the file cannot satisfy or break it: the allowlist is widened by exactly one column</automated>
  </verify>
  <done>
    `StatsEnricher.update_game_stats/2` persists `publishers`; a dry run still writes nothing;
    the image/description/name columns the module promises never to touch are still untouched;
    `game_text_test.exs` passes unchanged.
  </done>
</task>

<task type="auto">
  <name>Task 3: Re-enrich the DEV catalog and confirm the repair landed</name>
  <precondition>`BGG_API_TOKEN` is exported in the executing shell (`Credentials.fetch!/0` raises without it). It was NOT set in the planning shell — if it is still unset, halt on the unmet precondition (`gate="blocking-human"`) and ask the user for it. Do not improvise a fallback, do not skip the live run, and do not mark the task done without it. This halt is also the deliberate human stop before ~386 rows are rewritten.</precondition>
  <reversibility rating="costly">The live run rewrites `publishers`/`artists`/`bgg_payload` on every dev row with a `bgg_id`. It is re-runnable and idempotent against BGG, but the pre-run contaminated values are not recoverable from the dev database afterwards — Step 1's baseline measurement is the only record of the before-state, which is why it is captured before any write.</reversibility>
  <files>priv/repo/seed_data/bgg_stats_enrichment_report.md</files>
  <read_first>
    - `lib/mix/tasks/catalog.enrich_bgg_stats.ex` — the `--limit` / `--dry-run` flags, the
      `Credentials.redacted/1` log line, and the Markdown report it writes.
    - `config/dev.exs` lines ~35-46 — note `DATABASE_URL`, when set, overrides the local
      `pukllay_club_dev` target. That env var is the one way this task could reach a non-dev
      database; check it before doing anything.
  </read_first>
  <action>
    **Scope guard, first and non-negotiable.** This task writes to the dev database only. Do
    NOT run any part of it against production, do NOT set or reuse a production `DATABASE_URL`,
    do NOT open a tunnel or `kamal app exec` into the live host. Production carries the same
    contamination, but repairing it is a separate, explicitly-requested change with its own
    backup/rollback story — it is out of scope here. Flag it in the SUMMARY as follow-up.

    Before any write: confirm `DATABASE_URL` is unset (or points at `pukllay_club_dev`) and
    confirm the connected database name is `pukllay_club_dev`. If either check is ambiguous,
    stop and ask.

    **Step 1 — measure your own baseline.** Do not carry over the planning-time numbers in this
    plan's objective; the dev database has mutated since. Record, into the SUMMARY: the count
    of `games` rows with a non-null `bgg_id`, the max and the >5 count of
    `array_length(publishers, 1)`, the max `array_length(artists, 1)`, and the max
    `array_length(mechanics, 1)` / `array_length(designers, 1)`. The last two are the control:
    they should be identical before and after.

    **Step 2 — dry run.** `mix catalog.enrich_bgg_stats --dry-run --limit 20`. Confirm from its
    summary line and report that it fetched real items and wrote nothing. Confirm the console
    line printed a redacted credentials map, never the raw token.

    **Step 3 — live dev run.** `mix catalog.enrich_bgg_stats`. Expect roughly 20 batches at a
    1.5s inter-batch delay. If the run reports failed batches, re-run it — the task is
    idempotent per row and the report records what failed; do not hand-patch individual rows.

    **Step 4 — verify the repair by re-measuring**, comparing against your own Step 1 baseline.

    Do not run `mix catalog.backfill_artists` afterwards: it reads `bgg_payload["artists"]`,
    which Step 3 has already rewritten from the corrected extraction, so it is a no-op that
    would only muddy the SUMMARY.

    Then run the full gate: `mix quality`.
  </action>
  <verify>
    <automated>test -z "$DATABASE_URL" || echo "$DATABASE_URL" | grep -q 'pukllay_club_dev' # never pointed at a non-dev database</automated>
    <automated>psql "${DATABASE_URL:-postgresql://postgres:postgres@localhost/pukllay_club_dev}" -At -c "select current_database()" | grep -qx 'pukllay_club_dev'</automated>
    <automated>psql "${DATABASE_URL:-postgresql://postgres:postgres@localhost/pukllay_club_dev}" -At -c "select count(*) from games where array_length(publishers,1) > 25" | grep -qx '0'</automated>
    <automated>psql "${DATABASE_URL:-postgresql://postgres:postgres@localhost/pukllay_club_dev}" -At -c "select coalesce(max(jsonb_array_length(bgg_payload->'publishers')),0) <= 25 from games where bgg_payload ? 'publishers'" | grep -qx 't'</automated>
    <automated>mix quality</automated>
    <human-check>
      Open a catalog page in dev and inspect one cover image's `alt` attribute (a game that was
      badly contaminated — e.g. bgg_id 198454 / 50 / 162886). It should read as a short
      "Portada de {juego}, editado por {one to a few names}" sentence, not a paragraph-length
      publisher roll-call. Confirm the named publishers are plausibly the game's real
      publishers and not a list of every regional edition.

      Then confirm the before/after numbers recorded in the SUMMARY: publishers collapsed,
      while `mechanics` and `designers` maxima are byte-identical to the baseline (the control
      that proves the fix was scoped to the two colliding link types).
    </human-check>
  </verify>
  <done>
    Dev-only writes confirmed by database-name assertion; no dev row exceeds 25 publishers in
    either the column or the stored payload; the mechanics/designers control measurements are
    unchanged from the task's own baseline; `mix quality` passes; the human check confirms a
    short, plausible cover `alt` string; production is documented as untouched and flagged as
    follow-up.
  </done>
</task>

</tasks>

<threat_model>
ASVS level 1, blocking threshold: high.

## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| BGG xmlapi2 -> `BggClient.parse_items/1` | Untrusted external XML crosses here. Already hardened with `dtd: :none`; this plan edits the code immediately adjacent to that hardening. |
| Executor shell -> database | The re-enrich task issues bulk writes. The boundary being defended is dev-vs-production, selected purely by an env var. |
| `games.publishers` -> rendered `alt` / `aria-label` | Attacker-influenceable strings (anyone can edit a BGG publisher name) reach the DOM. HEEx escapes at render; `GameText` deliberately does not pre-escape. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-TUM-01 | Tampering | `BggClient.parse_items/1` XML entry point | high | mitigate | The `dtd: :none` option and its `catch :exit` conversion are adjacent to every line Task 1 edits. Task 1 changes selectors only, never the `parse/2` call, and carries a `grep -q 'dtd: :none'` gate plus the existing hostile-document test in the same file's run. |
| T-TUM-02 | Tampering | Dev vs production database target | high | mitigate | Task 3 asserts `DATABASE_URL` is unset-or-dev and `current_database() = pukllay_club_dev` before any write, and its action forbids production tunnels/`kamal app exec` outright. Its unmet `BGG_API_TOKEN` `<precondition>` additionally forces a `gate="blocking-human"` halt before the live run (the token is currently unset), so a human sees the run start even under `--auto`. Production repair is explicitly deferred to a separate request. |
| T-TUM-03 | Information Disclosure | `BGG_API_TOKEN` in logs, report file, or fixture | medium | mitigate | The task already logs via `Credentials.redacted/1`; Task 3 verifies that line is redacted. The Task 1 fixture is captured unauthenticated (BGG's public API needs no token) and the action forbids pasting any credential or auth header into the committed fixture. |
| T-TUM-04 | Tampering | `games.publishers` -> `GameText.cover_alt/1` -> DOM | low | accept | Publisher names are attacker-influenceable via BGG, but HEEx escapes every interpolation at render and `GameText` documents that it never pre-escapes (avoiding double-escape). The fix strictly reduces the attack surface by shrinking the list; no new sink is introduced. |
| T-TUM-05 | Denial of Service | BGG rate limit during the full re-enrich | low | accept | `BggClient` already batches at 20 ids and retries 429/5xx with backoff; `StatsEnricher` sleeps 1.5s between batches. A rate-limited run degrades to a partial run recorded in the report and is safely re-runnable. |
| T-TUM-06 | Elevation of Privilege | Widening `update_game_stats/2`'s cast allowlist | medium | mitigate | Exactly one column is added. Task 2 carries a behavioural test that the never-touch columns stay untouched, plus a gate asserting `:mechanics`/`:themes`/`:designers` did not slip in. |
| T-TUM-SC | Tampering | npm/pip/cargo/hex installs | n/a | accept | No package is added, removed or upgraded by this plan — `mix.exs` and `mix.lock` are not in `files_modified`. No package-legitimacy audit is required; if the executor finds itself needing a new dependency, that is a scope change and must go back to the user. |
</threat_model>

<verification>
- `mix quality` passes end to end (`hex.audit`, `deps.audit`, `deps.unlock --check-unused`,
  `format --check-formatted` incl. Styler, `credo --strict`, `sobelow`, `test`).
- Styler may rewrite touched code. Review `git diff` for every Styler-produced rewrite before
  committing — per Styler's own guidance it can change program behaviour, and `parse_items/1`'s
  extraction block is exactly the kind of dense literal map where an unreviewed rewrite is
  expensive.
- The regression test in Task 1 demonstrably fails against the pre-change parser. If it passes
  before the source edit, the fixture does not reproduce the defect — fix the fixture, do not
  proceed.
- `mechanics` / `designers` maxima measured in Task 3 are unchanged from that task's own
  baseline.
</verification>

<success_criteria>
- A BGG response carrying nested version items parses to publisher and artist lists containing
  only the top-level item's own links, proven by a committed fixture.
- All six top-level link extractions are direct-child scoped; the `/items/item` root selector,
  the nested `versions:` sub-block and `dtd: :none` are unchanged.
- `mix catalog.enrich_bgg_stats` writes `games.publishers`.
- No dev `games` row exceeds 25 publishers in the column or in the stored payload.
- `mechanics` / `themes` / `designers` are measurably unchanged.
- The falsified `dedup_artists/1` claim and the `GameText` publisher-length rationale are
  corrected in place.
- Production is untouched and recorded as follow-up.
- `mix quality` passes.
</success_criteria>

<output>
Create `.planning/quick/260922-tum-fix-the-bgg-xpath-bug-and-re-enrich/260922-tum-SUMMARY.md` when done.

The SUMMARY must record:
- Whether the Task 1 fixture was captured live from BGG or hand-built, and if hand-built, why.
- Any selector kept as descendant-scoped because the captured XML disagreed with the
  direct-child assumption, and which.
- Task 3's own before/after measurements (publishers max and >5 count; artists max;
  mechanics/designers maxima as the control) — the task's measurements, not this plan's.
- An explicit statement that production was not touched, plus the follow-up needed to repair it.
</output>
