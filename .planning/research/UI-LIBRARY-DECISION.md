---
title: UI Component Library Decision
date: 2026-08-21
status: decision
type: research
---

# UI Component Library Decision

**Question:** Should PukllayClub adopt a Phoenix component library layer, and if so which?

**Recommendation: None as a general component library. Keep `CoreComponents` + raw daisyUI classes
— with one narrow, named exception: adopt `live_select` if/when a real searchable-select need
appears, not preemptively.**

This is not the default-by-omission option — it is the only shape that survives the project's own
written disqualifier. Every *general-purpose component library* evaluated that provides real
interaction value beyond what daisyUI's markup+classes already give you (combobox, autocomplete,
focus-trapping, keyboard menu nav, ARIA wiring) does so by shipping **its own competing
design-token system** that the project's constraints explicitly rule out: *"any library that ships
its own color/token system and expects to own the visual layer. We are not replacing daisyUI."* The
one general library that doesn't violate that rule (`daisy_ui_components`) doesn't verifiably
deliver the behavior that would justify a dependency — see below.

A second research pass (below, "Additional candidates") specifically to check for anything missed
surfaced one exception to the "nothing passes both tests" pattern: **`live_select`**, a
narrowly-scoped, single-purpose searchable/multi-select field (not a general component library) that
ships a built-in `:daisyui` styling mode consuming daisyUI's own classes rather than a competing
token system. It's real, disqualifier-safe, and directly plugs the exact gap this document's
falsifying test names. It ships with **zero ARIA attributes**, though — so it doesn't fully answer
question 5 either. It's the closest thing to a genuine exception found, not a reversal of the "none"
recommendation for anything general-purpose.

---

## The single strongest reason

**Every component library with real behavioral value fails the disqualifier; the one that doesn't
fail it doesn't add real behavioral value.** That's not a coincidence — it's structural. A library
gets combobox/ARIA/focus-trap right by owning a cohesive design system end to end (shadcn's model,
Petal's model, Mishka's model). daisyUI already owns that role in this project. A library that
*doesn't* try to own the visual layer (`daisy_ui_components`) is, by construction, a thin typed
wrapper around daisyUI's existing classes — which is a convenience Phoenix.Component's `attr`/`slot`
macros already give you for free on hand-written components. There is no candidate that is both
disqualifier-safe and behaviorally additive. The tradeoff isn't "give up some polish for token
safety" — it's "there is nothing to gain that you don't already have."

Corroborating project evidence, not just theory: sketches 008/011/012 (see git log
`1c12d8b`, `0acc217`) already built and approved a filter modal — the most complex interactive
surface in the current design work — using nothing but `CoreComponents` and raw daisyUI classes.
The gap this research was meant to test ("can daisyUI alone carry real interaction complexity?") has
already been answered empirically, in this codebase, before this document was written.

---

## Evidence table

| Candidate | Version (verified) | Downloads (hex.pm) | Maintainers | License | Issue health | Phoenix/LV compat |
|---|---|---|---|---|---|---|
| **daisy_ui_components** (phcurado) | v0.9.8 — 2026-08-19 | 38,623 all-time / ~976 wk | 1 dominant (phcurado, 176 commits) of 14 | Apache-2.0 | 6 open, nothing stale | LV `~> 1.2` ✓, Phoenix 1.8+ recommended |
| **Mishka Chelekom** | v0.0.9 published (v0.0.10-alpha in dev) | 64,535 all-time | 1 dominant (shahryarjb, 802) of 9 | Apache-2.0 | 7 open, healthy | LV `~> 1.2` optional ✓, explicitly Tailwind 4 + Phoenix 1.8 |
| **SaladUI** | v1.0.0 — 2026-08-11 | 144,613 all-time / 1,810 wk | 1 (bluzky, 100% of last 6mo commits) | MIT | 4 open, **oldest 1.5+ yrs unaddressed** | LV `~> 1.2` ✓ |
| **Fluxon UI** | v3.1.1 (site), not on public hex.pm | UNVERIFIED (private repo) | 1 (andrielfn), closed-source | **Commercial** — $199/$399/$699 one-time | 5 open on tracker-only repo (no source) | Phoenix ≥1.7, LV ≥1.0, Tailwind ≥4 ✓ |
| **Petal Components** | v4.13.0 — 2026-08-11 | 1,442,099 all-time / 4,043 wk | 1 dominant (nhobes, near-daily) of ~45 | MIT (Petal Pro is separate paid product, doesn't gate this) | 51 open, oldest-age unverified but actively triaged | No explicit min version; confirmed updated for Tailwind v4 CSS-first config |
| **None (CoreComponents + daisyUI)** | current: phx.new 1.8 default, 506 lines, unmodified | n/a | project itself | n/a | n/a | native |
| **live_select** *(narrow, not general-purpose)* | v1.7.5 — 2026-02-08 | 653,714 all-time / ~4,433 mo | 1 dominant (maxmarcon) + occasional external PRs | Apache-2.0 | 20 open, several 1+ yr old | LV `~> 0.19 or ~> 1.0` ✓ |
| **Doggo** *(headless, combobox not yet functional)* | v0.14.7 — 2026-07-24 | 20,875 all-time / 683 mo | 1 dominant (woylie) | MIT | 13 open, reads as maintainer's own roadmap | LV `~> 1.1` ✓ |
| ~~PhiaUI~~ (dismissed) | v0.1.17, phia_ui | n/a | 1 (charlenopires) | MIT | 1 open | ships own Tailwind v4 `@theme` token system — same disqualifier as Petal/SaladUI |
| ~~phoenix-headlessui~~ (dismissed) | last push 2024-11-06 | n/a | 1 (ftes) | UNVERIFIED — no SPDX license found | n/a | reference repo, not a package; pulls in a React runtime bridge |

Every OSS candidate here is effectively a single-maintainer project right now, regardless of total
contributor count — that's a bus-factor fact worth weighing on its own, separate from the token
question.

---

## Per-candidate verdict

### daisy_ui_components (phcurado) — passes the disqualifier, fails to justify itself

1. **Conflicts with daisyUI tokens?** No — consumes daisyUI's existing semantic classes
   (`color`, `size`, `ghost` attrs map onto daisyUI's own utility vocabulary). This is the only
   candidate confirmed to compose rather than compete.
2. **Runtime dep or owned code?** Both models exist: a hex runtime dependency, *or* an
   installer (`mix archive.install hex daisy_ui_installer` → `mix daisy`) that copies component
   source into the app, shadcn-style.
3. **Exit cost if abandoned in 12 months?** Low either way — as a runtime dep, just stop
   upgrading it (Apache-2.0, no lock-in); as generated code, you already own it.
4. **Compile-time-checked attrs?** Yes, confirmed on `Menu`/`Select` — but this is a
   Phoenix.Component language feature, not something exclusive to this library. `CoreComponents`
   already does this.
5. **What does it cover that daisyUI cannot?** Checked directly (`menu.ex`, `select.ex`):
   **nothing**. `Menu` renders a plain `<ul>` with no ARIA attributes or JS hooks. `Select` is a
   native `<select>` wrapper with no search/filter. No `phx-hook` references in either file. It is
   a typed-attribute convenience layer over markup you can already write by hand. (Caveat: only 2
   of ~35 components were inspected — modal/drawer/dropdown weren't individually checked and could
   differ, but the pattern across the two checked components gives no reason to expect a different
   result.)

**Disqualifying fact:** none on the token rule — this is the only candidate that passes it. It's
excluded on cost/benefit: near-zero verified behavioral upside for a new dependency with a
single-maintainer bus factor, on an app that already has the same typed-attr capability natively.

### Mishka Chelekom — DISQUALIFIED

**Disqualifying fact:** ships its own competing token layer. Fetched `button.eex` uses
`bg-primary-light`, `hover:bg-primary-hover-light`, `dark:bg-primary-dark`,
`from-gradient-primary-from-light` — a self-contained `-light`/`-dark` suffixed palette configured
via its own `mix mishka.ui.css.config` task. Zero mention of daisyUI in the README. This is exactly
the "ships its own color/token system and expects to own the visual layer" case the constraint
names directly.

Notable in its favor, for the record: it's dev-only (not present in production — components are
generated then owned), and its headless behavior set is the richest surfaced in this research
(searchable + creatable combobox, menu/menubar/context-menu, dialog/drawer, tabs/accordion,
popover/tooltip/slider) — claimed "full WAI-ARIA wiring" but unverified at the code level. If the
token rule is ever relaxed, this is the strongest re-examination candidate on capability grounds
alone. Today, the token conflict is disqualifying regardless of that strength.

### SaladUI — DISQUALIFIED

**Disqualifying fact:** ships the canonical shadcn/ui token set (`--background`, `--foreground`,
`--primary`, `--sidebar-*`) under its own `@theme inline` block, confirmed by fetching the generated
`tailwind.theme.css` directly. Both SaladUI and daisyUI 5 define `--color-primary` inside a Tailwind
v4 `@theme` block — this isn't a stylistic mismatch, it's a **literal custom-property collision**:
whichever `@theme` loads last wins, non-deterministically from a maintenance standpoint. SaladUI
does not read or wrap daisyUI's variables; it expects a hand-populated parallel palette
(`--color-scheme` flag on install).

Also flagged independent of the token issue: effectively single-maintainer (100% of the last 6
months of commits are one author), and its oldest open issue (#143, sidebar/mobile) has sat
unaddressed for over 1.5 years — a real maintenance-health signal, not just a token problem.
Combobox — the interaction this research cares most about — is an **open, unimplemented feature
request** as of this check (#187), so even setting the token conflict aside, it doesn't yet cover
the gap it would be adopted for.

### Fluxon UI — DISQUALIFIED (two independent reasons)

**Disqualifying fact (token):** ships its own theme system (`@import ".../fluxon/priv/static/theme"`),
explicitly described by its own docs as following "different design principles" from daisyUI — a
second, parallel, non-integrated token system by the vendor's own admission.

**Disqualifying fact (budget):** commercial, one-time license — **$199 (1 user) / $399 (5 users) /
$699 (15 users)**, gated behind a private Hex repository requiring an ongoing license key just to
pull updates. The project constraint states "prefer free/open-source; flag any commercial license
explicitly with its actual cost" — this is that flag, and the cost is real, not nominal.

Compounding factor: closed-source. Every other candidate's claims here were checked against actual
component source; Fluxon's could not be, at any price point, without buying a license first. Its
interaction claims (cascading searchable select, autocomplete, keyboard-navigated date picker,
stacked dialogs with correct focus return) are the most compelling on paper of any candidate, and
also the least independently verifiable.

### Petal Components — DISQUALIFIED, but with the strongest *verified* (not claimed) evidence

**Disqualifying fact:** ships its own Tailwind v4 styling system (`default.css`, imported directly),
explicit "composable primitives, you own the patterns" philosophy, zero daisyUI mention anywhere in
its docs. The specific collision severity (vs. SaladUI's confirmed literal `--color-primary` clash)
is not directly confirmed — this is flagged as needing a spike if the rule is ever revisited — but
the library's own stated intent is to be *a* design system, which is what the constraint rules out
regardless of exact CSS specificity mechanics.

This is the one candidate where item 5 (what daisyUI can't do) was **confirmed in source, not
inferred from marketing copy**: `combo_box.ex` shows a genuine ARIA combobox pattern (`role`,
`aria-activedescendant`, `aria-expanded`, `aria-controls`, `aria-haspopup`), real keyboard
navigation (arrow-key traversal, type-to-filter, Enter-to-select), and virtual focus management.
It is also by a wide margin the most established candidate (1.44M downloads, near-daily commits).
If PukllayClub ever needs to revisit "none" — e.g., a genuinely complex combobox-heavy recommender
UI in Phase 2 that CoreComponents can't reasonably hand-roll — Petal is the benchmark to re-evaluate
against, not because it passes the token rule (it doesn't) but because it's the only candidate whose
interaction claims are both real and inspectable.

---

## Additional candidates (second research pass)

The first pass covered the five candidates named in the original question. A follow-up sweep
specifically hunted for anything missed — narrowly-scoped or headless libraries that might not
trigger the token disqualifier the way a full component system does. Two surfaced as real and worth
deep verification; two more were triaged and dismissed quickly.

### live_select — the one real exception found

1. **Conflicts with daisyUI tokens?** No, by design. It ships three explicit styling modes —
   `tailwind` (default), `daisyui`, `none` — documented directly: *"`daisyui`: uses daisyUI
   classes."* In `:daisyui` mode its defaults are daisyUI semantic classes (`dropdown
   dropdown-open`, `bg-base-200 dropdown-content menu`, `badge badge-primary`), not a custom
   palette. Every element also exposes a `{element}_class` / `{element}_extra_class` override, and
   `:none` mode hands you full manual control. This is the only candidate across both research
   passes confirmed to explicitly target daisyUI as a first-class styling mode rather than
   competing with or ignoring it.
2. **Runtime dependency or owned code?** Runtime hex dependency (`{:live_select, "~> 1.7"}`), plus
   a JS hook that must be wired into `app.js` and a Tailwind content-path addition. Not generated
   code you own.
3. **Exit cost if abandoned in 12 months?** Moderate, not low: unlike a pure-markup dependency,
   losing upstream means losing JS-hook maintenance (browser/LiveView JS-interop compat) too, not
   just Elixir code. Apache-2.0, so forking is legally unencumbered if that happens. 653k all-time
   downloads and 20 open issues (some 1+ year unaddressed) suggest steady but not fast-response
   maintenance — moderate bus-factor risk, same single-dominant-maintainer pattern as everything
   else in this document.
4. **Compile-time-checked attrs?** No — confirmed directly by reading the 816-line
   `LiveSelect.Component` source: it's a `Phoenix.LiveComponent`, not `Phoenix.Component`, and
   attribute validation happens via a hand-written `validate_assigns!/1` function, not `attr`/`slot`
   macros. This is a real gap relative to `CoreComponents`' own components, which do use `attr`.
5. **What does it cover that daisyUI cannot?** Debounced server-side search-as-you-type
   (`phx-change` → `live_select_change` event), single-select, tags (multi-select), and
   quick-tags modes — real, working dropdown-selection behavior daisyUI's static markup doesn't
   provide. **But it is not ARIA-managed**: a direct grep of both the JS hook
   (`assets/js/live_select.js`) and the full server-side component found **zero** instances of
   `role="combobox"`, `aria-activedescendant`, `aria-expanded`, or `aria-selected`. Keyboard
   handling is generic (`Enter` intercepted, other keys forwarded raw to the server) rather than a
   dedicated ARIA-pattern key listener. So it solves the *search-and-select* half of the gap this
   document's falsifying test names, but not the *accessible-widget* half — that would need to be
   layered on manually (e.g., via the `*_class`/render overrides plus custom hook additions) if it
   matters for this project's "teach a new player" audience.

**Verdict:** not disqualified, and the single strongest candidate surfaced across both passes —
but adopt it narrowly, only when a real searchable/multi-select need exists (the "algo de
negociación estilo Catan" natural-language matching UI is the most plausible near-term trigger),
and budget separate work for the ARIA gap it doesn't close on its own. It is not a substitute for
"none" as the answer to the original general-purpose-library question; it's a scoped, single-purpose
tool that happens to pass the same test everything else failed.

### Doggo — disqualifier-safe, but doesn't close the gap today

1. **Conflicts with daisyUI tokens?** No CSS ships at all — confirmed via its README: *"designed
   without default styles and does not prefer any particular CSS framework."* No `@theme` tokens or
   CSS custom properties of its own were found. As of v0.13.0 it renders `data-*` attributes
   (`data-size="small"`) for style variants instead of classes, which is a markup-selector
   convention you must target in your own CSS — a real constraint, but not a color/token conflict.
2. **Runtime dependency or owned code?** Runtime hex dependency (`{:doggo, "~> 0.14.7"}`) exposing
   `Doggo.Components` macros you `use`; separate optional dev tasks (`mix dog.gen.stories`, `mix
   dog.safelist`) are tooling, not the install path.
3. **Exit cost if abandoned in 12 months?** Low — no CSS to unwind, MIT-licensed, and since you
   write 100% of the styling yourself there's little vendor-specific surface to migrate away from
   beyond the `attr`/`slot` call sites themselves.
4. **Compile-time-checked attrs?** Yes, standard `Phoenix.Component` `attr`/`slot` across its ~63
   components.
5. **What does it cover that daisyUI cannot?** For the one behavior this document cares about
   most — combobox — **nothing yet**: Doggo's own docs mark it **"Experimental"** and state
   explicitly that "the necessary JavaScript for making this component fully functional and
   accessible will be added in a future version." No ARIA, no filtering, no keyboard support today.
   Elsewhere it does ship real JS-hook-backed behavior (e.g. carousel, via Elixir 1.18+ colocated
   hooks) — but nothing that fills this project's actual gap right now. Its other 60+ components
   are, like `daisy_ui_components`, primarily a typed-markup convenience layer you could hand-roll.

**Verdict:** genuinely disqualifier-safe, worth a watch (its combobox may mature), but adds no real
capability over "none" today. Not recommended now; revisit specifically if its combobox ships real
ARIA/keyboard behavior in a future release.

### Dismissed quickly

- **PhiaUI** (`phia_ui` on hex.pm, v0.1.17) — real and actively developed, but ships its own
  Tailwind v4 `@theme` token system with pre-built theme palettes (`mix phia.theme install`) —
  same disqualifier as Petal/SaladUI/Mishka. Not deep-dived further.
- **phoenix-headlessui** (`ftes/phoenix-headlessui`) — genuinely headless (no shipped CSS), but
  stale (last push Nov 2024), no clear license (null SPDX), and architecturally a demo/reference
  wrapping Tailwind Labs' **React** HeadlessUI rather than an installable Elixir-native package —
  fails on maintenance currency and dependency footprint, not on the token rule.
- Noted but not verified at all: `teamon/headless` and `TunkShif/sprout_ui` (the latter flagged in
  passing as possibly archived/deprecated) — surfaced by search, not fetched or confirmed. Listed
  here only so they aren't silently lost; treat as unresearched, not as ruled out.

---

## Does `/gsd-ui-phase` already cover the consistency problem?

**No — it solves a different, earlier-stage problem than "does the code stay consistent."**

Read directly (`~/.claude/gsd-core/workflows/ui-phase.md`, `~/.claude/agents/gsd-ui-checker.md`,
`.claude/skills/gsd-ui-phase/SKILL.md`): `/gsd-ui-phase` produces a **prose design contract**
(`UI-SPEC.md`) per phase — spacing, typography, color, copywriting, design-system decisions — and
validates that document's internal quality against 6 dimensions (Copywriting, Visuals, Color,
Typography, Spacing, Registry Safety) *before planning starts*. It is a planning-time gate on
what gets *specified*, not a runtime or compile-time check on what gets *implemented*. It has no
mechanism that inspects `.heex`/`.ex` files for drift from the spec after code is written — that's
out of its scope entirely.

Dimension 6 ("Registry Safety") is the only one that sounds adjacent to this question, and it
isn't: it checks whether a **shadcn npm component registry** was vetted via `npx shadcn view` before
use — a mechanism built for the React/shadcn ecosystem's registry model. It has no hex.pm/Elixir
equivalent and doesn't apply to any of the five candidates evaluated here (none of them are shadcn
registries in the npm sense, even SaladUI, which is a *port* of shadcn's design, not a registry
consumed through the shadcn CLI).

So: `/gsd-ui-phase` is complementary to this decision, not a substitute for it. It will keep each
phase's *written* design choices consistent with the locked brand tokens; it does nothing to prevent
one phase's LiveView code from hand-rolling a slightly different button markup than another phase's,
because it never reads implementation code. If cross-phase implementation drift in raw daisyUI
markup becomes a real, observed problem (not a hypothetical one), the fix is a lightweight internal
convention doc + `mix credo` custom check or `/gsd-ui-review`'s retroactive visual audit — not a
third-party component library, which this document has just shown doesn't cleanly compose here.

## Minimum viable adoption — can wrappers and headless behavior come from different libraries?

**Only by disassembling a library into code you own — at which point it stops being "a library" and
the argument for depending on it evaporates.** Concretely: to take, say, Petal's `combo_box.ex` JS
behavior while restyling it in daisyUI classes, you would need to strip Petal's `default.css`
import, override every daisyUI-colliding class, and vendor the component into your own tree for
ongoing maintenance — which is indistinguishable from Mishka's or SaladUI's *generator* mode, minus
the tooling that mode provides to do it cleanly. You'd be maintaining forked third-party JS/HEEx
with none of the "upstream keeps updating it" benefit that motivated depending on a library in the
first place.

Running two libraries simultaneously as actual runtime dependencies (e.g., SaladUI + Petal) is
worse, not better: both define `--color-primary` (and `--color-accent`, `--color-secondary`, etc.)
under Tailwind v4 `@theme` blocks, on top of daisyUI's own definitions of the same names — three
non-cooperating writers to the same custom-property namespace, with cascade order (CSS import
order) silently deciding which theme wins per property. That's a bug generator, not a strategy.

**Practical minimum viable adoption, updated after the second research pass:** don't vendor and
restyle a disqualified library at all — use `live_select` directly for the specific searchable-select
gap, in its `:daisyui` styling mode, as a real (small) runtime dependency, and hand-add the ARIA
attributes it doesn't ship on top. That's cheaper and less fragile than forking a general library's
component into owned code, and it's the one case in this whole research where "take the behavior,
leave the design system" doesn't require disassembly — `live_select` was built to be styled by
whatever you already have. If a *different* gap ever needs a generator-mode library's behavior as a
one-time reference (e.g. Mishka's or SaladUI's combobox/menu source, restyled and vendored in), that
fallback from the original analysis still holds — it's just no longer the first thing to reach for.

---

## Migration cost, in concrete terms

Current surface (verified by grep, 2026-08-21):
- `lib/pukllay_club_web/components/core_components.ex` — 506 lines, unmodified `phx.new` default:
  `flash`, `button`, `input`, `header`, `table`, `list`, `icon`.
- 7 files under `lib/pukllay_club_web` currently call these components, out of 18 total web files.
- No JS framework dependency exists yet (no `package.json`, no Alpine/Stimulus — just esbuild +
  two vanilla hooks files, `app.js` and `theme.js`).

This is the cheapest point in the project's life to make this call — the surface is still small
either direction. Cost of the "none" recommendation: **zero migration, zero new files.** Cost of
adopting `daisy_ui_components` instead (the only non-disqualified alternative): trivial to install
(~1 dep + `mix daisy` if generator mode), but genuinely low value per the evidence above, so the
real cost is *ongoing dependency-update overhead for a library whose typed-attr benefit
`CoreComponents` already has natively*. Reversibility of "none" is total — there's nothing to
reverse. Reversibility of adopting any disqualified library, once real screens are built against
its component API/classes, scales with how many of those 7 (soon more) files call into it — currently
cheap, will not stay cheap.

---

## Cheap falsifying test

**Updated after the second research pass — this is now a three-way bake-off, not a two-way one, and
it's cheaper than originally scoped because one arm already exists as a package.** In one afternoon,
build the same real combobox/autocomplete for the game catalog's search box three ways and compare:

1. Hand-built with only `CoreComponents` + one small LiveView JS hook — server-filtered results on
   `phx-change`, arrow-key selection, `aria-expanded`/`aria-activedescendant` set by hand.
2. `live_select` in `:daisyui` styling mode, with hand-added ARIA on top (since it ships none).
3. (Optional, only if 1 and 2 both feel weak) Petal's `combo_box.ex` vendored in and restyled —
   the one candidate with source-verified, complete ARIA/keyboard behavior out of the box, at the
   cost of accepting its token-system tradeoff explicitly.

If (1) takes meaningfully more than an afternoon or produces visibly worse ARIA/keyboard behavior
than (2), that's evidence "none" doesn't hold and `live_select` should be adopted for this surface
now rather than deferred. If (1) and (2) come out roughly equivalent in effort, prefer (1) — it adds
zero dependencies. Only reach for (3) if both (1) and (2) prove genuinely insufficient, since it's
the only arm that requires accepting the token-system compromise this whole document argues against.

If (1) takes under an afternoon and the result is solid, that's the same evidence this document
already has from the sketch-008/011/012 filter modal — confirmed twice, not once.

---

## Open questions (could not resolve)

- **Petal Components' exact token-collision severity against daisyUI** was not confirmed the way
  SaladUI's was (SaladUI's was proven via a fetched, generated CSS file showing the literal
  `--color-primary` clash; Petal's `default.css` wasn't diffed against `theme.css` line-by-line).
  Flagged as unverified, not assumed safe.
- **Fluxon UI's actual component source** — inaccessible without purchasing a license, so items 4
  and 8 (compile-time attrs, exact update/versioning mechanics) are UNVERIFIED, not confirmed absent.
- **Mishka Chelekom's and SaladUI's ARIA/focus-trap implementations beyond the single component each
  checked** (`button.eex` / `accordion.ex`) — not verified across their full component sets; the
  "full WAI-ARIA wiring" claims are documentation claims, not independently confirmed for every
  component.
- **Whether `/gsd-ui-review`'s retroactive visual audit is sufficient, on its own, to catch
  cross-phase daisyUI drift** once the app has more than 7 files touching components — this
  document asserts it as the right lightweight fallback but did not stress-test it against a
  larger, multi-phase codebase than currently exists.
- **`live_select`'s exact behavior under this project's Elixir constraint** — `mix.exs` pins
  `elixir: "~> 1.17"` (satisfied by the installed 1.19.5 toolchain), which is fine for `live_select`
  itself, but Doggo's colocated-hooks-based components need Elixir 1.18+ specifically; if the
  project's declared floor is ever loosened toward 1.17 in practice (not just in the installed
  toolchain), that would silently break any future Doggo JS-hook component, not `live_select`.
  Flagged, not resolved, since it only matters if Doggo is adopted later.
- **The severity of `live_select`'s missing ARIA for this project's specific audience** — the
  project brief states the UX must not assume board-game vocabulary/familiarity, which is an
  accessibility-adjacent goal, but this document did not evaluate whether *keyboard/screen-reader*
  accessibility specifically is a stated project priority versus a general best practice. Whether
  hand-adding ARIA on top of `live_select` is "important, do it" or "nice to have, defer" was not
  resolved here and should be a product call, not an inferred one.
- **`teamon/headless` and `TunkShif/sprout_ui`** — surfaced by search during the second pass, never
  fetched or verified at all. Could contain a disqualifier-safe general-purpose option this document
  missed; flagged as the most likely place a third research pass would find something new.
