#!/usr/bin/env node
// G-01.5-7 probe 2: rendered-pixel evidence. fromSurface:false keeps Chrome's
// own sign-in bubble out of the capture.
import { spawn } from "node:child_process"
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

const BASE = process.env.PROBE_BASE_URL || "http://localhost:4000"
const OUT = process.env.OUT_DIR || "/tmp/probe-out"

async function startChrome() {
  const userDataDir = await mkdtemp(join(tmpdir(), "g0157b-chrome-"))
  const proc = spawn(
    "google-chrome-stable",
    [
      "--headless=new",
      "--disable-gpu",
      "--hide-scrollbars",
      "--no-first-run",
      "--no-default-browser-check",
      "--disable-search-engine-choice-screen",
      "--disable-sync",
      "--disable-features=SigninIntercept,ChromeSigninBubble,TrustSafetySentimentSurvey",
      `--user-data-dir=${userDataDir}`,
      "--remote-debugging-port=0",
    ],
    { stdio: ["ignore", "ignore", "pipe"] },
  )
  await new Promise((res, rej) => {
    proc.once("spawn", res)
    proc.once("error", rej)
  })
  let buf = ""
  const port = await new Promise((res, rej) => {
    const t = setTimeout(() => rej(new Error("no devtools:\n" + buf)), 15000)
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

const MEASURE = `
(() => {
  const bar = document.querySelector('.pk-about-cta-bar');
  const r = (el) => el ? el.getBoundingClientRect().toJSON() : null;
  const cs = (el, p) => el ? getComputedStyle(el)[p] : null;
  return {
    scrollY, innerH: innerHeight, docH: document.documentElement.scrollHeight,
    bar: r(bar),
    barBg: cs(bar, 'backgroundColor'),
    cierre: r(document.querySelector('#cierre')),
    cierreBg: cs(document.querySelector('#cierre'), 'backgroundColor'),
    footer: r(document.querySelector('footer, .pk-footer')),
    footerBg: cs(document.querySelector('footer, .pk-footer'), 'backgroundColor'),
    htmlBg: getComputedStyle(document.documentElement).backgroundColor,
    bodyPadBottom: getComputedStyle(document.body).paddingBottom,
    main: r(document.querySelector('main'))
  };
})()
`


const ARMS = {
  A_status_quo: "",
  B_fill_only: ".pk-about-cta-bar{background:var(--color-base-200)!important}",
  C_fill_plus_border: ".pk-about-cta-bar{background:var(--color-base-200)!important;border-top-color:var(--color-neutral)!important}",
  D_fill_border_clearance: ".pk-about-cta-bar{background:var(--color-base-200)!important;border-top-color:var(--color-neutral)!important} body:has(.pk-about-cta-bar){padding-bottom:69px!important}"
}
async function main() {
  const chrome = await startChrome()
  const client = await connectCDP(chrome.port)
  const out = {}
  try {
    for (const theme of ["light", "dark"]) {
      for (const [arm, css] of Object.entries(ARMS)) {
        const key = `${theme}-${arm}`
        await client.send("Emulation.setDeviceMetricsOverride", {
          width: 375, height: 812, deviceScaleFactor: 1, mobile: false,
        })
        const nav = client.once("Page.loadEventFired")
        await client.send("Page.navigate", { url: `${BASE}/quienes-somos` })
        await nav
        await client.send("Runtime.evaluate", {
          expression: `document.documentElement.dataset.theme = ${JSON.stringify(theme)};` +
            (css ? `var s=document.createElement('style');s.textContent=${JSON.stringify(css)};document.head.appendChild(s);` : ""),
        })
        await new Promise((r) => setTimeout(r, 1400))
        await client.send("Runtime.evaluate", { expression: `window.scrollTo(0, document.documentElement.scrollHeight)` })
        await new Promise((r) => setTimeout(r, 900))
        const m = await client.send("Runtime.evaluate", { expression: MEASURE, returnByValue: true })
        out[key] = m.result.value
        const shot = await client.send("Page.captureScreenshot", { format: "png" })
        await writeFile(join(OUT, `arm-${key}.png`), Buffer.from(shot.data, "base64"))
      }
    }
    await writeFile(join(OUT, "arms.json"), JSON.stringify(out, null, 2))
    console.log("done")
  } finally {
    try { chrome.proc.kill() } catch {}
    await rm(chrome.userDataDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 })
  }
}

main().catch((e) => { console.error(e); process.exit(1) })
