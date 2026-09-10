import { launch, Session } from './probe.mjs';

const EXPR = `(() => {
  const out = [];
  document.querySelectorAll('main section, main > div').forEach(sec => {
    const r = sec.getBoundingClientRect();
    if (r.height < 40) return;
    const cs = getComputedStyle(sec);
    const inner = sec.querySelector('.pk-band-inner') || sec.firstElementChild;
    const ir = inner ? inner.getBoundingClientRect() : null;
    out.push({
      id: sec.id || sec.className.slice(0, 46),
      isBand: sec.classList.contains('pk-band'),
      h: +r.height.toFixed(1),
      padTop: cs.paddingTop, padBottom: cs.paddingBottom,
      innerH: ir ? +ir.height.toFixed(1) : null,
      fillPct: ir ? +((ir.height / r.height) * 100).toFixed(1) : null,
      padOverContent: ir ? +(((parseFloat(cs.paddingTop) + parseFloat(cs.paddingBottom)) / ir.height)).toFixed(2) : null,
    });
  });
  // Cierre pair-specific ratios
  const h2 = document.querySelector('#cierre h2');
  const sig = document.querySelector('#cierre .pk-about-closing-meta');
  const cta = document.querySelector('#cierre .pk-about-cierre-cta');
  const rr = (e) => e ? { w: +e.getBoundingClientRect().width.toFixed(2), h: +e.getBoundingClientRect().height.toFixed(2) } : null;
  const pair = {
    h2: rr(h2), sig: rr(sig), cta: rr(cta),
    h2FontSize: getComputedStyle(h2).fontSize,
    sigFontSize: getComputedStyle(sig).fontSize,
    ctaDisplay: cta ? getComputedStyle(cta).display : null,
    widthRatio_sig_over_h2: +(sig.getBoundingClientRect().width / h2.getBoundingClientRect().width).toFixed(3),
    fontRatio_h2_over_sig: +(parseFloat(getComputedStyle(h2).fontSize) / parseFloat(getComputedStyle(sig).fontSize)).toFixed(3),
    innerWidthAvail: +document.querySelector('#cierre .pk-band-inner').getBoundingClientRect().width.toFixed(2)
      - parseFloat(getComputedStyle(document.querySelector('#cierre .pk-band-inner')).paddingLeft) * 2,
  };
  return { viewport: innerWidth, sections: out, pair };
})()`;

const proc = await launch();
const s = await Session.open();
const widths = process.argv[2].split(',').map(Number);
for (const w of widths) {
  await s.viewport(w, 900);
  await s.goto('http://localhost:4000/quienes-somos');
  const d = await s.evalJs(EXPR);
  console.log(`\n===== ${w}px =====`);
  console.log('PAIR:', JSON.stringify(d.pair));
  console.log('BANDS:');
  for (const x of d.sections) {
    if (!x.isBand) continue;
    console.log(`  ${String(x.id).padEnd(20)} h=${String(x.h).padStart(7)} pad=${x.padTop}/${x.padBottom} inner=${String(x.innerH).padStart(7)} fill=${x.fillPct}%  pad/content=${x.padOverContent}`);
  }
}
proc.kill();
process.exit(0);
