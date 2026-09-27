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

// The declared call-site table (plan 01.8.3-07 Task 3 — expanded from
// Task 1's single `add-game-sheet` row to six, spanning both `sheet/1` and
// `dialog/1`, closing the gap's own third `missing:` bullet). Each row
// starts from a fresh navigation. `dataIndependent: true` rows render
// their opener UNCONDITIONALLY — a missing opener there means the walk
// itself is broken, not that the dev catalog is thin, so it is a FAIL. A
// missing opener on a data-dependent row (`dataIndependent: false`) is
// printed as an explicit not-openable verdict, never a FAIL and never
// counted as coverage. Each row's `steps` are run in order by
// `runOpenerSteps`: a `type` step fills an input and dispatches a bubbling
// `input` event (so a LiveView `phx-change` fires); a `click` step
// performs a real `clickCenterOf` click. Every step polls for its own
// selector's presence first, rather than sleeping a fixed interval.
//
// Destructive-path guard: `/admin/estantes/administrar`'s delete dialog
// and `/admin/estantes`'s remove-from-shelf dialog are reached ONLY as far
// as opening + measuring them — this walk must NEVER click either
// dialog's own commit control, `[phx-click="confirm-delete"]` or
// `[phx-click="confirm-quitar"]` (`EstanteLive.Administrar`'s
// `confirm-delete` handler deletes a real shelf; `EstanteLive.Index`'s
// `confirm-quitar` handler un-places a real copy). No step below targets
// either selector — `confirm-delete-shelf-dialog`'s own steps stop at
// `ask-delete`, which only OPENS the dialog. Each row's selectors are also
// scoped to that row's own named overlay/opener context so a later row can
// never accidentally resolve inside an earlier row's leftover markup.
const OVERLAY_CALL_SITES = [
  {
    page: "/admin/juegos",
    overlayId: "add-game-sheet",
    dataIndependent: true,
    steps: [{ kind: "click", selector: "#juegos-add-action" }],
  },
  {
    // `open-new-shelf` renders unconditionally in the header actions
    // regardless of shelf count (only "Ordenar" is gated on
    // `@shelves != []`) — data-independent.
    page: "/admin/estantes/administrar",
    overlayId: "shelf-name-sheet",
    dataIndependent: true,
    steps: [{ kind: "click", selector: '[phx-click="open-new-shelf"]' }],
  },
  {
    // Requires at least one real shelf row in `#administrar-rows` — data-
    // dependent (see this task's own precondition: seed one if the dev DB
    // has none).
    page: "/admin/estantes/administrar",
    overlayId: "shelf-options-sheet",
    dataIndependent: false,
    steps: [{ kind: "click", selector: "#administrar-rows .pk-admin-row" }],
  },
  {
    // Opens the SAME shelf row's options sheet, then its `ask-delete`
    // control — which only OPENS `dialog/1`'s `confirm-delete-shelf-
    // dialog`, never commits it. The confirm control itself
    // (`[phx-click="confirm-delete"]`) is never targeted by this walk.
    page: "/admin/estantes/administrar",
    overlayId: "confirm-delete-shelf-dialog",
    dataIndependent: false,
    steps: [
      { kind: "click", selector: "#administrar-rows .pk-admin-row" },
      { kind: "click", selector: '#shelf-options-sheet [phx-click="ask-delete"]' },
    ],
  },
  {
    // Requires a real search hit, and the picked copy must already be
    // PLACED on a shelf (`select_copy_struct/2` opens «¿Dónde va?»
    // instead of the rail for an unplaced copy) — data-dependent on both
    // counts. `[data-pk-rail-selected="true"]` is the rail's own marker
    // for "this is the currently selected copy" (`estante_live/index.ex`'s
    // `data-pk-rail-selected={to_string(copy.id == @selected_copy.id)}`)
    // — it resolves to whichever copy was just picked without hard-coding
    // a copy id, satisfying this row's own "derive from the DOM" contract.
    // Once the copy is selected, that SAME button's `phx-click` flips from
    // `pick-copy` to `open-cover-options`, so clicking it a second time
    // opens the sheet. The query below deliberately names a real game
    // rather than a bare single letter: a one-letter query against a dev
    // catalog with only ONE placed copy is very likely to surface an
    // UNPLACED game first (`search_copies/1` orders by name, not by
    // placement) — which opens «¿Dónde va?» instead, a false not-openable
    // that says nothing about this call site's real coverage. Naming the
    // one seeded, placed copy's own game removes that ambiguity; if the
    // dev catalog has no placed copies at all, this row still correctly
    // reports not-openable (see this task's own precondition).
    page: "/admin/estantes",
    overlayId: "cover-options-sheet",
    dataIndependent: false,
    steps: [
      { kind: "type", selector: "#estantes-search-input", value: "carcassonne" },
      { kind: "click", selector: "#estantes-suggestions [data-pk-pressable]" },
      { kind: "click", selector: '[data-pk-rail-selected="true"]' },
    ],
  },
  {
    // Requires at least one weight-band mismatch in the dev catalog.
    page: "/admin/niveles",
    overlayId: "niveles-sheet",
    dataIndependent: false,
    steps: [{ kind: "click", selector: "#band-mismatches .pk-admin-row" }],
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
// Plan 01.8.3-10 — G-01.8.3-4b: the sheet's BODY must share its own HEADER's
// horizontal keel. `.pk-admin-sheet__header` declares `padding: 0 16px 8px`;
// its sibling `.pk-admin-sheet__rows` (wrapping the default slot) declares
// only vertical padding — the sheet's keel is delegated IMPLICITLY to
// whatever the caller renders. A form-shaped body (no self-insetting child
// at its root) renders at x=0; a row-shaped body (`.pk-admin-row`/
// `.pk-admin-action--a4` at its root) self-insets 16px and reads correctly
// today, by design (A4's own anatomy is "48px, full-bleed, commit-first").
//
// Reuses `runOpenerSteps`/`isOverlayOpen`/`setViewport`/`navigate`/
// `pollUntil` from the G-01.8.3-2b overlay-coverage walk above — this is not
// a second opener mechanism.
// ---------------------------------------------------------------------------

// Same row shape as `OVERLAY_CALL_SITES` plus `bodyShape` ('form' | 'row' |
// 'mixed') — which of Task 2's two governing declarations this call site's
// body falls under ('mixed' names a body this plan's fix does not fully
// reach — see `donde-va-sheet` below). `staff-options-sheet` requires a
// staff-role user other than the operator (this task's own precondition):
// `phx-click` is only rendered on a row when `user.role == :staff`
// (`staff_live/index.ex`), so `[phx-click]` is present ONLY for such rows —
// if the dev DB has none, the selector never appears and the walk correctly
// reports NOT-OPENABLE (dataIndependent: false) rather than a false FAIL or
// a silent skip.
//
// Task 3 (the sweep) added `donde-va-sheet` below and a dynamically-
// resolved editor sheet (built in `main()`, since its URL is a real game
// id resolved off `/admin/juegos`, not a static route). Destructive events
// this whole table's steps must NEVER reach, taken from the templates read
// for this sweep: `add-game` (submits a game), `confirm-delete`/`confirm-
// quitar`/`confirm-remove` (deletes a shelf / un-places a copy / removes
// staff), `donde-va-commit` (commits a placement), `choice-select` (D-30:
// choosing IN a `.pk-editor-opt` sheet commits and closes immediately —
// no row inside an opened editor sheet is ever clicked here), and
// `confirm-discard`/`confirm-retire`. Every row below stops at OPENING its
// sheet.
const SHEET_KEEL_CALL_SITES = [
  {
    page: "/admin/juegos",
    overlayId: "add-game-sheet",
    dataIndependent: true,
    bodyShape: "form",
    steps: [{ kind: "click", selector: "#juegos-add-action" }],
  },
  {
    // `open-new-shelf` renders unconditionally in the header actions
    // regardless of shelf count — data-independent (mirrors
    // `OVERLAY_CALL_SITES`'s own row for this same opener).
    page: "/admin/estantes/administrar",
    overlayId: "shelf-name-sheet",
    dataIndependent: true,
    bodyShape: "form",
    steps: [{ kind: "click", selector: '[phx-click="open-new-shelf"]' }],
  },
  {
    // Requires at least one real shelf row in `#administrar-rows` — data-
    // dependent (this task's own precondition).
    page: "/admin/estantes/administrar",
    overlayId: "shelf-options-sheet",
    dataIndependent: false,
    bodyShape: "row",
    steps: [{ kind: "click", selector: "#administrar-rows .pk-admin-row" }],
  },
  {
    // Requires a staff-role user other than the operator — see this
    // table's own header comment. `#staff-list .pk-admin-row[phx-click]`
    // matches only a row that actually renders the attribute (staff role),
    // never the operator's own owner-role row, which renders no
    // `phx-click` at all.
    page: "/admin/staff",
    overlayId: "staff-options-sheet",
    dataIndependent: false,
    bodyShape: "row",
    steps: [{ kind: "click", selector: "#staff-list .pk-admin-row[phx-click]" }],
  },
  {
    // Task 3 — `placement_sheet/1`'s «¿Dónde va?», the `.pk-donde-va-search`
    // change's own call site. `pick-copy` on an UNPLACED copy opens THIS
    // sheet (`estante_live/index.ex`'s `open_donde_va/2`) rather than
    // `cover-options-sheet` (which needs an already-PLACED copy — see
    // `OVERLAY_CALL_SITES`'s own comment for why that row searches
    // "carcassonne" specifically). The dev catalog has 435 copies and only
    // 1 placed, so almost any other real game name resolves to an
    // unplaced copy — data-dependent since it still needs a search hit.
    // `bodyShape: "mixed"`: the search field is a direct child (governed
    // by Task 2's `.pk-donde-va-search` fix) but its estante-list rows
    // render inside a plain, unpadded wrapper div (`#donde-va-estante-
    // list`) — a GRANDCHILD of `.pk-admin-sheet__rows`, not a direct
    // child, so Task 2's direct-child-only compensation does not reach
    // them. See this sweep's own recorded finding below.
    page: "/admin/estantes",
    overlayId: "donde-va-sheet",
    dataIndependent: false,
    bodyShape: "mixed",
    steps: [
      { kind: "type", selector: "#estantes-search-input", value: "catan" },
      { kind: "click", selector: "#estantes-suggestions [data-pk-pressable]" },
    ],
  },
]

// A row-shaped body's own full-bleed children — excluded from Test 3
// (nothing [non-full-bleed] reaches the panel edge) and the SUBJECT of
// Test 5 (the full-bleed press surface positive control) instead. Covers
// both D-19e/A4's shared anatomy AND `.pk-editor-opt` (Task 3's editor
// choice sheet — a distinct class, same full-bleed contract: `editor.css`
// re-expresses its `margin`/`padding` through the same keel property this
// plan's components.css fix uses). Shared as a literal string (not a
// helper) per this file's established convention of a self-contained
// `evalJS` body per function.
const SHEET_FULL_BLEED_SELECTOR = ".pk-admin-row, .pk-admin-action--a4, .pk-editor-opt"

// The measurement body for one already-open sheet: the panel's own border
// box; the header's content box (`edges()`-shaped: left absolute, right an
// inset); the header title's own INK left (rule 7, a text Range, never a
// box); the body wrapper's content box, its own computed `padding`
// (deliberately the raw shorthand string — `"8px 0px"` is the single most
// legible proof of both the defect and the fix), and its `scrollWidth`/
// `clientWidth`; every body descendant that is either a direct child or a
// focusable control (deduped by node identity, never double-counted); the
// leftmost ink-or-control edge inside the body, derived by walking the real
// DOM rather than a per-call-site selector list (rule 7) — the winning
// element's own tag/id is reported so a selector mismatch cannot silently
// report a false pass; and, for a row-shaped body, the full-bleed child's
// own border box and its own ink left (Test 5's positive control).
async function measureSheetKeel(client, overlayId) {
  const json = await evalJS(
    client,
    `
    JSON.stringify((() => {
      function round(n) { return Math.round(n * 10) / 10; }
      function contentEdges(el) {
        if (!el) return null;
        const r = el.getBoundingClientRect();
        const cs = getComputedStyle(el);
        const pl = parseFloat(cs.paddingLeft) || 0;
        const pr = parseFloat(cs.paddingRight) || 0;
        return { left: round(r.left + pl), right: round(window.innerWidth - (r.right - pr)) };
      }
      function absBox(el) {
        const r = el.getBoundingClientRect();
        return { left: round(r.left), right: round(r.right), width: round(r.width) };
      }
      function textInk(el) {
        if (!el) return null;
        const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
        // Skip whitespace-only text nodes rather than giving up on the
        // first one found (Rule 1 — found via Task 3's own sweep run):
        // .pk-editor-opt's real label text sits two levels deep
        // (<button><span class="pk-editor-opt__text"><span
        // class="pk-editor-opt__label">Ligero</span>...) and the FIRST
        // text node in document order can be a template-emitted blank one.
        let node = walker.nextNode();
        while (node && (!node.nodeValue || !node.nodeValue.trim())) {
          node = walker.nextNode();
        }
        if (!node) return null;
        const range = document.createRange();
        range.selectNodeContents(node);
        return range.getBoundingClientRect();
      }

      const root = document.getElementById(${JSON.stringify(overlayId)});
      if (!root) return { found: false };
      const panel = root.querySelector('[data-pk-sheet-panel]');
      const header = root.querySelector('.pk-admin-sheet__header');
      const titleEl = root.querySelector('.pk-admin-sheet__title');
      const body = root.querySelector('.pk-admin-sheet__rows');
      if (!panel || !header || !body) {
        return { found: false, panelFound: !!panel, headerFound: !!header, bodyFound: !!body };
      }

      const FOCUSABLE_SELECTOR = 'a[href], button, input, select, textarea, [tabindex]';
      const FULL_BLEED_SELECTOR = ${JSON.stringify(SHEET_FULL_BLEED_SELECTOR)};

      const panelBox = absBox(panel);
      const headerEdges = contentEdges(header);
      const titleInk = textInk(titleEl);
      const bodyEdges = contentEdges(body);
      const bodyCs = getComputedStyle(body);

      // Union of direct children + focusable descendants, deduped by node
      // identity (a button that is both a direct child AND itself
      // focusable must not be measured twice).
      const nodeSet = new Set([...body.children, ...body.querySelectorAll(FOCUSABLE_SELECTOR)]);
      const descendants = [...nodeSet].map((el) => ({
        tag: el.tagName.toLowerCase(),
        id: el.id || null,
        className: typeof el.className === 'string' ? el.className : null,
        isFullBleed: el.matches(FULL_BLEED_SELECTOR),
        box: absBox(el),
      }));

      // The leftmost ink-or-control edge inside the body: walk EVERY
      // descendant element, keep a focusable control (its own border-box
      // left) or an element carrying a non-empty OWN text node (its ink
      // left via textInk), and take the minimum. Reports the winning
      // element's tag/id so the transcript can name it.
      const candidates = [];
      const walker = document.createTreeWalker(body, NodeFilter.SHOW_ELEMENT);
      let node = walker.currentNode;
      while (node) {
        if (node !== body) {
          // Ink beats box whenever the element carries its own text: a
          // full-bleed pk-admin-action--a4 button IS a focusable control,
          // but its border box is DELIBERATELY edge-to-edge (D-19e's
          // anatomy) while its own 16px padding insets the ink that is
          // actually seen — measuring the box here would report the
          // full-bleed anatomy itself as a misalignment. Only an element
          // with NO text of its own (a bare input, whose visible painted
          // border IS its box) falls back to the border-box edge.
          const hasOwnText = [...node.childNodes].some(
            (n) => n.nodeType === Node.TEXT_NODE && n.nodeValue && n.nodeValue.trim(),
          );
          if (hasOwnText) {
            const ink = textInk(node);
            if (ink && ink.width > 0) {
              candidates.push({ left: ink.left, tag: node.tagName.toLowerCase(), id: node.id || null, kind: 'ink' });
            }
          } else if (node.matches(FOCUSABLE_SELECTOR) && !node.matches(FULL_BLEED_SELECTOR)) {
            // A full-bleed control (.pk-editor-opt is the case that
            // surfaced this — Rule 1, Task 3's sweep) is EXCLUDED here even
            // when its own immediate children carry no direct text node:
            // its border box is deliberately edge-to-edge, and its real
            // ink sits two levels deeper (a nested label span) — the
            // TreeWalker continues into that subtree on its own next
            // iterations, where the label's own hasOwnText branch above
            // picks up the real ink. Treating the full-bleed node itself
            // as a "control" here would report its edge-to-edge BOX as if
            // it were content, exactly the same misreading Test 3 already
            // guards against on the other axis.
            const r = node.getBoundingClientRect();
            candidates.push({ left: r.left, tag: node.tagName.toLowerCase(), id: node.id || null, kind: 'control' });
          }
        }
        node = walker.nextNode();
      }
      let leftmost = null;
      for (const c of candidates) {
        if (!leftmost || c.left < leftmost.left) leftmost = c;
      }

      // Test 5's positive control: the row-shaped body's own full-bleed
      // child, if any.
      const fullBleedEl = [...nodeSet].find((el) => el.matches(FULL_BLEED_SELECTOR));
      const fullBleedInk = fullBleedEl ? textInk(fullBleedEl) : null;

      return {
        found: true,
        panelBox,
        headerEdges,
        titleInkLeft: titleInk ? round(titleInk.left) : null,
        bodyEdges,
        bodyPadding: bodyCs.padding,
        bodyScrollWidth: body.scrollWidth,
        bodyClientWidth: body.clientWidth,
        descendants,
        leftmost: leftmost ? { left: round(leftmost.left), tag: leftmost.tag, id: leftmost.id, kind: leftmost.kind } : null,
        fullBleedBox: fullBleedEl ? absBox(fullBleedEl) : null,
        fullBleedInkLeft: fullBleedInk ? round(fullBleedInk.left) : null,
      };
    })())
  `,
  )
  return JSON.parse(json)
}

// Drives `SHEET_KEEL_CALL_SITES` end to end: for each row, navigate fresh,
// run its opener steps, poll until its overlay's resolved `display` is not
// `none`, then run the five sheet-keel tests against the real, really-open
// sheet. Prints one verdict line per open sheet (every measured number) and
// a summary naming how many rows were attempted vs. not-openable.
async function checkSheetKeel({ client, baseUrl, rows }) {
  const fails = []
  const notOpenable = []
  const fail = (msg) => {
    fails.push(msg)
    log(`FAIL: ${msg}`)
  }

  for (const row of rows) {
    await setViewport(client, 390, 844)
    await navigate(client, `${baseUrl}${row.page}`)
    await new Promise((r) => setTimeout(r, 250))

    const openResult = await runOpenerSteps(client, row.steps)
    if (!openResult.openable) {
      if (row.dataIndependent) {
        fail(
          `${row.page} ${row.overlayId}: opener selector never appeared (${openResult.missingSelector}) — this opener renders unconditionally, so its absence means the walk itself is broken, not that dev data is thin`,
        )
      } else {
        notOpenable.push({ page: row.page, overlayId: row.overlayId, missingSelector: openResult.missingSelector })
        log(
          `NOT-OPENABLE: ${row.page} ${row.overlayId}: opener selector never appeared (${openResult.missingSelector}) — dev data is likely too thin for this row`,
        )
      }
      continue
    }

    const opened = await pollUntil(() => isOverlayOpen(client, row.overlayId))
    if (!opened) {
      fail(`${row.page} ${row.overlayId}: opener steps completed but the overlay never reached a resolved display other than 'none'`)
      continue
    }

    const m = await measureSheetKeel(client, row.overlayId)
    if (!m.found) {
      fail(
        `${row.page} ${row.overlayId}: overlay reported open but its panel/header/body could not all be found (panel=${m.panelFound}, header=${m.headerFound}, body=${m.bodyFound})`,
      )
      continue
    }

    const nameOf = (d) => `<${d.tag}${d.id ? "#" + d.id : d.className ? "." + d.className.split(" ")[0] : ""}>`
    log(
      `sheet keel ${row.page} ${row.overlayId} (${row.bodyShape}-shaped): panel=[${m.panelBox.left},${m.panelBox.right}]; ` +
        `header content=[${m.headerEdges.left},${m.headerEdges.right}] title ink left=${m.titleInkLeft}; ` +
        `body content=[${m.bodyEdges.left},${m.bodyEdges.right}] body padding="${m.bodyPadding}" scrollWidth=${m.bodyScrollWidth} clientWidth=${m.bodyClientWidth}; ` +
        `leftmost=${m.leftmost ? `${m.leftmost.kind}${nameOf(m.leftmost)}@${m.leftmost.left}` : "(none)"}`,
    )

    // Test 1 — the two siblings agree: header content edges == body content
    // edges. FAILS today on every sheet regardless of body shape — the
    // body wrapper itself has zero horizontal padding no matter what its
    // children do.
    if (Math.abs(m.headerEdges.left - m.bodyEdges.left) > 0.5) {
      fail(`${row.page} ${row.overlayId} test1 (header-vs-body content left): header=${m.headerEdges.left}px body=${m.bodyEdges.left}px, expected within 0.5px`)
    }
    if (Math.abs(m.headerEdges.right - m.bodyEdges.right) > 0.5) {
      fail(`${row.page} ${row.overlayId} test1 (header-vs-body content right inset): header=${m.headerEdges.right}px body=${m.bodyEdges.right}px, expected within 0.5px`)
    }

    // Test 2 — ink agrees with ink: the leftmost ink/control edge inside
    // the body equals the header's OWN CONTENT EDGE — not the title
    // glyph's own ink specifically (Rule 1, found via Task 3's own sweep
    // run: `placement_sheet/1` renders a leading `cover` image, which
    // pushes the title text itself right of the header's content edge
    // by the cover's own width+gap — 84px, not 16 — even though the
    // header's content edge, per Test 1, is still 16 there. Comparing
    // against the title's own ink specifically would report a cover-
    // bearing sheet as misaligned when it is not; `m.headerEdges.left`
    // is cover-invariant and is what G-01.8.3-4b's own truth actually
    // names — "the title AND the close X share one left/right
    // alignment" is the header's established axis, which the title
    // happens to sit flush against only when nothing precedes it).
    // FAILS today for a form-shaped body (its leftmost control sits at
    // x=0); a row-shaped body's own full-bleed child already self-insets
    // to 16px and PASSES today.
    if (m.headerEdges.left == null || !m.leftmost) {
      fail(`${row.page} ${row.overlayId} test2: could not measure the header content edge (${m.headerEdges.left}) or the body's leftmost ink/control (${m.leftmost})`)
    } else if (Math.abs(m.headerEdges.left - m.leftmost.left) > 0.5) {
      fail(
        `${row.page} ${row.overlayId} test2 (ink-vs-ink): header content edge left=${m.headerEdges.left}px, body leftmost ${m.leftmost.kind}${nameOf(m.leftmost)} left=${m.leftmost.left}px, expected within 0.5px`,
      )
    }

    // Test 3 — nothing (non-full-bleed) reaches the panel edge: every body
    // descendant that is NOT a `.pk-admin-row`/`.pk-admin-action--a4` full-
    // bleed child must sit inset from the panel's own border box by more
    // than 0.5px on both sides. Full-bleed children are deliberately
    // excluded here — they are Test 5's own positive control, not a
    // violation of this test. FAILS today for a form-shaped body: its
    // field/button render exactly flush with the panel (0px inset both
    // sides, the zero-horizontal-padding defect).
    for (const d of m.descendants) {
      if (d.isFullBleed) continue
      const leftInset = round2(d.box.left - m.panelBox.left)
      const rightInset = round2(m.panelBox.right - d.box.right)
      if (leftInset < 0.5 || rightInset < 0.5) {
        fail(
          `${row.page} ${row.overlayId} test3 (nothing reaches the panel edge): ${nameOf(d)} left inset=${leftInset}px right inset=${rightInset}px vs panel=[${m.panelBox.left},${m.panelBox.right}], expected both > 0.5px`,
        )
      }
    }

    // Test 4 — no horizontal scroll: the body's scrollWidth must not
    // exceed its clientWidth by more than 0.5px. PASSES today; the control
    // proving the fix's compensating negative margins (Task 2) do not
    // introduce a horizontal scroller.
    if (m.bodyScrollWidth - m.bodyClientWidth > 0.5) {
      fail(`${row.page} ${row.overlayId} test4 (no horizontal scroll): scrollWidth=${m.bodyScrollWidth}px clientWidth=${m.bodyClientWidth}px, expected scrollWidth <= clientWidth + 0.5px`)
    }

    // Test 5 — the row-shaped rows are a second control: for a row-shaped
    // body, the full-bleed child's own border box still spans the panel's
    // full width (the press surface) while its own ink sits on the
    // header's axis. PASSES today and must still pass after Task 2's fix —
    // this is what makes the compensation verifiable instead of assumed.
    if (row.bodyShape === "row") {
      if (!m.fullBleedBox) {
        fail(`${row.page} ${row.overlayId} test5: no .pk-admin-row/.pk-admin-action--a4 descendant found in a row-shaped body`)
      } else {
        if (Math.abs(m.fullBleedBox.left - m.panelBox.left) > 0.5 || Math.abs(m.fullBleedBox.right - m.panelBox.right) > 0.5) {
          fail(
            `${row.page} ${row.overlayId} test5 (full-bleed press surface): row/action box=[${m.fullBleedBox.left},${m.fullBleedBox.right}] vs panel=[${m.panelBox.left},${m.panelBox.right}], expected edge-to-edge within 0.5px`,
          )
        }
        // Header's own content edge, not the title glyph's ink — see
        // Test 2's own comment for why (cover-bearing sheets push the
        // title right without moving the header's established axis).
        if (m.fullBleedInkLeft == null || m.headerEdges.left == null) {
          fail(`${row.page} ${row.overlayId} test5: could not measure the row/action's own ink (${m.fullBleedInkLeft}) or the header content edge (${m.headerEdges.left})`)
        } else if (Math.abs(m.fullBleedInkLeft - m.headerEdges.left) > 0.5) {
          fail(
            `${row.page} ${row.overlayId} test5 (ink on header axis): row/action ink left=${m.fullBleedInkLeft}px header content edge left=${m.headerEdges.left}px, expected within 0.5px`,
          )
        }
      }
    }

    // Fresh navigation so no residual overlay/LiveView state leaks into the
    // next row's measurement (mirrors `checkOverlayRealOpenWalk`'s own
    // convention).
    await navigate(client, `${baseUrl}${row.page}`)
  }

  log(`sheet keel walk: attempted=${rows.length} not-openable=${notOpenable.length}`)
  return { fails, notOpenable }
}

function round2(n) {
  return Math.round(n * 10) / 10
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
// Plan 01.8.3-08 [Rule 1 - Bug]: this function measures `<main>`'s OWN
// horizontal padding (`main .mx-auto.w-full.max-w-3xl`'s rect, at each of
// D-19n's/079's named widths) — it is NOT "the content keel" despite the
// name below, and it can say nothing about content-level insets. D-20b
// (G-01.8.3-2c, DEBUG-juegos-horizontal-keel-three-axes.md) proved that
// page content on every non-fullbleed admin page actually renders at 32px
// viewport-relative (this same 16px padding PLUS each component's own 16px
// self-inset) — a quantity this function structurally cannot see, since it
// only reads the padding being doubled, not the doubled result. `PAGES`
// (above) EXCLUDES the one fullbleed admin page (the editor, `form.ex:1177`)
// BY CONSTRUCTION, where `main` contributes 0px and the same components
// land on 16px instead — so this check can say nothing about the editor
// either. See `measureJuegosKeelAt` below for the viewport-relative,
// D-20b-accurate content-keel measurement this function's own name used to
// falsely promise.
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

// Plan 01.8.3-08 [Rule 1 - Bug, G-01.8.3-2c]: every number below is
// VIEWPORT-relative — for each measured element, `left` is its own
// content-box left edge in viewport coordinates and `right` is
// `window.innerWidth` minus its content-box right edge. NO container rect
// is subtracted and NO padding is added back. The PREVIOUS form of this
// function measured relative to `.pk-admin-juegos`'s own box and added the
// element's own padding back, on the theory that `<main>`'s 16px would
// otherwise "silently double every reading to 32px" — but D-20b
// (DEBUG-juegos-horizontal-keel-three-axes.md, `probe_vs_eye`) proved that
// container-relative 16 was a quantity that existed NOWHERE on the
// rendered page: the caption band painted at 16 while the row it should
// match painted at 32, and this function's own netted-out reading of "16"
// for both was exactly what let that regression ship past a passing guard.
// D-20b declares the admin's keel as 32px measured exactly this way, on
// any page that is not `fullbleed` (the one exception is the editor,
// `form.ex:1177`, which this function does not visit).
//
// The band's and the divider's painted edges are both derived the same
// way: `hostRect.left + used(::before left)` for the left edge, and
// `innerWidth - (hostRect.right - used(::before right))` for the right
// inset — read off `getComputedStyle(host, '::before')`, the SAME
// mechanism `measureJuegosSectionPinned` below already trusts for the
// band's own `top`/`bottom`. The band's host is the section's own header
// (`.pk-admin-juegos-section-header`, `position: relative`, the `::before`
// pseudo-element's containing block); the divider's host is the SECOND row
// in the same section's rows list (`.pk-admin-row + .pk-admin-row`, the
// only rows that carry the hairline `::before`) — both resolved from the
// SAME section as the measured row/searchRow, via `.closest(...)`, so a
// page where a different section happens to be the one currently expanded
// (Borradores/Retirados start collapsed; only Juegos del club never is)
// never silently compares one section's band against a different
// section's rows.
async function measureJuegosKeelAt({ client, baseUrl, width }) {
  await setViewport(client, width, 844)
  await navigate(client, `${baseUrl}/admin/juegos`)
  const json = await pollUntil(async () => {
    const raw = await evalJS(
      client,
      `
      JSON.stringify((() => {
        const row = document.querySelector('.pk-admin-juegos-rows .pk-admin-row');
        const searchRow = document.querySelector('.pk-admin-juegos-search-row');
        if (!row || !searchRow) return null;
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
      function edges(el) {
        if (!el) return null;
        const r = el.getBoundingClientRect();
        const cs = getComputedStyle(el);
        const pl = parseFloat(cs.paddingLeft) || 0;
        const pr = parseFloat(cs.paddingRight) || 0;
        return {
          left: Math.round((r.left + pl) * 10) / 10,
          right: Math.round((window.innerWidth - (r.right - pr)) * 10) / 10,
        };
      }
      // Local copy of measureJuegosSectionPinned's own textInk helper — this
      // directory's established convention is a self-contained copy per
      // function, not a shared import across functions (rule 7: measure
      // ink, not boxes).
      function textInk(el) {
        if (!el) return null;
        const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
        const node = walker.nextNode();
        if (!node || !node.nodeValue || !node.nodeValue.trim()) return null;
        const range = document.createRange();
        range.selectNodeContents(node);
        return range.getBoundingClientRect();
      }

      // Plan 01.8.3-09 [G-01.8.3-2e]: viewport-relative BORDER-BOX rects for
      // the search cluster's own visible controls — never the search row
      // CONTAINER's content box ('searchRow' above already agrees with the
      // rows at 32/32 and is exactly why the shipped probe reported this
      // screen as passing; the defect lives on boxes this function never
      // read until now). 'left'/'right' here are the box's own edges in
      // viewport coordinates (no padding math — border-box, not content-box)
      // and 'width' is the box's own rendered width.
      function borderBoxEdges(el) {
        if (!el) return null;
        const r = el.getBoundingClientRect();
        return {
          left: Math.round(r.left * 10) / 10,
          right: Math.round((window.innerWidth - r.right) * 10) / 10,
          width: Math.round(r.width * 10) / 10,
        };
      }

      const rowsWrap = document.querySelector('.pk-admin-juegos-rows');
      const rows = rowsWrap ? [...rowsWrap.querySelectorAll('.pk-admin-row')] : [];
      const row = rows[0] || null;
      const secondRow = rows[1] || null;
      const searchRow = document.querySelector('.pk-admin-juegos-search-row');
      const section = row ? row.closest('.pk-admin-juegos-section') : null;
      const header = section ? section.querySelector('.pk-admin-juegos-section-header') : null;
      const captionLabel = header ? header.querySelector('.pk-admin-list-section-label') : null;
      const cover = row ? row.querySelector('.pk-admin-row__cover') : null;
      const chevron = row ? row.querySelector('.pk-admin-row__chevron') : null;
      const rowCs = row ? getComputedStyle(row) : null;

      // Plan 01.8.3-09 [G-01.8.3-2e]: the field, the '+' button, and the
      // '+'s own glyph — the three boxes the fix actually changes. The
      // glyph lookup mirrors the A3 glyph rule's own selector
      // ('.pk-admin-action--a3 [class^="hero-"], .pk-admin-action--a3
      // [class*=" hero-"]', components.css); icon/1 (core_components.ex)
      // renders a span, never an svg. Falls back to the button's
      // first element child, reporting the fallback rather than silently
      // measuring the box instead of the glyph (rule 8's substitution
      // mechanism).
      const searchInput = document.getElementById('juegos-search-input');
      const addAction = document.getElementById('juegos-add-action');
      let glyph = addAction ? addAction.querySelector('[class^="hero-"], [class*=" hero-"]') : null;
      let glyphIsFallback = false;
      if (addAction && !glyph) {
        glyph = addAction.firstElementChild;
        glyphIsFallback = true;
      }

      let bandLeft = null, bandRightInset = null;
      if (header) {
        const hr = header.getBoundingClientRect();
        const beforeCs = getComputedStyle(header, '::before');
        const l = parseFloat(beforeCs.left);
        const rr = parseFloat(beforeCs.right);
        bandLeft = Math.round((hr.left + (Number.isNaN(l) ? 0 : l)) * 10) / 10;
        bandRightInset = Math.round((window.innerWidth - (hr.right - (Number.isNaN(rr) ? 0 : rr))) * 10) / 10;
      }

      let dividerLeft = null, dividerRightInset = null;
      if (secondRow) {
        const dr = secondRow.getBoundingClientRect();
        const dcs = getComputedStyle(secondRow, '::before');
        const l = parseFloat(dcs.left);
        const rr = parseFloat(dcs.right);
        dividerLeft = Math.round((dr.left + (Number.isNaN(l) ? 0 : l)) * 10) / 10;
        dividerRightInset = Math.round((window.innerWidth - (dr.right - (Number.isNaN(rr) ? 0 : rr))) * 10) / 10;
      }

      const captionInkRect = textInk(captionLabel);

      return {
        row: edges(row),
        searchRow: edges(searchRow),
        coverLeft: cover ? Math.round(cover.getBoundingClientRect().left * 10) / 10 : null,
        coverWidth: cover ? Math.round(cover.getBoundingClientRect().width * 10) / 10 : null,
        chevronRightInset: chevron ? Math.round((window.innerWidth - chevron.getBoundingClientRect().right) * 10) / 10 : null,
        captionInkLeft: captionInkRect ? Math.round(captionInkRect.left * 10) / 10 : null,
        columnGap: rowCs ? (parseFloat(rowCs.columnGap) || 0) : null,
        bandLeft, bandRightInset,
        dividerLeft, dividerRightInset,
        searchInput: borderBoxEdges(searchInput),
        addAction: borderBoxEdges(addAction),
        glyph: borderBoxEdges(glyph),
        glyphIsFallback,
      };
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

// Scrolls the given section's caption into its pinned state via a REAL
// incremental scroll-down (never a single jump — admin_list.js's onScroll
// only sees a real `goingDown` direction across successive scroll events,
// exactly what a finger does), reads every DOWN-state geometry fact a real
// scrolling user actually sees, then scrolls back UP in real increments
// (the scroll-up differential control, same session, same section) and
// reads the UP-state geometry too — both states returned from one call so
// the differential between them is never assembled from two independent
// runs.
//
// Plan 01.8.3-11 [T-01.8.3-34]: this function used to drive the page OUT
// of the hidden state before measuring — `searchInputEl.focus({
// preventScroll: true })` plus a synthetic `new Event('scroll')`,
// justified by its own comment as "needed for the band/search-row
// adjacency measurement". That hack manufactured the passing condition for
// EVERY band and search-row number this function ever reported (rule 8's
// first mechanism, test/visual/README.md) and is the direct cause of
// G-01.8.3-2d/G-01.8.3-3's blind spot: `searchHidden` and the absolute
// `bandTop` were already measured and printed on every run, and nothing
// ever asserted on them. Both are deleted. Any future edit needing the
// un-hidden state must reach it by a REAL scroll-up, exactly as the
// differential control below does — never by focusing the input or
// dispatching a synthetic event.
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

      // Plan 01.8.3-11: real incremental scroll, never a single jump. A
      // bare window.scrollTo(0, target) reaches the target in one paint —
      // exactly the "single jump" the plan's own <behavior> rules out,
      // since it is not what a finger does across successive real scroll
      // events. This helper walks toward targetY in steps no larger than
      // maxStep, yielding a frame plus a short settle between each one.
      async function scrollStep(targetY, maxStep) {
        const maxScroll = Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
        const clamped = Math.min(Math.max(0, targetY), maxScroll);
        let guard = 0;
        while (Math.abs(window.scrollY - clamped) > 0.5 && guard < 500) {
          const remaining = clamped - window.scrollY;
          const delta = Math.abs(remaining) > maxStep ? Math.sign(remaining) * maxStep : remaining;
          window.scrollTo(0, window.scrollY + delta);
          await new Promise((r) => requestAnimationFrame(r));
          await new Promise((r) => setTimeout(r, 40));
          guard++;
        }
        return window.scrollY;
      }

      // Phase 1: walk incrementally to roughly 250px past the section's
      // own natural top (the same overshoot the old single-jump target
      // used, now reached via real steps instead of one paint).
      const phase1Target = naturalTop - pinnedH + 250;
      await scrollStep(phase1Target, 45);

      // Phase 2: creep the rest of the way in <=45px steps until the wrap
      // itself reports pinned — the try cap and rich error payload for the
      // never-pinned case are unchanged from before this plan.
      let pinned = wrap.getAttribute('data-pinned') === 'true';
      let tries = 0;
      let lastScrollY = window.scrollY;
      while (!pinned && tries < 60) {
        const maxScroll = Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
        const nextY = Math.min(window.scrollY + 45, maxScroll);
        if (nextY === window.scrollY) break;
        window.scrollTo(0, nextY);
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
            pinnedH, naturalTop, phase1Target, tries, lastScrollY,
            sentinelCount: document.querySelectorAll('[data-pk-section-sentinel]').length,
            sectionOuterHTMLLen: section.outerHTML.length,
            wrapAttrs: wrap.getAttributeNames(),
          },
        });
      }

      // ---- DOWN state: measured exactly where the real scroll left it.
      // No focus, no synthetic scroll event, no un-hide of any kind — this
      // is the state a scrolling user actually occupies. ----
      function textInkFull(el) {
        if (!el) return null;
        const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
        let node = walker.nextNode();
        while (node && (!node.nodeValue || !node.nodeValue.trim())) node = walker.nextNode();
        if (!node) return null;
        const range = document.createRange();
        range.selectNodeContents(node);
        return range.getBoundingClientRect();
      }

      const searchWrap = document.querySelector('#juegos-search-wrap');
      const searchHiddenDown = searchWrap ? searchWrap.hasAttribute('data-pinned-hidden') : null;
      const searchRectRawDown = searchWrap ? searchWrap.getBoundingClientRect() : null;
      const searchRectDown = searchRectRawDown
        ? { top: Math.round(searchRectRawDown.top * 10) / 10, bottom: Math.round(searchRectRawDown.bottom * 10) / 10 }
        : null;
      const transformDown = searchWrap ? getComputedStyle(searchWrap).transform : null;

      const headerRectDown = header.getBoundingClientRect();
      const beforeCsDown = getComputedStyle(header, '::before');
      const topOffsetDown = parseFloat(beforeCsDown.top) || 0;
      const bottomOffsetDown = parseFloat(beforeCsDown.bottom) || 0;
      const bandTopDown = Math.round((headerRectDown.top + topOffsetDown) * 10) / 10;
      const bandBottomDown = Math.round((headerRectDown.bottom - bottomOffsetDown) * 10) / 10;
      const bandHeightDown = Math.round((bandBottomDown - bandTopDown) * 10) / 10;
      const bandBgDown = beforeCsDown.backgroundColor;
      const bandSearchGapDown = searchRectDown ? Math.round((bandTopDown - searchRectDown.bottom) * 10) / 10 : null;

      // Plan 01.8.3-06's ink-inside-band reading, now taken in the DOWN
      // state (what a user actually sees while scrolling down) rather than
      // the old manufactured un-hidden state — algebraically the same
      // number either way (it depends only on header padding, never on the
      // search row's own visibility), but measured where it is claimed.
      const pinnedInkDown = textInkFull(labelElForInk);
      const inkGapAboveDown = pinnedInkDown ? Math.round((pinnedInkDown.top - bandTopDown) * 10) / 10 : null;
      const inkGapBelowDown = pinnedInkDown ? Math.round((bandBottomDown - pinnedInkDown.bottom) * 10) / 10 : null;

      const rowsWrap = section.querySelector('.pk-admin-juegos-rows');
      const rowsList = rowsWrap ? [...rowsWrap.querySelectorAll('.pk-admin-row')] : [];
      const firstRowBelow = rowsList[0] || null;
      const secondRowBelow = rowsList[1] || null;
      const rowHeightDown = firstRowBelow ? Math.round(firstRowBelow.getBoundingClientRect().height * 10) / 10 : null;

      function rowContentEdges(el) {
        if (!el) return null;
        const r = el.getBoundingClientRect();
        const cs = getComputedStyle(el);
        const pl = parseFloat(cs.paddingLeft) || 0;
        const pr = parseFloat(cs.paddingRight) || 0;
        return {
          left: Math.round((r.left + pl) * 10) / 10,
          right: Math.round((window.innerWidth - (r.right - pr)) * 10) / 10,
        };
      }
      const rowContentPinned = rowContentEdges(firstRowBelow);
      const beforeLeftRawDown = parseFloat(beforeCsDown.left);
      const beforeRightRawDown = parseFloat(beforeCsDown.right);
      const bandLeftPinned = Math.round((headerRectDown.left + (Number.isNaN(beforeLeftRawDown) ? 0 : beforeLeftRawDown)) * 10) / 10;
      const bandRightInsetPinned = Math.round(
        (window.innerWidth - (headerRectDown.right - (Number.isNaN(beforeRightRawDown) ? 0 : beforeRightRawDown))) * 10,
      ) / 10;
      let dividerLeftPinned = null, dividerRightInsetPinned = null;
      if (secondRowBelow) {
        const dr = secondRowBelow.getBoundingClientRect();
        const dcs = getComputedStyle(secondRowBelow, '::before');
        const dLeftRaw = parseFloat(dcs.left);
        const dRightRaw = parseFloat(dcs.right);
        dividerLeftPinned = Math.round((dr.left + (Number.isNaN(dLeftRaw) ? 0 : dLeftRaw)) * 10) / 10;
        dividerRightInsetPinned = Math.round((window.innerWidth - (dr.right - (Number.isNaN(dRightRaw) ? 0 : dRightRaw))) * 10) / 10;
      }

      // Test 3: an elementFromPoint sweep of the strip between the
      // viewport top and the band's own top — every whole pixel when that
      // strip is <=60px tall (the shipped defect's own magnitude), or at
      // least 12 evenly-spaced points otherwise, since a fixed 5-point
      // sample can straddle a row boundary and miss.
      const bandTopFloorDown = Math.floor(bandTopDown);
      const sweepYs = [];
      if (bandTopFloorDown > 0) {
        if (bandTopFloorDown <= 60) {
          for (let y = 1; y < bandTopFloorDown; y++) sweepYs.push(y);
        } else {
          const n = 12;
          for (let i = 1; i <= n; i++) sweepYs.push(Math.round((bandTopFloorDown * i) / (n + 1)));
        }
      }
      const sweepX = Math.round(window.innerWidth / 2);
      const sweep = sweepYs.map((y) => {
        const el = document.elementFromPoint(sweepX, y);
        const rowEl = el ? el.closest('.pk-admin-row') : null;
        const hit = el ? (typeof el.className === 'string' && el.className ? el.tagName.toLowerCase() + '.' + el.className.split(' ')[0] : el.tagName.toLowerCase()) : null;
        return { y, insideRow: !!rowEl, hit };
      });
      const offendingYs = sweep.filter((s) => s.insideRow);

      // ---- UP state: the scroll-up differential control, same session,
      // same section. Scroll back up in REAL increments (never a jump)
      // until the hide attribute is gone, wait for the row's transform
      // transition to settle, then measure. ----
      function transformIsIdentity(transformStr) {
        if (!transformStr || transformStr === 'none') return true;
        try {
          const m = new DOMMatrixReadOnly(transformStr);
          return Math.abs(m.m41) < 0.5 && Math.abs(m.m42) < 0.5;
        } catch (e) {
          return false;
        }
      }

      let upTries = 0;
      let searchHiddenNow = searchWrap ? searchWrap.hasAttribute('data-pinned-hidden') : null;
      while (searchHiddenNow && upTries < 20) {
        const nextY = Math.max(0, window.scrollY - 45);
        if (nextY === window.scrollY) break;
        window.scrollTo(0, nextY);
        await new Promise((r) => requestAnimationFrame(r));
        await new Promise((r) => setTimeout(r, 80));
        searchHiddenNow = searchWrap ? searchWrap.hasAttribute('data-pinned-hidden') : null;
        upTries++;
      }
      let settleTries = 0;
      while (searchWrap && settleTries < 30) {
        if (transformIsIdentity(getComputedStyle(searchWrap).transform)) break;
        await new Promise((r) => setTimeout(r, 30));
        settleTries++;
      }

      const stillPinned = wrap.getAttribute('data-pinned') === 'true';
      if (!stillPinned) {
        return JSON.stringify({ error: 'section un-pinned while scrolling up for the differential control' });
      }

      const searchHiddenUp = searchWrap ? searchWrap.hasAttribute('data-pinned-hidden') : null;
      const searchRectRawUp = searchWrap ? searchWrap.getBoundingClientRect() : null;
      const searchRectUp = searchRectRawUp
        ? { top: Math.round(searchRectRawUp.top * 10) / 10, bottom: Math.round(searchRectRawUp.bottom * 10) / 10 }
        : null;
      const headerRectUp = header.getBoundingClientRect();
      const beforeCsUp = getComputedStyle(header, '::before');
      const topOffsetUp = parseFloat(beforeCsUp.top) || 0;
      const bottomOffsetUp = parseFloat(beforeCsUp.bottom) || 0;
      const bandTopUp = Math.round((headerRectUp.top + topOffsetUp) * 10) / 10;
      const bandSearchGapUp = searchRectUp ? Math.round((bandTopUp - searchRectUp.bottom) * 10) / 10 : null;

      return JSON.stringify({
        pinned, pinnedH,
        hasRowAbove: hasRowAboveForInk, airAbove, airBelow, airRatio,
        down: {
          searchHidden: searchHiddenDown,
          searchRect: searchRectDown,
          transform: transformDown,
          bandTop: bandTopDown, bandBottom: bandBottomDown, bandHeight: bandHeightDown,
          bandBg: bandBgDown, bandSearchGap: bandSearchGapDown,
          rowHeight: rowHeightDown,
          inkGapAbove: inkGapAboveDown, inkGapBelow: inkGapBelowDown,
          rowContentPinned, bandLeftPinned, bandRightInsetPinned,
          dividerLeftPinned, dividerRightInsetPinned,
          sweep, offendingYs,
        },
        up: {
          searchHidden: searchHiddenUp,
          searchRect: searchRectUp,
          bandTop: bandTopUp,
          bandSearchGap: bandSearchGapUp,
        },
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

  // ---- keel: a list row vs the pinned search row, plus the band/divider/
  // caption-ink tests, at 375/360/390 (D-20b: the declared keel is 32px,
  // viewport-relative, not 16 — see measureJuegosKeelAt's own header
  // comment for why). ----
  const keelByWidth = {}
  for (const width of KEEL_VIEWPORTS) {
    keelByWidth[width] = await measureJuegosKeelAt({ client, baseUrl, width })
    const {
      row,
      searchRow,
      coverLeft,
      coverWidth,
      chevronRightInset,
      captionInkLeft,
      columnGap,
      bandLeft,
      bandRightInset,
      dividerLeft,
      dividerRightInset,
      searchInput,
      addAction,
      glyph,
      glyphIsFallback,
    } = keelByWidth[width]
    if (!row || !searchRow) {
      fail(`juegos keel @ ${width}px: row or search-row not found (row=${!!row}, searchRow=${!!searchRow})`)
      continue
    }
    log(
      `juegos keel @ ${width}px: row left=${row.left} right=${row.right}; search row left=${searchRow.left} right=${searchRow.right}; ` +
        `cover left=${coverLeft} width=${coverWidth}; chevron right inset=${chevronRightInset}; caption ink left=${captionInkLeft}; ` +
        `row column-gap=${columnGap}; band left=${bandLeft} right inset=${bandRightInset}; divider left=${dividerLeft} right inset=${dividerRightInset}; ` +
        `search input left=${searchInput?.left} right inset=${searchInput?.right} width=${searchInput?.width}; ` +
        `add action left=${addAction?.left} right inset=${addAction?.right} width=${addAction?.width}; ` +
        `glyph left=${glyph?.left} right inset=${glyph?.right} width=${glyph?.width} (fallback=${glyphIsFallback})`,
    )
    if (row.left !== 32 || row.right !== 32) {
      fail(`juegos keel @ ${width}px: row content edges left=${row.left} right=${row.right}, expected 32/32 (D-20b)`)
    }
    if (searchRow.left !== 32 || searchRow.right !== 32) {
      fail(`juegos keel @ ${width}px: search row content edges left=${searchRow.left} right=${searchRow.right}, expected 32/32 (D-20b)`)
    }
    if (row.left !== searchRow.left || row.right !== searchRow.right) {
      fail(`juegos keel @ ${width}px: row and search row disagree (row=${JSON.stringify(row)}, searchRow=${JSON.stringify(searchRow)})`)
    }

    // ---- G-01.8.3-2e: the search field and the `+` themselves, never the
    // search row CONTAINER (already asserted 32/32 above and unchanged by
    // this gap's fix). ----

    // Test 1 (G-01.8.3-2e) — left agreement, positive control: the field's
    // own border-box left must equal the row's content left. PASSES today
    // (both 32) — proves the cluster's left edge was never the defect; only
    // the right-hand side (the `+`) and the field's responsiveness are.
    if (!searchInput) {
      fail(`juegos keel @ ${width}px: #juegos-search-input not found`)
    } else if (Math.abs(searchInput.left - row.left) > 0.5) {
      fail(`juegos keel @ ${width}px search field left agreement: field=${searchInput.left}px row=${row.left}px, expected within 0.5px`)
    }

    // Test 2 (G-01.8.3-2e) — the `+`'s glyph is on the rows' axis: the
    // glyph span's right inset must equal the row chevron's right inset,
    // asserted against the MEASURED chevron inset (never a literal 32) so
    // the guard retains the ability to disagree with the stylesheet. FAILS
    // today at every width (`.pk-admin-action--a3`'s `margin-left: -12px`
    // is a leading-icon pull applied to a trailing action).
    if (!glyph || chevronRightInset == null) {
      fail(`juegos keel @ ${width}px: could not measure the +'s glyph or the row chevron (glyph=${!!glyph}, chevronRightInset=${chevronRightInset})`)
    } else {
      if (glyphIsFallback) {
        log(`juegos keel @ ${width}px: +'s glyph lookup fell back to the button's first element child (no [class^="hero-"]/[class*=" hero-"] descendant found)`)
      }
      if (Math.abs(glyph.right - chevronRightInset) > 0.5) {
        fail(`juegos keel @ ${width}px +'s glyph vs chevron: glyph right inset=${glyph.right}px chevron right inset=${chevronRightInset}px, expected within 0.5px`)
      }
    }

    // Test 3 (G-01.8.3-2e) — nothing spills: the `+`'s border-box right
    // inset must be >= the row's own content right inset minus half the
    // difference between the A3 box width and its glyph width — both
    // derived from the MEASURED rects here, never from the `-12px`/`-13px`
    // a stylesheet declares. In plainer terms, the button's box may
    // overhang the content edge by exactly the amount that centres its
    // glyph on that edge, and by no more. FAILS today at 360, where the
    // box already spills past the row's own content box.
    if (!addAction || !glyph) {
      fail(`juegos keel @ ${width}px: could not measure the +'s own box or glyph for the spill check (addAction=${!!addAction}, glyph=${!!glyph})`)
    } else {
      const allowance = Math.round(((addAction.width - glyph.width) / 2) * 10) / 10
      const minRightInset = Math.round((row.right - allowance) * 10) / 10
      if (addAction.right < minRightInset) {
        fail(
          `juegos keel @ ${width}px +'s spill: add-action right inset=${addAction.right}px, row content right inset=${row.right}px, ` +
            `allowance=${allowance}px (half of add-action width=${addAction.width}px minus glyph width=${glyph.width}px), ` +
            `expected right inset >= ${minRightInset}px`,
        )
      }
    }

    // Test 1 (G-01.8.3-2c): the pinned caption band's painted edges must
    // equal the row's own content edges. FAILS today: 16 against 32, both
    // edges, all three widths (the band is anchored to the header's
    // padding-box edge, bypassing the 16px `<main>` already adds).
    if (bandLeft == null || bandRightInset == null) {
      fail(`juegos keel @ ${width}px: band ::before geometry could not be measured`)
    } else {
      if (Math.abs(bandLeft - row.left) > 0.5) {
        fail(`juegos keel @ ${width}px band-vs-row left: band=${bandLeft}px row=${row.left}px, expected within 0.5px`)
      }
      if (Math.abs(bandRightInset - row.right) > 0.5) {
        fail(`juegos keel @ ${width}px band-vs-row right inset: band=${bandRightInset}px row=${row.right}px, expected within 0.5px`)
      }
    }

    // Test 2: the row divider's right end must equal the row's own content
    // right edge. FAILS today: 16 against 32 (the divider's `right: 0`
    // shares the band's unintended axis, not the rows').
    if (dividerRightInset == null) {
      fail(`juegos keel @ ${width}px: divider ::before geometry could not be measured (fewer than two rows in the visible section?)`)
    } else if (Math.abs(dividerRightInset - row.right) > 0.5) {
      fail(`juegos keel @ ${width}px divider-vs-row right inset: divider=${dividerRightInset}px row=${row.right}px, expected within 0.5px`)
    }

    // Test 3 (positive control): the divider's LEFT is the row-name column
    // — derived from the row's own cover/gap, never a copied 84 — and is
    // UNCHANGED by this gap's fix (only the divider's right end moves).
    // PASSES today; proves a coordinate-system change did not simply shift
    // everything uniformly.
    if (dividerLeft == null || coverLeft == null || coverWidth == null || columnGap == null) {
      fail(`juegos keel @ ${width}px: could not measure the row-name-column derivation inputs (dividerLeft=${dividerLeft}, coverLeft=${coverLeft}, coverWidth=${coverWidth}, columnGap=${columnGap})`)
    } else {
      const derivedColumn = Math.round((coverLeft + coverWidth + columnGap) * 10) / 10
      if (Math.abs(dividerLeft - derivedColumn) > 0.5) {
        fail(
          `juegos keel @ ${width}px: divider left ${dividerLeft}px does not match the derived row-name column ${derivedColumn}px ` +
            `(cover left=${coverLeft} + cover width=${coverWidth} + column-gap=${columnGap})`,
        )
      }
    }

    // Test 4 (positive control): the caption ink's left already agrees with
    // the row's content left (both 32 today) — the second proof the
    // coordinate-system change alone did not manufacture a pass.
    if (captionInkLeft == null) {
      fail(`juegos keel @ ${width}px: caption ink left could not be measured`)
    } else if (Math.abs(captionInkLeft - row.left) > 0.5) {
      fail(`juegos keel @ ${width}px: caption ink left ${captionInkLeft}px does not match row content left ${row.left}px`)
    }
  }

  // Test 4 (G-01.8.3-2e) — the cluster is responsive: cross-width, so it
  // runs once after the loop against the collected `keelByWidth` map. The
  // field's border-box width at 390 minus its width at 360 must equal 30px
  // within 1px, and its width at 375 minus its width at 360 must equal
  // 15px within 1px. FAILS today — the field's `flex: 1` has always been
  // inert (its parent, `#juegos-search-form`, is `display: block`), so all
  // three widths measure the same intrinsic `size=20` width and both
  // deltas are 0. Fails loudly (never silently skips) if any width's
  // measurement is missing.
  const widths390 = keelByWidth[390]?.searchInput?.width ?? null
  const widths375 = keelByWidth[375]?.searchInput?.width ?? null
  const widths360 = keelByWidth[360]?.searchInput?.width ?? null
  if (widths390 == null || widths375 == null || widths360 == null) {
    fail(
      `juegos keel search field responsiveness: missing a width measurement (390px=${widths390}, 375px=${widths375}, 360px=${widths360})`,
    )
  } else {
    log(`juegos keel search field widths: 360px=${widths360} 375px=${widths375} 390px=${widths390}`)
    const delta390v360 = Math.round((widths390 - widths360) * 10) / 10
    const delta375v360 = Math.round((widths375 - widths360) * 10) / 10
    if (Math.abs(delta390v360 - 30) > 1) {
      fail(`juegos keel search field responsiveness: width@390 - width@360 = ${delta390v360}px, expected 30px ±1px`)
    }
    if (Math.abs(delta375v360 - 15) > 1) {
      fail(`juegos keel search field responsiveness: width@375 - width@360 = ${delta375v360}px, expected 15px ±1px`)
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

  // Plan 01.8.3-11 [T-01.8.3-34/G-01.8.3-2d/G-01.8.3-3]: the pinned-offset
  // guard — tests 1/2/3/4/5 against `measureJuegosSectionPinned`'s DOWN and
  // UP sub-objects. Test 1: the row really is hidden in the DOWN state
  // (every other DOWN assertion is meaningless otherwise). Test 2: the
  // band is at the viewport top in the DOWN state. Test 3: nothing renders
  // above the band (the elementFromPoint sweep). Test 4: the band stays
  // flush to the row's own bottom in BOTH states — the pre-existing
  // adjacency assertion, restated against the wrap's measured bottom
  // instead of a constant. Test 5: the scroll-up differential control —
  // proves the offset now tracks the row rather than having simply moved
  // to a different constant.
  const checkPinnedOffset = (label, result) => {
    if (!result.down) {
      fail(`juegos ${label} pinned-offset: down-state measurement missing`)
      return
    }
    const { down, up, pinnedH } = result

    if (down.searchHidden !== true) {
      fail(`juegos ${label} pinned-offset test1: search row is NOT hidden in the DOWN state (searchHidden=${down.searchHidden})`)
    }

    if (down.bandTop == null || down.bandTop > 0.5) {
      fail(`juegos ${label} pinned-offset test2: band top=${down.bandTop}px in the DOWN state, expected at or below 0.5px`)
    }

    if (down.offendingYs && down.offendingYs.length > 0) {
      const named = down.offendingYs.map((o) => `y=${o.y}(${o.hit})`).join(", ")
      fail(`juegos ${label} pinned-offset test3: ${down.offendingYs.length} sampled y value(s) above the band resolve inside a .pk-admin-row: ${named}`)
    }

    if (down.bandSearchGap == null || Math.abs(down.bandSearchGap) > 0.5) {
      fail(`juegos ${label} pinned-offset test4 (DOWN): band-to-row gap=${down.bandSearchGap}px, expected within ±0.5px of 0`)
    }
    if (!up || up.bandSearchGap == null || Math.abs(up.bandSearchGap) > 0.5) {
      fail(`juegos ${label} pinned-offset test4 (UP): band-to-row gap=${up ? up.bandSearchGap : null}px, expected within ±0.5px of 0`)
    }

    if (!up) {
      fail(`juegos ${label} pinned-offset test5: UP-state measurement missing`)
    } else {
      if (up.searchHidden !== false) {
        fail(`juegos ${label} pinned-offset test5: search row still hidden after scrolling up (searchHidden=${up.searchHidden})`)
      }
      if (!up.searchRect || Math.abs(up.searchRect.top - 0) > 0.5) {
        fail(`juegos ${label} pinned-offset test5: UP wrap rect top=${up.searchRect ? up.searchRect.top : null}px, expected within ±0.5px of 0`)
      }
      if (!up.searchRect || pinnedH == null || Math.abs(up.searchRect.bottom - pinnedH) > 0.5) {
        fail(`juegos ${label} pinned-offset test5: UP wrap rect bottom=${up.searchRect ? up.searchRect.bottom : null}px, expected within ±0.5px of its own measured height (${pinnedH}px)`)
      }
      if (up.bandTop == null || !up.searchRect || Math.abs(up.bandTop - up.searchRect.bottom) > 0.5) {
        fail(`juegos ${label} pinned-offset test5: UP band top=${up.bandTop}px does not equal wrap bottom=${up.searchRect ? up.searchRect.bottom : null}px within ±0.5px`)
      }
    }

    log(
      `juegos ${label} pinned-offset: DOWN bandTop=${down.bandTop} searchHidden=${down.searchHidden} offendingYs=${down.offendingYs ? down.offendingYs.length : "n/a"}; ` +
        `UP bandTop=${up ? up.bandTop : null} searchHidden=${up ? up.searchHidden : null} searchRect=${up ? JSON.stringify(up.searchRect) : null} pinnedH=${pinnedH}`,
    )
  }

  const first = await measureJuegosSectionPinned(client, "#juegos-section-draft")
  if (first.error) {
    fail(`juegos first-section (Borradores) band: ${first.error}`)
  } else {
    log(
      `juegos first-section (Borradores) band: height=${first.down.bandHeight}px (top=${first.down.bandTop} bottom=${first.down.bandBottom}) ` +
        `bg=${first.down.bandBg} search-row gap=${first.down.bandSearchGap}px row-height=${first.down.rowHeight}px searchHidden=${first.down.searchHidden}`,
    )
    if (Math.abs(first.down.bandHeight - 44.0) > 0.5) fail(`juegos first-section band height ${first.down.bandHeight}px, expected 44.0 ±0.5px`)
    if (isFullyTransparent(first.down.bandBg)) fail(`juegos first-section band background is fully transparent while pinned (${first.down.bandBg})`)
    if (first.down.rowHeight === null || first.down.rowHeight < 64) fail(`juegos first-section row height ${first.down.rowHeight}px, expected >= 64px`)
    checkInkInBand("first-section (Borradores)", first.down)
    checkPinnedOffset("first-section (Borradores)", first)
  }

  const later = await measureJuegosSectionPinned(client, "#juegos-section-published")
  if (later.error) {
    fail(`juegos later-section (Juegos del club) band: ${later.error}`)
  } else {
    log(
      `juegos later-section (Juegos del club) band: height=${later.down.bandHeight}px (top=${later.down.bandTop} bottom=${later.down.bandBottom}) ` +
        `bg=${later.down.bandBg} search-row gap=${later.down.bandSearchGap}px row-height=${later.down.rowHeight}px searchHidden=${later.down.searchHidden}`,
    )
    if (Math.abs(later.down.bandHeight - 44.0) > 0.5) fail(`juegos later-section band height ${later.down.bandHeight}px, expected 44.0 ±0.5px`)
    if (isFullyTransparent(later.down.bandBg)) fail(`juegos later-section band background is fully transparent while pinned (${later.down.bandBg})`)
    if (later.down.rowHeight === null || later.down.rowHeight < 64) fail(`juegos later-section row height ${later.down.rowHeight}px, expected >= 64px`)

    if (!later.hasRowAbove) {
      fail("juegos ink ratio: later section has no row above it to measure — expected Borradores' last row above Juegos del club's caption")
    } else if (later.airAbove == null || later.airBelow == null || later.airRatio == null) {
      fail(`juegos ink ratio: could not measure both sides (airAbove=${later.airAbove}, airBelow=${later.airBelow})`)
    } else {
      log(`juegos ink-to-ink: above=${later.airAbove}px below=${later.airBelow}px ratio=${later.airRatio}:1`)
      if (later.airRatio < 2.5) fail(`juegos ink-to-ink ratio ${later.airRatio}:1 is below the 2.5:1 floor (above=${later.airAbove}px, below=${later.airBelow}px)`)
    }
    checkInkInBand("later-section (Juegos del club)", later.down)
    checkPinnedOffset("later-section (Juegos del club)", later)

    // Plan 01.8.3-08 [G-01.8.3-2c]: repeat Test 1 (band-vs-row) and Test 2
    // (divider-vs-row) from the resting-state loop above, but now with the
    // section REALLY pinned (the incremental real scroll
    // measureJuegosSectionPinned already performed to reach this branch) —
    // the diagnosis proved horizontal geometry is scroll-state independent,
    // so a divergence between the resting and pinned readings is itself a
    // finding, never a synthetic class poke.
    if (!later.down.rowContentPinned) {
      fail("juegos pinned band/divider: could not measure the pinned section's own row content edges")
    } else {
      log(
        `juegos pinned band-vs-row: band left=${later.down.bandLeftPinned} right inset=${later.down.bandRightInsetPinned}; ` +
          `divider left=${later.down.dividerLeftPinned} right inset=${later.down.dividerRightInsetPinned}; ` +
          `row left=${later.down.rowContentPinned.left} right=${later.down.rowContentPinned.right}`,
      )
      if (later.down.bandLeftPinned == null || later.down.bandRightInsetPinned == null) {
        fail("juegos pinned band-vs-row: band ::before geometry could not be measured while pinned")
      } else {
        if (Math.abs(later.down.bandLeftPinned - later.down.rowContentPinned.left) > 0.5) {
          fail(`juegos pinned band-vs-row left: band=${later.down.bandLeftPinned}px row=${later.down.rowContentPinned.left}px, expected within 0.5px`)
        }
        if (Math.abs(later.down.bandRightInsetPinned - later.down.rowContentPinned.right) > 0.5) {
          fail(`juegos pinned band-vs-row right inset: band=${later.down.bandRightInsetPinned}px row=${later.down.rowContentPinned.right}px, expected within 0.5px`)
        }
      }
      if (later.down.dividerRightInsetPinned == null) {
        fail("juegos pinned divider-vs-row: divider ::before geometry could not be measured while pinned (fewer than two rows in the section?)")
      } else if (Math.abs(later.down.dividerRightInsetPinned - later.down.rowContentPinned.right) > 0.5) {
        fail(`juegos pinned divider-vs-row right inset: divider=${later.down.dividerRightInsetPinned}px row=${later.down.rowContentPinned.right}px, expected within 0.5px`)
      }
    }
  }

  if (!first.error && !later.error) {
    const delta = Math.round((first.down.bandHeight - later.down.bandHeight) * 10) / 10
    log(`juegos band heights: first=${first.down.bandHeight}px later=${later.down.bandHeight}px delta=${delta}px`)
    if (Math.abs(delta) > 0.5) fail(`juegos band heights disagree between sections by ${delta}px (first=${first.down.bandHeight}px, later=${later.down.bandHeight}px) — the shipped 32.2/44.2 defect this guards against`)

    // Plan 01.8.3-06: the assertion that directly names the root cause — a
    // band whose ink offset tracks `--pt` reads 14 against 26 today, even
    // though the band's own HEIGHT is identical (44px) for both sections.
    if (first.down.inkGapAbove == null || later.down.inkGapAbove == null) {
      fail(`juegos ink gap-above cross-section: could not measure inkGapAbove for one or both sections (first=${first.down.inkGapAbove}, later=${later.down.inkGapAbove})`)
    } else {
      const crossDelta = Math.round(Math.abs(first.down.inkGapAbove - later.down.inkGapAbove) * 10) / 10
      log(`juegos ink gap-above cross-section: first=${first.down.inkGapAbove}px later=${later.down.inkGapAbove}px delta=${crossDelta}px`)
      if (crossDelta > 1.0) {
        fail(`juegos ink gap-above disagrees between sections by ${crossDelta}px (first=${first.down.inkGapAbove}px, later=${later.down.inkGapAbove}px) — the band's ink offset tracks --pt instead of staying fixed`)
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

    // ---- main's own horizontal padding (NOT the content keel — see the
    // relabelled comment above measureKeel) ----
    log("Measuring <main>'s own horizontal padding across admin pages (excludes the one fullbleed page by construction; not the content keel — see measureJuegosKeelAt for that)...")
    const keelResults = {}
    for (const width of [375, 360]) {
      const m = await measureKeel({ client, baseUrl, width })
      keelResults[width] = m
      for (const [page, edges] of Object.entries(m)) {
        if (!edges) {
          log(`FAIL: main padding @ ${width}px ${page}: content wrapper not found`)
          exitCode = 1
          continue
        }
        log(`MAIN PADDING @ ${width}px ${page}: left=${edges.left}px right=${edges.right}px`)
      }
    }
    // Cross-page consistency at each width — <main>'s own padding should be
    // one number per width across every non-fullbleed screen (D-18's shared
    // shape), not a fresh one per page. This says nothing about content.
    for (const width of [375, 360]) {
      const pages = Object.values(keelResults[width]).filter(Boolean)
      const distinctLeft = [...new Set(pages.map((p) => p.left))]
      const distinctRight = [...new Set(pages.map((p) => p.right))]
      if (distinctLeft.length > 1 || distinctRight.length > 1) {
        log(`FAIL: main padding @ ${width}px is not consistent across pages: ${JSON.stringify(keelResults[width])}`)
        exitCode = 1
      } else if (pages.length > 0) {
        log(`MAIN PADDING @ ${width}px (consistent across ${pages.length} page(s), excludes the fullbleed editor): left=${distinctLeft[0]}px right=${distinctRight[0]}px`)
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

    // ---- sheet body keel (plan 01.8.3-10, G-01.8.3-4b) ----
    log("Measuring the sheet body's own keel against its header...")
    // Task 3: the editor's own choice sheet (`form.ex:1035`'s
    // `.pk-editor-opt`, the call site this plan's editor.css fix re-
    // expressed — "must be measured, not reasoned about"). Its URL is a
    // real game id, resolved fresh here off `/admin/juegos` (same
    // mechanism `resolveEditorUrl` uses for the save-bar check above) —
    // not a static route, so it is built here rather than as a
    // `SHEET_KEEL_CALL_SITES` literal. `edit-field`/`weight_band` renders
    // unconditionally on the editor page — data-independent.
    const sheetKeelRows = [...SHEET_KEEL_CALL_SITES]
    const sheetKeelEditorUrl = await resolveEditorUrl(client, baseUrl)
    if (sheetKeelEditorUrl) {
      sheetKeelRows.push({
        page: sheetKeelEditorUrl,
        overlayId: "editor-weight-band-sheet",
        dataIndependent: true,
        bodyShape: "row",
        steps: [{ kind: "click", selector: '[phx-click="edit-field"][phx-value-field="weight_band"]' }],
      })
    } else {
      log("sheet keel: could not resolve an editor URL — skipping editor-weight-band-sheet (is the dev catalog empty?)")
    }
    const sheetKeel = await checkSheetKeel({ client, baseUrl, rows: sheetKeelRows })
    if (sheetKeel.fails.length > 0) {
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
