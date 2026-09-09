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
// strings. The sweep loop runs every check against every (viewport, theme,
// height) case. Plans 01.5-07 and 01.5-08 each extend this same file with
// one more check function appended to `CHECKS` — neither needs to touch the
// sweep loop, the dev-server/Chrome lifecycle, or the CDP client below.
//
// Plan 01.5-07 (G-01.5-3 items 3a/3b — .planning/debug/cierre-band-
// whitespace.md) added the HEIGHTS axis to the sweep (the width x theme
// sweep alone, at a single fixed 900px height, cannot observe the Cierre
// gap-evenness defect — the diagnosis proved the asymmetry is invariant to
// HEIGHT, so a single-height sweep would under-test it) and three checks:
// gap evenness, non-zero bottom breathing room at the short height, and
// mobile invariance. Every case now also measures `#cierre` and its
// `.pk-band-inner` content group's rects alongside the existing per-band
// list.
//
// Plan 01.5-08 (G-01.5-3 item 4 — the last open piece of this phase's
// gap-closure round) added: a 560px width to the sweep (the 481-639px
// middle band neither of this phase's media queries governs, and exactly
// where a regime-boundary bug would hide), a `footer` rect alongside the
// per-band list, and two more checks — the last-band-to-footer BUDGET
// (source-level: is there a boundary_collapse/bottom_collapse opt-in at
// all) and the fixed-bar/footer NON-INTERSECTION oracle (the only check
// that can confirm the relocated clearance actually lands where the bar
// is, since a source-level check can only confirm a rule exists, not that
// it matches). The second check needs a scrolled measurement the shared
// per-case sweep doesn't take, so it runs its own small loop after the
// main sweep, at the one width where the fixed bar is visible.
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
//
// Plan 01.5-08 adds 560: the 481-639px range this phase's two media queries
// (the About page's own 480px CTA-bar block, and #cierre's 640px desktop
// treatment) both leave ungoverned — the diagnosis flagged this exact gap as
// where a regime-boundary bug would hide, and it is otherwise never swept.
const VIEWPORTS = [390, 560, 768, 1280]
const THEMES = ["light", "dark"]

// Plan 01.5-07: viewport HEIGHTS swept alongside widths for the Cierre gap
// checks. 400 is the deliberately short case (matches the diagnosis's
// 900x400 row, one of the four short-viewport rows that measured the
// padding shorthand's zeroed bottom component flush against the band's
// edge before this plan's fix); 900 is this file's existing baseline
// height; 1200 is a tall desktop window, included so "several heights" (not
// two) actually exercises the invariant across a spread, not just short vs.
// baseline.
const CIERRE_HEIGHTS = [400, 900, 1200]

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
async function runCase({ client, baseUrl, viewport, theme, height = 900 }) {
  await client.send("Emulation.setDeviceMetricsOverride", {
    width: viewport,
    height,
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
          // Plan 01.5-09 (G-01.5-6 gap closure): every .pk-band has exactly
          // one direct-child .pk-band-inner content group (verified in
          // about_live.ex). Captured per-band, not just for #cierre, so the
          // run-ratio budget below can derive the page's own norm from the
          // OTHER band-to-band content runs instead of hard-coding it.
          const innerEl = el.querySelector('.pk-band-inner');
          const innerRect = innerEl ? innerEl.getBoundingClientRect() : null;
          return {
            index,
            id: el.id || null,
            className: el.className,
            rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
            contentRect: innerRect
              ? { x: innerRect.x, y: innerRect.y, width: innerRect.width, height: innerRect.height }
              : null,
          };
        });

        // Plan 01.5-07: #cierre's own box plus its single content group
        // (.pk-band-inner) — the two rects the gap-evenness/breathing-room/
        // mobile-invariance checks below derive gapTop/gapBottom from.
        // Both null at any width if the element is somehow missing, so a
        // check can report a clear failure instead of throwing on a null
        // deref.
        const cierreEl = document.querySelector('#cierre');
        const cierreInnerEl = cierreEl ? cierreEl.querySelector('.pk-band-inner') : null;
        const cierre = cierreEl
          ? (() => {
              const rect = cierreEl.getBoundingClientRect();
              return { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
            })()
          : null;
        const cierreInner = cierreInnerEl
          ? (() => {
              const rect = cierreInnerEl.getBoundingClientRect();
              return { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
            })()
          : null;

        // Plan 01.5-08: the footer's own rect. Unaffected by scroll position
        // (both it and the last band shift by the same scrollY delta), so
        // this unscrolled measurement is sufficient for the last-band-to-
        // footer BUDGET check below — only the fixed-bar NON-INTERSECTION
        // oracle (its own scrolled measurement pass, later in this file)
        // needs an actual scroll.
        const footerEl = document.querySelector('footer.pk-footer');
        const footer = footerEl
          ? (() => {
              const rect = footerEl.getBoundingClientRect();
              return { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
            })()
          : null;

        // Plan 01.5-09 (G-01.5-5 gap closure): computed backgrounds of the
        // LAST section.pk-band and of the footer — what
        // checkBottomBoundaryBudget below uses to decide whether the flat
        // pixel budget or the same-surface CONTACT rule applies. Read via
        // getComputedStyle so the comparison is on the resolved colour
        // (e.g. "rgb(243, 236, 250)"), not the declared CSS value, which is
        // what actually determines whether the eye reads a boundary here.
        const lastBandEl = nodes.length > 0 ? nodes[nodes.length - 1] : null;
        const lastBandBackground = lastBandEl
          ? getComputedStyle(lastBandEl).backgroundColor
          : null;
        const footerBackground = footerEl ? getComputedStyle(footerEl).backgroundColor : null;

        return { bands, cierre, cierreInner, footer, lastBandBackground, footerBackground };
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

// Sub-pixel tolerance for the Cierre gap checks below. The diagnosis
// measured the shipped defect's asymmetry at exactly one header height
// (64-65px) — anything below 1px is nowhere near that magnitude and is
// ordinary sub-pixel layout rounding, not a regression of the defect.
const CIERRE_GAP_TOLERANCE_PX = 1

// Derives { gapTop, gapBottom } from #cierre's own box and its single
// content group's box. Returns null if either rect is missing (the caller
// turns that into a failure with context instead of throwing).
function cierreGaps(measured) {
  const { cierre, cierreInner } = measured
  if (!cierre || !cierreInner) return null

  const gapTop = cierreInner.y - cierre.y
  const gapBottom = cierre.y + cierre.height - (cierreInner.y + cierreInner.height)
  return { gapTop, gapBottom }
}

// Plan 01.5-07 (G-01.5-3 item 3b — the gap-evenness oracle): at every width
// >=640px, #cierre's top and bottom gaps must be equal within a pixel, at
// every swept viewport HEIGHT — not different by exactly one header height,
// which is exactly what the shipped D-10 padding shorthand did before this
// plan removed it. This is the direct oracle for the defect: the pre-fix
// code fails this check by exactly --pk-header-h at every (width, height)
// combination the diagnosis measured.
function checkCierreGapEvenness(measured, ctx) {
  if (ctx.viewport < 640) return []

  const gaps = cierreGaps(measured)
  if (!gaps) {
    return [
      `#cierre gap evenness: could not measure #cierre and/or its .pk-band-inner ` +
        `content group at [${ctx.viewport}px, ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  const { gapTop, gapBottom } = gaps
  const diff = Math.abs(gapTop - gapBottom)
  if (diff >= CIERRE_GAP_TOLERANCE_PX) {
    return [
      `#cierre gap evenness: gapTop=${gapTop.toFixed(2)}px gapBottom=${gapBottom.toFixed(2)}px ` +
        `diff=${diff.toFixed(2)}px at [${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — ` +
        `expected the two gaps to match within ${CIERRE_GAP_TOLERANCE_PX}px`,
    ]
  }

  return []
}

// Plan 01.5-07 (G-01.5-3 item 3b — the latent third defect the padding
// shorthand's zeroed bottom component created): at the deliberately short
// viewport height, once the min-height floor is exhausted by the band's own
// content, the closing signature must still have non-zero breathing room
// below it — it must never sit flush against the tinted band's bottom
// edge. Scoped to the short height only; the taller heights already have
// ample leftover space and would pass trivially either way.
function checkCierreBottomBreathingRoom(measured, ctx) {
  if (ctx.viewport < 640) return []
  if (ctx.height !== Math.min(...CIERRE_HEIGHTS)) return []

  const gaps = cierreGaps(measured)
  if (!gaps) {
    return [
      `#cierre bottom breathing room: could not measure #cierre and/or its .pk-band-inner ` +
        `content group at [${ctx.viewport}px, ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  if (gaps.gapBottom <= 0) {
    return [
      `#cierre bottom breathing room: gapBottom=${gaps.gapBottom.toFixed(2)}px at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — the closing signature is flush ` +
        `(or overlapping) against the band's bottom edge on this short window`,
    ]
  }

  return []
}

// Plan 01.5-07: confirms the desktop-only gap-evenness/height change did not
// leak below the 640px media gate. Below it, #cierre must still behave like
// every other .pk-band: an even top/bottom split, and a height close to its
// content plus the shared band padding (2 x 4.5rem = 144px) — NOT the
// desktop min-height floor.
function checkCierreMobileInvariance(measured, ctx) {
  if (ctx.viewport >= 640) return []

  const gaps = cierreGaps(measured)
  if (!gaps || !measured.cierre || !measured.cierreInner) {
    return [
      `#cierre mobile invariance: could not measure #cierre and/or its .pk-band-inner ` +
        `content group at [${ctx.viewport}px, ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  const failures = []
  const diff = Math.abs(gaps.gapTop - gaps.gapBottom)
  if (diff >= CIERRE_GAP_TOLERANCE_PX) {
    failures.push(
      `#cierre mobile invariance: gapTop=${gaps.gapTop.toFixed(2)}px ` +
        `gapBottom=${gaps.gapBottom.toFixed(2)}px diff=${diff.toFixed(2)}px at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — expected the shared .pk-band ` +
        `even split below the 640px media gate`,
    )
  }

  const SHARED_BAND_PADDING_PX = 144 // 2 x 4.5rem, .pk-band's own padding
  const expectedHeight = measured.cierreInner.height + SHARED_BAND_PADDING_PX
  const heightDiff = Math.abs(measured.cierre.height - expectedHeight)
  if (heightDiff >= 1) {
    failures.push(
      `#cierre mobile invariance: band height=${measured.cierre.height.toFixed(2)}px, expected ` +
        `~${expectedHeight.toFixed(2)}px (content ${measured.cierreInner.height.toFixed(2)}px + ` +
        `shared band padding ${SHARED_BAND_PADDING_PX}px) at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — the desktop min-height floor must ` +
        `not apply below the media gate`,
    )
  }

  return failures
}

// Plan 01.5-09 (G-01.5-6 gap closure, 2026-09-09 —
// .planning/debug/G-01.5-6-cierre-top-bottom-whitespace.md). The prior
// oracle here (CIERRE_DESKTOP_GAP_TARGET_PX, deleted) hard-coded 128 —
// "matches app.css's padding-block" was its own comment — so it asserted
// the presence of exactly the value under complaint and failed on any
// legitimate retune, the same class of mistake `checkBottomBoundaryBudget`
// made before plan 01.5-09's Task 1 fixed it one level down. Replaced with
// a DERIVED budget: the closing band's inbound CONTENT RUN (previous
// band's content-group bottom edge to #cierre's own content-group top
// edge — the quantity the eye actually judges, which is why the
// box-level 0.00px gap checkAdjacentBandContact already confirms says
// nothing about proportion) must not exceed this page's OWN measured norm
// (the typical run at every OTHER band-to-band boundary, all ~144px per
// the diagnosis) by more than a stated factor. Both sides are measured
// live every run, so a future retune of either #cierre's own padding or
// the shared .pk-band padding moves this check's baseline with it instead
// of invalidating it.
//
// Budget derivation: at the shipped 5rem retune the run is ~152px against
// a ~144px norm (a 5.6% step); the prior 8rem defect measured ~200px (a
// 39% outlier). 1.15 (15%) sits comfortably above the retuned value's own
// ratio while leaving no room for the old defect to sneak back through —
// it would need the run to fall to within 15% of norm, i.e. under ~166px,
// well short of the 200px the shipped bug produced.
const CIERRE_RUN_RATIO_BUDGET = 1.15

// From one band's content-group bottom edge to the next band's
// content-group top edge. Null if either content rect is missing, so the
// caller can report a clear failure instead of computing NaN silently.
function bandContentRun(fromBand, toBand) {
  if (!fromBand?.contentRect || !toBand?.contentRect) return null
  return toBand.contentRect.y - (fromBand.contentRect.y + fromBand.contentRect.height)
}

function checkCierreRunRatioBudget(measured, ctx) {
  if (ctx.viewport < 640) return []

  const { bands } = measured
  const cierreIndex = bands.findIndex((b) => b.id === "cierre")
  if (cierreIndex <= 0) {
    return [
      `#cierre run-ratio budget: could not locate #cierre with a preceding band at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  const closingRun = bandContentRun(bands[cierreIndex - 1], bands[cierreIndex])

  // The page's own norm: the OTHER band-to-band content runs, excluding the
  // boundary into #cierre itself (that is the value under test, not part of
  // the baseline it is judged against).
  const otherRuns = []
  for (let i = 0; i < bands.length - 1; i++) {
    if (i === cierreIndex - 1) continue
    const run = bandContentRun(bands[i], bands[i + 1])
    if (run != null) otherRuns.push(run)
  }

  if (closingRun == null || otherRuns.length === 0) {
    return [
      `#cierre run-ratio budget: could not measure the inbound content run and/or the page's ` +
        `own comparison runs at [${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  const sorted = [...otherRuns].sort((a, b) => a - b)
  const mid = Math.floor(sorted.length / 2)
  const norm =
    sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]

  if (norm <= 0) {
    return [
      `#cierre run-ratio budget: page's own measured norm is non-positive (${norm.toFixed(2)}px) ` +
        `at [${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — cannot compute a ratio`,
    ]
  }

  const ratio = closingRun / norm
  if (ratio > CIERRE_RUN_RATIO_BUDGET) {
    return [
      `#cierre run-ratio budget: inbound run=${closingRun.toFixed(2)}px, page's own norm=` +
        `${norm.toFixed(2)}px, ratio=${ratio.toFixed(3)}, budget=${CIERRE_RUN_RATIO_BUDGET} at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — the closing band's inbound run is ` +
        `disproportionate against this page's own established rhythm. A ratio growing with ` +
        `${ctx.height}px viewport height is exactly the height-relative regression this budget also ` +
        `exists to catch — see the CSS comment above #cierre's >=640px rule for the full incident.`,
    ]
  }

  return []
}

// Plan 01.5-08 (G-01.5-3 item 4). Budget, not a single number — the catalog
// index and game detail pages this fix matches already render 16px at
// <=480px and 24px at >=481px (quick task 260902-il3's own measured split,
// the same split main.pk-bottom-collapse's shared declarations in app.css
// produce). A 2px headroom above each measured target absorbs ordinary
// sub-pixel layout rounding without coming anywhere near hiding a
// regression the size of the original defect (112-200px).
const BOTTOM_BOUNDARY_BUDGET_MOBILE_PX = 18 // 16px target + 2px rounding headroom, <=480px
const BOTTOM_BOUNDARY_BUDGET_PX = 26 // 24px target + 2px rounding headroom, >=481px

// Plan 01.5-09 (G-01.5-5 gap closure). The flat pixel budget above passed
// on the reported defect: 24.00px satisfied `<= 26`, because the budget was
// a correctly-implemented statement of a target that contradicted the UAT
// truth sitting next to it — the real property is not "small enough gap"
// but "no visible seam between two surfaces the eye reads as one". This
// check is now surface-conditional: when the last band's computed
// background equals the footer's computed background (the About page,
// where #cierre's tint and .pk-footer paint the identical token), it
// requires CONTACT within the same tolerance every other band-to-band
// boundary on the page already uses (checkAdjacentBandContact's own
// CONTACT_TOLERANCE_PX) — a same-surface sandwich is only invisible at
// zero. When the backgrounds differ (the catalog index, the detail page —
// where the last in-flow element never paints a background at all), the
// flat budget behaviour is unchanged, so this check still means something
// on a future page that has its own, different surface relationship.
function checkBottomBoundaryBudget(measured, ctx) {
  const { bands, footer, lastBandBackground, footerBackground } = measured

  if (!footer || bands.length === 0) {
    return [
      `bottom boundary budget: could not measure the last section.pk-band and/or <footer> at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  const lastBand = bands[bands.length - 1]
  const distance = footer.y - (lastBand.rect.y + lastBand.rect.height)
  const surfacesMatch =
    lastBandBackground != null && lastBandBackground === footerBackground

  if (surfacesMatch) {
    if (Math.abs(distance) > CONTACT_TOLERANCE_PX) {
      return [
        `bottom boundary budget: ${bandLabel(lastBand)} and <footer> paint the identical ` +
          `computed background (${lastBandBackground}) — expected contact (within ` +
          `${CONTACT_TOLERANCE_PX}px, the same rule every other boundary on this page follows), ` +
          `measured a ${distance.toFixed(2)}px gap at [${ctx.viewport}px x ${ctx.height}px, ` +
          `${ctx.theme}] — a same-token sandwich reads as a visible stripe at any non-zero size.`,
      ]
    }
    return []
  }

  const budget = ctx.viewport <= 480 ? BOTTOM_BOUNDARY_BUDGET_MOBILE_PX : BOTTOM_BOUNDARY_BUDGET_PX

  if (distance > budget) {
    return [
      `bottom boundary budget: measured ${distance.toFixed(2)}px between ` +
        `${bandLabel(lastBand)} (${lastBandBackground}) and <footer> (${footerBackground}), ` +
        `expected <= ${budget}px at [${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  if (distance < -CONTACT_TOLERANCE_PX) {
    return [
      `bottom boundary budget: ${bandLabel(lastBand)} overlaps <footer> by ` +
        `${(-distance).toFixed(2)}px at [${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  return []
}

// Named list of check functions the sweep loop calls. Plans 01.5-07 and
// 01.5-08 each add one more entry here for their own oracle.
const CHECKS = [
  checkAdjacentBandContact,
  checkCierreGapEvenness,
  checkCierreRunRatioBudget,
  checkCierreBottomBreathingRoom,
  checkCierreMobileInvariance,
  checkBottomBoundaryBudget,
]

// ---------------------------------------------------------------------------
// Plan 01.5-08: fixed-bar / footer non-intersection oracle
// ---------------------------------------------------------------------------
// The only oracle that can confirm Task 2's actual claim. A source-level
// test can confirm the body:has(.pk-about-cta-bar) clearance rule EXISTS;
// it cannot confirm the reserved amount actually lands where the fixed bar
// is once the page is scrolled to its real bottom. Runs its own small loop
// (below, in main()) at the one width where the bar is visible, since it
// needs an actual scroll — the shared per-case sweep above is deliberately
// unscrolled (see the footer-rect comment in runCase).
const CTA_BAR_VISIBLE_WIDTH = 390 // <=480px, matches app.css's own threshold

async function runBottomClearanceCase({ client, baseUrl, viewport, theme }) {
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
        // Scrolled to the real page bottom — the only scroll position
        // where a clearance defect can be observed at all: the fixed bar
        // always covers the same viewport-relative slice, so only once the
        // footer has scrolled as far up as it will go does "does the bar
        // cover it" become answerable.
        //
        // { behavior: 'instant' } is load-bearing, not decorative: app.css
        // declares html { scroll-behavior: smooth } (gated on
        // prefers-reduced-motion: no-preference, which headless Chrome
        // reports by default), so a bare scrollTo(x, y) call ANIMATES here
        // exactly as it does for a real visitor, and reading
        // getBoundingClientRect() synchronously afterward would observe the
        // pre-scroll position (scrollY still 0) rather than the settled one
        // — this cost real debugging time working out why an early version
        // of this check measured a ~2800px "overlap" that was actually just
        // an unscrolled page. Per the CSSOM View spec, an explicit
        // 'behavior' option in ScrollToOptions overrides the element's own
        // CSS scroll-behavior, which is exactly the override needed for a
        // synchronous measurement.
        window.scrollTo({ top: document.body.scrollHeight, left: 0, behavior: "instant" });

        const rectOf = (el) => {
          if (!el) return null;
          const r = el.getBoundingClientRect();
          return { x: r.x, y: r.y, width: r.width, height: r.height };
        };

        return {
          bar: rectOf(document.querySelector('.pk-about-cta-bar')),
          footer: rectOf(document.querySelector('footer.pk-footer')),
        };
      })())
    `,
    returnByValue: true,
  })

  return JSON.parse(measureResult.result.value)
}

function checkFixedBarFooterClearance(measured, ctx) {
  const { bar, footer } = measured

  if (!bar) {
    return [`fixed-bar footer clearance: could not measure .pk-about-cta-bar at [${ctx.viewport}px, ${ctx.theme}]`]
  }
  if (bar.width === 0 || bar.height === 0) {
    return [
      `fixed-bar footer clearance: .pk-about-cta-bar has a zero-size rect at ` +
        `[${ctx.viewport}px, ${ctx.theme}] — expected it visible (display: block) at this width`,
    ]
  }
  if (!footer) {
    return [`fixed-bar footer clearance: could not measure <footer> at [${ctx.viewport}px, ${ctx.theme}]`]
  }

  const overlap = footer.y + footer.height - bar.y
  if (overlap > CONTACT_TOLERANCE_PX) {
    return [
      `fixed-bar footer clearance: the fixed bar overlaps the footer by ` +
        `${overlap.toFixed(2)}px at [${ctx.viewport}px, ${ctx.theme}] (footer bottom=` +
        `${(footer.y + footer.height).toFixed(2)}, bar top=${bar.y.toFixed(2)}) — the ` +
        `document-end clearance is not reserving enough (or is not applying at all)`,
    ]
  }

  return []
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
        for (const height of CIERRE_HEIGHTS) {
          const label = `[${viewport}px x ${height}px, ${theme}]`

          try {
            const measured = await runCase({ client, baseUrl, viewport, theme, height })
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

            const gaps = cierreGaps(measured)
            if (gaps) {
              log(
                `${label} #cierre: gapTop=${gaps.gapTop.toFixed(2)}px ` +
                  `gapBottom=${gaps.gapBottom.toFixed(2)}px`,
              )
            }

            if (measured.footer && measured.bands.length > 0) {
              const lastBand = measured.bands[measured.bands.length - 1]
              const boundaryDistance =
                measured.footer.y - (lastBand.rect.y + lastBand.rect.height)
              log(`${label} last-band-to-footer: ${boundaryDistance.toFixed(2)}px`)
            }

            for (const check of CHECKS) {
              const failures = check(measured, { viewport, theme, height })
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
    }

    // Plan 01.5-08: fixed-bar/footer non-intersection, its own small loop —
    // scroll-dependent, so it cannot share the unscrolled per-case sweep
    // above. Runs at the one width where the bar is visible (390, <=480px),
    // in both themes for the same coverage the rest of this file gives.
    for (const theme of THEMES) {
      const label = `[${CTA_BAR_VISIBLE_WIDTH}px @ page-bottom, ${theme}]`

      try {
        const measured = await runBottomClearanceCase({
          client,
          baseUrl,
          viewport: CTA_BAR_VISIBLE_WIDTH,
          theme,
        })
        casesRun++

        if (measured.bar) {
          log(
            `${label} bar top=${measured.bar.y.toFixed(2)} footer bottom=` +
              `${measured.footer ? (measured.footer.y + measured.footer.height).toFixed(2) : "?"}`,
          )
        }

        for (const failure of checkFixedBarFooterClearance(measured, {
          viewport: CTA_BAR_VISIBLE_WIDTH,
          theme,
        })) {
          log(`${label} FAIL: ${failure}`)
          exitCode = 1
        }
      } catch (err) {
        log(`${label} FAIL: ${err.message}`)
        exitCode = 1
      }
    }
  } finally {
    await stopChrome(chrome)
    await stopDevServer(serverProc)
  }

  const expectedCases = VIEWPORTS.length * THEMES.length * CIERRE_HEIGHTS.length + THEMES.length
  if (casesRun !== expectedCases) {
    log(
      `FAIL: expected ${expectedCases} case blocks, only ${casesRun} ` +
        `completed far enough to be reported — a skipped viewport, theme or height is an ` +
        `unverified viewport, theme or height.`,
    )
    exitCode = 1
  }

  process.exit(exitCode)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
