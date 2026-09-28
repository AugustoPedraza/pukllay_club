# test/visual/

Zero-dependency Node + CDP (Chrome DevTools Protocol) probes that measure
the REAL, rendered app in a REAL headless browser — geometry (rects),
resolved computed styles, and (for the admin scripts) real interactions
driven through real UI paths. None of them read source text or assert
node existence as their pass/fail signal; every one reads a rect, a
resolved colour, or a real DOM/browser event outcome.

## Developer-invoked only — never `mix quality`, never CI

These scripts are **not** wired into `mix quality` and **must never** be
added to CI (`.github/workflows/`). Two independent reasons, both already
on record for the About-page scripts this directory started with
(01.4-10):

1. **They need a real browser.** CI's `ubuntu-latest` runner doesn't ship
   Chrome by default, and even where a browser exists, this repo has a
   real precedent for rendering divergence between headless Chromium and
   other engines (Phase 01.3's chevron bug reproduced only on real WebKit,
   never in headless Chromium) — a green run here is a strong signal, not
   a proof of correctness everywhere.
2. **They need a booted dev server**, and the admin scripts additionally
   need a real staff session (a real magic-link login flow) and, for the
   interactive checks, make real writes to the dev database (inviting and
   then removing a throwaway staff account) — none of which belongs in an
   automated, unattended CI run. `admin_shell.mjs`'s overlay-coverage walk
   (plan 01.8.3-07) additionally OPENS a real shelf-deletion confirmation
   dialog (`#confirm-delete-shelf-dialog`) to measure it — it never clicks
   that dialog's own confirm control, so it makes no destructive write, but
   an unattended CI run is still the wrong place for a script one line away
   from a real delete.

Run them by hand, against a running `mix phx.server`:

```bash
PROBE_BASE_URL=http://localhost:4000 node test/visual/admin_components.mjs
PROBE_BASE_URL=http://localhost:4000 node test/visual/admin_shell.mjs
```

Omit `PROBE_BASE_URL` and a script will boot (and later tear down) its own
`mix phx.server` for the duration of the run.

## Scripts

| Script | What it measures | Scope |
|---|---|---|
| `about_geometry.mjs` | The public About page's vertical rhythm (band adjacency, `#cierre`'s gaps, the Sumate CTA) | Public site (01.5-06/07/08/13) |
| `about_map_attribution.mjs` | The About page's live Google Maps embed (CSP, geometry, dark-mode filter) | Public site (01.4-12) |
| `admin_components.mjs` | The admin's measurable design-system rules (A1-A9 action anatomies, D1-D3 page-head rhythm, K1's 16px-field-on-touch rule, the 44px hit-box floor), plus D-19o's real press state and the `admin_sheet.js` interaction hook (Esc, scrim tap, drag-down, focus trap, focus return) driven against the real Staff screen | Admin (01.8.2-12) |
| `admin_shell.mjs` | The admin shell chrome every screen sits inside: the fixed foot save bar (D-28), the pinned page bar's zero-layout-cost-at-rest guarantee (D-19n), the tab bar (D-13b), the shell's content keel (open item 4), (plan 01.8.3-05) the Juegos-specific list/caption pixel geometry — the 16px content keel, both section pinned-band heights and their flush adjacency to the pinned search row, a list row's 64px floor, the caption's ink-to-ink air ratio (D-13/D-15/D-16), (plan 01.8.3-06) the pinned caption ink's own position INSIDE that band — per-section symmetry and cross-section `--pt` independence, and (plan 01.8.3-07, G-01.8.3-2b) the overlay-coverage walk — a synthetic `.pk-admin-overlay-root` clone injected as a non-last child of every admin page's own spacing container, plus a table-driven real-open walk over six `sheet/1`/`dialog/1` call sites (including a shelf-deletion confirmation dialog) that hit-tests each open overlay's own bounds via `elementFromPoint` | Admin (01.8.2-12, 01.8.3-05, 01.8.3-06, 01.8.3-07) |

## Structure convention

Each script exports a `CHECKS` (or equivalent named check-function) list a
later plan extends by appending — never by restructuring the sweep loop,
the dev-server/Chrome lifecycle, or the CDP client underneath it. See each
script's own header comment for its specific extension points (e.g.
`admin_components.mjs`'s `PAGES` array, appended one route per screen
plan, matching `admin_composition_test.exs`'s own `@files`-per-plan
pattern).

## Guard-writing rules (apply to every check in every script here)

Earned the hard way across the `.planning/sketches/` 059-080 lineage
(`01.8.2-CONTEXT.md`'s `canonical_refs`) and across this directory's own
prior incidents (`about_geometry.mjs`'s own header comment records the
16px whitespace strip that shipped for two weeks past every CLASS/COLOUR
check while a rect-level check would have caught it day one):

1. Assert geometry **before** reading a pixel diff.
2. Read **rect + resolved colour**, never node existence — a defect that
   is visual is invisible to a check that only confirms a node exists.
3. Use `offsetParent`, never `.hidden` — a class setting `display`
   out-specifies a bare `[hidden]` attribute selector.
4. Every class that sets `display` carries its own `[hidden]` companion.
5. Normalise whitespace before matching rendered text.
6. Measure the fold against the **pinned overlay's top**, not the
   scroller's rect.
7. Measure **ink, not boxes**, when the element draws nothing (a
   transparent element's box edge is invisible, so a box-only check
   reports padding changes as no change at all).
8. **Negative-test every new guard against today's unfixed source (rule 8),
   and record the failing transcript.** A guard that has never been observed
   to fail proves nothing about what it claims to measure. Earned from
   four independent diagnoses converging on ONE pattern on 2026-09-27
   (`.planning/debug/DEBUG-juegos-horizontal-keel-three-axes.md` and
   sibling sessions): a guard can pass TRUTHFULLY while asserting a
   quantity that is not true of the rendered page. Four confirmed
   mechanisms, each one a guard that passed while the developer's eye read
   a different quantity:
   - **Manufactured state** — driving the page into a state a real user
     never occupies (a synthetic scroll `Event`, a direct class/attribute
     poke) specifically to make a measurement, rather than reaching that
     state through a real interaction.
   - **Netted-out coordinates** — reporting a container-relative number as
     if it were an on-screen (viewport-relative) one; subtracting an
     ancestor's own padding back out of a reading can make a guard assert
     a quantity that exists nowhere on the painted page.
   - **Collected but never asserted** — a field is measured and printed on
     every run, but no assertion ever reads it, so a regression in exactly
     that field prints, unremarked, in the log of every "passing" run.
   - **Right axis, wrong property** — delivering exactly the guard a gap's
     own `missing:` list asked for, faithfully, when the real defect is a
     different, independent property of the same element (e.g. an
     overlay's viewport COVERAGE vs. its scroll LOCK — two independent
     questions about the same box).
   Consequence: every new guard in this directory must be demonstrated to
   FAIL against the current, unfixed source before its fix lands, and that
   demonstration recorded — a plan that only shows a guard passing has not
   closed its gap, it has only added an assertion.

`admin_components.mjs` additionally confirmed, empirically, that
**`offsetParent` is unconditionally `null` for any `position: fixed`
element in Chrome, regardless of visibility** — so a rule 3-compliant
check on a `position: fixed` overlay (this app's `sheet/1`/`dialog/1`)
needs the RESOLVED `display` value instead (still rule 2: resolved style,
not node existence), not `offsetParent`. See that script's own
`isOverlayOpen` comment for the full reasoning — including that this
SAME flaw is present in `assets/js/hooks/admin_sheet.js`'s own
`isOpen = () => this.el.offsetParent !== null`, which is why Esc,
drag-down-close, and focus-trap/focus-return are confirmed non-functional
in the shipped admin as of this writing (01.8.2-12-SUMMARY.md).

9. **A scroll assertion in this directory drives `Input.dispatchTouchEvent`
   (a real touchStart/touchMove/touchEnd sequence) or `Input.dispatchMouseEvent`
   with `type: "mouseWheel"` — NEVER CDP's gesture-synthesis input command
   (`Input.synthesizeScrollGesture`).** That command is INERT in this
   headless build: calibrated on a real page scrollable by 1506px, a
   `gestureSourceType: "touch"` synthesize call moved the document 0px,
   while `dispatchTouchEvent` moved it 281px and a `mouseWheel` moved it
   300px on the SAME page. Its `yDistance` argument is also
   positive-to-scroll-UP (the opposite of a natural downward scroll), so a
   positive distance applied at `scrollTop: 0` is a no-op regardless of
   whether the underlying mechanism works at all — plan 01.8.3-13's own
   diagnosis (`.planning/debug/DEBUG-admin-sheet-modal-contract.md`)
   produced a false "locked" reading from exactly that pair of mistakes in
   its first round. Consequence: **every scroll assertion must carry its
   own sheet/dialog-CLOSED positive control in the SAME run**, and that
   control must itself FAIL the harness (not merely log a warning) when it
   does not move the page by a clearly-nonzero margin — a guard that cannot
   move an unlocked page has not measured a lock, it has measured nothing.
