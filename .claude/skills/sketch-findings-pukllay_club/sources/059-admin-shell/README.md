---
sketch: 059
name: admin-shell
question: "How does a signed-in staff member navigate admin on a phone, know they're authenticated, and sign out?"
winner: "C2 (final, single design)"
tags: [admin, shell, drawer, session, logout, navigation, phase-01.8.1, mobile-first]
---

# Sketch 059: Admin Shell

## Design Question
Phase 01.8.1 UAT rejected the admin UI (G-01.8.1-admin-ux). Shell-level gaps: footer broken on admin
(1a — decided: **no footer on admin**), drawer not opening (1b — implementation bug, not design),
no signed-in affordance and a meaningless bare "Salir" text (1d). This sketch settles the shared
frame every admin screen sits in: header, drawer contents, account/session signal, the
Cerrar sesión action, page title + back navigation — plus how a signed-in staff member looks on
the public site.

Direction (intake): same brand, quieter tool. References: iOS Settings grouped lists,
Shopify/Square mobile admin, Linear/Notion mobile. Core action: curating dynamic sections, then
adding games by BGG ID.

## How to View
Serve the repo root (fonts/logo load via relative paths), e.g.
`python3 -m http.server 8765` then open
http://127.0.0.1:8765/.planning/sketches/059-admin-shell/index.html

Top bar: switch variant and state (Admin / public site while signed in / signed out). Bottom-right
tools: theme, phone/desktop, owner vs staff role (Staff entry is owner-only).

## Variants
- **A: Drawer carries the account** — public header unchanged; green dot on the hamburger when
  signed in; drawer = account card → Panel group (with counts) → Sitio group → Cerrar sesión row →
  theme. "‹ Panel" back row on phone, breadcrumb on desktop. Least-resistance path (extends
  shipped `nav_drawer/1`).
- **B: Avatar + account sheet** — "PANEL" mode label next to the mark; avatar with a green ring at
  the top-right on every page (public too); avatar → bottom sheet (desktop: dropdown) with account,
  Ver sitio público / Ir al panel, Cerrar sesión. Drawer is navigation only.
- **C: Bottom tab bar** — admin gets its own dock (Inicio · Juegos · Secciones · Estantes · Más);
  Más/avatar sheet holds Revisar niveles, Staff, account, Cerrar sesión. Public pages keep the
  normal shell with A-style drawer account block.

All variants: no footer on admin; logout is always an explicit "Cerrar sesión" with icon,
followed by a confirm sheet and then a "Cerraste sesión" toast on the Ingresar page (confirm vs
instant is revisited in 063).

## What to Look For
- Can you tell at a glance you're signed in — on admin AND on the public catalog?
- How many taps from any admin screen to another section (A/B: 2 via drawer, C: 1)?
- Does the drawer (A) get too long once account + 6 admin rows + site links + logout stack?
- Does C's dock feel like a second app, and is 72px of bottom chrome OK on a small phone?
- Back row vs breadcrumb on sub-pages (Secciones → Destacados).

## Bugs found while building
- Opening states driven by `requestAnimationFrame` never fired in a backgrounded/automated tab
  (same throttling class as the IntersectionObserver finding in `detail-page-mobile-interaction.md`)
  — switched to a forced reflow (`void el.offsetWidth`) before adding `.open`. Relevant to 1b's
  real drawer bug diagnosis: check the shipped hook for rAF/visibility-dependent wiring.

## Winner: C — Bottom tab bar (polished after selection)
Developer picked C with the requirement that it "works correctly and looks and behaves seamless".
Polish pass, browser-verified (phone + desktop, light + dark, owner + staff role, zero JS errors):

- **Tabs:** Panel · Juegos · Secciones · Estantes · Más. First tab renamed "Inicio" → **"Panel"** —
  "Inicio" is the public home's nav label (see `page-shell.md`), so reusing it in admin was ambiguous.
- **Desktop:** every section inline in a row under the header (no Más); row scrolls horizontally
  instead of overflowing the page if space runs out.
- **Header + tab bar persist; only content swaps** (100ms fade, scroll reset). Maps to a single admin
  `live_session` layout with `navigate` between LiveViews.
- **Re-tap active tab** → pop to that tab's root (Destacados → Secciones), or smooth-scroll to top.
- **Two sheets, one job each:** avatar (green ring = signed in) → account sheet (account card,
  Ver el sitio público, Cerrar sesión, theme). Más → overflow sections only (Revisar niveles, Staff),
  with a dot on Más when an overflow section needs attention. Staff role: Más holds only Revisar niveles.
- **Sheets:** backdrop tap, Esc, swipe-down to dismiss (a drag that starts on a row doesn't also
  trigger the row); focus moves into the sheet and returns to the opener.
- **Choosing from Más** swaps content under the closing sheet — no wait for the close animation.
- **Tab bar** respects `env(safe-area-inset-bottom)`; active tab = tinted pill + bold label.
- **Public pages with session** keep the public shell; drawer gains account card + Ir al panel +
  Cerrar sesión (and the green dot on the hamburger).
- **Logout:** Cerrar sesión → confirm sheet → Ingresar page with "Cerraste sesión" toast.

### Bugs found and fixed during polish
- Dark theme: active tab pill (`--color-accent-bg`) was near-invisible on the dark ground → dark uses
  `color-mix(accent-text 22%)` + bold label.
- Nav handler called `closeAll()` before checking whether a sheet was open, so the close-then-render
  delay never applied (moot now for C, which swaps under the closing sheet).

### Implementation notes (for the gap-closure plan)
- On mobile, hide the tab bar while an input has focus (on-screen keyboard) — not mockable here.
- The tab bar needs real bottom padding on `<main>` (~72px + safe area) so the last row isn't covered.
- Drawer bug (G-01.8.1-1b) is not answered by this sketch; diagnose it separately. Check the shipped
  hook for rAF/visibility-dependent wiring (see "Bugs found while building").

## Synthesis round: C2 — C + top drawer, account in the tab bar (2026-09-14)
Requested after C won: "keep the drawer menu on the top and move the profile icon to the more
bottom option". Added as tab **C2** (variant key `D`); C is kept for comparison.

- Header: public-style hamburger (same as the public shell) + mark + PANEL label; no header avatar.
- Drawer: navigation only — every admin section with counts + Sitio links (no account/logout).
- Tab bar: Panel · Juegos · Secciones · Estantes · **Cuenta** (avatar with green signed-in ring) →
  account sheet (Ver el sitio público, Cerrar sesión, theme).
- Revisar niveles / Staff live only in the drawer; a purple dot on the hamburger flags pending work
  there (green stays reserved for "signed in").
- On Niveles/Staff no tab is highlighted; the drawer row carries the active state.
- Desktop identical to C (all sections inline, avatar top-right, no hamburger).
- Tradeoff: main sections duplicated in tabs + drawer; overflow sections move from a bottom (thumb)
  target to a top one. Drawer slides from the right while the hamburger sits left — matches the
  shipped public drawer, kept for consistency.

Browser-verified: tab/drawer active-state sync through content-only swaps, account tab → logout →
Ingresar, no horizontal overflow on any screen, desktop, zero JS errors. **Developer picked C2 over C** — C2 is the winner.

## Polish round: Cerrar sesión confirm (2026-09-14) — SUPERSEDED by the consistency round below
Developer flagged the logout bottom sheet as needing polish. Problems found in the original:
solid red CTA-style button (contradicts the "no CTA look in admin" direction from G-01.8.1-2b),
Bebas all-caps "¿CERRAR SESIÓN?" shouting, left-aligned copy with an orphan wrap, no indication of
WHICH account signs out, a jarring double animation (account sheet slides down while a second
sheet slides up), and no acknowledgement after tapping.

Polished pattern (shared by every entry point):
- **One sheet, two steps (C/C2):** the account sheet turns into the confirm step in place — content
  slides/fades horizontally and the sheet height animates; no second sheet. Entry points from a drawer
  (A, public pages) open the same confirm content as a standalone sheet (desktop: centered dialog).
- **Content:** centered; soft danger-tinted logout icon; "¿Cerrar sesión?" in Inter 700 (not display
  type); the account email on its own line; one balanced line "Para volver a entrar, te mandamos un
  link por mail."
- **Buttons:** "Cerrar sesión" = soft danger (tinted background, danger text + icon, 48px), not a solid
  fill; "Cancelar" = ghost text button. Destructive first, Cancel last (thumb-closest).
- **Keyboard/focus:** opening the confirm step focuses Cancelar (the safe choice); Cancelar or Esc steps
  BACK to the account step (focus returns to the Cerrar sesión row) rather than closing everything;
  backdrop/swipe close the whole sheet and reset it to the account step.
- **Feedback:** tap → button shows spinner + "Cerrando sesión…", Cancelar disabled/dimmed → sheet closes
  → Ingresar page with "Cerraste sesión" toast. `role="alertdialog"` on the standalone sheet;
  hidden step is `inert`; `prefers-reduced-motion` disables the step animation; safe-area bottom padding.
- Dark theme: danger text/icon lightened (#F2A3B8) for contrast on the dark ground.

Browser-verified light + dark, phone + desktop, variants A and C2, zero JS errors.

## Consistency round: one row system + theme never moves (2026-09-14)
Developer rejected the polish round: "every option displayed on the profile bottom sheet looks
different" (tinted account card, chevron list row, bordered red button, divider, icon row — then a
centered icon card for the confirm), and the theme switcher changed place with login state (public:
drawer bottom; admin C2: inside the account sheet) — "violates the rhythm".

Fix — one anatomy everywhere (drawer, account sheet, confirm step, public drawer when signed in):
- **Row:** `[28px slot: icon or avatar] [label (+ optional secondary line)] [count] [chevron]`, 48px,
  full-bleed hover tint. The ONLY variation is a `danger` tone (text + icon color). No cards, borders,
  filled/soft buttons, or centered layouts inside sheets.
- **Group label** (small uppercase, same as drawer "PANEL"/"SITIO") heads every block: "TU CUENTA",
  "CERRAR SESIÓN".
- **Account sheet:** TU CUENTA → identity row (avatar + email + "Sesión iniciada · Dueña", static) →
  Ver el sitio público › → Cerrar sesión › (danger; chevron because it leads to a step).
- **Confirm step (same sheet):** CERRAR SESIÓN → one muted line naming the account → rows
  "Sí, cerrar sesión" (danger, no chevron) and "‹ Cancelar" (no chevron). Loading replaces the row icon
  with a spinner + "Cerrando sesión…"; the other row dims.
- **Public drawer signed in:** SITIO rows → TU CUENTA group with the exact same three rows (Ir al panel
  instead of Ver el sitio público). Drawer logout opens the same confirm step as a standalone sheet.
- **Theme switcher:** always the drawer's bottom block (divider + 3 icons), identical in admin, public
  signed-in and signed-out — measured 16px from the drawer bottom in all three. Removed from the account
  sheet.

Bugs found and fixed this round:
- Reopening Cuenta shortly after closing could show the stale confirm step (reset ran on a delayed
  timer after close) → reset now runs synchronously on open while the sheet is off-screen.
- Hidden step's translateX offset produced a horizontal scrollbar inside the sheet → `overflow-x: hidden`.
- (Testing artifact, not a bug: CSS transitions pause in a backgrounded automation tab, so mid-transition
  offsets were measured until the tab was foregrounded.)

Principle for 060-063: inside admin, a control keeps the same place and the same row/label anatomy
regardless of state (signed in/out, step, page); variation is expressed by tone or content only.

## Final round: one header for every state + other variants removed (2026-09-14)
Developer: "be sure that header doesn't show that weird 'Panel'… same header as not logged in user.
And remove the other variants."

- **index.html now contains only the final shell** (no variant tabs; A/B/C and the earlier C2 code
  are recoverable from git at commit `0329962`). Top bar switches state only: Admin / Sitio público
  con sesión / Sin sesión; tools: theme, phone/desktop, role.
- **Header identical in all 6 states** (phone + desktop × signed out / public signed in / admin):
  hamburger + isologo + "Pukllay Club" wordmark. Removed: the PANEL mode pill, the desktop header
  avatar, the phone wordmark-hiding in admin, the green signed-in dot and the purple attention dot on
  the hamburger. Verified by comparing the header markup across all 6 states (one unique signature).
- **Drawer identical whenever signed in** (admin or public): PANEL (every section + counts) → SITIO →
  TU CUENTA (identity, Ver el sitio público / Ir al panel, Cerrar sesión). Signed out: SITIO only.
- **Theme block pinned to the drawer's bottom edge**: the signed-in drawer (11 rows) overflowed a phone,
  pushing the theme switcher below the fold (−34px). The list now scrolls inside `.drawer-body` and
  `.drawer-bottom` is fixed — theme measured 16px from the drawer bottom in all 6 states.
- **Signed-in signal** now lives only in the tab bar's Cuenta avatar (green ring) in admin and in the
  drawer's TU CUENTA group everywhere — never in the header.
- **Desktop** tab row under the header: every section + Cuenta at the end (opens the account sheet as
  a dropdown panel).
- Account sheet / confirm step / swipe / Esc / focus / soft content swap unchanged from the
  consistency round.

## Drawer trim (2026-09-14)
Developer: "inside the drawer, not need of 'tu cuenta' section". Removed the TU CUENTA group from the
drawer in every state. Drawer is now PANEL → SITIO when signed in, SITIO when signed out; theme stays
pinned at the bottom. Account + Cerrar sesión live only in the admin tab bar's Cuenta sheet (its
"Ver el sitio público" row is fixed; the "Ir al panel" variant and the standalone drawer confirm sheet
were removed as unused). Consequence, accepted: on a public page while signed in, signing out means
going to the panel (drawer → PANEL) first, then Cuenta.

## Back row scope (2026-09-14)
"‹ Panel" was rendered on every non-Panel page. With the tab bar + drawer, Juegos/Secciones/Estantes/
Revisar niveles/Staff are siblings of Panel (reached from a tab or drawer row), not children — the back
row implied a false hierarchy and duplicated the Panel tab. Applied the existing `page-shell.md` rule
(crumb/back only for genuine drill-downs): no back row on tab/drawer-level pages, so titles sit at the
same height across tabs; back row only on drill-downs (Secciones → Destacados "‹ Secciones"; later
Juegos → editar "‹ Juegos", Estantes → asignar "‹ Estantes").

## Button system from sketch 064 applied (2026-09-15)
The admin now uses one button system everywhere. It's S3 Contorno, weight-tuned; see `064-admin-button-system/README.md`. The identical CSS block ("064: admin button system") is appended to this sketch's `<style>`, scoped with `#device`, so it overrides the older local `.obtn`/`.tbtn` rules.
- **One anatomy:** 44px · 8px radius · 14px/600 · 16px icon · 8px gap.
- **Principal** (`.obtn`/`.b-pri`) is a 1px primary outline. **Secundaria** (`.b-sec`) is a 1px neutral outline (`--stroke`, ≥ 3:1, shared with text fields). **Terciaria** (`.tbtn`) is secondary-purple text. **Peligro** (`.tbtn.danger`) is danger text.
- **No disabled buttons, and Principal is last in its row.**
- Login "Enviarme el link" moved from a grey filled `.btn` to a full-width Principal.
Checked by `064-admin-button-system/audit-admin.js`.

## Font weights normalized to what the app ships (2026-09-15)
The app self-hosts Inter **400 and 600 only** (`assets/css/app.css`), so a declared 500 rendered as 400 and 700 as 600. The sketch's balance was never what ships. This is the same fix 063 got in its R11.
- Every `font-weight: 700` is now 600 and every `500` is now 400. `b, strong, h1–h4, th` are pinned to 600, because their browser default is 700.
- **One state pair collapsed and was re-separated:** tab labels were 600 with the active one at 700, so both became 600. Inactive tab labels are now 400 and the active one stays 600. The other state pairs still differ: drawer rows, chips and the segmented control are all 400 → 600.
- Row names (`.gname`) went from 500 to 400, matching 063's rows.

Checked by `064-admin-button-system/audit-admin.js`: real Inter 400/600 loads, every visible element is 400 or 600, text is Inter or Bebas only, and the active tab label outweighs the inactive ones.

## Applied from sketch 065 (admin composition, 2026-09-15)
Walking the whole admin in one app turned up drift that was invisible one sketch at a time. The
identical shared block "065: one label per job" is appended to 059–063; the changes here are:
- **The polish type scale (061 R2) applied.** 059 had no `.polish` block and never set the class, so
  its titles rendered at 32px Bebas and its login field at the pre-polish scale while every page
  reached from it used 22px Inter.
- Section/field labels follow the shared 065 block.
- *Not* changed: the tab names (Panel · Secciones · Cuenta) and the non-pending counts. 060
  supersedes both, and rewriting them here would falsify the record of this round.
