/* Checks de Chrome headless para el sketch 080 — el `Guardar` del pie, FIJO.
     python3 -m http.server 8765 &
     node .planning/sketches/080-admin-guardar-fijo/verify.js
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

/* decodificador PNG mínimo, traído de la 079: la r4 necesita un NÚMERO de tinta, no un booleano.
   Comparar bytes de PNG no sirve — la compresión reescribe el stream con un corrimiento de 1px. */
const zlib = require('zlib');
function decodePNG(buf) {
  let p = 8, w = 0, h = 0, ct = 0, bd = 0; const idat = [];
  while (p < buf.length) {
    const len = buf.readUInt32BE(p), type = buf.toString('ascii', p + 4, p + 8);
    if (type === 'IHDR') { w = buf.readUInt32BE(p + 8); h = buf.readUInt32BE(p + 12); bd = buf[p + 16]; ct = buf[p + 17]; }
    else if (type === 'IDAT') idat.push(buf.subarray(p + 8, p + 8 + len));
    else if (type === 'IEND') break;
    p += 12 + len;
  }
  if (bd !== 8 || (ct !== 2 && ct !== 6)) throw new Error(`PNG no soportado: bd=${bd} ct=${ct}`);
  const bpp = ct === 6 ? 4 : 3, raw = zlib.inflateSync(Buffer.concat(idat)), stride = w * bpp;
  const out = Buffer.alloc(h * stride);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)], line = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
    for (let x = 0; x < stride; x++) {
      const a = x >= bpp ? out[y * stride + x - bpp] : 0;
      const b = y > 0 ? out[(y - 1) * stride + x] : 0;
      const c = x >= bpp && y > 0 ? out[(y - 1) * stride + x - bpp] : 0;
      let v = line[x];
      if (f === 1) v += a; else if (f === 2) v += b; else if (f === 3) v += (a + b) >> 1;
      else if (f === 4) { const pa = Math.abs(b - c), pb = Math.abs(a - c), pc = Math.abs(a + b - 2 * c);
        v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c); }
      out[y * stride + x] = v & 255;
    }
  }
  return { w, h, bpp, data: out };
}

const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/080-admin-guardar-fijo/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-080-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);
/* el `#vnav` del sketch ocupa 44px de flujo (dos botones, un renglon) y el device es `100vh - 44`: la ventana se pide 44px más
   alta para que «375×667» sea un device de 667 REALES, no de 623. */
const VN = 44;

const lum = c => { const [r, g, b] = c.match(/[\d.]+/g).slice(0, 3).map(Number)
  .map(v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
const ratio = (a, b) => { const l1 = lum(a), l2 = lum(b);
  return +(((Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05))).toFixed(2); };

const probe = () => {
  const devEl = document.querySelector('.device'), dev = devEl.getBoundingClientRect();
  const rel = r => ({ t: +(r.top - dev.top).toFixed(1), b: +(r.bottom - dev.top).toFixed(1), h: +r.height.toFixed(1) });
  const g = s => { const e = document.querySelector(s); return (e && e.offsetParent) ? rel(e.getBoundingClientRect()) : null; };
  const st = document.querySelector('.note'), dot = document.querySelector('.note .dot');
  const barCta = document.querySelector('#ctabar .cta');
  const flowCta = [...document.querySelectorAll('#main .cta')].find(e => e.offsetParent);
  /* el hit-test se hace sobre el `<button>`, no sobre lo que devuelva `elementFromPoint`:
     un `<svg>` reporta `className` como `SVGAnimatedString`, que serializa a `{}` y se lee
     como «no hay nada ahí». */
  const at = (x, y) => { const e = document.elementFromPoint(x, y); if (!e) return null;
    const b = e.closest('button'); return b ? (b.id || (typeof b.className === 'string' ? b.className : '?')) : ('no-boton:' + e.tagName); };
  const bk = document.querySelector('.tb-back').getBoundingClientRect();
  const kb = document.querySelector('#kebab').getBoundingClientRect();
  const bc = barCta ? barCta.getBoundingClientRect() : null;
  /* ¿el último bloque del cuerpo queda TAPADO por la barra? se mide contra el borde superior de la
     barra y se hit-testea, no se confía en el `padding-bottom`. */
  const sc = document.querySelector('#scroller');
  const last = [...document.querySelectorAll('#main .spec')].pop();
  const lr = last ? last.getBoundingClientRect() : null;
  const barTop = document.querySelector('#ctabar') && !document.querySelector('#ctabar').hidden
    ? document.querySelector('#ctabar').getBoundingClientRect().top : null;
  return {
    mode: document.querySelector('#vnav .on') ? document.querySelector('#vnav .on').dataset.var : null,
    scrollY: window.scrollY, scTop: +sc.scrollTop.toFixed(0),
    scMax: +(sc.scrollHeight - sc.clientHeight).toFixed(0),
    devH: +dev.height.toFixed(1),
    tbar: g('.tbar'), stbar: g('.stbar'), bar: g('#ctabar'),
    barStyle: (() => { const bar = document.querySelector('#ctabar'); if (!bar || bar.hidden) return null;
      const cs = getComputedStyle(bar), bs = barCta ? getComputedStyle(barCta) : null;
      return { barH: +bar.getBoundingClientRect().height.toFixed(1), barBg: cs.backgroundColor,
        btnH: barCta ? +barCta.getBoundingClientRect().height.toFixed(1) : null,
        radius: bs && bs.borderRadius, font: bs && (bs.fontSize + '/' + bs.fontWeight),
        /* la quilla se mide del borde DERECHO: con el botón a su ancho natural y alineado a la
           derecha, su borde izquierdo no es una quilla sino el largo de la palabra. */
        gut: barCta ? +(bar.getBoundingClientRect().right - barCta.getBoundingClientRect().right).toFixed(1) : null,
        disBg: bs && bs.backgroundColor }; })(),
    barCta: bc ? { txt: barCta.textContent.trim(), dis: barCta.disabled, h: +bc.height.toFixed(1),
      relT: +(bc.top - dev.top).toFixed(1), inView: bc.top >= dev.top && bc.bottom <= dev.bottom + 0.5,
      centre: at(bc.left + bc.width / 2, bc.top + bc.height / 2) } : null,
    flowCta: flowCta ? { relT: +(flowCta.getBoundingClientRect().top - dev.top).toFixed(1) } : null,
    lastClear: (lr && barTop !== null) ? +(barTop - lr.bottom).toFixed(1) : null,
    txt: st ? st.innerText.replace(/\s+/g, ' ').trim() : null,
    stbg: st ? getComputedStyle(st).backgroundColor : null,
    /* la nota ya NO es chrome fijo: vive dentro del scroller y se va con el cuerpo. */
    noteFixed: st ? (st.closest('#scroller') === null) : null,
    noteBleed: st ? +(st.getBoundingClientRect().width).toFixed(1) : null,
    noteDotCls: dot ? dot.className : null,
    /* ningún elemento EN PANTALLA puede usar el `--warn` inventado: la paleta no tiene parada de
       advertencia y ese era el `TODO(palette)` que la 075 dejó debiendo. */
    warnOnScreen: [...document.querySelectorAll('.note, .note *, #ctabar, #ctabar *')]
      .filter(e => /warn/.test(typeof e.className === 'string' ? e.className : '')).length,
    dot: dot ? { w: +dot.getBoundingClientRect().width.toFixed(1), c: getComputedStyle(dot).backgroundColor } : null,
    hit: { back: at(bk.left + bk.width / 2, bk.top + bk.height / 2), kebab: at(kb.left + kb.width / 2, kb.top + kb.height / 2) },
    /* la clase es `show`, no `on` — leer la equivocada devolvía `null` y el check se leía como
       «no hay snack» en vez de «no lo estoy midiendo». */
    snack: (() => { const sn = document.querySelector('#snack'); if (!sn || !sn.classList.contains('show')) return null;
      const r = sn.getBoundingClientRect(); return { t: +(r.top - dev.top).toFixed(1), b: +(r.bottom - dev.top).toFixed(1) }; })(),
    dialog: document.querySelector('#dscrim').classList.contains('open'),
    dlgTitle: (document.querySelector('#dlg-t') || {}).textContent || null,
  };
};
const setMode = m => document.querySelector(`#vnav [data-var="${m}"]`).click();
const hideTools = () => { document.querySelector('#tools').style.display = 'none'; };
const soil = () => document.querySelector('[data-edit="exp"]').click();
const pickOther = () => { const o = [...document.querySelectorAll('.sheet .opt')];
  const cur = o.find(x => x.querySelector('svg')); (o.find(x => x !== cur) || o[0]).click(); };

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN || '/usr/bin/google-chrome', args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 375, height: 667 + VN }, deviceScaleFactor: 2 });
  await page.goto(URL, { waitUntil: 'networkidle' });
  const go = async m => { await page.reload({ waitUntil: 'networkidle' });
    await page.evaluate(setMode, m); await page.evaluate(hideTools); await page.waitForTimeout(90); };
  const dirty = async () => { await page.evaluate(soil); await page.waitForTimeout(160);
    await page.evaluate(pickOther); await page.waitForTimeout(220); };
  const M = {};
  for (const m of ['HOY', 'FIJA']) {
    await go(m); M[m] = { clean: await page.evaluate(probe) };
    await dirty(); M[m].d = await page.evaluate(probe);
    await page.screenshot({ path: path.join(OUT, `${m}-sucio.png`) });
  }

  /* ---- 1-2 · EL NÚMERO DE LA RONDA: alcanzable o no, en reposo, sin scrollear ---- */
  ok(M.HOY.clean.flowCta && M.HOY.clean.flowCta.relT > 1400 && !M.HOY.clean.barCta,
     `1 HOY (079): el único \`Guardar\` está en el flujo, a y=${M.HOY.clean.flowCta && M.HOY.clean.flowCta.relT} — fuera de una pantalla de ${M.HOY.clean.devH}`);
  ok(M.FIJA.clean.barCta && M.FIJA.clean.barCta.inView && M.FIJA.clean.flowCta === null,
     `2 FIJA: el \`Guardar\` está en pantalla en reposo (y=${M.FIJA.clean.barCta.relT} de ${M.FIJA.clean.devH}) y NO quedó un segundo en el flujo`);

  /* ---- 3 · y sigue en pantalla con el cuerpo scrolleado hasta el fondo ---- */
  await go('FIJA');
  await page.evaluate(() => { const s = document.querySelector('#scroller'); s.scrollTop = s.scrollHeight; });
  await page.waitForTimeout(150);
  const bottom = await page.evaluate(probe);
  ok(bottom.barCta && bottom.barCta.inView && bottom.scTop > 500,
     `3 con el cuerpo al fondo (scrollTop ${bottom.scTop}) el \`Guardar\` sigue en y=${bottom.barCta.relT}`);

  /* ---- 4 · y NO tapa el último bloque: el hueco se reservó de verdad ---- */
  ok(bottom.lastClear !== null && bottom.lastClear > 0,
     `4 el último bloque del cuerpo queda ${bottom.lastClear}px por encima de la barra (no tapado)`);

  /* ---- 5-6 · habilitado sólo si hay algo que guardar ---- */
  ok(M.FIJA.clean.barCta.dis === true, '5 limpio: `Guardar` deshabilitado');
  ok(M.FIJA.d.barCta.dis === false, '6 con cambios: `Guardar` habilitado');

  /* ---- 7 · el botón se puede tocar de verdad (hit-test en su centro) ---- */
  /* la clase dejó de ser sólo `cta` al abrirse los ejes de la r3 (`cta nat out`): la aserción
     miraba una igualdad exacta y fallaba por el nombre, no por el hit. */
  ok(/\bcta\b/.test(M.FIJA.d.barCta.centre || ''), `7 el centro del botón da el botón (${M.FIJA.d.barCta.centre})`);

  /* ---- 8 · HOY sigue sin estado sucio: la hoja escribe, la 079 textual ---- */
  ok(M.HOY.d.flowCta !== null && M.HOY.d.barCta === null, '8 HOY sigue sin estado sucio después de editar');

  /* ---- 9-10 · la franja deja de afirmar lo que la web muestra ---- */
  ok(/Así se ve en la web/.test(M.FIJA.clean.txt), '9 limpio: «Así se ve en la web.»');
  /* la nota YA NO se tiñe: la r4 sacó el tinte `--warn` inventado y el estado queda en el PUNTO,
     que es lo que D-19h manda (punto + texto, nunca una cápsula). */
  ok(/todavía no están en la web/.test(M.FIJA.d.txt)
     && M.FIJA.clean.noteDotCls !== M.FIJA.d.noteDotCls && M.FIJA.clean.stbg === M.FIJA.d.stbg,
     `10 con cambios: la nota se corrige y cambia su PUNTO (${M.FIJA.clean.noteDotCls} → ${M.FIJA.d.noteDotCls}), sin teñir el fondo (${M.FIJA.d.stbg})`);

  /* ---- 11 · EL PUNTO. Cuarta vez en el linaje: rect + color resuelto, nunca el nodo. ---- */
  ok(M.FIJA.d.dot && M.FIJA.d.dot.w === 8 && !/rgba\(0, 0, 0, 0\)/.test(M.FIJA.d.dot.c),
     `11 el punto mide 8px y tiene color resuelto (${JSON.stringify(M.FIJA.d.dot)})`);

  /* ---- 12 · el chrome del sketch no tapa la barra de arriba, y la página no se desplaza ---- */
  ok(M.FIJA.clean.scrollY === 0 && M.FIJA.clean.hit.back === 'tb-back' && M.FIJA.clean.hit.kebab === 'kebab',
     `12 la página no se desplaza y los dos controles de \`.tbar\` se hit-testean (${JSON.stringify(M.FIJA.clean.hit)})`);

  /* ---- 13-14 · volver con cambios confirma; limpio no pregunta ---- */
  await go('FIJA');
  await page.evaluate(() => document.querySelector('.tb-back').click()); await page.waitForTimeout(150);
  ok((await page.evaluate(probe)).dialog === false, '13 limpio: volver no pregunta nada');
  await go('FIJA'); await dirty();
  await page.evaluate(() => document.querySelector('.tb-back').click()); await page.waitForTimeout(150);
  const bd = await page.evaluate(probe);
  ok(bd.dialog && /Salir sin guardar/.test(bd.dlgTitle || ''), `14 con cambios: confirma en el diálogo de D-19f («${bd.dlgTitle}»)`);

  /* ---- 15-16 · guardar apaga el botón y devuelve la frase; y el snack NO queda debajo de la barra ---- */
  await page.evaluate(() => document.querySelector('[data-act="dlg-no"]').click()); await page.waitForTimeout(120);
  await page.evaluate(() => document.querySelector('#ctabar .cta').click()); await page.waitForTimeout(160);
  const saved = await page.evaluate(probe);
  ok(saved.barCta.dis === true && /Así se ve en la web/.test(saved.txt),
     '15 al guardar: el botón se apaga y la nota vuelve a afirmar la web');
  /* la 079 r1 ya había encontrado que «el snack entierra la zona de M2». Con una barra fija al pie,
     el snack y la barra pelean por el mismo borde: se mide, no se supone. */
  const gap = (saved.snack && saved.bar) ? +(saved.bar.t - saved.snack.b).toFixed(1) : null;
  ok(saved.snack !== null && saved.bar !== null && gap >= 0,
     `16 el snackbar queda por encima de la barra, con ${gap}px de aire (snack ${saved.snack && saved.snack.t}–${saved.snack && saved.snack.b} · barra desde ${saved.bar && saved.bar.t})`);

  /* ================= la barra decidida (r2-r5) =================
     Las variantes se borraron al elegirse, que es lo que este linaje hace. Los números que las
     descartaron viven en el README; acá quedan las aserciones sobre lo que SÍ se eligió, más los
     negativos que impiden que vuelva sola cualquiera de las tres formas descartadas.

     Las referencias NO son de este sketch: se midieron EN VIVO contra la app corriendo
     (`localhost:4000/juegos/10` a 375), sobre `.pk-mobile-cta-bar` — la barra fija de la misma ficha
     que E3 dice que el editor espeja. Y la anatomía A1 sale de la tabla contexto × rol de `064`,
     que para `save bar .eactions` dice Principal = **A1, last**. */
  const bs = M.FIJA.clean.barStyle;
  ok(bs.btnH === 44 && bs.font === '14px/600' && bs.gut === 14,
     `20 el botón toma el tamaño del de la web: ${bs.btnH}px · ${bs.font} · quilla ${bs.gut}`);

  const btn = await page.evaluate(() => { const b = document.querySelector('#ctabar .cta'),
      bar = document.querySelector('#ctabar');
    const cs = getComputedStyle(b), bc = getComputedStyle(bar), dev = getComputedStyle(document.querySelector('.device'));
    const r = b.getBoundingClientRect(), br = bar.getBoundingClientRect();
    const rg = document.createRange(); rg.selectNodeContents(b);
    return { w: +r.width.toFixed(1), h: +r.height.toFixed(1), ink: +rg.getBoundingClientRect().width.toFixed(1),
      padL: cs.paddingLeft, bw: cs.borderTopWidth, radius: cs.borderRadius, font: cs.fontSize + '/' + cs.fontWeight,
      fill: cs.backgroundColor, right: +(br.right - r.right).toFixed(1),
      barBg: bc.backgroundColor, pageBg: dev.backgroundColor, barBt: bc.borderTopWidth, barH: +br.height.toFixed(1) }; });

  /* A1 de 064, al píxel — y el negativo de «relleno»: su fondo es el de la página, no un macizo. */
  ok(btn.h === 44 && btn.padL === '16px' && btn.bw === '1px' && btn.radius === '8px' && btn.font === '14px/600',
     `21 el botón es A1 de 064: ${btn.h}px · padding ${btn.padL} · trazo ${btn.bw} · radio ${btn.radius} · ${btn.font}`);
  ok(btn.fill === btn.pageBg, `22 no volvió el relleno de la 078: el botón es contorno sobre el fondo (${btn.fill})`);

  /* el negativo de «a lo ancho»: la tinta tiene que seguir llenando el botón. A lo ancho daba 15,8%
     porque la caja era de 347 para una palabra de 54,7 — una forma dimensionada para la etiqueta de
     la web («Reservar para el sábado», 47,1%), no para «Guardar». */
  const pct = +(btn.ink / btn.w * 100).toFixed(1);
  ok(pct > 55 && btn.w < 160, `23 el botón va a su ancho natural: ${btn.w}px, tinta ${pct}% (a lo ancho daba 15,8%)`);
  ok(btn.right === 14, `24 termina en la quilla de 14 (${btn.right})`);

  /* el negativo de «banda tonal» y de «sin banda»: la barra es opaca Y del color de la página. */
  ok(btn.barBg === btn.pageBg && btn.barBt === '1px',
     `25 la barra es un DIVISOR: toma el fondo de la página (${btn.barBg}) y sólo dibuja su línea (${btn.barBt})`);

  /* y que sea opaca se prueba midiendo: 0 píxeles del cuerpo dentro de la franja del botón, con el
     cuerpo scrolleado. Sin banda dejaba 1456px; la vela, 255. */
  await go('FIJA'); await dirty();
  await page.evaluate(() => { document.querySelector('#scroller').scrollTop = 700; });
  await page.waitForTimeout(160);
  const box = await page.evaluate(() => { const dev = document.querySelector('.device').getBoundingClientRect();
    const bar = document.querySelector('#ctabar').getBoundingClientRect(), b = document.querySelector('#ctabar .cta').getBoundingClientRect();
    return { x: Math.round(dev.x), y: Math.round(bar.y), w: Math.round(dev.width), h: Math.round(bar.height),
      bx: Math.round(b.x - dev.x), bw: Math.round(b.width) }; });
  const png = await page.screenshot({ clip: { x: box.x, y: box.y + 2, width: box.w, height: box.h - 2 } });
  const img = decodePNG(png); let ink = 0;
  /* el arnés corre a `deviceScaleFactor: 2`: la imagen viene al DOBLE de los px CSS con los que se
     midió la caja del botón. Sin escalar, la ventana de exclusión cae mal y el propio botón se
     cuenta como tinta del cuerpo — reportaba 3569 contra los ~1456 reales. La escala se deriva. */
  const k = img.w / box.w;
  for (let y = 0; y < img.h; y++) for (let x = 0; x < img.w; x++) {
    if (x >= (box.bx - 6) * k && x <= (box.bx + box.bw + 6) * k) continue;
    const i = y * img.w * img.bpp + x * img.bpp;
    if (Math.max(Math.abs(img.data[i] - 255), Math.abs(img.data[i + 1] - 255), Math.abs(img.data[i + 2] - 255)) > 28) ink++; }
  ok(ink === 0, `26 el divisor es opaco: ${ink}px del cuerpo dentro de la franja del botón (sin banda dejaba 1456, la vela 255)`);

  /* ---- la nota (r4): dentro del cuerpo, sin sangre, y sin colores inventados ---- */
  const N = M.FIJA.clean;
  ok(N.noteFixed === false, '30 la nota vive dentro del scroller: se va con el cuerpo, no es chrome fijo');
  ok(N.noteBleed < 375 - 20, `31 la nota no va a sangre: mide ${N.noteBleed} en un device de 375`);
  ok(N.warnOnScreen === 0, `32 nada en pantalla usa el \`--warn\` inventado: la paleta no tiene parada de advertencia (${N.warnOnScreen})`);

  /* ---- 17-18 · los otros anchos ---- */
  for (const [w, h] of [[360, 640], [375, 800]]) {
    const p2 = await browser.newPage({ viewport: { width: w, height: h + VN }, deviceScaleFactor: 1 });
    await p2.goto(URL, { waitUntil: 'networkidle' });
    await p2.evaluate(setMode, 'FIJA'); await p2.evaluate(hideTools);
    await p2.evaluate(() => { const s = document.querySelector('#scroller'); s.scrollTop = s.scrollHeight; });
    await p2.waitForTimeout(150);
    const r = await p2.evaluate(probe);
    ok(r.barCta.inView && r.lastClear > 0,
       `${w === 360 ? 27 : 28} ${w}×${h}: el botón en pantalla (y=${r.barCta.relT}) y el último bloque ${r.lastClear}px libre`);
    await p2.close();
  }

  /* ---- 19 · oscuro ---- */
  const p3 = await browser.newPage({ viewport: { width: 375, height: 667 + VN }, deviceScaleFactor: 1 });
  await p3.goto(URL, { waitUntil: 'networkidle' });
  await p3.evaluate(() => document.querySelector('[data-theme-set="dark"]').click());
  await p3.evaluate(setMode, 'FIJA'); await p3.evaluate(hideTools);
  const dc = await p3.evaluate(probe);
  await p3.evaluate(soil); await p3.waitForTimeout(160); await p3.evaluate(pickOther); await p3.waitForTimeout(220);
  const dd = await p3.evaluate(probe);
  await p3.screenshot({ path: path.join(OUT, 'FIJA-oscuro-sucio.png') });
  ok(dc.barCta.dis === true && dd.barCta.dis === false && dc.noteDotCls !== dd.noteDotCls,
     `29 oscuro: el botón enciende y el punto de la nota cambia (${dc.noteDotCls} → ${dd.noteDotCls})`);
  await p3.close();

  await browser.close();
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(log.join('\n'));
  console.log(`\n${pass}/${log.length}   capturas en ${OUT}`);
  process.exit(pass === log.length ? 0 : 1);
})();
