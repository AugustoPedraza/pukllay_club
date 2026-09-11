---
phase: quick-260910-dev
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/sketches/054-dark-mode-color-composition/index.html
  - .planning/sketches/054-dark-mode-color-composition/contrast-check.mjs
  - .planning/sketches/054-dark-mode-color-composition/README.md
  - .planning/sketches/MANIFEST.md
autonomous: false
requirements: [QUICK-260910-DEV]
user_setup: []

estimate:
  tokens: 70000
  raw_tokens: 35000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "Opening .planning/sketches/054-dark-mode-color-composition/index.html shows the SAME composed mini-screen rendered 5 times side by side — one control frame carrying today's shipped dark palette verbatim, plus 4 distinct dark-palette proposals — so only the color composition differs between frames."
    - "Each of the 4 proposals answers 'why does dark mode read as too dark' with a DIFFERENT hypothesis (base ladder lifted / surface elevation re-spaced / base chroma reduced / ink+accent softened), not four arbitrary shades of the same idea."
    - "Every frame displays its own live-computed WCAG contrast readout (text-on-bg, muted-on-bg, text-on-surface, primary-content-on-primary) so the palette is judged on measured contrast, not by eye."
    - "Every one of the 5 frames declares all 13 mapped color tokens explicitly on its own frame element — no frame silently inherits a value from themes/default.css, so what is being compared is unambiguous."
    - "assets/css/app.css and .planning/sketches/themes/default.css are byte-identical to their pre-task state — this task ships NO production or shared-theme color change, only a throwaway sketch."
    - "The developer picks one winning frame (or directs a refinement round) at the decision checkpoint, and that choice is recorded in the sketch README's winner field and in the MANIFEST row."
  artifacts:
    - ".planning/sketches/054-dark-mode-color-composition/index.html — 5-frame dark-palette comparison over one real composed substrate, with per-frame token overrides and a live contrast readout"
    - ".planning/sketches/054-dark-mode-color-composition/contrast-check.mjs — zero-dependency Node oracle asserting per-variant token completeness, WCAG floors, and non-no-op distinctness"
    - ".planning/sketches/054-dark-mode-color-composition/README.md — frontmatter (sketch/name/question/winner/tags) + design question, variant rationale, how-to-view, what-to-look-for"
    - ".planning/sketches/MANIFEST.md — one appended row for sketch 054 recording the question and the chosen winner"
  key_links:
    - "Each frame element's own custom-property declarations shadow themes/default.css's :root dark values for that frame's subtree via normal custom-property inheritance (nearest declaring ancestor wins) — this is why per-frame overrides work WITHOUT editing the shared theme file and WITHOUT any specificity battle."
    - "contrast-check.mjs parses the per-frame token blocks straight out of index.html (single source) — the sketch's on-screen readout and the CLI oracle therefore cannot disagree about what a variant's values are."
    - "The winner picked at the decision checkpoint is the ONLY input to a future, separate quick task that edits assets/css/app.css's daisyUI dark theme block — that edit is explicitly out of scope here."
---

<objective>
The shipped dark theme reads as too dark. Before changing a single production token, explore and
validate the right dark-mode color composition as a throwaway HTML sketch, following this repo's
established `.planning/sketches/NNN-slug/` convention (53 prior sketches, MANIFEST-indexed).

Today's shipped dark palette (`assets/css/app.css`, the `name: "dark"` daisyUI theme block) sits
at `--color-base-100: #170A26` — a near-black purple at roughly 13% lightness — with
`--color-base-content: #F3ECFA` near-white on top of it. Two independent things can produce the
"too dark" complaint from those numbers: a ground that is simply too low, and a
near-black-to-near-white blowout with a barely-separated 3-step surface ladder
(`#170A26` / `#22103A` / `#2F1750`) that gives no readable sense of elevation. This sketch tests
both readings, plus chroma and accent-presence readings, against the same real composed screen.

Purpose: give the developer 5 directly comparable renderings of the SAME screen so the winning
palette is chosen on evidence, then hand that winner to a follow-up implementation task.
Output: sketch 054 (index.html + contrast oracle + README) and one MANIFEST row. No production
CSS, no `.heex`, no Tailwind/daisyUI config — those belong to the follow-up task, not this one.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md

Grounding already done during planning — do NOT re-derive these, they are current as of this plan:

**Shipped dark palette** (`assets/css/app.css`, `@plugin ".../daisyui-theme"` block with
`name: "dark"`, roughly lines 139-172). Read that block once to confirm, then work from it:

| daisyUI token | value |
|---|---|
| `--color-base-100` | `#170A26` |
| `--color-base-200` | `#22103A` |
| `--color-base-300` | `#2F1750` |
| `--color-base-content` | `#F3ECFA` |
| `--color-primary` | `#A97FD1` |
| `--color-primary-content` | `#170A26` |
| `--color-secondary` | `#7E4CA5` |
| `--color-accent` | `#3D2A56` |
| `--color-accent-content` | `#E4D3F5` |
| `--color-neutral` | `#B8A6CC` |
| `--color-error` | `#E06B90` |
| `--color-success` | `#5FBE95` |

**Sketch-side token names.** `.planning/sketches/themes/default.css` mirrors those daisyUI tokens
under sketch-local names. The mapping (documented in that file's own header comment) is:
`base-100 -> --color-bg`, `base-200 -> --color-surface`,
`base-300 -> --color-surface-2` AND `--color-border` (feeds both),
`base-content -> --color-text`, `neutral -> --color-text-muted`,
`primary -> --color-primary`, `primary-content -> --color-primary-content`,
`secondary -> --color-secondary`, `accent -> --color-accent-bg`,
`accent-content -> --color-accent-text`, `error -> --color-danger`, `success -> --color-success`.
That is the 13-token set this sketch varies.

@.planning/sketches/themes/default.css
@.planning/sketches/053-about-mobile-cta-bar-footer-clearance/README.md

Read for the composed-substrate markup idiom (header / shelf / card / band / footer classes and
the standard bottom-right sketch toolbar with its theme selector) — take the shape, do not copy
the whole file:

@.planning/sketches/007-composed-catalog-page/index.html
</context>

<tasks>

<task type="tracer">
  <name>Task 1: Build sketch 054 — 5 dark palettes over one real composed screen</name>
  <files>.planning/sketches/054-dark-mode-color-composition/index.html, .planning/sketches/054-dark-mode-color-composition/contrast-check.mjs</files>
  <precondition>Node is available on PATH (`node --version` succeeds) — the contrast oracle is a zero-dependency `.mjs` script run directly by Node, matching this repo's existing `test/visual/*.mjs` idiom.</precondition>
  <action>
Invoke the `gsd-sketch` skill via the Skill tool FIRST and follow its mechanics for directory
naming, file layout and numbering. This is sketch **054**, slug
`054-dark-mode-color-composition` (053 is the highest existing number). Also invoke
`sketch-findings-pukllay_club` so the substrate reuses already-validated component decisions
instead of inventing new visual language.

Build `index.html` as a single page containing **5 frames of the identical composed screen**,
differing ONLY in their 13 color tokens. Link `../themes/default.css` and force the page into dark
mode by setting `data-theme="dark"` on the document element (keep the standard bottom-right sketch
toolbar with its theme selector so the light theme can still be spot-checked — light mode is NOT
under revision here, it is a sanity control).

**Frame mechanism (this is the load-bearing detail).** Give each frame a root element carrying
`data-variant` (`control`, `a`, `b`, `c`, `d`) and declare that frame's full 13-token set on that
element inside the sketch's OWN `<style>` block, e.g. a rule selecting
`.pk-sk-frame[data-variant="a"]`. Custom properties inherit from the nearest declaring ancestor,
so a frame's own declarations shadow `themes/default.css`'s `:root[data-theme="dark"]` values for
everything inside that frame — no specificity battle, no shared-file edit. Every frame declares
all 13 tokens explicitly, including `control`, which restates today's shipped values verbatim.

**HARD SCOPE GUARD:** do not modify `.planning/sketches/themes/default.css` — it is shared by all
53 prior sketches and is gated against `assets/css/app.css` by
`.planning/sketches/themes/check-theme-drift.sh`. Do not modify `assets/css/app.css`,
any `.heex`, or any Tailwind/daisyUI config. This plan produces sketch files only.

**The substrate**, rendered identically in all 5 frames. Mobile-first: size the frame to a phone
viewport (~360-390px wide) as the primary comparison, then place the 5 phone frames in a row that
wraps. Build it once as a template (a JS template string cloned into each frame, or one
`<template>` element stamped 5 times) so the markup provably cannot drift between frames. It must
contain every surface class of color actually used by the app:

- a header strip on the surface token (this is `base-200` in production),
- a real photograph — use `../../../priv/static/images/about-juego.jpg` (the same relative-path-
  to-repo-root idiom `themes/default.css` already uses for its self-hosted font), identical in
  every frame, because real image mass is a large part of whether a dark UI reads as too dark,
- a shelf title plus two game cards using the existing card idiom (gradient poster placeholder as
  the composed sketches already do, title, a weight badge, one chip),
- a content band on the accent tokens,
- a primary CTA button plus one muted/secondary text line (exercises
  `--color-primary` / `--color-primary-content` / `--color-text-muted`),
- a footer strip on the surface token.

**The 5 palettes.** Each proposal is a distinct hypothesis about WHY dark mode reads as too dark.
Derive concrete hex values yourself and label each frame on screen with its name plus a one-line
statement of its hypothesis:

- **Control — "Hoy"**: today's shipped values verbatim, reproduced solely for direct comparison
  (this is the same precedent sketch 053 set with its rejected-shipped-state frame).
- **A — Lifted Ladder**: the ground is simply too low. Raise all three base steps together,
  preserving the current hue, chroma relationship and relative step spacing.
- **B — Elevated Surfaces**: the ground is fine, the ladder is flat. Keep `--color-bg` near
  today's and widen/re-space the surface steps so header, card and footer read as clearly
  elevated above the page.
- **C — Quieter Ground**: the bases are too chromatic, reading heavy/muddy. Pull chroma out of
  the three bases toward a near-neutral charcoal that keeps only a hint of the brand purple, so
  the purple accents read louder against a calmer ground.
- **D — Softened Ink**: the ground is fine, the blowout is the problem. Keep the bases, step the
  text down from near-white and lift the muted and accent tokens so hierarchy is carried by
  several readable levels instead of one maximal-contrast jump.

**Per-frame contrast readout.** Each frame renders its own live-computed WCAG contrast ratios
(read from `getComputedStyle`, not hardcoded): text-on-bg, muted-on-bg, text-on-surface, and
primary-content-on-primary — each shown with its ratio and a pass/fail marker against 4.5:1. Also
show each frame's `--color-bg` relative luminance so "how much lighter is this really" is a number
on screen, not a feeling. This repo consistently measures rather than eyeballs (see
`test/visual/about_geometry.mjs` and `check-theme-drift.sh`); keep that discipline here.

**`contrast-check.mjs`** — a zero-dependency Node script in the same sketch directory that parses
the per-frame token blocks straight out of `index.html` (so the CLI and the on-screen readout can
never disagree about a variant's values) and exits non-zero unless ALL of the following hold:
its own count of variant blocks is exactly 5; each block declares all 13 mapped tokens; for every
block the four ratios above are at least 4.5:1; and each of the 4 proposals differs from the
control in at least one base token, so no proposal is a silent no-op. Print a per-variant table of
ratios and `--color-bg` luminance on success.
  </action>
  <verify>
    <automated>node .planning/sketches/054-dark-mode-color-composition/contrast-check.mjs && git diff --quiet -- assets/css/app.css .planning/sketches/themes/ && echo SCOPE-CLEAN</automated>
    <human-check>Open the sketch and confirm the 5 phone frames render the same screen with visibly different grounds, and that the photograph is present in every frame.</human-check>
  </verify>
  <done>`contrast-check.mjs` exits 0 reporting 5 variants x 13 tokens with every ratio at or above 4.5:1 and every proposal distinct from the control; `git diff --quiet` confirms `assets/css/app.css` and `.planning/sketches/themes/` are untouched; the sketch opens with 5 identical composed phone screens differing only in palette.</done>
</task>

<task type="checkpoint:decision">
  <name>Task 2: Developer picks the winning dark palette</name>
  <decision>Which dark-mode color composition wins — and therefore which 13 token values the follow-up implementation task will write into `assets/css/app.css`'s daisyUI dark theme block?</decision>
  <options>
    - **Control ("Hoy")** — today's shipped palette stands; the "too dark" complaint is not a palette problem and this thread closes here.
    - **A — Lifted Ladder** — the ground is too low; raise all three base steps together, hue/chroma relationships and step spacing preserved.
    - **B — Elevated Surfaces** — the ground is fine, the ladder is flat; keep `--color-bg` near today's and widen the surface steps so header/card/footer read as elevated.
    - **C — Quieter Ground** — the bases are too chromatic and read heavy; pull chroma toward a near-neutral charcoal so the purple accents carry the brand instead of the background.
    - **D — Softened Ink** — the ground is fine, the near-black-to-near-white blowout is the problem; step the text down and lift muted/accent so hierarchy has several readable levels.
    - **A named synthesis** — e.g. A's ladder with D's softened ink; recorded as a named refined winner the way sketch 053's winner was recorded as "D (refined)".
    - **Another round** — none convince; the developer directs new variants, `index.html` is iterated in place, the oracle is re-run, and this checkpoint repeats.
  </options>
  <action>
Present the sketch for a decision. Tell the developer exactly how to open it:

```
open .planning/sketches/054-dark-mode-color-composition/index.html
```

(File-protocol previews are blocked in some browser setups — if it opens blank, serve
`.planning/sketches/` with any static file server and open it over `http://`, the same note every
prior sketch README carries.)

Summarize the 4 hypotheses in one line each, paste the `contrast-check.mjs` ratio table so the
measured numbers are in front of the developer alongside the visual, and ask which frame wins.

Valid outcomes: (1) one variant wins outright; (2) a synthesis wins (e.g. A's ladder with D's
softened ink) — record it as a named refined winner, the same way sketch 053's winner was recorded
as "D (refined)"; (3) none convince and the developer directs another round of variants — in that
case iterate `index.html` in place, re-run the oracle, and return here. Rounds are normal in this
repo's sketch history (sketch 008 ran 8, sketch 011 ran 9); do not force a decision.

Do NOT begin editing production CSS after the pick. Implementing the winner in
`assets/css/app.css` (and re-syncing `themes/default.css` via `check-theme-drift.sh`) is a
SEPARATE follow-up quick task, deliberately out of this plan's scope.
  </action>
  <resume-signal>The developer names a winning frame, names a synthesis, or directs another round. On a win or a synthesis, proceed to Task 3 carrying the answer verbatim. On another round, return to Task 1's `index.html`, iterate the variants, re-run `contrast-check.mjs`, and re-present this checkpoint.</resume-signal>
  <done>The developer has named a winning frame or a named synthesis, and that answer is captured verbatim for Task 3.</done>
</task>

<task type="auto">
  <name>Task 3: Record findings — sketch README + MANIFEST row</name>
  <files>.planning/sketches/054-dark-mode-color-composition/README.md, .planning/sketches/MANIFEST.md</files>
  <action>
Write `README.md` in the sketch directory following the exact shape of
`053-about-mobile-cta-bar-footer-clearance/README.md`: YAML frontmatter with `sketch: 054`,
`name: dark-mode-color-composition`, a `question:` stating the design question, a `winner:` line
carrying the developer's verbatim choice from Task 2, and
`tags: [dark-mode, color, palette, theme, contrast, accessibility]`. Then the prose sections that
file uses: Design Question, Winner (with WHY it won, including any refinement rounds), How to View
(with the file-protocol caveat), and What to Look For.

Record the winner's actual 13 token values as a table in the README — that table is the input the
follow-up implementation task will consume, so it must be complete enough to act on without
re-opening the sketch. Note explicitly that light mode was not revised.

Append one row to `.planning/sketches/MANIFEST.md`'s table matching the existing column shape
(number, slug, question, winner, tags). Follow the file's existing convention of stating the
question as a real question and the winner with its parenthetical rationale.

Leave the losing variants in `index.html` if the developer wants them for the record, or trim to
the winner if the developer prefers — sketch 053 trimmed to the winner and preserved the rejected
directions in prose; either is acceptable, state which you did in the README.

Commit sketch files and the MANIFEST row together in one commit. Do not stage anything under
`assets/`.
  </action>
  <verify>
    <automated>test -f .planning/sketches/054-dark-mode-color-composition/README.md && head -8 .planning/sketches/054-dark-mode-color-composition/README.md | grep -q '^winner:' && grep -q '054' .planning/sketches/MANIFEST.md && git diff --quiet HEAD -- assets/ .planning/sketches/themes/ && echo FINDINGS-RECORDED</automated>
  </verify>
  <done>`README.md` carries frontmatter with a non-placeholder `winner:` and the winner's full 13-token table; `MANIFEST.md` has a row for 054; the commit contains only sketch files, with `assets/` and the shared theme untouched.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| sketch -> production CSS | A sketch that edits shared or production stylesheets escapes its throwaway scope and silently changes the live app |
| sketch -> repo filesystem | The sketch loads a repo-relative image and font via `../../../` paths, reaching outside the sketch directory |
| palette change -> accessibility contract | Lifting a dark ground can quietly drop text contrast below the WCAG floors recorded in `app.css`'s measured-constraints comment |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-quick-260910-dev-01 | Tampering | `.planning/sketches/themes/default.css` | high | mitigate | Explicit hard scope guard in Task 1 plus a `git diff --quiet -- assets/css/app.css .planning/sketches/themes/` gate in both automated verify steps — the shared theme feeds all 53 prior sketches and is drift-checked against production |
| T-quick-260910-dev-02 | Tampering | `assets/css/app.css` daisyUI dark theme block | high | mitigate | Same `git diff --quiet` gate; implementing the winner is explicitly deferred to a separate follow-up task, stated in Task 2's action and the README |
| T-quick-260910-dev-03 | Information Disclosure | end users of the shipped dark theme | medium | mitigate | `contrast-check.mjs` fails the task unless every variant holds text-on-bg, muted-on-bg, text-on-surface and primary-content-on-primary at or above 4.5:1 — no variant can reach the decision checkpoint carrying an unreadable pair |
| T-quick-260910-dev-04 | Repudiation | palette decision provenance | low | mitigate | The winner and its full 13-token values are recorded in the sketch README frontmatter plus a MANIFEST row, matching the 53-sketch audit trail already in the repo |
| T-quick-260910-dev-SC | Tampering | npm/pip/cargo installs | high | accept | No package installs in this plan — `contrast-check.mjs` is zero-dependency Node, matching the existing `test/visual/*.mjs` idiom, so the package-legitimacy seam is never crossed |
</threat_model>

<verification>
- `node .planning/sketches/054-dark-mode-color-composition/contrast-check.mjs` exits 0 and prints a 5-row table.
- `git diff --quiet -- assets/css/app.css .planning/sketches/themes/` exits 0 at every task boundary.
- `.planning/sketches/themes/check-theme-drift.sh` still exits 0 (unchanged inputs — run it once as a regression backstop).
- The sketch opens and renders 5 phone-width frames of the same composed screen.
- `MANIFEST.md` gained exactly one row.
</verification>

<success_criteria>
- 5 directly comparable dark-mode palettes exist as a throwaway sketch, each declaring its full
  13-token set and each backed by a stated hypothesis about the "too dark" complaint.
- Every variant is measured, not eyeballed: on-screen WCAG readout plus a CLI oracle that gates on
  a 4.5:1 floor and on each proposal being genuinely distinct from the control.
- The developer has picked a winner (or directed further rounds), and that pick is recorded in the
  README frontmatter, the README's token table, and one MANIFEST row.
- Zero production files changed: no `.heex`, no `assets/css/app.css`, no Tailwind/daisyUI config,
  no `.planning/sketches/themes/default.css`.
</success_criteria>

<output>
Create `.planning/quick/260910-dev-mejorar-arreglar-la-composici-n-de-color/260910-dev-SUMMARY.md` when done.

The SUMMARY must carry the winning palette's 13 token values verbatim, since the follow-up
implementation task (editing `assets/css/app.css`'s dark theme block, then re-syncing
`themes/default.css` and re-running `check-theme-drift.sh`) reads them from there.
</output>
