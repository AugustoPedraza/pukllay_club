#!/usr/bin/env node
// D-18/D-28/D-19n's harness: the admin SHELL'S own measured geometry — the
// chrome every screen sits inside, not the screens themselves (that is
// `admin_components.mjs`, this same plan's Task 1; reuses its CDP/login
// plumbing shape, not its module — this file's own copy, following this
// directory's established convention of self-contained probes). Plan
// 01.8.2-12 Task 2.
//
// Measures, against the real /admin and /admin/staff in real headless
// Chrome over a real staff session:
//   - the tab bar (D-13b): its height, the 56x30 active-pill indicator,
//     and that the snackbar's bottom offset derives from the tab bar's
//     REAL rendered height, not a second literal
//   - the pinned page bar (D-19n): at rest, zero layout cost (a set of
//     content anchors, unchanged whether the bar is present)
//   - the fixed foot save bar (D-28) and sketch 080's four negative
//     checks, against plan 01.8.2-17's game editor — the first live
//     `save_bar/1` call site (`resolveEditorUrl`/`measureSaveBarLive`)
//   - the keel (open item 4): the admin shell's real content edges at 375
//     and 360, so the CONTEXT.md-flagged 16-vs-14 decision is recorded
//     against a measurement, not a preference
//
// Guard-writing rules: see `admin_components.mjs`'s own header comment for
// the full seven-rule list this whole directory follows — not restated
// here to avoid two copies drifting apart. This file's own additions to
// that record:
//   - rule 6 ("measure the fold against the pinned overlay's TOP, not the
//     scroller's rect") is exercised directly by `checkPageBarZeroLayout`
//     below — the page bar is `position: absolute`, so its own top is
//     always `0` relative to its positioning context; what must be
//     measured is whether OTHER elements' rects move when the bar's
//     `visible` state flips, not the bar's own position.
//   - `offsetParent` is unconditionally `null` for a `position: fixed`
//     element in Chrome (confirmed empirically in `admin_components.mjs`)
//     — this file never uses it either; visibility reads go through
//     resolved `display`/rect presence instead.
//
// Developer-invoked only — not wired into `mix quality` or CI. See
// `test/visual/README.md`.
//
// Usage: node test/visual/admin_shell.mjs
// Env:   PROBE_BASE_URL=http://localhost:4000  (skip booting a dev server)

import { spawn } from "node:child_process"
import { mkdtemp, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

const PROBE_BASE_URL = process.env.PROBE_BASE_URL
const STAFF_EMAIL = process.env.STAFF_EMAIL || "augusto.pedraza08@gmail.com"

// D-19n's own two named widths, plus 390 for parity with
// `admin_components.mjs`'s own trio.
const KEEL_VIEWPORTS = [375, 360, 390]
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

function log(...args) {
  console.log(...args)
}

// ---------------------------------------------------------------------------
// Dev server + Chrome lifecycle + minimal CDP client — byte-identical
// shape to `admin_components.mjs` (this directory's established pattern;
// see that file for the fuller comments on each piece).
// ---------------------------------------------------------------------------
async function startDevServer() {
  if (PROBE_BASE_URL) {
    log(`Using existing server at ${PROBE_BASE_URL} (PROBE_BASE_URL set) — starting nothing.`)
    return { baseUrl: PROBE_BASE_URL, proc: null }
  }
  const baseUrl = "http://localhost:4000"
  log("Booting `mix phx.server`...")
  let stderrBuf = ""
  const proc = spawn("mix", ["phx.server"], { env: { ...process.env, MIX_ENV: "dev" }, stdio: ["ignore", "pipe", "pipe"] })
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

function findChromeBinary() {
  return ["google-chrome-stable", "google-chrome", "chromium", "chromium-browser"]
}

async function startChrome() {
  const userDataDir = await mkdtemp(join(tmpdir(), "admin-shell-chrome-"))
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
  await client.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile: false })
}

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
      input.closest('form').requestSubmit();
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
  await navigate(client, magicLinks[magicLinks.length - 1])
  await new Promise((r) => setTimeout(r, 400))
  await evalJS(client, `(() => { const btn = document.querySelector('button[type="submit"], form button'); if (btn) btn.click(); return !!btn; })()`)
  await new Promise((r) => setTimeout(r, 1200))
  const confirmed = await evalJS(client, `document.body ? document.body.innerHTML.includes('pk-admin-tab-bar') : false`)
  if (!confirmed) throw new Error("login: post-login page does not render the admin tab bar — login did not complete")
}

// ---------------------------------------------------------------------------
// The tab bar (D-13b) — height, indicator, and the snackbar derivation.
// ---------------------------------------------------------------------------
async function measureTabBar({ client, baseUrl, width }) {
  await setViewport(client, width, 844)
  await navigate(client, `${baseUrl}/admin`)
  await new Promise((r) => setTimeout(r, 250))

  const json = await evalJS(
    client,
    `
    JSON.stringify((() => {
      const bar = document.querySelector('.pk-admin-tab-bar');
      const activeIcon = document.querySelector('.pk-admin-tab.is-active .pk-admin-tab-icon');
      const tabBarHVar = getComputedStyle(document.documentElement).getPropertyValue('--pk-tab-bar-h').trim();
      return {
        barRect: bar ? (() => { const r = bar.getBoundingClientRect(); return { height: r.height, bottom: r.bottom, top: r.top }; })() : null,
        indicatorRect: activeIcon ? (() => { const r = activeIcon.getBoundingClientRect(); return { width: r.width, height: r.height }; })() : null,
        tabBarHVar,
      };
    })())
  `,
  )
  return JSON.parse(json)
}

// The snackbar's bottom offset must derive from the tab bar's REAL
// rendered height — measured via a REAL flash (inviting a throwaway staff
// account puts up a real "Invitación enviada." snackbar, D-19b), not
// assumed from the `--pk-tab-bar-h` custom property alone (the property
// could resolve correctly while the RENDERED bar height still drifted
// from it via padding/border rounding — this measures the actually
// painted relationship between the two real elements).
async function measureSnackbarDerivesFromTabBar({ client, baseUrl }) {
  await setViewport(client, 390, 844)
  await navigate(client, `${baseUrl}/admin/staff`)
  await new Promise((r) => setTimeout(r, 250))

  const probeEmail = `probe-shell-${Date.now()}@pukllayclub.invalid`
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

  const measured = await pollUntil(async () => {
    const json = await evalJS(
      client,
      `
      JSON.stringify((() => {
        const snack = document.querySelector('.pk-admin-snackbar');
        const bar = document.querySelector('.pk-admin-tab-bar');
        if (!snack || !bar) return null;
        const sr = snack.getBoundingClientRect(), br = bar.getBoundingClientRect();
        return { snackBottom: sr.bottom, snackTop: sr.top, barTop: br.top };
      })())
    `,
    )
    return JSON.parse(json)
  })

  // cleanup: remove the probe staff account regardless of what was measured.
  const rowId = JSON.parse(
    await evalJS(
      client,
      `
      JSON.stringify((() => {
        const rows = [...document.querySelectorAll('#staff-list [data-pk-pressable]')];
        const row = rows.find(r => r.textContent.includes(${JSON.stringify(probeEmail)}));
        return row ? row.id : null;
      })())
    `,
    ),
  )
  if (rowId) {
    // A fresh navigation both clears the snackbar (no auto-dismiss is
    // wired yet — see `admin_components.mjs`'s own note on this) and
    // avoids this cleanup click landing on the tab-bar/sheet z-index
    // collision `admin_components.mjs` found — the row itself, above the
    // sheet, is unaffected by that collision.
    await navigate(client, `${baseUrl}/admin/staff`)
    await new Promise((r) => setTimeout(r, 250))
    await evalJS(client, `document.getElementById(${JSON.stringify(rowId)})?.click()`)
    await new Promise((r) => setTimeout(r, 250))
    await evalJS(client, `document.querySelector('[phx-click="ask-remove"]')?.click()`)
    await new Promise((r) => setTimeout(r, 250))
    await evalJS(client, `document.querySelector('#confirm-remove-dialog .pk-admin-action--peligro')?.click()`)
    await new Promise((r) => setTimeout(r, 500))
    const gone = await pollUntil(async () => !(await evalJS(client, `document.getElementById(${JSON.stringify(rowId)}) !== null`)))
    log(gone ? `cleanup: probe staff account ${probeEmail} removed cleanly` : `cleanup: could not confirm removal of ${probeEmail} — check the dev DB manually`)
  }

  return measured
}

async function pollUntil(fn, { timeoutMs = 4000, intervalMs = 150 } = {}) {
  const deadline = Date.now() + timeoutMs
  while (Date.now() < deadline) {
    const result = await fn()
    if (result) return result
    await new Promise((r) => setTimeout(r, intervalMs))
  }
  return null
}

// ---------------------------------------------------------------------------
// The pinned page bar (D-19n) — at rest, zero layout cost. No live call
// site renders `page_bar/1` visible+scrolled yet (both shipped screens are
// short enough that the bar's `visible` toggle never flips in the current
// app), so this measures the ONE thing that IS live today regardless: the
// bar is `position: absolute` (`components.css`), so its presence in the
// DOM can never move ANY sibling content — confirmed by comparing a set of
// real content anchors' rects with and against the bar's own rect
// overlapping them (an absolutely-positioned element never participates
// in layout, by construction — this check confirms that construction
// holds against the real compiled CSS, not just asserts it from memory).
// ---------------------------------------------------------------------------
// Generalised by plan 01.8.2-14 (page/bodyAnchorSelector params, defaulted
// to the original `/admin`/`#admin-cards` call so the existing behaviour
// is byte-identical) — Juegos is this component's first call site whose
// own title→body rhythm is worth recording independently of the
// dashboard's grid.
async function checkPageBarZeroLayout({ client, baseUrl, page = "/admin", bodyAnchorSelector = "#admin-cards" }) {
  await setViewport(client, 375, 844)
  await navigate(client, `${baseUrl}${page}`)
  await new Promise((r) => setTimeout(r, 250))

  const json = await evalJS(
    client,
    `
    JSON.stringify((() => {
      const bar = document.querySelector('.pk-admin-page-bar');
      if (!bar) return { found: false };
      const cs = getComputedStyle(bar);
      const title = document.querySelector('.pk-admin-page-title');
      const grid = document.querySelector(${JSON.stringify(bodyAnchorSelector)});
      const backRow = document.querySelector('.pk-admin-back-row');
      return {
        found: true,
        position: cs.position,
        titleTop: title ? title.getBoundingClientRect().top : null,
        gridTop: grid ? grid.getBoundingClientRect().top : null,
        backRowTop: backRow ? backRow.getBoundingClientRect().top : null,
      };
    })())
  `,
  )
  return JSON.parse(json)
}

// ---------------------------------------------------------------------------
// The fixed foot save bar (D-28): resolves whether a live `[data-pk-save-
// bar]` instance now exists (it does, as of plan 01.8.2-17's editor) and
// reports the `--pk-save-bar-h` custom property. The real geometry + sketch
// 080 negative-check measurement against that live instance lives in
// `measureSaveBarLive`/`resolveEditorUrl` below, run from `main()` only
// when a live instance is confirmed present here.
// ---------------------------------------------------------------------------
async function checkSaveBarDeferred({ client, baseUrl }) {
  await navigate(client, `${baseUrl}/admin`)
  const saveBarH = await evalJS(client, `getComputedStyle(document.documentElement).getPropertyValue('--pk-save-bar-h').trim()`)
  const liveInstance = await evalJS(client, `document.querySelector('[data-pk-save-bar]') !== null`)
  return { saveBarHVar: saveBarH, liveInstance }
}

// ---------------------------------------------------------------------------
// Plan 01.8.2-17: the FIRST live `save_bar/1` call site (the game editor).
// Resolves a real published game's editor URL off the live /admin/juegos
// list (never a hardcoded id — the dev catalog's row ordering/ids are not
// this script's business), then measures the bar's real geometry, the
// button's A1 shape, and the body's own real clearance/last-block edge —
// this is what the deferred block above (`checkSaveBarDeferred`) itself
// says to do "now that a call site exists".
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

async function measureSaveBarLive({ client, baseUrl, editorUrl, width }) {
  await setViewport(client, width, 844)
  await navigate(client, `${baseUrl}${editorUrl}`)
  await new Promise((r) => setTimeout(r, 200))
  // Scroll to the real bottom of the document FIRST — `.pk-editor-body`'s
  // last block sits well past one screenful of content (pills, cover,
  // title, description, five BGG facts, three editable rows), so its
  // un-scrolled `getBoundingClientRect()` is naturally below the 844px
  // viewport even when the page works correctly. A `position: fixed` bar's
  // own top is always viewport-relative regardless of scroll — comparing
  // it against an un-scrolled body rect would silently always "pass"
  // (D-28's own named failure mode requires measuring at the real scrolled
  // position, exactly as `admin-game-editor.md`'s own reference script
  // does: `document.querySelector('#scroller').scrollTop = 700`).
  await evalJS(client, `window.scrollTo(0, document.body.scrollHeight)`)
  await new Promise((r) => setTimeout(r, 100))
  const json = await evalJS(
    client,
    `
    JSON.stringify((() => {
      const bar = document.querySelector('[data-pk-save-bar]');
      const btn = bar ? bar.querySelector('.pk-admin-save-bar__action') : null;
      if (!bar || !btn) return null;
      const br = bar.getBoundingClientRect();
      const bbr = btn.getBoundingClientRect();
      const barCs = getComputedStyle(bar);
      const btnCs = getComputedStyle(btn);
      const rg = document.createRange();
      rg.selectNodeContents(btn);
      const ink = rg.getBoundingClientRect().width;
      const bodyEls = [...document.querySelectorAll('.pk-editor-body > *')];
      const lastBlock = bodyEls[bodyEls.length - 1];
      const lastRect = lastBlock ? lastBlock.getBoundingClientRect() : null;
      // A bare, unstyled swatch element carries no rule of its own other
      // than the UA default (transparent) plus whatever inherits — so its
      // resolved backgroundColor is NOT useful; instead read
      // '--color-base-100' directly off :root and let the BROWSER resolve
      // it into the same rgb()/oklch() form backgroundColor already uses,
      // via a throwaway element's inline style (guarantees an apples-to-
      // apples comparison against barCs/btnCs regardless of the token's
      // declared colour space).
      const swatch = document.createElement('div');
      swatch.style.cssText = 'background-color: var(--color-base-100); position: fixed; visibility: hidden;';
      document.body.appendChild(swatch);
      const pageBg = getComputedStyle(swatch).backgroundColor;
      swatch.remove();
      return {
        barH: Math.round(br.height * 10) / 10,
        barBg: barCs.backgroundColor,
        barBt: barCs.borderTopWidth,
        pageBg,
        btnW: Math.round(bbr.width * 10) / 10,
        btnH: Math.round(bbr.height * 10) / 10,
        btnFill: btnCs.backgroundColor,
        btnPadL: btnCs.paddingLeft,
        btnBw: btnCs.borderTopWidth,
        btnRadius: btnCs.borderRadius,
        btnFont: btnCs.fontSize + '/' + btnCs.fontWeight,
        btnRight: Math.round((br.right - bbr.right) * 10) / 10,
        ink: Math.round(ink * 10) / 10,
        lastBlockBottom: lastRect ? Math.round(lastRect.bottom * 10) / 10 : null,
        barTop: Math.round(br.top * 10) / 10,
      };
    })())
  `,
  )
  return JSON.parse(json)
}

// ---------------------------------------------------------------------------
// The keel (open item 4) — the shell's real content edges. Measured on
// each page's own `.mx-auto.w-full.max-w-3xl` content wrapper (the D-18
// shared shape both live screens render), at each of D-19n's/079's named
// widths.
// ---------------------------------------------------------------------------
async function measureKeel({ client, baseUrl, width }) {
  await setViewport(client, width, 844)
  const results = {}
  for (const page of PAGES) {
    await navigate(client, `${baseUrl}${page}`)
    await new Promise((r) => setTimeout(r, 200))
    const json = await evalJS(
      client,
      `
      JSON.stringify((() => {
        const wrap = document.querySelector('main .mx-auto.w-full.max-w-3xl');
        if (!wrap) return null;
        const r = wrap.getBoundingClientRect();
        return { left: Math.round(r.left * 10) / 10, right: Math.round((window.innerWidth - r.right) * 10) / 10 };
      })())
    `,
    )
    results[page] = JSON.parse(json)
  }
  return results
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  const { baseUrl, proc: serverProc } = await startDevServer()
  const chrome = await startChrome()
  let exitCode = 0

  try {
    const client = await connectCDP(chrome.port)
    log(`Logging in as staff (${STAFF_EMAIL})...`)
    await loginAsStaff(client, baseUrl)
    log("Login confirmed (admin tab bar present).")

    // ---- tab bar ----
    const tabBarByWidth = {}
    for (const width of [375, 360]) {
      const m = await measureTabBar({ client, baseUrl, width })
      tabBarByWidth[width] = m
      log(`tab bar @ ${width}px: height=${m.barRect?.height}px --pk-tab-bar-h=${m.tabBarHVar} indicator=${m.indicatorRect ? `${m.indicatorRect.width}x${m.indicatorRect.height}` : "(not found)"}`)

      if (!m.barRect) {
        log(`FAIL: tab bar not found at ${width}px`)
        exitCode = 1
        continue
      }
      const heightVarPx = parseFloat(m.tabBarHVar)
      if (Math.abs(m.barRect.height - heightVarPx) > 1) {
        log(`FAIL: tab bar @ ${width}px: rendered height ${m.barRect.height}px does not match --pk-tab-bar-h (${m.tabBarHVar})`)
        exitCode = 1
      }
      // Derivation-only (above) is not enough on its own — it would still
      // report "consistent" even if BOTH the rendered bar and the custom
      // property drifted together to a wrong value (confirmed by
      // negative-testing this check while developing it: bumping
      // `--pk-tab-bar-h` to 90px left the derivation check green, because
      // the bar correctly followed the property to the new, WRONG value).
      // BENCHMARK's own literal — 67px, taken verbatim (chrome.css's own
      // header comment) — is the second, independent assertion that
      // actually catches that class of drift.
      if (Math.round(m.barRect.height) !== 67) {
        log(`FAIL: tab bar @ ${width}px: rendered height ${m.barRect.height}px, expected BENCHMARK's measured 67px`)
        exitCode = 1
      }
      if (!m.indicatorRect || Math.round(m.indicatorRect.width) !== 56 || Math.round(m.indicatorRect.height) !== 30) {
        log(`FAIL: tab bar @ ${width}px: active indicator is ${m.indicatorRect ? `${m.indicatorRect.width}x${m.indicatorRect.height}` : "missing"}, expected 56x30`)
        exitCode = 1
      }
    }

    // ---- snackbar derives from the tab bar's real height ----
    log("Measuring the snackbar's offset against the tab bar (inviting a throwaway staff account for a real flash)...")
    const snackMeasure = await measureSnackbarDerivesFromTabBar({ client, baseUrl })
    if (!snackMeasure) {
      log("FAIL: could not measure a real snackbar within 4s of inviting a probe staff account")
      exitCode = 1
    } else {
      const clearance = snackMeasure.barTop - snackMeasure.snackBottom
      log(`snackbar: bottom=${snackMeasure.snackBottom}px, tab bar top=${snackMeasure.barTop}px, clearance=${clearance.toFixed(1)}px`)
      if (clearance < 0) {
        log(`FAIL: the snackbar overlaps the tab bar by ${(-clearance).toFixed(1)}px`)
        exitCode = 1
      }
    }

    // ---- page bar: zero layout cost at rest ----
    log("Checking the pinned page bar's at-rest layout cost...")
    const pageBar = await checkPageBarZeroLayout({ client, baseUrl })
    if (!pageBar.found) {
      log("page bar: not found on /admin (this page's title row never scrolls behind it at rest — expected; the bar exists in the DOM regardless per components.css, gated `:visible` toggles `inert` only, never presence)")
    } else if (pageBar.position !== "absolute") {
      log(`FAIL: .pk-admin-page-bar's computed position is "${pageBar.position}", expected "absolute" — this is the SOLE mechanism giving it zero layout cost at rest (a sticky child still occupies its flow slot even while visually at rest)`)
      exitCode = 1
    } else {
      log(`page bar: position=absolute (confirmed zero layout cost by construction) — title top=${pageBar.titleTop}px, grid top=${pageBar.gridTop}px`)
    }

    // ---- save bar: plan 01.8.2-17's editor is the FIRST live call site ----
    log("Checking the fixed foot save bar (D-28)...")
    const saveBar = await checkSaveBarDeferred({ client, baseUrl })
    log(`--pk-save-bar-h resolves to ${saveBar.saveBarHVar} (checked on /admin, which never carries a save bar itself — save_bar/1 is editor-only)`)
    const editorUrl = await resolveEditorUrl(client, baseUrl)
    if (!editorUrl) {
      log("FAIL: could not resolve a real game editor URL off /admin/juegos — is the dev catalog empty?")
      exitCode = 1
    } else {
      const liveInstance = await (async () => {
        await navigate(client, `${baseUrl}${editorUrl}`)
        return evalJS(client, `document.querySelector('[data-pk-save-bar]') !== null`)
      })()
      log(`Resolved editor URL: ${editorUrl}; live [data-pk-save-bar] instance found there: ${liveInstance}`)
      if (!liveInstance) {
        log(`FAIL: no live [data-pk-save-bar] instance found on ${editorUrl}`)
        exitCode = 1
      } else {
        for (const width of [375, 360]) {
          const m = await measureSaveBarLive({ client, baseUrl, editorUrl, width })
          if (!m) {
            log(`FAIL: save_bar/1 not found on ${editorUrl} @ ${width}px`)
            exitCode = 1
            continue
          }
          const pct = Math.round((m.ink / m.btnW) * 1000) / 10
          const clearance = m.lastBlockBottom === null ? null : Math.round((m.barTop - m.lastBlockBottom) * 10) / 10
          log(
            `save bar @ ${width}px: barH=${m.barH}px (--pk-save-bar-h=${saveBar.saveBarHVar}) btn=${m.btnW}x${m.btnH} ` +
              `ink=${pct}% right-gap=${m.btnRight}px lastBlockBottom=${m.lastBlockBottom}px barTop=${m.barTop}px clearance=${clearance}px`,
          )
          if (Math.round(parseFloat(saveBar.saveBarHVar)) !== Math.round(m.barH)) {
            log(`FAIL: rendered bar height ${m.barH}px does not match --pk-save-bar-h (${saveBar.saveBarHVar})`)
            exitCode = 1
          }
          // sketch 080's four negative checks (21/22 filled, 23 full-width,
          // 25 tonal band) — 26 ("sin banda"/opaque, a pixel-scan) is not
          // re-run here: `.pk-admin-save-bar`'s `background` is a plain
          // solid CSS colour (`var(--color-base-100)`, `components.css`),
          // never a gradient/transparent value, so "opaque by construction"
          // holds without a screenshot diff — see editor.css/components.css.
          if (m.btnFill !== m.barBg) {
            log(`FAIL: negative 22 (no filled button) — button fill ${m.btnFill} != page-coloured bar background ${m.barBg}`)
            exitCode = 1
          }
          if (pct <= 55 || m.btnW >= 160) {
            log(`FAIL: negative 23 (no full width) — button is ${m.btnW}px wide, ${pct}% ink (expected natural width, >55% ink)`)
            exitCode = 1
          }
          // The bar's own background must be the PAGE ground
          // (`--color-base-100`), not a distinct tonal surface — asserted
          // by comparing it against a bare `--color-base-100` swatch
          // element (not `document.body`, which carries no explicit
          // background of its own in this app and reads transparent).
          if (m.barBg !== m.pageBg) {
            log(`FAIL: negative 25 (no tonal band) — bar background ${m.barBg} != --color-base-100 (${m.pageBg})`)
            exitCode = 1
          }
          if (clearance !== null && clearance < 0) {
            log(`FAIL: the last body block is hidden under the save bar by ${(-clearance).toFixed(1)}px @ ${width}px (D-28's named failure mode)`)
            exitCode = 1
          }
        }
      }
    }

    // ---- the keel ----
    log("Measuring the shell's content keel (open item 4)...")
    const keelResults = {}
    for (const width of [375, 360]) {
      const m = await measureKeel({ client, baseUrl, width })
      keelResults[width] = m
      for (const [page, edges] of Object.entries(m)) {
        if (!edges) {
          log(`FAIL: keel @ ${width}px ${page}: content wrapper not found`)
          exitCode = 1
          continue
        }
        log(`KEEL @ ${width}px ${page}: left=${edges.left}px right=${edges.right}px`)
      }
    }
    // Cross-page consistency at each width — the keel should be one number
    // per width across every screen (D-18's shared shape), not a fresh one
    // per page.
    for (const width of [375, 360]) {
      const pages = Object.values(keelResults[width]).filter(Boolean)
      const distinctLeft = [...new Set(pages.map((p) => p.left))]
      const distinctRight = [...new Set(pages.map((p) => p.right))]
      if (distinctLeft.length > 1 || distinctRight.length > 1) {
        log(`FAIL: keel @ ${width}px is not consistent across pages: ${JSON.stringify(keelResults[width])}`)
        exitCode = 1
      } else if (pages.length > 0) {
        log(`KEEL @ ${width}px (consistent across ${pages.length} page(s)): left=${distinctLeft[0]}px right=${distinctRight[0]}px`)
      }
    }
  } finally {
    await stopChrome(chrome)
    await stopDevServer(serverProc)
  }

  console.log(exitCode === 0 ? "\nadmin_shell.mjs: ALL CHECKS PASSED" : "\nadmin_shell.mjs: FAILURES ABOVE")
  process.exit(exitCode)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
