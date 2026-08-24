---
phase: quick-260818-fro
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - mix.exs
  - mix.lock
  - lib/pukllay_club_web/endpoint.ex
autonomous: true
requirements: [QUICK-260818-fro]

estimate:
  tokens: 24000
  raw_tokens: 12000
  tasks: 2
  confidence: low

must_haves:
  truths:
    - "In dev, the running Phoenix endpoint mounts Tidewave's MCP endpoint at /tidewave/mcp and answers on localhost."
    - "In prod, the dependency is never fetched or compiled, and the endpoint compiles cleanly without it."
    - "The project's own gate (mix quality) still passes after the change."
  artifacts:
    - "mix.exs — deps/0 contains the dev-only tidewave entry"
    - "mix.lock — pinned lock entry for the new dependency"
    - "lib/pukllay_club_web/endpoint.ex — dev-guarded plug block immediately above the code_reloading? block"
  key_links:
    - "The compile-time Mix.env() guard in endpoint.ex is what keeps a dev-only dependency from being referenced during a prod compile — a runtime guard instead of a compile-time one breaks the prod build."
    - "Plug ordering: the new plug sits above Phoenix.CodeReloader so MCP requests are handled before the code reloader and Phoenix.Ecto.CheckRepoStatus run."
---

<objective>
Integrate Tidewave into the Phoenix app as a development-only MCP endpoint, with zero
production surface area.

Purpose: gives local AI tooling a first-class MCP connection into the running dev app
(project/database/log introspection) without adding any runtime dependency, plug, or
network listener to the deployed release.
Output: a dev-only `~> 0.8` dependency, a compile-time dev-guarded plug in the endpoint,
an updated `mix.lock`, and proof that a `MIX_ENV=prod` compile succeeds with the
dependency completely absent.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md

@mix.exs
@lib/pukllay_club_web/endpoint.ex
</context>

<scope_boundaries>
Do NOT modify `config/dev.exs`, `config/prod.exs`, `config/runtime.exs`, `config/test.exs`,
or any other config file. The LiveView debug-annotation settings the upstream docs mention
are already present in `config/dev.exs`.

Do NOT pass any options to the plug. No `:allow_remote_access`, no `:allowed_origins`,
no `:autoformat` — the plug's restrictive localhost-only defaults are the intended security
posture (see threat model T-QT-01).

Note: `config/dev.exs` and `config/runtime.exs` already carry unrelated uncommitted
working-tree changes from prior work. Leave them alone, do not stage them, and scope the
commit to `mix.exs`, `mix.lock`, and `lib/pukllay_club_web/endpoint.ex` only.
</scope_boundaries>

<tasks>

<task type="tracer">
  <name>Task 1: Wire the MCP plug end-to-end — dependency, dev-guarded plug, dev compile</name>
  <files>mix.exs, mix.lock, lib/pukllay_club_web/endpoint.ex</files>
  <precondition>Mix and Hex are installed and hex.pm is reachable — `mix hex.info` exits 0. If it fails (offline, or Hex not installed), halt: `mix deps.get` cannot resolve the new dependency.</precondition>
  <action>
Two edits, then one dependency fetch, then one dev compile.

Edit 1 — `mix.exs`, inside `deps/0`: add the entry `{:tidewave, "~> 0.8", only: :dev},`
immediately after the existing `{:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},`
line, keeping dev-scoped tooling grouped. Use exactly `only: :dev` with no `runtime:` option —
this is a plug that must actually run in dev, and `only: :dev` alone already excludes it from
the prod release and from the `:test` env that `mix quality` runs under.

Edit 2 — `lib/pukllay_club_web/endpoint.ex`: insert a block immediately ABOVE the existing
`if code_reloading? do` block (currently line 32, directly under the two-line
"Code reloading can be explicitly enabled..." comment). The block is a compile-time guard
`if Mix.env() == :dev do` whose single body line is the bare plug declaration
`plug Tidewave`, closed by `end`, followed by a blank line before that comment. Placement
above the code reloader is required by the upstream README so MCP requests are handled
before `Phoenix.CodeReloader` and `Phoenix.Ecto.CheckRepoStatus` run. The guard must be
`Mix.env()` (compile-time, so the whole block is erased from a non-dev compile), never a
runtime check against application env — a runtime check would leave an unresolvable module
reference in the prod build.

Then run `mix deps.get` to resolve and lock the dependency, and
`mix compile --warnings-as-errors` (dev env) to confirm a clean build.

Finally run `mix format mix.exs lib/pukllay_club_web/endpoint.ex` so the Styler-augmented
`format --check-formatted` gate in `mix quality` stays green. Review `git diff` for any
Styler rewrite beyond the two intended edits and revert anything unrelated.

Provenance for the reviewer: `~> 0.8` resolves to 0.8.4, the latest release published on Hex
by the official `tidewave-ai/tidewave_phoenix` project — verified against the Hex package API
and the upstream README before planning. This is not an unverified package (T-QT-SC).
  </action>
  <verify>
    <automated>mix deps.get</automated>
    <automated>grep -q '{:tidewave, "~> 0.8", only: :dev}' mix.exs</automated>
    <automated>grep -q '"tidewave"' mix.lock</automated>
    <automated>grep -qE '^ +plug Tidewave$' lib/pukllay_club_web/endpoint.ex</automated>
    <automated>test "$(grep -n 'if Mix.env() == :dev do' lib/pukllay_club_web/endpoint.ex | cut -d: -f1)" -lt "$(grep -n 'if code_reloading? do' lib/pukllay_club_web/endpoint.ex | cut -d: -f1)"</automated>
    <automated>mix compile --warnings-as-errors</automated>
    <automated>git diff --name-only -- config | wc -l | grep -qx 0</automated>
    <human-check>Run `mix phx.server`, then in another shell run `curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:4000/tidewave/mcp` and confirm the status is NOT 404 (any other status proves the plug is mounted; 404 means it never ran). Confirm the catalog pages still load at http://localhost:4000.</human-check>
  </verify>
  <done>`mix deps.get` writes a lock entry; `mix compile --warnings-as-errors` exits 0 in dev; the bare plug declaration appears with no options inside a `Mix.env() == :dev` guard positioned above the `code_reloading?` block; `git diff` shows no newly-modified file under `config/`.</done>
</task>

<task type="auto">
  <name>Task 2: Prove production exclusion and re-green the project quality gate</name>
  <files>mix.exs, lib/pukllay_club_web/endpoint.ex</files>
  <precondition>Task 1 is complete — `mix.lock` contains the new entry and the dev compile passed.</precondition>
  <action>
Prove the two properties that make this change safe, and fix only what they surface. No new
source edits are expected; the file list above exists only so a formatting fix surfaced by
the gate can be applied in place.

First, production exclusion. Run a full `MIX_ENV=prod` compile with placeholder values for
the three env vars `config/runtime.exs` raises on (`DATABASE_URL`, `SECRET_KEY_BASE`,
`R2_PUBLIC_BASE_URL`) — placeholders are safe because nothing connects at compile time. A
successful prod compile is the real proof that the compile-time guard erased the plug: were
the guard wrong, prod compilation would fail on an undefined module. Then assert the
dependency was never built for prod at all by checking that no matching `_build/prod/lib`
directory exists.

Second, the project gate. Run `mix quality` (the 7-step alias: hex.audit, deps.audit,
deps.unlock --check-unused, format --check-formatted, credo --strict, sobelow --config,
test --warnings-as-errors). Expect it to pass unchanged — the dependency is absent in `:test`
env and the guarded block compiles away there too. If `deps.audit` or `hex.audit` flags the
new dependency, STOP and report rather than adding a suppression. If `format --check-formatted`
fails, run `mix format` on the two touched files and review the diff before re-running.

Do not add `.sobelow-conf` ignores, Credo exemptions, or any other suppression in this task.
  </action>
  <verify>
    <automated>env MIX_ENV=prod DATABASE_URL="ecto://placeholder:placeholder@localhost/placeholder" SECRET_KEY_BASE="0000000000000000000000000000000000000000000000000000000000000000" R2_PUBLIC_BASE_URL="https://images.example.invalid" mix compile --warnings-as-errors</automated>
    <automated>test ! -d _build/prod/lib/tidewave</automated>
    <automated>mix quality</automated>
  </verify>
  <done>The prod compile exits 0 with the dependency absent from `_build/prod/lib`, and `mix quality` exits 0 with no suppressions added.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| localhost HTTP client → dev endpoint `/tidewave/mcp` | An MCP client (AI agent) gets project, database, and log introspection plus code evaluation against the running dev app. Highest-privilege surface this change introduces. |
| non-local network → dev endpoint | Any other host on the developer's LAN could reach port 4000 if the dev server binds beyond loopback. |
| hex.pm → build (`mix deps.get`) | New third-party code enters the dependency tree and the lockfile. |
| build pipeline → production release | The boundary this change must NOT cross: the dependency and plug must be absent from every non-dev compile. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-QT-01 | Elevation of Privilege | `plug Tidewave` reachable from a non-local origin | critical | mitigate | Pass zero options so the plug's default localhost-only client-IP and origin restrictions stay in force; `<scope_boundaries>` explicitly forbids `:allow_remote_access` and `:allowed_origins`. |
| T-QT-02 | Elevation of Privilege | The plug shipping into the production release | critical | mitigate | Two independent controls: `only: :dev` in `deps/0` (dependency never fetched or built outside dev) and a compile-time `Mix.env() == :dev` guard (declaration erased from the compiled endpoint). Task 2 proves both via a real `MIX_ENV=prod` compile plus a `_build/prod/lib` absence assertion. |
| T-QT-03 | Information Disclosure | MCP database/log tools reading dev data | medium | accept | Scope is the developer's own local dev database and logs, already fully readable by that developer; the localhost-only default (T-QT-01) keeps the exposure to that same machine. |
| T-QT-04 | Tampering | Plug ordering relative to `Phoenix.CodeReloader` | low | mitigate | Position asserted mechanically in Task 1 by comparing the guard's line number against the `code_reloading?` block's line number, not by eyeball. |
| T-QT-SC | Tampering | Supply chain — new Hex dependency | high | mitigate | `~> 0.8` resolves to 0.8.4, verified pre-planning against the Hex package API and the official `tidewave-ai/tidewave_phoenix` README (not an `[ASSUMED]` package). `mix.lock` pins the resolved version and checksum; `mix hex.audit` and `mix deps.audit` run against it in Task 2, and any finding halts the task instead of being suppressed. |
| T-QT-05 | Denial of Service | Extra plug in the dev request path | low | accept | Dev-only, single developer, no availability requirement. |
</threat_model>

<verification>
1. `mix deps.get` resolves and locks the dependency; `mix.lock` gains a pinned entry.
2. `mix compile --warnings-as-errors` exits 0 in the dev environment.
3. The bare plug declaration appears exactly once, with no options, inside a
   `Mix.env() == :dev` guard positioned strictly above the `code_reloading?` block.
4. A `MIX_ENV=prod` compile exits 0 and `_build/prod/lib` has no directory for the dependency.
5. `mix quality` exits 0 with no new suppressions in `.sobelow-conf` or Credo config.
6. `git diff --name-only -- config` is empty (no config file touched by this task).
7. Human check: `/tidewave/mcp` answers with a non-404 status on localhost with the dev
   server running.
</verification>

<success_criteria>
- `mix.exs` declares the dependency as `only: :dev` with no `runtime:` option.
- `lib/pukllay_club_web/endpoint.ex` carries a compile-time dev guard wrapping an
  option-free plug declaration, above the code-reloading block.
- Dev compile, prod compile, and `mix quality` all exit 0.
- No config file and no unrelated file is modified or staged.
- Commit scoped to `mix.exs`, `mix.lock`, `lib/pukllay_club_web/endpoint.ex`.
</success_criteria>

<output>
Create `.planning/quick/260818-fro-integrate-tidewave-dev-only-into-phoenix/260818-fro-SUMMARY.md` when done
</output>
