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
//   - (plan 01.8.3-05) Juegos-specific list/caption geometry: the 16px
//     content keel of a list row and the pinned search row, both section
//     pinned-band heights and their flush adjacency to the pinned search
//     row (D-15), a list row's 64px floor, and the caption's ink-to-ink
//     air ratio (D-13) — see the Juegos list-geometry check below
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
//   - a `position: fixed` element's DOM offset-parent reference is
//     unconditionally null in Chrome (confirmed empirically in
//     `admin_components.mjs`) — this file never reads that property either;
//     visibility reads go through resolved `display`/rect presence instead.
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
  // Plan 01.8.3-06: replaces a fixed 1200ms post-confirm sleep, which
  // `01.8.3-UAT.md` recorded as flaking on a cold first boot (observed
  // needing ~1500ms there). Polls the same `pk-admin-tab-bar` presence
  // expression the confirmation check below already evaluates, with a
  // timeout comfortably above that observed cold-boot latency.
  const confirmed = await pollUntil(
    () => evalJS(client, `document.body ? document.body.innerHTML.includes('pk-admin-tab-bar') : false`),
    { timeoutMs: 6000, intervalMs: 150 },
  )
  if (!confirmed) throw new Error("login: post-login page does not render the admin tab bar — login did not complete")
}

// ---------------------------------------------------------------------------
// Plan 01.8.3-07 — G-01.8.3-2b: an open aria-modal sheet must actually
// cover the viewport. `.pk-admin-overlay-root` is `position: fixed; inset:
// 0`, which should mean full-viewport by construction — but a flow child
// that is not its parent's LAST child inherits Tailwind v4's `space-y-*`
// `margin-block-end`, which SHRINKS a fixed, `inset: 0` element's used
// height rather than offsetting it (confirmed: `#add-game-sheet` measured
// 820px against an 844px ICB, the bottom 24px of the admin tab bar left
// visible and clickable under an open, `aria-modal="true"` sheet — a real
// CDP click at that point navigated away with the modal still open).
//
// Two independent proofs, both required by the gap:
//   1. `checkSyntheticOverlayControl` — a synthetic overlay clone injected
//      as a NON-LAST child of every `[class*="space-y-"]` container on
//      every admin page in `PAGES`. Data-independent: it reaches every
//      call site's real parent, even pages this script never opens a real
//      sheet on. The trailing empty sibling is NOT decorative — Tailwind
//      v4's `space-y-*` compiles to a `:where(& > :not(:last-child))`
//      form, so an overlay injected as the LAST child would be exempted
//      from the margin entirely and this control would pass vacuously,
//      exactly the class of defect this whole gap is made of.
//   2. `checkOverlayRealOpenWalk` — real clicks through real controls that
//      open real sheets/dialogs (`OVERLAY_CALL_SITES` below), hit-tested
//      via `elementFromPoint` at their own viewport corners (guard rule 2:
//      read what is actually painted at a point, never node existence).
// ---------------------------------------------------------------------------

// Ported from `admin_components.mjs`'s own `isOverlayOpen` — module-level
// here (that file's version is a closure) since this file's `main()` and
// the walk below both call it directly. A DOM offset-parent reference is
// unconditionally null for a `position: fixed` element in Chrome
// regardless of visibility (confirmed empirically in
// `admin_components.mjs`) — `.pk-admin-overlay-root` is always
// `position: fixed`, so an open check based on that property can never
// pass. Reads the RESOLVED `display` instead (guard rule 2: resolved
// style, not node existence). A `:if`-mounted overlay entirely absent from
// the DOM also counts as closed.
async function isOverlayOpen(client, rootId) {
  return evalJS(
    client,
    `(() => { const el = document.getElementById(${JSON.stringify(rootId)}); return !!el && getComputedStyle(el).display !== 'none'; })()`,
  )
}

// Ported from `admin_components.mjs`'s own `clickCenterOf` — a real
// `Input.dispatchMouseEvent` at the target's own centre, with an
// `elementFromPoint` reachability pre-check (guard rule 2). On an
// obstruction it still delivers the click via a direct `.click()` so the
// opener chains below (testing whether an overlay OPENS and COVERS, not
// whether its OPENER is itself reachable) can keep running; the caller
// decides whether the obstruction is itself reportable.
async function clickCenterOf(client, selector) {
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
        hitDescription: hit ? (hit.id ? '#' + hit.id : (hit.className || hit.tagName)) : '(nothing)',
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
    return { obstructed: false, hitDescription: point.hitDescription }
  }

  log(`clickCenterOf: ${selector} is obstructed at its own centre point — a real tap there would hit ${point.hitDescription} instead. Falling back to a direct .click().`)
  await evalJS(client, `document.querySelector(${JSON.stringify(selector)}).click(); true`)
  return { obstructed: true, hitDescription: point.hitDescription }
}

// The declared call-site table (plan 01.8.3-07 Task 1: one row, the
// defect's own — `add-game-sheet`. Task 3 expands this to six rows
// spanning both `sheet/1` and `dialog/1`). Each row starts from a fresh
// navigation. `dataIndependent: true` rows render their opener
// UNCONDITIONALLY — a missing opener there means the walk itself is
// broken, not that the dev catalog is thin, so it is a FAIL. A missing
// opener on a data-dependent row (`dataIndependent: false`) is printed as
// an explicit not-openable verdict, never a FAIL and never counted as
// coverage. Each row's `steps` are run in order by `runOpenerSteps`: a
// `type` step fills an input and dispatches a bubbling `input` event (so a
// LiveView `phx-change` fires); a `click` step performs a real
// `clickCenterOf` click. Every step polls for its own selector's presence
// first, rather than sleeping a fixed interval.
const OVERLAY_CALL_SITES = [
  {
    page: "/admin/juegos",
    overlayId: "add-game-sheet",
    dataIndependent: true,
    steps: [{ kind: "click", selector: "#juegos-add-action" }],
  },
]

// Injects a synthetic overlay clone (plus a trailing empty sibling so the
// overlay is never the container's last child) into EVERY
// `[class*="space-y-"]` container on the current page, measures each, and
// removes both in a `finally` — all inside one `evalJS` expression so the
// DOM is never left mutated across a network round trip and a thrown error
// cannot leave debris behind for the next page.
async function measureSyntheticOverlaySpaceY(client) {
  return evalJS(
    client,
    `
    JSON.stringify((() => {
      const containers = [...document.querySelectorAll('[class*="space-y-"]')];
      const records = [];
      for (const container of containers) {
        const overlay = document.createElement('div');
        overlay.className = 'pk-admin-overlay-root pk-admin-overlay--open';
        const sibling = document.createElement('div');
        try {
          container.appendChild(overlay);
          container.appendChild(sibling);
          const r = overlay.getBoundingClientRect();
          const cs = getComputedStyle(overlay);
          records.push({
            containerClass: container.className,
            width: Math.round(r.width * 10) / 10,
            height: Math.round(r.height * 10) / 10,
            top: Math.round(r.top * 10) / 10,
            left: Math.round(r.left * 10) / 10,
            marginTop: cs.marginTop,
            marginRight: cs.marginRight,
            marginBottom: cs.marginBottom,
            marginLeft: cs.marginLeft,
          });
        } finally {
          overlay.remove();
          sibling.remove();
        }
      }
      return { records, innerWidth: window.innerWidth, innerHeight: window.innerHeight };
    })())
  `,
  )
}

async function checkSyntheticOverlayControl({ client, baseUrl }) {
  const fails = []
  for (const page of PAGES) {
    await setViewport(client, 390, 844)
    await navigate(client, `${baseUrl}${page}`)
    await new Promise((r) => setTimeout(r, 200))
    const { records, innerWidth, innerHeight } = JSON.parse(await measureSyntheticOverlaySpaceY(client))
    if (records.length === 0) {
      log(`synthetic overlay control ${page}: no [class*="space-y-"] container found — nothing to check`)
      continue
    }
    let pagePassed = true
    for (const r of records) {
      const marginsZero = ["marginTop", "marginRight", "marginBottom", "marginLeft"].every((k) => r[k] === "0px")
      const covers =
        Math.abs(r.height - innerHeight) <= 0.5 &&
        Math.abs(r.width - innerWidth) <= 0.5 &&
        Math.abs(r.top) <= 0.5 &&
        Math.abs(r.left) <= 0.5
      if (!covers || !marginsZero) {
        pagePassed = false
        const msg = `synthetic overlay control ${page} container=${JSON.stringify(r.containerClass)}: rect ${r.width}x${r.height} @ (${r.left},${r.top}) vs ICB ${innerWidth}x${innerHeight}, margins ${r.marginTop}/${r.marginRight}/${r.marginBottom}/${r.marginLeft}`
        fails.push(msg)
        log(`FAIL: ${msg}`)
      }
    }
    if (pagePassed) {
      log(`synthetic overlay control ${page}: full-ICB overlay for all ${records.length} container(s), margins 0px`)
    }
  }
  return { fails }
}

// Runs a call-site row's opener chain in order. Polls for each step's own
// target selector before acting on it (never a fixed sleep). Returns
// `{ openable: false, missingSelector }` the moment a step's selector never
// appears — the caller decides whether that is a FAIL (a data-independent
// row) or a printed not-openable verdict (a data-dependent one).
async function runOpenerSteps(client, steps) {
  for (const step of steps) {
    const present = await pollUntil(() => evalJS(client, `!!document.querySelector(${JSON.stringify(step.selector)})`))
    if (!present) return { openable: false, missingSelector: step.selector }
    if (step.kind === "type") {
      await evalJS(
        client,
        `
        (() => {
          const el = document.querySelector(${JSON.stringify(step.selector)});
          el.value = ${JSON.stringify(step.value)};
          el.dispatchEvent(new Event('input', { bubbles: true }));
          return true;
        })()
      `,
      )
    } else {
      await clickCenterOf(client, step.selector)
    }
  }
  return { openable: true }
}

// The real-open walk's own measurement body: the overlay root's own rect
// against the ICB, its four computed margins, and five `elementFromPoint`
// probes — each viewport corner inset 4px, plus the bottom-centre point
// (`innerWidth / 2`, `innerHeight - 12`) — the exact point family the UAT's
// own coordinate (195, 832 at 390x844) belongs to. `elementFromPoint`
// reads what is ACTUALLY painted at a point (guard rule 2), never node
// existence — this is what proves nothing outside the overlay is
// reachable, not just that the overlay node exists somewhere in the DOM.
async function measureOverlayCoverage(client, overlayId) {
  const json = await evalJS(
    client,
    `
    JSON.stringify((() => {
      const el = document.getElementById(${JSON.stringify(overlayId)});
      if (!el) return { found: false };
      const r = el.getBoundingClientRect();
      const cs = getComputedStyle(el);
      const w = window.innerWidth, h = window.innerHeight;
      const points = [
        [4, 4],
        [w - 4, 4],
        [4, h - 4],
        [w - 4, h - 4],
        [w / 2, h - 12],
      ];
      const hits = points.map(([x, y]) => {
        const hit = document.elementFromPoint(x, y);
        const inside = !!hit && (hit === el || el.contains(hit));
        return {
          x, y, inside,
          description: hit ? (hit.id ? '#' + hit.id : (hit.className || hit.tagName)) : '(nothing)',
        };
      });
      return {
        found: true,
        rect: { top: Math.round(r.top * 10) / 10, left: Math.round(r.left * 10) / 10, width: Math.round(r.width * 10) / 10, height: Math.round(r.height * 10) / 10 },
        icb: { width: w, height: h },
        margins: { top: cs.marginTop, right: cs.marginRight, bottom: cs.marginBottom, left: cs.marginLeft },
        hits,
      };
    })())
  `,
  )
  return JSON.parse(json)
}

// Drives `OVERLAY_CALL_SITES` end to end: for each row, navigate fresh,
// run its opener steps, poll until its overlay's resolved `display` is not
// `none`, then measure coverage. Prints exactly one verdict line per row —
// covered, a coverage failure, or not-openable — and a summary naming how
// many rows were attempted vs. covered, so an absent opener can never
// silently shrink the reported row count.
async function checkOverlayRealOpenWalk({ client, baseUrl, rows }) {
  const fails = []
  const notOpenable = []
  let covered = 0

  for (const row of rows) {
    await setViewport(client, 390, 844)
    await navigate(client, `${baseUrl}${row.page}`)
    await new Promise((r) => setTimeout(r, 250))

    const openResult = await runOpenerSteps(client, row.steps)
    if (!openResult.openable) {
      if (row.dataIndependent) {
        const msg = `${row.page} ${row.overlayId}: opener selector never appeared (${openResult.missingSelector}) — this opener renders unconditionally, so its absence means the walk itself is broken, not that dev data is thin`
        fails.push(msg)
        log(`FAIL: ${msg}`)
      } else {
        notOpenable.push({ page: row.page, overlayId: row.overlayId, missingSelector: openResult.missingSelector })
        log(`NOT-OPENABLE: ${row.page} ${row.overlayId}: opener selector never appeared (${openResult.missingSelector}) — dev data is likely too thin for this row`)
      }
      continue
    }

    const opened = await pollUntil(() => isOverlayOpen(client, row.overlayId))
    if (!opened) {
      const msg = `${row.page} ${row.overlayId}: opener steps completed but the overlay never reached a resolved display other than 'none'`
      fails.push(msg)
      log(`FAIL: ${msg}`)
      continue
    }

    const m = await measureOverlayCoverage(client, row.overlayId)
    if (!m.found) {
      const msg = `${row.page} ${row.overlayId}: overlay reported open but #${row.overlayId} is not in the DOM`
      fails.push(msg)
      log(`FAIL: ${msg}`)
      continue
    }

    const { rect, icb, margins, hits } = m
    const coversRect =
      Math.abs(rect.width - icb.width) <= 0.5 &&
      Math.abs(rect.height - icb.height) <= 0.5 &&
      Math.abs(rect.top) <= 0.5 &&
      Math.abs(rect.left) <= 0.5
    const marginsZero = margins.top === "0px" && margins.right === "0px" && margins.bottom === "0px" && margins.left === "0px"
    const badHits = hits.filter((h) => !h.inside)

    if (coversRect && marginsZero && badHits.length === 0) {
      covered++
      log(`COVERED: ${row.page} ${row.overlayId}: rect ${rect.width}x${rect.height} @ (${rect.left},${rect.top}) covers ICB ${icb.width}x${icb.height}, margins 0px, all ${hits.length} hit tests inside`)
    } else {
      const hitMsg = badHits.length ? `; hit test(s) missed: ${badHits.map((h) => `(${h.x},${h.y})->${h.description}`).join(", ")}` : ""
      const msg = `${row.page} ${row.overlayId}: coverage failure — rect ${rect.width}x${rect.height} @ (${rect.left},${rect.top}) vs ICB ${icb.width}x${icb.height}, margins ${margins.top}/${margins.right}/${margins.bottom}/${margins.left}${hitMsg}`
      fails.push(msg)
      log(`FAIL: ${msg}`)
    }

    // Fresh navigation so no residual overlay/LiveView state leaks into
    // the next row's measurement.
    await navigate(client, `${baseUrl}${row.page}`)
  }

  log(`overlay real-open walk: attempted=${rows.length} covered=${covered} not-openable=${notOpenable.length}`)
  return { fails, notOpenable, covered, attempted: rows.length }
}

async function checkOverlayCoversViewport({ client, baseUrl }) {
  const synthetic = await checkSyntheticOverlayControl({ client, baseUrl })
  const walk = await checkOverlayRealOpenWalk({ client, baseUrl, rows: OVERLAY_CALL_SITES })
  return {
    fails: [...synthetic.fails, ...walk.fails],
    notOpenable: walk.notOpenable,
    covered: walk.covered,
    attempted: walk.attempted,
  }
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
// Plan 01.8.3-05 — the Juegos list/caption geometry check below: the
// Juegos-specific pixel claims D-13/D-15/D-16 make and `LiveViewTest`
// cannot prove (no browser, no
// scroll, no `getBoundingClientRect`). Measures, against a real staff
// session on /admin/juegos:
//   - the 16px content keel of a list row and of the pinned search row, at
//     375/360/390px, and that the two agree with each other (D-16)
//   - the pinned `::before` band's own height while a section caption is
//     actually pinned — read off the pseudo-element's own box, never the
//     header's padded box — compared between the FIRST section
//     (`--pt: 14px`) and a LATER one (`--pt: 26px`), exactly the axis the
//     shipped 32.2px/44.2px defect varied on (D-15, 01.8.3-RESEARCH.md)
//   - that the band's top edge sits flush against the pinned search row's
//     own bottom edge (neither gap nor overlap), and that its resolved
//     background is not fully transparent while pinned — a height-only
//     check would pass against a band that exists but paints nothing, the
//     original G-01.8.2-4 report
//   - a list row's rendered height (D-13's 64px floor)
//   - the ink-to-ink air ratio around a pinned caption (D-13's 27px-above /
//     9px-below, 2.5:1+ floor), via a `Range` over each side's own text
//     node — this file's rule 7. Juegos captions render uppercase-
//     transformed (`text-transform: uppercase`), so their glyphs carry no
//     descenders regardless of the underlying text content ("Juegos" has a
//     lowercase `j`, but the rendered capital `J` does not descend) — a
//     plain text-node Range already reports cap-height ink without needing
//     a synthetic "H" fixture glyph.
//
// R2 landmine: every list cover is an R2 thumbnail. `forceEagerDecodeCovers`
// below runs before every measurement in this function — an undecoded cover
// renders as an empty box and silently shortens every row height and
// ink-to-ink distance measured here.
// ---------------------------------------------------------------------------
async function forceEagerDecodeCovers(client) {
  await evalJS(
    client,
    `
    (async () => {
      const imgs = [...document.querySelectorAll('.pk-admin-row__cover')];
      imgs.forEach((img) => { img.loading = 'eager'; });
      await Promise.race([
        Promise.all(imgs.map((img) => (img.decode ? img.decode().catch(() => {}) : Promise.resolve()))),
        new Promise((r) => setTimeout(r, 5000)),
      ]);
      return imgs.length;
    })()
  `,
  )
}

// "Content edge" is measured relative to `.pk-admin-juegos`'s OWN box, not
// the viewport — `<main>`'s site-wide 16px horizontal padding (the shared
// admin keel `measureKeel` above already independently verifies) would
// otherwise get counted a second time on top of the row's/search-row's own
// `padding-left`, silently doubling every reading to 32px. D-16's own
// language is explicit that this is a per-CHILD self-inset ("rows self-
// inset 16px") layered on a container that itself has none — this function
// nets the container's contribution back out so the reported number is
// each element's OWN contribution, which is what D-16 requires to be 16
// and consistent between the two.
async function measureJuegosKeelAt({ client, baseUrl, width }) {
  await setViewport(client, width, 844)
  await navigate(client, `${baseUrl}/admin/juegos`)
  const json = await pollUntil(async () => {
    const raw = await evalJS(
      client,
      `
      JSON.stringify((() => {
        const container = document.querySelector('.pk-admin-juegos');
        const row = document.querySelector('.pk-admin-juegos-rows .pk-admin-row');
        if (!container || !row) return null;
        return true;
      })())
    `,
    )
    return raw === "true" ? raw : null
  })
  if (!json) return { row: null, searchRow: null }
  await forceEagerDecodeCovers(client)
  const measured = await evalJS(
    client,
    `
    JSON.stringify((() => {
      const container = document.querySelector('.pk-admin-juegos');
      const cRect = container ? container.getBoundingClientRect() : null;
      function edges(el) {
        if (!el || !cRect) return null;
        const r = el.getBoundingClientRect();
        const cs = getComputedStyle(el);
        const pl = parseFloat(cs.paddingLeft) || 0;
        const pr = parseFloat(cs.paddingRight) || 0;
        return {
          left: Math.round(((r.left - cRect.left) + pl) * 10) / 10,
          right: Math.round(((cRect.right - r.right) + pr) * 10) / 10,
        };
      }
      const row = document.querySelector('.pk-admin-juegos-rows .pk-admin-row');
      const searchRow = document.querySelector('.pk-admin-juegos-search-row');
      return { row: edges(row), searchRow: edges(searchRow) };
    })())
  `,
  )
  return JSON.parse(measured)
}

// Borradores/Retirados start collapsed (index.ex's `collapsed_sections`
// default) — expand a collapsible section via a REAL click on its own
// toggle button (never a direct assign/attribute poke) so the LiveView
// round trip that actually re-renders `.pk-admin-juegos-rows` happens.
async function expandJuegosSection(client, key) {
  const json = await evalJS(
    client,
    `
    JSON.stringify((() => {
      const btn = document.getElementById(${JSON.stringify(`juegos-section-toggle-${key}`)});
      if (!btn) return { found: false };
      if (btn.getAttribute('aria-expanded') === 'false') {
        btn.click();
        return { found: true, clicked: true };
      }
      return { found: true, clicked: false };
    })())
  `,
  )
  const result = JSON.parse(json)
  if (result.clicked) await new Promise((r) => setTimeout(r, 300))
  return result
}

// Scrolls the given section's caption into its pinned state (overshooting
// so its own rows are visible below it too), nudges the scroll back up a
// few px so `admin_list.js`'s onScroll sees `goingDown === false` and
// un-hides the pinned search row (needed for the band/search-row adjacency
// measurement below), then reads every geometry fact this check needs off
// the real, currently-pinned DOM.
async function measureJuegosSectionPinned(client, sectionSelector) {
  const json = await evalJS(
    client,
    `
    (async () => {
      const section = document.querySelector(${JSON.stringify(sectionSelector)});
      if (!section) return JSON.stringify({ error: "section not found: ${sectionSelector}" });
      const wrap = section.querySelector('.pk-admin-juegos-section-heading-wrap');
      const header = wrap ? wrap.querySelector('.pk-admin-juegos-section-header') : null;
      const sentinel = section.querySelector('[data-pk-section-sentinel]');
      if (!wrap || !header || !sentinel) return JSON.stringify({ error: 'heading wrap/header/sentinel not found' });

      const pinnedHRaw = getComputedStyle(document.querySelector('.pk-admin-juegos')).getPropertyValue('--pk-juegos-pinned-h');
      const pinnedH = parseFloat(pinnedHRaw) || 60;

      // Ink-to-ink air ratio is a RESTING-layout property (D-13's 27px-
      // above/9px-below anatomy is about normal document flow, not the
      // pinned overlay) and MUST be measured here, before any pin-
      // triggering scroll — confirmed empirically that measuring it AFTER
      // pinning reads nonsense (a negative "below" distance), because a
      // pinned header visually overlaps (z-index above) whatever content
      // has scrolled up underneath it, corrupting the "row below" reading.
      // getBoundingClientRect() works regardless of whether these elements
      // are currently within the viewport, so this reads correctly even
      // while the page is unscrolled and this section is far off-screen.
      function textInk(el) {
        if (!el) return null;
        const target = el.querySelector ? (el.querySelector('.pk-admin-row__name') || el) : el;
        const walker = document.createTreeWalker(target, NodeFilter.SHOW_TEXT);
        const node = walker.nextNode();
        if (!node || !node.nodeValue || !node.nodeValue.trim()) return null;
        const range = document.createRange();
        range.selectNodeContents(node);
        const r = range.getBoundingClientRect();
        return { top: r.top, bottom: r.bottom };
      }
      const rowsWrapForInk = section.querySelector('.pk-admin-juegos-rows');
      const firstRowBelowForInk = rowsWrapForInk ? rowsWrapForInk.querySelector('.pk-admin-row') : null;
      const prevSectionForInk = section.previousElementSibling;
      const prevRowsWrapForInk = prevSectionForInk ? prevSectionForInk.querySelector('.pk-admin-juegos-rows') : null;
      const prevRowsForInk = prevRowsWrapForInk ? [...prevRowsWrapForInk.querySelectorAll('.pk-admin-row')] : [];
      const lastRowAboveForInk = prevRowsForInk.length ? prevRowsForInk[prevRowsForInk.length - 1] : null;
      const labelElForInk = header.querySelector('.pk-admin-list-section-label');
      const capInk = textInk(labelElForInk);
      const inkAbove = textInk(lastRowAboveForInk);
      const inkBelow = textInk(firstRowBelowForInk);
      let airAbove = null, airBelow = null, airRatio = null;
      if (inkAbove && capInk) airAbove = Math.round((capInk.top - inkAbove.bottom) * 10) / 10;
      if (capInk && inkBelow) airBelow = Math.round((inkBelow.top - capInk.bottom) * 10) / 10;
      if (airAbove != null && airBelow != null && airBelow > 0) airRatio = Math.round((airAbove / airBelow) * 100) / 100;
      const hasRowAboveForInk = !!lastRowAboveForInk;

      // The wrap itself is position:sticky — once scrolled past its own
      // pin threshold, its getBoundingClientRect().top reports its STUCK
      // viewport position (pinnedH), not its natural document-flow
      // position, so recomputing "naturalTop" from the WRAP on every loop
      // iteration drifts upward without bound the moment it first pins
      // (confirmed empirically: lastScrollY grew unbounded across 60
      // tries). The sentinel immediately before it is a normal-flow,
      // zero-height element (never sticky), so its document-absolute
      // position is stable regardless of current scroll — read it exactly
      // ONCE, before any scrolling, and reuse that fixed value.
      const naturalTop = sentinel.getBoundingClientRect().top + window.scrollY;

      let pinned = false;
      let tries = 0;
      let lastScrollY = -1;
      while (!pinned && tries < 60) {
        const maxScroll = Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
        const target = Math.min(Math.max(0, naturalTop - pinnedH + 250), maxScroll);
        window.scrollTo(0, target);
        await new Promise((r) => requestAnimationFrame(r));
        await new Promise((r) => setTimeout(r, 80));
        lastScrollY = window.scrollY;
        pinned = wrap.getAttribute('data-pinned') === 'true';
        tries++;
      }
      if (!pinned) {
        return JSON.stringify({
          error: 'section never reached data-pinned="true" after scrolling',
          debug: {
            pinnedH, naturalTop, tries, lastScrollY,
            sentinelCount: document.querySelectorAll('[data-pk-section-sentinel]').length,
            sectionOuterHTMLLen: section.outerHTML.length,
            wrapAttrs: wrap.getAttributeNames(),
          },
        });
      }

      // Now that the caption is confirmed pinned, un-hide the pinned search
      // row WITHOUT touching scroll position at all: a scroll-position nudge
      // risks crossing back over the observer's own pin threshold near the
      // boundary (observed empirically — a bare -5px nudge intermittently
      // un-pinned the caption). admin_list.js's onScroll only re-evaluates
      // on a real 'scroll' event, but its un-hide branch is
      // (focused OR nearTop) — focusing the search input and firing a
      // synthetic scroll event (net scrollY delta zero) satisfies that
      // branch without moving the page at all — the preventScroll focus
      // option below is required, not decorative: the search input is
      // visually translated off-screen while data-pinned-hidden is set
      // (its layout box still sits at its own sticky top:0, unaffected by
      // the transform), so a bare, option-less focus() call made the
      // browser "helpfully" scroll the whole page back toward that layout
      // box's natural position near the top of the document — observed
      // empirically resetting scrollY to near-zero and reading a stale
      // pinned attribute back before the observer had a chance to correct
      // it for the new, no-longer-pinned scroll position.
      const searchInputEl = document.querySelector('#juegos-search-input');
      if (searchInputEl) searchInputEl.focus({ preventScroll: true });
      window.dispatchEvent(new Event('scroll'));
      await new Promise((r) => requestAnimationFrame(r));
      await new Promise((r) => setTimeout(r, 150));
      pinned = wrap.getAttribute('data-pinned') === 'true';
      if (!pinned) {
        return JSON.stringify({ error: 'section un-pinned after focusing the search input — unexpected' });
      }
      if (searchInputEl) searchInputEl.blur();

      // Plan 01.8.3-06: the caption's ink rect a SECOND time, now that the
      // section is confirmed pinned — a distinct reading from capInk
      // above, which is the RESTING-layout measurement the D-13 air-ratio
      // assertions depend on and must not be disturbed. Read via the same
      // textInk helper, on the same label element, so both readings are
      // directly comparable.
      const pinnedInk = textInk(labelElForInk);

      const searchWrap = document.querySelector('#juegos-search-wrap');
      const searchHidden = searchWrap ? searchWrap.hasAttribute('data-pinned-hidden') : null;
      const searchRect = searchWrap ? searchWrap.getBoundingClientRect() : null;

      const headerRect = header.getBoundingClientRect();
      const beforeCs = getComputedStyle(header, '::before');
      const topOffset = parseFloat(beforeCs.top) || 0;
      const bottomOffset = parseFloat(beforeCs.bottom) || 0;
      const bandTop = Math.round((headerRect.top + topOffset) * 10) / 10;
      const bandBottom = Math.round((headerRect.bottom - bottomOffset) * 10) / 10;
      const bandHeight = Math.round((bandBottom - bandTop) * 10) / 10;
      const bandBg = beforeCs.backgroundColor;
      const bandSearchGap = searchRect ? Math.round((bandTop - searchRect.bottom) * 10) / 10 : null;

      // Plan 01.8.3-06: where the pinned caption's own ink sits INSIDE the
      // band — bandTop/bandBottom above are read off the ::before
      // pseudo-element's own resolved geometry, never the header's box,
      // exactly like the band-height reading a few lines up. A null
      // pinnedInk (ink could not be measured) propagates as null gaps
      // rather than a false zero, which would otherwise read as a perfect
      // pass.
      const inkGapAbove = pinnedInk ? Math.round((pinnedInk.top - bandTop) * 10) / 10 : null;
      const inkGapBelow = pinnedInk ? Math.round((bandBottom - pinnedInk.bottom) * 10) / 10 : null;

      const rowsWrap = section.querySelector('.pk-admin-juegos-rows');
      const firstRowBelow = rowsWrap ? rowsWrap.querySelector('.pk-admin-row') : null;
      const rowHeight = firstRowBelow ? Math.round(firstRowBelow.getBoundingClientRect().height * 10) / 10 : null;

      return JSON.stringify({
        pinned, searchHidden, bandTop, bandBottom, bandHeight, bandBg, bandSearchGap,
        rowHeight, hasRowAbove: hasRowAboveForInk, airAbove, airBelow, airRatio,
        inkGapAbove, inkGapBelow,
      });
    })()
  `,
    true,
  )
  return JSON.parse(json)
}

async function checkJuegosListGeometry({ client, baseUrl }) {
  const fails = []
  const fail = (msg) => {
    fails.push(msg)
    log(`FAIL: ${msg}`)
  }

  // Plan 01.8.3-06: the pinned caption's ink position INSIDE its 44px band
  // — a class of defect band-height/background/adjacency checks alone
  // cannot see, since the band can stay 44px and opaque while its ink
  // slides to an edge. Logs both gaps for a section and applies the
  // null-guard + per-section symmetry gate; the cross-section `--pt`
  // independence gate lives separately, below, where both sections' own
  // results are already in scope together.
  const checkInkInBand = (label, result) => {
    log(`juegos ${label} ink-in-band: above=${result.inkGapAbove}px below=${result.inkGapBelow}px`)
    if (result.inkGapAbove == null || result.inkGapBelow == null) {
      fail(`juegos ${label} ink-in-band: could not measure the pinned ink position (inkGapAbove=${result.inkGapAbove}, inkGapBelow=${result.inkGapBelow})`)
      return
    }
    if (result.inkGapAbove <= 0 || result.inkGapBelow <= 0) {
      fail(`juegos ${label} ink-in-band: ink is outside or flush against the band edge (above=${result.inkGapAbove}px, below=${result.inkGapBelow}px)`)
    }
    const diff = Math.round(Math.abs(result.inkGapAbove - result.inkGapBelow) * 10) / 10
    if (diff > 2.0) {
      fail(`juegos ${label} ink-in-band: asymmetric by ${diff}px (above=${result.inkGapAbove}px, below=${result.inkGapBelow}px), expected within 2.0px of each other`)
    }
  }

  // ---- keel: a list row vs the pinned search row, at 375/360/390 ----
  const keelByWidth = {}
  for (const width of KEEL_VIEWPORTS) {
    keelByWidth[width] = await measureJuegosKeelAt({ client, baseUrl, width })
    const { row, searchRow } = keelByWidth[width]
    if (!row || !searchRow) {
      fail(`juegos keel @ ${width}px: row or search-row not found (row=${!!row}, searchRow=${!!searchRow})`)
      continue
    }
    log(`juegos keel @ ${width}px: row left=${row.left} right=${row.right}; search row left=${searchRow.left} right=${searchRow.right}`)
    if (row.left !== 16 || row.right !== 16) {
      fail(`juegos keel @ ${width}px: row content edges left=${row.left} right=${row.right}, expected 16/16`)
    }
    if (searchRow.left !== 16 || searchRow.right !== 16) {
      fail(`juegos keel @ ${width}px: search row content edges left=${searchRow.left} right=${searchRow.right}, expected 16/16`)
    }
    if (row.left !== searchRow.left || row.right !== searchRow.right) {
      fail(`juegos keel @ ${width}px: row and search row disagree (row=${JSON.stringify(row)}, searchRow=${JSON.stringify(searchRow)})`)
    }
  }

  // ---- band height / adjacency / row height / ink ratio, at 375px ----
  await setViewport(client, 375, 844)
  await navigate(client, `${baseUrl}/admin/juegos`)
  await new Promise((r) => setTimeout(r, 300))
  await forceEagerDecodeCovers(client)

  // Borradores (`draft`) starts collapsed (index.ex's default
  // `collapsed_sections`) — expand it via a real click so its rows exist
  // to measure. Juegos del club (`published`) is never collapsible.
  const expandResult = await expandJuegosSection(client, "draft")
  if (!expandResult.found) {
    fail("juegos sections: #juegos-section-toggle-draft not found — is Borradores empty in this dev catalog?")
  }

  const first = await measureJuegosSectionPinned(client, "#juegos-section-draft")
  if (first.error) {
    fail(`juegos first-section (Borradores) band: ${first.error}`)
  } else {
    log(
      `juegos first-section (Borradores) band: height=${first.bandHeight}px (top=${first.bandTop} bottom=${first.bandBottom}) ` +
        `bg=${first.bandBg} search-row gap=${first.bandSearchGap}px row-height=${first.rowHeight}px searchHidden=${first.searchHidden}`,
    )
    if (Math.abs(first.bandHeight - 44.0) > 0.5) fail(`juegos first-section band height ${first.bandHeight}px, expected 44.0 ±0.5px`)
    if (first.bandSearchGap === null || Math.abs(first.bandSearchGap) > 0.5) {
      fail(`juegos first-section band-to-search-row gap is ${first.bandSearchGap}px, expected within ±0.5px (0 = flush)`)
    }
    if (isFullyTransparent(first.bandBg)) fail(`juegos first-section band background is fully transparent while pinned (${first.bandBg})`)
    if (first.rowHeight === null || first.rowHeight < 64) fail(`juegos first-section row height ${first.rowHeight}px, expected >= 64px`)
    checkInkInBand("first-section (Borradores)", first)
  }

  const later = await measureJuegosSectionPinned(client, "#juegos-section-published")
  if (later.error) {
    fail(`juegos later-section (Juegos del club) band: ${later.error}`)
  } else {
    log(
      `juegos later-section (Juegos del club) band: height=${later.bandHeight}px (top=${later.bandTop} bottom=${later.bandBottom}) ` +
        `bg=${later.bandBg} search-row gap=${later.bandSearchGap}px row-height=${later.rowHeight}px searchHidden=${later.searchHidden}`,
    )
    if (Math.abs(later.bandHeight - 44.0) > 0.5) fail(`juegos later-section band height ${later.bandHeight}px, expected 44.0 ±0.5px`)
    if (later.bandSearchGap === null || Math.abs(later.bandSearchGap) > 0.5) {
      fail(`juegos later-section band-to-search-row gap is ${later.bandSearchGap}px, expected within ±0.5px (0 = flush)`)
    }
    if (isFullyTransparent(later.bandBg)) fail(`juegos later-section band background is fully transparent while pinned (${later.bandBg})`)
    if (later.rowHeight === null || later.rowHeight < 64) fail(`juegos later-section row height ${later.rowHeight}px, expected >= 64px`)

    if (!later.hasRowAbove) {
      fail("juegos ink ratio: later section has no row above it to measure — expected Borradores' last row above Juegos del club's caption")
    } else if (later.airAbove == null || later.airBelow == null || later.airRatio == null) {
      fail(`juegos ink ratio: could not measure both sides (airAbove=${later.airAbove}, airBelow=${later.airBelow})`)
    } else {
      log(`juegos ink-to-ink: above=${later.airAbove}px below=${later.airBelow}px ratio=${later.airRatio}:1`)
      if (later.airRatio < 2.5) fail(`juegos ink-to-ink ratio ${later.airRatio}:1 is below the 2.5:1 floor (above=${later.airAbove}px, below=${later.airBelow}px)`)
    }
    checkInkInBand("later-section (Juegos del club)", later)
  }

  if (!first.error && !later.error) {
    const delta = Math.round((first.bandHeight - later.bandHeight) * 10) / 10
    log(`juegos band heights: first=${first.bandHeight}px later=${later.bandHeight}px delta=${delta}px`)
    if (Math.abs(delta) > 0.5) fail(`juegos band heights disagree between sections by ${delta}px (first=${first.bandHeight}px, later=${later.bandHeight}px) — the shipped 32.2/44.2 defect this guards against`)

    // Plan 01.8.3-06: the assertion that directly names the root cause — a
    // band whose ink offset tracks `--pt` reads 14 against 26 today, even
    // though the band's own HEIGHT is identical (44px) for both sections.
    if (first.inkGapAbove == null || later.inkGapAbove == null) {
      fail(`juegos ink gap-above cross-section: could not measure inkGapAbove for one or both sections (first=${first.inkGapAbove}, later=${later.inkGapAbove})`)
    } else {
      const crossDelta = Math.round(Math.abs(first.inkGapAbove - later.inkGapAbove) * 10) / 10
      log(`juegos ink gap-above cross-section: first=${first.inkGapAbove}px later=${later.inkGapAbove}px delta=${crossDelta}px`)
      if (crossDelta > 1.0) {
        fail(`juegos ink gap-above disagrees between sections by ${crossDelta}px (first=${first.inkGapAbove}px, later=${later.inkGapAbove}px) — the band's ink offset tracks --pt instead of staying fixed`)
      }
    }
  }

  return { fails }
}

// `background-color` reports as `rgba(r, g, b, a)` (4-component) when any
// transparency is involved, or `rgb(r, g, b)` (3-component, always opaque)
// otherwise — checking the parsed alpha component directly, rather than
// string-matching `"rgba(0, 0, 0, 0)"`, survives a themed (non-black)
// transparent colour.
function isFullyTransparent(colorStr) {
  if (!colorStr) return true
  const m = colorStr.match(/rgba?\(([^)]+)\)/)
  if (!m) return false
  const parts = m[1].split(",").map((s) => Number.parseFloat(s.trim()))
  if (parts.length < 4) return false
  return parts[3] === 0
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

    // ---- page bar: confirmed deleted (plan 01.8.3-02, D-09) ----
    // `AdminComponents.page_bar/1` and its four `.pk-admin-page-bar` CSS
    // rule blocks were deleted OUTRIGHT in plan 01.8.3-02 — not merely
    // hidden — so `.pk-admin-page-bar` can never match on ANY page again
    // (confirmed: `grep -rn "pk-admin-page-bar" assets/ lib/` finds only a
    // prose mention inside an unrelated component's doc comment). Before
    // that plan, `!pageBar.found` was a benign, expected branch on `/admin`
    // specifically (the bar existed in the DOM but this page's content
    // never scrolled behind it at rest). That framing is now permanently
    // false everywhere, and the check could never fail again for any
    // reason — a guard that cannot fail is indistinguishable from a guard
    // that was never wired up. Repurposed (not deleted — see plan
    // 01.8.3-05's own SUMMARY for why the function definition itself is
    // kept intact) into the opposite assertion: `.pk-admin-page-bar`
    // resurfacing on `/admin` is now itself the regression this checks
    // for, since nothing in the deleted component's call graph can ever
    // legitimately render it again.
    log("Confirming the deleted page bar has not resurfaced on /admin...")
    const pageBar = await checkPageBarZeroLayout({ client, baseUrl })
    if (pageBar.found) {
      log(
        `FAIL: .pk-admin-page-bar found on /admin — AdminComponents.page_bar/1 and its CSS were deleted outright in plan 01.8.3-02 (D-09); its reappearance is a regression, not an expected state`,
      )
      exitCode = 1
    } else {
      log(
        "page bar: absent on /admin, as expected — AdminComponents.page_bar/1 and its CSS were deleted outright in plan 01.8.3-02 (D-09); this check now guards against its return rather than measuring its (now nonexistent) at-rest layout cost",
      )
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

    // ---- Juegos list geometry (plan 01.8.3-05, D-13/D-15/D-16) ----
    log("Measuring the Juegos list/caption geometry...")
    const juegosGeometry = await checkJuegosListGeometry({ client, baseUrl })
    if (juegosGeometry.fails.length > 0) {
      exitCode = 1
    }

    // ---- overlay coverage (plan 01.8.3-07, G-01.8.3-2b) ----
    log("Measuring overlay coverage (synthetic control + real-open call-site walk)...")
    const overlayCoverage = await checkOverlayCoversViewport({ client, baseUrl })
    if (overlayCoverage.fails.length > 0) {
      exitCode = 1
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
