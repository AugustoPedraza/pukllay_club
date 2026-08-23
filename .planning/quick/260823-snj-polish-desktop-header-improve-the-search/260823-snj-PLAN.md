---
phase: quick-260823-snj
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/pukllay_club_web/components/layouts.ex
  - assets/css/app.css
  - test/pukllay_club_web/components/layouts_test.exs
  - .claude/skills/ui-design-system/SKILL.md
autonomous: true
requirements: [SHELL-01]

estimate:
  tokens: 45000
  raw_tokens: 45000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "On desktop the header's search control reads as a control at rest: a 44px circular pill with a visible border and a filled surface holding a 20px magnifying-glass icon at full base-content contrast — not a faint 16px glyph floating on the bare header bar."
    - "The resting search pill answers pointer hover and keyboard focus with the same primary-coloured treatment, so hover is never its only affordance."
    - "The header row's height is unchanged: the resting search control is still exactly 44px wide and 44px tall, so `--pk-header-h` and every sticky offset that reads it are untouched."
    - "Exactly one isologo mark appears on a rendered page, and it is the header's. The footer's brand lockup renders the wordmark plus its own tagline with no `<img>` at all."
    - "The header keeps its mark at every viewport width — including 481-767px, where the header wordmark is hidden and the mark is the header's only brand identity."
    - "The footer wordmark reads as a quiet sign-off rather than a second equal-weight brand: same Bebas 24px size (no new type combo added to the measured inventory), demoted to the muted colour tier."
    - "`brand_logo/1`'s existing compile-time `@isologo?` fallback still holds — a missing mark file still degrades to wordmark-only, never a half-rendered pair."
    - "`mix quality` passes end to end."
  artifacts:
    - lib/pukllay_club_web/components/layouts.ex
    - assets/css/app.css
    - test/pukllay_club_web/components/layouts_test.exs
    - .claude/skills/ui-design-system/SKILL.md
  key_links:
    - "`brand_logo/1`'s new `mark` attr -> `:if={@isologo? and @mark}` on both `<img>` -> the footer call site's `mark={false}` -> zero marks inside `.pk-footer-left`"
    - "`mark={false}` -> `pk-brand-quiet` modifier class on the anchor -> `.pk-brand-quiet .pk-brand-name` rule -> footer wordmark in the muted colour tier"
    - "`hero-magnifying-glass` in `header_inner/1` -> Tailwind content scan of `lib/pukllay_club_web/**` -> a generated `.hero-magnifying-glass` rule in `priv/static/assets/css/app.css` (a name typo yields a silently invisible icon, which is why this link is gated)"
    - "`.pk-search-morph` resting `base-100` fill -> the same `base-100` the `.is-open` state already sets -> the resting->open transition becomes a width change only, not a surface swap"
---

<objective>
Polish the desktop header on two counts the developer raised directly:

1. The search affordance is a 16px `hero-magnifying-glass-micro` glyph in the muted `neutral`
   colour sitting on a fully transparent 44px box. At desktop widths it reads as decoration, not
   as the site's search entry point. Raise its relevance to match what it actually does.
2. `Layouts.brand_logo/1` is called by both `header_inner/1` and `footer/1`, so every page renders
   the isologo mark twice. Two near-identical brand lockups compete for the same identity role.
   Make the mark belong to exactly one surface.

Purpose: the header is the shell every page shares (SHELL-01). A search control that does not read
as a control suppresses the feature the whole project exists to deliver, and a doubled brand mark
dilutes the identity both placements are trying to establish.

Output: an amended `brand_logo/1` with a `mark` attr, an amended `header_inner/1` search toggle,
edits to existing rules inside `app.css`'s `PK CATALOG SURFACES` block, inverted + extended tests in
`layouts_test.exs`, and a refreshed component-inventory row in the `ui-design-system` skill.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/skills/ui-design-system/SKILL.md
@.claude/skills/ux-responsive/SKILL.md

@lib/pukllay_club_web/components/layouts.ex
@assets/css/app.css
@test/pukllay_club_web/components/layouts_test.exs
</context>

<design_decisions>
Two judgement calls are locked here so the executor does not re-litigate them mid-task.

**D-A — The isologo mark becomes header-only; the footer is the side that gives it up.**
`app.css`'s base rule `.pk-nav-inner .pk-brand-wordmark { display: none }` hides the header wordmark
below 48rem, and the `@media (min-width: 48rem)` block near the end of the file is what reveals it.
Between 481px and 767px the mark is therefore the header's *only* brand identity — removing it from
the header would leave the header with no brand at all across a 287px band. The footer carries no
such constraint: `.pk-brand-wordmark` is unscoped there and renders at every width. So the footer
drops the mark and keeps the wordmark.

**D-B — The footer wordmark is demoted by colour, not by size.**
`ui-design-system`'s type hierarchy names weight and colour as the emphasis lever and reserves a
size bump for a genuinely larger content unit. The catalogue screen's measured inventory is already
at the 3-tier cap with `Bebas Neue / 24px / 400` as the single heading combo — a smaller Bebas size
in the footer would add a 4th combo and oblige a full re-measure. Demoting the footer wordmark to
`var(--color-neutral)` keeps the combo count fixed while removing the equal-weight competition.
</design_decisions>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Raise the header search toggle from decoration to control</name>
  <files>lib/pukllay_club_web/components/layouts.ex, assets/css/app.css, test/pukllay_club_web/components/layouts_test.exs</files>
  <read_first>
    - `lib/pukllay_club_web/components/layouts.ex` `header_inner/1` — the `.pk-search-morph` block and its toggle button.
    - `assets/css/app.css` — the `.pk-search-morph`, `.pk-search-morph-toggle` and `.pk-search-morph:hover:not(.is-open) .pk-search-morph-toggle` rules, plus the block comment above `.pk-search-morph.is-open` that records the measured row-seating arithmetic.
    - `assets/css/app.css` — the `.pk-nav` rule, to confirm the header bar's surface token before choosing the pill's fill.
    - `test/pukllay_club_web/components/layouts_test.exs` — the `render_with_nav_search/1` local wrapper and the `describe "app/1 search-morph (01.1-08)"` block.
  </read_first>
  <behavior>
    - Test 1: rendering through `render_with_nav_search/1`, the `.pk-search-morph-toggle` button's inner icon element carries the `hero-magnifying-glass` class and the `size-5` class.
    - Test 2: the same toggle button carries `title="Buscar"` in addition to its existing `aria-label="Buscar"`.
    - Test 3 (regression guard): the toggle still carries `aria-expanded="false"` and `aria-controls="pk-nav-search-region"`, and the close button still precedes nothing between it and the slot — i.e. the existing ordering assertions in the `describe` block still pass untouched.
  </behavior>
  <action>
Markup (`header_inner/1` in `layouts.ex`):

Swap the toggle's icon from `<.icon name="hero-magnifying-glass-micro" class="size-4" />` to
`<.icon name="hero-magnifying-glass" class="size-5" />`. The `-micro` heroicon is the 16px solid
variant, drawn for inline runs of text; this is a standalone 44px control, and the 24-outline
heroicon rendered at 20px fills it proportionally. `deps/heroicons/optimized/24/outline/magnifying-glass.svg`
exists, and `hero-bars-3` / `hero-x-mark` in `nav_drawer/1` already prove bare (24-outline) names
resolve through the `@plugin "../vendor/heroicons"` installation.

Add `title="Buscar"` to the same button, keeping the existing `aria-label="Buscar"`,
`aria-expanded` and `aria-controls` attributes exactly as they are. This gives desktop pointer
users a hover hint at zero layout cost.

Do NOT add a visible text label beside the icon. `.pk-search-morph` is pinned to a 44px resting
width and the comment above `.pk-search-morph.is-open` records the measured seating arithmetic
(250px brand + 24px gap + 166.3px nav links + 24px gap + 280px open pill + 64px gutters = 808.3px)
that the 48rem wordmark-reveal breakpoint is derived from. A wider resting control invalidates that
arithmetic and reopens the header-height and horizontal-overflow bugs the two most recent debug
sessions just closed.

CSS (`assets/css/app.css`, inside the `PK CATALOG SURFACES` delimited block — this layer's rule is
one class owning one visual property, so **edit the existing rules in place; do not append a second
competing rule for any property already declared**):

- `.pk-search-morph` base rule: give the resting state a real container. Set `background` to
  `var(--color-base-100)` and `border-color` to `var(--color-base-300)`. `.pk-nav` is
  `var(--color-base-200)`, so a `base-100` fill reads as an inset control against the header bar,
  and `base-100` is the exact token `.is-open` already sets — reuse it rather than introducing a
  new one. This also makes the resting-to-open transition a width change plus a border-colour
  change only, instead of a surface appearing out of nowhere. Layout is unaffected: the `1px`
  border is already declared on this rule and Tailwind preflight makes every box `border-box`, so
  the resting footprint stays exactly 44px x 44px. Leave `height`, `width`, `flex`, `margin-left`,
  `overflow`, `border-radius` and the `transition` list byte-unchanged.
- `.pk-search-morph-toggle`: raise the resting `color` from `var(--color-neutral)` to
  `var(--color-base-content)`. `neutral` is this app's muted/secondary text tier
  (`ui-design-system`, Spacing/typography scale); the site's search entry point must not sit in it.
  Change nothing else on this rule.
- The existing `.pk-search-morph:hover:not(.is-open) .pk-search-morph-toggle` rule: extend its
  selector list to also cover `.pk-search-morph:focus-within:not(.is-open) .pk-search-morph-toggle`,
  keeping the single `color: var(--color-primary)` declaration. Extending the existing selector is
  required rather than adding a second rule — two rules owning the same property is the drift this
  layer forbids.
- Add one new rule immediately after it, so the container answers the pointer and the keyboard the
  same way the glyph does:
  `.pk-search-morph:hover:not(.is-open), .pk-search-morph:focus-within:not(.is-open) { border-color: var(--color-primary); }`
  The `:not(.is-open)` guard keeps the open state's own `border-color` rule authoritative. Do not
  add a custom `outline` — no other button in this stylesheet declares one (the theme toggle, the
  hamburger and the drawer close all rely on the browser's default ring), and the border change is
  what makes the affordance legible without inventing a third focus language.

Tests (`layouts_test.exs`): add the three assertions from `<behavior>` as new tests inside the
existing `describe "app/1 search-morph (01.1-08)"` block, reusing `render_with_nav_search/1` and
the `LazyHTML.from_document/1 |> LazyHTML.query/2 |> LazyHTML.to_html/1` pattern the neighbouring
tests already use. Do not modify the existing tests in that block — they are the regression guard.
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/components/layouts_test.exs</automated>
    <automated>awk '/^\.pk-search-morph \{$/,/^\}$/' assets/css/app.css | grep -c 'var(--color-base-100)'</automated>
    <automated>awk '/^\.pk-search-morph \{$/,/^\}$/' assets/css/app.css | grep -c 'var(--color-base-300)'</automated>
    <automated>awk '/^\.pk-search-morph \{$/,/^\}$/' assets/css/app.css | grep -c 'height: 44px'</automated>
    <automated>awk '/^\.pk-search-morph \{$/,/^\}$/' assets/css/app.css | grep -c 'width: 44px'</automated>
    <automated>mix assets.build &amp;&amp; grep -cE '\.hero-magnifying-glass[^a-z-]' priv/static/assets/css/app.css</automated>
  </verify>
  <done>
`mix test` on the layouts suite passes. Each of the four `awk`-scoped greps against the
`.pk-search-morph` rule body returns exactly `1` — the first two proving the resting fill and border
tokens landed, the last two proving the 44px geometry contract survived. The built-stylesheet grep
returns at least `1`, proving the new heroicon name actually generates a class. If that last count
is `0` the icon name is wrong and the glyph would render invisibly — re-check the filename in
`deps/heroicons/optimized/24/outline/` before proceeding, do not continue past a `0`.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Make the isologo mark header-only and quiet the footer wordmark</name>
  <files>lib/pukllay_club_web/components/layouts.ex, assets/css/app.css, test/pukllay_club_web/components/layouts_test.exs, .claude/skills/ui-design-system/SKILL.md</files>
  <read_first>
    - `lib/pukllay_club_web/components/layouts.ex` lines 14-72 — the `@isologo?` compile-time gate, the `brand_logo/1` `@doc`, the test-only `isologo?` seam comment, and the component body.
    - `lib/pukllay_club_web/components/layouts.ex` lines 540-578 — the `footer/1` comment block and its `<.brand_logo tagline="Conectá jugando" />` call site.
    - `assets/css/app.css` — the `.pk-nav-inner .pk-brand-wordmark` rule and the long comment above it explaining why it is header-scoped.
    - `test/pukllay_club_web/components/layouts_test.exs` lines 51-111 and 352-414 — the two `describe` blocks that currently assert the footer DOES render both marks.
    - `.claude/skills/ui-design-system/SKILL.md` — the `Layouts` / `brand_logo/1` row in the component inventory table.
  </read_first>
  <behavior>
    - Test 1: `render_component(&Layouts.brand_logo/1, %{mark: false})` renders zero `<img>` elements but still renders `PUKLLAY CLUB`.
    - Test 2: `render_component(&Layouts.brand_logo/1, %{mark: false, tagline: "Conectá jugando"})` still renders the passed tagline, proving `mark` and `tagline` compose.
    - Test 3: rendering `Layouts.app/1`, `.pk-footer-left img` returns zero elements (inverting the current assertion of two).
    - Test 4: rendering `Layouts.app/1`, the `.pk-footer-left` HTML contains neither `isologo-light.png` nor `isologo-dark.png` (inverting the current four-string assertion).
    - Test 5: rendering `Layouts.app/1`, `#app-header img` still returns exactly two elements — this is what makes "header-only" executable rather than "removed from both surfaces".
    - Test 6: `render_component(&Layouts.brand_logo/1, %{mark: false})` emits the `pk-brand-quiet` class, and `%{}` (the header default) does not.
  </behavior>
  <reversibility rating="reversible">D-A relocates a rendered image between two surfaces; reverting is a one-line change at the footer call site plus the paired test inversions.</reversibility>
  <action>
Component (`brand_logo/1` in `layouts.ex`):

Add a declared `attr :mark, :boolean, default: true` beside the existing `attr :tagline`. Unlike
the `isologo?` seam directly below it, `mark` IS a real declared attr with a production call site,
so it belongs in the attr list rather than in the `assign_new/3` seam — do not conflate the two.

Change the `:if` guard on both `<img>` elements from `{@isologo?}` to `{@isologo? and @mark}`. The
compile-time `@isologo?` gate stays in front as an AND, not a replacement: it is the 260821-v7q
contract that a missing mark file degrades to wordmark-only rather than a half-rendered pair, and
that contract must survive this change.

Add the class `pk-brand-quiet` to the anchor when `mark` is false, using the existing list-class
form (`class={["flex-initial flex w-fit items-center gap-2 min-h-11", !@mark && "pk-brand-quiet"]}`)
so the header's class string is unchanged when `mark` is true.

Add the class `pk-brand-name` to the wordmark's first inner `<span>` (the one carrying
`font-display text-2xl uppercase tracking-wide`), keeping every existing utility on it. This gives
the CSS a named hook instead of a positional `:first-child` selector, matching how
`.pk-brand-wordmark` is already targeted.

Update `brand_logo/1`'s `@doc` to state the new contract: the mark is the header's, the footer
renders the lockup without it (D-A), and the `mark` attr is what selects between them. Update the
`footer/1` comment block above the call site the same way — its current text describes only the
tagline override.

Footer call site: `<.brand_logo tagline="Conectá jugando" mark={false} />`. Leave the header call
site (`<.brand_logo />` inside `header_inner/1`) byte-unchanged so it keeps the `true` default.

CSS (`assets/css/app.css`, inside the `PK CATALOG SURFACES` block): add one rule immediately after
the existing `.pk-nav-inner .pk-brand-wordmark` block, so the two brand-scoping rules sit together
and read as a pair:

`.pk-brand-quiet .pk-brand-name { color: var(--color-neutral); }`

with a short comment recording D-B — colour is the demotion lever because the measured type
inventory is at its 3-tier cap and a smaller Bebas size would add a 4th combo. This rule is
correctly a scoped override rather than a shared class: the two surfaces are meant to differ here,
which is exactly the case the header-scoped `.pk-nav-inner .pk-brand-wordmark` rule above already
sets precedent for. Do not touch `.pk-nav-inner .pk-brand-wordmark` or the 48rem reveal block.

Tests (`layouts_test.exs`) — these two existing tests currently assert the opposite of the new
contract and must be **inverted and renamed, never deleted**:

- `"both marks also render inside the footer's .pk-footer-left cluster"` (in the
  `describe "brand_logo/1 theme-aware isologo pair (260821-v7q)"` block): change
  `assert Enum.count(footer_left_imgs) == 2` to `assert Enum.empty?(footer_left_imgs)` and rename
  the test to state that the footer cluster renders no mark.
- `"the footer's left cluster renders both theme marks with their dark: variant classes"` (in the
  `describe "app/1 footer left cluster tagline (260821-umm)"` block): convert its four `assert`
  lines into `refute` on the two filename strings, drop the two now-meaningless class-string
  assertions, and rename the test accordingly.

Everything else in those two `describe` blocks calls `brand_logo/1` with `%{}` or exercises the
header, so it keeps passing on the `mark: true` default — leave those tests untouched, including
the `File.exists?/1` gate-truthfulness test and the `isologo?: false` fallback test.

Then add the six `<behavior>` assertions as new tests. Put Tests 1, 2 and 6 in a new
`describe "brand_logo/1 mark attr (260823-snj)"` block and Tests 3, 4 and 5 alongside the inverted
footer tests, so each assertion sits with the contract it belongs to.

Docs (`.claude/skills/ui-design-system/SKILL.md`): update the `Layouts` / `brand_logo/1` row of the
component inventory table. It currently documents the isologo pair as unconditional; it must now
document the `mark` attr, its `true` default, and that the footer is the one call site passing
`false`. Leave the surrounding rows and the rest of the table alone.
  </action>
  <verify>
    <automated>mix test test/pukllay_club_web/components/layouts_test.exs</automated>
    <automated>awk '/^\.pk-brand-quiet \.pk-brand-name \{$/,/^\}$/' assets/css/app.css | grep -c 'var(--color-neutral)'</automated>
    <automated>grep -cE 'brand_logo/1.*mark' .claude/skills/ui-design-system/SKILL.md</automated>
  </verify>
  <done>
The layouts suite passes with the two inverted tests and six new tests green — Tests 3/4 (zero marks
in `.pk-footer-left`) and Test 5 (exactly two marks in `#app-header`) together are the authoritative
proof of D-A, which is why no text-count gate on the call site is used here: the `@doc` and the
`footer/1` comment this task also updates would both legitimately mention the attr and make any such
count unreliable. The `awk`-scoped grep returns exactly `1`, proving the `.pk-brand-quiet
.pk-brand-name` rule exists and resolves through the neutral theme token rather than a literal
colour. The skill's component-inventory row for `brand_logo/1` mentions the new attr.
  </done>
</task>

<task type="auto">
  <name>Task 3: Full quality gate and desktop visual confirmation</name>
  <files>assets/css/app.css, lib/pukllay_club_web/components/layouts.ex</files>
  <precondition>A dev server is reachable at http://localhost:4000 (start it with `mix phx.server` if it is not already running).</precondition>
  <read_first>
    - `.claude/skills/ux-responsive/SKILL.md` — the repo's real breakpoint values, to confirm which widths the visual check must cover.
  </read_first>
  <action>
Run the project's full `mix quality` alias (7 steps: `hex.audit`, `deps.audit`,
`deps.unlock --check-unused`, `format --check-formatted`, `credo --strict`, `sobelow`, `test`).
`format --check-formatted` is Styler-augmented — if it rewrites anything in `layouts.ex`, review the
`git diff` hunk by hunk before accepting it rather than trusting the rewrite (AGENTS.md / the Styler
caveat in CLAUDE.md).

Then confirm visually at the three widths the CSS comments identify as this header's real seams,
loading `/` (catalogue, sticky header with the search slot) at each:

- **1440px** — the desktop case the developer raised. The search control must read as a bordered,
  filled circular button, not a floating glyph. Hover it: border and glyph both go primary. Tab to
  it: the same primary treatment appears without a pointer. Click it: it still morphs open to the
  17.5rem pill with the input focused.
- **768px** — the wordmark-reveal breakpoint. Brand mark plus wordmark plus nav links plus the
  resting search button must sit on one line with no horizontal scrollbar, and the header must be
  the same height it was before this change.
- **481px** — the width the two most recent debug sessions were opened against. No horizontal
  overflow anywhere on the page; the header wordmark is hidden and the mark alone carries the brand
  (D-A's reason for keeping the mark in the header).

At every width, scroll to the footer and confirm the page now shows exactly one isologo mark in
total, and that the footer's `PUKLLAY CLUB` wordmark sits in the muted colour tier rather than
matching the header's contrast. Repeat the 1440px pass once in dark theme via the footer theme
toggle, to confirm the `base-100` pill is still legible against the `base-200` header bar and that
the footer wordmark's demoted colour has not fallen below readable contrast in the dark palette.
  </action>
  <verify>
    <automated>mix quality</automated>
    <automated>mix compile --warnings-as-errors</automated>
    <human-check>At 1440px, 768px and 481px on `/`: the header search control reads as a bordered filled button and answers both hover and keyboard focus; the header height and single-line layout are unchanged and no horizontal scrollbar appears at any of the three widths; the page shows exactly one isologo mark (in the header) with the footer wordmark visibly quieter than the header's; and the 1440px dark-theme pass keeps both the search pill and the footer wordmark legible.</human-check>
  </verify>
  <done>
`mix quality` exits clean across all seven steps and `mix compile --warnings-as-errors` succeeds.
The human check confirms the two developer-raised complaints are resolved — the search icon reads as
a relevant control at desktop width, and no page renders a duplicated isologo — with no regression to
header height, single-line header layout, or horizontal overflow at 481px or 768px.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| browser -> Phoenix endpoint | Pre-existing. This change adds no new request parameter, form field, or handler — the search form inside `.pk-nav-search` is a caller-owned slot and is not touched by this plan. |
| build toolchain -> `priv/static/assets/css/app.css` | Tailwind/esbuild regenerate the served stylesheet from `assets/css/app.css` during `mix assets.build`. |

No package-manager installs (`npm`/`pip`/`cargo`) occur in this plan, so no `T-*-SC` supply-chain row
and no package-legitimacy checkpoint applies. No new dependency is added to `mix.exs` or `mix.lock`.

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-Q260823-01 | Information Disclosure | `Layouts.brand_logo/1`, `header_inner/1` | low | accept | Every value rendered by the changed markup is a compile-time literal — `tagline` is a static string from two in-repo call sites, `mark` is a boolean, `title="Buscar"` is a literal. No user-controlled data enters the changed markup, so no new injection or disclosure surface is created. |
| T-Q260823-02 | Tampering | `assets/css/app.css` `PK CATALOG SURFACES` block | low | mitigate | Edits are confined to existing rules inside the delimited block plus one appended rule. Task 1's four `awk`-scoped greps assert the `.pk-search-morph` 44px geometry contract is intact, and Task 3's `mix quality` runs Sobelow and Credo `--strict` over the full tree before commit. |
| T-Q260823-03 | Denial of Service | `.CatalogNav` `--pk-header-h` ResizeObserver publisher | low | accept | The icon grows from 16px to 20px inside a button whose `width`/`height` stay pinned at 44px, so the published header height is unchanged and no sticky-offset cascade is triggered. Task 1's geometry greps and Task 3's 768px/481px human check are the two independent confirmations. |
| T-Q260823-04 | Spoofing | brand identity surfaces (header/footer lockups) | low | accept | Removing the duplicate mark reduces, rather than expands, the number of places the brand is asserted; the remaining mark is served from `priv/static/images/` over the app's own origin, unchanged from 260821-v7q. |
</threat_model>

<verification>
- `mix quality` passes all seven steps.
- `mix compile --warnings-as-errors` succeeds.
- `mix test test/pukllay_club_web/components/layouts_test.exs` passes, including the two inverted
  footer-mark tests and the nine new tests added across Tasks 1 and 2.
- The four `awk`-scoped greps against the `.pk-search-morph` rule body each return `1`.
- `grep -cE '\.hero-magnifying-glass[^a-z-]' priv/static/assets/css/app.css` returns at least `1`
  after `mix assets.build`.
- `grep -c 'mark={false}' lib/pukllay_club_web/components/layouts.ex` returns exactly `1`.
- Human confirmation at 1440px / 768px / 481px in both themes, per Task 3.
</verification>

<success_criteria>
- The desktop header's search control renders as a 44px circular button with a visible border and a
  `base-100` fill, holding a 20px `hero-magnifying-glass` icon at `base-content` contrast.
- Hover and keyboard focus both drive the pill's border and glyph to `primary`; neither state is
  reachable only by pointer.
- The header's resting geometry is byte-identical at 44px x 44px, so `--pk-header-h` is unchanged and
  no horizontal scrollbar appears at 481px or 768px.
- A rendered page carries exactly two `<img>` marks inside `#app-header` and zero inside
  `.pk-footer-left`.
- The footer's `PUKLLAY CLUB` wordmark renders at the same Bebas 24px size in the muted colour tier,
  adding no new combination to the measured type inventory.
- `brand_logo/1` with `mark: false` renders no `<img>` while still rendering the wordmark and the
  passed tagline; with the default `mark: true` its output is unchanged from before this plan.
- The `ui-design-system` skill's `brand_logo/1` inventory row documents the `mark` attr.
</success_criteria>

<output>
Create `.planning/quick/260823-snj-polish-desktop-header-improve-the-search/260823-snj-SUMMARY.md` when done.
</output>
