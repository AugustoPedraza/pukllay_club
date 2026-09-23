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
   automated, unattended CI run.

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
| `admin_shell.mjs` | The admin shell chrome every screen sits inside: the fixed foot save bar (D-28), the pinned page bar's zero-layout-cost-at-rest guarantee (D-19n), the tab bar (D-13b), and the shell's content keel (open item 4) | Admin (01.8.2-12) |

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
