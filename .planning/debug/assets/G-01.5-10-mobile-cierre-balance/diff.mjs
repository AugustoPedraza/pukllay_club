import { launch, Session } from './probe.mjs';

const CASES = [
  ['S0-baseline',      ``],
  ['S1-pad48',         `#cierre { padding-block: 3rem !important; }`],
  ['S2-pad40',         `#cierre { padding-block: 2.5rem !important; }`],
  ['S3-gap16',         `#cierre .pk-band-inner { gap: 1rem !important; }`],
  ['S4-gap12',         `#cierre .pk-band-inner { gap: 0.75rem !important; }`],
  ['S5-buttonBack',    `#cierre .pk-about-cierre-cta { display: flex !important; }`],
  ['S6-h2-32',         `#cierre h2 { font-size: 32px !important; line-height: 40px !important; }`],
  ['S7-sig-12',        `#cierre .pk-about-closing-meta { font-size: 12px !important; }`],
  ['S8-noBr',          `#cierre .pk-about-closing-break { display: none !important; }`],
  ['S9-pad48-gap16',   `#cierre { padding-block: 3rem !important; } #cierre .pk-band-inner { gap: 1rem !important; }`],
];

const MEASURE = `(() => {
  const c = document.querySelector('#cierre');
  const inner = document.querySelector('#cierre .pk-band-inner');
  const h2 = document.querySelector('#cierre h2');
  const sig = document.querySelector('#cierre .pk-about-closing-meta');
  const cs = getComputedStyle(c);
  const R = e => e.getBoundingClientRect();
  const lines = (el) => { const o=[]; const w=document.createTreeWalker(el,NodeFilter.SHOW_TEXT); let n;
    while((n=w.nextNode())){ if(!n.nodeValue.trim()) continue; const rg=document.createRange(); rg.selectNodeContents(n);
      for(const r of rg.getClientRects()){ if(r.width<0.5) continue; o.push(+r.width.toFixed(1)); } } return o; };
  const pt = parseFloat(cs.paddingTop), pb = parseFloat(cs.paddingBottom);
  return {
    bandH: +R(c).height.toFixed(1), innerH: +R(inner).height.toFixed(1),
    pad: pt + '/' + pb,
    padOverContent: +((pt+pb)/R(inner).height).toFixed(2),
    fillPct: +((R(inner).height/R(c).height)*100).toFixed(1),
    gap: getComputedStyle(inner).gap,
    h2W: +R(h2).width.toFixed(1), sigW: +R(sig).width.toFixed(1),
    sigOverH2: +(R(sig).width/R(h2).width).toFixed(3),
    lineWidths: [...lines(h2), ...lines(sig)],
    boxGapH2ToSig: +(R(sig).top - R(h2).bottom).toFixed(1),
  };
})()`;

const proc = await launch();
const s = await Session.open();
await s.viewport(375, 812);

for (const [name, css] of CASES) {
  await s.goto('http://localhost:4000/quienes-somos');
  if (css) {
    await s.evalJs(`(() => { const st=document.createElement('style'); st.id='__diff'; st.textContent=${JSON.stringify(css)}; document.head.appendChild(st); return true; })()`);
  }
  await new Promise(r => setTimeout(r, 350));
  const m = await s.evalJs(MEASURE);
  const box = await s.evalJs(`(() => { const c=document.querySelector('#cierre'); const f=document.querySelector('.pk-footer');
    const r=c.getBoundingClientRect(), fr=f.getBoundingClientRect(); const y=r.top+scrollY;
    return { x:0, y:Math.round(y-16), width:375, height:Math.round(fr.bottom+scrollY-y+30), origin:Math.round(y-16) }; })()`);
  await s.screenshot(`d-${name}.png`, { x: box.x, y: box.y, width: box.width, height: box.height });
  console.log(`${name.padEnd(16)} band=${String(m.bandH).padStart(6)} inner=${String(m.innerH).padStart(6)} pad=${m.pad.padEnd(9)} pad/content=${String(m.padOverContent).padStart(5)} fill=${String(m.fillPct).padStart(5)}% gap=${m.gap.padEnd(6)} h2W=${String(m.h2W).padStart(6)} sigW=${String(m.sigW).padStart(6)} sig/h2=${m.sigOverH2} lines=[${m.lineWidths.join(', ')}] boxGap=${m.boxGapH2ToSig} origin=${box.origin}`);
}
proc.kill();
process.exit(0);
