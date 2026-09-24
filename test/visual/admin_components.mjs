#!/usr/bin/env node
// D-18's harness: the admin's measurable design rules, ported from the
// sketch lineage's own audit scripts and run against the REAL /admin, in
// real headless Chrome, over a real staff session — not against
// `.planning/sketches/`. Plan 01.8.2-12 Task 1.
//
// Sources ported (named so a future reader can find the original rule):
//   - .planning/sketches/064-admin-button-system/audit-admin.js — A1-A9,
//     narrowed to the subset 01.8.2-12-PLAN.md Task 1 names: height,
//     stroke, radius, padding, natural width, and the at-most-one-
//     outlined-per-block rule, plus the 44px hit-box floor (A8) and "a
//     sheet has no buttons" (A9). The at-most-one-outlined rule is ported
//     from `AdminComponents`' OWN shipped moduledoc contract (three rules,
//     `lib/pukllay_club_web/components/admin_components.ex` lines 18-20),
//     not the sketch's older two-role variant — the real component's own
//     stated contract is the more authoritative, more current source.
//   - .planning/sketches/065-admin-composition/verify.js — D1 (back rows
//     align), D2 (one page-title type), D3 (page head sits a fixed
//     distance above the body, and the title itself starts at a fixed
//     height).
//   - .planning/sketches/065-admin-composition/verify.js's K1 (16px
//     fields on a coarse pointer, so iOS never zooms on focus) plus the
//     viewport meta's own zoom-lockout guard from the same rule.
//   - `assets/css/admin/tokens.css`'s D-19o press-state rule
//     (`[data-pk-pressable]:active`) and `assets/js/hooks/admin_sheet.js`
//     (Esc / scrim tap / drag-down close, focus trap, focus return) — the
//     01.8.2-08 SUMMARY's own recorded gap: shipped with zero runtime
//     coverage because no `sheet/1` call site existed yet. Plan 01.8.2-11
//     shipped the FIRST real call site (Staff's options sheet + its
//     centred "Quitar del staff" dialog) — this is that coverage.
//
// K2 (tab bar leaves while a field has focus) and K3 (a sheet with the
// keyboard open sits ON the keyboard, not under it) are DELIBERATELY NOT
// ported here. The sketch's own K2/K3 probes drove a hand-rolled `.kbdsim`
// div that faked a keyboard's on-screen height — a real browser's on-screen
// keyboard has no CDP-observable geometry at all in headless mode (no
// `VisualViewport` resize occurs without a REAL platform keyboard), so a
// script here could only ever re-fake the same illusion the sketch did,
// which is not a measurement of the shipped admin — it is a measurement of
// this script's own fake keyboard. This is exactly the "rules the harness
// cannot measure are carried to the UAT phone checklist rather than
// dropped" must-have: both are checklist items 4 ("does the keyboard push
// [the sheet] or cover it (K1)?") and item 6/7 in
// `01.8.2-DEVICE-PASS.md`, confirmed on a REAL phone with a REAL keyboard
// instead.
//
// ---------------------------------------------------------------------
// Guard-writing rules earned across the 059-080 sketch lineage
// (01.8.2-CONTEXT.md's canonical_refs) — every check below follows these:
//   1. Assert geometry BEFORE reading a pixel diff.
//   2. Read rect + resolved colour, never node existence (079's status dot
//      vanished three times for three different causes with node-count
//      checks green).
//   3. Use `offsetParent`, never `.hidden` — a class setting `display`
//      out-specifies a bare `[hidden]` attribute selector.
//   4. Every class that sets `display` carries its own `[hidden]`
//      companion (not applicable to anything in this file — noted for the
//      next author who extends it).
//   5. Normalise whitespace before matching rendered text.
//   6. Measure the fold against the pinned overlay's top, not the
//      scroller's rect (not applicable to this file's checks — relevant to
//      `admin_shell.mjs`'s page-bar work; noted for the next author).
//   7. Measure ink, not boxes, when the element draws nothing.
// ---------------------------------------------------------------------
//
// Developer-invoked only — not wired into `mix quality` or CI (needs a
// real browser, a booted server, and a real staff session). See
// `test/visual/README.md`.
//
// Usage: node test/visual/admin_components.mjs
// Env:   PROBE_BASE_URL=http://localhost:4000  (skip booting a dev server)
//        STAFF_EMAIL=... (defaults to the dev owner seeded in this repo)

import { spawn } from "node:child_process"
import { mkdtemp, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

const PROBE_BASE_URL = process.env.PROBE_BASE_URL
const STAFF_EMAIL = process.env.STAFF_EMAIL || "augusto.pedraza08@gmail.com"

// 375x667 (iPhone SE-class), 360x640 (small Android), 390x844 (iPhone
// 12/13/14-class) — the plan's own stated trio.
const VIEWPORTS = [
  { w: 375, h: 667 },
  { w: 360, h: 640 },
  { w: 390, h: 844 },
]
const THEMES = ["light", "dark"]

// The two shipped admin pages with real content as of this plan (01.8.2-11
// shipped the dashboard + Staff). Append a new route here the same way
// `admin_composition_test.exs`'s own `@files` list is appended per plan —
// no other change to this file is needed.
const PAGES = [
  "/admin",
  "/admin/staff",
  "/admin/estantes",
  "/admin/estantes/pendientes",
  "/admin/estantes/administrar",
  "/admin/juegos",
  "/admin/secciones",
  "/admin/niveles",
]

// Plan 01.8.2-17: the game editor is NOT appended to `PAGES` above — its
// content wrapper (`.pk-editor-body`, a 16px keel `<div>`, not the shared
// `main .mx-auto.w-full.max-w-3xl` shape) and its title
// (`.pk-editor-topbar__title`, not `.pk-admin-page-title`) are a
// deliberately different shell per D-27/D-30 ("the ONE documented
// exception to..."), so folding it into the cross-page D1/D2/D3
// consistency checks above would compare two intentionally different
// shells against each other. It IS swept through `runPageCase`/`CHECKS`
// (the anatomy/padding/44px-floor/contrast/no-daisy-button assertions,
// which apply to every `.pk-admin-action`/`.pk-admin-editable-row`
// regardless of which page shell renders them) via its own dedicated block
// in `main()`, `resolveEditorUrl`/`runEditorPageChecks` below.

function log(...args) {
  console.log(...args)
}

// ---------------------------------------------------------------------------
// Dev server lifecycle (about_geometry.mjs's own pattern)
// ---------------------------------------------------------------------------
async function startDevServer() {
  if (PROBE_BASE_URL) {
    log(`Using existing server at ${PROBE_BASE_URL} (PROBE_BASE_URL set) — starting nothing.`)
    return { baseUrl: PROBE_BASE_URL, proc: null }
  }

  const baseUrl = "http://localhost:4000"
  log("Booting `mix phx.server`...")

  let stderrBuf = ""
  const proc = spawn("mix", ["phx.server"], {
    env: { ...process.env, MIX_ENV: "dev" },
    stdio: ["ignore", "pipe", "pipe"],
  })
  proc.stdout.on("data", (d) => (stderrBuf += d.toString()))
  proc.stderr.on("data", (d) => (stderrBuf += d.toString()))

  const deadline = Date.now() + 60_000
  let up = false
  while (Date.now() < deadline) {
    try {
      const res = await fetch(`${baseUrl}/up`)
      if (res.status === 200) {
        up = true
        break
      }
    } catch {
      // not up yet
    }
    await new Promise((r) => setTimeout(r, 500))
  }

  if (!up) {
    proc.kill()
    throw new Error(`dev server did not answer /up within 60s. Captured output:\n${stderrBuf}`)
  }

  log("Dev server is up.")
  return { baseUrl, proc }
}

async function stopDevServer(proc) {
  if (!proc || proc.exitCode !== null || proc.killed) return
  const exited = new Promise((resolve) => proc.once("exit", resolve))
  proc.kill()
  await Promise.race([exited, new Promise((r) => setTimeout(r, 5000))])
}

// ---------------------------------------------------------------------------
// Chrome lifecycle
// ---------------------------------------------------------------------------
function findChromeBinary() {
  return ["google-chrome-stable", "google-chrome", "chromium", "chromium-browser"]
}

async function startChrome() {
  const userDataDir = await mkdtemp(join(tmpdir(), "admin-components-chrome-"))
  const candidates = findChromeBinary()

  let proc = null
  let lastErr = null
  for (const bin of candidates) {
    try {
      proc = spawn(
        bin,
        [
          "--headless=new",
          "--disable-gpu",
          "--hide-scrollbars",
          "--no-first-run",
          "--no-sandbox",
          `--user-data-dir=${userDataDir}`,
          "--remote-debugging-port=0",
        ],
        { stdio: ["ignore", "ignore", "pipe"] },
      )
      await new Promise((resolve, reject) => {
        proc.once("spawn", resolve)
        proc.once("error", reject)
      })
      break
    } catch (err) {
      lastErr = err
      proc = null
    }
  }

  if (!proc) {
    await rm(userDataDir, { recursive: true, force: true })
    throw new Error(`Could not spawn any of: ${candidates.join(", ")}. Last error: ${lastErr?.message}`)
  }

  let stderrBuf = ""
  const port = await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      reject(new Error(`no DevTools endpoint on chrome stderr within 15s. Captured stderr:\n${stderrBuf}`))
    }, 15_000)

    proc.stderr.on("data", (d) => {
      stderrBuf += d.toString()
      const m = stderrBuf.match(/DevTools listening on ws:\/\/[^:]+:(\d+)\//)
      if (m) {
        clearTimeout(timeout)
        resolve(Number(m[1]))
      }
    })
  })

  return { proc, userDataDir, port }
}

async function stopChrome({ proc, userDataDir }) {
  if (proc && proc.exitCode === null && !proc.killed) {
    const exited = new Promise((resolve) => proc.once("exit", resolve))
    proc.kill()
    await Promise.race([exited, new Promise((r) => setTimeout(r, 5000))])
  }
  await rm(userDataDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 })
}

// ---------------------------------------------------------------------------
// Minimal CDP client
// ---------------------------------------------------------------------------
class CDPClient {
  constructor(ws) {
    this.ws = ws
    this.nextId = 1
    this.pending = new Map()
    ws.addEventListener("message", (ev) => {
      const msg = JSON.parse(ev.data)
      if (msg.id !== undefined && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id)
        this.pending.delete(msg.id)
        if (msg.error) reject(new Error(JSON.stringify(msg.error)))
        else resolve(msg.result)
      }
    })
  }

  send(method, params = {}) {
    const id = this.nextId++
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject })
      this.ws.send(JSON.stringify({ id, method, params }))
    })
  }
}

async function connectCDP(port) {
  const res = await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: "PUT" })
  const target = await res.json()
  const ws = new WebSocket(target.webSocketDebuggerUrl)
  await new Promise((resolve, reject) => {
    ws.addEventListener("open", resolve, { once: true })
    ws.addEventListener("error", reject, { once: true })
  })
  const client = new CDPClient(ws)
  await client.send("Page.enable")
  await client.send("Runtime.enable")
  await client.send("Input.setIgnoreInputEvents", { ignore: false })
  return client
}

async function navigate(client, url) {
  const navigated = new Promise((resolve) => {
    const handler = (ev) => {
      const msg = JSON.parse(ev.data)
      if (msg.method === "Page.loadEventFired") {
        client.ws.removeEventListener("message", handler)
        resolve()
      }
    }
    client.ws.addEventListener("message", handler)
  })
  await client.send("Page.navigate", { url })
  await navigated
}

async function evalJS(client, expression, returnByValue = true) {
  const result = await client.send("Runtime.evaluate", { expression, returnByValue, awaitPromise: true })
  if (result.exceptionDetails) {
    throw new Error(`Eval error: ${JSON.stringify(result.exceptionDetails)}`)
  }
  return result.result.value
}

async function setViewport(client, width, height) {
  await client.send("Emulation.setDeviceMetricsOverride", {
    width,
    height,
    deviceScaleFactor: 1,
    mobile: false,
  })
}

async function setTheme(client, theme) {
  const expr = `
    document.documentElement.dataset.theme = ${JSON.stringify(theme)};
    document.documentElement.dataset.themeSource = "user";
    true
  `
  // One retry: immediately after `Page.navigate`'s `loadEventFired`, the
  // execution context can momentarily be mid-transition (observed once in
  // this file's own development — `document.documentElement` came back
  // null on the very first case after login, never on any later case). A
  // short wait and a single retry is cheap insurance against that specific
  // race; a genuine failure still surfaces on the second attempt.
  try {
    await evalJS(client, expr)
  } catch {
    await new Promise((r) => setTimeout(r, 200))
    await evalJS(client, expr)
  }
}

// ---------------------------------------------------------------------------
// Staff login — the real magic-link flow, the same pattern this plan's own
// read_first names as proven (01.8.2-10's checkpoint-prep scratchpad
// script). Logs in ONCE; the session cookie carries across every
// subsequent navigation this file performs.
// ---------------------------------------------------------------------------
async function loginAsStaff(client, baseUrl) {
  await navigate(client, `${baseUrl}/admin/ingresar`)
  await new Promise((r) => setTimeout(r, 400))

  await evalJS(
    client,
    `
    (() => {
      const input = document.querySelector('input[type="email"]');
      if (!input) throw new Error('login: no email input found on /admin/ingresar');
      input.value = ${JSON.stringify(STAFF_EMAIL)};
      input.dispatchEvent(new Event('input', { bubbles: true }));
      const form = input.closest('form');
      form.requestSubmit();
      return true;
    })()
  `,
  )
  await new Promise((r) => setTimeout(r, 800))

  await navigate(client, `${baseUrl}/dev/mailbox`)
  await new Promise((r) => setTimeout(r, 300))

  const magicLinkJSON = await evalJS(
    client,
    `JSON.stringify((document.documentElement.outerHTML.match(/http:\\/\\/[^"'<\\s]*\\/admin\\/ingresar\\/[^"'<\\s]+/g)) || [])`,
  )
  const magicLinks = JSON.parse(magicLinkJSON)
  if (magicLinks.length === 0) throw new Error("login: no magic link found in the dev mailbox")
  const magicLink = magicLinks[magicLinks.length - 1] // newest message

  await navigate(client, magicLink)
  await new Promise((r) => setTimeout(r, 400))

  await evalJS(
    client,
    `
    (() => {
      const btn = document.querySelector('button[type="submit"], form button');
      if (btn) btn.click();
      return !!btn;
    })()
  `,
  )
  await new Promise((r) => setTimeout(r, 1200))

  const confirmed = await evalJS(
    client,
    `document.body ? document.body.innerHTML.includes('pk-admin-tab-bar') : false`,
  )
  if (!confirmed) {
    throw new Error("login: post-login page does not render the admin tab bar — login did not complete")
  }
}

// ---------------------------------------------------------------------------
// Shared colour-contrast helpers (rect + resolved colour, guard rule 2)
// ---------------------------------------------------------------------------
// Kept as a JS-source STRING (not a Node function) so it can be inlined
// into `Runtime.evaluate` payloads and run inside the page — this file
// itself never touches the DOM.
const PAGE_HELPERS = `
  function parseRgb(str) {
    const m = str.match(/rgba?\\(([^)]+)\\)/);
    if (!m) return null;
    const parts = m[1].split(',').map(s => parseFloat(s.trim()));
    return { r: parts[0], g: parts[1], b: parts[2], a: parts.length > 3 ? parts[3] : 1 };
  }
  function relLum(c) {
    const chan = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
    return 0.2126 * chan(c.r) + 0.7152 * chan(c.g) + 0.0722 * chan(c.b);
  }
  function bgOf(el) {
    let base = { r: 255, g: 255, b: 255 };
    const stack = [];
    for (let n = el; n; n = n.parentElement) {
      const c = parseRgb(getComputedStyle(n).backgroundColor);
      if (c && c.a > 0) { stack.push(c); if (c.a === 1) break; }
    }
    for (const c of stack.reverse()) {
      base = { r: c.r * c.a + base.r * (1 - c.a), g: c.g * c.a + base.g * (1 - c.a), b: c.b * c.a + base.b * (1 - c.a) };
    }
    return base;
  }
  function contrast(fgStr, bgEl) {
    const fg = parseRgb(fgStr);
    if (!fg) return null;
    const bg = bgOf(bgEl);
    const L1 = relLum(fg), L2 = relLum(bg);
    return (Math.max(L1, L2) + 0.05) / (Math.min(L1, L2) + 0.05);
  }
  function normText(el) {
    return (el.textContent || '').replace(/\\s+/g, ' ').trim();
  }
`

// ---------------------------------------------------------------------------
// Per-page, per-viewport measurement
// ---------------------------------------------------------------------------
async function runPageCase({ client, baseUrl, page, viewport, theme }) {
  await setViewport(client, viewport.w, viewport.h)
  await navigate(client, `${baseUrl}${page}`)
  await setTheme(client, theme)
  await new Promise((r) => setTimeout(r, 200))

  const json = await evalJS(
    client,
    `
    ${PAGE_HELPERS}
    JSON.stringify((() => {
      // guard rule 3: offsetParent, never .hidden.
      const visible = el => el.offsetParent !== null;

      const blockSelector = '.pk-admin-section-panel, .pk-admin-sheet, .pk-admin-dialog, main, form, .pk-admin-invite-form';
      const rowSelector = '.pk-admin-row, .pk-admin-editable-row, .pk-admin-dash-box';

      const actions = [...document.querySelectorAll('.pk-admin-action')].filter(visible).map(el => {
        const r = el.getBoundingClientRect();
        const cs = getComputedStyle(el);
        const block = el.closest(blockSelector);
        const row = el.closest(rowSelector);
        const blockContentWidth = block
          ? (() => {
              const br = block.getBoundingClientRect();
              const bs = getComputedStyle(block);
              return br.width - parseFloat(bs.paddingLeft) - parseFloat(bs.paddingRight);
            })()
          : null;
        return {
          label: normText(el).slice(0, 40) || el.getAttribute('aria-label') || '(no label)',
          anatomy: [...el.classList].find(c => /^pk-admin-action--a[1-4]$/.test(c)) || null,
          role: [...el.classList].find(c => /^pk-admin-action--(principal|secundaria|terciaria|peligro)$/.test(c)) || null,
          rect: { x: r.x, y: r.y, width: r.width, height: r.height },
          borderWidth: parseFloat(cs.borderTopWidth) * (cs.borderTopStyle === 'none' ? 0 : 1),
          borderRadius: cs.borderTopLeftRadius,
          paddingLeft: parseFloat(cs.paddingLeft),
          paddingRight: parseFloat(cs.paddingRight),
          fontSize: parseFloat(cs.fontSize),
          fontWeight: cs.fontWeight,
          color: cs.color,
          disabled: el.disabled === true || el.getAttribute('aria-disabled') === 'true',
          blockKey: block ? (block.id || [...block.classList].join('.') || block.tagName) : null,
          inSheetRows: !!el.closest('.pk-admin-sheet__rows'),
          inRow: !!row,
          blockContentWidth,
          contrast: contrast(cs.color, el),
        };
      });

      const fields = [...document.querySelectorAll('.pk-admin-field__control')].filter(visible).map(el => {
        const cs = getComputedStyle(el);
        return {
          id: el.id || el.name || '(unnamed)',
          fontSize: parseFloat(cs.fontSize),
          borderWidth: parseFloat(cs.borderTopWidth),
          borderColor: cs.borderTopColor,
          rect: (() => { const r = el.getBoundingClientRect(); return { height: r.height }; })(),
        };
      });

      // A8: every tappable, hit box measured including any bleeding
      // ::after pseudo-element — not the drawn box (guard rule 7 variant:
      // this is the one case this codebase's own lineage found where the
      // DRAWN box under-reports the real tap target).
      const tappableSelector = '.pk-admin-action, [data-pk-pressable], .pk-admin-row, .pk-admin-editable-row';
      const tappables = [...document.querySelectorAll(tappableSelector)].filter(visible).map(el => {
        const r = el.getBoundingClientRect();
        const after = getComputedStyle(el, '::after');
        const top = parseFloat(after.top), bottom = parseFloat(after.bottom);
        const hasBleed = after.content !== 'none' && !isNaN(top) && !isNaN(bottom) && (top < 0 || bottom < 0);
        const hit = hasBleed ? r.height - top - bottom : r.height;
        return { label: normText(el).slice(0, 30) || el.tagName, hit };
      });

      const titleEl = document.querySelector('.pk-admin-page-title');
      const backEl = document.querySelector('.pk-admin-back-row');
      let headToBody = null;
      if (titleEl) {
        const titleRect = titleEl.getBoundingClientRect();
        const wrap = titleEl.parentElement;
        const next = titleEl.nextElementSibling;
        if (next) {
          const nextRect = next.getBoundingClientRect();
          headToBody = Math.round((nextRect.top - titleRect.bottom) * 10) / 10;
        }
      }

      const sheetCancelText = [...document.querySelectorAll('.pk-admin-sheet__rows *')]
        .filter(visible)
        .some(el => normText(el) === 'Cancelar');

      return {
        actions,
        fields,
        tappables,
        title: titleEl
          ? {
              text: normText(titleEl),
              fontSize: parseFloat(getComputedStyle(titleEl).fontSize),
              fontWeight: getComputedStyle(titleEl).fontWeight,
              fontFamily: getComputedStyle(titleEl).fontFamily,
              top: Math.round(titleEl.getBoundingClientRect().top * 10) / 10,
            }
          : null,
        back: backEl ? { top: Math.round(backEl.getBoundingClientRect().top * 10) / 10 } : null,
        headToBody,
        sheetHasCancelRow: sheetCancelText,
      };
    })())
  `,
  )

  return JSON.parse(json)
}

// ---------------------------------------------------------------------------
// CHECKS — A1-A9 (narrowed to height/stroke/radius/padding/natural-width/
// at-most-one-outlined-per-block, A7, A8, A9) + D1-D3. Each takes
// (measured, ctx) and returns an array of failure strings. Append new
// check functions here; the sweep loop in main() needs no changes.
// ---------------------------------------------------------------------------
const ANATOMY_SPEC = {
  a1: { minHeight: 44, radius: "8px", stroke: 1, padding: 16, fontSize: 14, fontWeight: "600" },
  a2: { minHeight: 44, radius: "8px", stroke: 0, padding: 12, fontSize: 14, fontWeight: "600" },
  a3: { minHeight: 44, radius: "50%", stroke: 0, padding: 0, fontSize: 14, fontWeight: "600" },
  a4: { minHeight: 48, radius: "0px", stroke: 0, padding: 16, fontSize: 16, fontWeight: "400" },
}

function label(ctx) {
  return `[${ctx.page} @ ${ctx.viewport.w}x${ctx.viewport.h}, ${ctx.theme}]`
}

// A1/A2/A3/A4 own anatomy contract: height, stroke, radius, padding.
function checkAnatomyGeometry(measured, ctx) {
  const failures = []
  for (const a of measured.actions) {
    if (!a.anatomy) {
      failures.push(`${label(ctx)} ${a.label}: no pk-admin-action--a[1-4] anatomy class found`)
      continue
    }
    const spec = ANATOMY_SPEC[a.anatomy.replace("pk-admin-action--", "")]
    const roundedHeight = Math.round(a.rect.height)
    if (roundedHeight < spec.minHeight) {
      failures.push(
        `${label(ctx)} ${a.anatomy} "${a.label}": height ${roundedHeight}px, expected >= ${spec.minHeight}px`,
      )
    }
    if (a.borderRadius !== spec.radius) {
      failures.push(`${label(ctx)} ${a.anatomy} "${a.label}": radius ${a.borderRadius}, expected ${spec.radius}`)
    }
    const wantStroke = spec.stroke === 1
    const hasStroke = a.borderWidth >= 1
    if (wantStroke !== hasStroke) {
      failures.push(
        `${label(ctx)} ${a.anatomy} "${a.label}": stroke ${a.borderWidth}px, expected ${wantStroke ? "1px" : "0px"}`,
      )
    }
    if (a.fontSize !== spec.fontSize || a.fontWeight !== spec.fontWeight) {
      failures.push(
        `${label(ctx)} ${a.anatomy} "${a.label}": font ${a.fontSize}/${a.fontWeight}, expected ${spec.fontSize}/${spec.fontWeight}`,
      )
    }
  }
  return failures
}

// Padding — a1/a2/a4 declare a side padding (a3 is a borderless circle with
// no meaningful side padding, excluded).
function checkAnatomyPadding(measured, ctx) {
  const failures = []
  for (const a of measured.actions) {
    if (!a.anatomy) continue
    const key = a.anatomy.replace("pk-admin-action--", "")
    if (key === "a3") continue
    const want = ANATOMY_SPEC[key].padding
    if (Math.round(a.paddingLeft) !== want || Math.round(a.paddingRight) !== want) {
      failures.push(
        `${label(ctx)} ${a.anatomy} "${a.label}": padding ${a.paddingLeft}/${a.paddingRight}px, expected ${want}px both sides`,
      )
    }
  }
  return failures
}

// Natural width: a1/a2/a3 must NOT stretch to fill their block (that is A4's
// job, and only A4's). a4 IS meant to be full-bleed.
function checkNaturalWidth(measured, ctx) {
  const failures = []
  for (const a of measured.actions) {
    if (!a.anatomy || a.blockContentWidth == null) continue
    const key = a.anatomy.replace("pk-admin-action--", "")
    const fillsBlock = a.rect.width >= a.blockContentWidth - 1
    if (key === "a4" && !fillsBlock) {
      failures.push(
        `${label(ctx)} a4 "${a.label}": width ${a.rect.width.toFixed(1)}px does not fill its block's content width ${a.blockContentWidth.toFixed(1)}px — a4 is full-bleed by design`,
      )
    }
    if (key !== "a4" && fillsBlock) {
      failures.push(
        `${label(ctx)} ${a.anatomy} "${a.label}": width ${a.rect.width.toFixed(1)}px fills its block's content width ${a.blockContentWidth.toFixed(1)}px — only a4 is full-bleed, this anatomy must stay natural width`,
      )
    }
  }
  return failures
}

// AdminComponents' own shipped contract (admin_components.ex lines 18-20):
// rule 1, at most one a1 (outlined) per block.
function checkAtMostOneOutlinedPerBlock(measured, ctx) {
  const byBlock = new Map()
  for (const a of measured.actions) {
    if (a.anatomy !== "pk-admin-action--a1" || !a.blockKey) continue
    byBlock.set(a.blockKey, (byBlock.get(a.blockKey) || []).concat(a.label))
  }
  const failures = []
  for (const [block, labels] of byBlock) {
    if (labels.length > 1) {
      failures.push(`${label(ctx)} block "${block}": ${labels.length} outlined (a1) actions (${labels.join(", ")}) — at most one per block`)
    }
  }
  return failures
}

// AdminComponents' own shipped contract, rule 3: a row-level action is
// never outlined (a1).
function checkNoOutlinedInRow(measured, ctx) {
  const failures = []
  for (const a of measured.actions) {
    if (a.anatomy === "pk-admin-action--a1" && a.inRow) {
      failures.push(`${label(ctx)} "${a.label}": outlined (a1) action nested inside a row — row-level actions must never be outlined`)
    }
  }
  return failures
}

// A7 — a destructive (peligro) action is never outlined (a1).
function checkPeligroNeverOutlined(measured, ctx) {
  const failures = []
  for (const a of measured.actions) {
    if (a.anatomy === "pk-admin-action--a1" && a.role === "pk-admin-action--peligro") {
      failures.push(`${label(ctx)} "${a.label}": a destructive (peligro) action is outlined (a1)`)
    }
  }
  return failures
}

// A9 — a sheet has no buttons other than a4 rows (its header close ✕ is
// the one a3 exception, outside .pk-admin-sheet__rows); no Cancelar row
// (D-19e retired that shape outright — a Cancelar row reappearing would be
// a regression back to round 7's shape).
function checkSheetHasNoButtons(measured, ctx) {
  const failures = []
  for (const a of measured.actions) {
    if (!a.inSheetRows) continue
    if (a.anatomy !== "pk-admin-action--a4") {
      failures.push(`${label(ctx)} "${a.label}": ${a.anatomy} action inside .pk-admin-sheet__rows — a sheet's rows are a4 only (D-19e)`)
    }
  }
  if (measured.sheetHasCancelRow) {
    failures.push(`${label(ctx)} a sheet renders a "Cancelar" row — D-19e retired that shape; a sheet closes via its header ✕ only`)
  }
  return failures
}

// Label contrast >= 4.5:1 against the resolved background (guard rule 2).
function checkActionContrast(measured, ctx) {
  const failures = []
  for (const a of measured.actions) {
    if (a.disabled) continue
    if (a.contrast != null && a.contrast < 4.5) {
      failures.push(`${label(ctx)} "${a.label}": label contrast ${a.contrast.toFixed(2)}:1, expected >= 4.5:1`)
    }
  }
  return failures
}

// A8 — 44px hit-box floor on everything tappable, measured on the hit box
// (including any bleeding ::after), not the drawn box.
function check44pxFloor(measured, ctx) {
  const failures = []
  for (const t of measured.tappables) {
    if (t.hit < 43.5) {
      failures.push(`${label(ctx)} "${t.label}": ${t.hit.toFixed(1)}px tap target, under the 44px floor`)
    }
  }
  return failures
}

// D2 — one page-title type across the admin (22px/600, per screens.css).
// Collected across ALL pages/viewport/theme cases at the end of main(),
// since it is a cross-page consistency check, not a per-case one.
function collectTitleSignature(measured) {
  if (!measured.title) return null
  return `${measured.title.fontSize}/${measured.title.fontWeight} ${measured.title.fontFamily.split(",")[0]}`
}

const CHECKS = [
  checkAnatomyGeometry,
  checkAnatomyPadding,
  checkNaturalWidth,
  checkAtMostOneOutlinedPerBlock,
  checkNoOutlinedInRow,
  checkPeligroNeverOutlined,
  checkSheetHasNoButtons,
  checkActionContrast,
  check44pxFloor,
]

// ---------------------------------------------------------------------------
// K1 — 16px fields on a coarse (touch) pointer, so iOS never zooms on
// focus, plus the viewport meta's own zoom-lockout guard. A separate pass
// (not part of the per-page sweep above) because it needs
// `Emulation.setDeviceMetricsOverride`'s `mobile`/touch flags, which the
// desktop-pointer sweep above deliberately does not set.
// ---------------------------------------------------------------------------
async function runK1Check({ client, baseUrl }) {
  const failures = []
  await client.send("Emulation.setDeviceMetricsOverride", {
    width: 375,
    height: 667,
    deviceScaleFactor: 2,
    mobile: true,
  })
  await client.send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 5 })

  const allFields = []
  for (const page of PAGES) {
    await navigate(client, `${baseUrl}${page}`)
    await new Promise((r) => setTimeout(r, 200))
    const json = await evalJS(
      client,
      `
      JSON.stringify([...document.querySelectorAll('#invite-staff-email, .pk-admin-field__control')]
        .filter(el => el.offsetParent !== null)
        .map(el => ({ id: el.id || el.name || '(unnamed)', fontSize: parseFloat(getComputedStyle(el).fontSize) })))
    `,
    )
    for (const f of JSON.parse(json)) allFields.push({ page, ...f })

    const metaTag = await evalJS(
      client,
      `(() => { const m = document.querySelector('meta[name="viewport"]'); return m ? m.content : null; })()`,
    )
    if (metaTag && /maximum-scale|user-scalable\s*=\s*no/.test(metaTag)) {
      failures.push(`K1 ${page}: viewport meta locks out pinch-zoom (${metaTag}) — the iOS-zoom fix must never disable zoom entirely`)
    }
  }

  await client.send("Emulation.setTouchEmulationEnabled", { enabled: false })
  await client.send("Emulation.clearDeviceMetricsOverride", {})

  const small = allFields.filter((f) => f.fontSize < 16)
  if (small.length > 0) {
    failures.push(
      `K1 fields under 16px on a coarse pointer — iOS would zoom on focus: ${small.map((f) => `${f.page}/${f.id} ${f.fontSize}px`).join(", ")}`,
    )
  }
  if (allFields.length === 0) {
    log("K1: no fields found on any swept page — nothing to assert (extend PAGES if a new field ships).")
  } else {
    log(`K1: ${allFields.length} field(s) measured — ${JSON.stringify(allFields)}`)
  }

  return failures
}

// ---------------------------------------------------------------------------
// D-19o (press state) + the AdminSheet runtime gap (Esc, scrim tap,
// drag-down, focus trap, focus return) — driven against the REAL Staff
// screen's options sheet and its centred "Quitar del staff" dialog, the
// first (and, as of this plan, only) real call site for `sheet/1`/
// `dialog/1`. A throwaway staff account is invited through the REAL invite
// form (not injected via LiveView assigns) so every interaction below is a
// genuine user path, and removed again at the end via the REAL confirm
// flow so the dev DB is left exactly as this run found it.
//
// This file never drives a press assertion through CDP's touch-input
// dispatch API (D-19o) — the press-state assertion below uses a real
// `Input.dispatchMouseEvent` press/release pair, which DOES set `:active`
// in Chrome; confirming the SAME assertion is vacuous under a touch-based
// dispatch is left to a real tap on a real device
// (01.8.2-DEVICE-PASS.md item 1), per D-19o's own stated reason.
// ---------------------------------------------------------------------------
// Polls `fn` (an async predicate) every `intervalMs` until it returns a
// truthy value or `timeoutMs` elapses. Returns the truthy value, or `null`
// on timeout — callers decide whether a timeout is a failure. Used instead
// of a single fixed `setTimeout` wait for every LiveView round-trip below:
// a fixed wait is either too short (flaky) or wastes time being too long,
// and this repo's own dev server response time varies with what else is
// running on the machine.
async function pollUntil(fn, { timeoutMs = 4000, intervalMs = 150 } = {}) {
  const deadline = Date.now() + timeoutMs
  while (Date.now() < deadline) {
    const result = await fn()
    if (result) return result
    await new Promise((r) => setTimeout(r, intervalMs))
  }
  return null
}

// Removes any staff row whose email matches this file's own probe-account
// naming scheme, via the REAL "Quitar del staff" -> confirm dialog flow —
// self-healing cleanup for a probe account orphaned by an earlier run of
// this script that failed before reaching its own cleanup step (verified
// necessary: an earlier draft of this check left exactly this kind of
// orphan behind when a mid-flow assertion threw).
async function cleanupOrphanedProbeAccounts({ client, baseUrl, clickCenterOf, isOverlayOpen }) {
  await navigate(client, `${baseUrl}/admin/staff`)
  await new Promise((r) => setTimeout(r, 250))

  for (;;) {
    const orphanId = await evalJS(
      client,
      `
      JSON.stringify((() => {
        const rows = [...document.querySelectorAll('#staff-list [data-pk-pressable]')];
        const row = rows.find(r => /probe-visual-\\d+@pukllayclub\\.invalid/.test(r.textContent));
        return row ? row.id : null;
      })())
    `,
    )
    const id = JSON.parse(orphanId)
    if (!id) return

    log(`cleanup: found an orphaned probe staff row (#${id}) from an earlier run — removing it before this run starts`)
    await clickCenterOf(`#${id}`)
    await pollUntil(() => isOverlayOpen("staff-options-sheet"))
    await clickCenterOf('[phx-click="ask-remove"]')
    await pollUntil(() => isOverlayOpen("confirm-remove-dialog"))
    await clickCenterOf("#confirm-remove-dialog .pk-admin-action--peligro")
    const gone = await pollUntil(async () => !(await evalJS(client, `document.getElementById(${JSON.stringify(id)}) !== null`)))
    if (!gone) {
      log(`cleanup: could not remove orphaned probe row #${id} — stopping the orphan sweep so this run does not loop forever`)
      return
    }
  }
}

async function runInteractiveSheetChecks({ client, baseUrl }) {
  const failures = []
  const probeEmail = `probe-visual-${Date.now()}@pukllayclub.invalid`

  await client.send("Emulation.setDeviceMetricsOverride", { width: 390, height: 844, deviceScaleFactor: 1, mobile: false })

  // Real coordinate-based click at the target's own centre — but FIRST
  // confirms, via `elementFromPoint` (reading what is actually painted at
  // that point, guard rule 2), that the click would truly land on the
  // target. Found necessary while developing this check against the real
  // Staff screen: the sheet's own bottom row and the site-wide admin tab
  // bar share the identical `z-index: 70` (`components.css` line 509,
  // `chrome.css`'s own tab-bar rule) — since both are anchored flush to
  // the viewport's bottom edge (`position: fixed`/`bottom: 0`), a sheet's
  // last row can be ENTIRELY covered by the tab bar, at any viewport
  // height, making it untappable by a real user. This is exactly the
  // "reachability" failure mode 01.8.2-DEVICE-PASS.md's own checklist
  // (item 8) asks a real device to confirm — this automated check caught
  // it first, against the real DOM, before a human ever had to.
  //
  // On an obstruction, this function returns `{ obstructed: true, ... }`
  // instead of throwing, AND still delivers the click via a direct
  // `el.click()` JS call (bypassing hit-testing) so the REST of this
  // file's interaction chain — which is testing the sheet/dialog's own
  // WIRING, not tap reachability — can keep running and reporting. The
  // caller decides whether an obstruction on a given selector is itself a
  // reportable failure.
  async function clickCenterOf(selector) {
    const info = await evalJS(
      client,
      `
      JSON.stringify((() => {
        const el = document.querySelector(${JSON.stringify(selector)});
        if (!el) return { found: false };
        const r = el.getBoundingClientRect();
        const x = r.x + r.width / 2, y = r.y + r.height / 2;
        const hit = document.elementFromPoint(x, y);
        const reachable = !!hit && (hit === el || el.contains(hit));
        return {
          found: true,
          x, y,
          reachable,
          hitDescription: hit ? (hit.id ? '#' + hit.id : hit.className || hit.tagName) : '(nothing)',
        };
      })())
    `,
    )
    const point = JSON.parse(info)
    if (!point.found) throw new Error(`clickCenterOf: ${selector} not found`)

    if (point.reachable) {
      await client.send("Input.dispatchMouseEvent", { type: "mouseMoved", x: point.x, y: point.y })
      await client.send("Input.dispatchMouseEvent", { type: "mousePressed", x: point.x, y: point.y, button: "left", clickCount: 1 })
      await client.send("Input.dispatchMouseEvent", { type: "mouseReleased", x: point.x, y: point.y, button: "left", clickCount: 1 })
      return { obstructed: false }
    }

    log(`clickCenterOf: ${selector} is obstructed at its own centre point — a real tap there would hit ${point.hitDescription} instead. Falling back to a direct .click() so the rest of this run can still measure the sheet/dialog's own wiring.`)
    await evalJS(client, `document.querySelector(${JSON.stringify(selector)}).click(); true`)
    return { obstructed: true, hitDescription: point.hitDescription }
  }

  // NOT `offsetParent !== null` here — confirmed empirically while
  // developing this check: `offsetParent` is unconditionally `null` for a
  // `position: fixed` element in Chrome, REGARDLESS of visibility (spec
  // behaviour, not a bug in this app). `.pk-admin-overlay-root` (the
  // element `sheet/1`/`dialog/1` mount their id on) is `position: fixed`,
  // so `offsetParent !== null` on it is always `false` — a guard that
  // cannot pass is not a guard (measurement_discipline's own warning,
  // proven true against real markup here). Read the RESOLVED `display`
  // instead (guard rule 2: resolved style, not node existence) — this is
  // exactly what `pk-admin-overlay--open`'s class toggle controls
  // (`components.css` lines 506-515: `display: none` at rest, `display:
  // block` when open), so it correctly reflects the toggle regardless of
  // `position`. This SAME flaw is present in `admin_sheet.js`'s own
  // `isOpen = () => this.el.offsetParent !== null` — see this function's
  // callers below for what that means for Esc/drag-down/focus-trap.
  // The Staff screen mounts `sheet/1`/`dialog/1` behind `:if={@assign}` —
  // the element is entirely ABSENT from the DOM while closed, not merely
  // `display:none` — so "closed" also covers "not found", not just
  // "resolves display:none".
  async function isOverlayOpen(rootId) {
    return evalJS(
      client,
      `(() => { const el = document.getElementById(${JSON.stringify(rootId)}); return !!el && getComputedStyle(el).display !== 'none'; })()`,
    )
  }

  // Self-healing: remove any probe account left behind by an earlier failed
  // run before this run creates its own.
  await cleanupOrphanedProbeAccounts({ client, baseUrl, clickCenterOf, isOverlayOpen })

  await navigate(client, `${baseUrl}/admin/staff`)
  await new Promise((r) => setTimeout(r, 250))

  // ---- invite a throwaway staff account, for real ----
  await evalJS(
    client,
    `
    (() => {
      const input = document.getElementById('invite-staff-email');
      input.value = ${JSON.stringify(probeEmail)};
      input.dispatchEvent(new Event('input', { bubbles: true }));
      document.getElementById('invite-staff-form').requestSubmit();
      return true;
    })()
  `,
  )

  const rowId = await pollUntil(async () => {
    const json = await evalJS(
      client,
      `
      JSON.stringify((() => {
        const rows = [...document.querySelectorAll('#staff-list [data-pk-pressable]')];
        const row = rows.find(r => r.textContent.includes(${JSON.stringify(probeEmail)}));
        return row ? row.id : null;
      })())
    `,
    )
    return JSON.parse(json)
  })

  // The invite above puts up an "Invitación enviada." snackbar (D-19b) with
  // no action and therefore no dismiss control — and per the 01.8.2-08
  // SUMMARY's own recorded scope boundary, the runtime auto-dismiss timer
  // is NOT wired yet, so nothing on this page ever removes it on its own.
  // Confirmed empirically while developing this check: that snackbar sits
  // at `z-index: 80` (`components.css`), ABOVE the sheet's `z-index: 70`,
  // and can physically cover the sheet's own header controls — corrupting
  // an interaction check with an ARTIFACT OF THIS SCRIPT'S OWN SETUP
  // rather than a defect in the sheet itself. A full page navigation
  // starts a fresh LiveView mount with flash freshly read from the
  // session (empty here, since this was a `handle_event`, not a
  // redirect), giving every check below a clean slate.
  await navigate(client, `${baseUrl}/admin/staff`)
  await new Promise((r) => setTimeout(r, 250))
  if (!rowId) {
    failures.push("AdminSheet gap: could not find the newly-invited probe staff row within 4s — invite may have failed; skipping the interactive sheet/dialog checks entirely")
    return failures
  }
  const probeRowId = rowId

  // Everything from here on interacts with a real, now-existing staff
  // account. Wrapped in try/finally so a thrown assertion never leaves the
  // probe account behind — verified necessary: an earlier draft of this
  // check did exactly that on its first real run against this app.
  try {
    // ---- open the sheet for real ----
    await clickCenterOf(`#${probeRowId}`)
    const opened = await pollUntil(() => isOverlayOpen("staff-options-sheet"))
    if (!opened) {
      failures.push("AdminSheet gap: clicking the probe staff row did not open #staff-options-sheet within 4s")
      return failures
    }

    // ---- focus trap: open focuses the close control ----
    // Read BEFORE the D-19o press probe below, deliberately — found
    // necessary while developing this check: a native `mousedown` on a
    // focusable element moves focus to it as an intrinsic browser
    // behaviour, independent of any click completing. Reading
    // `document.activeElement` AFTER that probe would report the close
    // control as focused because THAT mousedown put it there, not because
    // `admin_sheet.js`'s own open-focus logic did — another case of one
    // check polluting the next one's evidence.
    const focusedOnOpen = await evalJS(client, `document.activeElement?.hasAttribute('data-pk-sheet-close')`)
    if (!focusedOnOpen) {
      failures.push("AdminSheet gap: opening the sheet did not move focus onto its close control (data-pk-sheet-close)")
    }

    // ---- D-19o: a real mouse press paints --color-surface-2 ----
    const closeCenter = await evalJS(
      client,
      `
      JSON.stringify((() => {
        const el = document.querySelector('[data-pk-sheet-close]');
        const r = el.getBoundingClientRect();
        return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
      })())
    `,
    )
    const cc = JSON.parse(closeCenter)
    const restBg = await evalJS(client, `getComputedStyle(document.querySelector('[data-pk-sheet-close]')).backgroundColor`)
    await client.send("Input.dispatchMouseEvent", { type: "mouseMoved", x: cc.x, y: cc.y })
    await client.send("Input.dispatchMouseEvent", { type: "mousePressed", x: cc.x, y: cc.y, button: "left", clickCount: 1 })
    await new Promise((r) => setTimeout(r, 50))
    const pressedBg = await evalJS(client, `getComputedStyle(document.querySelector('[data-pk-sheet-close]')).backgroundColor`)
    const surface2 = await evalJS(client, `getComputedStyle(document.documentElement).getPropertyValue('--color-surface-2').trim()`)
    // Release OUTSIDE the button, not on it — a mousedown+mouseup on the
    // SAME element fires a real `click` event, which would close the
    // sheet right here via its own `phx-click`. Found necessary while
    // developing this check: an earlier draft released on the button and
    // the resulting real click closed the sheet a full test early,
    // silently making the LATER "Escape closes it" assertion pass for the
    // wrong reason (the sheet was already closed from THIS click, not
    // from Escape) — exactly the "guard that passes for the wrong reason"
    // trap this repo's own measurement discipline warns about.
    await client.send("Input.dispatchMouseEvent", { type: "mouseMoved", x: cc.x + 200, y: cc.y })
    await client.send("Input.dispatchMouseEvent", { type: "mouseReleased", x: cc.x + 200, y: cc.y, button: "left", clickCount: 1 })
    const stillOpenAfterPress = await isOverlayOpen("staff-options-sheet")
    if (!stillOpenAfterPress) {
      failures.push("D-19o test harness check: the sheet closed during the press-state probe itself (should be impossible — release was dispatched away from the close control) — the D-19o result above may be unreliable")
    }
    if (pressedBg === restBg) {
      failures.push(`D-19o: a real mouse press on [data-pk-sheet-close] did not change its background (rest ${restBg}, pressed ${pressedBg}) — :active fill did not paint`)
    }
    log(`D-19o: sheet close control rest=${restBg} pressed=${pressedBg} --color-surface-2 resolves to a colour reference "${surface2}"`)

    // ---- Esc closes it ----
    await client.send("Input.dispatchKeyEvent", { type: "keyDown", key: "Escape", code: "Escape" })
    await client.send("Input.dispatchKeyEvent", { type: "keyUp", key: "Escape", code: "Escape" })
    const closedByEsc = await pollUntil(async () => !(await isOverlayOpen("staff-options-sheet")))
    if (!closedByEsc) {
      failures.push("AdminSheet gap: Escape did not close the open sheet within 4s")
    }

    // ---- focus return: closing restores focus to the row that opened it ----
    const focusedAfterClose = await evalJS(client, `document.activeElement?.id`)
    if (focusedAfterClose !== probeRowId) {
      failures.push(`AdminSheet gap: closing the sheet did not return focus to the invoking row (expected #${probeRowId}, got #${focusedAfterClose || "(none)"})`)
    }

    // ---- reopen, close via scrim tap ----
    await clickCenterOf(`#${probeRowId}`)
    await pollUntil(() => isOverlayOpen("staff-options-sheet"))
    const scrimPoint = await evalJS(
      client,
      `
      JSON.stringify((() => {
        const scrim = document.querySelector('#staff-options-sheet [data-pk-sheet-scrim]');
        const r = scrim.getBoundingClientRect();
        // top-left corner of the scrim, away from the sheet panel docked at
        // the bottom — guaranteed to be scrim, not panel.
        return { x: r.x + 20, y: r.y + 20 };
      })())
    `,
    )
    const sp = JSON.parse(scrimPoint)
    await client.send("Input.dispatchMouseEvent", { type: "mouseMoved", x: sp.x, y: sp.y })
    await client.send("Input.dispatchMouseEvent", { type: "mousePressed", x: sp.x, y: sp.y, button: "left", clickCount: 1 })
    await client.send("Input.dispatchMouseEvent", { type: "mouseReleased", x: sp.x, y: sp.y, button: "left", clickCount: 1 })
    const closedByScrim = await pollUntil(async () => !(await isOverlayOpen("staff-options-sheet")))
    if (!closedByScrim) {
      failures.push("AdminSheet gap: a scrim tap did not close the open sheet within 4s")
    }

    // ---- reopen, close via drag-down on the grabber ----
    await clickCenterOf(`#${probeRowId}`)
    await pollUntil(() => isOverlayOpen("staff-options-sheet"))
    const dragStart = await evalJS(
      client,
      `
      JSON.stringify((() => {
        const grabber = document.querySelector('#staff-options-sheet [data-pk-sheet-grabber]');
        const panel = document.querySelector('#staff-options-sheet [data-pk-sheet-panel]');
        const gr = grabber.getBoundingClientRect();
        const pr = panel.getBoundingClientRect();
        return { x: gr.x + gr.width / 2, y: gr.y + gr.height / 2, panelHeight: pr.height };
      })())
    `,
    )
    const ds = JSON.parse(dragStart)
    const dragDistance = ds.panelHeight * 0.4 // safely past the 25% close threshold
    await client.send("Input.dispatchMouseEvent", { type: "mouseMoved", x: ds.x, y: ds.y })
    await client.send("Input.dispatchMouseEvent", { type: "mousePressed", x: ds.x, y: ds.y, button: "left", clickCount: 1 })
    const steps = 6
    for (let i = 1; i <= steps; i++) {
      await client.send("Input.dispatchMouseEvent", {
        type: "mouseMoved",
        x: ds.x,
        y: ds.y + (dragDistance * i) / steps,
        button: "left",
      })
      await new Promise((r) => setTimeout(r, 16))
    }
    await client.send("Input.dispatchMouseEvent", { type: "mouseReleased", x: ds.x, y: ds.y + dragDistance, button: "left", clickCount: 1 })
    const closedByDrag = await pollUntil(async () => !(await isOverlayOpen("staff-options-sheet")))
    if (!closedByDrag) {
      failures.push(`AdminSheet gap: dragging the grabber down ${dragDistance.toFixed(0)}px (>25% of the panel's ${ds.panelHeight.toFixed(0)}px height) did not close the sheet within 4s`)
    }

    // ---- reopen, open the destructive dialog for real ----
    await clickCenterOf(`#${probeRowId}`)
    await pollUntil(() => isOverlayOpen("staff-options-sheet"))
    const askRemoveClick = await clickCenterOf('[phx-click="ask-remove"]')
    if (askRemoveClick.obstructed) {
      failures.push(
        `Z-INDEX REACHABILITY (severity: high): "Quitar del staff" is NOT reachable by a real tap — a tap at its own centre point lands on ${askRemoveClick.hitDescription} instead. The sheet's last row is flush with the viewport's bottom edge (\`.pk-admin-sheet\`'s \`bottom: 0\`), and the admin tab bar is ALSO fixed to the viewport's bottom edge with the SAME z-index (both \`z-index: 70\` — components.css/chrome.css) — the tab bar paints over the sheet's bottom row at every viewport height, not just this one. This affects every current and future single-row (or short) sheet's bottom-most row(s). Measured via a real coordinate click + elementFromPoint, not source text.`,
      )
    }
    const dialogOpened = await pollUntil(() => isOverlayOpen("confirm-remove-dialog"))
    if (!dialogOpened) {
      failures.push('AdminSheet gap: clicking "Quitar del staff" did not open #confirm-remove-dialog within 4s')
    } else {
      const dialogFocused = await evalJS(client, `document.activeElement?.hasAttribute('data-pk-dialog-cancel')`)
      if (!dialogFocused) {
        failures.push("D-19f: opening the dialog did not move focus onto Cancelar (data-pk-dialog-cancel) — D-19f requires Cancelar to carry initial focus")
      }

      // Esc cancels the dialog too.
      await client.send("Input.dispatchKeyEvent", { type: "keyDown", key: "Escape", code: "Escape" })
      await client.send("Input.dispatchKeyEvent", { type: "keyUp", key: "Escape", code: "Escape" })
      const dialogClosedByEsc = await pollUntil(async () => !(await isOverlayOpen("confirm-remove-dialog")))
      if (!dialogClosedByEsc) {
        failures.push("AdminSheet gap: Escape did not close the open dialog within 4s")
      }
    }
  } finally {
    // ---- cleanup: remove the probe staff account for real, via the real
    // confirm flow, so this run leaves the dev DB exactly as it found it —
    // runs whether the checks above passed, failed, or threw. ----
    const rowStillThere = await evalJS(client, `document.getElementById(${JSON.stringify(probeRowId)}) !== null`)
    if (rowStillThere) {
      try {
        await clickCenterOf(`#${probeRowId}`)
        await pollUntil(() => isOverlayOpen("staff-options-sheet"))
        await clickCenterOf('[phx-click="ask-remove"]')
        await pollUntil(() => isOverlayOpen("confirm-remove-dialog"))
        await clickCenterOf("#confirm-remove-dialog .pk-admin-action--peligro")
        const gone = await pollUntil(
          async () => !(await evalJS(client, `document.getElementById(${JSON.stringify(probeRowId)}) !== null`)),
        )
        if (!gone) {
          failures.push(`cleanup: probe staff account ${probeEmail} could not be confirmed removed within 4s — check the dev DB manually`)
        } else {
          log(`cleanup: probe staff account ${probeEmail} invited and removed cleanly via the real UI flow`)
        }
      } catch (err) {
        failures.push(`cleanup: removing the probe staff account ${probeEmail} threw: ${err.message} — check the dev DB manually`)
      }
    }
  }

  return failures
}

// ---------------------------------------------------------------------------
// Plan 01.8.2-17: the game editor, swept separately from `PAGES` (see that
// array's own comment on why). Resolves a real published game's editor URL
// off the live /admin/juegos list — never a hardcoded id.
// ---------------------------------------------------------------------------
async function resolveEditorUrl(client, baseUrl) {
  await navigate(client, `${baseUrl}/admin/juegos`)
  const href = await evalJS(
    client,
    `
    (() => {
      const a = document.querySelector('a[href^="/admin/juegos/"][href$="/editar"]');
      return a ? a.getAttribute('href') : null;
    })()
  `,
  )
  return href
}

async function runEditorPageChecks({ client, baseUrl }) {
  const failures = []
  let cases = 0

  const editorUrl = await resolveEditorUrl(client, baseUrl)
  if (!editorUrl) {
    failures.push("editor sweep: could not resolve a real game editor URL off /admin/juegos — is the dev catalog empty?")
    return { failures, cases }
  }
  log(`editor sweep: resolved ${editorUrl}`)

  for (const viewport of VIEWPORTS) {
    for (const theme of THEMES) {
      const ctx = { page: editorUrl, viewport, theme }
      try {
        const measured = await runPageCase({ client, baseUrl, page: editorUrl, viewport, theme })
        cases++
        log(`${label(ctx)} actions=${measured.actions.length} fields=${measured.fields.length} tappables=${measured.tappables.length}`)
        for (const check of CHECKS) {
          for (const f of check(measured, ctx)) failures.push(f)
        }
      } catch (err) {
        failures.push(`${label(ctx)} FAIL: ${err.message}`)
      }
    }
  }

  return { failures, cases }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  const { baseUrl, proc: serverProc } = await startDevServer()
  const chrome = await startChrome()

  let exitCode = 0
  let casesRun = 0
  let editorCasesRun = 0
  const titleSignatures = []
  const backTops = []
  const headToBodyGaps = []
  const titleTopsByBackPresence = { true: [], false: [] }

  try {
    const ws = await (async () => {
      const res = await fetch(`http://127.0.0.1:${chrome.port}/json/new?about:blank`, { method: "PUT" })
      return res.json()
    })()
    const client = new CDPClient(new WebSocket(ws.webSocketDebuggerUrl))
    await new Promise((resolve, reject) => {
      client.ws.addEventListener("open", resolve, { once: true })
      client.ws.addEventListener("error", reject, { once: true })
    })
    await client.send("Page.enable")
    await client.send("Runtime.enable")

    log(`Logging in as staff (${STAFF_EMAIL})...`)
    await loginAsStaff(client, baseUrl)
    log("Login confirmed (admin tab bar present).")

    for (const page of PAGES) {
      for (const viewport of VIEWPORTS) {
        for (const theme of THEMES) {
          const ctx = { page, viewport, theme }
          try {
            const measured = await runPageCase({ client, baseUrl, page, viewport, theme })
            casesRun++

            log(`${label(ctx)} actions=${measured.actions.length} fields=${measured.fields.length} tappables=${measured.tappables.length}`)

            for (const check of CHECKS) {
              const failures = check(measured, ctx)
              for (const f of failures) {
                log(`FAIL: ${f}`)
                exitCode = 1
              }
            }

            const sig = collectTitleSignature(measured)
            if (sig) titleSignatures.push({ page, sig })
            if (measured.back) backTops.push({ page, top: measured.back.top })
            if (measured.headToBody != null) headToBodyGaps.push({ page, gap: measured.headToBody })
            if (measured.title) {
              const hasBack = !!measured.back
              titleTopsByBackPresence[String(hasBack)].push({ page, top: measured.title.top })
            }
          } catch (err) {
            log(`${label(ctx)} FAIL: ${err.message}`)
            exitCode = 1
          }
        }
      }
    }

    // D2 — one page-title type across the admin.
    const distinctSigs = [...new Set(titleSignatures.map((s) => s.sig))]
    if (distinctSigs.length > 1) {
      log(`FAIL: D2 more than one page-title type across the admin: ${JSON.stringify(titleSignatures)}`)
      exitCode = 1
    } else if (distinctSigs.length === 1) {
      log(`D2: one page-title type across ${titleSignatures.length} sample(s): ${distinctSigs[0]}`)
    }

    // D1 — every drill-down's back row starts at the same height.
    const distinctBackTops = [...new Set(backTops.map((b) => b.top))]
    if (distinctBackTops.length > 1) {
      log(`FAIL: D1 back rows do not start at the same height: ${JSON.stringify(backTops)}`)
      exitCode = 1
    } else if (backTops.length >= 1) {
      log(`D1: back row top=${distinctBackTops[0]}px across ${backTops.length} sample(s) (single-screen sample until a second drill-down ships)`)
    }

    // D3 — the page head ends the same distance above the body, everywhere.
    const distinctGaps = [...new Set(headToBodyGaps.map((g) => g.gap))]
    if (distinctGaps.length > 1) {
      log(`FAIL: D3 the page head does not end the same distance above the body on every page: ${JSON.stringify(headToBodyGaps)}`)
      exitCode = 1
    } else if (headToBodyGaps.length >= 1) {
      log(`D3: page-head-to-body gap=${distinctGaps[0]}px across ${headToBodyGaps.length} sample(s)`)
    }
    for (const withBack of ["true", "false"]) {
      const grp = titleTopsByBackPresence[withBack]
      if (grp.length < 1) continue
      const distinctTops = [...new Set(grp.map((g) => g.top))]
      if (distinctTops.length > 1) {
        log(`FAIL: D3 page titles do not start at the same height (withBack=${withBack}): ${JSON.stringify(grp)}`)
        exitCode = 1
      } else {
        log(`D3: title top=${distinctTops[0]}px (withBack=${withBack}) across ${grp.length} sample(s)`)
      }
    }

    // K1
    log("Running K1 (16px fields on a coarse pointer)...")
    for (const f of await runK1Check({ client, baseUrl })) {
      log(`FAIL: ${f}`)
      exitCode = 1
    }
    casesRun++

    // D-19o + the AdminSheet runtime gap, against the real Staff screen.
    log("Running the interactive sheet/dialog checks (D-19o + the admin_sheet.js runtime gap)...")
    for (const f of await runInteractiveSheetChecks({ client, baseUrl })) {
      log(`FAIL: ${f}`)
      exitCode = 1
    }
    casesRun++

    // Plan 01.8.2-17: the game editor, swept separately from PAGES (see
    // that array's own comment on why) through the same anatomy/padding/
    // 44px-floor/contrast/no-daisy-button CHECKS every other page runs.
    log("Running the anatomy/44px-floor/contrast sweep against the game editor...")
    const editorResult = await runEditorPageChecks({ client, baseUrl })
    for (const f of editorResult.failures) {
      log(`FAIL: ${f}`)
      exitCode = 1
    }
    editorCasesRun = editorResult.cases
  } finally {
    await stopChrome(chrome)
    await stopDevServer(serverProc)
  }

  const expectedCases = PAGES.length * VIEWPORTS.length * THEMES.length + 2 + VIEWPORTS.length * THEMES.length // +K1, +interactive, +editor
  casesRun += editorCasesRun
  if (casesRun !== expectedCases) {
    log(`FAIL: expected ${expectedCases} case blocks, only ${casesRun} completed far enough to be reported.`)
    exitCode = 1
  }

  console.log(exitCode === 0 ? "\nadmin_components.mjs: ALL CHECKS PASSED" : "\nadmin_components.mjs: FAILURES ABOVE")
  process.exit(exitCode)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
