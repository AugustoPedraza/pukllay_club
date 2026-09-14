defmodule PukllayClubWeb.FilterModal do
  @moduledoc """
  Stateless filter modal (SHELL-04, 01.1-06, quick-260824-b71, sketch 019
  finish pass quick-260824-eqc) — replaces the slide-over `FilterDrawer`
  retired before it. Presents a pinned three-region shell (header /
  scrolling body / pinned footer). The header reads "Encuentra tu juego"
  with a one-line subtitle framing the modal as answering the visitor's
  own question rather than a technical "Filtros" label. The body holds
  the free-text query input (placeholder `¿Qué juego buscas?`, matching
  `CatalogLive.Index`'s nav search box — Task 3 of quick-260824-eqc keeps
  the two in sync), then a primary always-visible cluster (Jugadores/
  Duración máxima chips + the Nivel weight-band pills, each inside its
  own `rounded-box bg-base-200 p-4` card per sketch 019 variant D), then
  one collapsed `<details>` disclosure — also carrying the card
  treatment — holding a searchable Mecánicas/Temáticas checklist pair
  (the 67-option pill walls the shipped component used to dump flat into
  the always-visible body). The footer holds two actions: a `Limpiar
  filtros` ghost (no border/fill at rest) button (disabled whenever no
  filter or query is active) and a `Ver N juegos` primary CTA.

  **Editorial-hashtag group cut, superseded by a Secciones facet (D-27,
  01.8.1-11).** Sketch 019 Round 3 (quick-260824-eqc) removed the old flat
  `Destacados` pill row rendering `@facet_options.editorial_tags` — the
  hashtag vocabulary itself is retired (01.8.1-10/11 migrated it into
  staff-owned `sections`). D-27 (a user decision) brings a facet back for
  the replacement concept: the `Secciones` card below, directly after
  Nivel, lists the visible hand-picked sections and reuses the same
  pill-cluster markup and `toggle-facet` event Nivel already uses — this
  is a planner assumption (no UI-SPEC exists for this facet), since a
  future design pass may want a different presentation. It deliberately
  does NOT resurrect the old flat hashtag pill row FilterModal's prior
  moduledoc warned against reintroducing (RESEARCH.md anti-pattern) — this
  is a new facet over a new concept, not that one coming back.

  The disclosure auto-expands whenever a mechanic or theme is already
  selected, so re-opening the modal never hides an active choice — see
  `open={@mechanics != [] or @themes != []}` below. There is no age
  filter anywhere in this component: `min_age` was dropped per an
  explicit scope correction made during execution (difficulty/Nivel
  already serves the purpose an age filter would have), so the
  disclosure's expand condition and count suffix cover only mechanics
  and themes. The `.FilterChecklist` colocated hook gives each checklist
  client-side, accent-insensitive text filtering and keeps the
  disclosure open across LiveView patches — see its own comment block
  below for the full contract.

  Jugadores/Duración máxima render as chip clusters (`scalar_chip/1`)
  rather than the retired `Otros filtros` number-input form — each chip
  click emits `"toggle-scalar"` with `phx-value-scalar`/`phx-value-choice`
  for exactly one scalar, so clicking one never resets another (the
  regression the old shared scalar form would have caused). `min_age`
  has no control anywhere in this component — dropped per an explicit
  scope correction during execution: difficulty (Nivel) already serves
  the purpose an age filter would have, and `min_age` stays reachable
  only via its existing `?min_age=` URL param, never via a UI control.

  **The "6+" bucket (quick-260824-eqc).** Jugadores renders the four
  exact-fit chips (2/3/4/5, `@players == n`) plus one standalone open-
  ended chip labelled "6+". Both families send `scalar="players"`, which
  is what keeps the cluster single-select through the untouched
  `toggle-scalar` handler — a second scalar name would let "4" and "6+"
  be selected simultaneously, which the chip row's visual language
  promises is impossible. The predicate difference lives entirely in
  `PukllayClub.Catalog.maybe_filter_players/2`: below 6 it's an exact
  seat-count fit, at/above 6 it's open-ended (`max_players >= n`, no
  upper bound) — see that module's `@players_open_bucket` for the full
  rationale. Duración máxima's chip labels dropped the redundant "Hasta"
  prefix (now bare `"N min"`) since the section heading already
  carries the "up to" meaning; the underlying `max_playtime`/
  `coalesce(playing_time, max_playtime) <= n` predicate is unchanged.

  **Type-tier deviation (quick-260824-eqc):** sketch 019's group label
  used an 11px uppercase letter-spaced treatment. That would add a 4th
  type combo to a catalogue screen already measured and capped at 3
  (`ui-design-system` SKILL.md) — not adopted. Each card's `<h3>` stays
  on the existing `text-sm font-semibold` body-tier combo instead.

  Every facet pill toggle still emits `"toggle-facet"` with
  `phx-value-facet`/`phx-value-choice`; the query input still emits
  `"search"` with `phx-debounce="300"`.

  The payload key is `choice`, never `value`, and that is load-bearing:
  LiveView's client-side `extractMeta` copies every `phx-value-*`
  attribute into the event payload and then unconditionally overwrites
  `payload.value` with the clicked element's NATIVE `.value` DOM property
  for any non-form element that has one. A `<button>` with no `value=`
  attribute has a native `.value` of `""` and a checkbox has `"on"`, so a
  `phx-value-value` binding on these controls is silently clobbered with
  no error anywhere in the stack — the exact bug that made every filter
  control a no-op in the browser while ExUnit stayed green (`render_click`
  builds the params map directly and never runs `extractMeta`). Do not
  rename this back to `value`; `mix test` cannot catch the regression.

  `facet_pill/1` and `scalar_chip/1`
  both build their class list from one shared `chip_class/1` helper so
  the two visually-identical chip families cannot drift apart. Selection
  state and open/closed state both live entirely in the parent
  `PukllayClubWeb.CatalogLive.Index` (this is a `Phoenix.Component`, not a
  `Phoenix.LiveComponent` — no state of its own, matching `FilterDrawer`'s
  discipline before it, per 01-PATTERNS.md). Live-apply is unchanged by
  this shell: every control still applies its filter immediately on
  click/keystroke, nothing is staged. The footer CTA (dispatching the
  `apply-filters` event, 01.2-03 D-02) is now the modal's one explicit
  submission signal — pressing it, even with nothing selected, tells
  `CatalogLive.Index` the member asked to see the current result set (its
  `:browse_all` assign), which is what lets an empty submission land on
  the full-catalog grid instead of being indistinguishable from a fresh
  page load. It still does not filter or apply anything itself, since
  filtering already happened underneath — it only records intent.
  Dismissal and submission are deliberately two different events: the
  backdrop button and the corner close button both still dispatch the
  `close-filters` event and change nothing about the result set, so
  closing the modal without pressing its CTA always returns the member to
  wherever they were (the carousels, if nothing was active).

  `core_components.ex` was checked and has no modal component — this uses
  daisyUI's bundled `modal`/`modal-open`/`modal-box`/`modal-backdrop`
  classes directly (confirmed unwired-but-available per
  `ux-patterns` SKILL.md row B10). The root element also carries
  `modal-bottom sm:modal-middle`, daisyUI's own responsive modifiers:
  below Tailwind's `sm` (640px) the panel renders as a bottom sheet
  (bottom-aligned, full-width, top-corners-only rounded); at and above it,
  a centered dialog. No custom media query or `.pk-*` class is needed —
  same markup, same events, same content order at both sizes.

  The `.FilterModal` colocated hook below owns only Escape-to-close and
  Tab focus-trapping — both copied structurally from `GamePreview`'s
  `onSheetKeydown` pattern (game_preview.ex), the same pattern
  `layouts.ex`'s mobile drawer already reused. Backdrop click and the
  explicit close button both dispatch the existing `close-filters` event
  directly; the hook never talks to the server.
  """
  use Phoenix.Component

  import PukllayClubWeb.CoreComponents

  attr :id, :string, required: true
  attr :facet_options, :map, required: true
  attr :mechanics, :list, default: []
  attr :themes, :list, default: []
  attr :weight_bands, :list, default: []
  attr :sections, :list, default: []
  attr :players, :integer, default: nil
  attr :max_playtime, :integer, default: nil
  attr :open, :boolean, default: false
  attr :q, :string, default: ""
  attr :total, :integer, default: 0
  attr :filters_active, :boolean, default: false

  def filter_modal(assigns) do
    ~H"""
    <div
      id={@id}
      class={["modal", "modal-bottom", "sm:modal-middle", @open && "modal-open"]}
      phx-hook=".FilterModal"
      data-modal-open={to_string(@open)}
    >
      <script :type={Phoenix.LiveView.ColocatedHook} name=".FilterModal">
        export default {
          mounted() {
            this.box = this.el.querySelector(".modal-box")
            this.closeBtn = this.el.querySelector("[data-modal-close]")
            this.wasOpen = this.el.dataset.modalOpen === "true"

            this.onKeydown = (event) => {
              if (event.key === "Escape") {
                event.preventDefault()
                this.closeBtn?.click()
                return
              }
              if (event.key !== "Tab" || !this.box) return
              const focusable = this.box.querySelectorAll(
                'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])'
              )
              if (focusable.length === 0) return
              const first = focusable[0]
              const last = focusable[focusable.length - 1]
              if (event.shiftKey && document.activeElement === first) {
                event.preventDefault()
                last.focus()
              } else if (!event.shiftKey && document.activeElement === last) {
                event.preventDefault()
                first.focus()
              }
            }
            this.el.addEventListener("keydown", this.onKeydown)

            if (this.wasOpen) this.closeBtn?.focus()
          },
          updated() {
            const isOpen = this.el.dataset.modalOpen === "true"
            if (isOpen && !this.wasOpen) this.closeBtn?.focus()
            this.wasOpen = isOpen
          },
          destroyed() {
            this.el.removeEventListener("keydown", this.onKeydown)
          }
        }
      </script>

      <button
        type="button"
        class="modal-backdrop"
        aria-label="Cerrar filtros"
        phx-click="close-filters"
      ></button>

      <div
        class="modal-box flex flex-col overflow-hidden p-0"
        role="dialog"
        aria-modal="true"
        aria-label="Encuentra tu juego"
      >
        <div class="flex flex-none items-start justify-between gap-3 border-b border-base-300 p-4">
          <div class="space-y-1">
            <h2 class="font-display text-xl">Encuentra tu juego</h2>
            <p class="text-neutral text-sm">
              Combina filtros para llegar a los juegos que te interesan.
            </p>
          </div>
          <button
            type="button"
            data-modal-close
            phx-click="close-filters"
            aria-label="Cerrar filtros"
            class="btn btn-ghost btn-circle min-h-11 min-w-11"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>

        <div class="min-h-0 flex-1 space-y-3 overflow-y-auto p-4">
          <form phx-change="search" id={"#{@id}-search"}>
            <.input
              type="text"
              name="q"
              value={@q}
              placeholder="¿Qué juego buscas?"
              phx-debounce="300"
              maxlength="100"
            />
          </form>

          <section class="rounded-box bg-base-200 p-4">
            <h3 class="mb-2 text-sm font-semibold">Jugadores</h3>
            <div class="flex flex-wrap gap-2">
              <.scalar_chip
                :for={n <- [2, 3, 4, 5]}
                scalar="players"
                value={to_string(n)}
                label={to_string(n)}
                selected={@players == n}
              />
              <%!-- Open-ended top bucket — rides the SAME :players scalar as
              the exact-fit chips above (single-select, by design). Its
              predicate lives in PukllayClub.Catalog.maybe_filter_players/2,
              guarded by @players_open_bucket (quick-260824-eqc). --%>
              <.scalar_chip scalar="players" value="6" label="6+" selected={@players == 6} />
            </div>
          </section>

          <section class="rounded-box bg-base-200 p-4">
            <h3 class="mb-2 text-sm font-semibold">Duración máxima</h3>
            <div class="flex flex-wrap gap-2">
              <.scalar_chip
                :for={n <- [30, 60, 90, 120]}
                scalar="max_playtime"
                value={to_string(n)}
                label={"#{n} min"}
                selected={@max_playtime == n}
              />
            </div>
          </section>

          <section class="rounded-box bg-base-200 p-4">
            <h3 class="mb-2 text-sm font-semibold">Nivel</h3>
            <div class="flex flex-wrap gap-2">
              <.facet_pill
                :for={band <- @facet_options.weight_bands}
                facet="weight_bands"
                value={band.value}
                label={band.label}
                selected={band.value in @weight_bands}
              />
            </div>
          </section>

          <%!-- D-27: reuses the Nivel cluster's own markup/pill component and
          `toggle-facet` event verbatim — the choice value is the section's
          own database id (as a string; CatalogLive.Index's `toggle-facet`
          clause parses it back with `Integer.parse/1`). Omitted entirely
          when there is nothing to show (an empty catalog, or every manual
          section hidden/empty), matching every other facet card's implicit
          "nothing to filter by" behavior. --%>
          <section :if={@facet_options.sections != []} class="rounded-box bg-base-200 p-4">
            <h3 class="mb-2 text-sm font-semibold">Secciones</h3>
            <div class="flex flex-wrap gap-2">
              <.facet_pill
                :for={section <- @facet_options.sections}
                facet="sections"
                value={to_string(section.id)}
                label={section.name}
                selected={section.id in @sections}
              />
            </div>
          </section>

          <details
            id={"#{@id}-more"}
            phx-hook=".FilterChecklist"
            class="rounded-box bg-base-200 p-4"
            open={@mechanics != [] or @themes != []}
          >
            <script :type={Phoenix.LiveView.ColocatedHook} name=".FilterChecklist">
              export default {
                // Owns two jobs, no server communication:
                //   1. Sticky disclosure state — without this, unchecking the
                //      last mechanic/theme re-renders `open` as false and
                //      snaps the disclosure shut under the user mid-browse.
                //   2. Client-side, accent-insensitive checklist filtering —
                //      operates ONLY on already-rendered, HEEx-escaped DOM
                //      nodes (never assigns innerHTML or builds markup from a
                //      facet label). Sets row visibility via a JS-assigned
                //      `row.style.display` (not the banned author-written
                //      `style=` markup attribute): Tailwind's `flex` on the
                //      row and the `hidden` attribute/utility resolve
                //      `display` at equal specificity, so only a JS-assigned
                //      inline property reliably wins.
                mounted() {
                  this.sticky = this.el.open
                  this.queries = {}

                  this.onToggle = () => { this.sticky = this.el.open }
                  this.el.addEventListener("toggle", this.onToggle)

                  this.onInput = (event) => {
                    const input = event.target.closest("[data-fc-input]")
                    if (!input) return
                    const key = input.dataset.fcInput
                    this.queries[key] = input.value
                    this.filterList(key, input.value)
                  }
                  this.el.addEventListener("input", this.onInput)
                },
                updated() {
                  if (this.sticky) this.el.open = true
                  for (const [key, query] of Object.entries(this.queries)) {
                    const input = this.el.querySelector(`[data-fc-input="${key}"]`)
                    if (input) input.value = query
                    this.filterList(key, query)
                  }
                },
                destroyed() {
                  this.el.removeEventListener("toggle", this.onToggle)
                  this.el.removeEventListener("input", this.onInput)
                },
                normalize(value) {
                  return value
                    .normalize("NFD")
                    .replace(/[̀-ͯ]/g, "")
                    .toLowerCase()
                },
                filterList(key, query) {
                  const list = this.el.querySelector(`[data-fc-list="${key}"]`)
                  const empty = this.el.querySelector(`[data-fc-empty="${key}"]`)
                  if (!list) return
                  const needle = this.normalize(query || "")
                  let visibleCount = 0
                  list.querySelectorAll("[data-fc-row]").forEach((row) => {
                    const matches = this.normalize(row.dataset.fcRow).includes(needle)
                    row.style.display = matches ? "" : "none"
                    if (matches) visibleCount += 1
                  })
                  if (empty) empty.hidden = visibleCount !== 0
                }
              }
            </script>

            <summary class="flex min-h-11 cursor-pointer list-none items-center gap-2 text-sm font-semibold">
              Más filtros: mecánica y temática
              <span :if={length(@mechanics) + length(@themes) > 0} class="text-neutral font-normal">
                ({length(@mechanics) + length(@themes)})
              </span>
            </summary>

            <div class="mt-3 grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.checklist
                key="mechanics"
                label="Mecánicas"
                options={@facet_options.mechanics}
                selected={@mechanics}
              />
              <.checklist
                key="themes"
                label="Temáticas"
                options={@facet_options.themes}
                selected={@themes}
              />
            </div>
          </details>
        </div>

        <%!-- button/1 uses assign_new(:class, ...), which only fills in a
        default when :class is unset — passing class explicitly REPLACES the
        variant class list rather than appending to it. Both footer actions
        therefore pass an explicit class list and omit variant entirely. --%>
        <div class="flex flex-none items-center justify-between gap-3 border-t border-base-300 p-4">
          <.button
            class={["btn", "btn-ghost", "min-h-11"]}
            phx-click="clear-filters"
            disabled={not @filters_active}
          >
            Limpiar filtros
          </.button>
          <%!-- min-w-40 + tabular-nums (Task 2, G-01.2-4 defect C): the label
          carries a live match count, so it resizes on every facet click and
          keystroke, dragging the whole footer row with it. Sized for the
          widest string the catalog can produce — "Ver 9999 juegos" (16
          chars, a 4-digit ceiling one order of magnitude above today's
          ~434-game catalog, per the plan's own sizing note), which is wider
          than the singular "Ver 1 juego" (11 chars) — via a character-count
          estimate (no live browser measurement tool in this environment):
          ~8px/char average for this button's font plus its own horizontal
          padding comfortably fits inside 10rem. tabular-nums stops the
          digits themselves from shifting width as the count changes. The
          count still updates on every interaction — only the box stops
          moving. --%>
          <.button
            class={["btn", "btn-primary", "min-h-11", "min-w-40", "tabular-nums"]}
            phx-click="apply-filters"
          >
            {cta_label(@total)}
          </.button>
        </div>
      </div>
    </div>
    """
  end

  attr :facet, :string, required: true
  attr :value, :string, required: true
  attr :label, :string, required: true
  attr :selected, :boolean, default: false

  defp facet_pill(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="toggle-facet"
      phx-value-facet={@facet}
      phx-value-choice={@value}
      aria-pressed={@selected}
      class={chip_class(@selected)}
    >
      {@label}
    </button>
    """
  end

  attr :scalar, :string, required: true
  attr :value, :string, required: true
  attr :label, :string, required: true
  attr :selected, :boolean, default: false

  defp scalar_chip(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="toggle-scalar"
      phx-value-scalar={@scalar}
      phx-value-choice={@value}
      aria-pressed={@selected}
      class={chip_class(@selected)}
    >
      {@label}
    </button>
    """
  end

  attr :key, :string, required: true
  attr :label, :string, required: true
  attr :options, :list, required: true
  attr :selected, :list, required: true

  # One searchable checklist (`.FilterChecklist`'s `data-fc-*` contract) —
  # used twice (mechanics, themes) inside the shared disclosure. `key` must
  # match `facet_assign_key/1`'s clauses in `CatalogLive.Index`, since each
  # row reuses `toggle-facet` verbatim (no new server plumbing). A raw
  # `<input>` is used for the search box rather than `CoreComponents.input/1`,
  # which wraps its field in a fieldset this layout has no room for. Because
  # it bypasses input/1 it must carry input/1's focus:outline-hidden
  # focus-within:outline-hidden pair by hand (G-01-7,
  # .planning/debug/resolved/G-01-7-double-focus-ring.md), plus
  # focus:border-base-content because border-base-300 would otherwise pin
  # the border and leave no focus indicator.
  defp checklist(assigns) do
    ~H"""
    <div>
      <h4 class="mb-2 text-sm font-semibold">
        {@label}
        <span :if={@selected != []} class="text-neutral font-normal">({length(@selected)})</span>
      </h4>
      <div class="rounded-box border border-base-300">
        <input
          type="text"
          data-fc-input={@key}
          autocomplete="off"
          class="input input-ghost w-full rounded-none border-0 border-b border-base-300 focus:outline-hidden focus-within:outline-hidden focus:border-base-content"
          placeholder={checklist_placeholder(@key)}
        />
        <div data-fc-list={@key} class="max-h-40 overflow-y-auto">
          <label
            :for={opt <- @options}
            data-fc-row={opt}
            class="flex min-h-11 cursor-pointer items-center gap-2 px-3 text-sm hover:bg-base-200"
          >
            <input
              type="checkbox"
              class="checkbox checkbox-sm"
              checked={opt in @selected}
              phx-click="toggle-facet"
              phx-value-facet={@key}
              phx-value-choice={opt}
            />
            {opt}
          </label>
        </div>
        <p data-fc-empty={@key} hidden class="text-neutral p-3 text-sm">Sin coincidencias</p>
      </div>
    </div>
    """
  end

  defp checklist_placeholder("mechanics"), do: "Buscar mecánica…"
  defp checklist_placeholder("themes"), do: "Buscar temática…"

  # Single source of truth for the chip's visual contract (ui-design-system:
  # "a field that must look identical on two surfaces is declared in exactly
  # one place") — both `facet_pill/1` and `scalar_chip/1` build their class
  # from this, so the two chip families cannot drift apart. Both families now
  # derive from the app-wide shared pill (`pk-pill`, assets/css/app.css PK
  # CATALOG SURFACES block, G-01.2-26/27; diagnosis at
  # .planning/debug/G-01.2-15-pill-chip-design-inconsistency.md), so this
  # helper's job has narrowed from "define the chip's visual contract" to
  # "choose which tone of the shared pill this state gets."
  #
  # The soft lift on the selected state (sketch 019, quick-260824-eqc) —
  # originally shipped here as the Tailwind utility `shadow-sm`, the
  # non-arbitrary translation of the sketch's soft colored box-shadow, since
  # a literal colored shadow would need a banned arbitrary Tailwind value —
  # moved with the lift: `pk-pill-selected` now declares that same
  # `box-shadow` once, in the base's own variant block, which is why no
  # shadow utility appears in either returned list below any more.
  #
  # No `min-h-11` here (quick 260913-1s5, revising quick 260912-rwv/WINDOWS
  # #18): the 44px touch target comes from `.pk-pill-interactive`'s own
  # `::after` hit layer now, not a drawn height utility — a per-call-site
  # `min-h-11` would re-inflate the chip's drawn box back to 44px over the
  # new 32px `pk-pill-comfortable.pk-pill-interactive` compact floor.
  defp chip_class(true) do
    ["pk-pill", "pk-pill-selected", "pk-pill-comfortable", "pk-pill-interactive"]
  end

  defp chip_class(false) do
    ["pk-pill", "pk-pill-outline", "pk-pill-comfortable", "pk-pill-interactive"]
  end

  defp cta_label(1), do: "Ver 1 juego"
  defp cta_label(n), do: "Ver #{n} juegos"
end
