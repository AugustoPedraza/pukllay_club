# Architecture Research

**Domain:** Single-node Phoenix 1.8 LiveView app — board-game catalog, NL search over pgvector, RAG rules oracle, club/rental ops
**Researched:** 2026-07-24
**Confidence:** MEDIUM (Phoenix/Ecto/phx.gen.auth patterns confirmed against official hexdocs; pgvector-elixir and hybrid-search patterns cross-checked across the library's own README plus 2-3 independent implementation write-ups; Bumblebee/ONNX ARM CPU throughput numbers are from non-ARM, non-Elixir benchmarks and remain a genuine unknown flagged for Phase 2's spike)

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         Single Phoenix 1.8 Release (BEAM node)            │
├──────────────────────────────────────────────────────────────────────────┤
│  LiveView / Web layer (request hot path — nothing >~50ms runs here)       │
│  ┌───────────┐ ┌───────────┐ ┌────────────┐ ┌────────────┐ ┌──────────┐  │
│  │CatalogLive│ │SearchLive │ │ RulesLive  │ │AdminLive/*  │ │AuthLive/* │  │
│  │(Streams)  │ │(Streams)  │ │(Streams)   │ │(Streams)    │ │(magic-link│  │
│  └─────┬─────┘ └─────┬─────┘ └─────┬──────┘ └─────┬───────┘ └────┬─────┘  │
├────────┼─────────────┼─────────────┼──────────────┼──────────────┼───────┤
│        │        Contexts (public API boundary — pure Elixir, no web)     │
│  ┌─────▼──────┐┌─────▼──────┐┌──────▼───────┐┌─────▼───────┐┌────▼─────┐ │
│  │  Catalog   ││  Search    ││ RulesOracle  ││  ClubOps    ││ Accounts │ │
│  │(games,     ││(hybrid     ││ (documents,  ││(copies,     ││(User,    │ │
│  │ copies,    ││ query, RRF ││  chunks,     ││ rentals,    ││ scope,   │ │
│  │ tags[])    ││ ranking)   ││  retrieval)  ││ promos)     ││ tokens)  │ │
│  └─────┬──────┘└─────┬──────┘└──────┬───────┘└─────┬───────┘└────┬─────┘ │
├────────┼─────────────┼──────────────┼──────────────┼──────────────┼──────┤
│        │        Async / off-hot-path layer (Oban queues + PubSub)        │
│  ┌─────▼─────────────▼──────────────▼──────────────▼───────┐            │
│  │ Oban.Worker modules: Search.EmbedQuery, Search.ParseNLQuery,          │
│  │ Catalog.EmbedGame, RulesOracle.IngestDocument, RulesOracle.Answer     │
│  │  → broadcast via Phoenix.PubSub("topic:id", {:done, result})         │
│  └─────────────────────────────┬──────────────────────────┘            │
├───────────────────────────────┼───────────────────────────────────────┤
│                     One PostgreSQL 16+ database (pgvector, pg_trgm)     │
│  ┌──────────┐ ┌───────────────┐ ┌────────────┐ ┌────────┐ ┌──────────┐ │
│  │ games     │ │ game_embeddings│ │ rulebook_  │ │ copies/ │ │ users/  │ │
│  │ tags:text[]│ │ vector(384)   │ │ chunks     │ │ rentals │ │ tokens  │ │
│  │ + GIN     │ │ + HNSW        │ │ vector(384)│ │         │ │         │ │
│  │ tsvector  │ │               │ │ + HNSW+GIN │ │         │ │         │ │
│  └──────────┘ └───────────────┘ └────────────┘ └────────┘ └──────────┘ │
│                        oban_jobs table lives here too                   │
└──────────────────────────────────────────────────────────────────────────┘
                    │                                    │
            local ONNX/Bumblebee/Ortex             remote free-tier LLM
            embedding inference (CPU,               (Gemini via
            in-process Nx.Serving)                  InstructorLite,
                                                      HTTP, async only)
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|-------------------------|
| LiveView modules (`*Live`) | Render, handle UI events, subscribe to PubSub topics, call contexts for *fast* reads only | `Phoenix.LiveView`, `stream/4` for every list, `handle_info/2` for async results |
| Context modules (`Catalog`, `Search`, `RulesOracle`, `ClubOps`, `Accounts`) | Public API boundary; own their schemas; enforce invariants; the only thing LiveViews and Oban workers call into | Plain Elixir modules per `hexdocs.pm/phoenix/contexts.html`; no context calls another context's schema directly — it calls that context's public functions |
| Oban workers (`lib/pukllay_club/<context>/workers/*.ex`) | Everything slower than ~50ms: local embedding inference, remote LLM calls, RAG retrieval+generation, doc ingestion/chunking, image resizing | `Oban.Worker`, one queue per resource class (`:embeddings`, `:llm`, `:ingestion`) so a slow LLM call can't starve fast embedding jobs |
| PubSub topics | Deliver async job results back to the *specific* LiveView process/session that requested them | `Phoenix.PubSub.broadcast/3` keyed by a request-scoped id (`"search:#{live_view_pid_or_ref}"`), not a global topic |
| Postgres (single DB) | System of record for catalog, tags, embeddings (games + rulebook chunks), rulebook text, rentals, auth, and the Oban job queue itself | One `pukllay_club_prod` database; `pgvector` + `pg_trgm`/`unaccent` extensions; Oban's own tables live in the same DB (no separate queue infra) |
| Local embedding runtime | Turn Spanish text (game descriptions, user queries, rulebook chunks) into vectors, in-process, on CPU | `Bumblebee`/`Nx.Serving` or `Ortex` (ONNX Runtime) wrapping a small multilingual sentence-embedding model, started under the app's supervision tree |
| Remote LLM client | Structured generation only: NL-query parsing (Phase 2) and grounded rules answers (Phase 3); never called synchronously from `handle_event` | `InstructorLite` + Gemini adapter, called only from inside Oban workers |

## Recommended Project Structure

```
lib/pukllay_club/
├── catalog/                 # Phase 1 context — always-present, foundational
│   ├── catalog.ex           # public API: list_games/1, get_game!/1, filter_games/1
│   ├── game.ex               # schema: tags {:array,:string}+GIN, tsvector search_vector
│   └── copy.ex                # schema for physical copies (owned by ClubOps in Phase 4, FK'd from here)
├── search/                  # Phase 2 context — added, does not restructure catalog/
│   ├── search.ex            # public API: search/1 (sync fast path), request_nl_search/2 (enqueues Oban)
│   ├── game_embedding.ex     # schema: vector(N) column, belongs_to :game
│   ├── parsed_query.ex        # Ecto embedded_schema — the InstructorLite response_model
│   └── workers/
│       ├── embed_query.ex     # Oban worker: text -> local embedding -> PubSub
│       └── parse_nl_query.ex  # Oban worker: text -> InstructorLite/Gemini -> structured filters -> PubSub
├── rules_oracle/             # Phase 3 context — added, reuses Search's embedding runtime
│   ├── rules_oracle.ex       # public API: ask/2 (enqueues), documents/0
│   ├── document.ex            # schema: rulebook metadata (game_id FK, source file, version)
│   ├── chunk.ex                # schema: vector(N), tsvector, belongs_to :document
│   └── workers/
│       ├── ingest_document.ex # chunk + embed a rulebook PDF/text (admin-triggered, async)
│       └── answer_question.ex # retrieve top-k chunks -> InstructorLite/Gemini -> grounded answer -> PubSub
├── club_ops/                 # Phase 4 context — added last, against a stable schema
│   ├── club_ops.ex           # public API: check_out!/2, check_in!/2, list_active_rentals/0
│   ├── rental.ex               # schema: copy_id, user_id/member, checked_out_at, returned_at
│   └── promotion.ex
├── accounts/                 # phx.gen.auth-generated (Phase 2) — untouched by other contexts
│   ├── accounts.ex
│   ├── scope.ex               # injected into Search/RulesOracle/ClubOps functions that need current_user
│   ├── user.ex
│   └── user_token.ex
└── embeddings/                # cross-context infra, not a "business" context
    └── runtime.ex             # thin wrapper around Nx.Serving/Ortex; Search and RulesOracle both call this

lib/pukllay_club_web/
├── live/
│   ├── catalog_live/          # index.ex (stream), show.ex
│   ├── search_live/           # index.ex — submits query, subscribes to own topic, renders stream
│   ├── rules_live/            # ask.ex — submits question, streams partial/final answer
│   └── admin/                 # nested under a plug-enforced admin scope, Phase 4 only
```

### Structure Rationale

- **One context per roadmap phase, in `lib/pukllay_club/`, never split across an umbrella.** Each phase in PROJECT.md (Catalog, Search, RulesOracle, ClubOps) maps 1:1 to a context added at that phase — this is deliberate: it lets each phase land as an additive module without refactoring earlier contexts, and it matches the fixed phase order (later phases never need to "pull forward" earlier code).
- **`embeddings/runtime.ex` is infrastructure, not a context.** It has no schema and no business rules — it is a shared low-level capability (`embed(text) :: {:ok, [float]}`) that both `Search` (Phase 2) and `RulesOracle` (Phase 3) depend on. Putting it in its own `embeddings/` folder (not nested inside `search/`) avoids `RulesOracle` having to reach into `Search`'s internals when Phase 3 lands.
- **Oban workers live inside the context that owns the job's data, under `workers/`,** not in a top-level `lib/pukllay_club/workers/`. This keeps `Search.EmbedQuery` next to `Search`'s schemas and makes the context's async surface visible from its own directory.
- **`copy.ex` schema lives in `catalog/` even though `club_ops/` owns rental *behavior*.** A physical copy is fundamentally catalog data (which game, which condition) — Phase 4 adds rental *tracking* on top via a `rentals` table that FKs to `copies`, rather than redefining what a copy is. This avoids a Phase 4 migration that touches Phase 1 tables' meaning.
- **`accounts/` is untouched scaffolding from `phx.gen.auth`.** Every context that needs authorization (`Search.request_nl_search/2` for favorites, all of `club_ops`, admin-only writes in `catalog`) takes a `Scope` struct as documented in the Phoenix 1.8 generator output, rather than each context inventing its own auth check.

## Architectural Patterns

### Pattern 1: Enqueue-and-subscribe (the async hot-path rule, enforced structurally)

**What:** Any context function that would take >~50ms (embedding generation, LLM calls, RAG retrieval+generation, image processing, CSV/document ingestion) never runs inline in `handle_event`. Instead the context exposes two functions: a fast one that enqueues an Oban job and returns immediately, and the job itself does the work and broadcasts the result.
**When to use:** Every LLM call (Phase 2 query parsing, Phase 3 answer generation), every embedding computation, and any Phase 3 document ingestion.
**Trade-offs:** Requires every "slow" LiveView interaction to show a loading/pending state and handle the async result in `handle_info/2` — slightly more code per feature than a naive synchronous call, but it's what keeps a single BEAM node responsive under concurrent users with zero added infra (Oban's queue lives in the same Postgres DB already required).

**Example:**
```elixir
# lib/pukllay_club/search.ex
def request_nl_search(query_text, live_view_ref) do
  topic = "nl_search:#{live_view_ref}"
  %{query: query_text, topic: topic}
  |> PukllayClub.Search.Workers.ParseNLQuery.new()
  |> Oban.insert()

  {:ok, topic}
end

# lib/pukllay_club/search/workers/parse_nl_query.ex
defmodule PukllayClub.Search.Workers.ParseNLQuery do
  use Oban.Worker, queue: :llm, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"query" => query, "topic" => topic}}) do
    with {:ok, parsed} <- PukllayClub.Search.parse_query(query),       # InstructorLite/Gemini call
         {:ok, embedding} <- PukllayClub.Embeddings.Runtime.embed(query), # local CPU embedding
         {:ok, results} <- PukllayClub.Search.hybrid_search(parsed, embedding) do
      Phoenix.PubSub.broadcast(PukllayClub.PubSub, topic, {:nl_search_results, results})
    else
      {:error, reason} -> Phoenix.PubSub.broadcast(PukllayClub.PubSub, topic, {:nl_search_error, reason})
    end
  end
end

# lib/pukllay_club_web/live/search_live/index.ex
def handle_event("search", %{"q" => q}, socket) do
  {:ok, topic} = Search.request_nl_search(q, socket.assigns.session_ref)
  Phoenix.PubSub.subscribe(PukllayClub.PubSub, topic)
  {:noreply, assign(socket, :searching?, true)}
end

def handle_info({:nl_search_results, results}, socket) do
  {:noreply, socket |> assign(:searching?, false) |> stream(:results, results, reset: true)}
end
```

### Pattern 2: text[] + GIN for multi-valued tags (no join table)

**What:** Tags (mechanics, themes) live as a native Postgres `text[]` column with a GIN index, queried with `= ANY(?)` (single tag) or `&&` array-overlap (any-of-N) — instead of a `games_tags` join table.
**When to use:** From Phase 1 onward, for every multi-valued categorical attribute that doesn't yet need its own metadata (description, icon, translation). If a tag later needs metadata, promote *that specific dimension* to a join table without touching the others.
**Trade-offs:** Cannot cheaply attach per-tag metadata (e.g. a mechanic's own description) without a separate lookup table keyed by the same string values; array containment queries are less familiar to newcomers than `JOIN`s but are well-indexed and simpler to write for this scale (~400 games).

**Example:**
```elixir
# migration
create table(:games) do
  add :name, :string, null: false
  add :mechanics, {:array, :string}, default: []
  add :themes, {:array, :string}, default: []
  timestamps()
end
create index(:games, [:mechanics], using: :gin)
create index(:games, [:themes], using: :gin)

# schema
schema "games" do
  field :name, :string
  field :mechanics, {:array, :string}, default: []
  field :themes, {:array, :string}, default: []
  timestamps()
end

# query: games with ALL of the given mechanics
from(g in Game, where: fragment("? @> ?", g.mechanics, ^selected_mechanics))

# query: games with ANY of the given mechanics (typical filter UX)
from(g in Game, where: fragment("? && ?", g.mechanics, ^selected_mechanics))
```

### Pattern 3: Local embeddings + remote LLM, split by job type (never merged into one call)

**What:** Two distinct external dependencies with different failure/latency/cost profiles are kept in separate Oban workers/queues rather than one "do everything" job: (1) local CPU embedding inference (fast, free, no network, in-process `Nx.Serving`) and (2) remote free-tier LLM calls for structured generation (slower, rate-limited, network-dependent).
**When to use:** Query parsing (Phase 2) needs both — parse intent via LLM *and* embed the raw text — but they should be two jobs (or two steps with independent retry policies) so a Gemini free-tier rate-limit doesn't block the always-available local embedding path, and vice versa.
**Trade-offs:** Slightly more orchestration (two jobs or a `with` chain with distinct error branches) in exchange for independent retry/backoff policies and the ability to degrade gracefully (e.g. serve pure-vector results if the LLM parse fails or times out).

## Data Flow

### Request Flow (Phase 2 NL search, the representative "hard" case)

```
User types Spanish query in SearchLive
    ↓ handle_event("search", ...)
Search.request_nl_search/2 (context, <10ms: just an Oban.insert)
    ↓ enqueues Oban job on :llm queue                    ↓ returns topic immediately
LiveView subscribes to PubSub topic, shows spinner        (request cycle ends here — no wait)
    ↓ (async, off request path)
Oban worker: InstructorLite → Gemini (parse intent + filters)
    ↓
Oban worker: Embeddings.Runtime.embed/1 (local CPU, in-process Nx.Serving)
    ↓
Search.hybrid_search/2 → one SQL query: GIN tsvector rank ∪ pgvector cosine_distance rank
                          fused via reciprocal rank fusion (RRF), scored, LIMIT N
    ↓
Phoenix.PubSub.broadcast(topic, {:nl_search_results, results})
    ↓
SearchLive.handle_info/2 → stream(:results, results, reset: true) → diff sent to browser
```

### State Management

```
Postgres (source of truth: games, tags, embeddings, chunks, rentals, oban_jobs)
    ↓ read (fast context calls, <50ms)              ↑ write (Oban workers, async)
LiveView process state (assigns + streams)  ←──── PubSub broadcast (job completion)
    ↓ diff
Browser DOM (via LiveView's stream-aware patching — no full collection re-render)
```

### Key Data Flows

1. **Catalog browse/filter (Phase 1, all synchronous):** `CatalogLive` calls `Catalog.filter_games/1` directly in `handle_event` — this is a plain indexed Postgres query (scalar WHERE + GIN array/tsvector), well under 50ms, so it never touches Oban/PubSub. This is the baseline "fast path" every later phase's async work must not degrade.
2. **NL search (Phase 2):** described above — enqueue, subscribe, two async steps (LLM parse + local embed), fused SQL read, broadcast, stream update. Favorites (also Phase 2) are a fast synchronous context write (`Search.toggle_favorite/2`) — no Oban needed, it's a simple row insert/delete.
3. **RAG rules Q&A (Phase 3):** `RulesLive` enqueues `RulesOracle.Workers.AnswerQuestion`; the worker embeds the question (reuses `Embeddings.Runtime`, same local model as Search), retrieves top-k chunks from `chunks` (hybrid FTS+vector, same RRF pattern as catalog search but scoped to one document/game), builds a grounded prompt, calls Gemini via InstructorLite for the final answer, broadcasts. Document *ingestion* (admin uploads a rulebook) is a separate, heavier async pipeline (`IngestDocument`: extract text → chunk → embed each chunk → bulk insert) triggered from an admin action, not from a member-facing request.
4. **Rental tracking (Phase 4, mostly synchronous):** `ClubOps.check_out!/2` and `check_in!/2` are simple, fast Ecto transactions (update a `rentals` row + a `copies.status` column) — no Oban needed. PubSub is still useful here, but for a different reason: broadcasting rental-state changes to any other admin viewing the same copy list in real time (multi-admin concurrency), not because the work is slow.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|---------------------------|
| ~400 games, dozens of concurrent members (this project's actual target) | Single Phoenix node + single Postgres, exactly as constrained. HNSW index on `game_embeddings.embedding` (build-once, small N, HNSW's slower build time is irrelevant at this row count). In-process `Nx.Serving` embedding pool sized to a handful of concurrent inferences — CAX31's 8 vCPUs are plenty for this load. |
| A few thousand games / hundreds of concurrent members | Still one node. Tune Oban queue concurrency (`:llm` queue kept intentionally low — e.g. 2-4 concurrent — to respect Gemini free-tier rate limits; `:embeddings` queue can run higher concurrency since it's local CPU). Add a Postgres connection-pool ceiling check (`DBConnection`/Ecto pool size) before touching anything else. |
| Tens of thousands of games / many concurrent members | Out of scope for this project's stated ambitions, but the natural next steps *within the same constraints* (still no k8s/broker) would be: vertical scale the Hetzner node, move nightly backup/ingestion-heavy Oban jobs to off-peak cron windows, and reconsider IVFFlat-with-tuned-lists vs HNSW only if index build time becomes a real bottleneck — not before. |

### Scaling Priorities

1. **First bottleneck (realistic for this project): Gemini free-tier rate limits, not compute.** Because LLM calls are already isolated to their own Oban queue, the fix is queue-level (lower concurrency, backoff, `unique` job constraints to avoid duplicate parses of the same query) — never a new service.
2. **Second bottleneck (if it ever mattered): Postgres write contention from Oban's polling/locking under a single DB doing double duty as app DB + job queue.** At this project's scale (hundreds, not millions, of jobs/day) this is theoretical; Oban's `FOR UPDATE SKIP LOCKED` polling is designed for exactly this shared-DB pattern and is why the PROJECT.md constraint ("Oban covers async work at this scale, no message broker") is sound.

## Anti-Patterns

### Anti-Pattern 1: Calling InstructorLite/Gemini (or any HTTP-bound LLM client) directly inside `handle_event`

**What people do:** `handle_event("search", ...)` calls the LLM synchronously "just to keep it simple," because it's tempting during a demo/prototype.
**Why it's wrong:** Blocks the LiveView process (and the whole page's responsiveness) for however long the remote API takes — worse, Gemini free-tier calls can be slow or rate-limited, turning an occasional slowdown into a hung UI. This directly violates the project's explicit "never an LLM call on the request hot path" and "nothing slower than ~50ms in handle_event" rules.
**Instead:** Always the enqueue-and-subscribe pattern (Pattern 1 above) — no exceptions, including for admin-only or "just this once" features.

### Anti-Pattern 2: One giant `Catalog` context that later phases keep extending

**What people do:** Put `Game`, `GameEmbedding`, `Chunk`, `Rental` all inside the original `Catalog` context because "it's all about games" and it's less setup than defining new contexts.
**Why it's wrong:** Couples Phase 1's schema/API surface to Phase 2/3/4 concerns that don't exist yet, forces every later phase to touch and re-test Phase 1's already-shipped, already-validated context, and makes it hard to reason about "what does Search actually need from Catalog" as a stable public API.
**Instead:** New context per phase (`Search`, `RulesOracle`, `ClubOps`), each exposing the narrow slice of `Game`/`Copy` data it needs via `Catalog`'s public functions (or a lightweight FK'd schema of its own, like `game_embedding.ex` `belongs_to :game`), never reaching into `Catalog`'s internal query building.

### Anti-Pattern 3: Building the pgvector/RAG schema "for real" in Phase 0 or Phase 1 "to save a migration later"

**What people do:** Add the `vector` extension, embedding columns, and Oban to the walking-skeleton phase because "we know we'll need it," gold-plating the deploy pipeline before it's proven.
**Why it's wrong:** PROJECT.md explicitly scopes Phase 0 to a working deploy pipeline with *no* product features, AI, Oban, or BGG import — adding pgvector/Oban early means debugging deploy plumbing and AI plumbing simultaneously, and risks the ARM/aarch64 Docker image needing native deps (e.g. compiled NIFs for `pgvector`/`ex_bumblebee`/`ortex`) before the base image and build pipeline are even proven.
**Instead:** Phase 0 proves the deploy loop with the bare Ecto/Postgres/Kamal path. It's fine — and cheap — for Phase 0 to leave *room* (see Build-Order Implications below) without installing the actual dependencies yet.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|----------------------|-------|
| Gemini (LLM, free tier) | `InstructorLite` + `InstructorLite.Adapters.Gemini`, called only from Oban workers | v1.2+ of instructor_lite uses Gemini's native `responseJsonSchema`, avoiding earlier JSON-schema workarounds; keep the `:llm` Oban queue's concurrency low to respect free-tier rate limits and add `max_attempts`/backoff for 429s |
| Cloudflare R2 (backups) | `pg_dump` via a nightly cron/systemd timer on the Hetzner node (or an Oban cron plugin job), pushed via S3-compatible client | Already scoped in PROJECT.md/Phase 0; not an "architecture" concern for the app's contexts, but the backup job should live outside any request path too |
| Local embedding model (Bumblebee/Ortex) | In-process `Nx.Serving`, started as a child in the application's supervision tree (not a separate OS process) | Loaded once at boot; a small multilingual sentence-embedding ONNX model is the right class for Spanish board-game text; genuine open question is ARM/aarch64 CPU throughput — this is why PROJECT.md already schedules an ARM embedding-runtime spike as Phase 2's first task rather than assuming it |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|----------------|-------|
| LiveView ↔ Context | Direct function calls, always synchronous, always <50ms | Any context function whose name suggests network/inference (`embed`, `parse_query`, `ask`) must not be called directly from `handle_event` — only its `request_*`/enqueue counterpart may be |
| Context ↔ Oban worker | Worker modules live under the owning context's `workers/` namespace and call back into the *same* context's other public functions (e.g. `Search.hybrid_search/2`) — workers are not a separate architectural layer with its own business logic | Keeps business rules in the context, not scattered into job modules |
| Oban worker ↔ LiveView | `Phoenix.PubSub.broadcast/3` on a request-scoped topic string, `handle_info/2` on the LiveView side | Never broadcast on a single global topic shared by all users — always scope by session/query id so unrelated users' LiveViews don't receive each other's job results |
| Search ↔ RulesOracle | Both depend on `Embeddings.Runtime` (shared infra module), but neither context calls into the other's schemas/queries directly | If Phase 3 ever needs "games mentioning this rule," it goes through `Catalog`'s public API, not a raw join across contexts |
| ClubOps ↔ Catalog | `ClubOps.Rental` has a `copy_id` FK into `Catalog.Copy`; `ClubOps` reads copy data via `Catalog`'s public functions, never queries the `copies` table directly from `club_ops.ex` | Preserves Catalog as the sole owner of catalog/copy invariants even though rentals are a Phase 4 concern |

## Build-Order Implications for Phase 0's Skeleton

PROJECT.md fixes the phase order (0 → 1 → 2 → 3 → 4) and explicitly scopes Phase 0 to *no* product features, AI, Oban, or BGG import. Based on the architecture above, here's what Phase 0 should still leave room for, without building it:

- **Ecto migration numbering/discipline that won't fight later additive migrations.** No action needed beyond normal Ecto conventions — `mix ecto.gen.migration` per phase naturally supports "add a context's tables later" as long as Phase 0 doesn't hand-roll a non-standard migration runner.
- **Confirm (don't yet use) that the Postgres image/version chosen in Phase 0 supports the `vector` extension later.** Standard Postgres 16+ images from most providers support installing `pgvector` as an extension without a base-image change; this should be verified once during Phase 0's infra setup (which Postgres image Kamal/Hetzner will run) so Phase 2 isn't blocked on a database engine swap. This is a one-line verification, not new work.
- **Release config should not hard-code "no background jobs."** Phase 0's `mix release` / Kamal setup should run the app as a normal OTP release with its full supervision tree (the default) rather than, say, disabling children by config — so that adding Oban's supervisor and an `Nx.Serving` child later (Phase 2) is a matter of adding entries to `application.ex`'s children list, not restructuring how the release boots.
- **Do not add the `vector` extension, Oban tables, embedding columns, or InstructorLite/Gemini config in Phase 0.** These belong to Phase 2/3 per PROJECT.md's explicit scoping — Phase 0's only job is proving the deploy loop (CI → Docker/ARM build → Kamal deploy → migrations-on-deploy → HTTPS → nightly `pg_dump` backup) with a trivial real app.
- **Secrets management approach chosen in Phase 0 (Kamal secrets vs env) should anticipate a Gemini API key arriving in Phase 2** without redesign — i.e., whatever mechanism Phase 0 picks for the DB URL/`SECRET_KEY_BASE` should generalize to "one more secret" rather than being a one-off hack for exactly two values.
- **Phase 1's `Catalog` context (tags as `text[]`+GIN, `tsvector` search) is the first real precedent-setter.** Getting this pattern right in Phase 1 matters because Phase 3's `RulesOracle.Chunk` schema reuses the same tsvector+GIN-alongside-vector-column shape — Phase 1 is effectively where the "hybrid search on one table" pattern gets proven at the *keyword-search-only* level (Postgres `tsvector`/GIN, no vectors yet), before Phase 2 adds the vector half.

## Sources

- [1. Intro to Contexts — Phoenix v1.8.8](https://hexdocs.pm/phoenix/contexts.html) — HIGH (official docs)
- [4. Cross-context Boundaries — Phoenix v1.8.2](https://hexdocs.pm/phoenix/cross_context_boundaries.html) — HIGH (official docs)
- [mix phx.gen.auth — Phoenix v1.8.8](https://hexdocs.pm/phoenix/mix_phx_gen_auth.html) — HIGH (official docs)
- [pgvector-elixir README / hexdocs](https://hexdocs.pm/pgvector/readme.html) — HIGH (official library docs, cross-checked against GitHub source)
- [Ecto.Migration hexdocs](https://hexdocs.pm/ecto_sql/3.0.0/Ecto.Migration.html) — HIGH (official docs)
- [Tag All the Things! · The Phoenix Files (Fly.io)](https://fly.io/phoenix-files/tag-all-the-things/) — MEDIUM (practitioner reference, aligns with official Ecto docs)
- [Hybrid search with PostgreSQL and pgvector — Jonathan Katz](https://jkatz05.com/post/postgres/hybrid-search-postgres-pgvector/) — MEDIUM (author is a Postgres/pgvector contributor; concrete SQL pattern)
- [GitHub - agoodway/vecto: Hybrid Search with Postgres and Ecto](https://github.com/agoodway/vecto) — MEDIUM (community library, confirms the pattern exists as prior art; not independently verified beyond search summary)
- [Build a Self-Hosted RAG with Postgres pgvector — digitalapplied.com](https://www.digitalapplied.com/blog/build-self-hosted-rag-postgres-pgvector-tutorial-2026) — MEDIUM (2026 practitioner guide)
- [pgvector Guide / "you probably don't need a vector database" — Encore Blog](https://encore.dev/blog/you-probably-dont-need-a-vector-database) — MEDIUM (practitioner argument, consistent with multiple independent sources)
- [GitHub - nshkrdotcom/rag_ex](https://github.com/nshkrdotcom/rag_ex) — MEDIUM (Elixir-specific prior art for pgvector-backed RAG with Gemini routing)
- [GitHub - martosaur/instructor_lite](https://github.com/martosaur/instructor_lite) — MEDIUM (project README via search; Gemini adapter behavior confirmed via ElixirForum announcement)
- [InstructorLite - Gemini structured outputs announcement — Elixir Forum](https://elixirforum.com/t/instructorlite-less-headache-with-gemini-structured-outputs-for-anthropic-models/74143) — MEDIUM
- [Elixir Machine Learning: Using Pre-trained ONNX Models with Ortex — DockYard](https://dockyard.com/blog/2024/03/19/elixir-machine-learning-pre-trained-onnx-models-with-ortex) — MEDIUM (practitioner reference from a known Elixir consultancy)
- [How to compute LLM embeddings 3X faster with model quantization — Nixiesearch/Medium](https://medium.com/nixiesearch/how-to-compute-llm-embeddings-3x-faster-with-model-quantization-25523d9b4ce5) — LOW-MEDIUM (non-Elixir, non-ARM benchmark; directional only — treat CPU throughput numbers as illustrative, not a guarantee for the Hetzner CAX31 ARM node; this is exactly why PROJECT.md schedules a Phase 2 spike)
- [How to Use Phoenix LiveView with Oban for Real-Time Background Job Monitoring — Medium](https://hexshift.medium.com/how-to-use-phoenix-liveview-with-oban-for-real-time-background-job-monitoring-20e0c9efea28) — MEDIUM (practitioner pattern, consistent with Oban's own documented `Oban.Notifier`/PubSub-adjacent design)

---
*Architecture research for: single-node Phoenix/LiveView board-game catalog + NL search + RAG + club ops*
*Researched: 2026-07-24*
