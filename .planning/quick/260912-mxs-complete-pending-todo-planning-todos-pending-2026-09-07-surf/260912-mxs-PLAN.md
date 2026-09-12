---
phase: quick-260912-mxs
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/todos/pending/2026-09-07-surface-pukllay-club-brand-name-in-content.md
  - .planning/todos/completed/2026-09-07-surface-pukllay-club-brand-name-in-content.md
files_deleted:
  - .planning/todos/pending/2026-09-07-surface-pukllay-club-brand-name-in-content.md
autonomous: true

must_haves:
  truths:
    - "All three brand-name evidence points were re-verified BY CONTENT against the current tree before anything moved"
    - "The todo lives in .planning/todos/completed/ with frontmatter completed: <date> and status: completed, and no longer exists in pending/"
    - "The completed todo carries a ## Resolution section citing each evidence point with its current file:line"
    - "No file under lib/, assets/, test/, config/, or priv/ changed"
  artifacts:
    - path: ".planning/todos/completed/2026-09-07-surface-pukllay-club-brand-name-in-content.md"
      provides: "Closed todo with recorded evidence"
  key_links:
    - from: "## Resolution section"
      to: "lib/pukllay_club_web/live/about_live.ex, lib/pukllay_club_web/components/layouts.ex, lib/pukllay_club_web/seo.ex"
      via: "content-verified file:line citations"
---

<objective>
Close the pending todo "Surface Pukllay Club brand name in site content" — it is already satisfied
by shipped work. Re-verify the three evidence points by content (line numbers may have drifted),
append a `## Resolution` section recording that evidence, then move the todo with the
`todo complete` verb.

Purpose: the todo is stale backlog noise; its own "explore via /gsd-sketch when picked up"
instruction is obsolete because Sketch 050 (01.5-01, D-15) already happened and shipped. Do NOT
run /gsd-sketch.

Output: `.planning/todos/completed/2026-09-07-surface-pukllay-club-brand-name-in-content.md`
(pending copy removed). Documentation-only — zero application code changes.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md
@.planning/todos/pending/2026-09-07-surface-pukllay-club-brand-name-in-content.md

Precedent for how a completed todo records evidence (a `## Resolution` section with a
`**Date:**` line appended after `## Solution`):
@.planning/todos/completed/2026-08-18-reserve-btn-primary-for-a-single-page-action.md

**How `gsd_run` resolves.** In a bash shell run
`source <(sed -n '/^_GSD_SHIM_NAME=/p' ~/.claude/gsd-core/workflows/quick-batch.md)` to define it,
or call `node ~/.claude/gsd-core/bin/gsd-tools.cjs` directly (equivalent).

**What `todo complete` actually does** (read from `cmdTodoComplete` in
`~/.claude/gsd-core/bin/lib/commands.cjs`, planner-verified): takes ONE positional filename
relative to `.planning/todos/pending/`; supports `--dry-run` (preview only, mutates nothing);
writes the content to `.planning/todos/completed/<same filename>` with frontmatter keys
`completed: <local today>` and `status: completed` upserted (existing keys such as
`audit_acknowledged` are preserved); then unlinks the pending file. It has NO evidence/notes flag
— evidence must therefore be written into the file body BEFORE the verb runs, so it is carried
into the completed copy.

**Planner-observed evidence at planning time (2026-09-12)** — the executor must re-confirm, not trust:
1. `lib/pukllay_club_web/live/about_live.ex` — moduledoc paragraph starting
   `**Sketch 050 (01.5-01, D-15):** the pending todo "Surface Pukllay Club` (~line 34) states the
   todo is satisfied by the hero isologo companion wordmark; the wordmark element itself is
   `<span class="pk-about-morph-name">PUKLLAY CLUB</span>` (~line 970), styled by
   `.pk-about-morph-name` in `assets/css/app.css`.
2. `lib/pukllay_club_web/components/layouts.ex` — footer
   `<span class="pk-footer-meta pk-footer-copyright">© {@copyright_year} Pukllay Club</span>` (~line 1073).
3. `lib/pukllay_club_web/seo.ex` — `@site_description "La ludoteca de juegos de mesa de Pukllay Club, Jujuy — encontrá tu próximo juego."`
   (~line 32, consumed as `description: @site_description` ~line 95) and
   `@local_business_name "Pukllay Club"` (~line 37, consumed as `"name" => @local_business_name` ~line 150, JSON-LD).

Supplemental (non-gating, cite if still present): the About page Cierre signature
`Pukllay Club ·<br class="pk-about-closing-break" /> San Salvador de Jujuy, Argentina`
(about_live.ex ~line 843) and the header logo lockup text `PUKLLAY CLUB` (layouts.ex ~line 80).
Also note factually in the Resolution that `@site_title` in seo.ex is `"PukllayClub"` (no space) —
an observation only; it does not block closure and must NOT be changed by this plan.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Re-verify the three brand-name evidence points by content (read-only gate)</name>
  <files>lib/pukllay_club_web/live/about_live.ex, lib/pukllay_club_web/components/layouts.ex, lib/pukllay_club_web/seo.ex (all READ-ONLY)</files>
  <action>
Confirm `git status` is clean for lib/, assets/, test/, config/, priv/ before starting (the
branch may carry unrelated edits such as ideas.txt — ignore those).

For each evidence point in the context block, locate it by CONTENT with fixed-string grep
(`grep -nF`), never by assumed line number, and record the CURRENT line number from the grep
output for use in Task 2:

1. about_live.ex: (a) the moduledoc marker `Sketch 050 (01.5-01, D-15)` together with the phrase
   `Surface Pukllay Club`; (b) the rendered wordmark span with class `pk-about-morph-name` whose
   text is `PUKLLAY CLUB`; (c) `.pk-about-morph-name` still defined in assets/css/app.css.
2. layouts.ex: the `pk-footer-copyright` span whose text ends in `Pukllay Club`.
3. seo.ex: `@site_description` containing `Pukllay Club`, `@local_business_name "Pukllay Club"`,
   and that both attributes are still consumed (`description: @site_description` and
   `"name" => @local_business_name`).

Also grep the two supplemental points and the `@site_title` value; record them but do not gate on them.

HALT RULE: if ANY of points 1, 2, or 3 fails (text missing, element removed, attribute no longer
consumed), STOP. Do not edit the todo, do not run `todo complete`. Write the SUMMARY with status
"blocked — evidence no longer holds", naming exactly which check failed and what was found
instead, and return that as the result. Do not attempt to "fix" application code to make the
evidence hold — that is out of scope for this item.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && grep -qF 'Sketch 050 (01.5-01, D-15)' lib/pukllay_club_web/live/about_live.ex && grep -qF 'class="pk-about-morph-name">PUKLLAY CLUB</span>' lib/pukllay_club_web/live/about_live.ex && grep -qF '.pk-about-morph-name' assets/css/app.css && grep -qF 'pk-footer-copyright">© {@copyright_year} Pukllay Club</span>' lib/pukllay_club_web/components/layouts.ex && grep -qF '@site_description "La ludoteca de juegos de mesa de Pukllay Club' lib/pukllay_club_web/seo.ex && grep -qF '@local_business_name "Pukllay Club"' lib/pukllay_club_web/seo.ex && grep -qF 'description: @site_description' lib/pukllay_club_web/seo.ex && grep -qF '"name" => @local_business_name' lib/pukllay_club_web/seo.ex && echo EVIDENCE_OK</automated>
  </verify>
  <done>Command prints EVIDENCE_OK and the executor holds current file:line numbers for every evidence point (gating + supplemental). If it does not print EVIDENCE_OK, the plan halted per the HALT RULE with a blocked SUMMARY and nothing under .planning/todos/ changed.</done>
</task>

<task type="auto">
  <name>Task 2: Record evidence in the todo and close it with `todo complete`</name>
  <files>.planning/todos/pending/2026-09-07-surface-pukllay-club-brand-name-in-content.md (edited, then moved), .planning/todos/completed/2026-09-07-surface-pukllay-club-brand-name-in-content.md (created by the verb)</files>
  <action>
Only runs if Task 1 printed EVIDENCE_OK.

Step A — append evidence (Edit tool, scoped; do not rewrite the file or alter existing
frontmatter/Problem/Solution text): append a `## Resolution` section at the end of the PENDING
file, following the precedent todo's shape:
- `**Date:** 2026-09-12` (use the actual execution date if different).
- One short paragraph: already satisfied by shipped work — no new implementation in this item;
  the Solution section's "explore via /gsd-sketch" step is obsolete because Sketch 050
  (01.5-01, D-15) already ran and shipped.
- A bullet per gating evidence point with its CURRENT `path:line` from Task 1: (1) About hero
  isologo companion wordmark `.pk-about-morph-name` rendering "PUKLLAY CLUB", plus the moduledoc
  record of Sketch 050 / D-15 scoping it to the About page; (2) footer copyright
  "© {year} Pukllay Club" in layouts.ex; (3) Phase 01.8 SEO metadata in seo.ex —
  `@site_description` (meta/OG description) and `@local_business_name` (JSON-LD LocalBusiness name).
- Map these back to the todo's three candidate bullets: brand text near the isologo (About hero
  wordmark + header lockup text), About-page prose name (Cierre signature), title/meta/OG tags
  (seo.ex description + JSON-LD name).
- Supplemental notes: the Cierre signature and header lockup citations (if present), and the
  factual observation that `@site_title` is "PukllayClub" without a space — recorded, not acted on.

Step B — dry run then real run, from the repo root:
`gsd_run todo complete 2026-09-07-surface-pukllay-club-brand-name-in-content.md --dry-run`
(confirm `would_move.target` is `.planning/todos/completed/2026-09-07-surface-pukllay-club-brand-name-in-content.md`),
then the same command without `--dry-run`. Expect `completed: true`.

Step C — commit only the two todo paths (git records the move as a rename):
`git add -A .planning/todos/pending/2026-09-07-surface-pukllay-club-brand-name-in-content.md .planning/todos/completed/2026-09-07-surface-pukllay-club-brand-name-in-content.md`
with message `docs(quick-260912-mxs): close brand-name todo — satisfied by Sketch 050, footer, SEO`.
Do not stage ideas.txt or .planning/quick-batches/. No `git push origin main` (branch-protected, per CLAUDE.md).

Step D — write the SUMMARY recording the same evidence table (evidence point, current path:line,
matched text) and the `todo complete` JSON output.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && F=.planning/todos/completed/2026-09-07-surface-pukllay-club-brand-name-in-content.md && test -f "$F" && test ! -e .planning/todos/pending/2026-09-07-surface-pukllay-club-brand-name-in-content.md && grep -q '^status: completed$' "$F" && grep -q '^completed: ' "$F" && grep -q '^## Resolution' "$F" && grep -qF 'pk-about-morph-name' "$F" && grep -qF 'layouts.ex:' "$F" && grep -qF 'seo.ex:' "$F" && grep -q '^audit_acknowledged:' "$F" && C=$(git log -1 --format=%H -- "$F") && test -n "$C" && test -z "$(git diff --name-only "$C^" "$C" -- lib assets test config priv)" && echo CLOSED_OK</automated>
  </verify>
  <done>Prints CLOSED_OK: the todo exists only under completed/ with `status: completed`, a `completed:` date, preserved `audit_acknowledged` frontmatter, and a `## Resolution` section citing about_live.ex (pk-about-morph-name), layouts.ex, and seo.ex by current line; the commit touches no application code.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| planning docs → git history | Only .planning/todos/ markdown changes; no runtime, network, or user input surface |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-260912-mxs-01 | Repudiation | Todo closure record | low | mitigate | Task 1 content-verifies evidence against the live tree before closing; Resolution cites current path:line so the closure is auditable |
| T-260912-mxs-02 | Tampering | Commit scope | low | mitigate | Stage only the two todo paths; Task 2 verify asserts the commit has zero lib/assets/test/config/priv paths |
| T-260912-mxs-03 | Information disclosure | Todo content | low | accept | Content is internal planning prose with no secrets |
</threat_model>

<verification>
- Task 1 prints EVIDENCE_OK (or the plan halted with a blocked SUMMARY and no todo changes).
- Task 2 prints CLOSED_OK.
- `gsd_run list-todos` no longer lists the brand-name todo as pending.
</verification>

<success_criteria>
- Evidence re-verified by content for all three points before any mutation.
- Todo moved to .planning/todos/completed/ via `todo complete`, with a `## Resolution` evidence section.
- Zero application code changes; single docs commit scoped to the todo move.
</success_criteria>

<output>
Create `.planning/quick/260912-mxs-complete-pending-todo-planning-todos-pending-2026-09-07-surf/260912-mxs-SUMMARY.md` when done
</output>
