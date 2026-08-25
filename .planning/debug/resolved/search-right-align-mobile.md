---
status: resolved
trigger: "the last implementation breaks the search right aligment on mobile. Also this is over same line that header"
created: 2026-08-24T18:00:00.000Z
updated: 2026-08-25T01:30:00.000Z
---

## Current Focus — CYCLE 5 (un-stick the chip row + trim the band's excess whitespace)

<!-- Cycle 5 acts on two EXPLICIT user instructions, not on a self-generated hypothesis. Half (1)
     is a user-approved DESIGN CHANGE with no defect behind it; half (2) is a genuine measured
     defect with a root cause. They are implemented together because they interact. Cycles 1-4 are
     retained below for the record. -->

bug_class: Bohrbug (static layout outcome — deterministic on every load at <=480px; the sticky half
  is scroll-state-dependent but fully deterministic per scroll position)

reasoning_checkpoint:
  hypothesis: |
    TWO separable claims, deliberately not merged into one:

    (1) NOT A DEFECT — a design change the user explicitly approved via AskUserQuestion
        ("Un-stick the chip row" chosen over "Fine as-is" and "Reduce the header height").
        `{render_slot(@subnav)}` is rendered INSIDE the `#app-header` element
        (layouts.ex:439 sticky branch / :450 non-sticky branch), and that element is
        `position: sticky; top: 0` (`.pk-header-sticky`, app.css:530). Sticky pins the whole box,
        so the chip row shares the header's common fate at every scroll position — measured y=0..133
        at scrollY 0 AND at scrollY 1400 in cycle 4. There is no way to un-stick only the chip row
        while it remains a child of that box; it has to leave the element.

    (2) THE DEFECT behind "this looks too separated". The large white gap the user photographed
        between the chip row and "DESTACADOS DEL CLUB" is NOT cycle 4's 12px band padding and NOT
        an interaction with the sticky stack. It is `Layouts.app`'s `<main class="py-20">`
        (layouts.ex:454) — a flat 5rem/80px of top padding applied at EVERY viewport width, with
        no responsive step. On a 390px phone that spends 80px of vertical budget on nothing,
        directly under a band that is already 133px tall, so 213px (25% of an 844px viewport, and
        ~32% of a 667px iPhone SE) is consumed before the first pixel of content. `py-20` is a
        desktop-scale value shipped unconditionally to mobile.
  confirming_evidence:
    - "Measured at 390px light, headless Chrome + CDP (`before.json`): nav rect y=0..64, chip band
      y=64..133, `mainPadTop: 80px`, heading 'Destacados del club' at y=213. `gapWrapToHeading`
      computes to exactly 80.00px — the full `py-20` value, nothing else contributes. The gap is
      one declaration, not an accumulation."
    - "`mainPadTop: 80px` is IDENTICAL at 390/480/481/1280 in both themes. There is no responsive
      step on `<main>`'s vertical padding anywhere in the codebase — the same 80px desktop value
      is what mobile gets."
    - "The rendered 390px screenshot (`before-390-light-top.png`) shows it directly: header bar,
      then the chip row (cycle 4's 12px padding visibly present and reading correctly — the user
      did not flag this boundary), then a solid empty white band from y=133 to y=213 before the
      first heading. That empty band is the user's 'too separated'."
    - "Cycle 4 measured `#app-header` at y=0..133 at scrollY 0 AND unchanged at y=0..133 at
      scrollY 1400 with `.is-scrolled` active — zero relative motion between the nav and the chip
      row. That is the sticky grouping (1) removes, confirmed by measurement rather than by
      reading the CSS."
    - "Blast-radius probe for (2): all three pages that mount `Layouts.app` pass `fullbleed`
      (index.ex:463, show.ex:172, about_live.ex:44), so `!@fullbleed && \"px-4 sm:px-6 lg:px-8\"`
      never applies anywhere — `py-20` is the ONLY `<main>` padding in effect in the whole app.
      Its top and bottom halves have DIFFERENT consequences, which is what scopes the fix: both
      Detalle (`.pk-mobile-cta-bar`, app.css:2084) and Quiénes Somos (`.pk-about-cta-bar`,
      app.css:1714) render `position: fixed; bottom: 0` CTA bars at mobile, and `pb-20` is the
      clearance that keeps their last content from being permanently occluded."
  falsification_test: |
    For (2): if `mainPadTop` had measured anything other than 80px, or if `gapWrapToHeading` had
    exceeded 80px (meaning a second contributor — a margin on `.pk-page`, `space-y-*` collapse, or
    the wrap's own padding — was also in play), or if the gap had changed once the row was
    un-stuck, the diagnosis would be wrong. All three were measured: 80px flat, 80.00px total, and
    un-sticking is provably inert on the unscrolled layout (it changes scroll behaviour only, since
    at scrollY 0 a sticky element occupies its normal-flow position).
    For (1): falsified if the chip row still moved with the header after leaving `#app-header`, or
    if `--pk-header-h` did not drop to the nav-only height.
  fix_rationale: |
    (1) Move `{render_slot(@subnav)}` out of BOTH `#app-header` branches into a sibling
        `<div id="app-subnav">` placed between the header and `<main>`. This is the only change
        that actually un-sticks it — CSS cannot exempt a child from its ancestor's sticky box.
        The `.CatalogNav` hook collects scroll-spy targets with
        `this.el.querySelectorAll("[data-chip-target]")` where `this.el` IS `#app-header`, so the
        move would silently orphan all 8 chips (measured `spyTargets: 16` = 8 chips + 8 desktop
        `.pk-cat-item` rows, which stay inside the header). The hook must therefore collect from
        both surfaces — this is the interaction the change would otherwise break, and it is a
        latent-bug risk, not a cosmetic one, because the chips would keep rendering and simply
        stop highlighting.
    (2) `py-20` -> `pb-20 pt-8 sm:pt-20`. TOP ONLY, and MOBILE ONLY, both deliberately:
        - top only, because `pb-20` is load-bearing clearance for two fixed bottom CTA bars.
          Cutting the bottom to match would trade the reported spacing complaint for a content-
          occlusion bug on two other pages.
        - mobile only (`sm:pt-20` restores it at 640px), because 80px under a 65px desktop header
          is a normal airy layout and is not what was reported. Desktop stays byte-identical.
        - 32px, not 0: the repo's own documented page-container vertical value is `py-6`/24px
          (ui-design-system, "Spacing/typography scale") and its section rhythm is `space-y-6`.
          32px sits just above that floor while cutting the reported gap by 60%, and it is on the
          Tailwind scale rather than an invented number.
    Deliberately NOT touched: cycle 4's `padding: 0.75rem 0` on `.pk-chip-nav-wrap`. The user's
    screenshot shows that boundary reading correctly and they did not flag it; cycles 2-4
    established that a zero gap there reads as "glued". The ask was to trim excess ELSEWHERE.
  blind_spots: |
    (2) changes mobile top padding on Detalle and Quiénes Somos too, not just the catalog —
    `<main>` is layout-owned and there is no per-page vertical-padding knob. Scoping it to the
    catalog alone would mean inventing one, which is more machinery than the defect justifies, but
    it does mean two pages the user did not report get tighter at mobile. Both are verified below
    rather than assumed. Also unverified: real physical devices and non-Chromium engines — the
    material caveat, since THREE straight self-verified rounds have now been corrected on
    real-device review. Pre-existing and NOT introduced here: the hook collects spy targets once at
    mount and never re-collects in `updated()`, so a filters-on/filters-off round trip leaves stale
    node references. That is identical before and after this change (both `:subnav` and `:nav_menu`
    are gated on `not filters_active?` and both already lived inside the hook element), so it is
    recorded, not fixed under a bugfix.
  candidate_causes:
    - "code: `<main>` declares a flat `py-20` with no responsive step, shipping a desktop-scale
      80px top gap to a 390px phone (CONFIRMED — this is the defect behind 'too separated')."
    - "code/architecture: the subnav slot is rendered as a child of the `position: sticky`
      `#app-header`, so the chip row cannot scroll independently (CONFIRMED as the mechanism
      behind the sticky grouping — but it is NOT a defect, it is what sketch 020 shipped; it
      changes only because the user explicitly asked for it)."
    - "config/design-token: ruled out — no token is involved. `py-20` is a literal Tailwind
      utility, not a themed spacing variable, and the gap measured 80px in both themes."
    - "environment: ruled out — a static computed style, identical at every width and theme and on
      every load; no timing, engine or device dependence."
    - "data: ruled out — not content-dependent. The 80px gap is a constant; it is there with 8
      shelves or 1, and `gapWrapToHeading` is the same in the filtered and unfiltered renders."
  and_gate: |
    NO for the reported symptom. The 'too separated' gap needs only (a) — `py-20` unconditional at
    mobile. Nothing else contributes: the measured 80.00px accounts for 100% of the gap, so there
    is no second necessary condition to find.
    Stating this explicitly is what rules out the tempting wrong fix, which is real here: the
    obvious move after cycle 4 is to conclude "I added 12px last round and the user now says it is
    too separated, so back that out." The arithmetic forbids it — cycle 4's padding is 12px of a
    213px stack (5.6%), and removing it entirely would reclaim less than a sixth of what `py-20`
    alone costs while re-introducing the exact glued-band defect cycles 2-4 spent three rounds
    establishing. The excess is somewhere the user could not see, which is why it needed measuring
    rather than guessing.
    The sticky change (1) is a separate axis with no AND-gate at all — it has no defect behind it.

next_action: NONE — SESSION RESOLVED AND ARCHIVED. Human verification PASSED on 2026-08-25: the
  user re-checked `http://localhost:4000/` on their real device at mobile width after a hard
  refresh / incognito load and confirmed BOTH halves — the spacing now reads right (tighter, with
  the header-to-chip-row gap still clearly present) and the chip row scrolls away with the page
  while only the top bar stays pinned. That confirmation is terminal and retroactively closes
  cycle 4 as well: the user's screenshot at the cycle-4 checkpoint already showed that boundary
  reading correctly, and the final review did not re-flag it. All five cycles are now human-verified
  end to end. Session committed, moved to `.planning/debug/resolved/`, and appended to
  `.planning/debug/knowledge-base.md`.

## Current Focus

bug_class: Bohrbug (deterministic — reproduced at every load below 481px in headless Chrome, no timing/concurrency component)

reasoning_checkpoint:
  hypothesis: "`.pk-cat-trigger ~ .pk-search-morph { margin-left: 0 }` (app.css:963, added
    unconditionally by quick task 260824-jkc Task 3) strips `.pk-search-morph`'s base
    `margin-left: auto` at ALL widths, including `@media (max-width: 480px)` where
    `.pk-cat-trigger` is `display: none`. The `~` combinator matches on DOM tree structure while
    the intended precondition — 'a trigger absorbs the row's free space' — depends on BOX
    GENERATION. `display: none` separates the two, so below 481px the override fires with nothing
    replacing the right-push, collapsing the closed pill leftward against the brand."
  confirming_evidence:
    - "Direct measurement at 390px: `.pk-search-morph` computed `margin-left` is `0px`, its rect
      is left=110/right=154, and `.pk-nav-inner`'s content right edge is 376 — a 222px trailing
      gap where a right-aligned pill must measure 0."
    - "At the same 390px: `.pk-cat-trigger` computed `display` is `none` and its
      `getBoundingClientRect()` is 0x0 at (0,0) — it generates no box — yet its computed
      `margin-left` is still `auto` and `morph.matches('.pk-cat-trigger ~ .pk-search-morph')`
      returns `true`. Selector matched; box absent. That is the mechanism, observed directly."
    - "Boundary differential: 480px closed -> gap 312px (broken); 481px closed -> gap 0px
      (correct), where `triggerDisplay` flips `none` -> `flex`. The failure boundary lands exactly
      on the `max-width: 480px` block that hides the trigger, not on 48rem/50rem or any other
      declared breakpoint."
    - "`git show 9b88168 -- assets/css/app.css` contains exactly two deltas; the other is wholly
      inside `@media (min-width: 50rem)` and is inert below 481px. The new top-level rule is the
      only change in the commit that can reach the mobile cascade."
  falsification_test: "If `.pk-search-morph`'s computed `margin-left` had resolved non-zero at
    390px, or the pill's right edge had already matched `.pk-nav-inner`'s content right edge, or
    the failure boundary had sat anywhere other than 480/481, this hypothesis would be dead. All
    three were measured and all three point the same way."
  fix_rationale: "Scope the override to the exact complement of the band that hides the trigger,
    so the rule can only apply where its precondition (the trigger generates a box) actually
    holds. This removes the defect at its source — the rule's reach — rather than patching the
    pill's position with a second competing margin declaration. Desktop grouping (the 303px-gap
    fix Task 3 shipped) is preserved untouched above 480px; Detalle (no trigger, selector never
    matches) is unaffected at every width."
  blind_spots: "Measured on CatalogLive `/` only, in one Chrome build, light theme, at 390/480/
    481/1280px. Not yet measured: Detalle (which has a crumb and no trigger), the 481-799px band
    where the trigger is visible but its label is hidden, or the drawer-open state. Detalle is
    covered by reasoning (the `~` selector cannot match without a trigger in the DOM) rather than
    measurement; verification below closes the rest."
  candidate_causes:
    - "code: the general-sibling override is declared with no media query, so it applies in a band
      where the condition it was written for is false (CONFIRMED — this is the defect)."
    - "config/CSS-architecture: `.pk-cat-trigger` is hidden with `display: none` in a media query
      rather than not being rendered at all, so DOM presence and box generation diverge and a
      structural selector silently over-matches (CONFIRMED as the enabling condition — but this is
      intended design, not a defect: mobile deliberately uses the chip row instead of the
      mega-menu, and the slot must stay in the DOM for the desktop panel's containing-block
      contract)."
    - "environment: ruled out — this is spec-mandated behaviour (`display: none` generates no box;
      combinators match the DOM tree), identical across engines, and reproduced deterministically."
    - "data: ruled out — not content-dependent; the pill is a fixed 44px closed and the gap
      reproduces regardless of catalog contents."
  and_gate: "yes — the failure needs BOTH (a) the override being unscoped and (b) the trigger
    being display:none below 481px. But only (a) is a defect; (b) is correct, intended design that
    must be preserved. This matters because it rules out a plausible-but-wrong fix — revealing the
    trigger on mobile would also make the symptom disappear while destroying the intended mobile
    chip-row design. The fix must therefore remove (a)'s reach into the band where (b) holds, and
    leave (b) alone."

---

## Current Focus — CYCLE 4 (chip row reads as fused to the header — spacing/sticky, not fill)

<!-- Cycles 1 (CLOSED, verified) and 2 (fix applied, REJECTED on real-device human review) are
     retained below for the record. Cycle 3 is the rejection evidence entry. This is the new,
     independent hypothesis cycle prompted by the user's explicit new feedback: "This need better
     space from top and bottom" + "Even that also is 'sticky' as header". -->

bug_class: Bohrbug (static layout outcome — deterministic on every load at ≤480px, no timing
  component; the sticky half is scroll-state-dependent but fully deterministic per scroll position)

reasoning_checkpoint:
  hypothesis: "The chip row reads as fused to the header because the band has ZERO vertical
    padding — the chips are flush against the header's bottom edge (1px hairline, no whitespace)
    and flush against the occlusion line where page content scrolls under. This is a PORT
    REGRESSION, not a design choice: sketch 020's `.index-row` (the direct source of
    `.pk-chip-nav`) declares `padding: var(--space-2) var(--space-4)` = 8px vertical / 24px
    horizontal. quick task 260824-jkc correctly replaced the HORIZONTAL padding with
    `.pk-chip-spacer` flex items (the documented iOS Safari trailing-padding fix) — but dropped
    the VERTICAL padding along with it, which that fix never required, because the iOS clip only
    affects the scroll axis. The result is the only horizontally-scrolling row in this app with
    no vertical padding: `.pk-rail` carries `padding: 8px 0` (app.css:285), `.pk-chip-nav` carries
    none. With 0px proximity between the two bands, no fill step available in this app's flat
    token ladder (max 1.415:1 light / 1.086:1 dark — cycle 2's own arithmetic) can break the
    perceptual grouping, which is exactly why cycle 2's fill-only fix was rejected on a real
    device."
  confirming_evidence:
    - "Measured at 390px in headless Chrome, both themes, scrolled and unscrolled:
      `.pk-chip-nav-wrap` computed `paddingTop: 0px`, `paddingBottom: 0px`, `marginTop: 0px`,
      `marginBottom: 0px`; `.pk-chip-nav` `paddingTop: 0px`, `paddingBottom: 0px`. Band rect
      y=64..109 (45px) = 1px border + a 44px chip and nothing else."
    - "`gapNavToWrap` measured 0.00px — `.pk-chip-nav-wrap`'s top edge IS `.pk-nav`'s bottom edge.
      The chip rect is y=65..109, i.e. the 44px pills occupy 100% of the band's content box, top
      edge touching the header's 1px rule and bottom edge touching the occlusion line."
    - "Sketch 020 source, the design this shipped from:
      `.planning/sketches/020-catalog-index-row/index.html:96` —
      `.index-row { ... padding: var(--space-2) var(--space-4); }` with `--space-2: 8px` per
      `.planning/sketches/themes/default.css:66`. Production's `.pk-chip-nav` (app.css:1911) is
      the same element with `padding` absent entirely. The vertical value was lost in the port."
    - "In-app precedent, same element class: `.pk-rail` — this app's other horizontal scroller —
      declares `padding: 8px 0` (app.css:285), matching the sketch's `--space-2`. The chip row is
      the sole exception in the file, which makes this an inconsistency, not a considered choice."
    - "Rendered screenshot at 390px light (post-cycle-2, base-100 band): the header bar's lavender
      ends at y=64 and the chip pills begin at y=65 with no whitespace whatsoever — the pills read
      as hanging off the header bar's bottom edge. This is the user's 'This need better space from
      top and bottom' verbatim, observed."
  falsification_test: "If `.pk-chip-nav-wrap`/`.pk-chip-nav` had computed a non-zero
    padding-top/bottom, or the wrap's top edge had NOT been coincident with the nav's bottom edge,
    or sketch 020's `.index-row` had declared no vertical padding either (making the flush band a
    faithful port rather than a regression), this hypothesis would be dead. All four were checked
    and all four point the same way."
  fix_rationale: "Restore the dropped vertical padding on the band, generously. This addresses the
    root cause (missing whitespace) rather than the symptom (perceived merging) and it is the
    user's own literal request. Put it on `.pk-chip-nav-wrap` rather than on `.pk-chip-nav` where
    the sketch had it: the wrap already owns the band's fill and border, its fade pseudo-elements
    are positioned against it (`top: 0; bottom: 0`) so they keep tracking the band's full height
    for free, and the project has a WRITTEN rule against padding on a horizontally-scrolling
    element (layout-navigation.md) — a future reader seeing `padding` back on `.pk-chip-nav` would
    reasonably 'fix' it to 0 and silently reintroduce this bug. 0.75rem (12px) not the sketch's
    8px: 8px is this app's INTERIOR rhythm value (`.pk-rail`), whereas this gap separates two
    levels of one hierarchy across a sticky boundary, and two prior fixes were already rejected as
    sub-perceptible — a boundary needs more air than an interior rhythm gap. 12px is still within
    the app's scale (Tailwind space-3) and sits between sketch 020's 8px and sketch 011's 16px."
  blind_spots: "Costs 24px of permanently-pinned header height (109px -> 133px at ≤480px), which
    is a real mobile viewport tradeoff the user has not been asked about — surfaced explicitly at
    the checkpoint. Does NOT change the sticky grouping: the chip row still shares `#app-header`'s
    common fate, matching sketch 020, so if the user's 'also is sticky as header' remark was a
    request to un-stick it rather than an observation, this fix will not satisfy it — that is a
    design change, deliberately left as an explicit user decision rather than made unilaterally.
    Verified in headless Chrome only, not on a physical device; the last two self-verified rounds
    were both rejected on real-device review, so this one goes to human verification with no claim
    of certainty."
  candidate_causes:
    - "code: `.pk-chip-nav-wrap`/`.pk-chip-nav` declare no vertical padding, so a 44px touch
      target fills a 45px band edge-to-edge with zero whitespace on either side (CONFIRMED — this
      is the defect, and it is a port regression traceable to a specific dropped declaration)."
    - "config/design-token: the surface ladder is too flat for any fill step to separate two
      adjacent bands (ruled out AS A DEFECT but CONFIRMED as the enabling condition — it is why
      cycle 2's colour-only fix could not work, and it is what makes whitespace the only available
      separator. A property of the themes, not a defect; preserved untouched)."
    - "environment: ruled out — a static computed style. Reproduced identically in both themes, at
      every scroll position, on every load. The human's real-device report and the headless
      measurement agree."
    - "data: ruled out — not content-dependent. The band is 45px with 8 chips or 1; the padding is
      a constant."
  and_gate: "yes — the perceived merge needs BOTH (a) zero whitespace between the bands and
    (b) a surface ladder too flat for a fill step to compensate. Only (a) is a defect and only (a)
    is being fixed; (b) is a theme property that must not be 'fixed' (widening the token gaps
    repaints every surface in the app). Stating this is what explains the cycle-2 failure rather
    than merely repeating it: cycle 2 attacked (b)'s consequence with the only lever (b) allows —
    a 1.415:1 step — and was arithmetically doomed before it shipped. Whitespace is not bounded by
    the token ladder, which is why attacking (a) can succeed where attacking (b) could not."

next_action: AWAITING HUMAN VERIFICATION. Fix applied and self-verified (see Resolution — CYCLE 4
  below; guardrail_verdict: accepted). The user must confirm on their real device at mobile width
  that the chip row now reads as separate from the header. If confirmed: run archive_session (move
  to resolved/, commit, append all cycles to knowledge-base.md). If NOT confirmed, the remaining
  hypothesis is the one deliberately NOT acted on here — taking the chip row out of the sticky
  `#app-header` so it scrolls away with the page. That is a design change (sketch 020 ships it
  sticky, and scroll-spy's highlight is only useful while the row is visible), so it needs the
  user's explicit call, not a unilateral fix. Do NOT re-attempt another surface-token/colour fix:
  cycle 2 falsified that whole class on real-device review and the arithmetic is in this file.

## Current Focus — CYCLE 2 (merged header/chip-row) — fix REJECTED on human review

<!-- Cycle 1 (search pill margin-left) is CLOSED, fixed and verified. Its reasoning_checkpoint is
     retained ABOVE for the record. Everything below is the new, independent hypothesis cycle. -->

bug_class: Bohrbug (visual/deterministic — a static cascade outcome, no timing component;
  reproduced identically on every load at ≤480px, in both themes, scrolled and unscrolled)

reasoning_checkpoint:
  hypothesis: "`.pk-chip-nav-wrap { background: var(--color-base-200) }` (app.css:1854, added by
    quick task 260824-jkc Task 2 / commit c61e6a6) gives the mobile chip index row the SAME fill
    as the header bar `.pk-nav` (app.css:537, also `var(--color-base-200)`). The two are flush,
    full-bleed and stacked inside the same sticky `#app-header`, so with identical fills the ONLY
    thing left to separate them is `.pk-chip-nav-wrap`'s `border-top: 1px solid
    var(--color-base-300)` — a hairline whose measured rendered contrast against base-200 is
    1.226:1 in light and 1.130:1 in dark. That is roughly 2.5x below the 3:1 non-text-contrast
    floor and is sub-perceptual, so the 64px header row and the 45px chip row render as one
    continuous 109px block."
  confirming_evidence:
    - "Rendered-pixel scan of a clean gutter column (x=178) of a real 390px headless-Chrome
      screenshot: y=0..63 `#F3ECFA`, y=64 `#E3D3F0` (one pixel), y=65..108 `#F3ECFA`, y=109+
      `#FFFFFF`. The header band and the chip band are BYTE-IDENTICAL fills; the entire boundary
      between them is a single 1px row at 1.226:1."
    - "Computed styles at 390px: `.pk-nav` backgroundColor `rgb(243, 236, 250)` and
      `.pk-chip-nav-wrap` backgroundColor `rgb(243, 236, 250)` — the same value, read off two
      different elements. `.pk-header` itself is `rgba(0,0,0,0)` with `border-radius: 0px` and
      `box-shadow: none`, so there is NO shared card wrapper: the merged look is the two fills,
      not an enclosing box."
    - "Theme-independent: the same scan in dark theme gives y=0..63 `#22103A`, y=64 `#2F1750`,
      y=65..108 `#22103A` — identical fills again, hairline contrast 1.130:1. The defect is not a
      light-theme artifact."
    - "Introduced by c61e6a6, verified against the diff: before that commit `.pk-chip-nav` had no
      background at all and `.pk-chip` carried `background: var(--color-base-100)`. The commit
      created `.pk-chip-nav-wrap` and gave it `background: var(--color-base-200)` — the same token
      the header already used. The `<:subnav>` slot was ALREADY inside the sticky `#app-header`
      before that commit (it arrived with 320fc4b), so the band is what changed, not the
      placement."
    - "The codebase's own documented constraint condemns this exact shape. app.css:107-108, in the
      theme block's MEASURED CONSTRAINTS comment: `#3D096D vs #7E4CA5 ....... 2.38:1 FAIL -> NEVER
      adjacent as surfaces or as two levels of one hierarchy`. Header chrome and page index are
      two levels of one hierarchy rendered as adjacent surfaces at 1.0:1 (identical)."
  falsification_test: "If the pixel scan had shown two DIFFERENT fills either side of y=64, or a
    border-radius/box-shadow on `.pk-header` or any common ancestor (the 'shared card' reading of
    the user's screenshot), or if the merge had appeared in only one theme, this hypothesis would
    be dead. All three were checked and all three point the same way: identical fills, no wrapper,
    both themes."
  fix_rationale: "Take the chip row OUT of the header's surface hierarchy rather than trying to
    draw a stronger line inside it. Arithmetic rules out the line: no pair of this app's surface
    tokens clears 3:1 — base-200/base-300 is 1.226:1 light and 1.130:1 dark, base-200/base-100 is
    1.415:1 light and 1.086:1 dark, and even the app's existing 8%-base-content shadow computes to
    1.170:1. A divider strong enough to clear 3:1 would need ~50% base-content, a hard rule that
    is a large aesthetic departure from this app's whisper-soft separations. So the boundary must
    be carried by a FILL STEP over the band's full 45px height, not by a 1px line: moving the chip
    band to `var(--color-base-100)` makes it the PAGE surface, which is what it semantically is (a
    page-level index, not header chrome), restores the relationship production shipped before
    c61e6a6, and matches the project's own validated finding in
    sketch-findings/references/layout-navigation.md — 'a hero/featured shelf background wash
    tested as muddy against a white background — a plain heading + thin divider read as cleaner
    than a light-lavender panel'. It also aligns the chip row's edge-fade gradients with
    `.pk-rail-wrap`'s (app.css:271/276, already `--color-base-100`); the chip fades were the only
    base-200 fades in the file."
  blind_spots: "Verified on CatalogLive.Index only, at 390px, in headless Chrome, light and dark,
    scrolled and unscrolled. Not verified: real physical devices, non-Chromium engines, or the
    filtered/Detalle views — but those never render `<:subnav>` at all (index.ex:498 gates it on
    `not filters_active?`), so the rule cannot reach them. Known and deliberately NOT fixed: in
    the scrolled state `.pk-nav.is-scrolled`'s base-300 `border-bottom` and the wrap's base-300
    `border-top` stack into a 2px line (measured y=63..64). That is pre-existing, sub-perceptual,
    outside the report, and reads as the intended scroll emphasis."
  candidate_causes:
    - "code: `.pk-chip-nav-wrap` declares the same surface token as `.pk-nav` for two adjacent
      full-bleed bands that represent two levels of one hierarchy (CONFIRMED — this is the defect)."
    - "config/design-token: the surface ladder is nearly flat — no two of base-100/200/300 clear
      1.42:1 in light or 1.23:1 in dark. This is why a base-300 hairline cannot rescue two
      same-fill bands, and it is what makes the FILL of each band load-bearing rather than
      decorative (CONFIRMED as the enabling condition — a property of the themes, not a defect;
      preserved untouched)."
    - "environment: ruled out — a static computed style with no engine, timing or device
      dependence; reproduced deterministically on every load."
    - "data: ruled out — not content-dependent. Eight chips render regardless; the bands merge
      with any chip content, and the band fills are constants."
  and_gate: "no. The failure needs only (a) — two adjacent bands declaring the same fill. The flat
    surface ladder is a real enabling CONDITION (it is why the hairline cannot compensate), but it
    is not a second defect and must not be 'fixed': widening the token gaps would restyle every
    surface in the app. Stating this explicitly matters because it rules out the tempting wrong
    fix — darkening `--color-base-300` to make the hairline visible would repaint every border in
    the app to repair one 45px band."

next_action: AWAITING HUMAN VERIFICATION. Fix applied and self-verified (see Resolution — CYCLE 2
  below; guardrail_verdict: accepted). User must confirm on their real device at mobile width that
  the header row and the chip index row now read as two distinct regions. If confirmed: run
  archive_session (move to resolved/, commit, append BOTH cycles to knowledge-base.md). If NOT
  confirmed, the next hypothesis to test is (e) from the rejected-alternatives list — moving the
  chip row out of the sticky `#app-header` so it scrolls with the page — which is a design change
  and needs the user's call, not a unilateral fix.

## Current Focus — CYCLE 1 (CLOSED, verified)

next_action: HUMAN VERIFICATION REJECTED the search-alignment fix as addressing the full report.
See "Human verification round 2" in Evidence below — user confirms the search icon position is
NOT the remaining problem; the remaining problem is the mobile category chip index row (the
"Destacados del club" / "Crea conexiones" / "Equipo g..." row rendered just below the header)
reading as visually MERGED into the header — i.e. no visual separation between the header row and
the chip row, so they appear as one continuous block/card rather than two distinct regions. This
is very likely the actual referent of the original trigger's second clause ("this is over same
line that header") — not the search icon's horizontal position, which the fix already corrected.
DO NOT revert the search-alignment fix (app.css:963, `@media not all and (max-width: 480px)`) —
it remains independently correct per its own verification block above and untouched by this new
symptom. Next action: investigate why/whether the header (`.pk-header` or equivalent) and the new
mobile chip row wrapper (`.pk-chip-nav-wrap`, added by quick task 260824-jkc Task 2) share a
background/border/shadow treatment that reads as one merged card, vs. the intended two visually
distinct rows. Check for a shared rounded-corner + box-shadow + inset margin applied to a common
ancestor of both the header and `.pk-chip-nav-wrap` at mobile widths, and whether that ancestor is
new/changed vs. pre-260824-jkc. Confirm against a real mobile viewport screenshot before proposing
a fix.

## Symptoms

expected: On mobile viewport widths, the catalog header's search control renders right-aligned within the header row, without overlapping or colliding with other header elements (brand, nav trigger, etc.).
actual: User reports that after the most recent implementation (quick task 260824-jkc — sketch 020's desktop mega-menu + mobile chip index row, commits 88483cd/c61e6a6/9b88168 on branch fix/footer-theme-toggle-balance), on mobile the search control's right alignment is broken, and it now sits "over" (overlapping/on top of) the same line as the header instead of its correct position.
errors: None reported.
timeline: Started immediately after the last implementation (quick task 260824-jkc). Not present before that work landed.
reproduction: Load the catalog page (`/`) at a mobile/narrow viewport width and inspect the header row — the search control (`.pk-search-morph` per the last implementation's summary) is misaligned relative to the right edge and appears to overlap the header line.

## Suspect areas (from prior session context, not yet verified)

- `assets/css/app.css` — Task 3 of quick task 260824-jkc added a "general-sibling override" to fix a `margin-left: auto` conflict between `.pk-cat-trigger` (new desktop mega-menu trigger) and `.pk-search-morph` (existing search control). This fix targeted desktop/≥50rem behavior; it may have altered mobile-width cascade for `.pk-search-morph`'s alignment rules as a side effect.
- Same commit also moved a breakpoint from `48rem` to a measured `50rem` for the mega-menu trigger's label reveal — worth checking whether any shared selector or media query boundary was affected below that breakpoint (mobile range).
- `lib/pukllay_club_web/components/layouts.ex` — header_inner/1 markup order, in case the new `nav_menu` slot changed flex/sibling order that `.pk-search-morph`'s CSS relies on.

## Evidence

<!-- ===== CYCLE 5 (un-stick chip row + retune spacing, per explicit user decision) ===== -->

- timestamp: 2026-08-25T00:40:00.000Z
  checked: POST-FIX VERIFICATION. Same headless Chrome + CDP viewport-emulation harness, re-run
    across 390/480/481/1280 x light/dark, unscrolled and at scrollY 300/1400, plus functional
    probes (chip horizontal scroll, chip anchor jump, scroll-spy, edge fades, drawer, desktop
    mega-menu), the two unreported pages (Detalle, Quiénes Somos) and the filtered catalog, a
    stash differential for scroll-spy, and the asset pipeline.
  found: |
    Band density at 390px, both themes:
      first heading  y=213 -> y=165   (48px reclaimed, 23% of pre-content budget)
      gapWrapToHeading  80px -> 32px
      main padding   80/80 -> 32/80   (bottom deliberately held)
      band itself    y=64..133, padding 12/12 — cycle 4 UNCHANGED
      --pk-header-h  133px -> 64px
    Un-stick, by differential at scrollY 1400: `.pk-nav` y=0..64 (pinned, `.is-scrolled` true)
    while `.pk-chip-nav-wrap` is at y=-1336..-1267 — full travel with the page. Cycle 4 measured
    the same band still pinned at y=64..133 at that scroll position. `header.contains(wrap)` false
    at every width.
    Desktop 1280px: main 80/80, heading y=145, --pk-header-h 65px — byte-identical to before.
    `docOverflow: 0` at every width x theme x scroll position.
    Scroll-spy stash differential (the silent-failure risk): active target sampled at
    y=0/700/1400/2100/2800/3500 at 390px AND 1280px, on the fixed tree and the stashed pre-fix
    tree — sequences IDENTICAL at every sample, `total: 16`, `active: 1` throughout.
    Chip anchor jump lands the shelf at y=79.9, 15.9px clear of the nav.
    Detalle + Quiénes Somos at 390px: main 32/80, CTA bars 68px/73px against 80px of preserved
    clearance, docOverflow 0. Filtered catalog: no `#app-subnav`, 0 chips, 0 spy targets, no JS
    errors.
    Gates: `mix quality` green end to end, 439 tests / 0 failures (435 before, +4 new).
    Pipeline: `.py-20` emitted 0 times, `padding: 0.75rem 0` intact, `spyRoots` present in the
    bundled app.js.
  implication: |
    Both halves confirmed in the units they were diagnosed in. The defect half closes on its own
    arithmetic — the 80.00px that WAS the gap is now 32px, with nothing else in the band touched.
    The design half is proven by relative motion between two elements that previously had none,
    which is the only observation that can distinguish "un-stuck" from "looks different".
    Two findings worth carrying forward beyond this fix. First, the stash differential converted
    the scroll-spy question from an assumption into a measurement, and in doing so surfaced a
    PRE-EXISTING bug it would otherwise have been blamed for: `spyTargetsBySection` is keyed by
    section, so a shelf's chip and its desktop `.pk-cat-item` collide and only the last collected
    wins — `.pk-cat-item` never highlights at any width, in either tree. Recorded, not fixed:
    unrelated to this report and a behaviour change to the desktop panel.
    Second, an existing gate (`catalog_live_test.exs`'s composite) failed on this change because it
    had encoded the OLD placement as a contract. That is the gate working, not noise — retargeted
    to assert the new location and `refute` the old one.
    Real-device confirmation still outstanding; three straight self-verified rounds have been
    corrected by the human, so this goes to checkpoint with no claim of certainty.

- timestamp: 2026-08-24T23:45:00.000Z
  checked: Human verification of the cycle-4 fix (0.75rem top/bottom padding on
    `.pk-chip-nav-wrap`), requested via AskUserQuestion with a before/after comparison image, plus
    a second question surfacing the debugger's two open design tradeoffs (133px header height; chip
    row staying sticky together with the header).
  found: |
    User did not explicitly confirm/reject cycle 4's gap fix directly, but replied to the
    tradeoffs question choosing "Un-stick the chip row" (make it scroll away with the page instead
    of staying pinned to `#app-header`), and separately reported, with a fresh screenshot attached:
    "I want to be sure there are a better space [manage]ment, since now this looks to[o]
    separated." Orchestrator's read of the attached screenshot: header (hamburger/logo/search) ->
    reasonable gap -> chip row ("Destacados del club" active pill etc., now clearly offset from the
    header, cycle 4's fix visibly present and working for the header<->chip-row boundary) -> a
    LARGE white gap -> "DESTACADOS DEL CLUB" heading + body copy. So the header-to-chip-row gap
    from cycle 4 reads as resolved/accepted implicitly (not called out as wrong), but there is now
    perceived EXCESS vertical space somewhere in the band, described as "too separated" overall.
  implication: |
    Two explicit, distinct user decisions/requests to execute now, together (not sequentially —
    they likely interact, since un-sticking the chip row removes it from `#app-header`'s pinned
    box entirely and will change the effective vertical rhythm around it):

    1. DESIGN CHANGE (explicit user sign-off given): un-stick `.pk-chip-nav-wrap` / the chip row
       from the sticky `#app-header` so it scrolls away normally with page content instead of
       staying pinned. This was previously flagged by the debugger as "a design change, not a bug
       fix" requiring explicit user approval — approval is now given. Scroll-spy behavior (mega-menu
       parity, per cycle-1/cycle-2 context) must keep working for whatever surface remains
       responsible for it; re-examine whether scroll-spy highlighting was tied to the row being
       always-visible/sticky, and adjust if needed so it still functions with the row in normal flow.
    2. SPACING RETUNE: after un-sticking (or independently, if un-sticking doesn't fully resolve
       it), re-examine and likely REDUCE the vertical space in this whole band — the user
       explicitly says it now looks "too separated" / wants "better space management", i.e. tighter,
       not looser. Do not simply add more of cycle 4's padding; the direction of change requested
       here is toward LESS excess whitespace, particularly wherever the large gap before "DESTACADOS
       DEL CLUB" is coming from (verify whether that gap is from `.pk-chip-nav-wrap`'s new padding,
       pre-existing main-content top spacing, or an interaction between the two once un-stuck).

    Re-verify holistically (both changes together) at 390/480/481/1280px, light+dark, scrolled and
    unscrolled, before returning to the user again. Given three straight self-verified rounds have
    now needed real-device correction, be conservative: capture fresh before/after screenshots
    specifically of the FULL band (header through the start of body content) so the user can judge
    overall density, not just the header/chip-row boundary in isolation.

<!-- ===== CYCLE 4 (missing vertical whitespace — the layout half of the merge) ===== -->

- timestamp: 2026-08-24T23:25:00.000Z
  checked: POST-FIX VERIFICATION. Same headless Chrome + CDP viewport-emulation harness, re-run
    across 390/480/481/1280 x light/dark, unscrolled and at scrollY 900/1400, plus functional
    probes (chip horizontal scroll, scroll-spy, fades, drawer, desktop mega-menu) and the asset
    pipeline.
  found: |
    Band geometry at 390px, both themes — `.pk-chip-nav-wrap` padding `12px 0px 12px 0px`:
      band  y=64..133 (69px)   was y=64..109 (45px)
      chips y=77..121 (44px)   was y=65..109 (44px)
      gap above chips 13px (1px rule + 12px padding)   was 1px
      gap below chips 12px                             was 0px
      --pk-header-h 133px                              was 109px
    480px identical. 481/1280px: wrap `display: none`, 0x0 rect, `--pk-header-h` 65px — unchanged.
    `docOverflow: 0` at every width x theme x scroll position.
    Scrolled (scrollY 1400, `.is-scrolled` true): band still pinned y=64..133 and still opaque
    (light `rgb(255,255,255)`, dark `rgb(23,10,38)`) — content occluded, not bled through.
    Functional: 8 chips; scroll-spy fires with exactly ONE `.is-active` chip ("Ingenio estratega")
    carrying the sketch 020 Round 2 treatment (light bg `rgb(237,225,247)` + border
    `rgb(61,9,109)`; dark its own -content pairing); both fades now 68px tall, tracking the taller
    band, correct per-theme token, z-index 4; chip nav still scrolls (scrollWidth 1223 >
    clientWidth 390, scrollLeft honoured); drawer opens; desktop mega-menu opens
    (aria-expanded true, visibility visible, opacity 1, 8 items, right-anchored at 1248).
    Cycle 1 regression check: `.pk-search-morph` trailing gap to `.pk-nav-inner`'s content edge
    = 0px at 390/480/481/1280 in both themes.
    Pipeline: `priv/static/assets/css/app.css:4545` carries `padding: 0.75rem 0` after
    `mix assets.build` — LightningCSS did not downlevel, merge or drop it.
    Gates: `mix quality` green end to end, 435 tests / 0 failures (433 before, +2 new).
  implication: |
    Fix confirmed in the same units the defect was measured in — rendered geometry, not source
    text. The two numbers that ARE the bug went 1px -> 13px and 0px -> 12px. Every capability
    260824-jkc shipped survives, and the change is provably inert above 480px because the element
    it touches generates no box there. Real-device confirmation still outstanding — the two prior
    self-verified rounds were both rejected by the human, so this goes to checkpoint without any
    claim of certainty.

- timestamp: 2026-08-24T23:05:00.000Z
  checked: Project design precedent for the chip row's own spacing, before choosing a value —
    sketch 020's source (`.planning/sketches/020-catalog-index-row/index.html`), sketch 011's
    (`.claude/skills/.../sources/011-full-shell-composition/index.html`), the sketch spacing
    tokens, and every horizontal scroller declared in app.css.
  found: |
    1. Sketch 020 `.index-row` (:96) — the direct source of `.pk-chip-nav`:
       `padding: var(--space-2) var(--space-4)`, with `--space-2: 8px` / `--space-4: 24px`
       (`.planning/sketches/themes/default.css:66,68`).
    2. Production `.pk-chip-nav` (app.css:1911) declares NO padding at all. The horizontal half was
       deliberately replaced by `.pk-chip-spacer { flex: 0 0 var(--pk-gutter) }` — the documented
       iOS Safari trailing-padding clip — but the VERTICAL half simply vanished.
    3. `.pk-rail` (app.css:285), this app's OTHER horizontal scroller: `padding: 8px 0`. The chip
       row is the only horizontally-scrolling element in the file with zero vertical padding.
    4. Sketch 011's earlier `.mobile-chip-nav` (:191): `padding: var(--space-3) 0 var(--space-4)`
       — 16px top / 24px bottom, i.e. even more air than 020.
  implication: |
    Decisive, and it reclassifies the defect. This is not a design choice that a human happens to
    dislike — it is a PORT REGRESSION with a named, dropped declaration and two independent
    in-repo precedents (the sketch it was ported from, and the sibling scroller that kept its
    padding). It also sets the fix's floor at 8px and its ceiling around 16-24px, which is what
    made 12px defensible rather than arbitrary: above the interior rhythm value because this gap
    separates two levels of one hierarchy across a sticky boundary, below sketch 011's because the
    band is pinned and every pixel is charged to the viewport permanently.

- timestamp: 2026-08-24T22:45:00.000Z
  checked: DIRECT MEASUREMENT of the LAYOUT half of the merge (cycle 2 measured only the COLOUR
    half) — headless Chrome + CDP at 390x844 against `http://localhost:4000/`, light and dark,
    unscrolled and at scrollY 700, reading computed padding/margin plus band/chip/nav rects.
  found: |
    `.pk-chip-nav-wrap`: paddingTop `0px`, paddingBottom `0px`, marginTop `0px`, marginBottom
    `0px`, display `block`, position `relative`, rect y=64..109 (h=45).
    `.pk-chip-nav`: paddingTop `0px`, paddingBottom `0px`, alignItems `center`, gap `8px`.
    `.pk-chip`: minHeight `44px`, rect y=65..109 (h=44).
    `.pk-nav`: rect y=0..64. Measured `gapNavToWrap`: **0.00px**.
    `#app-header`: position `sticky`, top `0px`, z-index `50`, rect y=0..109 at scrollY 0 AND
    y=0..109 at scrollY 700 — both bands pinned identically, zero relative motion.
    `--pk-header-h` 109px. Identical in both themes.
  implication: |
    Root cause observed directly. The 44px pills fill 100% of the band's content box: their top
    edge touches the header's 1px rule and their bottom edge touches the line where page content
    scrolls under. There is no whitespace anywhere in the 109px block — which is the user's "This
    need better space from top and bottom" as a measurement rather than an impression.
    It also explains cycle 2's rejection instead of merely restating it: perceptual grouping is
    decided by adjacency at 0px proximity, and cycle 2's own arithmetic had already bounded every
    achievable fill step at 1.415:1 (light) / 1.086:1 (dark) against a 3:1 floor. The colour lever
    was exhausted before it shipped; the whitespace lever was never pulled, and it is the one
    separator NOT bounded by the token ladder. Cycle 2's fill step stays — necessary, not
    sufficient.
    The sticky measurement additionally confirms the user's "also is 'sticky' as header": the two
    bands share `#app-header`'s common fate exactly, at every scroll position. That is real, but it
    matches sketch 020 (which nests the index row inside the sticky nav) so it is a design question
    rather than a defect — routed to the checkpoint, not fixed unilaterally.

<!-- ===== CYCLE 3 (cycle-2 fix rejected by human on real device) ===== -->

- timestamp: 2026-08-24T22:00:00.000Z
  checked: Human verification of the cycle-2 fix (base-200 -> base-100 on `.pk-chip-nav-wrap`),
    requested via AskUserQuestion with before/after screenshots attached. Followed up twice to
    rule out staleness: (1) asked user to hard-refresh / use a private window, (2) explicitly asked
    whether the just-sent screenshot was a fresh post-refresh capture on http://localhost:4000/.
  found: |
    User confirmed: "Yes, fresh from http://localhost:4000/ incognito. Even that also is 'sticky'
    as header" — i.e. genuinely fresh, no-cache, correct URL, and STILL perceives the header and
    chip row as one merged/glued unit. Orchestrator independently re-checked assets/css/app.css
    (source) and priv/static/assets/css/app.css (compiled) — both correctly show
    `.pk-chip-nav-wrap { background: var(--color-base-100) }`, mtimes match (in sync), no other
    rule in the file re-declares a background on `.pk-chip-nav-wrap` or overrides it. So this is
    NOT a cache/staleness issue and NOT an unapplied-fix issue — the fix IS live in the user's
    browser and is STILL visually insufficient.
  implication: |
    This corroborates the cycle-2 reasoning_checkpoint's OWN stated numbers rather than
    contradicting them: the chosen fix (base-200 -> base-100) only reaches 1.415:1 contrast in
    light theme and a mere 1.086:1 in dark theme (both figures are in the cycle-2 fix_rationale
    above, computed by the debugger itself) — both far under the codebase's own documented 3:1
    "MEASURED CONSTRAINTS" floor for adjacent surfaces (app.css:107-108). The debugger's own
    analysis already concluded "no pair of this app's surface tokens clears 3:1" and chose the fill
    step as the *least-bad available option among existing tokens* — but a human on a real
    device/theme/ambient-lighting condition confirms that this fill step is, as predicted by the
    contrast math, NOT reliably perceptible. The fix direction (surface-token swap alone) is
    INSUFFICIENT and should be considered falsified by human observation, not just re-attempted
    with a different token pair (no pair clears 3:1 per the debugger's own arithmetic).

    Additionally, the user gave NEW, distinct, actionable feedback in the same message, independent
    of the color/contrast question: "This need better space from top and bottom" — i.e. the chip
    row wrapper currently has no vertical breathing room (padding/margin) separating it from the
    header above and the page content below; the user wants real spacing (a gap), not merely a
    color or line change. The user also flagged the chip row reads as "sticky" together with the
    header, reinforcing that the perceived defect is as much about LAYOUT/SPACING and STICKY
    grouping as about fill color.

    This session's OWN already-queued fallback hypothesis (recorded at the end of cycle 2, per the
    debug-session-manager's return: "move the chip row OUT of the sticky #app-header so it scrolls
    away with the page") is now directly supported by human evidence, not just a hedge. Combined
    with the user's explicit ask for top/bottom spacing, the next fix attempt should almost
    certainly: (a) add real vertical padding/margin around/within `.pk-chip-nav-wrap` so there is an
    actual visual GAP (not just a color step) between it and the header, and (b) seriously evaluate
    taking the chip row out of the sticky `#app-header` (or giving it its own independent
    sticky/non-sticky treatment) so it no longer reads as fused to the header bar. A fix should be
    considered verified only once it produces a GENUINE, unambiguous visual gap (real whitespace
    and/or a clearly perceptible >=3:1-equivalent boundary) — re-confirm with a human before
    declaring success again; do not re-declare this checkpoint passed on self-measurement alone
    given the last two self-verified rounds were both rejected on real-device review.

<!-- ===== CYCLE 2 (merged header/chip-row) ===== -->

- timestamp: 2026-08-24T21:20:00.000Z
  checked: POST-FIX VERIFICATION. Same headless Chrome + CDP harness, re-run across
    390/480/481px x light/dark, unscrolled and scrolled, plus a functional probe and a desktop
    pass at 1280px.
  found: |
    Boundary, rendered pixels at x=178 (clean inter-chip gutter), 390px:
      light  y=0..63 #F3ECFA | y=64 #E3D3F0 | y=65.. #FFFFFF   (fill step 1.415:1 over 45px)
      dark   y=0..63 #22103A | y=64 #2F1750 | y=65.. #170A26   (two-step 1.130 then 1.227:1)
    Before the fix both themes had IDENTICAL fills either side of y=64. There is now a real fill
    step carrying the boundary over the band's whole height instead of a 1px hairline.
    Computed: `.pk-nav` base-200 vs `.pk-chip-nav-wrap` base-100 at 390/480/481 in both themes;
    both edge fades track the band (`linear-gradient(90deg, rgb(255,255,255), rgba(0,0,0,0))` /
    `rgb(23,10,38)` in dark) — no smudge. `--pk-header-h` still 109px at ≤480 / 64-65px above.
    `docOverflow: 0` at every width and theme.
    Scrolled (scrollY 700): band still sticky at top=64, bottom=109, still opaque — content is
    occluded, not bled through. Pre-existing 2px scrolled line at y=63..64 (nav's is-scrolled
    base-300 border + the wrap's base-300 border) unchanged by this fix.
    Functional: 8 chips; wrap still `position: relative` with both fade pseudo-elements at
    z-index 4; chip nav still horizontally scrollable (scrollWidth > clientWidth, scrollLeft
    honoured); scroll-spy still fires with exactly ONE `.is-active` chip carrying the sketch 020
    Round 2 treatment (bg #EDE1F7 accent tint, border+text #3D096D primary); drawer still opens.
    Desktop 1280px: `.pk-chip-nav-wrap` `display: none` with a 0x0 rect, trigger `flex`,
    mega-menu opens with all 8 items, panel right-anchored at 1248 matching the header gutter.
    Cycle 1 regression check: `.pk-search-morph` trailing gap to `.pk-nav-inner`'s content edge
    = 0px at 390/480/481 in both themes. The search fix is intact.
  implication: |
    Fix confirmed at the level the defect was measured — rendered pixels, not source text. The
    symptom is gone by the same arithmetic that identified it: the boundary that was 1.0:1 (same
    fill) + a 1.226:1 hairline is now a 1.415:1 fill step sustained over 45px. Every capability
    shipped by 260824-jkc (fades, horizontal scroll, scroll-spy, active-chip treatment, drawer,
    desktop mega-menu) survives, and the fix is provably inert above 480px because the element it
    touches generates no box there.

- timestamp: 2026-08-24T21:05:00.000Z
  checked: Whether a stronger DIVIDER could fix this instead of changing the band's fill —
    computed WCAG relative-luminance contrast for every candidate line/surface pair in both
    themes, then cross-checked against rendered pixels.
  found: |
    light: base-200/base-300 1.226:1 | base-200/base-100 1.415:1 | base-200 vs the app's existing
      8%-base-content scroll shadow 1.170:1
    dark:  base-200/base-300 1.130:1 | base-200/base-100 1.086:1 | (ladder is flatter than light)
    Nothing in the app's surface/line vocabulary reaches the 3:1 non-text-contrast floor. Reaching
    it would need roughly a 50% base-content rule in light (~3.25:1) / ~38% in dark.
  implication: |
    Decisive, and it redirected the fix. A hairline CANNOT carry this boundary at these tokens —
    which is exactly why the shipped `border-top: 1px solid var(--color-base-300)` failed to do
    it. Two options remained: a ~50% base-content hard rule (a large aesthetic departure — nothing
    else in this app draws a line that heavy, and the whole surface language is whisper-soft), or
    carry the boundary as a FILL STEP over the band's full 45px. Chose the fill step. Also rules
    out the tempting token-level "fix" of darkening `--color-base-300` to make the hairline
    visible: that would repaint every border in the app to repair one 45px band.

- timestamp: 2026-08-24T20:50:00.000Z
  checked: Project design precedent, before choosing between candidate treatments —
    `.claude/skills/sketch-findings-pukllay_club/references/{layout-navigation,page-shell}.md`,
    sketch 020's own README + index.html, and app.css's theme block.
  found: |
    1. layout-navigation.md: "A hero/featured shelf background wash (gradient panel behind the
       row) tested as 'muddy' against a white background — a plain heading + thin divider read as
       cleaner than a light-lavender panel."
    2. app.css:107-108, in the theme block's MEASURED CONSTRAINTS comment: "#3D096D vs #7E4CA5
       ....... 2.38:1 FAIL -> NEVER adjacent as surfaces or as two levels of one hierarchy."
    3. Sketch 020's index.html is where the merged treatment originates: `.app-nav` and
       `.index-wrap` BOTH use `--color-surface`, and the sketch theme's tokens are byte-identical
       to production's (surface #F3ECFA, border #E3D3F0, bg #FFFFFF). Production is a faithful
       port; the sketch carried the defect.
  implication: |
    Finding 1 is directly on point and describes the winning treatment: page surface + thin
    divider, NOT a light-lavender panel. Finding 2 is the codebase's own written rule, and the
    shipped state violates it in its strongest form — not two sub-3:1 colours as adjacent
    surfaces of one hierarchy, but the SAME colour (1.0:1). Finding 3 matters for the postmortem:
    this is not implementation drift from the sketch, so "port the sketch faithfully" would not
    have caught it — the sketch is a 390px-wide iframe inside a white tools page, where the
    merged band is far less obvious than it is filling a real phone screen.

- timestamp: 2026-08-24T20:40:00.000Z
  checked: `git show c61e6a6 -- assets/css/app.css` (the Task 2 delta that created the wrap), and
    `git log -S"subnav" -- lib/pukllay_club_web/components/layouts.ex` for when the chip row
    became part of the sticky header.
  found: |
    Before c61e6a6: `.pk-chip-nav` declared NO background (transparent) and `.pk-chip` carried
    `background: var(--color-base-100)`. c61e6a6 created `.pk-chip-nav-wrap` with
    `background: var(--color-base-200)` + `border-top: 1px solid var(--color-base-300)`, moved the
    ≤480px display swap onto it, and changed `.pk-chip` to `background: transparent`.
    The `<:subnav>` slot was ALREADY rendered inside the sticky `#app-header` before c61e6a6 — it
    arrived with 320fc4b (phase 01.1), not with 260824-jkc.
  implication: |
    Pins the regression to one declaration and rules out two rival stories. (a) It is NOT that the
    chip row newly became sticky/attached to the header — that placement predates the task. (b)
    Reverting to a transparent band is NOT available as a fix: the band sits in a `position:
    sticky` stack, so transparent means page content bleeds THROUGH the chip row while scrolling.
    Making the band opaque was correct and necessary; choosing the header's own token for it is
    the defect. So the fix must change WHICH opaque surface it paints, never remove the surface —
    which is now pinned by an assertion.

- timestamp: 2026-08-24T20:30:00.000Z
  checked: DIRECT MEASUREMENT — headless Chrome over CDP (viewport emulation via
    `Emulation.setDeviceMetricsOverride`, NOT OS window resize, which the orchestrator found
    unreliable here) against `http://localhost:4000/` at 390x844, plus PNG pixel-column scans of
    the real screenshots.
  found: |
    Computed styles: `.pk-nav` backgroundColor `rgb(243, 236, 250)`; `.pk-chip-nav-wrap`
    backgroundColor `rgb(243, 236, 250)` — the same value on two different elements.
    `.pk-chip-nav-wrap` `border-top: 1px solid rgb(227, 211, 240)`, `display: block`,
    `position: relative`, rect y=64 h=45. `.pk-nav` rect y=0 h=64. `--pk-header-h` 109px.
    Ancestor chain from the wrap up to <body>: `.pk-header.pk-header-sticky` has
    `background: rgba(0,0,0,0)`, `border-radius: 0px`, `box-shadow: none`; then a
    `display: contents` LiveView wrapper; then <body>, transparent. <html> is `rgb(255,255,255)`.
    Pixel scan at x=178 (a clean gap between two chips), light theme:
      y=0..63 #F3ECFA | y=64 #E3D3F0 | y=65..108 #F3ECFA | y=109.. #FFFFFF
    Same scan, dark theme: #22103A | #2F1750 | #22103A | #170A26.
  implication: |
    Root cause observed directly, and one rival reading killed outright. The user's screenshot was
    read by the orchestrator as "one continuous rounded card with a drop shadow" — there is NO
    such card: every ancestor of both bands is transparent with zero radius and no shadow (that
    was device/browser chrome in the screenshot). The merge is entirely the two fills. The header
    band and the chip band are BYTE-IDENTICAL, so the whole boundary is one pixel row at 1.226:1
    (light) / 1.130:1 (dark), and the only real edge in the top 109px is at y=109 where the block
    finally meets the page. That is precisely "one continuous block instead of two distinct
    regions", and it is theme-independent.

<!-- ===== CYCLE 1 (search pill margin-left) — CLOSED ===== -->

- timestamp: 2026-08-24T20:00:00.000Z
  checked: Human verification of the applied search-alignment fix, requested via AskUserQuestion
    against the running dev server (http://localhost:4000/) at mobile width.
  found: |
    User rejected "confirmed fixed" and attached a screenshot (DATA_START user-attached image,
    not further parsed here DATA_END) of the catalog header at a narrow viewport. Orchestrator's
    read of the screenshot: hamburger icon (left), brand mark (left-center), circular search
    button (right edge) all in the header row — the search button visually appears correctly
    right-aligned, not overlapping anything. Below the header: the category chip row
    ("Destacados del club" active, "Crea conexiones", "Equipo g..." partially visible,
    horizontally scrollable). The whole header+chip-row block appears to render as a single
    rounded-corner card with a drop shadow on its right/bottom edges against a lighter page
    background, rather than two independent full-bleed rows.
  implication: |
    Follow-up Q&A with the user (not the debugger) established, in order:
    1. User was shown that the search icon looks correctly right-aligned in the screenshot and
       asked to pinpoint the actual problem. User's answer: "What is wrong is the index
       categories" — i.e. the chip row, not the search icon.
    2. Asked to characterize the chip-row problem specifically (merged-with-header vs.
       wrong/missing chips vs. overlap-or-clipping). User's answer: "Merged with header."
    So the CONFIRMED remaining defect is: the mobile chip index row is not visually distinct from
    the header — it reads as part of the same block/card — not a position or content error in the
    chips themselves, and not the search icon (which the applied fix already corrected and which
    the user did not flag as wrong on further questioning). This is a DIFFERENT rule/selector than
    the one fixed above (that fix only touched `.pk-search-morph`'s `margin-left`); the merged-look
    defect is most likely a shared background/border-radius/box-shadow declaration reaching a
    container that wraps both the header and `.pk-chip-nav-wrap`, or the two elements simply
    sharing an identical surface color with no dividing border/shadow between them at mobile
    widths. Orchestrator could not independently reproduce via headless browser in this pass (see
    next entry) — this needs a fresh gsd-debugger investigation pass, not a continuation of the
    already-closed search-alignment hypothesis.

- timestamp: 2026-08-24T19:55:00.000Z
  checked: Orchestrator attempted independent visual reproduction via claude-in-chrome browser
    automation against the running dev server before escalating to the user (resize_window to
    390x844/390x800, navigate to http://localhost:4000/, screenshot).
  found: Screenshot consistently returned at 1568x667 (desktop-width render) regardless of the
    resize_window target; the browser's OS-level window would not narrow below desktop width in
    this environment (suspected tiling-window-manager constraint, unrelated to the app).
  implication: Orchestrator-side visual verification is NOT reliable in this environment. The
    debugger MUST use its own headless Chrome + CDP viewport-emulation approach (as it did
    successfully for the search-alignment fix — setting the CDP viewport/device metrics directly
    rather than relying on OS window resize) to reproduce and verify this next.

- timestamp: 2026-08-24T18:05:00.000Z
  checked: Knowledge base (`.planning/debug/knowledge-base.md`) queried for search/header/align/mobile patterns.
  found: Two near-neighbour entries — `search-expand-header-overlap` (a dropped `.pk-search-morph`
    base rule, incl. its `margin-left: auto`, via a premature CSS comment terminator) and
    `header-height-wordmark-wrap` (a mobile-only `@media (max-width: 480px)` override MASKING a
    defect that lived above that breakpoint).
  implication: Both are hypothesis candidates, not diagnoses. `search-expand-header-overlap` is
    ELIMINATED below (base rule intact). `header-height-wordmark-wrap`'s generalizable lesson is
    the live one and it inverts here: this time the ≤480px block is where the defect LANDS rather
    than where it is masked. The KB's recurring theme — a rule whose applicability band does not
    match the band its author reasoned about — is exactly the shape of this bug.

- timestamp: 2026-08-24T18:07:00.000Z
  checked: Ran the existing guard `mix test test/pukllay_club_web/header_search_gutter_test.exs`
    (added by quick task 260824-hu1 to pin the open ≤480px pill's inset/padding/radius against
    `--pk-gutter`).
  found: 6 tests, 0 failures.
  implication: The OPEN mobile state's contract is intact and is not the regression.
    `.pk-search-morph.is-open` is `position: absolute; inset: 0 var(--pk-gutter)` at ≤480px
    (app.css:2389-2396), so its placement is inset-driven and immune to any margin change. This
    narrows the defect to the CLOSED (44px icon) state, whose placement is margin-driven — and
    correctly explains why an existing gate stayed green.

- timestamp: 2026-08-24T18:10:00.000Z
  checked: `git show 9b88168 -- assets/css/app.css` — the only CSS delta in quick task
    260824-jkc Task 3.
  found: Exactly two changes. (1) The label-reveal breakpoint moved 48rem -> 50rem, entirely
    inside `@media (min-width: 50rem)` — cannot affect ≤480px. (2) A NEW top-level rule
    `.pk-cat-trigger ~ .pk-search-morph { margin-left: 0 }` inserted at app.css:963 with NO
    enclosing media query.
  implication: Change (1) is eliminated by construction — a `min-width: 50rem` block is inert at
    mobile widths. Change (2) is the only delta in this commit that can reach the mobile cascade,
    and it directly targets the one property (`margin-left`) that owns the search pill's right
    alignment. Prime suspect.

- timestamp: 2026-08-24T18:12:00.000Z
  checked: `.pk-search-morph` base rule, app.css:642-657.
  found: Rule is present and intact in source, including `margin-left: auto` (line 652),
    `display: flex`, `height: 44px`, `flex: 0 0 auto`, `overflow: hidden`.
  implication: This is NOT a recurrence of KB entry `search-expand-header-overlap` (dropped base
    rule). The base rule survives; `margin-left: auto` is being OVERRIDDEN by a later, more
    specific rule rather than lost to a parser error. Different mechanism, same visual symptom
    class. Eliminated as a duplicate.

- timestamp: 2026-08-24T18:15:00.000Z
  checked: Media-query context of the `.pk-cat-trigger { display: none }` declaration
    (app.css:2349-2351) — nearest preceding `@media` boundaries are 48rem (2217), 50rem (2236),
    and `max-width: 480px` (2307).
  found: Line 2349 sits inside `@media (max-width: 480px)`. The trigger is therefore
    `display: none` for the entire mobile band, alongside `.pk-nav-links { display: none }`
    (2341) and `.pk-nav-hamburger { display: flex }` (2353).
  implication: Below 481px the mega-menu trigger renders no box at all — so it neither absorbs
    free space nor supplies the right-push its own `margin-left: auto` (app.css:920) provides on
    desktop. But it REMAINS in the DOM, so the `~` combinator at line 963 still matches. This is
    the load-bearing asymmetry: selector matching is a DOM-tree operation, box generation is a
    layout operation, and `display: none` separates the two.

- timestamp: 2026-08-24T18:18:00.000Z
  checked: Header markup order in `lib/pukllay_club_web/components/layouts.ex:472-528`
    (`header_inner/1`), plus the `nav_menu` slot doc at :147-150 and `category_menu/1` at :561.
  found: `.pk-nav-inner`'s children in source order are: `.pk-nav-hamburger` (476),
    brand `.shrink-0` (490), `.pk-nav-crumb` (493, Detalle only), `.pk-nav-links` (496),
    `{render_slot(@nav_menu)}` (499, renders `.pk-cat-trigger`), then `.pk-search-morph` (500).
  implication: `.pk-cat-trigger` is an immediately-preceding DOM sibling of `.pk-search-morph` on
    CatalogLive at EVERY viewport width — the slot is rendered unconditionally and hidden purely
    by CSS. So the `~` override is active on mobile by construction, and the effective mobile row
    is [hamburger][brand][links: none][trigger: none][search margin-left:0] — leaving the search
    pill with nothing pushing it right, landing it against the brand lockup on the same line.
    This matches the user's "breaks the right alignment" AND "is over same line that header".

- timestamp: 2026-08-24T18:35:00.000Z
  checked: DIRECT MEASUREMENT — headless Chrome over CDP against the running dev server at
    `http://localhost:4000/`, widths 390/480/481/1280, closed and open states, reading
    `getComputedStyle`, `getBoundingClientRect`, and `Element.matches()` for the `~` selector.
  found: At 390px CLOSED — `triggerDisplay: "none"`, `triggerRect: 0x0 at (0,0)` (no box), yet
    `triggerMarginLeft: "auto"` and `morph.matches('.pk-cat-trigger ~ .pk-search-morph') === true`;
    `morphMarginLeft: "0px"`; morph rect left=110 right=154; `.pk-nav-inner` content right edge
    = 376. Trailing gap to the right edge: **222px** (right-aligned == 0). Gap from brand's right
    edge: 8px — exactly `.pk-nav-inner`'s 0.5rem mobile row gap. Full mobile row geometry:
    hamburger 14-58, brand 66-102, search 110-154, then 222px of dead space to 376.
    At 480px CLOSED — same shape, trailing gap **312px**.
    At 481px CLOSED — `triggerDisplay` flips to `"flex"`, trailing gap **0px** (correct).
    At 1280px CLOSED — trigger `marginLeft: 469.969px` (its auto resolving), trailing gap **0px**
    (correct); OPEN also 0px. `docOverflow: 0` at every width.
  implication: HYPOTHESIS CONFIRMED, and confirmed by the strongest available evidence — the
    mechanism observed directly rather than inferred. `display: none` + a matching `~` combinator
    is the exact mechanism: the selector matches, the box does not exist, the auto margin is
    stripped with nothing to replace it. The failure boundary (broken at 480, correct at 481)
    coincides precisely with the `max-width: 480px` block that hides the trigger, which
    differentiates this cause from every other candidate — no other rule in the file changes state
    at that boundary in a way that touches the pill's margin. Desktop behaviour is correct and
    must be preserved, so the fix is to scope the override, not remove it.

- timestamp: 2026-08-24T18:37:00.000Z
  checked: Open-state measurement at 390/480px, cross-checked against the green gutter guard.
  found: `morphPosition: "absolute"`, morph spans left=14 right=376 at 390px, trailing gap 0px.
  implication: Confirms the open state is structurally immune (inset-driven, not margin-driven)
    and independently corroborates why `header_search_gutter_test.exs` stayed green through this
    regression. The fix must therefore be judged on the CLOSED state, and the existing guard is
    not a sufficient gate for this class — a new one is required.

## Eliminated

- hypothesis: Recurrence of KB entry `search-expand-header-overlap` — the `.pk-search-morph` base
    rule was dropped from the cascade by a CSS parse error, losing its `margin-left: auto`.
  evidence: Base rule verified present and complete in source at app.css:642-657 with
    `margin-left: auto` on line 652; `stylesheet_integrity_test.exs` guards this class and the
    suite is green. Measurement further shows the property resolving to a real `0px` (an applied
    override), not to the initial value. The property is overridden, not lost.
  timestamp: 2026-08-24T18:12:00.000Z

- hypothesis: The 48rem -> 50rem breakpoint move for `.pk-cat-trigger-label` altered the mobile
    cascade as a side effect (listed as a suspect area in the prior session's notes).
  evidence: The entire change is contained within `@media (min-width: 50rem)` (app.css:2236) and
    a `display: none` base declaration for `.pk-cat-trigger-label` (941-943) that only ever
    hides a label. A `min-width: 50rem` block cannot apply at ≤480px, and the label is a child of
    the trigger, not a sibling of the search pill — it has no bearing on the row's free-space
    distribution. Measurement confirms: the failure boundary is 480/481, not 768 or 800.
  timestamp: 2026-08-24T18:10:00.000Z

- hypothesis: The open-state mobile overlay's inset/gutter geometry regressed (the area quick task
    260824-hu1 last touched).
  evidence: `header_search_gutter_test.exs` green (6/6); measured open state at 390px is
    `position: absolute` spanning the full gutter line with a 0px trailing gap. The regression is
    in the CLOSED state.
  timestamp: 2026-08-24T18:07:00.000Z

- hypothesis: `header_inner/1` markup/slot order changed, breaking a sibling-order assumption.
  evidence: Markup order verified at layouts.ex:472-528 and matches the documented contract
    (`nav_menu` immediately before `.pk-search-morph`). The order is correct and is what the
    mega-menu's containing-block/anchoring contract requires; the ordering is not the defect —
    the unconditional CSS override that keys off it is.
  timestamp: 2026-08-24T18:18:00.000Z

- hypothesis: The fix is to reveal `.pk-cat-trigger` on mobile (or otherwise give it a box) so it
    can absorb the free space as it does on desktop.
  evidence: Rejected by the AND-gate analysis, not by measurement — it WOULD make the symptom
    disappear, which is precisely why it is dangerous. The mobile design deliberately replaces the
    mega-menu with the chip index row (`.pk-chip-nav-wrap { display: block }`, app.css:2345), and
    the trigger must stay in the DOM for the desktop panel's containing-block contract
    (layouts.ex:535-537). Treating an intended design condition as the defect would trade a
    layout bug for a design regression.
  timestamp: 2026-08-24T18:40:00.000Z

## Resolution — SESSION (final, human-confirmed 2026-08-25)

<!-- Session-level rollup. The per-cycle blocks below remain authoritative for their own
     measurements, arithmetic and rejected alternatives; this block is the closing record. -->

human_verification: |
  CONFIRMED FIXED by the user on 2026-08-25, on their real device at mobile width, against
  `http://localhost:4000/` after a hard refresh / incognito load (the same anti-staleness protocol
  that caught nothing in cycle 3 and is therefore known to be honest here). The user confirmed both
  halves of the final change in their own words: the spacing "now feels right" — tighter, with the
  header-to-chip-row gap still clearly readable — and the chip row "scrolls away with the page",
  with only the top bar staying pinned.

  This is the FIRST human confirmation in the session after three consecutive self-verified rounds
  were rejected on real-device review (cycles 1-report-remainder, 2 and implicitly 4). The pattern
  is the session's most transferable lesson and is recorded in the postmortem below.

root_cause: |
  FOUR confirmed defects across five cycles, in three different mechanisms. They were separate
  causes, not one cause re-diagnosed — which is why each needed its own falsification test.

  1. CYCLE 1 — search pill not right-aligned at <=480px.
     `.pk-cat-trigger ~ .pk-search-morph { margin-left: 0 }` was declared UNSCOPED at the top level
     (app.css:963). The `~` combinator matches on DOM TREE structure, but the behaviour the rule
     hands off to (the trigger absorbing the row's free space) requires the trigger to generate a
     BOX. `display: none` separates those two things, so below 481px — where the trigger is hidden
     but still in the DOM — the override stripped the pill's `margin-left: auto` with nothing
     replacing the right-push. Measured: closed pill at x=110, 222px of dead space before
     `.pk-nav-inner`'s content edge at 376.

  2. CYCLE 2 — header and chip row read as one continuous block (COLOUR half; necessary, not
     sufficient). `.pk-chip-nav-wrap` painted `var(--color-base-200)` — the same token `.pk-nav`
     already paints. Two full-bleed bands, byte-identical fills, the whole boundary left to a 1px
     base-300 hairline at 1.226:1 light / 1.130:1 dark against a 3:1 floor.

  3. CYCLE 4 — same symptom, LAYOUT half (the sufficient one). The band declared no vertical
     padding at all: 44px chips filling a 45px band edge to edge, `gapNavToWrap` measured 0.00px.
     A port regression — sketch 020's `.index-row` ships `padding: var(--space-2) var(--space-4)`
     and 260824-jkc dropped the vertical half while correctly replacing the horizontal half with
     `.pk-chip-spacer`. At 0px proximity no fill step this app's token ladder can produce (max
     1.415:1 light / 1.086:1 dark) breaks perceptual grouping, which is why cycle 2 alone failed on
     a real device.

  4. CYCLE 5 — "too separated" after cycle 4. `Layouts.app`'s `<main class="py-20">` — a flat
     80px of top padding at EVERY viewport width with no responsive step anywhere in the codebase.
     `gapWrapToHeading` measured 80.00px exactly: that one declaration was 100% of the gap the user
     photographed. Cycle 4's 12px band padding was 5.6% of the 213px stack and was NOT the cause,
     which is what ruled out the tempting "back out last round's change" fix.

  Cycle 5 also carried a change with NO defect behind it, kept deliberately separate: the subnav
  slot rendered inside the `position: sticky` `#app-header`, so the chip row shared the header's
  common fate. That is what sketch 020 shipped; it changed only because the user explicitly chose
  "Un-stick the chip row" at an AskUserQuestion checkpoint.

fix: |
  - `assets/css/app.css` — the cycle-1 override wrapped in `@media not all and (max-width: 480px)`
    (the exact complement of the block that hides the trigger, chosen over `min-width: 481px` to
    avoid a sub-pixel band matching neither rule); `.pk-chip-nav-wrap` moved to
    `var(--color-base-100)` with both edge-fade gradients following it; `.pk-chip-nav-wrap` gains
    `padding: 0.75rem 0`; three stale comments corrected so they cannot mislead the next reader.
  - `lib/pukllay_club_web/components/layouts.ex` — `{render_slot(@subnav)}` moved out of BOTH
    `#app-header` branches into a sibling `<div :if={@subnav != []} id="app-subnav">`; `.CatalogNav`
    now collects scroll-spy targets from BOTH roots (`this.spyRoots = [this.el,
    document.getElementById("app-subnav")].filter(Boolean)`) — the load-bearing half, since a
    hook still scoped to `this.el` would have left the chips rendering and silently never
    highlighting; `<main>`'s `py-20` -> `pb-20 pt-8 sm:pt-20` (top only, because `pb-20` is
    load-bearing clearance for two `position: fixed` bottom CTA bars; mobile only, because desktop
    was never reported).
  - Three regression suites: `header_search_right_align_test.exs` (new, 5 assertions),
    `header_chip_band_separation_test.exs` (new, 5 assertions across cycles 2 and 4),
    `header_subnav_placement_test.exs` (new, 4 assertions), plus
    `live/catalog_live_test.exs` retargeted from the old chip-row placement to the new one.

why_not_caught: |
  Blameless, and the answer differs per cycle — which is the useful part.

  - Cycles 1, 2 and 4: NO GATE EXISTED FOR THIS CLASS. Every one of these defects is a RENDERED
    GEOMETRY or RENDERED COLOUR outcome — a computed margin, two computed fills, a computed padding
    — and this repo's gates are `mix format` / `credo` / `sobelow` / ExUnit over rendered HTML
    STRINGS. None of them can see a cascade result. Cycle 1 is the sharpest illustration: the
    pre-existing sibling guard `header_search_gutter_test.exs` was green THROUGH the regression,
    because the markup it asserts on never changed — only the cascade did. A test that reads HTML
    cannot catch a CSS-cascade defect, so the gate was not weak, it was absent.
  - Cycle 1 additionally: the introducing change (260824-jkc Task 3) was measured at 1280px only,
    where it was correct. The defect lives in the complement of the band it was verified in, and
    nothing forced a mobile re-measurement of a rule shipped without a media query.
  - Cycle 4: a PORT REGRESSION with no gate possible — a declaration present in the sketch source
    (`.planning/sketches/020-catalog-index-row/index.html:96`) was simply absent from the
    production port. Nothing in this project diffs a sketch against its implementation.
  - Cycle 5: `py-20` was not "missed" — it predates the whole feature and was correct when the app
    was desktop-first. It became a defect when a 69px band was added above it at mobile. No gate
    catches a value that is only wrong in combination with something added later.
  - CROSS-CUTTING, and the session's real finding: THREE self-verified rounds were rejected on
    real-device human review. Headless-Chrome measurement proved reliable for identifying MECHANISM
    (every root cause above was confirmed by direct measurement and none was wrong) but proved
    unreliable for judging PERCEPTUAL SUFFICIENCY — cycle 2 was arithmetically doomed before it
    shipped by numbers the debugger itself had computed. Measurement answers "is the value what I
    think it is"; it does not answer "does a human see it".

recurrence_guard: |
  - `test/pukllay_club_web/header_search_right_align_test.exs` — 5 assertions, 2 RED-verified
    against the real pre-fix stylesheet via `git stash`. Pins that the `~` override is media-scoped
    and that the 480px literal appears in both coupled places.
  - `test/pukllay_club_web/header_chip_band_separation_test.exs` — 5 assertions, 2 RED-verified.
    Pins that `.pk-nav` and `.pk-chip-nav-wrap` must not paint the same surface token, that the
    fades track the band's fill, that the band is not "separated" by going transparent (which would
    re-introduce the sticky bleed-through c61e6a6 fixed), that vertical padding stays above an 8px
    floor, and — as a boundary neighbour — that `.pk-chip` stays >= 44px so the header height is
    never clawed back by shrinking the touch target.
  - `test/pukllay_club_web/header_subnav_placement_test.exs` — 4 assertions, 3 RED-verified. Pins
    the chip row OUTSIDE `#app-header`, the hook collecting from both spy roots, `<main>`'s mobile
    top padding within a 16-48px band, and `pb-20` preserved as CTA-bar clearance.
  - `test/pukllay_club_web/live/catalog_live_test.exs` — the existing composite gate FIRED on this
    change because it had encoded the old placement as a contract. Retargeted rather than deleted,
    and now `refute`s the old location, so a silent revert has to argue with a test.
  - PROCESS guard, the one with the widest reach: perceptual/visual claims on this project go to
    HUMAN verification before being declared fixed. Self-measurement establishes mechanism, not
    sufficiency. Recorded in the knowledge base so the next investigation inherits it.

known_not_fixed: |
  Two PRE-EXISTING findings surfaced by this session's instrumentation, both proven pre-existing by
  a stash differential rather than assumed, both out of scope for a bugfix and recorded so they are
  not rediscovered from scratch:

  1. `spyTargetsBySection` is a `Map` keyed by SECTION, but two surfaces share the
     `data-chip-target` contract — a shelf's mobile chip and its desktop `.pk-cat-item` row collide
     on one key and only the last collected wins. Chips are collected last in BOTH the pre-fix and
     post-fix trees, so `.pk-cat-item` never highlights at any width. Confirmed identical on both
     sides of the stash differential. Fixing it is a behaviour change to the desktop mega-menu
     panel and belongs in its own task.
  2. The hook collects spy targets once at `mounted()` and never re-collects in `updated()`, so a
     filters-on/filters-off round trip leaves stale node references. Identical before and after
     cycle 5's move (both `:subnav` and `:nav_menu` are gated on `not filters_active?`, and both
     already lived inside the hook element before the move), so the move neither caused nor worsened
     it.

files_changed:
  - assets/css/app.css (cycles 1, 2, 4, 5)
  - lib/pukllay_club_web/components/layouts.ex (cycle 5)
  - test/pukllay_club_web/header_search_right_align_test.exs (new — cycle 1)
  - test/pukllay_club_web/header_chip_band_separation_test.exs (new — cycles 2 and 4)
  - test/pukllay_club_web/header_subnav_placement_test.exs (new — cycle 5)
  - test/pukllay_club_web/live/catalog_live_test.exs (cycle 5 — existing gate retargeted)

## Resolution — CYCLE 5 (un-stuck chip row + mobile vertical budget)

root_cause: |
  TWO changes, only ONE of which has a defect behind it. Keeping them separate is the point —
  conflating them is what would make the sticky change look like a bug fix and the padding change
  look like a preference.

  (1) NO DEFECT — a design change the user explicitly approved. `{render_slot(@subnav)}` rendered
  as a child of `#app-header`, which is `position: sticky; top: 0`. Sticky pins the whole box, so
  the chip row shared the header's common fate: cycle 4 measured `#app-header` at y=0..133 at
  scrollY 0 AND unchanged at y=0..133 at scrollY 1400. No CSS can exempt a child from its
  ancestor's sticky box, so the row had to leave the element — a markup change, not a rule.

  (2) THE DEFECT behind "this looks too separated". `Layouts.app`'s `<main class="py-20">` — a flat
  5rem/80px of vertical padding at EVERY viewport width, with no responsive step anywhere in the
  codebase. Measured at 390px: nav y=0..64, chip band y=64..133, then `mainPadTop: 80px`, putting
  the first heading at y=213 — 25% of an 844px viewport (~32% of a 667px iPhone SE) spent before
  any content. `gapWrapToHeading` measured **80.00px exactly**, i.e. `py-20` accounted for 100% of
  the gap the user photographed; no margin, no `space-y-*` collapse and none of cycle 4's band
  padding contributed. A desktop-scale value shipped unconditionally to phones.

  What makes (2) worth stating carefully is the wrong fix it rules out. The obvious inference after
  cycle 4 is "I added 12px of band padding last round and the user now says it is too separated, so
  back that out." The arithmetic forbids it: cycle 4's padding is 12px of a 213px stack (5.6%), so
  removing it entirely would reclaim less than a sixth of what `py-20` alone costs — while
  re-introducing the exact glued-band defect cycles 2-4 spent three rounds establishing. The excess
  was somewhere the user could not see and could only be found by measuring.

  AND-gate: NO for the reported symptom. The gap needs only `py-20`; 80.00px of 80px accounts for
  all of it, so there is no second necessary condition. (1) is a separate axis with no gate at all.

fix: |
  (1) UN-STICK — `lib/pukllay_club_web/components/layouts.ex`.
  `{render_slot(@subnav)}` moved out of BOTH `#app-header` branches (sticky and non-sticky) into a
  sibling `<div :if={@subnav != []} id="app-subnav">` between the header and `<main>`.

  The hook change is the load-bearing half, and it is a latent-bug fix rather than a cosmetic one.
  `.CatalogNav` collected scroll-spy targets with `this.el.querySelectorAll("[data-chip-target]")`
  where `this.el` IS `#app-header`. Two surfaces share that attribute — the 8 desktop
  `.pk-cat-item` rows (still inside the header) and the 8 mobile chips (now outside). Left scoped
  to `this.el`, the hook would still find all 8 desktop rows and ZERO chips: the chips would keep
  rendering, keep scrolling, look completely healthy, and silently never highlight again. Now:
  `this.spyRoots = [this.el, document.getElementById("app-subnav")].filter(Boolean)` and a flatMap
  over both. Named roots rather than a bare `document` query so the two participating surfaces stay
  explicit.

  `--pk-header-h` needed no change and corrected itself, which is the payoff for it having been
  derived rather than hardcoded: published from `#app-header`'s own height, it now reports the nav
  alone (64px at <=480px, was 133px). Its consumer `.pk-shelf { scroll-margin-top:
  calc(var(--pk-header-h) + 1rem) }` therefore drops 149px -> 80px, which is a CORRECTION — a jump
  that cleared the chip row was overshooting by the band's full height now that the row no longer
  occludes anything. Measured: clicking a chip lands the target shelf at y=79.9 with 15.9px of
  clearance below the nav's bottom edge at y=64.

  (2) MOBILE VERTICAL BUDGET — same file. `<main>`'s `py-20` -> `pb-20 pt-8 sm:pt-20`.
  TOP only and MOBILE only, both deliberately:
    - top only, because `pb-20` is not symmetric decoration — it is the clearance keeping the last
      content on Detalle (`.pk-mobile-cta-bar`, measured 68px) and Quiénes Somos
      (`.pk-about-cta-bar`, measured 73px) out from behind their `position: fixed; bottom: 0` CTA
      bars. Cutting the bottom to match would trade a spacing complaint for a content-occlusion bug
      on two pages that were never part of the report.
    - mobile only (`sm:pt-20` restores it at 640px), because 80px under a 65px desktop header is a
      normal airy layout and was never what was reported. Desktop is byte-identical.
    - 32px rather than 0, because this layer's documented page-container value is `py-6`/24px and
      its section rhythm is `space-y-6`; 32px sits just above that floor, cuts the reported gap by
      60%, and is on the Tailwind scale rather than an invented number.

  Deliberately NOT touched: cycle 4's `padding: 0.75rem 0` on `.pk-chip-nav-wrap`. The user's
  screenshot shows that boundary reading correctly and they did not flag it; the ask was to trim
  excess elsewhere. Cycle 5 refunded its COST rather than the whitespace — those 24px are ordinary
  page pixels that scroll away now, not viewport permanently spent.

  Also NOT touched, and recorded rather than fixed: `spyTargetsBySection` is a Map keyed by section,
  so a shelf's chip and its desktop `.pk-cat-item` collide on one key and the last one collected
  wins. Chips are collected last both before and after this change, so `.pk-cat-item` never
  highlights at any width. Proven pre-existing by a stash differential (below), unrelated to this
  report, and fixing it is a behaviour change to the desktop panel that belongs in its own task.

  Three stale comments corrected in `assets/css/app.css` so they cannot mislead the next reader:
  `.pk-shelf`'s scroll-margin rationale (cited the chip row as "attached"), and two claims inside
  `.pk-chip-nav-wrap`'s comment (that the band sits inside the sticky header, and that its padding
  costs pinned header height).

verification: |
  guardrail_verdict: accepted

  1. Root cause observed directly, not inferred: `mainPadTop` read `80px` identically at
     390/480/481/1280 in both themes, and `gapWrapToHeading` computed to exactly 80.00px — so the
     one declaration accounts for the whole measured gap, with no residue pointing at a second
     cause. The rendered 390px screenshot shows the empty band directly (y=133..213).

  2. Symptom eliminated, measured in the same units: first heading y=213 -> y=165 at 390px (48px
     reclaimed, a 23% cut in pre-content vertical budget); `gapWrapToHeading` 80px -> 32px;
     `mainPadTop` 80px -> 32px with `mainPadBottom` held at 80px.

  3. The un-stick proven by DIFFERENTIAL, not by reading the markup. At scrollY 1400, 390px:
     `.pk-nav` rect y=0..64 (still pinned, `.is-scrolled` true) while `.pk-chip-nav-wrap` is at
     y=-1336..-1267 — it has travelled the full scroll distance with the page. Cycle 4 measured
     that same band still pinned at y=64..133 at the same scroll position. `header.contains(wrap)`
     returns `false` at every width; `--pk-header-h` 133px -> 64px.

  4. Breakpoint x theme sweep, unscrolled + scrolled (300/1400), `docOverflow: 0` everywhere:
       390 light/dark  nav 0..64, band 64..133 (pad 12/12 intact), main 32/80, heading 165, hH 64px
       480 light/dark  identical
       481 light/dark  band `display: none`, 0x0 rect, main 32/80, heading 96
      1280 light/dark  band `display: none`, main 80/80, heading 145, hH 65px — DESKTOP UNCHANGED

  5. Regression tests verified RED on the real pre-fix tree, not written green. With
     `git stash push -- assets/css/app.css lib/.../layouts.ex`, 3 of the 4 new assertions fail with
     their intended diagnostics ("`<main>` reserves 80px of top padding at mobile widths, over the
     48px ceiling"; "The chip row is rendering INSIDE `#app-header`..."; the hook-scope one). Green
     again after `git stash pop`. The 4th (bottom-padding clearance) and the minimum-top-padding
     assertion are boundary neighbours around the fixed defect's equivalence class — green by
     construction, guarding the two OPPOSITE wrong fixes: collapsing the gap to nothing, and
     re-symmetrising the padding into one `py-*`.

  6. An EXISTING gate caught the change and was retargeted rather than deleted:
     `catalog_live_test.exs`'s composite test asserted `header_html =~ "pk-chip-nav"` — it encoded
     the old placement contract. Now `refute`s the old location and asserts the new one, so a
     silent revert has to argue with a test.

  7. Scroll-spy proven un-regressed by a STASH DIFFERENTIAL rather than by inspection — the highest
     risk in this change, since the failure mode is silent. Sampled the active target at
     y=0/700/1400/2100/2800/3500 at both 390px and 1280px, on the fixed tree and on the stashed
     pre-fix tree. The two sequences are IDENTICAL at every sample (390px: Destacados del club ->
     Equipo ganador -> Ingenio estratega -> Recientemente añadidos; 1280px: Destacados -> Equipo
     ganador -> Descubre el hobby -> Nivel experto), with `total: 16` targets and `active: 1`
     throughout. Same run also established that `.pk-cat-item` never highlights in EITHER tree,
     which is what proves that pre-existing and not caused here.

  8. Shipped functionality exercised, not assumed, at 390px: chip nav still scrolls horizontally
     (scrollWidth 1223 > clientWidth 390, `scrollLeft` honoured at 200); chip anchor jump lands the
     shelf at y=79.9, 15.9px clear of the nav; both edge fades 68px tall tracking the band at
     z-index 4 with the correct per-theme token (light `rgb(255,255,255)`, dark `rgb(23,10,38)`),
     each matching the wrap's own `backgroundColor` exactly; active chip carries the sketch 020
     Round 2 treatment (`rgb(237,225,247)`); chips still 44px; drawer opens (aria-expanded true,
     visibility visible); desktop mega-menu opens at 1280px with 8 items right-anchored at 1248.

  9. Blast radius of (2) measured on the two pages the user did NOT report, rather than reasoned
     about: Detalle (`/juegos/177`) and Quiénes Somos both render `mainPadTop: 32px` /
     `mainPadBottom: 80px` at 390px, `docOverflow: 0`, no `#app-subnav`, `--pk-header-h` 64px, and
     their fixed CTA bars measure 68px and 73px against 80px of preserved bottom clearance. The
     filtered catalog (`/?q=catan`) emits no `#app-subnav`, 0 chips, 0 spy targets and no JS errors
     — nothing orphaned by the move.

  10. Cycles 1, 2 and 4 not regressed: `.pk-search-morph`'s trailing gap to `.pk-nav-inner`'s
      content edge is 0px at 390/480/481/1280 in both themes (cycle 1); the band still paints
      base-100 against the nav's base-200 (cycle 2); `.pk-chip-nav-wrap` still reads
      `paddingTop/paddingBottom: 12px` and the chip rect is still 44px (cycle 4).

  11. Project gates: `mix quality` green end to end — hex.audit, deps.audit,
      deps.unlock --check-unused, format --check-formatted (Styler active, no rewrites),
      credo --strict, sobelow --config (only the pre-existing low-confidence directory-traversal
      findings in the seed importer, untouched), and `test --warnings-as-errors` at 439 tests /
      0 failures (435 before, +4 new).

  12. Survives the asset pipeline: after `mix assets.build`, `.py-20` is emitted 0 times in
      `priv/static/assets/css/app.css`, `.pk-chip-nav-wrap`'s `padding: 0.75rem 0` is still there,
      and `spyRoots` appears in the bundled `priv/static/assets/js/app.js` — so the colocated hook
      change actually reached the browser rather than only the source tree.

  Not verified: real physical devices, non-Chromium engines. This is the material caveat and it is
  why this goes to human verification with no claim of certainty — THREE straight self-verified
  rounds have now been corrected on real-device review.

  Known and recorded, deliberately NOT fixed: (a) the `spyTargetsBySection` Map collision above;
  (b) the hook collects spy targets once at mount and never re-collects in `updated()`, so a
  filters-on/filters-off round trip leaves stale node references — identical before and after this
  change, since both `:subnav` and `:nav_menu` are gated on `not filters_active?` and both already
  lived inside the hook element.

files_changed:
  - lib/pukllay_club_web/components/layouts.ex (subnav moved out of both `#app-header` branches
    into `#app-subnav`; `.CatalogNav` collects scroll-spy targets from both roots; `<main>`
    `py-20` -> `pb-20 pt-8 sm:pt-20`; `:subnav` slot doc rewritten to the new contract; rationale
    for both changes recorded inline)
  - assets/css/app.css (three stale comments corrected — `.pk-shelf`'s scroll-margin rationale and
    two claims in `.pk-chip-nav-wrap`'s comment; no declaration changed)
  - test/pukllay_club_web/header_subnav_placement_test.exs (new — 4 assertions, 3 RED-verified)
  - test/pukllay_club_web/header_chip_band_separation_test.exs (two assertion rationales updated
    where they cited the now-retired sticky-occlusion argument; no assertion weakened)
  - test/pukllay_club_web/live/catalog_live_test.exs (composite test retargeted from the old
    placement to the new one, with a `refute` pinning the old location)

## Resolution — CYCLE 4 (chip row fused to the header — missing whitespace)

root_cause: |
  `.pk-chip-nav-wrap` (and `.pk-chip-nav` inside it) declared NO vertical padding, so the band was
  exactly `1px border + one 44px chip` and nothing else. Measured at 390px in both themes:
    band  y=64..109 (45px)
    chips y=65..109 (44px)  -> the pills filled the band's content box edge to edge
    gap from `.pk-nav`'s bottom edge to the wrap's top edge: 0.00px
  So the 44px pills touched the header bar's 1px rule above them and the line where page content
  scrolls under the sticky band below them. There was ZERO whitespace anywhere in the 109px block.

  This is why cycle 2's fix was rejected on a real device rather than being merely unlucky. At 0px
  proximity, perceptual grouping is decided by adjacency, and no fill step this app's tokens can
  produce breaks it — cycle 2's own arithmetic already bounded the entire ladder at 1.415:1 (light)
  and 1.086:1 (dark) against a 3:1 floor. Whitespace is the one separator NOT bounded by that
  ladder, which is exactly why attacking this condition can succeed where attacking the colour
  could not. Cycle 2's fill step was necessary (the two bands must not paint the same token) but
  not sufficient; both fixes are kept.

  The flush band was a PORT REGRESSION, traceable to one dropped declaration. Sketch 020's
  `.index-row` — the direct source of `.pk-chip-nav` — declares
  `padding: var(--space-2) var(--space-4)` (`.planning/sketches/020-catalog-index-row/index.html:96`,
  with `--space-2: 8px` at `.planning/sketches/themes/default.css:66`). quick task 260824-jkc
  correctly replaced the HORIZONTAL half with `.pk-chip-spacer` flex items — the documented iOS
  Safari trailing-padding clip — but dropped the VERTICAL half along with it, which that fix never
  required, because the iOS clip only affects the scroll axis. The result left the chip row as the
  only horizontal scroller in the file with no vertical padding: `.pk-rail`, this app's other
  horizontal scroller, ships `padding: 8px 0` (app.css:285).

  AND-gate: the perceived merge needs BOTH (a) zero whitespace between the bands and (b) a surface
  ladder too flat for a fill step to compensate. Only (a) is a defect and only (a) was fixed; (b)
  is a theme property that must not be "fixed" — widening the token gaps would repaint every
  surface in the app.

fix: |
  `.pk-chip-nav-wrap` gains `padding: 0.75rem 0` (app.css:1876-1912 rule family).

  On the WRAP, not on `.pk-chip-nav` where the sketch had it, for two reasons: the fade
  pseudo-elements are positioned against the wrap (`top: 0; bottom: 0`), so they keep spanning the
  band's full height for free (measured 68px after the change, tracking the 69px band minus its
  1px border); and this layer carries a WRITTEN rule against padding on a horizontally-scrolling
  element (layout-navigation.md, the iOS clip), so `padding` reappearing on `.pk-chip-nav` would
  read as that bug to the next reader and get "fixed" back to 0, silently reintroducing this one.

  0.75rem (12px), not the sketch's 8px: 8px is this app's INTERIOR row rhythm (`.pk-rail`), while
  this gap separates two levels of one hierarchy across a sticky boundary — and two sub-perceptible
  fixes had already been rejected here, so the instruction was to be generous rather than
  borderline. 12px is still on the app's scale (Tailwind space-3) and sits between sketch 020's 8px
  and sketch 011's 16px/24px for the same row.

  Measured result at 390px, both themes: band y=64..133 (69px, was 45px), chips y=77..121 (still
  44px), 13px of clear space above the chips (1px rule + 12px padding) and 12px below — where both
  were previously 1px and 0px.

  Accepted cost, deliberately: `--pk-header-h` goes 109px -> 133px at <=480px. That 24px of extra
  pinned header is the literal price of the whitespace the user asked for; it is recorded in the
  rule's comment and raised explicitly at the human checkpoint rather than hidden.

  Rejected alternatives: (a) another surface-token swap — falsified as a class by cycle 2's
  real-device rejection plus its own arithmetic; do not retry. (b) A ~50% base-content divider —
  clears 3:1 but is a hard rule alien to this app's whisper-soft surface language, and it still
  would not answer the user's actual request for SPACE. (c) Shrinking `.pk-chip` below 44px to keep
  the header height constant — trades a spacing bug for an accessibility one; pinned by a new
  assertion so it cannot be done later. (d) Taking the chip row out of the sticky `#app-header` —
  the strongest possible separation (it breaks common fate outright) and it would also refund the
  24px, but sketch 020 ships the row inside the sticky nav and scroll-spy's `is-active` highlight
  is only useful while the row is on screen. That is a design change, not a bug fix, so it is left
  as an explicit user decision at the checkpoint.

  CSS-only, one declaration, no markup and no JS. Provably inert above 480px: `.pk-chip-nav-wrap`
  is `display: none` there with a measured 0x0 rect and `--pk-header-h` unchanged at 65px.

verification: |
  guardrail_verdict: accepted

  1. Root cause observed directly, not inferred: computed `paddingTop`/`paddingBottom` read `0px`
     on both `.pk-chip-nav-wrap` and `.pk-chip-nav`, and the measured gap from `.pk-nav`'s bottom
     edge to the wrap's top edge was 0.00px with the chip rect (y=65..109) exactly filling the band
     rect (y=64..109). A rendered 390px screenshot shows the pills hanging off the header bar's
     bottom edge with no whitespace.

  2. The defect was traced to a specific dropped declaration, not just described: sketch 020's
     `.index-row` carries `padding: var(--space-2) var(--space-4)`; production's `.pk-chip-nav` has
     no `padding` at all; `.pk-rail` — the same element class — carries `padding: 8px 0`. The chip
     row was the file's only zero-vertical-padding horizontal scroller.

  3. Symptom eliminated, measured in the same units: 13px above the chips and 12px below, where
     the pre-fix values were 1px and 0px. Band 45px -> 69px, chips unchanged at 44px.

  4. Breakpoint x theme sweep, unscrolled and scrolled — `docOverflow: 0` at every combination:
       390 light/dark   band y=64..133, chips y=77..121, gaps 13/12, `--pk-header-h` 133px
       480 light/dark   same
       481 light/dark   wrap `display: none`, 0x0 rect, `--pk-header-h` back to 65px
      1280 light/dark   wrap `display: none`, 0x0 rect, mega-menu opens (aria-expanded true,
                        visibility visible, opacity 1, 8 items, right-anchored at 1248)
     Scrolled (scrollY 1400, `.is-scrolled` active): band still pinned at y=64..133 and still
     opaque (light `rgb(255,255,255)`, dark `rgb(23,10,38)`) — content occluded, not bled through.

  5. Regression test verified RED on the real defect, not written green: with
     `git stash push -- assets/css/app.css` restoring the pre-fix stylesheet, the new assertion
     fails with its intended diagnostic ("`.pk-chip-nav-wrap` reserves 0px of padding-top, under
     the 8px floor"). Green again after `git stash pop`. The 44px-touch-target assertion is a
     boundary neighbour guarding the tempting wrong fix (clawing the 24px back by shrinking the
     chip); it is green by construction and exists to stay that way.

  6. Shipped functionality intact — exercised, not assumed: 8 chips render; scroll-spy still fires
     with exactly ONE `.is-active` chip ("Ingenio estratega") carrying the sketch 020 Round 2
     treatment (light: accent tint `rgb(237,225,247)` + primary `rgb(61,9,109)` border; dark: its
     own -content pairing); both fade pseudo-elements track the taller band at 68px with the
     correct per-theme token and z-index 4; the chip nav still scrolls horizontally (scrollWidth
     1223 > clientWidth 390, `scrollLeft` honoured at 200); the drawer still opens; the desktop
     mega-menu still opens with all 8 rows.

  7. Cycles 1 and 2 not regressed: `.pk-search-morph`'s trailing gap to `.pk-nav-inner`'s content
     edge is 0px at 390/480/481/1280 in both themes, and the band still paints base-100 against the
     header's base-200 (its own suite is green).

  8. Project gates: `mix quality` green end to end — hex.audit, deps.audit,
     deps.unlock --check-unused, format --check-formatted (Styler active, no rewrites),
     credo --strict, sobelow --config (only the pre-existing low-confidence directory-traversal
     findings in the seed importer, untouched), and `test --warnings-as-errors` at 435 tests /
     0 failures (433 before, +2 new).

  9. Survives the asset pipeline: after `mix assets.build`, `priv/static/assets/css/app.css:4545`
     carries `padding: 0.75rem 0` inside the `.pk-chip-nav-wrap` rule — LightningCSS did not
     downlevel, merge or drop it.

  Not verified: real physical devices, non-Chromium engines. This is the material caveat — the two
  previous self-verified rounds were both rejected on real-device human review, so this fix goes to
  human verification making no claim of certainty. Closed by construction rather than measurement:
  Detalle, Quiénes Somos and the filtered catalog never render `<:subnav>` at all
  (index.ex:498 gates it on `not filters_active?`), so no `.pk-chip-nav-wrap` exists there.

  Known and deliberately NOT changed: the chip row still shares `#app-header`'s sticky common fate.
  If the user's "also is 'sticky' as header" remark was a request to un-stick it rather than an
  observation about why it looked merged, this fix will not satisfy it — see rejected alternative
  (d) and the checkpoint.

files_changed:
  - assets/css/app.css (`.pk-chip-nav-wrap` gains `padding: 0.75rem 0`, with the measured rationale
    and the port-regression trace recorded in the rule's comment)
  - test/pukllay_club_web/header_chip_band_separation_test.exs (+2 assertions, 1 RED-verified:
    vertical-whitespace floor and the 44px touch-target boundary neighbour)

## Resolution — CYCLE 2 (merged header/chip-row) — fill step; necessary but NOT sufficient

root_cause: |
  `assets/css/app.css:1854` declared `.pk-chip-nav-wrap { background: var(--color-base-200) }` —
  the SAME surface token `.pk-nav` already paints (app.css:537). The mobile category chip index
  row and the header bar are two full-bleed, opaque bands stacked flush inside the same sticky
  `#app-header`, so with identical fills the entire boundary between them fell to the wrap's
  `border-top: 1px solid var(--color-base-300)`.

  Measured from real screenshots at 390px, pixel column x=178 (a clean gap between two chips):
    light  y=0..63 #F3ECFA | y=64 #E3D3F0 | y=65..108 #F3ECFA | y=109.. #FFFFFF
    dark   y=0..63 #22103A | y=64 #2F1750 | y=65..108 #22103A | y=109.. #170A26
  The two bands are byte-identical; the hairline between them computes to 1.226:1 in light and
  1.130:1 in dark — roughly 2.5x under the 3:1 non-text-contrast floor, i.e. sub-perceptual. So
  the 64px header row and the 45px chip row render as one continuous 109px block, whose only real
  edge is at y=109 where it finally meets the page. That is the reported "the chip index row is
  merged with the header — one continuous block instead of two distinct regions", and it is why
  the original trigger's second clause ("this is over same line that header") kept being true
  after cycle 1's search fix landed.

  This is the exact shape app.css's own theme-block comment forbids (:107-108): "#3D096D vs
  #7E4CA5 ... 2.38:1 FAIL -> NEVER adjacent as surfaces or as two levels of one hierarchy". Header
  chrome and a page-level index are two levels of one hierarchy; shipped, they were adjacent
  surfaces at 1.0:1.

  Single defect. The flat surface ladder (no pair of base-100/200/300 clears 1.42:1 in light or
  1.23:1 in dark) is a real enabling CONDITION — it is why the base-300 hairline could not
  compensate — but it is not a second defect and was deliberately left alone: widening the token
  gaps would repaint every surface and border in the app to repair one 45px band.

  Introduced by quick task 260824-jkc Task 2 (commit c61e6a6). Not a placement change: the
  `<:subnav>` slot already lived inside the sticky header before that task (320fc4b). Not
  implementation drift either — sketch 020's own index.html puts `.app-nav` and `.index-wrap` on
  the same `--color-surface`, against a byte-identical token set. The sketch carried the defect;
  production ported it faithfully.

fix: |
  Moved the chip band off the header's surface and onto the PAGE surface, and moved its two
  edge-fade gradients with it:
    .pk-chip-nav-wrap          background: var(--color-base-200) -> var(--color-base-100)
    .pk-chip-nav-wrap::before  linear-gradient(90deg,  base-200 -> base-100, transparent)
    .pk-chip-nav-wrap::after   linear-gradient(270deg, base-200 -> base-100, transparent)

  A fill step, not a stronger line — because the arithmetic rules the line out. No pair of this
  app's surface/line tokens reaches 3:1 in either theme (base-200/300 1.226:1 light, 1.130:1 dark;
  base-200/100 1.415:1, 1.086:1; the existing 8% base-content scroll shadow 1.170:1), and a line
  that did would need ~50% base-content in light / ~38% in dark — a hard rule nothing else in this
  app draws. Carrying the boundary as a fill step spreads it over the band's full 45px instead of
  one pixel row, and it also states the right thing semantically: this row is a page-level index,
  not header chrome. It restores the relationship production shipped before c61e6a6, matches the
  validated finding in layout-navigation.md ("a plain heading + thin divider read as cleaner than
  a light-lavender panel"), and makes the chip fades consistent with `.pk-rail-wrap`'s, which
  already use base-100 — the chip fades were the only base-200 fades in the file.

  The `border-top: 1px solid var(--color-base-300)` is KEPT. It is now a crisp underline on a real
  fill step rather than the sole boundary, and it is what keeps dark theme legible (base-200 ->
  base-100 alone is only 1.086:1 there; with the hairline it is a two-step 1.130 then 1.227).

  Rejected alternatives: (a) darkening `--color-base-300` so the hairline reads — repaints every
  border in the app for one band; (b) a ~50% base-content divider — clears 3:1 but is a hard rule
  alien to this app's whisper-soft surface language; (c) base-300 for the band — 1.226:1 light /
  1.130:1 dark against the header, i.e. no better than the hairline it replaces; (d) reverting the
  band to transparent (the pre-c61e6a6 state) — NOT available: the band is in a `position: sticky`
  stack, so transparency lets page content bleed through the chip row while scrolling, which is
  the bug c61e6a6 was fixing. Pinned by an assertion so it cannot be "fixed" that way later.
  (e) Moving the chip row out of the sticky header entirely — would separate them decisively, but
  that is a design change to what sketch 020 shipped, not a bug fix, and the user characterised
  the problem as visual merging rather than wrong placement.

  CSS-only, three declarations in one rule family, no markup and no JS. Provably inert above
  480px: `.pk-chip-nav-wrap` is `display: none` there with a measured 0x0 rect.

verification: |
  guardrail_verdict: accepted

  1. Root cause observed directly, not inferred: two different elements read back the identical
     computed `backgroundColor` `rgb(243, 236, 250)`, and a pixel scan of the real screenshot
     showed byte-identical fills either side of the 1px divider. A rival reading was killed in the
     same pass — the "one continuous rounded card with a drop shadow" from the user's screenshot
     does not exist in the DOM: every ancestor of both bands is transparent, `border-radius: 0px`,
     `box-shadow: none` (that was device/browser chrome).

  2. Symptom eliminated, with the closing arithmetic. Re-scanned after the fix at the same pixel
     column: the boundary that was 1.0:1 (same fill) + a 1.226:1 hairline is now a 1.415:1 fill
     step sustained over the band's full 45px in light, and a two-step 1.130 -> 1.227:1 in dark.
     Measured in the same units the defect was measured in.

  3. Breakpoint x theme sweep, unscrolled and scrolled — `docOverflow: 0` throughout:
       390 light/dark  wrap block, base-100 band, both fades tracking, --pk-header-h 109px
       480 light/dark  same
       481 light/dark  wrap display:none, --pk-header-h back to 64px (desktop untouched)
      1280 light       wrap 0x0 rect, trigger flex, mega-menu opens, 8 items, panel right-anchored
                       at 1248 matching the header gutter
     Scrolled (scrollY 700, `.is-scrolled` active): band still sticky at top=64/bottom=109 and
     still opaque — content occluded, not bled through.

  4. Regression test verified RED on the real defect, not written green: with
     `git stash push -- assets/css/app.css` restoring the pre-fix stylesheet, the surface-token
     assertion fails with its intended diagnostic ("`.pk-nav` and `.pk-chip-nav-wrap` both paint
     `var(--color-base-200)`..."). Green again after `git stash pop`. The other two assertions are
     documented invariants that were green before and after by construction — they guard the fix
     being undone from the other side (moving the band's fill without its fades, or "separating"
     the bands with transparency).

  5. Shipped functionality intact — every capability 260824-jkc added was exercised, not assumed:
     8 chips render; the wrap keeps `position: relative` with both fade pseudo-elements at
     z-index 4; the chip nav still scrolls horizontally (scrollWidth > clientWidth, scrollLeft
     honoured); scroll-spy still fires with exactly ONE `.is-active` chip carrying the sketch 020
     Round 2 treatment (accent tint #EDE1F7, primary #3D096D border and text); the drawer still
     opens; the desktop mega-menu still opens with all 8 rows.

  6. Cycle 1 not regressed: `.pk-search-morph`'s trailing gap to `.pk-nav-inner`'s content edge is
     0px at 390/480/481 in both themes. The search right-alignment fix is untouched and intact.

  7. Project gates: `mix quality` green end to end — hex.audit, deps.audit,
     deps.unlock --check-unused, format --check-formatted (Styler active, no rewrites),
     credo --strict (69 files, 0 issues), sobelow --config (only the pre-existing low-confidence
     directory-traversal findings in the seed importer, untouched), and
     `test --warnings-as-errors` at 433 tests / 0 failures (430 before, +3 new).

  8. Survives the asset pipeline: after `mix assets.build`, `priv/static/assets/css/app.css`
     carries `background: var(--color-base-100)` on `.pk-chip-nav-wrap` and both gradients as
     `var(--color-base-100)` — LightningCSS did not inline, downlevel or drop the token
     references.

  Not verified: real physical devices, non-Chromium engines. Closed by construction rather than
  measurement: Detalle, Quiénes Somos and the filtered catalog never render `<:subnav>` at all
  (index.ex:498 gates it on `not filters_active?`), so no `.pk-chip-nav-wrap` exists there.

  Known and deliberately NOT fixed (pre-existing, outside this report): in the scrolled state
  `.pk-nav.is-scrolled`'s base-300 `border-bottom` and the wrap's base-300 `border-top` stack into
  a 2px line at y=63..64. It is sub-perceptual, predates this fix, and reads as the intended
  scroll emphasis.

files_changed:
  - assets/css/app.css (.pk-chip-nav-wrap background + its ::before/::after fade gradients:
    base-200 -> base-100, with the measured rationale recorded in the rule's comment)
  - test/pukllay_club_web/header_chip_band_separation_test.exs (new — 3 assertions, 1 RED-verified)

## Resolution — CYCLE 1 (search pill right-alignment) — CLOSED, verified

root_cause: |
  `assets/css/app.css:963` declared `.pk-cat-trigger ~ .pk-search-morph { margin-left: 0 }` at the
  top level, with no media query. The rule was written for desktop, where `.pk-cat-trigger` and
  `.pk-search-morph` both carried `margin-left: auto` and flexbox split the free space between
  them instead of grouping them (Task 3's measured 303px gap at 1280px). Neutralising the pill's
  auto margin is correct THERE — but the `~` combinator matches on DOM tree structure, whereas the
  behaviour the rule depends on (the trigger absorbing the row's free space) requires the trigger
  to generate a BOX. `display: none` separates those two things: at `@media (max-width: 480px)`
  the trigger is `display: none` (app.css:2349) yet remains in the DOM, so the selector still
  matched, still stripped `.pk-search-morph`'s base `margin-left: auto` (app.css:652), and nothing
  replaced the right-push. Measured at 390px: the closed 44px pill landed at x=110 — 8px after the
  brand, i.e. the row's own gap — leaving 222px of dead space before `.pk-nav-inner`'s content
  right edge at 376. That is both reported symptoms at once: the right alignment is gone, and the
  pill is crowded onto the header's left cluster beside the brand.
  Single defect, though the failure is an AND of two conditions: the second — the trigger being
  hidden below 481px — is intended design (mobile uses the chip index row) and was deliberately
  preserved.

fix: |
  Scoped the override to the exact complement of the band that hides the trigger, so the rule can
  only apply where its precondition (the trigger generates a box) actually holds. app.css:979 now
  reads `@media not all and (max-width: 480px) { .pk-cat-trigger ~ .pk-search-morph
  { margin-left: 0 } }`.

  Chose `not all and (max-width: 480px)` over the more obvious `min-width: 481px` deliberately:
  the latter leaves a sub-pixel band (e.g. 480.5px) matching NEITHER rule, where the trigger is
  already visible but the override has not yet engaged — both elements would carry
  `margin-left: auto` there, reinstating Task 3's original 303px-gap bug in a hairline band. The
  negated form is the exact complement, and pinning the same 480px literal in both places makes
  the coupling greppable.

  Rejected alternatives: (a) restoring `margin-left: auto` inside the ≤480px block — works, but
  makes three rules own one property and leaves the misleading unconditional override in place;
  (b) revealing `.pk-cat-trigger` on mobile — would mask the symptom while destroying the intended
  chip-row design (see the AND-gate note in root_cause); (c) replacing both auto margins with a
  flex spacer element — genuinely the most robust and immune to this whole class, but it is a
  markup change to the shared shell touching every page right after a run of header regressions,
  so it is recorded as a durable follow-up rather than done under a bugfix.

  The fix is CSS-only, one rule, no markup and no JS. It changes behaviour only on
  CatalogLive.Index with filters inactive at ≤480px — the reported case.

verification: |
  guardrail_verdict: accepted

  1. Root-cause mechanism observed directly, not inferred (headless Chrome + CDP against the dev
     server): at 390px `.pk-cat-trigger` had `display: none` and a 0x0 rect (no box) while
     `morph.matches('.pk-cat-trigger ~ .pk-search-morph')` returned `true` and the pill's
     `margin-left` computed to `0px`. Selector matched, box absent — the exact mechanism.

  2. Symptom eliminated, with closing arithmetic. Re-measured after the fix, the pill's computed
     `margin-left` at 390px is `222px` — EXACTLY the dead space measured before the fix. The
     recovered value and the lost value are the same number, which closes the loop on the
     mechanism rather than merely showing a better-looking result.

  3. Boundary/differential sweep, closed AND open, all right-aligned (gap-to-content-edge = 0,
     document overflow = 0 at every width):
       390px  closed margin-left 222px, pill 332-376, content edge 376  (was: pill 110-154, gap 222)
       480px  closed margin-left 312px, pill 422-466, content edge 466  (was: pill 110-154, gap 312)
       481px  closed margin-left 0px,   pill 390-434, content edge 434  (unchanged, override applies)
       600px  closed margin-left 0px,   pill 509-553, content edge 553  (481-799px band, label hidden)
       1280px closed margin-left 0px,   pill 1189-1233, content edge 1233 (desktop grouping intact)
     Desktop open state also unchanged at 1280px (pill 953-1233). Task 3's grouping fix is
     preserved in full.

  4. Regression test verified RED on the real defect, not written green:
     `git stash push -- assets/css/app.css` (restoring the pre-fix stylesheet) makes 2 of the 5
     assertions fail with their intended diagnostics; the other 3 are documented invariants that
     guard against the fix being undone from the other side. Green again after `git stash pop`.

  5. Visual confirmation: 390px screenshot shows hamburger at the left edge, brand beside it, and
     the search icon flush at the row's right edge.

  6. Project gates: `mix quality` green end to end — hex.audit, deps.audit,
     deps.unlock --check-unused, format --check-formatted (Styler active, produced no rewrites),
     credo --strict, sobelow --config (only pre-existing low-confidence findings in
     lib/pukllay_club/catalog/seed/report.ex, untouched by this change), and
     `test --warnings-as-errors` at 430 tests / 0 failures. The pre-existing sibling guard
     `header_search_gutter_test.exs` remains green (it was green through the regression too, which
     is why a new guard was required).

  7. Rule survives the asset pipeline: `@media not all and (max-width: 480px)` appears exactly
     once in `priv/static/assets/css/app.css` after `mix assets.build` — LightningCSS did not
     downlevel, merge or drop it.

  Blind spots closed by construction rather than measurement: `<:nav_menu>` is rendered only by
  CatalogLive.Index and only when filters are inactive (live/catalog_live/index.ex:495), so
  Detalle, AboutLive and the filtered catalog never emit `.pk-cat-trigger` at all — the `~`
  selector cannot match there, and the base `margin-left: auto` governs them at every width both
  before and after this change. Not verified: real physical devices, non-Chromium engines, and
  dark theme (the change is a margin scope with no colour or theme dependency).

files_changed:
  - assets/css/app.css (the override at :963 is now wrapped in a complementary media query at :979)
  - test/pukllay_club_web/header_search_right_align_test.exs (new — 5 assertions, 2 RED-verified)
