---
sketch: 059
name: admin-shell
question: "How does a signed-in staff member navigate admin on a phone, know they're authenticated, and sign out?"
winner: "C"
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
Ingresar, no horizontal overflow on any screen, desktop, zero JS errors. Winner still recorded as C
pending the developer's C vs C2 call.
