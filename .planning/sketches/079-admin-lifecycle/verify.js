/* Headless-Chrome checks for sketch 079 — slice 4: el ciclo de vida y el editor de un publicado.
   Correr desde la raíz del repo:
     python3 -m http.server 8765 &
     node .planning/sketches/079-admin-lifecycle/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-079-shots). */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/079-admin-lifecycle/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-079-shots'); fs.mkdirSync(OUT, { recursive: true });
const ROOT = path.resolve(__dirname, '../../..');
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);

/* ---------- decodificador PNG mínimo, para que 8a/8b devuelvan un NÚMERO y no un booleano ----------
   La primera versión comparaba los buffers con `.equals()`. Eso contesta "¿idénticos?" pero no "¿en
   cuántos píxeles y con cuánta diferencia?", y sin eso no se puede distinguir un affordance débil de
   un artefacto de compresión o de una diferencia de un píxel en el antialiasing de una letra.
   075-V4 reportó `diffPx 0 of 270000 · maxDelta 0` — ESE es el formato que hace falta para comparar
   contra aquel resultado. 8 bits, sin entrelazado, color type 2 (RGB) o 6 (RGBA), que es lo que
   Playwright emite. */
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
function diffPNG(b1, b2) {
  const a = decodePNG(b1), b = decodePNG(b2);
  if (a.w !== b.w || a.h !== b.h) return { diffPx: -1, maxDelta: -1, total: -1, note: `tamaños distintos ${a.w}x${a.h} vs ${b.w}x${b.h}` };
  let diffPx = 0, maxDelta = 0;
  const px = a.w * a.h;
  for (let i = 0; i < px; i++) {
    let d = 0;
    for (let k = 0; k < 3; k++) d = Math.max(d, Math.abs(a.data[i * a.bpp + k] - b.data[i * b.bpp + k]));
    if (d > 0) { diffPx++; if (d > maxDelta) maxDelta = d; }
  }
  return { diffPx, maxDelta, total: px, note: '' };
}

/* ============================================================================
   ESTADO DEL SKETCH: LAS CUATRO PREGUNTAS ESTÁN CONTESTADAS Y LOS TOGGLES
   ELIMINADOS (convención de 072: lo que está en pantalla es LA DECISIÓN y no un
   menú de decisiones).

     r1  dónde vive la transición de ciclo   ->  el ⋮, único control de la barra
     r2  qué dice que un bloque se edita     ->  el tinte de d37 + un lápiz sutil
     r3  dónde ocurre la edición             ->  EN UNA HOJA (d33)
     r4  el estado                           ->  explícito, en una franja bajo la barra

   Más el verbo colapsado (`Retirar` = despublicar) y el cuerpo con el ritmo de
   la ficha pública (E3), que fueron premisas del desarrollador.

   Las mediciones que sostienen cada decisión están en el README; acá quedan sólo
   las que siguen siendo verdaderas sobre la página decidida, más las que la
   protegen de volver atrás.

   TRAMPAS QUE ESTE ARCHIVO EVITA, todas cobradas en este linaje:

     · `.hidden` NO DICE SI ALGO ESTÁ EN PANTALLA (la 078 la pisó cinco veces en
       un archivo). Se usa `offsetParent` y, cuando importa, `elementFromPoint`.
     · UN HIT TEST FUERA DEL VIEWPORT NO MIDE OCLUSIÓN, MIDE EL SCROLL: devuelve
       `null` y se lee como "tapado". Cada elemento se scrollea a la vista antes.
     · UNA HOJA MEDIDA A MITAD DE SU TRANSICIÓN DE ENTRADA da posiciones que no
       existen. Se espera al `transitionend`, no a un `setTimeout` a ojo.
     · `getBoundingClientRect().top` ARRASTRA EL SCROLL ACUMULADO de checks
       anteriores. Donde la pregunta es "¿se movió el contenido?", se usa
       `offsetTop`.
     · UN NODO PRESENTE NO ES UNA MARCA VISIBLE: el lápiz de la descripción
       existía dentro de un clamp y salía recortado; el tick existía con un icono
       inexistente y dibujaba un `<svg>` vacío; el punto de estado desapareció
       TRES veces (transparente, naranja, y de ancho cero). Todo check de marca
       lee rect y color resuelto, nunca la existencia del nodo.
   ============================================================================ */

const FIELDS = ['name', 'description', 'band', 'units', 'shelf', 'exp', 'cover'];
const CHOICE = ['band', 'shelf', 'exp'];
const TEXT = ['name', 'description'];

const atRest = p => p.evaluate(() => {
  document.querySelector('#sheet').classList.remove('open');
  document.querySelector('#backdrop').classList.remove('open');
  document.querySelector('#dscrim').classList.remove('open');
  document.querySelector('#snack').classList.remove('show');
  document.querySelector('#device').classList.remove('kbd');
  document.querySelector('#scroller').scrollTop = 0;
  document.querySelector('#tbar').classList.remove('titled');
});
const setState = async (p, s) => { await p.evaluate(s => { document.querySelector(`#tools [data-cy="${s}"]`).click(); }, s); await atRest(p); };
const setCover = async (p, on) => { await p.evaluate(on => { document.querySelector(`#tools [data-cov="${on ? 1 : 0}"]`).click(); }, on); await atRest(p); };
const hideTools = p => p.evaluate(() => { document.querySelector('#tools').hidden = true; document.querySelector('#vnav').style.visibility = 'hidden'; });
const showTools = p => p.evaluate(() => { document.querySelector('#tools').hidden = false; document.querySelector('#vnav').style.visibility = ''; });
const deviceClip = p => p.evaluate(() => { const r = document.querySelector('#device').getBoundingClientRect(); return { x: r.x, y: r.y, width: r.width, height: r.height }; });

const dump = e => { console.log(log.join('\n')); console.error('\nREVENTÓ: ' + (e && e.message)); process.exit(2); };
process.on('uncaughtException', dump);
process.on('unhandledRejection', dump);

(async () => {
  const exe = [process.env.CHROME_BIN, '/usr/bin/google-chrome-stable', '/usr/bin/google-chrome', '/usr/bin/chromium-browser']
    .filter(Boolean).find(p => fs.existsSync(p));
  const browser = await chromium.launch(exe ? { executablePath: exe } : {});
  const page = await browser.newPage({ viewport: { width: 900, height: 900 }, deviceScaleFactor: 2 });
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  await page.goto(URL, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);

  /* la hoja entra con transición: medirla antes de que termine da posiciones que no existen. */
  const settle = () => page.evaluate(() => new Promise(res => {
    const sh = document.querySelector('#sheet');
    if (!sh.classList.contains('open')) return res();
    let done = false; const fin = () => { if (!done) { done = true; res(); } };
    sh.addEventListener('transitionend', fin, { once: true });
    setTimeout(fin, 600);
  }));
  const openField = async k => { await page.evaluate(k => document.querySelector(`#main [data-edit="${k}"]`).click(), k); await settle(); };
  const closeSheet = async () => { await page.evaluate(() => document.querySelector('[data-act="close"]')?.click()); await atRest(page); };

  await hideTools(page);
  ok(await page.evaluate(() => document.querySelector('#tools').offsetParent === null),
    '0 · el panel de herramientas está fuera de layout durante los hit tests (offsetParent, no .hidden)');
  await showTools(page);

  /* ---------- 1 · ninguna variante quedó en la página (072) ---------- */
  const decided = await page.evaluate(() => ({
    toggles: document.querySelectorAll('#vnav [data-var]').length,
    eds: [...document.querySelectorAll('#main .ed')].map(e => e.dataset.edit).join(','),
    pens: document.querySelectorAll('#main .pen').length,
    inline: document.querySelectorAll('#main .inl').length
  }));
  ok(decided.toggles === 0 && decided.inline === 0,
    `1 · cero toggles de variante y cero controles inline en la página — lo que se ve es la decisión (072)`);
  ok(decided.eds === 'band,cover,name,description,units,shelf,exp' && decided.pens === 7,
    `1b · los 7 bloques editables llevan su lápiz — ${decided.eds}`);

  /* 1c · y los lápices se VEN y se TOCAN. Cada uno se scrollea a la vista antes del hit test: fuera
     del viewport `elementFromPoint` devuelve null y eso mide el scroll, no la oclusión. */
  const pens = await page.evaluate(() => [...document.querySelectorAll('#main .pen')].map(pen => {
    const host = pen.closest('.ed'); host.scrollIntoView({ block: 'center' });
    const hr = host.getBoundingClientRect(), pr = pen.getBoundingClientRect();
    const cs = getComputedStyle(host);
    const clip = cs.overflow !== 'visible' || cs.webkitLineClamp !== 'none';
    const el = document.elementFromPoint(pr.left + pr.width / 2, pr.top + pr.height / 2);
    return { k: host.dataset.edit,
      dentro: !clip || (pr.bottom <= hr.bottom + 0.5 && pr.right <= hr.right + 0.5),
      alcanzable: !!(el && (el === pen || pen.contains(el) || el.closest('.pen') === pen || el.closest('.ed') === host)) };
  }));
  await atRest(page);
  const rotos = pens.filter(v => !v.dentro || !v.alcanzable);
  ok(rotos.length === 0, `1c · los ${pens.length} lápices se ven y se pueden tocar`
    + (rotos.length ? ` — FALLAN: ${rotos.map(r => r.k).join(', ')}` : ''));

  /* ============================================================================
     2 · LAS HOJAS DE CAMPO SIGUEN EL PATRÓN DEL EDITOR DE LA 078 (1788-1823)
     Y NO el del formulario de la hoja del borrador. Son dos superficies distintas
     y la 078 ya las había separado; yo había traído el control equivocado.
     ============================================================================ */
  const sheets = {};
  for (const k of FIELDS) {
    await openField(k);
    sheets[k] = await page.evaluate(() => {
      const sh = document.querySelector('#sheet');
      const t = sh.querySelector('.sh-title'), sub = sh.querySelector('.sh-sub');
      const opts = [...sh.querySelectorAll('.opt')];
      const ticks = opts.filter(o => o.querySelector('.tick'));
      const tickBox = ticks[0] ? ticks[0].querySelector('.tick svg').getBoundingClientRect() : null;
      return {
        titulo: t ? t.textContent : null, sub: sub ? sub.textContent : null,
        opts: opts.length, ticks: ticks.length,
        tickDibujado: !!(tickBox && tickBox.width > 8 && ticks[0].querySelector('.tick svg path')),
        guardar: !!sh.querySelector('.obtn.wide.pri'),
        seg: sh.querySelectorAll('.seg').length,
        chrome: !!sh.querySelector('.sh-top') && !!sh.querySelector('.grab')
      };
    });
    await closeSheet();
  }
  ok(FIELDS.every(k => sheets[k].sub && sheets[k].chrome),
    `2a · las ${FIELDS.length} hojas tienen subtítulo y el chrome de la 078 (agarradera + .sh-top)`);
  ok(CHOICE.every(k => sheets[k].opts > 0 && sheets[k].ticks === 1 && sheets[k].seg === 0),
    `2b · las de elección usan .opt con UN tick en el valor actual, no el .seg del formulario del borrador — `
    + CHOICE.map(k => `${k} ${sheets[k].opts} opciones/${sheets[k].ticks} tick`).join(' · '));
  /* 2c · Y EL TICK ESTÁ DIBUJADO. `P['tick']` no existía en el mapa de iconos, así que `ic('tick')`
     producía un `<svg>` con `undefined` adentro: nodo presente, con tamaño, sin nada pintado. Lo
     encontró la captura, no el conteo. */
  ok(CHOICE.every(k => sheets[k].tickDibujado),
    `2c · y el tick tiene un path de verdad, no un <svg> vacío — el icono existía como nodo y no como dibujo`);
  ok(TEXT.every(k => sheets[k].guardar) && CHOICE.every(k => !sheets[k].guardar),
    `2d · los campos de texto llevan su propio Guardar ancho y los de elección no (elegir es el commit)`);

  /* ---------- 3 · cerrar un campo de texto sin Guardar NO escribe ----------
     El defecto apareció al quedarse la hoja sola: el modo inline tenía un botón `Listo` que hacía de
     commit, y sin él escribir el nombre y cerrar con el ✕ lo descartaba en silencio. */
  const drop = await page.evaluate(async () => {
    const antes = document.querySelector('.ed.h1').textContent.trim();
    document.querySelector('#main [data-edit="name"]').click();
    await new Promise(r => setTimeout(r, 120));
    document.querySelector('#f-name').value = 'NOMBRE TIRADO';
    document.querySelector('[data-act="close"]').click();
    await new Promise(r => setTimeout(r, 320));
    return { antes, despues: document.querySelector('.ed.h1').textContent.trim() };
  });
  await atRest(page);
  ok(drop.antes === drop.despues,
    `3a · escribir y cerrar con el ✕ no escribe nada ("${drop.despues}") — nada se guarda sin tocar Guardar`);

  const commit = await page.evaluate(async () => {
    document.querySelector('#main [data-edit="name"]').click();
    await new Promise(r => setTimeout(r, 120));
    document.querySelector('#f-name').value = 'Scythe (edición 2016)';
    document.querySelector('[data-pick="name"]').click();
    await new Promise(r => setTimeout(r, 320));
    return { titulo: document.querySelector('.ed.h1').textContent.trim(), barra: document.querySelector('#tbar .tb-t').textContent.trim(),
      cerrada: !document.querySelector('#sheet').classList.contains('open') };
  });
  ok(commit.cerrada && /2016/.test(commit.titulo) && /2016/.test(commit.barra),
    `3b · y Guardar sí escribe, cierra, y el valor aparece en LOS DOS lugares que lo muestran (título y barra): "${commit.titulo}"`);
  await page.reload({ waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);

  /* 3c · elegir una opción escribe y cierra de una (d33: la elección ES el commit). */
  await openField('band');
  const pick = await page.evaluate(async () => {
    const opts = [...document.querySelectorAll('#sheet .opt')];
    const otra = opts.find(o => !o.querySelector('.tick'));
    const txt = otra.querySelector('.on2').textContent;
    otra.click();
    await new Promise(r => setTimeout(r, 320));
    return { txt, cerrada: !document.querySelector('#sheet').classList.contains('open'),
      pill: document.querySelector('.ed.pill').textContent.trim() };
  });
  await atRest(page);
  ok(pick.cerrada && pick.pill.includes(pick.txt),
    `3c · elegir escribe y cierra: el pill del nivel dice "${pick.pill}"`);
  await page.reload({ waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);

  /* 3d · el stepper edita DENTRO de la hoja, así que la hoja tiene que repintarse sola. La 078 perdió
     una ronda con este defecto: una edición hecha adentro de una hoja que el resto de la pantalla no
     puede ver es el modelo fallando en silencio. */
  await openField('units');
  const step = await page.evaluate(async () => {
    const n = () => document.querySelector('#sheet .stepper .n').textContent.trim();
    const antes = n();
    document.querySelector('#sheet [data-units="1"]').click();
    await new Promise(r => setTimeout(r, 60));
    return { antes, enHoja: n(), enPagina: [...document.querySelectorAll('.spec')].find(s => /Copias/.test(s.textContent)).querySelector('.ed').textContent.trim() };
  });
  await closeSheet();
  ok(step.enHoja === '2' && step.enPagina === '2',
    `3e · el stepper repinta la hoja Y la página detrás (${step.antes} → ${step.enHoja} / ${step.enPagina})`);
  await page.reload({ waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);

  /* ---------- 4 · la hoja no mueve la ficha, y sube sobre el teclado ----------
     Las dos cosas son por qué se eligió la hoja sobre el inline. `offsetTop`, no el rect: la pregunta
     es si el CONTENIDO se movió, y el rect arrastra el scroll de checks anteriores. */
  const quieto = await page.evaluate(async () => {
    const sc = document.querySelector('#scroller');
    const ref = () => document.querySelector('.glab').offsetTop;
    const antes = ref(), alto = sc.scrollHeight;
    document.querySelector('#main [data-edit="band"]').click();
    await new Promise(r => setTimeout(r, 320));
    return { delta: ref() - antes, dPage: sc.scrollHeight - alto };
  });
  await closeSheet();
  ok(quieto.delta === 0 && quieto.dPage === 0,
    `4a · abrir una hoja no mueve la ficha ni un píxel (${quieto.delta}px, alto ${quieto.dPage}px) — es lo que compra d33`);

  await hideTools(page);
  await openField('description');
  const kb = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const f = document.querySelector('.fld').getBoundingClientRect();
    const piso = d.bottom - 292;                  /* el borde superior del teclado, 078:537 */
    const hit = document.elementFromPoint(f.left + f.width / 2, f.top + f.height / 2);
    return { top: Math.round(f.top - d.top), bottom: Math.round(f.bottom - d.top),
      tapado: f.bottom > piso, tocable: !!(hit && hit.closest('.fld')) };
  });
  await page.screenshot({ path: path.join(OUT, 'r5-teclado.png'), clip: await deviceClip(page) });
  await closeSheet(); await showTools(page);
  ok(!kb.tapado && kb.tocable,
    `4b · con el teclado arriba, el textarea queda en y=${kb.top}-${kb.bottom}, sobre el piso de 448, y es tocable — `
    + `la hoja lo sube sola (.sheet.form + device.kbd, 078:537). Inline quedaba en y=595-713, debajo.`);

  /* ============================================================================
     5 · EL RITMO DE LA FICHA, que es la premisa de E3
     ============================================================================ */
  const type = await page.evaluate(() => {
    const cs = s => { const c = getComputedStyle(document.querySelector(s)); return { ff: c.fontFamily.split(',')[0].replace(/"/g, ''), fs: c.fontSize, fw: c.fontWeight, lh: c.lineHeight }; };
    return { h1: cs('.h1'), desc: cs('.desc'), dt: cs('.spec dt'), pill: cs('.pill.neutral'), tag: cs('.pill.tag') };
  });
  ok(type.h1.ff === 'Bebas Neue' && type.h1.fs === '30px' && type.h1.lh === '36px',
    `5a · el título es ${type.h1.ff} ${type.h1.fs}/${type.h1.lh} — el de la web (show.ex:660), no los 22/600 Inter de D-19j`);
  ok(type.desc.fs === '16px' && type.dt.fs === '12px' && type.pill.fs === '11px' && type.pill.fw === '600' && type.tag.fs === '14px',
    `5b · y el resto del rango también — descripción ${type.desc.fs} · etiquetas ${type.dt.fs} · pills ${type.pill.fs}/${type.pill.fw} · chip ${type.tag.fs}`);

  const keyline = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const cta = document.querySelector('.cta').getBoundingClientRect();
    const kb = document.querySelector('#kebab').getBoundingClientRect();
    const t = document.querySelector('.h1').getBoundingClientRect();
    const c = document.querySelector('.cardposter').getBoundingClientRect();
    return { gut: Math.round(parseFloat(getComputedStyle(document.querySelector('.wrap')).paddingLeft)),
      ctaR: Math.round(cta.right - d.left), kebabR: Math.round(kb.right - d.left),
      texto: Math.round(t.left - d.left), tapa: Math.round(c.left - d.left) };
  });
  ok(keyline.gut === 14 && keyline.ctaR === 361 && keyline.kebabR === 359,
    `5c · la quilla es la de la web (${keyline.gut}px), así que el cuerpo termina en R${keyline.ctaR} y la barra en R${keyline.kebabR} — `
    + `d42 fijó R359 y 074/075/078 lo sostuvieron. DOS bordes derechos, medido y no evitado.`);
  ok(keyline.texto === 14 && keyline.tapa === 31,
    `5d · y dos bordes izquierdos: texto a ${keyline.texto}, tapa a ${keyline.tapa} (= 14 quilla + 1 borde + 16 padding del panel). Es fiel a la web.`);

  /* 5e · el rango no puede decir qué se edita, que es por qué el affordance existe. */
  const rank = await page.evaluate(() => {
    const pick = el => { const c = getComputedStyle(el); return [c.fontSize, c.fontWeight, c.textTransform, c.letterSpacing, c.color].join('|'); };
    const dts = [...document.querySelectorAll('.spec dt')];
    const bgg = dts.filter(d => !d.closest('.spec').querySelector('.ed'));
    const club = dts.filter(d => d.closest('.spec').querySelector('.ed'));
    return { bggN: bgg.length, clubN: club.length, iguales: new Set([...bgg, ...club].map(pick)).size === 1, muestra: pick(dts[0]) };
  });
  ok(rank.iguales && rank.bggN === 5 && rank.clubN === 3,
    `5e · las ${rank.clubN} etiquetas editables son byte-idénticas en rango a las ${rank.bggN} de BGG (${rank.muestra}) — `
    + `el rango no puede decir qué se toca, y por eso todo el peso queda en el tinte y el lápiz`);

  /* 5f · COSTO MEDIDO (verde = el costo existe): el tinte es el mismo color que el chip de sección,
     que NO se edita. No se arregla sin tocar la paleta; lo único que desambigua es el lápiz. */
  const amb = await page.evaluate(() => {
    const c = el => getComputedStyle(el).color;
    const chip = document.querySelector('.pill.tag'), h1 = document.querySelector('.ed.h1');
    const pen = document.querySelector('.ed.h1 .pen svg').getBoundingClientRect();
    return { mismo: c(chip) === c(h1), color: c(chip), chipPen: !!chip.querySelector('.pen'), pen: [Math.round(pen.width), Math.round(pen.height)] };
  });
  ok(amb.mismo && !amb.chipPen,
    `5f · COSTO MEDIDO — el tinte (${amb.color}) es el mismo color que el chip de sección, que no se edita. `
    + `--color-primary y --color-accent-text son el mismo hex en claro (074 r3), así que lo único que desambigua `
    + `es un lápiz de ${amb.pen[0]}×${amb.pen[1]}: la marca más chica de la pantalla.`);

  /* 5g · COSTO MEDIDO: el CTA está a casi dos pantallas. La web resuelve el pie con una barra FIJA. */
  await hideTools(page);
  const cta = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const sc = document.querySelector('#scroller');
    const c = document.querySelector('.cta').getBoundingClientRect();
    return { top: Math.round(c.top - d.top), alto: Math.round(c.height), visible: c.top < d.bottom,
      scroll: sc.scrollHeight - sc.clientHeight, pantallas: +(sc.scrollHeight / d.height).toFixed(1) };
  });
  await showTools(page);
  ok(cta.alto >= 52 && !cta.visible,
    `5g · COSTO MEDIDO — el CTA de 52px (el patrón de Publicar, 078:860) está en y=${cta.top} contra un piso de 740: `
    + `${cta.scroll}px de scroll, ${cta.pantallas} pantallas. La web resuelve el pie con una barra FIJA + 148px reservados; `
    + `la 078 no, porque su formulario entraba en una hoja corta.`);

  /* 5h · el nivel aparece dos veces, y no es el fixture. */
  const twice = await page.evaluate(() => {
    const hits = [...document.querySelectorAll('#main .pill')].filter(p => /Ingenio estratega/.test(p.textContent));
    const d = document.querySelector('#device').getBoundingClientRect();
    return hits.map(h => ({ y: Math.round(h.getBoundingClientRect().top - d.top), editable: h.classList.contains('ed') }));
  });
  ok(twice.length === 2 && twice.filter(h => h.editable).length === 1,
    `5h · el nivel está dos veces — el pill de facts (y=${twice[0]?.y}, editable) y el chip de sección (y=${twice[1]?.y}, no editable, `
    + `porque es section_names, virtual). Publicar mete el juego en la sección de su banda: es cómo se ve la ficha.`);

  /* 5i · los 49 sin tapa. */
  await setCover(page, false); await hideTools(page);
  const nocover = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const c = document.querySelector('.cardposter').getBoundingClientRect();
    return { alto: Math.round(c.height), pct: Math.round(c.height / d.height * 100), titulo: Math.round(document.querySelector('.h1').getBoundingClientRect().top - d.top) };
  });
  await page.screenshot({ path: path.join(OUT, 'r5-sin-tapa.png'), clip: await deviceClip(page) });
  await showTools(page); await setCover(page, true);
  ok(nocover.pct >= 30,
    `5i · sin tapa (los 49 = no_bgg_id 41 + bgg_missing 8, contra la base) el hueco mide ${nocover.alto}px, el ${nocover.pct}% de la pantalla, `
    + `y empuja el título a y=${nocover.titulo}. Son los juegos que abrís el editor para arreglar.`);

  /* ---------- 6 · el piso táctil ---------- */
  const touch = await page.evaluate(() => [...document.querySelectorAll('#main .ed')].map(e => ({
    k: e.dataset.edit, h: Math.round(e.getBoundingClientRect().height), after: getComputedStyle(e, '::after').height })));
  const chicos = touch.filter(t => t.h < 44 && !/44px/.test(t.after));
  ok(chicos.length === 0, `6a · los ${touch.length} bloques editables llegan al piso de 44px`
    + (chicos.length ? ` — no llegan: ${chicos.map(c => c.k + ' ' + c.h).join(', ')}` : ''));
  const overlap = await page.evaluate(() => {
    const boxes = [...document.querySelectorAll('#main .spec dd .ed')].map(e => {
      const r = e.getBoundingClientRect(), h = parseFloat(getComputedStyle(e, '::after').height) || r.height;
      const cy = r.top + r.height / 2; return { k: e.dataset.edit, top: cy - h / 2, bottom: cy + h / 2 };
    });
    const pares = []; for (let i = 1; i < boxes.length; i++) if (boxes[i].top < boxes[i - 1].bottom) pares.push(`${boxes[i - 1].k}/${boxes[i].k}`);
    return { pares, n: boxes.length };
  });
  ok(overlap.pares.length === 0, `6b · y las ${overlap.n} capas de toque de DEL CLUB no se solapan`
    + (overlap.pares.length ? ` — SE SOLAPAN: ${overlap.pares.join(', ')}` : ''));

  /* ============================================================================
     7 · EL ESTADO, EXPLÍCITO (r4)
     ============================================================================ */
  await hideTools(page);
  const stShot = async st => { await setState(page, st); return page.screenshot({ clip: await deviceClip(page) }); };
  const sPub = await stShot('published'), sRet = await stShot('retired');
  fs.writeFileSync(path.join(OUT, 'r5-publicado.png'), sPub);
  fs.writeFileSync(path.join(OUT, 'r5-retirado.png'), sRet);
  ok(diffPNG(sPub, sRet).diffPx > 0, `7a · publicado y retirado ya no son la misma página`);

  const bare = async st => { await setState(page, st);
    await page.evaluate(() => { document.querySelector('#stbar').style.display = 'none'; });
    const png = await page.screenshot({ clip: await deviceClip(page) });
    await page.evaluate(() => { document.querySelector('#stbar').style.display = ''; });
    return png; };
  const dBare = diffPNG(await bare('published'), await bare('retired'));
  ok(dBare.diffPx === 0,
    `7b · NEGATIVO — sin la franja vuelven a ser IDÉNTICOS (diffPx ${dBare.diffPx} de ${dBare.total}): la franja es lo ÚNICO que lleva el estado, `
    + `porque la ficha espejada no lo dice en ninguna parte — la ficha pública tampoco. Ése era el defecto de la r4.`);
  await showTools(page);

  const dots = {};
  for (const st of ['published', 'retired']) {
    await setState(page, st);
    dots[st] = await page.evaluate(() => {
      const d = document.querySelector('#stbar .dot'), r = d.getBoundingClientRect(), c = getComputedStyle(d);
      return { w: Math.round(r.width), h: Math.round(r.height), bg: c.backgroundColor,
        texto: document.querySelector('#stbar').textContent.replace(/\s+/g, ' ').trim() };
    });
  }
  const vivo = d => d.w === 8 && d.h === 8 && !/rgba\(0, 0, 0, 0\)|transparent/.test(d.bg);
  ok(vivo(dots.published) && vivo(dots.retired) && dots.published.bg !== dots.retired.bg,
    `7c · el punto mide 8×8 con color resuelto en los dos estados, y son distintos — ${dots.published.bg} / ${dots.retired.bg}. `
    + `Se lee rect + color porque este punto desapareció TRES veces: transparente (078), naranja y de ancho cero (acá).`);

  await setState(page, 'published');
  const vis = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const sb = document.querySelector('#stbar').getBoundingClientRect();
    const hit = document.elementFromPoint(sb.left + sb.width / 2, sb.top + sb.height / 2);
    return { top: Math.round(sb.top - d.top), alto: Math.round(sb.height), enPantalla: sb.bottom <= d.bottom, tapada: !!(hit && !hit.closest('#stbar')) };
  });
  ok(vis.enPantalla && !vis.tapada && vis.top < 100,
    `7d · la franja está en y=${vis.top}, ${vis.alto}px, sin scrollear y sin nada encima — no hay que abrir nada para saber el estado`);
  ok(/Así se ve en la web/.test(dots.published.texto) && /No se ve en la web/.test(dots.retired.texto),
    `7e · y dice la consecuencia, no el nombre — "${dots.published.texto}" / "${dots.retired.texto}". `
    + `Para un retirado, la premisa de E3 ("así se ve en la web") es falsa, y la franja es lo único que puede decirlo.`);

  /* ---------- 8 · el ⋮ y el ciclo ---------- */
  const bar = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const kb = document.querySelector('#kebab').getBoundingClientRect();
    return { right: Math.round(kb.right - d.left), otros: document.querySelectorAll('#tbar button').length,
      primario: !!document.querySelector('#tbar .btn') };
  });
  ok(bar.otros === 2 && !bar.primario && bar.right === 359,
    `8a · la barra tiene ${bar.otros} controles (‹ y ⋮) y ningún primario: Guardar bajó al pie, así que el ⋮ no empuja nada y toma R${bar.right}. `
    + `El costo que queda es que hereda la esquina que cinco pantallas enseñaron como LA ACCIÓN PRINCIPAL — el inverso de lo que la 074 r1 encontró con Descartar.`);

  const cycle = await page.evaluate(async () => {
    document.querySelector('#kebab').click();
    await new Promise(r => setTimeout(r, 320));
    const opts = [...document.querySelectorAll('#sheet .opt')].map(o => o.querySelector('.on2').textContent);
    const enHoja = (document.querySelector('#sheet').textContent.match(/Publicado/g) || []).length;
    document.querySelector('[data-cyc="retire"]').click();
    const txt = document.querySelector('#dlg-d').textContent;
    document.querySelector('[data-act="dlg-yes"]').click();
    return { opts, enHoja, txt, after: document.querySelector('#tools [data-cy].on').dataset.cy };
  });
  await setState(page, 'published');
  ok(cycle.opts.length === 1 && cycle.after === 'retired',
    `8b · el ⋮ abre la hoja de ciclo, ofrece ${cycle.opts.length} opción (${cycle.opts.join('')}) y commitea a \`${cycle.after}\` — `
    + `un solo verbo en todos los estados, que es lo que el colapso decidió`);
  ok(cycle.enHoja === 1,
    `8c · y el estado se dice UNA vez en la hoja (su subtítulo), no otra vez en el cuerpo: con la franja ya son dos lugares, y tres era la forma que contó la 077`);
  ok(/ya no lo tiene/i.test(cycle.txt) && /ludoteca pública/i.test(cycle.txt) && /estantes/i.test(cycle.txt),
    `8d · el diálogo dice las DOS mitades — el club y la web. La copia que corre hoy (form.ex:352-356) sólo decía la de la web, `
    + `mientras shelves.ex usaba la otra en 5 consultas.`);

  /* ---------- 9 · el chrome de la hoja es el de la 078 ---------- */
  await openField('band');
  const chrome = await page.evaluate(() => {
    const sh = document.querySelector('#sheet');
    const t = sh.querySelector('.sh-title'), x = sh.querySelector('.sh-x');
    const tr = t.getBoundingClientRect(), xr = x.getBoundingClientRect();
    return { top: !!sh.querySelector('.sh-top'), grab: !!sh.querySelector('.grab'),
      h2: sh.querySelectorAll('.sh-head h2').length, tam: getComputedStyle(t).fontSize + '/' + getComputedStyle(t).fontWeight,
      mismaFila: Math.abs((tr.top + tr.height / 2) - (xr.top + xr.height / 2)) < 26, derecha: xr.left > tr.right };
  });
  await closeSheet();
  ok(chrome.top && chrome.grab && chrome.h2 === 0 && chrome.tam === '18px/600' && chrome.mismaFila && chrome.derecha,
    `9 · la hoja usa el chrome de la 078: agarradera ${chrome.grab}, título ${chrome.tam}, ✕ en la misma fila (${chrome.mismaFila}) `
    + `y a la derecha (${chrome.derecha}), cero <h2> sueltos. Se rompió exactamente así por escribirlo a mano.`);

  /* ---------- 10 · capturas y consola ---------- */
  await hideTools(page);
  await page.screenshot({ path: path.join(OUT, 'r5-reposo.png'), clip: await deviceClip(page) });
  await openField('band');
  await page.screenshot({ path: path.join(OUT, 'r5-hoja-nivel.png'), clip: await deviceClip(page) });
  await closeSheet();
  await page.evaluate(() => document.querySelector('#kebab').click());
  await settle();
  await page.screenshot({ path: path.join(OUT, 'r5-hoja-ciclo.png'), clip: await deviceClip(page) });
  await closeSheet(); await showTools(page);

  ok(errs.length === 0, `10 · consola limpia${errs.length ? ' — ' + errs.slice(0, 3).join(' | ') : ''}`);

  await browser.close();
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(log.join('\n'));
  console.log(`\n${pass}/${log.length}   capturas en ${OUT}`);
  process.exit(pass === log.length ? 0 : 1);
})();
