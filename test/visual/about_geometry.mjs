#!/usr/bin/env node
// Zero-dependency Node CDP probe for the About page's vertical rhythm
// (G-01.5-2 gap closure, plan 01.5-06 — see 01.5-06-SUMMARY.md and
// .planning/debug/inter-band-whitespace-gap.md). This is a GEOMETRIC
// oracle, not a CSS-source/class-attribute oracle: every test this phase
// shipped for band appearance (the D-14 describe block in
// about_live_test.exs) asserts the bands have the right COLOURS or CLASSES.
// None of them can observe whether two rendered boxes actually touch —
// that is exactly the property that let a 16px whitespace strip ship for
// two weeks at every band-to-band boundary (contributed by layouts.ex's
// shared `space-y-4` shell wrapper, not by anything the band itself
// declared) without failing a single existing gate.
//
// It is developer-invoked only: not wired into `mix quality`, not added to
// CI, for the same reasons the sibling probe (about_map_attribution.mjs)
// records — it needs a real browser and a booted server, and this repo has
// a real precedent for rendering divergence between headless Chromium and
// other engines (Phase 01.3's chevron bug reproduced only on real WebKit).
// A green run here is a strong signal, not a proof.
//
// Structure: `CHECKS` below is a named list of check functions, each taking
// the same per-case `measured` payload and returning an array of failure
// strings. The sweep loop runs every check against every (viewport, theme)
// case. Plans 01.5-07 and 01.5-08 each extend this same file with one more
// check function appended to `CHECKS` — neither needs to touch the sweep
// loop, the dev-server/Chrome lifecycle, or the CDP client below.
//
// Usage: node test/visual/about_geometry.mjs
// Env:   PROBE_BASE_URL=http://localhost:4000  (skip booting a dev server)

import { spawn } from "node:child_process"
import { mkdtemp, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

// The widths the root-cause diagnosis measured at (E-06: identical 16px gap
// at all three, ruling out a breakpoint-scoped explanation). Kept in sync
// with that evidence rather than freshly guessed.
const VIEWPORTS = [390, 768, 1280]
const THEMES = ["light", "dark"]

// Sub-pixel tolerance for fractional layout only (e.g. a viewport width
// that does not divide evenly into rem-based paddings). This must stay far
// below the 16px defect this probe exists to catch — anything near that
// magnitude would let the shipped bug back through silently.
const CONTACT_TOLERANCE_PX = 0.5

const PROBE_BASE_URL = process.env.PROBE_BASE_URL

function log(...args) {
  console.log(...args)
}

// ---------------------------------------------------------------------------
// Dev server lifecycle (same pattern as about_map_attribution.mjs)
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
    throw new Error(
      `dev server did not answer /up within 60s. Captured output:\n${stderrBuf}`,
    )
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
// Chrome lifecycle (same pattern as about_map_attribution.mjs)
// ---------------------------------------------------------------------------
function findChromeBinary() {
  const candidates = ["google-chrome-stable", "chromium", "chromium-browser"]
  return candidates
}

async function startChrome() {
  const userDataDir = await mkdtemp(join(tmpdir(), "about-geometry-chrome-"))
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
          `--user-data-dir=${userDataDir}`,
          "--remote-debugging-port=0",
        ],
        { stdio: ["ignore", "ignore", "pipe"] },
      )
      // Confirm the process actually spawned (spawn a bad binary emits an
      // async 'error' event rather than throwing synchronously).
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
    throw new Error(
      `Could not spawn any of: ${candidates.join(", ")}. Last error: ${lastErr?.message}`,
    )
  }

  let stderrBuf = ""
  const port = await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      reject(
        new Error(
          `no DevTools endpoint on chrome stderr within 15s. Captured stderr:\n${stderrBuf}`,
        ),
      )
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
  // Chrome can still be flushing profile files to its user-data-dir for a
  // moment after the process exits; retry the removal rather than treating
  // a transient ENOTEMPTY as a probe failure.
  await rm(userDataDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 })
}

// ---------------------------------------------------------------------------
// Minimal CDP client (same pattern as about_map_attribution.mjs)
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

  once(method) {
    return new Promise((resolve) => {
      const handler = (ev) => {
        const msg = JSON.parse(ev.data)
        if (msg.method === method) {
          this.ws.removeEventListener("message", handler)
          resolve(msg.params)
        }
      }
      this.ws.addEventListener("message", handler)
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
  return { client, targetId: target.id, ws }
}

// ---------------------------------------------------------------------------
// Per-case measurement
// ---------------------------------------------------------------------------
async function runCase({ client, baseUrl, viewport, theme }) {
  await client.send("Emulation.setDeviceMetricsOverride", {
    width: viewport,
    height: 900,
    deviceScaleFactor: 1,
    mobile: false,
  })

  const navigated = client.once("Page.loadEventFired")
  await client.send("Page.navigate", { url: `${baseUrl}/quienes-somos` })
  await navigated

  await client.send("Runtime.evaluate", {
    expression: `
      document.documentElement.dataset.theme = ${JSON.stringify(theme)};
      document.documentElement.dataset.themeSource = "user";
    `,
  })

  const measureResult = await client.send("Runtime.evaluate", {
    expression: `
      JSON.stringify((() => {
        // Deliberately queries section.pk-band only, in document order —
        // NOT every direct child of the shell wrapper. The hero <div>
        // above #fotos is a shell child too but is not a .pk-band, so it
        // never enters this list and the hero -> #fotos boundary is
        // structurally excluded from every check below. Plan 01.5-06
        // Task 1 decided to KEEP that one boundary's 16px deliberately
        // (both sides are transparent, so the gap is invisible) — see the
        // comment on .pk-band in app.css for the full reasoning.
        const nodes = Array.from(document.querySelectorAll('section.pk-band'));
        const bands = nodes.map((el, index) => {
          const rect = el.getBoundingClientRect();
          return {
            index,
            id: el.id || null,
            className: el.className,
            rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
          };
        });
        return { bands };
      })())
    `,
    returnByValue: true,
  })

  return JSON.parse(measureResult.result.value)
}

function bandLabel(band) {
  return band.id ? `#${band.id}` : `${band.className} (index ${band.index})`
}

// ---------------------------------------------------------------------------
// Checks — each takes (measured, ctx) and returns an array of failure
// strings. `ctx` carries { viewport, theme } for failure messages. Append
// new check functions to CHECKS; the sweep loop below needs no changes.
// ---------------------------------------------------------------------------

// Adjacent-band contact: the property this whole probe exists to add.
// Asserts each band's bottom edge touches the next band's top edge within
// CONTACT_TOLERANCE_PX. This is the check that fails on the shipped defect
// (a uniform 16px separation at all four band-to-band boundaries) and
// passes once .pk-band's margin-block-end: 0 (plan 01.5-06 Task 1) lands.
function checkAdjacentBandContact(measured, ctx) {
  const failures = []
  const { bands } = measured

  if (bands.length < 2) {
    failures.push(
      `expected at least 2 section.pk-band elements to check adjacency, found ${bands.length}`,
    )
    return failures
  }

  for (let i = 0; i < bands.length - 1; i++) {
    const prev = bands[i]
    const next = bands[i + 1]
    const prevBottom = prev.rect.y + prev.rect.height
    const nextTop = next.rect.y
    const distance = nextTop - prevBottom

    if (Math.abs(distance) > CONTACT_TOLERANCE_PX) {
      failures.push(
        `${bandLabel(prev)} -> ${bandLabel(next)}: expected contact (within ` +
          `${CONTACT_TOLERANCE_PX}px), measured a ${distance.toFixed(2)}px gap at ` +
          `[${ctx.viewport}px, ${ctx.theme}]`,
      )
    }
  }

  return failures
}

// Named list of check functions the sweep loop calls. Plans 01.5-07 and
// 01.5-08 each add one more entry here for their own oracle.
const CHECKS = [checkAdjacentBandContact]

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  const { baseUrl, proc: serverProc } = await startDevServer()
  const chrome = await startChrome()

  let exitCode = 0
  let casesRun = 0

  try {
    const conn = await connectCDP(chrome.port)
    const client = conn.client

    for (const viewport of VIEWPORTS) {
      for (const theme of THEMES) {
        const label = `[${viewport}px, ${theme}]`

        try {
          const measured = await runCase({ client, baseUrl, viewport, theme })
          casesRun++

          log(
            `${label} bands: ${measured.bands
              .map((b) => `${bandLabel(b)}@y=${b.rect.y.toFixed(1)}`)
              .join(", ")}`,
          )

          for (let i = 0; i < measured.bands.length - 1; i++) {
            const prev = measured.bands[i]
            const next = measured.bands[i + 1]
            const distance = next.rect.y - (prev.rect.y + prev.rect.height)
            log(
              `${label} ${bandLabel(prev)} -> ${bandLabel(next)}: ${distance.toFixed(2)}px`,
            )
          }

          for (const check of CHECKS) {
            const failures = check(measured, { viewport, theme })
            for (const failure of failures) {
              log(`${label} FAIL: ${failure}`)
              exitCode = 1
            }
          }
        } catch (err) {
          log(`${label} FAIL: ${err.message}`)
          exitCode = 1
        }
      }
    }
  } finally {
    await stopChrome(chrome)
    await stopDevServer(serverProc)
  }

  if (casesRun !== VIEWPORTS.length * THEMES.length) {
    log(
      `FAIL: expected ${VIEWPORTS.length * THEMES.length} case blocks, only ${casesRun} ` +
        `completed far enough to be reported — a skipped viewport or theme is an unverified ` +
        `viewport or theme.`,
    )
    exitCode = 1
  }

  process.exit(exitCode)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
