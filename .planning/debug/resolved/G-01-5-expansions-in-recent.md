---
status: resolved
trigger: "G-01-5: Game expansions are appearing in the 'Recién añadidos' (recently added) section on the catalog main page, when that section should only ever show base games."
created: 2026-08-18T00:00:00.000Z
updated: 2026-09-12
audit_acknowledged:
  milestone: v1.0
  at: 2026-09-11
  status: diagnosed
---

## Current Focus

hypothesis: CONFIRMED — recent_query/0 (backing the 'Recientemente añadidos' carousel row) has no expansion-exclusion filter, and no such filter is even possible today because the Game schema has no is_expansion/parent_game_id column; the only expansion signal is a free-text marker embedded in the Nombre field. Independently, the source CSV physically clusters all 21 "(expa)"/"Expansión"-marked rows (plus several more unmarked promo/expansion rows) as a contiguous block at the very tail of the sheet (csv_row ~410-435 of 434 total rows). Because the seed task inserts rows sequentially in ascending csv_row order, inserted_at is monotonically correlated with csv_row — so recent_query's `order_by: [desc: g.inserted_at, desc: g.csv_row], limit: 20` collapses to "return the highest csv_row rows first," which is exactly the CSV's expansions tail block.
test: Grepped the full CSV for expansion markers and confirmed line positions; read recent_query/0 and confirmed zero filter predicate; read Game schema and every migration and confirmed no expansion-marker column exists anywhere in the DB.
expecting: N/A — diagnosis complete, goal is find_root_cause_only.
next_action: Return ROOT CAUSE FOUND to caller. Do not fix (diagnose-only mode).

reasoning_checkpoint:
  hypothesis: "The 'Recientemente añadidos' carousel row surfaces expansions because (a) recent_query/0 in lib/pukllay_club/catalog.ex applies zero filter to exclude expansions, and no column exists to filter on even if it wanted to, and (b) its inserted_at/csv_row-desc ordering deterministically surfaces the CSV's tail rows first, which is where the club's source spreadsheet happens to cluster all its expansion/promo entries."
  confirming_evidence:
    - "lib/pukllay_club/catalog.ex recent_query/0 (lines ~178-182): `from g in Game, order_by: [desc: g.inserted_at, desc: g.csv_row], limit: ^@carousel_limit` — no where clause at all, unlike weight_band_query/1 and tags_query/1 which at least filter on a real column."
    - "lib/pukllay_club/catalog/game.ex schema has no is_expansion, parent_game_id, or any expansion-related field/column; grep of priv/repo/migrations/*.exs for expansion/is_expansion/parent_game confirms none was ever added."
    - "priv/repo/seed_data/ludoteca.csv: `grep -niE '\\(exp|expansion|expansión'` returns 21 matches, all on physically the last ~24 lines of the file (lines 2794-2818 of a 2817-line file) — i.e., a contiguous block at the tail of the source export."
    - "priv/repo/seed_data/catalog_seed_report.md's 'Unresolved' zero-hashtag section (rows 410-435 of 434 analyzed rows) is almost entirely these same expansion/promo names (Bunny Kingdom Celestial(expa), Root Expansion Los Rivereños, Kingdomino Age of Giants (Expansión), Catapul Feud (expa 1/2), etc.) plus a few non-'(expa)'-marked but still non-base entries (Star Wars promo miniatures, two LOTR 'Viajes por la Tierra Media' expansion sub-sets) — same tail-of-CSV cluster, same csv_row range."
    - "lib/mix/tasks/catalog.seed.ex build_rows_and_report/1 processes csv_rows via Enum.map_reduce in the CSV's original streamed order, and run_full_seed/3 upserts via Enum.reduce(rows, report, fn row, acc -> process_row(...) end) — also strictly original row order — so DB inserted_at timestamps are monotonically non-decreasing with csv_row across the single bulk seed run, making the query's primary sort key (inserted_at desc) functionally equivalent to (not just tie-broken by) csv_row desc."
    - "catalog.ex's own docstring on list_carousel_rows/0 already self-documents this as a 'Recorded limitation': 'the club export has no acquisition date, so after a single bulk seed Recientemente añadidos is effectively reverse-CSV order (inserted_at desc, csv_row desc tie-break)' — confirming the mechanism, though the docstring frames it only as an ordering quirk, not as the specific expansion-surfacing failure this ticket reports."
  falsification_test: "If the 20 highest-csv_row games in the DB were NOT dominated by expansion-marked rows (e.g., if expansions were scattered evenly through the CSV rather than clustered at the tail), the recency carousel would show a normal mix of base games despite the missing filter, and this hypothesis would be false. The tail-clustering (grep line positions 2794-2818 of 2817) directly confirms it is NOT scattered."
  fix_rationale: "N/A — diagnose-only mode (goal: find_root_cause_only); no fix applied in this session."
  blind_spots: "Have not run a live query against the actual seeded DB (mix run/psql) to print the literal 20 rows recent_query/0 returns today — evidence is derived from static CSV/report/code analysis, which is strong but not a live runtime confirmation. Also have not checked whether any expansion-marked rows exist mid-CSV (i.e., outside the tail cluster) that would still leak into other carousel rows (e.g. weight-band rows) if they happened to have a resolved weight_band — out of scope for G-01-5 but worth flagging for a broader fix."
  candidate_causes:
    - "code: recent_query/0 in lib/pukllay_club/catalog.ex has no where-clause exclusion for expansions (or for anything) — category: code"
    - "data: Game schema/migrations have no expansion-marker column at all; the CSV's source spreadsheet clusters all expansion/promo rows as a contiguous tail block, and the bulk-seed insertion order preserves that clustering into inserted_at/csv_row ordering — category: data"
  and_gate: "yes — both conditions are jointly necessary. If the query excluded expansions (even via a crude Nombre ILIKE check) the tail-clustering wouldn't matter; if expansions were scattered through the CSV instead of clustered at the tail, the unfiltered query's inserted_at/csv_row-desc ordering wouldn't systematically surface them. The bug is the AND of 'no filter exists' and 'the naive recency ordering happens to align exactly with where expansions live in the source data.'"

## Symptoms

expected: The 'Recién añadidos' (recently added) section on the main page never includes game expansions.
actual: User reported expansions appearing in the 'Recién añadidos' section. Per prior UAT investigation (Test 5 in 01-UAT.md), expansions are only identifiable via text markers in the seed CSV's Nombre field (no dedicated is_expansion column) — this section's query likely needs to exclude them, but the underlying data model/query had not yet been inspected.
errors: None reported
reproduction: Test 2 in .planning/phases/01-catalog-v1/01-UAT.md — load the main catalog page (/) and look at the 'Recién añadidos' carousel row
started: Discovered during UAT (Phase 01-catalog-v1)

## Eliminated

(none — first and only hypothesis, confirmed directly via static evidence)

## Evidence

- timestamp: 2026-08-18T00:00:00.000Z
  checked: lib/pukllay_club/catalog.ex — list_carousel_rows/0, recent_query/0, weight_band_query/1, tags_query/1
  found: recent_query/0 (backing the :recientemente_anadidos row, title "Recientemente añadidos") is `from g in Game, order_by: [desc: g.inserted_at, desc: g.csv_row], limit: ^@carousel_limit` — no where clause. By contrast weight_band_query/1 and tags_query/1 both filter on a real column (weight_band, tags). The docstring on list_carousel_rows/0 already flags "Recorded limitation: the club export has no acquisition date, so after a single bulk seed Recientemente añadidos is effectively reverse-CSV order (inserted_at desc, csv_row desc tie-break)".
  implication: This is the exact query rendering the buggy section, and it has zero expansion-awareness by construction.

- timestamp: 2026-08-18T00:00:00.000Z
  checked: lib/pukllay_club/catalog/game.ex schema + every file in priv/repo/migrations/*.exs (grepped for expansion/is_expansion/parent_game)
  found: No is_expansion, parent_game_id, or any expansion-related column exists anywhere in the Game schema or any migration. weight_band (nullable) is the closest proxy but is not a reliable expansion signal — it's also null for base games with no BGG_ID that are NOT expansions (e.g. "Marco Polo 2", "discordia", "ganges", "Cyclades", "Atiwa" per catalog_seed_report.md's "Rows with no BGG_ID" list).
  implication: Even if recent_query/0 wanted to exclude expansions today, there is no queryable column to filter on — the only signal is free text embedded in Nombre (e.g. "(expa)", "Expansión", "Expansion"), never parsed out during seeding.

- timestamp: 2026-08-18T00:00:00.000Z
  checked: priv/repo/seed_data/ludoteca.csv via grep -niE "\(exp|expansion|expansión"
  found: 21 matches, all physically located on the last ~24 lines of the file (file lines 2794-2818 of 2817 total lines) — a contiguous block at the very tail of the source spreadsheet. Matches priv/repo/seed_data/catalog_seed_report.md's "Unresolved" zero-hashtag section (csv rows 410-435 of 434 analyzed rows), which is almost entirely the same expansion/promo names plus a few unmarked-but-clearly-non-base entries (Star Wars promo miniatures, two LOTR "Viajes por la Tierra Media" expansion sub-sets, "Root Expansion Los Rivereños", "abyss leviatan", "viniculture tuscany").
  implication: The club's source export clusters essentially all expansion/promo rows as a contiguous block at the highest csv_row values, not scattered randomly through the sheet.

- timestamp: 2026-08-18T00:00:00.000Z
  checked: lib/mix/tasks/catalog.seed.ex — build_rows_and_report/1 (Enum.map_reduce over csv_rows in stream order) and run_full_seed/3 (Enum.reduce(rows, report, fn row, acc -> process_row(...) end))
  found: Both passes iterate rows in the CSV's original streamed order (ascending csv_row/row_number), with per-row Catalog.upsert_game! calls happening in that same sequential order during the single bulk seed run. No re-sort, no parallelism across rows that would scramble insertion order.
  implication: DB inserted_at is monotonically non-decreasing with csv_row across the bulk seed run, so recent_query/0's primary sort key (inserted_at desc) is functionally aligned with (not just tie-broken by) csv_row desc — the query effectively returns "the last N rows of the source CSV," which is precisely the expansions tail block confirmed above.

## Resolution

root_cause: "No is_expansion/parent_game_id column exists anywhere in the Game schema (only a free-text marker inside Nombre, e.g. '(expa)'/'Expansión'/'Expansion', which is never parsed during seeding) [data]; AND lib/pukllay_club/catalog.ex's recent_query/0 (backing the 'Recientemente añadidos' carousel row) applies zero filter and orders by inserted_at desc/csv_row desc, which — because the bulk seed inserts rows in strict ascending csv_row order — collapses to 'return the highest csv_row rows first' [code]. The club's source CSV (priv/repo/seed_data/ludoteca.csv) happens to cluster essentially all its expansion/promo entries as a contiguous block at the tail of the sheet (csv_row ~410-435 of 434), so this unfiltered recency ordering surfaces almost exclusively expansions instead of a representative recently-added set."
fix: "plan 01-09 (commits `7a3ea20`/`f94bc85`/`0ef4ef4`/`9896692`/`9846086`/`65d9930`): added a `games.is_expansion` boolean column with a migration backfill, a new `PukllayClub.Catalog.Seed.ExpansionClassifier` module deriving the flag from marker text plus override rules, and a `where: g.is_expansion == false` predicate on `recent_query/0` — closing both the [data] no-column half and the [code] unfiltered-query half of the AND-gate."
verification: |
  - [data] column now exists: priv/repo/migrations/20260818222551_add_games_is_expansion.exs (`add_games_is_expansion`); `PukllayClub.Catalog.Seed.ExpansionClassifier` at lib/pukllay_club/catalog/seed/expansion_classifier.ex derives `is_expansion` from the Nombre marker text this root cause identified as previously unparsed.
  - [code] filter now applied: lib/pukllay_club/catalog.ex:438-441 `defp recent_query do from g in Game, where: g.is_expansion == false, order_by: [desc: g.inserted_at, desc: g.csv_row] end` — the root cause's exact "no where clause at all" gap is filled; `grep -n 'is_expansion == false' lib/pukllay_club/catalog.ex` -> 1 hit at line 440.
  - 65d9930 (docs(01-09)) and 01-09-SUMMARY.md record the plan as complete, with the earlier 7a3ea20/9896692 commits being intentional failing-test-first (TDD) commits for the classifier and the query exclusion, both later made to pass by f94bc85/9846086.
files_changed:
  - lib/pukllay_club/catalog.ex
  - lib/pukllay_club/catalog/seed/expansion_classifier.ex
  - priv/repo/migrations/20260818222551_add_games_is_expansion.exs
