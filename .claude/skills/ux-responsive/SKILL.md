---
name: ux-responsive
description: This repo's real breakpoint values, touch-target minimums, and touch-vs-pointer rules for PukllayClub's Phoenix/LiveView UI. Load before layout, responsive, or mobile work — anything that changes at a breakpoint or must work by tap as well as pointer.
---

## Breakpoints in force

`assets/css/app.css`'s `@theme` block declares no `--breakpoint-*` overrides, so Tailwind v4's
defaults are in force: `sm` 40rem/640px, `md` 48rem/768px, `lg` 64rem/1024px, `xl` 80rem/1280px,
`2xl` 96rem/1536px. Only `sm:` and `lg:` are used anywhere in `lib/pukllay_club_web/` today —
reaching for `md:`, `xl:`, or `2xl:` is a new convention and needs a reason.

## What changes at each breakpoint

| Pattern (see `ux-patterns`) | base (under `sm`) | at `sm` (640px) | at `lg` (1024px) | Implement with (this repo) |
|---|---|---|---|---|
| Catalog grid | `grid-cols-2` | `grid-cols-3` | `grid-cols-4` | `grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4`; the skeleton at `index.ex:305` carries the identical classes so loading doesn't reflow |
| Page container (`Layouts.app`) | `px-4` | `px-6` | `px-8` | Each page's own `mx-auto max-w-{size} px-4 py-6 sm:px-6 lg:px-8`; `Layouts.app`'s `<main>` separately owns `px-4 py-20 sm:px-6 lg:px-8`, and `CatalogLive.Show` relies on that padding (it declares none of its own) |
| Filter drawer | trigger button + closed `drawer-side` | no change | no change | `FilterDrawer.filter_drawer/1` — daisyUI `drawer drawer-end`, open/close is a bare checkbox, pure CSS, no breakpoint logic (`filter_drawer.ex:33-41`) |
| Carousel row card | `w-40 shrink-0` | `w-48` | no further change | `CarouselRow` card sizing — `w-40 shrink-0 sm:w-48` |
| Detail page | single centred column | no change | no change | `CatalogLive.Show` — one centred column at every viewport; the two-pane branch has never existed here |
| Master/detail (B6/B31) | n/a — unbuilt | n/a — unbuilt | n/a — unbuilt | Not built; blocked on F34's uncommitted device-target decision before any breakpoint can be picked |
| Nav swap (B8/B32) | n/a — unbuilt | n/a — unbuilt | n/a — unbuilt | Not built; `Layouts.app`'s navbar only changes horizontal padding across breakpoints (`layouts.ex`); blocked on F34 |

## Touch targets

`min-h-11` (44px) is this app's minimum for any tappable pill or button — live today on the
drawer trigger (`btn btn-primary min-h-11`, `filter_drawer.ex:36`) and every facet pill (`badge
min-h-11 px-3`, `filter_drawer.ex:131`). See `ui-design-system`'s spacing scale for the owning
rule; don't restate a second number here. C20 records a source disagreement — Material 3's 48dp
vs Apple HIG's 44pt — and this repo has standardized on the 44px/44pt figure.

## Touch vs pointer

Hover may never be the only way to reveal something a user needs (E25) — a touch device has no
hover state. The daisyUI drawer and carousel both already work by tap alone with no JS hook.
B28's keyboard row navigation (arrows / `J` / `K`) is pointer/keyboard-only and, if built, needs
a client-side JS hook rather than a server round-trip per keypress (see `ux-patterns`).

## Scope

This covers responsive web only. No `manifest.json`/`.webmanifest` and no service worker exist in
this repo, so E27's PWA concerns (offline state, install prompt, splash/theme color,
standalone-mode chrome) are out of scope until they do.
