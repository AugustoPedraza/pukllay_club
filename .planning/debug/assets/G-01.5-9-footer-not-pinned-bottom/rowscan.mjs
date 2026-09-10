#!/usr/bin/env node
// Row-scan the bottom of a screenshot: report the run-length of each distinct row colour.
import { readFileSync } from "node:fs"
import zlib from "node:zlib"

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

const file = process.argv[2]
const fromY = Number(process.argv[3] ?? 0)
const sampleX = Number(process.argv[4] ?? 8)
const img = decodePNG(readFileSync(file))
const px = (x, y) => { const i = (y * img.w + x) * img.ch; return [img.data[i], img.data[i + 1], img.data[i + 2]] }

// classify each row by the colour at sampleX (a gutter column, away from text)
const runs = []
for (let y = fromY; y < img.h; y++) {
  const c = px(sampleX, y).join(",")
  // does this row contain ink? (any pixel differing from the row's own gutter colour by >18 in the middle 90%)
  let ink = 0
  const g = px(sampleX, y)
  for (let x = Math.floor(img.w * 0.05); x < Math.floor(img.w * 0.95); x++) {
    const q = px(x, y)
    if (Math.abs(q[0] - g[0]) + Math.abs(q[1] - g[1]) + Math.abs(q[2] - g[2]) > 30) { ink++; if (ink >= 3) break }
  }
  const key = c + (ink >= 3 ? "|INK" : "")
  const last = runs[runs.length - 1]
  if (last && last.key === key) last.end = y
  else runs.push({ key, colour: c, ink: ink >= 3, start: y, end: y })
}
console.log(`image ${img.w}x${img.h}  scanning from y=${fromY}, gutter x=${sampleX}`)
for (const r of runs) console.log(`  y ${String(r.start).padStart(5)}-${String(r.end).padStart(5)} (${String(r.end - r.start + 1).padStart(4)} rows)  rgb(${r.colour})${r.ink ? "  <INK>" : ""}`)
