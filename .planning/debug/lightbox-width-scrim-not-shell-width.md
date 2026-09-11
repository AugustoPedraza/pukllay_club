---
status: diagnosed
trigger: "Investigate issue: lightbox-width-scrim-not-shell-width. Plan 01.2-25 was supposed to make the game-detail lightbox photo derive its max-width from the site's own shell/container width token, and both chevrons were supposed to get an explicit z-index. Code-confirmed present by TWO independent verifier passes (source reads only, no live render). Live UAT round shows the fix did NOT visibly take effect."
created: 2026-08-28T00:00:00.000Z
updated: 2026-08-28T00:10:00.000Z
---

## Current Focus

hypothesis: CONFIRMED — `.pk-lightbox-img` only declares `max-width`/`max-height` (upper bounds), never
  an actual `width`. A plain `<img>` with no explicit width renders at its INTRINSIC pixel size by
  default; max-width/max-height can only shrink an oversized image, never grow one to fill available
  space. Every catalog image is seed-pipeline-generated at a fixed 800px width (`ImagePipeline.@large_width`)
  and is near-perfectly square (5/5 sampled games: 800x799 or 800x800). 800px was already narrower than
  BOTH the OLD max-width cap (~960px) and the NEW 01.2-25 cap (~1216px at 1920px viewport) — so raising
  the cap changed nothing observable for any real image in this catalog. The fix is real, correctly
  written, correctly compiled, correctly served — it just targets a constraint that was never binding.
test: verified via direct DB query (game 179's cover_url/gallery_urls), WebP header parsing (5/5 games
  sampled: all ~800x800), compiled-CSS byte comparison against source, running-process cwd inspection,
  and source-comment cross-reference (01.2-21 chevron decision).
expecting: N/A — diagnosis complete, goal is find_root_cause_only.
next_action: Return ROOT CAUSE FOUND to caller.

## Symptoms

expected: At 1440px+ desktop widths, the lightbox photo's left/right edges line up with the header's and footer's content edges (same shell max-width, e.g. driven by a --container-7xl-style CSS custom property or equivalent literal), with the surrounding scrim reading as sufficiently obscuring the page behind it. On mobile the scrim reads as clean, not "noisy."
actual: User-provided screenshot (desktop, ~1920px browser window, /juegos/179 "7 Wonders Duel"): the lightbox photo renders as a small, roughly-centered box far short of the shell/header/footer content width; both chevron buttons sit near the browser viewport's own left/right edges (not the shell's content edges); the page's masthead, description, and "FICHA TÉCNICA" section remain clearly legible through/around the lightbox, meaning the scrim is not obscuring the page. User also asked why the box cover image itself reads as "elevated"/"weird 3d" — may just be the source product photo's own angled box-cover rendering rather than a CSS artifact, flag and confirm either way. Mobile screenshot (~390px, /juegos/... detail page): lightbox photo similarly narrower than the poster column context, with the user describing the surrounding scrim/background as adding visual "noise."
errors: None reported in console by the user; not yet checked by this investigation.
reproduction: Open a game detail page (e.g. /juegos/179), click the poster image or a thumbnail to open the lightbox, observe at both ~390px (mobile) and ~1920px (desktop) viewport widths.
started: Regression/non-fix relative to plan 01.2-25 (executed earlier this session), which claimed to fix exactly this. This UAT round is the FIRST live-render check of that specific claim.

## Eliminated

- hypothesis: Stale compiled CSS asset (dev server serving pre-01.2-25 bundle)
  evidence: Running `mix phx.server` process (pid confirmed via /proc/<pid>/cwd) runs from the main
    checkout `/home/apedraza/projects/pukllay_club`, not this debug worktree. Its
    `priv/static/assets/css/app.css` mtime (Aug 27 22:10) is AFTER its source `assets/css/app.css`
    mtime (Aug 27 20:50), and the compiled `.pk-lightbox-img`/`.pk-lightbox-chevron` rules are
    byte-identical to source (same max-width calc formula, same z-index:2). No duplicate/stale
    `.pk-lightbox-img` rule found anywhere else in the 5000+-line compiled file.
  timestamp: 2026-08-28

- hypothesis: `--container-7xl` not emitted in build, or overridden by a later/more-specific rule
  evidence: `--container-7xl: 80rem` is declared exactly once, inside Tailwind's own
    `@layer theme { :root, :host { ... } }` block (line 12 of compiled CSS) — no other declaration
    anywhere in the file. `--pk-gutter` similarly has exactly two declarations (2rem desktop, 0.875rem
    inside one mobile media query) — both expected, no unexpected override. `.pk-lightbox-img` is
    outside any `@layer` (explicit repo convention: hand-written `.pk-*` rules are deliberately
    unlayered so they always outrank Tailwind's layered utilities regardless of specificity), and the
    `<img>` carries only the single class `pk-lightbox-img` with no competing Tailwind width utility
    in the markup.
  timestamp: 2026-08-28

- hypothesis: Dev server the user tested against is running from a different git checkout/branch that
    lacks 01.2-25's commits
  evidence: Confirmed via `/proc/<pid>/cwd` that the sole running `mix phx.server` beam.smp process's
    cwd is the main checkout, and that checkout's source `assets/css/app.css` already contains the
    01.2-25 fix (same line numbers/content as this debug worktree, consistent with this worktree having
    branched from a HEAD that already includes those commits). Server-side code is current.
  timestamp: 2026-08-28

- hypothesis: Chevrons anchored to viewport edges instead of shell edges is an unfixed regression
  evidence: `lib/pukllay_club_web/live/catalog_live/show.ex` lines 755-767 carry an explicit in-source
    comment: "Arrow-anchoring decision (G-01.2-21, sketch 033's open question): kept viewport-edge
    anchoring (left-4/right-4) at every width rather than switching to image-relative anchoring at
    desktop... Tradeoff, recorded honestly rather than hidden: at wide desktop windows with the image
    capped narrower than the viewport, the chevrons can sit across a lot of empty scrim from the photo
    — if the human check below reads that as accidental rather than deliberate, that is a follow-up gap
    with a designed answer, not a silent change made here." 01.2-25's own plan text explicitly
    prohibits re-anchoring: "Do NOT re-anchor the chevrons to the image... this plan makes the left one
    visible, it does not re-open where they sit." This is a known, previously-recorded, deliberate
    tradeoff whose human verdict was still outstanding — not a fresh code defect.
  timestamp: 2026-08-28

## Evidence

- timestamp: 2026-08-28
  checked: assets/css/app.css source (this worktree) around `.pk-lightbox-img`/`.pk-lightbox-chevron`
  found: Rule present exactly as SUMMARY claims — `max-width: calc(min(100vw, var(--container-7xl,
    80rem)) - (2 * var(--pk-gutter)));`, `max-height: 80vh; object-fit: contain;` unchanged; both
    chevrons carry `.pk-lightbox-chevron { z-index: 2; }`. No `width` property declared anywhere on
    `.pk-lightbox-img`.
  implication: Confirms the two prior source-only verifier passes were correct about what the CODE
    says. The discrepancy must be in how this code actually renders given real content, not in the
    code being missing/wrong/stale.

- timestamp: 2026-08-28
  checked: Running `mix phx.server` process (main checkout) compiled CSS + token values
  found: `priv/static/assets/css/app.css` matches source byte-for-byte for the relevant rules;
    `--container-7xl: 80rem` and `--pk-gutter: 2rem`/`0.875rem` resolve correctly with no cascade
    override.
  implication: Server-side is not the problem — the running dev server IS serving the fixed CSS
    correctly.

- timestamp: 2026-08-28
  checked: `games` table for game id 179 (7 Wonders Duel) via direct psql query
  found: cover_url and all 3 gallery_urls point to R2-hosted `*-large.webp` files.
  implication: Needed the actual served image URLs to test the real rendering math, not assumed
    dimensions.

- timestamp: 2026-08-28
  checked: Downloaded and parsed WebP headers (VP8X chunk) for game 179's cover + gallery-1, plus 4
    more random games' cover images (Marvel Champions, Wingspan, Obsesion, plus one more)
  found: ALL 5 sampled images are ~800x800 (800x799 or 800x800 exactly) — i.e., near-perfectly SQUARE.
  implication: This is systemic across the catalog, not a one-off for this game. Confirmed via
    `lib/pukllay_club/catalog/seed/image_pipeline.ex`: `@large_width 800` resizes every gallery/cover
    image to a fixed 800px width, preserving whatever aspect ratio BGG's own source image has — and
    BGG's source box-cover images are apparently consistently near-square.

- timestamp: 2026-08-28
  checked: CSS mechanics of a plain `<img>` with only `max-width`/`max-height` set (no `width`, no
    explicit box for `object-fit` to act within)
  found: Browsers render an unconstrained `<img>` at its INTRINSIC pixel size by default (`width: auto;
    height: auto`); `max-width`/`max-height` are upper bounds that can only shrink an oversized image,
    never grow one to fill more space. `object-fit: contain` has no visual effect here because no
    explicit `width`/`height` establishes a replaced-element box distinct from the image's own natural
    (already-capped) size.
  implication: An 800px-wide source image can NEVER render wider than 800 CSS pixels in this markup
    regardless of what value `max-width` evaluates to — the max-width formula was never the binding
    constraint. Both the OLD `min(90vw, 60rem)` (960px cap at typical desktop) and the NEW
    shell-derived cap (~1216px at 1920px viewport) sit ABOVE the image's 800px intrinsic ceiling, so
    changing the formula produces zero visible difference for any real catalog image.
  implication: This is the root cause. It fully explains why two independent source-only verifier
    passes correctly confirmed the code change (it IS present, correct, and compiled) while live UAT
    correctly observed no visible effect (the change doesn't matter for THIS catalog's actual assets).

- timestamp: 2026-08-28
  checked: `lib/pukllay_club_web/live/catalog_live/show.ex` `@lightbox_image`/`@selected_image`
    initialization
  found: `@selected_image` defaults to `game.cover_url` (the `*-large.webp`, 800px variant — not the
    300px `*-thumb.webp` variant); `@lightbox_image` is seeded from `@selected_image` on open.
  implication: Rules out "wrong (smaller) image variant accidentally used" as an alternative
    explanation — the lightbox correctly loads the largest available asset; that asset is simply only
    800px wide by design of the seed pipeline.

- timestamp: 2026-08-28
  checked: `--pk-overlay-scrim` token value and `.pk-lightbox` container's own background/inset
  found: `--pk-overlay-scrim: color-mix(in srgb, var(--pk-shadow-color) 72%, transparent)`;
    `.pk-lightbox { position: fixed; inset: 0; background: var(--pk-overlay-scrim); }` — the scrim
    technically covers 100% of the viewport at 72% opacity regardless of photo size. The G-01.2-16
    debug session (referenced by 01.2-25) already pixel-sampled this across 5 viewports and found no
    stacking/positioning/compositing fault.
  implication: The "not obscuring enough" complaint is a real, already-diagnosed-elsewhere perceptual
    consequence of a small photo leaving a large field where scrim-over-page dominates the visual
    impression — not a broken scrim. Since the photo's rendered size never actually changed (same root
    cause as above), this downstream symptom persists unchanged post-"fix," exactly as observed.

## Resolution

root_cause: "`.pk-lightbox-img` declares only `max-width`/`max-height` (upper bounds) and never an
  actual `width`, so a plain `<img>` renders at its own INTRINSIC pixel size, which max-width can only
  shrink, never grow. Every catalog image is generated by the seed pipeline at a fixed 800px width and
  is near-perfectly square (confirmed 5/5 sampled games), which is narrower than BOTH the pre-01.2-25
  and post-01.2-25 max-width caps at any normal desktop viewport width — so 01.2-25's max-width fix is
  syntactically correct, compiled, and served correctly, but has zero visible effect on real catalog
  content because it changes a constraint that was never the binding one. The chevron-position and
  scrim-transparency complaints are downstream/independent: chevron viewport-edge anchoring is a
  previously-recorded deliberate tradeoff from plan 01.2-21 (explicitly not reopened by 01.2-25, with
  this exact outcome pre-anticipated in a source comment), not a bug; the scrim-not-obscuring complaint
  is the already-diagnosed-in-G-01.2-16 perceptual consequence of a small photo against a large
  translucent field, which persists because the photo's actual rendered size never changed."
fix: (not applied — goal is find_root_cause_only; diagnosis returned to caller for fix planning)
verification: (n/a — no fix applied in this session)
files_changed: []
