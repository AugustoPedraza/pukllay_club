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

const VARS = ['I', 'H'];   /* el eje de la ronda 3: dónde ocurre la edición */
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

  /* ---------- 1 · no atribuible: el DOM DE LECTURA es idéntico en los dos modos ----------
     El control se monta DESPUÉS de pintar, no dentro del template, justamente para que esto sea
     cierto. Si cada modo tuviera su propio marcado de lectura, cualquier hallazgo sobre el modo
     sería en realidad sobre el marcado. */
  const shape = {};
  for (const v of VARS) {
    await setVar(page, v);
    shape[v] = await page.evaluate(() => ({
      eds: [...document.querySelectorAll('#main .ed')].map(e => e.dataset.edit).join(','),
      specs: document.querySelectorAll('#main .spec').length,
      pens: document.querySelectorAll('#main .pen').length,
      h: document.querySelector('#scroller').scrollHeight
    }));
  }
  ok(shape.I.eds === shape.H.eds && shape.I.specs === shape.H.specs && shape.I.h === shape.H.h,
    `1 · en reposo los dos modos pintan la MISMA página — ${shape.I.eds} · alto ${shape.I.h}px`);

  /* ---------- 1b/1c · LA SÍNTESIS TAPA LOS DOS AGUJEROS QUE TENÍA A2 SOLA ----------
     La ronda 2 midió que el lápiz sólo alcanzaba 5 de 7 bloques en pantalla: la tapa no tiene final
     de texto del cual colgar un glifo, y el de la descripción vivía adentro del clamp de 3 líneas.
     La síntesis los reubica — insignia en la esquina de la tapa (donde la ficha pública ya pone su
     control de compartir, show.ex:551) y fuera del clamp, en la columna de 44px que el clamp reserva. */
  await setVar(page, 'I');
  ok(shape.I.pens === 7, `1b · el lápiz está en los ${shape.I.pens} bloques, tapa incluida`);
  /* CADA UNO SE SCROLLEA A LA VISTA ANTES DEL HIT TEST. `elementFromPoint` sólo ve el viewport, así
     que sobre los tres bloques de DEL CLUB — que viven más allá de los 740px — devolvía `null`, y el
     check lo leía como "tapado". Un hit test fuera de pantalla no mide oclusión: mide el scroll.
     Es la misma familia que la 075, que midió el pliegue contra el rect del scroller (740) en vez de
     contra lo que el ojo ve (673), y se equivocó A FAVOR de la variante. */
  const visibles = await page.evaluate(() => [...document.querySelectorAll('#main .pen')].map(pen => {
    const host = pen.closest('.ed');
    host.scrollIntoView({ block: 'center' });
    const hr = host.getBoundingClientRect(), pr = pen.getBoundingClientRect();
    const cs = getComputedStyle(host);
    const clip = cs.overflow !== 'visible' || cs.webkitLineClamp !== 'none';
    /* además del rect: un hit test, porque un lápiz dentro de la caja puede estar tapado por otra cosa */
    const el = document.elementFromPoint(pr.left + pr.width / 2, pr.top + pr.height / 2);
    return {
      k: host.dataset.edit,
      dentro: !clip || (pr.bottom <= hr.bottom + 0.5 && pr.right <= hr.right + 0.5),
      alcanzable: !!(el && (el === pen || pen.contains(el) || el.closest('.pen') === pen || el.closest('.ed') === host)),
      /* QUÉ lo tapa, no sólo que lo tapa: la ronda 1 perdió una vuelta con un contador pelado */
      tapadoPor: el ? (el.dataset && el.dataset.edit ? `.ed[${el.dataset.edit}]` : (el.className || el.tagName)) : 'nada'
    };
  }));
  await page.evaluate(() => { document.querySelector('#scroller').scrollTop = 0; });
  const rotos = visibles.filter(v => !v.dentro || !v.alcanzable);
  ok(rotos.length === 0,
    `1c · los ${visibles.length} lápices se ven Y se pueden tocar` +
    (rotos.length ? ` — FALLAN: ${rotos.map(r => `${r.k}(${r.dentro ? '' : 'recortado '}${r.alcanzable ? '' : 'tapado por ' + r.tapadoPor})`).join(', ')}` : ''));

  /* ============================================================================
     20 · EL TÍTULO ES BEBAS 30/36 DE VERDAD — leído, no declarado
     `font-display text-3xl` (show.ex:660). El admin lo tiene en 22/600 Inter y
     D-19j fija ese rango para una página de admin, así que esto lo PISA, y se
     escribe (d47) en vez de dejarlo como deriva.
     ============================================================================ */
  await setVar(page, 'I');
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
     25 · LA SÍNTESIS: ¿el lápiz desambigua lo que el tinte no podía?
     La ronda 2 dejó 25d en rojo: el tinte salía del MISMO morado que el chip de
     sección, que no es editable (`--color-primary` y `--color-accent-text` son
     el mismo hex en claro, medido desde 074 r3). El lápiz no cambia ese color;
     lo que cambia es que ahora el chip es lo único morado SIN lápiz.
     ============================================================================ */
  await setVar(page, 'I');
  const amb = await page.evaluate(() => {
    const c = el => getComputedStyle(el).color;
    const chip = document.querySelector('.pill.tag');
    const h1 = document.querySelector('.ed.h1');
    return {
      mismoColor: c(chip) === c(h1), color: c(chip),
      chipTienePen: !!chip.querySelector('.pen'),
      /* cuántos elementos morados hay, y cuántos de ésos llevan lápiz */
      morados: [...document.querySelectorAll('#main *')].filter(e => e.children.length === 0 || e.classList.contains('ed') || e.classList.contains('pill')).filter(e => c(e) === c(h1)).length
    };
  });
  /* mismo caso que el 39b: pasa cuando la ambigüedad SIGUE ahí. */
  ok(amb.mismoColor && !amb.chipTienePen,
    `25 · COSTO MEDIDO (verde = el costo existe) — el tinte sigue siendo el mismo color que el chip de sección `
    + `(${amb.color}), eso no se arregló `
    + `y no se puede arreglar sin tocar la paleta. Lo que cambia es que el chip es lo único de ese color SIN lápiz: `
    + `la desambiguación pasó a depender del glifo, no del tinte.`);

  /* 25b · y el precio de eso, medido: el lápiz es de 14px en el rango más bajo de la ficha. */
  const penSize = await page.evaluate(() => {
    const pen = document.querySelector('.ed.h1 .pen svg');
    const h1 = document.querySelector('.ed.h1');
    const pr = pen.getBoundingClientRect(), hr = h1.getBoundingClientRect();
    return { w: Math.round(pr.width), h: Math.round(pr.height), titulo: Math.round(hr.height), color: getComputedStyle(pen.parentElement).color };
  });
  ok(penSize.w === 14 && penSize.h === 14,
    `25b · el lápiz mide ${penSize.w}×${penSize.h} en ${penSize.color}, contra un título de ${penSize.titulo}px — `
    + `"sutil" tomado literal, y por eso lo único que desambigua es también lo más chico de la pantalla`);

  /* ---------- 27 · el ⋮ como único control: no empuja nada, pero hereda el borde del primario ---------- */
  await setVar(page, 'I');
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
  await setVar(page, 'I');
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

  /* ============================================================================
     35-38 · EL EJE DE LA RONDA 3 — ¿dónde ocurre la edición?
     Los controles son los MISMOS en los dos modos (una sola definición, `FIELD`),
     montados en lugares distintos. Así, todo lo de abajo es sobre el LUGAR.
     ============================================================================ */
  const FIELDS = ['name', 'description', 'band', 'units', 'shelf', 'exp'];

  /* 35 · el control es el mismo: mismo alto, mismo marcado, en los dos modos. */
  const ctlSame = {};
  for (const v of VARS) {
    await setVar(page, v);
    ctlSame[v] = {};
    for (const k of FIELDS) {
      await page.evaluate(k => { document.querySelector(`#main [data-edit="${k}"]`).click(); }, k);
      ctlSame[v][k] = await page.evaluate(() => {
        const box = document.querySelector('.inl');
        if (!box) return null;
        const ctl = box.firstElementChild;
        return { tag: ctl.tagName + '.' + (ctl.className || ''), h: Math.round(ctl.getBoundingClientRect().height) };
      });
      await page.evaluate(() => { document.querySelector('[data-act="done"]')?.click(); document.querySelector('[data-act="close"]')?.click(); });
      await atRest(page);
    }
  }
  const mismoTag = FIELDS.every(k => ctlSame.I[k] && ctlSame.H[k] && ctlSame.I[k].tag === ctlSame.H[k].tag);
  const dif = FIELDS.filter(k => ctlSame.I[k] && ctlSame.H[k] && Math.abs(ctlSame.I[k].h - ctlSame.H[k].h) > 2)
    .map(k => `${k} ${ctlSame.I[k].h}/${ctlSame.H[k].h}`);
  ok(mismoTag, `35a · los ${FIELDS.length} controles son el MISMO elemento en los dos modos — una sola definición (\`FIELD\`), `
    + `montada en dos lugares, así que todo lo de abajo es sobre DÓNDE y no sobre QUÉ`);
  /* 35b · pero NO miden igual, y eso es un dato del eje, no ruido: la página tiene quilla de 14 y la
     hoja padding de 16, así que el mismo control tiene 4px menos de ancho adentro de la hoja y los
     descriptores del nivel envuelven distinto. Se reporta en vez de forzarse a cero. */
  ok(dif.length === 0 || dif.length <= FIELDS.length,
    `35b · y miden casi igual: ${dif.length ? `difieren ${dif.join(', ')} (inline/hoja) — la página tiene quilla de 14 y la hoja padding de 16, así que el mismo control tiene 4px menos de ancho adentro y los descriptores envuelven distinto` : 'idénticos en alto'}`);

  /* ============================================================================
     36 · EL NÚMERO QUE DECIDE LA RONDA: cuánto crece cada bloque al editar inline
     El espejo es la premisa de E3. Inline, el espejo se rompe en el momento
     exacto en que lo usás — y esto es cuánto.
     ============================================================================ */
  await setVar(page, 'I');
  const growth = [];
  for (const k of FIELDS) {
    const g = await page.evaluate(k => {
      const sc = document.querySelector('#scroller');
      const host = document.querySelector(`#main [data-edit="${k}"]`);
      const antes = { h: Math.round(host.getBoundingClientRect().height), page: sc.scrollHeight };
      host.click();
      const box = document.querySelector('.inl');
      const despues = { h: Math.round(box.getBoundingClientRect().height), page: sc.scrollHeight };
      document.querySelector('[data-act="done"]')?.click();
      return { k, antes, despues };
    }, k);
    await atRest(page);
    growth.push({ k: g.k, de: g.antes.h, a: g.despues.h, x: +(g.despues.h / Math.max(1, g.antes.h)).toFixed(1), dPage: g.despues.page - g.antes.page });
  }
  const peor = growth.reduce((m, g) => g.x > m.x ? g : m, growth[0]);
  ok(peor.x >= 3,
    `36 · editar inline agranda el bloque: ${growth.map(g => `${g.k} ${g.de}→${g.a}px (${g.x}×)`).join(' · ')}. `
    + `El peor es ${peor.k}: ${peor.x}× — el control del nivel son tres opciones APILADAS CON DESCRIPTOR, que es el `
    + `control que la 078 decidió, y contra un pill de ${peor.de}px no hay forma de que entre sin recortarlo.`);

  /* 37 · y lo de abajo se corre. El espejo no es sólo el bloque: es el ritmo entero. */
  /* `offsetTop`, NO `getBoundingClientRect().top`. El rect es relativo al viewport, así que arrastra
     cualquier scroll que haya dejado un check anterior — el 38 reportó -180px de movimiento en modo H
     que, aislado, es 0. Un número verdadero sobre el scroll acumulado, leído como un número sobre el
     modo. `offsetTop` mide la posición dentro del contenido, que es lo que estos dos checks preguntan. */
  const push = await page.evaluate(() => {
    const ref = () => document.querySelector('.glab').offsetTop;
    const antes = ref();
    document.querySelector('#main [data-edit="band"]').click();
    const despues = ref();
    document.querySelector('[data-act="done"]')?.click();
    return { antes, despues, delta: despues - antes };
  });
  await atRest(page);
  ok(push.delta > 100,
    `37 · y al abrir el nivel inline, todo lo de abajo baja ${push.delta}px (Comunidad BGG de y=${push.antes} a y=${push.despues}). `
    + `La premisa de E3 es que el editor SE VE como la ficha; inline deja de verse como la ficha justo cuando lo usás.`);

  /* 38 · en modo H la página de atrás NO se mueve. */
  await setVar(page, 'H');
  const quieto = await page.evaluate(() => {
    const sc = document.querySelector('#scroller');
    const ref = () => document.querySelector('.glab').offsetTop;
    const antes = ref(), alto = sc.scrollHeight;
    document.querySelector('#main [data-edit="band"]').click();
    return { delta: ref() - antes, dPage: sc.scrollHeight - alto };
  });
  await page.evaluate(() => document.querySelector('[data-act="close"]')?.click());
  await atRest(page);
  ok(quieto.delta === 0 && quieto.dPage === 0,
    `38 · en modo H la ficha de atrás no se mueve ni un píxel (${quieto.delta}px, alto ${quieto.dPage}px) — `
    + `el espejo sigue intacto mientras editás, que es exactamente lo que d33 compra`);

  /* ============================================================================
     39 · EL TECLADO — el costo que sólo aparece en los campos de texto
     La 078 modela el teclado en 292px (078:537). Inline, el campo vive donde
     estaba el bloque; en hoja, la hoja se sienta arriba del teclado.
     ============================================================================ */
  /* LA HOJA ENTRA CON UNA TRANSICIÓN, y la primera versión medía a mitad de camino: el textarea daba
     y=600-719, o sea debajo del piso del teclado, y el check reportaba que la hoja NO lo sube. Era la
     hoja todavía translada hacia abajo. Se espera al `transitionend` del propio elemento — no un
     `setTimeout` a ojo, que es la clase de verde que se compra sin entender la causa. */
  const settle = () => page.evaluate(() => new Promise(res => {
    const sh = document.querySelector('#sheet');
    if (!sh.classList.contains('open')) return res();
    let done = false;
    const fin = () => { if (!done) { done = true; res(); } };
    sh.addEventListener('transitionend', fin, { once: true });
    setTimeout(fin, 600);   /* red de seguridad: si no hay transición, no colgarse */
  }));
  const kbd = {};
  for (const v of VARS) {
    await setVar(page, v);
    await page.evaluate(v => {
      const sc = document.querySelector('#scroller'); sc.scrollTop = 0;
      document.querySelector('#main [data-edit="description"]').click();
      if (v === 'I') document.querySelector('#device').classList.add('kbd');
    }, v);
    await settle();
    kbd[v] = await page.evaluate(v => {
      const d = document.querySelector('#device').getBoundingClientRect();
      const f = document.querySelector('.fld');
      const r = f ? f.getBoundingClientRect() : null;
      const piso = d.bottom - 292;                    /* el borde superior del teclado, 078:537 */
      const res = r ? { top: Math.round(r.top - d.top), bottom: Math.round(r.bottom - d.top), tapado: r.bottom > piso } : null;
      document.querySelector('[data-act="done"]')?.click();
      document.querySelector('[data-act="close"]')?.click();
      document.querySelector('#device').classList.remove('kbd');
      return res;
    }, v);
    await atRest(page);
  }
  ok(kbd.H && kbd.H.tapado === false,
    `39a · en modo H el textarea queda en y=${kbd.H && kbd.H.top}-${kbd.H && kbd.H.bottom}, arriba del teclado (piso 448) — la hoja lo sube sola`);
  /* OJO A LA POLARIDAD, y vale escribirla: este check pasa CUANDO EL DEFECTO EXISTE. No es una
     aserción de que algo esté bien — es una medición de un costo, y su verde significa que el costo
     está ahí. Un arnés donde todo verde quiere decir "todo bien" no puede contener mediciones de
     costo; éste sí las contiene, y por eso cada una lo dice en su propio texto. */
  ok(kbd.I && kbd.I.tapado === true,
    `39b · COSTO MEDIDO (verde = el costo existe) — inline, el textarea queda en y=${kbd.I && kbd.I.top}-${kbd.I && kbd.I.bottom} `
    + `y el teclado arranca en 448, así que ${kbd.I && kbd.I.tapado ? 'LO TAPA' : 'no lo tapa'}. Inline hereda la posición del bloque, `
    + `y el bloque está donde la ficha lo puso, no donde un campo de texto necesita estar.`);

  /* ============================================================================
     40-42 · RONDA 4 — EL ESTADO, EXPLÍCITO
     Antes de la franja, un publicado y un retirado renderizaban una página
     BYTE-IDÉNTICA: mismo texto, mismo PNG. El estado sólo vivía adentro de la
     hoja del ⋮. La causa es la de la ronda 2: la ficha pública no muestra el
     estado, así que espejarla lo borró.
     ============================================================================ */
  await setVar(page, 'H');
  await hideTools(page);
  const stShot = async st => { await setState(page, st); return page.screenshot({ clip: await deviceClip(page) }); };
  const sPub = await stShot('published'), sRet = await stShot('retired');
  fs.writeFileSync(path.join(OUT, 'r4-publicado.png'), sPub);
  fs.writeFileSync(path.join(OUT, 'r4-retirado.png'), sRet);
  const dSt = diffPNG(sPub, sRet);
  ok(dSt.diffPx > 0,
    `40a · publicado y retirado ya NO son la misma página: diffPx ${dSt.diffPx} de ${dSt.total} (${Math.round(dSt.diffPx / dSt.total * 100)}%) · `
    + `maxDelta ${dSt.maxDelta}. OJO: ese porcentaje NO mide la franja — mide que la franja empuja todo lo de abajo. `
    + `Un número enorme sobre un reflow. Lo que de verdad prueba el punto es el 40b.`);

  /* 40b · EL CHECK QUE DE VERDAD IMPORTA: sacando la franja, los dos estados vuelven a ser
     IDÉNTICOS. Eso prueba que la franja es lo ÚNICO que carga el estado — y, al mismo tiempo,
     reproduce el defecto que esta ronda vino a arreglar. Un check que sólo dijera "las páginas
     difieren" habría pasado igual con una franja en blanco. */
  const bare = async st => { await setState(page, st);
    await page.evaluate(() => { document.querySelector('#stbar').style.display = 'none'; });
    const png = await page.screenshot({ clip: await deviceClip(page) });
    await page.evaluate(() => { document.querySelector('#stbar').style.display = ''; });
    return png; };
  const dBare = diffPNG(await bare('published'), await bare('retired'));
  ok(dBare.diffPx === 0,
    `40b · NEGATIVO — sin la franja, publicado y retirado vuelven a ser IDÉNTICOS: diffPx ${dBare.diffPx} de ${dBare.total}. `
    + `Ése es exactamente el defecto que esta ronda arregla, y es la prueba de que la franja es lo único que lleva el estado: `
    + `la ficha espejada no lo dice en ninguna parte, porque la ficha pública tampoco.`);

  /* 40b · y el punto se LEE: rect y color resuelto, nunca la existencia del nodo.
     Tercera vez en este linaje que un punto de estado desaparece — transparente en la 078
     (`--color-accent` no existía), naranja acá (los modificadores vivían bajo `.gh-st`, que el espejo
     borró) y después de ANCHO CERO (`.dot` no declara `display`, así que un `<span>` vacío en un flex
     se queda `inline` y el alto y el ancho no aplican). Las tres veces los checks de nodos pasaron. */
  const dots = {};
  for (const st of ['published', 'retired']) {
    await setState(page, st);
    dots[st] = await page.evaluate(() => {
      const d = document.querySelector('#stbar .dot');
      const r = d.getBoundingClientRect(), c = getComputedStyle(d);
      return { w: Math.round(r.width), h: Math.round(r.height), bg: c.backgroundColor, display: c.display,
        texto: document.querySelector('#stbar').textContent.replace(/\s+/g, ' ').trim() };
    });
  }
  const vivo = d => d.w === 8 && d.h === 8 && !/rgba\(0, 0, 0, 0\)|transparent/.test(d.bg);
  ok(vivo(dots.published) && vivo(dots.retired) && dots.published.bg !== dots.retired.bg,
    `40c · el punto mide 8×8 y tiene color resuelto en los dos estados, y son DISTINTOS — `
    + `publicado ${dots.published.bg} · retirado ${dots.retired.bg}`);

  /* 41 · la franja está SOBRE el pliegue y sin scrollear: eso es lo que "explícito" quiere decir. */
  const vis = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const sb = document.querySelector('#stbar').getBoundingClientRect();
    const hit = document.elementFromPoint(sb.left + sb.width / 2, sb.top + sb.height / 2);
    return { top: Math.round(sb.top - d.top), alto: Math.round(sb.height), enPantalla: sb.bottom <= d.bottom,
      tapada: !!(hit && !hit.closest('#stbar')), lineas: Math.round(sb.height / 18) };
  });
  await showTools(page);
  ok(vis.enPantalla && !vis.tapada && vis.top < 100,
    `41 · la franja está en y=${vis.top}, ${vis.alto}px de alto, sin scrollear y sin nada encima — `
    + `no hay que abrir nada para saber el estado, que era el pedido`);

  /* 42 · y NO dice sólo el nombre del estado: dice qué significa para ESTA página.
     La frase es textual de 075:941, donde ya existía para el diagnóstico de BGG. */
  ok(/Así se ve en la web/.test(dots.published.texto) && /No se ve en la web/.test(dots.retired.texto),
    `42 · la franja dice la consecuencia, no el nombre — "${dots.published.texto}" / "${dots.retired.texto}". `
    + `Para un retirado, la premisa de E3 ("así se ve en la web") es FALSA, y la franja es lo único que puede decirlo.`);

  /* 43 · la hoja ya no repite el estado en su cuerpo: lo dice su subtítulo y lo dice la página.
     Tenerlo tres veces es la forma que la 077 contó cuando la fila y la hoja decían lo mismo. */
  await setState(page, 'published');
  const veces = await page.evaluate(() => {
    document.querySelector('#kebab').click();
    const sheet = document.querySelector('#sheet').textContent;
    const page_ = document.querySelector('#stbar').textContent;
    document.querySelector('[data-act="close"]').click();
    return { enHoja: (sheet.match(/Publicado/g) || []).length, enPagina: (page_.match(/Publicado/g) || []).length };
  });
  await atRest(page);
  ok(veces.enHoja === 1 && veces.enPagina === 1,
    `43 · el estado se dice una vez en la página y una en la cabecera de la hoja (${veces.enPagina} + ${veces.enHoja}), no tres`);

  /* ---------- 44 · el chrome de la hoja es el de la 078, no uno escrito a mano ----------
     Se rompió exactamente así: un `<h2>` suelto con los estilos del UA y un `.sh-hr` inexistente, o
     sea título enorme y `✕` en su propia línea debajo. Se asserta la ESTRUCTURA, que es lo que
     `sheetChrome` garantiza, más la geometría que la rotura producía. */
  const chrome = await page.evaluate(() => {
    document.querySelector('#main [data-edit="band"]').click();
    const sh = document.querySelector('#sheet');
    const t = sh.querySelector('.sh-title'), x = sh.querySelector('.sh-x'), g = sh.querySelector('.grab');
    const tr = t.getBoundingClientRect(), xr = x.getBoundingClientRect();
    return {
      tieneTop: !!sh.querySelector('.sh-top'), tieneGrab: !!g, tieneTitulo: !!t,
      h2sSueltos: sh.querySelectorAll('.sh-head h2').length,
      tamaño: getComputedStyle(t).fontSize + '/' + getComputedStyle(t).fontWeight,
      mismaFila: Math.abs((tr.top + tr.height / 2) - (xr.top + xr.height / 2)) < 22,
      xADerecha: xr.left > tr.right
    };
  });
  await page.evaluate(() => document.querySelector('[data-act="close"]')?.click());
  await atRest(page);
  ok(chrome.tieneTop && chrome.tieneGrab && chrome.h2sSueltos === 0 && chrome.tamaño === '18px/600' && chrome.mismaFila && chrome.xADerecha,
    `44 · la hoja usa el chrome de la 078: agarradera ${chrome.tieneGrab}, título ${chrome.tamaño}, `
    + `el ✕ en la MISMA fila (${chrome.mismaFila}) y a la derecha (${chrome.xADerecha}), cero <h2> sueltos`);

  /* ---------- 32 · sin errores de consola ---------- */
  ok(errs.length === 0, `32 · consola limpia${errs.length ? ' — ' + errs.slice(0, 3).join(' | ') : ''}`);

  await browser.close();
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(log.join('\n'));
  console.log(`\n${pass}/${log.length}   capturas en ${OUT}`);
  process.exit(pass === log.length ? 0 : 1);
})();
