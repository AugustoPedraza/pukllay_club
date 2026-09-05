#!/usr/bin/env node
// Zero-dependency Node CDP probe for the Contacto card's Google Maps
// thumbnail (G-01.4-5 gap closure — see 01.4-VERIFICATION.md truth 10 and
// 01.4-10-PLAN.md). Boots the dev server and a headless Chrome, drives the
// Chrome DevTools Protocol directly over the built-in `WebSocket`/`fetch`
// (Node 22+, no npm dependency, no package.json in this repo's root to add
// one to), and asserts — per (viewport, theme) — that the attribution's
// source-pixel box survives the live `object-fit: cover` crop and never
// overlaps the caption chip.
//
// Fans out over the cross product of 4 viewports x 2 themes (8 cases),
// captures an element-clipped screenshot of each, writes cases.json
// recording the geometry (including the PRE-FIX crop, derived from the old
// 21/9 ratio rather than hard-coded, for the discrimination check), then
// delegates to test/visual/about_map_attribution_pixels.py to confirm the
// geometry model against actual painted pixels.
//
// Usage: node test/visual/about_map_attribution.mjs
// Env:   PROBE_BASE_URL=http://localhost:4000  (skip booting a dev server)

import { spawn } from "node:child_process"
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

// ---------------------------------------------------------------------------
// Measured constants (plan 01.4-10 <measured_constants>). Every number here
// was measured directly off the committed asset with python3 + PIL against
// priv/static/images/about-maps-thumb.jpg at its current bytes — record them
// once, here, and have every other consumer (the pixel oracle, in Task 2)
// read them from cases.json rather than re-typing them in a second place.
// ---------------------------------------------------------------------------
const ASSET_PATH = "priv/static/images/about-maps-thumb.jpg"
const ASSET_W = 1656
const ASSET_H = 804

// Attribution glyph box, inclusive source-pixel bounds. Obtained via a
// neutral-dark pixel mask (luminance < 170 AND max-min channel spread < 40)
// over rows 760-804, cols 720-1000 of the committed JPEG.
const ATTRIB_ROW_START = 781
const ATTRIB_ROW_END = 799
const ATTRIB_COL_START = 801
const ATTRIB_COL_END = 902

// Pre-fix geometry: the aspect-ratio literal this plan replaced, and the
// object-position default the rule carried before this plan added one
// (browsers default `object-position` to "50% 50%" when unspecified).
const LEGACY_ASPECT_RATIO = 21 / 9
const LEGACY_OBJECT_POSITION = { x: 50, y: 50 }
// --pk-map-attrib-band's value, needed here (not just in app.css) so the
// pixel oracle knows which strip of the box to isolate for its
// attribution-strip MAD assertion.
const ATTRIB_BAND_PCT = 3.5

const VIEWPORTS = [375, 640, 768, 1280]
const THEMES = ["light", "dark"]
const CAPTURE_SCALE = 3

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

  // `behavior: "instant"` deliberately overrides this stylesheet's
  // `html { scroll-behavior: smooth; }` (app.css) — a fire-and-forget
  // smooth scroll here would leave the element's rect stale (mid-animation)
  // by the time the measurement snippet below reads it, since nothing
  // awaits the scroll's completion.
  await client.send("Runtime.evaluate", {
    expression: `document.querySelector('#contacto').scrollIntoView({block: "center", behavior: "instant"})`,
  })

  await client.send("Runtime.evaluate", {
    expression: `
      (async () => {
        const imgs = Array.from(document.querySelectorAll('.pk-about-map-thumb img'));
        const visible = imgs.filter(img => getComputedStyle(img).display !== 'none');
        await Promise.all(visible.map(img => {
          if (img.complete && img.naturalWidth > 0) return Promise.resolve();
          return new Promise(resolve => img.addEventListener('load', resolve, { once: true }));
        }));
        await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
        return true;
      })()
    `,
    awaitPromise: true,
  })

  const measureResult = await client.send("Runtime.evaluate", {
    expression: `
      JSON.stringify((() => {
        const thumb = document.querySelector('.pk-about-map-thumb');
        const thumbRect = thumb.getBoundingClientRect();

        const imgs = Array.from(thumb.querySelectorAll('img')).filter(
          img => getComputedStyle(img).display !== 'none'
        );
        const images = imgs.map(img => {
          const r = img.getBoundingClientRect();
          const cs = getComputedStyle(img);
          return {
            rect: { x: r.x, y: r.y, width: r.width, height: r.height },
            naturalWidth: img.naturalWidth,
            naturalHeight: img.naturalHeight,
            src: img.currentSrc || img.src,
            objectFit: cs.objectFit,
            objectPosition: cs.objectPosition,
          };
        });

        const labels = Array.from(document.querySelectorAll('.pk-about-map-label')).filter(
          el => getComputedStyle(el).display !== 'none'
        );
        const label = labels.length
          ? (() => {
              const r = labels[0].getBoundingClientRect();
              return { x: r.x, y: r.y, width: r.width, height: r.height };
            })()
          : null;

        // Root font-size, so the Node side can reproduce the 7rem min-height
        // floor for the pre-fix (legacy) geometry reconstruction without
        // hard-coding a 16px assumption.
        const rootFontSizePx = parseFloat(getComputedStyle(document.documentElement).fontSize);

        return {
          thumbRect: { x: thumbRect.x, y: thumbRect.y, width: thumbRect.width, height: thumbRect.height },
          // Page.captureScreenshot's clip is relative to the DOCUMENT
          // (page) origin, not the current scrolled viewport --
          // getBoundingClientRect() above is viewport-relative, so the
          // scroll offset has to be added back on the Node side before it
          // is used as a capture clip origin.
          scrollX: window.scrollX,
          scrollY: window.scrollY,
          images,
          label,
          rootFontSizePx,
        };
      })())
    `,
    returnByValue: true,
  })

  return JSON.parse(measureResult.result.value)
}

async function captureThumb({ client, thumbRect }) {
  const shot = await client.send("Page.captureScreenshot", {
    format: "png",
    captureBeyondViewport: false,
    clip: {
      x: thumbRect.x,
      y: thumbRect.y,
      width: thumbRect.width,
      height: thumbRect.height,
      scale: CAPTURE_SCALE,
    },
  })
  return Buffer.from(shot.data, "base64")
}

// ---------------------------------------------------------------------------
// object-fit: cover geometry
// ---------------------------------------------------------------------------
// Given a box and a natural image size under `object-fit: cover`, compute
// the visible SOURCE rectangle (in the image's own natural pixel space),
// honouring `object-position`'s two percentages.
function visibleSourceRect({ boxW, boxH, naturalW, naturalH, objectPositionX, objectPositionY }) {
  const scale = Math.max(boxW / naturalW, boxH / naturalH)
  const renderedW = naturalW * scale
  const renderedH = naturalH * scale

  const overflowX = renderedW - boxW // overflow in RENDERED px
  const overflowY = renderedH - boxH

  // object-position: 0% = image's left/top aligns with box's left/top (all
  // overflow discarded from the right/bottom). 100% = image's right/bottom
  // aligns with box's right/bottom (all overflow discarded from the
  // left/top). The rendered-space offset of the image's top-left corner
  // relative to the box's top-left corner is therefore:
  const offsetXRendered = -overflowX * (objectPositionX / 100)
  const offsetYRendered = -overflowY * (objectPositionY / 100)

  // Convert back to source pixels: divide by scale.
  const visX0 = -offsetXRendered / scale
  const visY0 = -offsetYRendered / scale
  const visX1 = visX0 + boxW / scale
  const visY1 = visY0 + boxH / scale

  return { x0: visX0, y0: visY0, x1: visX1, y1: visY1 }
}

function parseObjectPosition(objectPosition) {
  // computed value is always two length/percentage tokens in px or %, e.g.
  // "50% 100%" — this repo only ever uses percentages here.
  const parts = objectPosition.trim().split(/\s+/)
  const parse = (tok) => {
    const m = tok.match(/^(-?[\d.]+)%$/)
    if (!m) throw new Error(`Unexpected object-position token: ${tok}`)
    return Number(m[1])
  }
  return { x: parse(parts[0]), y: parse(parts[1]) }
}

function rectsIntersect(a, b) {
  return a.x < b.x + b.width && a.x + a.width > b.x && a.y < b.y + b.height && a.y + a.height > b.y
}

// Reconstructs the visible SOURCE rectangle the box would have shown under
// the PRE-FIX stylesheet: aspect-ratio 21/9 (not derived from the asset),
// the same 7rem min-height floor (unchanged by this plan), and the
// object-position default (50% 50%, since the pre-fix rule declared none).
// Box WIDTH is unaffected by aspect-ratio (it comes from the grid/card
// layout), so the live-measured width is reused; only the height is
// recomputed under the old ratio.
function legacyVisibleSourceRect({ boxW, rootFontSizePx, naturalW, naturalH }) {
  const minHeightPx = 7 * rootFontSizePx
  const ratioHeight = boxW / LEGACY_ASPECT_RATIO
  const boxH = Math.max(ratioHeight, minHeightPx)

  return visibleSourceRect({
    boxW,
    boxH,
    naturalW,
    naturalH,
    objectPositionX: LEGACY_OBJECT_POSITION.x,
    objectPositionY: LEGACY_OBJECT_POSITION.y,
  })
}

function rectsEqual(a, b, eps = 0.01) {
  return (
    Math.abs(a.x0 - b.x0) < eps &&
    Math.abs(a.y0 - b.y0) < eps &&
    Math.abs(a.x1 - b.x1) < eps &&
    Math.abs(a.y1 - b.y1) < eps
  )
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  const { baseUrl, proc: serverProc } = await startDevServer()
  const chrome = await startChrome()

  const runDir = await mkdtemp(join(tmpdir(), "about-map-attrib-run-"))
  log(`Run directory (captures + cases.json): ${runDir}`)

  let exitCode = 0
  const cases = []

  try {
    const conn = await connectCDP(chrome.port)
    const client = conn.client

    for (const viewport of VIEWPORTS) {
      for (const theme of THEMES) {
        const label = `[${viewport}px, ${theme}]`
        try {
          const measured = await runCase({ client, baseUrl, viewport, theme })

          if (measured.images.length !== 1) {
            log(`${label} FAIL: expected exactly 1 visible map <img>, found ${measured.images.length}`)
            exitCode = 1
            continue
          }

          const img = measured.images[0]
          const pos = parseObjectPosition(img.objectPosition)

          const visSrc = visibleSourceRect({
            boxW: measured.thumbRect.width,
            boxH: measured.thumbRect.height,
            naturalW: img.naturalWidth,
            naturalH: img.naturalHeight,
            objectPositionX: pos.x,
            objectPositionY: pos.y,
          })

          const legacySrc = legacyVisibleSourceRect({
            boxW: measured.thumbRect.width,
            rootFontSizePx: measured.rootFontSizePx,
            naturalW: img.naturalWidth,
            naturalH: img.naturalHeight,
          })

          const attribInside =
            ATTRIB_ROW_START >= visSrc.y0 &&
            ATTRIB_ROW_END <= visSrc.y1 &&
            ATTRIB_COL_START >= visSrc.x0 &&
            ATTRIB_COL_END <= visSrc.x1

          log(
            `${label} visible source rect: rows ${visSrc.y0.toFixed(2)}..${visSrc.y1.toFixed(2)}, ` +
              `cols ${visSrc.x0.toFixed(2)}..${visSrc.x1.toFixed(2)}`,
          )
          log(
            `${label} attribution box: rows ${ATTRIB_ROW_START}..${ATTRIB_ROW_END}, ` +
              `cols ${ATTRIB_COL_START}..${ATTRIB_COL_END}`,
          )

          if (!attribInside) {
            log(
              `${label} FAIL: attribution rows/cols outside visible source rect ` +
                `(visible rows ${visSrc.y0.toFixed(2)}..${visSrc.y1.toFixed(2)}, ` +
                `cols ${visSrc.x0.toFixed(2)}..${visSrc.x1.toFixed(2)})`,
            )
            exitCode = 1
          }

          // Project the attribution box back into viewport coordinates and
          // check it does not intersect the visible caption chip.
          let overlapsChip = false
          let chipRelative = null
          if (measured.label) {
            const scaleX = img.rect.width / img.naturalWidth
            const scaleY = img.rect.height / img.naturalHeight
            // visSrc is already the visible window in source px, mapped
            // 1:1 onto the box; the attribution's position within that
            // visible window, scaled to viewport px, plus the box origin:
            const attribViewport = {
              x: img.rect.x + (ATTRIB_COL_START - visSrc.x0) * scaleX,
              y: img.rect.y + (ATTRIB_ROW_START - visSrc.y0) * scaleY,
              width: (ATTRIB_COL_END - ATTRIB_COL_START) * scaleX,
              height: (ATTRIB_ROW_END - ATTRIB_ROW_START) * scaleY,
            }
            overlapsChip = rectsIntersect(attribViewport, measured.label)
            chipRelative = {
              x: measured.label.x - measured.thumbRect.x,
              y: measured.label.y - measured.thumbRect.y,
              width: measured.label.width,
              height: measured.label.height,
            }
          }

          if (overlapsChip) {
            log(`${label} FAIL: attribution overlaps caption chip`)
            exitCode = 1
          }

          // Element-clipped screenshot for the pixel oracle, taken
          // regardless of the two DOM-geometry checks above (not gated
          // behind `continue`): the pixel oracle is an INDEPENDENT
          // confirmation of the geometry model, including — deliberately —
          // when run against a broken stylesheet during the Task 2 sanity
          // check (plan 01.4-10 Task 2, step 10), where the DOM-level
          // checks above already fail and a `continue` here would leave
          // nothing for the pixel oracle to independently reject. `clip` is
          // page-relative, so the scroll offset is added back on top of
          // the viewport-relative thumbRect used everywhere else.
          const png = await captureThumb({
            client,
            thumbRect: {
              ...measured.thumbRect,
              x: measured.thumbRect.x + measured.scrollX,
              y: measured.thumbRect.y + measured.scrollY,
            },
          })
          const pngPath = join(runDir, `thumb-${viewport}-${theme}.png`)
          await writeFile(pngPath, png)

          cases.push({
            viewport,
            theme,
            pngPath: `thumb-${viewport}-${theme}.png`,
            // Both theme variants are byte-identical today (a tracked,
            // accepted deviation — see this plan's frontmatter), but read
            // the file the case's src actually names, not a hard-coded
            // path, so this keeps working the day the dark asset diverges.
            assetPath: img.src.includes("about-maps-thumb-dark.jpg")
              ? "priv/static/images/about-maps-thumb-dark.jpg"
              : ASSET_PATH,
            src: img.src,
            naturalWidth: img.naturalWidth,
            naturalHeight: img.naturalHeight,
            captureScale: CAPTURE_SCALE,
            thumbRect: measured.thumbRect,
            visibleSourceRect: visSrc,
            legacyVisibleSourceRect: legacySrc,
            legacySameAsFixed: rectsEqual(visSrc, legacySrc),
            chipRelativeRect: chipRelative,
            attribBox: {
              rowStart: ATTRIB_ROW_START,
              rowEnd: ATTRIB_ROW_END,
              colStart: ATTRIB_COL_START,
              colEnd: ATTRIB_COL_END,
            },
            attribBandPct: ATTRIB_BAND_PCT,
            assetWidth: ASSET_W,
            assetHeight: ASSET_H,
          })

          if (attribInside && !overlapsChip) log(`${label} PASS`)
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

  if (cases.length !== VIEWPORTS.length * THEMES.length) {
    log(
      `FAIL: expected ${VIEWPORTS.length * THEMES.length} case blocks, only ${cases.length} ` +
        `completed far enough to be captured — a skipped viewport or theme is an unverified ` +
        `viewport or theme.`,
    )
    exitCode = 1
  }

  const casesJsonPath = join(runDir, "cases.json")
  await writeFile(casesJsonPath, JSON.stringify(cases, null, 2))

  if (cases.length > 0) {
    log(`Handing off to the pixel oracle: python3 test/visual/about_map_attribution_pixels.py ${runDir}`)
    const pyExit = await new Promise((resolve) => {
      const py = spawn("python3", ["test/visual/about_map_attribution_pixels.py", runDir], {
        stdio: "inherit",
      })
      py.on("exit", (code) => resolve(code ?? 1))
      py.on("error", (err) => {
        log(`FAIL: could not spawn python3: ${err.message}`)
        resolve(1)
      })
    })
    if (pyExit !== 0) exitCode = 1
  }

  log(`Run directory (captures + cases.json): ${runDir}`)
  process.exit(exitCode)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
