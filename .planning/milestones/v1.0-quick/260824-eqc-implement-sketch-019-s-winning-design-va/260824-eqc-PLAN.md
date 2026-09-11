---
phase: quick-260824-eqc
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/pukllay_club/catalog.ex
  - test/pukllay_club/catalog_test.exs
  - lib/pukllay_club_web/components/filter_modal.ex
  - test/pukllay_club_web/components/filter_modal_test.exs
  - lib/pukllay_club_web/live/catalog_live/index.ex
  - test/pukllay_club_web/live/catalog_live_test.exs
  - assets/css/app.css
autonomous: true
requirements: [SHELL-04]

estimate:
  tokens: 58000
  raw_tokens: 58000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "The filter modal's title reads 'Encuentra tu juego' with the subtitle 'Combina filtros para llegar a los juegos que te interesan.' — the bare technical 'Filtros' heading is gone from the modal and from its dialog aria-label."
    - "Both search boxes (the modal's and the header nav's) carry the same placeholder, '¿Qué juego buscas?' — one string, two surfaces, no drift."
    - "Duración máxima chips read '30 min' / '60 min' / '90 min' / '120 min'. The section heading carries the 'up to' meaning; the word 'Hasta' appears on no chip. The underlying predicate (coalesce(playing_time, max_playtime) <= n via toggle-scalar/max_playtime) is byte-for-byte unchanged."
    - "The Jugadores cluster offers 2 / 3 / 4 / 5 / 6+ . Clicking '6+' narrows the live catalog to games that seat at least 6 (max_players >= 6, no upper bound — including a game whose min_players is 7 or 8, which the exact-fit predicate would have excluded), and the match count is nonzero against the real catalog."
    - "Selecting any Jugadores chip still deselects the previously selected one — the cluster stays single-select, because all five chips still drive the one :players scalar."
    - "Jugadores, Duración máxima, Nivel and the Mecánica/Temática disclosure each sit in their own rounded, surface-tinted card (rounded-box bg-base-200 p-4) rather than a bare heading over a chip row."
    - "'Limpiar filtros' renders with no border and no fill at rest (daisyUI btn-ghost), still disabled whenever no filter or query is active, still in the footer beside 'Ver N juegos'."
    - "The editorial-hashtag filter group renders nowhere inside the modal — no heading, no pills, no phx-value-facet=\"tags\" control. The cut is recorded in the moduledoc as deliberate and expected to return, so nobody re-adds it as a bug fix."
    - "While the modal is open, the catalog surface behind it is visibly blurred and dimmed, and it returns to normal the moment the modal closes — driven by the existing @filters_open assign via a class toggle, with no new hook and no new server state."
    - "Every event handler, phx-value-choice binding, and the live-apply architecture from quick-260824-b71 and the phx-value-collision fix are untouched: toggle-facet, toggle-scalar, search, close-filters, clear-filters, open-filters, sort all keep their existing names, payload keys, and semantics."
    - "The four presentation behaviors that ExUnit provably cannot catch (6+ narrows results, the editorial group is gone, the background blurs and reverts, Limpiar filtros has no border/fill at rest) are each confirmed in a real browser against a running server, with the observed numbers recorded in the SUMMARY."
    - "`mix quality` passes end to end (hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted, credo --strict, sobelow --config, test --warnings-as-errors)."
  artifacts:
    - "lib/pukllay_club/catalog.ex — maybe_filter_players/2 gains an open-ended clause for the top bucket, guarded by a named module attribute, with the exact-fit clause intact for 2..5."
    - "test/pukllay_club/catalog_test.exs — a test proving players: 6 includes a min_players: 7 game and excludes a max_players: 5 game, alongside the untouched exact-fit test."
    - "lib/pukllay_club_web/components/filter_modal.ex — new copy, per-section cards, ghost clear button, 6+ chip, editorial group deleted, moduledoc updated."
    - "lib/pukllay_club_web/live/catalog_live/index.ex — nav placeholder parity plus a dimmable wrapper around the catalog surface (modal and preview host deliberately outside it)."
    - "assets/css/app.css — .pk-dimmable / .is-dimmed inside the PK CATALOG SURFACES block, plus .pk-dimmable added to the existing prefers-reduced-motion selector list."
  key_links:
    - "The 6+ chip's phx-value-choice=\"6\" -> toggle-scalar -> scalar_assign_key(\"players\") -> :players assign -> filter_opts/1 -> Catalog.filter_games(players: 6) -> the open-ended clause. If the chip stops emitting choice=\"6\" on the players scalar, the bucket silently reverts to exact fit with no error anywhere."
    - "@filters_open -> the is-dimmed class on the catalog wrapper. The modal and GamePreview.preview_host must stay OUTSIDE that wrapper: a CSS `filter` on an ancestor creates a containing block for position: fixed descendants, so nesting them would both blur the modal and reposition it."
    - "The placeholder string is written in two files (filter_modal.ex and index.ex's :nav_search slot). Both must change together or the two search surfaces drift."
---

<objective>
Implement sketch 019's winning design (variant D) in the real filter modal: new title/subtitle
copy, a shared conversational search placeholder, simplified duration chip labels, a real "6+"
Jugadores bucket, a text-only Limpiar filtros, per-section surface cards, a blurred/dimmed
catalog behind the open modal, and the deliberate removal of the editorial-hashtag filter group.

Purpose: quick-260824-b71 got the filter *mechanics* right (chip clusters, toggle-scalar,
live-apply, the phx-value-choice payload fix) but the visual execution landed flat and technical.
Sketch 019 decided the finish; this task ships it. Exactly one item is more than presentation —
the "6+" bucket needs a genuinely different SQL predicate shape than the exact-fit chips.

Output: a filter modal that matches `.planning/sketches/019-filter-modal-finish/index.html`,
translated to this project's daisyUI/Tailwind tokens (never a literal copy of the sketch's raw
CSS custom-property names), with the 6+ bucket verified nonzero against the real catalog and all
four browser-only behaviors confirmed live.

Out of scope, deliberately: no changes to event handler wiring, payload keys, predicate logic for
players 2..5 / max_playtime / weight_bands / mechanics / themes / tags, or the live-apply
architecture. No new hook. No new assign, URL param, or facet. No sketch-findings skill reference
file for the filter surface (that is a separate documentation pass, not forgotten).
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md

@.planning/sketches/019-filter-modal-finish/README.md
@.planning/sketches/019-filter-modal-finish/index.html
@lib/pukllay_club_web/components/filter_modal.ex
@lib/pukllay_club_web/live/catalog_live/index.ex
@lib/pukllay_club/catalog.ex

Load these project skills before touching any .heex/LiveView markup: `ui-design-system`,
`ux-patterns`, `ux-responsive`.

Design-system facts that constrain every translation below (from `ui-design-system` SKILL.md):
- Banned: arbitrary Tailwind values (`blur-[3px]`, `saturate-[0.7]`), raw hex/rgb colors, inline
  `style=` attributes, and any color class outside the theme tokens.
- `rounded-box` is the only radius token. `p-4` is card body padding. `text-neutral text-sm` is
  the muted tier. `min-h-11` is the single touch-target floor.
- The catalogue screen is already at its 3-tier type cap (5 measured font combos). Do not
  introduce a 4th tier.
- Custom CSS goes in exactly one place: the `PK CATALOG SURFACES START/END` block in
  `assets/css/app.css`, resolving color through daisyUI theme CSS variables, and the single
  trailing `@media (max-width: 480px)` block must stay last in the file.
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: The "6+" bucket — open-ended players predicate, end to end</name>
  <files>lib/pukllay_club/catalog.ex, test/pukllay_club/catalog_test.exs</files>
  <precondition>The dev database is reachable and holds the real imported catalog: `MIX_ENV=dev mix run -e 'IO.inspect(PukllayClub.Catalog.count_games([]), label: "catalog size")'` prints a number in the hundreds. If it prints 0, the catalog import has not been run in dev — stop and report, because the nonzero-bucket sanity check below cannot be satisfied against an empty DB.</precondition>
  <behavior>
    Against `Catalog.filter_games/1` and `Catalog.count_games/1`:
    - Test 1 (existing, must keep passing unchanged): `players: 4` returns only games whose
      range includes 4 — a 2-5 game matches, a 5-6 game does not, a 1-3 game does not.
    - Test 2 (new): `players: 6` is the open-ended top bucket. A game with
      `min_players: 2, max_players: 6` matches. A game with `min_players: 7, max_players: 8`
      ALSO matches (this is the whole point — the exact-fit predicate would have excluded it).
      A game with `min_players: 2, max_players: 5` does not match.
    - Test 3 (new): `players: nil` still applies no players predicate at all.
  </behavior>
  <action>
This is the only non-presentation change in the plan, and it is the thin end-to-end slice the
rest of the work expands from: prove the new query shape and the real-catalog match count first,
before any markup moves.

Write the tests in `test/pukllay_club/catalog_test.exs` first (they will fail red — the current
predicate excludes the `min_players: 7` fixture), next to the existing
`"min_players: 4 returns only games whose player range includes 4"` test. Use the same
`game_fixture(%{name: ..., min_players: ..., max_players: ...})` shape that test already uses,
and sort the resulting name list before asserting so the assertion does not depend on sort order.

Then change `lib/pukllay_club/catalog.ex`:

1. Add a module attribute next to the existing `@weight_band_order` / `@default_limit`
   attributes naming the open-ended threshold — `@players_open_bucket 6` — with a comment
   explaining the semantics: the Jugadores chip cluster's top chip is labelled "6+" and means
   "seats at least this many players", not "seats exactly this many". Below that threshold the
   request is a literal seat-count fit; at or above it there is no upper bound, so a party game
   requiring 7-8 players is a valid answer to "we are six or more" while an exact-fit predicate
   would silently hide it.
2. Insert a new `maybe_filter_players/2` clause BETWEEN the `nil` clause and the existing
   exact-fit clause, guarded `when n >= @players_open_bucket`, whose body is
   `from g in query, where: g.max_players >= ^n`. Leave the existing exact-fit clause
   (`g.min_players <= ^n and g.max_players >= ^n`) as the final catch-all so 2/3/4/5 behave
   exactly as they do today. Clause order matters: the guard clause must come first or it is
   unreachable.
3. Update the `filter_games/1` `@doc` where it lists `:players` so the open-ended semantics of
   the top bucket are documented at the public entry point, not only at the private clause.

Deliberately NOT done here, and say so in a comment so a later reader does not "finish" it: no
new assign, no new URL param, no new scalar name, no second facet. The chip keeps sending
`phx-value-scalar="players" phx-value-choice="6"` through the untouched `toggle-scalar` handler,
which is what preserves the cluster's single-select behavior for free — a second scalar would let
"4" and "6+" be selected simultaneously, which a chip row visually promises is impossible.

Finally, run the real-catalog sanity check (this is a throwaway command, not code to commit):

    MIX_ENV=dev mix run -e 'import Ecto.Query; alias PukllayClub.{Catalog, Repo}; alias PukllayClub.Catalog.Game; IO.inspect(%{total: Catalog.count_games([]), exact_five: Catalog.count_games(players: 5), open_six_plus: Catalog.count_games(players: 6), only_seven_plus: Repo.aggregate(from(g in Game, where: g.min_players > 6), :count)}, label: "players buckets")'

`open_six_plus` MUST be greater than zero — if it is zero, the chip would ship as a dead end and
this task stops for a decision instead. Record all four numbers verbatim in the SUMMARY.
`only_seven_plus` is the delta this predicate change actually buys: if it is 0, note in the
SUMMARY that "6+" and the old exact-6 chip currently return the identical set for this catalog
and the difference will only appear as bigger-group games are added — that is a correct outcome,
not a failed change.
  </action>
  <verify>
    <automated>mix test test/pukllay_club/catalog_test.exs --warnings-as-errors</automated>
    <automated>MIX_ENV=dev mix run -e 'IO.inspect(PukllayClub.Catalog.count_games(players: 6), label: "open_six_plus")' | grep -qE 'open_six_plus: [1-9]'</automated>
  </verify>
  <done>Both new tests and the pre-existing exact-fit test pass. `count_games(players: 6)` against the real dev catalog is nonzero, and all four sanity-check numbers are captured for the SUMMARY.</done>
</task>

<task type="auto">
  <name>Task 2: FilterModal presentation pass — copy, cards, chips, ghost clear, editorial cut</name>
  <files>lib/pukllay_club_web/components/filter_modal.ex, test/pukllay_club_web/components/filter_modal_test.exs</files>
  <action>
Rewrite the presentation layer of `filter_modal/1` only. Do not touch the two colocated hooks
(`.FilterModal`, `.FilterChecklist`), any `phx-click` / `phx-change` / `phx-value-*` attribute,
any `data-fc-*` attribute, `checklist/1`'s internals, `cta_label/1`, or the component's attr
list. Every change below is markup, class lists, or literal Spanish strings.

1. Header. Replace the single `<h2 class="font-display text-xl">` with a two-line block: the same
   `font-display text-xl` heading reading `Encuentra tu juego`, and directly under it a
   `<p class="text-neutral text-sm">` reading
   `Combina filtros para llegar a los juegos que te interesan.` Wrap the pair in a
   `<div class="space-y-1">` and switch the header row from `items-center` to `items-start` with
   `gap-3` so the close button stays top-aligned against the now two-line title. The close button
   itself, its `data-modal-close` marker, its `phx-click`, its `aria-label` and its
   `min-h-11 min-w-11` floor are unchanged — the `.FilterModal` hook queries
   `[data-modal-close]` for both Escape-to-close and initial focus.
   Also update the `.modal-box`'s `aria-label` from the bare technical noun to
   `Encuentra tu juego` so the accessible name matches the visible title.

2. Search placeholder. Change the modal search input's placeholder to `¿Qué juego buscas?`.
   Leave `phx-change="search"`, `phx-debounce="300"`, `maxlength="100"` and the `name="q"`
   binding exactly as they are. (Task 3 makes the identical change on the header nav search box —
   the two must land together.)

3. Jugadores. Split the current single comprehension into the four exact-fit chips plus one
   explicit open-ended chip:
   - `:for={n <- [2, 3, 4, 5]}` — unchanged shape, `scalar="players"`, `value={to_string(n)}`,
     `label={to_string(n)}`, `selected={@players == n}`.
   - one standalone `<.scalar_chip scalar="players" value="6" label="6+" selected={@players == 6} />`.
   Both families keep `scalar="players"`, which is what keeps the cluster single-select through
   the untouched `toggle-scalar` handler. Add a short comment above the standalone chip pointing
   at Task 1's open-ended clause in `Catalog` so the label/predicate pairing is discoverable from
   the markup.

4. Duración máxima. Change the chip label expression from the prefixed form to `{"#{n} min"}`.
   The section heading already carries the cumulative meaning. `scalar="max_playtime"`,
   the `[30, 60, 90, 120]` list and `selected={@max_playtime == n}` are unchanged.

5. Section cards (sketch 019's `.fm-group`). Give each of the three `<section>` elements
   (Jugadores, Duración máxima, Nivel) the class `rounded-box bg-base-200 p-4`, and give the
   `<details>` disclosure the same `rounded-box bg-base-200 p-4` in place of its current
   `border-t border-base-300 pt-3`. This is the token translation of the sketch's
   `background: var(--color-surface); border-radius: var(--radius-md); padding: var(--space-3)`
   — `rounded-box` is this app's only radius token and `bg-base-200` is its surface tint against
   the modal box's base-100. The body wrapper keeps `space-y-3 overflow-y-auto p-4`, which now
   spaces the cards rather than bare sections. The search form stays outside any card, as the
   first child of the body, matching the sketch's header-adjacent search.
   Keep each card's `<h3>` on `text-sm font-semibold` — do NOT copy the sketch's 11px uppercase
   letter-spaced group label, which would add a 4th type tier to a screen the design system has
   measured and capped at 3. Record that deviation in the moduledoc.

6. Chip selected state. In `chip_class/1` only (the single source of truth both chip families
   share — do not add a second class list anywhere), append `shadow-sm` to the selected list so
   it becomes `["badge", "min-h-11", "px-3", "badge-primary", "shadow-sm"]`. This is the
   non-arbitrary translation of the sketch's soft colored box-shadow on the active chip; a
   literal colored shadow would need an arbitrary value, which is banned. The resting list stays
   exactly `["badge", "min-h-11", "px-3", "badge-neutral", "badge-outline"]` — it already renders
   the sketch's 1px soft-bordered pill, and dropping `badge-neutral` would push the border to the
   heavier base-content tone rather than the muted one the sketch specifies.

7. Limpiar filtros. Change the footer secondary action's class list from the outlined variant to
   `["btn", "btn-ghost", "min-h-11"]` — daisyUI's ghost button is transparent with no border at
   rest, which is exactly the "plain text button" the sketch asks for, without hand-rolling
   markup. Keep `phx-click="clear-filters"`, keep `disabled={not @filters_active}`, keep it in
   the same footer position beside the CTA, and keep the existing comment above the footer
   explaining why both actions pass an explicit class list instead of `variant`.

8. Editorial-hashtag group. Delete the whole `<section>` that renders
   `@facet_options.editorial_tags` — heading, chip row, and all. Do not delete `facet_pill/1`
   (Nivel still uses it), do not touch `Catalog.facet_options/0`, and keep the `attr :tags`
   declaration and the call site's `tags={@tags}` pass-through: the assign is still reachable via
   its `?tags=` URL param, still counted by `active_filter_count/1`, and still cleared by
   `clear-filters`, so removing the attr would be a behavior change rather than a scope cut.

9. Moduledoc. Update it to describe: the new title/subtitle and placeholder copy; the per-section
   surface cards; the duration labels no longer repeating the heading's meaning; the "6+" chip
   and the fact that it rides the same `:players` scalar on purpose (single-select) with its
   open-ended predicate living in `Catalog`; the `shadow-sm` and 3-tier-type-cap translation
   decisions; and — stated unambiguously — that the editorial-hashtag group was cut
   DELIBERATELY per sketch 019 Round 3 and is expected to return in a future design pass, so it
   must not be "restored" as a bug fix without that pass happening first.

Then update `test/pukllay_club_web/components/filter_modal_test.exs`:
- The `clear_button_class` local in the disabled/enabled test currently pins the outlined variant
  string; repoint it at the ghost class combo so the regex still uniquely identifies the footer's
  secondary button (the CTA has no ghost class), and add an assertion that the button no longer
  carries the outline variant.
- The scalar-cluster test's duration assertion currently pins the prefixed label; change it to
  the bare `60 min` form and add `refute html =~ "Hasta"` against the RENDERED html so the
  prefix cannot creep back in via any chip.
- Add a test that the open-ended chip renders: with `players: 6`, the html contains
  `>6+<` (or the chip label with `aria-pressed`), `phx-value-scalar="players"` and
  `phx-value-choice="6"`.
- Add a test that the editorial group is gone: render with `facet_options` whose
  `editorial_tags` list is NON-empty (e.g. `[%{tag: "#CreaConexiones", meaning: "x"}]`) and
  assert the rendered html contains neither that tag string nor `phx-value-facet="tags"`. These
  are assertions against rendered output, not source greps — the moduledoc legitimately discusses
  the cut, so a source-level grep gate would be wrong here.
- Add a test for the new copy: title, subtitle, and the `¿Qué juego buscas?` placeholder.
- Add a test that each primary section and the disclosure carry the card wrapper classes
  (`rounded-box` and `bg-base-200` both present at least four times in the rendered html).
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/components/filter_modal_test.exs --warnings-as-errors</automated>
    <automated>grep -v '^\s*#' lib/pukllay_club_web/components/filter_modal.ex | grep -c 'phx-value-choice' | grep -q '^[3-9]'</automated>
  </verify>
  <done>The component test file passes in full, including the new copy/6+/editorial-cut/card tests. The rendered modal has no editorial-tag control, no chip label repeating the section heading's meaning, an outline-free clear button, and every `phx-value-choice` binding from before this task still present.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Placeholder parity, background dim/blur, and live browser verification</name>
  <files>lib/pukllay_club_web/live/catalog_live/index.ex, assets/css/app.css, test/pukllay_club_web/live/catalog_live_test.exs</files>
  <behavior>
    Against `CatalogLive.Index` via `Phoenix.LiveViewTest`:
    - Test 1: on first render the catalog wrapper carries `pk-dimmable` and does NOT carry the
      dimmed modifier.
    - Test 2: after clicking the element with `aria-label="Abrir filtros"`, the wrapper carries
      both `pk-dimmable` and the dimmed modifier.
    - Test 3: after clicking the close control, the dimmed modifier is gone again.
    - Test 4: the header nav search input renders the same placeholder string as the modal's.
  </behavior>
  <action>
Write the four assertions above first (they fail red — the wrapper does not exist yet), in the
existing `"filter surface reachable from the nav search box (SHELL-04, 01.1-06)"` describe block
in `test/pukllay_club_web/live/catalog_live_test.exs`. While in that file, fix the existing
`"clicking the filter-open button opens the modal surface"` test: its second assertion pins the
old capitalised title noun, which Task 2 removed — repoint it at `Encuentra tu juego`. Leave the
`refute html =~ "drawer-toggle"` / `"drawer-side"` test alone.

Then, `lib/pukllay_club_web/live/catalog_live/index.ex`:

1. Placeholder parity: change the `:nav_search` slot's `<.input>` placeholder to
   `¿Qué juego buscas?`, matching Task 2's modal input exactly. Both surfaces feed the same
   `phx-change="search"` handler; the placeholder is the only thing changing.

2. Dimmable wrapper. The page root is currently `<div class="pk-page space-y-6">` holding, in
   order: the sort toolbar, the carousel rows, the load-error state, the grid heading, the
   empty state, the loading skeleton grid, the real grid, the load-more row, then
   `<GamePreview.preview_host />` and `<FilterModal.filter_modal ... />`.
   Restructure to:

       <div class="pk-page">
         <div class={["space-y-6", "pk-dimmable", @filters_open && "is-dimmed"]}>
           ...every catalog section, unchanged, in the same order...
         </div>
         <GamePreview.preview_host />
         <FilterModal.filter_modal ... />
       </div>

   Two things here are load-bearing and must be called out in a comment above the wrapper:
   - `space-y-6` MOVES from the outer div to the inner one. Left on the outer div it would apply
     to a single child and silently collapse every gap between the page's sections.
   - The modal and the preview host MUST stay outside the wrapper. A CSS `filter` on an ancestor
     establishes a containing block for `position: fixed` descendants, so nesting them would both
     blur the modal itself and re-anchor its fixed positioning to the wrapper's box.
   No new assign: the class is driven by the existing `@filters_open`, the same assign already
   passed to the modal as `open=`.
   Deliberately NOT added: `aria-hidden` or `inert` on the wrapper. The `.FilterModal` hook
   already traps Tab focus inside the dialog, and `aria-hidden` over a subtree containing
   focusable elements is itself an accessibility violation. Note that in the comment so the
   omission reads as a decision.

3. `assets/css/app.css`, inside the `PK CATALOG SURFACES` block:
   - Add the base rules immediately BEFORE the file's single trailing
     `@media (max-width: 480px)` block (currently right after the `.pk-skel` rule), so that
     block stays last in the file as this stylesheet's stated discipline requires:

         .pk-dimmable {
           transition: filter var(--duration-base) var(--ease-out-soft);
         }

         .pk-dimmable.is-dimmed {
           filter: blur(3px) saturate(0.7) brightness(0.94);
           pointer-events: none;
         }

     Check the real names of the duration/easing custom properties in this file before writing
     them and use whatever the block already uses for its other transitions — do not invent a new
     one, and do not introduce a literal ms/cubic-bezier value.
   - Add `.pk-dimmable` to the selector list of the EXISTING
     `@media (prefers-reduced-motion: reduce)` block (the one already listing `.pk-search-morph`,
     `.pk-drawer`, etc. and setting `transition-duration: 1ms`) rather than opening a second
     reduced-motion block.
   - Add a group comment explaining that these numbers come from sketch 019 and that the filter
     value cannot be expressed with Tailwind utilities without arbitrary values, which is why it
     lives in this block at all.

Finally — the part `mix quality` provably cannot do. A previous quick task in this repo shipped
with a fully green suite and a completely broken interaction layer, because `render_click/1`
builds the event params map directly and never runs LiveView's client-side `extractMeta`. Run a
real browser against a real server and confirm each of the following, capturing a screenshot for
each numbered item into this task's quick directory:

    mix phx.server   # background; http://localhost:4000

Use the `claude-in-chrome` skill (or headless Chrome over CDP) to drive it:
  a. Load the catalog. Screenshot the resting grid.
  b. Click `[aria-label="Abrir filtros"]`. Screenshot. The grid behind the modal must be
     VISIBLY blurred and dimmed relative to (a) — compare the two screenshots, do not just
     assert the class is present. Confirm the modal itself is sharp and correctly centered
     (proof it is outside the filtered wrapper).
  c. Read the modal: title `Encuentra tu juego` + its subtitle; search placeholder
     `¿Qué juego buscas?`; Jugadores showing 2/3/4/5/6+; duration chips reading `30 min` /
     `60 min` / `90 min` / `120 min`; Jugadores, Duración máxima, Nivel and the disclosure each
     visibly in their own tinted rounded card. Confirm NO editorial-hashtag group renders
     anywhere in the modal.
  d. With no filters active, read the computed style of the `Limpiar filtros` button: it must be
     disabled, with a transparent/none background and zero visible border width at rest.
  e. Click the `6+` chip. The CTA count and the grid must both change, the chip must show its
     selected (filled) state, and the resulting count must match Task 1's `open_six_plus` number
     from the same dev database. A count that does not move at all is the exact
     green-suite/broken-browser failure mode this step exists to catch.
  f. Click `4`, then `6+` again: only one Jugadores chip may be selected at a time.
  g. Click `Limpiar filtros` (now enabled), then close the modal. The background must return to
     sharp and undimmed.
  h. Repeat (b) and (g) at a 390px-wide viewport to confirm the bottom-sheet layout still works
     and the dim still applies.

Record the observed counts from (e) and any deviation in the SUMMARY.
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/live/catalog_live_test.exs --warnings-as-errors</automated>
    <automated>grep -v '^\s*/\*' assets/css/app.css | grep -c 'pk-dimmable' | grep -q '^[3-9]'</automated>
    <automated>mix quality</automated>
    <human-check>Review the browser screenshots from steps (a)-(h): the background visibly blurs on open and reverts on close, the 6+ chip moves the live count to the number Task 1 measured, no editorial-hashtag group renders, and Limpiar filtros has no border or fill at rest.</human-check>
  </verify>
  <done>`mix quality` is green; the four LiveView assertions pass; and all eight browser steps are confirmed with screenshots, including a 6+ count that matches Task 1's measured `open_six_plus`.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| browser → LiveView event | `toggle-scalar` payloads (`scalar`, `choice`) arrive attacker-controllable |
| URL query string → `handle_params/3` | `?players=` reaches the new open-ended predicate |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-eqc-01 | Tampering | `Catalog.maybe_filter_players/2` (new open-ended clause) | medium | mitigate | The clause interpolates through Ecto's `^` parameter binding, never string interpolation, so the widened predicate adds no injection surface. The value reaching it is already normalised to an integer-or-nil by `parse_int/1` (non-binary and unparseable inputs degrade to `nil`), so a crafted `?players[]=1&players[]=2` still cannot reach SQL. |
| T-eqc-02 | Denial of Service | `count_games/1` + `filter_games/1` via `?players=` | low | accept | The open-ended clause is strictly less selective than exact fit, but `filter_games/1` always applies `LIMIT` (T-01-22) and `count_games/1` is a bare aggregate over an already-bounded ~400-row table. No new unbounded result set is introduced. |
| T-eqc-03 | Information Disclosure | editorial-tag facet removal | low | accept | Removing the UI control is a presentation cut only — `?tags=` remains a valid, membership-validated URL param against the closed `Vocabulary.editorial_tags/0` set, exactly as before. No data becomes newly reachable or newly hidden at the query layer. |
| T-eqc-SC | Tampering | package installs | low | accept | No package-manager install task exists in this plan — no new hex/npm dependency is added. |
</threat_model>

<verification>
1. `mix quality` green end to end (hex.audit, deps.audit, deps.unlock --check-unused,
   format --check-formatted, credo --strict, sobelow --config, test --warnings-as-errors).
2. `MIX_ENV=dev mix run` sanity check prints a nonzero `open_six_plus`, and all four bucket
   numbers are recorded in the SUMMARY.
3. Live browser pass (steps a-h of Task 3) with screenshots, confirming specifically:
   the 6+ chip narrows results to the measured count; no editorial-hashtag group renders; the
   background grid blurs/dims on open and reverts on close; `Limpiar filtros` has no border or
   fill at rest.
4. `git diff` review confirming zero changes to: event handler names, `phx-value-*` attribute
   names, `scalar_assign_key/1`, `facet_assign_key/1`, `apply_filters/1`, the two colocated
   hooks, and the exact-fit players predicate for 2..5.
</verification>

<success_criteria>
- Every `must_haves.truths` entry is observably true in a running browser, not only in ExUnit.
- The editorial-hashtag cut is documented in the moduledoc as deliberate and expected to return.
- The "6+" bucket ships with a real, measured, nonzero match count against the real catalog, and
  the delta vs the old exact-fit chip (`only_seven_plus`) is stated explicitly in the SUMMARY.
- No new hook, assign, URL param, facet, or event handler was introduced.
- Every visual value comes from a daisyUI/Tailwind theme token or the one sanctioned custom-CSS
  block — no arbitrary Tailwind values, no raw colors, no inline `style=`, no 4th type tier.
</success_criteria>

<output>
Create `.planning/quick/260824-eqc-implement-sketch-019-s-winning-design-va/260824-eqc-SUMMARY.md` when done.
</output>
