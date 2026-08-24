---
phase: quick-260818-jpm
plan: 01
subsystem: docs
tags: [ux-reference, documentation, research]
status: complete
dependency-graph:
  requires: [docs/ux-patterns.md (existing A1-E27 entries)]
  provides: [docs/ux-patterns.md B28-B32, docs/ux-patterns.md F33-F35]
  affects: []
tech-stack:
  added: []
  patterns:
    - "Live-fetch-then-cite reference doc convention (WebFetch/curl against exact URLs, ledger row per source, unreachable sources recorded with HTTP outcome rather than silently omitted)"
key-files:
  created: []
  modified:
    - docs/ux-patterns.md
decisions:
  - "WebFetch tool unavailable to this executor; substituted curl (with a browser User-Agent) + a small Python HTML-to-text strip for every live fetch in this pass. Functionally equivalent to WebFetch for this task's purpose (retrieve and quote live page content) and satisfies house rule 6/2 (nothing from memory, every claim traced to a page actually fetched this pass) — all 12 URLs named in the plan were fetched or retried live via curl, with HTTP status codes captured for each."
  - "B31/Microsoft Learn: the plan's URL (.../design/controls/list-details) issues a 301 to a newer path (.../develop/ui/controls/list-details) but still returns HTTP 200 with full content; treated as the same 'confirmed reachable' source the plan described, not a new unreachable case."
  - "B32 quotes were adjusted to the NN/g article's exact live wording where it differed from the plan's paraphrase (e.g. navigation-bar scroll-away behavior), per house rule 2's live-fetch-wins clause."
metrics:
  duration: ~35min
  completed: 2026-08-18
actuals:
  tokens: 4636
  tasks: 3
  commits: 3
---

# Phase quick-260818-jpm Plan 01: Add Linear/GOV.UK/Shopify/Microsoft/NN.g reference points + LiveView-fit answers Summary

Extended `docs/ux-patterns.md` with five new named reference points (B28-B32: Linear dense-list
selection, a GOV.UK forms index entry, an unreachable Shopify Polaris empty-states entry,
Microsoft's list/details pattern, and NN/g's mobile-navigation guidance) and a new closing
section F answering three project-specific questions about LiveView fit, device target, and PWA
scope — each answer citing concrete repo file paths rather than the eight external design systems
the rest of the doc draws from.

## What Was Built

- **B28 — Dense list rows (Linear).** Fetched `linear.app/docs/select-issues` live; documents
  arrow/`J`/`K` navigation, `X` to select, `Shift`-click, hover-revealed checkboxes, `Shift`+arrow
  range extension, `Cmd/Ctrl A` select-all, `Esc` clear, and `Cmd/Ctrl K` command bar for property
  changes. Carries a Disagreement bullet against B10 (Atlassian inline-edit): Linear routes
  property changes through the command bar/context menu, not an in-place field swap.
- **B29 — Forms (GOV.UK, index entry).** No new fetch; routes to existing B12 (validate-after-
  action) and B15 (one-question-per-page) by ID, per house rule 3 (cross-reference, don't repeat).
- **B30 — Empty states (Shopify Polaris, unreachable).** Retried both
  `polaris.shopify.com/patterns` and `.../components/layout-and-structure/empty-state` live; both
  return HTTP 301 to `shopify.dev/docs/api/polaris`, which renders (HTTP 200) but documents only
  app surfaces (App Home, Admin, Checkout, Customer accounts, POS) with zero empty-state guidance.
  Recorded as `unreachable` with the full attempt chain, not filled in from memory.
- **B31 — Master/detail in practice (Microsoft Learn).** Fetched the list/details pattern page
  live; documents selection-updates-detail-pane behavior in both side-by-side and stacked styles,
  drill-down/back navigation in stacked mode, and a 320-640 epx (stacked) vs 641+ epx (side-by-
  side) width threshold. Carries a Disagreement bullet against B6: Material 3 switches to two
  panes at 840dp+, Microsoft at 641 epx — roughly 200 units earlier.
- **B32 — Mobile navigation (NN/g).** Fetched the mobile-navigation-patterns article live; picks
  the visible tab bar over a hamburger/drawer menu below ~5 destinations on discoverability and
  interaction-cost grounds, cross-references B8 for the breakpoint-keyed bar-vs-rail swap.
- **Section F — LiveView fit / device target / PWA scope.** Three project-specific answers, each
  citing concrete repo paths and line-level evidence (`CatalogLive.Show`/`.Index`, `FilterDrawer`,
  `Layouts.app`, `root.html.heex`): F33 says most patterns need only a server round-trip except
  rapid keyboard row-nav and clock-driven motion, which need a JS hook; F34 states the device
  target is genuinely ambiguous (mobile-first grid/touch-targets exist, but no nav-shape swap and
  no split-pane layout have been built); F35 confirms the app is not a PWA (no manifest, no
  service worker, no manifest/theme-color meta tags) and scopes E27 accordingly.
- **Ledger and attempt log.** Source ledger grew from 8 to 10 rows (Linear docs, Microsoft
  Learn); row 1 (Shopify) and row 8 (NN/g) gained the new URLs attempted/read this pass; a new
  "Attempted this pass and not usable" note records four dead ends with their HTTP outcomes
  (Linear keyboard-shortcuts 404, Microsoft singular `list-detail` 404, Gmail reading-pane 404,
  and three JS-only Apple HIG/Material 3 pages with no rendered body).
- **E27.** Gained exactly one appended `- **Scope:**` bullet pointing to F35; no other existing
  bullet, heading, or entry (A1-E27) was touched, renumbered, or rewritten.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - blocking fix] WebFetch tool not available to this executor; substituted curl-based live fetches**

- **Found during:** Task 1, before the first fetch
- **Issue:** The plan's `<action>` blocks specify `WebFetch <url>` as the fetch mechanism, per
  house rule 6 ("WebSearch is disabled in this session. Use WebFetch against the exact URLs given
  below."). This execution environment's tool list does not include a `WebFetch` tool.
- **Fix:** Used `curl` (with a standard browser User-Agent, `--max-time` bounded, `-L` to follow
  redirects) plus a small inline Python HTML-tag-stripping pass to get readable text, against
  every URL named in the plan — the same 12 URLs, fetched live during this pass, with HTTP status
  codes captured explicitly for each (200/301/404 as applicable). This satisfies the substance of
  house rules 2 and 6 (nothing from memory; every claim traced to a page actually fetched this
  pass) even though the specific tool differs from what the plan named.
- **Verification:** Every quoted string in B28, B31, and B32 was cross-checked word-for-word
  against the curl-fetched text before being written into the doc; the B32 tab-bar/nav-bar
  scroll-away quote was rewritten to match the live page's actual wording rather than the plan's
  paraphrase, since it differed slightly.
- **Files modified:** docs/ux-patterns.md
- **Commits:** 22e5e20, baeef49, 58a2b6c

Or: none beyond the above — no other auto-fixes were needed; the plan's task structure, numbering
decision, and house rules were followed exactly as written.

## Known Stubs

None. This is a documentation-only change with no application code, UI, or data flow — nothing to
stub.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes were
introduced; the plan's own threat register (T-jpm-01 through T-jpm-04) covers the only relevant
surface (WebFetch/curl source attribution and existing-entry tampering), both mitigated as
described above.

## Self-Check: PASSED

- `docs/ux-patterns.md` exists and contains B28-B32, F33-F35, the updated 10-row ledger, and the
  attempt log — verified via `grep`/`awk` against the file on disk after each commit.
- Commits `22e5e20`, `baeef49`, `58a2b6c` all found in `git log --oneline --all`.
- `git diff HEAD~3 -- docs/ux-patterns.md` shows 185 insertions / 3 deletions and zero removed
  `###` headings — no existing A1-E27 entry was renumbered, deleted, or rewritten.
- `docs/ux-patterns.md` is the only file this plan modified (all other working-tree changes shown
  by `git status` predate this session and are out of scope for quick task 260818-jpm).
