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

  /* ---- r2 (DECIDIDA): la barra toma el tamaño de la barra fija REAL de la web, medida EN VIVO
         contra `localhost:4000/juegos/10` a 375 — la misma ficha que E3 dice que el editor espeja:
         barra 69px tonal · botón 44 · 14/600 · quilla 14 · reserva 148px en el body. ---- */
  const WEBREF = { barH: 69, btnH: 44, font: '14px/600', gut: 14, barBg: 'rgb(241, 236, 253)' };
  const B = M.FIJA.clean.barStyle;
  /* el TAMAÑO es independiente del chrome, así que se asierta sobre el modo por defecto... */
  ok(B.btnH === WEBREF.btnH && B.font === WEBREF.font && B.gut === WEBREF.gut,
     `20 el botón toma el tamaño del de la web: ${B.btnH}px · ${B.font} · quilla ${B.gut}`);
  /* ...y el fondo tonal sólo existe en `band`, así que se mide AHÍ y no en el modo por defecto,
     que desde la r4 es `veil` y no tiene fondo. Medir el default habría reportado un contraste
     contra `rgba(0,0,0,0)`, que no es un contraste contra nada. */
  await go('FIJA');
  await page.evaluate(() => { CHROME = 'band'; render(); }); await page.waitForTimeout(90);
  const bandS = (await page.evaluate(probe)).barStyle;
  ok(bandS.barH === WEBREF.barH && bandS.barBg === WEBREF.barBg && ratio(bandS.disBg, bandS.barBg) > 1.1,
     `21 en \`banda\` reproduce la de la web (${bandS.barH}px · ${bandS.barBg}) y el apagado se distingue (${ratio(bandS.disBg, bandS.barBg)}:1; con el relleno de la web daba 1:1)`);

  /* ================= r3 · ¿tiene que ocupar todo el ancho? =================
     DOS ejes independientes, barridos como 2×2 y no como cuatro pestañas: si fueran pestañas no se
     podría ver cuál de los dos está haciendo el trabajo. */
  const sweep = async (w, t, d) => { await go('FIJA'); if (d) await dirty();
    await page.evaluate(([w, t]) => { WIDTH = w; TREAT = t; render(); }, [w, t]);
    await page.waitForTimeout(90);
    return page.evaluate(() => { const bar = document.querySelector('#ctabar'), btn = bar.querySelector('.cta');
      const bt = btn.getBoundingClientRect(), rg = document.createRange(); rg.selectNodeContents(btn);
      const cs = getComputedStyle(btn), bs = getComputedStyle(bar);
      return { w: +bt.width.toFixed(1), h: +bt.height.toFixed(1), ink: +rg.getBoundingClientRect().width.toFixed(1),
        radius: cs.borderRadius, bw: cs.borderTopWidth, bc: cs.borderTopColor, bg: cs.backgroundColor,
        fg: cs.color, padL: cs.paddingLeft, font: cs.fontSize + '/' + cs.fontWeight,
        right: +(375 - bt.right).toFixed(1), barBg: bs.backgroundColor, dis: btn.disabled }; }); };

  const FF = await sweep('full', 'fill', false), NO = await sweep('nat', 'out', false);
  const NOd = await sweep('nat', 'out', true), FFd = await sweep('full', 'fill', true);
  const pct = x => +(x.ink / x.w * 100).toFixed(1);

  /* EL NÚMERO DE LA RONDA. La barra de la web da 47,1% de tinta porque su etiqueta es «Reservar para
     el sábado» (163,5 de 347). La nuestra dice «Guardar»: 54,7. Copiar el ANCHO copió una caja
     dimensionada para 23 caracteres sobre una de 7. */
  ok(pct(FF) < 20 && pct(NO) > 55,
     `22 tinta: a lo ancho ${pct(FF)}% · natural ${pct(NO)}% (la web real, con su etiqueta larga, da 47,1%)`);

  /* `064` ya contesta este contenedor: save bar `.eactions` → Principal = **A1, last**; y en su tabla
     un Principal a lo ancho es **never**. A1 = outlined 44 · 16px de padding · 1px · radio 8 · 14/600. */
  ok(NO.h === 44 && NO.padL === '16px' && NO.bw === '1px' && NO.radius === '8px' && NO.font === '14px/600',
     `23 natural+contorno reproduce A1 de 064: ${NO.h}px · padding ${NO.padL} · trazo ${NO.bw} · radio ${NO.radius} · ${NO.font}`);
  ok(NO.right === 14 && NO.w >= 44,
     `24 termina en la quilla (${NO.right}) y sigue por encima del piso de 44px (${NO.w}×${NO.h})`);
  ok(NO.bc !== NOd.bc && ratio(NOd.fg, NOd.bg) > 4.5,
     `25 contorno: el trazo cambia al habilitarse (${NO.bc} → ${NOd.bc}) y el texto da ${ratio(NOd.fg, NOd.bg)}:1`);
  ok(ratio(FFd.fg, FFd.bg) > 4.5, `26 relleno habilitado: texto ${ratio(FFd.fg, FFd.bg)}:1`);


  /* ================= r4 · la nota, y cuánto contenedor lleva el botón =================
     Desarrollador: *"the «status» label shouldn't be full width and fixed. Just a top «note» about
     the status and that is all, following the same colors that the rest of the app"* y *"that bottom
     bar for save feels balance breaker"*. */
  const N = M.FIJA.clean;
  ok(N.noteFixed === false, '30 la nota vive dentro del scroller: se va con el cuerpo, no es chrome fijo');
  ok(N.noteBleed < 375 - 20, `31 la nota no va a sangre: mide ${N.noteBleed} en un device de 375 (respeta la quilla)`);
  ok(N.warnOnScreen === 0, `32 nada en pantalla usa el \`--warn\` inventado: la nota sale sólo de la paleta (${N.warnOnScreen})`);

  /* la medición que contesta lo de la banda: tinta REAL del cuerpo dentro de la franja que ocupa el
     botón, fuera de su caja, con el cuerpo scrolleado a 700 (decodificando el PNG, no contando nodos
     — contar nodos daba 66 para «sin banda» Y para «vela», que es justo lo que la vela arregla). */
  const stripInk = async (chrome) => { await go('FIJA'); await dirty();
    await page.evaluate(([c, y]) => { CHROME = c; render(); document.querySelector('#scroller').scrollTop = y; }, [chrome, 700]);
    await page.waitForTimeout(160);
    const box = await page.evaluate(() => { const dev = document.querySelector('.device').getBoundingClientRect();
      const bar = document.querySelector('#ctabar').getBoundingClientRect(), btn = document.querySelector('#ctabar .cta').getBoundingClientRect();
      return { x: Math.round(dev.x), y: Math.round(bar.y), w: Math.round(dev.width), h: Math.round(bar.height),
        bx: Math.round(btn.x - dev.x), bw: Math.round(btn.width), opaque: getComputedStyle(document.querySelector('#ctabar')).backgroundImage !== 'none' || getComputedStyle(document.querySelector('#ctabar')).backgroundColor !== 'rgba(0, 0, 0, 0)' }; });
    const png = await page.screenshot({ clip: { x: box.x, y: box.y + 2, width: box.w, height: box.h - 2 } });
    const img = decodePNG(png); let ink = 0;
    /* el arnés corre a `deviceScaleFactor: 2`, así que la imagen viene al DOBLE de los px CSS con los
       que se midió la caja del botón. Sin escalar, la ventana de exclusión cae en el lugar
       equivocado y el propio botón se cuenta como tinta del cuerpo: daba 3569 contra los 537 reales.
       La escala se deriva de la imagen, no se asume. */
    const k = img.w / box.w;
    for (let y = 0; y < img.h; y++) for (let x = 0; x < img.w; x++) {
      if (x >= (box.bx - 6) * k && x <= (box.bx + box.bw + 6) * k) continue;
      const i = y * img.w * img.bpp + x * img.bpp;
      if (Math.max(Math.abs(img.data[i] - 255), Math.abs(img.data[i + 1] - 255), Math.abs(img.data[i + 2] - 255)) > 28) ink++; }
    return ink; };
  const inkBare = await stripInk('bare'), inkVeil = await stripInk('veil');
  ok(inkBare > 300, `33 sin banda: ${inkBare}px de texto del cuerpo quedan dentro de la franja del botón`);
  ok(inkVeil < inkBare / 4, `34 la vela borra ${(100 - inkVeil / inkBare * 100).toFixed(0)}% de eso (${inkBare} → ${inkVeil}px) sin dibujar ningún contenedor`);

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
