---
phase: quick-260821-umm
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/pukllay_club_web/components/layouts.ex
  - test/pukllay_club_web/components/layouts_test.exs
  - .claude/skills/ui-design-system/SKILL.md
autonomous: true
requirements: [SHELL-01]

estimate:
  tokens: 28000
  raw_tokens: 28000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "The footer's left cluster renders `Conectá jugando` as the second line under the PUKLLAY CLUB wordmark."
    - "The footer's left cluster no longer repeats the header's brand subtitle."
    - "The header's brand lockup still renders its original subtitle, unchanged."
    - "`Layouts.brand_logo/1` called with no attrs still renders the header subtitle (default preserved)."
    - "The footer still renders no broken isologo image reference."
  artifacts:
    - lib/pukllay_club_web/components/layouts.ex
    - test/pukllay_club_web/components/layouts_test.exs
    - .claude/skills/ui-design-system/SKILL.md
  key_links:
    - "`brand_logo/1` `tagline` attr default -> header call site (line ~175) renders unchanged output"
    - "`footer/1` `<.brand_logo tagline={...} />` -> the only site that overrides the second line"
    - "`about_live.ex` `<h1>` text <-> footer tagline string (verbatim, accent included)"
---

<objective>
Stop the shared footer from repeating the header's brand subtitle. The footer's left cluster
currently calls `Layouts.brand_logo/1` as-is, so the micro-caps line under the wordmark reads
identically in the header and the footer. Replace that second line — footer-only — with the About
page's hero tagline, taken verbatim from `about_live.ex`.

Purpose: removes redundant copy in the footer and reuses the club's real tagline as the brand's
closing line, without changing the header or the footer's other clusters.
Output: a parameterized `brand_logo/1` tagline, a footer call site that overrides it, updated and
expanded `layouts_test.exs` assertions, and a truthful design-system component-inventory row.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@lib/pukllay_club_web/components/layouts.ex
@lib/pukllay_club_web/live/about_live.ex
@test/pukllay_club_web/components/layouts_test.exs

Load the `ui-design-system` project skill before editing the template — it owns the component
inventory table this plan updates and the muted-text token convention the tagline slot uses.
</context>

<planning_notes>

## Correction to the task description (read before starting)

The task description quotes the About hero tagline as `Conecta jugando`. **That string does not
exist in the codebase.** The actual `<h1>` in `lib/pukllay_club_web/live/about_live.ex` (line 43)
reads:

> Conectá jugando

— with an acute accent on the final `a` (Argentine voseo imperative). The task's own binding
constraint is "verbatim match to `about_live.ex`", so the accented form is the correct string and
the unaccented quote in the description is a transcription slip. Every task below uses the accented
form. Do not "fix" it to `Conecta`.

## Decision: parameterize rather than duplicate (D-01)

The constraint reads "do NOT touch `Layouts.brand_logo/1` itself (the header still needs its
subtitle)". The parenthetical states the actual intent: **the header's rendered output must not
change.** Two implementations satisfy that intent:

| Option | Effect on header output | Cost |
|---|---|---|
| **A (chosen)** — add an optional `tagline` attr to `brand_logo/1` defaulting to the current literal; footer passes an override | byte-identical | one attr declaration + one interpolation |
| B — add a second private footer-local brand component duplicating the lockup markup | byte-identical | duplicates the wordmark markup *and* the compile-time isologo gate in two places; adds a second brand component to the design-system inventory |

Option A is chosen because this repo actively guards against exactly the kind of drift B creates
(the `check-theme-drift.sh` precedent, and the `ui-design-system` inventory that tracks one brand
component). Option A is also how `Layouts.app/1` and `CarouselRow.carousel_row/1` already express
optional variation in this codebase, so it matches house style.

Task 1 adds a regression test that mechanically enforces the constraint's intent (header subtitle
unchanged, and `brand_logo/1` with no attrs unchanged), so the guarantee is checked by CI rather
than by reviewer memory.

**If the developer literally meant "do not edit that function body," option B is the fallback** —
but flag it before switching, since it costs a duplicated isologo gate.

## Decision: keep the existing type treatment (D-02)

The tagline slot's classes stay exactly `font-sans text-xs uppercase tracking-widest text-neutral`.
Only the text content changes.

Rationale: quick task `260821-dah` re-measured this screen's font-combination inventory at 5 combos
against a documented cap of 3. Introducing a new, differently-styled tagline treatment for the
footer would add a sixth combo and reopen a todo that was just closed. Reusing the identical class
string is a zero-delta change to the type inventory.

Consequence to eyeball: `uppercase` is a CSS transform, so the DOM text stays `Conectá jugando`
(tests assert on the DOM, unaffected) while the rendered footer displays it in caps. The
`<human-check>` in `<verification>` exists to confirm that reads correctly.

## Explicit non-goals (from the task constraints)

- The isologo asset and its compile-time `@isologo?` gate — untouched. It stays intentionally
  absent and non-blocking.
- The header's brand lockup rendering — untouched.
- Every other part of the footer built in plan `01.1-01`: the FAQ/Contacto/Juntadas links, the
  WhatsApp/Facebook/Instagram/Email social set, the `© 2026` meta line, and `bgg_attribution/1` —
  all untouched.
- `about_live.ex` — read-only source of truth for the tagline string. Do not edit it.

</planning_notes>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Swap the footer's second brand line to the About hero tagline</name>
  <files>test/pukllay_club_web/components/layouts_test.exs, lib/pukllay_club_web/components/layouts.ex</files>

  <read_first>
    - `lib/pukllay_club_web/live/about_live.ex` line 43 — copy the `<h1>` string character-for-character, accent included. This is the single source of truth for the new text.
    - `lib/pukllay_club_web/components/layouts.ex` lines 21-41 (`brand_logo/1`) and 229-240 (`footer/1` left cluster).
    - `test/pukllay_club_web/components/layouts_test.exs` lines 26-49, 76-88, 126-146, 173-197 — for the established scoping idiom.
  </read_first>

  <behavior>
    Write these as failing tests first, in `test/pukllay_club_web/components/layouts_test.exs`.
    Render the full layout with `render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})`
    so header and footer are both present in one document, then scope each assertion to its own
    element — an unscoped `html =~` cannot distinguish the two clusters and would pass vacuously.

    Scope with the two selectors this file already uses: `#app-header` for the header (see the
    01-11 rework test at line 76) and `.pk-footer-left` for the footer's left cluster (the
    `LazyHTML.from_document/1 |> LazyHTML.query/2` idiom at line 179).

    - Test 1 (footer, positive): the text of `.pk-footer-left` contains the About hero tagline.
    - Test 2 (footer, negative): the text of `.pk-footer-left` does NOT contain the header's brand
      subtitle. This is the assertion that actually proves the redundancy is gone; without it
      Test 1 would still pass if both lines rendered.
    - Test 3 (header regression): the HTML of `#app-header` still contains the header's brand
      subtitle, and does NOT contain the About hero tagline.
    - Test 4 (default preserved): `render_component(&Layouts.brand_logo/1, %{})` — called with no
      attrs, exactly as the four existing `brand_logo/1` tests call it — still renders the header
      subtitle. This is the mechanical guard on D-01's "header output is byte-identical" claim.
    - Test 5 (isologo untouched): the HTML of `.pk-footer-left` contains no `isologo.svg`
      reference, mirroring the existing absent-asset test at line 34.

    Run the file and confirm Tests 1 and 2 fail (and 3, 4, 5 pass) before writing any
    implementation. Tests 3-5 passing up front is the point — they are regression guards, and a
    guard that fails before the change would mean the scoping selector is wrong.
  </behavior>

  <action>
    Then make them pass with the smallest possible change, per D-01:

    1. In `brand_logo/1`, declare one optional attr immediately above the function head:
       `attr :tagline, :string, default: "JUEGOS DE MESA MODERNOS"`. The default value must be the
       exact literal the template currently hardcodes, so every existing call site — the header at
       line ~175 and the two `render_component(&Layouts.brand_logo/1, %{})` test call sites — keeps
       rendering identically with no edit.
    2. In that same template, replace the hardcoded second-line text with a `{@tagline}`
       interpolation. Leave the wrapping `<span>` and its class string untouched, per D-02. Leave
       the `<a>`, the `min-h-11` hit target, the isologo `<img :if={@isologo?}>`, and the
       `PUKLLAY CLUB` wordmark span all exactly as they are.
    3. In `footer/1`'s left cluster, pass the override: `<.brand_logo tagline="..." />` using the
       accented string read from `about_live.ex`. This is the only call site that passes the attr.
    4. Extend the existing `defp footer/1` comment block to record why the footer's line differs
       from the header's, and update the `@doc` on `brand_logo/1` so it mentions that the tagline
       is overridable and names its default.

    Note for step 4: `brand_logo/1`'s `@doc` currently describes the lockup as
    "isologo + wordmark + tagline" — that phrasing stays accurate, just add the overridability
    sentence rather than rewriting the paragraph.
  </action>

  <verify>
    <automated>mix test test/pukllay_club_web/components/layouts_test.exs</automated>
  </verify>

  <done>
    The full `layouts_test.exs` file passes, including the five new assertions. The footer's left
    cluster renders the accented About hero tagline; the header renders its original subtitle; a
    no-attr `brand_logo/1` render is unchanged; no `isologo.svg` reference appears anywhere.
  </done>
</task>

<task type="auto">
  <name>Task 2: Update the design-system component inventory row</name>
  <files>.claude/skills/ui-design-system/SKILL.md</files>

  <read_first>
    `.claude/skills/ui-design-system/SKILL.md` lines 172-187 — the `| Module | Function | Required attrs |` inventory table. Note how row 180 (`Layouts` / `app/1`) and row 184 (`CarouselRow` / `carousel_row/1`) document optional attrs inline after the required ones, e.g. "Optional: `fullbleed` (bool, default `false`)".
  </read_first>

  <action>
    Row 181 (`| Layouts | brand_logo/1 | — |`) is now stale — the component gained an optional attr
    in Task 1. Replace the `—` cell with an entry following the exact house format already used by
    the `app/1` and `carousel_row/1` rows: no required attrs, plus the optional `tagline` string
    attr, its default, and a short note that the footer is the one call site that overrides it.

    Change only that one table cell. Do not touch the typography table (line 104), the rest of the
    inventory, or any other section of the skill.
  </action>

  <verify>
    <automated>mix test test/pukllay_club_web/components/layouts_test.exs</automated>
    <human-check>Row 181 of the inventory table names the `tagline` attr and its default, and reads in the same shape as rows 180 and 184.</human-check>
  </verify>

  <done>
    The `Layouts` / `brand_logo/1` inventory row documents the optional `tagline` attr and its
    default value; the rest of the skill file is byte-identical.
  </done>
</task>

<task type="auto">
  <name>Task 3: Run the full quality gate</name>
  <files>lib/pukllay_club_web/components/layouts.ex, test/pukllay_club_web/components/layouts_test.exs</files>

  <action>
    Run the project's 7-step `mix quality` alias (`hex.audit`, `deps.audit`,
    `deps.unlock --check-unused`, `format --check-formatted`, `credo --strict`, `sobelow`, `test`)
    and drive it to green.

    Two known friction points, both from the project's own tooling notes:

    - `format --check-formatted` runs the `Phoenix.LiveView.HTMLFormatter` and Styler plugins. The
      HEEx formatter is likely to re-wrap the newly-interpolated tagline span and the new
      `<.brand_logo tagline={...} />` call. If the check fails, run `mix format` on the two touched
      files, then **review `git diff` hunk by hunk before accepting** — Styler is documented as able
      to change program behaviour (its `case`->`if` rewrites), so its output is never accepted on
      trust in this repo.
    - `credo --strict` may flag the extended comment blocks. Fix by editing the code, not by adding
      a `.credo.exs` exclusion — this change is far too small to justify loosening a lint config.

    If any failure traces to a pre-existing issue unrelated to this change, stop and report it
    rather than expanding scope to fix it.
  </action>

  <verify>
    <automated>mix quality</automated>
  </verify>

  <done>
    `mix quality` exits 0 with no new warnings, and any formatter-applied rewrite to the two touched
    files has been reviewed in `git diff` and is limited to whitespace/wrapping.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| server -> rendered HTML | The only boundary this change touches. The new tagline is a compile-time string literal in a HEEx template; no user-controlled, database-sourced, or request-scoped data enters the changed markup. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-umm-01 | Tampering (XSS) | `Layouts.brand_logo/1` `{@tagline}` interpolation | low | mitigate | The attr is declared `:string` and every call site passes a compile-time literal (default, or the footer's override). HEEx auto-escapes `{...}` interpolations by default. Do not introduce `raw/1` or `Phoenix.HTML.raw` around the tagline, and do not widen the attr to `:any` — either would turn an inert literal slot into a live injection point if a future caller passes user data. `mix sobelow` (step 6 of `mix quality`, Task 3) covers XSS checks for this template. |
| T-umm-02 | Information Disclosure | footer copy | low | accept | The tagline is public marketing copy already rendered publicly on `/quienes-somos`. Duplicating it in the footer discloses nothing new. |

No package-manager installs occur in this plan (no `mix.exs` / `mix.lock` changes), so no
supply-chain legitimacy gate applies. `mix hex.audit` and `mix deps.audit` still run as steps 1-2
of `mix quality` in Task 3.
</threat_model>

<verification>
1. `mix test test/pukllay_club_web/components/layouts_test.exs` — all assertions pass, including
   the five added in Task 1.
2. `mix quality` — exits 0.
3. `git diff --stat` — exactly three files changed. If `about_live.ex`, the isologo asset, or any
   other footer cluster appears in the diff, the scope constraint was violated; revert and rescope.
4. `<human-check>` (visual, `human_verify_mode` is `end-of-phase` so this is non-blocking): load any
   page, scroll to the footer, and confirm the left cluster reads `PUKLLAY CLUB` over the tagline in
   micro-caps, that it no longer echoes the header, and that the accented capital renders correctly
   in the caps treatment (see D-02). If the caps treatment reads badly, that is a follow-up styling
   decision — not a fix inside this plan, since changing it reopens the type-inventory cap.
</verification>

<success_criteria>
- The footer's left cluster second line matches `about_live.ex`'s `<h1>` character-for-character,
  accent included.
- The footer's left cluster no longer contains the header's brand subtitle, proven by a
  footer-scoped negative assertion.
- The header's brand lockup and a no-attr `brand_logo/1` render are unchanged, proven by two
  regression assertions.
- The isologo gate, the footer links, the social set, the meta line, and `bgg_attribution/1` are
  untouched.
- The design-system inventory row for `brand_logo/1` documents the new optional attr.
- `mix test` and `mix quality` both pass.
</success_criteria>

<output>
Create `.planning/quick/260821-umm-footer-left-cluster-in-layouts-ex-footer/260821-umm-SUMMARY.md` when done.

Record in the summary: the `Conecta` -> `Conectá` correction and that the accented form is
authoritative; D-01 (parameterize vs. duplicate) and D-02 (type treatment unchanged) with their
rationale; and the outcome of the visual `<human-check>` on the uppercase rendering.
</output>
</content>
</invoke>
