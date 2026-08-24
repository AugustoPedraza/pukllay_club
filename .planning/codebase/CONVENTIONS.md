# Coding Conventions

**Analysis Date:** 2026-08-18

## Naming Patterns

**Files:**
- Snake case for all files: `catalog.ex`, `game_card.ex`, `catalog_live.ex`
- Test files mirror source structure: `lib/pukllay_club/catalog.ex` → `test/pukllay_club/catalog_test.exs`
- Migration files: timestamp-prefixed (`priv/repo/migrations/20260810172415_add_games_search_and_indexes.exs`)
- Support modules: `test/support/data_case.ex`, `test/support/fixtures/catalog_fixtures.ex`

**Functions:**
- Snake case: `filter_games/1`, `list_carousel_rows/0`, `normalize_opts/1`
- Private functions use `defp`: `defp maybe_search/2`, `defp base_filtered_query/2`
- Predicate functions end with `?` when returning boolean: `filters_active?/1`, `connected?/1`
- Helper function prefix pattern: `maybe_*` for conditional filtering functions, `safe_*` for error-wrapped functions
  - Examples: `maybe_filter_mechanics/2`, `maybe_search/2`, `safe_filter_games/1`
- Plurals for collection operations: `list_games/1`, `count_games/1`, `list_carousel_rows/0`
- Singular for record operations: `get_game!/1`, `upsert_game!/1`

**Variables:**
- Snake case: `game_fixture`, `default_attrs`, `weight_band_order`
- List/collection suffix: `fixture_attrs`, `mechanics`, `themes`
- Private module constants in SCREAMING_SNAKE_CASE: `@default_limit`, `@carousel_limit`, `@allowed_sorts`, `@weight_band_order`
- Pattern match variables follow same snake_case: `{:ok, games}`, `%{key: key, title: title, games: games}`

**Types/Modules:**
- PascalCase for modules: `PukllayClub.Catalog`, `PukllayClubWeb.GameCard`, `PukllayClub.Catalog.Game`
- Web modules use `PukllayClubWeb` prefix: `PukllayClubWeb.CatalogLive.Index`, `PukllayClubWeb.GameCard`
- Schema/context modules nested under parent: `PukllayClub.Catalog.Game`, `PukllayClub.Catalog.Vocabulary`
- Struct field names: snake_case (`min_players`, `weight_band`, `bgg_weight`, `enrichment_status`)

**Atoms:**
- Snake case for atom names: `:name_asc`, `:playtime_asc`, `:complexity_desc`, `:enriched`, `pending`
- Tag/marker atoms: `:async`, `:only`, `:dev`, `:test`, `:prod`

## Code Style

**Formatting:**
- Tool: `Styler` + `Phoenix.LiveView.HTMLFormatter` plugins to `mix format --check-formatted`
- Max line length: 120 characters (enforced by Credo with `priority: :low`)
- Indentation: 2 spaces (Elixir standard via Styler)
- No trailing whitespace, semicolons, or redundant blank lines

**Linting:**
- Tool: Credo with `--strict` flag in `mix quality` alias
- Exit status for TODO: 2 (causes failure), FIXME: 0 (warning only)
- AliasUsage check has `exit_status: 0` because phx.new boilerplate trips it
- Configuration file: `.credo.exs`

**Run Commands:**
```bash
mix quality              # Run all quality checks (fast)
mix quality.full         # Run all quality checks + dialyzer (slow)
mix precommit            # Pre-commit hook alias (warnings-as-errors, no mutations)
mix format --check-formatted  # Check formatting (runs Styler as plugin)
mix credo --strict       # Static analysis (strict mode)
mix sobelow --config     # Security analysis
mix test --warnings-as-errors  # Run tests, fail on warnings
```

## Import Organization

**Order in source files:**
1. `use` statements (Phoenix macros, ExUnit templates): `use Ecto.Schema`, `use PukllayClubWeb, :live_view`
2. `import` statements (bringing functions into scope): `import Ecto.Query`, `import Ecto.Changeset`
3. `alias` statements (module references): `alias PukllayClub.Catalog`, `alias PukllayClub.Repo`
4. Module attributes and constants: `@default_limit 24`, `@enrichment_statuses ~w(...)`
5. Function definitions

**Alias patterns:**
- Single-line aliases for one or two modules: `alias PukllayClub.Repo`
- Grouped aliases rarely used (Credo MultiAliasImportRequireUse is disabled)
- Full module names repeated if aliases not used (no performance cost in Elixir)

**Path aliases in verified routes:**
- Used in templates and controllers: `~p"/"`, `~p"/juegos/#{@game}"`, `~p"/up"`
- Prevents hardcoding route strings

## Error Handling

**Patterns:**
- `Repo.get!/1` for single record retrieval — raises `Ecto.NoResultsError`, which Plug.Exception converts to 404 status (see `lib/pukllay_club_web/live/catalog_live/show.ex`)
- `Repo.insert!/2` for writes — raises on constraint violation
- Wrapped reads with `rescue` clauses for LiveView filter operations: `safe_filter_games/1` catches all errors and returns `:error` atom instead of crashing
- LiveView handles both `:ok` and `:error` tuples in `handle_event` to assign error flags and render error UI
- Changeset validation via `validate_*` functions rather than exceptions

**Example pattern:**
```elixir
defp safe_filter_games(opts) do
  {:ok, Catalog.filter_games(opts)}
rescue
  _error -> :error
end
```

## Logging

**Framework:** `Logger` module (Elixir standard)

**Patterns:**
- Minimal logging — only startup/shutdown and operational events
- Info level for successful operations: `Logger.info("R2 object already present, skipping upload: #{key}")`
- No debug-level logging visible in typical production deployments
- Structured logging via Telemetry for metrics (see `lib/pukllay_club_web/telemetry.ex`)
- Sentry handler attached to Logger for error reporting (see `lib/pukllay_club/application.ex`)

**Test environment:** Logger level set to `:warning` to reduce noise (see `config/test.exs`)

## Comments

**When to Comment:**
- Module-level: Always include `@moduledoc` describing purpose, constraints, and decision rationale
- Function-level: Include `@doc` for public functions; detail: parameter semantics, return value, when it raises, side effects
- Inline comments: Used sparingly for non-obvious Postgres/Ecto interactions, constraint-driven design decisions, or bugs being worked around
- Reference tracking: Comments link to design documents (e.g., `(CATALOG-03, D-15)`, `(T-01-20)`) and issue/phase numbers

**JSDoc/TSDoc:**
- Not applicable (Elixir uses `@doc` and `@spec`)

**Spec/Type annotations:**
- Rarely used in this codebase; Dialyzer configuration exists but is run separately (`mix quality.full`)
- When used: function specs like `@spec normalize_sort(atom | string) :: atom` to codify expected types

**Example from codebase:**
```elixir
@moduledoc """
The Catalog context — the only module `CatalogLive.Index` (and the seed
pipeline) reads/writes `PukllayClub.Catalog.Game` rows through.

`filter_games/1` is the single composed query serving CATALOG-02
(filter), CATALOG-03 (search), and CATALOG-04 (sort) together, per
01-RESEARCH.md Pattern 3 — one pipeline of `maybe_*` predicates, never a
branch between "search mode" and "filter mode". Every user-supplied value
reaches Postgres as a pinned `^` parameter inside `fragment/2`; no query
text is ever built by string interpolation (T-01-20).
"""
```

## Function Design

**Size Guidelines:**
- Prefer small functions (<15 lines) over large ones
- Use `defp` for single-use helpers; consider extracting public functions for reusable logic
- Example: `maybe_search/2`, `maybe_filter_mechanics/2` are each 3-5 lines

**Parameters:**
- Pattern matching in function heads to match on structure: 
  ```elixir
  defp maybe_search(query, q) when q in [nil, ""], do: query
  defp maybe_search(query, term) do ...
  ```
- Guard clauses for nil/empty checks
- Pipe operator used extensively to pass query/socket/assigns through transformations

**Return Values:**
- Functions that may fail return `{:ok, result}` or error atoms (`:error`, `{:error, reason}`)
- Query-building functions return modified queries for further piping
- LiveView event handlers return `{:noreply, socket}` or `{:reply, message, socket}`
- Casting/validation functions return changesets with errors attached

**Example pipeline:**
```elixir
def filter_games(opts \\ []) do
  opts = normalize_opts(opts)

  Game
  |> base_filtered_query(opts)
  |> apply_sort(normalize_sort(Map.get(opts, :sort)))
  |> limit(^(Map.get(opts, :limit) || @default_limit))
  |> offset(^(Map.get(opts, :offset) || 0))
  |> Repo.all()
end
```

## Module Design

**Exports:**
- Only public functions at top level; private helpers use `defp`
- LiveView modules use `@impl true` directive before callback implementations
- Contexts (`PukllayClub.Catalog`) expose high-level operations; Repo is never called directly outside contexts

**Barrel Files:**
- Not used; imports are explicit (`import PukllayClub.CatalogFixtures` in tests)

**Schema/Changeset pattern:**
- Schema defines one or more changesets for different use cases: `seed_changeset/2` vs. user input changesets
- Changesets validate required fields, constraints, and value inclusion
- Never leave validation to the database alone — Ecto changesets catch errors before queries

**Example changeset:**
```elixir
def seed_changeset(game, attrs) do
  game
  |> cast(attrs, [
    :name, :csv_row, :bgg_id, :units, :min_players, :max_players,
    :min_playtime, :max_playtime, :playing_time, :min_age, :year_published,
    :weight_band, :bgg_weight, :tags, :mechanics, :themes, :designers,
    :publishers, :description, :thumbnail_url, :cover_url, :gallery_urls,
    :bgg_payload, :enrichment_status
  ])
  |> validate_required([:name, :csv_row])
  |> validate_inclusion(:enrichment_status, @enrichment_statuses)
  |> unique_constraint(:csv_row)
end
```

## LiveView Conventions

**Module structure:**
- Mount handler initializes assigns and streams
- Event handlers (handle_event) update state and return `{:noreply, socket}` or stream updates
- Two-phase mount pattern: disconnected render shows skeletons, connected re-renders with real data
- Render function uses `~H` sigil for template syntax

**Event naming:**
- Kebab-case for event names: `"search"`, `"toggle-facet"`, `"set-scalar"`, `"load-more"`
- Event handler names: `handle_event("search", %{"q" => q}, socket)`

**Assigns:**
- All state lives in socket assigns
- Filters use separate assigns for each facet: `:q`, `:mechanics`, `:themes`, `:weight_bands`, `:tags`, `:players`, `:max_playtime`, `:min_age`
- Page state: `:offset`, `:total`, `:load_error`, `:page_size`
- Loaded data: `:games` (stream), `:carousel_rows`, `:facet_options`

## Component Conventions

**Stateless components (Phoenix.Component):**
- Used for rendering logic only; no internal state
- File: `lib/pukllay_club_web/components/game_card.ex`
- Called with attributes via `<GameCard.game_card game={@game} />`
- Accepts optional `:class` for layout flexibility

**Test data fixtures:**
- All game test data created via `game_fixture/1` with sane Spanish defaults
- Fixtures accept optional `attrs` map to override defaults
- Signature stable across phases: `def game_fixture(attrs \\ %{})`

## Agent Workflow Rules

- Run `mix precommit` before marking any individual task complete. It is non-mutating;
  if it fails, fix the cause rather than re-running.
- Run `mix quality` once before declaring a phase verified.
- Never run `mix format` or `mix deps.unlock --unused` as part of completing a task —
  formatting changes must be their own isolated commit.

---

*Convention analysis: 2026-08-18*
