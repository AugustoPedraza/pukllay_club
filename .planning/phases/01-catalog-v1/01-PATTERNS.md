# Phase 1: Catalog v1 - Pattern Map

**Mapped:** 2026-07-28
**Files analyzed:** 16 (new/modified)
**Analogs found:** 4 exact-generated-default / 12 no-analog (greenfield, first custom code in this repo)

**Context:** This repo contains only Phase 0's `mix phx.new` walking skeleton — one health
controller, one page controller, stock `core_components.ex`, one no-op migration, empty
`priv/repo/seeds.exs`. There is **no existing context module, no existing LiveView, no existing
custom migration, no existing seed/mix-task pattern** anywhere in the codebase. Phase 1 is the
first phase to write any of these. Consequently, analogs below are mostly the **generated
Phoenix/Ecto defaults** (router pipeline shape, `Repo` config, migration DSL) rather than
project-specific precedent — the planner should treat RESEARCH.md's Code Examples section as the
primary implementation reference where no real analog exists, and this file as the source for
"how this specific repo is already wired" (module naming, router pipeline conventions, component
conventions).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `lib/pukllay_club/catalog.ex` | service (context) | CRUD/request-response | `lib/pukllay_club/repo.ex` (only existing "backend layer" file) | no-analog (first context module) |
| `lib/pukllay_club/catalog/game.ex` | model (Ecto schema) | CRUD | none (no schema exists in repo) | no-analog |
| `lib/pukllay_club/catalog/seed/excel_import.ex` | utility (file I/O) | batch/file-I/O | `priv/repo/seeds.exs` (empty stub) | no-analog |
| `lib/pukllay_club/catalog/seed/bgg_client.ex` | service (HTTP client) | request-response (external API) | none (`req` is a dep but unused so far) | no-analog |
| `lib/pukllay_club/catalog/seed/xml_parser.ex` | utility (transform) | transform | none | no-analog |
| `lib/pukllay_club/catalog/seed/image_pipeline.ex` | utility (file I/O) | file-I/O/batch | none | no-analog |
| `lib/mix/tasks/catalog.seed.ex` (or similar, one-time seed task) | utility (mix task) | batch | `priv/repo/seeds.exs` (stub, phx.new default) | no-analog |
| `priv/repo/migrations/..._create_games.exs` | migration | CRUD (DDL) | `priv/repo/migrations/20260727154440_create_deploy_proof.exs` | exact (same DSL, same `use Ecto.Migration`) |
| `priv/repo/migrations/..._add_games_gin_indexes.exs` | migration | CRUD (DDL) | `priv/repo/migrations/20260727154440_create_deploy_proof.exs` | role-match (index-only migration, same DSL) |
| `lib/pukllay_club_web/live/catalog_live/index.ex` | component (LiveView) | streaming/request-response | `lib/pukllay_club_web/controllers/page_controller.ex` + `page_html/home.html.heex` | role-match (only existing "public page" precedent, but it's a plain controller, not a LiveView) |
| `lib/pukllay_club_web/live/catalog_live/show.ex` | component (LiveView) | request-response | same as above | role-match |
| `lib/pukllay_club_web/components/game_card.ex` | component | request-response | `lib/pukllay_club_web/components/core_components.ex` (`button/1`, `flash/1`) | role-match (same `Phoenix.Component` conventions) |
| `lib/pukllay_club_web/components/filter_drawer.ex` | component | event-driven | `lib/pukllay_club_web/components/core_components.ex` | role-match |
| `lib/pukllay_club_web/components/carousel_row.ex` | component | request-response | `lib/pukllay_club_web/components/core_components.ex` | role-match |
| `lib/pukllay_club_web/router.ex` (modified — add catalog routes) | route | request-response | itself (existing `scope "/", PukllayClubWeb do ... end` blocks) | exact (extend existing file, don't rewrite) |
| `test/pukllay_club/catalog_test.exs`, `test/pukllay_club_web/live/catalog_live_test.exs` | test | CRUD/request-response | no existing test dir contents shown beyond `test/support` (ConnCase/DataCase generated defaults, not read this pass) | role-match (use standard `ConnCase`/`DataCase` phx.new generators) |

## Pattern Assignments

### `priv/repo/migrations/..._create_games.exs` (migration, CRUD/DDL)

**Analog:** `priv/repo/migrations/20260727154440_create_deploy_proof.exs`

**Full pattern** (lines 1-17):
```elixir
defmodule PukllayClub.Repo.Migrations.CreateDeployProof do
  use Ecto.Migration

  def change do
    create table(:deploy_proof) do
      add :note, :string
    end
  end
end
```
Copy this exact shape (`use Ecto.Migration`, `def change do ... end`, `create table(...) do add ... end`)
for `create_games.exs`. Per RESEARCH.md Pattern 1 ("Bulk-load before GIN-indexing"), split into two
migrations: this one with scalar + `{:array, :string}` columns only (no GIN yet), and a second
`add_games_gin_indexes.exs` migration that runs after the seed task populates ~400 rows. See
RESEARCH.md's "Code Examples" section for the full column list (`bgg_id`, `weight_band`, `tags`,
`mechanics`, `themes`, `cover_url`, `thumbnail_url`, `gallery_urls`, generated `search_vector`
tsvector column, GIN indexes) — that is the primary reference since no richer schema exists in
this repo yet.

---

### `lib/pukllay_club/repo.ex` (existing, for reference — not modified)

```elixir
defmodule PukllayClub.Repo do
  use Ecto.Repo,
    otp_app: :pukllay_club,
    adapter: Ecto.Adapters.Postgres
end
```
Confirms standard Ecto Repo config — no custom telemetry/logging wrapper exists to replicate in
`catalog.ex`; the context module should call `Repo` directly (`alias PukllayClub.Repo`), matching
plain `Ecto.Repo` usage, not a custom repository-pattern wrapper.

---

### `lib/pukllay_club_web/router.ex` (route, modified)

**Existing pattern** (lines 21-25, 33-36):
```elixir
scope "/", PukllayClubWeb do
  pipe_through :browser

  get "/", PageController, :home
end

# Other scopes may use custom stacks.
# scope "/api", PukllayClubWeb do
#   pipe_through :api
# end
```
Add catalog LiveView routes inside the existing `:browser`-piped scope (no new pipeline needed —
CATALOG-08 requires no auth, and `:browser` already has no auth plug). Use standard
`live "/catalogo", CatalogLive.Index, :index` / `live "/catalogo/:id", CatalogLive.Show, :show`
inside the same `scope "/", PukllayClubWeb do pipe_through :browser end` block — do not create a
separate pipeline or scope. Note the existing `:browser` pipeline already has `:protect_from_forgery`
and `:put_secure_browser_headers`, which apply automatically to any route added inside that scope.

---

### `lib/pukllay_club_web/components/core_components.ex` (existing — analog for all new components)

**Module/import conventions** (lines 1-33):
```elixir
defmodule PukllayClubWeb.CoreComponents do
  use Phoenix.Component
  use Gettext, backend: PukllayClubWeb.Gettext

  alias Phoenix.LiveView.JS
  ...
```

**Attr/slot + conditional-class pattern** (lines 89-121, `button/1`):
```elixir
attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
attr :class, :any
attr :variant, :string, values: ~w(primary)
slot :inner_block, required: true

def button(%{rest: rest} = assigns) do
  variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

  assigns =
    assign_new(assigns, :class, fn ->
      ["btn", Map.fetch!(variants, assigns[:variant])]
    end)

  if rest[:href] || rest[:navigate] || rest[:patch] do
    ~H"""
    <.link class={@class} {@rest}>
      {render_slot(@inner_block)}
    </.link>
    """
  else
    ~H"""
    <button class={@class} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

**Conditional-class + directive pattern** (lines 57-87, `flash/1`), useful for `game_card.ex`'s
weight-band chip styling and `filter_drawer.ex`'s open/closed state:
```elixir
def flash(assigns) do
  assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

  ~H"""
  <div
    :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
    id={@id}
    ...
  >
    <div class={[
      "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
      @kind == :info && "alert-info",
      @kind == :error && "alert-error"
    ]}>
    ...
  """
end
```

**Apply to:** `game_card.ex`, `filter_drawer.ex`, `carousel_row.ex` — all should be `Phoenix.Component`
function components (not `Phoenix.LiveComponent` unless they need their own event handlers/state;
per RESEARCH.md, filter state and stream updates live in `CatalogLive.Index`, so these are most
likely plain stateless function components receiving assigns from the parent LiveView), using
`attr`/`slot` declarations and the `[...]` conditional-class-list Tailwind pattern shown above —
this is the one clear, real, repo-native convention to replicate exactly (daisyUI class names per
RESEARCH.md Pitfall 5: `carousel`/`carousel-item`, `drawer`/`drawer-toggle`/`drawer-side`/
`drawer-content`, `badge`/`badge-*` are v5-safe as-is).

---

### `lib/pukllay_club_web/controllers/page_controller.ex` + `page_html/home.html.heex` (existing — closest "page" precedent, though it's a controller not a LiveView)

```elixir
defmodule PukllayClubWeb.PageController do
  use PukllayClubWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
```
No LiveView exists yet to copy `mount/3`/`handle_event/3`/`stream/3` conventions from — this file
only confirms the `PukllayClubWeb.___, :controller|:live_view` macro-based module setup pattern
(see `lib/pukllay_club_web.ex` for the `use PukllayClubWeb, :live_view` macro definition, not read
this pass but standard for `mix phx.new` 1.8 scaffolding). For `catalog_live/index.ex` and
`catalog_live/show.ex`, RESEARCH.md's "Code Examples" Pattern 4 (`mount/3` + `handle_event("load-more"...)`
+ `handle_event("filter-changed"...)` with `stream/3`) is the primary and only available reference —
there is no in-repo LiveView to pattern-match against.

## Shared Patterns

### Module naming / namespacing
**Source:** All existing modules (`PukllayClub.Repo`, `PukllayClubWeb.PageController`,
`PukllayClubWeb.CoreComponents`)
**Apply to:** All new files — context modules under `PukllayClub.Catalog.*`, web modules under
`PukllayClubWeb.CatalogLive.*` / `PukllayClubWeb.*Component`, matching the existing
`PukllayClub`/`PukllayClubWeb` split (business logic vs. web layer) with no exceptions found in
the codebase.

### Migration DSL
**Source:** `priv/repo/migrations/20260727154440_create_deploy_proof.exs`
**Apply to:** Both new games migrations — plain `use Ecto.Migration`, `def change do ... end`, no
`up`/`down` split, matching the one existing migration exactly.

### Router pipeline reuse (no-auth)
**Source:** `lib/pukllay_club_web/router.ex` lines 4-11, 21-25
**Apply to:** All catalog LiveView routes — reuse the existing `:browser` pipeline unmodified
(CATALOG-08 "fully public, no account required" is already satisfied by the current pipeline
having no auth plug; do not add one).

### Component conventions (Phoenix.Component + Tailwind/daisyUI conditional classes)
**Source:** `lib/pukllay_club_web/components/core_components.ex` (see excerpts above)
**Apply to:** `game_card.ex`, `filter_drawer.ex`, `carousel_row.ex` — `attr`/`slot` declarations,
`assign_new` for computed defaults, `[...]` conditional Tailwind class lists, daisyUI v5-safe class
names (per RESEARCH.md Pitfall 5).

## No Analog Found

Files with no close match in the codebase — planner should use RESEARCH.md's Architecture Patterns
and Code Examples sections (Pattern 1-4, BGG client example, hashtag normalizer example) as the
primary implementation reference instead of an in-repo analog:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/pukllay_club/catalog.ex` | service (context) | CRUD/request-response | First context module in the repo — no existing `lib/pukllay_club/*.ex` business-logic module beyond `Repo`/`Mailer`/`Release` (infra shims) |
| `lib/pukllay_club/catalog/game.ex` | model | CRUD | No Ecto schema exists anywhere in the repo yet |
| `lib/pukllay_club/catalog/seed/*.ex` (bgg_client, xml_parser, image_pipeline, excel_import) | utility | file-I/O/batch/transform/request-response | No mix-task-adjacent utility module exists; `priv/repo/seeds.exs` is an untouched empty stub |
| `lib/mix/tasks/catalog.seed.ex` | utility (mix task) | batch | No custom mix task exists in the repo (`lib/mix/tasks/` doesn't exist yet) |
| `lib/pukllay_club_web/live/catalog_live/index.ex`, `show.ex` | component (LiveView) | streaming/request-response | No LiveView exists in the repo at all — Phase 0 shipped only a plain controller-rendered page and the generated `/dev/dashboard` LiveDashboard route (framework-internal, not app code) |

## Metadata

**Analog search scope:** `lib/`, `priv/repo/migrations/`, `mix.exs`, `test/` (directory listing
only, contents not read — likely just phx.new-generated `ConnCase`/`DataCase`)
**Files scanned:** 17 (full `lib/` tree + migrations dir + mix.exs)
**Pattern extraction date:** 2026-07-28
