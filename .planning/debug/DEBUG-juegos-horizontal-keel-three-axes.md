---
status: diagnosed
trigger: "Diagnose UAT gaps G-01.8.3-2c (pinned band width), G-01.8.3-2e (search row + `+` inset), G-01.8.3-4b (sheet body vs its own header keel) on /admin/juegos. goal: find_root_cause_only"
created: 2026-09-27T00:00:00Z
updated: 2026-09-27T00:00:00Z
---

## Current Focus

bug_class: Bohrbug — pure static layout. Reproduces on every load at every width,
  at rest and while pinned, in headless Chrome exactly as on the real Brave/Android
  device (the screenshot's band left edge back-solves to ~15.6 CSS px at DPR 2.769;
  measured 16.0 in Chrome).

reasoning_checkpoint:
  hypothesis: |
    There is NO shared keel token in the admin. Every surface re-derives the
    "16px keel" as a hand-written literal, and the three reported surfaces sit
    at three DIFFERENT nesting depths relative to that literal:
      (a) page content  = <main>'s `px-4` (16) + the component's own 16 = 32px
      (b) full-bleed decoration (the caption `::before` band, the row divider
          `::before`) = anchored to its host's PADDING-BOX outer edge, so it
          picks up <main>'s 16 only = 16px
      (c) sheet content = `position: fixed` escapes <main> entirely, and
          `.pk-admin-sheet__rows` declares NO horizontal padding = 0px
    Three axes on one screen (0 / 16 / 32) plus a fourth, viewport-dependent
    one for the `+` button (54 / 39 / 24 at 390 / 375 / 360).
  confirming_evidence:
    - "Measured at 390/375/360: band ::before painted [16, W-16]; row cover 32; row chevron W-32; caption ink 32; search field 32."
    - "Sheet open at 390: header content [16, W-16]; `.pk-admin-sheet__rows` computed padding `8px 0px`; EVERY body descendant L=0, Rin=0, width=390."
    - "`+` button border box L=292 at 390 AND 375 AND 360 — a fixed x, never tracking the viewport."
    - "test/visual/admin_shell.mjs:1055-1062 states in its own comment that measuring viewport-relative would read 32px, and deliberately subtracts <main>'s contribution."
  falsification_test: |
    If the keel were genuinely one number, the band's painted rect and the row
    cover's rect would share a left edge. They do not, at any of the three
    widths, at rest or pinned: 16 vs 32, an exact 16px constant offset.
    If `<main>`'s px-4 were not the doubling source, an admin page WITHOUT it
    would still read 32. The editor (`form.ex:1177`, the one `fullbleed` admin
    page) reads `main` paddingLeft `0px` and `.pk-editor-title` ink at 16 —
    confirming px-4 is exactly the extra 16.
  fix_rationale: n/a (find_root_cause_only)
  blind_spots: |
    Measured in headless Chrome at 390/375/360 x 844 only. The real device is
    Brave/Android; the developer's own screenshot independently corroborates the
    band-vs-cover offset and the sheet-vs-header offset, so engine divergence is
    not implicated. Widths below 360 were not exercised — the `+` button's fixed
    x=292 means it will cross the viewport's own right edge somewhere below
    ~336px, untested. iOS Safari untested.
  candidate_causes:
    - "code/CSS: `.pk-admin-juegos-section-header::before { left:0; right:0 }` (juegos.css:274-275) anchors the band to the padding-box edge, NOT to the 16px the header's own `padding: var(--pt) 16px 0` (juegos.css:216) gives its ink"
    - "code/markup: `Layouts.app`'s `<main class=\"px-4 ...\">` (layouts.ex:637) applies on every non-`fullbleed` page; `game_live/index.ex`'s `<Layouts.app>` (index.ex:615-622) passes no `fullbleed`, so the page's 16px keel is applied TWICE"
    - "code/markup: `#juegos-search-input`'s `flex: 1` (juegos.css:64) is inert — its parent is `<form id=\"juegos-search-form\">` (index.ex:641), a plain block that is itself the flex ITEM; the field never grows, so the `+` lands at a fixed x"
    - "code/CSS: `.pk-admin-sheet__rows` (components.css:697-702) declares only vertical padding; the keel is delegated implicitly to whatever the caller renders"
    - "config/token: ELIMINATED as a fix lever — there is no admin keel custom property at all. `--pk-gutter` (app.css:524) is public-site only; admin/tokens.css carries colour tokens only. Every admin keel is a copied `16px` literal."
    - "environment: ELIMINATED — identical numbers in headless Chrome and on the real Brave/Android screenshot"
    - "data: ELIMINATED — independent of catalog content; reproduces on Borradores and Juegos del club alike, and on /admin/staff, /admin/niveles, /admin/secciones, /admin/estantes/administrar"
  and_gate: |
    PARTIALLY. G-01.8.3-2c is AND-gated: the band reads wrong ONLY because
    (1) the band is anchored to the padding-box edge AND (2) <main> adds a
    second 16px that the band picks up but the ink does not. Neutralising
    either alone collapses the two axes onto one.
    G-01.8.3-2e is a genuine TWO-cause AND as well: (1) the doubled page keel
    puts the field's left at 32 instead of 16, AND (2) the inert `flex: 1`
    leaves the `+` at a fixed x that matches nothing at any width.
    G-01.8.3-4b is single-cause: `.pk-admin-sheet__rows` has no horizontal
    padding while `.pk-admin-sheet__header` has 16px.
    All three share ONE upstream cause — no single keel source of truth — but
    they have three distinct proximate mechanisms and three distinct fix sites.

## Symptoms

expected: |
  G-01.8.3-2c: the pinned caption band spans the same width as everything else.
  G-01.8.3-2e: the search field and `+` occupy the same width as the rest — no
    extra left/right inset beyond one shared keel.
  G-01.8.3-4b: the sheet's body sits on the same keel as the sheet's own header.
actual: |
  Developer, real device (Brave, ~390px CSS, 2026-09-27):
  - "The band that is pinted for 'borradores' when I scroll doesnt have same
     width that the rest."
  - "Then the search and + should take same width that the rest (currently
     there is padding at left ant right)."
  - "the content of the bottom sheet isn't using the widts correctly. Only the
     Title and its 'X' are using the width correctly."
errors: none — pure layout. `admin_shell.mjs` reports its Juegos keel assertions
  PASSING against this exact screen.
reproduction: /admin/juegos at 360/375/390px over a staff session, at rest and
  scrolled; then tap `+` and measure the open sheet.
started: latent since the admin was built on the shared public `Layouts.app`
  (`<main class="px-4 ...">`) while every admin component declared its own 16px.

## Eliminated

- hypothesis: "A shared keel token exists and is simply unapplied in these places
  (the UAT's own suggestion for G-01.8.3-4b)."
  evidence: |
    No admin keel custom property exists. `assets/css/admin/tokens.css` declares
    only `--color-surface`, `--color-surface-2`, `--stroke`, `--val`.
    `--pk-gutter` (app.css:524, 2rem) is the PUBLIC site's gutter and is never
    read by any `.pk-admin-*` rule. Every admin keel is a hand-written `16px`
    literal — components.css:67, 102, 154, 258, 307, 365, 397, 654, 712, 814,
    902; juegos.css:60, 216, 389; editor.css:186-187; estantes.css:350.
    There is nothing to "apply"; the token has to be created first.
  timestamp: 2026-09-27

- hypothesis: "The band is only wrong when pinned (a pinned-state-specific rule)."
  evidence: |
    The pinned rule (`juegos.css:339-343`) sets only `top`, `bottom` and
    `background`. Measured at rest AND pinned at 390/375/360: band painted
    [16, W-16] in every one of the six states. Horizontal geometry is
    scroll-state-independent; only the tint's visibility is not.
  timestamp: 2026-09-27

- hypothesis: "The band is NARROWER than the content (the developer's wording
  could mean either)."
  evidence: |
    It is WIDER. Band painted width 358/343/328 vs content width 326/311/296
    at 390/375/360 — exactly +16px on each side.
  timestamp: 2026-09-27

- hypothesis: "The search row's own container is at the wrong inset (the UAT's
  first proposed shape for G-01.8.3-2e)."
  evidence: |
    `.pk-admin-juegos-search-row` measures contentL 32 / contentRin 32 — the
    SAME 32 as every `.pk-admin-row`. The container is consistent with the rows.
    The defect is INSIDE it: the field's left lands on 32 but the `+`'s right
    lands on 54/39/24 (viewport-dependent), matching neither 16 nor 32.
  timestamp: 2026-09-27

- hypothesis: "Engine divergence (Brave/Android vs headless Chrome)."
  evidence: |
    The developer's own JPEG back-solves (DPR 1080/390 = 2.769) to band left
    ~15.6 CSS px, cover left ~32.6, divider left ~85, divider right-inset ~17 —
    matching headless Chrome's 16 / 32 / 84 / 16 within measurement error of a
    JPEG. Same defect, same magnitude, both engines.
  timestamp: 2026-09-27

## Evidence

- checked: `lib/pukllay_club_web/components/layouts.ex:629-641`
  found: |
    `<main class={[..., !@fullbleed && "px-4 sm:px-6 lg:px-8"]}>`. The only
    `fullbleed` callers are `about_live.ex:64`, `catalog_live/index.ex:918`,
    `catalog_live/show.ex:406` and — the only ADMIN one —
    `admin/game_live/form.ex:1177` (the editor). `game_live/index.ex:615-622`
    passes `bottom_collapse admin_chrome active_tab={:juegos}` and no
    `fullbleed`.
  implication: <main> contributes a second, unaccounted 16px on /admin/juegos.

- checked: LIVE, headless Chrome over a real staff session, /admin/juegos,
    VIEWPORT-relative rects at 390 / 375 / 360 (at rest AND with the published
    caption really pinned by an incremental scroll)
  found: |
    identical in all six states:
      main                        content [16, W-16]   (paddingLeft/Right 16px/16px)
      .max-w-3xl wrapper          border  [16, W-16]
      .pk-admin-juegos            border  [16, W-16]
      .pk-admin-juegos-search-wrap border [16, W-16]
      .pk-admin-juegos-search-row content [32, W-32]
      .pk-admin-row               content [32, W-32]
      row cover art (40x40)       L = 32
      row chevron                 right inset = 32
      caption ink                 L = 32
      section-header ::before BAND painted L = 16, right inset = 16
        (bg rgba(0,0,0,0) at rest; rgb(241,236,253) pinned — both sections)
      row divider ::before        painted L = 84, right inset = 16
      #juegos-search-input        L = 32,  right inset 94 / 79 / 64
      #juegos-add-action (`+`)    L = 292 at ALL THREE WIDTHS,
                                  right inset 54 / 39 / 24
  implication: |
    Three static x-axes on one screen — 16 (band, divider-right), 32 (all row
    and caption content), 84 (divider-left / row-name column) — plus a fourth,
    viewport-DEPENDENT one for the `+`. The band is 16px outdented from every
    row; the divider's right end is on the band's axis, not the rows'.

- checked: LIVE, the `+` sheet actually OPENED (real click on `#juegos-add-action`,
    polled for `pk-admin-overlay--open`), 390x844
  found: |
    .pk-admin-overlay-root      [0, 0]           (position: fixed; escapes <main>)
    .pk-admin-sheet panel       [0, 0]
    .pk-admin-sheet__header     content [16, W-16]
      title ink "Agregar juego" L = 16
      close ✕ button            right inset = 16
    .pk-admin-sheet__rows       computed padding "8px 0px"  <- ZERO horizontal
      .pk-admin-juegos-sheet-body   L=0  Rin=0  width 390
      form                          L=0  Rin=0  width 390
      .pk-admin-field               L=0  Rin=0  width 390
      label .pk-admin-field__label-wrap L=0 Rin=0 width 390
      span .pk-admin-label--field   L=0  Rin=0  width 390
      input .pk-admin-field__control L=0 Rin=0  width 390
      button .pk-admin-action--a1   L=0  Rin=0  width 390
  implication: |
    Exactly the developer's report. The header's ink is on 16; every body box —
    including the outlined `Agregar` button's stroke and the text field's border
    — runs the full 390px, flush to both screen edges, 16px outside the header.
    Screenshots (.planning/phases/01.8.3-admin-screen-by-screen-refinement/evidence/):
      01.8.3-diag-keel-sheet-390-2026-09-27.png   (open `+` sheet)
      01.8.3-diag-keel-top-390-2026-09-27.png     (page at rest)
      01.8.3-diag-keel-pinned-390-2026-09-27.png  (scrolled; reproduces the
        developer's real-device JPEG exactly)

- checked: LIVE, `editor-shelf-sheet` (a DIFFERENT sheet call site, on
    /admin/juegos/177/editar) opened for a blast-radius read
  found: |
    rowsPadding "8px 0px" (same component).
    `.pk-donde-va-search`            L=16  (compensates via its OWN `margin: 0 16px 8px`, estantes.css:350)
    a plain wrapper div              L=0
      span.pk-admin-list-section-label  L=0   <- a section label flush at x=0
      div.pk-admin-row                  L=0, but `.pk-admin-row__body` L=16
  implication: |
    The sheet's real, implicit keel is 16 — met only by children that self-inset
    (`.pk-admin-row`'s own `padding: 8px 16px`, components.css:307) or that
    hand-roll a compensating margin. Everything else falls to 0. Confirms this
    is a SHARED-component gap, not a Juegos-only call-site slip: the same
    component leaks on at least two screens. (`.pk-editor-opt`, editor.css:456-457,
    goes further: `padding: 8px 16px; margin: 0 -16px` — a negative margin written
    for a 16px-padded parent that does not exist here.)

- checked: LIVE cross-page sweep at 390px
  found: |
    /admin, /admin/juegos, /admin/estantes/administrar, /admin/staff,
    /admin/niveles, /admin/secciones — all `main` paddingLeft 16px,
    all `.pk-admin-row` content [32, W-32].
    /admin/juegos/177/editar (`fullbleed`) — `main` paddingLeft 0px,
    `.pk-editor-body` content [16, W-16], `.pk-editor-title` ink L=16, but
    `.pk-admin-editable-row` content [32, W-32].
  implication: |
    The doubling is systematic, not Juegos-specific: `<main>`'s px-4 sits under
    every admin list page. The editor is the control — remove px-4 and the same
    components land on 16. Note the editor's own title (16) vs its rows (32)
    reproduces the same two-axis split one level down.

- checked: `test/visual/admin_shell.mjs:1055-1062` (the comment above
    `measureJuegosKeelAt`) and `:1088-1099` (`edges()`)
  found: |
    Verbatim comment: «"Content edge" is measured relative to
    `.pk-admin-juegos`'s OWN box, not the viewport — `<main>`'s site-wide 16px
    horizontal padding ... would otherwise get counted a second time on top of
    the row's/search-row's own `padding-left`, SILENTLY DOUBLING EVERY READING
    TO 32px.»
    `edges()` computes `left = (r.left - cRect.left) + paddingLeft`.
  implication: |
    The probe's author MEASURED 32px, read D-16's "rows self-inset 16px"
    language as licensing it, and subtracted `<main>`'s contribution. The
    "16px keel" the guard asserts is a container-relative quantity that exists
    nowhere on screen. The developer's eye sees the un-netted 32.

- checked: LIVE, running admin_shell.mjs's exact `edges()` side by side with
    viewport-relative rects in the same evaluation, at 390/375/360, at rest and
    pinned
  found: |
    PROBE_SAYS  row {left:16, right:16}   searchRow {left:16, right:16}   (all 6 states)
    EYE_SEES    row cover L=32 · row chevron Rin=32 · search field L=32
                `+` L=292 / Rin 54|39|24 · band [16, W-16]
  implication: |
    Direct, same-frame proof that the probe and the eye are measuring different
    boxes in different coordinate systems. Nothing in the probe reads the
    band's `::before`, the `+`'s own rect, or the sheet body's rect.

- checked: `test/visual/admin_shell.mjs:986-999` (`measureKeel`, the "consistent
    16px keel across all 8 admin pages" check) and `PAGES` (lines 61-70)
  found: |
    It measures `main .mx-auto.w-full.max-w-3xl`'s rect.left — i.e. `<main>`'s
    OWN padding, 16px, and nothing about content. `PAGES` contains only the 8
    non-`fullbleed` admin pages; the editor URL is not in the list.
  implication: |
    That check can only ever report 16 — it asserts the very padding that is
    being double-applied. It is structurally incapable of noticing the editor's
    divergent 0px, or any content-level inset.

- checked: `.pk-admin-juegos-search-row` flex mechanics, computed
  found: |
    row: display flex, gap 8px, padding "4px 16px 8px"
    child0 <form id="juegos-search-form">: display block, flex "0 1 auto",
      width 264px at 390 AND 375 AND 360
    #juegos-search-input: flex "1 1 0%", width 264px — but its parent is the
      <form>, which is display:block, so `flex: 1` is INERT
    child1 #juegos-add-action: flex "0 0 auto", width 44px,
      margin "0px 0px 0px -12px" (.pk-admin-action--a3, components.css:124)
    overflow of the `+`'s right edge past the row's own content box:
      -22px at 390 (22px of dead space left inside the row)
      +8px  at 360 (the button spills into the row's own right padding)
  implication: |
    The search cluster is not responsive at all. The field is stuck at its
    intrinsic `size=20` width and the `+` sits at a fixed x=292. Its distance
    from the screen edge therefore CHANGES with the viewport (54/39/24) while
    every row's chevron stays at exactly 32. The A3 `margin-left: -12px` — a
    pull written for a LEADING icon so its glyph lands on the keel — pulls a
    TRAILING action further away from the right keel, compounding it.

- checked: `.planning/phases/01.8.2-admin-ui-ux-redesign/01.8.2-UI-SPEC.md:161-180`
    ("The keel (open item 4) — decided: 16") and
    `.planning/phases/01.8.3-admin-screen-by-screen-refinement/01.8.3-CONTEXT.md:169-183` (D-16)
  found: |
    The UI-SPEC's evidence for "keel = 16" is a table of
    `main .mx-auto.w-full.max-w-3xl`'s own left/right rect at 375 and 360 —
    i.e. it measured `<main>`'s `px-4`, not content. D-16 then reasons from
    that: «All nine admin screens hand-copy `<div class="mx-auto w-full
    max-w-3xl space-y-6">` WITH NO GUTTER; adding padding there would DOUBLE
    every existing child's inset to 32px» — and therefore fixes "at the
    children, not the container", giving each child its own 16px.
    D-16 also states the intent for the band explicitly: «Full-bleed elements
    (the pinned caption band, the pinned search row's own background) still
    span EDGE TO EDGE with their ink at 16.»
  implication: |
    The premise is false. The wrapper has no gutter, but its PARENT `<main>`
    does (`px-4`, layouts.ex:637) — so the doubling D-16 explicitly set out to
    avoid is exactly what shipped: children at 32px. And the band, intended to
    reach x=0 with ink at 16, instead reaches x=16 with ink at 32. Both halves
    of D-16 are off by the same unaccounted 16px, in opposite directions — which
    is why the band and the content land on two different axes rather than one.
    The developer's eye agrees with the project's OWN written decision (16);
    the shipped pixels and the guard's netted-out reading are the outliers.

## Resolution

root_cause: |
  ONE upstream cause, three distinct proximate mechanisms, three distinct fix
  sites.

  UPSTREAM (shared by all three): the admin has no single source of truth for
  its horizontal keel. `01.8.2-UI-SPEC.md` decided "the keel = 16", but that
  decision was implemented as a hand-copied `16px` literal in ~15 separate CSS
  rules, and each of the three reported surfaces sits at a different nesting
  depth relative to it. There is no `--pk-admin-keel` token to "simply apply"
  (checked: `assets/css/admin/tokens.css` holds colour tokens only; `--pk-gutter`
  is public-site only).

  G-01.8.3-2c (pinned band width) — AND-gated, two simultaneously necessary
  conditions:
    (1) `assets/css/admin/juegos.css:274-275` — the caption's `::before` band is
        `left: 0; right: 0`, i.e. anchored to `.pk-admin-juegos-section-header`'s
        PADDING-BOX outer edge, deliberately bypassing the very
        `padding: var(--pt) 16px 0` (juegos.css:216) that insets the caption ink;
        AND
    (2) `lib/pukllay_club_web/components/layouts.ex:637` — `<main>`'s
        `px-4` is applied because `game_live/index.ex:615-622` does not pass
        `fullbleed`, so the whole page is already inset 16px before any component
        adds its own.
  Result: the band paints [16, W-16] while every row and the caption ink sit at
  [32, W-32]. Measured at 390/375/360, at rest and pinned: a constant 16px
  outdent on each side. The band's own authoring comment (juegos.css:174-178)
  says it is "full-bleed for free … this wrapper and every ancestor up to the
  16px-inset content keel carry no horizontal padding of their own" — that
  premise is false: `<main>` is such an ancestor and it does carry 16px, so what
  was meant to be a 0-to-viewport-edge band lands on an unintended third axis.
  The same defect appears on the row divider (`juegos.css:412-414`,
  `left: 68px; right: 0` -> painted [84, W-16]): its right end is on the band's
  axis, not the rows'.

  G-01.8.3-2e (search + `+`) — AND-gated, two necessary conditions:
    (1) the same doubled page keel (layouts.ex:637 + juegos.css:60's own 16px)
        puts the field's left border at 32, not at the intended 16; AND
    (2) `assets/css/admin/juegos.css:64` — `#juegos-search-input { flex: 1 }` is
        INERT, because the input's parent is `<form id="juegos-search-form">`
        (`lib/pukllay_club_web/live/admin/game_live/index.ex:641`), a plain
        `display: block` element that is itself the flex item of
        `.pk-admin-juegos-search-row`. The field therefore never grows; it stays
        at its intrinsic `size=20` width of 264px and the `+` lands at a fixed
        x=292 at every viewport width, aggravated by `.pk-admin-action--a3`'s
        `margin-left: -12px` (components.css:124), a leading-icon pull applied
        to a trailing action.
  Result: the `+`'s right edge sits 54 / 39 / 24 px from the screen edge at
  390 / 375 / 360 while every row's chevron sits at exactly 32 — a gap that
  matches no keel and changes with the viewport. At 360 the button already
  spills 8px past the row's own content box.

  G-01.8.3-4b (sheet body) — single cause:
    `assets/css/admin/components.css:697-702` — `.pk-admin-sheet__rows` declares
    `padding-top: 8px; padding-bottom: 8px` and NO horizontal padding, while its
    sibling `.pk-admin-sheet__header` (components.css:649-655) declares
    `padding: 0 16px 8px`. The sheet's keel is therefore delegated implicitly to
    whatever the caller renders: `.pk-admin-row`/`--a4` children self-inset 16px
    and read correctly; a form-shaped body does not and renders at x=0.
    `/admin/juegos`'s add-game sheet (`index.ex:682-750`, body
    `.pk-admin-juegos-sheet-body`) is form-shaped, so its label, its text field's
    border box and its `Agregar` button all measure L=0, Rin=0, width 390 —
    16px outside the header's ink on each side. The overlay is
    `position: fixed` (components.css:600-606) so it escapes `<main>`'s px-4
    entirely, which is why the sheet's header at 16 and the page's rows at 32 do
    not agree either.
    Blast radius beyond Juegos, confirmed live: the editor's `editor-shelf-sheet`
    renders `span.pk-admin-list-section-label` at L=0 in the same wrapper. Other
    form-shaped bodies with the same shape, not individually re-measured:
    `game_live/index.ex:814` (draft sheet, `.pk-draft-sheet-form`),
    `form.ex:1067` (text sheet), `form.ex:1104` (`#editor-bgg-edition-prompt`),
    `form.ex:1035` (`.pk-editor-opt`, whose `margin: 0 -16px` compensates for a
    parent padding that does not exist), `estante_live/administrar.ex:475`
    (shelf-name form).

fix: n/a — goal was find_root_cause_only
verification: n/a
files_changed: []
