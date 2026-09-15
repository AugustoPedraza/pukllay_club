---
sketch: 064
name: admin-button-system
question: "How should every action in the admin (059–063) look so the main step is easy to spot, and the same verb always looks the same?"
winner: "S3 (Contorno) — tuned for weight in round 2"
tags: [admin, buttons, cta, consistency, hierarchy, forms, phase-01.8.1, mobile-first]
---

# Sketch 064: Admin button system

## Design Question
Developer, on 063's Estado: "why there are Publicar as text and then there are disable text? I need all CTA and submit consistent. Review all the admin to be sure those are consistent and easily identifiable."

## Audit of 059–063 (before)
| Look | Used for |
|------|----------|
| Outlined `.obtn` | Agregar (061), Guardar cambios (062), Guardar (062 rename, 063 Estado, **disabled when clean**) |
| Text `.tbtn` | **Publicar**, Restaurar, Retirar (red), Reintentar, Mostrar más, Cancelar, Sí, agregar edición, Renombrar, Listo, Ver en la ludoteca / BGG, **Guardar** (062 rename in a sheet) |
| Soft full-width `.cta2` | Agregar a una fila (063) |
| Disclosure `.bgg-more` | Ver más (063) |
| Grey fill + border `.btn` | Enviarme el link (login) |
| Sheet rows `.dlink` | Sí, retirar / Guardar y salir / Descartar / Cancelar |

Problems found:
- **One verb, many looks:** "Guardar" appears 3 ways (outlined, text, sheet row), and "Agregar" 2 ways (outlined, soft).
- **Inverted hierarchy in Estado:** the draft's main next step (Publicar) is the weakest style, a text button, while a *disabled* outlined Guardar is the heaviest thing in the box. That's why it read as "text and then disabled text".
- **Disabled buttons** (Guardar in 062 and 063, Agregar in 061) show a dimmed box that explains nothing. The status line already says "Todo guardado".
- **Button sizes vary:** heights and type sizes differ (48px vs 44px, 13px vs 14px), and the login uses a fifth style.

## How to View
From the repo root: `python3 -m http.server 8765`, then open http://127.0.0.1:8765/.planning/sketches/064-admin-button-system/index.html

The top bar has **Sistema** (S1 / S2 / S3), **Vista** (Teléfono / Todas) and **Tema** (Claro / Oscuro). Every card is a real admin moment from 059–063.

## Shared by all systems (the part that fixes consistency)
- **One anatomy:** 44px tall, 8px radius, 14px/600 label, 16px icon, 8px between buttons. Text-style buttons use 12px side padding so their label lines up with content edges.
- **Four roles:**
  - **Principal:** at most one per block, the step the page is asking for: Publicar (draft), Guardar (with changes), Agregar, Guardar cambios, Enviarme el link.
  - **Secundaria:** a real action that isn't the main step: Guardar next to Publicar, Restaurar, Agregar a una fila, Sí, agregar edición.
  - **Terciaria:** dismiss, navigation, disclosure and links: Cancelar, Reintentar, Mostrar más, Borrar búsqueda, Ver más, Renombrar, Ordenar, Ver en BoardGameGeek ↗.
  - **Peligro:** red text, never Principal, always confirmed in a sheet: Retirar.
- **Order:** action rows are right-aligned with Principal last. Peligro goes to the far left when it shares a row with Principal. An inline form's button sits beside its field. The single-task login button is full width.
- **No disabled buttons:** Guardar only exists while there are changes. Submits validate on tap, e.g. empty Agregar → "Pegá un ID o link de BGG." + focus.
- **Estado layout:** the status and its line on top, the actions row below. The status never gets squeezed into a column beside two buttons.
  - Borrador: [Publicar]; with changes: [Guardar] [Publicar].
  - Publicado: [Retirar de la web]; with changes: Retirar … [Guardar].
  - Retirado: [Restaurar].
- **Sheets stay 059 rows** (Sí, retirar / Cancelar), not buttons.

## Variants (paint only)
- **S1: Relleno.** Material 3 filled / tonal / text. Principal = solid primary with white text; Secundaria = surface-2 tonal with primary text; Terciaria = primary text. daisyUI: `btn btn-primary` / `btn btn-soft btn-primary` / `btn btn-ghost`. **Overturns 061's "never filled" rule** (and 060's "no filled buttons"). It's the easiest to spot.
- **S2: Tonal.** Principal = a strong primary tint (a white-text tint in dark); Secundaria = primary-tinted outline; Terciaria = text. daisyUI: `btn btn-soft btn-primary` / `btn btn-outline btn-primary` / `btn btn-ghost`. No solid fill, but on the lavender boxes the tonal Principal sits close to the box color.
- **S3: Contorno (the 061 rule, tightened).** Principal = 1.5px primary outline with primary text; Secundaria = neutral outline; Terciaria = text. daisyUI: `btn btn-outline btn-primary` / `btn btn-outline` / `btn btn-ghost`. The closest to today; Principal and Secundaria differ only by border color and weight.

## Winner: S3 Contorno, weight-tuned (round 2, 2026-09-15)
Developer: "S3 looks better. Just be sure that has the correct weight so don't look unbalanced."

S1 and S2 and the Sistema switch are removed (commit `bf17cf7` is their record). What was unbalanced in S3, and the fix:
- **Stroke widths were mixed:** Principal had 1.5px (heavy and blurry at 1x density), Secundaria 1px. Now there's **one 1px stroke for every outline**: Principal, Secundaria and text fields.
- **Secundaria was too faint:** a surface-2 stroke at about 1.4:1 made "Sí, agregar edición" and "Guardar" read as white cards or inputs. Secundaria and fields now share one neutral token, `--stroke` (text mixed into bg: 58% light, 42% dark), at **≥ 3:1** (WCAG 1.4.11). Measured 3.7:1 light, 3.1:1 dark.
- **Text buttons competed with Principal:** they used the same primary color and weight. Terciaria now uses `--color-secondary` (dark: `--color-text-muted`), one step lighter but still ≥ 4.5:1.

The resulting ladder, measured:

| Role | Stroke | Label contrast | daisyUI |
|------|--------|----------------|---------|
| Principal | 1px primary, 12.2:1 (dark 10.5) | 14.2:1 | `btn btn-outline btn-primary` |
| Secundaria | 1px neutral `--stroke`, 3.7:1 (dark 3.1) | text color | `btn btn-outline` with a neutral border |
| Terciaria | none | ≤ 6.0:1 (secondary purple) | `btn btn-ghost` |
| Peligro | none | danger | `btn btn-ghost text-error` |

Verified in headless Chrome, 30 of 30 checks. New since round 1:
- One stroke width across Principal, Secundaria and fields.
- Secundaria and field strokes ≥ 3:1, and the same token.
- Principal stroke more than 1.5× stronger than Secundaria.
- Terciaria labels lighter than Principal labels.
- Only one system left.

## Applied to 059–063 (2026-09-15)
The identical "064: admin button system" CSS block is appended to every admin sketch, scoped with `#device`. Per-sketch changes are listed in each sketch's README:
- **Logins (059–062)** → a full-width Principal.
- **061/062:** add forms are never disabled; empty names/values error on submit; "Sí, agregar edición" → Secundaria.
- **062 only:** "Guardar cambios" only with changes; the rename sheet's Guardar → Principal; Invitar hidden (not disabled) when the staff is full.
- **063:** Estado role matrix with status on top; "Agregar a una fila" → Secundaria; "Ver más" → Terciaria.

**Cross-sketch audit:** `audit-admin.js` loads every admin sketch and walks 25 screens/states in light and dark.
- **Screens:** logins, Juegos + the edition prompt, Web, Estantes, Asignar, Niveles, Staff (+ an empty invite), the rename sheet, a dirty section editor, and 063 draft/published/retired, clean/dirty and BGG failed.
- **Every visible action button:**
  - 44px, 8px radius, 14px/600, not disabled;
  - outlined roles have a 1px stroke and text roles none;
  - the role actually renders its paint (Peligro red, Terciaria `--ter`), which catches specificity losses;
  - label ≥ 4.5:1;
  - outlined buttons stay inside their container's content edge;
  - at most one Principal per action row, and it's last.
- **Text fields:** 1px stroke ≥ 3:1.

Result: 89 of 89. Run: `python3 -m http.server 8765 &` then `node .planning/sketches/064-admin-button-system/audit-admin.js`.

Still open (not part of the button work): 059–062 still declare some 500/700 font weights (only 063 was normalized to the app's 400/600 in its R11).

## What to Look For
- In Estado (borrador con cambios), can you tell in half a second which button publishes?
- Does Retirar feel far enough from Guardar (publicado con cambios)?
- Do the forms (Agregar, Renombrar, Guardar cambios, login) all read as the same kind of submit?
- Check dark mode, and the "Todas" view for the whole admin side by side.

## Verification
`verify.js` (round 1 version) ran 44 checks in headless Chrome for every system × light/dark:
- no overflow at 420px;
- every button is 44px / 8px radius / 14px 600;
- no disabled buttons;
- at most one Principal per block, and Peligro is never Principal;
- the four roles are painted four different ways;
- every label has ≥ 4.5:1 contrast against the color actually behind it.

It also checks:
- the Estado role matrix;
- Principal last in every action row;
- empty Agregar validates on tap and focuses the field, and typing clears the error;
- desktop has no overflow.

The first run showed 3 false contrast failures: `color-mix()` backgrounds come back as `color(srgb 0–1)` and were parsed as 0–255. The parser is fixed; real contrast passes.
