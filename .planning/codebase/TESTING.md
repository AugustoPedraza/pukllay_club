# Testing Patterns

**Analysis Date:** 2026-08-18

## Test Framework

**Runner:**
- ExUnit (built into Elixir)
- Version: Shipped with Elixir 1.17+ (no separate package)
- Config: `test/test_helper.exs`

**Assertion Library:**
- ExUnit assertions: `assert`, `refute`, `assert_raise`, `assert_receive`
- Pattern matching in assertions: `assert {:ok, _view, _html} = live(conn, ~p"/")`

**Run Commands:**
```bash
mix test                           # Run all tests (with database setup)
mix test --warnings-as-errors     # Run tests, fail on compiler warnings
mix test --failed                 # Re-run only failed tests
mix quality                        # All quality checks including tests
mix quality.full                   # Quality + dialyzer
mix coveralls                      # Generate coverage report
mix coveralls.html                 # Generate HTML coverage report
mix coveralls.detail               # Detailed coverage output
```

**Coverage Tool:**
- ExCoveralls (hex package `excoveralls`, version ~0.18)
- Configured in `mix.exs`: `test_coverage: [tool: ExCoveralls]`
- Coverage env: added to `cli` preferred_envs for `coveralls`, `coveralls.detail`, `coveralls.html`, `quality.full`

## Test File Organization

**Location:**
- Tests are co-located in directory structure mirroring `lib/`: `lib/pukllay_club/catalog.ex` → `test/pukllay_club/catalog_test.exs`
- Component tests: `lib/pukllay_club_web/components/game_card.ex` → `test/pukllay_club_web/components/game_card_test.exs`
- LiveView tests: `lib/pukllay_club_web/live/catalog_live/index.ex` → `test/pukllay_club_web/live/catalog_live_test.exs`
- Support files (fixtures, case templates): `test/support/`

**Naming:**
- Test files end with `_test.exs`
- Test modules named `PukllayClub.CatalogTest`, `PukllayClubWeb.CatalogLive.IndexTest`
- Test suite pattern: `describe "feature name" do test "behavior" do ... end end`

**Directory Structure:**
```
test/
├── pukllay_club/               # Context/domain logic tests
│   ├── catalog_test.exs
│   └── catalog/
│       ├── vocabulary_test.exs
│       └── seed/
│           ├── bgg_client_test.exs
│           ├── image_pipeline_test.exs
│           └── report_test.exs
├── pukllay_club_web/           # Web/UI tests
│   ├── controllers/
│   │   ├── error_html_test.exs
│   │   ├── error_json_test.exs
│   │   └── health_controller_test.exs
│   ├── components/
│   │   ├── game_card_test.exs
│   │   ├── game_chips_test.exs
│   │   └── layouts_test.exs
│   └── live/
│       ├── catalog_live_test.exs
│       └── catalog_show_test.exs
├── support/                    # Test infrastructure
│   ├── conn_case.ex            # HTTP connection test case
│   ├── data_case.ex            # Database test case
│   └── fixtures/
│       └── catalog_fixtures.ex  # Test data builders
└── test_helper.exs             # ExUnit setup
```

## Test Structure

**Suite Organization:**
```elixir
defmodule PukllayClub.CatalogTest do
  use PukllayClub.DataCase, async: true

  import Ecto.Query
  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Repo

  describe "filter_games/1 — no options" do
    test "returns games ordered by name, limited to the default page size" do
      game_fixture(%{name: "Zeta"})
      game_fixture(%{name: "Alfa"})

      assert Enum.map(Catalog.filter_games(), & &1.name) == ["Alfa", "Zeta"]
    end
  end
end
```

**Patterns:**
- `use PukllayClub.DataCase, async: true` for tests interacting with the database
- `use PukllayClubWeb.ConnCase, async: true` for HTTP/LiveView tests
- `use ExUnit.Case, async: true` for pure unit tests (e.g., component tests without database)
- `async: true` enabled for Postgres (SQL.Sandbox in manual mode handles isolation)
- `describe` blocks group related tests with a common prefix (description comes first)
- Test names start with lowercase verb: `"returns games ordered by name"`, `"renders the game cover"`

**Setup and Teardown:**
- DataCase handles database sandbox setup automatically via `setup_sandbox/1`
- No explicit setup/teardown in most tests; fixtures create data directly
- `on_exit/1` callbacks used for cleanup if needed (already wrapped in DataCase setup)

## Mocking

**Framework:** 
- Mox for behavior-based mocking (rarely used; only in seed pipeline)
- Req.Test for HTTP request stubbing
- Ecto.Adapters.SQL.Sandbox for database isolation (manual mode)

**HTTP Mocking (Req.Test):**
```elixir
# In config/test.exs:
config :pukllay_club, :bgg_req_options, plug: {Req.Test, PukllayClub.Catalog.Seed.BggClient}
config :pukllay_club, :image_download_req_options, plug: {Req.Test, PukllayClub.Catalog.Seed.ImagePipeline}

# In test:
defmodule PukllayClub.Catalog.Seed.BggClientTest do
  use PukllayClub.DataCase, async: true

  test "fetches game data from BGG API stub" do
    # Req.Test intercepts all HTTP in this test; no network call is made
    # Stub responses via Req.Test configuration
  end
end
```

**Database Sandbox:**
```elixir
# In test_helper.exs:
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(PukllayClub.Repo, :manual)

# Each test is isolated; changes don't persist between tests
# Allows async: true because Sandbox handles row-level locking
```

**What to Mock:**
- External HTTP APIs (BGG, R2/S3) — use Req.Test stubs
- Minimal mocking of internal functions — prefer real implementations and fixtures

**What NOT to Mock:**
- Repo calls — use real database with fixtures
- Context module functions — test the real implementation
- Internal query builders — test via the top-level Catalog functions

## Fixtures and Factories

**Test Data:**
```elixir
defmodule PukllayClub.CatalogFixtures do
  def game_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "Catán",
      csv_row: System.unique_integer([:positive]),
      bgg_id: 13,
      min_players: 3,
      max_players: 4,
      min_playtime: 60,
      max_playtime: 90,
      min_age: 10,
      year_published: 1995,
      weight_band: "ingenio_estratega",
      bgg_weight: 2.3,
      tags: ["#CreaConexiones"],
      mechanics: ["Dice Rolling", "Hand Management"],
      themes: ["Economic"],
      designers: ["Klaus Teuber"],
      publishers: ["Devir"],
      description: "Compite por colonizar la isla de Catán.",
      thumbnail_url: "https://images.test.invalid/games/13/cover-thumb.webp",
      cover_url: "https://images.test.invalid/games/13/cover-large.webp",
      gallery_urls: [],
      enrichment_status: "enriched"
    }

    %Game{}
    |> Game.seed_changeset(Map.merge(default_attrs, attrs))
    |> Repo.insert!()
  end
end
```

**Location:**
- `test/support/fixtures/catalog_fixtures.ex` — all game-related test data builders
- Imported in tests: `import PukllayClub.CatalogFixtures`
- Called as: `game_fixture()` or `game_fixture(%{name: "Custom Game"})`

**Pattern:**
- Fixtures provide sane Spanish defaults so tests focus on one behavior
- Overrides via attrs parameter: `game_fixture(%{name: "Zeta", mechanics: ["Auction / Bidding"]})`
- Unique constraint on `csv_row` avoided via `System.unique_integer([:positive])`
- Signature kept stable (`attrs \\ %{}`) so new fixtures can be added in later phases without breaking call sites

## Coverage

**Requirements:** No explicit target percentage enforced, but all code is expected to be exercised by tests

**View Coverage:**
```bash
mix coveralls.html         # Generates cover/ directory with HTML report
open cover/excoveralls.html  # View in browser
```

**Tool Configuration:**
- `excoveralls` hex package version ~0.18
- Configured in `mix.exs`: `test_coverage: [tool: ExCoveralls]`
- Test-only dependency: `{:excoveralls, "~> 0.18", only: :test}`

## Test Types

**Unit Tests (Context Logic):**
- File: `test/pukllay_club/catalog_test.exs`
- Scope: Pure function behavior (filter, search, sort, pagination)
- Approach: Arrange (create fixtures) → Act (call function) → Assert (check result)
- Example: `test "filter on mechanic labels returns games matching EITHER"`
- No HTTP, no LiveView, no UI rendering

**Integration Tests (Context + Database):**
- File: `test/pukllay_club/catalog_test.exs` (same unit test file)
- Scope: Context functions interacting with Repo (Ecto queries)
- Approach: Create fixtures → call Catalog function → assert on returned data
- Database isolation via SQL.Sandbox (async safe)

**Component Tests (Rendering):**
- File: `test/pukllay_club_web/components/game_card_test.exs`
- Scope: Stateless Phoenix.Component rendering
- Approach: Build assigns → render component → assert HTML
- Uses `render_component(&Module.function/1, assigns: ...)`
- No database needed (`use ExUnit.Case, async: true`)

**LiveView Tests:**
- File: `test/pukllay_club_web/live/catalog_live_test.exs`
- Scope: Full LiveView lifecycle (mount, handle_event, render)
- Approach: `live(conn, path)` → send events → assert on HTML output
- Uses `PukllayClubWeb.ConnCase` (database + HTTP connection)
- Example: `assert {:ok, _view, html} = live(conn, ~p"/")`

**E2E Tests:**
- Not in current test suite
- Noted as future work for real browser automation

## Common Patterns

**Async Testing:**
```elixir
defmodule PukllayClub.CatalogTest do
  use PukllayClub.DataCase, async: true
  
  test "async test runs in parallel with other async tests" do
    game_fixture(%{name: "Parallel Test"})
    assert [game] = Catalog.list_games()
  end
end

# SQL.Sandbox.mode(:manual) allows async: true
# Sandbox pins each test to its own transaction; changes are isolated
```

**Error Testing:**
```elixir
test "get_game! raises Ecto.NoResultsError for unknown id" do
  assert_raise Ecto.NoResultsError, fn ->
    Catalog.get_game!(9999)
  end
end
```

**LiveView Event Testing:**
```elixir
test "search event updates socket assigns and re-renders" do
  {:ok, view, _html} = live(conn, ~p"/")
  
  assert render_submit(view, "search", %{"q" => "Catán"}) =~ "Catán"
end
```

**HTML Assertion in Templates:**
```elixir
test "renders game name in HTML" do
  game_fixture(%{name: "Terra Mystica"})
  {:ok, _view, html} = live(conn, ~p"/")
  
  assert html =~ "Terra Mystica"
end

test "never renders broken BGG image link" do
  game_fixture()
  {:ok, _view, html} = live(conn, ~p"/")
  
  refute html =~ "geekdo-images.com"
end
```

**String Trimming and Whitespace:**
```elixir
test "component renders nothing for empty list" do
  html = render_component(&GameChips.chip_row/1, terms: [], limit: 4)
  
  assert String.trim(html) == ""
end
```

**Fixture Variation Pattern:**
```elixir
test "player count filter matches games in range" do
  game_fixture(%{name: "Fits4", min_players: 2, max_players: 5})
  game_fixture(%{name: "TooFew", min_players: 5, max_players: 6})
  game_fixture(%{name: "TooMany", min_players: 1, max_players: 3})

  names = [players: 4] |> Catalog.filter_games() |> Enum.map(& &1.name)
  
  assert "Fits4" in names
  refute "TooFew" in names
end
```

## Test Sandbox Configuration

**Mode:** `:manual` (manual transaction control)
```elixir
# test/test_helper.exs
Ecto.Adapters.SQL.Sandbox.mode(PukllayClub.Repo, :manual)
```

**Behavior:**
- Each test starts a transaction; all changes are rolled back after
- Async tests can run in parallel without contention (row-level locking within transaction)
- No cleanup needed between tests; Sandbox handles isolation

**Multi-Database Partitioning:**
```elixir
# config/test.exs
database: "pukllay_club_test#{System.get_env("MIX_TEST_PARTITION")}"
pool_size: System.schedulers_online() * 2
```

## Test Case Templates

**DataCase (for database tests):**
```elixir
# test/support/data_case.ex
defmodule PukllayClub.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import PukllayClub.DataCase
      alias PukllayClub.Repo
    end
  end

  setup tags do
    PukllayClub.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Sandbox.start_owner!(PukllayClub.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end
end
```

**ConnCase (for HTTP/LiveView tests):**
```elixir
# test/support/conn_case.ex
defmodule PukllayClubWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use PukllayClubWeb, :verified_routes
      import Phoenix.ConnTest
      import Plug.Conn
      import PukllayClubWeb.ConnCase
      @endpoint PukllayClubWeb.Endpoint
    end
  end

  setup tags do
    PukllayClub.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
```

## Error Handling in Tests

**Rescue in Tests:**
```elixir
defp safe_filter_games(opts) do
  {:ok, Catalog.filter_games(opts)}
rescue
  _error -> :error
end
```

**In LiveView:** The `safe_filter_games/1` wrapper is used in `handle_event` to return `:error` instead of crashing; the handler assigns `:load_error` flag and renders error UI.

**Test Coverage:** Error paths tested via:
1. `assert_raise` for expected exceptions
2. Pattern matching on error tuples
3. Checking error flags set on socket assigns

---

*Testing analysis: 2026-08-18*
