---
name: ux-patterns
description: Stack-bound UX decision table for PukllayClub covering master/detail, long lists, navigation, carousels, create/edit, destructive actions, form validation, async feedback, filter/search, multi-step flows, dense list rows, empty states, progressive disclosure, action caps, and dashboard splitting. Load before building or editing a list, table, form, modal, navigation, or user-flow feature.
---

## Decision table

Situation matches this repo's real UI surfaces. Where a pattern isn't built here, the cell says
so and names what building it would require, rather than inventing a binding.

| Situation | Default | Flips when | Implement with (this repo) |
|---|---|---|---|
| B6/B31 Master/detail | Single-pane drill-down at narrow widths, two-pane above a width threshold | Window crosses that threshold | Not built — `CatalogLive.Show` is a single centred column at every viewport; the two-pane branch needs F34's device-target decision before a breakpoint can be picked |
| B7 Long lists | Load-more, not pagination or infinite scroll | n/a — already committed in this repo | `handle_event("load-more", ...)` + `phx-update="stream"` (`index.ex:126,312`); `<button phx-click="load-more" class="btn btn-outline">Cargar más</button>` (`index.ex:322`) |
| B8/B32 Navigation | Swap nav shape at breakpoint; on mobile prefer a visible tab bar over a hidden hamburger | Destination count exceeds ~5, or the window narrows back past the swap point | Not built — `Layouts.app`'s navbar only changes horizontal padding across breakpoints (`layouts.ex`); a nav-shape swap needs F34's device-target decision first |
| B9 Carousels | Avoid unless multiple items must share one slot; cap at 5 frames, visible in-carousel controls, slow auto-advance if used | Every single frame alone still gives an accurate impression | `CarouselRow.carousel_row/1` — daisyUI `carousel carousel-center gap-4 rounded-box` + `carousel-item` (`carousel_row.ex:24-25`); no auto-advance exists, and adding it needs a client-side JS hook (F33, LiveView has no timer primitive) |
| B10 Create/edit | Inline edit for one field in place; modal for a short bounded task; full page once too large for either | Field/step count grows past "short-term" | No inline-edit or modal wrapper exists in `core_components.ex` yet; daisyUI `modal`/`modal-box` classes are available but must be hand-wired |
| B11 Destructive actions | Warn before the action commits, not an undo-after toast | The message reports a change that already happened (that's an error, not a warning) | Not built; when needed, wire a confirm step with daisyUI `modal`/`modal-box`, not a toast |
| B12 Form validation | Validate after the action (blur/submit), not while typing; 1-2 sentence message stating the reason and next step, never an invented cause | The condition is one that *might* cause a problem later (that's a warning, see B11) | `CoreComponents.input/1` renders `<.error :for={msg <- @errors}>` beneath each input (`core_components.ex:235,256,276,299`); timing via `phx-change`/`phx-blur`/`phx-submit` on the form |
| B13 Async feedback | Skeleton for a full-page load, spinner for a single module, skip both under ~1s | Wait crosses ~10s, or it's not a full-page load at all — use a progress bar instead | `@loading` assign gates `CarouselRow.skeleton_row/1` / `skeleton_card/1` (daisyUI `skeleton`), plus a grid skeleton at `index.ex:305` sharing the real grid's classes so loading doesn't reflow; `assign_async`/`<.async_result>` are the available LiveView primitive but unused here |
| B14 Filter and search | Search collapsed behind an icon by default; cap the toolbar at 5 visible actions | Search is a primary, frequently-used entry point for the view, not an occasional refinement | `phx-debounce="300"` on the search input + `phx-change="search"` (`index.ex:228,234`); `FilterModal.filter_modal/1` — daisyUI `modal modal-bottom sm:modal-middle`, live-apply on every control (`toggle-facet` for pills/checklist rows, `toggle-scalar` for the players/duration chip clusters, debounced `search`), a footer CTA that only closes the surface (never a submit — filtering already happened live), and the 67 mechanic/theme options collapsed into one auto-expanding disclosure with a searchable checklist per facet, rather than two always-visible pill walls |
| B15 Multi-step flows | One question per page — back link, page heading, continue button, never re-ask the same field | Fields are tightly related enough that splitting breaks one mental model (e.g. a date's day/month/year) | Not built |
| B28 Dense list rows | Keyboard nav (arrows / `J` / `K`) plus a command bar for actions, with a hover-revealed checkbox as the pointer fallback | User is a pointer user without the shortcuts — the same selection stays reachable via the checkbox | Not built — needs a client-side JS hook per F33, since a server round-trip per keypress would feel laggy during rapid navigation |
| B30 Empty states | Unresolved — source (Shopify Polaris) was unreachable during research | Stays unresolved regardless of context | Not built; do not invent an empty-state pattern from memory |
| D21 Progressive disclosure | Keep identifying/summary data in the always-visible row; put supplementary detail behind an expand control | The hidden information is required to complete the primary task, not just supplementary | `CoreComponents.table/1` (`id`, `rows`, `:col` slot) has no expand-row variant yet; build on top of it, don't hand-roll a new table |
| D22 Action caps | Cap a toolbar at 5 actions; cap inline row icon actions at fewer than 3 before switching to a labelled menu | Row-level vs toolbar-level changes which cap applies (row: <3, toolbar: ≤5) | `CoreComponents.icon/1` (`hero-*` names) for inline icon buttons under the cap; `CoreComponents.button/1` for a labelled menu past it |
| D23 Dashboard splitting | Split into a hub-and-task overview once work spans multiple sessions or distinct activity groups | The work is simple enough to reduce task count instead — simplify before splitting | Not applicable — no dashboard exists in this repo yet |

## Where sources disagree

- **B10** (Atlassian inline edit vs GOV.UK change-link): house rule — no inline-edit component
  exists in `core_components.ex` today, so use a modal for a short edit and a full page for a
  larger one until an inline-edit component is actually built.
- **B13** (NN/g spinner-for-a-module vs Carbon skeleton-even-at-module-level): house rule — this
  repo has already committed to skeleton-only (`CarouselRow.skeleton_card/1`, no spinner
  component exists); keep using `skeleton` for both module- and page-level loading.
- **B6** (Material 840dp vs Microsoft 641epx breakpoint): house rule — moot until F34's
  device-target decision lands; do not pick either breakpoint number yet.

## Precedence

`ui-design-system` wins on any conflict with a source system named above — radius token, color
tokens, spacing scale, muted-text convention, heading font.
