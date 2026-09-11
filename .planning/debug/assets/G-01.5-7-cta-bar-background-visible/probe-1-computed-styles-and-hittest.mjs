#!/usr/bin/env node
// Focused CDP probe for G-01.5-7: is .pk-about-cta-bar's background fully
// occluding content that scrolls under it at <=480px?
import { spawn } from "node:child_process"
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

const BASE = process.env.PROBE_BASE_URL || "http://localhost:4000"
const OUT = process.env.OUT_DIR || "/tmp/probe-out"

async function startChrome() {
  const userDataDir = await mkdtemp(join(tmpdir(), "g0157-chrome-"))
  let proc = null
  let lastErr = null
  for (const bin of ["google-chrome-stable", "chromium", "chromium-browser", "google-chrome"]) {
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
      await new Promise((res, rej) => {
        proc.once("spawn", res)
        proc.once("error", rej)
      })
      break
    } catch (e) {
      lastErr = e
      proc = null
    }
  }
  if (!proc) throw new Error("no chrome: " + lastErr?.message)
  let buf = ""
  const port = await new Promise((res, rej) => {
    const t = setTimeout(() => rej(new Error("no devtools endpoint:\n" + buf)), 15000)
    proc.stderr.on("data", (d) => {
      buf += d.toString()
      const m = buf.match(/DevTools listening on ws:\/\/[^:]+:(\d+)\//)
      if (m) {
        clearTimeout(t)
        res(Number(m[1]))
      }
    })
  })
  return { proc, userDataDir, port }
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
  once(method) {
    return new Promise((resolve) => {
      const h = (ev) => {
        const msg = JSON.parse(ev.data)
        if (msg.method === method) {
          this.ws.removeEventListener("message", h)
          resolve(msg.params)
        }
      }
      this.ws.addEventListener("message", h)
    })
  }
}

async function connectCDP(port) {
  const res = await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: "PUT" })
  const target = await res.json()
  const ws = new WebSocket(target.webSocketDebuggerUrl)
  await new Promise((r, j) => {
    ws.addEventListener("open", r, { once: true })
    ws.addEventListener("error", j, { once: true })
  })
  const client = new CDPClient(ws)
  await client.send("Page.enable")
  await client.send("Runtime.enable")
  return client
}

const EXPR = `
(() => {
  const out = {};
  const bar = document.querySelector('.pk-about-cta-bar');
  if (!bar) return { error: 'no bar' };

  const props = ["display","position","left","right","bottom","top","width","height",
    "zIndex","opacity","backgroundColor","backgroundImage","backdropFilter",
    "webkitBackdropFilter","filter","mixBlendMode","isolation","transform","willChange",
    "contain","perspective","borderTopWidth","borderTopColor","borderTopStyle",
    "paddingTop","paddingBottom","paddingLeft","paddingRight","marginBlockEnd",
    "boxShadow","overflow","clipPath","maskImage"];

  const pick = (el) => {
    const cs = getComputedStyle(el);
    const o = {};
    for (const p of props) o[p] = cs[p];
    return o;
  };

  out.bar = pick(bar);
  out.barRect = bar.getBoundingClientRect().toJSON();
  out.barClass = bar.className;
  out.barHTML = bar.outerHTML.slice(0, 600);

  // button inside
  const btn = bar.firstElementChild;
  if (btn) {
    out.btn = pick(btn);
    out.btnRect = btn.getBoundingClientRect().toJSON();
    out.btnClass = btn.className;
  }

  // ancestor chain: anything that would make position:fixed resolve
  // against an ancestor instead of the viewport, or that dilutes paint.
  out.ancestors = [];
  let n = bar.parentElement;
  while (n) {
    const cs = getComputedStyle(n);
    out.ancestors.push({
      tag: n.tagName,
      id: n.id,
      cls: (n.className && n.className.toString ? n.className.toString() : "").slice(0,140),
      transform: cs.transform,
      filter: cs.filter,
      backdropFilter: cs.backdropFilter,
      willChange: cs.willChange,
      contain: cs.contain,
      perspective: cs.perspective,
      opacity: cs.opacity,
      position: cs.position,
      zIndex: cs.zIndex,
      isolation: cs.isolation,
      containerType: cs.containerType,
      backgroundColor: cs.backgroundColor,
      overflow: cs.overflow,
      rect: n.getBoundingClientRect().toJSON()
    });
    n = n.parentElement;
  }

  out.viewport = { w: innerWidth, h: innerHeight, scrollY: scrollY,
    docH: document.documentElement.scrollHeight,
    bodyPadBottom: getComputedStyle(document.body).paddingBottom,
    bodyBg: getComputedStyle(document.body).backgroundColor,
    htmlBg: getComputedStyle(document.documentElement).backgroundColor };

  // Tokens
  const rootCS = getComputedStyle(document.documentElement);
  out.tokens = {};
  for (const t of ["--color-base-100","--color-base-200","--color-base-300","--pk-gutter"]) {
    out.tokens[t] = rootCS.getPropertyValue(t).trim();
  }

  // Hit-test a grid of points inside the bar's box: what actually paints on top?
  const r = out.barRect;
  out.hits = [];
  const ys = [r.top + 1, r.top + 4, r.top + r.height/2, r.bottom - 4, r.bottom - 1];
  const xs = [2, innerWidth/2, innerWidth - 3];
  for (const y of ys) for (const x of xs) {
    const stack = document.elementsFromPoint(x, y).slice(0,4).map(e =>
      e.tagName + (e.id ? '#'+e.id : '') + (e.className && e.className.toString ? '.'+e.className.toString().trim().split(/\\s+/).slice(0,3).join('.') : ''));
    out.hits.push({ x: Math.round(x), y: Math.round(y), stack });
  }

  // Footer + last band rects for context
  const footer = document.querySelector('footer, .pk-footer');
  if (footer) out.footerRect = footer.getBoundingClientRect().toJSON();
  const cierre = document.querySelector('#cierre');
  if (cierre) out.cierreRect = cierre.getBoundingClientRect().toJSON();

  return out;
})()
`

async function main() {
  const chrome = await startChrome()
  const client = await connectCDP(chrome.port)
  const results = {}
  try {
    for (const theme of ["light", "dark"]) {
      for (const scrollMode of ["bottom", "mid"]) {
        const key = `${theme}-${scrollMode}`
        await client.send("Emulation.setDeviceMetricsOverride", {
          width: 375,
          height: 812,
          deviceScaleFactor: 1,
          mobile: false,
        })
        const nav = client.once("Page.loadEventFired")
        await client.send("Page.navigate", { url: `${BASE}/quienes-somos` })
        await nav
        await client.send("Runtime.evaluate", {
          expression: `document.documentElement.dataset.theme = ${JSON.stringify(theme)};`,
        })
        await new Promise((r) => setTimeout(r, 1200))
        await client.send("Runtime.evaluate", {
          expression:
            scrollMode === "bottom"
              ? `window.scrollTo(0, document.documentElement.scrollHeight)`
              : `window.scrollTo(0, Math.round(document.documentElement.scrollHeight * 0.72))`,
        })
        await new Promise((r) => setTimeout(r, 900))
        const res = await client.send("Runtime.evaluate", {
          expression: EXPR,
          returnByValue: true,
        })
        results[key] = res.result.value
        const shot = await client.send("Page.captureScreenshot", { format: "png" })
        await writeFile(join(OUT, `${key}.png`), Buffer.from(shot.data, "base64"))
      }
    }
    await writeFile(join(OUT, "measurements.json"), JSON.stringify(results, null, 2))
    console.log(JSON.stringify(results, null, 2))
  } finally {
    try {
      chrome.proc.kill()
    } catch {}
    await rm(chrome.userDataDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 })
  }
}

main().catch((e) => {
  console.error(e)
  process.exit(1)
})
