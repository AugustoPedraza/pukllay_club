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
//
// Plan 01.5-13 (G-01.5-10 gap closure) adds 320: this phase's narrowest
// supported width, and the one landmine 4 of that plan's debug session
// flagged by name — at 375px a 32px heading measures 218.3px in a ~347px
// content box (63% fill), but the box shrinks to ~292px at 320px, so the
// margin against a wrap shrinks too. Every check in CHECKS below now also
// runs at this width for the first time it is swept; per that plan's own
// SUMMARY, any pre-existing failure that surfaces here for a reason
// unrelated to G-01.5-10 is recorded as a finding, not silently excluded.
const VIEWPORTS = [320, 390, 560, 768, 1280]
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

        // Plan 01.5-13 (G-01.5-10 gap closure): #cierre's own COMPUTED
        // vertical padding, read live via getComputedStyle rather than
        // assumed from the stylesheet's declared literal — this is the
        // operand checkCierreMobileInvariance below re-derives its
        // expectation from, replacing the SHARED_BAND_PADDING_PX=144
        // literal that pinned the check to exactly the value this plan
        // changes (the same class of mistake CIERRE_DESKTOP_GAP_TARGET_PX
        // made one level up, which plan 01.5-09 had to replace with a
        // derived budget before it could ship a legitimate retune).
        const cierrePadding = cierreEl
          ? (() => {
              const cs = getComputedStyle(cierreEl);
              return { top: parseFloat(cs.paddingTop), bottom: parseFloat(cs.paddingBottom) };
            })()
          : null;

        // Plan 01.5-13: the closing heading's own rendered box (width — the
        // #cierre .pk-band-inner column is display:flex with
        // align-items:center, so a block-level h2 with no explicit width
        // shrink-wraps to its own ink width rather than stretching to the
        // column's full cross-axis size, the same reasoning E-02 already
        // relied on measuring the pre-fix 163.73px heading box) plus its
        // rendered LINE COUNT, measured via a Range over its own text
        // node's getClientRects() — one ClientRect per wrapped line — so
        // the no-wrap check below can distinguish "one line, wide" from
        // "wrapped onto two lines" even if both report a similar box width
        // (the box itself is capped by the column, not by the text).
        const cierreH2El = cierreEl ? cierreEl.querySelector('h2') : null;
        const cierreHeading = cierreH2El
          ? (() => {
              const rect = cierreH2El.getBoundingClientRect();
              const textNode = Array.from(cierreH2El.childNodes).find(
                (n) => n.nodeType === Node.TEXT_NODE && n.textContent.trim().length > 0,
              );
              let lineCount = null;
              if (textNode) {
                const range = document.createRange();
                range.selectNodeContents(textNode);
                lineCount = range.getClientRects().length;
              }
              return { width: rect.width, height: rect.height, lineCount };
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

        // Plan 01.5-10 (G-01.5-4 gap closure): the closing band's Sumate
        // anchor. pk-sumate-btn (app.css) declares min-height/padding-
        // inline/border-radius/font-size, but neither it nor daisyUI's own
        // .btn ever declares literal vertical (block) padding — both the
        // design source (sketch 051's .btn-sumate: 'padding: 0 28px') and
        // this app's .btn architecture centre the label vertically via
        // flex + min-height, not via a padding-block property. That is why
        // the diagnosis's own padding-ratio figures (1.03:1 / 1.74:1 /
        // 2.15:1) are NOT literal CSS padding-inline/padding-block — a
        // literal padding-block-start reads 0px in every one of those three
        // states, which would make a ratio against it always infinite and
        // unable to distinguish a squat box from a well-proportioned one.
        // The diagnosis instead derived a vertical INSET from the box
        // height minus the label's own rendered ink height, halved — this
        // measures the SAME visual quantity a padding-block property would
        // if one existed. Reproduced here via a Range over the anchor's
        // text node, which is what "ink" means throughout this file's
        // debug sessions (the rendered glyph box, not the CSS line box).
        const sumateAnchorEl = document.querySelector('#cierre .pk-about-cierre-cta a');
        const sumateCta = sumateAnchorEl
          ? (() => {
              const rect = sumateAnchorEl.getBoundingClientRect();
              const cs = getComputedStyle(sumateAnchorEl);
              const textNode = Array.from(sumateAnchorEl.childNodes).find(
                (n) => n.nodeType === Node.TEXT_NODE && n.textContent.trim().length > 0,
              );
              let inkHeight = null;
              if (textNode) {
                const range = document.createRange();
                range.selectNodeContents(textNode);
                inkHeight = range.getBoundingClientRect().height;
              }
              return {
                rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
                paddingInlineStart: parseFloat(cs.paddingInlineStart),
                borderTopLeftRadius: parseFloat(cs.borderTopLeftRadius),
                fontSize: parseFloat(cs.fontSize),
                inkHeight,
              };
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

        // Plan 01.5-11 (G-01.5-8 gap closure, second lever): computed
        // font-size and colour of the Cierre closing signature and of
        // .pk-footer-meta — the exact five-attribute-collision pair the
        // diagnosis measured (font-size and colour are the two properties
        // this fix's own >= 640px rule can move; line-height/family/weight
        // are shared type-scale defaults this fix does not touch). Read via
        // getComputedStyle, same reasoning as lastBandBackground/
        // footerBackground above: the resolved value is what the eye reads,
        // not the declared rule. Also captures the signature's own
        // rendered width, following sumateCta's pattern above, so this
        // task's whole >= 640px scoping argument (the signature's width is
        // an operand G-01.5-10 spends and must not move) is evidenced
        // rather than merely asserted.
        const signatureEl = document.querySelector('#cierre .pk-about-closing-meta');
        const footerMetaEl = document.querySelector('.pk-footer-meta');
        const signatureType = signatureEl
          ? (() => {
              const cs = getComputedStyle(signatureEl);
              const rect = signatureEl.getBoundingClientRect();
              return { fontSize: cs.fontSize, color: cs.color, width: rect.width };
            })()
          : null;
        const footerMetaType = footerMetaEl
          ? (() => {
              const cs = getComputedStyle(footerMetaEl);
              return { fontSize: cs.fontSize, color: cs.color };
            })()
          : null;

        return {
          bands,
          cierre,
          cierreInner,
          cierrePadding,
          cierreHeading,
          footer,
          lastBandBackground,
          footerBackground,
          sumateCta,
          signatureType,
          footerMetaType,
        };
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
// every other .pk-band: an even top/bottom split, and a height that is
// exactly its own content plus its OWN declared padding — NOT the desktop
// min-height floor.
//
// Plan 01.5-13 (G-01.5-10 gap closure) RE-DERIVES the height half of this
// check rather than re-pinning it. The original body here hard-coded
// `SHARED_BAND_PADDING_PX = 144` (2 x the shared `.pk-band` padding) and
// asserted the mobile band's height equals its content plus that literal —
// i.e. it pinned the mobile band to EXACTLY the padding value this plan's
// own gap closure changes (2.5rem/40px per side, not 4.5rem/72px). Left
// alone it would fail this plan's own correct fix; nudged to a new literal
// it would re-arm the identical trap for the next retune — the same class
// of mistake `CIERRE_DESKTOP_GAP_TARGET_PX` made one level up, which plan
// 01.5-09 had to replace with a derived budget before it could ship a
// legitimate retune (see checkCierreRunRatioBudget's own comment above for
// that precedent). A check that restates the CSS it tests fails every
// legitimate retune and catches no defect.
//
// Re-derived: the expected height is now #cierre's own content-group height
// PLUS its own COMPUTED padding (`cierrePadding`, captured live in runCase
// via getComputedStyle — not a literal anywhere in this function), and a
// second assertion confirms that computed padding is itself symmetric
// top/bottom. Written this way the check still catches exactly what it was
// built to catch — a desktop-only treatment leaking below the gate (the
// band's rendered height would then diverge from content + ITS OWN padding
// by the min-height floor's slack) or an accidental asymmetric padding —
// while surviving every future deliberate retune of the mobile padding
// value, including this one.
function checkCierreMobileInvariance(measured, ctx) {
  if (ctx.viewport >= 640) return []

  const gaps = cierreGaps(measured)
  if (!gaps || !measured.cierre || !measured.cierreInner || !measured.cierrePadding) {
    return [
      `#cierre mobile invariance: could not measure #cierre, its .pk-band-inner content group ` +
        `and/or its computed padding at [${ctx.viewport}px, ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  const failures = []
  const diff = Math.abs(gaps.gapTop - gaps.gapBottom)
  if (diff >= CIERRE_GAP_TOLERANCE_PX) {
    failures.push(
      `#cierre mobile invariance: gapTop=${gaps.gapTop.toFixed(2)}px ` +
        `gapBottom=${gaps.gapBottom.toFixed(2)}px diff=${diff.toFixed(2)}px at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — expected an even top/bottom split ` +
        `below the 640px media gate (this guard survives any deliberate padding retune; it only ever ` +
        `fails on an ASYMMETRIC one)`,
    )
  }

  const { top: paddingTop, bottom: paddingBottom } = measured.cierrePadding
  const paddingDiff = Math.abs(paddingTop - paddingBottom)
  if (paddingDiff >= CIERRE_GAP_TOLERANCE_PX) {
    failures.push(
      `#cierre mobile invariance: computed padding-top=${paddingTop.toFixed(2)}px ` +
        `padding-bottom=${paddingBottom.toFixed(2)}px diff=${paddingDiff.toFixed(2)}px at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — #cierre's own mobile padding must ` +
        `stay symmetric, whatever its magnitude`,
    )
  }

  const expectedHeight = measured.cierreInner.height + paddingTop + paddingBottom
  const heightDiff = Math.abs(measured.cierre.height - expectedHeight)
  if (heightDiff >= 1) {
    failures.push(
      `#cierre mobile invariance: band height=${measured.cierre.height.toFixed(2)}px, expected ` +
        `~${expectedHeight.toFixed(2)}px (content ${measured.cierreInner.height.toFixed(2)}px + ` +
        `the band's OWN computed padding, read live: ${paddingTop.toFixed(2)}px + ` +
        `${paddingBottom.toFixed(2)}px) at [${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — ` +
        `the desktop min-height floor (or any other treatment scoped to >=640px) must not apply ` +
        `below the media gate`,
    )
  }

  return failures
}

// Plan 01.5-13 (G-01.5-10 gap closure), first of three NEW checks —
// PROPORTION, the "it has too much space" clause. `checkCierreRunRatioBudget`
// below already derives a budget live from this page's OTHER bands; this
// check applies the same derived-not-literal shape one axis over: THIS
// band's own mobile padding-to-content ratio, judged against THIS SAME
// band's own DESKTOP padding-to-content ratio, measured live in this same
// run (`collectCierreDesktopPadContentRatio`, called once near the top of
// main() before the sweep, below). Deriving the budget this way is what
// lets it survive plan 01.5-09's desktop retune already on record and any
// future one — both sides move together, unlike a hard-coded 0.90-1.02.
//
// Ratio computed the same way the diagnosis's own norms.mjs script did:
// (padTop + padBottom) / contentHeight, recovered from rects alone
// (`cierre.height - cierreInner.height`, over `cierreInner.height`) since
// the gap-evenness assertions above already guard the padding being read
// correctly from the box. Pre-fix this measured 1.67 against a 0.19-0.53
// page-wide norm and a 0.90-1.02 desktop-accepted range (E-05); this
// check's budget IS that accepted range, read live instead of copied.
const CIERRE_PROPORTION_BUDGET_MULTIPLIER = 1.15 // same headroom checkCierreRunRatioBudget uses one band over

let cierreDesktopPadContentRatio = null

function cierrePadContentRatio(measured) {
  const { cierre, cierreInner } = measured
  if (!cierre || !cierreInner || cierreInner.height <= 0) return null
  return (cierre.height - cierreInner.height) / cierreInner.height
}

// Runs ONE extra, dedicated measurement (not part of the width x theme x
// height sweep's own case accounting) at a representative desktop width
// before the main loop starts. Geometry here is invariant to theme (colour
// does not move a box) and to viewport height (no vh floor since 01.5-07),
// which is WHY one measurement suffices as this run's live desktop
// reference rather than needing its own sweep — confirmed by this file's
// existing dark-theme control (E-09) and the mobile-invariance check above,
// both of which already rely on that same invariance.
async function collectCierreDesktopPadContentRatio({ client, baseUrl }) {
  const measured = await runCase({ client, baseUrl, viewport: 1280, theme: "light", height: 900 })
  const ratio = cierrePadContentRatio(measured)
  if (ratio == null) {
    throw new Error(
      "collectCierreDesktopPadContentRatio: could not derive #cierre's desktop pad/content ratio " +
        "at 1280px — checkCierreProportionBudget has no live budget to compare mobile widths " +
        "against for the rest of this run",
    )
  }
  return ratio
}

function checkCierreProportionBudget(measured, ctx) {
  if (ctx.viewport >= 640) return []

  if (cierreDesktopPadContentRatio == null) {
    return [
      `#cierre proportion budget: no live desktop pad/content ratio was captured for this run ` +
        `(collectCierreDesktopPadContentRatio must run before the sweep) — cannot judge ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] against it`,
    ]
  }

  const ratio = cierrePadContentRatio(measured)
  if (ratio == null) {
    return [
      `#cierre proportion budget: could not measure #cierre and/or its .pk-band-inner content ` +
        `group at [${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  const budget = cierreDesktopPadContentRatio * CIERRE_PROPORTION_BUDGET_MULTIPLIER
  if (ratio > budget) {
    return [
      `#cierre proportion budget: mobile pad/content=${ratio.toFixed(3)}, this run's OWN live ` +
        `desktop pad/content=${cierreDesktopPadContentRatio.toFixed(3)}, budget=` +
        `${budget.toFixed(3)} (desktop x ${CIERRE_PROPORTION_BUDGET_MULTIPLIER}) at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — the closing band's mobile padding-` +
        `to-content ratio is disproportionate against THIS SAME band's own desktop state, not a ` +
        `fixed literal. G-01.5-10's diagnosis measured the pre-fix mobile ratio at 1.67 against a ` +
        `0.19-0.53 page-wide norm and a 0.90-1.02 desktop-accepted range; this run's own live ` +
        `desktop ratio (${cierreDesktopPadContentRatio.toFixed(3)}) IS that accepted range.`,
    ]
  }

  return []
}

// Plan 01.5-13, second new check — HIERARCHY, the "needs better balance"
// clause. The band's three rendered lines measured 163.7 / 85.9 / 204.4px
// pre-fix (E-02/E-03): the widest object in the band was its smallest,
// greyest, most subordinate one — the 10px uppercase signature 24.8%
// WIDER than the 24px heading it sits under, the exact inversion the user
// called unbalanced. Compares `cierreHeading.width` (runCase, above — a
// shrink-to-fit box in this flex column, the same reasoning E-02 relied on
// for the pre-fix 163.73px measurement) against `signatureType.width`
// (already captured by plan 01.5-11) at mobile widths only; the desktop
// signature and desktop heading are a different, larger-margin pair this
// check does not need to re-litigate.
function checkCierreHierarchy(measured, ctx) {
  if (ctx.viewport >= 640) return []

  const { cierreHeading, signatureType } = measured
  if (!cierreHeading || cierreHeading.width == null) {
    return [
      `#cierre hierarchy: could not measure #cierre h2's rendered width at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }
  if (!signatureType || signatureType.width == null) {
    return [
      `#cierre hierarchy: could not measure #cierre .pk-about-closing-meta's rendered width at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  const headingWidth = cierreHeading.width
  const signatureWidth = signatureType.width

  if (signatureWidth > headingWidth) {
    const ratio = signatureWidth / headingWidth
    return [
      `#cierre hierarchy: signature width=${signatureWidth.toFixed(2)}px is WIDER than heading ` +
        `width=${headingWidth.toFixed(2)}px (ratio ${ratio.toFixed(3)}) at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — the widest object in the band is ` +
        `its smallest, greyest, most subordinate line. G-01.5-10's pre-fix diagnosis measured this ` +
        `inversion at 163.7px (heading) vs 204.4px (signature), a 24.8% overshoot; the signature ` +
        `must never out-measure the heading it is subordinate to.`,
    ]
  }

  return []
}

// Plan 01.5-13, third new check — NO-WRAP, landmine 4 of both the debug
// session's Resolution block and this plan's own read_first: a 32px
// heading measures 218.3px in #cierre's ~347px content box at 375px (63%
// fill), but the box shrinks to ~292px at the narrowest swept width — a
// two-line heading there would introduce a NEW defect while fixing this
// one. Scoped to exactly the sweep's narrowest width (not "< 640px") so
// this check runs exactly once per (theme, height) rather than redundantly
// at every mobile width already covered by the wider-margin cases.
//
// Line count is measured via a Range over the heading's own text node
// (this file's established definition of "ink," the same idiom
// sumateCta.inkHeight already uses) rather than trusted from a bare box
// width — the column's own width cap means a wrapped two-line heading and
// a one-line heading can report similar-looking boxes; only the ink itself
// tells them apart.
const CIERRE_NARROWEST_WIDTH = Math.min(...VIEWPORTS)

function checkCierreNoWrap(measured, ctx) {
  if (ctx.viewport !== CIERRE_NARROWEST_WIDTH) return []

  const { cierreHeading } = measured
  if (!cierreHeading || cierreHeading.lineCount == null) {
    return [
      `#cierre no-wrap: could not measure #cierre h2's rendered line count at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  if (cierreHeading.lineCount !== 1) {
    return [
      `#cierre no-wrap: heading rendered on ${cierreHeading.lineCount} lines (width=` +
        `${cierreHeading.width.toFixed(2)}px) at [${ctx.viewport}px x ${ctx.height}px, ` +
        `${ctx.theme}] — expected exactly 1 line box at this phase's narrowest supported width. ` +
        `A mobile heading size step must never wrap "Nos vemos el sábado" onto two lines.`,
    ]
  }

  return []
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

// True only for a fully transparent computed background — the catalog
// index's and the game detail page's trailing wrapper (a plain div, not a
// .pk-band) is the only surface this app renders with an alpha channel at
// all, so `alpha === 0` is an unambiguous test with no other computed
// background this app declares to confuse it with.
function isTransparentBackground(bg) {
  if (!bg) return true
  const match = bg.match(/^rgba\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*([\d.]+)\s*\)$/)
  return match != null && parseFloat(match[1]) === 0
}

// Plan 01.5-09 (G-01.5-5 gap closure) shipped this check surface-
// conditional: "when the last band's computed background equals the
// footer's, require CONTACT; otherwise fall back to the flat pixel
// budget." Before that, the ORIGINAL flat budget alone had already passed
// on the reported G-01.5-5 defect — 24.00px satisfied `<= 26` — because the
// budget was a correctly-implemented statement of a target that
// contradicted the UAT truth sitting next to it: the real property was
// never "small enough gap" but "no visible seam between two surfaces the
// eye reads as one". That lesson still holds one level down and is why
// case 1 below exists at all.
//
// Read literally, though, the 01.5-09 surface-conditional check ASSERTED
// the next defect it was standing in front of: when the last band and the
// footer paint the identical token, it REQUIRED them to be flush — and on
// the shipped tree that was exactly true (surfacesMatch, distance 0.00), so
// it returned clean instead of failing
// (.planning/debug/G-01.5-8-cierre-tagline-footer-grouping.md, E-09). Plan
// 01.5-11 rewrites it into the three-way rule the design actually needs,
// in the SAME change as the fill fix that flips `surfacesMatch` to false —
// a bare inversion of the old branch, done separately, would silently drop
// this boundary into the flat budget below and quietly delete the contact
// guarantee G-01.5-5 was closed on, letting a 24px gap reappear here with a
// green suite:
//   1. the last band and the footer paint the IDENTICAL computed
//      background -> FAIL. No gap size is correct for two same-token
//      full-bleed bands: a non-zero gap paints a visible third-colour
//      stripe (G-01.5-5, closed) and zero merges the two surfaces into one
//      field (G-01.5-8, this plan).
//   2. the two backgrounds DIFFER and both are opaque -> require CONTACT
//      within the same tolerance every other band-to-band boundary on this
//      page already uses (checkAdjacentBandContact's own
//      CONTACT_TOLERANCE_PX) — any gap between two opaque surfaces paints
//      a visible third colour between them, the exact thing G-01.5-5 was
//      closed on, and that guarantee must survive the fill change rather
//      than lapsing into case 3's looser budget.
//   3. the last band paints NOTHING at all (a fully transparent
//      background — the catalog index's and the game detail page's
//      trailing wrapper) -> the original flat pixel budget, unchanged;
//      that surface relationship is a different page and a different
//      defect, and this check should still mean something there.
// Case 3 is evaluated BEFORE the equality/opacity comparison in cases 1-2:
// a transparent last band never has a fill to compare, so testing equality
// first would wrongly route it into case 2's stricter contact requirement.
// No gate anywhere else in this repo compares two adjacent surfaces'
// backgrounds for DIFFERENCE, and the equality this check now fails on
// holds in dark theme with different literals — both cases 1 and 2 must
// run, and do run, in every theme the sweep covers, not just light.
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

  if (isTransparentBackground(lastBandBackground)) {
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

  const surfacesMatch = lastBandBackground != null && lastBandBackground === footerBackground

  if (surfacesMatch) {
    return [
      `bottom boundary budget: ${bandLabel(lastBand)} and <footer> paint the identical ` +
        `computed background (${lastBandBackground}) at [${ctx.viewport}px x ${ctx.height}px, ` +
        `${ctx.theme}] — no gap size is correct for two same-token full-bleed bands (a non-zero ` +
        `gap paints a visible third-colour stripe, the G-01.5-5 defect; zero merges the two ` +
        `surfaces into one field, the G-01.5-8 defect). Break the token equality, not the gap.`,
    ]
  }

  if (Math.abs(distance) > CONTACT_TOLERANCE_PX) {
    return [
      `bottom boundary budget: ${bandLabel(lastBand)} (${lastBandBackground}) and <footer> ` +
        `(${footerBackground}) paint DIFFERENT opaque backgrounds — expected CONTACT (within ` +
        `${CONTACT_TOLERANCE_PX}px, the same rule every other boundary on this page follows), ` +
        `measured a ${distance.toFixed(2)}px gap at [${ctx.viewport}px x ${ctx.height}px, ` +
        `${ctx.theme}] — any gap between two opaque surfaces paints a visible third colour ` +
        `between them, the guarantee G-01.5-5 was closed on.`,
    ]
  }

  return []
}

// Plan 01.5-11 (G-01.5-8 gap closure, second lever). No gate anywhere in
// this repo observes TYPE-REGISTER SIMILARITY between two elements — every
// existing check here is geometry (rects, gaps, distances) or a single
// element's own surface. `.pk-about-eyebrow` (the signature's class) and
// `.pk-footer-meta` sit 475 lines apart in app.css and independently
// declare the same font-size/colour pair because they express the same
// design-system role, so nothing structural stops them re-converging — a
// future edit to either rule could silently restore the exact collision
// this plan closes, with every other check in this file still green (none
// of them look at font-size or colour of these two specific elements
// together). This check exists to make that re-convergence a failure.
//
// Fails when BOTH font-size AND colour match between the signature and
// .pk-footer-meta — the conjunction is the collision the diagnosis
// measured (E-05: five attributes identical at once), not either property
// alone; line-height/font-family/font-weight are shared type-scale
// defaults neither this fix nor a plausible future edit is likely to
// diverge on, so testing the two properties this plan's own rule can move
// is the meaningful test. Must hold in BOTH themes: the collision holds in
// dark theme with different literals, exactly like the surface equality
// above.
function checkSignatureFooterTypeCollision(measured, ctx) {
  const { signatureType, footerMetaType } = measured

  if (!signatureType) {
    return [
      `signature/footer-meta type collision: could not measure #cierre .pk-about-closing-meta at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }
  if (!footerMetaType) {
    return [
      `signature/footer-meta type collision: could not measure .pk-footer-meta at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  const sameFontSize = signatureType.fontSize === footerMetaType.fontSize
  const sameColor = signatureType.color === footerMetaType.color

  if (sameFontSize && sameColor) {
    return [
      `signature/footer-meta type collision: the Cierre closing signature and .pk-footer-meta ` +
        `both compute font-size=${signatureType.fontSize} and color=${signatureType.color} at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}] — the exact collision that made the ` +
        `signature read as the footer's own meta text instead of the closing statement's last ` +
        `line (G-01.5-8).`,
    ]
  }

  return []
}

// Plan 01.5-10 (G-01.5-4 gap closure). This repo's first assertion that
// observes the Sumate button's own rendered box rather than the presence of
// a class name — no ExUnit test can (rendered geometry is invisible to a
// string match on class attributes) and check-theme-drift.sh is colour-
// scoped by design, so this probe is the only place these three properties
// can be verified. All three are DERIVED so they stay meaningful if the
// type scale or button size is ever deliberately retuned: a touch floor on
// measured height, a ratio (not an absolute px value) for padding, and a
// radius-vs-height comparison (not a literal radius value) for "is this a
// pill". Thresholds and the historical progression they replace:
//   touch floor      44px  (app-wide floor, unrelated to this button specifically)
//   padding ratio    1.03:1 original defect -> 1.74:1 (plan 01.5-05) -> 2.15:1 design source (this plan's target)
//   corner radius    4px original/01.5-05 (a KIND difference from a pill) -> >=half the rendered height (this plan's target)
const SUMATE_TOUCH_FLOOR_PX = 44
const SUMATE_DESIGN_SOURCE_PADDING_RATIO = 2.15
// Absorbs ink-height Range-measurement/font-rendering variance across
// widths and themes; far below the 0.41 (1.74 -> 2.15) and 1.12 (1.03 ->
// 2.15) deltas this check exists to catch, so it cannot mask either
// historical defect while still tolerating sub-pixel glyph metrics.
const SUMATE_PADDING_RATIO_TOLERANCE = 0.15
const SUMATE_MEASUREMENT_TOLERANCE_PX = 0.5

function checkSumateButtonGeometry(measured, ctx) {
  // D-11 (app.css @media max-width: 480px) hides #cierre .pk-about-cierre-cta
  // at this width — the sticky bar's own button takes over instead, and its
  // button is width-stretched (a padding-ratio assertion would be
  // meaningless on it); its height is covered by Task 3's clearance oracle.
  if (ctx.viewport <= 480) return []

  const { sumateCta } = measured
  if (!sumateCta) {
    return [
      `sumate button geometry: could not measure #cierre .pk-about-cierre-cta a at ` +
        `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`,
    ]
  }

  const failures = []
  const { rect, paddingInlineStart, borderTopLeftRadius, inkHeight } = sumateCta
  const label = `[${ctx.viewport}px x ${ctx.height}px, ${ctx.theme}]`

  if (rect.height < SUMATE_TOUCH_FLOOR_PX - SUMATE_MEASUREMENT_TOLERANCE_PX) {
    failures.push(
      `sumate button geometry: rendered height=${rect.height.toFixed(2)}px at ${label} — ` +
        `expected at or above the app's ${SUMATE_TOUCH_FLOOR_PX}px touch floor`,
    )
  }

  if (inkHeight == null) {
    failures.push(
      `sumate button geometry: could not measure the button's label ink height at ${label}`,
    )
  } else {
    const verticalInset = (rect.height - inkHeight) / 2
    if (verticalInset <= 0) {
      failures.push(
        `sumate button geometry: derived vertical inset=${verticalInset.toFixed(2)}px at ${label} ` +
          `— the label's ink (${inkHeight.toFixed(2)}px) does not fit inside the button's own ` +
          `rendered height (${rect.height.toFixed(2)}px)`,
      )
    } else {
      const ratio = paddingInlineStart / verticalInset
      if (ratio < SUMATE_DESIGN_SOURCE_PADDING_RATIO - SUMATE_PADDING_RATIO_TOLERANCE) {
        failures.push(
          `sumate button geometry: padding ratio=${ratio.toFixed(2)}:1 (inline=` +
            `${paddingInlineStart.toFixed(2)}px, derived vertical inset=${verticalInset.toFixed(2)}px) ` +
            `at ${label} — expected at or above the design source's ` +
            `${SUMATE_DESIGN_SOURCE_PADDING_RATIO}:1 (tolerance ${SUMATE_PADDING_RATIO_TOLERANCE}). ` +
            `This is the exact channel G-01.5-4 diagnosed as defective (1.03:1 original, 1.74:1 ` +
            `after plan 01.5-05, 2.15:1 at sketch 051).`,
        )
      }
    }
  }

  const radiusFloor = rect.height / 2
  if (borderTopLeftRadius < radiusFloor - SUMATE_MEASUREMENT_TOLERANCE_PX) {
    failures.push(
      `sumate button geometry: border-top-left-radius=${borderTopLeftRadius.toFixed(2)}px at ` +
        `${label} — expected at or above half the rendered height (${radiusFloor.toFixed(2)}px), ` +
        `the shape-independent definition of a pill regardless of which literal the CSS uses`,
    )
  }

  return failures
}

// Named list of check functions the sweep loop calls. Plans 01.5-07,
// 01.5-08 and 01.5-10 each add one more entry here for their own oracle.
const CHECKS = [
  checkAdjacentBandContact,
  checkCierreGapEvenness,
  checkCierreRunRatioBudget,
  checkCierreBottomBreathingRoom,
  checkCierreMobileInvariance,
  checkCierreProportionBudget,
  checkCierreHierarchy,
  checkCierreNoWrap,
  checkBottomBoundaryBudget,
  checkSignatureFooterTypeCollision,
  checkSumateButtonGeometry,
]

// ---------------------------------------------------------------------------
// Plan 01.5-08/01.5-10/01.5-14: fixed-bar / footer clearance oracle
// ---------------------------------------------------------------------------
// The only oracle that can confirm Task 2's actual claim. A source-level
// test can confirm the body:has(.pk-about-cta-bar) clearance rule EXISTS;
// it cannot confirm the reserved amount actually lands where the fixed bar
// is once the page is scrolled to its real bottom. Runs its own small loop
// (below, in main()) at the one width where the bar is visible, since it
// needs an actual scroll — the shared per-case sweep above is deliberately
// unscrolled (see the footer-rect comment in runCase).
//
// Plan 01.5-10 (G-01.5-7 gap closure): the ORIGINAL check here asserted only
// non-intersection (footer.bottom <= bar.top + tolerance), which the shipped
// defect satisfied — a 3px strip of document background between the two was
// "non-overlapping" and passed. Rewritten to assert a TIGHT FIT: the
// footer's bottom edge and the bar's top edge must coincide within
// CONTACT_TOLERANCE_PX, reporting the two failure directions distinctly
// (SLACK — a gap is visible, the defect this task closes; OVERLAP — the bar
// covers real footer content, the opposite failure mode plan 01.5-08
// originally guarded against). Both the bar's real rendered height and the
// reserved clearance are captured in the same pass so a future reader can
// see which one moved without re-running the probe.
//
// Plan 01.5-14 (G-01.5-11 gap closure, sketch 052 winner B, SUPERSEDED):
// briefly rewrote this oracle around a content-sized pill floating
// `bottom: 20px` above the viewport edge, measuring `.pk-about-cta-bar a`
// (the anchor) rather than the wrapper, on the premise that a floating
// pill's whole design was a visible gap below it. Winner B was rejected at
// round-3 UAT for covering the footer's "Powered by BGG" line — the exact
// defect this oracle's BGG check (below) now exists to catch by name.
//
// Sketch 053 winner D (quick task 260910-av6, G-01.5-12): the wrapper
// (`.pk-about-cta-bar`) is the surface again — its own rect is what can
// cover content, so this is what the oracle measures once more. The reveal
// is now asynchronous in two stages (the `.AboutHeaderMorph` rAF frame
// flips `is-docked`, then the CSS transform transition runs for
// `--duration-slow`), so `runBottomClearanceCase` below adds a settle wait
// after the instant scroll — the same class of hazard as the `behavior:
// "instant"` note above (that one fixed a stale SCROLL position; this one
// fixes a stale TRANSITION state). `checkFixedBarFooterClearance` now
// asserts three independent things, all derived from live measurements and
// never from literals:
//   1. VISIBLE AT THE BOTTOM — the bar actually revealed (`is-docked`) and
//      sits flush with the viewport's bottom edge, proving it neither
//      auto-hid nor is still mid-transition.
//   2. BGG NEVER COVERED — `.pk-bgg-note`'s bottom edge is at or above the
//      bar's top edge. This is winner B's exact rejection cause, named in
//      the failure message so a future regression reads as a recurrence,
//      not a fresh mystery.
//   3. NO FOOTER OVERLAP / BOUNDED SLACK — the gap between the footer's
//      bottom edge and the bar's top edge is non-negative (no overlap) and
//      does not exceed the deliberate breathing step, itself derived as
//      `reservedClearance - bar.height` (never restated as a literal
//      step size).
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
      (async () => {
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

        // Settle wait (sketch 053 winner D): the reveal is now asynchronous
        // in two stages — the .AboutHeaderMorph rAF frame flips is-docked
        // on the NEXT frame after the scroll event fires, then the CSS
        // transform/opacity transitions run for up to --duration-slow
        // (280ms). A synchronous read immediately after scrollTo would
        // capture a mid-flight or pre-flip rect — the same class of hazard
        // as the 'behavior: instant' override above, just for a
        // TRANSITION's settled state instead of a SCROLL position's. A
        // double requestAnimationFrame guarantees at least one full paint
        // cycle has run (so the scroll listener's rAF-scheduled frame has
        // fired), then a timeout comfortably past 280ms lets the CSS
        // transition itself finish.
        await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
        await new Promise((resolve) => setTimeout(resolve, 450));

        const rectOf = (el) => {
          if (!el) return null;
          const r = el.getBoundingClientRect();
          return { x: r.x, y: r.y, width: r.width, height: r.height };
        };

        const aboutHero = document.getElementById("about-hero");

        return JSON.stringify({
          // Sketch 053 winner D: the WRAPPER is the surface again, so its
          // own top edge is what can cover content — not the anchor inside
          // it (winner B's premise, now superseded).
          bar: rectOf(document.querySelector(".pk-about-cta-bar")),
          bggNote: rectOf(document.querySelector(".pk-bgg-note")),
          footer: rectOf(document.querySelector("footer.pk-footer")),
          // The reserved document-end clearance itself
          // (body:has(.pk-about-cta-bar)'s computed padding-bottom),
          // captured alongside the rects so the SUMMARY can report the
          // bar's real footprint against what was actually reserved for
          // it, without a second probe run.
          reservedClearance: parseFloat(getComputedStyle(document.body).paddingBottom),
          // Whether the reveal trigger actually fired at the real page
          // bottom — the D-03 boolean .AboutHeaderMorph toggles on
          // #about-hero, reused verbatim as this bar's own entry trigger.
          docked: aboutHero ? aboutHero.classList.contains("is-docked") : false,
          // The bar is position:fixed, so its viewport-relative rect is
          // scroll-invariant, but the flush-to-bottom check below still
          // needs the viewport's own height — captured live here rather
          // than assumed as the 900px the sweep happens to set, so this
          // stays correct if that ever changes.
          viewportHeight: window.innerHeight,
        });
      })()
    `,
    awaitPromise: true,
    returnByValue: true,
  })

  return JSON.parse(measureResult.result.value)
}

function checkFixedBarFooterClearance(measured, ctx) {
  const { bar, bggNote, footer, reservedClearance, viewportHeight, docked } = measured
  const label = `[${ctx.viewport}px, ${ctx.theme}]`
  const failures = []

  if (!bar || bar.width === 0 || bar.height === 0) {
    return [
      `fixed-bar footer clearance: could not measure a non-zero .pk-about-cta-bar rect at ` +
        `${label} — expected it visible (docked) at the real page bottom at this width.`,
    ]
  }

  // 1. VISIBLE AT THE BOTTOM — the reveal trigger fired and the bar is
  // flush with the viewport's own bottom edge, proving it neither
  // auto-hid (there is no such mechanism) nor is still mid-transition
  // after the settle wait above.
  if (!docked) {
    failures.push(
      `fixed-bar footer clearance: #about-hero did not carry is-docked at the real page bottom ` +
        `at ${label} — the bar's ONE reveal trigger (D-03 reuse) never fired, so it never ` +
        `appeared at all.`,
    )
  }

  const barBottomGap = viewportHeight - (bar.y + bar.height)

  if (Math.abs(barBottomGap) > CONTACT_TOLERANCE_PX) {
    failures.push(
      `fixed-bar footer clearance: the bar's bottom edge is ${barBottomGap.toFixed(2)}px from ` +
        `the viewport's own bottom edge at ${label} (expected within ${CONTACT_TOLERANCE_PX}px) ` +
        `— sketch 053 winner D is a FLUSH bar (bottom: 0), so it should sit exactly at the ` +
        `viewport edge once revealed.`,
    )
  }

  // 2. BGG NEVER COVERED — the exact rejection cause of sketch 052 winner
  // B at round-3 UAT.
  if (!bggNote) {
    failures.push(`fixed-bar footer clearance: could not measure .pk-bgg-note at ${label}.`)
  } else if (bggNote.y + bggNote.height > bar.y + CONTACT_TOLERANCE_PX) {
    failures.push(
      `fixed-bar footer clearance: the "Powered by BGG" line (.pk-bgg-note, bottom edge ` +
        `${(bggNote.y + bggNote.height).toFixed(2)}) extends below the bar's top edge ` +
        `(${bar.y.toFixed(2)}) at ${label} — this is the EXACT rejection cause of sketch 052 ` +
        `winner B at round-3 UAT ("covers the footer's Powered by BGG line"), which sketch 053 ` +
        `winner D and this check both exist to prevent from recurring.`,
    )
  }

  // 3. NO FOOTER OVERLAP / BOUNDED SLACK — the gap between the footer's
  // bottom edge and the bar's top edge must be non-negative (no overlap)
  // and no larger than the deliberate breathing step, itself derived
  // live rather than restated as a literal.
  if (!footer) {
    failures.push(`fixed-bar footer clearance: could not measure footer.pk-footer at ${label}.`)
  } else {
    const distance = bar.y - (footer.y + footer.height)
    const step = reservedClearance - bar.height
    const context =
      `bar height=${bar.height.toFixed(2)}px, reserved clearance=` +
      `${Number.isFinite(reservedClearance) ? reservedClearance.toFixed(2) : "?"}px, breathing ` +
      `step=${step.toFixed(2)}px, footer bottom=${(footer.y + footer.height).toFixed(2)}, bar ` +
      `top=${bar.y.toFixed(2)}`

    if (distance < -CONTACT_TOLERANCE_PX) {
      failures.push(
        `fixed-bar footer clearance: OVERLAP of ${(-distance).toFixed(2)}px — the bar covers ` +
          `real footer content at ${label} (${context}) — the document-end clearance is not ` +
          `reserving enough. This is the serious direction: it hides content a member needs to ` +
          `read or tap.`,
      )
    } else if (distance > step + CONTACT_TOLERANCE_PX) {
      failures.push(
        `fixed-bar footer clearance: SLACK of ${distance.toFixed(2)}px between the footer's ` +
          `bottom edge and the bar's top edge at ${label} (${context}) — expected at most the ` +
          `deliberate breathing step (${step.toFixed(2)}px, derived as reserved clearance minus ` +
          `bar height), not more.`,
      )
    }
  }

  return failures
}

// ---------------------------------------------------------------------------
// Quick task 260910-av6, Task 3: dock-vs-hero-CTA scroll-window diagnostic
// ---------------------------------------------------------------------------
// LOG-ONLY, never a failure. Quantifies the one place the locked mechanism
// (reuse the docked boolean as the bar's entry trigger) and the stated
// intent ("hidden until the hero's own Sumate scrolls out of view") can
// diverge: if the bar's own dock trigger fires at a SMALLER scroll delta
// than the delta at which the hero's own Sumate CTA leaves the viewport,
// there is a scroll window where BOTH the hero CTA and the sticky bar are
// on screen at once — two "Sumate" asks visible simultaneously. This task
// deliberately does NOT change the trigger; it only measures and reports
// the window, so a developer can judge whether it reads as a duplicate ask.
async function runDockVsHeroCtaDiagnostic({ client, baseUrl, viewport }) {
  await client.send("Emulation.setDeviceMetricsOverride", {
    width: viewport,
    height: 900,
    deviceScaleFactor: 1,
    mobile: false,
  })

  const navigated = client.once("Page.loadEventFired")
  await client.send("Page.navigate", { url: `${baseUrl}/quienes-somos` })
  await navigated

  const result = await client.send("Runtime.evaluate", {
    expression: `
      JSON.stringify((() => {
        const anchor = document.querySelector("#about-hero [data-morph-anchor]");
        const header = document.getElementById("app-header");
        const sumate = document.querySelector("#about-hero a.pk-sumate-btn");
        if (!anchor || !header || !sumate) {
          return { error: "missing #about-hero [data-morph-anchor], #app-header or #about-hero a.pk-sumate-btn" };
        }

        // Mirrors .AboutHeaderMorph's own this.dockRect() exactly: walk
        // BOTH theme brand marks and take the one that actually has
        // layout size (the other is display:none for the inactive theme).
        const marks = header.querySelectorAll(".pk-brand-mark");
        let dockRect = null;
        for (const mark of marks) {
          const rect = mark.getBoundingClientRect();
          if (rect.width > 0 && rect.height > 0) {
            dockRect = rect;
            break;
          }
        }
        if (!dockRect) return { error: "no visible .pk-brand-mark in #app-header" };

        const anchorRect = anchor.getBoundingClientRect();
        const sumateRect = sumate.getBoundingClientRect();

        return {
          // The hook docks when natural.top <= dock.top (this.frame()).
          // At scrollY=0, scrolling down by (anchorRect.top - dockRect.top)
          // brings anchor.top down to dock.top — the same arithmetic the
          // hook itself performs every frame, just solved for scrollY
          // once instead of re-evaluated continuously.
          dockScrollDelta: anchorRect.top - dockRect.top,
          // sumateRect.bottom (at scrollY=0) IS the scroll delta at which
          // the hero Sumate's bottom edge reaches the viewport's top edge
          // (y=0) — the point it fully leaves view scrolling down.
          heroCtaScrollDelta: sumateRect.bottom,
        };
      })())
    `,
    returnByValue: true,
  })

  return JSON.parse(result.result.value)
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

    // Plan 01.5-13: this run's own live desktop pad/content reference,
    // captured ONCE before the sweep starts — checkCierreProportionBudget
    // (mobile-only) reads this module-scope value via closure rather than
    // needing the sweep loop reordered so a desktop case runs before a
    // mobile one (VIEWPORTS stays ascending, matching this file's own
    // evidence-ordering convention). Counted in casesRun/expectedCases
    // below the same way the fixed-bar loop's own extra cases already are.
    cierreDesktopPadContentRatio = await collectCierreDesktopPadContentRatio({ client, baseUrl })
    casesRun++
    log(
      `[1280px x 900px, light] #cierre desktop pad/content reference: ` +
        `${cierreDesktopPadContentRatio.toFixed(3)} (checkCierreProportionBudget's live budget input)`,
    )

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

    // Quick task 260910-av6, Task 3: dock-vs-hero-CTA scroll-window
    // diagnostic — log-only, run once (page geometry, not theme-dependent),
    // ahead of the bottom-clearance loop below.
    try {
      const diag = await runDockVsHeroCtaDiagnostic({
        client,
        baseUrl,
        viewport: CTA_BAR_VISIBLE_WIDTH,
      })

      if (diag.error) {
        log(`[dock-vs-hero-CTA diagnostic @ ${CTA_BAR_VISIBLE_WIDTH}px] SKIPPED: ${diag.error}`)
      } else {
        const diff = diag.heroCtaScrollDelta - diag.dockScrollDelta
        log(
          `[dock-vs-hero-CTA diagnostic @ ${CTA_BAR_VISIBLE_WIDTH}px] bar's dock trigger fires at ` +
            `scrollY=${diag.dockScrollDelta.toFixed(2)}px, hero Sumate leaves the viewport at ` +
            `scrollY=${diag.heroCtaScrollDelta.toFixed(2)}px, difference=${diff.toFixed(2)}px ` +
            `(${diff > 0 ? "POSITIVE — a scroll window exists where the hero CTA and the bar are both on screen" : "non-positive — no such window"})`,
        )
      }
    } catch (err) {
      log(`[dock-vs-hero-CTA diagnostic @ ${CTA_BAR_VISIBLE_WIDTH}px] SKIPPED (error): ${err.message}`)
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
            `${label} bar top=${measured.bar.y.toFixed(2)} bar height=` +
              `${measured.bar.height.toFixed(2)} docked=${measured.docked} reserved clearance=` +
              `${Number.isFinite(measured.reservedClearance) ? measured.reservedClearance.toFixed(2) : "?"} ` +
              `footer bottom=${measured.footer ? (measured.footer.y + measured.footer.height).toFixed(2) : "?"} ` +
              `bgg bottom=${measured.bggNote ? (measured.bggNote.y + measured.bggNote.height).toFixed(2) : "?"}`,
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

  // +1: the single collectCierreDesktopPadContentRatio reference case above
  // (plan 01.5-13), not part of the viewport x theme x height sweep's own
  // matrix but still a real case that must not silently fail to run.
  const expectedCases = VIEWPORTS.length * THEMES.length * CIERRE_HEIGHTS.length + THEMES.length + 1
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
