import { launch, Session } from './probe.mjs';

const MEASURE = `(() => {
  const q = (s) => document.querySelector(s);
  const cierre = q('#cierre');
  const inner = q('#cierre .pk-band-inner');
  const h2 = q('#cierre h2');
  const cta = q('#cierre .pk-about-cierre-cta');
  const sig = q('#cierre .pk-about-closing-meta');
  const footer = q('.pk-footer');
  const prevBand = cierre ? cierre.previousElementSibling : null;

  const R = (el) => { if (!el) return null; const r = el.getBoundingClientRect();
    return { top: +r.top.toFixed(2), bottom: +r.bottom.toFixed(2), left: +r.left.toFixed(2),
             right: +r.right.toFixed(2), w: +r.width.toFixed(2), h: +r.height.toFixed(2) }; };

  const S = (el, props) => { if (!el) return null; const cs = getComputedStyle(el);
    const o = {}; props.forEach(p => o[p] = cs.getPropertyValue(p)); return o; };

  // Range-based line boxes: the REAL rendered text line rects inside an element.
  const lines = (el) => {
    if (!el) return null;
    const out = [];
    const walk = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    let n;
    while ((n = walk.nextNode())) {
      if (!n.nodeValue.trim()) continue;
      const rg = document.createRange();
      rg.selectNodeContents(n);
      for (const r of rg.getClientRects()) {
        if (r.width < 0.5 || r.height < 0.5) continue;
        out.push({ top: +r.top.toFixed(2), bottom: +r.bottom.toFixed(2),
                   left: +r.left.toFixed(2), right: +r.right.toFixed(2),
                   w: +r.width.toFixed(2), h: +r.height.toFixed(2),
                   text: n.nodeValue.trim().slice(0, 40) });
      }
    }
    return out.sort((a,b) => a.top - b.top);
  };

  const typeProps = ['font-size','line-height','font-family','font-weight','letter-spacing',
                     'text-transform','color','margin-top','margin-bottom','display'];

  return {
    viewport: { w: innerWidth, h: innerHeight },
    cierre: { rect: R(cierre), style: S(cierre, ['padding-top','padding-bottom','background-color','padding-left','padding-right']) },
    inner:  { rect: R(inner),  style: S(inner, ['gap','display','flex-direction','align-items','text-align','padding-left','padding-right','max-width']) },
    h2:     { rect: R(h2),     style: S(h2, typeProps), lines: lines(h2) },
    cta:    { rect: R(cta),    style: S(cta, ['display']) },
    sig:    { rect: R(sig),    style: S(sig, typeProps), lines: lines(sig) },
    footer: { rect: R(footer), style: S(footer, ['background-color','border-top-width','border-top-color','margin-top','padding-top']) },
    prevBand: { id: prevBand ? (prevBand.id || prevBand.className) : null, rect: R(prevBand),
                style: S(prevBand, ['padding-bottom','background-color']) },
    bodyPadBottom: getComputedStyle(document.body).paddingBottom,
    ctaBar: { rect: R(q('.pk-about-cta-bar')), style: S(q('.pk-about-cta-bar'), ['display','height']) },
  };
})()`;

const proc = await launch();
const s = await Session.open();

const widths = process.argv[2] ? process.argv[2].split(',').map(Number) : [375, 390, 360, 320, 430, 479, 481, 640];
const out = {};
for (const w of widths) {
  await s.viewport(w, 812);
  await s.goto('http://localhost:4000/quienes-somos');
  await s.evalJs(`document.querySelector('#cierre').scrollIntoView({block:'center'})`);
  await new Promise(r => setTimeout(r, 300));
  out[w] = await s.evalJs(MEASURE);
}
console.log(JSON.stringify(out, null, 1));
proc.kill();
process.exit(0);
