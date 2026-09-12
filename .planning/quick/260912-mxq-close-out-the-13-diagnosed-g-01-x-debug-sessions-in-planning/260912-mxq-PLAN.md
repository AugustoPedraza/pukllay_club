---
phase: quick-260912-mxq
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
files_modified:
  - .planning/debug/G-01-2-badge-title-overlap.md
  - .planning/debug/G-01-3-catalog-grid-overflow.md
  - .planning/debug/G-01-4-carousel-affordance.md
  - .planning/debug/G-01-4-section-hierarchy.md
  - .planning/debug/G-01-5-expansions-in-recent.md
  - .planning/debug/G-01-6-card-info-density.md
  - .planning/debug/G-01-7-double-focus-ring.md
  - .planning/debug/G-01.4-1-isologo-morph-blink.md
  - .planning/debug/G-01.4-2-map-thumb-coverage.md
  - .planning/debug/G-01.5-4-hero-cierre-composition-balance.md
  - .planning/debug/G-01.5-5-cierre-footer-gap.md
  - .planning/debug/G-01.5-6-cierre-top-bottom-whitespace.md
  - .planning/debug/G-01.5-7-cta-bar-background-visible.md
  - .planning/debug/resolved/G-01-2-badge-title-overlap.md
  - .planning/debug/resolved/G-01-3-catalog-grid-overflow.md
  - .planning/debug/resolved/G-01-4-carousel-affordance.md
  - .planning/debug/resolved/G-01-4-section-hierarchy.md
  - .planning/debug/resolved/G-01-5-expansions-in-recent.md
  - .planning/debug/resolved/G-01-6-card-info-density.md
  - .planning/debug/resolved/G-01-7-double-focus-ring.md
  - .planning/debug/resolved/G-01.4-1-isologo-morph-blink.md
  - .planning/debug/resolved/G-01.4-2-map-thumb-coverage.md
  - .planning/debug/resolved/G-01.5-4-hero-cierre-composition-balance.md
  - .planning/debug/resolved/G-01.5-5-cierre-footer-gap.md
  - .planning/debug/resolved/G-01.5-6-cierre-top-bottom-whitespace.md
  - .planning/debug/resolved/G-01.5-7-cta-bar-background-visible.md
files_deleted:
  - .planning/debug/G-01-2-badge-title-overlap.md
  - .planning/debug/G-01-3-catalog-grid-overflow.md
  - .planning/debug/G-01-4-carousel-affordance.md
  - .planning/debug/G-01-4-section-hierarchy.md
  - .planning/debug/G-01-5-expansions-in-recent.md
  - .planning/debug/G-01-6-card-info-density.md
  - .planning/debug/G-01-7-double-focus-ring.md
  - .planning/debug/G-01.4-1-isologo-morph-blink.md
  - .planning/debug/G-01.4-2-map-thumb-coverage.md
  - .planning/debug/G-01.5-4-hero-cierre-composition-balance.md
  - .planning/debug/G-01.5-5-cierre-footer-gap.md
  - .planning/debug/G-01.5-6-cierre-top-bottom-whitespace.md
  - .planning/debug/G-01.5-7-cta-bar-background-visible.md

must_haves:
  truths:
    - "Every one of the 13 G-01.x debug sessions ends in exactly one of two states: moved to .planning/debug/resolved/ with status resolved, or left byte-identical at .planning/debug/ with status diagnosed"
    - "No session is marked resolved without current-code file:line evidence that its recorded root cause no longer holds, plus the gap-closure plan id that landed the fix"
    - "The recorded root_cause text of every resolved session is preserved verbatim; only status, updated, fix, verification and files_changed change"
    - "Zero files under lib/, assets/, test/, config/ or priv/ are modified by this item"
    - "Every session that stays diagnosed is reported in the SUMMARY with the cause that still holds and its current file:line"
  artifacts:
    - path: ".planning/debug/resolved/"
      provides: "Destination for closed G-01.x debug sessions, matching the existing resolved/ file shape"
  key_links:
    - from: "each resolved debug file's fix field"
      to: "the gap-closure PLAN/SUMMARY under .planning/milestones/v1.0-phases/ and its git commit"
      via: "plan id + commit sha cited in the fix string"
      pattern: "plan 01(\\.[0-9])?-[0-9]{2}"
---

<objective>
Close out the 13 G-01.x debug sessions in `.planning/debug/` that were produced by diagnose-only
runs (goal: find_root_cause_only), handed to `/gsd-plan-phase --gaps`, fixed by downstream
gap-closure plans, and never flipped from `status: diagnosed`.

For each session: verify the recorded `root_cause` against the CURRENT code. If the root cause is
gone, fill `fix` / `verification` / `files_changed`, set `status: resolved`, and `git mv` the file
into `.planning/debug/resolved/`. If the root cause still holds (or cannot be proven gone), leave
the file completely untouched and report it.

Purpose: `.planning/debug/` should list only genuinely open investigations; 13 stale "diagnosed"
entries hide the real open ones (sibling batch item 260912-mxr handles the other 6).
Output: up to 13 renamed+edited debug files under `.planning/debug/resolved/`, plus a SUMMARY
listing every decision with its evidence.

Bookkeeping only. No application code changes.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md

Resolved-shape exemplars (read the frontmatter + `## Resolution` section of each, nothing else):
@.planning/debug/resolved/G-01.5-8-cierre-tagline-footer-grouping.md
@.planning/debug/resolved/G-01.4-3-isologo-bottom-spacing.md

Where the closing records live (phases were archived at the v1.0 milestone close — `.planning/phases/`
now holds only 01.7 and 01.8, so search the archive):
- `.planning/milestones/v1.0-phases/01-catalog-v1/` — `01-UAT.md` (Gaps section, `resolved_by`),
  `01-0N-PLAN.md` (`gap_ids:` frontmatter), `01-0N-SUMMARY.md`, `01-VERIFICATION.md`
- `.planning/milestones/v1.0-phases/01.4-ui-polish-pass-for-about-page-sketches/` — `01.4-UAT.md`
  (`resolved_by`), `01.4-0N-PLAN.md`, `01.4-0N-SUMMARY.md`
- `.planning/milestones/v1.0-phases/01.5-about-page-cta-rhythm-header-morph-refinement-implement-sket/`
  — `01.5-UAT.md` (`closed_by`), `01.5-VERIFICATION.md` (live measurements), `01.5-NN-PLAN.md`, `01.5-NN-SUMMARY.md`

Known gap -> closing plan mapping (from `gap_ids:` / UAT `resolved_by` / `closed_by`; these are
LEADS — current code is the proof):
- G-01-2, G-01-6, G-01-7 -> plan 01-07
- G-01-3, G-01-4 (section hierarchy) -> plan 01-08
- G-01-4 carousel affordance -> plan 01-11 (01-UAT.md records the w-full diagnosis as superseded by the pk-rail rework)
- G-01-5 -> plan 01-09
- G-01.4-1 -> plan 01.4-06 (S2 spacing later re-derived again by 01.4-08 for G-01.4-3)
- G-01.4-2 -> plan 01.4-07 (commit 3238c3d), with the thumbnail itself later reworked by 01.4-09 (G-01.4-4) and 01.4-11/01.4-12 (live Maps embed, G-01.4-5)
- G-01.5-5, G-01.5-6 -> plan 01.5-09
- G-01.5-4, G-01.5-7 -> plan 01.5-10 (G-01.5-7 fix commit e42d713)

Git caveat: Phases 00 through 01.1 reached origin via squash-sync commit 320fc4b (PR #28), so
`git log --grep "(01-07)"` may return only that squash. Fall back to
`git log --oneline -S '<distinctive token the fix introduced>' -- <file>` and cite whatever sha
first introduced the token.

Baseline commit for untouched-file and root_cause-preservation checks:
bd3592c292bdd4aa9e697c7360b45a69169f7836 (HEAD of chore/planning-cleanup-260912 at planning time).

<closure_protocol>
Apply these steps to EVERY debug file, one file at a time, completing all steps for a file before
starting the next.

Step 1 — Enumerate the causes. Read the file's `## Resolution` `root_cause` in full. List each
distinct cause/mechanism it names, and record whether the causes are AND-gated (the defect lives in
their conjunction — breaking one removes it) or independent (each separately sufficient for its own
symptom). The files state this explicitly in most cases ("AND-gate", "THREE INDEPENDENT", "jointly
contributing").

Step 2 — Find the closing record. Grep the gap id (e.g. `G-01.5-6`) in the archived phase dir's
UAT, PLAN `gap_ids`, and SUMMARY files listed in context. Then find the commit(s): try
`git log --oneline --grep "(<plan-id>)"` first, then the `-S` fallback from the git caveat.
Capture plan id(s) and commit sha(s). If no closing plan or commit can be found, the file STAYS
DIAGNOSED (Step 6).

Step 3 — Verify against CURRENT code. For each cause, grep / Read the current working tree.
Recorded line numbers have drifted heavily (assets/css/app.css has grown by thousands of lines since
some of these diagnoses) — locate each mechanism by selector, function name, attribute, or class
token, never by the old line number. Record the current `path:line` for each piece of evidence,
including zero-hit greps when a mechanism was removed (cite the command and "0 hits"). Evidence is
static only: grep, Read, `git show`, `git log`. Do not start a dev server or run mix. Where a
root_cause quantity can only be measured in a live render (pixel geometry, contrast ratios), cite
the static CSS/markup evidence AND the closing plan's live-verification line (e.g. the
`01.5-VERIFICATION.md` or UAT `closed_by` line with its measured numbers).

Step 4 — Decide.
- RESOLVED when: (a) independent causes — every one is absent or neutralized in current code;
  (b) AND-gated causes — the half the closing plan targeted is gone so the conjunction no longer
  exists (a half that the diagnosis itself said must be preserved, e.g. a closed D-14 tint, is
  expected to still be present and does not block resolution); (c) the code the root cause lives in
  was replaced or removed entirely, proven by a zero-hit grep plus the replacing plan/commit;
  (d) the root cause locates the mechanism in upstream library behaviour (daisyUI compiled CSS) —
  verify the PROJECT-side condition the fix targeted (e.g. the suppression class or the replaced
  component), not the upstream CSS, which is expected to still exist.
- STAYS DIAGNOSED when: any independent cause is still present; the conjunction still holds; no
  closing plan/commit can be found; the evidence is ambiguous; or the mechanism is still present in
  code but the UAT closed the gap by a design decision (report this last case as "mechanism
  present, UAT closed by decision — needs a developer call").
- Never resolve on the strength of a UAT/SUMMARY/commit-message claim alone. Those supply the lead;
  current code supplies the proof. G-01.5-4's and G-01.5-5's own diagnoses document commit dfb1259
  claiming closures its diff did not deliver.

Step 5 — If RESOLVED, edit the file in place, changing ONLY these fields:
- frontmatter `status: diagnosed` -> `status: resolved` (the top-level key on line 2 only; leave any
  nested `audit_acknowledged:` block exactly as-is — it is the historical milestone-audit record);
- frontmatter `updated:` -> today's date in ISO form;
- `fix:` -> ONE line, a double-quoted string that begins with `plan <plan-id>` (for example
  `plan 01.5-09`), names every commit sha found in Step 2, and states in one sentence what changed.
  Use backticks, not inner double quotes, for code tokens. Replace whatever the field held before,
  including multi-line or bracketed diagnosis-era text;
- `verification:` -> a YAML `|` block with one bullet per cause from Step 1: the current
  `path:line` evidence (at least one `.ex`/`.exs`/`.css`/`.js`/`.heex` `path:line` reference is
  required), the grep command and its result, and where available the test/probe name or UAT /
  VERIFICATION line that confirmed it live. Write it as affirmative evidence; do not reuse the
  diagnosis-era placeholder wording that the field held before;
- `files_changed:` -> a non-empty YAML list of repo-relative application files the closing plan(s)
  changed that bear on this root cause (from the SUMMARY key-files list or `git show --stat <sha>`).
Leave everything else byte-identical: `trigger`, `created`, Current Focus, Symptoms, Eliminated,
Evidence, `root_cause`, `suggested_fix_direction`, `## Assets`, and any other section.
Then run `git mv .planning/debug/<name>.md .planning/debug/resolved/<name>.md`.

Step 6 — If STAYS DIAGNOSED, do not edit and do not move the file. Record for the SUMMARY: file
name, which cause still holds, its current `path:line` evidence, the UAT status of that gap, and a
recommended next step (`/gsd-debug` re-investigation or a developer decision).

Step 7 — Scope fences (every step, every file):
- Never modify anything under `lib/`, `assets/`, `test/`, `config/`, `priv/`.
- Never edit or move `.planning/debug/assets/<name>/` directories (prior closures such as
  G-01.5-8 / G-01.5-9 left their assets in place), `.planning/debug/knowledge-base.md`, or any
  debug file not in this item's list of 13 (sibling item 260912-mxr owns cierre-band-whitespace,
  hashtags-not-visible, hero-cta-isologo-balance, inter-band-whitespace-gap,
  lightbox-width-scrim-not-shell-width and no-disconnect-banner — read-only for this item).
- Do not edit UAT, PLAN, SUMMARY or VERIFICATION files in the milestone archive; they are sources
  only.
- When committing each task, include BOTH sides of every rename (the deleted
  `.planning/debug/<name>.md` and the added `.planning/debug/resolved/<name>.md`) so git records the
  move. Commit message form: `docs(260912-mxq): close G-01-x debug sessions` (adjust the group
  label per task).
</closure_protocol>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Close out the seven G-01-* catalog debug sessions (plans 01-07 / 01-08 / 01-09 / 01-11)</name>
  <files>.planning/debug/G-01-2-badge-title-overlap.md, .planning/debug/G-01-3-catalog-grid-overflow.md, .planning/debug/G-01-4-carousel-affordance.md, .planning/debug/G-01-4-section-hierarchy.md, .planning/debug/G-01-5-expansions-in-recent.md, .planning/debug/G-01-6-card-info-density.md, .planning/debug/G-01-7-double-focus-ring.md, and their .planning/debug/resolved/ destinations</files>
  <read_first>
    - The two resolved exemplars named in context (frontmatter + Resolution section only)
    - .planning/milestones/v1.0-phases/01-catalog-v1/01-UAT.md (Gaps section)
    - .planning/milestones/v1.0-phases/01-catalog-v1/01-07-SUMMARY.md, 01-08-SUMMARY.md, 01-09-SUMMARY.md, 01-11-SUMMARY.md
    - Each of the seven debug files' Resolution section
  </read_first>
  <action>
Apply the closure_protocol, Steps 1-7, to each file below. Process G-01-2 first all the way through
Step 5/6 (including the git mv if resolved) so the full edit-and-move loop is proven on one file
before repeating it for the other six. Leads (starting points for Step 3, not conclusions):

- G-01-2-badge-title-overlap (plan 01-07): the fixed-height daisyUI `.badge` with no wrap allowance
  on the weight-band label. Lead: the class list rendered by `weight_band_badge/1` in
  lib/pukllay_club_web/components/game_chips.ex — look for the height-pin release and wrap classes
  01-07-SUMMARY.md records (`h-auto`, `whitespace-normal`).
- G-01-3-catalog-grid-overflow (plans 01-08, 01-11): this root cause explicitly says the `#games`
  grid was never defective; the report was the by-design horizontal carousel, with the contributing
  factor being daisyUI `.carousel`'s hidden scrollbar leaving no scroll cue. What must be proven gone
  is that contributing factor. Leads: lib/pukllay_club_web/components/carousel_row.ex — the rail
  markup (`data-rail`, `pk-rail`, `pk-rail-wrap`), a grep for the old `carousel carousel-center`
  class returning zero hits, the persistent prev/next controls and edge-fade from 01-08/01-11. The
  20-game row cap itself is by-design and is not a defect to verify away (decision rule 4(d)/(c)).
- G-01-4-carousel-affordance (plan 01-11): missing `w-full` on the daisyUI `.carousel` rail,
  causing window-level horizontal scroll. 01-UAT.md's G-01-4 entry records this diagnosis as
  superseded because 01-11 replaced `.carousel` entirely. Leads: zero-hit grep for the daisyUI
  `carousel` class on the rail in carousel_row.ex; the `.pk-rail` / `.pk-rail-wrap` overflow rules in
  assets/css/app.css; 01-UAT.md Test 3 result.
- G-01-4-section-hierarchy (plan 01-08): identical unvaried row headings plus no heading on the main
  `#games` grid. Two causes, both must be gone. Leads: variant/subtitle attrs on `carousel_row/1` in
  carousel_row.ex; a heading element for the main grid in
  lib/pukllay_club_web/live/catalog_live/index.ex.
- G-01-5-expansions-in-recent (plan 01-09): no expansion column [data] AND an unfiltered recency
  query [code]. Leads: `is_expansion` in lib/pukllay_club/catalog.ex (the recent query's
  `is_expansion == false` filter), the backing migration under priv/repo/migrations/ (read-only),
  and `PukllayClub.Catalog.Seed.ExpansionClassifier`.
- G-01-6-card-info-density (plan 01-07): (1) three co-equal stacked chip rows with the primary badge
  differentiated only by hue, AND (2) an uncapped editorial-tags row. Leads: `editorial_tags/1`
  limit and "+N" overflow in game_chips.ex; badge size step (`badge-lg` primary vs smaller
  secondary); the shared secondary wrapper grouping in lib/pukllay_club_web/components/game_card.ex.
- G-01-7-double-focus-ring (plan 01-07): daisyUI's `.input`/`.select` border ring plus an offset
  outline in the same colour, applied un-suppressed by `CoreComponents.input/1`. Upstream daisyUI
  CSS is expected to be unchanged (rule 4(d)); verify the project-side suppression. Lead:
  `focus:outline-hidden focus-within:outline-hidden` on the select, textarea and catch-all input
  branches in lib/pukllay_club_web/components/core_components.ex, and grep for any plain
  `.input`/`.select` render site that bypasses `CoreComponents.input/1` without the suppression.

Commit the task's renames and edits together (both sides of each rename). Record every decision
(resolved or diagnosed) with its evidence for the SUMMARY.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && B=bd3592c292bdd4aa9e697c7360b45a69169f7836 && T=$(mktemp -d) && fail=0 && for f in G-01-2-badge-title-overlap G-01-3-catalog-grid-overflow G-01-4-carousel-affordance G-01-4-section-hierarchy G-01-5-expansions-in-recent G-01-6-card-info-density G-01-7-double-focus-ring; do s=.planning/debug/$f.md; r=.planning/debug/resolved/$f.md; if [ -f "$r" ]; then git show "$B:$s" > "$T/base" || { echo "NO-BASELINE $f"; fail=1; }; sed -n '/^root_cause:/,/^fix:/{/^fix:/!p}' "$T/base" > "$T/old"; sed -n '/^root_cause:/,/^fix:/{/^fix:/!p}' "$r" > "$T/new"; sed -n '/^verification:/,/^files_changed:/p' "$r" > "$T/ver"; if [ -e "$s" ] || ! grep -qx 'status: resolved' "$r" || grep -qx 'files_changed: \[\]' "$r" || ! grep -qE '^fix: ".*plan 01(\.[0-9])?-[0-9]{2}' "$r" || grep -E '^fix:' "$r" | grep -qiE 'not applied|n/a' || grep -qiE 'not applied|not applicable|not run|diagnosis only|n/a' "$T/ver" || ! grep -qE '\.(ex|exs|css|js|heex):[0-9]+' "$T/ver" || ! cmp -s "$T/old" "$T/new"; then echo "BAD-RESOLVED $f"; fail=1; else echo "RESOLVED $f"; fi; else if git diff --quiet "$B" -- "$s" && grep -qx 'status: diagnosed' "$s"; then echo "DIAGNOSED $f"; else echo "TOUCHED-DIAGNOSED $f"; fail=1; fi; fi; done; st=$(git status --porcelain -- lib assets test config priv) || { echo GIT-STATUS-FAILED; fail=1; }; [ -n "$st" ] && { echo APP-CODE-TOUCHED; fail=1; }; git diff --quiet "$B" -- lib assets test config priv || { echo APP-CODE-TOUCHED; fail=1; }; test $fail -eq 0</automated>
  </verify>
  <done>
Each of the seven G-01-* files is either (a) at .planning/debug/resolved/ with `status: resolved`, a
one-line `fix:` citing its plan id and commit sha, a `verification:` block with current path:line
evidence per cause, a non-empty `files_changed:` list, and a `root_cause` byte-identical to the
baseline; or (b) still at .planning/debug/ byte-identical to the baseline with `status: diagnosed`.
No path under lib/, assets/, test/, config/ or priv/ is modified (git status and git diff against the
baseline both empty for those paths). Every decision and its evidence is captured for the SUMMARY.
  </done>
</task>

<task type="auto">
  <name>Task 2: Close out the two G-01.4-* About-page debug sessions (plans 01.4-06 / 01.4-07, later 01.4-08..12 rework)</name>
  <files>.planning/debug/G-01.4-1-isologo-morph-blink.md, .planning/debug/G-01.4-2-map-thumb-coverage.md, and their .planning/debug/resolved/ destinations</files>
  <read_first>
    - .planning/milestones/v1.0-phases/01.4-ui-polish-pass-for-about-page-sketches/01.4-UAT.md (G-01.4-1 and G-01.4-2 gap entries)
    - .planning/milestones/v1.0-phases/01.4-ui-polish-pass-for-about-page-sketches/01.4-06-SUMMARY.md, 01.4-07-SUMMARY.md, 01.4-12-SUMMARY.md
    - Both debug files' Resolution section
  </read_first>
  <action>
Apply the closure_protocol, Steps 1-7, to each file below. Both About-page surfaces were reworked
again after their closing plan (phase 01.4 follow-up plans and phase 01.5's header-morph work), so
verify strictly against the current lib/pukllay_club_web/live/about_live.ex and assets/css/app.css,
not against the 01.4-06/01.4-07 snapshot. Leads:

- G-01.4-1-isologo-morph-blink (plan 01.4-06): THREE INDEPENDENT causes — every one must be proven
  gone (rule 4(a)).
  S1 blink: header hiding applied only by the client hook after join, with an animated opacity fade.
  Leads: a server-rendered `data-morph-armed` marker in about_live.ex and the `body:has()` CSS guard
  keyed on it in app.css; the `#app-header.pk-header-about-morph` rule's transition.
  S2 spacing: a bare 200px anchor with only the hero's flat 12px `space-y-3` below it. 01.4-06 set a
  spacing tier and 01.4-08 (G-01.4-3, already in resolved/) re-derived it — lead: the
  `--pk-about-mark-clear` / anchor-height rules and the hero spacing classes.
  S3 not fluid: (a) top/left/width/height transitions with `--ease-out-soft` at large travel,
  (b) the cancelled undock (`place(natural, false)` + `.no-anim` hard snap on the next scroll frame),
  (c) the stale entrance (`onScroll` early-return while the 500ms `entered` timer runs). Leads:
  `.pk-about-morph-mark` transition properties in app.css (transform-based interpolation vs layout
  properties), the hook's syncPosition / onScroll / entered logic in about_live.ex.
- G-01.4-2-map-thumb-coverage (plan 01.4-07, commit 3238c3d): THREE AND-gated conditions — (1) the
  59-character desktop caption shipped at every width, (2) the 88%-opaque flat caption overlay over a
  real screenshot, (3) the `aspect-ratio: 21/9` box shrinking while the caption grows. Leads: the
  caption markup and any short/mobile caption variant in about_live.ex; the `.pk-about-map-label`
  background/border rule and `.pk-about-map-thumb` sizing rule in app.css. Note that plans 01.4-11 /
  01.4-12 replaced the screenshot with a live Maps embed (see the "The live embed itself (plan
  01.4-12" comment in app.css) — if the screenshot thumbnail markup is gone, apply rule 4(c) with a
  zero-hit grep and cite 01.4-12's commit as well as 01.4-07's in `fix:`.

Commit the task's renames and edits together (both sides of each rename). Record every decision
with its evidence for the SUMMARY.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && B=bd3592c292bdd4aa9e697c7360b45a69169f7836 && T=$(mktemp -d) && fail=0 && for f in G-01.4-1-isologo-morph-blink G-01.4-2-map-thumb-coverage; do s=.planning/debug/$f.md; r=.planning/debug/resolved/$f.md; if [ -f "$r" ]; then git show "$B:$s" > "$T/base" || { echo "NO-BASELINE $f"; fail=1; }; sed -n '/^root_cause:/,/^fix:/{/^fix:/!p}' "$T/base" > "$T/old"; sed -n '/^root_cause:/,/^fix:/{/^fix:/!p}' "$r" > "$T/new"; sed -n '/^verification:/,/^files_changed:/p' "$r" > "$T/ver"; if [ -e "$s" ] || ! grep -qx 'status: resolved' "$r" || grep -qx 'files_changed: \[\]' "$r" || ! grep -qE '^fix: ".*plan 01(\.[0-9])?-[0-9]{2}' "$r" || grep -E '^fix:' "$r" | grep -qiE 'not applied|n/a' || grep -qiE 'not applied|not applicable|not run|diagnosis only|n/a' "$T/ver" || ! grep -qE '\.(ex|exs|css|js|heex):[0-9]+' "$T/ver" || ! cmp -s "$T/old" "$T/new"; then echo "BAD-RESOLVED $f"; fail=1; else echo "RESOLVED $f"; fi; else if git diff --quiet "$B" -- "$s" && grep -qx 'status: diagnosed' "$s"; then echo "DIAGNOSED $f"; else echo "TOUCHED-DIAGNOSED $f"; fail=1; fi; fi; done; st=$(git status --porcelain -- lib assets test config priv) || { echo GIT-STATUS-FAILED; fail=1; }; [ -n "$st" ] && { echo APP-CODE-TOUCHED; fail=1; }; git diff --quiet "$B" -- lib assets test config priv || { echo APP-CODE-TOUCHED; fail=1; }; test $fail -eq 0</automated>
  </verify>
  <done>
Both G-01.4-* files are either resolved-and-moved (all three causes of G-01.4-1 individually
evidenced gone; G-01.4-2's conjunction evidenced broken or its markup evidenced replaced; one-line
`fix:` with plan id + sha; path:line `verification:`; non-empty `files_changed:`; `root_cause`
byte-identical to baseline) or left byte-identical as diagnosed. No path under lib/, assets/, test/,
config/ or priv/ is modified. Every decision and its evidence is captured for the SUMMARY.
  </done>
</task>

<task type="auto">
  <name>Task 3: Close out the four G-01.5-* Cierre/CTA debug sessions (plans 01.5-09 / 01.5-10) and write the item SUMMARY report</name>
  <files>.planning/debug/G-01.5-4-hero-cierre-composition-balance.md, .planning/debug/G-01.5-5-cierre-footer-gap.md, .planning/debug/G-01.5-6-cierre-top-bottom-whitespace.md, .planning/debug/G-01.5-7-cta-bar-background-visible.md, and their .planning/debug/resolved/ destinations</files>
  <read_first>
    - .planning/milestones/v1.0-phases/01.5-about-page-cta-rhythm-header-morph-refinement-implement-sket/01.5-UAT.md (G-01.5-4 through G-01.5-7 gap entries, `closed_by`)
    - .planning/milestones/v1.0-phases/01.5-about-page-cta-rhythm-header-morph-refinement-implement-sket/01.5-VERIFICATION.md (live measurements for these gaps)
    - .planning/milestones/v1.0-phases/01.5-about-page-cta-rhythm-header-morph-refinement-implement-sket/01.5-09-SUMMARY.md, 01.5-10-SUMMARY.md
    - The four debug files' Resolution section (skip the long Evidence sections unless a cause needs them)
  </read_first>
  <action>
Apply the closure_protocol, Steps 1-7, to each file below. The Cierre band and footer boundary were
touched again after these closures (01.5-11 through 01.5-14, and the still-open sibling session
cierre-band-whitespace owned by 260912-mxr — read it only if needed, never edit it), so verify
against current assets/css/app.css and lib/pukllay_club_web/components/layouts.ex. Leads:

- G-01.5-4-hero-cierre-composition-balance (plan 01.5-10): CAUSE 1 visual — `sumate_cta/1`'s button
  spec (btn-lg min-h-11, 20px padding-inline, 4px radius, 18px type) diverging from sketch 051's
  pill; CAUSE 2 process — commit dfb1259 claimed a closure while 01.5-UAT.md carried the gap as
  failed. Independent causes, both must be gone. Leads: the `pk-sumate-btn` class on `sumate_cta/1`
  in layouts.ex and its padding-inline / border-radius / font-size rule in app.css; 01.5-UAT.md's
  G-01.5-4 `status: closed` with `closed_by` naming plan 01.5-10 (that reconciled record is the
  evidence that CAUSE 2's disagreement between records no longer exists), plus the
  01.5-VERIFICATION.md live measurement line (116.75x48, 2.00:1, pill radius).
- G-01.5-5-cierre-footer-gap (plan 01.5-09): AND-gate of the shared 24px footer margin-top and the
  same-token `#cierre` tint above the footer; the tint is a preserved D-14 decision (rule 4(b)), so
  the margin half must be 0 on this page. Lead: the page-scoped
  `body:has(#cierre) main.pk-bottom-collapse + .pk-footer` / `main.pk-boundary-collapse + .pk-footer`
  `margin-top: 0` override in app.css, confirming the shared 1.5rem rule still exists for the
  catalog pages; 01.5-UAT.md `closed_by` (0.00px at 4 widths x 2 themes).
- G-01.5-6-cierre-top-bottom-whitespace (plan 01.5-09): one declaration —
  `@media (min-width: 640px) { #cierre { padding-block: 8rem } }`. Resolved only if the 8rem value
  is gone from that rule. Leads: grep the `#cierre` rule(s) in app.css for `padding-block`;
  01.5-UAT.md `closed_by` (8rem to 5rem, gapTop=gapBottom=80px). If the current value is neither
  8rem nor the 5rem the closing plan set, still resolve when 8rem is gone, but state the current
  value and the commit that last changed it in `verification:` and flag it in the SUMMARY.
- G-01.5-7-cta-bar-background-visible (plan 01.5-10, commit e42d713): three AND-gated conditions —
  (1) the dominant low-contrast `border-top: 1px solid var(--color-base-300)` on
  `.pk-about-cta-bar`, (2) the base-100 fill, documented in the root cause as not independently
  fixable (may legitimately remain), (3) the literal 4.5rem `body:has(.pk-about-cta-bar)`
  reservation against a 69px bar. Resolved when (1) and (3) are evidenced gone. Leads: the
  `.pk-about-cta-bar` rule's border-top token in app.css; the `body:has(.pk-about-cta-bar)`
  reservation now driven by `--pk-about-cta-bar-h` instead of a literal; 01.5-UAT.md `closed_by`
  (bar 73.00px = clearance 73.00px).

Commit the task's renames and edits together (both sides of each rename).

Then, in the item SUMMARY (`.planning/quick/260912-mxq-close-out-the-13-diagnosed-g-01-x-debug-sessions-in-planning/260912-mxq-SUMMARY.md`,
written by the execute-plan workflow), include a 13-row decision table covering all three tasks with
columns: debug file, decision (resolved / stays diagnosed), closing plan id(s), commit sha(s), key
current-code evidence (path:line). Below it, a "Still diagnosed" section giving, for each file that
stayed, the cause that still holds, its current path:line, the UAT status of the gap, and the
recommended next step — or the explicit statement that all 13 were resolved.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && B=bd3592c292bdd4aa9e697c7360b45a69169f7836 && T=$(mktemp -d) && fail=0 && for f in G-01.5-4-hero-cierre-composition-balance G-01.5-5-cierre-footer-gap G-01.5-6-cierre-top-bottom-whitespace G-01.5-7-cta-bar-background-visible; do s=.planning/debug/$f.md; r=.planning/debug/resolved/$f.md; if [ -f "$r" ]; then git show "$B:$s" > "$T/base" || { echo "NO-BASELINE $f"; fail=1; }; sed -n '/^root_cause:/,/^fix:/{/^fix:/!p}' "$T/base" > "$T/old"; sed -n '/^root_cause:/,/^fix:/{/^fix:/!p}' "$r" > "$T/new"; sed -n '/^verification:/,/^files_changed:/p' "$r" > "$T/ver"; if [ -e "$s" ] || ! grep -qx 'status: resolved' "$r" || grep -qx 'files_changed: \[\]' "$r" || ! grep -qE '^fix: ".*plan 01(\.[0-9])?-[0-9]{2}' "$r" || grep -E '^fix:' "$r" | grep -qiE 'not applied|n/a' || grep -qiE 'not applied|not applicable|not run|diagnosis only|n/a' "$T/ver" || ! grep -qE '\.(ex|exs|css|js|heex):[0-9]+' "$T/ver" || ! cmp -s "$T/old" "$T/new"; then echo "BAD-RESOLVED $f"; fail=1; else echo "RESOLVED $f"; fi; else if git diff --quiet "$B" -- "$s" && grep -qx 'status: diagnosed' "$s"; then echo "DIAGNOSED $f"; else echo "TOUCHED-DIAGNOSED $f"; fail=1; fi; fi; done; st=$(git status --porcelain -- lib assets test config priv) || { echo GIT-STATUS-FAILED; fail=1; }; [ -n "$st" ] && { echo APP-CODE-TOUCHED; fail=1; }; git diff --quiet "$B" -- lib assets test config priv || { echo APP-CODE-TOUCHED; fail=1; }; git diff --quiet "$B" -- .planning/debug/knowledge-base.md .planning/debug/assets .planning/milestones || { echo OUT-OF-SCOPE-PLANNING-TOUCHED; fail=1; }; test $fail -eq 0</automated>
  </verify>
  <done>
All four G-01.5-* files are either resolved-and-moved with plan-id + sha `fix:`, per-cause path:line
`verification:`, non-empty `files_changed:`, and byte-identical `root_cause`, or left byte-identical
as diagnosed. knowledge-base.md, .planning/debug/assets/ and the milestone archive are unchanged. No
path under lib/, assets/, test/, config/ or priv/ is modified. The SUMMARY carries the 13-row
decision table and the "Still diagnosed" report.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| planning records -> future agents | Resolved debug files are read by later /gsd-debug, knowledge-base and audit runs as ground truth about what is fixed |
| archived UAT/SUMMARY/commit claims -> closure decision | Prior records have already been shown to over-claim closures (commit dfb1259) |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-mxq-01 | Tampering (record integrity) | resolved debug files | medium | mitigate | closure_protocol Step 4 forbids resolving on a UAT/SUMMARY/commit claim alone; every task's verify requires a `.ex`/`.css`/`.js` path:line reference in `verification:` and a `plan NN-NN` citation in `fix:` |
| T-mxq-02 | Tampering (history loss) | root_cause / diagnosis sections | medium | mitigate | Step 5 restricts edits to five fields; verify diffs the root_cause region against baseline bd3592c and fails on any change |
| T-mxq-03 | Tampering (scope escape) | lib/, assets/, test/, config/, priv/ | high | mitigate | Step 7 fence plus verify gates on both `git status --porcelain` and `git diff` against baseline for those paths; Task 3 also gates knowledge-base.md, debug assets and the milestone archive |
| T-mxq-04 | Repudiation | stays-diagnosed files silently dropped | low | mitigate | verify fails on any diagnosed file that was touched; SUMMARY must carry a 13-row table plus the Still diagnosed report |
</threat_model>

<verification>
- Run all three task verify commands in sequence from the repo root; each must exit 0 and print one
  RESOLVED or DIAGNOSED line per file with no BAD-RESOLVED, TOUCHED-DIAGNOSED, APP-CODE-TOUCHED or
  OUT-OF-SCOPE-PLANNING-TOUCHED line.
- The item's commits (`git log --stat` from the baseline) show only `.planning/debug/` renames/edits (plus the
  quick SUMMARY written by the workflow).
- `ls .planning/debug/G-01*` lists only the files reported as still diagnosed.
</verification>

<success_criteria>
- 13 of 13 sessions have an evidenced decision; resolved ones live in `.planning/debug/resolved/`
  with the resolved frontmatter shape and filled fix/verification/files_changed.
- Zero application-code changes (lib/, assets/, test/, config/, priv/ untouched).
- The SUMMARY reports every session that stays diagnosed, with the cause that still holds.
</success_criteria>

<output>
Create `.planning/quick/260912-mxq-close-out-the-13-diagnosed-g-01-x-debug-sessions-in-planning/260912-mxq-SUMMARY.md` when done
</output>
