---
status: resolved
trigger: "footer for desktop is too overloaded for being one line. What alternatives do you offer? how can this be simplified? Be sure to get a consistent rythm for dessktop and mobile"
created: 2026-08-23
updated: 2026-08-23
---

## Symptoms

- **Expected behavior:** The desktop footer should feel organized and give each concern (brand, navigation, social, theme, legal) enough visual room — with a layout rhythm (grouping/spacing pattern) that reads as the same system as the mobile footer, not an unrelated layout.
- **Actual behavior:** On desktop, `.pk-footer-row` (lib/pukllay_club_web/components/layouts.ex:577-600) lays out ALL footer content in a single flex row across two clusters:
  - `.pk-footer-left`: brand_logo (wordmark + tagline "Conectá jugando") + 3 nav links (FAQ, Contacto, Juntadas)
  - `.pk-footer-right`: social icons + "Tema" label + theme toggle (3 icon buttons) + copyright/BGG attribution text
  Five distinct concerns (brand, nav, social, theme, legal) are crammed into one thin horizontal band. Nothing technically overflows/wraps at normal desktop widths (there's already `flex-wrap: wrap` + a documented tablet-width overflow fix at app.css:920-937), but it's visually cramped/cluttered — the symptom is density, not breakage.
- **Error messages:** None — this is a visual/UX density issue, not a functional bug.
- **Timeline:** Current shape comes from the footer's original build (SHELL-01, page-shell.md sketch 011: "one row, two natural-width clusters") plus a later change that relocated the theme toggle into the footer between social icons and the meta line (sketch 017 Round 2) and moved social+theme into the mobile drawer below 480px (01.1-09 Task 2). Each addition made sense individually; the row was never revisited holistically after theme toggle was added, which is likely when it went from "two clusters" to "overloaded."
- **Reproduction:** View any page at a desktop viewport width (>480px, e.g. 1280px) and look at the footer band.

## Current Focus

- hypothesis: The overload is NOT "too many items in a row" in the abstract — it is a **loss of
  grouping signal from a single, uniform gap value**. `.pk-footer-left` and `.pk-footer-right`
  both declare `gap: 1.5rem` (app.css:938-944), the same 1.5rem used as the row's column-gap
  (app.css:917). So the spacing that separates *unrelated concerns* inside the right cluster
  (social icons | "Tema" | theme toggle | copyright+BGG) is identical to the spacing that
  separates *related items*, and there is no third spacing tier anywhere in the footer. With one
  gap value doing all three jobs, the ~4 concerns in the right cluster read as one flat 620px run
  of equally-spaced atoms rather than as distinct groups — that is the perceived "overload."
- test: Sweep the live app in headless Chrome (CDP), flatten the footer into its left-to-right
  atoms and measure every inter-atom gap plus each cluster's width, at desktop widths and at 375px.
  Falsification: if the within-cluster gaps and the between-cluster gap already differ by a wide
  margin (a real spacing hierarchy exists), this hypothesis is wrong and the cause is elsewhere
  (e.g. sheer item count, or vertical band thickness).
- expecting: A flat gap distribution inside `.pk-footer-right` (every gap == 24px) with one large
  `space-between` gap only at the cluster boundary; and on mobile, an INVERTED rhythm — 1.5rem
  between items inside a cluster vs 0.75rem between clusters (row-gap, app.css:917), i.e. same-group
  items spaced FURTHER apart than different-group items.
- next_action: NONE — session closed. The user answered the checkpoint with alternative A ("Keep as
  fixed"): the applied spacing-hierarchy fix stands as-is, and neither alternative B nor C (shedding
  a concern from `.pk-footer-right`) is to be implemented. `.pk-footer-right` intentionally remains
  620.8px carrying three concerns at >=1070px — accepted by the user, now grouped by a real 3x
  spacing contrast rather than a flat 1.0x. Gates re-run green at closure (366 tests / 0 failures,
  format clean, credo clean apart from the pre-existing core_components.ex suggestion).
- reasoning_checkpoint:
    hypothesis: "The desktop footer reads as overloaded because proximity — the ONLY grouping cue
      available (sketch 011 forbids dividers) — is not being used: one 1.5rem value serves every
      spacing tier, so `.pk-footer-right`'s three unrelated concerns and the label/control pair
      inside one of them are all equidistant, and ~9 atoms read as a single flat 620.8px run.
      Separately, `.pk-footer-row`'s row-gap (0.75rem) is smaller than the clusters' gap (1.5rem),
      so on every wrapped line the proximity signal is INVERTED — which is the measurable form of
      the 'inconsistent rhythm between desktop and mobile' half of the report."
    confirming_evidence:
      - "Measured at 700/1024/1280/1440px: every within-cluster gap is exactly 24.0px. Inside
         .pk-footer-right the social->Tema, Tema->toggle and toggle->meta gaps are all 24.0px —
         the label is exactly as far from the control it labels as from an unrelated concern."
      - "Measured at 375px and 430px: brand->links (same cluster) = 24.0px while links->meta
         (different clusters) = 12.0px. Proximity inverted, directly observed, not inferred."
      - "Screenshot at 1280px shows the right half as an undifferentiated run: 4 social circles,
         the word 'Tema', 3 loose 44px toggle buttons, then a 245.8px legal line — with no visible
         spacing break anywhere between them."
      - "The drawer already solves this exact pair: .pk-drawer-utility wraps the same
         'Tema' label + theme_toggle as one unit (app.css:1186-1191). The footer is the
         inconsistent surface, so binding them there is a consistency fix, not a new invention."
    falsification_test: "If the within-cluster gaps had already differed materially from the
      between-cluster gap (a real hierarchy present), or if the row-gap had been >= the cluster
      gap, this hypothesis would be dead. Both were checked directly and both went the other way."
    fix_rationale: "Addresses the mechanism, not the symptom: it introduces the missing spacing
      TIERS rather than shrinking the footer or deleting content. It cannot be a symptom-fix by
      content removal, because the two obvious removals are both forbidden by documented
      decisions — the 'Tema' label exists for discoverability (01.1-08-PLAN.md:430-431, sketch 017
      Round 2) and the BGG attribution is a compliance requirement (page-shell.md, D-04)."
    blind_spots: "(1) Whether restoring a spacing hierarchy is SUFFICIENT to satisfy 'too
      overloaded', or whether the user also wants fewer concerns in the row — that is a design
      decision, not a defect, and is being offered as alternatives at the checkpoint rather than
      decided unilaterally. (2) Dark theme not separately measured (spacing is colour-independent).
      (3) Measured in headless Chrome at dPR 1-2, not on a real device."
    candidate_causes:
      - "code/CSS: one gap value (1.5rem) serving every spacing tier — no grouping signal"
      - "code/markup: concern accretion — sketch 017 R2 inserted the theme control into a cluster
         sketch 011 designed for two concerns, without revisiting the cluster"
      - "config/breakpoint: the only responsive branch is at 480px, leaving 481-1072px as an
         undesigned flex-wrap fallback"
      - "data/content: NOT a cause — the 5 concerns are all required (BGG = compliance,
         'Tema' = documented discoverability decision)"
    and_gate: "YES — fires. Item count alone is not sufficient (5 concerns with a real spacing
      hierarchy would read as grouped) and flat spacing alone is not sufficient (2 concerns at a
      flat gap reads fine). The overload requires BOTH the accreted concern count AND the absent
      spacing hierarchy, simultaneously. The inverted row-gap is a THIRD, independent defect
      producing its own distinct symptom (the desktop/mobile rhythm mismatch), so root_cause is a
      set, not a single cause."
- tdd_checkpoint: null

## Evidence

- timestamp: 2026-08-23T21:30:00Z
  checked: Knowledge base (`.planning/debug/knowledge-base.md`) for prior matches on the footer.
  found: Three prior resolved sessions touch this exact shell — `footer-overflow-tablet-width`
    (same element, `.pk-footer-right`), `header-height-wordmark-wrap`, `search-expand-header-overlap`.
    All three are *functional* layout bugs (overflow / height inflation / a dropped CSS rule). None
    is a density or information-architecture complaint, so there is no known-pattern shortcut here.
  implication: No KB hypothesis to test first. But `footer-overflow-tablet-width` supplies hard prior
    geometry for the same element — right cluster natural width 620.8px, left 408.1px, children
    social 136 + "Tema" 31.1 + toggle 136 + meta 227.8 with 3x1.5rem gaps. Those numbers PREDATE the
    260823-snj change that dropped the isologo from the footer (`mark={false}`), so `.pk-footer-left`
    must be re-measured rather than reused.

- timestamp: 2026-08-23T21:32:00Z
  checked: Read the footer markup (layouts.ex:577-600) and its full CSS block (app.css:899-1039)
    plus the trailing <=480px block (app.css:1839-1855).
  found: |
    Exactly ONE gap value carries the entire footer's spacing hierarchy:
      .pk-footer-row     gap: 0.75rem 1.5rem   (row-gap 0.75rem / column-gap 1.5rem)  app.css:917
      .pk-footer-left    gap: 1.5rem                                                  app.css:943
      .pk-footer-right   gap: 1.5rem                                                  app.css:943
      .pk-footer-links   gap: 1rem                                                    app.css:951
      .pk-footer-social  gap: 0.5rem                                                  app.css:958
    The two clusters share one declaration (`.pk-footer-left, .pk-footer-right`), so the gap that
    separates brand-from-links is the same 1.5rem that separates social-from-Tema-from-toggle-from-
    copyright. `.pk-footer-right` holds four children spanning three unrelated concerns (social
    links, a theme CONTROL with its own text label, and legal/attribution text).
  implication: There is no "group" spacing tier distinct from the "item" spacing tier. The design's
    own source (page-shell.md sketch 011) specified only TWO clusters — brand+links / social+meta —
    and the theme toggle was inserted into the right cluster later (sketch 017 Round 2) without the
    cluster's spacing being revisited. That insertion is what took the right cluster from 2 concerns
    to 3 (4 children) at a uniform gap. Matches the Timeline exactly.

- timestamp: 2026-08-23T21:34:00Z
  checked: The <=480px mobile branch, to establish what rhythm desktop must stay consistent WITH
    (project standing priority is mobile-first; mobile must not regress).
  found: At <=480px, `.pk-footer-row`, `.pk-footer-left` and `.pk-footer-right` all become
    `flex-direction: column` (app.css:1839-1843), and social + "Tema" + theme toggle are hidden
    (`display: none`, app.css:1851-1855) because they relocate into the mobile drawer. `.pk-footer-links`
    is NOT columned, so it stays a horizontal row. The surviving mobile stack is therefore three
    blocks: brand -> links -> meta.
  implication: In column direction the gap between items INSIDE a cluster is 1.5rem (the clusters'
    `gap: 1.5rem`), while the gap BETWEEN the two clusters is the row-gap 0.75rem (app.css:917).
    So on mobile, brand->links (same group, 24px) is spaced TWICE as far apart as links->meta
    (different groups, 12px) — the proximity signal is inverted. This is very likely the concrete
    mechanism behind the user's "get a consistent rhythm for desktop and mobile" ask, and it is
    measurable. Verify before asserting.

- timestamp: 2026-08-23T21:41:00Z
  checked: CDP gap sweep on the LIVE app (localhost:4000), transitions disabled, viewport set via
    Emulation.setDeviceMetricsOverride. Flattened the footer into its left-to-right atoms and
    measured every inter-atom gap. Harness: scratchpad/footer-density.js (adapted from the
    footer-overflow-tablet-width session's already-live-validated footer.js).
  found: |
    w      dir     footerH  left.w  right.w  gap sequence (px, in flow order)
    375    column  180      201.1   245.8    24 within-left | 12 BETWEEN-CLUSTERS
    430    column  180      201.1   245.8    24 within-left | 12 BETWEEN-CLUSTERS
    481    row     200      364.1   417.0    24 | wrapped | 24 | 24 | wrapped
    700    row     153      364.1   620.8    24 | wrapped | 24 | 24 | 24
    1024   row     153      364.1   620.8    24 | wrapped | 24 | 24 | 24
    1280   row      97      364.1   620.8    24 | 231.1 BETWEEN | 24 | 24 | 24
    1440   row      97      364.1   620.8    24 | 231.1 BETWEEN | 24 | 24 | 24
  implication: BOTH predictions confirmed exactly. (a) Every within-cluster gap is 24.0px at every
    width — social->Tema, Tema->toggle and toggle->meta are indistinguishable, so the label sits as
    far from the control it labels as from an unrelated concern. The ONLY spacing differentiation
    in the entire footer is the `space-between` free space, and it exists solely at >=1073px.
    (b) At 375/430px the same-group gap (24px) is DOUBLE the different-group gap (12px) — proximity
    inverted, as predicted from the source.

- timestamp: 2026-08-23T21:43:00Z
  checked: Y-coordinates of every atom, to test whether the "one line" in the report is actually
    one line at all widths. Then a fine sweep at 1040/1060/1073/1080/1100/1120px.
  found: At 700px and 1024px `.pk-footer-right` starts at x=32 — back at the left gutter, on a NEW
    flex line. The footer is 153px tall and TWO tiers there, not one. At 481px it is 200px and
    THREE tiers (`.pk-footer-meta` orphans onto its own line). The one-line layout begins exactly
    at 1073px (97px tall); 1060px still wraps. Arithmetic checks: left 364.1 + right 620.8 + 24 gap
    + 64 gutters = 1072.9px.
  implication: SURPRISE — this reframes the report. The "one line" the user is objecting to only
    exists at >=1073px. From 481px to 1072px the footer is ALREADY a two-tier band, but an
    accidental one: it is the `flex-wrap: wrap` added as the fix for `footer-overflow-tablet-width`,
    so `justify-content: space-between` does nothing (both clusters left-align at the gutter) and
    the 12px row-gap makes the two tiers sit CLOSER together than the items within each tier.
    Most laptop widths therefore already get a two-tier footer with an inverted rhythm. Any fix
    must treat the wrapped state as a real state, not an edge case.

- timestamp: 2026-08-23T21:46:00Z
  checked: Rendered screenshots of the real footer at 375/1024/1280px (scratchpad/before-*.png,
    dPR 2, footer clipped in page coordinates).
  found: At 1280px the right half renders as a continuous run of roughly nine atoms — four social
    circles, the word "Tema", three loose 44px theme buttons, then "© 2026 Pukllay Club · [BGG
    logo] Powered by BGG" — with no visible spacing break at any concern boundary. At 1024px the
    two wrapped tiers are both jammed against the left gutter with the entire right half of the
    band empty.
  implication: Visual confirmation of the measured numbers, and it settles the "is 24px enough
    separation" question: it is not, because 24px is ALSO the within-group value, so there is
    nothing for the eye to contrast it against. Confirms the fix must add tiers, not just space.

- timestamp: 2026-08-23T21:48:00Z
  checked: Whether the concern count can simply be reduced (the obvious "simplify" move), by
    searching the planning record for the provenance of each atom.
  found: Both candidate removals are blocked by documented decisions. The "Tema" label exists
    specifically "so the control is discoverable in a place users are not yet used to looking for
    it" (01.1-08-PLAN.md:430-431, quoting sketch 017 Round 2), and sketch 017 Round 2 also named
    "the footer as the conventional home for utility controls" (01.1-08-PLAN.md:393) — so the
    toggle may not be moved back to the header either. The BGG attribution is a compliance
    requirement (page-shell.md). Separately, `.pk-drawer-utility` (app.css:1186-1191) already wraps
    the identical "Tema" + theme_toggle pair as ONE unit on mobile.
  implication: The fix lane is forced, and that is a good outcome — content removal is off the
    table, so the fix must be the spacing/grouping hierarchy, which is exactly what the evidence
    points at. It also reveals the footer is the INCONSISTENT surface: the drawer already binds
    the label to its control, the footer does not. Binding them in the footer is a consistency
    repair against an existing in-repo pattern, not a newly invented design.

## Eliminated

- hypothesis: "The footer overflows or breaks its layout at desktop widths (a recurrence of
    footer-overflow-tablet-width, the prior session on this same element)."
  evidence: Measured `documentElement.scrollWidth - clientWidth` = 0 at all of
    375/430/481/700/1024/1280/1440px. The prior fix holds; nothing overflows. The report is purely
    about perceived density, exactly as the Symptoms section states.
  timestamp: 2026-08-23T21:41:00Z

- hypothesis: "The desktop footer is cramped because the two clusters have too little space
    between them — i.e. the row is nearly full and the clusters nearly touch."
  evidence: At 1280/1440px the between-cluster gap measures 231.1px against 24px within-cluster
    gaps — a 9.6x ratio. The two CLUSTERS are, if anything, generously separated; total content
    (364.1 + 620.8 = 984.9px) leaves 231.1px of the 1216px content box free. The crowding is
    entirely INSIDE `.pk-footer-right`, not between the clusters. Had this hypothesis been acted
    on, the fix would have been to widen or re-justify the row — which would have changed nothing.
  timestamp: 2026-08-23T21:41:00Z

- hypothesis: "The concern count can be cut by removing the 'Tema' label or relocating the theme
    toggle back to the header — the simplest reading of 'how can this be simplified?'."
  evidence: Both are blocked by documented decisions with stated rationale (01.1-08-PLAN.md:393
    and :430-431, sketch 017 Round 2); the BGG attribution is additionally a compliance
    requirement. Acting on this would have silently reverted two deliberate decisions.
  timestamp: 2026-08-23T21:48:00Z

## Resolution

- root_cause: |
    Three contributing causes; the AND-gate fires between the first two.

    (1) NO SPACING HIERARCHY. `.pk-footer-left, .pk-footer-right { gap: 1.5rem }` (app.css:938-944)
        is one declaration serving every tier, and 1.5rem is also `.pk-footer-row`'s column-gap
        (app.css:917). Measured: every within-cluster gap is exactly 24.0px at every viewport. So
        the gap between unrelated concerns equals the gap binding "Tema" to the toggle it labels.
        Since sketch 011 deliberately forbids dividers, proximity is the footer's ONLY grouping
        cue — and it is switched off. ~9 atoms read as one flat 620.8px run.

    (2) CONCERN ACCRETION. Sketch 011 sized `.pk-footer-right` for two concerns (social + meta).
        Sketch 017 Round 2 inserted the theme control (label + 3 buttons) between them, taking it
        to three concerns / four children, without revisiting the cluster's spacing.

        AND-gate: neither alone is sufficient. Five concerns WITH a real hierarchy read as grouped;
        two concerns at a flat gap read fine. The overload requires both at once.

    (3) INVERTED PROXIMITY ACROSS FLEX LINES (independent third defect, own symptom).
        `.pk-footer-row`'s row-gap is 0.75rem while its clusters' gap is 1.5rem, so on every
        wrapped line same-group items sit 24px apart and different-group items 12px apart.
        This affects not just mobile but the entire 481-1072px band, where the footer already
        wraps to two tiers. This is the measurable form of the reported desktop/mobile rhythm
        mismatch.
- fix: |
    Restored a spacing HIERARCHY where there was one flat value. No content was removed or
    relocated — both candidate removals are blocked by documented decisions.

    1. A four-tier scale, declared once as tokens scoped to `.pk-footer` and consumed by BOTH the
       desktop row and the <=480px column layout (app.css:904-931):
         --pk-footer-gap-item    0.5rem  inside ONE unit (icon set, label+control)
         --pk-footer-gap-list    1rem    between sibling text links
         --pk-footer-gap-group   1.5rem  between distinct concerns in a cluster
         --pk-footer-gap-cluster 2rem    between clusters, in either orientation
    2. `.pk-footer-theme` wraps the "Tema" label + theme toggle as one unit (layouts.ex:601-607,
       app.css). The label now binds to its control at 8px while concerns separate at 24px — a 3x
       contrast where it used to be 1.0x. Mirrors the drawer's existing `.pk-drawer-utility`.
    3. `.pk-footer-row`'s `gap: 0.75rem 1.5rem` replaced by the single cluster token, ending the
       inversion where wrapped lines put different-group items closer than same-group items.
    4. The <=480px block retunes group/cluster to 1rem/1.5rem for vertical rhythm but preserves
       the tier ORDER, so mobile grew only 4px (180 -> 184px) while its rhythm flipped from
       inverted (24 within / 12 between) to correct (16 within / 24 between).
    5. The <=480px hide rule collapses to `.pk-footer-theme, .pk-footer-social` — the wrapper is
       footer-only, so it no longer needs descendant scoping to spare the drawer's `.pk-theme-toggle`.

    Also fixed a self-inflicted build break: prose was initially inserted after a comment's `*/`,
    orphaning it into CSS context. Tailwind v4 failed the build loudly (unlike the silent rule-drop
    in the KB's `search-expand-header-overlap`), so it was caught immediately.
- verification: |
    guardrail_verdict: accepted

    - regression_test: 6 new tests in test/pukllay_club_web/footer_rhythm_test.exs. Verified RED
      against the pre-fix tree via `git stash` (6/6 failed with the right messages: "Token
      --pk-footer-gap-item is missing", "has 4 direct children, expected 3", "≤480px block no
      longer re-declares tokens") and GREEN after. Oracle type: derived (contract) — ExUnit cannot
      observe rendered geometry, so the tests pin the token ordering geometry depends on. Includes
      a boundary neighbour on the defect's own equivalence class: group/item >= 2.0x, since the bug
      was exactly 1.0x and a strict `<` alone would still admit it.
    - revert_check: PASS. Stashing the fix restores the defect conditions and the tests fail.
    - live_geometry: PASS. CDP sweep of the running app at 375/430/481/700/1024/1060/1070/1280/1440px.
      Desktop gaps now 8px item / 24px group; mobile 16px within / 24px between (was 24/12 inverted);
      right cluster 4 children -> 3; zero horizontal overflow at every width (prior fix intact);
      one-line threshold improved slightly, 1073px -> 1070px.
    - full_suite: PASS. 366 tests, 0 failures (was 360; +6 new).
    - static_gates: PASS. `mix format --check-formatted` clean; `mix credo --strict` reports only
      one pre-existing suggestion in core_components.ex, unrelated to this change.
    - not_deletion_only: PASS. The diff adds tokens, a wrapper element and tests; it removes no
      content or functionality.
    - false_pass_found_and_fixed: the sibling footer_overflow_test.exs began passing for the WRONG
      reason — its `narrow =~ ".pk-footer-toggle-tag"` string match was satisfied by the selector
      merely being NAMED in one of my comments. Both footer test files now strip comments before
      matching, and that assertion now requires a real `display: none` rule.

    - human_verify: CONFIRMED. The checkpoint offered three alternatives (A: keep the applied
      spacing-hierarchy fix as-is; B/C: additionally shed a concern from `.pk-footer-right`). The
      user selected **A — "Keep as fixed"**, confirming the desktop footer now reads as grouped
      rather than overloaded and that the desktop/mobile rhythm mismatch is resolved. B and C were
      explicitly declined; the three-concern right cluster is accepted as intentional. This closes
      the one blind spot the evidence could not settle on its own (whether restoring the spacing
      hierarchy was SUFFICIENT, or whether content also had to be reduced) — it was sufficient.
    - closure_gates: re-run at archive time, all green. `mix test` 366 tests / 0 failures;
      `mix format --check-formatted` clean; `mix credo --strict` reports only the pre-existing
      `core_components.ex:214` nested-alias suggestion, untouched by this change.

    Residual known-unverified (accepted, non-blocking): dark theme not separately measured (the fix
    is spacing-only and therefore colour-independent); geometry measured in headless Chrome at
    dPR 1-2 rather than on a physical device — but the user has now confirmed the result in their
    own browser, which supersedes the headless measurement as the acceptance signal.

    prevention: |
      why not caught: no gate existed for this class. Every prior gate on this element was
        functional — `footer_overflow_test.exs` asserts nothing overflows, and the CDP sweeps in
        the three prior footer sessions all measured breakage, never grouping. A footer can pass
        "zero horizontal overflow" and "no wrap at width W" while its proximity signal is fully
        switched off (one gap value for every tier) or outright inverted (row-gap < cluster gap).
        Nothing in test, typecheck, lint, review, verify or build could observe a spacing RATIO,
        so concern accretion across sketch 011 -> sketch 017 R2 -> 01.1-09 T2 was invisible: each
        addition was individually correct and no gate looked at the cumulative rhythm.
      guard: test/pukllay_club_web/footer_rhythm_test.exs — 6 regression tests that pin the four-tier
        token scale (item/list/group/cluster) and its ORDERING, so a future edit cannot flatten the
        hierarchy back into one value or re-invert the row-gap without failing. The boundary
        neighbour matters: the assertion requires group/item >= 2.0x, not merely `>`, because the
        defect was exactly 1.0x and a strict inequality alone would still have admitted a 1.01x
        near-flat regression. Supporting guards: `.pk-footer-theme` binds the "Tema" label to its
        control structurally (mirroring the drawer's `.pk-drawer-utility`), so the pair can no
        longer drift apart; and both footer test files now strip CSS comments before matching,
        closing the false-pass channel where merely NAMING a selector in a comment satisfied an
        assertion.
- files_changed:
    - assets/css/app.css (footer spacing scale + tier assignments + <=480px retune/hide rule)
    - lib/pukllay_club_web/components/layouts.ex (.pk-footer-theme wrapper + rationale comment)
    - test/pukllay_club_web/footer_rhythm_test.exs (new — 6 regression tests)
    - test/pukllay_club_web/footer_overflow_test.exs (hardened against comment-text false passes)
