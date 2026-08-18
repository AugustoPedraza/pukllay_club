---
phase: quick-260818-jpm
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - docs/ux-patterns.md
autonomous: true
requirements: [QUICK-260818-jpm]

estimate:
  tokens: 60000
  raw_tokens: 60000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "docs/ux-patterns.md contains five new reference-point entries B28-B32 appended after E27, each following the existing `**Default** / **Flips when** / **Why** / **Source**` bullet format"
    - "Every external claim in B28-B32 traces to a URL fetched during this pass and listed in the source ledger, or is explicitly marked unreachable with the attempted URLs and their HTTP outcome"
    - "A new section F states plainly which patterns need a JS hook, that the device target is ambiguous, and that the app is not a PWA — each answer citing concrete repo file paths"
    - "No entry numbered A1-E27 is renumbered, deleted, or rewritten; the only change to an existing entry is one appended bullet on E27"
    - "No file other than docs/ux-patterns.md is modified"
  artifacts:
    - docs/ux-patterns.md
  key_links:
    - "B28-B32 `**Source:**` bullets -> source ledger rows 1/8/9/10 (citation integrity: nothing cited that was not fetched this pass)"
    - "B31 -> B6 and B32 -> B8 cross-references (new named reference points extend the existing general rules rather than restating them)"
    - "F33/F34/F35 claims -> concrete repo file paths and line numbers (each answer is checkable against the codebase, not asserted)"
---

<objective>
Extend `docs/ux-patterns.md` with five new named reference points (B28-B32) and a new final
section F that answers three project-specific questions: which patterns translate cleanly to
LiveView, what device this app actually targets, and whether PWA concerns are in scope.

Purpose: the doc currently answers 27 general UX questions from eight design systems but names no
concrete product implementations for dense lists, master/detail, or mobile nav, and says nothing
about how any of it maps onto this codebase's actual stack and constraints.

Output: `docs/ux-patterns.md` grows by five sourced entries plus one answers section, with the
source ledger updated to record every URL newly read and every URL newly attempted and failed.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@docs/ux-patterns.md
@.claude/skills/ui-design-system/SKILL.md
</context>

<house_rules>
These are the doc's own conventions, already established by entries A1-E27. Every task below is
bound by all six:

1. **Behavior only.** Interaction, timing, keyboard, state transitions, breakpoint thresholds.
   Never visual styling, palette, or branding opinions — `.claude/skills/ui-design-system/SKILL.md`
   owns the visual layer and this doc must not restate or override it. The one exception is
   section F, which may name layout utility classes purely as *evidence of what the repo does*,
   never as a recommendation.
2. **Nothing from memory.** Every factual claim about an external product or design system must be
   traceable to a page fetched during this pass, or the entry must say `unreachable` and record
   exactly which URLs were attempted and what each returned.
3. **Cross-reference, do not repeat.** Point at existing entries by ID (`see B6`, `see B8`,
   `see B12/B15`) instead of restating their content.
4. **Append only.** New entries go after E27. Do not renumber, reorder, delete, or rewrite any
   existing entry. The single permitted edit to an existing entry is one appended bullet on E27
   (Task 3). The source ledger table and the intro sentence's source count are also updated.
5. **Record disagreements.** Where a new source contradicts an entry already in the doc, add a
   trailing `**Disagreement:**` bullet naming both sides and citing both — this is an existing
   convention (see B10, B13, C17, C20).
6. **WebSearch is disabled in this session.** Use WebFetch against the exact URLs given below.
   Do not go hunting for substitutes; if a given URL fails, record the failure per rule 2 rather
   than swapping in an unverified one.
</house_rules>

<numbering_decision>
The five new entries are numbered **B28-B32**, continuing the doc's global number sequence after
E27 while keeping the `B` topic tag (component interaction), which is what all five are about.
They are physically appended after E27 under a new heading
`## Named reference points (B28-B32 extend section B)`, because the answers section is explicitly
`## F.` and cannot be displaced. The `<letter><number>` ID stays globally unique and
cross-referenceable, which is what the doc's existing `see B6` / `see B8` references rely on.

The three answers in section F are numbered **F33-F35**, continuing the same number sequence. They
use a different bullet shape than A1-B32 (`**Answer** / **Evidence** / **Implication**) because
they are project answers sourced from this repo, not recommendations sourced from a design system.
</numbering_decision>

<tasks>

<task type="tracer">
  <name>Task 1: One entry end-to-end — fetch Linear, add ledger row, write B28</name>
  <files>docs/ux-patterns.md</files>
  <read_first>
    Read `docs/ux-patterns.md` in full first. Match its existing entry format exactly: each entry
    is `### <letter><number>. <Title>` followed by `- **Default:**`, `- **Flips when:**`,
    `- **Why:**`, `- **Source:**` bullets, wrapped at roughly 100 columns, with an optional
    trailing `- **Disagreement:**` bullet.
  </read_first>
  <action>
Prove the whole shape on one entry before expanding: fetch a source, record it in the ledger, and
write the entry that cites it.

**Step 1 — fetch.** WebFetch `https://linear.app/docs/select-issues`, asking for the documented
keyboard and mouse behavior for navigating and selecting issues in the list, plus any documented
way to change an issue property from the list. This URL was confirmed reachable during planning;
capture the exact shortcut keys and quoted wording from the live page rather than reusing the
summary below verbatim. Note that `https://linear.app/docs/keyboard-shortcuts` returns HTTP 404 —
do not cite it.

Planning confirmed the page documents: navigation with the up/down arrows or `J` / `K`; `X` to
select a highlighted issue; holding `Shift` and clicking to select with the mouse; checkboxes
revealed by hovering near a row's left edge; holding `Shift` then using the arrow keys to extend
the selected range one issue at a time; `Cmd/Ctrl` `A` to select all issues in a list or board;
`Esc` to clear the selection; and `Cmd/Ctrl` `K` to open the command bar (or right-click) to act
on the selection. Critically, it documents **no** click-to-edit-in-place shortcut — property
changes on a selected row route through the command bar or context menu.

**Step 2 — ledger.** Add a new row `9` to the source ledger table for Linear docs, listing the
pages read (`https://linear.app/docs` and `https://linear.app/docs/select-issues`) with status
`read`. Then update the intro paragraph's source count so it matches the ledger's actual row
count once Task 2 finishes adding row 10 — write it as `ten` (Linear is 9, Microsoft Learn is 10),
and keep the intro's existing note that some ledger rows are unreachable accurate.

**Step 3 — write B28.** Under a new heading `## Named reference points (B28-B32 extend section B)`
placed immediately after E27, write:

`### B28. Dense list rows — Linear's issue list navigation, selection, and property editing`

- **Default:** keyboard-first navigation and selection over a dense list, with property changes
  routed through a command bar rather than a modal or a click-to-edit field. Quote the fetched
  shortcut set (arrow keys / `J` / `K` to move, `X` to select, `Shift`-click, `Shift`+arrows to
  extend a range, `Cmd/Ctrl` `A` for all, `Esc` to clear, `Cmd/Ctrl` `K` for the command bar).
- **Flips when:** the user is a pointer user who does not know the shortcuts — the same selection
  model stays reachable via checkboxes revealed on hover near the row's left edge. Note that this
  is a hover-revealed affordance, which C16 already flags as undiscoverable on touch devices.
- **Why:** a dense list is scanned far more often than it is clicked, so binding navigation and
  selection to keys keeps the hand off the pointer for the common case; routing actions through a
  command bar also means the row itself does not have to carry a visible control per action
  (see C19 and D22 on per-row and per-toolbar action caps).
- **Source:** [Linear — Select issues](https://linear.app/docs/select-issues)
- **Disagreement:** B10 records Atlassian's inline edit as a component that "switches between
  reading and editing on the same page." Linear's documented path for changing a property on a
  selected row is the command bar or context menu — the user stays on the list either way, but
  Linear's transition is list -> transient overlay -> committed change, not an in-place field
  swap. Report this honestly: the fetched page documents no click-to-edit-in-place behavior, so
  do not describe one.

Do not invent inline-edit behavior that the fetched page does not document. If the live fetch
contradicts any detail summarized above, the live fetch wins and the entry records what was
actually read.
  </action>
  <verify>
    <automated>grep -q '^### B28\.' docs/ux-patterns.md && test "$(grep -c 'linear\.app/docs/select-issues' docs/ux-patterns.md)" -ge 2 && awk '/^### B28\./{f=1} f' docs/ux-patterns.md | grep -q '^- \*\*Source:\*\*' && echo PASS</automated>
  </verify>
  <done>
    B28 exists after E27 under the new heading, cites a URL that also appears as a new ledger row
    9 with status `read`, carries a Disagreement bullet against B10, and describes only behavior
    the live fetch actually documented. The intro's source count reads `ten`.
  </done>
</task>

<task type="auto">
  <name>Task 2: Expand to B29-B32 and finish the source ledger</name>
  <files>docs/ux-patterns.md</files>
  <action>
Write the remaining four entries in the same shape B28 proved, then close out the ledger.

**B29 — forms reference point (no new fetch).**
`### B29. Forms — GOV.UK is this doc's reference point`
This is an index entry, not a new recommendation. State that GOV.UK is the forms reference point
and route to the two answers already recorded: **B12** (validate after the action has been taken,
1-2 sentences giving the reason and the next step) and **B15** (one question per page, with a back
link, a page heading, and a continue button). Do **not** restate their content and do **not**
re-fetch the GOV.UK validation or question-pages URLs — they are already ledger row 4. For the
`**Flips when:**` bullet, say plainly that it does not apply because this is an index entry, and
point out that where GOV.UK conflicts with another system the conflict is already written up on
the entry itself (the Disagreement bullets on B10 and C17 are both GOV.UK-vs-other-system).
`**Source:**` is `_no new page fetched_ — see ledger row 4 for the pages behind B12 and B15`.

**B30 — empty states, unreachable.**
`### B30. Empty states and onboarding — Shopify Polaris (unreachable)`
First make a genuine retry: WebFetch `https://polaris.shopify.com/patterns`. Planning confirmed it
returns HTTP 301 to `https://shopify.dev/docs/api/polaris`; fetch that redirect target too.
Planning confirmed the target renders successfully but documents only app surfaces (App Home,
Admin / Checkout / Customer-account / POS UI extensions) with no empty-state pattern or guidance.
Planning also confirmed `https://polaris.shopify.com/components/layout-and-structure/empty-state`
returns the same HTTP 301 to the same page. Repeat both attempts live.

Record the outcome honestly. The `**Default:**` bullet says the question is unresolved and that no
default is recorded because no source could be fetched; `**Flips when:**` and `**Why:**` say the
same in one line each. The `**Source:**` bullet is the substance: mark it `unreachable` and list
each URL attempted, the HTTP status it returned, and what the redirect target actually contained.
State explicitly that nothing about empty states is recorded here from memory. If the live retry
unexpectedly succeeds and real empty-state guidance is reachable, write a normal sourced entry
instead and drop the unreachable framing.

**B31 — master/detail, a named implementation on top of B6.**
`### B31. Master/detail in practice — Microsoft's list/details pattern`
WebFetch `https://learn.microsoft.com/en-us/windows/apps/design/controls/list-details` (confirmed
reachable and fully rendered during planning; note the singular `list-detail` variant returns HTTP
404). Planning confirmed it documents: "When an item in the list is selected, the details pane is
updated"; a side-by-side style where "the list in the list pane has a selection visual to indicate
the currently selected item" and "selecting a new item in the list updates the details pane"; a
stacked style where "only one pane is visible at a time," the user "starts at the list pane and
'drills down' to the details pane by selecting an item in the list," and "to the user, it appears
as though the list and details views exist on two separate pages," with back-navigation handled by
real page-level navigation history; a stated width threshold of 320-640 epx stacked versus 641 epx
or wider side-by-side; and a stated fit for "an email app, address book, or any app that is based
on a list-details layout" and for "working back-and-forth between contexts."

Build the entry on that: `**Default:**` covers the selection-updates-detail-pane behavior in both
styles and the drill-down/back behavior in stacked mode; `**Flips when:**` is the width threshold;
`**Why:**` is that the side-by-side form exists so repeated selection does not cost a navigation
each time. Add a `**Disagreement:**` bullet against **B6**: both agree the rule is keyed to width
and that narrow means drill-down while wide means two panes, but B6 records Material 3 holding a
single pane through compact and medium and only recommending two panes at 840dp+, whereas
Microsoft switches at 641 epx — roughly 200 units earlier. Do not re-derive B6's general rule;
reference it.

**B32 — mobile navigation, one shape picked and justified.**
`### B32. Mobile navigation — visible tab bar over hamburger/drawer, and when that flips`
WebFetch `https://www.nngroup.com/articles/mobile-navigation-patterns/` (confirmed reachable
during planning; NN/g is already ledger row 8, so this is a new page on an existing row). Planning
confirmed it documents: a navigation menu "makes the navigation options least discoverable" and
"out of sight is out of mind"; opening one costs a decision because "users will have to make a
decision to open it and check whether the individual navigation options are relevant"; a tab bar
is "always visible on the screen, whether the user scrolls down the page or not," while a
navigation bar "typically disappear[s] when scrolled"; "tab bars and navigation bars are well
suited for sites with relatively few navigation options. If your site has more than 5 options,
it's hard to fit them in a tab or navigation bar"; and a hidden menu "can contain a fairly large
number of navigation options in a tiny space and can also easily support submenus."

Pick the **visible tab bar** and justify the pick from that evidence: it wins on discoverability
and on interaction cost below about five destinations. `**Flips when:**` is the destination count
exceeding what a bar can hold, plus the caveat that a bar which scrolls away forfeits the
persistence argument that justified choosing it. Cross-reference **B8** for the breakpoint-keyed
swap between a bottom bar and a rail and state explicitly that this entry only picks the mobile
shape, it does not re-derive when to swap it.

**Ledger and attempt log.** Update the source ledger table:
- Row 1 (Shopify Polaris): append the two URLs retried this pass and note that both returned HTTP
  301 to `https://shopify.dev/docs/api/polaris`, which was fetched and contains no pattern
  content. Status stays `unreachable`.
- Row 8 (NN/g): append `https://www.nngroup.com/articles/mobile-navigation-patterns/`. Status
  stays `read`.
- New row 10: Microsoft Learn, `https://learn.microsoft.com/en-us/windows/apps/design/controls/list-details`,
  status `read`.

Then add a short bulleted note directly beneath the ledger table headed
`**Attempted this pass and not usable:**` recording, with what each returned, the URLs that were
tried and produced no citable content: the Linear keyboard-shortcuts page (HTTP 404), the singular
Microsoft `list-detail` URL (HTTP 404), the Gmail reading-pane support page
`https://support.google.com/mail/answer/187605` (HTTP 404), and the pages that returned a title
with no rendered body and so could not be quoted —
`https://developer.apple.com/design/human-interface-guidelines/split-views`,
`https://developer.apple.com/design/human-interface-guidelines/sidebars`, and
`https://m3.material.io/components/navigation-bar/guidelines`. This note is why B31 is sourced
from Microsoft Learn rather than from a named consumer mail client, and it keeps the doc's
honesty convention intact.
  </action>
  <verify>
    <automated>test "$(grep -cE '^### B(29|30|31|32)\.' docs/ux-patterns.md)" -eq 4 && test "$(awk '/^### B28\./{f=1} /^## F\./{f=0} f' docs/ux-patterns.md | grep -c '^- \*\*Source:\*\*')" -ge 5 && ! awk '/^### B28\./{f=1} /^## F\./{f=0} f' docs/ux-patterns.md | grep -qE '#[0-9a-fA-F]{6}|bg-|text-\[' && test "$(grep -c 'learn\.microsoft\.com/en-us/windows/apps/design/controls/list-details' docs/ux-patterns.md)" -ge 2 && test "$(grep -c 'nngroup\.com/articles/mobile-navigation-patterns' docs/ux-patterns.md)" -ge 2 && echo PASS</automated>
  </verify>
  <done>
    B29-B32 exist in the doc's exact format; all five new entries carry a Source bullet; B30 is
    marked unreachable with every attempted URL and its HTTP outcome recorded; B31 and B32 each
    carry a working cross-reference to B6 and B8 respectively; the ledger has ten rows plus an
    attempt-log note; and no hex value or layout utility class appears anywhere in B28-B32.
  </done>
</task>

<task type="auto">
  <name>Task 3: Write section F answers and scope E27</name>
  <files>docs/ux-patterns.md</files>
  <action>
Append `## F. Answers — LiveView fit, device target, PWA scope` after B32, containing three
entries in an `**Answer:** / **Evidence:** / **Implication:**` bullet shape. These answers are
sourced from this repository, not from a design system, so every claim cites a file path (and a
line number where useful). All three findings below were verified during planning against the
working tree — re-confirm any line number that has drifted, but do not re-derive the conclusions.

`### F33. Which patterns translate cleanly to LiveView, and which need a JS hook`

- **Answer:** most of the interaction patterns in this doc translate to plain LiveView with a
  server round-trip per interaction. Two do not: rapid keyboard row navigation, and anything that
  advances on a clock.
- **Evidence — translates cleanly:**
  - The view-to-edit toggle shape behind B28 and B10 is `phx-click` plus assign-driven conditional
    rendering; no client state is needed. Already proven in this repo:
    `CatalogLive.Show.handle_event("select-image", ...)` swaps `@selected_image` on a server
    round-trip per click (`lib/pukllay_club_web/live/catalog_live/show.ex`), and `FilterDrawer`'s
    facet pills do the same via `phx-click` with `phx-value-facet` / `phx-value-value`
    (`lib/pukllay_club_web/components/filter_drawer.ex`).
  - Drawer and master/detail panel open-close (B31) needs neither LiveView nor JS: `FilterDrawer`
    holds its open state in a bare checkbox input driven by daisyUI's drawer classes
    (`lib/pukllay_club_web/components/filter_drawer.ex`), so the transition is pure CSS.
  - Mobile nav open-close (B32) is the same mechanism as that drawer — no hook.
  - Debounced search-as-you-type (B14) already works without a hook: the catalog search input
    carries `phx-debounce="300"` (`lib/pukllay_club_web/live/catalog_live/index.ex`).
- **Evidence — needs a client-side JS hook:**
  - B28's arrow-key / `J` / `K` row navigation is the latency-sensitive case. A server round-trip
    per keypress would feel laggy during rapid navigation, so the highlighted-row state has to be
    held client-side in a hook, contacting the server only on an actual selection or edit commit —
    not on every key.
  - Carousel auto-advance and pacing (B9), and any timed animation, need a hook because LiveView
    has no client-side timer primitive of its own.
- **Implication:** the split falls on whether the user is already waiting. An interaction whose
  result the user waits for anyway (a click that changes content) tolerates a round-trip; an
  interaction the user expects to be instantaneous and repeats rapidly (held or repeated
  keypresses, clock-driven motion) does not.

`### F34. Device target — ambiguous, leaning mobile-considered rather than desktop-primary`

- **Answer:** ambiguous, and not committed either way yet. State this plainly; do not force a pick.
- **Evidence for mobile-considered:** the catalog card grid is mobile-first — a two-column grid is
  the base, scaling up at the `sm` and `lg` breakpoints, rather than a desktop base scaled down
  (`lib/pukllay_club_web/live/catalog_live/index.ex`). Touch targets are explicitly sized to a
  44px minimum — matching the Apple HIG figure recorded in C20 — on both the filter-drawer trigger
  button and every facet pill (`lib/pukllay_club_web/components/filter_drawer.ex`). The detail
  page's thumbnail strip is a horizontally scrolling swipe strip rather than a wrapping grid
  (`lib/pukllay_club_web/live/catalog_live/show.ex`).
- **Evidence it is not committed:** there is no dedicated mobile navigation at all — no bottom bar
  and no hamburger. `Layouts.app`'s header is a single navbar whose only breakpoint-dependent
  change is horizontal padding (`lib/pukllay_club_web/components/layouts.ex`), so the nav shape
  never swaps, which is exactly what B8 and B32 describe doing. And no desktop split-pane layout
  exists: the detail page is a single centred column at every viewport
  (`lib/pukllay_club_web/live/catalog_live/show.ex`), so the two-pane branch of B6 and B31 has
  never been built.
- **Implication:** do not resolve this by assumption. B6/B31 (master/detail) and B8/B32 (nav
  shape) both need a device-target answer before either can be implemented, and that answer is not
  in the code yet.

`### F35. PWA scope — no, and section E is scoped to responsive web only`

- **Answer:** no. This is not a PWA and nothing in the repo is building toward one.
- **Evidence (verified against the working tree this pass):** no `manifest.json` and no
  `.webmanifest` file exists anywhere in the repository — searched by filename across the whole
  tree excluding `deps`, `_build`, and `node_modules`, zero hits. No service worker is registered:
  `assets/js/` contains no occurrence of `serviceWorker`, zero hits. And the document head in
  `lib/pukllay_club_web/components/layouts/root.html.heex` contains only a charset meta, a
  viewport meta, a CSRF-token meta, the live title, one stylesheet link, and two script tags — it
  carries no manifest link element and no theme-colour meta tag.
- **Implication:** scope section E to responsive web only for now. E24 (breakpoints), E25 (touch
  versus pointer) and E26 (safe areas) remain valid general responsive-web guidance and apply
  today. E27 (PWA offline state, install prompt, splash, standalone-mode differences) is out of
  scope until a manifest and a service worker actually exist here — do not build UI against it
  prematurely.

**Finally, append exactly one bullet to E27** — appended at the end of its existing bullet list,
changing none of its existing bullets and leaving its heading untouched:

`- **Scope:** out of scope for this repo until a web app manifest and a service worker actually
exist — see F35. The two sources added in this pass (Linear docs, Microsoft Learn) likewise carry
no PWA install, offline, or standalone-mode guidance, so E27's original finding is unchanged.`

Then re-read the whole file once and confirm that every entry heading from A1 through E27 is
byte-identical to what it was before this plan started, and that nothing in section F reads as a
styling or palette recommendation — the layout utilities named there are cited strictly as
evidence of what the repo currently does.
  </action>
  <verify>
    <automated>grep -q '^## F\. Answers' docs/ux-patterns.md && test "$(grep -cE '^### F(33|34|35)\.' docs/ux-patterns.md)" -eq 3 && grep -q '^- \*\*Scope:\*\*' docs/ux-patterns.md && grep -q 'root\.html\.heex' docs/ux-patterns.md && grep -q 'phx-debounce' docs/ux-patterns.md && test "$(grep -cE '^### [A-E][0-9]+\.' docs/ux-patterns.md)" -eq 32 && test "$(git diff -- docs/ux-patterns.md | grep -c '^-### ')" -eq 0 && echo PASS</automated>
    <human-check>Skim B28-B32 and section F for tone drift: no palette, colour, or branding opinion anywhere, and every external claim either carries a live URL or is explicitly marked unreachable.</human-check>
  </verify>
  <done>
    Section F exists with F33, F34 and F35; each cites concrete repo paths; F34 states the
    ambiguity plainly without forcing a pick; F35 states plainly that the app is not a PWA and
    scopes E to responsive web only; E27 has exactly one appended Scope bullet and is otherwise
    untouched; the doc holds 32 lettered A-E entries and the diff removes no existing heading.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| external web -> doc content | WebFetch pulls third-party page content that is then quoted into a repo-tracked file |
| planner assertion -> doc claim | Findings summarized in this plan are restated as sourced claims in a durable reference doc |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-jpm-01 | Spoofing | WebFetch source attribution | medium | mitigate | Every entry cites the exact URL fetched and its ledger row; B30 records the HTTP 301 chain rather than citing the redirect target as if it were the original page |
| T-jpm-02 | Tampering | `docs/ux-patterns.md` existing entries | medium | mitigate | Task 3's automated gate asserts the diff removes no `###` heading and that exactly 32 lettered A-E entries remain, so no existing entry can be silently renumbered or dropped |
| T-jpm-03 | Information disclosure | repo paths quoted in section F | low | accept | Only public source paths and public Tailwind utility names are quoted; no secrets, env vars, or credentials are referenced. The repo is already public (00-03 D-19) |
| T-jpm-04 | Repudiation | unverifiable "from memory" claims | high | mitigate | House rule 2 plus the B30 unreachable convention force every claim to be either URL-backed or explicitly marked as failed, with the attempt log recording each failed URL and its status |
| T-jpm-SC | Tampering | package installs | n/a | accept | No package-manager install occurs in this plan — it modifies one markdown file and runs no dependency resolution |
</threat_model>

<verification>
- `docs/ux-patterns.md` is the only file changed: `git status --porcelain` lists no other path.
- Five new entries B28-B32 exist after E27; three new answers F33-F35 exist after them.
- The source ledger has ten rows; rows 9 and 10 are new; rows 1 and 8 gained URLs; a
  `**Attempted this pass and not usable:**` note sits beneath the table.
- Every `**Source:**` bullet in B28-B32 either names a URL that appears in the ledger with status
  `read`, or is marked `unreachable` with the attempted URLs and their HTTP outcomes.
- B29 cites no new URL and routes to B12/B15 by ID; B31 cross-references B6; B32 cross-references
  B8; B28 carries a Disagreement bullet against B10; B31 carries one against B6.
- No entry A1-E27 is renumbered or rewritten; E27 gained exactly one appended bullet.
- No hex value and no layout utility class appears in B28-B32.
</verification>

<success_criteria>
- `docs/ux-patterns.md` answers the five new reference-point questions and the three project
  questions, in the doc's existing voice and format.
- A reader can trace every external claim to a fetched URL or to an explicit, itemized fetch
  failure — nothing is assertable only on trust.
- A reader can trace every section F claim to a file in this repo.
- The doc still defers to `.claude/skills/ui-design-system/SKILL.md` on anything visual, and adds
  no styling opinion of its own.
</success_criteria>

<output>
Create `.planning/quick/260818-jpm-add-linear-gov-uk-shopify-master-detail-/260818-jpm-SUMMARY.md` when done
</output>
