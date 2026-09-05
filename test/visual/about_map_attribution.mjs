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

        // G-01.4-5, plan 01.4-11: the credit Task 1 added. "Legible" is a
        // real-browser claim (rendered size, painted colour, whether it is
        // actually visible) that the markup-level ExUnit suite cannot make
        // — a zero-height box, a hidden-visibility ancestor, or a colour
        // that vanishes into its background would all pass a DOM-presence
        // check and fail every person looking at the page.
        const contactoEl = document.querySelector('#contacto');
        const contactoRectRaw = contactoEl ? contactoEl.getBoundingClientRect() : null;
        const contactoRect = contactoRectRaw
          ? { x: contactoRectRaw.x, y: contactoRectRaw.y, width: contactoRectRaw.width, height: contactoRectRaw.height }
          : null;

        const creditEls = document.querySelectorAll('.pk-about-map-credit');
        let credit = null;
        if (creditEls.length === 1) {
          const el = creditEls[0];
          const r = el.getBoundingClientRect();
          const cs = getComputedStyle(el);

          // Walk up from the credit to find the nearest ancestor whose
          // OWN background-color actually paints something (not fully
          // transparent) — the surface the credit's text is read against.
          // .pk-about-contact-card (bg-base-200) is the expected hit.
          let bgNode = el;
          let backgroundColor = null;
          while (bgNode) {
            const bg = getComputedStyle(bgNode).backgroundColor;
            const m = bg.match(/rgba?\(([^)]+)\)/);
            if (m) {
              const parts = m[1].split(',').map((s) => parseFloat(s.trim()));
              const alpha = parts.length > 3 ? parts[3] : 1;
              if (alpha > 0) {
                backgroundColor = bg;
                break;
              }
            }
            bgNode = bgNode.parentElement;
          }

          credit = {
            rect: { x: r.x, y: r.y, width: r.width, height: r.height },
            fontSize: parseFloat(cs.fontSize),
            color: cs.color,
            visibility: cs.visibility,
            opacity: parseFloat(cs.opacity),
            textContent: el.textContent,
            backgroundColor,
            hasAnchor: el.querySelector('a') !== null,
          };
        }

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
          contactoRect,
          creditCount: creditEls.length,
          credit,
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
// WCAG contrast (credit legibility, G-01.4-5 plan 01.4-11)
// ---------------------------------------------------------------------------
// Parses a computed `rgb(r, g, b)` / `rgba(r, g, b, a)` string (the only
// shape `getComputedStyle(...).color`/`.backgroundColor` ever return) into
// [r, g, b], 0-255 each.
function parseRgbString(str) {
  const m = str.match(/rgba?\(([^)]+)\)/)
  if (!m) throw new Error(`Unexpected computed colour string: ${str}`)
  const parts = m[1].split(",").map((s) => parseFloat(s.trim()))
  return [parts[0], parts[1], parts[2]]
}

// sRGB relative luminance, per the WCAG 2.x formula
// (https://www.w3.org/TR/WCAG21/#dfn-relative-luminance) — computed from
// the LIVE computed colour values, never a hard-coded token hex, so this
// keeps working through a theme edit rather than silently drifting from
// what the browser actually painted.
function relativeLuminance([r, g, b]) {
  const channel = (c) => {
    const s = c / 255
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4)
  }
  const [rl, gl, bl] = [channel(r), channel(g), channel(b)]
  return 0.2126 * rl + 0.7152 * gl + 0.0722 * bl
}

function contrastRatio(rgbA, rgbB) {
  const lA = relativeLuminance(rgbA)
  const lB = relativeLuminance(rgbB)
  const lighter = Math.max(lA, lB)
  const darker = Math.min(lA, lB)
  return (lighter + 0.05) / (darker + 0.05)
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

          // -------------------------------------------------------------
          // Plan 01.4-11 (G-01.4-5, second half): the credit Task 1 added.
          // The markup-level ExUnit suite can see the credit exists and
          // carries the right classes/text — it structurally cannot see
          // whether it PAINTS: a real rendered size, a colour that
          // actually contrasts against the card, or a rect that stays
          // inside #contacto and clear of the clipping thumbnail. That is
          // this real-browser probe's job.
          // -------------------------------------------------------------
          let creditContrast = null
          let creditOk = true
          if (measured.creditCount !== 1) {
            log(
              `${label} FAIL: no .pk-about-map-credit found ` +
                `(expected exactly 1, found ${measured.creditCount})`,
            )
            exitCode = 1
            creditOk = false
          } else {
            const credit = measured.credit

            if (credit.rect.width <= 0 || credit.rect.height <= 0) {
              log(
                `${label} FAIL: credit rect is ${credit.rect.width.toFixed(2)}x` +
                  `${credit.rect.height.toFixed(2)} — a credit that renders to nothing is not attribution`,
              )
              exitCode = 1
              creditOk = false
            }

            if (credit.visibility !== "visible" || credit.opacity !== 1) {
              log(
                `${label} FAIL: credit visibility="${credit.visibility}" opacity=${credit.opacity} ` +
                  `— expected visible/1`,
              )
              exitCode = 1
              creditOk = false
            }

            if (credit.fontSize < 12) {
              log(
                `${label} FAIL: credit font-size ${credit.fontSize.toFixed(2)}px below 12px ` +
                  `(the design system's muted tier, and the floor that distinguishes this from ` +
                  `the 2.5-5.9 CSS px baked-in mark it exists to supplement)`,
              )
              exitCode = 1
              creditOk = false
            }

            if (!credit.textContent.includes("Google")) {
              log(`${label} FAIL: credit text does not contain "Google" (got "${credit.textContent}")`)
              exitCode = 1
              creditOk = false
            }

            if (credit.hasAnchor) {
              log(`${label} FAIL: credit contains a nested anchor — must be plain text, not a link`)
              exitCode = 1
              creditOk = false
            }

            if (!measured.contactoRect) {
              log(`${label} FAIL: #contacto not found — cannot check credit containment`)
              exitCode = 1
              creditOk = false
            } else if (!rectContains(measured.contactoRect, credit.rect)) {
              log(
                `${label} FAIL: credit rect not contained in #contacto rect ` +
                  `(credit ${JSON.stringify(credit.rect)}, #contacto ${JSON.stringify(measured.contactoRect)})`,
              )
              exitCode = 1
              creditOk = false
            }

            if (rectsIntersect(credit.rect, measured.thumbRect)) {
              log(
                `${label} FAIL: credit rect intersects .pk-about-map-thumb rect ` +
                  `— .pk-about-map-thumb clips with overflow: hidden, so any overlap is a ` +
                  `credit at risk of the same fate as the baked-in wordmark`,
              )
              exitCode = 1
              creditOk = false
            }

            if (!credit.backgroundColor) {
              log(`${label} FAIL: could not resolve a non-transparent ancestor background for the credit`)
              exitCode = 1
              creditOk = false
            } else {
              const textRgb = parseRgbString(credit.color)
              const bgRgb = parseRgbString(credit.backgroundColor)
              creditContrast = contrastRatio(textRgb, bgRgb)
              log(`${label} credit contrast: ${creditContrast.toFixed(2)}:1`)

              if (creditContrast < 4.5) {
                log(
                  `${label} FAIL: credit contrast ${creditContrast.toFixed(2)}:1 below 4.5:1 ` +
                    `(color ${credit.color} on ${credit.backgroundColor})`,
                )
                exitCode = 1
                creditOk = false
              }
            }

            log(
              `${label} credit: rect ${JSON.stringify(credit.rect)}, font-size ` +
                `${credit.fontSize.toFixed(2)}px, contrast ${creditContrast ? creditContrast.toFixed(2) : "n/a"}:1`,
            )
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
          //
          // `clip` stays the THUMBNAIL rect ONLY — plan 01.4-11 deliberately
          // does NOT widen it to also cover the new credit below the image.
          // The pixel oracle's expected-crop reconstruction (below) is
          // defined against the image box; widening the clip would break
          // that reconstruction's own geometry assumptions. The credit's
          // legibility is fully covered by the DOM-measured assertions
          // above (rect, font-size, contrast) — it does not need a second,
          // pixel-level oracle.
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

          if (attribInside && !overlapsChip && creditOk) log(`${label} PASS`)
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

  // Plan 01.4-11 Task 2, step 5: leave a live environment for the Task 3
  // human checkpoint instead of tearing everything down. Started ONLY
  // after a fully green run — the checkpoint rule that a verification
  // environment must never be presented against a dead (or broken) server.
  // This is a SEPARATE, detached process from the probe's own ephemeral
  // `serverProc` above (already stopped in the `finally` block) — that one
  // exists only for the duration of the CDP run.
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
