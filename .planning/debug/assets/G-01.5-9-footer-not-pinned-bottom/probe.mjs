#!/usr/bin/env node
// G-01.5-9 probe: is there scrollable/visible space BELOW the footer?
import { spawn } from "node:child_process"
import { mkdtemp, rm, writeFile, mkdir } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

const BASE = process.env.PROBE_BASE_URL || "http://localhost:4000"
const OUT = process.env.OUT_DIR || "/tmp/probe9-out"

async function startChrome() {
  const userDataDir = await mkdtemp(join(tmpdir(), "g0159-chrome-"))
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
    proc.stderr.on("data", d => {
      buf += d.toString()
      const m = buf.match(/DevTools listening on ws:\/\/[^:]+:(\d+)\//)
      if (m) { clearTimeout(t); res(Number(m[1])) }
    })
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
      if (m.id !== undefined && this.pending.has(m.id)) {
        const { resolve, reject } = this.pending.get(m.id); this.pending.delete(m.id)
        if (m.error) reject(new Error(JSON.stringify(m.error))); else resolve(m.result)
      }
    })
  }
  send(method, params = {}) {
    const id = this.nextId++
    return new Promise((res, rej) => { this.pending.set(id, { resolve: res, reject: rej }); this.ws.send(JSON.stringify({ id, method, params })) })
  }
  once(method) {
    return new Promise(res => {
      const h = ev => { const m = JSON.parse(ev.data); if (m.method === method) { this.ws.removeEventListener("message", h); res(m.params) } }
      this.ws.addEventListener("message", h)
    })
  }
}
async function connect(port) {
  const res = await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: "PUT" })
  const target = await res.json()
  const ws = new WebSocket(target.webSocketDebuggerUrl)
  await new Promise((r, j) => { ws.addEventListener("open", r, { once: true }); ws.addEventListener("error", j, { once: true }) })
  const c = new CDP(ws)
  await c.send("Page.enable"); await c.send("Runtime.enable")
  return c
}
async function evalJs(c, expr) {
  const r = await c.send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true })
  if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails))
  return r.result.value
}
async function goto(c, url, w, h, theme) {
  await c.send("Emulation.setDeviceMetricsOverride", { width: w, height: h, deviceScaleFactor: 1, mobile: false })
  const loaded = c.once("Page.loadEventFired")
  await c.send("Page.navigate", { url })
  await loaded
  if (theme === "dark") {
    await evalJs(c, `document.documentElement.setAttribute('data-theme','pukllay-dark')`)
  }
  await evalJs(c, `new Promise(r=>setTimeout(r,450))`)
}

const MEASURE = `(() => {
  const de = document.documentElement, b = document.body
  const foot = document.querySelector('footer.pk-footer') || document.querySelector('footer')
  const main = document.querySelector('main')
  const sy = window.scrollY
  const r = el => { if(!el) return null; const q = el.getBoundingClientRect(); return {top:+(q.top+sy).toFixed(2), bottom:+(q.bottom+sy).toFixed(2), height:+q.height.toFixed(2)} }
  const cs = el => { if(!el) return null; const s = getComputedStyle(el); return {
    height:s.height, minHeight:s.minHeight, display:s.display, position:s.position,
    marginTop:s.marginTop, marginBottom:s.marginBottom, paddingTop:s.paddingTop, paddingBottom:s.paddingBottom,
    background:s.backgroundColor, overflowY:s.overflowY, flexDirection:s.flexDirection } }
  // enumerate every element whose page-coord bottom exceeds the footer's bottom
  const fb = foot ? foot.getBoundingClientRect().bottom + sy : 0
  const below = []
  for (const el of document.querySelectorAll('*')) {
    const q = el.getBoundingClientRect()
    const bot = q.bottom + sy
    if (bot > fb + 0.5 && q.height > 0) {
      const s = getComputedStyle(el)
      below.push({ tag: el.tagName.toLowerCase(), cls: (el.className && el.className.baseVal !== undefined ? el.className.baseVal : el.className || '').toString().slice(0,60),
        id: el.id||'', bottom:+bot.toFixed(2), height:+q.height.toFixed(2), position:s.position, display:s.display })
    }
  }
  return {
    innerHeight: window.innerHeight,
    deClientHeight: de.clientHeight,
    deScrollHeight: de.scrollHeight,
    deOffsetHeight: de.offsetHeight,
    bodyScrollHeight: b.scrollHeight,
    bodyOffsetHeight: b.offsetHeight,
    maxScrollY: de.scrollHeight - de.clientHeight,
    html: { rect: r(de), cs: cs(de) },
    body: { rect: r(b), cs: cs(b) },
    main: { rect: r(main), cs: cs(main) },
    footer: { rect: r(foot), cs: cs(foot) },
    lastBand: (()=>{ const bs=[...document.querySelectorAll('section.pk-band')]; const l=bs[bs.length-1]; return l?{id:l.id, rect:r(l), bg:getComputedStyle(l).backgroundColor}:null })(),
    gapBelowFooterInDoc: foot ? +(de.scrollHeight - (foot.getBoundingClientRect().bottom + sy)).toFixed(2) : null,
    elementsBelowFooter: below,
    footerNextSiblings: foot ? [...(()=>{const out=[];let n=foot.nextElementSibling;while(n){out.push(n);n=n.nextElementSibling}return out})()].map(n=>{
      const s=getComputedStyle(n); const q=n.getBoundingClientRect();
      return {tag:n.tagName.toLowerCase(), cls:(n.className||'').toString().slice(0,60), id:n.id||'', display:s.display, position:s.position, h:+q.height.toFixed(2), bottom:+(q.bottom+sy).toFixed(2)}
    }) : []
  }
})()`

async function main() {
  await mkdir(OUT, { recursive: true })
  const chrome = await startChrome()
  const results = []
  try {
    const c = await connect(chrome.port)
    const cases = [
      ["/quienes-somos", 1280, 900, "light"],
      ["/quienes-somos", 1280, 2000, "light"],
      ["/quienes-somos", 1440, 900, "light"],
      ["/quienes-somos", 390, 844, "light"],
      ["/quienes-somos", 1280, 900, "dark"],
      ["/", 1280, 900, "light"],
      ["/", 1280, 4000, "light"],
      ["/juegos/1", 1280, 900, "light"],
    ]
    for (const [path, w, h, theme] of cases) {
      await goto(c, BASE + path, w, h, theme)
      // scroll to the very bottom
      await evalJs(c, `window.scrollTo(0, document.documentElement.scrollHeight); new Promise(r=>setTimeout(r,300))`)
      const m = await evalJs(c, MEASURE)
      results.push({ case: `${path} ${w}x${h} ${theme}`, ...m })
      const shot = await c.send("Page.captureScreenshot", { format: "png" })
      const safe = `${path.replace(/\//g, "_") || "root"}-${w}x${h}-${theme}.png`
      await writeFile(join(OUT, safe), Buffer.from(shot.data, "base64"))
    }
  } finally { await stopChrome(chrome) }
  await writeFile(join(OUT, "measure.json"), JSON.stringify(results, null, 2))
  for (const r of results) {
    console.log("=".repeat(78))
    console.log(r.case)
    console.log(`  innerHeight=${r.innerHeight} de.clientHeight=${r.deClientHeight} de.scrollHeight=${r.deScrollHeight} body.scrollHeight=${r.bodyScrollHeight} body.offsetHeight=${r.bodyOffsetHeight}`)
    console.log(`  html rect  ${JSON.stringify(r.html.rect)}  cs.height=${r.html.cs.height} minH=${r.html.cs.minHeight} mb=${r.html.cs.marginBottom} pb=${r.html.cs.paddingBottom} bg=${r.html.cs.background}`)
    console.log(`  body rect  ${JSON.stringify(r.body.rect)}  cs.height=${r.body.cs.height} minH=${r.body.cs.minHeight} mb=${r.body.cs.marginBottom} pb=${r.body.cs.paddingBottom} display=${r.body.cs.display} bg=${r.body.cs.background}`)
    console.log(`  main rect  ${JSON.stringify(r.main.rect)}  pb=${r.main.cs.paddingBottom} mb=${r.main.cs.marginBottom}`)
    console.log(`  footer rect ${JSON.stringify(r.footer.rect)} mt=${r.footer.cs.marginTop} mb=${r.footer.cs.marginBottom} bg=${r.footer.cs.background}`)
    console.log(`  lastBand   ${JSON.stringify(r.lastBand)}`)
    console.log(`  >>> gap below footer within document = ${r.gapBelowFooterInDoc}px   (scrollHeight - footer.bottom)`)
    console.log(`  footer next siblings: ${JSON.stringify(r.footerNextSiblings)}`)
    console.log(`  elements below footer: ${JSON.stringify(r.elementsBelowFooter)}`)
  }
}
main().catch(e => { console.error(e); process.exit(1) })
