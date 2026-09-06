#!/usr/bin/env node
// Zero-dependency Node CDP probe for the Contacto card's Google Maps embed
// (G-01.4-5 gap closure, plan 01.4-12 — see 01.4-VERIFICATION.md and
// .planning/debug/resolved/G-01.4-4-maps-thumbnail-approach.md). This is an
// EMBED oracle, not an attribution-crop oracle: what it checks is whether a
// live, keyless google.com/maps/embed?pb= iframe actually loads under this
// app's Content-Security-Policy, in a real browser, whose whole point is
// that the answer cannot be known by inspecting markup alone.
//
// This requires NETWORK ACCESS to https://www.google.com — new, since the
// prior (screenshot-era) probe was fully local. It stays developer-invoked
// and out of `mix quality`/CI for two reasons: the pre-existing
// engine-divergence risk documented in the original header (this repo has
// a real precedent — the Phase 01.3 chevron bug reproduced only on real
// WebKit, not headless Chromium), plus this NEW network dependency on a
// third party. It is also the ONLY detector this repo has for the embed's
// undocumented, unversioned `pb=` payload breaking: there is no
// server-side signal if Google ever stops resolving it, so a red run here
// is the first and only warning.
//
// Usage: node test/visual/about_map_attribution.mjs
// Env:   PROBE_BASE_URL=http://localhost:4000  (skip booting a dev server)

import { spawn } from "node:child_process"
import { mkdtemp, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

const EMBED_ORIGIN = "https://www.google.com"
const EMBED_PATH_PREFIX = "/maps/embed"

// The strip along the bottom of the embed's rect that Google's own
// attribution bar paints into. 28px is a deliberate margin over the
// roughly 20-24 CSS px that bar actually occupies — this assertion is not
// here to catch today's CSS, it is here to fail the day someone moves the
// caption chip back down toward that edge (D-13/D-14 moved it to the top
// specifically to vacate this strip).
const ATTRIBUTION_CLEARANCE_PX = 28

const VIEWPORTS = [375, 640, 768, 1280]
const THEMES = ["light", "dark"]

const PROBE_BASE_URL = process.env.PROBE_BASE_URL

function log(...args) {
  console.log(...args)
}

// ---------------------------------------------------------------------------
// Dev server lifecycle
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
// Chrome lifecycle
// ---------------------------------------------------------------------------
function findChromeBinary() {
  const candidates = ["google-chrome-stable", "chromium", "chromium-browser"]
  return candidates
}

async function startChrome() {
  const userDataDir = await mkdtemp(join(tmpdir(), "about-map-attrib-chrome-"))
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
          // Cross-origin iframes normally get an Out-Of-Process-iframe (OOPIF)
          // process swap under Chrome's site isolation — CDP reports this to
          // the top-level Page-domain session as `Page.frameDetached
          // {reason: "swap"}`, with NO further `Page.frameNavigated` for that
          // frameId on this session (the real navigation event lands on a
          // separate auto-attached target this script does not attach to).
          // Disabling site isolation keeps the embed's navigation observable
          // on the one Page-domain session this probe already has — this is
          // a LOCAL TESTING flag for the probe's own headless Chrome
          // instance, not a production security relaxation (nothing here
          // touches the app's actual CSP or sandboxing).
          "--disable-site-isolation-trials",
          "--disable-features=IsolateOrigins,site-per-process",
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
// Minimal CDP client
// ---------------------------------------------------------------------------
class CDPClient {
  constructor(ws) {
    this.ws = ws
    this.nextId = 1
    this.pending = new Map()
    this.listeners = new Map()
    ws.addEventListener("message", (ev) => {
      const msg = JSON.parse(ev.data)
      if (msg.id !== undefined && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id)
        this.pending.delete(msg.id)
        if (msg.error) reject(new Error(JSON.stringify(msg.error)))
        else resolve(msg.result)
      } else if (msg.method) {
        const set = this.listeners.get(msg.method)
        if (set) for (const cb of set) cb(msg.params)
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
      const set = this.listeners.get(method) || new Set()
      const cb = (params) => {
        set.delete(cb)
        resolve(params)
      }
      set.add(cb)
      this.listeners.set(method, set)
    })
  }

  // Like `once`, but resolves only for the first event matching `predicate`
  // — needed for `Page.frameNavigated`, which fires once per frame
  // (including the top-level document) and we need specifically the CHILD
  // frame's navigation, not the first frameNavigated event of any kind.
  onceMatching(method, predicate) {
    return new Promise((resolve) => {
      const set = this.listeners.get(method) || new Set()
      const cb = (params) => {
        if (!predicate(params)) return
        set.delete(cb)
        resolve(params)
      }
      set.add(cb)
      this.listeners.set(method, set)
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

  // CSP-violation capture MUST be installed via
  // Page.addScriptToEvaluateOnNewDocument, not a post-load Runtime.evaluate
  // — a listener attached after the frame was already refused would
  // observe nothing and report success, which is the exact failure this
  // assertion exists to catch. Registered ONCE here (not per case): this
  // method re-runs the script at the start of EVERY future navigation on
  // this session, so `window.__cspViolations = []` resets the array fresh
  // for each case's own navigation without needing to re-register (and
  // without accumulating duplicate `securitypolicyviolation` listeners
  // across all 8 cases, which re-registering per case would do).
  await client.send("Page.addScriptToEvaluateOnNewDocument", {
    source: `
      window.__cspViolations = [];
      document.addEventListener("securitypolicyviolation", (e) => {
        window.__cspViolations.push({
          blockedURI: e.blockedURI,
          effectiveDirective: e.effectiveDirective,
        });
      });
    `,
  })

  return { client, targetId: target.id, ws }
}

// ---------------------------------------------------------------------------
// Geometry helpers (kept — Task 3 uses them for the D-14 hit-test and the
// chip/attribution-strip clearance assertions across the full 8-case fan-out)
// ---------------------------------------------------------------------------
function rectsIntersect(a, b) {
  return a.x < b.x + b.width && a.x + a.width > b.x && a.y < b.y + b.height && a.y + a.height > b.y
}

// Whether `inner` is fully inside `outer` — Google's "close proximity"
// requirement, checked geometrically rather than assumed from DOM nesting
// (a descendant can still be visually clipped or positioned outside its
// ancestor's box).
function rectContains(outer, inner) {
  return (
    inner.x >= outer.x - 0.5 &&
    inner.y >= outer.y - 0.5 &&
    inner.x + inner.width <= outer.x + outer.width + 0.5 &&
    inner.y + inner.height <= outer.y + outer.height + 0.5
  )
}

// ---------------------------------------------------------------------------
// WCAG-style colour parsing helpers (kept — Task 3's dark-filter assertion
// reads computed `filter`, not colour, but these are the general-purpose
// computed-colour-string helpers this file already had and Task 3's per-
// case reporting reuses `parseRgbString`-shaped parsing for consistency).
// ---------------------------------------------------------------------------
function parseRgbString(str) {
  const m = str.match(/rgba?\(([^)]+)\)/)
  if (!m) throw new Error(`Unexpected computed colour string: ${str}`)
  const parts = m[1].split(",").map((s) => parseFloat(s.trim()))
  return [parts[0], parts[1], parts[2]]
}

function relativeLuminance([r, g, b]) {
  const channel = (c) => {
    const s = c / 255
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4)
  }
  const [rl, gl, bl] = [channel(r), channel(g), channel(b)]
  return 0.2126 * rl + 0.7152 * gl + 0.0722 * bl
}

// ---------------------------------------------------------------------------
// Per-case measurement, run across the full 4x2 (viewport, theme) matrix
// (plan 01.4-12 Task 3, restoring the fan-out Task 1 narrowed to a single
// tracer case). 640px is deliberately in the set: the parent's
// sm:grid-cols-2 halves the Contacto card there, and it is where every
// previous round of this gap (01.4-02/07/09/10/11) failed first.
// ---------------------------------------------------------------------------
async function runCase({ client, baseUrl, viewport, theme }) {
  await client.send("Emulation.setDeviceMetricsOverride", {
    width: viewport,
    height: 900,
    deviceScaleFactor: 1,
    mobile: false,
  })

  // Subscribe to Page.frameNavigated BEFORE navigating, so we cannot miss
  // the child frame's commit event to a race. A blocked frame produces an
  // <iframe> element in the DOM with no navigation commit, so element
  // presence proves nothing — this is what actually separates the two.
  const childFrameNavigated = client.onceMatching(
    "Page.frameNavigated",
    (params) =>
      params.frame.parentId != null &&
      typeof params.frame.url === "string" &&
      params.frame.url.startsWith(EMBED_ORIGIN) &&
      params.frame.url.includes(EMBED_PATH_PREFIX),
  )

  const navigated = client.once("Page.loadEventFired")
  await client.send("Page.navigate", { url: `${baseUrl}/quienes-somos` })
  await navigated

  await client.send("Runtime.evaluate", {
    expression: `
      document.documentElement.dataset.theme = ${JSON.stringify(theme)};
      document.documentElement.dataset.themeSource = "user";
    `,
  })

  // `behavior: "instant"` deliberately overrides this stylesheet's
  // `html { scroll-behavior: smooth; }` (app.css) — a fire-and-forget
  // smooth scroll here would leave the element's rect stale (mid-animation)
  // by the time the measurement snippet below reads it, since nothing
  // awaits the scroll's completion.
  await client.send("Runtime.evaluate", {
    expression: `document.querySelector('#contacto').scrollIntoView({block: "center", behavior: "instant"})`,
  })

  const childFrameTimeout = new Promise((resolve) =>
    setTimeout(() => resolve(null), 20_000),
  )
  const childFrame = await Promise.race([childFrameNavigated, childFrameTimeout])

  const violationsResult = await client.send("Runtime.evaluate", {
    expression: "JSON.stringify(window.__cspViolations || [])",
    returnByValue: true,
  })
  const allViolations = JSON.parse(violationsResult.result.value)

  // Phoenix's dev-only LiveReloader plug injects a same-origin
  // `/phoenix/live_reload/frame` iframe for its own hot-reload watcher.
  // Before this plan, `default-src 'self'` covered same-origin framing
  // implicitly (no frame-src existed to override the fallback); D-12's
  // frame-src now scopes framing to exactly one third-party origin, which
  // — as a side effect confined to LOCAL DEVELOPMENT — blocks that
  // unrelated dev-tooling frame too. This is a real, expected consequence
  // of "exactly one origin, derived from the embed URL" (the plan's own
  // constraint) and is out of scope to fix by widening frame-src in
  // csp.ex — see the SUMMARY's deviations section. It never reaches
  // production (the LiveReloader plug is only mounted when
  // `code_reloading?` is true). Filtered out here so this probe's
  // assertion stays about the map embed, the thing it actually tests.
  const violations = allViolations.filter(
    (v) => !v.blockedURI.includes("/phoenix/live_reload"),
  )

  const measureResult = await client.send("Runtime.evaluate", {
    expression: `
      JSON.stringify((() => {
        const thumb = document.querySelector('.pk-about-map-thumb');
        const link = document.querySelector('.pk-about-map-link');
        const embed = document.querySelector('.pk-about-map-embed');
        // Scoped to the thumb box, not document.querySelectorAll('iframe') —
        // Phoenix's dev-only LiveReloader plug injects its OWN unrelated
        // iframe elsewhere in the document when this probe boots a dev
        // server, which would make a document-wide count meaningless here.
        // The ExUnit suite (about_live_test.exs, runs under MIX_ENV=test,
        // no LiveReloader) is what gates "exactly one iframe on the page" —
        // this is informational only.
        const iframeCount = thumb ? thumb.querySelectorAll('iframe').length : 0;

        const thumbRect = thumb ? thumb.getBoundingClientRect() : null;
        const linkRect = link ? link.getBoundingClientRect() : null;
        const embedRect = embed ? embed.getBoundingClientRect() : null;

        const toRect = (r) => r ? { x: r.x, y: r.y, width: r.width, height: r.height } : null;

        const labels = Array.from(document.querySelectorAll('.pk-about-map-label')).filter(
          el => getComputedStyle(el).display !== 'none'
        );
        const label = labels.length ? toRect(labels[0].getBoundingClientRect()) : null;

        const embedCs = embed ? getComputedStyle(embed) : null;

        const centreX = thumbRect ? thumbRect.x + thumbRect.width / 2 : null;
        const centreY = thumbRect ? thumbRect.y + thumbRect.height / 2 : null;
        const hitEl = (centreX !== null) ? document.elementFromPoint(centreX, centreY) : null;
        const hitIsLink = hitEl != null && link != null && (hitEl === link || link.contains(hitEl));

        return {
          iframeCount,
          thumbRect: toRect(thumbRect),
          linkRect: toRect(linkRect),
          embedRect: toRect(embedRect),
          label,
          pointerEvents: embedCs ? embedCs.pointerEvents : null,
          filter: embedCs ? embedCs.filter : null,
          hitIsLink,
          hitElementDescription: hitEl ? (hitEl.className || hitEl.tagName) : null,
        };
      })())
    `,
    returnByValue: true,
  })

  const measured = JSON.parse(measureResult.result.value)

  return {
    violations,
    childFrameUrl: childFrame ? childFrame.frame.url : null,
    ...measured,
  }
}

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

          log(`${label} CSP violations: ${measured.violations.length}`)
          if (measured.violations.length > 0) {
            for (const v of measured.violations) {
              log(
                `${label} FAIL: CSP VIOLATION: effectiveDirective=${v.effectiveDirective} blockedURI=${v.blockedURI}`,
              )
            }
            exitCode = 1
          }

          log(`${label} child frame URL: ${measured.childFrameUrl ?? "(none — no commit observed)"}`)
          if (!measured.childFrameUrl) {
            log(
              `${label} FAIL: TIMEOUT waiting for child frame navigation to the embed URL ` +
                `(expected an origin starting with ${EMBED_ORIGIN}${EMBED_PATH_PREFIX})`,
            )
            exitCode = 1
          }

          // Scoped to .pk-about-map-thumb, not document.querySelectorAll —
          // Phoenix's dev-only LiveReloader plug injects its OWN unrelated
          // iframe elsewhere in the document whenever this probe boots a
          // dev server (never in production — see runCase's comment on
          // `violations`). This IS a gate here (unlike Task 1's tracer,
          // which only logged it): "exactly 1" scoped to the app's own
          // frame box is both correct and immune to that dev-tooling
          // false positive.
          log(`${label} iframe count (inside .pk-about-map-thumb): ${measured.iframeCount}`)
          if (measured.iframeCount !== 1) {
            log(`${label} FAIL: expected 1 iframe, found ${measured.iframeCount}`)
            exitCode = 1
          }

          const embedRect = measured.embedRect
          const thumbRect = measured.thumbRect
          const linkRect = measured.linkRect
          const label_ = measured.label

          log(`${label} embed rect: ${JSON.stringify(embedRect)}`)
          log(`${label} thumb rect: ${JSON.stringify(thumbRect)}`)
          log(`${label} link rect: ${JSON.stringify(linkRect)}`)
          log(`${label} caption chip rect: ${JSON.stringify(label_)}`)
          log(`${label} embed pointer-events: ${measured.pointerEvents}`)
          log(`${label} embed filter: ${measured.filter}`)
          log(`${label} hit-test at box centre: ${measured.hitElementDescription} (isLink=${measured.hitIsLink})`)

          if (!embedRect || embedRect.width <= 0 || embedRect.height <= 0) {
            log(`${label} FAIL: embed rect is ${embedRect ? `${embedRect.width}x${embedRect.height}` : "null"}`)
            exitCode = 1
          } else if (thumbRect && !rectContains(thumbRect, embedRect)) {
            log(
              `${label} FAIL: embed rect ${JSON.stringify(embedRect)} is not contained by ` +
                `.pk-about-map-thumb's rect ${JSON.stringify(thumbRect)} (within 1px) — a frame ` +
                `overflowing its clipping box would be cropped by the same overflow: hidden that ` +
                `ran this entire gap`,
            )
            exitCode = 1
          }

          if (measured.pointerEvents !== "none") {
            log(`${label} FAIL: embed pointer-events is ${measured.pointerEvents}, expected none`)
            exitCode = 1
          }

          if (!measured.hitIsLink) {
            log(
              `${label} FAIL: hit test at box centre resolved to ${measured.hitElementDescription}, ` +
                `expected .pk-about-map-link or a descendant`,
            )
            exitCode = 1
          }

          if (thumbRect && linkRect && !rectContains(linkRect, thumbRect)) {
            log(
              `${label} FAIL: overlay link rect ${JSON.stringify(linkRect)} does not cover thumb ` +
                `rect ${JSON.stringify(thumbRect)} (within 1px) — the click-out is not reachable ` +
                `from everywhere on the map`,
            )
            exitCode = 1
          }

          if (embedRect && label_) {
            const attribStrip = {
              x: embedRect.x,
              y: embedRect.y + embedRect.height - ATTRIBUTION_CLEARANCE_PX,
              width: embedRect.width,
              height: ATTRIBUTION_CLEARANCE_PX,
            }
            if (rectsIntersect(label_, attribStrip)) {
              log(
                `${label} FAIL: caption chip intersects the bottom ${ATTRIBUTION_CLEARANCE_PX}px ` +
                  `of the embed rect — the strip Google's own attribution bar paints into`,
              )
              exitCode = 1
            }
          }

          if (theme === "light") {
            if (measured.filter !== "none") {
              log(`${label} FAIL: filter is ${measured.filter} in the light case, expected none`)
              exitCode = 1
            }
          } else {
            if (measured.filter === "none" || !measured.filter.includes("invert(")) {
              log(
                `${label} FAIL: filter is ${measured.filter} in the dark case, expected a value ` +
                  `containing invert(`,
              )
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

  // Plan 01.4-12 Task 1, step 7 (Task 3 restores this for the full 4x2
  // matrix): leave a live environment for the Task 4 human checkpoint
  // instead of tearing everything down. Started ONLY after a fully green
  // run, per the rule that a verification environment is never presented
  // broken. This is a SEPARATE, detached process from the probe's own
  // ephemeral `serverProc` above (already stopped in the `finally` block)
  // — that one exists only for the duration of the CDP run.
  if (exitCode === 0) {
    await startCheckpointServer()
  } else {
    log("Probe did not pass cleanly — not starting a server for the checkpoint.")
  }

  process.exit(exitCode)
}

// Starts a detached `mix phx.server`, independent of this script's own
// process tree (so it keeps running after this script exits), polls
// `GET /up` until it answers 200, then prints the checkpoint URL and PID.
// If PROBE_BASE_URL was already set (an existing server the caller is
// managing), no new process is spawned — the existing server is polled and
// reported instead.
async function startCheckpointServer() {
  if (PROBE_BASE_URL) {
    const ok = await pollUp(PROBE_BASE_URL)
    if (!ok) {
      log(`FAIL: ${PROBE_BASE_URL}/up did not return 200 for the checkpoint.`)
      return
    }
    log(`Checkpoint server (externally managed via PROBE_BASE_URL): ${PROBE_BASE_URL}/quienes-somos#contacto`)
    return
  }

  const baseUrl = "http://localhost:4000"
  const proc = spawn("mix", ["phx.server"], {
    env: { ...process.env, MIX_ENV: "dev" },
    stdio: "ignore",
    detached: true,
  })
  proc.unref()

  const ok = await pollUp(baseUrl)
  if (!ok) {
    log(`FAIL: ${baseUrl}/up did not return 200 within 60s — checkpoint server not confirmed up.`)
    return
  }

  log(`Checkpoint server is up. PID: ${proc.pid}`)
  log(`Open: ${baseUrl}/quienes-somos#contacto`)
}

async function pollUp(baseUrl) {
  const deadline = Date.now() + 60_000
  while (Date.now() < deadline) {
    try {
      const res = await fetch(`${baseUrl}/up`)
      if (res.status === 200) return true
    } catch {
      // not up yet
    }
    await new Promise((r) => setTimeout(r, 500))
  }
  return false
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
