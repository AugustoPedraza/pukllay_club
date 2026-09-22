/* Headless-Chrome checks for sketch 079 — slice 4 of the create scenario: the lifecycle transition.
   Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/079-admin-lifecycle/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-079-shots).

   LA PREGUNTA DE LA RONDA 1: dónde vive la transición de ciclo. Tres contenedores —
     M1  el menú ⋮ en la barra de 074
     M2  la zona CICLO al pie del formulario   <- EL INCUMBENTE (form.ex:324-330)
     M3  el read-out `● Publicado` convertido en control (la jugada de 075-V4)

   TRAMPAS QUE ESTE ARCHIVO EVITA A PROPÓSITO — las cinco primeras heredadas del linaje, donde cada una
   produjo un número verde que describía otra cosa que la página:

     · `.hidden` NO DICE SI ALGO ESTÁ EN PANTALLA. Cualquier clase que setea `display` out-especifica el
       `[hidden] { display: none }` del UA. La 078 pisó esa trampa CINCO veces en un solo archivo. Todo
       check de visibilidad de acá usa `offsetParent` y, cuando importa, `elementFromPoint`.
     · UN CONTENEDOR VACÍO NO PRUEBA UN CONTENEDOR AUSENTE: el menú de M1 está `hidden` al reposo, que es
       también lo que se ve si `actions()` devolvió cero. Todo check del menú cerrado va acompañado del
       menú ABIERTO sobre el mismo estado.
     · UN `const` DE NIVEL SUPERIOR EN UN SCRIPT CLÁSICO NO ES PROPIEDAD DE `window`, así que asignarle
       desde el arnés no cambia nada mientras parece que sí (076 dos veces, 077 una). `actions` es una
       DECLARACIÓN de función, alcanzable por `window.actions`, y el check 1b la usa para falsificar al 1.
     · EL PANEL DE HERRAMIENTAS ES `position: fixed` SOBRE EL DEVICE y se come `elementFromPoint`. El
       check 0 asserta que está realmente oculto antes de cualquier hit test.
     · UN NÚMERO SOBRE UN ELEMENTO EN `opacity: 0` ES UN NÚMERO VERDADERO SOBRE ALGO INVISIBLE (074,
       check 20). Acá el título de la barra arranca invisible, así que el check 6 mide el borde derecho
       de `Guardar`, que nunca lo está.
     · Y LA DE ESTA RONDA: DOS PNG IGUALES NO PRUEBAN QUE EL AFFORDANCE NO SE VEA si la región recortada
       no lo incluye. El check 8 recorta por el rect REAL de `.gh-st` y el 8c verifica que el recorte
       contenga la banda, antes de creerle al diff. */
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
   RONDA 2 — E3, la ficha editable.

   PREMISAS DEL DESARROLLADOR, no se varían y por eso no se checkean como si
   fueran una elección: el ⋮ es el único control de arriba y abre una hoja
   inferior · un solo verbo (Retirar/Restaurar) · el CTA es el apilado de 52px
   de la 078 · el cuerpo es la ficha, editable en el lugar.

   EL ÚNICO EJE: ¿qué dice que un bloque de la ficha se puede editar?
   A1 el tinte de d37 · A2 el lápiz · A3 nada (la línea base falsificable).

   POR QUÉ ES UN EJE Y NO UNA PREFERENCIA: d37 contestó esto para el spine del
   admin — etiqueta prominente, valor subordinado, y el valor lleva `--val`.
   E3 no tiene esa anatomía en la cabecera: el título es un `<h1>` pelado, la
   descripción es prosa pelada, el nivel es un pill. No hay etiqueta de la cual
   el valor sea subordinado, así que d37 no cubre el caso.

   TRAMPAS NUEVAS DE ESTA RONDA, las dos encontradas en la captura y no por un
   número — y las dos habrían dejado pasar checks de conteo de nodos:

     · `.ed .h1` NO ES `.ed.h1`. El bloque editable ES el título, no lo
       contiene. Con el selector descendiente, A1 no pintaba nada y era
       byte-idéntica a A3 — la variante del tinte y la de "nada", la misma
       página. Por eso el check 25 compara PÍXELES contra A3, nunca nodos.
     · UN RESET VA ANTES QUE LAS REGLAS DE TIPO. `.pg .ed { font: inherit }`
       puesto después le ganaba por orden a `.pg .h1` (misma especificidad) y
       el título salía en Inter 16 en vez de Bebas 30. El check 20 lee la
       familia y el tamaño COMPUTADOS.
   ============================================================================ */

const VARS = ['A1', 'A2', 'A3'];
const setVar = async (p, v) => { await p.evaluate(v => { document.querySelector(`#vnav [data-var="${v}"]`).click(); }, v); await atRest(p); };
const setCover = async (p, on) => { await p.evaluate(on => { document.querySelector(`#tools [data-cov="${on ? 1 : 0}"]`).click(); }, on); await atRest(p); };
const setState = async (p, s) => { await p.evaluate(s => { document.querySelector(`#tools [data-cy="${s}"]`).click(); }, s); await atRest(p); };
const atRest = p => p.evaluate(() => {
  document.querySelector('#sheet').classList.remove('open');
  document.querySelector('#backdrop').classList.remove('open');
  document.querySelector('#dscrim').classList.remove('open');
  document.querySelector('#snack').classList.remove('show');
  document.querySelector('#scroller').scrollTop = 0;
  document.querySelector('#tbar').classList.remove('titled');
});
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
  /* la fuente de display importa para todo lo de abajo; si no cargó, cada medida de tipo es sobre
     el fallback y no sobre Bebas. Se espera explícitamente en vez de confiar en networkidle. */
  await page.evaluate(() => document.fonts.ready);

  await hideTools(page);
  ok(await page.evaluate(() => document.querySelector('#tools').offsetParent === null),
    '0 · el panel de herramientas está fuera de layout durante los hit tests (offsetParent, no .hidden)');
  await showTools(page);

  /* ---------- 1 · no atribuible: el DOM de las tres difiere SÓLO en el affordance ---------- */
  const shape = {};
  for (const v of VARS) {
    await setVar(page, v);
    shape[v] = await page.evaluate(() => ({
      eds: [...document.querySelectorAll('#main .ed')].map(e => e.dataset.edit).join(','),
      specs: document.querySelectorAll('#main .spec').length,
      pens: document.querySelectorAll('#main .pen').length
    }));
  }
  ok(shape.A1.eds === shape.A2.eds && shape.A2.eds === shape.A3.eds && shape.A1.specs === shape.A3.specs,
    `1 · las tres variantes tienen los MISMOS bloques editables y las mismas filas — ${shape.A3.eds}`);
  /* 6, no 7: LA TAPA NO LLEVA LÁPIZ, y eso es un hallazgo de A2, no un descuido del fixture. Un glifo
     inline se cuelga del final de un texto; una imagen no tiene final de texto del cual colgarse, así
     que el lápiz tendría que ir superpuesto sobre la tapa — que es otro affordance, no el mismo.
     A2 marca 6 de los 7 bloques. */
  ok(shape.A1.pens === 0 && shape.A3.pens === 0 && shape.A2.pens === 6,
    `1b · el único nodo que difiere es el lápiz: A1 ${shape.A1.pens} · A2 ${shape.A2.pens} · A3 ${shape.A3.pens} — `
    + `y son 6 de 7 bloques: LA TAPA SE QUEDA SIN MARCA en A2, porque un glifo inline necesita un final de texto `
    + `del cual colgarse y una imagen no lo tiene.`);

  /* ---------- 1c · CONTAR NODOS NO ES CONTAR MARCAS VISIBLES, y lo encontró la captura ----------
     El lápiz de la descripción se cuelga del final del párrafo, y el párrafo está clampeado a 3
     líneas con `-webkit-line-clamp`. El nodo existe, tiene tamaño, y está recortado fuera de la caja.
     El check 1b lo contaba como marca; en pantalla no hay ninguna.
     Es la forma del punto invisible de la 078 (tres checks verdes sobre cuadraditos transparentes) y
     de la banda de la ronda 1 que pintaba detrás de `.device`. Se mide contra el rect del ancestro
     que recorta, no contra la existencia del nodo. */
  await setVar(page, 'A2');
  const visibles = await page.evaluate(() => {
    return [...document.querySelectorAll('#main .pen')].map(pen => {
      const host = pen.closest('.ed');
      const hr = host.getBoundingClientRect(), pr = pen.getBoundingClientRect();
      const clip = getComputedStyle(host).overflow !== 'visible' || getComputedStyle(host).webkitLineClamp !== 'none';
      const dentro = !clip || (pr.bottom <= hr.bottom + 0.5 && pr.right <= hr.right + 0.5);
      return { k: host.dataset.edit, dentro, penY: Math.round(pr.top), hostBottom: Math.round(hr.bottom) };
    });
  });
  const ocultos = visibles.filter(v => !v.dentro);
  ok(ocultos.length === 0,
    `1c · los ${visibles.length} lápices de A2 se ven de verdad (no sólo existen en el DOM)`
    + (ocultos.length ? ` — RECORTADOS: ${ocultos.map(o => `${o.k} (el lápiz en y=${o.penY}, la caja termina en ${o.hostBottom})`).join(', ')}. `
       + `Sumado a la tapa, A2 marca ${visibles.length - ocultos.length} de 7 bloques en pantalla.` : ''));

  /* ============================================================================
     20 · EL TÍTULO ES BEBAS 30/36 DE VERDAD — leído, no declarado
     `font-display text-3xl` (show.ex:660). El admin lo tiene en 22/600 Inter y
     D-19j fija ese rango para una página de admin, así que esto lo PISA, y se
     escribe (d47) en vez de dejarlo como deriva.
     ============================================================================ */
  await setVar(page, 'A3');
  const type = await page.evaluate(() => {
    const cs = s => { const c = getComputedStyle(document.querySelector(s)); return { ff: c.fontFamily.split(',')[0].replace(/"/g, ''), fs: c.fontSize, fw: c.fontWeight, lh: c.lineHeight }; };
    return { h1: cs('.h1'), desc: cs('.desc'), dt: cs('.spec dt'), pill: cs('.pill.neutral'), tag: cs('.pill.tag') };
  });
  ok(type.h1.ff === 'Bebas Neue' && type.h1.fs === '30px' && type.h1.lh === '36px',
    `20a · el título es ${type.h1.ff} ${type.h1.fs}/${type.h1.lh} — la web (show.ex:660), no los 22/600 Inter de D-19j`);
  ok(type.desc.fs === '16px' && type.dt.fs === '12px' && type.pill.fs === '11px' && type.pill.fw === '600' && type.tag.fs === '14px' && type.tag.fw === '400',
    `20b · el resto del rango también es el de la web — descripción ${type.desc.fs} · etiquetas ${type.dt.fs} · pills ${type.pill.fs}/${type.pill.fw} · chip de sección ${type.tag.fs}/${type.tag.fw}`);

  /* ---------- 21 · LA QUILLA: 14, no 16 — y qué le hace a R359 ---------- */
  const keyline = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const w = document.querySelector('.wrap').getBoundingClientRect();
    const cta = document.querySelector('.cta').getBoundingClientRect();
    const kb = document.querySelector('#kebab').getBoundingClientRect();
    return {
      /* el padding se lee COMPUTADO, no del rect: `.wrap` ES el elemento que lo lleva, así que su
         borde izquierdo está en 0 y el rect no dice nada de la quilla. La primera versión medía
         `w.left - d.left` y reportaba 0 — un número verdadero sobre el borde equivocado. */
      gut: Math.round(parseFloat(getComputedStyle(document.querySelector('.wrap')).paddingLeft)),
      ctaR: Math.round(cta.right - d.left),
      kebabR: Math.round(kb.right - d.left)
    };
  });
  ok(keyline.gut === 14, `21a · la quilla es ${keyline.gut}px, la de la web a ≤480 (--pk-gutter 0.875rem), no los 16 del admin`);
  ok(keyline.ctaR === 361 && keyline.ctaR !== 359,
    `21b · así que el CTA termina en R${keyline.ctaR}, no en R359 — d42 fijó ese borde y 074/075/078 lo sostuvieron. `
    + `Adoptar el ritmo de la web lo mueve 2px. Medido, no evitado eligiendo 16 y llamándolo "el ritmo de la web".`);
  ok(keyline.kebabR === 359,
    `21c · y la barra NO se mudó: el ⋮ sigue en R${keyline.kebabR}, así que la página tiene ahora DOS bordes derechos — `
    + `la barra en 359 y el cuerpo en 361`);

  /* ---------- 22 · y DOS bordes izquierdos, que es como es la web ---------- */
  const edges = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const t = document.querySelector('.h1').getBoundingClientRect();
    const c = document.querySelector('.cardposter').getBoundingClientRect();
    const p = document.querySelector('.poster').getBoundingClientRect();
    return { texto: Math.round(t.left - d.left), tapa: Math.round(c.left - d.left), panel: Math.round(p.left - d.left) };
  });
  /* 31, NO 30 — Y LA CUENTA DE 30 ERA LA MÍA, NO LA DE LA PÁGINA. `.pk-poster-panel` lleva
     `border: 1px solid` además del `padding: 1rem` (app.css:4875-4884), así que la tapa arranca a
     14 (quilla) + 1 (borde) + 16 (padding) = 31. Había escrito 30 sumando sólo padding + quilla.
     El check pasó a afirmar el número medido y a mostrar la suma, para que el próximo que lo lea no
     tenga que rehacerla. */
  ok(edges.texto === 14 && edges.tapa === 31,
    `22 · dos bordes izquierdos: el texto a ${edges.texto}px y la tapa a ${edges.tapa} (= 14 quilla + 1 borde + 16 padding del `
    + `panel, app.css:4875-4884). Es fiel a la web, que tiene los dos; el editor tenía UNO solo.`);

  /* ============================================================================
     23 · LOS DOS "APILADO ABAJO" NO SON EL MISMO, Y ACÁ SE VE CUÁNTO
     El desarrollador pidió el patrón de `Publicar` de la 078: `.cta` como último
     hijo, que scrollea. La web en mobile hace otra cosa: `.pk-mobile-cta-bar` es
     `position: fixed` con 148px de body reservado (app.css:5375-5398, 5440-5441).
     ============================================================================ */
  await hideTools(page);
  const cta = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const sc = document.querySelector('#scroller');
    const c = document.querySelector('.cta').getBoundingClientRect();
    const hit = document.elementFromPoint(c.left + c.width / 2, c.top + c.height / 2);
    return {
      top: Math.round(c.top - d.top), floor: Math.round(d.height), alto: Math.round(c.height),
      visible: c.top < d.bottom, tocable: !!(hit && hit.closest('.cta')),
      scrollTotal: sc.scrollHeight - sc.clientHeight, pantallas: +((sc.scrollHeight) / d.height).toFixed(1)
    };
  });
  await showTools(page);
  ok(cta.alto >= 52, `23a · el CTA mide ${cta.alto}px de alto, el patrón de Publicar de la 078 (078:860)`);
  ok(cta.visible === false && cta.tocable === false,
    `23b · y al reposo está en y=${cta.top}, contra un piso de ${cta.floor}: invisible y no tocable. `
    + `Hay que scrollear ${cta.scrollTotal}px — la página mide ${cta.pantallas} pantallas — para llegar a Guardar. `
    + `La web resuelve esto con una barra FIJA; la 078 no, porque su formulario entraba en una hoja corta.`);

  /* ============================================================================
     24 · EN E3, EL RANGO YA NO PUEDE DECIR QUÉ SE EDITA
     La web sólo tiene UN vocabulario etiqueta→valor: 12px mayúsculas 0.08em. Y
     en la web pertenece EXCLUSIVAMENTE a datos de BGG que no se tocan (AÑO,
     DISEÑADORES, ILUSTRADORES, MECÁNICAS, TEMÁTICAS, COMUNIDAD BGG). E3 obliga a
     usarlo también para COPIAS, ESTANTE y EXPANSIÓN, que sí se editan.
     ============================================================================ */
  const rank = await page.evaluate(() => {
    const pick = el => { const c = getComputedStyle(el); return [c.fontSize, c.fontWeight, c.textTransform, c.letterSpacing, c.color].join('|'); };
    const dts = [...document.querySelectorAll('.spec dt')];
    const bgg = dts.filter(d => !d.closest('.spec').querySelector('.ed'));
    const club = dts.filter(d => d.closest('.spec').querySelector('.ed'));
    return {
      bggN: bgg.length, clubN: club.length,
      iguales: bgg.length > 0 && club.length > 0 && new Set([...bgg, ...club].map(pick)).size === 1,
      muestra: pick(dts[0]),
      bggLabels: bgg.map(d => d.textContent), clubLabels: club.map(d => d.textContent)
    };
  });
  ok(rank.iguales && rank.bggN === 5 && rank.clubN === 3,
    `24 · las ${rank.clubN} etiquetas editables (${rank.clubLabels.join(', ')}) son BYTE-IDÉNTICAS en rango a las ${rank.bggN} `
    + `no editables (${rank.bggLabels.join(', ')}) — ${rank.muestra}. En E3 el rango no puede decir qué se puede tocar: `
    + `todo el peso queda en el affordance, que es el eje de esta ronda.`);

  /* ============================================================================
     25-26 · EL EJE, EN PÍXELES Y EN ESTILO COMPUTADO
     ============================================================================ */
  await hideTools(page);
  const shot = async v => { await setVar(page, v); return page.screenshot({ clip: await deviceClip(page) }); };
  const sA1 = await shot('A1'), sA2 = await shot('A2'), sA3 = await shot('A3');
  fs.writeFileSync(path.join(OUT, 'r2-A1.png'), sA1);
  fs.writeFileSync(path.join(OUT, 'r2-A2.png'), sA2);
  fs.writeFileSync(path.join(OUT, 'r2-A3.png'), sA3);
  const d1 = diffPNG(sA3, sA1), d2 = diffPNG(sA3, sA2);
  ok(d1.diffPx > 0, `25a · A1 (el tinte) pinta ${d1.diffPx} px de ${d1.total} contra A3 · maxDelta ${d1.maxDelta}`);
  ok(d2.diffPx > 0, `25b · A2 (el lápiz) pinta ${d2.diffPx} px de ${d2.total} contra A3 · maxDelta ${d2.maxDelta}`);
  ok(d1.diffPx > d2.diffPx * 3,
    `25c · y el tinte cubre ${(d1.diffPx / Math.max(1, d2.diffPx)).toFixed(1)}× lo que el lápiz — en el spine de d37 el valor es `
    + `una línea corta; acá es un H1 de 30px y un párrafo justificado de tres líneas`);

  /* ---------- 25d · EL TINTE DE A1 CHOCA CON UN ELEMENTO QUE NO SE EDITA ----------
     Encontrado en la captura: el chip de sección bajo el título ("Ingenio estratega") sale del mismo
     morado que los bloques tinteados, y NO es editable — es `section_names`, un campo virtual.
     La causa está medida desde la 074 ronda 3: en tema claro `--color-primary` y `--color-accent-text`
     son EL MISMO HEX, y `--val` se define sobre el segundo mientras `.pill.tag` usa el primero.
     Así que en A1 el tinte no puede significar "esto se edita": ya significa otra cosa en esta página. */
  await setVar(page, 'A1');
  const clash = await page.evaluate(() => {
    const c = el => getComputedStyle(el).color;
    return {
      tinte: c(document.querySelector('.ed.h1')),
      chip: c(document.querySelector('.pill.tag')),
      noEditable: c([...document.querySelectorAll('.spec dd')].find(d => !d.querySelector('.ed')))
    };
  });
  ok(clash.tinte !== clash.chip,
    `25d · EN ROJO SI FALLA — el tinte de A1 (${clash.tinte}) contra el chip de sección NO editable (${clash.chip}). `
    + `Si son iguales, el tinte ya significa otra cosa en esta misma pantalla: la 074 ronda 3 midió que en claro `
    + `--color-primary y --color-accent-text son el mismo hex, y --val se define sobre el segundo.`);
  await showTools(page);

  /* ---------- 26 · EL CHECK CENTRAL, y está escrito para poder salir en rojo ----------
     La pregunta no es "¿A3 pinta algo?" (no, por construcción) sino la que importa:
     ¿SE DISTINGUE UN VALOR EDITABLE DE UNO QUE NO LO ES, estando los dos en el mismo rango?
     `Copias` (editable) contra `Año` (de BGG). Si en A3 son idénticos, el editor se ve exactamente
     como la ficha pública y nada dice que se pueda tocar — que es el `diffPx 0` de 075-V4, dicho
     sobre el par que de verdad importa.
     Se compara estilo COMPUTADO y no píxeles a propósito: los dos valores tienen textos distintos
     ("1" contra "2016"), así que un diff de píxeles mediría los glifos, no el tratamiento. */
  const distinguible = {};
  for (const v of VARS) {
    await setVar(page, v);
    distinguible[v] = await page.evaluate(() => {
      const pick = el => { const c = getComputedStyle(el); return [c.color, c.fontWeight, c.textDecorationLine, c.backgroundColor, c.borderBottomStyle].join('|'); };
      const club = document.querySelector('.spec dd .ed');                      /* Copias — editable */
      const bgg = [...document.querySelectorAll('.spec dd')].find(d => !d.querySelector('.ed')); /* Año — de BGG */
      return { club: pick(club), bgg: pick(bgg), extraNodes: club.querySelectorAll('.pen').length };
    });
  }
  ok(distinguible.A1.club !== distinguible.A1.bgg, `26a · A1 · el valor editable SÍ se distingue del de BGG (${distinguible.A1.club.split('|')[0]} contra ${distinguible.A1.bgg.split('|')[0]})`);
  ok(distinguible.A2.extraNodes === 1, `26b · A2 · se distingue por un nodo (el lápiz), no por tratamiento — el estilo es idéntico al de BGG`);
  ok(distinguible.A3.club !== distinguible.A3.bgg || distinguible.A3.extraNodes > 0,
    `26c · A3 · EN ROJO A PROPÓSITO SI FALLA — editable y no editable son "${distinguible.A3.club}" contra "${distinguible.A3.bgg}", `
    + `y el editable no agrega ningún nodo. Si son iguales, en A3 nada distingue lo que podés cambiar de lo que no: `
    + `es el diffPx 0 de 075-V4, sobre el par que importa.`);

  /* ---------- 27 · el ⋮ como único control: no empuja nada, pero hereda el borde del primario ---------- */
  await setVar(page, 'A3');
  const bar = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const kb = document.querySelector('#kebab').getBoundingClientRect();
    const tb = document.querySelector('#tbar');
    return {
      right: Math.round(kb.right - d.left), w: Math.round(kb.width), h: Math.round(kb.height),
      otros: tb.querySelectorAll('button').length,
      primarioArriba: !!tb.querySelector('.btn')
    };
  });
  ok(bar.otros === 2 && !bar.primarioArriba,
    `27a · la barra tiene ${bar.otros} controles (‹ y ⋮) y NINGÚN primario — Guardar bajó al pie, así que el ⋮ no empuja nada. `
    + `Esto borra el único costo que la ronda 1 le midió a M1 (empujaba Guardar de R359 a R307).`);
  ok(bar.right === 359,
    `27b · pero el ⋮ hereda R${bar.right}, la esquina que cinco pantallas enseñaron como LA ACCIÓN PRINCIPAL. `
    + `Es la forma inversa de lo que la 074 ronda 1 encontró con Descartar heredando el borde del primario.`);

  /* ---------- 28 · el nivel aparece DOS veces en la ficha ---------- */
  const twice = await page.evaluate(() => {
    const band = 'Ingenio estratega';
    const hits = [...document.querySelectorAll('#main .pill')].filter(p => p.textContent.includes(band));
    const d = document.querySelector('#device').getBoundingClientRect();
    return hits.map(h => ({ cls: h.className, y: Math.round(h.getBoundingClientRect().top - d.top), editable: h.classList.contains('ed') }));
  });
  ok(twice.length === 2 && twice.filter(h => h.editable).length === 1,
    `28 · el nivel está DOS veces: el pill de facts (y=${twice[0]?.y}, editable) y el chip de sección bajo el título `
    + `(y=${twice[1]?.y}, NO editable, porque es section_names, que es virtual). Mismo texto, dos rangos, uno se toca y el otro no. `
    + `No es el fixture: es cómo se ve la ficha, porque publicar mete el juego en la sección de su banda.`);

  /* ---------- 29 · los 49 sin tapa abren sobre un hueco del tamaño de la pantalla ---------- */
  await setCover(page, false);
  await hideTools(page);
  const nocover = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const c = document.querySelector('.cardposter').getBoundingClientRect();
    const h1 = document.querySelector('.h1').getBoundingClientRect();
    return { alto: Math.round(c.height), pctPantalla: Math.round(c.height / d.height * 100), tituloY: Math.round(h1.top - d.top) };
  });
  await page.screenshot({ path: path.join(OUT, 'r2-sin-tapa.png'), clip: await deviceClip(page) });
  await showTools(page);
  await setCover(page, true);
  ok(nocover.pctPantalla >= 30,
    `29 · sin tapa (los 49 = no_bgg_id 41 + bgg_missing 8, verificado contra la base) el hueco mide ${nocover.alto}px, `
    + `el ${nocover.pctPantalla}% de la pantalla, y empuja el título a y=${nocover.tituloY}. `
    + `Son exactamente los juegos que abrís el editor para arreglar.`);

  /* ---------- 30 · piso táctil de 44px en cada bloque editable ---------- */
  await setVar(page, 'A3');
  const touch = await page.evaluate(() => [...document.querySelectorAll('#main .ed')].map(e => {
    const r = e.getBoundingClientRect();
    const after = getComputedStyle(e, '::after').height;
    return { k: e.dataset.edit, h: Math.round(r.height), after };
  }));
  const chicos = touch.filter(t => t.h < 44 && !/44px/.test(t.after));
  ok(chicos.length === 0,
    `30a · los ${touch.length} bloques editables llegan al piso de 44px` + (chicos.length ? ` — no llegan: ${chicos.map(c => c.k + ' ' + c.h + 'px').join(', ')}` : ''));

  /* 30b · Y NO SE PISAN. Un piso de 44 sobre un valor de 22 se desborda 11px por lado, y las filas del
     bloque DEL CLUB están a 16px una de otra. Si dos capas se solapan, un toque en la zona compartida
     le llega a la de arriba y editás el campo equivocado sin que nada lo diga. Se mide con rects, y
     además con un hit test en el punto medio entre dos filas. */
  const overlap = await page.evaluate(() => {
    const boxes = [...document.querySelectorAll('#main .spec dd .ed')].map(e => {
      const r = e.getBoundingClientRect();
      const h = parseFloat(getComputedStyle(e, '::after').height) || r.height;
      const cy = r.top + r.height / 2;
      return { k: e.dataset.edit, top: cy - h / 2, bottom: cy + h / 2, x: r.left + 4 };
    });
    const pares = [];
    for (let i = 1; i < boxes.length; i++) if (boxes[i].top < boxes[i - 1].bottom) pares.push(`${boxes[i - 1].k}/${boxes[i].k}`);
    /* el hit test: justo en el medio entre el primer y el segundo valor */
    let medio = null;
    if (boxes.length > 1) {
      const y = (boxes[0].bottom + boxes[1].top) / 2;
      const el = document.elementFromPoint(boxes[0].x, y);
      medio = el && el.closest('.ed') ? el.closest('.ed').dataset.edit : 'nada';
    }
    return { pares, medio, n: boxes.length };
  });
  ok(overlap.pares.length === 0,
    `30b · las ${overlap.n} capas de toque del bloque DEL CLUB no se solapan` +
    (overlap.pares.length ? ` — SE SOLAPAN: ${overlap.pares.join(', ')}; un toque en la zona compartida edita el campo de arriba (en el punto medio cae: ${overlap.medio})` : ` (en el punto medio entre dos cae: ${overlap.medio})`));

  /* ---------- 31 · la hoja del ⋮ funciona y commitea ---------- */
  await setState(page, 'published');
  const cycle = await page.evaluate(() => {
    document.querySelector('#kebab').click();
    const abierta = document.querySelector('#sheet').classList.contains('open');
    const opts = [...document.querySelectorAll('#sheet .opt')].map(o => o.querySelector('.on2').textContent);
    document.querySelector('[data-cyc="retire"]').click();
    const txt = document.querySelector('#dlg-d').textContent;
    document.querySelector('[data-act="dlg-yes"]').click();
    return { abierta, opts, txt, after: document.querySelector('#tools [data-cy].on').dataset.cy };
  });
  await setState(page, 'published');
  ok(cycle.abierta && cycle.opts.length === 1 && cycle.after === 'retired',
    `31a · el ⋮ abre la hoja, ofrece ${cycle.opts.length} opción (${cycle.opts.join('')}) y commitea a \`${cycle.after}\``);
  ok(/ya no lo tiene/i.test(cycle.txt) && /ludoteca pública/i.test(cycle.txt) && /estantes/i.test(cycle.txt),
    `31b · y el diálogo dice AHORA LAS DOS MITADES — el club y la web — que es lo que el verbo colapsado exige. `
    + `La copia que corre hoy (form.ex:352-356) sólo decía la mitad de la web.`);

  /* ---------- 32 · sin errores de consola ---------- */
  ok(errs.length === 0, `32 · consola limpia${errs.length ? ' — ' + errs.slice(0, 3).join(' | ') : ''}`);

  await browser.close();
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(log.join('\n'));
  console.log(`\n${pass}/${log.length}   capturas en ${OUT}`);
  process.exit(pass === log.length ? 0 : 1);
})();
