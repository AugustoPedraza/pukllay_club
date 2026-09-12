---
phase: quick-260912-rwv
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
files_modified:
  - assets/css/app.css
  - test/pukllay_club_web/live/catalog_show_test.exs
  - .planning/debug/creator-pill-touch-target.md
  - .planning/debug/resolved/creator-pill-touch-target.md
files_deleted:
  - .planning/debug/creator-pill-touch-target.md

must_haves:
  truths:
    - "Every pill that carries pk-pill-interactive (creator pills, Mecanicas/Tematicas links, masthead facts-row links, editorial hashtag links) renders at least 44px tall, because the `.pk-pill-interactive` rule itself declares `min-height: 44px` (user decision, option A)"
    - "A CSS-source regression test in catalog_show_test.exs fails if the top-level `.pk-pill-interactive` rule stops declaring a 44px minimum height"
    - "The interactive variant adds only a height FLOOR: it declares no fixed height, max height, width, padding or font-size, so pill widths and per-row wrapping are unchanged"
    - "Text stays vertically centred inside the taller pill for every tone, including the zero-vertical-padding hashtag tone, because the `.pk-pill` base keeps inline-flex + align-items:center and no tone overrides them"
    - "On /juegos/137 (Wingspan) at a 390px viewport the artist pills still wrap onto multiple rows with no horizontal overflow (document scrollWidth equals clientWidth)"
    - "The pre-existing pill tone-variant geometry gate (catalog_show_test.exs, G-01.2-26 task 2) still passes, and `mix quality` exits 0"
    - "The creator-pill-touch-target debug session has status resolved, fix/verification/files_changed filled, root_cause text unchanged, and lives at .planning/debug/resolved/creator-pill-touch-target.md (moved with git mv)"
    - "The WINDOWS ledger file (.planning/WINDOWS.md) is byte-identical to local main (this item's branch never touches it)"
  artifacts:
    - path: "assets/css/app.css"
      provides: "`.pk-pill-interactive` rule declaring `min-height: 44px` alongside its existing cursor + transition"
    - path: "test/pukllay_club_web/live/catalog_show_test.exs"
      provides: "New describe block pinning the interactive variant's 44px touch floor, its floor-only geometry, and the base's flex centring"
    - path: ".planning/debug/resolved/creator-pill-touch-target.md"
      provides: "Closed debug session with fix, verification (incl. live 390px measurements) and files_changed"
  key_links:
    - from: "assets/css/app.css `.pk-pill-interactive` rule"
      to: "every call site composing pk-pill-interactive (show.ex creator_pills/1, game_chips.ex chip_row/1 + editorial_tags/1, game_preview.ex facts_row/1)"
      via: "class token, no markup change"
      pattern: "min-height: 44px"
    - from: "catalog_show_test.exs new touch-floor describe block"
      to: "assets/css/app.css"
      via: "module-level css_source/0 helper (defined ~line 3514) + top-level rule regex"
      pattern: "pk-pill-interactive"
---

<objective>
Close WINDOWS #18: tappable pills on the game detail page render 26.5px tall (hashtags 23px),
under the project's 44px touch-target minimum. The root cause is already diagnosed in
.planning/debug/creator-pill-touch-target.md — do NOT re-investigate. Per the user-chosen fix
(option A), the 44px floor moves INTO the pill system's "tappable" variant: add
`min-height: 44px` to `.pk-pill-interactive` in assets/css/app.css. That single declaration fixes
creator pills, the Mecanicas/Tematicas links, the masthead facts row and the editorial hashtag
links at once, restoring sketch 036's interactive-chip contract that was dropped in the c33e7f1
port.

Purpose: every tappable pill meets the 44px touch floor by construction, so no future call site
can compose a sub-44px tappable pill by forgetting a per-call-site `min-h-11` utility.

Output: one scoped CSS declaration (+ provenance comment above the rule), one CSS-source
regression describe block, a live 390px geometry confirmation, and the resolved debug session.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md
@.planning/debug/creator-pill-touch-target.md

Project skills relevant to this item: `ui-design-system` (pill variant set, banned styling
patterns) and `ux-responsive` (44px touch floor). Load them before editing CSS.

Sibling batch item 260912-rwt also edits assets/css/app.css (nav drawer rules around lines
2800-2850). Items run in separate worktrees and merge sequentially, so keep this item's app.css
edit confined to the `.pk-pill-interactive` rule (~line 1232) and a comment directly above it.
Do not reflow, reformat or touch any other region of app.css.

## Interfaces the executor needs (extracted, do not re-derive)

assets/css/app.css pill system (lines ~1054-1252):
- `.pk-pill` base (~1054): display inline-flex; align-items center; gap 4px; white-space nowrap;
  border-radius 9999px; border 1px solid transparent; font-weight 600; font-size 11px;
  padding 4px 9px. No line-height, no min-height.
- `.pk-pill-tag` (~1111): background/border transparent, color primary, font-size 0.875rem,
  font-weight 400, padding 0 3px. Declares no display and no align-items.
- `.pk-pill-comfortable` (~1213), `.pk-pill-large` (~1225): size variants.
- `.pk-pill-interactive` (~1232): currently ONLY `cursor: pointer` + a `transition` on
  border-color/color. This is the rule to edit.
- `.pk-pill-interactive:hover` (~1249): border-color/color from `--pk-ink-brand`. Leave untouched.

Call sites composing `pk-pill-interactive` (markup NOT edited by this plan):
- lib/pukllay_club_web/live/catalog_live/show.ex:1254 creator_pills/1 (inside
  `div.pk-chip-row.flex.flex-wrap.gap-2`)
- lib/pukllay_club_web/components/game_chips.ex:107 chip_row/1 linked branch; :167
  editorial_tags/1 linked branch (inside `flex flex-wrap gap-1`)
- lib/pukllay_club_web/components/game_preview.ex:76/90/104 facts_row/1 links
- lib/pukllay_club_web/components/filter_modal.ex:534/538 and
  lib/pukllay_club_web/live/catalog_live/index.ex:1098 — already carry `min-h-11`; now redundant
  but LEAVE THEM IN PLACE (tests pin those class strings; removal is out of scope).

test/pukllay_club_web/live/catalog_show_test.exs:
- `defp css_source, do: File.read!(@css_path)` is defined at ~line 3514 inside a describe block;
  ExUnit `defp` is module-level, so later describe blocks (e.g. the 01.3-07 block at ~4612)
  already call `css_source()` directly. Reuse it — do not write a second CSS reader.
- Pattern to follow: the "pill system tone-variant geometry gate" describe at ~4576-4603 extracts a
  top-level rule body with `Regex.run(~r/(?m)^\.#{tone}\s*\{([^}]*)\}/s, src)` and `flunk`s with a
  clear message on `nil`.
- Class-string pins that must keep passing unchanged: line 58 (facts_row link class exact
  equality), line 2553 (chip_row linked branch regex). This plan changes no markup, so both stay
  green with no edits.
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Tracer — 44px floor on .pk-pill-interactive, pinned by a failing-first CSS-source test</name>
  <files>test/pukllay_club_web/live/catalog_show_test.exs, assets/css/app.css</files>
  <read_first>
    - .planning/debug/creator-pill-touch-target.md (Resolution root_cause + the 23:57 injected-min-height evidence entry — the proof this one declaration is sufficient)
    - assets/css/app.css lines 1017-1064 and 1206-1252 (pill-system governing comment, base, size variants, interactive rule)
    - test/pukllay_club_web/live/catalog_show_test.exs lines 3505-3520 (css_source/0) and 4571-4603 (tone-variant gate to mirror)
    - test/pukllay_club_web/stylesheet_integrity_test.exs lines 1-30 (why a stray comment terminator in CSS silently drops the next rule)
  </read_first>
  <behavior>
    - Test A: the top-level `.pk-pill-interactive { ... }` rule body (matched with a regex requiring `\s*\{` right after the class name so the `:hover` rule is never matched) declares `min-height: 44px`. Fails today (RED) because the rule declares only cursor + transition.
    - Test B: that same rule body declares no fixed `height`, no `max-height`, no `width` / `min-width` / `max-width`, no `padding`, no `font-size` — the interactive variant owns a height floor only, so pill widths and per-row wrapping cannot change (the structural half of the Wingspan 390px no-overflow requirement). Use lookbehind-anchored property regexes (for example `(?<![\w-])height\s*:`) so the required `min-height` declaration is not mistaken for a fixed height.
    - Test C: the top-level `.pk-pill` base rule declares `display: inline-flex` and `align-items: center`, and the top-level `.pk-pill-tag` rule declares neither `display` nor `align-items` — so text stays vertically centred inside the 44px floor for every tone, including the hashtag tone whose vertical padding is 0.
    - Each missing-rule case `flunk`s with a message naming the selector and assets/css/app.css, matching the tone-variant gate's style.
  </behavior>
  <action>
    RED: In test/pukllay_club_web/live/catalog_show_test.exs, add a new describe block placed immediately AFTER the existing "pill system tone-variant geometry gate" describe block (its closing `end` at ~line 4603) and before the 01.3-07 describe. Name it along the lines of "pill system interactive touch-target floor (WINDOWS #18, quick 260912-rwv)". Precede it with a short comment citing the debug session creator-pill-touch-target (26.5px creator/fact-grid pills, 23px hashtags), the user-chosen option A (floor lives on the variant, not per call site), and sketch 036's 44px interactive-chip contract. Implement Tests A, B and C from the behavior block using the module-level `css_source()` helper and the same `Regex.run(~r/(?m)^\.<selector>\s*\{([^}]*)\}/s, src)` extraction idiom as the tone-variant gate. Do NOT modify the tone-variant gate itself or its `@tone_variants` list — `.pk-pill-interactive` is a behaviour variant, not a tone, and the gate must keep passing untouched. Run the new tests and confirm Test A fails for the right reason (min-height absent) while B and C pass; commit the failing test as the RED step.

    GREEN: In assets/css/app.css, add exactly one declaration, `min-height: 44px;`, inside the existing top-level `.pk-pill-interactive` rule (~line 1232), keeping `cursor: pointer` and the `transition` declaration as they are. Per the user decision use the literal 44px value (not a rem value, not a Tailwind utility at the call sites). Add a brief provenance comment DIRECTLY ABOVE the rule (outside its braces, never inside the rule body, because Test B scans the body text): WINDOWS #18 / debug session creator-pill-touch-target, "tappable pill owns the 44px touch floor" (sketch 036 action chip, dropped in the c33e7f1 port), the call sites it now covers (creator_pills/1, chip_row/1 and editorial_tags/1 links, facts_row/1 links), and that vertical centring comes from the base's inline-flex + align-items. The comment must contain no brace characters and no premature comment terminator (the stylesheet_integrity_test hazard — e.g. never write a wildcard token immediately followed by a slash). Do not touch `.pk-pill-interactive:hover`, the pill-system governing comment, any tone or size variant, any call-site markup, the redundant `min-h-11` utilities on filter_modal.ex / index.ex, or any other region of app.css (sibling item 260912-rwt edits the drawer rules). Re-run the tests: all three new tests plus the tone-variant gate pass. Commit as the GREEN step.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && mix test test/pukllay_club_web/live/catalog_show_test.exs test/pukllay_club_web/stylesheet_integrity_test.exs</automated>
  </verify>
  <acceptance_criteria>
    - The new describe block exists after the tone-variant gate and its three tests pass; the tone-variant geometry gate test passes unmodified.
    - Test A was observed failing before the app.css edit (RED recorded in the SUMMARY) and passing after it.
    - Record the RED commit sha and the GREEN commit sha in the SUMMARY; `git diff <red_sha>^..<green_sha> -- assets/css/app.css` (explicit shas, never a relative anchor) shows only added lines, all located at the `.pk-pill-interactive` rule and the comment immediately above it.
    - stylesheet_integrity_test.exs passes (no comment-termination or brace-balance regression).
  </acceptance_criteria>
  <done>`.pk-pill-interactive` declares `min-height: 44px`; a CSS-source test pins the 44px floor, the floor-only geometry and the base's flex centring; catalog_show_test.exs and stylesheet_integrity_test.exs are green.</done>
</task>

<task type="auto">
  <name>Task 2: Full quality gate + live 390px geometry confirmation on /juegos/137 and /juegos/179</name>
  <files>(no repo files — measurement script lives in the executor's session scratchpad and is not committed)</files>
  <read_first>
    - test/visual/about_geometry.mjs lines 1-140 (zero-dependency Node + headless Chrome + CDP lifecycle and PROBE_BASE_URL convention to copy into a scratchpad probe)
    - .planning/debug/creator-pill-touch-target.md Evidence entries 23:55 and 23:57 (the exact measurements to reproduce: pill heights, row line counts, scrollWidth vs clientWidth)
  </read_first>
  <action>
    First run `mix quality` from the repo root (hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted, credo --strict, sobelow --config, test --warnings-as-errors). It must exit 0. If the new test file hunk trips `format --check-formatted`, run `mix format` on that test file only, review the diff, and amend; fix any credo --strict finding in the new describe block. Do not "fix" unrelated pre-existing failures — if one appears that this change did not cause, stop and report it.

    Then confirm the geometry live. Write a throwaway Node CDP probe in the executor's session scratchpad directory (never under the repo, never committed), reusing the Chrome-launch + CDP-client pattern from test/visual/about_geometry.mjs. Boot the worktree's own dev server so the CSS under test is this worktree's app.css: `PORT=4010 mix phx.server` in the background (the main checkout may already hold port 4000), wait for it to answer, and point the probe at it (or set PROBE_BASE_URL if you boot it yourself). Emulate a 390px-wide mobile viewport (Emulation.setDeviceMetricsOverride, mobile true). Measure:
    (1) /juegos/137 — confirm the page is Wingspan (h1 text); record every `a.pk-pill-interactive` getBoundingClientRect height (expect each >= 44, i.e. 44); record the artist ("Ilustradores") pill row: count of distinct pill top offsets (expect > 1, i.e. still wrapping onto multiple rows) and that every pill's right edge is within its `.pk-chip-row` container's right edge; record `document.documentElement.scrollWidth` and `clientWidth` (expect equal).
    (2) /juegos/179 — creator pills (Antoine Bauza, Bruno Cathala, Miguel Coimbra), Mecanicas/Tematicas links, facts-row links and the `#DuelosMemorables` hashtag link: heights (expect 44), and for the hashtag link its computed `display` (inline-flex) and `align-items` (center) plus that its text node's vertical midpoint is within 1px of the pill box's vertical midpoint.
    Record every measured number verbatim for Task 3. Stop the dev server when done. If the dev server or headless Chrome genuinely cannot run in this worktree (e.g. missing dev DB data), say so explicitly and record which measurements were not taken — do not report unmeasured values as passing.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && mix quality</automated>
  </verify>
  <acceptance_criteria>
    - `mix quality` exits 0 (all seven steps), with the test count recorded.
    - Live probe output shows: every `a.pk-pill-interactive` on /juegos/137 and /juegos/179 at 390px measures >= 44px tall; Wingspan artist pills occupy more than one row with no pill overflowing its row; scrollWidth == clientWidth on both pages; the hashtag link is inline-flex / align-items center with text centred.
    - No files under the repo were added by the probe (`git status --porcelain` shows only this plan's declared paths).
  </acceptance_criteria>
  <done>`mix quality` is green and live 390px measurements confirm 44px tappable pills with unchanged wrapping and no horizontal overflow, with raw numbers captured for the debug Resolution.</done>
</task>

<task type="auto">
  <name>Task 3: Resolve the creator-pill-touch-target debug session and git mv it to resolved/</name>
  <files>.planning/debug/creator-pill-touch-target.md, .planning/debug/resolved/creator-pill-touch-target.md</files>
  <read_first>
    - .planning/debug/creator-pill-touch-target.md (whole file — frontmatter, Current Focus, Specialist Review, Resolution)
    - .planning/debug/resolved/G-01-7-double-focus-ring.md lines 1-10 and its ## Resolution section (house style for a resolved session closed by a quick task)
  </read_first>
  <action>
    Edit .planning/debug/creator-pill-touch-target.md in place first, then move it:
    - Frontmatter: `status: diagnosed` becomes `status: resolved`; set `updated:` to the current ISO timestamp. Leave `trigger`, `created` and `goal` as they are.
    - Current Focus: set `next_action` to a one-line note that the session was closed by quick task 260912-rwv (option A applied); leave the reasoning_checkpoint content as recorded history.
    - Specialist Review: append a one-line note that the user chose option A (min-height on `.pk-pill-interactive`) over option B and the scoped middle option, and why (fixes every tappable-pill call site at once and restores sketch 036's contract).
    - Resolution: keep the existing `root_cause:` text byte-identical. Replace `fix: (not applied — diagnose-only)` with the applied fix — `min-height: 44px` added to the top-level `.pk-pill-interactive` rule in assets/css/app.css (closes AND-gate item 2, which makes item 1's missing per-call-site `min-h-11` moot for all current and future call sites); markup unchanged; the existing `min-h-11` utilities on filter_modal.ex / index.ex left in place as harmless redundancy; plus the new CSS-source regression describe block in catalog_show_test.exs (44px floor, floor-only geometry, base flex centring). Replace `verification:` with the Task 1 RED/GREEN result, the `mix quality` exit 0 + test count from Task 2, and Task 2's live 390px measurements verbatim (per-page pill heights, Wingspan artist row count, scrollWidth/clientWidth, hashtag centring) — or an explicit statement of any measurement that could not be taken. Note the remaining blind spot honestly: real-device tap behaviour and the developer's visual acceptance of the taller outline pills in the fact grid and masthead were not reviewed in this task. Replace `files_changed: []` with the list: assets/css/app.css, test/pukllay_club_web/live/catalog_show_test.exs. Optionally add a one-line follow-up note that the ux-responsive skill's "min-h-11 on every tappable pill" wording predates this variant-level floor (not edited here).
    - Then run `git mv .planning/debug/creator-pill-touch-target.md .planning/debug/resolved/creator-pill-touch-target.md` so history is preserved as a rename.
    Scope limits: do not edit .planning/WINDOWS.md (its rows are updated separately by the user), do not append to .planning/debug/knowledge-base.md (sibling batch items resolve their own sessions in parallel worktrees and a shared append would conflict at merge), and do not touch the other open debug sessions. Commit as a docs commit for this quick task.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && test -f .planning/debug/resolved/creator-pill-touch-target.md && test ! -e .planning/debug/creator-pill-touch-target.md && grep -q '^status: resolved$' .planning/debug/resolved/creator-pill-touch-target.md && git diff --exit-code main -- .planning/WINDOWS.md .planning/debug/knowledge-base.md</automated>
  </verify>
  <acceptance_criteria>
    - .planning/debug/resolved/creator-pill-touch-target.md exists with `status: resolved`; the original path no longer exists; `git show --name-status <docs_commit_sha>` (explicit sha recorded in the SUMMARY) lists the move as an R (rename) entry.
    - The Resolution section's root_cause text is unchanged; fix, verification and files_changed are filled with the concrete values above.
    - `git diff --exit-code main -- .planning/WINDOWS.md .planning/debug/knowledge-base.md` exits 0 (ledger and knowledge base untouched by this item's branch).
  </acceptance_criteria>
  <done>The debug session is closed with a complete, honest Resolution, lives under .planning/debug/resolved/ via git mv, and the WINDOWS ledger is untouched.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| none new | Static stylesheet declaration + ExUnit test + planning doc move. No new input, route, data flow, dependency or runtime code path crosses a trust boundary. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-rwv-01 | Tampering (integrity of the served stylesheet) | assets/css/app.css `.pk-pill-interactive` comment + rule | low | mitigate | A malformed comment (premature terminator or stray brace) would silently drop the next rule from the cascade. Comment is placed outside the rule body with no braces or terminator-like tokens, and stylesheet_integrity_test.exs runs in Task 1's verify and in `mix quality`. |
| T-rwv-02 | Denial of Service (usability: layout overflow on mobile) | Detail-page fact grid / masthead pills at 390px | low | mitigate | Test B pins that the variant declares no width/padding/font-size (widths cannot change); Task 2 live-measures scrollWidth == clientWidth and multi-row wrapping on /juegos/137 and /juegos/179. |
| T-rwv-03 | Information Disclosure | .planning/debug/resolved/creator-pill-touch-target.md (public repo) | low | accept | Content is local-dev URLs, CSS measurements and file paths only; the probe script and any screenshots stay in the session scratchpad and are never committed. No secrets involved. |
</threat_model>

<verification>
- `mix test test/pukllay_club_web/live/catalog_show_test.exs test/pukllay_club_web/stylesheet_integrity_test.exs` passes, including the new touch-floor describe block and the unmodified tone-variant geometry gate.
- `mix quality` exits 0.
- Live 390px probe: all `a.pk-pill-interactive` on /juegos/137 and /juegos/179 measure 44px; Wingspan artist pills wrap on multiple rows; no horizontal overflow.
- `git diff --exit-code main -- .planning/WINDOWS.md` exits 0.
- The app.css diff is confined to the `.pk-pill-interactive` rule and its preceding comment.
</verification>

<success_criteria>
- WINDOWS #18's failing measurement (26.5px creator pills, 23px hashtag) is replaced by 44px for every tappable pill, via one declaration on `.pk-pill-interactive` (option A).
- A CSS-source regression test guards the 44px floor going forward.
- Wingspan artist pills still wrap cleanly at 390px with no horizontal overflow.
- `mix quality` passes.
- Debug session creator-pill-touch-target is resolved and moved to .planning/debug/resolved/ with git mv.
- WINDOWS.md rows untouched.
</success_criteria>

<output>
Create `.planning/quick/260912-rwv-fix-windows-18-tappable-pills-under-44px-read-the-diagnosed/260912-rwv-SUMMARY.md` when done
</output>
