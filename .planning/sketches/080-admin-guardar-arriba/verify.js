/* Checks de Chrome headless para el sketch 080 — `Guardar` sube y se apila.
   Correr desde la raíz del repo:
     python3 -m http.server 8765 &
     node .planning/sketches/080-admin-guardar-arriba/verify.js
   Env: PLAYWRIGHT_CORE, CHROME_BIN, SKETCH_URL, SHOTS_DIR. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
/* el `#vnav` del sketch ocupa 80px de flujo y el device es `100vh - 80`: la ventana se pide 80px
   más alta para que «375×667» sea un device de 667 reales, no de 587. */
const VN = 80;
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/080-admin-guardar-arriba/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-080-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);

/* el chrome se mide por el BORDE INFERIOR DE LA ÚLTIMA BANDA FIJA, no por `#main.top`.
   Primera versión: leía `#main`, que vive adentro de `.scroller` y SE MUEVE — daba 171,5 limpio y
   165,5 sucio, y el "adelgazamiento" era scroll, no layout. Un número que cambia cuando abrís una
   hoja no está midiendo el chrome. */
const probe = () => {
  const dev = document.querySelector('.device').getBoundingClientRect();
  const g = s => { const e = document.querySelector(s); if (!e || !e.offsetParent) return null;
    const r = e.getBoundingClientRect(); return { t: +(r.top - dev.top).toFixed(1), b: +(r.bottom - dev.top).toFixed(1), h: +r.height.toFixed(1) }; };
  const st = document.querySelector('.stbar'), sb = document.querySelector('.sbar');
  const bands = [g('.tbar'), g('.stbar'), g('.sbar')].filter(Boolean);
  const dot = document.querySelector('.stbar .dot');
  const cta = document.querySelector('.stbar .cta, .sbar .cta');
  const foot = [...document.querySelectorAll('.pg .cta')].find(e => e.offsetParent);
  const hostBg = cta ? getComputedStyle(cta.parentElement).backgroundColor : null;
  return {
    chrome: bands.length ? Math.max(...bands.map(b => b.b)) : 0,
    tbar: g('.tbar'), stbar: g('.stbar'), sbar: g('.sbar'),
    txt: st ? st.innerText.replace(/\s+/g, ' ').trim() : null,
    stbg: st ? getComputedStyle(st).backgroundColor : null,
    dot: dot ? { w: +dot.getBoundingClientRect().width.toFixed(1), h: +dot.getBoundingClientRect().height.toFixed(1),
                 c: getComputedStyle(dot).backgroundColor } : null,
    cta: cta ? { txt: cta.textContent.trim(), dis: cta.disabled, h: +cta.getBoundingClientRect().height.toFixed(1),
                 bg: getComputedStyle(cta).backgroundColor, hostBg,
                 hit: +cta.getBoundingClientRect().height.toFixed(1) } : null,
    foot: foot ? { txt: foot.textContent.trim(), t: +(foot.getBoundingClientRect().top - dev.top).toFixed(1) } : null,
    /* la barra ES el sujeto de la ronda: se hit-testea, no se asume. `#vnav` es `fixed` y en la
       primera versión pisaba sus primeros 2,8px — lo encontró la captura, no los 23 checks.
       Y `elementFromPoint` sobre un `<svg>` devuelve un `SVGAnimatedString` por `className`, que
       serializa a `{}` y se lee como "no hay nada ahí": se sube al `<button>` antes de nombrarlo. */
    vnavB: +document.querySelector('#vnav').getBoundingClientRect().bottom.toFixed(2),
    scrollY: window.scrollY,
    hit: (() => { const at = (x, y) => { const e = document.elementFromPoint(x, y); if (!e) return null;
        const b = e.closest('button'); return b ? (b.id || b.className) : ('no-boton:' + e.tagName); };
      const bk = document.querySelector('.tb-back').getBoundingClientRect();
      const kb = document.querySelector('#kebab').getBoundingClientRect();
      return { back: at(bk.left + bk.width / 2, bk.top + bk.height / 2),
               kebab: at(kb.left + kb.width / 2, kb.top + kb.height / 2) }; })(),
    dialog: document.querySelector('#dscrim') && document.querySelector('#dscrim').classList.contains('open'),
    dlgTitle: (document.querySelector('#dlg-t') || {}).textContent || null,
  };
};
const setMode = m => document.querySelector(`#vnav [data-var="${m}"]`).click();
const hideTools = () => { document.querySelector('#tools').style.display = 'none'; };
const soil = () => {                       /* cambia `Es una expansión` desde su hoja */
  document.querySelector('[data-edit="exp"]').click();
};
const pickOther = () => { const o = [...document.querySelectorAll('.sheet .opt')];
  const cur = o.find(x => x.querySelector('svg')); (o.find(x => x !== cur) || o[0]).click(); };

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN || '/usr/bin/google-chrome', args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 375, height: 667 + VN }, deviceScaleFactor: 2 });
  await page.goto(URL, { waitUntil: 'networkidle' });
  const go = async (m) => { await page.reload({ waitUntil: 'networkidle' });
    await page.evaluate(setMode, m); await page.evaluate(hideTools); await page.waitForTimeout(80); };
  const dirty = async () => { await page.evaluate(soil); await page.waitForTimeout(160);
    await page.evaluate(pickOther); await page.waitForTimeout(200); };

  const M = {};
  for (const m of ['HOY', 'A', 'B']) {
    await go(m); const clean = await page.evaluate(probe);
    await dirty(); const d = await page.evaluate(probe);
    M[m] = { clean, d };
    await page.screenshot({ path: path.join(OUT, `${m}-sucio.png`) });
  }

  if (process.env.DBG) for (const m of ['HOY','A','B'])
    console.error('DBG', m, 'vnavB', M[m].clean.vnavB, 'scrollY', M[m].clean.scrollY, 'hit', JSON.stringify(M[m].clean.hit), 'tbar', JSON.stringify(M[m].clean.tbar));
  /* ---- 1-3 · el presupuesto vertical, la pregunta de la ronda ---- */
  ok(M.HOY.clean.chrome === 94.5, `1 HOY chrome 94,5 (medido ${M.HOY.clean.chrome})`);
  ok(M.A.clean.chrome === 171.5, `2 A chrome 171,5 = tbar 56 + franja 38,5 + banda 77 (medido ${M.A.clean.chrome})`);
  ok(M.B.clean.chrome === 158.5, `3 B chrome 158,5 = tbar 56 + banda unida 102,5 (medido ${M.B.clean.chrome})`);
  /* EL HALLAZGO QUE CONTRADICE LA PREMISA DEL DIBUJO: yo predije que unir las bandas ahorraba ~70px.
     Ahorra 13. El CTA de 52px existe en las dos y domina; la costura vale 13px = 2% de 667. */
  ok(M.A.clean.chrome - M.B.clean.chrome === 13, `4 unir las bandas ahorra 13px, no los ~70 predichos (${(M.A.clean.chrome - M.B.clean.chrome)})`);

  /* ---- 5-6 · el chrome NO cambia al ensuciar (la franja no crece ni se encoge) ---- */
  ok(M.A.clean.chrome === M.A.d.chrome, `5 A: el chrome no se mueve al ensuciar (${M.A.clean.chrome} → ${M.A.d.chrome})`);
  ok(M.B.clean.chrome === M.B.d.chrome, `6 B: el chrome no se mueve al ensuciar (${M.B.clean.chrome} → ${M.B.d.chrome})`);

  /* ---- 7-10 · `Guardar`: existe arriba, deshabilitado limpio, habilitado sucio, y el pie se fue ---- */
  ok(M.A.clean.cta && M.A.clean.cta.dis === true && M.B.clean.cta.dis === true, '7 limpio: `Guardar` deshabilitado en A y B');
  ok(M.A.d.cta.dis === false && M.B.d.cta.dis === false, '8 sucio: `Guardar` habilitado en A y B');
  ok(M.A.clean.foot === null && M.B.clean.foot === null, '9 A y B no dejan un segundo `Guardar` al pie');
  ok(M.HOY.clean.foot && M.HOY.clean.foot.t > 1400 && !M.HOY.clean.cta,
     `10 HOY es la 079 textual: sin CTA arriba y el del pie a y=${M.HOY.clean.foot && M.HOY.clean.foot.t}`);

  /* ---- 11 · HOY no tiene estado sucio: la hoja escribe y no queda nada que guardar ---- */
  ok(M.HOY.d.foot !== null && M.HOY.d.cta === null, '11 HOY sigue sin estado sucio después de editar');

  /* ---- 12-13 · la frase de la franja: "Así se ve en la web" es FALSA mientras hay cambios ---- */
  ok(/Así se ve en la web/.test(M.A.clean.txt), '12 limpio: la franja dice «Así se ve en la web.»');
  ok(/todavía no están en la web/.test(M.A.d.txt) && /todavía no están en la web/.test(M.B.d.txt),
     '13 sucio: la franja deja de afirmar lo que la web muestra');

  /* ---- 14 · el tinte pendiente PINTA de verdad (`color-mix` sobre `--warn`, que es local) ---- */
  ok(M.A.clean.stbg !== M.A.d.stbg, `14 el tinte pendiente cambia el fondo de la franja (${M.A.clean.stbg} → ${M.A.d.stbg})`);

  /* ---- 15 · EL PUNTO. Cuarta vez en el linaje. Se lee rect + color resuelto, nunca el nodo. ---- */
  ok(M.A.d.dot && M.A.d.dot.w === 8 && M.A.d.dot.h === 8 && !/rgba\(0, 0, 0, 0\)/.test(M.A.d.dot.c),
     `15 el punto mide 8×8 y tiene color resuelto (${JSON.stringify(M.A.d.dot)})`);

  /* ---- 16 · COSTO DE B, encontrado midiendo: el `Guardar` deshabilitado es del MISMO color que la
         banda que lo contiene. En A la banda es `--color-bg` y sí contrasta. ---- */
  const bSame = M.B.clean.cta.bg === M.B.clean.cta.hostBg;
  const aSame = M.A.clean.cta.bg === M.A.clean.cta.hostBg;
  ok(bSame && !aSame,
     `16 B: el CTA deshabilitado es el mismo relleno que su banda (${M.B.clean.cta.bg}); en A contrasta (${M.A.clean.cta.bg} sobre ${M.A.clean.cta.hostBg})`);

  /* ---- 17 · el CTA conserva los 52px de la 078 en las dos ---- */
  ok(M.A.clean.cta.h === 52 && M.B.clean.cta.h === 52, `17 el CTA mide 52px en A y B`);

  /* ---- 18-19 · el confirmar-al-salir vuelve con el estado sucio, y NO aparece si está limpio ---- */
  await go('A');
  await page.evaluate(() => document.querySelector('.tb-back').click()); await page.waitForTimeout(150);
  const backClean = await page.evaluate(probe);
  ok(backClean.dialog === false, '18 limpio: volver no pregunta nada');
  await go('A'); await dirty();
  await page.evaluate(() => document.querySelector('.tb-back').click()); await page.waitForTimeout(150);
  const backDirty = await page.evaluate(probe);
  ok(backDirty.dialog === true && /Salir sin guardar/.test(backDirty.dlgTitle || ''),
     `19 sucio: volver confirma en el diálogo de D-19f («${backDirty.dlgTitle}»)`);

  /* ---- 20 · guardar limpia: el CTA se apaga y la frase vuelve ---- */
  await page.evaluate(() => document.querySelector('[data-act="dlg-no"]').click()); await page.waitForTimeout(120);
  await page.evaluate(() => document.querySelector('.sbar .cta').click()); await page.waitForTimeout(200);
  const saved = await page.evaluate(probe);
  ok(saved.cta.dis === true && /Así se ve en la web/.test(saved.txt),
     '20 al guardar: el CTA se deshabilita y la franja vuelve a afirmar la web');

  /* ---- 21 · el chrome del sketch no puede tapar la barra que la ronda está decidiendo ---- */
  const barLibre = m => M[m].clean.scrollY === 0 && M[m].clean.hit.back === 'tb-back' && M[m].clean.hit.kebab === 'kebab';
  ok(barLibre('HOY') && barLibre('A') && barLibre('B'),
     `21 en los TRES modos la página no se desplaza y los dos controles de la barra se hit-testean `
     + `(scrollY ${['HOY','A','B'].map(m => m + ':' + M[m].clean.scrollY).join(' ')})`);

  /* ---- 22-23 · los tres anchos, y el peor caso de alto ---- */
  for (const [w, h] of [[360, 640], [375, 800]]) {
    const p2 = await browser.newPage({ viewport: { width: w, height: h + VN }, deviceScaleFactor: 1 });
    await p2.goto(URL, { waitUntil: 'networkidle' });
    await p2.evaluate(setMode, 'A'); await p2.evaluate(hideTools);
    await p2.evaluate(() => document.querySelector('#tools [data-cy="retired"]').click()); await p2.waitForTimeout(120);
    const r = await p2.evaluate(probe);
    ok(r.chrome === 171.5, `2${w === 360 ? 2 : 3} ${w}×${h} retirado: A sigue en 171,5 de chrome (${r.chrome})`);
    await p2.close();
  }

  /* ---- 23 · oscuro: el tinte pendiente sigue distinguiéndose ---- */
  const p3 = await browser.newPage({ viewport: { width: 375, height: 667 + VN }, deviceScaleFactor: 1 });
  await p3.goto(URL, { waitUntil: 'networkidle' });
  await p3.evaluate(() => document.querySelector('[data-theme-set="dark"]').click());
  await p3.evaluate(setMode, 'A'); await p3.evaluate(hideTools);
  const dc = await p3.evaluate(probe);
  await p3.evaluate(soil); await p3.waitForTimeout(160); await p3.evaluate(pickOther); await p3.waitForTimeout(200);
  const dd = await p3.evaluate(probe);
  await p3.screenshot({ path: path.join(OUT, 'A-oscuro-sucio.png') });
  ok(dc.stbg !== dd.stbg, `24 oscuro: el tinte pendiente también cambia el fondo (${dc.stbg} → ${dd.stbg})`);
  await p3.close();

  await browser.close();
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(log.join('\n'));
  console.log(`\n${pass}/${log.length}   capturas en ${OUT}`);
  process.exit(pass === log.length ? 0 : 1);
})();
