---
phase: quick-260912-mxr
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/debug/no-disconnect-banner.md
  - .planning/debug/resolved/no-disconnect-banner.md
  - .planning/debug/cierre-band-whitespace.md
  - .planning/debug/resolved/cierre-band-whitespace.md
  - .planning/debug/hero-cta-isologo-balance.md
  - .planning/debug/resolved/hero-cta-isologo-balance.md
  - .planning/debug/inter-band-whitespace-gap.md
  - .planning/debug/resolved/inter-band-whitespace-gap.md
  - .planning/debug/lightbox-width-scrim-not-shell-width.md
  - .planning/debug/resolved/lightbox-width-scrim-not-shell-width.md
  - .planning/debug/hashtags-not-visible.md
  - .planning/debug/resolved/hashtags-not-visible.md
files_deleted:
  - .planning/debug/no-disconnect-banner.md
  - .planning/debug/cierre-band-whitespace.md
  - .planning/debug/hero-cta-isologo-balance.md
  - .planning/debug/inter-band-whitespace-gap.md
  - .planning/debug/lightbox-width-scrim-not-shell-width.md
  - .planning/debug/hashtags-not-visible.md
autonomous: true

must_haves:
  truths:
    - "no-disconnect-banner.md lives at .planning/debug/resolved/ with `status: resolved`, `files_changed: []`, and a recorded not-a-bug rationale: Chrome DevTools Offline emulation does not close WebSockets, so the defect was in the UAT procedure, not the code"
    - "Each of cierre-band-whitespace, hero-cta-isologo-balance, inter-band-whitespace-gap, lightbox-width-scrim-not-shell-width is moved to resolved/ ONLY if every component of its recorded root_cause is gone in current code, and its fix/verification/files_changed fields cite concrete file:line evidence plus the landing plan SUMMARY and commit hash"
    - "Any session whose root_cause (or any component of it) still holds stays at .planning/debug/ byte-unchanged with `status: diagnosed`, and is named in the SUMMARY with the grep result that proves it still holds"
    - "No file under lib/, assets/, test/, config/ or priv/ is modified by any commit of this plan"
    - ".planning/debug/whatsapp-og-image-preview.md and .planning/debug/knowledge-base.md are untouched"
  artifacts:
    - path: ".planning/debug/resolved/no-disconnect-banner.md"
      provides: "not-a-bug closure record for G-01.7-3"
      contains: "status: resolved"
    - path: ".planning/debug/resolved/cierre-band-whitespace.md"
      provides: "retroactive closure (G-01.5-3), only if all three root causes are gone"
    - path: ".planning/debug/resolved/hero-cta-isologo-balance.md"
      provides: "retroactive closure (G-01.5-1), only if the min-h-12 one-axis stretch is gone"
    - path: ".planning/debug/resolved/inter-band-whitespace-gap.md"
      provides: "retroactive closure (G-01.5-2), only if bands are no longer pushed apart by the shell margin"
    - path: ".planning/debug/resolved/lightbox-width-scrim-not-shell-width.md"
      provides: "retroactive closure (01.2-25 non-fix), only if .pk-lightbox-img now declares a real width"
  key_links:
    - from: ".planning/debug/resolved/*.md frontmatter `status:`"
      to: "milestone audit / STATE.md Deferred Items `debug_sessions` scan"
      via: "top-level `^status:` line (NOT the indented `status:` inside `audit_acknowledged`)"
      pattern: "^status: resolved"
    - from: "each resolved file's `verification:` field"
      to: "landing commit + archived plan SUMMARY under .planning/milestones/v1.0-phases/"
      via: "commit hash and SUMMARY path cited verbatim"
      pattern: "[0-9a-f]{7}"
---

<objective>
Close out the 6 remaining diagnosed debug sessions in `.planning/debug/` with a verify-then-resolve
protocol. For each session: re-read the recorded `root_cause`, re-check that exact condition against
current code with a grep/read the executor runs itself, and locate the plan + commit that landed the
fix. If the condition is gone, fill `fix:`, `verification:`, `files_changed:` with what actually
landed, set `status: resolved`, and `git mv` the file into `.planning/debug/resolved/`. If the
condition (or any component of a multi-part root cause) still holds, leave the file untouched at
`diagnosed` and report it. `no-disconnect-banner` is closed as not-a-bug by explicit instruction.

Purpose: bookkeeping only. These sessions show up as stale `diagnosed` entries in the v1.0 deferred
items and in milestone audits even though most of their fixes shipped in phases 01.2 and 01.5.
Output: up to 6 files moved to `.planning/debug/resolved/` with evidence-backed Resolution fields;
a SUMMARY listing the verdict and evidence for each of the 6.

HARD SCOPE: only files under `.planning/debug/` may change. Nothing under `lib/`, `assets/`,
`test/`, `config/`, `priv/`. Do not touch `whatsapp-og-image-preview.md`, `knowledge-base.md`, the
13 `G-01*` sessions (sibling item 260912-mxq owns those), STATE.md, or ROADMAP.md.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md

# Resolved-shape reference (frontmatter adds `resolved:` date; Resolution keeps root_cause, rewrites fix/verification/files_changed)
@.planning/debug/resolved/cta-bar-footer-gap-uncolored.md

# The 6 sessions (read each fully before judging it)
@.planning/debug/no-disconnect-banner.md
@.planning/debug/cierre-band-whitespace.md
@.planning/debug/hero-cta-isologo-balance.md
@.planning/debug/inter-band-whitespace-gap.md
@.planning/debug/lightbox-width-scrim-not-shell-width.md
@.planning/debug/hashtags-not-visible.md

Planner pre-check (2026-09-12, for orientation ONLY — the executor must re-run every check and cite
its own output; never copy these line numbers into a Resolution without re-verifying):

- no-disconnect-banner: `.planning/phases/01.7-production-catalog-data-security-hardening-inserted/01.7-UAT.md`
  gap G-01.7-3 is `status: resolved`, re-verified with `liveSocket.disconnect()/connect()`; landing
  commit `322b4bb` (test(01.7): resolve UAT gap - disconnect banner was a test-method artifact).
  Latent factors B (`.pk-conn-banner` at assets/css/app.css ~1571 has no `position`) and C
  (layouts.ex ~556 `show("#connection-status")` passes no `display`) still exist and are tracked in
  STATE.md Blockers/Concerns — they are NOT this session's reported symptom and do not block closure.
- hero-cta-isologo-balance: `min-h-12` survives only inside a comment (layouts.ex ~880); the
  `sumate_cta/1` class list (~921) is `btn btn-outline btn-primary pk-sumate-btn`; `.pk-sumate-btn`
  (app.css ~3045) sets min-height 48px + padding-inline 28px + font-size 1rem + pill radius, i.e. a
  coupled geometry, not a one-axis stretch. Landing commits `eaf9f76` (01.5-05) then `0e99941` (01.5-10).
- inter-band-whitespace-gap: `.pk-band { padding: 4.5rem 0; margin-block-end: 0; }` (app.css ~3334).
  Landing commit `5ebfde3` (01.5-06). The shell `space-y-4` in layouts.ex is DELIBERATELY retained
  (the session's own fix direction forbids removing it) — its presence is not a HOLDS signal.
- cierre-band-whitespace: 3a `min-height: 100vh` on `#cierre` gone (≥640px block is now
  `#cierre { padding-block: 5rem }`, app.css ~3498); 3b `padding: var(--pk-header-h, 4.5rem) 0 0`
  survives only in a comment (~3426); item 4 — about_live.ex ~61 passes `bottom_collapse`, no
  `class="pk-about-cta-spacer"` element or `.pk-about-cta-spacer` CSS rule remains (replaced by
  `body:has(.pk-about-cta-bar)`, app.css ~6888). Landing commits `860b95e` (01.5-07), `83c9880`
  (01.5-08), `50c41b0` (01.5-09), `5ebfde3` (01.5-06), `a257841` (01.5-11).
- lightbox-width-scrim-not-shell-width: `.pk-lightbox-img` (app.css ~5624) now declares
  `width: var(--pk-shell-content-width)`. Landing commit `739b057` (01.2-28, "give the lightbox photo
  a real box — shell width, unchanged height, opaque stage").
- hashtags-not-visible: condition STILL HOLDS — game_chips.ex ~162 still has the `:if={@tags != []}`
  guard and hashtag_normalizer.ex ~22 still maps exactly 3 `@editorial_columns`. This was a product
  decision (01.3-UAT.md G-01.3-1 `resolved_by: "product decision — accepted as intended"`), but the
  user authorized not-a-bug closure only for no-disconnect-banner, so this file stays untouched.

Archived plan SUMMARYs live under `.planning/milestones/v1.0-phases/` (e.g.
`01.5-about-page-cta-rhythm-header-morph-refinement-implement-sket/01.5-05-SUMMARY.md` … `01.5-11-SUMMARY.md`,
`01.2-catalog-detail-navigation-polish/01.2-28-SUMMARY.md`), not under `.planning/phases/`.
</context>

<tasks>

<task type="tracer">
  <name>Task 1: Tracer — close no-disconnect-banner end-to-end as not-a-bug</name>
  <files>.planning/debug/no-disconnect-banner.md, .planning/debug/resolved/no-disconnect-banner.md</files>
  <read_first>
    .planning/debug/no-disconnect-banner.md;
    .planning/debug/resolved/cta-bar-footer-gap-uncolored.md (frontmatter lines 1-7 and the fix/verification/files_changed block only);
    .planning/phases/01.7-production-catalog-data-security-hardening-inserted/01.7-UAT.md (gap G-01.7-3 block, ~lines 50-70)
  </read_first>
  <action>
    This task proves the whole closure path (evidence gather, frontmatter edit, Resolution edit,
    git mv, scoped commit, scope gate) on the one session whose verdict is fixed by instruction,
    before the verify-dependent sessions in Task 2.

    1. Gather evidence by running, and keeping the output of: `grep -n 'connection-status' lib/pukllay_club_web/components/layouts.ex`
       (confirms the banner markup + phx-disconnected/phx-connected bindings still exist, i.e. the
       code path the UAT failed to exercise is present), `grep -n -A3 'G-01.7-3' .planning/phases/01.7-production-catalog-data-security-hardening-inserted/01.7-UAT.md`
       plus the `reason:` line of that gap (records the liveSocket.disconnect()/connect() re-verification pass),
       and `git log --oneline -1 322b4bb` (landing record of the UAT resolution). Read-only; do not
       run the app.
    2. Edit the frontmatter: `status: diagnosed` becomes `status: resolved`; `updated:` becomes
       `2026-09-12`; add a `resolved: 2026-09-12` line directly after `updated:` (same shape as
       cta-bar-footer-gap-uncolored.md). This file has no `audit_acknowledged` block; do not add one.
    3. In `## Resolution`, keep `root_cause:` and `suggested_verification_method:` verbatim. Replace
       `fix:` with a block scalar that starts with the literal token `not-a-bug` and records: closed
       as not-a-bug on 2026-09-12 (quick 260912-mxr); Chrome DevTools Offline network emulation does
       not close or block established WebSocket connections, so the LiveView socket never
       disconnected and `phx-disconnected` never fired; the defect was in the UAT procedure (01.7-UAT.md
       Test 3 used DevTools Offline), not in the application code; no application change was made or
       needed. Also state explicitly that latent contributing factors B (in-flow banner with no
       `position`, invisible when scrolled) and C (`JS.show` inline `display: block` overriding
       `display: flex`) are NOT resolved by this closure, still exist in code (cite the file:line you
       observed), and remain tracked in STATE.md Blockers/Concerns.
    4. Replace `verification:` with a block scalar citing: the 01.7-UAT.md G-01.7-3 record
       (`status: resolved`, re-verified via `liveSocket.disconnect()` / `liveSocket.connect()` —
       banner appeared, clean reconnect), commit `322b4bb`, and the layouts.ex grep line numbers you
       observed in step 1. Set `files_changed: []` (the literal empty list, since nothing in the app changed).
    5. Do not edit Current Focus, Symptoms, Eliminated or Evidence — they are the investigation record.
    6. `git mv .planning/debug/no-disconnect-banner.md .planning/debug/resolved/no-disconnect-banner.md`,
       then commit only that path with subject `docs(debug): resolve no-disconnect-banner as not-a-bug (260912-mxr)`.
       Stage explicitly by path; never `git add -A` / `git add .` (the main checkout has an unrelated
       modified ideas.txt and an untracked .planning/quick-batches/).
  </action>
  <verify>
    <automated>F=$(git show --name-only --format= HEAD) && S=$(git status --porcelain -- lib assets test config priv) && test -f .planning/debug/resolved/no-disconnect-banner.md && test ! -e .planning/debug/no-disconnect-banner.md && grep -q '^status: resolved' .planning/debug/resolved/no-disconnect-banner.md && grep -q '^resolved: 2026-09-12' .planning/debug/resolved/no-disconnect-banner.md && grep -q 'not-a-bug' .planning/debug/resolved/no-disconnect-banner.md && grep -q '^files_changed: \[\]' .planning/debug/resolved/no-disconnect-banner.md && grep -q '322b4bb' .planning/debug/resolved/no-disconnect-banner.md && test -z "$(printf '%s\n' "$F" | grep -v '^$' | grep -v '^\.planning/debug/')" && test -z "$S" && echo TRACER-OK</automated>
  </verify>
  <done>
    no-disconnect-banner.md is at .planning/debug/resolved/ with `status: resolved`, a `resolved:` date,
    a not-a-bug `fix:` naming the Chrome DevTools/WebSocket mechanism and the UAT-procedure defect,
    a `verification:` citing 01.7-UAT.md G-01.7-3 + commit 322b4bb, `files_changed: []`, latent B/C
    explicitly recorded as still open; committed alone in one commit touching only .planning/debug/ paths.
  </done>
</task>

<task type="auto">
  <name>Task 2: Verify-then-resolve the four sessions whose fixes appear to have landed</name>
  <files>.planning/debug/cierre-band-whitespace.md, .planning/debug/resolved/cierre-band-whitespace.md, .planning/debug/hero-cta-isologo-balance.md, .planning/debug/resolved/hero-cta-isologo-balance.md, .planning/debug/inter-band-whitespace-gap.md, .planning/debug/resolved/inter-band-whitespace-gap.md, .planning/debug/lightbox-width-scrim-not-shell-width.md, .planning/debug/resolved/lightbox-width-scrim-not-shell-width.md</files>
  <read_first>
    Each of the four session files in full (their `## Resolution` root_cause is the thing being tested);
    .planning/milestones/v1.0-phases/01.5-about-page-cta-rhythm-header-morph-refinement-implement-sket/01.5-05-SUMMARY.md, 01.5-06-SUMMARY.md, 01.5-07-SUMMARY.md, 01.5-08-SUMMARY.md, 01.5-09-SUMMARY.md, 01.5-10-SUMMARY.md, 01.5-11-SUMMARY.md;
    .planning/milestones/v1.0-phases/01.2-catalog-detail-navigation-polish/01.2-28-SUMMARY.md
  </read_first>
  <action>
    Process each session independently with the same protocol. Verdict per session is GONE or HOLDS.
    A multi-part root cause is GONE only if EVERY component is gone; if any single component still
    holds, the whole file is HOLDS — no partial resolution, no edits to that file.

    Evidence step (run yourself, keep exact output for the Resolution and SUMMARY):
    - For every condition, grep/read current code and record file:line. Distinguish live declarations
      from comments: a match inside a CSS `/* */` comment, an HEEx `<%!-- --%>` comment, or an Elixir
      `#` comment / moduledoc prose does not count as the condition holding — say so explicitly when
      that is the case (several fixes left the old declaration quoted in a rationale comment).
    - Locate the landing record: `git log --oneline -S '<distinguishing string>' -- <path>` and
      `git show --stat <hash>` for each candidate commit, then open the matching SUMMARY under
      .planning/milestones/v1.0-phases/. Only cite commits whose `git show --stat` actually touches
      the file that fixed the condition.

    Session-specific conditions to test:
    (a) hero-cta-isologo-balance (G-01.5-1). Condition: `Layouts.sumate_cta/1` sizes the button with
        a raw one-axis `min-h-12` over daisyUI's default size step. Check the live class list of
        `sumate_cta/1` in lib/pukllay_club_web/components/layouts.ex, every `min-h-12` occurrence in
        lib/ and assets/css/app.css (classify code vs comment), and the `.pk-sumate-btn` rule in
        app.css (does it set height, padding-inline and font-size together?). Candidates: eaf9f76
        (01.5-05), 0e99941 (01.5-10).
    (b) inter-band-whitespace-gap (G-01.5-2). Condition: every `.pk-band` carries the shell wrapper's
        16px `space-y-4` `margin-block-end` because `.pk-band` declares no margin of its own. Check the
        `.pk-band {` rule body in app.css for an own `margin-block-end: 0`. The shell `space-y-4` in
        layouts.ex is intentionally retained per the session's own fix constraints — record its
        presence, but it is not the holding condition. Candidate: 5ebfde3 (01.5-06); also note the
        geometric adjacency oracle `test/visual/about_geometry.mjs` if its SUMMARY says it shipped there.
    (c) cierre-band-whitespace (G-01.5-3). Three components, all must be gone:
        3a `min-height: 100vh` on `#cierre` inside the `@media (min-width: 640px)` block;
        3b `padding: var(--pk-header-h, 4.5rem) 0 0` on `#cierre` in that same block (live, not comment);
        4  the About page's stacked bottom boundary — about_live.ex's `<Layouts.app ...>` call must pass
           `bottom_collapse`, and no rendered `class="pk-about-cta-spacer"` element and no live
           `.pk-about-cta-spacer` CSS rule may remain (grep both lib/ and assets/css/app.css).
        Candidates: 860b95e (01.5-07), 83c9880 (01.5-08), 50c41b0 (01.5-09), 5ebfde3 (01.5-06), a257841 (01.5-11).
        Note: this session's item 5 (CTA balance) belongs to hero-cta-isologo-balance's root cause and
        is not a separate condition here.
    (d) lightbox-width-scrim-not-shell-width. Condition: `.pk-lightbox-img` declares only
        `max-width`/`max-height` and never an actual `width`, so the ~800px catalog image renders at
        intrinsic size. Check the `.pk-lightbox-img {` rule body in app.css for a real `width:`
        declaration. Record (do not treat as conditions) the chevron/scrim sub-complaints the
        root_cause already classed as a deliberate 01.2-21 tradeoff and a downstream perception —
        note what the `.pk-lightbox {` rule now paints if the 01.2-28 SUMMARY claims an opaque stage.
        Candidate: 739b057 (01.2-28).

    If GONE, edit the file:
    - Frontmatter: top-level `status: diagnosed` becomes `status: resolved`; `updated: 2026-09-12`;
      add `resolved: 2026-09-12` right after `updated:`. Leave any `audit_acknowledged` block (and the
      indented `status: diagnosed` inside it) untouched — it is the historical v1.0-close record.
    - `## Resolution`: keep `root_cause:` and any `suggested_fix_direction:` verbatim. Replace `fix:`
      with a block scalar beginning `RETROACTIVE CLOSURE (quick 260912-mxr, 2026-09-12) — fix landed after this diagnosis:`
      then, per root-cause component, which plan landed it, the commit hash, and one sentence on what
      the change actually was (taken from the SUMMARY and `git show --stat`, not from this plan).
      Replace `verification:` with a block scalar listing, per component, the grep/read command you
      ran and its current file:line result proving the condition is gone (with the comment-vs-code
      classification where relevant), plus the SUMMARY path(s). Replace `files_changed:` with a YAML
      list of `"<app path> — <what changed>"` entries for the application files the landing commits
      touched per `git show --stat` (these describe the landed fix; this plan itself changes no app files).
    - Do not edit Current Focus, Symptoms, Eliminated, Evidence or Assets sections.
    - `git mv .planning/debug/<name>.md .planning/debug/resolved/<name>.md`. Asset directories under
      .planning/debug/assets/ stay where they are (resolved sessions already reference assets there).
    If HOLDS: do not edit, do not move; record the session name, the holding component, and the exact
    grep output for the SUMMARY.

    Commit all GONE sessions from this task in one commit, staging explicitly by path, subject
    `docs(debug): resolve <N> diagnosed sessions whose fixes landed (260912-mxr)`. If all four HOLD,
    make no commit and say so in the SUMMARY.
  </action>
  <verify>
    <automated>L=$(git log --name-only --format= --all-match --grep='260912-mxr' --grep='docs(debug)') || exit 1; S=$(git status --porcelain -- lib assets test config priv) || exit 1; for s in cierre-band-whitespace hero-cta-isologo-balance inter-band-whitespace-gap lightbox-width-scrim-not-shell-width; do if [ -f .planning/debug/resolved/$s.md ]; then test ! -e .planning/debug/$s.md && grep -q '^status: resolved' .planning/debug/resolved/$s.md && grep -q '^resolved: 2026-09-12' .planning/debug/resolved/$s.md && grep -q 'RETROACTIVE CLOSURE (quick 260912-mxr' .planning/debug/resolved/$s.md && grep -Eq '[0-9a-f]{7}' .planning/debug/resolved/$s.md || { echo "FAIL resolved-shape $s"; exit 1; }; echo "RESOLVED $s"; else P=$(git status --porcelain -- .planning/debug/$s.md) || exit 1; test -f .planning/debug/$s.md && test -z "$P" && grep -q '^status: diagnosed' .planning/debug/$s.md || { echo "FAIL untouched $s"; exit 1; }; echo "HOLDS $s"; fi; done; test -z "$(printf '%s\n' "$L" | grep -v '^$' | grep -v '^\.planning/debug/')" && test -z "$S" && echo TASK2-OK</automated>
  </verify>
  <done>
    Every one of the four sessions is either (a) at .planning/debug/resolved/ with `status: resolved`,
    a `resolved:` date, a RETROACTIVE CLOSURE `fix:` naming landing plan + commit per root-cause
    component, a `verification:` with the executor's own file:line grep results, and a populated
    `files_changed:` list — or (b) untouched at .planning/debug/ with `status: diagnosed` and its
    holding evidence captured for the SUMMARY. No commit from this plan touches a path outside .planning/debug/.
  </done>
</task>

<task type="auto">
  <name>Task 3: Verify hashtags-not-visible, run the final scope gate, write the report</name>
  <files>.planning/debug/hashtags-not-visible.md, .planning/debug/resolved/hashtags-not-visible.md</files>
  <read_first>
    .planning/debug/hashtags-not-visible.md;
    .planning/milestones/v1.0-phases/01.3-game-detail-layout-content-accuracy/01.3-UAT.md (Test 1 note ~lines 22-30 and gap G-01.3-1 ~lines 170-186)
  </read_first>
  <action>
    1. Test the recorded root_cause against current code. It has two components: (i) the silent
       omission — `GameChips.editorial_tags/1` in lib/pukllay_club_web/components/game_chips.ex renders
       nothing when `game.tags == []` (look for the `:if={@tags != []}` guard and whether any
       placeholder / empty-state branch now exists); (ii) the narrow data mapping — `@editorial_columns`
       in lib/pukllay_club/catalog/seed/hashtag_normalizer.ex still lists exactly three columns
       (#CreaConexiones, #EquipoGanador, #DuelosMemorables). Record file:line output for both. Read-only;
       do not query the database.
    2. Apply the protocol strictly. If both components are still present (expected), the condition
       HOLDS: leave the file byte-unchanged at .planning/debug/ with `status: diagnosed`, do not
       git mv it. The user authorized not-a-bug closure only for no-disconnect-banner, so the 01.3
       product-decision acceptance does NOT license closing this file here. In the SUMMARY, report it
       under "Left diagnosed (condition still holds)" with both grep results, and add a one-line
       recommendation: 01.3-UAT.md gap G-01.3-1 already records `status: resolved` with
       `resolved_by: "product decision — accepted as intended, no code fix"` (2026-08-31), so the user
       can authorize an accepted-as-intended closure in the same shape as no-disconnect-banner if they
       want it off the deferred list.
       Only if a component is genuinely gone (e.g. a placeholder branch was added or the column mapping
       widened), resolve it with Task 2's GONE procedure (frontmatter, RETROACTIVE CLOSURE fix,
       evidence-backed verification, files_changed from `git show --stat` of the landing commit, git mv,
       commit subject `docs(debug): resolve hashtags-not-visible (260912-mxr)`).
    3. Final scope gate across the whole plan: confirm every commit whose message contains both
       `260912-mxr` and `docs(debug)` touches only `.planning/debug/` paths; confirm
       `git status --porcelain -- lib assets test config priv` is empty; confirm
       .planning/debug/whatsapp-og-image-preview.md and .planning/debug/knowledge-base.md show no diff
       and are not in any of this plan's commits; confirm none of the 13 `G-01*` session files were
       touched by this plan's commits (sibling item 260912-mxq owns them).
    4. SUMMARY content (written per the summary template at the output path below): a table of all 6
       sessions with columns session | verdict (resolved / not-a-bug / left diagnosed) | evidence
       (file:line) | landing plan + commit. Also note for the orchestrator, without editing it, that
       STATE.md's "Deferred Items" table still lists the now-resolved sessions as `diagnosed`
       (bookkeeping follow-up, out of this item's .planning/debug/-only scope).
  </action>
  <verify>
    <automated>L=$(git log --name-only --format= --all-match --grep='260912-mxr' --grep='docs(debug)') || exit 1; S=$(git status --porcelain -- lib assets test config priv .planning/debug/whatsapp-og-image-preview.md .planning/debug/knowledge-base.md) || exit 1; H=$(git status --porcelain -- .planning/debug/hashtags-not-visible.md) || exit 1; { if [ -f .planning/debug/resolved/hashtags-not-visible.md ]; then test ! -e .planning/debug/hashtags-not-visible.md && grep -q '^status: resolved' .planning/debug/resolved/hashtags-not-visible.md && grep -q 'RETROACTIVE CLOSURE (quick 260912-mxr' .planning/debug/resolved/hashtags-not-visible.md && echo "RESOLVED hashtags-not-visible"; else test -f .planning/debug/hashtags-not-visible.md && test -z "$H" && grep -q '^status: diagnosed' .planning/debug/hashtags-not-visible.md && echo "HOLDS hashtags-not-visible"; fi; } && test -z "$(printf '%s\n' "$L" | grep -v '^$' | grep -v '^\.planning/debug/')" && test -z "$(printf '%s\n' "$L" | grep -E 'whatsapp-og-image-preview|knowledge-base|/G-01')" && test -z "$S" && echo SCOPE-OK</automated>
  </verify>
  <done>
    hashtags-not-visible has a recorded verdict backed by its own file:line greps (expected: left
    untouched at diagnosed with the 01.3 product-decision closure recommended to the user); the scope
    gate passes (no lib/assets/test/config/priv change, whatsapp-og-image-preview.md, knowledge-base.md
    and all G-01* sessions untouched); SUMMARY contains the 6-row verdict table.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| planning record -> future planners/auditors | A `status: resolved` claim is trusted by milestone audits and the deferred-items scan; a false claim silently buries a live defect |
| bookkeeping task -> application tree | A docs-only task must not reach into shipped code |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-mxr-01 | Tampering | `.planning/debug/resolved/*.md` status/fix fields | medium | mitigate | Resolution requires executor-run file:line grep evidence per root-cause component plus a landing commit verified with `git show --stat`; any holding component forces the whole file to stay untouched (Task 2/3 protocol) |
| T-mxr-02 | Repudiation | not-a-bug closure of no-disconnect-banner | low | mitigate | `fix:` records the mechanism (DevTools Offline vs WebSockets), the UAT-procedure defect, the 01.7-UAT.md G-01.7-3 re-verification and commit 322b4bb; latent factors B/C recorded as still open so the closure cannot be read as fixing them |
| T-mxr-03 | Tampering | lib/, assets/, test/, config/, priv/ | medium | mitigate | Per-task and final automated scope gates: commits tagged `260912-mxr` + `docs(debug)` may list only `.planning/debug/` paths; `git status --porcelain` on app dirs must be empty; explicit path staging, never `git add -A` |
| T-mxr-04 | Information disclosure | debug session contents | low | accept | Files are already committed in a public repo; moving them within `.planning/debug/` changes no exposure |
</threat_model>

<verification>
- `ls .planning/debug/resolved/ | grep -E 'no-disconnect-banner|cierre-band-whitespace|hero-cta-isologo-balance|inter-band-whitespace-gap|lightbox-width-scrim-not-shell-width|hashtags-not-visible'` lists every session judged GONE or not-a-bug.
- Every session left at `.planning/debug/` still has top-level `status: diagnosed` and an empty `git status --porcelain` for its path.
- `git log --name-only --format= --all-match --grep='260912-mxr' --grep='docs(debug)'` lists only `.planning/debug/` paths and none of whatsapp-og-image-preview.md, knowledge-base.md, or any G-01* file.
- `git status --porcelain -- lib assets test config priv` is empty.
</verification>

<success_criteria>
- no-disconnect-banner closed as not-a-bug with the Chrome DevTools/WebSocket rationale recorded.
- Each of the other five sessions has an explicit, evidence-backed verdict; resolved files cite file:line evidence and the landing plan + commit; holding files are byte-unchanged.
- Zero application-code changes; out-of-scope debug files untouched.
- SUMMARY contains the 6-row verdict table and flags the stale STATE.md Deferred Items rows plus the hashtags product-decision closure option for the user.
</success_criteria>

<output>
Create `.planning/quick/260912-mxr-close-out-the-6-remaining-diagnosed-debug-sessions-in-planni/260912-mxr-SUMMARY.md` when done
</output>
