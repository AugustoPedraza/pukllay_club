This is a web application written using the Phoenix web framework.

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

## TDD Loop

1. Derive/write a test from the acceptance criterion being implemented.
2. Run it — confirm it fails (red).
3. Write the minimum code to make it pass (green).
4. Refactor with the test green as a safety net.
5. Run `mix quality` before committing.

## `mix quality` Alias

Order: `hex.audit` -> `deps.audit` -> `deps.unlock --check-unused` -> `format --check-formatted` ->
`credo --strict` -> `sobelow --config` -> `test --warnings-as-errors`.

Cheapest/fastest checks run first — `hex.audit`/`deps.audit`/`deps.unlock --check-unused` are
metadata-only checks against mix.lock/mix.exs with no compilation step, so they run ahead of
`format`; a formatting typo then fails in seconds, not after a full test-suite run. Run `mix
quality` locally before every commit; it is also what CI runs on every PR and again on every merge
to `main` (see Manual Merge Gate below).

`format --check-formatted` also runs **Styler** (`adobe/elixir-styler`), wired as a `mix format`
plugin via `.formatter.exs`'s `plugins` list — it auto-fixes non-idiomatic Elixir on every `mix
format` run, guarding against AI-generated code drift. Styler's own README warns it "can change the
behaviour of your program" (e.g. `case`->`if` rewrites can alter semantics). **Always review `git
diff` for every Styler-produced rewrite before committing** — first-run or future, do not accept
rewrites on trust.

## Manual Merge Gate

Every PR must pass CI (`mix quality`, run against a Postgres service) before merge. No merge bypasses
this gate — not for "trivial" changes, not via admin/force-merge. Merging to `main` re-runs
`mix quality` a second time as a build/deploy gate, so a broken merge never reaches production (D-04).
Treat a failing or hanging health check (Kamal's `/up` probe) the same way: fix the underlying
readiness issue, never disable or loosen the check to force a deploy through.

## Social/Crawler Head-Block Changes

Any change to the meta/Open Graph/Twitter head block (`lib/pukllay_club_web/components/seo_tags.ex`,
`lib/pukllay_club_web/components/layouts/root.html.heex`) must be re-verified against a strict
link-preview crawler before shipping, by running
`node test/production/og_tags_whatsapp_ua.mjs <deployed-url>` against the deployed host. Passing
Facebook Sharing Debugger, Twitter Card Validator, or Google Rich Results Test does **not**
substitute for this — those parsers are tolerant of markup a strict crawler (WhatsApp) rejects,
which is exactly how G-01.8-3 (an attribute interposed before `property=`/`name=`, from LiveView's
`phx-r` root-tag stamping) shipped to production while every one of those three validators passed.
See `.planning/debug/whatsapp-og-image-preview.md` for the full diagnosis.

## Domain & DNS

`pukllay.club` is registered at Spaceship, and its DNS is hosted there too. DNS is not managed from
this repo. `docs/runbooks/domain-and-dns.md` records the registrar, expiry date, current records
and how to verify them. Update it whenever a DNS record changes.

## Non-Goals (Phase 0)

Phase 0 is the deploy pipeline only — a proven walking skeleton, not gold-plating:

- No product features: no catalog, no auth, no AI/embeddings, no Oban, no BGG import.
- No log-aggregation dashboard beyond Sentry (crash capture) + stdout (`kamal app logs`).
- No alerting service beyond CI failure signals and `kamal deploy` failure output (D-07).
- No automated backup restore-test — restores are manual and periodic, not scripted.
- No secrets-manager integration beyond GitHub Actions repo secrets + `.kamal/secrets` (D-08).

**Known limitation:** GitHub's scheduled-workflow cron trigger (used for the nightly backup) is
best-effort timing and can lag under platform load. This private repo is not subject to GitHub's
60-day public-repo scheduled-workflow auto-disable, so the only real tradeoff is timing precision,
which is acceptable for a nightly, non-time-critical job.

### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
custom classes must fully style the input

### JS and CSS guidelines

- **Use Tailwind CSS classes and custom CSS rules** to create polished, responsive, and visually stunning interfaces.
- Tailwindcss v4 **no longer needs a tailwind.config.js** and uses a new import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- **Always use and maintain this import syntax** in the app.css file for projects generated with `phx.new`
- **Never** use `@apply` when writing raw css
- **Always** manually write your own tailwind-based components instead of using daisyUI for a unique, world-class design
- Out of the box **only the app.js and app.css bundles are supported**
  - You cannot reference an external vendor'd script `src` or link `href` in the layouts
  - You must import the vendor deps into app.js and app.css to use them
  - **Never write inline <script>custom js</script> tags within templates**

### UI/UX & design guidelines

- **Produce world-class UI designs** with a focus on usability, aesthetics, and modern design principles
- Implement **subtle micro-interactions** (e.g., button hover effects, and smooth transitions)
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look
- Focus on **delightful details** like hover effects, loading states, and smooth page transitions

## Catalog data: la base es la fuente de verdad

The database is the single source of truth for the catalog (D-09, phase 01.8.1). `/admin` is the
only editing surface for club-owned fields (name, units, `weight_band`, `is_expansion`, tags,
section membership, shelf location, Spanish description). The old CSV import task, its
`Catalog.Seed.CsvImport` module, and the full-row `Catalog.upsert_game!/1` upsert were removed in
phase 01.8.1 and must not be reintroduced — a replace-all upsert would silently revert every staff
edit the next time anyone ran it.

The one-time restore that originally populated production's `games` table (01.7 D-01/D-03) remains
a historical record only — see
`.planning/phases/01.7-production-catalog-data-security-hardening-inserted/01.7-SEED-RESTORE.md`
for the actual commands, including the lesson any future manual restore must not skip: verify the
dump's own `setval` line actually restored `games_id_seq` before trusting the restore, since a
skipped check doesn't fail at restore time — it fails later, as a primary-key collision on the next
write.

Five offline, developer-machine tasks remain and are safe to keep running against production over
the same manual SSH tunnel as before — none of them writes a club-owned field:

- `mix catalog.enrich_bgg_stats` — re-fetches BGG stats/artists for every game with a `bgg_id`
- `mix catalog.backfill_artists` — fills `artists` from each game's already-stored `bgg_payload`
- `mix catalog.backfill_gallery` — clears stale `gallery_urls` entries
- `mix catalog.backfill_og_cards` — regenerates the letterboxed OG share card
- `mix catalog.translate_descriptions` — translates a game's description to Spanish via Gemini,
  unconditionally skipping any game whose stored description no longer reads as English
  (D-06/D-07), so a staff-edited Spanish description can never be re-translated over

Running any of these against production still needs the same three load-bearing tunnel
constraints:

- **Open a foreground SSH local port-forward** (`ssh -f -N -L 127.0.0.1:15432:localhost:5432
  deploy@<host>`) and supply `DATABASE_URL` inline for that single command only — never export it
  into a shell profile, or it silently retargets every later `mix` invocation in that shell,
  including an unrelated local `mix test` or `mix ecto.migrate` run, to production.
- **BGG, R2, and Gemini credentials for a local run resolve from the developer's gitignored
  `config/dev.secret.exs`** through `PukllayClub.Catalog.Seed.Credentials` (env-var-first, then
  `Application` config). They never touch the production host directly and never route through
  Kamal for a developer-initiated run — that is a standing decision from plan 01-01, not a
  preference for this runbook.
- **Production is only reachable at all while the SSH forward above is open** — a deliberate,
  foreground, manual act, not something any CI job or scheduled task does on your behalf.

Production now enriches a staff-added game itself, through an Oban worker (D-02, phase 01.8.1
plans 06-08) — this deliberately reverses 01.7 D-04's "credentials never touch the production
host" decision, per 01.8.1 D-02. `BGG_API_TOKEN`, the R2 write keys, and `GEMINI_API_KEY` now also
live in GitHub repo secrets (for CI) and Kamal `env.secret` (for the running app), the same
pattern the app's other production secrets already follow.

The owner account is created once, over SSH, with:

```
bin/pukllay_club eval 'PukllayClub.Release.create_owner("owner@example.com")'
```

(D-32) — see `PukllayClub.Release.create_owner/1`, which delegates to `Accounts.create_owner/1`
inside `Ecto.Migrator.with_repo/2`.


<!-- phoenix-gen-auth-start -->
## Authentication

- **Always** handle authentication flow at the router level with proper redirects
- **Always** be mindful of where to place routes. `phx.gen.auth` creates multiple router plugs and `live_session` scopes:
  - A plug `:fetch_current_scope_for_user` that is included in the default browser pipeline
  - A plug `:require_authenticated_user` that redirects to the log in page when the user is not authenticated
  - A `live_session :current_user` scope - for routes that need the current user but don't require authentication, similar to `:fetch_current_scope_for_user`
  - A `live_session :require_authenticated_user` scope - for routes that require authentication, similar to the plug with the same name
  - In both cases, a `@current_scope` is assigned to the Plug connection and LiveView socket
  - A plug `redirect_if_user_is_authenticated` that redirects to a default path in case the user is authenticated - useful for a registration page that should only be shown to unauthenticated users
- **Always let the user know in which router scopes, `live_session`, and pipeline you are placing the route, AND SAY WHY**
- `phx.gen.auth` assigns the `current_scope` assign - it **does not assign a `current_user` assign**
- Always pass the assign `current_scope` to context modules as first argument. When performing queries, use `current_scope.user` to filter the query results
- To derive/access `current_user` in templates, **always use the `@current_scope.user`**, never use **`@current_user`** in templates or LiveViews
- **Never** duplicate `live_session` names. A `live_session :current_user` can only be defined __once__ in the router, so all routes for the `live_session :current_user`  must be grouped in a single block
- Anytime you hit `current_scope` errors or the logged in session isn't displaying the right content, **always double check the router and ensure you are using the correct plug and `live_session` as described below**

### Routes that require authentication

LiveViews that require login should **always be placed inside the __existing__ `live_session :require_authenticated_user` block**:

    scope "/", AppWeb do
      pipe_through [:browser, :require_authenticated_user]

      live_session :require_authenticated_user,
        on_mount: [{PukllayClubWeb.UserAuth, :require_authenticated}] do
        # phx.gen.auth generated routes
        live "/users/settings", UserLive.Settings, :edit
        live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
        # our own routes that require logged in user
        live "/", MyLiveThatRequiresAuth, :index
      end
    end

Controller routes must be placed in a scope that sets the `:require_authenticated_user` plug:

    scope "/", AppWeb do
      pipe_through [:browser, :require_authenticated_user]

      get "/", MyControllerThatRequiresAuth, :index
    end

### Routes that work with or without authentication

LiveViews that can work with or without authentication, **always use the __existing__ `:current_user` scope**, ie:

    scope "/", MyAppWeb do
      pipe_through [:browser]

      live_session :current_user,
        on_mount: [{PukllayClubWeb.UserAuth, :mount_current_scope}] do
        # our own routes that work with or without authentication
        live "/", PublicLive
      end
    end

Controllers automatically have the `current_scope` available if they use the `:browser` pipeline.

<!-- phoenix-gen-auth-end -->

<!-- usage-rules-start -->
<!-- usage_rules-start -->
## usage_rules usage
_A config-driven dev tool for Elixir projects to manage AGENTS.md files and agent skills from dependencies_

## Using Usage Rules

Many packages have usage rules, which you should *thoroughly* consult before taking any
action. These usage rules contain guidelines and rules *directly from the package authors*.
They are your best source of knowledge for making decisions.

## Modules & functions in the current app and dependencies

When looking for docs for modules & functions that are dependencies of the current project,
or for Elixir itself, use `mix usage_rules.docs`

```
# Search a whole module
mix usage_rules.docs Enum

# Search a specific function
mix usage_rules.docs Enum.zip

# Search a specific function & arity
mix usage_rules.docs Enum.zip/1
```


## Searching Documentation

You should also consult the documentation of any tools you are using, early and often. The best 
way to accomplish this is to use the `usage_rules.search_docs` mix task. Once you have
found what you are looking for, use the links in the search results to get more detail. For example:

```
# Search docs for all packages in the current application, including Elixir
mix usage_rules.search_docs Enum.zip

# Search docs for specific packages
mix usage_rules.search_docs Req.get -p req

# Search docs for multi-word queries
mix usage_rules.search_docs "making requests" -p req

# Search only in titles (useful for finding specific functions/modules)
mix usage_rules.search_docs "Enum.zip" --query-by title
```


<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
# Elixir Core Usage Rules

## Pattern Matching
- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else` or `case` in function bodies
- `%{}` matches ANY map, not just empty maps. Use `map_size(map) == 0` guard to check for truly empty maps

## Error Handling
- Use `{:ok, result}` and `{:error, reason}` tuples for operations that can fail
- Avoid raising exceptions for control flow
- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`

## Common Mistakes to Avoid
- Elixir has no `return` statement, nor early returns. The last expression in a block is always returned.
- Don't use `Enum` functions on large collections when `Stream` is more appropriate
- Avoid nested `case` statements - refactor to a single `case`, `with` or separate functions
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or `Enum` functions
- Prefer `Enum` functions like `Enum.reduce` over recursion
- When recursion is necessary, prefer to use pattern matching in function heads for base case detection
- Using the process dictionary is typically a sign of unidiomatic code
- Only use macros if explicitly requested
- There are many useful standard library functions, prefer to use them where possible

## Function Design
- Use guard clauses: `when is_binary(name) and byte_size(name) > 0`
- Prefer multiple function clauses over complex conditional logic
- Name functions descriptively: `calculate_total_price/2` not `calc/2`
- Predicate function names should not start with `is` and should end in a question mark.
- Names like `is_thing` should be reserved for guards

## Data Structures
- Use structs over maps when the shape is known: `defstruct [:name, :age]`
- Prefer keyword lists for options: `[timeout: 5000, retries: 3]`
- Use maps for dynamic key-value data
- Prefer to prepend to lists `[new | list]` not `list ++ [new]`

## Mix Tasks

- Use `mix help` to list available mix tasks
- Use `mix help task_name` to get docs for an individual task
- Read the docs and options fully before using tasks

## Testing
- Run tests in a specific file with `mix test test/my_test.exs` and a specific test with the line number `mix test path/to/test.exs:123`
- Limit the number of failed tests with `mix test --max-failures n`
- Use `@tag` to tag specific tests, and `mix test --only tag` to run only those tests
- Use `assert_raise` for testing expected exceptions: `assert_raise ArgumentError, fn -> invalid_function() end`
- Use `mix help test` to for full documentation on running tests

## Debugging

- Use `dbg/1` to print values while debugging. This will display the formatted value and other relevant information in the console.

<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
# OTP Usage Rules

## GenServer Best Practices
- Keep state simple and serializable
- Handle all expected messages explicitly
- Use `handle_continue/2` for post-init work
- Implement proper cleanup in `terminate/2` when necessary

## Process Communication
- Use `GenServer.call/3` for synchronous requests expecting replies
- Use `GenServer.cast/2` for fire-and-forget messages.
- When in doubt, use `call` over `cast`, to ensure back-pressure
- Set appropriate timeouts for `call/3` operations

## Fault Tolerance
- Set up processes such that they can handle crashing and being restarted by supervisors
- Use `:max_restarts` and `:max_seconds` to prevent restart loops

## Task and Async
- Use `Task.Supervisor` for better fault tolerance
- Handle task failures with `Task.yield/2` or `Task.shutdown/2`
- Set appropriate task timeouts
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure

<!-- usage_rules:otp-end -->
<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- phoenix:ecto-start -->
## phoenix:ecto usage
[phoenix:ecto usage rules](deps/phoenix/usage-rules/ecto.md)
<!-- phoenix:ecto-end -->
<!-- phoenix:elixir-start -->
## phoenix:elixir usage
[phoenix:elixir usage rules](deps/phoenix/usage-rules/elixir.md)
<!-- phoenix:elixir-end -->
<!-- phoenix:html-start -->
## phoenix:html usage
[phoenix:html usage rules](deps/phoenix/usage-rules/html.md)
<!-- phoenix:html-end -->
<!-- phoenix:liveview-start -->
## phoenix:liveview usage
[phoenix:liveview usage rules](deps/phoenix/usage-rules/liveview.md)
<!-- phoenix:liveview-end -->
<!-- phoenix:phoenix-start -->
## phoenix:phoenix usage
[phoenix:phoenix usage rules](deps/phoenix/usage-rules/phoenix.md)
<!-- phoenix:phoenix-end -->
<!-- usage-rules-end -->
