#!/usr/bin/env node
// G-01.5-8 probe: Cierre tagline grouping + Cierre/footer contrast.
import { spawn } from "node:child_process"
import { mkdtemp, rm, writeFile, mkdir } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import zlib from "node:zlib"

const BASE = process.env.PROBE_BASE_URL || "http://localhost:4000"
const OUT = process.env.OUT_DIR || "/tmp/probe-out"

async function startChrome() {
  const userDataDir = await mkdtemp(join(tmpdir(), "g0158-chrome-"))
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

// --- zero-dep PNG decode (RGBA8, non-interlaced) ---
function decodePNG(buf) {
  let p = 8, w = 0, h = 0, bd = 0, ct = 0
  const idat = []
  while (p < buf.length) {
    const len = buf.readUInt32BE(p); const type = buf.toString("ascii", p + 4, p + 8)
    const data = buf.subarray(p + 8, p + 8 + len)
    if (type === "IHDR") { w = data.readUInt32BE(0); h = data.readUInt32BE(4); bd = data[8]; ct = data[9] }
    else if (type === "IDAT") idat.push(data)
    else if (type === "IEND") break
    p += 12 + len
  }
  if (bd !== 8) throw new Error("bitdepth " + bd)
  const ch = { 0: 1, 2: 3, 4: 2, 6: 4 }[ct]
  const raw = zlib.inflateSync(Buffer.concat(idat))
  const stride = w * ch
  const out = Buffer.alloc(h * stride)
  let pos = 0
  for (let y = 0; y < h; y++) {
    const f = raw[pos++]
    const line = raw.subarray(pos, pos + stride); pos += stride
    const cur = out.subarray(y * stride, (y + 1) * stride)
    const prev = y > 0 ? out.subarray((y - 1) * stride, y * stride) : null
    for (let i = 0; i < stride; i++) {
      const a = i >= ch ? cur[i - ch] : 0
      const b = prev ? prev[i] : 0
      const c = (prev && i >= ch) ? prev[i - ch] : 0
      let v = line[i]
      if (f === 1) v += a
      else if (f === 2) v += b
      else if (f === 3) v += (a + b) >> 1
      else if (f === 4) { const pp = a + b - c, pa = Math.abs(pp - a), pb = Math.abs(pp - b), pc = Math.abs(pp - c); v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c) }
      cur[i] = v & 0xff
    }
  }
  return { w, h, ch, data: out }
}
function srgb(c) { const s = c / 255; return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4) }
function lum(r, g, b) { return 0.2126 * srgb(r) + 0.7152 * srgb(g) + 0.0722 * srgb(b) }
function ratio(a, b) { const l1 = lum(...a), l2 = lum(...b); return ((Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05)) }

async function evalJS(c, expr) {
  const r = await c.send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true })
  if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails))
  return r.result.value
}

const MEASURE = `(() => {
  const q = s => document.querySelector(s);
  const r = el => { if(!el) return null; const b = el.getBoundingClientRect(); return {t:+b.top.toFixed(2),b:+b.bottom.toFixed(2),h:+b.height.toFixed(2),l:+b.left.toFixed(2),w:+b.width.toFixed(2)} };
  const cs = (el,props) => { if(!el) return null; const s=getComputedStyle(el); const o={}; props.forEach(p=>o[p]=s[p]); return o };
  const cierre = q('#cierre');
  const inner = q('#cierre .pk-band-inner');
  const h2 = q('#cierre h2');
  const ctaWrap = q('#cierre .pk-about-cierre-cta');
  const ctaLink = ctaWrap && ctaWrap.querySelector('a,button');
  const sig = q('#cierre .pk-about-closing-meta');
  const footer = q('footer.pk-footer') || q('.pk-footer');
  const frow = q('.pk-footer-row');
  const fleft = q('.pk-footer-left');
  const fmeta = q('.pk-footer-meta');
  // text ink line-boxes via Range
  const rangeRect = el => { if(!el) return null; const rg=document.createRange(); rg.selectNodeContents(el); const b=rg.getBoundingClientRect(); return {t:+b.top.toFixed(2),b:+b.bottom.toFixed(2),h:+b.height.toFixed(2)} };
  return {
    scrollY: window.scrollY, docH: document.documentElement.scrollHeight,
    rects: { cierre:r(cierre), inner:r(inner), h2:r(h2), ctaWrap:r(ctaWrap), ctaLink:r(ctaLink), sig:r(sig), footer:r(footer), frow:r(frow), fleft:r(fleft), fmeta:r(fmeta) },
    ink: { h2:rangeRect(h2), sig:rangeRect(sig), fmeta:rangeRect(fmeta) },
    styles: {
      cierre: cs(cierre,['backgroundColor','paddingTop','paddingBottom','borderBottomWidth','marginBottom']),
      inner: cs(inner,['display','gap','rowGap','alignItems','textAlign']),
      h2: cs(h2,['fontSize','lineHeight','fontFamily','color','marginTop','marginBottom','textTransform','fontWeight']),
      ctaWrap: cs(ctaWrap,['display','marginTop','marginBottom','paddingTop','paddingBottom']),
      ctaLink: cs(ctaLink,['fontSize','lineHeight','paddingTop','paddingBottom','borderTopWidth','borderColor','color','backgroundColor','borderRadius','fontWeight','textTransform','letterSpacing']),
      sig: cs(sig,['fontSize','lineHeight','color','letterSpacing','textTransform','fontWeight','marginTop','marginBottom','opacity','fontFamily']),
      footer: cs(footer,['backgroundColor','borderTopWidth','borderTopColor','marginTop','paddingTop']),
      frow: cs(frow,['paddingTop','paddingBottom']),
      fmeta: cs(fmeta,['fontSize','lineHeight','color','letterSpacing','textTransform','fontWeight','fontFamily']),
      html: cs(document.documentElement,['backgroundColor']),
      body: cs(document.body,['backgroundColor'])
    },
    gaps: (() => {
      const g=(a,b)=> (a&&b)? +(b.top-a.bottom).toFixed(2) : null;
      const A=el=>el?el.getBoundingClientRect():null;
      return {
        h2_to_cta: g(A(h2),A(ctaWrap)),
        cta_to_sig: g(A(ctaWrap),A(sig)),
        ctaLink_to_sig: g(A(ctaLink),A(sig)),
        sig_to_cierreBottom: cierre&&sig? +(cierre.getBoundingClientRect().bottom - sig.getBoundingClientRect().bottom).toFixed(2):null,
        cierre_to_footer: g(A(cierre),A(footer)),
        sig_to_footerInk: g(A(sig),A(frow)),
        innerTop_to_cierreTop: inner&&cierre? +(inner.getBoundingClientRect().top - cierre.getBoundingClientRect().top).toFixed(2):null
      }
    })(),
    lastBand: (() => { const bs=[...document.querySelectorAll('section.pk-band')]; return bs.length? bs[bs.length-1].id : null })()
  }
})()`

async function shot(c, name, clip) {
  const params = { format: "png", captureBeyondViewport: true }
  if (clip) params.clip = { ...clip, scale: 1 }
  const r = await c.send("Page.captureScreenshot", params)
  const buf = Buffer.from(r.data, "base64")
  await writeFile(join(OUT, name + ".png"), buf)
  return buf
}

// row scan: for each y, does the row contain non-background ink?
function rowScan(png, bgSamples, tol = 10) {
  const { w, h, ch, data } = png
  const rows = []
  for (let y = 0; y < h; y++) {
    let inkCount = 0, minL = 999, sample = null
    for (let x = Math.floor(w * 0.05); x < Math.floor(w * 0.95); x++) {
      const i = (y * w + x) * ch
      const r = data[i], g = data[i + 1], b = data[i + 2]
      const isBg = bgSamples.some(s => Math.abs(r - s[0]) <= tol && Math.abs(g - s[1]) <= tol && Math.abs(b - s[2]) <= tol)
      if (!isBg) { inkCount++; const l = lum(r, g, b); if (l < minL) { minL = l; sample = [r, g, b] } }
    }
    rows.push({ y, inkCount, sample })
  }
  return rows
}
function inkBands(rows, minCount = 1) {
  const out = []; let cur = null
  for (const r of rows) {
    if (r.inkCount >= minCount) { if (!cur) cur = { start: r.y, end: r.y, max: r.inkCount }; else { cur.end = r.y; cur.max = Math.max(cur.max, r.inkCount) } }
    else if (cur) { out.push(cur); cur = null }
  }
  if (cur) out.push(cur)
  return out
}

async function loadCase(c, { width, height, theme, css }) {
  await c.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile: false })
  const nav = c.once("Page.loadEventFired")
  await c.send("Page.navigate", { url: `${BASE}/quienes-somos` })
  await nav
  await evalJS(c, `document.documentElement.dataset.theme = ${JSON.stringify(theme)}; true`)
  if (css) await evalJS(c, `(()=>{const s=document.createElement('style');s.id='probe-inject';s.textContent=${JSON.stringify(css)};document.head.appendChild(s);return true})()`)
  await new Promise(r => setTimeout(r, 350))
  await evalJS(c, `document.querySelector('#cierre').scrollIntoView({block:'end'}); window.scrollTo(0, document.documentElement.scrollHeight); true`)
  await new Promise(r => setTimeout(r, 250))
  return evalJS(c, MEASURE)
}

async function main() {
  await mkdir(OUT, { recursive: true })
  const chrome = await startChrome()
  const results = {}
  try {
    const c = await connect(chrome.port)
    const arg = process.argv[2] || "base"

    if (arg === "base") {
      for (const [w, h, theme] of [[1280, 900, "light"], [1440, 900, "light"], [1280, 900, "dark"], [768, 900, "light"], [390, 844, "light"]]) {
        const key = `${w}x${h}-${theme}`
        results[key] = await loadCase(c, { width: w, height: h, theme })
      }
      // pixel scan at 1280 light over the cierre+footer region
      const m = await loadCase(c, { width: 1280, height: 900, theme: "light" })
      const cy = m.rects.cierre, fo = m.rects.footer
      const sy = m.scrollY; const clip = { x: 0, y: Math.max(0, cy.t + sy - 120), width: 1280, height: Math.min(2000, fo.b - cy.t + 120) }
      const buf = await shot(c, "base-1280-light-cierre-footer", clip)
      const png = decodePNG(buf)
      results.scan1280 = {
        clip,
        bands: inkBands(rowScan(png, [[243, 236, 250], [255, 255, 255]], 6), 3).map(b => ({ ...b, absTop: +(clip.y + b.start).toFixed(1), absBot: +(clip.y + b.end).toFixed(1) })),
        colorProbe: (() => {
          const at = (x, y) => { const i = (y * png.w + x) * png.ch; return [png.data[i], png.data[i + 1], png.data[i + 2]] }
          const rel = y => Math.round(y + sy - clip.y)
          return {
            cierreMid: at(20, rel((cy.t + cy.b) / 2)),
            cierreJustAbove: at(20, rel(fo.t - 4)),
            boundaryRow: at(20, rel(fo.t)),
            boundaryRow1: at(20, rel(fo.t + 1)),
            footerJustBelow: at(20, rel(fo.t + 4)),
            footerMid: at(20, rel(fo.t + 30))
          }
        })()
      }
      await shot(c, "base-1280-light-full", null)
    }

    if (arg === "diff") {
      // Differentials, one variable at a time, at 1280x900 light
      const cases = {
        S1_footer_base100: `.pk-footer{background:var(--color-base-100) !important}`,
        S2_footer_base300: `.pk-footer{background:var(--color-base-300) !important}`,
        S3_cierre_untint: `#cierre{background:var(--color-base-100) !important}`,
        S4_gap24_back: `body:has(#cierre) main.pk-bottom-collapse + .pk-footer{margin-top:1.5rem !important}`,
        T1_sig_register: `#cierre .pk-about-closing-meta{font-size:1rem;letter-spacing:normal;text-transform:none;color:var(--color-base-content)}`,
        P1_tier_gap: `#cierre .pk-band-inner{gap:2.5rem} #cierre .pk-about-closing-meta{margin-top:-1.75rem}`,
        P2_gap_flat_8: `#cierre .pk-band-inner{gap:0.5rem}`,
        AND_surface_only: `.pk-footer{background:var(--color-base-100) !important}`,
        AND_spacing_only: `#cierre .pk-band-inner{gap:2.5rem} #cierre .pk-about-closing-meta{margin-top:-1.75rem}`,
        AND_both: `.pk-footer{background:var(--color-base-100) !important} #cierre .pk-band-inner{gap:2.5rem} #cierre .pk-about-closing-meta{margin-top:-1.75rem}`,
      }
      for (const [name, css] of Object.entries(cases)) {
        const m = await loadCase(c, { width: 1280, height: 900, theme: "light", css })
        results[name] = { gaps: m.gaps, cierre: m.rects.cierre, sig: m.rects.sig, footerBg: m.styles.footer.backgroundColor, cierreBg: m.styles.cierre.backgroundColor }
        const cy = m.rects.cierre, fo = m.rects.footer
        await shot(c, "diff-" + name, { x: 0, y: Math.max(0, cy.t + m.scrollY), width: 1280, height: Math.min(1400, fo.b - cy.t) })
      }
    }
    console.log(JSON.stringify(results, null, 1))
  } finally { await stopChrome(chrome) }
}
main().catch(e => { console.error("FAIL", e); process.exit(1) })
