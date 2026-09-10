#!/usr/bin/env node
// G-01.5-9 differentials: (D1) footer fill on About desktop; (D2/D3) sticky-footer mechanisms.
import { spawn } from "node:child_process"
import { mkdtemp, rm, writeFile, mkdir } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

const BASE = process.env.PROBE_BASE_URL || "http://localhost:4000"
const OUT = process.env.OUT_DIR || "/tmp/diff9-out"

async function startChrome() {
  const userDataDir = await mkdtemp(join(tmpdir(), "g0159d-chrome-"))
  let proc = null
  for (const bin of ["google-chrome-stable", "chromium", "chromium-browser"]) {
    try {
      proc = spawn(bin, ["--headless=new", "--disable-gpu", "--hide-scrollbars", "--no-first-run",
        `--user-data-dir=${userDataDir}`, "--remote-debugging-port=0"], { stdio: ["ignore", "ignore", "pipe"] })
      await new Promise((res, rej) => { proc.once("spawn", res); proc.once("error", rej) })
      break
    } catch { proc = null }
  }
  if (!proc) throw new Error("no chrome")
  let buf = ""
  const port = await new Promise((res, rej) => {
    const t = setTimeout(() => rej(new Error("no devtools:\n" + buf)), 15000)
    proc.stderr.on("data", d => { buf += d.toString(); const m = buf.match(/DevTools listening on ws:\/\/[^:]+:(\d+)\//); if (m) { clearTimeout(t); res(Number(m[1])) } })
  })
  return { proc, userDataDir, port }
}
async function stopChrome({ proc, userDataDir }) {
  if (proc && proc.exitCode === null) { const e = new Promise(r => proc.once("exit", r)); proc.kill(); await Promise.race([e, new Promise(r => setTimeout(r, 5000))]) }
  await rm(userDataDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 })
}
class CDP {
  constructor(ws) {
    this.ws = ws; this.nextId = 1; this.pending = new Map()
    ws.addEventListener("message", ev => {
      const m = JSON.parse(ev.data)
      if (m.id !== undefined && this.pending.has(m.id)) { const { resolve, reject } = this.pending.get(m.id); this.pending.delete(m.id); if (m.error) reject(new Error(JSON.stringify(m.error))); else resolve(m.result) }
    })
  }
  send(method, params = {}) { const id = this.nextId++; return new Promise((res, rej) => { this.pending.set(id, { resolve: res, reject: rej }); this.ws.send(JSON.stringify({ id, method, params })) }) }
  once(method) { return new Promise(res => { const h = ev => { const m = JSON.parse(ev.data); if (m.method === method) { this.ws.removeEventListener("message", h); res(m.params) } }; this.ws.addEventListener("message", h) }) }
}
async function connect(port) {
  const res = await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: "PUT" })
  const target = await res.json()
  const ws = new WebSocket(target.webSocketDebuggerUrl)
  await new Promise((r, j) => { ws.addEventListener("open", r, { once: true }); ws.addEventListener("error", j, { once: true }) })
  const c = new CDP(ws); await c.send("Page.enable"); await c.send("Runtime.enable"); return c
}
async function ev(c, expr) {
  const r = await c.send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true })
  if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails))
  return r.result.value
}
async function goto(c, url, w, h) {
  await c.send("Emulation.setDeviceMetricsOverride", { width: w, height: h, deviceScaleFactor: 1, mobile: false })
  const loaded = c.once("Page.loadEventFired"); await c.send("Page.navigate", { url }); await loaded
  await ev(c, `new Promise(r=>setTimeout(r,450))`)
}
const inject = css => `(() => { let s=document.getElementById('__diff9'); if(!s){s=document.createElement('style');s.id='__diff9';document.head.appendChild(s)} s.textContent=${JSON.stringify(css)}; return true })()`
const clearInject = `(() => { const s=document.getElementById('__diff9'); if(s) s.remove(); return true })()`

const M = `(() => {
  const de=document.documentElement, b=document.body
  const foot=document.querySelector('footer.pk-footer'), main=document.querySelector('main')
  const hdr=document.querySelector('#app-header')||document.querySelector('header')
  const sy=window.scrollY
  const r=el=>{if(!el)return null;const q=el.getBoundingClientRect();return {top:+(q.top+sy).toFixed(2),bottom:+(q.bottom+sy).toFixed(2),h:+q.height.toFixed(2),left:+q.left.toFixed(2),w:+q.width.toFixed(2)}}
  return {
    scrollH:de.scrollHeight, clientH:de.clientHeight, bodyH:+b.getBoundingClientRect().height.toFixed(2),
    gapBelowFooter: foot?+(de.scrollHeight-(foot.getBoundingClientRect().bottom+sy)).toFixed(2):null,
    footer:r(foot), main:r(main), header:r(hdr),
    headerPos: hdr?getComputedStyle(hdr).position:null,
    headerTopViewport: hdr?+hdr.getBoundingClientRect().top.toFixed(2):null,
    bodyDisplay:getComputedStyle(b).display, bodyMinH:getComputedStyle(b).minHeight, bodyPadB:getComputedStyle(b).paddingBottom,
    innerDiv: (()=>{const d=main&&main.querySelector(':scope > div');return d?r(d):null})(),
    footerBg: foot?getComputedStyle(foot).backgroundColor:null
  }
})()`

const STICKY_M1 = `body { min-height: 100dvh; display: flex; flex-direction: column; }
footer.pk-footer { margin-top: auto; }`
const STICKY_M2 = `body { min-height: 100dvh; display: flex; flex-direction: column; }
main { flex: 1 0 auto; }`
const FILL_D1 = `footer.pk-footer { background: var(--color-base-300) !important; }`

async function main() {
  await mkdir(OUT, { recursive: true })
  const chrome = await startChrome()
  const rows = []
  try {
    const c = await connect(chrome.port)
    const scenarios = [
      // [label, path, w, h, css, screenshot?]
      ["BASE  about-desktop", "/quienes-somos", 1280, 900, null, true],
      ["D1    about-desktop footer->base300", "/quienes-somos", 1280, 900, FILL_D1, true],
      ["BASE  detail 1280x1080", "/juegos/1", 1280, 1080, null, true],
      ["M1    detail 1280x1080", "/juegos/1", 1280, 1080, STICKY_M1, true],
      ["M2    detail 1280x1080", "/juegos/1", 1280, 1080, STICKY_M2, false],
      ["BASE  emptysearch 1280x900", "/?q=zzqqxxnope", 1280, 900, null, true],
      ["M1    emptysearch 1280x900", "/?q=zzqqxxnope", 1280, 900, STICKY_M1, true],
      ["M2    emptysearch 1280x900", "/?q=zzqqxxnope", 1280, 900, STICKY_M2, false],
      ["BASE  about-desktop tallpage", "/quienes-somos", 1280, 900, null, false],
      ["M1    about-desktop tallpage (regression check)", "/quienes-somos", 1280, 900, STICKY_M1, true],
      ["M2    about-desktop tallpage (regression check)", "/quienes-somos", 1280, 900, STICKY_M2, false],
      ["BASE  about-mobile 390x844", "/quienes-somos", 390, 844, null, false],
      ["M1    about-mobile 390x844 (cta clearance)", "/quienes-somos", 390, 844, STICKY_M1, true],
      ["BASE  catalog 1280x900", "/", 1280, 900, null, false],
      ["M1    catalog 1280x900", "/", 1280, 900, STICKY_M1, false],
      ["BASE  detail-mobile 390x844 (cta bar)", "/juegos/1", 390, 844, null, false],
      ["M1    detail-mobile 390x844 (cta bar)", "/juegos/1", 390, 844, STICKY_M1, false],
    ]
    for (const [label, path, w, h, css, shot] of scenarios) {
      await goto(c, BASE + path, w, h)
      await ev(c, clearInject)
      if (css) { await ev(c, inject(css)); await ev(c, `new Promise(r=>setTimeout(r,250))`) }
      await ev(c, `window.scrollTo(0, document.documentElement.scrollHeight); new Promise(r=>setTimeout(r,300))`)
      const m = await ev(c, M)
      rows.push({ label, ...m })
      if (shot) {
        const s = await c.send("Page.captureScreenshot", { format: "png" })
        await writeFile(join(OUT, label.replace(/[^a-z0-9]+/gi, "-") + ".png"), Buffer.from(s.data, "base64"))
      }
    }
  } finally { await stopChrome(chrome) }
  await writeFile(join(OUT, "diff.json"), JSON.stringify(rows, null, 2))
  console.log("label".padEnd(48), "scrollH".padStart(8), "bodyH".padStart(9), "gapBelowFooter".padStart(15), "footer.top".padStart(11), "footer.h".padStart(9), "hdrPos".padStart(8), "hdrVpTop".padStart(9), "mainW".padStart(8), "innerW".padStart(8))
  for (const r of rows) {
    console.log(r.label.padEnd(48), String(r.scrollH).padStart(8), String(r.bodyH).padStart(9), String(r.gapBelowFooter).padStart(15),
      String(r.footer?.top).padStart(11), String(r.footer?.h).padStart(9), String(r.headerPos).padStart(8), String(r.headerTopViewport).padStart(9),
      String(r.main?.w).padStart(8), String(r.innerDiv?.w).padStart(8))
  }
}
main().catch(e => { console.error(e); process.exit(1) })
